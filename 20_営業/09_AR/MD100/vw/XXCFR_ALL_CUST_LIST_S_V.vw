CREATE OR REPLACE FORCE VIEW "APPS"."XXCFR_ALL_CUST_LIST_S_V" ("CUSTOMER_CODE", "CUSTOMER_NAME","CUSTOMER_CLASS_CODE") AS 
  SELECT xca.customer_code           AS customer_code
      ,xxcfr_common_pkg.get_cust_account_name(
         xca.customer_code,'0')    AS customer_name
      ,hca.customer_class_code     AS customer_class_code
FROM   hz_cust_accounts     hca
      ,xxcmm_cust_accounts  xca
      ,(SELECT pap.attribute28 AS current_base_code
        FROM   per_all_people_f pap
              ,fnd_user         fu
        WHERE  fu.employee_id = pap.person_id
        AND    fu.user_id     = fnd_global.user_id
        AND  ( pap.effective_start_date IS NULL
            OR pap.effective_start_date <= SYSDATE
             )
        AND  ( pap.effective_end_date IS NULL
            OR pap.effective_end_date >= SYSDATE
             )
       )                   temp
WHERE  hca.cust_account_id     = xca.customer_id
AND    hca.customer_class_code in ('10','20','21','14')
AND    EXISTS(SELECT NULL
              FROM   hz_cust_acct_sites hcas
              WHERE  hca.cust_account_id = hcas.cust_account_id
       )
AND  ( xca.bill_base_code = temp.current_base_code
    OR EXISTS(SELECT NULL 
              FROM   fnd_lookup_values_vl 
              WHERE  lookup_type = 'XXCFR1_INVOICE_ALL_OUTPUT_DEPT'
              AND    lookup_code = temp.current_base_code
              AND    attribute3  = 'Y'
       )
     );