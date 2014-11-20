/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCMN_RCV_PAY_MST_OMSO_V
 * Description     : �o���󕥋敪���VIEW_�󒍊֘A
 * Version         : 1.7
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-04-14    1.0   Y.Ishikawa       �V�K�쐬
 *  2008-05-20    1.1   Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_V�����
 *                                       �K�v�ȃe�[�u���݂̂̌����Ƃ���B
 *  2008-06-10    1.2   Y.Ishikawa       ����敪'���{�o��','�p�p�o��' ��
 *                                       '���{','�p�p'�֕ύX
 *  2008-06-12    1.3   Y.Ishikawa       ���ڂɎ���敪����ǉ�
 *  2008-06-12    1.4   Y.Ishikawa       ���ڂɎd����ID��ǉ�
 *  2008-06-13    1.5   Y.Ishikawa       ���ח\�����ǉ�
 *  2008-06-13    1.6   Y.Ishikawa       �J�e�S���擾������GROUP BY�̗��p����߂�
 *  2008-07-01    1.7   Y.Ishikawa       �o�׎x���敪�ɂ���Ď󒍃w�b�_�[�̒��o����
 *                                       ���o�׎��т��x�����т𔻒f����悤�ύX����
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCMN_RCV_PAY_MST_OMSO_V
    (NEW_DIV_ACCOUNT,DEALINGS_DIV,RCV_PAY_DIV,DOC_TYPE,SOURCE_DOCUMENT_CODE,TRANSACTION_TYPE,
     SHIPMENT_PROVISION_DIV,STOCK_ADJUSTMENT_DIV,SHIP_PROV_RCV_PAY_CATEGORY,ITEM_DIV_AHEAD,
     ITEM_DIV_ORIGIN,PROD_DIV_AHEAD,PROD_DIV_ORIGIN,ROUTING_CLASS,LINE_TYPE,HIT_IN_DIV,
     REASON_CODE,DOC_LINE,RESULT_POST,UNIT_PRICE,REQUEST_ITEM_CODE,ARRIVAL_DATE,
     DELIVER_TO_ID,ITEM_ID,ITEM_DIV,PROD_DIV,CROWD_CODE,ACNT_CROWD_CODE,DEALINGS_DIV_NAME,
     VENDOR_SITE_ID,SCHEDULE_ARRIVAL_DATE)
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
       ,wdd.delivery_detail_id          AS doc_line                   -- ������הԍ�
       ,ooha.attribute11                AS result_post                -- ���ѕ���
       ,xola.unit_price                 AS unit_price                 -- �̔��P��
       ,oola.attribute3                 AS request_item_code          -- �˗��i�ڃR�[�h
       ,xoha.arrival_date               AS arrival_date               -- ���ד�
       ,DECODE(xrpm.shipment_provision_div,'1',
               xoha.result_deliver_to_id,  '2',
               xoha.deliver_to_id)      AS deliver_to_id              -- �o�א�ID
       ,NULL                            AS item_id                    -- �i��ID
       ,mcb_o2.segment1                 AS item_div                   -- �i�ڋ敪
       ,mcb_o1.segment1                 AS prod_div                   -- ���i�敪
       ,mcb_o3.segment1                 AS crowd_code                 -- �S
       ,mcb_o4.segment1                 AS acnt_crowd_code            -- �o���S
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
       ,xoha.vendor_site_id             AS vendor_site_id             -- �d����ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- ���ח\���
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,wsh_delivery_details     wdd     -- �o�ה�������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �U�֐�i�ڏ��
       ,ic_item_mst_b          iimb_o    -- �U�֌��i�ڏ��
       ,gmi_item_categories    gic_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a1   -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a2   -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_a3    -- �U�֐�i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_a3    -- �U�֐�i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_a3   -- �U�֐�i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_a4    -- �U�֐�i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_a4    -- �U�֐�i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_a4   -- �U�֐�i�ڌo���S�J�e�S�����
       ,gmi_item_categories    gic_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_o1   -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_o2   -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_o3    -- �U�֌��i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_o3    -- �U�֌��i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_o3   -- �U�֌��i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_o4    -- �U�֌��i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_o4    -- �U�֌��i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_o4   -- �U�֌��i�ڌo���S�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type             = 'OMSO'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('���i�o��','�L��')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = wdd.source_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND oola.line_id              = wdd.source_line_id
  AND wdd.org_id                = ooha.org_id
  AND wdd.org_id                = oola.org_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND xola.header_id            = xoha.header_id
  AND oola.line_id              = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4       IS NULL))        -- �݌ɒ����ȊO
  AND NVL( xrpm.ship_prov_rcv_pay_category, NVL( otta.attribute11, 'NULL' ) ) =
      NVL( otta.attribute11, 'NULL' )
  AND xrpm.item_div_ahead      IS NOT NULL
  AND xrpm.item_div_origin     IS NOT NULL
  AND xrpm.prod_div_ahead      IS NULL
  AND xrpm.prod_div_origin     IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND xrpm.item_div_origin = mcb_o2.segment1
  AND xola.request_item_code = xola.shipping_item_code
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '���i�敪'
  AND iimb_a.item_id            = gic_a1.item_id
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '�i�ڋ敪'
  AND iimb_a.item_id            = gic_a2.item_id
  -- �U�֐�S�擾���
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '�Q�R�[�h'
  AND iimb_a.item_id            = gic_a3.item_id
  -- �U�֐�o���S�擾���
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_a.item_id            = gic_a4.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o1.category_set_id    = mcst_o1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND mcst_o1.language          = 'JA'
  AND mcst_o1.source_lang       = 'JA'
  AND mcst_o1.category_set_name = '���i�敪'
  AND iimb_o.item_id            = gic_o1.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o2.category_set_id    = mcst_o2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND mcst_o2.language          = 'JA'
  AND mcst_o2.source_lang       = 'JA'
  AND mcst_o2.category_set_name = '�i�ڋ敪'
  AND iimb_o.item_id            = gic_o2.item_id
  -- �U�֌��S�擾���
  AND gic_o3.category_set_id    = mcst_o3.category_set_id
  AND gic_o3.category_id        = mcb_o3.category_id
  AND mcst_o3.language          = 'JA'
  AND mcst_o3.source_lang       = 'JA'
  AND mcst_o3.category_set_name = '�Q�R�[�h'
  AND iimb_o.item_id            = gic_o3.item_id
  -- �U�֌��o���S�擾���
  AND gic_o4.category_set_id    = mcst_o4.category_set_id
  AND gic_o4.category_id        = mcb_o4.category_id
  AND mcst_o4.language          = 'JA'
  AND mcst_o4.source_lang       = 'JA'
  AND mcst_o4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_o.item_id            = gic_o4.item_id
--
UNION
--
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
       ,wdd.delivery_detail_id          AS doc_line                   -- ������הԍ�
       ,ooha.attribute11                AS result_post                -- ���ѕ���
       ,xola.unit_price                 AS unit_price                 -- �̔��P��
       ,oola.attribute3                 AS request_item_code          -- �˗��i�ڃR�[�h
       ,xoha.arrival_date               AS arrival_date               -- ���ד�
       ,DECODE(xrpm.shipment_provision_div,'1',
               xoha.result_deliver_to_id,  '2',
               xoha.deliver_to_id)      AS deliver_to_id              -- �o�א�ID
       ,NULL                            AS item_id                    -- �i��ID
       ,mcb_o2.segment1                 AS item_div                   -- �i�ڋ敪
       ,mcb_o1.segment1                 AS prod_div                   -- ���i�敪
       ,mcb_o3.segment1                 AS crowd_code                 -- �S
       ,mcb_o4.segment1                 AS acnt_crowd_code            -- �o���S
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
       ,xoha.vendor_site_id             AS vendor_site_id             -- �d����ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- ���ח\���
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,wsh_delivery_details     wdd     -- �o�ה�������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �U�֐�i�ڏ��
       ,ic_item_mst_b          iimb_o    -- �U�֌��i�ڏ��
       ,gmi_item_categories    gic_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a1   -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a2   -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_a3    -- �U�֐�i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_a3    -- �U�֐�i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_a3   -- �U�֐�i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_a4    -- �U�֐�i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_a4    -- �U�֐�i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_a4   -- �U�֐�i�ڌo���S�J�e�S�����
       ,gmi_item_categories    gic_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_o1   -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_o2   -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_o3    -- �U�֌��i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_o3    -- �U�֌��i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_o3   -- �U�֌��i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_o4    -- �U�֌��i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_o4    -- �U�֌��i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_o4   -- �U�֌��i�ڌo���S�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type             = 'OMSO'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('���ޏo��','�L��')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = wdd.source_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND oola.line_id              = wdd.source_line_id
  AND wdd.org_id                = ooha.org_id
  AND wdd.org_id                = oola.org_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND xola.header_id            = xoha.header_id
  AND oola.line_id              = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4       IS NULL))        -- �݌ɒ����ȊO
  AND NVL( xrpm.ship_prov_rcv_pay_category, NVL( otta.attribute11, 'NULL' ) ) =
      NVL( otta.attribute11, 'NULL' )
  AND xrpm.item_div_ahead      IS NULL
  AND xrpm.item_div_origin     IS NULL
  AND xrpm.prod_div_ahead      IS NULL
  AND xrpm.prod_div_origin     IS NULL
  AND mcb_a2.segment1  <> '5'   -- ���i�ȊO
  AND mcb_o2.segment1  <> '5'   -- ���i�ȊO
  AND xola.request_item_code = xola.shipping_item_code
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '���i�敪'
  AND iimb_a.item_id            = gic_a1.item_id
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '�i�ڋ敪'
  AND iimb_a.item_id            = gic_a2.item_id
  -- �U�֐�S�擾���
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '�Q�R�[�h'
  AND iimb_a.item_id            = gic_a3.item_id
  -- �U�֐�o���S�擾���
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_a.item_id            = gic_a4.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o1.category_set_id    = mcst_o1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND mcst_o1.language          = 'JA'
  AND mcst_o1.source_lang       = 'JA'
  AND mcst_o1.category_set_name = '���i�敪'
  AND iimb_o.item_id            = gic_o1.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o2.category_set_id    = mcst_o2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND mcst_o2.language          = 'JA'
  AND mcst_o2.source_lang       = 'JA'
  AND mcst_o2.category_set_name = '�i�ڋ敪'
  AND iimb_o.item_id            = gic_o2.item_id
  -- �U�֌��S�擾���
  AND gic_o3.category_set_id    = mcst_o3.category_set_id
  AND gic_o3.category_id        = mcb_o3.category_id
  AND mcst_o3.language          = 'JA'
  AND mcst_o3.source_lang       = 'JA'
  AND mcst_o3.category_set_name = '�Q�R�[�h'
  AND iimb_o.item_id            = gic_o3.item_id
  -- �U�֌��o���S�擾���
  AND gic_o4.category_set_id    = mcst_o4.category_set_id
  AND gic_o4.category_id        = mcb_o4.category_id
  AND mcst_o4.language          = 'JA'
  AND mcst_o4.source_lang       = 'JA'
  AND mcst_o4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_o.item_id            = gic_o4.item_id
