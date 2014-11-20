CREATE OR REPLACE VIEW xxwsh_label_v
(
 ship_type,
 order_type_id,
 deliver_from,
 career_code,
 schedule_ship_date,
 prod_class,
 delivery_no,
 deliver_to,
 block,
 request_no,
 small_quantity,
 label_quantity,
 party_site_name,
 address_line,
 phone
 )
AS
SELECT
  ---------------------------------------------------------------------------------
  -- �p�����[�^�w�荀��
  -- �Ɩ���ʋ���
  TO_CHAR('1')                       AS  ship_type              --"�Ɩ����"
  ,xoha.order_type_id                AS  order_type_id          --"�o�Ɍ`��"
  ,xoha.deliver_from                 AS  deliver_from           --"�o�׌�ID"
  ,CASE
    WHEN (xoha.req_status = '04') THEN xoha.result_freight_carrier_code
    WHEN (xoha.req_status = '03') THEN xoha.freight_carrier_code
   END                               AS  career_code            --"�^���Ǝ�"
  ,CASE
    WHEN (xoha.req_status = '04') THEN xoha.shipped_date
    WHEN (xoha.req_status = '03') THEN xoha.schedule_ship_date
   END                               AS  schedule_ship_date     --"�o�ד�"
  ,xoha.prod_class                   AS  prod_class             --"���i�敪"
  ,xcs.delivery_no                   AS  delivery_no            --"�z��No"
  ,xoha.deliver_to                   AS  deliver_to             --"�z����/���ɐ�"
  ,xilv.distribution_block           AS  block                  --"�u���b�N"
  ------------------------------------------------
  ,xoha.request_no                   AS  request_no             --"�˗�No"
  ,xoha.small_quantity               AS  small_quantity         --"������"
  ,xoha.label_quantity               AS  label_quantity         --"���x������"
  ,xcas.party_site_full_name         AS  party_site_name        --"������(�ڋq��)"
  ,( xcas.address_line1 || xcas.address_line2 ) AS address_line --"�Z��"
  ,xcas.phone                        AS  phone                  --"�d�b�ԍ�"
FROM
   xxwsh_order_headers_all           xoha          -- �󒍃w�b�_�A�h�I��
  ,xxwsh_carriers_schedule           xcs           -- �z�Ԕz���v��(�A�h�I��)
  ,xxcmn_cust_acct_sites2_v          xcas          -- �ڋq�T�C�g
  ,xxcmn_item_locations2_v           xilv          -- OPM�ۊǏꏊ�}�X�^2
  ,xxwsh_oe_transaction_types2_v     xottv         -- �󒍃^�C�v
  ,xxwsh_ship_method2_v              xsm2v         -- �z���敪���VIEW2
