CREATE OR REPLACE PACKAGE APPS.XXCOK024A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A08C (spec)
 * Description      : 販売控除データCSV出力
 * MD.050           : 販売控除データCSV出力 MD050_COS_024_A08
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
 *  2019/09/20    1.0   H.Ishii          main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2     -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2     -- エラーコード     #固定#
   ,iv_customer_code                IN     VARCHAR2     -- 顧客番号
   ,iv_order_list_date_from         IN     VARCHAR2     -- 出力日(FROM)
   ,iv_order_list_date_to           IN     VARCHAR2     -- 出力日(TO)
  );
END XXCOK024A08C;
/
