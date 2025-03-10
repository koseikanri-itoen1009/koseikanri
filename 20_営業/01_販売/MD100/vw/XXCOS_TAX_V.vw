/************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_tax_v
 * Description     : ÁïÅview
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/09/09    1.0   SCS              VKì¬
 *  2013/08/23    1.1   T.Shimoji        [E_{Ò®_10904]ÁïÅÅÎ
 *
 ************************************************************************************/
CREATE OR REPLACE FORCE VIEW "APPS"."XXCOS_TAX_V" ("TAX_CODE", "TAX_RATE", "HHT_TAX_CLASS", "TAX_CLASS", "START_DATE_ACTIVE", "END_DATE_ACTIVE", "SET_OF_BOOKS_ID") AS 
SELECT  avtab.tax_code                     tax_code             -- ÁïÅR[h
       ,avtab.tax_rate                     tax_rate             -- ÁïÅ¦
-- 2013/08/23 Mod Start
--       ,SUBSTRB(look_val.lookup_code,1,1)  hht_tax_class        -- HHTÁïÅæª
       ,SUBSTRB(look_val.attribute1,1,1)  hht_tax_class        -- HHTÁïÅæª
-- 2013/08/23 Mod End
       ,look_val.attribute3                tax_class            -- ÌÀÑAgÌÁïÅæª
       ,look_val.start_date_active         start_date_active    -- NCbNR[hKpJnú
       ,look_val.end_date_active           end_date_active      -- NCbNR[hKpI¹ú
       ,avtab.set_of_books_id              set_of_books_id      -- ïv ëID
FROM    fnd_lookup_values          look_val-- bNAbvl}X^
       ,ar_vat_tax_all_b           avtab   -- ARÁïÅ}X^
WHERE   look_val.language     = USERENV( 'LANG' )
AND     look_val.enabled_flag = 'Y'
AND     look_val.lookup_type  = 'XXCOS1_CONSUMPTION_TAX_CLASS'
AND     avtab.enabled_flag    = 'Y'
AND     avtab.tax_code        = look_val.attribute2;
--
COMMENT ON  COLUMN  XXCOS_TAX_V.tax_code            IS  'ÁïÅR[h';
COMMENT ON  COLUMN  XXCOS_TAX_V.tax_rate            IS  'ÁïÅ¦';
COMMENT ON  COLUMN  XXCOS_TAX_V.hht_tax_class       IS  'HHTÁïÅæª';
COMMENT ON  COLUMN  XXCOS_TAX_V.tax_class           IS  'ÌÀÑAgÁïÅæª';
COMMENT ON  COLUMN  XXCOS_TAX_V.start_date_active   IS  'KpJnú';
COMMENT ON  COLUMN  XXCOS_TAX_V.end_date_active     IS  'KpI¹ú';
COMMENT ON  COLUMN  XXCOS_TAX_V.set_of_books_id     IS  'ïv ëID';
--
COMMENT ON  TABLE   XXCOS_TAX_V                     IS  'XXCOSÁïÅr[';