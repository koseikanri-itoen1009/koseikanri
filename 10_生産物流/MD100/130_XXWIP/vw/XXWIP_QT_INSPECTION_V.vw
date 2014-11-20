CREATE OR REPLACE VIEW apps.xxwip_qt_inspection_v
(
  row_id
, qt_inspect_req_no               -- 検査依頼No
, vendor_line                     -- 仕入先コード/ラインNo
, vendor_line_name                -- 仕入先/ライン名称
, item_id                         -- 品目ID
, item_no                         -- 品目コード
, item_name                       -- 品目名称
, lot_id                          -- ロットID
, lot_no                          -- ロットNo
, product_date                    -- 製造日
, unique_sign                     -- 固有記号
, use_by_date                     -- 賞味期限
, qt_effect1                      -- 結果１
, qt_effect1_desc                 -- 結果１名称
, inspect_due_date1               -- 検査予定日１
, test_date1                      -- 検査日１
, qt_effect2                      -- 結果２
, qt_effect2_desc                 -- 結果２名称
, inspect_due_date2               -- 検査予定日２
, test_date2                      -- 検査日２
, qt_effect3                      -- 結果３
, qt_effect3_desc                 -- 結果３名称
, inspect_due_date3               -- 検査予定日３
, test_date3                      -- 検査日３
, remarks_column                  -- 備考
, qty                             -- 数量
, inspection_times                -- 検査回数
, order_times                     -- 発注回数
, inspect_period                  -- 検査期間
, inspect_class                   -- 検査種別
, prod_dely_date                  -- 生産/納入日
, division                        -- 区分
, batch_po_id                     -- 番号
, created_by                      -- 作成者
, creation_date                   -- 作成日
, last_updated_by                 -- 最終更新者
, last_update_date                -- 最終更新日
, last_update_login               -- 最終更新ログイン
, request_id                      -- 要求ID
, program_application_id          -- コンカレント・プログラム・アプリケーションID
, program_id                      -- コンカレント・プログラムID
, program_update_date             -- プログラム更新日
, lot_last_update_date            -- ロットマスタ最終更新日
)
AS
  SELECT
    xqi.rowid                           row_id
  , xqi.qt_inspect_req_no               qt_inspect_req_no               -- 検査依頼No
  , xqi.vendor_line                     vendor_line                     -- 仕入先コード/ラインNo
  , grv.attribute1                      vendor_line_name                -- 仕入先/ライン名称
  , xqi.item_id                         item_id                         -- 品目ID
  , xim2v.item_no                       item_no                         -- 品目コード
  , xim2v.item_short_name               item_name                       -- 品目名称
  , xqi.lot_id                          lot_id                          -- ロットID
  , ilm.lot_no                          lot_no                          -- ロットNo
-- 2008/07/24 H.Itou MOD START
--  , xqi.product_date                    product_date                    -- 製造日
--  , xqi.unique_sign                     unique_sign                     -- 固有記号
--  , xqi.use_by_date                     use_by_date                     -- 賞味期限
  , FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
                                        product_date                    -- 製造日
  , ilm.attribute2                      unique_sign                     -- 固有記号
  , FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                        use_by_date                     -- 賞味期限
