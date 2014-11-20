CREATE OR REPLACE VIEW xxinv_stc_trans_p0_v 
(
-- 2008/12/07 N.Yoshida start
--  ownership_code
  po_trans_id
 ,ownership_code
-- 2008/12/07 N.Yoshida end
 ,inventory_location_id
 ,item_id
 ,lot_no
 ,manufacture_date
 ,uniqe_sign
 ,expiration_date
 ,arrival_date
 ,leaving_date
 ,status
 ,reason_code
 ,reason_code_name
 ,voucher_no
 ,ukebaraisaki_name
 ,deliver_to_name
 ,stock_quantity
 ,leaving_quantity
) 
AS 
  ------------------------------------------------------------------------
  -- 入庫予定
  ------------------------------------------------------------------------
  -- 発注受入予定
-- 2008/12/07 N.Yoshida start
--    SELECT iwm_in_po.attribute1                          AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_po.attribute1                          AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_po.inventory_location_id               AS inventory_location_id
        ,iimb_in_po.item_id                            AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
        ,TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) AS arrival_date
        ,TO_DATE( pha_in_po.attribute4, 'YYYY/MM/DD' ) AS leaving_date
        ,'1'                                           AS status        -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,pha_in_po.segment1                            AS voucher_no
        ,xv_in_po.vendor_name                          AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,pla_in_po.quantity                            AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   po_headers_all          pha_in_po                        -- 発注ヘッダ
        ,po_lines_all            pla_in_po                        -- 発注明細
        ,po_vendors              pv_in_po                         -- 仕入先マスタ
        ,xxcmn_vendors           xv_in_po                         -- 仕入先アドオンマスタ
        ,ic_whse_mst             iwm_in_po                        -- OPM倉庫マスタ
        ,mtl_item_locations      mil_in_po                        -- OPM保管場所マスタ
        ,ic_item_mst_b           iimb_in_po                       -- OPM品目マスタ
        ,mtl_system_items_b      msib_in_po                       -- 品目マスタ
        ,(SELECT xrpm_in_po.new_div_invent
                ,flv_in_po.meaning 
          FROM   xxcmn_rcv_pay_mst       xrpm_in_po               -- 受払区分アドオンマスタ
                ,fnd_lookup_values       flv_in_po                -- クイックコード
          WHERE  flv_in_po.lookup_type           = 'XXCMN_NEW_DIVISION'
          AND    flv_in_po.language              = 'JA'
          AND    flv_in_po.lookup_code           = xrpm_in_po.new_div_invent
          AND    xrpm_in_po.doc_type             = 'PORC'
          AND    xrpm_in_po.source_document_code = 'PO'
          AND    xrpm_in_po.use_div_invent       = 'Y'
          AND    xrpm_in_po.transaction_type     = 'DELIVER'
         ) xrpm
  WHERE  pha_in_po.po_header_id         = pla_in_po.po_header_id
-- 2008/11/26 Upd Y.Kawano Start
--  AND    pha_in_po.attribute4          <= TO_CHAR( TRUNC( SYSDATE ), 'YYYY/MM/DD' )
-- 2008/11/26 Upd Y.Kawano End
  AND    pha_in_po.attribute1          IN ( '20'                 -- 発注作成済
                                           ,'25' )               -- 受入あり
  AND    pla_in_po.attribute13          = 'N'                    -- 未承諾
  AND    pla_in_po.cancel_flag         <> 'Y'
  AND    pla_in_po.item_id              = msib_in_po.inventory_item_id
  AND    iimb_in_po.item_no             = msib_in_po.segment1
  AND    msib_in_po.organization_id     = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    pha_in_po.attribute5           = mil_in_po.segment1
  AND    pha_in_po.vendor_id            = pv_in_po.vendor_id
  AND    pv_in_po.vendor_id             = xv_in_po.vendor_id
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    pv_in_po.end_date_active      IS NULL
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xv_in_po.start_date_active    <= TRUNC( SYSDATE )
  AND    xv_in_po.end_date_active      >= TRUNC( SYSDATE )
  AND    iwm_in_po.mtl_organization_id  = mil_in_po.organization_id
  UNION ALL
  -- 移動入庫予定(指示 積送あり)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_xf.attribute1                          AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_xf.attribute1                          AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_xf.inventory_location_id               AS inventory_location_id
        ,xmld_in_xf.item_id                            AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xmrih_in_xf.schedule_arrival_date             AS arrival_date
--        ,xmrih_in_xf.schedule_ship_date                AS leaving_date
        ,TRUNC(xmrih_in_xf.schedule_arrival_date)      AS arrival_date
        ,TRUNC(xmrih_in_xf.schedule_ship_date)         AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status         -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_in_xf.mov_num                           AS voucher_no
        ,mil2_in_xf.description                        AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,xmld_in_xf.actual_quantity                    AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_in_xf                  -- 移動依頼/指示ヘッダ(アドオン)
        ,xxinv_mov_req_instr_lines    xmril_in_xf                  -- 移動依頼/指示明細(アドオン)
        ,xxinv_mov_lot_details        xmld_in_xf                   -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_in_xf                    -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_xf                    -- OPM保管場所マスタ
        ,mtl_item_locations           mil2_in_xf                   -- OPM保管場所マスタ
        ,(SELECT xrpm_in_xf.new_div_invent
                ,flv_in_xf.meaning 
          FROM   xxcmn_rcv_pay_mst       xrpm_in_xf               -- 受払区分アドオンマスタ
                ,fnd_lookup_values       flv_in_xf                -- クイックコード
          WHERE  flv_in_xf.lookup_type     = 'XXCMN_NEW_DIVISION'
          AND    flv_in_xf.language        = 'JA'
          AND    flv_in_xf.lookup_code     = xrpm_in_xf.new_div_invent
          AND    xrpm_in_xf.doc_type       = 'XFER'               -- 移動積送あり
          AND    xrpm_in_xf.use_div_invent = 'Y'
          AND    xrpm_in_xf.rcv_pay_div    = '1'                  -- 受入
         ) xrpm
  WHERE  xmrih_in_xf.mov_hdr_id             = xmril_in_xf.mov_hdr_id
  AND    xmrih_in_xf.ship_to_locat_id       = mil_in_xf.inventory_location_id
  AND    iwm_in_xf.mtl_organization_id      = mil_in_xf.organization_id
  AND    xmrih_in_xf.shipped_locat_id       = mil2_in_xf.inventory_location_id
  AND    xmld_in_xf.mov_line_id             = xmril_in_xf.mov_line_id
  AND    xmld_in_xf.document_type_code      = '20'                 -- 移動
  AND    xmld_in_xf.record_type_code        = '10'                 -- 指示
  AND    xmld_in_xf.lot_id                  = 0
-- 2008/11/26 Upd Y.Kawano Start
--  AND    xmrih_in_xf.schedule_arrival_date <= TRUNC( SYSDATE )
-- 2008/11/26 Upd Y.Kawano End
  AND    xmrih_in_xf.mov_type               = '1'
  AND    xmrih_in_xf.comp_actual_flg        = 'N'                  -- 実績未計上
  AND    xmrih_in_xf.status                IN ( '02'               -- 依頼済
                                               ,'03' )             -- 調整中
  AND    xmril_in_xf.delete_flg             = 'N'                  -- OFF
  UNION ALL
  -- 移動入庫予定(指示 積送なし)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_tr.attribute1                          AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_tr.attribute1                          AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_tr.inventory_location_id               AS inventory_location_id
        ,xmld_in_tr.item_id                            AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xmrih_in_tr.schedule_arrival_date             AS arrival_date
--        ,xmrih_in_tr.schedule_ship_date                AS leaving_date
        ,TRUNC(xmrih_in_tr.schedule_arrival_date)      AS arrival_date
        ,TRUNC(xmrih_in_tr.schedule_ship_date)         AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status      -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_in_tr.mov_num                           AS voucher_no
        ,mil2_in_tr.description                        AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,xmld_in_tr.actual_quantity                    AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_in_tr               -- 移動依頼/指示ヘッダ(アドオン)
        ,xxinv_mov_req_instr_lines    xmril_in_tr               -- 移動依頼/指示明細(アドオン)
        ,xxinv_mov_lot_details        xmld_in_tr                -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_in_tr                    -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_tr                    -- OPM保管場所マスタ
        ,mtl_item_locations           mil2_in_tr                   -- OPM保管場所マスタ
        ,(SELECT xrpm_in_tr.new_div_invent
                ,flv_in_tr.meaning 
          FROM   xxcmn_rcv_pay_mst       xrpm_in_tr               -- 受払区分アドオンマスタ
                ,fnd_lookup_values       flv_in_tr                -- クイックコード
          WHERE  flv_in_tr.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_tr.language                 = 'JA'
          AND    flv_in_tr.lookup_code              = xrpm_in_tr.new_div_invent
          AND    xrpm_in_tr.doc_type                = 'TRNI'            -- 移動積送なし
          AND    xrpm_in_tr.use_div_invent          = 'Y'
          AND    xrpm_in_tr.rcv_pay_div             = '1'               -- 受入
         ) xrpm
  WHERE  xmrih_in_tr.mov_hdr_id             = xmril_in_tr.mov_hdr_id
  AND    xmrih_in_tr.ship_to_locat_id       = mil_in_tr.inventory_location_id
  AND    iwm_in_tr.mtl_organization_id      = mil_in_tr.organization_id
  AND    xmrih_in_tr.shipped_locat_id       = mil2_in_tr.inventory_location_id
  AND    xmld_in_tr.mov_line_id             = xmril_in_tr.mov_line_id
  AND    xmld_in_tr.document_type_code      = '20'              -- 移動
  AND    xmld_in_tr.record_type_code        = '10'              -- 指示
  AND    xmld_in_tr.lot_id                  = 0
-- 2008/11/26 Upd Y.Kawano Start
--  AND    xmrih_in_tr.schedule_arrival_date <= TRUNC( SYSDATE )
-- 2008/11/26 Upd Y.Kawano End
  AND    xmrih_in_tr.mov_type               = '2'
  AND    xmrih_in_tr.comp_actual_flg        = 'N'               -- 実績未計上
  AND    xmrih_in_tr.status                IN ( '02'            -- 依頼済
                                               ,'03' )          -- 調整中
  AND    xmril_in_tr.delete_flg             = 'N'               -- OFF
  UNION ALL
  -- 移動入庫予定(出庫報告有 積送あり)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_xf20.attribute1                        AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_xf20.attribute1                        AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_xf20.inventory_location_id             AS inventory_location_id
        ,xmld_in_xf20.item_id                          AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xmrih_in_xf20.schedule_arrival_date             AS arrival_date
--        ,xmrih_in_xf20.schedule_ship_date                AS leaving_date
        ,TRUNC(xmrih_in_xf20.schedule_arrival_date)    AS arrival_date
        ,TRUNC(xmrih_in_xf20.schedule_ship_date)       AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status         -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_in_xf20.mov_num                         AS voucher_no
        ,mil2_in_xf20.description                      AS deliver_to_name
        ,NULL                                          AS deliver_to_name
        ,xmld_in_xf20.actual_quantity                  AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_in_xf20                -- 移動依頼/指示ヘッダ(アドオン)
        ,xxinv_mov_req_instr_lines    xmril_in_xf20                -- 移動依頼/指示明細(アドオン)
        ,xxinv_mov_lot_details        xmld_in_xf20                 -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_in_xf20                    -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_xf20                    -- OPM保管場所マスタ
        ,mtl_item_locations           mil2_in_xf20                   -- OPM保管場所マスタ
        ,(SELECT xrpm_in_xf20.new_div_invent
                ,flv_in_xf20.meaning 
          FROM   xxcmn_rcv_pay_mst       xrpm_in_xf20               -- 受払区分アドオンマスタ
                ,fnd_lookup_values       flv_in_xf20                -- クイックコード
          WHERE  flv_in_xf20.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_xf20.language                 = 'JA'
          AND    flv_in_xf20.lookup_code              = xrpm_in_xf20.new_div_invent
          AND    xrpm_in_xf20.doc_type                = 'XFER'             -- 移動積送あり
          AND    xrpm_in_xf20.use_div_invent          = 'Y'
          AND    xrpm_in_xf20.rcv_pay_div             = '1'                -- 受入
         ) xrpm
  WHERE  xmrih_in_xf20.mov_hdr_id             = xmril_in_xf20.mov_hdr_id
  AND    xmrih_in_xf20.ship_to_locat_id       = mil_in_xf20.inventory_location_id
  AND    iwm_in_xf20.mtl_organization_id      = mil_in_xf20.organization_id
  AND    xmrih_in_xf20.shipped_locat_id       = mil2_in_xf20.inventory_location_id
  AND    xmld_in_xf20.mov_line_id             = xmril_in_xf20.mov_line_id
  AND    xmld_in_xf20.document_type_code      = '20'               -- 移動
  AND    xmld_in_xf20.record_type_code        = '20'               -- 出庫実績
  AND    xmld_in_xf20.lot_id                  = 0
-- 2008/11/26 Upd Y.Kawano Start
--  AND    xmrih_in_xf20.schedule_arrival_date <= TRUNC( SYSDATE )
-- 2008/11/26 Upd Y.Kawano End
  AND    xmrih_in_xf20.mov_type               = '1'  -- 積送あり
  AND    xmrih_in_xf20.comp_actual_flg        = 'N'                -- 実績未計上
  AND    xmrih_in_xf20.status                 = '04'               -- 出庫報告有
  AND    xmril_in_xf20.delete_flg             = 'N'                -- OFF
-- 2008/12/24 #752 Y.Yamamoto add start
  UNION ALL
  -- 移動入庫予定(出庫報告有 積送なし)
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_tr20.attribute1                        AS ownership_code
        ,mil_in_tr20.inventory_location_id             AS inventory_location_id
        ,xmld_in_tr20.item_id                          AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xmrih_in_tr20.schedule_arrival_date             AS arrival_date
--        ,xmrih_in_tr20.schedule_ship_date                AS leaving_date
        ,TRUNC(xmrih_in_tr20.schedule_arrival_date)    AS arrival_date
        ,TRUNC(xmrih_in_tr20.schedule_ship_date)       AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status         -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_in_tr20.mov_num                         AS voucher_no
        ,mil2_in_tr20.description                      AS deliver_to_name
        ,NULL                                          AS deliver_to_name
        ,xmld_in_tr20.actual_quantity                  AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_in_tr20                -- 移動依頼/指示ヘッダ(アドオン)
        ,xxinv_mov_req_instr_lines    xmril_in_tr20                -- 移動依頼/指示明細(アドオン)
        ,xxinv_mov_lot_details        xmld_in_tr20                 -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_in_tr20                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_tr20                  -- OPM保管場所マスタ
        ,mtl_item_locations           mil2_in_tr20                 -- OPM保管場所マスタ
        ,(SELECT xrpm_in_tr20.new_div_invent
                ,flv_in_tr20.meaning 
          FROM   xxcmn_rcv_pay_mst       xrpm_in_tr20               -- 受払区分アドオンマスタ
                ,fnd_lookup_values       flv_in_tr20                -- クイックコード
          WHERE  flv_in_tr20.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_tr20.language                 = 'JA'
          AND    flv_in_tr20.lookup_code              = xrpm_in_tr20.new_div_invent
          AND    xrpm_in_tr20.doc_type                = 'TRNI'             -- 移動積送なし
          AND    xrpm_in_tr20.use_div_invent          = 'Y'
          AND    xrpm_in_tr20.rcv_pay_div             = '1'                -- 受入
         ) xrpm
  WHERE  xmrih_in_tr20.mov_hdr_id             = xmril_in_tr20.mov_hdr_id
  AND    xmrih_in_tr20.ship_to_locat_id       = mil_in_tr20.inventory_location_id
  AND    iwm_in_tr20.mtl_organization_id      = mil_in_tr20.organization_id
  AND    xmrih_in_tr20.shipped_locat_id       = mil2_in_tr20.inventory_location_id
  AND    xmld_in_tr20.mov_line_id             = xmril_in_tr20.mov_line_id
  AND    xmld_in_tr20.document_type_code      = '20'               -- 移動
  AND    xmld_in_tr20.record_type_code        = '20'               -- 出庫実績
  AND    xmld_in_tr20.lot_id                  = 0
  AND    xmrih_in_tr20.mov_type               = '2'                -- 積送なし
  AND    xmrih_in_tr20.comp_actual_flg        = 'N'                -- 実績未計上
  AND    xmrih_in_tr20.status                 = '04'               -- 出庫報告有
  AND    xmril_in_tr20.delete_flg             = 'N'                -- OFF
-- 2008/12/24 #752 Y.Yamamoto add end
  UNION ALL
  -- 生産入庫予定
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_pr.attribute1                          AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_pr.attribute1                          AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_pr.inventory_location_id               AS inventory_location_id
        ,gmd_in_pr.item_id                             AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,gbh_in_pr.plan_start_date                     AS arrival_date
--        ,gbh_in_pr.plan_start_date                     AS leaving_date
        ,TRUNC(gbh_in_pr.plan_start_date)              AS arrival_date
        ,TRUNC(gbh_in_pr.plan_start_date)              AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status       -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_in_pr.batch_no                            AS voucher_no
        ,grt_in_pr.routing_desc                        AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
-- 2009/01/16 D.Nihei update start 本番障害#1033
---- 2008/11/19 Y.Yamamoto v1.2 update start
----        ,gmd_in_pr.plan_qty                            AS stock_quantity
--        ,TO_NUMBER(NVL(gbh_in_pr.attribute23,'0'))     AS stock_quantity
---- 2008/11/19 Y.Yamamoto v1.2 update end
        ,NVL(xmld_in_pr.actual_quantity, 0)            AS stock_quantity
-- 2009/01/16 D.Nihei update end
        ,0                                             AS leaving_quantity
  FROM   gme_batch_header             gbh_in_pr                  -- 生産バッチ
        ,gme_material_details         gmd_in_pr                  -- 生産原料詳細
        ,gmd_routings_b               grb_in_pr                  -- 工順マスタ
        ,gmd_routings_tl              grt_in_pr                  -- 工順マスタ日本語
-- 2008/10/28 Y.Yamamoto v1.1 add start
        ,xxinv_mov_lot_details        xmld_in_pr                 -- 移動ロット詳細(アドオン)
-- 2008/10/28 Y.Yamamoto v1.1 add end
        ,ic_tran_pnd                  itp_in_pr                  -- OPM保留在庫トランザクション
        ,ic_whse_mst                  iwm_in_pr                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_pr                  -- OPM保管場所マスタ
        ,(SELECT xrpm_in_pr.new_div_invent
                ,flv_in_pr.meaning
                ,xrpm_in_pr.doc_type
                ,xrpm_in_pr.routing_class
                ,xrpm_in_pr.line_type
                ,xrpm_in_pr.hit_in_div
          FROM   xxcmn_rcv_pay_mst       xrpm_in_pr               -- 受払区分アドオンマスタ
                ,fnd_lookup_values       flv_in_pr                -- クイックコード
          WHERE  flv_in_pr.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_pr.language                 = 'JA'
          AND    flv_in_pr.lookup_code              = xrpm_in_pr.new_div_invent
          AND    xrpm_in_pr.doc_type                = 'PROD'
          AND    xrpm_in_pr.use_div_invent          = 'Y'
-- 2009/01/07 Y.Yamamoto #IS50 add start
          AND    xrpm_in_pr.routing_class          <> '70'
-- 2009/01/07 Y.Yamamoto #IS50 add end
         ) xrpm
  WHERE  gbh_in_pr.batch_id                 = gmd_in_pr.batch_id
  AND    gmd_in_pr.line_type               IN ( 1                -- 完成品
                                               ,2 )              -- 副産物
  AND    itp_in_pr.doc_type                 = xrpm.doc_type
  AND    itp_in_pr.doc_id                   = gmd_in_pr.batch_id
  AND    itp_in_pr.line_id                  = gmd_in_pr.material_detail_id
  AND    itp_in_pr.doc_line                 = gmd_in_pr.line_no
  AND    itp_in_pr.line_type                = gmd_in_pr.line_type
  AND    itp_in_pr.item_id                  = gmd_in_pr.item_id
  AND    itp_in_pr.completed_ind            = 0
  AND    itp_in_pr.delete_mark              = 0                  -- 有効チェック(OPM保留在庫)
  AND    grb_in_pr.attribute9               = mil_in_pr.segment1
-- 2008/10/28 Y.Yamamoto v1.1 update start
--  AND    EXISTS ( SELECT 1
--                  FROM   xxinv_mov_lot_details xmld
--                  WHERE  xmld.mov_line_id        = gmd_in_pr.material_detail_id
--                  AND    xmld.document_type_code = '40'    -- 生産指示
--                  AND    xmld.record_type_code   = '10'    -- 指示
--                  AND    ROWNUM = 1)
  AND    xmld_in_pr.mov_line_id             = gmd_in_pr.material_detail_id
  AND    xmld_in_pr.document_type_code      = '40'    -- 生産指示
  AND    xmld_in_pr.record_type_code        = '10'    -- 指示
  AND    xmld_in_pr.lot_id                  = 0
-- 2008/10/28 Y.Yamamoto v1.1 update start
-- 2008/11/19 Y.Yamamoto v1.2 update start
--  AND    NOT EXISTS( SELECT 1
--                     FROM   gme_batch_header gbh_in_pr_ex
--                     WHERE  gbh_in_pr_ex.batch_id      = gbh_in_pr.batch_id
--                     AND    gbh_in_pr_ex.batch_status IN ( 7     -- 完了
--                                                          ,8     -- クローズ
--                                                          ,-1 )) -- 取消
  AND    gbh_in_pr.batch_status            IN ( 1                  -- 保留
                                               ,2 )                -- WIP
-- 2008/11/19 Y.Yamamoto v1.2 update end
-- 2008/11/26 Y.Kawano Upd Start
--  AND    gbh_in_pr.plan_start_date         <= TRUNC( SYSDATE )
-- 2008/11/26 Y.Kawano Upd End
  AND    grb_in_pr.routing_id               = gbh_in_pr.routing_id
  AND    xrpm.routing_class                 = grb_in_pr.routing_class
  AND    xrpm.line_type                     = gmd_in_pr.line_type
  AND ((( gmd_in_pr.attribute5             IS NULL )
    AND ( xrpm.hit_in_div                  IS NULL ))
  OR   (( gmd_in_pr.attribute5             IS NOT NULL )
    AND ( xrpm.hit_in_div                   = gmd_in_pr.attribute5 )))
  AND    grb_in_pr.routing_id               = grt_in_pr.routing_id
  AND    grt_in_pr.language                 = 'JA'
  AND    iwm_in_pr.mtl_organization_id      = mil_in_pr.organization_id
-- 2009/01/07 Y.Yamamoto #IS50 add start
  UNION ALL
  -- 品目振替予定
  SELECT NULL                                         AS po_trans_id
        ,iwm_in_pr.attribute1                         AS ownership_code
        ,mil_in_pr.inventory_location_id              AS inventory_location_id
        ,xmld_in_pr.item_id                           AS item_id
        ,NULL                                         AS lot_no
        ,NULL                                         AS manufacture_date
        ,NULL                                         AS uniqe_sign
        ,NULL                                         AS expiration_date -- <---- ここまで共通
        ,TRUNC(gbh_in_pr.plan_start_date)             AS arrival_date
        ,TRUNC(gbh_in_pr.plan_start_date)             AS leaving_date
        ,'1'                                          AS status       -- 予定
        ,xrpm.new_div_invent                          AS reason_code
        ,xrpm.meaning                                 AS reason_code_name
        ,gbh_in_pr.batch_no                           AS voucher_no
        ,grt_in_pr.routing_desc                       AS ukebaraisaki_name
        ,NULL                                         AS deliver_to_name
        ,xmld_in_pr.actual_quantity                   AS stock_quantity
        ,0                                            AS leaving_quantity
  FROM   gme_batch_header             gbh_in_pr                  -- 生産バッチ
        ,gme_material_details         gmd_in_pr                  -- 生産原料詳細
        ,gme_material_details         gmd_in_pr2                 -- 生産原料詳細
        ,xxinv_mov_lot_details        xmld_in_pr                 -- 移動ロット詳細(アドオン)
        ,gmd_routings_b               grb_in_pr                  -- 工順マスタ
        ,gmd_routings_tl              grt_in_pr                  -- 工順マスタ日本語
        ,ic_tran_pnd                  itp_in_pr                  -- OPM保留在庫トランザクション
        ,ic_whse_mst                  iwm_in_pr                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_pr                  -- OPM保管場所マスタ
        ,gmi_item_categories          gic
        ,mtl_categories_b             mcb
        ,gmi_item_categories          gic2
        ,mtl_categories_b             mcb2
        ,(SELECT xrpm_in_pr.new_div_invent
                ,flv_in_pr.meaning
                ,xrpm_in_pr.routing_class
                ,xrpm_in_pr.line_type
                ,xrpm_in_pr.hit_in_div
                ,xrpm_in_pr.doc_type
                ,xrpm_in_pr.item_div_origin
                ,xrpm_in_pr.item_div_ahead
          FROM   fnd_lookup_values flv_in_pr                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_in_pr                    -- 受払区分アドオンマスタ
          WHERE  flv_in_pr.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_pr.language                 = 'JA'
          AND    flv_in_pr.lookup_code              = xrpm_in_pr.new_div_invent
          AND    xrpm_in_pr.doc_type                = 'PROD'
          AND    xrpm_in_pr.use_div_invent          = 'Y'
          AND    xrpm_in_pr.routing_class           = '70'
         ) xrpm
  WHERE  gbh_in_pr.batch_id                 = gmd_in_pr.batch_id
  AND    gmd_in_pr.material_detail_id       = xmld_in_pr.mov_line_id
  AND    gmd_in_pr.line_type               IN ( 1                -- 完成品
                                               ,2 )              -- 副産物
  AND    itp_in_pr.doc_type                 = xrpm.doc_type
  AND    itp_in_pr.doc_id                   = gmd_in_pr.batch_id
  AND    itp_in_pr.line_id                  = gmd_in_pr.material_detail_id
  AND    itp_in_pr.doc_line                 = gmd_in_pr.line_no
  AND    itp_in_pr.line_type                = gmd_in_pr.line_type
  AND    itp_in_pr.item_id                  = gmd_in_pr.item_id
  AND    itp_in_pr.completed_ind            = 0
  AND    itp_in_pr.delete_mark              = 0                  -- 有効チェック(OPM保留在庫)
  AND    itp_in_pr.item_id                  = gic.item_id
  AND    gic.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb.category_id                    = gic.category_id
  AND    xrpm.item_div_ahead                = mcb.segment1
  AND    gmd_in_pr2.item_id                 = gic2.item_id
  AND    gic2.category_set_id               = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb2.category_id                   = gic.category_id
  AND    xrpm.item_div_origin               = mcb2.segment1
  AND    xmld_in_pr.document_type_code      = '40'
  AND    xmld_in_pr.record_type_code        = '10'
  AND    xmld_in_pr.lot_id                  = 0
  AND    grb_in_pr.attribute9               = mil_in_pr.segment1
  AND    iwm_in_pr.mtl_organization_id      = mil_in_pr.organization_id
  AND    gbh_in_pr.batch_status            IN ( 1                  -- 保留
                                                ,2 )                -- WIP
  AND    grb_in_pr.routing_id               = gbh_in_pr.routing_id
  AND    xrpm.routing_class                 = grb_in_pr.routing_class
  AND    xrpm.line_type                     = gmd_in_pr.line_type
  AND    gbh_in_pr.batch_id                 = gmd_in_pr2.batch_id
  AND    gmd_in_pr.batch_id                 = gmd_in_pr2.batch_id
  AND    gmd_in_pr2.line_type               = -1                  -- 投入品
  AND    grb_in_pr.routing_id               = grt_in_pr.routing_id
  AND    grt_in_pr.language                 = 'JA'
-- 2009/01/07 Y.Yamamoto #IS50 add end
  UNION ALL
  ------------------------------------------------------------------------
  -- 出庫予定
  ------------------------------------------------------------------------
  -- 移動出庫予定(指示 積送あり)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_xf.attribute1                         AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_xf.attribute1                         AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_xf.inventory_location_id              AS inventory_location_id
        ,xmld_out_xf.item_id                           AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xmrih_out_xf.schedule_arrival_date            AS arrival_date
