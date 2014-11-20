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
--2009/01/21 Mod Start
  ,CASE
     WHEN xilv.whse_inside_outside_div = 1 THEN
       SUBSTRB('(��)�ɓ���' || xilv.description,1,50)
     ELSE
       xilv.description
   END                                AS  shipped_name           --"�o�Ɍ�(����)"
--  ,xilv.description                   AS  shipped_name           --"�o�Ɍ�(����)"
--2009/01/21 Mod End
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
--del start 2008/07/14
--  ,xxwsh_order_lines_all          xola    -- �󒍖��׃A�h�I��
--del end 2008/07/14
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
--add start 2008/07/14
  AND  NVL(xoha.small_quantity,0) > 0            -- ������>0
--add end 2008/07/14
  -- �o�׌����
  AND  xoha.deliver_from_id         = xilv.inventory_location_id
  AND  xilv.location_id             = xlv.location_id
  -- �o�א���
  AND  xoha.head_sales_branch       =  xcav.party_number
--mod start 2009/05/28 �{�ԏ�Q#1398
--  AND  xoha.result_deliver_to_id    = xcasv1.party_site_id(+)
--  AND  xoha.deliver_to_id    = xcasv2.party_site_id(+)
  AND  xoha.result_deliver_to       = xcasv1.party_site_number(+)
  AND  xoha.deliver_to              = xcasv2.party_site_number(+)
--mod end 2009/05/28
--add start 2009/05/28 �{�ԏ�Q#1398
  AND  NVL(xcasv1.party_site_status, 'A')     = 'A'  -- �L���ȏo�א�
  AND  NVL(xcasv1.cust_acct_site_status, 'A') = 'A'  -- �L���ȏo�א�
  AND  NVL(xcasv2.party_site_status, 'A')     = 'A'  -- �L���ȏo�א�
  AND  NVL(xcasv2.cust_acct_site_status, 'A') = 'A'  -- �L���ȏo�א�
--add end 2009/05/28
  ----------------------------------------------------------------------------------
--del start 2008/07/14
--  -- ���׏��
--  AND  xoha.order_header_id         =  xola.order_header_id
--  AND  NVL(xola.delete_flag,0)     <>  'Y'
--del end 2008/07/14
  ----------------------------------------------------------------------------------
  -- �K�p��
--mod start 2008/06/27
--  --"���Ə�.�K�p�J�n��"
--  AND xlv.start_date_active        <= xoha.schedule_ship_date
--  --"���Ə�.�K�p�I����"
--  AND ( xlv.end_date_active IS NULL
--        OR
--        xlv.end_date_active        >= xoha.schedule_ship_date
--      )
  --���Ə����(�o�׌����)
  AND NVL(xoha.shipped_date,xoha.schedule_ship_date)                 --�K�p�J�n�� <= �o�ד�(�o�ח\���) <= �K�p�I����
    BETWEEN xlv.start_date_active
    AND NVL(xlv.end_date_active,NVL(xoha.shipped_date,xoha.schedule_ship_date))
--mod end 2008/06/27
--mod start 2008/06/27
--  --"�ڋq.�K�p�J�n��"
--  AND ( DECODE (xoha.req_status
--             , '04' , xcasv1.start_date_active 
--             , '03' , xcasv2.start_date_active)
--             IS NULL 
--        OR 
--        DECODE (xoha.req_status
--             , '04' , xcasv1.start_date_active 
--             , '03' , xcasv2.start_date_active)
--             <=
--        DECODE (xoha.req_status
--             , '04' , xoha.shipped_date 
--             , '03' , xoha.schedule_ship_date)
--      )
--  --"�ڋq.�K�p�I����"
--  AND ( DECODE (xoha.req_status
--             , '04' , xcasv1.end_date_active 
--             , '03' , xcasv2.end_date_active)
--             IS NULL 
--        OR 
--        DECODE (xoha.req_status
--             , '04' , xcasv1.end_date_active 
--             , '03' , xcasv2.end_date_active)
--             >=
--        DECODE (xoha.req_status
--             , '04' , xoha.shipped_date 
--             , '03' , xoha.schedule_ship_date)
--      )
  --�ڋq�T�C�g���(�o�א���)(����)
  AND NVL(xoha.shipped_date,xoha.schedule_ship_date)
    BETWEEN xcasv1.start_date_active(+)
    AND NVL(xcasv1.end_date_active(+),NVL(xoha.shipped_date,xoha.schedule_ship_date))
  --�ڋq�T�C�g���(�o�א���)(�w��)
  AND NVL(xoha.shipped_date,xoha.schedule_ship_date)
    BETWEEN xcasv2.start_date_active(+)
    AND NVL(xcasv2.end_date_active(+),NVL(xoha.shipped_date,xoha.schedule_ship_date))
--mod end 2008/06/27
--mod start 2008/06/27
--  --"�ڋq���.�K�p�J�n��"
--  AND xcav.start_date_active       <= xoha.schedule_ship_date
--  --"�ڋq���.�K�p�I����"
--  AND ( xcav.end_date_active IS NULL
--        OR
--        xcav.end_date_active       >= xoha.schedule_ship_date
--      )
  --�ڋq���VIEW2
  AND NVL(xoha.shipped_date,xoha.schedule_ship_date)                 --�K�p�J�n�� <= �o�ד�(�o�ח\���) <= �K�p�I����
    BETWEEN xcav.start_date_active
    AND NVL(xcav.end_date_active,NVL(xoha.shipped_date,xoha.schedule_ship_date))
--mod end 2008/06/27
--add start 2008/06/27
  --OPM�ۊǏꏊ���(�o�׌����)(����)
  AND   NVL(xoha.shipped_date,xoha.schedule_ship_date)                 --�K�p�J�n�� <= �o�ד�(�o�ח\���) <= �K�p�I����
    BETWEEN xilv.date_from
    AND NVL(xilv.date_to,NVL(xoha.shipped_date,xoha.schedule_ship_date))
--add end 2008/06/27
--add start 2009/05/26 �{�ԏ�Q#1493 �z��No���Ȃ��f�[�^�͏o���Ȃ��B
  AND xoha.delivery_no IS NOT NULL
--add end 2009/05/26
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
--2009/01/21 Mod Start
  ,CASE
     WHEN xilv.whse_inside_outside_div = 1 THEN
       SUBSTRB('(��)�ɓ���' || xilv.description,1,50)
     ELSE
       xilv.description
     END                              AS  shipped_name           --"�o�Ɍ�(����)"
--  ,xilv.description                   AS  shipped_name           --"�o�Ɍ�(����)"
--2009/01/21 Mod End
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
--del start 2008/07/14
--  ,xxwsh_order_lines_all          xola    -- �󒍖��׃A�h�I��
--del end 2008/07/14
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
--add start 2008/07/14
  AND  NVL(xoha.small_quantity,0) > 0            -- ������>0
--add end 2008/07/14
  -- �o�׌����
  AND  xoha.deliver_from_id         = xilv.inventory_location_id
  AND  xilv.location_id             =  xlv.location_id
--mod start 2008/07/14
--  -- �d����T�C�g(���їp)
--  AND  xoha.vendor_id               =  xvsv1.vendor_id(+)
--  -- �d����T�C�g(�w���p)
--  AND  xoha.vendor_id               =  xvsv2.vendor_id(+)
  -- �d����T�C�g(���їp)
  AND  xoha.vendor_site_id               =  xvsv1.vendor_site_id(+)
  -- �d����T�C�g(�w���p)
  AND  xoha.vendor_site_id               =  xvsv2.vendor_site_id(+)
--mod end 2008/07/14
  ----------------------------------------------------------------------------------
--del start 2008/07/14
--  -- ���׏��
--  AND  xoha.order_header_id         =  xola.order_header_id
--  AND  NVL(xola.delete_flag,0)     <>  'Y'
--del end 2008/07/14
  ----------------------------------------------------------------------------------
  -- �K�p��
--mod start 2008/06/27
--  --"���Ə�.�K�p�J�n��"
--  AND xlv.start_date_active        <= xoha.schedule_ship_date
--  --"���Ə�.�K�p�I����"
--  AND ( xlv.end_date_active IS NULL
--        OR
--        xlv.end_date_active        >= xoha.schedule_ship_date
--      )
  --���Ə����(�o�׌����)
  AND NVL(xoha.shipped_date,xoha.schedule_ship_date)
    BETWEEN xlv.start_date_active
    AND NVL(xlv.end_date_active,NVL(xoha.shipped_date,xoha.schedule_ship_date))
--mod end 2008/06/27
--mod start 2008/06/27
--  --"�d����.�K�p�J�n��"
--  AND ( DECODE (xoha.req_status
--             , '08' , xvsv1.start_date_active 
--             , '07' , xvsv2.start_date_active)
--             IS NULL 
--        OR 
--        DECODE (xoha.req_status
--             , '08' , xvsv1.start_date_active 
--             , '07' , xvsv2.start_date_active)
--             <=
--        DECODE (xoha.req_status
--             , '08' , xoha.shipped_date 
--             , '07' , xoha.schedule_ship_date)
--      )
--  --"�d����.�K�p�I����"
--  AND ( DECODE (xoha.req_status
--             , '08' , xvsv1.end_date_active 
--             , '07' , xvsv2.end_date_active)
--             IS NULL 
--        OR 
--        DECODE (xoha.req_status
--             , '08' , xvsv1.end_date_active 
--             , '07' , xvsv2.end_date_active)
--             >=
--        DECODE (xoha.req_status
--             , '08' , xoha.shipped_date 
--             , '07' , xoha.schedule_ship_date)
--      )
  --�d����T�C�g���(���їp)
  AND NVL(xoha.shipped_date,xoha.schedule_ship_date)
    BETWEEN xvsv1.start_date_active(+)
    AND NVL(xvsv1.end_date_active(+),NVL(xoha.shipped_date,xoha.schedule_ship_date))
  --�d����T�C�g���(�w���p)
  AND NVL(xoha.shipped_date,xoha.schedule_ship_date)
    BETWEEN xvsv2.start_date_active(+)
    AND NVL(xvsv2.end_date_active(+),NVL(xoha.shipped_date,xoha.schedule_ship_date))
--mod end 2008/06/27
--add start 2008/06/27
  --OPM�ۊǏꏊ���(�o�׌����)
  AND   NVL(xoha.shipped_date,xoha.schedule_ship_date)                 --�K�p�J�n�� <= �o�ד�(�o�ח\���) <= �K�p�I����
    BETWEEN xilv.date_from
    AND NVL(xilv.date_to,NVL(xoha.shipped_date,xoha.schedule_ship_date))
--add end 2008/06/27
--add start 2009/05/26 �{�ԏ�Q#1493 �z��No���Ȃ��f�[�^�͏o���Ȃ��B
  AND xoha.delivery_no IS NOT NULL
--add end 2009/05/26
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
--2009/01/21 Mod Start
  ,CASE
     WHEN xilv2.whse_inside_outside_div = 1 THEN
       SUBSTRB('(��)�ɓ���' || xilv2.description,1,50)
     ELSE
       xilv2.description
     END                               AS  shipped_name           --"�o�Ɍ�(����)"
--  ,xilv2.description                   AS  shipped_name           --"�o�Ɍ�(����)"
--2009/01/21 Mod End
  ,xlv2.phone                          AS  shipped_phone          --"�o�Ɍ�(�d�b�ԍ�)"
  ,TO_CHAR('�z�B�w��@�L �E ��')       AS  deli_shitei            --"�z�B�w��"
  ---------------------------------------------------------------------------------
  -- �Ɩ���ʂ���
  ,NULL                                AS  party_name             --"�Ǌ����_"
  ,xmrih.ship_to_locat_code            AS  deliver_to             --"�z����/���ɐ�(�R�[�h)"
  ,xlv1.zip                            AS  ship_zip               --"�z����/���ɐ�(�X�֔ԍ�)"
  ,xlv1.address_line1                  AS  ship_address           --"�z����/���ɐ�(�Z��)"
--2009/01/21 Mod Start
  ,CASE
     WHEN xilv1.whse_inside_outside_div = 1 THEN
       SUBSTRB('(��)�ɓ���' || xilv1.description,1,50)
     ELSE
       xilv1.description
     END                               AS  shipped_name           --"�o�Ɍ�(����)"
--  ,xilv1.description                   AS  ship_name              --"�z����/���ɐ�(����)"
--2009/01/21 Mod End
  ,xlv1.phone                          AS  ship_phone             --"�z����/���ɐ�(�d�b�ԍ�)"
FROM
   xxinv_mov_req_instr_headers    xmrih     -- �ړ��˗�/�w���w�b�_(�A�h�I��)
--del start 2008/07/14
--  ,xxinv_mov_req_instr_lines      xmril     -- �ړ��˗�/�w������(�A�h�I��)
--del end 2008/07/14
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
--add start 2008/07/14
  AND  NVL(xmrih.small_quantity,0) > 0 -- ������>0
--add end 2008/07/14
  -- ���ɐ�
  AND  xmrih.ship_to_locat_id   =  xilv1.inventory_location_id
  AND  xilv1.location_id        =  xlv1.location_id
  -- �o�Ɍ�
  AND  xmrih.shipped_locat_id   =  xilv2.inventory_location_id
  AND  xilv2.location_id        =  xlv2.location_id
  ----------------------------------------------------------------------------------
--del start 2008/07/14
--  -- ���׏��
--  AND  xmrih.mov_hdr_id         = xmril.mov_hdr_id
--  AND  xmril.delete_flg        <> 'Y'
--del end 2008/07/14
  ----------------------------------------------------------------------------------
  -- �K�p��
--mod start 2008/06/27
--  --"���ɐ�.�K�p�J�n��"
--  AND xlv1.start_date_active   <= xmrih.schedule_ship_date
--  --"���ɐ�.�K�p�I����"
--  AND ( xlv1.end_date_active IS NULL
--        OR
--        xlv1.end_date_active   >= xmrih.schedule_ship_date
--     )
  --OPM�ۊǏꏊ���(���ɐ�)
  AND NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date)
    BETWEEN xilv1.date_from
    AND NVL(xilv1.date_to,NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date))
--mod end 2008/06/27
--mod start 2008/06/27
--  --"�o�Ɍ�.�K�p�J�n��"
--  AND xlv2.start_date_active   <= xmrih.schedule_ship_date
--  --"�o�Ɍ�.�K�p�I����"
--  AND ( xlv2.end_date_active IS NULL
--        OR
--        xlv2.end_date_active   >= xmrih.schedule_ship_date
--      )
  --OPM�ۊǏꏊ���(�o�Ɍ�)
  AND NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date)
    BETWEEN xilv2.date_from
    AND NVL(xilv2.date_to,NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date))
