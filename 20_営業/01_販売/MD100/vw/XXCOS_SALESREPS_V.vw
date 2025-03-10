/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_salesreps_v
 * Description     : ScÆõr[
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   K.Kakishita      VKì¬
 *  2009/07/22    1.1   K.Kakishita      [0000741]ptH[}XÎ
 *                                       EqgåÇÁ
 *                                       E'HZ_ORG_PROFILES_GROUP'ÌðÇÁ
 *  2009/08/03    1.2   K.Kakishita      [0000741]ptH[}XÎ
 *                                       Eqgåí
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_salesreps_v (
  cust_account_id,                      --ÚqID
  account_number,                       --ÚqÔ
  party_name,                           --Úq¼Ì
  account_name,                         --ÚqªÌ
  party_id,                             --p[eBID
  party_number,                         --p[eBÔ
  effective_start_date,                 --KpJnú
  effective_end_date,                   --KpI¹ú
  employee_number,                      --]ÆõÔ
  resource_id,                          --\[XID
  person_id,                            --]ÆõID
  kanji_last,                           --¿¼i©j
  kanji_first                           --¿¼i¼j
)
AS
  SELECT
    hca.cust_account_id                     cust_account_id,                    --ÚqID
    hca.account_number                      account_number,                     --ÚqÔ
    hp.party_name                           party_name,                         --Úq¼Ì
    hca.account_name                        account_name,                       --ÚqªÌ
    hop.party_id                            party_id,                           --p[eBID
    hp.party_number                         party_number,                       --p[eBÔ
    hopeb.d_ext_attr1                       effective_start_date,               --KpJnú
    hopeb.d_ext_attr2                       effective_end_date,                 --KpI¹ú
    jrre.source_number                      employee_number,                    --]ÆõÔ
    jrre.resource_id                        resource_id,                        --\[Xhc
    jrre.source_id                          person_id,                          --]Æõhc
    papf.per_information18                  kanji_last,                         --¿¼i©j
    papf.per_information19                  kanji_first                         --¿¼i¼j
  FROM
    hz_organization_profiles                hop,                                --gDvt@C}X^
    hz_org_profiles_ext_b                   hopeb,                              --gDvt@Cg£}X^
--  hz_org_profiles_ext_tl                  hopet,                              --gDvt@Cg£}X^i|ój
    ego_fnd_dsc_flx_ctx_ext                 efdfce,                             --EvtbNXReLXgg£}X^
    fnd_application                         fa,                                 --AvP[V}X^
    jtf_rs_resource_extns                   jrre,                               --\[X}X^
    hz_parties                              hp,                                 --p[eB}X^
    hz_cust_accounts                        hca,                                --Úq}X^
    per_all_people_f                        papf                                --]Æõ}X^
  WHERE
   hop.organization_profile_id              = hopeb.organization_profile_id
  AND hop.effective_end_date                IS NULL
--AND hopeb.organization_profile_id         = hopet.organization_profile_id
--AND hopet.language                        = USERENV( 'LANG' )
  AND hopeb.attr_group_id                   = efdfce.attr_group_id
  AND efdfce.descriptive_flexfield_name     = 'HZ_ORG_PROFILES_GROUP'
  AND efdfce.descriptive_flex_context_code  = 'RESOURCE'
  AND efdfce.application_id                 = fa.application_id
  AND fa.application_short_name             = 'AR'
  AND jrre.source_number                    = hopeb.c_ext_attr1
  AND jrre.category                         = 'EMPLOYEE'
  AND hop.party_id                          = hp.party_id
  AND hp.party_id                           = hca.party_id
  AND jrre.source_id                        = papf.person_id
  AND NVL( hopeb.d_ext_attr1, papf.effective_start_date )
                                            >= papf.effective_start_date
  AND NVL( hopeb.d_ext_attr1, papf.effective_end_date )
                                            <= papf.effective_end_date
 ;
COMMENT ON  COLUMN  xxcos_salesreps_v.cust_account_id             IS  'ÚqID';
COMMENT ON  COLUMN  xxcos_salesreps_v.account_number              IS  'ÚqÔ';
COMMENT ON  COLUMN  xxcos_salesreps_v.party_name                  IS  'Úq¼Ì';
COMMENT ON  COLUMN  xxcos_salesreps_v.account_name                IS  'ÚqªÌ';
COMMENT ON  COLUMN  xxcos_salesreps_v.party_id                    IS  'p[eBID';
COMMENT ON  COLUMN  xxcos_salesreps_v.party_number                IS  'p[eBÔ';
COMMENT ON  COLUMN  xxcos_salesreps_v.effective_start_date        IS  'KpJnú';
COMMENT ON  COLUMN  xxcos_salesreps_v.effective_end_date          IS  'KpI¹ú';
COMMENT ON  COLUMN  xxcos_salesreps_v.employee_number             IS  ']ÆõÔ';
COMMENT ON  COLUMN  xxcos_salesreps_v.resource_id                 IS  '\[XID';
COMMENT ON  COLUMN  xxcos_salesreps_v.person_id                   IS  ']ÆõID';
COMMENT ON  COLUMN  xxcos_salesreps_v.kanji_last                  IS  '¿¼(©)';
COMMENT ON  COLUMN  xxcos_salesreps_v.kanji_first                 IS  '¿¼(¼)';
--
COMMENT ON  TABLE   xxcos_salesreps_v                             IS  'ScÆõr[';
