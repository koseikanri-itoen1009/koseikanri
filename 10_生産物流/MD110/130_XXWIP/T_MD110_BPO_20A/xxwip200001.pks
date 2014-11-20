CREATE OR REPLACE PACKAGE xxwip200001
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwip200001(SPEC)
 * Description            : 生産バッチロット詳細画面データソースパッケージ(SPEC)
 * MD.050                 : T_MD050_BPO_200_生産バッチ.doc
 * MD.070                 : T_MD070_BPO_20A_生産バッチ一覧画面.doc
 * Version                : 1.5
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
 *  2008/10/07   1.1   D.Nihei          統合障害#123対応（PT 6-2_31）
 *  2008/10/22   1.2   D.Nihei          統合障害#123対応（PT 6-2_31）(ロットステータスVIEW箇所修正)
 *  2008/10/29   1.3   D.Nihei          統合障害#481対応（ORDER BY句編集) 
 *  2008/11/19   1.4   D.Nihei          統合障害#681対応（条件追加) 
 *  2008/12/02   1.5   D.Nihei          本番障害#251対応（条件追加) 
*****************************************************************************************/
--
  --#######################  パッケージ変数宣言部 START   #######################
--
  -- 生産バッチロット詳細画面基礎表となるレコード定義
  TYPE rec_ilm_block IS RECORD(
    storehouse_id               xxcmn_item_locations_v.inventory_location_id%TYPE     -- 保管倉庫ID
  , storehouse_code             xxcmn_item_locations_v.segment1%TYPE                  -- 保管倉庫コード
  , storehouse_name             xxcmn_item_locations_v.short_name%TYPE                -- 保管倉庫名称
  , batch_id                    gme_batch_header.batch_id%TYPE                        -- バッチID
  , material_detail_id          gme_material_details.material_detail_id%TYPE          -- 生産原料詳細ID
  , mtl_detail_addon_id         xxwip_material_detail.mtl_detail_addon_id%TYPE        -- 生産原料詳細アドオンID
  , mov_lot_dtl_id              xxinv_mov_lot_details.mov_lot_dtl_id%TYPE             -- ロット詳細ID
  , trans_id                    ic_tran_pnd.trans_id%TYPE                             -- トランザクションID
  , item_id                     xxcmn_item_mst_v.item_id%TYPE                         -- 品目ID
  , item_no                     xxcmn_item_mst_v.item_no%TYPE                         -- 品目コード
  , lot_id                      ic_lots_mst.lot_id%TYPE                               -- ロットID
  , lot_no                      ic_lots_mst.lot_no%TYPE                               -- ロットNo
  , lot_create_type             ic_lots_mst.attribute24%TYPE                          -- 作成区分
  , instructions_qty            xxwip_material_detail.instructions_qty%TYPE           -- 指示総数
  , instructions_qty_orig       xxwip_material_detail.instructions_qty%TYPE           -- 元指示総数
  , stock_qty                   NUMBER                                                -- 在庫総数
-- 2008/10/07 D.Nihei ADD START
  , inbound_qty                 NUMBER                                                -- 入庫予定数
  , outbound_qty                NUMBER                                                -- 出庫予定数
-- 2008/10/07 D.Nihei ADD END
  , enabled_qty                 NUMBER                                                -- 可能数
  , entity_inner                NUMBER                                                -- 在庫入数
  , unit_price                  NUMBER                                                -- 単価
  , orgn_code                   xxcmn_vendors_v.segment1%TYPE                         -- 取引先コード
  , orgn_name                   xxcmn_vendors_v.vendor_short_name%TYPE                -- 取引先名称
  , stocking_form               xxcmn_lookup_values_v.meaning%TYPE                    -- 仕入形態
  , tea_season_type             xxcmn_lookup_values_v.meaning%TYPE                    -- 茶期区分
  , period_of_year              ic_lots_mst.attribute11%TYPE                          -- 年度
  , producing_area              xxcmn_lookup_values_v.meaning%TYPE                    -- 産地
  , package_type                xxcmn_lookup_values_v.meaning%TYPE                    -- タイプ
  , rank1                       ic_lots_mst.attribute14%TYPE                          -- R1
  , rank2                       ic_lots_mst.attribute15%TYPE                          -- R2
  , rank3                       ic_lots_mst.attribute19%TYPE                          -- R3
  , maker_date                  ic_lots_mst.attribute1%TYPE                           -- 製造日
  , use_by_date                 ic_lots_mst.attribute3%TYPE                           -- 賞味期限日
  , unique_sign                 ic_lots_mst.attribute2%TYPE                           -- 固有記号
  , dely_date                   ic_lots_mst.attribute4%TYPE                           -- 納入日（初回）
  , slip_type_name              xxcmn_lookup_values_v.meaning%TYPE                    -- 伝票区分(名称)
  , routing_no                  gmd_routings_vl.routing_no%TYPE                       -- ラインNo
  , routing_name                gmd_routings_vl.attribute1%TYPE                       -- ライン名称
  , remarks_column              ic_lots_mst.attribute18%TYPE                          -- 摘要
  , record_type                 NUMBER                                                -- レコードタイプ
  , created_by                  ic_lots_mst.created_by%TYPE                           -- 作成者(OPMロットマスタ)
  , creation_date               ic_lots_mst.creation_date%TYPE                        -- 作成日(OPMロットマスタ)
  , last_updated_by             ic_lots_mst.last_updated_by%TYPE                      -- 更新者(OPMロットマスタ)
  , last_update_date            ic_lots_mst.last_update_date%TYPE                     -- 更新日(OPMロットマスタ)
  , last_update_login           ic_lots_mst.last_update_login%TYPE                    -- 最終ログイン(OPMロットマスタ)
  , xmd_last_update_date        xxwip_material_detail.last_update_date%TYPE           -- 最終更新日(生産原料詳細アドオン)
  , whse_inside_outside_div     xxcmn_item_locations_v.whse_inside_outside_div%TYPE   -- 内外倉庫区分
  );
--
  -- 生産バッチロット詳細画面基礎表となる索引付きレコード
  TYPE tbl_ilm_block IS TABLE OF rec_ilm_block
  INDEX BY BINARY_INTEGER;
--
  --#######################  パッケージ変数宣言部 END   #######################
--
  --#######################  パッケージプロシージャ宣言部 START   #######################
--
  PROCEDURE blk_ilm_qry(
    ior_ilm_data           IN OUT NOCOPY tbl_ilm_block
  , in_material_detail_id  IN gme_material_details.material_detail_id%TYPE   -- 生産原料詳細ID
  , id_material_date       IN DATE                                           -- 原料入庫予定日
  );
--
  --#######################  パッケージプロシージャ宣言部 END   #######################
--
  --#######################  パッケージファンクション宣言部 START   #######################
--
  --#######################  パッケージファンクション宣言部 END   #######################
--
END xxwip200001;
/
