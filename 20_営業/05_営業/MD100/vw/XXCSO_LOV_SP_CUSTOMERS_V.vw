/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * VIEW Name      : XXCSO_LOV_SP_CUSTOMERS_V
 * Description    : SP専決顧客LOVビュー
 * Version        : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2015/02/10    1.0   S.Yamashita      新規作成
 *
 ****************************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_LOV_SP_CUSTOMERS_V
(
 account_number
,account_name
,cust_account_id
,search_class
)
AS
SELECT  xcav.account_number   AS account_number
       ,xcav.party_name       AS account_name
       ,xcav.cust_account_id  AS cust_account_id
       ,'1'                   AS search_class
FROM    xxcso_cust_accounts_v    xcav
WHERE   (fnd_profile.value('XXCSO1_SP_REGIST_APPROVE_KBN') = '1')
  AND   (xcav.account_number  IN
          (
           SELECT xcr1.account_number
           FROM   xxcso_cust_resources_v2 xcr1
           WHERE  xcr1.employee_number IN (
                  SELECT employee_number
                  FROM (
                    SELECT xev3.employee_number
                    FROM   xxcso_employees_v2 xev3
                    WHERE xev3.work_base_code_new IN (
                                  SELECT xev1.work_base_code_new  work_base_code
                                  FROM   xxcso_employees_v2 xev1
                                  WHERE  xev1.user_id     = fnd_global.user_id
                                  AND    xev1.issue_date <= TO_CHAR(xxccp_common_pkg2.get_process_date,'YYYYMMDD')
                           )
                    UNION ALL
                    SELECT xev4.employee_number
                    FROM   xxcso_employees_v2 xev4
                    WHERE  xev4.work_base_code_old IN (
                                  SELECT xev2.work_base_code_old  work_base_code
                                  FROM   xxcso_employees_v2 xev2
                                  WHERE  xev2.user_id     = fnd_global.user_id
                                  AND    xev2.issue_date  > TO_CHAR(xxccp_common_pkg2.get_process_date,'YYYYMMDD')
                           )
                  )
           )
           UNION
           SELECT xca2.customer_code
           FROM   xxcmm_cust_accounts xca2
           WHERE  xca2.sale_base_code IN  (
                  SELECT xx3.work_base_code
                  FROM  (SELECT xev1.work_base_code_new  work_base_code
                         FROM   xxcso_employees_v2 xev1
                         WHERE  xev1.user_id     = fnd_global.user_id
                         AND    xev1.issue_date <= TO_CHAR(xxccp_common_pkg2.get_process_date,'YYYYMMDD')
                         UNION ALL
                         SELECT xev2.work_base_code_old  work_base_code
                         FROM   xxcso_employees_v2 xev2
                         WHERE  xev2.user_id     = fnd_global.user_id
                         AND    xev2.issue_date  > TO_CHAR(xxccp_common_pkg2.get_process_date,'YYYYMMDD')
                        ) xx3
                  )
           UNION
           SELECT xca3.customer_code
           FROM   xxcmm_cust_accounts xca3
                 ,fnd_lookup_values_vl flv
           WHERE  flv.lookup_type  = 'XXCMM_CHAIN_CODE'
           AND    flv.lookup_code  = xca3.sales_chain_code -- 販売先チェーンコード
           AND    flv.enabled_flag = 'Y'
           AND    NVL(flv.start_date_active, TRUNC(xxccp_common_pkg2.get_process_date))
                                  <= TRUNC(xxccp_common_pkg2.get_process_date)
           AND    NVL(flv.end_date_active, TRUNC(xxccp_common_pkg2.get_process_date))
                                  >= TRUNC(xxccp_common_pkg2.get_process_date)
           AND    flv.attribute3 IN (
                  SELECT xx4.work_base_code
                  FROM  (SELECT xev1.work_base_code_new  work_base_code
                         FROM   xxcso_employees_v2 xev1
                         WHERE  xev1.user_id     = fnd_global.user_id
                         AND    xev1.issue_date <= TO_CHAR(xxccp_common_pkg2.get_process_date,'YYYYMMDD')
                         UNION ALL
                         SELECT xev2.work_base_code_old  work_base_code
                         FROM   xxcso_employees_v2 xev2
                         WHERE  xev2.user_id     = fnd_global.user_id
                         AND    xev2.issue_date  > TO_CHAR(xxccp_common_pkg2.get_process_date,'YYYYMMDD')
                        ) xx4
                  )
          )
        )
  AND   (xcav.customer_class_code = '10' OR xcav.customer_class_code IS NULL)
  AND   (xcav.business_low_type IS NULL OR
         xcav.business_low_type IN (
           SELECT  flvv2.lookup_code
           FROM    fnd_lookup_values_vl  flvv1
                  ,fnd_lookup_values_vl  flvv2
           WHERE   flvv1.lookup_type   = 'XXCMM_CUST_GYOTAI_SHO'
             AND   flvv1.enabled_flag  = 'Y'
             AND   NVL(flvv1.start_date_active, TRUNC(xxccp_common_pkg2.get_process_date))
                                      <= TRUNC(xxccp_common_pkg2.get_process_date)
             AND   NVL(flvv1.end_date_active, TRUNC(xxccp_common_pkg2.get_process_date))
                                      >= TRUNC(xxccp_common_pkg2.get_process_date)
             AND   flvv2.lookup_type   = 'XXCSO1_SP_CATEGORY'
             AND   flvv2.enabled_flag  = 'Y'
             AND   NVL(flvv2.start_date_active, TRUNC(xxccp_common_pkg2.get_process_date))
                                      <= TRUNC(xxccp_common_pkg2.get_process_date)
             AND   NVL(flvv2.end_date_active, TRUNC(xxccp_common_pkg2.get_process_date))
                                      >= TRUNC(xxccp_common_pkg2.get_process_date)
             AND   flvv2.lookup_code   = flvv1.lookup_code
         )
       )
