/*************************************************************************
 * 
 * VIEW Name       : XXCSO_CUST_ACCT_SITES_V
 * Description     : ���ʗp�F�ڋq�}�X�^�T�C�g�r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_CUST_ACCT_SITES_V
(
 account_number
,cust_account_id
,account_name
,customer_class_code
,customer_class_name
,account_status
,cust_acct_site_id
,acct_site_status
,location_id
,postal_code
,state
,city
,address1
,address2
,area_code
,phone_number
,fax_number
,business_low_type
,industry_div
,sale_base_code
,management_base_code
,past_sale_base_code
,rsv_sale_base_act_date
,rsv_sale_base_code
,contractor_supplier_code
,bm_pay_supplier_code1
,bm_pay_supplier_code2
,final_tran_date
,final_call_date
,party_representative_name
,party_emp_name
,established_site_name
,establishment_location
,open_close_div
,operation_div
,vist_target_div
,cnvs_date
,cnvs_business_person
,cnvs_base_code
,party_id
,party_name
,organization_name_phonetic
,party_number
,party_status
,customer_status
,employees
,party_site_id
,party_site_status
,identifying_address_flag
)
AS
SELECT
 hca.account_number
,hca.cust_account_id
,hca.account_name
,hca.customer_class_code
,xxcso_util_common_pkg.get_lookup_meaning('CUSTOMER CLASS', hca.customer_class_code, xxcso_util_common_pkg.get_online_sysdate)
,hca.status
,hcas.cust_acct_site_id
,hcas.status
,hl.location_id
,hl.postal_code
,hl.state
,hl.city
,hl.address1
,hl.address2
,hl.address3
,hl.address_lines_phonetic
,hl.address4
,xca.business_low_type
,xca.industry_div
,xca.sale_base_code
,xca.management_base_code
,xca.past_sale_base_code
,xca.rsv_sale_base_act_date
,xca.rsv_sale_base_code
,xca.contractor_supplier_code
,xca.bm_pay_supplier_code1
,xca.bm_pay_supplier_code2
,xca.final_tran_date
,xca.final_call_date
,xca.party_representative_name
,xca.party_emp_name
,xca.established_site_name
,xca.establishment_location
,xca.open_close_div
,xca.operation_div
,xca.vist_target_div
,xca.cnvs_date
,xca.cnvs_business_person
,xca.cnvs_base_code
,hp.party_id
,hp.party_name
,hp.organization_name_phonetic
,hp.party_number
,hp.status
,hp.duns_number_c
,hp.attribute2
,hps.party_site_id
,hps.status
,hps.identifying_address_flag
FROM
 hz_parties hp
,hz_party_sites hps
,hz_locations hl
,hz_cust_accounts hca
,hz_cust_acct_sites hcas
,xxcmm_cust_accounts xca
WHERE
hps.party_id = hp.party_id AND
hl.location_id = hps.location_id AND
hca.party_id = hp.party_id AND
hcas.cust_account_id = hca.cust_account_id AND
hcas.party_site_id = hps.party_site_id AND
xca.customer_id(+) = hca.cust_account_id
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.account_number IS '�ڋq�R�[�h';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.cust_account_id IS '�A�J�E���gID';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.account_name IS '����';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.customer_class_code IS '�ڋq�敪�R�[�h';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.customer_class_name IS '�ڋq�敪��';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.account_status IS '�A�J�E���g�X�e�[�^�X';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.cust_acct_site_id IS '�ڋq���ݒnID';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.acct_site_status IS '�ڋq���ݒn�X�e�[�^�X';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.location_id IS '�ڋq���Ə�ID';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.postal_code IS '�X�֔ԍ�';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.state IS '�s���{��';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.city IS '�s�E��';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.address1 IS '�Z��1';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.address2 IS '�Z��2';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.area_code IS '�n��R�[�h';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.phone_number IS '�d�b�ԍ�';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.fax_number IS 'FAX�ԍ�';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.business_low_type IS '�Ƒԁi�����ށj';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.industry_div IS '�Ǝ�@  ';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.sale_base_code IS '���㋒�_�R�[�h';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.management_base_code IS '�Ǘ������_�R�[�h';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.past_sale_base_code IS '�O�����㋒�_�R�[�h';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.rsv_sale_base_act_date IS '�\�񔄏㋒�_�L���J�n��';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.rsv_sale_base_code IS '�\�񔄏㋒�_�R�[�h';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.contractor_supplier_code IS '�_��Ҏd����R�[�h';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.bm_pay_supplier_code1 IS '�Љ��BM�x���d����R�[�h�P';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.bm_pay_supplier_code2 IS '�Љ��BM�x���d����R�[�h�Q';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.final_tran_date IS '�ŏI�����';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.final_call_date IS '�ŏI�K���';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_representative_name IS '��\�Җ��i�����j';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_emp_name IS '�S���ҁi�����j';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.established_site_name IS '�ݒu�於';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.establishment_location IS '�ݒu���P�[�V����';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.open_close_div IS '�����I�[�v���E�N���[�Y�敪';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.operation_div IS '�I�y���[�V�����敪';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.vist_target_div IS '�K��Ώۋ敪�i���̕ύX�j';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.cnvs_date IS '�ڋq�l����';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.cnvs_business_person IS '�l���c�ƈ�';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.cnvs_base_code IS '�l�����_';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_id IS '�p�[�e�BID';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_name IS '�ڋq��';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.organization_name_phonetic IS '�ڋq���i�J�i�j';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_number IS '�p�[�e�B�ԍ�';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_status IS '�p�[�e�B�X�e�[�^�X';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.customer_status IS '�ڋq�X�e�[�^�X';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.employees IS '�Ј���';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_site_id IS '�p�[�e�B�T�C�gID';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_site_status IS '�p�[�e�B�T�C�g�X�e�[�^�X';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.identifying_address_flag IS '���ʏ��ݒn�t���O';
COMMENT ON TABLE XXCSO_CUST_ACCT_SITES_V IS '���ʗp�F�ڋq�}�X�^�T�C�g�r���[';
