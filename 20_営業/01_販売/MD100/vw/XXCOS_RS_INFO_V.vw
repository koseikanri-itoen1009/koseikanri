/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_xxcos_rs_info_v
 * Description     : �c�ƈ����r���[
 * Version         : 1.4
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/28    1.0   T.Nakabayashi   �V�K�쐬
 *  2008/12/11    1.0   T.Nakabayashi   ���\�[�X�O���[�v�}�X�^�ƃA�T�C�����g��R�t��
 *  2008/12/12    1.0   T.Nakabayashi   �O���[�v�R�[�h�ƃO���[�v���t���O������ւ���Ă����s����C��
 *                                      �ő��group_member_id�������S�f�[�^��Ώۂɂ��Ă��܂��Ă����s����C��
 *                                      �����_���̏ꍇ�A���\�[�X�O���[�v�����o�̍폜�t���O�͕s��Ƃ���
 *  2008/12/30    1.0   T.Nakabayashi   ���ߓ��ɒl���Ȃ��ꍇ�A�����_���͖������ɑΏۊO�Ƃ���
 *  2009/02/26    1.1   T.Nakabayashi   �]�ƈ��}�X�^�A�]�ƈ��A�T�C�������g�̓K�p����view���ڂɒǉ�
 *                                      business_group_id�̒��o�������A�Œ�l����fnd_global�Q�Ƃ֕ύX
 *  2009/07/09    1.2   K.Kakishita     [T3_0000208]�p�t�H�[�}���X��Q  �q���g��ǉ�
 *  2009/07/30    1.3   K.Kakishita     [T3_0000900]�p�t�H�[�}���X��Q  �q���g��폜
 *                                                  �wUNION�x���wUNION ALL�x�ɕύX
 *  2009/08/28    1.4   T.Miyata        [T3_0001206]�@�wUNION ALL�x���wUNION�x�ɕύX
 *                                                  �ASQL A(�V���_��񒊏o)�ɕʖ��t�^
 *                                                  �BSQL B(�����_��񒊏o)�ɕʖ��t�^
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_rs_info_v
AS
--  SQL A(�V���_��񒊏o)
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
--view���ʖڎ��p��business_group_id�𒼐ڎw��  �J���t�F�[�Y�������fnd_global���擾
AND   pept_n.business_group_id    =   fnd_global.per_business_group_id
--AND   pept.business_group_id    =   101
AND   pept_n.system_person_type   =   'EMP'
AND   pept_n.active_flag          =   'Y'
AND   papf_n.person_type_id       =   pept_n.person_type_id
AND   paaf_n.person_id            =   papf_n.person_id
AND   paaf_n.ass_attribute5       =   jrgb_n.attribute1
--AND   paaf.ass_attribute6       =   jrgb.attribute1
UNION
--  SQL B(�����_��񒊏o)
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
--view���ʖڎ��p��business_group_id�𒼐ڎw��  �J���t�F�[�Y�������fnd_global���擾
AND   pept_o.business_group_id  =   fnd_global.per_business_group_id
--AND   pept.business_group_id  =   101
AND   pept_o.system_person_type =   'EMP'
AND   pept_o.active_flag        =   'Y'
AND   papf_o.person_type_id     =   pept_o.person_type_id
AND   paaf_o.person_id          =   papf_o.person_id
--AND   paaf.ass_attribute5       =   jrgb.attribute1
AND   paaf_o.ass_attribute6     =   jrgb_o.attribute1
--  SQL B�ŗL����
AND   paaf_o.ass_attribute2     IS  NOT NULL
/
COMMENT ON  COLUMN  xxcos_rs_info_v.base_code                 IS  '���_CD';
COMMENT ON  COLUMN  xxcos_rs_info_v.effective_start_date      IS  '���_�K�p�J�n��';
COMMENT ON  COLUMN  xxcos_rs_info_v.effective_end_date        IS  '���_�K�p�I����';
COMMENT ON  COLUMN  xxcos_rs_info_v.group_code                IS  '�O���[�v�ԍ�';
COMMENT ON  COLUMN  xxcos_rs_info_v.group_chief_flag          IS  '�O���[�v���敪';
COMMENT ON  COLUMN  xxcos_rs_info_v.group_in_sequence         IS  '�O���[�v���ԍ�';
COMMENT ON  COLUMN  xxcos_rs_info_v.resource_id               IS  '���\�[�XID';
COMMENT ON  COLUMN  xxcos_rs_info_v.employee_number           IS  '�c�ƈ��R�[�h';
COMMENT ON  COLUMN  xxcos_rs_info_v.employee_name             IS  '�c�ƈ�����';
COMMENT ON  COLUMN  xxcos_rs_info_v.per_effective_start_date  IS  '�]�ƈ��K�p�J�n��';
COMMENT ON  COLUMN  xxcos_rs_info_v.per_effective_end_date    IS  '�]�ƈ��K�p�I����';
COMMENT ON  COLUMN  xxcos_rs_info_v.paa_effective_start_date  IS  '�A�T�C�������g�K�p�J�n��';
COMMENT ON  COLUMN  xxcos_rs_info_v.paa_effective_end_date    IS  '�A�T�C�������g�K�p�I����';
--
COMMENT ON  TABLE   xxcos_rs_info_v                           IS  '�c�ƈ����r���[';
