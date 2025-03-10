CREATE OR REPLACE PACKAGE XXCOI004A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI004A04R(spec)
 * Description      : VD@àÝÉ\
 * MD.050           : MD050_COI_004_A04
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 RJgÀst@Co^vV[W
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   H.Wada           VKì¬
 *
 *****************************************************************************************/
  PROCEDURE main(
    errbuf           OUT VARCHAR2             --   G[EbZ[W
   ,retcode          OUT VARCHAR2             --   ^[ER[h
   ,iv_output_base   IN  VARCHAR2             --  1.oÍ_
   ,iv_output_period IN  VARCHAR2 DEFAULT '0' --  2.oÍúÔ
   ,iv_output_target IN  VARCHAR2             --  3.oÍÎÛ
   ,iv_sales_staff_1 IN  VARCHAR2             --  4.cÆõ1
   ,iv_sales_staff_2 IN  VARCHAR2             --  5.cÆõ2
   ,iv_sales_staff_3 IN  VARCHAR2             --  6.cÆõ3
   ,iv_sales_staff_4 IN  VARCHAR2             --  7.cÆõ4
   ,iv_sales_staff_5 IN  VARCHAR2             --  8.cÆõ5
   ,iv_sales_staff_6 IN  VARCHAR2             --  9.cÆõ6
   ,iv_customer_1    IN  VARCHAR2             -- 10.Úq1
   ,iv_customer_2    IN  VARCHAR2             -- 11.Úq2
   ,iv_customer_3    IN  VARCHAR2             -- 12.Úq3
   ,iv_customer_4    IN  VARCHAR2             -- 13.Úq4
   ,iv_customer_5    IN  VARCHAR2             -- 14.Úq5
   ,iv_customer_6    IN  VARCHAR2             -- 15.Úq6
   ,iv_customer_7    IN  VARCHAR2             -- 16.Úq7
   ,iv_customer_8    IN  VARCHAR2             -- 17.Úq8
   ,iv_customer_9    IN  VARCHAR2             -- 18.Úq9
   ,iv_customer_10   IN  VARCHAR2             -- 19.Úq10
   ,iv_customer_11   IN  VARCHAR2             -- 20.Úq11
   ,iv_customer_12   IN  VARCHAR2             -- 21.Úq12
  );
END XXCOI004A04R;
/
