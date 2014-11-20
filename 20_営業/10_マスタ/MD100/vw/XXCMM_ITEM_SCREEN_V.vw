CREATE OR REPLACE VIEW APPS.XXCMM_ITEM_SCREEN_V
AS
SELECT   iimb.item_no                      AS item_no                       -- 品名コード
        ,iimb.item_id                      AS item_id                       -- 品名ID
        ,iimb.item_desc1                   AS item_desc1                    -- OPM品目摘要
        ,iimb.item_um                      AS item_um                       -- 基準単位
        ,TO_NUMBER(iimb.attribute5)        AS list_price                    -- 定価(新)
        ,TO_DATE(iimb.attribute6, 'RRRR/MM/DD')
                                           AS list_price_start_date         -- 定価適用開始日
        ,TO_NUMBER(iimb.attribute8)        AS business_cost                 -- 営業原価(新)
        ,TO_DATE(iimb.attribute9, 'RRRR/MM/DD')
                                           AS business_cost_start_date      -- 営業原価適用開始日
        ,TO_NUMBER(iimb.attribute11)       AS case_number                   -- ケース入数
        ,TO_NUMBER(iimb.attribute12)       AS net                           -- NET
        ,TO_DATE(iimb.attribute13, 'RRRR/MM/DD')
                                           AS release_day                   -- 発売開始日
        ,TO_NUMBER(iimb.attribute26)       AS sales_target                  -- 売上対象
        ,iimb.attribute21                  AS jan_code                      -- JANコード
        ,iimb.attribute22                  AS itf_code                      -- ITFコード
--      2009/03/12 追加
        ,iimb.attribute10                  AS weight_volume_class           -- 重量容積区分
