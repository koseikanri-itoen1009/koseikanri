/*************************************************************************
 * 
 * VIEW Name       : xxcso_sales_v
 * Description     : ¤ÊpFãÀÑr[
 * MD.070          : 
 * Version         : 1.4
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ñì¬
 *  2009/03/03    1.1  K.Boku        ãÀÑUÖîñe[uæ¾·é
 *  2009/03/09    1.1  M.Maruyama    ÌÀÑwb_.æÁEù³æªÇÁ
 *  2009/04/22    1.2  K.Satomura    VXeeXgáQÎ(T1_0743)
 *  2009/05/21    1.3  K.Satomura    VXeeXgáQÎ(T1_1036)
 *  2013/08/12    1.4  K.Kiriu       ÀÑUÖÌüàløÎ(E_{Ò®_02011)
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_sales_v
(
 account_number
,order_no_hht
,cancel_correct_class
,delivery_date
,change_out_time_100
,change_out_time_10
,delivery_pattern_class
,pure_amount
,sold_out_class
,sold_out_time
/* 2009.04.22 K.Satomura T1_0743Î START */
,dlv_invoice_number
/* 2009.04.22 K.Satomura T1_0743Î END */
/* 2009.04.22 K.Satomura T1_1036Î START */
,digestion_ln_number
/* 2009.04.22 K.Satomura T1_1036Î END */
)
AS
SELECT  seh.ship_to_customer_code      -- Úqy[iæz
       ,seh.order_no_hht               -- óNo(HHT)
       ,seh.cancel_correct_class       -- æÁEù³æª
       ,seh.delivery_date              -- [iú
       ,seh.change_out_time_100        -- ÂèKØêÔPOO~
       ,seh.change_out_time_10         -- ÂèKØêÔPO~
       ,sel.delivery_pattern_class     -- [i`Ôæª
       ,sel.pure_amount                -- {Ìàzi¾×j
       ,sel.sold_out_class             -- Øæª
       ,sel.sold_out_time              -- ØÔ
       /* 2009.04.22 K.Satomura T1_0743Î START */
       ,seh.dlv_invoice_number         -- [i`[Ô
       /* 2009.04.22 K.Satomura T1_0743Î END */
       /* 2009.04.22 K.Satomura T1_1036Î START */
       ,seh.digestion_ln_number        -- óNoiHHTj}Ô
       /* 2009.04.22 K.Satomura T1_1036Î END */
FROM    xxcos_sales_exp_headers seh -- ÌÀÑwb_[
       ,xxcos_sales_exp_lines   sel -- ÌÀÑ¾×
WHERE  seh.sales_exp_header_id = sel.sales_exp_header_id  -- ÌÀÑwb_ID
AND    NOT EXISTS
       ( -- iÚR[h<>Ï®dC¿iÚR[h
         SELECT 'X'
         FROM   DUAL
         WHERE  sel.item_code = fnd_profile.value('XXCOS1_ELECTRIC_FEE_ITEM_CODE')
       )
UNION ALL
SELECT  xsti.cust_code                 -- ÚqR[h
       ,NULL                           -- 
       ,NULL                           -- 
       ,xsti.selling_date              -- ãvãú
       ,NULL                           --
       ,NULL                           --
       ,xsti.delivery_form_type        -- [i`Ôæª
       ,xsti.selling_amt_no_tax        -- ãàziÅ²«j
       ,NULL                           --
       ,NULL                           --
       /* 2009.04.22 K.Satomura T1_0743Î START */
       ,NULL                           -- [i`[Ô
       /* 2009.04.22 K.Satomura T1_0743Î END */
       /* 2009.04.22 K.Satomura T1_1036Î START */
       ,NULL                           -- óNoiHHTj}Ô
       /* 2009.04.22 K.Satomura T1_1036Î END */
FROM    xxcok_selling_trns_info xsti   -- ãÀÑUÖîñe[u
WHERE  NOT EXISTS 
       ( -- iÚR[h<>Ï®dC¿EüàløiÚR[h
         SELECT 'X'
         FROM   DUAL
/* 2013.08.12 K.Kiriu E_{Ò®_02011 MOD START */
--         WHERE  xsti.item_code = fnd_profile.value('XXCOS1_ELECTRIC_FEE_ITEM_CODE')
         WHERE  xsti.item_code IN (
            fnd_profile.value('XXCOS1_ELECTRIC_FEE_ITEM_CODE')
           ,fnd_profile.value('XXCOS1_PAYMENT_DISCOUNTS_CODE')
         )
/* 2013.08.12 K.Kiriu E_{Ò®_02011 MOD END */
       )
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_SALES_V IS '¤ÊpFãÀÑr[';

