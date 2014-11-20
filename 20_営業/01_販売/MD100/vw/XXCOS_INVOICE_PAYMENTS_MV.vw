/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * View Name       : XXCOS_INVOICE_PAYMENTS_MV
 * Description     : �����x���}�e���A���C�Y�h�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 * 2012/12/07     1.0   K.Nakamura       [E_�{�ғ�_09040]�V�K�쐬
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
       aia.invoice_id          AS invoice_id         -- ����ID
     , aia.invoice_num         AS invoice_number     -- �������ԍ�
     , aipa.invoice_payment_id AS invoice_payment_id -- �����x��ID
     , aipa.accounting_date    AS accounting_date    -- �v���
     , aipa.amount             AS aipa_amount        -- ���������z
     , aca.check_date          AS check_date         -- �x����
     , aca.check_number        AS check_number       -- �x�������ԍ�
     , aca.doc_sequence_value  AS doc_sequence_value -- �؜ߔԍ�
     , aca.checkrun_name       AS checkrun_name      -- �x���o�b�`��
     , aca.bank_account_num    AS bank_account_num   -- �����ԍ�
     , aca.bank_account_name   AS bank_account_name  -- ������
     , aca.amount              AS ac_amount          -- �x�����z
     , aca.currency_code       AS currency_code      -- �x���ʉ�
     , aca.exchange_date       AS exchange_date      -- ���Z��
     , aca.exchange_rate       AS exchange_rate      -- ���Z���[�g
     , aca.base_amount         AS base_amount        -- �@�\�ʉݐ��������z
     , aca.check_id            AS check_id           -- �x��ID
FROM   ap_invoices_all           aia                 -- AP����
     , ap_invoice_payments_all   aipa                -- AP�����x��
     , ap_checks_all             aca                 -- AP�x��
     , hr_all_organization_units haou                -- �ڋq�P��
     , gl_sets_of_books          gsob                -- ��v����
WHERE  aia.invoice_id      = aipa.invoice_id
AND    aipa.check_id       = aca.check_id
AND    aia.org_id          = aca.org_id
AND    aca.org_id          = haou.organization_id
AND    aia.set_of_books_id = gsob.set_of_books_id
AND    haou.name           = 'SALES-OU'
AND    gsob.name           = 'SALES-SOB'
;
COMMENT ON MATERIALIZED VIEW apps.xxcos_invoice_payments_mv         IS '�����x���}�e���A���C�Y�h�r���['
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.invoice_id         IS '����ID'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.invoice_number     IS '�������ԍ�'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.invoice_payment_id IS '�����x��ID'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.accounting_date    IS '�v���'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.aipa_amount        IS '���������z'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.check_date         IS '�x����'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.check_number       IS '�x�������ԍ�'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.doc_sequence_value IS '�؜ߔԍ�'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.checkrun_name      IS '�x���o�b�`��'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.bank_account_num   IS '�����ԍ�'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.bank_account_name  IS '������'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.ac_amount          IS '�x�����z'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.currency_code      IS '�x���ʉ�'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.exchange_date      IS '���Z��'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.exchange_rate      IS '���Z���[�g'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.base_amount        IS '�@�\�ʉݐ��������z'
/
COMMENT ON COLUMN apps.xxcos_invoice_payments_mv.check_id           IS '�x��ID'
/
