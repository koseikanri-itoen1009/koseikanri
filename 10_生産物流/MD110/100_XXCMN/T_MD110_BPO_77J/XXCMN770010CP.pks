create or replace PACKAGE xxcmn770010cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770010CP(spec)
 * Description      : 標準原価内訳表(プロト)
 * MD.050/070       : 月次〆切処理帳票Issue1.0 (T_MD050_BPO_770)
 *                    月次〆切処理帳票Issue1.0 (T_MD070_BPO_77J)
 * Version          : 1.26
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
 *  2008/04/14    1.0   N.Chinen         新規作成
 *  2008/05/13    1.1   N.Chinen         着荷日でデータを抽出するよう修正。
 *  2008/05/16    1.2   Y.Majikina       パラメータ：処理年月がYYYYMで入力されるとエラーと
 *                                       なる点を修正。
 *  2008/06/12    1.3   Y.Ishikawa       生産原料詳細(アドオン)の結合が不要の為削除
 *  2008/06/19    1.4   Y.Ishikawa       取引区分が廃却、見本に関しては、受払区分を掛けない
 *  2008/06/19    1.5   Y.Ishikawa       金額、数量がNULLの場合は0を表示する。
 *  2008/06/25    1.6   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/07/23    1.7   Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_V→XXCMN_ITEM_CATEGORIES6_V変更
 *  2008/08/07    1.8   Y.Majikina       参照するVIEWをXXCMN_RCV_PAY_MST_PORC_RMA_V →
 *                                       XXCMN_RCV_PAY_MST_PORC_RMA10_Vへ変更
 *  2008/08/28    1.9   A.Shiina         T_TE080_BPO_770 指摘19対応
 *  2008/10/23    1.10  N.Yoshida        T_S_524対応(PT対応)
 *  2008/11/14    1.11  N.Yoshida        移行データ検証不具合対応
 *  2008/11/19    1.12  N.Yoshida        I_S_684対応、移行データ検証不具合対応
 *  2008/11/29    1.13  N.Yoshida        本番#215対応
 *  2008/12/02    1.14  N.Yoshida        本番障害対応(振替入庫、緑営１、緑営２追加対応)
 *  2008/12/06    1.15  T.Miyata         本番#495対応
 *  2008/12/06    1.16  T.Miyata         本番#498対応
 *  2008/12/07    1.17  N.Yoshida        本番#496対応
 *  2008/12/11    1.18  A.Shiina         本番#580対応
 *  2008/12/13    1.19  T.Ohashi         本番#580対応
 *  2008/12/14    1.20  N.Yoshida        本番障害669対応
 *  2008/12/15    1.21  N.Yoshida        本番障害727対応
 *  2008/12/22    1.22  N.Yoshida        本番障害825、828対応
 *  2009/01/15    1.23  N.Yoshida        本番障害1023対応
 *  2009/03/10    1.24  A.Shiina         本番障害1298対応
 *  2009/04/10    1.25  A.Shiina         本番障害1396対応
 *  2009/05/29    1.26  Marushita        本番障害1511対応
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
     ,iv_exec_date_from     IN     VARCHAR2         --   01 : 処理年月(from)
     ,iv_exec_date_to       IN     VARCHAR2         --   02 : 処理年月(to)
     ,iv_goods_class        IN     VARCHAR2         --   03 : 商品区分
     ,iv_item_class         IN     VARCHAR2         --   04 : 品目区分
     ,iv_rcv_pay_div        IN     VARCHAR2         --   05 : 受払区分
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : 集計種別
     ,iv_crowd_code         IN     VARCHAR2         --   07 : 群コード
     ,iv_acct_crowd_code    IN     VARCHAR2         --   08 : 経理群コード
    );
END xxcmn770010cp;
/
