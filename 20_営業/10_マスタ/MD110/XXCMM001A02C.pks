CREATE OR REPLACE PACKAGE APPS.XXCMM001A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCMM001A02C(spec)
 * Description      : 仕入先マスタIF抽出_EBSコンカレント
 * MD.050           : T_MD050_CMM_001_A02_仕入先マスタIF抽出_EBSコンカレント
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
 *  2022-11-02    1.0   Y.Ooyama         新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2          --   エラーコード     #固定#
  );
END XXCMM001A02C;
/
