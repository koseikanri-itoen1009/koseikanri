CREATE OR REPLACE PACKAGE xxpo870003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo870003c(spec)
 * Description      : 発注単価洗替処理
 * MD.050           : 仕入単価／標準原価マスタ登録 Issue1.0 T_MD050_BPO_870
 * MD.070           : 仕入単価／標準原価マスタ登録 Issue1.0  T_MD070_BPO_870
 * Version          : 1.11
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
 *  2008/03/10    1.0   Y.Ishikawa       新規作成
 *  2008/05/01    1.1   Y.Ishikawa       発注明細、発注納入明細、ロットマスタの単価設定を
 *                                       粉引額→粉引単価に修正
 *  2008/05/07    1.2   Y.Ishikawa       トレースの指摘にて、品目チェック時に
 *                                       MTL_SYSTEM_ITEMS_Bの参照を削除
 *  2008/05/09    1.3   Y.Ishikawa       mainの起動時間出力にて、日付のフォーマットを
 *                                       'YYYY/MM/DD HH:MM:SS'→'YYYY/MM/DD HH24:MI:SS'に変更
 *  2008/06/03    1.4   Y.Ishikawa       仕入単価マスタ複数発注更新時に１件のみしか更新されない
 *                                       不具合対応
 *  2008/06/03    1.5   Y.Ishikawa       仕入単価マスタの支給先コードが登録されていない場合は
 *                                       条件に含めない。
 *                                       粉引後単価がNULLの場合は、0として計算する。
 *  2008/07/01    1.6   Y.Ishikawa       発注ヘッダの配送先コードより仕入先コードを導出し
 *                                       発注単価マスタの支給先に対して、同仕入先コードを
 *                                       条件にして抽出する。
 *  2008/07/02    1.7   Y.Ishikawa       口銭区分及び配賦金区分が率以外の時
 *                                       発注納入明細の粉引後単価が更新されない。
 *  2008/09/19    1.8   Oracle山根一浩   変更#193対応
 *  2008/12/04    1.9   Oracle二瓶大輔   本番障害#381対応(TRUNC削除)
 *  2008/12/19    1.10  H.Marushita      本番障害#794対応
 *  2008/12/25    1.11  T.Yoshimoto      発注EBS標準ステータス:未承認対応
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf             OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode            OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_date_type       IN     VARCHAR2,         --   日付タイプ(1:製造日 2:納入日)
    iv_start_date      IN     VARCHAR2,         --   期間開始日(YYYY/MM/DD)
    iv_end_date        IN     VARCHAR2,         --   期間終了日(YYYY/MM/DD)
    iv_commodity_type  IN     VARCHAR2,         --   商品区分
    iv_item_type       IN     VARCHAR2,         --   品目区分
    iv_item_code1      IN     VARCHAR2,         --   品目コード1
    iv_item_code2      IN     VARCHAR2,         --   品目コード2
    iv_item_code3      IN     VARCHAR2,         --   品目コード3
    iv_customer_code1  IN     VARCHAR2,         --   取引先コード1
    iv_customer_code2  IN     VARCHAR2,         --   取引先コード2
    iv_customer_code3  IN     VARCHAR2          --   取引先コード3
  );
END xxpo870003c;
/
