CREATE OR REPLACE PACKAGE xxpo360006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360006C(spec)
 * Description      : 仕入取引明細表
 * MD.050           : 有償支給帳票Issue1.0(T_MD050_BPO_360)
 * MD.070           : 有償支給帳票Issue1.0(T_MD070_BPO_36G)
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
 *  2008/03/13    1.0   K.Kamiyoshi      main 新規作成
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
      errbuf                OUT   VARCHAR2  -- エラーメッセージ
     ,retcode               OUT   VARCHAR2  -- エラーコード
     ,iv_out_flg            IN    VARCHAR2  --出力区分
     ,iv_deliver_from       IN    VARCHAR2  --納入日FROM
     ,iv_deliver_to         IN    VARCHAR2  --納入日TO
     ,iv_dept_code1         IN    VARCHAR2  --担当部署１
     ,iv_dept_code2         IN    VARCHAR2  --担当部署２
     ,iv_dept_code3         IN    VARCHAR2  --担当部署３
     ,iv_dept_code4         IN    VARCHAR2  --担当部署４
     ,iv_dept_code5         IN    VARCHAR2  --担当部署５
     ,iv_vendor_code1       IN    VARCHAR2  -- 取引先1
     ,iv_vendor_code2       IN    VARCHAR2  -- 取引先2
     ,iv_vendor_code3       IN    VARCHAR2  -- 取引先3
     ,iv_vendor_code4       IN    VARCHAR2  -- 取引先4
     ,iv_vendor_code5       IN    VARCHAR2  -- 取引先5
     ,iv_mediator_code1     IN    VARCHAR2  -- 斡旋者1
     ,iv_mediator_code2     IN    VARCHAR2  -- 斡旋者2
     ,iv_mediator_code3     IN    VARCHAR2  -- 斡旋者3
     ,iv_mediator_code4     IN    VARCHAR2  -- 斡旋者4
     ,iv_mediator_code5     IN    VARCHAR2  -- 斡旋者5
     ,iv_po_num             IN    VARCHAR2  -- 発注番号
     ,iv_item_code          IN    VARCHAR2  -- 品目コード
     ,iv_security_flg       IN    VARCHAR2  -- セキュリティ区分
    );
--
END xxpo360006c;
/
