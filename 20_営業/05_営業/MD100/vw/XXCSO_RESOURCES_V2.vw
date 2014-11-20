/*************************************************************************
 * 
 * VIEW Name       : XXCSO_RESOURCES_V2
 * Description     : 共通用：リソースマスタ（最新）ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_RESOURCES_V2
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
,sales_dashboad_use_flag
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
,paf.ass_attribute3
,paf.ass_attribute4
,xxcso_util_common_pkg.get_base_name(paf.ass_attribute3, xxcso_util_common_pkg.get_online_sysdate)
,xxcso_util_common_pkg.get_base_name(paf.ass_attribute4, xxcso_util_common_pkg.get_online_sysdate)
,paf.ass_attribute11
,paf.ass_attribute12
,SUBSTRB(paf.ass_attribute13, 1, 3)
,SUBSTRB(paf.ass_attribute14, 1, 3)
,jrre.resource_id
,jrre.attribute1
,jrre.attribute4
FROM
 fnd_user fu
,per_people_f ppf
,per_assignments_f paf
,jtf_rs_resource_extns jrre
WHERE
fu.start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
NVL(fu.end_date, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
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
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_RESOURCES_V2.user_id IS 'ユーザーID';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.user_name IS 'ユーザー名';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.person_id IS '従業員ID';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.employee_number IS '従業員番号';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.last_name IS '漢字姓';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.first_name IS '漢字名';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.full_name IS '氏名';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.qualify_code_new IS '資格コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.qualify_code_old IS '資格コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.qualify_name_new IS '資格名（新）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.qualify_name_old IS '資格名（旧）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.position_code_new IS '職位コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.position_code_old IS '職位コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.position_name_new IS '職位名（新）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.position_name_old IS '職位名（旧）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.duty_code_new IS '職務コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.duty_code_old IS '職務コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.duty_name_new IS '職務名（新）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.duty_name_old IS '職務名（旧）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.job_type_code_new IS '職種コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.job_type_code_old IS '職種コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.job_type_name_new IS '職種名（新）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.job_type_name_old IS '職種名（旧）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.assignment_id IS 'アサイメントID';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.issue_date IS '発令日';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.work_base_code_new IS '勤務地拠点コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.work_base_code_old IS '勤務地拠点コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.work_base_name_new IS '勤務地拠点名（新）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.work_base_name_old IS '勤務地拠点名（旧）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.position_sort_code_new IS '職位並順コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.position_sort_code_old IS '職位並順コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.approval_type_code_new IS '承認コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.approval_type_code_old IS '承認コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.resource_id IS 'リソースID';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.sales_style IS '営業形態';
COMMENT ON COLUMN XXCSO_RESOURCES_V2.sales_dashboad_use_flag IS '営業ダッシュボード使用';
COMMENT ON TABLE XXCSO_RESOURCES_V2 IS '共通用：リソースマスタ（最新）ビュー';
