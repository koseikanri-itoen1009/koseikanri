/*************************************************************************
 * 
 * VIEW Name       : xxcso_sales_v
 * Description     : 共通用：売上実績ビュー
 * MD.070          : 
 * Version         : 1.4
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 *  2009/03/03    1.1  K.Boku        売上実績振替情報テーブル取得する
 *  2009/03/09    1.1  M.Maruyama    販売実績ヘッダ.取消・訂正区分追加
 *  2009/04/22    1.2  K.Satomura    システムテスト障害対応(T1_0743)
 *  2009/05/21    1.3  K.Satomura    システムテスト障害対応(T1_1036)
 *  2013/08/12    1.4  K.Kiriu       実績振替の入金時値引対応(E_本稼動_02011)
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
/* 2009.04.22 K.Satomura T1_0743対応 START */
,dlv_invoice_number
/* 2009.04.22 K.Satomura T1_0743対応 END */
/* 2009.04.22 K.Satomura T1_1036対応 START */
,digestion_ln_number
/* 2009.04.22 K.Satomura T1_1036対応 END */
)
AS
SELECT  seh.ship_to_customer_code      -- 顧客【納品先】
       ,seh.order_no_hht               -- 受注No(HHT)
       ,seh.cancel_correct_class       -- 取消・訂正区分
       ,seh.delivery_date              -- 納品日
       ,seh.change_out_time_100        -- つり銭切れ時間１００円
       ,seh.change_out_time_10         -- つり銭切れ時間１０円
       ,sel.delivery_pattern_class     -- 納品形態区分
       ,sel.pure_amount                -- 本体金額（明細）
       ,sel.sold_out_class             -- 売切区分
       ,sel.sold_out_time              -- 売切時間
       /* 2009.04.22 K.Satomura T1_0743対応 START */
       ,seh.dlv_invoice_number         -- 納品伝票番号
       /* 2009.04.22 K.Satomura T1_0743対応 END */
       /* 2009.04.22 K.Satomura T1_1036対応 START */
       ,seh.digestion_ln_number        -- 受注No（HHT）枝番
       /* 2009.04.22 K.Satomura T1_1036対応 END */
FROM    xxcos_sales_exp_headers seh -- 販売実績ヘッダー
       ,xxcos_sales_exp_lines   sel -- 販売実績明細
WHERE  seh.sales_exp_header_id = sel.sales_exp_header_id  -- 販売実績ヘッダID
AND    NOT EXISTS
       ( -- 品目コード<>変動電気料品目コード
         SELECT 'X'
         FROM   DUAL
         WHERE  sel.item_code = fnd_profile.value('XXCOS1_ELECTRIC_FEE_ITEM_CODE')
       )
UNION ALL
SELECT  xsti.cust_code                 -- 顧客コード
       ,NULL                           -- 
       ,NULL                           -- 
       ,xsti.selling_date              -- 売上計上日
       ,NULL                           --
       ,NULL                           --
       ,xsti.delivery_form_type        -- 納品形態区分
       ,xsti.selling_amt_no_tax        -- 売上金額（税抜き）
       ,NULL                           --
       ,NULL                           --
       /* 2009.04.22 K.Satomura T1_0743対応 START */
       ,NULL                           -- 納品伝票番号
       /* 2009.04.22 K.Satomura T1_0743対応 END */
       /* 2009.04.22 K.Satomura T1_1036対応 START */
       ,NULL                           -- 受注No（HHT）枝番
       /* 2009.04.22 K.Satomura T1_1036対応 END */
FROM    xxcok_selling_trns_info xsti   -- 売上実績振替情報テーブル
WHERE  NOT EXISTS 
       ( -- 品目コード<>変動電気料・入金値引品目コード
         SELECT 'X'
         FROM   DUAL
/* 2013.08.12 K.Kiriu E_本稼動_02011 MOD START */
--         WHERE  xsti.item_code = fnd_profile.value('XXCOS1_ELECTRIC_FEE_ITEM_CODE')
         WHERE  xsti.item_code IN (
            fnd_profile.value('XXCOS1_ELECTRIC_FEE_ITEM_CODE')
           ,fnd_profile.value('XXCOS1_PAYMENT_DISCOUNTS_CODE')
         )
/* 2013.08.12 K.Kiriu E_本稼動_02011 MOD END */
       )
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_SALES_V IS '共通用：売上実績ビュー';

