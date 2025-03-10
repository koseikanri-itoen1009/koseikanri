CREATE OR REPLACE PACKAGE XXCCP002A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCCP002A01C(spec)
 * Description      : 棚卸商品データCSVダウンロード
 * MD.070           : 棚卸商品データCSVダウンロード (MD070_IPO_CCP_002_A01)
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
 *  2016/11/04    1.0   H.Sakihama      [E_本稼動_13895]新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT    VARCHAR2      --   エラーメッセージ #固定#
   ,retcode               OUT    VARCHAR2      --   エラーコード     #固定#
   ,iv_practice_month     IN     VARCHAR2      --   年月
  );
END XXCCP002A01C;
/
