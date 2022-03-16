CREATE OR REPLACE PACKAGE APPS.XXCOK024A40R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A40R (spec)
 * Description      : 問屋未収単価チェックリスト
 * MD.050           : MD050_COK_024_A40_問屋未収単価チェックリスト.doc
 * Version          : 1.0
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
 *  2022/01/28    1.0   K.Yoshikawa      main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                   OUT VARCHAR2  -- エラー・メッセージ
  , retcode                  OUT VARCHAR2  -- リターン・コード
  , iv_payment_date          IN  VARCHAR2  -- 支払年月日
  , iv_selling_date          IN  VARCHAR2  -- 売上対象年月
  , iv_base_code             IN  VARCHAR2  -- 拠点コード
  , iv_wholesale_vendor_code IN  VARCHAR2  -- 仕入先コード
  , iv_bill_no               IN  VARCHAR2  -- 請求書番号
  , iv_chain_code            IN  VARCHAR2  -- 控除用チェーンコード
  );
END XXCOK024A40R;
/
