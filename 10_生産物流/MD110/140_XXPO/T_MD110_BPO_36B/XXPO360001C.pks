CREATE OR REPLACE PACKAGE xxpo360001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo360001c(spec)
 * Description      : 発注書
 * MD.050/070       : 仕入（帳票）Issue1.0(T_MD050_BPO_360)
 *                    仕入（帳票）Issue1.0(T_MD070_BPO_36B)
 * Version          : 1.15
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
 *  2008/03/14    1.0   C.Kinjo          新規作成
 *  2008/05/14    1.1   R.Tomoyose       発注明細と仕入先サイトIDの紐付きを修正
 *                                       数値項目の値が0の場合は値を出力しない(ブランクにする)
 *  2008/05/19    1.2   Y.Ishikawa       斡旋者IDが存在しない場合でも出力するように変更
 *  2008/05/20    1.3   T.Endou          セキュリティ外部倉庫の不具合対応
 *  2008/05/20    1.4   T.Endou          入出庫換算単位がある場合の、仕入金額計算方法ミス修正
 *  2008/06/10    1.5   Y.Ishikawa       ロットマスタに同じロットNoが存在する場合、2明細出力される
 *  2008/06/17    1.6   T.Ikehara        TEMP領域エラー回避のため、xxpo_categories_vを
 *                                       使用しないようにする
 *  2008/06/25    1.7   I.Higa           特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/06/27    1.8   R.Tomoyose       明細が最大行出力（６行出力）の時に、
 *                                       合計が次ページに表示される現象を修正
 *  2008/10/21    1.9   T.Ohashi         指摘382対応
 *  2008/11/20    1.10  T.Ohashi         指摘664対応
 *  2009/03/30    1.11  A.Shiina         本番#1346対応
 *  2009/04/01    1.12  T.Yoshimoto      本番#1363対応
 *  2009/04/01    1.13  T.Yoshimoto      本番#1363対応(再)
 *  2009/09/15    1.14  T.Yoshimoto      本番#1624対応
 *  2009/09/24    1.15  T.Yoshimoto      本番#1523対応
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