--        ,xmrih_out_xf.schedule_ship_date               AS leaving_date
        ,TRUNC(xmrih_out_xf.schedule_arrival_date)     AS arrival_date
        ,TRUNC(xmrih_out_xf.schedule_ship_date)        AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status         -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_out_xf.mov_num                          AS voucher_no
        ,mil2_out_xf.description                       AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_xf.actual_quantity                   AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_out_xf                 -- 移動依頼/指示ヘッダ(アドオン)
        ,xxinv_mov_req_instr_lines    xmril_out_xf                 -- 移動依頼/指示明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_xf                  -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_out_xf                   -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_xf                   -- OPM保管場所マスタ
        ,mtl_item_locations           mil2_out_xf                  -- OPM保管場所マスタ
        ,(SELECT xrpm_out_xf.new_div_invent
                ,flv_out_xf.meaning
          FROM   fnd_lookup_values flv_out_xf                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_xf                    -- 受払区分アドオンマスタ
          WHERE  flv_out_xf.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_xf.language                 = 'JA'
          AND    flv_out_xf.lookup_code              = xrpm_out_xf.new_div_invent
          AND    xrpm_out_xf.doc_type                = 'XFER'              -- 移動積送あり
          AND    xrpm_out_xf.use_div_invent          = 'Y'
          AND    xrpm_out_xf.rcv_pay_div             = '-1'                -- 払出
         ) xrpm
  WHERE  xmrih_out_xf.mov_hdr_id             = xmril_out_xf.mov_hdr_id
  AND    xmrih_out_xf.shipped_locat_id       = mil_out_xf.inventory_location_id
  AND    iwm_out_xf.mtl_organization_id      = mil_out_xf.organization_id
  AND    xmrih_out_xf.ship_to_locat_id       = mil2_out_xf.inventory_location_id
  AND    xmld_out_xf.mov_line_id             = xmril_out_xf.mov_line_id
  AND    xmld_out_xf.document_type_code      = '20'                -- 移動
  AND    xmld_out_xf.record_type_code        = '10'                -- 指示
  AND    xmld_out_xf.lot_id                  = 0
-- 2008/11/26 Upd Y.Kawano Start
--  AND    xmrih_out_xf.schedule_ship_date    <= TRUNC( SYSDATE )
-- 2008/11/26 Upd Y.Kawano End
  AND    xmrih_out_xf.mov_type               = '1'
  AND    xmrih_out_xf.comp_actual_flg        = 'N'                 -- 実績未計上
  AND    xmrih_out_xf.status                IN ( '02'              -- 依頼済
                                                ,'03' )            -- 調整中
  AND    xmril_out_xf.delete_flg             = 'N'                 -- OFF
  UNION ALL
  -- 移動出庫予定(指示 積送なし)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_tr.attribute1                         AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_tr.attribute1                         AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_tr.inventory_location_id              AS inventory_location_id
        ,xmld_out_tr.item_id                           AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xmrih_out_tr.schedule_arrival_date            AS arrival_date
--        ,xmrih_out_tr.schedule_ship_date               AS leaving_date
        ,TRUNC(xmrih_out_tr.schedule_arrival_date)     AS arrival_date
        ,TRUNC(xmrih_out_tr.schedule_ship_date)        AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status       -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_out_tr.mov_num                          AS voucher_no
        ,mil2_out_tr.description                       AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_tr.actual_quantity                   AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_out_tr               -- 移動依頼/指示ヘッダ(アドオン)
        ,xxinv_mov_req_instr_lines    xmril_out_tr               -- 移動依頼/指示明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_tr                -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_out_tr                   -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_tr                   -- OPM保管場所マスタ
        ,mtl_item_locations           mil2_out_tr                  -- OPM保管場所マスタ
        ,(SELECT xrpm_out_tr.new_div_invent
                ,flv_out_tr.meaning
          FROM   fnd_lookup_values flv_out_tr                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_tr                    -- 受払区分アドオンマスタ
          WHERE  flv_out_tr.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_tr.language                 = 'JA'
          AND    flv_out_tr.lookup_code              = xrpm_out_tr.new_div_invent
          AND    xrpm_out_tr.doc_type                = 'TRNI'            -- 移動積送なし
          AND    xrpm_out_tr.use_div_invent          = 'Y'
          AND    xrpm_out_tr.rcv_pay_div             = '-1'              -- 払出
         ) xrpm
  WHERE  xmrih_out_tr.mov_hdr_id             = xmril_out_tr.mov_hdr_id
  AND    xmrih_out_tr.shipped_locat_id       = mil_out_tr.inventory_location_id
  AND    iwm_out_tr.mtl_organization_id      = mil_out_tr.organization_id
  AND    xmrih_out_tr.ship_to_locat_id       = mil2_out_tr.inventory_location_id
  AND    xmld_out_tr.mov_line_id             = xmril_out_tr.mov_line_id
  AND    xmld_out_tr.document_type_code      = '20'              -- 移動
  AND    xmld_out_tr.record_type_code        = '10'             -- 指示
  AND    xmld_out_tr.lot_id                  = 0
-- 2008/11/26 Upd Y.Kawano Start
--  AND    xmrih_out_tr.schedule_ship_date    <= TRUNC( SYSDATE )
-- 2008/11/26 Upd Y.Kawano End
  AND    xmrih_out_tr.mov_type               = '2'
  AND    xmrih_out_tr.comp_actual_flg        = 'N'               -- 実績未計上
  AND    xmrih_out_tr.status                IN ( '02'            -- 依頼済
                                                ,'03' )          -- 調整中
  AND    xmril_out_tr.delete_flg             = 'N'               -- OFF
  UNION ALL
  -- 移動出庫予定(入庫報告有 積送あり)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_xf20.attribute1                       AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_xf20.attribute1                       AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_xf20.inventory_location_id            AS inventory_location_id
        ,xmld_out_xf20.item_id                         AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xmrih_out_xf20.schedule_arrival_date          AS arrival_date
--        ,xmrih_out_xf20.schedule_ship_date             AS leaving_date
        ,TRUNC(xmrih_out_xf20.schedule_arrival_date)   AS arrival_date
        ,TRUNC(xmrih_out_xf20.schedule_ship_date)      AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status         -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_out_xf20.mov_num                        AS voucher_no
        ,mil2_out_xf20.description                     AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_xf20.actual_quantity                 AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_out_xf20                -- 移動依頼/指示ヘッダ(アドオン)
        ,xxinv_mov_req_instr_lines    xmril_out_xf20                -- 移動依頼/指示明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_xf20                 -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_out_xf20                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_xf20                  -- OPM保管場所マスタ
        ,mtl_item_locations           mil2_out_xf20                 -- OPM保管場所マスタ
        ,(SELECT xrpm_out_xf20.new_div_invent
                ,flv_out_xf20.meaning
          FROM   fnd_lookup_values flv_out_xf20                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_xf20                    -- 受払区分アドオンマスタ
          WHERE  flv_out_xf20.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_xf20.language                 = 'JA'
          AND    flv_out_xf20.lookup_code              = xrpm_out_xf20.new_div_invent
          AND    xrpm_out_xf20.doc_type                = 'XFER'             -- 移動積送あり
          AND    xrpm_out_xf20.use_div_invent          = 'Y'
          AND    xrpm_out_xf20.rcv_pay_div             = '-1'                -- 払出
         ) xrpm
  WHERE  xmrih_out_xf20.mov_hdr_id             = xmril_out_xf20.mov_hdr_id
  AND    xmrih_out_xf20.shipped_locat_id       = mil_out_xf20.inventory_location_id
  AND    iwm_out_xf20.mtl_organization_id      = mil_out_xf20.organization_id
  AND    xmrih_out_xf20.ship_to_locat_id       = mil2_out_xf20.inventory_location_id
  AND    xmld_out_xf20.mov_line_id             = xmril_out_xf20.mov_line_id
  AND    xmld_out_xf20.document_type_code      = '20'               -- 移動
  AND    xmld_out_xf20.record_type_code        = '30'               -- 入庫実績
  AND    xmld_out_xf20.lot_id                  = 0
-- 2008/11/26 Upd Y.Kawano Start
--  AND    xmrih_out_xf20.schedule_ship_date    <= TRUNC( SYSDATE )
-- 2008/11/26 Upd Y.Kawano End
  AND    xmrih_out_xf20.mov_type               = '1'  -- 積送あり
  AND    xmrih_out_xf20.comp_actual_flg        = 'N'                -- 実績未計上
  AND    xmrih_out_xf20.status                 = '05'               -- 入庫報告有
  AND    xmril_out_xf20.delete_flg             = 'N'                -- OFF
-- 2008/12/24 #752 Y.Yamamoto add start
  UNION ALL
  -- 移動出庫予定(入庫報告有 積送なし)
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_tr20.attribute1                       AS ownership_code
        ,mil_out_tr20.inventory_location_id            AS inventory_location_id
        ,xmld_out_tr20.item_id                         AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xmrih_out_tr20.schedule_arrival_date          AS arrival_date
--        ,xmrih_out_tr20.schedule_ship_date             AS leaving_date
        ,TRUNC(xmrih_out_tr20.schedule_arrival_date)   AS arrival_date
        ,TRUNC(xmrih_out_tr20.schedule_ship_date)      AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status         -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_out_tr20.mov_num                        AS voucher_no
        ,mil2_out_tr20.description                     AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_tr20.actual_quantity                 AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_out_tr20                -- 移動依頼/指示ヘッダ(アドオン)
        ,xxinv_mov_req_instr_lines    xmril_out_tr20                -- 移動依頼/指示明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_tr20                 -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_out_tr20                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_tr20                  -- OPM保管場所マスタ
        ,mtl_item_locations           mil2_out_tr20                 -- OPM保管場所マスタ
        ,(SELECT xrpm_out_tr20.new_div_invent
                ,flv_out_tr20.meaning
          FROM   fnd_lookup_values flv_out_tr20                     -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_tr20                    -- 受払区分アドオンマスタ
          WHERE  flv_out_tr20.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_tr20.language                 = 'JA'
          AND    flv_out_tr20.lookup_code              = xrpm_out_tr20.new_div_invent
          AND    xrpm_out_tr20.doc_type                = 'TRNI'             -- 移動積送なし
          AND    xrpm_out_tr20.use_div_invent          = 'Y'
          AND    xrpm_out_tr20.rcv_pay_div             = '-1'                -- 払出
         ) xrpm
  WHERE  xmrih_out_tr20.mov_hdr_id             = xmril_out_tr20.mov_hdr_id
  AND    xmrih_out_tr20.shipped_locat_id       = mil_out_tr20.inventory_location_id
  AND    iwm_out_tr20.mtl_organization_id      = mil_out_tr20.organization_id
  AND    xmrih_out_tr20.ship_to_locat_id       = mil2_out_tr20.inventory_location_id
  AND    xmld_out_tr20.mov_line_id             = xmril_out_tr20.mov_line_id
  AND    xmld_out_tr20.document_type_code      = '20'               -- 移動
  AND    xmld_out_tr20.record_type_code        = '30'               -- 入庫実績
  AND    xmld_out_tr20.lot_id                  = 0
  AND    xmrih_out_tr20.mov_type               = '2'                -- 積送なし
  AND    xmrih_out_tr20.comp_actual_flg        = 'N'                -- 実績未計上
  AND    xmrih_out_tr20.status                 = '05'               -- 入庫報告有
  AND    xmril_out_tr20.delete_flg             = 'N'                -- OFF
-- 2008/12/24 #752 Y.Yamamoto add end
  UNION ALL
  -- 受注出荷予定
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_om.attribute1                         AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_om.attribute1                         AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_om.inventory_location_id              AS inventory_location_id
        ,xmld_out_om.item_id                           AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xoha_out_om.schedule_arrival_date             AS arrival_date
--        ,xoha_out_om.schedule_ship_date                AS leaving_date
        ,TRUNC(xoha_out_om.schedule_arrival_date)      AS arrival_date
        ,TRUNC(xoha_out_om.schedule_ship_date)         AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status        -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om.request_no                        AS voucher_no
-- 2008/12/01 Upd Y.Kawano Start
--        ,hpat_out_om.attribute19                       AS ukebaraisaki_name
        ,xp_out_om.party_name                          AS ukebaraisaki_name
-- 2008/12/01 Upd Y.Kawano End
        ,xpas_out_om.party_site_name                   AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_om.actual_quantity                   AS leaving_quantity
  FROM   xxwsh_order_headers_all      xoha_out_om                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_out_om                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_om                 -- 移動ロット詳細(アドオン)
        ,oe_transaction_types_all     otta_out_om                 -- 受注タイプ
        ,ic_whse_mst                  iwm_out_om                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_om                  -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb2_out_om                -- OPM品目マスタ
        ,mtl_system_items_b           msib2_out_om                -- 品目マスタ
-- 2009/01/23 Upd N.Yoshida Start
--        ,hz_parties                   hpat_out_om
-- 2009/01/23 Upd N.Yoshida End
        ,hz_cust_accounts             hcsa_out_om
        ,hz_party_sites               hpas_out_om
        ,xxcmn_party_sites            xpas_out_om
        ,gmi_item_categories          gic_out_om
        ,mtl_categories_b             mcb_out_om
        ,(SELECT xrpm_out_om.new_div_invent
                ,flv_out_om.meaning
                ,xrpm_out_om.shipment_provision_div
                ,xrpm_out_om.ship_prov_rcv_pay_category
          FROM   fnd_lookup_values flv_out_om                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_om                    -- 受払区分アドオンマスタ
          WHERE  flv_out_om.lookup_type               = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om.language                  = 'JA'
          AND    flv_out_om.lookup_code               = xrpm_out_om.new_div_invent
          AND    xrpm_out_om.doc_type                 = 'OMSO'
          AND    xrpm_out_om.use_div_invent           = 'Y'
          AND    xrpm_out_om.shipment_provision_div   = '1'       -- 出荷依頼
          AND    xrpm_out_om.item_div_origin          = '5'
          AND    xrpm_out_om.item_div_ahead           = '5'
         ) xrpm
-- 2008/12/01 Upd Y.Kawano Start
        ,xxcmn_parties                xp_out_om
-- 2008/12/01 Upd Y.Kawano End
  WHERE  xoha_out_om.order_header_id                  = xola_out_om.order_header_id
  AND    xoha_out_om.deliver_from_id                  = mil_out_om.inventory_location_id
  AND    iwm_out_om.mtl_organization_id               = mil_out_om.organization_id
  AND    xola_out_om.request_item_id                  = msib2_out_om.inventory_item_id
  AND    iimb2_out_om.item_no                         = msib2_out_om.segment1
  AND    msib2_out_om.organization_id                 = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om.mov_line_id                      = xola_out_om.order_line_id
  AND    xmld_out_om.document_type_code               = '10'      -- 出荷依頼
  AND    xmld_out_om.record_type_code                 = '10'      -- 指示
  AND    xmld_out_om.lot_id                           = 0
  AND    xoha_out_om.req_status                       = '03'      -- 締め済
  AND    NVL( xoha_out_om.actual_confirm_class, 'N' ) = 'N'       -- 実績未計上
  AND    xoha_out_om.latest_external_flag             = 'Y'       -- ON
  AND    xola_out_om.delete_flag                      = 'N'       -- OFF
-- 2008/11/26 Upd Y.Kawano Start
--  AND    xoha_out_om.schedule_ship_date              <= TRUNC( SYSDATE )
-- 2008/11/26 Upd Y.Kawano End
  AND    xoha_out_om.order_type_id                    = otta_out_om.transaction_type_id
  AND    xrpm.shipment_provision_div                  = otta_out_om.attribute1
  AND    gic_out_om.item_id                           = iimb2_out_om.item_id
  AND    gic_out_om.category_id                       = mcb_out_om.category_id
  AND    gic_out_om.category_set_id                   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om.segment1                          = '5'
  AND   (xrpm.ship_prov_rcv_pay_category              = otta_out_om.attribute11
  OR     xrpm.ship_prov_rcv_pay_category             IS NULL)
-- 2009/01/23 Upd N.Yoshida Start
--  AND    xoha_out_om.customer_id                      = hpat_out_om.party_id
--  AND    hpat_out_om.party_id                         = hcsa_out_om.party_id
  AND    xoha_out_om.head_sales_branch                = hcsa_out_om.account_number
-- 2009/01/23 Upd N.Yoshida End
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    hpat_out_om.status                           = 'A'
--  AND    hcsa_out_om.status                           = 'A'
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xoha_out_om.deliver_to_id                    = hpas_out_om.party_site_id
  AND    hpas_out_om.party_site_id                    = xpas_out_om.party_site_id
  AND    hpas_out_om.party_id                         = xpas_out_om.party_id
  AND    hpas_out_om.location_id                      = xpas_out_om.location_id
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    hpas_out_om.status                           = 'A'
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xpas_out_om.start_date_active               <= TRUNC(SYSDATE)
  AND    xpas_out_om.end_date_active                 >= TRUNC(SYSDATE)
-- 2008/12/01 Upd Y.Kawano Start
-- 2009/01/23 Upd N.Yoshida Start
--  AND    hpat_out_om.party_id                         = xp_out_om.party_id
  AND    hcsa_out_om.party_id                         = xp_out_om.party_id
-- 2009/01/23 Upd N.Yoshida Start
  AND    xp_out_om.start_date_active                 <= TRUNC(SYSDATE)
  AND    xp_out_om.end_date_active                   >= TRUNC(SYSDATE)
-- 2008/12/01 Upd Y.Kawano End
  UNION ALL
  -- 有償出荷予定
  ------------------------------------------------------------------------
  -- 商品振替有償
  ------------------------------------------------------------------------
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_om2.attribute1                        AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_om2.attribute1                        AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_om2.inventory_location_id             AS inventory_location_id
        ,xmld_out_om2.item_id                          AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
-- 2008/10/23 Y.Yamamoto v1.1 update start
--        ,xoha_out_om2.schedule_arrival_date            AS arrival_date
--        ,NVL(xoha_out_om2.schedule_arrival_date
--            ,xoha_out_om2.schedule_ship_date)          AS arrival_date
-- 2008/10/23 Y.Yamamoto v1.1 update end
--        ,xoha_out_om2.schedule_ship_date               AS leaving_date
        ,NVL(TRUNC(xoha_out_om2.schedule_arrival_date)
            ,TRUNC(xoha_out_om2.schedule_ship_date))   AS arrival_date
        ,TRUNC(xoha_out_om2.schedule_ship_date)        AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status        -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2.request_no                       AS voucher_no
        ,xvsa_out_om2.vendor_site_name                 AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2.actual_quantity                  AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2.actual_quantity ) * -1
          ELSE
            xmld_out_om2.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_out_om2                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_om2                 -- 移動ロット詳細(アドオン)
        ,oe_transaction_types_all     otta_out_om2                 -- 受注タイプ
        ,ic_whse_mst                  iwm_out_om2                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_om2                  -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_out_om2                 -- OPM品目マスタ
        ,mtl_system_items_b           msib_out_om2                 -- 品目マスタ
        ,ic_item_mst_b                iimb2_out_om2                -- OPM品目マスタ
        ,mtl_system_items_b           msib2_out_om2                -- 品目マスタ
        ,gmi_item_categories          gic_out_om2
        ,mtl_categories_b             mcb_out_om2
        ,gmi_item_categories          gic2_out_om2
        ,mtl_categories_b             mcb2_out_om2
        ,xxcmn_vendor_sites_all       xvsa_out_om2
        ,(SELECT xrpm_out_om2.new_div_invent
                ,flv_out_om2.meaning
                ,xrpm_out_om2.shipment_provision_div
                ,xrpm_out_om2.ship_prov_rcv_pay_category
-- 2008/10/24 Y.Yamamoto v1.1 add start
                ,xrpm_out_om2.item_div_origin
                ,xrpm_out_om2.item_div_ahead
-- 2008/10/24 Y.Yamamoto v1.1 add end
          FROM   fnd_lookup_values flv_out_om2                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_om2                    -- 受払区分アドオンマスタ
          WHERE  flv_out_om2.lookup_type               = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2.language                  = 'JA'
          AND    flv_out_om2.lookup_code               = xrpm_out_om2.new_div_invent
          AND    xrpm_out_om2.doc_type                 = 'OMSO'
          AND    xrpm_out_om2.use_div_invent           = 'Y'
          AND    xrpm_out_om2.shipment_provision_div   = '2'       -- 支給依頼
          AND    xrpm_out_om2.item_div_origin          = '5'
          AND    xrpm_out_om2.item_div_ahead           = '5'
          AND    xrpm_out_om2.prod_div_origin         IS NOT NULL
          AND    xrpm_out_om2.prod_div_ahead          IS NOT NULL
         ) xrpm
  WHERE  xoha_out_om2.order_header_id                  = xola_out_om2.order_header_id
  AND    xoha_out_om2.deliver_from_id                  = mil_out_om2.inventory_location_id
  AND    iwm_out_om2.mtl_organization_id               = mil_out_om2.organization_id
  AND    xola_out_om2.shipping_inventory_item_id      <> xola_out_om2.request_item_id
  AND    xola_out_om2.request_item_id                  = msib_out_om2.inventory_item_id
  AND    iimb_out_om2.item_no                          = msib_out_om2.segment1
  AND    msib_out_om2.organization_id                  = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2.shipping_inventory_item_id       = msib2_out_om2.inventory_item_id
  AND    iimb2_out_om2.item_no                         = msib2_out_om2.segment1
  AND    msib2_out_om2.organization_id                 = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2.mov_line_id                      = xola_out_om2.order_line_id
  AND    xmld_out_om2.document_type_code               = '30'      -- 支給指示
  AND    xmld_out_om2.record_type_code                 = '10'      -- 指示
  AND    xmld_out_om2.lot_id                           = 0
  AND    xoha_out_om2.req_status                       = '07'      -- 受領済
  AND    NVL( xoha_out_om2.actual_confirm_class, 'N' ) = 'N'       -- 実績未計上
  AND    xoha_out_om2.latest_external_flag             = 'Y'       -- ON
  AND    xola_out_om2.delete_flag                      = 'N'       -- OFF
-- 2008/11/26 Upd Y.Kawano Start
--  AND    xoha_out_om2.schedule_ship_date              <= TRUNC( SYSDATE )
-- 2008/11/26 Upd Y.Kawano End
  AND    xoha_out_om2.order_type_id                    = otta_out_om2.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2.attribute1
  AND    gic_out_om2.item_id                           = iimb_out_om2.item_id
  AND    gic_out_om2.category_id                       = mcb_out_om2.category_id
  AND    gic_out_om2.category_set_id                   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2.segment1                          = '5'
  AND    gic2_out_om2.item_id                          = iimb2_out_om2.item_id
  AND    gic2_out_om2.category_id                      = mcb2_out_om2.category_id
  AND    gic2_out_om2.category_set_id                  = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb2_out_om2.segment1                         = '5'
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2.attribute11
  OR     xrpm.ship_prov_rcv_pay_category              IS NULL)
-- 2008/10/24 Y.Yamamoto v1.1 add start
  AND    xrpm.item_div_origin                          = mcb2_out_om2.segment1
  AND    xrpm.item_div_ahead                           = mcb_out_om2.segment1
-- 2008/10/24 Y.Yamamoto v1.1 add end
  AND    xvsa_out_om2.vendor_site_id                   = xoha_out_om2.vendor_site_id
  AND    xvsa_out_om2.start_date_active               <= TRUNC(SYSDATE)
  AND    xvsa_out_om2.end_date_active                 >= TRUNC(SYSDATE)
  UNION ALL
  ------------------------------------------------------------------------
  -- 振替有償
  ------------------------------------------------------------------------
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_om2.attribute1                        AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_om2.attribute1                        AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_om2.inventory_location_id             AS inventory_location_id
        ,xmld_out_om2.item_id                          AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
-- 2008/10/23 Y.Yamamoto v1.1 update start
--        ,xoha_out_om2.schedule_arrival_date            AS arrival_date
--        ,NVL(xoha_out_om2.schedule_arrival_date
--            ,xoha_out_om2.schedule_ship_date)          AS arrival_date
-- 2008/10/23 Y.Yamamoto v1.1 update end
--        ,xoha_out_om2.schedule_ship_date               AS leaving_date
        ,NVL(TRUNC(xoha_out_om2.schedule_arrival_date)
            ,TRUNC(xoha_out_om2.schedule_ship_date))   AS arrival_date
        ,TRUNC(xoha_out_om2.schedule_ship_date)        AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status        -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2.request_no                       AS voucher_no
        ,xvsa_out_om2.vendor_site_name                 AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2.actual_quantity                  AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2.actual_quantity ) * -1
          ELSE
            xmld_out_om2.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_out_om2                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_om2                 -- 移動ロット詳細(アドオン)
        ,oe_transaction_types_all     otta_out_om2                 -- 受注タイプ
        ,ic_whse_mst                  iwm_out_om2                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_om2                  -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_out_om2                 -- OPM品目マスタ
        ,mtl_system_items_b           msib_out_om2                 -- 品目マスタ
        ,ic_item_mst_b                iimb2_out_om2                -- OPM品目マスタ
        ,mtl_system_items_b           msib2_out_om2                -- 品目マスタ
        ,gmi_item_categories          gic_out_om2
        ,mtl_categories_b             mcb_out_om2
        ,gmi_item_categories          gic2_out_om2
        ,mtl_categories_b             mcb2_out_om2
        ,xxcmn_vendor_sites_all       xvsa_out_om2
        ,(SELECT xrpm_out_om2.new_div_invent
                ,flv_out_om2.meaning
                ,xrpm_out_om2.shipment_provision_div
                ,xrpm_out_om2.ship_prov_rcv_pay_category
-- 2008/10/24 Y.Yamamoto v1.1 update start
--                ,nvl(xrpm_out_om2.item_div_origin,'Dummy')         AS item_div_origin
--                ,nvl(xrpm_out_om2.item_div_ahead,'Dummy')          AS item_div_ahead
                ,xrpm_out_om2.item_div_origin
                ,DECODE(xrpm_out_om2.item_div_ahead,'5','5','Dummy') AS item_div_ahead
-- 2008/10/24 Y.Yamamoto v1.1 update end
          FROM   fnd_lookup_values flv_out_om2                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_om2                    -- 受払区分アドオンマスタ
          WHERE  flv_out_om2.lookup_type               = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2.language                  = 'JA'
          AND    flv_out_om2.lookup_code               = xrpm_out_om2.new_div_invent
          AND    xrpm_out_om2.doc_type                 = 'OMSO'
          AND    xrpm_out_om2.use_div_invent           = 'Y'
          AND    xrpm_out_om2.shipment_provision_div   = '2'       -- 支給依頼
-- 2009/04/01 本番#1364 ADD START
--          AND    xrpm_out_om2.item_div_origin          = '5'
          AND    xrpm_out_om2.item_div_origin         <> '5'
          AND    xrpm_out_om2.item_div_ahead           = '5'
-- 2009/04/01 本番#1364 ADD END
          AND    xrpm_out_om2.prod_div_origin         IS NULL
          AND    xrpm_out_om2.prod_div_ahead          IS NULL
         ) xrpm
  WHERE  xoha_out_om2.order_header_id                  = xola_out_om2.order_header_id
  AND    xoha_out_om2.deliver_from_id                  = mil_out_om2.inventory_location_id
  AND    iwm_out_om2.mtl_organization_id               = mil_out_om2.organization_id
  AND    xola_out_om2.shipping_inventory_item_id      <> xola_out_om2.request_item_id
  AND    xola_out_om2.request_item_id                  = msib_out_om2.inventory_item_id
  AND    iimb_out_om2.item_no                          = msib_out_om2.segment1
  AND    msib_out_om2.organization_id                  = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2.shipping_inventory_item_id       = msib2_out_om2.inventory_item_id
  AND    iimb2_out_om2.item_no                         = msib2_out_om2.segment1
  AND    msib2_out_om2.organization_id                 = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2.mov_line_id                      = xola_out_om2.order_line_id
  AND    xmld_out_om2.document_type_code               = '30'      -- 支給指示
  AND    xmld_out_om2.record_type_code                 = '10'      -- 指示
  AND    xmld_out_om2.lot_id                           = 0
  AND    xoha_out_om2.req_status                       = '07'      -- 受領済
  AND    NVL( xoha_out_om2.actual_confirm_class, 'N' ) = 'N'       -- 実績未計上
  AND    xoha_out_om2.latest_external_flag             = 'Y'       -- ON
  AND    xola_out_om2.delete_flag                      = 'N'       -- OFF
-- 2008/11/26 Upd Y.Kawano Start
--  AND    xoha_out_om2.schedule_ship_date              <= TRUNC( SYSDATE )
-- 2008/11/26 Upd Y.Kawano End
  AND    xoha_out_om2.order_type_id                    = otta_out_om2.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2.attribute1
  AND    gic_out_om2.item_id                           = iimb_out_om2.item_id
  AND    gic_out_om2.category_id                       = mcb_out_om2.category_id
  AND    gic_out_om2.category_set_id                   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2.segment1                          = '5'
  AND    gic2_out_om2.item_id                          = iimb2_out_om2.item_id
  AND    gic2_out_om2.category_id                      = mcb2_out_om2.category_id
  AND    gic2_out_om2.category_set_id                  = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    xrpm.item_div_origin                          = DECODE(mcb2_out_om2.segment1,'5','5','Dummy')
-- 2008/10/24 Y.Yamamoto v1.1 update start
--  AND    xrpm.item_div_ahead                           = DECODE(mcb_out_om2.segment1,'5','5','Dummy')
  AND    xrpm.item_div_ahead                           = mcb_out_om2.segment1
-- 2008/10/24 Y.Yamamoto v1.1 update end
-- 2009/04/01 本番#1364 ADD START
  AND    mcb_out_om2.segment1                         IN ('1','2','4')
-- 2009/04/01 本番#1364 ADD END
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2.attribute11
  OR     xrpm.ship_prov_rcv_pay_category              IS NULL)
  AND    xvsa_out_om2.vendor_site_id                   = xoha_out_om2.vendor_site_id
  AND    xvsa_out_om2.start_date_active               <= TRUNC(SYSDATE)
  AND    xvsa_out_om2.end_date_active                 >= TRUNC(SYSDATE)
