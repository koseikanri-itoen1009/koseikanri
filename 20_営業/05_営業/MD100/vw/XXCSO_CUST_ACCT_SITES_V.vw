/*************************************************************************
 * 
 * VIEW Name       : XXCSO_CUST_ACCT_SITES_V
 * Description     : 共通用：顧客マスタサイトビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
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
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.account_number IS '顧客コード';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.cust_account_id IS 'アカウントID';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.account_name IS '略称';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.customer_class_code IS '顧客区分コード';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.customer_class_name IS '顧客区分名';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.account_status IS 'アカウントステータス';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.cust_acct_site_id IS '顧客所在地ID';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.acct_site_status IS '顧客所在地ステータス';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.location_id IS '顧客事業所ID';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.postal_code IS '郵便番号';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.state IS '都道府県';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.city IS '市・区';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.address1 IS '住所1';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.address2 IS '住所2';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.area_code IS '地区コード';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.phone_number IS '電話番号';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.fax_number IS 'FAX番号';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.business_low_type IS '業態（小分類）';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.industry_div IS '業種　  ';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.sale_base_code IS '売上拠点コード';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.management_base_code IS '管理元拠点コード';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.past_sale_base_code IS '前月売上拠点コード';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.rsv_sale_base_act_date IS '予約売上拠点有効開始日';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.rsv_sale_base_code IS '予約売上拠点コード';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.contractor_supplier_code IS '契約者仕入先コード';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.bm_pay_supplier_code1 IS '紹介者BM支払仕入先コード１';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.bm_pay_supplier_code2 IS '紹介者BM支払仕入先コード２';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.final_tran_date IS '最終取引日';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.final_call_date IS '最終訪問日';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_representative_name IS '代表者名（相手先）';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_emp_name IS '担当者（相手先）';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.established_site_name IS '設置先名';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.establishment_location IS '設置ロケーション';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.open_close_div IS '物件オープン・クローズ区分';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.operation_div IS 'オペレーション区分';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.vist_target_div IS '訪問対象区分（名称変更）';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.cnvs_date IS '顧客獲得日';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.cnvs_business_person IS '獲得営業員';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.cnvs_base_code IS '獲得拠点';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_id IS 'パーティID';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_name IS '顧客名';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.organization_name_phonetic IS '顧客名（カナ）';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_number IS 'パーティ番号';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_status IS 'パーティステータス';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.customer_status IS '顧客ステータス';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.employees IS '社員数';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_site_id IS 'パーティサイトID';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.party_site_status IS 'パーティサイトステータス';
COMMENT ON COLUMN XXCSO_CUST_ACCT_SITES_V.identifying_address_flag IS '識別所在地フラグ';
COMMENT ON TABLE XXCSO_CUST_ACCT_SITES_V IS '共通用：顧客マスタサイトビュー';
