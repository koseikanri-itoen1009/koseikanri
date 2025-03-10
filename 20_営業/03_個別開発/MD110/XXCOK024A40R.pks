CREATE OR REPLACE PACKAGE APPS.XXCOK024A40R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A40R (spec)
 * Description      : 問屋未収単価チェックリスト
 * MD.050           : MD050_COK_024_A40_問屋未収単価チェックリスト.doc
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
 *  2022/01/28    1.0   K.Yoshikawa      main新規作成
 *  2022/03/24    1.1   K.Yoshikawa      main新規作成
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
-- 2022/03/24 Ver1.1 ADD Start
  --単位換算ファンクション
  FUNCTION get_uom_conversion_f(
    iv_item_code             IN  VARCHAR2 -- 品目コード
  , iv_befor_uom_code        IN  VARCHAR2 -- 換算前単位コード
  , in_befor_quantity        IN  NUMBER   -- 換算前金額
  , iv_after_uom_code        IN  VARCHAR2 -- 換算後単位コード
  )
  RETURN NUMBER;              -- 単位換算後金額
-- 2022/03/24 Ver1.1 ADD End
END XXCOK024A40R;
/
