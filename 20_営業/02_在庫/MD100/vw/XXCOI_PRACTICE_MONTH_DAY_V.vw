/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOI_PRACTICE_MONTH_DAY_V
 * Description : 棚卸年月日ビュー2
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/02/06    1.0   SCS              新規作成
 *
 ************************************************************************/
  CREATE OR REPLACE FORCE VIEW "APPS"."XXCOI_PRACTICE_MONTH_DAY_V" ("PRACTICE_DATE","INVENTORY_KBN") AS 
  SELECT  DISTINCT
          a.practice_date,
          a.inventory_kbn
FROM  (SELECT TO_CHAR(practice_date,'YYYYMMDD')   practice_date
             ,'1'                                 inventory_kbn
       FROM   xxcoi_inv_reception_daily
       WHERE  practice_date < xxccp_common_pkg2.get_process_date
       UNION ALL
       SELECT TO_CHAR(practice_date,'YYYYMMDD')   practice_date
             ,'2'                                 inventory_kbn
       FROM   xxcoi_inv_reception_monthly
       WHERE  inventory_kbn = '1'
       AND    practice_date < xxccp_common_pkg2.get_process_date
       UNION ALL
       SELECT practice_month                      practice_date
             ,'3'                                 inventory_kbn
       FROM   xxcoi_inv_reception_monthly
       WHERE  inventory_kbn = '2'
       AND    practice_date < xxccp_common_pkg2.get_process_date
       )      a
ORDER BY a.practice_date;
