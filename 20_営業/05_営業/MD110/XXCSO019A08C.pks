CREATE OR REPLACE PACKAGE APPS.XXCSO019A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A08C(spec)
 * Description      : 要求の発行画面から、営業員ごとに指定日を含む月の1日～指定日まで
 *                    訪問実績の無い顧客を表示します。
 * MD.050           : MD050_CSO_019_A08_未訪問顧客一覧表
 * Version          : 1.2
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
 *  2009-02-12    1.0   Ryo.Oikawa       新規作成
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *  2017-01-17    1.2   Yasuhiro.Shoji   E_本稼動_13985対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2          --   エラーメッセージ #固定#
   ,retcode       OUT NOCOPY VARCHAR2          --   エラーコード     #固定#
   ,iv_current_date  IN  VARCHAR2              --   基準日
-- Ver1.2 add start
   ,iv_vd_output_div IN  VARCHAR2              --   出力区分
-- Ver1.2 add end
  );
END XXCSO019A08C;
/
