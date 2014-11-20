create or replace
PACKAGE XXCFF003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF003A05C(spec)
 * Description      : 支払計画作成
 * MD.050           : MD050_CFF_003_A05_支払計画作成.doc
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
 *  2008-12-03    1.0   SCS礒崎祐次       新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    iv_shori_type              IN VARCHAR2            -- 1.処理区分
   ,in_contract_line_id        IN NUMBER              -- 2.契約明細内部ID  
   ,ov_errbuf                  OUT NOCOPY VARCHAR2    -- エラー・メッセージ
   ,ov_retcode                 OUT NOCOPY VARCHAR2    -- リターン・コード
   ,ov_errmsg                  OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ
  );
END XXCFF003A05C;
/