-- 2008/10/24 Y.Yamamoto v1.1 add start
  UNION ALL
  ------------------------------------------------------------------------
  -- 有償
  ------------------------------------------------------------------------
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_om2.attribute1                        AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_om2.attribute1                        AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_om2.inventory_location_id             AS inventory_location_id
        ,xmld_out_om2.item_id                          AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,NVL(xoha_out_om2.schedule_arrival_date
--            ,xoha_out_om2.schedule_ship_date)          AS arrival_date
--        ,xoha_out_om2.schedule_ship_date               AS leaving_date
        ,NVL(TRUNC(xoha_out_om2.schedule_arrival_date)
            ,TRUNC(xoha_out_om2.schedule_ship_date))   AS arrival_date
        ,TRUNC(xoha_out_om2.schedule_ship_date)        AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status        -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2.request_no                       AS voucher_no
        ,xvsa_out_om2.vendor_site_name                 AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2.actual_quantity                  AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2.actual_quantity ) * -1
          ELSE
            xmld_out_om2.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_out_om2                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_om2                 -- 移動ロット詳細(アドオン)
        ,oe_transaction_types_all     otta_out_om2                 -- 受注タイプ
        ,ic_whse_mst                  iwm_out_om2                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_om2                  -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_out_om2                 -- OPM品目マスタ
        ,mtl_system_items_b           msib_out_om2                 -- 品目マスタ
        ,ic_item_mst_b                iimb2_out_om2                -- OPM品目マスタ
        ,mtl_system_items_b           msib2_out_om2                -- 品目マスタ
        ,gmi_item_categories          gic_out_om2
        ,mtl_categories_b             mcb_out_om2
        ,gmi_item_categories          gic2_out_om2
        ,mtl_categories_b             mcb2_out_om2
        ,xxcmn_vendor_sites_all       xvsa_out_om2
        ,(SELECT xrpm_out_om2.new_div_invent
                ,flv_out_om2.meaning
                ,xrpm_out_om2.shipment_provision_div
                ,xrpm_out_om2.ship_prov_rcv_pay_category
                ,xrpm_out_om2.item_div_origin
                ,DECODE(xrpm_out_om2.item_div_ahead,'5','5','Dummy') AS item_div_ahead
          FROM   fnd_lookup_values flv_out_om2                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_om2                    -- 受払区分アドオンマスタ
          WHERE  flv_out_om2.lookup_type               = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2.language                  = 'JA'
          AND    flv_out_om2.lookup_code               = xrpm_out_om2.new_div_invent
          AND    xrpm_out_om2.doc_type                 = 'OMSO'
          AND    xrpm_out_om2.use_div_invent           = 'Y'
          AND    xrpm_out_om2.shipment_provision_div   = '2'       -- 支給依頼
          AND    xrpm_out_om2.item_div_origin          = '5'
          AND    xrpm_out_om2.prod_div_origin         IS NULL
          AND    xrpm_out_om2.prod_div_ahead          IS NULL
         ) xrpm
  WHERE  xoha_out_om2.order_header_id                  = xola_out_om2.order_header_id
  AND    xoha_out_om2.deliver_from_id                  = mil_out_om2.inventory_location_id
  AND    iwm_out_om2.mtl_organization_id               = mil_out_om2.organization_id
  AND    xola_out_om2.shipping_inventory_item_id       = xola_out_om2.request_item_id
  AND    xola_out_om2.request_item_id                  = msib_out_om2.inventory_item_id
  AND    iimb_out_om2.item_no                          = msib_out_om2.segment1
  AND    msib_out_om2.organization_id                  = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2.shipping_inventory_item_id       = msib2_out_om2.inventory_item_id
  AND    iimb2_out_om2.item_no                         = msib2_out_om2.segment1
  AND    msib2_out_om2.organization_id                 = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2.mov_line_id                      = xola_out_om2.order_line_id
  AND    xmld_out_om2.document_type_code               = '30'      -- 支給指示
  AND    xmld_out_om2.record_type_code                 = '10'      -- 指示
  AND    xmld_out_om2.lot_id                           = 0
  AND    xoha_out_om2.req_status                       = '07'      -- 受領済
  AND    NVL( xoha_out_om2.actual_confirm_class, 'N' ) = 'N'       -- 実績未計上
  AND    xoha_out_om2.latest_external_flag             = 'Y'       -- ON
  AND    xola_out_om2.delete_flag                      = 'N'       -- OFF
-- 2008/11/26 Upd Y.Kawano Start
--  AND    xoha_out_om2.schedule_ship_date              <= TRUNC( SYSDATE )
-- 2008/11/26 Upd Y.Kawano End
  AND    xoha_out_om2.order_type_id                    = otta_out_om2.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2.attribute1
  AND    gic_out_om2.item_id                           = iimb_out_om2.item_id
  AND    gic_out_om2.category_id                       = mcb_out_om2.category_id
  AND    gic_out_om2.category_set_id                   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2.segment1                          = '5'
  AND    gic2_out_om2.item_id                          = iimb2_out_om2.item_id
  AND    gic2_out_om2.category_id                      = mcb2_out_om2.category_id
  AND    gic2_out_om2.category_set_id                  = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    xrpm.item_div_origin                          = DECODE(mcb2_out_om2.segment1,'5','5','Dummy')
  AND    xrpm.item_div_ahead                           = mcb_out_om2.segment1
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2.attribute11
  OR     xrpm.ship_prov_rcv_pay_category              IS NULL)
  AND    xvsa_out_om2.vendor_site_id                   = xoha_out_om2.vendor_site_id
  AND    xvsa_out_om2.start_date_active               <= TRUNC(SYSDATE)
  AND    xvsa_out_om2.end_date_active                 >= TRUNC(SYSDATE)
-- 2008/10/24 Y.Yamamoto v1.1 add end
  UNION ALL
  -- 生産原料投入予定
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_pr.attribute1                         AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_pr.attribute1                         AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_pr.inventory_location_id              AS inventory_location_id
        ,xmld_out_pr.item_id                           AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,gbh_out_pr.plan_start_date                    AS arrival_date
--        ,gbh_out_pr.plan_start_date                    AS leaving_date
        ,TRUNC(gbh_out_pr.plan_start_date)             AS arrival_date
        ,TRUNC(gbh_out_pr.plan_start_date)             AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'1'                                           AS status       -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_out_pr.batch_no                           AS voucher_no
        ,grt_out_pr.routing_desc                       AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_pr.actual_quantity                   AS leaving_quantity
  FROM   gme_batch_header             gbh_out_pr                  -- 生産バッチ
        ,gme_material_details         gmd_out_pr                  -- 生産原料詳細
        ,xxinv_mov_lot_details        xmld_out_pr                 -- 移動ロット詳細(アドオン)
        ,gmd_routings_b               grb_out_pr                  -- 工順マスタ
        ,gmd_routings_tl              grt_out_pr                  -- 工順マスタ日本語
-- 2008/11/19 Y.Yamamoto v1.2 add start
        ,ic_tran_pnd                  itp_out_pr                  -- OPM保留在庫トランザクション
-- 2008/11/19 Y.Yamamoto v1.2 add end
        ,ic_whse_mst                  iwm_out_pr                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_pr                  -- OPM保管場所マスタ
        ,(SELECT xrpm_out_pr.new_div_invent
                ,flv_out_pr.meaning
                ,xrpm_out_pr.routing_class
                ,xrpm_out_pr.line_type
                ,xrpm_out_pr.hit_in_div
-- 2008/11/19 Y.Yamamoto v1.2 add start
                ,xrpm_out_pr.doc_type
-- 2008/11/19 Y.Yamamoto v1.2 add end
          FROM   fnd_lookup_values flv_out_pr                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_pr                    -- 受払区分アドオンマスタ
          WHERE  flv_out_pr.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_pr.language                 = 'JA'
          AND    flv_out_pr.lookup_code              = xrpm_out_pr.new_div_invent
          AND    xrpm_out_pr.doc_type                = 'PROD'
          AND    xrpm_out_pr.use_div_invent          = 'Y'
-- 2009/01/07 Y.Yamamoto #IS50 add start
          AND    xrpm_out_pr.routing_class          <> '70'
-- 2009/01/07 Y.Yamamoto #IS50 add end
         ) xrpm
  WHERE  gbh_out_pr.batch_id                 = gmd_out_pr.batch_id
  AND    gmd_out_pr.material_detail_id       = xmld_out_pr.mov_line_id
  AND    gmd_out_pr.line_type                = -1                 -- 投入品
-- 2008/11/19 Y.Yamamoto v1.2 add start
  AND    itp_out_pr.doc_type                 = xrpm.doc_type
  AND    itp_out_pr.doc_id                   = gmd_out_pr.batch_id
  AND    itp_out_pr.line_id                  = gmd_out_pr.material_detail_id
  AND    itp_out_pr.doc_line                 = gmd_out_pr.line_no
  AND    itp_out_pr.line_type                = gmd_out_pr.line_type
  AND    itp_out_pr.item_id                  = gmd_out_pr.item_id
  AND    itp_out_pr.completed_ind            = 0
  AND    itp_out_pr.delete_mark              = 0                  -- 有効チェック(OPM保留在庫)
-- 2008/11/19 Y.Yamamoto v1.2 add end
  AND    xmld_out_pr.document_type_code      = '40'
  AND    xmld_out_pr.record_type_code        = '10'
  AND    xmld_out_pr.lot_id                  = 0
  AND    grb_out_pr.attribute9               = mil_out_pr.segment1
  AND    iwm_out_pr.mtl_organization_id      = mil_out_pr.organization_id
-- 2008/11/19 Y.Yamamoto v1.2 update start
--  AND    NOT EXISTS( SELECT 1
--                     FROM   gme_batch_header gbh_out_pr_ex
--                     WHERE  gbh_out_pr_ex.batch_id      = gbh_out_pr.batch_id
--                     AND    gbh_out_pr_ex.batch_status IN ( 7     -- 完了
--                                                           ,8     -- クローズ
--                                                           ,-1 )) -- 取消
  AND    gbh_out_pr.batch_status            IN ( 1                  -- 保留
                                                ,2 )                -- WIP
-- 2008/11/19 Y.Yamamoto v1.2 update end
-- 2008/11/26 Y.Kawano Upd Start
--  AND    gbh_out_pr.plan_start_date         <= TRUNC( SYSDATE )
-- 2008/11/26 Y.Kawano Upd End
  AND    grb_out_pr.routing_id               = gbh_out_pr.routing_id
  AND    xrpm.routing_class                  = grb_out_pr.routing_class
  AND    xrpm.line_type                      = gmd_out_pr.line_type
  AND ((( gmd_out_pr.attribute5             IS NULL )
    AND ( xrpm.hit_in_div                   IS NULL ))
  OR   (( gmd_out_pr.attribute5              = 'Y' )
    AND ( xrpm.hit_in_div                    = gmd_out_pr.attribute5 )))
  AND    grb_out_pr.routing_id               = grt_out_pr.routing_id
  AND    grt_out_pr.language                 = 'JA'
-- 2009/01/07 Y.Yamamoto #IS50 add start
  UNION ALL
  -- 品目振替予定
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_pr.attribute1                         AS ownership_code
        ,mil_out_pr.inventory_location_id              AS inventory_location_id
        ,xmld_out_pr.item_id                           AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
        ,TRUNC(gbh_out_pr.plan_start_date)             AS arrival_date
        ,TRUNC(gbh_out_pr.plan_start_date)             AS leaving_date
        ,'1'                                           AS status       -- 予定
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_out_pr.batch_no                           AS voucher_no
        ,grt_out_pr.routing_desc                       AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_pr.actual_quantity                   AS leaving_quantity
  FROM   gme_batch_header             gbh_out_pr                  -- 生産バッチ
        ,gme_material_details         gmd_out_pr                  -- 生産原料詳細
        ,gme_material_details         gmd_out_pr2                 -- 生産原料詳細
        ,xxinv_mov_lot_details        xmld_out_pr                 -- 移動ロット詳細(アドオン)
        ,gmd_routings_b               grb_out_pr                  -- 工順マスタ
        ,gmd_routings_tl              grt_out_pr                  -- 工順マスタ日本語
        ,ic_tran_pnd                  itp_out_pr                  -- OPM保留在庫トランザクション
        ,ic_whse_mst                  iwm_out_pr                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_pr                  -- OPM保管場所マスタ
        ,gmi_item_categories          gic
        ,mtl_categories_b             mcb
        ,gmi_item_categories          gic2
        ,mtl_categories_b             mcb2
        ,(SELECT xrpm_out_pr.new_div_invent
                ,flv_out_pr.meaning
                ,xrpm_out_pr.routing_class
                ,xrpm_out_pr.line_type
                ,xrpm_out_pr.hit_in_div
                ,xrpm_out_pr.doc_type
                ,xrpm_out_pr.item_div_origin
                ,xrpm_out_pr.item_div_ahead
          FROM   fnd_lookup_values flv_out_pr                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_pr                    -- 受払区分アドオンマスタ
          WHERE  flv_out_pr.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_pr.language                 = 'JA'
          AND    flv_out_pr.lookup_code              = xrpm_out_pr.new_div_invent
          AND    xrpm_out_pr.doc_type                = 'PROD'
          AND    xrpm_out_pr.use_div_invent          = 'Y'
          AND    xrpm_out_pr.routing_class           = '70'
         ) xrpm
  WHERE  gbh_out_pr.batch_id                 = gmd_out_pr.batch_id
  AND    gmd_out_pr.material_detail_id       = xmld_out_pr.mov_line_id
  AND    gmd_out_pr.line_type                = -1                 -- 投入品
  AND    itp_out_pr.doc_type                 = xrpm.doc_type
  AND    itp_out_pr.doc_id                   = gmd_out_pr.batch_id
  AND    itp_out_pr.line_id                  = gmd_out_pr.material_detail_id
  AND    itp_out_pr.doc_line                 = gmd_out_pr.line_no
  AND    itp_out_pr.line_type                = gmd_out_pr.line_type
  AND    itp_out_pr.item_id                  = gmd_out_pr.item_id
  AND    itp_out_pr.completed_ind            = 0
  AND    itp_out_pr.delete_mark              = 0                  -- 有効チェック(OPM保留在庫)
  AND    itp_out_pr.item_id                  = gic.item_id
  AND    gic.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb.category_id                     = gic.category_id
  AND    xrpm.item_div_origin                = mcb.segment1
  AND    gmd_out_pr2.item_id                 = gic2.item_id
  AND    gic2.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb2.category_id                    = gic.category_id
  AND    xrpm.item_div_origin                = mcb2.segment1
  AND    xmld_out_pr.document_type_code      = '40'
  AND    xmld_out_pr.record_type_code        = '10'
  AND    xmld_out_pr.lot_id                  = 0
  AND    grb_out_pr.attribute9               = mil_out_pr.segment1
  AND    iwm_out_pr.mtl_organization_id      = mil_out_pr.organization_id
  AND    gbh_out_pr.batch_status            IN ( 1                  -- 保留
                                                ,2 )                -- WIP
  AND    grb_out_pr.routing_id               = gbh_out_pr.routing_id
  AND    xrpm.routing_class                  = grb_out_pr.routing_class
  AND    xrpm.line_type                      = gmd_out_pr.line_type
  AND    gbh_out_pr.batch_id                 = gmd_out_pr2.batch_id
  AND    gmd_out_pr.batch_id                 = gmd_out_pr2.batch_id
  AND    gmd_out_pr2.line_type               = -1                  -- 投入品
  AND    grb_out_pr.routing_id               = grt_out_pr.routing_id
  AND    grt_out_pr.language                 = 'JA'
-- 2009/01/07 Y.Yamamoto #IS50 add end
  UNION ALL
  -- 相手先在庫出庫予定
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_ad.attribute1                          AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_ad.attribute1                          AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_ad.inventory_location_id               AS inventory_location_id
        ,iimb_out_ad.item_id                            AS item_id
        ,NULL                                           AS lot_no
        ,NULL                                           AS manufacture_date
        ,NULL                                           AS uniqe_sign
        ,NULL                                           AS expiration_date -- <---- ここまで共通
        ,TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) AS arrival_date
        ,TO_DATE( pha_out_ad.attribute4, 'YYYY/MM/DD' ) AS leaving_date
        ,'1'                                            AS status        -- 予定
        ,xrpm.new_div_invent                            AS reason_code
        ,xrpm.meaning                                   AS reason_code_name
        ,pha_out_ad.segment1                            AS voucher_no
        ,xv_out_ad.vendor_name                          AS ukebaraisaki_name
        ,NULL                                           AS deliver_to_name
        ,0                                              AS stock_quantity
        ,pla_out_ad.quantity                            AS leaving_quantity
  FROM   po_headers_all               pha_out_ad                  -- 発注ヘッダ
        ,po_lines_all                 pla_out_ad                  -- 発注明細
        ,ic_whse_mst                  iwm_out_ad                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_ad                  -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_out_ad                 -- OPM品目マスタ
        ,mtl_system_items_b           msib_out_ad                 -- 品目マスタ
        ,po_vendors                   pv_out_ad                   -- 仕入先マスタ
        ,xxcmn_vendors                xv_out_ad                   -- 仕入先アドオンマスタ
        ,(SELECT xrpm_out_ad.new_div_invent
                ,flv_out_ad.meaning
          FROM   fnd_lookup_values flv_out_ad                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_ad                     -- 受払区分アドオンマスタ
          WHERE  flv_out_ad.lookup_type           = 'XXCMN_NEW_DIVISION'
          AND    flv_out_ad.language              = 'JA'
          AND    flv_out_ad.lookup_code           = xrpm_out_ad.new_div_invent
          AND    xrpm_out_ad.doc_type             = 'ADJI'
          AND    xrpm_out_ad.use_div_invent       = 'Y'
          AND    xrpm_out_ad.reason_code          = 'X977'                 -- 相手先在庫
          AND    xrpm_out_ad.rcv_pay_div          = '-1'                   -- 払出
         ) xrpm
  WHERE  pha_out_ad.po_header_id          = pla_out_ad.po_header_id
  AND    pha_out_ad.attribute1           IN ( '20'                 -- 発注作成済
                                             ,'25' )               -- 受入あり
  AND    pla_out_ad.attribute13           = 'N'                    -- 未承諾
  AND    pha_out_ad.attribute11           = '3'
  AND    pla_out_ad.item_id               = msib_out_ad.inventory_item_id
  AND    iimb_out_ad.item_no              = msib_out_ad.segment1
  AND    msib_out_ad.organization_id      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    EXISTS (SELECT 1
                 FROM   xxinv_mov_lot_details   xmld
                 WHERE  xmld.mov_line_id        = pla_out_ad.po_line_id
                 AND    xmld.document_type_code = '50'
                 AND    xmld.record_type_code   = '10'
                 AND    ROWNUM = 1)
  AND    pla_out_ad.attribute12           = mil_out_ad.segment1
  AND    iwm_out_ad.mtl_organization_id   = mil_out_ad.organization_id
-- 2008/11/26 Upd Y.Kawano Start
--  AND    pha_out_ad.attribute4           <= TO_CHAR( SYSDATE, 'YYYY/MM/DD' )
-- 2008/11/26 Upd Y.Kawano End
  AND    pha_out_ad.vendor_id             = xv_out_ad.vendor_id   -- 仕入先情報VIEW
  AND    pv_out_ad.vendor_id              = xv_out_ad.vendor_id
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    pv_out_ad.end_date_active       IS NULL
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xv_out_ad.start_date_active     <= TRUNC( SYSDATE )
  AND    xv_out_ad.end_date_active       >= TRUNC( SYSDATE )
  UNION ALL
  ------------------------------------------------------------------------
  -- 入庫実績
  ------------------------------------------------------------------------
  --発注受入実績
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_po_e.attribute1                        AS ownership_code
  SELECT DISTINCT xrart_in_po_e.txns_id                AS po_trans_id
        ,iwm_in_po_e.attribute1                        AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_po_e.inventory_location_id             AS inventory_location_id
        ,iimb_in_po_e.item_id                          AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xrart_in_po_e.txns_date                       AS arrival_date
--        ,xrart_in_po_e.txns_date                       AS leaving_date
        ,TRUNC(xrart_in_po_e.txns_date)                AS arrival_date
        ,TRUNC(xrart_in_po_e.txns_date)                AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status        -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,pha_in_po_e.segment1                          AS voucher_no
        ,xv_in_po_e.vendor_name                        AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,xrart_in_po_e.quantity                        AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   po_headers_all               pha_in_po_e               -- 発注ヘッダ
        ,po_lines_all                 pla_in_po_e               -- 発注明細
        ,xxpo_rcv_and_rtn_txns        xrart_in_po_e             -- 受入返品実績(アドオン)
        ,rcv_shipment_lines           rsl_in_po_e               -- 受入明細
        ,rcv_transactions             rt_in_po_e                -- 受入取引
        ,po_vendors                   pv_in_po_e                -- 仕入先マスタ
        ,xxcmn_vendors                xv_in_po_e                -- 仕入先アドオンマスタ
        ,ic_whse_mst                  iwm_in_po_e               -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_po_e               -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_in_po_e              -- OPM品目マスタ
        ,mtl_system_items_b           msib_in_po_e              -- 品目マスタ
        ,(SELECT xrpm_in_po_e.new_div_invent
                ,flv_in_po_e.meaning
                ,xrpm_in_po_e.transaction_type
          FROM   fnd_lookup_values flv_in_po_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_in_po_e                     -- 受払区分アドオンマスタ
          WHERE  flv_in_po_e.lookup_type           = 'XXCMN_NEW_DIVISION'
          AND    flv_in_po_e.language              = 'JA'
          AND    flv_in_po_e.lookup_code           = xrpm_in_po_e.new_div_invent
          AND    xrpm_in_po_e.doc_type             = 'PORC'
          AND    xrpm_in_po_e.source_document_code = 'PO'
          AND    xrpm_in_po_e.use_div_invent       = 'Y'
         ) xrpm
  WHERE  pha_in_po_e.po_header_id          = pla_in_po_e.po_header_id
  AND    pha_in_po_e.attribute5            = mil_in_po_e.segment1
  AND    iwm_in_po_e.mtl_organization_id   = mil_in_po_e.organization_id
  AND    pla_in_po_e.item_id               = msib_in_po_e.inventory_item_id
  AND    iimb_in_po_e.item_no              = msib_in_po_e.segment1
  AND    msib_in_po_e.organization_id      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    pha_in_po_e.attribute1           IN ( '25'                 -- 受入あり
                                              ,'30'                 -- 数量確定済
                                              ,'35' )               -- 金額確定済
  AND    pla_in_po_e.attribute13           = 'Y'                    -- 承諾済
  AND    pha_in_po_e.segment1              = xrart_in_po_e.source_document_number
  AND    pla_in_po_e.line_num              = xrart_in_po_e.source_document_line_num
  AND    xrart_in_po_e.txns_type           = '1'                    -- 受入
  AND    pla_in_po_e.cancel_flag          <> 'Y'
  AND    rsl_in_po_e.po_header_id          = pha_in_po_e.po_header_id
  AND    rsl_in_po_e.po_line_id            = pla_in_po_e.po_line_id
-- 2008/12/08 T.Ohashi start
--  AND    xrart_in_po_e.txns_id             = rsl_in_po_e.attribute1
-- 2008/12/08 T.Ohashi end
  AND    rt_in_po_e.shipment_line_id       = rsl_in_po_e.shipment_line_id
-- 2008/12/07 N.Yoshida start
--  AND    rt_in_po_e.destination_type_code  = rsl_in_po_e.destination_type_code
-- 2008/12/07 N.Yoshida end
  AND    xrpm.transaction_type             = rt_in_po_e.transaction_type
  AND    pha_in_po_e.vendor_id             = xv_in_po_e.vendor_id   -- 仕入先情報VIEW
  AND    pv_in_po_e.vendor_id              = xv_in_po_e.vendor_id
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    pv_in_po_e.end_date_active       IS NULL
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xv_in_po_e.start_date_active     <= TRUNC( SYSDATE )
  AND    xv_in_po_e.end_date_active       >= TRUNC( SYSDATE )
  UNION ALL
  -- 移動入庫実績(積送あり)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_xf_e.attribute1                        AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_xf_e.attribute1                        AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_xf_e.inventory_location_id             AS inventory_location_id
        ,xmld_in_xf_e.item_id                          AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xmrih_in_xf_e.actual_arrival_date             AS arrival_date
--        ,xmrih_in_xf_e.actual_ship_date                AS leaving_date
        ,TRUNC(xmrih_in_xf_e.actual_arrival_date)      AS arrival_date
        ,TRUNC(xmrih_in_xf_e.actual_ship_date)         AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status           -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_in_xf_e.mov_num                         AS voucher_no
        ,mil2_in_xf_e.description                      AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,xmld_in_xf_e.actual_quantity                  AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_in_xf_e                  -- 移動依頼/指示ヘッダ(アドオン)
        ,xxinv_mov_req_instr_lines    xmril_in_xf_e                  -- 移動依頼/指示明細(アドオン)
        ,xxinv_mov_lot_details        xmld_in_xf_e                   -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_in_xf_e                    -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_xf_e                    -- OPM保管場所マスタ
        ,mtl_item_locations           mil2_in_xf_e                   -- OPM保管場所マスタ
        ,(SELECT xrpm_in_xf_e.new_div_invent
                ,flv_in_xf_e.meaning
          FROM   fnd_lookup_values flv_in_xf_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_in_xf_e                     -- 受払区分アドオンマスタ
          WHERE  flv_in_xf_e.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_xf_e.language                 = 'JA'
          AND    flv_in_xf_e.lookup_code              = xrpm_in_xf_e.new_div_invent
          AND    xrpm_in_xf_e.doc_type                = 'XFER'               -- 移動積送あり
          AND    xrpm_in_xf_e.use_div_invent          = 'Y'
          AND    xrpm_in_xf_e.rcv_pay_div             = '1'
         ) xrpm
  WHERE  xmrih_in_xf_e.mov_hdr_id             = xmril_in_xf_e.mov_hdr_id
  AND    xmril_in_xf_e.mov_line_id            = xmld_in_xf_e.mov_line_id
  AND    xmrih_in_xf_e.ship_to_locat_id       = mil_in_xf_e.inventory_location_id
  AND    iwm_in_xf_e.mtl_organization_id      = mil_in_xf_e.organization_id
  AND    xmrih_in_xf_e.shipped_locat_id       = mil2_in_xf_e.inventory_location_id
  AND    xmld_in_xf_e.lot_id                  = 0
  AND    xmld_in_xf_e.document_type_code      = '20'                 -- 移動
  AND    xmld_in_xf_e.record_type_code        = '30'                 -- 入庫実績
  AND    xmrih_in_xf_e.mov_type               = '1'                  -- 積送あり
  AND    xmril_in_xf_e.delete_flg             = 'N'                  -- OFF
  AND    xmrih_in_xf_e.status                IN ( '06'               -- 入出庫報告有
                                                 ,'05' )             -- 入庫報告有
  UNION ALL
  -- 移動入庫実績(積送なし)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_tr_e.attribute1                        AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_tr_e.attribute1                        AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_tr_e.inventory_location_id             AS inventory_location_id
        ,xmld_in_tr_e.item_id                          AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xmrih_in_tr_e.actual_arrival_date             AS arrival_date
--        ,xmrih_in_tr_e.actual_ship_date                AS leaving_date
        ,TRUNC(xmrih_in_tr_e.actual_arrival_date)      AS arrival_date
        ,TRUNC(xmrih_in_tr_e.actual_ship_date)         AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status        -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_in_tr_e.mov_num                         AS voucher_no
        ,mil2_in_tr_e.description                      AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,xmld_in_tr_e.actual_quantity                  AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_in_tr_e               -- 移動依頼/指示ヘッダ(アドオン)
        ,xxinv_mov_req_instr_lines    xmril_in_tr_e               -- 移動依頼/指示明細(アドオン)
        ,xxinv_mov_lot_details        xmld_in_tr_e                -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_in_tr_e                    -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_tr_e                    -- OPM保管場所マスタ
        ,mtl_item_locations           mil2_in_tr_e                   -- OPM保管場所マスタ
        ,(SELECT xrpm_in_tr_e.new_div_invent
                ,flv_in_tr_e.meaning
          FROM   fnd_lookup_values flv_in_tr_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_in_tr_e                     -- 受払区分アドオンマスタ
          WHERE  flv_in_tr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_tr_e.language                 = 'JA'
          AND    flv_in_tr_e.lookup_code              = xrpm_in_tr_e.new_div_invent
          AND    xrpm_in_tr_e.doc_type                = 'TRNI'            -- 移動積送なし
          AND    xrpm_in_tr_e.use_div_invent          = 'Y'
          AND    xrpm_in_tr_e.rcv_pay_div             = '1'
         ) xrpm
  WHERE  xmrih_in_tr_e.mov_hdr_id             = xmril_in_tr_e.mov_hdr_id
  AND    xmril_in_tr_e.mov_line_id            = xmld_in_tr_e.mov_line_id
  AND    xmrih_in_tr_e.ship_to_locat_id       = mil_in_tr_e.inventory_location_id
  AND    iwm_in_tr_e.mtl_organization_id      = mil_in_tr_e.organization_id
  AND    xmrih_in_tr_e.shipped_locat_id       = mil2_in_tr_e.inventory_location_id
  AND    xmld_in_tr_e.lot_id                  = 0
  AND    xmld_in_tr_e.document_type_code      = '20'              -- 移動
  AND    xmld_in_tr_e.record_type_code        = '30'              -- 入庫実績
  AND    xmrih_in_tr_e.mov_type               = '2'               -- 積送なし
