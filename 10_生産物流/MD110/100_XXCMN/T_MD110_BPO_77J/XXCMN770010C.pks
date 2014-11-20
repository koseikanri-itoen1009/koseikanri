CREATE OR REPLACE PACKAGE xxcmn770010c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770010C(spec)
 * Description      : 標準原価内訳表
 * MD.050/070       : 月次〆切処理帳票Issue1.0 (T_MD050_BPO_770)
 *                    月次〆切処理帳票Issue1.0 (T_MD070_BPO_77J)
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
 *  2008/04/14    1.0   N.Chinen         新規作成
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
     ,iv_exec_date_from     IN     VARCHAR2         --   01 : 処理年月(from)
     ,iv_exec_date_to       IN     VARCHAR2         --   02 : 処理年月(to)
     ,iv_goods_class        IN     VARCHAR2         --   03 : 商品区分
     ,iv_item_class         IN     VARCHAR2         --   04 : 品目区分
     ,iv_rcv_pay_div        IN     VARCHAR2         --   05 : 受払区分
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : 集計種別
     ,iv_crowd_code         IN     VARCHAR2         --   07 : 群コード
     ,iv_acct_crowd_code    IN     VARCHAR2         --   08 : 経理群コード
    );
END xxcmn770010c;
/
