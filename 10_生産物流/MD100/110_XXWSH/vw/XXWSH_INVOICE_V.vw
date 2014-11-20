CREATE OR REPLACE VIEW xxwsh_invoice_v
(
  biz_type,
  distribution_block,
  freight_carrier_code,
  prod_class_code,
  order_type_id,
  arrival_date,
  arrival_time_from,
  delivery_no,
  request_no,
  small_quantity,
  cust_po_number,
  shipped_date,
  deliver_from,
  shipped_zip,
  shipped_address,
  shipped_name,
  shipped_phone,
  deli_shitei,
  party_name,
  deliver_to,
  ship_zip,
  ship_address,
  ship_name,
  ship_phone
  )
AS
SELECT
  ---------------------------------------------------------------------------------
  -- �p�����[�^�w�荀��
  -- �Ɩ���ʋ���
   TO_CHAR('1')                       AS  biz_type               --"�Ɩ����"
  ,xilv.distribution_block            AS  distribution_block     --"�����u���b�N"
  ,CASE
     WHEN (xoha.req_status = '04') THEN xoha.result_freight_carrier_code
     WHEN (xoha.req_status = '03') THEN xoha.freight_carrier_code
   END                                AS  freight_carrier_code   --"�^���Ǝ�"
  ,xoha.prod_class                    AS  prod_class_code        --"���i�敪"
  -- �o�׎x���p�p�����[�^
  ,xoha.order_type_id                 AS  order_type_id          --"�󒍃^�C�vID"
  ---------------------------------------------------------------------------------
  -- ���ʏo�͍���
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xoha.arrival_date
    WHEN (xoha.req_status = '03')  THEN xoha.schedule_arrival_date
   END                                AS  arrival_date           --"���ח\���"
  ,xoha.arrival_time_from             AS  arrival_time_from      --"���Ԏw��"
  ,xoha.delivery_no                   AS  delivery_no            --"�z��No"
  ,xoha.request_no                    AS  request_no             --"�˗�No/�ړ�No"
  ,xoha.small_quantity                AS  small_quantity         --"��"
  ,xoha.cust_po_number                AS  cust_po_number         --"�ڋq����No"
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xoha.shipped_date
    WHEN (xoha.req_status = '03')  THEN xoha.schedule_ship_date
   END                                AS  shipped_date           --"�o�ɗ\���"
  ,xoha.deliver_from                  AS  deliver_from           --"�o�Ɍ�(�R�[�h)"
  ,xlv.zip                            AS  shipped_zip            --"�o�Ɍ�(�X�֔ԍ�)"
  ,xlv.address_line1                  AS  shipped_address        --"�o�Ɍ�(�Z��)"
  ,xilv.description                   AS  shipped_name           --"�o�Ɍ�(����)"
  ,xlv.phone                          AS  shipped_phone          --"�o�Ɍ�(�d�b�ԍ�)"
  ,TO_CHAR('�z�B�w��@�L �E ��')      AS  deli_shitei            --"�z�B�w��"
  ---------------------------------------------------------------------------------
  ,xcav.party_name                   AS  party_name              --"�Ǌ����_"
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xoha.result_deliver_to
    WHEN (xoha.req_status = '03')  THEN xoha.deliver_to
   END                                AS  deliver_to             --"�z����/���ɐ�(�R�[�h)"
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xcasv1.zip
    WHEN (xoha.req_status = '03')  THEN xcasv2.zip
   END                                AS  ship_zip               --"�z����/���ɐ�(�X�֔ԍ�)"
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xcasv1.address_line1
    WHEN (xoha.req_status = '03')  THEN xcasv2.address_line1 || xcasv2.address_line2
   END                                AS  ship_address           --"�z����/���ɐ�(�Z��)"
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xcasv1.party_site_full_name
    WHEN (xoha.req_status = '03')  THEN xcasv2.party_site_full_name
   END                                AS  ship_name               --"�z����/���ɐ�(����)"
  ,CASE
    WHEN (xoha.req_status = '04')  THEN xcasv1.phone
    WHEN (xoha.req_status = '03')  THEN xcasv2.phone
   END                                AS  ship_phone              --"�z����/���ɐ�(�d�b�ԍ�)"
FROM
   xxwsh_order_headers_all        xoha    -- �󒍃w�b�_�A�h�I��
  ,xxwsh_order_lines_all          xola    -- �󒍖��׃A�h�I��
  ,xxwsh_oe_transaction_types2_v  xottv   -- �󒍃^�C�v���VIEW2
  ,xxcmn_item_locations2_v        xilv    -- OPM�ۊǏꏊ���(�o�׌����)(����)
  ,xxcmn_locations2_v             xlv     -- ���Ə����(�o�׌����)
  ,xxcmn_cust_acct_sites2_v       xcasv1  -- �ڋq�T�C�g���(�o�א���)(����)
  ,xxcmn_cust_acct_sites2_v       xcasv2  -- �ڋq�T�C�g���(�o�א���)(�w��)
  ,xxcmn_cust_accounts2_v         xcav    -- �ڋq���VIEW2
WHERE
  ----------------------------------------------------------------------------------
  -- �w�b�_���
       xoha.order_type_id           = xottv.transaction_type_id
  AND  xottv.order_category_code   <> 'RETURN'   -- �󒍃J�e�S���F�ԕi
  AND  xoha.req_status             <> '99'       -- �X�e�[�^�X�F���
  AND  xottv.shipping_shikyu_class  = '1'        -- �o�׎x���敪�F�u�o�׈˗��v
  AND  xoha.req_status             >= '03'       -- �X�e�[�^�X�F�u���ߍς݁v
  AND  xoha.latest_external_flag    = 'Y'        -- �ŐV�t���O
  -- �o�׌����
  AND  xoha.deliver_from_id         = xilv.inventory_location_id
  AND  xilv.location_id             = xlv.location_id
  -- �o�א���
  AND  xoha.head_sales_branch       =  xcav.party_number
  AND  xoha.result_deliver_to_id    = xcasv1.party_site_id(+)
  AND  xoha.deliver_to_id    = xcasv2.party_site_id(+)
  ----------------------------------------------------------------------------------
  -- ���׏��
  AND  xoha.order_header_id         =  xola.order_header_id
  AND  NVL(xola.delete_flag,0)     <>  'Y'
  ----------------------------------------------------------------------------------
  -- �K�p��
  --"���Ə�.�K�p�J�n��"
  AND xlv.start_date_active        <= xoha.schedule_ship_date
  --"���Ə�.�K�p�I����"
  AND ( xlv.end_date_active IS NULL
        OR
        xlv.end_date_active        >= xoha.schedule_ship_date
      )
  --"�ڋq.�K�p�J�n��"(����)
  AND ( xcasv1.start_date_active IS NULL
        OR
        xcasv1.start_date_active   <= xoha.shipped_date
      )
  --"�ڋq.�K�p�I����"(����)
  AND ( xcasv1.end_date_active IS NULL
        OR
        xcasv1.end_date_active     >= xoha.shipped_date
      )
  --"�ڋq.�K�p�J�n��"(�w��)
  AND ( xcasv2.start_date_active IS NULL
        OR
        xcasv2.start_date_active   <= xoha.schedule_ship_date
      )
  --"�ڋq.�K�p�I����"(�w��)
  AND ( xcasv2.end_date_active IS NULL
        OR
        xcasv2.end_date_active     >= xoha.schedule_ship_date
      )
  --"�ڋq���.�K�p�J�n��"
  AND xcav.start_date_active       <= xoha.schedule_ship_date
  --"�ڋq���.�K�p�I����"
  AND ( xcav.end_date_active IS NULL
        OR
        xcav.end_date_active       >= xoha.schedule_ship_date
      )
--------------------------------------------------------------------------------
UNION ALL
--�x���˗����̒��o
SELECT
  ---------------------------------------------------------------------------------
  -- �p�����[�^�w�荀��
  -- �Ɩ���ʋ���
   TO_CHAR('2')                       AS  biz_type               --"�Ɩ����"
  ,xilv.distribution_block            AS  distribution_block     --"�����u���b�N"
  ,CASE
    WHEN (xoha.req_status = '08') THEN xoha.result_freight_carrier_code
    WHEN (xoha.req_status = '07') THEN xoha.freight_carrier_code
   END                                AS  freight_carrier_code   --"�^���Ǝ�"
  ,xoha.prod_class                    AS  prod_class_code        --"���i�敪"
  -- �o�׎x���p�p�����[�^
  ,xoha.order_type_id                 AS  order_type_id          --"�󒍃^�C�vID"
  ---------------------------------------------------------------------------------
  -- ���ʏo�͍���
  ,CASE
    WHEN (xoha.req_status = '08') THEN xoha.arrival_date
    WHEN (xoha.req_status = '07') THEN xoha.schedule_arrival_date
   END                                AS  arrival_date           --"���ח\���"
  ,xoha.arrival_time_from             AS  arrival_time_from      --"���Ԏw��"
  ,xoha.delivery_no                   AS  delivery_no            --"�z��No"
  ,xoha.request_no                    AS  request_no             --"�˗�No/�ړ�No"
  ,xoha.small_quantity                AS  small_quantity         --"��"
  ,xoha.cust_po_number                AS  cust_po_number         --"�ڋq����No"
  ,CASE
    WHEN (xoha.req_status = '08') THEN xoha.shipped_date
    WHEN (xoha.req_status = '07') THEN xoha.schedule_ship_date
   END                                AS  shipped_date           --"�o�ɗ\���"
  ,xoha.deliver_from                  AS  deliver_from           --"�o�Ɍ�(�R�[�h)"
  ,xlv.zip                            AS  shipped_zip            --"�o�Ɍ�(�X�֔ԍ�)"
  ,xlv.address_line1                  AS  shipped_address        --"�o�Ɍ�(�Z��)"
  ,xilv.description                   AS  shipped_name           --"�o�Ɍ�(����)"
  ,xlv.phone                          AS  shipped_phone          --"�o�Ɍ�(�d�b�ԍ�)"
  ,TO_CHAR('�z�B�w��@�L �E ��')      AS  deli_shitei            --"�z�B�w��"
  ---------------------------------------------------------------------------------
  ,NULL                               AS  party_name   --"�Ǌ����_"
  ,xoha.vendor_site_code              AS  deliver_to             --"�z����/���ɐ�(�R�[�h)"
  ,CASE
    WHEN  (xoha.req_status = '08') THEN xvsv1.zip
    WHEN  (xoha.req_status = '07') THEN xvsv2.zip
   END                                AS  ship_zip               --"�z����/���ɐ�(�X�֔ԍ�)"
  ,CASE
    WHEN  (xoha.req_status = '08') THEN xvsv1.address_line1 || xvsv1.address_line2
    WHEN  (xoha.req_status = '07') THEN xvsv2.address_line1 || xvsv2.address_line2
   END                                AS  ship_address           --"�z����/���ɐ�(�Z��)"
  ,CASE
    WHEN  (xoha.req_status = '08') THEN xvsv1.vendor_site_name
    WHEN  (xoha.req_status = '07') THEN xvsv2.vendor_site_name
   END                                AS  ship_name              --"�z����/���ɐ�(����)"
  ,CASE
    WHEN  (xoha.req_status = '08') THEN xvsv1.phone
    WHEN  (xoha.req_status = '07') THEN xvsv2.phone
   END                                AS  ship_phone             --"�z����/���ɐ�(�d�b�ԍ�)"
FROM
   xxwsh_order_headers_all        xoha    -- �󒍃w�b�_�A�h�I��
  ,xxwsh_order_lines_all          xola    -- �󒍖��׃A�h�I��
  ,xxwsh_oe_transaction_types2_v  xottv   -- �󒍃^�C�v���VIEW2
  ,xxcmn_item_locations2_v        xilv    -- OPM�ۊǏꏊ���(�o�׌����)
  ,xxcmn_locations2_v             xlv     -- ���Ə����(�o�׌����)
  ,xxcmn_vendor_sites2_v          xvsv1   -- �d����T�C�g���(���їp)
  ,xxcmn_vendor_sites2_v          xvsv2   -- �d����T�C�g���(�w���p)
WHERE
  ----------------------------------------------------------------------------------
  -- �w�b�_���
       xoha.order_type_id           = xottv.transaction_type_id
  AND  xottv.order_category_code   <> 'RETURN'   -- �󒍃J�e�S���F�ԕi
  AND  xoha.req_status             <> '99'       -- �X�e�[�^�X�F���
  AND  xottv.shipping_shikyu_class  = '2'        -- �o�׎x���敪�F�u�x���˗��v
  AND  xoha.req_status             >= '07'       -- �X�e�[�^�X�F�u��̍ρv
  AND  xoha.latest_external_flag    = 'Y'        -- �ŐV�t���O
  -- �o�׌����
  AND  xoha.deliver_from_id         = xilv.inventory_location_id
  AND  xilv.location_id             =  xlv.location_id
  -- �d����T�C�g(���їp)
  AND  xoha.vendor_id               =  xvsv1.vendor_id(+)
  -- �d����T�C�g(�w���p)
  AND  xoha.vendor_id               =  xvsv2.vendor_id(+)
  ----------------------------------------------------------------------------------
  -- ���׏��
  AND  xoha.order_header_id         =  xola.order_header_id
  AND  NVL(xola.delete_flag,0)     <>  'Y'
  ----------------------------------------------------------------------------------
  -- �K�p��
  --"���Ə�.�K�p�J�n��"
  AND xlv.start_date_active        <= xoha.schedule_ship_date
  --"���Ə�.�K�p�I����"
  AND ( xlv.end_date_active IS NULL
        OR
        xlv.end_date_active        >= xoha.schedule_ship_date
      )
  --"�d����.�K�p�J�n��"(����)
  AND ( xvsv1.start_date_active IS NULL
        OR 
        xvsv1.start_date_active    <= xoha.shipped_date
      )
  --"�d����.�K�p�I����"(����)
  AND ( xvsv1.end_date_active IS NULL
        OR
        xvsv1.end_date_active      >= xoha.shipped_date
      )--
  --"�d����.�K�p�J�n��"(�w��)
  AND ( xvsv2.start_date_active IS NULL
        OR 
        xvsv2.start_date_active    <= xoha.schedule_ship_date
      )
  --"�d����.�K�p�I����"(�w��)
  AND ( xvsv2.end_date_active IS NULL
        OR
        xvsv2.end_date_active      >= xoha.schedule_ship_date
      )
--------------------------------------------------------------------------------
UNION ALL
--�ړ��w�����̒��o
SELECT
  ---------------------------------------------------------------------------------
  -- �p�����[�^�w�荀��
  -- �Ɩ���ʋ���
   TO_CHAR('3')                        AS  biz_type               --"�Ɩ����"
  ,xilv2.distribution_block            AS  distribution_block     --"�����u���b�N"
  ,CASE
    WHEN (xmrih.status IN ('04','06')) THEN xmrih.actual_freight_carrier_code
    WHEN (xmrih.status IN ('02','03','05')) THEN xmrih.freight_carrier_code
    END                                AS  freight_carrier_code   --"�^���Ǝ�"
  ,xmrih.item_class                    AS  prod_class_code        --"���i�敪"
  -- �o�׎x���p�p�����[�^
  ,NULL                                AS  order_type_id          --"�󒍃^�C�vID"
  ---------------------------------------------------------------------------------
  -- ���ʏo�͍���
  ,CASE
    WHEN (xmrih.status IN ('04','06')) THEN xmrih.actual_arrival_date
    WHEN (xmrih.status IN ('02','03','05')) THEN xmrih.schedule_arrival_date
   END                                 AS  arrival_date           --"���ח\���"
  ,xmrih.arrival_time_from             AS  arrival_time_from      --"���Ԏw��"
  ,xmrih.delivery_no                   AS  delivery_no            --"�z��No"
  ,xmrih.mov_num                       AS  request_no             --"�˗�No/�ړ�No"
  ,xmrih.small_quantity                AS  small_quantity         --"��"
  ,NULL                                AS  cust_po_number         --"�ڋq����No"
  ,CASE
    WHEN (xmrih.status IN ('04','06')) THEN xmrih.actual_ship_date
    WHEN (xmrih.status IN ('02','03','05')) THEN xmrih.schedule_ship_date
   END                                 AS  shipped_date           --"�o�ɗ\���"
  ,xmrih.shipped_locat_code            AS  deliver_from           --"�o�Ɍ�(�R�[�h)"
  ,xlv2.zip                            AS  shipped_zip            --"�o�Ɍ�(�X�֔ԍ�)"
  ,xlv2.address_line1                  AS  shipped_address        --"�o�Ɍ�(�Z��)"
  ,xilv2.description                   AS  shipped_name           --"�o�Ɍ�(����)"
  ,xlv2.phone                          AS  shipped_phone          --"�o�Ɍ�(�d�b�ԍ�)"
  ,TO_CHAR('�z�B�w��@�L �E ��')       AS  deli_shitei            --"�z�B�w��"
  ---------------------------------------------------------------------------------
  -- �Ɩ���ʂ���
  ,NULL                                AS  party_name             --"�Ǌ����_"
  ,xmrih.ship_to_locat_code            AS  deliver_to             --"�z����/���ɐ�(�R�[�h)"
  ,xlv1.zip                            AS  ship_zip               --"�z����/���ɐ�(�X�֔ԍ�)"
  ,xlv1.address_line1                  AS  ship_address           --"�z����/���ɐ�(�Z��)"
  ,xilv1.description                   AS  ship_name              --"�z����/���ɐ�(����)"
  ,xlv1.phone                          AS  ship_phone             --"�z����/���ɐ�(�d�b�ԍ�)"
FROM
   xxinv_mov_req_instr_headers    xmrih     -- �ړ��˗�/�w���w�b�_(�A�h�I��)
  ,xxinv_mov_req_instr_lines      xmril     -- �ړ��˗�/�w������(�A�h�I��)
  ,xxcmn_item_locations2_v        xilv1     -- OPM�ۊǏꏊ���(���ɐ�)
  ,xxcmn_item_locations2_v        xilv2     -- OPM�ۊǏꏊ���(�o�Ɍ�)
  ,xxcmn_locations2_v             xlv1      -- ���Ə����(���ɐ�)
  ,xxcmn_locations2_v             xlv2      -- ���Ə����(�o�Ɍ�)
WHERE
  ----------------------------------------------------------------------------------
  -- �w�b�_���
       xmrih.status            >= '02' --�X�e�[�^�X:�˗���
  AND  xmrih.status            <> '99' --�X�e�[�^�X:���
  AND  xmrih.mov_type           = '1'  --�X�e�[�^�X:�ϑ�����
  -- ���ɐ�
  AND  xmrih.ship_to_locat_id   =  xilv1.inventory_location_id
  AND  xilv1.location_id        =  xlv1.location_id
  -- �o�Ɍ�
  AND  xmrih.shipped_locat_id   =  xilv2.inventory_location_id
  AND  xilv2.location_id        =  xlv2.location_id
  ----------------------------------------------------------------------------------
  -- ���׏��
  AND  xmrih.mov_hdr_id         = xmril.mov_hdr_id
  AND  xmril.delete_flg        <> 'Y'
  ----------------------------------------------------------------------------------
  -- �K�p��
  --"���ɐ�.�K�p�J�n��"
  AND xlv1.start_date_active   <= xmrih.schedule_ship_date
  --"���ɐ�.�K�p�I����"
  AND ( xlv1.end_date_active IS NULL
        OR
        xlv1.end_date_active   >= xmrih.schedule_ship_date
      )
  --"�o�Ɍ�.�K�p�J�n��"
  AND xlv2.start_date_active   <= xmrih.schedule_ship_date
  --"�o�Ɍ�.�K�p�I����"
  AND ( xlv2.end_date_active IS NULL
        OR
        xlv2.end_date_active   >= xmrih.schedule_ship_date
      )
  --"���Ə�(���ɐ�).�K�p�J�n��"
  AND xlv1.start_date_active   <= xmrih.schedule_ship_date
  --"���Ə�(���ɐ�).�K�p�I����"
  AND ( xlv1.end_date_active IS NULL
        OR
        xlv1.end_date_active   >= xmrih.schedule_ship_date
      )
  --"���Ə�(�o�Ɍ�).�K�p�J�n��"
  AND xlv2.start_date_active   <= xmrih.schedule_ship_date
  --"���Ə�(�o�Ɍ�).�K�p�I����"
  AND ( xlv2.end_date_active IS NULL
        OR
        xlv2.end_date_active   >= xmrih.schedule_ship_date
      )
  ------------------------------------------------------------------------------------
ORDER BY
   deliver_from  ASC
  ,shipped_date  ASC
  ,delivery_no   ASC
  ,deliver_to    ASC
/
COMMENT ON TABLE xxwsh_invoice_v IS '�����VIEW'
/
COMMENT ON COLUMN xxwsh_invoice_v.biz_type is '�Ɩ����'
/
COMMENT ON COLUMN xxwsh_invoice_v.distribution_block IS '�����u���b�N'
/
COMMENT ON COLUMN xxwsh_invoice_v.freight_carrier_code IS '�^���Ǝ�'
/
COMMENT ON COLUMN xxwsh_invoice_v.prod_class_code IS '���i�敪'
/
COMMENT ON COLUMN xxwsh_invoice_v.order_type_id IS '�󒍃^�C�vID'
/
COMMENT ON COLUMN xxwsh_invoice_v.arrival_date IS '���ח\���'
/
COMMENT ON COLUMN xxwsh_invoice_v.arrival_time_from IS '���Ԏw��'
/
COMMENT ON COLUMN xxwsh_invoice_v.delivery_no IS '�z��NO'
/
COMMENT ON COLUMN xxwsh_invoice_v.request_no IS '�˗�NO/�ړ�NO'
/
COMMENT ON COLUMN xxwsh_invoice_v.small_quantity IS '��'
/
COMMENT ON COLUMN xxwsh_invoice_v.cust_po_number IS '�ڋq����NO'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_date IS '�o�ɗ\���'
/
COMMENT ON COLUMN xxwsh_invoice_v.deliver_from IS '�o�Ɍ�(�R�[�h)'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_zip IS '�o�Ɍ�(����)'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_address IS '�o�Ɍ�(�X�֔ԍ�)'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_name IS '�o�Ɍ�(�Z��)'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_phone IS '�o�Ɍ�(�d�b�ԍ�)'
/
COMMENT ON COLUMN xxwsh_invoice_v.deli_shitei IS '�z�B�w��'
/
COMMENT ON COLUMN xxwsh_invoice_v.party_name IS '�Ǌ����_'
/
COMMENT ON COLUMN xxwsh_invoice_v.deliver_to IS '�z����/���ɐ�(�R�[�h)'
/
COMMENT ON COLUMN xxwsh_invoice_v.ship_zip IS '�z����/���ɐ�(����)'
/
COMMENT ON COLUMN xxwsh_invoice_v.ship_address IS '�z����/���ɐ�(�X�֔ԍ�)'
/
COMMENT ON COLUMN xxwsh_invoice_v.ship_name IS '�z����/���ɐ�(�Z��)'
/
COMMENT ON COLUMN xxwsh_invoice_v.ship_phone IS '�z����/���ɐ�(�d�b�ԍ�)'
/