-- 2008/12/24 #752 Y.Yamamoto update start
--  AND    xmrih_in_tr_e.status                 = '06'              -- 入出庫報告有
  AND    xmrih_in_tr_e.status                IN ( '06'               -- 入出庫報告有
                                                 ,'05' )             -- 入庫報告有
-- 2008/12/24 #752 Y.Yamamoto update end
  AND    xmril_in_tr_e.delete_flg             = 'N'               -- OFF
  UNION ALL
  -- 生産入庫実績
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_pr_e.attribute1                        AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_pr_e.attribute1                        AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_pr_e.inventory_location_id             AS inventory_location_id
        ,gmd_in_pr_e.item_id                           AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itp_in_pr_e.trans_date                        AS arrival_date
--        ,itp_in_pr_e.trans_date                        AS leaving_date
        ,TRUNC(itp_in_pr_e.trans_date)                 AS arrival_date
        ,TRUNC(itp_in_pr_e.trans_date)                 AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status         -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_in_pr_e.batch_no                          AS voucher_no
        ,grt_in_pr_e.routing_desc                      AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itp_in_pr_e.trans_qty                         AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   gme_batch_header             gbh_in_pr_e                  -- 生産バッチ
        ,gme_material_details         gmd_in_pr_e                  -- 生産原料詳細
        ,ic_tran_pnd                  itp_in_pr_e                  -- OPM保留在庫トランザクション
        ,gmd_routings_b               grb_in_pr_e                  -- 工順マスタ
        ,gmd_routings_tl              grt_in_pr_e                  -- 工順マスタ日本語
        ,ic_whse_mst                  iwm_in_pr_e                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_pr_e                  -- OPM保管場所マスタ
        ,(SELECT xrpm_in_pr_e.new_div_invent
                ,flv_in_pr_e.meaning
                ,xrpm_in_pr_e.doc_type
                ,xrpm_in_pr_e.transaction_type
                ,xrpm_in_pr_e.routing_class
                ,xrpm_in_pr_e.line_type
                ,xrpm_in_pr_e.hit_in_div
          FROM   fnd_lookup_values flv_in_pr_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_in_pr_e                     -- 受払区分アドオンマスタ
          WHERE  flv_in_pr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_pr_e.language                 = 'JA'
          AND    flv_in_pr_e.lookup_code              = xrpm_in_pr_e.new_div_invent
          AND    xrpm_in_pr_e.doc_type                = 'PROD'
          AND    xrpm_in_pr_e.use_div_invent          = 'Y'
         ) xrpm
  WHERE  gbh_in_pr_e.batch_id                 = gmd_in_pr_e.batch_id
  AND    itp_in_pr_e.doc_id                   = gmd_in_pr_e.batch_id
  AND    itp_in_pr_e.doc_line                 = gmd_in_pr_e.line_no
  AND    itp_in_pr_e.line_type                = gmd_in_pr_e.line_type
  AND    itp_in_pr_e.item_id                  = gmd_in_pr_e.item_id
  AND    itp_in_pr_e.location                 = mil_in_pr_e.segment1
  AND    grb_in_pr_e.attribute9               = mil_in_pr_e.segment1
  AND    mil_in_pr_e.organization_id          = iwm_in_pr_e.mtl_organization_id
  AND    itp_in_pr_e.delete_mark              = 0                  -- 有効チェック(OPM保留在庫)
  AND    gmd_in_pr_e.line_type               IN ( 1                -- 完成品
                                                 ,2 )              -- 副産物
  AND    itp_in_pr_e.doc_type                 = xrpm.doc_type
  AND    itp_in_pr_e.completed_ind            = 1
  AND    itp_in_pr_e.reverse_id              IS NULL
  AND    itp_in_pr_e.lot_id                   = 0
  AND    grb_in_pr_e.routing_id               = gbh_in_pr_e.routing_id
  AND    xrpm.routing_class                   = grb_in_pr_e.routing_class
  AND    xrpm.line_type                       = gmd_in_pr_e.line_type
  AND ((( gmd_in_pr_e.attribute5              IS NULL )
    AND ( xrpm.hit_in_div                     IS NULL ))
  OR   (( gmd_in_pr_e.attribute5              = 'Y' )
    AND ( xrpm.hit_in_div                     = gmd_in_pr_e.attribute5 )))
  AND    grb_in_pr_e.routing_id               = grt_in_pr_e.routing_id
  AND    grt_in_pr_e.language                 = 'JA'
  AND NOT EXISTS 
    ( SELECT 1
      FROM   gmd_routing_class_b   grcb_in_pr_ex          -- 工順区分マスタ
            ,gmd_routing_class_tl  grct_in_pr_ex          -- 工順区分マスタ日本語
      WHERE  grcb_in_pr_ex.routing_class      = grb_in_pr_e.routing_class
      AND    grct_in_pr_ex.routing_class      = grcb_in_pr_ex.routing_class
      AND    grct_in_pr_ex.language           = 'JA'
      AND    grct_in_pr_ex.routing_class_desc IN (FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING')
                                                 ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE')
                                                 ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET'))
    )
  UNION ALL
  -- 生産入庫実績 品目振替 品種振替
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_pr_e70.attribute1                      AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_pr_e70.attribute1                      AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_pr_e70.inventory_location_id           AS inventory_location_id
        ,gmd_in_pr_e70a.item_id                        AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itp_in_pr_e70.trans_date                      AS arrival_date
--        ,itp_in_pr_e70.trans_date                      AS leaving_date
        ,TRUNC(itp_in_pr_e70.trans_date)               AS arrival_date
        ,TRUNC(itp_in_pr_e70.trans_date)               AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status         -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_in_pr_e70.batch_no                        AS voucher_no
        ,grt_in_pr_e70.routing_desc                    AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itp_in_pr_e70.trans_qty                       AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   gme_batch_header             gbh_in_pr_e70                  -- 生産バッチ
        ,gme_material_details         gmd_in_pr_e70a                 -- 生産原料詳細(振替先)
        ,gme_material_details         gmd_in_pr_e70b                 -- 生産原料詳細(振替元)
        ,ic_tran_pnd                  itp_in_pr_e70                  -- OPM保留在庫トランザクション
        ,gmd_routings_b               grb_in_pr_e70                  -- 工順マスタ
        ,gmd_routings_tl              grt_in_pr_e70                  -- 工順マスタ日本語
        ,gmd_routing_class_b          grcb_in_pr_e70                 -- 工順区分マスタ
        ,gmd_routing_class_tl         grct_in_pr_e70                 -- 工順区分マスタ日本語
        ,ic_whse_mst                  iwm_in_pr_e70                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_pr_e70                  -- OPM保管場所マスタ
        ,gmi_item_categories          gic_in_pr_e70_s
        ,mtl_categories_b             mcb_in_pr_e70_s
        ,gmi_item_categories          gic_in_pr_e70_r
        ,mtl_categories_b             mcb_in_pr_e70_r
        ,(SELECT xrpm_in_pr_e70.new_div_invent
                ,flv_in_pr_e70.meaning
                ,xrpm_in_pr_e70.doc_type
                ,xrpm_in_pr_e70.routing_class
                ,xrpm_in_pr_e70.line_type
                ,xrpm_in_pr_e70.item_div_ahead
                ,xrpm_in_pr_e70.item_div_origin
          FROM   fnd_lookup_values flv_in_pr_e70                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_in_pr_e70                     -- 受払区分アドオンマスタ
          WHERE  flv_in_pr_e70.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_pr_e70.language                 = 'JA'
          AND    flv_in_pr_e70.lookup_code              = xrpm_in_pr_e70.new_div_invent
          AND    xrpm_in_pr_e70.doc_type                = 'PROD'
          AND    xrpm_in_pr_e70.use_div_invent          = 'Y'
         ) xrpm
  WHERE  gbh_in_pr_e70.batch_id                 = gmd_in_pr_e70a.batch_id
  AND    gmd_in_pr_e70a.batch_id                = itp_in_pr_e70.doc_id
  AND    gmd_in_pr_e70a.line_no                 = itp_in_pr_e70.doc_line
  AND    gmd_in_pr_e70a.line_type               = itp_in_pr_e70.line_type
  AND    gmd_in_pr_e70a.item_id                 = itp_in_pr_e70.item_id
  AND    itp_in_pr_e70.location                 = mil_in_pr_e70.segment1
  AND    mil_in_pr_e70.organization_id          = iwm_in_pr_e70.mtl_organization_id
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    grb_in_pr_e70.attribute9               = mil_in_pr_e70.segment1
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    grct_in_pr_e70.language                = 'JA'
  AND    grct_in_pr_e70.routing_class           = grcb_in_pr_e70.routing_class
  AND    grcb_in_pr_e70.routing_class           = grb_in_pr_e70.routing_class
  AND    grt_in_pr_e70.language                 = 'JA'
  AND    grb_in_pr_e70.routing_id               = grt_in_pr_e70.routing_id
  AND    itp_in_pr_e70.delete_mark              = 0                  -- 有効チェック(OPM保留在庫)
  AND    gmd_in_pr_e70a.line_type               = 1                  -- 完成品
  AND    itp_in_pr_e70.doc_type                 = xrpm.doc_type
  AND    itp_in_pr_e70.completed_ind            = 1
  AND    itp_in_pr_e70.lot_id                   = 0
  AND    grb_in_pr_e70.routing_id               = gbh_in_pr_e70.routing_id
  AND    xrpm.routing_class                     = grb_in_pr_e70.routing_class
  AND    xrpm.line_type                         = gmd_in_pr_e70a.line_type
  AND    grct_in_pr_e70.routing_class_desc      = FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING')
  AND    gic_in_pr_e70_s.item_id                = itp_in_pr_e70.item_id
  AND    gic_in_pr_e70_s.category_id            = mcb_in_pr_e70_s.category_id
  AND    gic_in_pr_e70_s.category_set_id        = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_in_pr_e70_s.segment1               = xrpm.item_div_ahead
  AND    gic_in_pr_e70_r.item_id                = gmd_in_pr_e70b.item_id
  AND    gic_in_pr_e70_r.category_id            = mcb_in_pr_e70_r.category_id
  AND    gic_in_pr_e70_r.category_set_id        = gic_in_pr_e70_s.category_set_id
  AND    mcb_in_pr_e70_r.segment1               = xrpm.item_div_origin
  AND    gbh_in_pr_e70.batch_id                 = gmd_in_pr_e70b.batch_id
  AND    gmd_in_pr_e70a.batch_id                = gmd_in_pr_e70b.batch_id
  AND    gmd_in_pr_e70b.line_type               = -1                  -- 投入品
  UNION ALL
  -- 生産入庫実績 解体
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_pr_e70.attribute1                      AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_pr_e70.attribute1                      AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_pr_e70.inventory_location_id           AS inventory_location_id
        ,gmd_in_pr_e70.item_id                         AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itp_in_pr_e70.trans_date                      AS arrival_date
--        ,itp_in_pr_e70.trans_date                      AS leaving_date
        ,TRUNC(itp_in_pr_e70.trans_date)               AS arrival_date
        ,TRUNC(itp_in_pr_e70.trans_date)               AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status         -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_in_pr_e70.batch_no                        AS voucher_no
        ,grt_in_pr_e70.routing_desc                    AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itp_in_pr_e70.trans_qty                       AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   gme_batch_header             gbh_in_pr_e70                  -- 生産バッチ
        ,gme_material_details         gmd_in_pr_e70                  -- 生産原料詳細
        ,ic_tran_pnd                  itp_in_pr_e70                  -- OPM保留在庫トランザクション
        ,ic_whse_mst                  iwm_in_pr_e70                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_pr_e70                  -- OPM保管場所マスタ
        ,gmd_routings_b               grb_in_pr_e70                  -- 工順マスタ
        ,gmd_routings_tl              grt_in_pr_e70                  -- 工順マスタ日本語
        ,gmd_routing_class_b          grcb_in_pr_e70                 -- 工順区分マスタ
        ,gmd_routing_class_tl         grct_in_pr_e70                 -- 工順区分マスタ日本語
        ,(SELECT xrpm_in_pr_e70.new_div_invent
                ,flv_in_pr_e70.meaning
                ,xrpm_in_pr_e70.doc_type
                ,xrpm_in_pr_e70.routing_class
                ,xrpm_in_pr_e70.line_type
          FROM   fnd_lookup_values flv_in_pr_e70                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_in_pr_e70                    -- 受払区分アドオンマスタ
          WHERE  flv_in_pr_e70.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_in_pr_e70.language                 = 'JA'
          AND    flv_in_pr_e70.lookup_code              = xrpm_in_pr_e70.new_div_invent
          AND    xrpm_in_pr_e70.doc_type                = 'PROD'
          AND    xrpm_in_pr_e70.use_div_invent          = 'Y'
         ) xrpm
  WHERE  gbh_in_pr_e70.batch_id                 = gmd_in_pr_e70.batch_id
  AND    gmd_in_pr_e70.batch_id                 = itp_in_pr_e70.doc_id
  AND    gmd_in_pr_e70.line_no                  = itp_in_pr_e70.doc_line
  AND    gmd_in_pr_e70.line_type                = itp_in_pr_e70.line_type
  AND    grct_in_pr_e70.routing_class_desc     IN (FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET')       -- 返品原料
                                                  ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE')) -- 解体半製品
  AND    grct_in_pr_e70.language                = 'JA'
  AND    grct_in_pr_e70.routing_class           = grcb_in_pr_e70.routing_class
  AND    grcb_in_pr_e70.routing_class           = grb_in_pr_e70.routing_class
  AND    grt_in_pr_e70.language                 = 'JA'
  AND    grb_in_pr_e70.routing_id               = grt_in_pr_e70.routing_id
  AND    itp_in_pr_e70.delete_mark              = 0                  -- 有効チェック(OPM保留在庫)
  AND    gmd_in_pr_e70.line_type                = 1                  -- 完成品
  AND    itp_in_pr_e70.doc_type                 = xrpm.doc_type
  AND    itp_in_pr_e70.completed_ind            = 1
  AND    itp_in_pr_e70.lot_id                   = 0
  AND    itp_in_pr_e70.location                 = mil_in_pr_e70.segment1
  AND    mil_in_pr_e70.organization_id          = iwm_in_pr_e70.mtl_organization_id
-- 2009/02/13 Y.Kawano Upd Start
--  AND    grb_in_pr_e70.attribute9               = mil_in_pr_e70.segment1
  AND    itp_in_pr_e70.reverse_id              IS NULL
-- 2009/02/13 Y.Kawano Upd End
  AND    grb_in_pr_e70.routing_id               = gbh_in_pr_e70.routing_id
  AND    xrpm.routing_class                     = grb_in_pr_e70.routing_class
  AND    xrpm.line_type                         = gmd_in_pr_e70.line_type
  UNION ALL
  -- 倉替返品 入庫実績
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_po_e_rma.attribute1                    AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_po_e_rma.attribute1                    AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_po_e_rma.inventory_location_id         AS inventory_location_id
        ,xmld_in_po_e_rma.item_id                      AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xoha_in_po_e_rma.arrival_date                 AS arrival_date
--        ,xoha_in_po_e_rma.shipped_date                 AS leaving_date
        ,TRUNC(xoha_in_po_e_rma.arrival_date)          AS arrival_date
        ,TRUNC(xoha_in_po_e_rma.shipped_date)          AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status              -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_in_po_e_rma.request_no                   AS voucher_no
-- 2008/12/01 Upd Y.Kawano Start
--        ,hpat_in_po_e_rma.attribute19                  AS ukebaraisaki_name
        ,xp_in_po_e_rma.party_name                     AS ukebaraisaki_name
-- 2008/12/01 Upd Y.Kawano End
        ,xpas_in_po_e_rma.party_site_name              AS deliver_to_name
        ,xmld_in_po_e_rma.actual_quantity              AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxwsh_order_headers_all      xoha_in_po_e_rma                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_in_po_e_rma                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_in_po_e_rma                 -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_in_po_e_rma                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_po_e_rma                  -- OPM保管場所マスタ
        ,oe_transaction_types_all     otta_in_po_e_rma                 -- 受注タイプ
-- 2009/01/23 Upd N.Yoshida Start
--        ,hz_parties                   hpat_in_po_e_rma
-- 2009/01/23 Upd N.Yoshida End
        ,hz_cust_accounts             hcsa_in_po_e_rma
        ,hz_party_sites               hpas_in_po_e_rma
        ,xxcmn_party_sites            xpas_in_po_e_rma
        ,(SELECT xrpm_in_po_e_rma.new_div_invent
                ,flv_in_po_e_rma.meaning
                ,xrpm_in_po_e_rma.shipment_provision_div
                ,xrpm_in_po_e_rma.ship_prov_rcv_pay_category
          FROM   fnd_lookup_values flv_in_po_e_rma                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_in_po_e_rma                    -- 受払区分アドオンマスタ
          WHERE  flv_in_po_e_rma.lookup_type                  = 'XXCMN_NEW_DIVISION'
          AND    flv_in_po_e_rma.language                     = 'JA'
          AND    flv_in_po_e_rma.lookup_code                  = xrpm_in_po_e_rma.new_div_invent
          AND    xrpm_in_po_e_rma.doc_type                    = 'PORC'
          AND    xrpm_in_po_e_rma.source_document_code        = 'RMA'
          AND    xrpm_in_po_e_rma.use_div_invent              = 'Y'
          AND    xrpm_in_po_e_rma.rcv_pay_div                 = '1'            -- 受入
         ) xrpm
-- 2008/12/01 Upd Y.Kawano Start
        ,xxcmn_parties                xp_in_po_e_rma
-- 2008/12/01 Upd Y.Kawano End
  WHERE  xoha_in_po_e_rma.order_header_id             = xola_in_po_e_rma.order_header_id
  AND    xola_in_po_e_rma.order_line_id               = xmld_in_po_e_rma.mov_line_id
  AND    xoha_in_po_e_rma.deliver_from_id             = mil_in_po_e_rma.inventory_location_id
  AND    mil_in_po_e_rma.organization_id              = iwm_in_po_e_rma.mtl_organization_id
  AND    xmld_in_po_e_rma.lot_id                      = 0
  AND    xmld_in_po_e_rma.document_type_code          = '10'           -- 出荷依頼
  AND    xmld_in_po_e_rma.record_type_code            = '20'           -- 出庫実績
  AND    xoha_in_po_e_rma.order_type_id               = otta_in_po_e_rma.transaction_type_id
  AND    otta_in_po_e_rma.attribute1                  = '3'            -- 倉替返品
  AND    otta_in_po_e_rma.attribute1                  = xrpm.shipment_provision_div
  AND    xoha_in_po_e_rma.req_status                  = '04'           -- 出荷実績計上済
  AND    xrpm.ship_prov_rcv_pay_category              = otta_in_po_e_rma.attribute11
                                                                        -- 受払区分アドオンを複数読まない為
  AND    otta_in_po_e_rma.attribute11                 in  ('03','04')
  AND    otta_in_po_e_rma.order_category_code         = 'RETURN'
  AND    xoha_in_po_e_rma.latest_external_flag        = 'Y'            -- ON
  AND    xola_in_po_e_rma.delete_flag                 = 'N'            -- OFF
-- 2009/01/23 Upd N.Yoshida Start
--  AND    xoha_in_po_e_rma.customer_id                 = hpat_in_po_e_rma.party_id
--  AND    hpat_in_po_e_rma.party_id                    = hcsa_in_po_e_rma.party_id
  AND    xoha_in_po_e_rma.head_sales_branch           = hcsa_in_po_e_rma.account_number
-- 2009/01/23 Upd N.Yoshida End
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    hpat_in_po_e_rma.status                      = 'A'
--  AND    hcsa_in_po_e_rma.status                      = 'A'
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xoha_in_po_e_rma.result_deliver_to_id        = hpas_in_po_e_rma.party_site_id
  AND    hpas_in_po_e_rma.party_site_id               = xpas_in_po_e_rma.party_site_id
  AND    hpas_in_po_e_rma.party_id                    = xpas_in_po_e_rma.party_id
  AND    hpas_in_po_e_rma.location_id                 = xpas_in_po_e_rma.location_id
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    hpas_in_po_e_rma.status                      = 'A'
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xpas_in_po_e_rma.start_date_active          <= TRUNC(SYSDATE)
  AND    xpas_in_po_e_rma.end_date_active            >= TRUNC(SYSDATE)
-- 2008/12/01 Upd Y.Kawano Start
-- 2009/01/23 Upd N.Yoshida Start
--  AND    hpat_in_po_e_rma.party_id                    = xp_in_po_e_rma.party_id
  AND    hcsa_in_po_e_rma.party_id                    = xp_in_po_e_rma.party_id
-- 2009/01/23 Upd N.Yoshida Start
  AND    xp_in_po_e_rma.start_date_active            <= TRUNC(SYSDATE)
  AND    xp_in_po_e_rma.end_date_active              >= TRUNC(SYSDATE)
-- 2008/12/01 Upd Y.Kawano End
-- 2009/01/30 Add Y.Kawano Start
  UNION ALL
  -- 倉替返品取消 入庫実績
  SELECT NULL                                           AS po_trans_id
        ,iwm_in_po_e_rma.attribute1                    AS ownership_code
        ,mil_in_po_e_rma.inventory_location_id         AS inventory_location_id
        ,xmld_in_po_e_rma.item_id                      AS item_id
        ,ilm_in_po_e_rma.lot_no                        AS lot_no
        ,ilm_in_po_e_rma.attribute1                    AS manufacture_date
        ,ilm_in_po_e_rma.attribute2                    AS uniqe_sign
        ,ilm_in_po_e_rma.attribute3                    AS expiration_date -- <---- ここまで共通
        ,TRUNC(xoha_in_po_e_rma.arrival_date)          AS arrival_date
        ,TRUNC(xoha_in_po_e_rma.shipped_date)          AS leaving_date
        ,'2'                                           AS status              -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_in_po_e_rma.request_no                   AS voucher_no
        ,xp_in_po_e_rma.party_name                     AS ukebaraisaki_name
        ,xpas_in_po_e_rma.party_site_name              AS deliver_to_name
        ,xmld_in_po_e_rma.actual_quantity*-1           AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   xxwsh_order_headers_all      xoha_in_po_e_rma                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_in_po_e_rma                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_in_po_e_rma                 -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_in_po_e_rma                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_po_e_rma                  -- OPM保管場所マスタ
        ,ic_lots_mst                  ilm_in_po_e_rma                  -- OPMロットマスタ
        ,oe_transaction_types_all     otta_in_po_e_rma                 -- 受注タイプ
        ,hz_cust_accounts             hcsa_in_po_e_rma
        ,hz_party_sites               hpas_in_po_e_rma
        ,xxcmn_party_sites            xpas_in_po_e_rma
        ,(SELECT xrpm_in_po_e_rma.new_div_invent
                ,flv_in_po_e_rma.meaning
                ,xrpm_in_po_e_rma.shipment_provision_div
                ,xrpm_in_po_e_rma.ship_prov_rcv_pay_category
          FROM   fnd_lookup_values flv_in_po_e_rma                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_in_po_e_rma                    -- 受払区分アドオンマスタ
          WHERE  flv_in_po_e_rma.lookup_type                  = 'XXCMN_NEW_DIVISION'
          AND    flv_in_po_e_rma.language                     = 'JA'
          AND    flv_in_po_e_rma.lookup_code                  = xrpm_in_po_e_rma.new_div_invent
          AND    xrpm_in_po_e_rma.doc_type                    = 'OMSO'
          AND    xrpm_in_po_e_rma.use_div_invent              = 'Y'
          AND    xrpm_in_po_e_rma.rcv_pay_div                 = '1'            -- 受入
         ) xrpm
        ,xxcmn_parties                xp_in_po_e_rma
  WHERE  xoha_in_po_e_rma.order_header_id             = xola_in_po_e_rma.order_header_id
  AND    xola_in_po_e_rma.order_line_id               = xmld_in_po_e_rma.mov_line_id
  AND    xoha_in_po_e_rma.deliver_from_id             = mil_in_po_e_rma.inventory_location_id
  AND    mil_in_po_e_rma.organization_id              = iwm_in_po_e_rma.mtl_organization_id
  AND    xmld_in_po_e_rma.item_id                     = ilm_in_po_e_rma.item_id
  AND    xmld_in_po_e_rma.lot_id                      = ilm_in_po_e_rma.lot_id
  AND    xmld_in_po_e_rma.document_type_code          = '10'           -- 出荷依頼
  AND    xmld_in_po_e_rma.record_type_code            = '20'           -- 出庫実績
  AND    xoha_in_po_e_rma.order_type_id               = otta_in_po_e_rma.transaction_type_id
  AND    otta_in_po_e_rma.attribute1                  = '3'            -- 倉替返品
  AND    otta_in_po_e_rma.attribute1                  = xrpm.shipment_provision_div
  AND    xoha_in_po_e_rma.req_status                  = '04'           -- 出荷実績計上済
  AND    xrpm.ship_prov_rcv_pay_category              = otta_in_po_e_rma.attribute11
                                                                        -- 受払区分アドオンを複数読まない為
  AND    otta_in_po_e_rma.attribute11                 in  ('03','04')
  AND    otta_in_po_e_rma.order_category_code         = 'ORDER'
  AND    xoha_in_po_e_rma.latest_external_flag        = 'Y'            -- ON
  AND    xola_in_po_e_rma.delete_flag                 = 'N'            -- OFF
  AND    xoha_in_po_e_rma.head_sales_branch           = hcsa_in_po_e_rma.account_number
  AND    xoha_in_po_e_rma.result_deliver_to_id        = hpas_in_po_e_rma.party_site_id
  AND    hpas_in_po_e_rma.party_site_id               = xpas_in_po_e_rma.party_site_id
  AND    hpas_in_po_e_rma.party_id                    = xpas_in_po_e_rma.party_id
  AND    hpas_in_po_e_rma.location_id                 = xpas_in_po_e_rma.location_id
  AND    xpas_in_po_e_rma.start_date_active          <= TRUNC(SYSDATE)
  AND    xpas_in_po_e_rma.end_date_active            >= TRUNC(SYSDATE)
  AND    hcsa_in_po_e_rma.party_id                    = xp_in_po_e_rma.party_id
  AND    xp_in_po_e_rma.start_date_active            <= TRUNC(SYSDATE)
  AND    xp_in_po_e_rma.end_date_active              >= TRUNC(SYSDATE)
-- 2009/01/30 Add Y.Kawano End
  UNION ALL
  -- 在庫調整 入庫実績(相手先在庫)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_ad_e_x97.attribute1                    AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_ad_e_x97.attribute1                    AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_ad_e_x97.inventory_location_id         AS inventory_location_id
        ,itc_in_ad_e_x97.item_id                       AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itc_in_ad_e_x97.trans_date                    AS arrival_date
--        ,itc_in_ad_e_x97.trans_date                    AS leaving_date
        ,TRUNC(itc_in_ad_e_x97.trans_date)             AS arrival_date
        ,TRUNC(itc_in_ad_e_x97.trans_date)             AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status        -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,ijm_in_ad_e_x97.journal_no                    AS voucher_no
        ,xrpm.meaning                                  AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itc_in_ad_e_x97.trans_qty                     AS leaving_quantity
        ,0                                             AS stock_quantity
  FROM   ic_tran_cmp                  itc_in_ad_e_x97                        -- OPM完了在庫トランザクション
        ,ic_jrnl_mst                  ijm_in_ad_e_x97                        -- OPMジャーナルマスタ
        ,ic_adjs_jnl                  iaj_in_ad_e_x97                        -- OPM在庫調整ジャーナル
        ,ic_whse_mst                  iwm_in_ad_e_x97                        -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_ad_e_x97                        -- OPM保管場所マスタ
        ,(SELECT xrpm_in_ad_e_x97.new_div_invent
                ,flv_in_ad_e_x97.meaning
                ,xrpm_in_ad_e_x97.doc_type
                ,xrpm_in_ad_e_x97.reason_code
                ,xrpm_in_ad_e_x97.rcv_pay_div
          FROM   fnd_lookup_values flv_in_ad_e_x97                           -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_in_ad_e_x97                          -- 受払区分アドオンマスタ
          WHERE  flv_in_ad_e_x97.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_in_ad_e_x97.language                = 'JA'
          AND    flv_in_ad_e_x97.lookup_code             = xrpm_in_ad_e_x97.new_div_invent
          AND    xrpm_in_ad_e_x97.doc_type               = 'ADJI'
          AND    xrpm_in_ad_e_x97.use_div_invent         = 'Y'
          AND    xrpm_in_ad_e_x97.reason_code            = 'X977'            -- 相手先在庫
          AND    xrpm_in_ad_e_x97.rcv_pay_div            = '1'               -- 受入
         ) xrpm
  WHERE  itc_in_ad_e_x97.doc_type                = xrpm.doc_type
  AND    itc_in_ad_e_x97.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_in_ad_e_x97.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_in_ad_e_x97.lot_id                  = 0
  AND    itc_in_ad_e_x97.whse_code               = iwm_in_ad_e_x97.whse_code
  AND    itc_in_ad_e_x97.location                = mil_in_ad_e_x97.segment1
  AND    mil_in_ad_e_x97.organization_id         = iwm_in_ad_e_x97.mtl_organization_id
  AND    ijm_in_ad_e_x97.journal_id              = iaj_in_ad_e_x97.journal_id   --OPMジャーナルマスタ抽出条件
  AND    iaj_in_ad_e_x97.doc_id                  = itc_in_ad_e_x97.doc_id       --OPM在庫調整ジャーナル抽出条件
  AND    iaj_in_ad_e_x97.doc_line                = itc_in_ad_e_x97.doc_line     --OPM在庫調整ジャーナル抽出条件
  AND    ijm_in_ad_e_x97.attribute1             IS NULL                         --OPMジャーナルマスタ.実績IDがNULL
-- 2008/12/24 #809 Y.Yamamoto add start
  AND    ijm_in_ad_e_x97.attribute4              = 'Y'
-- 2008/12/24 #809 Y.Yamamoto add end
  UNION ALL
  -- 在庫調整 入庫実績(外注出来高)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_ad_e_x97.attribute1                    AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_ad_e_x97.attribute1                    AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_ad_e_x97.inventory_location_id         AS inventory_location_id
        ,itc_in_ad_e_x97.item_id                       AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itc_in_ad_e_x97.trans_date                    AS arrival_date
--        ,itc_in_ad_e_x97.trans_date                    AS leaving_date
        ,TRUNC(itc_in_ad_e_x97.trans_date)             AS arrival_date
        ,TRUNC(itc_in_ad_e_x97.trans_date)             AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status        -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,NULL                                          AS voucher_no        -- 伝票No
        ,xv_in_ad_e_x97.vendor_name                    AS ukebaraisaki_name -- 受払先名
        ,NULL                                          AS deliver_to_name
        ,itc_in_ad_e_x97.trans_qty                     AS leaving_quantity
        ,0                                             AS stock_quantity
  FROM   ic_tran_cmp                  itc_in_ad_e_x97                        -- OPM完了在庫トランザクション
        ,ic_jrnl_mst                  ijm_in_ad_e_x97                        -- OPMジャーナルマスタ
        ,ic_adjs_jnl                  iaj_in_ad_e_x97                        -- OPM在庫調整ジャーナル
        ,ic_whse_mst                  iwm_in_ad_e_x97                        -- OPM倉庫マスタ
        ,xxpo_vendor_supply_txns      xvst_in_ad_e_x97                       -- 外注出来高実績
        ,mtl_item_locations           mil_in_ad_e_x97                        -- OPM保管場所マスタ
        ,po_vendors                   pv_in_ad_e_x97                         -- 仕入先マスタ
        ,xxcmn_vendors                xv_in_ad_e_x97                         -- 仕入先アドオンマスタ
        ,(SELECT xrpm_in_ad_e_x97.new_div_invent
                ,flv_in_ad_e_x97.meaning
                ,xrpm_in_ad_e_x97.doc_type
                ,xrpm_in_ad_e_x97.reason_code
                ,xrpm_in_ad_e_x97.rcv_pay_div
          FROM   fnd_lookup_values    flv_in_ad_e_x97                           -- クイックコード
                ,xxcmn_rcv_pay_mst    xrpm_in_ad_e_x97                          -- 受払区分アドオンマスタ
          WHERE  flv_in_ad_e_x97.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_in_ad_e_x97.language                = 'JA'
          AND    flv_in_ad_e_x97.lookup_code             = xrpm_in_ad_e_x97.new_div_invent
          AND    xrpm_in_ad_e_x97.doc_type               = 'ADJI'
          AND    xrpm_in_ad_e_x97.use_div_invent         = 'Y'
          AND    xrpm_in_ad_e_x97.reason_code            = 'X977'               -- 相手先在庫
          AND    xrpm_in_ad_e_x97.rcv_pay_div            = '1'                  -- 受入
         ) xrpm
  WHERE  itc_in_ad_e_x97.doc_type                = xrpm.doc_type
  AND    itc_in_ad_e_x97.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_in_ad_e_x97.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_in_ad_e_x97.lot_id                  = 0
  AND    itc_in_ad_e_x97.whse_code               = iwm_in_ad_e_x97.whse_code
  AND    itc_in_ad_e_x97.location                = mil_in_ad_e_x97.segment1
  AND    mil_in_ad_e_x97.organization_id         = iwm_in_ad_e_x97.mtl_organization_id
  AND    ijm_in_ad_e_x97.journal_id              = iaj_in_ad_e_x97.journal_id         -- OPMジャーナルマスタ抽出条件
  AND    iaj_in_ad_e_x97.doc_id                  = itc_in_ad_e_x97.doc_id             -- OPM在庫調整ジャーナル抽出条件
  AND    iaj_in_ad_e_x97.doc_line                = itc_in_ad_e_x97.doc_line           -- OPM在庫調整ジャーナル抽出条件
  AND    ijm_in_ad_e_x97.attribute1             IS NOT NULL                           -- OPMジャーナルマスタ.実績IDがNULLでない
  AND    ijm_in_ad_e_x97.attribute1              = TO_CHAR(xvst_in_ad_e_x97.txns_id)  -- 実績ID
-- 2008/12/24 #809 Y.Yamamoto add start
  AND    ijm_in_ad_e_x97.attribute4              = 'Y'
-- 2008/12/24 #809 Y.Yamamoto add end
  AND    xvst_in_ad_e_x97.vendor_id              = xv_in_ad_e_x97.vendor_id          -- 仕入先ID
  AND    pv_in_ad_e_x97.vendor_id                = xv_in_ad_e_x97.vendor_id
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    pv_in_ad_e_x97.end_date_active         IS NULL
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xv_in_ad_e_x97.start_date_active       <= TRUNC( SYSDATE )
  AND    xv_in_ad_e_x97.end_date_active         >= TRUNC( SYSDATE )
  UNION ALL
  -- 在庫調整 入庫実績(浜岡入庫)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_ad_e_x9.attribute1                     AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_ad_e_x9.attribute1                     AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_ad_e_x9.inventory_location_id          AS inventory_location_id
        ,itc_in_ad_e_x9.item_id                        AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itc_in_ad_e_x9.trans_date                     AS arrival_date
--        ,itc_in_ad_e_x9.trans_date                     AS leaving_date
        ,TRUNC(itc_in_ad_e_x9.trans_date)              AS arrival_date
        ,TRUNC(itc_in_ad_e_x9.trans_date)              AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status      -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xnpt_in_ad_e_x9.entry_number                  AS voucher_no
        ,xrpm.meaning                                  AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itc_in_ad_e_x9.trans_qty                      AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   ic_adjs_jnl                  iaj_in_ad_e_x9                        -- OPM在庫調整ジャーナル
        ,ic_jrnl_mst                  ijm_in_ad_e_x9                        -- OPMジャーナルマスタ
        ,ic_tran_cmp                  itc_in_ad_e_x9                        -- OPM完了在庫トランザクション
        ,xxpo_namaha_prod_txns        xnpt_in_ad_e_x9                       -- 生葉実績（アドオン）
        ,ic_whse_mst                  iwm_in_ad_e_x9                        -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_ad_e_x9                        -- OPM保管場所マスタ
        ,(SELECT xrpm_in_ad_e_x9.new_div_invent
                ,flv_in_ad_e_x9.meaning
                ,xrpm_in_ad_e_x9.doc_type
                ,xrpm_in_ad_e_x9.reason_code
                ,xrpm_in_ad_e_x9.rcv_pay_div
          FROM   fnd_lookup_values flv_in_ad_e_x9                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_in_ad_e_x9                    -- 受払区分アドオンマスタ
          WHERE  flv_in_ad_e_x9.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_in_ad_e_x9.language                = 'JA'
          AND    flv_in_ad_e_x9.lookup_code             = xrpm_in_ad_e_x9.new_div_invent
          AND    xrpm_in_ad_e_x9.doc_type               = 'ADJI'
          AND    xrpm_in_ad_e_x9.use_div_invent         = 'Y'
          AND    xrpm_in_ad_e_x9.reason_code            = 'X988'               -- 浜岡入庫
          AND    xrpm_in_ad_e_x9.rcv_pay_div            = '1'                  -- 受入
         ) xrpm
  WHERE  itc_in_ad_e_x9.doc_type                = xrpm.doc_type
  AND    itc_in_ad_e_x9.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_in_ad_e_x9.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_in_ad_e_x9.lot_id                  = 0
  AND    itc_in_ad_e_x9.whse_code               = iwm_in_ad_e_x9.whse_code
  AND    itc_in_ad_e_x9.location                = mil_in_ad_e_x9.segment1
  AND    mil_in_ad_e_x9.organization_id         = iwm_in_ad_e_x9.mtl_organization_id
  AND    iaj_in_ad_e_x9.journal_id              = ijm_in_ad_e_x9.journal_id
-- 2008/12/24 #809 Y.Yamamoto add start
-- 2008/12/29 #809 Y.Yamamoto delete start
--  AND    ijm_in_ad_e_x9.attribute4              = 'Y'
-- 2008/12/29 #809 Y.Yamamoto delete end
-- 2008/12/24 #809 Y.Yamamoto add end
  AND    itc_in_ad_e_x9.doc_type                = iaj_in_ad_e_x9.trans_type
  AND    itc_in_ad_e_x9.doc_id                  = iaj_in_ad_e_x9.doc_id
  AND    itc_in_ad_e_x9.doc_line                = iaj_in_ad_e_x9.doc_line
-- 2009/11/06 #1685 Y.Fukami update start
--  AND    ijm_in_ad_e_x9.attribute1              = xnpt_in_ad_e_x9.entry_number
  AND    ijm_in_ad_e_x9.attribute1              = xnpt_in_ad_e_x9.txns_id
-- 2009/11/06 #1685 Y.Fukami update end
  UNION ALL
-- 2008/12/3 Y.Kawano delete start
--  -- 在庫調整 入庫実績(移動実績訂正)
--  SELECT iwm_in_ad_e_xx.attribute1                     AS ownership_code
--        ,mil_in_ad_e_xx.inventory_location_id          AS inventory_location_id
--        ,itc_in_ad_e_xx.item_id                        AS item_id
--        ,NULL                                          AS lot_no
--        ,NULL                                          AS manufacture_date
--        ,NULL                                          AS uniqe_sign
--        ,NULL                                          AS expiration_date -- <---- ここまで共通
--        ,itc_in_ad_e_xx.trans_date                     AS arrival_date
--        ,itc_in_ad_e_xx.trans_date                     AS leaving_date
--        ,'2'                                           AS status   -- 実績
--        ,xrpm.new_div_invent                           AS reason_code
--        ,xrpm.meaning                                  AS reason_code_name
--        ,xmrih_in_ad_e_xx.mov_num                      AS voucher_no
--        ,mil2_in_ad_e_xx.description                   AS ukebaraisaki_name
--        ,NULL                                          AS deliver_to_name
--        ,0                                             AS stock_quantity
---- 2008/10/31 Y.Yamamoto v1.1 update start
----        ,ABS(itc_in_ad_e_xx.trans_qty)                 AS leaving_quantity
--        ,itc_in_ad_e_xx.trans_qty                      AS leaving_quantity
---- 2008/10/31 Y.Yamamoto v1.1 update end
--  FROM   xxinv_mov_req_instr_headers  xmrih_in_ad_e_xx               -- 移動依頼/指示ヘッダ(アドオン)
--        ,xxinv_mov_req_instr_lines    xmril_in_ad_e_xx               -- 移動依頼/指示明細(アドオン)
--        ,xxinv_mov_lot_details        xmldt_in_ad_e_xx               -- 移動ロット詳細(アドオン)
--        ,ic_adjs_jnl                  iaj_in_ad_e_xx                 -- OPM在庫調整ジャーナル
--        ,ic_jrnl_mst                  ijm_in_ad_e_xx                 -- OPMジャーナルマスタ
--        ,ic_tran_cmp                  itc_in_ad_e_xx                 -- OPM完了在庫トランザクション
--        ,ic_whse_mst                  iwm_in_ad_e_xx                 -- OPM倉庫マスタ
--        ,mtl_item_locations           mil_in_ad_e_xx                 -- OPM保管場所マスタ
--        ,mtl_item_locations           mil2_in_ad_e_xx                -- OPM保管場所マスタ
--        ,(SELECT xrpm_in_ad_e_xx.new_div_invent
--                ,flv_in_ad_e_xx.meaning
--                ,xrpm_in_ad_e_xx.doc_type
--                ,xrpm_in_ad_e_xx.reason_code
--                ,xrpm_in_ad_e_xx.rcv_pay_div
--          FROM   fnd_lookup_values flv_in_ad_e_xx                    -- クイックコード
--                ,xxcmn_rcv_pay_mst xrpm_in_ad_e_xx                   -- 受払区分アドオンマスタ
--          WHERE  flv_in_ad_e_xx.lookup_type             = 'XXCMN_NEW_DIVISION'
--          AND    flv_in_ad_e_xx.language                = 'JA'
--          AND    flv_in_ad_e_xx.lookup_code             = xrpm_in_ad_e_xx.new_div_invent
--          AND    xrpm_in_ad_e_xx.doc_type               = 'ADJI'
--          AND    xrpm_in_ad_e_xx.use_div_invent         = 'Y'
--          AND    xrpm_in_ad_e_xx.reason_code            = 'X123'               -- 移動実績訂正
--          AND    xrpm_in_ad_e_xx.rcv_pay_div            = '-1'                 -- 払出
--         ) xrpm
--  WHERE  xmrih_in_ad_e_xx.mov_hdr_id            = xmril_in_ad_e_xx.mov_hdr_id
--  AND    xmril_in_ad_e_xx.mov_line_id           = xmldt_in_ad_e_xx.mov_line_id
--  AND    itc_in_ad_e_xx.doc_type                = xrpm.doc_type
--  AND    itc_in_ad_e_xx.reason_code             = xrpm.reason_code
---- 2008/10/23 Y.Yamamoto v1.1 delete start
----  AND    SIGN( itc_in_ad_e_xx.trans_qty )       = xrpm.rcv_pay_div
---- 2008/10/23 Y.Yamamoto v1.1 delete end
--  AND    itc_in_ad_e_xx.item_id                 = xmril_in_ad_e_xx.item_id
--  AND    itc_in_ad_e_xx.lot_id                  = xmldt_in_ad_e_xx.lot_id
--  AND    itc_in_ad_e_xx.location                = xmrih_in_ad_e_xx.ship_to_locat_code
--  AND    itc_in_ad_e_xx.doc_type                = iaj_in_ad_e_xx.trans_type
--  AND    itc_in_ad_e_xx.doc_id                  = iaj_in_ad_e_xx.doc_id
--  AND    itc_in_ad_e_xx.doc_line                = iaj_in_ad_e_xx.doc_line
--  AND    iaj_in_ad_e_xx.journal_id              = ijm_in_ad_e_xx.journal_id
--  AND    xmril_in_ad_e_xx.mov_line_id           = TO_NUMBER( ijm_in_ad_e_xx.attribute1 )
--  AND    xmrih_in_ad_e_xx.ship_to_locat_id      = mil_in_ad_e_xx.inventory_location_id
--  AND    mil_in_ad_e_xx.organization_id         = iwm_in_ad_e_xx.mtl_organization_id
--  AND    xmrih_in_ad_e_xx.shipped_locat_id      = mil2_in_ad_e_xx.inventory_location_id
--  AND    xmldt_in_ad_e_xx.record_type_code      = '30'
--  AND    xmldt_in_ad_e_xx.document_type_code    = '20'
--  AND    xmldt_in_ad_e_xx.lot_id                = 0
--  UNION ALL
-- 2008/12/3 Y.Kawano delete end
  -- 在庫調整 入庫実績(上記以外)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_in_ad_e_xx.attribute1                     AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_in_ad_e_xx.attribute1                     AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_in_ad_e_xx.inventory_location_id          AS inventory_location_id
        ,itc_in_ad_e_xx.item_id                        AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itc_in_ad_e_xx.trans_date                     AS arrival_date
--        ,itc_in_ad_e_xx.trans_date                     AS leaving_date
        ,TRUNC(itc_in_ad_e_xx.trans_date)              AS arrival_date
        ,TRUNC(itc_in_ad_e_xx.trans_date)              AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status   -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,ijm_in_ad_e_xx.journal_no                     AS voucher_no
        ,xrpm.meaning                                  AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,itc_in_ad_e_xx.trans_qty                      AS stock_quantity
        ,0                                             AS leaving_quantity
  FROM   ic_adjs_jnl                  iaj_in_ad_e_xx                 -- OPM在庫調整ジャーナル
        ,ic_jrnl_mst                  ijm_in_ad_e_xx                 -- OPMジャーナルマスタ
        ,ic_tran_cmp                  itc_in_ad_e_xx                 -- OPM完了在庫トランザクション
        ,ic_whse_mst                  iwm_in_ad_e_xx                 -- OPM倉庫マスタ
        ,mtl_item_locations           mil_in_ad_e_xx                 -- OPM保管場所マスタ
        ,(SELECT xrpm_in_ad_e_xx.new_div_invent
                ,flv_in_ad_e_xx.meaning
                ,xrpm_in_ad_e_xx.doc_type
                ,xrpm_in_ad_e_xx.reason_code
                ,xrpm_in_ad_e_xx.rcv_pay_div
          FROM   fnd_lookup_values flv_in_ad_e_xx                    -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_in_ad_e_xx                   -- 受払区分アドオンマスタ
          WHERE  flv_in_ad_e_xx.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_in_ad_e_xx.language                = 'JA'
          AND    flv_in_ad_e_xx.lookup_code             = xrpm_in_ad_e_xx.new_div_invent
          AND    xrpm_in_ad_e_xx.doc_type               = 'ADJI'
          AND    xrpm_in_ad_e_xx.use_div_invent         = 'Y'
-- 2008/12/11 T.Ohashi start
--          AND    xrpm_in_ad_e_xx.reason_code       NOT IN ('X977','X988','X123')
          AND    xrpm_in_ad_e_xx.reason_code       NOT IN ('X977','X988','X123','X201')
-- 2008/12/11 T.Ohashi end
          AND    xrpm_in_ad_e_xx.rcv_pay_div            = '1'                  -- 受入
         ) xrpm
  WHERE  itc_in_ad_e_xx.doc_type                = xrpm.doc_type
  AND    itc_in_ad_e_xx.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_in_ad_e_xx.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_in_ad_e_xx.lot_id                  = 0
  AND    itc_in_ad_e_xx.whse_code               = iwm_in_ad_e_xx.whse_code
  AND    itc_in_ad_e_xx.location                = mil_in_ad_e_xx.segment1
  AND    mil_in_ad_e_xx.organization_id         = iwm_in_ad_e_xx.mtl_organization_id
  AND    iaj_in_ad_e_xx.journal_id              = ijm_in_ad_e_xx.journal_id
-- 2008/12/24 #809 Y.Yamamoto add start
-- 2008/12/29 #809 Y.Yamamoto delete start
--  AND    ijm_in_ad_e_xx.attribute4              = 'Y'
-- 2008/12/29 #809 Y.Yamamoto delete end
-- 2008/12/24 #809 Y.Yamamoto add end
  AND    itc_in_ad_e_xx.doc_type                = iaj_in_ad_e_xx.trans_type
  AND    itc_in_ad_e_xx.doc_id                  = iaj_in_ad_e_xx.doc_id
  AND    itc_in_ad_e_xx.doc_line                = iaj_in_ad_e_xx.doc_line
  UNION ALL
  ------------------------------------------------------------------------
  -- 出庫実績
  ------------------------------------------------------------------------
  -- 移動出庫実績(積送あり)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_xf_e.attribute1                       AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_xf_e.attribute1                       AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_xf_e.inventory_location_id            AS inventory_location_id
        ,xmld_out_xf_e.item_id                         AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xmrih_out_xf_e.actual_arrival_date            AS arrival_date
--        ,xmrih_out_xf_e.actual_ship_date               AS leaving_date
        ,TRUNC(xmrih_out_xf_e.actual_arrival_date)     AS arrival_date
        ,TRUNC(xmrih_out_xf_e.actual_ship_date)        AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status           -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_out_xf_e.mov_num                        AS voucher_no
        ,mil2_out_xf_e.description                     AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_xf_e.actual_quantity                 AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_out_xf_e                  -- 移動依頼/指示ヘッダ(アドオン)
        ,xxinv_mov_req_instr_lines    xmril_out_xf_e                  -- 移動依頼/指示明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_xf_e                   -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_out_xf_e                 -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_xf_e                 -- OPM保管場所マスタ
        ,mtl_item_locations           mil2_out_xf_e                -- OPM保管場所マスタ
        ,(SELECT xrpm_out_xf_e.new_div_invent
                ,flv_out_xf_e.meaning
          FROM   fnd_lookup_values flv_out_xf_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_xf_e                    -- 受払区分アドオンマスタ
          WHERE  flv_out_xf_e.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_xf_e.language                 = 'JA'
          AND    flv_out_xf_e.lookup_code              = xrpm_out_xf_e.new_div_invent
          AND    xrpm_out_xf_e.doc_type                = 'XFER'               -- 移動積送あり
          AND    xrpm_out_xf_e.use_div_invent          = 'Y'
          AND    xrpm_out_xf_e.rcv_pay_div             = '-1'
         ) xrpm
  WHERE  xmrih_out_xf_e.mov_hdr_id             = xmril_out_xf_e.mov_hdr_id
  AND    xmril_out_xf_e.mov_line_id            = xmld_out_xf_e.mov_line_id
  AND    xmrih_out_xf_e.shipped_locat_id       = mil_out_xf_e.inventory_location_id
  AND    mil_out_xf_e.organization_id          = iwm_out_xf_e.mtl_organization_id
  AND    xmrih_out_xf_e.ship_to_locat_id       = mil2_out_xf_e.inventory_location_id
  AND    xmld_out_xf_e.lot_id                  = 0
  AND    xmld_out_xf_e.document_type_code      = '20'                 -- 移動
  AND    xmld_out_xf_e.record_type_code        = '20'                -- 出庫実績
  AND    xmrih_out_xf_e.mov_type               = '1'                  -- 積送あり
  AND    xmril_out_xf_e.delete_flg             = 'N'                  -- OFF
  AND    xmrih_out_xf_e.status                IN ( '06'               -- 入出庫報告有
                                                  ,'04' )             -- 出庫報告有
  UNION ALL
  -- 移動出庫実績(積送なし)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_tr_e.attribute1                       AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_tr_e.attribute1                       AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_tr_e.inventory_location_id            AS inventory_location_id
        ,xmld_out_tr_e.item_id                         AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xmrih_out_tr_e.actual_arrival_date            AS arrival_date
--        ,xmrih_out_tr_e.actual_ship_date               AS leaving_date
        ,TRUNC(xmrih_out_tr_e.actual_arrival_date)     AS arrival_date
        ,TRUNC(xmrih_out_tr_e.actual_ship_date)        AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status        -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xmrih_out_tr_e.mov_num                        AS voucher_no
        ,mil2_out_tr_e.description                     AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_tr_e.actual_quantity                 AS leaving_quantity
  FROM   xxinv_mov_req_instr_headers  xmrih_out_tr_e               -- 移動依頼/指示ヘッダ(アドオン)
        ,xxinv_mov_req_instr_lines    xmril_out_tr_e               -- 移動依頼/指示明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_tr_e                -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_out_tr_e                 -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_tr_e                 -- OPM保管場所マスタ
        ,mtl_item_locations           mil2_out_tr_e                -- OPM保管場所マスタ
        ,(SELECT xrpm_out_tr_e.new_div_invent
                ,flv_out_tr_e.meaning
          FROM   fnd_lookup_values flv_out_tr_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_tr_e                    -- 受払区分アドオンマスタ
          WHERE  flv_out_tr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_tr_e.language                 = 'JA'
          AND    flv_out_tr_e.lookup_code              = xrpm_out_tr_e.new_div_invent
          AND    xrpm_out_tr_e.doc_type                = 'TRNI'            -- 移動積送なし
          AND    xrpm_out_tr_e.use_div_invent          = 'Y'
          AND    xrpm_out_tr_e.rcv_pay_div             = '-1'
         ) xrpm
  WHERE  xmrih_out_tr_e.mov_hdr_id             = xmril_out_tr_e.mov_hdr_id
  AND    xmril_out_tr_e.mov_line_id            = xmld_out_tr_e.mov_line_id
  AND    xmrih_out_tr_e.shipped_locat_id       = mil_out_tr_e.inventory_location_id
  AND    mil_out_tr_e.organization_id          = iwm_out_tr_e.mtl_organization_id
  AND    xmrih_out_tr_e.ship_to_locat_id       = mil2_out_tr_e.inventory_location_id
  AND    xmld_out_tr_e.lot_id                  = 0
  AND    xmld_out_tr_e.document_type_code      = '20'              -- 移動
  AND    xmld_out_tr_e.record_type_code        = '20'              -- 出庫実績
  AND    xmrih_out_tr_e.mov_type               = '2'               -- 積送なし
-- 2008/12/24 #752 Y.Yamamoto update start
--  AND    xmrih_out_tr_e.status                 = '06'              -- 入出庫報告有
  AND    xmrih_out_tr_e.status                IN ( '06'               -- 入出庫報告有
                                                  ,'04' )             -- 出庫報告有
-- 2008/12/24 #752 Y.Yamamoto update end
  AND    xmril_out_tr_e.delete_flg             = 'N'               -- OFF
  UNION ALL
  -- 生産出庫実績
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_pr_e.attribute1                       AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_pr_e.attribute1                       AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_pr_e.inventory_location_id            AS inventory_location_id
        ,itp_out_pr_e.item_id                          AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itp_out_pr_e.trans_date                       AS arrival_date
--        ,itp_out_pr_e.trans_date                       AS leaving_date
        ,TRUNC(itp_out_pr_e.trans_date)                AS arrival_date
        ,TRUNC(itp_out_pr_e.trans_date)                AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status         -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_out_pr_e.batch_no                         AS voucher_no
        ,grt_out_pr_e.routing_desc                     AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,ABS(itp_out_pr_e.trans_qty)                   AS leaving_quantity
  FROM   gme_batch_header             gbh_out_pr_e                  -- 生産バッチ
        ,gme_material_details         gmd_out_pr_e                  -- 生産原料詳細
        ,ic_tran_pnd                  itp_out_pr_e                  -- OPM保留在庫トランザクション
        ,gmd_routings_b               grb_out_pr_e                  -- 工順マスタ
        ,gmd_routings_tl              grt_out_pr_e                  -- 工順マスタ日本語
        ,ic_whse_mst                  iwm_out_pr_e                 -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_pr_e                 -- OPM保管場所マスタ
        ,(SELECT xrpm_out_pr_e.new_div_invent
                ,flv_out_pr_e.meaning
                ,xrpm_out_pr_e.doc_type
                ,xrpm_out_pr_e.routing_class
                ,xrpm_out_pr_e.line_type
                ,xrpm_out_pr_e.hit_in_div
          FROM   fnd_lookup_values flv_out_pr_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_pr_e                    -- 受払区分アドオンマスタ
          WHERE  flv_out_pr_e.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_pr_e.language                 = 'JA'
          AND    flv_out_pr_e.lookup_code              = xrpm_out_pr_e.new_div_invent
          AND    xrpm_out_pr_e.doc_type                = 'PROD'
          AND    xrpm_out_pr_e.use_div_invent          = 'Y'
         ) xrpm
  WHERE  gbh_out_pr_e.batch_id                 = gmd_out_pr_e.batch_id
  AND    itp_out_pr_e.delete_mark              = 0                  -- 有効チェック(OPM保留在庫)
  AND    gmd_out_pr_e.line_type                = -1                 -- 投入品
  AND    itp_out_pr_e.completed_ind            = 1
  AND    itp_out_pr_e.reverse_id              IS NULL
  AND    itp_out_pr_e.doc_type                 = xrpm.doc_type
  AND    itp_out_pr_e.lot_id                   = 0
  AND    itp_out_pr_e.location                 = mil_out_pr_e.segment1
  AND    mil_out_pr_e.organization_id          = iwm_out_pr_e.mtl_organization_id
  AND    itp_out_pr_e.item_id                  = gmd_out_pr_e.item_id
  AND    itp_out_pr_e.doc_id                   = gmd_out_pr_e.batch_id
  AND    itp_out_pr_e.doc_line                 = gmd_out_pr_e.line_no
  AND    itp_out_pr_e.line_type                = gmd_out_pr_e.line_type
  AND    grb_out_pr_e.attribute9               = mil_out_pr_e.segment1
  AND    grb_out_pr_e.routing_id               = gbh_out_pr_e.routing_id
  AND    xrpm.routing_class                    = grb_out_pr_e.routing_class
  AND    xrpm.line_type                        = gmd_out_pr_e.line_type
  AND ((( gmd_out_pr_e.attribute5             IS NULL )
    AND ( xrpm.hit_in_div                     IS NULL ))
  OR   (( gmd_out_pr_e.attribute5              = 'Y' )
    AND ( xrpm.hit_in_div                      = gmd_out_pr_e.attribute5 )))
  AND    grb_out_pr_e.routing_id               = grt_out_pr_e.routing_id
  AND    grt_out_pr_e.language                 = 'JA'
  AND NOT EXISTS 
    ( SELECT 1
      FROM   gmd_routing_class_b   grcb_out_pr_ex          -- 工順区分マスタ
            ,gmd_routing_class_tl  grct_out_pr_ex          -- 工順区分マスタ日本語
      WHERE  grcb_out_pr_ex.routing_class      = grb_out_pr_e.routing_class
      AND    grct_out_pr_ex.routing_class      = grcb_out_pr_ex.routing_class
      AND    grct_out_pr_ex.language           = 'JA'
      AND    grct_out_pr_ex.routing_class_desc IN (FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING')
                                                  ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE')
                                                  ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET'))
    )
  UNION ALL
  -- 生産出庫実績 品目振替 品種振替
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_pr_e70.attribute1                     AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_pr_e70.attribute1                     AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_pr_e70.inventory_location_id          AS inventory_location_id
        ,gmd_out_pr_e70a.item_id                       AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itp_out_pr_e70.trans_date                     AS arrival_date
--        ,itp_out_pr_e70.trans_date                     AS leaving_date
        ,TRUNC(itp_out_pr_e70.trans_date)              AS arrival_date
        ,TRUNC(itp_out_pr_e70.trans_date)              AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status            -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_out_pr_e70.batch_no                       AS voucher_no
        ,grt_out_pr_e70.routing_desc                   AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,ABS(itp_out_pr_e70.trans_qty)                 AS leaving_quantity
  FROM   gme_batch_header             gbh_out_pr_e70                  -- 生産バッチ
        ,gme_material_details         gmd_out_pr_e70a                 -- 生産原料詳細(振替元)
        ,gme_material_details         gmd_out_pr_e70b                 -- 生産原料詳細(振替先)
        ,ic_tran_pnd                  itp_out_pr_e70                  -- OPM保留在庫トランザクション
        ,ic_whse_mst                  iwm_out_pr_e70                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_pr_e70                  -- OPM保管場所マスタ
        ,gmd_routings_b               grb_out_pr_e70                  -- 工順マスタ
        ,gmd_routings_tl              grt_out_pr_e70                  -- 工順マスタ日本語
        ,gmd_routing_class_b          grcb_out_pr_e70                 -- 工順区分マスタ
        ,gmd_routing_class_tl         grct_out_pr_e70                 -- 工順区分マスタ日本語
-- 2008/10/31 Y.Yamamoto v1.1 update start
--        ,gmi_item_categories          gic_in_pr_e70_r
--        ,mtl_categories_b             mcb_in_pr_e70_r
        ,gmi_item_categories          gic_out_pr_e70_r
        ,mtl_categories_b             mcb_out_pr_e70_r
        ,gmi_item_categories          gic_out_pr_e70_s
        ,mtl_categories_b             mcb_out_pr_e70_s
-- 2008/10/31 Y.Yamamoto v1.1 update end
        ,(SELECT xrpm_out_pr_e70.new_div_invent
                ,flv_out_pr_e70.meaning
                ,xrpm_out_pr_e70.doc_type
                ,xrpm_out_pr_e70.routing_class
                ,xrpm_out_pr_e70.line_type
                ,xrpm_out_pr_e70.item_div_origin
                ,xrpm_out_pr_e70.item_div_ahead
          FROM   fnd_lookup_values flv_out_pr_e70                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_pr_e70                    -- 受払区分アドオンマスタ
          WHERE  flv_out_pr_e70.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_pr_e70.language                 = 'JA'
          AND    flv_out_pr_e70.lookup_code              = xrpm_out_pr_e70.new_div_invent
          AND    xrpm_out_pr_e70.doc_type                = 'PROD'
          AND    xrpm_out_pr_e70.use_div_invent          = 'Y'
         ) xrpm
  WHERE  gbh_out_pr_e70.batch_id                 = gmd_out_pr_e70a.batch_id
  AND    grct_out_pr_e70.language                = 'JA'
  AND    grct_out_pr_e70.routing_class           = grcb_out_pr_e70.routing_class
  AND    grcb_out_pr_e70.routing_class           = grb_out_pr_e70.routing_class
  AND    grt_out_pr_e70.language                 = 'JA'
  AND    grb_out_pr_e70.routing_id               = grt_out_pr_e70.routing_id
  AND    itp_out_pr_e70.delete_mark              = 0                  -- 有効チェック(OPM保留在庫)
  AND    gmd_out_pr_e70a.line_type               = -1                 -- 投入品
  AND    itp_out_pr_e70.doc_type                 = xrpm.doc_type
  AND    itp_out_pr_e70.doc_id                   = gmd_out_pr_e70a.batch_id
  AND    itp_out_pr_e70.doc_line                 = gmd_out_pr_e70a.line_no
  AND    itp_out_pr_e70.line_type                = gmd_out_pr_e70a.line_type
  AND    itp_out_pr_e70.completed_ind            = 1
  AND    itp_out_pr_e70.item_id                  = gmd_out_pr_e70a.item_id
  AND    itp_out_pr_e70.lot_id                   = 0
  AND    itp_out_pr_e70.whse_code                = iwm_out_pr_e70.whse_code
  AND    itp_out_pr_e70.location                 = mil_out_pr_e70.segment1
  AND    iwm_out_pr_e70.mtl_organization_id      = mil_out_pr_e70.organization_id
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    grb_out_pr_e70.attribute9               = mil_out_pr_e70.segment1
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    grb_out_pr_e70.routing_id               = gbh_out_pr_e70.routing_id
  AND    xrpm.routing_class                      = grb_out_pr_e70.routing_class
  AND    xrpm.line_type                          = gmd_out_pr_e70a.line_type
  AND    grct_out_pr_e70.routing_class_desc      = FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING')
-- 2008/10/31 Y.Yamamoto v1.1 update start
  AND    gic_out_pr_e70_s.item_id                = itp_out_pr_e70.item_id
  AND    gic_out_pr_e70_s.category_id            = mcb_out_pr_e70_s.category_id
  AND    gic_out_pr_e70_s.category_set_id        = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_pr_e70_s.segment1               = xrpm.item_div_ahead
  AND    gic_out_pr_e70_r.item_id                = gmd_out_pr_e70b.item_id
  AND    gic_out_pr_e70_r.category_id            = mcb_out_pr_e70_r.category_id
  AND    gic_out_pr_e70_r.category_set_id        = gic_out_pr_e70_s.category_set_id
  AND    mcb_out_pr_e70_r.segment1               = xrpm.item_div_origin
--  AND    xrpm.item_div_origin                    = '5'
--  AND    xrpm.item_div_ahead                     = mcb_in_pr_e70_r.segment1
  AND    gbh_out_pr_e70.batch_id                 = gmd_out_pr_e70b.batch_id
  AND    gmd_out_pr_e70a.batch_id                = gmd_out_pr_e70b.batch_id
  AND    gmd_out_pr_e70b.line_type               = 1                   -- 完成品
--  AND    gmd_out_pr_e70b.item_id                 = gic_in_pr_e70_r.item_id
--  AND    gic_in_pr_e70_r.category_id             = mcb_in_pr_e70_r.category_id
--  AND    gic_in_pr_e70_r.category_set_id         = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
-- 2008/10/31 Y.Yamamoto v1.1 update start
  UNION ALL
  -- 生産出庫実績 解体
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_pr_e70.attribute1                     AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_pr_e70.attribute1                     AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_pr_e70.inventory_location_id          AS inventory_location_id
        ,gmd_out_pr_e70.item_id                        AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itp_out_pr_e70.trans_date                     AS arrival_date
--        ,itp_out_pr_e70.trans_date                     AS leaving_date
        ,TRUNC(itp_out_pr_e70.trans_date)              AS arrival_date
        ,TRUNC(itp_out_pr_e70.trans_date)              AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status            -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,gbh_out_pr_e70.batch_no                       AS voucher_no
        ,grt_out_pr_e70.routing_desc                   AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
        ,ABS(itp_out_pr_e70.trans_qty)                 AS leaving_quantity
  FROM   gme_batch_header             gbh_out_pr_e70                  -- 生産バッチ
        ,gme_material_details         gmd_out_pr_e70                  -- 生産原料詳細
        ,ic_tran_pnd                  itp_out_pr_e70                  -- OPM保留在庫トランザクション
        ,ic_whse_mst                  iwm_out_pr_e70                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_pr_e70                  -- OPM保管場所マスタ
        ,gmd_routings_b               grb_out_pr_e70                  -- 工順マスタ
        ,gmd_routings_tl              grt_out_pr_e70                  -- 工順マスタ日本語
        ,gmd_routing_class_b          grcb_out_pr_e70                 -- 工順区分マスタ
        ,gmd_routing_class_tl         grct_out_pr_e70                 -- 工順区分マスタ日本語
        ,(SELECT xrpm_out_pr_e70.new_div_invent
                ,flv_out_pr_e70.meaning
                ,xrpm_out_pr_e70.doc_type
                ,xrpm_out_pr_e70.routing_class
                ,xrpm_out_pr_e70.line_type
          FROM   fnd_lookup_values flv_out_pr_e70                     -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_pr_e70                    -- 受払区分アドオンマスタ
          WHERE  flv_out_pr_e70.lookup_type              = 'XXCMN_NEW_DIVISION'
          AND    flv_out_pr_e70.language                 = 'JA'
          AND    flv_out_pr_e70.lookup_code              = xrpm_out_pr_e70.new_div_invent
          AND    xrpm_out_pr_e70.doc_type                = 'PROD'
          AND    xrpm_out_pr_e70.use_div_invent          = 'Y'
         ) xrpm
  WHERE  grct_out_pr_e70.language                = 'JA'
  AND    grct_out_pr_e70.routing_class           = grcb_out_pr_e70.routing_class
  AND    grcb_out_pr_e70.routing_class           = grb_out_pr_e70.routing_class
  AND    grt_out_pr_e70.language                 = 'JA'
  AND    grb_out_pr_e70.routing_id               = grt_out_pr_e70.routing_id
  AND    itp_out_pr_e70.delete_mark              = 0                  -- 有効チェック(OPM保留在庫)
  AND    gbh_out_pr_e70.batch_id                 = gmd_out_pr_e70.batch_id
  AND    gmd_out_pr_e70.line_type                = -1                 -- 投入品
  AND    itp_out_pr_e70.doc_type                 = xrpm.doc_type
  AND    itp_out_pr_e70.doc_id                   = gmd_out_pr_e70.batch_id
  AND    itp_out_pr_e70.doc_line                 = gmd_out_pr_e70.line_no
  AND    itp_out_pr_e70.line_type                = gmd_out_pr_e70.line_type
  AND    itp_out_pr_e70.completed_ind            = 1
  AND    itp_out_pr_e70.item_id                  = gmd_out_pr_e70.item_id
  AND    itp_out_pr_e70.lot_id                   = 0
  AND    itp_out_pr_e70.whse_code                = iwm_out_pr_e70.whse_code
  AND    itp_out_pr_e70.location                 = mil_out_pr_e70.segment1
  AND    iwm_out_pr_e70.mtl_organization_id      = mil_out_pr_e70.organization_id
-- 2009/02/13 Y.Kawano Upd Start
--  AND    grb_out_pr_e70.attribute9               = mil_out_pr_e70.segment1
  AND    itp_out_pr_e70.reverse_id              IS NULL
-- 2009/02/13 Y.Kawano Upd End
  AND    grb_out_pr_e70.routing_id               = gbh_out_pr_e70.routing_id
  AND    xrpm.routing_class                      = grb_out_pr_e70.routing_class
  AND    xrpm.line_type                          = gmd_out_pr_e70.line_type
  AND    grct_out_pr_e70.routing_class_desc      IN (FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_SEPARATE')
                                                    ,FND_PROFILE.VALUE('XXINV_DUMMY_ROUTING_RET'))
  UNION ALL
  -- 受注出荷実績
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_om_e.attribute1                       AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_om_e.attribute1                       AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_om_e.inventory_location_id            AS inventory_location_id
        ,xmld_out_om_e.item_id                         AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xoha_out_om_e.arrival_date                    AS arrival_date
--        ,xoha_out_om_e.shipped_date                    AS leaving_date
        ,TRUNC(xoha_out_om_e.arrival_date)             AS arrival_date
        ,TRUNC(xoha_out_om_e.shipped_date)             AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status          -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om_e.request_no                      AS voucher_no
-- 2008/12/01 Upd Y.Kawano Start
--        ,hpat_out_om_e.attribute19                     AS ukebaraisaki_name
        ,xp_out_om_e.party_name                        AS ukebaraisaki_name
-- 2008/12/01 Upd Y.Kawano End
        ,xpas_out_om_e.party_site_name                 AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_om_e.actual_quantity                 AS leaving_quantity
  FROM   xxwsh_order_headers_all      xoha_out_om_e                    -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_out_om_e                    -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_om_e                    -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_out_om_e                     -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_om_e                     -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_out_om_e                    -- OPM品目マスタ
        ,mtl_system_items_b           msib_out_om_e                    -- 品目マスタ
        ,oe_transaction_types_all     otta_out_om_e                    -- 受注タイプ
-- 2009/01/23 Upd N.Yoshida Start
--        ,hz_parties                   hpat_out_om_e
-- 2009/01/23 Upd N.Yoshida End
        ,hz_cust_accounts             hcsa_out_om_e
        ,hz_party_sites               hpas_out_om_e
        ,xxcmn_party_sites            xpas_out_om_e
        ,gmi_item_categories          gic_out_om_e
        ,mtl_categories_b             mcb_out_om_e
        ,(SELECT xrpm_out_om_e.new_div_invent
                ,flv_out_om_e.meaning
                ,xrpm_out_om_e.shipment_provision_div
                ,xrpm_out_om_e.ship_prov_rcv_pay_category
                ,xrpm_out_om_e.stock_adjustment_div
                ,xrpm_out_om_e.item_div_ahead
          FROM   fnd_lookup_values flv_out_om_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_om_e                    -- 受払区分アドオンマスタ
          WHERE  flv_out_om_e.lookup_type                       = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om_e.language                          = 'JA'
          AND    flv_out_om_e.lookup_code                       = xrpm_out_om_e.new_div_invent
          AND    xrpm_out_om_e.doc_type                         = 'OMSO'
          AND    xrpm_out_om_e.use_div_invent                   = 'Y'
          AND    xrpm_out_om_e.stock_adjustment_div             = '1'
          AND    xrpm_out_om_e.item_div_origin                  = '5'
          AND    xrpm_out_om_e.item_div_ahead                   = '5'
         ) xrpm
-- 2008/12/01 Upd Y.Kawano Start
        ,xxcmn_parties                xp_out_om_e
-- 2008/12/01 Upd Y.Kawano End
  WHERE  otta_out_om_e.order_category_code              = 'ORDER'
  AND    xoha_out_om_e.order_header_id                  = xola_out_om_e.order_header_id
  AND    xoha_out_om_e.deliver_from_id                  = mil_out_om_e.inventory_location_id
  AND    iwm_out_om_e.mtl_organization_id               = mil_out_om_e.organization_id
  AND    xola_out_om_e.request_item_id                  = msib_out_om_e.inventory_item_id
  AND    iimb_out_om_e.item_no                          = msib_out_om_e.segment1
  AND    msib_out_om_e.organization_id                  = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om_e.mov_line_id                      = xola_out_om_e.order_line_id
  AND    xmld_out_om_e.document_type_code               = '10'      -- 出荷依頼
  AND    xmld_out_om_e.record_type_code                 = '20'      -- 出庫実績
  AND    xmld_out_om_e.lot_id                          = 0
  AND    xoha_out_om_e.req_status                       = '04'      -- 出荷実績計上済
  AND    xoha_out_om_e.latest_external_flag             = 'Y'       -- ON
  AND    xola_out_om_e.delete_flag                      = 'N'       -- OFF
  AND    otta_out_om_e.attribute1                       = '1'       -- 出荷依頼
  AND    xoha_out_om_e.order_type_id                    = otta_out_om_e.transaction_type_id
  AND    xrpm.shipment_provision_div                    = otta_out_om_e.attribute1
  AND    gic_out_om_e.item_id                           = iimb_out_om_e.item_id
  AND    gic_out_om_e.category_id                       = mcb_out_om_e.category_id
  AND    gic_out_om_e.category_set_id                   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om_e.segment1                          = '5'
  AND   (xrpm.ship_prov_rcv_pay_category                = otta_out_om_e.attribute11
      OR xrpm.ship_prov_rcv_pay_category               IS NULL)
-- 2009/01/23 Upd N.Yoshida Start
--  AND    xoha_out_om_e.customer_id                      = hpat_out_om_e.party_id
--  AND    hpat_out_om_e.party_id                         = hcsa_out_om_e.party_id
  AND    xoha_out_om_e.head_sales_branch                = hcsa_out_om_e.account_number
-- 2009/01/23 Upd N.Yoshida End
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    hpat_out_om_e.status                           = 'A'
--  AND    hcsa_out_om_e.status                           = 'A'
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xoha_out_om_e.result_deliver_to_id             = hpas_out_om_e.party_site_id
  AND    hpas_out_om_e.party_site_id                    = xpas_out_om_e.party_site_id
  AND    hpas_out_om_e.party_id                         = xpas_out_om_e.party_id
  AND    hpas_out_om_e.location_id                      = xpas_out_om_e.location_id
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    hpas_out_om_e.status                           = 'A'
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xpas_out_om_e.start_date_active               <= TRUNC(SYSDATE)
  AND    xpas_out_om_e.end_date_active                 >= TRUNC(SYSDATE)
  AND    xrpm.stock_adjustment_div                      = otta_out_om_e.attribute4
-- 2008/12/01 Upd Y.Kawano Start
-- 2009/01/23 Upd N.Yoshida Start
--  AND    hpat_out_om_e.party_id                         = xp_out_om_e.party_id
  AND    hcsa_out_om_e.party_id                         = xp_out_om_e.party_id
-- 2009/01/23 Upd N.Yoshida Start
  AND    xp_out_om_e.start_date_active                 <= TRUNC(SYSDATE)
  AND    xp_out_om_e.end_date_active                   >= TRUNC(SYSDATE)
-- 2008/12/01 Upd Y.Kawano End
  UNION ALL
  -- 有償出荷実績
  ------------------------------------------------------------------------
  -- 商品振替有償
  ------------------------------------------------------------------------
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_om2_e.attribute1                      AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_om2_e.attribute1                      AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_om2_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om2_e.item_id                        AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
-- 2008/10/23 Y.Yamamoto v1.1 update start
--        ,xoha_out_om2_e.arrival_date                   AS arrival_date
--        ,NVL(xoha_out_om2_e.arrival_date
--            ,xoha_out_om2_e.shipped_date)              AS arrival_date
-- 2008/10/23 Y.Yamamoto v1.1 update end
--        ,xoha_out_om2_e.shipped_date                   AS leaving_date
        ,NVL(TRUNC(xoha_out_om2_e.arrival_date)
            ,TRUNC(xoha_out_om2_e.shipped_date))       AS arrival_date
        ,TRUNC(xoha_out_om2_e.shipped_date)            AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status           -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2_e.request_no                     AS voucher_no
        ,xvsa_out_om2_e.vendor_site_name               AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2_e.actual_quantity                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2_e.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2_e.actual_quantity ) * -1
          ELSE
            xmld_out_om2_e.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2_e                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_out_om2_e                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_om2_e                 -- 移動ロット詳細(アドオン)
        ,oe_transaction_types_all     otta_out_om2_e                 -- 受注タイプ
        ,ic_whse_mst                  iwm_out_om2_e                     -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_om2_e                     -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_out_om2_e                    -- OPM品目マスタ
        ,mtl_system_items_b           msib_out_om2_e                    -- 品目マスタ
        ,ic_item_mst_b                iimb2_out_om2_e                -- OPM品目マスタ
        ,mtl_system_items_b           msib2_out_om2_e                -- 品目マスタ
        ,xxcmn_vendor_sites_all       xvsa_out_om2_e
        ,gmi_item_categories          gic_out_om2_e
        ,mtl_categories_b             mcb_out_om2_e
        ,gmi_item_categories          gic2_out_om2_e
        ,mtl_categories_b             mcb2_out_om2_e
        ,(SELECT xrpm_out_om2_e.new_div_invent
                ,flv_out_om2_e.meaning
                ,xrpm_out_om2_e.shipment_provision_div
                ,xrpm_out_om2_e.ship_prov_rcv_pay_category
                ,xrpm_out_om2_e.stock_adjustment_div
-- 2008/10/24 Y.Yamamoto v1.1 add start
                ,xrpm_out_om2_e.item_div_origin
                ,xrpm_out_om2_e.item_div_ahead
-- 2008/10/24 Y.Yamamoto v1.1 add end
          FROM   fnd_lookup_values flv_out_om2_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_om2_e                    -- 受払区分アドオンマスタ
          WHERE  flv_out_om2_e.lookup_type                      = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2_e.language                         = 'JA'
          AND    flv_out_om2_e.lookup_code                      = xrpm_out_om2_e.new_div_invent
          AND    xrpm_out_om2_e.doc_type                        = 'OMSO'
          AND    xrpm_out_om2_e.use_div_invent                  = 'Y'
          AND    xrpm_out_om2_e.item_div_origin                 = '5'
          AND    xrpm_out_om2_e.item_div_ahead                  = '5'
          AND    xrpm_out_om2_e.prod_div_origin                IS NOT NULL
          AND    xrpm_out_om2_e.prod_div_ahead                 IS NOT NULL
         ) xrpm
  WHERE  otta_out_om2_e.order_category_code            = 'ORDER'
  AND    xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
  AND    xoha_out_om2_e.deliver_from_id                = mil_out_om2_e.inventory_location_id
  AND    iwm_out_om2_e.mtl_organization_id             = mil_out_om2_e.organization_id
  AND    xola_out_om2_e.shipping_inventory_item_id    <> xola_out_om2_e.request_item_id
  AND    xola_out_om2_e.request_item_id                = msib_out_om2_e.inventory_item_id
  AND    iimb_out_om2_e.item_no                        = msib_out_om2_e.segment1
  AND    msib_out_om2_e.organization_id                = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2_e.shipping_inventory_item_id     = msib2_out_om2_e.inventory_item_id
  AND    iimb2_out_om2_e.item_no                       = msib2_out_om2_e.segment1
  AND    msib2_out_om2_e.organization_id               = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
  AND    xmld_out_om2_e.document_type_code             = '30'      -- 支給指示
  AND    xmld_out_om2_e.record_type_code               = '20'      -- 出庫実績
  AND    xmld_out_om2_e.lot_id                         = 0
  AND    xoha_out_om2_e.req_status                     = '08'      -- 出荷実績計上済
  AND    xoha_out_om2_e.latest_external_flag           = 'Y'       -- ON
  AND    xola_out_om2_e.delete_flag                    = 'N'       -- OFF
  AND    otta_out_om2_e.attribute1                     = '2'       -- 支給依頼
  AND    xoha_out_om2_e.order_type_id                  = otta_out_om2_e.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2_e.attribute1
  AND    gic_out_om2_e.item_id                         = iimb_out_om2_e.item_id
  AND    gic_out_om2_e.category_id                     = mcb_out_om2_e.category_id
  AND    gic_out_om2_e.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2_e.segment1                        = '5' 
  AND    gic2_out_om2_e.item_id                        = iimb2_out_om2_e.item_id
  AND    gic2_out_om2_e.category_id                    = mcb2_out_om2_e.category_id
  AND    gic2_out_om2_e.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb2_out_om2_e.segment1                       = '5'
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2_e.attribute11 
      OR xrpm.ship_prov_rcv_pay_category              IS NULL)
-- 2008/10/24 Y.Yamamoto v1.1 add start
  AND    xrpm.item_div_origin                          = mcb2_out_om2_e.segment1
  AND    xrpm.item_div_ahead                           = mcb_out_om2_e.segment1
-- 2008/10/24 Y.Yamamoto v1.1 add end
  AND    xvsa_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
  AND    xvsa_out_om2_e.start_date_active             <= TRUNC(SYSDATE)
  AND    xvsa_out_om2_e.end_date_active               >= TRUNC(SYSDATE)
  UNION ALL
  ------------------------------------------------------------------------
  -- 商品振替有償_返品
  ------------------------------------------------------------------------
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_om2_e.attribute1                      AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_om2_e.attribute1                      AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_om2_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om2_e.item_id                        AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
-- 2008/10/23 Y.Yamamoto v1.1 update start
--        ,xoha_out_om2_e.arrival_date                   AS arrival_date
--        ,NVL(xoha_out_om2_e.arrival_date
--            ,xoha_out_om2_e.shipped_date)              AS arrival_date
-- 2008/10/23 Y.Yamamoto v1.1 update end
--        ,xoha_out_om2_e.shipped_date                   AS leaving_date
        ,NVL(TRUNC(xoha_out_om2_e.arrival_date)
            ,TRUNC(xoha_out_om2_e.shipped_date))       AS arrival_date
        ,TRUNC(xoha_out_om2_e.shipped_date)            AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status           -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2_e.request_no                     AS voucher_no
        ,xvsa_out_om2_e.vendor_site_name               AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2_e.actual_quantity                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2_e.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2_e.actual_quantity ) * -1
          ELSE
            xmld_out_om2_e.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2_e                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_out_om2_e                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_om2_e                 -- 移動ロット詳細(アドオン)
        ,oe_transaction_types_all     otta_out_om2_e                 -- 受注タイプ
        ,ic_whse_mst                  iwm_out_om2_e                     -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_om2_e                     -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_out_om2_e                    -- OPM品目マスタ
        ,mtl_system_items_b           msib_out_om2_e                    -- 品目マスタ
        ,ic_item_mst_b                iimb2_out_om2_e                -- OPM品目マスタ
        ,mtl_system_items_b           msib2_out_om2_e                -- 品目マスタ
        ,xxcmn_vendor_sites_all       xvsa_out_om2_e
        ,gmi_item_categories          gic_out_om2_e
        ,mtl_categories_b             mcb_out_om2_e
        ,gmi_item_categories          gic2_out_om2_e
        ,mtl_categories_b             mcb2_out_om2_e
        ,(SELECT xrpm_out_om2_e.new_div_invent
                ,flv_out_om2_e.meaning
                ,xrpm_out_om2_e.shipment_provision_div
                ,xrpm_out_om2_e.ship_prov_rcv_pay_category
                ,xrpm_out_om2_e.stock_adjustment_div
-- 2008/10/24 Y.Yamamoto v1.1 add start
                ,xrpm_out_om2_e.item_div_origin
                ,xrpm_out_om2_e.item_div_ahead
-- 2008/10/24 Y.Yamamoto v1.1 add end
          FROM   fnd_lookup_values flv_out_om2_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_om2_e                    -- 受払区分アドオンマスタ
          WHERE  flv_out_om2_e.lookup_type                      = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2_e.language                         = 'JA'
          AND    flv_out_om2_e.lookup_code                      = xrpm_out_om2_e.new_div_invent
          AND    xrpm_out_om2_e.doc_type                        = 'PORC'
          AND    xrpm_out_om2_e.source_document_code            = 'RMA'
          AND    xrpm_out_om2_e.use_div_invent                  = 'Y'
          AND    xrpm_out_om2_e.item_div_origin                 = '5'
          AND    xrpm_out_om2_e.item_div_ahead                  = '5'
          AND    xrpm_out_om2_e.prod_div_origin                IS NOT NULL
          AND    xrpm_out_om2_e.prod_div_ahead                 IS NOT NULL
         ) xrpm
  WHERE  otta_out_om2_e.order_category_code            = 'RETURN'
  AND    xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
  AND    xoha_out_om2_e.deliver_from_id                = mil_out_om2_e.inventory_location_id
  AND    iwm_out_om2_e.mtl_organization_id             = mil_out_om2_e.organization_id
  AND    xola_out_om2_e.shipping_inventory_item_id    <> xola_out_om2_e.request_item_id
  AND    xola_out_om2_e.request_item_id                = msib_out_om2_e.inventory_item_id
  AND    iimb_out_om2_e.item_no                        = msib_out_om2_e.segment1
  AND    msib_out_om2_e.organization_id                = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2_e.shipping_inventory_item_id     = msib2_out_om2_e.inventory_item_id
  AND    iimb2_out_om2_e.item_no                       = msib2_out_om2_e.segment1
  AND    msib2_out_om2_e.organization_id               = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
  AND    xmld_out_om2_e.document_type_code             = '30'      -- 支給指示
  AND    xmld_out_om2_e.record_type_code               = '20'      -- 出庫実績
  AND    xmld_out_om2_e.lot_id                         = 0
  AND    xoha_out_om2_e.req_status                     = '08'      -- 出荷実績計上済
  AND    xoha_out_om2_e.latest_external_flag           = 'Y'       -- ON
  AND    xola_out_om2_e.delete_flag                    = 'N'       -- OFF
  AND    otta_out_om2_e.attribute1                     = '2'       -- 支給依頼
  AND    xoha_out_om2_e.order_type_id                  = otta_out_om2_e.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2_e.attribute1
  AND    gic_out_om2_e.item_id                         = iimb_out_om2_e.item_id
  AND    gic_out_om2_e.category_id                     = mcb_out_om2_e.category_id
  AND    gic_out_om2_e.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2_e.segment1                        = '5' 
  AND    gic2_out_om2_e.item_id                        = iimb2_out_om2_e.item_id
  AND    gic2_out_om2_e.category_id                    = mcb2_out_om2_e.category_id
  AND    gic2_out_om2_e.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb2_out_om2_e.segment1                       = '5'
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2_e.attribute11 
      OR xrpm.ship_prov_rcv_pay_category              IS NULL)