--    重量容積区分の変更に伴い、重量/体積の設定値を動的に抽出  2009/03/12
--        ,TO_NUMBER(iimb.attribute25)       AS weight_volume                 -- 重量／体積
        ,( CASE iimb.attribute10
                WHEN '1' THEN TO_NUMBER( iimb.attribute25 )
                WHEN '2' THEN TO_NUMBER( iimb.attribute16 )
                ELSE NULL
          END )                            AS weight_volume                 -- 重量／体積
        ,iimb.dualum_ind                   AS dualum_ind                    -- 二重管理
        ,iimb.lot_ctl                      AS lot_ctl                       -- ロット
        ,iimb.autolot_active_indicator     AS autolot_active_indicator      -- 自動ロット採番有効
        ,iimb.lot_suffix                   AS lot_suffix                    -- ロット・サフィックス
        ,iimb.ATTRIBUTE1                   AS old_seisakugun                -- 旧・群コード
        ,iimb.ATTRIBUTE2                   AS new_seisakugun                -- 新・群コード
        ,iimb.ATTRIBUTE3                   AS seisakugun_start_date         -- 群コード適用開始日
        ,iimb.created_by                   AS iimb_created_by               -- OPM品目_作成者のUSER_ID
        ,iimb.creation_date                AS iimb_creation_date            -- OPM品目_作成日時
        ,iimb.last_updated_by              AS iimb_last_updated_by          -- OPM品目_最終更新者のUSER_ID
        ,iimb.last_update_date             AS iimb_last_update_date         -- OPM品目_最終更新日時
        ,iimb.last_update_login            AS iimb_last_update_login        -- OPM品目_最終更新時のLOGIN_ID
        ,iimb.request_id                   AS iimb_request_id               -- OPM品目_要求ID
        ,iimb.program_application_id       AS iimb_program_application_id   -- OPM品目_コンカレント・プログラムのアプリケーションID
        ,iimb.program_id                   AS iimb_program_id               -- OPM品目_コンカレント・プログラムID
        ,iimb.program_update_date          AS iimb_program_update_date      -- OPM品目_プログラムによる更新日
         --
        ,ximb.item_name                    AS item_name                     -- 正式名
        ,ximb.item_short_name              AS item_short_name               -- 略称
        ,ximb.item_name_alt                AS item_name_alt                 -- カナ名
        ,ximb.parent_item_id               AS parent_item_id                -- 親商品ID
        ,TO_NUMBER(ximb.rate_class)        AS rate_class                    -- 率区分
        ,ximb.product_class                AS product_class                 -- 商品分類
        ,ximb.palette_max_cs_qty           AS palette_max_cs_qty            -- 配数
        ,ximb.palette_max_step_qty         AS palette_max_step_qty          -- 段数
        ,ximb.obsolete_date                AS obsolete_date                 -- 廃止日（製造中止日）
        ,ximb.obsolete_class               AS obsolete_class                -- 廃止区分
        ,ximb.start_date_active            AS opm_item_start_date           -- 適用開始日
        ,ximb.end_date_active              AS opm_item_end_date             -- 適用終了日
        ,ximb.active_flag                  AS opm_item_active_flag          -- 適用済フラグ
        ,ximb.created_by                   AS ximb_created_by               -- OPM品目アドオン_作成者のUSER_ID
        ,ximb.creation_date                AS ximb_creation_date            -- OPM品目アドオン_作成日時
        ,ximb.last_updated_by              AS ximb_last_updated_by          -- OPM品目アドオン_最終更新者のUSER_ID
        ,ximb.last_update_date             AS ximb_last_update_date         -- OPM品目アドオン_最終更新日時
        ,ximb.last_update_login            AS ximb_last_update_login        -- OPM品目アドオン_最終更新時のLOGIN_ID
        ,ximb.request_id                   AS ximb_request_id               -- OPM品目アドオン_要求ID
        ,ximb.program_application_id       AS ximb_program_application_id   -- OPM品目アドオン_コンカレント・プログラムのアプリケーションID
        ,ximb.program_id                   AS ximb_program_id               -- OPM品目アドオン_コンカレント・プログラムID
        ,ximb.program_update_date          AS ximb_program_update_date      -- OPM品目アドオン_プログラムによる更新日
         --
        ,xsib.item_status_apply_date       AS item_status_apply_date        -- 品目ステータス適用日
        ,xsib.item_status                  AS item_status                   -- 品目ステータス
        ,CASE WHEN xsib.item_status IS NULL THEN NULL
              ELSE xsib.item_status || ':' || his.item_status_name
              END                          AS item_status_name              -- 品目ステータス名
        ,xsib.nets                         AS nets                          -- 内容量
        ,xsib.nets_uom_code                AS nets_uom_code                 -- 内容量単位
        ,xsib.inc_num                      AS inc_num                       -- 内訳入数
        ,xsib.baracha_div                  AS baracha_div                   -- バラ茶区分
        ,xsib.case_jan_code                AS case_jan_code                 -- ケースJANコード
        ,xsib.bowl_inc_num                 AS bowl_inc_num                  -- ボール入数
        ,xsib.vessel_group                 AS vessel_group                  -- 容器群
        ,xsib.new_item_div                 AS new_item_div                  -- 新商品区分
        ,xsib.acnt_group                   AS acnt_group                    -- 経理群
        ,xsib.acnt_vessel_group            AS acnt_vessel_group             -- 経理容器群
        ,xsib.brand_group                  AS brand_group                   -- ブランド群
        ,xsib.renewal_item_code            AS renewal_item_code             -- リニューアル元商品コード
        ,xsib.sp_supplier_code             AS sp_supplier_code              -- 専門店仕入先
        ,xsib.search_update_date           AS search_update_date            -- 検索対象更新日
        ,xsib.created_by                   AS created_by                    -- 作成者のUSER_ID
        ,xsib.creation_date                AS creation_date                 -- 作成日時
        ,xsib.last_updated_by              AS last_updated_by               -- 最終更新者のUSER_ID
        ,xsib.last_update_date             AS last_update_date              -- 最終更新日時
        ,xsib.last_update_login            AS last_update_login             -- 最終更新時のLOGIN_ID
        ,xsib.request_id                   AS request_id                    -- 要求ID
        ,xsib.program_application_id       AS program_application_id        -- コンカレント・プログラムのアプリケーションID
        ,xsib.program_id                   AS program_id                    -- コンカレント・プログラムID
        ,xsib.program_update_date          AS program_update_date           -- プログラムによる更新日
         --
        ,disc.inventory_item_id            AS inventory_item_id             -- Disc品目ID
        ,disc.description                  AS disc_description              -- Disc摘要
        ,disc.primary_unit_of_measure      AS disc_primary_unit_of_measure  -- Disc基準単位
        ,disc.m_organization_id            AS m_organization_id             -- マスター組織ID
         --
        ,TRUNC(t.standard_cost, 2)         AS standard_cost                 -- 標準原価
        ,t.start_date                      AS standard_cost_start_date      -- 標準原価適用日
         --
        ,ximbp.item_name                   AS parent_item_name              -- 親商品名
        ,iimbp.item_no                     AS parent_item_no                -- 親商品コード
        ,ximbr.item_name                   AS renewal_item_name             -- リニューアル元商品名
         --
        ,TO_NUMBER(ipc.item_product_class) AS item_product_class            -- 商品製品区分
        ,ipc.item_product_class_name       AS item_product_class_name       -- 商品製品区分名
        ,ipc.item_product_category_id      AS item_product_category_id      -- 商品製品区分カテゴリID
        ,ipc.item_product_category_set_id  AS item_product_category_set_id  -- 商品製品区分カテゴリセットID
        ,TO_NUMBER(ho.hon_product_class)   AS hon_product_class             -- 本社商品区分
        ,ho.hon_product_class_name         AS hon_product_class_name        -- 本社商品区分名
        ,ho.hon_product_category_id        AS hon_product_category_id       -- 本社商品区分カテゴリID
        ,ho.hon_product_category_set_id    AS hon_product_category_set_id   -- 本社商品区分カテゴリセットID
        ,se.seisakugun                     AS seisakugun                    -- 政策群
        ,se.seisakugun_category_id         AS seisakugun_category_id        -- 政策群カテゴリID
        ,se.seisakugun_category_set_id     AS seisakugun_category_set_id    -- 政策群カテゴリセットID
         --
        ,uri.sales_target_name             AS sales_target_name             -- 売上対象名
        ,rat.rate_class_name               AS rate_class_name               -- 率区分名
        ,nets.nets_uom_code_name           AS nets_uom_code_name            -- 内容量単位名
        ,bar.baracha_div_name              AS baracha_div_name              -- バラ茶区分名
        ,obs.obsolete_class_name           AS obsolete_class_name           -- 廃止区分名
        ,nic.new_item_div_name             AS new_item_div_name             -- 新商品区分名
        ,sen.sp_supplier_code_name         AS sp_supplier_code_name         -- 専門店仕入先名
         --
