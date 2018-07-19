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
 * Version          : 1.12
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
 *  2008/05/20    1.1   Yusuke   Tabata     内部変更要求Seq95(日付型パラメータ型変換)対応
 *  2008/05/20    1.2   Daisuke  Nihei      結合テスト不具合対応（資材：依頼数が表示されない）
 *  2008/05/30    1.3   Daisuke  Nihei      結合テスト不具合対応（条件：予定区分不備)
 *  2008/06/04    1.4   Daisuke  Nihei      結合テスト不具合対応（生産指示書表示不正)
 *  2008/07/02    1.5   Satoshi  Yunba      禁則文字対応
 *  2008/07/18    1.6   Hitomi   Itou       結合テスト 指摘23対応 生産依頼書の時、保留中・手配済も対象とする
 *  2008/07/18    1.7   Daisuke  Nihei      統合障害#183対応 入力日時の結合先を作成日から更新日に変更する
 *                                          統合障害#196対応 一度引き当ててある品目のデフォルトロットを表示しない
 *                                          T_TE080_BPO_230 No15対応 生産指図書の時、手配済も対象とする
 *                                          統合障害#499対応 製造日、在庫入数の参照先変更
 *  2009/01/16    1.8   Daisuke  Nihei      本番障害#1032対応 生産指図書を「確定済」でも出力する
 *  2009/02/02    1.9   Daisuke  Nihei      本番障害#1111対応
 *  2009/02/04    1.10  Yasuhisa Yamamoto   本番障害#4対応 ランク３出力対応
 *  2018/07/11    1.12  H.Sasaki            E_本稼動_15158 製造日を賞味期限に変更（データ抽出部のみ変更し、PG内の変数名などはそのままとする）
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
--  V1.12 2018/07/11 Added START
     ,iv_concurrent_type    IN     VARCHAR2         -- 12 : コンカレント区分
--  V1.12 2018/07/11 Added END
    ) ;
END xxwip230001c;
/
