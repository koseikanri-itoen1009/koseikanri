/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_LOCT_INV_MV
 * Description     : �v��_�莝�݌Ƀ}�e���A���C�Y�h�r���[
 * Version         : 1.3
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009-05-07    1.0   SCS.Goto         �V�K�쐬(2009/04/27 XXINV540001.pkb)
 *  2009-05-14    1.1   SCS.Goto         T1_0989�Ή�
 *  2009-06-08    1.2   SCS.Goto         T1_1365�Ή�
 *  2009-06-24    1.3   SCS.Goto         ��Q:0000116�Ή�
 *
 ************************************************************************/
CREATE MATERIALIZED VIEW APPS.XXCOP_LOCT_INV_MV
--20090608_Ver1.2_T1_1365_SCS.Goto_MOD_START
--ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
--STORAGE(INITIAL 131072 NEXT 131072 MINEXTENTS 1 MAXEXTENTS 2147483645
--PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
--TABLESPACE "APPS_TS_TX_DATA"
  TABLESPACE "XXDATA2"
--20090608_Ver1.2_T1_1365_SCS.Goto_MOD_END
  BUILD IMMEDIATE
  USING INDEX
  REFRESH COMPLETE ON DEMAND START WITH SYSDATE+0 NEXT SYSDATE + 1/24/60*10
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  DISABLE QUERY REWRITE
  AS
  SELECT
    iwm.whse_code   organization_code,
    iwm.mtl_organization_id organization_id,
    mil.segment1    whse_code,
    mil.attribute12 whse_short_name,
    mil.inventory_location_id inv_loct_id,
    ximv.item_id    item_id,
    ximv.item_no    item_no,
    ximv.item_short_name item_short_name,
    NVL(ximv.num_of_cases, 1) num_of_cases,
    ilm.lot_no      lot_no,
    ilm.lot_id      lot_id,
    FND_DATE.STRING_TO_DATE(ilm.attribute1, 'YYYY/MM/DD') manufacture_date,
    FND_DATE.STRING_TO_DATE(ilm.attribute3, 'YYYY/MM/DD') expiration_date,
    ilm.attribute2  uniqe_sign,
--20090624_Ver1.3_0000116_SCS.Goto_DEL_START
--  FND_DATE.STRING_TO_DATE(ilm.attribute4, 'YYYY/MM/DD') attr4,
--  FND_DATE.STRING_TO_DATE(ilm.attribute5, 'YYYY/MM/DD') attr5,
--  TO_NUMBER(ilm.attribute6) attr6,
--  TO_NUMBER(ilm.attribute7) attr7,
--  ilm.attribute8  attr8,
--  xvv.vendor_short_name vnd_short_name,
--  ilm.attribute9  attr9,
--  xlvv_xl5.meaning attr9_mean,
--  ilm.attribute10 attr10,
--  xlvv_xl6.meaning attr10_mean,
--  ilm.attribute11 attr11,
--  ilm.attribute12 attr12,
--  xlvv_xl7.meaning attr12_mean,
--  ilm.attribute13 attr13,
--  xlvv_xl8.meaning attr13_mean,
--  ilm.attribute14 attr14,
--  ilm.attribute15 attr15,
--  ilm.attribute19 attr19,
--  ilm.attribute16 attr16,
--  xlvv_xl3.meaning attr16_mean,
--  ilm.attribute17 attr17,
--  gr.routing_desc routing_desc,
--  ilm.attribute18 attr18,
--20090624_Ver1.3_0000116_SCS.Goto_DEL_END
    ilm.attribute23 lot_status,
--20090624_Ver1.3_0000116_SCS.Goto_DEL_START
--  xlvv_xls.meaning lot_mean,
--  xqi.qt_inspect_req_no qt_inspect_req_no,
--  xlvv_xqs.meaning qt_ins_mean,
--20090624_Ver1.3_0000116_SCS.Goto_DEL_END
    ili.loct_onhand loct_onhand,
--20090624_Ver1.3_0000116_SCS.Goto_MOD_START
    0 stock_qty,
--  (
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status            IN ('05','06')
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '30')
--   -
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status            IN ('04','06')
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '20')
--   -
--  (SELECT  NVL(SUM(CASE
--           WHEN (otta.order_category_code = 'ORDER') THEN
--             NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
--           WHEN (otta.order_category_code = 'RETURN') THEN
--            (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
--           END), 0)
--   FROM    xxwsh_order_headers_all    oha,
--           xxwsh_order_lines_all      ola,
--           xxinv_mov_lot_details      mld,
--           oe_transaction_types_all   otta
--   WHERE   oha.deliver_from_id       = mil.inventory_location_id
--   AND     oha.req_status            = '04'
--   AND     oha.actual_confirm_class  = 'N'
--   AND     oha.latest_external_flag  = 'Y'
--   AND     oha.order_header_id       = ola.order_header_id
--   AND     ola.delete_flag           = 'N'
--   AND     ola.order_line_id         = mld.mov_line_id
--   AND     mld.item_id               = ximv.item_id
--   AND     mld.lot_id                = ilm.lot_id
--   AND     mld.document_type_code    = '10'
--   AND     mld.record_type_code      = '20'
--   AND     otta.attribute1           IN ('1','3')
--   AND     otta.transaction_type_id  = oha.order_type_id)
--   -
--  (SELECT  NVL(SUM(CASE
--           WHEN (otta.order_category_code = 'ORDER') THEN
--             NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
--           WHEN (otta.order_category_code = 'RETURN') THEN
--            (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
--           END), 0)
--   FROM    xxwsh_order_headers_all    oha,
--           xxwsh_order_lines_all      ola,
--           xxinv_mov_lot_details      mld,
--           oe_transaction_types_all  otta
--   WHERE   oha.deliver_from_id       = mil.inventory_location_id
--   AND     oha.req_status            = '08'
--   AND     oha.actual_confirm_class  = 'N'
--   AND     oha.latest_external_flag  = 'Y'
--   AND     oha.order_header_id       = ola.order_header_id
--   AND     ola.delete_flag           = 'N'
--   AND     ola.order_line_id         = mld.mov_line_id
--   AND     mld.item_id               = ximv.item_id
--   AND     mld.lot_id                = ilm.lot_id
--   AND     mld.document_type_code    = '30'
--   AND     mld.record_type_code      = '20'
--   AND     otta.attribute1           = '2'
--   AND     otta.transaction_type_id  = oha.order_type_id)
--   +
--   (SELECT  NVL(SUM(mld.actual_quantity), 0) - NVL(SUM(mld.before_actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'Y'
--   AND     mrih.correct_actual_flg = 'Y'
--   AND     mrih.status             = '06'
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '30')
--   +
--   (SELECT  NVL(SUM(mld.before_actual_quantity), 0) - NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'Y'
--   AND     mrih.correct_actual_flg = 'Y'
--   AND     mrih.status             = '06'
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '20')
--  )               stock_qty,
--  (
--  (SELECT  NVL(SUM(pla.quantity), 0)
--   FROM    mtl_system_items_b msib,
--           po_lines_all       pla,
--           po_headers_all     pha
--   WHERE   msib.segment1          = ximv.item_no
--   AND     msib.organization_id   = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'))
--   AND     msib.inventory_item_id = pla.item_id
--   AND     pla.attribute1         = ilm.lot_no
--   AND     pla.attribute13        = 'N'
--   AND     pla.cancel_flag        = 'N'
--   AND     pla.po_header_id       = pha.po_header_id
--   AND     pha.org_id = FND_PROFILE.VALUE('ORG_ID')
--   AND     pha.attribute1        IN ('20','25')
--   AND     pha.attribute5         = mil.segment1
--   AND     pha.attribute4        <= FND_PROFILE.VALUE('XXCMN_MAX_DATE'))
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status IN ('02','03')
--   AND     mrih.schedule_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '10')
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status             = '04'
--   AND     mrih.schedule_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.actual_arrival_date  IS NULL
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '20')
--  +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status             = '04'
--   AND     mrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.actual_arrival_date  IS NOT NULL
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '20')
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    gme_batch_header      gbh,
--           gme_material_details  gmd,
--           ic_tran_pnd           itp,
--           xxinv_mov_lot_details mld,
--           gmd_routings_b        grb
--   WHERE   gbh.batch_status      IN (1,2)
--   AND     gbh.plan_start_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     gbh.batch_id           = gmd.batch_id
--   AND     gmd.line_type         IN (1,2)
--   AND     gmd.item_id            = ximv.item_id
--   AND     gmd.material_detail_id = itp.line_id
--   AND     itp.completed_ind      = 0
--   AND     itp.doc_type           = 'PROD'
--   AND     itp.delete_mark        = 0
--   AND     itp.lot_id             = ilm.lot_id
--   AND     gmd.material_detail_id = mld.mov_line_id
--   AND     mld.document_type_code = '40'
--   AND     mld.record_type_code   = '10'
--   AND     gbh.routing_id         = grb.routing_id
--   AND     grb.attribute9         = mil.segment1)
--  ) inbound_qty,
--  (
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status IN ('02','03')
--   AND     mrih.schedule_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '10')
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status             = '05'
--   AND     mrih.schedule_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.actual_ship_date  IS NULL
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '30')
--  +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status             = '05'
--   AND     mrih.actual_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.actual_ship_date  IS NOT NULL
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '30')
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxwsh_order_headers_all    oha,
--           xxwsh_order_lines_all      ola,
--           xxinv_mov_lot_details      mld,
--           oe_transaction_types_all   otta
--   WHERE   oha.deliver_from_id       = mil.inventory_location_id
--   AND     oha.req_status            = '03'
--   AND     oha.actual_confirm_class  = 'N'
--   AND     oha.latest_external_flag  = 'Y'
--   AND     oha.schedule_ship_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     oha.order_header_id       = ola.order_header_id
--   AND     ola.delete_flag           = 'N'
--   AND     ola.order_line_id         = mld.mov_line_id
--   AND     mld.item_id               = ximv.item_id
--   AND     mld.lot_id                = ilm.lot_id
--   AND     mld.document_type_code    = '10'
--   AND     mld.record_type_code      = '10'
--   AND     otta.attribute1           = '1'
--   AND     otta.transaction_type_id  = oha.order_type_id)
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxwsh_order_headers_all    oha,
--           xxwsh_order_lines_all      ola,
--           xxinv_mov_lot_details      mld,
--           oe_transaction_types_all  otta
--   WHERE   oha.deliver_from_id       = mil.inventory_location_id
--   AND     oha.req_status            = '07'
--   AND     oha.actual_confirm_class  = 'N'
--   AND     oha.latest_external_flag  = 'Y'
--   AND     oha.schedule_ship_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     oha.order_header_id       = ola.order_header_id
--   AND     ola.delete_flag           = 'N'
--   AND     ola.order_line_id         = mld.mov_line_id
--   AND     mld.item_id               = ximv.item_id
--   AND     mld.lot_id                = ilm.lot_id
--   AND     mld.document_type_code    = '30'
--   AND     mld.record_type_code      = '10'
--   AND     otta.attribute1           = '2'
--   AND     otta.transaction_type_id  = oha.order_type_id)
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    gme_batch_header      gbh,
--           gme_material_details  gmd,
--           xxinv_mov_lot_details mld,
--           gmd_routings_b        grb,
--           ic_tran_pnd           itp
--   WHERE   gbh.batch_status      IN (1,2)
--   AND     gbh.plan_start_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     gbh.batch_id           = gmd.batch_id
--   AND     gmd.line_type          = -1
--   AND     gmd.item_id            = ximv.item_id
--   AND     gmd.material_detail_id = mld.mov_line_id
--   AND     mld.lot_id             = ilm.lot_id
--   AND     gbh.routing_id         = grb.routing_id
--   AND     grb.attribute9         = mil.segment1
--   AND     mld.document_type_code = '40'
--   AND     mld.record_type_code   = '10'
--   AND     itp.line_id            = gmd.material_detail_id
--   AND     itp.item_id            = gmd.item_id
--   AND     itp.lot_id             = mld.lot_id
--   AND     itp.doc_type           = 'PROD'
--   AND     itp.delete_mark        = 0
--   AND     itp.completed_ind      = 0)
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    mtl_system_items_b    msib,
--           po_lines_all          pla,
--           po_headers_all        pha,
--           xxinv_mov_lot_details mld
--   WHERE   msib.segment1          = ximv.item_no
--   AND     msib.organization_id   = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'))
--   AND     msib.inventory_item_id = pla.item_id
--   AND     pla.attribute13        = 'N'
--   AND     pla.cancel_flag        = 'N'
--   AND     pla.attribute12        = mil.segment1
--   AND     pla.po_header_id       = pha.po_header_id
--   AND     pha.org_id = FND_PROFILE.VALUE('ORG_ID')
--   AND     pha.attribute1        IN ('20','25')
--   AND     pha.attribute4        <= FND_PROFILE.VALUE('XXCMN_MAX_DATE')
--   AND     pla.po_line_id         = mld.mov_line_id
--   AND     mld.lot_id             = ilm.lot_id
--   AND     mld.document_type_code = '50'
--   AND     mld.record_type_code   = '10')
--  ) outbound_qty,
--  ilm.created_by created_by,
--  ilm.creation_date creation_date,
--  ilm.last_updated_by last_updated_by,
--  ilm.last_update_date last_update_date,
--  ilm.last_update_login last_update_login,
--  ili.last_update_date  ili_last_update_date,
--20090624_Ver1.3_0000116_SCS.Goto_MOD_END
    mil.attribute5 frequent_whse
  FROM
    xxcmn_item_mst_v           ximv,
    ic_lots_mst                ilm,
    mtl_item_locations         mil,
    ic_whse_mst                iwm,
    gmi_item_categories        gic_s,
    mtl_categories_b           mcb_s,
    gmi_item_categories        gic_h,
    mtl_categories_b           mcb_h,
