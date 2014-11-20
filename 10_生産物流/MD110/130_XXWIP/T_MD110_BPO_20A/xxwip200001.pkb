CREATE OR REPLACE PACKAGE BODY xxwip200001
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwip200001(BODY)
 * Description            : 生産バッチロット詳細画面データソースパッケージ(SPEC)
 * MD.050                 : T_MD050_BPO_200_生産バッチ.doc
 * MD.070                 : T_MD070_BPO_20A_生産バッチ一覧画面.doc
 * Version                : 1.0
 *
 * Program List
 *  --------------------  ---- ----- -------------------------------------------------
 *   Name                 Type  Ret   Description
 *  --------------------  ---- ----- -------------------------------------------------
 *  blk_ilm_qry             P    -    データ取得
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/08/28   1.0   D.Nihei          新規作成
 *
 *****************************************************************************************/
--
  -- 定数宣言
  cv_status_normal        CONSTANT VARCHAR2(1)  := '0';
  cv_status_warning       CONSTANT VARCHAR2(1)  := '1';
  cv_status_error         CONSTANT VARCHAR2(1)  := '2';
  cv_shizai               CONSTANT VARCHAR2(1)  := '2';
--
  /***********************************************************************************
   * Procedure Name   : blk_ilm_qry
   * Description      : データ取得(REFカーソルオープン)
   ***********************************************************************************/
  PROCEDURE blk_ilm_qry(
    ior_ilm_data            IN OUT NOCOPY tbl_ilm_block
  , in_material_detail_id   IN gme_material_details.material_detail_id%TYPE   -- 生産原料詳細ID
  , id_material_date        IN DATE                                           -- 原料入庫予定日
  )
  IS
--
    -- 変数宣言
    lt_item_class_code       xxcmn_item_categories5_v.item_class_code%TYPE;       -- 品目区分
    lt_prod_class_code       xxcmn_item_categories5_v.prod_class_code%TYPE;       -- 商品区分
    lt_location1             xxcmn_item_locations_v.segment1%TYPE;                -- 出庫倉庫1
    lt_location2             xxcmn_item_locations_v.segment1%TYPE;                -- 出庫倉庫2
    lt_location3             xxcmn_item_locations_v.segment1%TYPE;                -- 出庫倉庫3
    lt_location4             xxcmn_item_locations_v.segment1%TYPE;                -- 出庫倉庫4
    lt_location5             xxcmn_item_locations_v.segment1%TYPE;                -- 出庫倉庫5
    lt_item_id               xxcmn_item_mst_v.item_id%TYPE;                       -- 品目ID
    lt_item_no               xxcmn_item_mst_v.item_no%TYPE;                       -- 品目No
    wk_sql                   VARCHAR2(15000);
    lt_batch_id              gme_batch_header.batch_id%TYPE;                      -- バッチID
--
  BEGIN
--
    BEGIN
      --==========================
      -- 対象倉庫情報取得
      --==========================
      SELECT gmd.batch_id
           , gmd.item_id
           , gmd.attribute13
           , gmd.attribute18
           , gmd.attribute19
           , gmd.attribute20
           , gmd.attribute21
      INTO   lt_batch_id
           , lt_item_id
           , lt_location1
           , lt_location2
           , lt_location3
           , lt_location4
           , lt_location5
      FROM   gme_material_details gmd -- 生産原料詳細
      WHERE  gmd.material_detail_id = in_material_detail_id
      ;
--
      --==========================
      -- 品目区分、商品区分取得
      --==========================
      SELECT ximv.item_no          item_no
           , xicv.item_class_code  item_class_code
           , xicv.prod_class_code  prod_class_code
      INTO   lt_item_no
           , lt_item_class_code
           , lt_prod_class_code
      FROM   xxcmn_item_mst_v         ximv  -- OPM品目マスタVIEW2
           , xxcmn_item_categories5_v xicv  -- 品目カテゴリ情報VIEW5
      WHERE  ximv.item_id = xicv.item_id
      AND    xicv.item_id = lt_item_id
      ;
