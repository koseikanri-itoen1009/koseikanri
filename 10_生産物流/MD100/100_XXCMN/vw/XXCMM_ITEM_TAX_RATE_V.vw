/*************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 * 
 * VIEW Name       : xxcmm_item_tax_rate_v
 * Description     : 消費税率VIEW
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2019/04/25    1.0   Y.Shoji      初回作成
 *
 ************************************************************************/
 CREATE OR REPLACE VIEW apps.xxcmm_item_tax_rate_v(
    item_id             -- 品目ID
   ,item_no             -- 品目NO
   ,tax                 -- 税率
   ,start_date_active   -- 適用開始日
   ,end_date_active     -- 適用終了日
   ,tax_code_ex         -- 税コード（仕入・外税）
   ,tax_code_in         -- 税コード（仕入・内税）
   ,tax_code_sales_ex   -- 税コード（売上・外税）
   ,tax_code_sales_in   -- 税コード（売上・内税）
 )
 AS
-- 1.OPM品目の食品区分から税率を取得するケース
--   OPM品目の食品区分が存在する場合
SELECT /*+ LEADING(iimb1) */
       iimb1.item_id                  item_id            -- 品目ID
      ,iimb1.item_no                  item_no            -- 品目NO
      ,flv_hist_o1.attribute1         tax                -- 税率
      ,flv_hist_o1.start_date_active  start_date_active  -- 適用開始日
      ,flv_hist_o1.end_date_active    end_date_active    -- 適用終了日
      ,flv_hist_o1.attribute2         tax_code_ex        -- 税コード（仕入・外税）
      ,flv_hist_o1.attribute3         tax_code_in        -- 税コード（仕入・内税）
      ,flv_hist_o1.attribute4         tax_code_sales_ex  -- 税コード（売上・外税）
      ,flv_hist_o1.attribute5         tax_code_sales_in  -- 税コード（売上・内税）
FROM   ic_item_mst_b             iimb1        -- OPM品目マスタ1
      ,gmi_item_categories       gic1         -- OPM品目カテゴリ割当
      ,mtl_categories_b          mcb1         -- 品目カテゴリマスタ
      ,mtl_categories_tl         mct1         -- 品目カテゴリマスタ日本語
      ,fnd_lookup_values         flv_tax_o1   -- OPM消費税コード（軽減税率対応用）
      ,fnd_lookup_values         flv_hist_o1  -- OPM消費税履歴（軽減税率対応用）
WHERE  iimb1.item_id            = gic1.item_id
AND    gic1.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_SYOKUHIN_CLASS')
AND    gic1.category_id         = mcb1.category_id
AND    mcb1.category_id         = mct1.category_id
AND    mct1.source_lang         = 'JA'
AND    mct1.language            = 'JA'
AND    mcb1.segment1            = flv_tax_o1.lookup_code
AND    flv_tax_o1.lookup_type   = 'XXCFO1_TAX_CODE'
AND    flv_tax_o1.language      = USERENV('LANG')
AND    flv_tax_o1.enabled_flag  = 'Y'
AND    flv_tax_o1.lookup_code   = flv_hist_o1.tag
AND    flv_hist_o1.lookup_type  = 'XXCFO1_TAX_CODE_HISTORIES'
AND    flv_hist_o1.language     = USERENV('LANG')
AND    flv_hist_o1.enabled_flag = 'Y'
--
UNION ALL
--
-- 2.DISC品目の食品区分から税率を取得するケース
--   品目区分:5（製品）で、
--   OPM品目の食品区分が存在しない、かつ
--   DISC品目の食品区分が存在する場合
SELECT /*+ LEADING(iimb2)
           USE_NL(xicv52.gic_s xicv52.mcb_s)
           USE_NL(xicv52.gic_h xicv52.mcb_h)
           USE_NL(xsib2 flv_tax_d2) */
       iimb2.item_id                   item_id            -- 品目ID
      ,iimb2.item_no                   item_no            -- 品目NO
      ,flv_hist_d2.attribute1          tax                -- 税率
      ,flv_hist_d2.start_date_active   start_date_active  -- 適用開始日
      ,flv_hist_d2.end_date_active     end_date_active    -- 適用終了日
      ,flv_hist_d2.attribute2          tax_code_ex        -- 税コード（仕入・外税）
      ,flv_hist_d2.attribute3          tax_code_in        -- 税コード（仕入・内税）
      ,flv_hist_d2.attribute4          tax_code_sales_ex  -- 税コード（売上・外税）
      ,flv_hist_d2.attribute5          tax_code_sales_in  -- 税コード（売上・内税）