-- 2008/10/24 Y.Yamamoto v1.1 add start
  AND    xrpm.item_div_origin                          = mcb2_out_om2_e.segment1
  AND    xrpm.item_div_ahead                           = mcb_out_om2_e.segment1
-- 2008/10/24 Y.Yamamoto v1.1 add end
  AND    xvsa_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
  AND    xvsa_out_om2_e.start_date_active             <= TRUNC(SYSDATE)
  AND    xvsa_out_om2_e.end_date_active               >= TRUNC(SYSDATE)
  UNION ALL
  ------------------------------------------------------------------------
  -- 振替有償
  ------------------------------------------------------------------------
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_om2_e.attribute1                      AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_om2_e.attribute1                      AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_om2_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om2_e.item_id                        AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
-- 2008/10/23 Y.Yamamoto v1.1 update start
--        ,xoha_out_om2_e.arrival_date                   AS arrival_date
--        ,NVL(xoha_out_om2_e.arrival_date
--            ,xoha_out_om2_e.shipped_date)              AS arrival_date
-- 2008/10/23 Y.Yamamoto v1.1 update end
--        ,xoha_out_om2_e.shipped_date                   AS leaving_date
        ,NVL(TRUNC(xoha_out_om2_e.arrival_date)
            ,TRUNC(xoha_out_om2_e.shipped_date))       AS arrival_date
        ,TRUNC(xoha_out_om2_e.shipped_date)            AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status           -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2_e.request_no                     AS voucher_no
        ,xvsa_out_om2_e.vendor_site_name               AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2_e.actual_quantity                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2_e.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2_e.actual_quantity ) * -1
          ELSE
            xmld_out_om2_e.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2_e                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_out_om2_e                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_om2_e                 -- 移動ロット詳細(アドオン)
        ,oe_transaction_types_all     otta_out_om2_e                 -- 受注タイプ
        ,ic_whse_mst                  iwm_out_om2_e                     -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_om2_e                     -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_out_om2_e                    -- OPM品目マスタ
        ,mtl_system_items_b           msib_out_om2_e                    -- 品目マスタ
        ,ic_item_mst_b                iimb2_out_om2_e                -- OPM品目マスタ
        ,mtl_system_items_b           msib2_out_om2_e                -- 品目マスタ
        ,xxcmn_vendor_sites_all       xvsa_out_om2_e
        ,gmi_item_categories          gic_out_om2_e
        ,mtl_categories_b             mcb_out_om2_e
        ,gmi_item_categories          gic2_out_om2_e
        ,mtl_categories_b             mcb2_out_om2_e
        ,(SELECT xrpm_out_om2_e.new_div_invent
                ,flv_out_om2_e.meaning
                ,xrpm_out_om2_e.shipment_provision_div
                ,xrpm_out_om2_e.ship_prov_rcv_pay_category
                ,xrpm_out_om2_e.stock_adjustment_div
-- 2008/10/24 Y.Yamamoto v1.1 update start
--                ,nvl(xrpm_out_om2_e.item_div_origin,'Dummy')         AS item_div_origin
--                ,nvl(xrpm_out_om2_e.item_div_ahead,'Dummy')          AS item_div_ahead
                ,xrpm_out_om2_e.item_div_origin
                ,DECODE(xrpm_out_om2_e.item_div_ahead,'5','5','Dummy') AS item_div_ahead
-- 2008/10/24 Y.Yamamoto v1.1 update end
          FROM   fnd_lookup_values flv_out_om2_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_om2_e                    -- 受払区分アドオンマスタ
          WHERE  flv_out_om2_e.lookup_type                      = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2_e.language                         = 'JA'
          AND    flv_out_om2_e.lookup_code                      = xrpm_out_om2_e.new_div_invent
          AND    xrpm_out_om2_e.doc_type                        = 'OMSO'
          AND    xrpm_out_om2_e.use_div_invent                  = 'Y'
-- 2009/04/01 本番#1364 UPDATE START
--          AND    xrpm_out_om2_e.item_div_origin                 = '5'
          AND    xrpm_out_om2_e.shipment_provision_div          = '2'       -- 支給依頼
          AND    xrpm_out_om2_e.item_div_origin                <> '5'
          AND    xrpm_out_om2_e.item_div_ahead                  = '5'
-- 2009/04/01 本番#1364 UPDATE END
          AND    xrpm_out_om2_e.prod_div_origin                IS NULL
          AND    xrpm_out_om2_e.prod_div_ahead                 IS NULL
         ) xrpm
  WHERE  otta_out_om2_e.order_category_code            = 'ORDER'
  AND    xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
  AND    xoha_out_om2_e.deliver_from_id                = mil_out_om2_e.inventory_location_id
  AND    iwm_out_om2_e.mtl_organization_id             = mil_out_om2_e.organization_id
  AND    xola_out_om2_e.shipping_inventory_item_id    <> xola_out_om2_e.request_item_id
  AND    xola_out_om2_e.request_item_id                = msib_out_om2_e.inventory_item_id
  AND    iimb_out_om2_e.item_no                        = msib_out_om2_e.segment1
  AND    msib_out_om2_e.organization_id                = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2_e.shipping_inventory_item_id     = msib2_out_om2_e.inventory_item_id
  AND    iimb2_out_om2_e.item_no                       = msib2_out_om2_e.segment1
  AND    msib2_out_om2_e.organization_id               = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
  AND    xmld_out_om2_e.document_type_code             = '30'      -- 支給指示
  AND    xmld_out_om2_e.record_type_code               = '20'      -- 出庫実績
  AND    xmld_out_om2_e.lot_id                         = 0
  AND    xoha_out_om2_e.req_status                     = '08'      -- 出荷実績計上済
  AND    xoha_out_om2_e.latest_external_flag           = 'Y'       -- ON
  AND    xola_out_om2_e.delete_flag                    = 'N'       -- OFF
  AND    otta_out_om2_e.attribute1                     = '2'       -- 支給依頼
  AND    xoha_out_om2_e.order_type_id                  = otta_out_om2_e.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2_e.attribute1
  AND    gic_out_om2_e.item_id                         = iimb_out_om2_e.item_id
  AND    gic_out_om2_e.category_id                     = mcb_out_om2_e.category_id
  AND    gic_out_om2_e.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2_e.segment1                        = '5' 
  AND    gic2_out_om2_e.item_id                        = iimb2_out_om2_e.item_id
  AND    gic2_out_om2_e.category_id                    = mcb2_out_om2_e.category_id
  AND    gic2_out_om2_e.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
