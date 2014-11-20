CREATE OR REPLACE PACKAGE xxpo780001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo780001c(spec)
 * Description      : 月次〆切処理（有償支給相殺）
 * MD.050/070       : 月次〆切処理（有償支給相殺）Issue1.0  (T_MD050_BPO_780)
 *                    計算書                                (T_MD070_BPO_78A)
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
 *  2007/12/03    1.0   Masayuki Ikeda   新規作成
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
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         --   エラーメッセージ
     ,retcode               OUT    VARCHAR2         --   エラーコード
     ,iv_fiscal_ym          IN     VARCHAR2         --   01 : 〆切年月
     ,iv_dept_code          IN     VARCHAR2         --   02 : 請求管理部署
     ,iv_vendor_code        IN     VARCHAR2         --   03 : 取引先
    ) ;
END xxpo780001c;
/
