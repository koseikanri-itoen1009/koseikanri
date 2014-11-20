CREATE OR REPLACE VIEW APPS.XXSKY_�^���i�ڕ�_��{1_V
(
 �z��NO
,�˗�_�ړ�NO
,�敪
,�󒍃^�C�v
,�X�e�[�^�X
,�X�e�[�^�X��
,�Ǌ����_
,�Ǌ����_��
,�^���Ǝ�
,�^���ƎҖ�
,�^���Ǝҗ���
,���ɐ�_�z����
,���ɐ�_�z���於
,���ɐ�_�z���旪��
,�o�Ɍ�
,�o�Ɍ���
,�o�Ɍ�����
,�z���敪
,�z���敪��
,�o�ɓ�
,���ɓ�
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ���
,�i�ڗ���
,�i�ڃo����
,�i�ڃP�[�X��
,���v�P�[�X��
,�ύڏd�ʍ��v
,���v�Z�p_�ύڏd�ʍ��v
,�i�ڏd�ʍ��v
,���v�Z�p_�i�ڏd�ʍ��v
,���v���z
,�i��_���v���z
)
AS
SELECT
        UHK.delivery_no                     --�z��No
       ,UHK.request_no                      --�˗�_�ړ�No
       ,UHK.delivery_item_details_class     --�敪
       ,UHK.order_type                      --�󒍃^�C�v
       ,UHK.req_status                      --�X�e�[�^�X
       ,CASE WHEN UHK.delivery_item_details_class = '�o��'
             THEN FLV01.meaning             --���ɐ�_�z���於
             ELSE FLV00.meaning             --���ɐ�_�z���於
        END
       ,UHK.head_sales_branch               --�Ǌ����_
       ,CASE WHEN UHK.delivery_item_details_class = '�o��'
             THEN XCAV.party_name           --�Ǌ����_��
             ELSE XL2V.location_name        --�Ǌ����_��
        END
       ,UHK.freight_carrier_code            --�^���Ǝ�
       ,XCRV.party_name                     --�^���ƎҖ�
       ,XCRV.party_short_name               --�^���Ǝҗ���
       ,UHK.ship_to_deliver_to_code         --���ɐ�_�z����
       ,CASE WHEN UHK.delivery_item_details_class = '�o��'
             THEN XPSV.party_site_name                --���ɐ�_�z���於
             ELSE XILV1.description                   --���ɐ�_�z���於
        END
       ,CASE WHEN UHK.delivery_item_details_class = '�o��'
             THEN XPSV.party_site_short_name          --���ɐ�_�z���旪��
             ELSE XILV1.short_name                    --���ɐ�_�z���旪��
        END
       ,UHK.deliver_from                    --�o�Ɍ�
       ,XILV.description                    --�o�Ɍ���
       ,XILV.short_name                     --�o�Ɍ�����
       ,UHK.shipping_method_code            --�z���敪
       ,FLV02.meaning                       --�z���敪��
       ,UHK.shipped_date                    --�o�ɓ�
       ,UHK.arrival_date                    --���ɓ�
       ,PRODC.prod_class_code               --���i�敪
       ,PRODC.prod_class_name               --���i�敪��
       ,ITEMC.item_class_code               --�i�ڋ敪
       ,ITEMC.item_class_name               --�i�ڋ敪��
       ,CROWD.crowd_code                    --�Q�R�[�h
       ,UHK.item_no                         --�i�ڃR�[�h
       ,ITEM.item_name                      --�i�ږ���
       ,ITEM.item_short_name                --�i�ڗ���
       ,UHK.shipped_quantity                --�i�ڃo����
       ,UHK.shipped_case_quantity           --�i�ڃP�[�X��
       ,UHK.sum_case_quantity               --���v�P�[�X��
       ,UHK.sum_loading_weight              --�ύڏd�ʍ��v
       ,UHK.calc_sum_loading_weight         --���v�Z�p_�ύڏd�ʍ��v
       ,UHK.item_loading_weight             --�i�ڏd�ʍ��v
       ,UHK.calc_item_loading_weight        --���v�Z�p_�i�ڏd�ʍ��v
       ,UHK.sum_amount                      --���v���z
       ,UHK.item_amount                     --�i��_���v���z
  FROM
        xxwip_delivery_item_details     UHK      --�i�ڕʈ��^�����׃A�h�I��
       ,xxsky_prod_class_v              PRODC    --SKYLINK�p����VIEW ���i�敪VIEW
       ,xxsky_item_class_v              ITEMC    --SKYLINK�p����VIEW �i�ڋ敪VIEW
       ,xxsky_crowd_code_v              CROWD    --SKYLINK�p����VIEW �Q�R�[�hVIEW
       ,xxsky_cust_accounts2_v          XCAV     --SKYLINK�p����VIEW �ڋq���VIEW2(�Ǌ����_)
       ,xxsky_locations2_v              XL2V     --SKYLINK�p����VIEW ���Ə����VIEW2(�Ǌ����_��)
       ,xxsky_carriers2_v               XCRV     --SKYLINK�p����VIEW �^���Ǝҏ��VIEW2(�^���ƎҖ�)
       ,xxsky_party_sites2_v            XPSV     --SKYLINK�p����VIEW �z������VIEW2(�z���於)
       ,xxsky_item_locations2_v         XILV1    --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(���ɐ於)
       ,xxsky_item_locations2_v         XILV     --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(�o�Ɍ���)
       ,xxsky_item_mst2_v               ITEM     --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�i�ڏ��)
       ,fnd_lookup_values               FLV00    --�N�C�b�N�R�[�h(�X�e�[�^�X��)
       ,fnd_lookup_values               FLV01    --�N�C�b�N�R�[�h(�X�e�[�^�X��)
       ,fnd_lookup_values               FLV02    --�N�C�b�N�R�[�h(�z���敪��)
 WHERE
   -- �i�ڂ̃J�e�S�����擾����
        ITEM.item_id = PRODC.item_id(+)  --���i�敪
   AND  ITEM.item_id = ITEMC.item_id(+)  --�i�ڋ敪
   AND  ITEM.item_id = CROWD.item_id(+)  --�Q�R�[�h
   -- �Ǌ����_���擾����(�ړ�)
   AND  UHK.head_sales_branch = XL2V.location_code(+)
   AND  UHK.arrival_date >= XL2V.start_date_active(+)
   AND  UHK.arrival_date <= XL2V.end_date_active(+)
   -- �Ǌ����_���擾����(�o��)
   AND  UHK.head_sales_branch = XCAV.party_number(+)
   AND  UHK.arrival_date >= XCAV.start_date_active(+)
   AND  UHK.arrival_date <= XCAV.end_date_active(+)
   -- �^���Ǝ�_���і��擾����
   AND  UHK.freight_carrier_code = XCRV.freight_code(+)
   AND  UHK.arrival_date >= XCRV.start_date_active(+)
   AND  UHK.arrival_date <= XCRV.end_date_active(+)
   -- �ړ�_���ɐ於�擾
   AND  UHK.ship_to_deliver_to_code = XILV1.segment1(+)
   -- �o��_�z���於�擾����
   AND  UHK.ship_to_deliver_to_code = XPSV.party_site_number(+)
   AND  UHK.arrival_date >= XPSV.start_date_active(+)
   AND  UHK.arrival_date <= XPSV.end_date_active(+)
   -- �o�Ɍ����擾����
   AND  UHK.deliver_from = XILV.segment1(+)
   -- �o�וi�ڏ��擾����
   AND  UHK.item_no = ITEM.item_no(+)
   AND  UHK.arrival_date >= ITEM.start_date_active(+)
   AND  UHK.arrival_date <= ITEM.end_date_active(+)
   -- �X�e�[�^�X��(�ړ�)
   AND  FLV00.language(+)    = 'JA'
   AND  FLV00.lookup_type(+) = 'XXINV_MOVE_STATUS'
   AND  FLV00.lookup_code(+) = UHK.req_status
   -- �X�e�[�^�X��(�o��)
   AND  FLV01.language(+)    = 'JA'
   AND  FLV01.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'
   AND  FLV01.lookup_code(+) = UHK.req_status
   -- �z���敪��
   AND  FLV02.language(+)    = 'JA'
   AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV02.lookup_code(+) = UHK.shipping_method_code
/
COMMENT ON TABLE APPS.XXSKY_�^���i�ڕ�_��{1_V IS 'SKYLINK�p�^���i�ڕʁi��{�j VIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�z��NO IS '�z��No'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�˗�_�ړ�NO IS '�˗�_�ړ�No'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�敪 IS '�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�󒍃^�C�v IS '�󒍃^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�X�e�[�^�X IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�X�e�[�^�X�� IS '�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�Ǌ����_ IS '�Ǌ����_'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�Ǌ����_�� IS '�Ǌ����_��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�^���Ǝ� IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�^���ƎҖ� IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�^���Ǝҗ��� IS '�^���Ǝҗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.���ɐ�_�z���� IS '���ɐ�_�z����'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.���ɐ�_�z���於 IS '���ɐ�_�z���於'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.���ɐ�_�z���旪�� IS '���ɐ�_�z���旪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�o�Ɍ� IS '�o�Ɍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�o�Ɍ��� IS '�o�Ɍ���'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�o�Ɍ����� IS '�o�Ɍ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�z���敪 IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�z���敪�� IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�o�ɓ� IS '�o�ɓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.���ɓ� IS '���ɓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�i�ڃR�[�h IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�i�ږ��� IS '�i�ږ���'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�i�ڗ��� IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�i�ڃo���� IS '�i�ڃo����'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�i�ڃP�[�X�� IS '�i�ڃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.���v�P�[�X�� IS '���v�P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�ύڏd�ʍ��v IS '�ύڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.���v�Z�p_�ύڏd�ʍ��v IS '���v�Z�p_�ύڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�i�ڏd�ʍ��v IS '�i�ڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.���v�Z�p_�i�ڏd�ʍ��v IS '���v�Z�p_�i�ڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.���v���z IS '���v���z'
/
COMMENT ON COLUMN APPS.XXSKY_�^���i�ڕ�_��{1_V.�i��_���v���z IS '�i��_���v���z'
/
