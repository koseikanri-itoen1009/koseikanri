/*************************************************************************
 * 
 * VIEW Name       : XXCSO_EMPLOYEES_V3
 * Description     : ���ʗp�F�]�ƈ��}�X�^�i�ŐV�j�r���[3
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/05/29    1.0  M.Ohtsuki    ����쐬
 *  2009/06/09    1.1  K.Satomura   �V�X�e���e�X�g�Ή�(T1_1207)
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_EMPLOYEES_V3
(
/* 2009.06.09 K.Satomura T1_1207�Ή� START */
-- user_id
--,user_name
--,person_id
--,employee_number
--,last_name
--,first_name
--,full_name
--,qualify_code_new
--,qualify_code_old
--,qualify_name_new
--,qualify_name_old
--,position_code_new
--,position_code_old
--,position_name_new
--,position_name_old
--,duty_code_new
--,duty_code_old
--,duty_name_new
--,duty_name_old
--,job_type_code_new
--,job_type_code_old
--,job_type_name_new
--,job_type_name_old
--,assignment_id
--,issue_date
--,work_base_code_new
--,work_base_code_old
--,work_base_name_new
--,work_base_name_old
--,position_sort_code_new
--,position_sort_code_old
--,approval_type_code_new
--,approval_type_code_old
 employee_number
,full_name
/* 2009.06.09 K.Satomura T1_1207�Ή� END */
)
AS
SELECT
/* 2009.06.09 K.Satomura T1_1207�Ή� START */
DISTINCT
-- fu.user_id
--,fu.user_name
--,ppf.person_id
--,ppf.employee_number
--,ppf.per_information18
--,ppf.per_information19
--,ppf.per_information18 || ' ' || ppf.per_information19
--,ppf.attribute7
--,ppf.attribute9
--,ppf.attribute8
--,ppf.attribute10
--,ppf.attribute11
--,ppf.attribute13
--,ppf.attribute12
--,ppf.attribute14
--,ppf.attribute15
--,ppf.attribute17
--,ppf.attribute16
--,ppf.attribute18
--,ppf.attribute19
--,ppf.attribute21
--,ppf.attribute20
--,ppf.attribute22
--,paf.assignment_id
--,paf.ass_attribute2
--,paf.ass_attribute5
--,paf.ass_attribute6
--,xxcso_util_common_pkg.get_base_name(paf.ass_attribute5, xxcso_util_common_pkg.get_online_sysdate)
--,xxcso_util_common_pkg.get_base_name(paf.ass_attribute6, xxcso_util_common_pkg.get_online_sysdate)
--,paf.ass_attribute11
--,paf.ass_attribute12
--,SUBSTRB(paf.ass_attribute13, 1, 3)
--,SUBSTRB(paf.ass_attribute14, 1, 3)
 ppf.employee_number
,ppf.per_information18 || ' ' || ppf.per_information19
/* 2009.06.09 K.Satomura T1_1207�Ή� END */
FROM
 fnd_user fu
,per_people_f ppf
,per_assignments_f paf
WHERE
fu.start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
NVL(ADD_MONTHS(fu.end_date,1), TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
ppf.person_id = fu.employee_id AND
ppf.effective_start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
ADD_MONTHS(ppf.effective_end_date,1) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
paf.person_id = ppf.person_id AND
paf.effective_start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
ADD_MONTHS(paf.effective_end_date,1) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
/* 2009.06.09 K.Satomura T1_1207�Ή� START */
AND ppf.effective_start_date = paf.effective_start_date
/* 2009.06.09 K.Satomura T1_1207�Ή� END */
WITH READ ONLY
;
/* 2009.06.09 K.Satomura T1_1207�Ή� START */
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.user_id IS '���[�U�[ID';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.user_name IS '���[�U�[��';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.person_id IS '�]�ƈ�ID';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.employee_number IS '�]�ƈ��ԍ�';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.last_name IS '������';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.first_name IS '������';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.full_name IS '����';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.qualify_code_new IS '���i�R�[�h�i�V�j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.qualify_code_old IS '���i�R�[�h�i���j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.qualify_name_new IS '���i���i�V�j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.qualify_name_old IS '���i���i���j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.position_code_new IS '�E�ʃR�[�h�i�V�j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.position_code_old IS '�E�ʃR�[�h�i���j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.position_name_new IS '�E�ʖ��i�V�j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.position_name_old IS '�E�ʖ��i���j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.duty_code_new IS '�E���R�[�h�i�V�j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.duty_code_old IS '�E���R�[�h�i���j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.duty_name_new IS '�E�����i�V�j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.duty_name_old IS '�E�����i���j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.job_type_code_new IS '�E��R�[�h�i�V�j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.job_type_code_old IS '�E��R�[�h�i���j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.job_type_name_new IS '�E�햼�i�V�j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.job_type_name_old IS '�E�햼�i���j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.assignment_id IS '�A�T�C�����gID';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.issue_date IS '���ߓ�';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.work_base_code_new IS '���_�R�[�h�i�V�j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.work_base_code_old IS '���_�R�[�h�i���j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.work_base_name_new IS '���_���i�V�j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.work_base_name_old IS '���_���i���j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.position_sort_code_new IS '�E�ʕ����R�[�h�i�V�j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.position_sort_code_old IS '�E�ʕ����R�[�h�i���j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.approval_type_code_new IS '���F�R�[�h�i�V�j';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.approval_type_code_old IS '���F�R�[�h�i���j';
--COMMENT ON TABLE XXCSO_EMPLOYEES_V3 IS '���ʗp�F�]�ƈ��}�X�^�i�ŐV�j�r���[3';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.employee_number IS '�]�ƈ��ԍ�';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.full_name IS '����';
/* 2009.06.09 K.Satomura T1_1207�Ή� END */
