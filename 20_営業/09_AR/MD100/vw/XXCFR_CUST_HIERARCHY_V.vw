
  CREATE OR REPLACE FORCE VIEW "APPS"."XXCFR_CUST_HIERARCHY_V" ("CASH_ACCOUNT_ID", "CASH_ACCOUNT_NUMBER", "CASH_ACCOUNT_NAME", "BILL_ACCOUNT_ID", "BILL_ACCOUNT_NUMBER", "BILL_ACCOUNT_NAME", "SHIP_ACCOUNT_ID", "SHIP_ACCOUNT_NUMBER", "SHIP_ACCOUNT_NAME", "CASH_RECEIV_BASE_CODE", "BILL_PARTY_ID", "BILL_BILL_BASE_CODE", "BILL_POSTAL_CODE", "BILL_STATE", "BILL_CITY", "BILL_ADDRESS1", "BILL_ADDRESS2", "BILL_TEL_NUM", "BILL_CONS_INV_FLAG", "BILL_TORIHIKISAKI_CODE", "BILL_STORE_CODE", "BILL_CUST_STORE_NAME", "BILL_TAX_DIV", "BILL_CRED_REC_CODE1", "BILL_CRED_REC_CODE2", "BILL_CRED_REC_CODE3", "BILL_INVOICE_TYPE", "BILL_PAYMENT_TERM_ID", "BILL_PAYMENT_TERM2", "BILL_PAYMENT_TERM3", "BILL_TAX_ROUND_RULE", "SHIP_SALE_BASE_CODE") AS 
  SELECT 
