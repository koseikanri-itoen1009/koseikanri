CREATE OR REPLACE PACKAGE XXCOS012A01R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS012A01R (spec)
 * Description      : ピックリスト（チェーン・製品別トータル）
 * MD.050           : ピックリスト（チェーン・製品別トータル） MD050_COS_012_A01
 * Version          : 1.2
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
 *  2008/11/21    1.0   K.Kakishita      新規作成
 *  2009/02/26    1.1   K.Kakishita      帳票コンカレント起動後のワークテーブル削除処理の
 *                                       コメント化を外す。
 *  2009/04/03    1.2   N.Maeda          【ST障害No.T1_0086対応】
 *                                       非在庫品目を抽出対象より除外するよう変更。
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_login_base_code        IN      VARCHAR2,         -- 1.拠点
    iv_login_chain_store_code IN      VARCHAR2,         -- 2.チェーン店
    iv_request_date_from      IN      VARCHAR2,         -- 3.着日（From）
    iv_request_date_to        IN      VARCHAR2)         -- 4.着日（To）
  ;
END XXCOS012A01R;
/
