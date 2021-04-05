CREATE OR REPLACE PACKAGE XXCMM004A15C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A15C(spec)
 * Description      : CSV形式のデータファイルから、Disc品目アドオンの更新を行います。
 * MD.050           : 品目一括更新 CMM_004_A15
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
 *  2021/03/12    1.0   H.Futamura       新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2       --   エラーメッセージ #固定#
   ,retcode       OUT    VARCHAR2       --   エラーコード     #固定#
   ,iv_file_id    IN     VARCHAR2       --   ファイルID
   ,iv_format     IN     VARCHAR2       --   フォーマット
  );
END XXCMM004A15C;
/
