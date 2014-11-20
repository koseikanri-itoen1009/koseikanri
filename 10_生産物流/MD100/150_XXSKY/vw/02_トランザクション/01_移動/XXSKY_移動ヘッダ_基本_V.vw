CREATE OR REPLACE VIEW APPS.XXSKY_�ړ��w�b�__��{_V
(
 �ړ��ԍ�
,�ړ��^�C�v
,�ړ��^�C�v��
,�z��NO
,���͓�
,�w������
,�w��������
,�X�e�[�^�X
,�X�e�[�^�X��
,�ʒm�X�e�[�^�X
,�ʒm�X�e�[�^�X��
,�o�Ɍ��ۊǏꏊ
,�o�Ɍ��ۊǏꏊ��
,���ɐ�ۊǏꏊ
,���ɐ�ۊǏꏊ��
,�o�ɗ\���
,���ɗ\���
,�^���敪
,�^���敪��
,�p���b�g�������
,�p���b�g����_�o
,�p���b�g����_��
,�_��O�^���敪
,�_��O�^���敪��
,�ړ�_�E�v
,�ύڗ�_�d��
,�ύڗ�_�e��
,�g�D��
,�^���Ǝ�
,�^���ƎҖ�
,�z���敪
,�z���敪��
,�^���Ǝ�_����
,�^���ƎҖ�_����
,�z���敪_����
,�z���敪��_����
,�^���Ǝ�_�\��
,�^���ƎҖ�_�\��
,�z���敪_�\��
,�z���敪��_�\��
,���׎���FROM
,���׎���FROM��
,���׎���TO
,���׎���TO��
,�����NO
,���v����
,������
,���x������
,��{�d��
,��{�e��
,�ύڏd�ʍ��v
,�ύڗe�ύ��v
,���v�p���b�g�d��
,�p���b�g���v����
,���ڗ�
,�d�ʗe�ϋ敪
,�d�ʗe�ϋ敪��
,�o�Ɏ��ѓ�
,�o�ɓ�_�\��
,���Ɏ��ѓ�
,���ɓ�_�\��
,���ڋL��
,��zNo
,���i�敪
,���i�敪��
,���i���ʋ敪
,���i���ʋ敪��
,�w���Ȃ����ы敪
,���ьv��σt���O
,���ьv��σt���O��
,���ђ����t���O
,���ђ����t���O��
,�O��ʒm�X�e�[�^�X
,�O��ʒm�X�e�[�^�X��
,�m��ʒm���{����
,�O��z��NO
,�V�K�C���t���O
,�V�K�C���t���O��
,��ʍX�V��
,��ʍX�V����
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
,�z��_�ύڏd�ʍ��v_�z��
,�z��_�ύڗe�ύ��v_�z��
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
SELECT  XMRIH.mov_num                      --�ړ��ԍ�
       ,XMRIH.mov_type                     --�ړ��^�C�v
       ,FLV01.meaning                      --�ړ��^�C�v��
       ,XMRIH.delivery_no                  --�z��No
       ,XMRIH.entered_date                 --���͓�
       ,XMRIH.instruction_post_code        --�w������
       ,XLV.location_name                  --�w��������
       ,XMRIH.status                       --�X�e�[�^�X
       ,FLV02.meaning                      --�X�e�[�^�X��
       ,XMRIH.notif_status                 --�ʒm�X�e�[�^�X
       ,FLV03.meaning                      --�ʒm�X�e�[�^�X��
       ,XMRIH.shipped_locat_code           --�o�Ɍ��ۊǏꏊ
       ,XILV1.description                  --�o�Ɍ��ۊǏꏊ��
       ,XMRIH.ship_to_locat_code           --���ɐ�ۊǏꏊ
       ,XILV2.description                  --���ɐ�ۊǏꏊ��
       ,XMRIH.schedule_ship_date           --�o�ɗ\���
       ,XMRIH.schedule_arrival_date        --���ɗ\���
       ,XMRIH.freight_charge_class         --�^���敪
       ,FLV04.meaning                      --�^���敪��
       ,XMRIH.collected_pallet_qty         --�p���b�g�������
       ,XMRIH.out_pallet_qty               --�p���b�g����_�o
       ,XMRIH.in_pallet_qty                --�p���b�g����_��
       ,XMRIH.no_cont_freight_class        --�_��O�^���敪
       ,FLV05.meaning                      --�_��O�^���敪��
       ,XMRIH.description                  --�ړ�_�E�v
       ,CEIL( XMRIH.loading_efficiency_weight * 100 ) / 100  --�����_��R�ȉ��؂�グ
        loading_efficiency_weight          --�ύڗ�_�d��
       ,CEIL( XMRIH.loading_efficiency_capacity * 100 ) / 100  --�����_��R�ȉ��؂�グ
        loading_efficiency_capacity        --�ύڗ�_�e��
       ,HAOUT.name                         --�g�D��
       ,XMRIH.freight_carrier_code         --�^���Ǝ�
       ,XCV1.party_name                    --�^���ƎҖ�
       ,XMRIH.shipping_method_code         --�z���敪
       ,FLV06.meaning                      --�z���敪��
       ,XMRIH.actual_freight_carrier_code  --�^���Ǝ�_����
       ,XCV2.party_name                    --�^���ƎҖ�_����
       ,XMRIH.actual_shipping_method_code  --�z���敪_����
       ,FLV07.meaning                      --�z���敪��_����
       ,NVL( XMRIH.actual_freight_carrier_code, XMRIH.freight_carrier_code )      --NVL( �^���Ǝ�_����, �^���Ǝ� )
             yj_freight_carrier_code       --�^���Ǝ�_�\��
       ,CASE WHEN XMRIH.actual_freight_carrier_code IS NULL THEN XCV1.party_name  --�^���Ǝ�_���т����݂��Ȃ��ꍇ�͉^���ƎҖ�
             ELSE                                                XCV2.party_name  --�^���Ǝ�_���т����݂���ꍇ�͉^���ƎҖ�_����
        END  yj_freight_carrier_name       --�^���ƎҖ�_�\��
       ,NVL(  XMRIH.actual_shipping_method_code, XMRIH.shipping_method_code )     --NVL( �z���敪_����, �z���敪 )
                                           --�z���敪_�\��
       ,CASE WHEN XMRIH.actual_shipping_method_code IS NULL THEN FLV06.meaning    --�z���敪_���т����݂��Ȃ��ꍇ�͔z���敪��
             ELSE                                                FLV07.meaning    --�z���敪���т����݂���ꍇ�͔z���敪��_����
        END                                --�z���敪��_�\��
       ,XMRIH.arrival_time_from            --���׎���FROM
       ,FLV08.meaning                      --���׎���FROM��
       ,XMRIH.arrival_time_to              --���׎���TO
       ,FLV09.meaning                      --���׎���TO��
       ,XMRIH.slip_number                  --�����No
       ,XMRIH.sum_quantity                 --���v����
       ,XMRIH.small_quantity               --������
       ,XMRIH.label_quantity               --���x������
       ,CEIL(XMRIH.based_weight)
        based_weight                       --��{�d��
       ,CEIL(XMRIH.based_capacity)
        based_capacity                     --��{�e��
-- 2010/1/7 #627 Y.FUkami Mod Start
--       ,CEIL(XMRIH.sum_weight)
       ,CEIL(TRUNC(NVL(XMRIH.sum_weight,0),1))     --�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ
-- 2010/1/7 #627 Y.FUkami Mod End
        sum_weight                         --�ύڏd�ʍ��v
       ,CEIL(XMRIH.sum_capacity)
        sum_capacity                       --�ύڗe�ύ��v
       ,XMRIH.sum_pallet_weight            --���v�p���b�g�d��
       ,XMRIH.pallet_sum_quantity          --�p���b�g���v����
       ,CEIL( XMRIH.mixed_ratio * 100 ) / 100  --�����_��R�ȉ��؂�グ
        mixed_ratio                        --���ڗ�
       ,XMRIH.weight_capacity_class        --�d�ʗe�ϋ敪
       ,FLV10.meaning                      --�d�ʗe�ϋ敪��
       ,XMRIH.actual_ship_date             --�o�Ɏ��ѓ�
       ,NVL( XMRIH.actual_ship_date, XMRIH.schedule_ship_date )        --NVL( �o�ד�, �o�ח\��� )
             yj_shipped_date               --�o�ɓ�_�\��
       ,XMRIH.actual_arrival_date          --���Ɏ��ѓ�
       ,NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date )  --NVL( ���ד�, ���ח\��� )
             yj_arrival_date               --���ɓ�_�\��
       ,XMRIH.mixed_sign                   --���ڋL��
       ,XMRIH.batch_no                     --��zNo
       ,XMRIH.item_class                   --���i�敪
       ,FLV11.meaning                      --���i�敪��
       ,XMRIH.product_flg                  --���i���ʋ敪
       ,FLV12.meaning                      --���i���ʋ敪��
       ,XMRIH.no_instr_actual_class        --�w���Ȃ����ы敪
       ,XMRIH.comp_actual_flg              --���ьv��σt���O
       ,FLV13.meaning                      --���ьv��σt���O��
       ,XMRIH.correct_actual_flg           --���ђ����t���O
       ,FLV14.meaning                      --���ђ����t���O��
       ,XMRIH.prev_notif_status            --�O��ʒm�X�e�[�^�X
       ,FLV15.meaning                      --�O��ʒm�X�e�[�^�X��
       ,TO_CHAR( XMRIH.notif_date, 'YYYY/MM/DD HH24:MI:SS')
                                           --�m��ʒm���{����
       ,XMRIH.prev_delivery_no             --�O��z��No
       ,XMRIH.new_modify_flg               --�V�K�C���t���O
       ,FLV16.meaning                      --�V�K�C���t���O��
       ,FU_SU.user_name                    --��ʍX�V�҂̃��[�U�[��
       ,TO_CHAR( XMRIH.screen_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                           --��ʍX�V����
       ,XCS.transaction_type               --�z��_�������
       ,FLV17.meaning                      --�z��_������ʖ�
       ,XCS.mixed_type                     --�z��_���ڎ��
       ,DECODE(XCS.mixed_type ,'1','�W��'  ,'2','����')
        mixed_name                         --�z��_���ڎ�ʖ�
       ,XCS.deliver_to_code_class          --�z��_�z����R�[�h�敪
       ,FLV18.meaning                      --�z��_�z����R�[�h�敪��
       ,XCS.auto_process_type              --�z��_�����z�ԑΏۋ敪
       ,FLV19.meaning                      --�z��_�����z�ԑΏۋ敪��
       ,XCS.description                    --�z��_�E�v
       ,XCS.payment_freight_flag           --�z��_�x���^���v�Z�Ώۃt���O
       ,DECODE(XCS.payment_freight_flag ,'1','�Ώ�'  ,'�ΏۊO')
        payment_freight_flg_name           --�z��_�x���^���v�Z�Ώۃt���O��
       ,XCS.demand_freight_flag            --�z��_�����^���v�Z�Ώۃt���O
       ,DECODE(XCS.demand_freight_flag  ,'1','�Ώ�'  ,'�ΏۊO')
        demand_freight_flg_name            --�z��_�����^���v�Z�Ώۃt���O��
-- 2010/1/7 #627 Y.FUkami Mod Start
--       ,CEIL(XCS.sum_loading_weight)
       ,CEIL(TRUNC(NVL(XCS.sum_loading_weight,0),1))     --�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ
-- 2010/1/7 #627 Y.FUkami Mod End
        sum_loading_weight                 --�z��_�ύڏd�ʍ��v_�z��
       ,CEIL(XCS.sum_loading_capacity)
        sum_loading_capacity               --�z��_�ύڗe�ύ��v_�z��
       ,CEIL( XCS.loading_efficiency_weight * 100 ) / 100  --�����_��R�ȉ��؂�グ
        loading_efficiency_weight          --�z��_�d�ʐύڌ���
       ,CEIL( XCS.loading_efficiency_capacity * 100 ) / 100  --�����_��R�ȉ��؂�グ
        loading_efficiency_capacity        --�z��_�e�ϐύڌ���
       ,XCS.freight_charge_type            --�z��_�^���`��
       ,FLV20.meaning                      --�z��_�^���`�Ԗ�
       ,FU_CB.user_name                    --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XMRIH.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                           --�쐬����
       ,FU_LU.user_name                    --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XMRIH.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                           --�X�V����
       ,FU_LL.user_name                    --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  xxinv_mov_req_instr_headers  XMRIH --�ړ��˗�/�w���w�b�_�A�h�I��
       ,xxwsh_carriers_schedule      XCS   --�z�Ԕz���v��A�h�I��
       ,xxsky_locations2_v           XLV   --SKYLINK�p����VIEW ���Ə����VIEW
       ,xxsky_item_locations2_v      XILV1 --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(�o�Ɍ��ۊǏꏊ���擾�p)
       ,xxsky_item_locations2_v      XILV2 --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW(���ɐ�ۊǏꏊ���擾�p)
       ,hr_all_organization_units_tl HAOUT --
       ,xxsky_carriers2_v            XCV1  --SKYLINK�p����VIEW �^���Ǝҏ��VIEW(�^���ƎҖ��擾�p)
       ,xxsky_carriers2_v            XCV2  --SKYLINK�p����VIEW �^���Ǝҏ��VIEW(�^���ƎҖ�_���ю擾�p)
       ,fnd_lookup_values            FLV01 --�N�C�b�N�R�[�h(�ړ��^�C�v��)
       ,fnd_lookup_values            FLV02 --�N�C�b�N�R�[�h(�X�e�[�^�X��)
       ,fnd_lookup_values            FLV03 --�N�C�b�N�R�[�h(�ʒm�X�e�[�^�X��)
       ,fnd_lookup_values            FLV04 --�N�C�b�N�R�[�h(�^���敪��)
       ,fnd_lookup_values            FLV05 --�N�C�b�N�R�[�h(�_��O�^���敪��)
       ,fnd_lookup_values            FLV06 --�N�C�b�N�R�[�h(�z���敪��)
       ,fnd_lookup_values            FLV07 --�N�C�b�N�R�[�h(�z���敪��_����)
       ,fnd_lookup_values            FLV08 --�N�C�b�N�R�[�h(���׎���FROM��)
       ,fnd_lookup_values            FLV09 --�N�C�b�N�R�[�h(���׎���TO��)
       ,fnd_lookup_values            FLV10 --�N�C�b�N�R�[�h(�d�ʗe�ϋ敪��)
       ,fnd_lookup_values            FLV11 --�N�C�b�N�R�[�h(���i�敪��)
       ,fnd_lookup_values            FLV12 --�N�C�b�N�R�[�h(���i���ʋ敪��)
       ,fnd_lookup_values            FLV13 --�N�C�b�N�R�[�h(���ьv��σt���O��)
       ,fnd_lookup_values            FLV14 --�N�C�b�N�R�[�h(���ђ����t���O��)
       ,fnd_lookup_values            FLV15 --�N�C�b�N�R�[�h(�O��ʒm�X�e�[�^�X��)
       ,fnd_lookup_values            FLV16 --�N�C�b�N�R�[�h(�V�K�C���t���O��)
       ,fnd_lookup_values            FLV17 --�N�C�b�N�R�[�h(�z��_������ʖ�)
       ,fnd_lookup_values            FLV18 --�N�C�b�N�R�[�h(�z��_�z����R�[�h�敪��)
       ,fnd_lookup_values            FLV19 --�N�C�b�N�R�[�h(�z��_�����z�ԑΏۋ敪��)
       ,fnd_lookup_values            FLV20 --�N�C�b�N�R�[�h(�z��_�^���`�Ԗ�)
       ,fnd_user                     FU_SU --���[�U�[�}�X�^(��ʍX�V�Җ��擾�p)
       ,fnd_user                     FU_CB --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                     FU_LU --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                     FU_LL --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                   FL_LL --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE  XMRIH.delivery_no = XCS.delivery_no(+)
   --�w���������擾
   AND  XMRIH.instruction_post_code        = XLV.location_code(+)
   AND  NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date ) >= XLV.start_date_active(+)
   AND  NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date ) <= XLV.end_date_active(+)
   --�o�Ɍ��ۊǏꏊ���擾
   AND  XMRIH.shipped_locat_id             = XILV1.inventory_location_id(+)
   --���ɐ�ۊǏꏊ���擾
   AND  XMRIH.ship_to_locat_id             = XILV2.inventory_location_id(+)
   --�g�D���擾
   AND  XMRIH.organization_id              = HAOUT.organization_id(+)
   AND  HAOUT.language(+)                  = 'JA'
   --�^���ƎҖ��擾
   AND  XMRIH.freight_carrier_code         = XCV1.freight_code(+)
   AND  NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date ) >= XCV1.start_date_active(+)
   AND  NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date ) <= XCV1.end_date_active(+)
   --�^���ƎҖ�_���ю擾
   AND  XMRIH.actual_freight_carrier_code  = XCV2.freight_code(+)
   AND  NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date ) >= XCV2.start_date_active(+)
   AND  NVL( XMRIH.actual_arrival_date, XMRIH.schedule_arrival_date ) <= XCV2.end_date_active(+)
   --�N�C�b�N�R�[�h�F�ړ��^�C�v���擾
   AND  FLV01.language(+) = 'JA'
   AND  FLV01.lookup_type(+) = 'XXINV_MOVE_TYPE'
   AND  FLV01.lookup_code(+) = XMRIH.mov_type
   --�N�C�b�N�R�[�h�F�X�e�[�^�X���擾
   AND  FLV02.language(+) = 'JA'
   AND  FLV02.lookup_type(+) = 'XXINV_MOVE_STATUS'
   AND  FLV02.lookup_code(+) = XMRIH.status
   --�N�C�b�N�R�[�h�F�ʒm�X�e�[�^�X���擾
   AND  FLV03.language(+) = 'JA'
   AND  FLV03.lookup_type(+) = 'XXWSH_NOTIF_STATUS'
   AND  FLV03.lookup_code(+) = XMRIH.notif_status
   --�N�C�b�N�R�[�h�F�^���敪���擾
   AND  FLV04.language(+) = 'JA'
   AND  FLV04.lookup_type(+) = 'XXINV_PRESENCE_CLASS'
   AND  FLV04.lookup_code(+) = XMRIH.freight_charge_class
   --�N�C�b�N�R�[�h�F�_��O�^���敪���擾
   AND  FLV05.language(+) = 'JA'
   AND  FLV05.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV05.lookup_code(+) = XMRIH.no_cont_freight_class
   --�N�C�b�N�R�[�h�F�z���敪���擾
   AND  FLV06.language(+) = 'JA'
   AND  FLV06.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV06.lookup_code(+) = XMRIH.shipping_method_code
   --�N�C�b�N�R�[�h�F�z���敪��_���ю擾
   AND  FLV07.language(+) = 'JA'
   AND  FLV07.lookup_type(+) = 'XXCMN_SHIP_METHOD'
   AND  FLV07.lookup_code(+) = XMRIH.actual_shipping_method_code
   --�N�C�b�N�R�[�h�F���׎���FROM���擾
   AND  FLV08.language(+) = 'JA'
   AND  FLV08.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
   AND  FLV08.lookup_code(+) = XMRIH.arrival_time_from
   --�N�C�b�N�R�[�h�F���׎���TO���擾
   AND  FLV09.language(+) = 'JA'
   AND  FLV09.lookup_type(+) = 'XXWSH_ARRIVAL_TIME'
   AND  FLV09.lookup_code(+) = XMRIH.arrival_time_to
   --�N�C�b�N�R�[�h�F�d�ʗe�ϋ敪���擾
   AND  FLV10.language(+) = 'JA'
   AND  FLV10.lookup_type(+) = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV10.lookup_code(+) = XMRIH.weight_capacity_class
   --�N�C�b�N�R�[�h�F���i�敪���擾
   AND  FLV11.language(+) = 'JA'
   AND  FLV11.lookup_type(+) = 'XXWIP_ITEM_TYPE'
   AND  FLV11.lookup_code(+) = XMRIH.item_class
   --�N�C�b�N�R�[�h�F���i���ʋ敪���擾
   AND  FLV12.language(+) = 'JA'
   AND  FLV12.lookup_type(+) = 'XXINV_PRODUCT_CLASS'
   AND  FLV12.lookup_code(+) = XMRIH.product_flg
   --�N�C�b�N�R�[�h�F���ьv��σt���O���擾
   AND  FLV13.language(+) = 'JA'
   AND  FLV13.lookup_type(+) = 'XXCMN_YESNO'
   AND  FLV13.lookup_code(+) = XMRIH.comp_actual_flg
   --�N�C�b�N�R�[�h�F���ђ����t���O���擾
   AND  FLV14.language(+) = 'JA'
   AND  FLV14.lookup_type(+) = 'XXCMN_YESNO'
   AND  FLV14.lookup_code(+) = XMRIH.correct_actual_flg
   --�N�C�b�N�R�[�h�F�O��ʒm�X�e�[�^�X���擾
   AND  FLV15.language(+) = 'JA'
   AND  FLV15.lookup_type(+) = 'XXWSH_NOTIF_STATUS'
   AND  FLV15.lookup_code(+) = XMRIH.prev_notif_status
   --�N�C�b�N�R�[�h�F�V�K�C���t���O���擾
   AND  FLV16.language(+) = 'JA'
   AND  FLV16.lookup_type(+) = 'XXWSH_NEW_MODIFY_FLG'
   AND  FLV16.lookup_code(+) = XMRIH.new_modify_flg
   --�N�C�b�N�R�[�h�F�z��_������ʖ��擾
   AND  FLV17.language(+) = 'JA'
   AND  FLV17.lookup_type(+) = 'XXWSH_PROCESS_TYPE'
   AND  FLV17.lookup_code(+) = XCS.transaction_type
   --�N�C�b�N�R�[�h�F�z��_�z����R�[�h�敪���擾
   AND  FLV18.language(+) = 'JA'
   AND  FLV18.lookup_type(+) = 'CUSTOMER CLASS'
   AND  FLV18.lookup_code(+) = XCS.deliver_to_code_class
   --�N�C�b�N�R�[�h�F�z��_�����z�ԑΏۋ敪���擾
   AND  FLV19.language(+) = 'JA'
   AND  FLV19.lookup_type(+) = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV19.lookup_code(+) = XCS.auto_process_type
   --�N�C�b�N�R�[�h�F�z��_�^���`�Ԗ��擾
   AND  FLV20.language(+) = 'JA'
   AND  FLV20.lookup_type(+) = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV20.lookup_code(+) = XCS.freight_charge_type
   --��ʍX�V�Җ��擾
   AND  XMRIH.screen_update_by = FU_SU.user_id(+)
   --WHO�J�����擾
   AND  XMRIH.created_by = FU_CB.user_id(+)
   AND  XMRIH.last_updated_by = FU_LU.user_id(+)
   AND  XMRIH.last_update_login = FL_LL.login_id(+)
   AND  FL_LL.user_id = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKY_�ړ��w�b�__��{_V IS 'SKYLINK�p�ړ��w�b�_�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ړ��ԍ�                       IS '�ړ��ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ړ��^�C�v                     IS '�ړ��^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ړ��^�C�v��                   IS '�ړ��^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��NO                         IS '�z��No'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���͓�                         IS '���͓�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�w������                       IS '�w������'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�w��������                     IS '�w��������'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�X�e�[�^�X                     IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�X�e�[�^�X��                   IS '�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ʒm�X�e�[�^�X                 IS '�ʒm�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ʒm�X�e�[�^�X��               IS '�ʒm�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�o�Ɍ��ۊǏꏊ                 IS '�o�Ɍ��ۊǏꏊ'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�o�Ɍ��ۊǏꏊ��               IS '�o�Ɍ��ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���ɐ�ۊǏꏊ                 IS '���ɐ�ۊǏꏊ'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���ɐ�ۊǏꏊ��               IS '���ɐ�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�o�ɗ\���                     IS '�o�ɗ\���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���ɗ\���                     IS '���ɗ\���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�^���敪                       IS '�^���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�^���敪��                     IS '�^���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�p���b�g�������               IS '�p���b�g�������'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�p���b�g����_�o                IS '�p���b�g����_�o'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�p���b�g����_��                IS '�p���b�g����_��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�_��O�^���敪                 IS '�_��O�^���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�_��O�^���敪��               IS '�_��O�^���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ړ�_�E�v                      IS '�ړ�_�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ύڗ�_�d��                    IS '�ύڗ�_�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ύڗ�_�e��                    IS '�ύڗ�_�e��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�g�D��                         IS '�g�D��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�^���Ǝ�                       IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�^���ƎҖ�                     IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z���敪                       IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z���敪��                     IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�^���Ǝ�_����                  IS '�^���Ǝ�_����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�^���ƎҖ�_����                IS '�^���ƎҖ�_����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z���敪_����                  IS '�z���敪_����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z���敪��_����                IS '�z���敪��_����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�^���Ǝ�_�\��                  IS '�^���Ǝ�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�^���ƎҖ�_�\��                IS '�^���ƎҖ�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z���敪_�\��                  IS '�z���敪_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z���敪��_�\��                IS '�z���敪��_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���׎���FROM                   IS '���׎���FROM'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���׎���FROM��                 IS '���׎���FROM��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���׎���TO                     IS '���׎���TO'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���׎���TO��                   IS '���׎���TO��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�����NO                       IS '�����No'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���v����                       IS '���v����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.������                       IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���x������                     IS '���x������'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.��{�d��                       IS '��{�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.��{�e��                       IS '��{�e��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ύڏd�ʍ��v                   IS '�ύڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ύڗe�ύ��v                   IS '�ύڗe�ύ��v'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���v�p���b�g�d��               IS '���v�p���b�g�d��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�p���b�g���v����               IS '�p���b�g���v����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���ڗ�                         IS '���ڗ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�d�ʗe�ϋ敪                   IS '�d�ʗe�ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�d�ʗe�ϋ敪��                 IS '�d�ʗe�ϋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�o�Ɏ��ѓ�                     IS '�o�Ɏ��ѓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�o�ɓ�_�\��                    IS '�o�ɓ�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���Ɏ��ѓ�                     IS '���Ɏ��ѓ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���ɓ�_�\��                    IS '���ɓ�_�\��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���ڋL��                       IS '���ڋL��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.��zNO                         IS '��zNo'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���i�敪                       IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���i�敪��                     IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���i���ʋ敪                   IS '���i���ʋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���i���ʋ敪��                 IS '���i���ʋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�w���Ȃ����ы敪               IS '�w���Ȃ����ы敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���ьv��σt���O               IS '���ьv��σt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���ьv��σt���O��             IS '���ьv��σt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���ђ����t���O                 IS '���ђ����t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.���ђ����t���O��               IS '���ђ����t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�O��ʒm�X�e�[�^�X             IS '�O��ʒm�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�O��ʒm�X�e�[�^�X��           IS '�O��ʒm�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�m��ʒm���{����               IS '�m��ʒm���{����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�O��z��No                     IS '�O��z��No'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�V�K�C���t���O                 IS '�V�K�C���t���O'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�V�K�C���t���O��               IS '�V�K�C���t���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.��ʍX�V��                     IS '��ʍX�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.��ʍX�V����                   IS '��ʍX�V����'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�������                  IS '�z��_�������'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_������ʖ�                IS '�z��_������ʖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_���ڎ��                  IS '�z��_���ڎ��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_���ڎ�ʖ�                IS '�z��_���ڎ�ʖ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�z����R�[�h�敪          IS '�z��_�z����R�[�h�敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�z����R�[�h�敪��        IS '�z��_�z����R�[�h�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�����z�ԑΏۋ敪          IS '�z��_�����z�ԑΏۋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�����z�ԑΏۋ敪��        IS '�z��_�����z�ԑΏۋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�E�v                      IS '�z��_�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�x���^���v�Z�Ώۃt���O    IS '�z��_�x���^���v�Z�Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�x���^���v�Z�Ώۃt���O��  IS '�z��_�x���^���v�Z�Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�����^���v�Z�Ώۃt���O    IS '�z��_�����^���v�Z�Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�����^���v�Z�Ώۃt���O��  IS '�z��_�����^���v�Z�Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�ύڏd�ʍ��v_�z��         IS '�z��_�ύڏd�ʍ��v_�z��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�ύڗe�ύ��v_�z��         IS '�z��_�ύڗe�ύ��v_�z��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�d�ʐύڌ���              IS '�z��_�d�ʐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�e�ϐύڌ���              IS '�z��_�e�ϐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�^���`��                  IS '�z��_�^���`��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�z��_�^���`�Ԗ�                IS '�z��_�^���`�Ԗ�'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�쐬��                         IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ŏI�X�V��                     IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_�ړ��w�b�__��{_V.�ŏI�X�V���O�C��               IS '�ŏI�X�V���O�C��'
/
