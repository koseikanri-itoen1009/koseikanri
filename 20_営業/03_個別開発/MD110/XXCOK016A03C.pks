CREATE OR REPLACE PACKAGE XXCOK016A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : XXCOK016A03C(spec)
 * Description      : EDIシステムにてインフォマート社へ送信するワークデータ作成
 * MD.050           : インフォマート用赤黒情報作成 MD050_COK_016_A03
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
 *  2021/12/21    1.0   H.Futamura       新規作成 E_本稼動_17680 インフォマートの電子帳簿保存法対応
 *
 *****************************************************************************************/
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf          OUT VARCHAR2
   ,retcode         OUT VARCHAR2
   ,iv_proc_div     IN  VARCHAR2          -- 1.処理タイミング
  );
END XXCOK016A03C;
/
