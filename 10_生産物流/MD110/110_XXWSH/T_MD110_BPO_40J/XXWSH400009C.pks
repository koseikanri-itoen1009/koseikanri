CREATE OR REPLACE PACKAGE xxwsh400009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH400009C(spec)
 * Description      : 出荷依頼確認表
 * MD.050           : 出荷依頼       T_MD050_BPO_401
 * MD.070           : 出荷依頼確認表 T_MD070_BPO_40J
 * Version          : 1.12
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
 *  2008/04/11    1.0   Masanobu Kimura  main新規作成
 *  2008/06/10    1.1   石渡  賢和       ヘッダ「出力日付」の書式を変更
 *  2008/06/13    1.2   石渡  賢和       ST不具合対応
 *  2008/06/23    1.3   石渡  賢和       ST不具合対応#106
 *  2008/07/01    1.4   福田  直樹       ST不具合対応#331 商品区分は入力パラメータから取得
 *  2008/07/02    1.5   Satoshi Yunba    禁則文字「'」「"」「<」「>」「＆」対応
 *  2008/07/03    1.6   椎名  昭圭       ST不具合対応#344･357･406対応
 *  2008/07/10    1.7   上原  正好       変更要求#91対応 配送区分情報VIEWを外部結合に変更
 *  2008/07/15    1.8   熊本  和郎       TE080指摘事項#3対応(受注明細アドオン.削除フラグを条件に追加)
 *  2008/07/31    1.9   Yuko  Kawano     結合テスト不具合対応(総重量/総容積の算出ロジック変更)
 *  2008/10/20    1.10  Yuko  Kawano     課題＃32,48,62、統合指摘＃294、T_S_627対応
 *  2008/11/14    1.11  大橋  孝郎       指摘567,599,605対応
 *  2008/12/11    1.12  山本  恭久       本番障害#641対応
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
    errbuf                     OUT VARCHAR2,      --   エラーメッセージ
    retcode                    OUT VARCHAR2,      --   エラーコード
    iv_head_sales_branch       IN  VARCHAR2,      --   1.管轄拠点
    iv_input_sales_branch      IN  VARCHAR2,      --   2.入力拠点
    iv_deliver_to              IN  VARCHAR2,      --   3.配送先
    iv_deliver_from            IN  VARCHAR2,      --   4.出荷元
    iv_ship_date_from          IN  VARCHAR2,      --   5.出庫日From
    iv_ship_date_to            IN  VARCHAR2,      --   6.出庫日To
    iv_arrival_date_from       IN  VARCHAR2,      --   7.着日From
    iv_arrival_date_to         IN  VARCHAR2,      --   8.着日To
    iv_order_type_id           IN  VARCHAR2,      --   9.出庫形態
    iv_request_no              IN  VARCHAR2,      --   10.依頼No.
    iv_req_status              IN  VARCHAR2,      --   11.出荷依頼ステータス
    iv_confirm_request_class   IN  VARCHAR2,      --   12.物流担当確認依頼区分
    iv_prod_class              IN  VARCHAR2       --   13.商品区分
    );
--
END xxwsh400009c;
/
