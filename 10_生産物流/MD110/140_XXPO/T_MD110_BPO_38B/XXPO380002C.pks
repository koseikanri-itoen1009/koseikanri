CREATE OR REPLACE PACKAGE xxpo380002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO380002C(spec)
 * Description      : 発注依頼書
 * MD.050/070       : 発注依頼作成Issue1.0  (T_MD050_BPO_380)
 *                    発注依頼作成Issue1.0  (T_MD070_BPO_38B)
 * Version          : 1.4
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 帳票プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/06    1.0   Syogo Chinen     新規作成
 *  2008/06/17    1.1   T.Ikehara        TEMP領域エラー回避のため、xxpo_categories_vを
 *                                       使用しないようにする
 *  2008/06/24    1.2   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/06/27    1.3   T.Ikehara        明細が最大行出力（30行出力）の時に、
 *                                       合計が次ページに表示される現象を修正
 *  2008/07/04    1.4   I.Higa           TEMP領域エラー回避のため、xxcmn_item_categories4_vを
 *                                       使用しないようにする
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
  PROCEDURE main (
      errbuf                OUT    VARCHAR2         --   エラーメッセージ
     ,retcode               OUT    VARCHAR2         --   エラーコード
     ,iv_po_number          IN     VARCHAR2         --   01 : 発注番号
     ,iv_division_code      IN     VARCHAR2         --   02 : 依頼部署
     ,iv_employee_number    IN     VARCHAR2         --   03 : 担当者
     ,iv_location_code      IN     VARCHAR2         --   04 : 発注部署
     ,iv_creation_date_f    IN     VARCHAR2         --   05 : 作成日FROM
     ,iv_creation_date_t    IN     VARCHAR2         --   06 : 作成日TO
     ,iv_vendor_code        IN     VARCHAR2         --   07 : 取引先
     ,iv_promised_date_f    IN     VARCHAR2         --   08 : 納入日FROM
     ,iv_promised_date_t    IN     VARCHAR2         --   09 : 納入日TO
     ,iv_whse_code          IN     VARCHAR2         --   10 : 納入先
     ,iv_prod_class_code    IN     VARCHAR2         --   11 : 商品区分
     ,iv_item_class_code    IN     VARCHAR2         --   12 : 品目区分
    ) ;
END xxpo380002c;
/
