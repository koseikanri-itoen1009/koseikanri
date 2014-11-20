CREATE OR REPLACE PACKAGE xxwsh620001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620001c(spec)
 * Description      : 在庫不足確認リスト
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_620
 * MD.070           : 在庫不足確認リスト T_MD070_BPO_62B
 * Version          : 1.7
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -----------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -----------------------------------------------
 *  2008/05/05    1.0   Nozomi Kashiwagi   新規作成
 *  2008/07/08    1.1   Akiyoshi Shiina    禁則文字「'」「"」「<」「>」「＆」対応
 *  2008/09/26    1.2   Hitomi Itou        T_TE080_BPO_600 指摘38
 *                                         T_TE080_BPO_600 指摘37
 *                                         T_S_533(PT対応)
 *  2008/10/03    1.3   Hitomi Itou        T_TE080_BPO_600 指摘37 在庫不足の場合、依頼数には不足数を表示する
 *  2008/11/13    1.4   Tsuyoki Yoshimoto  内部変更#168
 *  2008/12/10    1.5   T.Miyata           本番#637 パフォーマンス対応
 *  2008/12/10    1.6   Hitomi Itou        本番障害#650
 *  2009/01/07    1.7   Akiyoshi Shiina    本番障害#873
 *****************************************************************************************/
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1)
                          );
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  固定部 END   ###############################
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf                 OUT    VARCHAR2      -- エラーメッセージ
    ,retcode                OUT    VARCHAR2      -- エラーコード
    ,iv_block1              IN     VARCHAR2      -- 01:ブロック1
    ,iv_block2              IN     VARCHAR2      -- 02:ブロック2
    ,iv_block3              IN     VARCHAR2      -- 03:ブロック3
    ,iv_tighten_date        IN     VARCHAR2      -- 04:締め実施日
    ,iv_tighten_time_from   IN     VARCHAR2      -- 05:締め実施時間From
    ,iv_tighten_time_to     IN     VARCHAR2      -- 06:締め実施時間To
    ,iv_shipped_cd          IN     VARCHAR2      -- 07:出庫元
    ,iv_item_cd             IN     VARCHAR2      -- 08:品目
    ,iv_shipped_date_from   IN     VARCHAR2      -- 09:出庫日From
    ,iv_shipped_date_to     IN     VARCHAR2      -- 10:出庫日To
  );
END xxwsh620001c;
/
