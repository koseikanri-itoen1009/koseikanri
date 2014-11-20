create or replace
PACKAGE xxwip230001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxwip230001c(spec)
 * Description      : 生産帳票機能（生産依頼書兼生産指図書）
 * MD.050/070       : 生産帳票機能（生産依頼書兼生産指図書）Issue1.0  (T_MD050_BPO_230)
 *                    生産帳票機能（生産依頼書兼生産指図書）          (T_MD070_BPO_23A)
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2007/12/13    1.0   Masakazu Yamashita  新規作成
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
     ,iv_den_kbn            IN     VARCHAR2         -- 01 : 伝票区分
     ,iv_chohyo_kbn         IN     VARCHAR2         -- 02 : 帳票区分
     ,iv_plant              IN     VARCHAR2         -- 03 : プラント
     ,iv_line_no            IN     VARCHAR2         -- 04 : ラインNo
     ,iv_make_plan_from     IN     VARCHAR2         -- 05 : 生産予定日(FROM)
     ,iv_make_plan_to       IN     VARCHAR2         -- 06 : 生産予定日(TO)
     ,iv_tehai_no_from      IN     VARCHAR2         -- 07 : 手配No(FROM)
     ,iv_tehai_no_to        IN     VARCHAR2         -- 08 : 手配No(TO)
     ,iv_hinmoku_cd         IN     VARCHAR2         -- 09 : 品目コード
     ,iv_input_date_from    IN     VARCHAR2         -- 10 : 入力日時(FROM)
     ,iv_input_date_to      IN     VARCHAR2         -- 11 : 入力日時(TO)
    ) ;
END xxwip230001c;
/