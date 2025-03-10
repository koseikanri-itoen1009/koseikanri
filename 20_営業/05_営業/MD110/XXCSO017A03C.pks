CREATE OR REPLACE PACKAGE APPS.XXCSO017A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO017A03C(spec)
 * Description      : 販売先用見積入力画面から、見積番号、版毎に見積書を
 *                    帳票に出力します。
 * MD.050           : MD050_CSO_017_A03_見積書（販売先用）PDF出力
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
 *  2009-01-06    1.0   Kazuyo.Hosoi     新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   エラーメッセージ #固定#
   ,retcode       OUT NOCOPY VARCHAR2          --   エラーコード     #固定#
   ,in_qt_hdr_id  IN  NUMBER                   --   見積ヘッダーID
  );
END XXCSO017A03C;
/
