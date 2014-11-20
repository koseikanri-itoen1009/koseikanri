CREATE OR REPLACE PACKAGE xxwsh620004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620004c(spec)
 * Description      : 倉庫払出指示書
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_621
 * MD.070           : 倉庫払出指示書  T_MD070_BPO_62F
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
 *  2008/05/02    1.0   Yuki Komikado    新規作成
 *  2008/06/24    1.1   Masayoshi Uehara   支給の場合、パラメータ配送先/入庫先のリレーションを
 *                                         vendor_site_codeに変更。
 *  2008/07/02    1.2   Satoshi Yunba    禁則文字対応
 *  2008/07/18    1.3   Hitomi Itou      ST不具合#465対応 出庫元・ブロックの抽出条件を変更
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
