CREATE OR REPLACE PACKAGE xxinv530003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV530003C (spec)
 * Description      : 棚卸表
 * MD.050/070       : 棚卸Issue1.0 (T_MD050_BPO_530)
                      棚卸表Issue1.0 (T_MD070_BPO_530C)
 * Version          : 1.4
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  main                       帳票実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-03-06    1.0   T.Ikehara        新規作成
 *  2008-05-02    1.1   T.Ikehara        パラメータ：品目コードを品目IDに変更対応
 *  2008-05-02    1.2   T.Ikehara        日付出力形式、倉庫コード条件不具合対応
 *  2008/06/03    1.3   T.Endou          担当部署または担当者名が未取得時は正常終了に修正
 *  2008/06/24    1.4   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *
 *****************************************************************************************/
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    ov_errbuf             OUT     VARCHAR2,   -- エラー・メッセージ
    ov_retcode            OUT     VARCHAR2,   -- リターン・コード
    iv_inventory_time     IN      VARCHAR2,   -- 1.棚卸年月度
    iv_stock_name         IN      VARCHAR2,   -- 2.名義
    iv_report_post        IN      VARCHAR2,   -- 3.報告部署
    iv_warehouse_code     IN      VARCHAR2,   -- 4.倉庫コード
    iv_distribution_block IN      VARCHAR2,   -- 5.ブロック
    iv_item_type          IN      VARCHAR2,   -- 6.品目区分
    iv_item_code          IN      VARCHAR2);  -- 7.品目コード
--
END xxinv530003c;
/