-- 2009/05/12 障害T1_0906 add start by Yutaka.Kuboshima
        ,xsib.case_conv_inc_num            AS case_conv_inc_num             -- ケース換算入数
-- 2009/05/12 障害T1_0906 add end by Yutaka.Kuboshima
-- 2009/06/15 障害T1_1366 add start by Yutaka.Kuboshima
        ,ma.mark_group_code                AS mark_group_code               -- マーケ用群コード
        ,ma.mark_group_category_id         AS mark_group_category_id        -- マーケ用群コードカテゴリID
        ,ma.mark_group_category_set_id     AS mark_group_category_set_id    -- マーケ用群コードカテゴリセットI
        ,gu.group_code                     AS group_code                    -- 群コード
        ,gu.group_category_id              AS group_category_id             -- 群コードカテゴリID
        ,gu.group_category_set_id          AS group_category_set_id         -- 群コードカテゴリセットID
        ,ba.baracha_div                    AS baracha_div_category          -- バラ茶区分カテゴリ
        ,baracha_div_category_id           AS baracha_div_category_id       -- バラ茶区分カテゴリID
        ,baracha_div_category_set_id       AS baracha_div_category_set_id   -- バラ茶区分カテゴリセットID
-- 2009/06/15 障害T1_1366 add end by Yutaka.Kuboshima
-- 2012/08/29 E_本稼動_09591 add start by T.Makuta
        ,iimb.attribute19                  AS freshness_condition           -- 鮮度条件
