/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOI_REC_DAILY_MONTHLY_V
 * Description : 受払年月日ビュー
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/28    1.0   U.Sai            新規作成
 *  2009/04/30    1.1   T.Nakamura       カラムコメント、バックスラッシュを追加
 *  2009/08/20    1.2   T.Murakami       以下のカラムコメントを修正
 *                                       1.受払年月日の「BASE_CODE」→「PRACTICE_DATE」
 *                                       2.棚卸区分の「BASE_SHORT_NAME」→「INVENTORY_KBN」
 *
 ************************************************************************/

  CREATE OR REPLACE FORCE VIEW "APPS"."XXCOI_REC_DAILY_MONTHLY_V" ("PRACTICE_DATE", "INVENTORY_KBN") AS 
  SELECT DISTINCT
       MD.PRACTICE_DATE
      ,MD.INVENTORY_KBN       
FROM  (SELECT TO_CHAR(PRACTICE_DATE,'YYYYMMDD') AS PRACTICE_DATE
             ,'2' AS INVENTORY_KBN
       FROM   XXCOI_INV_RECEPTION_MONTHLY
       WHERE  INVENTORY_KBN = '1'
       AND    PRACTICE_DATE < XXCCP_COMMON_PKG2.GET_PROCESS_DATE
       UNION ALL
       SELECT PRACTICE_MONTH AS PRACTICE_DATE
             ,'3' AS INVENTORY_KBN
       FROM   XXCOI_INV_RECEPTION_MONTHLY
       WHERE  INVENTORY_KBN = '2'
       AND    PRACTICE_MONTH < TO_CHAR(XXCCP_COMMON_PKG2.GET_PROCESS_DATE,'YYYYMM')
       UNION ALL
       SELECT TO_CHAR(PRACTICE_DATE,'YYYYMMDD') AS PRACTICE_DATE
             ,'1' AS INVENTORY_KBN
       FROM   XXCOI_INV_RECEPTION_DAILY
       WHERE  PRACTICE_DATE < XXCCP_COMMON_PKG2.GET_PROCESS_DATE
       )      MD
ORDER BY MD.PRACTICE_DATE
/
COMMENT ON TABLE  XXCOI_REC_DAILY_MONTHLY_V                   IS '受払年月日ビュー';
/
COMMENT ON COLUMN XXCOI_REC_DAILY_MONTHLY_V.PRACTICE_DATE     IS '受払年月日';
/
COMMENT ON COLUMN XXCOI_REC_DAILY_MONTHLY_V.INVENTORY_KBN     IS '棚卸区分';
/