--mod end 2008/06/27
--mod start 2008/06/27
--  --"���Ə�(���ɐ�).�K�p�J�n��"
--  AND xlv1.start_date_active   <= xmrih.schedule_ship_date
--  --"���Ə�(���ɐ�).�K�p�I����"
--  AND ( xlv1.end_date_active IS NULL
--        OR
--        xlv1.end_date_active   >= xmrih.schedule_ship_date
--      )
  --���Ə�(���ɐ�)
  AND NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date)
    BETWEEN xlv1.start_date_active
    AND NVL(xlv1.end_date_active,NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date))
--mod end 2008/06/27
--mod start 2008/06/27
--  --"���Ə�(�o�Ɍ�).�K�p�J�n��"
--  AND xlv2.start_date_active   <= xmrih.schedule_ship_date
--  --"���Ə�(�o�Ɍ�).�K�p�I����"
--  AND ( xlv2.end_date_active IS NULL
--        OR
--        xlv2.end_date_active   >= xmrih.schedule_ship_date
--      )
--
  --���Ə�(�o�Ɍ�)
  AND NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date)
    BETWEEN xlv2.start_date_active
    AND NVL(xlv2.end_date_active,NVL(xmrih.actual_ship_date,xmrih.schedule_ship_date))
--mod end 2008/06/27
--add start 2009/05/26 �{�ԏ�Q#1493 �z��No���Ȃ��f�[�^�͏o���Ȃ��B
  AND xmrih.delivery_no IS NOT NULL
--add end 2009/05/26
------------------------------------------------------------------------------------
--add start 2008/06/27
UNION ALL
--���̑����̒��o
SELECT
   '4'                                AS biz_type               --"�Ɩ����"
  ,xilv_from.distribution_block       AS distribution_block     --"�����u���b�N"
  ,NVL(xcs.result_freight_carrier_code
      ,xcs.carrier_code)              AS freight_carrier_code   --"�^���Ǝ�"
  ,xcs.prod_class                     AS prod_class_code        --"���i�敪"
  ,NULL                               AS order_type_id          --"�󒍃^�C�vID"
  ,NVL(xcs.arrival_date
      ,xcs.schedule_arrival_date)     AS arrival_date           --"���ח\���"
  ,NULL                               AS arrival_time_from      --"���Ԏw��"
  ,xcs.delivery_no                    AS delivery_no            --"�z��No"
  ,NULL                               AS request_no             --"�˗�No/�ړ�No"
  ,xcs.small_quantity                 AS small_quantity         --"��"
  ,NULL                               AS cust_po_number         --"�ڋq����No"
  ,NVL(xcs.shipped_date
      ,xcs.schedule_ship_date)        AS shipped_date           --"�o�ɗ\���"
  ,xcs.deliver_from                   AS deliver_from           --"�o�Ɍ�(�R�[�h)"
  ,xlv_from.zip                       AS shipped_zip            --"�o�Ɍ�(�X�֔ԍ�)"
  ,xlv_from.address_line1             AS shipped_address        --"�o�Ɍ�(�Z��)"
--2009/01/21 Mod Start
  ,CASE
     WHEN xilv_from.whse_inside_outside_div = 1 THEN
       SUBSTRB('(��)�ɓ���' || xilv_from.description,1,50)
     ELSE
       xilv_from.description
     END                               AS  shipped_name           --"�o�Ɍ�(����)"
--  ,xilv_from.description              AS shipped_name           --"�o�Ɍ�(����)"
--2009/01/21 Mod End
  ,xlv_from.phone                     AS shipped_phone          --"�o�Ɍ�(�d�b�ԍ�)"
  ,'�z�B�w��@�L �E ��'               AS deli_shitei            --"�z�B�w��"
  ---------------------------------------------------------------------------------
  ,NULL                               AS party_name             --"�Ǌ����_"
  ,xcs.deliver_to                     AS deliver_to             --"�z����/���ɐ�(�R�[�h)"
  ,CASE
     WHEN xcs.deliver_to_code_class IN ('1','10') THEN xcasv.zip
     WHEN xcs.deliver_to_code_class = '4'        THEN xlv.zip
     WHEN xcs.deliver_to_code_class = '11'         THEN xvsv.zip
   END                                AS ship_zip               --"�z����/���ɐ�(�X�֔ԍ�)"
  ,CASE
     WHEN xcs.deliver_to_code_class IN ('1','10') THEN xcasv.address_line1 || xcasv.address_line2
     WHEN xcs.deliver_to_code_class = '4'        THEN xlv.address_line1
     WHEN xcs.deliver_to_code_class = '11'         THEN xvsv.address_line1 || xvsv.address_line2
   END                                AS ship_address           --"�z����/���ɐ�(�Z��)"
  ,CASE
     WHEN xcs.deliver_to_code_class IN ('1','10') THEN xcasv.party_site_full_name
--2009/01/21 Mod Start
     WHEN xcs.deliver_to_code_class = '4'        THEN
       CASE
         WHEN xilv.whse_inside_outside_div = 1 THEN
           SUBSTRB('(��)�ɓ���' || xilv.description,1,50)
         ELSE
           xilv.description
         END
--     WHEN xcs.deliver_to_code_class = '4'        THEN xilv.description
--2009/01/21 Mod End
     WHEN xcs.deliver_to_code_class = '11'         THEN xvsv.vendor_site_name
   END                                AS ship_name              --"�z����/���ɐ�(����)"
  ,CASE
     WHEN xcs.deliver_to_code_class IN ('1','10') THEN xcasv.phone
     WHEN xcs.deliver_to_code_class = '4'        THEN xlv.phone
     WHEN xcs.deliver_to_code_class = '11'         THEN xvsv.phone
   END                                AS ship_phone             --"�z����/���ɐ�(�d�b�ԍ�)"
FROM
   xxwsh_carriers_schedule        xcs         --�z�Ԕz���v��A�h�I��
  ,xxcmn_cust_acct_sites2_v       xcasv       --�ڋq�T�C�g���view
  ,xxcmn_vendor_sites2_v          xvsv        --�d����T�C�g���view
  ,xxcmn_item_locations2_v        xilv        --OPM�ۊǏꏊ���view
  ,xxcmn_locations2_v             xlv         --���Ə����view
  ,xxcmn_item_locations2_v        xilv_from   --OPM�ۊǏꏊ���view(�o�Ɍ�)
  ,xxcmn_locations2_v             xlv_from    --���Ə����view(�o�Ɍ�)
--�z�Ԕz���v��A�h�I�����o����
WHERE xcs.deliver_to_code_class IN ('1','11','10','4')                         --�z����R�[�h�敪 IN (���_,�x����,�ڋq,�q��)
AND   xcs.non_slip_class = '2'                                                 --�`�[�Ȃ��z�ԋ敪 = �`�[�Ȃ�
--add start 2008/07/14
AND  NVL(xcs.small_quantity,0) > 0                                             -- ������>0
--add end 2008/07/14
--�ڋq�T�C�g���view���o����
AND   xcs.deliver_to_id = xcasv.party_site_id(+)                               --�z����ID = �p�[�e�B�T�C�gID
AND   NVL(xcs.shipped_date,xcs.schedule_ship_date)                             --�K�p�J�n�� <= �o�ד�(�o�ח\���) <= �K�p�I����
  BETWEEN xcasv.start_date_active(+)
  AND NVL(xcasv.end_date_active(+),NVL(xcs.shipped_date,xcs.schedule_ship_date))
--�d����T�C�g���view���o����
AND   xcs.deliver_to_id = xvsv.vendor_site_id(+)                               --�z����ID = �d����T�C�gID
AND   NVL(xcs.shipped_date,xcs.schedule_ship_date)                             --�K�p�J�n�� <= �o�ד�(�o�ח\���) <= �K�p�I����
  BETWEEN xvsv.start_date_active(+)
  AND NVL(xvsv.end_date_active(+),NVL(xcs.shipped_date,xcs.schedule_ship_date))
--OPM�ۊǏꏊ���view���o����
AND   xcs.deliver_to_id = xilv.inventory_location_id(+)                        --�z����ID = �q��ID
AND   NVL(xcs.shipped_date,xcs.schedule_ship_date)                             --�K�p�J�n�� <= �o�ד�(�o�ח\���) <= �K�p�I����
  BETWEEN xilv.date_from(+)
  AND NVL(xilv.date_to(+),NVL(xcs.shipped_date,xcs.schedule_ship_date))
--���Ə����view���o����
AND   xilv.location_id = xlv.location_id(+)                                    --���Ə�ID = ���Ə�ID
AND  (NVL(xcs.shipped_date,xcs.schedule_ship_date)                             --�K�p�J�n�� <= �o�ד�(�o�ח\���) <= �K�p�I����
  BETWEEN xlv.start_date_active
  AND NVL(xlv.end_date_active,NVL(xcs.shipped_date,xcs.schedule_ship_date))
OR    xlv.location_id IS NULL                                                  --�܂��́A���Ə���񖢑���(�O�������Ƃ��邽��)
      )
--OPM�ۊǏꏊ���view(�o�Ɍ�)���o����
AND   xcs.deliver_from_id = xilv_from.inventory_location_id                    --�z����ID = �q��ID
AND   NVL(xcs.shipped_date,xcs.schedule_ship_date)                             --�K�p�J�n�� <= �o�ד�(�o�ח\���) <= �K�p�I����
  BETWEEN xilv_from.date_from
  AND NVL(xilv_from.date_to,NVL(xcs.shipped_date,xcs.schedule_ship_date))
--���Ə����view(�o�Ɍ�)���o����
AND   xilv_from.location_id = xlv_from.location_id                             --���Ə�ID = ���Ə�ID
AND   NVL(xcs.shipped_date,xcs.schedule_ship_date)                             --�K�p�J�n�� <= �o�ד�(�o�ח\���) <= �K�p�I����
  BETWEEN xlv_from.start_date_active
  AND NVL(xlv_from.end_date_active,NVL(xcs.shipped_date,schedule_ship_date))
--add end 2008/06/27
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
COMMENT ON COLUMN xxwsh_invoice_v.shipped_zip IS '�o�Ɍ�(�X�֔ԍ�)'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_address IS '�o�Ɍ�(�Z��)'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_name IS '�o�Ɍ�(����)'
/
COMMENT ON COLUMN xxwsh_invoice_v.shipped_phone IS '�o�Ɍ�(�d�b�ԍ�)'
/
COMMENT ON COLUMN xxwsh_invoice_v.deli_shitei IS '�z�B�w��'
/
COMMENT ON COLUMN xxwsh_invoice_v.party_name IS '�Ǌ����_'
/
COMMENT ON COLUMN xxwsh_invoice_v.deliver_to IS '�z����/���ɐ�(�R�[�h)'
/
COMMENT ON COLUMN xxwsh_invoice_v.ship_zip IS '�z����/���ɐ�(�X�֔ԍ�)'
/
COMMENT ON COLUMN xxwsh_invoice_v.ship_address IS '�z����/���ɐ�(�Z��)'
/
COMMENT ON COLUMN xxwsh_invoice_v.ship_name IS '�z����/���ɐ�(����)'
/
COMMENT ON COLUMN xxwsh_invoice_v.ship_phone IS '�z����/���ɐ�(�d�b�ԍ�)'
/
