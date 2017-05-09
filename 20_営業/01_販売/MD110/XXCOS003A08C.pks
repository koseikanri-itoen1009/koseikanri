CREATE OR REPLACE PACKAGE APPS.XXCOS003A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOS003A08C (spec)
 * Description      : CSVデータアップロード（特売価格表）
 * MD.050           : CSVデータアップロード（特売価格表） MD050_COS_003_A08
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
 *  2017/03/02    1.0   S.Yamashita      新規作成
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2, -- エラーメッセージ #固定#
    retcode           OUT NOCOPY VARCHAR2, -- エラーコード     #固定#
    in_get_file_id    IN  NUMBER,   -- 1.<file_id>
    iv_get_format_pat IN  VARCHAR2  -- 2.<フォーマットパターン>
  );
--
END XXCOS003A08C;
/
