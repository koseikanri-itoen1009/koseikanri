/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOI_STORAGE_INFORMATION_V
 * Description     : 入庫確認／訂正入力画面ビュー
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-12-05    1.0   S.Moriyama       新規作成
 *  2009-03-30    1.1   S.Moriyama       バラ茶区分を追加
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcoi_storage_information_v
  (  transaction_id                                                   -- 取引ID
   , base_code                                                        -- 拠点コード
   , warehouse_code                                                   -- 倉庫コード
   , slip_date                                                        -- 伝票日付
   , slip_num                                                         -- 伝票No
   , slip_type                                                        -- 伝票区分コード
   , meaning                                                          -- 伝票区分
   , parent_item_code                                                 -- 親品目コード
   , item_code                                                        -- 子品目コード
   , item_short_name                                                  -- 品目略称
   , case_in_qty                                                      -- ケース入数
   , ship_case_qty                                                    -- 出庫数量ケース数
   , ship_singly_qty                                                  -- 出庫数量バラ数
   , ship_summary_qty                                                 -- 出庫数量総バラ数
   , summary_data_flag                                                -- サマリーデータフラグ
   , store_check_flag                                                 -- 入庫確認フラグ
   , material_transaction_set_flag                                    -- 資材取引連携済フラグ
   , auto_store_check_flag                                            -- 自動入庫確認フラグ
   , check_warehouse_code                                             -- 確認倉庫コード
   , baracha_div                                                      -- バラ茶区分
   , created_by                                                       -- 作成者
   , creation_date                                                    -- 作成日
   , last_updated_by                                                  -- 最終更新者
   , last_update_date                                                 -- 最終更新日
   , last_update_login                                                -- 最終更新ユーザ
  )
AS
  SELECT   xsi.transaction_id                                         -- 取引ID
         , xsi.base_code                                              -- 拠点コード
         , xsi.warehouse_code                                         -- 倉庫コード
         , xsi.slip_date                                              -- 伝票日付
         , xsi.slip_num                                               -- 伝票No
         , xsi.slip_type                                              -- 伝票区分コード
         , flv.meaning                                                -- 伝票区分
         , xsi.parent_item_code                                       -- 親品目コード
         , xsi.item_code                                              -- 子品目コード
         , ximb.item_short_name                                       -- 品目略称
         , xsi.case_in_qty                                            -- ケース入数
         , xsi.ship_case_qty                                          -- 出庫数量ケース数
         , xsi.ship_singly_qty                                        -- 出庫数量バラ数
         , xsi.ship_summary_qty                                       -- 出庫数量総バラ数
         , xsi.summary_data_flag                                      -- サマリーデータフラグ
         , xsi.store_check_flag                                       -- 入庫確認フラグ
         , xsi.material_transaction_set_flag                          -- 資材取引連携済フラグ
         , xsi.auto_store_check_flag                                  -- 自動入庫確認フラグ
         , xsi.check_warehouse_code                                   -- 確認倉庫コード
         , xsib.baracha_div                                           -- バラ茶区分
         , xsi.created_by                                             -- 作成者
         , xsi.creation_date                                          -- 作成日
         , xsi.last_updated_by                                        -- 最終更新者
         , xsi.last_update_date                                       -- 最終更新日
         , xsi.last_update_login                                      -- 最終更新ユーザ
  FROM     xxcoi_storage_information xsi
         , fnd_lookup_values         flv
         , xxcmn_item_mst_b          ximb
         , ic_item_mst_b             iimb
         , xxcmm_system_items_b      xsib
  WHERE    flv.lookup_type = 'XXCOI1_STOCKED_VOUCH_DIV'
  AND      flv.language = USERENV('LANG')
  AND      flv.enabled_flag = 'Y'
  AND      TRUNC ( SYSDATE ) BETWEEN TRUNC ( NVL ( flv.start_date_active, SYSDATE ) )
                         AND TRUNC ( NVL ( flv.end_date_active, SYSDATE ) )
  AND      flv.lookup_code = xsi.slip_type
  AND      iimb.item_id = ximb.item_id
  AND      xsi.item_code = iimb.item_no
  AND      iimb.item_id = xsib.item_id
/
COMMENT ON TABLE xxcoi_storage_information_v IS '入庫確認／訂正画面ビュー'
/
COMMENT ON COLUMN xxcoi_storage_information_v.transaction_id IS '取引ID'
/
COMMENT ON COLUMN xxcoi_storage_information_v.base_code IS '拠点コード'
/
COMMENT ON COLUMN xxcoi_storage_information_v.warehouse_code IS '倉庫コード'
/
COMMENT ON COLUMN xxcoi_storage_information_v.slip_date IS '伝票日付'
/
COMMENT ON COLUMN xxcoi_storage_information_v.slip_num IS '伝票No'
/
COMMENT ON COLUMN xxcoi_storage_information_v.slip_type IS '伝票区分コード'
/
COMMENT ON COLUMN xxcoi_storage_information_v.meaning IS '伝票区分'
/
COMMENT ON COLUMN xxcoi_storage_information_v.parent_item_code IS '親品目コード'
/
COMMENT ON COLUMN xxcoi_storage_information_v.item_code IS '子品目コード'
/
COMMENT ON COLUMN xxcoi_storage_information_v.item_short_name IS '品目略称'
/
COMMENT ON COLUMN xxcoi_storage_information_v.case_in_qty IS 'ケース入数'
/
COMMENT ON COLUMN xxcoi_storage_information_v.ship_case_qty IS '出庫数量ケース数'
/
COMMENT ON COLUMN xxcoi_storage_information_v.ship_singly_qty IS '出庫数量バラ数'
/
COMMENT ON COLUMN xxcoi_storage_information_v.ship_summary_qty IS '出庫数量総バラ数'
/
COMMENT ON COLUMN xxcoi_storage_information_v.summary_data_flag IS 'サマリーデータフラグ'
/
COMMENT ON COLUMN xxcoi_storage_information_v.store_check_flag IS '入庫確認フラグ'
/
COMMENT ON COLUMN xxcoi_storage_information_v.material_transaction_set_flag IS '資材取引連携済フラグ'
/
COMMENT ON COLUMN xxcoi_storage_information_v.auto_store_check_flag IS '自動入庫確認フラグ'
/
COMMENT ON COLUMN xxcoi_storage_information_v.check_warehouse_code IS '確認倉庫コード'
/
COMMENT ON COLUMN xxcoi_storage_information_v.baracha_div IS 'バラ茶区分'
/
COMMENT ON COLUMN xxcoi_storage_information_v.created_by IS '作成者'
/
COMMENT ON COLUMN xxcoi_storage_information_v.creation_date IS '作成日'
/
COMMENT ON COLUMN xxcoi_storage_information_v.last_updated_by IS '最終更新者'
/
COMMENT ON COLUMN xxcoi_storage_information_v.last_update_date IS '最終更新日'
/
COMMENT ON COLUMN xxcoi_storage_information_v.last_update_login IS '最終更新ユーザ'
/
