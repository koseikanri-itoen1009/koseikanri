/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCMN_RCV_PAY_MST_PORC_PO_V
 * Description     : �o���󕥋敪���VIEW_�w���֘A_�d��
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-04-14    1.0   Y.Ishikawa       �V�K�쐬
 *  2008-06-12    1.1   Y.Ishikawa       ���ڂɎ���敪����ǉ�
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCMN_RCV_PAY_MST_PORC_PO_V
    (NEW_DIV_ACCOUNT,DEALINGS_DIV,RCV_PAY_DIV,DOC_TYPE,SOURCE_DOCUMENT_CODE,TRANSACTION_TYPE,
     SHIPMENT_PROVISION_DIV,STOCK_ADJUSTMENT_DIV,SHIP_PROV_RCV_PAY_CATEGORY,ITEM_DIV_AHEAD,
     ITEM_DIV_ORIGIN,PROD_DIV_AHEAD,PROD_DIV_ORIGIN,ROUTING_CLASS,LINE_TYPE,HIT_IN_DIV,REASON_CODE,
     LINE_ID,DOC_ID,DOC_LINE,POWDER_PRICE,COMMISSION_PRICE,ASSESSMENT,VENDOR_ID,RESULT_POST,
     UNIT_PRICE,DEALINGS_DIV_NAME)
AS
SELECT  xrpm.new_div_account            AS new_div_account            -- �V�o���󕥋敪
       ,xrpm.dealings_div               AS dealings_div               -- ����敪
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- �󕥋敪
       ,xrpm.doc_type                   AS doc_type                   -- �����^�C�v
       ,xrpm.source_document_code       AS source_document_code       -- �\�[�X����
       ,xrpm.transaction_type           AS transaction_type           -- PO����^�C�v
       ,xrpm.shipment_provision_div     AS shipment_provision_div     -- �o�׎x���敪
       ,xrpm.stock_adjustment_div       AS stock_adjustment_div       -- �݌ɒ����敪
       ,xrpm.ship_prov_rcv_pay_category AS ship_prov_rcv_pay_category -- �o�׎x���󕥃J�e�S��
       ,xrpm.item_div_ahead             AS item_div_ahead             -- �i�ڋ敪�i�U�֐�j
       ,xrpm.item_div_origin            AS item_div_origin            -- �i�ڋ敪�i�U�֌��j
       ,xrpm.prod_div_ahead             AS prod_div_ahead             -- ���i�敪�i�U�֐�j
       ,xrpm.prod_div_origin            AS prod_div_origin            -- ���i�敪�i�U�֌��j
       ,xrpm.routing_class              AS routing_class              -- �H���敪
       ,xrpm.line_type                  AS line_type                  -- ���C���^�C�v
       ,xrpm.hit_in_div                 AS hit_in_div                 -- �ō��敪
       ,xrpm.reason_code                AS reason_code                -- ���R�R�[�h
       ,rt.transaction_id               AS line_id                    -- ����ID
       ,rsl.shipment_header_id          AS doc_id                     -- ����ID
       ,rsl.line_num                    AS doc_line                   -- ������הԍ�
       ,plla.attribute2                 AS powder_price               -- ������P��
       ,plla.attribute4                 AS commission_price           -- ���K�P��
       ,plla.attribute7                 AS assessment                 -- ���ۋ�
       ,pha.vendor_id                   AS vendor_id                  -- �d����ID
       ,pha.attribute10                 AS result_post                -- ���ѕ���
       ,pla.unit_price                  AS unit_price                 -- �̔��P��
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,rcv_shipment_lines       rsl     -- �������
       ,rcv_transactions         rt      -- ������
       ,po_headers_all           pha     -- �����w�b�_�[
       ,po_lines_all             pla     -- ��������
       ,po_line_locations_all    plla    -- �����[������
       ,po_vendors               pv      -- �d����}�X�^
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
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
COMMENT ON TABLE XXCMN_RCV_PAY_MST_PORC_PO_V IS '�o���󕥋敪���VIEW_�w���֘A_�d��'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.NEW_DIV_ACCOUNT IS '�V�o���󕥋敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.DEALINGS_DIV IS '����敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.RCV_PAY_DIV IS '�󕥋敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.DOC_TYPE IS '�����^�C�v'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.SOURCE_DOCUMENT_CODE IS '�\�[�X����'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.TRANSACTION_TYPE IS 'PO����^�C�v'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.SHIPMENT_PROVISION_DIV IS '�o�׎x���敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.STOCK_ADJUSTMENT_DIV IS '�݌ɒ����敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.SHIP_PROV_RCV_PAY_CATEGORY IS '�o�׎x���󕥃J�e�S��'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.ITEM_DIV_AHEAD IS '�i�ڋ敪�i�U�֐�j'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.ITEM_DIV_ORIGIN IS '�i�ڋ敪�i�U�֌��j'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.PROD_DIV_AHEAD IS '���i�敪�i�U�֐�j'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.PROD_DIV_ORIGIN IS '���i�敪�i�U�֌��j'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.ROUTING_CLASS IS '�H���敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.LINE_TYPE IS '���C���^�C�v'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.HIT_IN_DIV IS '�ō��敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.REASON_CODE IS '���R�R�[�h'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.LINE_ID IS '����ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.DOC_ID   IS '����ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.DOC_LINE IS '������הԍ�'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.POWDER_PRICE IS '������P��'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.COMMISSION_PRICE IS '�a������K�P��'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.ASSESSMENT IS '���ۋ�'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.VENDOR_ID IS '�d����ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.RESULT_POST IS '���ѕ���'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.UNIT_PRICE IS '�̔��P��'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_PO_V.DEALINGS_DIV_NAME IS '����敪��'
/