--20090624_Ver1.3_0000116_SCS.Goto_MOD_START
    ic_loct_inv                ili
--  ic_loct_inv                ili,
--  (SELECT xq.qt_inspect_req_no,
--          CASE
--            WHEN xq.test_date3 IS NOT NULL THEN
--              xq.qt_effect3
--            WHEN xq.test_date2 IS NOT NULL THEN
--              xq.qt_effect2
--            WHEN xq.test_date1 IS NOT NULL THEN
--              xq.qt_effect1
--            ELSE
--              NULL
--          END  qt_effect
--   FROM   xxwip_qt_inspection xq) xqi,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXCMN_L05') xlvv_xl5,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXCMN_L06') xlvv_xl6,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXCMN_L07') xlvv_xl7,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXCMN_L08') xlvv_xl8,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXCMN_L03') xlvv_xl3,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXWIP_QT_STATUS') xlvv_xqs,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXCMN_LOT_STATUS') xlvv_xls,
--   xxcmn_vendors_v            xvv,
--  (SELECT grb.routing_no,
--          grt.routing_desc
--   FROM   gmd_routings_b  grb,
--          gmd_routings_tl grt
--   WHERE  grb.routing_id = grt.routing_id
--   AND    grt.language   = 'JA') gr
--20090624_Ver1.3_0000116_SCS.Goto_MOD_END
  WHERE  ximv.item_id            = ilm.item_id
  AND    ximv.item_id            = gic_s.item_id
  AND    gic_s.category_id       = mcb_s.category_id
  AND    gic_s.category_set_id   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_s.segment1          = '5'
  AND    ximv.item_id            = gic_h.item_id
  AND    gic_h.category_id       = mcb_h.category_id
  AND    gic_h.category_set_id   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND    mcb_h.segment1          = '2'
  AND    ximv.lot_ctl            = '1'
  AND    ilm.lot_id             <> 0
  AND    ximv.item_id            = ili.item_id
  AND    mil.segment1            = ili.location
  AND    ilm.lot_id              = ili.lot_id
  AND    iwm.mtl_organization_id = mil.organization_id
