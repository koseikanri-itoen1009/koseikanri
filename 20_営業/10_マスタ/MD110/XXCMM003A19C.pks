CREATE OR REPLACE PACKAGE XXCMM003A19C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A19C(spec)
 * Description      : HHT連携IFデータ作成
 * MD.050           : MD050_CMM_003_A19_HHT系連携IFデータ作成
 * Version          : 1.1
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
 *  2009-02-18    1.0   Takuya.Kaihara   新規作成
 *  2009/03/09    1.1   Takuya Kaihara   プロファイル値共通化
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ（HHT系連携IFデータ作成）
  PROCEDURE main(
    errbuf                    OUT    VARCHAR2,     --エラーメッセージ #固定#
    retcode                   OUT    VARCHAR2,     --エラーコード     #固定#
    iv_proc_date_from         IN     VARCHAR2,     --最終更新日（開始）
    iv_proc_date_to           IN     VARCHAR2      --最終更新日（終了）
  );
END XXCMM003A19C;
/
