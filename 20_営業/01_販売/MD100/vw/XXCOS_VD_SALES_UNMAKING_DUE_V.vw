/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_vd_sales_unmaking_due_v
 * Description     : 消化VD販売実績未作成締日ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/20    1.0   K.Atsushiba      新規作成
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOS_VD_SALES_UNMAKING_DUE_V
AS
SELECT DISTINCT
       hca_b.account_number                         base_code
       ,TO_CHAR(xsdh.digestion_due_date,'YYYY/MM/DD') due_date
FROM   hz_cust_accounts hca_c
       ,xxcmm_cust_accounts xca_c
       ,hz_cust_accounts hca_b
       ,xxcmm_cust_accounts xca_b
       ,xxcos_vd_digestion_hdrs xsdh
WHERE  xsdh.sales_result_creation_flag = 'N'
AND    xsdh.uncalculate_class          = '0'
AND    hca_c.cust_account_id  = xca_c.customer_id
AND    hca_b.cust_account_id  = xca_b.customer_id
AND    hca_b.account_number   = NVL( xca_c.past_sale_base_code,xca_c.sale_base_code )
AND    hca_c.account_number   = xsdh.customer_number
AND    EXISTS (SELECT  flv.meaning
                 FROM  fnd_lookup_values             flv
                       ,xxccp_process_dates          xpd
                WHERE  flv.lookup_type    = 'XXCOS1_CUS_CLASS_MST_004_A04'
                  AND  flv.lookup_code    LIKE 'XXCOS_004_A04_2%'
                  AND  flv.enabled_flag   = 'Y'
                  AND  flv.language       = 'JA'
                  AND  flv.meaning        = hca_c.customer_class_code
                  AND  TRUNC( xpd.process_date )  BETWEEN NVL( flv.start_date_active, TRUNC( xpd.process_date ) )
                                                  AND     NVL( flv.end_date_active, TRUNC( xpd.process_date ) )
              )
AND    EXISTS (SELECT   flv.meaning
                 FROM   fnd_lookup_values     flv
                        ,xxccp_process_dates  xpd
                WHERE   flv.lookup_type      = 'XXCOS1_CUS_CLASS_MST_004_A04'
                  AND   flv.lookup_code      LIKE 'XXCOS_004_A04_1%'
                  AND   flv.enabled_flag     = 'Y'
                  AND   flv.language         = 'JA'
                  AND   flv.meaning          = hca_b.customer_class_code
                  AND   TRUNC( xpd.process_date )     BETWEEN NVL( flv.start_date_active, TRUNC( xpd.process_date ))
                                                      AND     NVL( flv.end_date_active, TRUNC( xpd.process_date ) )
              )
AND    EXISTS (SELECT   flv.meaning
                 FROM   fnd_lookup_values      flv
                        ,xxccp_process_dates   xpd
                WHERE   flv.lookup_type    = 'XXCOS1_GYOTAI_SHO_MST_004_A04'
                  AND   flv.lookup_code    LIKE 'XXCOS_004_A04%'
                  AND   flv.enabled_flag   = 'Y'
                  AND   flv.language       = 'JA'
                  AND   flv.meaning        = xca_c.business_low_type
                  AND   TRUNC( xpd.process_date )   BETWEEN NVL( flv.start_date_active, TRUNC( xpd.process_date ) )
                                                    AND     NVL( flv.end_date_active, TRUNC( xpd.process_date ) )
              )
;
COMMENT ON  COLUMN  xxcos_vd_sales_unmaking_due_v.base_code          IS  '拠点コード';
COMMENT ON  COLUMN  xxcos_vd_sales_unmaking_due_v.due_date           IS  '締日';