-- 2012/08/29 E_本稼動_09591 add end by T.Makuta
FROM     ic_item_mst_b      iimb        -- OPM品目マスタ
        ,xxcmn_item_mst_b   ximb        -- OPM品目アドオンマスタ
        ,xxcmm_system_items_b xsib      -- Disc品目アドオンマスタ
        ,(SELECT      msib.inventory_item_id       AS inventory_item_id
                     ,msib.organization_id         AS m_organization_id
                     ,msib.segment1                AS item_code
                     ,msib.description             AS description
                     ,msib.primary_unit_of_measure AS primary_unit_of_measure
          FROM        mtl_system_items_b msib
-- ↓2009/03/19 Add Start
                     ,mtl_parameters               mp       -- 組織パラメータ
-- ↑2009/03/19 Add End
                     ,financials_system_parameters fsp
-- ↓2009/03/19 Add Start
--          WHERE       msib.organization_id = fsp.inventory_organization_id
          WHERE       mp.organization_id   = fsp.inventory_organization_id
          AND         msib.organization_id = mp.master_organization_id
-- ↑2009/03/19 Add End
        ) disc                          -- Disc品目マスタ
        ,(SELECT      SUM(ccd.cmpnt_cost)          AS standard_cost
                     ,ccd.item_id                  AS item_id
                     ,ccd.calendar_code            AS calendar_code
                     ,ccd.period_code              AS period_code
                     ,ccc.start_date               AS start_date
          FROM        cm_cmpt_dtl ccd                -- OPM原価
                     ,cm_cldr_dtl ccc                -- OPM原価カレンダ
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
        ) t                             -- OPM原価
        ,ic_item_mst_b      iimbp       -- OPM品目マスタ(親品目情報)
        ,xxcmn_item_mst_b   ximbp       -- OPM品目アドオンマスタ(親品目情報)
        ,ic_item_mst_b iimbr            -- OPM品目マスタ(リニューアル元商品名情報結合)
        ,xxcmn_item_mst_b   ximbr       -- OPM品目アドオンマスタ(リニューアル元商品名情報)
        ,(SELECT      gic_ipc.item_id          AS item_id
                     ,mcv_ipc.segment1         AS item_product_class
                     ,mcv_ipc.description      AS item_product_class_name
                     ,mcv_ipc.category_id      AS item_product_category_id
                     ,mcsv_ipc.category_set_id AS item_product_category_set_id
          FROM        gmi_item_categories  gic_ipc
                     ,mtl_category_sets_vl mcsv_ipc
                     ,mtl_categories_vl    mcv_ipc
          WHERE       gic_ipc.category_set_id    = mcsv_ipc.category_set_id
          AND         mcsv_ipc.category_set_name = '商品製品区分'
          AND         gic_ipc.category_id        = mcv_ipc.category_id
          AND         gic_ipc.category_id        = mcv_ipc.category_id
        ) ipc                           -- 商品製品区分用
        ,(SELECT      gic_ho.item_id          AS item_id
                     ,mcv_ho.segment1         AS hon_product_class
                     ,mcv_ho.description      AS hon_product_class_name
                     ,mcv_ho.category_id      AS hon_product_category_id
                     ,mcsv_ho.category_set_id AS hon_product_category_set_id
          FROM        gmi_item_categories  gic_ho
                     ,mtl_category_sets_vl mcsv_ho
                     ,mtl_categories_vl    mcv_ho
          WHERE       gic_ho.category_set_id    = mcsv_ho.category_set_id
          AND         mcsv_ho.category_set_name = '本社商品区分'
          AND         gic_ho.category_id        = mcv_ho.category_id
          AND         gic_ho.category_id        = mcv_ho.category_id
        ) ho                            -- 本社商品区分用
        ,(SELECT      gic_se.item_id          AS item_id
                     ,mcv_se.segment1         AS seisakugun
                     ,mcv_se.description      AS seisakugun_name
                     ,mcv_se.category_id      AS seisakugun_category_id
                     ,mcsv_se.category_set_id AS seisakugun_category_set_id
          FROM        gmi_item_categories  gic_se
                     ,mtl_category_sets_vl mcsv_se
                     ,mtl_categories_vl    mcv_se
          WHERE       gic_se.category_set_id    = mcsv_se.category_set_id
          AND         mcsv_se.category_set_name = '政策群コード'
          AND         gic_se.category_id        = mcv_se.category_id
          AND         gic_se.category_id        = mcv_se.category_id
        ) se                            -- 政策群用
