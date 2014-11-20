CREATE OR REPLACE VIEW apps.xxwip_batch_lot_reinvest_v
(
  row_id
, storehouse_id                   -- 保管倉庫ID
, storehouse_code                 -- 保管倉庫コード
, storehouse_name                 -- 保管倉庫名称
, batch_id                        -- バッチID
, material_detail_id              -- 生産原料詳細ID
, mtl_detail_addon_id             -- 生産原料詳細アドオンID
, mov_lot_dtl_id                  -- ロット詳細ID
, trans_id                        -- トランザクションID
, item_id                         -- 品目ID
, item_no                         -- 品目コード
, lot_id                          -- ロットID
, lot_no                          -- ロットNo
, lot_create_type                 -- 作成区分
, instructions_qty                -- 指示総数
, instructions_qty_orig           -- 元指示総数
, stock_qty                       -- 在庫総数
, enabled_qty                     -- 可能数
, entity_inner                    -- 在庫入数
, unit_price                      -- 単価
, orgn_code                       -- 取引先コード
, orgn_name                       -- 取引先名称
, stocking_form                   -- 仕入形態
, tea_season_type                 -- 茶期区分
, period_of_year                  -- 年度
, producing_area                  -- 産地
, package_type                    -- タイプ
, rank1                           -- R1
, rank2                           -- R2
, rank3                           -- R3
, maker_date                      -- 製造日
, use_by_date                     -- 賞味期限日
, unique_sign                     -- 固有記号
, dely_date                       -- 納入日（初回）
, slip_type_name                  -- 伝票区分(名称)
, routing_no                      -- ラインNo
, routing_name                    -- ライン名称
, remarks_column                  -- 摘要
, record_type
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
, xmd_last_update_date
)
AS
  SELECT
    ilm.rowid                       row_id
  , xilv.inventory_location_id      storehouse_id                   -- 保管倉庫ID
  , enable_lot.storehouse_code      storehouse_code                 -- 保管倉庫(コード)
  , xilv.description                storehouse_name                 -- 保管倉庫(名称)
  , enable_lot.batch_id             batch_id                        -- バッチID
  , enable_lot.material_detail_id   material_detail_id              -- 生産原料詳細ID
  , enable_lot.mtl_detail_addon_id  mtl_detail_addon_id             -- 生産原料詳細アドオンID
  , xmld.mov_lot_dtl_id             mov_lot_dtl_id                  -- 移動ロット詳細ID
  , NULL                            trans_id
  , enable_lot.item_id              item_id                         -- 品目ID
  , xim2v.item_no                   item_no                         -- 品目(コード)
  , enable_lot.lot_id               lot_id                          -- ロットID
  , DECODE( xic4v.item_class_code
          , '2', NULL
          , ilm.lot_no )
                                    lot_no                          -- ロットNo
  , ilm.attribute24                 lot_create_type                 -- 作成区分
  , enable_lot.instructions_qty     instructions_qty                -- 指示総数
  , enable_lot.instructions_qty     instructions_qty_orig           -- 元指示総数
  , enable_lot.stock_qty            stock_qty                       -- 在庫総数
  , enable_lot.enabled_qty          enabled_qty                     -- 可能数
  , TO_NUMBER( DECODE( ilm.attribute6
                     , '0', NULL
                     , ilm.attribute6 )
             )
                                    entity_inner                    -- 在庫入数
  , TO_NUMBER( ilm.attribute7 )     unit_price                      -- 単価
  , pv.segment1                     orgn_code                       -- 取引先コード
  , xv.vendor_short_name            orgn_name                       -- 取引先名称
  , xlvv_l05.meaning                stocking_form                   -- 仕入形態
  , xlvv_l06.meaning                tea_season_type                 -- 茶期区分
  , ilm.attribute11                 period_of_year                  -- 年度
  , xlvv_l07.meaning                producing_area                  -- 産地
  , xlvv_l08.meaning                package_type                    -- タイプ
  , ilm.attribute14                 rank1                           -- R1
  , ilm.attribute15                 rank2                           -- R2
  , ilm.attribute19                 rank3                           -- R3
  , ilm.attribute1                  maker_date                      -- 製造日
  , ilm.attribute3                  use_by_date                     -- 賞味期限日
  , ilm.attribute2                  unique_sign                     -- 固有記号
  , ilm.attribute4                  dely_date                       -- 納入日（初回）
  , xlvv_l03.meaning                slip_type_name                  -- 伝票区分(名称)
  , grv.routing_no                  routing_no                      -- ラインNo
  , grv.attribute1                  routing_name                    -- ライン名称
  , ilm.attribute18                 remarks_column                  -- 摘要
  , enable_lot.record_type          record_type
  , ilm.created_by
  , ilm.creation_date
  , ilm.last_updated_by
  , ilm.last_update_date
  , ilm.last_update_login
  , enable_lot.xmd_last_update_date
  FROM
    xxcmn_lookup_values_v           xlvv_l03      -- 伝票区分
  , xxcmn_lookup_values_v           xlvv_l05      -- 仕入形態
  , xxcmn_lookup_values_v           xlvv_l06      -- 茶期区分
  , xxcmn_lookup_values_v           xlvv_l07      -- 産地
  , xxcmn_lookup_values_v           xlvv_l08      -- タイプ
  , xxinv_mov_lot_details           xmld          -- 移動ロット詳細
  , gmd_routings_vl                 grv           -- 工順マスタVIEW
  , xxcmn_vendors                   xv            -- 仕入先アドオン
  , po_vendors                      pv            -- 仕入先
  , xxcmn_item_locations_v          xilv          -- 保管倉庫
  , xxcmn_item_categories4_v        xic4v         -- 品目カテゴリ情報VIEW4
  , xxcmn_item_mst2_v               xim2v         -- OPM品目マスタVIEW2
  , gme_batch_header                gbh           -- 生産バッチヘッダ
  , ic_lots_mst                     ilm           -- OPMロット
  , (
      SELECT
        TO_CHAR( MAX( record_type ) )   record_type
      , batch_id                        batch_id                      -- バッチID
      , material_detail_id              material_detail_id            -- 生産原料詳細ID
      , MAX( mtl_detail_addon_id )      mtl_detail_addon_id           -- 生産原料詳細アドオンID
      , item_id                         item_id                       -- 品目ID
      , lot_id                          lot_id                        -- ロットID
      , storehouse_code                 storehouse_code               -- 保管場所コード
      , MAX( instructions_qty )         instructions_qty              -- 指示総数
      , SUM( stock_qty )                stock_qty                     -- 在庫総数
      , SUM( enabled_qty )              enabled_qty                   -- (引当)可能数
      , MAX( xmd_last_update_date )     xmd_last_update_date          -- 最終更新日(排他制御用)
      FROM
        (
          SELECT
            1                               record_type                   -- 更新
          , gmd.batch_id                    batch_id                      -- バッチID
          , gmd.material_detail_id          material_detail_id            -- 生産原料詳細ID
          , xmd.mtl_detail_addon_id         mtl_detail_addon_id           -- 生産原料詳細アドオンID
          , xmd.item_id                     item_id                       -- 品目ID
          , xmd.lot_id                      lot_id                        -- ロットID
          , xmd.location_code               storehouse_code               -- 保管場所コード
          , xmd.instructions_qty            instructions_qty              -- 指示総数
          , 0                               stock_qty                     -- 在庫総数
          , 0                               enabled_qty                   -- (引当)可能数
          , xmd.last_update_date            xmd_last_update_date          -- 最終更新日(排他制御用)
          FROM
            gme_material_details            gmd     -- 生産原料詳細
          , xxwip_material_detail           xmd     -- 生産原料詳細アドオン
          WHERE
                gmd.material_detail_id  = xmd.material_detail_id
            AND gmd.line_type           = -1                          -- 投入品
            AND gmd.attribute5          = 'Y'                         -- 打込
            AND gmd.attribute24         IS NULL                       -- 未取消
            AND xmd.plan_type           IN ( '1', '2', '3' )
--
          UNION
--
          SELECT
            0                               record_type           -- 挿入
          , stock.batch_id                  batch_id              -- バッチID
          , stock.material_detail_id        material_detail_id    -- 生産原料詳細ID
          , NULL                            mtl_detail_addon_id   -- 生産原料詳細アドオンID
          , stock.item_id                   item_id               -- 品目ID
          , stock.lot_id                    lot_id                -- ロットID
          , stock.storehouse_code           storehouse_code       -- 保管場所コード
          , NULL                            instructions_qty      -- 指示総数
          , xxcmn_common_pkg.get_stock_qty(
              stock.inventory_location_id, stock.item_id, stock.lot_id )
                                            stock_qty             -- 在庫総数
          , stock.enabled_qty               enabled_qty           -- (引当)可能数
          , NULL                            xmd_last_update_date  -- 最終更新日(排他制御用)
          FROM
            (
              SELECT
                gmd.batch_id                                                                                batch_id
              , gmd.material_detail_id                                                                      material_detail_id
              , gmd.item_id                                                                                 item_id
              , lot.lot_id                                                                                  lot_id
              , xilv.segment1                                                                               storehouse_code
              , xilv.inventory_location_id                                                                  inventory_location_id
              , xxcmn_common_pkg.get_stock_qty( xilv.inventory_location_id, gmd.item_id, lot.nise_lot_id )  enabled_qty
              FROM
                xxcmn_item_locations_v          xilv   -- 保管倉庫
              , gme_material_details            gmd    -- 生産原料詳細
              , (
                  SELECT  -- 資材以外
                    ilm.item_id                     item_id
                  , ilm.lot_id                      lot_id
                  , ilm.lot_id                      nise_lot_id
                  FROM
                    xxcmn_lot_status_v              xlsv          -- ロットステータス
                  , xxcmn_item_categories4_v        xic4v         -- 品目カテゴリ情報VIEW4
                  , ic_lots_mst                     ilm           -- OPMロットマスタ
                  WHERE
                        xlsv.prod_class_code         = xic4v.prod_class_code
                    AND xlsv.raw_mate_turn_m_reserve = 'Y'
                    AND xlsv.lot_status              = ilm.attribute23
                    AND xic4v.item_id                = ilm.item_id
                    AND NOT EXISTS(
                          SELECT 'X'
                          FROM xxcmn_item_categories4_v        xic4v2
                          WHERE xic4v2.item_id         = ilm.item_id
                            AND xic4v2.item_class_code = '2'
                        )
--
                  UNION ALL
--
                  SELECT  -- 資材
                    ilm.item_id                     item_id
                  , ilm.lot_id                      lot_id
                  , NULL                            nise_lot_id
                  FROM
                    ic_lots_mst                     ilm           -- OPMロットマスタ
                  WHERE
                        EXISTS(
                          SELECT 'X'
                          FROM xxcmn_item_categories4_v        xic4v3
                          WHERE xic4v3.item_id         = ilm.item_id
                            AND xic4v3.item_class_code = '2'
                        )
                ) lot
              WHERE
                    (
                       ( xilv.segment1 IN ( gmd.attribute13, gmd.attribute18, gmd.attribute19, gmd.attribute20, gmd.attribute21 ) )
                    OR (     gmd.attribute13 IS NULL
                         AND gmd.attribute18 IS NULL
                         AND gmd.attribute19 IS NULL
                         AND gmd.attribute20 IS NULL
                         AND gmd.attribute21 IS NULL
                       )
                    )
                AND gmd.line_type           = -1                            -- 投入品
                AND gmd.attribute5          = 'Y'                           -- 打込
                AND gmd.attribute24         IS NULL                         -- 未取消
                AND gmd.item_id             = lot.item_id
            ) stock
          WHERE
                stock.enabled_qty > 0
        )
      GROUP BY
        batch_id
      , material_detail_id
      , item_id
      , lot_id
      , storehouse_code
    ) enable_lot
  WHERE
        xlvv_l03.lookup_code     (+) = ilm.attribute16
    AND xlvv_l03.lookup_type     (+) = 'XXCMN_L03'
    AND xlvv_l05.lookup_code     (+) = ilm.attribute9
    AND xlvv_l05.lookup_type     (+) = 'XXCMN_L05'
    AND xlvv_l06.lookup_code     (+) = ilm.attribute10
    AND xlvv_l06.lookup_type     (+) = 'XXCMN_L06'
    AND xlvv_l07.lookup_code     (+) = ilm.attribute12
    AND xlvv_l07.lookup_type     (+) = 'XXCMN_L07'
    AND xlvv_l08.lookup_code     (+) = ilm.attribute13
    AND xlvv_l08.lookup_type     (+) = 'XXCMN_L08'
    AND xmld.mov_line_id         (+) = enable_lot.mtl_detail_addon_id
    AND xmld.lot_id              (+) = enable_lot.lot_id
    AND grv.routing_no           (+) = ilm.attribute17
    AND xv.vendor_id             (+) = pv.vendor_id
    AND pv.segment1              (+) = ilm.attribute8
    AND xilv.segment1                = enable_lot.storehouse_code
    AND xic4v.item_id                = enable_lot.item_id
    AND xim2v.item_id                = enable_lot.item_id
    AND xim2v.start_date_active      <= TRUNC( gbh.plan_start_date )
    AND xim2v.end_date_active        >= TRUNC( gbh.plan_start_date )
    AND gbh.batch_id                 = enable_lot.batch_id
    AND ilm.item_id                  = enable_lot.item_id
    AND ilm.lot_id                   = enable_lot.lot_id
/
