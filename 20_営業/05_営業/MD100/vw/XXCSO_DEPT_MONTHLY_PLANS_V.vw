/*************************************************************************
 * 
 * VIEW Name       : xxcso_dept_monthly_plans_v
 * Description     : 画面用：売上計画の選択画面用ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_dept_monthly_plans_v
(
 base_code
,base_name
,target_year
,target_month
,dept_monthly_plan_id
,sales_plan_rel_div
,created_by
,creation_date
,last_updated_by
,last_update_date
,last_update_login
)
AS
SELECT  xabv.base_code
       ,xabv.base_name
       ,TO_CHAR(ADD_MONTHS(TRUNC(xxcso_util_common_pkg.get_online_sysdate), month.month_index), 'YYYY')
       ,TO_CHAR(ADD_MONTHS(TRUNC(xxcso_util_common_pkg.get_online_sysdate), month.month_index), 'MM')
       ,(SELECT  xdmp.dept_monthly_plan_id
         FROM    xxcso_dept_monthly_plans  xdmp
         WHERE   xdmp.base_code        = xabv.base_code
           AND   xdmp.year_month       = TO_CHAR(ADD_MONTHS(TRUNC(xxcso_util_common_pkg.get_online_sysdate), month.month_index), 'YYYYMM')
        )
       ,(SELECT  xdmp.sales_plan_rel_div
         FROM    xxcso_dept_monthly_plans  xdmp
         WHERE   xdmp.base_code        = xabv.base_code
           AND   xdmp.year_month       = TO_CHAR(ADD_MONTHS(TRUNC(xxcso_util_common_pkg.get_online_sysdate), month.month_index), 'YYYYMM')
        )
       ,fnd_global.user_id
       ,SYSDATE
       ,fnd_global.user_id
       ,SYSDATE
       ,fnd_global.login_id
FROM    xxcso_aff_base_v2   xabv
       ,(SELECT  0 month_index
         FROM    DUAL
         UNION ALL
         SELECT  1 month_index
         FROM    DUAL
        ) month
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_DEPT_MONTHLY_PLANS_V IS '画面用：売上計画の選択画面用ビュー';
