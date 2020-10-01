CREATE OR REPLACE PACKAGE APPS.XXCOK024A28C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A28C (spec)
 * Description      : 控除データ用実績振替(EDI)作成
 * MD.050           : 控除データ用実績振替(EDI)作成 MD050_COK_024_A28
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
 *  2020/06/05    1.0   N.Koyama         新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode                         OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_proc_kind                    IN     VARCHAR2,         --   処理区分
    iv_from_date                    IN     VARCHAR2,         --   処理日付From
    iv_to_date                      IN     VARCHAR2          --   処理日付To
  );
END XXCOK024A28C;
/
