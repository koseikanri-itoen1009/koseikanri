CREATE OR REPLACE PACKAGE APPS.XXCSO014A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A06C(spec)
 * Description      : 営業員管理ファイルをHHTに送信するための 
 *                    CSVファイルを作成します。
 * MD.050           : MD050_CSO_014_A06_HHT-EBSインターフェース：
 *                     (OUT)営業員管理ファイル_Draft2.0B.doc
 * Version          : 1.0
 *
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
 *  2008-11-28    1.0   Seirin.Kin        新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   エラーメッセージ #固定#
   ,retcode       OUT NOCOPY VARCHAR2          --   エラーコード     #固定#
  );
END XXCSO014A06C;
/
