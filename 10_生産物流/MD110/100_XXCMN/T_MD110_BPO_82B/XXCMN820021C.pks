CREATE OR REPLACE PACKAGE xxcmn820021c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN820021(spec)
 * Description      : 原価差異表作成
 * MD.050/070       : 標準原価マスタIssue1.0(T_MD050_BPO_820)
 *                    原価差異表作成Issue1.0(T_MD070_BPO_82B/T_MD070_BPO_82C)
 * Version          : 1.5
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
 *  2008/01/10    1.0   Masayuki Ikeda   新規作成
 *  2008/05/20    1.1   Masayuki Ikeda   内部変更要求#113対応
 *  2008/06/10    1.2   Kazuo Kumamoto   結合テスト障害対応(Null値によるテンプレート式エラー対応)
 *  2008/06/24    1.3   Kazuo Kumamoto   障害対応
 *                                       (1.3.1)システムテスト障害対応(仕入標準単価ヘッダ抽出条件追加)
 *                                       (1.3.2)結合テスト障害対応(ヘッダだけのページが出力される不具合の修正)
 *                                       (1.3.3)結合テスト障害対応(実質原価の算出方法変更)
 *  2008/06/30    1.4   Kazuo Kumamoto   システムテスト障害対応
 *                                       (1.4.1)ケース入り数が1件目しか出力されない不具合対応
 *                                       (1.4.2)「**項目計**」が「項目計」と出力される不具合対応
 *  2008/07/01    1.5   Marushita        ST不具合339対応製造日をロットマスタから取得
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
     ,iv_output_type        IN     VARCHAR2         -- 01 : 出力形式
     ,iv_fiscal_ym          IN     VARCHAR2         -- 02 : 対象年月
     ,iv_prod_div           IN     VARCHAR2         -- 03 : 商品区分
     ,iv_item_div           IN     VARCHAR2         -- 04 : 品目区分
     ,iv_dept_code          IN     VARCHAR2         -- 05 : 所属部署
     ,iv_crowd_code_01      IN     VARCHAR2         -- 06 : 群コード１
     ,iv_crowd_code_02      IN     VARCHAR2         -- 07 : 群コード２
     ,iv_crowd_code_03      IN     VARCHAR2         -- 08 : 群コード３
     ,iv_item_code_01       IN     VARCHAR2         -- 09 : 品目コード１
     ,iv_item_code_02       IN     VARCHAR2         -- 10 : 品目コード２
     ,iv_item_code_03       IN     VARCHAR2         -- 11 : 品目コード３
     ,iv_item_code_04       IN     VARCHAR2         -- 12 : 品目コード４
     ,iv_item_code_05       IN     VARCHAR2         -- 13 : 品目コード５
     ,iv_vendor_id_01       IN     VARCHAR2         -- 14 : 取引先ＩＤ１
     ,iv_vendor_id_02       IN     VARCHAR2         -- 15 : 取引先ＩＤ２
     ,iv_vendor_id_03       IN     VARCHAR2         -- 16 : 取引先ＩＤ３
     ,iv_vendor_id_04       IN     VARCHAR2         -- 17 : 取引先ＩＤ４
     ,iv_vendor_id_05       IN     VARCHAR2         -- 18 : 取引先ＩＤ５
    ) ;
END xxcmn820021c;
/
