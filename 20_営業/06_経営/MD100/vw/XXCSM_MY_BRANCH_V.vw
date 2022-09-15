CREATE OR REPLACE VIEW XXCSM_MY_BRANCH_V
(
  branch_code
 ,branch_name
)
AS
  --���ߓ����ߋ����t�̏ꍇ�A(�V)���_�R�[�h�𓱏o
  SELECT xlnlv.base_code      --�����_�R�[�h
        ,xlnlv.base_name      --�����_����
  FROM   xxcsm_loc_name_list_v xlnlv
        ,fnd_user              fu
        ,per_all_assignments_f paa
        ,xxcsm_process_date_v  xpcdv
  WHERE  xlnlv.base_code = paa.ass_attribute5
  AND    fu.employee_id  = paa.person_id
  AND    fu.user_id      = fnd_global.user_id
  AND    TO_DATE(paa.ass_attribute2,'YYYY/MM/DD') <= xpcdv.process_date
-- 2022/07/12 E_�{�ғ�_15286 MOD START
--  UNION ALL
  UNION
-- 2022/07/12 E_�{�ғ�_15286 MOD END
  --���ߓ�������t�̏ꍇ�A(��)���_�R�[�h�𓱏o
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
-- 2022/07/12 E_�{�ғ�_15286 ADD START
  UNION
  -- �Ǘ������_�i���ߓ����ߋ����t�̏ꍇ�A(�V)���_�R�[�h�𓱏o�j
  SELECT xlnlv.base_code      --�����_�R�[�h
        ,xlnlv.base_name      --�����_����
  FROM   xxcsm_loc_name_list_v     xlnlv
        ,fnd_user                  fu
        ,per_all_assignments_f     paa
        ,xxcsm_process_date_v      xpcdv
        ,xxcmm.xxcmm_cust_accounts xcav
  WHERE  xlnlv.base_code           = xcav.customer_code
  AND    fu.employee_id            = paa.person_id
  AND    fu.user_id                = fnd_global.user_id
  AND    xcav.management_base_code = paa.ass_attribute5
  AND    TO_DATE(paa.ass_attribute2,'YYYY/MM/DD') <= xpcdv.process_date
  UNION
  --�Ǘ������_�i���ߓ�������t�̏ꍇ�A(��)���_�R�[�h�𓱏o�j
  SELECT xlnlv.base_code
        ,xlnlv.base_name
  FROM   xxcsm_loc_name_list_v     xlnlv
        ,fnd_user                  fu
        ,per_all_assignments_f     paa
        ,xxcsm_process_date_v      xpcdv
        ,xxcmm.xxcmm_cust_accounts xcav
  WHERE  xlnlv.base_code           = xcav.customer_code
  AND    fu.employee_id            = paa.person_id
  AND    fu.user_id                = fnd_global.user_id
  AND    xcav.management_base_code = paa.ass_attribute6
  AND    TO_DATE(paa.ass_attribute2,'YYYY/MM/DD') > xpcdv.process_date
-- 2022/07/12 E_�{�ғ�_15286 ADD END
;
--
COMMENT ON COLUMN xxcsm_my_branch_v.branch_code           IS '�����_�R�[�h';
COMMENT ON COLUMN xxcsm_my_branch_v.branch_name           IS '�����_����';
--                
COMMENT ON TABLE  xxcsm_my_branch_v IS '�����_�r���[';
