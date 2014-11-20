CREATE OR REPLACE VIEW xxcfr_dept_relate_v
/*************************************************************************
 * 
 * View Name       : XXCFR_DEPT_RELATE_V
 * Description     : 所属拠点及び管理拠点ビュー
 * MD.050          : MD.050_LDM_CFR_001
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- -------------  -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- -------------  -------------------------------------
 *  2010-03-11    1.0  SCS 金田 拓朗   初回作成
 ************************************************************************/
(
  dept_code                   -- 拠点コード
)
AS
  SELECT ppf.attribute28  dept_code       -- 拠点コード
    FROM per_all_people_f ppf
        ,fnd_user fu
   WHERE fu.employee_id = ppf.person_id
    AND  ppf.current_employee_flag = 'Y'
    AND  TRUNC( sysdate )
         BETWEEN ppf.effective_start_date
             AND ppf.effective_end_date
    AND  fu.user_id = fnd_profile.value( 'USER_ID' ) 
  UNION ALL
  SELECT hca2.account_number  dept_code    -- 拠点コード
   FROM hz_cust_accounts       hca2
       ,xxcmm_cust_accounts    xca2
       ,per_all_people_f       ppf
       ,fnd_user               fu
  WHERE fu.user_id = fnd_profile.value( 'USER_ID' )
    AND fu.employee_id            = ppf.person_id
    AND ppf.current_employee_flag = 'Y'
    AND TRUNC( SYSDATE )    BETWEEN ppf.effective_start_date
                                AND ppf.effective_end_date
    AND ppf.attribute28           = xca2.management_base_code
    AND xca2.customer_id          = hca2.cust_account_id
    AND hca2.customer_class_code  = '1'
;

COMMENT ON COLUMN  xxcfr_dept_relate_v.dept_code        IS '拠点コード';

COMMENT ON TABLE  xxcfr_dept_relate_v IS '所属拠点及び管理拠点ビュー';
