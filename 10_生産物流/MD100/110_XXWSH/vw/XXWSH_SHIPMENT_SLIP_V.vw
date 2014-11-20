CREATE OR REPLACE VIEW xxwsh_shipment_slip_v
(
  gyomu_class,
  plan_type,
  request_no,
  head_sales_branch,
  party_name,
  deliver_to,
  party_site_full_name,
  address_line,
  deliver_from,
  shipped_name,
  shipped_date,
  arrival_date,
  shipping_instructions,
  cust_po_number,
  item_class_code,
  shipping_item_code,
  item_short_name,
  case_quantity,
  lot_no,
  num_of_cases,
  quantity,item_um,
  freight_carrier_code,
  delivery_no,
  block,
  prod_class,
  order_type_id,
  inventory_location_id,
  xvs2v_start_date_active,
  xvs2v_end_date_active,
  xv2v_start_date_active,
  xv2v_end_date_active
  )
AS
SELECT
   TO_CHAR ( '1' )                                     AS    gyomu_class         -- �Ɩ����
  ,TO_CHAR ( '2' )                                     AS    plan_type           -- �\��/���ы敪
  ,xoha.request_no                                     AS    request_no          -- �`�[No
  ,xoha.head_sales_branch                              AS    head_sales_branch   -- �Ǌ����_(�R�[�h)
  ,xcav.party_name                                     AS    party_name          -- �Ǌ����_(����)
  ,xoha.deliver_to                                     AS    deliver_to          -- �z����(�R�[�h)
  ,xcas2v.party_site_full_name                         AS    party_site_full_name-- �z����(����)
  , ( xcas2v.address_line1 || xcas2v.address_line2 )   AS    address_line        -- �Z��
  ,xoha.deliver_from                                   AS    deliver_from        -- �o�Ɍ�(�R�[�h)
  ,xil2v.description                                   AS    shipped_name        -- �o�Ɍ�(����)
  ,xoha.shipped_date                                   AS    shipped_date
  ,xoha.arrival_date                                   AS    arrival_date        -- ������
  ,xoha.shipping_instructions                          AS    shipping_instructions    -- �E�v
  ,xoha.cust_po_number                                 AS    cust_po_number      -- ��No
  ,xic4v.item_class_code                               AS    item_class_code     -- �i�ڋ敪
  ,xola.shipping_item_code                             AS    shipping_item_code  -- �R�[�h(�i��)
  ,xim2v.item_short_name                               AS    item_short_name     -- ���i��
  ,CASE 
    WHEN ( xola.reserved_quantity IS NULL ) THEN 
     TRUNC ( ( xola.quantity /  xim2v.num_of_cases ),3 )
    ELSE 
       xola.quantity
   END                                                 AS   case_quantity        -- �P�[�X����
  ,ilm.attribute3                                      AS   lot_no               -- ���b�gNo
  ,xim2v.num_of_cases                                  AS   num_of_cases         -- ����
  ,xmld.actual_quantity                                AS   actual_quantity      -- ����
  ,xim2v.item_um                                       AS   item_um              -- �P��
  ,xoha.result_freight_carrier_code                    AS   freight_carrier_code -- �^���Ǝ�
  ,xoha.delivery_no                                    AS   delivery_no          -- �z��No
------------------------------------------------------------------------------------------------
  ,xil2v.distribution_block                            AS   block                -- �u���b�N
  ,xoha.prod_class                                     AS   prod_class           -- ���i�敪
  ,xoha.order_type_id                                  AS   order_type_id
  ,xil2v.inventory_location_id                         AS   inventory_location_id
  ,NULL                                                AS   xvs2v_start_date_active
  ,NULL                                                AS   xvs2v_end_date_active
  ,NULL                                                AS   xv2v_start_date_active
  ,NULL                                                AS   xv2v_end_date_active
----------------------------------------------------------------------------------------------------
FROM   xxwsh_order_headers_all          xoha         -- �󒍃w�b�_�A�h�I��
      ,xxwsh_order_lines_all            xola         -- �󒍖��׃A�h�I��
      ,xxcmn_item_locations2_v          xil2v        -- OPM�ۊǏꏊ���VIEW2  
      ,xxwsh_oe_transaction_types2_v    xott2v       -- �󒍃^�C�v���VIEW2
      ,xxinv_mov_lot_details            xmld         -- �ړ����b�g�ڍ� ( �A�h�I�� ) 
      ,xxcmn_item_mst2_v                xim2v        -- OPM�i�ڏ��VIEW2
      ,xxcmn_item_categories4_v         xic4v        -- OPM�i�ڃJ�e�S���������VIEW4
      ,ic_lots_mst                      ilm          -- OPM���b�g�}�X�^
      ,xxcmn_cust_acct_sites2_v         xcas2v       -- �ڋq�T�C�g
      ,xxcmn_cust_accounts2_v           xcav         -- �ڋq���VIEW2
WHERE     xoha.req_status               =            '04' -- �o�׎��ьv���
      AND xott2v.order_category_code    <> 'RETURN'
      AND xott2v.shipping_shikyu_class  =            '1'   -- �o�׈˗�
      AND xoha.order_type_id            =            xott2v.transaction_type_id 
      AND xoha.latest_external_flag     =            'Y' 
      AND xoha.head_sales_branch        =            xcav.party_number
      AND xoha.result_deliver_to_id     =            xcas2v.party_site_id
      AND xoha.deliver_from_id          =            xil2v .inventory_location_id 
      AND xoha.order_header_id          =            xola.order_header_id
      AND xola.delete_flag              =            'N'
      AND xola.order_line_id            =            xmld.mov_line_id(+)
      AND xola.shipping_inventory_item_id =          xim2v.inventory_item_id
      AND xim2v.item_id                 =            xic4v.item_id
      AND xmld.lot_id                   =            ilm.lot_id(+)
      AND xmld.item_id                  =            ilm.item_id(+)
      AND xmld.document_type_code(+)    =            '10'      --�o�׈˗�
      AND xmld.record_type_code(+)      =            '20'      --�o�Ɏ���
  --------------------------------------------------------------------------------------------
      AND xcav.start_date_active        <=   xoha.shipped_date
      AND ( xcav.end_date_active IS NULL
            OR ( xcav.end_date_active   >=   xoha.shipped_date ) )
  --------------------------------------------------------------------------------------------
      AND  xcas2v.start_date_active     <=   xoha.shipped_date
      AND ( xcas2v.end_date_active IS NULL
            OR ( xcas2v.end_date_active >=   xoha.shipped_date ) )
  --------------------------------------------------------------------------------------------
      AND  xim2v.start_date_active      <=   xoha.shipped_date
      AND ( xim2v.end_date_active IS NULL
            OR ( xim2v.end_date_active  >=   xoha.shipped_date ) )
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
UNION
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
   TO_CHAR ( '1' )                                     AS    gyomu_class         -- �Ɩ����
  ,TO_CHAR ( '1' )                                     AS    plan_type           -- �\��/���ы敪
  ,xoha.request_no                                     AS    request_no          -- �`�[No
  ,xoha.head_sales_branch                              AS    head_sales_branch   -- �Ǌ����_(�R�[�h)
  ,xcav.party_name                                     AS    party_name          -- �Ǌ����_(����)
  ,xoha.deliver_to                                     AS    deliver_to          -- �z����(�R�[�h)
  ,xcas2v.party_site_full_name                         AS    party_site_full_name-- �z����(����)
  , ( xcas2v.address_line1 || xcas2v.address_line2 )   AS    address_line        -- �Z��
  ,xoha.deliver_from                                   AS    deliver_from        -- �o�Ɍ�(�R�[�h)
  ,xil2v.description                                   AS    shipped_name        -- �o�Ɍ�(����)
  ,xoha.schedule_ship_date                             AS    shipped_date
  ,xoha.schedule_arrival_date                          AS    arrival_date        -- ������
  ,xoha.shipping_instructions                          AS    shipping_instructions    -- �E�v
  ,xoha.cust_po_number                                 AS    cust_po_number      -- ��No
  ,xic4v.item_class_code                               AS    item_class_code     -- �i�ڋ敪
  ,xola.shipping_item_code                             AS    shipping_item_code  -- �R�[�h(�i��)
  ,xim2v.item_short_name                               AS    item_short_name     -- ���i��
  ,CASE
   -- ��������Ă���ꍇ
    WHEN ( xola.reserved_quantity > 0 ) THEN
      CASE 
        WHEN  ( ( xic4v.item_class_code = '5' )
        AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
          TRUNC (xmld.actual_quantity / TO_NUMBER(
                                            CASE
                                              WHEN ( xim2v.num_of_cases > 0 ) THEN
                                                xim2v.num_of_cases
                                              ELSE
                                                TO_CHAR(1)
                                            END
                                          ),3 )
        ELSE
          xmld.actual_quantity
    END
    -- ��������Ă��Ȃ��ꍇ
    WHEN  ( ( xola.reserved_quantity IS NULL ) 
              OR ( xola.reserved_quantity = 0 ) ) THEN
      CASE 
        WHEN  ( ( xic4v.item_class_code = '5' )
        AND     ( xim2v.conv_unit IS NOT NULL ) ) THEN
          TRUNC (xola.quantity / TO_NUMBER(
                                     CASE
                                       WHEN ( xim2v.num_of_cases > 0 ) THEN
                                         xim2v.num_of_cases
                                       ELSE
                                         TO_CHAR(1)
                                       END
                                   ),3 )
        ELSE
          xola.quantity
      END
    END                                                AS     case_quantity      -- �P�[�X����
  ,ilm.attribute3                                      AS     lot_no             -- ���b�gNo
  ,xim2v.num_of_cases                                  AS     num_of_cases       -- ����
  ,CASE 
    --��������Ă���ꍇ
    WHEN ( xola.reserved_quantity > 0 ) THEN ( 
      xmld.actual_quantity                                   --�ړ����b�g�ڍׂ̎��ѐ��ʂ��擾
    ) 
    --��������Ă��Ȃ��ꍇ  
    WHEN  ( ( xola.reserved_quantity IS NULL ) 
              OR  ( xola.reserved_quantity = 0 ) ) THEN ( 
      xola.quantity                                          --�󒍖��׃A�h�I���̐��ʂ��擾
    )
   END                                                 AS    actual_quantity      -- ����
  ,xim2v.item_um                                       AS    item_um              -- �P��
  ,xoha.freight_carrier_code                           AS    freight_carrier_code -- �^���Ǝ�
  ,xoha.delivery_no                                    AS    delivery_no          -- �z��No
-------------------------------------------------------------------------------------------------
  ,xil2v.distribution_block                            AS    block                -- �u���b�N
  ,xoha.prod_class                                     AS    prod_class           -- ���i�敪
  ,xoha.order_type_id                                  AS    order_type_id
  ,xil2v.inventory_location_id                         AS    inventory_location_id
  ,NULL                                                AS    xvs2v_start_date_active
  ,NULL                                                AS    xvs2v_end_date_active
  ,NULL                                                AS    xv2v_start_date_active
  ,NULL                                                AS    xv2v_end_date_active
----------------------------------------------------------------------------------------------------
FROM   xxwsh_order_headers_all          xoha         -- �󒍃w�b�_�A�h�I��
      ,xxwsh_order_lines_all            xola         -- �󒍖��׃A�h�I��
      ,xxcmn_item_locations2_v          xil2v        -- OPM�ۊǏꏊ���VIEW2  
      ,xxwsh_oe_transaction_types2_v    xott2v       -- �󒍃^�C�v���VIEW2
      ,xxinv_mov_lot_details            xmld         -- �ړ����b�g�ڍ� ( �A�h�I�� ) 
      ,xxcmn_item_mst2_v                xim2v        -- OPM�i�ڏ��VIEW2
      ,xxcmn_item_categories4_v         xic4v        -- OPM�i�ڃJ�e�S���������VIEW4
      ,ic_lots_mst                      ilm          -- OPM���b�g�}�X�^
      ,xxcmn_cust_acct_sites2_v         xcas2v       -- �ڋq�T�C�g
      ,xxcmn_cust_accounts2_v           xcav         -- �ڋq���VIEW2
WHERE     xoha.req_status               =            '03' -- �o�׎��ьv���
      AND xott2v.order_category_code    <>           'RETURN'
      AND xott2v.shipping_shikyu_class  =            '1'   -- �o�׈˗�
      AND xoha.order_type_id            =            xott2v.transaction_type_id 
      AND xoha.latest_external_flag     =            'Y' 
      AND xoha.head_sales_branch        =            xcav.party_number
      AND xoha.deliver_to_id            =            xcas2v.party_site_id
      AND xoha.deliver_from_id          =            xil2v .inventory_location_id 
      AND xoha.order_header_id          =            xola.order_header_id
      AND xola.delete_flag              =            'N'
      AND xola.order_line_id            =            xmld.mov_line_id(+)
      AND xola.shipping_inventory_item_id =          xim2v.inventory_item_id
      AND xim2v.item_id                 =            xic4v.item_id
      AND xmld.lot_id                   =            ilm.lot_id(+)
      AND xmld.item_id                  =            ilm.item_id(+)
      AND xmld.document_type_code(+)    =            '10'      -- �o�׈˗�
      AND xmld.record_type_code(+)      =            '10'      -- �w��
  --------------------------------------------------------------------------------------------
      AND xcav.start_date_active        <=   xoha.schedule_ship_date
      AND ( xcav.end_date_active IS NULL
            OR ( xcav.end_date_active   >=   xoha.schedule_ship_date ) )
  --------------------------------------------------------------------------------------------
      AND xcas2v.start_date_active      <=   xoha.schedule_ship_date
      AND ( xcas2v.end_date_active IS NULL
            OR ( xcas2v.end_date_active >=   xoha.schedule_ship_date ) ) 
  --------------------------------------------------------------------------------------------
      AND  xim2v.start_date_active      <=   xoha.schedule_ship_date
      AND ( xim2v.end_date_active IS NULL
            OR ( xim2v.end_date_active  >=   xoha.schedule_ship_date ) ) 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
UNION
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- �x��
SELECT
   TO_CHAR ( '2' )                                     AS    gyomu_class         -- �x��
  ,TO_CHAR ( '2' )                                     AS    plan_type           -- �\��/���ы敪
  ,xoha.request_no                                     AS    request_no          -- �`�[No
  ,xoha.vendor_code                                    AS    head_sales_branch   -- �Ǌ����_(�R�[�h)
  ,xv2v.vendor_full_name                               AS    party_name          -- �Ǌ����_(����)
  ,xoha.vendor_site_code                               AS    deliver_to          -- �z����(�R�[�h)
  ,xvs2v.vendor_site_name                              AS    party_site_full_name-- �z����(����)
  , ( xvs2v.address_line1 || xvs2v.address_line2 )     AS    address_line        -- �Z��
  ,xoha.deliver_from                                   AS    deliver_from        -- �o�Ɍ�(�R�[�h)
  ,xil2v.description                                   AS    shipped_name        -- �o�Ɍ�(����)
  ,xoha.shipped_date                                   AS    shipped_date
  ,xoha.arrival_date                                   AS    arrival_date        -- ������
  ,xoha.shipping_instructions                          AS    shipping_instructions-- �E�v
  ,NULL                                                AS    cust_po_number      -- ��No
  ,xic4v.item_class_code                               AS    item_class_code     -- �i�ڋ敪
  ,xola.shipping_item_code                             AS    shipping_item_code  -- �R�[�h(�i��)
  ,xim2v.item_short_name                               AS    item_short_name     -- ���i��
  ,NULL                                                AS    case_quantity       -- �P�[�X����
  ,xmld.lot_no                                         AS    lot_no              -- ���b�gNo
  ,NULL                                                AS    num_of_cases        -- ����
  ,CASE 
    WHEN ( xott2v.order_category_code   <> 'RETURN' ) THEN ( 
      xmld.actual_quantity 
    )
    WHEN ( xott2v.order_category_code   =  'RETURN' ) THEN (
      ( xmld.actual_quantity * -1 )
    ) 
  END                                                   AS    actual_quantity    -- ����
  ,xim2v.item_um                                        AS   item_um             -- �P��
  ,xoha.result_freight_carrier_code                     AS   freight_carrier_code-- �^���Ǝ�
  ,xoha.delivery_no                                     AS   delivery_no         -- �z��No
-------------------------------------------------------------------------------------------------
  ,xil2v.distribution_block                             AS    block              -- �u���b�N
  ,xoha.prod_class                                      AS    prod_class         -- ���i�敪
  ,xoha.order_type_id                                   AS    order_type_id
  ,xil2v.inventory_location_id                          AS    inventory_location_id
  ,xvs2v.start_date_active                              AS    xvs2v_start_date_active
  ,xvs2v.end_date_active                                AS    xvs2v_end_date_active
  ,xv2v.start_date_active                               AS    xv2v_start_date_active
  ,xv2v.end_date_active                                 AS    xv2v_end_date_active
---------------------------------------------------------------------------------------------------
FROM   
       xxwsh_order_headers_all          xoha         -- �󒍃w�b�_�A�h�I��
      ,xxwsh_order_lines_all            xola         -- �󒍖��׃A�h�I��
      ,xxcmn_vendor_sites2_v            xvs2v        -- �d����T�C�g���VIEW2
      ,xxcmn_vendors2_v                 xv2v         -- �d������VIEW2
      ,xxcmn_item_locations2_v          xil2v        -- OPM�ۊǏꏊ���VIEW2  
      ,xxwsh_oe_transaction_types2_v    xott2v       -- �󒍃^�C�v���VIEW2
      ,xxinv_mov_lot_details            xmld         -- �ړ����b�g�ڍ� ( �A�h�I�� ) 
      ,xxcmn_item_mst2_v                xim2v        -- OPM�i�ڏ��VIEW2
      ,xxcmn_item_categories4_v         xic4v        -- OPM�i�ڃJ�e�S���������VIEW4
      ,ic_lots_mst                      ilm          -- OPM���b�g�}�X�^
WHERE     xoha.req_status               =            '08'
      AND xott2v.shipping_shikyu_class  =            '2'  -- �x���˗�
      AND xoha.order_type_id            =            xott2v.transaction_type_id 
      AND xoha.latest_external_flag     =            'Y' 
      AND xoha.vendor_site_id           =            xvs2v.vendor_site_id
      AND xoha.vendor_id                =            xv2v.vendor_id
      AND xv2v.vendor_id                =            xvs2v.vendor_id
      AND xoha.deliver_from_id          =            xil2v.inventory_location_id 
      AND xoha.order_header_id          =            xola.order_header_id
      AND xola.delete_flag              =            'N'
      AND xola.order_line_id            =            xmld.mov_line_id(+)
      AND xola.shipping_inventory_item_id =          xim2v.inventory_item_id
      AND xim2v.item_id                 =            xic4v.item_id
      AND xmld.lot_id                   =            ilm.lot_id(+)
      AND xmld.item_id                  =            ilm.item_id(+)
      AND xmld.document_type_code(+)    =            '30'      -- �x���w��
      AND xmld.record_type_code(+)      =            '20'      -- �o�Ɏ���
  --------------------------------------------------------------------------------------------
      AND xvs2v.start_date_active       <=   xoha.shipped_date
      AND ( xvs2v.end_date_active IS NULL
            OR (xvs2v.end_date_active  >=   xoha.shipped_date ) ) 
  --------------------------------------------------------------------------------------------
      AND xv2v.start_date_active        <=   xoha.shipped_date
      AND ( xv2v.end_date_active IS NULL
            OR ( xv2v.end_date_active   >=   xoha.shipped_date ) ) 
  --------------------------------------------------------------------------------------------
      AND xim2v.start_date_active       <=   xoha.shipped_date
      AND ( xim2v.end_date_active IS NULL
            OR ( xim2v.end_date_active  >=   xoha.shipped_date ) )
  --------------------------------------------------------------------------------------------
UNION
-- �x��
SELECT
   TO_CHAR ( '2' )                                     AS    gyomu_class              -- �x��
  ,TO_CHAR ( '1' )                                     AS    plan_type           -- �\��/���ы敪
  ,xoha.request_no                                     AS    request_no          -- �`�[No
  ,xoha.vendor_code                                    AS    head_sales_branch -- �Ǌ����_(�R�[�h)
  ,xv2v.vendor_full_name                               AS    party_name          -- �Ǌ����_(����)
  ,xoha.vendor_site_code                               AS    deliver_to          -- �z����(�R�[�h)
  ,xvs2v.vendor_site_name                              AS    party_site_full_name-- �z����(����)
  , ( xvs2v.address_line1 || xvs2v.address_line2 )     AS    address_line        -- �Z��
  ,xoha.deliver_from                                   AS    deliver_from        -- �o�Ɍ�(�R�[�h)
  ,xil2v.description                                   AS    shipped_name        -- �o�Ɍ�(����)
  ,xoha.schedule_ship_date                             AS    shipped_date
  ,xoha.schedule_arrival_date                          AS    arrival_date      -- ������
  ,xoha.shipping_instructions                          AS    shipping_instructions-- �E�v
  ,NULL                                                AS    cust_po_number      -- ��No
  ,xic4v.item_class_code                               AS    item_class_code     -- �i�ڋ敪
  ,xola.shipping_item_code                             AS    shipping_item_code  -- �R�[�h(�i��)
  ,xim2v.item_short_name                               AS    item_short_name     -- ���i��
  ,NULL                                                AS    case_quantity       -- �P�[�X����
  ,xmld.lot_no                                         AS    lot_no              -- ���b�gNo
  ,NULL                                                AS    num_of_cases        -- ����
  ,CASE 
    WHEN ( xott2v.order_category_code   <> 'RETURN' ) THEN ( 
      CASE 
        --��������Ă���ꍇ
        WHEN ( xola.reserved_quantity  > 0  ) THEN ( 
          xmld.actual_quantity                       --�ړ����b�g�ڍׂ̎��ѐ��ʂ��擾
        ) 
        --��������Ă��Ȃ��ꍇ  
        WHEN ( ( xola.reserved_quantity IS NULL  ) 
                  OR ( xola.reserved_quantity = 0 ) ) THEN ( 
          xola.quantity                              --�󒍖��׃A�h�I���̐��ʂ��擾
        )
      END
    )  --�ړ����b�g�ڍׂ̎��ѐ��ʁ�-1���擾
    WHEN ( xott2v.order_category_code   =  'RETURN' ) THEN (
      CASE 
        --��������Ă���ꍇ
        WHEN ( xola.reserved_quantity  > 0  ) THEN ( 
          ( xmld.actual_quantity * -1 )              --�ړ����b�g�ڍׂ̎��ѐ��ʂ��擾
        ) 
        --��������Ă��Ȃ��ꍇ  
        WHEN  ( ( xola.reserved_quantity IS NULL  ) 
                  OR ( xola.reserved_quantity = 0 ) ) THEN ( 
          ( xola.quantity * -1 )                     --�󒍖��׃A�h�I���̐��ʂ��擾
        )
      END
    ) 
  END                                                  AS    actual_quantity     -- ����
  ,xim2v.item_um                                       AS    item_um             -- �P��
  ,xoha.freight_carrier_code                           AS    freight_carrier_code-- �^���Ǝ�
  ,xoha.delivery_no                                    AS    delivery_no         -- �z��No
-------------------------------------------------------------------------------------------------
  ,xil2v.distribution_block                            AS    block               -- �u���b�N
  ,xoha.prod_class                                     AS    prod_class          -- ���i�敪
  ,xoha.order_type_id                                  AS    order_type_id
  ,xil2v.inventory_location_id                         AS    inventory_location_id
  ,xvs2v.start_date_active                             AS    xvs2v_start_date_active
  ,xvs2v.end_date_active                               AS    xvs2v_end_date_active
  ,xv2v.start_date_active                              AS    xv2v_start_date_active
  ,xv2v.end_date_active                                AS    xv2v_end_date_active
---------------------------------------------------------------------------------------------------
FROM   
      xxwsh_order_headers_all           xoha         -- �󒍃w�b�_�A�h�I��
      ,xxwsh_order_lines_all            xola         -- �󒍖��׃A�h�I��
      ,xxcmn_vendor_sites2_v            xvs2v        -- �d����T�C�g���VIEW2
      ,xxcmn_vendors2_v                 xv2v         -- �d������VIEW2
      ,xxcmn_item_locations2_v          xil2v        -- OPM�ۊǏꏊ���VIEW2  
      ,xxwsh_oe_transaction_types2_v    xott2v       -- �󒍃^�C�v���VIEW2
      ,xxinv_mov_lot_details            xmld         -- �ړ����b�g�ڍ� ( �A�h�I�� ) 
      ,xxcmn_item_mst2_v                xim2v        -- OPM�i�ڏ��VIEW2
      ,xxcmn_item_categories4_v         xic4v        -- OPM�i�ڃJ�e�S���������VIEW4
      ,ic_lots_mst                      ilm          -- OPM���b�g�}�X�^
       --�x���̏ꍇ
WHERE     xoha.req_status               =            '07' -- �o�׎��ьv���
      AND xott2v.shipping_shikyu_class  =            '2'  -- �x���˗�
      AND xoha.order_type_id            =            xott2v.transaction_type_id 
      AND xoha.latest_external_flag     =            'Y' 
      AND xoha.vendor_site_id           =            xvs2v.vendor_site_id
      AND xoha.vendor_id                =            xv2v.vendor_id
      AND xv2v.vendor_id                =            xvs2v.vendor_id
      AND xoha.deliver_from_id          =            xil2v.inventory_location_id 
      AND xoha.order_header_id          =            xola.order_header_id
      AND xola.delete_flag              =            'N'
      AND xola.order_line_id            =            xmld.mov_line_id(+)
      AND xola.shipping_inventory_item_id =          xim2v.inventory_item_id
      AND xim2v.item_id                 =            xic4v.item_id
      AND xmld.lot_id                   =            ilm.lot_id(+)
      AND xmld.item_id                  =            ilm.item_id(+)
      AND xmld.document_type_code(+)    =            '30'      -- �x���w��
      AND xmld.record_type_code(+)      =            '10'      -- �w��
  --------------------------------------------------------------------------------------------
      AND xvs2v.start_date_active       <=   xoha.schedule_ship_date
      AND ( xvs2v.end_date_active IS NULL
            OR ( xvs2v.end_date_active  >=   xoha.schedule_ship_date ) )
  --------------------------------------------------------------------------------------------
      AND xv2v.start_date_active        <=   xoha.schedule_ship_date
      AND ( xv2v.end_date_active IS NULL
            OR ( xv2v.end_date_active   >=   xoha.schedule_ship_date ) )
  --------------------------------------------------------------------------------------------
      AND xim2v.start_date_active       <=   xoha.schedule_ship_date
      AND ( xim2v.end_date_active IS NULL
            OR ( xim2v.end_date_active  >=   xoha.schedule_ship_date ) )
  --------------------------------------------------------------------------------------------
/
COMMENT ON TABLE xxwsh_shipment_slip_v IS '�o�ד`�[view'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.gyomu_class IS '�Ɩ����'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.plan_type IS '�\��/���ы敪'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.request_no IS '�`�[NO'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.head_sales_branch IS '�Ǌ����_(�R�[�h)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.party_name IS '�Ǌ����_(����)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.deliver_to IS '�z����(�R�[�h)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.party_site_full_name IS '�z����(����)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.address_line IS '�Z��'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.deliver_from IS '�o�Ɍ�(�R�[�h)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.shipped_name IS '�o�Ɍ�(����)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.shipped_date IS '�o�ɗ\���'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.arrival_date IS '�����\���'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.shipping_instructions IS '�E�v'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.cust_po_number IS '��NO'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.item_class_code IS '�i�ڋ敪'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.shipping_item_code IS '�R�[�h(�i��)'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.item_short_name IS '���i��'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.case_quantity IS '�P�[�X'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.lot_no IS '���b�gNO'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.num_of_cases IS '����'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.quantity IS '����'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.item_um IS '�P��'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.freight_carrier_code IS '�^���Ǝ�'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.delivery_no IS '�z��NO'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.block IS '�u���b�N'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.prod_class IS '���i�敪'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.order_type_id IS '�o�Ɍ`��'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.inventory_location_id IS '�q��ID'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.xvs2v_start_date_active IS '�d����T�C�g�K�p�J�n��'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.xvs2v_end_date_active IS '�d����T�C�g�K�p�I����'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.xv2v_start_date_active IS '�d����K�p�J�n��'
/
COMMENT ON COLUMN xxwsh_shipment_slip_v.xv2v_end_date_active IS '�d����K�p�I����'
/
