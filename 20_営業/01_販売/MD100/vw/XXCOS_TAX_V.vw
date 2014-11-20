/************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_tax_v
 * Description     : 消費税view
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/09/09    1.0   SCS              新規作成
 *  2013/08/23    1.1   T.Shimoji        [E_本稼動_10904]消費税増税対応
 *
 ************************************************************************************/
CREATE OR REPLACE FORCE VIEW "APPS"."XXCOS_TAX_V" ("TAX_CODE", "TAX_RATE", "HHT_TAX_CLASS", "TAX_CLASS", "START_DATE_ACTIVE", "END_DATE_ACTIVE", "SET_OF_BOOKS_ID") AS 
SELECT  avtab.tax_code                     tax_code             -- 消費税コード
       ,avtab.tax_rate                     tax_rate             -- 消費税率
-- 2013/08/23 Mod Start
--       ,SUBSTRB(look_val.lookup_code,1,1)  hht_tax_class        -- HHT消費税区分
       ,SUBSTRB(look_val.attribute1,1,1)  hht_tax_class        -- HHT消費税区分
-- 2013/08/23 Mod End
       ,look_val.attribute3                tax_class            -- 販売実績連携時の消費税区分
       ,look_val.start_date_active         start_date_active    -- クイックコード適用開始日
       ,look_val.end_date_active           end_date_active      -- クイックコード適用終了日
       ,avtab.set_of_books_id              set_of_books_id      -- 会計帳簿ID
FROM    fnd_lookup_values          look_val-- ルックアップ値マスタ
       ,ar_vat_tax_all_b           avtab   -- AR消費税マスタ
WHERE   look_val.language     = USERENV( 'LANG' )
AND     look_val.enabled_flag = 'Y'
AND     look_val.lookup_type  = 'XXCOS1_CONSUMPTION_TAX_CLASS'
AND     avtab.enabled_flag    = 'Y'
AND     avtab.tax_code        = look_val.attribute2;
--
COMMENT ON  COLUMN  XXCOS_TAX_V.tax_code            IS  '消費税コード';
COMMENT ON  COLUMN  XXCOS_TAX_V.tax_rate            IS  '消費税率';
COMMENT ON  COLUMN  XXCOS_TAX_V.hht_tax_class       IS  'HHT消費税区分';
COMMENT ON  COLUMN  XXCOS_TAX_V.tax_class           IS  '販売実績連携消費税区分';
COMMENT ON  COLUMN  XXCOS_TAX_V.start_date_active   IS  '適用開始日';
COMMENT ON  COLUMN  XXCOS_TAX_V.end_date_active     IS  '適用終了日';
COMMENT ON  COLUMN  XXCOS_TAX_V.set_of_books_id     IS  '会計帳簿ID';
--
COMMENT ON  TABLE   XXCOS_TAX_V                     IS  'XXCOS消費税ビュー';