--
UNION
--
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
       ,wdd.delivery_detail_id          AS doc_line                   -- ������הԍ�
       ,ooha.attribute11                AS result_post                -- ���ѕ���
       ,xola.unit_price                 AS unit_price                 -- �̔��P��
       ,oola.attribute3                 AS request_item_code          -- �˗��i�ڃR�[�h
       ,xoha.arrival_date               AS arrival_date               -- ���ד�
       ,DECODE(xrpm.shipment_provision_div,'1',
               xoha.result_deliver_to_id,  '2',
               xoha.deliver_to_id)      AS deliver_to_id              -- �o�א�ID
       ,DECODE(xlvv.meaning,
                 '�U�֗L��_���',iimb_a.item_id,                      -- �U�֐�i��ID
                 '�U�֗L��_�o��',iimb_a.item_id,                      -- �U�֐�i��ID
                 '�U�֗L��_���o',iimb_o.item_id) AS item_id           -- �U�֌��i��ID
       ,DECODE(xlvv.meaning,
                 '�U�֗L��_���',mcb_a2.segment1,                     -- �U�֐�i�ڋ敪
                 '�U�֗L��_�o��',mcb_a2.segment1,                     -- �U�֐�i�ڋ敪
                 '�U�֗L��_���o',mcb_o2.segment1) AS item_div         -- �U�֌��i�ڋ敪
       ,DECODE(xlvv.meaning,
                 '�U�֗L��_���',mcb_a1.segment1,                     -- �U�֐揤�i�敪
                 '�U�֗L��_�o��',mcb_a1.segment1,                     -- �U�֐揤�i�敪
                 '�U�֗L��_���o',mcb_o1.segment1) AS prod_div         -- �U�֌����i�敪
       ,DECODE(xlvv.meaning,
                 '�U�֗L��_���',mcb_a3.segment1,                     -- �U�֐�S
                 '�U�֗L��_�o��',mcb_a3.segment1,                     -- �U�֐�S
                 '�U�֗L��_���o',mcb_o3.segment1) AS crowd_code       -- �U�֌��S
       ,DECODE(xlvv.meaning,
                 '�U�֗L��_���',mcb_a4.segment1,                     -- �U�֐�o���S
                 '�U�֗L��_�o��',mcb_a4.segment1,                     -- �U�֐�o���S
                 '�U�֗L��_���o',mcb_o4.segment1) AS acnt_crowd_code  -- �U�֌��o���S
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
       ,xoha.vendor_site_id             AS vendor_site_id             -- �d����ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- ���ח\���
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,wsh_delivery_details     wdd     -- �o�ה�������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �U�֐�i�ڏ��
       ,ic_item_mst_b          iimb_o    -- �U�֌��i�ڏ��
       ,gmi_item_categories    gic_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a1   -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a2   -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_a3    -- �U�֐�i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_a3    -- �U�֐�i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_a3   -- �U�֐�i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_a4    -- �U�֐�i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_a4    -- �U�֐�i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_a4   -- �U�֐�i�ڌo���S�J�e�S�����
       ,gmi_item_categories    gic_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_o1   -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_o2   -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_o3    -- �U�֌��i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_o3    -- �U�֌��i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_o3   -- �U�֌��i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_o4    -- �U�֌��i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_o4    -- �U�֌��i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_o4   -- �U�֌��i�ڌo���S�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type             = 'OMSO'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('�U�֗L��_���','�U�֗L��_�o��','�U�֗L��_���o')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = wdd.source_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND oola.line_id              = wdd.source_line_id
  AND wdd.org_id                = ooha.org_id
  AND wdd.org_id                = oola.org_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND xola.header_id            = xoha.header_id
  AND oola.line_id              = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4       IS NULL))        -- �݌ɒ����ȊO
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  AND xrpm.item_div_ahead      IS NOT NULL
  AND xrpm.item_div_origin     IS NULL
  AND xrpm.prod_div_ahead      IS NULL
  AND xrpm.prod_div_origin     IS NULL
  AND xrpm.item_div_ahead         = mcb_a2.segment1
  AND mcb_o2.segment1          <> '5'   -- ���i�ȊO
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '���i�敪'
  AND iimb_a.item_id            = gic_a1.item_id
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '�i�ڋ敪'
  AND iimb_a.item_id            = gic_a2.item_id
  -- �U�֐�S�擾���
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '�Q�R�[�h'
  AND iimb_a.item_id            = gic_a3.item_id
  -- �U�֐�o���S�擾���
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_a.item_id            = gic_a4.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o1.category_set_id    = mcst_o1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND mcst_o1.language          = 'JA'
  AND mcst_o1.source_lang       = 'JA'
  AND mcst_o1.category_set_name = '���i�敪'
  AND iimb_o.item_id            = gic_o1.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o2.category_set_id    = mcst_o2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND mcst_o2.language          = 'JA'
  AND mcst_o2.source_lang       = 'JA'
  AND mcst_o2.category_set_name = '�i�ڋ敪'
  AND iimb_o.item_id            = gic_o2.item_id
  -- �U�֌��S�擾���
  AND gic_o3.category_set_id    = mcst_o3.category_set_id
  AND gic_o3.category_id        = mcb_o3.category_id
  AND mcst_o3.language          = 'JA'
  AND mcst_o3.source_lang       = 'JA'
  AND mcst_o3.category_set_name = '�Q�R�[�h'
  AND iimb_o.item_id            = gic_o3.item_id
  -- �U�֌��o���S�擾���
  AND gic_o4.category_set_id    = mcst_o4.category_set_id
  AND gic_o4.category_id        = mcb_o4.category_id
  AND mcst_o4.language          = 'JA'
  AND mcst_o4.source_lang       = 'JA'
  AND mcst_o4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_o.item_id            = gic_o4.item_id
