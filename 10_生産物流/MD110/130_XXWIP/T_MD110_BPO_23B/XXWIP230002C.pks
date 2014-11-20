CREATE OR REPLACE
PACKAGE xxwip230002c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip230002(spec)
 * Description      : 生産帳票機能（生産日報）
 * MD.050/070       : 生産帳票機能（生産日報）Issue1.0  (T_MD050_BPO_230)
 *                    生産帳票機能（生産日報）          (T_MD070_BPO_23B)
 * Version          : 1.11
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
 *  2008/02/06    1.0   Ryouhei Fujii       新規作成
 *  2008/05/20    1.1   Yusuke  Tabata      内部変更要求(Seq95)日付型パラメータ型変換対応
 *  2008/05/29    1.2   Ryouhei Fujii       結合テスト不具合対応　NET換算パターン障害
 *  2008/06/04    1.3   Daisuke Nihei       結合テスト不具合対応　切／計込計算式不備対応
 *                                          結合テスト不具合対応　パーセント計算式不備対応
 *  2008/07/02    1.4   Satoshi Yunba       禁則文字対応
 *  2008/10/08    1.5   Daisuke  Nihei      T_TE080_BPO_230 No15対応 入力日時の結合先を作成日から更新日に変更する
 *  2008/12/02    1.6   Daisuke  Nihei      本番障害#325対応
 *  2008/12/17    1.7   Daisuke  Nihei      本番障害#709対応
 *  2008/12/24    1.8   Akiyoshi Shiina     本番障害#849,#823対応
 *  2008/12/25    1.9   Akiyoshi Shiina     本番障害#823再対応
 *  2009/02/04    1.10  Yasuhisa Yamamoto   本番障害#4対応 ランク３出力対応
 *  2009/11/24    1.11  Hitomi Itou         本番障害#1696対応 入力パラメータFROM-TO片方のみは不可
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
     ,iv_den_kbn            IN     VARCHAR2         -- 01 : 伝票区分
     ,iv_plant              IN     VARCHAR2         -- 02 : プラント
     ,iv_line_no            IN     VARCHAR2         -- 03 : ラインNo
     ,iv_make_date_from     IN     VARCHAR2         -- 04 : 生産日(FROM)
     ,iv_make_date_to       IN     VARCHAR2         -- 05 : 生産日(TO)
     ,iv_tehai_no_from      IN     VARCHAR2         -- 06 : 手配No(FROM)
     ,iv_tehai_no_to        IN     VARCHAR2         -- 07 : 手配No(TO)
     ,iv_hinmoku_cd         IN     VARCHAR2         -- 08 : 品目コード
     ,iv_input_date_from    IN     VARCHAR2         -- 09 : 入力日時(FROM)
     ,iv_input_date_to      IN     VARCHAR2         -- 10 : 入力日時(TO)
  );
END xxwip230002c;
/
