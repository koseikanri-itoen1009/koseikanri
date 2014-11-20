/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name   : XXCOI_HHT_INV_DATE_V
 * Description : �I���N�����r���[
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/12/09    1.0   U.Sai            �V�K�쐬
 *  2009/04/30    1.1   T.Nakamura       �J�����R�����g�A�o�b�N�X���b�V����ǉ�
 *
 ************************************************************************/

  CREATE OR REPLACE FORCE VIEW "APPS"."XXCOI_HHT_INV_DATE_V" ("INVENTORY_DATE", "INVENTORY_KBN") AS 
  SELECT DISTINCT
       MD.INVENTORY_DATE
      ,MD.INVENTORY_KBN       
FROM  (SELECT TO_CHAR(INVENTORY_DATE,'YYYYMMDD') AS INVENTORY_DATE
             ,'1' AS INVENTORY_KBN
       FROM   XXCOI_INV_RESULT
       WHERE  INVENTORY_KBN = '1'
       AND    INVENTORY_DATE < XXCCP_COMMON_PKG2.GET_PROCESS_DATE
       UNION ALL
       SELECT TO_CHAR(INVENTORY_DATE,'YYYYMM') AS INVENTORY_DATE
             ,'2' AS INVENTORY_KBN
       FROM   XXCOI_INV_RESULT
       WHERE  INVENTORY_KBN = '2'
       AND    INVENTORY_DATE < XXCCP_COMMON_PKG2.GET_PROCESS_DATE
       )      MD
ORDER BY MD.INVENTORY_DATE
/
COMMENT ON TABLE  XXCOI_HHT_INV_DATE_V                   IS '�I���N�����r���[';
/
COMMENT ON COLUMN XXCOI_HHT_INV_DATE_V.INVENTORY_DATE    IS '�I���N����';
/
COMMENT ON COLUMN XXCOI_HHT_INV_DATE_V.INVENTORY_KBN     IS '�I���敪';
/
