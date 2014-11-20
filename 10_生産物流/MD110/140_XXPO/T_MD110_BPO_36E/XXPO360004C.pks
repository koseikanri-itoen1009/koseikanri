CREATE OR REPLACE PACKAGE xxpo360004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360004C(spec)
 * Description      : 仕入明細表
 * MD.050/070       : 有償支給帳票Issue1.0(T_MD050_BPO_360)
 *                  : 有償支給帳票Issue1.0(T_MD070_BPO_36E)
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
 *  2008/03/17    1.0   Y.Majikina       新規作成
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
      iv_deliver_from       IN    VARCHAR2,  -- 納入日FROM
      iv_deliver_to         IN    VARCHAR2,  -- 納入日TO
      iv_item_division      IN    VARCHAR2,  -- 商品区分
      iv_dept_code          IN    VARCHAR2,  -- 担当部署
      iv_vendor_code1       IN    VARCHAR2,  -- 取引先1
      iv_vendor_code2       IN    VARCHAR2,  -- 取引先2
      iv_vendor_code3       IN    VARCHAR2,  -- 取引先3
      iv_vendor_code4       IN    VARCHAR2,  -- 取引先4
      iv_vendor_code5       IN    VARCHAR2,  -- 取引先5
      iv_art_division       IN    VARCHAR2,  -- 品目区分
      iv_crowd1             IN    VARCHAR2,  -- 群1
      iv_crowd2             IN    VARCHAR2,  -- 群2
      iv_crowd3             IN    VARCHAR2,  -- 群3
      iv_art1               IN    VARCHAR2,  -- 品目1
      iv_art2               IN    VARCHAR2,  -- 品目2
      iv_art3               IN    VARCHAR2,  -- 品目3
      iv_security_flg       IN    VARCHAR2   -- セキュリティ区分
    );
--
END xxpo360004c;
/
