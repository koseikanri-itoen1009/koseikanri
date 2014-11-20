CREATE OR REPLACE PACKAGE XXCOK014A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK014A04R(spec)
 * Description      : 「支払先」「売上計上拠点」「顧客」単位に販手残高情報を出力
 * MD.050           : 自販機販手残高一覧 MD050_COK_014_A04
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
 *  2008/12/17    1.0   T.Taniguchi      main新規作成
 *
 *****************************************************************************************/
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                   OUT    VARCHAR2,         -- エラーメッセージ
    retcode                  OUT    VARCHAR2,         -- エラーコード
    iv_payment_date          IN     VARCHAR2,         -- 支払日
    iv_ref_base_code         IN     VARCHAR2,         -- 問合せ担当拠点
    iv_selling_base_code     IN     VARCHAR2,         -- 売上計上拠点
    iv_target_disp           IN     VARCHAR2          -- 表示対象
  );
END XXCOK014A04R;
/
