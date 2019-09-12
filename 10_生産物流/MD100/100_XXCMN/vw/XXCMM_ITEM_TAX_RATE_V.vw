/*************************************************************************
 * Copyright(c)SCSK Corporation, 2019. All rights reserved.
 * 
 * VIEW Name       : xxcmm_item_tax_rate_v
 * Description     : ����ŗ�VIEW
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2019/04/25    1.0   Y.Shoji      ����쐬
 *
 ************************************************************************/
 CREATE OR REPLACE VIEW apps.xxcmm_item_tax_rate_v(
    item_id             -- �i��ID
   ,item_no             -- �i��NO
   ,tax                 -- �ŗ�
   ,start_date_active   -- �K�p�J�n��
   ,end_date_active     -- �K�p�I����
   ,tax_code_ex         -- �ŃR�[�h�i�d���E�O�Łj
   ,tax_code_in         -- �ŃR�[�h�i�d���E���Łj
   ,tax_code_sales_ex   -- �ŃR�[�h�i����E�O�Łj
   ,tax_code_sales_in   -- �ŃR�[�h�i����E���Łj
 )
 AS
-- 1.OPM�i�ڂ̐H�i�敪����ŗ����擾����P�[�X
--   OPM�i�ڂ̐H�i�敪�����݂���ꍇ
SELECT /*+ LEADING(iimb1) */
       iimb1.item_id                  item_id            -- �i��ID
      ,iimb1.item_no                  item_no            -- �i��NO
      ,flv_hist_o1.attribute1         tax                -- �ŗ�
      ,flv_hist_o1.start_date_active  start_date_active  -- �K�p�J�n��
      ,flv_hist_o1.end_date_active    end_date_active    -- �K�p�I����
      ,flv_hist_o1.attribute2         tax_code_ex        -- �ŃR�[�h�i�d���E�O�Łj
      ,flv_hist_o1.attribute3         tax_code_in        -- �ŃR�[�h�i�d���E���Łj
      ,flv_hist_o1.attribute4         tax_code_sales_ex  -- �ŃR�[�h�i����E�O�Łj
      ,flv_hist_o1.attribute5         tax_code_sales_in  -- �ŃR�[�h�i����E���Łj
FROM   ic_item_mst_b             iimb1        -- OPM�i�ڃ}�X�^1
      ,gmi_item_categories       gic1         -- OPM�i�ڃJ�e�S������
      ,mtl_categories_b          mcb1         -- �i�ڃJ�e�S���}�X�^
      ,mtl_categories_tl         mct1         -- �i�ڃJ�e�S���}�X�^���{��
      ,fnd_lookup_values         flv_tax_o1   -- OPM����ŃR�[�h�i�y���ŗ��Ή��p�j
      ,fnd_lookup_values         flv_hist_o1  -- OPM����ŗ����i�y���ŗ��Ή��p�j
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
-- 2.DISC�i�ڂ̐H�i�敪����ŗ����擾����P�[�X
--   �i�ڋ敪:5�i���i�j�ŁA
--   OPM�i�ڂ̐H�i�敪�����݂��Ȃ��A����
--   DISC�i�ڂ̐H�i�敪�����݂���ꍇ
SELECT /*+ LEADING(iimb2)
           USE_NL(xicv52.gic_s xicv52.mcb_s)
           USE_NL(xicv52.gic_h xicv52.mcb_h)
           USE_NL(xsib2 flv_tax_d2) */
       iimb2.item_id                   item_id            -- �i��ID
      ,iimb2.item_no                   item_no            -- �i��NO
      ,flv_hist_d2.attribute1          tax                -- �ŗ�
      ,flv_hist_d2.start_date_active   start_date_active  -- �K�p�J�n��
      ,flv_hist_d2.end_date_active     end_date_active    -- �K�p�I����
      ,flv_hist_d2.attribute2          tax_code_ex        -- �ŃR�[�h�i�d���E�O�Łj
      ,flv_hist_d2.attribute3          tax_code_in        -- �ŃR�[�h�i�d���E���Łj
      ,flv_hist_d2.attribute4          tax_code_sales_ex  -- �ŃR�[�h�i����E�O�Łj
      ,flv_hist_d2.attribute5          tax_code_sales_in  -- �ŃR�[�h�i����E���Łj
FROM   ic_item_mst_b             iimb2        -- OPM�i�ڃ}�X�^1
      ,xxcmn_item_categories5_v  xicv52       -- OPM�i�ڃJ�e�S���������VIEW5
      ,xxcmm_system_items_b      xsib2        -- DISC�i�ڃA�h�I��
      ,fnd_lookup_values         flv_tax_d2   -- OPM����ŃR�[�h�i�y���ŗ��Ή��p�j
      ,fnd_lookup_values         flv_hist_d2  -- OPM����ŗ����i�y���ŗ��Ή��p�j
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
-- OPM�i�ڂ̐H�i�敪�����݂��Ȃ�
AND    NOT EXISTS(SELECT 1
                  FROM   gmi_item_categories       gic2         -- OPM�i�ڃJ�e�S������
                        ,mtl_categories_b          mcb2         -- �i�ڃJ�e�S���}�X�^
                        ,mtl_categories_tl         mct2         -- �i�ڃJ�e�S���}�X�^���{��
                  WHERE  iimb2.item_id        = gic2.item_id
                  AND    gic2.category_set_id = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_SYOKUHIN_CLASS')
                  AND    gic2.category_id     = mcb2.category_id
                  AND    mcb2.category_id     = mct2.category_id
                  AND    mct2.source_lang     = 'JA'
                  AND    mct2.language        = 'JA')
--
UNION ALL
--
-- 3.�i�ڃJ�e�S���ɐݒ肳�ꂽ�ŗ����擾����P�[�X�i���i�j
--   �i�ڋ敪:5�i���i�j�ŁA
--   OPM�i�ڂ̐H�i�敪�����݂��Ȃ��A����
--   DISC�i�ڂ̐H�i�敪�����݂��Ȃ��ꍇ
SELECT /*+ LEADING(iimb3)
           USE_NL(xicv53.gic_s xicv53.mcb_s)
           USE_NL(xicv53.gic_h xicv53.mcb_h)
           USE_NL(xicv53.mcb_h flv_cat3) */
       iimb3.item_id                item_id            -- �i��ID
      ,iimb3.item_no                item_no            -- �i��NO
      ,flv_cat3.attribute1          tax                -- �ŗ�
      ,flv_cat3.start_date_active   start_date_active  -- �K�p�J�n��
      ,flv_cat3.end_date_active     end_date_active    -- �K�p�I����
      ,flv_cat3.attribute2          tax_code_ex        -- �ŃR�[�h�i�d���E�O�Łj
      ,flv_cat3.attribute3          tax_code_in        -- �ŃR�[�h�i�d���E���Łj
      ,flv_cat3.attribute4          tax_code_sales_ex  -- �ŃR�[�h�i����E�O�Łj
      ,flv_cat3.attribute5          tax_code_sales_in  -- �ŃR�[�h�i����E���Łj
FROM   ic_item_mst_b             iimb3        -- OPM�i�ڃ}�X�^1
      ,xxcmn_item_categories5_v  xicv53       -- OPM�i�ڃJ�e�S���������VIEW5
      ,fnd_lookup_values         flv_cat3     -- �Q�ƃ^�C�v�F�i�ڃJ�e�S������ŕ���
WHERE  iimb3.item_id          = xicv53.item_id
AND    xicv53.item_class_code = '5'
AND    xicv53.item_class_code = flv_cat3.description
AND    flv_cat3.lookup_type   = 'XXCMN_ITEM_CATEGORY_TAX_KBN'
AND    flv_cat3.language      = USERENV('LANG')
AND    flv_cat3.enabled_flag  = 'Y'
-- OPM�i�ڂ̐H�i�敪�����݂��Ȃ�
AND    NOT EXISTS(SELECT 1
                  FROM   gmi_item_categories       gic3         -- OPM�i�ڃJ�e�S������
                        ,mtl_categories_b          mcb3         -- �i�ڃJ�e�S���}�X�^
                        ,mtl_categories_tl         mct3         -- �i�ڃJ�e�S���}�X�^���{��
                  WHERE  iimb3.item_id          = gic3.item_id
                  AND    gic3.category_set_id  = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_SYOKUHIN_CLASS')
                  AND    gic3.category_id      = mcb3.category_id
                  AND    mcb3.category_id      = mct3.category_id
                  AND    mct3.source_lang      = 'JA'
                  AND    mct3.language         = 'JA')
-- DISC�i�ڂ̐H�i�敪�����݂��Ȃ�
AND    NOT EXISTS(SELECT 1
                  FROM   xxcmm_system_items_b   xsib3  -- DISC�i�ڃA�h�I��
                  WHERE  iimb3.item_id                = xsib3.item_id
                  AND    xsib3.class_for_variable_tax IS NOT NULL)
--
UNION ALL
-- 4.�i�ڃJ�e�S���ɐݒ肳�ꂽ�ŗ����擾����P�[�X�i���i�ȊO�j
--   �i�ڋ敪:5�i���i�j�ȊO�ŁA
--   OPM�i�ڂ̐H�i�敪�����݂��Ȃ��ꍇ
SELECT /*+ LEADING(iimb4)
           USE_NL(xicv54.gic_s xicv54.mcb_s)
           USE_NL(xicv54.gic_h xicv54.mcb_h)
           USE_NL(xicv54.mcb_h flv_cat4) */
       iimb4.item_id                item_id            -- �i��ID
      ,iimb4.item_no                item_no            -- �i��NO
      ,flv_cat4.attribute1          tax                -- �ŗ�
      ,flv_cat4.start_date_active   start_date_active  -- �K�p�J�n��
      ,flv_cat4.end_date_active     end_date_active    -- �K�p�I����
      ,flv_cat4.attribute2          tax_code_ex        -- �ŃR�[�h�i�d���E�O�Łj
      ,flv_cat4.attribute3          tax_code_in        -- �ŃR�[�h�i�d���E���Łj
      ,flv_cat4.attribute4          tax_code_sales_ex  -- �ŃR�[�h�i����E�O�Łj
      ,flv_cat4.attribute5          tax_code_sales_in  -- �ŃR�[�h�i����E���Łj
FROM   ic_item_mst_b             iimb4        -- OPM�i�ڃ}�X�^1
      ,xxcmn_item_categories5_v  xicv54       -- OPM�i�ڃJ�e�S���������VIEW5
      ,fnd_lookup_values         flv_cat4     -- �Q�ƃ^�C�v�F�i�ڃJ�e�S������ŕ���
WHERE  iimb4.item_id          = xicv54.item_id
AND    xicv54.item_class_code IN ('1' ,'2' ,'4')
AND    xicv54.item_class_code = flv_cat4.description
AND    flv_cat4.lookup_type   = 'XXCMN_ITEM_CATEGORY_TAX_KBN'
AND    flv_cat4.language      = USERENV('LANG')
AND    flv_cat4.enabled_flag  = 'Y'
-- OPM�i�ڂ̐H�i�敪�����݂��Ȃ�
AND    NOT EXISTS(SELECT 1
                  FROM   gmi_item_categories       gic4         -- OPM�i�ڃJ�e�S������
                        ,mtl_categories_b          mcb4         -- �i�ڃJ�e�S���}�X�^
                        ,mtl_categories_tl         mct4         -- �i�ڃJ�e�S���}�X�^���{��
                  WHERE  iimb4.item_id          = gic4.item_id
                  AND    gic4.category_set_id  = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_SYOKUHIN_CLASS')
                  AND    gic4.category_id      = mcb4.category_id
                  AND    mcb4.category_id      = mct4.category_id
                  AND    mct4.source_lang      = 'JA'
                  AND    mct4.language         = 'JA')
;
/
COMMENT ON TABLE xxcmm_item_tax_rate_v IS '����ŗ�VIEW';
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.item_id              IS '�i��ID'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.item_no              IS '�i��NO'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.tax                  IS '�ŗ�'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.start_date_active    IS '�K�p�J�n��'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.end_date_active      IS '�K�p�I����'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.tax_code_ex          IS '�ŃR�[�h�i�d���E�O�Łj'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.tax_code_in          IS '�ŃR�[�h�i�d���E���Łj'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.tax_code_sales_ex    IS '�ŃR�[�h�i����E�O�Łj'
/
COMMENT ON COLUMN apps.xxcmm_item_tax_rate_v.tax_code_sales_in    IS '�ŃR�[�h�i����E���Łj'
/
