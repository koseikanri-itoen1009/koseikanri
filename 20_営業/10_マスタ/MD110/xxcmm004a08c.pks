CREATE OR REPLACE PACKAGE xxcmm004a08c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A08C(spec)
 * Description      : EBS(ファイルアップロードIF)に取込まれた標準原価データを
 *                  : OPM標準原価テーブルに反映します。
 * MD.050           : 標準原価一括改定    MD050_CMM_004_A08
 * Version          : Draft2B
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
 *  2008/12/19    1.0   H.Yoshikawa      main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT      VARCHAR2                                        -- エラー・メッセージ
   ,retcode           OUT      VARCHAR2                                        -- リターン・コード
   ,iv_file_id        IN       VARCHAR2                                        -- ファイルID
   ,iv_format         IN       VARCHAR2                                        -- フォーマットパターン
  );
END xxcmm004a08c;
/
