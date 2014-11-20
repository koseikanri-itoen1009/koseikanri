/************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * View Name       : XXCMN_RCV_PAY_MST_PORC_RMA02_V
 * Description     : �o���󕥋敪���VIEW_�w���֘A_�o��(for XXCMN770002C)
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008-08-04    1.0   R.Tomoyose       �V�K�쐬
 *
 ************************************************************************/
CREATE OR REPLACE VIEW XXCMN_RCV_PAY_MST_PORC_RMA02_V
    (DEALINGS_DIV,RCV_PAY_DIV,DOC_TYPE,DOC_ID,DOC_LINE,ITEM_ID,ITEM_DIV,PROD_DIV,DEALINGS_DIV_NAME)
AS
SELECT  xrpm.dealings_div               AS dealings_div               -- ����敪
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- �󕥋敪
       ,xrpm.doc_type                   AS doc_type                   -- �����^�C�v
       ,rsl.shipment_header_id          AS doc_id                     -- ����ID
       ,rsl.line_num                    AS doc_line                   -- ������הԍ�
       ,NULL                            AS item_id                    -- �i��ID
       ,mcb_a2.segment1                 AS item_div                   -- �i�ڋ敪
       ,mcb_a1.segment1                 AS prod_div                   -- ���i�敪
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,rcv_shipment_lines       rsl     -- �������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �i�ڏ��
       ,gmi_item_categories    gic_a1    -- �i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- �i�ڕi�ڋ敪�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('���i�o��','�L��')
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
  AND ((otta.attribute4           <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4       IS NULL))        -- �݌ɒ����ȊO
  AND NVL( xrpm.ship_prov_rcv_pay_category, NVL( otta.attribute11, 'NULL' ) ) =
      NVL( otta.attribute11, 'NULL' )
  AND xrpm.item_div_ahead      IS NOT NULL
  AND xrpm.item_div_origin     IS NOT NULL
  AND xrpm.prod_div_ahead      IS NULL
  AND xrpm.prod_div_origin     IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND xrpm.item_div_origin = mcb_a2.segment1
  -- ���i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- �i�ڋ敪�J�e�S���擾���
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
--
UNION
--
SELECT  xrpm.dealings_div               AS dealings_div               -- ����敪
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- �󕥋敪
       ,xrpm.doc_type                   AS doc_type                   -- �����^�C�v
       ,rsl.shipment_header_id          AS doc_id                     -- ����ID
       ,rsl.line_num                    AS doc_line                   -- ������הԍ�
       ,NULL                            AS item_id                    -- �i��ID
       ,mcb_a2.segment1                 AS item_div                   -- �i�ڋ敪
       ,mcb_a1.segment1                 AS prod_div                   -- ���i�敪
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,rcv_shipment_lines       rsl     -- �������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �i�ڏ��
       ,gmi_item_categories    gic_a1    -- �i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- �i�ڕi�ڋ敪�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('���ޏo��','�L��')
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
  AND ((otta.attribute4           <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4       IS NULL))        -- �݌ɒ����ȊO
  AND NVL( xrpm.ship_prov_rcv_pay_category, NVL( otta.attribute11, 'NULL' ) ) =
      NVL( otta.attribute11, 'NULL' )
  AND xrpm.item_div_ahead      IS NULL
  AND xrpm.item_div_origin     IS NULL
  AND xrpm.prod_div_ahead      IS NULL
  AND xrpm.prod_div_origin     IS NULL
  AND mcb_a2.segment1  <> '5'   -- ���i�ȊO
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- �U�֐�i�ڋ敪�J�e�S���擾���
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
--
UNION
--
SELECT  xrpm.dealings_div               AS dealings_div               -- ����敪
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- �󕥋敪
       ,xrpm.doc_type                   AS doc_type                   -- �����^�C�v
       ,rsl.shipment_header_id          AS doc_id                     -- ����ID
       ,rsl.line_num                    AS doc_line                   -- ������הԍ�
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
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,rcv_shipment_lines       rsl     -- �������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �U�֐�i�ڏ��
       ,ic_item_mst_b          iimb_o    -- �U�֌��i�ڏ��
       ,gmi_item_categories    gic_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type               = 'PORC'
  AND xrpm.source_document_code   = 'RMA'
  AND xlvv.lookup_type            = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                IN ('�U�֗L��_���','�U�֗L��_�o��','�U�֗L��_���o')
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
  AND ((otta.attribute4           <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4       IS NULL))        -- �݌ɒ����ȊO
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  AND xrpm.item_div_ahead         IS NOT NULL
  AND xrpm.item_div_origin        IS NULL
  AND xrpm.prod_div_ahead         IS NULL
  AND xrpm.prod_div_origin        IS NULL
  AND xrpm.item_div_ahead         = mcb_a2.segment1
  AND mcb_o2.segment1          <> '5'   -- ���i�ȊO
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- �U�֐�i�ڋ敪�J�e�S���擾���
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o1.category_set_id    = gic_a1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND iimb_o.item_id            = gic_o1.item_id
  -- �U�֌��i�ڋ敪�J�e�S���擾���
  AND gic_o2.category_set_id    = gic_a2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND iimb_o.item_id            = gic_o2.item_id
