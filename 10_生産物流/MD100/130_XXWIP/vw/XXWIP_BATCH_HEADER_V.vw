CREATE OR REPLACE VIEW apps.xxwip_batch_header_v
(
  row_id
, duty_status                     -- 業務ステータス
, duty_status_name                -- 業務ステータス(名称)
, batch_id                        -- バッチID
, batch_no                        -- バッチNo
, plant_code                      -- プラントコード
, recipe_validity_rule_id         -- 妥当性ルールID
, material_detail_id              -- 生産原料詳細ID
, formulaline_id                  -- フォーミュラ明細ID
, trans_id                        -- 保留在庫トランザクションID
, item_id                         -- 品目ID
, item_no                         -- 品目コード
, item_short_name                 -- 品目(略称)
, item_class_code                 -- 品目区分
, item_class_name                 -- 品目区分(名称)
, lot_id                          -- ロットID
, lot_no                          -- ロットNo
, routing_id                      -- 工順ID
, routing_no                      -- 工順No
, routing_name                    -- ライン名・略称
, shinkansen_type                 -- 新缶煎区分
, unique_sign                     -- 固有記号
, destination_div                 -- 仕向区分
, slip_type                       -- 伝票区分
, slip_type_name                  -- 伝票区分(名称)
, in_out_type                     -- 内外区分
, item_um                         -- 単位
, product_plan_date               -- 生産予定日
, store_plan_date                 -- 原料入庫予定日
, request_qty                     -- 依頼総数
, instructions_qty                -- 指図総数
, delivery_location_id            -- 納品場所ID
, delivery_location               -- 納品場所
, delivery_location_name          -- 納品場所名称
, move_location_id                -- 移動場所ID
, move_location                   -- 移動場所
, move_location_name              -- 移動場所名称
, material_type                   -- タイプ
, material_type_name              -- タイプ(名称)
, rank1                           -- ランク1
, rank2                           -- ランク2
, wip_whse_code                   -- WIP倉庫コード
, send_class                      -- 送信区分
, result_management_post          -- 成績管理部署
, result_management_post_name     -- 成績管理部署(名称)
, remarks_column                  -- 摘要
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
, detail_last_update_date
)
AS
  SELECT
    gbh.rowid                                     row_id
  , gbh.attribute4                                duty_status                     -- 業務ステータス
  , xlvv_status.meaning                           duty_status_name                -- 業務ステータス(名称)
  , gbh.batch_id                                  batch_id                        -- バッチID
  , gbh.batch_no                                  batch_no                        -- バッチNo
  , gbh.plant_code                                plant_code                      -- プラントコード
  , gbh.recipe_validity_rule_id                   recipe_validity_rule_id         -- 妥当性ルールID
  , gmd.material_detail_id                        material_detail_id              -- 生産原料詳細ID
  , gmd.formulaline_id                            formulaline_id                  -- フォーミュラ明細ID
  , itp.trans_id                                  trans_id                        -- 保留在庫トランザクションID
  , xim2v.item_id                                 item_id                         -- 品目ID
  , xim2v.item_no                                 item_no                         -- 品目コード
  , xim2v.item_short_name                         item_short_name                 -- 品目(略称)
  , xic5v.item_class_code                         item_class_code                 -- 品目区分
  , xic5v.item_class_name                         item_class_name                 -- 品目区分(名称)
  , ilm.lot_id                                    lot_id                          -- ロットID
  , ilm.lot_no                                    lot_no                          -- ロットNo
  , grv.routing_id                                routing_id                      -- 工順ID
  , grv.routing_no                                routing_no                      -- 工順No
  , grv.attribute1                                routing_name                    -- ライン名・略称
  , grv.attribute17                               shinkansen_type                 -- 新缶煎区分
  , grv.attribute19                               unique_sign                     -- 固有記号
  , xim2v.destination_div                         destination_div                 -- 仕向区分
  , grv.attribute13                               slip_type                       -- 伝票区分
  , xlvv_l03.meaning                              slip_type_name                  -- 伝票区分(名称)
  , grv.attribute15                               in_out_type                     -- 内外区分
  , CASE
      WHEN ( ( grv.attribute16 = '3' ) AND ( xic5v.item_class_code = '5' ) )
        THEN xim2v.conv_unit
        ELSE xim2v.item_um
    END                                           item_um                         -- 単位
  , gbh.plan_start_date                           product_plan_date               -- 生産予定日
  , FND_DATE.STRING_TO_DATE(
      gmd.attribute22, 'RRRR/MM/DD' )             store_plan_date                 -- 原料入庫予定日
  , xxcmn_common_pkg.rcv_ship_conv_qty(
      '2', xim2v.item_id, TO_NUMBER( gmd.attribute7 ) )
                                                  request_qty                     -- 依頼総数
  , xxcmn_common_pkg.rcv_ship_conv_qty(
      '2', xim2v.item_id, TO_NUMBER( gmd.attribute23 ) )
                                                  instructions_qty                -- 指図総数
  , xilv_deli.inventory_location_id               delivery_location_id            -- 納品場所ID
  , grv.attribute9                                delivery_location               -- 納品場所
  , xilv_deli.description                         delivery_location_name          -- 納品場所(名称)
  , xilv_move.inventory_location_id               move_location_id                -- 移動場所ID
  , gmd.attribute12                               move_location                   -- 移動場所
  , xilv_move.description                         move_location_name              -- 移動場所(名称)
  , gmd.attribute1                                material_type                   -- タイプ
  , xlvv_l08.meaning                              material_type_name              -- タイプ(名称)
  , gmd.attribute2                                rank1                           -- ランク1
  , gmd.attribute3                                rank2                           -- ランク2
  , gbh.wip_whse_code                             wip_whse_code                   -- WIP倉庫コード
  , gbh.attribute3                                send_class                      -- 送信区分
  , grv.attribute14                               result_management_post          -- 成績管理部署
  , xlvv_l10.meaning                              result_management_post_name     -- 成績管理部署(名称)
  , gmd.attribute4                                remarks_column                  -- 摘要
  , gbh.created_by                                created_by
  , gbh.creation_date                             creation_date
  , gbh.last_updated_by                           last_updated_by
  , gbh.last_update_date                          last_update_date
  , gbh.last_update_login                         last_update_login
  , gmd.last_update_date                          detail_last_update_date
  FROM
    xxcmn_lookup_values_v           xlvv_status   -- 業務ステータス
  , xxcmn_lookup_values_v           xlvv_l10      -- 成績管理部署
  , xxcmn_lookup_values_v           xlvv_l08      -- タイプ
  , xxcmn_lookup_values_v           xlvv_l03      -- 伝票区分
  , xxcmn_item_categories5_v        xic5v         -- カテゴリVIEW5
  , xxcmn_item_locations_v          xilv_deli     -- 保管場所マスタVIEW(納品場所)
  , xxcmn_item_locations_v          xilv_move     -- 保管場所マスタVIEW(移動場所)
  , gmd_routings_vl                 grv           -- 工順マスタVIEW
  , xxcmn_item_mst2_v               xim2v         -- OPM品目VIEW
  , ic_lots_mst                     ilm           -- OPMロット
  , ic_tran_pnd                     itp           -- OPM保留在庫トランザクション
  , gme_material_details            gmd           -- 生産原料詳細
  , gme_batch_header                gbh           -- 生産バッチヘッダ
  WHERE
        xlvv_status.lookup_code (+) = gbh.attribute4
    AND xlvv_status.lookup_type (+) = 'XXWIP_DUTY_STATUS'
    AND xlvv_l10.lookup_code    (+) = grv.attribute14
    AND xlvv_l10.lookup_type    (+) = 'XXCMN_L10'
    AND xlvv_l08.lookup_code    (+) = gmd.attribute1
    AND xlvv_l08.lookup_type    (+) = 'XXCMN_L08'
    AND xlvv_l03.lookup_code    (+) = grv.attribute13
    AND xlvv_l03.lookup_type    (+) = 'XXCMN_L03'
    AND xic5v.item_id           (+) = gmd.item_id
    AND xilv_deli.segment1      (+) = grv.attribute9
    AND grv.routing_id              = gbh.routing_id
    AND xim2v.item_id           (+) = gmd.item_id
    AND xim2v.start_date_active     <= TRUNC( gbh.plan_start_date )
    AND xim2v.end_date_active       >= TRUNC( gbh.plan_start_date )
    AND xilv_move.segment1      (+) = gmd.attribute12
    AND ilm.lot_id              (+) = itp.lot_id
    AND ilm.item_id             (+) = itp.item_id
    AND itp.reverse_id              IS NULL
    AND itp.delete_mark         (+) = 0
    AND itp.lot_id              (+) > 0
    AND itp.line_id             (+) = gmd.material_detail_id
-- 2008/09/08 D.Nihei Add Start 複数件表示対応
    AND itp.doc_type            (+) = 'PROD'
-- 2008/09/08 D.Nihei Add End
    AND gmd.line_type               = 1
    AND gmd.batch_id                = gbh.batch_id
/
