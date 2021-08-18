CREATE OR REPLACE PACKAGE APPS.XXCOK024A14C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A14 (spec)
 * Description      : 控除消込作成API(AP支払)
 * MD.050           : 控除消込作成API(AP支払) MD050_COK_024_A14
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
 *  2020/04/30    1.0   Y.Nakajima       main新規作成
 *  2021/07/21    1.1   K.Yoshikawa      [E_本稼働_17382](Q4148)
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
   ,id_target_date_end              IN     DATE              -- 対象期間(TO)
   ,id_invoice_date                 IN     DATE              -- 請求書日付
   ,iv_payee_code                   IN     VARCHAR2          -- 支払先コード
   ,iv_corp_code                    IN     VARCHAR2          -- 企業コード
   ,iv_deduction_chain_code         IN     VARCHAR2          -- 控除用チェーンコード
   ,iv_cust_code                    IN     VARCHAR2          -- 顧客コード
   ,iv_invoice_number               IN     VARCHAR2          -- 受領請求書番号
   ,iv_terms_name                   IN     VARCHAR2          -- 支払条件
   ,iv_target_data_type             IN     VARCHAR2          -- 対象データ種類
-- 2021/07/21 Ver1.1 ADD Start
   ,iv_condition_no                 IN     VARCHAR2          -- 控除番号(カンマ区切り最大50件)
-- 2021/07/21 Ver1.1 ADD End
  );
END XXCOK024A14C;
/
