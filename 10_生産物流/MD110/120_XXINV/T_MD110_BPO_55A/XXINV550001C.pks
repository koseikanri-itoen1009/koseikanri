CREATE OR REPLACE PACKAGE xxinv550001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv550001c(spec)
 * Description      : 在庫（帳票）
 * MD.050/070       : 在庫（帳票）Issue1.0  (T_MD050_BPO_550)
 *                    受払残高リスト        (T_MD070_BPO_55A)
 * Version          : 1.44
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
 *  2008/02/01    1.0   Yasuhisa Yamamoto  新規作成
 *  2008/05/07    1.1   Yasuhisa Yamamoto  変更要求対応(Seq83)
 *  2008/05/09    1.2   Yasuhisa Yamamoto  結合テスト障害対応(抽出データ有差異データ無対応)
 *  2008/05/09    1.3   Yasuhisa Yamamoto  結合テスト障害対応(棚卸結果テーブルLotID NULL対応)
 *  2008/05/20    1.4   Yusuke   Tabata    内部変更要求(Seq95)日付型パラメータ型変換対応
 *  2008/05/20    1.5   Kazuo Kumamoto     結合テスト障害対応(品目原価マスタ未登録対応)
 *  2008/05/20    1.6   Kazuo Kumamoto     結合テスト障害対応(棚卸スナップショット例外キャッチ)
 *  2008/05/21    1.7   Kazuo Kumamoto     結合テスト障害対応(合計数量ALL0は除外)
 *  2008/05/21    1.8   Kazuo Kumamoto     結合テスト障害対応(実棚月末在庫数の算出不具合)
 *  2008/05/26    1.9   Kazuo Kumamoto     結合テスト障害対応(単位出力のズレ)
 *  2008/05/26    1.10  Kazuo Kumamoto     結合テスト障害対応(品目計出力条件変更)
 *  2008/06/07    1.11  Yasuhisa Yamamoto  結合テスト障害対応(抽出データ不正対応)
 *  2008/06/20    1.12  Kazuo Kumamoto     システムテスト障害対応(パラメータ条件指定の不具合)
 *  2008/07/02    1.13  Satoshi Yunba      禁則文字対応
 *  2008/07/08    1.14  Yasuhisa Yamamoto  結合テスト障害対応(ADJI文書IDのNULL対応、入出庫数量0の出力対応)
 *  2008/08/28    1.15  Oracle 山根 一浩   PT 2_1_12 #33,T_S_503対応
 *  2008/09/05    1.16  Yasuhisa Yamamoto  PT 2_1_12 再改修
 *  2008/09/17    1.17  Yasuhisa Yamamoto  PT 2_1_12 #63
 *  2008/09/19    1.18  Yasuhisa Yamamoto  T_TE080_BPO_550 #32#33,T_S_466,変更#171
 *  2008/09/22    1.19  Yasuhisa Yamamoto  PT 2_1_12 #63 再改修
 *  2008/10/02    1.20  Yasuhisa Yamamoto  PT 2-1_12 #85
 *  2008/10/22    1.21  Yasuhisa Yamamoto  仕様不備障害 T_S_492
 *  2008/11/10    1.22  Yasuhisa Yamamoto  統合指摘 #536、#547対応
 *  2008/11/17    1.23  Yasuhisa Yamamoto  統合指摘 #659対応
 *  2008/12/02    1.24  Yasuhisa Yamamoto  本番指摘 #321対応
 *  2008/12/04    1.25  Hitomi Itou        本番指摘 #362対応
 *  2008/12/07    1.26  Natsuki Yoshida    本番指摘 #520対応
 *  2008/12/07    1.27  Yasuhisa Yamamoto  統合指摘 #503,509対応
 *  2008/12/07    1.28  Yasuhisa Yamamoto  統合指摘 #509対応
 *  2008/12/07    1.29  Yasuhisa Yamamoto  統合指摘 #466対応
 *  2008/12/09    1.30  Yasuhisa Yamamoto  統合指摘 #472対応
 *  2008/12/09    1.31  Yasuhisa Yamamoto  統合指摘 #472対応
 *  2008/12/10    1.32  Yasuhisa Yamamoto  統合指摘 #627対応
 *  2008/12/16    1.33  Akiyoshi Shiina    統合指摘 #742対応
 *  2008/12/19    1.34  Yasuhisa Yamamoto  統合指摘 #732対応
 *  2008/12/25    1.35  Yasuhisa Yamamoto  統合指摘 #674対応
 *  2008/12/29    1.36  Akiyoshi Shiina    統合指摘 #809対応
 *  2008/12/30    1.37  Yasuhisa Yamamoto  本番指摘 #898対応
 *  2009/01/05    1.38  Takao    Ohashi    本番指摘 #911対応
 *  2008/01/07    1.39  Yasuhisa Yamamoto  本番指摘 #945対応
 *  2008/01/08    1.40  Yasuhisa Yamamoto  本番指摘 #957対応
 *  2008/02/10    1.41  Yukari Kanami      本番指摘 #1168対応
 *  2009/02/13    1.42  Yasuhisa Yamamoto  本番指摘 #1186対応
 *  2009/08/05    1.43  Masayuki Nomura    本番指摘 #1592対応
 *  2009/11/06    1.44  Yukiko Fukami      本番指摘 #1685対応
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
     ,iv_date_ym            IN     VARCHAR2         -- 01 : 対象年月
     ,iv_whse_dept1         IN     VARCHAR2         -- 02 : 倉庫管理部署1
     ,iv_whse_dept2         IN     VARCHAR2         -- 03 : 倉庫管理部署2
     ,iv_whse_dept3         IN     VARCHAR2         -- 04 : 倉庫管理部署3
     ,iv_whse_code1         IN     VARCHAR2         -- 05 : 倉庫コード1
     ,iv_whse_code2         IN     VARCHAR2         -- 06 : 倉庫コード2
     ,iv_whse_code3         IN     VARCHAR2         -- 07 : 倉庫コード3
     ,iv_block_code1        IN     VARCHAR2         -- 08 : ブロック1
     ,iv_block_code2        IN     VARCHAR2         -- 09 : ブロック2
     ,iv_block_code3        IN     VARCHAR2         -- 10 : ブロック3
     ,iv_item_class         IN     VARCHAR2         -- 11 : 商品区分
     ,iv_um_class           IN     VARCHAR2         -- 12 : 単位区分
     ,iv_item_div           IN     VARCHAR2         -- 13 : 品目区分
     ,iv_item_no1           IN     VARCHAR2         -- 14 : 品目コード1
     ,iv_item_no2           IN     VARCHAR2         -- 15 : 品目コード2
     ,iv_item_no3           IN     VARCHAR2         -- 16 : 品目コード3
     ,iv_create_date1       IN     VARCHAR2         -- 17 : 製造年月日1
     ,iv_create_date2       IN     VARCHAR2         -- 18 : 製造年月日2
     ,iv_create_date3       IN     VARCHAR2         -- 19 : 製造年月日3
     ,iv_lot_no1            IN     VARCHAR2         -- 20 : ロットNo1
     ,iv_lot_no2            IN     VARCHAR2         -- 21 : ロットNo2
     ,iv_lot_no3            IN     VARCHAR2         -- 22 : ロットNo3
     ,iv_output_ctl         IN     VARCHAR2         -- 23 : 差異データ区分
     ,iv_inv_ctrl           IN     VARCHAR2         -- 24 : 名義
    ) ;
END xxinv550001c;
/