-- Modify 2009.08.03 hirose start
--  SELECT cash_account_id                                  --������ڋqID        
--        ,cash_account_number                              --������ڋq�R�[�h    
--        ,xxcfr_common_pkg.get_cust_account_name(
--                            cash_account_number,
--                            0)                            --������ڋq����      
--        ,bill_account_id                                  --������ڋqID        
--        ,bill_account_number                              --������ڋq�R�[�h    
--        ,xxcfr_common_pkg.get_cust_account_name(
--                            bill_account_number,
--                            0)                            --������ڋq����      
--        ,ship_account_id                                  --�o�א�ڋqID        
--        ,ship_account_number                              --�o�א�ڋq�R�[�h    
--        ,xxcfr_common_pkg.get_cust_account_name(
--                            ship_account_number,
--                            0)                            --�o�א�ڋq����      
--        ,cash_receiv_base_code                            --�������_�R�[�h      
--        ,bill_party_id                                    --�p�[�e�BID          
--        ,bill_bill_base_code                              --�������_�R�[�h      
--        ,bill_postal_code                                 --�X�֔ԍ�            
--        ,bill_state                                       --�s���{��            
--        ,bill_city                                        --�s�E��              
--        ,bill_address1                                    --�Z��1               
--        ,bill_address2                                    --�Z��2               
--        ,bill_tel_num                                     --�d�b�ԍ�            
--        ,bill_cons_inv_flag                               --�ꊇ���������s�t���O
--        ,bill_torihikisaki_code                           --�����R�[�h        
--        ,bill_store_code                                  --�X�܃R�[�h          
--        ,bill_cust_store_name                             --�ڋq�X�ܖ���        
--        ,bill_tax_div                                     --����ŋ敪          
--        ,bill_cred_rec_code1                              --���|�R�[�h1(������) 
--        ,bill_cred_rec_code2                              --���|�R�[�h2(���Ə�) 
--        ,bill_cred_rec_code3                              --���|�R�[�h3(���̑�) 
--        ,bill_invoice_type                                --�������o�͌`��      
--        ,bill_payment_term_id                             --�x������            
--        ,TO_NUMBER(bill_payment_term2)                    --��2�x������         
--        ,TO_NUMBER(bill_payment_term3)                    --��3�x������         
--        ,bill_tax_round_rule                              --�ŋ��|�[������      
--        ,ship_sale_base_code                              --���㋒�_�R�[�h      
         temp.cash_account_id                          AS cash_account_id        --������ڋqID        
        ,temp.cash_account_number                      AS cash_account_number    --������ڋq�R�[�h    
        ,xxcfr_common_pkg.get_cust_account_name(
                            temp.cash_account_number,
                            0)                         AS cash_account_name      --������ڋq����      
        ,temp.bill_account_id                          AS bill_account_id        --������ڋqID        
        ,temp.bill_account_number                      AS bill_account_number    --������ڋq�R�[�h    
        ,xxcfr_common_pkg.get_cust_account_name(
                            temp.bill_account_number,
                            0)                         AS bill_account_name      --������ڋq����      
        ,temp.ship_account_id                          AS ship_account_id        --�o�א�ڋqID        
        ,temp.ship_account_number                      AS ship_account_number    --�o�א�ڋq�R�[�h    
        ,xxcfr_common_pkg.get_cust_account_name(
                            temp.ship_account_number,
                            0)                         AS ship_account_name      --�o�א�ڋq����      
        ,temp.cash_receiv_base_code                    AS cash_receiv_base_code  --�������_�R�[�h      
        ,temp.bill_party_id                            AS bill_party_id          --�p�[�e�BID          
        ,temp.bill_bill_base_code                      AS bill_bill_base_code    --�������_�R�[�h      
        ,temp.bill_postal_code                         AS bill_postal_code       --�X�֔ԍ�            
        ,temp.bill_state                               AS bill_state             --�s���{��            
        ,temp.bill_city                                AS bill_city              --�s�E��              
        ,temp.bill_address1                            AS bill_address1          --�Z��1               
        ,temp.bill_address2                            AS bill_address2          --�Z��2               
        ,temp.bill_tel_num                             AS bill_tel_num           --�d�b�ԍ�            
        ,temp.bill_cons_inv_flag                       AS bill_cons_inv_flag     --�ꊇ���������s�t���O
        ,temp.bill_torihikisaki_code                   AS bill_torihikisaki_code --�����R�[�h        
        ,temp.bill_store_code                          AS bill_store_code        --�X�܃R�[�h          
        ,temp.bill_cust_store_name                     AS bill_cust_store_name   --�ڋq�X�ܖ���        
        ,temp.bill_tax_div                             AS bill_tax_div           --����ŋ敪          
        ,temp.bill_cred_rec_code1                      AS bill_cred_rec_code1    --���|�R�[�h1(������) 
        ,temp.bill_cred_rec_code2                      AS bill_cred_rec_code2    --���|�R�[�h2(���Ə�) 
        ,temp.bill_cred_rec_code3                      AS bill_cred_rec_code3    --���|�R�[�h3(���̑�) 
        ,temp.bill_invoice_type                        AS bill_invoice_type      --�������o�͌`��      
        ,temp.bill_payment_term_id                     AS bill_payment_term_id   --�x������            
        ,TO_NUMBER(temp.bill_payment_term2)            AS bill_payment_term2     --��2�x������         
        ,TO_NUMBER(temp.bill_payment_term3)            AS bill_payment_term3     --��3�x������         
        ,temp.bill_tax_round_rule                      AS bill_tax_round_rule    --�ŋ��|�[������      
        ,temp.ship_sale_base_code                      AS ship_sale_base_code    --���㋒�_�R�[�h      
-- Modify 2009.08.03 hirose End
  FROM   (
  --�@������ڋq��������ڋq�|�o�א�ڋq
    SELECT bill_hzca_1.cust_account_id         AS cash_account_id         --������ڋqID        
          ,bill_hzca_1.account_number          AS cash_account_number     --������ڋq�R�[�h    
          ,bill_hzca_1.cust_account_id         AS bill_account_id         --������ڋqID        
          ,bill_hzca_1.account_number          AS bill_account_number     --������ڋq�R�[�h    
          ,ship_hzca_1.cust_account_id         AS ship_account_id         --�o�א�ڋqID        
          ,ship_hzca_1.account_number          AS ship_account_number     --�o�א�ڋq�R�[�h    
          ,bill_hzad_1.receiv_base_code        AS cash_receiv_base_code   --�������_�R�[�h      
          ,bill_hzca_1.party_id                AS bill_party_id           --�p�[�e�BID          
          ,bill_hzad_1.bill_base_code          AS bill_bill_base_code     --�������_�R�[�h      
          ,bill_hzlo_1.postal_code             AS bill_postal_code        --�X�֔ԍ�            
          ,bill_hzlo_1.state                   AS bill_state              --�s���{��            
          ,bill_hzlo_1.city                    AS bill_city               --�s�E��              
          ,bill_hzlo_1.address1                AS bill_address1           --�Z��1               
          ,bill_hzlo_1.address2                AS bill_address2           --�Z��2               
          ,bill_hzlo_1.address_lines_phonetic  AS bill_tel_num            --�d�b�ԍ�            
          ,bill_hzcp_1.cons_inv_flag           AS bill_cons_inv_flag      --�ꊇ���������s�t���O
          ,bill_hzad_1.torihikisaki_code       AS bill_torihikisaki_code  --�����R�[�h        
          ,bill_hzad_1.store_code              AS bill_store_code         --�X�܃R�[�h          
          ,bill_hzad_1.cust_store_name         AS bill_cust_store_name    --�ڋq�X�ܖ���        
          ,bill_hzad_1.tax_div                 AS bill_tax_div            --����ŋ敪          
          ,bill_hsua_1.attribute4              AS bill_cred_rec_code1     --���|�R�[�h1(������) 
          ,bill_hsua_1.attribute5              AS bill_cred_rec_code2     --���|�R�[�h2(���Ə�) 
          ,bill_hsua_1.attribute6              AS bill_cred_rec_code3     --���|�R�[�h3(���̑�) 
          ,bill_hsua_1.attribute7              AS bill_invoice_type       --�������o�͌`��      
          ,bill_hsua_1.payment_term_id         AS bill_payment_term_id    --�x������            
          ,bill_hsua_1.attribute2              AS bill_payment_term2      --��2�x������         
          ,bill_hsua_1.attribute3              AS bill_payment_term3      --��3�x������         
          ,bill_hsua_1.tax_rounding_rule       AS bill_tax_round_rule     --�ŋ��|�[������      
          ,ship_hzad_1.sale_base_code          AS ship_sale_base_code     --���㋒�_�R�[�h      
    FROM   hz_cust_accounts          bill_hzca_1              --������ڋq�}�X�^
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    bill_hasa_1              --������ڋq���ݒn
--          ,hz_cust_site_uses_all     bill_hsua_1              --������ڋq�g�p�ړI
          ,hz_cust_acct_sites        bill_hasa_1              --������ڋq���ݒn
          ,hz_cust_site_uses         bill_hsua_1              --������ڋq�g�p�ړI
-- Modify 2009.06.26 kayahara end
          ,xxcmm_cust_accounts       bill_hzad_1              --������ڋq�ǉ����
          ,hz_party_sites            bill_hzps_1              --������p�[�e�B�T�C�g  
          ,hz_locations              bill_hzlo_1              --������ڋq���Ə�      
          ,hz_customer_profiles      bill_hzcp_1              --������ڋq�v���t�@�C��
          ,hz_cust_accounts          ship_hzca_1              --�o�א�ڋq�}�X�^
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    ship_hasa_1              --�o�א�ڋq���ݒn
--          ,hz_cust_site_uses_all     ship_hsua_1              --�o�א�ڋq�g�p�ړI
          ,hz_cust_acct_sites        ship_hasa_1              --�o�א�ڋq���ݒn
          ,hz_cust_site_uses         ship_hsua_1              --�o�א�ڋq�g�p�ړI
-- Modify 2009.06.26 kayahara end
          ,xxcmm_cust_accounts       ship_hzad_1              --�o�א�ڋq�ǉ����
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_relate_all   bill_hcar_1              --�ڋq�֘A�}�X�^(�����֘A)
          ,hz_cust_acct_relate       bill_hcar_1              --�ڋq�֘A�}�X�^(�����֘A)
-- Modify 2009.06.26 kayahara end
    WHERE  bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^.�ڋqID
    AND    bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --�ڋq�֘A�}�X�^.�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
    AND    bill_hzca_1.customer_class_code = '14'                            --������ڋq.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
    AND    bill_hcar_1.status = 'A'                                          --�ڋq�֘A�}�X�^.�X�e�[�^�X = �eA�f
    AND    bill_hcar_1.attribute1 = '1'                                      --�ڋq�֘A�}�X�^.�֘A���� = �e1�f (����)
-- Modify 2009.06.26 kayahara start    
--    AND    bill_hasa_1.org_id = fnd_profile.value('ORG_ID')                  --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
--    AND    ship_hasa_1.org_id = fnd_profile.value('ORG_ID')                  --�o�א�ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
--    AND    bill_hcar_1.org_id = fnd_profile.value('ORG_ID')                  --�ڋq�֘A�}�X�^(�����֘A).�g�DID = ���O�C�����[�U�̑g�DID
--    AND    bill_hsua_1.org_id = fnd_profile.value('ORG_ID')                  --������ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
--    AND    ship_hsua_1.org_id = fnd_profile.value('ORG_ID')                  --�o�א�ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
-- Modify 2009.06.26 kayahara end   
    AND    bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
    AND    bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hsua_1.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
-- Add 2010.01.29 Yasukawa Start
    AND    bill_hsua_1.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq���ݒn.�ڋqID
    AND    ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --�o�א�ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
-- Add 2010.01.29 Yasukawa Start
    AND    ship_hsua_1.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
    AND    ship_hzca_1.cust_account_id = ship_hzad_1.customer_id             --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq�ǉ����.�ڋqID
    AND    bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID  
    AND    bill_hzps_1.location_id = bill_hzlo_1.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID                  
    AND    bill_hsua_1.site_use_id = bill_hzcp_1.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
    AND NOT EXISTS (
                SELECT 'X'
-- Modify 2009.06.26 kayahara start                
--                FROM   hz_cust_acct_relate_all   cash_hcar_1   --�ڋq�֘A�}�X�^(�����֘A)
                FROM   hz_cust_acct_relate       cash_hcar_1   --�ڋq�֘A�}�X�^(�����֘A)
-- Modify 2009.06.26 kayahara end
                WHERE  cash_hcar_1.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
                AND    cash_hcar_1.attribute1 = '2'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
                AND    cash_hcar_1.related_cust_account_id = bill_hzca_1.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = ������ڋq�}�X�^.�ڋqID
-- Modify 2009.06.26 kayahara start                 
--                AND    cash_hcar_1.org_id = fnd_profile.value('ORG_ID')                  --�ڋq�֘A�}�X�^(�����֘A).�g�DID = ���O�C�����[�U�̑g�DID
-- Modify 2009.06.26 kayahara end                     
                     )
    UNION ALL
    --�A������ڋq�|������ڋq�|�o�א�ڋq
    SELECT cash_hzca_2.cust_account_id           AS cash_account_id         --������ڋqID        
          ,cash_hzca_2.account_number            AS cash_account_number     --������ڋq�R�[�h    
          ,bill_hzca_2.cust_account_id           AS bill_account_id         --������ڋqID        
          ,bill_hzca_2.account_number            AS bill_account_number     --������ڋq�R�[�h    
          ,ship_hzca_2.cust_account_id           AS ship_account_id         --�o�א�ڋqID        
          ,ship_hzca_2.account_number            AS ship_account_number     --�o�א�ڋq�R�[�h    
          ,cash_hzad_2.receiv_base_code          AS cash_receiv_base_code   --�������_�R�[�h      
          ,bill_hzca_2.party_id                  AS bill_party_id           --�p�[�e�BID          
          ,bill_hzad_2.bill_base_code            AS bill_bill_base_code     --�������_�R�[�h      
          ,bill_hzlo_2.postal_code               AS bill_postal_code        --�X�֔ԍ�            
          ,bill_hzlo_2.state                     AS bill_state              --�s���{��            
          ,bill_hzlo_2.city                      AS bill_city               --�s�E��              
          ,bill_hzlo_2.address1                  AS bill_address1           --�Z��1               
          ,bill_hzlo_2.address2                  AS bill_address2           --�Z��2               
          ,bill_hzlo_2.address_lines_phonetic    AS bill_tel_num            --�d�b�ԍ�            
          ,bill_hzcp_2.cons_inv_flag             AS bill_cons_inv_flag      --�ꊇ���������s�t���O
          ,bill_hzad_2.torihikisaki_code         AS bill_torihikisaki_code  --�����R�[�h        
          ,bill_hzad_2.store_code                AS bill_store_code         --�X�܃R�[�h          
          ,bill_hzad_2.cust_store_name           AS bill_cust_store_name    --�ڋq�X�ܖ���        
          ,bill_hzad_2.tax_div                   AS bill_tax_div            --����ŋ敪          
          ,bill_hsua_2.attribute4                AS bill_cred_rec_code1     --���|�R�[�h1(������) 
          ,bill_hsua_2.attribute5                AS bill_cred_rec_code2     --���|�R�[�h2(���Ə�) 
          ,bill_hsua_2.attribute6                AS bill_cred_rec_code3     --���|�R�[�h3(���̑�) 
          ,bill_hsua_2.attribute7                AS bill_invoice_type       --�������o�͌`��      
          ,bill_hsua_2.payment_term_id           AS bill_payment_term_id    --�x������            
          ,bill_hsua_2.attribute2                AS bill_payment_term2      --��2�x������         
          ,bill_hsua_2.attribute3                AS bill_payment_term3      --��3�x������         
          ,bill_hsua_2.tax_rounding_rule         AS bill_tax_round_rule     --�ŋ��|�[������      
          ,ship_hzad_2.sale_base_code            AS ship_sale_base_code     --���㋒�_�R�[�h      
    FROM   hz_cust_accounts          cash_hzca_2              --������ڋq�}�X�^
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    cash_hasa_2              --������ڋq���ݒn
          ,hz_cust_acct_sites        cash_hasa_2              --������ڋq���ݒn
-- Modify 2009.06.26 kayahara end
          ,xxcmm_cust_accounts       cash_hzad_2              --������ڋq�ǉ����
          ,hz_cust_accounts          bill_hzca_2              --������ڋq�}�X�^
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    bill_hasa_2              --������ڋq���ݒn
--          ,hz_cust_site_uses_all     bill_hsua_2              --������ڋq�g�p�ړI
          ,hz_cust_acct_sites        bill_hasa_2              --������ڋq���ݒn
          ,hz_cust_site_uses         bill_hsua_2              --������ڋq�g�p�ړI
-- Modify 2009.06.26 kayahara end          
          ,xxcmm_cust_accounts       bill_hzad_2              --������ڋq�ǉ����
          ,hz_party_sites            bill_hzps_2              --������p�[�e�B�T�C�g  
          ,hz_locations              bill_hzlo_2              --������ڋq���Ə�      
          ,hz_customer_profiles      bill_hzcp_2              --������ڋq�v���t�@�C��      
          ,hz_cust_accounts          ship_hzca_2              --�o�א�ڋq�}�X�^
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    ship_hasa_2              --�o�א�ڋq���ݒn
--          ,hz_cust_site_uses_all     ship_hsua_2              --�o�א�ڋq�g�p�ړI
          ,hz_cust_acct_sites        ship_hasa_2              --�o�א�ڋq���ݒn
          ,hz_cust_site_uses         ship_hsua_2              --�o�א�ڋq�g�p�ړI
-- Modify 2009.06.26 kayahara end           
          ,xxcmm_cust_accounts       ship_hzad_2              --�o�א�ڋq�ǉ����
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_relate_all   cash_hcar_2              --�ڋq�֘A�}�X�^(�����֘A)
--          ,hz_cust_acct_relate_all   bill_hcar_2              --�ڋq�֘A�}�X�^(�����֘A)
          ,hz_cust_acct_relate       cash_hcar_2              --�ڋq�֘A�}�X�^(�����֘A)
          ,hz_cust_acct_relate       bill_hcar_2              --�ڋq�֘A�}�X�^(�����֘A)
-- Modify 2009.06.26 kayahara end            
    WHERE  cash_hzca_2.cust_account_id = cash_hcar_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^(�����֘A).�ڋqID
    AND    cash_hzca_2.cust_account_id = cash_hzad_2.customer_id             --������ڋq�}�X�^.�ڋqID = ������ڋq�ǉ����.�ڋqID
    AND    cash_hcar_2.related_cust_account_id = bill_hzca_2.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = ������ڋq�}�X�^.�ڋqID
    AND    bill_hzca_2.cust_account_id = bill_hcar_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^(�����֘A).�ڋqID
    AND    bill_hcar_2.related_cust_account_id = ship_hzca_2.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
    AND    cash_hzca_2.customer_class_code = '14'                            --������ڋq.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
    AND    ship_hzca_2.customer_class_code = '10'                            --������ڋq.�ڋq�敪 = '10'(�ڋq)
    AND    cash_hcar_2.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
    AND    cash_hcar_2.attribute1 = '2'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
    AND    bill_hcar_2.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
    AND    bill_hcar_2.attribute1 = '1'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e1�f (����)
-- Modify 2009.06.26 kayahara start    
--    AND    cash_hasa_2.org_id = fnd_profile.value('ORG_ID')                  --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
--    AND    bill_hasa_2.org_id = fnd_profile.value('ORG_ID')                  --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
--    AND    ship_hasa_2.org_id = fnd_profile.value('ORG_ID')                  --�o�א�ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
--    AND    cash_hcar_2.org_id = fnd_profile.value('ORG_ID')                  --�ڋq�֘A�}�X�^(�����֘A).�g�DID = ���O�C�����[�U�̑g�DID
--    AND    bill_hcar_2.org_id = fnd_profile.value('ORG_ID')                  --�ڋq�֘A�}�X�^(�����֘A).�g�DID = ���O�C�����[�U�̑g�DID
--    AND    bill_hsua_2.org_id = fnd_profile.value('ORG_ID')                  --������ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
--    AND    ship_hsua_2.org_id = fnd_profile.value('ORG_ID')                  --�o�א�ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
-- Modify 2009.06.26 kayahara end    
    AND    bill_hzca_2.cust_account_id = bill_hzad_2.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
    AND    bill_hzca_2.cust_account_id = bill_hasa_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_2.cust_acct_site_id = bill_hsua_2.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hsua_2.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
-- Add 2010.01.29 Yasukawa Start
    AND    bill_hsua_2.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    cash_hzca_2.cust_account_id = cash_hasa_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    ship_hzca_2.cust_account_id = ship_hzad_2.customer_id             --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq�ǉ����.�ڋqID
    AND    ship_hzca_2.cust_account_id = ship_hasa_2.cust_account_id         --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq���ݒn.�ڋqID
    AND    ship_hasa_2.cust_acct_site_id = ship_hsua_2.cust_acct_site_id     --�o�א�ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
-- Add 2010.01.29 Yasukawa Start
    AND    ship_hsua_2.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    ship_hsua_2.bill_to_site_use_id = bill_hsua_2.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
    AND    bill_hasa_2.party_site_id = bill_hzps_2.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID  
    AND    bill_hzps_2.location_id = bill_hzlo_2.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID                  
    AND    bill_hsua_2.site_use_id = bill_hzcp_2.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
    UNION ALL
    --�B������ڋq�|������ڋq���o�א�ڋq
    SELECT cash_hzca_3.cust_account_id             AS cash_account_id         --������ڋqID        
          ,cash_hzca_3.account_number              AS cash_account_number     --������ڋq�R�[�h    
          ,ship_hzca_3.cust_account_id             AS bill_account_id         --������ڋqID        
          ,ship_hzca_3.account_number              AS bill_account_number     --������ڋq�R�[�h    
          ,ship_hzca_3.cust_account_id             AS ship_account_id         --�o�א�ڋqID        
          ,ship_hzca_3.account_number              AS ship_account_number     --�o�א�ڋq�R�[�h    
          ,cash_hzad_3.receiv_base_code            AS cash_receiv_base_code   --�������_�R�[�h      
          ,ship_hzca_3.party_id                    AS bill_party_id           --�p�[�e�BID          
          ,bill_hzad_3.bill_base_code              AS bill_bill_base_code     --�������_�R�[�h      
          ,bill_hzlo_3.postal_code                 AS bill_postal_code        --�X�֔ԍ�            
          ,bill_hzlo_3.state                       AS bill_state              --�s���{��            
          ,bill_hzlo_3.city                        AS bill_city               --�s�E��              
          ,bill_hzlo_3.address1                    AS bill_address1           --�Z��1               
          ,bill_hzlo_3.address2                    AS bill_address2           --�Z��2               
          ,bill_hzlo_3.address_lines_phonetic      AS bill_tel_num            --�d�b�ԍ�            
          ,bill_hzcp_3.cons_inv_flag               AS bill_cons_inv_flag      --�ꊇ���������s�t���O
          ,bill_hzad_3.torihikisaki_code           AS bill_torihikisaki_code  --�����R�[�h        
          ,bill_hzad_3.store_code                  AS bill_store_code         --�X�܃R�[�h          
          ,bill_hzad_3.cust_store_name             AS bill_cust_store_name    --�ڋq�X�ܖ���        
          ,bill_hzad_3.tax_div                     AS bill_tax_div            --����ŋ敪          
          ,bill_hsua_3.attribute4                  AS bill_cred_rec_code1     --���|�R�[�h1(������) 
          ,bill_hsua_3.attribute5                  AS bill_cred_rec_code2     --���|�R�[�h2(���Ə�) 
          ,bill_hsua_3.attribute6                  AS bill_cred_rec_code3     --���|�R�[�h3(���̑�) 
          ,bill_hsua_3.attribute7                  AS bill_invoice_type       --�������o�͌`��      
          ,bill_hsua_3.payment_term_id             AS bill_payment_term_id    --�x������            
          ,bill_hsua_3.attribute2                  AS bill_payment_term2      --��2�x������         
          ,bill_hsua_3.attribute3                  AS bill_payment_term3      --��3�x������         
          ,bill_hsua_3.tax_rounding_rule           AS bill_tax_round_rule     --�ŋ��|�[������      
          ,bill_hzad_3.sale_base_code              AS ship_sale_base_code     --���㋒�_�R�[�h      
    FROM   hz_cust_accounts          cash_hzca_3              --������ڋq�}�X�^
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    cash_hasa_3              --������ڋq���ݒn
          ,hz_cust_acct_sites        cash_hasa_3              --������ڋq���ݒn
-- Modify 2009.06.26 kayahara end         
          ,xxcmm_cust_accounts       cash_hzad_3              --������ڋq�ǉ����
          ,hz_cust_accounts          ship_hzca_3              --�o�א�ڋq�}�X�^�@��������܂�
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    bill_hasa_3              --������ڋq���ݒn
--          ,hz_cust_site_uses_all     bill_hsua_3              --������ڋq�g�p�ړI
--          ,hz_cust_site_uses_all     ship_hsua_3              --�o�א�ڋq�g�p�ړI
          ,hz_cust_acct_sites        bill_hasa_3              --������ڋq���ݒn
          ,hz_cust_site_uses         bill_hsua_3              --������ڋq�g�p�ړI
          ,hz_cust_site_uses         ship_hsua_3              --�o�א�ڋq�g�p�ړI
-- Modify 2009.06.26 kayahara end           
          ,xxcmm_cust_accounts       bill_hzad_3              --������ڋq�ǉ����
          ,hz_party_sites            bill_hzps_3              --������p�[�e�B�T�C�g  
          ,hz_locations              bill_hzlo_3              --������ڋq���Ə�      
          ,hz_customer_profiles      bill_hzcp_3              --������ڋq�v���t�@�C�� 
-- Modify 2009.06.26 kayahara start     
--          ,hz_cust_acct_relate_all   cash_hcar_3              --�ڋq�֘A�}�X�^(�����֘A)
          ,hz_cust_acct_relate       cash_hcar_3              --�ڋq�֘A�}�X�^(�����֘A)
-- Modify 2009.06.26 kayahara end           
    WHERE  cash_hzca_3.cust_account_id = cash_hcar_3.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^(�����֘A).�ڋqID
    AND    cash_hzca_3.cust_account_id = cash_hzad_3.customer_id             --������ڋq�}�X�^.�ڋqID = ������ڋq�ǉ����.�ڋqID
    AND    cash_hcar_3.related_cust_account_id = ship_hzca_3.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
    AND    cash_hzca_3.customer_class_code = '14'                            --������ڋq.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
    AND    ship_hzca_3.customer_class_code = '10'                            --������ڋq.�ڋq�敪 = '10'(�ڋq)
    AND    cash_hcar_3.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
    AND    cash_hcar_3.attribute1 = '2'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
-- Modify 2009.06.26 kayahara start   
--    AND    cash_hasa_3.org_id = fnd_profile.value('ORG_ID')                  --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
--    AND    bill_hasa_3.org_id = fnd_profile.value('ORG_ID')                  --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
--    AND    cash_hcar_3.org_id = fnd_profile.value('ORG_ID')                  --�ڋq�֘A�}�X�^(�����֘A).�g�DID = ���O�C�����[�U�̑g�DID
--    AND    bill_hsua_3.org_id = fnd_profile.value('ORG_ID')                  --������ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
--    AND    ship_hsua_3.org_id = fnd_profile.value('ORG_ID')                  --�o�א�ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
-- Modify 2009.06.26 kayahara end    
    AND    NOT EXISTS (
               SELECT ROWNUM
-- Modify 2009.06.26 kayahara start
--               FROM   hz_cust_acct_relate_all ex_hcar_3       --�ڋq�֘A�}�X�^(�����֘A)
               FROM   hz_cust_acct_relate     ex_hcar_3       --�ڋq�֘A�}�X�^(�����֘A)
-- Modify 2009.06.26 kayahara end                 
               WHERE  ex_hcar_3.cust_account_id = ship_hzca_3.cust_account_id         --�ڋq�֘A�}�X�^(�����֘A).�ڋqID = �o�א�ڋq�}�X�^.�ڋqID
               AND    ex_hcar_3.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
-- Modify 2009.06.26 kayahara start               
--               AND    ex_hcar_3.org_id = fnd_profile.value('ORG_ID')                  --�ڋq�֘A�}�X�^(�����֘A).�g�DID = ���O�C�����[�U�̑g�DID
-- Modify 2009.06.26 kayahara end                    
                    )
    AND    ship_hzca_3.cust_account_id = bill_hzad_3.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
    AND    ship_hzca_3.cust_account_id = bill_hasa_3.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_3.cust_acct_site_id = bill_hsua_3.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hasa_3.cust_acct_site_id = ship_hsua_3.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hsua_3.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
-- Add 2010.01.29 Yasukawa Start
    AND    bill_hsua_3.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = 'A'
-- Add 2010.01.29 Yasukawa End
-- Add 2010.01.29 Yasukawa Start
    AND    ship_hsua_3.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    ship_hsua_3.bill_to_site_use_id = bill_hsua_3.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
    AND    cash_hzca_3.cust_account_id = cash_hasa_3.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_3.party_site_id = bill_hzps_3.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID  
    AND    bill_hzps_3.location_id = bill_hzlo_3.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID                  
    AND    bill_hsua_3.site_use_id = bill_hzcp_3.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
    UNION ALL
    --�C������ڋq��������ڋq���o�א�ڋq
    SELECT ship_hzca_4.cust_account_id               AS cash_account_id         --������ڋqID        
          ,ship_hzca_4.account_number                AS cash_account_number     --������ڋq�R�[�h    
          ,ship_hzca_4.cust_account_id               AS bill_account_id         --������ڋqID        
          ,ship_hzca_4.account_number                AS bill_account_number     --������ڋq�R�[�h    
          ,ship_hzca_4.cust_account_id               AS ship_account_id         --�o�א�ڋqID        
          ,ship_hzca_4.account_number                AS ship_account_number     --�o�א�ڋq�R�[�h    
          ,bill_hzad_4.receiv_base_code              AS cash_receiv_base_code   --�������_�R�[�h      
          ,ship_hzca_4.party_id                      AS bill_party_id           --�p�[�e�BID          
          ,bill_hzad_4.bill_base_code                AS bill_bill_base_code     --�������_�R�[�h      
          ,bill_hzlo_4.postal_code                   AS bill_postal_code        --�X�֔ԍ�            
          ,bill_hzlo_4.state                         AS bill_state              --�s���{��            
          ,bill_hzlo_4.city                          AS bill_city               --�s�E��              
          ,bill_hzlo_4.address1                      AS bill_address1           --�Z��1               
          ,bill_hzlo_4.address2                      AS bill_address2           --�Z��2               
          ,bill_hzlo_4.address_lines_phonetic        AS bill_tel_num            --�d�b�ԍ�            
          ,bill_hzcp_4.cons_inv_flag                 AS bill_cons_inv_flag      --�ꊇ���������s�t���O
          ,bill_hzad_4.torihikisaki_code             AS bill_torihikisaki_code  --�����R�[�h        
          ,bill_hzad_4.store_code                    AS bill_store_code         --�X�܃R�[�h          
          ,bill_hzad_4.cust_store_name               AS bill_cust_store_name    --�ڋq�X�ܖ���        
          ,bill_hzad_4.tax_div                       AS bill_tax_div            --����ŋ敪          
          ,bill_hsua_4.attribute4                    AS bill_cred_rec_code1     --���|�R�[�h1(������) 
          ,bill_hsua_4.attribute5                    AS bill_cred_rec_code2     --���|�R�[�h2(���Ə�) 
          ,bill_hsua_4.attribute6                    AS bill_cred_rec_code3     --���|�R�[�h3(���̑�) 
          ,bill_hsua_4.attribute7                    AS bill_invoice_type       --�������o�͌`��      
          ,bill_hsua_4.payment_term_id               AS bill_payment_term_id    --�x������            
          ,bill_hsua_4.attribute2                    AS bill_payment_term2      --��2�x������         
          ,bill_hsua_4.attribute3                    AS bill_payment_term3      --��3�x������         
          ,bill_hsua_4.tax_rounding_rule             AS bill_tax_round_rule     --�ŋ��|�[������      
          ,bill_hzad_4.sale_base_code                AS ship_sale_base_code     --���㋒�_�R�[�h      
    FROM   hz_cust_accounts          ship_hzca_4              --�o�א�ڋq�}�X�^�@��������E������܂�
-- Modify 2009.06.26 kayahara start
--          ,hz_cust_acct_sites_all    bill_hasa_4              --������ڋq���ݒn
--          ,hz_cust_site_uses_all     bill_hsua_4              --������ڋq�g�p�ړI
--          ,hz_cust_site_uses_all     ship_hsua_4              --�o�א�ڋq�g�p�ړI
          ,hz_cust_acct_sites        bill_hasa_4              --������ڋq���ݒn
          ,hz_cust_site_uses         bill_hsua_4              --������ڋq�g�p�ړI
          ,hz_cust_site_uses         ship_hsua_4              --�o�א�ڋq�g�p�ړI
-- Modify 2009.06.26 kayahara end          
          ,xxcmm_cust_accounts       bill_hzad_4              --������ڋq�ǉ����
          ,hz_party_sites            bill_hzps_4              --������p�[�e�B�T�C�g  
          ,hz_locations              bill_hzlo_4              --������ڋq���Ə�      
          ,hz_customer_profiles      bill_hzcp_4              --������ڋq�v���t�@�C��      
    WHERE  ship_hzca_4.customer_class_code = '10'             --������ڋq.�ڋq�敪 = '10'(�ڋq)
-- Modify 2009.06.26 kayahara start
--    AND    bill_hasa_4.org_id = fnd_profile.value('ORG_ID')   --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
--    AND    bill_hsua_4.org_id = fnd_profile.value('ORG_ID')   --������ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
--    AND    ship_hsua_4.org_id = fnd_profile.value('ORG_ID')   --�o�א�ڋq�g�p�ړI.�g�DID = ���O�C�����[�U�̑g�DID
-- Modify 2009.06.26 kayahara end
    AND    NOT EXISTS (
               SELECT ROWNUM
-- Modify 2009.06.26 kayahara start
--               FROM   hz_cust_acct_relate_all ex_hcar_4       --�ڋq�֘A�}�X�^
               FROM   hz_cust_acct_relate     ex_hcar_4       --�ڋq�֘A�}�X�^
-- Modify 2009.06.26 kayahara end               
               WHERE 
                     (ex_hcar_4.cust_account_id = ship_hzca_4.cust_account_id           --�ڋq�֘A�}�X�^(�����֘A).�ڋqID = �o�א�ڋq�}�X�^.�ڋqID
               OR     ex_hcar_4.related_cust_account_id = ship_hzca_4.cust_account_id)  --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
               AND    ex_hcar_4.status = 'A'                                            --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
-- Modify 2009.06.26 kayahara start               
--               AND    ex_hcar_4.org_id = fnd_profile.value('ORG_ID')                    --������ڋq���ݒn.�g�DID = ���O�C�����[�U�̑g�DID
-- Modify 2009.06.26 kayahara end                    
-- Modify 2009.10.13 hirose start
               AND    ex_hcar_4.attribute1 = '2'                                        --�ڋq�֘A�}�X�^(�����֘A).�֘A�敪 = �e2�f(����)
-- Modify 2009.10.13 hirose End
                    )
    AND    ship_hzca_4.cust_account_id = bill_hzad_4.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
    AND    ship_hzca_4.cust_account_id = bill_hasa_4.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_4.cust_acct_site_id = bill_hsua_4.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hasa_4.cust_acct_site_id = ship_hsua_4.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hsua_4.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
-- Add 2010.01.29 Yasukawa Start
    AND    bill_hsua_4.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    ship_hsua_4.bill_to_site_use_id = bill_hsua_4.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
-- Add 2010.01.29 Yasukawa Start
    AND    ship_hsua_4.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
-- Add 2010.01.29 Yasukawa End
    AND    bill_hasa_4.party_site_id = bill_hzps_4.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID  
    AND    bill_hzps_4.location_id = bill_hzlo_4.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID                  
    AND    bill_hsua_4.site_use_id = bill_hzcp_4.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
-- Modify 2009.08.03 hirose start
--)
) temp
-- Modify 2009.08.03 hirose end;
 