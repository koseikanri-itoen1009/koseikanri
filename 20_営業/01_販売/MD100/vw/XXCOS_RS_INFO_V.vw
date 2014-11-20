/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_xxcos_rs_info_v
 * Description     : �c�ƈ����r���[
 * Version         : 1.2
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
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_rs_info_v
AS
--  SQL A(�V���_��񒊏o)
SELECT
  /*+
    INDEX( JRRX XXCSO_JRRE_N02 )
    INDEX( JRGM JTF_RS_GROUP_MEMBERS_N2 )
    INDEX( JRGB JTF_RS_GROUPS_B_U1 )
    INDEX( pept PER_PERSON_TYPES_PK)
    INDEX( papf PER_PEOPLE_F_PK)
    INDEX( paaf XXCSO_PAAF_N100)
  */
      jrgb.attribute1                           AS  base_code
      ,to_date(nvl(paaf.ass_attribute2, '19000101'), 'yyyymmdd')
                                                AS  effective_start_date
      ,to_date('99991231', 'yyyymmdd')          AS  effective_end_date
--      ,to_date('19000101', 'yyyymmdd')          AS  effective_start_date
--      ,nvl(to_date(paaf.ass_attribute2, 'yyyymmdd') -1
--          ,to_date('99991231', 'yyyymmdd'))     AS  effective_end_date
      ,FIRST_VALUE(jrgm.attribute2)
        OVER(PARTITION BY jrgm.group_id,  jrgm.resource_id  ORDER BY jrgm.group_member_id DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                AS  group_code
      ,FIRST_VALUE(jrgm.attribute1) 
        OVER(PARTITION BY jrgm.group_id,  jrgm.resource_id  ORDER BY jrgm.group_member_id DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                AS  group_chief_flag
      ,FIRST_VALUE(jrgm.attribute3) 
        OVER(PARTITION BY jrgm.group_id,  jrgm.resource_id  ORDER BY jrgm.group_member_id DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                AS  group_in_sequence
      ,jrrx.resource_id                         AS  resource_id
      ,papf.employee_number                     AS  employee_number
      ,papf.per_information18
  ||  ' '
  ||  papf.per_information19                    AS  employee_name,
      nvl(papf.effective_start_date, to_date('19000101', 'yyyymmdd'))
                                                AS  per_effective_start_date,
      nvl(papf.effective_end_date, to_date('99991231', 'yyyymmdd'))
                                                AS  per_effective_end_date,
      nvl(paaf.effective_start_date, to_date('19000101', 'yyyymmdd'))
                                                AS  paa_effective_start_date,
      nvl(paaf.effective_end_date, to_date('99991231', 'yyyymmdd'))
                                                AS  paa_effective_end_date
FROM
      per_all_assignments_f     paaf
      ,per_all_people_f         papf
      ,per_person_types         pept
      ,jtf_rs_resource_extns    jrrx
      ,jtf_rs_group_members     jrgm
      ,jtf_rs_groups_b          jrgb
WHERE
      jrrx.category             =   'EMPLOYEE'
AND   jrgm.resource_id          =   jrrx.resource_id
AND   jrgm.delete_flag          =   'N'
AND   jrgb.group_id             =   jrgm.group_id
AND   papf.person_id            =   jrrx.source_id
--view���ʖڎ��p��business_group_id�𒼐ڎw��  �J���t�F�[�Y�������fnd_global���擾
AND   pept.business_group_id    =   fnd_global.per_business_group_id
--AND   pept.business_group_id    =   101
AND   pept.system_person_type   =   'EMP'
AND   pept.active_flag          =   'Y'
AND   papf.person_type_id       =   pept.person_type_id
AND   paaf.person_id            =   papf.person_id
AND   paaf.ass_attribute5       =   jrgb.attribute1
--AND   paaf.ass_attribute6       =   jrgb.attribute1
UNION
--  SQL B(�����_��񒊏o)
SELECT
  /*+
    INDEX( JRRX XXCSO_JRRE_N02 )
    INDEX( JRGM JTF_RS_GROUP_MEMBERS_N2 )
    INDEX( JRGB JTF_RS_GROUPS_B_U1 )
    INDEX( pept PER_PERSON_TYPES_PK)
    INDEX( papf PER_PEOPLE_F_PK)
    INDEX( paaf XXCSO_PAAF_N101)
  */
      jrgb.attribute1                           AS  base_code
--      ,to_date(nvl(paaf.ass_attribute2, '19000101'), 'yyyymmdd')
--                                                AS  effective_start_date
--      ,to_date('99991231', 'yyyymmdd')          AS  effective_end_date
      ,to_date('19000101', 'yyyymmdd')          AS  effective_start_date
      ,nvl(to_date(paaf.ass_attribute2, 'yyyymmdd') -1
          ,to_date('99991231', 'yyyymmdd'))     AS  effective_end_date
      ,FIRST_VALUE(jrgm.attribute2)
        OVER(PARTITION BY jrgm.group_id,  jrgm.resource_id  ORDER BY jrgm.group_member_id DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                AS  group_code
      ,FIRST_VALUE(jrgm.attribute1) 
        OVER(PARTITION BY jrgm.group_id,  jrgm.resource_id  ORDER BY jrgm.group_member_id DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                AS  group_chief_flag
      ,FIRST_VALUE(jrgm.attribute3) 
        OVER(PARTITION BY jrgm.group_id,  jrgm.resource_id  ORDER BY jrgm.group_member_id DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                AS  group_in_sequence
      ,jrrx.resource_id                         AS  resource_id
      ,papf.employee_number                     AS  employee_number
      ,papf.per_information18
  ||  ' '
  ||  papf.per_information19                    AS  employee_name,
      nvl(papf.effective_start_date, to_date('19000101', 'yyyymmdd'))
                                                AS  per_effective_start_date,
      nvl(papf.effective_end_date, to_date('99991231', 'yyyymmdd'))
                                                AS  per_effective_end_date,
      nvl(paaf.effective_start_date, to_date('19000101', 'yyyymmdd'))
                                                AS  paa_effective_start_date,
      nvl(paaf.effective_end_date, to_date('99991231', 'yyyymmdd'))
                                                AS  paa_effective_end_date
FROM
      per_all_assignments_f     paaf
      ,per_all_people_f         papf
      ,per_person_types         pept
      ,jtf_rs_resource_extns    jrrx
      ,jtf_rs_group_members     jrgm
      ,jtf_rs_groups_b          jrgb
WHERE
      jrrx.category             =   'EMPLOYEE'
AND   jrgm.resource_id          =   jrrx.resource_id
--AND   jrgm.delete_flag          =   'N'
AND   jrgb.group_id             =   jrgm.group_id
AND   papf.person_id            =   jrrx.source_id
--view���ʖڎ��p��business_group_id�𒼐ڎw��  �J���t�F�[�Y�������fnd_global���擾
AND   pept.business_group_id    =   fnd_global.per_business_group_id
--AND   pept.business_group_id    =   101
AND   pept.system_person_type   =   'EMP'
AND   pept.active_flag          =   'Y'
AND   papf.person_type_id       =   pept.person_type_id
AND   paaf.person_id            =   papf.person_id
--AND   paaf.ass_attribute5       =   jrgb.attribute1
AND   paaf.ass_attribute6       =   jrgb.attribute1
--  SQL B�ŗL����
AND   paaf.ass_attribute2       IS  NOT NULL
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