FROM   ic_item_mst_b             iimb2        -- OPM品目マスタ1
      ,xxcmn_item_categories5_v  xicv52       -- OPM品目カテゴリ割当情報VIEW5
      ,xxcmm_system_items_b      xsib2        -- DISC品目アドオン
      ,fnd_lookup_values         flv_tax_d2   -- OPM消費税コード（軽減税率対応用）
      ,fnd_lookup_values         flv_hist_d2  -- OPM消費税履歴（軽減税率対応用）
WHERE  iimb2.item_id                = xicv52.item_id
AND    xicv52.item_class_code       = '5'
AND    iimb2.item_id                = xsib2.item_id
AND    xsib2.class_for_variable_tax = flv_tax_d2.lookup_code
AND    flv_tax_d2.lookup_type       = 'XXCFO1_TAX_CODE'
AND    flv_tax_d2.language          = USERENV('LANG')
AND    flv_tax_d2.enabled_flag      = 'Y'
AND    flv_tax_d2.lookup_code       = flv_hist_d2.tag
AND    flv_hist_d2.lookup_type      = 'XXCFO1_TAX_CODE_HISTORIES'
AND    flv_hist_d2.language         = USERENV('LANG')
AND    flv_hist_d2.enabled_flag     = 'Y'
-- OPM品目の食品区分が存在しない
AND    NOT EXISTS(SELECT 1
                  FROM   gmi_item_categories       gic2         -- OPM品目カテゴリ割当
                        ,mtl_categories_b          mcb2         -- 品目カテゴリマスタ
                        ,mtl_categories_tl         mct2         -- 品目カテゴリマスタ日本語
                  WHERE  iimb2.item_id        = gic2.item_id
                  AND    gic2.category_set_id = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_SYOKUHIN_CLASS')
                  AND    gic2.category_id     = mcb2.category_id
                  AND    mcb2.category_id     = mct2.category_id
                  AND    mct2.source_lang     = 'JA'
                  AND    mct2.language        = 'JA')
--
UNION ALL
--
-- 3.品目カテゴリに設定された税率を取得するケース（製品）
--   品目区分:5（製品）で、
--   OPM品目の食品区分が存在しない、かつ
--   DISC品目の食品区分も存在しない場合
SELECT /*+ LEADING(iimb3)
           USE_NL(xicv53.gic_s xicv53.mcb_s)
           USE_NL(xicv53.gic_h xicv53.mcb_h)
           USE_NL(xicv53.mcb_h flv_cat3) */
       iimb3.item_id                item_id            -- 品目ID
      ,iimb3.item_no                item_no            -- 品目NO
      ,flv_cat3.attribute1          tax                -- 税率
      ,flv_cat3.start_date_active   start_date_active  -- 適用開始日
      ,flv_cat3.end_date_active     end_date_active    -- 適用終了日
      ,flv_cat3.attribute2          tax_code_ex        -- 税コード（仕入・外税）
      ,flv_cat3.attribute3          tax_code_in        -- 税コード（仕入・内税）
      ,flv_cat3.attribute4          tax_code_sales_ex  -- 税コード（売上・外税）
      ,flv_cat3.attribute5          tax_code_sales_in  -- 税コード（売上・内税）
FROM   ic_item_mst_b             iimb3        -- OPM品目マスタ1
      ,xxcmn_item_categories5_v  xicv53       -- OPM品目カテゴリ割当情報VIEW5
      ,fnd_lookup_values         flv_cat3     -- 参照タイプ：品目カテゴリ消費税分類
