CREATE OR REPLACE
PACKAGE xxwsh400008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400008c(spec)
 * Description      : 生産物流（出荷）
 * MD.050/070       : 生産物流（出荷）Issue1.0  (T_MD050_BPO_401)
 *                    出荷調整表                (T_MD070_BPO_40I)
 * Version          : 1.5
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- --------------------- -------------------------------------------------
 *  Date          Ver.  Editor                Description
 * ------------- ----- --------------------- -------------------------------------------------
 *  2008/03/26    1.0   Masakazu Yamashita    新規作成
 *  2008/06/19    1.1   Yasuhisa Yamamoto     システムテスト障害対応
 *  2008/06/26    1.2   ToshikazuIshiwata     システムテスト障害対応(#309)
 *  2008/07/02    1.3   Naoki Fukuda          ST不具合対応(#373)
 *  2008/07/02    1.4   Satoshi Yunba         禁則文字対応
 *  2008/07/23    1.5   Naoki Fukuda          ST不具合対応(#475)
 *
 *****************************************************************************************/
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY PLS_INTEGER;
--
--################################  固定部 END   ###############################
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
      errbuf                OUT    VARCHAR2         -- エラーメッセージ
     ,retcode               OUT    VARCHAR2         -- エラーコード
     ,iv_syori_kbn          IN     VARCHAR2         -- 01 : 処理種別
     ,iv_kyoten_cd          IN     VARCHAR2         -- 02 : 拠点
     ,iv_shipped_locat      IN     VARCHAR2         -- 03 : 出庫元
     ,iv_arrival_date       IN     VARCHAR2         -- 04 : 着日
  );
END xxwsh400008c;
/