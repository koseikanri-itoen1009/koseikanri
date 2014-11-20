CREATE OR REPLACE PACKAGE xxcmn770003cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770003CP(spec)
 * Description      : 受払残高表（Ⅱ）(プロト)
 * MD.050/070       : 月次〆切処理帳票Issue1.0(T_MD050_BPO_770)
 *                  : 月次〆切処理帳票Issue1.0(T_MD070_BPO_77C)
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
 *  2008/04/08    1.0   Y.Majikina       新規作成
 *  2008/05/15    1.1   Y.Majikina       パラメータ：処理年月がYYYYMで入力された時、エラー
 *                                       となる点を修正。
 *                                       担当部署、担当者名の最大長処理を修正。
 *  2008/05/30    1.2   Y.Ishikawa       実際原価を抽出する時、原価管理区分が実際原価の場合、
 *                                       ロット管理の対象の場合はロット別原価テーブル
 *                                       ロット管理の対象外の場合は標準原価マスタテーブルより取得
 *
 *  2008/06/12    1.3   I.Higa           取引区分が"棚卸増"または"棚卸減"の場合、マイナスデータが
 *                                       入っているので絶対値計算を行わず、設定値で集計を行う。
 *  2008/06/13    1.4   Y.Ishikawa       生産原料詳細(アドオン)の結合が不要の為削除。
 *  2008/06/24    1.5   Y.Ishikawa       金額、数量がNULLの場合は0を表示する。
 *  2008/06/25    1.6   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/08/05    1.7   R.Tomoyose       参照ビューの変更「xxcmn_rcv_pay_mst_porc_rma_v」→
 *                                                       「xxcmn_rcv_pay_mst_porc_rma03_v」
 *  2008/08/28    1.8   A.Shiina         取引数量は取得時に受払区分を掛ける。
 *  2008/10/22    1.9   N.Yoshida        T_S_524対応(PT対応)
 *  2008/11/04    1.10  N.Yoshida        移行リハ暫定対応
 *  2008/11/12    1.11  N.Fukuda         統合指摘#634対応(移行データ検証不具合対応)
 *  2008/11/19    1.12  N.Yoshida        I_S_684対応、移行データ検証不具合対応
 *  2008/12/08    1.13  H.Marushita      本番数値検証受注ヘッダ最新フラグおよび標準原価計算修正
 *  2008/12/08    1.14  A.Shiina         本番#562対応
 *  2008/12/11    1.15  N.Yoshida        本番障害580対応
 *  2008/12/12    1.16  N.Yoshida        本番障害669対応
 *  2009/01/13    1.17  N.Yoshida        本番障害997対応
 *  2009/03/05    1.18  H.Marushita      本番障害1274対応
 *  2009/05/29    1.19  Marushita        本番障害1511対応
 *  2009/08/12    1.20  Marushita        本番障害1608対応
 *  2009/09/07    1.21  Marushita        本番障害1639対応
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
      errbuf                OUT   VARCHAR2,  -- エラーメッセージ
      retcode               OUT   VARCHAR2,  -- エラーコード
      iv_process_year       IN    VARCHAR2,  -- 処理年月
      iv_item_division      IN    VARCHAR2,  -- 商品区分
      iv_art_division       IN    VARCHAR2,  -- 品目区分
      iv_report_type        IN    VARCHAR2,  -- レポート区分
      iv_warehouse_code     IN    VARCHAR2,  -- 倉庫コード
      iv_crowd_type         IN    VARCHAR2,  -- 群種別
      iv_crowd_code         IN    VARCHAR2,  -- 群コード
      iv_account_code       IN    VARCHAR2   -- 経理群コード
    );
--
END xxcmn770003cp;
/
