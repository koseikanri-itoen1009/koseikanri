CREATE OR REPLACE PACKAGE xxcmn770004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770004C(spec)
 * Description      : 受払その他実績リスト
 * MD.050/070       : 月次〆切処理帳票Issue1.0 (T_MD050_BPO_770)
 *                    月次〆切処理帳票Issue1.0 (T_MD070_BPO_77D)
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
 *  2008/04/09    1.0   C.Kinjo          新規作成
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
      errbuf                OUT    VARCHAR2         --   エラーメッセージ
     ,retcode               OUT    VARCHAR2         --   エラーコード
     ,iv_exec_year_month    IN     VARCHAR2         --   01 : 処理年月
     ,iv_goods_class        IN     VARCHAR2         --   02 : 商品区分
     ,iv_item_class         IN     VARCHAR2         --   03 : 品目区分
     ,iv_div_type1          IN     VARCHAR2         --   04 : 受払区分１
     ,iv_div_type2          IN     VARCHAR2         --   05 : 受払区分２
     ,iv_div_type3          IN     VARCHAR2         --   06 : 受払区分３
     ,iv_div_type4          IN     VARCHAR2         --   07 : 受払区分４
     ,iv_div_type5          IN     VARCHAR2         --   08 : 受払区分５
     ,iv_reason_code        IN     VARCHAR2         --   09 : 事由コード
    ) ;
END xxcmn770004c ;
/
