/************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * View Name       : XXCOI_LOT_TRANS_INFO_V
 * Description     : ロット別取引情報画面ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/11/04    1.0   Y.Umino          新規作成
 *  2015/03/10    1.1   Y.Nagasue        [E_本稼動_12237]倉庫管理システム追加対応
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_lot_trans_info_v
  (  transaction_id                                                   -- 取引ID
   , transaction_set_id                                               -- 取引セットID
   , organization_id                                                  -- 在庫組織ID
   , slip_num                                                         -- 伝票No
   , item_kbn                                                         -- 商品区分
   , item_kbn_name                                                    -- 商品区分名
   , parent_item_id                                                   -- 親品目ID
   , parent_item_cd                                                   -- 親品目コード
   , parent_item_name                                                 -- 親品目名称
   , child_item_id                                                    -- 子品目ID
   , child_item_cd                                                    -- 子品目コード
   , child_item_name                                                  -- 子品目名称
   , lot                                                              -- ロット
   , difference_summary_code                                          -- 固有記号
   , subinventory_code                                                -- 保管場所
   , location_code                                                    -- ロケーションコード
   , location_name                                                    -- ロケーション名称
   , case_in_qty                                                      -- 入数
   , case_qty                                                         -- ケース数
   , singly_qty                                                       -- バラ数
   , summary_qty                                                      -- 数量
   , transaction_date                                                 -- 日付
   , transfer_subinventory                                            -- 転送先保管場所コード
   , transfer_subinventory_name                                       -- 転送先保管場所名称
   , transaction_type_code                                            -- 取引タイプコード
   , transaction_type_name                                            -- 取引タイプ名称
   , status_code                                                      -- ステータス（コード）
   , status_name                                                      -- ステータス（名称）
   , transfer_location_code                                           -- 転送先ロケーションコード
-- 2015/03/10 Add Ver1.1 Y.Nagasue
   , transfer_location_name                                           -- 転送先ロケーション名
-- 2015/03/10 Add Ver1.1 Y.Nagasue
   , sign_div                                                         -- 符号区分
   , source_code                                                      -- ソースコード
   , relation_key                                                     -- 紐付けキー
   , reserve_transaction_type_code                                    -- 引当時取引タイプコード
   , reason                                                           -- 摘要
   , fix_user_code                                                    -- 確定者コード
   , fix_user_name                                                    -- 確定者名
   , created_by                                                       -- 作成者
   , creation_date                                                    -- 作成日
   , last_updated_by                                                  -- 最終更新者
   , last_update_date                                                 -- 最終更新日
   , last_update_login                                                -- 最終更新ログイン
  )
AS
  SELECT
    xltt.transaction_id                          transaction_id                -- 取引ID
   ,xltt.transaction_set_id                      transaction_set_id            -- 取引セットID
   ,xltt.organization_id                         organization_id               -- 在庫組織ID
   ,xltt.slip_num                                slip_num                      -- 伝票No
   ,mcv.segment1                                 item_kbn                      -- 商品区分
   ,mcv.description                              item_kbn_name                 -- 商品区分名
   ,xltt.parent_item_id                          parent_item_id                -- 親品目ID
   ,iimb_oya.item_no                             parent_item_cd                -- 親品目コード
   ,ximb_oya.item_short_name                     parent_item_name              -- 親品目名称
   ,xltt.child_item_id                           child_item_id                 -- 子品目ID
   ,iimb_ko.item_no                              child_item_cd                 -- 子品目コード
   ,ximb_ko.item_short_name                      child_item_name               -- 子品目名称
   ,xltt.lot                                     lot                           -- ロット
   ,xltt.difference_summary_code                 difference_summary_code       -- 固有記号
   ,xltt.subinventory_code                       subinventory_code             -- 保管場所
   ,xltt.location_code                           location_code                 -- ロケーションコード
   ,xmwl.location_name                           location_name                 -- ロケーション名称
   ,xltt.case_in_qty                             case_in_qty                   -- 入数
   ,xltt.case_qty                                case_qty                      -- ケース数
   ,xltt.singly_qty                              singly_qty                    -- バラ数
   ,xltt.summary_qty                             summary_qty                   -- 数量
   ,TO_CHAR(xltt.transaction_date, 'yyyy/mm/dd') transaction_date              -- 日付
   ,xltt.transfer_subinventory                   transfer_subinventory         -- 転送先保管場所コード
   ,(
      CASE
        WHEN ( LENGTHB(xltt.transfer_subinventory) = '4' ) THEN
          ( SELECT mil.attribute12
            FROM mtl_item_locations  mil
            WHERE mil.segment1 = xltt.transfer_subinventory
           )
        ELSE
          ( SELECT msi.description
            FROM mtl_secondary_inventories  msi
            WHERE msi.organization_id = xltt.organization_id
              AND msi.secondary_inventory_name = xltt.transfer_subinventory
           )
      END
     )                                           transfer_subinventory_name    -- 転送先保管場所名称
   ,(
      CASE
        WHEN ( xltt.transaction_type_code = '10' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt1.lookup_code
            FROM fnd_lookup_values  flv_tt1
            WHERE flv_tt1.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt1.lookup_code = '11'
              AND flv_tt1.attribute1 = xltt.transaction_type_code
              AND flv_tt1.enabled_flag = 'Y'
              AND flv_tt1.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt1.start_date_active
                                                     AND     NVL(flv_tt1.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '10' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt2.lookup_code
            FROM fnd_lookup_values  flv_tt2
            WHERE flv_tT2.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt2.lookup_code = '12'
              AND flv_tt2.attribute1 = xltt.transaction_type_code
              AND flv_tt2.enabled_flag = 'Y'
              AND flv_tt2.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt2.start_date_active
                                                     AND     NVL(flv_tt2.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '20' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt3.lookup_code
            FROM fnd_lookup_values  flv_tt3
            WHERE flv_tt3.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt3.lookup_code = '21'
              AND flv_tt3.attribute1 = xltt.transaction_type_code
              AND flv_tt3.enabled_flag = 'Y'
              AND flv_tt3.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt3.start_date_active
                                                     AND     NVL(flv_tt3.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '20' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt4.lookup_code
            FROM fnd_lookup_values  flv_tt4
            WHERE flv_tt4.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt4.lookup_code = '22'
              AND flv_tt4.attribute1 = xltt.transaction_type_code
              AND flv_tt4.enabled_flag = 'Y'
              AND flv_tt4.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt4.start_date_active
                                                     AND     NVL(flv_tt4.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '70' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt5.lookup_code
            FROM fnd_lookup_values  flv_tt5
            WHERE flv_tt5.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt5.lookup_code = '71'
              AND flv_tt5.attribute1 = xltt.transaction_type_code
              AND flv_tt5.enabled_flag = 'Y'
              AND flv_tt5.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt5.start_date_active
                                                     AND     NVL(flv_tt5.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '70' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt6.lookup_code
            FROM fnd_lookup_values  flv_tt6
            WHERE flv_tt6.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt6.lookup_code = '72'
              AND flv_tt6.attribute1 = xltt.transaction_type_code
              AND flv_tt6.enabled_flag = 'Y'
              AND flv_tt6.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt6.start_date_active
                                                     AND     NVL(flv_tt6.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '390' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt7.lookup_code
            FROM fnd_lookup_values  flv_tt7
            WHERE flv_tt7.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt7.lookup_code = '391'
              AND flv_tt7.attribute1 = xltt.transaction_type_code
              AND flv_tt7.enabled_flag = 'Y'
              AND flv_tt7.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt7.start_date_active
                                                     AND     NVL(flv_tt7.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '390' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt8.lookup_code
            FROM fnd_lookup_values  flv_tt8
            WHERE flv_tt8.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt8.lookup_code = '392'
              AND flv_tt8.attribute1 = xltt.transaction_type_code
              AND flv_tt8.enabled_flag = 'Y'
              AND flv_tt8.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt8.start_date_active
                                                     AND     NVL(flv_tt8.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        ELSE flv_tt.lookup_code
      END
     )                                           transaction_type_code         -- 取引タイプコード
   ,(
      CASE
        WHEN ( xltt.transaction_type_code = '10' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt1.meaning
            FROM fnd_lookup_values  flv_tt1
            WHERE flv_tt1.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt1.lookup_code = '11'
              AND flv_tt1.attribute1 = xltt.transaction_type_code
              AND flv_tt1.enabled_flag = 'Y'
              AND flv_tt1.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt1.start_date_active
                                                     AND     NVL(flv_tt1.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '10' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt2.meaning
            FROM fnd_lookup_values  flv_tt2
            WHERE flv_tT2.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt2.lookup_code = '12'
              AND flv_tt2.attribute1 = xltt.transaction_type_code
              AND flv_tt2.enabled_flag = 'Y'
              AND flv_tt2.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt2.start_date_active
                                                     AND     NVL(flv_tt2.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '20' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt3.meaning
            FROM fnd_lookup_values  flv_tt3
            WHERE flv_tt3.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt3.lookup_code = '21'
              AND flv_tt3.attribute1 = xltt.transaction_type_code
              AND flv_tt3.enabled_flag = 'Y'
              AND flv_tt3.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt3.start_date_active
                                                     AND     NVL(flv_tt3.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '20' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt4.meaning
            FROM fnd_lookup_values  flv_tt4
            WHERE flv_tt4.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt4.lookup_code = '22'
              AND flv_tt4.attribute1 = xltt.transaction_type_code
              AND flv_tt4.enabled_flag = 'Y'
              AND flv_tt4.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt4.start_date_active
                                                     AND     NVL(flv_tt4.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '70' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt5.meaning
            FROM fnd_lookup_values  flv_tt5
            WHERE flv_tt5.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt5.lookup_code = '71'
              AND flv_tt5.attribute1 = xltt.transaction_type_code
              AND flv_tt5.enabled_flag = 'Y'
              AND flv_tt5.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt5.start_date_active
                                                     AND     NVL(flv_tt5.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '70' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt6.meaning
            FROM fnd_lookup_values  flv_tt6
            WHERE flv_tt6.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt6.lookup_code = '72'
              AND flv_tt6.attribute1 = xltt.transaction_type_code
              AND flv_tt6.enabled_flag = 'Y'
              AND flv_tt6.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt6.start_date_active
                                                     AND     NVL(flv_tt6.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '390' AND xltt.sign_div = '1' ) THEN
          ( SELECT flv_tt7.meaning
            FROM fnd_lookup_values  flv_tt7
            WHERE flv_tt7.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt7.lookup_code = '391'
              AND flv_tt7.attribute1 = xltt.transaction_type_code
              AND flv_tt7.enabled_flag = 'Y'
              AND flv_tt7.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt7.start_date_active
                                                     AND     NVL(flv_tt7.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xltt.transaction_type_code = '390' AND xltt.sign_div = '0' ) THEN
          ( SELECT flv_tt8.meaning
            FROM fnd_lookup_values  flv_tt8
            WHERE flv_tt8.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_tt8.lookup_code = '392'
              AND flv_tt8.attribute1 = xltt.transaction_type_code
              AND flv_tt8.enabled_flag = 'Y'
              AND flv_tt8.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt8.start_date_active
                                                     AND     NVL(flv_tt8.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        ELSE flv_tt.meaning
      END
     )                                           transaction_type_name         -- 取引タイプ名称
   ,flv_st.lookup_code                           status_code                   -- ステータス（コード）
   ,flv_st.meaning                               status_name                   -- ステータス（名称）
   ,xltt.transfer_location_code                  transfer_location_code        -- 転送先ロケーションコード
   ,xmwl2.location_name                          transfer_location_name        -- 転送先ロケーション名
   ,xltt.sign_div                                sign_div                      -- 符号区分
   ,xltt.source_code                             source_code                   -- ソースコード
   ,xltt.relation_key                            relation_key                  -- 紐付けキー
   ,NULL                                         reserve_transaction_type_code -- 引当時取引タイプコード
   ,NULL                                         reason                        -- 摘要
   ,NULL                                         fix_user_code                 -- 確定者コード
   ,NULL                                         fix_user_name                 -- 確定者名
   ,xltt.created_by                              created_by                    -- 作成者
   ,xltt.creation_date                           creation_date                 -- 作成日
   ,xltt.last_updated_by                         last_updated_by               -- 最終更新者
   ,xltt.last_update_date                        last_update_date              -- 最終更新日
   ,xltt.last_update_login                       last_update_login             -- 最終更新ログイン
  FROM
    xxcoi_lot_transactions_temp         xltt               -- ロット別取引TEMP
   ,mtl_system_items_b                  msib_oya           -- Disc品目マスタ_親
   ,mtl_system_items_b                  msib_ko            -- Disc品目マスタ_子
   ,ic_item_mst_b                       iimb_oya           -- OPM品目マスタ_親
   ,ic_item_mst_b                       iimb_ko            -- OPM品目マスタ_子
   ,xxcmn_item_mst_b                    ximb_oya           -- OPM品目アドオンマスタ_親
   ,xxcmn_item_mst_b                    ximb_ko            -- OPM品目アドオンマスタ_子
   ,gmi_item_categories                 gic                -- 品目カテゴリ
   ,mtl_category_sets_vl                mcsv               -- 品目カテゴリセットビュー
   ,mtl_categories_vl                   mcv                -- 品目カテゴリビュー
   ,xxcoi_warehouse_location_mst_v      xmwl               -- 倉庫ロケーションマスタ
-- 2015/03/10 Add Ver1.1 Y.Nagasue
   ,xxcoi_warehouse_location_mst_v      xmwl2              -- 倉庫ロケーションマスタ(転送先)
-- 2015/03/10 Add Ver1.1 Y.Nagasue
   ,fnd_lookup_values                   flv_st             -- クイックコード（ステータス）
   ,fnd_lookup_values                   flv_tt             -- クイックコード（取引タイプ名）
  WHERE
      xltt.organization_id = msib_oya.organization_id
  AND xltt.parent_item_id = msib_oya.inventory_item_id
  AND xltt.organization_id = msib_ko.organization_id(+)
  AND xltt.child_item_id = msib_ko.inventory_item_id(+)
  AND msib_oya.segment1 = iimb_oya.item_no
  AND msib_ko.segment1 = iimb_ko.item_no(+)
  AND iimb_oya.item_id = ximb_oya.item_id
  AND xltt.transaction_date
        BETWEEN ximb_oya.start_date_active AND ximb_oya.end_date_active
  AND iimb_ko.item_id = ximb_ko.item_id(+)
  AND ( xltt.child_item_id IS NULL OR
      xltt.transaction_date
        BETWEEN ximb_ko.start_date_active AND ximb_ko.end_date_active )
  AND gic.category_set_id = mcsv.category_set_id(+)
  AND ((xltt.child_item_id IS NULL) OR (xltt.child_item_id IS NOT NULL AND mcsv.category_set_name = '本社商品区分'))
  AND gic.category_id = mcv.category_id(+)
  AND gic.item_id(+) = iimb_ko.item_id
  AND xltt.organization_id = xmwl.organization_id(+)
  AND xltt.base_code = xmwl.base_code(+)
  AND xltt.subinventory_code = xmwl.subinventory_code(+)
  AND xltt.location_code = xmwl.location_code(+)
-- 2015/03/10 Add Ver1.1 Y.Nagasue
  AND xltt.organization_id = xmwl2.organization_id(+)
  AND xltt.base_code = xmwl2.base_code(+)
  AND xltt.subinventory_code = xmwl2.subinventory_code(+)
  AND xltt.transfer_location_code = xmwl2.location_code(+)
-- 2015/03/10 Add Ver1.1 Y.Nagasue
  AND flv_st.lookup_type = 'XXCOI1_CREATE_DIV'
  AND flv_st.lookup_code = '10'
  AND flv_st.enabled_flag = 'Y'
  AND flv_st.language = USERENV('LANG')
  AND xxccp_common_pkg2.get_process_date BETWEEN flv_st.start_date_active
                                         AND     NVL(flv_st.end_date_active, xxccp_common_pkg2.get_process_date)
  AND flv_tt.lookup_type = 'XXCOI1_TRANSACTION_TYPE_NAME'
  AND flv_tt.lookup_code = xltt.transaction_type_code
  AND flv_tt.enabled_flag = 'Y'
  AND flv_tt.language = USERENV('LANG')
  AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt.start_date_active
                                         AND     NVL(flv_tt.end_date_active, xxccp_common_pkg2.get_process_date)
  UNION ALL
  SELECT
    xlt.transaction_id                          transaction_id                -- 取引ID
   ,xlt.transaction_set_id                      transaction_set_id            -- 取引セットID
   ,xlt.organization_id                         organization_id               -- 在庫組織ID
   ,xlt.slip_num                                slip_num                      -- 伝票No
   ,mcv.segment1                                item_kbn                      -- 商品区分
   ,mcv.description                             item_kbn_name                 -- 商品区分名
   ,xlt.parent_item_id                          parent_item_id                -- 親品目ID
   ,iimb_oya.item_no                            parent_item_cd                -- 親品目コード
   ,ximb_oya.item_short_name                    parent_item_name              -- 親品目名称
   ,xlt.child_item_id                           child_item_id                 -- 子品目ID
   ,iimb_ko.item_no                             child_item_cd                 -- 子品目コード
   ,ximb_ko.item_short_name                     child_item_name               -- 子品目名称
   ,xlt.lot                                     lot                           -- ロット
   ,xlt.difference_summary_code                 difference_summary_code       -- 固有記号
   ,xlt.subinventory_code                       subinventory_code             -- 保管場所
   ,xlt.location_code                           location_code                 -- ロケーションコード
   ,xmwl.location_name                          location_name                 -- ロケーション名称
   ,xlt.case_in_qty                             case_in_qty                   -- 入数
   ,( CASE
        WHEN ( ( xlt.transaction_type_code IN ( '10', '20', '70', '390' ) AND xlt.sign_div = '0' )
            OR ( xlt.transaction_type_code IN ( '90', '110', '130', '170','180','190','200','320','330','340','350','360','370', '410' ) ) ) THEN
          xlt.case_qty * (-1)
        ELSE
          xlt.case_qty
        END
    )                                           case_qty                      -- ケース数
   ,( CASE
        WHEN ( ( xlt.transaction_type_code IN ( '10', '20', '70', '390' ) AND xlt.sign_div = '0' )
            OR ( xlt.transaction_type_code IN ( '90', '110', '130', '170','180','190','200','320','330','340','350','360','370', '410' ) ) ) THEN
          xlt.singly_qty * (-1)
        ELSE
          xlt.singly_qty
        END
    )                                           singly_qty                    -- バラ数
   ,( CASE
        WHEN ( ( xlt.transaction_type_code IN ( '10', '20', '70', '390' ) AND xlt.sign_div = '0' )
            OR ( xlt.transaction_type_code IN ( '90', '110', '130', '170','180','190','200','320','330','340','350','360','370', '410' ) ) ) THEN
          xlt.summary_qty * (-1)
        ELSE
          xlt.summary_qty
        END
    )                                           summary_qty                   -- 数量
   ,TO_CHAR(xlt.transaction_date, 'yyyy/mm/dd') transaction_date              -- 日付
   ,xlt.transfer_subinventory                   transfer_subinventory         -- 転送先保管場所コード
   ,(
      CASE
        WHEN ( LENGTHB(xlt.transfer_subinventory) = '4' ) THEN
          ( SELECT mil.attribute12
            FROM mtl_item_locations  mil
            WHERE mil.segment1 = xlt.transfer_subinventory
           )
        ELSE
          ( SELECT msi.description
            FROM mtl_secondary_inventories  msi
            WHERE msi.organization_id = xlt.organization_id
              AND msi.secondary_inventory_name = xlt.transfer_subinventory
           )
      END
     )                                          transfer_subinventory_name    -- 転送先保管場所名称
   ,(
      CASE
        WHEN ( xlt.transaction_type_code = '10' AND xlt.sign_div = '1' ) THEN
          ( SELECT flv_t1.lookup_code
            FROM fnd_lookup_values  flv_t1
            WHERE flv_t1.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t1.lookup_code = '11'
              AND flv_t1.attribute1 = xlt.transaction_type_code
              AND flv_t1.enabled_flag = 'Y'
              AND flv_t1.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t1.start_date_active
                                                     AND     NVL(flv_t1.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '10' AND xlt.sign_div = '0' ) THEN
          ( SELECT flv_t2.lookup_code
            FROM fnd_lookup_values  flv_t2
            WHERE flv_t2.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t2.lookup_code = '12'
              AND flv_t2.attribute1 = xlt.transaction_type_code
              AND flv_t2.enabled_flag = 'Y'
              AND flv_t2.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t2.start_date_active
                                                     AND     NVL(flv_t2.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '20' AND xlt.sign_div = '1' ) THEN
          ( SELECT flv_t3.lookup_code
            FROM fnd_lookup_values  flv_t3
            WHERE flv_t3.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t3.lookup_code = '21'
              AND flv_t3.attribute1 = xlt.transaction_type_code
              AND flv_t3.enabled_flag = 'Y'
              AND flv_t3.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t3.start_date_active
                                                     AND     NVL(flv_t3.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '20' AND xlt.sign_div = '0' ) THEN
          ( SELECT flv_t4.lookup_code
            FROM fnd_lookup_values  flv_t4
            WHERE flv_t4.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t4.lookup_code = '22'
              AND flv_t4.attribute1 = xlt.transaction_type_code
              AND flv_t4.enabled_flag = 'Y'
              AND flv_t4.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t4.start_date_active
                                                     AND     NVL(flv_t4.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '70' AND xlt.sign_div = '1' ) THEN
          ( SELECT flv_t5.lookup_code
            FROM fnd_lookup_values  flv_t5
            WHERE flv_t5.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t5.lookup_code = '71'
              AND flv_t5.attribute1 = xlt.transaction_type_code
              AND flv_t5.enabled_flag = 'Y'
              AND flv_t5.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t5.start_date_active
                                                     AND     NVL(flv_t5.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '70' AND xlt.sign_div = '0' ) THEN
          ( SELECT flv_t6.lookup_code
            FROM fnd_lookup_values  flv_t6
            WHERE flv_t6.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t6.lookup_code = '72'
              AND flv_t6.attribute1 = xlt.transaction_type_code
              AND flv_t6.enabled_flag = 'Y'
              AND flv_t6.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t6.start_date_active
                                                     AND     NVL(flv_t6.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '390' AND xlt.sign_div = '1' ) THEN
          ( SELECT flv_t7.lookup_code
            FROM fnd_lookup_values  flv_t7
            WHERE flv_t7.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t7.lookup_code = '391'
              AND flv_t7.attribute1 = xlt.transaction_type_code
              AND flv_t7.enabled_flag = 'Y'
              AND flv_t7.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t7.start_date_active
                                                     AND     NVL(flv_t7.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '390' AND xlt.sign_div = '0' ) THEN
          ( SELECT flv_t8.lookup_code
            FROM fnd_lookup_values  flv_t8
            WHERE flv_t8.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t8.lookup_code = '392'
              AND flv_t8.attribute1 = xlt.transaction_type_code
              AND flv_t8.enabled_flag = 'Y'
              AND flv_t8.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t8.start_date_active
                                                     AND     NVL(flv_t8.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        ELSE flv_tt.lookup_code
      END
     )                                          transaction_type_code         -- 取引タイプコード
   ,(
      CASE
        WHEN ( xlt.transaction_type_code = '10' AND xlt.sign_div = '1' ) THEN
          ( SELECT flv_t1.meaning
            FROM fnd_lookup_values  flv_t1
            WHERE flv_t1.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t1.lookup_code = '11'
              AND flv_t1.attribute1 = xlt.transaction_type_code
              AND flv_t1.enabled_flag = 'Y'
              AND flv_t1.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t1.start_date_active
                                                     AND     NVL(flv_t1.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '10' AND xlt.sign_div = '0' ) THEN
          ( SELECT flv_t2.meaning
            FROM fnd_lookup_values  flv_t2
            WHERE flv_t2.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t2.lookup_code = '12'
              AND flv_t2.attribute1 = xlt.transaction_type_code
              AND flv_t2.enabled_flag = 'Y'
              AND flv_t2.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t2.start_date_active
                                                     AND     NVL(flv_t2.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '20' AND xlt.sign_div = '1' ) THEN
          ( SELECT flv_t3.meaning
            FROM fnd_lookup_values  flv_t3
            WHERE flv_t3.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t3.lookup_code = '21'
              AND flv_t3.attribute1 = xlt.transaction_type_code
              AND flv_t3.enabled_flag = 'Y'
              AND flv_t3.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t3.start_date_active
                                                     AND     NVL(flv_t3.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '20' AND xlt.sign_div = '0' ) THEN
          ( SELECT flv_t4.meaning
            FROM fnd_lookup_values  flv_t4
            WHERE flv_t4.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t4.lookup_code = '22'
              AND flv_t4.attribute1 = xlt.transaction_type_code
              AND flv_t4.enabled_flag = 'Y'
              AND flv_t4.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t4.start_date_active
                                                     AND     NVL(flv_t4.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '70' AND xlt.sign_div = '1' ) THEN
          ( SELECT flv_t5.meaning
            FROM fnd_lookup_values  flv_t5
            WHERE flv_t5.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t5.lookup_code = '71'
              AND flv_t5.attribute1 = xlt.transaction_type_code
              AND flv_t5.enabled_flag = 'Y'
              AND flv_t5.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t5.start_date_active
                                                     AND     NVL(flv_t5.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '70' AND xlt.sign_div = '0' ) THEN
          ( SELECT flv_t6.meaning
            FROM fnd_lookup_values  flv_t6
            WHERE flv_t6.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t6.lookup_code = '72'
              AND flv_t6.attribute1 = xlt.transaction_type_code
              AND flv_t6.enabled_flag = 'Y'
              AND flv_t6.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t6.start_date_active
                                                     AND     NVL(flv_t6.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '390' AND xlt.sign_div = '1' ) THEN
          ( SELECT flv_t7.meaning
            FROM fnd_lookup_values  flv_t7
            WHERE flv_t7.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t7.lookup_code = '391'
              AND flv_t7.attribute1 = xlt.transaction_type_code
              AND flv_t7.enabled_flag = 'Y'
              AND flv_t7.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t7.start_date_active
                                                     AND     NVL(flv_t7.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        WHEN ( xlt.transaction_type_code = '390' AND xlt.sign_div = '0' ) THEN
          ( SELECT flv_t8.meaning
            FROM fnd_lookup_values  flv_t8
            WHERE flv_t8.lookup_type = 'XXCOI1_LOT_TRAN_TYPE_NAME_DISP'
              AND flv_t8.lookup_code = '392'
              AND flv_t8.attribute1 = xlt.transaction_type_code
              AND flv_t8.enabled_flag = 'Y'
              AND flv_t8.language = userenv('LANG')
              AND xxccp_common_pkg2.get_process_date BETWEEN flv_t8.start_date_active
                                                     AND     NVL(flv_t8.end_date_active, xxccp_common_pkg2.get_process_date)
           )
        ELSE flv_tt.meaning
      END
     )                                          transaction_type_name         -- 取引タイプ名称
   ,flv_st.lookup_code                          status_code                   -- ステータス（コード）
   ,flv_st.meaning                              status_name                   -- ステータス（名称）
   ,xlt.transfer_location_code                  transfer_location_code        -- 転送先ロケーションコード
-- 2015/03/10 Mod Ver1.1 Y.Nagasue
--   ,NULL                                        sign_div
   ,xmwl2.location_name                         transfer_location_name        -- 転送先ロケーション名
   ,xlt.sign_div                                sign_div                      -- 符号区分
-- 2015/03/10 Mod Ver1.1 Y.Nagasue
   ,xlt.source_code                             source_code                   -- ソースコード
   ,xlt.relation_key                            relation_key                  -- 紐付けキー
   ,xlt.reserve_transaction_type_code           reserve_transaction_type_code -- 引当時取引タイプコード
   ,xlt.reason                                  reason                        -- 摘要
   ,xlt.fix_user_code                           fix_user_code                 -- 確定者コード
   ,xlt.fix_user_name                           fix_user_name                 -- 確定者名
   ,xlt.created_by                              created_by                    -- 作成者
   ,xlt.creation_date                           creation_date                 -- 作成日
   ,xlt.last_updated_by                         last_updated_by               -- 最終更新者
   ,xlt.last_update_date                        last_update_date              -- 最終更新日
   ,xlt.last_update_login                       last_update_login             -- 最終更新ログイン
  FROM
    xxcoi_lot_transactions              xlt                -- ロット別取引明細
   ,mtl_system_items_b                  msib_oya           -- Disc品目マスタ_親
   ,mtl_system_items_b                  msib_ko            -- Disc品目マスタ_子
   ,ic_item_mst_b                       iimb_oya           -- OPM品目マスタ_親
   ,ic_item_mst_b                       iimb_ko            -- OPM品目マスタ_子
   ,xxcmn_item_mst_b                    ximb_oya           -- OPM品目アドオンマスタ_親
   ,xxcmn_item_mst_b                    ximb_ko            -- OPM品目アドオンマスタ_子
   ,gmi_item_categories                 gic                -- 品目カテゴリ
   ,mtl_category_sets_vl                mcsv               -- 品目カテゴリセットビュー
   ,mtl_categories_vl                   mcv                -- 品目カテゴリビュー
   ,xxcoi_warehouse_location_mst_v      xmwl               -- 倉庫ロケーションマスタ
-- 2015/03/10 Add Ver1.1 Y.Nagasue
   ,xxcoi_warehouse_location_mst_v      xmwl2              -- 倉庫ロケーションマスタ(転送先)
-- 2015/03/10 Add Ver1.1 Y.Nagasue
   ,fnd_lookup_values                   flv_st             -- クイックコード（ステータス）
   ,fnd_lookup_values                   flv_tt             -- クイックコード（取引タイプ名）
  WHERE
      xlt.organization_id = msib_oya.organization_id
  AND xlt.parent_item_id = msib_oya.inventory_item_id
  AND xlt.organization_id = msib_ko.organization_id
  AND xlt.child_item_id = msib_ko.inventory_item_id
  AND msib_oya.segment1 = iimb_oya.item_no
  AND iimb_oya.item_id = ximb_oya.item_id
  AND xlt.transaction_date
        BETWEEN ximb_oya.start_date_active AND ximb_oya.end_date_active
  AND msib_ko.segment1 = iimb_ko.item_no
  AND iimb_ko.item_id = ximb_ko.item_id
  AND xlt.transaction_date
        BETWEEN ximb_ko.start_date_active AND ximb_ko.end_date_active
  AND gic.category_set_id = mcsv.category_set_id
  AND gic.category_set_id = mcsv.category_set_id
  AND mcsv.category_set_name = '本社商品区分'
  AND gic.category_id = mcv.category_id
  AND gic.item_id = iimb_ko.item_id
  AND xlt.organization_id = xmwl.organization_id(+)
  AND xlt.base_code = xmwl.base_code(+)
  AND xlt.subinventory_code = xmwl.subinventory_code(+)
  AND xlt.location_code = xmwl.location_code(+)
-- 2015/03/10 Add Ver1.1 Y.Nagasue
  AND xlt.organization_id = xmwl2.organization_id(+)
  AND xlt.base_code = xmwl2.base_code(+)
  AND xlt.subinventory_code = xmwl2.subinventory_code(+)
  AND xlt.transfer_location_code = xmwl2.location_code(+)
-- 2015/03/10 Add Ver1.1 Y.Nagasue
  AND flv_st.lookup_type = 'XXCOI1_CREATE_DIV'
  AND flv_st.lookup_code = '20'
  AND flv_st.enabled_flag = 'Y'
  AND flv_st.language = USERENV('LANG')
  AND xxccp_common_pkg2.get_process_date BETWEEN flv_st.start_date_active
                                         AND     NVL(flv_st.end_date_active, xxccp_common_pkg2.get_process_date)
  AND flv_tt.lookup_type = 'XXCOI1_TRANSACTION_TYPE_NAME'
  AND flv_tt.lookup_code = xlt.transaction_type_code
  AND flv_tt.enabled_flag = 'Y'
  AND flv_tt.language = USERENV('LANG')
  AND xxccp_common_pkg2.get_process_date BETWEEN flv_tt.start_date_active
                                         AND     NVL(flv_tt.end_date_active, xxccp_common_pkg2.get_process_date)
/
COMMENT ON TABLE xxcoi_lot_trans_info_v IS 'ロット別取引情報作成照会画面ビュー';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transaction_id IS '取引ID';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transaction_set_id IS '取引セットID';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.organization_id IS '在庫組織ID';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.slip_num IS '伝票No';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.item_kbn IS '商品区分';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.item_kbn_name IS '商品区分名';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.parent_item_id IS '親品目ID';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.parent_item_cd IS '親品目コード';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.parent_item_name IS '親品目名称';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.child_item_id IS '子品目ID';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.child_item_cd IS '子品目コード';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.child_item_name IS '子品目名称';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.lot IS 'ロット';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.difference_summary_code IS '固有記号';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.subinventory_code IS '保管場所';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.location_code IS 'ロケーションコード';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.location_name IS 'ロケーション名称';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.case_in_qty IS '入数';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.case_qty IS 'ケース数';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.singly_qty IS 'バラ数';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.summary_qty IS '数量';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transaction_date IS '日付';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transfer_subinventory IS '転送先保管場所コード';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transfer_subinventory_name IS '転送先保管場所名称';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transaction_type_code IS '取引タイプコード';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transaction_type_name IS '取引タイプ名称';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.status_code IS 'ステータス（コード）';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.status_name IS 'ステータス（名称）';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transfer_location_code IS '転送先ロケーションコード';
/
-- 2015/03/10 Add Ver1.1 Y.Nagasue
COMMENT ON COLUMN xxcoi_lot_trans_info_v.transfer_location_name IS '転送先ロケーション名';
/
-- 2015/03/10 Add Ver1.1 Y.Nagasue
COMMENT ON COLUMN xxcoi_lot_trans_info_v.sign_div IS '符号区分';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.source_code IS 'ソースコード';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.relation_key IS '紐付けキー';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.reserve_transaction_type_code IS '引当時取引タイプコード';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.reason IS '摘要';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.fix_user_code IS '確定者コード';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.fix_user_name IS '確定者名';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.created_by IS '作成者';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.creation_date IS '作成日';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.last_updated_by IS '最終更新者';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.last_update_date IS '最終更新日';
/
COMMENT ON COLUMN xxcoi_lot_trans_info_v.last_update_login IS '最終更新ログイン';
/
