CREATE OR REPLACE PACKAGE xxwsh620008c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620008c(spec)
 * Description      : 積込指示書
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_621
 * MD.070           : 積込指示書 T_MD070_BPO_62J
 * Version          : 1.4
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/03/31    1.0   Yoshitomo Kawasaki 新規作成
 *  2008/06/23    1.1   Yoshikatsu Shindou 配送区分情報VIEWのリレーションを外部結合に変更
 *                                         小口区分がNULLの時の処理を追加
 *  2008/07/03    1.2   Jun Nakada         ST不具合対応No412 重量容積の小数第一位切り上げ
 *  2008/07/07    1.3   Akiyoshi Shiina    変更要求対応#92
 *                                         禁則文字「'」「"」「<」「>」「＆」対応
 *  2008/07/15    1.4   Masayoshi Uehara   入数の小数部を切り捨てて、整数で表示
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
       errbuf                   OUT   VARCHAR2          -- エラーメッセージ
      ,retcode                  OUT   VARCHAR2          -- エラーコード
      ,iv_business_type         IN    VARCHAR2          -- 01 : 業務種別
      ,iv_block_1               IN    VARCHAR2          -- 02 : ブロック１
      ,iv_block_2               IN    VARCHAR2          -- 03 : ブロック２
      ,iv_block_3               IN    VARCHAR2          -- 04 : ブロック３
      ,iv_delivery_origin       IN    VARCHAR2          -- 05 : 出庫元
      ,iv_delivery_day          IN    VARCHAR2          -- 06 : 出庫日
      ,iv_delivery_no           IN    VARCHAR2          -- 07 : 配送№
      ,iv_delivery_form         IN    VARCHAR2          -- 08 : 出庫形態
      ,iv_jurisdiction_base     IN    VARCHAR2          -- 09 : 管轄拠点
      ,iv_addre_delivery_dest   IN    VARCHAR2          -- 10 : 配送先/入庫先
      ,iv_request_movement_no   IN    VARCHAR2          -- 11 : 依頼№/移動№
      ,iv_commodity_div         IN    VARCHAR2          -- 12 : 商品区分
    ) ;
END xxwsh620008c;
/
