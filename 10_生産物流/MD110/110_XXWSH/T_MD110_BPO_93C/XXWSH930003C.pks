CREATE OR REPLACE PACKAGE xxwsh930003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH930003C(spec)
 * Description      : 入出庫情報差異リスト（出庫基準）
 * MD.050/070       : 生産物流共通（出荷・移動インタフェース）Issue1.0(T_MD050_BPO_930)
 *                    生産物流共通（出荷・移動インタフェース）Issue1.0(T_MD070_BPO_93C)
 * Version          : 1.11
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
 *  2008/02/19    1.0   Masayuki Ikeda   新規作成
 *  2008/06/23    1.1   Oohashi  Takao   不具合ログ対応
 *  2008/06/25    1.2   Oohashi  Takao   不具合ログ対応
 *  2008/06/30    1.3   Oohashi  Takao   不具合ログ対応
 *  2008/07/02    1.4   Kawano   Yuko    ST不具合対応#352
 *  2008/07/07    1.5   Akiyoshi Shiina  変更要求対応#92
 *  2008/07/08    1.5   Satoshi  Yunba   禁則文字対応
 *  2008/07/24    1.6   Akiyoshi Shiina  ST不具合#197、内部課題#32、内部変更要求#180対応
 *  2008/10/10    1.7   Naoki    Fukuda  統合テスト障害#338対応
 *  2008/10/17    1.8   Naoki    Fukuda  統合テスト障害#146対応
 *  2008/10/17    1.8   Naoki    Fukuda  課題T_S_458対応(部署を任意入力パラメータに変更。PACKAGEの修正はなし)
 *  2008/10/17    1.8   Naoki    Fukuda  変更要求#210対応
 *  2008/10/20    1.9   Naoki    Fukuda  課題T_S_486対応
 *  2008/10/20    1.9   Naoki    Fukuda  統合テスト障害#394(1)対応
 *  2008/10/20    1.9   Naoki    Fukuda  統合テスト障害#394(2)対応
 *  2008/10/31    1.10  Naoki    Fukuda  統合指摘#461対応
 *  2008/11/13    1.11  Naoki    Fukuda  統合指摘#603対応
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
     ,iv_business_type      IN     VARCHAR2         -- 01 : 業務種別
     ,iv_prod_div           IN     VARCHAR2         -- 02 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 03 : 品目区分
     ,iv_date_from          IN     VARCHAR2         -- 04 : 出庫日From
     ,iv_date_to            IN     VARCHAR2         -- 05 : 出庫日To
     ,iv_dept_code          IN     VARCHAR2         -- 06 : 部署
     ,iv_output_type        IN     VARCHAR2         -- 07 : 出力区分
     ,iv_deliver_type       IN     VARCHAR2         -- 08 : 出庫形態
     ,iv_block_01           IN     VARCHAR2         -- 09 : ブロック１
     ,iv_block_02           IN     VARCHAR2         -- 10 : ブロック２
     ,iv_block_03           IN     VARCHAR2         -- 11 : ブロック３
     ,iv_deliver_from       IN     VARCHAR2         -- 12 : 出庫元
     ,iv_online_type        IN     VARCHAR2         -- 13 : オンライン対象区分
     ,iv_request_no         IN     VARCHAR2         -- 14 : 依頼No／移動No
    ) ;
--
END xxwsh930003c ;
/
