CREATE OR REPLACE VIEW xxcfr_bill_customers_v
/*************************************************************************
 * 
 * View Name       : XXCFR_BILL_CUSTOMERS_V
 * Description     : ¿æÚqr[
 * MD.050          : MD.050_LDM_CFR_001
 * MD.070          : 
 * Version         : 1.3
 * 
 * Change Record
 * ------------- ----- -------------  -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- -------------  -------------------------------------
 *  2009-01-30    1.0  SCS gº i   ñì¬
 *  2009/04/07    1.1  SCS åì b   [áQT1_0383] æ¾Úqs³Î
 *  2009/04/14    1.2  SCS åì b   [áQT1_0546] Úqvt@Cæ¾s³Î
 *  2009/06/26    1.3  SCS ´ LÆ [eXgáQ0000030] }`IOr[Î
 ************************************************************************/
(
  pay_customer_id,                   -- üàæÚqID
  pay_customer_number,               -- üàæÚqR[h
  pay_customer_name,                 -- üàæÚq¼
  receiv_base_code,                  -- üà_R[h
  receiv_base_name,                  -- üà_¼
  receiv_code1,                      -- |R[h1i¿j
  receiv_code1_name,                 -- |R[h1i¿j¼Ì
  bill_customer_id,                  -- ¿æÚqID
  bill_customer_code,                -- ¿æÚqR[h
  bill_customer_name,                -- ¿æÚq¼
  bill_base_code,                    -- ¿_R[h
  bill_base_name,                    -- ¿_¼
  store_code,                        -- ¿æÚqXR[h
  tax_div,                           -- ÁïÅæª
  tax_rounding_rule,                 -- Åà-[
  inv_prt_type,                      -- ¿oÍ`®
  cons_inv_flag,                     -- ê¿­stO
  org_id                             -- gDID
)
AS
  SELECT  NVL(chcar.cust_account_id,bcus.cust_account_id)    pay_customer_id,      -- üàæÚqID
          NVL(chca.account_number,bcus.customer_code)        pay_customer_number,  -- üàæÚqR[h
          NVL(chp.party_name,bcus.customer_name)             pay_customer_name,    -- üàæÚq¼
          NVL(cxca.receiv_base_code,bcus.bill_base_code)     receiv_base_code,     -- üà_R[h
          NVL(cffvv.description,bcus.bill_base_name)         receiv_base_name,     -- üà_¼
          bcus.receiv_code1                                  receiv_code1,         -- |R[h1i¿j
          xigc.receiv_code1_name                             receiv_code1_name,    -- |R[h1i¿j¼
          bcus.cust_account_id                               cust_account_id,      -- ¿æÚqID
          bcus.customer_code                                 bill_customer_code,   -- ¿æÚqR[h
          bcus.customer_name                                 bill_customer_name,   -- ¿æÚq¼
          bcus.bill_base_code                                bill_base_code,       -- ¿_R[h
          bcus.bill_base_name                                bill_base_name,       -- ¿_¼
          bcus.store_code                                    store_code,           -- ¿æÚqXR[h
          bcus.tax_div                                       tax_div,              -- ÁïÅæª
          bcus.tax_rounding_rule                             tax_rounding_rule,    -- [æª
          bcus.inv_prt_type                                  inv_prt_type,         -- ¿oÍ`®
          bcus.cons_inv_flag                                 cons_inv_flag,        -- ê¿­stO
          NVL(chcar.org_id,bcus.org_id)                      org_id                -- gDID
-- Modify 2009.06.26 Ver1.3 Start
--  FROM    hz_cust_acct_relate_all chcar,     -- ÚqÖAiüàæ-¿æj
  FROM    hz_cust_acct_relate     chcar,     -- ÚqÖAiüàæ-¿æj
-- Modify 2009.06.26 Ver1.3 End  
          hz_cust_accounts        chca,      -- Úqiüàæj
          hz_parties              chp,       -- p[eBiüàæj
          xxcmm_cust_accounts     cxca,      -- ÚqAhIiüàæj
          (SELECT  lookup_code              receiv_code1,              -- |R[h1i¿æj
                   meaning                  receiv_code1_name          -- |R[h1i¿æj¼
           FROM    fnd_lookup_values_vl
           WHERE   lookup_type        =  'XXCMM_INVOICE_GRP_CODE'      -- |R[h1o^ QÆ^Cv
           AND     enabled_flag       =  'Y'
           AND     NVL(start_date_active,TO_DATE('19000101','YYYYMMDD'))  <= SYSDATE
           AND     NVL(end_date_active,TO_DATE('22001231','YYYYMMDD'))    >= SYSDATE ) xigc, -- |R[hP
          (SELECT  flex_value,
                   description
           FROM    fnd_flex_values_vl ffv
           WHERE   EXISTS
                   (SELECT  'X'
                    FROM    fnd_flex_value_sets
                    WHERE   flex_value_set_name = 'XX03_DEPARTMENT'
                    AND     flex_value_set_id   = ffv.flex_value_set_id)) cffvv,  --lZbgli®åj
          (
           --¿æ
           SELECT  xhca.cust_account_id,        -- ¿æÚqID
                   xhcp.cust_account_profile_id,
                   xhcas.cust_acct_site_id,
                   xhcsu.site_use_id,
                   xhca.party_id,
                   xhp.party_number,
                   xhcsu.attribute4          receiv_code1,             -- |R[h1i¿æj
                   xhca.account_number       customer_code,            -- ¿æÚqR[h
                   xhp.party_name            customer_name,            -- ¿æÚq¼
                   xhca.status               status,                   -- ÚqXe[^X
                   xhca.customer_type        customer_type,            -- Úq^Cv
                   xhca.customer_class_code  customer_class_code,      -- Úqæª
                   xxca.bill_base_code       bill_base_code,           -- ¿_R[h
                   xffvv.description         bill_base_name,           -- ¿_¼
                   xxca.store_code           store_code,               -- XÜR[h
                   xxca.tax_div              tax_div,                  -- ÁïÅæª
                   xhcsu.tax_rounding_rule   tax_rounding_rule,        -- Åà|[
                   xhcsu.attribute7          inv_prt_type,             -- ¿oÍ`®
                   xhcp.cons_inv_flag        cons_inv_flag,            -- ê¿­sæª
                   xhcas.org_id              org_id                    -- gDID
           FROM    hz_cust_accounts        xhca,                       -- ÚqAJEgi¿æj
                   hz_parties              xhp,                        -- p[eBi¿æj
-- Modify 2009.06.26 Ver1.3 Start
--                   hz_cust_acct_sites_all  xhcas,                      -- ÚqTCgi¿æj
--                   hz_cust_site_uses_all   xhcsu,                      -- ÚqgpÚIi¿æj
                   hz_cust_acct_sites      xhcas,                      -- ÚqTCgi¿æj
                   hz_cust_site_uses       xhcsu,                      -- ÚqgpÚIi¿æj
-- Modify 2009.06.26 Ver1.3 Start
                   hz_customer_profiles    xhcp,                       -- Úqvt@Ci¿æj
                   xxcmm_cust_accounts     xxca,                       -- ÚqAhIi¿æj
                   (SELECT flex_value,
                           description
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT  'X'
                            FROM    fnd_flex_value_sets
                            WHERE   flex_value_set_name = 'XX03_DEPARTMENT'
                            AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv  -- lZbgli®åj
           WHERE   xhca.party_id            = xhp.party_id
           AND     xhca.customer_class_code = '14'
-- Modify 2009.04.07 Ver1.1 Start
--           AND     xhca.status              = 'A'                       --Xe[^X
-- Modify 2009.04.07 Ver1.1 END
           AND     xhca.cust_account_id     = xhcas.cust_account_id
-- Modify 2009.06.26 Ver1.3 Start
-- Modify 2009.04.07 Ver1.1 Start
--           AND     xhcas.org_id             = fnd_profile.value('ORG_ID') -- ¿æÚqÝn
-- Modify 2009.04.07 Ver1.1 END
-- Modify 2009.06.26 Ver1.3 End
           AND     xhcas.bill_to_flag       IS NOT NULL                 --
           AND     xhcas.cust_acct_site_id  = xhcsu.cust_acct_site_id
           AND     xhcsu.site_use_code      = 'BILL_TO'                 --gpÚI
-- Modify 2009.04.07 Ver1.1 Start
           AND     xhcsu.primary_flag       = 'Y'
           AND     xhcsu.status             = 'A'                       --Xe[^X
-- Modify 2009.04.07 Ver1.1 END
           AND     xhca.cust_account_id     = xhcp.cust_account_id
           AND     xhcsu.site_use_id       = xhcp.site_use_id
           AND     xhca.cust_account_id     = xxca.customer_id(+)
           AND     xxca.bill_base_code      = xffvv.flex_value(+)
           AND     EXISTS
                   (SELECT   'X'
-- Modify 2009.06.26 Ver1.3 Start
--                    FROM     hz_cust_acct_relate_all hcar
                    FROM     hz_cust_acct_relate     hcar
-- Modify 2009.06.26 Ver1.3 End
                    WHERE    hcar.attribute1  = '1'
                    AND      hcar.status      = 'A'
                    AND      hcar.cust_account_id = xhca.cust_account_id
                    )
         UNION ALL
           -- [iæ AND ¿æ
           SELECT  yhca.cust_account_id,                               -- ¿æÚqID
                   yhcp.cust_account_profile_id,
                   yhcas.cust_acct_site_id,
                   yhcsu.site_use_id,
                   yhca.party_id,
                   yhp.party_number,
                   yhcsu.attribute4          receiv_code1,             -- |R[h1i¿æj
                   yhca.account_number       customer_code,            -- ¿æÚqR[h
                   yhp.party_name            customer_name,            -- ¿æÚq¼Ì
                   yhca.status               status,                   -- ÚqXe[^X
                   yhca.customer_type        customer_type,            -- Úq^Cv
                   yhca.customer_class_code  customer_class_code,      -- Úqæª
                   yxca.bill_base_code       bill_base_code,           -- ¿_R[h
                   yffvv.description         bill_base_name,           -- ¿_¼
                   yxca.store_code           store_code,               -- XÜR[h
                   yxca.tax_div              tax_div,                  -- ÁïÅæª
                   yhcsu.tax_rounding_rule   tax_rounding_rule,        -- Åà|[
                   yhcsu.attribute7          inv_prt_type,             -- ¿oÍ`®
                   yhcp.cons_inv_flag        cons_inv_flag,            -- ê¿­sæª
                   yhcas.org_id              org_id                    -- gDID
           FROM    hz_cust_accounts        yhca,                       -- ÚqAJEgi¿æj
                   hz_parties              yhp,                        -- p[eBi¿æj
-- Modify 2009.06.26 Ver1.3 Start
--                   hz_cust_acct_sites_all  yhcas,                      -- ÚqTCgi¿æj
--                   hz_cust_site_uses_all   yhcsu,                      -- ÚqgpÚIi¿æj
                   hz_cust_acct_sites      yhcas,                      -- ÚqTCgi¿æj
                   hz_cust_site_uses       yhcsu,                      -- ÚqgpÚIi¿æj
-- Modify 2009.06.26 Ver1.3 End
                   hz_customer_profiles    yhcp,                       -- Úqvt@Ci¿æj
                   xxcmm_cust_accounts     yxca,                       -- ÚqAhIi¿æj
                   (SELECT  flex_value,
                           description
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT   'X'
                            FROM     fnd_flex_value_sets
                            WHERE    flex_value_set_name = 'XX03_DEPARTMENT'
                            AND      flex_value_set_id = ffv.flex_value_set_id)) yffvv  -- lZbgli®åj
           WHERE   yhca.party_id            = yhp.party_id
           AND     yhca.customer_class_code = '10'
-- Modify 2009.04.07 Ver1.1 Start
--           AND     yhca.status              = 'A'                       --Xe[^X
-- Modify 2009.04.07 Ver1.1 END
           AND     yhca.cust_account_id     = yhcas.cust_account_id
           AND     yhcas.bill_to_flag       IS NOT NULL                 --
           AND     yhcas.cust_acct_site_id  = yhcsu.cust_acct_site_id
-- Modify 2009.06.26 Ver1.3 Start
-- Modify 2009.04.07 Ver1.1 Start
--           AND     yhcas.org_id             = fnd_profile.value('ORG_ID') -- ¿æÚqÝn
-- Modify 2009.04.07 Ver1.1 END
-- Modify 2009.06.26 Ver1.3 End
           AND     yhcsu.site_use_code      = 'BILL_TO'                 --gpÚI
-- Modify 2009.04.07 Ver1.1 Start
           AND     yhcsu.primary_flag       = 'Y'
           AND     yhcsu.status             = 'A'                       --Xe[^X
-- Modify 2009.04.07 Ver1.1 END
           AND     yhca.cust_account_id     = yhcp.cust_account_id
           AND     yhcsu.site_use_id        = yhcp.site_use_id
           AND     yhca.cust_account_id     = yxca.customer_id(+)
           AND     yxca.bill_base_code      = yffvv.flex_value(+)
           AND     NOT EXISTS
                   (SELECT   'X'
-- Modify 2009.06.26 Ver1.3 Start
--                    FROM     hz_cust_acct_relate_all hcar
                    FROM     hz_cust_acct_relate     hcar
-- Modify 2009.06.26 Ver1.3 End
                    WHERE    hcar.attribute1  = '1'
                    AND      hcar.status      = 'A'
                    AND      hcar.related_cust_account_id = yhca.cust_account_id
                   )
          ) bcus
  WHERE   chcar.related_cust_account_id(+) = bcus.cust_account_id
  AND     chcar.org_id(+)                  = bcus.org_id
  AND     chcar.cust_account_id            = chca.cust_account_id(+)
  AND     chca.party_id                    = chp.party_id(+)
  AND     chca.cust_account_id             = cxca.customer_id(+)
  AND     cxca.receiv_base_code            = cffvv.flex_value(+)
  AND     chcar.status(+)                  = 'A'
  AND     bcus.receiv_code1                = xigc.receiv_code1(+)
;

COMMENT ON COLUMN  xxcfr_bill_customers_v.pay_customer_id        IS 'üàæÚqID';
COMMENT ON COLUMN  xxcfr_bill_customers_v.pay_customer_number    IS 'üàæÚqR[h';
COMMENT ON COLUMN  xxcfr_bill_customers_v.pay_customer_name      IS 'üàæÚq¼';
COMMENT ON COLUMN  xxcfr_bill_customers_v.receiv_base_code       IS 'üà_R[h';
COMMENT ON COLUMN  xxcfr_bill_customers_v.receiv_base_name       IS 'üà_¼';
COMMENT ON COLUMN  xxcfr_bill_customers_v.receiv_code1           IS '|R[h1i¿j';
COMMENT ON COLUMN  xxcfr_bill_customers_v.receiv_code1_name      IS '|R[h1i¿j¼';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_customer_id       IS '¿æÚqID';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_customer_code     IS '¿æÚqR[h';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_customer_name     IS '¿æÚq¼';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_base_code         IS '¿_R[h';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_base_name         IS '¿_¼';
COMMENT ON COLUMN  xxcfr_bill_customers_v.store_code             IS '¿æÚqXR[h';
COMMENT ON COLUMN  xxcfr_bill_customers_v.tax_div                IS 'ÁïÅæª';
COMMENT ON COLUMN  xxcfr_bill_customers_v.tax_rounding_rule      IS '[æª';
COMMENT ON COLUMN  xxcfr_bill_customers_v.inv_prt_type           IS '¿oÍ`®';
COMMENT ON COLUMN  xxcfr_bill_customers_v.cons_inv_flag          IS 'ê¿­stO';
COMMENT ON COLUMN  xxcfr_bill_customers_v.org_id                 IS 'gDID';

COMMENT ON TABLE  xxcfr_bill_customers_v IS '¿æÚqr[';
