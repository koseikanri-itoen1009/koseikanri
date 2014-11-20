CREATE OR REPLACE VIEW apps.xxwip_batch_lot_reinvest_v
(
  row_id
, storehouse_id                   -- �ۊǑq��ID
, storehouse_code                 -- �ۊǑq�ɃR�[�h
, storehouse_name                 -- �ۊǑq�ɖ���
, batch_id                        -- �o�b�`ID
, material_detail_id              -- ���Y�����ڍ�ID
, mtl_detail_addon_id             -- ���Y�����ڍ׃A�h�I��ID
, mov_lot_dtl_id                  -- ���b�g�ڍ�ID
, trans_id                        -- �g�����U�N�V����ID
, item_id                         -- �i��ID
, item_no                         -- �i�ڃR�[�h
, lot_id                          -- ���b�gID
, lot_no                          -- ���b�gNo
, lot_create_type                 -- �쐬�敪
, instructions_qty                -- �w������
, instructions_qty_orig           -- ���w������
, stock_qty                       -- �݌ɑ���
, enabled_qty                     -- �\��
, entity_inner                    -- �݌ɓ���
, unit_price                      -- �P��
, orgn_code                       -- �����R�[�h
, orgn_name                       -- ����於��
, stocking_form                   -- �d���`��
, tea_season_type                 -- �����敪
, period_of_year                  -- �N�x
, producing_area                  -- �Y�n
, package_type                    -- �^�C�v
, rank1                           -- R1
, rank2                           -- R2
, rank3                           -- R3
, maker_date                      -- ������
, use_by_date                     -- �ܖ�������
, unique_sign                     -- �ŗL�L��
, dely_date                       -- �[�����i����j
, slip_type_name                  -- �`�[�敪(����)
, routing_no                      -- ���C��No
, routing_name                    -- ���C������
, remarks_column                  -- �E�v
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
  , xilv.inventory_location_id      storehouse_id                   -- �ۊǑq��ID
  , enable_lot.storehouse_code      storehouse_code                 -- �ۊǑq��(�R�[�h)
  , xilv.description                storehouse_name                 -- �ۊǑq��(����)
  , enable_lot.batch_id             batch_id                        -- �o�b�`ID
  , enable_lot.material_detail_id   material_detail_id              -- ���Y�����ڍ�ID
  , enable_lot.mtl_detail_addon_id  mtl_detail_addon_id             -- ���Y�����ڍ׃A�h�I��ID
  , xmld.mov_lot_dtl_id             mov_lot_dtl_id                  -- �ړ����b�g�ڍ�ID
  , NULL                            trans_id
  , enable_lot.item_id              item_id                         -- �i��ID
  , xim2v.item_no                   item_no                         -- �i��(�R�[�h)
  , enable_lot.lot_id               lot_id                          -- ���b�gID
  , DECODE( xic4v.item_class_code
          , '2', NULL
          , ilm.lot_no )
                                    lot_no                          -- ���b�gNo
  , ilm.attribute24                 lot_create_type                 -- �쐬�敪
  , enable_lot.instructions_qty     instructions_qty                -- �w������
  , enable_lot.instructions_qty     instructions_qty_orig           -- ���w������
  , enable_lot.stock_qty            stock_qty                       -- �݌ɑ���
  , enable_lot.enabled_qty          enabled_qty                     -- �\��
  , TO_NUMBER( DECODE( ilm.attribute6
                     , '0', NULL
                     , ilm.attribute6 )
             )
                                    entity_inner                    -- �݌ɓ���
  , TO_NUMBER( ilm.attribute7 )     unit_price                      -- �P��
  , pv.segment1                     orgn_code                       -- �����R�[�h
  , xv.vendor_short_name            orgn_name                       -- ����於��
  , xlvv_l05.meaning                stocking_form                   -- �d���`��
  , xlvv_l06.meaning                tea_season_type                 -- �����敪
  , ilm.attribute11                 period_of_year                  -- �N�x
  , xlvv_l07.meaning                producing_area                  -- �Y�n
  , xlvv_l08.meaning                package_type                    -- �^�C�v
  , ilm.attribute14                 rank1                           -- R1
  , ilm.attribute15                 rank2                           -- R2
  , ilm.attribute19                 rank3                           -- R3
  , ilm.attribute1                  maker_date                      -- ������
  , ilm.attribute3                  use_by_date                     -- �ܖ�������
  , ilm.attribute2                  unique_sign                     -- �ŗL�L��
  , ilm.attribute4                  dely_date                       -- �[�����i����j
  , xlvv_l03.meaning                slip_type_name                  -- �`�[�敪(����)
  , grv.routing_no                  routing_no                      -- ���C��No
  , grv.attribute1                  routing_name                    -- ���C������
  , ilm.attribute18                 remarks_column                  -- �E�v
  , enable_lot.record_type          record_type
  , ilm.created_by
  , ilm.creation_date
  , ilm.last_updated_by
  , ilm.last_update_date
  , ilm.last_update_login
  , enable_lot.xmd_last_update_date
  FROM
    xxcmn_lookup_values_v           xlvv_l03      -- �`�[�敪
  , xxcmn_lookup_values_v           xlvv_l05      -- �d���`��
  , xxcmn_lookup_values_v           xlvv_l06      -- �����敪
  , xxcmn_lookup_values_v           xlvv_l07      -- �Y�n
  , xxcmn_lookup_values_v           xlvv_l08      -- �^�C�v
  , xxinv_mov_lot_details           xmld          -- �ړ����b�g�ڍ�
  , gmd_routings_vl                 grv           -- �H���}�X�^VIEW
  , xxcmn_vendors                   xv            -- �d����A�h�I��
  , po_vendors                      pv            -- �d����
  , xxcmn_item_locations_v          xilv          -- �ۊǑq��
  , xxcmn_item_categories4_v        xic4v         -- �i�ڃJ�e�S�����VIEW4
  , xxcmn_item_mst2_v               xim2v         -- OPM�i�ڃ}�X�^VIEW2
  , gme_batch_header                gbh           -- ���Y�o�b�`�w�b�_
  , ic_lots_mst                     ilm           -- OPM���b�g
  , (
      SELECT
        TO_CHAR( MAX( record_type ) )   record_type
      , batch_id                        batch_id                      -- �o�b�`ID
      , material_detail_id              material_detail_id            -- ���Y�����ڍ�ID
      , MAX( mtl_detail_addon_id )      mtl_detail_addon_id           -- ���Y�����ڍ׃A�h�I��ID
      , item_id                         item_id                       -- �i��ID
      , lot_id                          lot_id                        -- ���b�gID
      , storehouse_code                 storehouse_code               -- �ۊǏꏊ�R�[�h
      , MAX( instructions_qty )         instructions_qty              -- �w������
      , SUM( stock_qty )                stock_qty                     -- �݌ɑ���
      , SUM( enabled_qty )              enabled_qty                   -- (����)�\��
      , MAX( xmd_last_update_date )     xmd_last_update_date          -- �ŏI�X�V��(�r������p)
      FROM
        (
          SELECT
            1                               record_type                   -- �X�V
          , gmd.batch_id                    batch_id                      -- �o�b�`ID
          , gmd.material_detail_id          material_detail_id            -- ���Y�����ڍ�ID
          , xmd.mtl_detail_addon_id         mtl_detail_addon_id           -- ���Y�����ڍ׃A�h�I��ID
          , xmd.item_id                     item_id                       -- �i��ID
          , xmd.lot_id                      lot_id                        -- ���b�gID
          , xmd.location_code               storehouse_code               -- �ۊǏꏊ�R�[�h
          , xmd.instructions_qty            instructions_qty              -- �w������
          , 0                               stock_qty                     -- �݌ɑ���
          , 0                               enabled_qty                   -- (����)�\��
          , xmd.last_update_date            xmd_last_update_date          -- �ŏI�X�V��(�r������p)
          FROM
            gme_material_details            gmd     -- ���Y�����ڍ�
          , xxwip_material_detail           xmd     -- ���Y�����ڍ׃A�h�I��
          WHERE
                gmd.material_detail_id  = xmd.material_detail_id
            AND gmd.line_type           = -1                          -- �����i
            AND gmd.attribute5          = 'Y'                         -- �ō�
            AND gmd.attribute24         IS NULL                       -- �����
            AND xmd.plan_type           IN ( '1', '2', '3' )
--
          UNION
--
          SELECT
            0                               record_type           -- �}��
          , stock.batch_id                  batch_id              -- �o�b�`ID
          , stock.material_detail_id        material_detail_id    -- ���Y�����ڍ�ID
          , NULL                            mtl_detail_addon_id   -- ���Y�����ڍ׃A�h�I��ID
          , stock.item_id                   item_id               -- �i��ID
          , stock.lot_id                    lot_id                -- ���b�gID
          , stock.storehouse_code           storehouse_code       -- �ۊǏꏊ�R�[�h
          , NULL                            instructions_qty      -- �w������
          , xxcmn_common_pkg.get_stock_qty(
              stock.inventory_location_id, stock.item_id, stock.lot_id )
                                            stock_qty             -- �݌ɑ���
          , stock.enabled_qty               enabled_qty           -- (����)�\��
          , NULL                            xmd_last_update_date  -- �ŏI�X�V��(�r������p)
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
                xxcmn_item_locations_v          xilv   -- �ۊǑq��
              , gme_material_details            gmd    -- ���Y�����ڍ�
              , (
                  SELECT  -- ���ވȊO
                    ilm.item_id                     item_id
                  , ilm.lot_id                      lot_id
                  , ilm.lot_id                      nise_lot_id
                  FROM
                    xxcmn_lot_status_v              xlsv          -- ���b�g�X�e�[�^�X
                  , xxcmn_item_categories4_v        xic4v         -- �i�ڃJ�e�S�����VIEW4
                  , ic_lots_mst                     ilm           -- OPM���b�g�}�X�^
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
                  SELECT  -- ����
                    ilm.item_id                     item_id
                  , ilm.lot_id                      lot_id
                  , NULL                            nise_lot_id
                  FROM
                    ic_lots_mst                     ilm           -- OPM���b�g�}�X�^
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
                AND gmd.line_type           = -1                            -- �����i
                AND gmd.attribute5          = 'Y'                           -- �ō�
                AND gmd.attribute24         IS NULL                         -- �����
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
