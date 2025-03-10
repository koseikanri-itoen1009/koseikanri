CREATE OR REPLACE PACKAGE xxwsh620004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620004c(spec)
 * Description      : 倉庫払出指示書
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_621
 * MD.070           : 倉庫払出指示書  T_MD070_BPO_62F
 * Version          : 1.6
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
 *  2008/05/02    1.0   Yuki Komikado    新規作成
 *  2008/06/24    1.1   Masayoshi Uehara   支給の場合、パラメータ配送先/入庫先のリレーションを
 *                                         vendor_site_codeに変更。
 *  2008/07/02    1.2   Satoshi Yunba    禁則文字対応
 *  2008/07/18    1.3   Hitomi Itou      ST不具合#465対応 出庫元・ブロックの抽出条件を変更
 *  2008/08/07    1.4   Akiyoshi Shiina  内部変更要求#168,#183対応
 *  2008/10/20    1.5   Masayoshi Uehara T_TE080_BPO_620 指摘44(品目、ロット単位に合計して算出)
 *                                       課題#62変更#168 指示無し実績の帳票出力制御
 *  2009/04/27    1.6   Y.Kazama         本番障害#1398対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  固定部 END   ###############################
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
     errbuf                    OUT    VARCHAR2         --   エラーメッセージ
    ,retcode                   OUT    VARCHAR2         --   エラーコード
    ,iv_biz_type               IN     VARCHAR2         --   01 : 業務種別
    ,iv_deliver_type           IN     VARCHAR2         --   02 : 出庫形態
    ,iv_block                  IN     VARCHAR2         --   03 : ブロック
    ,iv_deliver_from           IN     VARCHAR2         --   04 : 出庫元
    ,iv_deliver_to             IN     VARCHAR2         --   05 : 配送先／入庫先
    ,iv_prod_div               IN     VARCHAR2         --   06 : 商品区分
    ,iv_item_div               IN     VARCHAR2         --   07 : 品目区分
    ,iv_date                   IN     VARCHAR2         --   08 : 出庫日
  );
END xxwsh620004c;
/
