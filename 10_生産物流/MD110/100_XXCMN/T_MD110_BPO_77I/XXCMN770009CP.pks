create or replace PACKAGE xxcmn770009cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770009cp(spec)
 * Description      : 他勘定振替原価差異表
 * MD.050/070       : 月次〆切処理帳票Issue1.0(T_MD050_BPO_770)
 *                  : 月次〆切処理帳票Issue1.0(T_MD070_BPO_77I)
 * Version          : 1.19
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
 *  2008/04/19    1.0   M.Hamamoto       新規作成
 *  2008/05/16    1.1   M.Hamamoto       パラメータ：処理年月がYYYYMで入力されるとエラーになる
 *                                       点を修正。
 *                                       帳票に出力されているのは、パラメータの処理年月のみで
 *                                       入力パラメータに200804ではなく、20084とすると正常に抽出
 *                                       されるが、ヘッダの処理年月が帳票出力時に書式’YYYY/MM
 *                                       ’へ変換されるよう修正。
 *  2008/05/31    1.2   M.Hamamoto       原価取得方法を修正。
 *  2008/06/19    1.3   Y.Ishikawa       金額、数量がNULLの場合は0を表示する。
 *  2008/06/25    1.4   T.Ikehara        特定文字列を出力しようとすると、エラーとなり帳票が出力
 *                                       されない現象への対応
 *  2008/07/23    1.5   Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_V→XXCMN_ITEM_CATEGORIES6_V変更
 *  2008/08/07    1.6   R.Tomoyose       参照ビューの変更「xxcmn_rcv_pay_mst_porc_rma_v」→
 *                                                       「xxcmn_rcv_pay_mst_porc_rma09_v」
 *  2008/08/27    1.7   A.Shiina         T_TE080_BPO_770 指摘18対応
 *  2008/10/14    1.8   N.Yoshida        T_S_524対応(PT対応)
 *  2008/10/28    1.9   T.Ohashi         T_S_524対応(PT対応)再対応
 *  2008/10/29    1.10  T.Ohashi         T_S_524対応(PT対応)再対応
 *  2008/11/13    1.11  A.Shiina         移行データ検証不具合対応
 *  2008/11/19    1.12  N.Yoshida        移行データ検証不具合対応
 *  2008/11/29    1.13  N.Yoshida        本番#213、214対応
 *  2008/12/08    1.14  N.Yoshida        本番障害対応 受注ヘッダアドオンで最新フラグYを追加
 *  2008/12/18    1.15  A.Shiina         本番#789対応
 *  2009/01/14    1.16  N.Yoshida        本番#1015対応
 *  2009/05/12    1.17  M.Nomura         本番#1496対応
 *  2009/05/29    1.18  Marushita        本番障害1511対応
 *  2009/11/30    1.19  Marushita        本番#200対応
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
      errbuf             OUT   VARCHAR2  -- エラーメッセージ
     ,retcode            OUT   VARCHAR2  -- エラーコード
     ,iv_proc_from       IN    VARCHAR2  -- 処理年月FROM
     ,iv_proc_to         IN    VARCHAR2  -- 処理年月TO
     ,iv_prod_div        IN    VARCHAR2  -- 商品区分
     ,iv_item_div        IN    VARCHAR2  -- 品目区分
     ,iv_rcv_pay_div     IN    VARCHAR2  -- 受払区分
     ,iv_crowd_type      IN    VARCHAR2  -- 集計種別
     ,iv_crowd_code      IN    VARCHAR2  -- 群コード
     ,iv_acnt_crowd_code IN    VARCHAR2  -- 経理群コード
    );
--
END xxcmn770009cp;
/
