/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOI_USER_BASE_INFO2_V
 * Description : 自拠点情報ビュー2
 * Version     : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   N.Abe            新規作成
 *  2009/04/30    1.1   T.Nakamura       カラムコメント、バックスラッシュを追加
 *  2009/06/02    1.2   H.Wada           障害番号：T1_1299
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW "APPS"."XXCOI_USER_BASE_INFO2_V" ("ACCOUNT_NUMBER", "ACCOUNT_NAME") AS 
SELECT DISTINCT
       a.account_number
      ,a.account_name
FROM    (SELECT  hca.account_number
                ,hca.account_name
         FROM    hz_cust_accounts    hca
                ,xxcmm_cust_accounts xca
         WHERE   hca.customer_class_code  = 1
         AND     hca.cust_account_id      = xca.customer_id
         AND     xca.sale_base_code       =
         (
          SELECT 
           CASE 
           WHEN TO_DATE(paaf.ass_attribute2,'YYYYMMDD') > SYSDATE
           THEN paaf.ass_attribute6
           ELSE paaf.ass_attribute5
           END
           FROM  fnd_user               fu,
                 per_all_people_f       papf,
                 per_all_assignments_f  paaf,
                 per_person_types       ppt
           WHERE fu.user_id             = fnd_global.user_id
           AND   papf.person_id         = fu.employee_id
           AND   TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date) AND TRUNC(papf.effective_end_date)
           AND   TRUNC(SYSDATE) BETWEEN TRUNC(paaf.effective_start_date) AND TRUNC(paaf.effective_end_date)
           AND   ppt.business_group_id  = fnd_global.per_business_group_id
           AND   ppt.system_person_type = 'EMP'
           AND   ppt.active_flag        = 'Y'
           AND   papf.person_type_id    = ppt.person_type_id
           AND   paaf.person_id         = papf.person_id
         )
         UNION ALL
         SELECT  hca.account_number
                ,hca.account_name
         FROM    hz_cust_accounts    hca
                ,xxcmm_cust_accounts xca
         WHERE   hca.customer_class_code  = 1
         AND     hca.cust_account_id      = xca.customer_id
         AND     hca.account_number       =
         (
          SELECT 
           CASE 
           WHEN TO_DATE(paaf.ass_attribute2,'YYYYMMDD') > SYSDATE
           THEN paaf.ass_attribute6
           ELSE paaf.ass_attribute5
           END
           FROM  fnd_user               fu,
                 per_all_people_f       papf,
                 per_all_assignments_f  paaf,
                 per_person_types       ppt
           WHERE fu.user_id = fnd_global.user_id
           AND   papf.person_id         = fu.employee_id
           AND   TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date) AND TRUNC(papf.effective_end_date)
           AND   TRUNC(SYSDATE) BETWEEN TRUNC(paaf.effective_start_date) AND TRUNC(paaf.effective_end_date)
           AND   ppt.business_group_id  = fnd_global.per_business_group_id
           AND   ppt.system_person_type = 'EMP'
           AND   ppt.active_flag        = 'Y'
           AND   papf.person_type_id    = ppt.person_type_id
           AND   paaf.person_id         = papf.person_id
         )
        ) a
ORDER BY a.account_number
/
COMMENT ON TABLE  XXCOI_USER_BASE_INFO2_V                   IS '自拠点情報ビュー2';
/
COMMENT ON COLUMN XXCOI_USER_BASE_INFO2_V.ACCOUNT_NUMBER    IS '拠点コード';
/
COMMENT ON COLUMN XXCOI_USER_BASE_INFO2_V.ACCOUNT_NAME      IS '拠点略称';
/
