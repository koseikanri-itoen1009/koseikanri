/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOI_REC_DAILY_MONTHLY_V
 * Description : �󕥔N�����r���[
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/28    1.0   U.Sai            �V�K�쐬
 *  2009/04/30    1.1   T.Nakamura       �J�����R�����g�A�o�b�N�X���b�V����ǉ�
 *  2009/08/20    1.2   T.Murakami       �ȉ��̃J�����R�����g���C��
 *                                       1.�󕥔N�����́uBASE_CODE�v���uPRACTICE_DATE�v
 *                                       2.�I���敪�́uBASE_SHORT_NAME�v���uINVENTORY_KBN�v
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
COMMENT ON TABLE  XXCOI_REC_DAILY_MONTHLY_V                   IS '�󕥔N�����r���[';
/
COMMENT ON COLUMN XXCOI_REC_DAILY_MONTHLY_V.PRACTICE_DATE     IS '�󕥔N����';
/
COMMENT ON COLUMN XXCOI_REC_DAILY_MONTHLY_V.INVENTORY_KBN     IS '�I���敪';
/
