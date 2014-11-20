CREATE OR REPLACE PACKAGE xxwip740002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP740002(spec)
 * Description      : 請求書
 * MD.050/070       : 請求書(T_MD050_BPO_740)
 *                    請求書(T_MD070_BPO_74C)
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
 *  2008/04/25    1.0   Yusuke Tabata    新規作成
 *  2008/07/02    1.1   Satoshi Yunba   禁則文字「'」「"」「<」「>」「&」対応
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
      errbuf                OUT  VARCHAR2  -- エラーメッセージ
     ,retcode               OUT  VARCHAR2  -- エラーコード
     ,iv_billing_code       IN   VARCHAR2  -- 01 : 請求先コード
     ,iv_billing_date       IN   VARCHAR2  -- 02 : 請求年月
    ) ;
--
END xxwip740002c ;
/
