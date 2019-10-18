/************************************************************************
 * Copyright(c) 2019, SCSK Corporation. All rights reserved.
 *
 * View Name       : XXCOS_CUST_HIERARCHY_MV
 * Description     : �ڋq�K�w�}�e���A���C�Y�h�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2019/10/06    1.0   N.Koyama         �V�K�쐬
 *  2019/10/17    1.1   N.Koyama         E_�{�ғ�_15949��Q(���z���O�C���s�v�Ή�)
 *                                       ���p�t�H�[�}���X���l�����AOU���Œ�l�őΉ�
 *
 ************************************************************************/
  CREATE MATERIALIZED VIEW "APPS"."XXCOS_CUST_HIERARCHY_MV" ("CASH_ACCOUNT_ID", "CASH_ACCOUNT_NUMBER", "CASH_ACCOUNT_NAME", "BILL_ACCOUNT_ID", "BILL_ACCOUNT_NUMBER", "BILL_ACCOUNT_NAME", "SHIP_ACCOUNT_ID", "SHIP_ACCOUNT_NUMBER", "SHIP_ACCOUNT_NAME", "CASH_RECEIV_BASE_CODE", "BILL_PARTY_ID", "BILL_BILL_BASE_CODE", "BILL_POSTAL_CODE", "BILL_STATE", "BILL_CITY", "BILL_ADDRESS1", "BILL_ADDRESS2", "BILL_TEL_NUM", "BILL_CONS_INV_FLAG", "BILL_TORIHIKISAKI_CODE", "BILL_STORE_CODE", "BILL_CUST_STORE_NAME", "BILL_TAX_DIV", "BILL_CRED_REC_CODE1", "BILL_CRED_REC_CODE2", "BILL_CRED_REC_CODE3", "BILL_INVOICE_TYPE", "BILL_PAYMENT_TERM_ID", "BILL_PAYMENT_TERM2", "BILL_PAYMENT_TERM3", "BILL_TAX_ROUND_RULE", "SHIP_SALE_BASE_CODE", "BILL_LAST_UPDATE_DATE")
    TABLESPACE "XXDATA2"
    BUILD IMMEDIATE 
    USING INDEX 
    REFRESH COMPLETE ON DEMAND 
    USING DEFAULT LOCAL ROLLBACK SEGMENT
    DISABLE QUERY REWRITE
  AS
  SELECT cust_hier.cash_account_id                          AS cash_account_id        --������ڋqID
        ,cust_hier.cash_account_number                      AS cash_account_number    --������ڋq�R�[�h
        ,xxcfr_common_pkg.get_cust_account_name(
                            cust_hier.cash_account_number,
                            0)                              AS cash_account_name      --������ڋq����
        ,cust_hier.bill_account_id                          AS bill_account_id        --������ڋqID
        ,cust_hier.bill_account_number                      AS bill_account_number    --������ڋq�R�[�h
        ,xxcfr_common_pkg.get_cust_account_name(
                            cust_hier.bill_account_number,
                            0)                              AS bill_account_name      --������ڋq����
        ,cust_hier.ship_account_id                          AS ship_account_id        --�o�א�ڋqID
        ,cust_hier.ship_account_number                      AS ship_account_number    --�o�א�ڋq�R�[�h
        ,xxcfr_common_pkg.get_cust_account_name(
                            cust_hier.ship_account_number,
                            0)                              AS ship_account_name      --�o�א�ڋq����
        ,cust_hier.cash_receiv_base_code                    AS cash_receiv_base_code  --�������_�R�[�h
        ,cust_hier.bill_party_id                            AS bill_party_id          --�p�[�e�BID
        ,cust_hier.bill_bill_base_code                      AS bill_bill_base_code    --�������_�R�[�h
        ,cust_hier.bill_postal_code                         AS bill_postal_code       --�X�֔ԍ�
        ,cust_hier.bill_state                               AS bill_state             --�s���{��
        ,cust_hier.bill_city                                AS bill_city              --�s�E��
        ,cust_hier.bill_address1                            AS bill_address1          --�Z��1
        ,cust_hier.bill_address2                            AS bill_address2          --�Z��2
        ,cust_hier.bill_tel_num                             AS bill_tel_num           --�d�b�ԍ�
        ,cust_hier.bill_cons_inv_flag                       AS bill_cons_inv_flag     --�ꊇ���������s�t���O
        ,cust_hier.bill_torihikisaki_code                   AS bill_torihikisaki_code --�����R�[�h
        ,cust_hier.bill_store_code                          AS bill_store_code        --�X�܃R�[�h
        ,cust_hier.bill_cust_store_name                     AS bill_cust_store_name   --�ڋq�X�ܖ���
        ,cust_hier.bill_tax_div                             AS bill_tax_div           --����ŋ敪
        ,cust_hier.bill_cred_rec_code1                      AS bill_cred_rec_code1    --���|�R�[�h1(������)
        ,cust_hier.bill_cred_rec_code2                      AS bill_cred_rec_code2    --���|�R�[�h2(���Ə�)
        ,cust_hier.bill_cred_rec_code3                      AS bill_cred_rec_code3    --���|�R�[�h3(���̑�)
        ,cust_hier.bill_invoice_type                        AS bill_invoice_type      --�������o�͌`��
        ,cust_hier.bill_payment_term_id                     AS bill_payment_term_id   --�x������
        ,TO_NUMBER(cust_hier.bill_payment_term2)            AS bill_payment_term2     --��2�x������
        ,TO_NUMBER(cust_hier.bill_payment_term3)            AS bill_payment_term3     --��3�x������
        ,cust_hier.bill_tax_round_rule                      AS bill_tax_round_rule    --�ŋ��|�[������
        ,cust_hier.ship_sale_base_code                      AS ship_sale_base_code    --���㋒�_�R�[�h
        ,cust_hier.bill_last_update_date                    AS bill_last_update_date  --������ڋq�ŏI�X�V��
  FROM   (
  --�@������ڋq��������ڋq�|�o�א�ڋq
    SELECT
           /*+
             LEADING(ship_hzca_1)
             USE_NL(ship_hzca_1 bill_hzca_1 bill_hcar_1 bill_hzad_1 ship_hzad_1)
           */
           bill_hzca_1.cust_account_id         AS cash_account_id         --������ڋqID
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
          ,bill_hsua_1.last_update_date        AS bill_last_update_date   --������ڋq�g�p�ړI�ŏI�X�V��
    FROM   hz_cust_accounts          bill_hzca_1              --������ڋq�}�X�^
-- Ver1.1 Mod Start
--          ,hz_cust_acct_sites        bill_hasa_1              --������ڋq���ݒn
--          ,hz_cust_site_uses         bill_hsua_1              --������ڋq�g�p�ړI
          ,hz_cust_acct_sites_all    bill_hasa_1              --������ڋq���ݒn
          ,hz_cust_site_uses_all     bill_hsua_1              --������ڋq�g�p�ړI
-- Ver1.1 Mod End
          ,xxcmm_cust_accounts       bill_hzad_1              --������ڋq�ǉ����
          ,hz_party_sites            bill_hzps_1              --������p�[�e�B�T�C�g
          ,hz_locations              bill_hzlo_1              --������ڋq���Ə�
          ,hz_customer_profiles      bill_hzcp_1              --������ڋq�v���t�@�C��
          ,hz_cust_accounts          ship_hzca_1              --�o�א�ڋq�}�X�^
-- Ver1.1 Mod Start
--          ,hz_cust_acct_sites        ship_hasa_1              --�o�א�ڋq���ݒn
--          ,hz_cust_site_uses         ship_hsua_1              --�o�א�ڋq�g�p�ړI
          ,hz_cust_acct_sites_all    ship_hasa_1              --�o�א�ڋq���ݒn
          ,hz_cust_site_uses_all     ship_hsua_1              --�o�א�ڋq�g�p�ړI
-- Ver1.1 Mod End
          ,xxcmm_cust_accounts       ship_hzad_1              --�o�א�ڋq�ǉ����
-- Ver1.1 Mod Start
--          ,hz_cust_acct_relate       bill_hcar_1              --�ڋq�֘A�}�X�^(�����֘A)
          ,hz_cust_acct_relate_all   bill_hcar_1              --�ڋq�֘A�}�X�^(�����֘A)
-- Ver1.1 Mod End
    WHERE  bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^.�ڋqID
    AND    bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --�ڋq�֘A�}�X�^.�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
    AND    bill_hzca_1.customer_class_code = '14'                            --������ڋq.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
    AND    bill_hcar_1.status = 'A'                                          --�ڋq�֘A�}�X�^.�X�e�[�^�X = �eA�f
    AND    bill_hcar_1.attribute1 = '1'                                      --�ڋq�֘A�}�X�^.�֘A���� = �e1�f (����)
    AND    bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
    AND    bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hsua_1.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
    AND    ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq���ݒn.�ڋqID
    AND    ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --�o�א�ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
    AND    ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
    AND    ship_hzca_1.cust_account_id = ship_hzad_1.customer_id             --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq�ǉ����.�ڋqID
    AND    bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID
    AND    bill_hzps_1.location_id = bill_hzlo_1.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID
    AND    bill_hsua_1.site_use_id = bill_hzcp_1.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
    AND    bill_hsua_1.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = �eA�f
    AND    ship_hsua_1.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = �eA�f
    AND    bill_hasa_1.status = 'A'                                          --������ڋq���ݒn.�X�e�[�^�X = 'A'
    AND    ship_hasa_1.status = 'A'                                          --�o�א�ڋq���ݒn.�X�e�[�^�X = 'A'
    AND    bill_hsua_1.primary_flag = 'Y'                                    --������ڋq�g�p�ړI.��t���O = 'Y'
    AND    ship_hsua_1.primary_flag = 'Y'                                    --������ڋq�g�p�ړI.��t���O = 'Y'
-- Ver1.1 Add Start
    AND    bill_hasa_1.org_id = 2424
    AND    bill_hsua_1.org_id = 2424
    AND    ship_hasa_1.org_id = 2424
    AND    ship_hsua_1.org_id = 2424
    AND    bill_hcar_1.org_id = 2424
-- Ver1.1 Add End
    AND NOT EXISTS (
                SELECT /*+ INDEX( cash_hcar_1 HZ_CUST_ACCT_RELATE_N2 ) */
                       'X'
-- Ver1.1 Mod Start
--                FROM   hz_cust_acct_relate       cash_hcar_1   --�ڋq�֘A�}�X�^(�����֘A)
                FROM   hz_cust_acct_relate_all   cash_hcar_1   --�ڋq�֘A�}�X�^(�����֘A)
-- Ver1.1 Mod End
                WHERE  cash_hcar_1.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
                AND    cash_hcar_1.attribute1 = '2'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
                AND    cash_hcar_1.related_cust_account_id = bill_hzca_1.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = ������ڋq�}�X�^.�ڋqID
-- Ver1.1 Add Start
                AND    cash_hcar_1.org_id = 2424
-- Ver1.1 Add End
                     )
    UNION ALL
    --�A������ڋq�|������ڋq�|�o�א�ڋq
    SELECT
           /*+
             LEADING(ship_hzca_2)
             USE_NL(ship_hzca_2 bill_hzca_2 cash_hzca_2 bill_hcar_2 cash_hcar_2 cash_hzad_2 bill_hzad_2 ship_hzad_2)
           */
           cash_hzca_2.cust_account_id           AS cash_account_id         --������ڋqID
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
          ,bill_hsua_2.last_update_date          AS bill_last_update_date   --������ڋq�g�p�ړI�ŏI�X�V��
    FROM   hz_cust_accounts          cash_hzca_2              --������ڋq�}�X�^
-- Ver1.1 Mod Start
--          ,hz_cust_acct_sites        cash_hasa_2              --������ڋq���ݒn
          ,hz_cust_acct_sites_all    cash_hasa_2              --������ڋq���ݒn
-- Ver1.1 Mod End
          ,xxcmm_cust_accounts       cash_hzad_2              --������ڋq�ǉ����
          ,hz_cust_accounts          bill_hzca_2              --������ڋq�}�X�^
-- Ver1.1 Mod Start
--          ,hz_cust_acct_sites        bill_hasa_2              --������ڋq���ݒn
--          ,hz_cust_site_uses         bill_hsua_2              --������ڋq�g�p�ړI
          ,hz_cust_acct_sites_all    bill_hasa_2              --������ڋq���ݒn
          ,hz_cust_site_uses_all     bill_hsua_2              --������ڋq�g�p�ړI
-- Ver1.1 Mod End
          ,xxcmm_cust_accounts       bill_hzad_2              --������ڋq�ǉ����
          ,hz_party_sites            bill_hzps_2              --������p�[�e�B�T�C�g
          ,hz_locations              bill_hzlo_2              --������ڋq���Ə�
          ,hz_customer_profiles      bill_hzcp_2              --������ڋq�v���t�@�C��
          ,hz_cust_accounts          ship_hzca_2              --�o�א�ڋq�}�X�^
-- Ver1.1 Mod Start
--          ,hz_cust_acct_sites        ship_hasa_2              --�o�א�ڋq���ݒn
--          ,hz_cust_site_uses         ship_hsua_2              --�o�א�ڋq�g�p�ړI
          ,hz_cust_acct_sites_all    ship_hasa_2              --�o�א�ڋq���ݒn
          ,hz_cust_site_uses_all     ship_hsua_2              --�o�א�ڋq�g�p�ړI
-- Ver1.1 Mod End
          ,xxcmm_cust_accounts       ship_hzad_2              --�o�א�ڋq�ǉ����
-- Ver1.1 Mod Start
--          ,hz_cust_acct_relate       cash_hcar_2              --�ڋq�֘A�}�X�^(�����֘A)
--          ,hz_cust_acct_relate       bill_hcar_2              --�ڋq�֘A�}�X�^(�����֘A)
          ,hz_cust_acct_relate_all   cash_hcar_2              --�ڋq�֘A�}�X�^(�����֘A)
          ,hz_cust_acct_relate_all   bill_hcar_2              --�ڋq�֘A�}�X�^(�����֘A)
-- Ver1.1 Mod End
    WHERE  cash_hzca_2.cust_account_id = cash_hcar_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^(�����֘A).�ڋqID
    AND    cash_hzca_2.cust_account_id = cash_hzad_2.customer_id             --������ڋq�}�X�^.�ڋqID = ������ڋq������.�ڋqID
    AND    cash_hcar_2.related_cust_account_id = bill_hzca_2.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = ������ڋq�}�X�^.�ڋqID
    AND    bill_hzca_2.cust_account_id = bill_hcar_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^(�����֘A).�ڋqID
    AND    bill_hcar_2.related_cust_account_id = ship_hzca_2.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
    AND    cash_hzca_2.customer_class_code = '14'                            --������ڋq.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
    AND    ship_hzca_2.customer_class_code IN ('10','12')                    --������ڋq.�ڋq�敪 = '10'(�ڋq)
    AND    cash_hcar_2.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
    AND    cash_hcar_2.attribute1 = '2'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
    AND    bill_hcar_2.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
    AND    bill_hcar_2.attribute1 = '1'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e1�f (����)
    AND    bill_hzca_2.cust_account_id = bill_hzad_2.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
    AND    bill_hzca_2.cust_account_id = bill_hasa_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_2.cust_acct_site_id = bill_hsua_2.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hsua_2.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
    AND    cash_hzca_2.cust_account_id = cash_hasa_2.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    ship_hzca_2.cust_account_id = ship_hzad_2.customer_id             --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq�ǉ����.�ڋqID
    AND    ship_hzca_2.cust_account_id = ship_hasa_2.cust_account_id         --�o�א�ڋq�}�X�^.�ڋqID = �o�א�ڋq���ݒn.�ڋqID
    AND    ship_hasa_2.cust_acct_site_id = ship_hsua_2.cust_acct_site_id     --�o�א�ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
    AND    ship_hsua_2.bill_to_site_use_id = bill_hsua_2.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
    AND    bill_hasa_2.party_site_id = bill_hzps_2.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID
    AND    bill_hzps_2.location_id = bill_hzlo_2.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID
    AND    bill_hsua_2.site_use_id = bill_hzcp_2.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
    AND    bill_hsua_2.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = �eA�f
    AND    ship_hsua_2.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = �eA�f
    AND    cash_hasa_2.status = 'A'                                          --������ڋq���ݒn.�X�e�[�^�X = 'A'
    AND    bill_hasa_2.status = 'A'                                          --������ڋq���ݒn.�X�e�[�^�X = 'A'
    AND    ship_hasa_2.status = 'A'                                          --�o�א�ڋq���ݒn.�X�e�[�^�X = 'A'
    AND    bill_hsua_2.primary_flag = 'Y'                                    --������ڋq�g�p�ړI.��t���O = 'Y'
    AND    ship_hsua_2.primary_flag = 'Y'                                    --������ڋq�g�p�ړI.��t���O = 'Y'
-- Ver1.1 Add Start
    AND    cash_hasa_2.org_id = 2424
    AND    bill_hasa_2.org_id = 2424
    AND    bill_hsua_2.org_id = 2424
    AND    ship_hasa_2.org_id = 2424
    AND    ship_hsua_2.org_id = 2424
    AND    cash_hcar_2.org_id = 2424
    AND    bill_hcar_2.org_id = 2424
-- Ver1.1 Add End
    UNION ALL
    --�B������ڋq�|������ڋq���o�א�ڋq
    SELECT
           /*+
             LEADING(ship_hzca_3)
             USE_NL(ship_hzca_3 cash_hzca_3 cash_hcar_3)
             USE_NL(bill_hzad_3)
             USE_NL(cash_hasa_3)
             USE_NL(bill_hasa_3)
           */
           cash_hzca_3.cust_account_id             AS cash_account_id         --������ڋqID
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
          ,bill_hsua_3.last_update_date            AS bill_last_update_date   --������ڋq�g�p�ړI�ŏI�X�V��
    FROM   hz_cust_accounts          cash_hzca_3              --������ڋq�}�X�^
-- Ver1.1 Mod Start
--          ,hz_cust_acct_sites        cash_hasa_3              --������ڋq���ݒn
          ,hz_cust_acct_sites_all    cash_hasa_3              --������ڋq���ݒn
-- Ver1.1 Mod End
          ,xxcmm_cust_accounts       cash_hzad_3              --������ڋq�ǉ����
          ,hz_cust_accounts          ship_hzca_3              --�o�א�ڋq�}�X�^�@��������܂�
-- Ver1.1 Mod Start
--          ,hz_cust_acct_sites        bill_hasa_3              --������ڋq���ݒn
--          ,hz_cust_site_uses         bill_hsua_3              --������ڋq�g�p�ړI
--          ,hz_cust_site_uses         ship_hsua_3              --�o�א�ڋq�g�p�ړI
          ,hz_cust_acct_sites_all    bill_hasa_3              --������ڋq���ݒn
          ,hz_cust_site_uses_all     bill_hsua_3              --������ڋq�g�p�ړI
          ,hz_cust_site_uses_all     ship_hsua_3              --�o�א�ڋq�g�p�ړI
-- Ver1.1 Mod End
          ,xxcmm_cust_accounts       bill_hzad_3              --������ڋq�ǉ����
          ,hz_party_sites            bill_hzps_3              --������p�[�e�B�T�C�g
          ,hz_locations              bill_hzlo_3              --������ڋq���Ə�
          ,hz_customer_profiles      bill_hzcp_3              --������ڋq�v���t�@�C��
-- Ver1.1 Mod Start
--          ,hz_cust_acct_relate       cash_hcar_3              --�ڋq�֘A�}�X�^(�����֘A)
          ,hz_cust_acct_relate_all   cash_hcar_3              --�ڋq�֘A�}�X�^(�����֘A)
-- Ver1.1 Mod End
    WHERE  cash_hzca_3.cust_account_id = cash_hcar_3.cust_account_id         --������ڋq�}�X�^.�ڋqID = �ڋq�֘A�}�X�^(�����֘A).�ڋqID
    AND    cash_hzca_3.cust_account_id = cash_hzad_3.customer_id             --������ڋq�}�X�^.�ڋqID = ������ڋq�ǉ����.�ڋqID
    AND    cash_hcar_3.related_cust_account_id = ship_hzca_3.cust_account_id --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
    AND    cash_hzca_3.customer_class_code = '14'                            --������ڋq.�ڋq�敪 = '14'(���|�Ǘ���ڋq)
    AND    ship_hzca_3.customer_class_code IN ('10','12')                            --������ڋq.�ڋq�敪 = '10'(�ڋq)
    AND    cash_hcar_3.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
    AND    cash_hcar_3.attribute1 = '2'                                      --�ڋq�֘A�}�X�^(�����֘A).�֘A���� = �e2�f (����)
    AND    NOT EXISTS (
               SELECT /*+ INDEX( ex_hcar_3 HZ_CUST_ACCT_RELATE_N1 ) */
                      'X'
-- Ver1.1 Mod Start
--               FROM   hz_cust_acct_relate     ex_hcar_3       --�ڋq�֘A�}�X�^(�����֘A)
               FROM   hz_cust_acct_relate_all ex_hcar_3       --�ڋq�֘A�}�X�^(�����֘A)
-- Ver1.1 Mod End
               WHERE  ex_hcar_3.cust_account_id = ship_hzca_3.cust_account_id         --�ڋq�֘A�}�X�^(�����֘A).�ڋqID = �o�א�ڋq�}�X�^.�ڋqID
               AND    ex_hcar_3.status = 'A'                                          --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
-- Ver1.1 Add Start
               AND    ex_hcar_3.org_id = 2424
-- Ver1.1 Add End
                    )
    AND    ship_hzca_3.cust_account_id = bill_hzad_3.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
    AND    ship_hzca_3.cust_account_id = bill_hasa_3.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_3.cust_acct_site_id = bill_hsua_3.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hasa_3.cust_acct_site_id = ship_hsua_3.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hsua_3.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
    AND    ship_hsua_3.bill_to_site_use_id = bill_hsua_3.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
    AND    cash_hzca_3.cust_account_id = cash_hasa_3.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_3.party_site_id = bill_hzps_3.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID
    AND    bill_hzps_3.location_id = bill_hzlo_3.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID
    AND    bill_hsua_3.site_use_id = bill_hzcp_3.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
    AND    bill_hsua_3.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = �eA�f
    AND    ship_hsua_3.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = �eA�f
    AND    cash_hasa_3.status = 'A'                                          --������ڋq���ݒn.�X�e�[�^�X = 'A'
    AND    bill_hasa_3.status = 'A'                                          --������ڋq���ݒn.�X�e�[�^�X = 'A'
    AND    bill_hsua_3.primary_flag = 'Y'                                    --������ڋq�g�p�ړI.��t���O = 'Y'
    AND    ship_hsua_3.primary_flag = 'Y'                                    --������ڋq�g�p�ړI.��t���O = 'Y'
-- Ver1.1 Add Start
    AND    cash_hasa_3.org_id = 2424
    AND    bill_hasa_3.org_id = 2424
    AND    bill_hsua_3.org_id = 2424
    AND    ship_hsua_3.org_id = 2424
    AND    cash_hcar_3.org_id = 2424
-- Ver1.1 Add End
    UNION ALL
    --�C������ڋq��������ڋq���o�א�ڋq
    SELECT
           /*+
             LEADING(ship_hzca_4)
             USE_NL(ship_hzca_4 bill_hasa_4 bill_hsua_4 ship_hsua_4)
             USE_NL(bill_hzad_4)
           */
           ship_hzca_4.cust_account_id               AS cash_account_id         --������ڋqID
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
          ,bill_hsua_4.last_update_date              AS bill_last_update_date   --������ڋq�g�p�ړI�ŏI�X�V��
    FROM   hz_cust_accounts          ship_hzca_4              --�o�א�ڋq�}�X�^�@��������E������܂�
-- Ver1.1 Mod Start
--          ,hz_cust_acct_sites        bill_hasa_4              --������ڋq���ݒn
--          ,hz_cust_site_uses         bill_hsua_4              --������ڋq�g�p�ړI
--          ,hz_cust_site_uses         ship_hsua_4              --�o�א�ڋq�g�p�ړI
          ,hz_cust_acct_sites_all    bill_hasa_4              --������ڋq���ݒn
          ,hz_cust_site_uses_all     bill_hsua_4              --������ڋq�g�p�ړI
          ,hz_cust_site_uses_all     ship_hsua_4              --�o�א�ڋq�g�p�ړI
-- Ver1.1 Mod End
          ,xxcmm_cust_accounts       bill_hzad_4              --������ڋq�ǉ����
          ,hz_party_sites            bill_hzps_4              --������p�[�e�B�T�C�g
          ,hz_locations              bill_hzlo_4              --������ڋq���Ə�
          ,hz_customer_profiles      bill_hzcp_4              --������ڋq�v���t�@�C��
    WHERE  (
             ship_hzca_4.customer_class_code  IS NULL
           OR
             ship_hzca_4.customer_class_code  IN ( '10', '12' )               --������ڋq.�ڋq�敪 = '10'(�ڋq)�A'12'(��l�ڋq)
           )
    AND    NOT EXISTS (
               SELECT /*+ INDEX( ex_hcar_41 HZ_CUST_ACCT_RELATE_N1 ) */
                      'X'
-- Ver1.1 Mod Start
--               FROM   hz_cust_acct_relate     ex_hcar_41      --�ڋq�֘A�}�X�^
               FROM   hz_cust_acct_relate_all ex_hcar_41      --�ڋq�֘A�}�X�^
-- Ver1.1 Mod End
               WHERE
                      ex_hcar_41.cust_account_id = ship_hzca_4.cust_account_id          --�ڋq�֘A�}�X�^(�����֘A).�ڋqID = �o�א�ڋq�}�X�^.�ڋqID
               AND    ex_hcar_41.status = 'A'                                           --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
               AND    ex_hcar_41.attribute1 = '2'
-- Ver1.1 Add Start
               AND    ex_hcar_41.org_id = 2424
-- Ver1.1 Add End
                    )
    AND    NOT EXISTS (
               SELECT /*+ INDEX( ex_hcar_42 HZ_CUST_ACCT_RELATE_N2 ) */
                      'X'
-- Ver1.1 Mod Start
--               FROM   hz_cust_acct_relate     ex_hcar_42      --�ڋq�֘A�}�X�^
               FROM   hz_cust_acct_relate_all ex_hcar_42      --�ڋq�֘A�}�X�^
-- Ver1.1 Mod End
               WHERE
                      ex_hcar_42.related_cust_account_id = ship_hzca_4.cust_account_id   --�ڋq�֘A�}�X�^(�����֘A).�֘A��ڋqID = �o�א�ڋq�}�X�^.�ڋqID
               AND    ex_hcar_42.status = 'A'                                            --�ڋq�֘A�}�X�^(�����֘A).�X�e�[�^�X = �eA�f
               AND    ex_hcar_42.attribute1 = '2'
-- Ver1.1 Add Start
               AND    ex_hcar_42.org_id = 2424
-- Ver1.1 Add End
                    )
    AND    ship_hzca_4.cust_account_id = bill_hzad_4.customer_id             --������ڋq�}�X�^.�ڋqID = �ڋq�ǉ����.�ڋqID
    AND    ship_hzca_4.cust_account_id = bill_hasa_4.cust_account_id         --������ڋq�}�X�^.�ڋqID = ������ڋq���ݒn.�ڋqID
    AND    bill_hasa_4.cust_acct_site_id = bill_hsua_4.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = ������ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hasa_4.cust_acct_site_id = ship_hsua_4.cust_acct_site_id     --������ڋq���ݒn.�ڋq���ݒnID = �o�א�ڋq�g�p�ړI.�ڋq���ݒnID
    AND    bill_hsua_4.site_use_code = 'BILL_TO'                             --������ڋq�g�p�ړI.�g�p�ړI = 'BILL_TO'(������)
    AND    ship_hsua_4.bill_to_site_use_id = bill_hsua_4.site_use_id         --�o�א�ڋq�g�p�ړI.�����掖�Ə�ID = ������ڋq�g�p�ړI.�g�p�ړIID
    AND    bill_hasa_4.party_site_id = bill_hzps_4.party_site_id             --������ڋq���ݒn.�p�[�e�B�T�C�gID = ������p�[�e�B�T�C�g.�p�[�e�B�T�C�gID
    AND    bill_hzps_4.location_id = bill_hzlo_4.location_id                 --������p�[�e�B�T�C�g.���Ə�ID = ������ڋq���Ə�.���Ə�ID
    AND    bill_hsua_4.site_use_id = bill_hzcp_4.site_use_id(+)              --������ڋq�g�p�ړI.�g�p�ړIID = ������ڋq�v���t�@�C��.�g�p�ړIID
    AND    bill_hsua_4.status = 'A'                                          --������ڋq�g�p�ړI.�X�e�[�^�X = �eA�f
    AND    ship_hsua_4.status = 'A'                                          --�o�א�ڋq�g�p�ړI.�X�e�[�^�X = �eA�f
    AND    bill_hasa_4.status = 'A'                                          --������ڋq���ݒn.�X�e�[�^�X = 'A'
    AND    bill_hsua_4.primary_flag = 'Y'                                    --������ڋq�g�p�ړI.��t���O = 'Y'
    AND    ship_hsua_4.primary_flag = 'Y'                                    --�o�א�ڋq�g�p�ړI.��t���O = 'Y'
-- Ver1.1 Add Start
    AND    bill_hasa_4.org_id = 2424
    AND    bill_hsua_4.org_id = 2424
    AND    ship_hsua_4.org_id = 2424
-- Ver1.1 Add End
) cust_hier;
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.cash_account_id         IS  '������ڋqID';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.cash_account_number     IS  '������ڋq�R�[�h';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.cash_account_name       IS  '������ڋq����';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_account_id         IS  '������ڋqID';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_account_number     IS  '������ڋq�R�[�h';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_account_name       IS  '������ڋq����';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.ship_account_id         IS  '�o�א�ڋqID';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.ship_account_number     IS  '�o�א�ڋq�R�[�h';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.ship_account_name       IS  '�o�א�ڋq����';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.cash_receiv_base_code   IS  '�������_�R�[�h';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_party_id           IS  '�p�[�e�BID';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_bill_base_code     IS  '�������_�R�[�h';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_postal_code        IS  '�X�֔ԍ�';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_state              IS  '�s���{��';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_city               IS  '�s�E��';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_address1           IS  '�Z��1';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_address2           IS  '�Z��2';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_tel_num            IS  '�d�b�ԍ�';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_cons_inv_flag      IS  '�ꊇ���������s�t���O';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_torihikisaki_code  IS  '�����R�[�h';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_store_code         IS  '�X�܃R�[�h';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_cust_store_name    IS  '�ڋq�X�ܖ���';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_tax_div            IS  '����ŋ敪';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_cred_rec_code1     IS  '���|�R�[�h1(������)';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_cred_rec_code2     IS  '���|�R�[�h2(���Ə�)';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_cred_rec_code3     IS  '���|�R�[�h3(���̑�)';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_invoice_type       IS  '�������o�͌`��';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_payment_term_id    IS  '�x������';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_payment_term2      IS  '��2�x������';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_payment_term3      IS  '��3�x������';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_tax_round_rule     IS  '�ŋ��|�[������';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.ship_sale_base_code     IS  '���㋒�_�R�[�h';
COMMENT ON  COLUMN  apps.xxcos_cust_hierarchy_mv.bill_last_update_date   IS  '������ڋq�g�p�ړI�ŏI�X�V��';
--
COMMENT ON  MATERIALIZED VIEW   apps.xxcos_cust_hierarchy_mv             IS  'XXCOS�ڋq�K�w�}�e���A���C�Y�h�r���[';