--
UNION
--
SELECT  xrpm.dealings_div               AS dealings_div               -- ����敪
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- �󕥋敪
       ,xrpm.doc_type                   AS doc_type                   -- �����^�C�v
       ,rsl.shipment_header_id          AS doc_id                     -- ����ID
       ,rsl.line_num                    AS doc_line                   -- ������הԍ�
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
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,rcv_shipment_lines       rsl     -- �������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �U�֐�i�ڏ��
       ,ic_item_mst_b          iimb_o    -- �U�֌��i�ڏ��
       ,gmi_item_categories    gic_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('���i�U�֗L��_���','���i�U�֗L��_�o��','���i�U�֗L��_���o')
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
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- �U�֐�i�ڋ敪�J�e�S���擾���
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o1.category_set_id    = gic_a1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND iimb_o.item_id            = gic_o1.item_id
  -- �U�֌��i�ڋ敪�J�e�S���擾���
  AND gic_o2.category_set_id    = gic_a2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND iimb_o.item_id            = gic_o2.item_id
--
UNION
--
SELECT  xrpm.dealings_div               AS dealings_div               -- ����敪
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- �󕥋敪
       ,xrpm.doc_type                   AS doc_type                   -- �����^�C�v
       ,rsl.shipment_header_id          AS doc_id                     -- ����ID
       ,rsl.line_num                    AS doc_line                   -- ������הԍ�
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
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,rcv_shipment_lines       rsl     -- �������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �U�֐�i�ڏ��
       ,ic_item_mst_b          iimb_o    -- �U�֌��i�ڏ��
       ,gmi_item_categories    gic_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('�U�֏o��_���_��','�U�֏o��_���_��',
                                    '�U�֏o��_�o��','�U�֏o��_���o')
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
  AND ((otta.attribute4           <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4       IS NULL))        -- �݌ɒ����ȊO
  AND xrpm.item_div_ahead  IS NOT NULL
  AND xrpm.item_div_origin IS NULL
  AND xrpm.prod_div_ahead  IS NULL
  AND xrpm.prod_div_origin IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND mcb_o2.segment1      <> '5'   -- ���i�ȊO
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- �U�֐�i�ڋ敪�J�e�S���擾���
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o1.category_set_id    = gic_a1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND iimb_o.item_id            = gic_o1.item_id
  -- �U�֌��i�ڋ敪�J�e�S���擾���
  AND gic_o2.category_set_id    = gic_a2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND iimb_o.item_id            = gic_o2.item_id
--
UNION
--
SELECT  xrpm.dealings_div               AS dealings_div               -- ����敪
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- �󕥋敪
       ,xrpm.doc_type                   AS doc_type                   -- �����^�C�v
       ,rsl.shipment_header_id          AS doc_id                     -- ����ID
       ,rsl.line_num                    AS doc_line                   -- ������הԍ�
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
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,rcv_shipment_lines       rsl     -- �������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �U�֐�i�ڏ��
       ,ic_item_mst_b          iimb_o    -- �U�֌��i�ڏ��
       ,gmi_item_categories    gic_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �U�֐�i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- �U�֐�i�ڕi�ڋ敪�J�e�S�����
       ,gmi_item_categories    gic_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_o1    -- �U�֌��i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_o2    -- �U�֌��i�ڕi�ڋ敪�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type             = 'PORC'
  AND xrpm.source_document_code = 'RMA'
  AND xlvv.lookup_type          = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning              IN ('�U�֏o��_���_��','�U�֏o��_���_��',
                                    '�U�֏o��_�o��','�U�֏o��_���o')
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
  AND ((otta.attribute4           <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4       IS NULL))        -- �݌ɒ����ȊO
  AND xrpm.item_div_ahead  IS NOT NULL
  AND xrpm.item_div_origin IS NOT NULL
  AND xrpm.prod_div_ahead  IS NULL
  AND xrpm.prod_div_origin IS NULL
  AND xrpm.item_div_ahead  = mcb_a2.segment1
  AND xrpm.item_div_origin = mcb_o2.segment1
  -- �U�֐揤�i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- �U�֐�i�ڋ敪�J�e�S���擾���
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
  -- �U�֌����i�敪�J�e�S���擾���
  AND gic_o1.category_set_id    = gic_a1.category_set_id
  AND gic_o1.category_id        = mcb_o1.category_id
  AND iimb_o.item_id            = gic_o1.item_id
  -- �U�֌��i�ڋ敪�J�e�S���擾���
  AND gic_o2.category_set_id    = gic_a2.category_set_id
  AND gic_o2.category_id        = mcb_o2.category_id
  AND iimb_o.item_id            = gic_o2.item_id
