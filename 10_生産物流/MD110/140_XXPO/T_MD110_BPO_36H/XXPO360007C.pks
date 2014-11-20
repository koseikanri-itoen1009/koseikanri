CREATE OR REPLACE PACKAGE xxpo360007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360007C(spec)
 * Description      : 入出庫差異表
 * MD.050/070       : 仕入（帳票）Issue2.0 (T_MD050_BPO_360)
 *                    仕入（帳票）Issue2.0 (T_MD070_BPO_36H)
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
 *  2008/04/03    1.0   N.Chinen         新規作成
 *  2008/05/19    1.1   Y.Ishikawa       外部ユーザー時に警告終了になる
 *  2008/05/20    1.2   Y.Majikina       セキュリティ外部倉庫の不具合対応
 *  2008/05/22    1.3   Y.Ishikawa       入力パラメータ差異コードがNULLの場合全データ対象にする。
 *  2008/05/22    1.4   Y.Ishikawa       品目コードの表示不正修正
 *                                       指示数を数量→発注数量(DFF11)に変更
 *  2008/06/10    1.5   Y.Ishikawa       ロットマスタに同じロットNoが存在する場合、
 *                                       2明細出力される
 *  2008/06/17    1.6   I.Higa           xxpo_categories_vを使用しないようにする
 *  2008/06/24    1.7   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/07/04    1.8   Y.Ishikawa       xxcmn_item_categories4_vを使用しないようにする
 *  2008/11/21    1.9   T.Yoshimoto      統合指摘#703
 *  2009/03/30    1.10  A.Shiina         本番#1346対応
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
      errbuf                OUT   VARCHAR2,  -- エラーメッセージ
      retcode               OUT   VARCHAR2,  -- エラーコード
      iv_sai_cd             IN    VARCHAR2,  -- 差異事由
      iv_rcpt_subinv_code   IN    VARCHAR2,  -- 入庫倉庫
      iv_goods_class        IN    VARCHAR2,  -- 商品区分
      iv_item_class         IN    VARCHAR2,  -- 品目区分
      iv_dlv_from           IN    VARCHAR2,  -- 納入日from
      iv_dlv_to             IN    VARCHAR2,  -- 納入日to
      iv_ship_code_from     IN    VARCHAR2,  -- 出庫元
      iv_order_num          IN    VARCHAR2,  -- 発注番号
      iv_item_code          IN    VARCHAR2,  -- 品目
      iv_position           IN    VARCHAR2,  -- 担当部署
      iv_seqrt_class        IN    VARCHAR2   -- セキュリティ区分
    );
--
END xxpo360007c;
/
