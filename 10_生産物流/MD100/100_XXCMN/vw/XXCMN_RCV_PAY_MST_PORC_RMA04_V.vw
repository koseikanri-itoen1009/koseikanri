/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCMN_RCV_PAY_MST_PORC_RMA04_V
 * Description     : oó¥æªîñVIEW_wÖA_o×(for XXCMN770004C)
 * Version         : 1.7
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-08-07    1.0   R.Tomoyose       VKì¬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCMN_RCV_PAY_MST_PORC_RMA04_V
    (NEW_DIV_ACCOUNT,DEALINGS_DIV,RCV_PAY_DIV,DOC_TYPE,DOC_ID,DOC_LINE,RESULT_POST,
     ITEM_ID,ITEM_DIV,PROD_DIV,DEALINGS_DIV_NAME)
AS
SELECT  xrpm.new_div_account            AS new_div_account            -- Voó¥æª
       ,xrpm.dealings_div               AS dealings_div               -- æøæª
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- ó¥æª
       ,xrpm.doc_type                   AS doc_type                   -- ¶^Cv
       ,rsl.shipment_header_id          AS doc_id                     -- ¶ID
       ,rsl.line_num                    AS doc_line                   -- æø¾×Ô
       ,ooha.attribute11                AS result_post                -- ¬Ñ
       ,NULL                            AS item_id                    -- iÚID
       ,mcb_a2.segment1                 AS item_div                   -- iÚæª
       ,mcb_a1.segment1                 AS prod_div                   -- ¤iæª
       ,xlvv.meaning                    AS dealings_div_name          -- æøæª¼
 FROM   xxcmn_rcv_pay_mst        xrpm    -- ó¥æª}X^
       ,rcv_shipment_lines       rsl     -- óü¾×
       ,oe_order_headers_all     ooha    -- ówb_
       ,oe_order_lines_all       oola    -- ó¾×
       ,oe_transaction_types_all otta    -- ó^Cv
       ,ic_item_mst_b          iimb_a    -- iÚîñ
       ,gmi_item_categories    gic_a1    -- iÚ¤iæªJeSîñ
       ,mtl_categories_b       mcb_a1    -- iÚ¤iæªJeSîñ
       ,gmi_item_categories    gic_a2    -- iÚiÚæªJeSîñ
       ,mtl_categories_b       mcb_a2    -- iÚiÚæªJeSîñ
       ,xxwsh_order_headers_all  xoha    -- ówb_AhI
       ,xxwsh_order_lines_all    xola    -- ó¾×AhI
       ,xxcmn_lookup_values_v    xlvv    -- NCbNR[hr[LOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('»io×','L')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = rsl.oe_order_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND oola.line_id              = rsl.oe_order_line_id
  AND oola.line_id              = xola.line_id
  AND xola.request_item_code    = xola.shipping_item_code
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_a.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- ÝÉ²®ÈO
      OR  (otta.attribute4       IS NULL))        -- ÝÉ²®ÈO
  AND NVL( xrpm.ship_prov_rcv_pay_category, NVL( otta.attribute11, 'NULL' ) ) =
      NVL( otta.attribute11, 'NULL' )
  AND xrpm.item_div_ahead      IS NOT NULL
  AND xrpm.item_div_origin     IS NOT NULL
  AND xrpm.prod_div_ahead      IS NULL
  AND xrpm.prod_div_origin     IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND xrpm.item_div_origin = mcb_a2.segment1
  -- ¤iæªJeSæ¾îñ
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- iÚæªJeSæ¾îñ
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- Voó¥æª
       ,xrpm.dealings_div               AS dealings_div               -- æøæª
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- ó¥æª
       ,xrpm.doc_type                   AS doc_type                   -- ¶^Cv
       ,rsl.shipment_header_id          AS doc_id                     -- ¶ID
       ,rsl.line_num                    AS doc_line                   -- æø¾×Ô
       ,ooha.attribute11                AS result_post                -- ¬Ñ
       ,NULL                            AS item_id                    -- iÚID
       ,mcb_a2.segment1                 AS item_div                   -- iÚæª
       ,mcb_a1.segment1                 AS prod_div                   -- ¤iæª
       ,xlvv.meaning                    AS dealings_div_name          -- æøæª¼
 FROM   xxcmn_rcv_pay_mst        xrpm    -- ó¥æª}X^
       ,rcv_shipment_lines       rsl     -- óü¾×
       ,oe_order_headers_all     ooha    -- ówb_
       ,oe_order_lines_all       oola    -- ó¾×
       ,oe_transaction_types_all otta    -- ó^Cv
       ,ic_item_mst_b          iimb_a    -- iÚîñ
       ,gmi_item_categories    gic_a1    -- iÚ¤iæªJeSîñ
       ,mtl_categories_b       mcb_a1    -- iÚ¤iæªJeSîñ
       ,gmi_item_categories    gic_a2    -- iÚiÚæªJeSîñ
       ,mtl_categories_b       mcb_a2    -- iÚiÚæªJeSîñ
       ,xxwsh_order_headers_all  xoha    -- ówb_AhI
       ,xxwsh_order_lines_all    xola    -- ó¾×AhI
       ,xxcmn_lookup_values_v    xlvv    -- NCbNR[hr[LOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('Þo×','L')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = rsl.oe_order_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND oola.line_id              = rsl.oe_order_line_id
  AND oola.line_id              = xola.line_id
  AND xola.request_item_code    = xola.shipping_item_code
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_a.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- ÝÉ²®ÈO
      OR  (otta.attribute4       IS NULL))        -- ÝÉ²®ÈO
  AND NVL( xrpm.ship_prov_rcv_pay_category, NVL( otta.attribute11, 'NULL' ) ) =
      NVL( otta.attribute11, 'NULL' )
  AND xrpm.item_div_ahead      IS NULL
  AND xrpm.item_div_origin     IS NULL
  AND xrpm.prod_div_ahead      IS NULL
  AND xrpm.prod_div_origin     IS NULL
  AND mcb_a2.segment1  <> '5'   -- »iÈO
  -- ¤iæªJeSæ¾îñ
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- iÚæªJeSæ¾îñ
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- Voó¥æª
       ,xrpm.dealings_div               AS dealings_div               -- æøæª
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- ó¥æª
       ,xrpm.doc_type                   AS doc_type                   -- ¶^Cv
       ,rsl.shipment_header_id          AS doc_id                     -- ¶ID
       ,rsl.line_num                    AS doc_line                   -- æø¾×Ô
       ,ooha.attribute11                AS result_post                -- ¬Ñ
       ,DECODE(xlvv.meaning,
                 'UÖL_óü',iimb_a.item_id,                      -- UÖæiÚID
                 'UÖL_o×',iimb_a.item_id,                      -- UÖæiÚID
                 'UÖL_¥o',iimb_o.item_id) AS item_id           -- UÖ³iÚID
       ,DECODE(xlvv.meaning,
                 'UÖL_óü',mcb_a2.segment1,                     -- UÖæiÚæª
                 'UÖL_o×',mcb_a2.segment1,                     -- UÖæiÚæª
                 'UÖL_¥o',mcb_o2.segment1) AS item_div         -- UÖ³iÚæª
       ,DECODE(xlvv.meaning,
                 'UÖL_óü',mcb_a1.segment1,                     -- UÖæ¤iæª
                 'UÖL_o×',mcb_a1.segment1,                     -- UÖæ¤iæª
                 'UÖL_¥o',mcb_o1.segment1) AS prod_div         -- UÖ³¤iæª
       ,xlvv.meaning                    AS dealings_div_name          -- æøæª¼
 FROM   xxcmn_rcv_pay_mst        xrpm    -- ó¥æª}X^
       ,rcv_shipment_lines       rsl     -- óü¾×
       ,oe_order_headers_all     ooha    -- ówb_
       ,oe_order_lines_all       oola    -- ó¾×
       ,oe_transaction_types_all otta    -- ó^Cv
       ,ic_item_mst_b          iimb_a    -- UÖæiÚîñ
       ,ic_item_mst_b          iimb_o    -- UÖ³iÚîñ
       ,gmi_item_categories    gic_a1    -- UÖæiÚ¤iæªJeSîñ
       ,mtl_categories_b       mcb_a1    -- UÖæiÚ¤iæªJeSîñ
       ,mtl_category_sets_tl   mcst_a1   -- UÖæiÚ¤iæªJeSîñ
       ,gmi_item_categories    gic_a2    -- UÖæiÚiÚæªJeSîñ
       ,mtl_categories_b       mcb_a2    -- UÖæiÚiÚæªJeSîñ
       ,mtl_category_sets_tl   mcst_a2   -- UÖæiÚiÚæªJeSîñ
       ,gmi_item_categories    gic_o1    -- UÖ³iÚ¤iæªJeSîñ
       ,mtl_categories_b       mcb_o1    -- UÖ³iÚ¤iæªJeSîñ
       ,mtl_category_sets_tl   mcst_o1   -- UÖ³iÚ¤iæªJeSîñ
       ,gmi_item_categories    gic_o2    -- UÖ³iÚiÚæªJeSîñ
       ,mtl_categories_b       mcb_o2    -- UÖ³iÚiÚæªJeSîñ
       ,mtl_category_sets_tl   mcst_o2   -- UÖ³iÚiÚæªJeSîñ
       ,xxwsh_order_headers_all  xoha    -- ówb_AhI
       ,xxwsh_order_lines_all    xola    -- ó¾×AhI
       ,xxcmn_lookup_values_v    xlvv    -- NCbNR[hr[LOOKUP_CODE
WHERE xrpm.doc_type               = 'PORC'
  AND xrpm.source_document_code   = 'RMA'
  AND xlvv.lookup_type            = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                IN ('UÖL_óü','UÖL_o×','UÖL_¥o')
  AND xrpm.dealings_div           = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id              = rsl.oe_order_header_id
  AND otta.transaction_type_id    = ooha.order_type_id
  AND xoha.header_id              = ooha.header_id
  AND oola.header_id              = ooha.header_id
  AND oola.line_id                = rsl.oe_order_line_id
  AND oola.line_id                = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- ÝÉ²®ÈO
      OR  (otta.attribute4       IS NULL))        -- ÝÉ²®ÈO
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  AND xrpm.item_div_ahead         IS NOT NULL
  AND xrpm.item_div_origin        IS NULL
  AND xrpm.prod_div_ahead         IS NULL
  AND xrpm.prod_div_origin        IS NULL
  AND xrpm.item_div_ahead         = mcb_a2.segment1
  AND mcb_o2.segment1          <> '5'   -- »iÈO
  -- UÖæ¤iæªJeSæ¾îñ
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- UÖæiÚæªJeSæ¾îñ
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
  -- UÖ³¤iæªJeSæ¾îñ
  AND gic_o1.category_set_id    = gic_a1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND iimb_o.item_id            = gic_o1.item_id
  -- UÖ³iÚæªJeSæ¾îñ
  AND gic_o2.category_set_id    = gic_a2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND iimb_o.item_id            = gic_o2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- Voó¥æª
       ,xrpm.dealings_div               AS dealings_div               -- æøæª
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- ó¥æª
       ,xrpm.doc_type                   AS doc_type                   -- ¶^Cv
       ,rsl.shipment_header_id          AS doc_id                     -- ¶ID
       ,rsl.line_num                    AS doc_line                   -- æø¾×Ô
       ,ooha.attribute11                AS result_post                -- ¬Ñ
       ,DECODE(xlvv.meaning,
                 '¤iUÖL_óü',iimb_a.item_id,                     -- UÖæiÚID
                 '¤iUÖL_o×',iimb_a.item_id,                     -- UÖæiÚID
                 '¤iUÖL_¥o',iimb_o.item_id) AS item_id          -- UÖ³iÚID
       ,DECODE(xlvv.meaning,
                 '¤iUÖL_óü',mcb_a2.segment1,             -- UÖæiÚæª
                 '¤iUÖL_o×',mcb_a2.segment1,             -- UÖæiÚæª
                 '¤iUÖL_¥o',mcb_o2.segment1) AS item_div -- UÖ³iÚæª
       ,DECODE(xlvv.meaning,
                 '¤iUÖL_óü',mcb_a1.segment1,             -- UÖæ¤iæª
                 '¤iUÖL_o×',mcb_a1.segment1,             -- UÖæ¤iæª
                 '¤iUÖL_¥o',mcb_o1.segment1) AS prod_div -- UÖ³¤iæª
       ,xlvv.meaning                    AS dealings_div_name          -- æøæª¼
 FROM   xxcmn_rcv_pay_mst        xrpm    -- ó¥æª}X^
       ,rcv_shipment_lines       rsl     -- óü¾×
       ,oe_order_headers_all     ooha    -- ówb_
       ,oe_order_lines_all       oola    -- ó¾×
       ,oe_transaction_types_all otta    -- ó^Cv
       ,ic_item_mst_b          iimb_a    -- UÖæiÚîñ
       ,ic_item_mst_b          iimb_o    -- UÖ³iÚîñ
       ,gmi_item_categories    gic_a1    -- UÖæiÚ¤iæªJeSîñ
       ,mtl_categories_b       mcb_a1    -- UÖæiÚ¤iæªJeSîñ
       ,mtl_category_sets_tl   mcst_a1   -- UÖæiÚ¤iæªJeSîñ
       ,gmi_item_categories    gic_a2    -- UÖæiÚiÚæªJeSîñ
       ,mtl_categories_b       mcb_a2    -- UÖæiÚiÚæªJeSîñ
       ,mtl_category_sets_tl   mcst_a2   -- UÖæiÚiÚæªJeSîñ
       ,gmi_item_categories    gic_o1    -- UÖ³iÚ¤iæªJeSîñ
       ,mtl_categories_b       mcb_o1    -- UÖ³iÚ¤iæªJeSîñ
       ,mtl_category_sets_tl   mcst_o1   -- UÖ³iÚ¤iæªJeSîñ
       ,gmi_item_categories    gic_o2    -- UÖ³iÚiÚæªJeSîñ
       ,mtl_categories_b       mcb_o2    -- UÖ³iÚiÚæªJeSîñ
       ,mtl_category_sets_tl   mcst_o2   -- UÖ³iÚiÚæªJeSîñ
       ,xxwsh_order_headers_all  xoha    -- ówb_AhI
       ,xxwsh_order_lines_all    xola    -- ó¾×AhI
       ,xxcmn_lookup_values_v    xlvv    -- NCbNR[hr[LOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('¤iUÖL_óü','¤iUÖL_o×','¤iUÖL_¥o')
  AND xrpm.dealings_div           = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id              = rsl.oe_order_header_id
  AND otta.transaction_type_id    = ooha.order_type_id
  AND xoha.header_id              = ooha.header_id
  AND oola.header_id              = ooha.header_id
  AND oola.line_id                = rsl.oe_order_line_id
  AND oola.line_id                = xola.line_id
  AND iimb_a.item_no           = xola.request_item_code
  AND iimb_o.item_no           = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- ÝÉ²®ÈO
      OR  (otta.attribute4       IS NULL))        -- ÝÉ²®ÈO
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  AND xrpm.item_div_ahead  IS NOT NULL
  AND xrpm.item_div_origin IS NOT NULL
  AND xrpm.prod_div_ahead  IS NOT NULL
  AND xrpm.prod_div_origin IS NOT NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND xrpm.item_div_origin = mcb_o2.segment1
  AND xrpm.prod_div_ahead  = mcb_a1.segment1
  AND xrpm.prod_div_origin = mcb_o1.segment1
  -- UÖæ¤iæªJeSæ¾îñ
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- UÖæiÚæªJeSæ¾îñ
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
  -- UÖ³¤iæªJeSæ¾îñ
  AND gic_o1.category_set_id    = gic_a1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND iimb_o.item_id            = gic_o1.item_id
  -- UÖ³iÚæªJeSæ¾îñ
  AND gic_o2.category_set_id    = gic_a2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND iimb_o.item_id            = gic_o2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- Voó¥æª
       ,xrpm.dealings_div               AS dealings_div               -- æøæª
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- ó¥æª
       ,xrpm.doc_type                   AS doc_type                   -- ¶^Cv
       ,rsl.shipment_header_id          AS doc_id                     -- ¶ID
       ,rsl.line_num                    AS doc_line                   -- æø¾×Ô
       ,ooha.attribute11                AS result_post                -- ¬Ñ
       ,DECODE(xlvv.meaning,
                 'UÖo×_óü_´',iimb_a.item_id,                  -- UÖæiÚID
                 'UÖo×_óü_¼',iimb_a.item_id,                  -- UÖæiÚID
                 'UÖo×_o×'   ,iimb_a.item_id,                  -- UÖæiÚID
                 'UÖo×_¥o'   ,iimb_o.item_id) AS item_id       -- UÖ³iÚID
       ,DECODE(xlvv.meaning,
                 'UÖo×_óü_´',mcb_a2.segment1,                 -- UÖæiÚæª
                 'UÖo×_óü_¼',mcb_a2.segment1,                 -- UÖæiÚæª
                 'UÖo×_o×'   ,mcb_a2.segment1,                 -- UÖæiÚæª
                 'UÖo×_¥o'   ,mcb_o2.segment1) AS item_div     -- UÖ³iÚæª
       ,DECODE(xlvv.meaning,
                 'UÖo×_óü_´',mcb_a1.segment1,                 -- UÖæ¤iæª
                 'UÖo×_óü_¼',mcb_a1.segment1,                 -- UÖæ¤iæª
                 'UÖo×_o×'   ,mcb_a1.segment1,                 -- UÖæ¤iæª
                 'UÖo×_¥o'   ,mcb_o1.segment1) AS prod_div     -- UÖ³¤iæª
       ,xlvv.meaning                    AS dealings_div_name          -- æøæª¼
 FROM   xxcmn_rcv_pay_mst        xrpm    -- ó¥æª}X^
       ,rcv_shipment_lines       rsl     -- óü¾×
       ,oe_order_headers_all     ooha    -- ówb_
       ,oe_order_lines_all       oola    -- ó¾×
       ,oe_transaction_types_all otta    -- ó^Cv
       ,ic_item_mst_b          iimb_a    -- UÖæiÚîñ
       ,ic_item_mst_b          iimb_o    -- UÖ³iÚîñ
       ,gmi_item_categories    gic_a1    -- UÖæiÚ¤iæªJeSîñ
       ,mtl_categories_b       mcb_a1    -- UÖæiÚ¤iæªJeSîñ
       ,mtl_category_sets_tl   mcst_a1   -- UÖæiÚ¤iæªJeSîñ
       ,gmi_item_categories    gic_a2    -- UÖæiÚiÚæªJeSîñ
       ,mtl_categories_b       mcb_a2    -- UÖæiÚiÚæªJeSîñ
       ,mtl_category_sets_tl   mcst_a2   -- UÖæiÚiÚæªJeSîñ
       ,gmi_item_categories    gic_o1    -- UÖ³iÚ¤iæªJeSîñ
       ,mtl_categories_b       mcb_o1    -- UÖ³iÚ¤iæªJeSîñ
       ,mtl_category_sets_tl   mcst_o1   -- UÖ³iÚ¤iæªJeSîñ
       ,gmi_item_categories    gic_o2    -- UÖ³iÚiÚæªJeSîñ
       ,mtl_categories_b       mcb_o2    -- UÖ³iÚiÚæªJeSîñ
       ,mtl_category_sets_tl   mcst_o2   -- UÖ³iÚiÚæªJeSîñ
       ,xxwsh_order_headers_all  xoha    -- ówb_AhI
       ,xxwsh_order_lines_all    xola    -- ó¾×AhI
       ,xxcmn_lookup_values_v    xlvv    -- NCbNR[hr[LOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('UÖo×_óü_´','UÖo×_óü_¼',
                                    'UÖo×_o×','UÖo×_¥o')
  AND xrpm.dealings_div           = xlvv.lookup_code
  AND xoha.req_status             = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id              = rsl.oe_order_header_id
  AND otta.transaction_type_id    = ooha.order_type_id
  AND xoha.header_id              = ooha.header_id
  AND oola.header_id              = ooha.header_id
  AND oola.line_id                = rsl.oe_order_line_id
  AND oola.line_id                = xola.line_id
  AND iimb_a.item_no              = xola.request_item_code
  AND iimb_o.item_no              = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- ÝÉ²®ÈO
      OR  (otta.attribute4       IS NULL))        -- ÝÉ²®ÈO
  AND xrpm.item_div_ahead  IS NOT NULL
  AND xrpm.item_div_origin IS NULL
  AND xrpm.prod_div_ahead  IS NULL
  AND xrpm.prod_div_origin IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND mcb_o2.segment1      <> '5'   -- »iÈO
  -- UÖæ¤iæªJeSæ¾îñ
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- UÖæiÚæªJeSæ¾îñ
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
  -- UÖ³¤iæªJeSæ¾îñ
  AND gic_o1.category_set_id    = gic_a1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND iimb_o.item_id            = gic_o1.item_id
  -- UÖ³iÚæªJeSæ¾îñ
  AND gic_o2.category_set_id    = gic_a2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND iimb_o.item_id            = gic_o2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- Voó¥æª
       ,xrpm.dealings_div               AS dealings_div               -- æøæª
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- ó¥æª
       ,xrpm.doc_type                   AS doc_type                   -- ¶^Cv
       ,rsl.shipment_header_id          AS doc_id                     -- ¶ID
       ,rsl.line_num                    AS doc_line                   -- æø¾×Ô
       ,ooha.attribute11                AS result_post                -- ¬Ñ
       ,DECODE(xlvv.meaning,
                 'UÖo×_óü_´',iimb_a.item_id,                   -- UÖæiÚID
                 'UÖo×_óü_¼',iimb_a.item_id,                   -- UÖæiÚID
                 'UÖo×_o×'   ,iimb_a.item_id,                   -- UÖæiÚID
                 'UÖo×_¥o'   ,iimb_o.item_id) AS item_id        -- UÖ³iÚID
       ,DECODE(xlvv.meaning,
                 'UÖo×_óü_´',mcb_a2.segment1,                  -- UÖæiÚæª
                 'UÖo×_óü_¼',mcb_a2.segment1,                  -- UÖæiÚæª
                 'UÖo×_o×'   ,mcb_a2.segment1,                  -- UÖæiÚæª
                 'UÖo×_¥o'   ,mcb_o2.segment1) AS item_div      -- UÖ³iÚæª
       ,DECODE(xlvv.meaning,
                 'UÖo×_óü_´',mcb_a1.segment1,                  -- UÖæ¤iæª
                 'UÖo×_óü_¼',mcb_a1.segment1,                  -- UÖæ¤iæª
                 'UÖo×_o×'   ,mcb_a1.segment1,                  -- UÖæ¤iæª
                 'UÖo×_¥o'   ,mcb_o1.segment1) AS prod_div      -- UÖ³¤iæª
       ,xlvv.meaning                    AS dealings_div_name          -- æøæª¼
 FROM   xxcmn_rcv_pay_mst        xrpm    -- ó¥æª}X^
       ,rcv_shipment_lines       rsl     -- óü¾×
       ,oe_order_headers_all     ooha    -- ówb_
       ,oe_order_lines_all       oola    -- ó¾×
       ,oe_transaction_types_all otta    -- ó^Cv
       ,ic_item_mst_b          iimb_a    -- UÖæiÚîñ
       ,ic_item_mst_b          iimb_o    -- UÖ³iÚîñ
       ,gmi_item_categories    gic_a1    -- UÖæiÚ¤iæªJeSîñ
       ,mtl_categories_b       mcb_a1    -- UÖæiÚ¤iæªJeSîñ
       ,mtl_category_sets_tl   mcst_a1   -- UÖæiÚ¤iæªJeSîñ
       ,gmi_item_categories    gic_a2    -- UÖæiÚiÚæªJeSîñ
       ,mtl_categories_b       mcb_a2    -- UÖæiÚiÚæªJeSîñ
       ,mtl_category_sets_tl   mcst_a2   -- UÖæiÚiÚæªJeSîñ
       ,gmi_item_categories    gic_o1    -- UÖ³iÚ¤iæªJeSîñ
       ,mtl_categories_b       mcb_o1    -- UÖ³iÚ¤iæªJeSîñ
       ,mtl_category_sets_tl   mcst_o1   -- UÖ³iÚ¤iæªJeSîñ
       ,gmi_item_categories    gic_o2    -- UÖ³iÚiÚæªJeSîñ
       ,mtl_categories_b       mcb_o2    -- UÖ³iÚiÚæªJeSîñ
       ,mtl_category_sets_tl   mcst_o2   -- UÖ³iÚiÚæªJeSîñ
       ,xxwsh_order_headers_all  xoha    -- ówb_AhI
       ,xxwsh_order_lines_all    xola    -- ó¾×AhI
       ,xxcmn_lookup_values_v    xlvv    -- NCbNR[hr[LOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('UÖo×_óü_´','UÖo×_óü_¼',
                                    'UÖo×_o×','UÖo×_¥o')
  AND xrpm.dealings_div           = xlvv.lookup_code
  AND xoha.req_status             = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id              = rsl.oe_order_header_id
  AND otta.transaction_type_id    = ooha.order_type_id
  AND xoha.header_id              = ooha.header_id
  AND oola.header_id              = ooha.header_id
  AND oola.line_id                = rsl.oe_order_line_id
  AND oola.line_id                = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- ÝÉ²®ÈO
      OR  (otta.attribute4       IS NULL))        -- ÝÉ²®ÈO
  AND xrpm.item_div_ahead  IS NOT NULL
  AND xrpm.item_div_origin IS NOT NULL
  AND xrpm.prod_div_ahead  IS NULL
  AND xrpm.prod_div_origin IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND xrpm.item_div_origin = mcb_o2.segment1
  -- UÖæ¤iæªJeSæ¾îñ
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- UÖæiÚæªJeSæ¾îñ
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
  -- UÖ³¤iæªJeSæ¾îñ
  AND gic_o1.category_set_id    = gic_a1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND iimb_o.item_id            = gic_o1.item_id
  -- UÖ³iÚæªJeSæ¾îñ
  AND gic_o2.category_set_id    = gic_a2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND iimb_o.item_id            = gic_o2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- Voó¥æª
       ,xrpm.dealings_div               AS dealings_div               -- æøæª
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- ó¥æª
       ,xrpm.doc_type                   AS doc_type                   -- ¶^Cv
       ,rsl.shipment_header_id          AS doc_id                     -- ¶ID
       ,rsl.line_num                    AS doc_line                   -- æø¾×Ô
       ,ooha.attribute11                AS result_post                -- ¬Ñ
       ,NULL                            AS item_id                    -- iÚID
       ,mcb_a2.segment1                 AS item_div                   -- iÚæª
       ,mcb_a1.segment1                 AS prod_div                   -- ¤iæª
       ,xlvv.meaning                    AS dealings_div_name          -- æøæª¼
 FROM   xxcmn_rcv_pay_mst        xrpm    -- ó¥æª}X^
       ,rcv_shipment_lines       rsl     -- óü¾×
       ,oe_order_headers_all     ooha    -- ówb_
       ,oe_order_lines_all       oola    -- ó¾×
       ,oe_transaction_types_all otta    -- ó^Cv
       ,ic_item_mst_b          iimb_a    -- iÚîñ
       ,gmi_item_categories    gic_a1    -- iÚ¤iæªJeSîñ
       ,mtl_categories_b       mcb_a1    -- iÚ¤iæªJeSîñ
       ,gmi_item_categories    gic_a2    -- iÚiÚæªJeSîñ
       ,mtl_categories_b       mcb_a2    -- æiÚiÚæªJeSîñ
       ,xxwsh_order_headers_all  xoha    -- ówb_AhI
       ,xxwsh_order_lines_all    xola    -- ó¾×AhI
       ,xxcmn_lookup_values_v    xlvv    -- NCbNR[hr[LOOKUP_CODE
WHERE xrpm.doc_type                   = 'PORC'
  AND xrpm.source_document_code       = 'RMA'
  AND xlvv.lookup_type                = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                    IN ('qÖ','Ôi')
  AND xrpm.dealings_div               = xlvv.lookup_code
  AND ooha.header_id                  = rsl.oe_order_header_id
  AND otta.transaction_type_id        = ooha.order_type_id
  AND xoha.header_id                  = ooha.header_id
  AND oola.header_id                  = ooha.header_id
  AND oola.line_id                    = rsl.oe_order_line_id
  AND oola.line_id                    = xola.line_id
  AND iimb_a.item_no                  = xola.shipping_item_code
  AND xrpm.shipment_provision_div     = otta.attribute1
  AND ((otta.attribute4               <> '2')         -- ÝÉ²®ÈO
      OR  (otta.attribute4            IS NULL))       -- ÝÉ²®ÈO
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  -- ¤iæªJeSæ¾îñ
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- iÚæªJeSæ¾îñ
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
--
UNION
--
SELECT  xrpm.new_div_account            AS new_div_account            -- Voó¥æª
       ,xrpm.dealings_div               AS dealings_div               -- æøæª
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- ó¥æª
       ,xrpm.doc_type                   AS doc_type                   -- ¶^Cv
       ,rsl.shipment_header_id          AS doc_id                     -- ¶ID
       ,rsl.line_num                    AS doc_line                   -- æø¾×Ô
       ,ooha.attribute11                AS result_post                -- ¬Ñ
       ,NULL                            AS item_id                    -- iÚID
       ,mcb_a2.segment1                 AS item_div                   -- iÚæª
       ,mcb_a1.segment1                 AS prod_div                   -- ¤iæª
       ,xlvv.meaning                    AS dealings_div_name          -- æøæª¼
 FROM   xxcmn_rcv_pay_mst        xrpm    -- ó¥æª}X^
       ,rcv_shipment_lines       rsl     -- óü¾×
       ,oe_order_headers_all     ooha    -- ówb_
       ,oe_order_lines_all       oola    -- ó¾×
       ,oe_transaction_types_all otta    -- ó^Cv
       ,ic_item_mst_b          iimb_a    -- iÚîñ
       ,gmi_item_categories    gic_a1    -- iÚ¤iæªJeSîñ
       ,mtl_categories_b       mcb_a1    -- iÚ¤iæªJeSîñ
       ,gmi_item_categories    gic_a2    -- iÚiÚæªJeSîñ
       ,mtl_categories_b       mcb_a2    -- æiÚiÚæªJeSîñ
       ,xxwsh_order_headers_all  xoha    -- ówb_AhI
       ,xxwsh_order_lines_all    xola    -- ó¾×AhI
       ,xxcmn_lookup_values_v    xlvv    -- NCbNR[hr[LOOKUP_CODE
WHERE xrpm.doc_type                   = 'PORC'
  AND xrpm.source_document_code       = 'RMA'
  AND xlvv.lookup_type                = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                    IN ('©{','pp')
  AND xrpm.dealings_div               = xlvv.lookup_code
  AND ooha.header_id                  = rsl.oe_order_header_ID
  AND otta.transaction_type_id        = ooha.order_type_id
  AND xoha.header_id                  = ooha.header_id
  AND oola.header_id                  = ooha.header_id
  AND oola.line_id                    = rsl.oe_order_line_iD
  AND oola.line_id                    = xola.line_id
  AND iimb_a.item_no                   = xola.shipping_item_code
  AND xrpm.stock_adjustment_div       = otta.attribute4
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  -- ¤iæªJeSæ¾îñ
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- iÚæªJeSæ¾îñ
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
/
COMMENT ON TABLE XXCMN_RCV_PAY_MST_PORC_RMA04_V IS 'oó¥æªîñVIEW_wÖA_o×04'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA04_V.NEW_DIV_ACCOUNT IS 'Voó¥æª'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA04_V.DEALINGS_DIV IS 'æøæª'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA04_V.RCV_PAY_DIV IS 'ó¥æª'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA04_V.DOC_TYPE IS '¶^Cv'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA04_V.DOC_ID   IS '¶ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA04_V.DOC_LINE IS 'æø¾×Ô'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA04_V.RESULT_POST IS '¬Ñ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA04_V.ITEM_ID IS 'iÚID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA04_V.ITEM_DIV IS 'iÚæª'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA04_V.PROD_DIV IS '¤iæª'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA04_V.DEALINGS_DIV_NAME IS 'æøæª¼'
/