-- 2011/09/29 販売予測情報更新対応 mod start by Kenichi.Nakamura
-- 2010/09/22 障害E_本稼動_02021 mod start by Shigeto.Niki
--CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
--CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,store_cust_code,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
CREATE OR REPLACE FORCE VIEW APPS.XXCMM_CUST_ACCOUNTS_V (customer_id,party_id,customer_code,customer_status,cust_update_flag,business_low_type,industry_div,selling_transfer_div,torihiki_form,delivery_form,wholesale_ctrl_code,ship_storage_code,start_tran_date,final_tran_date,past_final_tran_date,final_call_date,stop_approval_date,stop_approval_reason,vist_untarget_date,vist_target_div,party_representative_name,party_emp_name,sale_base_code,past_sale_base_code,rsv_sale_base_act_date,rsv_sale_base_code,delivery_base_code,sales_head_base_code,chain_store_code,store_code,cust_store_name,torihikisaki_code,sales_chain_code,delivery_chain_code,policy_chain_code,intro_chain_code1,intro_chain_code2,tax_div,rate,receiv_discount_rate,conclusion_day1,conclusion_day2,conclusion_day3,contractor_supplier_code,bm_pay_supplier_code1,bm_pay_supplier_code2,delivery_order,edi_district_code,edi_district_name,edi_district_kana,center_edi_div,tsukagatazaiko_div,establishment_location,open_close_div,operation_div,change_amount,vendor_machine_number,calendar_code,established_site_name,cnvs_date,cnvs_base_code,cnvs_business_person,new_point_div,new_point,intro_base_code,intro_business_person,edi_chain_code,latitude,longitude,management_base_code,edi_item_code_div,edi_forward_number,handwritten_slip_div,deli_center_code,deli_center_name,dept_hht_div,bill_base_code,receiv_base_code,child_dept_shop_code,parnt_dept_shop_code,past_customer_status,card_company_div,card_company,invoice_printing_unit,invoice_code,enclose_invoice_code,store_cust_code,created_by,creation_date,last_updated_by,last_update_date,last_update_date_hp,last_update_date_hca,last_update_login,request_id,program_application_id,program_id,program_update_date) AS
-- 2010/09/22 障害E_本稼動_02021 mod end by Shigeto.Niki
-- 2011/09/29 販売予測情報更新対応 mod end by Kenichi.Nakamura
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
-- 2011/09/29 販売予測情報更新対応 add start by Kenichi.Nakamura
       xca.calendar_code calendar_code,
-- 2011/09/29 販売予測情報更新対応 add end by Kenichi.Nakamura
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
-- 2009/09/15 障害0001350 add start by Yutaka.Kuboshima
       xca.invoice_printing_unit,
       xca.invoice_code,
       xca.enclose_invoice_code,
-- 2009/09/15 障害0001350 add end by Yutaka.Kuboshima
-- 2010/09/22 障害E_本稼動_02021 add start by Shigeto.Niki
       xca.store_cust_code,
