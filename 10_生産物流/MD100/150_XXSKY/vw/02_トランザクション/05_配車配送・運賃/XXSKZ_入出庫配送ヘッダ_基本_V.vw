/*************************************************************************
 * 
 * View  Name      : XXSKZ_���o�ɔz���w�b�__��{_V
 * Description     : XXSKZ_���o�ɔz���w�b�__��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_���o�ɔz���w�b�__��{_V
(
 �˗�_�ړ�NO
,�z��NO
,�^�C�v
,�ړ��^�C�v
,�ړ��^�C�v��
,�g�D��
,��_���͓�
,�ŐV�t���O
,���˗�NO
,�O��z��NO
,�ڋq
,�ڋq��
,�o��_���ɐ�
,�o��_���ɐ於
,�o�׎w��
,�����
,����於
,�����T�C�g
,�����T�C�g��
,�^���Ǝ�
,�^���ƎҖ�
,�z���敪
,�z���敪��
,�ڋq����
,���i�\
,���i�\��
,�X�e�[�^�X
,�X�e�[�^�X��
,�o��_�o�ɗ\���
,����_���ɗ\���
,���ڌ�NO
,�p���b�g�������
,�p���b�g����_�o
,�p���b�g����_��
,�ړ�_�E�v
,�����S���m�F�˗��敪
,�����S���m�F�˗��敪��
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
,�o��_�o�Ɍ��ۊǏꏊ
,�o��_�o�Ɍ��ۊǏꏊ��
,�Ǌ����_
,�Ǌ����_��
,�Ǌ����_����
,���͋��_
,���͋��_��
,���͋��_����
,����NO
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,���i���ʋ敪
,���i���ʋ敪��
,�w���Ȃ����ы敪
,�_��O�^���敪
,�_��O�^���敪��
,���׎���FROM
,���׎���FROM��
,���׎���TO
,���׎���TO��
,�����i��
,�����i�ږ�
,�����i�ڗ���
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
,�o�א�_����
,�o�א�_�\��
,�o�א�_���і�
,�o�א�_�\����
,�o��_�o�ɓ�
,�o��_�o�ɓ�_�\��
,����_���ɓ�
,����_���ɓ�_�\��
,�d�ʗe�ϋ敪
,�d�ʗe�ϋ敪��
,���ьv��ϋ敪
,���ђ����t���O
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
,��zNO
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
        SPMH.request_no                                     request_no                    --�˗�_�ړ�No
       ,SPMH.delivery_no                                    delivery_no                   --�z��No
       ,SPMH.type                                           type                          --�^�C�v
       ,SPMH.mov_type                                       mov_type                      --�ړ��^�C�v
       ,SPMH.mov_type_name                                  mov_type_name                 --�ړ��^�C�v��
       ,HAOUT.name                                          org_name                      --�g�D��
       ,SPMH.ordered_date                                   ordered_date                  --�󒍓��͓�
       ,SPMH.latest_external_flag                           latest_external_flag          --�ŐV�t���O
       ,SPMH.base_request_no                                base_request_no               --���˗�No
       ,SPMH.prev_delivery_no                               prev_delivery_no              --�O��z��No
       ,CUST1.party_number                                  customer_code                 --�ڋq
       ,CUST1.party_name                                    customer_name                 --�ڋq��
       ,SPMH.deliver_to                                     deliver_to                    --�o��_���ɐ�
       ,SPMH.deliver_to_name                                deliver_to_name               --�o��_���ɐ於
       ,SPMH.shipping_instructions                          shipping_instructions         --�o�׎w��
       ,SPMH.vendor_code                                    vendor_code                   --�����
       ,SPMH.vendor_name                                    vendor_name                   --����於
       ,SPMH.vendor_site_code                               vendor_site_code              --�����T�C�g
       ,SPMH.vendor_site_name                               vendor_site_name              --�����T�C�g��
       ,CARR1.freight_code                                  carrier_code                  --�^���Ǝ�
       ,CARR1.party_name                                    carrier_name                  --�^���ƎҖ�
       ,SPMH.shipping_method_code                           shipping_method_code          --�z���敪
       ,FLV02.meaning                                       shipping_method_name          --�z���敪��
       ,SPMH.cust_po_number                                 cust_po_number                --�ڋq����
       ,SPMH.price_list_id                                  price_list_id                 --���i�\
       ,QLHT.name                                           price_list_name               --���i�\��
       ,SPMH.status                                         status                        --�X�e�[�^�X
       ,SPMH.status_name                                    status_name                   --�X�e�[�^�X��
       ,SPMH.schedule_ship_date                             schedule_ship_date            --�o��_�o�ɗ\���
       ,SPMH.schedule_arrival_date                          schedule_arrival_date         --����_���ɗ\���
       ,SPMH.mixed_no                                       mixed_no                      --���ڌ�No
       ,SPMH.collected_pallet_qty                           collected_pallet_qty          --�p���b�g�������
       ,SPMH.out_pallet_qty                                 out_pallet_qty                --�p���b�g����_�o
       ,SPMH.in_pallet_qty                                  in_pallet_qty                 --�p���b�g����_��
       ,SPMH.mov_description                                mov_description               --�ړ�_�E�v
       ,SPMH.confirm_request_class                          confirm_request_class         --�����S���m�F�˗��敪
       ,FLV03.meaning                                       confirm_request_class_name    --�����S���m�F�˗��敪
       ,SPMH.freight_charge_class                           freight_charge_class          --�^���敪
       ,FLV04.meaning                                       freight_charge_class          --�^���敪��
       ,SPMH.shikyu_instruction_class                       shikyu_instruction_class      --�x���o�Ɏw���敪
       ,FLV05.meaning                                       shikyu_instruction_class_name --�x���o�Ɏw���敪��
       ,SPMH.shikyu_inst_rcv_class                          shikyu_inst_rcv_class         --�x���w����̋敪
       ,FLV06.meaning                                       shikyu_inst_rcv_class_name    --�x���w����̋敪��
       ,SPMH.amount_fix_class                               amount_fix_class              --�L�����z�m��敪
       ,FLV07.meaning                                       amount_fix_class_name         --�L�����z�m��敪��
       ,SPMH.takeback_class                                 takeback_class                --����敪
       ,FLV08.meaning                                       takeback_class_name           --����敪��
       ,ILCT1.segment1                                      deliver_from                  --�o��_�o�Ɍ��ۊǏꏊ
       ,ILCT1.description                                   deliver_from_name             --�o��_�o�Ɍ��ۊǏꏊ��
       ,SPMH.head_sales_branch                              head_sales_branch             --�Ǌ����_
       ,CUST2.party_name                                    head_sales_branch_name        --�Ǌ����_��
       ,CUST2.party_short_name                              head_sales_branch_s_name      --�Ǌ����_����
       ,SPMH.input_sales_branch                             input_sales_branch            --���͋��_
       ,CUST3.party_name                                    input_sales_branch_name       --���͋��_��
       ,CUST3.party_short_name                              input_sales_branch_s_name     --���͋��_����
       ,SPMH.po_no                                          po_no                         --����No
       ,SPMH.prod_class                                     prod_class                    --���i�敪
       ,FLV09.meaning                                       prod_class_name               --���i�敪��
       ,SPMH.item_class                                     item_class                    --�i�ڋ敪
       ,FLV10.meaning                                       item_class_name               --�i�ڋ敪��
       ,SPMH.product_flg                                    product_flg                   --���i���ʋ敪
       ,FLV11.meaning                                       product_flg_name              --���i���ʋ敪��
       ,SPMH.no_instr_actual_class                          no_instr_actual_class         --�w���Ȃ����ы敪
       ,SPMH.no_cont_freight_class                          no_cont_freight_class         --�_��O�^���敪
       ,FLV12.meaning                                       no_cont_freight_class_name    --�_��O�^���敪��
       ,SPMH.arrival_time_from                              arrival_time_from             --���׎���FROM
       ,FLV13.meaning                                       arrival_time_from_name        --���׎���FROM��
       ,SPMH.arrival_time_to                                arrival_time_to               --���׎���TO
       ,FLV14.meaning                                       arrival_time_to_name          --���׎���TO��
       ,ITEM.item_no                                        designated_item_code          --�����i��
       ,ITEM.item_name                                      designated_item_name          --�����i�ږ�
       ,ITEM.item_short_name                                designated_item_s_name        --�����i�ڗ���
       ,SPMH.designated_production_date                     designated_production_date    --������
       ,SPMH.designated_branch_no                           designated_branch_no          --�����}��
       ,SPMH.slip_number                                    slip_number                   --�����No
       ,SPMH.sum_quantity                                   sum_quantity                  --���v����
       ,SPMH.small_quantity                                 small_quantity                --������
       ,SPMH.label_quantity                                 label_quantity                --���x������
       ,CEIL( SPMH.loading_efficiency_weight   * 100 ) / 100    --�����_��R�ȉ��؂�グ
                                                            loading_efficiency_weight     --�d�ʐύڌ���
       ,CEIL( SPMH.loading_efficiency_capacity * 100 ) / 100    --�����_��R�ȉ��؂�グ
                                                            loading_efficiency_capacity   --�e�ϐύڌ���
       ,CEIL( SPMH.based_weight )                           based_weight                  --��{�d��
       ,CEIL( SPMH.based_capacity )                         based_capacity                --��{�e��
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL( SPMH.sum_weight )                             sum_weight                    --�ύڏd�ʍ��v
       ,CEIL( TRUNC(NVL(SPMH.sum_weight,0),1) )             sum_weight                    --�ύڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/7 #627 Y.Fukami Mod End
       ,CEIL( SPMH.sum_capacity )                           sum_capacity                  --�ύڗe�ύ��v
       ,CEIL( SPMH.mixed_ratio                 * 100 ) / 100    --�����_��R�ȉ��؂�グ
                                                            mixed_ratio                   --���ڗ�
       ,SPMH.pallet_sum_quantity                            pallet_sum_quantity           --�p���b�g���v����
       ,SPMH.real_pallet_quantity                           real_pallet_quantity          --�p���b�g���і���
       ,SPMH.sum_pallet_weight                              sum_pallet_weight             --���v�p���b�g�d��
       ,CARR2.freight_code                                  result_carrier_code           --�^���Ǝ�_����
       ,CARR3.freight_code                                  yj_carrier_code               --�^���Ǝ�_�\��
       ,CARR2.party_name                                    result_carrier_name           --�^���Ǝ�_���і�
       ,CARR3.party_name                                    yj_carrier_name               --�^���Ǝ�_�\����
       ,SPMH.result_shipping_method_code                    result_shipping_method_code   --�z���敪_����
       ,SPMH.yj_shipping_method_code                        yj_shipping_method_code       --�z���敪_�\��
       ,FLV15.meaning                                       result_shipping_method_name   --�z���敪_���і�
       ,FLV16.meaning                                       yj_shipping_method_name       --�z���敪_�\����
       ,SPMH.result_deliver_to                              result_deliver_to             --�o�א�_����
       ,SPMH.yj_deliver_to                                  yj_deliver_to                 --�o�א�_�\��
       ,SPMH.result_deliver_to_name                         result_deliver_to_name        --�o�א�_���і�
       ,SPMH.yj_deliver_to_name                             yj_deliver_to_name            --�o�א�_�\����
       ,SPMH.shipped_date                                   shipped_date                  --�o��_�o�ɓ�
       ,SPMH.yj_shipped_date                                yj_shipped_date               --�o�ד�_�\��
       ,SPMH.arrival_date                                   arrival_date                  --����_���ɓ�
       ,SPMH.yj_arrival_date                                yj_arrival_date               --���ד�_�\��
       ,SPMH.weight_capacity_class                          weight_capacity_class         --�d�ʗe�ϋ敪
       ,FLV17.meaning                                       weight_capacity_class_name    --�d�ʗe�ϋ敪��
       ,SPMH.actual_confirm_class                           actual_confirm_class          --���ьv��ϋ敪
       ,SPMH.correct_actual_flg                             correct_actual_flg            --���ђ����t���O
       ,SPMH.notif_status                                   notif_status                  --�ʒm�X�e�[�^�X
       ,FLV18.meaning                                       notif_status_name             --�ʒm�X�e�[�^�X��
       ,SPMH.prev_notif_status                              prev_notif_status             --�O��ʒm�X�e�[�^�X
       ,FLV19.meaning                                       prev_notif_status_name        --�O��ʒm�X�e�[�^�X��
       ,TO_CHAR( SPMH.notif_date, 'YYYY/MM/DD HH24:MI:SS')
                                                            notif_date                    --�m��ʒm���{����
       ,SPMH.new_modify_flg                                 new_modify_flg                --�V�K�C���t���O
       ,FLV20.meaning                                       new_modify_flg_name           --�V�K�C���t���O��
       ,SPMH.performance_management_dept                    performance_manage_dept       --���ъǗ�����
       ,LOCT1.location_name                                 performance_manage_dept_name  --���ъǗ�������
       ,SPMH.instruction_dept                               instruction_dept              --�w������
       ,LOCT2.location_name                                 instruction_dept_name         --�w��������
       ,SPMH.transfer_location_code                         transfer_location_code        --�U�֐�
       ,LOCT3.location_name                                 transfer_location_name        --�U�֐於
       ,SPMH.mixed_sign                                     mixed_sign                    --���ڋL��
       ,SPMH.batch_no                                       batch_no                      --��zNo
       ,TO_CHAR( SPMH.screen_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            screen_update_date            --��ʍX�V����
       ,FU.user_name                                        screen_update_by              --��ʍX�V��
       ,TO_CHAR( SPMH.tightening_date   , 'YYYY/MM/DD HH24:MI:SS' )
                                                            tightening_date               --�o�׈˗����ߓ���
       ,SPMH.tightening_program_id                          tightening_program_id         --���߃R���J�����gID
       ,SPMH.corrected_tighten_class                        corrected_tighten_class       --���ߌ�C���敪
       ,FLV21.meaning                                       corrected_tighten_class_name  --���ߌ�C���敪��
        --�z��/�z���A�h�I���f�[�^
       ,XCS.transaction_type                                transaction_type              --�z��_�������
       ,FLV22.meaning                                       transaction_type_name         --�z��_������ʖ�
       ,XCS.mixed_type                                      mixed_type                    --�z��_���ڎ��
       ,DECODE(XCS.mixed_type, '1', '�W��', '2', '����')    mixed_type_name               --�z��_���ڎ�ʖ�
       ,XCS.deliver_to_code_class                           deliver_to_code_class         --�z��_�z����R�[�h�敪
       ,FLV23.meaning                                       deliver_to_code_class_name    --�z��_�z����R�[�h�敪��
       ,XCS.auto_process_type                               auto_process_type             --�z��_�����z�ԑΏۋ敪
       ,FLV24.meaning                                       auto_process_type_name        --�z��_�����z�ԑΏۋ敪��
       ,XCS.description                                     cs_description                --�z��_�E�v
       ,XCS.payment_freight_flag                            payment_freight_flag          --�z��_�x���^���v�Z�Ώۃt���O
       ,DECODE(XCS.payment_freight_flag, '0', '�ΏۊO', '1', '�Ώ�')
                                                            payment_freight_flag_name     --�z��_�x���^���v�Z�Ώۃt���O��
       ,XCS.demand_freight_flag                             demand_freight_flag           --�z��_�����^���v�Z�Ώۃt���O
       ,DECODE(XCS.demand_freight_flag , '0', '�ΏۊO', '1', '�Ώ�')
                                                            demand_freight_flag_name      --�z��_�����^���v�Z�Ώۃt���O��
-- 2010/1/7 #627 Y.Fukami Mod Start
--       ,CEIL( XCS.sum_loading_weight )                      sum_loading_weight            --�z��_�ύڏd�ʍ��v
       ,CEIL( TRUNC(NVL(XCS.sum_loading_weight,0),1) )      sum_loading_weight            --�z��_�ύڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/7 #627 Y.Fukami Mod End
       ,CEIL( XCS.sum_loading_capacity )                    sum_loading_capacity          --�z��_�ύڗe�ύ��v
       ,CEIL( XCS.loading_efficiency_weight    * 100 ) / 100    --�����_��R�ȉ��؂�グ
                                                            cs_loading_effc_weight        --�z��_�d�ʐύڌ���
       ,CEIL( XCS.loading_efficiency_capacity  * 100 ) / 100    --�����_��R�ȉ��؂�グ
                                                            cs_loading_effc_capacity      --�z��_�e�ϐύڌ���
       ,XCS.freight_charge_type                             freight_charge_type           --�z��_�^���`��
       ,FLV25.meaning                                       freight_charge_type_name      --�z��_�^���`�Ԗ�
        --WHO�J����
       ,FU_CB.user_name                                     created_by                    --�쐬��
       ,TO_CHAR( SPMH.creation_date     , 'YYYY/MM/DD HH24:MI:SS' )
                                                            creation_date                 --�쐬��
       ,FU_LU.user_name                                     last_updated_by               --�ŏI�X�V��
       ,TO_CHAR( SPMH.last_update_date  , 'YYYY/MM/DD HH24:MI:SS' )
                                                            last_update_date              --�ŏI�X�V��
       ,FU_LL.user_name                                     last_update_login             --�ŏI�X�V���O�C��
  FROM (
         --==========================
         -- �o�׃f�[�^
         --==========================
         SELECT
                 XOHA.request_no                            request_no                    --�˗�_�ړ�No
                ,XOHA.delivery_no                           delivery_no                   --�z��No
                ,OTTT.name                                  type                          --�^�C�v
                ,NULL                                       mov_type                      --�ړ��^�C�v
                ,NULL                                       mov_type_name                 --�ړ��^�C�v��
                ,XOHA.organization_id                       organization_id               --�g�DID
                ,XOHA.ordered_date                          ordered_date                  --��_���͓�
                ,XOHA.latest_external_flag                  latest_external_flag          --�ŐV�t���O
                ,XOHA.base_request_no                       base_request_no               --���˗�No
                ,XOHA.prev_delivery_no                      prev_delivery_no              --�O��z��No
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
--                ,XOHA.customer_id                           customer_id                   --�ڋqID
                ,CASE WHEN XOHA.result_deliver_to IS NULL THEN PSIT1.party_id   --�o�א���т����݂��Ȃ��ꍇ�͔z����i�\��j�̌ڋqID
                      ELSE                                     PSIT2.party_id   --�o�א���т����݂���ꍇ�͔z����i���сj�̌ڋqID
                 END                                        customer_id                   --�ڋqID
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
                ,XOHA.deliver_to                            deliver_to                    --�o��_���ɐ�
                ,PSIT1.party_site_name                      deliver_to_name               --�o��_���ɐ於
                ,XOHA.shipping_instructions                 shipping_instructions         --�o�׎w��
                ,NULL                                       vendor_code                   --�����
                ,NULL                                       vendor_name                   --����於
                ,NULL                                       vendor_site_code              --�����T�C�g
                ,NULL                                       vendor_site_name              --�����T�C�g��
                ,XOHA.career_id                             career_id                     --�^���Ǝ�ID
                ,XOHA.shipping_method_code                  shipping_method_code          --�z���敪
                ,XOHA.cust_po_number                        cust_po_number                --�ڋq����
                ,XOHA.price_list_id                         price_list_id                 --���i�\ID
                ,XOHA.req_status                            status                        --�X�e�[�^�X
                ,FLV01.meaning                              status_name                   --�X�e�[�^�X��
                ,XOHA.schedule_ship_date                    schedule_ship_date            --�o��_�o�ɗ\���
                ,XOHA.schedule_arrival_date                 schedule_arrival_date         --����_���ɗ\���
                ,XOHA.mixed_no                              mixed_no                      --���ڌ�No
                ,XOHA.collected_pallet_qty                  collected_pallet_qty          --�p���b�g�������
                ,NULL                                       out_pallet_qty                --�p���b�g����_�o
                ,NULL                                       in_pallet_qty                 --�p���b�g����_��
                ,NULL                                       mov_description               --�ړ�_�E�v
                ,XOHA.confirm_request_class                 confirm_request_class         --�����S���m�F�˗��敪
                ,XOHA.freight_charge_class                  freight_charge_class          --�^���敪
                ,NULL                                       shikyu_instruction_class      --�x���o�Ɏw���敪
                ,NULL                                       shikyu_inst_rcv_class         --�x���w����̋敪
                ,NULL                                       amount_fix_class              --�L�����z�m��敪
                ,NULL                                       takeback_class                --����敪
                ,XOHA.deliver_from_id                       deliver_from_id               --�o��_�o�Ɍ��ۊǏꏊID
                ,XOHA.head_sales_branch                     head_sales_branch             --�Ǌ����_
                ,XOHA.input_sales_branch                    input_sales_branch            --���͋��_
                ,NULL                                       po_no                         --����No
                ,XOHA.prod_class                            prod_class                    --���i�敪
                ,XOHA.item_class                            item_class                    --�i�ڋ敪
                ,NULL                                       product_flg                   --���i���ʋ敪
                ,NULL                                       no_instr_actual_class         --�w���Ȃ����ы敪
                ,XOHA.no_cont_freight_class                 no_cont_freight_class         --�_��O�^���敪
                ,XOHA.arrival_time_from                     arrival_time_from             --���׎���FROM
                ,XOHA.arrival_time_to                       arrival_time_to               --���׎���TO
                ,NULL                                       designated_item_id            --�����i��ID
                ,NULL                                       designated_production_date    --������
                ,NULL                                       designated_branch_no          --�����}��
                ,XOHA.slip_number                           slip_number                   --�����No
                ,XOHA.sum_quantity                          sum_quantity                  --���v����
                ,XOHA.small_quantity                        small_quantity                --������
                ,XOHA.label_quantity                        label_quantity                --���x������
                ,XOHA.loading_efficiency_weight             loading_efficiency_weight     --�d�ʐύڌ���
                ,XOHA.loading_efficiency_capacity           loading_efficiency_capacity   --�e�ϐύڌ���
                ,XOHA.based_weight                          based_weight                  --��{�d��
                ,XOHA.based_capacity                        based_capacity                --��{�e��
                ,XOHA.sum_weight                            sum_weight                    --�ύڏd�ʍ��v
                ,XOHA.sum_capacity                          sum_capacity                  --�ύڗe�ύ��v
                ,XOHA.mixed_ratio                           mixed_ratio                   --���ڗ�
                ,XOHA.pallet_sum_quantity                   pallet_sum_quantity           --�p���b�g���v����
                ,XOHA.real_pallet_quantity                  real_pallet_quantity          --�p���b�g���і���
                ,XOHA.sum_pallet_weight                     sum_pallet_weight             --���v�p���b�g�d��
                ,XOHA.result_freight_carrier_id             result_freight_carrier_id     --�^���Ǝ�_����
                ,NVL( XOHA.result_freight_carrier_id, XOHA.career_id )                 --NVL( �^���Ǝ�_����ID, �^���Ǝ�ID )
                                                            yj_freight_carrier_id         --�^���Ǝ�_�\��ID
                ,XOHA.result_shipping_method_code           result_shipping_method_code   --�z���敪_����
                ,NVL( XOHA.result_shipping_method_code, XOHA.shipping_method_code )    --NVL( �z���敪_����, �z���敪 )
                                                            yj_shipping_method_code       --�z���敪_�\��
                ,XOHA.result_deliver_to                     result_deliver_to             --�o�א�_����
                ,PSIT2.party_site_name                      result_deliver_to_name        --�o�א�_���і�
                ,NVL( XOHA.result_deliver_to, XOHA.deliver_to )                        --NVL( �o�א����, �o�א� )
                                                            yj_deliver_to                 --�o�א�_�\��
                ,CASE WHEN XOHA.result_deliver_to IS NULL THEN PSIT1.party_site_name   --�o�א���т����݂��Ȃ��ꍇ�͏o�א於
                      ELSE                                     PSIT2.party_site_name   --�o�א���т����݂���ꍇ�͏o�א�_���і�
                 END                                        yj_deliver_to_name            --�o�א�_�\����
                ,XOHA.shipped_date                          shipped_date                  --�o��_�o�ɓ�
                ,XOHA.arrival_date                          arrival_date                  --����_���ɓ�
                ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date )                     --NVL( �o�ד�, �o�ח\��� )
                                                            yj_shipped_date               --�o�ד�_�\��
                ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )                  --NVL( ���ד�, ���ח\��� )
                                                            yj_arrival_date               --���ד�_�\��
                ,XOHA.weight_capacity_class                 weight_capacity_class         --�d�ʗe�ϋ敪
                ,XOHA.actual_confirm_class                  actual_confirm_class          --���ьv��ϋ敪
                ,NULL                                       correct_actual_flg            --���ђ����t���O
                ,XOHA.notif_status                          notif_status                  --�ʒm�X�e�[�^�X
                ,XOHA.prev_notif_status                     prev_notif_status             --�O��ʒm�X�e�[�^�X
                ,XOHA.notif_date                            notif_date                    --�m��ʒm���{����
                ,XOHA.new_modify_flg                        new_modify_flg                --�V�K�C���t���O
                ,XOHA.performance_management_dept           performance_management_dept   --���ъǗ�����
                ,XOHA.instruction_dept                      instruction_dept              --�w������
                ,XOHA.transfer_location_code                transfer_location_code        --�U�֐�
                ,XOHA.mixed_sign                            mixed_sign                    --���ڋL��
                ,NULL                                       batch_no                      --��zNo
                ,XOHA.screen_update_date                    screen_update_date            --��ʍX�V����
                ,XOHA.screen_update_by                      screen_update_by              --��ʍX�V��ID
                ,XOHA.tightening_date                       tightening_date               --�o�׈˗����ߓ���
                ,XOHA.tightening_program_id                 tightening_program_id         --���߃R���J�����gID
                ,XOHA.corrected_tighten_class               corrected_tighten_class       --���ߌ�C���敪
                ,XOHA.created_by                            created_by                    --�쐬��
                ,XOHA.creation_date                         creation_date                 --�쐬��
                ,XOHA.last_updated_by                       last_updated_by               --�ŏI�X�V��
                ,XOHA.last_update_date                      last_update_date              --�ŏI�X�V��
                ,XOHA.last_update_login                     last_update_login             --�ŏI�X�V���O�C��
           FROM
                 xxcmn_order_headers_all_arc     XOHA       --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                ,oe_transaction_types_all    OTTA           --�󒍃^�C�v�}�X�^
                ,oe_transaction_types_tl     OTTT           --�󒍃^�C�v�}�X�^(���{��)
                ,xxskz_party_sites2_v        PSIT1          --SKYLINK�p����VIEW �z������VIEW(�o��_���ɐ�)
                ,xxskz_party_sites2_v        PSIT2          --SKYLINK�p����VIEW �z������VIEW(�o�א�_����)
                ,fnd_lookup_values           FLV01          --�N�C�b�N�R�[�h(�X�e�[�^�X��)
          WHERE
            --�o�׏��̎擾
                 OTTA.attribute1             = '1'          --�o��
            AND  XOHA.latest_external_flag   = 'Y'          --�ŐV�t���O���L��
            AND  XOHA.order_type_id          = OTTA.transaction_type_id
            --�󒍃^�C�v���擾����
            AND  OTTT.language(+)            = 'JA'
            AND  XOHA.order_type_id          = OTTT.transaction_type_id(+)
            --�o��_���ɐ於�擾
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
-- id�ɂ�錋���ł͂Ȃ�code�Ō�������
--            AND  XOHA.deliver_to_id          = PSIT1.party_site_id(+)
            AND  XOHA.deliver_to             = PSIT1.party_site_number(+)
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= PSIT1.start_date_active(+)  --�L���J�n��
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= PSIT1.end_date_active(+)    --�L���I����
            --�o�א�_���і��擾
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
-- id�ɂ�錋���ł͂Ȃ�code�Ō�������
--            AND  XOHA.result_deliver_to_id   = PSIT2.party_site_id(+)
            AND  XOHA.result_deliver_to   = PSIT2.party_site_number(+)
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= PSIT2.start_date_active(+)  --�L���J�n��
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= PSIT2.end_date_active(+)    --�L���I����
            --�X�e�[�^�X���擾
            AND  FLV01.language(+)           = 'JA'
            AND  FLV01.lookup_type(+)        = 'XXWSH_TRANSACTION_STATUS'
            AND  FLV01.lookup_code(+)        = XOHA.req_status
         --[ �o�׃f�[�^  END ]
        UNION ALL
         --==========================
         -- �x���f�[�^
         --==========================
         SELECT
                 XOHA.request_no                            request_no                    --�˗�_�ړ�No
                ,XOHA.delivery_no                           delivery_no                   --�z��No
                ,OTTT.name                                  type                          --�^�C�v
                ,NULL                                       mov_type                      --�ړ��^�C�v
                ,NULL                                       mov_type_name                 --�ړ��^�C�v��
                ,XOHA.organization_id                       organization_id               --�g�DID
                ,XOHA.ordered_date                          ordered_date                  --��_���͓�
                ,XOHA.latest_external_flag                  latest_external_flag          --�ŐV�t���O
                ,XOHA.base_request_no                       base_request_no               --���˗�No
                ,XOHA.prev_delivery_no                      prev_delivery_no              --�O��z��No
                ,XOHA.customer_id                           customer_id                   --�ڋqID
                ,XOHA.vendor_site_code                      deliver_to                    --�o��_���ɐ�
                ,VSIT.vendor_site_name                      deliver_to_name               --�o��_���ɐ於
                ,XOHA.shipping_instructions                 shipping_instructions         --�o�׎w��
                ,XOHA.vendor_code                           vendor_code                   --�����
                ,VNDR.vendor_name                           vendor_code                   --����於
                ,XOHA.vendor_site_code                      vendor_site_code              --�����T�C�g
                ,VSIT.vendor_site_name                      vendor_site_code              --�����T�C�g��
                ,XOHA.career_id                             career_id                     --�^���Ǝ�ID
                ,XOHA.shipping_method_code                  shipping_method_code          --�z���敪
                ,XOHA.cust_po_number                        cust_po_number                --�ڋq����
                ,XOHA.price_list_id                         price_list_id                 --���i�\ID
                ,XOHA.req_status                            status                        --�X�e�[�^�X
                ,FLV01.meaning                              status_name                   --�X�e�[�^�X��
                ,XOHA.schedule_ship_date                    schedule_ship_date            --�o��_�o�ɗ\���
                ,XOHA.schedule_arrival_date                 schedule_arrival_date         --����_���ɗ\���
                ,XOHA.mixed_no                              mixed_no                      --���ڌ�No
                ,XOHA.collected_pallet_qty                  collected_pallet_qty          --�p���b�g�������
                ,NULL                                       out_pallet_qty                --�p���b�g����_�o
                ,NULL                                       in_pallet_qty                 --�p���b�g����_��
                ,NULL                                       mov_description               --�ړ�_�E�v
                ,XOHA.confirm_request_class                 confirm_request_class         --�����S���m�F�˗��敪
                ,XOHA.freight_charge_class                  freight_charge_class          --�^���敪
                ,XOHA.shikyu_instruction_class              shikyu_instruction_class      --�x���o�Ɏw���敪
                ,XOHA.shikyu_inst_rcv_class                 shikyu_inst_rcv_class         --�x���w����̋敪
                ,XOHA.amount_fix_class                      amount_fix_class              --�L�����z�m��敪
                ,XOHA.takeback_class                        takeback_class                --����敪
                ,XOHA.deliver_from_id                       deliver_from_id               --�o��_�o�Ɍ��ۊǏꏊID
                ,XOHA.head_sales_branch                     head_sales_branch             --�Ǌ����_
                ,XOHA.input_sales_branch                    input_sales_branch            --���͋��_
                ,XOHA.po_no                                 po_no                         --����No
                ,XOHA.prod_class                            prod_class                    --���i�敪
                ,XOHA.item_class                            item_class                    --�i�ڋ敪
                ,NULL                                       product_flg                   --���i���ʋ敪
                ,NULL                                       no_instr_actual_class         --�w���Ȃ����ы敪
                ,XOHA.no_cont_freight_class                 no_cont_freight_class         --�_��O�^���敪
                ,XOHA.arrival_time_from                     arrival_time_from             --���׎���FROM
                ,XOHA.arrival_time_to                       arrival_time_to               --���׎���TO
                ,XOHA.designated_item_code                  designated_item_id            --�����i��ID
                ,XOHA.designated_production_date            designated_production_date    --������
                ,XOHA.designated_branch_no                  designated_branch_no          --�����}��
                ,XOHA.slip_number                           slip_number                   --�����No
                ,XOHA.sum_quantity                          sum_quantity                  --���v����
                ,XOHA.small_quantity                        small_quantity                --������
                ,XOHA.label_quantity                        label_quantity                --���x������
                ,XOHA.loading_efficiency_weight             loading_efficiency_weight     --�d�ʐύڌ���
                ,XOHA.loading_efficiency_capacity           loading_efficiency_capacity   --�e�ϐύڌ���
                ,XOHA.based_weight                          based_weight                  --��{�d��
                ,XOHA.based_capacity                        based_capacity                --��{�e��
                ,XOHA.sum_weight                            sum_weight                    --�ύڏd�ʍ��v
                ,XOHA.sum_capacity                          sum_capacity                  --�ύڗe�ύ��v
                ,XOHA.mixed_ratio                           mixed_ratio                   --���ڗ�
                ,XOHA.pallet_sum_quantity                   pallet_sum_quantity           --�p���b�g���v����
                ,XOHA.real_pallet_quantity                  real_pallet_quantity          --�p���b�g���і���
                ,XOHA.sum_pallet_weight                     sum_pallet_weight             --���v�p���b�g�d��
                ,XOHA.result_freight_carrier_id             result_freight_carrier_id     --�^���Ǝ�_����ID
                ,NVL( XOHA.result_freight_carrier_id, XOHA.career_id )                 --NVL( �^���Ǝ�_����ID, �^���Ǝ�ID )
                                                            yj_freight_carrier_id         --�^���Ǝ�_�\��ID
                ,XOHA.result_shipping_method_code           result_shipping_method_code   --�z���敪_����
                ,NVL( XOHA.result_shipping_method_code, XOHA.shipping_method_code )    --NVL( �z���敪_����, �z���敪 )
                                                            yj_shipping_method_code       --�z���敪_�\��
                ,XOHA.vendor_site_code                      result_deliver_to             --�o�א�_����
                ,VSIT.vendor_site_name                      result_deliver_to_name        --�o�א�_���і�
                ,XOHA.vendor_site_code                      yj_deliver_to                 --�o�א�_�\��
                ,VSIT.vendor_site_name                      yj_deliver_to_name            --�o�א�_�\����
                ,XOHA.shipped_date                          shipped_date                  --�o��_�o�ɓ�
                ,XOHA.arrival_date                          arrival_date                  --����_���ɓ�
                ,NVL( XOHA.shipped_date, XOHA.schedule_ship_date )                     --NVL( �o�ד�, �o�ח\��� )
                                                            yj_shipped_date               --�o�ד�_�\��
                ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )                  --NVL( ���ד�, ���ח\��� )
                                                            yj_arrival_date               --���ד�_�\��
                ,XOHA.weight_capacity_class                 weight_capacity_class         --�d�ʗe�ϋ敪
                ,XOHA.actual_confirm_class                  actual_confirm_class          --���ьv��ϋ敪
                ,NULL                                       correct_actual_flg            --���ђ����t���O
                ,XOHA.notif_status                          notif_status                  --�ʒm�X�e�[�^�X
                ,XOHA.prev_notif_status                     prev_notif_status             --�O��ʒm�X�e�[�^�X
                ,XOHA.notif_date                            notif_date                    --�m��ʒm���{����
                ,XOHA.new_modify_flg                        new_modify_flg                --�V�K�C���t���O
                ,XOHA.performance_management_dept           performance_management_dept   --���ъǗ�����
                ,XOHA.instruction_dept                      instruction_dept              --�w������
                ,XOHA.transfer_location_code                transfer_location_code        --�U�֐�
                ,XOHA.mixed_sign                            mixed_sign                    --���ڋL��
                ,NULL                                       batch_no                      --��zNo
                ,XOHA.screen_update_date                    screen_update_date            --��ʍX�V����
                ,XOHA.screen_update_by                      screen_update_by              --��ʍX�V��ID
                ,NULL                                       tightening_date               --�o�׈˗����ߓ���
                ,NULL                                       tightening_program_id         --���߃R���J�����gID
                ,NULL                                       corrected_tighten_class       --���ߌ�C���敪
                ,XOHA.created_by                            created_by                    --�쐬��
                ,XOHA.creation_date                         creation_date                 --�쐬��
                ,XOHA.last_updated_by                       last_updated_by               --�ŏI�X�V��
                ,XOHA.last_update_date                      last_update_date              --�ŏI�X�V��
                ,XOHA.last_update_login                     last_update_login             --�ŏI�X�V���O�C��
           FROM
                 xxcmn_order_headers_all_arc     XOHA       --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                ,oe_transaction_types_all    OTTA           --�󒍃^�C�v�}�X�^
                ,oe_transaction_types_tl     OTTT           --�󒍃^�C�v�}�X�^(���{��)
                ,xxskz_vendors2_v            VNDR           --SKYLINK�p����VIEW �z������VIEW(�����)
                ,xxskz_vendor_sites2_v       VSIT           --SKYLINK�p����VIEW �z������VIEW(�����T�C�g)
                ,fnd_lookup_values           FLV01          --�N�C�b�N�R�[�h(�X�e�[�^�X��)
          WHERE
            --�o�׏��̎擾
                 OTTA.attribute1             = '2'          --�x��
            AND  XOHA.latest_external_flag   = 'Y'          --�ŐV�t���O���L��
            AND  XOHA.order_type_id          = OTTA.transaction_type_id
            --�󒍃^�C�v���擾����
            AND  OTTT.language(+)            = 'JA'
            AND  XOHA.order_type_id          = OTTT.transaction_type_id(+)
            --����於�擾
            AND  XOHA.vendor_id              = VNDR.vendor_id(+)
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= VNDR.start_date_active(+)  --�L���J�n��
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= VNDR.end_date_active(+)    --�L���I����
            --�����T�C�g���擾
            AND  XOHA.vendor_site_id         = VSIT.vendor_site_id(+)
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) >= VSIT.start_date_active(+)  --�L���J�n��
            AND  NVL( XOHA.arrival_date, XOHA.schedule_arrival_date ) <= VSIT.end_date_active(+)    --�L���I����
            --�X�e�[�^�X���擾
            AND  FLV01.language(+)           = 'JA'
            AND  FLV01.lookup_type(+)        = 'XXPO_TRANSACTION_STATUS'
            AND  FLV01.lookup_code(+)        = XOHA.req_status
         --[ �x���f�[�^  END ]
        UNION ALL
         --==========================
         -- �ړ��f�[�^
         --==========================
         SELECT
                 XMVH.mov_num                               request_no                    --�˗�_�ړ�No
                ,XMVH.delivery_no                           delivery_no                   --�z��No
                ,'�ړ�'                                     type                          --�^�C�v
                ,XMVH.mov_type                              mov_type                      --�ړ��^�C�v
                ,FLV01.meaning                              mov_type_name                 --�ړ��^�C�v��
                ,XMVH.organization_id                       organization_id               --�g�DID
                ,XMVH.entered_date                          ordered_date                  --��_���͓�
                ,NULL                                       latest_external_flag          --�ŐV�t���O
                ,NULL                                       base_request_no               --���˗�No
                ,XMVH.prev_delivery_no                      prev_delivery_no              --�O��z��No
                ,NULL                                       customer_id                   --�ڋqID
                ,XMVH.ship_to_locat_code                    deliver_to                    --�o��_���ɐ�
                ,ILCT.description                           deliver_to_name               --�o��_���ɐ於
                ,NULL                                       shipping_instructions         --�o�׎w��
                ,NULL                                       vendor_code                   --�����
                ,NULL                                       vendor_name                   --����於
                ,NULL                                       vendor_site_code              --�����T�C�g
                ,NULL                                       vendor_site_name              --�����T�C�g��
                ,XMVH.career_id                             career_id                     --�^���Ǝ�ID
                ,XMVH.shipping_method_code                  shipping_method_code          --�z���敪
                ,NULL                                       cust_po_number                --�ڋq����
                ,NULL                                       price_list_id                 --���i�\ID
                ,XMVH.status                                status                        --�X�e�[�^�X
                ,FLV02.meaning                              status_name                   --�X�e�[�^�X��
                ,XMVH.schedule_ship_date                    schedule_ship_date            --�o��_�o�ɗ\���
                ,XMVH.schedule_arrival_date                 schedule_arrival_date         --����_���ɗ\���
                ,NULL                                       mixed_no                      --���ڌ�No
                ,XMVH.collected_pallet_qty                  collected_pallet_qty          --�p���b�g�������
                ,XMVH.out_pallet_qty                        out_pallet_qty                --�p���b�g����_�o
                ,XMVH.in_pallet_qty                         in_pallet_qty                 --�p���b�g����_��
                ,XMVH.description                           mov_description               --�ړ�_�E�v
                ,NULL                                       confirm_request_class         --�����S���m�F�˗��敪
                ,XMVH.freight_charge_class                  freight_charge_class          --�^���敪
                ,NULL                                       shikyu_instruction_class      --�x���o�Ɏw���敪
                ,NULL                                       shikyu_inst_rcv_class         --�x���w����̋敪
                ,NULL                                       amount_fix_class              --�L�����z�m��敪
                ,NULL                                       takeback_class                --����敪
                ,XMVH.shipped_locat_id                      deliver_from_id               --�o��_�o�Ɍ��ۊǏꏊID
                ,NULL                                       head_sales_branch             --�Ǌ����_
                ,NULL                                       input_sales_branch            --���͋��_
                ,NULL                                       po_no                         --����No
                ,XMVH.item_class                            prod_class                    --���i�敪
                ,NULL                                       item_class                    --�i�ڋ敪
                ,XMVH.product_flg                           product_flg                   --���i���ʋ敪
                ,XMVH.no_instr_actual_class                 no_instr_actual_class         --�w���Ȃ����ы敪
                ,XMVH.no_cont_freight_class                 no_cont_freight_class         --�_��O�^���敪
                ,XMVH.arrival_time_from                     arrival_time_from             --���׎���FROM
                ,XMVH.arrival_time_to                       arrival_time_to               --���׎���TO
                ,NULL                                       designated_item_id            --�����i��ID
                ,NULL                                       designated_production_date    --������
                ,NULL                                       designated_branch_no          --�����}��
                ,XMVH.slip_number                           slip_number                   --�����No
                ,XMVH.sum_quantity                          sum_quantity                  --���v����
                ,XMVH.small_quantity                        small_quantity                --������
                ,XMVH.label_quantity                        label_quantity                --���x������
                ,XMVH.loading_efficiency_weight             loading_efficiency_weight     --�d�ʐύڌ���
                ,XMVH.loading_efficiency_capacity           loading_efficiency_capacity   --�e�ϐύڌ���
                ,XMVH.based_weight                          based_weight                  --��{�d��
                ,XMVH.based_capacity                        based_capacity                --��{�e��
                ,XMVH.sum_weight                            sum_weight                    --�ύڏd�ʍ��v
                ,XMVH.sum_capacity                          sum_capacity                  --�ύڗe�ύ��v
                ,XMVH.mixed_ratio                           mixed_ratio                   --���ڗ�
                ,XMVH.pallet_sum_quantity                   pallet_sum_quantity           --�p���b�g���v����
                ,NULL                                       real_pallet_quantity          --�p���b�g���і���
                ,XMVH.sum_pallet_weight                     sum_pallet_weight             --���v�p���b�g�d��
                ,XMVH.actual_career_id                      result_freight_carrier_id     --�^���Ǝ�_����ID
                ,NVL( XMVH.actual_career_id, XMVH.career_id )                          --NVL( �^���Ǝ�_����ID, �^���Ǝ�ID )
                                                            yj_freight_carrier_id         --�^���Ǝ�_�\��ID
                ,XMVH.actual_shipping_method_code           result_shipping_method_code   --�z���敪_����
                ,NVL( XMVH.actual_shipping_method_code, XMVH.shipping_method_code )    --NVL( �z���敪_����, �z���敪 )
                                                            yj_shipping_method_code       --�z���敪_�\��
                ,XMVH.ship_to_locat_code                    result_deliver_to             --�o�א�_����
                ,ILCT.description                           result_deliver_to_name        --�o�א�_���і�
                ,XMVH.ship_to_locat_code                    yj_deliver_to                 --�o�א�_�\��
                ,ILCT.description                           yj_deliver_to_name            --�o�א�_�\����
                ,XMVH.actual_ship_date                      shipped_date                  --�o��_�o�ɓ�
                ,XMVH.actual_arrival_date                   arrival_date                  --����_���ɓ�
                ,NVL( XMVH.actual_ship_date, XMVH.schedule_ship_date )                 --NVL( �o�ד�, �o�ח\��� )
                                                            yj_shipped_date               --�o�ד�_�\��
                ,NVL( XMVH.actual_arrival_date, XMVH.schedule_arrival_date )           --NVL( ���ד�, ���ח\��� )
                                                            yj_arrival_date               --���ד�_�\��
                ,XMVH.weight_capacity_class                 weight_capacity_class         --�d�ʗe�ϋ敪
                ,XMVH.comp_actual_flg                       actual_confirm_class          --���ьv��ϋ敪
                ,XMVH.correct_actual_flg                    correct_actual_flg            --���ђ����t���O
                ,XMVH.notif_status                          notif_status                  --�ʒm�X�e�[�^�X
                ,XMVH.prev_notif_status                     prev_notif_status             --�O��ʒm�X�e�[�^�X
                ,XMVH.notif_date                            notif_date                    --�m��ʒm���{����
                ,XMVH.new_modify_flg                        new_modify_flg                --�V�K�C���t���O
                ,NULL                                       performance_management_dept   --���ъǗ�����
                ,XMVH.instruction_post_code                 instruction_dept              --�w������
                ,NULL                                       transfer_location_code        --�U�֐�
                ,XMVH.mixed_sign                            mixed_sign                    --���ڋL��
                ,XMVH.batch_no                              batch_no                      --��zNo
                ,NULL                                       screen_update_date            --��ʍX�V����
                ,NULL                                       screen_update_by              --��ʍX�V��ID
                ,NULL                                       tightening_date               --�o�׈˗����ߓ���
                ,NULL                                       tightening_program_id         --���߃R���J�����gID
                ,NULL                                       corrected_tighten_class       --���ߌ�C���敪
                ,XMVH.created_by                            created_by                    --�쐬��
                ,XMVH.creation_date                         creation_date                 --�쐬��
                ,XMVH.last_updated_by                       last_updated_by               --�ŏI�X�V��
                ,XMVH.last_update_date                      last_update_date              --�ŏI�X�V��
                ,XMVH.last_update_login                     last_update_login             --�ŏI�X�V���O�C��
           FROM
                 xxcmn_mov_req_instr_hdrs_arc  XMVH         --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                ,xxskz_item_locations2_v     ILCT           --SKYLINK�p����VIEW �ۊǏꏊ���VIEW(�o��_���ɐ�ۊǏꏊ)
                ,fnd_lookup_values           FLV01          --�N�C�b�N�R�[�h(�ړ��^�C�v��)
                ,fnd_lookup_values           FLV02          --�N�C�b�N�R�[�h(�X�e�[�^�X��)
          WHERE
            --�o��_���ɐ於�擾
                 XMVH.ship_to_locat_id       = ILCT.inventory_location_id(+)
            --�ړ��^�C�v���擾
            AND  FLV01.language(+)           = 'JA'
            AND  FLV01.lookup_type(+)        = 'XXINV_MOVE_TYPE'
            AND  FLV01.lookup_code(+)        = XMVH.mov_type
            --�X�e�[�^�X���擾
            AND  FLV02.language(+)           = 'JA'
            AND  FLV02.lookup_type(+)        = 'XXINV_MOVE_STATUS'
            AND  FLV02.lookup_code(+)        = XMVH.status
         --[ �ړ��f�[�^  END ]
       )                                     SPMH           --�o��/�x��/�ړ� �w�b�_���
       ,xxcmn_carriers_schedule_arc              XCS        --�z�Ԕz���v��i�A�h�I���j�o�b�N�A�b�v
       ,hr_all_organization_units_tl         HAOUT          --�g�D�}�X�^
       ,xxskz_cust_accounts2_v               CUST1          --SKYLINK�p����VIEW �ڋq���VIEW(�ڋq)
       ,xxskz_cust_accounts2_v               CUST2          --SKYLINK�p����VIEW �ڋq���VIEW(�Ǌ����_)
       ,xxskz_cust_accounts2_v               CUST3          --SKYLINK�p����VIEW �ڋq���VIEW(���͋��_)
       ,xxskz_carriers2_v                    CARR1          --SKYLINK�p����VIEW �^���Ǝҏ��VIEW(�^���Ǝ�)
       ,xxskz_carriers2_v                    CARR2          --SKYLINK�p����VIEW �^���Ǝҏ��VIEW(�^���Ǝ�_����)
       ,xxskz_carriers2_v                    CARR3          --SKYLINK�p����VIEW �^���Ǝҏ��VIEW(�^���Ǝ�_�\��)
       ,xxskz_item_locations2_v              ILCT1           --SKYLINK�p����VIEW �ۊǏꏊ���VIEW(�o��_�o�Ɍ��ۊǏꏊ)
       ,xxskz_item_mst2_v                    ITEM           --SKYLINK�p����VIEW �i�ڏ��VIEW(�����i��)
       ,xxskz_locations2_v                   LOCT1          --SKYLINK�p����VIEW ���Ə����VIEW(���ъǗ�����)
       ,xxskz_locations2_v                   LOCT2          --SKYLINK�p����VIEW ���Ə����VIEW(�w������)
       ,xxskz_locations2_v                   LOCT3          --SKYLINK�p����VIEW ���Ə����VIEW(�U�֐�)
       ,qp_list_headers_tl                   QLHT           --���i�\�w�b�_(���{��)
       ,fnd_user                             FU             --���[�U�[�}�X�^(��ʍX�V�Җ��擾�p)
       ,fnd_user                             FU_CB          --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                             FU_LU          --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                             FU_LL          --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                           FL_LL          --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_lookup_values                    FLV02          --�N�C�b�N�R�[�h(�z���敪��)
       ,fnd_lookup_values                    FLV03          --�N�C�b�N�R�[�h(�����S���m�F�˗��敪��)
       ,fnd_lookup_values                    FLV04          --�N�C�b�N�R�[�h(�^���敪��)
       ,fnd_lookup_values                    FLV05          --�N�C�b�N�R�[�h(�x���o�Ɏw���敪��)
       ,fnd_lookup_values                    FLV06          --�N�C�b�N�R�[�h(�x���w����̋敪��)
       ,fnd_lookup_values                    FLV07          --�N�C�b�N�R�[�h(�L�����z�m��敪��)
       ,fnd_lookup_values                    FLV08          --�N�C�b�N�R�[�h(����敪��)
       ,fnd_lookup_values                    FLV09          --�N�C�b�N�R�[�h(���i�敪��)
       ,fnd_lookup_values                    FLV10          --�N�C�b�N�R�[�h(�i�ڋ敪��)
       ,fnd_lookup_values                    FLV11          --�N�C�b�N�R�[�h(���i���ʋ敪��)
       ,fnd_lookup_values                    FLV12          --�N�C�b�N�R�[�h(�_��O�^���敪��)
       ,fnd_lookup_values                    FLV13          --�N�C�b�N�R�[�h(���׎���FROM��)
       ,fnd_lookup_values                    FLV14          --�N�C�b�N�R�[�h(���׎���TO��)
       ,fnd_lookup_values                    FLV15          --�N�C�b�N�R�[�h(�z���敪_���і�)
       ,fnd_lookup_values                    FLV16          --�N�C�b�N�R�[�h(�z���敪_�\����)
       ,fnd_lookup_values                    FLV17          --�N�C�b�N�R�[�h(�d�ʗe�ϋ敪��)
       ,fnd_lookup_values                    FLV18          --�N�C�b�N�R�[�h(�ʒm�X�e�[�^�X��)
       ,fnd_lookup_values                    FLV19          --�N�C�b�N�R�[�h(�O��ʒm�X�e�[�^�X��)
       ,fnd_lookup_values                    FLV20          --�N�C�b�N�R�[�h(�V�K�C���t���O��)
       ,fnd_lookup_values                    FLV21          --�N�C�b�N�R�[�h(���ߌ�C���敪��)
       ,fnd_lookup_values                    FLV22          --�N�C�b�N�R�[�h(�z��_������ʖ�)
       ,fnd_lookup_values                    FLV23          --�N�C�b�N�R�[�h(�z��_�z����R�[�h�敪��)
       ,fnd_lookup_values                    FLV24          --�N�C�b�N�R�[�h(�z��_�����z�ԑΏۋ敪)
       ,fnd_lookup_values                    FLV25          --�N�C�b�N�R�[�h(�z��_�^���`��)
 WHERE
   --�z�Ԕz���A�h�I���e�[�u���f�[�^�擾
        SPMH.delivery_no                     = XCS.delivery_no(+)
   --�g�D���擾
   AND  HAOUT.language(+)                    = 'JA'
   AND  SPMH.organization_id                 = HAOUT.organization_id(+)
   --�ڋq���擾
   AND  SPMH.customer_id                     = CUST1.party_id(+)
   AND  SPMH.yj_arrival_date                >= CUST1.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= CUST1.end_date_active(+)
   --�^���ƎҖ��擾
   AND  SPMH.career_id                       = CARR1.party_id(+)
   AND  SPMH.yj_arrival_date                >= CARR1.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= CARR1.end_date_active(+)
   --���i�\���擾
   AND  QLHT.LANGUAGE(+)                     = 'JA'
   AND  SPMH.price_list_id                   = QLHT.LIST_HEADER_ID(+)
   --�o��_�o�Ɍ��ۊǏꏊ���擾
   AND  SPMH.deliver_from_id                 = ILCT1.inventory_location_id(+)
   --�Ǌ����_���擾
   AND  SPMH.head_sales_branch               = CUST2.party_number(+)
   AND  SPMH.yj_arrival_date                >= CUST2.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= CUST2.end_date_active(+)
   --���͋��_���擾
   AND  SPMH.input_sales_branch              = CUST3.party_number(+)
   AND  SPMH.yj_arrival_date                >= CUST3.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= CUST3.end_date_active(+)
   --�����i�ږ��擾
   AND  SPMH.designated_item_id              = ITEM.item_id(+)
   AND  SPMH.yj_arrival_date                >= ITEM.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= ITEM.end_date_active(+)
   --�^���Ǝ�_���і��擾
   AND  SPMH.result_freight_carrier_id       = CARR2.party_id(+)
   AND  SPMH.yj_arrival_date                >= CARR2.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= CARR2.end_date_active(+)
   --�^���Ǝ�_�\�����擾
   AND  SPMH.yj_freight_carrier_id           = CARR3.party_id(+)
   AND  SPMH.yj_arrival_date                >= CARR3.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= CARR3.end_date_active(+)
   --���ъǗ��������擾
   AND  SPMH.performance_management_dept     = LOCT1.location_code(+)
   AND  SPMH.yj_arrival_date                >= LOCT1.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= LOCT1.end_date_active(+)
   --�w���������擾
   AND  SPMH.instruction_dept                = LOCT2.location_code(+)
   AND  SPMH.yj_arrival_date                >= LOCT2.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= LOCT2.end_date_active(+)
   --�U�֐於�擾
   AND  SPMH.transfer_location_code          = LOCT3.location_code(+)
   AND  SPMH.yj_arrival_date                >= LOCT3.start_date_active(+)
   AND  SPMH.yj_arrival_date                <= LOCT3.end_date_active(+)
   -- ��ʍX�V�Җ��擾
   AND  SPMH.screen_update_by                = FU.user_id(+)
   --�쐬�ҁE�ŏI�X�V�Ҏ擾����
   AND  SPMH.created_by                      = FU_CB.user_id(+)
   AND  SPMH.last_updated_by                 = FU_LU.user_id(+)
   AND  SPMH.last_update_login               = FL_LL.login_id(+)
   AND  FL_LL.user_id                        = FU_LL.user_id(+)
   --�y�N�C�b�N�R�[�h�z�z���敪��
   AND  FLV02.language(+)                    = 'JA'
   AND  FLV02.lookup_type(+)                 = 'XXCMN_SHIP_METHOD'
   AND  FLV02.lookup_code(+)                 = SPMH.shipping_method_code
   --�y�N�C�b�N�R�[�h�z�����S���m�F�˗��敪��
   AND  FLV03.language(+)                    = 'JA'
   AND  FLV03.lookup_type(+)                 = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV03.lookup_code(+)                 = SPMH.confirm_request_class
   --�y�N�C�b�N�R�[�h�z�^���敪��
   AND  FLV04.language(+)                    = 'JA'
   AND  FLV04.lookup_type(+)                 = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV04.lookup_code(+)                 = SPMH.freight_charge_class
   --�y�N�C�b�N�R�[�h�z�x���o�Ɏw���敪��
   AND  FLV05.language(+)                    = 'JA'
   AND  FLV05.lookup_type(+)                 = 'XXWSH_SHIKYU_INSTRUCTION_CLASS'
   AND  FLV05.lookup_code(+)                 = SPMH.shikyu_instruction_class
   --�y�N�C�b�N�R�[�h�z�x���w����̋敪��
   AND  FLV06.language(+)                    = 'JA'
   AND  FLV06.lookup_type(+)                 = 'XXWSH_SHIKYU_INST_RCV_CLASS'
   AND  FLV06.lookup_code(+)                 = SPMH.shikyu_inst_rcv_class
   --�y�N�C�b�N�R�[�h�z�L�����z�m��敪��
   AND  FLV07.language(+)                    = 'JA'
   AND  FLV07.lookup_type(+)                 = 'XXWSH_AMOUNT_FIX_CLASS'
   AND  FLV07.lookup_code(+)                 = SPMH.amount_fix_class
   --�y�N�C�b�N�R�[�h�z����敪��
   AND  FLV08.language(+)                    = 'JA'
   AND  FLV08.lookup_type(+)                 = 'XXWSH_TAKEBACK_CLASS'
   AND  FLV08.lookup_code(+)                 = SPMH.takeback_class
   --�y�N�C�b�N�R�[�h�z���i�敪��
   AND  FLV09.language(+)                    = 'JA'
   AND  FLV09.lookup_type(+)                 = 'XXWIP_ITEM_TYPE'
   AND  FLV09.lookup_code(+)                 = SPMH.prod_class
   --�y�N�C�b�N�R�[�h�z�i�ڋ敪��
   AND  FLV10.language(+)                    = 'JA'
   AND  FLV10.lookup_type(+)                 = 'XXWSH_ITEM_DIV'
   AND  FLV10.lookup_code(+)                 = SPMH.item_class
   --�y�N�C�b�N�R�[�h�z���i���ʋ敪��
   AND  FLV11.language(+)                    = 'JA'
   AND  FLV11.lookup_type(+)                 = 'XXINV_PRODUCT_CLASS'
   AND  FLV11.lookup_code(+)                 = SPMH.product_flg
   --�y�N�C�b�N�R�[�h�z�_��O�^���敪��
   AND  FLV12.language(+)                    = 'JA'
   AND  FLV12.lookup_type(+)                 = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV12.lookup_code(+)                 = SPMH.no_cont_freight_class
   --�y�N�C�b�N�R�[�h�z���׎���FROM��
   AND  FLV13.language(+)                    = 'JA'
   AND  FLV13.lookup_type(+)                 = 'XXWSH_ARRIVAL_TIME'
   AND  FLV13.lookup_code(+)                 = SPMH.arrival_time_from
   --�y�N�C�b�N�R�[�h�z���׎���TO��
   AND  FLV14.language(+)                    = 'JA'
   AND  FLV14.lookup_type(+)                 = 'XXWSH_ARRIVAL_TIME'
   AND  FLV14.lookup_code(+)                 = SPMH.arrival_time_to
   --�y�N�C�b�N�R�[�h�z�z���敪_���і�
   AND  FLV15.language(+)                    = 'JA'
   AND  FLV15.lookup_type(+)                 = 'XXCMN_SHIP_METHOD'
   AND  FLV15.lookup_code(+)                 = SPMH.result_shipping_method_code
   --�y�N�C�b�N�R�[�h�z�z���敪_�\����
   AND  FLV16.language(+)                    = 'JA'
   AND  FLV16.lookup_type(+)                 = 'XXCMN_SHIP_METHOD'
   AND  FLV16.lookup_code(+)                 = SPMH.yj_shipping_method_code
   --�y�N�C�b�N�R�[�h�z�d�ʗe�ϋ敪��
   AND  FLV17.language(+)                    = 'JA'
   AND  FLV17.lookup_type(+)                 = 'XXCMN_WEIGHT_CAPACITY_CLASS'
   AND  FLV17.lookup_code(+)                 = SPMH.weight_capacity_class
   --�y�N�C�b�N�R�[�h�z�ʒm�X�e�[�^�X��
   AND  FLV18.language(+)                    = 'JA'
   AND  FLV18.lookup_type(+)                 = 'XXWSH_NOTIF_STATUS'
   AND  FLV18.lookup_code(+)                 = SPMH.notif_status
   --�y�N�C�b�N�R�[�h�z�O��ʒm�X�e�[�^�X��
   AND  FLV19.language(+)                    = 'JA'
   AND  FLV19.lookup_type(+)                 = 'XXWSH_NOTIF_STATUS'
   AND  FLV19.lookup_code(+)                 = SPMH.prev_notif_status
   --�y�N�C�b�N�R�[�h�z�V�K�C���t���O��
   AND  FLV20.language(+)                    = 'JA'
   AND  FLV20.lookup_type(+)                 = 'XXWSH_NEW_MODIFY_FLG'
   AND  FLV20.lookup_code(+)                 = SPMH.new_modify_flg
   --�y�N�C�b�N�R�[�h�z���ߌ�C���敪��
   AND  FLV21.language(+)                    = 'JA'
   AND  FLV21.lookup_type(+)                 = 'XXWSH_TIGHTEN_RELEASE_CLASS'
   AND  FLV21.lookup_code(+)                 = SPMH.corrected_tighten_class
   --�y�N�C�b�N�R�[�h�z�z��_������ʖ�
   AND  FLV22.language(+)                    = 'JA'
   AND  FLV22.lookup_type(+)                 = 'XXWSH_PROCESS_TYPE'
   AND  FLV22.lookup_code(+)                 = XCS.transaction_type
   --�y�N�C�b�N�R�[�h�z�z��_�z����R�[�h�敪��
   AND  FLV23.language(+)                    = 'JA'
   AND  FLV23.lookup_type(+)                 = 'CUSTOMER CLASS'
   AND  FLV23.lookup_code(+)                 = XCS.deliver_to_code_class
   --�y�N�C�b�N�R�[�h�z�z��_�����z�ԑΏۋ敪��
   AND  FLV24.language(+)                    = 'JA'
   AND  FLV24.lookup_type(+)                 = 'XXCMN_INCLUDE_EXCLUDE'
   AND  FLV24.lookup_code(+)                 = XCS.auto_process_type
   --�y�N�C�b�N�R�[�h�z�z��_�^���`�Ԗ�
   AND  FLV25.language(+)                    = 'JA'
   AND  FLV25.lookup_type(+)                 = 'XXCMN_TRNSFR_FARE_STD'
   AND  FLV25.lookup_code(+)                 = XCS.freight_charge_type
/
COMMENT ON TABLE APPS.XXSKZ_���o�ɔz���w�b�__��{_V IS 'SKYLINK�p���o�ɔz���w�b�_�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�˗�_�ړ�NO                   IS '�˗�_�ړ�NO'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��NO                        IS '�z��NO'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�^�C�v                        IS '�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ړ��^�C�v                    IS '�ړ��^�C�v'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ړ��^�C�v��                  IS '�ړ��^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�g�D��                        IS '�g�D��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.��_���͓�                   IS '��_���͓�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ŐV�t���O                    IS '�ŐV�t���O'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���˗�NO                      IS '���˗�NO'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�O��z��NO                    IS '�O��z��NO'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ڋq                          IS '�ڋq'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ڋq��                        IS '�ڋq��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o��_���ɐ�                   IS '�o��_���ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o��_���ɐ於                 IS '�o��_���ɐ於'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o�׎w��                      IS '�o�׎w��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�����                        IS '�����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.����於                      IS '����於'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�����T�C�g                  IS '�����T�C�g'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�����T�C�g��                IS '�����T�C�g��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�^���Ǝ�                      IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�^���ƎҖ�                    IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z���敪                      IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z���敪��                    IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ڋq����                      IS '�ڋq����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���i�\                        IS '���i�\'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���i�\��                      IS '���i�\��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�X�e�[�^�X                    IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�X�e�[�^�X��                  IS '�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o��_�o�ɗ\���               IS '�o��_�o�ɗ\���'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.����_���ɗ\���               IS '����_���ɗ\���'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���ڌ�NO                      IS '���ڌ�NO'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�p���b�g�������              IS '�p���b�g�������'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�p���b�g����_�o               IS '�p���b�g����_�o'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�p���b�g����_��               IS '�p���b�g����_��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ړ�_�E�v                     IS '�ړ�_�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�����S���m�F�˗��敪          IS '�����S���m�F�˗��敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�����S���m�F�˗��敪��        IS '�����S���m�F�˗��敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�^���敪                      IS '�^���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�^���敪��                    IS '�^���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�x���o�Ɏw���敪              IS '�x���o�Ɏw���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�x���o�Ɏw���敪��            IS '�x���o�Ɏw���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�x���w����̋敪              IS '�x���w����̋敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�x���w����̋敪��            IS '�x���w����̋敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�L�����z�m��敪              IS '�L�����z�m��敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�L�����z�m��敪��            IS '�L�����z�m��敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.����敪                      IS '����敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.����敪��                    IS '����敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o��_�o�Ɍ��ۊǏꏊ           IS '�o��_�o�Ɍ��ۊǏꏊ'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o��_�o�Ɍ��ۊǏꏊ��         IS '�o��_�o�Ɍ��ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�Ǌ����_                      IS '�Ǌ����_'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�Ǌ����_��                    IS '�Ǌ����_��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�Ǌ����_����                  IS '�Ǌ����_����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���͋��_                      IS '���͋��_'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���͋��_��                    IS '���͋��_��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���͋��_����                  IS '���͋��_����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.����NO                        IS '����NO'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���i�敪                      IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���i�敪��                    IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�i�ڋ敪                      IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�i�ڋ敪��                    IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���i���ʋ敪                  IS '���i���ʋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���i���ʋ敪��                IS '���i���ʋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�w���Ȃ����ы敪              IS '�w���Ȃ����ы敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�_��O�^���敪                IS '�_��O�^���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�_��O�^���敪��              IS '�_��O�^���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���׎���FROM                  IS '���׎���FROM'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���׎���FROM��                IS '���׎���FROM��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���׎���TO                    IS '���׎���TO'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���׎���TO��                  IS '���׎���TO��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�����i��                      IS '�����i��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�����i�ږ�                    IS '�����i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�����i�ڗ���                  IS '�����i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.������                        IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�����}��                      IS '�����}��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�����NO                      IS '�����NO'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���v����                      IS '���v����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.������                      IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���x������                    IS '���x������'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�d�ʐύڌ���                  IS '�d�ʐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�e�ϐύڌ���                  IS '�e�ϐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.��{�d��                      IS '��{�d��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.��{�e��                      IS '��{�e��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ύڏd�ʍ��v                  IS '�ύڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ύڗe�ύ��v                  IS '�ύڗe�ύ��v'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���ڗ�                        IS '���ڗ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�p���b�g���v����              IS '�p���b�g���v����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�p���b�g���і���              IS '�p���b�g���і���'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���v�p���b�g�d��              IS '���v�p���b�g�d��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�^���Ǝ�_����                 IS '�^���Ǝ�_����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�^���Ǝ�_�\��                 IS '�^���Ǝ�_�\��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�^���Ǝ�_���і�               IS '�^���Ǝ�_���і�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�^���Ǝ�_�\����               IS '�^���Ǝ�_�\����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z���敪_����                 IS '�z���敪_����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z���敪_�\��                 IS '�z���敪_�\��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z���敪_���і�               IS '�z���敪_���і�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z���敪_�\����               IS '�z���敪_�\����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o�א�_����                   IS '�o�א�_����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o�א�_�\��                   IS '�o�א�_�\��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o�א�_���і�                 IS '�o�א�_���і�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o�א�_�\����                 IS '�o�א�_�\����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o��_�o�ɓ�                   IS '�o��_�o�ɓ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o��_�o�ɓ�_�\��              IS '�o��_�o�ɓ�_�\��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.����_���ɓ�                   IS '����_���ɓ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.����_���ɓ�_�\��              IS '����_���ɓ�_�\��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�d�ʗe�ϋ敪                  IS '�d�ʗe�ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�d�ʗe�ϋ敪��                IS '�d�ʗe�ϋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���ьv��ϋ敪                IS '���ьv��ϋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���ђ����t���O                IS '���ђ����t���O'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ʒm�X�e�[�^�X                IS '�ʒm�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ʒm�X�e�[�^�X��              IS '�ʒm�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�O��ʒm�X�e�[�^�X            IS '�O��ʒm�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�O��ʒm�X�e�[�^�X��          IS '�O��ʒm�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�m��ʒm���{����              IS '�m��ʒm���{����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�V�K�C���t���O                IS '�V�K�C���t���O'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�V�K�C���t���O��              IS '�V�K�C���t���O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���ъǗ�����                  IS '���ъǗ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���ъǗ�������                IS '���ъǗ�������'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�w������                      IS '�w������'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�w��������                    IS '�w��������'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�U�֐�                        IS '�U�֐�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�U�֐於                      IS '�U�֐於'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���ڋL��                      IS '���ڋL��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.��zNO                        IS '��zNO'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.��ʍX�V����                  IS '��ʍX�V����'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.��ʍX�V��                    IS '��ʍX�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�o�׈˗����ߓ���              IS '�o�׈˗����ߓ���'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���߃R���J�����gID            IS '���߃R���J�����gID'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���ߌ�C���敪                IS '���ߌ�C���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.���ߌ�C���敪��              IS '���ߌ�C���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�������                 IS '�z��_�������'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_������ʖ�               IS '�z��_������ʖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_���ڎ��                 IS '�z��_���ڎ��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_���ڎ�ʖ�               IS '�z��_���ڎ�ʖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�z����R�[�h�敪         IS '�z��_�z����R�[�h�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�z����R�[�h�敪��       IS '�z��_�z����R�[�h�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�����z�ԑΏۋ敪         IS '�z��_�����z�ԑΏۋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�����z�ԑΏۋ敪��       IS '�z��_�����z�ԑΏۋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�E�v                     IS '�z��_�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�x���^���v�Z�Ώۃt���O   IS '�z��_�x���^���v�Z�Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�x���^���v�Z�Ώۃt���O�� IS '�z��_�x���^���v�Z�Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�����^���v�Z�Ώۃt���O   IS '�z��_�����^���v�Z�Ώۃt���O'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�����^���v�Z�Ώۃt���O�� IS '�z��_�����^���v�Z�Ώۃt���O��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�ύڏd�ʍ��v             IS '�z��_�ύڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�ύڗe�ύ��v             IS '�z��_�ύڗe�ύ��v'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�d�ʐύڌ���             IS '�z��_�d�ʐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�e�ϐύڌ���             IS '�z��_�e�ϐύڌ���'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�^���`��                 IS '�z��_�^���`��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�z��_�^���`�Ԗ�               IS '�z��_�^���`�Ԗ�'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�쐬��                        IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�쐬��                        IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ŏI�X�V��                    IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ŏI�X�V��                    IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_���o�ɔz���w�b�__��{_V.�ŏI�X�V���O�C��              IS '�ŏI�X�V���O�C��'
/