-- 2009/06/15 障害T1_1366 add start by Yutaka.Kuboshima
        ,(SELECT      gic_se.item_id          AS item_id
                     ,mcv_se.segment1         AS mark_group_code
                     ,mcv_se.description      AS mark_group_code_name
                     ,mcv_se.category_id      AS mark_group_category_id
                     ,mcsv_se.category_set_id AS mark_group_category_set_id
          FROM        gmi_item_categories  gic_se
                     ,mtl_category_sets_vl mcsv_se
                     ,mtl_categories_vl    mcv_se
          WHERE       gic_se.category_set_id    = mcsv_se.category_set_id
          AND         mcsv_se.category_set_name = 'マーケ用群コード'
          AND         gic_se.category_id        = mcv_se.category_id
          AND         gic_se.category_id        = mcv_se.category_id
        ) ma                            -- マーケ用群コード用
        ,(SELECT      gic_se.item_id          AS item_id
                     ,mcv_se.segment1         AS group_code
                     ,mcv_se.description      AS group_code_name
                     ,mcv_se.category_id      AS group_category_id
                     ,mcsv_se.category_set_id AS group_category_set_id
          FROM        gmi_item_categories  gic_se
                     ,mtl_category_sets_vl mcsv_se
                     ,mtl_categories_vl    mcv_se
          WHERE       gic_se.category_set_id    = mcsv_se.category_set_id
          AND         mcsv_se.category_set_name = '群コード'
          AND         gic_se.category_id        = mcv_se.category_id
          AND         gic_se.category_id        = mcv_se.category_id
        ) gu                            -- 群コード用
        ,(SELECT      gic_se.item_id          AS item_id
                     ,mcv_se.segment1         AS baracha_div
                     ,mcv_se.description      AS baracha_div_name
                     ,mcv_se.category_id      AS baracha_div_category_id
                     ,mcsv_se.category_set_id AS baracha_div_category_set_id
          FROM        gmi_item_categories  gic_se
                     ,mtl_category_sets_vl mcsv_se
                     ,mtl_categories_vl    mcv_se
          WHERE       gic_se.category_set_id    = mcsv_se.category_set_id
          AND         mcsv_se.category_set_name = 'バラ茶区分'
          AND         gic_se.category_id        = mcv_se.category_id
          AND         gic_se.category_id        = mcv_se.category_id
        ) ba                            -- バラ茶区分用
