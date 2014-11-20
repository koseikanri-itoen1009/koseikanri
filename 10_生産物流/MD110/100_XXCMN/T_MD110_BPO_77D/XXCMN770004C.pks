CREATE OR REPLACE PACKAGE xxcmn770004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770004C(spec)
 * Description      : 受払その他実績リスト
 * MD.050/070       : 月次〆切処理帳票Issue1.0 (T_MD050_BPO_770)
 *                    月次〆切処理帳票Issue1.0 (T_MD070_BPO_77D)
 * Version          : 1.24
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
 *  2008/04/09    1.0   C.Kinjo          新規作成
 *  2008/05/12    1.1   M.Hamamoto       着荷日の抽出が行われていない
 *  2008/05/16    1.2   T.Endou          不具合ID:5,6,7,8対応
 *                                       5 YYYYMでも正常に抽出されるように修正
 *                                       6 ヘッダの出力日付と「担当：」を合わせました
 *                                       7 帳票名が＜帳票ID＞の下にしました
 *                                       8 品目区分名称、商品区分名称の文字最大長を考慮しました
 *  2008/05/28    1.3   Y.Ishikawa       ロット管理外の場合、ロット情報はNULLを出力する。
 *  2008/05/30    1.4   Y.Ishikawa       実際原価を抽出する時、原価管理区分が実際原価の場合、
 *                                       ロット管理の対象の場合はロット別原価テーブル
 *                                       ロット管理の対象外の場合は標準原価マスタテーブルより取得
 *  2008/06/13    1.5   T.Endou          着荷日が無い場合は、予定着荷日を使用する
 *                                       生産原料詳細（アドオン）を結合条件から外す
 *  2008/06/19    1.6   Y.Ishikawa       取引区分が廃却、見本に関しては、受払区分を掛けない
 *  2008/06/25    1.7   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/08/07    1.8   R.Tomoyose       参照ビューの変更「xxcmn_rcv_pay_mst_porc_rma_v」→
 *                                                       「xxcmn_rcv_pay_mst_porc_rma04_v」
 *  2008/08/20    1.9   A.Shiina         結合指摘#14対応
 *  2008/10/27    1.10  A.Shiina         T_S_524対応
 *  2008/11/11    1.11  A.Shiina         移行不具合修正
 *  2008/11/19    1.12  N.Yoshida        I_S_684対応、移行データ検証不具合対応
 *  2008/11/29    1.13  N.Yoshida        本番#210対応
 *  2008/12/03    1.14  H.Itou           本番#384対応
 *  2008/12/04    1.15  T.Miyata         本番#454対応
 *  2008/12/08    1.16  T.Ohashi         本番障害数値あわせ対応
 *  2008/12/11    1.17  N.Yoshida        本番障害580対応
 *  2008/12/13    1.18  T.Ohashi         本番障害580対応
 *  2008/12/14    1.19  N.Yoshida        本番障害669対応
 *  2008/12/19    1.20  A.Shiina         本番障害812対応
 *                                       実際原価の取得先変更 「xxcmn_lot_cost.unit_ploce」⇒
 *                                                            「ic_lots_mst.attribute7」 
 *  2008/12/22    1.21  A.Shiina         本番障害719対応
 *  2008/03/06    1.22  H.Marushita      本番障害1274対応
 *  2009/05/29    1.23  Marushita        本番障害1511対応
 *  2009/11/09    1.24  Marushita        本番障害1685対応
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
      errbuf                OUT    VARCHAR2         --   エラーメッセージ
     ,retcode               OUT    VARCHAR2         --   エラーコード
     ,iv_exec_year_month    IN     VARCHAR2         --   01 : 処理年月
     ,iv_goods_class        IN     VARCHAR2         --   02 : 商品区分
     ,iv_item_class         IN     VARCHAR2         --   03 : 品目区分
     ,iv_div_type1          IN     VARCHAR2         --   04 : 受払区分１
     ,iv_div_type2          IN     VARCHAR2         --   05 : 受払区分２
     ,iv_div_type3          IN     VARCHAR2         --   06 : 受払区分３
     ,iv_div_type4          IN     VARCHAR2         --   07 : 受払区分４
     ,iv_div_type5          IN     VARCHAR2         --   08 : 受払区分５
     ,iv_reason_code        IN     VARCHAR2         --   09 : 事由コード
    ) ;
END xxcmn770004c ;
/
