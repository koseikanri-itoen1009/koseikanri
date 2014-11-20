CREATE OR REPLACE PACKAGE xxpo440002c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440002(spec)
 * Description      : 出庫予定表
 * MD.050/070       : 有償支給帳票Issue1.0(T_MD050_BPO_444)
 *                    有償支給帳票Issue1.0(T_MD070_BPO_44J)
 * Version          : 1.1
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
 *  2008/03/12    1.0   Masayuki Ikeda   新規作成
 *  2008/06/04    1.1 Yasuhisa Yamamoto  結合テスト不具合ログ#440_52
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
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_use_purpose        IN     VARCHAR2         -- 01 : 使用目的
     ,iv_locat_code         IN     VARCHAR2         -- 02 : 出庫倉庫
     ,iv_date_from          IN     VARCHAR2         -- 03 : 出庫日From
     ,iv_date_to            IN     VARCHAR2         -- 04 : 出庫日To
     ,iv_prod_div           IN     VARCHAR2         -- 05 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 06 : 品目区分
     ,iv_item_code          IN     VARCHAR2         -- 07 : 品目
     ,iv_deliver_to_code    IN     VARCHAR2         -- 08 : 配送先
     ,iv_security_div       IN     VARCHAR2         -- 09 : 有償セキュリティ区分
    ) ;
--
END xxpo440002c ;
/
