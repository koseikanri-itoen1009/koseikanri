CREATE OR REPLACE VIEW XXCSM_MY_BRANCH_V
(
  branch_code
 ,branch_name
)
AS
  --発令日が過去日付の場合、(新)拠点コードを導出
  SELECT xlnlv.base_code      --自拠点コード
        ,xlnlv.base_name      --自拠点名称
  FROM   xxcsm_loc_name_list_v xlnlv
        ,fnd_user              fu
        ,per_all_assignments_f paa
        ,xxcsm_process_date_v  xpcdv
  WHERE  xlnlv.base_code = paa.ass_attribute5
  AND    fu.employee_id  = paa.person_id
  AND    fu.user_id      = fnd_global.user_id
  AND    TO_DATE(paa.ass_attribute2,'YYYY/MM/DD') <= xpcdv.process_date
  UNION ALL
  --発令日が先日付の場合、(旧)拠点コードを導出
  SELECT xlnlv.base_code
        ,xlnlv.base_name
  FROM   xxcsm_loc_name_list_v xlnlv
        ,fnd_user fu
        ,per_all_assignments_f paa
        ,xxcsm_process_date_v  xpcdv
  WHERE  xlnlv.BASE_CODE = paa.ass_attribute6
  AND    fu.employee_id  = paa.person_id
  AND    fu.user_id      = fnd_global.user_id
  AND    TO_DATE(paa.ass_attribute2,'YYYY/MM/DD') > xpcdv.process_date
;
--
COMMENT ON COLUMN xxcsm_my_branch_v.branch_code           IS '自拠点コード';
COMMENT ON COLUMN xxcsm_my_branch_v.branch_name           IS '自拠点名称';
--                
COMMENT ON TABLE  xxcsm_my_branch_v IS '自拠点ビュー';
