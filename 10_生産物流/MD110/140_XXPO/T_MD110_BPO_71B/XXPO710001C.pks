CREATE OR REPLACE PACKAGE xxpo710001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxpo710001c(spec)
 * Description      : 生産物流（仕入）
 * MD.050/070       : 生産物流（仕入）Issue1.0  (T_MD050_BPO_710)
 *                    荒茶製造表                (T_MD070_BPO_71B)
 * Version          : 1.4
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
 *  2007/12/28    1.0   Yasuhisa Yamamoto  新規作成
 *  2008/05/02    1.1   Yasuhisa Yamamoto  結合テスト障害対応(710_10)
 *  2008/05/19    1.2   Masayuki Ikeda     内部変更要求#62対応
 *  2008/05/20    1.3   Yohei    Takayama  結合テスト障害対応(710_11)
 *  2008/07/02    1.4   Satoshi Yunba      禁則文字「'」「"」「<」「>」「&」対応
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
     ,iv_entry_num          IN     VARCHAR2         -- 04 : 伝票NO
     ,iv_item_code          IN     VARCHAR2         -- 05 : 仕上品目
     ,iv_department_code    IN     VARCHAR2         -- 06 : 入力部署
     ,iv_employee_number    IN     VARCHAR2         -- 07 : 入力担当者
     ,iv_input_date_from    IN     VARCHAR2         -- 08 : 入力期間FROM
     ,iv_input_date_to      IN     VARCHAR2         -- 09 : 入力期間TO
    ) ;
END xxpo710001c;
/
