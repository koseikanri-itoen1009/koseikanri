/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCFR_ROCK_CUST_TRX_MV
 * Description     : ���}�e���A���C�Y�h�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010-10-27    1.0   SCS.Hirose      �V�K�쐬
 *
 ************************************************************************/
CREATE MATERIALIZED VIEW APPS.XXCFR_ROCK_CUST_TRX_MV
  TABLESPACE "XXDATA2"
  BUILD IMMEDIATE 
  USING INDEX 
  REFRESH COMPLETE ON DEMAND 
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  DISABLE QUERY REWRITE
  AS
SELECT /*+ USE_NL(rcta apsa radist )
            INDEX(rcta   RA_CUSTOMER_TRX_U1)
            INDEX(apsa   XXCFR_AR_PAYMENT_SCHEDULES_N01)
            INDEX(radist RA_CUST_TRX_LINE_GL_DIST_N6 )
       */
       rcta.customer_trx_id             AS customer_trx_id       -- ���ID
      ,rcta.trx_number                  AS trx_number            -- ����ԍ�
      ,NVL(apsa.amount_due_remaining,0) AS amount_due_remaining  -- ������c��
      ,rcta.bill_to_customer_id         AS bill_to_customer_id   -- ������ڋqID
FROM   apps.ra_customer_trx_all          rcta       -- ����w�b�_
      ,apps.ar_payment_schedules_all     apsa       -- �x���v��
      ,apps.ra_cust_trx_line_gl_dist_all radist     -- ����z��
      ,apps.hr_all_organization_units    org_units  -- �ڋq�P��
      ,apps.gl_sets_of_books             gsob       -- ��v����
WHERE rcta.customer_trx_id     = apsa.customer_trx_id  -- ����ID
AND   radist.customer_trx_id   = rcta.customer_trx_id  -- ����ID
AND   radist.account_class     = 'REC'  -- ���|�^������
AND   rcta.complete_flag       = 'Y'    -- ����쐬��
AND   apsa.status              = 'OP'   -- ������̍��̂�
-- �x���������P�\���ԓ�
AND   apsa.due_date            <= xxccp_common_pkg2.get_process_date 
                                + TO_NUMBER(FND_PROFILE.VALUE('XXCFR1_FB_RECEIPT_DATE'))  
-- ��������Ɩ����t�ȓ�
AND   rcta.trx_date            <=  xxccp_common_pkg2.get_process_date
-- GL�L�������Ɩ����t�ȓ�
AND   radist.gl_date           <=  xxccp_common_pkg2.get_process_date
AND   rcta.set_of_books_id      = gsob.set_of_books_id
AND   radist.set_of_books_id    = gsob.set_of_books_id
AND   radist.org_id  = org_units.organization_id
AND   rcta.org_id    = org_units.organization_id
AND   apsa.org_id    = org_units.organization_id
AND   gsob.name      = 'SALES-SOB'
AND   org_units.name = 'SALES-OU'
;
COMMENT ON  MATERIALIZED VIEW apps.xxcfr_rock_cust_trx_mv IS '���}�e���A���C�Y�h�r���['
/
COMMENT ON COLUMN apps.xxcfr_rock_cust_trx_mv.customer_trx_id      IS '���ID'
/
COMMENT ON COLUMN apps.xxcfr_rock_cust_trx_mv.trx_number           IS '����ԍ�'
/
COMMENT ON COLUMN apps.xxcfr_rock_cust_trx_mv.amount_due_remaining IS '������c��'
/
COMMENT ON COLUMN apps.xxcfr_rock_cust_trx_mv.bill_to_customer_id  IS '������ڋqID'
/
