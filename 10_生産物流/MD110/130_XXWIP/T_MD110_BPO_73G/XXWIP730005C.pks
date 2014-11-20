CREATE OR REPLACE PACKAGE xxwip730005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP730005C(spec)
 * Description      : 請求運賃チェックリスト
 * MD.050/070       : 運賃計算（トランザクション）  (T_MD050_BPO_734)
 *                    請求運賃チェックリスト        (T_MD070_BPO_73G)
 * Version          : 1.10
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
 *  2008/04/30    1.0   Masayuki Ikeda   新規作成
 *  2008/05/23    1.1   Masayuki Ikeda   結合テスト障害対応
 *  2008/07/02    1.2   Satoshi Yunba   禁則文字対応
 *  2008/07/15    1.3   Masayuki Nomura  ST障害対応#444
 *  2008/07/15    1.4   Masayuki Nomura  ST障害対応#444（記号対応）
 *  2008/07/17    1.5   Satoshi Takemoto ST障害対応#456
 *  2008/07/24    1.6   Satoshi Takemoto ST障害対応#477
 *  2008/07/25    1.7   Masayuki Nomura  ST障害対応#456
 *  2008/07/28    1.8   Masayuki Nomura  変更要求結合テスト障害対応
 *  2008/08/19    1.9   Takao Ohashi     T_TE080_BPO_730 指摘10対応
 *  2008/10/15    1.10  Yasuhisa Yamamoto 統合障害#300,331
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
     ,iv_prod_div           IN     VARCHAR2         -- 01 : 商品区分
     ,iv_carrier_code_from  IN     VARCHAR2         -- 02 : 運送業者From
     ,iv_carrier_code_to    IN     VARCHAR2         -- 03 : 運送業者To
     ,iv_whs_code_from      IN     VARCHAR2         -- 04 : 出庫元倉庫From
     ,iv_whs_code_to        IN     VARCHAR2         -- 05 : 出庫元倉庫To
     ,iv_ship_date_from     IN     VARCHAR2         -- 06 : 出庫日From
     ,iv_ship_date_to       IN     VARCHAR2         -- 07 : 出庫日To
     ,iv_arrival_date_from  IN     VARCHAR2         -- 08 : 着日From
     ,iv_arrival_date_to    IN     VARCHAR2         -- 09 : 着日To
     ,iv_judge_date_from    IN     VARCHAR2         -- 10 : 決済日From
     ,iv_judge_date_to      IN     VARCHAR2         -- 11 : 決済日To
     ,iv_report_date_from   IN     VARCHAR2         -- 12 : 報告日From
     ,iv_report_date_to     IN     VARCHAR2         -- 13 : 報告日To
     ,iv_delivery_no_from   IN     VARCHAR2         -- 14 : 配送NoFrom
     ,iv_delivery_no_to     IN     VARCHAR2         -- 15 : 配送NoTo
     ,iv_request_no_from    IN     VARCHAR2         -- 16 : 依頼NoFrom
     ,iv_request_no_to      IN     VARCHAR2         -- 17 : 依頼NoTo
     ,iv_invoice_no_from    IN     VARCHAR2         -- 18 : 送り状NoFrom
     ,iv_invoice_no_to      IN     VARCHAR2         -- 19 : 送り状NoTo
     ,iv_order_type         IN     VARCHAR2         -- 20 : 受注タイプ
     ,iv_wc_class           IN     VARCHAR2         -- 21 : 重量容積区分
     ,iv_outside_contract   IN     VARCHAR2         -- 22 : 契約外
     ,iv_return_flag        IN     VARCHAR2         -- 23 : 確定後変更
     ,iv_output_flag        IN     VARCHAR2         -- 24 : 差異
    ) ;
--
END xxwip730005c ;
/
