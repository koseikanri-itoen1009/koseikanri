CREATE OR REPLACE PACKAGE APPS.XXCOS005A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOS005A10C (spec)
 * Description      : CSVファイルのEDI受注取込
 * MD.050           : CSVファイルのEDI受注取込 MD050_COS_005_A10_
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
 *  2020/10/26    1.0   N.Koyama         新規作成(E_本稼動_16636)
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT VARCHAR2, -- エラーメッセージ #固定#
    retcode           OUT VARCHAR2, -- エラーコード     #固定#
    in_get_file_id    IN  NUMBER,   -- 1.<file_id>
    iv_get_format_pat IN  VARCHAR2  -- 2.<フォーマットパターン>
  );
--
END XXCOS005A10C;
/