-- 2009/06/15 障害T1_1366 add end by Yutaka.Kuboshima
        ,(SELECT      flv_uri.lookup_code  AS sales_target
                     ,flv_uri.meaning      AS sales_target_name
          FROM        fnd_lookup_values_vl flv_uri
          WHERE       flv_uri.lookup_type  = 'XXCMN_SALES_TARGET_CLASS'
        ) uri    -- 売上対象区分用
        ,(SELECT      flv_his.lookup_code  AS item_status
                     ,flv_his.meaning      AS item_status_name
          FROM        fnd_lookup_values_vl flv_his
          WHERE       flv_his.lookup_type  = 'XXCMM_ITM_STATUS'
        ) his    -- 品目ステータス用
        ,(SELECT      flv_rat.lookup_code  AS rate_class
                     ,flv_rat.meaning      AS rate_class_name
          FROM        fnd_lookup_values_vl flv_rat
          WHERE       flv_rat.lookup_type  = 'XXCMM_ITM_RATE_CLASS'
        ) rat    -- 率区分用
        ,(SELECT      flv_nets.lookup_code  AS nets_uom_code
                     ,flv_nets.meaning      AS nets_uom_code_name
          FROM        fnd_lookup_values_vl flv_nets
          WHERE       flv_nets.lookup_type = 'XXCMM_ITM_NET_UOM_CODE'
        ) nets   -- 内容量単位用
        ,(SELECT      flv_bar.lookup_code  AS baracha_div
                     ,flv_bar.meaning      AS baracha_div_name
          FROM        fnd_lookup_values_vl flv_bar
          WHERE       flv_bar.lookup_type  = 'XXCMM_ITM_BARACHAKUBUN'
        ) bar    -- バラ茶区分用
        ,(SELECT      flv_obs.lookup_code  AS obsolete_class
                     ,flv_obs.meaning      AS obsolete_class_name
          FROM        fnd_lookup_values_vl flv_obs
          WHERE       flv_obs.lookup_type  = 'XXCMM_ITM_HAISHI_KUBUN'
        ) obs    -- 廃止区分用
        ,(SELECT      flv_nic.lookup_code  AS new_item_div
                     ,flv_nic.meaning      AS new_item_div_name
          FROM        fnd_lookup_values_vl flv_nic
          WHERE       flv_nic.lookup_type  = 'XXCMM_ITM_SHINSYOHINKUBUN'
        ) nic    -- 新商品区分用
        ,(SELECT      flv_sen.lookup_code  AS sp_supplier_code
                     ,flv_sen.description  AS sp_supplier_code_name
          FROM        fnd_lookup_values_vl flv_sen
          WHERE       flv_sen.lookup_type  = 'XXCMM_ITM_SENMONTEN_SHIIRESAKI'
        ) sen    -- 専門店仕入先用
