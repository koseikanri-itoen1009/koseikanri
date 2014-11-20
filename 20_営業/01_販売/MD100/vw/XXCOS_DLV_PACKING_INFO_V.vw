/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_dlv_packing_info_v
 * Description     : �[�i�\��X�V(�הԏ��)���view
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/10/29    1.0   K.Kiriu         �V�K�쐬
 *  2010/06/16    1.1   H.Sasaki        [E_�{�ғ�_03075]���_�I��Ή�
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_dlv_packing_info_v(
   edi_header_info_id          -- EDI�w�b�_���.EDI�w�b�_���ID
  ,edi_chain_code              -- EDI�w�b�_���.EDI�`�F�[���X�R�[�h
  ,shop_code                   -- EDI�w�b�_���.�X�R�[�h
  ,shop_delivery_date          -- EDI�w�b�_���.�X�ܔ[�i��
  ,invoice_class               -- EDI�w�b�_���.�`�[�敪
  ,delivery_schedule_flag      -- EDI�w�b�_���.EDI�[�i�\�著�M�σt���O
  ,xeh_last_updated_by         -- EDI�w�b�_���.�ŏI�X�V��
  ,xeh_last_update_date        -- EDI�w�b�_���.�ŏI�X�V��
  ,xeh_last_update_login       -- EDI�w�b�_���.�ŏI���O�C��ID
  ,edi_line_info_id            -- EDI���׏��.EDI���׏��ID
  ,product_code_itouen         -- EDI���׏��.���i�R�[�h(�ɓ���)
  ,packing_number              -- EDI���׏��.����ԍ�
  ,sum_order_qty               -- EDI���׏��.��������(���v�A�o��)
  ,sum_shipping_qty            -- EDI���׏��.�o�א���(���v�A�o��)
  ,sum_stockout_qty            -- EDI���׏��.���i����(���v�A�o��)
  ,xel_last_updated_by         -- EDI���׏��.�ŏI�X�V��
  ,xel_last_update_date        -- EDI���׏��.�ŏI�X�V��
  ,xel_last_update_login       -- EDI���׏��.�ŏI���O�C��ID
  ,ordered_item                -- �󒍖���.�󒍕i��
  ,order_quantity_uom          -- �󒍖���.�󒍒P��
  ,ordered_quantity            -- �󒍖���.�󒍐���(�����l��)
  ,num_of_case                 -- OPM�i��.�P�[�X����
  ,num_of_bowl                 -- Disc�i�ڃA�h�I��.�{�[������
  ,jan_code                    -- JAN�R�[�h
  ,item_name                   -- ���i��
  ,org_id                      -- �󒍃w�b�_.�c�ƒP��ID
  ,organization_id             -- Disc�i��.�݌ɑg�DID
/* 2010/06/16 Ver1.1 Add START */
  ,base_code                   --  �ڋq�A�h�I��.�[�i���_
/* 2010/06/16 Ver1.1 Add END   */
)
AS
  SELECT xeh.edi_header_info_id          edi_header_info_id      -- EDI�w�b�_���.EDI�w�b�_���ID
        ,xeh.edi_chain_code              edi_chain_code          -- EDI�w�b�_���.EDI�`�F�[���X�R�[�h
        ,xeh.shop_code                   shop_code               -- EDI�w�b�_���.�X�R�[�h
        ,xeh.shop_delivery_date          shop_delivery_date      -- EDI�w�b�_���.�X�ܔ[�i��
        ,xeh.invoice_class               invoice_class           -- EDI�w�b�_���.�`�[�敪
        ,xeh.edi_delivery_schedule_flag  delivery_schedule_flag  -- EDI�w�b�_���.EDI�[�i�\�著�M�σt���O
        ,xeh.last_updated_by             xeh_last_updated_by     -- EDI�w�b�_���.�ŏI�X�V��
        ,xeh.last_update_date            xeh_last_update_date    -- EDI�w�b�_���.�ŏI�X�V��
        ,xeh.last_update_login           xeh_last_update_login   -- EDI�w�b�_���.�ŏI���O�C��ID
        ,xel.edi_line_info_id            edi_line_info_id        -- EDI���׏��.EDI���׏��ID
        ,xel.product_code_itouen         product_code_itouen     -- EDI���׏��.���i�R�[�h(�ɓ���)
        ,xel.packing_number              packing_number          -- EDI���׏��.����ԍ�
        ,xel.sum_order_qty               sum_order_qty           -- EDI���׏��.��������(���v�A�o��)
        ,xel.sum_shipping_qty            sum_shipping_qty        -- EDI���׏��.�o�א���(���v�A�o��)
        ,xel.sum_stockout_qty            sum_stockout_qty        -- EDI���׏��.���i����(���v�A�o��)
        ,xel.last_updated_by             xel_last_updated_by     -- EDI���׏��.�ŏI�X�V��
        ,xel.last_update_date            xel_last_update_date    -- EDI���׏��.�ŏI�X�V��
        ,xel.last_update_login           xel_last_update_login   -- EDI���׏��.�ŏI���O�C��ID
        ,oola.ordered_item               ordered_item            -- �󒍖���.�󒍕i��
        ,oola.order_quantity_uom         order_quantity_uom      -- �󒍖���.�󒍒P��
        ,( SELECT /*+
                     INDEX(oola1 oe_order_lines_n1)
                  */
                  NVL( SUM( oola1.ordered_quantity ), 0 )
           FROM   oe_order_lines_all oola1
           WHERE  oola1.header_id = oola.header_id
           AND    (
                    ( oola1.line_id = oola.line_id )
                  OR
                    (
                      ( oola1.global_attribute3 = TO_CHAR( oola.line_id ) )
                      AND
                      ( oola1.global_attribute4 = xel.order_connection_line_number )
                    )
                  )
         )                               ordered_quantity        -- �󒍖���.�󒍐���(�����l��)
        ,iimb.attribute11                num_of_case             -- OPM�i��.�P�[�X����
        ,xsib.bowl_inc_num               num_of_bowl             -- Disc�i�ڃA�h�I��.�{�[������
        ,DECODE( iimb.attribute21,
                 NULL, xel.product_code2,
                 iimb.attribute21 )      jan_code                -- JAN�R�[�h
        ,DECODE( iimb.attribute21,
                 NULL, xel.product_name2_alt,
                 msib.description )      item_name               -- ���i��
        ,ooha.org_id                     org_id                  -- �󒍃w�b�_.�c�ƒP��ID
        ,msib.organization_id            organization_id         -- Disc�i��.�݌ɑg�DID
/* 2010/06/16 Ver1.1 Add START */
        ,xca.delivery_base_code          base_code               --  �ڋq�A�h�I��.�[�i���_
/* 2010/06/16 Ver1.1 Add END   */
  FROM   xxcos_edi_headers     xeh   -- EDI�w�b�_���
        ,xxcos_edi_lines       xel   -- EDI���׏��
        ,oe_order_headers_all  ooha  -- �󒍃w�b�_
        ,oe_order_lines_all    oola  -- �󒍖���
        ,ic_item_mst_b         iimb  -- OPM�i��
        ,mtl_system_items_b    msib  -- Disc�i��
        ,xxcmm_system_items_b  xsib  -- Disc�i�ڃA�h�I��
/* 2010/06/16 Ver1.1 Add START */
        , xxcmm_cust_accounts   xca   --  �ڋq�A�h�I��
/* 2010/06/16 Ver1.1 Add END   */
  WHERE  xeh.edi_header_info_id            =  xel.edi_header_info_id
  AND    xeh.edi_delivery_schedule_flag    =  'N'
  AND    xeh.order_connection_number       =  ooha.orig_sys_document_ref
  AND    xel.order_connection_line_number  =  oola.orig_sys_line_ref
  AND    ooha.header_id                    =  oola.header_id
  AND    (
           ( ooha.global_attribute3        =  '02' )
           OR
           ( ooha.global_attribute3        IS NULL )
         )
  AND    oola.inventory_item_id            =  msib.inventory_item_id
  AND    msib.segment1                     =  iimb.item_no
  AND    msib.segment1                     =  xsib.item_code
/* 2010/06/16 Ver1.1 Add START */
  AND    ooha.sold_to_org_id               =   xca.customer_id
/* 2010/06/16 Ver1.1 Add END   */
  ;
--
COMMENT ON COLUMN xxcos_dlv_packing_info_v.edi_header_info_id      IS 'EDI�w�b�_���ID';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.edi_chain_code          IS 'EDI�`�F�[���X�R�[�h';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.shop_code               IS '�X�R�[�h';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.shop_delivery_date      IS '�X�ܔ[�i��';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.invoice_class           IS '�`�[�敪';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.delivery_schedule_flag  IS 'EDI�[�i�\�著�M�σt���O';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.xeh_last_updated_by     IS '�ŏI�X�V��(�w�b�_)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.xeh_last_update_date    IS '�ŏI�X�V��(�w�b�_)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.xeh_last_update_login   IS '�ŏI���O�C��ID(�w�b�_)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.edi_line_info_id        IS 'EDI���׏��ID';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.product_code_itouen     IS '���i�R�[�h(�ɓ���)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.packing_number          IS '����ԍ�';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.sum_order_qty           IS '��������(���v�A�o��)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.sum_shipping_qty        IS '�o�א���(���v�A�o��)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.sum_stockout_qty        IS '���i����(���v�A�o��)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.xel_last_updated_by     IS '�ŏI�X�V��(����)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.xel_last_update_date    IS '�ŏI�X�V��(����)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.xel_last_update_login   IS '�ŏI���O�C��ID(����)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.ordered_item            IS '�󒍕i��';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.order_quantity_uom      IS '�󒍒P��';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.ordered_quantity        IS '�󒍐���(�����l��)';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.num_of_case             IS '�P�[�X����';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.num_of_bowl             IS '�{�[������';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.jan_code                IS 'JAN�R�[�h';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.item_name               IS '���i��';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.org_id                  IS '�c�ƒP��ID';
COMMENT ON COLUMN xxcos_dlv_packing_info_v.organization_id         IS '�݌ɑg�DID';
/* 2010/06/16 Ver1.1 Add START */
COMMENT ON COLUMN xxcos_dlv_packing_info_v.base_code               IS '���_�R�[�h';
/* 2010/06/16 Ver1.1 Add END   */
--
COMMENT ON TABLE  xxcos_dlv_packing_info_v                         IS  '�[�i�\��X�V(�הԏ��)���view';
