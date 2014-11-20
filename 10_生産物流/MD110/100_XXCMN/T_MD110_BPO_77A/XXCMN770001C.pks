CREATE OR REPLACE PACKAGE xxcmn770001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770001c(spec)
 * Description      : 受払残高表（Ⅰ）原料・資材・半製品
 * MD.050/070       : 月次〆切処理（経理）Issue1.0(T_MD050_BPO_770)
 *                    月次〆切処理（経理）Issue1.0(T_MD070_BPO_77A)
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
 *  2008/04/02    1.0   M.Inamine        新規作成
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
      errbuf                  OUT    VARCHAR2    -- エラーメッセージ
     ,retcode                 OUT    VARCHAR2    -- エラーコード
     ,iv_yyyymm               IN     VARCHAR2    -- 01 : 処理年月
     ,iv_product_class        IN     VARCHAR2    -- 02 : 商品区分
     ,iv_item_class           IN     VARCHAR2    -- 03 : 品目区分
     ,iv_report_type          IN     VARCHAR2    -- 04 : 帳票種別
     ,iv_whse_code            IN     VARCHAR2    -- 05 : 倉庫コード
     ,iv_group_type           IN     VARCHAR2    -- 06 : 群種別
     ,iv_group_code           IN     VARCHAR2    -- 07 : 群コード
     ,iv_accounting_grp_code  IN     VARCHAR2);  -- 08 : 経理群コード
END xxcmn770001c;
/