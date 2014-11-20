CREATE OR REPLACE PACKAGE xxpo360007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360007C(spec)
 * Description      : 入出庫差異表
 * MD.050/070       : 仕入（帳票）Issue2.0 (T_MD050_BPO_360)
 *                    仕入（帳票）Issue2.0 (T_MD070_BPO_36H)
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
 *  2008/04/02    1.0   N.Chinen        新規作成
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
