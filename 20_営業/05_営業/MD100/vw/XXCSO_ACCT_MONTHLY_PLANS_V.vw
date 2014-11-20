/*************************************************************************
 * 
 * VIEW Name       : xxcso_acct_monthly_plans_v
 * Description     : 画面用：訪問・売上計画／売上計画（複数顧客）画面用ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_acct_monthly_plans_v
(
  base_code
 ,account_number
 ,year_month
 ,employee_number
 ,party_id
 ,vist_target_div
 ,target_account_sales_plan_id
 ,target_month_sales_plan_amt
 ,target_year_month
 ,target_month_last_upd_date
 ,target_route_number
 ,next_account_sales_plan_id
 ,next_month_sales_plan_amt
 ,next_year_month
 ,next_month_last_upd_date
 ,next_route_number
 ,created_by
 ,creation_date
 ,last_updated_by
 ,last_update_date
 ,last_update_login
 ,distribute_flg
)
AS 
SELECT  xtsp.base_code
       ,xtsp.account_number
       ,xtsp.year_month
       ,xtsp.employee_number
       ,NULL
       ,NULL
       ,trgt_month.account_sales_plan_id
       ,TO_CHAR(trgt_month.sales_plan_month_amt, 'FM9G999G990')
       ,xtsp.year_month
       ,trgt_month.last_update_date
       ,NULL
       ,next_month.account_sales_plan_id
       ,DECODE(
          NVL(xcrv.account_number, 'NULL')
         ,'NULL'
         ,NULL
         ,TO_CHAR(next_month.sales_plan_month_amt, 'FM9G999G990')
        )
       ,TO_CHAR(ADD_MONTHS(TO_DATE(xtsp.year_month, 'YYYYMM'), 1), 'YYYYMM')
       ,next_month.last_update_date
       ,NULL
       ,fnd_global.user_id
       ,SYSDATE
       ,fnd_global.user_id
       ,SYSDATE
       ,fnd_global.login_id
       ,NULL
FROM    xxcso_tmp_sales_plan       xtsp
       ,xxcso_account_sales_plans  trgt_month
       ,xxcso_account_sales_plans  next_month
       ,xxcso_cust_resources_v xcrv
WHERE   trgt_month.base_code(+)            = xtsp.base_code
  AND   trgt_month.account_number(+)       = xtsp.account_number
  AND   trgt_month.year_month(+)           = xtsp.year_month
  AND   trgt_month.month_date_div(+)       = '1'
  AND   next_month.base_code(+)            = xtsp.base_code
  AND   next_month.account_number(+)       = xtsp.account_number
  AND   next_month.year_month(+)           = TO_CHAR(ADD_MONTHS(TO_DATE(xtsp.year_month, 'YYYYMM'), 1), 'YYYYMM')
  AND   next_month.month_date_div(+)       = '1'
  AND   xcrv.account_number(+)             = xtsp.account_number
  AND   xcrv.employee_number(+)            = xtsp.employee_number
  AND   TRUNC(
          xcrv.start_date_active(+)
         ,'MM'
        ) <= ADD_MONTHS(TO_DATE(xtsp.year_month, 'YYYYMM'), 1)
  AND   TRUNC(
          NVL(xcrv.end_date_active(+)
           ,ADD_MONTHS(TO_DATE(xtsp.year_month, 'YYYYMM'), 1)
          )
         ,'MM'
        ) >= ADD_MONTHS(TO_DATE(xtsp.year_month, 'YYYYMM'), 1)
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_ACCT_MONTHLY_PLANS_V IS '画面用：訪問・売上計画／売上計画（複数顧客）画面用ビュー';
