CREATE OR REPLACE PACKAGE XXCOK024A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A03C_pks(spec)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : アドオン：販売実績・販売控除データの作成 MD050_COK_024_A03
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
 *  2020/01/15    1.0   Y.Koh            新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf  OUT VARCHAR2           -- エラー・メッセージ
  , retcode OUT VARCHAR2           -- エラーコード
  );
END XXCOK024A03C;
/