-- 2010/09/22 障害E_本稼動_02021 add end by Shigeto.Niki
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
COMMENT ON TABLE apps.xxcmm_cust_accounts_v IS '顧客追加情報ビュー'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.customer_id IS '顧客ID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.party_id IS 'パーティID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.customer_code IS '顧客コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.customer_status IS '顧客ステータス'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cust_update_flag IS '新規／更新フラグ'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.business_low_type IS '業態（小分類）'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.industry_div IS '業種'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.selling_transfer_div IS '売上実績振替'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.torihiki_form IS '取引形態'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.delivery_form IS '配送形態'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.wholesale_ctrl_code IS '問屋管理コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.ship_storage_code IS '出荷元保管場所'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.start_tran_date IS '初回取引日'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.final_tran_date IS '最終取引日'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.past_final_tran_date IS '前月最終取引日'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.final_call_date IS '最終訪問日'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.stop_approval_date IS '中止決裁日'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.stop_approval_reason IS '中止理由'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.vist_untarget_date IS '顧客対象外変更日'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.vist_target_div IS '訪問対象区分'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.party_representative_name IS '代表者名（相手先）'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.party_emp_name IS '担当者（相手先）'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.sale_base_code IS '売上拠点コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.past_sale_base_code IS '前月売上拠点コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.rsv_sale_base_act_date IS '予約売上拠点有効開始日'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.rsv_sale_base_code IS '予約売上拠点コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.delivery_base_code IS '納品拠点コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.sales_head_base_code IS '販売先本部担当拠点コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.chain_store_code IS 'チェーン店コード（EDI）'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.store_code IS '店舗コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cust_store_name IS '顧客店舗名称'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.torihikisaki_code IS '取引先コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.sales_chain_code IS '販売先チェーンコード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.delivery_chain_code IS '納品先チェーンコード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.policy_chain_code IS '政策用チェーンコード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_chain_code1 IS '紹介者チェーンコード１'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_chain_code2 IS '紹介者チェーンコード２'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.tax_div IS '消費税区分'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.rate IS '消化計算用掛率'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.receiv_discount_rate IS '入金値引率'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.conclusion_day1 IS '消化計算締め日１'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.conclusion_day2 IS '消化計算締め日２'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.conclusion_day3 IS '消化計算締め日３'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.contractor_supplier_code IS '契約者仕入先コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.bm_pay_supplier_code1 IS '紹介者BM支払仕入先コード１'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.bm_pay_supplier_code2 IS '紹介者BM支払仕入先コード２'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.delivery_order IS '配送順（EDI)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_district_code IS 'EDI地区コード（EDI)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_district_name IS 'EDI地区名（EDI)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_district_kana IS 'EDI地区名カナ（EDI)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.center_edi_div IS 'センターEDI区分'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.tsukagatazaiko_div IS '通過在庫型区分（EDI）'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.establishment_location IS '設置ロケーション'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.open_close_div IS '物件オープン・クローズ区分'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.operation_div IS 'オペレーション区分'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.change_amount IS '釣銭'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.vendor_machine_number IS '自動販売機番号（相手先）'
/
-- 2011/09/29 販売予測情報更新対応 add start by Kenichi.Nakamura
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.calendar_code IS '稼働日カレンダコード'
/
-- 2011/09/29 販売予測情報更新対応 add end by Kenichi.Nakamura
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.established_site_name IS '設置先名（相手先）'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cnvs_date IS '顧客獲得日'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cnvs_base_code IS '獲得拠点コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.cnvs_business_person IS '獲得営業員'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.new_point_div IS '新規ポイント区分'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.new_point IS '新規ポイント'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_base_code IS '紹介拠点コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.intro_business_person IS '紹介営業員'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_chain_code IS 'チェーン店コード(EDI)【親レコード用】'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.latitude IS '緯度'
/
-- 2011/05/18 障害E_本稼動_07429 modify start by Shigeto.Niki
--COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.longitude IS '経度'
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.longitude IS 'ピークカット開始時刻'
-- 2011/05/18 障害E_本稼動_07429 modify end by Shigeto.Niki
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.management_base_code IS '管理元拠点コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_item_code_div IS 'EDI連携品目コード区分'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.edi_forward_number IS 'EDI伝送追番'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.handwritten_slip_div IS 'EDI手書伝票伝送区分'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.deli_center_code IS 'EDI納品センターコード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.deli_center_name IS 'EDI納品センター名'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.dept_hht_div IS '百貨店用HHT区分'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.bill_base_code IS '請求拠点コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.receiv_base_code IS '入金拠点コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.child_dept_shop_code IS '百貨店伝区コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.parnt_dept_shop_code IS '百貨店伝区コード【親レコード用】'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.past_customer_status IS '前月顧客ステータス'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.card_company_div IS 'カード会社区分'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.card_company IS 'カード会社コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.invoice_printing_unit IS '請求書印刷単位'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.invoice_code IS '請求書用コード'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.enclose_invoice_code IS '統括請求書用コード'
/
-- 2010/09/22 障害E_本稼動_02021 add start by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.store_cust_code IS '店舗営業用顧客コード'
/
-- 2010/09/22 障害E_本稼動_02021 add end by Shigeto.Niki
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.created_by IS '作成者'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.creation_date IS '作成日'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_updated_by IS '最終更新者'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_update_date IS '最終更新日時'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_update_date_hp IS '最終更新日時(パーティ)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_update_date_hca IS '最終更新日時(顧客マスタ)'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.last_update_login IS '最終更新ﾛｸﾞｲﾝ'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.request_id IS '要求ID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.program_application_id IS 'ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.program_id IS 'ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID'
/
COMMENT ON COLUMN apps.xxcmm_cust_accounts_v.program_update_date IS 'ﾌﾟﾛｸﾞﾗﾑ更新日'
/
