/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_employee_v
 * Description     : �]�ƈ��r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.kitajima       �V�K�쐬
 *  2009/02/12    1.1   T.kitajima       [COS_059]�����_�R�[�h�̔��ߓ��擾���@�ύX
 *  2009/02/26    1.2   T.kitajima       �A�T�C�����g�̓K�p�����ڂ�ǉ�
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOS_EMPLOYEE_V (
    employee_number
   ,group_cd
   ,base_code
   ,area_code
   ,division_code
   ,ori_division_code
   ,effective_start_date
   ,effective_end_date
   ,announcement_start_day
   ,announcement_end_day
   ,asaiment_start_date
   ,asaiment_end_date
   ,Add_on_start_date
   ,Add_on_end_date
)
AS
SELECT    pap.employee_number,
          FIRST_VALUE(jrm.attribute2)
            OVER(PARTITION BY jrm.group_id,  jrm.resource_id  ORDER BY jrm.group_member_id DESC
              RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS  group_cd,
           bif.base_code,
           bif.xla_area_code,
           bif.xla_division_code,
           bif.xla_ori_division_code,
           pap.effective_start_date,
           pap.effective_end_date,
           NVL(bif.paa_start_date,TO_DATE('1900/01/01', 'yyyy/mm/dd')),
           NVL(bif.paa_end_date,TO_DATE('9999/12/31', 'yyyy/mm/dd')),
           bif.paa_effective_start_date,
           bif.paa_effective_end_date,
           bif.xla_start_date,
           bif.xla_end_date
      FROM per_all_people_f      pap,
           (
            SELECT paa.person_id                                              as person_id,
                   paa.ass_attribute5                                         as base_code,
                   TO_DATE(paa.ass_attribute2,'YYYY/MM/DD')                   as paa_start_date,
                   TO_DATE('9999/12/31', 'yyyy/mm/dd')                        as paa_end_date,
                   paa.effective_start_date                                   as paa_effective_start_date,
                   paa.effective_end_date                                     as paa_effective_end_date,
                   substr(xla.division_code,1,2)                              as xla_division_code,
                   substr(xla.division_code,1,3)                              as xla_area_code,
                   xla.division_code                                          as xla_ori_division_code,
                   xla.start_date_active                                      as xla_start_date,
                   xla.end_date_active                                        as xla_end_date
              FROM per_all_assignments_f paa,
                   xxcmn_locations_all   xla
             WHERE paa.location_id = xla.location_id
               AND paa.ass_attribute5 IS NOT NULL
            UNION
            SELECT paa.person_id                                              as person_id,
                   paa.ass_attribute6                                         as base_code,
                   TO_DATE('1900/01/01', 'yyyy/mm/dd')                        as paa_start_date,
                   TO_DATE(paa.ass_attribute2,'YYYY/MM/DD') - 1               as paa_end_date,
                   paa.effective_start_date                                   as ppa_effective_start_date,
                   paa.effective_end_date                                     as ppa_effective_end_date,
                   substr(xla.division_code,1,2)                              as xla_division_code,
                   substr(xla.division_code,1,3)                              as xla_area_code,
                   xla.division_code                                          as xla_ori_division_code,
                   xla.start_date_active                                      as xla_start_date,
                   xla.end_date_active                                        as xla_end_date
              FROM per_all_assignments_f paa,
                   xxcmn_locations_all   xla
             WHERE paa.location_id = xla.location_id
               AND paa.ass_attribute6 IS NOT NULL
           ) bif,
           jtf.jtf_rs_resource_extns jre,
           jtf.jtf_rs_group_members  jrm
     WHERE pap.person_id   = bif.person_id
       AND pap.person_id   = jre.source_id(+)
       AND jre.resource_id = jrm.resource_id(+)
       AND jrm.delete_flag = 'N'
       AND pap.attribute3 IN ('1','2')
;
COMMENT ON  COLUMN  xxcos_employee_v.employee_number        IS  '�]�ƈ��R�[�h';
COMMENT ON  COLUMN  xxcos_employee_v.group_cd               IS  '�O���[�v�R�[�h';
COMMENT ON  COLUMN  xxcos_employee_v.base_code              IS  '���_CD';
COMMENT ON  COLUMN  xxcos_employee_v.area_code              IS  '�n��R�[�h';
COMMENT ON  COLUMN  xxcos_employee_v.division_code          IS  '�{���R�[�h';
COMMENT ON  COLUMN  xxcos_employee_v.ori_division_code      IS  '�I���W�i���{���R�[�h';
COMMENT ON  COLUMN  xxcos_employee_v.effective_start_date   IS  '�]�ƈ��}�X�^�K�p�J�n��';
COMMENT ON  COLUMN  xxcos_employee_v.effective_end_date     IS  '�]�ƈ��}�X�^�K�p�I����';
COMMENT ON  COLUMN  xxcos_employee_v.announcement_start_day IS  '���ߓ��J�n';
COMMENT ON  COLUMN  xxcos_employee_v.announcement_end_day   IS  '���ߓ��I��';
COMMENT ON  COLUMN  xxcos_employee_v.asaiment_start_date    IS  '�A�T�C�����g�K�p�J�n��';
COMMENT ON  COLUMN  xxcos_employee_v.asaiment_end_date      IS  '�A�T�C�����g�K�p�I����';
COMMENT ON  COLUMN  xxcos_employee_v.add_on_start_date      IS  '���Ə��A�h�I���K�p�J�n��';
COMMENT ON  COLUMN  xxcos_employee_v.add_on_end_date        IS  '���Ə��A�h�I���K�p�I����';
--
COMMENT ON  TABLE   xxcos_employee_v                        IS  '�]�ƈ��r���[';
