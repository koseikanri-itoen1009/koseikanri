CREATE OR REPLACE PACKAGE APPS.XXCFO010A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFO010A06C(spec)
 * Description      : GLOIF仕訳の転送抽出
 * MD.050           : T_MD050_CFO_010_A06_GLOIF仕訳の転送抽出_EBSコンカレント
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
 *  2022-12-09    1.0   K.Tomie          新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf              OUT VARCHAR2    -- エラーメッセージ # 固定 #
    , retcode             OUT VARCHAR2    -- エラーコード     # 固定 #
    , iv_execute_kbn      IN  VARCHAR2    -- 実行区分
    , in_set_of_books_id  IN  NUMBER      -- 帳簿ID
    , iv_je_source_name   IN  VARCHAR2    -- 仕訳ソース
    , iv_je_category_name IN  VARCHAR2    -- 仕訳カテゴリ
  );
END XXCFO010A06C;
/