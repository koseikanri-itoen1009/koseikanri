CREATE OR REPLACE PACKAGE xxcmn770002cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770002CP(spec)
 * Description      : 受払残高表（Ⅰ）製品(プロト)
 * MD.050/070       : 月次〆切処理帳票Issue1.0 (T_MD050_BPO_770)
 *                    月次〆切処理帳票Issue1.0 (T_MD070_BPO_77B)
 * Version          : 1.35
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
 *  2008/04/08    1.0   T.Hokama         新規作成
 *  2008/05/15    1.1   T.Endou          不具合ID11,13対応
 *                                       11 入力パラ、処理日yyyym対応
 *                                       13 ヘッダー部分の最大文字数制限の変更
 *  2008/05/30    1.2   R.Tomoyose       実際原価を抽出する時、原価管理区分が実際原価の場合、
 *                                       ロット管理の対象の場合はロット別原価テーブル
 *                                       ロット管理の対象外の場合は標準原価マスタテーブルより取得
 *  2008/06/12    1.3   Y.Ishikawa       生産原料詳細(アドオン)の結合が不要の為削除。
 *                                       取引区分名 = 仕入先返品は払出だが出力位置は受入の部分に
 *                                       出力する。
 *  2008/06/24    1.4   T.Endou          数量・金額項目がNULLでも0出力する。
 *                                       数量・金額の間を詰める。
 *  2008/06/25    1.5   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/08/05    1.6   R.Tomoyose       参照ビューの変更「xxcmn_rcv_pay_mst_porc_rma_v」→
 *                                                       「xxcmn_rcv_pay_mst_porc_rma02_v」
 *  2008/08/20    1.7   A.Shiina         T_TE080_BPO_770 指摘9対応
 *  2008/08/22    1.8   A.Shiina         T_TE080_BPO_770 指摘14対応
 *  2008/08/27    1.9   A.Shiina         T_TE080_BPO_770 指摘20対応
 *  2008/08/28    1.10  A.Shiina         取引数量は取得時に受払区分を掛ける。
 *  2008/08/28    1.11  A.Shiina         振替項目の+-表示修正。
 *  2008/10/08    1.12  N.Yoshida        T_S_492、T_S_524対応(PT対応)
 *  2008/10/24    1.13  H.Itou           T_S_492、T_S_524対応(PT対応)
 *  2008/10/31    1.14  Y.Suzuki         Tune(prc_get_report_data cursor8 , prc_create_xml_data fnc_get_item_unit_price,prc_get_inv_qty_amt)
 *  2008/11/04    1.15  N.Yoshida        移行リハ暫定対応
 *  2008/11/12    1.15  N.Fukuda         統合指摘#634対応(移行データ検証不具合対応)
 *  2008/11/17    1.16  A.Shiina         積送データの修正
 *  2008/11/19    1.17  N.Yoshida        I_S_684対応、移行データ検証不具合対応
 *  2008/11/25    1.18  A.Shiina         本番指摘52対応
 *  2008/12/03    1.19  A.Shiina         本番指摘361対応
 *  2008/12/05    1.20  H.Maru           本番障害492対応
 *  2008/12/07    1.21  N.Yoshida        本番障害数値あわせ対応(受注ヘッダの最新フラグを追加)
 *  2008/12/08    1.22  A.Shiina         本番障害565対応
 *  2008/12/09    1.23  H.Marushita      本番障害565対応
 *  2008/12/10    1.24  A.Shiina         本番障害617,636対応
 *  2008/12/11    1.25  N.Yoshida        本番障害580対応
 *  2008/12/12    1.26  N.Yoshida        本番障害669対応
 *  2008/12/12    1.27  A.Shiina         本番障害685対応
 *  2008/12/15    1.28  N.Yoshida        本番障害725対応
 *  2008/12/17    1.29  A.Shiina         本番障害774対応
 *  2008/12/18    1.30  N.Yoshida        本番障害773対応
 *  2008/12/19    1.31  A.Shiina         本番障害799対応
 *  2008/12/25    1.32  A.Shiina         本番障害674対応
 *  2009/03/05    1.33  Y.Yamamoto       本番障害1274対応
 *  2009/04/08    1.34  A.Shiina         本番障害1387対応
 *  2009/05/29    1.35  Marushita        本番障害1511対応
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
      errbuf                OUT    VARCHAR2         --   エラーメッセージ
     ,retcode               OUT    VARCHAR2         --   エラーコード
     ,iv_exec_year_month    IN     VARCHAR2         --   01 : 処理年月
     ,iv_goods_class        IN     VARCHAR2         --   02 : 商品区分
     ,iv_item_class         IN     VARCHAR2         --   03 : 品目区分
     ,iv_print_kind         IN     VARCHAR2         --   04 : 帳票種別
     ,iv_locat_code         IN     VARCHAR2         --   05 : 倉庫コード
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : 群種別
     ,iv_crowd_code         IN     VARCHAR2         --   07 : 群コード
     ,iv_acct_crowd_code    IN     VARCHAR2         --   08 : 経理群コード
    ) ;
END xxcmn770002cp ;
/
