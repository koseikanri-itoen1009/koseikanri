/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_edi_chain_security_v
 * Description     : EDI`F[XZLeBview
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/12/25    1.0   S.Nakamura      VKì¬
 *  2009/05/11    1.1   K.Kiriu          [T1_0777]ÀñÔÌðí
 *  2022/01/11    1.2   SCSK Y.Koh       [E_{Ò®_17874]
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_edi_chain_security_v(
   account_number     -- ÚqR[h
  ,edi_chain_code     -- EDI`F[XR[h
  ,edi_chain_name     -- `F[X¼(Úq¼Ì)
  ,delivery_base_code -- [i_R[h
  ,delivery_base_name -- [i_¼
)
AS
  SELECT 
         hca2.account_number         -- ÚqR[h
-- 2022/01/11 Ver1.2 MOD Start
        ,xca2.chain_store_code       -- EDI`F[XR[h
        ,hp2.party_name              -- Úq¼Ì
        ,xca1.delivery_base_code     -- [i_R[h
        ,xlb.base_name               -- [i_¼
--        ,hca2.chain_store_code       -- EDI`F[XR[h
--        ,hca2.account_name           -- Úq¼Ì
--        ,hca1.delivery_base_code     -- [i_R[h
--        ,hca1.delivery_base_name     -- [i_¼
-- 2022/01/11 Ver1.2 MOD End
  FROM
-- 2022/01/11 Ver1.2 MOD Start
         hz_cust_accounts         hca1                      -- Úq
        ,xxcmm_cust_accounts      xca1                      -- ÚqÇÁîñ
        ,xxcos_login_base_info_v  xlb                       -- OC[U_r[
        ,hz_parties               hp1                       -- p[eB
        ,hz_cust_accounts         hca2                      -- Úq
        ,xxcmm_cust_accounts      xca2                      -- ÚqÇÁîñ
        ,hz_parties               hp2                       -- p[eB
   ,( SELECT   DISTINCT
               flv.attribute1        chain_store_code  -- EDI`F[XR[h
--    ( SELECT hca.cust_account_id       cust_account_id    -- ÚqID
--            ,hca.account_number        account_number     -- ÚqR[h
--            ,xca.chain_store_code      chain_store_code   -- EDI`F[XR[h
--            ,xca.store_code            store_code         -- XÜR[h
--            ,hp.party_name             account_name       -- Úq¼
--            ,xca.delivery_base_code    delivery_base_code -- [i_R[h
--            ,xlb.base_name             delivery_base_name -- [i_¼
--      FROM  hz_cust_accounts         hca  -- Úq
--           ,xxcmm_cust_accounts      xca  -- ÚqÇÁîñ
--           ,xxcos_login_base_info_v  xlb  -- OC[U_r[
--           ,hz_parties               hp   -- p[eB
--      WHERE   hca.cust_account_id     = xca.customer_id
--      AND     hca.customer_class_code = '10'
--      AND     xca.delivery_base_code  = xlb.base_code    -- _ZLeB
--      AND     hca.party_id            = hp.party_id
--      AND     hca.status              = 'A'
--      AND     hp.duns_number_c        in ('30','40')     -- ÚqXe[^X
--      AND     xca.store_code IS NOT NULL                 -- XÜR[h è
--    )    hca1   -- Úq}X^(Úq)
--   ,( SELECT  hca.account_number           account_number    -- ÚqR[h
--             ,xca.chain_store_code         chain_store_code  -- EDI`F[XR[h
--             ,hp.party_name                account_name      -- Úq¼
--      FROM    hz_cust_accounts       hca               -- Úq
--             ,xxcmm_cust_accounts    xca               -- ÚqÇÁîñ
--             ,hz_parties             hp   -- p[eB
--      WHERE   hca.cust_account_id     = xca.customer_id
--      AND     hca.customer_class_code = '18'
--      AND     hca.party_id            = hp.party_id
--    )    hca2   -- Úq}X^(`F[X)
--   ,( SELECT   flv.attribute1        chain_store_code  -- EDI`F[XR[h
-- 2022/01/11 Ver1.2 MOD End
      FROM     fnd_lookup_values     flv
      WHERE    flv.lookup_type        = 'XXCOS1_EDI_CONTROL_LIST'   -- EDI§äîñ
        AND    flv.attribute2         = '21'                        -- f[^íR[h [i\è
/* 2009/05/11 Ver1.1 Del Start */
--        AND    flv.attribute3         = '01'                        -- ÀñÔ
/* 2009/05/11 Ver1.1 Del End   */
        AND    flv.language           = userenv('LANG')
        AND    flv.source_lang        = userenv('LANG')
        AND    flv.enabled_flag       = 'Y'
        AND    flv.start_date_active <= TRUNC(SYSDATE)
        AND  ( flv.end_date_active   >= TRUNC(SYSDATE) OR flv.end_date_active IS NULL )
    )  flv     -- EDI§äîñ
-- 2022/01/11 Ver1.2 MOD Start
WHERE    hca1.cust_account_id     =   xca1.customer_id
  AND    hca1.customer_class_code =   '10'
  AND    xca1.delivery_base_code  =   xlb.base_code         -- _ZLeB
  AND    hca1.party_id            =   hp1.party_id
  AND    hca1.status              =   'A'
  AND    hp1.duns_number_c        in  ('30','40')           -- ÚqXe[^X
  AND    xca1.store_code          IS  NOT NULL              -- XÜR[h è
  AND    hca2.cust_account_id     =   xca2.customer_id
  AND    hca2.customer_class_code =   '18'
  AND    hca2.party_id            =   hp2.party_id
  AND    xca1.chain_store_code    =   xca2.chain_store_code
  AND    xca2.chain_store_code    =   flv.chain_store_code
--WHERE    hca1.chain_store_code = hca2.chain_store_code
--  AND    hca1.chain_store_code = flv.chain_store_code
--  AND    hca2.chain_store_code = flv.chain_store_code
-- 2022/01/11 Ver1.2 MOD End
GROUP BY hca2.account_number         -- ÚqR[h
-- 2022/01/11 Ver1.2 MOD Start
        ,xca2.chain_store_code       -- EDI`F[XR[h
        ,hp2.party_name              -- Úq¼Ì
        ,xca1.delivery_base_code     -- [i_R[h
        ,xlb.base_name               -- [i_¼
--        ,hca2.chain_store_code       -- EDI`F[XR[h
--        ,hca2.account_name           -- Úq¼Ì
--        ,hca1.delivery_base_code     -- [i_R[h
--        ,hca1.delivery_base_name     -- [i_¼
-- 2022/01/11 Ver1.2 MOD End
;
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.account_number      IS 'ÚqR[h';
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.edi_chain_code      IS 'EDI`F[XR[h';
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.edi_chain_name      IS '`F[X¼(Úq¼Ì)';
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.delivery_base_code  IS '[i_R[h';
COMMENT ON  COLUMN  xxcos_edi_chain_security_v.delivery_base_name  IS '[i_¼';
--
COMMENT ON  TABLE   xxcos_edi_chain_security_v                     IS 'EDI`F[XZLeBr[';