WHERE  iimb3.item_id          = xicv53.item_id
AND    xicv53.item_class_code = '5'
AND    xicv53.item_class_code = flv_cat3.description
AND    flv_cat3.lookup_type   = 'XXCMN_ITEM_CATEGORY_TAX_KBN'
AND    flv_cat3.language      = USERENV('LANG')
AND    flv_cat3.enabled_flag  = 'Y'
-- OPM品目の食品区分が存在しない
AND    NOT EXISTS(SELECT 1
                  FROM   gmi_item_categories       gic3         -- OPM品目カテゴリ割当
                        ,mtl_categories_b          mcb3         -- 品目カテゴリマスタ
                        ,mtl_categories_tl         mct3         -- 品目カテゴリマスタ日本語
                  WHERE  iimb3.item_id          = gic3.item_id
                  AND    gic3.category_set_id  = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_SYOKUHIN_CLASS')
                  AND    gic3.category_id      = mcb3.category_id
                  AND    mcb3.category_id      = mct3.category_id
                  AND    mct3.source_lang      = 'JA'
                  AND    mct3.language         = 'JA')
-- DISC品目の食品区分が存在しない
AND    NOT EXISTS(SELECT 1
                  FROM   xxcmm_system_items_b   xsib3  -- DISC品目アドオン
                  WHERE  iimb3.item_id                = xsib3.item_id
                  AND    xsib3.class_for_variable_tax IS NOT NULL)
--
UNION ALL
-- 4.品目カテゴリに設定された税率を取得するケース（製品以外）
--   品目区分:5（製品）以外で、
--   OPM品目の食品区分が存在しない場合
SELECT /*+ LEADING(iimb4)
           USE_NL(xicv54.gic_s xicv54.mcb_s)
           USE_NL(xicv54.gic_h xicv54.mcb_h)
           USE_NL(xicv54.mcb_h flv_cat4) */
       iimb4.item_id                item_id            -- 品目ID
      ,iimb4.item_no                item_no            -- 品目NO
      ,flv_cat4.attribute1          tax                -- 税率
      ,flv_cat4.start_date_active   start_date_active  -- 適用開始日
      ,flv_cat4.end_date_active     end_date_active    -- 適用終了日
      ,flv_cat4.attribute2          tax_code_ex        -- 税コード（仕入・外税）
      ,flv_cat4.attribute3          tax_code_in        -- 税コード（仕入・内税）
      ,flv_cat4.attribute4          tax_code_sales_ex  -- 税コード（売上・外税）
      ,flv_cat4.attribute5          tax_code_sales_in  -- 税コード（売上・内税）
FROM   ic_item_mst_b             iimb4        -- OPM品目マスタ1
      ,xxcmn_item_categories5_v  xicv54       -- OPM品目カテゴリ割当情報VIEW5
      ,fnd_lookup_values         flv_cat4     -- 参照タイプ：品目カテゴリ消費税分類
WHERE  iimb4.item_id          = xicv54.item_id
AND    xicv54.item_class_code IN ('1' ,'2' ,'4')
AND    xicv54.item_class_code = flv_cat4.description
AND    flv_cat4.lookup_type   = 'XXCMN_ITEM_CATEGORY_TAX_KBN'
AND    flv_cat4.language      = USERENV('LANG')
AND    flv_cat4.enabled_flag  = 'Y'
-- OPM品目の食品区分が存在しない
AND    NOT EXISTS(SELECT 1
                  FROM   gmi_item_categories       gic4         -- OPM品目カテゴリ割当
                        ,mtl_categories_b          mcb4         -- 品目カテゴリマスタ
                        ,mtl_categories_tl         mct4         -- 品目カテゴリマスタ日本語
                  WHERE  iimb4.item_id          = gic4.item_id
                  AND    gic4.category_set_id  = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_SYOKUHIN_CLASS')
                  AND    gic4.category_id      = mcb4.category_id
                  AND    mcb4.category_id      = mct4.category_id
                  AND    mct4.source_lang      = 'JA'
                  AND    mct4.language         = 'JA')
;
/
COMMENT ON TABLE xxcmm_item_tax_rate_v IS '消費税率VIEW';
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.item_id              IS '品目ID'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.item_no              IS '品目NO'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.tax                  IS '税率'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.start_date_active    IS '適用開始日'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.end_date_active      IS '適用終了日'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.tax_code_ex          IS '税コード（仕入・外税）'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.tax_code_in          IS '税コード（仕入・内税）'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.tax_code_sales_ex    IS '税コード（売上・外税）'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.tax_code_sales_in    IS '税コード（売上・内税）'
/
