CREATE OR REPLACE PACKAGE XXCOS004A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A01C (spec)
 * Description      : 店舗別掛率作成
 * MD.050           : 店舗別掛率作成 MD050_COS_004_A01
 * Version          : 1.1
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
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   エラーメッセージ #固定#
    retcode       OUT    VARCHAR2,         --   エラーコード     #固定#
    iv_base_code              IN      VARCHAR2,         -- 1.拠点コード
    iv_customer_number        IN      VARCHAR2          -- 2.顧客コード
  );
END XXCOS004A01C;
/
