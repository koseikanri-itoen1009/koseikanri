-- 2011/09/29 Ì\ªîñXVÎ mod start by Kenichi.Nakamura
-- 2010/09/22 áQE_{Ò®_02021 mod start by Shigeto.Niki
--CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
--CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,store_cust_code,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
-- 2014/11/21 [E_{Ò®_12237]qÉÇVXeÎ mod start by Yasunari.Nagasue
--CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,calendar_code,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,store_cust_code,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
-- 2017/04/05 [E_{Ò®_13976]eSMOf[^AgÎ mod start by S.Yamashita
--CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,calendar_code,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,store_cust_code,cust_fresh_con_code,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
-- 2017/06/14 [E_{Ò®_14271]mod start
--CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,calendar_code,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,store_cust_code,cust_fresh_con_code,esm_target_div,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V
AS
-- 2017/06/14 [E_{Ò®_14271]mod end
-- 2017/04/05 [E_{Ò®_13976]eSMOf[^AgÎ mod end by S.Yamashita
-- 2014/11/21 [E_{Ò®_12237]qÉÇVXeÎ mod end   by Yasunari.Nagasue
-- 2010/09/22 áQE_{Ò®_02021 mod end by Shigeto.Niki
-- 2011/09/29 Ì\ªîñXVÎ mod end by Kenichi.Nakamura
-- 2024/07/09 [E_{Ò®_20030] add
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
-- 2011/09/29 Ì\ªîñXVÎ add start by Kenichi.Nakamura
       xca.calendar_code calendar_code,
-- 2011/09/29 Ì\ªîñXVÎ add end by Kenichi.Nakamura
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
-- 2009/09/15 áQ0001350 add start by Yutaka.Kuboshima
       xca.invoice_printing_unit,
       xca.invoice_code,
       xca.enclose_invoice_code,
-- 2009/09/15 áQ0001350 add end by Yutaka.Kuboshima
-- 2010/09/22 áQE_{Ò®_02021 add start by Shigeto.Niki
       xca.store_cust_code,
-- 2010/09/22 áQE_{Ò®_02021 add end by Shigeto.Niki
-- 2014/11/21 [E_{Ò®_12237]qÉÇVXeÎ mod start by Yasunari.Nagasue
       xca.cust_fresh_con_code cust_fresh_con_code,
-- 2014/11/21 [E_{Ò®_12237]qÉÇVXeÎ mod end   by Yasunari.Nagasue
-- 2017/04/05 [E_{Ò®_13976]eSMOf[^AgÎ add start by S.Yamashita
       xca.esm_target_div esm_target_div,
-- 2017/04/05 [E_{Ò®_13976]eSMOf[^AgÎ add end by S.Yamashita
-- 2017/06/14 [E_{Ò®_14271]add start
       xca.offset_cust_div offset_cust_div,
       xca.offset_cust_code offset_cust_code,
       xca.bp_customer_code bp_customer_code,
-- 2017/06/14 [E_{Ò®_14271]add end
-- 2023/03/01 [E_{Ò®_19080]add start
       xca.invoice_tax_div,
-- 2023/03/01 [E_{Ò®_19080]add end
-- 2024/07/09 [E_{Ò®_20030] add start
       xca.pos_enterprise_code,
       xca.pos_store_code,
-- 2024/07/09 [E_{Ò®_20030] add end
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
COMMENT ON TABLE apps.xxcmm_cust_accounts_v IS 'ÚqÇÁîñr['
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.customer_id IS 'ÚqID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.party_id IS 'p[eBID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.customer_code IS 'ÚqR[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.customer_status IS 'ÚqXe[^X'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cust_update_flag IS 'VK^XVtO'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.business_low_type IS 'ÆÔi¬ªÞj'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.industry_div IS 'Æí'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.selling_transfer_div IS 'ãÀÑUÖ'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.torihiki_form IS 'æø`Ô'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.delivery_form IS 'z`Ô'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.wholesale_ctrl_code IS 'â®ÇR[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.ship_storage_code IS 'o×³ÛÇê'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.start_tran_date IS 'ñæøú'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.final_tran_date IS 'ÅIæøú'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.past_final_tran_date IS 'OÅIæøú'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.final_call_date IS 'ÅIKâú'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.stop_approval_date IS '~Ùú'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.stop_approval_reason IS '~R'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.vist_untarget_date IS 'ÚqÎÛOÏXú'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.vist_target_div IS 'KâÎÛæª'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.party_representative_name IS 'ã\Ò¼ièæj'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.party_emp_name IS 'SÒièæj'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.sale_base_code IS 'ã_R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.past_sale_base_code IS 'Oã_R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.rsv_sale_base_act_date IS '\ñã_LøJnú'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.rsv_sale_base_code IS '\ñã_R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.delivery_base_code IS '[i_R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.sales_head_base_code IS 'Ìæ{S_R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.chain_store_code IS '`F[XR[hiEDIj'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.store_code IS 'XÜR[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cust_store_name IS 'ÚqXÜ¼Ì'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.torihikisaki_code IS 'æøæR[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.sales_chain_code IS 'Ìæ`F[R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.delivery_chain_code IS '[iæ`F[R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.policy_chain_code IS '­ôp`F[R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_chain_code1 IS 'ÐîÒ`F[R[hP'
/
-- 2021/05/31 [E_{Ò®_16026]mod start
--COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_chain_code2 IS 'ÐîÒ`F[R[hQ'
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_chain_code2 IS 'Tp`F[R[h'
-- 2021/05/31 [E_{Ò®_16026]mod end
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.tax_div IS 'ÁïÅæª'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.rate IS 'Á»vZp|¦'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.receiv_discount_rate IS 'üàlø¦'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.conclusion_day1 IS 'Á»vZ÷ßúP'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.conclusion_day2 IS 'Á»vZ÷ßúQ'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.conclusion_day3 IS 'Á»vZ÷ßúR'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.contractor_supplier_code IS '_ñÒdüæR[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.bm_pay_supplier_code1 IS 'ÐîÒBMx¥düæR[hP'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.bm_pay_supplier_code2 IS 'ÐîÒBMx¥düæR[hQ'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.delivery_order IS 'ziEDI)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_district_code IS 'EDInæR[hiEDI)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_district_name IS 'EDInæ¼iEDI)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_district_kana IS 'EDInæ¼JiiEDI)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.center_edi_div IS 'Z^[EDIæª'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.tsukagatazaiko_div IS 'ÊßÝÉ^æªiEDIj'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.establishment_location IS 'ÝuP[V'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.open_close_div IS '¨I[vEN[Yæª'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.operation_div IS 'Iy[Væª'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.change_amount IS 'ÞK'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.vendor_machine_number IS '©®Ì@Ôièæj'
/
-- 2011/09/29 Ì\ªîñXVÎ add start by Kenichi.Nakamura
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.calendar_code IS 'Ò­úJ_R[h'
/
-- 2011/09/29 Ì\ªîñXVÎ add end by Kenichi.Nakamura
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.established_site_name IS 'Ýuæ¼ièæj'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cnvs_date IS 'Úql¾ú'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cnvs_base_code IS 'l¾_R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cnvs_business_person IS 'l¾cÆõ'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.new_point_div IS 'VK|Cgæª'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.new_point IS 'VK|Cg'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_base_code IS 'Ðî_R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_business_person IS 'ÐîcÆõ'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_chain_code IS '`F[XR[h(EDI)yeR[hpz'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.latitude IS 'Üx'
/
-- 2011/05/18 áQE_{Ò®_07429 modify start by Shigeto.Niki
--COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.longitude IS 'ox'
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.longitude IS 's[NJbgJn'
-- 2011/05/18 áQE_{Ò®_07429 modify end by Shigeto.Niki
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.management_base_code IS 'Ç³_R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_item_code_div IS 'EDIAgiÚR[hæª'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_forward_number IS 'EDI`ÇÔ'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.handwritten_slip_div IS 'EDIè`[`æª'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.deli_center_code IS 'EDI[iZ^[R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.deli_center_name IS 'EDI[iZ^[¼'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.dept_hht_div IS 'SÝXpHHTæª'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.bill_base_code IS '¿_R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.receiv_base_code IS 'üà_R[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.child_dept_shop_code IS 'SÝX`æR[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.parnt_dept_shop_code IS 'SÝX`æR[hyeR[hpz'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.past_customer_status IS 'OÚqXe[^X'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.card_company_div IS 'J[hïÐæª'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.card_company IS 'J[hïÐR[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.invoice_printing_unit IS '¿óüPÊ'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.invoice_code IS '¿pR[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.enclose_invoice_code IS '¿pR[h'
/
-- 2010/09/22 áQE_{Ò®_02021 add start by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.store_cust_code IS 'XÜcÆpÚqR[h'
/
-- 2010/09/22 áQE_{Ò®_02021 add end by Shigeto.Niki
-- 2014/11/21 [E_{Ò®_12237]qÉÇVXeÎ mod start by Yasunari.Nagasue
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cust_fresh_con_code IS 'ÚqÊNxðR[h'
/
-- 2014/11/21 [E_{Ò®_12237]qÉÇVXeÎ mod end   by Yasunari.Nagasue
-- 2017/04/05 [E_{Ò®_13976]eSMOf[^AgÎ add start by S.Yamashita
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.esm_target_div IS 'Xg|¤k­ñAgÎÛtO'
/
-- 2017/04/05 [E_{Ò®_13976]eSMOf[^AgÎ add end by S.Yamashita
-- 2017/06/14 [E_{Ò®_14271]add start
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.offset_cust_div IS 'EpÚqæª'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.offset_cust_code IS 'EpÚqR[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.bp_customer_code IS 'æøæÚqR[h'
/
-- 2017/06/14 [E_{Ò®_14271]add end
-- 2023/03/01 [E_{Ò®_19080]add start
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.invoice_tax_div IS '¿ÁïÅÏã°vZû®'
/
-- 2023/03/01 [E_{Ò®_19080]add end
-- 2024/07/09 [E_{Ò®_20030] add start
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.pos_enterprise_code IS 'POSéÆR[h'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.pos_store_code IS 'POSXÜR[h'
/
-- 2024/07/09 [E_{Ò®_20030] add end
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.created_by IS 'ì¬Ò'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.creation_date IS 'ì¬ú'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_updated_by IS 'ÅIXVÒ'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_update_date IS 'ÅIXVú'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_update_date_hp IS 'ÅIXVú(p[eB)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_update_date_hca IS 'ÅIXVú(Úq}X^)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_update_login IS 'ÅIXVÛ¸Þ²Ý'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.request_id IS 'vID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.program_application_id IS 'ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×Ñ¥±ÌßØ¹°¼®ÝID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.program_id IS 'ºÝ¶ÚÝÄ¥ÌßÛ¸Þ×ÑID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.program_update_date IS 'ÌßÛ¸Þ×ÑXVú'
/
