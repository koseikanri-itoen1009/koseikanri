/*************************************************************************
 * 
 * VIEW Name       : XXCSO_EMPLOYEES_V
 * Description     : 共通用：従業員マスタビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 *  2009/03/25    1.1  K.Satomura    ST障害対応(T1_0156)
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
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.user_id IS 'ユーザーID';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.user_name IS 'ユーザー名';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.start_date IS '開始日（ユーザー）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.end_date IS '終了日（ユーザー）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.person_id IS '従業員ID';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.employee_start_date IS '有効開始日（従業員）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.employee_end_date IS '有効終了日（従業員）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.employee_number IS '従業員番号';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.last_name IS '漢字姓';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.first_name IS '漢字名';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.full_name IS '氏名';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.qualify_code_new IS '資格コード（新）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.qualify_code_old IS '資格コード（旧）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.qualify_name_new IS '資格名（新）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.qualify_name_old IS '資格名（旧）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.position_code_new IS '職位コード（新）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.position_code_old IS '職位コード（旧）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.position_name_new IS '職位名（新）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.position_name_old IS '職位名（旧）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.duty_code_new IS '職務コード（新）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.duty_code_old IS '職務コード（旧）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.duty_name_new IS '職務名（新）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.duty_name_old IS '職務名（旧）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.job_type_code_new IS '職種コード（新）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.job_type_code_old IS '職種コード（旧）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.job_type_name_new IS '職種名（新）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.job_type_name_old IS '職種名（旧）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.assignment_id IS 'アサイメントID';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.assign_start_date IS '有効開始日（アサイメント）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.assign_end_date IS '有効終了日（アサイメント）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.issue_date IS '発令日';
/* 2009/03/25 K.Satomura ST0156 START */
-- COMMENT ON COLUMN XXCSO_EMPLOYEES_V.work_base_code_new IS '勤務地拠点コード（新）';
-- COMMENT ON COLUMN XXCSO_EMPLOYEES_V.work_base_code_old IS '勤務地拠点コード（旧）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.work_base_code_new IS '拠点コード（新）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.work_base_code_old IS '拠点コード（旧）';
/* 2009/03/25 K.Satomura ST0156 END */
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.position_sort_code_new IS '職位並順コード（新）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.position_sort_code_old IS '職位並順コード（旧）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.approval_type_code_new IS '承認コード（新）';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V.approval_type_code_old IS '承認コード（旧）';
COMMENT ON TABLE XXCSO_EMPLOYEES_V IS '共通用：従業員マスタビュー';
