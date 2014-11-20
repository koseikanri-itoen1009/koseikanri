CREATE OR REPLACE PACKAGE xxwsh620002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620002c(spec)
 * Description      : 出庫配送依頼表
 * MD.050           : 引当/配車(帳票) T_MD050_BPO_620
 * MD.070           : 出庫配送依頼表 T_MD070_BPO_62C
 * Version          : 1.21
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
 *  2008/04/30    1.0   Yoshitomo Kawasaki 新規作成
 *  2008/06/04    1.1   Jun Nakada       出力担当部署の値をコードから名称に修正。GLOBAL変数名整理
 *                                       運送依頼元の名称を 部署=>会社名 から 会社名 => 部署に修正
 *  2008/06/12    1.2   Kazuo Kumamoto   パラメータ.業務種別によって抽出対象を選択
 *  2008/06/18    1.3   Kazuo Kumamoto   結合テスト障害対応
 *                                       (配送No未設定の場合は数量合計、混在重量、混載体積を出力しない)
 *  2008/06/23    1.4   Yoshikatsu Shindou 配送区分情報VIEWのリレーションを外部結合に変更
 *                                         (システムテスト不具合#229)
 *                                         小口区分が取得できない場合,重量容積合計をNULLとする。
 *  2008/07/02    1.5   Satoshi Yunba    禁則文字対応
 *  2008/07/04    1.6   Naoki Fukuda     ST不具合対応#394
 *  2008/07/04    1.7   Naoki Fukuda     ST不具合対応#409
 *  2008/07/07    1.8   Naoki Fukuda     ST不具合対応#337
 *  2008/07/09    1.9   Satoshi Takemoto 変更要求対応#92,#98
 *  2008/07/17    1.10  Kazuo Kumamoto   結合テスト障害対応
 *                                       1.10.1 パラメータ.品目区分未指定時の品目区分名を空欄とする。
 *                                       1.10.2 支給の配送先等の情報取得先を変更。
 *                                       1.10.3 配送先が混載している場合は全ての配送先を出力する。
 *  2008/07/17    1.11  Satoshi Takemoto 結合テスト不具合対応(変更要求対応#92,#98)
 *  2008/08/04    1.12  Takao Ohashi     結合出荷テスト(出荷追加_18,19,20)修正
 *  2008/10/27    1.13  Masayoshi Uehara 統合指摘297、T_TE080_BPO_620 指摘35指摘45指摘47
 *                                       T_S_501T_S_601T_S_607、T_TE110_BPO_230-001 指摘440
 *                                       課題#32 単位/入数換算の処理ロジック
 *  2008/11/07    1.14  Y.Yamamoto       統合指摘#143対応(数量0のデータを対象外とする)
 *  2008/11/13    1.15  Y.Yamamoto       統合指摘#595対応、内部変更#168
 *  2008/11/20    1.16  Y.Yamamoto       統合指摘#464、#686対応
 *  2008/11/27    1.17  A.Shiina         本番#185対応
 *  2009/01/23    1.18  N.Yoshida        本番#765対応
 *  2009/02/04    1.19  Y.Kanami         本番#41対応
 *                                       重量容積の計算でパレット重量加算を削除する
 *  2009/04/24    1.20  H.Itou           本番#1398対応
 *  2009/12/15    1.21  H.Itou           本稼動障害#XXXX対応
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
  PROCEDURE main(
     errbuf                     OUT    VARCHAR2         --  エラーメッセージ
    ,retcode                    OUT    VARCHAR2         --  エラーコード
    ,iv_dept                    IN     VARCHAR2         --  01 : 部署
    ,iv_plan_decide_kbn         IN     VARCHAR2         --  02 : 予定/確定区分
    ,iv_ship_from               IN     VARCHAR2         --  03 : 出庫日From
    ,iv_ship_to                 IN     VARCHAR2         --  04 : 出庫日To
    ,iv_shukko_haisou_kbn       IN     VARCHAR2         --  05 : 出庫/配送区分
    ,iv_gyoumu_shubetsu         IN     VARCHAR2         --  06 : 業務種別
    ,iv_notif_date              IN     VARCHAR2         --  07 : 確定通知実施日
    ,iv_notif_time_from         IN     VARCHAR2         --  08 : 確定通知実施時間From
    ,iv_notif_time_to           IN     VARCHAR2         --  09 : 確定通知実施時間To
    ,iv_freight_carrier_code    IN     VARCHAR2         --  10 : 運送業者
    ,iv_block1                  IN     VARCHAR2         --  11 : ブロック1
    ,iv_block2                  IN     VARCHAR2         --  12 : ブロック2
    ,iv_block3                  IN     VARCHAR2         --  13 : ブロック3
    ,iv_shipped_locat_code      IN     VARCHAR2         --  14 : 出庫元
    ,iv_mov_num                 IN     VARCHAR2         --  15 : 依頼No/移動No
    ,iv_shime_date              IN     VARCHAR2         --  16 : 締め実施日
    ,iv_shime_time_from         IN     VARCHAR2         --  17 : 締め実施時間From
    ,iv_shime_time_to           IN     VARCHAR2         --  18 : 締め実施時間To
    ,iv_online_kbn              IN     VARCHAR2         --  19 : オンライン対象区分
    ,iv_item_kbn                IN     VARCHAR2         --  20 : 品目区分
    ,iv_shukko_keitai           IN     VARCHAR2         --  21 : 出庫形態
    ,iv_unsou_irai_inzi_kbn     IN     VARCHAR2         --  22 : 運送依頼元印字区分
  );
END xxwsh620002c;
/
