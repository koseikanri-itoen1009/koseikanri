/*************************************************************************
 * 
 * VIEW Name       : XXCSO_VISIT_SALES_RESULTS_V
 * Description     : 共通用：訪問売上実績ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 *  2009/03/03    1.1  K.Boku        売上実績VIEWを参照する
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
SELECT  *
  FROM  (
         SELECT  jtb.source_object_id
                ,jtb.task_id
                ,jtb.owner_id
                ,jtb.attribute13
                ,jtb.actual_end_date
                ,SUM(xsv.pure_amount)
           FROM  jtf_tasks_b jtb
                ,xxcso_sales_v xsv
          WHERE jtb.source_object_type_code = 'PARTY'
            AND jtb.task_status_id          = FND_PROFILE.VALUE('XXCSO1_TASK_STATUS_CLOSED_ID')
            AND jtb.owner_type_code         = 'RS_EMPLOYEE'
            AND jtb.deleted_flag            = 'N'
            AND jtb.attribute11             = '1'
            AND jtb.attribute12             IN ('3', '5')
            AND jtb.attribute13             = xsv.order_no_hht(+)
          GROUP BY
                jtb.source_object_id
               ,jtb.task_id
               ,jtb.owner_id
               ,jtb.attribute13
               ,jtb.actual_end_date
        )
UNION ALL
SELECT  jtb.source_object_id
       ,jtb.task_id
       ,jtb.owner_id
       ,jtb.attribute13
       ,jtb.actual_end_date
       ,NULL
  FROM  jtf_tasks_b jtb
 WHERE jtb.source_object_type_code = 'PARTY'
   AND jtb.task_status_id          = FND_PROFILE.VALUE('XXCSO1_TASK_STATUS_CLOSED_ID')
   AND jtb.owner_type_code         = 'RS_EMPLOYEE'
   AND jtb.deleted_flag            = 'N'
   AND NVL(jtb.attribute11, ' ') || '-' || NVL(jtb.attribute12, ' ') NOT IN ('1-3', '1-5')
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_VISIT_SALES_RESULTS_V IS '共通用：訪問売上実績ビュー';
