/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCFR_ROCK_CUST_TRX_MV
 * Description     : 債権マテリアライズドビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010-10-27    1.0   SCS.Hirose      新規作成
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
       rcta.customer_trx_id             AS customer_trx_id       -- 取引ID
      ,rcta.trx_number                  AS trx_number            -- 取引番号
      ,NVL(apsa.amount_due_remaining,0) AS amount_due_remaining  -- 未回収残高
      ,rcta.bill_to_customer_id         AS bill_to_customer_id   -- 請求先顧客ID
FROM   apps.ra_customer_trx_all          rcta       -- 取引ヘッダ
      ,apps.ar_payment_schedules_all     apsa       -- 支払計画
      ,apps.ra_cust_trx_line_gl_dist_all radist     -- 取引配分
      ,apps.hr_all_organization_units    org_units  -- 顧客単位
      ,apps.gl_sets_of_books             gsob       -- 会計帳簿
WHERE rcta.customer_trx_id     = apsa.customer_trx_id  -- 内部ID
AND   radist.customer_trx_id   = rcta.customer_trx_id  -- 内部ID
AND   radist.account_class     = 'REC'  -- 売掛／未収金
AND   rcta.complete_flag       = 'Y'    -- 取引作成済
AND   apsa.status              = 'OP'   -- 未回収の債権のみ
-- 支払期日が猶予期間内
AND   apsa.due_date            <= xxccp_common_pkg2.get_process_date 
                                + TO_NUMBER(FND_PROFILE.VALUE('XXCFR1_FB_RECEIPT_DATE'))  
-- 取引日が業務日付以内
AND   rcta.trx_date            <=  xxccp_common_pkg2.get_process_date
-- GL記帳日が業務日付以内
AND   radist.gl_date           <=  xxccp_common_pkg2.get_process_date
AND   rcta.set_of_books_id      = gsob.set_of_books_id
AND   radist.set_of_books_id    = gsob.set_of_books_id
AND   radist.org_id  = org_units.organization_id
AND   rcta.org_id    = org_units.organization_id
AND   apsa.org_id    = org_units.organization_id
AND   gsob.name      = 'SALES-SOB'
AND   org_units.name = 'SALES-OU'
;
COMMENT ON  MATERIALIZED VIEW apps.xxcfr_rock_cust_trx_mv IS '債権マテリアライズドビュー'
/
COMMENT ON COLUMN apps.xxcfr_rock_cust_trx_mv.customer_trx_id      IS '取引ID'
/
COMMENT ON COLUMN apps.xxcfr_rock_cust_trx_mv.trx_number           IS '取引番号'
/
COMMENT ON COLUMN apps.xxcfr_rock_cust_trx_mv.amount_due_remaining IS '未回収残高'
/
COMMENT ON COLUMN apps.xxcfr_rock_cust_trx_mv.bill_to_customer_id  IS '請求先顧客ID'
/
