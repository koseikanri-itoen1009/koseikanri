CREATE OR REPLACE PACKAGE xxwsh920002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH920002C(spec)
 * Description      : 引当解除処理
 * MD.050/070       : 生産物流共通（出荷・移動仮引当）(T_MD050_BPO_920)
 *                    引当解除処理                    (T_MD070_BPO_92D)
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
 *  2008/04/18    1.0   Tatsuya Kurata    main新規作成
 *  2008/06/03    1.1   Masao Hokkanji    結合テスト不具合対応
 *  2008/06/12    1.2   Masao Hokkanji    T_TE080_BPO920不具合ログNo24対応
 *  2008/06/13    1.3   Masao Hokkanji    抽出条件変更対応
 *  2008/12/01    1.4   SCS Miyata        ロック対応
 *  2009/01/27    1.5   SCS Itou          本番障害#1028対応
 *  2009/05/01    1.6   SCS Itou          本番障害#1447対応
 *  2009/12/10    1.7   SCS Itou          本稼動障害#383対応
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         --   エラーメッセージ
     ,retcode               OUT    VARCHAR2         --   エラーコード
     ,iv_item_class         IN     VARCHAR2         -- 1.商品区分
     ,iv_action_type        IN     VARCHAR2         -- 2.処理種別
     ,iv_block1             IN     VARCHAR2         -- 3.ブロック１
     ,iv_block2             IN     VARCHAR2         -- 4.ブロック２
     ,iv_block3             IN     VARCHAR2         -- 5.ブロック３
     ,iv_deliver_from_id    IN     VARCHAR2         -- 6.出庫元
     ,iv_deliver_type       IN     VARCHAR2         -- 7.出庫形態
     ,iv_deliver_date_from  IN     VARCHAR2         -- 8.出庫日From
     ,iv_deliver_date_to    IN     VARCHAR2         -- 9.出庫日To
-- 2009/01/27 H.Itou Add Start 本番障害#1028対応
     ,iv_instruction_dept   IN     VARCHAR2         -- 10.指示部署
-- 2009/01/27 H.Itou Add End
-- 2009/05/01 H.Itou Add Start 本番障害#1447対応
     ,iv_item_code          IN     VARCHAR2         -- 11.品目コード
-- 2009/05/01 H.Itou Add End
    );
END xxwsh920002c;
/
