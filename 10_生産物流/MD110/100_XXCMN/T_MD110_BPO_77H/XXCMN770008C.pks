CREATE OR REPLACE PACKAGE xxcmn770008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770008c(spec)
 * Description      : 返品原料原価差異表
 * MD.050/070       : 月次〆切処理（経理）Issue1.0(T_MD050_BPO_770)
 *                    返品原料原価差異表Draft1A(T_MD070_BPO_77H)
 * Version          : 1.0
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
  END xxcmn770008c;
/