--20090624_Ver1.3_0000116_SCS.Goto_MOD_START
--AND    ilm.attribute8             = xvv.segment1(+)
--AND    ilm.attribute9             = xlvv_xl5.lookup_code(+)
--AND    ilm.attribute10            = xlvv_xl6.lookup_code(+)
--AND    ilm.attribute12            = xlvv_xl7.lookup_code(+)
--AND    ilm.attribute13            = xlvv_xl8.lookup_code(+)
--AND    ilm.attribute16            = xlvv_xl3.lookup_code(+)
--AND    xqi.qt_effect              = xlvv_xqs.lookup_code(+)
--AND    ilm.attribute23            = xlvv_xls.lookup_code(+)
--AND    ilm.attribute17            = gr.routing_no(+)
--AND    TO_NUMBER(ilm.attribute22) = xqi.qt_inspect_req_no(+)
--20090624_Ver1.3_0000116_SCS.Goto_MOD_END
  AND    iwm.attribute1             = '0'
  UNION ALL
  SELECT
    iwm.whse_code   organization_code,
    iwm.mtl_organization_id organization_id,
    mil.segment1    whse_code,
    mil.attribute12 whse_short_name,
    mil.inventory_location_id inv_loct_id,
    ximv.item_id    item_id,
    ximv.item_no    item_no,
    ximv.item_short_name item_short_name,
    NVL(ximv.num_of_cases, 1) num_of_cases,
    ilm.lot_no      lot_no,
    ilm.lot_id      lot_id,
    FND_DATE.STRING_TO_DATE(ilm.attribute1, 'YYYY/MM/DD') manufacture_date,
    FND_DATE.STRING_TO_DATE(ilm.attribute3, 'YYYY/MM/DD') expiration_date,
    ilm.attribute2  uniqe_sign,
