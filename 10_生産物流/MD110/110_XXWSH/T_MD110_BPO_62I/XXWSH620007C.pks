CREATE OR REPLACE PACKAGE xxwsh620007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620007c(spec)
 * Description      : 倉庫払出指示書（配送先明細）
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_621
 * MD.070           : 倉庫払出指示書（配送先明細） T_MD070_BPO_62I
 * Version          : 1.6
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
 *  2008/05/14    1.0   Nozomi Kashiwagi   新規作成
 *  2008/06/24    1.1   Masayoshi Uehara   支給の場合、パラメータ配送先/入庫先のリレーションを
 *                                         vendor_site_codeに変更。
 *  2008/07/04    1.2   Satoshi Yunba      禁則文字対応
 *  2008/07/10    1.3   Naoki Fukuda       ロットNo.がNULLだと品目が違っても一括りで出力される
 *  2008/08/05    1.4   Akiyoshi Shiina    ST不具合#519対応
 *  2008/10/23    1.5   Yuko Kawano        課題#32,#62 変更#183対応
 *  2009/04/27    1.6   Y.Kazama           本番障害#1398対応
 *
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
    ,iv_biz_type            IN     VARCHAR2      -- 01:業務種別        ※必須
    ,iv_ship_type           IN     VARCHAR2      -- 02:出庫形態
    ,iv_block               IN     VARCHAR2      -- 03:ブロック
    ,iv_shipped_cd          IN     VARCHAR2      -- 04:出庫元
    ,iv_delivery_to         IN     VARCHAR2      -- 05:配送先／入庫先
    ,iv_prod_class          IN     VARCHAR2      -- 06:商品区分        ※必須
    ,iv_item_class          IN     VARCHAR2      -- 07:品目区分
    ,iv_shipped_date        IN     VARCHAR2      -- 08:出庫日          ※必須
  );
END xxwsh620007c;
/
