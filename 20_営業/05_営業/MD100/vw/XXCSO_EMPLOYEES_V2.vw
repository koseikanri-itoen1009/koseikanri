/*************************************************************************
 * 
 * VIEW Name       : XXCSO_EMPLOYEES_V2
 * Description     : €ΚpF]Ζυ}X^iΕVjr[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ρμ¬
 *  2009/03/25    1.1  K.Satomura    STαQΞ(T1_0156)
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_EMPLOYEES_V2
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
)
AS
SELECT
 fu.user_id
,fu.user_name
,ppf.person_id
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
,paf.ass_attribute2
/* 2009/03/25 K.Satomura ST0156 START */
--,paf.ass_attribute3
--,paf.ass_attribute4
--,xxcso_util_common_pkg.get_base_name(paf.ass_attribute3, xxcso_util_common_pkg.get_online_sysdate)
--,xxcso_util_common_pkg.get_base_name(paf.ass_attribute4, xxcso_util_common_pkg.get_online_sysdate)
,paf.ass_attribute5
,paf.ass_attribute6
,xxcso_util_common_pkg.get_base_name(paf.ass_attribute5, xxcso_util_common_pkg.get_online_sysdate)
,xxcso_util_common_pkg.get_base_name(paf.ass_attribute6, xxcso_util_common_pkg.get_online_sysdate)
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
fu.start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
NVL(fu.end_date, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
ppf.person_id = fu.employee_id AND
ppf.effective_start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
ppf.effective_end_date >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
paf.person_id = ppf.person_id AND
paf.effective_start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
paf.effective_end_date >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.user_id IS '[U[ID';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.user_name IS '[U[Ό';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.person_id IS ']ΖυID';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.employee_number IS ']ΖυΤ';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.last_name IS 'Ώ©';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.first_name IS 'ΏΌ';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.full_name IS 'Ό';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.qualify_code_new IS 'iR[hiVj';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.qualify_code_old IS 'iR[hij';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.qualify_name_new IS 'iΌiVj';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.qualify_name_old IS 'iΌij';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.position_code_new IS 'EΚR[hiVj';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.position_code_old IS 'EΚR[hij';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.position_name_new IS 'EΚΌiVj';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.position_name_old IS 'EΚΌij';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.duty_code_new IS 'E±R[hiVj';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.duty_code_old IS 'E±R[hij';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.duty_name_new IS 'E±ΌiVj';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.duty_name_old IS 'E±Όij';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.job_type_code_new IS 'EνR[hiVj';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.job_type_code_old IS 'EνR[hij';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.job_type_name_new IS 'EνΌiVj';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.job_type_name_old IS 'EνΌij';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.assignment_id IS 'ATCgID';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.issue_date IS '­ίϊ';
/* 2009/03/25 K.Satomura ST0156 START */
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.work_base_code_new IS 'Ξ±n_R[hiVj';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.work_base_code_old IS 'Ξ±n_R[hij';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.work_base_name_new IS 'Ξ±n_ΌiVj';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.work_base_name_old IS 'Ξ±n_Όij';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.work_base_code_new IS '_R[hiVj';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.work_base_code_old IS '_R[hij';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.work_base_name_new IS '_ΌiVj';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.work_base_name_old IS '_Όij';
/* 2009/03/25 K.Satomura ST0156 END */
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.position_sort_code_new IS 'EΚΐR[hiVj';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.position_sort_code_old IS 'EΚΐR[hij';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.approval_type_code_new IS '³FR[hiVj';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V2.approval_type_code_old IS '³FR[hij';
COMMENT ON TABLE XXCSO_EMPLOYEES_V2 IS '€ΚpF]Ζυ}X^iΕVjr[';