--20090624_Ver1.3_0000116_SCS.Goto_DEL_START
--  FND_DATE.STRING_TO_DATE(ilm.attribute4, 'YYYY/MM/DD') attr4,
--  FND_DATE.STRING_TO_DATE(ilm.attribute5, 'YYYY/MM/DD') attr5,
--  TO_NUMBER(ilm.attribute6) attr6,
--  TO_NUMBER(ilm.attribute7) attr7,
--  ilm.attribute8  attr8,
--  xvv.vendor_short_name vnd_short_name,
--  ilm.attribute9  attr9,
--  xlvv_xl5.meaning attr9_mean,
--  ilm.attribute10 attr10,
--  xlvv_xl6.meaning attr10_mean,
--  ilm.attribute11 attr11,
--  ilm.attribute12 attr12,
--  xlvv_xl7.meaning attr12_mean,
--  ilm.attribute13 attr13,
--  xlvv_xl8.meaning attr13_mean,
--  ilm.attribute14 attr14,
--  ilm.attribute15 attr15,
--  ilm.attribute19 attr19,
--  ilm.attribute16 attr16,
--  xlvv_xl3.meaning attr16_mean,
--  ilm.attribute17 attr17,
--  gr.routing_desc routing_desc,
--  ilm.attribute18 attr18,
--20090624_Ver1.3_0000116_SCS.Goto_DEL_END
    ilm.attribute23 lot_status,
