CREATE OR REPLACE PACKAGE APPS.XXCOS004A01C 
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A01C (spec)
 * Description      : 店舗別掛率作成
 * MD.050           : 店舗別掛率作成 MD050_COS_004_A01
 * Version          : 1.9
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
 *  2009/01/19    1.0   T.kitajima       新規作成
 *  2009/02/06    1.1   K.Kakishita      [COS_036]AR取引タイプマスタの抽出条件に営業単位を追加
 *  2009/02/10    1.2   T.kitajima       [COS_057]顧客区分絞り込み条件不足対応(仕様漏れ)
 *  2009/02/17    1.3   T.kitajima       get_msgのパッケージ名修正
 *  2009/02/24    1.4   T.kitajima       パラメータのログファイル出力対応
 *  2009/03/05    1.5   N.Maeda          棚卸減耗の抽出時の計算処理削除
 *                                       ・修正前
 *                                         ⇒sirm.inv_wear * -1
 *                                       ・修正後
 *                                         ⇒sirm.inv_wear
 *  2009/03/19    1.6   T.kitajima       [T1_0093]INV月次在庫受払い表情報取得修正
 *  2009/07/17    1.7   T.Tominaga       [0000429]PTの考慮、ロック処理の条件修正
 *  2009/08/03    1.7   N.Maeda          [0000429] レビュー指摘対応
 *  2009/12/16    1.8   N.Maeda          [E_本稼動_00486] 今回データ削除条件修正
 *  2010/02/09    1.9   M.Uehara         [E_本稼動_01394,E_本稼動_01397]定期モード追加,異常掛率チェック
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_base_code              IN      VARCHAR2,         -- 1.拠点コード
--******************************* 2010/02/09 1.9 M.Uehara MOD START ***************************************
    iv_customer_number        IN      VARCHAR2,         -- 2.顧客コード
    iv_mode                   IN      VARCHAR2          -- 3.起動モード
--    iv_customer_number        IN      VARCHAR2          -- 2.顧客コード
--******************************* 2010/02/09 1.9 M.Uehara ADD END   ***************************************
  );
END XXCOS004A01C;
/
