CREATE OR REPLACE PACKAGE XXCFO019A04C--←<package_name>は大文字で記述して下さい。
AS
/*****************************************************************************************
 * Copyright(c)2011,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO019A04C.pks
 * Description      : 電子帳簿AP仕入請求の情報系システム連携
 * MD.050           : MD050_CFO_019_A04_電子帳簿AP仕入請求の情報系システム連携
 * 
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
 * 2012/08/31     1.0   M.Kitajima       初回作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2,         -- エラーメッセージ #固定#
    retcode               OUT NOCOPY VARCHAR2,         -- エラーコード     #固定#
    iv_ins_upd_kbn        IN  VARCHAR2,                                       -- 追加更新区分
    iv_file_name          IN  VARCHAR2,                                       -- ファイル名
    it_invoice_num        IN  ap_invoices_all.invoice_num%TYPE,               -- 請求書番号
    it_invoice_dist_id_fr IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE,  -- 請求書配分ID(From)
    it_invoice_dist_id_to IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE,  -- 請求書配分ID(To)
    iv_fixedmanual_kbn    IN  VARCHAR2                                        -- 定期手動区分
   );
END XXCFO019A04C;
/
