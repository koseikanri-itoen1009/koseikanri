CREATE OR REPLACE PACKAGE xxpo360001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo360001c(spec)
 * Description      : 発注書
 * MD.050/070       : 仕入（帳票）Issue1.0(T_MD050_BPO_360)
 *                    仕入（帳票）Issue1.0(T_MD070_BPO_36B)
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
 *  2008/03/13    1.0   C.Kinjo          新規作成
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
     ,iv_site_use           IN     VARCHAR2         --   01 : 使用目的
     ,iv_po_number          IN     VARCHAR2         --   02 : 発注番号
     ,iv_role_department    IN     VARCHAR2         --   03 : 担当部署
     ,iv_role_people        IN     VARCHAR2         --   04 : 担当者
     ,iv_create_date_from   IN     VARCHAR2         --   05 : 作成日FROM
     ,iv_create_date_to     IN     VARCHAR2         --   06 : 作成日TO
     ,iv_vendor_code        IN     VARCHAR2         --   07 : 取引先
     ,iv_mediation          IN     VARCHAR2         --   08 : 斡旋者
     ,iv_delivery_date_from IN     VARCHAR2         --   09 : 納入日FROM
     ,iv_delivery_date_to   IN     VARCHAR2         --   10 : 納入日TO
     ,iv_delivery_to        IN     VARCHAR2         --   11 : 納入先
     ,iv_product_type       IN     VARCHAR2         --   12 : 商品区分
     ,iv_item_type          IN     VARCHAR2         --   13 : 品目区分
     ,iv_security_type      IN     VARCHAR2         --   14 : セキュリティ区分
    ) ;
END xxpo360001c;
/