WHERE
  ----------------------------------------------------------------------------------
  -- �w�b�_���
      xottv.shipping_shikyu_class   =   '1'        -- �o�׎x���敪�F�u�o�׈˗��v
  AND xottv.order_category_code     =   'ORDER'    -- �󒍃J�e�S���F��
  AND xoha.req_status               >=  '03'       -- �X�e�[�^�X�F�u���ߍς݁v
  AND xoha.req_status               <>  '99'       -- �X�e�[�^�X�F���
  --------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------
  AND  xoha.shipping_method_code    =    xsm2v.ship_method_code
  AND  (CASE 
         WHEN  xoha.req_status = '03' THEN  xoha.deliver_to_id
         WHEN  xoha.req_status = '04' THEN  xoha.result_deliver_to_id
        END )          =    xcas.party_site_id ( + ) 
  AND  xoha.delivery_no             =    xcs.delivery_no
  AND  xoha.order_type_id           =    xottv.transaction_type_id
  --------------------------------------------------------------------------------------------
  AND ( xcas.start_date_active IS NULL
        OR ( ( xoha.req_status = '03' 
              AND 
               xcas.start_date_active       <=   xoha.schedule_ship_date )
           OR
             ( xoha.req_status = '04' 
              AND 
               xcas.start_date_active       <=   xoha.shipped_date ) ) 
  )
  --------------------------------------------------------------------------------------------
  AND ( xcas.end_date_active IS NULL
        OR ( ( xoha.req_status = '03' 
              AND 
               xcas.end_date_active         >=   xoha.schedule_ship_date )
           OR
             ( xoha.req_status = '04' 
              AND 
               xcas.end_date_active         >=   xoha.shipped_date ) ) 
  )
  --------------------------------------------------------------------------------------------
UNION 
SELECT
  ---------------------------------------------------------------------------------
  -- �p�����[�^�w�荀��
  -- �Ɩ���ʋ���
  TO_CHAR('2')                       AS  ship_type              --"�Ɩ����"
  ,xoha.order_type_id                AS  order_type_id          --"�o�Ɍ`��"
  ,xoha.deliver_from                 AS  deliver_from           --"�o�׌�ID"
  ,CASE
    WHEN (xoha.req_status = '08') THEN xoha.result_freight_carrier_code
    WHEN (xoha.req_status = '07') THEN xoha.freight_carrier_code
   END                               AS  career_id              --"�^���Ǝ�"
  ,CASE
    WHEN (xoha.req_status = '08') THEN xoha.shipped_date
    WHEN (xoha.req_status = '07') THEN xoha.schedule_ship_date
   END                               AS  schedule_ship_date     --"�o�ד�"
  ,xoha.prod_class                   AS  prod_class             --"���i�敪"
  ,xcs.delivery_no                   AS  delivery_no            --"�z��No"
  ,xoha.deliver_to                   AS  deliver_to             --"�z����/���ɐ�"
  ,xilv.distribution_block           AS  block                  --"�u���b�N"
  ------------------------------------------------
  ,xoha.request_no                   AS  request_no             --"�˗�No"
  ,xoha.small_quantity               AS  small_quantity         --"������"
  ,xoha.label_quantity               AS  label_quantity         --"���x������"
  ,xvsa.vendor_site_name             AS  party_site_name        --"������(�ڋq��)"
  ,( xvsa.address_line1 || xvsa.address_line2 ) AS address_line --"�Z��"
  ,xvsa.phone                        AS  phone                  --"�d�b�ԍ�"
FROM
   xxwsh_order_headers_all           xoha    -- �󒍃w�b�_�A�h�I��
  ,xxwsh_carriers_schedule           xcs     -- �z�Ԕz���v��(�A�h�I��)
  ,xxcmn_vendor_sites2_v             xvsa    -- �d����T�C�g���VIEW
  ,xxcmn_item_locations2_v           xilv    -- OPM�ۊǏꏊ�}�X�^2
  ,xxwsh_oe_transaction_types2_v     xottv   -- �󒍃^�C�v
  ,xxwsh_ship_method2_v              xsm2v   -- �z���敪���VIEW2
WHERE
  ----------------------------------------------------------------------------------
  -- �w�b�_���
       xottv.shipping_shikyu_class  =   '2'
  AND  xottv.order_category_code    =   'ORDER'    -- �󒍃J�e�S���F��
  AND  xoha.req_status              >=  '07'       -- �X�e�[�^�X�F�u��̍ρv
  AND  xoha.req_status              <>  '99'       -- �X�e�[�^�X�F���
  --------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------
  AND  xoha.shipping_method_code    =    xsm2v.ship_method_code
  AND  xoha.vendor_site_id          =    xvsa.vendor_site_id ( + )
  AND  xoha.delivery_no             =    xcs.delivery_no
  AND  xoha.order_type_id           =    xottv.transaction_type_id
  --------------------------------------------------------------------------------------------
  AND ( xvsa.start_date_active IS NULL
        OR ( ( xoha.req_status = '07' 
              AND 
               xvsa.start_date_active       <=   xoha.schedule_ship_date )
           OR
             ( xoha.req_status = '08' 
              AND 
               xvsa.start_date_active       <=   xoha.shipped_date ) ) 
  )
  --------------------------------------------------------------------------------------------
  AND ( xvsa.end_date_active IS NULL
        OR ( ( xoha.req_status = '07' 
              AND 
               xvsa.end_date_active         >=   xoha.schedule_ship_date )
           OR
             ( xoha.req_status = '08' 
              AND 
               xvsa.end_date_active         >=   xoha.shipped_date ) ) 
  )
  --------------------------------------------------------------------------------------------
UNION 
SELECT
  ---------------------------------------------------------------------------------
  -- �p�����[�^�w�荀��
  -- �Ɩ���ʋ���
   TO_CHAR('3')                      AS  ship_type              --"�Ɩ����"
  ,NULL                              AS  order_type_id          --"�o�Ɍ`��"
  ,xmrih.shipped_locat_code          AS  deliver_from           --"�o�׌�ID"
  ,CASE
    WHEN (xmrih.status = '04') THEN xmrih.actual_freight_carrier_code
    WHEN (xmrih.status = '06') THEN xmrih.actual_freight_carrier_code
    WHEN (xmrih.status = '02') THEN xmrih.freight_carrier_code
    WHEN (xmrih.status = '03') THEN xmrih.freight_carrier_code
    WHEN (xmrih.status = '05') THEN xmrih.freight_carrier_code
   END                               AS  career_id              --"�^���Ǝ�"
  ,CASE
    WHEN (xmrih.status = '04') THEN xmrih.actual_ship_date
    WHEN (xmrih.status = '06') THEN xmrih.actual_ship_date
    WHEN (xmrih.status = '02') THEN xmrih.schedule_ship_date
    WHEN (xmrih.status = '03') THEN xmrih.schedule_ship_date
    WHEN (xmrih.status = '05') THEN xmrih.schedule_ship_date
   END                               AS  schedule_ship_date     --"�o�ד�"
  ,xmrih.item_class                  AS  prod_class             --"���i�敪"
  ,xcs.delivery_no                   AS  delivery_no            --"�z��No"
  ,xmrih.ship_to_locat_code          AS  deliver_to             --"�z����/���ɐ�"
  ,xilv.distribution_block           AS  block                  --"�u���b�N"
  ------------------------------------------------
  ,xmrih.mov_num                     AS  request_no             --"�˗�No"
  ,xmrih.small_quantity              AS  small_quantity         --"������"
  ,xmrih.label_quantity              AS  label_quantity         --"���x������"
  ,xilv.description                  AS  party_site_name        --"������(�ڋq��)"
  ,xl2v.address_line1                AS  address_line           --"�Z��"
  ,xl2v.phone                        AS  phone                  --"�d�b�ԍ�"
FROM
   xxwsh_carriers_schedule          xcs      --�z�Ԕz���v��( �A�h�I��)
  ,xxcmn_item_locations2_v          xilv     --OPM�ۊǏꏊ�}�X�^2
  ,xxcmn_locations2_v               xl2v     --���Ə��A�h�I���}�X�^
  ,xxinv_mov_req_instr_headers      xmrih    --�ړ��˗�/�w���w�b�_( �A�h�I��)
  ,xxwsh_ship_method2_v             xsm2v    --�z���敪���VIEW2
WHERE 
      xmrih.status                  >=   '02'
  AND xmrih.status                  <>   '99'
  AND xmrih.mov_type                <>   '2'
  AND xmrih.ship_to_locat_id        =    xilv.inventory_location_id 
  AND xilv.location_id              =    xl2v.location_id
  AND xmrih.shipping_method_code    =    xsm2v.ship_method_code
  AND xmrih.delivery_no             =    xcs.delivery_no
  --------------------------------------------------------------------------------------------
  AND ( xl2v.start_date_active IS NULL
        OR ( ( ( xmrih.status                =    '02' 
                 OR
                 xmrih.status                =    '03' 
                 OR
                 xmrih.status                =    '05' )
              AND 
               xl2v.start_date_active       <=   xmrih.schedule_ship_date )
           OR
             ( ( xmrih.status                =    '04' 
                 OR
                 xmrih.status                =    '06' )
              AND 
               xl2v.start_date_active       <=   xmrih.actual_ship_date ) ) 
  )
  --------------------------------------------------------------------------------------------
  AND ( xl2v.end_date_active IS NULL
        OR ( ( ( xmrih.status                =    '02' 
                 OR
                 xmrih.status                =    '03' 
                 OR
                 xmrih.status                =    '05' )
              AND 
               xl2v.end_date_active         >=   xmrih.schedule_ship_date )
           OR
             ( ( xmrih.status                =    '04' 
                 OR
                 xmrih.status                =    '06' )
              AND 
               xl2v.end_date_active         >=   xmrih.actual_ship_date ) ) 
  )
/
COMMENT ON TABLE xxwsh_label_v IS '���x��VIEW'
/
COMMENT ON COLUMN xxwsh_label_v.ship_type is '�Ɩ����'
/
COMMENT ON COLUMN xxwsh_label_v.order_type_id is '�o�Ɍ`��'
/
COMMENT ON COLUMN xxwsh_label_v.deliver_from is '�o�׌�ID'
/
COMMENT ON COLUMN xxwsh_label_v.career_code is '�^���Ǝ�'
/
COMMENT ON COLUMN xxwsh_label_v.schedule_ship_date is '�o�ד�'
/
COMMENT ON COLUMN xxwsh_label_v.prod_class is '���i�敪'
/
COMMENT ON COLUMN xxwsh_label_v.delivery_no is '�z��No'
/
COMMENT ON COLUMN xxwsh_label_v.deliver_to is '�z����/���ɐ�'
/
COMMENT ON COLUMN xxwsh_label_v.block is '�u���b�N'
/
COMMENT ON COLUMN xxwsh_label_v.request_no is '�˗�No'
/
COMMENT ON COLUMN xxwsh_label_v.small_quantity is '������'
/
COMMENT ON COLUMN xxwsh_label_v.label_quantity is '���x������'
/
COMMENT ON COLUMN xxwsh_label_v.party_site_name is '������(�ڋq��)'
/
COMMENT ON COLUMN xxwsh_label_v.address_line is '�Z��'
/
COMMENT ON COLUMN xxwsh_label_v.phone is '�d�b�ԍ�'
/
