CREATE OR REPLACE PACKAGE APPS.XXCCP003A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : XXCCP003A04C(spec)
 * Description      : 問屋未確定データ出力（収益認識）
 * MD.070           : 問屋未確定データ出力（収益認識） (MD070_IPO_CCP_003_A04)
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
 *  2021/01/05    1.0   SCSK N.Abe       [E_本稼動_11084]新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT    VARCHAR2      --   エラーメッセージ #固定#
   ,retcode               OUT    VARCHAR2      --   エラーコード     #固定#
   ,iv_base_code          IN     VARCHAR2      --   1.拠点
   ,iv_payment_date_from  IN     VARCHAR2      --   2.支払予定日FROM
   ,iv_payment_date_to    IN     VARCHAR2      --   3.支払予定日TO
   ,iv_selling_date_from  IN     VARCHAR2      --   4.売上対象年月FROM
   ,iv_selling_date_to    IN     VARCHAR2      --   5.売上対象年月TO
   ,iv_cust_code          IN     VARCHAR2      --   6.顧客
   ,iv_bill_no            IN     VARCHAR2      --   7.請求書No
   ,iv_supplier_code      IN     VARCHAR2      --   8.仕入先CD
   ,iv_status             IN     VARCHAR2      --   9.ステータス(0:全て,1:未払,2:支払済,3:削除済)
  );
END XXCCP003A04C;
/
