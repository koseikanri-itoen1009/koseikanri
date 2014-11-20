/*************************************************************************
 * 
 * VIEW Name       : XXCSO_RESOURCE_RELATIONS_V2
 * Description     : ���ʗp�F���\�[�X�֘A�}�X�^�i�ŐV�j�r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_RESOURCE_RELATIONS_V2
(
 user_id
,user_name
,person_id
,employee_number
,last_name
,first_name
,full_name
,qualify_code_new
,qualify_code_old
,qualify_name_new
,qualify_name_old
,position_code_new
,position_code_old
,position_name_new
,position_name_old
,duty_code_new
,duty_code_old
,duty_name_new
,duty_name_old
,job_type_code_new
,job_type_code_old
,job_type_name_new
,job_type_name_old
,assignment_id
,issue_date
,work_base_code_new
,work_base_code_old
,work_base_name_new
,work_base_name_old
,position_sort_code_new
,position_sort_code_old
,approval_type_code_new
,approval_type_code_old
,resource_id
,sales_style
,group_id_new
,group_id_old
,group_member_id_new
,group_member_id_old
,group_leader_flag_new
,group_leader_flag_old
,group_number_new
,group_number_old
,group_grade_new
,group_grade_old
)
AS
SELECT
 rs.user_id
,rs.user_name
,rs.person_id
,rs.employee_number
,rs.per_information18
,rs.per_information19
,rs.per_information18 || ' ' || rs.per_information19
,rs.attribute7
,rs.attribute9
,rs.attribute8
,rs.attribute10
,rs.attribute11
,rs.attribute13
,rs.attribute12
,rs.attribute14
,rs.attribute15
,rs.attribute17
,rs.attribute16
,rs.attribute18
,rs.attribute19
,rs.attribute21
,rs.attribute20
,rs.attribute22
,rs.assignment_id
,rs.ass_attribute2
,rs.ass_attribute3
,rs.ass_attribute4
,xxcso_util_common_pkg.get_base_name(rs.ass_attribute3, xxcso_util_common_pkg.get_online_sysdate)
,xxcso_util_common_pkg.get_base_name(rs.ass_attribute4, xxcso_util_common_pkg.get_online_sysdate)
,rs.ass_attribute11
,rs.ass_attribute12
,SUBSTRB(rs.ass_attribute13, 1, 3)
,SUBSTRB(rs.ass_attribute14, 1, 3)
,rs.resource_id
,rs.sales_style
,jrgmn.group_id
,jrgmo.group_id
,jrgmn.group_member_id
,jrgmo.group_member_id
,jrgmn.attribute1
,jrgmo.attribute1
,jrgmn.attribute2
,jrgmo.attribute2
,jrgmn.attribute3
,jrgmo.attribute3
FROM
 ( 
 SELECT 
   fu.user_id, 
   fu.user_name, 
   ppf.person_id, 
   ppf.employee_number, 
   ppf.per_information18, 
   ppf.per_information19, 
   ppf.attribute7, 
   ppf.attribute8, 
   ppf.attribute9, 
   ppf.attribute10, 
   ppf.attribute11, 
   ppf.attribute12, 
   ppf.attribute13, 
   ppf.attribute14, 
   ppf.attribute15, 
   ppf.attribute16, 
   ppf.attribute17, 
   ppf.attribute18, 
   ppf.attribute19, 
   ppf.attribute20, 
   ppf.attribute21, 
   ppf.attribute22, 
   paf.assignment_id, 
   paf.ass_attribute2, 
   paf.ass_attribute3, 
   paf.ass_attribute4, 
   paf.ass_attribute11, 
   paf.ass_attribute12, 
   paf.ass_attribute13, 
   paf.ass_attribute14, 
   jrre.resource_id, 
   jrre.attribute1 sales_style 
 FROM 
   fnd_user fu, 
   per_people_f ppf, 
   per_assignments_f paf, 
   jtf_rs_resource_extns jrre 
 WHERE 
   ppf.person_id = fu.employee_id AND 
   ppf.effective_start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND 
   ppf.effective_end_date >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND 
   paf.person_id = ppf.person_id AND 
   paf.effective_start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND 
   paf.effective_end_date >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND 
   jrre.user_id = fu.user_id AND 
   jrre.source_id = ppf.person_id AND 
   jrre.category = 'EMPLOYEE' AND 
   jrre.start_date_active <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND 
   NVL(jrre.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) 
) rs
,( 
 SELECT 
   jrgb.group_id, 
   jrgb.attribute1 rsg_dept_code, 
   jrgm.group_member_id, 
   jrgm.resource_id, 
   jrgm.attribute1, 
   jrgm.attribute2, 
   jrgm.attribute3 
 FROM 
   jtf_rs_groups_b jrgb, 
   jtf_rs_group_members jrgm 
 WHERE 
   jrgb.start_date_active <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND 
   NVL(jrgb.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND 
   jrgm.delete_flag = 'N' AND 
   jrgm.group_id = jrgb.group_id 
)  jrgmn
,( 
 SELECT 
   jrgb.group_id, 
   jrgb.attribute1 rsg_dept_code, 
   jrgm.group_member_id, 
   jrgm.resource_id, 
   jrgm.attribute1, 
   jrgm.attribute2, 
   jrgm.attribute3 
 FROM 
   jtf_rs_groups_b jrgb, 
   jtf_rs_group_members jrgm 
 WHERE 
   jrgb.start_date_active <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND 
   NVL(jrgb.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND 
   jrgm.delete_flag = 'N' AND 
   jrgm.group_id = jrgb.group_id 
)  jrgmo
WHERE
jrgmn.rsg_dept_code(+) = rs.ass_attribute3 AND
jrgmn.resource_id(+) = rs.resource_id AND
jrgmo.rsg_dept_code(+) = rs.ass_attribute4 AND
jrgmo.resource_id(+) = rs.resource_id
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.user_id IS '���[�U�[ID';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.user_name IS '���[�U�[��';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.person_id IS '�]�ƈ�ID';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.employee_number IS '�]�ƈ��ԍ�';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.last_name IS '������';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.first_name IS '������';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.full_name IS '����';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.qualify_code_new IS '���i�R�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.qualify_code_old IS '���i�R�[�h�i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.qualify_name_new IS '���i���i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.qualify_name_old IS '���i���i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.position_code_new IS '�E�ʃR�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.position_code_old IS '�E�ʃR�[�h�i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.position_name_new IS '�E�ʖ��i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.position_name_old IS '�E�ʖ��i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.duty_code_new IS '�E���R�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.duty_code_old IS '�E���R�[�h�i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.duty_name_new IS '�E�����i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.duty_name_old IS '�E�����i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.job_type_code_new IS '�E��R�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.job_type_code_old IS '�E��R�[�h�i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.job_type_name_new IS '�E�햼�i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.job_type_name_old IS '�E�햼�i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.assignment_id IS '�A�T�C�����gID';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.issue_date IS '���ߓ�';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.work_base_code_new IS '�Ζ��n���_�R�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.work_base_code_old IS '�Ζ��n���_�R�[�h�i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.work_base_name_new IS '�Ζ��n���_���i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.work_base_name_old IS '�Ζ��n���_���i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.position_sort_code_new IS '�E�ʕ����R�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.position_sort_code_old IS '�E�ʕ����R�[�h�i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.approval_type_code_new IS '���F�R�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.approval_type_code_old IS '���F�R�[�h�i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.resource_id IS '���\�[�XID';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.sales_style IS '�c�ƌ`��';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.group_id_new IS '�O���[�vID�i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.group_id_old IS '�O���[�vID�i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.group_member_id_new IS '�O���[�v�����o�[ID�i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.group_member_id_old IS '�O���[�v�����o�[ID�i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.group_leader_flag_new IS '�O���[�v���敪�i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.group_leader_flag_old IS '�O���[�v���敪�i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.group_number_new IS '�O���[�v�ԍ��i�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.group_number_old IS '�O���[�v�ԍ��i���j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.group_grade_new IS '�O���[�v���ʁi�V�j';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V2.group_grade_old IS '�O���[�v���ʁi���j';
COMMENT ON TABLE XXCSO_RESOURCE_RELATIONS_V2 IS '���ʗp�F���\�[�X�֘A�}�X�^�i�ŐV�j�r���[';
