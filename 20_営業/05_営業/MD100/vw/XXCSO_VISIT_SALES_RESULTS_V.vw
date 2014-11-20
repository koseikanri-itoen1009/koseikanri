/*************************************************************************
 * 
 * VIEW Name       : XXCSO_VISIT_SALES_RESULTS_V
 * Description     : ���ʗp�F�K�┄����уr���[
 * MD.070          : 
 * Version         : 1.4
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ����쐬
 *  2009/03/03    1.1  K.Boku        �������VIEW���Q�Ƃ���
 *  2009/04/14    1.2  K.Satomura    �V�X�e���e�X�g��Q�Ή�(T1_0479,T1_0480)
 *  2009/04/24    1.3  K.Satomura    �V�X�e���e�X�g��Q�Ή�(T1_0734,T1_0743)
 *  2009/11/24    1.4  D.Abe         ��Q�Ή�(E_�{�ғ�_00026)
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_VISIT_SALES_RESULTS_V
(
  party_id
 ,task_id
 ,owner_id
 ,attribute13
 ,actual_end_date
 ,pure_amount_sum
)
AS
/* 2009.04.14 K.Satomura T1_0479,T1_0480�Ή� START */
--SELECT  *
--  FROM  (
--         SELECT  jtb.source_object_id
--                ,jtb.task_id
--                ,jtb.owner_id
--                ,jtb.attribute13
--                ,jtb.actual_end_date
--                ,SUM(xsv.pure_amount)
--           FROM  jtf_tasks_b jtb
--                ,xxcso_sales_v xsv
--          WHERE jtb.source_object_type_code = 'PARTY'
--            AND jtb.task_status_id          = FND_PROFILE.VALUE('XXCSO1_TASK_STATUS_CLOSED_ID')
--            AND jtb.owner_type_code         = 'RS_EMPLOYEE'
--            AND jtb.deleted_flag            = 'N'
--            AND jtb.attribute11             = '1'
--            AND jtb.attribute12             IN ('3', '5')
--            AND jtb.attribute13             = xsv.order_no_hht(+)
--          GROUP BY
--                jtb.source_object_id
--               ,jtb.task_id
--               ,jtb.owner_id
--               ,jtb.attribute13
--               ,jtb.actual_end_date
--        )
--UNION ALL
--SELECT  jtb.source_object_id
--       ,jtb.task_id
--       ,jtb.owner_id
--       ,jtb.attribute13
--       ,jtb.actual_end_date
--       ,NULL
--  FROM  jtf_tasks_b jtb
-- WHERE jtb.source_object_type_code = 'PARTY'
--   AND jtb.task_status_id          = FND_PROFILE.VALUE('XXCSO1_TASK_STATUS_CLOSED_ID')
--   AND jtb.owner_type_code         = 'RS_EMPLOYEE'
--   AND jtb.deleted_flag            = 'N'
--   AND NVL(jtb.attribute11, ' ') || '-' || NVL(jtb.attribute12, ' ') NOT IN ('1-3', '1-5')
SELECT party_id
      ,task_id
      ,owner_id
      ,attribute13
      ,actual_end_date
      ,pure_amount