UNION ALL
SELECT  xcav.account_number   AS account_number
       ,xcav.party_name       AS account_name
       ,xcav.cust_account_id  AS cust_account_id
       ,'2'                   AS search_class
FROM    xxcso_cust_accounts_v    xcav
WHERE   (fnd_profile.value('XXCSO1_SP_REGIST_APPROVE_KBN') = '2')
  AND   (xcav.customer_class_code = '10' OR xcav.customer_class_code IS NULL)
  AND   (xcav.business_low_type IS NULL OR
         xcav.business_low_type IN (
           SELECT  flvv2.lookup_code
           FROM    fnd_lookup_values_vl  flvv1
                  ,fnd_lookup_values_vl  flvv2
           WHERE   flvv1.lookup_type   = 'XXCMM_CUST_GYOTAI_SHO'
             AND   flvv1.enabled_flag  = 'Y'
             AND   NVL(flvv1.start_date_active, TRUNC(xxccp_common_pkg2.get_process_date))
                                      <= TRUNC(xxccp_common_pkg2.get_process_date)
             AND   NVL(flvv1.end_date_active, TRUNC(xxccp_common_pkg2.get_process_date))
                                      >= TRUNC(xxccp_common_pkg2.get_process_date)
             AND   flvv2.lookup_type   = 'XXCSO1_SP_CATEGORY'
             AND   flvv2.enabled_flag  = 'Y'
             AND   NVL(flvv2.start_date_active, TRUNC(xxccp_common_pkg2.get_process_date))
                                      <= TRUNC(xxccp_common_pkg2.get_process_date)
             AND   NVL(flvv2.end_date_active, TRUNC(xxccp_common_pkg2.get_process_date))
                                      >= TRUNC(xxccp_common_pkg2.get_process_date)
             AND   flvv2.lookup_code   = flvv1.lookup_code
         )
        )
;
--
COMMENT ON COLUMN XXCSO_LOV_SP_CUSTOMERS_V.account_number   IS '顧客コード';
COMMENT ON COLUMN XXCSO_LOV_SP_CUSTOMERS_V.account_name     IS '顧客名称';
COMMENT ON COLUMN XXCSO_LOV_SP_CUSTOMERS_V.cust_account_id  IS 'アカウントID';
COMMENT ON COLUMN XXCSO_LOV_SP_CUSTOMERS_V.search_class     IS '検索区分';
COMMENT ON TABLE XXCSO_LOV_SP_CUSTOMERS_V                   IS 'SP専決顧客LOVビュー';
