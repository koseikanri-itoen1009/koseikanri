CREATE OR REPLACE PACKAGE XXWSH920009C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920009C(spec)
 * Description      : 引当解除処理ロック対応
 * MD.050           : 
 * MD.070           : 
 * Version          : 1.2
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 メイン関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01   1.0   T.MIYATA         初回作成
 *  2009/01/19   1.1   M.Nomura         本番#1038対応
 *  2009/01/27   1.2   H.Itou           本番#1028対応
 *****************************************************************************************/
--
  -- メイン関数
  PROCEDURE main(
      errbuf                OUT NOCOPY  VARCHAR2         --   エラーメッセージ
     ,retcode               OUT NOCOPY   VARCHAR2         --   エラーコード
     ,iv_item_class         IN     VARCHAR2         -- 1.商品区分
     ,iv_action_type        IN     VARCHAR2         -- 2.処理種別
     ,iv_block1             IN     VARCHAR2         -- 3.ブロック１
     ,iv_block2             IN     VARCHAR2         -- 4.ブロック２
     ,iv_block3             IN     VARCHAR2         -- 5.ブロック３
     ,iv_deliver_from_id    IN     VARCHAR2         -- 6.出庫元
     ,iv_deliver_type       IN     VARCHAR2         -- 7.出庫形態
     ,iv_deliver_date_from  IN     VARCHAR2         -- 8.出庫日From
     ,iv_deliver_date_to    IN     VARCHAR2         -- 9.出庫日To
-- ##### 20090127 Ver.1.2 本番#1038対応 START #####
     ,iv_instruction_dept   IN     VARCHAR2         -- 10.指示部署
-- ##### 20090127 Ver.1.2 本番#1038対応 END   #####
    );
END XXWSH920009C;
/
