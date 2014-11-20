CREATE OR REPLACE PACKAGE XXCOP004A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP004A01C(spec)
 * Description      : アップロードファイルからの登録(リーフ便）
 * MD.050           : アップロードファイルからの登録(リーフ便） MD050_COP_004_A01
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
 *  2008/11/05    1.00  SCS.Tsubomatsu   main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf            OUT VARCHAR2,           --   エラー・メッセージ  --# 固定 #
    retcode           OUT VARCHAR2,           --   リターン・コード    --# 固定 #
    in_file_id        IN  VARCHAR2,           --   FILE_ID
    in_format_pattern IN  VARCHAR2            --   フォーマット・パターン
  );

END XXCOP004A01C;
/
