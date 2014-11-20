/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_LOCT_INV_MV
 * Description     : 計画_手持在庫マテリアライズドビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009-05-07    1.0   SCS.Goto         新規作成(2009/04/27 XXINV540001.pkb)
 *
 ************************************************************************/
--
CREATE MATERIALIZED VIEW APPS.XXCOP_LOCT_INV_MV
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 131072 NEXT 131072 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "APPS_TS_TX_DATA"
  BUILD IMMEDIATE
  USING INDEX
  REFRESH COMPLETE ON DEMAND START WITH SYSDATE+0 NEXT SYSDATE + 1/24/60*10
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  DISABLE QUERY REWRITE
  AS
  SELECT iwm.whse_code   organization_code,                       -- 組織コード
         iwm.mtl_organization_id organization_id,                 -- 組織ID
         mil.segment1    whse_code,                               -- 保管倉庫コード
         mil.attribute12 whse_short_name,                         -- 保管倉庫名
         mil.inventory_location_id inv_loct_id,                   -- 保管倉庫ID
         ximv.item_id    item_id,                                 -- 品目ID
         ximv.item_no    item_no,                                 -- 品目コード
         ximv.item_short_name item_short_name,                    -- 品目名
         NVL(ximv.num_of_cases, 1) num_of_cases,                  -- ケース入数
         ilm.lot_no      lot_no,                                  -- ロットNo
         ilm.lot_id      lot_id,                                  -- ロットID
         FND_DATE.STRING_TO_DATE(ilm.attribute1, 'YYYY/MM/DD') manufacture_date, -- 製造年月日(DFF1)
         FND_DATE.STRING_TO_DATE(ilm.attribute3, 'YYYY/MM/DD') expiration_date, -- 賞味期限(DFF3)
         ilm.attribute2  uniqe_sign,                                   -- 固有記号(DFF2)
         FND_DATE.STRING_TO_DATE(ilm.attribute4, 'YYYY/MM/DD') attr4, -- 初回納入日(DFF4)
         FND_DATE.STRING_TO_DATE(ilm.attribute5, 'YYYY/MM/DD') attr5, -- 最終納入日(DFF5)
         TO_NUMBER(ilm.attribute6) attr6,                         -- 在庫入数(DFF6)
         TO_NUMBER(ilm.attribute7) attr7,                         -- 在庫単価(DFF7)
         ilm.attribute8  attr8,                                   -- 受払先(DFF8)
         xvv.vendor_short_name vnd_short_name,                    -- 受払先名
         ilm.attribute9  attr9,                                   -- 仕入形態(DFF9)
         xlvv_xl5.meaning attr9_mean,                             -- 仕入形態内容
         ilm.attribute10 attr10,                                  -- 茶期区分(DFF10)
         xlvv_xl6.meaning attr10_mean,                            -- 茶期区分内容
         ilm.attribute11 attr11,                                  -- 年度(DFF11)
         ilm.attribute12 attr12,                                  -- 産地(DFF12)
         xlvv_xl7.meaning attr12_mean,                            -- 産地内容
         ilm.attribute13 attr13,                                  -- タイプ(DFF13)
         xlvv_xl8.meaning attr13_mean,                            -- タイプ内容
         ilm.attribute14 attr14,                                  -- ランク1(DFF14)
         ilm.attribute15 attr15,                                  -- ランク2(DFF15)
         ilm.attribute19 attr19,                                  -- ランク3(DFF19)
         ilm.attribute16 attr16,                                  -- 生産伝票区分(DFF16)
         xlvv_xl3.meaning attr16_mean,                            -- 生産伝票区分内容
         ilm.attribute17 attr17,                                  -- ラインNo(DFF17)
         gr.routing_desc routing_desc,                            -- 工順摘要
         ilm.attribute18 attr18,                                  -- 摘要(DFF18)
         ilm.attribute23 lot_status,                              -- ロットステータス(DFF23)
         xlvv_xls.meaning lot_mean,                               -- ロットステータス内容
         xqi.qt_inspect_req_no qt_inspect_req_no,                 -- 品質検査依頼情報
         xlvv_xqs.meaning qt_ins_mean,                            -- 品質結果内容
         ili.loct_onhand loct_onhand,                             -- 手持数量
         (
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status            IN ('05','06')
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '30')
          -
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status            IN ('04','06')
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '20')
          -
         (SELECT  NVL(SUM(CASE
                  WHEN (otta.order_category_code = 'ORDER') THEN
                    NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                  WHEN (otta.order_category_code = 'RETURN') THEN
                   (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                  END), 0)
          FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
                  xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
                  xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
                  oe_transaction_types_all   otta  -- 受注タイプ
          WHERE   oha.deliver_from_id       = mil.inventory_location_id
          AND     oha.req_status            = '04'
          AND     oha.actual_confirm_class  = 'N'
          AND     oha.latest_external_flag  = 'Y'
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = 'N'
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.item_id               = ximv.item_id
          AND     mld.lot_id                = ilm.lot_id
          AND     mld.document_type_code    = '10'
          AND     mld.record_type_code      = '20'
          AND     otta.attribute1           IN ('1','3')
          AND     otta.transaction_type_id  = oha.order_type_id)
          -
         (SELECT  NVL(SUM(CASE
                  WHEN (otta.order_category_code = 'ORDER') THEN
                    NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                  WHEN (otta.order_category_code = 'RETURN') THEN
                   (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                  END), 0)
          FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
                  xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
                  xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
                  oe_transaction_types_all  otta   -- 受注タイプ
          WHERE   oha.deliver_from_id       = mil.inventory_location_id
          AND     oha.req_status            = '08'
          AND     oha.actual_confirm_class  = 'N'
          AND     oha.latest_external_flag  = 'Y'
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = 'N'
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.item_id               = ximv.item_id
          AND     mld.lot_id                = ilm.lot_id
          AND     mld.document_type_code    = '30'
          AND     mld.record_type_code      = '20'
          AND     otta.attribute1           = '2'
          AND     otta.transaction_type_id  = oha.order_type_id)
          +
          (SELECT  NVL(SUM(mld.actual_quantity), 0) - NVL(SUM(mld.before_actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'Y'
          AND     mrih.correct_actual_flg = 'Y'
          AND     mrih.status             = '06'
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '30')
          +
          (SELECT  NVL(SUM(mld.before_actual_quantity), 0) - NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'Y'
          AND     mrih.correct_actual_flg = 'Y'
          AND     mrih.status             = '06'
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '20')
         )               stock_qty,                               -- 手持在庫数
         (
         (SELECT  NVL(SUM(pla.quantity), 0)
          FROM    mtl_system_items_b msib,
                  po_lines_all       pla,
                  po_headers_all     pha
          WHERE   msib.segment1          = ximv.item_no
          AND     msib.organization_id   = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'))
          AND     msib.inventory_item_id = pla.item_id
          AND     pla.attribute1         = ilm.lot_no
          AND     pla.attribute13        = 'N'
          AND     pla.cancel_flag        = 'N'
          AND     pla.po_header_id       = pha.po_header_id
          AND     pha.org_id = FND_PROFILE.VALUE('ORG_ID')
          AND     pha.attribute1        IN ('20','25')
          AND     pha.attribute5         = mil.segment1
          AND     pha.attribute4        <= FND_PROFILE.VALUE('XXCMN_MAX_DATE')) -- 納入日
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status IN ('02','03')
          AND     mrih.schedule_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '10')
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status             = '04'
          AND     mrih.schedule_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.actual_arrival_date  IS NULL
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '20')
         +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status             = '04'
          AND     mrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.actual_arrival_date  IS NOT NULL
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '20')
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    gme_batch_header      gbh, -- 生産バッチ
                  gme_material_details  gmd, -- 生産原料詳細
                  ic_tran_pnd           itp, -- OPM保留在庫トランザクション
                  xxinv_mov_lot_details mld, -- 移動ロット詳細（アドオン）
                  gmd_routings_b        grb  -- 工順マスタ
          WHERE   gbh.batch_status      IN (1,2)
          AND     gbh.plan_start_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     gbh.batch_id           = gmd.batch_id
          AND     gmd.line_type         IN (1,2)
          AND     gmd.item_id            = ximv.item_id
          AND     gmd.material_detail_id = itp.line_id
          AND     itp.completed_ind      = 0
          AND     itp.doc_type           = 'PROD'
          AND     itp.delete_mark        = 0
          AND     itp.lot_id             = ilm.lot_id
          AND     gmd.material_detail_id = mld.mov_line_id
          AND     mld.document_type_code = '40'
          AND     mld.record_type_code   = '10'
          AND     gbh.routing_id         = grb.routing_id
          AND     grb.attribute9         = mil.segment1)     -- 納品場所
         ) inbound_qty,                        -- 入庫予定数
         (
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status IN ('02','03')
          AND     mrih.schedule_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '10')
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status             = '05'
          AND     mrih.schedule_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.actual_ship_date  IS NULL
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '30')
         +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status             = '05'
          AND     mrih.actual_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.actual_ship_date  IS NOT NULL
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '30')
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
                  xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
                  xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
                  oe_transaction_types_all   otta  -- 受注タイプ
          WHERE   oha.deliver_from_id       = mil.inventory_location_id
          AND     oha.req_status            = '03'
          AND     oha.actual_confirm_class  = 'N'
          AND     oha.latest_external_flag  = 'Y'
          AND     oha.schedule_ship_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = 'N'
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.item_id               = ximv.item_id
          AND     mld.lot_id                = ilm.lot_id
          AND     mld.document_type_code    = '10'
          AND     mld.record_type_code      = '10'
          AND     otta.attribute1           = '1'
          AND     otta.transaction_type_id  = oha.order_type_id)
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
                  xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
                  xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
                  oe_transaction_types_all  otta   -- 受注タイプ
          WHERE   oha.deliver_from_id       = mil.inventory_location_id
          AND     oha.req_status            = '07'
          AND     oha.actual_confirm_class  = 'N'
          AND     oha.latest_external_flag  = 'Y'
          AND     oha.schedule_ship_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = 'N'
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.item_id               = ximv.item_id
          AND     mld.lot_id                = ilm.lot_id
          AND     mld.document_type_code    = '30'
          AND     mld.record_type_code      = '10'
          AND     otta.attribute1           = '2'
          AND     otta.transaction_type_id  = oha.order_type_id)
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    gme_batch_header      gbh, -- 生産バッチ
                  gme_material_details  gmd, -- 生産原料詳細
                  xxinv_mov_lot_details mld, -- 移動ロット詳細（アドオン）
                  gmd_routings_b        grb, -- 工順マスタ
                  ic_tran_pnd           itp  -- 保留在庫トランザクション
          WHERE   gbh.batch_status      IN (1,2)
          AND     gbh.plan_start_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     gbh.batch_id           = gmd.batch_id
          AND     gmd.line_type          = -1
          AND     gmd.item_id            = ximv.item_id
          AND     gmd.material_detail_id = mld.mov_line_id
          AND     mld.lot_id             = ilm.lot_id
          AND     gbh.routing_id         = grb.routing_id
          AND     grb.attribute9         = mil.segment1      -- 納品場所
          AND     mld.document_type_code = '40'
          AND     mld.record_type_code   = '10'
          AND     itp.line_id            = gmd.material_detail_id
          AND     itp.item_id            = gmd.item_id
          AND     itp.lot_id             = mld.lot_id
          AND     itp.doc_type           = 'PROD'
          AND     itp.delete_mark        = 0
          AND     itp.completed_ind      = 0)
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    mtl_system_items_b    msib,   -- 品目マスタ
                  po_lines_all          pla,    -- 発注明細
                  po_headers_all        pha,    -- 発注ヘッダ
                  xxinv_mov_lot_details mld     -- 移動ロット詳細（アドオン）
          WHERE   msib.segment1          = ximv.item_no
          AND     msib.organization_id   = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'))
          AND     msib.inventory_item_id = pla.item_id
          AND     pla.attribute13        = 'N'
          AND     pla.cancel_flag        = 'N'
          AND     pla.attribute12        = mil.segment1     -- 相手先在庫入庫先
          AND     pla.po_header_id       = pha.po_header_id
          AND     pha.org_id = FND_PROFILE.VALUE('ORG_ID')
          AND     pha.attribute1        IN ('20','25')
          AND     pha.attribute4        <= FND_PROFILE.VALUE('XXCMN_MAX_DATE') -- 納入日
          AND     pla.po_line_id         = mld.mov_line_id
          AND     mld.lot_id             = ilm.lot_id
          AND     mld.document_type_code = '50'
          AND     mld.record_type_code   = '10')
         ) outbound_qty,                        -- 出庫予定数
         ilm.created_by created_by,                               -- 作成者
         ilm.creation_date creation_date,                         -- 作成日
         ilm.last_updated_by last_updated_by,                     -- 最終更新者
         ilm.last_update_date last_update_date,                   -- 最終更新日
         ilm.last_update_login last_update_login,                 -- 最終更新ログイン
         ili.last_update_date  ili_last_update_date,              -- OPM手持数量 最終更新日
         mil.attribute5 frequent_whse                             -- 代表倉庫
  FROM   xxcmn_item_mst_v           ximv,    -- OPM品目マスタ情報VIEW
         ic_lots_mst                ilm,     -- OPMロットマスタ
         mtl_item_locations         mil,
         ic_whse_mst                iwm,
         gmi_item_categories        gic_s,
         mtl_categories_b           mcb_s,
         gmi_item_categories        gic_h,
         mtl_categories_b           mcb_h,
         ic_loct_inv                ili,
        (SELECT xq.qt_inspect_req_no,
                CASE
                  WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                    xq.qt_effect3                      -- 結果3
                  WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                    xq.qt_effect2                      -- 結果2
                  WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                    xq.qt_effect1                      -- 結果1
                  ELSE
                    NULL
                END  qt_effect
         FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXCMN_L05') xlvv_xl5,
                                                -- クイックコード(仕入形態内容)
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXCMN_L06') xlvv_xl6,
                                                -- クイックコード(茶期区分内容)
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXCMN_L07') xlvv_xl7,
                                                -- クイックコード(産地内容)
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXCMN_L08') xlvv_xl8,
                                                -- クイックコード(タイプ内容)
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXCMN_L03') xlvv_xl3,
                                                -- クイックコード(生産伝票区分内容)
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXWIP_QT_STATUS') xlvv_xqs,
                                                -- クイックコード(品質結果内容)
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXCMN_LOT_STATUS') xlvv_xls,
                                                -- クイックコード(ロットステータス)
         xxcmn_vendors_v            xvv,        -- 仕入先情報
        (SELECT grb.routing_no,
                grt.routing_desc
         FROM   gmd_routings_b  grb,            -- 工順マスタ
                gmd_routings_tl grt             -- 工順マスタ名称
         WHERE  grb.routing_id = grt.routing_id
         AND    grt.language   = 'JA') gr
  WHERE  ximv.item_id            = ilm.item_id
  AND    ximv.item_id            = gic_s.item_id
  AND    gic_s.category_id       = mcb_s.category_id
  AND    gic_s.category_set_id   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_s.segment1          = '5'
  AND    ximv.item_id            = gic_h.item_id
  AND    gic_h.category_id       = mcb_h.category_id
  AND    gic_h.category_set_id   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND    mcb_h.segment1          = '2'
  -- ロット管理品
  AND    ximv.lot_ctl            = '1'
  AND    ilm.lot_id             <> 0
  -- OPM手持絞込み
  -- 品目(保管場所)と手持数量の関連付け
  AND    ximv.item_id            = ili.item_id
  AND    mil.segment1            = ili.location
  AND    ilm.lot_id              = ili.lot_id
  -- 在庫組織とOPM倉庫の紐付け
  AND    iwm.mtl_organization_id = mil.organization_id
  -- 名称取得
  AND    ilm.attribute8             = xvv.segment1(+)
  AND    ilm.attribute9             = xlvv_xl5.lookup_code(+)
  AND    ilm.attribute10            = xlvv_xl6.lookup_code(+)
  AND    ilm.attribute12            = xlvv_xl7.lookup_code(+)
  AND    ilm.attribute13            = xlvv_xl8.lookup_code(+)
  AND    ilm.attribute16            = xlvv_xl3.lookup_code(+)
  AND    xqi.qt_effect              = xlvv_xqs.lookup_code(+)
  AND    ilm.attribute23            = xlvv_xls.lookup_code(+)
  AND    ilm.attribute17            = gr.routing_no(+)
  AND    TO_NUMBER(ilm.attribute22) = xqi.qt_inspect_req_no(+)
  -- 抽出条件(画面検索値)
  AND    iwm.attribute1             = '0'
  UNION ALL
  SELECT iwm.whse_code   organization_code,                       -- 組織コード
         iwm.mtl_organization_id organization_id,                 -- 組織ID
         mil.segment1    whse_code,                               -- 保管倉庫コード
         mil.attribute12 whse_short_name,                         -- 保管倉庫名
         mil.inventory_location_id inv_loct_id,                   -- 保管倉庫ID
         ximv.item_id    item_id,                                 -- 品目ID
         ximv.item_no    item_no,                                 -- 品目コード
         ximv.item_short_name item_short_name,                    -- 品目名
         NVL(ximv.num_of_cases, 1) num_of_cases,             -- ケース入数
         ilm.lot_no      lot_no,                                  -- ロットNo
         ilm.lot_id      lot_id,                                  -- ロットID
         FND_DATE.STRING_TO_DATE(ilm.attribute1, 'YYYY/MM/DD') manufacture_date, -- 製造年月日(DFF1)
         FND_DATE.STRING_TO_DATE(ilm.attribute3, 'YYYY/MM/DD') expiration_date, -- 賞味期限(DFF3)
         ilm.attribute2  uniqe_sign,                                   -- 固有記号(DFF2)
         FND_DATE.STRING_TO_DATE(ilm.attribute4, 'YYYY/MM/DD') attr4, -- 初回納入日(DFF4)
         FND_DATE.STRING_TO_DATE(ilm.attribute5, 'YYYY/MM/DD') attr5, -- 最終納入日(DFF5)
         TO_NUMBER(ilm.attribute6) attr6,                         -- 在庫入数(DFF6)
         TO_NUMBER(ilm.attribute7) attr7,                         -- 在庫単価(DFF7)
         ilm.attribute8  attr8,                                   -- 受払先(DFF8)
         xvv.vendor_short_name vnd_short_name,                    -- 受払先名
         ilm.attribute9  attr9,                                   -- 仕入形態(DFF9)
         xlvv_xl5.meaning attr9_mean,                             -- 仕入形態内容
         ilm.attribute10 attr10,                                  -- 茶期区分(DFF10)
         xlvv_xl6.meaning attr10_mean,                            -- 茶期区分内容
         ilm.attribute11 attr11,                                  -- 年度(DFF11)
         ilm.attribute12 attr12,                                  -- 産地(DFF12)
         xlvv_xl7.meaning attr12_mean,                            -- 産地内容
         ilm.attribute13 attr13,                                  -- タイプ(DFF13)
         xlvv_xl8.meaning attr13_mean,                            -- タイプ内容
         ilm.attribute14 attr14,                                  -- ランク1(DFF14)
         ilm.attribute15 attr15,                                  -- ランク2(DFF15)
         ilm.attribute19 attr19,                                  -- ランク3(DFF19)
         ilm.attribute16 attr16,                                  -- 生産伝票区分(DFF16)
         xlvv_xl3.meaning attr16_mean,                            -- 生産伝票区分内容
         ilm.attribute17 attr17,                                  -- ラインNo(DFF17)
         gr.routing_desc routing_desc,                            -- 工順摘要
         ilm.attribute18 attr18,                                  -- 摘要(DFF18)
         ilm.attribute23 lot_status,                              -- ロットステータス(DFF23)
         xlvv_xls.meaning lot_mean,                               -- ロットステータス内容
         xqi.qt_inspect_req_no qt_inspect_req_no,                 -- 品質検査依頼情報
         xlvv_xqs.meaning qt_ins_mean,                            -- 品質結果内容
         0 loct_onhand,                                           -- 手持数量
         (
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status            IN ('05','06')
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '30')
          -
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status            IN ('04','06')
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '20')
          -
         (SELECT  NVL(SUM(CASE
                  WHEN (otta.order_category_code = 'ORDER') THEN
                    NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                  WHEN (otta.order_category_code = 'RETURN') THEN
                   (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                  END), 0)
          FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
                  xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
                  xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
                  oe_transaction_types_all   otta  -- 受注タイプ
          WHERE   oha.deliver_from_id       = mil.inventory_location_id
          AND     oha.req_status            = '04'
          AND     oha.actual_confirm_class  = 'N'
          AND     oha.latest_external_flag  = 'Y'
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = 'N'
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.item_id               = ximv.item_id
          AND     mld.lot_id                = ilm.lot_id
          AND     mld.document_type_code    = '10'
          AND     mld.record_type_code      = '20'
          AND     otta.attribute1           IN ('1','3')
          AND     otta.transaction_type_id  = oha.order_type_id)
          -
         (SELECT  NVL(SUM(CASE
                  WHEN (otta.order_category_code = 'ORDER') THEN
                    NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                  WHEN (otta.order_category_code = 'RETURN') THEN
                   (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                  END), 0)
          FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
                  xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
                  xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
                  oe_transaction_types_all  otta   -- 受注タイプ
          WHERE   oha.deliver_from_id       = mil.inventory_location_id
          AND     oha.req_status            = '08'
          AND     oha.actual_confirm_class  = 'N'
          AND     oha.latest_external_flag  = 'Y'
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = 'N'
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.item_id               = ximv.item_id
          AND     mld.lot_id                = ilm.lot_id
          AND     mld.document_type_code    = '30'
          AND     mld.record_type_code      = '20'
          AND     otta.attribute1           = '2'
          AND     otta.transaction_type_id  = oha.order_type_id)
          +
          (SELECT  NVL(SUM(mld.actual_quantity), 0) - NVL(SUM(mld.before_actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'Y'
          AND     mrih.correct_actual_flg = 'Y'
          AND     mrih.status             = '06'
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '30')
          +
          (SELECT  NVL(SUM(mld.before_actual_quantity), 0) - NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'Y'
          AND     mrih.correct_actual_flg = 'Y'
          AND     mrih.status             = '06'
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '20')
         )               stock_qty,                               -- 手持在庫数
         (
         (SELECT  NVL(SUM(pla.quantity), 0)
          FROM    mtl_system_items_b msib,
                  po_lines_all       pla,
                  po_headers_all     pha
          WHERE   msib.segment1          = ximv.item_no
          AND     msib.organization_id   = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'))
          AND     msib.inventory_item_id = pla.item_id
          AND     pla.attribute1         = ilm.lot_no
          AND     pla.attribute13        = 'N'
          AND     pla.cancel_flag        = 'N'
          AND     pla.po_header_id       = pha.po_header_id
          AND     pha.org_id = FND_PROFILE.VALUE('ORG_ID')
          AND     pha.attribute1        IN ('20','25')
          AND     pha.attribute5         = mil.segment1
          AND     pha.attribute4        <= FND_PROFILE.VALUE('XXCMN_MAX_DATE')) -- 納入日
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status IN ('02','03')
          AND     mrih.schedule_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '10')
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status             = '04'
          AND     mrih.schedule_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.actual_arrival_date  IS NULL
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '20')
         +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status             = '04'
          AND     mrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.actual_arrival_date  IS NOT NULL
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '20')
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    gme_batch_header      gbh, -- 生産バッチ
                  gme_material_details  gmd, -- 生産原料詳細
                  ic_tran_pnd           itp, -- OPM保留在庫トランザクション
                  xxinv_mov_lot_details mld, -- 移動ロット詳細（アドオン）
                  gmd_routings_b        grb  -- 工順マスタ
          WHERE   gbh.batch_status      IN (1,2)
          AND     gbh.plan_start_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     gbh.batch_id           = gmd.batch_id
          AND     gmd.line_type         IN (1,2)
          AND     gmd.item_id            = ximv.item_id
          AND     gmd.material_detail_id = itp.line_id
          AND     itp.completed_ind      = 0
          AND     itp.doc_type           = 'PROD'
          AND     itp.delete_mark        = 0
          AND     itp.lot_id             = ilm.lot_id
          AND     gmd.material_detail_id = mld.mov_line_id
          AND     mld.document_type_code = '40'
          AND     mld.record_type_code   = '10'
          AND     gbh.routing_id         = grb.routing_id
          AND     grb.attribute9         = mil.segment1)     -- 納品場所
         ) inbound_qty,                        -- 入庫予定数
         (
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status IN ('02','03')
          AND     mrih.schedule_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '10')
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status             = '05'
          AND     mrih.schedule_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.actual_ship_date  IS NULL
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '30')
         +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
          AND     mrih.comp_actual_flg    = 'N'
          AND     mrih.status             = '05'
          AND     mrih.actual_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.actual_ship_date  IS NOT NULL
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.item_id             = ximv.item_id
          AND     mld.lot_id              = ilm.lot_id
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '30')
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
                  xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
                  xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
                  oe_transaction_types_all   otta  -- 受注タイプ
          WHERE   oha.deliver_from_id       = mil.inventory_location_id
          AND     oha.req_status            = '03'
          AND     oha.actual_confirm_class  = 'N'
          AND     oha.latest_external_flag  = 'Y'
          AND     oha.schedule_ship_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = 'N'
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.item_id               = ximv.item_id
          AND     mld.lot_id                = ilm.lot_id
          AND     mld.document_type_code    = '10'
          AND     mld.record_type_code      = '10'
          AND     otta.attribute1           = '1'
          AND     otta.transaction_type_id  = oha.order_type_id)
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
                  xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
                  xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
                  oe_transaction_types_all  otta   -- 受注タイプ
          WHERE   oha.deliver_from_id       = mil.inventory_location_id
          AND     oha.req_status            = '07'
          AND     oha.actual_confirm_class  = 'N'
          AND     oha.latest_external_flag  = 'Y'
          AND     oha.schedule_ship_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = 'N'
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.item_id               = ximv.item_id
          AND     mld.lot_id                = ilm.lot_id
          AND     mld.document_type_code    = '30'
          AND     mld.record_type_code      = '10'
          AND     otta.attribute1           = '2'
          AND     otta.transaction_type_id  = oha.order_type_id)
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    gme_batch_header      gbh, -- 生産バッチ
                  gme_material_details  gmd, -- 生産原料詳細
                  xxinv_mov_lot_details mld, -- 移動ロット詳細（アドオン）
                  gmd_routings_b        grb, -- 工順マスタ
                  ic_tran_pnd           itp  -- 保留在庫トランザクション
          WHERE   gbh.batch_status      IN (1,2)
          AND     gbh.plan_start_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     gbh.batch_id           = gmd.batch_id
          AND     gmd.line_type          = -1
          AND     gmd.item_id            = ximv.item_id
          AND     gmd.material_detail_id = mld.mov_line_id
          AND     mld.lot_id             = ilm.lot_id
          AND     gbh.routing_id         = grb.routing_id
          AND     grb.attribute9         = mil.segment1      -- 納品場所
          AND     mld.document_type_code = '40'
          AND     mld.record_type_code   = '10'
          AND     itp.line_id            = gmd.material_detail_id
          AND     itp.item_id            = gmd.item_id
          AND     itp.lot_id             = mld.lot_id
          AND     itp.doc_type           = 'PROD'
          AND     itp.delete_mark        = 0
          AND     itp.completed_ind      = 0)
          +
         (SELECT  NVL(SUM(mld.actual_quantity), 0)
          FROM    mtl_system_items_b    msib,   -- 品目マスタ
                  po_lines_all          pla,    -- 発注明細
                  po_headers_all        pha,    -- 発注ヘッダ
                  xxinv_mov_lot_details mld     -- 移動ロット詳細（アドオン）
          WHERE   msib.segment1          = ximv.item_no
          AND     msib.organization_id   = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'))
          AND     msib.inventory_item_id = pla.item_id
          AND     pla.attribute13        = 'N'
          AND     pla.cancel_flag        = 'N'
          AND     pla.attribute12        = mil.segment1     -- 相手先在庫入庫先
          AND     pla.po_header_id       = pha.po_header_id
          AND     pha.org_id = FND_PROFILE.VALUE('ORG_ID')
          AND     pha.attribute1        IN ('20','25')
          AND     pha.attribute4        <= FND_PROFILE.VALUE('XXCMN_MAX_DATE') -- 納入日
          AND     pla.po_line_id         = mld.mov_line_id
          AND     mld.lot_id             = ilm.lot_id
          AND     mld.document_type_code = '50'
          AND     mld.record_type_code   = '10')
         ) outbound_qty,                        -- 出庫予定数
         ilm.created_by created_by,                               -- 作成者
         ilm.creation_date creation_date,                         -- 作成日
         ilm.last_updated_by last_updated_by,                     -- 最終更新者
         ilm.last_update_date last_update_date,                   -- 最終更新日
         ilm.last_update_login last_update_login,                 -- 最終更新ログイン
         NULL                  ili_last_update_date,              -- OPM手持数量 最終更新日(使用しないのでNULL)
         mil.attribute5 frequent_whse                             -- 代表倉庫
  FROM   xxcmn_item_mst_v           ximv,    -- OPM品目マスタ情報VIEW
         ic_lots_mst                ilm,     -- OPMロットマスタ
         mtl_item_locations         mil,
         ic_whse_mst                iwm,
         gmi_item_categories        gic_s,
         mtl_categories_b           mcb_s,
         gmi_item_categories        gic_h,
         mtl_categories_b           mcb_h,
         (SELECT  mrih.ship_to_locat_id       location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.comp_actual_flg    = 'N'
          AND     mrih.status            IN ('05','06')
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '30'
          UNION
          SELECT  mrih.shipped_locat_id       location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.comp_actual_flg    = 'N'
          AND     mrih.status            IN ('04','06')
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '20'
          UNION
          SELECT  oha.deliver_from_id         location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
                  xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
                  xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
                  oe_transaction_types_all   otta  -- 受注タイプ
          WHERE   oha.req_status            = '04'
          AND     oha.actual_confirm_class  = 'N'
          AND     oha.latest_external_flag  = 'Y'
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = 'N'
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.document_type_code    = '10'
          AND     mld.record_type_code      = '20'
          AND     otta.attribute1           IN ('1','3')
          AND     otta.transaction_type_id  = oha.order_type_id
          UNION
          SELECT  oha.deliver_from_id         location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
                  xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
                  xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
                  oe_transaction_types_all  otta   -- 受注タイプ
          WHERE   oha.req_status            = '08'
          AND     oha.actual_confirm_class  = 'N'
          AND     oha.latest_external_flag  = 'Y'
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = 'N'
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.document_type_code    = '30'
          AND     mld.record_type_code      = '20'
          AND     otta.attribute1           = '2'
          AND     otta.transaction_type_id  = oha.order_type_id
          UNION
          SELECT  mil2.inventory_location_id  location_id
                 ,iimb.item_id                item_id
                 ,ilm.lot_id                  lot_id
          FROM    mtl_system_items_b msib,
                  ic_item_mst_b      iimb,
                  po_lines_all       pla,
                  po_headers_all     pha,
                  ic_lots_mst        ilm,
                  mtl_item_locations mil2
          WHERE   iimb.item_no           = msib.segment1
          AND     msib.organization_id   = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'))
          AND     msib.inventory_item_id = pla.item_id
          AND     pla.attribute13        = 'N'
          AND     pla.cancel_flag        = 'N'
          AND     pla.attribute1         = ilm.lot_no
          AND     pla.po_header_id       = pha.po_header_id
          AND     pha.org_id = FND_PROFILE.VALUE('ORG_ID')
          AND     pha.attribute1        IN ('20','25')
          AND     pha.attribute5         = mil2.segment1
          AND     pha.attribute4        <= FND_PROFILE.VALUE('XXCMN_MAX_DATE') -- 納入日
          UNION
          SELECT  mrih.ship_to_locat_id       location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.comp_actual_flg    = 'N'
          AND     mrih.status IN ('02','03')
          AND     mrih.schedule_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '10'
          UNION
          SELECT  mrih.ship_to_locat_id       location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.comp_actual_flg    = 'N'
          AND     mrih.status             = '04'
          AND     mrih.schedule_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.actual_arrival_date  IS NULL
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '20'
          UNION
          SELECT  mrih.ship_to_locat_id       location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.comp_actual_flg    = 'N'
          AND     mrih.status             = '04'
          AND     mrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.actual_arrival_date  IS NOT NULL
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '20'
          UNION
          SELECT  mil2.inventory_location_id   location_id
                 ,gmd.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    gme_batch_header      gbh, -- 生産バッチ
                  gme_material_details  gmd, -- 生産原料詳細
                  ic_tran_pnd           itp, -- OPM保留在庫トランザクション
                  xxinv_mov_lot_details mld, -- 移動ロット詳細（アドオン）
                  gmd_routings_b        grb, -- 工順マスタ
                  mtl_item_locations    mil2
          WHERE   gbh.batch_status      IN (1,2)
          AND     gbh.plan_start_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     gbh.batch_id           = gmd.batch_id
          AND     gmd.line_type         IN (1,2)
          AND     gmd.material_detail_id = itp.line_id
          AND     itp.completed_ind      = 0
          AND     itp.doc_type           = 'PROD'
          AND     itp.delete_mark        = 0
          AND     gmd.material_detail_id = mld.mov_line_id
          AND     mld.document_type_code = '40'
          AND     mld.record_type_code   = '10'
          AND     gbh.routing_id         = grb.routing_id
          AND     grb.attribute9         = mil2.segment1      -- 納品場所
          UNION
          SELECT  mrih.shipped_locat_id       location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.comp_actual_flg    = 'N'
          AND     mrih.status IN ('02','03')
          AND     mrih.schedule_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '10'
          UNION
          SELECT  mrih.shipped_locat_id       location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.comp_actual_flg    = 'N'
          AND     mrih.status             = '05'
          AND     mrih.schedule_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.actual_ship_date  IS NULL
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '30'
          UNION
          SELECT  mrih.shipped_locat_id       location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.comp_actual_flg    = 'N'
          AND     mrih.status             = '05'
          AND     mrih.actual_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     mrih.actual_ship_date  IS NOT NULL
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '30'
          UNION
          SELECT  oha.deliver_from_id         location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
                  xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
                  xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
                  oe_transaction_types_all   otta  -- 受注タイプ
          WHERE   oha.req_status            = '03'
          AND     oha.actual_confirm_class  = 'N'
          AND     oha.latest_external_flag  = 'Y'
          AND     oha.schedule_ship_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = 'N'
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.document_type_code    = '10'
          AND     mld.record_type_code      = '10'
          AND     otta.attribute1           = '1'
          AND     otta.transaction_type_id  = oha.order_type_id
          UNION
          SELECT  oha.deliver_from_id         location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxwsh_order_headers_all    oha,  -- 受注ヘッダ（アドオン）
                  xxwsh_order_lines_all      ola,  -- 受注明細（アドオン）
                  xxinv_mov_lot_details      mld,  -- 移動ロット詳細（アドオン）
                  oe_transaction_types_all  otta   -- 受注タイプ
          WHERE   oha.req_status            = '07'
          AND     oha.actual_confirm_class  = 'N'
          AND     oha.latest_external_flag  = 'Y'
          AND     oha.schedule_ship_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     oha.order_header_id       = ola.order_header_id
          AND     ola.delete_flag           = 'N'
          AND     ola.order_line_id         = mld.mov_line_id
          AND     mld.document_type_code    = '30'
          AND     mld.record_type_code      = '10'
          AND     otta.attribute1           = '2'
          AND     otta.transaction_type_id  = oha.order_type_id
          UNION
          SELECT  mil2.inventory_location_id   location_id
                 ,gmd.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    gme_batch_header      gbh, -- 生産バッチ
                  gme_material_details  gmd, -- 生産原料詳細
                  xxinv_mov_lot_details mld, -- 移動ロット詳細（アドオン）
                  gmd_routings_b        grb, -- 工順マスタ
                  ic_tran_pnd           itp, -- 保留在庫トランザクション
                  mtl_item_locations    mil2
          WHERE   gbh.batch_status      IN (1,2)
          AND     gbh.plan_start_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
          AND     gbh.batch_id           = gmd.batch_id
          AND     gmd.line_type          = -1
          AND     gmd.material_detail_id = mld.mov_line_id
          AND     gbh.routing_id         = grb.routing_id
          AND     grb.attribute9         = mil2.segment1      -- 納品場所
          AND     mld.document_type_code = '40'
          AND     mld.record_type_code   = '10'
          AND     itp.line_id            = gmd.material_detail_id
          AND     itp.item_id            = gmd.item_id
          AND     itp.lot_id             = mld.lot_id
          AND     itp.doc_type           = 'PROD'
          AND     itp.delete_mark        = 0
          AND     itp.completed_ind      = 0
          UNION
          SELECT  mil2.inventory_location_id  location_id
                 ,iimb.item_id                item_id
                 ,mld.lot_id                  lot_id
          FROM    mtl_system_items_b    msib,   -- 品目マスタ
                  ic_item_mst_b         iimb,
                  po_lines_all          pla,    -- 発注明細
                  po_headers_all        pha,    -- 発注ヘッダ
                  xxinv_mov_lot_details mld,    -- 移動ロット詳細（アドオン）
                  mtl_item_locations    mil2
          WHERE   iimb.item_no           = msib.segment1
          AND     msib.organization_id   = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'))
          AND     msib.inventory_item_id = pla.item_id
          AND     pla.attribute13        = 'N'
          AND     pla.cancel_flag        = 'N'
          AND     pla.attribute12        = mil2.segment1     -- 相手先在庫入庫先
          AND     pla.po_header_id       = pha.po_header_id
          AND     pha.org_id = FND_PROFILE.VALUE('ORG_ID')
          AND     pha.attribute1        IN ('20','25')
          AND     pha.attribute4        <= FND_PROFILE.VALUE('XXCMN_MAX_DATE') -- 納入日
          AND     pla.po_line_id         = mld.mov_line_id
          AND     mld.document_type_code = '50'
          AND     mld.record_type_code   = '10'
          UNION
          SELECT  mrih.ship_to_locat_id       location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.comp_actual_flg    = 'Y'
          AND     mrih.correct_actual_flg = 'Y'
          AND     mrih.status             = '06'
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '30'
          UNION
          SELECT  mrih.shipped_locat_id       location_id
                 ,mld.item_id                 item_id
                 ,mld.lot_id                  lot_id
          FROM    xxinv_mov_req_instr_headers mrih,   -- 移動依頼/指示ヘッダ（アドオン）
                  xxinv_mov_req_instr_lines   mril,   -- 移動依頼/指示明細（アドオン）
                  xxinv_mov_lot_details       mld     -- 移動ロット詳細（アドオン）
          WHERE   mrih.comp_actual_flg    = 'Y'
          AND     mrih.correct_actual_flg = 'Y'
          AND     mrih.status             = '06'
          AND     mrih.mov_hdr_id         = mril.mov_hdr_id
          AND     mril.mov_line_id        = mld.mov_line_id
          AND     mril.delete_flg         = 'N'
          AND     mld.document_type_code  = '20'
          AND     mld.record_type_code    = '20') txn_main,
        (SELECT xq.qt_inspect_req_no,
                CASE
                  WHEN xq.test_date3 IS NOT NULL THEN  -- 検査日3
                    xq.qt_effect3                      -- 結果3
                  WHEN xq.test_date2 IS NOT NULL THEN  -- 検査日2
                    xq.qt_effect2                      -- 結果2
                  WHEN xq.test_date1 IS NOT NULL THEN  -- 検査日1
                    xq.qt_effect1                      -- 結果1
                  ELSE
                    NULL
                END  qt_effect
         FROM   xxwip_qt_inspection xq) xqi,    -- 品質検査依頼情報
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXCMN_L05') xlvv_xl5,
                                                -- クイックコード(仕入形態内容)
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXCMN_L06') xlvv_xl6,
                                                -- クイックコード(茶期区分内容)
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXCMN_L07') xlvv_xl7,
                                                -- クイックコード(産地内容)
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXCMN_L08') xlvv_xl8,
                                                -- クイックコード(タイプ内容)
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXCMN_L03') xlvv_xl3,
                                                -- クイックコード(生産伝票区分内容)
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXWIP_QT_STATUS') xlvv_xqs,
                                                -- クイックコード(品質結果内容)
        (SELECT xlvv.lookup_code,
                xlvv.meaning
         FROM   xxcmn_lookup_values_v xlvv
         WHERE  xlvv.lookup_type = 'XXCMN_LOT_STATUS') xlvv_xls,
                                                -- クイックコード(ロットステータス)
         xxcmn_vendors_v            xvv,        -- 仕入先情報
        (SELECT grb.routing_no,
                grt.routing_desc
         FROM   gmd_routings_b  grb,            -- 工順マスタ
                gmd_routings_tl grt             -- 工順マスタ名称
         WHERE  grb.routing_id = grt.routing_id
         AND    grt.language   = 'JA') gr
  WHERE  ximv.item_id            = ilm.item_id
  AND    ximv.item_id            = gic_s.item_id
  AND    gic_s.category_id       = mcb_s.category_id
  AND    gic_s.category_set_id   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_s.segment1          = '5'
  AND    ximv.item_id            = gic_h.item_id
  AND    gic_h.category_id       = mcb_h.category_id
  AND    gic_h.category_set_id   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND    mcb_h.segment1          = '2'
  -- ロット管理品
  AND    ximv.lot_ctl            = '1'
  AND    ilm.lot_id             <> 0
  -- ロット倉庫組合せ絞込み
  AND    (NOT EXISTS (
          SELECT  1
          FROM    ic_loct_inv ili
          WHERE   ili.item_id  = txn_main.item_id
          AND     ili.lot_id   = txn_main.lot_id
          AND     ili.location = mil.segment1
          AND     ROWNUM = 1))
  -- 品目(保管場所)と手持数量の関連付け
  AND    ximv.item_id            = txn_main.item_id
  AND    mil.inventory_location_id = txn_main.location_id
  AND    ilm.lot_id              = txn_main.lot_id
  -- 在庫組織とOPM倉庫の紐付け
  AND    iwm.mtl_organization_id = mil.organization_id
  -- 名称取得
  AND    ilm.attribute8             = xvv.segment1(+)
  AND    ilm.attribute9             = xlvv_xl5.lookup_code(+)
  AND    ilm.attribute10            = xlvv_xl6.lookup_code(+)
  AND    ilm.attribute12            = xlvv_xl7.lookup_code(+)
  AND    ilm.attribute13            = xlvv_xl8.lookup_code(+)
  AND    ilm.attribute16            = xlvv_xl3.lookup_code(+)
  AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
  AND    ilm.attribute23            = xlvv_xls.lookup_code(+)
  AND    ilm.attribute17            = gr.routing_no(+)
  AND    TO_NUMBER(ilm.attribute22) = xqi.qt_inspect_req_no(+)
  -- 抽出条件(画面検索値)
  AND    iwm.attribute1             = '0'