--20090624_Ver1.3_0000116_SCS.Goto_DEL_START
--  xlvv_xls.meaning lot_mean,
--  xqi.qt_inspect_req_no qt_inspect_req_no,
--  xlvv_xqs.meaning qt_ins_mean,
--20090624_Ver1.3_0000116_SCS.Goto_DEL_END
    0 loct_onhand,
    (
    (SELECT  NVL(SUM(mld.actual_quantity), 0)
     FROM    xxinv_mov_req_instr_headers mrih,
             xxinv_mov_req_instr_lines   mril,
             xxinv_mov_lot_details       mld
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
     FROM    xxinv_mov_req_instr_headers mrih,
             xxinv_mov_req_instr_lines   mril,
             xxinv_mov_lot_details       mld
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
     FROM    xxwsh_order_headers_all    oha,
             xxwsh_order_lines_all      ola,
             xxinv_mov_lot_details      mld,
             oe_transaction_types_all   otta
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
     FROM    xxwsh_order_headers_all    oha,
             xxwsh_order_lines_all      ola,
             xxinv_mov_lot_details      mld,
             oe_transaction_types_all  otta
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
     FROM    xxinv_mov_req_instr_headers mrih,
             xxinv_mov_req_instr_lines   mril,
             xxinv_mov_lot_details       mld
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
     FROM    xxinv_mov_req_instr_headers mrih,
             xxinv_mov_req_instr_lines   mril,
             xxinv_mov_lot_details       mld
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
    )               stock_qty,
--20090624_Ver1.3_0000116_SCS.Goto_DEL_START
--  (
--  (SELECT  NVL(SUM(pla.quantity), 0)
--   FROM    mtl_system_items_b msib,
--           po_lines_all       pla,
--           po_headers_all     pha
--   WHERE   msib.segment1          = ximv.item_no
--   AND     msib.organization_id   = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'))
--   AND     msib.inventory_item_id = pla.item_id
--   AND     pla.attribute1         = ilm.lot_no
--   AND     pla.attribute13        = 'N'
--   AND     pla.cancel_flag        = 'N'
--   AND     pla.po_header_id       = pha.po_header_id
--   AND     pha.org_id = FND_PROFILE.VALUE('ORG_ID')
--   AND     pha.attribute1        IN ('20','25')
--   AND     pha.attribute5         = mil.segment1
--   AND     pha.attribute4        <= FND_PROFILE.VALUE('XXCMN_MAX_DATE'))
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status IN ('02','03')
--   AND     mrih.schedule_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '10')
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status             = '04'
--   AND     mrih.schedule_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.actual_arrival_date  IS NULL
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '20')
--  +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.ship_to_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status             = '04'
--   AND     mrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.actual_arrival_date  IS NOT NULL
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '20')
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    gme_batch_header      gbh,
--           gme_material_details  gmd,
--           ic_tran_pnd           itp,
--           xxinv_mov_lot_details mld,
--           gmd_routings_b        grb
--   WHERE   gbh.batch_status      IN (1,2)
--   AND     gbh.plan_start_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     gbh.batch_id           = gmd.batch_id
--   AND     gmd.line_type         IN (1,2)
--   AND     gmd.item_id            = ximv.item_id
--   AND     gmd.material_detail_id = itp.line_id
--   AND     itp.completed_ind      = 0
--   AND     itp.doc_type           = 'PROD'
--   AND     itp.delete_mark        = 0
--   AND     itp.lot_id             = ilm.lot_id
--   AND     gmd.material_detail_id = mld.mov_line_id
--   AND     mld.document_type_code = '40'
--   AND     mld.record_type_code   = '10'
--   AND     gbh.routing_id         = grb.routing_id
--   AND     grb.attribute9         = mil.segment1)
--  ) inbound_qty,
--  (
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status IN ('02','03')
--   AND     mrih.schedule_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '10')
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status             = '05'
--   AND     mrih.schedule_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.actual_ship_date  IS NULL
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '30')
--  +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.shipped_locat_id   = mil.inventory_location_id
--   AND     mrih.comp_actual_flg    = 'N'
--   AND     mrih.status             = '05'
--   AND     mrih.actual_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.actual_ship_date  IS NOT NULL
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.item_id             = ximv.item_id
--   AND     mld.lot_id              = ilm.lot_id
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '30')
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxwsh_order_headers_all    oha,
--           xxwsh_order_lines_all      ola,
--           xxinv_mov_lot_details      mld,
--           oe_transaction_types_all   otta
--   WHERE   oha.deliver_from_id       = mil.inventory_location_id
--   AND     oha.req_status            = '03'
--   AND     oha.actual_confirm_class  = 'N'
--   AND     oha.latest_external_flag  = 'Y'
--   AND     oha.schedule_ship_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     oha.order_header_id       = ola.order_header_id
--   AND     ola.delete_flag           = 'N'
--   AND     ola.order_line_id         = mld.mov_line_id
--   AND     mld.item_id               = ximv.item_id
--   AND     mld.lot_id                = ilm.lot_id
--   AND     mld.document_type_code    = '10'
--   AND     mld.record_type_code      = '10'
--   AND     otta.attribute1           = '1'
--   AND     otta.transaction_type_id  = oha.order_type_id)
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    xxwsh_order_headers_all    oha,
--           xxwsh_order_lines_all      ola,
--           xxinv_mov_lot_details      mld,
--           oe_transaction_types_all  otta
--   WHERE   oha.deliver_from_id       = mil.inventory_location_id
--   AND     oha.req_status            = '07'
--   AND     oha.actual_confirm_class  = 'N'
--   AND     oha.latest_external_flag  = 'Y'
--   AND     oha.schedule_ship_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     oha.order_header_id       = ola.order_header_id
--   AND     ola.delete_flag           = 'N'
--   AND     ola.order_line_id         = mld.mov_line_id
--   AND     mld.item_id               = ximv.item_id
--   AND     mld.lot_id                = ilm.lot_id
--   AND     mld.document_type_code    = '30'
--   AND     mld.record_type_code      = '10'
--   AND     otta.attribute1           = '2'
--   AND     otta.transaction_type_id  = oha.order_type_id)
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    gme_batch_header      gbh,
--           gme_material_details  gmd,
--           xxinv_mov_lot_details mld,
--           gmd_routings_b        grb,
--           ic_tran_pnd           itp
--   WHERE   gbh.batch_status      IN (1,2)
--   AND     gbh.plan_start_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     gbh.batch_id           = gmd.batch_id
--   AND     gmd.line_type          = -1
--   AND     gmd.item_id            = ximv.item_id
--   AND     gmd.material_detail_id = mld.mov_line_id
--   AND     mld.lot_id             = ilm.lot_id
--   AND     gbh.routing_id         = grb.routing_id
--   AND     grb.attribute9         = mil.segment1
--   AND     mld.document_type_code = '40'
--   AND     mld.record_type_code   = '10'
--   AND     itp.line_id            = gmd.material_detail_id
--   AND     itp.item_id            = gmd.item_id
--   AND     itp.lot_id             = mld.lot_id
--   AND     itp.doc_type           = 'PROD'
--   AND     itp.delete_mark        = 0
--   AND     itp.completed_ind      = 0)
--   +
--  (SELECT  NVL(SUM(mld.actual_quantity), 0)
--   FROM    mtl_system_items_b    msib,
--           po_lines_all          pla,
--           po_headers_all        pha,
--           xxinv_mov_lot_details mld
--   WHERE   msib.segment1          = ximv.item_no
--   AND     msib.organization_id   = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'))
--   AND     msib.inventory_item_id = pla.item_id
--   AND     pla.attribute13        = 'N'
--   AND     pla.cancel_flag        = 'N'
--   AND     pla.attribute12        = mil.segment1
--   AND     pla.po_header_id       = pha.po_header_id
--   AND     pha.org_id = FND_PROFILE.VALUE('ORG_ID')
--   AND     pha.attribute1        IN ('20','25')
--   AND     pha.attribute4        <= FND_PROFILE.VALUE('XXCMN_MAX_DATE')
--   AND     pla.po_line_id         = mld.mov_line_id
--   AND     mld.lot_id             = ilm.lot_id
--   AND     mld.document_type_code = '50'
--   AND     mld.record_type_code   = '10')
--  ) outbound_qty,
--  ilm.created_by created_by,
--  ilm.creation_date creation_date,
--  ilm.last_updated_by last_updated_by,
--  ilm.last_update_date last_update_date,
--  ilm.last_update_login last_update_login,
--  NULL                  ili_last_update_date,
--20090624_Ver1.3_0000116_SCS.Goto_DEL_END
    mil.attribute5 frequent_whse
  FROM
    xxcmn_item_mst_v           ximv,
    ic_lots_mst                ilm,
    mtl_item_locations         mil,
    ic_whse_mst                iwm,
    gmi_item_categories        gic_s,
    mtl_categories_b           mcb_s,
    gmi_item_categories        gic_h,
    mtl_categories_b           mcb_h,
    (SELECT  mrih.ship_to_locat_id       location_id
            ,mld.item_id                 item_id
            ,mld.lot_id                  lot_id
     FROM    xxinv_mov_req_instr_headers mrih,
             xxinv_mov_req_instr_lines   mril,
             xxinv_mov_lot_details       mld
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
     FROM    xxinv_mov_req_instr_headers mrih,
             xxinv_mov_req_instr_lines   mril,
             xxinv_mov_lot_details       mld
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
     FROM    xxwsh_order_headers_all    oha,
             xxwsh_order_lines_all      ola,
             xxinv_mov_lot_details      mld,
             oe_transaction_types_all   otta
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
     FROM    xxwsh_order_headers_all    oha,
             xxwsh_order_lines_all      ola,
             xxinv_mov_lot_details      mld,
             oe_transaction_types_all  otta
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
--20090624_Ver1.3_0000116_SCS.Goto_DEL_START
--   UNION
--   SELECT  mil2.inventory_location_id  location_id
--          ,iimb.item_id                item_id
--          ,ilm.lot_id                  lot_id
--   FROM    mtl_system_items_b msib,
--           ic_item_mst_b      iimb,
--           po_lines_all       pla,
--           po_headers_all     pha,
--           ic_lots_mst        ilm,
--           mtl_item_locations mil2
--   WHERE   iimb.item_no           = msib.segment1
--   AND     msib.organization_id   = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'))
--   AND     msib.inventory_item_id = pla.item_id
--   AND     pla.attribute13        = 'N'
--   AND     pla.cancel_flag        = 'N'
--   AND     pla.attribute1         = ilm.lot_no
--   AND     pla.po_header_id       = pha.po_header_id
--   AND     pha.org_id = FND_PROFILE.VALUE('ORG_ID')
--   AND     pha.attribute1        IN ('20','25')
--   AND     pha.attribute5         = mil2.segment1
--   AND     pha.attribute4        <= FND_PROFILE.VALUE('XXCMN_MAX_DATE')
--   UNION
--   SELECT  mrih.ship_to_locat_id       location_id
--          ,mld.item_id                 item_id
--          ,mld.lot_id                  lot_id
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.comp_actual_flg    = 'N'
--   AND     mrih.status IN ('02','03')
--   AND     mrih.schedule_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '10'
--   UNION
--   SELECT  mrih.ship_to_locat_id       location_id
--          ,mld.item_id                 item_id
--          ,mld.lot_id                  lot_id
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.comp_actual_flg    = 'N'
--   AND     mrih.status             = '04'
--   AND     mrih.schedule_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.actual_arrival_date  IS NULL
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '20'
--   UNION
--   SELECT  mrih.ship_to_locat_id       location_id
--          ,mld.item_id                 item_id
--          ,mld.lot_id                  lot_id
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.comp_actual_flg    = 'N'
--   AND     mrih.status             = '04'
--   AND     mrih.actual_arrival_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.actual_arrival_date  IS NOT NULL
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '20'
--   UNION
--   SELECT  mil2.inventory_location_id   location_id
--          ,gmd.item_id                 item_id
--          ,mld.lot_id                  lot_id
--   FROM    gme_batch_header      gbh,
--           gme_material_details  gmd,
--           ic_tran_pnd           itp,
--           xxinv_mov_lot_details mld,
--           gmd_routings_b        grb,
--           mtl_item_locations    mil2
--   WHERE   gbh.batch_status      IN (1,2)
--   AND     gbh.plan_start_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     gbh.batch_id           = gmd.batch_id
--   AND     gmd.line_type         IN (1,2)
--   AND     gmd.material_detail_id = itp.line_id
--   AND     itp.completed_ind      = 0
--   AND     itp.doc_type           = 'PROD'
--   AND     itp.delete_mark        = 0
--   AND     gmd.material_detail_id = mld.mov_line_id
--   AND     mld.document_type_code = '40'
--   AND     mld.record_type_code   = '10'
--   AND     gbh.routing_id         = grb.routing_id
--   AND     grb.attribute9         = mil2.segment1
--   UNION
--   SELECT  mrih.shipped_locat_id       location_id
--          ,mld.item_id                 item_id
--          ,mld.lot_id                  lot_id
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.comp_actual_flg    = 'N'
--   AND     mrih.status IN ('02','03')
--   AND     mrih.schedule_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '10'
--   UNION
--   SELECT  mrih.shipped_locat_id       location_id
--          ,mld.item_id                 item_id
--          ,mld.lot_id                  lot_id
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.comp_actual_flg    = 'N'
--   AND     mrih.status             = '05'
--   AND     mrih.schedule_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.actual_ship_date  IS NULL
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '30'
--   UNION
--   SELECT  mrih.shipped_locat_id       location_id
--          ,mld.item_id                 item_id
--          ,mld.lot_id                  lot_id
--   FROM    xxinv_mov_req_instr_headers mrih,
--           xxinv_mov_req_instr_lines   mril,
--           xxinv_mov_lot_details       mld
--   WHERE   mrih.comp_actual_flg    = 'N'
--   AND     mrih.status             = '05'
--   AND     mrih.actual_ship_date  <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     mrih.actual_ship_date  IS NOT NULL
--   AND     mrih.mov_hdr_id         = mril.mov_hdr_id
--   AND     mril.mov_line_id        = mld.mov_line_id
--   AND     mril.delete_flg         = 'N'
--   AND     mld.document_type_code  = '20'
--   AND     mld.record_type_code    = '30'
--   UNION
--   SELECT  oha.deliver_from_id         location_id
--          ,mld.item_id                 item_id
--          ,mld.lot_id                  lot_id
--   FROM    xxwsh_order_headers_all    oha,
--           xxwsh_order_lines_all      ola,
--           xxinv_mov_lot_details      mld,
--           oe_transaction_types_all   otta
--   WHERE   oha.req_status            = '03'
--   AND     oha.actual_confirm_class  = 'N'
--   AND     oha.latest_external_flag  = 'Y'
--   AND     oha.schedule_ship_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     oha.order_header_id       = ola.order_header_id
--   AND     ola.delete_flag           = 'N'
--   AND     ola.order_line_id         = mld.mov_line_id
--   AND     mld.document_type_code    = '10'
--   AND     mld.record_type_code      = '10'
--   AND     otta.attribute1           = '1'
--   AND     otta.transaction_type_id  = oha.order_type_id
--   UNION
--   SELECT  oha.deliver_from_id         location_id
--          ,mld.item_id                 item_id
--          ,mld.lot_id                  lot_id
--   FROM    xxwsh_order_headers_all    oha,
--           xxwsh_order_lines_all      ola,
--           xxinv_mov_lot_details      mld,
--           oe_transaction_types_all  otta
--   WHERE   oha.req_status            = '07'
--   AND     oha.actual_confirm_class  = 'N'
--   AND     oha.latest_external_flag  = 'Y'
--   AND     oha.schedule_ship_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     oha.order_header_id       = ola.order_header_id
--   AND     ola.delete_flag           = 'N'
--   AND     ola.order_line_id         = mld.mov_line_id
--   AND     mld.document_type_code    = '30'
--   AND     mld.record_type_code      = '10'
--   AND     otta.attribute1           = '2'
--   AND     otta.transaction_type_id  = oha.order_type_id
--   UNION
--   SELECT  mil2.inventory_location_id   location_id
--          ,gmd.item_id                 item_id
--          ,mld.lot_id                  lot_id
--   FROM    gme_batch_header      gbh,
--           gme_material_details  gmd,
--           xxinv_mov_lot_details mld,
--           gmd_routings_b        grb,
--           ic_tran_pnd           itp,
--           mtl_item_locations    mil2
--   WHERE   gbh.batch_status      IN (1,2)
--   AND     gbh.plan_start_date   <= FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCMN_MAX_DATE'), 'YYYY/MM/DD')
--   AND     gbh.batch_id           = gmd.batch_id
--   AND     gmd.line_type          = -1
--   AND     gmd.material_detail_id = mld.mov_line_id
--   AND     gbh.routing_id         = grb.routing_id
--   AND     grb.attribute9         = mil2.segment1
--   AND     mld.document_type_code = '40'
--   AND     mld.record_type_code   = '10'
--   AND     itp.line_id            = gmd.material_detail_id
--   AND     itp.item_id            = gmd.item_id
--   AND     itp.lot_id             = mld.lot_id
--   AND     itp.doc_type           = 'PROD'
--   AND     itp.delete_mark        = 0
--   AND     itp.completed_ind      = 0
--   UNION
--   SELECT  mil2.inventory_location_id  location_id
--          ,iimb.item_id                item_id
--          ,mld.lot_id                  lot_id
--   FROM    mtl_system_items_b    msib,
--           ic_item_mst_b         iimb,
--           po_lines_all          pla,
--           po_headers_all        pha,
--           xxinv_mov_lot_details mld,
--           mtl_item_locations    mil2
--   WHERE   iimb.item_no           = msib.segment1
--   AND     msib.organization_id   = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID'))
--   AND     msib.inventory_item_id = pla.item_id
--   AND     pla.attribute13        = 'N'
--   AND     pla.cancel_flag        = 'N'
--   AND     pla.attribute12        = mil2.segment1
--   AND     pla.po_header_id       = pha.po_header_id
--   AND     pha.org_id = FND_PROFILE.VALUE('ORG_ID')
--   AND     pha.attribute1        IN ('20','25')
--   AND     pha.attribute4        <= FND_PROFILE.VALUE('XXCMN_MAX_DATE')
--   AND     pla.po_line_id         = mld.mov_line_id
--   AND     mld.document_type_code = '50'
--   AND     mld.record_type_code   = '10'
--20090624_Ver1.3_0000116_SCS.Goto_DEL_END
     UNION
     SELECT  mrih.ship_to_locat_id       location_id
            ,mld.item_id                 item_id
            ,mld.lot_id                  lot_id
     FROM    xxinv_mov_req_instr_headers mrih,
             xxinv_mov_req_instr_lines   mril,
             xxinv_mov_lot_details       mld
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
     FROM    xxinv_mov_req_instr_headers mrih,
             xxinv_mov_req_instr_lines   mril,
             xxinv_mov_lot_details       mld
     WHERE   mrih.comp_actual_flg    = 'Y'
     AND     mrih.correct_actual_flg = 'Y'
     AND     mrih.status             = '06'
     AND     mrih.mov_hdr_id         = mril.mov_hdr_id
     AND     mril.mov_line_id        = mld.mov_line_id
     AND     mril.delete_flg         = 'N'
     AND     mld.document_type_code  = '20'
--20090624_Ver1.3_0000116_SCS.Goto_MOD_START
     AND     mld.record_type_code    = '20') txn_main