-- 2009/04/01 本番#1364 ADD START
  AND    mcb_out_om2_e.segment1                       IN ('1','2','4')
-- 2009/04/01 本番#1364 ADD END
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2_e.attribute11 
      OR xrpm.ship_prov_rcv_pay_category              IS NULL)
  AND    xrpm.item_div_origin                          = DECODE(mcb2_out_om2_e.segment1,'5','5','Dummy')
-- 2008/10/24 Y.Yamamoto v1.1 update start
--  AND    xrpm.item_div_ahead                           = DECODE(mcb_out_om2_e.segment1,'5','5','Dummy')
  AND    xrpm.item_div_ahead                           = mcb_out_om2_e.segment1
-- 2008/10/24 Y.Yamamoto v1.1 update end
  AND    xvsa_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
  AND    xvsa_out_om2_e.start_date_active             <= TRUNC(SYSDATE)
  AND    xvsa_out_om2_e.end_date_active               >= TRUNC(SYSDATE)
  UNION ALL
  ------------------------------------------------------------------------
  -- 振替有償_返品
  ------------------------------------------------------------------------
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_om2_e.attribute1                      AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_om2_e.attribute1                      AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_om2_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om2_e.item_id                        AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
-- 2008/10/23 Y.Yamamoto v1.1 update start
--        ,xoha_out_om2_e.arrival_date                   AS arrival_date
--        ,NVL(xoha_out_om2_e.arrival_date
--            ,xoha_out_om2_e.shipped_date)              AS arrival_date
-- 2008/10/23 Y.Yamamoto v1.1 update end
--        ,xoha_out_om2_e.shipped_date                   AS leaving_date
        ,NVL(TRUNC(xoha_out_om2_e.arrival_date)
            ,TRUNC(xoha_out_om2_e.shipped_date))       AS arrival_date
        ,TRUNC(xoha_out_om2_e.shipped_date)            AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status           -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2_e.request_no                     AS voucher_no
        ,xvsa_out_om2_e.vendor_site_name               AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2_e.actual_quantity                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2_e.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2_e.actual_quantity ) * -1
          ELSE
            xmld_out_om2_e.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2_e                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_out_om2_e                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_om2_e                 -- 移動ロット詳細(アドオン)
        ,oe_transaction_types_all     otta_out_om2_e                 -- 受注タイプ
        ,ic_whse_mst                  iwm_out_om2_e                     -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_om2_e                     -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_out_om2_e                    -- OPM品目マスタ
        ,mtl_system_items_b           msib_out_om2_e                    -- 品目マスタ
        ,ic_item_mst_b                iimb2_out_om2_e                -- OPM品目マスタ
        ,mtl_system_items_b           msib2_out_om2_e                -- 品目マスタ
        ,xxcmn_vendor_sites_all       xvsa_out_om2_e
        ,gmi_item_categories          gic_out_om2_e
        ,mtl_categories_b             mcb_out_om2_e
        ,gmi_item_categories          gic2_out_om2_e
        ,mtl_categories_b             mcb2_out_om2_e
        ,(SELECT xrpm_out_om2_e.new_div_invent
                ,flv_out_om2_e.meaning
                ,xrpm_out_om2_e.shipment_provision_div
                ,xrpm_out_om2_e.ship_prov_rcv_pay_category
                ,xrpm_out_om2_e.stock_adjustment_div
-- 2008/10/24 Y.Yamamoto v1.1 update start
--                ,nvl(xrpm_out_om2_e.item_div_origin,'Dummy')         AS item_div_origin
--                ,nvl(xrpm_out_om2_e.item_div_ahead,'Dummy')          AS item_div_ahead
                ,xrpm_out_om2_e.item_div_origin
                ,DECODE(xrpm_out_om2_e.item_div_ahead,'5','5','Dummy') AS item_div_ahead
-- 2008/10/24 Y.Yamamoto v1.1 update end
          FROM   fnd_lookup_values flv_out_om2_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_om2_e                    -- 受払区分アドオンマスタ
          WHERE  flv_out_om2_e.lookup_type                      = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2_e.language                         = 'JA'
          AND    flv_out_om2_e.lookup_code                      = xrpm_out_om2_e.new_div_invent
          AND    xrpm_out_om2_e.doc_type                        = 'PORC'
          AND    xrpm_out_om2_e.source_document_code            = 'RMA'
          AND    xrpm_out_om2_e.use_div_invent                  = 'Y'
-- 2009/04/01 本番#1364 UPDATE START
--          AND    xrpm_out_om2_e.item_div_origin                 = '5'
          AND    xrpm_out_om2_e.shipment_provision_div          = '2'       -- 支給依頼
          AND    xrpm_out_om2_e.item_div_origin                <> '5'
          AND    xrpm_out_om2_e.item_div_ahead                  = '5'
-- 2009/04/01 本番#1364 UPDATE END
          AND    xrpm_out_om2_e.prod_div_origin                IS NULL
          AND    xrpm_out_om2_e.prod_div_ahead                 IS NULL
         ) xrpm
  WHERE  otta_out_om2_e.order_category_code            = 'RETURN'
  AND    xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
  AND    xoha_out_om2_e.deliver_from_id                = mil_out_om2_e.inventory_location_id
  AND    iwm_out_om2_e.mtl_organization_id             = mil_out_om2_e.organization_id
  AND    xola_out_om2_e.shipping_inventory_item_id    <> xola_out_om2_e.request_item_id
  AND    xola_out_om2_e.request_item_id                = msib_out_om2_e.inventory_item_id
  AND    iimb_out_om2_e.item_no                        = msib_out_om2_e.segment1
  AND    msib_out_om2_e.organization_id                = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2_e.shipping_inventory_item_id     = msib2_out_om2_e.inventory_item_id
  AND    iimb2_out_om2_e.item_no                       = msib2_out_om2_e.segment1
  AND    msib2_out_om2_e.organization_id               = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
  AND    xmld_out_om2_e.document_type_code             = '30'      -- 支給指示
  AND    xmld_out_om2_e.record_type_code               = '20'      -- 出庫実績
  AND    xmld_out_om2_e.lot_id                         = 0
  AND    xoha_out_om2_e.req_status                     = '08'      -- 出荷実績計上済
  AND    xoha_out_om2_e.latest_external_flag           = 'Y'       -- ON
  AND    xola_out_om2_e.delete_flag                    = 'N'       -- OFF
  AND    otta_out_om2_e.attribute1                     = '2'       -- 支給依頼
  AND    xoha_out_om2_e.order_type_id                  = otta_out_om2_e.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2_e.attribute1
  AND    gic_out_om2_e.item_id                         = iimb_out_om2_e.item_id
  AND    gic_out_om2_e.category_id                     = mcb_out_om2_e.category_id
  AND    gic_out_om2_e.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2_e.segment1                        = '5' 
  AND    gic2_out_om2_e.item_id                        = iimb2_out_om2_e.item_id
  AND    gic2_out_om2_e.category_id                    = mcb2_out_om2_e.category_id
  AND    gic2_out_om2_e.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
