CREATE OR REPLACE PACKAGE xxcmn770008cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770008cp(spec)
 * Description      : 返品原料原価差異表(プロト)
 * MD.050/070       : 月次〆切処理（経理）Issue1.0(T_MD050_BPO_770)
 *                    月次〆切処理（経理）Issue1.0(T_MD070_BPO_77H)
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
 *  2008/04/14    1.0   T.Ikehara        新規作成
 *  2008/05/15    1.1   T.Ikehara        処理年月パラYYYYM入力対応
 *                                       担当部署、担当者名の最大長処理を修正
 *  2008/06/03    1.2   T.Endou          担当部署または担当者名が未取得時は正常終了に修正
 *  2008/06/10    1.3   T.Ikehara        投入品と製品のラインタイプを修正
 *  2008/06/13    1.4   T.Ikehara        生産原料詳細(アドオン)の結合が不要の為削除
 *  2008/06/19    1.5   Y.Ishikawa       金額、数量がNULLの場合は0を表示する。
 *  2008/06/25    1.6   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/08/26    1.7   A.Shiina         T_TE080_BPO_770 指摘17対応
 *  2008/10/15    1.8   N.Yoshida        T_S_524対応(PT対応)
 *  2008/11/11    1.9   N.Yoshida        移行データ検証時不具合対応
 *  2009/02/13    1.10  A.Shiina         本番#1190対応
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
      errbuf                  OUT    VARCHAR2    -- エラーメッセージ
     ,retcode                 OUT    VARCHAR2    -- エラーコード
     ,iv_proc_date            IN     VARCHAR2    -- 01 : 処理年月
     ,iv_product_class        IN     VARCHAR2    -- 02 : 商品区分
     ,iv_item_class           IN     VARCHAR2    -- 03 : 品目区分
     ,iv_rcv_pay_div          IN     VARCHAR2);  -- 04 : 受払区分
  END xxcmn770008cp;
/
