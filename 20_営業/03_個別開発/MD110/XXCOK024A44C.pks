CREATE OR REPLACE PACKAGE APPS.XXCOK024A44C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOK024A44C (spec)
 * Description      : 控除未作成入金相殺伝票CSV出力
 * MD.050           : 控除未作成入金相殺伝票CSV出力 MD050_COK_024_A44
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
 *  2022/10/07    1.0   R.Oikawa         main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2          -- エラーコード     #固定#
   ,iv_record_date_from             IN     VARCHAR2          -- 計上日(FROM)
   ,iv_record_date_to               IN     VARCHAR2          -- 計上日(TO)
   ,iv_cust_code                    IN     VARCHAR2          -- 顧客
   ,iv_base_code                    IN     VARCHAR2          -- 起票部門
   ,iv_user_name                    IN     VARCHAR2          -- 入力者
   ,iv_slip_line_type_name          IN     VARCHAR2          -- 請求内容
   ,iv_payment_scheduled_date       IN     VARCHAR2          -- 入金予定日
  );
END XXCOK024A44C;
/