/
--
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ORGANIZATION_CODE IS '組織コード'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ORGANIZATION_ID IS '組織ID'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.WHSE_CODE IS '保管倉庫コード'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.WHSE_SHORT_NAME IS '保管倉庫名'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.INV_LOCT_ID IS '保管倉庫ID'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ITEM_ID IS '品目ID'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ITEM_NO IS '品目コード'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ITEM_SHORT_NAME IS '品目名'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.NUM_OF_CASES IS 'ケース入数'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LOT_NO IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LOT_ID IS 'ロットID'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.MANUFACTURE_DATE IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.EXPIRATION_DATE IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.UNIQE_SIGN IS '固有記号'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR4 IS '初回納入日'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR5 IS '最終納入日'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR6 IS '在庫入数'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR7 IS '在庫単価'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR8 IS '受払先'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.VND_SHORT_NAME IS '受払先名'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR9 IS '仕入形態'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR9_MEAN IS '仕入形態内容'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR10 IS '茶期区分'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR10_MEAN IS '茶期区分内容'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR11 IS '年度'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR12 IS '産地'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR12_MEAN IS '産地内容'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR13 IS 'タイプ'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR13_MEAN IS 'タイプ内容'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR14 IS 'ランク1'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR15 IS 'ランク2'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR19 IS 'ランク3'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR16 IS '生産伝票区分'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR16_MEAN IS '生産伝票区分内容'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR17 IS 'ラインNo'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ROUTING_DESC IS '工順摘要'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR18 IS '摘要'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LOT_STATUS IS 'ロットステータス'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LOT_MEAN IS 'ロットステータス内容'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.QT_INSPECT_REQ_NO IS '品質検査依頼情報'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.QT_INS_MEAN IS '品質結果内容'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LOCT_ONHAND IS '手持数量'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.STOCK_QTY IS '手持在庫数'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.INBOUND_QTY IS '入庫予定数'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.OUTBOUND_QTY IS '出庫予定数'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.CREATED_BY IS '作成者'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.CREATION_DATE IS '作成日'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LAST_UPDATED_BY IS '最終更新者'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LAST_UPDATE_DATE IS '最終更新日'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LAST_UPDATE_LOGIN IS '最終更新ログイン'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ILI_LAST_UPDATE_DATE IS 'OPM手持数量 最終更新日'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.FREQUENT_WHSE IS '代表倉庫'
/
