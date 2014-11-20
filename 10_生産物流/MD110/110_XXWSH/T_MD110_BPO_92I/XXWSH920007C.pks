CREATE OR REPLACE PACKAGE XXWSH920007C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920007C(spec)
 * Description      : 生産物流(引当、配車)
 * MD.050           : 出荷・引当/配車：生産物流共通（出荷・移動仮引当） T_MD050_BPO_920
 * MD.070           : 出荷・引当/配車：生産物流共通（出荷・移動仮引当） T_MD070_BPO92I
 * Version          : 1.15
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
 *  2008/11/20   1.0   SCS 北寒寺        新規作成
 *  2008/12/01   1.2   SCS 宮田          ロック対応
 *  2008/12/20   1.3   SCS 北寒寺        本番障害#738
 *  2009/01/19   1.4   SCS 野村          本番障害#1038
 *  2009/01/27   1.5   SCS 二瓶          本番障害#332対応（条件：出庫元不備対応）
 *  2009/01/28   1.6   SCS 伊藤          本番障害#1028対応（パラメータに指示部署追加）
 *  2009/02/03   1.8   SCS 二瓶          本番障害#949対応（トレース取得用処理削除）
 *  2009/02/18   1.9   SCS 野村          本番障害#1176対応
 *  2009/02/19   1.10  SCS 野村          本番障害#1176対応（追加修正）
 *  2009/04/03   1.11  SCS 野村          本番障害#1367（1321）調査用対応
 *  2009/04/17   1.12  SCS 野村          本番障害#1367（1321）リトライ対応
 *  2009/05/01   1.13  SCS 野村          本番障害#1367（1321）子除外対応
 *  2009/05/19   1.14  SCS 伊藤          本番障害#1447対応
 *  2009/12/29   1.15  SCS 北寒寺        本番稼働障害#701対応 品目0005000はプロト版を
 *                                       実行するように修正
 *
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
-- 2009/01/28 H.Itou Add Start 本番障害#1028対応
   , iv_instruction_dept   IN           VARCHAR2         -- 指示部署
-- 2009/01/28 H.Itou Add End
-- 2009/05/19 H.Itou Add Start 本番障害#1447対応
   , iv_item_code          IN           VARCHAR2         -- 品目コード
-- 2009/05/19 H.Itou Add End
  );
END XXWSH920007C;
/
