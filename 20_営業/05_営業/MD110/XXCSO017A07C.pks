CREATE OR REPLACE PACKAGE XXCSO017A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO017A07C(spec)
 * Description      : 見積書アップロード
 * MD.050           : 見積書アップロード MD050_CSO_017_A07
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
 *  2012/01/26    1.0   Y.Horikawa       main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_file_id    IN     VARCHAR2,         -- 1.ファイルID
    iv_fmt_ptn    IN     VARCHAR2          -- 2.フォーマットパターン
  );
END XXCSO017A07C;
/
