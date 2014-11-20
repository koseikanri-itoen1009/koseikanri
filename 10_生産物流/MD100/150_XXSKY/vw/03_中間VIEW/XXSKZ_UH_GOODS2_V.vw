/*************************************************************************
 * 
 * View  Name      : XXSKZ_UH_GOODS2_V
 * Description     : XXSKZ_UH_GOODS2_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/28    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
--*******************************************************************
-- �󕥏��_���i ����VIEW2(SYSDATE-1���x��)
--   �y�g�p�Ώ�VIEW�z
--     �EXXSKZ_�󕥏��_���i_��{2_V
--     �EXXSKZ_�󕥏��_���i_����2_V
--*******************************************************************
CREATE OR REPLACE VIEW APPS.XXSKZ_UH_GOODS2_V
(
 whse_code
,item_id
,lot_id
,trans_qty
,column_no
,trans_date
)
AS
    --****************************************************************************
    -- �Ώۂ̃f�[�^���擾 START (�Q�l�R�[�h�FXXCMN770002C �ɃC���f���g�����킹��)
    --****************************************************************************
      ------------------------------------------------------
      -- �I�������݌Ƀe�[�u�����猎��݌ɐ����擾
      ------------------------------------------------------
      SELECT  XSIMS.whse_code            whse_code                                 --�q�ɃR�[�h
             ,XSIMS.item_id              item_id                                   --�i��ID
             ,XSIMS.lot_id               lot_id                                    --���b�gID
             ,NVL(XSIMS.monthly_stock, 0) + NVL(XSIMS.cargo_stock, 0) trans_qty    --����݌ɐ�
             ,'0'                        column_no
             ,TRUNC(ADD_MONTHS(TO_DATE(XSIMS.invent_ym, 'YYYYMM'), 1), 'MM')       trans_date    --�I���N��
        FROM  xxcmn_stc_inv_month_stck_arc       XSIMS
             ,ic_whse_mst                        IWM
-- 2009/11/12 Add Start
             -- �i�ڋ敪
             ,gmi_item_categories    gic_h
             ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
       WHERE  
              IWM.whse_code  = XSIMS.whse_code
         AND  IWM.attribute1 = '0'
-- 2009/11/12 Add Start
         AND  mcb_h.segment1 = '5'
         AND  gic_h.category_id         = mcb_h.category_id
         AND  gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
         AND  XSIMS.item_id             = gic_h.item_id
-- 2009/12/17 T.Yoshimoto Add Start
         AND  xsims.invent_ym          >= TO_CHAR(ADD_MONTHS(trunc(sysdate,'MM'), -2), 'YYYYMM')
         AND  xsims.invent_ym          <  TO_CHAR(ADD_MONTHS(trunc(sysdate,'MM'),  1), 'YYYYMM')
-- 2009/12/17 T.Yoshimoto Add End
-- 2009/11/12 Add End
      UNION ALL
      ------------------------------------------------------
      -- PROD :�o���󕥋敪���Y�֘A�iReverse_id�Ȃ��j�i��E�i�ڐU�ւȂ�
      -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,itp.item_id                      item_id
            ,itp.lot_id                       lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,itp.trans_date                   trans_date
      FROM   xxcmn_ic_tran_pnd_arc           itp
            ,xxcmn_gme_material_details_arc  gmd
            ,xxcmn_gme_batch_header_arc      gbh
            ,gmd_routings_b                  grb
            ,xxcmn_rcv_pay_mst               xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
            ,gmi_item_categories    gic_h
            ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itp.doc_type            = 'PROD'
      AND    itp.completed_ind       = 1
      AND    itp.reverse_id          IS NULL
-- 2009/12/17 T.Yoshimoto Add Start
      AND    itp.trans_date         >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    itp.trans_date         <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    gmd.batch_id            = itp.doc_id
      AND    gmd.line_no             = itp.doc_line
      AND    gmd.line_type           = itp.line_type
      AND    gbh.batch_id            = gmd.batch_id
      AND    grb.routing_id          = gbh.routing_id
      AND    xrpm.routing_class      = grb.routing_class
      AND    xrpm.line_type          = gmd.line_type
      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
             OR (xrpm.hit_in_div = gmd.attribute5))
      AND    itp.doc_type            = xrpm.doc_type
      AND    itp.line_type           = xrpm.line_type
      AND    xrpm.break_col_02       IS NOT NULL
-- 2009/12/17 Mod Start �i�ڐU��(�H��70)�͌����A�����i�݂̂Ȃ̂ŁA�擾���Ȃ��B
--      AND    ((xrpm.routing_class    <> '70')
--             OR ((xrpm.routing_class     = '70')
--                 AND (EXISTS (SELECT 1
--                              FROM   xxcmn_gme_material_details_arc gmd2
--                                    ,gmi_item_categories  gic
--                                    ,mtl_categories_b     mcb
--                              WHERE  gmd2.batch_id   = gmd.batch_id
--                              AND    gmd2.line_no    = gmd.line_no
--                              AND    gmd2.line_type  = -1
--                              AND    gic.item_id     = gmd2.item_id
--                              AND    gic.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
--                              AND    gic.category_id = mcb.category_id
--                              AND    mcb.segment1    = xrpm.item_div_origin))
--                 AND (EXISTS (SELECT 1
--                              FROM   xxcmn_gme_material_details_arc gmd3
--                                    ,gmi_item_categories  gic
--                                    ,mtl_categories_b     mcb
--                              WHERE  gmd3.batch_id   = gmd.batch_id
--                              AND    gmd3.line_no    = gmd.line_no
--                              AND    gmd3.line_type  = 1
--                              AND    gic.item_id     = gmd3.item_id
--                              AND    gic.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
--                              AND    gic.category_id = mcb.category_id
--                              AND    mcb.segment1    = xrpm.item_div_ahead))
--             ))
      AND  xrpm.routing_class       <> '70'
      AND  xrpm.doc_type             = 'PROD'
-- 2009/12/17 Mod End
-- 2009/11/12 Add Start
      AND  mcb_h.segment1 = '5'
      AND  gic_h.category_id         = mcb_h.category_id
      AND  gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND  itp.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
      --���_
      -- ----------------------------------------------------
      -- PORC1 :�o���󕥋敪�w���֘A (���i�o��,�L��)
      -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,itp.item_id                      item_id
            ,itp.lot_id                       lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,xxcmn_rcv_shipment_lines_arc     rsl
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
             ,gmi_item_categories    gic_h
             ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xola.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
      AND    xola.order_header_id    = xoha.order_header_id
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead     = '5'
      AND    xoha.req_status         IN ('04','08')
      AND    otta.attribute1         IN ('1','2')
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_02       IS NOT NULL
-- 2009/11/12 Add Start
      AND    mcb_h.segment1 = '5'
      AND    gic_h.category_id         = mcb_h.category_id
      AND    gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND    itp.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
      -- �U�֓��ɁE�U�֗L��
      -- ----------------------------------------------------
      -- PORC2 :�o���󕥋敪�w���֘A (�U�֗L��)
      -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,iimb.item_id                     item_id
            ,itp.lot_id                       lot_id
            ,CASE WHEN xrpm.dealings_div_name IN ('�U�֗L��_���'
                                                 ,'���i�U�֗L��_���'
                                                 ,'�U�֏o��_���_��'
                                                 ,'�U�֏o��_���_��')
                       THEN itp.trans_qty * TO_NUMBER('-1')
                  ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
             END                              trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,xxcmn_rcv_shipment_lines_arc     rsl
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_item_mst_b                    iimb
            ,xxskz_item_class_v               xicv1
            ,xxskz_item_class_v               xicv2
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    iimb.item_no            = xola.request_item_code
      AND    xicv1.item_id           = iimb.item_id
      AND    xrpm.item_div_ahead     = xicv1.item_class_code
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xicv1.item_class_code   = '5'
-- 2009/12/17 T.Yoshimoto Add End
      AND    xicv2.item_id           = itp.item_id
      AND    xicv2.item_class_code   <> '5'
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
-- 2009/11/12 Del Start
      --AND    ooha.header_id          = rsl.oe_order_header_id
-- 2009/11/12 Del End
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2009/11/12 Del Start
      --AND    ooha.header_id          = xoha.header_id
-- 2009/11/12 Del End
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('104','105')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_02       IS NOT NULL
      UNION ALL
      -- �h�����N�M�t�g���
      -- ----------------------------------------------------
      -- PORC3 :�o���󕥋敪�w���֘A (���i�U�֗L��)
      -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,iimb.item_id                     item_id
            ,itp.lot_id                       lot_id
            ,CASE WHEN xrpm.dealings_div_name IN ('�U�֗L��_���'
                                                 ,'���i�U�֗L��_���'
                                                 ,'�U�֏o��_���_��'
                                                 ,'�U�֏o��_���_��')
                       THEN itp.trans_qty * TO_NUMBER('-1')
                  ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
             END                              trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,xxcmn_rcv_shipment_lines_arc     rsl
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_item_mst_b                    iimb
            ,xxskz_prod_class_v               prdc1  --�U�֑O�i�� ���i�敪
            ,xxskz_item_class_v               itmc1  --�U�֑O�i�� �i�ڋ敪
            ,xxskz_prod_class_v               prdc2  --�U�֌�i�� ���i�敪
            ,xxskz_item_class_v               itmc2  --�U�֌�i�� ���i�敪
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    iimb.item_no            = xola.request_item_code
      AND    prdc1.item_id           = iimb.item_id
      AND    xrpm.prod_div_ahead     = prdc1.prod_class_code
      AND    itmc1.item_id           = iimb.item_id
      AND    xrpm.item_div_ahead     = itmc1.item_class_code
-- 2009/12/17 T.Yoshimoto Add Start
      AND    itmc1.item_class_code   = '5'
-- 2009/12/17 T.Yoshimoto Add End
      AND    prdc2.item_id           = itp.item_id
      AND    xrpm.prod_div_origin    = prdc2.prod_class_code
      AND    itmc2.item_id           = itp.item_id
      AND    xrpm.item_div_origin    = itmc2.item_class_code
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
-- 2009/11/12 Del Start
      --AND    ooha.header_id          = rsl.oe_order_header_id
-- 2009/11/12 Del End
      AND    xoha.header_id          = rsl.oe_order_header_id
-- 2009/11/12 Del Start
      --AND    ooha.header_id          = xoha.header_id
-- 2009/11/12 Del End
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('107','108')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_02       IS NOT NULL
      UNION ALL
      -- ���̑�
      -- ----------------------------------------------------
      -- PORC4 :�o���󕥋敪�w���֘A (���i�U�֗L���A���o)
      -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,itp.item_id                      item_id
            ,itp.lot_id                       lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,xxcmn_rcv_shipment_lines_arc     rsl
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_item_mst_b                    iimb
            ,xxskz_prod_class_v               prdc1  --�U�֑O�i�� ���i�敪
            ,xxskz_item_class_v               itmc1  --�U�֑O�i�� �i�ڋ敪
            ,xxskz_prod_class_v               prdc2  --�U�֌�i�� ���i�敪
            ,xxskz_item_class_v               itmc2  --�U�֌�i�� ���i�敪
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    prdc1.item_id           = itp.item_id
      AND    xrpm.prod_div_origin    = prdc1.prod_class_code
      AND    itmc1.item_id           = itp.item_id
      AND    xrpm.item_div_origin    = itmc1.item_class_code
-- 2009/12/17 T.Yoshimoto Add Start
      AND    itmc1.item_class_code   = '5'
-- 2009/12/17 T.Yoshimoto Add End
      AND    xola.request_item_code  = iimb.item_no
      AND    prdc2.item_id           = iimb.item_id
      AND    xrpm.prod_div_ahead     = prdc2.prod_class_code
      AND    itmc2.item_id           = iimb.item_id
      AND    xrpm.item_div_ahead     = itmc2.item_class_code
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.oe_order_header_id  = xoha.header_id
      AND    rsl.oe_order_line_id    = xola.line_id
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
      AND    xola.order_header_id    = xoha.order_header_id
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod Start
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '109'
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_02       IS NOT NULL
      UNION ALL
      -- ���_
      -- ----------------------------------------------------
      -- PORC5 :�o���󕥋敪�w���֘A (�U�֏o�ׁA�o��)
      -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,iimb.item_id                     item_id
            ,itp.lot_id                       lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,xxcmn_rcv_shipment_lines_arc     rsl
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_item_mst_b                    iimb
            ,xxskz_item_class_v               xicv
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    iimb.item_no            = xola.request_item_code
      AND    xicv.item_id            = iimb.item_id
      AND    xrpm.item_div_ahead     = xicv.item_class_code
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xicv.item_class_code    = '5'
-- 2009/12/17 T.Yoshimoto Add End
      AND    xola.request_item_code <> xola.shipping_item_code
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
-- 2009/11/12 Del Start
      --AND    ooha.header_id          = rsl.oe_order_header_id
      --AND    ooha.header_id          = xoha.header_id
-- 2009/11/12 Del End
      AND    xola.order_header_id    = xoha.order_header_id
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       = '112'
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_02       IS NOT NULL
      UNION ALL
      -- �Ήc�P�E�Ήc�Q
      -- ----------------------------------------------------
      -- PORC6 :�o���󕥋敪�w���֘A (�U�֏o�ׁA���_�����A���_��)
      -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,iimb.item_id                     item_id
            ,itp.lot_id                       lot_id
            ,CASE WHEN xrpm.dealings_div_name IN ('�U�֗L��_���'
                                                 ,'���i�U�֗L��_���'
                                                 ,'�U�֏o��_���_��'
                                                 ,'�U�֏o��_���_��')
                       THEN itp.trans_qty * TO_NUMBER('-1')
                  ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
             END                              trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,xxcmn_rcv_shipment_lines_arc     rsl
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_item_mst_b                    iimb
            ,xxskz_item_class_v               xicv1
            ,xxskz_item_class_v               xicv2
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    iimb.item_no            = xola.request_item_code
      AND    xicv1.item_id           = iimb.item_id
      AND    xrpm.item_div_ahead     = xicv1.item_class_code
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xicv1.item_class_code   = '5'
-- 2009/12/17 T.Yoshimoto Add End
      AND    xicv2.item_id           = itp.item_id
      AND    xrpm.item_div_origin    = xicv2.item_class_code
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
-- 2009/11/12 Del Start
      --AND    ooha.header_id          = rsl.oe_order_header_id
-- 2009/11/12 Del End
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('110','111')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_02       IS NOT NULL
      UNION ALL
      --�q�ցE�ԕi
      -- ----------------------------------------------------
      -- PORC7 :�o���󕥋敪�w���֘A (�q��,�ԕi)
      -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,itp.item_id                      item_id
            ,itp.lot_id                       lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,xxcmn_rcv_shipment_lines_arc     rsl
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
             ,gmi_item_categories    gic_h
             ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
      AND    xola.order_header_id    = xoha.order_header_id
-- 2009/11/12 Add Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Add End
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '3'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('201','203')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_02       IS NOT NULL
-- 2009/11/12 Add Start
      AND    mcb_h.segment1 = '5'
      AND    gic_h.category_id         = mcb_h.category_id
      AND    gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND    itp.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
      -- ���̑�
      -- ----------------------------------------------------
      -- PORC8 :�o���󕥋敪�w���֘A (���{,�p�p)
      -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,itp.item_id                      item_id
            ,itp.lot_id                       lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,xxcmn_rcv_shipment_lines_arc     rsl
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
             ,gmi_item_categories    gic_h
             ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
      AND    xola.order_header_id    = xoha.order_header_id
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_02       IS NOT NULL
-- 2009/11/12 Add Start
      AND    mcb_h.segment1 = '5'
      AND    gic_h.category_id         = mcb_h.category_id
      AND    gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND    itp.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
    -- ----------------------------------------------------
    -- PORC :�o���󕥋敪�w���֘A�i�d���j
    -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,itp.item_id                      item_id
            ,itp.lot_id                       lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,itp.trans_date                   trans_date
      FROM   ic_tran_pnd                      itp
            ,rcv_shipment_lines               rsl
            ,rcv_transactions                 rt
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
             ,gmi_item_categories    gic_h
             ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
-- 2009/12/17 T.Yoshimoto Add Start
      AND    itp.trans_date         >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    itp.trans_date         <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    rsl.source_document_code = 'PO'
      AND    rt.transaction_id       = itp.line_id
      AND    rt.shipment_line_id     = rsl.shipment_line_id
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = rsl.source_document_code
      AND    xrpm.transaction_type   = rt.transaction_type
      AND    xrpm.break_col_02       IS NOT NULL
-- 2009/11/12 Add Start
      AND  mcb_h.segment1 = '5'
      AND  gic_h.category_id         = mcb_h.category_id
      AND  gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND  itp.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
    -- �L���E���_
    -- ----------------------------------------------------
    -- OMSO1 :�o���󕥋敪�󒍊֘A (���i�o��,�L��)
    -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,itp.item_id                      item_id
            ,itp.lot_id                       lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,wsh_delivery_details             wdd
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
             ,gmi_item_categories    gic_h
             ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itp.doc_type            = 'OMSO'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    otta.attribute1         IN ('1','2')
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
      AND    xola.order_header_id    = xoha.order_header_id
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    xrpm.item_div_ahead     = '5'
      AND    xoha.req_status        IN ('04','08')
      AND    xola.request_item_code  = xola.shipping_item_code
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('102','103')
      AND    xrpm.shipment_provision_div = DECODE(xoha.req_status,'04','1','08','2')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ((xrpm.ship_prov_rcv_pay_category IS NULL)
             OR (xrpm.ship_prov_rcv_pay_category = otta.attribute11))
      AND    xrpm.break_col_02       IS NOT NULL
-- 2009/11/12 Add Start
      AND  mcb_h.segment1 = '5'
      AND  gic_h.category_id         = mcb_h.category_id
      AND  gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND  itp.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
    -- �U�֓��ɁE�U�֗L��
    -- ----------------------------------------------------
    -- OMSO2 :�o���󕥋敪�󒍊֘A (�U�֗L��)
    -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,iimb.item_id                     item_id
            ,itp.lot_id                       lot_id
            ,CASE WHEN xrpm.dealings_div_name IN ('�U�֗L��_���'
                                                 ,'���i�U�֗L��_���'
                                                 ,'�U�֏o��_���_��'
                                                 ,'�U�֏o��_���_��')
                       THEN itp.trans_qty * TO_NUMBER('-1')
                  ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
             END                              trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,wsh_delivery_details             wdd
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_item_mst_b                    iimb
            ,xxskz_item_class_v               xicv1
            ,xxskz_item_class_v               xicv2
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    iimb.item_no            = xola.request_item_code
      AND    xicv1.item_id           = iimb.item_id
      AND    xrpm.item_div_ahead     = xicv1.item_class_code
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xicv1.item_class_code   = '5'
-- 2009/12/17 T.Yoshimoto Add End
      AND    xicv2.item_id            = itp.item_id
      AND    xicv2.item_class_code    <> '5'
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('104','105')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_02       IS NOT NULL
      UNION ALL
    -- �h�����N�M�t�g���o
    -- ----------------------------------------------------
    -- OMSO3 :�o���󕥋敪�󒍊֘A (���i�U�֗L��)
    -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,iimb.item_id                     item_id
            ,itp.lot_id                       lot_id
            ,CASE WHEN xrpm.dealings_div_name IN ('�U�֗L��_���'
                                                 ,'���i�U�֗L��_���'
                                                 ,'�U�֏o��_���_��'
                                                 ,'�U�֏o��_���_��')
                       THEN itp.trans_qty * TO_NUMBER('-1')
                  ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
             END                              trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,wsh_delivery_details             wdd
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_item_mst_b                    iimb
            ,xxskz_prod_class_v               prdc1  --�U�֑O�i�� ���i�敪
            ,xxskz_item_class_v               itmc1  --�U�֑O�i�� �i�ڋ敪
            ,xxskz_prod_class_v               prdc2  --�U�֌�i�� ���i�敪
            ,xxskz_item_class_v               itmc2  --�U�֌�i�� ���i�敪
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    iimb.item_no            = xola.request_item_code
      AND    prdc1.item_id           = iimb.item_id
      AND    xrpm.prod_div_ahead     = prdc1.prod_class_code
      AND    itmc1.item_id           = iimb.item_id
      AND    xrpm.item_div_ahead     = itmc1.item_class_code
-- 2009/12/17 T.Yoshimoto Add Start
      AND    itmc1.item_class_code   = '5'
-- 2009/12/17 T.Yoshimoto Add End
      AND    prdc2.item_id           = itp.item_id
      AND    xrpm.prod_div_origin    = prdc2.prod_class_code
      AND    itmc2.item_id           = itp.item_id
      AND    xrpm.item_div_origin    = itmc2.item_class_code
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2009/11/12 Del Start
      --AND    ooha.header_id          = xoha.header_id
-- 2009/11/12 Del End
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod Start
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('107','108')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_02       IS NOT NULL
      UNION ALL
    -- ���̑�
    -- ----------------------------------------------------
    -- OMSO4 :�o���󕥋敪�󒍊֘A (���i�U�֗L���A���o)
    -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,itp.item_id                      item_id
            ,itp.lot_id                       lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,wsh_delivery_details             wdd
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
            ,xxskz_prod_class_v               prdc
            ,xxskz_item_class_v               itmc
      WHERE  itp.doc_type            = 'OMSO'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    prdc.item_id            = itp.item_id
      AND    xrpm.prod_div_origin    = prdc.prod_class_code
      AND    itmc.item_id            = itp.item_id
      AND    xrpm.item_div_origin    = itmc.item_class_code
-- 2009/12/17 T.Yoshimoto Add Start
      AND    itmc.item_class_code    = '5'
-- 2009/12/17 T.Yoshimoto Add End
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '2'
      AND    xoha.req_status         = '08'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       = '109'
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_02       IS NOT NULL
      UNION ALL
    -- ���_
    -- ----------------------------------------------------
    -- OMSO5 :�o���󕥋敪�󒍊֘A (�U�֏o�ׁA�o��)
    -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,iimb.item_id                     item_id
            ,itp.lot_id                       lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,wsh_delivery_details             wdd
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_item_mst_b                    iimb
            ,xxskz_item_class_v               xicv
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    iimb.item_no            = xola.request_item_code
      AND    xicv.item_id            = iimb.item_id
      AND    xrpm.item_div_ahead     = xicv.item_class_code
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xicv.item_class_code    = '5'
-- 2009/12/17 T.Yoshimoto Add End
      AND    xola.request_item_code  <> xola.shipping_item_code
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.header_id          = wdd.source_header_id
      AND    xoha.req_status         = '04'
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       = '112'
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_02       IS NOT NULL
      UNION ALL
    -- �Ήc�P�E�Ήc�Q
    -- ----------------------------------------------------
    -- OMSO6 :�o���󕥋敪�󒍊֘A (�U�֏o�ׁA���_�����A���_��)
    -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,iimb.item_id                     item_id
            ,itp.lot_id                       lot_id
            ,CASE WHEN xrpm.dealings_div_name IN ('�U�֗L��_���'
                                                 ,'���i�U�֗L��_���'
                                                 ,'�U�֏o��_���_��'
                                                 ,'�U�֏o��_���_��')
                       THEN itp.trans_qty * TO_NUMBER('-1')
                  ELSE itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)
             END                              trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,wsh_delivery_details             wdd
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
            ,ic_item_mst_b                    iimb
            ,xxskz_item_class_v               xicv1
            ,xxskz_item_class_v               xicv2
      WHERE  itp.doc_type            = xrpm.doc_type
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    iimb.item_no            = xola.request_item_code
      AND    xicv1.item_id           = iimb.item_id
      AND    xrpm.item_div_ahead     = xicv1.item_class_code
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xicv1.item_class_code   = '5'
-- 2009/12/17 T.Yoshimoto Add End
      AND    xicv2.item_id            = itp.item_id
      AND    xicv2.item_class_code    IN ('1','4')
      AND    xrpm.item_div_origin    = xicv2.item_class_code
      AND    xrpm.item_div_origin    = xicv2.item_class_code
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.order_header_id    = xoha.order_header_id
      AND    xola.line_id            = wdd.source_line_id
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '1'
      AND    xoha.req_status         = '04'
      AND    xrpm.doc_type           = 'OMSO'
      AND    xrpm.dealings_div       IN ('110','111')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.break_col_02       IS NOT NULL
      UNION ALL
    -- �ԕi
    -- ----------------------------------------------------
    -- OMSO7 :�o���󕥋敪�󒍊֘A (�q��,�ԕi)
    -- ----------------------------------------------------
      SELECT
             itp.whse_code                    whse_code
            ,itp.item_id                      item_id
            ,itp.lot_id                       lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,wsh_delivery_details             wdd
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
            ,gmi_item_categories    gic_h
            ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itp.doc_type            = 'OMSO'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/21 T.Yoshimoto Add Start
      AND    xoha.req_status         = '04'
-- 2009/12/21 T.Yoshimoto Add End
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    wdd.source_header_id    = xoha.header_id
      AND    wdd.source_line_id      = xola.line_id
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
      AND    xola.order_header_id    = xoha.order_header_id
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    ((otta.attribute4           <> '2')
             OR  (otta.attribute4       IS NULL))
      AND    otta.attribute1         = '3'
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('201','203')
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_02       IS NOT NULL
-- 2009/11/12 Add Start
      AND  mcb_h.segment1 = '5'
      AND  gic_h.category_id         = mcb_h.category_id
      AND  gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND  itp.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
    -- ���̑�
    -- ----------------------------------------------------
    -- OMSO8 :�o���󕥋敪�󒍊֘A (���{,�p�p)
    -- ----------------------------------------------------
      SELECT 
             itp.whse_code                    whse_code
            ,itp.item_id                      item_id
            ,itp.lot_id                       lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,wsh_delivery_details             wdd
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
             ,gmi_item_categories    gic_h
             ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itp.doc_type            = 'OMSO'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/21 T.Yoshimoto Add Start
      AND    xoha.req_status         = '04'
-- 2009/12/21 T.Yoshimoto Add End
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    wdd.delivery_detail_id  = itp.line_detail_id
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
-- 2009/12/21 T.Yoshimoto Add Start
      AND    otta.attribute1 = '1'
-- 2009/12/21 T.Yoshimoto Add End
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_02       IS NOT NULL
-- 2009/11/12 Add Start
      AND  mcb_h.segment1 = '5'
      AND  gic_h.category_id         = mcb_h.category_id
      AND  gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND  itp.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
      -- �q�Ɉړ�
      -- ----------------------------------------------------
      -- XFER :�o���󕥋敪�ړ��ϑ�����
      -- ----------------------------------------------------
      SELECT
             itp.whse_code              whse_code
            ,itp.item_id                item_id
            ,itp.lot_id                 lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,xmrih.actual_arrival_date  trans_date
      FROM   xxcmn_ic_tran_pnd_arc          itp
            ,ic_xfer_mst                    ixm
            ,xxcmn_mov_req_instr_lines_arc  xmril
            ,xxcmn_mov_req_instr_hdrs_arc   xmrih
            ,xxcmn_rcv_pay_mst              xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
             ,gmi_item_categories    gic_h
             ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itp.doc_type            = 'XFER'
      AND    itp.completed_ind       = 1
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xmrih.actual_arrival_date  >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xmrih.actual_arrival_date  <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    ixm.transfer_id         = itp.doc_id
-- 2009/12/21 T.Yoshimoto Mod Start
--      AND    ixm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    xmril.mov_line_id       = TO_NUMBER(ixm.attribute1)
-- 2009/12/21 T.Yoshimoto Mod End
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itp.trans_qty >= 0
                                         THEN '1'
                                         ELSE '-1'
                                       END
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.reason_code        = itp.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/11/12 Add Start
      AND  mcb_h.segment1 = '5'
      AND  gic_h.category_id         = mcb_h.category_id
      AND  gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND  itp.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
      -- �q�Ɉړ�
      -- ----------------------------------------------------
      -- TRNI :�o���󕥋敪�ړ��ϑ��Ȃ�
      -- ----------------------------------------------------
      SELECT
             itc.whse_code              whse_code
            ,itc.item_id                item_id
            ,itc.lot_id                 lot_id
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,xmrih.actual_arrival_date        trans_date
      FROM   xxcmn_ic_tran_cmp_arc          itc
            ,ic_adjs_jnl                    iaj
            ,ic_jrnl_mst                    ijm
            ,xxcmn_mov_req_instr_lines_arc  xmril
            ,xxcmn_mov_req_instr_hdrs_arc   xmrih
            ,xxcmn_rcv_pay_mst              xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
             ,gmi_item_categories    gic_h
             ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itc.doc_type            = 'TRNI'
      AND    itc.reason_code         = 'X122'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xmrih.actual_arrival_date  >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xmrih.actual_arrival_date  <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    xmrih.mov_hdr_id        = xmril.mov_hdr_id
      AND    iaj.trans_type          = itc.doc_type
      AND    itc.doc_id              = iaj.doc_id
      AND    itc.doc_line            = iaj.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2009/12/21 T.Yoshimoto Mod Start
--      AND    ijm.attribute1          = TO_CHAR(xmril.mov_line_id)
      AND    xmril.mov_line_id       = TO_NUMBER(ijm.attribute1)
-- 2009/12/21 T.Yoshimoto Mod End
      AND    xrpm.rcv_pay_div        = CASE
                                       WHEN itc.trans_qty >= 0 THEN 1
                                       ELSE -1
                                       END
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/11/12 Add Start
      AND    mcb_h.segment1 = '5'
      AND    gic_h.category_id         = mcb_h.category_id
      AND    gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND    itc.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
      -- �p�p�E���{�E�������o�E�I������
      -- ----------------------------------------------------
      -- ADJI :�o���󕥋敪�݌ɒ���(��)
      -- ----------------------------------------------------
      SELECT
             itc.whse_code              whse_code
            ,itc.item_id                item_id
            ,itc.lot_id                 lot_id
            ,CASE WHEN xrpm.rcv_pay_div = '-1'
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
                  WHEN xrpm.rcv_pay_div = '1' AND itc.reason_code = 'X911'
                  THEN NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div) * -1
                  ELSE NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)
             END                        trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,itc.trans_date             trans_date
      FROM   xxcmn_ic_tran_cmp_arc      itc
            ,xxcmn_rcv_pay_mst          xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
             ,gmi_item_categories    gic_h
             ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itc.doc_type          = 'ADJI'
      AND    itc.reason_code       IN ('X911'
                                      ,'X912'
                                      ,'X921'
                                      ,'X922'
                                      ,'X931'
                                      ,'X932'
                                      ,'X941'
                                      ,'X952'
                                      ,'X953'
                                      ,'X954'
                                      ,'X955'
                                      ,'X956'
                                      ,'X957'
                                      ,'X958'
                                      ,'X959'
                                      ,'X960'
                                      ,'X961'
                                      ,'X962'
                                      ,'X963'
                                      ,'X964'
                                      ,'X965'
                                      ,'X966'
                                      )
-- 2009/12/17 T.Yoshimoto Add Start
      AND    itc.trans_date         >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    itc.trans_date         <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/11/12 Add Start
      AND    mcb_h.segment1 = '5'
      AND    gic_h.category_id         = mcb_h.category_id
      AND    gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND    itc.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
      -- �d����ԕi
      -- ----------------------------------------------------
      -- ADJI :�o���󕥋敪�݌ɒ���(�d��)
      -- ----------------------------------------------------
      SELECT
             itc.whse_code                    whse_code
            ,itc.item_id                      item_id
            ,itc.lot_id                       lot_id
            ,itc.trans_qty * ABS(TO_NUMBER(xrpm.rcv_pay_div)) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_02,'-') = 0
                  THEN ''
                  WHEN xrpm.rcv_pay_div = '1'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  WHEN xrpm.dealings_div_name = '�d��'
                  THEN SUBSTR(xrpm.break_col_02,1,INSTR(xrpm.break_col_02,'-')-1)
                  ELSE SUBSTR(xrpm.break_col_02,INSTR(xrpm.break_col_02,'-')+1)
             END                              column_no
            ,itc.trans_date                   trans_date
      FROM   xxcmn_ic_tran_cmp_arc            itc
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/11/12 Add Start
            -- �i�ڋ敪
            ,gmi_item_categories    gic_h
            ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itc.doc_type            = 'ADJI'
      AND    itc.reason_code         = 'X201'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    itc.trans_date         >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    itc.trans_date         <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_02       IS NOT NULL
-- 2009/11/12 Add Start
      AND    mcb_h.segment1 = '5'
      AND    gic_h.category_id         = mcb_h.category_id
      AND    gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND    itc.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
      -- �l��
      -- ----------------------------------------------------
      -- ADJI :�o���󕥋敪�݌ɒ���(�l��)
      -- ----------------------------------------------------
      SELECT
             itc.whse_code              whse_code
            ,itc.item_id                item_id
            ,itc.lot_id                 lot_id
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,itc.trans_date             trans_date
      FROM   xxcmn_ic_tran_cmp_arc      itc
            ,xxcmn_rcv_pay_mst          xrpm
-- 2009/11/12 Add Start
            -- �i�ڋ敪
            ,gmi_item_categories    gic_h
            ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itc.doc_type            = 'ADJI'
      AND    itc.reason_code         = 'X988'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    itc.trans_date         >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    itc.trans_date         <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/11/12 Add Start
      AND    mcb_h.segment1 = '5'
      AND    gic_h.category_id         = mcb_h.category_id
      AND    gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND    itc.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
      -- ----------------------------------------------------
      -- ADJI :�o���󕥋敪�݌ɒ���(�ړ�)
      -- ----------------------------------------------------
      SELECT
             itc.whse_code              whse_code
            ,itc.item_id                item_id
            ,itc.lot_id                 lot_id
            ,NVL(itc.trans_qty,0) * TO_NUMBER(xrpm.rcv_pay_div)  trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,xmrih.actual_arrival_date  trans_date
      FROM   xxcmn_ic_tran_cmp_arc          itc
            ,ic_adjs_jnl                    iaj
            ,ic_jrnl_mst                    ijm
            ,xxcmn_mov_req_instr_lines_arc  xmrl
            ,xxcmn_mov_req_instr_hdrs_arc   xmrih
            ,xxcmn_rcv_pay_mst              xrpm
-- 2009/11/12 Add Start
            -- �i�ڋ敪
            ,gmi_item_categories    gic_h
            ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itc.doc_type            = 'ADJI'
      AND    itc.reason_code         = 'X123'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xmrih.actual_arrival_date  >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xmrih.actual_arrival_date  <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    xmrih.mov_hdr_id        = xmrl.mov_hdr_id
      AND    iaj.trans_type          = itc.doc_type
      AND    iaj.doc_id              = itc.doc_id
      AND    iaj.doc_line            = itc.doc_line
      AND    ijm.journal_id          = iaj.journal_id
-- 2009/12/21 T.Yoshimoto Mod Start
--      AND    ijm.attribute1          = TO_CHAR(xmrl.mov_line_id)
      AND    xmrl.mov_line_id       = TO_NUMBER(ijm.attribute1)
-- 2009/12/21 T.Yoshimoto Mod End
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.rcv_pay_div        = CASE
                                         WHEN itc.trans_qty >= 0
                                         THEN '-1'
                                         WHEN itc.trans_qty <  0
                                         THEN '1'
                                         ELSE xrpm.rcv_pay_div
                                       END
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/11/12 Add Start
      AND    mcb_h.segment1 = '5'
      AND    gic_h.category_id         = mcb_h.category_id
      AND    gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND    itc.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
      -- ���̑�
      -- ----------------------------------------------------
      -- ADJI :�o���󕥋敪�݌ɒ���(���̑����o)
      -- ----------------------------------------------------
      SELECT
             itc.whse_code              whse_code
            ,itc.item_id                item_id
            ,itc.lot_id                 lot_id
            ,itc.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,itc.trans_date             trans_date
      FROM   xxcmn_ic_tran_cmp_arc      itc
            ,xxcmn_rcv_pay_mst          xrpm
-- 2009/11/12 Add Start
            -- �i�ڋ敪
            ,gmi_item_categories    gic_h
            ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itc.doc_type            = 'ADJI'
      AND    itc.reason_code        IN ('X942','X943','X950','X951')
-- 2009/12/17 T.Yoshimoto Add Start
      AND    itc.trans_date         >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    itc.trans_date         <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    xrpm.doc_type           = itc.doc_type
      AND    xrpm.reason_code        = itc.reason_code
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/11/12 Add Start
      AND  mcb_h.segment1 = '5'
      AND  gic_h.category_id         = mcb_h.category_id
      AND  gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND  itc.item_id               = gic_h.item_id
-- 2009/11/12 Add End
-- 2009/12/17 T.Yoshimoto Del Start
--      UNION ALL
--      -- �i��ړ�
--      -- ----------------------------------------------------
--      -- PROD :�o���󕥋敪���Y�֘A�iReverse_id�Ȃ��j�i��E�i�ڐU�ւȂ�
--      -- ----------------------------------------------------
--      SELECT
--             itp.whse_code              whse_code
--            ,itp.item_id                item_id
--            ,itp.lot_id                 lot_id
--            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
--            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
--                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
--                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
--                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
--                       END
--                  ELSE xrpm.break_col_03
--             END                              column_no
--            ,itp.trans_date             trans_date
--      FROM   ic_tran_pnd                itp
--            ,xxcmn_gme_material_details_arc  gmd
--            ,xxcmn_gme_batch_header_arc      gbh
--            ,gmd_routings_b                  grb
--            ,xxcmn_rcv_pay_mst               xrpm
--      WHERE  itp.doc_type            = 'PROD'
--      AND    itp.completed_ind       = 1
--      AND    itp.reverse_id          IS NULL
--      AND    gmd.batch_id            = itp.doc_id
--      AND    gmd.line_no             = itp.doc_line
--      AND    gmd.line_type           = itp.line_type
--      AND    gbh.batch_id            = gmd.batch_id
--      AND    grb.routing_id          = gbh.routing_id
--      AND    xrpm.routing_class      = grb.routing_class
--      AND    xrpm.line_type          = gmd.line_type
--      AND    (((gmd.attribute5 IS NULL) AND (xrpm.hit_in_div IS NULL))
--             OR (xrpm.hit_in_div = gmd.attribute5))
--      AND    itp.doc_type            = xrpm.doc_type
--      AND    itp.line_type           = xrpm.line_type
--      AND    xrpm.break_col_03       IS NOT NULL
--      AND    xrpm.dealings_div       = '309'
--      AND    (EXISTS (SELECT 1
--                      FROM   xxcmn_gme_material_details_arc gmd2
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd2.batch_id   = gmd.batch_id
--                      AND    gmd2.line_no    = gmd.line_no
--                      AND    gmd2.line_type  = -1
--                      AND    gic.item_id     = gmd2.item_id
--                      AND    gic.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_origin))
--      AND    (EXISTS (SELECT 1
--                      FROM   xxcmn_gme_material_details_arc gmd3
--                            ,gmi_item_categories  gic
--                            ,mtl_categories_b     mcb
--                      WHERE  gmd3.batch_id   = gmd.batch_id
--                      AND    gmd3.line_no    = gmd.line_no
--                      AND    gmd3.line_type  = 1
--                      AND    gic.item_id     = gmd3.item_id
--                      AND    gic.category_set_id = TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'))
--                      AND    gic.category_id = mcb.category_id
--                      AND    mcb.segment1    = xrpm.item_div_ahead))
-- 2009/12/17 T.Yoshimoto Del End
      UNION ALL
    -- �p�p�E���{
    -- ----------------------------------------------------
    -- OMSO8 :�o���󕥋敪�󒍊֘A (���{,�p�p)
    -- ----------------------------------------------------
      SELECT
             itp.whse_code              whse_code
            ,itp.item_id                item_id
            ,itp.lot_id                 lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,wsh_delivery_details             wdd
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
             ,gmi_item_categories    gic_h
             ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itp.doc_type            = 'OMSO'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/21 T.Yoshimoto Add Start
      AND    xoha.req_status         = '04'
-- 2009/12/21 T.Yoshimoto Add End
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    wdd.delivery_detail_id  = itp.line_detail_id
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
-- 2009/12/21 T.Yoshimoto Add Start
      AND    otta.attribute1 = '1'
-- 2009/12/21 T.Yoshimoto Add End
      AND    xoha.header_id          = wdd.source_header_id
      AND    xola.line_id            = wdd.source_line_id
      AND    xola.order_header_id    = xoha.order_header_id
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/11/12 Add Start
      AND    mcb_h.segment1 = '5'
      AND    gic_h.category_id         = mcb_h.category_id
      AND    gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND    itp.item_id               = gic_h.item_id
-- 2009/11/12 Add End
      UNION ALL
      -- �p�p�E���{
      -- ----------------------------------------------------
      -- PORC8 :�o���󕥋敪�w���֘A (���{,�p�p)
      -- ----------------------------------------------------
      SELECT
             itp.whse_code              whse_code
            ,itp.item_id                item_id
            ,itp.lot_id                 lot_id
            ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div) trans_qty
            ,CASE WHEN INSTR(xrpm.break_col_03,'-') > 0
                  THEN CASE WHEN xrpm.rcv_pay_div = '1'
                            THEN TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, 1, INSTR(xrpm.break_col_03,'-') - 1)) + 19)
                            ELSE TO_CHAR(TO_NUMBER(SUBSTR(xrpm.break_col_03, INSTR(xrpm.break_col_03,'-') + 1 )) + 19)
                       END
                  ELSE xrpm.break_col_03
             END                              column_no
            ,xoha.arrival_date                trans_date
      FROM   xxcmn_ic_tran_pnd_arc            itp
            ,xxcmn_rcv_shipment_lines_arc     rsl
-- 2009/11/12 Del Start
            --,oe_order_headers_all             ooha
-- 2009/11/12 Del End
            ,oe_transaction_types_all         otta
            ,xxcmn_order_headers_all_arc      xoha
            ,xxcmn_order_lines_all_arc        xola
            ,xxcmn_rcv_pay_mst                xrpm
-- 2009/11/12 Add Start
             -- �i�ڋ敪
             ,gmi_item_categories    gic_h
             ,mtl_categories_b       mcb_h
-- 2009/11/12 Add End
      WHERE  itp.doc_type            = 'PORC'
      AND    itp.completed_ind       = 1
      AND    xoha.latest_external_flag = 'Y'
-- 2009/12/17 T.Yoshimoto Add Start
      AND    xoha.arrival_date      >= ADD_MONTHS(trunc(sysdate,'MM'), -2)
      AND    xoha.arrival_date      <  ADD_MONTHS(trunc(sysdate,'MM'),  1)
-- 2009/12/17 T.Yoshimoto Add End
      AND    rsl.shipment_header_id  = itp.doc_id
      AND    rsl.line_num            = itp.doc_line
      AND    xoha.header_id          = rsl.oe_order_header_id
      AND    xola.line_id            = rsl.oe_order_line_id
-- 2009/11/12 Del Start
      --AND    xoha.header_id          = ooha.header_id
-- 2009/11/12 Del End
      AND    xola.order_header_id    = xoha.order_header_id
-- 2009/11/12 Mod Start
      --AND    otta.transaction_type_id = ooha.order_type_id
      AND    otta.transaction_type_id = xoha.order_type_id
-- 2009/11/12 Mod End
      AND    xrpm.doc_type           = itp.doc_type
      AND    xrpm.source_document_code = 'RMA'
      AND    xrpm.dealings_div       IN ('504','509')
      AND    xrpm.stock_adjustment_div = otta.attribute4
      AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
      AND    xrpm.break_col_03       IS NOT NULL
-- 2009/11/12 Add Start
      AND  mcb_h.segment1 = '5'
      AND  gic_h.category_id         = mcb_h.category_id
      AND  gic_h.category_set_id     = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
      AND  itp.item_id               = gic_h.item_id
-- 2009/11/12 Add End
    --****************************************************************************
    -- �Ώۂ̃f�[�^���擾 END
    --****************************************************************************
/
COMMENT ON TABLE APPS.XXSKZ_UH_GOODS2_V IS 'XXSKZ_�󕥏��_���i_����VIEW2'
/
COMMENT ON COLUMN APPS.XXSKZ_UH_GOODS2_V.whse_code  IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_UH_GOODS2_V.item_id    IS '�i��ID'
/
COMMENT ON COLUMN APPS.XXSKZ_UH_GOODS2_V.lot_id     IS '���b�gID'
/
COMMENT ON COLUMN APPS.XXSKZ_UH_GOODS2_V.trans_qty  IS '�󕥐�'
/
COMMENT ON COLUMN APPS.XXSKZ_UH_GOODS2_V.column_no  IS '���ڔԍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_UH_GOODS2_V.trans_date IS '�����'
/
