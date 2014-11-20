CREATE OR REPLACE VIEW APPS.XXCMM_ITEM_SCREEN_V
AS
SELECT   iimb.item_no                      AS item_no                       -- �i���R�[�h
        ,iimb.item_id                      AS item_id                       -- �i��ID
        ,iimb.item_desc1                   AS item_desc1                    -- OPM�i�ړE�v
        ,iimb.item_um                      AS item_um                       -- ��P��
        ,TO_NUMBER(iimb.attribute5)        AS list_price                    -- �艿(�V)
        ,TO_DATE(iimb.attribute6, 'RRRR/MM/DD')
                                           AS list_price_start_date         -- �艿�K�p�J�n��
        ,TO_NUMBER(iimb.attribute8)        AS business_cost                 -- �c�ƌ���(�V)
        ,TO_DATE(iimb.attribute9, 'RRRR/MM/DD')
                                           AS business_cost_start_date      -- �c�ƌ����K�p�J�n��
        ,TO_NUMBER(iimb.attribute11)       AS case_number                   -- �P�[�X����
        ,TO_NUMBER(iimb.attribute12)       AS net                           -- NET
        ,TO_DATE(iimb.attribute13, 'RRRR/MM/DD')
                                           AS release_day                   -- �����J�n��
        ,TO_NUMBER(iimb.attribute26)       AS sales_target                  -- ����Ώ�
        ,iimb.attribute21                  AS jan_code                      -- JAN�R�[�h
        ,iimb.attribute22                  AS itf_code                      -- ITF�R�[�h
--      2009/03/12 �ǉ�
        ,iimb.attribute10                  AS weight_volume_class           -- �d�ʗe�ϋ敪
--    �d�ʗe�ϋ敪�̕ύX�ɔ����A�d��/�̐ς̐ݒ�l�𓮓I�ɒ��o  2009/03/12
--        ,TO_NUMBER(iimb.attribute25)       AS weight_volume                 -- �d�ʁ^�̐�
        ,( CASE iimb.attribute10
                WHEN '1' THEN TO_NUMBER( iimb.attribute25 )
                WHEN '2' THEN TO_NUMBER( iimb.attribute16 )
                ELSE NULL
          END )                            AS weight_volume                 -- �d�ʁ^�̐�
        ,iimb.dualum_ind                   AS dualum_ind                    -- ��d�Ǘ�
        ,iimb.lot_ctl                      AS lot_ctl                       -- ���b�g
        ,iimb.autolot_active_indicator     AS autolot_active_indicator      -- �������b�g�̔ԗL��
        ,iimb.lot_suffix                   AS lot_suffix                    -- ���b�g�E�T�t�B�b�N�X
        ,iimb.ATTRIBUTE1                   AS old_seisakugun                -- ���E�Q�R�[�h
        ,iimb.ATTRIBUTE2                   AS new_seisakugun                -- �V�E�Q�R�[�h
        ,iimb.ATTRIBUTE3                   AS seisakugun_start_date         -- �Q�R�[�h�K�p�J�n��
        ,iimb.created_by                   AS iimb_created_by               -- OPM�i��_�쐬�҂�USER_ID
        ,iimb.creation_date                AS iimb_creation_date            -- OPM�i��_�쐬����
        ,iimb.last_updated_by              AS iimb_last_updated_by          -- OPM�i��_�ŏI�X�V�҂�USER_ID
        ,iimb.last_update_date             AS iimb_last_update_date         -- OPM�i��_�ŏI�X�V����
        ,iimb.last_update_login            AS iimb_last_update_login        -- OPM�i��_�ŏI�X�V����LOGIN_ID
        ,iimb.request_id                   AS iimb_request_id               -- OPM�i��_�v��ID
        ,iimb.program_application_id       AS iimb_program_application_id   -- OPM�i��_�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
        ,iimb.program_id                   AS iimb_program_id               -- OPM�i��_�R���J�����g�E�v���O����ID
        ,iimb.program_update_date          AS iimb_program_update_date      -- OPM�i��_�v���O�����ɂ��X�V��
         --
        ,ximb.item_name                    AS item_name                     -- ������
        ,ximb.item_short_name              AS item_short_name               -- ����
        ,ximb.item_name_alt                AS item_name_alt                 -- �J�i��
        ,ximb.parent_item_id               AS parent_item_id                -- �e���iID
        ,TO_NUMBER(ximb.rate_class)        AS rate_class                    -- ���敪
        ,ximb.product_class                AS product_class                 -- ���i����
        ,ximb.palette_max_cs_qty           AS palette_max_cs_qty            -- �z��
        ,ximb.palette_max_step_qty         AS palette_max_step_qty          -- �i��
        ,ximb.obsolete_date                AS obsolete_date                 -- �p�~���i�������~���j
        ,ximb.obsolete_class               AS obsolete_class                -- �p�~�敪
        ,ximb.start_date_active            AS opm_item_start_date           -- �K�p�J�n��
        ,ximb.end_date_active              AS opm_item_end_date             -- �K�p�I����
        ,ximb.active_flag                  AS opm_item_active_flag          -- �K�p�σt���O
        ,ximb.created_by                   AS ximb_created_by               -- OPM�i�ڃA�h�I��_�쐬�҂�USER_ID
        ,ximb.creation_date                AS ximb_creation_date            -- OPM�i�ڃA�h�I��_�쐬����
        ,ximb.last_updated_by              AS ximb_last_updated_by          -- OPM�i�ڃA�h�I��_�ŏI�X�V�҂�USER_ID
        ,ximb.last_update_date             AS ximb_last_update_date         -- OPM�i�ڃA�h�I��_�ŏI�X�V����
        ,ximb.last_update_login            AS ximb_last_update_login        -- OPM�i�ڃA�h�I��_�ŏI�X�V����LOGIN_ID
        ,ximb.request_id                   AS ximb_request_id               -- OPM�i�ڃA�h�I��_�v��ID
        ,ximb.program_application_id       AS ximb_program_application_id   -- OPM�i�ڃA�h�I��_�R���J�����g�E�v���O�����̃A�v���P�[�V����ID
        ,ximb.program_id                   AS ximb_program_id               -- OPM�i�ڃA�h�I��_�R���J�����g�E�v���O����ID
        ,ximb.program_update_date          AS ximb_program_update_date      -- OPM�i�ڃA�h�I��_�v���O�����ɂ��X�V��
         --
        ,xsib.item_status_apply_date       AS item_status_apply_date        -- �i�ڃX�e�[�^�X�K�p��
        ,xsib.item_status                  AS item_status                   -- �i�ڃX�e�[�^�X
        ,CASE WHEN xsib.item_status IS NULL THEN NULL
              ELSE xsib.item_status || ':' || his.item_status_name
              END                          AS item_status_name              -- �i�ڃX�e�[�^�X��
        ,xsib.nets                         AS nets                          -- ���e��
        ,xsib.nets_uom_code                AS nets_uom_code                 -- ���e�ʒP��
        ,xsib.inc_num                      AS inc_num                       -- �������
        ,xsib.baracha_div                  AS baracha_div                   -- �o�����敪
        ,xsib.case_jan_code                AS case_jan_code                 -- �P�[�XJAN�R�[�h
        ,xsib.bowl_inc_num                 AS bowl_inc_num                  -- �{�[������
        ,xsib.vessel_group                 AS vessel_group                  -- �e��Q
        ,xsib.new_item_div                 AS new_item_div                  -- �V���i�敪
        ,xsib.acnt_group                   AS acnt_group                    -- �o���Q
        ,xsib.acnt_vessel_group            AS acnt_vessel_group             -- �o���e��Q
        ,xsib.brand_group                  AS brand_group                   -- �u�����h�Q
        ,xsib.renewal_item_code            AS renewal_item_code             -- ���j���[�A�������i�R�[�h
        ,xsib.sp_supplier_code             AS sp_supplier_code              -- ���X�d����
        ,xsib.search_update_date           AS search_update_date            -- �����ΏۍX�V��
        ,xsib.created_by                   AS created_by                    -- �쐬�҂�USER_ID
        ,xsib.creation_date                AS creation_date                 -- �쐬����
        ,xsib.last_updated_by              AS last_updated_by               -- �ŏI�X�V�҂�USER_ID
        ,xsib.last_update_date             AS last_update_date              -- �ŏI�X�V����
        ,xsib.last_update_login            AS last_update_login             -- �ŏI�X�V����LOGIN_ID
        ,xsib.request_id                   AS request_id                    -- �v��ID
        ,xsib.program_application_id       AS program_application_id        -- �R���J�����g�E�v���O�����̃A�v���P�[�V����ID
        ,xsib.program_id                   AS program_id                    -- �R���J�����g�E�v���O����ID
        ,xsib.program_update_date          AS program_update_date           -- �v���O�����ɂ��X�V��
         --
        ,disc.inventory_item_id            AS inventory_item_id             -- Disc�i��ID
        ,disc.description                  AS disc_description              -- Disc�E�v
        ,disc.primary_unit_of_measure      AS disc_primary_unit_of_measure  -- Disc��P��
        ,disc.m_organization_id            AS m_organization_id             -- �}�X�^�[�g�DID
         --
        ,TRUNC(t.standard_cost, 2)         AS standard_cost                 -- �W������
        ,t.start_date                      AS standard_cost_start_date      -- �W�������K�p��
         --
        ,ximbp.item_name                   AS parent_item_name              -- �e���i��
        ,iimbp.item_no                     AS parent_item_no                -- �e���i�R�[�h
        ,ximbr.item_name                   AS renewal_item_name             -- ���j���[�A�������i��
         --
        ,TO_NUMBER(ipc.item_product_class) AS item_product_class            -- ���i���i�敪
        ,ipc.item_product_class_name       AS item_product_class_name       -- ���i���i�敪��
        ,ipc.item_product_category_id      AS item_product_category_id      -- ���i���i�敪�J�e�S��ID
        ,ipc.item_product_category_set_id  AS item_product_category_set_id  -- ���i���i�敪�J�e�S���Z�b�gID
        ,TO_NUMBER(ho.hon_product_class)   AS hon_product_class             -- �{�Џ��i�敪
        ,ho.hon_product_class_name         AS hon_product_class_name        -- �{�Џ��i�敪��
        ,ho.hon_product_category_id        AS hon_product_category_id       -- �{�Џ��i�敪�J�e�S��ID
        ,ho.hon_product_category_set_id    AS hon_product_category_set_id   -- �{�Џ��i�敪�J�e�S���Z�b�gID
        ,se.seisakugun                     AS seisakugun                    -- ����Q
        ,se.seisakugun_category_id         AS seisakugun_category_id        -- ����Q�J�e�S��ID
        ,se.seisakugun_category_set_id     AS seisakugun_category_set_id    -- ����Q�J�e�S���Z�b�gID
         --
        ,uri.sales_target_name             AS sales_target_name             -- ����Ώۖ�
        ,rat.rate_class_name               AS rate_class_name               -- ���敪��
        ,nets.nets_uom_code_name           AS nets_uom_code_name            -- ���e�ʒP�ʖ�
        ,bar.baracha_div_name              AS baracha_div_name              -- �o�����敪��
        ,obs.obsolete_class_name           AS obsolete_class_name           -- �p�~�敪��
        ,nic.new_item_div_name             AS new_item_div_name             -- �V���i�敪��
        ,sen.sp_supplier_code_name         AS sp_supplier_code_name         -- ���X�d���於
         --
-- 2009/05/12 ��QT1_0906 add start by Yutaka.Kuboshima
        ,xsib.case_conv_inc_num            AS case_conv_inc_num             -- �P�[�X���Z����
-- 2009/05/12 ��QT1_0906 add end by Yutaka.Kuboshima
-- 2009/06/15 ��QT1_1366 add start by Yutaka.Kuboshima
        ,ma.mark_group_code                AS mark_group_code               -- �}�[�P�p�Q�R�[�h
        ,ma.mark_group_category_id         AS mark_group_category_id        -- �}�[�P�p�Q�R�[�h�J�e�S��ID
        ,ma.mark_group_category_set_id     AS mark_group_category_set_id    -- �}�[�P�p�Q�R�[�h�J�e�S���Z�b�gI
        ,gu.group_code                     AS group_code                    -- �Q�R�[�h
        ,gu.group_category_id              AS group_category_id             -- �Q�R�[�h�J�e�S��ID
        ,gu.group_category_set_id          AS group_category_set_id         -- �Q�R�[�h�J�e�S���Z�b�gID
        ,ba.baracha_div                    AS baracha_div_category          -- �o�����敪�J�e�S��
        ,baracha_div_category_id           AS baracha_div_category_id       -- �o�����敪�J�e�S��ID
        ,baracha_div_category_set_id       AS baracha_div_category_set_id   -- �o�����敪�J�e�S���Z�b�gID
-- 2009/06/15 ��QT1_1366 add end by Yutaka.Kuboshima
-- 2012/08/29 E_�{�ғ�_09591 add start by T.Makuta
        ,iimb.attribute19                  AS freshness_condition           -- �N�x����
-- 2012/08/29 E_�{�ғ�_09591 add end by T.Makuta
FROM     ic_item_mst_b      iimb        -- OPM�i�ڃ}�X�^
        ,xxcmn_item_mst_b   ximb        -- OPM�i�ڃA�h�I���}�X�^
        ,xxcmm_system_items_b xsib      -- Disc�i�ڃA�h�I���}�X�^
        ,(SELECT      msib.inventory_item_id       AS inventory_item_id
                     ,msib.organization_id         AS m_organization_id
                     ,msib.segment1                AS item_code
                     ,msib.description             AS description
                     ,msib.primary_unit_of_measure AS primary_unit_of_measure
          FROM        mtl_system_items_b msib
-- ��2009/03/19 Add Start
                     ,mtl_parameters               mp       -- �g�D�p�����[�^
-- ��2009/03/19 Add End
                     ,financials_system_parameters fsp
-- ��2009/03/19 Add Start
--          WHERE       msib.organization_id = fsp.inventory_organization_id
          WHERE       mp.organization_id   = fsp.inventory_organization_id
          AND         msib.organization_id = mp.master_organization_id
-- ��2009/03/19 Add End
        ) disc                          -- Disc�i�ڃ}�X�^
        ,(SELECT      SUM(ccd.cmpnt_cost)          AS standard_cost
                     ,ccd.item_id                  AS item_id
                     ,ccd.calendar_code            AS calendar_code
                     ,ccd.period_code              AS period_code
                     ,ccc.start_date               AS start_date
          FROM        cm_cmpt_dtl ccd                -- OPM����
                     ,cm_cldr_dtl ccc                -- OPM�����J�����_
          WHERE       ccd.calendar_code  = ccc.calendar_code
          AND         ccd.period_code    = ccc.period_code
-- 2009/08/20 modify start by Yutaka.Kuboshima
--          AND         ccc.start_date    <= xxccp_common_pkg2.get_working_day(SYSDATE, 0, NULL)
--          AND         ccc.end_date      >= xxccp_common_pkg2.get_working_day(SYSDATE, 0, NULL)
          AND         ccc.start_date    <= xxccp_common_pkg2.get_process_date
          AND         ccc.end_date      >= xxccp_common_pkg2.get_process_date
-- 2009/08/20 modify end by Yutaka.Kuboshima
          GROUP BY    ccd.item_id
                     ,ccd.calendar_code
                     ,ccd.period_code
                     ,ccc.start_date
        ) t                             -- OPM����
        ,ic_item_mst_b      iimbp       -- OPM�i�ڃ}�X�^(�e�i�ڏ��)
        ,xxcmn_item_mst_b   ximbp       -- OPM�i�ڃA�h�I���}�X�^(�e�i�ڏ��)
        ,ic_item_mst_b iimbr            -- OPM�i�ڃ}�X�^(���j���[�A�������i����񌋍�)
        ,xxcmn_item_mst_b   ximbr       -- OPM�i�ڃA�h�I���}�X�^(���j���[�A�������i�����)
        ,(SELECT      gic_ipc.item_id          AS item_id
                     ,mcv_ipc.segment1         AS item_product_class
                     ,mcv_ipc.description      AS item_product_class_name
                     ,mcv_ipc.category_id      AS item_product_category_id
                     ,mcsv_ipc.category_set_id AS item_product_category_set_id
          FROM        gmi_item_categories  gic_ipc
                     ,mtl_category_sets_vl mcsv_ipc
                     ,mtl_categories_vl    mcv_ipc
          WHERE       gic_ipc.category_set_id    = mcsv_ipc.category_set_id
          AND         mcsv_ipc.category_set_name = '���i���i�敪'
          AND         gic_ipc.category_id        = mcv_ipc.category_id
          AND         gic_ipc.category_id        = mcv_ipc.category_id
        ) ipc                           -- ���i���i�敪�p
        ,(SELECT      gic_ho.item_id          AS item_id
                     ,mcv_ho.segment1         AS hon_product_class
                     ,mcv_ho.description      AS hon_product_class_name
                     ,mcv_ho.category_id      AS hon_product_category_id
                     ,mcsv_ho.category_set_id AS hon_product_category_set_id
          FROM        gmi_item_categories  gic_ho
                     ,mtl_category_sets_vl mcsv_ho
                     ,mtl_categories_vl    mcv_ho
          WHERE       gic_ho.category_set_id    = mcsv_ho.category_set_id
          AND         mcsv_ho.category_set_name = '�{�Џ��i�敪'
          AND         gic_ho.category_id        = mcv_ho.category_id
          AND         gic_ho.category_id        = mcv_ho.category_id
        ) ho                            -- �{�Џ��i�敪�p
        ,(SELECT      gic_se.item_id          AS item_id
                     ,mcv_se.segment1         AS seisakugun
                     ,mcv_se.description      AS seisakugun_name
                     ,mcv_se.category_id      AS seisakugun_category_id
                     ,mcsv_se.category_set_id AS seisakugun_category_set_id
          FROM        gmi_item_categories  gic_se
                     ,mtl_category_sets_vl mcsv_se
                     ,mtl_categories_vl    mcv_se
          WHERE       gic_se.category_set_id    = mcsv_se.category_set_id
          AND         mcsv_se.category_set_name = '����Q�R�[�h'
          AND         gic_se.category_id        = mcv_se.category_id
          AND         gic_se.category_id        = mcv_se.category_id
        ) se                            -- ����Q�p
-- 2009/06/15 ��QT1_1366 add start by Yutaka.Kuboshima
        ,(SELECT      gic_se.item_id          AS item_id
                     ,mcv_se.segment1         AS mark_group_code
                     ,mcv_se.description      AS mark_group_code_name
                     ,mcv_se.category_id      AS mark_group_category_id
                     ,mcsv_se.category_set_id AS mark_group_category_set_id
          FROM        gmi_item_categories  gic_se
                     ,mtl_category_sets_vl mcsv_se
                     ,mtl_categories_vl    mcv_se
          WHERE       gic_se.category_set_id    = mcsv_se.category_set_id
          AND         mcsv_se.category_set_name = '�}�[�P�p�Q�R�[�h'
          AND         gic_se.category_id        = mcv_se.category_id
          AND         gic_se.category_id        = mcv_se.category_id
        ) ma                            -- �}�[�P�p�Q�R�[�h�p
        ,(SELECT      gic_se.item_id          AS item_id
                     ,mcv_se.segment1         AS group_code
                     ,mcv_se.description      AS group_code_name
                     ,mcv_se.category_id      AS group_category_id
                     ,mcsv_se.category_set_id AS group_category_set_id
          FROM        gmi_item_categories  gic_se
                     ,mtl_category_sets_vl mcsv_se
                     ,mtl_categories_vl    mcv_se
          WHERE       gic_se.category_set_id    = mcsv_se.category_set_id
          AND         mcsv_se.category_set_name = '�Q�R�[�h'
          AND         gic_se.category_id        = mcv_se.category_id
          AND         gic_se.category_id        = mcv_se.category_id
        ) gu                            -- �Q�R�[�h�p
        ,(SELECT      gic_se.item_id          AS item_id
                     ,mcv_se.segment1         AS baracha_div
                     ,mcv_se.description      AS baracha_div_name
                     ,mcv_se.category_id      AS baracha_div_category_id
                     ,mcsv_se.category_set_id AS baracha_div_category_set_id
          FROM        gmi_item_categories  gic_se
                     ,mtl_category_sets_vl mcsv_se
                     ,mtl_categories_vl    mcv_se
          WHERE       gic_se.category_set_id    = mcsv_se.category_set_id
          AND         mcsv_se.category_set_name = '�o�����敪'
          AND         gic_se.category_id        = mcv_se.category_id
          AND         gic_se.category_id        = mcv_se.category_id
        ) ba                            -- �o�����敪�p
-- 2009/06/15 ��QT1_1366 add end by Yutaka.Kuboshima
        ,(SELECT      flv_uri.lookup_code  AS sales_target
                     ,flv_uri.meaning      AS sales_target_name
          FROM        fnd_lookup_values_vl flv_uri
          WHERE       flv_uri.lookup_type  = 'XXCMN_SALES_TARGET_CLASS'
        ) uri    -- ����Ώۋ敪�p
        ,(SELECT      flv_his.lookup_code  AS item_status
                     ,flv_his.meaning      AS item_status_name
          FROM        fnd_lookup_values_vl flv_his
          WHERE       flv_his.lookup_type  = 'XXCMM_ITM_STATUS'
        ) his    -- �i�ڃX�e�[�^�X�p
        ,(SELECT      flv_rat.lookup_code  AS rate_class
                     ,flv_rat.meaning      AS rate_class_name
          FROM        fnd_lookup_values_vl flv_rat
          WHERE       flv_rat.lookup_type  = 'XXCMM_ITM_RATE_CLASS'
        ) rat    -- ���敪�p
        ,(SELECT      flv_nets.lookup_code  AS nets_uom_code
                     ,flv_nets.meaning      AS nets_uom_code_name
          FROM        fnd_lookup_values_vl flv_nets
          WHERE       flv_nets.lookup_type = 'XXCMM_ITM_NET_UOM_CODE'
        ) nets   -- ���e�ʒP�ʗp
        ,(SELECT      flv_bar.lookup_code  AS baracha_div
                     ,flv_bar.meaning      AS baracha_div_name
          FROM        fnd_lookup_values_vl flv_bar
          WHERE       flv_bar.lookup_type  = 'XXCMM_ITM_BARACHAKUBUN'
        ) bar    -- �o�����敪�p
        ,(SELECT      flv_obs.lookup_code  AS obsolete_class
                     ,flv_obs.meaning      AS obsolete_class_name
          FROM        fnd_lookup_values_vl flv_obs
          WHERE       flv_obs.lookup_type  = 'XXCMM_ITM_HAISHI_KUBUN'
        ) obs    -- �p�~�敪�p
        ,(SELECT      flv_nic.lookup_code  AS new_item_div
                     ,flv_nic.meaning      AS new_item_div_name
          FROM        fnd_lookup_values_vl flv_nic
          WHERE       flv_nic.lookup_type  = 'XXCMM_ITM_SHINSYOHINKUBUN'
        ) nic    -- �V���i�敪�p
        ,(SELECT      flv_sen.lookup_code  AS sp_supplier_code
                     ,flv_sen.description  AS sp_supplier_code_name
          FROM        fnd_lookup_values_vl flv_sen
          WHERE       flv_sen.lookup_type  = 'XXCMM_ITM_SENMONTEN_SHIIRESAKI'
        ) sen    -- ���X�d����p
WHERE   iimb.item_id                 = ximb.item_id
-- 2009/08/20 modify start by Yutaka.Kuboshima
--AND     ximb.start_date_active(+)   <= TRUNC(SYSDATE)
--AND     ximb.end_date_active(+)     >= TRUNC(SYSDATE)
AND     ximb.start_date_active(+)   <= xxccp_common_pkg2.get_process_date
AND     ximb.end_date_active(+)     >= xxccp_common_pkg2.get_process_date
-- 2009/08/20 modify end by Yutaka.Kuboshima
AND     iimb.item_no                 = disc.item_code(+)            -- �O������
-- 2009/05/12 ��QT1_0317 modify start by Yutaka.Kuboshima
--AND     iimb.item_no                 = xsib.item_code(+)
AND     iimb.item_no                 = xsib.item_code
-- 2009/05/12 ��QT1_0317 modify end by Yutaka.Kuboshima
AND     iimb.item_id                 = t.item_id(+)
AND     ximb.parent_item_id          = ximbp.item_id(+)          -- xxcmn_item_mst_b(�q)  xxcmn_item_mst_b(�e)
-- 2009/08/20 modify start by Yutaka.Kuboshima
--AND     ximbp.start_date_active(+)  <= TRUNC(SYSDATE)
--AND     ximbp.end_date_active(+)    >= TRUNC(SYSDATE)
AND     ximbp.start_date_active(+)  <= xxccp_common_pkg2.get_process_date
AND     ximbp.end_date_active(+)    >= xxccp_common_pkg2.get_process_date
-- 2009/08/20 modify end by Yutaka.Kuboshima
AND     ximb.parent_item_id          = iimbp.item_id(+)
AND     xsib.renewal_item_code       = iimbr.item_no(+)
AND     iimbr.item_id                = ximbr.item_id(+)
-- 2009/08/20 modify start by Yutaka.Kuboshima
--AND     ximbr.start_date_active(+)  <= TRUNC(SYSDATE)
--AND     ximbr.end_date_active(+)    >= TRUNC(SYSDATE)
AND     ximbr.start_date_active(+)  <= xxccp_common_pkg2.get_process_date
AND     ximbr.end_date_active(+)    >= xxccp_common_pkg2.get_process_date
-- 2009/08/20 modify end by Yutaka.Kuboshima
AND     iimb.item_id                 = ipc.item_id
AND     iimb.item_id                 = ho.item_id(+)
AND     iimb.item_id                 = se.item_id(+)
-- 2009/06/15 ��QT1_1366 add start by Yutaka.Kuboshima
AND     iimb.item_id                 = ma.item_id(+)
AND     iimb.item_id                 = gu.item_id(+)
AND     iimb.item_id                 = ba.item_id(+)
-- 2009/06/15 ��QT1_1366 add end by Yutaka.Kuboshima
-- Lookup�n
AND     iimb.attribute26             = uri.sales_target(+)
AND     TO_CHAR(xsib.item_status)    = his.item_status(+)
AND     ximb.rate_class              = rat.rate_class(+)
AND     TO_CHAR(xsib.baracha_div)    = bar.baracha_div(+)
AND     xsib.nets_uom_code           = nets.nets_uom_code(+)
AND     ximb.obsolete_class          = obs.obsolete_class(+)
AND     xsib.new_item_div            = nic.new_item_div(+)
AND     xsib.sp_supplier_code        = sen.sp_supplier_code(+)
-- 2009/05/12 ��QT1_0317 delete start by Yutaka.Kuboshima
--AND     LENGTHB(iimb.item_no) = 7
--AND     iimb.item_no BETWEEN '0000001' AND '3999999'
-- 2009/05/12 ��QT1_0317 delete end by Yutaka.Kuboshima
/
COMMENT ON TABLE APPS.XXCMM_ITEM_SCREEN_V IS '�i�ړo�^��ʃr���['
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_NO IS '�i���R�[�h'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_ID IS '�i��ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_DESC1 IS 'OPM�i�ړE�v'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_UM IS '��P��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LIST_PRICE IS '�艿'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LIST_PRICE_START_DATE IS '�艿�K�p��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BUSINESS_COST IS '�c�ƌ���'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BUSINESS_COST_START_DATE IS '�c�ƌ����K�p��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.CASE_NUMBER IS '�P�[�X����'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NET IS 'NET'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.RELEASE_DAY IS '�����J�n��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SALES_TARGET IS '����Ώ�'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.JAN_CODE IS 'JAN�R�[�h'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITF_CODE IS 'ITF�R�[�h'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.WEIGHT_VOLUME_CLASS IS '�d�ʗe�ϋ敪'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.WEIGHT_VOLUME IS '�d�ʁ^�̐�'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.DUALUM_IND IS '��d�Ǘ�'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LOT_CTL IS '���b�g'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.AUTOLOT_ACTIVE_INDICATOR IS '�������b�g�̔ԗL��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LOT_SUFFIX IS '���b�g�E�T�t�B�b�N�X'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OLD_SEISAKUGUN IS '���E�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NEW_SEISAKUGUN IS '�V�E�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SEISAKUGUN_START_DATE IS '�Q�R�[�h�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_CREATED_BY IS 'OPM�i��_�쐬�҂�USER_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_CREATION_DATE IS 'OPM�i��_�쐬����'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_LAST_UPDATED_BY IS 'OPM�i��_�ŏI�X�V�҂�USER_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_LAST_UPDATE_DATE IS 'OPM�i��_�ŏI�X�V����'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_LAST_UPDATE_LOGIN IS 'OPM�i��_�ŏI�X�V����LOGIN_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_REQUEST_ID IS 'OPM�i��_�v��ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_PROGRAM_APPLICATION_ID IS 'OPM�i��_�R���J�����g�E�v���O�����̃A�v���P�[�V����ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_PROGRAM_ID IS 'OPM�i��_�R���J�����g�E�v���O����ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_PROGRAM_UPDATE_DATE IS 'OPM�i��_�v���O�����ɂ��X�V��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_NAME IS '������'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_SHORT_NAME IS '����'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_NAME_ALT IS '�J�i��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PARENT_ITEM_ID IS '�e���iID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.RATE_CLASS IS '���敪'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PRODUCT_CLASS IS '���i����'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PALETTE_MAX_CS_QTY IS '�z��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PALETTE_MAX_STEP_QTY IS '�i��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OBSOLETE_DATE IS '�p�~��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OBSOLETE_CLASS IS '�p�~�敪'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OPM_ITEM_START_DATE IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OPM_ITEM_END_DATE IS '�K�p�I����'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OPM_ITEM_ACTIVE_FLAG IS '�K�p�σt���O'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_CREATED_BY IS 'OPM�i�ڃA�h�I��_�쐬�҂�USER_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_CREATION_DATE IS 'OPM�i�ڃA�h�I��_�쐬����'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_LAST_UPDATED_BY IS 'OPM�i�ڃA�h�I��_�ŏI�X�V�҂�USER_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_LAST_UPDATE_DATE IS 'OPM�i�ڃA�h�I��_�ŏI�X�V����'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_LAST_UPDATE_LOGIN IS 'OPM�i�ڃA�h�I��_�ŏI�X�V����LOGIN_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_REQUEST_ID IS 'OPM�i�ڃA�h�I��_�v��ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_PROGRAM_APPLICATION_ID IS 'OPM�i�ڃA�h�I��_�R���J�����g�E�v���O�����̃A�v���P�[�V����ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_PROGRAM_ID IS 'OPM�i�ڃA�h�I��_�R���J�����g�E�v���O����ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_PROGRAM_UPDATE_DATE IS 'OPM�i�ڃA�h�I��_�v���O�����ɂ��X�V��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_STATUS_APPLY_DATE IS '�i�ڃX�e�[�^�X�K�p��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_STATUS IS '�i�ڃX�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_STATUS_NAME IS '�i�ڃX�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NETS IS '���e��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NETS_UOM_CODE IS '���e�ʒP��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.INC_NUM IS '�������'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BARACHA_DIV IS '�o�����敪'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.CASE_JAN_CODE IS '�P�[�XJAN�R�[�h'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BOWL_INC_NUM IS '�{�[������'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.VESSEL_GROUP IS '�e��Q'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NEW_ITEM_DIV IS '�V���i�敪'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ACNT_GROUP IS '�o���Q'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ACNT_VESSEL_GROUP IS '�o���e��Q'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BRAND_GROUP IS '�u�����h�Q'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.RENEWAL_ITEM_CODE IS '���j���[�A�������i�R�[�h'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SP_SUPPLIER_CODE IS '���X�d����'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SEARCH_UPDATE_DATE IS '�����ΏۍX�V��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.CREATED_BY IS '�쐬�҂�USER_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.CREATION_DATE IS '�쐬����'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LAST_UPDATED_BY IS '�ŏI�X�V�҂�USER_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LAST_UPDATE_DATE IS '�ŏI�X�V����'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LAST_UPDATE_LOGIN IS '�ŏI�X�V����LOGIN_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.REQUEST_ID IS '�v��ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PROGRAM_APPLICATION_ID IS '�R���J�����g�E�v���O�����̃A�v���P�[�V����ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PROGRAM_ID IS '�R���J�����g�E�v���O����ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PROGRAM_UPDATE_DATE IS '�v���O�����ɂ��X�V��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.INVENTORY_ITEM_ID IS 'Disc�i��ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.DISC_DESCRIPTION IS 'Disc�E�v'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.DISC_PRIMARY_UNIT_OF_MEASURE IS 'Disc��P��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.M_ORGANIZATION_ID IS '�}�X�^�[�g�DID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.STANDARD_COST IS '�W������'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.STANDARD_COST_START_DATE IS '�W�������K�p��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PARENT_ITEM_NAME IS '�e���i��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PARENT_ITEM_NO IS '�e���i�R�[�h'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.RENEWAL_ITEM_NAME IS '���j���[�A�������i��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_PRODUCT_CLASS IS '���i���i�敪'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_PRODUCT_CLASS_NAME IS '���i���i�敪��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_PRODUCT_CATEGORY_ID IS '���i���i�敪�J�e�S��ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_PRODUCT_CATEGORY_SET_ID IS '���i���i�敪�J�e�S���Z�b�gID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.HON_PRODUCT_CLASS IS '�{�Џ��i�敪'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.HON_PRODUCT_CLASS_NAME IS '�{�Џ��i�敪��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.HON_PRODUCT_CATEGORY_ID IS '�{�Џ��i�敪�J�e�S��ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.HON_PRODUCT_CATEGORY_SET_ID IS '�{�Џ��i�敪�J�e�S���Z�b�gID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SEISAKUGUN IS '����Q'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SEISAKUGUN_CATEGORY_ID IS '����Q�J�e�S��ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SEISAKUGUN_CATEGORY_SET_ID IS '����Q�J�e�S���Z�b�gID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SALES_TARGET_NAME IS '����Ώۖ�'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.RATE_CLASS_NAME IS '���敪��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NETS_UOM_CODE_NAME IS '���e�ʒP�ʖ�'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BARACHA_DIV_NAME IS '�o�����敪��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OBSOLETE_CLASS_NAME IS '�p�~�敪��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NEW_ITEM_DIV_NAME IS '�V���i�敪��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SP_SUPPLIER_CODE_NAME IS '���X�d���於'
/
-- 2009/05/12 ��QT1_0906 add start by Yutaka.Kuboshima
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.CASE_CONV_INC_NUM IS '�P�[�X���Z����'
/
-- 2009/06/15 ��QT1_1366 add start by Yutaka.Kuboshima
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.MARK_GROUP_CODE IS '�}�[�P�p�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.MARK_GROUP_CATEGORY_ID IS '�}�[�P�p�Q�R�[�h�J�e�S��ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.mark_group_category_set_id IS '�}�[�P�p�Q�R�[�h�J�e�S���Z�b�gID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.GROUP_CODE IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.GROUP_CATEGORY_ID IS '�Q�R�[�h�J�e�S��ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.GROUP_CATEGORY_SET_ID IS '�Q�R�[�h�J�e�S���Z�b�gID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BARACHA_DIV_CATEGORY IS '�o�����敪�J�e�S��'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BARACHA_DIV_CATEGORY_ID IS '�o�����敪�J�e�S��ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BARACHA_DIV_CATEGORY_SET_ID IS '�o�����敪�J�e�S���Z�b�gID'
/
-- 2012/08/29 E_�{�ғ�_09591 add start by T.Makuta
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.FRESHNESS_CONDITION IS '�N�x����'
-- 2012/08/29 E_�{�ғ�_09591 add end by T.Makuta
/
