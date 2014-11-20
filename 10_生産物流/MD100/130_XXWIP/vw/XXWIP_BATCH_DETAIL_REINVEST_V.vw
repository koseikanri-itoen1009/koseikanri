CREATE OR REPLACE VIEW apps.xxwip_batch_detail_reinvest_v
(
  row_id
, batch_id               -- バッチID
, material_detail_id     -- 生産原料詳細ID
, line_no                -- 行番号
, item_id                -- 品目ID
, item_no                -- 品目コード
, item_short_name        -- 品目(略称)
, item_um                -- 単位
, original_qty           -- 計画数
, request_qty_all        -- 依頼総数
, instructions_qty_all   -- 指示総数
, out_whse_1             -- 出倉庫1
, out_whse_2             -- 出倉庫2
, out_whse_3             -- 出倉庫3
, out_whse_4             -- 出倉庫4
, out_whse_5             -- 出倉庫5
, comments               -- コメント
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
)
AS
  SELECT
    gmd.rowid                       row_id
  , gbh.batch_id                    batch_id               -- バッチID
  , gmd.material_detail_id          material_detail_id     -- 生産原料詳細ID
  , gmd.line_no                     line_no                -- 行番号
  , xim2v.item_id                   item_id                -- 品目ID
  , xim2v.item_no                   item_no                -- 品目コード
  , xim2v.item_short_name           item_short_name        -- 品目(略称)
  , xim2v.item_um                   item_um                -- 単位
-- 2009/01/20 D.Nihei Mod Start
--  , gmd.original_qty                original_qty           -- 計画数
  , NVL(gmd.attribute25, gmd.original_qty)
                                    original_qty           -- 計画数
-- 2009/01/20 D.Nihei Mod End
-- 2009/03/06 D.Nihei Mod Start 本番障害#1278
--  , TO_NUMBER( gmd.attribute7 )     request_qty_all        -- 依頼総数
  , NVL(TO_NUMBER( gmd.attribute7 ), 0)
                                    request_qty_all        -- 依頼総数
-- 2009/03/06 D.Nihei Mod End
  , NVL( xmd_sq.instructions_qty, 0 )
                                    instructions_qty_all   -- 指示総数
  , gmd.attribute13                 out_whse_1             -- 出倉庫1
  , gmd.attribute18                 out_whse_2             -- 出倉庫2
  , gmd.attribute19                 out_whse_3             -- 出倉庫3
  , gmd.attribute20                 out_whse_4             -- 出倉庫4
  , gmd.attribute21                 out_whse_5             -- 出倉庫5
  , DECODE( xmd_sq.location_count
          , NULL, '引当てられていません'
          , 0, '引当てられていません'
          , 1, '単一倉庫で引当されています'
          , '複数倉庫で引当されています' )
                                    comments               -- コメント
  , gmd.created_by
  , gmd.creation_date
  , gmd.last_updated_by
  , gmd.last_update_date
  , gmd.last_update_login
  FROM
    xxcmn_item_locations_v          xilv          -- 保管倉庫(納品場所)
  , gmd_routings_vl                 grv           -- 工順マスタVIEW
  , xxcmn_item_mst2_v               xim2v         -- OPM品目VIEW
  , gme_batch_header                gbh           -- 生産バッチヘッダ
  , gme_material_details            gmd           -- 生産原料詳細
  , (
      SELECT
        SUM( xmd.instructions_qty )     instructions_qty
      , COUNT( DISTINCT xmd.location_code )
                                        location_count
      , xmd.batch_id                    batch_id
      , xmd.material_detail_id          material_detail_id
      FROM
        xxwip_material_detail           xmd     -- 生産原料詳細アドオン
      WHERE
            xmd.plan_type IN ( '1', '2', '3' )
-- 2009/03/06 D.Nihei Add Start 本番障害#1280
      AND   EXISTS(SELECT 1
                   FROM   xxwip_material_detail xmdd
                   WHERE  xmdd.material_detail_id = xmd.material_detail_id
                   AND    xmdd.plan_type          = '4'
                   AND    ROWNUM                  = 1)
-- 2009/03/06 D.Nihei Add End
      GROUP BY
        batch_id
      , material_detail_id
    ) xmd_sq
  WHERE
        xilv.segment1              (+) = grv.attribute9
    AND grv.routing_id                 = gbh.routing_id
    AND xim2v.item_id                  = gmd.item_id
    AND xim2v.start_date_active        <= TRUNC( gbh.plan_start_date )
    AND xim2v.end_date_active          >= TRUNC( gbh.plan_start_date )
    AND gbh.batch_id                   = gmd.batch_id
    AND xmd_sq.batch_id            (+) = gmd.batch_id
    AND xmd_sq.material_detail_id  (+) = gmd.material_detail_id
    AND gmd.line_type                  = -1                           -- 投入品
    AND gmd.attribute5                 = 'Y'                          -- 打込
    AND gmd.attribute24                IS NULL
/
