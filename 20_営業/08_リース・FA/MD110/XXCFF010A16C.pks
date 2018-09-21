CREATE OR REPLACE PACKAGE XXCFF010A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF010A16(spec)
 * Description      : リース仕訳作成
 * MD.050           : MD050_CFF_010_A16_リース仕訳作成
 * Version          : 1.12
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
 *  2009/01/05    1.00  SCS渡辺学        新規作成
 *  2018/09/07    1.12  SCSK小路恭弘     [E_本稼動_14830]IFRSリース追加対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf         OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode        OUT    VARCHAR2,         --   エラーコード     #固定#
-- 2018/09/07 Ver.1.12 Y.Shoji MOD Start
--    iv_period_name IN     VARCHAR2          -- 1.会計期間名
    iv_period_name    IN     VARCHAR2,      -- 1.会計期間名
    iv_book_type_code IN     VARCHAR2       -- 2.台帳名
-- 2018/09/07 Ver.1.12 Y.Shoji MOD End
  );
END XXCFF010A16C;
/
