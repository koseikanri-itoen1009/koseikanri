CREATE OR REPLACE PACKAGE APPS.XXCSO019A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A05C(spec)
 * Description      : 要求の発行画面から、訪問売上計画管理表を帳票に出力します。
 * MD.050           : MD050_CSO_019_A05_訪問売上計画管理表_Draft2.0A
 * Version          : 1.0
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  
 * submain              
 * main                  コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-05    1.0   Seirin.Kin        新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
 --
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2          -- エラーメッセージ #固定#
   ,retcode           OUT NOCOPY VARCHAR2          -- エラーコード     #固定#
   ,iv_year_month     IN         VARCHAR2          -- 基準年月
   ,iv_report_type    IN         VARCHAR2          -- 帳票種別
   ,iv_base_code      IN         VARCHAR2          -- 拠点コード
  );
END XXCSO019A05C;
/
