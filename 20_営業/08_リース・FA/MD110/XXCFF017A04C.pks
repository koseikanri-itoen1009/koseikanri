create or replace
PACKAGE XXCFF017A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A04C(spec)
 * Description      : 自販機物件情報アップロード
 * MD.050           : MD050_CFF_017_A04_自販機物件情報アップロード
 * Version          : 1.00
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
 *  2014/06/13    1.00  SCSK 山下         新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   エラーメッセージ #固定#
    retcode          OUT   VARCHAR2,        --   エラーコード     #固定#
    in_file_id       IN    NUMBER,          --   1.ファイルID(必須)
    iv_file_format   IN    VARCHAR2         --   2.ファイルフォーマット(必須)
  );
END XXCFF017A04C;
/
