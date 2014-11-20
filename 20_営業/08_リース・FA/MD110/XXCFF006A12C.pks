CREATE OR REPLACE PACKAGE XXCFF006A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF006A12C(spec)
 * Description      : リース契約情報連携
 * MD.050           : リース契約情報連携 MD050_CFF_006_A12
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 リース契約情報CSVファイル作成
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/22    1.0   SCS奥河          main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT   VARCHAR2,        --   エラーメッセージ #固定#
    retcode               OUT   VARCHAR2,        --   エラーコード     #固定#
    iv_object_code_from   IN    VARCHAR2,        -- 1.物件コード(FROM)
    iv_object_code_to     IN    VARCHAR2         -- 2.物件コード(TO)
  );
--
END XXCFF006A12C;
/
