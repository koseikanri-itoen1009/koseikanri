CREATE OR REPLACE PACKAGE xxpo440006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440006(spec)
 * Description      : 製造指示書
 * MD.050/070       : 製造指示書(T_MD050_BPO_444)
 *                    製造指示書(T_MD070_BPO_44N)
 * Version          : 1.5
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
 *  2008/04/21    1.0   Yusuke Tabata    新規作成
 *  2008/05/20    1.1   Yusuke Tabata   内部変更要求Seq95(日付型パラメータ型変換)対応
 *  2008/06/03    1.2   Yohei  Takayama 結合テスト不具合ログ#440_47
 *  2008/06/04    1.3 Yasuhisa Yamamoto 結合テスト不具合ログ#440_48,#440_55
 *  2008/06/07    1.4   Yohei  Takayama 結合テスト不具合ログ#440_67
 *  2008/07/02    1.5   Satoshi Yunba      禁則文字対応
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
      errbuf                 OUT    VARCHAR2         -- エラーメッセージ
     ,retcode                OUT    VARCHAR2         -- エラーコード
     ,iv_vendor_code         IN     VARCHAR2         -- 01 : 取引先
     ,iv_deliver_to_code     IN     VARCHAR2         -- 02 : 配送先
     ,iv_design_item_code_01 IN     VARCHAR2         -- 03 : 製造品目１
     ,iv_design_item_code_02 IN     VARCHAR2         -- 04 : 製造品目２
     ,iv_design_item_code_03 IN     VARCHAR2         -- 05 : 製造品目３
     ,iv_date_from           IN     VARCHAR2         -- 06 : 出庫日From
     ,iv_date_to             IN     VARCHAR2         -- 07 : 出庫日To
     ,iv_design_no           IN     VARCHAR2         -- 08 : 製造番号
     ,iv_security_div        IN     VARCHAR2         -- 09 : 有償セキュリティ区分
    ) ;
--
END xxpo440006c ;
/