--
UNION
--
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
       ,wdd.delivery_detail_id          AS doc_line                   -- ������הԍ�
       ,ooha.attribute11                AS result_post                -- ���ѕ���
       ,xola.unit_price                 AS unit_price                 -- �̔��P��
       ,oola.attribute3                 AS request_item_code          -- �˗��i�ڃR�[�h
       ,xoha.arrival_date               AS arrival_date               -- ���ד�
       ,DECODE(xrpm.shipment_provision_div,'1',
               xoha.result_deliver_to_id,  '2',
               xoha.deliver_to_id)      AS deliver_to_id              -- �o�א�ID
       ,DECODE(xlvv.meaning,
                 '���i�U�֗L��_���',iimb_a.item_id,                     -- �U�֐�i��ID
                 '���i�U�֗L��_�o��',iimb_a.item_id,                     -- �U�֐�i��ID
                 '���i�U�֗L��_���o',iimb_o.item_id) AS item_id          -- �U�֌��i��ID
       ,DECODE(xlvv.meaning,
                 '���i�U�֗L��_���',mcb_a2.segment1,             -- �U�֐�i�ڋ敪
                 '���i�U�֗L��_�o��',mcb_a2.segment1,             -- �U�֐�i�ڋ敪
                 '���i�U�֗L��_���o',mcb_o2.segment1) AS item_div -- �U�֌��i�ڋ敪
       ,DECODE(xlvv.meaning,
                 '���i�U�֗L��_���',mcb_a1.segment1,             -- �U�֐揤�i�敪
                 '���i�U�֗L��_�o��',mcb_a1.segment1,             -- �U�֐揤�i�敪
                 '���i�U�֗L��_���o',mcb_o1.segment1) AS prod_div -- �U�֌����i�敪
       ,DECODE(xlvv.meaning,
                 '���i�U�֗L��_���',mcb_a3.segment1,                  -- �U�֐�S
                 '���i�U�֗L��_�o��',mcb_a3.segment1,                  -- �U�֐�S
                 '���i�U�֗L��_���o',mcb_o3.segment1) AS crowd_code    -- �U�֌��S
       ,DECODE(xlvv.meaning,
                 '���i�U�֗L��_���',mcb_a4.segment1,             -- �U�֐�o���S
                 '���i�U�֗L��_�o��',mcb_a4.segment1,             -- �U�֐�o���S
                 '���i�U�֗L��_���o',mcb_o4.segment1) AS acnt_crowd_code -- �U�֌��o���S
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
       ,xoha.vendor_site_id             AS vendor_site_id             -- �d����ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- ���ח\���
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,wsh_delivery_details     wdd     -- �o�ה�������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �U�֐�i�ڏ��
       ,ic_item_mst_b          iimb_o    -- �U�֌��i�ڏ��
       ,gmi_item_categories    gic_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a1   -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a2   -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_a3    -- �U�֐�i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_a3    -- �U�֐�i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_a3   -- �U�֐�i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_a4    -- �U�֐�i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_a4    -- �U�֐�i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_a4   -- �U�֐�i�ڌo���S�J�e�S�����
       ,gmi_item_categories    gic_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_o1   -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_o2   -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_o3    -- �U�֌��i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_o3    -- �U�֌��i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_o3   -- �U�֌��i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_o4    -- �U�֌��i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_o4    -- �U�֌��i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_o4   -- �U�֌��i�ڌo���S�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type             = 'OMSO'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('���i�U�֗L��_���','���i�U�֗L��_�o��','���i�U�֗L��_���o')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = wdd.source_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND oola.line_id              = wdd.source_line_id
  AND wdd.org_id                = ooha.org_id
  AND wdd.org_id                = oola.org_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND xola.header_id            = xoha.header_id
  AND oola.line_id              = xola.line_id
  AND iimb_a.item_no           = xola.request_item_code
  AND iimb_o.item_no           = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4       IS NULL))        -- �݌ɒ����ȊO
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  AND xrpm.item_div_ahead  IS NOT NULL
  AND xrpm.item_div_origin IS NOT NULL
  AND xrpm.prod_div_ahead  IS NOT NULL
  AND xrpm.prod_div_origin IS NOT NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND xrpm.item_div_origin = mcb_o2.segment1
  AND xrpm.prod_div_ahead  = mcb_a1.segment1
  AND xrpm.prod_div_origin = mcb_o1.segment1
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '���i�敪'
  AND iimb_a.item_id            = gic_a1.item_id
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '�i�ڋ敪'
  AND iimb_a.item_id            = gic_a2.item_id
  -- �U�֐�S�擾���
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '�Q�R�[�h'
  AND iimb_a.item_id            = gic_a3.item_id
  -- �U�֐�o���S�擾���
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_a.item_id            = gic_a4.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o1.category_set_id    = mcst_o1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND mcst_o1.language          = 'JA'
  AND mcst_o1.source_lang       = 'JA'
  AND mcst_o1.category_set_name = '���i�敪'
  AND iimb_o.item_id            = gic_o1.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o2.category_set_id    = mcst_o2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND mcst_o2.language          = 'JA'
  AND mcst_o2.source_lang       = 'JA'
  AND mcst_o2.category_set_name = '�i�ڋ敪'
  AND iimb_o.item_id            = gic_o2.item_id
  -- �U�֌��S�擾���
  AND gic_o3.category_set_id    = mcst_o3.category_set_id
  AND gic_o3.category_id        = mcb_o3.category_id
  AND mcst_o3.language          = 'JA'
  AND mcst_o3.source_lang       = 'JA'
  AND mcst_o3.category_set_name = '�Q�R�[�h'
  AND iimb_o.item_id            = gic_o3.item_id
  -- �U�֌��o���S�擾���
  AND gic_o4.category_set_id    = mcst_o4.category_set_id
  AND gic_o4.category_id        = mcb_o4.category_id
  AND mcst_o4.language          = 'JA'
  AND mcst_o4.source_lang       = 'JA'
  AND mcst_o4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_o.item_id            = gic_o4.item_id
