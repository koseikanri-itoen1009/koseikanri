-- 2011/09/29 �̔��\�����X�V�Ή� mod start by Kenichi.Nakamura
-- 2010/09/22 ��QE_�{�ғ�_02021 mod start by Shigeto.Niki
--CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
--CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,store_cust_code,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
-- 2014/11/21 [E_�{�ғ�_12237]�q�ɊǗ��V�X�e���Ή� mod start by Yasunari.Nagasue
--CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,calendar_code,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,store_cust_code,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
-- 2017/04/05 [E_�{�ғ�_13976]eSM�O���f�[�^�A�g�Ή� mod start by S.Yamashita
--CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,calendar_code,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,store_cust_code,cust_fresh_con_code,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
-- 2017/06/14 [E_�{�ғ�_14271]mod start
--CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,calendar_code,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,store_cust_code,cust_fresh_con_code,esm_target_div,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V
AS
-- 2017/06/14 [E_�{�ғ�_14271]mod end
-- 2017/04/05 [E_�{�ғ�_13976]eSM�O���f�[�^�A�g�Ή� mod end by S.Yamashita
-- 2014/11/21 [E_�{�ғ�_12237]�q�ɊǗ��V�X�e���Ή� mod end   by Yasunari.Nagasue
-- 2010/09/22 ��QE_�{�ғ�_02021 mod end by Shigeto.Niki
-- 2011/09/29 �̔��\�����X�V�Ή� mod end by Kenichi.Nakamura
SELECT xca.customer_id customer_id,
       hp.party_id party_id,
       xca.customer_code customer_code,
       hp.duns_number_c customer_status,
       xca.cust_update_flag cust_update_flag,
       xca.business_low_type business_low_type,
       xca.industry_div industry_div,
       xca.selling_transfer_div selling_transfer_div,
       xca.torihiki_form torihiki_form,
       xca.delivery_form delivery_form,
       xca.wholesale_ctrl_code wholesale_ctrl_code,
       xca.ship_storage_code ship_storage_code,
       xca.start_tran_date start_tran_date,
       xca.final_tran_date final_tran_date,
       xca.past_final_tran_date past_final_tran_date,
       xca.final_call_date final_call_date,
       xca.stop_approval_date stop_approval_date,
       xca.stop_approval_reason stop_approval_reason,
       xca.vist_untarget_date vist_untarget_date,
       xca.vist_target_div vist_target_div,
       xca.party_representative_name party_representative_name,
       xca.party_emp_name party_emp_name,
       xca.sale_base_code sale_base_code,
       xca.past_sale_base_code past_sale_base_code,
       xca.rsv_sale_base_act_date rsv_sale_base_act_date,
       xca.rsv_sale_base_code rsv_sale_base_code,
       xca.delivery_base_code delivery_base_code,
       xca.sales_head_base_code sales_head_base_code,
       xca.chain_store_code chain_store_code,
       xca.store_code store_code,
       xca.cust_store_name cust_store_name,
       xca.torihikisaki_code torihikisaki_code,
       xca.sales_chain_code sales_chain_code,
       xca.delivery_chain_code delivery_chain_code,
       xca.policy_chain_code policy_chain_code,
       xca.intro_chain_code1 intro_chain_code1,
       xca.intro_chain_code2 intro_chain_code2,
       xca.tax_div tax_div,
       xca.rate rate,
       xca.receiv_discount_rate receiv_discount_rate,
       xca.conclusion_day1 conclusion_day1,
       xca.conclusion_day2 conclusion_day2,
       xca.conclusion_day3 conclusion_day3,
       xca.contractor_supplier_code contractor_supplier_code,
       xca.bm_pay_supplier_code1 bm_pay_supplier_code1,
       xca.bm_pay_supplier_code2 bm_pay_supplier_code2,
       xca.delivery_order delivery_order,
       xca.edi_district_code edi_district_code,
       xca.edi_district_name edi_district_name,
       xca.edi_district_kana edi_district_kana,
       xca.center_edi_div center_edi_div,
       xca.tsukagatazaiko_div tsukagatazaiko_div,
       xca.establishment_location establishment_location,
       xca.open_close_div open_close_div,
       xca.operation_div operation_div,
       xca.change_amount change_amount,
       xca.vendor_machine_number vendor_machine_number,
-- 2011/09/29 �̔��\�����X�V�Ή� add start by Kenichi.Nakamura
       xca.calendar_code calendar_code,
-- 2011/09/29 �̔��\�����X�V�Ή� add end by Kenichi.Nakamura
       xca.established_site_name established_site_name,
       xca.cnvs_date cnvs_date,
       xca.cnvs_base_code cnvs_base_code,
       xca.cnvs_business_person cnvs_business_person,
       xca.new_point_div new_point_div,
       xca.new_point new_point,
       xca.intro_base_code intro_base_code,
       xca.intro_business_person intro_business_person,
       xca.edi_chain_code edi_chain_code,
       xca.latitude latitude,
       xca.longitude longitude,
       xca.management_base_code management_base_code,
       xca.edi_item_code_div edi_item_code_div,
       xca.edi_forward_number edi_forward_number,
       xca.handwritten_slip_div handwritten_slip_div,
       xca.deli_center_code deli_center_code,
       xca.deli_center_name deli_center_name,
       xca.dept_hht_div dept_hht_div,
       xca.bill_base_code bill_base_code,
       xca.receiv_base_code receiv_base_code,
       xca.child_dept_shop_code child_dept_shop_code,
       xca.parnt_dept_shop_code parnt_dept_shop_code,
       xca.past_customer_status past_customer_status,
       xca.card_company_div card_company_div,
       xca.card_company card_company,
-- 2009/09/15 ��Q0001350 add start by Yutaka.Kuboshima
       xca.invoice_printing_unit,
       xca.invoice_code,
       xca.enclose_invoice_code,
-- 2009/09/15 ��Q0001350 add end by Yutaka.Kuboshima
-- 2010/09/22 ��QE_�{�ғ�_02021 add start by Shigeto.Niki
       xca.store_cust_code,
-- 2010/09/22 ��QE_�{�ғ�_02021 add end by Shigeto.Niki
-- 2014/11/21 [E_�{�ғ�_12237]�q�ɊǗ��V�X�e���Ή� mod start by Yasunari.Nagasue
       xca.cust_fresh_con_code cust_fresh_con_code,
-- 2014/11/21 [E_�{�ғ�_12237]�q�ɊǗ��V�X�e���Ή� mod end   by Yasunari.Nagasue
-- 2017/04/05 [E_�{�ғ�_13976]eSM�O���f�[�^�A�g�Ή� add start by S.Yamashita
       xca.esm_target_div esm_target_div,
-- 2017/04/05 [E_�{�ғ�_13976]eSM�O���f�[�^�A�g�Ή� add end by S.Yamashita
-- 2017/06/14 [E_�{�ғ�_14271]add start
       xca.offset_cust_div offset_cust_div,
       xca.offset_cust_code offset_cust_code,
       xca.bp_customer_code bp_customer_code,
-- 2017/06/14 [E_�{�ғ�_14271]add end
       xca.created_by created_by,
       xca.creation_date creation_date,
       xca.last_updated_by last_updated_by,
       xca.last_update_date last_update_date,
       hp.last_update_date last_update_date_hp,
       hca.last_update_date last_update_date_hca,
       xca.last_update_login last_update_login,
       xca.request_id request_id,
       xca.program_application_id program_application_id,
       xca.program_id program_id,
       xca.program_update_date program_update_date
FROM xxcmm_cust_accounts xca,
     hz_cust_accounts hca,
     hz_parties hp
WHERE xca.customer_id = hca.cust_account_id
  AND hca.party_id    = hp.party_id
/
COMMENT ON TABLE apps.xxcmm_cust_accounts_v IS '�ڋq�ǉ����r���['
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.customer_id IS '�ڋqID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.party_id IS '�p�[�e�BID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.customer_code IS '�ڋq�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.customer_status IS '�ڋq�X�e�[�^�X'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cust_update_flag IS '�V�K�^�X�V�t���O'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.business_low_type IS '�Ƒԁi�����ށj'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.industry_div IS '�Ǝ�'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.selling_transfer_div IS '������ѐU��'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.torihiki_form IS '����`��'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.delivery_form IS '�z���`��'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.wholesale_ctrl_code IS '�≮�Ǘ��R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.ship_storage_code IS '�o�׌��ۊǏꏊ'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.start_tran_date IS '��������'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.final_tran_date IS '�ŏI�����'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.past_final_tran_date IS '�O���ŏI�����'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.final_call_date IS '�ŏI�K���'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.stop_approval_date IS '���~���ٓ�'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.stop_approval_reason IS '���~���R'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.vist_untarget_date IS '�ڋq�ΏۊO�ύX��'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.vist_target_div IS '�K��Ώۋ敪'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.party_representative_name IS '��\�Җ��i�����j'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.party_emp_name IS '�S���ҁi�����j'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.sale_base_code IS '���㋒�_�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.past_sale_base_code IS '�O�����㋒�_�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.rsv_sale_base_act_date IS '�\�񔄏㋒�_�L���J�n��'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.rsv_sale_base_code IS '�\�񔄏㋒�_�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.delivery_base_code IS '�[�i���_�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.sales_head_base_code IS '�̔���{���S�����_�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.chain_store_code IS '�`�F�[���X�R�[�h�iEDI�j'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.store_code IS '�X�܃R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cust_store_name IS '�ڋq�X�ܖ���'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.torihikisaki_code IS '�����R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.sales_chain_code IS '�̔���`�F�[���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.delivery_chain_code IS '�[�i��`�F�[���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.policy_chain_code IS '�����p�`�F�[���R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_chain_code1 IS '�Љ�҃`�F�[���R�[�h�P'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_chain_code2 IS '�Љ�҃`�F�[���R�[�h�Q'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.tax_div IS '����ŋ敪'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.rate IS '�����v�Z�p�|��'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.receiv_discount_rate IS '�����l����'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.conclusion_day1 IS '�����v�Z���ߓ��P'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.conclusion_day2 IS '�����v�Z���ߓ��Q'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.conclusion_day3 IS '�����v�Z���ߓ��R'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.contractor_supplier_code IS '�_��Ҏd����R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.bm_pay_supplier_code1 IS '�Љ��BM�x���d����R�[�h�P'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.bm_pay_supplier_code2 IS '�Љ��BM�x���d����R�[�h�Q'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.delivery_order IS '�z�����iEDI)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_district_code IS 'EDI�n��R�[�h�iEDI)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_district_name IS 'EDI�n�於�iEDI)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_district_kana IS 'EDI�n�於�J�i�iEDI)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.center_edi_div IS '�Z���^�[EDI�敪'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.tsukagatazaiko_div IS '�ʉߍ݌Ɍ^�敪�iEDI�j'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.establishment_location IS '�ݒu���P�[�V����'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.open_close_div IS '�����I�[�v���E�N���[�Y�敪'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.operation_div IS '�I�y���[�V�����敪'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.change_amount IS '�ޑK'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.vendor_machine_number IS '�����̔��@�ԍ��i�����j'
/
-- 2011/09/29 �̔��\�����X�V�Ή� add start by Kenichi.Nakamura
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.calendar_code IS '�ғ����J�����_�R�[�h'
/
-- 2011/09/29 �̔��\�����X�V�Ή� add end by Kenichi.Nakamura
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.established_site_name IS '�ݒu�於�i�����j'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cnvs_date IS '�ڋq�l����'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cnvs_base_code IS '�l�����_�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cnvs_business_person IS '�l���c�ƈ�'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.new_point_div IS '�V�K�|�C���g�敪'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.new_point IS '�V�K�|�C���g'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_base_code IS '�Љ�_�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_business_person IS '�Љ�c�ƈ�'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_chain_code IS '�`�F�[���X�R�[�h(EDI)�y�e���R�[�h�p�z'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.latitude IS '�ܓx'
/
-- 2011/05/18 ��QE_�{�ғ�_07429 modify start by Shigeto.Niki
--COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.longitude IS '�o�x'
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.longitude IS '�s�[�N�J�b�g�J�n����'
-- 2011/05/18 ��QE_�{�ғ�_07429 modify end by Shigeto.Niki
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.management_base_code IS '�Ǘ������_�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_item_code_div IS 'EDI�A�g�i�ڃR�[�h�敪'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_forward_number IS 'EDI�`���ǔ�'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.handwritten_slip_div IS 'EDI�菑�`�[�`���敪'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.deli_center_code IS 'EDI�[�i�Z���^�[�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.deli_center_name IS 'EDI�[�i�Z���^�[��'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.dept_hht_div IS '�S�ݓX�pHHT�敪'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.bill_base_code IS '�������_�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.receiv_base_code IS '�������_�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.child_dept_shop_code IS '�S�ݓX�`��R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.parnt_dept_shop_code IS '�S�ݓX�`��R�[�h�y�e���R�[�h�p�z'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.past_customer_status IS '�O���ڋq�X�e�[�^�X'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.card_company_div IS '�J�[�h��Ћ敪'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.card_company IS '�J�[�h��ЃR�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.invoice_printing_unit IS '����������P��'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.invoice_code IS '�������p�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.enclose_invoice_code IS '�����������p�R�[�h'
/
-- 2010/09/22 ��QE_�{�ғ�_02021 add start by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.store_cust_code IS '�X�܉c�Ɨp�ڋq�R�[�h'
/
-- 2010/09/22 ��QE_�{�ғ�_02021 add end by Shigeto.Niki
-- 2014/11/21 [E_�{�ғ�_12237]�q�ɊǗ��V�X�e���Ή� mod start by Yasunari.Nagasue
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cust_fresh_con_code IS '�ڋq�ʑN�x�����R�[�h'
/
-- 2014/11/21 [E_�{�ғ�_12237]�q�ɊǗ��V�X�e���Ή� mod end   by Yasunari.Nagasue
-- 2017/04/05 [E_�{�ғ�_13976]eSM�O���f�[�^�A�g�Ή� add start by S.Yamashita
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.esm_target_div IS '�X�g���|�����k����A�g�Ώۃt���O'
/
-- 2017/04/05 [E_�{�ғ�_13976]eSM�O���f�[�^�A�g�Ή� add end by S.Yamashita
-- 2017/06/14 [E_�{�ғ�_14271]add start
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.offset_cust_div IS '���E�p�ڋq�敪'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.offset_cust_code IS '���E�p�ڋq�R�[�h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.bp_customer_code IS '�����ڋq�R�[�h'
/
-- 2017/06/14 [E_�{�ғ�_14271]add end
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.created_by IS '�쐬��'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.creation_date IS '�쐬��'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_updated_by IS '�ŏI�X�V��'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_update_date IS '�ŏI�X�V����'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_update_date_hp IS '�ŏI�X�V����(�p�[�e�B)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_update_date_hca IS '�ŏI�X�V����(�ڋq�}�X�^)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_update_login IS '�ŏI�X�V۸޲�'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.request_id IS '�v��ID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.program_application_id IS '�ݶ��ĥ��۸��ѥ���ع����ID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.program_id IS '�ݶ��ĥ��۸���ID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.program_update_date IS '��۸��эX�V��'
/
