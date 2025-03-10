/*************************************************************************
 * 
 * VIEW Name       : xxcso_sales_of_task_v
 * Description     : ¤ÊpFLøKâÌÀÑr[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/11/24    1.0  D.Abe        ñì¬
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_sales_of_task_v
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
,dlv_invoice_number
,digestion_ln_number
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
       ,seh.dlv_invoice_number         -- [i`[Ô
       ,seh.digestion_ln_number        -- óNoiHHTj}Ô
FROM    xxcos_sales_exp_headers seh -- ÌÀÑwb_[
       ,xxcos_sales_exp_lines   sel -- ÌÀÑ¾×
WHERE  seh.sales_exp_header_id = sel.sales_exp_header_id  -- ÌÀÑwb_ID
AND    NOT EXISTS
       ( -- iÚR[h<>Ï®dC¿iÚR[h
         SELECT 'X'
         FROM   DUAL
         WHERE  sel.item_code = fnd_profile.value('XXCOS1_ELECTRIC_FEE_ITEM_CODE')
       )
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_SALES_OF_TASK_V IS '¤ÊpFLøKâÌÀÑr[';

