CREATE OR REPLACE PACKAGE XXWSH920001C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920001C(spec)
 * Description      : 生産物流(引当、配車)
 * MD.050           : 出荷・引当/配車：生産物流共通（出荷・移動仮引当） T_MD050_BPO_920
 * MD.070           : 出荷・引当/配車：生産物流共通（出荷・移動仮引当） T_MD070_BPO92A
 * Version          : 1.6
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 * main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/12   1.0   Oracle 土田 茂   初回作成
 *  2008/04/23   1.1   Oracle 土田 茂   内部変更要求63,65対応
 *  2008/05/30   1.2   Oracle 北寒寺 正夫 結合テスト不具合対応
 *  2008/05/31   1.3   Oracle 北寒寺 正夫 結合テスト不具合対応
 *  2008/06/02   1.4   Oracle 北寒寺 正夫 結合テスト不具合対応
 *  2008/06/05   1.5   Oracle 北寒寺 正夫 結合テスト不具合対応
 *  2008/06/12   1.6   Oracle 北寒寺 正夫 結合テスト不具合対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT NOCOPY   VARCHAR2,         -- エラーメッセージ #固定#
    retcode               OUT NOCOPY   VARCHAR2,         -- エラーコード     #固定#
    iv_item_class         IN           VARCHAR2,         -- 商品区分
    iv_action_type        IN           VARCHAR2,         -- 処理種別
    iv_block1             IN           VARCHAR2,         -- ブロック１
    iv_block2             IN           VARCHAR2,         -- ブロック２
    iv_block3             IN           VARCHAR2,         -- ブロック３
    iv_deliver_from_id    IN           VARCHAR2,           -- 出庫元
    iv_deliver_type       IN           VARCHAR2,           -- 出庫形態
    iv_deliver_date_from  IN           VARCHAR2,         -- 出庫日From
    iv_deliver_date_to    IN           VARCHAR2          -- 出庫日To
  );
END XXWSH920001C;
/
