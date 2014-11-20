/*************************************************************************
 * 
 * VIEW Name       : XXCSO_RESOURCE_RELATIONS_V
 * Description     : 共通用：リソース関連マスタビュー
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
CREATE OR REPLACE VIEW APPS.XXCSO_RESOURCE_RELATIONS_V
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
/* 2009/03/25 K.Satomura ST0156 START */
,last_name_kana
,first_name_kana
/* 2009/03/25 K.Satomura ST0156 END */
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
,work_dept_code_new
,work_dept_code_old
,position_sort_code_new
,position_sort_code_old
,approval_type_code_new
,approval_type_code_old
,resource_id
,resource_start_date
,resource_end_date
,sales_style
,group_id_new
,group_id_old
,start_date_active_new
,start_date_active_old
,end_date_active_new
,end_date_active_old
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
,rs.start_date
,rs.end_date
,rs.person_id
,rs.ppf_start_date
,rs.ppf_end_date
,rs.employee_number
,rs.per_information18
,rs.per_information19
,rs.per_information18 || ' ' || rs.per_information19
/* 2009/03/25 K.Satomura ST0156 START */
,rs.last_name
,rs.first_name
/* 2009/03/25 K.Satomura ST0156 END */
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
,rs.paf_start_date
,rs.paf_end_date
,rs.ass_attribute2
/* 2009/03/25 K.Satomura ST0156 START */
--,rs.ass_attribute3
--,rs.ass_attribute4
,rs.ass_attribute5
,rs.ass_attribute6
/* 2009/03/25 K.Satomura ST0156 END */
,rs.ass_attribute11
,rs.ass_attribute12
,SUBSTRB(rs.ass_attribute13, 1, 3)
,SUBSTRB(rs.ass_attribute14, 1, 3)
,rs.resource_id
,rs.start_date_active
,rs.end_date_active
,rs.sales_style
,jrgmn.group_id
,jrgmo.group_id
,jrgmn.start_date_active
,jrgmo.start_date_active
,jrgmn.end_date_active
,jrgmo.end_date_active
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
   fu.start_date, 
   fu.end_date, 
   ppf.person_id, 
   ppf.employee_number, 
   ppf.effective_start_date ppf_start_date, 
   ppf.effective_end_date ppf_end_date, 
   ppf.per_information18, 
   ppf.per_information19, 
   /* 2009/03/25 K.Satomura ST0156 START */
   ppf.last_name, 
   ppf.first_name, 
   /* 2009/03/25 K.Satomura ST0156 END */
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
   paf.effective_start_date paf_start_date, 
   paf.effective_end_date paf_end_date, 
   paf.ass_attribute2, 
   /* 2009/03/25 K.Satomura ST0156 START */
   --paf.ass_attribute3, 
   --paf.ass_attribute4, 
   paf.ass_attribute5, 
   paf.ass_attribute6, 
   /* 2009/03/25 K.Satomura ST0156 END */
   paf.ass_attribute11, 
   paf.ass_attribute12, 
   paf.ass_attribute13, 
   paf.ass_attribute14, 
   jrre.resource_id, 
   jrre.start_date_active, 
   jrre.end_date_active, 
   jrre.attribute1 sales_style 
 FROM 
   fnd_user fu, 
   per_people_f ppf, 
   per_assignments_f paf, 
   jtf_rs_resource_extns jrre 
 WHERE 
   ppf.person_id = fu.employee_id AND 
   paf.person_id = ppf.person_id AND 
   jrre.user_id = fu.user_id AND 
   jrre.source_id = ppf.person_id AND 
   jrre.category = 'EMPLOYEE' 
) rs
,( 
 SELECT 
   jrgb.group_id, 
   jrgb.attribute1 rsg_dept_code, 
   jrgb.start_date_active, 
   jrgb.end_date_active, 
   jrgm.group_member_id, 
   jrgm.resource_id, 
   jrgm.attribute1, 
   jrgm.attribute2, 
   jrgm.attribute3 
 FROM 
   jtf_rs_groups_b jrgb, 
   jtf_rs_group_members jrgm 
 WHERE 
   jrgm.delete_flag = 'N' AND 
   jrgm.group_id = jrgb.group_id 
)  jrgmn
,( 
 SELECT 
   jrgb.group_id, 
   jrgb.attribute1 rsg_dept_code, 
   jrgb.start_date_active, 
   jrgb.end_date_active, 
   jrgm.group_member_id, 
   jrgm.resource_id, 
   jrgm.attribute1, 
   jrgm.attribute2, 
   jrgm.attribute3 
 FROM 
   jtf_rs_groups_b jrgb, 
   jtf_rs_group_members jrgm 
 WHERE 
   jrgm.delete_flag = 'N' AND 
   jrgm.group_id = jrgb.group_id 
)  jrgmo
WHERE
/* 2009/03/25 K.Satomura ST0156 START */
--jrgmn.rsg_dept_code(+) = rs.ass_attribute3 AND
jrgmn.rsg_dept_code(+) = rs.ass_attribute5 AND
/* 2009/03/25 K.Satomura ST0156 END */
jrgmn.resource_id(+) = rs.resource_id AND
/* 2009/03/25 K.Satomura ST0156 START */
--jrgmo.rsg_dept_code(+) = rs.ass_attribute4 AND
jrgmo.rsg_dept_code(+) = rs.ass_attribute6 AND
/* 2009/03/25 K.Satomura ST0156 END */
jrgmo.resource_id(+) = rs.resource_id
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.user_id IS 'ユーザーID';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.user_name IS 'ユーザー名';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.start_date IS '開始日（ユーザー）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.end_date IS '終了日（ユーザー）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.person_id IS '従業員ID';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.employee_start_date IS '有効開始日（従業員）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.employee_end_date IS '有効終了日（従業員）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.employee_number IS '従業員番号';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.last_name IS '漢字姓';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.first_name IS '漢字名';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.full_name IS '氏名';
/* 2009/03/25 K.Satomura ST0156 START */
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.last_name_kana IS 'カナ姓';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.first_name_kana IS 'カナ名';
/* 2009/03/25 K.Satomura ST0156 END */
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.qualify_code_new IS '資格コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.qualify_code_old IS '資格コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.qualify_name_new IS '資格名（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.qualify_name_old IS '資格名（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.position_code_new IS '職位コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.position_code_old IS '職位コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.position_name_new IS '職位名（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.position_name_old IS '職位名（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.duty_code_new IS '職務コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.duty_code_old IS '職務コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.duty_name_new IS '職務名（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.duty_name_old IS '職務名（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.job_type_code_new IS '職種コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.job_type_code_old IS '職種コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.job_type_name_new IS '職種名（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.job_type_name_old IS '職種名（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.assignment_id IS 'アサイメントID';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.assign_start_date IS '有効開始日（アサイメント）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.assign_end_date IS '有効終了日（アサイメント）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.issue_date IS '発令日';
/* 2009/03/25 K.Satomura ST0156 START */
-- COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.work_dept_code_new IS '勤務地拠点コード（新）';
-- COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.work_dept_code_old IS '勤務地拠点コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.work_dept_code_new IS '拠点コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.work_dept_code_old IS '拠点コード（旧）';
/* 2009/03/25 K.Satomura ST0156 END */
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.position_sort_code_new IS '職位並順コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.position_sort_code_old IS '職位並順コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.approval_type_code_new IS '承認コード（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.approval_type_code_old IS '承認コード（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.resource_id IS 'リソースID';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.resource_start_date IS '有効開始日（リソース）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.resource_end_date IS '有効開始日（リソース）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.sales_style IS '営業形態';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.group_id_new IS 'グループID（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.group_id_old IS 'グループID（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.start_date_active_new IS '有効開始日（グループ）（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.start_date_active_old IS '有効開始日（グループ）（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.end_date_active_new IS '有効終了日（グループ）（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.end_date_active_old IS '有効終了日（グループ）（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.group_member_id_new IS 'グループメンバーID（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.group_member_id_old IS 'グループメンバーID（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.group_leader_flag_new IS 'グループ長区分（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.group_leader_flag_old IS 'グループ長区分（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.group_number_new IS 'グループ番号（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.group_number_old IS 'グループ番号（旧）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.group_grade_new IS 'グループ順位（新）';
COMMENT ON COLUMN XXCSO_RESOURCE_RELATIONS_V.group_grade_old IS 'グループ順位（旧）';
COMMENT ON TABLE XXCSO_RESOURCE_RELATIONS_V IS '共通用：リソース関連マスタビュー';
