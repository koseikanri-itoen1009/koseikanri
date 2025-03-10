CREATE OR REPLACE PACKAGE XXCOK014A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A03C(spec)
 * Description      : 販手残高計算処理
 * MD.050           : 販売手数料（自販機）の支払予定額（未払残高）を計算 MD050_COK_014_A03
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
 *  2009/01/13    1.0   A.Yano           新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf          OUT    VARCHAR2         -- エラーメッセージ
    ,retcode         OUT    VARCHAR2         -- エラーコード
    ,iv_process_date IN     VARCHAR2         -- 業務処理日付
  );
END XXCOK014A03C;
/