-- 2008/07/24 H.Itou MOD END
  , xqi.qt_effect1                      qt_effect1                      -- 結果１
  , xlvv1.meaning                       qt_effect1_desc                 -- 結果１名称
  , xqi.inspect_due_date1               inspect_due_date1               -- 検査予定日１
  , xqi.test_date1                      test_date1                      -- 検査日１
  , xqi.qt_effect2                      qt_effect2                      -- 結果２
  , xlvv2.meaning                       qt_effect2_desc                 -- 結果２名称
  , xqi.inspect_due_date2               inspect_due_date2               -- 検査予定日２
  , xqi.test_date2                      test_date2                      -- 検査日２
  , xqi.qt_effect3                      qt_effect3                      -- 結果３
  , xlvv3.meaning                       qt_effect3_desc                 -- 結果３名称
  , xqi.inspect_due_date3               inspect_due_date3               -- 検査予定日３
  , xqi.test_date3                      test_date3                      -- 検査日３
  , ilm.attribute18                     remarks_column                  -- 備考
  , xqi.qty                             qty                             -- 数量
  , xim2v.judge_times                   inspection_times                -- 検査回数
  , xim2v.order_judge_times             order_times                     -- 発注回数
  , xqi.inspect_period                  inspect_period                  -- 検査期間
  , xqi.inspect_class                   inspect_class                   -- 検査種別
  , xqi.prod_dely_date                  prod_dely_date                  -- 生産/納入日
  , xqi.division                        division                        -- 区分
  , xqi.batch_po_id                     batch_po_id                     -- 番号
  , xqi.created_by                      created_by                      -- 作成者
  , xqi.creation_date                   creation_date                   -- 作成日
  , xqi.last_updated_by                 last_updated_by                 -- 最終更新者
  , xqi.last_update_date                last_update_date                -- 最終更新日
  , xqi.last_update_login               last_update_login               -- 最終更新ログイン
  , xqi.request_id                      request_id                      -- 要求ID
  , xqi.program_application_id          program_application_id          -- コンカレント・プログラム・アプリケーションID
  , xqi.program_id                      program_id                      -- コンカレント・プログラムID
  , xqi.program_update_date             program_update_date             -- プログラム更新日
  , ilm.last_update_date                lot_last_update_date            -- ロットマスタ最終更新日
  FROM
    xxcmn_lookup_values_v           xlvv1
  , xxcmn_lookup_values_v           xlvv2
  , xxcmn_lookup_values_v           xlvv3
  , gmd_routings_vl                 grv     -- 工順VIEW
  , xxcmn_item_mst2_v               xim2v   -- 品目
  , ic_lots_mst                     ilm     -- ロット
  , xxwip_qt_inspection             xqi     -- 品質検査依頼
  WHERE xlvv1.lookup_code (+)        = xqi.qt_effect1 
    AND xlvv1.lookup_type (+)        = 'XXWIP_QT_STATUS'
    AND xlvv2.lookup_code (+)        = xqi.qt_effect2
    AND xlvv2.lookup_type (+)        = 'XXWIP_QT_STATUS'
    AND xlvv3.lookup_code (+)        = xqi.qt_effect3
    AND xlvv3.lookup_type (+)        = 'XXWIP_QT_STATUS'
    AND grv.routing_no (+)           = xqi.vendor_line
    AND xim2v.item_id                = xqi.item_id
-- 2008/07/24 H.Itou MOD START
--    AND xim2v.start_date_active      <= TRUNC( xqi.product_date )
--    AND xim2v.end_date_active        >= TRUNC( xqi.product_date )
    AND xim2v.start_date_active      <= TRUNC( NVL( xqi.product_date, SYSDATE ) )
    AND xim2v.end_date_active        >= TRUNC( NVL( xqi.product_date, SYSDATE ) )
-- 2008/07/24 H.Itou MOD END
    AND ilm.lot_id                   = xqi.lot_id
    AND xqi.inspect_class            = '1'
--
  UNION ALL
--
  SELECT
    xqi.rowid                           row_id
  , xqi.qt_inspect_req_no               qt_inspect_req_no               -- 検査依頼No
  , xqi.vendor_line                     vendor_line                     -- 仕入先コード/ラインNo
  , xv.vendor_short_name                vendor_line_name                -- 仕入先/ライン名称
  , xqi.item_id                         item_id                         -- 品目ID
  , xim2v.item_no                       item_no                         -- 品目コード
  , xim2v.item_short_name               item_name                       -- 品目名称
  , xqi.lot_id                          lot_id                          -- ロットID
  , ilm.lot_no                          lot_no                          -- ロットNo
-- 2008/07/24 H.Itou MOD START
--  , xqi.product_date                    product_date                    -- 製造日
--  , xqi.unique_sign                     unique_sign                     -- 固有記号
--  , xqi.use_by_date                     use_by_date                     -- 賞味期限
  , FND_DATE.STRING_TO_DATE(ilm.attribute1,'YYYY/MM/DD')
                                        product_date                    -- 製造日
  , ilm.attribute2                      unique_sign                     -- 固有記号
  , FND_DATE.STRING_TO_DATE(ilm.attribute3,'YYYY/MM/DD')
                                        use_by_date                     -- 賞味期限
