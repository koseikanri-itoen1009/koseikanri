CREATE OR REPLACE PACKAGE XXCOK021A06R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A06R(spec)
 * Description      : 帳合問屋に関する請求書と見積書を突き合わせ、品目別に請求書と見積書の内容を表示
 * MD.050           : 問屋販売条件支払チェック表 MD050_COK_021_A06
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
 *  2008/12/05    1.0   K.Iwabuchi       main新規作成
 *  2009/02/05    1.1   K.Iwabuchi       [障害COK_011] パラメータ不具合対応
 *
 *****************************************************************************************/
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                   OUT    VARCHAR2         -- エラーメッセージ
  , retcode                  OUT    VARCHAR2         -- エラーコード
  , iv_base_code             IN     VARCHAR2         -- 拠点コード
  , iv_payment_date          IN     VARCHAR2         -- 支払年月日
  , iv_selling_month         IN     VARCHAR2         -- 売上対象年月
  , iv_wholesale_code_admin  IN     VARCHAR2         -- 問屋管理コード
  , iv_cust_code             IN     VARCHAR2         -- 顧客コード
  , iv_sales_outlets_code    IN     VARCHAR2         -- 問屋帳合先コード
  );
END XXCOK021A06R;
/
