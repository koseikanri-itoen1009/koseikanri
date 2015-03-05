/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2014. All rights reserved.
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
    xltt.transaction_id
   ,xltt.transaction_set_id
   ,xltt.organization_id
   ,xltt.slip_num
   ,mcv.segment1
   ,mcv.description
   ,xltt.parent_item_id
   ,iimb_oya.item_no
   ,ximb_oya.item_short_name
   ,xltt.child_item_id
   ,iimb_ko.item_no
   ,ximb_ko.item_short_name
   ,xltt.lot
   ,xltt.difference_summary_code
   ,xltt.subinventory_code
   ,xltt.location_code
   ,xmwl.location_name
   ,xltt.case_in_qty
   ,xltt.case_qty
   ,xltt.singly_qty
   ,xltt.summary_qty
   ,TO_CHAR(xltt.transaction_date, 'yyyy/mm/dd')
   ,xltt.transfer_subinventory
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
     ) transfer_subinventory_name
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
        ELSE flv_tt.lookup_code
      END
     ) transaction_type_code
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
        ELSE flv_tt.meaning
      END
     ) transaction_type_name
   ,flv_st.lookup_code
   ,flv_st.meaning
   ,xltt.transfer_location_code
   ,xltt.sign_div
   ,xltt.source_code
   ,xltt.relation_key
   ,NULL
   ,NULL
   ,NULL
   ,NULL
   ,xltt.created_by
   ,xltt.creation_date
   ,xltt.last_updated_by
   ,xltt.last_update_date
   ,xltt.last_update_login
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
  AND flv_st.lookup_type = 'XXCOI1_CREATE_DIV'
  AND flv_st.lookup_code = 10
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
    xlt.transaction_id
   ,xlt.transaction_set_id
   ,xlt.organization_id
   ,xlt.slip_num
   ,mcv.segment1
   ,mcv.description
   ,xlt.parent_item_id
   ,iimb_oya.item_no
   ,ximb_oya.item_short_name
   ,xlt.child_item_id
   ,iimb_ko.item_no
   ,ximb_ko.item_short_name
   ,xlt.lot
   ,xlt.difference_summary_code
   ,xlt.subinventory_code
   ,xlt.location_code
   ,xmwl.location_name
   ,xlt.case_in_qty
   ,xlt.case_qty
   ,xlt.singly_qty
   ,xlt.summary_qty
   ,TO_CHAR(xlt.transaction_date, 'yyyy/mm/dd')
   ,xlt.transfer_subinventory
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
     ) transfer_subinventory_name
   ,(
      CASE
        WHEN ( xlt.transaction_type_code = '10' AND xlt.summary_qty > 0 ) THEN
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
        WHEN ( xlt.transaction_type_code = '10' AND xlt.summary_qty < 0 ) THEN
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
        WHEN ( xlt.transaction_type_code = '20' AND xlt.summary_qty > 0 ) THEN
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
        WHEN ( xlt.transaction_type_code = '20' AND xlt.summary_qty < 0 ) THEN
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
        WHEN ( xlt.transaction_type_code = '70' AND xlt.summary_qty > 0 ) THEN
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
        WHEN ( xlt.transaction_type_code = '70' AND xlt.summary_qty < 0 ) THEN
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
        ELSE flv_tt.lookup_code
      END
     ) transaction_type_code
   ,(
      CASE
        WHEN ( xlt.transaction_type_code = '10' AND xlt.summary_qty > 0 ) THEN
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
        WHEN ( xlt.transaction_type_code = '10' AND xlt.summary_qty < 0 ) THEN
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
        WHEN ( xlt.transaction_type_code = '20' AND xlt.summary_qty > 0 ) THEN
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
        WHEN ( xlt.transaction_type_code = '20' AND xlt.summary_qty < 0 ) THEN
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
        WHEN ( xlt.transaction_type_code = '70' AND xlt.summary_qty > 0 ) THEN
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
        WHEN ( xlt.transaction_type_code = '70' AND xlt.summary_qty < 0 ) THEN
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
        ELSE flv_tt.meaning
      END
     ) transaction_type_name
   ,flv_st.lookup_code
   ,flv_st.meaning
   ,xlt.transfer_location_code
   ,NULL
   ,xlt.source_code
   ,xlt.relation_key
   ,xlt.reserve_transaction_type_code
   ,xlt.reason
   ,xlt.fix_user_code
   ,xlt.fix_user_name
   ,xlt.created_by
   ,xlt.creation_date
   ,xlt.last_updated_by
   ,xlt.last_update_date
   ,xlt.last_update_login
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
  AND xlt.organization_id = xmwl.organization_id
  AND xlt.base_code = xmwl.base_code
  AND xlt.subinventory_code = xmwl.subinventory_code
  AND xlt.location_code = xmwl.location_code
  AND flv_st.lookup_type = 'XXCOI1_CREATE_DIV'
  AND flv_st.lookup_code = 20
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
