CREATE OR REPLACE PACKAGE xxpo360005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360005C(spec)
 * Description      : 代行請求書（帳票）
 * MD.050/070       : 仕入（帳票）Issue1.0  (T_MD050_BPO_360)
 *                    代行請求書            (T_MD070_BPO_36F)
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
 *  2008/03/28    1.0   T.Endou          新規作成
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
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_deliver_from       IN     VARCHAR2         -- 納入日FROM
     ,iv_deliver_to         IN     VARCHAR2         -- 納入日TO
     ,iv_vendor_code1       IN     VARCHAR2         -- 取引先１
     ,iv_vendor_code2       IN     VARCHAR2         -- 取引先２
     ,iv_vendor_code3       IN     VARCHAR2         -- 取引先３
     ,iv_vendor_code4       IN     VARCHAR2         -- 取引先４
     ,iv_vendor_code5       IN     VARCHAR2         -- 取引先５
     ,iv_assen_vendor_code1 IN     VARCHAR2         -- 斡旋者１
     ,iv_assen_vendor_code2 IN     VARCHAR2         -- 斡旋者２
     ,iv_assen_vendor_code3 IN     VARCHAR2         -- 斡旋者３
     ,iv_assen_vendor_code4 IN     VARCHAR2         -- 斡旋者４
     ,iv_assen_vendor_code5 IN     VARCHAR2         -- 斡旋者５
     ,iv_dept_code1         IN     VARCHAR2         -- 担当部署１
     ,iv_dept_code2         IN     VARCHAR2         -- 担当部署２
     ,iv_dept_code3         IN     VARCHAR2         -- 担当部署３
     ,iv_dept_code4         IN     VARCHAR2         -- 担当部署４
     ,iv_dept_code5         IN     VARCHAR2         -- 担当部署５
     ,iv_security_flg       IN     VARCHAR2         -- セキュリティ区分
    ) ;
END xxpo360005c ;
/
