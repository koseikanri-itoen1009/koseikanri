/*************************************************************************
 * 
 * VIEW Name       : XXCSO_RESOURCE_CUSTS_V2
 * Description     : 共通用：営業員担当顧客（最新）ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_RESOURCE_CUSTS_V2
(
 employee_number
,party_id
,cust_account_id
,account_number
)
AS
SELECT
 hopeb.c_ext_attr1
,hp.party_id
,hca.cust_account_id
,hca.account_number
FROM
 fnd_application fa
,ego_fnd_dsc_flx_ctx_ext efdfce
,hz_org_profiles_ext_b hopeb
,hz_organization_profiles hop
,hz_parties hp
,hz_cust_accounts hca
WHERE
fa.application_short_name = 'AR' AND
efdfce.application_id = fa.application_id AND
efdfce.descriptive_flexfield_name = 'HZ_ORG_PROFILES_GROUP' AND
efdfce.descriptive_flex_context_code = 'RESOURCE' AND
hopeb.attr_group_id = efdfce.attr_group_id AND
hopeb.d_ext_attr1 <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
NVL(hopeb.d_ext_attr2, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
hop.organization_profile_id = hopeb.organization_profile_id AND
hop.effective_end_date IS NULL AND
hp.party_id = hop.party_id AND
hca.party_id = hp.party_id
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_RESOURCE_CUSTS_V2.employee_number IS '従業員番号';
COMMENT ON COLUMN XXCSO_RESOURCE_CUSTS_V2.party_id IS 'パーティID';
COMMENT ON COLUMN XXCSO_RESOURCE_CUSTS_V2.cust_account_id IS 'アカウントID';
COMMENT ON COLUMN XXCSO_RESOURCE_CUSTS_V2.account_number IS '顧客コード';
COMMENT ON TABLE XXCSO_RESOURCE_CUSTS_V2 IS '共通用：営業員担当顧客（最新）ビュー';
