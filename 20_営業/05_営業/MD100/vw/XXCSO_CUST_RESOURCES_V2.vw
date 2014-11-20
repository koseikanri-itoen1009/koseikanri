/*************************************************************************
 * 
 * VIEW Name       : XXCSO_CUST_RESOURCES_V2
 * Description     : 共通用：顧客担当営業員（最新）ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_CUST_RESOURCES_V2
(
 party_id
,cust_account_id
,account_number
,employee_number
)
AS
SELECT
 hp.party_id
,hca.cust_account_id
,hca.account_number
,hopeb.c_ext_attr1
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
efdfce.descriptive_flex_context_code = 'RESOURCE' AND
hopeb.attr_group_id = efdfce.attr_group_id AND
hopeb.organization_profile_id = hop.organization_profile_id AND
hopeb.d_ext_attr1 <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
NVL(hopeb.d_ext_attr2, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_CUST_RESOURCES_V2.party_id IS 'パーティID';
COMMENT ON COLUMN XXCSO_CUST_RESOURCES_V2.cust_account_id IS 'アカウントID';
COMMENT ON COLUMN XXCSO_CUST_RESOURCES_V2.account_number IS '顧客コード';
COMMENT ON COLUMN XXCSO_CUST_RESOURCES_V2.employee_number IS '従業員番号';
COMMENT ON TABLE XXCSO_CUST_RESOURCES_V2 IS '共通用：顧客担当営業員（最新）ビュー';