-- 2009/04/01 本番#1364 ADD START
  AND    mcb_out_om2_e.segment1                       IN ('1','2','4')
-- 2009/04/01 本番#1364 ADD END
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2_e.attribute11 
      OR xrpm.ship_prov_rcv_pay_category              IS NULL)
  AND    xrpm.item_div_origin                          = DECODE(mcb2_out_om2_e.segment1,'5','5','Dummy')
-- 2008/10/24 Y.Yamamoto v1.1 update start
--  AND    xrpm.item_div_ahead                           = DECODE(mcb_out_om2_e.segment1,'5','5','Dummy')
  AND    xrpm.item_div_ahead                           = mcb_out_om2_e.segment1
-- 2008/10/24 Y.Yamamoto v1.1 update end
  AND    xvsa_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
  AND    xvsa_out_om2_e.start_date_active             <= TRUNC(SYSDATE)
  AND    xvsa_out_om2_e.end_date_active               >= TRUNC(SYSDATE)
-- 2008/10/24 Y.Yamamoto v1.1 add start
  UNION ALL
  ------------------------------------------------------------------------
  -- 有償
  ------------------------------------------------------------------------
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_om2_e.attribute1                      AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_om2_e.attribute1                      AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_om2_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om2_e.item_id                        AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,NVL(xoha_out_om2_e.arrival_date
--            ,xoha_out_om2_e.shipped_date)              AS arrival_date
--        ,xoha_out_om2_e.shipped_date                   AS leaving_date
        ,NVL(TRUNC(xoha_out_om2_e.arrival_date)
            ,TRUNC(xoha_out_om2_e.shipped_date))       AS arrival_date
        ,TRUNC(xoha_out_om2_e.shipped_date)            AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status           -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2_e.request_no                     AS voucher_no
        ,xvsa_out_om2_e.vendor_site_name               AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2_e.actual_quantity                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2_e.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2_e.actual_quantity ) * -1
          ELSE
            xmld_out_om2_e.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2_e                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_out_om2_e                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_om2_e                 -- 移動ロット詳細(アドオン)
        ,oe_transaction_types_all     otta_out_om2_e                 -- 受注タイプ
        ,ic_whse_mst                  iwm_out_om2_e                     -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_om2_e                     -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_out_om2_e                    -- OPM品目マスタ
        ,mtl_system_items_b           msib_out_om2_e                    -- 品目マスタ
        ,ic_item_mst_b                iimb2_out_om2_e                -- OPM品目マスタ
        ,mtl_system_items_b           msib2_out_om2_e                -- 品目マスタ
        ,xxcmn_vendor_sites_all       xvsa_out_om2_e
        ,gmi_item_categories          gic_out_om2_e
        ,mtl_categories_b             mcb_out_om2_e
        ,gmi_item_categories          gic2_out_om2_e
        ,mtl_categories_b             mcb2_out_om2_e
        ,(SELECT xrpm_out_om2_e.new_div_invent
                ,flv_out_om2_e.meaning
                ,xrpm_out_om2_e.shipment_provision_div
                ,xrpm_out_om2_e.ship_prov_rcv_pay_category
                ,xrpm_out_om2_e.stock_adjustment_div
                ,xrpm_out_om2_e.item_div_origin
                ,DECODE(xrpm_out_om2_e.item_div_ahead,'5','5','Dummy') AS item_div_ahead
          FROM   fnd_lookup_values flv_out_om2_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_om2_e                    -- 受払区分アドオンマスタ
          WHERE  flv_out_om2_e.lookup_type                      = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2_e.language                         = 'JA'
          AND    flv_out_om2_e.lookup_code                      = xrpm_out_om2_e.new_div_invent
          AND    xrpm_out_om2_e.doc_type                        = 'OMSO'
          AND    xrpm_out_om2_e.use_div_invent                  = 'Y'
          AND    xrpm_out_om2_e.item_div_origin                 = '5'
          AND    xrpm_out_om2_e.prod_div_origin                IS NULL
          AND    xrpm_out_om2_e.prod_div_ahead                 IS NULL
         ) xrpm
  WHERE  otta_out_om2_e.order_category_code            = 'ORDER'
  AND    xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
  AND    xoha_out_om2_e.deliver_from_id                = mil_out_om2_e.inventory_location_id
  AND    iwm_out_om2_e.mtl_organization_id             = mil_out_om2_e.organization_id
  AND    xola_out_om2_e.shipping_inventory_item_id     = xola_out_om2_e.request_item_id
  AND    xola_out_om2_e.request_item_id                = msib_out_om2_e.inventory_item_id
  AND    iimb_out_om2_e.item_no                        = msib_out_om2_e.segment1
  AND    msib_out_om2_e.organization_id                = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2_e.shipping_inventory_item_id     = msib2_out_om2_e.inventory_item_id
  AND    iimb2_out_om2_e.item_no                       = msib2_out_om2_e.segment1
  AND    msib2_out_om2_e.organization_id               = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
  AND    xmld_out_om2_e.document_type_code             = '30'      -- 支給指示
  AND    xmld_out_om2_e.record_type_code               = '20'      -- 出庫実績
  AND    xmld_out_om2_e.lot_id                         = 0
  AND    xoha_out_om2_e.req_status                     = '08'      -- 出荷実績計上済
  AND    xoha_out_om2_e.latest_external_flag           = 'Y'       -- ON
  AND    xola_out_om2_e.delete_flag                    = 'N'       -- OFF
  AND    otta_out_om2_e.attribute1                     = '2'       -- 支給依頼
  AND    xoha_out_om2_e.order_type_id                  = otta_out_om2_e.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2_e.attribute1
  AND    gic_out_om2_e.item_id                         = iimb_out_om2_e.item_id
  AND    gic_out_om2_e.category_id                     = mcb_out_om2_e.category_id
  AND    gic_out_om2_e.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2_e.segment1                        = '5' 
  AND    gic2_out_om2_e.item_id                        = iimb2_out_om2_e.item_id
  AND    gic2_out_om2_e.category_id                    = mcb2_out_om2_e.category_id
  AND    gic2_out_om2_e.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2_e.attribute11 
      OR xrpm.ship_prov_rcv_pay_category              IS NULL)
  AND    xrpm.item_div_origin                          = DECODE(mcb2_out_om2_e.segment1,'5','5','Dummy')
  AND    xrpm.item_div_ahead                           = mcb_out_om2_e.segment1
  AND    xvsa_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
  AND    xvsa_out_om2_e.start_date_active             <= TRUNC(SYSDATE)
  AND    xvsa_out_om2_e.end_date_active               >= TRUNC(SYSDATE)
  UNION ALL
  ------------------------------------------------------------------------
  -- 有償_返品
  ------------------------------------------------------------------------
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_om2_e.attribute1                      AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_om2_e.attribute1                      AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_om2_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om2_e.item_id                        AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,NVL(xoha_out_om2_e.arrival_date
--            ,xoha_out_om2_e.shipped_date)              AS arrival_date
--        ,xoha_out_om2_e.shipped_date                   AS leaving_date
        ,NVL(TRUNC(xoha_out_om2_e.arrival_date)
            ,TRUNC(xoha_out_om2_e.shipped_date))       AS arrival_date
        ,TRUNC(xoha_out_om2_e.shipped_date)            AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status           -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om2_e.request_no                     AS voucher_no
        ,xvsa_out_om2_e.vendor_site_name               AS ukebaraisaki_name
        ,NULL                                          AS vendor_site_name
        ,0                                             AS stock_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update start
--        ,xmld_out_om2_e.actual_quantity                AS leaving_quantity
        ,CASE
          WHEN (xrpm.new_div_invent = '104'
            AND otta_out_om2_e.order_category_code = 'RETURN' ) THEN
            ABS( xmld_out_om2_e.actual_quantity ) * -1
          ELSE
            xmld_out_om2_e.actual_quantity
          END                                             leaving_quantity
-- 2008/10/24 Y.Yamamoto v1.1 update end
  FROM   xxwsh_order_headers_all      xoha_out_om2_e                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_out_om2_e                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_om2_e                 -- 移動ロット詳細(アドオン)
        ,oe_transaction_types_all     otta_out_om2_e                 -- 受注タイプ
        ,ic_whse_mst                  iwm_out_om2_e                     -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_om2_e                     -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_out_om2_e                    -- OPM品目マスタ
        ,mtl_system_items_b           msib_out_om2_e                    -- 品目マスタ
        ,ic_item_mst_b                iimb2_out_om2_e                -- OPM品目マスタ
        ,mtl_system_items_b           msib2_out_om2_e                -- 品目マスタ
        ,xxcmn_vendor_sites_all       xvsa_out_om2_e
        ,gmi_item_categories          gic_out_om2_e
        ,mtl_categories_b             mcb_out_om2_e
        ,gmi_item_categories          gic2_out_om2_e
        ,mtl_categories_b             mcb2_out_om2_e
        ,(SELECT xrpm_out_om2_e.new_div_invent
                ,flv_out_om2_e.meaning
                ,xrpm_out_om2_e.shipment_provision_div
                ,xrpm_out_om2_e.ship_prov_rcv_pay_category
                ,xrpm_out_om2_e.stock_adjustment_div
                ,xrpm_out_om2_e.item_div_origin
                ,DECODE(xrpm_out_om2_e.item_div_ahead,'5','5','Dummy') AS item_div_ahead
          FROM   fnd_lookup_values flv_out_om2_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_om2_e                    -- 受払区分アドオンマスタ
          WHERE  flv_out_om2_e.lookup_type                      = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om2_e.language                         = 'JA'
          AND    flv_out_om2_e.lookup_code                      = xrpm_out_om2_e.new_div_invent
          AND    xrpm_out_om2_e.doc_type                        = 'PORC'
          AND    xrpm_out_om2_e.source_document_code            = 'RMA'
          AND    xrpm_out_om2_e.use_div_invent                  = 'Y'
          AND    xrpm_out_om2_e.item_div_origin                 = '5'
          AND    xrpm_out_om2_e.prod_div_origin                IS NULL
          AND    xrpm_out_om2_e.prod_div_ahead                 IS NULL
         ) xrpm
  WHERE  otta_out_om2_e.order_category_code            = 'RETURN'
  AND    xoha_out_om2_e.order_header_id                = xola_out_om2_e.order_header_id
  AND    xoha_out_om2_e.deliver_from_id                = mil_out_om2_e.inventory_location_id
  AND    iwm_out_om2_e.mtl_organization_id             = mil_out_om2_e.organization_id
  AND    xola_out_om2_e.shipping_inventory_item_id     = xola_out_om2_e.request_item_id
  AND    xola_out_om2_e.request_item_id                = msib_out_om2_e.inventory_item_id
  AND    iimb_out_om2_e.item_no                        = msib_out_om2_e.segment1
  AND    msib_out_om2_e.organization_id                = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xola_out_om2_e.shipping_inventory_item_id     = msib2_out_om2_e.inventory_item_id
  AND    iimb2_out_om2_e.item_no                       = msib2_out_om2_e.segment1
  AND    msib2_out_om2_e.organization_id               = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om2_e.mov_line_id                    = xola_out_om2_e.order_line_id
  AND    xmld_out_om2_e.document_type_code             = '30'      -- 支給指示
  AND    xmld_out_om2_e.record_type_code               = '20'      -- 出庫実績
  AND    xmld_out_om2_e.lot_id                         = 0
  AND    xoha_out_om2_e.req_status                     = '08'      -- 出荷実績計上済
  AND    xoha_out_om2_e.latest_external_flag           = 'Y'       -- ON
  AND    xola_out_om2_e.delete_flag                    = 'N'       -- OFF
  AND    otta_out_om2_e.attribute1                     = '2'       -- 支給依頼
  AND    xoha_out_om2_e.order_type_id                  = otta_out_om2_e.transaction_type_id
  AND    xrpm.shipment_provision_div                   = otta_out_om2_e.attribute1
  AND    gic_out_om2_e.item_id                         = iimb_out_om2_e.item_id
  AND    gic_out_om2_e.category_id                     = mcb_out_om2_e.category_id
  AND    gic_out_om2_e.category_set_id                 = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_out_om2_e.segment1                        = '5' 
  AND    gic2_out_om2_e.item_id                        = iimb2_out_om2_e.item_id
  AND    gic2_out_om2_e.category_id                    = mcb2_out_om2_e.category_id
  AND    gic2_out_om2_e.category_set_id                = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND   (xrpm.ship_prov_rcv_pay_category               = otta_out_om2_e.attribute11 
      OR xrpm.ship_prov_rcv_pay_category              IS NULL)
  AND    xrpm.item_div_origin                          = DECODE(mcb2_out_om2_e.segment1,'5','5','Dummy')
  AND    xrpm.item_div_ahead                           = mcb_out_om2_e.segment1
  AND    xvsa_out_om2_e.vendor_site_id                 = xoha_out_om2_e.vendor_site_id
  AND    xvsa_out_om2_e.start_date_active             <= TRUNC(SYSDATE)
  AND    xvsa_out_om2_e.end_date_active               >= TRUNC(SYSDATE)
-- 2008/10/24 Y.Yamamoto v1.1 add end
  UNION ALL
  -- 在庫調整 出庫実績(出荷 見本出庫 廃却出庫)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_om3_e.attribute1                      AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_om3_e.attribute1                      AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_om3_e.inventory_location_id           AS inventory_location_id
        ,xmld_out_om3_e.item_id                        AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,xoha_out_om3_e.shipped_date                   AS arrival_date
--        ,xoha_out_om3_e.shipped_date                   AS leaving_date
        ,TRUNC(xoha_out_om3_e.shipped_date)            AS arrival_date
        ,TRUNC(xoha_out_om3_e.shipped_date)            AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status          -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xoha_out_om3_e.request_no                     AS voucher_no
-- 2008/12/01 Upd Y.Kawano Start
--        ,hpat_out_om3_e.attribute19                    AS ukebaraisaki_name
        ,xp_out_om3_e.party_name                          AS ukebaraisaki_name
-- 2008/12/01 Upd Y.Kawano End
        ,xpas_out_om3_e.party_site_name                AS deliver_to_name
        ,0                                             AS stock_quantity
        ,xmld_out_om3_e.actual_quantity                AS leaving_quantity
  FROM   xxwsh_order_headers_all      xoha_out_om3_e                 -- 受注ヘッダ(アドオン)
        ,xxwsh_order_lines_all        xola_out_om3_e                 -- 受注明細(アドオン)
        ,xxinv_mov_lot_details        xmld_out_om3_e                 -- 移動ロット詳細(アドオン)
        ,ic_whse_mst                  iwm_out_om3_e                     -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_om3_e                     -- OPM保管場所マスタ
        ,ic_item_mst_b                iimb_out_om3_e                    -- OPM品目マスタ
        ,mtl_system_items_b           msib_out_om3_e                    -- 品目マスタ
        ,oe_transaction_types_all     otta_out_om3_e                 -- 受注タイプ
-- 2009/01/23 Upd N.Yoshida Start
--        ,hz_parties                   hpat_out_om3_e
-- 2009/01/23 Upd N.Yoshida End
        ,hz_cust_accounts             hcsa_out_om3_e
        ,hz_party_sites               hpas_out_om3_e
        ,xxcmn_party_sites            xpas_out_om3_e
        ,(SELECT xrpm_out_om3_e.new_div_invent
                ,flv_out_om3_e.meaning
                ,xrpm_out_om3_e.stock_adjustment_div
                ,xrpm_out_om3_e.ship_prov_rcv_pay_category
          FROM   fnd_lookup_values flv_out_om3_e                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_om3_e                    -- 受払区分アドオンマスタ
          WHERE  flv_out_om3_e.lookup_type                       = 'XXCMN_NEW_DIVISION'
          AND    flv_out_om3_e.language                          = 'JA'
          AND    flv_out_om3_e.lookup_code                       = xrpm_out_om3_e.new_div_invent
          AND    xrpm_out_om3_e.doc_type                         = 'OMSO'
          AND    xrpm_out_om3_e.use_div_invent                   = 'Y'
         ) xrpm
