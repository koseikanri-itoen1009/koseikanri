CREATE OR REPLACE PACKAGE xxpo360002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo360002c(spec)
 * Description      : 出庫予定表
 * MD.050/070       : 有償支給帳票Issue1.0 (T_MD050_BPO_360)
 *                    有償支給帳票Issue1.0 (T_MD070_BPO_36C)
 * Version          : 1.10
 *
 * Program List
 * -------------------- ------------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -----------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -----------------------------------------------
 *  2008/03/12    1.0   hirofumi yamazato  新規作成
 *  2008/05/14    1.1   hirofumi yamazato  不具合ID3対応
 *  2008/05/19    1.2   Y.Ishikawa         外部ユーザー時に警告終了になる
 *  2008/05/20    1.3   T.Endou            セキュリティ外部倉庫の不具合対応
 *  2008/05/22    1.4   Y.Majikina         明細適用の最大長を修正
 *  2008/06/10    1.5   Y.Ishikawa         ロットマスタに同じロットNoが存在する場合、
 *                                         2明細出力される
 *  2008/06/17    1.6   I.Higa             xxpo_categories_vを使用しないようにする
 *  2008/06/25    1.7   I.Higa             特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                         されない現象への対応
 *  2008/07/04    1.8   Y.Ishikawa         xxcmn_item_categories4_vを使用しないようにする
 *  2009/03/30    1.9   A.Shiina           本番#1346対応
 *  2009/09/24    1.10  T.Yoshimoto        本番#1523対応
 ****************************************************************************************/
--
--#######################  固定グローバル変数宣言部 START   ####################
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
      errbuf          OUT    VARCHAR2         --   エラーメッセージ
     ,retcode         OUT    VARCHAR2         --   エラーコード
     ,iv_vend_code    IN     VARCHAR2         --   01 : 出庫元
     ,iv_dlv_f        IN     VARCHAR2         --   02 : 納入日FROM
     ,iv_dlv_t        IN     VARCHAR2         --   03 : 納入日TO
     ,iv_goods_class  IN     VARCHAR2         --   04 : 商品区分
     ,iv_item_class   IN     VARCHAR2         --   05 : 品目区分
     ,iv_item_code    IN     VARCHAR2         --   06 : 品目
     ,iv_dept_code    IN     VARCHAR2         --   07 : 入庫倉庫
     ,iv_seqrt_class  IN     VARCHAR2         --   08 : セキュリティ区分
    ) ;
END xxpo360002c;
/
