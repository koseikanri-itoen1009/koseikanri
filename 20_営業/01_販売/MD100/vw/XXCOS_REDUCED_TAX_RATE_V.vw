/************************************************************************************
 * Copyright(c) 2018, SCSK Corporation. All rights reserved..
 *
 * View Name       : xxcos_reduced_tax_rate_v
 * Description     : 品目別消費税率view
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2019/06/04    1.0   S.Kuwako         新規作成
 *
 ************************************************************************************/
CREATE OR REPLACE FORCE VIEW apps.xxcos_reduced_tax_rate_v(
   item_code                            -- 品目コード
 , class_for_variable_tax               -- 軽減税率用税種別
 , tax_name                             -- 税率キー名称
 , tax_description                      -- 摘要
 , tax_histories_code                   -- 消費税履歴コード
 , tax_histories_description            -- 消費税履歴名称
 , start_date                           -- 税率キー_開始日
 , end_date                             -- 税率キー_終了日
 , start_date_histories                 -- 消費税履歴_開始日
 , end_date_histories                   -- 消費税履歴_終了日
 , tax_rate                             -- 消費税率
 , tax_class_suppliers_outside          -- 税区分_仕入外税
 , tax_class_suppliers_inside           -- 税区分_仕入内税
 , tax_class_sales_outside              -- 税区分_売上外税
 , tax_class_sales_inside               -- 税区分_売上内税
)
AS
  SELECT  xsib.item_code             item_code                    -- 品目コード
         ,flv1.lookup_code           class_for_variable_tax       -- 軽減税率用税種別
         ,flv1.meaning               tax_name                     -- 税率キー名称
         ,flv1.description           tax_description              -- 摘要
         ,flv2.meaning               tax_histories_code           -- 消費税履歴コード
         ,flv2.description           tax_histories_description    -- 消費税履歴名称
         ,flv1.start_date_active     start_date                   -- 税率キー_開始日
         ,flv1.end_date_active       end_date                     -- 税率キー_終了日
         ,flv2.start_date_active     start_date_histories         -- 消費税履歴_開始日
         ,flv2.end_date_active       end_date_histories           -- 消費税履歴_終了日
         ,TO_NUMBER(flv2.attribute1) tax_rate                     -- 消費税率
         ,flv2.attribute2            tax_class_suppliers_outside  -- 税区分_仕入外税
         ,flv2.attribute3            tax_class_suppliers_inside   -- 税区分_仕入内税
         ,flv2.attribute4            tax_class_sales_outside      -- 税区分_売上外税
         ,flv2.attribute5            tax_class_sales_inside       -- 税区分_売上内税
  FROM    fnd_lookup_values          flv1                         -- 軽減税率用税種別マスタ
         ,fnd_lookup_values          flv2                         -- 軽減税率履歴マスタ
         ,xxcmm_system_items_b       xsib                         -- DISC品目アドオン
  WHERE   flv1.lookup_code             =  flv2.tag
  AND     xsib.class_for_variable_tax  =  flv1.lookup_code
  AND     flv1.lookup_type             = 'XXCFO1_TAX_CODE'
  AND     flv2.lookup_type             = 'XXCFO1_TAX_CODE_HISTORIES'
  AND     flv1.language                =  USERENV( 'LANG' )
  AND     flv2.language                =  USERENV( 'LANG' )
  AND     flv1.enabled_flag            = 'Y'
  AND     flv2.enabled_flag            = 'Y'
  ;
--
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.item_code                   IS  '品目コード';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.class_for_variable_tax      IS  '軽減税率用税種別';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_name                    IS  '税率キー名称';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_description             IS  '摘要';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_histories_code          IS  '消費税履歴コード';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_histories_description   IS  '消費税履歴名称';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.start_date                  IS  '税率キー_開始日';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.end_date                    IS  '税率キー_終了日';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.start_date_histories        IS  '消費税履歴_開始日';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.end_date_histories          IS  '消費税履歴_終了日';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_rate                    IS  '消費税率';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_class_suppliers_outside IS  '税区分_仕入外税';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_class_suppliers_inside  IS  '税区分_仕入内税';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_class_sales_outside     IS  '税区分_売上外税';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_class_sales_inside      IS  '税区分_売上内税';
--
COMMENT ON  TABLE   xxcos_reduced_tax_rate_v                             IS  'XXCOS品目別消費税率ビュー';
