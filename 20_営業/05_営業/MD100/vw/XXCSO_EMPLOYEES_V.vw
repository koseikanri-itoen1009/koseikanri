/*************************************************************************
 * 
 * VIEW Name       : XXCSO_EMPLOYEES_V
 * Description     : ���ʗp�F�]�ƈ��}�X�^�r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ����쐬
 *  2009/03/25    1.1  K.Satomura    ST��Q�Ή�(T1_0156)
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_EMPLOYEES_V
(
 user_id
,user_name
,start_date
,end_date
,person_id
,employee_start_date
,employee_end_date
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
,assign_start_date
,assign_end_date
,issue_date
,work_base_code_new
,work_base_code_old
,position_sort_code_new
,position_sort_code_old
,approval_type_code_new
,approval_type_code_old
)
AS
SELECT
 fu.user_id
,fu.user_name
,fu.start_date
,fu.end_date
,ppf.person_id
,ppf.effective_start_date
,ppf.effective_end_date
,ppf.employee_number
,ppf.per_information18
,ppf.per_information19
,ppf.per_information18 || ' ' || ppf.per_information19
,ppf.attribute7
,ppf.attribute9
,ppf.attribute8
,ppf.attribute10
,ppf.attribute11
,ppf.attribute13
,ppf.attribute12
,ppf.attribute14
,ppf.attribute15
,ppf.attribute17
,ppf.attribute16
,ppf.attribute18
,ppf.attribute19
,ppf.attribute21
,ppf.attribute20
,ppf.attribute22
,paf.assignment_id
,paf.effective_start_date
,paf.effective_end_date
,paf.ass_attribute2
/* 2009/03/25 K.Satomura ST0156 START */
--,paf.ass_attribute3
--,paf.ass_attribute4
,paf.ass_attribute5
,paf.ass_attribute6
/* 2009/03/25 K.Satomura ST0156 END */
,paf.ass_attribute11
,paf.ass_attribute12
,SUBSTRB(paf.ass_attribute13, 1, 3)
,SUBSTRB(paf.ass_attribute14, 1, 3)
FROM
 fnd_user fu
,per_people_f ppf
,per_assignments_f paf
WHERE
ppf.person_id = fu.employee_id AND
paf.person_id = ppf.person_id
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.user_id IS '���[�U�[ID';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.user_name IS '���[�U�[��';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.start_date IS '�J�n���i���[�U�[�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.end_date IS '�I�����i���[�U�[�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.person_id IS '�]�ƈ�ID';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.employee_start_date IS '�L���J�n���i�]�ƈ��j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.employee_end_date IS '�L���I�����i�]�ƈ��j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.employee_number IS '�]�ƈ��ԍ�';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.last_name IS '������';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.first_name IS '������';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.full_name IS '����';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.qualify_code_new IS '���i�R�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.qualify_code_old IS '���i�R�[�h�i���j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.qualify_name_new IS '���i���i�V�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.qualify_name_old IS '���i���i���j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.position_code_new IS '�E�ʃR�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.position_code_old IS '�E�ʃR�[�h�i���j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.position_name_new IS '�E�ʖ��i�V�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.position_name_old IS '�E�ʖ��i���j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.duty_code_new IS '�E���R�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.duty_code_old IS '�E���R�[�h�i���j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.duty_name_new IS '�E�����i�V�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.duty_name_old IS '�E�����i���j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.job_type_code_new IS '�E��R�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.job_type_code_old IS '�E��R�[�h�i���j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.job_type_name_new IS '�E�햼�i�V�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.job_type_name_old IS '�E�햼�i���j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.assignment_id IS '�A�T�C�����gID';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.assign_start_date IS '�L���J�n���i�A�T�C�����g�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.assign_end_date IS '�L���I�����i�A�T�C�����g�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.issue_date IS '���ߓ�';
/* 2009/03/25 K.Satomura ST0156 START */
-- COMMENT ON COLUMN XXCSO_EMPLOYEES_V.work_base_code_new IS '�Ζ��n���_�R�[�h�i�V�j';
-- COMMENT ON COLUMN XXCSO_EMPLOYEES_V.work_base_code_old IS '�Ζ��n���_�R�[�h�i���j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.work_base_code_new IS '���_�R�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.work_base_code_old IS '���_�R�[�h�i���j';
/* 2009/03/25 K.Satomura ST0156 END */
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.position_sort_code_new IS '�E�ʕ����R�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.position_sort_code_old IS '�E�ʕ����R�[�h�i���j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.approval_type_code_new IS '���F�R�[�h�i�V�j';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.approval_type_code_old IS '���F�R�[�h�i���j';
COMMENT ON TABLE XXCSO_EMPLOYEES_V IS '���ʗp�F�]�ƈ��}�X�^�r���[';