WHERE   iimb.item_id                 = ximb.item_id
-- 2009/08/20 modify start by Yutaka.Kuboshima
--AND     ximb.start_date_active(+)   <= TRUNC(SYSDATE)
--AND     ximb.end_date_active(+)     >= TRUNC(SYSDATE)
AND     ximb.start_date_active(+)   <= xxccp_common_pkg2.get_process_date
AND     ximb.end_date_active(+)     >= xxccp_common_pkg2.get_process_date
-- 2009/08/20 modify end by Yutaka.Kuboshima
AND     iimb.item_no                 = disc.item_code(+)            -- 外部結合
-- 2009/05/12 障害T1_0317 modify start by Yutaka.Kuboshima
--AND     iimb.item_no                 = xsib.item_code(+)
AND     iimb.item_no                 = xsib.item_code
-- 2009/05/12 障害T1_0317 modify end by Yutaka.Kuboshima
AND     iimb.item_id                 = t.item_id(+)
AND     ximb.parent_item_id          = ximbp.item_id(+)          -- xxcmn_item_mst_b(子)  xxcmn_item_mst_b(親)
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
-- 2009/06/15 障害T1_1366 add start by Yutaka.Kuboshima
AND     iimb.item_id                 = ma.item_id(+)
AND     iimb.item_id                 = gu.item_id(+)
AND     iimb.item_id                 = ba.item_id(+)
-- 2009/06/15 障害T1_1366 add end by Yutaka.Kuboshima
-- Lookup系
AND     iimb.attribute26             = uri.sales_target(+)
AND     TO_CHAR(xsib.item_status)    = his.item_status(+)
AND     ximb.rate_class              = rat.rate_class(+)
AND     TO_CHAR(xsib.baracha_div)    = bar.baracha_div(+)
AND     xsib.nets_uom_code           = nets.nets_uom_code(+)
AND     ximb.obsolete_class          = obs.obsolete_class(+)
AND     xsib.new_item_div            = nic.new_item_div(+)
AND     xsib.sp_supplier_code        = sen.sp_supplier_code(+)
-- 2009/05/12 障害T1_0317 delete start by Yutaka.Kuboshima
--AND     LENGTHB(iimb.item_no) = 7
--AND     iimb.item_no BETWEEN '0000001' AND '3999999'
-- 2009/05/12 障害T1_0317 delete end by Yutaka.Kuboshima
/
COMMENT ON TABLE APPS.XXCMM_ITEM_SCREEN_V IS '品目登録画面ビュー'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_NO IS '品名コード'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_ID IS '品名ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_DESC1 IS 'OPM品目摘要'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_UM IS '基準単位'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LIST_PRICE IS '定価'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LIST_PRICE_START_DATE IS '定価適用日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BUSINESS_COST IS '営業原価'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BUSINESS_COST_START_DATE IS '営業原価適用日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.CASE_NUMBER IS 'ケース入数'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NET IS 'NET'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.RELEASE_DAY IS '発売開始日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SALES_TARGET IS '売上対象'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.JAN_CODE IS 'JANコード'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITF_CODE IS 'ITFコード'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.WEIGHT_VOLUME_CLASS IS '重量容積区分'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.WEIGHT_VOLUME IS '重量／体積'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.DUALUM_IND IS '二重管理'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LOT_CTL IS 'ロット'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.AUTOLOT_ACTIVE_INDICATOR IS '自動ロット採番有効'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LOT_SUFFIX IS 'ロット・サフィックス'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OLD_SEISAKUGUN IS '旧・群コード'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NEW_SEISAKUGUN IS '新・群コード'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SEISAKUGUN_START_DATE IS '群コード適用開始日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_CREATED_BY IS 'OPM品目_作成者のUSER_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_CREATION_DATE IS 'OPM品目_作成日時'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_LAST_UPDATED_BY IS 'OPM品目_最終更新者のUSER_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_LAST_UPDATE_DATE IS 'OPM品目_最終更新日時'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_LAST_UPDATE_LOGIN IS 'OPM品目_最終更新時のLOGIN_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_REQUEST_ID IS 'OPM品目_要求ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_PROGRAM_APPLICATION_ID IS 'OPM品目_コンカレント・プログラムのアプリケーションID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_PROGRAM_ID IS 'OPM品目_コンカレント・プログラムID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.IIMB_PROGRAM_UPDATE_DATE IS 'OPM品目_プログラムによる更新日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_NAME IS '正式名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_SHORT_NAME IS '略称'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_NAME_ALT IS 'カナ名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PARENT_ITEM_ID IS '親商品ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.RATE_CLASS IS '率区分'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PRODUCT_CLASS IS '商品分類'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PALETTE_MAX_CS_QTY IS '配数'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PALETTE_MAX_STEP_QTY IS '段数'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OBSOLETE_DATE IS '廃止日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OBSOLETE_CLASS IS '廃止区分'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OPM_ITEM_START_DATE IS '適用開始日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OPM_ITEM_END_DATE IS '適用終了日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OPM_ITEM_ACTIVE_FLAG IS '適用済フラグ'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_CREATED_BY IS 'OPM品目アドオン_作成者のUSER_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_CREATION_DATE IS 'OPM品目アドオン_作成日時'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_LAST_UPDATED_BY IS 'OPM品目アドオン_最終更新者のUSER_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_LAST_UPDATE_DATE IS 'OPM品目アドオン_最終更新日時'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_LAST_UPDATE_LOGIN IS 'OPM品目アドオン_最終更新時のLOGIN_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_REQUEST_ID IS 'OPM品目アドオン_要求ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_PROGRAM_APPLICATION_ID IS 'OPM品目アドオン_コンカレント・プログラムのアプリケーションID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_PROGRAM_ID IS 'OPM品目アドオン_コンカレント・プログラムID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.XIMB_PROGRAM_UPDATE_DATE IS 'OPM品目アドオン_プログラムによる更新日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_STATUS_APPLY_DATE IS '品目ステータス適用日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_STATUS IS '品目ステータス'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_STATUS_NAME IS '品目ステータス名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NETS IS '内容量'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NETS_UOM_CODE IS '内容量単位'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.INC_NUM IS '内訳入数'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BARACHA_DIV IS 'バラ茶区分'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.CASE_JAN_CODE IS 'ケースJANコード'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BOWL_INC_NUM IS 'ボール入数'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.VESSEL_GROUP IS '容器群'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NEW_ITEM_DIV IS '新商品区分'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ACNT_GROUP IS '経理群'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ACNT_VESSEL_GROUP IS '経理容器群'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BRAND_GROUP IS 'ブランド群'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.RENEWAL_ITEM_CODE IS 'リニューアル元商品コード'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SP_SUPPLIER_CODE IS '専門店仕入先'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SEARCH_UPDATE_DATE IS '検索対象更新日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.CREATED_BY IS '作成者のUSER_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.CREATION_DATE IS '作成日時'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LAST_UPDATED_BY IS '最終更新者のUSER_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LAST_UPDATE_DATE IS '最終更新日時'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.LAST_UPDATE_LOGIN IS '最終更新時のLOGIN_ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.REQUEST_ID IS '要求ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PROGRAM_APPLICATION_ID IS 'コンカレント・プログラムのアプリケーションID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PROGRAM_ID IS 'コンカレント・プログラムID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PROGRAM_UPDATE_DATE IS 'プログラムによる更新日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.INVENTORY_ITEM_ID IS 'Disc品目ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.DISC_DESCRIPTION IS 'Disc摘要'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.DISC_PRIMARY_UNIT_OF_MEASURE IS 'Disc基準単位'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.M_ORGANIZATION_ID IS 'マスター組織ID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.STANDARD_COST IS '標準原価'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.STANDARD_COST_START_DATE IS '標準原価適用日'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PARENT_ITEM_NAME IS '親商品名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.PARENT_ITEM_NO IS '親商品コード'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.RENEWAL_ITEM_NAME IS 'リニューアル元商品名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_PRODUCT_CLASS IS '商品製品区分'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_PRODUCT_CLASS_NAME IS '商品製品区分名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_PRODUCT_CATEGORY_ID IS '商品製品区分カテゴリID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.ITEM_PRODUCT_CATEGORY_SET_ID IS '商品製品区分カテゴリセットID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.HON_PRODUCT_CLASS IS '本社商品区分'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.HON_PRODUCT_CLASS_NAME IS '本社商品区分名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.HON_PRODUCT_CATEGORY_ID IS '本社商品区分カテゴリID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.HON_PRODUCT_CATEGORY_SET_ID IS '本社商品区分カテゴリセットID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SEISAKUGUN IS '政策群'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SEISAKUGUN_CATEGORY_ID IS '政策群カテゴリID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SEISAKUGUN_CATEGORY_SET_ID IS '政策群カテゴリセットID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SALES_TARGET_NAME IS '売上対象名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.RATE_CLASS_NAME IS '率区分名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NETS_UOM_CODE_NAME IS '内容量単位名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BARACHA_DIV_NAME IS 'バラ茶区分名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.OBSOLETE_CLASS_NAME IS '廃止区分名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.NEW_ITEM_DIV_NAME IS '新商品区分名'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.SP_SUPPLIER_CODE_NAME IS '専門店仕入先名'
/
-- 2009/05/12 障害T1_0906 add start by Yutaka.Kuboshima
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.CASE_CONV_INC_NUM IS 'ケース換算入数'
/
-- 2009/06/15 障害T1_1366 add start by Yutaka.Kuboshima
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.MARK_GROUP_CODE IS 'マーケ用群コード'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.MARK_GROUP_CATEGORY_ID IS 'マーケ用群コードカテゴリID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.mark_group_category_set_id IS 'マーケ用群コードカテゴリセットID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.GROUP_CODE IS '群コード'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.GROUP_CATEGORY_ID IS '群コードカテゴリID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.GROUP_CATEGORY_SET_ID IS '群コードカテゴリセットID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BARACHA_DIV_CATEGORY IS 'バラ茶区分カテゴリ'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BARACHA_DIV_CATEGORY_ID IS 'バラ茶区分カテゴリID'
/
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.BARACHA_DIV_CATEGORY_SET_ID IS 'バラ茶区分カテゴリセットID'
/
-- 2012/08/29 E_本稼動_09591 add start by T.Makuta
COMMENT ON COLUMN APPS.XXCMM_ITEM_SCREEN_V.FRESHNESS_CONDITION IS '鮮度条件'
-- 2012/08/29 E_本稼動_09591 add end by T.Makuta
/
