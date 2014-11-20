CREATE OR REPLACE PACKAGE APPS.XXCOS010A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS010A06C(spec)
 * Description      : 受注インポートエラー検知
 * MD.050           : MD050_COS_010_A06_受注インポートエラー検知
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/07/06    1.0   K.Satomura       新規作成
 *  2009/11/10    1.1   M.Sano           [E_T4_00173]不要な結合テーブルの削除・ヒント句追加
 *****************************************************************************************/
  --
  --実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf               OUT NOCOPY VARCHAR2 -- エラーメッセージ #固定#
    ,retcode              OUT NOCOPY VARCHAR2 -- エラーコード     #固定#
    ,iv_order_source_name IN         VARCHAR2 -- 受注ソース名称
  );
  --
END XXCOS010A06C;
/