--
UNION
--
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
       ,wdd.delivery_detail_id          AS doc_line                   -- ������הԍ�
       ,ooha.attribute11                AS result_post                -- ���ѕ���
       ,xola.unit_price                 AS unit_price                 -- �̔��P��
       ,oola.attribute3                 AS request_item_code          -- �˗��i�ڃR�[�h
       ,xoha.arrival_date               AS arrival_date               -- ���ד�
       ,DECODE(xrpm.shipment_provision_div,'1',
               xoha.result_deliver_to_id,  '2',
               xoha.deliver_to_id)      AS deliver_to_id              -- �o�א�ID
       ,DECODE(xlvv.meaning,
                 '�U�֏o��_���_��',iimb_a.item_id,                  -- �U�֐�i��ID
                 '�U�֏o��_���_��',iimb_a.item_id,                  -- �U�֐�i��ID
                 '�U�֏o��_�o��'   ,iimb_a.item_id,                  -- �U�֐�i��ID
                 '�U�֏o��_���o'   ,iimb_o.item_id) AS item_id       -- �U�֌��i��ID
       ,DECODE(xlvv.meaning,
                 '�U�֏o��_���_��',mcb_a2.segment1,                 -- �U�֐�i�ڋ敪
                 '�U�֏o��_���_��',mcb_a2.segment1,                 -- �U�֐�i�ڋ敪
                 '�U�֏o��_�o��'   ,mcb_a2.segment1,                 -- �U�֐�i�ڋ敪
                 '�U�֏o��_���o'   ,mcb_o2.segment1) AS item_div     -- �U�֌��i�ڋ敪
       ,DECODE(xlvv.meaning,
                 '�U�֏o��_���_��',mcb_a1.segment1,                 -- �U�֐揤�i�敪
                 '�U�֏o��_���_��',mcb_a1.segment1,                 -- �U�֐揤�i�敪
                 '�U�֏o��_�o��'   ,mcb_a1.segment1,                 -- �U�֐揤�i�敪
                 '�U�֏o��_���o'   ,mcb_o1.segment1) AS prod_div     -- �U�֌����i�敪
       ,DECODE(xlvv.meaning,
                 '�U�֏o��_���_��',mcb_a3.segment1,                 -- �U�֐�S
                 '�U�֏o��_���_��',mcb_a3.segment1,                 -- �U�֐�S
                 '�U�֏o��_�o��'   ,mcb_a3.segment1,                 -- �U�֐�S
                 '�U�֏o��_���o'   ,mcb_o3.segment1) AS crowd_code   -- �U�֌��S
       ,DECODE(xlvv.meaning,
                 '�U�֏o��_���_��',mcb_a4.segment1,                 -- �U�֐�o���S
                 '�U�֏o��_���_��',mcb_a4.segment1,                 -- �U�֐�o���S
                 '�U�֏o��_�o��'   ,mcb_a4.segment1,                 -- �U�֐�o���S
                 '�U�֏o��_���o'   ,mcb_o4.segment1) AS acnt_crowd_code -- �U�֌��o���S
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
       ,xoha.vendor_site_id             AS vendor_site_id             -- �d����ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- ���ח\���
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,wsh_delivery_details     wdd     -- �o�ה�������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �U�֐�i�ڏ��
       ,ic_item_mst_b          iimb_o    -- �U�֌��i�ڏ��
       ,gmi_item_categories    gic_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a1   -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a2   -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_a3    -- �U�֐�i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_a3    -- �U�֐�i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_a3   -- �U�֐�i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_a4    -- �U�֐�i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_a4    -- �U�֐�i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_a4   -- �U�֐�i�ڌo���S�J�e�S�����
       ,gmi_item_categories    gic_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_o1   -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_o2   -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_o3    -- �U�֌��i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_o3    -- �U�֌��i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_o3   -- �U�֌��i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_o4    -- �U�֌��i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_o4    -- �U�֌��i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_o4   -- �U�֌��i�ڌo���S�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type             = 'OMSO'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('�U�֏o��_���_��','�U�֏o��_���_��',
                                    '�U�֏o��_�o��','�U�֏o��_���o')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = wdd.source_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND oola.line_id              = wdd.source_line_id
  AND wdd.org_id                = ooha.org_id
  AND wdd.org_id                = oola.org_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND xola.header_id            = xoha.header_id
  AND oola.line_id              = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4       IS NULL))        -- �݌ɒ����ȊO
  AND xrpm.item_div_ahead  IS NOT NULL
  AND xrpm.item_div_origin IS NULL
  AND xrpm.prod_div_ahead  IS NULL
  AND xrpm.prod_div_origin IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND mcb_o2.segment1      <> '5'   -- ���i�ȊO
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '���i�敪'
  AND iimb_a.item_id            = gic_a1.item_id
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '�i�ڋ敪'
  AND iimb_a.item_id            = gic_a2.item_id
  -- �U�֐�S�擾���
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '�Q�R�[�h'
  AND iimb_a.item_id            = gic_a3.item_id
  -- �U�֐�o���S�擾���
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_a.item_id            = gic_a4.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o1.category_set_id    = mcst_o1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND mcst_o1.language          = 'JA'
  AND mcst_o1.source_lang       = 'JA'
  AND mcst_o1.category_set_name = '���i�敪'
  AND iimb_o.item_id            = gic_o1.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o2.category_set_id    = mcst_o2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND mcst_o2.language          = 'JA'
  AND mcst_o2.source_lang       = 'JA'
  AND mcst_o2.category_set_name = '�i�ڋ敪'
  AND iimb_o.item_id            = gic_o2.item_id
  -- �U�֌��S�擾���
  AND gic_o3.category_set_id    = mcst_o3.category_set_id
  AND gic_o3.category_id        = mcb_o3.category_id
  AND mcst_o3.language          = 'JA'
  AND mcst_o3.source_lang       = 'JA'
  AND mcst_o3.category_set_name = '�Q�R�[�h'
  AND iimb_o.item_id            = gic_o3.item_id
  -- �U�֌��o���S�擾���
  AND gic_o4.category_set_id    = mcst_o4.category_set_id
  AND gic_o4.category_id        = mcb_o4.category_id
  AND mcst_o4.language          = 'JA'
  AND mcst_o4.source_lang       = 'JA'
  AND mcst_o4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_o.item_id            = gic_o4.item_id
