
  CREATE OR REPLACE FORCE VIEW "APPS"."XXCFR_CUST_HIERARCHY_V" ("CASH_ACCOUNT_ID", "CASH_ACCOUNT_NUMBER", "CASH_ACCOUNT_NAME", "BILL_ACCOUNT_ID", "BILL_ACCOUNT_NUMBER", "BILL_ACCOUNT_NAME", "SHIP_ACCOUNT_ID", "SHIP_ACCOUNT_NUMBER", "SHIP_ACCOUNT_NAME", "CASH_RECEIV_BASE_CODE", "BILL_PARTY_ID", "BILL_BILL_BASE_CODE", "BILL_POSTAL_CODE", "BILL_STATE", "BILL_CITY", "BILL_ADDRESS1", "BILL_ADDRESS2", "BILL_TEL_NUM", "BILL_CONS_INV_FLAG", "BILL_TORIHIKISAKI_CODE", "BILL_STORE_CODE", "BILL_CUST_STORE_NAME", "BILL_TAX_DIV", "BILL_CRED_REC_CODE1", "BILL_CRED_REC_CODE2", "BILL_CRED_REC_CODE3", "BILL_INVOICE_TYPE", "BILL_PAYMENT_TERM_ID", "BILL_PAYMENT_TERM2", "BILL_PAYMENT_TERM3", "BILL_TAX_ROUND_RULE", "SHIP_SALE_BASE_CODE") AS 
  SELECT 
-- Modify 2009.08.03 hirose start
--  SELECT cash_account_id                                  --入金先顧客ID        
--        ,cash_account_number                              --入金先顧客コード    
--        ,xxcfr_common_pkg.get_cust_account_name(
--                            cash_account_number,
--                            0)                            --入金先顧客名称      
--        ,bill_account_id                                  --請求先顧客ID        
--        ,bill_account_number                              --請求先顧客コード    
--        ,xxcfr_common_pkg.get_cust_account_name(
--                            bill_account_number,
--                            0)                            --請求先顧客名称      
--        ,ship_account_id                                  --出荷先顧客ID        
--        ,ship_account_number                              --出荷先顧客コード    
--        ,xxcfr_common_pkg.get_cust_account_name(
--                            ship_account_number,
--                            0)                            --出荷先顧客名称      
--        ,cash_receiv_base_code                            --入金拠点コード      
--        ,bill_party_id                                    --パーティID          
--        ,bill_bill_base_code                              --請求拠点コード      
--        ,bill_postal_code                                 --郵便番号            
--        ,bill_state                                       --都道府県            
--        ,bill_city                                        --市・区              
--        ,bill_address1                                    --住所1               
--        ,bill_address2                                    --住所2               
--        ,bill_tel_num                                     --電話番号            
--        ,bill_cons_inv_flag                               --一括請求書発行フラグ
--        ,bill_torihikisaki_code                           --取引先コード        
--        ,bill_store_code                                  --店舗コード          
--        ,bill_cust_store_name                             --顧客店舗名称        
--        ,bill_tax_div                                     --消費税区分          
--        ,bill_cred_rec_code1                              --売掛コード1(請求書) 
--        ,bill_cred_rec_code2                              --売掛コード2(事業所) 
--        ,bill_cred_rec_code3                              --売掛コード3(その他) 
--        ,bill_invoice_type                                --請求書出力形式      
--        ,bill_payment_term_id                             --支払条件            
--        ,TO_NUMBER(bill_payment_term2)                    --第2支払条件         
--        ,TO_NUMBER(bill_payment_term3)                    --第3支払条件         
--        ,bill_tax_round_rule                              --税金－端数処理      
--        ,ship_sale_base_code                              --売上拠点コード      
         temp.cash_account_id                          AS cash_account_id        --入金先顧客ID        
        ,temp.cash_account_number                      AS cash_account_number    --入金先顧客コード    
        ,xxcfr_common_pkg.get_cust_account_name(
                            temp.cash_account_number,
                            0)                         AS cash_account_name      --入金先顧客名称      
        ,temp.bill_account_id                          AS bill_account_id        --請求先顧客ID        
        ,temp.bill_account_number                      AS bill_account_number    --請求先顧客コード    
        ,xxcfr_common_pkg.get_cust_account_name(
                            temp.bill_account_number,
                            0)                         AS bill_account_name      --請求先顧客名称      
        ,temp.ship_account_id                          AS ship_account_id        --出荷先顧客ID        
        ,temp.ship_account_number                      AS ship_account_number    --出荷先顧客コード    
        ,xxcfr_common_pkg.get_cust_account_name(
                            temp.ship_account_number,
                            0)                         AS ship_account_name      --出荷先顧客名称      
        ,temp.cash_receiv_base_code                    AS cash_receiv_base_code  --入金拠点コード      
        ,temp.bill_party_id                            AS bill_party_id          --パーティID          
        ,temp.bill_bill_base_code                      AS bill_bill_base_code    --請求拠点コード      
        ,temp.bill_postal_code                         AS bill_postal_code       --郵便番号            
        ,temp.bill_state                               AS bill_state             --都道府県            
        ,temp.bill_city                                AS bill_city              --市・区              
        ,temp.bill_address1                            AS bill_address1          --住所1               
        ,temp.bill_address2                            AS bill_address2          --住所2               
        ,temp.bill_tel_num                             AS bill_tel_num           --電話番号            
        ,temp.bill_cons_inv_flag                       AS bill_cons_inv_flag     --一括請求書発行フラグ
        ,temp.bill_torihikisaki_code                   AS bill_torihikisaki_code --取引先コード        
        ,temp.bill_store_code                          AS bill_store_code        --店舗コード          
        ,temp.bill_cust_store_name                     AS bill_cust_store_name   --顧客店舗名称        
        ,temp.bill_tax_div                             AS bill_tax_div           --消費税区分          
        ,temp.bill_cred_rec_code1                      AS bill_cred_rec_code1    --売掛コード1(請求書) 
        ,temp.bill_cred_rec_code2                      AS bill_cred_rec_code2    --売掛コード2(事業所) 
        ,temp.bill_cred_rec_code3                      AS bill_cred_rec_code3    --売掛コード3(その他) 
        ,temp.bill_invoice_type                        AS bill_invoice_type      --請求書出力形式      
        ,temp.bill_payment_term_id                     AS bill_payment_term_id   --支払条件            
        ,TO_NUMBER(temp.bill_payment_term2)            AS bill_payment_term2     --第2支払条件         
        ,TO_NUMBER(temp.bill_payment_term3)            AS bill_payment_term3     --第3支払条件         
        ,temp.bill_tax_round_rule                      AS bill_tax_round_rule    --税金－端数処理      
        ,temp.ship_sale_base_code                      AS ship_sale_base_code    --売上拠点コード      
