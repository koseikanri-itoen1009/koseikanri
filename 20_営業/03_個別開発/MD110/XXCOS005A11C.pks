CREATE OR REPLACE PACKAGE APPS.XXCOS005A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOS005A11C (spec)
 * Description      : CSVデータアップロード（価格表）
 * MD.050           : CSVデータアップロード（価格表） MD050_COS_005_A11
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
 *  2022/08/30    1.0   R.Oikawa      新規作成
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
END XXCOS005A11C;
/
