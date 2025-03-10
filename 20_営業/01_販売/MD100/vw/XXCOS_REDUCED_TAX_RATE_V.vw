/************************************************************************************
 * Copyright(c) 2018, SCSK Corporation. All rights reserved..
 *
 * View Name       : xxcos_reduced_tax_rate_v
 * Description     : iΪΚΑοΕ¦view
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2019/06/04    1.0   S.Kuwako         VKμ¬
 *
 ************************************************************************************/
CREATE OR REPLACE FORCE VIEW apps.xxcos_reduced_tax_rate_v(
   item_code                            -- iΪR[h
 , class_for_variable_tax               -- yΈΕ¦pΕνΚ
 , tax_name                             -- Ε¦L[ΌΜ
 , tax_description                      -- Ev
 , tax_histories_code                   -- ΑοΕπR[h
 , tax_histories_description            -- ΑοΕπΌΜ
 , start_date                           -- Ε¦L[_Jnϊ
 , end_date                             -- Ε¦L[_IΉϊ
 , start_date_histories                 -- ΑοΕπ_Jnϊ
 , end_date_histories                   -- ΑοΕπ_IΉϊ
 , tax_rate                             -- ΑοΕ¦
 , tax_class_suppliers_outside          -- Εζͺ_dόOΕ
 , tax_class_suppliers_inside           -- Εζͺ_dόΰΕ
 , tax_class_sales_outside              -- Εζͺ_γOΕ
 , tax_class_sales_inside               -- Εζͺ_γΰΕ
)
AS
  SELECT  xsib.item_code             item_code                    -- iΪR[h
         ,flv1.lookup_code           class_for_variable_tax       -- yΈΕ¦pΕνΚ
         ,flv1.meaning               tax_name                     -- Ε¦L[ΌΜ
         ,flv1.description           tax_description              -- Ev
         ,flv2.meaning               tax_histories_code           -- ΑοΕπR[h
         ,flv2.description           tax_histories_description    -- ΑοΕπΌΜ
         ,flv1.start_date_active     start_date                   -- Ε¦L[_Jnϊ
         ,flv1.end_date_active       end_date                     -- Ε¦L[_IΉϊ
         ,flv2.start_date_active     start_date_histories         -- ΑοΕπ_Jnϊ
         ,flv2.end_date_active       end_date_histories           -- ΑοΕπ_IΉϊ
         ,TO_NUMBER(flv2.attribute1) tax_rate                     -- ΑοΕ¦
         ,flv2.attribute2            tax_class_suppliers_outside  -- Εζͺ_dόOΕ
         ,flv2.attribute3            tax_class_suppliers_inside   -- Εζͺ_dόΰΕ
         ,flv2.attribute4            tax_class_sales_outside      -- Εζͺ_γOΕ
         ,flv2.attribute5            tax_class_sales_inside       -- Εζͺ_γΰΕ
  FROM    fnd_lookup_values          flv1                         -- yΈΕ¦pΕνΚ}X^
         ,fnd_lookup_values          flv2                         -- yΈΕ¦π}X^
         ,xxcmm_system_items_b       xsib                         -- DISCiΪAhI
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
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.item_code                   IS  'iΪR[h';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.class_for_variable_tax      IS  'yΈΕ¦pΕνΚ';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_name                    IS  'Ε¦L[ΌΜ';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_description             IS  'Ev';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_histories_code          IS  'ΑοΕπR[h';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_histories_description   IS  'ΑοΕπΌΜ';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.start_date                  IS  'Ε¦L[_Jnϊ';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.end_date                    IS  'Ε¦L[_IΉϊ';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.start_date_histories        IS  'ΑοΕπ_Jnϊ';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.end_date_histories          IS  'ΑοΕπ_IΉϊ';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_rate                    IS  'ΑοΕ¦';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_class_suppliers_outside IS  'Εζͺ_dόOΕ';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_class_suppliers_inside  IS  'Εζͺ_dόΰΕ';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_class_sales_outside     IS  'Εζͺ_γOΕ';
COMMENT ON  COLUMN  xxcos_reduced_tax_rate_v.tax_class_sales_inside      IS  'Εζͺ_γΰΕ';
--
COMMENT ON  TABLE   xxcos_reduced_tax_rate_v                             IS  'XXCOSiΪΚΑοΕ¦r[';
