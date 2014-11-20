CREATE OR REPLACE PACKAGE XXWSH920008C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920008C(spec)
 * Description      : 生産物流(引当、配車)
 * MD.050           : 出荷・引当/配車：生産物流共通（出荷・移動仮引当） T_MD050_BPO_920
 * MD.070           : 出荷・引当/配車：生産物流共通（出荷・移動仮引当） T_MD070_BPO92J
 * Version          : 1.3
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
 *  2008/11/20   1.0  Oracle 北寒寺正夫   新規作成
 *  2008/11/28   1.1   Oracle 北寒寺正夫 本番障害246対応
 *  2008/11/29   1.2   SCS宮田           ロック対応
 *  2008/12/02   1.3   SCS二瓶           本番障害#251対応（条件追加) 
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf                OUT NOCOPY   VARCHAR2         -- エラーメッセージ #固定#
   , retcode               OUT NOCOPY   VARCHAR2         -- エラーコード     #固定#
   , iv_item_class         IN           VARCHAR2         -- 商品区分
   , iv_action_type        IN           VARCHAR2         -- 処理種別
   , iv_block1             IN           VARCHAR2         -- ブロック１
   , iv_block2             IN           VARCHAR2         -- ブロック２
   , iv_block3             IN           VARCHAR2         -- ブロック３
   , iv_deliver_from_id    IN           VARCHAR2         -- 出庫元
   , iv_deliver_type       IN           VARCHAR2         -- 出庫形態
   , iv_deliver_date_from  IN           VARCHAR2         -- 出庫日From
   , iv_deliver_date_to    IN           VARCHAR2         -- 出庫日To
   , iv_item_code          IN           VARCHAR2         -- 親品目コード
     );
--
END XXWSH920008C;
/
