CREATE OR REPLACE PACKAGE xxpo440005c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440005(spec)
 * Description      : 有償明細表
 * MD.050/070       : 有償支給帳票Issue1.0(T_MD050_BPO_444)
 *                    有償支給帳票Issue1.0(T_MD070_BPO_44M)
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
 *  2008/04/09    1.0   Yusuke Tabata    新規作成
 *  2008/05/20    1.1   Yusuke Tabata   内部変更要求Seq95(日付型パラメータ型変換)対応
 *  2008/06/03    1.2   Yohei  Takayama 結合テスト不具合#440_46対応
 *  2008/06/04    1.3 Yasuhisa Yamamoto 結合テスト不具合ログ#440_54
 *  2008/06/19    1.4   Kazuo Kumamoto  結合テストレビュー指摘事項#18対応
 *  2008/07/02    1.5   Satoshi Yunba   禁則文字「'」「"」「<」「>」「&」対応
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
     ,iv_date_from          IN     VARCHAR2         -- 01 : 出庫日From
     ,iv_date_to            IN     VARCHAR2         -- 02 : 出庫日To
     ,iv_prod_div           IN     VARCHAR2         -- 03 : 商品区分
     ,iv_dept_code          IN     VARCHAR2         -- 04 : 担当部署
     ,iv_vendor_code_01     IN     VARCHAR2         -- 05 : 取引先１
     ,iv_vendor_code_02     IN     VARCHAR2         -- 06 : 取引先２
     ,iv_vendor_code_03     IN     VARCHAR2         -- 07 : 取引先３
     ,iv_vendor_code_04     IN     VARCHAR2         -- 08 : 取引先４
     ,iv_vendor_code_05     IN     VARCHAR2         -- 09 : 取引先５
     ,iv_item_div           IN     VARCHAR2         -- 10 : 品目区分
     ,iv_crowd_code_01      IN     VARCHAR2         -- 11 : 群１
     ,iv_crowd_code_02      IN     VARCHAR2         -- 12 : 群２
     ,iv_crowd_code_03      IN     VARCHAR2         -- 13 : 群３
     ,iv_item_code_01       IN     VARCHAR2         -- 14 : 品目１
     ,iv_item_code_02       IN     VARCHAR2         -- 15 : 品目２
     ,iv_item_code_03       IN     VARCHAR2         -- 16 : 品目３
     ,iv_security_div       IN     VARCHAR2         -- 17 : 有償セキュリティ区分
    ) ;
--
END xxpo440005c ;
/
