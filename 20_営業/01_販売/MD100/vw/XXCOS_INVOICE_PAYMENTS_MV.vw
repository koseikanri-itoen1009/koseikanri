/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * View Name       : XXCOS_INVOICE_PAYMENTS_MV
 * Description     : 請求支払マテリアライズドビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 * 2012/12/07     1.0   K.Nakamura       [E_本稼動_09040]新規作成
 *
 ****************************************************************************************/
CREATE MATERIALIZED VIEW APPS.XXCOS_INVOICE_PAYMENTS_MV
  TABLESPACE "XXDATA2"
  BUILD IMMEDIATE
  USING INDEX
  REFRESH COMPLETE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  DISABLE QUERY REWRITE
  AS
SELECT /*+ LEADING(haou gsob aia aipa aca)
           USE_NL(haou gsob aia aipa aca)
           INDEX(aipa AP_INVOICE_PAYMENTS_N1)
           INDEX(aca  AP_CHECKS_U1)
       */
       aia.invoice_id          AS invoice_id         -- 請求ID
     , aia.invoice_num         AS invoice_number     -- 請求書番号
     , aipa.invoice_payment_id AS invoice_payment_id -- 請求支払ID
     , aipa.accounting_date    AS accounting_date    -- 計上日
     , aipa.amount             AS aipa_amount        -- 請求書金額
     , aca.check_date          AS check_date         -- 支払日
     , aca.check_number        AS check_number       -- 支払文書番号
     , aca.doc_sequence_value  AS doc_sequence_value -- 証憑番号
     , aca.checkrun_name       AS checkrun_name      -- 支払バッチ名
     , aca.bank_account_num    AS bank_account_num   -- 口座番号
     , aca.bank_account_name   AS bank_account_name  -- 口座名
     , aca.amount              AS ac_amount          -- 支払金額
     , aca.currency_code       AS currency_code      -- 支払通貨
     , aca.exchange_date       AS exchange_date      -- 換算日
     , aca.exchange_rate       AS exchange_rate      -- 換算レート
     , aca.base_amount         AS base_amount        -- 機能通貨請求書金額
     , aca.check_id            AS check_id           -- 支払ID
FROM   ap_invoices_all           aia                 -- AP請求
     , ap_invoice_payments_all   aipa                -- AP請求支払
     , ap_checks_all             aca                 -- AP支払
     , hr_all_organization_units haou                -- 顧客単位
     , gl_sets_of_books          gsob                -- 会計帳簿
WHERE  aia.invoice_id      = aipa.invoice_id
AND    aipa.check_id       = aca.check_id
AND    aia.org_id          = aca.org_id
AND    aca.org_id          = haou.organization_id
AND    aia.set_of_books_id = gsob.set_of_books_id
AND    haou.name           = 'SALES-OU'
AND    gsob.name           = 'SALES-SOB'
;
COMMENT ON MATERIALIZED VIEW apps.xxcos_invoice_payments_mv         IS '請求支払マテリアライズドビュー'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.invoice_id         IS '請求ID'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.invoice_number     IS '請求書番号'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.invoice_payment_id IS '請求支払ID'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.accounting_date    IS '計上日'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.aipa_amount        IS '請求書金額'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.check_date         IS '支払日'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.check_number       IS '支払文書番号'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.doc_sequence_value IS '証憑番号'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.checkrun_name      IS '支払バッチ名'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.bank_account_num   IS '口座番号'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.bank_account_name  IS '口座名'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.ac_amount          IS '支払金額'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.currency_code      IS '支払通貨'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.exchange_date      IS '換算日'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.exchange_rate      IS '換算レート'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.base_amount        IS '機能通貨請求書金額'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.check_id           IS '支払ID'
/