FROM   (
         SELECT jtb.source_object_id party_id
               ,jtb.task_id          task_id
               ,jtb.owner_id         owner_id
               ,jtb.attribute13      attribute13
               ,jtb.actual_end_date  actual_end_date
               /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� START */
               --,SUM(xsv.pure_amount) pure_amount
               ,xsv.pure_amount      pure_amount
               /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� END */
         FROM   jtf_tasks_b   jtb
               /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� START */
               ,(select order_no_hht,SUM(pure_amount) pure_amount from xxcso_sales_of_task_v group by order_no_hht) xsv
               --,xxcso_sales_v xsv
               /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� END */
         WHERE jtb.source_object_type_code = 'PARTY'
         AND   jtb.task_status_id          = fnd_profile.value('XXCSO1_TASK_STATUS_CLOSED_ID')
         AND   jtb.task_type_id            = fnd_profile.value('XXCSO1_TASK_TYPE_VISIT')
         AND   jtb.owner_type_code         = 'RS_EMPLOYEE'
         AND   jtb.deleted_flag            = 'N'
         AND   jtb.attribute11             = '1'
         /* 2009.04.14 K.Satomura T1_0743�Ή� START */
         --AND   jtb.attribute12             IN ('3', '5')
         --AND   jtb.attribute13             = xsv.order_no_hht(+)
         AND   (
                     jtb.attribute12            = '3'
                 AND TO_NUMBER(jtb.attribute13) = xsv.order_no_hht
               )
         /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� START */
         --      OR
         --      (     jtb.attribute12 = '5'
         --         AND jtb.attribute13 = xsv.dlv_invoice_number
         --      )
         /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� END */
         /* 2009.04.14 K.Satomura T1_0743�Ή� END */
         /* 2009.04.14 K.Satomura T1_0734�Ή� START */
         AND   jtb.actual_end_date IS NOT NULL
         /* 2009.04.14 K.Satomura T1_0734�Ή� END */
         /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� START */
         --GROUP BY jtb.source_object_id
         --        ,jtb.task_id
         --        ,jtb.owner_id
         --        ,jtb.attribute13
         --        ,jtb.actual_end_date
          /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� END */
          /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� START */
         UNION ALL
         SELECT jtb.source_object_id party_id
               ,jtb.task_id          task_id
               ,jtb.owner_id         owner_id
               ,jtb.attribute13      attribute13
               ,jtb.actual_end_date  actual_end_date
               ,xsv.pure_amount      pure_amount
         FROM   jtf_tasks_b   jtb
               ,(select dlv_invoice_number,SUM(pure_amount) pure_amount from xxcso_sales_of_task_v group by dlv_invoice_number) xsv
         WHERE jtb.source_object_type_code = 'PARTY'
         AND   jtb.task_status_id          = fnd_profile.value('XXCSO1_TASK_STATUS_CLOSED_ID')
         AND   jtb.task_type_id            = fnd_profile.value('XXCSO1_TASK_TYPE_VISIT')
         AND   jtb.owner_type_code         = 'RS_EMPLOYEE'
         AND   jtb.deleted_flag            = 'N'
         AND   jtb.attribute11             = '1'
         AND   (     jtb.attribute12 = '5'
                 AND jtb.attribute13 = xsv.dlv_invoice_number
               )
         AND   jtb.actual_end_date IS NOT NULL
         /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� END */
         /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� START */
         --UNION ALL
         --SELECT ala.customer_id      party_id
         --      ,jtb.task_id          task_id
         --      ,jtb.owner_id         owner_id
         --      ,jtb.attribute13      attribute13
         --      ,jtb.actual_end_date  actual_end_date
         --      ,SUM(xsv.pure_amount) pure_amount
         --FROM   jtf_tasks_b   jtb
         --      ,xxcso_sales_v xsv
         --      ,as_leads_all  ala
         --WHERE jtb.source_object_type_code = 'OPPORTUNITY'
         --AND   jtb.task_status_id          = fnd_profile.value('XXCSO1_TASK_STATUS_CLOSED_ID')
         --AND   jtb.task_type_id            = fnd_profile.value('XXCSO1_TASK_TYPE_VISIT')
         --AND   jtb.owner_type_code         = 'RS_EMPLOYEE'
         --AND   jtb.deleted_flag            = 'N'
         --AND   jtb.attribute11             = '1'
         --/* 2009.04.14 K.Satomura T1_0743�Ή� START */
         ----AND   jtb.attribute12             IN ('3', '5')
         ----AND   jtb.attribute13             = xsv.order_no_hht(+)
         --AND   (
         --            jtb.attribute12            = '3'
         --        AND TO_NUMBER(jtb.attribute13) = xsv.order_no_hht
         --      )
         --      OR
         --      (     jtb.attribute12 = '5'
         --        AND jtb.attribute13 = xsv.dlv_invoice_number
         --      )
         --/* 2009.04.14 K.Satomura T1_0743�Ή� END */
         --/* 2009.04.14 K.Satomura T1_0734�Ή� START */
         ----AND   ala.customer_id             = jtb.source_object_id
         --AND   ala.lead_id                 = jtb.source_object_id
         --AND   jtb.actual_end_date IS NOT NULL
         --/* 2009.04.14 K.Satomura T1_0734�Ή� END */
         --GROUP BY ala.customer_id
         --        ,jtb.task_id
         --        ,jtb.owner_id
         --        ,jtb.attribute13
         --        ,jtb.actual_end_date
         /* 2009.11.24 D.Abe E_�{�ғ�_00026�Ή� END */
       )
UNION ALL
SELECT party_id
      ,task_id
      ,owner_id
      ,attribute13
      ,actual_end_date
      ,NULL
FROM   (
         SELECT jtb.source_object_id party_id
               ,jtb.task_id          task_id
               ,jtb.owner_id         owner_id
               ,jtb.attribute13      attribute13
               ,jtb.actual_end_date  actual_end_date
               ,NULL                 pure_amount
         FROM  jtf_tasks_b jtb
         WHERE jtb.source_object_type_code = 'PARTY'
         AND jtb.task_status_id          = fnd_profile.value('XXCSO1_TASK_STATUS_CLOSED_ID')
         AND jtb.task_type_id            = fnd_profile.value('XXCSO1_TASK_TYPE_VISIT')
         AND jtb.owner_type_code         = 'RS_EMPLOYEE'
         AND jtb.deleted_flag            = 'N'
         AND NVL(jtb.attribute11, ' ') || '-' || NVL(jtb.attribute12, ' ') NOT IN ('1-3', '1-5')
         /* 2009.04.14 K.Satomura T1_0734�Ή� START */
         AND   jtb.actual_end_date IS NOT NULL
         /* 2009.04.14 K.Satomura T1_0734�Ή� END */
         UNION ALL
         SELECT ala.customer_id     party_id
               ,jtb.task_id         task_id
               ,jtb.owner_id        owner_id
               ,jtb.attribute13     attribute13
               ,jtb.actual_end_date actual_end_date
               ,NULL                pure_amount
         FROM   jtf_tasks_b  jtb
               ,as_leads_all ala
         WHERE jtb.source_object_type_code = 'OPPORTUNITY'
         AND   jtb.task_status_id          = fnd_profile.value('XXCSO1_TASK_STATUS_CLOSED_ID')
         AND   jtb.task_type_id            = fnd_profile.value('XXCSO1_TASK_TYPE_VISIT')
         AND   jtb.owner_type_code         = 'RS_EMPLOYEE'
         AND   jtb.deleted_flag            = 'N'
         AND   NVL(jtb.attribute11, ' ') || '-' || NVL(jtb.attribute12, ' ') NOT IN ('1-3', '1-5')
         /* 2009.04.14 K.Satomura T1_0734�Ή� START */
         --AND   ala.customer_id             = jtb.source_object_id
         AND   ala.lead_id                 = jtb.source_object_id
         AND   jtb.actual_end_date IS NOT NULL
         /* 2009.04.14 K.Satomura T1_0734�Ή� END */
       )
       /* 2009.04.14 K.Satomura T1_0479,T1_0480�Ή� END */
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_VISIT_SALES_RESULTS_V IS '���ʗp�F�K�┄����уr���[';
