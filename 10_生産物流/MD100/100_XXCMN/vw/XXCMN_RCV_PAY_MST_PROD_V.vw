/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCMN_RCV_PAY_MST_PROD_V
 * Description     : �o���󕥋敪���VIEW_���Y�֘A
 * Version         : 1.3
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-04-14    1.0   R.Tomoyose       �V�K�쐬
 *  2008-06-12    1.1   Y.Ishikawa       ���ڂɎ���敪����ǉ�
 *  2008-07-25    1.2   Y.Ishikawa       XXCMN_ITEM_CATEGORIES4_V�̎g�p���~�߂�
 *  2008-07-30    1.3   T.Ikehara        GROUP BY��̎g�p���~�߂�
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
  BATCH_NO,
  DEALINGS_DIV_NAME
)
AS
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
      ,xlvv.meaning                      AS dealings_div_name          -- ����敪��
FROM   xxcmn_rcv_pay_mst        xrpm_a
      ,gme_material_details     gmd_a
      ,gme_batch_header         gbh_a
      ,gmd_routings_b           grb_a
      ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE  xrpm_a.doc_type          = 'PROD'
AND    xrpm_a.routing_class    <> '70'
AND    xlvv.lookup_type         = 'XXCMN_DEALINGS_DIV'
AND    xrpm_a.dealings_div      = xlvv.lookup_code
AND    gbh_a.batch_id           = gmd_a.batch_id
AND    grb_a.routing_id         = gbh_a.routing_id
AND    xrpm_a.routing_class     = grb_a.routing_class
AND    xrpm_a.line_type         = gmd_a.line_type
AND    ( ( ( gmd_a.attribute5 IS NULL ) AND ( xrpm_a.hit_in_div IS NULL ) )
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
      ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
FROM   xxcmn_rcv_pay_mst        xrpm_b
      ,gme_material_details     gmd_b
      ,gme_batch_header         gbh_b
      ,gmd_routings_b           grb_b
      ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE  xrpm_b.doc_type          = 'PROD'
AND    xrpm_b.routing_class     = '70'
AND    xlvv.lookup_type         = 'XXCMN_DEALINGS_DIV'
AND    xrpm_b.dealings_div      = xlvv.lookup_code
AND    gbh_b.batch_id           = gmd_b.batch_id
AND    grb_b.routing_id         = gbh_b.routing_id
AND    xrpm_b.routing_class     = grb_b.routing_class
AND    xrpm_b.line_type         = gmd_b.line_type
AND    ( ( ( gmd_b.attribute5 IS NULL ) AND ( xrpm_b.hit_in_div IS NULL ) )
       OR ( xrpm_b.hit_in_div        = gmd_b.attribute5 ) )
AND    EXISTS(
         SELECT 1
         FROM   gme_batch_header         gbh_item
               ,gme_material_details     gmd_item
               ,gmd_routings_b           grb_item
               ,gmi_item_categories    gic
               ,mtl_categories_b       mcb
               ,mtl_category_sets_tl   mcst
         WHERE  gbh_item.batch_id      = gmd_item.batch_id
         AND    gbh_item.routing_id    = grb_item.routing_id
         AND    grb_item.routing_class = '70'
         AND    gic.category_set_id    = mcst.category_set_id
         AND    gic.category_id        = mcb.category_id
         AND    mcst.language          = 'JA'
         AND    mcst.source_lang       = 'JA'
         AND    mcst.category_set_name = '�i�ڋ敪'
         AND    gmd_item.item_id       = gic.item_id
         AND    gmd_item.batch_id      = gmd_b.batch_id
         AND    gmd_item.line_no       = gmd_b.line_no
         GROUP BY gbh_item.batch_id
                 ,gmd_item.line_no
         HAVING MAX(DECODE(gmd_item.line_type,-1,mcb.segment1,NULL)) = xrpm_b.item_div_origin
         AND    MAX(DECODE(gmd_item.line_type, 1,mcb.segment1,NULL)) = xrpm_b.item_div_ahead
       )
/
COMMENT ON TABLE XXCMN_RCV_PAY_MST_PROD_V IS '�o���󕥋敪���VIEW_���Y�֘A'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.NEW_DIV_ACCOUNT IS '�V�o���󕥋敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.DEALINGS_DIV IS '����敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.RCV_PAY_DIV IS '�󕥋敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.DOC_TYPE IS '�����^�C�v'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.SOURCE_DOCUMENT_CODE IS '�\�[�X����'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.TRANSACTION_TYPE IS 'PO����^�C�v'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.SHIPMENT_PROVISION_DIV IS '�o�׎x���敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.STOCK_ADJUSTMENT_DIV IS '�݌ɒ����敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.SHIP_PROV_RCV_PAY_CATEGORY IS '�o�׎x���󕥃J�e�S��'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.ITEM_DIV_AHEAD IS '�i�ڋ敪�i�U�֐�j'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.ITEM_DIV_ORIGIN IS '�i�ڋ敪�i�U�֌��j'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.PROD_DIV_AHEAD IS '���i�敪�i�U�֐�j'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.PROD_DIV_ORIGIN IS '���i�敪�i�U�֌��j'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.ROUTING_CLASS IS '�H���敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.LINE_TYPE IS '���C���^�C�v'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.HIT_IN_DIV IS '�ō��敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.REASON_CODE IS '���R�R�[�h'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.DOC_ID IS '����ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.DOC_LINE IS '������הԍ�'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.GMD_LINE_TYPE IS '���Y�����ڍׁF���C���^�C�v'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.ITEM_TRANSFER_DIV IS '�i�ڐU�֖ړI'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.RESULT_POST IS '���ѕ���'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.FORMULA_ID IS '�t�H�[�~�����h�c'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.ITEM_ID IS '�i�ڂh�c'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.BATCH_NO IS '�o�b�`�m��'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PROD_V.DEALINGS_DIV_NAME IS '����敪��'
/