-- 2008/12/01 Upd Y.Kawano Start
        ,xxcmn_parties                xp_out_om3_e
-- 2008/12/01 Upd Y.Kawano End
  WHERE  otta_out_om3_e.order_category_code              = 'ORDER'
  AND    xoha_out_om3_e.order_header_id                  = xola_out_om3_e.order_header_id
  AND    xoha_out_om3_e.deliver_from_id                  = mil_out_om3_e.inventory_location_id
  AND    iwm_out_om3_e.mtl_organization_id               = mil_out_om3_e.organization_id
  AND    xola_out_om3_e.shipping_inventory_item_id       = msib_out_om3_e.inventory_item_id
  AND    iimb_out_om3_e.item_no                          = msib_out_om3_e.segment1
  AND    msib_out_om3_e.organization_id                  = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
  AND    xmld_out_om3_e.mov_line_id                      = xola_out_om3_e.order_line_id
  AND    xmld_out_om3_e.document_type_code               = '10'      -- 出荷依頼
  AND    xmld_out_om3_e.record_type_code                 = '20'      -- 出庫実績
  AND    xmld_out_om3_e.lot_id                           = 0
  AND    xoha_out_om3_e.req_status                       = '04'      -- 出荷実績計上済
  AND    xoha_out_om3_e.latest_external_flag             = 'Y'       -- ON
  AND    xola_out_om3_e.delete_flag                      = 'N'       -- OFF
  AND    otta_out_om3_e.attribute1                       = '1'       -- 出荷依頼
  AND    xoha_out_om3_e.order_type_id                    = otta_out_om3_e.transaction_type_id
  AND    xrpm.stock_adjustment_div                       = otta_out_om3_e.attribute4
  AND    xrpm.stock_adjustment_div                       = '2'
  AND    xrpm.ship_prov_rcv_pay_category                 = otta_out_om3_e.attribute11
  AND    xrpm.ship_prov_rcv_pay_category                IN ( '01' , '02' )
-- 2009/01/23 Upd N.Yoshida Start
--  AND    xoha_out_om3_e.customer_id                      = hpat_out_om3_e.party_id
--  AND    hpat_out_om3_e.party_id                         = hcsa_out_om3_e.party_id
  AND    xoha_out_om3_e.head_sales_branch                = hcsa_out_om3_e.account_number
-- 2009/01/23 Upd N.Yoshida End
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    hpat_out_om3_e.status                           = 'A'
--  AND    hcsa_out_om3_e.status                           = 'A'
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xoha_out_om3_e.result_deliver_to_id             = hpas_out_om3_e.party_site_id
  AND    hpas_out_om3_e.party_site_id                    = xpas_out_om3_e.party_site_id
  AND    hpas_out_om3_e.party_id                         = xpas_out_om3_e.party_id
  AND    hpas_out_om3_e.location_id                      = xpas_out_om3_e.location_id
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    hpas_out_om3_e.status                           = 'A'
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xpas_out_om3_e.start_date_active               <= TRUNC(SYSDATE)
  AND    xpas_out_om3_e.end_date_active                 >= TRUNC(SYSDATE)
-- 2008/12/01 Upd Y.Kawano Start
-- 2009/01/23 Upd N.Yoshida Start
--  AND    hpat_out_om3_e.party_id                         = xp_out_om3_e.party_id
  AND    hcsa_out_om3_e.party_id                         = xp_out_om3_e.party_id
-- 2009/01/23 Upd N.Yoshida End
  AND    xp_out_om3_e.start_date_active                 <= TRUNC(SYSDATE)
  AND    xp_out_om3_e.end_date_active                   >= TRUNC(SYSDATE)
-- 2008/12/01 Upd Y.Kawano End
  UNION ALL
  -- 在庫調整 出庫実績(相手先在庫)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_ad_e_x97.attribute1                   AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_ad_e_x97.attribute1                   AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_ad_e_x97.inventory_location_id        AS inventory_location_id
        ,itc_out_ad_e_x97.item_id                      AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itc_out_ad_e_x97.trans_date                   AS arrival_date
--        ,itc_out_ad_e_x97.trans_date                   AS leaving_date
        ,TRUNC(itc_out_ad_e_x97.trans_date)            AS arrival_date
        ,TRUNC(itc_out_ad_e_x97.trans_date)            AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status        -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,ijm_out_ad_e_x97.journal_no                   AS voucher_no
        ,xrpm.meaning                                  AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update start
--        ,ABS(itc_out_ad_e_x97.trans_qty)               AS leaving_quantity
        ,itc_out_ad_e_x97.trans_qty                    AS leaving_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update end
  FROM   ic_tran_cmp                  itc_out_ad_e_x97                  -- OPM完了在庫トランザクション
        ,ic_jrnl_mst                  ijm_out_ad_e_x97                  -- OPMジャーナルマスタ
        ,ic_adjs_jnl                  iaj_out_ad_e_x97                  -- OPM在庫調整ジャーナル
        ,ic_whse_mst                  iwm_out_ad_e_x97                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_ad_e_x97                  -- OPM保管場所マスタ
        ,(SELECT xrpm_out_ad_e_x97.new_div_invent
                ,flv_out_ad_e_x97.meaning
                ,xrpm_out_ad_e_x97.reason_code
                ,xrpm_out_ad_e_x97.rcv_pay_div
          FROM   fnd_lookup_values flv_out_ad_e_x97                     -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_ad_e_x97                    -- 受払区分アドオンマスタ
          WHERE  flv_out_ad_e_x97.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_out_ad_e_x97.language                = 'JA'
          AND    flv_out_ad_e_x97.lookup_code             = xrpm_out_ad_e_x97.new_div_invent
          AND    xrpm_out_ad_e_x97.doc_type               = 'ADJI'
          AND    xrpm_out_ad_e_x97.use_div_invent         = 'Y'
          AND    xrpm_out_ad_e_x97.reason_code            = 'X977'               -- 相手先在庫
          AND    xrpm_out_ad_e_x97.rcv_pay_div            = '-1'                 -- 払出
         ) xrpm
  WHERE  itc_out_ad_e_x97.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_out_ad_e_x97.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_out_ad_e_x97.lot_id                  = 0
  AND    iwm_out_ad_e_x97.mtl_organization_id     = mil_out_ad_e_x97.organization_id
  AND    itc_out_ad_e_x97.whse_code               = iwm_out_ad_e_x97.whse_code
  AND    itc_out_ad_e_x97.location                = mil_out_ad_e_x97.segment1
  AND    ijm_out_ad_e_x97.journal_id              = iaj_out_ad_e_x97.journal_id   -- OPMジャーナルマスタ抽出条件
  AND    iaj_out_ad_e_x97.doc_id                  = itc_out_ad_e_x97.doc_id       -- OPM在庫調整ジャーナル抽出条件
  AND    iaj_out_ad_e_x97.doc_line                = itc_out_ad_e_x97.doc_line     -- OPM在庫調整ジャーナル抽出条件
  AND    ijm_out_ad_e_x97.attribute1             IS NULL                          -- OPMジャーナルマスタ.実績IDがNULL
-- 2008/12/24 #809 Y.Yamamoto add start
  AND    ijm_out_ad_e_x97.attribute4             IS NULL
-- 2008/12/24 #809 Y.Yamamoto add end
  UNION ALL
  -- 相手先在庫出庫実績
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_ad_e_x97.attribute1                   AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_ad_e_x97.attribute1                   AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_ad_e_x97.inventory_location_id        AS inventory_location_id
        ,itc_out_ad_e_x97.item_id                      AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itc_out_ad_e_x97.trans_date                   AS arrival_date
--        ,itc_out_ad_e_x97.trans_date                   AS leaving_date
        ,TRUNC(itc_out_ad_e_x97.trans_date)            AS arrival_date
        ,TRUNC(itc_out_ad_e_x97.trans_date)            AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status        -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xrart_out_ad_e_x97.source_document_number     AS voucher_no        -- 伝票No
        ,xv_out_ad_e_x97.vendor_name                   AS ukebaraisaki_name -- 受払先名
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update start
--        ,ABS(itc_out_ad_e_x97.trans_qty)               AS leaving_quantity
        ,itc_out_ad_e_x97.trans_qty                    AS leaving_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update end
  FROM   ic_tran_cmp                  itc_out_ad_e_x97                  -- OPM完了在庫トランザクション
        ,ic_jrnl_mst                  ijm_out_ad_e_x97                  -- OPMジャーナルマスタ
        ,ic_adjs_jnl                  iaj_out_ad_e_x97                  -- OPM在庫調整ジャーナル
        ,xxpo_rcv_and_rtn_txns        xrart_out_ad_e_x97                -- 受入返品実績アドオン
        ,ic_whse_mst                  iwm_out_ad_e_x97                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_ad_e_x97                  -- OPM保管場所マスタ
        ,po_vendors                   pv_out_ad_e_x97                   -- 仕入先マスタ
        ,xxcmn_vendors                xv_out_ad_e_x97                   -- 仕入先アドオンマスタ
        ,(SELECT xrpm_out_ad_e_x97.new_div_invent
                ,flv_out_ad_e_x97.meaning
                ,xrpm_out_ad_e_x97.reason_code
                ,xrpm_out_ad_e_x97.rcv_pay_div
          FROM   fnd_lookup_values flv_out_ad_e_x97                     -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_ad_e_x97                    -- 受払区分アドオンマスタ
          WHERE  flv_out_ad_e_x97.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_out_ad_e_x97.language                = 'JA'
          AND    flv_out_ad_e_x97.lookup_code             = xrpm_out_ad_e_x97.new_div_invent
          AND    xrpm_out_ad_e_x97.doc_type               = 'ADJI'
          AND    xrpm_out_ad_e_x97.use_div_invent         = 'Y'
          AND    xrpm_out_ad_e_x97.reason_code            = 'X977'               -- 相手先在庫
          AND    xrpm_out_ad_e_x97.rcv_pay_div            = '-1'                 -- 払出
         ) xrpm
  WHERE  itc_out_ad_e_x97.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_out_ad_e_x97.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_out_ad_e_x97.lot_id                  = 0
  AND    iwm_out_ad_e_x97.mtl_organization_id     = mil_out_ad_e_x97.organization_id
  AND    itc_out_ad_e_x97.whse_code               = iwm_out_ad_e_x97.whse_code
  AND    itc_out_ad_e_x97.location                = mil_out_ad_e_x97.segment1
  AND    ijm_out_ad_e_x97.journal_id              = iaj_out_ad_e_x97.journal_id   -- OPMジャーナルマスタ抽出条件
  AND    iaj_out_ad_e_x97.doc_id                  = itc_out_ad_e_x97.doc_id       -- OPM在庫調整ジャーナル抽出条件
  AND    iaj_out_ad_e_x97.doc_line                = itc_out_ad_e_x97.doc_line     -- OPM在庫調整ジャーナル抽出条件
  AND    ijm_out_ad_e_x97.attribute1             IS NOT NULL                      -- OPMジャーナルマスタ.実績IDがNULLでない
  AND    TO_NUMBER(ijm_out_ad_e_x97.attribute1)   = xrart_out_ad_e_x97.txns_id    -- 実績ID
-- 2008/12/24 #809 Y.Yamamoto add start
  AND    ijm_out_ad_e_x97.attribute4             IS NULL
-- 2008/12/24 #809 Y.Yamamoto add end
  AND    xrart_out_ad_e_x97.vendor_id             = xv_out_ad_e_x97.vendor_id     -- 仕入先ID
  AND    pv_out_ad_e_x97.vendor_id                = xv_out_ad_e_x97.vendor_id
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    pv_out_ad_e_x97.end_date_active         IS NULL
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xv_out_ad_e_x97.start_date_active       <= TRUNC( SYSDATE )
  AND    xv_out_ad_e_x97.end_date_active         >= TRUNC( SYSDATE )
  UNION ALL
  -- 在庫調整 出庫実績(仕入先返品)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_ad_e_x2.attribute1                    AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_ad_e_x2.attribute1                    AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_ad_e_x2.inventory_location_id         AS inventory_location_id
        ,itc_out_ad_e_x2.item_id                       AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itc_out_ad_e_x2.trans_date                    AS arrival_date
--        ,itc_out_ad_e_x2.trans_date                    AS leaving_date
        ,TRUNC(itc_out_ad_e_x2.trans_date)             AS arrival_date
        ,TRUNC(itc_out_ad_e_x2.trans_date)             AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status      -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,xrart_out_ad_e_x2.rcv_rtn_number              AS voucher_no
        ,xv_out_ad_e_x2.vendor_name                    AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
-- 2008/12/11 T.Ohashi start
-- 2008/12/02 Y.Yamamoto update start
--        ,itc_out_ad_e_x2.trans_qty                     AS deliver_to_name
--        ,0                                             AS leaving_quantity
--        ,0                                             AS stock_quantity
        ,itc_out_ad_e_x2.trans_qty                     AS stock_quantity
--        ,itc_out_ad_e_x2.trans_qty * -1                AS leaving_quantity
        ,0                                             AS leaving_quantity
-- 2008/12/02 Y.Yamamoto update end
-- 2008/12/11 T.Ohashi end
  FROM   ic_adjs_jnl                  iaj_out_ad_e_x2                   -- OPM在庫調整ジャーナル
        ,ic_jrnl_mst                  ijm_out_ad_e_x2                   -- OPMジャーナルマスタ
        ,ic_tran_cmp                  itc_out_ad_e_x2                   -- OPM完了在庫トランザクション
        ,xxpo_rcv_and_rtn_txns        xrart_out_ad_e_x2                 -- 受入返品実績（アドオン）
        ,ic_whse_mst                  iwm_out_ad_e_x2                   -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_ad_e_x2                   -- OPM保管場所マスタ
        ,po_vendors                   pv_out_ad_e_x2                    -- 仕入先マスタ
        ,xxcmn_vendors                xv_out_ad_e_x2                    -- 仕入先アドオンマスタ
        ,(SELECT xrpm_out_ad_e_x2.new_div_invent
                ,flv_out_ad_e_x2.meaning
                ,xrpm_out_ad_e_x2.doc_type
                ,xrpm_out_ad_e_x2.reason_code
                ,xrpm_out_ad_e_x2.rcv_pay_div
          FROM   fnd_lookup_values flv_out_ad_e_x2                      -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_ad_e_x2                    -- 受払区分アドオンマスタ
          WHERE  flv_out_ad_e_x2.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_out_ad_e_x2.language                = 'JA'
          AND    flv_out_ad_e_x2.lookup_code             = xrpm_out_ad_e_x2.new_div_invent
          AND    xrpm_out_ad_e_x2.doc_type               = 'ADJI'
          AND    xrpm_out_ad_e_x2.use_div_invent         = 'Y'
          AND    xrpm_out_ad_e_x2.reason_code            = 'X201'               -- 仕入返品出庫
-- 2008/12/11 T.Ohashi start
--          AND    xrpm_out_ad_e_x2.rcv_pay_div            = '-1'                 -- 払出
          AND    xrpm_out_ad_e_x2.rcv_pay_div            = '1'                  -- 受入
-- 2008/12/11 T.Ohashi end
         ) xrpm
  WHERE  itc_out_ad_e_x2.doc_type                = xrpm.doc_type
  AND    itc_out_ad_e_x2.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_out_ad_e_x2.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_out_ad_e_x2.lot_id                  = 0
  AND    iwm_out_ad_e_x2.mtl_organization_id     = mil_out_ad_e_x2.organization_id
  AND    itc_out_ad_e_x2.whse_code               = iwm_out_ad_e_x2.whse_code
  AND    itc_out_ad_e_x2.location                = mil_out_ad_e_x2.segment1
  AND    iaj_out_ad_e_x2.journal_id              = ijm_out_ad_e_x2.journal_id
  AND    itc_out_ad_e_x2.doc_type                = iaj_out_ad_e_x2.trans_type
  AND    itc_out_ad_e_x2.doc_id                  = iaj_out_ad_e_x2.doc_id
  AND    itc_out_ad_e_x2.doc_line                = iaj_out_ad_e_x2.doc_line
  AND    TO_NUMBER( ijm_out_ad_e_x2.attribute1 ) = xrart_out_ad_e_x2.txns_id
-- 2008/12/24 #809 Y.Yamamoto add start
-- 2008/12/29 #809 Y.Yamamoto delete start
--  AND    ijm_out_ad_e_x2.attribute4             IS NULL
-- 2008/12/29 #809 Y.Yamamoto delete end
-- 2008/12/24 #809 Y.Yamamoto add end
  AND    xrart_out_ad_e_x2.vendor_id             = xv_out_ad_e_x2.vendor_id     -- 仕入先ID
  AND    pv_out_ad_e_x2.vendor_id                = xv_out_ad_e_x2.vendor_id
-- 2008/12/24 #826 Y.Yamamoto delete start
--  AND    pv_out_ad_e_x2.end_date_active         IS NULL
-- 2008/12/24 #826 Y.Yamamoto delete end
  AND    xv_out_ad_e_x2.start_date_active       <= TRUNC( SYSDATE )
  AND    xv_out_ad_e_x2.end_date_active         >= TRUNC( SYSDATE )
  UNION ALL
-- 2008/12/3 Y.Kawano delete start
--  -- 在庫調整 出庫実績(移動実績訂正)
--  SELECT iwm_out_ad_e_12.attribute1                    AS ownership_code
--        ,mil_out_ad_e_12.inventory_location_id         AS inventory_location_id
--        ,xmldt_out_ad_e_12.item_id                     AS item_id
--        ,NULL                                          AS lot_no
--        ,NULL                                          AS manufacture_date
--        ,NULL                                          AS uniqe_sign
--        ,NULL                                          AS expiration_date -- <---- ここまで共通
--        ,itc_out_ad_e_12.trans_date                    AS arrival_date
--        ,itc_out_ad_e_12.trans_date                    AS leaving_date
--        ,'2'                                           AS status   -- 実績
--        ,xrpm.new_div_invent                           AS reason_code
--        ,xrpm.meaning                                  AS reason_code_name
--        ,xmrih_out_ad_e_12.mov_num                     AS voucher_no
--        ,mil2_out_ad_e_12.description                  AS ukebaraisaki_name
--        ,NULL                                          AS deliver_to_name
--        ,itc_out_ad_e_12.trans_qty                     AS stock_quantity
--        ,0                                             AS leaving_quantity
--  FROM   xxinv_mov_req_instr_headers  xmrih_out_ad_e_12                -- 移動依頼/指示ヘッダ(アドオン)
--        ,xxinv_mov_req_instr_lines    xmril_out_ad_e_12                -- 移動依頼/指示明細(アドオン)
--        ,xxinv_mov_lot_details        xmldt_out_ad_e_12                -- 移動ロット詳細(アドオン)
--        ,ic_adjs_jnl                  iaj_out_ad_e_12                  -- OPM在庫調整ジャーナル
--        ,ic_jrnl_mst                  ijm_out_ad_e_12                  -- OPMジャーナルマスタ
--        ,ic_tran_cmp                  itc_out_ad_e_12                  -- OPM完了在庫トランザクション
--        ,ic_whse_mst                  iwm_out_ad_e_12                  -- OPM倉庫マスタ
--        ,mtl_item_locations           mil_out_ad_e_12                  -- OPM保管場所マスタ
--        ,mtl_item_locations           mil2_out_ad_e_12                 -- OPM保管場所マスタ
--        ,(SELECT xrpm_out_ad_e_12.new_div_invent
--                ,flv_out_ad_e_12.meaning
--                ,xrpm_out_ad_e_12.doc_type
--                ,xrpm_out_ad_e_12.reason_code
--                ,xrpm_out_ad_e_12.rcv_pay_div
--          FROM   fnd_lookup_values flv_out_ad_e_12                      -- クイックコード
--                ,xxcmn_rcv_pay_mst xrpm_out_ad_e_12                    -- 受払区分アドオンマスタ
--          WHERE  flv_out_ad_e_12.lookup_type            = 'XXCMN_NEW_DIVISION'
--          AND    flv_out_ad_e_12.language               = 'JA'
--          AND    flv_out_ad_e_12.lookup_code            = xrpm_out_ad_e_12.new_div_invent
--          AND    xrpm_out_ad_e_12.doc_type              = 'ADJI'
--          AND    xrpm_out_ad_e_12.use_div_invent        = 'Y'
--          AND    xrpm_out_ad_e_12.reason_code           = 'X123'               -- 移動実績訂正
--          AND    xrpm_out_ad_e_12.rcv_pay_div           = '1'                  -- 受入
--         ) xrpm
--  WHERE  itc_out_ad_e_12.doc_type               = xrpm.doc_type
--  AND    itc_out_ad_e_12.reason_code            = xrpm.reason_code
---- 2008/10/23 Y.Yamamoto v1.1 delete start
----  AND    SIGN( itc_out_ad_e_12.trans_qty )      = xrpm.rcv_pay_div
---- 2008/10/23 Y.Yamamoto v1.1 delete end
--  AND    itc_out_ad_e_12.item_id                = xmldt_out_ad_e_12.item_id
--  AND    itc_out_ad_e_12.lot_id                 = xmldt_out_ad_e_12.lot_id
--  AND    itc_out_ad_e_12.location               = xmrih_out_ad_e_12.shipped_locat_code
--  AND    itc_out_ad_e_12.doc_type               = iaj_out_ad_e_12.trans_type
--  AND    itc_out_ad_e_12.doc_id                 = iaj_out_ad_e_12.doc_id
--  AND    itc_out_ad_e_12.doc_line               = iaj_out_ad_e_12.doc_line
--  AND    iaj_out_ad_e_12.journal_id             = ijm_out_ad_e_12.journal_id
--  AND    xmril_out_ad_e_12.mov_line_id          = TO_NUMBER( ijm_out_ad_e_12.attribute1 )
--  AND    xmldt_out_ad_e_12.lot_id               = 0
--  AND    xmldt_out_ad_e_12.record_type_code     = '20'
--  AND    xmldt_out_ad_e_12.document_type_code   = '20'
--  AND    xmril_out_ad_e_12.mov_line_id          = xmldt_out_ad_e_12.mov_line_id
--  AND    xmrih_out_ad_e_12.mov_hdr_id           = xmril_out_ad_e_12.mov_hdr_id
--  AND    xmrih_out_ad_e_12.shipped_locat_id     = mil_out_ad_e_12.inventory_location_id
--  AND    iwm_out_ad_e_12.mtl_organization_id    = mil_out_ad_e_12.organization_id
--  AND    xmrih_out_ad_e_12.ship_to_locat_id     = mil2_out_ad_e_12.inventory_location_id
--  UNION ALL
-- 2008/12/3 Y.Kawano delete end
  -- 在庫調整 出庫実績(上記以外)
-- 2008/12/07 N.Yoshida start
--  SELECT iwm_out_ad_e_xx.attribute1                    AS ownership_code
  SELECT NULL                                          AS po_trans_id
        ,iwm_out_ad_e_xx.attribute1                    AS ownership_code
-- 2008/12/07 N.Yoshida end
        ,mil_out_ad_e_xx.inventory_location_id         AS inventory_location_id
        ,itc_out_ad_e_xx.item_id                       AS item_id
        ,NULL                                          AS lot_no
        ,NULL                                          AS manufacture_date
        ,NULL                                          AS uniqe_sign
        ,NULL                                          AS expiration_date -- <---- ここまで共通
--2009/01/07 Y.Kawano Mod Start
--        ,itc_out_ad_e_xx.trans_date                    AS arrival_date
--        ,itc_out_ad_e_xx.trans_date                    AS leaving_date
        ,TRUNC(itc_out_ad_e_xx.trans_date)             AS arrival_date
        ,TRUNC(itc_out_ad_e_xx.trans_date)             AS leaving_date
--2009/01/07 Y.Kawano Mod End
        ,'2'                                           AS status   -- 実績
        ,xrpm.new_div_invent                           AS reason_code
        ,xrpm.meaning                                  AS reason_code_name
        ,ijm_out_ad_e_xx.journal_no                    AS voucher_no
        ,xrpm.meaning                                  AS ukebaraisaki_name
        ,NULL                                          AS deliver_to_name
        ,0                                             AS stock_quantity
-- 2008/10/31 Y.Yamamoto v1.1 update start
--        ,ABS(itc_out_ad_e_xx.trans_qty)                AS leaving_quantity
-- 2008/11/28 H.Itou Mod Start 本番障害#142
--        ,CASE
--          WHEN (xrpm.new_div_invent = '503' ) THEN
--            itc_out_ad_e_xx.trans_qty * -1
--          ELSE
--            itc_out_ad_e_xx.trans_qty
--          END                                             leaving_quantity
        ,itc_out_ad_e_xx.trans_qty * -1                AS leaving_quantity
-- 2008/11/28 H.Itou Mod End 本番障害#142
-- 2008/10/31 Y.Yamamoto v1.1 update end
  FROM   ic_adjs_jnl                  iaj_out_ad_e_xx                  -- OPM在庫調整ジャーナル
        ,ic_jrnl_mst                  ijm_out_ad_e_xx                  -- OPMジャーナルマスタ
        ,ic_tran_cmp                  itc_out_ad_e_xx                  -- OPM完了在庫トランザクション
        ,ic_whse_mst                  iwm_out_ad_e_xx                  -- OPM倉庫マスタ
        ,mtl_item_locations           mil_out_ad_e_xx                  -- OPM保管場所マスタ
        ,(SELECT xrpm_out_ad_e_xx.new_div_invent
                ,flv_out_ad_e_xx.meaning
                ,xrpm_out_ad_e_xx.doc_type
                ,xrpm_out_ad_e_xx.reason_code
                ,xrpm_out_ad_e_xx.rcv_pay_div
          FROM   fnd_lookup_values flv_out_ad_e_xx                     -- クイックコード
                ,xxcmn_rcv_pay_mst xrpm_out_ad_e_xx                    -- 受払区分アドオンマスタ
          WHERE  flv_out_ad_e_xx.lookup_type             = 'XXCMN_NEW_DIVISION'
          AND    flv_out_ad_e_xx.language                = 'JA'
          AND    flv_out_ad_e_xx.lookup_code             = xrpm_out_ad_e_xx.new_div_invent
          AND    xrpm_out_ad_e_xx.doc_type               = 'ADJI'
          AND    xrpm_out_ad_e_xx.use_div_invent         = 'Y'
          AND    xrpm_out_ad_e_xx.reason_code       NOT IN ('X977','X201','X123')
          AND    xrpm_out_ad_e_xx.rcv_pay_div            = '-1'                 -- 払出
         ) xrpm
  WHERE  itc_out_ad_e_xx.doc_type                = xrpm.doc_type
  AND    itc_out_ad_e_xx.reason_code             = xrpm.reason_code
-- 2008/10/23 Y.Yamamoto v1.1 delete start
--  AND    SIGN( itc_out_ad_e_xx.trans_qty )       = xrpm.rcv_pay_div
-- 2008/10/23 Y.Yamamoto v1.1 delete end
  AND    itc_out_ad_e_xx.lot_id                  = 0
  AND    iwm_out_ad_e_xx.mtl_organization_id     = mil_out_ad_e_xx.organization_id
  AND    itc_out_ad_e_xx.whse_code               = iwm_out_ad_e_xx.whse_code
  AND    itc_out_ad_e_xx.location                = mil_out_ad_e_xx.segment1
  AND    iaj_out_ad_e_xx.journal_id              = ijm_out_ad_e_xx.journal_id
-- 2008/12/24 #809 Y.Yamamoto add start
-- 2008/12/29 #809 Y.Yamamoto delete start
--  AND    ijm_out_ad_e_xx.attribute4             IS NULL
-- 2008/12/29 #809 Y.Yamamoto delete end
-- 2008/12/24 #809 Y.Yamamoto add end
  AND    itc_out_ad_e_xx.doc_type                = iaj_out_ad_e_xx.trans_type
  AND    itc_out_ad_e_xx.doc_id                  = iaj_out_ad_e_xx.doc_id
  AND    itc_out_ad_e_xx.doc_line                = iaj_out_ad_e_xx.doc_line
;
--
-- 2008/12/07 N.Yoshida start
COMMENT ON COLUMN xxinv_stc_trans_p0_v.po_trans_id           IS '発注実績用ID';
-- 2008/12/07 N.Yoshida end
COMMENT ON COLUMN xxinv_stc_trans_p0_v.ownership_code        IS '名義コード';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.inventory_location_id IS '保管倉庫ID';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.item_id               IS '品目ID';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.lot_no                IS 'ロットNo';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.manufacture_date      IS '製造年月日';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.uniqe_sign            IS '固有記号';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.expiration_date       IS '賞味期限';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.arrival_date          IS '着日';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.leaving_date          IS '発日';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.status                IS 'ステータス';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.reason_code           IS '事由コード';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.reason_code_name      IS '事由コード名';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.voucher_no            IS '伝票No';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.ukebaraisaki_name     IS '受払先';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.deliver_to_name       IS '配送先';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.stock_quantity        IS '入庫数';
COMMENT ON COLUMN xxinv_stc_trans_p0_v.leaving_quantity      IS '出庫数';
--
COMMENT ON TABLE  xxinv_stc_trans_p0_v IS '入出庫情報ビュー 製品 非ロット管理品' ;
/