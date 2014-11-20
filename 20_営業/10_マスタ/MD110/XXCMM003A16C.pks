CREATE OR REPLACE PACKAGE XXCMM003A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A16C(spec)
 * Description      : AFF顧客マスタ更新
 * MD.050           : MD050_CMM_003_A16_AFF顧客マスタ更新
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
 *  2009-02-06    1.0   Takuya.Kaihara   新規作成
 *  2009/03/09    1.1   Takuya Kaihara   プロファイル値共通化
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ（AFF顧客マスタ更新）
  PROCEDURE main(
    errbuf                    OUT    VARCHAR2,     --エラーメッセージ #固定#
    retcode                   OUT    VARCHAR2,     --エラーコード     #固定#
    iv_proc_date_from         IN     VARCHAR2,     -- コンカレント・パラメータ処理日(FROM)
    iv_proc_date_to           IN     VARCHAR2      -- コンカレント・パラメータ処理日(TO)
  );
END XXCMM003A16C;
/
