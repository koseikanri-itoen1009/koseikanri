/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCOP_LOCT_INV_V
 * Description     : �v��_�莝�݌Ƀr���[
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009-07-29    1.0   SCS.Goto         �V�K�쐬
 *  2009-12-07    1.1   SCS.Goto         I_E_479_019(�A�v��PT�Ή�)
 *
 ************************************************************************/
CREATE OR REPLACE FORCE VIEW APPS.XXCOP_LOCT_INV_V
  (
   LOCT_ID
  ,LOCT_CODE
  ,ORGANIZATION_ID
  ,ORGANIZATION_CODE
  ,ITEM_ID
  ,ITEM_NO
  ,LOT_ID
  ,LOT_NO
  ,MANUFACTURE_DATE
  ,EXPIRATION_DATE
  ,UNIQUE_SIGN
  ,LOT_STATUS
  ,LOCT_ONHAND
  ,SCHEDULE_DATE
  ,SHIPMENT_DATE
  ,VOUCHER_NO
)
AS
  -------------------------------------------------------------------------
  -- �莝�݌�
  -------------------------------------------------------------------------
  --EBS�莝�݌�
--20091207_Ver1.1_I_E_479_019_SCS.Goto_MOD_START
  SELECT /*+ INDEX(mil MTL_ITEM_LOCATIONS_U1) INDEX(iwm IC_WHSE_MST_U1)*/
--  SELECT
--20091207_Ver1.1_I_E_479_019_SCS.Goto_MOD_END
     mil.inventory_location_id                              LOCT_ID
    ,mil.segment1                                           LOCT_CODE
    ,iwm.mtl_organization_id                                ORGANIZATION_ID
    ,iwm.whse_code                                          ORGANIZATION_CODE
    ,iimb.item_id                                           ITEM_ID
    ,iimb.item_no                                           ITEM_NO
    ,ilm.lot_id                                             LOT_ID
    ,ilm.lot_no                                             LOT_NO
    ,FND_DATE.STRING_TO_DATE(ilm.attribute1, 'YYYY/MM/DD')  MANUFACTURE_DATE
    ,FND_DATE.STRING_TO_DATE(ilm.attribute3, 'YYYY/MM/DD')  EXPIRATION_DATE
    ,ilm.attribute2                                         UNIQUE_SIGN
    ,ilm.attribute23                                        LOT_STATUS
    ,ili.loct_onhand                                        LOCT_ONHAND
    ,FND_DATE.STRING_TO_DATE('1900/01/01', 'YYYY/MM/DD')    SCHEDULE_DATE
    ,FND_DATE.STRING_TO_DATE('1900/01/01', 'YYYY/MM/DD')    SHIPMENT_DATE
    ,NULL                                                   VOUCHER_NO
  FROM
     ic_item_mst_b       iimb
    ,mtl_item_locations  mil
    ,ic_whse_mst         iwm
    ,ic_lots_mst         ilm
    ,ic_loct_inv         ili
  WHERE ilm.item_id             = iimb.item_id
    AND ilm.lot_id             <> 0
    AND iwm.mtl_organization_id = mil.organization_id
    AND ili.item_id             = ilm.item_id
    AND ili.lot_id              = ilm.lot_id
    AND ili.location            = mil.segment1
    AND ilm.attribute23    NOT IN ('60')
  UNION ALL
  --���і��v��
  SELECT
     mil.inventory_location_id                              LOCT_ID
    ,mil.segment1                                           LOCT_CODE
    ,iwm.mtl_organization_id                                ORGANIZATION_ID
    ,iwm.whse_code                                          ORGANIZATION_CODE
    ,iimb.item_id                                           ITEM_ID
    ,iimb.item_no                                           ITEM_NO
    ,ilm.lot_id                                             LOT_ID
    ,ilm.lot_no                                             LOT_NO
    ,FND_DATE.STRING_TO_DATE(ilm.attribute1, 'YYYY/MM/DD')  MANUFACTURE_DATE
    ,FND_DATE.STRING_TO_DATE(ilm.attribute3, 'YYYY/MM/DD')  EXPIRATION_DATE
    ,ilm.attribute2                                         UNIQUE_SIGN
    ,ilm.attribute23                                        LOT_STATUS
    ,(--�ړ�����(���o�ɕ񍐗L/���ɕ񍐗L)
      SELECT
         NVL(SUM(mld.actual_quantity), 0)
      FROM
         xxinv_mov_req_instr_headers mrih
        ,xxinv_mov_req_instr_lines   mril
        ,xxinv_mov_lot_details       mld
      WHERE mrih.ship_to_locat_id   = mil.inventory_location_id
        AND mrih.comp_actual_flg    = 'N'
        AND mrih.status            IN ('05','06')
        AND mrih.mov_hdr_id         = mril.mov_hdr_id
        AND mril.mov_line_id        = mld.mov_line_id
        AND mril.delete_flg         = 'N'
        AND mld.item_id             = iimb.item_id
        AND mld.lot_id              = ilm.lot_id
        AND mld.document_type_code  = '20'
        AND mld.record_type_code    = '30'
     )
     -
     (--�ړ��o��(���o�ɕ񍐗L/�o�ɕ񍐗L)
      SELECT
         NVL(SUM(mld.actual_quantity), 0)
      FROM
         xxinv_mov_req_instr_headers mrih
        ,xxinv_mov_req_instr_lines   mril
        ,xxinv_mov_lot_details       mld
      WHERE mrih.shipped_locat_id   = mil.inventory_location_id
        AND mrih.comp_actual_flg    = 'N'
        AND mrih.status            IN ('04','06')
        AND mrih.mov_hdr_id         = mril.mov_hdr_id
        AND mril.mov_line_id        = mld.mov_line_id
        AND mril.delete_flg         = 'N'
        AND mld.item_id             = iimb.item_id
        AND mld.lot_id              = ilm.lot_id
        AND mld.document_type_code  = '20'
        AND mld.record_type_code    = '20'
     )
     -
     (--�o��
      SELECT
         NVL(SUM(CASE
                   WHEN (otta.order_category_code = 'ORDER') THEN
                     NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)
                   WHEN (otta.order_category_code = 'RETURN') THEN
                    (NVL(mld.actual_quantity, 0) - NVL(mld.before_actual_quantity, 0)) * -1
                 END), 0)
      FROM
         xxwsh_order_headers_all    oha
        ,xxwsh_order_lines_all      ola
        ,xxinv_mov_lot_details      mld
        ,oe_transaction_types_all   otta
      WHERE oha.deliver_from_id       = mil.inventory_location_id
        AND oha.req_status            = '04'
        AND oha.actual_confirm_class  = 'N'
        AND oha.latest_external_flag  = 'Y'
        AND oha.order_header_id       = ola.order_header_id
        AND ola.delete_flag           = 'N'
        AND ola.order_line_id         = mld.mov_line_id
        AND mld.item_id               = iimb.item_id
        AND mld.lot_id                = ilm.lot_id
        AND mld.document_type_code    = '10'
        AND mld.record_type_code      = '20'
        AND otta.attribute1           IN ('1','3')
        AND otta.transaction_type_id  = oha.order_type_id
        AND otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
     )
     +
     (--�ړ�����:����(���o�ɕ񍐗L)
      SELECT
         NVL(SUM(mld.actual_quantity),0) - NVL(SUM(mld.before_actual_quantity),0)
      FROM
         xxinv_mov_req_instr_headers mrih
        ,xxinv_mov_req_instr_lines   mril
        ,xxinv_mov_lot_details       mld
      WHERE mrih.ship_to_locat_id   = mil.inventory_location_id
        AND mrih.comp_actual_flg    = 'Y'
        AND mrih.correct_actual_flg = 'Y'
        AND mrih.status             = '06'
        AND mrih.mov_hdr_id         = mril.mov_hdr_id
        AND mril.mov_line_id        = mld.mov_line_id
        AND mril.delete_flg         = 'N'
        AND mld.item_id             = iimb.item_id
        AND mld.lot_id              = ilm.lot_id
        AND mld.document_type_code  = '20'
        AND mld.record_type_code    = '30'
     )
     -
     (--�ړ��o��:����(���o�ɕ񍐗L)
      SELECT
         NVL(SUM(mld.actual_quantity),0) - NVL(SUM(mld.before_actual_quantity),0)
      FROM
         xxinv_mov_req_instr_headers mrih
        ,xxinv_mov_req_instr_lines   mril
        ,xxinv_mov_lot_details       mld
      WHERE mrih.shipped_locat_id   = mil.inventory_location_id
        AND mrih.comp_actual_flg    = 'Y'
        AND mrih.correct_actual_flg = 'Y'
        AND mrih.status             = '06'
        AND mrih.mov_hdr_id         = mril.mov_hdr_id
        AND mril.mov_line_id        = mld.mov_line_id
        AND mril.delete_flg         = 'N'
        AND mld.item_id             = iimb.item_id
        AND mld.lot_id              = ilm.lot_id
        AND mld.document_type_code  = '20'
        AND mld.record_type_code    = '20'
     )                                                      LOCT_ONHAND
    ,FND_DATE.STRING_TO_DATE('1900/01/01', 'YYYY/MM/DD')    SCHEDULE_DATE
    ,FND_DATE.STRING_TO_DATE('1900/01/01', 'YYYY/MM/DD')    SHIPMENT_DATE
    ,NULL                                                   VOUCHER_NO
  FROM
     ic_item_mst_b       iimb
    ,mtl_item_locations  mil
    ,ic_whse_mst         iwm
    ,ic_lots_mst         ilm
    ,(
      --�ړ�����(���o�ɕ񍐗L/���ɕ񍐗L)
      SELECT
         mld.item_id            item_id
        ,mld.lot_id             lot_id
        ,mrih.ship_to_locat_id  loct_id
      FROM
         xxinv_mov_req_instr_headers mrih
        ,xxinv_mov_req_instr_lines   mril
        ,xxinv_mov_lot_details       mld
      WHERE mrih.comp_actual_flg    = 'N'
        AND mrih.status            IN ('05','06')
        AND mrih.mov_hdr_id         = mril.mov_hdr_id
        AND mril.mov_line_id        = mld.mov_line_id
        AND mril.delete_flg         = 'N'
        AND mld.document_type_code  = '20'
        AND mld.record_type_code    = '30'
      UNION
      --�ړ��o��(���o�ɕ񍐗L/�o�ɕ񍐗L)
      SELECT
         mld.item_id            item_id
        ,mld.lot_id             lot_id
        ,mrih.shipped_locat_id  loct_id
      FROM
         xxinv_mov_req_instr_headers mrih
        ,xxinv_mov_req_instr_lines   mril
        ,xxinv_mov_lot_details       mld
      WHERE mrih.comp_actual_flg    = 'N'
        AND mrih.status            IN ('04','06')
        AND mrih.mov_hdr_id         = mril.mov_hdr_id
        AND mril.mov_line_id        = mld.mov_line_id
        AND mril.delete_flg         = 'N'
        AND mld.document_type_code  = '20'
        AND mld.record_type_code    = '20'
      UNION
      --�o��
      SELECT
         mld.item_id            item_id
        ,mld.lot_id             lot_id
        ,oha.deliver_from_id    loct_id
      FROM
         xxwsh_order_headers_all    oha
        ,xxwsh_order_lines_all      ola
        ,xxinv_mov_lot_details      mld
        ,oe_transaction_types_all   otta
      WHERE oha.req_status            = '04'
        AND oha.actual_confirm_class  = 'N'
        AND oha.latest_external_flag  = 'Y'
        AND oha.order_header_id       = ola.order_header_id
        AND ola.delete_flag           = 'N'
        AND ola.order_line_id         = mld.mov_line_id
        AND mld.document_type_code    = '10'
        AND mld.record_type_code      = '20'
        AND otta.attribute1           IN ('1','3')
        AND otta.transaction_type_id  = oha.order_type_id
        AND otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
      UNION
      --�ړ�����:����(���o�ɕ񍐗L)
      SELECT
         mld.item_id            item_id
        ,mld.lot_id             lot_id
        ,mrih.ship_to_locat_id  loct_id
      FROM
         xxinv_mov_req_instr_headers mrih
        ,xxinv_mov_req_instr_lines   mril
        ,xxinv_mov_lot_details       mld
      WHERE mrih.comp_actual_flg    = 'Y'
        AND mrih.correct_actual_flg = 'Y'
        AND mrih.status             = '06'
        AND mrih.mov_hdr_id         = mril.mov_hdr_id
        AND mril.mov_line_id        = mld.mov_line_id
        AND mril.delete_flg         = 'N'
        AND mld.document_type_code  = '20'
        AND mld.record_type_code    = '30'
      UNION
      --�ړ��o��:����(���o�ɕ񍐗L)
      SELECT
         mld.item_id            item_id
        ,mld.lot_id             lot_id
        ,mrih.shipped_locat_id  loct_id
      FROM
         xxinv_mov_req_instr_headers mrih
        ,xxinv_mov_req_instr_lines   mril
        ,xxinv_mov_lot_details       mld
      WHERE mrih.comp_actual_flg    = 'Y'
        AND mrih.correct_actual_flg = 'Y'
        AND mrih.status             = '06'
        AND mrih.mov_hdr_id         = mril.mov_hdr_id
        AND mril.mov_line_id        = mld.mov_line_id
        AND mril.delete_flg         = 'N'
        AND mld.document_type_code  = '20'
        AND mld.record_type_code    = '20'
     ) xmld
  WHERE ilm.item_id             = iimb.item_id
    AND ilm.lot_id             <> 0
    AND iwm.mtl_organization_id = mil.organization_id
    AND xmld.item_id            = ilm.item_id
    AND xmld.lot_id             = ilm.lot_id
    AND xmld.loct_id            = mil.inventory_location_id
    AND ilm.attribute23    NOT IN ('60')
  -------------------------------------------------------------------------
  -- ���o�ɗ\��
  -------------------------------------------------------------------------
  UNION ALL
  --������  ��������\��
  SELECT
     mil.inventory_location_id                                  LOCT_ID
    ,mil.segment1                                               LOCT_CODE
    ,iwm.mtl_organization_id                                    ORGANIZATION_ID
    ,iwm.whse_code                                              ORGANIZATION_CODE
    ,iimb.item_id                                               ITEM_ID
    ,iimb.item_no                                               ITEM_NO
    ,ilm.lot_id                                                 LOT_ID
    ,ilm.lot_no                                                 LOT_NO
    ,FND_DATE.STRING_TO_DATE(ilm.attribute1, 'YYYY/MM/DD')      MANUFACTURE_DATE
    ,FND_DATE.STRING_TO_DATE(ilm.attribute3, 'YYYY/MM/DD')      EXPIRATION_DATE
    ,ilm.attribute2                                             UNIQUE_SIGN
    ,ilm.attribute23                                            LOT_STATUS
    ,pla.quantity                                               LOCT_ONHAND
    ,FND_DATE.STRING_TO_DATE(pha.attribute4, 'YYYY/MM/DD')      SCHEDULE_DATE
    ,FND_DATE.STRING_TO_DATE('1900/01/01', 'YYYY/MM/DD')        SHIPMENT_DATE
    ,pha.segment1                                               VOUCHER_NO
  FROM
     ic_item_mst_b       iimb
    ,mtl_item_locations  mil
    ,ic_whse_mst         iwm
    ,ic_lots_mst         ilm
    ,mtl_system_items_b  msib
    ,po_lines_all        pla
    ,po_headers_all      pha
  WHERE ilm.item_id             = iimb.item_id
    AND ilm.lot_id             <> 0
    AND iwm.mtl_organization_id = mil.organization_id
    AND msib.segment1           = iimb.item_no
    AND msib.organization_id    = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
    AND msib.inventory_item_id  = pla.item_id
    AND pla.attribute1          = ilm.lot_no
    AND pla.attribute13         = 'N'
    AND pla.cancel_flag         = 'N'
    AND pla.po_header_id        = pha.po_header_id
    AND pha.attribute1         IN ('20', '25')
    AND pha.attribute5          = mil.segment1
    AND pha.org_id              = FND_PROFILE.VALUE('ORG_ID')
    AND ilm.attribute23    NOT IN ('60')
  UNION ALL
  --������  �ړ����ɗ\��
--20091207_Ver1.1_I_E_479_019_SCS.Goto_MOD_START
  SELECT /*+ INDEX(mil MTL_ITEM_LOCATIONS_U1 iwm IC_WHSE_MST_U1) */
--  SELECT
--20091207_Ver1.1_I_E_479_019_SCS.Goto_MOD_END
     mil.inventory_location_id                                  LOCT_ID
    ,mil.segment1                                               LOCT_CODE
    ,iwm.mtl_organization_id                                    ORGANIZATION_ID
    ,iwm.whse_code                                              ORGANIZATION_CODE
    ,iimb.item_id                                               ITEM_ID
    ,iimb.item_no                                               ITEM_NO
    ,ilm.lot_id                                                 LOT_ID
    ,ilm.lot_no                                                 LOT_NO
    ,FND_DATE.STRING_TO_DATE(ilm.attribute1, 'YYYY/MM/DD')      MANUFACTURE_DATE
    ,FND_DATE.STRING_TO_DATE(ilm.attribute3, 'YYYY/MM/DD')      EXPIRATION_DATE
    ,ilm.attribute2                                             UNIQUE_SIGN
    ,ilm.attribute23                                            LOT_STATUS
    ,mld.actual_quantity                                        LOCT_ONHAND
    ,mrih.schedule_arrival_date                                 SCHEDULE_DATE
    ,FND_DATE.STRING_TO_DATE('1900/01/01', 'YYYY/MM/DD')        SHIPMENT_DATE
    ,mrih.mov_num                                               VOUCHER_NO
  FROM
     ic_item_mst_b               iimb
    ,mtl_item_locations          mil
    ,ic_whse_mst                 iwm
    ,ic_lots_mst                 ilm
    ,xxinv_mov_req_instr_headers mrih
    ,xxinv_mov_req_instr_lines   mril
    ,xxinv_mov_lot_details       mld
  WHERE ilm.item_id             = iimb.item_id
    AND ilm.lot_id             <> 0
    AND iwm.mtl_organization_id = mil.organization_id
    AND mrih.ship_to_locat_id   = mil.inventory_location_id
    AND mrih.comp_actual_flg    = 'N'
    AND mrih.status            IN ('02', '03')
    AND mrih.mov_hdr_id         = mril.mov_hdr_id
    AND mril.mov_line_id        = mld.mov_line_id
    AND mril.delete_flg         = 'N'
    AND mld.item_id             = iimb.item_id
    AND mld.lot_id              = ilm.lot_id
    AND mld.document_type_code  = '20'
    AND mld.record_type_code    = '10'
    AND ilm.attribute23    NOT IN ('60')
  UNION ALL
  --������  ���ьv��ς̈ړ��o�Ɏ���
--20091207_Ver1.1_I_E_479_019_SCS.Goto_MOD_START
  SELECT /*+ INDEX(mil MTL_ITEM_LOCATIONS_U1) INDEX(iwm IC_WHSE_MST_U1)*/
--  SELECT
--20091207_Ver1.1_I_E_479_019_SCS.Goto_MOD_END
     mil.inventory_location_id                                  LOCT_ID
    ,mil.segment1                                               LOCT_CODE
    ,iwm.mtl_organization_id                                    ORGANIZATION_ID
    ,iwm.whse_code                                              ORGANIZATION_CODE
    ,iimb.item_id                                               ITEM_ID
    ,iimb.item_no                                               ITEM_NO
    ,ilm.lot_id                                                 LOT_ID
    ,ilm.lot_no                                                 LOT_NO
    ,FND_DATE.STRING_TO_DATE(ilm.attribute1, 'YYYY/MM/DD')      MANUFACTURE_DATE
    ,FND_DATE.STRING_TO_DATE(ilm.attribute3, 'YYYY/MM/DD')      EXPIRATION_DATE
    ,ilm.attribute2                                             UNIQUE_SIGN
    ,ilm.attribute23                                            LOT_STATUS
    ,mld.actual_quantity                                        LOCT_ONHAND
    ,NVL(mrih.actual_arrival_date, mrih.schedule_arrival_date)  SCHEDULE_DATE
    ,FND_DATE.STRING_TO_DATE('1900/01/01', 'YYYY/MM/DD')        SHIPMENT_DATE
    ,mrih.mov_num                                               VOUCHER_NO
  FROM
     ic_item_mst_b               iimb
    ,mtl_item_locations          mil
    ,ic_whse_mst                 iwm
    ,ic_lots_mst                 ilm
    ,xxinv_mov_req_instr_headers mrih
    ,xxinv_mov_req_instr_lines   mril
    ,xxinv_mov_lot_details       mld
  WHERE ilm.item_id             = iimb.item_id
    AND ilm.lot_id             <> 0
    AND iwm.mtl_organization_id = mil.organization_id
    AND mrih.ship_to_locat_id   = mil.inventory_location_id
    AND mrih.comp_actual_flg    = 'N'
    AND mrih.status             = '04'
    AND mrih.mov_hdr_id         = mril.mov_hdr_id
    AND mril.mov_line_id        = mld.mov_line_id
    AND mril.delete_flg         = 'N'
    AND mld.item_id             = iimb.item_id
    AND mld.lot_id              = ilm.lot_id
    AND mld.document_type_code  = '20'
    AND mld.record_type_code    = '20'
    AND ilm.attribute23    NOT IN ('60')
  UNION ALL
  --���v��  ���і��v��̈ړ��w��
--20091207_Ver1.1_I_E_479_019_SCS.Goto_MOD_START
  SELECT /*+ INDEX(mil MTL_ITEM_LOCATIONS_U1 iwm IC_WHSE_MST_U1) */
--  SELECT
--20091207_Ver1.1_I_E_479_019_SCS.Goto_MOD_END
     mil.inventory_location_id                                  LOCT_ID
    ,mil.segment1                                               LOCT_CODE
    ,iwm.mtl_organization_id                                    ORGANIZATION_ID
    ,iwm.whse_code                                              ORGANIZATION_CODE
    ,iimb.item_id                                               ITEM_ID
    ,iimb.item_no                                               ITEM_NO
    ,ilm.lot_id                                                 LOT_ID
    ,ilm.lot_no                                                 LOT_NO
    ,FND_DATE.STRING_TO_DATE(ilm.attribute1, 'YYYY/MM/DD')      MANUFACTURE_DATE
    ,FND_DATE.STRING_TO_DATE(ilm.attribute3, 'YYYY/MM/DD')      EXPIRATION_DATE
    ,ilm.attribute2                                             UNIQUE_SIGN
    ,ilm.attribute23                                            LOT_STATUS
    ,mld.actual_quantity * -1                                   LOCT_ONHAND
    ,mrih.schedule_ship_date                                    SCHEDULE_DATE
    ,FND_DATE.STRING_TO_DATE('1900/01/01', 'YYYY/MM/DD')        SHIPMENT_DATE
    ,mrih.mov_num                                               VOUCHER_NO
  FROM
     ic_item_mst_b               iimb
    ,mtl_item_locations          mil
    ,ic_whse_mst                 iwm
    ,ic_lots_mst                 ilm
    ,xxinv_mov_req_instr_headers mrih
    ,xxinv_mov_req_instr_lines   mril
    ,xxinv_mov_lot_details       mld
  WHERE ilm.item_id             = iimb.item_id
    AND ilm.lot_id             <> 0
    AND iwm.mtl_organization_id = mil.organization_id
    AND mrih.shipped_locat_id   = mil.inventory_location_id
    AND mrih.comp_actual_flg    = 'N'
    AND mrih.status            IN ('02', '03')
    AND mrih.mov_hdr_id         = mril.mov_hdr_id
    AND mril.mov_line_id        = mld.mov_line_id
    AND mril.delete_flg         = 'N'
    AND mld.item_id             = iimb.item_id
    AND mld.lot_id              = ilm.lot_id
    AND mld.document_type_code  = '20'
    AND mld.record_type_code    = '10'
    AND ilm.attribute23    NOT IN ('60')
  UNION ALL
  --���v��  ���ьv��ς̈ړ����Ɏ���
--20091207_Ver1.1_I_E_479_019_SCS.Goto_MOD_START
  SELECT /*+ INDEX(mil MTL_ITEM_LOCATIONS_U1) INDEX(iwm IC_WHSE_MST_U1)*/
--  SELECT
--20091207_Ver1.1_I_E_479_019_SCS.Goto_MOD_END
     mil.inventory_location_id                                  LOCT_ID
    ,mil.segment1                                               LOCT_CODE
    ,iwm.mtl_organization_id                                    ORGANIZATION_ID
    ,iwm.whse_code                                              ORGANIZATION_CODE
    ,iimb.item_id                                               ITEM_ID
    ,iimb.item_no                                               ITEM_NO
    ,ilm.lot_id                                                 LOT_ID
    ,ilm.lot_no                                                 LOT_NO
    ,FND_DATE.STRING_TO_DATE(ilm.attribute1, 'YYYY/MM/DD')      MANUFACTURE_DATE
    ,FND_DATE.STRING_TO_DATE(ilm.attribute3, 'YYYY/MM/DD')      EXPIRATION_DATE
    ,ilm.attribute2                                             UNIQUE_SIGN
    ,ilm.attribute23                                            LOT_STATUS
    ,mld.actual_quantity * -1                                   LOCT_ONHAND
    ,NVL(mrih.actual_ship_date, mrih.schedule_ship_date)        SCHEDULE_DATE
    ,FND_DATE.STRING_TO_DATE('1900/01/01', 'YYYY/MM/DD')        SHIPMENT_DATE
    ,mrih.mov_num                                               VOUCHER_NO
  FROM
     ic_item_mst_b               iimb
    ,mtl_item_locations          mil
    ,ic_whse_mst                 iwm
    ,ic_lots_mst                 ilm
    ,xxinv_mov_req_instr_headers mrih
    ,xxinv_mov_req_instr_lines   mril
    ,xxinv_mov_lot_details       mld
  WHERE ilm.item_id             = iimb.item_id
    AND ilm.lot_id             <> 0
    AND iwm.mtl_organization_id = mil.organization_id
    AND mrih.shipped_locat_id   = mil.inventory_location_id
    AND mrih.comp_actual_flg    = 'N'
    AND mrih.status             = '05'
    AND mrih.mov_hdr_id         = mril.mov_hdr_id
    AND mril.mov_line_id        = mld.mov_line_id
    AND mril.delete_flg         = 'N'
    AND mld.item_id             = iimb.item_id
    AND mld.lot_id              = ilm.lot_id
    AND mld.document_type_code  = '20'
    AND mld.record_type_code    = '30'
    AND ilm.attribute23    NOT IN ('60')
  -------------------------------------------------------------------------
  -- �o�ח\��
  -------------------------------------------------------------------------
  UNION ALL
  --���v��  ���і��v��̏o�׈˗�
--20091207_Ver1.1_I_E_479_019_SCS.Goto_MOD_START
  SELECT /*+ INDEX(mil MTL_ITEM_LOCATIONS_U1 iwm IC_WHSE_MST_U1) */
--  SELECT
--20091207_Ver1.1_I_E_479_019_SCS.Goto_MOD_END
     mil.inventory_location_id                                  LOCT_ID
    ,mil.segment1                                               LOCT_CODE
    ,iwm.mtl_organization_id                                    ORGANIZATION_ID
    ,iwm.whse_code                                              ORGANIZATION_CODE
    ,iimb.item_id                                               ITEM_ID
    ,iimb.item_no                                               ITEM_NO
    ,ilm.lot_id                                                 LOT_ID
    ,ilm.lot_no                                                 LOT_NO
    ,FND_DATE.STRING_TO_DATE(ilm.attribute1, 'YYYY/MM/DD')      MANUFACTURE_DATE
    ,FND_DATE.STRING_TO_DATE(ilm.attribute3, 'YYYY/MM/DD')      EXPIRATION_DATE
    ,ilm.attribute2                                             UNIQUE_SIGN
    ,ilm.attribute23                                            LOT_STATUS
    ,mld.actual_quantity * -1                                   LOCT_ONHAND
    ,FND_DATE.STRING_TO_DATE('1900/01/01', 'YYYY/MM/DD')        SCHEDULE_DATE
    ,oha.schedule_ship_date                                     SHIPMENT_DATE
    ,oha.request_no                                             VOUCHER_NO
  FROM
     ic_item_mst_b              iimb
    ,mtl_item_locations         mil
    ,ic_whse_mst                iwm
    ,ic_lots_mst                ilm
    ,xxwsh_order_headers_all    oha
    ,xxwsh_order_lines_all      ola
    ,xxinv_mov_lot_details      mld
    ,oe_transaction_types_all   otta
  WHERE ilm.item_id               = iimb.item_id
    AND ilm.lot_id               <> 0
    AND iwm.mtl_organization_id   = mil.organization_id
    AND oha.deliver_from_id       = mil.inventory_location_id
    AND oha.req_status            = '03'
    AND oha.actual_confirm_class  = 'N'
    AND oha.latest_external_flag  = 'Y'
    AND oha.order_header_id       = ola.order_header_id
    AND ola.delete_flag           = 'N'
    AND ola.order_line_id         = mld.mov_line_id
    AND mld.item_id               = iimb.item_id
    AND mld.lot_id                = ilm.lot_id
    AND mld.document_type_code    = '10'
    AND mld.record_type_code      = '10'
    AND otta.attribute1           = '1'
    AND otta.transaction_type_id  = oha.order_type_id
    AND otta.org_id               = FND_PROFILE.VALUE('ORG_ID')
    AND ilm.attribute23    NOT IN ('60')
/
--
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.LOCT_ID                                  IS '�ۊǏꏊID'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.LOCT_CODE                                IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.ORGANIZATION_ID                          IS '�g�DID'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.ORGANIZATION_CODE                        IS '�g�D�R�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.ITEM_ID                                  IS '�i��ID'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.ITEM_NO                                  IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.LOT_ID                                   IS '���b�gID'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.LOT_NO                                   IS '���b�gNO'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.MANUFACTURE_DATE                         IS '�����N����'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.EXPIRATION_DATE                          IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.UNIQUE_SIGN                              IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.LOT_STATUS                               IS '���b�g�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.LOCT_ONHAND                              IS '�莝�݌ɐ�'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.SCHEDULE_DATE                            IS '�v���'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.SHIPMENT_DATE                            IS '�o�ד�'
/
COMMENT ON COLUMN APPS.XXCOP_LOCT_INV_V.VOUCHER_NO                               IS '�`�[NO'
/