--
UNION
--
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
       ,wdd.delivery_detail_id          AS doc_line                   -- ������הԍ�
       ,ooha.attribute11                AS result_post                -- ���ѕ���
       ,xola.unit_price                 AS unit_price                 -- �̔��P��
       ,oola.attribute3                 AS request_item_code          -- �˗��i�ڃR�[�h
       ,xoha.arrival_date               AS arrival_date               -- ���ד�
       ,DECODE(xrpm.shipment_provision_div,'1',
               xoha.result_deliver_to_id,  '2',
               xoha.deliver_to_id)      AS deliver_to_id              -- �o�א�ID
       ,DECODE(xlvv.meaning,
                 '�U�֏o��_���_��',iimb_a.item_id,                   -- �U�֐�i��ID
                 '�U�֏o��_���_��',iimb_a.item_id,                   -- �U�֐�i��ID
                 '�U�֏o��_�o��'   ,iimb_a.item_id,                   -- �U�֐�i��ID
                 '�U�֏o��_���o'   ,iimb_o.item_id) AS item_id        -- �U�֌��i��ID
       ,DECODE(xlvv.meaning,
                 '�U�֏o��_���_��',mcb_a2.segment1,                  -- �U�֐�i�ڋ敪
                 '�U�֏o��_���_��',mcb_a2.segment1,                  -- �U�֐�i�ڋ敪
                 '�U�֏o��_�o��'   ,mcb_a2.segment1,                  -- �U�֐�i�ڋ敪
                 '�U�֏o��_���o'   ,mcb_o2.segment1) AS item_div      -- �U�֌��i�ڋ敪
       ,DECODE(xlvv.meaning,
                 '�U�֏o��_���_��',mcb_a1.segment1,                  -- �U�֐揤�i�敪
                 '�U�֏o��_���_��',mcb_a1.segment1,                  -- �U�֐揤�i�敪
                 '�U�֏o��_�o��'   ,mcb_a1.segment1,                  -- �U�֐揤�i�敪
                 '�U�֏o��_���o'   ,mcb_o1.segment1) AS prod_div      -- �U�֌����i�敪
       ,DECODE(xlvv.meaning,
                 '�U�֏o��_���_��',mcb_a3.segment1,                  -- �U�֐�S
                 '�U�֏o��_���_��',mcb_a3.segment1,                  -- �U�֐�S
                 '�U�֏o��_�o��'   ,mcb_a3.segment1,                  -- �U�֐�S
                 '�U�֏o��_���o'   ,mcb_o3.segment1) AS crowd_code    -- �U�֌��S
       ,DECODE(xlvv.meaning,
                 '�U�֏o��_���_��',mcb_a4.segment1,                  -- �U�֐�o���S
                 '�U�֏o��_���_��',mcb_a4.segment1,                  -- �U�֐�o���S
                 '�U�֏o��_�o��'   ,mcb_a4.segment1,                  -- �U�֐�o���S
                 '�U�֏o��_���o'   ,mcb_o4.segment1) AS acnt_crowd_code -- �U�֌��o���S
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
       ,xoha.vendor_site_id             AS vendor_site_id             -- �d����ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- ���ח\���
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,wsh_delivery_details     wdd     -- �o�ה�������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �U�֐�i�ڏ��
       ,ic_item_mst_b          iimb_o    -- �U�֌��i�ڏ��
       ,gmi_item_categories    gic_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a1   -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a2   -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_a3    -- �U�֐�i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_a3    -- �U�֐�i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_a3   -- �U�֐�i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_a4    -- �U�֐�i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_a4    -- �U�֐�i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_a4   -- �U�֐�i�ڌo���S�J�e�S�����
       ,gmi_item_categories    gic_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_o1   -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_o2   -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_o3    -- �U�֌��i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_o3    -- �U�֌��i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_o3   -- �U�֌��i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_o4    -- �U�֌��i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_o4    -- �U�֌��i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_o4   -- �U�֌��i�ڌo���S�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type             = 'OMSO'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('�U�֏o��_���_��','�U�֏o��_���_��',
                                    '�U�֏o��_�o��','�U�֏o��_���o')
  AND xrpm.dealings_div         = xlvv.lookup_code
  AND xoha.req_status           = DECODE(xrpm.shipment_provision_div,'1','04','2','08')
  AND ooha.header_id            = wdd.source_header_id
  AND otta.transaction_type_id  = ooha.order_type_id
  AND oola.line_id              = wdd.source_line_id
  AND wdd.org_id                = ooha.org_id
  AND wdd.org_id                = oola.org_id
  AND xoha.header_id            = ooha.header_id
  AND oola.header_id            = ooha.header_id
  AND xola.header_id            = xoha.header_id
  AND oola.line_id              = xola.line_id
  AND iimb_a.item_no            = xola.request_item_code
  AND iimb_o.item_no            = xola.shipping_item_code
  AND xrpm.shipment_provision_div = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4       IS NULL))        -- �݌ɒ����ȊO
  AND xrpm.item_div_ahead  IS NOT NULL
  AND xrpm.item_div_origin IS NOT NULL
  AND xrpm.prod_div_ahead  IS NULL
  AND xrpm.prod_div_origin IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND xrpm.item_div_origin = mcb_o2.segment1
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '���i�敪'
  AND iimb_a.item_id            = gic_a1.item_id
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '�i�ڋ敪'
  AND iimb_a.item_id            = gic_a2.item_id
  -- �U�֐�S�擾���
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '�Q�R�[�h'
  AND iimb_a.item_id            = gic_a3.item_id
  -- �U�֐�o���S�擾���
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_a.item_id            = gic_a4.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o1.category_set_id    = mcst_o1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND mcst_o1.language          = 'JA'
  AND mcst_o1.source_lang       = 'JA'
  AND mcst_o1.category_set_name = '���i�敪'
  AND iimb_o.item_id            = gic_o1.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o2.category_set_id    = mcst_o2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND mcst_o2.language          = 'JA'
  AND mcst_o2.source_lang       = 'JA'
  AND mcst_o2.category_set_name = '�i�ڋ敪'
  AND iimb_o.item_id            = gic_o2.item_id
  -- �U�֌��S�擾���
  AND gic_o3.category_set_id    = mcst_o3.category_set_id
  AND gic_o3.category_id        = mcb_o3.category_id
  AND mcst_o3.language          = 'JA'
  AND mcst_o3.source_lang       = 'JA'
  AND mcst_o3.category_set_name = '�Q�R�[�h'
  AND iimb_o.item_id            = gic_o3.item_id
  -- �U�֌��o���S�擾���
  AND gic_o4.category_set_id    = mcst_o4.category_set_id
  AND gic_o4.category_id        = mcb_o4.category_id
  AND mcst_o4.language          = 'JA'
  AND mcst_o4.source_lang       = 'JA'
  AND mcst_o4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_o.item_id            = gic_o4.item_id
