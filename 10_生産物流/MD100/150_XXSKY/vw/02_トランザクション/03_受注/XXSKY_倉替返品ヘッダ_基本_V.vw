CREATE OR REPLACE VIEW APPS.XXSKY_�q�֕ԕi�w�b�__��{_V
(
 �˗�NO
,�󒍃^�C�v��
,�g�D��
,�󒍓�
,�ŐV�t���O
,���˗�NO
,�ڋq
,�ڋq��
,�o�א�
,�o�א於
,�o�׎w��
,���i�\
,���i�\��
,�X�e�[�^�X
,�X�e�[�^�X��
,�o�ח\���
,���ח\���
,�o�׌��ۊǏꏊ
,�o�׌��ۊǏꏊ��
,�Ǌ����_
,�Ǌ����_��
,�Ǌ����_����
,���͋��_
,���͋��_��
,���͋��_����
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,���v����
,�o�א�_����
,�o�א�_�\��
,�o�א�_���і�
,�o�א�_�\����
,�o�ד�
,�o�ד�_�\��
,���ד�
,���ד�_�\��
,���ьv��ϋ敪
,�m��ʒm���{����
,�V�K�C���t���O
,�V�K�C���t���O��
,���ъǗ�����
,���ъǗ�������
,�o�^����
,�o�׈˗����ߓ���
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XOHA.request_no                  --�˗�No
       ,OTTT.name                        --�󒍃^�C�v��
       ,HAOUT.name                       --�g�D��
       ,XOHA.ordered_date                --�󒍓�
       ,XOHA.latest_external_flag        --�ŐV�t���O
       ,XOHA.base_request_no             --���˗�No
       ,XOHA.customer_code               --�ڋq
       ,XCA2V01.party_name               --�ڋq��
       ,XOHA.deliver_to                  --�o�א�
       ,XPS2V01.party_site_name          --�o�א於
       ,XOHA.shipping_instructions       --�o�׎w��
       ,XOHA.price_list_id               --���i�\
       ,QLHT.name                        --���i�\��
       ,XOHA.req_status                  --�X�e�[�^�X
       ,FLV01.meaning                    --�X�e�[�^�X��
       ,XOHA.schedule_ship_date          --�o�ח\���
       ,XOHA.schedule_arrival_date       --���ח\���
       ,XOHA.deliver_from                --�o�׌��ۊǏꏊ
       ,XIL2V.description                --�o�׌��ۊǏꏊ��
       ,XOHA.head_sales_branch           --�Ǌ����_
       ,XCA2V02.party_name               --�Ǌ����_��
       ,XCA2V02.party_short_name         --�Ǌ����_����
       ,XOHA.input_sales_branch          --���͋��_
       ,XCA2V03.party_name               --���͋��_��
       ,XCA2V03.party_short_name         --���͋��_����
       ,XOHA.prod_class                  --���i�敪
       ,FLV02.meaning                    --���i�敪��
       ,XOHA.item_class                  --�i�ڋ敪
       ,FLV03.meaning                    --�i�ڋ敪��
       ,XOHA.sum_quantity                --���v����
       ,XOHA.result_deliver_to           --�o�א�_����
       ,NVL( XOHA.result_deliver_to, XOHA.deliver_to )                            --NVL( �o�א�_����, �o�א� )
                                         --�o�א�_�\��
       ,XPS2V02.party_site_name          --�o�א�_���і�
       ,CASE WHEN XOHA.result_deliver_to IS NULL THEN XPS2V01.party_site_name     --�o�א�_���т����݂��Ȃ��ꍇ�͏o�א於
             ELSE                                     XPS2V02.party_site_name     --�o�א�_���т����݂���ꍇ�͏o�א�_���і�
        END                              --�o�א�_�\����
       ,XOHA.shipped_date                --�o�ד�
       ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date )                         --NVL( �o�ד�, �o�ח\��� )
                                         --�o�ד�_�\��
       ,XOHA.arrival_date                --���ד�
       ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )                      --NVL( ���ד�, ���ח\��� )
                                         --���ד�_�\��
       ,XOHA.actual_confirm_class        --���ьv��ϋ敪
       ,TO_CHAR( XOHA.notif_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�m��ʒm���{����
       ,XOHA.new_modify_flg              --�V�K�C���t���O
       ,FLV04.meaning                    --�V�K�C���t���O��
       ,XOHA.performance_management_dept --���ъǗ�����
       ,XL2V.location_name               --���ъǗ�������
       ,XOHA.registered_sequence         --�o�^����
       ,TO_CHAR( XOHA.tightening_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�o�׈˗����ߓ���
       ,FU_CB.user_name                  --�쐬��
       ,TO_CHAR( XOHA.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�쐬��
       ,FU_LU.user_name                  --�ŏI�X�V��
       ,TO_CHAR( XOHA.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�ŏI�X�V��
       ,FU_LL.user_name                  --�ŏI�X�V���O�C��
  FROM  xxwsh_order_headers_all      XOHA    --�󒍃w�b�_�A�h�I��
       ,oe_transaction_types_all     OTTA    --�󒍃^�C�v�}�X�^
       ,oe_transaction_types_tl      OTTT    --�󒍃^�C�v�}�X�^(���{��)
       ,hr_all_organization_units_tl HAOUT   --�q��(�g�D��)
       ,xxsky_cust_accounts2_v       XCA2V01 --SKYLINK�p����VIEW �ڋq���VIEW2(�ڋq��)
       ,xxsky_party_sites2_v         XPS2V01 --SKYLINK�p����VIEW �z������VIEW2(�o�א於)
       ,qp_list_headers_tl           QLHT    --���i�\
       ,xxsky_item_locations2_v      XIL2V   --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(�o�׌��ۊǏꏊ��)
       ,xxsky_cust_accounts2_v       XCA2V02 --SKYLINK�p����VIEW �ڋq���VIEW2(�Ǌ����_��)
       ,xxsky_cust_accounts2_v       XCA2V03 --SKYLINK�p����VIEW �ڋq���VIEW2(���͋��_��)
       ,xxsky_party_sites2_v         XPS2V02 --SKYLINK�p����VIEW �z������VIEW2(�o�א�_���і�)
       ,xxsky_locations2_v           XL2V    --SKYLINK�p����VIEW ���Ə����VIEW2(���ъǗ�������)
       ,fnd_user                     FU_CB   --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                     FU_LU   --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                     FU_LL   --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                   FL_LL   --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_lookup_values            FLV01   --�N�C�b�N�R�[�h(�X�e�[�^�X��)
       ,fnd_lookup_values            FLV02   --�N�C�b�N�R�[�h(���i�敪��)
       ,fnd_lookup_values            FLV03   --�N�C�b�N�R�[�h(�i�ڋ敪��)
       ,fnd_lookup_values            FLV04   --�N�C�b�N�R�[�h(�V�K�C���t���O��)
 WHERE
   --�q�֕ԕi���擾
        OTTA.attribute1 = '3'            --�q�֕ԕi
   AND  XOHA.latest_external_flag = 'Y'
   AND  XOHA.order_type_id = OTTA.transaction_type_id
   --�󒍃^�C�v���擾
   AND  OTTT.language(+) = 'JA'
   AND  XOHA.order_type_id = OTTT.transaction_type_id(+)
   --�g�D���擾
   AND  HAOUT.language(+) = 'JA'
   AND  XOHA.organization_id = HAOUT.organization_id(+)
   --�ڋq���擾
   AND  XOHA.customer_id = XCA2V01.party_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V01.end_date_active(+)
   --�o�א於�擾
-- 2010/01/28 M.Miyagawa MOD Start �{�ԏ�Q#1694
   AND  XOHA.deliver_to = XPS2V01.party_site_number(+)         --�z����R�[�h
--   AND  XOHA.deliver_to_id = XPS2V01.party_site_id(+)        --�z����ID
-- 2010/01/28 M.Miyagawa MOD ENd
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XPS2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XPS2V01.end_date_active(+)
   --���i�\���擾
   AND  QLHT.language(+) = 'JA'
   AND  XOHA.price_list_id = QLHT.list_header_id(+)
   --�o�Ɍ��ۊǏꏊ���擾
   AND  XOHA.deliver_from_id = XIL2V.inventory_location_id(+)
   --�Ǌ����_���擾
   AND  XOHA.head_sales_branch = XCA2V02.party_number(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V02.end_date_active(+)
   --���͋��_���擾
   AND  XOHA.input_sales_branch = XCA2V03.party_number(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V03.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V03.end_date_active(+)
   --�o�א�_���і��擾
-- 2010/01/28 M.Miyagawa MOD Start �{�ԏ�Q#1694
   AND  XOHA.result_deliver_to = XPS2V02.party_site_number(+)  --�z����R�[�h
--   AND  XOHA.result_deliver_to_id = XPS2V02.party_site_id(+) --�z����ID
-- 2010/01/28 M.Miyagawa MOD End
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XPS2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XPS2V02.end_date_active(+)
   --���ъǗ��������擾
   AND  XOHA.performance_management_dept = XL2V.location_code(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XL2V.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XL2V.end_date_active(+)
   --WHO�J�������擾
   AND  XOHA.created_by        = FU_CB.user_id(+)
   AND  XOHA.last_updated_by   = FU_LU.user_id(+)
   AND  XOHA.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id          = FU_LL.user_id(+)
   --�y�N�C�b�N�R�[�h�z�X�e�[�^�X��
   AND  FLV01.language(+) = 'JA'                              --����
   AND  FLV01.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'     --�N�C�b�N�R�[�h�^�C�v
   AND  FLV01.lookup_code(+) = XOHA.req_status                --�N�C�b�N�R�[�h
   --�y�N�C�b�N�R�[�h�z���i�敪��
   AND  FLV02.language(+) = 'JA'
   AND  FLV02.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   AND  FLV02.lookup_code(+) = XOHA.prod_class
   --�y�N�C�b�N�R�[�h�z�i�ڋ敪��
   AND  FLV03.language(+) = 'JA'
   AND  FLV03.lookup_type(+) = 'XXWSH_ITEM_DIV'
   AND  FLV03.lookup_code(+) = XOHA.item_class
   --�y�N�C�b�N�R�[�h�z�V�K�C���t���O��
   AND  FLV04.language(+) = 'JA'
   AND  FLV04.lookup_type(+) = 'XXWSH_NEW_MODIFY_FLG'
   AND  FLV04.lookup_code(+) = XOHA.new_modify_flg
/
COMMENT ON TABLE APPS.XXSKY_�q�֕ԕi�w�b�__��{_V IS 'SKYLINK�p�q�֕ԕi�w�b�_�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�˗�NO IS '�˗�No'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�󒍃^�C�v�� IS '�󒍃^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�g�D�� IS '�g�D��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�󒍓� IS '�󒍓�'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�ŐV�t���O IS '�ŐV�t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���˗�NO IS '���˗�No'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�ڋq IS '�ڋq'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�ڋq�� IS '�ڋq��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�א� IS '�o�א�'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�א於 IS '�o�א於'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�׎w�� IS '�o�׎w��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���i�\ IS '���i�\'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���i�\�� IS '���i�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�X�e�[�^�X IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�X�e�[�^�X�� IS '�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�ח\��� IS '�o�ח\���'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���ח\��� IS '���ח\���'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�׌��ۊǏꏊ IS '�o�׌��ۊǏꏊ'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�׌��ۊǏꏊ�� IS '�o�׌��ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�Ǌ����_ IS '�Ǌ����_'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�Ǌ����_�� IS '�Ǌ����_��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�Ǌ����_���� IS '�Ǌ����_����'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���͋��_ IS '���͋��_'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���͋��_�� IS '���͋��_��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���͋��_���� IS '���͋��_����'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���v���� IS '���v����'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�א�_���� IS '�o�א�_����'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�א�_�\�� IS '�o�א�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�א�_���і� IS '�o�א�_���і�'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�א�_�\���� IS '�o�א�_�\����'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�ד� IS '�o�ד�'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�ד�_�\�� IS '�o�ד�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���ד� IS '���ד�'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���ד�_�\�� IS '���ד�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���ьv��ϋ敪 IS '���ьv��ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�m��ʒm���{���� IS '�m��ʒm���{����'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�V�K�C���t���O IS '�V�K�C���t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�V�K�C���t���O�� IS '�V�K�C���t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���ъǗ����� IS '���ъǗ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.���ъǗ������� IS '���ъǗ�������'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�^���� IS '�o�^����'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�o�׈˗����ߓ��� IS '�o�׈˗����ߓ���'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�q�֕ԕi�w�b�__��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
