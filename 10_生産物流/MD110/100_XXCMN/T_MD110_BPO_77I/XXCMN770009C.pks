CREATE OR REPLACE PACKAGE xxcmn770009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770009C(spec)
 * Description      : 他勘定振替原価差異表
 * MD.050/070       : 月次〆切処理帳票Issue1.0(T_MD050_BPO_770)
 *                  : 月次〆切処理帳票Issue1.0(T_MD070_BPO_77I)
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
 *  2008/04/09    1.0   M.Hamamoto       新規作成
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
      errbuf             OUT   VARCHAR2  -- エラーメッセージ
     ,retcode            OUT   VARCHAR2  -- エラーコード
     ,iv_proc_from       IN    VARCHAR2  -- 処理年月FROM
     ,iv_proc_to         IN    VARCHAR2  -- 処理年月TO
     ,iv_prod_div        IN    VARCHAR2  -- 商品区分
     ,iv_item_div        IN    VARCHAR2  -- 品目区分
     ,iv_rcv_pay_div     IN    VARCHAR2  -- 受払区分
     ,iv_crowd_type      IN    VARCHAR2  -- 集計種別
     ,iv_crowd_code      IN    VARCHAR2  -- 群コード
     ,iv_acnt_crowd_code IN    VARCHAR2  -- 経理群コード
    );
--
END xxcmn770009c;
/