--   AND     mld.record_type_code    = '20') txn_main,
--  (SELECT xq.qt_inspect_req_no,
--          CASE
--            WHEN xq.test_date3 IS NOT NULL THEN
--              xq.qt_effect3
--            WHEN xq.test_date2 IS NOT NULL THEN
--              xq.qt_effect2
--            WHEN xq.test_date1 IS NOT NULL THEN
--              xq.qt_effect1
--            ELSE
--              NULL
--          END  qt_effect
--   FROM   xxwip_qt_inspection xq) xqi,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXCMN_L05') xlvv_xl5,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXCMN_L06') xlvv_xl6,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXCMN_L07') xlvv_xl7,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXCMN_L08') xlvv_xl8,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXCMN_L03') xlvv_xl3,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXWIP_QT_STATUS') xlvv_xqs,
--  (SELECT xlvv.lookup_code,
--          xlvv.meaning
--   FROM   xxcmn_lookup_values_v xlvv
--   WHERE  xlvv.lookup_type = 'XXCMN_LOT_STATUS') xlvv_xls,
--   xxcmn_vendors_v            xvv,
--  (SELECT grb.routing_no,
--          grt.routing_desc
--   FROM   gmd_routings_b  grb,
--          gmd_routings_tl grt
--   WHERE  grb.routing_id = grt.routing_id
--   AND    grt.language   = 'JA') gr
--20090624_Ver1.3_0000116_SCS.Goto_MOD_END
  WHERE  ximv.item_id            = ilm.item_id
  AND    ximv.item_id            = gic_s.item_id
  AND    gic_s.category_id       = mcb_s.category_id
  AND    gic_s.category_set_id   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND    mcb_s.segment1          = '5'
  AND    ximv.item_id            = gic_h.item_id
  AND    gic_h.category_id       = mcb_h.category_id
  AND    gic_h.category_set_id   = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND    mcb_h.segment1          = '2'
  AND    ximv.lot_ctl            = '1'
  AND    ilm.lot_id             <> 0