-- Modify 2009.08.03 hirose End
  FROM   (
  --①入金先顧客＆請求先顧客－出荷先顧客
    SELECT bill_hzca_1.cust_account_id         AS cash_account_id         --入金先顧客ID        
          ,bill_hzca_1.account_number          AS cash_account_number     --入金先顧客コード    
          ,bill_hzca_1.cust_account_id         AS bill_account_id         --請求先顧客ID        
          ,bill_hzca_1.account_number          AS bill_account_number     --請求先顧客コード    
          ,ship_hzca_1.cust_account_id         AS ship_account_id         --出荷先顧客ID        
          ,ship_hzca_1.account_number          AS ship_account_number     --出荷先顧客コード    
          ,bill_hzad_1.receiv_base_code        AS cash_receiv_base_code   --入金拠点コード      
          ,bill_hzca_1.party_id                AS bill_party_id           --パーティID          
          ,bill_hzad_1.bill_base_code          AS bill_bill_base_code     --請求拠点コード      
          ,bill_hzlo_1.postal_code             AS bill_postal_code        --郵便番号            
          ,bill_hzlo_1.state                   AS bill_state              --都道府県            
          ,bill_hzlo_1.city                    AS bill_city               --市・区              
          ,bill_hzlo_1.address1                AS bill_address1           --住所1               
          ,bill_hzlo_1.address2                AS bill_address2           --住所2               
          ,bill_hzlo_1.address_lines_phonetic  AS bill_tel_num            --電話番号            
          ,bill_hzcp_1.cons_inv_flag           AS bill_cons_inv_flag      --一括請求書発行フラグ
          ,bill_hzad_1.torihikisaki_code       AS bill_torihikisaki_code  --取引先コード        
          ,bill_hzad_1.store_code              AS bill_store_code         --店舗コード          
          ,bill_hzad_1.cust_store_name         AS bill_cust_store_name    --顧客店舗名称        
          ,bill_hzad_1.tax_div                 AS bill_tax_div            --消費税区分          
          ,bill_hsua_1.attribute4              AS bill_cred_rec_code1     --売掛コード1(請求書) 
          ,bill_hsua_1.attribute5              AS bill_cred_rec_code2     --売掛コード2(事業所) 
          ,bill_hsua_1.attribute6              AS bill_cred_rec_code3     --売掛コード3(その他) 
          ,bill_hsua_1.attribute7              AS bill_invoice_type       --請求書出力形式      
          ,bill_hsua_1.payment_term_id         AS bill_payment_term_id    --支払条件            
          ,bill_hsua_1.attribute2              AS bill_payment_term2      --第2支払条件         
          ,bill_hsua_1.attribute3              AS bill_payment_term3      --第3支払条件         
          ,bill_hsua_1.tax_rounding_rule       AS bill_tax_round_rule     --税金－端数処理      
          ,ship_hzad_1.sale_base_code          AS ship_sale_base_code     --売上拠点コード      
    FROM   hz_cust_accounts          bill_hzca_1              --請求先顧客マスタ
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    bill_hasa_1              --請求先顧客所在地
--          ,hz_cust_site_uses_all     bill_hsua_1              --請求先顧客使用目的
          ,hz_cust_acct_sites        bill_hasa_1              --請求先顧客所在地
          ,hz_cust_site_uses         bill_hsua_1              --請求先顧客使用目的
-- Modify 2009.06.26 kayahara end
          ,xxcmm_cust_accounts       bill_hzad_1              --請求先顧客追加情報
          ,hz_party_sites            bill_hzps_1              --請求先パーティサイト  
          ,hz_locations              bill_hzlo_1              --請求先顧客事業所      
          ,hz_customer_profiles      bill_hzcp_1              --請求先顧客プロファイル
          ,hz_cust_accounts          ship_hzca_1              --出荷先顧客マスタ
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    ship_hasa_1              --出荷先顧客所在地
--          ,hz_cust_site_uses_all     ship_hsua_1              --出荷先顧客使用目的
          ,hz_cust_acct_sites        ship_hasa_1              --出荷先顧客所在地
          ,hz_cust_site_uses         ship_hsua_1              --出荷先顧客使用目的
-- Modify 2009.06.26 kayahara end
          ,xxcmm_cust_accounts       ship_hzad_1              --出荷先顧客追加情報
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_relate_all   bill_hcar_1              --顧客関連マスタ(請求関連)
          ,hz_cust_acct_relate       bill_hcar_1              --顧客関連マスタ(請求関連)
-- Modify 2009.06.26 kayahara end
    WHERE  bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --請求先顧客マスタ.顧客ID = 顧客関連マスタ.顧客ID
    AND    bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --顧客関連マスタ.関連先顧客ID = 出荷先顧客マスタ.顧客ID
    AND    bill_hzca_1.customer_class_code = '14'                            --請求先顧客.顧客区分 = '14'(売掛管理先顧客)
    AND    bill_hcar_1.status = 'A'                                          --顧客関連マスタ.ステータス = ‘A’
    AND    bill_hcar_1.attribute1 = '1'                                      --顧客関連マスタ.関連分類 = ‘1’ (請求)
-- Modify 2009.06.26 kayahara start    
--    AND    bill_hasa_1.org_id = fnd_profile.value('ORG_ID')                  --請求先顧客所在地.組織ID = ログインユーザの組織ID
--    AND    ship_hasa_1.org_id = fnd_profile.value('ORG_ID')                  --出荷先顧客所在地.組織ID = ログインユーザの組織ID
--    AND    bill_hcar_1.org_id = fnd_profile.value('ORG_ID')                  --顧客関連マスタ(請求関連).組織ID = ログインユーザの組織ID
--    AND    bill_hsua_1.org_id = fnd_profile.value('ORG_ID')                  --請求先顧客使用目的.組織ID = ログインユーザの組織ID
--    AND    ship_hsua_1.org_id = fnd_profile.value('ORG_ID')                  --出荷先顧客使用目的.組織ID = ログインユーザの組織ID
-- Modify 2009.06.26 kayahara end   
    AND    bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
    AND    bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
    AND    bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
    AND    bill_hsua_1.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
-- Add 2010.01.29 Yasukawa Start
    AND    bill_hsua_1.status = 'A'                                          --請求先顧客使用目的.ステータス = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --出荷先顧客マスタ.顧客ID = 出荷先顧客所在地.顧客ID
    AND    ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --出荷先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
-- Add 2010.01.29 Yasukawa Start
    AND    ship_hsua_1.status = 'A'                                          --出荷先顧客使用目的.ステータス = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
    AND    ship_hzca_1.cust_account_id = ship_hzad_1.customer_id             --出荷先顧客マスタ.顧客ID = 出荷先顧客追加情報.顧客ID
    AND    bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID  
    AND    bill_hzps_1.location_id = bill_hzlo_1.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID                  
    AND    bill_hsua_1.site_use_id = bill_hzcp_1.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
    AND NOT EXISTS (
                SELECT 'X'
-- Modify 2009.06.26 kayahara start                
--                FROM   hz_cust_acct_relate_all   cash_hcar_1   --顧客関連マスタ(入金関連)
                FROM   hz_cust_acct_relate       cash_hcar_1   --顧客関連マスタ(入金関連)
-- Modify 2009.06.26 kayahara end
                WHERE  cash_hcar_1.status = 'A'                                          --顧客関連マスタ(入金関連).ステータス = ‘A’
                AND    cash_hcar_1.attribute1 = '2'                                      --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
                AND    cash_hcar_1.related_cust_account_id = bill_hzca_1.cust_account_id --顧客関連マスタ(入金関連).関連先顧客ID = 請求先顧客マスタ.顧客ID
-- Modify 2009.06.26 kayahara start                 
--                AND    cash_hcar_1.org_id = fnd_profile.value('ORG_ID')                  --顧客関連マスタ(入金関連).組織ID = ログインユーザの組織ID
-- Modify 2009.06.26 kayahara end                     
                     )
    UNION ALL
    --②入金先顧客－請求先顧客－出荷先顧客
    SELECT cash_hzca_2.cust_account_id           AS cash_account_id         --入金先顧客ID        
          ,cash_hzca_2.account_number            AS cash_account_number     --入金先顧客コード    
          ,bill_hzca_2.cust_account_id           AS bill_account_id         --請求先顧客ID        
          ,bill_hzca_2.account_number            AS bill_account_number     --請求先顧客コード    
          ,ship_hzca_2.cust_account_id           AS ship_account_id         --出荷先顧客ID        
          ,ship_hzca_2.account_number            AS ship_account_number     --出荷先顧客コード    
          ,cash_hzad_2.receiv_base_code          AS cash_receiv_base_code   --入金拠点コード      
          ,bill_hzca_2.party_id                  AS bill_party_id           --パーティID          
          ,bill_hzad_2.bill_base_code            AS bill_bill_base_code     --請求拠点コード      
          ,bill_hzlo_2.postal_code               AS bill_postal_code        --郵便番号            
          ,bill_hzlo_2.state                     AS bill_state              --都道府県            
          ,bill_hzlo_2.city                      AS bill_city               --市・区              
          ,bill_hzlo_2.address1                  AS bill_address1           --住所1               
          ,bill_hzlo_2.address2                  AS bill_address2           --住所2               
          ,bill_hzlo_2.address_lines_phonetic    AS bill_tel_num            --電話番号            
          ,bill_hzcp_2.cons_inv_flag             AS bill_cons_inv_flag      --一括請求書発行フラグ
          ,bill_hzad_2.torihikisaki_code         AS bill_torihikisaki_code  --取引先コード        
          ,bill_hzad_2.store_code                AS bill_store_code         --店舗コード          
          ,bill_hzad_2.cust_store_name           AS bill_cust_store_name    --顧客店舗名称        
          ,bill_hzad_2.tax_div                   AS bill_tax_div            --消費税区分          
          ,bill_hsua_2.attribute4                AS bill_cred_rec_code1     --売掛コード1(請求書) 
          ,bill_hsua_2.attribute5                AS bill_cred_rec_code2     --売掛コード2(事業所) 
          ,bill_hsua_2.attribute6                AS bill_cred_rec_code3     --売掛コード3(その他) 
          ,bill_hsua_2.attribute7                AS bill_invoice_type       --請求書出力形式      
          ,bill_hsua_2.payment_term_id           AS bill_payment_term_id    --支払条件            
          ,bill_hsua_2.attribute2                AS bill_payment_term2      --第2支払条件         
          ,bill_hsua_2.attribute3                AS bill_payment_term3      --第3支払条件         
          ,bill_hsua_2.tax_rounding_rule         AS bill_tax_round_rule     --税金－端数処理      
          ,ship_hzad_2.sale_base_code            AS ship_sale_base_code     --売上拠点コード      
    FROM   hz_cust_accounts          cash_hzca_2              --入金先顧客マスタ
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    cash_hasa_2              --入金先顧客所在地
          ,hz_cust_acct_sites        cash_hasa_2              --入金先顧客所在地
-- Modify 2009.06.26 kayahara end
          ,xxcmm_cust_accounts       cash_hzad_2              --入金先顧客追加情報
          ,hz_cust_accounts          bill_hzca_2              --請求先顧客マスタ
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    bill_hasa_2              --請求先顧客所在地
--          ,hz_cust_site_uses_all     bill_hsua_2              --請求先顧客使用目的
          ,hz_cust_acct_sites        bill_hasa_2              --請求先顧客所在地
          ,hz_cust_site_uses         bill_hsua_2              --請求先顧客使用目的
-- Modify 2009.06.26 kayahara end          
          ,xxcmm_cust_accounts       bill_hzad_2              --請求先顧客追加情報
          ,hz_party_sites            bill_hzps_2              --請求先パーティサイト  
          ,hz_locations              bill_hzlo_2              --請求先顧客事業所      
          ,hz_customer_profiles      bill_hzcp_2              --請求先顧客プロファイル      
          ,hz_cust_accounts          ship_hzca_2              --出荷先顧客マスタ
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    ship_hasa_2              --出荷先顧客所在地
--          ,hz_cust_site_uses_all     ship_hsua_2              --出荷先顧客使用目的
          ,hz_cust_acct_sites        ship_hasa_2              --出荷先顧客所在地
          ,hz_cust_site_uses         ship_hsua_2              --出荷先顧客使用目的
-- Modify 2009.06.26 kayahara end           
          ,xxcmm_cust_accounts       ship_hzad_2              --出荷先顧客追加情報
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_relate_all   cash_hcar_2              --顧客関連マスタ(入金関連)
--          ,hz_cust_acct_relate_all   bill_hcar_2              --顧客関連マスタ(請求関連)
          ,hz_cust_acct_relate       cash_hcar_2              --顧客関連マスタ(入金関連)
          ,hz_cust_acct_relate       bill_hcar_2              --顧客関連マスタ(請求関連)
-- Modify 2009.06.26 kayahara end            
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
-- Modify 2009.06.26 kayahara start    
--    AND    cash_hasa_2.org_id = fnd_profile.value('ORG_ID')                  --入金先顧客所在地.組織ID = ログインユーザの組織ID
--    AND    bill_hasa_2.org_id = fnd_profile.value('ORG_ID')                  --請求先顧客所在地.組織ID = ログインユーザの組織ID
--    AND    ship_hasa_2.org_id = fnd_profile.value('ORG_ID')                  --出荷先顧客所在地.組織ID = ログインユーザの組織ID
--    AND    cash_hcar_2.org_id = fnd_profile.value('ORG_ID')                  --顧客関連マスタ(入金関連).組織ID = ログインユーザの組織ID
--    AND    bill_hcar_2.org_id = fnd_profile.value('ORG_ID')                  --顧客関連マスタ(請求関連).組織ID = ログインユーザの組織ID
--    AND    bill_hsua_2.org_id = fnd_profile.value('ORG_ID')                  --請求先顧客使用目的.組織ID = ログインユーザの組織ID
--    AND    ship_hsua_2.org_id = fnd_profile.value('ORG_ID')                  --出荷先顧客使用目的.組織ID = ログインユーザの組織ID
-- Modify 2009.06.26 kayahara end    
    AND    bill_hzca_2.cust_account_id = bill_hzad_2.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
    AND    bill_hzca_2.cust_account_id = bill_hasa_2.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
    AND    bill_hasa_2.cust_acct_site_id = bill_hsua_2.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
    AND    bill_hsua_2.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
-- Add 2010.01.29 Yasukawa Start
    AND    bill_hsua_2.status = 'A'                                          --請求先顧客使用目的.ステータス = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    cash_hzca_2.cust_account_id = cash_hasa_2.cust_account_id         --入金先顧客マスタ.顧客ID = 入金先顧客所在地.顧客ID
    AND    ship_hzca_2.cust_account_id = ship_hzad_2.customer_id             --出荷先顧客マスタ.顧客ID = 出荷先顧客追加情報.顧客ID
    AND    ship_hzca_2.cust_account_id = ship_hasa_2.cust_account_id         --出荷先顧客マスタ.顧客ID = 出荷先顧客所在地.顧客ID
    AND    ship_hasa_2.cust_acct_site_id = ship_hsua_2.cust_acct_site_id     --出荷先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
-- Add 2010.01.29 Yasukawa Start
    AND    ship_hsua_2.status = 'A'                                          --出荷先顧客使用目的.ステータス = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    ship_hsua_2.bill_to_site_use_id = bill_hsua_2.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
    AND    bill_hasa_2.party_site_id = bill_hzps_2.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID  
    AND    bill_hzps_2.location_id = bill_hzlo_2.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID                  
    AND    bill_hsua_2.site_use_id = bill_hzcp_2.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
    UNION ALL
    --③入金先顧客－請求先顧客＆出荷先顧客
    SELECT cash_hzca_3.cust_account_id             AS cash_account_id         --入金先顧客ID        
          ,cash_hzca_3.account_number              AS cash_account_number     --入金先顧客コード    
          ,ship_hzca_3.cust_account_id             AS bill_account_id         --請求先顧客ID        
          ,ship_hzca_3.account_number              AS bill_account_number     --請求先顧客コード    
          ,ship_hzca_3.cust_account_id             AS ship_account_id         --出荷先顧客ID        
          ,ship_hzca_3.account_number              AS ship_account_number     --出荷先顧客コード    
          ,cash_hzad_3.receiv_base_code            AS cash_receiv_base_code   --入金拠点コード      
          ,ship_hzca_3.party_id                    AS bill_party_id           --パーティID          
          ,bill_hzad_3.bill_base_code              AS bill_bill_base_code     --請求拠点コード      
          ,bill_hzlo_3.postal_code                 AS bill_postal_code        --郵便番号            
          ,bill_hzlo_3.state                       AS bill_state              --都道府県            
          ,bill_hzlo_3.city                        AS bill_city               --市・区              
          ,bill_hzlo_3.address1                    AS bill_address1           --住所1               
          ,bill_hzlo_3.address2                    AS bill_address2           --住所2               
          ,bill_hzlo_3.address_lines_phonetic      AS bill_tel_num            --電話番号            
          ,bill_hzcp_3.cons_inv_flag               AS bill_cons_inv_flag      --一括請求書発行フラグ
          ,bill_hzad_3.torihikisaki_code           AS bill_torihikisaki_code  --取引先コード        
          ,bill_hzad_3.store_code                  AS bill_store_code         --店舗コード          
          ,bill_hzad_3.cust_store_name             AS bill_cust_store_name    --顧客店舗名称        
          ,bill_hzad_3.tax_div                     AS bill_tax_div            --消費税区分          
          ,bill_hsua_3.attribute4                  AS bill_cred_rec_code1     --売掛コード1(請求書) 
          ,bill_hsua_3.attribute5                  AS bill_cred_rec_code2     --売掛コード2(事業所) 
          ,bill_hsua_3.attribute6                  AS bill_cred_rec_code3     --売掛コード3(その他) 
          ,bill_hsua_3.attribute7                  AS bill_invoice_type       --請求書出力形式      
          ,bill_hsua_3.payment_term_id             AS bill_payment_term_id    --支払条件            
          ,bill_hsua_3.attribute2                  AS bill_payment_term2      --第2支払条件         
          ,bill_hsua_3.attribute3                  AS bill_payment_term3      --第3支払条件         
          ,bill_hsua_3.tax_rounding_rule           AS bill_tax_round_rule     --税金－端数処理      
          ,bill_hzad_3.sale_base_code              AS ship_sale_base_code     --売上拠点コード      
    FROM   hz_cust_accounts          cash_hzca_3              --入金先顧客マスタ
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    cash_hasa_3              --入金先顧客所在地
          ,hz_cust_acct_sites        cash_hasa_3              --入金先顧客所在地
-- Modify 2009.06.26 kayahara end         
          ,xxcmm_cust_accounts       cash_hzad_3              --入金先顧客追加情報
          ,hz_cust_accounts          ship_hzca_3              --出荷先顧客マスタ　※請求先含む
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    bill_hasa_3              --請求先顧客所在地
--          ,hz_cust_site_uses_all     bill_hsua_3              --請求先顧客使用目的
--          ,hz_cust_site_uses_all     ship_hsua_3              --出荷先顧客使用目的
          ,hz_cust_acct_sites        bill_hasa_3              --請求先顧客所在地
          ,hz_cust_site_uses         bill_hsua_3              --請求先顧客使用目的
          ,hz_cust_site_uses         ship_hsua_3              --出荷先顧客使用目的
-- Modify 2009.06.26 kayahara end           
          ,xxcmm_cust_accounts       bill_hzad_3              --請求先顧客追加情報
          ,hz_party_sites            bill_hzps_3              --請求先パーティサイト  
          ,hz_locations              bill_hzlo_3              --請求先顧客事業所      
          ,hz_customer_profiles      bill_hzcp_3              --請求先顧客プロファイル 
-- Modify 2009.06.26 kayahara start     
--          ,hz_cust_acct_relate_all   cash_hcar_3              --顧客関連マスタ(入金関連)
          ,hz_cust_acct_relate       cash_hcar_3              --顧客関連マスタ(入金関連)
-- Modify 2009.06.26 kayahara end           
    WHERE  cash_hzca_3.cust_account_id = cash_hcar_3.cust_account_id         --入金先顧客マスタ.顧客ID = 顧客関連マスタ(入金関連).顧客ID
    AND    cash_hzca_3.cust_account_id = cash_hzad_3.customer_id             --入金先顧客マスタ.顧客ID = 入金先顧客追加情報.顧客ID
    AND    cash_hcar_3.related_cust_account_id = ship_hzca_3.cust_account_id --顧客関連マスタ(入金関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
    AND    cash_hzca_3.customer_class_code = '14'                            --入金先顧客.顧客区分 = '14'(売掛管理先顧客)
    AND    ship_hzca_3.customer_class_code = '10'                            --請求先顧客.顧客区分 = '10'(顧客)
    AND    cash_hcar_3.status = 'A'                                          --顧客関連マスタ(入金関連).ステータス = ‘A’
    AND    cash_hcar_3.attribute1 = '2'                                      --顧客関連マスタ(入金関連).関連分類 = ‘2’ (入金)
-- Modify 2009.06.26 kayahara start   
--    AND    cash_hasa_3.org_id = fnd_profile.value('ORG_ID')                  --入金先顧客所在地.組織ID = ログインユーザの組織ID
--    AND    bill_hasa_3.org_id = fnd_profile.value('ORG_ID')                  --請求先顧客所在地.組織ID = ログインユーザの組織ID
--    AND    cash_hcar_3.org_id = fnd_profile.value('ORG_ID')                  --顧客関連マスタ(入金関連).組織ID = ログインユーザの組織ID
--    AND    bill_hsua_3.org_id = fnd_profile.value('ORG_ID')                  --請求先顧客使用目的.組織ID = ログインユーザの組織ID
--    AND    ship_hsua_3.org_id = fnd_profile.value('ORG_ID')                  --出荷先顧客使用目的.組織ID = ログインユーザの組織ID
-- Modify 2009.06.26 kayahara end    
    AND    NOT EXISTS (
               SELECT ROWNUM
-- Modify 2009.06.26 kayahara start
--               FROM   hz_cust_acct_relate_all ex_hcar_3       --顧客関連マスタ(請求関連)
               FROM   hz_cust_acct_relate     ex_hcar_3       --顧客関連マスタ(請求関連)
-- Modify 2009.06.26 kayahara end                 
               WHERE  ex_hcar_3.cust_account_id = ship_hzca_3.cust_account_id         --顧客関連マスタ(請求関連).顧客ID = 出荷先顧客マスタ.顧客ID
               AND    ex_hcar_3.status = 'A'                                          --顧客関連マスタ(請求関連).ステータス = ‘A’
-- Modify 2009.06.26 kayahara start               
--               AND    ex_hcar_3.org_id = fnd_profile.value('ORG_ID')                  --顧客関連マスタ(請求関連).組織ID = ログインユーザの組織ID
-- Modify 2009.06.26 kayahara end                    
                    )
    AND    ship_hzca_3.cust_account_id = bill_hzad_3.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
    AND    ship_hzca_3.cust_account_id = bill_hasa_3.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
    AND    bill_hasa_3.cust_acct_site_id = bill_hsua_3.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
    AND    bill_hasa_3.cust_acct_site_id = ship_hsua_3.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
    AND    bill_hsua_3.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
-- Add 2010.01.29 Yasukawa Start
    AND    bill_hsua_3.status = 'A'                                          --請求先顧客使用目的.ステータス = 'A'
-- Add 2010.01.29 Yasukawa End
-- Add 2010.01.29 Yasukawa Start
    AND    ship_hsua_3.status = 'A'                                          --出荷先顧客使用目的.ステータス = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    ship_hsua_3.bill_to_site_use_id = bill_hsua_3.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
    AND    cash_hzca_3.cust_account_id = cash_hasa_3.cust_account_id         --入金先顧客マスタ.顧客ID = 入金先顧客所在地.顧客ID
    AND    bill_hasa_3.party_site_id = bill_hzps_3.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID  
    AND    bill_hzps_3.location_id = bill_hzlo_3.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID                  
    AND    bill_hsua_3.site_use_id = bill_hzcp_3.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
    UNION ALL
    --④入金先顧客＆請求先顧客＆出荷先顧客
    SELECT ship_hzca_4.cust_account_id               AS cash_account_id         --入金先顧客ID        
          ,ship_hzca_4.account_number                AS cash_account_number     --入金先顧客コード    
          ,ship_hzca_4.cust_account_id               AS bill_account_id         --請求先顧客ID        
          ,ship_hzca_4.account_number                AS bill_account_number     --請求先顧客コード    
          ,ship_hzca_4.cust_account_id               AS ship_account_id         --出荷先顧客ID        
          ,ship_hzca_4.account_number                AS ship_account_number     --出荷先顧客コード    
          ,bill_hzad_4.receiv_base_code              AS cash_receiv_base_code   --入金拠点コード      
          ,ship_hzca_4.party_id                      AS bill_party_id           --パーティID          
          ,bill_hzad_4.bill_base_code                AS bill_bill_base_code     --請求拠点コード      
          ,bill_hzlo_4.postal_code                   AS bill_postal_code        --郵便番号            
          ,bill_hzlo_4.state                         AS bill_state              --都道府県            
          ,bill_hzlo_4.city                          AS bill_city               --市・区              
          ,bill_hzlo_4.address1                      AS bill_address1           --住所1               
          ,bill_hzlo_4.address2                      AS bill_address2           --住所2               
          ,bill_hzlo_4.address_lines_phonetic        AS bill_tel_num            --電話番号            
          ,bill_hzcp_4.cons_inv_flag                 AS bill_cons_inv_flag      --一括請求書発行フラグ
          ,bill_hzad_4.torihikisaki_code             AS bill_torihikisaki_code  --取引先コード        
          ,bill_hzad_4.store_code                    AS bill_store_code         --店舗コード          
          ,bill_hzad_4.cust_store_name               AS bill_cust_store_name    --顧客店舗名称        
          ,bill_hzad_4.tax_div                       AS bill_tax_div            --消費税区分          
          ,bill_hsua_4.attribute4                    AS bill_cred_rec_code1     --売掛コード1(請求書) 
          ,bill_hsua_4.attribute5                    AS bill_cred_rec_code2     --売掛コード2(事業所) 
          ,bill_hsua_4.attribute6                    AS bill_cred_rec_code3     --売掛コード3(その他) 
          ,bill_hsua_4.attribute7                    AS bill_invoice_type       --請求書出力形式      
          ,bill_hsua_4.payment_term_id               AS bill_payment_term_id    --支払条件            
          ,bill_hsua_4.attribute2                    AS bill_payment_term2      --第2支払条件         
          ,bill_hsua_4.attribute3                    AS bill_payment_term3      --第3支払条件         
          ,bill_hsua_4.tax_rounding_rule             AS bill_tax_round_rule     --税金－端数処理      
          ,bill_hzad_4.sale_base_code                AS ship_sale_base_code     --売上拠点コード      
    FROM   hz_cust_accounts          ship_hzca_4              --出荷先顧客マスタ　※入金先・請求先含む
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    bill_hasa_4              --請求先顧客所在地
--          ,hz_cust_site_uses_all     bill_hsua_4              --請求先顧客使用目的
--          ,hz_cust_site_uses_all     ship_hsua_4              --出荷先顧客使用目的
          ,hz_cust_acct_sites        bill_hasa_4              --請求先顧客所在地
          ,hz_cust_site_uses         bill_hsua_4              --請求先顧客使用目的
          ,hz_cust_site_uses         ship_hsua_4              --出荷先顧客使用目的
-- Modify 2009.06.26 kayahara end          
          ,xxcmm_cust_accounts       bill_hzad_4              --請求先顧客追加情報
          ,hz_party_sites            bill_hzps_4              --請求先パーティサイト  
          ,hz_locations              bill_hzlo_4              --請求先顧客事業所      
          ,hz_customer_profiles      bill_hzcp_4              --請求先顧客プロファイル      
    WHERE  ship_hzca_4.customer_class_code = '10'             --請求先顧客.顧客区分 = '10'(顧客)
-- Modify 2009.06.26 kayahara start
--    AND    bill_hasa_4.org_id = fnd_profile.value('ORG_ID')   --請求先顧客所在地.組織ID = ログインユーザの組織ID
--    AND    bill_hsua_4.org_id = fnd_profile.value('ORG_ID')   --請求先顧客使用目的.組織ID = ログインユーザの組織ID
--    AND    ship_hsua_4.org_id = fnd_profile.value('ORG_ID')   --出荷先顧客使用目的.組織ID = ログインユーザの組織ID
-- Modify 2009.06.26 kayahara end
    AND    NOT EXISTS (
               SELECT ROWNUM
-- Modify 2009.06.26 kayahara start
--               FROM   hz_cust_acct_relate_all ex_hcar_4       --顧客関連マスタ
               FROM   hz_cust_acct_relate     ex_hcar_4       --顧客関連マスタ
-- Modify 2009.06.26 kayahara end               
               WHERE 
                     (ex_hcar_4.cust_account_id = ship_hzca_4.cust_account_id           --顧客関連マスタ(請求関連).顧客ID = 出荷先顧客マスタ.顧客ID
               OR     ex_hcar_4.related_cust_account_id = ship_hzca_4.cust_account_id)  --顧客関連マスタ(請求関連).関連先顧客ID = 出荷先顧客マスタ.顧客ID
               AND    ex_hcar_4.status = 'A'                                            --顧客関連マスタ(請求関連).ステータス = ‘A’
-- Modify 2009.06.26 kayahara start               
--               AND    ex_hcar_4.org_id = fnd_profile.value('ORG_ID')                    --請求先顧客所在地.組織ID = ログインユーザの組織ID
-- Modify 2009.06.26 kayahara end                    
-- Modify 2009.10.13 hirose start
               AND    ex_hcar_4.attribute1 = '2'                                        --顧客関連マスタ(請求関連).関連区分 = ‘2’(入金)
-- Modify 2009.10.13 hirose End
                    )
    AND    ship_hzca_4.cust_account_id = bill_hzad_4.customer_id             --請求先顧客マスタ.顧客ID = 顧客追加情報.顧客ID
    AND    ship_hzca_4.cust_account_id = bill_hasa_4.cust_account_id         --請求先顧客マスタ.顧客ID = 請求先顧客所在地.顧客ID
    AND    bill_hasa_4.cust_acct_site_id = bill_hsua_4.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 請求先顧客使用目的.顧客所在地ID
    AND    bill_hasa_4.cust_acct_site_id = ship_hsua_4.cust_acct_site_id     --請求先顧客所在地.顧客所在地ID = 出荷先顧客使用目的.顧客所在地ID
    AND    bill_hsua_4.site_use_code = 'BILL_TO'                             --請求先顧客使用目的.使用目的 = 'BILL_TO'(請求先)
-- Add 2010.01.29 Yasukawa Start
    AND    bill_hsua_4.status = 'A'                                          --請求先顧客使用目的.ステータス = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    ship_hsua_4.bill_to_site_use_id = bill_hsua_4.site_use_id         --出荷先顧客使用目的.請求先事業所ID = 請求先顧客使用目的.使用目的ID
-- Add 2010.01.29 Yasukawa Start
    AND    ship_hsua_4.status = 'A'                                          --出荷先顧客使用目的.ステータス = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    bill_hasa_4.party_site_id = bill_hzps_4.party_site_id             --請求先顧客所在地.パーティサイトID = 請求先パーティサイト.パーティサイトID  
    AND    bill_hzps_4.location_id = bill_hzlo_4.location_id                 --請求先パーティサイト.事業所ID = 請求先顧客事業所.事業所ID                  
    AND    bill_hsua_4.site_use_id = bill_hzcp_4.site_use_id(+)              --請求先顧客使用目的.使用目的ID = 請求先顧客プロファイル.使用目的ID
-- Modify 2009.08.03 hirose start
--)
) temp
-- Modify 2009.08.03 hirose end;
 