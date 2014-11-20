/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCMN_RCV_PAY_MST_XFER_V
 * Description     : 経理受払区分情報VIEW_移動積送あり
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-04-14    1.0   R.Tomoyose       新規作成
 *  2008-06-12    1.1   Y.Ishikawa       項目に取引区分名を追加
 *
 ************************************************************************/
 CREATE OR REPLACE VIEW XXCMN_RCV_PAY_MST_XFER_V (
  NEW_DIV_ACCOUNT,
  DEALINGS_DIV,
  RCV_PAY_DIV,
  DOC_TYPE,
  SOURCE_DOCUMENT_CODE,
  TRANSACTION_TYPE,
  SHIPMENT_PROVISION_DIV,
  STOCK_ADJUSTMENT_DIV,
  SHIP_PROV_RCV_PAY_CATEGORY,
  ITEM_DIV_AHEAD,
  ITEM_DIV_ORIGIN,
  PROD_DIV_AHEAD,
  PROD_DIV_ORIGIN,
  ROUTING_CLASS,
  LINE_TYPE,
  HIT_IN_DIV,
  REASON_CODE,
  DEALINGS_DIV_NAME
)
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
       ,xlvv.meaning                    AS dealings_div_name          -- 取引区分名
FROM   xxcmn_rcv_pay_mst  xrpm
       ,xxcmn_lookup_values_v    xlvv    -- クイックコードビューLOOKUP_CODE
WHERE  xrpm.doc_type  = 'XFER'
  AND  xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND  xrpm.dealings_div         = xlvv.lookup_code
/
COMMENT ON TABLE XXCMN_RCV_PAY_MST_XFER_V IS '経理受払区分情報VIEW_移動積送あり'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.NEW_DIV_ACCOUNT IS '新経理受払区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.DEALINGS_DIV IS '取引区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.RCV_PAY_DIV IS '受払区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.DOC_TYPE IS '文書タイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.SOURCE_DOCUMENT_CODE IS 'ソース文書'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.TRANSACTION_TYPE IS 'PO取引タイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.SHIPMENT_PROVISION_DIV IS '出荷支給区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.STOCK_ADJUSTMENT_DIV IS '在庫調整区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.SHIP_PROV_RCV_PAY_CATEGORY IS '出荷支給受払カテゴリ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.ITEM_DIV_AHEAD IS '品目区分（振替先）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.ITEM_DIV_ORIGIN IS '品目区分（振替元）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.PROD_DIV_AHEAD IS '商品区分（振替先）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.PROD_DIV_ORIGIN IS '商品区分（振替元）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.ROUTING_CLASS IS '工順区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.LINE_TYPE IS 'ラインタイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.HIT_IN_DIV IS '打込区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.REASON_CODE IS '事由コード'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_XFER_V.DEALINGS_DIV_NAME IS '取引区分名'
/