--20090624_Ver1.3_0000116_SCS.Goto_DEL_START
--AND    (NOT EXISTS (
--        SELECT  1
--        FROM    ic_loct_inv ili
--        WHERE   ili.item_id  = txn_main.item_id
--        AND     ili.lot_id   = txn_main.lot_id
--        AND     ili.location = mil.segment1
--        AND     ROWNUM = 1))
--20090624_Ver1.3_0000116_SCS.Goto_DEL_END
  AND    ximv.item_id            = txn_main.item_id
  AND    mil.inventory_location_id = txn_main.location_id
  AND    ilm.lot_id              = txn_main.lot_id
  AND    iwm.mtl_organization_id = mil.organization_id
--20090624_Ver1.3_0000116_SCS.Goto_MOD_START
--AND    ilm.attribute8             = xvv.segment1(+)
--AND    ilm.attribute9             = xlvv_xl5.lookup_code(+)
--AND    ilm.attribute10            = xlvv_xl6.lookup_code(+)
--AND    ilm.attribute12            = xlvv_xl7.lookup_code(+)
--AND    ilm.attribute13            = xlvv_xl8.lookup_code(+)
--AND    ilm.attribute16            = xlvv_xl3.lookup_code(+)
--AND    xqi.qt_effect               = xlvv_xqs.lookup_code(+)
--AND    ilm.attribute23            = xlvv_xls.lookup_code(+)
--AND    ilm.attribute17            = gr.routing_no(+)
--AND    TO_NUMBER(ilm.attribute22) = xqi.qt_inspect_req_no(+)
--20090624_Ver1.3_0000116_SCS.Goto_MOD_END
  AND    iwm.attribute1             = '0'
