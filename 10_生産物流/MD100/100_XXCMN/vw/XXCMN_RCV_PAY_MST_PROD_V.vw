/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCMN_RCV_PAY_MST_PROD_V
 * Description     : 経理受払区分情報VIEW_生産関連
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-04-14    1.0    R.Tomoyose       新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCMN_RCV_PAY_MST_PROD_V (
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
  DOC_ID,
  DOC_LINE,
  GMD_LINE_TYPE,
  ITEM_TRANSFER_DIV,
  RESULT_POST,
  FORMULA_ID,
  ITEM_ID,
  BATCH_NO
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
       ,xrpm.doc_id                     AS doc_id                     -- 文書ID
       ,xrpm.doc_line                   AS doc_line                   -- 取引明細番号
       ,xrpm.gmd_line_type              AS gmd_line_type              -- ラインタイプ
       ,xrpm.item_transfer_div          AS item_transfer_div          -- 品目振替目的
       ,xrpm.result_post                AS result_post                -- 成績部署
       ,xrpm.formula_id                 AS formula_id                 -- フォーミュラＩＤ
       ,xrpm.item_id                    AS item_id                    -- 品目ＩＤ
       ,xrpm.batch_no                   AS batch_no                   -- バッチＮｏ
FROM (
      SELECT xrpm_a.new_div_account            AS new_div_account
            ,xrpm_a.dealings_div               AS dealings_div
            ,xrpm_a.rcv_pay_div                AS rcv_pay_div
            ,xrpm_a.doc_type                   AS doc_type
            ,xrpm_a.source_document_code       AS source_document_code
            ,xrpm_a.transaction_type           AS transaction_type
            ,xrpm_a.shipment_provision_div     AS shipment_provision_div
            ,xrpm_a.stock_adjustment_div       AS stock_adjustment_div
            ,xrpm_a.ship_prov_rcv_pay_category AS ship_prov_rcv_pay_category
            ,xrpm_a.item_div_ahead             AS item_div_ahead
            ,xrpm_a.item_div_origin            AS item_div_origin
            ,xrpm_a.prod_div_ahead             AS prod_div_ahead
            ,xrpm_a.prod_div_origin            AS prod_div_origin
            ,xrpm_a.routing_class              AS routing_class
            ,xrpm_a.line_type                  AS line_type
            ,xrpm_a.hit_in_div                 AS hit_in_div
            ,xrpm_a.reason_code                AS reason_code
            ,gmd_a.batch_id                    AS doc_id
            ,gmd_a.line_no                     AS doc_line
            ,gmd_a.line_type                   AS gmd_line_type
            ,gbh_a.attribute7                  AS item_transfer_div
            ,grb_a.attribute14                 AS result_post
            ,gbh_a.formula_id                  AS formula_id
            ,gmd_a.item_id                     AS item_id
            ,gbh_a.batch_no                    AS batch_no
      FROM   xxcmn_rcv_pay_mst        xrpm_a      
            ,gme_material_details     gmd_a
            ,gme_batch_header         gbh_a
            ,gmd_routings_b           grb_a
      WHERE  xrpm_a.doc_type          = 'PROD'
      AND    xrpm_a.routing_class    <> '70'
      AND    gbh_a.batch_id           = gmd_a.batch_id
      AND    grb_a.routing_id         = gbh_a.routing_id
      AND    xrpm_a.routing_class     = grb_a.routing_class
      AND    xrpm_a.line_type         = gmd_a.line_type
      AND (   ( ( gmd_a.attribute5 IS NULL ) AND ( xrpm_a.hit_in_div IS NULL ) )
           OR ( xrpm_a.hit_in_div        = gmd_a.attribute5 ) )
      UNION ALL
      SELECT xrpm_b.new_div_account            AS new_div_account
            ,xrpm_b.dealings_div               AS dealings_div
            ,xrpm_b.rcv_pay_div                AS rcv_pay_div
            ,xrpm_b.doc_type                   AS doc_type
            ,xrpm_b.source_document_code       AS source_document_code
            ,xrpm_b.transaction_type           AS transaction_type
            ,xrpm_b.shipment_provision_div     AS shipment_provision_div
            ,xrpm_b.stock_adjustment_div       AS stock_adjustment_div
            ,xrpm_b.ship_prov_rcv_pay_category AS ship_prov_rcv_pay_category
            ,xrpm_b.item_div_ahead             AS item_div_ahead
            ,xrpm_b.item_div_origin            AS item_div_origin
            ,xrpm_b.prod_div_ahead             AS prod_div_ahead
            ,xrpm_b.prod_div_origin            AS prod_div_origin
            ,xrpm_b.routing_class              AS routing_class
            ,xrpm_b.line_type                  AS line_type
            ,xrpm_b.hit_in_div                 AS hit_in_div
            ,xrpm_b.reason_code                AS reason_code
            ,gmd_b.batch_id                    AS doc_id
            ,gmd_b.line_no                     AS doc_line
            ,gmd_b.line_type                   AS gmd_line_type
            ,gbh_b.attribute7                  AS item_transfer_div
            ,grb_b.attribute14                 AS result_post
            ,gbh_b.formula_id                  AS formula_id
            ,gmd_b.item_id                     AS item_id
            ,gbh_b.batch_no                    AS batch_no
      FROM   xxcmn_rcv_pay_mst        xrpm_b
            ,gme_material_details     gmd_b
            ,gme_batch_header         gbh_b
            ,gmd_routings_b           grb_b
            ,( SELECT gbh_item.batch_id
                     ,gmd_item.line_no
                     ,MAX(DECODE(gmd_item.line_type,-1,xicv.item_class_code,NULL)) item_class_origin
                     ,MAX(DECODE(gmd_item.line_type, 1,xicv.item_class_code,NULL)) item_class_ahead
               FROM   gme_batch_header         gbh_item
                     ,gme_material_details     gmd_item
                     ,gmd_routings_b           grb_item
                     ,xxcmn_item_categories4_v xicv
               WHERE  gbh_item.batch_id      = gmd_item.batch_id
               AND    gbh_item.routing_id    = grb_item.routing_id
               AND    grb_item.routing_class = '70'
               AND    gmd_item.item_id       = xicv.item_id
               GROUP BY gbh_item.batch_id
                       ,gmd_item.line_no ) gmd_item_b
      WHERE  xrpm_b.doc_type          = 'PROD'
      AND    xrpm_b.routing_class     = '70'
      AND    gbh_b.batch_id           = gmd_b.batch_id
      AND    grb_b.routing_id         = gbh_b.routing_id
      AND    xrpm_b.routing_class     = grb_b.routing_class
      AND    xrpm_b.line_type         = gmd_b.line_type
      AND (   ( ( gmd_b.attribute5 IS NULL ) AND ( xrpm_b.hit_in_div IS NULL ) )
           OR ( xrpm_b.hit_in_div        = gmd_b.attribute5 ) )
      AND    gmd_item_b.batch_id      = gmd_b.batch_id
      AND    gmd_item_b.line_no       = gmd_b.line_no
      AND    xrpm_b.item_div_ahead    = gmd_item_b.item_class_ahead
      AND    xrpm_b.item_div_origin   = gmd_item_b.item_class_origin
) xrpm
/
COMMENT ON TABLE XXCMN_RCV_PAY_MST_PROD_V IS '経理受払区分情報VIEW_生産関連'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.NEW_DIV_ACCOUNT IS '新経理受払区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.DEALINGS_DIV IS '取引区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.RCV_PAY_DIV IS '受払区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.DOC_TYPE IS '文書タイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.SOURCE_DOCUMENT_CODE IS 'ソース文書'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.TRANSACTION_TYPE IS 'PO取引タイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.SHIPMENT_PROVISION_DIV IS '出荷支給区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.STOCK_ADJUSTMENT_DIV IS '在庫調整区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.SHIP_PROV_RCV_PAY_CATEGORY IS '出荷支給受払カテゴリ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.ITEM_DIV_AHEAD IS '品目区分（振替先）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.ITEM_DIV_ORIGIN IS '品目区分（振替元）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.PROD_DIV_AHEAD IS '商品区分（振替先）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.PROD_DIV_ORIGIN IS '商品区分（振替元）'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.ROUTING_CLASS IS '工順区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.LINE_TYPE IS 'ラインタイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.HIT_IN_DIV IS '打込区分'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.REASON_CODE IS '事由コード'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.DOC_ID IS '文書ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.DOC_LINE IS '取引明細番号'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.GMD_LINE_TYPE IS '生産原料詳細：ラインタイプ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.ITEM_TRANSFER_DIV IS '品目振替目的'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.RESULT_POST IS '成績部署'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.FORMULA_ID IS 'フォーミュラＩＤ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.ITEM_ID IS '品目ＩＤ'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.BATCH_NO IS 'バッチＮｏ'
/