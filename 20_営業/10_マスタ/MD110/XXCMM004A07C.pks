CREATE OR REPLACE PACKAGE      XXCMM004A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A07C(spec)
 * Description      : EBS(ファイルアップロードIF)に取込まれた営業原価データを
 *                  : Disc品目変更履歴テーブル(アドオン)に取込みます。
 * MD.050           : 営業原価一括改定    MD050_CMM_004_A07
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
 *  2008/12/17    1.0   H.Yoshikawa      main新規作成
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
END XXCMM004A07C;
/
