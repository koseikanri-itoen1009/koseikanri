CREATE OR REPLACE VIEW APPS.XXSKY_�x���w�b�__��{_V
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
,�����
,����於
,�����T�C�g
,�����T�C�g��
,�o�׎w��
,�^���Ǝ�
,�^���ƎҖ�
,�z���敪
,�z���敪��
,���i�\
,���i�\��
,�X�e�[�^�X
,�X�e�[�^�X��
,�o�ח\���
,���ח\���
,�^���敪
,�^���敪��
,�x���o�Ɏw���敪
,�x���o�Ɏw���敪��
,�x���w����̋敪
,�x���w����̋敪��
,�L�����z�m��敪
,�L�����z�m��敪��
,����敪
,����敪��
,�o�׌��ۊǏꏊ
,�o�׌��ۊǏꏊ��
,���͋��_
,���͋��_��
,���͋��_����
,����NO
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
,�����i��
,�����i�ږ�
,������
,�����}��
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
,�o�ד�
,�o�ד�_�\��
,���ד�
,���ד�_�\��
-- 2019/09/04 E_�{�ғ�_15601 H.Sasaki Added START
,�L���x���N��_�ԕi
-- 2019/09/04 E_�{�ғ�_15601 H.Sasaki Added END
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
,���ڋL��
,��ʍX�V����
,��ʍX�V��
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
       ,XOHA.vendor_code                 --�����
       ,XV2V.vendor_name                 --����於
       ,XOHA.vendor_site_code            --�����T�C�g
       ,XVS2V.vendor_site_name           --�����T�C�g��
       ,XOHA.shipping_instructions       --�o�׎w��
       ,XOHA.freight_carrier_code        --�^���Ǝ�
       ,XC2V01.party_name                --�^���ƎҖ�
       ,XOHA.shipping_method_code        --�z���敪
       ,FLV01.meaning                    --�z���敪��
       ,XOHA.price_list_id               --���i�\
       ,QLHT.name                        --���i�\��
       ,XOHA.req_status                  --�X�e�[�^�X
       ,FLV02.meaning                    --�X�e�[�^�X��
       ,XOHA.schedule_ship_date          --�o�ח\���
       ,XOHA.schedule_arrival_date       --���ח\���
       ,XOHA.freight_charge_class        --�^���敪
       ,FLV03.meaning                    --�^���敪��
       ,XOHA.shikyu_instruction_class    --�x���o�Ɏw���敪
       ,FLV04.meaning                    --�x���o�Ɏw���敪��
       ,XOHA.shikyu_inst_rcv_class       --�x���w����̋敪
       ,FLV05.meaning                    --�x���w����̋敪��
       ,XOHA.amount_fix_class            --�L�����z�m��敪
       ,FLV06.meaning                    --�L�����z�m��敪��
       ,XOHA.takeback_class              --����敪
       ,FLV07.meaning                    --����敪��
       ,XOHA.deliver_from                --�o�׌��ۊǏꏊ
       ,XIL2V.description                --�o�׌��ۊǏꏊ��
       ,XOHA.input_sales_branch          --���͋��_
       ,XCA2V02.party_name               --���͋��_��
       ,XCA2V02.party_short_name         --���͋��_����
       ,XOHA.po_no                       --����No
       ,XOHA.prod_class                  --���i�敪
       ,FLV08.meaning                    --���i�敪��
       ,XOHA.item_class                  --�i�ڋ敪
       ,FLV09.meaning                    --�i�ڋ敪��
       ,XOHA.no_cont_freight_class       --�_��O�^���敪
       ,FLV10.meaning                    --�_��O�^���敪��
       ,XOHA.arrival_time_from           --���׎���FROM
       ,FLV11.meaning                    --���׎���FROM��
       ,XOHA.arrival_time_to             --���׎���TO
       ,FLV12.meaning                    --���׎���TO��
       ,XOHA.designated_item_code        --�����i��
       ,XIM2V.item_name                  --�����i�ږ�
       ,XOHA.designated_production_date  --������
       ,XOHA.designated_branch_no        --�����}��
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
-- 2010/1/8 #627 Y.Fukami Mod Start
--       ,CEIL( XOHA.sum_weight )
       ,CEIL(TRUNC(NVL(XOHA.sum_weight,0),1))     --�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ
-- 2010/1/8 #627 Y.Fukami Mod Start
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
       ,FLV13.meaning                    --�z���敪_���і�
       ,CASE WHEN XOHA.result_shipping_method_code IS NULL THEN FLV01.meaning     --�z���敪_���т����݂��Ȃ��ꍇ�͔z���敪��
             ELSE                                               FLV10.meaning     --�z���敪_���т����݂���ꍇ�͔z���敪_���і�
        END                              --�z���敪_�\����
       ,XOHA.shipped_date                --�o�ד�
       ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date )                         --NVL( �o�ד�, �o�ח\��� )
                                         --�o�ד�_�\��
       ,XOHA.arrival_date                --���ד�
       ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )                      --NVL( ���ד�, ���ח\��� )
                                         --���ד�_�\��
-- 2019/09/04 E_�{�ғ�_15601 H.Sasaki Added START
      , TO_CHAR( xoha.sikyu_return_date, 'YYYY/MM' )                              -- �L���x���N��(�ԕi)
-- 2019/09/04 E_�{�ғ�_15601 H.Sasaki Added END
       ,XOHA.weight_capacity_class       --�d�ʗe�ϋ敪
       ,FLV14.meaning                    --�d�ʗe�ϋ敪��
       ,XOHA.actual_confirm_class        --���ьv��ϋ敪
       ,XOHA.notif_status                --�ʒm�X�e�[�^�X
       ,FLV15.meaning                    --�ʒm�X�e�[�^�X��
       ,XOHA.prev_notif_status           --�O��ʒm�X�e�[�^�X
       ,FLV16.meaning                    --�O��ʒm�X�e�[�^�X��
       ,TO_CHAR( XOHA.notif_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --�m��ʒm���{����
       ,XOHA.new_modify_flg              --�V�K�C���t���O
       ,FLV17.meaning                    --�V�K�C���t���O��
       ,XOHA.performance_management_dept --���ъǗ�����
       ,XL2V01.location_name             --���ъǗ�������
       ,XOHA.instruction_dept            --�w������
       ,XL2V02.location_name             --�w��������
       ,XOHA.mixed_sign                  --���ڋL��
       ,TO_CHAR( XOHA.screen_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                         --��ʍX�V����
       ,FU.user_name                     --��ʍX�V��
       ,XCS.transaction_type             --�z��_�������
       ,FLV18.meaning                    --�z��_������ʖ�
       ,XCS.mixed_type                   --�z��_���ڎ��
       ,DECODE(XCS.mixed_type, '1', '�W��', '2', '����')
        mixed_type_name                  --�z��_���ڎ�ʖ�
       ,XCS.deliver_to_code_class        --�z��_�z����R�[�h�敪
       ,FLV19.meaning                    --�z��_�z����R�[�h�敪��
       ,XCS.auto_process_type            --�z��_�����z�ԑΏۋ敪
       ,FLV20.meaning                    --�z��_�����z�ԑΏۋ敪��
       ,XCS.description                  --�z��_�E�v
       ,XCS.payment_freight_flag         --�z��_�x���^���v�Z�Ώۃt���O
       ,DECODE(XCS.payment_freight_flag, '0', '�ΏۊO', '1', '�Ώ�')
        payment_freight_flag_name        --�z��_�x���^���v�Z�Ώۃt���O��
       ,XCS.demand_freight_flag          --�z��_�����^���v�Z�Ώۃt���O
       ,DECODE(XCS.demand_freight_flag, '0', '�ΏۊO', '1', '�Ώ�')
        demand_freight_flag_name         --�z��_�����^���v�Z�Ώۃt���O��
-- 2010/1/8 #627 Y.Fukami Mod Start
--       ,CEIL( XCS.sum_loading_weight )
       ,CEIL( TRUNC(NVL(XCS.sum_loading_weight,0),1) )     --�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ
-- 2010/1/8 #627 Y.Fukami Mod End
        sum_loading_weight               --�z��_�ύڏd�ʍ��v
       ,CEIL( XCS.sum_loading_capacity )
        sum_loading_capacity             --�z��_�ύڗe�ύ��v
       ,CEIL( XCS.loading_efficiency_weight * 100 ) / 100  --�����_��R�ȉ��؂�グ
        loading_efficiency_weight        --�z��_�d�ʐύڌ���
       ,CEIL( XCS.loading_efficiency_capacity * 100 ) / 100  --�����_��R�ȉ��؂�グ
        loading_efficiency_capacity      --�z��_�e�ϐύڌ���
       ,XCS.freight_charge_type          --�z��_�^���`��
       ,FLV21.meaning                    --�z��_�^���`�Ԗ�
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
       ,xxsky_vendors2_v             XV2V    --�d������VIEW2(����於)
       ,xxsky_vendor_sites2_v        XVS2V   --�d����T�C�g���VIEW2(�d����T�C�g��)
       ,xxsky_carriers2_v            XC2V01  --�^���Ǝҏ��VIEW2(�^���ƎҖ�)
       ,qp_list_headers_tl           QLHT    --���i�\
       ,xxsky_item_locations2_v      XIL2V   --OPM�ۊǏꏊ���VIEW2(�o�׌��ۊǏꏊ��)
       ,xxsky_cust_accounts2_v       XCA2V02 --SKYLINK�p����VIEW �ڋq���VIEW2(���͋��_)
       ,xxsky_item_mst2_v            XIM2V   --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�����i�ږ�)
       ,xxsky_carriers2_v            XC2V02  --�^���Ǝҏ��VIEW2(�^���ƎҖ�)
       ,xxsky_locations2_v           XL2V01  --SKYLINK�p����VIEW ���Ə����VIEW2(���ъǗ�������)
       ,xxsky_locations2_v           XL2V02  --SKYLINK�p����VIEW ���Ə����VIEW2(�w��������)
       ,fnd_user                     FU      --���[�U�[�}�X�^(��ʍX�V��)
       ,fnd_user                     FU_CB   --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                     FU_LU   --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                     FU_LL   --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                   FL_LL   --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_lookup_values            FLV01   --�N�C�b�N�R�[�h(�z���敪��)
       ,fnd_lookup_values            FLV02   --�N�C�b�N�R�[�h(�X�e�[�^�X��)
       ,fnd_lookup_values            FLV03   --�N�C�b�N�R�[�h(�^���敪��)
       ,fnd_lookup_values            FLV04   --�N�C�b�N�R�[�h(�x���o�Ɏw���敪��)
       ,fnd_lookup_values            FLV05   --�N�C�b�N�R�[�h(�x���w����̋敪��)
       ,fnd_lookup_values            FLV06   --�N�C�b�N�R�[�h(�L�����z�m��敪��)
       ,fnd_lookup_values            FLV07   --�N�C�b�N�R�[�h(����敪��)
       ,fnd_lookup_values            FLV08   --�N�C�b�N�R�[�h(���i�敪��)
       ,fnd_lookup_values            FLV09   --�N�C�b�N�R�[�h(�i�ڋ敪��)
       ,fnd_lookup_values            FLV10   --�N�C�b�N�R�[�h(�_��O�^���敪��)
       ,fnd_lookup_values            FLV11   --�N�C�b�N�R�[�h(���׎���FROM��)
       ,fnd_lookup_values            FLV12   --�N�C�b�N�R�[�h(���׎���TO��)
       ,fnd_lookup_values            FLV13   --�N�C�b�N�R�[�h(�z���敪_���і�)
       ,fnd_lookup_values            FLV14   --�N�C�b�N�R�[�h(�d�ʗe�ϋ敪��)
       ,fnd_lookup_values            FLV15   --�N�C�b�N�R�[�h(�ʒm�X�e�[�^�X��)
       ,fnd_lookup_values            FLV16   --�N�C�b�N�R�[�h(�O��ʒm�X�e�[�^�X��)
       ,fnd_lookup_values            FLV17   --�N�C�b�N�R�[�h(�V�K�C���t���O��)
       ,fnd_lookup_values            FLV18   --�N�C�b�N�R�[�h(�z��_������ʖ�)
       ,fnd_lookup_values            FLV19   --�N�C�b�N�R�[�h(�z��_�z����R�[�h�敪��)
       ,fnd_lookup_values            FLV20   --�N�C�b�N�R�[�h(�z��_�����z�ԑΏۋ敪��)
       ,fnd_lookup_values            FLV21   --�N�C�b�N�R�[�h(�z��_�^���`�Ԗ�)
 WHERE
   --�x�����擾
        OTTA.attribute1 = '2'            -- �x��
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
   --����於�擾
   AND  XOHA.vendor_id = XV2V.vendor_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XV2V.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XV2V.end_date_active(+)
   --�����T�C�g���擾
   AND  XOHA.vendor_site_id = XVS2V.vendor_site_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XVS2V.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XVS2V.end_date_active(+)
   --�^���ƎҖ��擾
   AND  XOHA.career_id = XC2V01.party_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XC2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XC2V01.end_date_active(+)
   --���i�\���擾
   AND  QLHT.LANGUAGE(+) = 'JA'
   AND  XOHA.price_list_id = QLHT.LIST_HEADER_ID(+)
   --�o�׌��ۊǏꏊ���擾
   AND  XOHA.deliver_from_id = XIL2V.inventory_location_id(+)
   --���͋��_���擾
   AND  XOHA.input_sales_branch = XCA2V02.party_number(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XCA2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XCA2V02.end_date_active(+)
   --�����i�ڏ��擾
-- 2009/03/30 H.Iida MOD START �{�ԏ�Q#1344
--   AND  XOHA.designated_item_id = XIM2V.item_id(+)
   AND  XOHA.designated_item_code = XIM2V.item_no(+)
-- 2009/03/30 H.Iida MOD END
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XIM2V.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XIM2V.end_date_active(+)
   --�^���Ǝ�_���і��擾
   AND  XOHA.result_freight_carrier_id = XC2V02.party_id(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XC2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XC2V02.end_date_active(+)
   --���ъǗ��������擾
   AND  XOHA.performance_management_dept = XL2V01.location_code(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XL2V01.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XL2V01.end_date_active(+)
   --�w���������擾
   AND  XOHA.instruction_dept = XL2V02.location_code(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= XL2V02.start_date_active(+)
   AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= XL2V02.end_date_active(+)
   --��ʍX�V�Җ��擾
   AND  XOHA.screen_update_by  = FU.user_id(+)
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
   AND  FLV02.lookup_type(+) = 'XXPO_TRANSACTION_STATUS'
   AND  FLV02.lookup_code(+) = XOHA.req_status
   --�y�N�C�b�N�R�[�h�z�^���敪��
   AND  FLV03.language(+) = 'JA'
   AND  FLV03.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV03.lookup_code(+) = XOHA.freight_charge_class
   --�y�N�C�b�N�R�[�h�z�x���o�Ɏw���敪��
   AND  FLV04.language(+) = 'JA'
   AND  FLV04.lookup_type(+) = 'XXWSH_SHIKYU_INSTRUCTION_CLASS'
   AND  FLV04.lookup_code(+) = XOHA.shikyu_instruction_class
   --�y�N�C�b�N�R�[�h�z�x���w����̋敪��
   AND  FLV05.language(+) = 'JA'
   AND  FLV05.lookup_type(+) = 'XXWSH_SHIKYU_INST_RCV_CLASS'
   AND  FLV05.lookup_code(+) = XOHA.shikyu_inst_rcv_class
   --�y�N�C�b�N�R�[�h�z�L�����z�m��敪��
   AND  FLV06.language(+) = 'JA'
   AND  FLV06.lookup_type(+) = 'XXWSH_AMOUNT_FIX_CLASS'
   AND  FLV06.lookup_code(+) = XOHA.amount_fix_class
   --�y�N�C�b�N�R�[�h�z����敪��
   AND  FLV07.language(+) = 'JA'
   AND  FLV07.lookup_type(+) = 'XXWSH_TAKEBACK_CLASS'
   AND  FLV07.lookup_code(+) = XOHA.takeback_class
   --�y�N�C�b�N�R�[�h�z���i�敪��
   AND  FLV08.language(+) = 'JA'
   AND  FLV08.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   AND  FLV08.lookup_code(+) = XOHA.prod_class
   --�y�N�C�b�N�R�[�h�z�i�ڋ敪��
   AND  FLV09.language(+) = 'JA'
   AND  FLV09.lookup_type(+) = 'XXWSH_ITEM_DIV'
   AND  FLV09.lookup_code(+) = XOHA.item_class
   --�y�N�C�b�N�R�[�h�z�_��O�^���敪��
   AND  FLV10.language(+) = 'JA'
   AND  FLV10.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV10.lookup_code(+) = XOHA.no_cont_freight_class
   --�y�N�C�b�N�R�[�h�z���׎���FROM��
   AND  FLV11.language(+) = 'JA'
   AND  FLV11.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
   AND  FLV11.lookup_code(+) = XOHA.arrival_time_from
   --�y�N�C�b�N�R�[�h�z���׎���TO��
   AND  FLV12.language(+) = 'JA'
   AND  FLV12.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
   AND  FLV12.lookup_code(+) = XOHA.arrival_time_to
   --�y�N�C�b�N�R�[�h�z�z���敪_���і�
   AND  FLV13.language(+) = 'JA'
   AND  FLV13.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV13.lookup_code(+) = XOHA.result_shipping_method_code
   --�y�N�C�b�N�R�[�h�z�d�ʗe�ϋ敪��
   AND  FLV14.language(+) = 'JA'
   AND  FLV14.lookup_type(+) = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV14.lookup_code(+) = XOHA.weight_capacity_class
   --�y�N�C�b�N�R�[�h�z�ʒm�X�e�[�^�X��
   AND  FLV15.language(+) = 'JA'
   AND  FLV15.lookup_type(+) = 'XXWSH_NOTIF_STATUS'
   AND  FLV15.lookup_code(+) = XOHA.notif_status
   --�y�N�C�b�N�R�[�h�z�O��ʒm�X�e�[�^�X��
   AND  FLV16.language(+) = 'JA'
   AND  FLV16.lookup_type(+) = 'XXWSH_NOTIF_STATUS'
   AND  FLV16.lookup_code(+) = XOHA.prev_notif_status
   --�y�N�C�b�N�R�[�h�z�V�K�C���t���O��
   AND  FLV17.language(+) = 'JA'
   AND  FLV17.lookup_type(+) = 'XXWSH_NEW_MODIFY_FLG'
   AND  FLV17.lookup_code(+) = XOHA.new_modify_flg
   --�y�N�C�b�N�R�[�h�z�z��_������ʖ�
   AND  FLV18.language(+) = 'JA'
   AND  FLV18.lookup_type(+) = 'XXWSH_PROCESS_TYPE'
   AND  FLV18.lookup_code(+) = XCS.transaction_type
   --�y�N�C�b�N�R�[�h�z�z��_�z����R�[�h�敪��
   AND  FLV19.language(+) = 'JA'
   AND  FLV19.lookup_type(+) = 'CUSTOMER CLASS'
   AND  FLV19.lookup_code(+) = XCS.deliver_to_code_class
   --�y�N�C�b�N�R�[�h�z�z��_�����z�ԑΏۋ敪��
   AND  FLV20.language(+) = 'JA'
   AND  FLV20.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV20.lookup_code(+) = XCS.auto_process_type
   --�y�N�C�b�N�R�[�h�z�z��_�^���`��
   AND  FLV21.language(+) = 'JA'
   AND  FLV21.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV21.lookup_code(+) = XCS.freight_charge_type
/
COMMENT ON TABLE APPS.XXSKY_�x���w�b�__��{_V IS 'SKYLINK�p�x���w�b�_�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�˗�NO IS '�˗�No'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��NO IS '�z��No'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�󒍃^�C�v�� IS '�󒍃^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�g�D�� IS '�g�D��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�󒍓� IS '�󒍓�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�ŐV�t���O IS '�ŐV�t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���˗�NO IS '���˗�No'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�O��z��NO IS '�O��z��No'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�ڋq IS '�ڋq'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�ڋq�� IS '�ڋq��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.����� IS '�����'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.����於 IS '����於'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�����T�C�g IS '�����T�C�g'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�����T�C�g�� IS '�����T�C�g��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�o�׎w�� IS '�o�׎w��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�^���Ǝ� IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�^���ƎҖ� IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z���敪 IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z���敪�� IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���i�\ IS '���i�\'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���i�\�� IS '���i�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�X�e�[�^�X IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�X�e�[�^�X�� IS '�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�o�ח\��� IS '�o�ח\���'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���ח\��� IS '���ח\���'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�^���敪 IS '�^���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�^���敪�� IS '�^���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�x���o�Ɏw���敪 IS '�x���o�Ɏw���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�x���o�Ɏw���敪�� IS '�x���o�Ɏw���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�x���w����̋敪 IS '�x���w����̋敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�x���w����̋敪�� IS '�x���w����̋敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�L�����z�m��敪 IS '�L�����z�m��敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�L�����z�m��敪�� IS '�L�����z�m��敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.����敪 IS '����敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.����敪�� IS '����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�o�׌��ۊǏꏊ IS '�o�׌��ۊǏꏊ'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�o�׌��ۊǏꏊ�� IS '�o�׌��ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���͋��_ IS '���͋��_'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���͋��_�� IS '���͋��_��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���͋��_���� IS '���͋��_����'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.����NO IS '����No'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�_��O�^���敪 IS '�_��O�^���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�_��O�^���敪�� IS '�_��O�^���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���׎���FROM IS '���׎���FROM'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���׎���FROM�� IS '���׎���FROM��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���׎���TO IS '���׎���TO'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���׎���TO�� IS '���׎���TO��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�����i�� IS '�����i��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�����i�ږ� IS '�����i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�����}�� IS '�����}��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�����NO IS '�����No'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���v���� IS '���v����'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���x������ IS '���x������'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�d�ʐύڌ��� IS '�d�ʐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�e�ϐύڌ��� IS '�e�ϐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.��{�d�� IS '��{�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.��{�e�� IS '��{�e��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�ύڏd�ʍ��v IS '�ύڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�ύڗe�ύ��v IS '�ύڗe�ύ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���ڗ� IS '���ڗ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�p���b�g���v���� IS '�p���b�g���v����'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�p���b�g���і��� IS '�p���b�g���і���'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���v�p���b�g�d�� IS '���v�p���b�g�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�^���Ǝ�_���� IS '�^���Ǝ�_����'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�^���Ǝ�_�\�� IS '�^���Ǝ�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�^���Ǝ�_���і� IS '�^���Ǝ�_���і�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�^���Ǝ�_�\���� IS '�^���Ǝ�_�\����'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z���敪_���� IS '�z���敪_����'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z���敪_�\�� IS '�z���敪_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z���敪_���і� IS '�z���敪_���і�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z���敪_�\���� IS '�z���敪_�\����'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�o�ד� IS '�o�ד�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�o�ד�_�\�� IS '�o�ד�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���ד� IS '���ד�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���ד�_�\�� IS '���ד�_�\��'
/
-- 2019/09/04 E_�{�ғ�_15601 H.Sasaki Added START
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�L���x���N��_�ԕi IS '�L���x���N��_�ԕi'
/
-- 2019/09/04 E_�{�ғ�_15601 H.Sasaki Added END
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�d�ʗe�ϋ敪 IS '�d�ʗe�ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�d�ʗe�ϋ敪�� IS '�d�ʗe�ϋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���ьv��ϋ敪 IS '���ьv��ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�ʒm�X�e�[�^�X IS '�ʒm�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�ʒm�X�e�[�^�X�� IS '�ʒm�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�O��ʒm�X�e�[�^�X IS '�O��ʒm�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�O��ʒm�X�e�[�^�X�� IS '�O��ʒm�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�m��ʒm���{���� IS '�m��ʒm���{����'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�V�K�C���t���O IS '�V�K�C���t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�V�K�C���t���O�� IS '�V�K�C���t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���ъǗ����� IS '���ъǗ�����'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���ъǗ������� IS '���ъǗ�������'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�w������ IS '�w������'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�w�������� IS '�w��������'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.���ڋL�� IS '���ڋL��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.��ʍX�V���� IS '��ʍX�V����'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.��ʍX�V�� IS '��ʍX�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_������� IS '�z��_�������'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_������ʖ� IS '�z��_������ʖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_���ڎ�� IS '�z��_���ڎ��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_���ڎ�ʖ� IS '�z��_���ڎ�ʖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�z����R�[�h�敪 IS '�z��_�z����R�[�h�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�z����R�[�h�敪�� IS '�z��_�z����R�[�h�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�����z�ԑΏۋ敪 IS '�z��_�����z�ԑΏۋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�����z�ԑΏۋ敪�� IS '�z��_�����z�ԑΏۋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�E�v IS '�z��_�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�x���^���v�Z�Ώۃt���O IS '�z��_�x���^���v�Z�Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�x���^���v�Z�Ώۃt���O�� IS '�z��_�x���^���v�Z�Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�����^���v�Z�Ώۃt���O IS '�z��_�����^���v�Z�Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�����^���v�Z�Ώۃt���O�� IS '�z��_�����^���v�Z�Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�ύڏd�ʍ��v IS '�z��_�ύڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�ύڗe�ύ��v IS '�z��_�ύڗe�ύ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�d�ʐύڌ��� IS '�z��_�d�ʐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�e�ϐύڌ��� IS '�z��_�e�ϐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�^���`�� IS '�z��_�^���`��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�z��_�^���`�Ԗ� IS '�z��_�^���`�Ԗ�'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�x���w�b�__��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
