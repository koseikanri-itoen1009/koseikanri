/*************************************************************************
 * 
 * VIEW Name       : XXCSO_EMPLOYEES_V3
 * Description     : 共通用：従業員マスタ（最新）ビュー3
 * MD.070          : 
 * Version         : 1.2
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/05/29    1.0  M.Ohtsuki    初回作成
 *  2009/06/09    1.1  K.Satomura   システムテスト対応(T1_1207)
 *  2009/09/11    1.2  K.Satomura   統合テスト対応(0001349)
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_EMPLOYEES_V3
(
/* 2009.06.09 K.Satomura T1_1207対応 START */
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
/* 2009.06.09 K.Satomura T1_1207対応 END */
)
AS
SELECT
/* 2009.06.09 K.Satomura T1_1207対応 START */
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
/* 2009.06.09 K.Satomura T1_1207対応 END */
FROM
 fnd_user fu
,per_people_f ppf
,per_assignments_f paf
/* 2009.09.11 K.Satomura 0001349対応 START */
--WHERE
--fu.start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
--NVL(ADD_MONTHS(fu.end_date,1), TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
--ppf.person_id = fu.employee_id AND
--ppf.effective_start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
--ADD_MONTHS(ppf.effective_end_date,1) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
--paf.person_id = ppf.person_id AND
--paf.effective_start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
--ADD_MONTHS(paf.effective_end_date,1) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
--/* 2009.06.09 K.Satomura T1_1207対応 START */
--AND ppf.effective_start_date = paf.effective_start_date
--/* 2009.06.09 K.Satomura T1_1207対応 END */
WHERE fu.start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
AND   NVL(ADD_MONTHS(fu.end_date,NVL(TO_NUMBER(fnd_profile.value('XXCSO1_ADMIN_EXTENSION_MONTHS')),0)), TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >=
        TRUNC(xxcso_util_common_pkg.get_online_sysdate)
AND   ppf.person_id             = fu.employee_id
AND   ppf.effective_start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
AND   ADD_MONTHS(ppf.effective_end_date,NVL(TO_NUMBER(fnd_profile.value('XXCSO1_ADMIN_EXTENSION_MONTHS')),0)) >=
      TRUNC(xxcso_util_common_pkg.get_online_sysdate)
AND   paf.person_id             = ppf.person_id
AND   paf.effective_start_date <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
AND   ADD_MONTHS(paf.effective_end_date,NVL(TO_NUMBER(fnd_profile.value('XXCSO1_ADMIN_EXTENSION_MONTHS')),0)) >=
      TRUNC(xxcso_util_common_pkg.get_online_sysdate)
AND   ppf.effective_start_date = paf.effective_start_date
/* 2009.09.11 K.Satomura 0001349対応 END */
WITH READ ONLY
;
/* 2009.06.09 K.Satomura T1_1207対応 START */
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.user_id IS 'ユーザーID';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.user_name IS 'ユーザー名';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.person_id IS '従業員ID';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.employee_number IS '従業員番号';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.last_name IS '漢字姓';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.first_name IS '漢字名';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.full_name IS '氏名';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.qualify_code_new IS '資格コード（新）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.qualify_code_old IS '資格コード（旧）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.qualify_name_new IS '資格名（新）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.qualify_name_old IS '資格名（旧）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.position_code_new IS '職位コード（新）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.position_code_old IS '職位コード（旧）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.position_name_new IS '職位名（新）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.position_name_old IS '職位名（旧）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.duty_code_new IS '職務コード（新）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.duty_code_old IS '職務コード（旧）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.duty_name_new IS '職務名（新）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.duty_name_old IS '職務名（旧）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.job_type_code_new IS '職種コード（新）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.job_type_code_old IS '職種コード（旧）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.job_type_name_new IS '職種名（新）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.job_type_name_old IS '職種名（旧）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.assignment_id IS 'アサイメントID';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.issue_date IS '発令日';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.work_base_code_new IS '拠点コード（新）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.work_base_code_old IS '拠点コード（旧）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.work_base_name_new IS '拠点名（新）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.work_base_name_old IS '拠点名（旧）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.position_sort_code_new IS '職位並順コード（新）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.position_sort_code_old IS '職位並順コード（旧）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.approval_type_code_new IS '承認コード（新）';
--COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.approval_type_code_old IS '承認コード（旧）';
--COMMENT ON TABLE XXCSO_EMPLOYEES_V3 IS '共通用：従業員マスタ（最新）ビュー3';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.employee_number IS '従業員番号';
COMMENT ON COLUMN XXCSO_EMPLOYEES_V3.full_name IS '氏名';
/* 2009.06.09 K.Satomura T1_1207対応 END */
