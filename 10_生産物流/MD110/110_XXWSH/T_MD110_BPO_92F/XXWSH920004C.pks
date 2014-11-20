CREATE OR REPLACE PACKAGE xxwsh920004c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxwsh920004c(spec)
 * Description      : 出荷購入依頼一覧
 * MD.050/070       : 生産物流共通（出荷・移動仮引当）Issue1.0 (T_MD050_BPO_921)
 *                    生産物流共通（出荷・移動仮引当）Issue1.0 (T_MD070_BPO_92F)
 * Version          : 1.2
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
 *  2008/03/25    1.0   Yoshitomo Kawasaki 新規作成
 *  2008/06/11    1.1   Kazuo Kumamoto     内部変更要求#131対応
 *  2008/07/08    1.2   Satoshi Yunba      禁則文字対応
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
       errbuf                 OUT   VARCHAR2          -- エラーメッセージ
      ,retcode                OUT   VARCHAR2          -- エラーコード
      ,iv_delivery_dest       IN    VARCHAR2          -- 01 : 納入先
      ,iv_delivery_form       IN    VARCHAR2          -- 02 : 出庫形態
      ,iv_delivery_date       IN    VARCHAR2          -- 03 : 納期
      ,iv_delivery_day_from   IN    VARCHAR2          -- 04 : 出庫日From
      ,iv_delivery_day_to     IN    VARCHAR2          -- 05 : 出庫日To
    ) ;
END xxwsh920004c;
/
