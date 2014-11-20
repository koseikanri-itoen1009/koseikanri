/*************************************************************************
 * 
 * VIEW Name       : XXCSO_CUST_ACCOUNTS_V
 * Description     : 共通用：顧客マスタビュー
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 *  2010/01/06    1.1  D.Abe         E_本稼動_00069対応
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_CUST_ACCOUNTS_V
(
 account_number
,cust_account_id
,account_name
,customer_class_code
,customer_class_name
,account_status
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
,new_point_div
/* 2010.01.06 D.Abe E_本稼動_00069対応 START */
,torihiki_form
/* 2010.01.06 D.Abe E_本稼動_00069対応 END */
,party_id
,party_name
,organization_name_phonetic
,party_number
,party_status
,customer_status
,employees
)
AS
SELECT
 hca.account_number
,hca.cust_account_id
,hca.account_name
,hca.customer_class_code
,xxcso_util_common_pkg.get_lookup_meaning('CUSTOMER CLASS', hca.customer_class_code, xxcso_util_common_pkg.get_online_sysdate)
,hca.status
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
,xca.new_point_div
/* 2010.01.06 D.Abe E_本稼動_00069対応 START */
,xca.torihiki_form
/* 2010.01.06 D.Abe E_本稼動_00069対応 END */
,hp.party_id
,hp.party_name
,hp.organization_name_phonetic
,hp.party_number
,hp.status
,hp.duns_number_c
,hp.attribute2
FROM
 hz_parties hp
,hz_cust_accounts hca
,xxcmm_cust_accounts xca
WHERE
hca.party_id = hp.party_id AND
xca.customer_id(+) = hca.cust_account_id
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.account_number IS '顧客コード';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.cust_account_id IS 'アカウントID';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.account_name IS '略称';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.customer_class_code IS '顧客区分コード';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.customer_class_name IS '顧客区分名';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.account_status IS 'アカウントステータス';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.business_low_type IS '業態（小分類）';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.industry_div IS '業種　  ';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.sale_base_code IS '売上拠点コード';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.management_base_code IS '管理元拠点コード';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.past_sale_base_code IS '前月売上拠点コード';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.rsv_sale_base_act_date IS '予約売上拠点有効開始日';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.rsv_sale_base_code IS '予約売上拠点コード';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.contractor_supplier_code IS '契約者仕入先コード';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.bm_pay_supplier_code1 IS '紹介者BM支払仕入先コード１';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.bm_pay_supplier_code2 IS '紹介者BM支払仕入先コード２';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.final_tran_date IS '最終取引日';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.final_call_date IS '最終訪問日';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.party_representative_name IS '代表者名（相手先）';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.party_emp_name IS '担当者（相手先）';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.established_site_name IS '設置先名';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.establishment_location IS '設置ロケーション';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.open_close_div IS '物件オープン・クローズ区分';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.operation_div IS 'オペレーション区分';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.vist_target_div IS '訪問対象区分（名称変更）';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.cnvs_date IS '顧客獲得日';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.cnvs_business_person IS '獲得営業員';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.cnvs_base_code IS '獲得拠点';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.new_point_div IS '新規ポイント区分';
/* 2010.01.06 D.Abe E_本稼動_00069対応 START */
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.torihiki_form IS '取引形態';
/* 2010.01.06 D.Abe E_本稼動_00069対応 END */
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.party_id IS 'パーティID';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.party_name IS '顧客名';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.organization_name_phonetic IS '顧客名（カナ）';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.party_number IS 'パーティ番号';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.party_status IS 'パーティステータス';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.customer_status IS '顧客ステータス';
COMMENT ON COLUMN XXCSO_CUST_ACCOUNTS_V.employees IS '社員数';
COMMENT ON TABLE XXCSO_CUST_ACCOUNTS_V IS '共通用：顧客マスタビュー';