/
--
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ORGANIZATION_CODE IS '�g�D�R�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ORGANIZATION_ID IS '�g�DID'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.WHSE_CODE IS '�ۊǑq�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.WHSE_SHORT_NAME IS '�ۊǑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.INV_LOCT_ID IS '�ۊǑq��ID'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ITEM_ID IS '�i��ID'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ITEM_NO IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ITEM_SHORT_NAME IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.NUM_OF_CASES IS '�P�[�X����'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LOT_NO IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LOT_ID IS '���b�gID'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.MANUFACTURE_DATE IS '�����N����'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.EXPIRATION_DATE IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.UNIQE_SIGN IS '�ŗL�L��'
/
--20090624_Ver1.3_0000116_SCS.Goto_DEL_START
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR4 IS '����[����'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR5 IS '�ŏI�[����'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR6 IS '�݌ɓ���'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR7 IS '�݌ɒP��'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR8 IS '�󕥐�'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.VND_SHORT_NAME IS '�󕥐於'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR9 IS '�d���`��'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR9_MEAN IS '�d���`�ԓ��e'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR10 IS '�����敪'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR10_MEAN IS '�����敪���e'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR11 IS '�N�x'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR12 IS '�Y�n'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR12_MEAN IS '�Y�n���e'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR13 IS '�^�C�v'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR13_MEAN IS '�^�C�v���e'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR14 IS '�����N1'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR15 IS '�����N2'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR19 IS '�����N3'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR16 IS '���Y�`�[�敪'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR16_MEAN IS '���Y�`�[�敪���e'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR17 IS '���C��No'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ROUTING_DESC IS '�H���E�v'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ATTR18 IS '�E�v'
--/
--20090624_Ver1.3_0000116_SCS.Goto_DEL_END
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LOT_STATUS IS '���b�g�X�e�[�^�X'
/
--20090624_Ver1.3_0000116_SCS.Goto_DEL_START
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LOT_MEAN IS '���b�g�X�e�[�^�X���e'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.QT_INSPECT_REQ_NO IS '�i�������˗����'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.QT_INS_MEAN IS '�i�����ʓ��e'
--/
--20090624_Ver1.3_0000116_SCS.Goto_DEL_END
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LOCT_ONHAND IS '�莝����'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.STOCK_QTY IS '�莝�݌ɐ�'
/
--20090624_Ver1.3_0000116_SCS.Goto_DEL_START
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.INBOUND_QTY IS '���ɗ\�萔'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.OUTBOUND_QTY IS '�o�ɗ\�萔'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.CREATED_BY IS '�쐬��'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.CREATION_DATE IS '�쐬��'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LAST_UPDATED_BY IS '�ŏI�X�V��'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LAST_UPDATE_DATE IS '�ŏI�X�V��'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.LAST_UPDATE_LOGIN IS '�ŏI�X�V���O�C��'
--/
--COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.ILI_LAST_UPDATE_DATE IS 'OPM�莝���� �ŏI�X�V��'
--/
--20090624_Ver1.3_0000116_SCS.Goto_DEL_END
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_MV.FREQUENT_WHSE IS '��\�q��'
/
