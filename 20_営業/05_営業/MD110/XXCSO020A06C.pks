CREATE OR REPLACE PACKAGE APPS.XXCSO020A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO020A06C(spec)
 * Description      : EBS(ファイルアップロードI/F)に取込まれたSP専決WF承認組織
 *                    マスタデータをWF承認組織マスタテーブルに取込みます。
 *                    
 * MD.050           : MD050_CSO_020_A06_SP-WF承認組織マスタ情報一括取込
 *                    
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
 *  2008-01-06    1.0   Maruyama.Mio     新規作成
 *  2008-01-30    1.0   Maruyama.Mio     INパラメータファイルID変数名変更(記述ルール参考)
 *  2008-02-25    1.1   Maruyama.Mio     【障害対応028】有効期間重複チェック不具合対応
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf               OUT NOCOPY VARCHAR2          -- エラーメッセージ #固定#
   ,retcode              OUT NOCOPY VARCHAR2          -- エラーコード     #固定#
   ,in_file_id           IN         NUMBER            -- ファイルID
   ,iv_fmt_ptn           IN         VARCHAR2          -- フォーマットパターン
  );
END XXCSO020A06C;
/