--
UNION
--
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
       ,wdd.delivery_detail_id          AS doc_line                   -- ������הԍ�
       ,ooha.attribute11                AS result_post                -- ���ѕ���
       ,xola.unit_price                 AS unit_price                 -- �̔��P��
       ,oola.attribute3                 AS request_item_code          -- �˗��i�ڃR�[�h
       ,xoha.arrival_date               AS arrival_date               -- ���ד�
       ,xoha.deliver_to_id              AS deliver_to_id              -- �o�א�ID
       ,NULL                            AS item_id                    -- �i��ID
       ,mcb_a2.segment1                 AS item_div                   -- �i�ڋ敪
       ,mcb_a1.segment1                 AS prod_div                   -- ���i�敪
       ,mcb_a3.segment1                 AS crowd_code                 -- �S
       ,mcb_a4.segment1                 AS acnt_crowd_code            -- �o���S
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
       ,xoha.vendor_site_id             AS vendor_site_id             -- �d����ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- ���ח\���
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,wsh_delivery_details     wdd     -- �o�ה�������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �i�ڏ��
       ,gmi_item_categories    gic_a1    -- �i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a1   -- �i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- ��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a2   -- �i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_a3    -- �i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_a3    -- �i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_a3   -- �i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_a4    -- �i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_a4    -- �i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_a4   -- �i�ڌo���S�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type                   = 'OMSO'
  AND xlvv.lookup_type                = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                    IN ('�q��','�ԕi')
  AND xrpm.dealings_div               = xlvv.lookup_code
  AND ooha.header_id                  = wdd.source_header_id
  AND otta.transaction_type_id        = ooha.order_type_id
  AND oola.line_id                    = wdd.source_line_id
  AND wdd.org_id                      = ooha.org_id
  AND wdd.org_id                      = oola.org_id
  AND xoha.header_id                  = ooha.header_id
  AND oola.header_id                  = ooha.header_id
  AND xola.header_id                  = xoha.header_id
  AND oola.line_id                    = xola.line_id
  AND iimb_a.item_no                  = xola.shipping_item_code
  AND xrpm.shipment_provision_div     = otta.attribute1
  AND ((otta.attribute4           <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4       IS NULL))        -- �݌ɒ����ȊO
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  -- ���i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '���i�敪'
  AND iimb_a.item_id            = gic_a1.item_id
  -- ���i�敪�J�e�S���擾���
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '�i�ڋ敪'
  AND iimb_a.item_id            = gic_a2.item_id
  -- �S�擾���
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '�Q�R�[�h'
  AND iimb_a.item_id            = gic_a3.item_id
  -- �o���S�擾���
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_a.item_id            = gic_a4.item_id
--
UNION
--
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
       ,wdd.delivery_detail_id          AS doc_line                   -- ������הԍ�
       ,ooha.attribute11                AS result_post                -- ���ѕ���
       ,xola.unit_price                 AS unit_price                 -- �̔��P��
       ,oola.attribute3                 AS request_item_code          -- �˗��i�ڃR�[�h
       ,xoha.arrival_date               AS arrival_date               -- ���ד�
       ,xoha.deliver_to_id              AS deliver_to_id              -- �o�א�ID
       ,NULL                            AS item_id                    -- �i��ID
       ,mcb_a2.segment1                 AS item_div                   -- �i�ڋ敪
       ,mcb_a1.segment1                 AS prod_div                   -- ���i�敪
       ,mcb_a3.segment1                 AS crowd_code                 -- �S
       ,mcb_a4.segment1                 AS acnt_crowd_code            -- �o���S
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
       ,xoha.vendor_site_id             AS vendor_site_id             -- �d����ID
       ,xoha.schedule_arrival_date      AS schedule_arrival_date      -- ���ח\���
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,wsh_delivery_details     wdd     -- �o�ה�������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �i�ڏ��
       ,gmi_item_categories    gic_a1    -- �i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �i�ڏ��i�敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a1   -- �i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- ��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_category_sets_tl   mcst_a2   -- �i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_a3    -- �i�ڌS�J�e�S�����
       ,mtl_categories_b       mcb_a3    -- �i�ڌS�J�e�S�����
       ,mtl_category_sets_tl   mcst_a3   -- �i�ڌS�J�e�S�����
       ,gmi_item_categories    gic_a4    -- �i�ڌo���S�J�e�S�����
       ,mtl_categories_b       mcb_a4    -- �i�ڌo���S�J�e�S�����
       ,mtl_category_sets_tl   mcst_a4   -- �i�ڌo���S�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type                   = 'OMSO'
  AND xlvv.lookup_type                = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                    IN ('���{','�p�p')
  AND xrpm.dealings_div               = xlvv.lookup_code
  AND ooha.header_id                  = wdd.source_header_id
  AND otta.transaction_type_id        = ooha.order_type_id
  AND oola.line_id                    = wdd.source_line_id
  AND wdd.org_id                      = ooha.org_id
  AND wdd.org_id                      = oola.org_id
  AND xoha.header_id                  = ooha.header_id
  AND oola.header_id                  = ooha.header_id
  AND xola.header_id                  = xoha.header_id
  AND oola.line_id                    = xola.line_id
  AND iimb_a.item_no                   = xola.shipping_item_code
  AND xrpm.stock_adjustment_div       = otta.attribute4
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  -- ���i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = mcst_a1.category_set_id
  AND gic_a1.category_id        = mcb_a1.category_id
  AND mcst_a1.language          = 'JA'
  AND mcst_a1.source_lang       = 'JA'
  AND mcst_a1.category_set_name = '���i�敪'
  AND iimb_a.item_id            = gic_a1.item_id
  -- ���i�敪�J�e�S���擾���
  AND gic_a2.category_set_id    = mcst_a2.category_set_id
  AND gic_a2.category_id        = mcb_a2.category_id
  AND mcst_a2.language          = 'JA'
  AND mcst_a2.source_lang       = 'JA'
  AND mcst_a2.category_set_name = '�i�ڋ敪'
  AND iimb_a.item_id            = gic_a2.item_id
  -- �S�擾���
  AND gic_a3.category_set_id    = mcst_a3.category_set_id
  AND gic_a3.category_id        = mcb_a3.category_id
  AND mcst_a3.language          = 'JA'
  AND mcst_a3.source_lang       = 'JA'
  AND mcst_a3.category_set_name = '�Q�R�[�h'
  AND iimb_a.item_id            = gic_a3.item_id
  -- �o���S�擾���
  AND gic_a4.category_set_id    = mcst_a4.category_set_id
  AND gic_a4.category_id        = mcb_a4.category_id
  AND mcst_a4.language          = 'JA'
  AND mcst_a4.source_lang       = 'JA'
  AND mcst_a4.category_set_name = '�o�����p�Q�R�[�h'
  AND iimb_a.item_id            = gic_a4.item_id
/
COMMENT ON TABLE XXCMN_RCV_PAY_MST_OMSO_V IS '�o���󕥋敪���VIEW_�󒍊֘A'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.NEW_DIV_ACCOUNT IS '�V�o���󕥋敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.DEALINGS_DIV IS '����敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.RCV_PAY_DIV IS '�󕥋敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.DOC_TYPE IS '�����^�C�v'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.SOURCE_DOCUMENT_CODE IS '�\�[�X����'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.TRANSACTION_TYPE IS 'PO����^�C�v'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.SHIPMENT_PROVISION_DIV IS '�o�׎x���敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.STOCK_ADJUSTMENT_DIV IS '�݌ɒ����敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.SHIP_PROV_RCV_PAY_CATEGORY IS '�o�׎x���󕥃J�e�S��'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ITEM_DIV_AHEAD IS '�i�ڋ敪�i�U�֐�j'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ITEM_DIV_ORIGIN IS '�i�ڋ敪�i�U�֌��j'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.PROD_DIV_AHEAD IS '���i�敪�i�U�֐�j'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.PROD_DIV_ORIGIN IS '���i�敪�i�U�֌��j'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ROUTING_CLASS IS '�H���敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.LINE_TYPE IS '���C���^�C�v'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.HIT_IN_DIV IS '�ō��敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.REASON_CODE IS '���R�R�[�h'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.DOC_LINE IS '������הԍ�'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.RESULT_POST IS '���ѕ���'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.UNIT_PRICE IS '�̔��P��'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.REQUEST_ITEM_CODE IS '�˗��i�ڃR�[�h'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ARRIVAL_DATE IS '���ד�'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.DELIVER_TO_ID IS '�o�א�ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ITEM_ID IS '�i��ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ITEM_DIV IS '�i�ڋ敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.PROD_DIV IS '���i�敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.CROWD_CODE IS '�S'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.ACNT_CROWD_CODE IS '�o���S'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.DEALINGS_DIV_NAME IS '����敪��'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.VENDOR_SITE_ID IS '�d����ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_OMSO_V.SCHEDULE_ARRIVAL_DATE IS '���ח\���'
/