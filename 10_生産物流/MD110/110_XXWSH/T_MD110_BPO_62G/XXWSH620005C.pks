CREATE OR REPLACE PACKAGE xxwsh620005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620005c(spec)
 * Description      : 生産物流（出荷）
 * MD.050/070       : 生産物流（出荷）Issue1.0  (T_MD050_BPO_401)
 *                    出庫指示確認表            (T_MD070_BPO_40I)
 * Version          : 1.0
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
 *  2008/05/12    1.0   Masakazu Yamashita    新規作成
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
      errbuf                OUT    VARCHAR2
     ,retcode               OUT    VARCHAR2
     ,iv_gyoumu_kbn         IN     VARCHAR2         -- 01:業務種別
     ,iv_block1             IN     VARCHAR2         -- 02:ブロック1
     ,iv_block2             IN     VARCHAR2         -- 03:ブロック2 
     ,iv_block3             IN     VARCHAR2         -- 04:ブロック3
     ,iv_deliver_from_code  IN     VARCHAR2         -- 05:出庫元
     ,iv_tanto_code         IN     VARCHAR2         -- 06:担当者コード
     ,iv_input_date         IN     VARCHAR2         -- 07:入力日付
     ,iv_input_time_from    IN     VARCHAR2         -- 08:入力時間FROM
     ,iv_input_time_to      IN     VARCHAR2         -- 09:入力時間TO
  );
END xxwsh620005c;
/