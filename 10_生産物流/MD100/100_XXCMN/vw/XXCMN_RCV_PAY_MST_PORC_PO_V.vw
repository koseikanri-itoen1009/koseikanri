/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCMN_RCV_PAY_MST_PORC_PO_V
 * Description     : 経理受払区分情報VIEW_購買関連_仕入
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-04-14    1.0   Y.Ishikawa       新規作成
 *  2008-06-12    1.1   Y.Ishikawa       項目に取引区分名を追加
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCMN_RCV_PAY_MST_PORC_PO_V
    (NEW_DIV_ACCOUNT,DEALINGS_DIV,RCV_PAY_DIV,DOC_TYPE,SOURCE_DOCUMENT_CODE,TRANSACTION_TYPE,
     SHIPMENT_PROVISION_DIV,STOCK_ADJUSTMENT_DIV,SHIP_PROV_RCV_PAY_CATEGORY,ITEM_DIV_AHEAD,
     ITEM_DIV_ORIGIN,PROD_DIV_AHEAD,PROD_DIV_ORIGIN,ROUTING_CLASS,LINE_TYPE,HIT_IN_DIV,REASON_CODE,
     LINE_ID,DOC_ID,DOC_LINE,POWDER_PRICE,COMMISSION_PRICE,ASSESSMENT,VENDOR_ID,RESULT_POST,
     UNIT_PRICE,DEALINGS_DIV_NAME)
AS
SELECT  xrpm.new_div_account            AS new_div_account            -- 新経理受払区分
       ,xrpm.dealings_div               AS dealings_div               -- 取引区分
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- 受払区分
       ,xrpm.doc_type                   AS doc_type                   -- 文書タイプ
       ,xrpm.source_document_code       AS source_document_code       -- ソース文書
       ,xrpm.transaction_type           AS transaction_type           -- PO取引タイプ
       ,xrpm.shipment_provision_div     AS shipment_provision_div     -- 出荷支給区分
       ,xrpm.stock_adjustment_div       AS stock_adjustment_div       -- 在庫調整区分
       ,xrpm.ship_prov_rcv_pay_category AS ship_prov_rcv_pay_category -- 出荷支給受払カテゴリ
       ,xrpm.item_div_ahead             AS item_div_ahead             -- 品目区分（振替先）
       ,xrpm.item_div_origin            AS item_div_origin            -- 品目区分（振替元）
       ,xrpm.prod_div_ahead             AS prod_div_ahead             -- 商品区分（振替先）
       ,xrpm.prod_div_origin            AS prod_div_origin            -- 商品区分（振替元）
       ,xrpm.routing_class              AS routing_class              -- 工順区分
       ,xrpm.line_type                  AS line_type                  -- ラインタイプ
       ,xrpm.hit_in_div                 AS hit_in_div                 -- 打込区分
       ,xrpm.reason_code                AS reason_code                -- 事由コード
       ,rt.transaction_id               AS line_id                    -- 明細ID
       ,rsl.shipment_header_id          AS doc_id                     -- 文書ID
       ,rsl.line_num                    AS doc_line                   -- 取引明細番号
       ,plla.attribute2                 AS powder_price               -- 粉引後単価
       ,plla.attribute4                 AS commission_price           -- 口銭単価
       ,plla.attribute7                 AS assessment                 -- 賦課金
       ,pha.vendor_id                   AS vendor_id                  -- 仕入先ID
       ,pha.attribute10                 AS result_post                -- 成績部署
       ,pla.unit_price                  AS unit_price                 -- 販売単価
       ,xlvv.meaning                    AS dealings_div_name          -- 取引区分名
 FROM   xxcmn_rcv_pay_mst        xrpm    -- 受払区分マスタ
       ,rcv_shipment_lines       rsl     -- 受入明細
       ,rcv_transactions         rt      -- 受入取引
       ,po_headers_all           pha     -- 発注ヘッダー
       ,po_lines_all             pla     -- 発注明細
       ,po_line_locations_all    plla    -- 発注納入明細
       ,po_vendors               pv      -- 仕入先マスタ
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code <> 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND pha.vendor_id             = pv.vendor_id
  AND rsl.po_header_id          = pha.po_header_id
  AND rsl.po_line_id            = pla.po_line_id
  AND rsl.shipment_line_id      = rt.shipment_line_id
  AND rsl.source_document_code  = xrpm.source_document_code
  AND rt.transaction_type       = xrpm.transaction_type
  AND pla.po_line_id            = plla.po_line_id
/
COMMENT ON TABLE XXCMN_RCV_PAY_MST_PORC_PO_V IS '経理受払区分情報VIEW_購買関連_仕入'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.NEW_DIV_ACCOUNT IS '新経理受払区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.DEALINGS_DIV IS '取引区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.RCV_PAY_DIV IS '受払区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.DOC_TYPE IS '文書タイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.SOURCE_DOCUMENT_CODE IS 'ソース文書'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.TRANSACTION_TYPE IS 'PO取引タイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.SHIPMENT_PROVISION_DIV IS '出荷支給区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.STOCK_ADJUSTMENT_DIV IS '在庫調整区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.SHIP_PROV_RCV_PAY_CATEGORY IS '出荷支給受払カテゴリ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.ITEM_DIV_AHEAD IS '品目区分（振替先）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.ITEM_DIV_ORIGIN IS '品目区分（振替元）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.PROD_DIV_AHEAD IS '商品区分（振替先）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.PROD_DIV_ORIGIN IS '商品区分（振替元）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.ROUTING_CLASS IS '工順区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.LINE_TYPE IS 'ラインタイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.HIT_IN_DIV IS '打込区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.REASON_CODE IS '事由コード'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.LINE_ID IS '明細ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.DOC_ID   IS '文書ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.DOC_LINE IS '取引明細番号'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.POWDER_PRICE IS '粉引後単価'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.COMMISSION_PRICE IS '預かり口銭単価'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.ASSESSMENT IS '賦課金'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.VENDOR_ID IS '仕入先ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.RESULT_POST IS '成績部署'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.UNIT_PRICE IS '販売単価'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.DEALINGS_DIV_NAME IS '取引区分名'
/