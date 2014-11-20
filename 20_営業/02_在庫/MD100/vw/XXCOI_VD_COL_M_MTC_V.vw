/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcoi_vd_col_m_mtc_v
 * Description     : VDコラムマスタメンテナンス画面ビュー
 * Version         : 1.4
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/18    1.0   SCS H.Wada       新規作成
 *  2008/12/04    1.1   SCS H.Wada       修正（VDコラムマスタ名修正）
 *  2009/08/20    1.2   SCS T.Murakami   在庫組織を「S01」→「Z99」に変更
 *  2009/09/08    1.3   SCS H.Sasaki     [0001266]OPM品目アドオンの版管理対応
 *  2011/09/29    1.4   SCS K.Nakamura   [E_本稼動_08440]納品日1～5、本数1～5、コラム更新日を追加
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCOI_VD_COL_M_MTC_V
  (vd_column_mst_id                                                           -- 1.VDコラムマスタID
  ,customer_id                                                                -- 2.顧客ID
  ,column_no                                                                  -- 3.コラム№
  ,item_code                                                                  -- 4.品目コード(当月)
  ,last_item_code                                                             -- 5.品目コード(前月)
-- == 2009/09/08 V1.3 Deleted START ===============================================================
--  ,item_name                                                                  -- 6.品目名称(当月)
--  ,last_item_name                                                             -- 7.品目名称(前月)
-- == 2009/09/08 V1.3 Deleted END   ===============================================================
  ,item_id                                                                    -- 8.品目ID(当月)
  ,last_item_id                                                               -- 9.品目ID(前月)
  ,primary_uom_code                                                           -- 10.基準単位(当月)
  ,last_primary_uom_code                                                      -- 11.基準単位(前月)
  ,inventory_quantity                                                         -- 12.基準在庫数(当月)
  ,last_inventory_quantity                                                    -- 13.基準在庫数(前月)
  ,price                                                                      -- 14.単価(当月)
  ,last_price                                                                 -- 15.単価(前月)
  ,hot_cold                                                                   -- 16.H/C値(当月)
  ,last_hot_cold                                                              -- 17.H/C値(前月)
  ,rack_quantity                                                              -- 18.ラック数
-- == 2011/09/29 V1.4 Added   START ===============================================================
  ,dlv_date_1                                                                 -- 28.納品日1
  ,quantity_1                                                                 -- 29.本数1
  ,dlv_date_2                                                                 -- 30.納品日2
  ,quantity_2                                                                 -- 31.本数2
  ,dlv_date_3                                                                 -- 32.納品日3
  ,quantity_3                                                                 -- 33.本数3
  ,dlv_date_4                                                                 -- 34.納品日4
  ,quantity_4                                                                 -- 35.本数4
  ,dlv_date_5                                                                 -- 36.納品日5
  ,quantity_5                                                                 -- 37.本数5
  ,column_change_date                                                         -- 38.コラム変更日
-- == 2011/09/29 V1.4 Added   END   ===============================================================
  ,created_by                                                                 -- 23.作成者
  ,creation_date                                                              -- 24.作成日
  ,last_updated_by                                                            -- 25.最終更新者
  ,last_update_date                                                           -- 26.最終更新日
  ,last_update_login                                                          -- 27.最終更新ログイン
  )
AS
SELECT   xmvc.vd_column_mst_id               AS vd_column_mst_id              -- 1.VDコラムマスタID
        ,xmvc.customer_id                    AS customer_id                   -- 2.顧客ID
        ,xmvc.column_no                      AS column_no                     -- 3.コラム№
        ,sub_query1.item_code                AS item_code                     -- 4.品目コード(当月)
        ,sub_query2.item_code                AS last_item_code                -- 5.品目コード(前月)
