CREATE OR REPLACE PACKAGE APPS.XXCOK024A15C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A15 (spec)
 * Description      : 控除消込作成API(AP問屋支払)
 * MD.050           : 控除消込作成API(AP問屋支払) MD050_COK_024_A15
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
 *  2020/04/28    1.0   Y.Nakajima       main新規作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- エラーメッセージ #固定#
   ,retcode                         OUT    VARCHAR2          -- エラーコード     #固定#
   ,ov_recon_slip_num               OUT    VARCHAR2          -- 支払伝票番号
   ,iv_recon_base_code              IN     VARCHAR2          -- 支払請求拠点
   ,id_recon_due_date               IN     DATE              -- 支払予定日
   ,id_gl_date                      IN     DATE              -- GL記帳日
   ,od_target_date_end              OUT    DATE              -- 対象期間(TO)
   ,iv_payee_code                   IN     VARCHAR2          -- 支払先コード
   ,iv_invoice_number               IN     VARCHAR2          -- 問屋請求書番号
   ,iv_terms_name                   IN     VARCHAR2          -- 支払条件
   ,id_invoice_date                 IN     DATE              -- 請求書日付
   ,iv_target_data_type             IN     VARCHAR2          -- 対象データ種類
  );
END XXCOK024A15C;
/
