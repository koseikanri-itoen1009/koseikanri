CREATE OR REPLACE PACKAGE xxinv530002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv530002c(spec)
 * Description      : HHT棚卸データIFプログラム
 * MD.050           : 棚卸 T_MD050_BPO_530
 * MD.070           : HHT棚卸データIFプログラム(53B) T_MD070_BPO_53B
 * Version          : 1.7
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
 *  2008/03/06    1.0   T.Endou          main 新規作成
 *  2008/12/06    1.5   T.Miyata         修正(本番障害#510対応：日付は変換して比較)
 *  2009/02/09    1.6   A.Shiina         修正(本番障害#1117対応：在庫クローズチェック追加)
 *  2009/02/09    1.7   A.Shiina         修正(本番障害#1129対応：パラメータ追加)
 *
 *****************************************************************************************/
--
  -- 2008/12/06 Add Start T.Miyata 本番障害#510対応
  FUNCTION fnc_check_date(
    iv_date IN VARCHAR2
    ) RETURN VARCHAR2;
  -- 2008/12/06 Add End T.Miyata 本番障害#510対応
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         --   エラーメッセージ
-- 2009/02/09 v1.7 UPDATE START
--     ,retcode               OUT    VARCHAR2);       --   エラーコード
     ,retcode               OUT    VARCHAR2       --   エラーコード
     ,iv_report_post_code   IN     VARCHAR2    -- 報告部署
     ,iv_whse_code          IN     VARCHAR2    -- 倉庫コード
     ,iv_item_type          IN     VARCHAR2    -- 品目区分
     );
-- 2009/02/09 v1.7 UPDATE END
--
END xxinv530002c;
/
