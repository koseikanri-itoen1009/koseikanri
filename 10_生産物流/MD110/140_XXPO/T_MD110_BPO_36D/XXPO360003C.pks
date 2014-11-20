CREATE OR REPLACE PACKAGE xxpo360003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360003C(spec)
 * Description      : 入庫予定表
 * MD.050/070       : 有償支給帳票Issue1.0 (T_MD050_BPO_360)
 *                    有償支給帳票Issue1.0 (T_MD070_BPO_36D)
 * Version          : 1.9
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
 *  2008/03/10    1.0   T.Hokama         新規作成
 *  2008/05/14    1.1   H.Yamazato       不具合ID3～5対応
 *  2008/05/19    1.2   Y.Ishikawa       外部ユーザー時に警告終了になる
 *  2008/05/20    1.3   Y.Majikina       セキュリティ外部倉庫の不具合対応
 *  2008/06/10    1.4   Y.Ishikawa       ロットマスタに同じロットNoが存在する場合、
 *                                       2明細出力される
 *  2008/06/17    1.5   I.Higa           xxpo_categories_vを使用しないようにする
 *  2008/06/25    1.6   I.Higa           特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/07/04    1.7   Y.Ishikawa       xxcmn_item_categories4_vを使用しないようにする
 *  2009/03/30    1.8   A.Shiina         本番#1346対応
 *  2009/09/24    1.9   T.Yoshimoto      本番#1523対応
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
     ,iv_rcpt_subinv_code   IN     VARCHAR2         --   01 : 入庫保管場所コード
     ,iv_dlv_from           IN     VARCHAR2         --   02 : 納品日（ＦＲＯＭ）
     ,iv_dlv_to             IN     VARCHAR2         --   03 : 納品日（ＴＯ）
     ,iv_goods_class        IN     VARCHAR2         --   04 : 商品区分
     ,iv_item_class         IN     VARCHAR2         --   05 : 品目区分
     ,iv_item_code          IN     VARCHAR2         --   06 : 品目コード
     ,iv_ship_code_from     IN     VARCHAR2         --   07 : 出庫元コード
     ,iv_seqrt_class        IN     VARCHAR2         --   08 : セキュリティ区分
    ) ;
END xxpo360003c ;
/
