CREATE OR REPLACE PACKAGE xxpo440004c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440004(spec)
 * Description      : 入出庫差異明細表
 * MD.050/070       : 有償支給帳票Issue1.0(T_MD050_BPO_444)
 *                    有償支給帳票Issue1.0(T_MD070_BPO_44L)
 * Version          : 1.5
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
 *  2008/03/18    1.0   Yusuke Tabata    新規作成
 *  2008/05/20    1.1   Yusuke Tabata    内部変更要求Seq95(日付型パラメータ型変換)対応
 *  2008/05/28    1.2   Yusuke Tabata    結合不具合対応(出荷実績計上済のコード誤り)
 *  2008/07/01    1.3   Oracle 椎名      内部変更要求142
 *  2009/12/14    1.4   SCS    吉元 強樹 E_本稼動_00430対応
 *  2009/12/15    1.5   SCS    吉元 強樹 E_本稼動_00430対応
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
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_diff_reason_code   IN     VARCHAR2         -- 01 : 差異事由
     ,iv_deliver_from_code  IN     VARCHAR2         -- 02 : 出庫倉庫
     ,iv_prod_div           IN     VARCHAR2         -- 03 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 04 : 品目区分
     ,iv_date_from          IN     VARCHAR2         -- 05 : 出庫日From
     ,iv_date_to            IN     VARCHAR2         -- 06 : 出庫日To
     ,iv_dlv_vend_code      IN     VARCHAR2         -- 07 : 配送先
     ,iv_request_no         IN     VARCHAR2         -- 08 : 依頼No
     ,iv_item_code          IN     VARCHAR2         -- 09 : 品目
     ,iv_dept_code          IN     VARCHAR2         -- 10 : 担当部署
     ,iv_security_div       IN     VARCHAR2         -- 11 : 有償セキュリティ区分
    ) ;
--
END xxpo440004c ;
/
