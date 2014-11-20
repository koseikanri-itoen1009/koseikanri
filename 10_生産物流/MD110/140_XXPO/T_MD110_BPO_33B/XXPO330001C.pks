CREATE OR REPLACE PACKAGE xxpo330001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo330001c(SPEC)
 * Description      : 仕入・有償支給（仕入先返品）
 * MD.050/070       : 仕入・有償支給（仕入先返品）Issue2.0  (T_MD050_BPO_330)
 *                    返品指示書                            (T_MD070_BPO_33B)
 * Version          : 1.6
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
 *  2008/01/21    1.0   Yusuke Tabata   新規作成
 *  2008/04/28    1.1   Yusuke Tabata   内部変更#43／TE080不具合対応
 *  2008/05/01    1.2   Yasuhisa Yamamoto TE080不具合対応(330_8)
 *  2008/05/02    1.3   Yasuhisa Yamamoto TE080不具合対応(330_10)
 *  2008/05/02    1.4   Yasuhisa Yamamoto TE080不具合対応(330_11)
 *  2008/06/30    1.5   Yohei  Takayama   ST不具合#92対応
 *  2008/07/07    1.6   Satoshi Yunba     禁則文字対応
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
     ,iv_rtn_number         IN     VARCHAR2         --   01 : 返品番号
     ,iv_dept_code          IN     VARCHAR2         --   02 : 担当部署
     ,iv_tantousya_code     IN     VARCHAR2         --   03 : 担当者
     ,iv_creation_date_from IN     VARCHAR2         --   04 : 作成日時FROM
     ,iv_creation_date_to   IN     VARCHAR2         --   05 : 作成日時TO
     ,iv_vendor_code        IN     VARCHAR2         --   06 : 取引先
     ,iv_assen_code         IN     VARCHAR2         --   07 : 斡旋者
     ,iv_location_code      IN     VARCHAR2         --   08 : 納入先
     ,iv_rtn_date_from      IN     VARCHAR2         --   09 : 返品日FROM
     ,iv_rtn_date_to        IN     VARCHAR2         --   10 : 返品日TO
     ,iv_prod_div           IN     VARCHAR2         --   11 : 商品区分
     ,iv_item_div           IN     VARCHAR2         --   12 : 品目区分
    ) ;
END xxpo330001c;
/
