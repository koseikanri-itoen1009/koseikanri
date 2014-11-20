CREATE OR REPLACE PACKAGE XXCOK008A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK008A05R(spec)
 * Description      : 要求の発行画面から、売上振替割合チェックリストを帳票に出力します。
 * MD.050           : 売上振替割合チェックリスト MD050_COK_008_A05
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
 *  2008/10/23    1.0   T.Abe            新規作成
 *  2009/03/25    1.1   S.Kayahara       最終行にスラッシュ追加
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                    OUT VARCHAR2         -- エラーメッセージ
   ,retcode                   OUT VARCHAR2         -- エラーコード
   ,iv_selling_from_base_code IN  VARCHAR2         -- 売上振替元拠点コード
   ,iv_selling_from_cust_code IN  VARCHAR2         -- 売上振替元顧客コード
   ,iv_selling_to_base_code   IN  VARCHAR2         -- 売上振替先拠点コード
  );
END XXCOK008A05R;
/
