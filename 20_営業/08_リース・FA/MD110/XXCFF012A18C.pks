CREATE OR REPLACE PACKAGE XXCFF012A18C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF012A18C(spec)
 * Description      : リース債務残高レポート
 * MD.050           : リース債務残高レポート MD050_CFF_012_A18
 * Version          : 1.2
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
 *  2009/01/19    1.0   SCS山岸          main新規作成
 *  2018/03/27    1.2   SCSK森           E_本稼動_14830（パラメータ追加)
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT VARCHAR2,      --   エラーメッセージ #固定#
    retcode              OUT VARCHAR2,      --   エラーコード     #固定#
    iv_period_name       IN  VARCHAR2       -- 1.会計期間名
-- 2018/03/27 1.8 H.Mori ADD START
   ,iv_book_type_code    IN  VARCHAR2       -- 2.資産台帳名
-- 2018/03/27 1.8 H.Mori ADD END
  );
END XXCFF012A18C;
/
