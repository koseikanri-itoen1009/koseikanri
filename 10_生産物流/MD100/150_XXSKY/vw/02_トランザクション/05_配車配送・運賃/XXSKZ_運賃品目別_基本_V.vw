/*************************************************************************
 * 
 * View  Name      : XXSKZ_�^���i�ڕ�_��{_V
 * Description     : XXSKZ_�^���i�ڕ�_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/26    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�^���i�ڕ�_��{_V
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
       ,UHK.req_mov_no                      --�˗�_�ړ�No
       ,UHK.kbn                             --�敪
       ,UHK.order_type                      --�󒍃^�C�v
       ,UHK.status                          --�X�e�[�^�X
       ,UHK.status_name                     --�X�e�[�^�X��
       ,UHK.branch                          --�Ǌ����_
       ,UHK.branch_name                     --�Ǌ����_��
       ,UHK.carrier_code                    --�^���Ǝ�
       ,UHK.carrier_name                    --�^���ƎҖ�
       ,UHK.carrier_short_name              --�^���Ǝҗ���
       ,UHK.ship_deliver_to                 --���ɐ�_�z����
       ,UHK.ship_deliver_to_name            --���ɐ�_�z���於
       ,UHK.ship_deliver_to_short_name      --���ɐ�_�z���旪��
       ,UHK.ship_from                       --�o�Ɍ�
       ,UHK.ship_from_name                  --�o�Ɍ���
       ,UHK.ship_from_short_name            --�o�Ɍ�����
       ,UHK.ship_method_code                --�z���敪
       ,UHK.ship_method_name                --�z���敪��
       ,UHK.shipped_date                    --�o�ɓ�
       ,UHK.arrival_date                    --���ɓ�
       ,PRODC.prod_class_code               --���i�敪
       ,PRODC.prod_class_name               --���i�敪��
       ,ITEMC.item_class_code               --�i�ڋ敪
       ,ITEMC.item_class_name               --�i�ڋ敪��
       ,CROWD.crowd_code                    --�Q�R�[�h
       ,UHK.item_code                       --�i�ڃR�[�h
       ,UHK.item_name                       --�i�ږ���
       ,UHK.item_short_name                 --�i�ڗ���
       ,UHK.quantity                        --�i�ڃo����
       ,UHK.cs_quantity                     --�i�ڃP�[�X��
       ,UHK.sum_cs_quantity                 --���v�P�[�X��
       ,UHK.sum_loading_weight              --�ύڏd�ʍ��v
       ,UHK.distribute_sum_loading_weight   --���v�Z�p_�ύڏd�ʍ��v
       ,UHK.item_weight                     --�i�ڏd�ʍ��v
       ,UHK.distribute_item_weight          --���v�Z�p_�i�ڏd��
       ,UHK.total_amount                    --���v���z
       ,UHK.item_total_amount               --�i��_���v���z
  FROM
       (
        --=========================================================
        -- �o�׃f�[�^
        --=========================================================
        SELECT
                DELV.delivery_no                    delivery_no                     --�z��No
               ,DELV.request_no                     req_mov_no                      --�˗�_�ړ�No
               ,'�o��'                              kbn                             --�敪
               ,DELV.order_type_name                order_type                      --�󒍃^�C�v
               ,DELV.req_status                     status                          --�X�e�[�^�X
               ,FLV01.meaning                       status_name                     --�X�e�[�^�X��
               ,DELV.head_sales_branch              branch                          --�Ǌ����_
               ,XCAV.party_name                     branch_name                     --�Ǌ����_��
               ,DELV.freight_carrier_code           carrier_code                    --�^���Ǝ�
               ,XCRV.party_name                     carrier_name                    --�^���ƎҖ�
               ,XCRV.party_short_name               carrier_short_name              --�^���Ǝҗ���
               ,DELV.deliver_to                     ship_deliver_to                 --���ɐ�_�z����
               ,XPSV.party_site_name                ship_deliver_to_name            --���ɐ�_�z���於
               ,XPSV.party_site_short_name          ship_deliver_to_short_name      --���ɐ�_�z���旪��
               ,DELV.deliver_from                   ship_from                       --�o�Ɍ�
               ,XILV.description                    ship_from_name                  --�o�Ɍ���
               ,XILV.short_name                     ship_from_short_name            --�o�Ɍ�����
               ,DELV.shipping_method_code           ship_method_code                --�z���敪
               ,FLV02.meaning                       ship_method_name                --�z���敪��
               ,DELV.shipped_date                   shipped_date                    --�o�ɓ�
               ,DELV.arrival_date                   arrival_date                    --���ɓ�
               ,ITEM.item_id                        item_id                         --�i��ID
               ,ITEM.item_no                        item_code                       --�i�ڃR�[�h
               ,ITEM.item_name                      item_name                       --�i�ږ���
               ,ITEM.item_short_name                item_short_name                 --�i�ڗ���
               ,DELV.shipped_quantity               quantity                        --�i�ڃo����
               ,NVL( DELV.shipped_quantity / ITEM.num_of_cases, 0 )
                                                    cs_quantity                     --�i�ڃP�[�X��
               ,NVL( DELV.qty1, 0 )                 sum_cs_quantity                 --���v�P�[�X��
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.sum_loading_weight)      sum_loading_weight              --�ύڏd�ʍ��v
               ,CEIL(TRUNC(NVL(DELV.sum_loading_weight,0),1))      
                                                    sum_loading_weight              --�ύڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_sum_loading_weight  distribute_sum_loading_weight   --���v�Z�p_�ύڏd�ʍ��v
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.weight)                  item_weight                     --�i�ڏd�ʍ��v
               ,CEIL(TRUNC(NVL(DELV.weight,0),1))   item_weight                     --�i�ڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_item_weight         distribute_item_weight          --���v�Z�p_�i�ڏd�ʍ��v
               --�z���P�ʂƕi�ڒP�ʂ̉^��
               ,NVL( DELV.total_amount      , 0 )                       total_amount             --���v���z
               ,NVL( ROUND( DELV.total_amount       * item_rate ), 0 )  item_total_amount        --�i��_���v���z
          FROM  (  --�Ώۃf�[�^�𒊏o
                   SELECT  XOHA.delivery_no                                          --�z��No
                          ,XOHA.request_no                                           --�˗�_�ړ�No
                          ,XOHA.order_type_id                                        --�󒍃^�C�v
                          ,OTTT.name                         order_type_name         --�󒍃^�C�v��
                          ,XOHA.req_status                                           --�X�e�[�^�X
                          ,XOHA.head_sales_branch                                    --�Ǌ����_
                          ,XOHA.result_freight_carrier_id    freight_carrier_id      --�^���Ǝ�ID
                          ,XOHA.result_freight_carrier_code  freight_carrier_code    --�^���Ǝ�
                          ,XOHA.result_deliver_to_id         deliver_to_id           --�o��_�z����ID
                          ,XOHA.result_deliver_to            deliver_to              --�o��_�z����
                          ,XOHA.deliver_from_id                                      --�o�Ɍ�ID
                          ,XOHA.deliver_from                                         --�o�Ɍ�
                          ,XOHA.result_shipping_method_code  shipping_method_code    --�z���敪
                          ,XOHA.shipped_date                                         --�o�ɓ�
                          ,XOHA.arrival_date                                         --���ɓ�
--                        ,XOLA.shipping_item_code                                   --�o�וi�ڃR�[�h
                          ,XOLA.request_item_code                                    --�˗��i�ڃR�[�h
                          ,XOLA.shipped_quantity                                     --�i��_����
                          ,XCS.sum_loading_weight            sum_loading_weight      --�z��_�ύڏd�ʍ��v
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --�z��_���v�Z�p_�ύڏd�ʍ��v
                          ,XOLA.weight                                               --�i�ڏd�ʍ��v
                          ,XOLA.weight                       distribute_item_weight  --���v�Z�p_�i�ڏd�ʍ��v
                           --�z��No���̕i�ڏd�ʊ����i�i��_�d�ʍ��v �� �z��_�d�ʍ��v�j
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XOLA.weight / XCS.sum_loading_weight
                           END                               item_rate               --�z��No���̕i�ڏd�ʊ���
                           --�z���P�ʂ̉^��
                          ,XDLV.qty1                                                 --�z��_���P
                          ,XDLV.total_amount                                         --�z��_���v���z
                     FROM  xxcmn_order_headers_all_arc         XOHA                  --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                          ,oe_transaction_types_all        OTTA                      --�󒍃^�C�v�}�X�^
                          ,oe_transaction_types_tl         OTTT                      --�󒍃^�C�v���}�X�^
                          ,xxcmn_order_lines_all_arc           XOLA                  --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                          ,(    -- �z��NO�P�ʂ̐ύڏd�ʍ��v�Z�o
                            SELECT delivery_no                                       --�z��NO
                                  ,SUM(sum_weight)   sum_loading_weight              --�ύڏd�ʍ��v
                              FROM (SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_order_headers_all_arc               --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                     WHERE latest_external_flag = 'Y'
                                    UNION ALL
                                    SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_mov_req_instr_hdrs_arc              --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                   )
                            GROUP BY delivery_no
                           )                               XCS                      --�z��NO�P�ʐύڏd�ʍ��v
                          ,(
                            SELECT XD1.delivery_no                                  --�z��NO
                                  ,XD1.qty1                                         --�z��_���P
                                  ,XD1.total_amount                                 --�z��_���v���z
                              FROM xxwip_deliverys XD1
                             WHERE XD1.p_b_classe = '2'                             --'2:�����^��'
                            UNION ALL
                            SELECT XD2.delivery_no                                  --�z��NO
                                  ,XD2.qty1                                         --�z��_���P
                                  ,0                                                --�z��_���v���z
                              FROM xxwip_deliverys XD2
                             WHERE XD2.p_b_classe = '1'                             --'1:�x���^��'
                               -- �x�������敪��'1':�x���^���̂�
                               AND NOT EXISTS
                                   (
                                    SELECT 'X'
                                      FROM xxwip_deliverys XD3
                                      WHERE XD3.p_b_classe = '2'                    --'2:�����^��'
                                        AND XD3.delivery_no = XD2.delivery_no
                                   )
                           )                               XDLV                     --�^���w�b�_�A�h�I��
                    WHERE
                      -- �o�׃f�[�^�擾����
                           OTTA.attribute1 = '1'                                    --'1:�o��'
                      -- �o�׃w�b�_�f�[�^�擾����
                      AND  XOHA.latest_external_flag = 'Y'                          --�ŐV�t���O
                      AND  XOHA.order_type_id = OTTA.transaction_type_id
                      AND  XOHA.req_status = '04'                                   --�o�׎��ьv��ς̂�
                      -- �o�ז��׃f�[�^�擾����
                      AND  NVL(XOLA.delete_flag, 'N') <> 'Y'
                      AND  XOHA.order_header_id = XOLA.order_header_id
                      -- �z��NO�P�ʐύڏd�ʍ��v�擾����
                      AND  XOHA.delivery_no = XCS.delivery_no
                      -- �^���w�b�_�A�h�I�����擾����
                      AND  XOHA.delivery_no = XDLV.delivery_no
                      -- �󒍃^�C�v���擾����
                      AND  OTTT.language(+) = 'JA'
                      AND  XOHA.order_type_id = OTTT.transaction_type_id(+)
                )  DELV
               ,xxskz_cust_accounts2_v          XCAV     --SKYLINK�p����VIEW �ڋq���VIEW2(�Ǌ����_)
               ,xxskz_carriers2_v               XCRV     --SKYLINK�p����VIEW �^���Ǝҏ��VIEW2(�^���ƎҖ�)
               ,xxskz_party_sites2_v            XPSV     --SKYLINK�p����VIEW �z������VIEW2(�z���於)
               ,xxskz_item_locations2_v         XILV     --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(�o�Ɍ���)
               ,xxskz_item_mst2_v               ITEM     --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�i�ڏ��)
               ,fnd_lookup_values               FLV01    --�N�C�b�N�R�[�h(�X�e�[�^�X��)
               ,fnd_lookup_values               FLV02    --�N�C�b�N�R�[�h(�z���敪��)
         WHERE
           -- �Ǌ����_���擾����
                DELV.head_sales_branch = XCAV.party_number(+)
           AND  DELV.arrival_date >= XCAV.start_date_active(+)
           AND  DELV.arrival_date <= XCAV.end_date_active(+)
           -- �^���Ǝ�_���і��擾����
           AND  DELV.freight_carrier_id = XCRV.party_id(+)
           AND  DELV.arrival_date >= XCRV.start_date_active(+)
           AND  DELV.arrival_date <= XCRV.end_date_active(+)
           -- �o��_�z���於�擾����
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
--           AND  DELV.deliver_to_id = XPSV.party_site_id(+)
           AND  DELV.deliver_to    = XPSV.party_site_number(+)
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
           AND  DELV.arrival_date >= XPSV.start_date_active(+)
           AND  DELV.arrival_date <= XPSV.end_date_active(+)
           -- �o�Ɍ����擾����
           AND  DELV.deliver_from_id = XILV.inventory_location_id(+)
           -- �o�וi�ڏ��擾����
--         AND  DELV.shipping_item_code = ITEM.item_no(+)
           AND  DELV.request_item_code  = ITEM.item_no(+)
           AND  DELV.arrival_date >= ITEM.start_date_active(+)
           AND  DELV.arrival_date <= ITEM.end_date_active(+)
           -- �X�e�[�^�X��
           AND  FLV01.language(+)    = 'JA'
           AND  FLV01.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'
           AND  FLV01.lookup_code(+) = DELV.req_status
           -- �z���敪��
           AND  FLV02.language(+)    = 'JA'
           AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
           AND  FLV02.lookup_code(+) = DELV.shipping_method_code
           -- �ύڏd�ʍ��v���[���ȏ�̂�
           AND  NVL( DELV.sum_loading_weight, 0 ) > 0
        UNION ALL
        --=========================================================
        -- �o�׃f�[�^�i�ύڏd�ʍ��v�[���̂݁y�ύڏd�ʃ[���ŉ^������������ꍇ������ׁz�j
        --=========================================================
        SELECT
                DELV.delivery_no                    delivery_no                     --�z��No
               ,DELV.request_no                     req_mov_no                      --�˗�_�ړ�No
               ,'�o��'                              kbn                             --�敪
               ,DELV.order_type_name                order_type                      --�󒍃^�C�v
               ,DELV.req_status                     status                          --�X�e�[�^�X
               ,FLV01.meaning                       status_name                     --�X�e�[�^�X��
               ,DELV.head_sales_branch              branch                          --�Ǌ����_
               ,XCAV.party_name                     branch_name                     --�Ǌ����_��
               ,DELV.freight_carrier_code           carrier_code                    --�^���Ǝ�
               ,XCRV.party_name                     carrier_name                    --�^���ƎҖ�
               ,XCRV.party_short_name               carrier_short_name              --�^���Ǝҗ���
               ,DELV.deliver_to                     ship_deliver_to                 --���ɐ�_�z����
               ,XPSV.party_site_name                ship_deliver_to_name            --���ɐ�_�z���於
               ,XPSV.party_site_short_name          ship_deliver_to_short_name      --���ɐ�_�z���旪��
               ,DELV.deliver_from                   ship_from                       --�o�Ɍ�
               ,XILV.description                    ship_from_name                  --�o�Ɍ���
               ,XILV.short_name                     ship_from_short_name            --�o�Ɍ�����
               ,DELV.shipping_method_code           ship_method_code                --�z���敪
               ,FLV02.meaning                       ship_method_name                --�z���敪��
               ,DELV.shipped_date                   shipped_date                    --�o�ɓ�
               ,DELV.arrival_date                   arrival_date                    --���ɓ�
               ,ITEM.item_id                        item_id                         --�i��ID
               ,ITEM.item_no                        item_code                       --�i�ڃR�[�h
               ,ITEM.item_name                      item_name                       --�i�ږ���
               ,ITEM.item_short_name                item_short_name                 --�i�ڗ���
               ,DELV.shipped_quantity               quantity                        --�i�ڃo����
               ,NVL( DELV.shipped_quantity / ITEM.num_of_cases, 0 )
                                                    cs_quantity                     --�i�ڃP�[�X��
               ,NVL( DELV.qty1, 0 )                 sum_cs_quantity                 --���v�P�[�X��
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.sum_loading_weight)      sum_loading_weight            --�ύڏd�ʍ��v
               ,CEIL(TRUNC(NVL(DELV.sum_loading_weight,0),1))      
                                                    sum_loading_weight              --�ύڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_sum_loading_weight  distribute_sum_loading_weight   --���v�Z�p_�ύڏd�ʍ��v
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.weight)                  item_weight                   --�i�ڏd�ʍ��v
               ,CEIL(TRUNC(NVL(DELV.weight,0),1))   item_weight                     --�i�ڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_item_weight         distribute_item_weight          --���v�Z�p_�i�ڏd�ʍ��v
               --�z���P�ʂƕi�ڒP�ʂ̉^��
               --�^��������ꍇ�A�z���P�ʂ̍ő�˗�NO�̍ő喾�הԍ��ɃZ�b�g����
               ,CASE WHEN DELV.req_mov_line = DELV.request_no || LPAD(order_line_number, 5, '0')
                     THEN NVL( DELV.total_amount      , 0 )
                     ELSE 0
                END                                 total_amount                     --���v���z
               ,CASE WHEN DELV.req_mov_line = DELV.request_no || LPAD(order_line_number, 5, '0')
                     THEN NVL( DELV.total_amount      , 0 )
                     ELSE 0
                END                                 item_total_amount                --�i��_���v���z
          FROM  (  --�Ώۃf�[�^�𒊏o
                   SELECT  XOHA.delivery_no                                          --�z��No
                          ,XOHA.request_no                                           --�˗�_�ړ�No
                          ,XOLA.order_line_number                                    --���הԍ�
                          ,XOHA.order_type_id                                        --�󒍃^�C�v
                          ,OTTT.name                         order_type_name         --�󒍃^�C�v��
                          ,XOHA.req_status                                           --�X�e�[�^�X
                          ,XOHA.head_sales_branch                                    --�Ǌ����_
                          ,XOHA.result_freight_carrier_id    freight_carrier_id      --�^���Ǝ�ID
                          ,XOHA.result_freight_carrier_code  freight_carrier_code    --�^���Ǝ�
                          ,XOHA.result_deliver_to_id         deliver_to_id           --�o��_�z����ID
                          ,XOHA.result_deliver_to            deliver_to              --�o��_�z����
                          ,XOHA.deliver_from_id                                      --�o�Ɍ�ID
                          ,XOHA.deliver_from                                         --�o�Ɍ�
                          ,XOHA.result_shipping_method_code  shipping_method_code    --�z���敪
                          ,XOHA.shipped_date                                         --�o�ɓ�
                          ,XOHA.arrival_date                                         --���ɓ�
--                        ,XOLA.shipping_item_code                                   --�o�וi�ڃR�[�h
                          ,XOLA.request_item_code                                    --�˗��i�ڃR�[�h
                          ,XOLA.shipped_quantity                                     --�i��_����
                          ,XCS.sum_loading_weight            sum_loading_weight      --�z��_�ύڏd�ʍ��v
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --�z��_���v�Z�p_�ύڏd�ʍ��v
                          ,XOLA.weight                                               --�i�ڏd�ʍ��v
                          ,XOLA.weight                       distribute_item_weight  --���v�Z�p_�i�ڏd�ʍ��v
                          ,RML.req_mov_line                                          --�ő�˗��E���הԍ�
                           --�z��No���̕i�ڏd�ʊ����i�i��_�d�ʍ��v �� �z��_�d�ʍ��v�j
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XOLA.weight / XCS.sum_loading_weight
                           END                               item_rate               --�z��No���̕i�ڏd�ʊ���
                           --�z���P�ʂ̉^��
                          ,XDLV.qty1                                                 --�z��_���P
                          ,XDLV.total_amount                                         --�z��_���v���z
                     FROM  xxcmn_order_headers_all_arc         XOHA                      --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                          ,oe_transaction_types_all        OTTA                      --�󒍃^�C�v�}�X�^
                          ,oe_transaction_types_tl         OTTT                      --�󒍃^�C�v���}�X�^
                          ,xxcmn_order_lines_all_arc           XOLA                      --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                          ,(    -- �z��NO�P�ʂ̐ύڏd�ʍ��v�Z�o
                            SELECT delivery_no                                       --�z��NO
                                  ,SUM(sum_weight)   sum_loading_weight              --�ύڏd�ʍ��v
                              FROM (SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_order_headers_all_arc               --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                     WHERE latest_external_flag = 'Y'
                                    UNION ALL
                                    SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_mov_req_instr_hdrs_arc              --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                   )
                            GROUP BY delivery_no
                           )                               XCS                       --�z��NO�P�ʐύڏd�ʍ��v
                          ,(
                            SELECT XD1.delivery_no                                   --�z��NO
                                  ,XD1.qty1                                          --�z��_���P
                                  ,XD1.total_amount                                  --�z��_���v���z
                              FROM xxwip_deliverys XD1
                             WHERE XD1.p_b_classe = '2'                              --'2:�����^��'
                            UNION ALL
                            SELECT XD2.delivery_no                                   --�z��NO
                                  ,XD2.qty1                                          --�z��_���P
                                  ,0                                                 --�z��_���v���z
                              FROM xxwip_deliverys XD2
                             WHERE XD2.p_b_classe = '1'                              --'1:�x���^��'
                               -- �x�������敪��'1':�x���^���̂�
                               AND NOT EXISTS
                                   (
                                    SELECT 'X'
                                      FROM xxwip_deliverys XD3
                                      WHERE XD3.p_b_classe = '2'                     --'2:�����^��'
                                        AND XD3.delivery_no = XD2.delivery_no
                                   )
                           )                               XDLV                      --�^���w�b�_�A�h�I��
                          ,(    -- �z��NO�P�ʂ̍ő�˗�NO�A�ő喾�הԍ��擾
                            SELECT delivery_no
                                  ,req_mov_line
                              FROM (SELECT OH.delivery_no
                                          ,MAX(OH.request_no || LPAD(OL.order_line_number, 5, '0')) req_mov_line
                                      FROM xxcmn_order_headers_all_arc  OH  --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                          ,xxcmn_order_lines_all_arc    OL   --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                                     WHERE OH.order_header_id = OL.order_header_id
                                       AND OH.latest_external_flag = 'Y'
                                       AND NVL(OL.delete_flag, 'N') <> 'Y'
                                    GROUP BY OH.delivery_no
                                    UNION ALL
                                    SELECT MH.delivery_no
                                          ,MAX(MH.mov_num || LPAD(ML.line_number, 5, '0')) req_mov_line
                                      FROM xxcmn_mov_req_instr_hdrs_arc    MH          --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                          ,xxcmn_mov_req_instr_lines_arc   ML        --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                                     WHERE MH.mov_hdr_id = ML.mov_hdr_id
                                       AND NVL( ML.delete_flg, 'N' ) <> 'Y'          --�������׈ȊO
                                    GROUP BY MH.delivery_no
                                   )
                           )                               RML                       --�z��NO�P�ʂ̍ő�˗��E���הԍ����
                    WHERE
                      -- �o�׃f�[�^�擾����
                           OTTA.attribute1 = '1'                                     --'1:�o��'
                      -- �o�׃w�b�_�f�[�^�擾����
                      AND  XOHA.latest_external_flag = 'Y'                           --�ŐV�t���O
                      AND  XOHA.order_type_id = OTTA.transaction_type_id
                      AND  XOHA.req_status = '04'                                    --�o�׎��ьv��ς̂�
                      -- �o�ז��׃f�[�^�擾����
                      AND  NVL(XOLA.delete_flag, 'N') <> 'Y'
                      AND  XOHA.order_header_id = XOLA.order_header_id
                      -- �z��NO�P�ʐύڏd�ʍ��v�擾����
                      AND  XOHA.delivery_no = XCS.delivery_no
                      -- �^���w�b�_�A�h�I�����擾����
                      AND  XOHA.delivery_no = XDLV.delivery_no
                      -- �z��NO�P�ʍő�˗��E���הԍ��擾����
                      AND  XOHA.delivery_no = RML.delivery_no
                      -- �󒍃^�C�v���擾����
                      AND  OTTT.language(+) = 'JA'
                      AND  XOHA.order_type_id = OTTT.transaction_type_id(+)
                )  DELV
               ,xxskz_cust_accounts2_v          XCAV     --SKYLINK�p����VIEW �ڋq���VIEW2(�Ǌ����_)
               ,xxskz_carriers2_v               XCRV     --SKYLINK�p����VIEW �^���Ǝҏ��VIEW2(�^���ƎҖ�)
               ,xxskz_party_sites2_v            XPSV     --SKYLINK�p����VIEW �z������VIEW2(�z���於)
               ,xxskz_item_locations2_v         XILV     --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(�o�Ɍ���)
               ,xxskz_item_mst2_v               ITEM     --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�i�ڏ��)
               ,fnd_lookup_values               FLV01    --�N�C�b�N�R�[�h(�X�e�[�^�X��)
               ,fnd_lookup_values               FLV02    --�N�C�b�N�R�[�h(�z���敪��)
         WHERE
           -- �Ǌ����_���擾����
                DELV.head_sales_branch = XCAV.party_number(+)
           AND  DELV.arrival_date >= XCAV.start_date_active(+)
           AND  DELV.arrival_date <= XCAV.end_date_active(+)
           -- �^���Ǝ�_���і��擾����
           AND  DELV.freight_carrier_id = XCRV.party_id(+)
           AND  DELV.arrival_date >= XCRV.start_date_active(+)
           AND  DELV.arrival_date <= XCRV.end_date_active(+)
           -- �o��_�z���於�擾����
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
--           AND  DELV.deliver_to_id = XPSV.party_site_id(+)
           AND  DELV.deliver_to    = XPSV.party_site_number(+)
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
           AND  DELV.arrival_date >= XPSV.start_date_active(+)
           AND  DELV.arrival_date <= XPSV.end_date_active(+)
           -- �o�Ɍ����擾����
           AND  DELV.deliver_from_id = XILV.inventory_location_id(+)
           -- �o�וi�ڏ��擾����
--         AND  DELV.shipping_item_code = ITEM.item_no(+)
           AND  DELV.request_item_code  = ITEM.item_no(+)
           AND  DELV.arrival_date >= ITEM.start_date_active(+)
           AND  DELV.arrival_date <= ITEM.end_date_active(+)
           -- �X�e�[�^�X��
           AND  FLV01.language(+)    = 'JA'
           AND  FLV01.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'
           AND  FLV01.lookup_code(+) = DELV.req_status
           -- �z���敪��
           AND  FLV02.language(+)    = 'JA'
           AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
           AND  FLV02.lookup_code(+) = DELV.shipping_method_code
           -- �ύڏd�ʍ��v���[���̂�
           AND  NVL( DELV.sum_loading_weight, 0 ) = 0
-- 2009.01.21��
        UNION ALL
        --=========================================================
        -- �o�׃f�[�^�i�^���A�h�I���ɑ��݂��Ȃ����́j
        --=========================================================
        SELECT
                DELV.delivery_no                    delivery_no                     --�z��No
               ,DELV.request_no                     req_mov_no                      --�˗�_�ړ�No
               ,'�o��'                              kbn                             --�敪
               ,DELV.order_type_name                order_type                      --�󒍃^�C�v
               ,DELV.req_status                     status                          --�X�e�[�^�X
               ,FLV01.meaning                       status_name                     --�X�e�[�^�X��
               ,DELV.head_sales_branch              branch                          --�Ǌ����_
               ,XCAV.party_name                     branch_name                     --�Ǌ����_��
               ,DELV.freight_carrier_code           carrier_code                    --�^���Ǝ�
               ,XCRV.party_name                     carrier_name                    --�^���ƎҖ�
               ,XCRV.party_short_name               carrier_short_name              --�^���Ǝҗ���
               ,DELV.deliver_to                     ship_deliver_to                 --���ɐ�_�z����
               ,XPSV.party_site_name                ship_deliver_to_name            --���ɐ�_�z���於
               ,XPSV.party_site_short_name          ship_deliver_to_short_name      --���ɐ�_�z���旪��
               ,DELV.deliver_from                   ship_from                       --�o�Ɍ�
               ,XILV.description                    ship_from_name                  --�o�Ɍ���
               ,XILV.short_name                     ship_from_short_name            --�o�Ɍ�����
               ,DELV.shipping_method_code           ship_method_code                --�z���敪
               ,FLV02.meaning                       ship_method_name                --�z���敪��
               ,DELV.shipped_date                   shipped_date                    --�o�ɓ�
               ,DELV.arrival_date                   arrival_date                    --���ɓ�
               ,ITEM.item_id                        item_id                         --�i��ID
               ,ITEM.item_no                        item_code                       --�i�ڃR�[�h
               ,ITEM.item_name                      item_name                       --�i�ږ���
               ,ITEM.item_short_name                item_short_name                 --�i�ڗ���
               ,DELV.shipped_quantity               quantity                        --�i�ڃo����
               ,NVL( DELV.shipped_quantity / ITEM.num_of_cases, 0 )
                                                    cs_quantity                     --�i�ڃP�[�X��
--             ,NVL( DELV.qty1 / ITEM.num_of_cases, 0 )
--                                                  sum_cs_quantity                 --���v�P�[�X��
               ,DELV.qty1                           sum_cs_quantity                 --���v�P�[�X��
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.sum_loading_weight)      sum_loading_weight              --�ύڏd�ʍ��v
               ,CEIL(TRUNC(NVL(DELV.sum_loading_weight,0),1))      
                                                    sum_loading_weight              --�ύڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_sum_loading_weight  distribute_sum_loading_weight   --���v�Z�p_�ύڏd�ʍ��v
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.weight)                  item_weight                     --�i�ڏd�ʍ��v
               ,CEIL(TRUNC(NVL(DELV.weight,0),1))   item_weight                     --�i�ڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_item_weight         distribute_item_weight          --���v�Z�p_�i�ڏd�ʍ��v
               ,0                                   total_amount                    --���v���z
               ,0                                   item_total_amount               --�i��_���v���z
          FROM  (  --�Ώۃf�[�^�𒊏o
                   SELECT  XOHA.delivery_no                                          --�z��No
                          ,XOHA.request_no                                           --�˗�_�ړ�No
                          ,XOLA.order_line_number                                    --���הԍ�
                          ,XOHA.order_type_id                                        --�󒍃^�C�v
                          ,OTTT.name                         order_type_name         --�󒍃^�C�v��
                          ,XOHA.req_status                                           --�X�e�[�^�X
                          ,XOHA.head_sales_branch                                    --�Ǌ����_
                          ,XOHA.result_freight_carrier_id    freight_carrier_id      --�^���Ǝ�ID
                          ,XOHA.result_freight_carrier_code  freight_carrier_code    --�^���Ǝ�
                          ,XOHA.result_deliver_to_id         deliver_to_id           --�o��_�z����ID
                          ,XOHA.result_deliver_to            deliver_to              --�o��_�z����
                          ,XOHA.deliver_from_id                                      --�o�Ɍ�ID
                          ,XOHA.deliver_from                                         --�o�Ɍ�
                          ,XOHA.result_shipping_method_code  shipping_method_code    --�z���敪
                          ,XOHA.shipped_date                                         --�o�ɓ�
                          ,XOHA.arrival_date                                         --���ɓ�
--                        ,XOLA.shipping_item_code                                   --�o�וi�ڃR�[�h
                          ,XOLA.request_item_code                                    --�˗��i�ڃR�[�h
                          ,XOLA.shipped_quantity                                     --�i��_����
                          ,XCS.sum_loading_weight            sum_loading_weight      --�z��_�ύڏd�ʍ��v
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --�z��_���v�Z�p_�ύڏd�ʍ��v
                          ,XOLA.weight                                               --�i�ڏd�ʍ��v
                          ,XOLA.weight                       distribute_item_weight  --���v�Z�p_�i�ڏd�ʍ��v
                           --�z��No���̕i�ڏd�ʊ����i�i��_�d�ʍ��v �� �z��_�d�ʍ��v�j
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XOLA.weight / XCS.sum_loading_weight
                           END                               item_rate               --�z��No���̕i�ڏd�ʊ���
                           --�z���P�ʂ̉^��
                          ,XCS.sum_loading_quantity          qty1                    --���P
                     FROM  xxcmn_order_headers_all_arc         XOHA                      --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                          ,oe_transaction_types_all        OTTA                      --�󒍃^�C�v�}�X�^
                          ,oe_transaction_types_tl         OTTT                      --�󒍃^�C�v���}�X�^
                          ,xxcmn_order_lines_all_arc           XOLA                      --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                          ,(    -- �z��NO�P�ʂ̐ύڏd�ʍ��v�Z�o
                            SELECT delivery_no                                       --�z��NO
                                  ,SUM(sum_quantity) sum_loading_quantity
                                  ,SUM(sum_weight)   sum_loading_weight              --�ύڏd�ʍ��v
                              FROM (
                                    SELECT delivery_no
                                          ,NVL(shipped_quantity / ITEM11.num_of_cases, 0)  sum_quantity
                                          ,weight                                          sum_weight
                                      FROM (
                                            SELECT XOHA.delivery_no
                                                  ,XOHA.arrival_date
--                                                ,XOLA.shipping_item_code
                                                  ,XOLA.request_item_code
                                                  ,XOLA.shipped_quantity
                                                  ,XOLA.weight
                                              FROM xxcmn_order_headers_all_arc  XOHA,  --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                                   xxcmn_order_lines_all_arc    XOLA  --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                                             WHERE NVL(XOLA.delete_flag, 'N') <> 'Y'
                                               AND XOHA.order_header_id = XOLA.order_header_id
                                               AND XOHA.delivery_no IS NOT NULL
                                               AND XOHA.latest_external_flag = 'Y'
                                               AND XOHA.req_status = '04'
                                           )  XOHA11,
                                           xxskz_item_mst2_v   ITEM11
--                                   WHERE XOHA11.shipping_item_code = ITEM11.item_no(+)
                                     WHERE XOHA11.request_item_code  = ITEM11.item_no(+)
                                       AND XOHA11.arrival_date >= ITEM11.start_date_active(+)
                                       AND XOHA11.arrival_date <= ITEM11.end_date_active(+)
                                       AND XOHA11.delivery_no IS NOT NULL
                                    UNION ALL
                                    SELECT delivery_no
                                          ,NVL(shipped_quantity / ITEM11.num_of_cases, 0)  sum_quantity
                                          ,weight                                          sum_weight
                                      FROM (
                                            SELECT XMRH11.delivery_no
                                                  ,XMRH11.actual_arrival_date
                                                  ,XMRL11.item_code
                                                  ,XMRL11.shipped_quantity
                                                  ,XMRL11.weight
                                              FROM xxcmn_mov_req_instr_hdrs_arc   XMRH11   --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                                  ,xxcmn_mov_req_instr_lines_arc   XMRL11  --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                                             WHERE NVL(XMRL11.delete_flg, 'N') <> 'Y'
                                               AND XMRH11.mov_hdr_id = XMRL11.mov_hdr_id
                                               AND XMRH11.delivery_no IS NOT NULL
                                           )  XMR11,
                                           xxskz_item_mst2_v   ITEM11
                                     WHERE XMR11.item_code = ITEM11.item_no(+)
                                       AND XMR11.actual_arrival_date >= ITEM11.start_date_active(+)
                                       AND XMR11.actual_arrival_date <= ITEM11.end_date_active(+)
                                       AND XMR11.delivery_no IS NOT NULL
                                   )
                            GROUP BY delivery_no
                           )                               XCS                       --�z��NO�P�ʐύڏd�ʍ��v
                    WHERE
                      -- �o�׃f�[�^�擾����
                           OTTA.attribute1 = '1'                                     --'1:�o��'
                      AND  OTTA.attribute4 = '1'
                      -- �o�׃w�b�_�f�[�^�擾����
                      AND  XOHA.latest_external_flag = 'Y'                           --�ŐV�t���O
                      AND  XOHA.order_type_id = OTTA.transaction_type_id
                      AND  XOHA.req_status = '04'                                    --�o�׎��ьv��ς̂�
                      -- �o�ז��׃f�[�^�擾����
                      AND  NVL(XOLA.delete_flag, 'N') <> 'Y'
                      AND  XOHA.order_header_id = XOLA.order_header_id
                      -- �z��NO�P�ʐύڏd�ʍ��v�擾����
                      AND  XOHA.delivery_no = XCS.delivery_no
                      -- �󒍃^�C�v���擾����
                      AND  OTTT.language(+) = 'JA'
                      AND  XOHA.order_type_id = OTTT.transaction_type_id(+)
                      AND  NOT EXISTS(SELECT 'X' FROM xxwip_deliverys VD11
                                       WHERE VD11.delivery_no = XOHA.delivery_no
                                     )
                      AND  XOHA.delivery_no IS NOT NULL
                   UNION
                   SELECT  XOHA2.delivery_no                                          --�z��No
                          ,XOHA2.request_no                                           --�˗�_�ړ�No
                          ,XOLA2.order_line_number                                    --���הԍ�
                          ,XOHA2.order_type_id                                        --�󒍃^�C�v
                          ,OTTT2.name                         order_type_name         --�󒍃^�C�v��
                          ,XOHA2.req_status                                           --�X�e�[�^�X
                          ,XOHA2.head_sales_branch                                    --�Ǌ����_
                          ,XOHA2.result_freight_carrier_id    freight_carrier_id      --�^���Ǝ�ID
                          ,XOHA2.result_freight_carrier_code  freight_carrier_code    --�^���Ǝ�
                          ,XOHA2.result_deliver_to_id         deliver_to_id           --�o��_�z����ID
                          ,XOHA2.result_deliver_to            deliver_to              --�o��_�z����
                          ,XOHA2.deliver_from_id                                      --�o�Ɍ�ID
                          ,XOHA2.deliver_from                                         --�o�Ɍ�
                          ,XOHA2.result_shipping_method_code  shipping_method_code    --�z���敪
                          ,XOHA2.shipped_date                                         --�o�ɓ�
                          ,XOHA2.arrival_date                                         --���ɓ�
--                        ,XOLA2.shipping_item_code                                   --�o�וi�ڃR�[�h
                          ,XOLA2.request_item_code                                    --�˗��i�ڃR�[�h
                          ,XOLA2.shipped_quantity                                     --�i��_����
                          ,XCS2.sum_loading_weight            sum_loading_weight      --�z��_�ύڏd�ʍ��v
                          ,XCS2.sum_loading_weight            distribute_sum_loading_weight      --�z��_���v�Z�p_�ύڏd�ʍ��v
                          ,XOLA2.weight                                               --�i�ڏd�ʍ��v
                          ,XOLA2.weight                       distribute_item_weight  --���v�Z�p_�i�ڏd�ʍ��v
                           --�z��No���̕i�ڏd�ʊ����i�i��_�d�ʍ��v �� �z��_�d�ʍ��v�j
                          ,CASE WHEN XCS2.sum_loading_weight = 0 THEN 0
                                ELSE XOLA2.weight / XCS2.sum_loading_weight
                           END                               item_rate               --�z��No���̕i�ڏd�ʊ���
                           --�z���P�ʂ̉^��
                          ,XCS2.sum_loading_quantity          qty1                    --���P
                     FROM  xxcmn_order_headers_all_arc         XOHA2                     --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                          ,oe_transaction_types_all        OTTA2                     --�󒍃^�C�v�}�X�^
                          ,oe_transaction_types_tl         OTTT2                     --�󒍃^�C�v���}�X�^
                          ,xxcmn_order_lines_all_arc           XOLA2                     --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                          ,(    -- �˗�NO�P�ʂ̐ύڏd�ʍ��v�Z�o
                            SELECT request_no                                        --�˗�NO
                                  ,SUM(sum_quantity) sum_loading_quantity
                                  ,SUM(sum_weight)   sum_loading_weight              --�ύڏd�ʍ��v
                              FROM (
                                   SELECT request_no
                                          ,NVL(shipped_quantity / ITEM11.num_of_cases, 0)  sum_quantity
                                          ,weight                                          sum_weight
                                      FROM (
                                            SELECT XOHA.request_no
                                                  ,XOHA.arrival_date
--                                                ,XOLA.shipping_item_code
                                                  ,XOLA.request_item_code
                                                  ,XOLA.shipped_quantity
                                                  ,XOLA.weight
                                              FROM xxcmn_order_headers_all_arc  XOHA,  --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                                   xxcmn_order_lines_all_arc   XOLA  --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                                             WHERE NVL(XOLA.delete_flag, 'N') <> 'Y'
                                               AND XOHA.order_header_id = XOLA.order_header_id
                                               AND XOHA.delivery_no IS NULL
                                               AND XOHA.latest_external_flag = 'Y'
                                               AND XOHA.req_status = '04'
                                           )  XOHA11,
                                           xxskz_item_mst2_v   ITEM11
--                                   WHERE XOHA11.shipping_item_code = ITEM11.item_no(+)
                                     WHERE XOHA11.request_item_code  = ITEM11.item_no(+)
                                       AND XOHA11.arrival_date >= ITEM11.start_date_active(+)
                                       AND XOHA11.arrival_date <= ITEM11.end_date_active(+)
                                   )
                            GROUP BY request_no
                           )     �@                          XCS2                      --�˗�NO�P�ʐύڏd�ʍ��v
                    WHERE
                      -- �o�׃f�[�^�擾����
                           OTTA2.attribute1 = '1'                                     --'1:�o��'
                      AND  OTTA2.attribute4 = '1'
                      -- �o�׃w�b�_�f�[�^�擾����
                      AND  XOHA2.latest_external_flag = 'Y'                           --�ŐV�t���O
                      AND  XOHA2.order_type_id = OTTA2.transaction_type_id
                      AND  XOHA2.req_status = '04'                                    --�o�׎��ьv��ς̂�
                      -- �o�ז��׃f�[�^�擾����
                      AND  NVL(XOLA2.delete_flag, 'N') <> 'Y'
                      AND  XOHA2.order_header_id = XOLA2.order_header_id
                      -- �˗�NO�P�ʐύڏd�ʍ��v�擾����
                      AND  XOHA2.request_no = XCS2.request_no
                      -- �󒍃^�C�v���擾����
                      AND  OTTT2.language(+) = 'JA'
                      AND  XOHA2.order_type_id = OTTT2.transaction_type_id(+)
                      AND  NOT EXISTS(SELECT 'X' FROM xxwip_deliverys VD11
                                       WHERE VD11.delivery_no = XOHA2.delivery_no
                                     )
                      AND  XOHA2.delivery_no IS NULL
                )  DELV
               ,xxskz_cust_accounts2_v          XCAV     --SKYLINK�p����VIEW �ڋq���VIEW2(�Ǌ����_)
               ,xxskz_carriers2_v               XCRV     --SKYLINK�p����VIEW �^���Ǝҏ��VIEW2(�^���ƎҖ�)
               ,xxskz_party_sites2_v            XPSV     --SKYLINK�p����VIEW �z������VIEW2(�z���於)
               ,xxskz_item_locations2_v         XILV     --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(�o�Ɍ���)
               ,xxskz_item_mst2_v               ITEM     --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�i�ڏ��)
               ,fnd_lookup_values               FLV01    --�N�C�b�N�R�[�h(�X�e�[�^�X��)
               ,fnd_lookup_values               FLV02    --�N�C�b�N�R�[�h(�z���敪��)
         WHERE
           -- �Ǌ����_���擾����
                DELV.head_sales_branch = XCAV.party_number(+)
           AND  DELV.arrival_date >= XCAV.start_date_active(+)
           AND  DELV.arrival_date <= XCAV.end_date_active(+)
           -- �^���Ǝ�_���і��擾����
           AND  DELV.freight_carrier_id = XCRV.party_id(+)
           AND  DELV.arrival_date >= XCRV.start_date_active(+)
           AND  DELV.arrival_date <= XCRV.end_date_active(+)
           -- �o��_�z���於�擾����
-- *----------* 2009/06/23 �{��#1438�Ή� start *----------*
--           AND  DELV.deliver_to_id = XPSV.party_site_id(+)
           AND  DELV.deliver_to    = XPSV.party_site_number(+)
-- *----------* 2009/06/23 �{��#1438�Ή� end   *----------*
           AND  DELV.arrival_date >= XPSV.start_date_active(+)
           AND  DELV.arrival_date <= XPSV.end_date_active(+)
           -- �o�Ɍ����擾����
           AND  DELV.deliver_from_id = XILV.inventory_location_id(+)
           -- �o�וi�ڏ��擾����
--         AND  DELV.shipping_item_code = ITEM.item_no(+)
           AND  DELV.request_item_code  = ITEM.item_no(+)
           AND  DELV.arrival_date >= ITEM.start_date_active(+)
           AND  DELV.arrival_date <= ITEM.end_date_active(+)
           -- �X�e�[�^�X��
           AND  FLV01.language(+)    = 'JA'
           AND  FLV01.lookup_type(+) = 'XXWSH_TRANSACTION_STATUS'
           AND  FLV01.lookup_code(+) = DELV.req_status
           -- �z���敪��
           AND  FLV02.language(+)    = 'JA'
           AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
           AND  FLV02.lookup_code(+) = DELV.shipping_method_code
-- 2009.01.21��
        UNION ALL
        --=========================================================
        -- �ړ��f�[�^
        --=========================================================
        SELECT
                DELV.delivery_no                    delivery_no                     --�z��No
               ,DELV.mov_num                        req_mov_no                      --�˗�_�ړ�No
               ,'�ړ�'                              kbn                             --�敪
               ,NULL                                order_type                      --�󒍃^�C�v
               ,DELV.status                         status                          --�X�e�[�^�X
               ,FLV01.meaning                       status_name                     --�X�e�[�^�X��
               ,'2100'                              branch                          --�Ǌ����_
               ,XL2V.location_name                  branch_name                     --�Ǌ����_��
               ,DELV.freight_carrier_code           carrier_code                    --�^���Ǝ�
               ,XCRV.party_name                     carrier_name                    --�^���ƎҖ�
               ,XCRV.party_short_name               carrier_short_name              --�^���Ǝҗ���
               ,DELV.ship_to_locat_code             ship_deliver_to                 --���ɐ�_�z����
               ,XILV1.description                   ship_deliver_to_name            --���ɐ�_�z���於
               ,XILV1.short_name                    ship_deliver_to_short_name      --���ɐ�_�z���旪��
               ,DELV.shipped_locat_code             ship_from                       --�o�Ɍ�
               ,XILV2.description                   ship_from_name                  --�o�Ɍ���
               ,XILV2.short_name                    ship_from_short_name            --�o�Ɍ�����
               ,DELV.shipping_method_code           ship_method_code                --�z���敪
               ,FLV02.meaning                       ship_method_name                --�z���敪��
               ,DELV.shipped_date                   shipped_date                    --�o�ɓ�
               ,DELV.arrival_date                   arrival_date                    --���ɓ�
               ,ITEM.item_id                        item_id                         --�i��ID
               ,DELV.item_code                      item_code                       --�i�ڃR�[�h
               ,ITEM.item_name                      item_name                       --�i�ږ���
               ,ITEM.item_short_name                item_short_name                 --�i�ڗ���
               ,DELV.quantity                       quantity                        --�i��_�o����
               ,NVL( DELV.quantity / ITEM.num_of_cases, 0 )
                                                    cs_quantity                     --�i��_�P�[�X��
               ,NVL( DELV.qty1, 0 )                 sum_cs_quantity                 --���v�P�[�X��
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.sum_loading_weight)      sum_loading_weight              --�z��_�ύڏd�ʍ��v
               ,CEIL(TRUNC(NVL(DELV.sum_loading_weight,0),1))      
                                                    sum_loading_weight              --�ύڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_sum_loading_weight  distribute_sum_loading_weight   --�z��_���v�Z�p_�ύڏd�ʍ��v
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.weight)                  item_weight                     --�i�ڏd�ʍ��v
               ,CEIL(TRUNC(NVL(DELV.weight,0),1))   item_weight                     --�i�ڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_item_weight         distribute_item_weight          --���v�Z�p_�i�ڏd�ʍ��v
               --�z���P�ʂƕi�ڒP�ʂ̉^��
               ,NVL( DELV.total_amount      , 0 )                       total_amount             --���v���z
               ,NVL( ROUND( DELV.total_amount       * item_rate ), 0 )  item_total_amount        --�i��_���v���z
          FROM  (  --�Ώۃf�[�^�𒊏o
                   SELECT  XMRH.delivery_no                                          --�z��No
                          ,XMRH.mov_num                                              --�˗�_�ړ�No
                          ,XMRH.status                                               --�X�e�[�^�X
                          ,XMRH.actual_career_id             freight_carrier_id      --�^���Ǝ�ID
                          ,XMRH.actual_freight_carrier_code  freight_carrier_code    --�^���Ǝ�
                          ,XMRH.ship_to_locat_id                                     --���ɐ�ID
                          ,XMRH.ship_to_locat_code                                   --���ɐ�
                          ,XMRH.shipped_locat_id                                     --�o�Ɍ�ID
                          ,XMRH.shipped_locat_code                                   --�o�Ɍ�
                          ,XMRH.actual_shipping_method_code  shipping_method_code    --�z���敪
                          ,XMRH.actual_ship_date             shipped_date            --�o�ɓ�
                          ,XMRH.actual_arrival_date          arrival_date            --���ɓ�
                          ,XMRL.item_code                                            --�i�ڃR�[�h
--                        ,XMRL.shipped_quantity             quantity                --�i��_����
                          ,XMRL.ship_to_quantity             quantity                --�i��_����
                          ,XCS.sum_loading_weight            sum_loading_weight      --�z��_�ύڏd�ʍ��v
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --�z��_���v�Z�p_�ύڏd�ʍ��v
                          ,XMRL.weight                                               --�i�ڏd�ʍ��v
                          ,XMRL.weight                       distribute_item_weight  --���v�Z�p_�i�ڏd�ʍ��v
                           --�z��No���̕i�ڏd�ʊ����i�i��_�d�ʍ��v �� �z��_�d�ʍ��v�j
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XMRL.weight / XCS.sum_loading_weight
                           END                               item_rate               --�z��No���̕i�ڏd�ʊ���
                           --�z���P�ʂ̉^��
                          ,XDLV.qty1                                                 --�z��_���P
                          ,XDLV.total_amount                                         --�z��_���v���z
                     FROM  xxcmn_mov_req_instr_hdrs_arc     XMRH                     --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                          ,xxcmn_mov_req_instr_lines_arc       XMRL                  --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                          ,(    -- �z��NO�P�ʂ̐ύڏd�ʍ��v�Z�o
                            SELECT delivery_no                                       --�z��NO
                                  ,SUM(sum_weight)   sum_loading_weight              --�ύڏd�ʍ��v
                              FROM (SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_order_headers_all_arc  --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                     WHERE latest_external_flag = 'Y'
                                    UNION ALL
                                    SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_mov_req_instr_hdrs_arc  --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                   )
                            GROUP BY delivery_no
                           )                               XCS                       --�z��NO�P�ʐύڏd�ʍ��v
                          ,(
                            SELECT XD1.delivery_no                                   --�z��NO
                                  ,XD1.qty1                                          --�z��_���P
                                  ,XD1.total_amount                                  --�z��_���v���z
                              FROM xxwip_deliverys XD1
                             WHERE XD1.p_b_classe = '2'                              --'2:�����^��'
                            UNION ALL
                            SELECT XD2.delivery_no                                   --�z��NO
                                  ,XD2.qty1                                          --�z��_���P
                                  ,0                                                 --�z��_���v���z
                              FROM xxwip_deliverys XD2
                             WHERE XD2.p_b_classe = '1'                              --'1:�x���^��'
                               -- �x�������敪��'1':�x���^���̂�
                               AND NOT EXISTS
                                   (
                                    SELECT 'X'
                                      FROM xxwip_deliverys XD3
                                      WHERE XD3.p_b_classe = '2'                     --'2:�����^��'
                                        AND XD3.delivery_no = XD2.delivery_no
                                   )
                           )                               XDLV                      --�^���w�b�_�A�h�I��
                    WHERE
                      -- �ړ��w�b�_�f�[�^�擾����
                           XMRH.status = '06'                                        --���o�ɕ񍐗L�̂�
                      -- �ړ����׃f�[�^�擾����
                      AND  NVL(XMRL.delete_flg, 'N') <> 'Y'
                      AND  XMRH.mov_hdr_id = XMRL.mov_hdr_id
                      -- �z��NO�P�ʐύڏd�ʍ��v�擾����
                      AND  XMRH.delivery_no = XCS.delivery_no
                      -- �^���w�b�_�A�h�I�����擾����
                      AND  XMRH.delivery_no = XDLV.delivery_no
                )  DELV
               ,xxskz_locations2_v              XL2V     --SKYLINK�p����VIEW ���Ə����VIEW2(�Ǌ����_��)
               ,xxskz_carriers2_v               XCRV     --SKYLINK�p����VIEW �^���Ǝҏ��VIEW2(�^���ƎҖ�)
               ,xxskz_item_locations2_v         XILV1    --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(���ɐ於)
               ,xxskz_item_locations2_v         XILV2    --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(�o�Ɍ���)
               ,xxskz_item_mst2_v               ITEM     --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�i�ڏ��)
               ,fnd_lookup_values               FLV01    --�N�C�b�N�R�[�h(�X�e�[�^�X��)
               ,fnd_lookup_values               FLV02    --�N�C�b�N�R�[�h(�z���敪��)
         WHERE
           -- �Ǌ����_���擾����
                XL2V.location_code(+)           = '2100'            -- ������
           AND  XL2V.start_date_active(+)       <= DELV.shipped_date
           AND  XL2V.end_date_active(+)         >= DELV.shipped_date
           -- �^���Ǝ�_���і��擾����
           AND  DELV.freight_carrier_id = XCRV.party_id(+)
           AND  DELV.arrival_date >= XCRV.start_date_active(+)
           AND  DELV.arrival_date <= XCRV.end_date_active(+)
           -- �ړ�_���ɐ於�擾
           AND  DELV.ship_to_locat_id = XILV1.inventory_location_id(+)
           -- �o�Ɍ����擾����
           AND  DELV.shipped_locat_id = XILV2.inventory_location_id(+)
           -- �o�וi�ڏ��擾����
           AND  DELV.item_code = ITEM.item_no(+)
           AND  DELV.arrival_date >= ITEM.start_date_active(+)
           AND  DELV.arrival_date <= ITEM.end_date_active(+)
           -- �X�e�[�^�X��
           AND  FLV01.language(+)    = 'JA'
           AND  FLV01.lookup_type(+) = 'XXINV_MOVE_STATUS'
           AND  FLV01.lookup_code(+) = DELV.status
           -- �z���敪��
           AND  FLV02.language(+)    = 'JA'
           AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
           AND  FLV02.lookup_code(+) = DELV.shipping_method_code
           -- �ύڏd�ʍ��v���[���ȏ�̂�
           AND  NVL( DELV.sum_loading_weight, 0 ) > 0
        UNION ALL
        --=========================================================
        -- �ړ��f�[�^�i�ύڏd�ʍ��v�[���̂݁y�ύڏd�ʃ[���ŉ^������������ꍇ������ׁz�j
        --=========================================================
        SELECT
                DELV.delivery_no                    delivery_no                     --�z��No
               ,DELV.mov_num                        req_mov_no                      --�˗�_�ړ�No
               ,'�ړ�'                              kbn                             --�敪
               ,NULL                                order_type                      --�󒍃^�C�v
               ,DELV.status                         status                          --�X�e�[�^�X
               ,FLV01.meaning                       status_name                     --�X�e�[�^�X��
               ,'2100'                              branch                          --�Ǌ����_
               ,XL2V.location_name                  branch_name                     --�Ǌ����_��
               ,DELV.freight_carrier_code           carrier_code                    --�^���Ǝ�
               ,XCRV.party_name                     carrier_name                    --�^���ƎҖ�
               ,XCRV.party_short_name               carrier_short_name              --�^���Ǝҗ���
               ,DELV.ship_to_locat_code             ship_deliver_to                 --���ɐ�_�z����
               ,XILV1.description                   ship_deliver_to_name            --���ɐ�_�z���於
               ,XILV1.short_name                    ship_deliver_to_short_name      --���ɐ�_�z���旪��
               ,DELV.shipped_locat_code             ship_from                       --�o�Ɍ�
               ,XILV2.description                   ship_from_name                  --�o�Ɍ���
               ,XILV2.short_name                    ship_from_short_name            --�o�Ɍ�����
               ,DELV.shipping_method_code           ship_method_code                --�z���敪
               ,FLV02.meaning                       ship_method_name                --�z���敪��
               ,DELV.shipped_date                   shipped_date                    --�o�ɓ�
               ,DELV.arrival_date                   arrival_date                    --���ɓ�
               ,ITEM.item_id                        item_id                         --�i��ID
               ,DELV.item_code                      item_code                       --�i�ڃR�[�h
               ,ITEM.item_name                      item_name                       --�i�ږ���
               ,ITEM.item_short_name                item_short_name                 --�i�ڗ���
               ,DELV.quantity                       quantity                        --�i��_�o����
               ,NVL( DELV.quantity / ITEM.num_of_cases, 0 )
                                                    cs_quantity                     --�i��_�P�[�X��
               ,NVL( DELV.qty1, 0 )                 sum_cs_quantity                 --���v�P�[�X��
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.sum_loading_weight)      sum_loading_weight              --�z��_�ύڏd�ʍ��v
               ,CEIL(TRUNC(NVL(DELV.sum_loading_weight,0),1))      
                                                    sum_loading_weight              --�ύڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_sum_loading_weight  distribute_sum_loading_weight   --�z��_���v�Z�p_�ύڏd�ʍ��v
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.weight)                  item_weight                     --�i�ڏd�ʍ��v
               ,CEIL(TRUNC(NVL(DELV.weight,0),1))   item_weight                     --�i�ڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_item_weight         distribute_item_weight          --���v�Z�p_�i�ڏd�ʍ��v
               --�z���P�ʂƕi�ڒP�ʂ̉^��
               --�^��������ꍇ�A�z���P�ʂ̍ő�˗�NO�̍ő喾�הԍ��ɃZ�b�g����
               ,CASE WHEN DELV.req_mov_line = DELV.mov_num || LPAD(line_number, 5, '0')
                     THEN NVL( DELV.total_amount      , 0 )
                     ELSE 0
                END                                 total_amount                    --���v���z
               ,CASE WHEN DELV.req_mov_line = DELV.mov_num || LPAD(line_number, 5, '0')
                     THEN NVL( DELV.total_amount      , 0 )
                     ELSE 0
                END                                 item_total_amount               --�i��_���v���z
          FROM  (  --�Ώۃf�[�^�𒊏o
                   SELECT  XMRH.delivery_no                                          --�z��No
                          ,XMRH.mov_num                                              --�˗�_�ړ�No
                          ,XMRL.line_number                                          --���הԍ�
                          ,XMRH.status                                               --�X�e�[�^�X
                          ,XMRH.actual_career_id             freight_carrier_id      --�^���Ǝ�ID
                          ,XMRH.actual_freight_carrier_code  freight_carrier_code    --�^���Ǝ�
                          ,XMRH.ship_to_locat_id                                     --���ɐ�ID
                          ,XMRH.ship_to_locat_code                                   --���ɐ�
                          ,XMRH.shipped_locat_id                                     --�o�Ɍ�ID
                          ,XMRH.shipped_locat_code                                   --�o�Ɍ�
                          ,XMRH.actual_shipping_method_code  shipping_method_code    --�z���敪
                          ,XMRH.actual_ship_date             shipped_date            --�o�ɓ�
                          ,XMRH.actual_arrival_date          arrival_date            --���ɓ�
                          ,XMRL.item_code                                            --�i�ڃR�[�h
--                        ,XMRL.shipped_quantity             quantity                --�i��_����
                          ,XMRL.ship_to_quantity             quantity                --�i��_����
                          ,XCS.sum_loading_weight            sum_loading_weight      --�z��_�ύڏd�ʍ��v
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --�z��_���v�Z�p_�ύڏd�ʍ��v
                          ,XMRL.weight                                               --�i�ڏd�ʍ��v
                          ,XMRL.weight                       distribute_item_weight  --���v�Z�p_�i�ڏd�ʍ��v
                          ,RML.req_mov_line                                          --�ő�˗��E���הԍ�
                           --�z��No���̕i�ڏd�ʊ����i�i��_�d�ʍ��v �� �z��_�d�ʍ��v�j
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XMRL.weight / XCS.sum_loading_weight
                           END                               item_rate               --�z��No���̕i�ڏd�ʊ���
                           --�z���P�ʂ̉^��
                          ,XDLV.qty1                                                 --�z��_���P
                          ,XDLV.total_amount                                         --�z��_���v���z
                     FROM  xxcmn_mov_req_instr_hdrs_arc     XMRH                     --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                          ,xxcmn_mov_req_instr_lines_arc       XMRL                  --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                          ,(    -- �z��NO�P�ʂ̐ύڏd�ʍ��v�Z�o
                            SELECT delivery_no                                       --�z��NO
                                  ,SUM(sum_weight)   sum_loading_weight              --�ύڏd�ʍ��v
                              FROM (SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_order_headers_all_arc  --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                     WHERE latest_external_flag = 'Y'
                                    UNION ALL
                                    SELECT delivery_no
                                          ,sum_weight
                                      FROM xxcmn_mov_req_instr_hdrs_arc  --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                   )
                            GROUP BY delivery_no
                           )                               XCS                       --�z��NO�P�ʐύڏd�ʍ��v
                          ,(
                            SELECT XD1.delivery_no                                   --�z��NO
                                  ,XD1.qty1                                          --�z��_���P
                                  ,XD1.total_amount                                  --�z��_���v���z
                              FROM xxwip_deliverys XD1
                             WHERE XD1.p_b_classe = '2'                              --'2:�����^��'
                            UNION ALL
                            SELECT XD2.delivery_no                                   --�z��NO
                                  ,XD2.qty1                                          --�z��_���P
                                  ,0                                                 --�z��_���v���z
                              FROM xxwip_deliverys XD2
                             WHERE XD2.p_b_classe = '1'                              --'1:�x���^��'
                               -- �x�������敪��'1':�x���^���̂�
                               AND NOT EXISTS
                                   (
                                    SELECT 'X'
                                      FROM xxwip_deliverys XD3
                                      WHERE XD3.p_b_classe = '2'                     --'2:�����^��'
                                        AND XD3.delivery_no = XD2.delivery_no
                                   )
                           )                               XDLV                      --�^���w�b�_�A�h�I��
                          ,(    -- �z��NO�P�ʂ̍ő�˗�NO�A�ő喾�הԍ��擾
                            SELECT delivery_no
                                  ,req_mov_line
                              FROM (SELECT OH.delivery_no
                                          ,MAX(OH.request_no || LPAD(OL.order_line_number, 5, '0')) req_mov_line
                                      FROM xxcmn_order_headers_all_arc  OH  --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                          ,xxcmn_order_lines_all_arc   OL  --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                                     WHERE OH.order_header_id = OL.order_header_id
                                       AND OH.latest_external_flag = 'Y'
                                       AND NVL(OL.delete_flag, 'N') <> 'Y'
                                    GROUP BY OH.delivery_no
                                    UNION ALL
                                    SELECT MH.delivery_no
                                          ,MAX(MH.mov_num || LPAD(ML.line_number, 5, '0')) req_mov_line
                                      FROM xxcmn_mov_req_instr_hdrs_arc  MH   --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                          ,xxcmn_mov_req_instr_lines_arc   ML --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                                     WHERE MH.mov_hdr_id = ML.mov_hdr_id
                                       AND NVL( ML.delete_flg, 'N' ) <> 'Y'      --�������׈ȊO
                                    GROUP BY MH.delivery_no
                                   )
                           )                               RML                       --�z��NO�P�ʂ̍ő�˗��E���הԍ����
                    WHERE
                      -- �ړ��w�b�_�f�[�^�擾����
                           XMRH.status = '06'                                        --���o�ɕ񍐗L�̂�
                      -- �ړ����׃f�[�^�擾����
                      AND  NVL(XMRL.delete_flg, 'N') <> 'Y'
                      AND  XMRH.mov_hdr_id = XMRL.mov_hdr_id
                      -- �z��NO�P�ʐύڏd�ʍ��v�擾����
                      AND  XMRH.delivery_no = XCS.delivery_no
                      -- �^���w�b�_�A�h�I�����擾����
                      AND  XMRH.delivery_no = XDLV.delivery_no
                      -- �z��NO�P�ʍő�˗��E���הԍ��擾����
                      AND  XMRH.delivery_no = RML.delivery_no
                )  DELV
               ,xxskz_locations2_v              XL2V     --SKYLINK�p����VIEW ���Ə����VIEW2(�Ǌ����_��)
               ,xxskz_carriers2_v               XCRV     --SKYLINK�p����VIEW �^���Ǝҏ��VIEW2(�^���ƎҖ�)
               ,xxskz_item_locations2_v         XILV1    --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(���ɐ於)
               ,xxskz_item_locations2_v         XILV2    --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(�o�Ɍ���)
               ,xxskz_item_mst2_v               ITEM     --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�i�ڏ��)
               ,fnd_lookup_values               FLV01    --�N�C�b�N�R�[�h(�X�e�[�^�X��)
               ,fnd_lookup_values               FLV02    --�N�C�b�N�R�[�h(�z���敪��)
         WHERE
           -- �Ǌ����_���擾����
                XL2V.location_code(+)           = '2100'            -- ������
           AND  XL2V.start_date_active(+)       <= DELV.shipped_date
           AND  XL2V.end_date_active(+)         >= DELV.shipped_date
           -- �^���Ǝ�_���і��擾����
           AND  DELV.freight_carrier_id = XCRV.party_id(+)
           AND  DELV.arrival_date >= XCRV.start_date_active(+)
           AND  DELV.arrival_date <= XCRV.end_date_active(+)
           -- �ړ�_���ɐ於�擾
           AND  DELV.ship_to_locat_id = XILV1.inventory_location_id(+)
           -- �o�Ɍ����擾����
           AND  DELV.shipped_locat_id = XILV2.inventory_location_id(+)
           -- �o�וi�ڏ��擾����
           AND  DELV.item_code = ITEM.item_no(+)
           AND  DELV.arrival_date >= ITEM.start_date_active(+)
           AND  DELV.arrival_date <= ITEM.end_date_active(+)
           -- �X�e�[�^�X��
           AND  FLV01.language(+)    = 'JA'
           AND  FLV01.lookup_type(+) = 'XXINV_MOVE_STATUS'
           AND  FLV01.lookup_code(+) = DELV.status
           -- �z���敪��
           AND  FLV02.language(+)    = 'JA'
           AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
           AND  FLV02.lookup_code(+) = DELV.shipping_method_code
           -- �ύڏd�ʍ��v���[���̂�
           AND  NVL( DELV.sum_loading_weight, 0 ) = 0
-- 2009.01.21��
        UNION ALL
        --=========================================================
        -- �ړ��f�[�^�i�^���A�h�I���ɑ��݂��Ȃ����́j
        --=========================================================
        SELECT
                DELV.delivery_no                    delivery_no                     --�z��No
               ,DELV.mov_num                        req_mov_no                      --�˗�_�ړ�No
               ,'�ړ�'                              kbn                             --�敪
               ,NULL                                order_type                      --�󒍃^�C�v
               ,DELV.status                         status                          --�X�e�[�^�X
               ,FLV01.meaning                       status_name                     --�X�e�[�^�X��
               ,'2100'                              branch                          --�Ǌ����_
               ,XL2V.location_name                  branch_name                     --�Ǌ����_��
               ,DELV.freight_carrier_code           carrier_code                    --�^���Ǝ�
               ,XCRV.party_name                     carrier_name                    --�^���ƎҖ�
               ,XCRV.party_short_name               carrier_short_name              --�^���Ǝҗ���
               ,DELV.ship_to_locat_code             ship_deliver_to                 --���ɐ�_�z����
               ,XILV1.description                   ship_deliver_to_name            --���ɐ�_�z���於
               ,XILV1.short_name                    ship_deliver_to_short_name      --���ɐ�_�z���旪��
               ,DELV.shipped_locat_code             ship_from                       --�o�Ɍ�
               ,XILV2.description                   ship_from_name                  --�o�Ɍ���
               ,XILV2.short_name                    ship_from_short_name            --�o�Ɍ�����
               ,DELV.shipping_method_code           ship_method_code                --�z���敪
               ,FLV02.meaning                       ship_method_name                --�z���敪��
               ,DELV.shipped_date                   shipped_date                    --�o�ɓ�
               ,DELV.arrival_date                   arrival_date                    --���ɓ�
               ,ITEM.item_id                        item_id                         --�i��ID
               ,DELV.item_code                      item_code                       --�i�ڃR�[�h
               ,ITEM.item_name                      item_name                       --�i�ږ���
               ,ITEM.item_short_name                item_short_name                 --�i�ڗ���
               ,DELV.quantity                       quantity                        --�i��_�o����
               ,NVL( DELV.quantity / ITEM.num_of_cases, 0 )
                                                    cs_quantity                     --�i��_�P�[�X��
               ,NVL( DELV.qty1, 0 )                 sum_cs_quantity                 --���v�P�[�X��
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.sum_loading_weight)      sum_loading_weight              --�z��_�ύڏd�ʍ��v
               ,CEIL(TRUNC(NVL(DELV.sum_loading_weight,0),1))      
                                                    sum_loading_weight              --�ύڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_sum_loading_weight  distribute_sum_loading_weight   --�z��_���v�Z�p_�ύڏd�ʍ��v
-- 2010/1/8 #627 Y.Fukami Mod Start
--               ,ROUND(DELV.weight)                  item_weight                     --�i�ڏd�ʍ��v
               ,CEIL(TRUNC(NVL(DELV.weight,0),1))   item_weight                     --�i�ڏd�ʍ��v(�����_��2�ʈȉ���؂�̂Č�A�����_��1�ʂ�؂�グ)
-- 2010/1/8 #627 Y.Fukami Mod End
               ,DELV.distribute_item_weight         distribute_item_weight          --���v�Z�p_�i�ڏd�ʍ��v
               ,0                                   total_amount                    --���v���z
               ,0                                   item_total_amount               --�i��_���v���z
          FROM  (  --�Ώۃf�[�^�𒊏o
--aaa
                   SELECT  XMRH.delivery_no                                          --�z��No
                          ,XMRH.mov_num                                              --�˗�_�ړ�No
                          ,XMRL.line_number                                          --���הԍ�
                          ,XMRH.status                                               --�X�e�[�^�X
                          ,XMRH.actual_career_id             freight_carrier_id      --�^���Ǝ�ID
                          ,XMRH.actual_freight_carrier_code  freight_carrier_code    --�^���Ǝ�
                          ,XMRH.ship_to_locat_id                                     --���ɐ�ID
                          ,XMRH.ship_to_locat_code                                   --���ɐ�
                          ,XMRH.shipped_locat_id                                     --�o�Ɍ�ID
                          ,XMRH.shipped_locat_code                                   --�o�Ɍ�
                          ,XMRH.actual_shipping_method_code  shipping_method_code    --�z���敪
                          ,XMRH.actual_ship_date             shipped_date            --�o�ɓ�
                          ,XMRH.actual_arrival_date          arrival_date            --���ɓ�
                          ,XMRL.item_code                                            --�i�ڃR�[�h
--                        ,XMRL.shipped_quantity             quantity                --�i��_����
                          ,XMRL.ship_to_quantity             quantity                --�i��_����
                          ,XCS.sum_loading_weight            sum_loading_weight      --�z��_�ύڏd�ʍ��v
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --�z��_���v�Z�p_�ύڏd�ʍ��v
                          ,XMRL.weight                                               --�i�ڏd�ʍ��v
                          ,XMRL.weight                       distribute_item_weight  --���v�Z�p_�i�ڏd�ʍ��v
                           --�z��No���̕i�ڏd�ʊ����i�i��_�d�ʍ��v �� �z��_�d�ʍ��v�j
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XMRL.weight / XCS.sum_loading_weight
                           END                               item_rate               --�z��No���̕i�ڏd�ʊ���
                           --�z���P�ʂ̉^��
                          ,XCS.sum_loading_quantity          qty1                    --�z��_���P
                     FROM  xxcmn_mov_req_instr_hdrs_arc     XMRH                     --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                          ,xxcmn_mov_req_instr_lines_arc       XMRL                  --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                          ,(    -- �z��NO�P�ʂ̐ύڏd�ʍ��v�Z�o
                            SELECT delivery_no                                       --�z��NO
                                  ,SUM(sum_quantity) sum_loading_quantity
                                  ,SUM(sum_weight)   sum_loading_weight              --�ύڏd�ʍ��v
                              FROM (
                                    SELECT delivery_no
                                          ,NVL(shipped_quantity / ITEM11.num_of_cases, 0)  sum_quantity
                                          ,weight                                          sum_weight
                                      FROM (
                                            SELECT XOHA.delivery_no
                                                  ,XOHA.arrival_date
                                                  ,XOLA.shipping_item_code
                                                  ,XOLA.shipped_quantity
                                                  ,XOLA.weight
                                              FROM xxcmn_order_headers_all_arc  XOHA,  --�󒍃w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                                   xxcmn_order_lines_all_arc   XOLA  --�󒍖��ׁi�A�h�I���j�o�b�N�A�b�v
                                             WHERE NVL(XOLA.delete_flag, 'N') <> 'Y'
                                               AND XOHA.order_header_id = XOLA.order_header_id
                                               AND XOHA.delivery_no IS NOT NULL
                                               AND XOHA.latest_external_flag = 'Y'
                                               AND XOHA.req_status = '04'
                                           )  XOHA11,
                                           xxskz_item_mst2_v   ITEM11
                                     WHERE XOHA11.shipping_item_code = ITEM11.item_no(+)
                                       AND XOHA11.arrival_date >= ITEM11.start_date_active(+)
                                       AND XOHA11.arrival_date <= ITEM11.end_date_active(+)
                                       AND XOHA11.delivery_no IS NOT NULL
                                    UNION ALL
                                    SELECT delivery_no
                                          ,NVL(shipped_quantity / ITEM11.num_of_cases, 0)  sum_quantity
                                          ,weight                                          sum_weight
                                      FROM (
                                            SELECT XMRH11.delivery_no
                                                  ,XMRH11.actual_arrival_date
                                                  ,XMRL11.item_code
--                                                ,XMRL11.shipped_quantity
                                                  ,XMRL11.ship_to_quantity    shipped_quantity
                                                  ,XMRL11.weight
                                              FROM xxcmn_mov_req_instr_hdrs_arc  XMRH11,   --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                                   xxcmn_mov_req_instr_lines_arc   XMRL11  --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                                             WHERE NVL(XMRL11.delete_flg, 'N') <> 'Y'
                                               AND XMRH11.mov_hdr_id = XMRL11.mov_hdr_id
                                               AND XMRH11.delivery_no IS NOT NULL
                                           )  XMR11,
                                           xxskz_item_mst2_v   ITEM11
                                     WHERE item_code = item_no(+)
                                       AND actual_arrival_date >= start_date_active(+)
                                       AND actual_arrival_date <= end_date_active(+)
                                       AND delivery_no IS NOT NULL
                                   )
                            GROUP BY delivery_no
                           )                               XCS                       --�z��NO�P�ʐύڏd�ʍ��v
                    WHERE
                      -- �ړ��w�b�_�f�[�^�擾����
                           XMRH.status = '06'                                        --���o�ɕ񍐗L�̂�
                      -- �ړ����׃f�[�^�擾����
                      AND  NVL(XMRL.delete_flg, 'N') <> 'Y'
                      AND  XMRH.mov_hdr_id = XMRL.mov_hdr_id
                      -- �z��NO�P�ʐύڏd�ʍ��v�擾����
                      AND  XMRH.delivery_no = XCS.delivery_no
                      AND  NOT EXISTS(SELECT 'X' FROM xxwip_deliverys VD12
                                       WHERE VD12.delivery_no = XMRH.delivery_no
                                     )
                      AND  XMRH.delivery_no IS NOT NULL
                   UNION ALL
                   SELECT  XMRH.delivery_no                                          --�z��No
                          ,XMRH.mov_num                                              --�˗�_�ړ�No
                          ,XMRL.line_number                                          --���הԍ�
                          ,XMRH.status                                               --�X�e�[�^�X
                          ,XMRH.actual_career_id             freight_carrier_id      --�^���Ǝ�ID
                          ,XMRH.actual_freight_carrier_code  freight_carrier_code    --�^���Ǝ�
                          ,XMRH.ship_to_locat_id                                     --���ɐ�ID
                          ,XMRH.ship_to_locat_code                                   --���ɐ�
                          ,XMRH.shipped_locat_id                                     --�o�Ɍ�ID
                          ,XMRH.shipped_locat_code                                   --�o�Ɍ�
                          ,XMRH.actual_shipping_method_code  shipping_method_code    --�z���敪
                          ,XMRH.actual_ship_date             shipped_date            --�o�ɓ�
                          ,XMRH.actual_arrival_date          arrival_date            --���ɓ�
                          ,XMRL.item_code                                            --�i�ڃR�[�h
--                        ,XMRL.shipped_quantity             quantity                --�i��_����
                          ,XMRL.ship_to_quantity             quantity                --�i��_����
                          ,XCS.sum_loading_weight            sum_loading_weight      --�z��_�ύڏd�ʍ��v
                          ,XCS.sum_loading_weight            distribute_sum_loading_weight      --�z��_���v�Z�p_�ύڏd�ʍ��v
                          ,XMRL.weight                                               --�i�ڏd�ʍ��v
                          ,XMRL.weight                       distribute_item_weight  --���v�Z�p_�i�ڏd�ʍ��v
                           --�z��No���̕i�ڏd�ʊ����i�i��_�d�ʍ��v �� �z��_�d�ʍ��v�j
                          ,CASE WHEN XCS.sum_loading_weight = 0 THEN 0
                                ELSE XMRL.weight / XCS.sum_loading_weight
                           END                               item_rate               --�z��No���̕i�ڏd�ʊ���
                           --�z���P�ʂ̉^��
                          ,XCS.sum_loading_quantity          qty1                    --�z��_���P
                     FROM  xxcmn_mov_req_instr_hdrs_arc     XMRH                     --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                          ,xxcmn_mov_req_instr_lines_arc       XMRL                  --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                          ,(    -- �ړ�NO�P�ʂ̐ύڏd�ʍ��v�Z�o
                            SELECT mov_num                                           --�ړ�NO
                                  ,SUM(sum_quantity) sum_loading_quantity
                                  ,SUM(sum_weight)   sum_loading_weight              --�ύڏd�ʍ��v
                              FROM (
                                    SELECT mov_num
                                          ,NVL(shipped_quantity / ITEM11.num_of_cases, 0)  sum_quantity
                                          ,weight                                          sum_weight
                                      FROM (
                                            SELECT XMRH11.delivery_no
                                                  ,XMRH11.mov_num
                                                  ,XMRH11.actual_arrival_date
                                                  ,XMRL11.item_code
--                                                ,XMRL11.shipped_quantity
                                                  ,XMRL11.ship_to_quantity   shipped_quantity
                                                  ,XMRL11.weight
                                              FROM xxcmn_mov_req_instr_hdrs_arc  XMRH11,   --�ړ��˗�/�w���w�b�_�i�A�h�I���j�o�b�N�A�b�v
                                                   xxcmn_mov_req_instr_lines_arc   XMRL11  --�ړ��˗�/�w�����ׁi�A�h�I���j�o�b�N�A�b�v
                                             WHERE NVL(XMRL11.delete_flg, 'N') <> 'Y'
                                               AND XMRH11.mov_hdr_id = XMRL11.mov_hdr_id
                                               AND XMRH11.delivery_no IS NULL
                                           )  XMR11,
                                           xxskz_item_mst2_v   ITEM11
                                     WHERE item_code = item_no(+)
                                       AND actual_arrival_date >= start_date_active(+)
                                       AND actual_arrival_date <= end_date_active(+)
                                   )
                            GROUP BY mov_num
                           )                               XCS                       --�z��NO�P�ʐύڏd�ʍ��v
                    WHERE
                      -- �ړ��w�b�_�f�[�^�擾����
                           XMRH.status = '06'                                        --���o�ɕ񍐗L�̂�
                      -- �ړ����׃f�[�^�擾����
                      AND  NVL(XMRL.delete_flg, 'N') <> 'Y'
                      AND  XMRH.mov_hdr_id = XMRL.mov_hdr_id
                      -- �ړ�NO�P�ʐύڏd�ʍ��v�擾����
                      AND  XMRH.mov_num = XCS.mov_num
                      AND  XMRH.delivery_no IS NULL
--aaa
                )  DELV
               ,xxskz_locations2_v              XL2V     --SKYLINK�p����VIEW ���Ə����VIEW2(�Ǌ����_��)
               ,xxskz_carriers2_v               XCRV     --SKYLINK�p����VIEW �^���Ǝҏ��VIEW2(�^���ƎҖ�)
               ,xxskz_item_locations2_v         XILV1    --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(���ɐ於)
               ,xxskz_item_locations2_v         XILV2    --SKYLINK�p����VIEW OPM�ۊǏꏊ���VIEW2(�o�Ɍ���)
               ,xxskz_item_mst2_v               ITEM     --SKYLINK�p����VIEW OPM�i�ڏ��VIEW2(�i�ڏ��)
               ,fnd_lookup_values               FLV01    --�N�C�b�N�R�[�h(�X�e�[�^�X��)
               ,fnd_lookup_values               FLV02    --�N�C�b�N�R�[�h(�z���敪��)
         WHERE
           -- �Ǌ����_���擾����
                XL2V.location_code(+)           = '2100'            -- ������
           AND  XL2V.start_date_active(+)       <= DELV.shipped_date
           AND  XL2V.end_date_active(+)         >= DELV.shipped_date
           -- �^���Ǝ�_���і��擾����
           AND  DELV.freight_carrier_id = XCRV.party_id(+)
           AND  DELV.arrival_date >= XCRV.start_date_active(+)
           AND  DELV.arrival_date <= XCRV.end_date_active(+)
           -- �ړ�_���ɐ於�擾
           AND  DELV.ship_to_locat_id = XILV1.inventory_location_id(+)
           -- �o�Ɍ����擾����
           AND  DELV.shipped_locat_id = XILV2.inventory_location_id(+)
           -- �o�וi�ڏ��擾����
           AND  DELV.item_code = ITEM.item_no(+)
           AND  DELV.arrival_date >= ITEM.start_date_active(+)
           AND  DELV.arrival_date <= ITEM.end_date_active(+)
           -- �X�e�[�^�X��
           AND  FLV01.language(+)    = 'JA'
           AND  FLV01.lookup_type(+) = 'XXINV_MOVE_STATUS'
           AND  FLV01.lookup_code(+) = DELV.status
           -- �z���敪��
           AND  FLV02.language(+)    = 'JA'
           AND  FLV02.lookup_type(+) = 'XXCMN_SHIP_METHOD'
           AND  FLV02.lookup_code(+) = DELV.shipping_method_code
-- 2009.01.21��
        )    UHK
       ,xxskz_prod_class_v              PRODC    --SKYLINK�p����VIEW ���i�敪VIEW
       ,xxskz_item_class_v              ITEMC    --SKYLINK�p����VIEW �i�ڋ敪VIEW
       ,xxskz_crowd_code_v              CROWD    --SKYLINK�p����VIEW �Q�R�[�hVIEW
 WHERE
   -- �o�וi�ڂ̃J�e�S�����擾����
        UHK.item_id = PRODC.item_id(+)  --���i�敪
   AND  UHK.item_id = ITEMC.item_id(+)  --�i�ڋ敪
   AND  UHK.item_id = CROWD.item_id(+)  --�Q�R�[�h
   -- �h�����N�̂�
   AND  PRODC.prod_class_code = '2'
   -- ���i�̂� 2009.01.21
   AND  ITEMC.item_class_code = '5'
/
COMMENT ON TABLE APPS.XXSKZ_�^���i�ڕ�_��{_V IS 'SKYLINK�p�^���i�ڕʁi��{�j VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�z��NO IS '�z��No'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�˗�_�ړ�NO IS '�˗�_�ړ�No'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�敪 IS '�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�󒍃^�C�v IS '�󒍃^�C�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�X�e�[�^�X IS '�X�e�[�^�X'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�X�e�[�^�X�� IS '�X�e�[�^�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�Ǌ����_ IS '�Ǌ����_'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�Ǌ����_�� IS '�Ǌ����_��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�^���Ǝ� IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�^���ƎҖ� IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�^���Ǝҗ��� IS '�^���Ǝҗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.���ɐ�_�z���� IS '���ɐ�_�z����'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.���ɐ�_�z���於 IS '���ɐ�_�z���於'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.���ɐ�_�z���旪�� IS '���ɐ�_�z���旪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�o�Ɍ� IS '�o�Ɍ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�o�Ɍ��� IS '�o�Ɍ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�o�Ɍ����� IS '�o�Ɍ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�z���敪 IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�z���敪�� IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�o�ɓ� IS '�o�ɓ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.���ɓ� IS '���ɓ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.���i�敪 IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.���i�敪�� IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�i�ڋ敪 IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�i�ڋ敪�� IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�Q�R�[�h IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�i�ڃR�[�h IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�i�ږ��� IS '�i�ږ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�i�ڗ��� IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�i�ڃo���� IS '�i�ڃo����'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�i�ڃP�[�X�� IS '�i�ڃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.���v�P�[�X�� IS '���v�P�[�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�ύڏd�ʍ��v IS '�ύڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.���v�Z�p_�ύڏd�ʍ��v IS '���v�Z�p_�ύڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�i�ڏd�ʍ��v IS '�i�ڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.���v�Z�p_�i�ڏd�ʍ��v IS '���v�Z�p_�i�ڏd�ʍ��v'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.���v���z IS '���v���z'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���i�ڕ�_��{_V.�i��_���v���z IS '�i��_���v���z'
/
