create or replace
PACKAGE XXCFF013A19C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF013A19C(spec)
 * Description      : リース契約月次更新
 * MD.050           : MD050_CFF_013_A19_リース契約月次更新
 * Version          : 1.6
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
 *  2008/12/12    1.0   SCS 嶋田         新規作成
 *  2018/09/07    1.6   SCSK 小路        [E_本稼動_14830]IFRS追加対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   エラーメッセージ #固定#
    retcode          OUT   VARCHAR2,        --   エラーコード     #固定#
-- 2018/09/07 Ver.1.6 Y.Shoji MOD Start
--    iv_period_name   IN    VARCHAR2         -- 1.会計期間名
    iv_period_name    IN   VARCHAR2,        -- 1.会計期間名
    iv_book_type_code IN   VARCHAR2         -- 2.台帳名
-- 2018/09/07 Ver.1.6 Y.Shoji MOD End
  );
END XXCFF013A19C;
/
