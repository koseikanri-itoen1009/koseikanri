CREATE OR REPLACE PACKAGE XXCFO019A05C--←<package_name>は大文字で記述して下さい。
AS
/*****************************************************************************************
 * Copyright(c)2011,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO019A05C.pks
 * Description      : 電子帳簿AP支払の情報系システム連携
 * MD.050           : MD050_CFO_019_A05_電子帳簿AP支払の情報系システム連携
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
 * 2012/09/25     1.0   M.Kitajima       初回作成
 *
 *****************************************************************************************/
--
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf                OUT NOCOPY VARCHAR2,         -- エラーメッセージ #固定#
    retcode               OUT NOCOPY VARCHAR2,         -- エラーコード     #固定#
    iv_ins_upd_kbn        IN  VARCHAR2,                                       -- 追加更新区分
    iv_file_name          IN  VARCHAR2,                                       -- ファイル名
    it_doc_sequence_val   IN  ap_checks_all.doc_sequence_value%TYPE,          -- 証憑番号
    it_invoice_pay_id_fr  IN  ap_invoice_payments_all.invoice_payment_id%TYPE,-- 請求支払ID(From)
    it_invoice_pay_id_to  IN  ap_invoice_payments_all.invoice_payment_id%TYPE,-- 請求支払ID(To)
    iv_fixedmanual_kbn    IN  VARCHAR2                                        -- 定期手動区分
   );
END XXCFO019A05C;
/
