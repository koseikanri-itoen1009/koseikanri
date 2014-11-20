/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_xxcos_rs_info_v
 * Description     : 営業員情報ビュー
 * Version         : 1.4
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/28    1.0   T.Nakabayashi   新規作成
 *  2008/12/11    1.0   T.Nakabayashi   リソースグループマスタとアサイメントを紐付け
 *  2008/12/12    1.0   T.Nakabayashi   グループコードとグループ長フラグが入れ替わっていた不具合を修正
 *                                      最大のgroup_member_id検索時全データを対象にしてしまっていた不具合を修正
 *                                      旧拠点情報の場合、リソースグループメンバの削除フラグは不問とする
 *  2008/12/30    1.0   T.Nakabayashi   発令日に値がない場合、旧拠点情報は無条件に対象外とする
 *  2009/02/26    1.1   T.Nakabayashi   従業員マスタ、従業員アサインメントの適用日をview項目に追加
 *                                      business_group_idの抽出条件を、固定値からfnd_global参照へ変更
 *  2009/07/09    1.2   K.Kakishita     [T3_0000208]パフォーマンス障害  ヒント句追加
 *  2009/07/30    1.3   K.Kakishita     [T3_0000900]パフォーマンス障害  ヒント句削除
 *                                                  『UNION』を『UNION ALL』に変更
 *  2009/08/28    1.4   T.Miyata        [T3_0001206]①『UNION ALL』を『UNION』に変更
 *                                                  ②SQL A(新拠点情報抽出)に別名付与
 *                                                  ③SQL B(旧拠点情報抽出)に別名付与
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_rs_info_v
AS
--  SQL A(新拠点情報抽出)
SELECT
      jrgb_n.attribute1                         AS  base_code
      ,to_date(nvl(paaf_n.ass_attribute2, '19000101'), 'yyyymmdd')
                                                AS  effective_start_date
      ,to_date('99991231', 'yyyymmdd')          AS  effective_end_date
