CREATE OR REPLACE PACKAGE APPS.XXCCP003A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCCP003A01C(spec)
 * Description      : 問屋未払データ出力
 * MD.070           : 問屋未払データ出力 (MD070_IPO_CCP_003_A01)
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
 *  2015/09/08     1.0  S.Yamashita      [E_本稼動_11083]新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT    VARCHAR2      --   エラーメッセージ #固定#
   ,retcode               OUT    VARCHAR2      --   エラーコード     #固定#
   ,iv_payment_date_from  IN     VARCHAR2      --   1.支払予定日FROM
   ,iv_payment_date_to    IN     VARCHAR2      --   2.支払予定日TO
  );
END XXCCP003A01C;
/