--
      --==========================
      -- 動的SQL作成
      --==========================
      wk_sql := NULL;
      wk_sql := wk_sql || 'SELECT  enable_lot.inventory_location_id      storehouse_id            '; -- 保管倉庫ID
      wk_sql := wk_sql || '      , enable_lot.storehouse_code            storehouse_code          '; -- 保管倉庫(コード)
      wk_sql := wk_sql || '      , enable_lot.description                storehouse_name          '; -- 保管倉庫(名称)
      wk_sql := wk_sql || '      , ' || lt_batch_id || '                 batch_id                 '; -- バッチID
      wk_sql := wk_sql || '      , ' || in_material_detail_id || '       material_detail_id       '; -- 生産原料詳細ID
      wk_sql := wk_sql || '      , enable_lot.mtl_detail_addon_id        mtl_detail_addon_id      '; -- 生産原料詳細アドオンID
      wk_sql := wk_sql || '      , enable_lot.mov_lot_dtl_id             mov_lot_dtl_id           '; -- 移動ロット詳細ID
      wk_sql := wk_sql || '      , NULL                                  trans_id                 '; -- 
      wk_sql := wk_sql || '      , enable_lot.item_id                    item_id                  '; -- 品目ID
      wk_sql := wk_sql || '      , ''' || lt_item_no || '''              item_no                  '; -- 品目(コード)
      wk_sql := wk_sql || '      , enable_lot.lot_id                     lot_id                   '; -- ロットID
      --==========================
      -- 資材
      --==========================
      IF ( lt_item_class_code = cv_shizai ) 
      THEN
        wk_sql := wk_sql || '    , NULL ';
      --==========================
      -- 資材以外
      --==========================
      ELSE
        wk_sql := wk_sql || '    , ilm.lot_no ';
      END IF;
      wk_sql := wk_sql || '                                              lot_no                   '; -- ロットNo
      wk_sql := wk_sql || '      , ilm.attribute24                       lot_create_type          '; -- 作成区分
      wk_sql := wk_sql || '      , enable_lot.instructions_qty           instructions_qty         '; -- 指示総数
      wk_sql := wk_sql || '      , enable_lot.instructions_qty           instructions_qty_orig    '; -- 元指示総数
      --==========================
      -- 資材
      --==========================
      IF ( lt_item_class_code = cv_shizai ) 
      THEN
        wk_sql := wk_sql || '      , xxcmn_common_pkg.get_stock_qty(enable_lot.inventory_location_id, enable_lot.item_id, NULL ) ';
      --==========================
      -- 資材以外
      --==========================
      ELSE
        wk_sql := wk_sql || '      , xxcmn_common_pkg.get_stock_qty(enable_lot.inventory_location_id, enable_lot.item_id, enable_lot.lot_id ) ';
      END IF;
      wk_sql := wk_sql || '                                              stock_qty                '; -- 在庫総数
      wk_sql := wk_sql || '      , enable_lot.enabled_qty                enabled_qty              '; -- 可能数
      wk_sql := wk_sql || '      , TO_NUMBER( DECODE( ilm.attribute6, ''0'', NULL, ilm.attribute6 ))';
      wk_sql := wk_sql || '                                              entity_inner             '; -- 在庫入数
      wk_sql := wk_sql || '      , TO_NUMBER( ilm.attribute7 )           unit_price               '; -- 単価
      wk_sql := wk_sql || '      , ilm.attribute8                        orgn_code                '; -- 取引先コード
      wk_sql := wk_sql || '      , (SELECT xvv.vendor_short_name ';
      wk_sql := wk_sql || '         FROM   xxcmn_vendors2_v xvv  ';  -- 仕入先情報VIEW
      wk_sql := wk_sql || '         WHERE  xvv.segment1           = ilm.attribute8 ';
      wk_sql := wk_sql || '         AND    xvv.start_date_active <= trunc( TO_DATE(''' || id_material_date || ''')) ';
      wk_sql := wk_sql || '         AND    xvv.end_date_active   >= trunc( TO_DATE(''' || id_material_date || ''')) ';
      wk_sql := wk_sql || '        )                                     orgn_name                '; -- 取引先名称
      wk_sql := wk_sql || '      , (SELECT xlvv_l05.meaning ';
      wk_sql := wk_sql || '         FROM   xxcmn_lookup_values_v xlvv_l05 ';
      wk_sql := wk_sql || '         WHERE  xlvv_l05.lookup_code = ilm.attribute9  ';
      wk_sql := wk_sql || '         AND    xlvv_l05.lookup_type = ''XXCMN_L05''   ';
      wk_sql := wk_sql || '        )                                     stocking_form            '; -- 仕入形態
      wk_sql := wk_sql || '      , (SELECT xlvv_l06.meaning ';
      wk_sql := wk_sql || '         FROM   xxcmn_lookup_values_v xlvv_l06 ';
      wk_sql := wk_sql || '         WHERE  xlvv_l06.lookup_code = ilm.attribute10 ';
      wk_sql := wk_sql || '         AND    xlvv_l06.lookup_type = ''XXCMN_L06''   ';
      wk_sql := wk_sql || '        )                                     tea_season_type          '; -- 茶期区分
      wk_sql := wk_sql || '      , ilm.attribute11                       period_of_year           '; -- 年度
      wk_sql := wk_sql || '      , (SELECT xlvv_l07.meaning ';
      wk_sql := wk_sql || '         FROM   xxcmn_lookup_values_v xlvv_l07 ';
      wk_sql := wk_sql || '         WHERE  xlvv_l07.lookup_code = ilm.attribute12 ';
      wk_sql := wk_sql || '         AND    xlvv_l07.lookup_type = ''XXCMN_L07''   ';
      wk_sql := wk_sql || '        )                                     producing_area           '; -- 産地
      wk_sql := wk_sql || '      , (SELECT xlvv_l08.meaning ';
      wk_sql := wk_sql || '         FROM   xxcmn_lookup_values_v xlvv_l08  ';
      wk_sql := wk_sql || '         WHERE  xlvv_l08.lookup_code = ilm.attribute13 ';
      wk_sql := wk_sql || '         AND    xlvv_l08.lookup_type = ''XXCMN_L08''   ';
      wk_sql := wk_sql || '        )                                     package_type             '; -- タイプ
      wk_sql := wk_sql || '      , ilm.attribute14                       rank1                    '; -- R1
      wk_sql := wk_sql || '      , ilm.attribute15                       rank2                    '; -- R2
      wk_sql := wk_sql || '      , ilm.attribute19                       rank3                    '; -- R3
      wk_sql := wk_sql || '      , ilm.attribute1                        maker_date               '; -- 製造日
      wk_sql := wk_sql || '      , ilm.attribute3                        use_by_date              '; -- 賞味期限日
      wk_sql := wk_sql || '      , ilm.attribute2                        unique_sign              '; -- 固有記号
      wk_sql := wk_sql || '      , ilm.attribute4                        dely_date                '; -- 納入日（初回）
      wk_sql := wk_sql || '      , (SELECT xlvv_l03.meaning ';
      wk_sql := wk_sql || '         FROM   xxcmn_lookup_values_v xlvv_l03  ';
      wk_sql := wk_sql || '         WHERE  xlvv_l03.lookup_code = ilm.attribute16 ';
      wk_sql := wk_sql || '         AND    xlvv_l03.lookup_type = ''XXCMN_L03''   ';
      wk_sql := wk_sql || '        )                                     slip_type_name           '; -- 伝票区分(名称)
      wk_sql := wk_sql || '      , ilm.attribute17                       routing_no               '; -- ラインNo
      wk_sql := wk_sql || '      , (SELECT grv.attribute1     ';
      wk_sql := wk_sql || '         FROM   gmd_routings_b grv '; -- 工順マスタVIEW
      wk_sql := wk_sql || '         WHERE  grv.routing_no = ilm.attribute17 ';
      wk_sql := wk_sql || '        )                                     routing_name             '; -- ライン名称
      wk_sql := wk_sql || '      , ilm.attribute18                       remarks_column           '; -- 摘要
      wk_sql := wk_sql || '      , enable_lot.record_type                record_type              ';
      wk_sql := wk_sql || '      , ilm.created_by                        created_by               ';
      wk_sql := wk_sql || '      , ilm.creation_date                     creation_date            ';
      wk_sql := wk_sql || '      , ilm.last_updated_by                   last_updated_by          ';
      wk_sql := wk_sql || '      , ilm.last_update_date                  last_update_date         ';
      wk_sql := wk_sql || '      , ilm.last_update_login                 last_update_login        ';
      wk_sql := wk_sql || '      , enable_lot.xmd_last_update_date       xmd_last_update_date     ';
      wk_sql := wk_sql || '      , NVL(enable_lot.whse_inside_outside_div, ''2'')  ';
      wk_sql := wk_sql || '                                              whse_inside_outside_div  '; -- 内外倉庫区分
      wk_sql := wk_sql || '      FROM ';
      wk_sql := wk_sql || '        ic_lots_mst ilm '; -- OPMロット
      wk_sql := wk_sql || '      , ( SELECT 1                               record_type             ';       -- 更新
      wk_sql := wk_sql || '               , xmd.mtl_detail_addon_id         mtl_detail_addon_id     ';       -- 生産原料詳細アドオンID
      wk_sql := wk_sql || '               , xmd.item_id                     item_id                 ';       -- 品目ID
      wk_sql := wk_sql || '               , xmd.lot_id                      lot_id                  ';       -- ロットID
      wk_sql := wk_sql || '               , xmd.location_code               storehouse_code         ';       -- 保管場所コード
      wk_sql := wk_sql || '               , xmd.instructions_qty            instructions_qty        ';       -- 指示総数
      --==========================
      -- 資材
      --==========================
      IF ( lt_item_class_code = cv_shizai ) 
      THEN
        wk_sql := wk_sql || '             , xxcmn_common_pkg.get_can_enc_qty( xilv.inventory_location_id, xmd.item_id, NULL, TO_DATE(''' || id_material_date || ''') )   enabled_qty ';
      --==========================
      -- 資材以外
      --==========================
      ELSE
        wk_sql := wk_sql || '             , xxcmn_common_pkg.get_can_enc_qty( xilv.inventory_location_id, xmd.item_id, xmd.lot_id, TO_DATE(''' || id_material_date || ''') )   enabled_qty ';
      END IF;
      wk_sql := wk_sql || '               , xmd.last_update_date            xmd_last_update_date     '; -- 最終更新日(排他制御用)
      wk_sql := wk_sql || '               , xmld.mov_lot_dtl_id             mov_lot_dtl_id           '; -- 移動ロット詳細ID
      wk_sql := wk_sql || '               , xilv.inventory_location_id      inventory_location_id    '; -- 保管倉庫ID
      wk_sql := wk_sql || '               , xilv.description                description              '; -- 保管倉庫(名称)
      wk_sql := wk_sql || '               , xilv.whse_inside_outside_div    whse_inside_outside_div  '; -- 内外倉庫区分
      wk_sql := wk_sql || '          FROM   xxwip_material_detail           xmd  '; -- 生産原料詳細アドオン
      wk_sql := wk_sql || '               , xxinv_mov_lot_details           xmld '; -- 移動ロット詳細
      wk_sql := wk_sql || '               , xxcmn_item_locations_v          xilv '; -- 保管倉庫
      wk_sql := wk_sql || '          WHERE  xmd.material_detail_id  = ' || in_material_detail_id;
      wk_sql := wk_sql || '          AND    xmd.plan_type           IN ( ''1'', ''2'', ''3'' )     ';
      wk_sql := wk_sql || '          AND    xilv.segment1           = xmd.location_code ';
      wk_sql := wk_sql || '          AND    xmld.mov_line_id(+)     = xmd.mtl_detail_addon_id ';
      wk_sql := wk_sql || '          AND    xmld.lot_id(+)          = xmd.lot_id ';
      wk_sql := wk_sql || '          UNION ALL ';
      wk_sql := wk_sql || '          SELECT 0                               record_type               '; -- 挿入
      wk_sql := wk_sql || '               , NULL                            mtl_detail_addon_id       '; -- 生産原料詳細アドオンID
      wk_sql := wk_sql || '               , stock.item_id                   item_id                   '; -- 品目ID
      wk_sql := wk_sql || '               , stock.lot_id                    lot_id                    '; -- ロットID
      wk_sql := wk_sql || '               , stock.storehouse_code           storehouse_code           '; -- 保管場所コード
      wk_sql := wk_sql || '               , NULL                            instructions_qty          '; -- 指示総数
      wk_sql := wk_sql || '               , stock.enabled_qty               enabled_qty               '; -- (引当)可能数
      wk_sql := wk_sql || '               , NULL                            xmd_last_update_date      '; -- 最終更新日(排他制御用)
      wk_sql := wk_sql || '               , NULL                            mov_lot_dtl_id            '; -- 移動ロット詳細ID
      wk_sql := wk_sql || '               , stock.inventory_location_id     inventory_location_id     '; -- 保管倉庫ID
      wk_sql := wk_sql || '               , stock.description               description               '; -- 保管倉庫(名称)
      wk_sql := wk_sql || '               , stock.whse_inside_outside_div   whse_inside_outside_div   '; -- 内外倉庫区分
      wk_sql := wk_sql || '          FROM ';
      wk_sql := wk_sql || '            ( ';
      wk_sql := wk_sql || '              SELECT ';
      wk_sql := wk_sql || '                lot.item_id                     item_id ';
      wk_sql := wk_sql || '              , lot.lot_id                      lot_id ';
      wk_sql := wk_sql || '              , xilv.segment1                   storehouse_code ';
      wk_sql := wk_sql || '              , xilv.inventory_location_id      inventory_location_id ';
      --==========================
      -- 資材
      --==========================
      IF ( lt_item_class_code = cv_shizai ) 
      THEN
        wk_sql := wk_sql || '            , xxcmn_common_pkg.get_can_enc_qty( xilv.inventory_location_id, lot.item_id, NULL, TO_DATE(''' || id_material_date || ''') )   enabled_qty ';
      --==========================
      -- 資材以外
      --==========================
      ELSE
        wk_sql := wk_sql || '            , xxcmn_common_pkg.get_can_enc_qty( xilv.inventory_location_id, lot.item_id, lot.lot_id, TO_DATE(''' || id_material_date || ''') )   enabled_qty ';
      END IF;
      wk_sql := wk_sql || '              , xilv.description                description             '; -- 保管倉庫(名称)
      wk_sql := wk_sql || '              , xilv.whse_inside_outside_div    whse_inside_outside_div '; -- 内外倉庫区分
      wk_sql := wk_sql || '              FROM ';
      wk_sql := wk_sql || '                xxcmn_item_locations_v xilv ';   -- 保管倉庫
      wk_sql := wk_sql || '              , ( SELECT  ilm.item_id  item_id ';
      wk_sql := wk_sql || '                        , ilm.lot_id   lot_id  ';
      wk_sql := wk_sql || '                  FROM    ic_lots_mst        ilm     '; -- OPMロットマスタ
      --==========================
      -- 資材
      --==========================
      IF ( lt_item_class_code = cv_shizai ) 
      THEN
        wk_sql := wk_sql || '                WHERE   ilm.item_id = ' || lt_item_id;
      --==========================
      -- 資材以外
      --==========================
      ELSE
        wk_sql := wk_sql || '                      , xxcmn_lot_status_v xlsv '; -- ロットステータス
        wk_sql := wk_sql || '                WHERE   ilm.item_id                  = '   || lt_item_id;
        wk_sql := wk_sql || '                AND     xlsv.prod_class_code         = ''' || lt_prod_class_code || '''';
        wk_sql := wk_sql || '                AND     xlsv.raw_mate_turn_m_reserve = ''Y''           ';
        wk_sql := wk_sql || '                AND     xlsv.lot_status              = ilm.attribute23 ';
      END IF;
      wk_sql := wk_sql || '                ) lot ';
      wk_sql := wk_sql || '              WHERE NOT EXISTS (SELECT 1  ';
      wk_sql := wk_sql || '                                FROM   xxwip_material_detail   xmdd ';     -- 生産原料詳細アドオン
      wk_sql := wk_sql || '                                WHERE  xmdd.material_detail_id  = ' || in_material_detail_id;
      wk_sql := wk_sql || '                                AND    xmdd.plan_type           IN ( ''1'', ''2'', ''3'' )     ';
      wk_sql := wk_sql || '                                AND    xilv.segment1           = xmdd.location_code ';
      wk_sql := wk_sql || '                                AND    lot.lot_id              = xmdd.lot_id ) ';
      --==========================
      -- 検索条件：出倉庫1～5のいずれかが指定されている場合
      --==========================
      IF ( ( lt_location1 IS NOT NULL )
        OR ( lt_location2 IS NOT NULL )
        OR ( lt_location3 IS NOT NULL )
        OR ( lt_location4 IS NOT NULL )
        OR ( lt_location5 IS NOT NULL )
         )
      THEN
        wk_sql := wk_sql || '            AND  xilv.segment1 IN ( ''' || lt_location1 || ''', ''' 
                                                                     || lt_location2 || ''', ''' 
                                                                     || lt_location3 || ''', ''' 
                                                                     || lt_location4 || ''', ''' 
                                                                     || lt_location5 || ''' ) ';
      END IF;
      wk_sql := wk_sql || '            ) stock ';
      wk_sql := wk_sql || '          WHERE  stock.enabled_qty > 0 ';
      wk_sql := wk_sql || '        ) enable_lot ';
      wk_sql := wk_sql || '      WHERE ilm.item_id = enable_lot.item_id ';
      wk_sql := wk_sql || '        AND ilm.lot_id  = enable_lot.lot_id ';
      wk_sql := wk_sql || '      ORDER BY enable_lot.record_type             DESC ';
      wk_sql := wk_sql || '              ,enable_lot.instructions_qty        DESC ';
      wk_sql := wk_sql || '              ,enable_lot.whse_inside_outside_div DESC ';
      wk_sql := wk_sql || '              ,enable_lot.storehouse_code ';
      wk_sql := wk_sql || '              ,TO_NUMBER( lot_no ) ';
--
      EXECUTE IMMEDIATE wk_sql BULK COLLECT INTO ior_ilm_data ;
--
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
--
  END blk_ilm_qry;
--
END xxwip200001;
/
