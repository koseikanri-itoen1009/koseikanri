CREATE OR REPLACE VIEW APPS.XXSKY_�o�׈˗�IF_��{_V
(
 �󒍃^�C�v
,�󒍓�
,�o�א�
,�o�א於
,�o�׎w��
,�ڋq����
,�󒍃\�[�X�Q��
,�o�ח\���
,���ח\���
,�p���b�g�g�p����
,�p���b�g�������
,�o�׌�
,�o�׌���
,�Ǌ����_
,�Ǌ����_��
,���͋��_
,���͋��_��
,���׎���FROM
,���׎���FROM��
,���׎���TO
,���׎���TO��
,�f�[�^�^�C�v
,�^���Ǝ�
,�^���ƎҖ�
,�z���敪
,�z���敪��
,�z��NO
,�o�ד�
,���ד�
,EOS�f�[�^���
,EOS�f�[�^��ʖ�
,�`���p�}��
,���ɑq��
,���ɑq�ɖ�
,�q�֕ԕi�敪
,�q�֕ԕi�敪��
,�˗��敪
,�˗��敪��
,�񍐕���
,�񍐕�����
,���הԍ�
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�󒍕i�ڃR�[�h
,�󒍕i�ږ�
,�󒍕i�ڗ���
,�P�[�X��
,����
,�o�׎��ѐ���
,������
,�ŗL�L��
,�ܖ�����
,���󐔗�
,���Ɏ��ѐ���
,�ۗ��X�e�[�^�X
,�ۗ��X�e�[�^�X��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XSH_XSL.order_type                  --�󒍃^�C�v
       ,XSH_XSL.ordered_date                --�󒍓�
       ,XSH_XSL.party_site_code             --�o�א�
       ,XPSV.party_site_name                --�o�א於
       ,XSH_XSL.shipping_instructions       --�o�׎w��
       ,XSH_XSL.cust_po_number              --�ڋq����
       ,XSH_XSL.order_source_ref            --�󒍃\�[�X�Q��
       ,XSH_XSL.schedule_ship_date          --�o�ח\���
       ,XSH_XSL.schedule_arrival_date       --���ח\���
       ,XSH_XSL.used_pallet_qty             --�p���b�g�g�p����
       ,XSH_XSL.collected_pallet_qty        --�p���b�g�������
       ,XSH_XSL.location_code               --�o�׌�
       ,XLV_SHU.location_name               --�o�׌���
       ,XSH_XSL.head_sales_branch           --�Ǌ����_
       ,XCAV_KAN.party_name                 --�Ǌ����_��
       ,XSH_XSL.input_sales_branch          --���͋��_
       ,XCAV_NYU.party_name                 --���͋��_��
       ,XSH_XSL.arrival_time_from           --���׎���FROM
       ,FLV_CHFROM.meaning                  --���׎���FROM��
       ,XSH_XSL.arrival_time_to             --���׎���TO
       ,FLV_CHTO.meaning                    --���׎���TO��
       ,XSH_XSL.data_type                   --�f�[�^�^�C�v
       ,XSH_XSL.freight_carrier_code        --�^���Ǝ�
       ,XCV.party_name                      --�^���ƎҖ�
       ,XSH_XSL.shipping_method_code        --�z���敪
       ,FLV_HAI.meaning                     --�z���敪��
       ,XSH_XSL.delivery_no                 --�z��No
       ,XSH_XSL.shipped_date                --�o�ד�
       ,XSH_XSL.arrival_date                --���ד�
       ,XSH_XSL.eos_data_type               --EOS�f�[�^���
       ,FLV_EOS.meaning                     --EOS�f�[�^��ʖ�
       ,XSH_XSL.tranceration_number         --�`���p�}��
       ,XSH_XSL.ship_to_location            --���ɑq��
       ,XILV.description                    --���ɑq�ɖ�
       ,XSH_XSL.rm_class                    --�q�֕ԕi�敪
       ,FLV_KURA.meaning                    --�q�֕ԕi�敪��
       ,XSH_XSL.ordered_class               --�˗��敪
       ,XSCV.request_class_name             --�˗��敪��
       ,XSH_XSL.report_post_code            --�񍐕���
       ,XLV_HOU.location_name               --�񍐕�����
       ,XSH_XSL.line_number                 --���הԍ�
       ,XPCV.prod_class_code                --���i�敪
       ,XPCV.prod_class_name                --���i�敪��
       ,XICV.item_class_code                --�i�ڋ敪
       ,XICV.item_class_name                --�i�ڋ敪��
       ,XCCV.crowd_code                     --�Q�R�[�h
       ,XSH_XSL.orderd_item_code            --�󒍕i�ڃR�[�h
       ,XIMV.item_name                      --�󒍕i�ږ�
       ,XIMV.item_short_name                --�󒍕i�ڗ���
       ,XSH_XSL.case_quantity               --�P�[�X��
       ,XSH_XSL.orderd_quantity             --����
       ,XSH_XSL.shiped_quantity             --�o�׎��ѐ���
-- 2009/03/18 H.Iida MOD START �{�ԏ�Q#1329
--       ,XSH_XSL.designated_production_date  --������
       ,TO_CHAR( XSH_XSL.designated_production_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --������
-- 2009/03/18 H.Iida MOD END
       ,XSH_XSL.original_character          --�ŗL�L��
-- 2009/03/18 H.Iida MOD START �{�ԏ�Q#1329
--       ,XSH_XSL.use_by_date                 --�ܖ�����
       ,TO_CHAR( XSH_XSL.use_by_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�ܖ�����
-- 2009/03/18 H.Iida MOD END
       ,XSH_XSL.detailed_quantity           --���󐔗�
       ,XSH_XSL.ship_to_quantity            --���Ɏ��ѐ���
       ,XSH_XSL.reserved_status             --�ۗ��X�e�[�^�X
       ,CASE XSH_XSL.reserved_status        --�ۗ��X�e�[�^�X��
           WHEN '1' THEN '�ۗ�'
        END
       ,FU_CB.user_name                     --�쐬��
       ,TO_CHAR( XSH_XSL.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�쐬��
       ,FU_LU.user_name                     --�ŏI�X�V��
       ,TO_CHAR( XSH_XSL.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                            --�ŏI�X�V��
       ,FU_LL.user_name                     --�ŏI�X�V���O�C��
FROM
        ( SELECT 
             XSHI.order_type                    AS  order_type                  --�󒍃^�C�v
            ,XSHI.ordered_date                  AS  ordered_date                --�󒍓�
            ,XSHI.party_site_code               AS  party_site_code             --�o�א�
            ,XSHI.shipping_instructions         AS  shipping_instructions       --�o�׎w��
            ,XSHI.cust_po_number                AS  cust_po_number              --�ڋq����
            ,XSHI.order_source_ref              AS  order_source_ref            --�󒍃\�[�X�Q��
            ,XSHI.schedule_ship_date            AS  schedule_ship_date          --�o�ח\���
            ,XSHI.schedule_arrival_date         AS  schedule_arrival_date       --���ח\���
            ,XSHI.used_pallet_qty               AS  used_pallet_qty             --�p���b�g�g�p����
            ,XSHI.collected_pallet_qty          AS  collected_pallet_qty        --�p���b�g�������
            ,XSHI.location_code                 AS  location_code               --�o�׌�
            ,XSHI.head_sales_branch             AS  head_sales_branch           --�Ǌ����_
            ,XSHI.input_sales_branch            AS  input_sales_branch          --���͋��_
            ,XSHI.arrival_time_from             AS  arrival_time_from           --���׎���FROM
            ,XSHI.arrival_time_to               AS  arrival_time_to             --���׎���TO
            ,XSHI.data_type                     AS  data_type                   --�f�[�^�^�C�v
            ,XSHI.freight_carrier_code          AS  freight_carrier_code        --�^���Ǝ�
            ,XSHI.shipping_method_code          AS  shipping_method_code        --�z���敪
            ,XSHI.delivery_no                   AS  delivery_no                 --�z��No
            ,XSHI.shipped_date                  AS  shipped_date                --�o�ד�
            ,XSHI.arrival_date                  AS  arrival_date                --���ד�
            ,XSHI.eos_data_type                 AS  eos_data_type               --EOS�f�[�^���
            ,XSHI.tranceration_number           AS  tranceration_number         --�`���p�}��
            ,XSHI.ship_to_location              AS  ship_to_location            --���ɑq��
            ,XSHI.rm_class                      AS  rm_class                    --�q�֕ԕi�敪
            ,XSHI.ordered_class                 AS  ordered_class               --�˗��敪
            ,XSHI.report_post_code              AS  report_post_code            --�񍐕���
            ,XSLI.line_number                   AS  line_number                 --���הԍ�
            ,XSLI.orderd_item_code              AS  orderd_item_code            --�󒍕i�ڃR�[�h
            ,XSLI.case_quantity                 AS  case_quantity               --�P�[�X��
            ,XSLI.orderd_quantity               AS  orderd_quantity             --����
            ,XSLI.shiped_quantity               AS  shiped_quantity             --�o�׎��ѐ���
            ,XSLI.designated_production_date    AS  designated_production_date  --������
            ,XSLI.original_character            AS  original_character          --�ŗL�L��
            ,XSLI.use_by_date                   AS  use_by_date                 --�ܖ�����
            ,XSLI.detailed_quantity             AS  detailed_quantity           --���󐔗�
            ,XSLI.ship_to_quantity              AS  ship_to_quantity            --���Ɏ��ѐ���
            ,XSLI.reserved_status               AS  reserved_status             --�ۗ��X�e�[�^�X
            ,XSHI.creation_date                 AS  creation_date               --�쐬��
            ,XSHI.last_update_date              AS  last_update_date            --�ŏI�X�V��
            ,XSHI.last_update_login             AS  last_update_login
            ,XSHI.created_by                    AS  created_by
            ,XSHI.last_updated_by               AS  last_updated_by
          FROM 
             xxwsh_shipping_headers_if          XSHI        --�o�׈˗��C���^�t�F�[�X�A�h�I���w�b�_
            ,xxwsh_shipping_lines_if            XSLI        --�o�׈˗��C���^�t�F�[�X�A�h�I������
          WHERE
             XSHI.header_id = XSLI.header_id                --�o�׈˗��C���^�t�F�[�X�A�h�I���w�b�_�E���׌���
        )                                       XSH_XSL
       ,xxsky_party_sites2_v                    XPSV        --�o�א於�擾
       ,xxsky_locations2_v                      XLV_SHU     --�o�׌����Ə��擾
       ,xxsky_cust_accounts2_v                  XCAV_KAN    --�Ǌ����_���擾
       ,xxsky_cust_accounts2_v                  XCAV_NYU    --���͋��_���擾
       ,fnd_lookup_values                       FLV_CHFROM  --���׎���FROM���擾
       ,fnd_lookup_values                       FLV_CHTO    --���׎���TO���擾�p����
       ,xxsky_carriers2_v                       XCV         --�^���ƎҖ��擾
       ,fnd_lookup_values                       FLV_HAI     --�z���敪���擾�p����
       ,fnd_lookup_values                       FLV_EOS     --EOS�f�[�^��ʖ��擾�p����
       ,fnd_lookup_values                       FLV_KURA    --�q�֕ԕi�敪���擾�p����
       ,xxsky_item_locations_v                  XILV        --�ۊǑq�ɖ��擾
       ,( SELECT DISTINCT 
             request_class
            ,request_class_name
            ,start_date_active
            ,end_date_active
          FROM  xxwsh_shipping_class2_v
          WHERE request_class IS NOT NULL
        )                                       XSCV        --�˗��敪�擾
       ,xxsky_locations2_v                      XLV_HOU     --�񍐕������擾
       ,xxsky_item_mst2_v                       XIMV        --�i�ږ��擾(���i�敪�E�i�ڋ敪�E�Q�R�[�h�擾�ɂ��g�p)
       ,xxsky_prod_class_v                      XPCV        --���i�敪�擾
       ,xxsky_item_class_v                      XICV        --�i�ڋ敪�擾
       ,xxsky_crowd_code_v                      XCCV        --�Q�R�[�h�擾
       ,fnd_user                                FU_CB       --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                                FU_LU       --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                                FU_LL       --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                              FL_LL       --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
WHERE
  --�o�א於�擾�p����
      XSH_XSL.party_site_code = XPSV.party_site_number(+)
  AND XPSV.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XPSV.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --�o�׌����Ə��擾�p����
  AND XLV_SHU.LOCATION_CODE(+) = XSH_XSL.location_code
  AND XLV_SHU.START_DATE_ACTIVE(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XLV_SHU.END_DATE_ACTIVE(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --�Ǌ����_���擾�p����
  AND XCAV_KAN.party_number(+) = XSH_XSL.head_sales_branch
  AND XCAV_KAN.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XCAV_KAN.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --���͋��_���擾�p����
  AND XCAV_NYU.party_number(+) = XSH_XSL.input_sales_branch
  AND XCAV_NYU.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XCAV_NYU.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --���׎���FROM���擾�p����
  AND FLV_CHFROM.language(+) = 'JA'
  AND FLV_CHFROM.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
  AND FLV_CHFROM.lookup_code(+) = XSH_XSL.arrival_time_from
  --���׎���TO���擾�p����
  AND FLV_CHTO.language(+) = 'JA'
  AND FLV_CHTO.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
  AND FLV_CHTO.lookup_code(+) = XSH_XSL.arrival_time_to
  --�^���ƎҖ��擾�p����
  AND XSH_XSL.freight_carrier_code = XCV.freight_code(+)
  AND XCV.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XCV.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --�z���敪���擾�p����
  AND FLV_HAI.language(+) = 'JA'
  AND FLV_HAI.lookup_type(+) = 'XXCMN_SHIP_METHOD'
  AND FLV_HAI.lookup_code(+) = XSH_XSL.shipping_method_code
  --EOS�f�[�^��ʖ��擾�p����
  AND FLV_EOS.language(+) = 'JA'
  AND FLV_EOS.lookup_type(+) = 'XXCMN_D17'
  AND FLV_EOS.lookup_code(+) = XSH_XSL.eos_data_type
  --�q�֕ԕi�敪���擾�p����
  AND FLV_KURA.language(+) = 'JA'
  AND FLV_KURA.lookup_type(+) = 'XXCMN_L03'
  AND FLV_KURA.lookup_code(+) = XSH_XSL.rm_class
  --�ۊǑq�ɖ��擾�p����
  AND XSH_XSL.ship_to_location = XILV.segment1(+)
  --�˗��敪�擾�p����
  AND XSH_XSL.ordered_class = XSCV.request_class(+)
  AND XSCV.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XSCV.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --�񍐕����擾�p����
  AND XLV_HOU.location_code(+) = XSH_XSL.report_post_code
  AND XLV_HOU.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XLV_HOU.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --�i�ږ��擾�p����
  AND XIMV.item_no(+) = XSH_XSL.orderd_item_code
  AND XIMV.start_date_active(+) <= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  AND XIMV.end_date_active(+)   >= NVL(XSH_XSL.schedule_ship_date,SYSDATE)
  --���i�敪�擾�p����
  AND XIMV.item_id = XPCV.item_id(+)
  --�i�ڋ敪�擾�p����
  AND XIMV.item_id = XICV.item_id(+)
  --�Q�R�[�h�擾�p����
  AND XIMV.item_id = XCCV.item_id(+)
  AND FU_CB.user_id(+)  = XSH_XSL.created_by                    --CREATED_BY���̎擾�p����
  AND FU_LU.user_id(+)  = XSH_XSL.last_updated_by               --LAST_UPDATE_BY���̎擾�p����
  AND FL_LL.login_id(+) = XSH_XSL.last_update_login             --LAST_UPDATE_LOGIN���̎擾�p����
  AND FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�o�׈˗�IF_��{_V IS 'XXSKY_�o�׈˗�IF (��{) VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�󒍃^�C�v            IS '�󒍃^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�󒍓�                IS '�󒍓�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�o�א�                IS '�o�א�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�o�א於              IS '�o�א於'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�o�׎w��              IS '�o�׎w��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�ڋq����              IS '�ڋq����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�󒍃\�[�X�Q��        IS '�󒍃\�[�X�Q��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�o�ח\���            IS '�o�ח\���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���ח\���            IS '���ח\���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�p���b�g�g�p����      IS '�p���b�g�g�p����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�p���b�g�������      IS '�p���b�g�������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�o�׌�                IS '�o�׌�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�o�׌���              IS '�o�׌���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�Ǌ����_              IS '�Ǌ����_'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�Ǌ����_��            IS '�Ǌ����_��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���͋��_              IS '���͋��_'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���͋��_��            IS '���͋��_��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���׎���FROM          IS '���׎���FROM'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���׎���FROM��        IS '���׎���FROM��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���׎���TO            IS '���׎���TO'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���׎���TO��          IS '���׎���TO��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�f�[�^�^�C�v          IS '�f�[�^�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�^���Ǝ�              IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�^���ƎҖ�            IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�z���敪              IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�z���敪��            IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�z��NO                IS '�z��No'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�o�ד�                IS '�o�ד�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���ד�                IS '���ד�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.EOS�f�[�^���         IS 'EOS�f�[�^���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.EOS�f�[�^��ʖ�       IS 'EOS�f�[�^��ʖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�`���p�}��            IS '�`���p�}��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���ɑq��              IS '���ɑq��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���ɑq�ɖ�            IS '���ɑq�ɖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�q�֕ԕi�敪          IS '�q�֕ԕi�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�q�֕ԕi�敪��        IS '�q�֕ԕi�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�˗��敪              IS '�˗��敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�˗��敪��            IS '�˗��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�񍐕���              IS '�񍐕���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�񍐕�����            IS '�񍐕�����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���הԍ�              IS '���הԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���i�敪              IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���i�敪��            IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�i�ڋ敪              IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�i�ڋ敪��            IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�Q�R�[�h              IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�󒍕i�ڃR�[�h        IS '�󒍕i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�󒍕i�ږ�            IS '�󒍕i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�󒍕i�ڗ���          IS '�󒍕i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�P�[�X��              IS '�P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.����                  IS '����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�o�׎��ѐ���          IS '�o�׎��ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.������                IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�ŗL�L��              IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�ܖ�����              IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���󐔗�              IS '���󐔗�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.���Ɏ��ѐ���          IS '���Ɏ��ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�ۗ��X�e�[�^�X        IS '�ۗ��X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�ۗ��X�e�[�^�X��      IS '�ۗ��X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�쐬��                IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�쐬��                IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�ŏI�X�V��            IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�ŏI�X�V��            IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׈˗�IF_��{_V.�ŏI�X�V���O�C��      IS '�ŏI�X�V���O�C��'
/
