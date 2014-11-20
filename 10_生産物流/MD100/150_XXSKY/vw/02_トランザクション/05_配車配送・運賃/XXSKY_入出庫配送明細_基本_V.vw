CREATE OR REPLACE VIEW APPS.XXSKY_���o�ɔz������_��{_V
(
 �˗�_�ړ�NO
,�^�C�v
,�ړ��^�C�v
,�ړ��^�C�v��
,���הԍ�
,���R�[�h�^�C�v
,���R�[�h�^�C�v��
,�g�D��
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�o�׈ړ�_�i��
,�o�׈ړ�_�i�ږ�
,�o�׈ړ�_�i�ڗ���
,���b�gNO
,�����N����
,�ŗL�L��
,�ܖ�����
,�폜�t���O
,�˗�����
,�w������
,�P��
,�P��
,�w�萻����
,�˗��i��
,�˗��i�ږ�
,�˗��i�ڗ���
,�t�уR�[�h
,�w����t_���[�t
,�ړ�NO
,����NO
,�ڋq����
,�p���b�g��
,�i��
,�P�[�X��
,�d��
,�e��
,�p���b�g����
,�p���b�g�d��
,������
,�Q�ƈړ��ԍ�
,�Q�Ɣ����ԍ�
,����w������
,�o�Ɏ��ѐ���
,���Ɏ��ѐ���
,�x���敪
,�x���敪��
,�x�����t
,�E�v
,�o�׈˗��C���^�t�F�[�X�σt���O
,�o�׎��уC���^�t�F�[�X�σt���O
,���ѓ�
,���ѐ���
,�����O���ѐ���
,�����蓮�����敪
,�����蓮�����敪��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT
        SPML.request_no                                     request_no                    --�˗�_�ړ�NO
       ,SPML.type                                           type                          --�^�C�v
       ,SPML.mov_type                                       mov_type                      --�ړ��^�C�v
       ,SPML.mov_type_name                                  mov_type_name                 --�ړ��^�C�v��
       ,SPML.line_number                                    line_number                   --���הԍ�
       ,SPML.record_type_code                               record_type_code              --���R�[�h�^�C�v
       ,FLV01.meaning                                       record_type_name              --���R�[�h�^�C�v��
       ,HAOUT.name                                          organization_name             --�g�D��
       ,PRODC.prod_class_code                               prod_class_code               --���i�敪
       ,PRODC.prod_class_name                               prod_class_name               --���i�敪��
       ,ITEMC.item_class_code                               item_class_code               --�i�ڋ敪
       ,ITEMC.item_class_name                               item_class_name               --�i�ڋ敪��
       ,CROWD.crowd_code                                    crowd_code                    --�Q�R�[�h
       ,SPML.shipping_item_code                             shipping_item_code            --�o�׈ړ�_�i��
       ,ITEM1.item_name                                     shipping_item_name            --�o�׈ړ�_�i�ږ�
       ,ITEM1.item_short_name                               shipping_item_s_name          --�o�׈ړ�_�i�ڗ���
       ,NVL( DECODE( SPML.lot_no, 'DEFAULTLOT', '0', SPML.lot_no ), '0' )
                                                            lot_no                        --���b�gNo('DEFALTLOT'�A���b�g��������'0')
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN LOT.attribute1  --���b�g�Ǘ��i   �������N�������擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END                                                 lot_date                      --�����N����
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN LOT.attribute2  --���b�g�Ǘ��i   ���ŗL�L�����擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END                                                 lot_sign                      --�ŗL�L��
       ,CASE WHEN ITEM1.lot_ctl = 1 THEN LOT.attribute3  --���b�g�Ǘ��i   ���ܖ��������擾
             ELSE NULL                                   --�񃍃b�g�Ǘ��i ��NULL
        END                                                 best_bfr_date                 --�ܖ�����
       ,SPML.delete_flag                                    delete_flag                   --�폜�t���O
       ,SPML.request_quantity                               request_quantity              --�˗�����
       ,SPML.instruct_quantity                              instruct_quantity             --�w������
       ,SPML.uom_code                                       uom_code                      --�P��
       ,SPML.unit_price                                     unit_price                    --�P��
       ,SPML.designated_production_date                     designated_production_date    --�w�萻����
       ,SPML.request_item_code                              request_item_code             --�˗��i��
       ,ITEM2.item_name                                     request_item_name             --�˗��i�ږ�
       ,ITEM2.item_short_name                               request_item_s_name           --�˗��i�ڗ���
       ,SPML.futai_code                                     futai_code                    --�t�уR�[�h
       ,SPML.designated_date                                designated_date               --�w����t_���[�t
       ,SPML.move_number                                    move_number                   --�ړ�No
       ,SPML.po_number                                      po_number                     --����No
       ,SPML.cust_po_number                                 cust_po_number                --�ڋq����
       ,SPML.pallet_quantity                                pallet_quantity               --�p���b�g��
       ,SPML.layer_quantity                                 layer_quantity                --�i��
       ,SPML.case_quantity                                  case_quantity                 --�P�[�X��
       ,CEIL( SPML.weight )                                 weight                        --�d��
       ,CEIL( SPML.capacity )                               capacity                      --�e��
       ,SPML.pallet_qty                                     pallet_qty                    --�p���b�g����
       ,CEIL( SPML.pallet_weight )                          pallet_weight                 --�p���b�g�d��
       ,SPML.reserved_quantity                              reserved_quantity             --������
       ,SPML.move_num                                       move_num                      --�Q�ƈړ��ԍ�
       ,SPML.po_num                                         po_num                        --�Q�Ɣ����ԍ�
       ,SPML.first_instruct_qty                             first_instruct_qty            --����w������
       ,SPML.shipped_quantity                               shipped_quantity              --�o�Ɏ��ѐ���
       ,SPML.ship_to_quantity                               ship_to_quantity              --���Ɏ��ѐ���
       ,SPML.warning_class                                  warning_class                 --�x���敪
       ,FLV02.meaning                                       warning_name                  --�x���敪��
       ,SPML.warning_date                                   warning_date                  --�x�����t
       ,SPML.line_description                               line_description              --�E�v
       ,SPML.shipping_request_if_flg                        shipping_request_if_flg       --�o�׈˗��C���^�t�F�[�X�σt���O
       ,SPML.shipping_result_if_flg                         shipping_result_if_flg        --�o�׎��уC���^�t�F�[�X�σt���O
       ,SPML.actual_date                                    actual_date                   --���ѓ�
       ,SPML.actual_quantity                                actual_quantity               --���ѐ���
       ,SPML.before_actual_quantity                         before_actual_quantity        --�����O���ѐ���
       ,SPML.automanual_reserve_class                       automanual_reserve_class      --�����蓮�����敪
       ,FLV03.meaning                                       automanual_reserve_name       --�����蓮�����敪��
       ,FU_CB.user_name                                     created_by_name               --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( SPML.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            creation_date                 --�쐬����
       ,FU_LU.user_name                                     last_updated_by_name          --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( SPML.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                                            last_update_date              --�X�V����
       ,FU_LL.user_name                                     last_update_login_name        --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM (
         --==========================
         -- �o�׃f�[�^
         --==========================
         SELECT
                 XOLA.request_no                            request_no                    --�˗�_�ړ�No
                ,OTTT.name                                  type                          --�^�C�v
                ,NULL                                       mov_type                      --�ړ��^�C�v
                ,NULL                                       mov_type_name                 --�ړ��^�C�v��
                ,XOLA.order_line_number                     line_number                   --���הԍ�
                ,XMLD.record_type_code                      record_type_code              --���R�[�h�^�C�v
                ,XOHA.organization_id                       organization_id               --�g�DID
                ,ITEM1.item_id                              shipping_item_id              --�o�׈ړ�_�i��ID
                ,XOLA.shipping_item_code                    shipping_item_code            --�o�׈ړ�_�i��
                ,XMLD.lot_id                                lot_id                        --���b�gID
                ,XMLD.lot_no                                lot_no                        --���b�gNo
                ,XOLA.delete_flag                           delete_flag                   --�폜�t���O
                ,XOLA.based_request_quantity                request_quantity              --�˗�����
                ,XOLA.quantity                              instruct_quantity             --�w������
                ,XOLA.uom_code                              uom_code                      --�P��
                ,NULL                                       unit_price                    --�P��
                ,XOLA.designated_production_date            designated_production_date    --�w�萻����
                ,ITEM2.item_id                              request_item_id               --�˗��i��ID
                ,XOLA.request_item_code                     request_item_code             --�˗��i��
                ,NULL                                       futai_code                    --�t�уR�[�h
                ,XOLA.designated_date                       designated_date               --�w����t_���[�t
                ,XOLA.move_number                           move_number                   --�ړ�No
                ,XOLA.po_number                             po_number                     --����No
                ,XOLA.cust_po_number                        cust_po_number                --�ڋq����
                ,XOLA.pallet_quantity                       pallet_quantity               --�p���b�g��
                ,XOLA.layer_quantity                        layer_quantity                --�i��
                ,XOLA.case_quantity                         case_quantity                 --�P�[�X��
                ,XOLA.weight                                weight                        --�d��
                ,XOLA.capacity                              capacity                      --�e��
                ,XOLA.pallet_qty                            pallet_qty                    --�p���b�g����
                ,XOLA.pallet_weight                         pallet_weight                 --�p���b�g�d��
                ,XOLA.reserved_quantity                     reserved_quantity             --������
                ,NULL                                       move_num                      --�Q�ƈړ��ԍ�
                ,NULL                                       po_num                        --�Q�Ɣ����ԍ�
                ,NULL                                       first_instruct_qty            --����w������
                ,XOLA.shipped_quantity                      shipped_quantity              --�o�Ɏ��ѐ���
                ,NULL                                       ship_to_quantity              --���Ɏ��ѐ���
                ,XOLA.warning_class                         warning_class                 --�x���敪
                ,XOLA.warning_date                          warning_date                  --�x�����t
                ,XOLA.line_description                      line_description              --�E�v
                ,XOLA.shipping_request_if_flg               shipping_request_if_flg       --�o�׈˗��C���^�t�F�[�X�σt���O
                ,XOLA.shipping_result_if_flg                shipping_result_if_flg        --�o�׎��уC���^�t�F�[�X�σt���O
                ,XMLD.actual_date                           actual_date                   --���ѓ�
                ,XMLD.actual_quantity                       actual_quantity               --���ѐ���
                ,XMLD.before_actual_quantity                before_actual_quantity        --�����O���ѐ���
                ,XMLD.automanual_reserve_class              automanual_reserve_class      --�����蓮�����敪
                ,XMLD.created_by                            created_by                    --�쐬��
                ,XMLD.creation_date                         creation_date                 --�쐬��
                ,XMLD.last_updated_by                       last_updated_by               --�ŏI�X�V��
                ,XMLD.last_update_date                      last_update_date              --�ŏI�X�V��
                ,XMLD.last_update_login                     last_update_login             --�ŏI�X�V���O�C��
                ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )    --NVL( ���ד�, ���ח\��� )
                                                            arrival_date                  --���ד� (�˕i�ږ��̎擾�Ŏg�p)
          FROM   xxwsh_order_headers_all     XOHA           --�󒍃w�b�_�A�h�I��
                ,oe_transaction_types_all    OTTA           --�󒍃^�C�v�}�X�^
                ,oe_transaction_types_tl     OTTT           --�󒍃^�C�v�}�X�^(���{��)
                ,xxwsh_order_lines_all       XOLA           --�󒍖��׃A�h�I��
                ,ic_item_mst_b               ITEM1          --�i�ڃ}�X�^(�o�וi�ڂ̕i��ID�擾�p)
                ,ic_item_mst_b               ITEM2          --�i�ڃ}�X�^(�˗��i�ڂ̕i��ID�擾�p)
                ,xxinv_mov_lot_details       XMLD           --�ړ����b�g�ڍ׃A�h�I��
          WHERE
            --�o�׏��̎擾
                 OTTA.attribute1             = '1'          --�o��
            AND  XOHA.latest_external_flag   = 'Y'          --�ŐV�t���O���L��
            AND  XOHA.order_type_id          = OTTA.transaction_type_id
            --�󒍃^�C�v���擾����
            AND  OTTT.language(+)            = 'JA'
            AND  XOHA.order_type_id          = OTTT.transaction_type_id(+)
            --�󒍖��׏��̎擾
            AND  NVL(XOLA.delete_flag, 'N') <> 'Y'
            AND  XOHA.order_header_id        = XOLA.order_header_id
            --�o�וi��ID�擾
            AND  XOLA.shipping_item_code     = ITEM1.item_no
            --�˗��i��ID�擾
            AND  XOLA.request_item_code      = ITEM2.item_no
            --�ړ����b�g�ڍ׏��̎擾
            AND  XMLD.document_type_code(+)  = '10'         --�o�׈˗�
            AND  XOLA.order_line_id          = XMLD.mov_line_id(+)
         --[ �o�׃f�[�^  END ]
        UNION ALL
         --==========================
         -- �x���f�[�^
         --==========================
         SELECT
                 XOLA.request_no                            request_no                    --�˗�_�ړ�No
                ,OTTT.name                                  type                          --�^�C�v
                ,NULL                                       mov_type                      --�ړ��^�C�v
                ,NULL                                       mov_type_name                 --�ړ��^�C�v��
                ,XOLA.order_line_number                     line_number                   --���הԍ�
                ,XMLD.record_type_code                      record_type_code              --���R�[�h�^�C�v
                ,XOHA.organization_id                       organization_id               --�g�DID
                ,ITEM1.item_id                              shipping_item_id              --�o�׈ړ�_�i��ID
                ,XOLA.shipping_item_code                    shipping_item_code            --�o�׈ړ�_�i��
                ,XMLD.lot_id                                lot_id                        --���b�gID
                ,XMLD.lot_no                                lot_no                        --���b�gNo
                ,XOLA.delete_flag                           delete_flag                   --�폜�t���O
                ,XOLA.based_request_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --�ԕi�̏ꍇ�̓}�C�i�X�l
                                                            request_quantity              --�˗�����
                ,XOLA.quantity               * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --�ԕi�̏ꍇ�̓}�C�i�X�l
                                                            instruct_quantity             --�w������
                ,XOLA.uom_code                              uom_code                      --�P��
                ,XOLA.unit_price                            unit_price                    --�P��
                ,NULL                                       designated_production_date    --�w�萻����
                ,ITEM2.item_id                              request_item_id               --�˗��i��ID
                ,XOLA.request_item_code                     request_item_code             --�˗��i��
                ,XOLA.futai_code                            futai_code                    --�t�уR�[�h
                ,NULL                                       designated_date               --�w����t_���[�t
                ,NULL                                       move_number                   --�ړ�No
                ,NULL                                       po_number                     --����No
                ,NULL                                       cust_po_number                --�ڋq����
                ,XOLA.pallet_quantity                       pallet_quantity               --�p���b�g��
                ,XOLA.layer_quantity                        layer_quantity                --�i��
                ,XOLA.case_quantity                         case_quantity                 --�P�[�X��
                ,XOLA.weight                                weight                        --�d��
                ,XOLA.capacity                              capacity                      --�e��
                ,XOLA.pallet_qty                            pallet_qty                    --�p���b�g����
                ,XOLA.pallet_weight                         pallet_weight                 --�p���b�g�d��
                ,XOLA.reserved_quantity      * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --�ԕi�̏ꍇ�̓}�C�i�X�l
                                                            reserved_quantity             --������
                ,NULL                                       move_num                      --�Q�ƈړ��ԍ�
                ,NULL                                       po_num                        --�Q�Ɣ����ԍ�
                ,NULL                                       first_instruct_qty            --����w������
                ,XOLA.shipped_quantity       * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --�ԕi�̏ꍇ�̓}�C�i�X�l
                                                            shipped_quantity              --�o�Ɏ��ѐ���
                ,XOLA.ship_to_quantity       * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --�ԕi�̏ꍇ�̓}�C�i�X�l
                                                            ship_to_quantity              --���Ɏ��ѐ���
                ,XOLA.warning_class                         warning_class                 --�x���敪
                ,XOLA.warning_date                          warning_date                  --�x�����t
                ,XOLA.line_description                      line_description              --�E�v
                ,NULL                                       shipping_request_if_flg       --�o�׈˗��C���^�t�F�[�X�σt���O
                ,NULL                                       shipping_result_if_flg        --�o�׎��уC���^�t�F�[�X�σt���O
                ,XMLD.actual_date                           actual_date                   --���ѓ�
                ,XMLD.actual_quantity        * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --�ԕi�̏ꍇ�̓}�C�i�X�l
                                                            actual_quantity               --���ѐ���
                ,XMLD.before_actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )    --�ԕi�̏ꍇ�̓}�C�i�X�l
                                                            before_actual_quantity        --�����O���ѐ���
                ,XMLD.automanual_reserve_class              automanual_reserve_class      --�����蓮�����敪
                ,XMLD.created_by                            created_by                    --�쐬��
                ,XMLD.creation_date                         creation_date                 --�쐬��
                ,XMLD.last_updated_by                       last_updated_by               --�ŏI�X�V��
                ,XMLD.last_update_date                      last_update_date              --�ŏI�X�V��
                ,XMLD.last_update_login                     last_update_login             --�ŏI�X�V���O�C��
                ,NVL( XOHA.arrival_date, XOHA.schedule_arrival_date )    --NVL( ���ד�, ���ח\��� )
                                                            arrival_date                  --���ד� (�˕i�ږ��̎擾�Ŏg�p)
          FROM   xxwsh_order_headers_all     XOHA           --�󒍃w�b�_�A�h�I��
                ,oe_transaction_types_all    OTTA           --�󒍃^�C�v�}�X�^
                ,oe_transaction_types_tl     OTTT           --�󒍃^�C�v�}�X�^(���{��)
                ,xxwsh_order_lines_all       XOLA           --�󒍖��׃A�h�I��
                ,ic_item_mst_b               ITEM1          --�i�ڃ}�X�^(�o�וi�ڂ̕i��ID�擾�p)
                ,ic_item_mst_b               ITEM2          --�i�ڃ}�X�^(�˗��i�ڂ̕i��ID�擾�p)
                ,xxinv_mov_lot_details       XMLD           --�ړ����b�g�ڍ׃A�h�I��
          WHERE
            --�o�׏��̎擾
                 OTTA.attribute1             = '2'          --�x��
            AND  XOHA.latest_external_flag   = 'Y'          --�ŐV�t���O���L��
            AND  XOHA.order_type_id          = OTTA.transaction_type_id
            --�󒍃^�C�v���擾����
            AND  OTTT.language(+)            = 'JA'
            AND  XOHA.order_type_id          = OTTT.transaction_type_id(+)
            --�󒍖��׏��̎擾
            AND  NVL(XOLA.delete_flag, 'N') <> 'Y'
            AND  XOHA.order_header_id        = XOLA.order_header_id
            --�o�וi��ID�擾
            AND  XOLA.shipping_item_code     = ITEM1.item_no
            --�˗��i��ID�擾
            AND  XOLA.request_item_code      = ITEM2.item_no
            --�ړ����b�g�ڍ׏��̎擾
            AND  XMLD.document_type_code(+)  = '30'         --�x���w��
            AND  XOLA.order_line_id          = XMLD.mov_line_id(+)
         --[ �x���f�[�^  END ]
        UNION ALL
         --==========================
         -- �ړ��f�[�^
         --==========================
         SELECT
                 XMVH.mov_num                               request_no                    --�˗�_�ړ�No
                ,'�ړ�'                                     type                          --�^�C�v
                ,XMVH.mov_type                              mov_type                      --�ړ��^�C�v
                ,FLV01.meaning                              mov_type_name                 --�ړ��^�C�v��
                ,XMVL.line_number                           line_number                   --���הԍ�
                ,XMLD.record_type_code                      record_type_code              --���R�[�h�^�C�v
                ,XMVL.organization_id                       organization_id               --�g�DID
                ,XMVL.item_id                               shipping_item_id              --�o�׈ړ�_�i��ID
                ,XMVL.item_code                             shipping_item_code            --�o�׈ړ�_�i��
                ,XMLD.lot_id                                lot_id                        --���b�gID
                ,XMLD.lot_no                                lot_no                        --���b�gNo
                ,XMVL.delete_flg                            delete_flag                   --�폜�t���O
                ,XMVL.request_qty                           request_quantity              --�˗�����
                ,XMVL.instruct_qty                          instruct_quantity             --�w������
                ,XMVL.uom_code                              uom_code                      --�P��
                ,NULL                                       unit_price                    --�P��
                ,XMVL.designated_production_date            designated_production_date    --�w�萻����
                ,NULL                                       request_item_id               --�˗��i��ID
                ,NULL                                       request_item_code             --�˗��i��
                ,NULL                                       futai_code                    --�t�уR�[�h
                ,NULL                                       designated_date               --�w����t_���[�t
                ,NULL                                       move_number                   --�ړ�No
                ,NULL                                       po_number                     --����No
                ,NULL                                       cust_po_number                --�ڋq����
                ,XMVL.pallet_quantity                       pallet_quantity               --�p���b�g��
                ,XMVL.layer_quantity                        layer_quantity                --�i��
                ,XMVL.case_quantity                         case_quantity                 --�P�[�X��
                ,XMVL.weight                                weight                        --�d��
                ,XMVL.capacity                              capacity                      --�e��
                ,XMVL.pallet_qty                            pallet_qty                    --�p���b�g����
                ,XMVL.pallet_weight                         pallet_weight                 --�p���b�g�d��
                ,XMVL.reserved_quantity                     reserved_quantity             --������
                ,XMVL.move_num                              move_num                      --�Q�ƈړ��ԍ�
                ,XMVL.po_num                                po_num                        --�Q�Ɣ����ԍ�
                ,XMVL.first_instruct_qty                    first_instruct_qty            --����w������
                ,XMVL.shipped_quantity                      shipped_quantity              --�o�Ɏ��ѐ���
                ,XMVL.ship_to_quantity                      ship_to_quantity              --���Ɏ��ѐ���
                ,XMVL.warning_class                         warning_class                 --�x���敪
                ,XMVL.warning_date                          warning_date                  --�x�����t
                ,NULL                                       line_description              --�E�v
                ,NULL                                       shipping_request_if_flg       --�o�׈˗��C���^�t�F�[�X�σt���O
                ,NULL                                       shipping_result_if_flg        --�o�׎��уC���^�t�F�[�X�σt���O
                ,XMLD.actual_date                           actual_date                   --���ѓ�
                ,XMLD.actual_quantity                       actual_quantity               --���ѐ���
                ,XMLD.before_actual_quantity                before_actual_quantity        --�����O���ѐ���
                ,XMLD.automanual_reserve_class              automanual_reserve_class      --�����蓮�����敪
                ,XMLD.created_by                            created_by                    --�쐬��
                ,XMLD.creation_date                         creation_date                 --�쐬��
                ,XMLD.last_updated_by                       last_updated_by               --�ŏI�X�V��
                ,XMLD.last_update_date                      last_update_date              --�ŏI�X�V��
                ,XMLD.last_update_login                     last_update_login             --�ŏI�X�V���O�C��
                ,NVL( XMVH.actual_arrival_date, XMVH.schedule_arrival_date )    --NVL( ���ד�, ���ח\��� )
                                                            arrival_date                  --���ד� (�˕i�ږ��̎擾�Ŏg�p)
           FROM  xxinv_mov_req_instr_headers XMVH           --�ړ��˗��w���w�b�_�A�h�I��
                ,xxinv_mov_req_instr_lines   XMVL           --�ړ��˗��w�����׃A�h�I��
                ,xxinv_mov_lot_details       XMLD           --�ړ����b�g�ڍ׃A�h�I��
                ,fnd_lookup_values           FLV01          --�N�C�b�N�R�[�h(�ړ��^�C�v��)
          WHERE
            --�ړ����׏��̎擾
                 NVL(XMVL.delete_flg, 'N')  <> 'Y'
            AND  XMVH.mov_hdr_id             = XMVL.mov_hdr_id
            --�ړ����b�g�ڍ׏��̎擾
            AND  XMLD.document_type_code(+)  = '20'         --�ړ��w��
            AND  XMVL.mov_line_id            = XMLD.mov_line_id(+)
            --�ړ��^�C�v���擾
            AND  FLV01.language(+)           = 'JA'
            AND  FLV01.lookup_type(+)        = 'XXINV_MOVE_TYPE'
            AND  FLV01.lookup_code(+)        = XMVH.mov_type
         --[ �ړ��f�[�^  END ]
       )                                SPML                     --�o��/�x��/�ړ� ���׏��
       ,hr_all_organization_units_tl    HAOUT                    --�g�D�}�X�^
       ,xxsky_item_mst2_v               ITEM1                    --SKYLINK�p����VIEW OPM�i�ڏ��VIEW(�o�׈ړ�_�i��)
       ,xxsky_item_mst2_v               ITEM2                    --SKYLINK�p����VIEW OPM�i�ڏ��VIEW(�˗��i��)
       ,xxsky_prod_class_v              PRODC                    --SKYLINK�p����VIEW ���i�敪���VIEW
       ,xxsky_item_class_v              ITEMC                    --SKYLINK�p����VIEW �i�ڋ敪���VIEW
       ,xxsky_crowd_code_v              CROWD                    --SKYLINK�p����VIEW �Q�R�[�h���VIEW
       ,ic_lots_mst                     LOT                      --���b�g�}�X�^
       ,fnd_user                        FU_CB                    --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                        FU_LU                    --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                        FU_LL                    --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                      FL_LL                    --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_lookup_values               FLV01                    --�N�C�b�N�R�[�h(���R�[�h�^�C�v��)
       ,fnd_lookup_values               FLV02                    --�N�C�b�N�R�[�h(�x���敪��)
       ,fnd_lookup_values               FLV03                    --�N�C�b�N�R�[�h(�����蓮�����敪��)
 WHERE
   --�g�D���擾
        HAOUT.language(+)               = 'JA'
   AND  SPML.organization_id            = HAOUT.organization_id(+)
   --�o�׈ړ�_�i�ږ��擾
   AND  SPML.shipping_item_id           = ITEM1.item_id(+)
   AND  SPML.arrival_date              >= ITEM1.start_date_active(+)
   AND  SPML.arrival_date              <= ITEM1.end_date_active(+)
   --�i�ڃJ�e�S�����擾
   AND  SPML.shipping_item_id           = PRODC.item_id(+)       --���i�敪
   AND  SPML.shipping_item_id           = ITEMC.item_id(+)       --�i�ڋ敪
   AND  SPML.shipping_item_id           = CROWD.item_id(+)       --�Q�R�[�h
   --���b�g���擾
   AND  SPML.shipping_item_id           = LOT.item_id(+)
   AND  SPML.lot_id                     = LOT.lot_id(+)
   --�˗��i�ږ��擾
   AND  SPML.request_item_id            = ITEM2.item_id(+)
   AND  SPML.arrival_date              >= ITEM2.start_date_active(+)
   AND  SPML.arrival_date              <= ITEM2.end_date_active(+)
   --WHO�J�������擾
   AND  SPML.created_by                 = FU_CB.user_id(+)
   AND  SPML.last_updated_by            = FU_LU.user_id(+)
   AND  SPML.last_update_login          = FL_LL.login_id(+)
   AND  FL_LL.user_id                   = FU_LL.user_id(+)
   --�y�N�C�b�N�R�[�h�z���R�[�h�^�C�v��
   AND  FLV01.language(+)               = 'JA'
   AND  FLV01.lookup_type(+)            = 'XXINV_RECORD_TYPE'
   AND  FLV01.lookup_code(+)            = SPML.record_type_code
   --�y�N�C�b�N�R�[�h�z�x���敪��
   AND  FLV02.language(+)               = 'JA'
   AND  FLV02.lookup_type(+)            = 'XXWSH_WARNING_CLASS'
   AND  FLV02.lookup_code(+)            = SPML.warning_class
   --�y�N�C�b�N�R�[�h�z�����哱�����敪��
   AND  FLV03.language(+)               = 'JA'
   AND  FLV03.lookup_type(+)            = 'XXINV_AM_RESERVE_CLASS'
   AND  FLV03.lookup_code(+)            = SPML.automanual_reserve_class
/
COMMENT ON TABLE APPS.XXSKY_���o�ɔz������_��{_V IS 'SKYLINK�p���o�ɔz�����ׁi��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�˗�_�ړ�NO IS '�˗�_�ړ�No'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�^�C�v IS '�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�ړ��^�C�v IS '�ړ��^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�ړ��^�C�v�� IS '�ړ��^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.���הԍ� IS '���הԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.���R�[�h�^�C�v IS '���R�[�h�^�C�v'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.���R�[�h�^�C�v�� IS '���R�[�h�^�C�v��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�g�D�� IS '�g�D��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�o�׈ړ�_�i�� IS '�o�׈ړ�_�i��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�o�׈ړ�_�i�ږ� IS '�o�׈ړ�_�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�o�׈ړ�_�i�ڗ��� IS '�o�׈ړ�_�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.���b�gNO IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�����N���� IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�ŗL�L�� IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�ܖ����� IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�폜�t���O IS '�폜�t���O'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�˗����� IS '�˗�����'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�w������ IS '�w������'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�P�� IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�P�� IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�w�萻���� IS '�w�萻����'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�˗��i�� IS '�˗��i��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�˗��i�ږ� IS '�˗��i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�˗��i�ڗ��� IS '�˗��i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�t�уR�[�h IS '�t�уR�[�h'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�w����t_���[�t IS '�w����t_���[�t'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�ړ�NO IS '�ړ�No'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.����NO IS '����No'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�ڋq���� IS '�ڋq����'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�p���b�g�� IS '�p���b�g��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�i�� IS '�i��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�P�[�X�� IS '�P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�d�� IS '�d��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�e�� IS '�e��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�p���b�g���� IS '�p���b�g����'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�p���b�g�d�� IS '�p���b�g�d��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.������ IS '������'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�Q�ƈړ��ԍ� IS '�Q�ƈړ��ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�Q�Ɣ����ԍ� IS '�Q�Ɣ����ԍ�'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.����w������ IS '����w������'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�o�Ɏ��ѐ��� IS '�o�Ɏ��ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.���Ɏ��ѐ��� IS '���Ɏ��ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�x���敪 IS '�x���敪'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�x���敪�� IS '�x���敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�x�����t IS '�x�����t'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�E�v IS '�E�v'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�o�׈˗��C���^�t�F�[�X�σt���O IS '�o�׈˗��C���^�t�F�[�X�σt���O'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�o�׎��уC���^�t�F�[�X�σt���O IS '�o�׎��уC���^�t�F�[�X�σt���O'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.���ѓ� IS '���ѓ�'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.���ѐ��� IS '���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�����O���ѐ��� IS '�����O���ѐ���'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�����蓮�����敪 IS '�����蓮�����敪'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�����蓮�����敪�� IS '�����蓮�����敪��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�쐬�� IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�ŏI�X�V�� IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKY_���o�ɔz������_��{_V.�ŏI�X�V���O�C�� IS '�ŏI�X�V���O�C��'
/
