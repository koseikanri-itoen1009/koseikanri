/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_employee_v
 * Description     : 従業員ビュー
 * Version         : 1.4
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.kitajima       新規作成
 *  2009/02/12    1.1   T.kitajima       [COS_059]旧拠点コードの発令日取得方法変更
 *  2009/02/26    1.2   T.kitajima       アサイメントの適用日項目を追加
 *  2009/10/16    1.3   S.Miyakoshi      [0001397]グループの所属条件を追加
 *  2010/04/20    1.4   K.Atsushiba      [E_本稼動_02151]本部コード対応
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOS_EMPLOYEE_V (
    employee_number
   ,group_cd
   ,base_code
-- == 2010/04/20 1.4 Mod Start ===============================================================
--   ,area_code
--   ,division_code
--   ,ori_division_code
   ,old_area_code
   ,new_area_code
   ,old_division_code
   ,new_division_code
   ,old_ori_division_code
   ,new_ori_division_code
-- == 2010/04/20 1.4 Mod End ===============================================================
   ,effective_start_date
   ,effective_end_date
   ,announcement_start_day
   ,announcement_end_day
   ,asaiment_start_date
   ,asaiment_end_date
-- == 2010/04/20 1.4 Mod Start ===============================================================
--   ,Add_on_start_date
--   ,Add_on_end_date
   ,aff_effective_date
-- == 2010/04/20 1.4 Mod End ===============================================================
)
AS
SELECT    pap.employee_number,
          FIRST_VALUE(jrm.attribute2)
            OVER(PARTITION BY jrm.group_id,  jrm.resource_id  ORDER BY jrm.group_member_id DESC
              RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS  group_cd,
           bif.base_code,
-- == 2010/04/20 1.4 Mod Start ===============================================================
--           bif.xla_area_code,
--           bif.xla_division_code,
--           bif.xla_ori_division_code,
           bif.old_area_code,
           bif.new_area_code,
           bif.old_division_code,
           bif.new_division_code,
           bif.old_ori_division_code,
           bif.new_ori_division_code,
-- == 2010/04/20 1.4 Mod End ===============================================================
           pap.effective_start_date,
           pap.effective_end_date,
           NVL(bif.paa_start_date,TO_DATE('1900/01/01', 'yyyy/mm/dd')),
           NVL(bif.paa_end_date,TO_DATE('9999/12/31', 'yyyy/mm/dd')),
           bif.paa_effective_start_date,
           bif.paa_effective_end_date,
-- == 2010/04/20 1.4 Mod Start ===============================================================
--           bif.xla_start_date,
--           bif.xla_end_date
           bif.aff_effective_date
-- == 2010/04/20 1.4 Mod End ===============================================================
      FROM per_all_people_f      pap,
           (
            SELECT paa.person_id                                              AS person_id,
                   paa.ass_attribute5                                         AS base_code,
                   TO_DATE(paa.ass_attribute2,'YYYY/MM/DD')                   AS paa_start_date,
                   TO_DATE('9999/12/31', 'yyyy/mm/dd')                        AS paa_end_date,
                   paa.effective_start_date                                   AS paa_effective_start_date,
                   paa.effective_end_date                                     AS paa_effective_end_date,
-- == 2010/04/20 1.4 Mod Start ===============================================================
--                   SUBSTR(xla.division_code,1,2)                              AS xla_division_code,
--                   SUBSTR(xla.division_code,1,3)                              AS xla_area_code,
--                   xla.division_code                                          AS xla_ori_division_code,
--                   xla.start_date_active                                      AS xla_start_date,
--                   xla.end_date_active                                        AS xla_end_date
                   SUBSTR(ffv.attribute7,1,2)                                 AS old_division_code,
                   SUBSTR(ffv.attribute9,1,2)                                 AS new_division_code,
                   SUBSTR(ffv.attribute7,1,3)                                 AS old_area_code,
                   SUBSTR(ffv.attribute9,1,3)                                 AS new_area_code,
                   TO_DATE(ffv.attribute6,'YYYYMMDD')                         AS aff_effective_date,
                   ffv.attribute7                                             AS old_ori_division_code,
                   ffv.attribute9                                             AS new_ori_division_code
-- == 2010/04/20 1.4 Mod End ===============================================================
              FROM per_all_assignments_f paa,
-- == 2010/04/20 1.4 Mod Start ===============================================================
--                   xxcmn_locations_all   xla
--             WHERE paa.location_id = xla.location_id
                   fnd_flex_value_sets   ffvs,
                   fnd_flex_values       ffv
               WHERE ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
               AND   ffv.flex_value           = paa.ass_attribute5
               AND   ffvs.flex_value_set_id   = ffv.flex_value_set_id
-- == 2010/04/20 1.4 Mod End ===============================================================
               AND   paa.ass_attribute5       IS NOT NULL
            UNION
            SELECT paa.person_id                                              AS person_id,
                   paa.ass_attribute6                                         AS base_code,
                   TO_DATE('1900/01/01', 'yyyy/mm/dd')                        AS paa_start_date,
                   TO_DATE(paa.ass_attribute2,'YYYY/MM/DD') - 1               AS paa_end_date,
                   paa.effective_start_date                                   AS ppa_effective_start_date,
                   paa.effective_end_date                                     AS ppa_effective_end_date,
-- == 2010/04/20 1.4 Mod Start ===============================================================
--                   SUBSTR(xla.division_code,1,2)                              AS xla_division_code,
--                   SUBSTR(xla.division_code,1,3)                              AS xla_area_code,
--                   xla.division_code                                          AS xla_ori_division_code,
--                   xla.start_date_active                                      AS xla_start_date,
--                   xla.end_date_active                                        AS xla_end_date
                   SUBSTR(ffv.attribute7,1,2)                                 AS old_division_code,
                   SUBSTR(ffv.attribute9,1,2)                                 AS new_division_code,
                   SUBSTR(ffv.attribute7,1,3)                                 AS old_area_code,
                   SUBSTR(ffv.attribute9,1,3)                                 AS new_area_code,
                   TO_DATE(ffv.attribute6,'YYYYMMDD')                         AS aff_effective_date,
                   ffv.attribute7                                             AS old_ori_division_code,
                   ffv.attribute9                                             AS new_ori_division_code
-- == 2010/04/20 1.4 Mod End ===============================================================
              FROM per_all_assignments_f paa,
-- == 2010/04/20 1.4 Mod Start ===============================================================
--                   xxcmn_locations_all   xla
--             WHERE paa.location_id = xla.location_id
                   fnd_flex_value_sets   ffvs,
                   fnd_flex_values       ffv
               WHERE ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
               AND   ffvs.flex_value_set_id   = ffv.flex_value_set_id
               AND   ffv.flex_value           = paa.ass_attribute6
-- == 2010/04/20 1.4 Mod End ===============================================================
               AND   paa.ass_attribute6       IS NOT NULL
           ) bif,
           jtf.jtf_rs_resource_extns jre,
           jtf.jtf_rs_group_members  jrm,
           jtf.jtf_rs_groups_b       jrb
     WHERE pap.person_id   = bif.person_id
       AND pap.person_id   = jre.source_id(+)
       AND jre.resource_id = jrm.resource_id(+)
       AND jrm.delete_flag = 'N'
       AND pap.attribute3 IN ('1','2')
       AND jrm.group_id    = jrb.group_id
       AND jrb.attribute1  = bif.base_code
;
COMMENT ON  COLUMN  xxcos_employee_v.employee_number        IS  '従業員コード';
COMMENT ON  COLUMN  xxcos_employee_v.group_cd               IS  'グループコード';
COMMENT ON  COLUMN  xxcos_employee_v.base_code              IS  '拠点CD';
-- == 2010/04/20 1.4 Mod Start ===============================================================
--COMMENT ON  COLUMN  xxcos_employee_v.area_code              IS  '地区コード';
--COMMENT ON  COLUMN  xxcos_employee_v.division_code          IS  '本部コード';
--COMMENT ON  COLUMN  xxcos_employee_v.ori_division_code      IS  'オリジナル本部コード';
COMMENT ON  COLUMN  xxcos_employee_v.old_area_code          IS  '地区コード(旧)';
COMMENT ON  COLUMN  xxcos_employee_v.new_area_code          IS  '地区コード(新)';
COMMENT ON  COLUMN  xxcos_employee_v.old_division_code      IS  '本部コード(旧)';
COMMENT ON  COLUMN  xxcos_employee_v.new_division_code      IS  '本部コード(新)';
COMMENT ON  COLUMN  xxcos_employee_v.old_ori_division_code  IS  'オリジナル本部コード(旧)';
COMMENT ON  COLUMN  xxcos_employee_v.new_ori_division_code  IS  'オリジナル本部コード(新)';
-- == 2010/04/20 1.4 Mod End ===============================================================
COMMENT ON  COLUMN  xxcos_employee_v.effective_start_date   IS  '従業員マスタ適用開始日';
COMMENT ON  COLUMN  xxcos_employee_v.effective_end_date     IS  '従業員マスタ適用終了日';
COMMENT ON  COLUMN  xxcos_employee_v.announcement_start_day IS  '発令日開始';
COMMENT ON  COLUMN  xxcos_employee_v.announcement_end_day   IS  '発令日終了';
COMMENT ON  COLUMN  xxcos_employee_v.asaiment_start_date    IS  'アサイメント適用開始日';
COMMENT ON  COLUMN  xxcos_employee_v.asaiment_end_date      IS  'アサイメント適用終了日';
-- == 2010/04/20 1.4 Mod Start ===============================================================
--COMMENT ON  COLUMN  xxcos_employee_v.add_on_start_date      IS  '事業所アドオン適用開始日';
--COMMENT ON  COLUMN  xxcos_employee_v.add_on_end_date        IS  '事業所アドオン適用終了日';
COMMENT ON  COLUMN  xxcos_employee_v.aff_effective_date     IS  'AFF部門適用開始日';
-- == 2010/04/20 1.4 Mod End ===============================================================
--
COMMENT ON  TABLE   xxcos_employee_v                        IS  '従業員ビュー';
