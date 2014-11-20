/*************************************************************************
 * 
 * VIEW Name       : XXCSO_CUST_ROUTES_V
 * Description     : 共通用：顧客ルートNoビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_CUST_ROUTES_V
(
 party_id
,cust_account_id
,account_number
,route_number
,start_date_active
,end_date_active
)
AS
SELECT
 hp.party_id
,hca.cust_account_id
,hca.account_number
,hopeb.c_ext_attr2
,hopeb.d_ext_attr3
,hopeb.d_ext_attr4
FROM
 hz_parties hp
,hz_cust_accounts hca
,hz_organization_profiles hop
,fnd_application fa
,ego_fnd_dsc_flx_ctx_ext efdfce
,hz_org_profiles_ext_b hopeb
WHERE
hca.party_id = hp.party_id AND
hop.effective_end_date IS NULL AND
hop.party_id = hp.party_id AND
fa.application_short_name = 'AR' AND
efdfce.application_id = fa.application_id AND
efdfce.descriptive_flexfield_name = 'HZ_ORG_PROFILES_GROUP' AND
efdfce.descriptive_flex_context_code = 'ROUTE' AND
hopeb.attr_group_id = efdfce.attr_group_id AND
hopeb.organization_profile_id = hop.organization_profile_id
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_CUST_ROUTES_V.party_id IS 'パーティID';
COMMENT ON COLUMN XXCSO_CUST_ROUTES_V.cust_account_id IS 'アカウントID';
COMMENT ON COLUMN XXCSO_CUST_ROUTES_V.account_number IS '顧客コード';
COMMENT ON COLUMN XXCSO_CUST_ROUTES_V.route_number IS 'ルートNo';
COMMENT ON COLUMN XXCSO_CUST_ROUTES_V.start_date_active IS '適用開始日';
COMMENT ON COLUMN XXCSO_CUST_ROUTES_V.end_date_active IS '適用終了日';
COMMENT ON TABLE XXCSO_CUST_ROUTES_V IS '共通用：顧客ルートNoビュー';