-- 2008/07/24 H.Itou MOD END
  , xqi.qt_effect1                      qt_effect1                      -- 結果１
  , xlvv1.meaning                       qt_effect1_desc                 -- 結果１名称
  , xqi.inspect_due_date1               inspect_due_date1               -- 検査予定日１
  , xqi.test_date1                      test_date1                      -- 検査日１
  , xqi.qt_effect2                      qt_effect2                      -- 結果２
  , xlvv2.meaning                       qt_effect2_desc                 -- 結果２名称
  , xqi.inspect_due_date2               inspect_due_date2               -- 検査予定日２
  , xqi.test_date2                      test_date2                      -- 検査日２
  , xqi.qt_effect3                      qt_effect3                      -- 結果３
  , xlvv3.meaning                       qt_effect3_desc                 -- 結果３名称
  , xqi.inspect_due_date3               inspect_due_date3               -- 検査予定日３
  , xqi.test_date3                      test_date3                      -- 検査日３
  , ilm.attribute18                     remarks_column                  -- 備考
  , xqi.qty                             qty                             -- 数量
  , xim2v.judge_times                   inspection_times                -- 検査回数
  , xim2v.order_judge_times             order_times                     -- 発注回数
  , xqi.inspect_period                  inspect_period                  -- 検査期間
  , xqi.inspect_class                   inspect_class                   -- 検査種別
  , xqi.prod_dely_date                  prod_dely_date                  -- 生産/納入日
  , xqi.division                        division                        -- 区分
  , xqi.batch_po_id                     batch_po_id                     -- 番号
  , xqi.created_by                      created_by                      -- 作成者
  , xqi.creation_date                   creation_date                   -- 作成日
  , xqi.last_updated_by                 last_updated_by                 -- 最終更新者
  , xqi.last_update_date                last_update_date                -- 最終更新日
  , xqi.last_update_login               last_update_login               -- 最終更新ログイン
  , xqi.request_id                      request_id                      -- 要求ID
  , xqi.program_application_id          program_application_id          -- コンカレント・プログラム・アプリケーションID
  , xqi.program_id                      program_id                      -- コンカレント・プログラムID
  , xqi.program_update_date             program_update_date             -- プログラム更新日
  , ilm.last_update_date                lot_last_update_date            -- ロットマスタ最終更新日
  FROM
    xxcmn_lookup_values_v           xlvv1
  , xxcmn_lookup_values_v           xlvv2
  , xxcmn_lookup_values_v           xlvv3
  , xxcmn_vendors                   xv      -- 仕入先アドオンマスタ
  , xxcmn_vendors2_v                xv2v    -- 仕入先マスタVIEW
  , xxcmn_item_mst2_v               xim2v   -- 品目
  , ic_lots_mst                     ilm     -- ロット
  , xxwip_qt_inspection             xqi     -- 品質検査依頼
  WHERE xlvv1.lookup_code (+)        = xqi.qt_effect1 
    AND xlvv1.lookup_type (+)        = 'XXWIP_QT_STATUS'
    AND xlvv2.lookup_code (+)        = xqi.qt_effect2
    AND xlvv2.lookup_type (+)        = 'XXWIP_QT_STATUS'
    AND xlvv3.lookup_code (+)        = xqi.qt_effect3
    AND xlvv3.lookup_type (+)        = 'XXWIP_QT_STATUS'
    AND xv.vendor_id (+)             = xv2v.vendor_id
    AND (
             ( xv.vendor_id IS NULL )
          OR ( xv.start_date_active = (
                 SELECT MAX( xv2.start_date_active )
                 FROM xxcmn_vendors  xv2
                 WHERE xv2.vendor_id (+) = xv2v.vendor_id
               )
             )
        )
    AND xv2v.segment1 (+)            = xqi.vendor_line
-- 変更 START 2008/04/25 Oikawa
-- 2008/07/24 H.Itou MOD START
--    AND xv2v.start_date_active (+)   <= TRUNC( xqi.product_date )
--    AND xv2v.end_date_active (+)     >= TRUNC( xqi.product_date )
    AND xv2v.start_date_active (+)   <= TRUNC( NVL( xqi.product_date, SYSDATE ) )
    AND xv2v.end_date_active (+)     >= TRUNC( NVL( xqi.product_date, SYSDATE ) )
-- 2008/07/24 H.Itou MOD END
--    AND xv2v.start_date_active       <= TRUNC( xqi.product_date )
--    AND xv2v.end_date_active         >= TRUNC( xqi.product_date )
-- 変更 END
    AND xim2v.item_id                = xqi.item_id
-- 2008/07/24 H.Itou MOD START
--    AND xim2v.start_date_active      <= TRUNC( xqi.product_date )
--    AND xim2v.end_date_active        >= TRUNC( xqi.product_date )
    AND xim2v.start_date_active      <= TRUNC( NVL( xqi.product_date, SYSDATE ) )
    AND xim2v.end_date_active        >= TRUNC( NVL( xqi.product_date, SYSDATE ) )
-- 2008/07/24 H.Itou MOD END
    AND ilm.lot_id                   = xqi.lot_id
    AND xqi.inspect_class            = '2'
/
