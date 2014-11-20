/*************************************************************************
 * 
 * VIEW Name       : xxcso_rtn_rsrc_v
 * Description     : 画面用：訪問・売上計画／ルートNo担当営業員一括更新画面用ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 *  2009/03/05    1.1  N.Yanagitaira [CT1-034]TOO_MANY_ROWS対応
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_rtn_rsrc_v
(
 account_number
,cust_account_id
,created_by
,creation_date
,last_updated_by
,last_update_date
,last_update_login
,trgt_route_no
,trgt_route_no_start_date
,trgt_route_no_extension_id
,trgt_route_no_last_upd_date
,next_route_no
,next_route_no_start_date
,next_route_no_extension_id
,next_route_no_last_upd_date
,new_route_no
,new_route_no_start_date
,new_route_no_extension_id
,trgt_resource
,trgt_resource_start_date
,trgt_resource_extension_id
,trgt_resource_last_upd_date
,next_resource
,next_resource_start_date
,next_resource_extension_id
,next_resource_last_upd_date
,new_resource
,new_resource_start_date
,new_resource_extension_id
,trgt_resource_cnt
,next_resource_cnt
)
AS
SELECT  hca.account_number
       ,hca.cust_account_id
       ,fnd_global.user_id
       ,SYSDATE
       ,fnd_global.user_id
       ,SYSDATE
       ,fnd_global.login_id
       ,(SELECT  hopeb.c_ext_attr2
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                                 = rtn_ctx.attr_group_id
           AND   hopeb.organization_profile_id                       = hop.organization_profile_id
           AND   hopeb.d_ext_attr3                                  <= TRUNC(util.online_sysdate)
           AND   NVL(hopeb.d_ext_attr4, TRUNC(util.online_sysdate)) >= TRUNC(util.online_sysdate)
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.d_ext_attr3
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                                 = rtn_ctx.attr_group_id
           AND   hopeb.organization_profile_id                       = hop.organization_profile_id
           AND   hopeb.d_ext_attr3                                  <= TRUNC(util.online_sysdate)
           AND   NVL(hopeb.d_ext_attr4, TRUNC(util.online_sysdate)) >= TRUNC(util.online_sysdate)
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.extension_id
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                                 = rtn_ctx.attr_group_id
           AND   hopeb.organization_profile_id                       = hop.organization_profile_id
           AND   hopeb.d_ext_attr3                                  <= TRUNC(util.online_sysdate)
           AND   NVL(hopeb.d_ext_attr4, TRUNC(util.online_sysdate)) >= TRUNC(util.online_sysdate)
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.last_update_date
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                                 = rtn_ctx.attr_group_id
           AND   hopeb.organization_profile_id                       = hop.organization_profile_id
           AND   hopeb.d_ext_attr3                                  <= TRUNC(util.online_sysdate)
           AND   NVL(hopeb.d_ext_attr4, TRUNC(util.online_sysdate)) >= TRUNC(util.online_sysdate)
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.c_ext_attr2
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                     = rtn_ctx.attr_group_id
           AND   hopeb.organization_profile_id           = hop.organization_profile_id
           AND   hopeb.d_ext_attr3                       > TRUNC(util.online_sysdate)
           AND   hopeb.d_ext_attr4 IS NULL
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.d_ext_attr3
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                     = rtn_ctx.attr_group_id
           AND   hopeb.organization_profile_id           = hop.organization_profile_id
           AND   hopeb.d_ext_attr3                       > TRUNC(util.online_sysdate)
           AND   hopeb.d_ext_attr4 IS NULL
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.extension_id
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                     = rtn_ctx.attr_group_id
           AND   hopeb.organization_profile_id           = hop.organization_profile_id
           AND   hopeb.d_ext_attr3                       > TRUNC(util.online_sysdate)
           AND   hopeb.d_ext_attr4 IS NULL
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.last_update_date
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                     = rtn_ctx.attr_group_id
           AND   hopeb.organization_profile_id           = hop.organization_profile_id
           AND   hopeb.d_ext_attr3                       > TRUNC(util.online_sysdate)
           AND   hopeb.d_ext_attr4 IS NULL
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.c_ext_attr2
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   1 = 2
        )
       ,(SELECT  hopeb.d_ext_attr3
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   1 = 2
        )
       ,(SELECT  hopeb.extension_id
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   1 = 2
        )
       ,(SELECT  hopeb.c_ext_attr1
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                                 = rsrc_ctx.attr_group_id
           AND   hopeb.organization_profile_id                       = hop.organization_profile_id
           AND   hopeb.d_ext_attr1                                  <= TRUNC(util.online_sysdate)
           AND   NVL(hopeb.d_ext_attr2, TRUNC(util.online_sysdate)) >= TRUNC(util.online_sysdate)
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.d_ext_attr1
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                                 = rsrc_ctx.attr_group_id
           AND   hopeb.organization_profile_id                       = hop.organization_profile_id
           AND   hopeb.d_ext_attr1                                  <= TRUNC(util.online_sysdate)
           AND   NVL(hopeb.d_ext_attr2, TRUNC(util.online_sysdate)) >= TRUNC(util.online_sysdate)
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.extension_id
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                                 = rsrc_ctx.attr_group_id
           AND   hopeb.organization_profile_id                       = hop.organization_profile_id
           AND   hopeb.d_ext_attr1                                  <= TRUNC(util.online_sysdate)
           AND   NVL(hopeb.d_ext_attr2, TRUNC(util.online_sysdate)) >= TRUNC(util.online_sysdate)
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.last_update_date
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                                 = rsrc_ctx.attr_group_id
           AND   hopeb.organization_profile_id                       = hop.organization_profile_id
           AND   hopeb.d_ext_attr1                                  <= TRUNC(util.online_sysdate)
           AND   NVL(hopeb.d_ext_attr2, TRUNC(util.online_sysdate)) >= TRUNC(util.online_sysdate)
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.c_ext_attr1
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                     = rsrc_ctx.attr_group_id
           AND   hopeb.organization_profile_id           = hop.organization_profile_id
           AND   hopeb.d_ext_attr1                       > TRUNC(util.online_sysdate)
           AND   hopeb.d_ext_attr2 IS NULL
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.d_ext_attr1
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                     = rsrc_ctx.attr_group_id
           AND   hopeb.organization_profile_id           = hop.organization_profile_id
           AND   hopeb.d_ext_attr1                       > TRUNC(util.online_sysdate)
           AND   hopeb.d_ext_attr2 IS NULL
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.extension_id
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                     = rsrc_ctx.attr_group_id
           AND   hopeb.organization_profile_id           = hop.organization_profile_id
           AND   hopeb.d_ext_attr1                       > TRUNC(util.online_sysdate)
           AND   hopeb.d_ext_attr2 IS NULL
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.last_update_date
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                     = rsrc_ctx.attr_group_id
           AND   hopeb.organization_profile_id           = hop.organization_profile_id
           AND   hopeb.d_ext_attr1                       > TRUNC(util.online_sysdate)
           AND   hopeb.d_ext_attr2 IS NULL
           AND   ROWNUM = 1
        )
       ,(SELECT  hopeb.c_ext_attr1
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   1 = 2
        )
       ,(SELECT  hopeb.d_ext_attr1
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   1 = 2
        )
       ,(SELECT  hopeb.extension_id
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   1 = 2
        )
       ,(SELECT  COUNT(hopeb.c_ext_attr1)
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                                 = rsrc_ctx.attr_group_id
           AND   hopeb.organization_profile_id                       = hop.organization_profile_id
           AND   hopeb.d_ext_attr1                                  <= TRUNC(util.online_sysdate)
           AND   NVL(hopeb.d_ext_attr2, TRUNC(util.online_sysdate)) >= TRUNC(util.online_sysdate)
        )
       ,(SELECT  COUNT(hopeb.c_ext_attr1)
         FROM    hz_org_profiles_ext_b   hopeb
         WHERE   hopeb.attr_group_id                     = rsrc_ctx.attr_group_id
           AND   hopeb.organization_profile_id           = hop.organization_profile_id
           AND   hopeb.d_ext_attr1                       > TRUNC(util.online_sysdate)
           AND   hopeb.d_ext_attr2 IS NULL
        )
FROM    hz_cust_accounts          hca
       ,hz_parties                hp
       ,hz_organization_profiles  hop
       ,fnd_application           fa
       ,ego_fnd_dsc_flx_ctx_ext   rtn_ctx
       ,ego_fnd_dsc_flx_ctx_ext   rsrc_ctx
       ,(SELECT xxcso_util_common_pkg.get_online_sysdate online_sysdate
         FROM   DUAL
        ) util
WHERE   hp.party_id                             = hca.party_id
  AND   hop.party_id                            = hp.party_id
  AND   hop.effective_end_date IS NULL
  AND   fa.application_short_name               = 'AR'
  AND   rtn_ctx.application_id                  = fa.application_id
  AND   rtn_ctx.descriptive_flexfield_name      = 'HZ_ORG_PROFILES_GROUP'
  AND   rtn_ctx.descriptive_flex_context_code   = 'ROUTE'
  AND   rsrc_ctx.application_id                 = fa.application_id
  AND   rsrc_ctx.descriptive_flexfield_name     = 'HZ_ORG_PROFILES_GROUP'
  AND   rsrc_ctx.descriptive_flex_context_code  = 'RESOURCE'
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_RTN_RSRC_V IS '画面用：訪問・売上計画／ルートNo担当営業員一括更新画面用ビュー';

