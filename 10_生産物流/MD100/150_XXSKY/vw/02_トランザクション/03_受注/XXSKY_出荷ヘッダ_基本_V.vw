CREATE OR REPLACE VIEW APPS.XXSKY_�o�׃w�b�__��{_V
(
 �˗�NO
,�z��NO
,�󒍃^�C�v��
,�g�D��
,�󒍓�
,�ŐV�t���O
,���˗�NO
,�O��z��NO
,�ڋq
,�ڋq��
,�o�א�
,�o�א於
,�o�׎w��
,�^���Ǝ�
,�^���ƎҖ�
,�z���敪
,�z���敪��
,�ڋq����
,���i�\
,���i�\��
,�X�e�[�^�X
,�X�e�[�^�X��
,�o�ח\���
,���ח\���
,���ڌ�NO
,�p���b�g�������
,�����S���m�F�˗��敪
,�����S���m�F�˗��敪��
,�^���敪
,�^���敪��
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
,�_��O�^���敪
,�_��O�^���敪��
,���׎���FROM
,���׎���FROM��
,���׎���TO
,���׎���TO��
,�����NO
,���v����
,������
,���x������
,�d�ʐύڌ���
,�e�ϐύڌ���
,��{�d��
,��{�e��
,�ύڏd�ʍ��v
,�ύڗe�ύ��v
,���ڗ�
,�p���b�g���v����
,�p���b�g���і���
,���v�p���b�g�d��
,�^���Ǝ�_����
,�^���Ǝ�_�\��
,�^���Ǝ�_���і�
,�^���Ǝ�_�\����
,�z���敪_����
,�z���敪_�\��
,�z���敪_���і�
,�z���敪_�\����
,�o�א�_����
,�o�א�_�\��
,�o�א�_���і�
,�o�א�_�\����
,�o�ד�
,�o�ד�_�\��
,���ד�
,���ד�_�\��
,�d�ʗe�ϋ敪
,�d�ʗe�ϋ敪��
,���ьv��ϋ敪
,�ʒm�X�e�[�^�X
,�ʒm�X�e�[�^�X��
,�O��ʒm�X�e�[�^�X
,�O��ʒm�X�e�[�^�X��
,�m��ʒm���{����
,�V�K�C���t���O
,�V�K�C���t���O��
,���ъǗ�����
,���ъǗ�������
,�w������
,�w��������
,�U�֐�
,�U�֐於
,���ڋL��
,��ʍX�V����
,��ʍX�V��
,�o�׈˗����ߓ���
,���߃R���J�����gID
,���ߌ�C���敪
,���ߌ�C���敪��
,�z��_�������
,�z��_������ʖ�
,�z��_���ڎ��
,�z��_���ڎ�ʖ�
,�z��_�z����R�[�h�敪
,�z��_�z����R�[�h�敪��
,�z��_�����z�ԑΏۋ敪
,�z��_�����z�ԑΏۋ敪��
,�z��_�E�v
,�z��_�x���^���v�Z�Ώۃt���O
,�z��_�x���^���v�Z�Ώۃt���O��
,�z��_�����^���v�Z�Ώۃt���O
,�z��_�����^���v�Z�Ώۃt���O��
,�z��_�ύڏd�ʍ��v
,�z��_�ύڗe�ύ��v
,�z��_�d�ʐύڌ���
,�z��_�e�ϐύڌ���
,�z��_�^���`��
,�z��_�^���`�Ԗ�
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        XOHA.request_no                  --�˗�No
       ,XOHA.delivery_no                 --�z��No
       ,OTTT.name                        --�󒍃^�C�v��
       ,HAOUT.name                       --�g�D��
       ,XOHA.ordered_date                --�󒍓�
       ,XOHA.latest_external_flag        --�ŐV�t���O
       ,XOHA.base_request_no             --���˗�No
       ,XOHA.prev_delivery_no            --�O��z��No
       ,XOHA.customer_code               --�ڋq
       ,XCA2V01.party_name               --�ڋq��
       ,XOHA.deliver_to                  --�o�א�
       ,XPS2V01.party_site_name          --�o�א於
       ,XOHA.shipping_instructions       --�o�׎w��
       ,XOHA.freight_carrier_code        --�^���Ǝ�
       ,XC2V01.party_name                --�^���ƎҖ�
       ,XOHA.shipping_method_code        --�z���敪
       ,FLV01.meaning                    --�z���敪��
       ,XOHA.cust_po_number              --�ڋq����
       ,XOHA.price_list_id               --���i�\
       ,QLHT.name                        --���i�\��
       ,XOHA.req_status                  --�X�e�[�^�X
       ,FLV02.meaning                    --�X�e�[�^�X��
       ,XOHA.schedule_ship_date          --�o�ח\���
       ,XOHA.schedule_arrival_date       --���ח\���
       ,XOHA.mixed_no                    --���ڌ�No
       ,XOHA.collected_pallet_qty        --�p���b�g�������
       ,XOHA.confirm_request_class       --�����S���m�F�˗��敪
       ,FLV03.meaning                    --�����S���m�F�˗��敪��
       ,XOHA.freight_charge_class        --�^���敪
       ,FLV04.meaning                    --�^���敪��
       ,XOHA.deliver_from                --�o�׌��ۊǏꏊ
       ,XIL2V.description                --�o�׌��ۊǏꏊ��
       ,XOHA.head_sales_branch           --�Ǌ����_
       ,XCA2V02.party_name               --�Ǌ����_��
       ,XCA2V02.party_short_name         --�Ǌ����_����
       ,XOHA.input_sales_branch          --���͋��_
       ,XCA2V03.party_name               --���͋��_��
       ,XCA2V03.party_short_name         --���͋��_����
       ,XOHA.prod_class                  --���i�敪
       ,FLV05.meaning                    --���i�敪��
       ,XOHA.item_class                  --�i�ڋ敪
       ,FLV06.meaning                    --�i�ڋ敪��
       ,XOHA.no_cont_freight_class       --�_��O�^���敪
       ,FLV07.meaning                    --�_��O�^���敪��
       ,XOHA.arrival_time_from           --���׎���FROM
       ,FLV08.meaning                    --���׎���FROM��
       ,XOHA.arrival_time_to             --���׎���TO
       ,FLV09.meaning                    --���׎���TO��
       ,XOHA.slip_number                 --�����No
       ,XOHA.sum_quantity                --���v����
       ,XOHA.small_quantity              --������
       ,XOHA.label_quantity              --���x������
       ,CEIL( XOHA.loading_efficiency_weight * 100 ) / 100  --�����_��R�ȉ��؂�グ
        loading_efficiency_weight        --�d�ʐύڌ���
       ,CEIL( XOHA.loading_efficiency_capacity * 100 ) / 100  --�����_��R�ȉ��؂�グ
        loading_efficiency_capacity      --�e�ϐύڌ���
       ,CEIL( XOHA.based_weight )
        based_weight                     --��{�d��
       ,CEIL( XOHA.based_capacity )
        based_capacity                   --��{�e��
       ,CEIL( XOHA.sum_weight )
        sum_weight                       --�ύڏd�ʍ��v
       ,CEIL( XOHA.sum_capacity )
        sum_capacity                     --�ύڗe�ύ��v
       ,CEIL( XOHA.mixed_ratio * 100 ) / 100  --�����_��R�ȉ��؂�グ
        mixed_ratio                      --���ڗ�
       ,XOHA.pallet_sum_quantity         --�p���b�g���v����
       ,XOHA.real_pallet_quantity        --�p���b�g���і���
       ,XOHA.sum_pallet_weight           --���v�p���b�g�d��
       ,XOHA.result_freight_carrier_code --�^���Ǝ�_����
       ,NVL( XOHA.result_freight_carrier_code, XOHA.freight_carrier_code )        --NVL( �^���Ǝ�_����, �^���Ǝ� )
                                         --�^���Ǝ�_�\��
       ,XC2V02.party_name                --�^���Ǝ�_���і�
       ,CASE WHEN XOHA.result_freight_carrier_code IS NULL THEN XC2V01.party_name --�^���Ǝ�_���т����݂��Ȃ��ꍇ�͉^���ƎҖ�
             ELSE                                               XC2V02.party_name --�^���Ǝ�_���т����݂���ꍇ�͉^���Ǝ�_���і�
        END                              --�^���Ǝ�_�\����
       ,XOHA.result_shipping_method_code --�z���敪_����
       ,NVL( XOHA.result_shipping_method_code, XOHA.shipping_method_code )        --NVL( �z���敪_����, �z���敪 )
                                         --�z���敪_�\��
       ,FLV10.meaning                    --�z���敪_���і�
       ,CASE WHEN XOHA.result_shipping_method_code IS NULL THEN FLV01.meaning     --�z���敪_���т����݂��Ȃ��ꍇ�͔z���敪��
             ELSE                                               FLV10.meaning     --�z���敪_���т����݂���ꍇ�͔z���敪_���і�
        END                              --�z���敪_�\����
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
       ,XOHA.weight_capacity_class       --�d�ʗe�ϋ敪
       ,FLV11.meaning                    --�d�ʗe�ϋ敪��
       ,XOHA.actual_confirm_class        --���ьv��ϋ敪
       ,XOHA.notif_status                --�ʒm�X�e�[�^�X
       ,FLV12.meaning                    --�ʒm�X�e�[�^�X��
       ,XOHA.prev_notif_status           --�O��ʒm�X�e�[�^�X
       ,FLV13.meaning                    --�O��ʒm�X�e�[�^�X��
       ,TO_CHAR( XOHA.notif_date,'YYYY/MM/DD HH24:MI:SS')
                                         --�m��ʒm���{����
       ,XOHA.new_modify_flg              --�V�K�C���t���O
       ,FLV14.meaning                    --�V�K�C���t���O��
       ,XOHA.performance_management_dept --���ъǗ�����
       ,XL2V01.location_name             --���ъǗ�������
       ,XOHA.instruction_dept            --�w������
       ,XL2V02.location_name             --�w��������
       ,XOHA.transfer_location_code      --�U�֐�
       ,XL2V03.location_name             --�U�֐於
       ,XOHA.mixed_sign                  --���ڋL��
       ,TO_CHAR( XOHA.screen_update_date,'YYYY/MM/DD HH24:MI:SS')
                                         --��ʍX�V����
       ,FU.user_name                     --��ʍX�V��
       ,TO_CHAR( XOHA.tightening_date,'YYYY/MM/DD HH24:MI:SS')
                                         --�o�׈˗����ߓ���
       ,XOHA.tightening_program_id       --���߃R���J�����gID
       ,XOHA.corrected_tighten_class     --���ߌ�C���敪
       ,FLV15.meaning                    --���ߌ�C���敪��
       ,XCS.transaction_type             --�z��_�������
       ,FLV16.meaning                    --�z��_������ʖ�
       ,XCS.mixed_type                   --�z��_���ڎ��
       ,DECODE(XCS.mixed_type, '1' ,'�W��', '2', '����')
        mixed_type_name                  --�z��_���ڎ�ʖ�
       ,XCS.deliver_to_code_class        --�z��_�z����R�[�h�敪
       ,FLV17.meaning                    --�z��_�z����R�[�h�敪��
       ,XCS.auto_process_type            --�z��_�����z�ԑΏۋ敪
       ,FLV18.meaning                    --�z��_�����z�ԑΏۋ敪��
       ,XCS.description                  --�z��_�E�v
       ,XCS.payment_freight_flag         --�z��_�x���^���v�Z�Ώۃt���O
       ,DECODE(XCS.payment_freight_flag, '0', '�ΏۊO', '1', '�Ώ�')
        payment_freight_flag_name        --�z��_�x���^���v�Z�Ώۃt���O��
       ,XCS.demand_freight_flag          --�z��_�����^���v�Z�Ώۃt���O
       ,DECODE(XCS.demand_freight_flag, '0', '�ΏۊO', '1', '�Ώ�')
        demand_freight_flag_name         --�z��_�����^���v�Z�Ώۃt���O��
       ,CEIL( XCS.sum_loading_weight )
        sum_loading_weight               --�z��_�ύڏd�ʍ��v
       ,CEIL( XCS.sum_loading_capacity )
        sum_loading_capacity             --�z��_�ύڗe�ύ��v
       ,CEIL( XCS.loading_efficiency_weight * 100 ) / 100  --�����_��R�ȉ��؂�グ
        loading_efficiency_weight        --�z��_�d�ʐύڌ���
       ,CEIL( XCS.loading_efficiency_capacity * 100 ) / 100  --�����_��R�ȉ��؂�グ
        loading_efficiency_capacity      --�z��_�e�ϐύڌ���
       ,XCS.freight_charge_type          --�z��_�^���`��
       ,FLV19.meaning                    --�z��_�^���`�Ԗ�
       ,FU_CB.user_name                  --�쐬��
       ,TO_CHAR( XOHA.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�쐬��
       ,FU_LU.user_name                  --�ŏI�X�V��
       ,TO_CHAR( XOHA.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                         --�ŏI�X�V��
       ,FU_LL.user_name                  --�ŏI�X�V���O�C��
  FROM  xxwsh_order_headers_all      XOHA    --�󒍃w�b�_�A�h�I��
       ,oe_transaction_types_all     OTTA    --�󒍃^�C�v�}�X�^
       ,xxwsh_carriers_schedule      XCS     --�z�Ԕz���A�h�I���e�[�u��
       ,oe_transaction_types_tl      OTTT    --�󒍃^�C�v�}�X�^(���{��)
       ,hr_all_organization_units_tl HAOUT   --�q��(�g�D��)
       ,xxsky_cust_accounts2_v       XCA2V01 --SKYLINK�p����VIEW �ڋq���VIEW2(�ڋq��)
       ,xxsky_party_sites2_v         XPS2V01 --SKYLINK�p����VIEW �z������VIEW2(�z���於)
       ,xxsky_carriers2_v            XC2V01  --SKYLINK�p����VIEW �^���Ǝҏ��VIEW2(�^���ƎҖ�)
       ,qp_list_headers_tl           QLHT    --���i�\
       ,xxsky_item_locations2_v      XIL2V   --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(�o�׌��ۊǏꏊ��)
       ,xxsky_cust_accounts2_v       XCA2V02 --SKYLINK�p����VIEW �ڋq���VIEW2(�Ǌ����_)
       ,xxsky_cust_accounts2_v       XCA2V03 --SKYLINK�p����VIEW �ڋq���VIEW2(���͋��_)
       ,xxsky_carriers2_v            XC2V02  --SKYLINK�p����VIEW �^���Ǝҏ��VIEW2(�^���Ǝ�_���і�)
       ,xxsky_party_sites2_v         XPS2V02 --SKYLINK�p����VIEW �z������VIEW2(�o�א�_���і�)
       ,xxsky_locations2_v           XL2V01  --SKYLINK�p����VIEW ���Ə����VIEW2(���ъǗ�����)
       ,xxsky_locations2_v           XL2V02  --SKYLINK�p����VIEW ���Ə����VIEW2(�w��������)
       ,xxsky_locations2_v           XL2V03  --SKYLINK�p����VIEW ���Ə����VIEW2(�U�֐於)
       ,fnd_user                     FU      --���[�U�[�}�X�^(��ʍX�V��)
       ,fnd_user                     FU_CB   --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                     FU_LU   --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                     FU_LL   --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                   FL_LL   --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_lookup_values            FLV01   --�N�C�b�N�R�[�h(�z���敪��)
       ,fnd_lookup_values            FLV02   --�N�C�b�N�R�[�h(�X�e�[�^�X��)
       ,fnd_lookup_values            FLV03   --�N�C�b�N�R�[�h(�����S���m�F�˗��敪��)
       ,fnd_lookup_values            FLV04   --�N�C�b�N�R�[�h(�^���敪)
       ,fnd_lookup_values            FLV05   --�N�C�b�N�R�[�h(���i�敪��)
       ,fnd_lookup_values            FLV06   --�N�C�b�N�R�[�h(�i�ڋ敪��)
       ,fnd_lookup_values            FLV07   --�N�C�b�N�R�[�h(�_��O�^���敪��)
       ,fnd_lookup_values            FLV08   --�N�C�b�N�R�[�h(���׎���FROM��)
       ,fnd_lookup_values            FLV09   --�N�C�b�N�R�[�h(���׎���TO��)
       ,fnd_lookup_values            FLV10   --�N�C�b�N�R�[�h(�z���敪_���і�)
       ,fnd_lookup_values            FLV11   --�N�C�b�N�R�[�h(�d�ʗe�ϋ敪��)
       ,fnd_lookup_values            FLV12   --�N�C�b�N�R�[�h(�ʒm�X�e�[�^�X��)
       ,fnd_lookup_values            FLV13   --�N�C�b�N�R�[�h(�O��ʒm�X�e�[�^�X��)
       ,fnd_lookup_values            FLV14   --�N�C�b�N�R�[�h(�V�K�C���t���O��)
       ,fnd_lookup_values            FLV15   --�N�C�b�N�R�[�h(���ߌ�C���敪��)
       ,fnd_lookup_values            FLV16   --�N�C�b�N�R�[�h(�z��_������ʖ�)
       ,fnd_lookup_values            FLV17   --�N�C�b�N�R�[�h(�z��_�z����R�[�h�敪��)
       ,fnd_lookup_values            FLV18   --�N�C�b�N�R�[�h(�z��_�����z�ԑΏۋ敪��)
       ,fnd_lookup_values            FLV19   --�N�C�b�N�R�[�h(�z��_�^���`�Ԗ�)
 WHERE
   --�o�׏��擾
        OTTA.attribute1 = '1'            -- �o��
   AND  XOHA.latest_external_flag = 'Y'
   AND  XOHA.order_type_id = OTTA.transaction_type_id
   --�z��/�z���A�h�I�����擾
   AND  XOHA.delivery_no = XCS.delivery_no(+)
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
   AND  XOHA.deliver_to_id = XPS2V01.party_site_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XPS2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XPS2V01.end_date_active(+)
   --�^���ƎҖ��擾
   AND  XOHA.career_id = XC2V01.party_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XC2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XC2V01.end_date_active(+)
   --���i�\���擾
   AND  QLHT.language(+) = 'JA'
   AND  XOHA.price_list_id = QLHT.list_header_id(+)
   --�o�׌��ۊǏꏊ���擾
   AND  XOHA.deliver_from_id = XIL2V.inventory_location_id(+)
   --�Ǌ����_���擾
   AND  XOHA.head_sales_branch = XCA2V02.party_number(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V02.end_date_active(+)
   --���͋��_���擾
   AND  XOHA.input_sales_branch = XCA2V03.party_number(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V03.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V03.end_date_active(+)
   --�^���Ǝ�_���і��擾
   AND  XOHA.result_freight_carrier_id = XC2V02.party_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XC2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XC2V02.end_date_active(+)
   --�o�א�_���і��擾
   AND  XOHA.result_deliver_to_id = XPS2V02.party_site_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XPS2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XPS2V02.end_date_active(+)
   --���ъǗ��������擾
   AND  XOHA.performance_management_dept = XL2V01.location_code(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XL2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XL2V01.end_date_active(+)
   --�w���������擾
   AND  XOHA.instruction_dept = XL2V02.location_code(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XL2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XL2V02.end_date_active(+)
   --�U�֐於�擾
   AND  XOHA.transfer_location_code = XL2V03.location_code(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XL2V03.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XL2V03.end_date_active(+)
   --��ʍX�V�Җ��擾
   AND  XOHA.screen_update_by = FU.user_id(+)
   --WHO�J�������擾
   AND  XOHA.created_by        = FU_CB.user_id(+)
   AND  XOHA.last_updated_by   = FU_LU.user_id(+)
   AND  XOHA.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id          = FU_LL.user_id(+)
   --�y�N�C�b�N�R�[�h�z�z���敪��
   AND  FLV01.language(+) = 'JA'                              --����
   AND  FLV01.lookup_type(+) = 'XXCMN_SHIP_METHOD'            --�N�C�b�N�R�[�h�^�C�v
   AND  FLV01.lookup_code(+) = XOHA.shipping_method_code      --�N�C�b�N�R�[�h
   --�y�N�C�b�N�R�[�h�z�X�e�[�^�X��
   AND  FLV02.language(+) = 'JA'
   AND  FLV02.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'
   AND  FLV02.lookup_code(+) = XOHA.req_status
   --�y�N�C�b�N�R�[�h�z�����S���m�F�˗��敪��
   AND  FLV03.language(+) = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV03.lookup_code(+) = XOHA.confirm_request_class
   --�y�N�C�b�N�R�[�h�z�^���敪��
   AND  FLV04.language(+) = 'JA'
   AND  FLV04.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV04.lookup_code(+) = XOHA.freight_charge_class
   --�y�N�C�b�N�R�[�h�z���i�敪��
   AND  FLV05.language(+) = 'JA'
   AND  FLV05.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   AND  FLV05.lookup_code(+) = XOHA.prod_class
   --�y�N�C�b�N�R�[�h�z�i�ڋ敪��
   AND  FLV06.language(+) = 'JA'
   AND  FLV06.lookup_type(+) = 'XXWSH_ITEM_DIV'
   AND  FLV06.lookup_code(+) = XOHA.item_class
   --�y�N�C�b�N�R�[�h�z�_��O�^���敪��
   AND  FLV07.language(+) = 'JA'
   AND  FLV07.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV07.lookup_code(+) = XOHA.no_cont_freight_class
   --�y�N�C�b�N�R�[�h�z���׎���FROM��
   AND  FLV08.language(+) = 'JA'
   AND  FLV08.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
   AND  FLV08.lookup_code(+) = XOHA.arrival_time_from
   --�y�N�C�b�N�R�[�h�z���׎���TO��
   AND  FLV09.language(+) = 'JA'
   AND  FLV09.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
   AND  FLV09.lookup_code(+) = XOHA.arrival_time_to
   --�y�N�C�b�N�R�[�h�z�z���敪_���і�
   AND  FLV10.language(+) = 'JA'
   AND  FLV10.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV10.lookup_code(+) = XOHA.result_shipping_method_code
   --�y�N�C�b�N�R�[�h�z�d�ʗe�ϋ敪��
   AND  FLV11.language(+) = 'JA'
   AND  FLV11.lookup_type(+) = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV11.lookup_code(+) = XOHA.weight_capacity_class
   --�y�N�C�b�N�R�[�h�z�ʒm�X�e�[�^�X��
   AND  FLV12.language(+) = 'JA'
   AND  FLV12.lookup_type(+) = 'XXWSH_NOTIF_STATUS'
   AND  FLV12.lookup_code(+) = XOHA.notif_status
   --�y�N�C�b�N�R�[�h�z�O��ʒm�X�e�[�^�X��
   AND  FLV13.language(+) = 'JA'
   AND  FLV13.lookup_type(+) = 'XXWSH_NOTIF_STATUS'
   AND  FLV13.lookup_code(+) = XOHA.prev_notif_status
   --�y�N�C�b�N�R�[�h�z�V�K�C���t���O��
   AND  FLV14.language(+) = 'JA'
   AND  FLV14.lookup_type(+) = 'XXWSH_NEW_MODIFY_FLG'
   AND  FLV14.lookup_code(+) = XOHA.new_modify_flg
   --�y�N�C�b�N�R�[�h�z���ߌ㏈���敪��
   AND  FLV15.language(+) = 'JA'
   AND  FLV15.lookup_type(+) = 'XXWSH_TIGHTEN_RELEASE_CLASS'
   AND  FLV15.lookup_code(+) = XOHA.corrected_tighten_class
   --�y�N�C�b�N�R�[�h�z�z��_������ʖ�
   AND  FLV16.language(+) = 'JA'
   AND  FLV16.lookup_type(+) = 'XXWSH_PROCESS_TYPE'
   AND  FLV16.lookup_code(+) = XCS.transaction_type
   --�y�N�C�b�N�R�[�h�z�z��_�z����R�[�h�敪��
   AND  FLV17.language(+) = 'JA'
   AND  FLV17.lookup_type(+) = 'CUSTOMER CLASS'
   AND  FLV17.lookup_code(+) = XCS.deliver_to_code_class
   --�y�N�C�b�N�R�[�h�z�z��_�����z�ԑΏۋ敪��
   AND  FLV18.language(+) = 'JA'
   AND  FLV18.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV18.lookup_code(+) = XCS.auto_process_type
   --�y�N�C�b�N�R�[�h�z�z��_�^���`�Ԗ�
   AND  FLV19.language(+) = 'JA'
   AND  FLV19.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV19.lookup_code(+) = XCS.freight_charge_type
/
COMMENT ON TABLE APPS.XXSKY_�o�׃w�b�__��{_V IS 'SKYLINK�p�o�׃w�b�_�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�˗�NO IS '�˗�No'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��NO IS '�z��No'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�󒍃^�C�v�� IS '�󒍃^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�g�D�� IS '�g�D��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�󒍓� IS '�󒍓�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�ŐV�t���O IS '�ŐV�t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���˗�NO IS '���˗�No'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�O��z��NO IS '�O��z��No'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�ڋq IS '�ڋq'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�ڋq�� IS '�ڋq��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�א� IS '�o�א�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�א於 IS '�o�א於'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�׎w�� IS '�o�׎w��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�^���Ǝ� IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�^���ƎҖ� IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z���敪 IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z���敪�� IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�ڋq���� IS '�ڋq����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���i�\ IS '���i�\'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���i�\�� IS '���i�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�X�e�[�^�X IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�X�e�[�^�X�� IS '�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�ח\��� IS '�o�ח\���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���ח\��� IS '���ח\���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���ڌ�NO IS '���ڌ�No'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�p���b�g������� IS '�p���b�g�������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�����S���m�F�˗��敪 IS '�����S���m�F�˗��敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�����S���m�F�˗��敪�� IS '�����S���m�F�˗��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�^���敪 IS '�^���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�^���敪�� IS '�^���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�׌��ۊǏꏊ IS '�o�׌��ۊǏꏊ'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�׌��ۊǏꏊ�� IS '�o�׌��ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�Ǌ����_ IS '�Ǌ����_'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�Ǌ����_�� IS '�Ǌ����_��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�Ǌ����_���� IS '�Ǌ����_����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���͋��_ IS '���͋��_'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���͋��_�� IS '���͋��_��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���͋��_���� IS '���͋��_����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�_��O�^���敪 IS '�_��O�^���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�_��O�^���敪�� IS '�_��O�^���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���׎���FROM IS '���׎���FROM'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���׎���FROM�� IS '���׎���FROM��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���׎���TO IS '���׎���TO'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���׎���TO�� IS '���׎���TO��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�����NO IS '�����No'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���v���� IS '���v����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���x������ IS '���x������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�d�ʐύڌ��� IS '�d�ʐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�e�ϐύڌ��� IS '�e�ϐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.��{�d�� IS '��{�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.��{�e�� IS '��{�e��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�ύڏd�ʍ��v IS '�ύڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�ύڗe�ύ��v IS '�ύڗe�ύ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���ڗ� IS '���ڗ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�p���b�g���v���� IS '�p���b�g���v����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�p���b�g���і��� IS '�p���b�g���і���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���v�p���b�g�d�� IS '���v�p���b�g�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�^���Ǝ�_���� IS '�^���Ǝ�_����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�^���Ǝ�_�\�� IS '�^���Ǝ�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�^���Ǝ�_���і� IS '�^���Ǝ�_���і�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�^���Ǝ�_�\���� IS '�^���Ǝ�_�\����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z���敪_���� IS '�z���敪_����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z���敪_�\�� IS '�z���敪_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z���敪_���і� IS '�z���敪_���і�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z���敪_�\���� IS '�z���敪_�\����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�א�_���� IS '�o�א�_����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�א�_�\�� IS '�o�א�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�א�_���і� IS '�o�א�_���і�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�א�_�\���� IS '�o�א�_�\����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�ד� IS '�o�ד�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�ד�_�\�� IS '�o�ד�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���ד� IS '���ד�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���ד�_�\�� IS '���ד�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�d�ʗe�ϋ敪 IS '�d�ʗe�ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�d�ʗe�ϋ敪�� IS '�d�ʗe�ϋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���ьv��ϋ敪 IS '���ьv��ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�ʒm�X�e�[�^�X IS '�ʒm�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�ʒm�X�e�[�^�X�� IS '�ʒm�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�O��ʒm�X�e�[�^�X IS '�O��ʒm�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�O��ʒm�X�e�[�^�X�� IS '�O��ʒm�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�m��ʒm���{���� IS '�m��ʒm���{����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�V�K�C���t���O IS '�V�K�C���t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�V�K�C���t���O�� IS '�V�K�C���t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���ъǗ����� IS '���ъǗ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���ъǗ������� IS '���ъǗ�������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�w������ IS '�w������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�w�������� IS '�w��������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�U�֐� IS '�U�֐�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�U�֐於 IS '�U�֐於'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���ڋL�� IS '���ڋL��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.��ʍX�V���� IS '��ʍX�V����'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.��ʍX�V�� IS '��ʍX�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�o�׈˗����ߓ��� IS '�o�׈˗����ߓ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���߃R���J�����gID IS '���߃R���J�����gID'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���ߌ�C���敪 IS '���ߌ�C���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.���ߌ�C���敪�� IS '���ߌ�C���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_������� IS '�z��_�������'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_������ʖ� IS '�z��_������ʖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_���ڎ�� IS '�z��_���ڎ��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_���ڎ�ʖ� IS '�z��_���ڎ�ʖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�z����R�[�h�敪 IS '�z��_�z����R�[�h�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�z����R�[�h�敪�� IS '�z��_�z����R�[�h�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�����z�ԑΏۋ敪 IS '�z��_�����z�ԑΏۋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�����z�ԑΏۋ敪�� IS '�z��_�����z�ԑΏۋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�E�v IS '�z��_�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�x���^���v�Z�Ώۃt���O IS '�z��_�x���^���v�Z�Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�x���^���v�Z�Ώۃt���O�� IS '�z��_�x���^���v�Z�Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�����^���v�Z�Ώۃt���O IS '�z��_�����^���v�Z�Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�����^���v�Z�Ώۃt���O�� IS '�z��_�����^���v�Z�Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�ύڏd�ʍ��v IS '�z��_�ύڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�ύڗe�ύ��v IS '�z��_�ύڗe�ύ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�d�ʐύڌ��� IS '�z��_�d�ʐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�e�ϐύڌ��� IS '�z��_�e�ϐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�^���`�� IS '�z��_�^���`��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�z��_�^���`�Ԗ� IS '�z��_�^���`�Ԗ�'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�o�׃w�b�__��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