--
UNION
--
SELECT  xrpm.dealings_div               AS dealings_div               -- ����敪
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- �󕥋敪
       ,xrpm.doc_type                   AS doc_type                   -- �����^�C�v
       ,rsl.shipment_header_id          AS doc_id                     -- ����ID
       ,rsl.line_num                    AS doc_line                   -- ������הԍ�
       ,NULL                            AS item_id                    -- �i��ID
       ,mcb_a2.segment1                 AS item_div                   -- �i�ڋ敪
       ,mcb_a1.segment1                 AS prod_div                   -- ���i�敪
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,rcv_shipment_lines       rsl     -- �������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �i�ڏ��
       ,gmi_item_categories    gic_a1    -- �i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- ��i�ڕi�ڋ敪�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type                   = 'PORC'
  AND xrpm.source_document_code       = 'RMA'
  AND xlvv.lookup_type                = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                    IN ('�q��','�ԕi')
  AND xrpm.dealings_div               = xlvv.lookup_code
  AND ooha.header_id                  = rsl.oe_order_header_id
  AND otta.transaction_type_id        = ooha.order_type_id
  AND xoha.header_id                  = ooha.header_id
  AND oola.header_id                  = ooha.header_id
  AND oola.line_id                    = rsl.oe_order_line_id
  AND oola.line_id                    = xola.line_id
  AND iimb_a.item_no                  = xola.shipping_item_code
  AND xrpm.shipment_provision_div     = otta.attribute1
  AND ((otta.attribute4               <> '2')         -- �݌ɒ����ȊO
      OR  (otta.attribute4            IS NULL))       -- �݌ɒ����ȊO
  AND xrpm.ship_prov_rcv_pay_category = otta.attribute11
  -- ���i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- �i�ڋ敪�J�e�S���擾���
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
--
UNION
--
SELECT  xrpm.dealings_div               AS dealings_div               -- ����敪
       ,xrpm.rcv_pay_div                AS rcv_pay_div                -- �󕥋敪
       ,xrpm.doc_type                   AS doc_type                   -- �����^�C�v
       ,rsl.shipment_header_id          AS doc_id                     -- ����ID
       ,rsl.line_num                    AS doc_line                   -- ������הԍ�
       ,NULL                            AS item_id                    -- �i��ID
       ,mcb_a2.segment1                 AS item_div                   -- �i�ڋ敪
       ,mcb_a1.segment1                 AS prod_div                   -- ���i�敪
       ,xlvv.meaning                    AS dealings_div_name          -- ����敪��
 FROM   xxcmn_rcv_pay_mst        xrpm    -- �󕥋敪�}�X�^
       ,rcv_shipment_lines       rsl     -- �������
       ,oe_order_headers_all     ooha    -- �󒍃w�b�_
       ,oe_order_lines_all       oola    -- �󒍖���
       ,oe_transaction_types_all otta    -- �󒍃^�C�v
       ,ic_item_mst_b          iimb_a    -- �i�ڏ��
       ,gmi_item_categories    gic_a1    -- �i�ڏ��i�敪�J�e�S�����
       ,mtl_categories_b       mcb_a1    -- �i�ڏ��i�敪�J�e�S�����
       ,gmi_item_categories    gic_a2    -- �i�ڕi�ڋ敪�J�e�S�����
       ,mtl_categories_b       mcb_a2    -- ��i�ڕi�ڋ敪�J�e�S�����
       ,xxwsh_order_headers_all  xoha    -- �󒍃w�b�_�A�h�I��
       ,xxwsh_order_lines_all    xola    -- �󒍖��׃A�h�I��
       ,xxcmn_lookup_values_v    xlvv    -- �N�C�b�N�R�[�h�r���[LOOKUP_CODE
WHERE xrpm.doc_type                   = 'PORC'
  AND xrpm.source_document_code       = 'RMA'
  AND xlvv.lookup_type                = 'XXCMN_DEALINGS_DIV'
  AND xlvv.meaning                    IN ('���{','�p�p')
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
  -- ���i�敪�J�e�S���擾���
  AND gic_a1.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS')
  AND gic_a1.category_id        = mcb_a1.category_id
  AND iimb_a.item_id            = gic_a1.item_id
  -- �i�ڋ敪�J�e�S���擾���
  AND gic_a2.category_set_id    = FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS')
  AND gic_a2.category_id        = mcb_a2.category_id
  AND iimb_a.item_id            = gic_a2.item_id
/
COMMENT ON TABLE XXCMN_RCV_PAY_MST_PORC_RMA02_V IS '�o���󕥋敪���VIEW_�w���֘A_�o��02'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA02_V.DEALINGS_DIV IS '����敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA02_V.RCV_PAY_DIV IS '�󕥋敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA02_V.DOC_TYPE IS '�����^�C�v'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA02_V.DOC_ID   IS '����ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA02_V.DOC_LINE IS '������הԍ�'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA02_V.ITEM_ID IS '�i��ID'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA02_V.ITEM_DIV IS '�i�ڋ敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA02_V.PROD_DIV IS '���i�敪'
/
COMMENT ON COLUMN XXCMN_RCV_PAY_MST_PORC_RMA02_V.DEALINGS_DIV_NAME IS '����敪��'
/