-- == 2009/09/08 V1.3 Deleted START ===============================================================
--        ,sub_query1.short_name               AS item_short_name               -- 6.品目名称(当月)
--        ,sub_query2.short_name               AS last_item_short_name          -- 7.品目名称(前月)
-- == 2009/09/08 V1.3 Deleted END   ===============================================================
        ,sub_query1.item_id                  AS item_id                       -- 8.品目ID(当月)
        ,sub_query2.item_id                  AS last_item_id                  -- 9.品目ID(前月)
        ,sub_query1.primary_unit_of_measure  AS primary_uom_code              -- 10.基準単位(当月)
        ,sub_query2.primary_unit_of_measure  AS last_primary_uom_code         -- 11.基準単位(前月)
        ,xmvc.inventory_quantity             AS inventory_quantity            -- 12.基準在庫数(当月)
        ,xmvc.last_month_inventory_quantity  AS last_inventory_quantity       -- 13.基準在庫数(前月)
        ,xmvc.price                          AS price                         -- 14.単価(当月)
        ,xmvc.last_month_price               AS last_price                    -- 15.単価(前月)
        ,xmvc.hot_cold                       AS hot_cold                      -- 16.H/C値(当月)
        ,xmvc.last_month_hot_cold            AS last_hot_cold                 -- 17.H/C値(前月)
        ,xmvc.rack_quantity                  AS rack_quantity                 -- 18.ラック数
-- == 2011/09/29 V1.4 Added START   ===============================================================
        ,xmvc.dlv_date_1                     AS dlv_date1                     -- 28.納品日1
        ,xmvc.quantity_1                     AS quantity_1                    -- 29.本数1
        ,xmvc.dlv_date_2                     AS dlv_date2                     -- 30.納品日2
        ,xmvc.quantity_2                     AS quantity_2                    -- 31.本数2
        ,xmvc.dlv_date_3                     AS dlv_date3                     -- 32.納品日3
        ,xmvc.quantity_3                     AS quantity_3                    -- 33.本数3
        ,xmvc.dlv_date_4                     AS dlv_date4                     -- 34.納品日4
        ,xmvc.quantity_4                     AS quantity_4                    -- 35.本数4
        ,xmvc.dlv_date_5                     AS dlv_date_5                    -- 36.納品日5
        ,xmvc.quantity_5                     AS quantity_5                    -- 37.本数5
        ,xmvc.column_change_date             AS column_change_date            -- 38.コラム変更日
-- == 2011/09/29 V1.4 Added END     ===============================================================
        ,xmvc.created_by                     AS created_by                    -- 23.作成者
        ,xmvc.creation_date                  AS creation_date                 -- 24.作成日
        ,xmvc.last_updated_by                AS last_updated_by               -- 25.最終更新者
        ,xmvc.last_update_date               AS last_update_date              -- 26.最終更新日
        ,xmvc.last_update_login              AS last_update_login             -- 27.最終更新ログイン
