CREATE OR REPLACE PACKAGE APPS.XXCFO010A05C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 * 
 * Package Name    : XXCFO010A05C
 * Description     : EBS仕訳抽出
 * MD.050          : T_MD050_CFO_010_A05_EBS仕訳抽出_EBSコンカレント
 * Version         : 1.0
 * 
 * Program List
 * -------------------- -----------------------------------------------------
 *  Name                Description
 * -------------------- -----------------------------------------------------
 *  main                コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2023-01-11    1.0   T.Okuyama     初回作成
 ************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf                  OUT    VARCHAR2         -- エラーメッセージ # 固定 #
    , retcode                 OUT    VARCHAR2         -- エラーコード     # 固定 #
    , iv_execute_kbn          IN     VARCHAR2         -- 実行区分 夜間:'N'、定時:'D'
    , in_set_of_books_id      IN     NUMBER           -- 帳簿ID
    , iv_je_source_name       IN     VARCHAR2         -- 仕訳ソース
    , iv_je_category_name     IN     VARCHAR2         -- 仕訳カテゴリ
  );
END XXCFO010A05C;
/
