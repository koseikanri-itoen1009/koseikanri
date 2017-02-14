CREATE OR REPLACE PACKAGE xxwsh620005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620005c(spec)
 * Description      : 生産物流（出荷）
 * MD.050/070       : 生産物流（出荷）          (T_MD050_BPO_401)
 *                    出庫指示確認表            (T_MD070_BPO_40I)
 * Version          : 1.12
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
 *  2008/06/04    1.1   Jun Nakada            クイックコード警告区分の結合を外部結合に変更(出荷移動)
 *  2008/06/17    1.2   Masao Hokkanji        システムテスト不具合No150対応
 *  2008/06/18    1.3   Kazuo Kumamoto        事業所情報VIEWの結合を外部結合に変更
 *  2008/06/19    1.4   SCS yamane            配車配送情報VIEWの結合を外部結合に変更
 *  2008/07/02    1.5   Akiyoshi Shiina       変更要求対応#92
 *                                            禁則文字「'」「"」「<」「>」「＆」対応
 *  2008/07/11    1.6   Kazuo Kumamoto        結合テスト障害対応(単位出力制御)
 *  2008/08/05    1.7   Yasuhisa Yamamoto     内部変更要求対応
 *  2008/09/25    1.8   Yasuhisa Yamamoto     T_TE080_BPO_620 #36,41、使用不備障害T_S_479,501
 *  2008/11/14    1.9   Naoki Fukuda          課題#62(内部変更#168)対応(指示無し実績を除外する)
 *  2009/05/28    1.10  Hitomi Itou           本番障害#1398
 *  2009/09/14    1.11  Hitomi Itou           本番障害#1632
 *  2017/01/27    1.12  Shigeto Niki          E_本稼動_14014
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
-- v1.12 ADD Start
     ,iv_reserve_class      IN     VARCHAR2         -- 10:手動のみ
-- v1.12 ADD End
  );
END xxwsh620005c;
/
