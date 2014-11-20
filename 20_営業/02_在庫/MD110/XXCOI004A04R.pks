CREATE OR REPLACE PACKAGE XXCOI004A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI004A04R(spec)
 * Description      : VD機内在庫表
 * MD.050           : MD050_COI_004_A04
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   H.Wada           新規作成
 *
 *****************************************************************************************/
  PROCEDURE main(
    errbuf           OUT VARCHAR2             --   エラー・メッセージ
   ,retcode          OUT VARCHAR2             --   リターン・コード
   ,iv_output_base   IN  VARCHAR2             --  1.出力拠点
   ,iv_output_period IN  VARCHAR2 DEFAULT '0' --  2.出力期間
   ,iv_output_target IN  VARCHAR2             --  3.出力対象
   ,iv_sales_staff_1 IN  VARCHAR2             --  4.営業員1
   ,iv_sales_staff_2 IN  VARCHAR2             --  5.営業員2
   ,iv_sales_staff_3 IN  VARCHAR2             --  6.営業員3
   ,iv_sales_staff_4 IN  VARCHAR2             --  7.営業員4
   ,iv_sales_staff_5 IN  VARCHAR2             --  8.営業員5
   ,iv_sales_staff_6 IN  VARCHAR2             --  9.営業員6
   ,iv_customer_1    IN  VARCHAR2             -- 10.顧客1
   ,iv_customer_2    IN  VARCHAR2             -- 11.顧客2
   ,iv_customer_3    IN  VARCHAR2             -- 12.顧客3
   ,iv_customer_4    IN  VARCHAR2             -- 13.顧客4
   ,iv_customer_5    IN  VARCHAR2             -- 14.顧客5
   ,iv_customer_6    IN  VARCHAR2             -- 15.顧客6
   ,iv_customer_7    IN  VARCHAR2             -- 16.顧客7
   ,iv_customer_8    IN  VARCHAR2             -- 17.顧客8
   ,iv_customer_9    IN  VARCHAR2             -- 18.顧客9
   ,iv_customer_10   IN  VARCHAR2             -- 19.顧客10
   ,iv_customer_11   IN  VARCHAR2             -- 20.顧客11
   ,iv_customer_12   IN  VARCHAR2             -- 21.顧客12
  );
END XXCOI004A04R;
/
