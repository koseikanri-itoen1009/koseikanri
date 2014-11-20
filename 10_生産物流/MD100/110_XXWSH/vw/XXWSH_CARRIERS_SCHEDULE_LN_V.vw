CREATE OR REPLACE VIEW apps.xxwsh_carriers_schedule_ln_v
(ROW_ID,
 HEADER_ID,
 DEFAULT_LINE,
 TRANSACTION_TYPE,
 TRANSACTION_TYPE_NAME,
 DELIVERY_NO,
 REQUEST_NO,
 CAREER_ID,
 FREIGHT_CARRIER_CODE,
 SHIPPING_METHOD_CODE,
 SHIPPING_KUBUN_CODE,
 MIXED_CLASS_CODE,
 TRANSACTION_TYPE_ID,
 SCHEDULE_SHIP_DATE,
 SCHEDULE_ARRIVAL_DATE,
-- 2008/09/02 TE080_600�w�ENo13�Ή� Add D.Nihei Start
 AMOUNT_FIX_CLASS,
-- 2008/09/02 TE080_600�w�ENo13�Ή� Add D.Nihei End
 DELIVER_FROM,
 DELIVER_FROM_NAME,
 DELIVER_TO,
 VENDOR_SITE_CODE,
 DELIVER_TO_NAME,
 VENDOR_SITE_CODE_NAME,
 HEAD_SALES_BRANCH,
 HEAD_SALES_BRANCH_NAME,
 VENDOR_CODE,
 VENDOR_SHORT_NAME,
 BASED_WEIGHT,
 BASED_CAPACITY,
 SUM_WEIGHT,
 SUM_CAPACITY,
 PALLET_SUM_QUANTITY,
 SUM_PALLET_WEIGHT,
 LOADING_EFFICIENCY_WEIGHT,
 LOADING_EFFICIENCY_CAPACITY,
 WEIGHT_CAPACITY_CLASS,
 PROD_CLASS,
 MIXED_RATIO,
 SLIP_NUMBER,
 SMALL_QUANTITY,
 LABEL_QUANTITY,
 MIXED_SIGN,
 MIXED_NO,
 RESULT_FREIGHT_CARRIER_ID,
 RESULT_FREIGHT_CARRIER_CODE,
 RESULT_SHIPPING_METHOD_CODE,
 RESULT_SHIPPING_KUBUN_CODE,
 RESULT_MIXED_CLASS_CODE,
 RESULT_DELIVER_TO,
 RESULT_DELIVER_TO_NAME,
 SHIPPED_DATE,
 ARRIVAL_DATE,
 REQ_STATUS,
 NOTIF_STATUS,
 PREV_NOTIF_STATUS,
 NOTIF_DATE,
 NEW_MODIFY_FLG,
 SCREEN_UPDATE_BY,
 SCREEN_UPDATE_DATE,
 PREV_DELIVERY_NO,
 ACTUAL_CONFIRM_CLASS,
 CREATED_BY,
 CREATION_DATE,
 LAST_UPDATED_BY,
 LAST_UPDATE_DATE,
 LAST_UPDATE_LOGIN
) AS 
SELECT xoha.rowid                       row_id
      ,xoha.order_header_id             header_id                   -- �󒍃w�b�_ID
      ,NVL2(xcs.default_line_number,'0','1') default_line           -- �����
      ,xottv.shipping_shikyu_class      transaction_type           -- ������ʃR�[�h
      ,xlvv1.meaning                    transaction_type_name       -- ������ʖ���
-- 2008/09/02 PT1-1_4 Mod D.Nihei Start
--      ,NVL(xoha.delivery_no,xoha.mixed_no) delivery_no              -- �z��No
      ,xoha.delivery_no                 delivery_no              -- �z��No
      ,xoha.request_no                  request_no                  -- �˗�No
      ,xoha.career_id                   career_id                   -- �^���Ǝ�ID
      ,xoha.freight_carrier_code        freight_carrier_code        -- �^���Ǝ�
      ,xoha.shipping_method_code        shipping_method_code        -- �z���敪
      ,xlvv2.attribute6                 shipping_kubun_code         -- DFF�����敪
      ,xlvv2.attribute9                 mixed_class_code            -- DFF���ڋ敪
      ,xottv.transaction_type_id        transaction_type_id         -- ����^�C�vID
      ,xoha.schedule_ship_date          schedule_ship_date          -- �o�ɗ\���
      ,xoha.schedule_arrival_date       schedule_arrival_date       -- ���ח\���
-- 2008/09/02 TE080_600�w�ENo13�Ή� Add D.Nihei Start
      ,xoha.amount_fix_class            amount_fix_class            -- �L�����z�m��敪
-- 2008/09/02 TE080_600�w�ENo13�Ή� Add D.Nihei End
      ,xoha.deliver_from                deliver_from                -- �o�׌��ۊǏꏊ
      ,xilv.description                 deliver_from_name           -- �E�v
      ,xoha.deliver_to                  deliver_to                  -- �o�א�
      ,xoha.vendor_site_code            vendor_site_code            -- �����T�C�g
      ,xcasv.party_site_full_name       deliver_to_name             -- �o�א搳������
      ,xvsv.vendor_site_short_name      vendor_site_code_name       -- �����T�C�g����
      ,xoha.head_sales_branch           head_sales_branch           -- �Ǌ����_
      ,xcav.party_short_name            head_sales_branch_name      -- �Ǌ����_����
      ,xoha.vendor_code                 vendor_code                 -- �����
      ,xvv.vendor_short_name            vendor_short_name           -- ����旪��
      ,xoha.based_weight                based_weight                -- ��{�d��
      ,xoha.based_capacity              based_capacity              -- ��{�e��
      ,xoha.sum_weight                  sum_weight                  -- �ύڏd�ʍ��v
      ,xoha.sum_capacity                sum_capacity                -- �ύڗe�ύ��v
      ,xoha.pallet_sum_quantity         pallet_sum_quantity         -- ���v�p���b�g����
      ,xoha.sum_pallet_weight           sum_pallet_weight           -- ���v�p���b�g�d��
      ,xoha.loading_efficiency_weight   loading_efficiency_weight   -- �d�ʐύڌ���
      ,xoha.loading_efficiency_capacity loading_efficiency_capacity -- �e�ϐύڌ���
      ,xoha.weight_capacity_class       weight_capacity_class       -- �d�ʗe�ϋ敪
      ,xoha.prod_class                  prod_class                  -- ���i�敪
      ,xoha.mixed_ratio                 mixed_ratio                 -- ���ڗ�
      ,xoha.slip_number                 slip_number                 -- �����No
      ,xoha.small_quantity              small_quantity              -- ������
      ,xoha.label_quantity              label_quantity              -- ���x������
      ,xoha.mixed_sign                  mixed_sign                  -- ���ڋL��
      ,DECODE(xottv.shipping_shikyu_class
         ,'1',xoha.mixed_no
         ,'2',NULL)                     mixed_no                    -- ���ڌ�No
      ,xoha.result_freight_carrier_id   result_freight_carrier_id   -- �^���Ǝ�_����ID
      ,xoha.result_freight_carrier_code result_freight_carrier_code -- �^���Ǝ�_����
      ,xoha.result_shipping_method_code result_shipping_method_code -- �z���敪_����
      ,xlvv3.attribute6                 result_shipping_kubun_code  -- DFF�����敪_����
      ,xlvv3.attribute9                 result_mixed_class_code     -- DFF���ڋ敪_����
      ,xoha.result_deliver_to           result_deliver_to           -- �o�א�_����
      ,xcasv2.party_site_full_name      result_deliver_to_name      -- �o�א�_���і���
      ,xoha.shipped_date                shipped_date                -- �o�ד�
      ,xoha.arrival_date                arrival_date                -- ���ד�
      --
      ,xoha.req_status                  req_status                  -- �X�e�[�^�X
      ,xoha.notif_status                notif_status                -- �ʒm�X�e�[�^�X
      ,xoha.prev_notif_status           prev_notif_status           -- �O��ʒm�X�e�[�^�X
      ,xoha.notif_date                  notif_date                  -- �m��ʒm���{����
      ,xoha.new_modify_flg              new_modify_flg              -- �V�K�C���t���O
      ,xoha.screen_update_by            screen_update_by            -- ��ʍX�V��
      ,xoha.screen_update_date          screen_update_date          -- ��ʍX�V����
      ,xoha.prev_delivery_no            prev_delivery_no            -- �O��z����
      ,xoha.actual_confirm_class        actual_confirm_class        -- ���ьv��ϋ敪
      --
      ,xoha.created_by                  created_by                  -- �쐬��
      ,xoha.creation_date               creation_date               -- �쐬��
      ,xoha.last_updated_by             last_updated_by             -- �ŏI�X�V��
      ,xoha.last_update_date            last_update_date            -- �ŏI�X�V��
      ,xoha.last_update_login           last_update_login           -- �ŏI�X�V���O�C��
FROM   xxwsh_order_headers_all      xoha   -- �󒍃w�b�_�[
      ,xxwsh_oe_transaction_types_v xottv  -- �󒍃^�C�v
      ,xxwsh_carriers_schedule      xcs    -- �z�Ԕz���v��
      ,xxcmn_lookup_values_v        xlvv1
      ,xxcmn_lookup_values_v        xlvv2
      ,xxcmn_lookup_values_v        xlvv3
      ,xxcmn_item_locations_v       xilv
      ,xxcmn_cust_acct_sites_v      xcasv
      ,xxcmn_cust_acct_sites_v      xcasv2
      ,xxcmn_vendor_sites_v         xvsv
      ,xxcmn_cust_accounts_v        xcav
      ,xxcmn_vendors_v              xvv
WHERE xlvv1.lookup_type(+)        = 'XXWSH_PROCESS_TYPE'
AND   xlvv1.lookup_code(+)        = xottv.shipping_shikyu_class       -- �������
AND   xlvv2.lookup_type(+)        = 'XXCMN_SHIP_METHOD'
AND   xlvv2.lookup_code(+)        = xoha.shipping_method_code         -- �z���敪
AND   xlvv3.lookup_type(+)        = 'XXCMN_SHIP_METHOD'
AND   xlvv3.lookup_code(+)        = xoha.result_shipping_method_code  -- �z���敪_����
AND   xilv.segment1(+)            = xoha.deliver_from                 -- �o�׌��ۊǏꏊ���̎擾
AND   xcasv.party_site_id(+)      = xoha.deliver_to_id                -- �o�א於��
AND   xcasv2.party_site_id(+)     = xoha.result_deliver_to_id         -- �o�א�_���і���
AND   xvsv.vendor_site_id(+)      = xoha.vendor_site_id               -- �����T�C�g����
AND   xcav.party_number(+)        = xoha.head_sales_branch            -- �Ǌ����_����
AND   xcav.customer_class_code(+) = '1'                               -- �ڋq�敪
AND   xvv.segment1(+)             = xoha.vendor_code                  -- ����於��
AND   xcs.default_line_number (+) = xoha.request_no
AND   xcs.delivery_no (+)         = xoha.delivery_no
AND   xoha.order_type_id          = xottv.transaction_type_id
AND   xoha.latest_external_flag   = 'Y'
AND   (    (xottv.shipping_shikyu_class   = '1')
      OR   (xottv.shipping_shikyu_class = '2') )
AND   xoha.delivery_no IS NOT NULL
UNION ALL
SELECT xoha.rowid                       row_id
      ,xoha.order_header_id             header_id                   -- �󒍃w�b�_ID
      ,NVL2(xcs.default_line_number,'0','1') default_line           -- �����
      ,xottv.shipping_shikyu_class      transaction_type           -- ������ʃR�[�h
      ,xlvv1.meaning                    transaction_type_name       -- ������ʖ���
      ,xoha.mixed_no                    delivery_no              -- �z��No
-- 2008/09/02 PT1-1_4 Mod D.Nihei End
      ,xoha.request_no                  request_no                  -- �˗�No
      ,xoha.career_id                   career_id                   -- �^���Ǝ�ID
      ,xoha.freight_carrier_code        freight_carrier_code        -- �^���Ǝ�
      ,xoha.shipping_method_code        shipping_method_code        -- �z���敪
      ,xlvv2.attribute6                 shipping_kubun_code         -- DFF�����敪
      ,xlvv2.attribute9                 mixed_class_code            -- DFF���ڋ敪
      ,xottv.transaction_type_id        transaction_type_id         -- ����^�C�vID
      ,xoha.schedule_ship_date          schedule_ship_date          -- �o�ɗ\���
      ,xoha.schedule_arrival_date       schedule_arrival_date       -- ���ח\���
-- 2008/09/02 TE080_600�w�ENo13�Ή� Add D.Nihei Start
      ,xoha.amount_fix_class            amount_fix_class            -- �L�����z�m��敪
-- 2008/09/02 TE080_600�w�ENo13�Ή� Add D.Nihei End
      ,xoha.deliver_from                deliver_from                -- �o�׌��ۊǏꏊ
      ,xilv.description                 deliver_from_name           -- �E�v
      ,xoha.deliver_to                  deliver_to                  -- �o�א�
      ,xoha.vendor_site_code            vendor_site_code            -- �����T�C�g
      ,xcasv.party_site_full_name       deliver_to_name             -- �o�א搳������
      ,xvsv.vendor_site_short_name      vendor_site_code_name       -- �����T�C�g����
      ,xoha.head_sales_branch           head_sales_branch           -- �Ǌ����_
      ,xcav.party_short_name            head_sales_branch_name      -- �Ǌ����_����
      ,xoha.vendor_code                 vendor_code                 -- �����
      ,xvv.vendor_short_name            vendor_short_name           -- ����旪��
      ,xoha.based_weight                based_weight                -- ��{�d��
      ,xoha.based_capacity              based_capacity              -- ��{�e��
      ,xoha.sum_weight                  sum_weight                  -- �ύڏd�ʍ��v
      ,xoha.sum_capacity                sum_capacity                -- �ύڗe�ύ��v
      ,xoha.pallet_sum_quantity         pallet_sum_quantity         -- ���v�p���b�g����
      ,xoha.sum_pallet_weight           sum_pallet_weight           -- ���v�p���b�g�d��
      ,xoha.loading_efficiency_weight   loading_efficiency_weight   -- �d�ʐύڌ���
      ,xoha.loading_efficiency_capacity loading_efficiency_capacity -- �e�ϐύڌ���
      ,xoha.weight_capacity_class       weight_capacity_class       -- �d�ʗe�ϋ敪
      ,xoha.prod_class                  prod_class                  -- ���i�敪
      ,xoha.mixed_ratio                 mixed_ratio                 -- ���ڗ�
      ,xoha.slip_number                 slip_number                 -- �����No
      ,xoha.small_quantity              small_quantity              -- ������
      ,xoha.label_quantity              label_quantity              -- ���x������
      ,xoha.mixed_sign                  mixed_sign                  -- ���ڋL��
      ,DECODE(xottv.shipping_shikyu_class
         ,'1',xoha.mixed_no
         ,'2',NULL)                     mixed_no                    -- ���ڌ�No
      ,xoha.result_freight_carrier_id   result_freight_carrier_id   -- �^���Ǝ�_����ID
      ,xoha.result_freight_carrier_code result_freight_carrier_code -- �^���Ǝ�_����
      ,xoha.result_shipping_method_code result_shipping_method_code -- �z���敪_����
      ,xlvv3.attribute6                 result_shipping_kubun_code  -- DFF�����敪_����
      ,xlvv3.attribute9                 result_mixed_class_code     -- DFF���ڋ敪_����
      ,xoha.result_deliver_to           result_deliver_to           -- �o�א�_����
      ,xcasv2.party_site_full_name      result_deliver_to_name      -- �o�א�_���і���
      ,xoha.shipped_date                shipped_date                -- �o�ד�
      ,xoha.arrival_date                arrival_date                -- ���ד�
      --
      ,xoha.req_status                  req_status                  -- �X�e�[�^�X
      ,xoha.notif_status                notif_status                -- �ʒm�X�e�[�^�X
      ,xoha.prev_notif_status           prev_notif_status           -- �O��ʒm�X�e�[�^�X
      ,xoha.notif_date                  notif_date                  -- �m��ʒm���{����
      ,xoha.new_modify_flg              new_modify_flg              -- �V�K�C���t���O
      ,xoha.screen_update_by            screen_update_by            -- ��ʍX�V��
      ,xoha.screen_update_date          screen_update_date          -- ��ʍX�V����
      ,xoha.prev_delivery_no            prev_delivery_no            -- �O��z����
      ,xoha.actual_confirm_class        actual_confirm_class        -- ���ьv��ϋ敪
      --
      ,xoha.created_by                  created_by                  -- �쐬��
      ,xoha.creation_date               creation_date               -- �쐬��
      ,xoha.last_updated_by             last_updated_by             -- �ŏI�X�V��
      ,xoha.last_update_date            last_update_date            -- �ŏI�X�V��
      ,xoha.last_update_login           last_update_login           -- �ŏI�X�V���O�C��
FROM   xxwsh_order_headers_all      xoha   -- �󒍃w�b�_�[
      ,xxwsh_oe_transaction_types_v xottv  -- �󒍃^�C�v
      ,xxwsh_carriers_schedule      xcs    -- �z�Ԕz���v��
      ,xxcmn_lookup_values_v        xlvv1
      ,xxcmn_lookup_values_v        xlvv2
      ,xxcmn_lookup_values_v        xlvv3
      ,xxcmn_item_locations_v       xilv
      ,xxcmn_cust_acct_sites_v      xcasv
      ,xxcmn_cust_acct_sites_v      xcasv2
      ,xxcmn_vendor_sites_v         xvsv
      ,xxcmn_cust_accounts_v        xcav
      ,xxcmn_vendors_v              xvv
WHERE xlvv1.lookup_type(+)        = 'XXWSH_PROCESS_TYPE'
AND   xlvv1.lookup_code(+)        = xottv.shipping_shikyu_class       -- �������
AND   xlvv2.lookup_type(+)        = 'XXCMN_SHIP_METHOD'
AND   xlvv2.lookup_code(+)        = xoha.shipping_method_code         -- �z���敪
AND   xlvv3.lookup_type(+)        = 'XXCMN_SHIP_METHOD'
AND   xlvv3.lookup_code(+)        = xoha.result_shipping_method_code  -- �z���敪_����
AND   xilv.segment1(+)            = xoha.deliver_from                 -- �o�׌��ۊǏꏊ���̎擾
AND   xcasv.party_site_id(+)      = xoha.deliver_to_id                -- �o�א於��
AND   xcasv2.party_site_id(+)     = xoha.result_deliver_to_id         -- �o�א�_���і���
AND   xvsv.vendor_site_id(+)      = xoha.vendor_site_id               -- �����T�C�g����
AND   xcav.party_number(+)        = xoha.head_sales_branch            -- �Ǌ����_����
AND   xcav.customer_class_code(+) = '1'                               -- �ڋq�敪
AND   xvv.segment1(+)             = xoha.vendor_code                  -- ����於��
AND   xcs.default_line_number (+) = xoha.request_no
-- 2008/09/02 PT1-1_4 Mod D.Nihei Start
--AND   xcs.delivery_no (+)         = NVL(xoha.delivery_no,xoha.mixed_no)
AND   xcs.delivery_no (+)         = xoha.mixed_no
-- 2008/09/02 PT1-1_4 Mod D.Nihei End
AND   xoha.order_type_id          = xottv.transaction_type_id
AND   xoha.latest_external_flag   = 'Y'
AND   (    (xottv.shipping_shikyu_class   = '1')
      OR (   (xottv.shipping_shikyu_class = '2')
         AND (xoha.delivery_no IS NOT NULL)))
-- 2008/09/02 PT1-1_4 Add D.Nihei Start
AND   xoha.delivery_no IS NULL
-- 2008/09/02 PT1-1_4 Add D.Nihei End
UNION ALL
SELECT xmrih.rowid                        row_id
      ,xmrih.mov_hdr_id                       header_id               -- �ړ��w�b�_ID
      ,NVL2(xcs.default_line_number,'0','1') default_line            -- �����
      ,'3'                                transaction_type            -- ������ʃR�[�h
-- 2008/09/02 PT1-1_4 Mod D.Nihei Start
--      ,xlvv1.meaning                      transaction_type_name       -- ������ʖ���
      ,(SELECT  xlvv1.meaning
        FROM    xxcmn_lookup_values_v xlvv1
        WHERE   xlvv1.lookup_type = 'XXWSH_PROCESS_TYPE'
        AND     xlvv1.lookup_code = '3'
        AND     ROWNUM            = 1  )  transaction_type_name       -- ������ʖ���
-- 2008/09/02 PT1-1_4 Mod D.Nihei End
      ,xmrih.delivery_no                  delivery_no                 -- �z��No
      ,xmrih.mov_num                      request_no                  -- �˗�No/�ړ�No
      ,xmrih.career_id                    career_id                   -- �^���Ǝ�ID
      ,xmrih.freight_carrier_code         freight_carrier_code        -- �^���Ǝ�
      ,xmrih.shipping_method_code         shipping_method_code        -- �z���敪
      ,xlvv2.attribute6                   shipping_kubun_code         -- DFF�����敪
      ,xlvv2.attribute9                   mixed_class_code            -- DFF���ڋ敪
      ,NULL                               transaction_type_id         -- ����^�C�vID
      ,xmrih.schedule_ship_date           schedule_ship_date          -- �o�ɗ\���
      ,xmrih.schedule_arrival_date        schedule_arrival_date       -- ���ח\���
-- 2008/09/02 TE080_600�w�ENo13�Ή� Add D.Nihei Start
      ,NULL                               amount_fix_class            -- �L�����z�m��敪
-- 2008/09/02 TE080_600�w�ENo13�Ή� Add D.Nihei End
      ,xmrih.shipped_locat_code           deliver_from                -- �o�׌��ۊǏꏊ
      ,xilv.description                   deliver_from_name           -- �E�v
      ,xmrih.ship_to_locat_code           deliver_to                  -- �o�א�
      ,NULL                               vendor_site_code            -- �����T�C�g
      ,xilv2.description                  deliver_to_name             -- ��������
      ,NULL                               vendor_site_code_name       -- �����T�C�g����
      ,NULL                               head_sales_branch           -- �Ǌ����_
      ,NULL                               head_sales_branch_name      -- �Ǌ����_����
      ,NULL                               vendor_code                 -- �����
      ,NULL                               vendor_short_name           -- ����旪��
      ,xmrih.based_weight                 based_weight                -- ��{�d��
      ,xmrih.based_capacity               based_capacity              -- ��{�e��
      ,xmrih.sum_weight                   sum_weight                  -- �ύڏd�ʍ��v
      ,xmrih.sum_capacity                 sum_capacity                -- �ύڗe�ύ��v
      ,xmrih.pallet_sum_quantity          pallet_sum_quantity         -- ���v�p���b�g����
      ,xmrih.sum_pallet_weight            sum_pallet_weight           -- ���v�p���b�g�d��
      ,xmrih.loading_efficiency_weight    loading_efficiency_weight   -- �d�ʐύڌ���
      ,xmrih.loading_efficiency_capacity  loading_efficiency_capacity -- �e�ϐύڌ���
      ,xmrih.weight_capacity_class        weight_capacity_class       -- �d�ʗe�ϋ敪
      ,xmrih.item_class                   prod_class                  -- ���i�敪
      ,xmrih.mixed_ratio                  mixed_ratio                 -- ���ڗ�
      ,xmrih.slip_number                  slip_number                 -- �����No
      ,xmrih.small_quantity               small_quantity              -- ������
      ,xmrih.label_quantity               label_quantity              -- ���x������
      ,xmrih.mixed_sign                   mixed_sign                  -- ���ڋL��
      ,NULL                               mixed_no                    -- ���ڌ�No
      ,xmrih.actual_career_id             result_freight_carrier_id   -- �^���Ǝ�_����ID
      ,xmrih.actual_freight_carrier_code  result_freight_carrier_code -- �^���Ǝ�_����
      ,xmrih.actual_shipping_method_code  result_shipping_method_code -- �z���敪_����
      ,xlvv3.attribute6                   result_shipping_kubun_code  -- DFF�����敪_����
      ,xlvv3.attribute9                   result_mixed_class_code     -- DFF���ڋ敪_����
      ,NULL                               result_deliver_to           -- �o�א�_����
      ,NULL                               result_deliver_to_name      -- �o�א�_���і���
      ,xmrih.actual_ship_date             shipped_date                -- �o�ד�
      ,xmrih.actual_arrival_date          arrival_date                -- ���ד�
      --
      ,xmrih.status                       req_status                  -- �X�e�[�^�X
      ,xmrih.notif_status                 notif_status                -- �ʒm�X�e�[�^�X
      ,xmrih.prev_notif_status            prev_notif_status           -- �O��ʒm�X�e�[�^�X
      ,xmrih.notif_date                   notif_date                  -- �m��ʒm���{����
      ,xmrih.new_modify_flg               new_modify_flg              -- �V�K�C���t���O
      ,xmrih.screen_update_by             screen_update_by            -- ��ʍX�V��
      ,xmrih.screen_update_date           screen_update_date          -- ��ʍX�V����
      ,xmrih.prev_delivery_no             prev_delivery_no            -- �O��z����
      ,xmrih.comp_actual_flg              actual_confirm_class        -- ���ьv��ϋ敪
      --
      ,xmrih.created_by                   created_by                  -- �쐬��
      ,xmrih.creation_date                creation_date               -- �쐬��
      ,xmrih.last_updated_by              last_updated_by             -- �ŏI�X�V��
      ,xmrih.last_update_date             last_update_date            -- �ŏI�X�V��
      ,xmrih.last_update_login            last_update_login           -- �ŏI�X�V���O�C��
FROM   xxinv_mov_req_instr_headers xmrih
      ,xxwsh_carriers_schedule     xcs    -- �z�Ԕz���v��
-- 2008/09/02 PT1-1_4 Del D.Nihei Start
--      ,xxcmn_lookup_values_v       xlvv1
-- 2008/09/02 PT1-1_4 Del D.Nihei End
      ,xxcmn_lookup_values_v       xlvv2
      ,xxcmn_lookup_values_v       xlvv3
      ,xxcmn_item_locations_v      xilv
      ,xxcmn_item_locations_v      xilv2
-- 2008/09/02 PT1-1_4 Mod D.Nihei Start
--WHERE  xlvv1.lookup_type          = 'XXWSH_PROCESS_TYPE' 
--AND    xlvv1.lookup_code          = '3'                                -- �������
WHERE  xlvv2.lookup_type(+)       = 'XXCMN_SHIP_METHOD'
-- 2008/09/02 PT1-1_4 Mod D.Nihei End
AND    xlvv2.lookup_code(+)       = xmrih.shipping_method_code         -- �z���敪
AND    xlvv3.lookup_type(+)       = 'XXCMN_SHIP_METHOD'
AND    xlvv3.lookup_code(+)       = xmrih.actual_shipping_method_code  -- �z���敪_����
AND    xilv.segment1(+)           = xmrih.shipped_locat_code           -- �o�׌��ۊǏꏊ���̎擾
AND    xilv2.segment1(+)          = xmrih.ship_to_locat_code           -- �o�א�ۊǏꏊ���擾
AND    xcs.default_line_number(+) = xmrih.mov_num
AND    xcs.delivery_no (+)        = xmrih.delivery_no
AND    xmrih.delivery_no IS NOT NULL;
