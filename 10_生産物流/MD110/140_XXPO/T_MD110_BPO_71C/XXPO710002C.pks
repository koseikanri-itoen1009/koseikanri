CREATE OR REPLACE PACKAGE xxpo710002c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo710002c(spec)
 * Description      : 生産物流（仕入）
 * MD.050/070       : 生産物流（仕入）Issue1.0  (T_MD050_BPO_710)
 *                    荒茶製造表累計            (T_MD070_BPO_71C)
 * Version          : 1.2
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/01/22    1.0   Yasuhisa Yamamoto  新規作成
 *  2008/05/20    1.1   Yohei    Takayama  結合テスト対応(710_11)
 *  2008/07/02    1.2   Satoshi Yunba      禁則文字対応
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
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_report_type        IN     VARCHAR2         -- 01 : 帳票種別
     ,iv_creat_date_from    IN     VARCHAR2         -- 02 : 製造期間FROM
     ,iv_creat_date_to      IN     VARCHAR2         -- 03 : 製造期間TO
    ) ;
END xxpo710002c;
/
