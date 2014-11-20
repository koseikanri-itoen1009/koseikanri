/*************************************************************************
 * 
 * VIEW Name       : XXCSO_ACCT_WEEKLY_PLANS_V
 * Description     : 画面用：訪問・売上計画画面用ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_ACCT_WEEKLY_PLANS_V
(
 base_code
 ,account_number
 ,year_month
 ,week_index
 ,monday_column
 ,monday_sales_plan_id
 ,monday_value
 ,tuesday_column
 ,tuesday_sales_plan_id
 ,tuesday_value
 ,wednesday_column
 ,wednesday_sales_plan_id
 ,wednesday_value
 ,thursday_column
 ,thursday_sales_plan_id
 ,thursday_value
 ,friday_column
 ,friday_sales_plan_id
 ,friday_value
 ,saturday_column
 ,saturday_sales_plan_id
 ,saturday_value
 ,sunday_column
 ,sunday_sales_plan_id
 ,sunday_value
 ,created_by
 ,creation_date
 ,last_updated_by
 ,last_update_date
 ,last_update_login
)
AS
SELECT  clndr.base_code
       ,clndr.account_number
       ,clndr.year_month
       ,clndr.week_index
       ,clndr.mon
       ,(SELECT  xasp.account_sales_plan_id
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.mon, 2, '0')
           AND   xasp.month_date_div = '2'
        ) monday_sales_plan_id
       ,(SELECT  TO_CHAR(xasp.sales_plan_day_amt, 'FM999G990')
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.mon, 2, '0')
           AND   xasp.month_date_div = '2'
        ) monday_value
       ,clndr.tue
       ,(SELECT  xasp.account_sales_plan_id
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.tue, 2, '0')
           AND   xasp.month_date_div = '2'
        ) tuesday_sales_plan_id
       ,(SELECT  TO_CHAR(xasp.sales_plan_day_amt, 'FM999G990')
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.tue, 2, '0')
           AND   xasp.month_date_div = '2'
        ) tuesday_value
       ,clndr.wed
       ,(SELECT  xasp.account_sales_plan_id
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.wed, 2, '0')
           AND   xasp.month_date_div = '2'
        ) wednesday_sales_plan_id
       ,(SELECT  TO_CHAR(xasp.sales_plan_day_amt, 'FM999G990')
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.wed, 2, '0')
           AND   xasp.month_date_div = '2'
        ) wednesday_value
       ,clndr.thu
       ,(SELECT  xasp.account_sales_plan_id
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.thu, 2, '0')
           AND   xasp.month_date_div = '2'
        ) thursday_sales_plan_id
       ,(SELECT  TO_CHAR(xasp.sales_plan_day_amt, 'FM999G990')
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.thu, 2, '0')
           AND   xasp.month_date_div = '2'
        ) thursday_value
       ,clndr.fri
       ,(SELECT  xasp.account_sales_plan_id
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.fri, 2, '0')
           AND   xasp.month_date_div = '2'
        ) friday_sales_plan_id
       ,(SELECT  TO_CHAR(xasp.sales_plan_day_amt, 'FM999G990')
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.fri, 2, '0')
           AND   xasp.month_date_div = '2'
        ) friday_value
       ,clndr.sat
       ,(SELECT  xasp.account_sales_plan_id
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.sat, 2, '0')
           AND   xasp.month_date_div = '2'
        ) saturday_sales_plan_id
       ,(SELECT  TO_CHAR(xasp.sales_plan_day_amt, 'FM999G990')
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.sat, 2, '0')
           AND   xasp.month_date_div = '2'
        ) saturday_value
       ,clndr.sun
       ,(SELECT  xasp.account_sales_plan_id
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.sun, 2, '0')
           AND   xasp.month_date_div = '2'
        ) sunday_sales_plan_id
       ,(SELECT  TO_CHAR(xasp.sales_plan_day_amt, 'FM999G990')
         FROM    xxcso_account_sales_plans  xasp
         WHERE   xasp.base_code      = clndr.base_code
           AND   xasp.account_number = clndr.account_number
           AND   xasp.year_month     = clndr.year_month
           AND   xasp.plan_day       = LPAD(clndr.sun, 2, '0')
           AND   xasp.month_date_div = '2'
        ) sunday_value
       ,fnd_global.user_id
       ,SYSDATE
       ,fnd_global.user_id
       ,SYSDATE
       ,fnd_global.login_id
FROM    (SELECT  full_clndr.base_code
                ,full_clndr.account_number
                ,full_clndr.year_month
                ,full_clndr.week_index
                ,full_clndr.mon
                ,full_clndr.tue
                ,full_clndr.wed
                ,full_clndr.thu
                ,full_clndr.fri
                ,full_clndr.sat
                ,full_clndr.sun
         FROM    (SELECT  full_calendar.base_code
                         ,full_calendar.account_number
                         ,full_calendar.year_month
                         ,full_calendar.week_index
                         ,DECODE(
                            GREATEST(
                              DECODE(
                                GREATEST(full_calendar.monday + 1, full_calendar.lastday)
                               ,full_calendar.lastday
                               ,full_calendar.monday + 1
                               ,-1
                              )
                             ,0
                            )
                           ,0
                           ,NULL
                           ,full_calendar.monday + 1
                          ) AS mon
                         ,DECODE(
                            GREATEST(
                              DECODE(
                                GREATEST(full_calendar.monday + 2, full_calendar.lastday)
                               ,full_calendar.lastday
                               ,full_calendar.monday + 2
                               ,-1
                              )
                             ,0
                            )
                           ,0
                           ,NULL
                           ,full_calendar.monday + 2
                          ) AS tue
                         ,DECODE(
                            GREATEST(
                              DECODE(
                                GREATEST(full_calendar.monday + 3, full_calendar.lastday)
                               ,full_calendar.lastday
                               ,full_calendar.monday + 3
                               ,-1
                              )
                             ,0
                            )
                           ,0
                           ,NULL
                           ,full_calendar.monday + 3
                          ) AS wed
                         ,DECODE(
                            GREATEST(
                              DECODE(
                                GREATEST(full_calendar.monday + 4, full_calendar.lastday)
                               ,full_calendar.lastday
                               ,full_calendar.monday + 4
                               ,-1
                              )
                             ,0
                            )
                           ,0
                           ,NULL
                           ,full_calendar.monday + 4
                          ) AS thu
                         ,DECODE(
                            GREATEST(
                              DECODE(
                                GREATEST(full_calendar.monday + 5, full_calendar.lastday)
                               ,full_calendar.lastday
                               ,full_calendar.monday + 5
                               ,-1
                              )
                             ,0
                            )
                           ,0
                           ,NULL
                           ,full_calendar.monday + 5
                          ) AS fri
                         ,DECODE(
                            GREATEST(
                              DECODE(
                                GREATEST(full_calendar.monday + 6, full_calendar.lastday)
                               ,full_calendar.lastday
                               ,full_calendar.monday + 6
                               ,-1
                              )
                             ,0
                            )
                           ,0
                           ,NULL
                           ,full_calendar.monday + 6
                          ) AS sat
                         ,DECODE(
                            GREATEST(
                              DECODE(
                                GREATEST(full_calendar.monday + 7, full_calendar.lastday)
                               ,full_calendar.lastday
                               ,full_calendar.monday + 7
                               ,-1
                              )
                             ,0
                            )
                           ,0
                           ,NULL
                           ,full_calendar.monday + 7
                          ) AS sun
                  FROM    (SELECT  xtsp.base_code
                                  ,xtsp.account_number
                                  ,xtsp.year_month
                                  ,week.week_index
                                  ,(week.week_index - 1) * 7
                                      - TO_NUMBER(
                                          TO_CHAR(
                                            TO_DATE(xtsp.year_month, 'YYYYMM')
                                           ,'D'
                                          )
                                        )
                                      - 5 monday
                                  ,TO_NUMBER(
                                     TO_CHAR(
                                       LAST_DAY(
                                         TO_DATE(xtsp.year_month, 'YYYYMM')
                                       )
                                      ,'DD'
                                     )
                                   ) lastday
                           FROM    (SELECT 1 week_index
                                    FROM   DUAL
                                    UNION ALL
                                    SELECT 2 week_index
                                    FROM   DUAL
                                    UNION ALL
                                    SELECT 3 week_index
                                    FROM   DUAL
                                    UNION ALL
                                    SELECT 4 week_index
                                    FROM   DUAL
                                    UNION ALL
                                    SELECT 5 week_index
                                    FROM   DUAL
                                    UNION ALL
                                    SELECT 6 week_index
                                    FROM   DUAL
                                    UNION ALL
                                    SELECT 7 week_index
                                    FROM   DUAL
                                   ) week
                                  ,xxcso_tmp_sales_plan xtsp
                          ) full_calendar
                 ) full_clndr
          WHERE  full_clndr.mon IS NOT NULL
             OR  full_clndr.tue IS NOT NULL
             OR  full_clndr.wed IS NOT NULL
             OR  full_clndr.thu IS NOT NULL
             OR  full_clndr.fri IS NOT NULL
             OR  full_clndr.sat IS NOT NULL
             OR  full_clndr.sun IS NOT NULL
        ) clndr
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_ACCT_WEEKLY_PLANS_V IS '画面用：訪問・売上計画画面用ビュー';
