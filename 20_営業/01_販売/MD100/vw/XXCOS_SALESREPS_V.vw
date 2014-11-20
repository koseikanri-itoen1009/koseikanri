/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_salesreps_v
 * Description     : 担当営業員ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   K.Kakishita      新規作成
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_salesreps_v (
  cust_account_id,                      --顧客ID
  account_number,                       --顧客番号
  party_name,                           --顧客名称
  account_name,                         --顧客略称
  party_id,                             --パーティID
  party_number,                         --パーティ番号
  effective_start_date,                 --適用開始日
  effective_end_date,                   --適用終了日
  employee_number,                      --従業員番号
  resource_id,                          --リソースID
  person_id,                            --従業員ID
  kanji_last,                           --漢字氏名（姓）
  kanji_first                           --漢字氏名（名）
)
AS
  SELECT
    hca.cust_account_id                     cust_account_id,                    --顧客ID
    hca.account_number                      account_number,                     --顧客番号
    hp.party_name                           party_name,                         --顧客名称
    hca.account_name                        account_name,                       --顧客略称
    hop.party_id                            party_id,                           --パーティID
    hp.party_number                         party_number,                       --パーティ番号
    hopeb.d_ext_attr1                       effective_start_date,               --適用開始日
    hopeb.d_ext_attr2                       effective_end_date,                 --適用終了日
    jrre.source_number                      employee_number,                    --従業員番号
    jrre.resource_id                        resource_id,                        --リソースＩＤ
    jrre.source_id                          person_id,                          --従業員ＩＤ
    papf.per_information18                  kanji_last,                         --漢字氏名（姓）
    papf.per_information19                  kanji_first                         --漢字氏名（名）
  FROM
    hz_organization_profiles                hop,                                --組織プロファイルマスタ
    hz_org_profiles_ext_b                   hopeb,                              --組織プロファイル拡張マスタ
--  hz_org_profiles_ext_tl                  hopet,                              --組織プロファイル拡張マスタ（翻訳）
    ego_fnd_dsc_flx_ctx_ext                 efdfce,                             --摘要フレックスコンテキスト拡張マスタ
    fnd_application                         fa,                                 --アプリケーションマスタ
    jtf_rs_resource_extns                   jrre,                               --リソースマスタ
    hz_parties                              hp,                                 --パーティマスタ
    hz_cust_accounts                        hca,                                --顧客マスタ
    per_all_people_f                        papf                                --従業員マスタ
  WHERE
   hop.organization_profile_id              = hopeb.organization_profile_id
  AND hop.effective_end_date                IS NULL
--AND hopeb.organization_profile_id         = hopet.organization_profile_id
--AND hopet.language                        = USERENV( 'LANG' )
  AND hopeb.attr_group_id                   = efdfce.attr_group_id
--AND efdfce.descriptive_flexfield_name     = 'HZ_ORG_PROFILES_GROUP'
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
COMMENT ON  COLUMN  xxcos_salesreps_v.cust_account_id             IS  '顧客ID';
COMMENT ON  COLUMN  xxcos_salesreps_v.account_number              IS  '顧客番号';
COMMENT ON  COLUMN  xxcos_salesreps_v.party_name                  IS  '顧客名称';
COMMENT ON  COLUMN  xxcos_salesreps_v.account_name                IS  '顧客略称';
COMMENT ON  COLUMN  xxcos_salesreps_v.party_id                    IS  'パーティID';
COMMENT ON  COLUMN  xxcos_salesreps_v.party_number                IS  'パーティ番号';
COMMENT ON  COLUMN  xxcos_salesreps_v.effective_start_date        IS  '適用開始日';
COMMENT ON  COLUMN  xxcos_salesreps_v.effective_end_date          IS  '適用終了日';
COMMENT ON  COLUMN  xxcos_salesreps_v.employee_number             IS  '従業員番号';
COMMENT ON  COLUMN  xxcos_salesreps_v.resource_id                 IS  'リソースID';
COMMENT ON  COLUMN  xxcos_salesreps_v.person_id                   IS  '従業員ID';
COMMENT ON  COLUMN  xxcos_salesreps_v.kanji_last                  IS  '漢字氏名(姓)';
COMMENT ON  COLUMN  xxcos_salesreps_v.kanji_first                 IS  '漢字氏名(名)';
--
COMMENT ON  TABLE   xxcos_salesreps_v                             IS  '担当営業員ビュー';