FROM     xxcoi_mst_vd_column                 xmvc                             -- VDコラムマスタ
-- == 2009/09/08 V1.3 Deleted START ===============================================================
--        ,(SELECT msib.segment1          AS item_code
--                ,ximb.item_short_name   AS short_name
--                ,msib.inventory_item_id AS item_id
--                ,msib.primary_uom_code  AS primary_unit_of_measure
--          FROM   mtl_system_items_b   msib
--                ,ic_item_mst_b        iimb
--                ,xxcmn_item_mst_b     ximb
--                ,xxcmm_system_items_b xsib
--          WHERE  msib.segment1 = iimb.item_no
--          AND    msib.organization_id = xxcoi_common_pkg.get_organization_id('S01')
--          AND    iimb.item_id = ximb.item_id
--          AND    iimb.item_id = xsib.item_id 
--          AND    iimb.attribute26 = '1')     sub_query1                       -- 2.品目情報サブクエリー1
--        ,(SELECT msib.segment1          AS item_code
--                ,ximb.item_short_name   AS short_name
--                ,msib.inventory_item_id AS item_id
--                ,msib.primary_uom_code  AS primary_unit_of_measure
--          FROM   mtl_system_items_b   msib
--                ,ic_item_mst_b        iimb
--                ,xxcmn_item_mst_b     ximb
--                ,xxcmm_system_items_b xsib
--          WHERE  msib.segment1 = iimb.item_no
--          AND    msib.organization_id = xxcoi_common_pkg.get_organization_id('S01')
--          AND    iimb.item_id = ximb.item_id
--          AND    iimb.item_id = xsib.item_id 
--          AND    iimb.attribute26 = '1')     sub_query2                       -- 3.品目情報サブクエリー2
        ,(SELECT msib.segment1          AS item_code
                ,msib.inventory_item_id AS item_id
                ,msib.primary_uom_code  AS primary_unit_of_measure
          FROM   mtl_system_items_b   msib
                ,ic_item_mst_b        iimb
                ,xxcmm_system_items_b xsib
          WHERE  msib.segment1 = iimb.item_no
          AND    msib.organization_id = xxcoi_common_pkg.get_organization_id('Z99')
          AND    iimb.item_id = xsib.item_id 
          AND    iimb.attribute26 = '1')     sub_query1                       -- 2.品目情報サブクエリー1
        ,(SELECT msib.segment1          AS item_code
                ,msib.inventory_item_id AS item_id
                ,msib.primary_uom_code  AS primary_unit_of_measure
          FROM   mtl_system_items_b   msib
                ,ic_item_mst_b        iimb
                ,xxcmm_system_items_b xsib
          WHERE  msib.segment1 = iimb.item_no
          AND    msib.organization_id = xxcoi_common_pkg.get_organization_id('Z99')
          AND    iimb.item_id = xsib.item_id 
          AND    iimb.attribute26 = '1')     sub_query2                       -- 3.品目情報サブクエリー2
-- == 2009/09/08 V1.3 Deleted END   ===============================================================
WHERE    xmvc.item_id                        = sub_query1.item_id(+)
AND      xmvc.last_month_item_id             = sub_query2.item_id(+)
-- == 2009/09/08 V1.3 Deleted START ===============================================================
--ORDER BY xmvc.customer_id, xmvc.column_no
-- == 2009/09/08 V1.3 Deleted END   ===============================================================
/
COMMENT ON TABLE xxcoi_vd_col_m_mtc_v IS 'VDコラムマスタメンテナンス画面ビュー'
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.vd_column_mst_id              IS 'VDコラムマスタID';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.customer_id                   IS '顧客ID';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.column_no                     IS 'コラム№';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.item_code                     IS '品目コード(当月)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_item_code                IS '品目コード(前月)';
/
-- == 2009/09/08 V1.3 Deleted START ===============================================================
--COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.item_name                     IS '品目名称(当月)';
--/
--COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_item_name                IS '品目名称(前月)';
--/
-- == 2009/09/08 V1.3 Deleted END   ===============================================================
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.item_id                       IS '品目ID(当月)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_item_id                  IS '品目ID(前月)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.primary_uom_code              IS '基準単位(当月)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_primary_uom_code         IS '基準単位(前月)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.inventory_quantity            IS '基準在庫数(当月)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_inventory_quantity       IS '基準在庫数(前月)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.price                         IS '単価(当月)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_price                    IS '単価(前月)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.hot_cold                      IS 'H/C値(当月)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_hot_cold                 IS 'H/C値(前月)';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.rack_quantity                 IS 'ラック数';
/
-- == 2011/09/29 V1.4 Added   START ===============================================================
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.dlv_date_1                    IS '納品日1';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.quantity_1                    IS '本数1';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.dlv_date_2                    IS '納品日2';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.quantity_2                    IS '本数2';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.dlv_date_3                    IS '納品日3';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.quantity_3                    IS '本数3';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.dlv_date_4                    IS '納品日4';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.quantity_4                    IS '本数4';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.dlv_date_5                    IS '納品日5';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.quantity_5                    IS '本数5';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.column_change_date            IS 'コラム変更日';
/
-- == 2011/09/29 V1.4 Added   END   ===============================================================
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.created_by                    IS '作成者';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.creation_date                 IS '作成日';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_updated_by               IS '最終更新者';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_update_date              IS '最終更新日';
/
COMMENT ON COLUMN xxcoi_vd_col_m_mtc_v.last_update_login             IS '最終更新ログイン';
/