--      ,to_date('19000101', 'yyyymmdd')          AS  effective_start_date
--      ,nvl(to_date(paaf.ass_attribute2, 'yyyymmdd') -1
--          ,to_date('99991231', 'yyyymmdd'))     AS  effective_end_date
      ,FIRST_VALUE(jrgm_n.attribute2)
        OVER(PARTITION BY jrgm_n.group_id,  jrgm_n.resource_id  ORDER BY jrgm_n.group_member_id DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                AS  group_code
      ,FIRST_VALUE(jrgm_n.attribute1) 
        OVER(PARTITION BY jrgm_n.group_id,  jrgm_n.resource_id  ORDER BY jrgm_n.group_member_id DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                AS  group_chief_flag
      ,FIRST_VALUE(jrgm_n.attribute3) 
        OVER(PARTITION BY jrgm_n.group_id,  jrgm_n.resource_id  ORDER BY jrgm_n.group_member_id DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                AS  group_in_sequence
      ,jrrx_n.resource_id                       AS  resource_id
      ,papf_n.employee_number                   AS  employee_number
      ,papf_n.per_information18
  ||  ' '
  ||  papf_n.per_information19                  AS  employee_name,
      nvl(papf_n.effective_start_date, to_date('19000101', 'yyyymmdd'))
                                                AS  per_effective_start_date,
      nvl(papf_n.effective_end_date, to_date('99991231', 'yyyymmdd'))
                                                AS  per_effective_end_date,
      nvl(paaf_n.effective_start_date, to_date('19000101', 'yyyymmdd'))
                                                AS  paa_effective_start_date,
      nvl(paaf_n.effective_end_date, to_date('99991231', 'yyyymmdd'))
                                                AS  paa_effective_end_date
FROM
      per_all_assignments_f     paaf_n
      ,per_all_people_f         papf_n
      ,per_person_types         pept_n
      ,jtf_rs_resource_extns    jrrx_n
      ,jtf_rs_group_members     jrgm_n
      ,jtf_rs_groups_b          jrgb_n
WHERE
      jrrx_n.category           =   'EMPLOYEE'
AND   jrgm_n.resource_id        =   jrrx_n.resource_id
AND   jrgm_n.delete_flag        =   'N'
AND   jrgb_n.group_id           =   jrgm_n.group_id
AND   papf_n.person_id          =   jrrx_n.source_id
--view結果目視用にbusiness_group_idを直接指定  開発フェーズ完了後はfnd_globalより取得
AND   pept_n.business_group_id    =   fnd_global.per_business_group_id
--AND   pept.business_group_id    =   101
AND   pept_n.system_person_type   =   'EMP'
AND   pept_n.active_flag          =   'Y'
AND   papf_n.person_type_id       =   pept_n.person_type_id
AND   paaf_n.person_id            =   papf_n.person_id
AND   paaf_n.ass_attribute5       =   jrgb_n.attribute1
--AND   paaf.ass_attribute6       =   jrgb.attribute1
UNION
--  SQL B(旧拠点情報抽出)
SELECT
      jrgb_o.attribute1                         AS  base_code
--      ,to_date(nvl(paaf.ass_attribute2, '19000101'), 'yyyymmdd')
--                                                AS  effective_start_date
--      ,to_date('99991231', 'yyyymmdd')          AS  effective_end_date
      ,to_date('19000101', 'yyyymmdd')          AS  effective_start_date
      ,nvl(to_date(paaf_o.ass_attribute2, 'yyyymmdd') -1
          ,to_date('99991231', 'yyyymmdd'))     AS  effective_end_date
      ,FIRST_VALUE(jrgm_o.attribute2)
        OVER(PARTITION BY jrgm_o.group_id,  jrgm_o.resource_id  ORDER BY jrgm_o.group_member_id DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                AS  group_code
      ,FIRST_VALUE(jrgm_o.attribute1) 
        OVER(PARTITION BY jrgm_o.group_id,  jrgm_o.resource_id  ORDER BY jrgm_o.group_member_id DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                AS  group_chief_flag
      ,FIRST_VALUE(jrgm_o.attribute3) 
        OVER(PARTITION BY jrgm_o.group_id,  jrgm_o.resource_id  ORDER BY jrgm_o.group_member_id DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                AS  group_in_sequence
      ,jrrx_o.resource_id                       AS  resource_id
      ,papf_o.employee_number                   AS  employee_number
      ,papf_o.per_information18
  ||  ' '
  ||  papf_o.per_information19                  AS  employee_name,
      nvl(papf_o.effective_start_date, to_date('19000101', 'yyyymmdd'))
                                                AS  per_effective_start_date,
      nvl(papf_o.effective_end_date, to_date('99991231', 'yyyymmdd'))
                                                AS  per_effective_end_date,
      nvl(paaf_o.effective_start_date, to_date('19000101', 'yyyymmdd'))
                                                AS  paa_effective_start_date,
      nvl(paaf_o.effective_end_date, to_date('99991231', 'yyyymmdd'))
                                                AS  paa_effective_end_date
FROM
      per_all_assignments_f     paaf_o
      ,per_all_people_f         papf_o
      ,per_person_types         pept_o
      ,jtf_rs_resource_extns    jrrx_o
      ,jtf_rs_group_members     jrgm_o
      ,jtf_rs_groups_b          jrgb_o
WHERE
      jrrx_o.category           =   'EMPLOYEE'
AND   jrgm_o.resource_id        =   jrrx_o.resource_id
--AND   jrgm.delete_flag          =   'N'
AND   jrgb_o.group_id           =   jrgm_o.group_id
AND   papf_o.person_id          =   jrrx_o.source_id
--view結果目視用にbusiness_group_idを直接指定  開発フェーズ完了後はfnd_globalより取得
AND   pept_o.business_group_id  =   fnd_global.per_business_group_id
--AND   pept.business_group_id  =   101
AND   pept_o.system_person_type =   'EMP'
AND   pept_o.active_flag        =   'Y'
AND   papf_o.person_type_id     =   pept_o.person_type_id
AND   paaf_o.person_id          =   papf_o.person_id
--AND   paaf.ass_attribute5       =   jrgb.attribute1
AND   paaf_o.ass_attribute6     =   jrgb_o.attribute1
--  SQL B固有条件
AND   paaf_o.ass_attribute2     IS  NOT NULL
/
COMMENT ON  COLUMN  xxcos_rs_info_v.base_code                 IS  '拠点CD';
COMMENT ON  COLUMN  xxcos_rs_info_v.effective_start_date      IS  '拠点適用開始日';
COMMENT ON  COLUMN  xxcos_rs_info_v.effective_end_date        IS  '拠点適用終了日';
COMMENT ON  COLUMN  xxcos_rs_info_v.group_code                IS  'グループ番号';
COMMENT ON  COLUMN  xxcos_rs_info_v.group_chief_flag          IS  'グループ長区分';
COMMENT ON  COLUMN  xxcos_rs_info_v.group_in_sequence         IS  'グループ内番号';
COMMENT ON  COLUMN  xxcos_rs_info_v.resource_id               IS  'リソースID';
COMMENT ON  COLUMN  xxcos_rs_info_v.employee_number           IS  '営業員コード';
COMMENT ON  COLUMN  xxcos_rs_info_v.employee_name             IS  '営業員名称';
COMMENT ON  COLUMN  xxcos_rs_info_v.per_effective_start_date  IS  '従業員適用開始日';
COMMENT ON  COLUMN  xxcos_rs_info_v.per_effective_end_date    IS  '従業員適用終了日';
COMMENT ON  COLUMN  xxcos_rs_info_v.paa_effective_start_date  IS  'アサインメント適用開始日';
COMMENT ON  COLUMN  xxcos_rs_info_v.paa_effective_end_date    IS  'アサインメント適用終了日';
--
COMMENT ON  TABLE   xxcos_rs_info_v                           IS  '営業員情報ビュー';
