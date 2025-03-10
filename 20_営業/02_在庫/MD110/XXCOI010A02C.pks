CREATE OR REPLACE PACKAGE XXCOI010A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI010A02C(spec)
 * Description      : 気づき情報IF出力
 * MD.050           : 気づき情報IF出力 MD050_COI_010_A02
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
 *  2008/12/26    1.0   T.Nakamura       新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf        OUT    VARCHAR2          --   エラーメッセージ #固定#
    , retcode       OUT    VARCHAR2          --   エラーコード     #固定#
  );
END XXCOI010A02C;
/
