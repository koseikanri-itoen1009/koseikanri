CREATE OR REPLACE VIEW apps.xxwip_batch_all_v
(
  row_id
, duty_status                     -- Æ±Xe[^X
, duty_status_name                -- Æ±Xe[^X(¼Ì)
, duty_status_order               -- Æ±Xe[^X(\[gp)
, batch_id                        -- ob`ID
, batch_no                        -- ob`No
, material_detail_id              -- ¶Y´¿Ú×ID
, trans_id                        -- Û¯ÝÉgUNVID
, item_id                         -- iÚID
, item_no                         -- iÚR[h
, item_short_name                 -- iÚ(ªÌ)
, lot_id                          -- bgID
, lot_no                          -- bgNo
, routing_id                      -- HID
, routing_no                      -- HNo
, routing_name                    -- C¼EªÌ
, slip_type                       -- `[æª
, slip_type_name                  -- `[æª(¼Ì)
, in_out_type                     -- àOæª
, product_plan_date               -- ¶Y\èú
, store_plan_date                 -- ´¿üÉ\èú
, product_date                    -- ¶Yú
, maker_date                      -- »¢ú
, use_by_date                     -- Ü¡úÀú
, request_qty                     -- Ë
, instructions_qty                -- w}
, actual_qty                      -- ÀÑ
, delivery_location               -- [iê
, delivery_location_name          -- [iê¼Ì
, move_location                   -- Ú®ê
, move_location_name              -- Ú®ê¼Ì
, wip_whse_code                   -- WIPqÉR[h
, send_class                      -- Mæª
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
)
AS
  SELECT
    gbh.rowid                                                     row_id
  , gbh.attribute4                                                duty_status                     -- Æ±Xe[^X
  , xlvv_status.meaning                                           duty_status_name                -- Æ±Xe[^X(¼Ì)
  , DECODE( gbh.attribute4
          , '-1', '99'
          , gbh.attribute4 )
                                                                  duty_status_order               -- Æ±Xe[^X(\[gp)
  , gbh.batch_id                                                  batch_id                        -- ob`ID
  , gbh.batch_no                                                  batch_no                        -- ob`No
  , gmd.material_detail_id                                        material_detail_id              -- ¶Y´¿Ú×ID
  , itp.trans_id                                                  trans_id                        -- Û¯ÝÉgUNVID
  , xim2v.item_id                                                 item_id                         -- iÚID
  , xim2v.item_no                                                 item_no                         -- iÚR[h
  , xim2v.item_short_name                                         item_short_name                 -- iÚ(ªÌ)
  , ilm.lot_id                                                    lot_id                          -- bgID
  , ilm.lot_no                                                    lot_no                          -- bgNo
  , grv.routing_id                                                routing_id                      -- HID
  , grv.routing_no                                                routing_no                      -- HNo
  , grv.attribute1                                                routing_name                    -- C¼EªÌ
  , grv.attribute13                                               slip_type                       -- `[æª
  , xlvv_l03.meaning                                              slip_type_name                  -- `[æª(¼Ì)
  , grv.attribute15                                               in_out_type                     -- àOæª
  , gbh.plan_start_date                                           product_plan_date               -- ¶Y\èú
  , FND_DATE.STRING_TO_DATE( gmd.attribute22, 'RRRR/MM/DD' )      store_plan_date                 -- ´¿üÉ\èú
  , FND_DATE.STRING_TO_DATE( gmd.attribute11, 'RRRR/MM/DD' )      product_date                    -- ¶Yú
  , FND_DATE.STRING_TO_DATE( gmd.attribute17, 'RRRR/MM/DD' )      maker_date                      -- »¢ú
  , FND_DATE.STRING_TO_DATE( gmd.attribute10, 'RRRR/MM/DD' )      use_by_date                     -- Ü¡úÀú
  , xxcmn_common_pkg.rcv_ship_conv_qty(
      '2', xim2v.item_id, TO_NUMBER( gmd.attribute7 ) )           request_qty                     -- Ë
  , xxcmn_common_pkg.rcv_ship_conv_qty(
      '2', xim2v.item_id, TO_NUMBER( gmd.attribute23 ) )          instructions_qty                -- w}
  , xxcmn_common_pkg.rcv_ship_conv_qty(
      '2', xim2v.item_id, gmd.actual_qty )                        actual_qty                      -- ÀÑ
  , grv.attribute9                                                delivery_location               -- [iê
  , xilv_deli.description                                         delivery_location_name          -- [iê¼Ì
  , gmd.attribute12                                               move_location                   -- Ú®ê
  , xilv_move.description                                         move_location_name              -- Ú®ê¼Ì
  , gbh.wip_whse_code                                             wip_whse_code                   -- WIPqÉR[h
  , gbh.attribute3                                                send_class                      -- Mæª
  , gbh.created_by                                                created_by
  , gbh.creation_date                                             creation_date
  , gbh.last_updated_by                                           last_updated_by
  , gbh.last_update_date                                          last_update_date
  , gbh.last_update_login                                         last_update_login
  FROM
    xxcmn_lookup_values_v           xlvv_status   -- Æ±Xe[^X
  , xxcmn_lookup_values_v           xlvv_l03      -- `[æª
  , xxcmn_item_locations_v          xilv_deli     -- ÛÇê}X^([iê)
  , xxcmn_item_locations_v          xilv_move     -- ÛÇê}X^(Ú®ê)
  , gmd_routings_vl                 grv           -- H}X^
  , xxcmn_item_mst2_v               xim2v         -- OPMiÚVIEW
  , ic_lots_mst                     ilm           -- OPMbg
  , ic_tran_pnd                     itp           -- OPMÛ¯ÝÉgUNV
  , gme_material_details            gmd           -- ¶Y´¿Ú×
  , gme_batch_header                gbh           -- ¶Yob`wb_
  WHERE
        xlvv_status.lookup_code (+) = gbh.attribute4
    AND xlvv_status.lookup_type (+) = 'XXWIP_DUTY_STATUS'
    AND xlvv_l03.lookup_code    (+) = grv.attribute13
    AND xlvv_l03.lookup_type    (+) = 'XXCMN_L03'
    AND xilv_deli.segment1      (+) = grv.attribute9
    AND grv.routing_id              = gbh.routing_id
    AND xim2v.item_id           (+) = gmd.item_id
    AND xim2v.start_date_active     <= TRUNC( gbh.plan_start_date )
    AND xim2v.end_date_active       >= TRUNC( gbh.plan_start_date )
    AND xilv_move.segment1      (+) = gmd.attribute12
    AND ilm.lot_id              (+) = itp.lot_id
    AND ilm.item_id             (+) = itp.item_id
-- 2009/01/15 D.Nihei Mod Start {ÔáQ#836PvÎU
--    AND itp.reverse_id           IS NULL
    AND itp.reverse_id          (+) IS NULL
-- 2009/01/15 D.Nihei Mod End
    AND itp.delete_mark         (+) = 0
    AND itp.lot_id              (+) > 0
    AND itp.line_id             (+) = gmd.material_detail_id
-- 2008/09/08 D.Nihei Add Start ¡\¦Î
    AND itp.doc_type            (+) = 'PROD'
-- 2008/09/08 D.Nihei Add End
    AND gbh.attribute4              IS NOT NULL
    AND gmd.line_type               = 1
    AND gmd.batch_id                = gbh.batch_id
/
