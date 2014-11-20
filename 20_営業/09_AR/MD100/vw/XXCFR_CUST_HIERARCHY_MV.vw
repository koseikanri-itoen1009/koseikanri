/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCFR_CUST_HIERARCHY_MV
 * Description     : �����ڋq�K�w�}�e���A���C�Y�h�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010-10-27    1.0   SCS.Hirose      �V�K�쐬
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
  --�@������ڋq��������ڋq�|�o�א�ڋq
SELECT temp.cash_account_id     AS cash_account_id    
      ,temp.cash_account_number AS cash_account_number
      ,temp.bill_account_id     AS bill_account_id    
      ,temp.bill_account_number AS bill_account_number
FROM  (
    SELECT bill_hzca_1.cust_account_id         AS cash_account_id         --������ڋqID        
          ,bill_hzca_1.account_number          AS cash_account_number     --������ڋq�R�[�h    
          ,bill_hzca_1.cust_account_id         AS bill_account_id         --������ڋqID        
          ,bill_hzca_1.account_number          AS bill_account_number     --������ڋq�R�[�h    
    FROM   hz_cust_accounts          bill_hzca_1              --������ڋq�}�X�^
          ,hz_cust_acct_sites_all    bill_hasa_1              --������ڋq���ݒn
          ,hz_cust_site_uses_all     bill_hsua_1              --������ڋq�g�p�ړI
          ,xxcmm_cust_accounts       bill_hzad_1              --������ڋq�ǉ����
          ,hz_party_sites            bill_hzps_1              --������p�[�e�B�T�C�g  
          ,hz_locations              bill_hzlo_1              --������ڋq���Ə�      
          ,hz_customer_profiles      bill_hzcp_1              --������ڋq�v���t�@�C��
          ,hz_cust_accounts          ship_hzca_1              --�o�א�ڋq�}�X�^
          ,hz_cust_acct_sites_all    ship_hasa_1              --�o�א�ڋq���ݒn
          ,hz_cust_site_uses_all     ship_hsua_1              --�o�א�ڋq�g�p�ړI
          ,xxcmm_cust_accounts       ship_hzad_1              --�o�א�ڋq�ǉ����
          ,hz_cust_acct_relate_all   bill_hcar_1              --�ڋq�֘A�}�X�^(�����֘A)
          ,hr_all_organization_units org_units                --�g�D�P��
    WHERE  bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^.�ڋqID
    AND    bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --�ڋq�֘A�}�X�^.�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
    AND    bill_hzca_1.customer_class_code = '14'                            --������ڋq.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
    AND    bill_hcar_1.status = 'A'                                          --�ڋq�֘A�}�X�^.�X�e�[�^�X = �eA�f
    AND    bill_hcar_1.attribute1 = '1'                                      --�ڋq�֘A�}�X�^.�֘A���� = �e1�f (����)
    AND    bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
    AND    bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hsua_1.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
    AND    bill_hsua_1.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = 'A'
    AND    ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq���ݒn.�ڋqID
    AND    ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --�o�א�ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
    AND    ship_hsua_1.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
    AND    ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
    AND    ship_hzca_1.cust_account_id = ship_hzad_1.customer_id             --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq�ǉ����.�ڋqID
    AND    bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID  
    AND    bill_hzps_1.location_id = bill_hzlo_1.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID                  
    AND    bill_hsua_1.site_use_id = bill_hzcp_1.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
    AND    bill_hasa_1.org_id = org_units.organization_id
    AND    bill_hsua_1.org_id = org_units.organization_id
    AND    ship_hasa_1.org_id = org_units.organization_id
    AND    ship_hsua_1.org_id = org_units.organization_id
    AND    bill_hcar_1.org_id = org_units.organization_id
    AND    org_units.name = 'SALES-OU'
    AND NOT EXISTS (
                SELECT 'X'
                FROM   hz_cust_acct_relate_all   cash_hcar_1  --�ڋq�֘A�}�X�^(�����֘A)
                      ,hr_all_organization_units org_units    --�g�D�P��
                WHERE  cash_hcar_1.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
                AND    cash_hcar_1.attribute1 = '2'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
                AND    cash_hcar_1.related_cust_account_id = bill_hzca_1.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = ������ڋq�}�X�^.�ڋqID
                AND    cash_hcar_1.org_id = org_units.organization_id
                AND    org_units.name = 'SALES-OU'
                     )
    UNION ALL
    --�A������ڋq�|������ڋq�|�o�א�ڋq
    SELECT cash_hzca_2.cust_account_id           AS cash_account_id         --������ڋqID        
          ,cash_hzca_2.account_number            AS cash_account_number     --������ڋq�R�[�h    
          ,bill_hzca_2.cust_account_id           AS bill_account_id         --������ڋqID        
          ,bill_hzca_2.account_number            AS bill_account_number     --������ڋq�R�[�h    
    FROM   hz_cust_accounts          cash_hzca_2              --������ڋq�}�X�^
          ,hz_cust_acct_sites_all    cash_hasa_2              --������ڋq���ݒn
          ,xxcmm_cust_accounts       cash_hzad_2              --������ڋq�ǉ����
          ,hz_cust_accounts          bill_hzca_2              --������ڋq�}�X�^
          ,hz_cust_acct_sites_all    bill_hasa_2              --������ڋq���ݒn
          ,hz_cust_site_uses_all     bill_hsua_2              --������ڋq�g�p�ړI
          ,xxcmm_cust_accounts       bill_hzad_2              --������ڋq�ǉ����
          ,hz_party_sites            bill_hzps_2              --������p�[�e�B�T�C�g  
          ,hz_locations              bill_hzlo_2              --������ڋq���Ə�      
          ,hz_customer_profiles      bill_hzcp_2              --������ڋq�v���t�@�C��      
          ,hz_cust_accounts          ship_hzca_2              --�o�א�ڋq�}�X�^
          ,hz_cust_acct_sites_all    ship_hasa_2              --�o�א�ڋq���ݒn
          ,hz_cust_site_uses_all     ship_hsua_2              --�o�א�ڋq�g�p�ړI
          ,xxcmm_cust_accounts       ship_hzad_2              --�o�א�ڋq�ǉ����
          ,hz_cust_acct_relate_all   cash_hcar_2              --�ڋq�֘A�}�X�^(�����֘A)
          ,hz_cust_acct_relate_all   bill_hcar_2              --�ڋq�֘A�}�X�^(�����֘A)
          ,hr_all_organization_units org_units                --�g�D�P��
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
    AND    bill_hzca_2.cust_account_id = bill_hzad_2.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
    AND    bill_hzca_2.cust_account_id = bill_hasa_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_2.cust_acct_site_id = bill_hsua_2.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hsua_2.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
    AND    bill_hsua_2.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = 'A'
    AND    cash_hzca_2.cust_account_id = cash_hasa_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    ship_hzca_2.cust_account_id = ship_hzad_2.customer_id             --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq�ǉ����.�ڋqID
    AND    ship_hzca_2.cust_account_id = ship_hasa_2.cust_account_id         --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq���ݒn.�ڋqID
    AND    ship_hasa_2.cust_acct_site_id = ship_hsua_2.cust_acct_site_id     --�o�א�ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
    AND    ship_hsua_2.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
    AND    ship_hsua_2.bill_to_site_use_id = bill_hsua_2.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
    AND    bill_hasa_2.party_site_id = bill_hzps_2.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID  
    AND    bill_hzps_2.location_id = bill_hzlo_2.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID                  
    AND    bill_hsua_2.site_use_id = bill_hzcp_2.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
    AND    cash_hasa_2.org_id = org_units.organization_id
    AND    bill_hasa_2.org_id = org_units.organization_id
    AND    bill_hsua_2.org_id = org_units.organization_id
    AND    ship_hasa_2.org_id = org_units.organization_id
    AND    ship_hsua_2.org_id = org_units.organization_id
    AND    cash_hcar_2.org_id = org_units.organization_id
    AND    bill_hcar_2.org_id = org_units.organization_id
    AND    org_units.name = 'SALES-OU'
    UNION ALL
    --�B������ڋq�|������ڋq���o�א�ڋq
    SELECT cash_hzca_3.cust_account_id             AS cash_account_id         --������ڋqID        
          ,cash_hzca_3.account_number              AS cash_account_number     --������ڋq�R�[�h    
          ,ship_hzca_3.cust_account_id             AS bill_account_id         --������ڋqID        
          ,ship_hzca_3.account_number              AS bill_account_number     --������ڋq�R�[�h    
    FROM   hz_cust_accounts          cash_hzca_3              --������ڋq�}�X�^
          ,hz_cust_acct_sites_all    cash_hasa_3              --������ڋq���ݒn
          ,xxcmm_cust_accounts       cash_hzad_3              --������ڋq�ǉ����
          ,hz_cust_accounts          ship_hzca_3              --�o�א�ڋq�}�X�^�@��������܂�
          ,hz_cust_acct_sites_all    bill_hasa_3              --������ڋq���ݒn
          ,hz_cust_site_uses_all     bill_hsua_3              --������ڋq�g�p�ړI
          ,hz_cust_site_uses_all     ship_hsua_3              --�o�א�ڋq�g�p�ړI
          ,xxcmm_cust_accounts       bill_hzad_3              --������ڋq�ǉ����
          ,hz_party_sites            bill_hzps_3              --������p�[�e�B�T�C�g  
          ,hz_locations              bill_hzlo_3              --������ڋq���Ə�      
          ,hz_customer_profiles      bill_hzcp_3              --������ڋq�v���t�@�C�� 
          ,hz_cust_acct_relate_all   cash_hcar_3              --�ڋq�֘A�}�X�^(�����֘A)
          ,hr_all_organization_units org_units                --�g�D�P��
    WHERE  cash_hzca_3.cust_account_id = cash_hcar_3.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^(�����֘A).�ڋqID
    AND    cash_hzca_3.cust_account_id = cash_hzad_3.customer_id             --������ڋq�}�X�^.�ڋqID = ������ڋq�ǉ����.�ڋqID
    AND    cash_hcar_3.related_cust_account_id = ship_hzca_3.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
    AND    cash_hzca_3.customer_class_code = '14'                            --������ڋq.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
    AND    ship_hzca_3.customer_class_code = '10'                            --������ڋq.�ڋq�敪 = '10'(�ڋq)
    AND    cash_hcar_3.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
    AND    cash_hcar_3.attribute1 = '2'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
    AND    NOT EXISTS (
               SELECT ROWNUM
               FROM   hz_cust_acct_relate_all     ex_hcar_3       --�ڋq�֘A�}�X�^(�����֘A)
                     ,hr_all_organization_units   org_units       --�g�D�P��
               WHERE  ex_hcar_3.cust_account_id = ship_hzca_3.cust_account_id         --�ڋq�֘A�}�X�^(�����֘A).�ڋqID = �o�א�ڋq�}�X�^.�ڋqID
               AND    ex_hcar_3.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
               AND    ex_hcar_3.org_id = org_units.organization_id
               AND    org_units.name = 'SALES-OU'
                    )
    AND    ship_hzca_3.cust_account_id = bill_hzad_3.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
    AND    ship_hzca_3.cust_account_id = bill_hasa_3.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_3.cust_acct_site_id = bill_hsua_3.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hasa_3.cust_acct_site_id = ship_hsua_3.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hsua_3.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
    AND    bill_hsua_3.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = 'A'
    AND    ship_hsua_3.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
    AND    ship_hsua_3.bill_to_site_use_id = bill_hsua_3.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
    AND    cash_hzca_3.cust_account_id = cash_hasa_3.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_3.party_site_id = bill_hzps_3.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID  
    AND    bill_hzps_3.location_id = bill_hzlo_3.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID                  
    AND    bill_hsua_3.site_use_id = bill_hzcp_3.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
    AND    cash_hasa_3.org_id = org_units.organization_id
    AND    bill_hasa_3.org_id = org_units.organization_id
    AND    bill_hsua_3.org_id = org_units.organization_id
    AND    ship_hsua_3.org_id = org_units.organization_id
    AND    cash_hcar_3.org_id = org_units.organization_id
    AND    org_units.name = 'SALES-OU'
    UNION ALL
    --�C������ڋq��������ڋq���o�א�ڋq
    SELECT ship_hzca_4.cust_account_id               AS cash_account_id         --������ڋqID        
          ,ship_hzca_4.account_number                AS cash_account_number     --������ڋq�R�[�h    
          ,ship_hzca_4.cust_account_id               AS bill_account_id         --������ڋqID        
          ,ship_hzca_4.account_number                AS bill_account_number     --������ڋq�R�[�h    
    FROM   hz_cust_accounts          ship_hzca_4              --�o�א�ڋq�}�X�^�@��������E������܂�
          ,hz_cust_acct_sites_all    bill_hasa_4              --������ڋq���ݒn
          ,hz_cust_site_uses_all     bill_hsua_4              --������ڋq�g�p�ړI
          ,hz_cust_site_uses_all     ship_hsua_4              --�o�א�ڋq�g�p�ړI
          ,xxcmm_cust_accounts       bill_hzad_4              --������ڋq�ǉ����
          ,hz_party_sites            bill_hzps_4              --������p�[�e�B�T�C�g  
          ,hz_locations              bill_hzlo_4              --������ڋq���Ə�      
          ,hz_customer_profiles      bill_hzcp_4              --������ڋq�v���t�@�C��
          ,hr_all_organization_units org_units                --�g�D�P��
    WHERE  ship_hzca_4.customer_class_code = '10'             --������ڋq.�ڋq�敪 = '10'(�ڋq)
    AND    NOT EXISTS (
               SELECT ROWNUM
               FROM   hz_cust_acct_relate_all     ex_hcar_4       --�ڋq�֘A�}�X�^
                     ,hr_all_organization_units   org_units       --�g�D�P��
               WHERE 
                     (ex_hcar_4.cust_account_id = ship_hzca_4.cust_account_id           --�ڋq�֘A�}�X�^(�����֘A).�ڋqID = �o�א�ڋq�}�X�^.�ڋqID
               OR     ex_hcar_4.related_cust_account_id = ship_hzca_4.cust_account_id)  --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
               AND    ex_hcar_4.status = 'A'                                            --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
               AND    ex_hcar_4.attribute1 = '2'                                        --�ڋq�֘A�}�X�^(�����֘A).�֘A�敪 = �e2�f(����)
               AND    ex_hcar_4.org_id = org_units.organization_id
               AND    org_units.name = 'SALES-OU'
                    )
    AND    ship_hzca_4.cust_account_id = bill_hzad_4.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
    AND    ship_hzca_4.cust_account_id = bill_hasa_4.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_4.cust_acct_site_id = bill_hsua_4.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hasa_4.cust_acct_site_id = ship_hsua_4.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hsua_4.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
    AND    bill_hsua_4.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = 'A'
    AND    ship_hsua_4.bill_to_site_use_id = bill_hsua_4.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
    AND    ship_hsua_4.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = 'A'
    AND    bill_hasa_4.party_site_id = bill_hzps_4.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID  
    AND    bill_hzps_4.location_id = bill_hzlo_4.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID                  
    AND    bill_hsua_4.site_use_id = bill_hzcp_4.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
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
COMMENT ON MATERIALIZED VIEW apps.xxcfr_cust_hierarchy_mv IS '�����ڋq�K�w�}�e���A���C�Y�h�r���['
/
COMMENT ON COLUMN apps.xxcfr_cust_hierarchy_mv.cash_account_id     IS '������ڋqID'
/
COMMENT ON COLUMN apps.xxcfr_cust_hierarchy_mv.cash_account_number IS '������ڋq�ԍ�'
/
COMMENT ON COLUMN apps.xxcfr_cust_hierarchy_mv.bill_account_id     IS '������ڋqID'
/
COMMENT ON COLUMN apps.xxcfr_cust_hierarchy_mv.bill_account_number IS '������ڋq�ԍ�'
/
