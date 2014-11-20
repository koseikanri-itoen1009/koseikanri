CREATE OR REPLACE PACKAGE BODY xxwsh_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh_common2_pkg(BODY)
 * Description            : ���ʊ֐�(OAF�p)(BODY)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.3
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  copy_order_data         F    NUM   �󒍏��R�s�[����
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/04/08   1.0   H.Itou          �V�K�쐬
 *  2008/12/06   1.1   T.Miyata        �R�s�[�쐬���A�o�׎��уC���^�t�F�[�X�σt���O��N(�Œ�)�Ƃ���B
 *  2008/12/16   1.2   D.Nihei         �ǉ��ΏہF���ьv��ϋ敪��ǉ��B
 *  2008/12/19   1.3   M.Hokkanji      �ړ����b�g�ڍו��ʎ��ɒ����O���ѐ��ʂ�ǉ�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'xxwsh_common2_pkg'; -- �p�b�P�[�W��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Function Name   : copy_order_data
   * Description      : �󒍏��R�s�[����
   ***********************************************************************************/
  FUNCTION copy_order_data(
    it_header_id     IN  xxwsh_order_lines_all.order_header_id%TYPE )          -- �󒍃w�b�_�A�h�I��ID
  RETURN NUMBER  -- �V�K�󒍃w�b�_�A�h�I��ID
  IS 
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'copy_order_data'; --�v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
-- Ver1.3 M.Hokkanji Start
    -- *** ���[�J���萔 ***
    cv_document_type_code_10  CONSTANT VARCHAR2(2) := '10';     -- �o��
    cv_document_type_code_30  CONSTANT VARCHAR2(2) := '30';     -- �ړ�
-- Ver1.3 M.Hokkanji End
    -- *** ���[�J���ϐ� ***
    lt_header_id xxwsh_order_headers_all.order_header_id%TYPE;  -- �󒍃w�b�_ID
    lt_line_id   xxwsh_order_headers_all.order_header_id%TYPE;  -- �󒍖���ID
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �󒍃w�b�_�A�h�I���J�[�\��
    CURSOR order_header_cur IS
      SELECT xoha.order_header_id             order_header_id             -- �󒍃w�b�_�A�h�I��ID
            ,xoha.order_type_id               order_type_id               -- �󒍃^�C�vID
            ,xoha.organization_id             organization_id             -- �g�DID
            ,xoha.latest_external_flag        latest_external_flag        -- �ŐV�t���O
            ,xoha.ordered_date                ordered_date                -- �󒍓�
            ,xoha.customer_id                 customer_id                 -- �ڋqID
            ,xoha.customer_code               customer_code               -- �ڋq
            ,xoha.deliver_to_id               deliver_to_id               -- �o�א�ID
            ,xoha.deliver_to                  deliver_to                  -- �o�א�
            ,xoha.shipping_instructions       shipping_instructions       -- �o�׎w��
            ,xoha.career_id                   career_id                   -- �^���Ǝ�ID
            ,xoha.freight_carrier_code        freight_carrier_code        -- �^���Ǝ�
            ,xoha.shipping_method_code        shipping_method_code        -- �z���敪
            ,xoha.cust_po_number              cust_po_number              -- �ڋq����
            ,xoha.price_list_id               price_list_id               -- ���i�\
            ,xoha.request_no                  request_no                  -- �˗�No
-- 2008/12/16 D.Nihei Add Start �{�ԏ�Q#759�Ή�
            ,xoha.base_request_no             base_request_no             -- ���˗�No
-- 2008/12/16 D.Nihei Add End
            ,xoha.req_status                  req_status                  -- �X�e�[�^�X
            ,xoha.delivery_no                 delivery_no                 -- �z��No
            ,xoha.prev_delivery_no            prev_delivery_no            -- �O��z��No
            ,xoha.schedule_ship_date          schedule_ship_date          -- �o�ח\���
            ,xoha.schedule_arrival_date       schedule_arrival_date       -- ���ח\���
            ,xoha.mixed_no                    mixed_no                    -- ���ڌ�No
            ,xoha.collected_pallet_qty        collected_pallet_qty        -- �p���b�g�������
            ,xoha.confirm_request_class       confirm_request_class       -- �����S���m�F�˗��敪
            ,xoha.freight_charge_class        freight_charge_class        -- �^���敪
            ,xoha.shikyu_instruction_class    shikyu_instruction_class    -- �x���o�Ɏw���敪
            ,xoha.shikyu_inst_rcv_class       shikyu_inst_rcv_class       -- �x���w����̋敪
            ,xoha.amount_fix_class            amount_fix_class            -- �L�����z�m��敪
            ,xoha.takeback_class              takeback_class              -- ����敪
            ,xoha.deliver_from_id             deliver_from_id             -- �o�׌�ID
            ,xoha.deliver_from                deliver_from                -- �o�׌��ۊǏꏊ
            ,xoha.head_sales_branch           head_sales_branch           -- �Ǌ����_
            ,xoha.input_sales_branch          input_sales_branch          -- ���͋��_
            ,xoha.po_no                       po_no                       -- ����No
            ,xoha.prod_class                  prod_class                  -- ���i�敪
            ,xoha.item_class                  item_class                  -- �i�ڋ敪
            ,xoha.no_cont_freight_class       no_cont_freight_class       -- �_��O�^���敪
            ,xoha.arrival_time_from           arrival_time_from           -- ���׎���FROM
            ,xoha.arrival_time_to             arrival_time_to             -- ���׎���TO
            ,xoha.designated_item_id          designated_item_id          -- �����i��ID
            ,xoha.designated_item_code        designated_item_code        -- �����i��
            ,xoha.designated_production_date  designated_production_date  -- ������
            ,xoha.designated_branch_no        designated_branch_no        -- �����}��
            ,xoha.slip_number                 slip_number                 -- �����No
            ,xoha.sum_quantity                sum_quantity                -- ���v����
            ,xoha.small_quantity              small_quantity              -- ������
            ,xoha.label_quantity              label_quantity              -- ���x������
            ,xoha.loading_efficiency_weight   loading_efficiency_weight   -- �d�ʐύڌ���
            ,xoha.loading_efficiency_capacity loading_efficiency_capacity -- �e�ϐύڌ���
            ,xoha.based_weight                based_weight                -- ��{�d��
            ,xoha.based_capacity              based_capacity              -- ��{�e��
            ,xoha.sum_weight                  sum_weight                  -- �ύڏd�ʍ��v
            ,xoha.sum_capacity                sum_capacity                -- �ύڗe�ύ��v
            ,xoha.mixed_ratio                 mixed_ratio                 -- ���ڗ�
            ,xoha.pallet_sum_quantity         pallet_sum_quantity         -- �p���b�g���v����
            ,xoha.real_pallet_quantity        real_pallet_quantity        -- �p���b�g���і���
            ,xoha.sum_pallet_weight           sum_pallet_weight           -- ���v�p���b�g�d��
            ,xoha.order_source_ref            order_source_ref            -- �󒍃\�[�X�Q��
            ,xoha.result_freight_carrier_id   result_freight_carrier_id   -- �^���Ǝ�_����ID
            ,xoha.result_freight_carrier_code result_freight_carrier_code -- �^���Ǝ�_����
            ,xoha.result_shipping_method_code result_shipping_method_code -- �z���敪_����
            ,xoha.result_deliver_to_id        result_deliver_to_id        -- �o�א�_����ID
            ,xoha.result_deliver_to           result_deliver_to           -- �o�א�_����
            ,xoha.shipped_date                shipped_date                -- �o�ד�
            ,xoha.arrival_date                arrival_date                -- ���ד�
            ,xoha.weight_capacity_class       weight_capacity_class       -- �d�ʗe�ϋ敪
            ,xoha.notif_status                notif_status                -- �ʒm�X�e�[�^�X
            ,xoha.prev_notif_status           prev_notif_status           -- �O��ʒm�X�e�[�^�X
            ,xoha.notif_date                  notif_date                  -- �m��ʒm���{����
            ,xoha.new_modify_flg              new_modify_flg              -- �V�K�C���t���O
            ,xoha.process_status              process_status              -- �����o�߃X�e�[�^�X
            ,xoha.performance_management_dept performance_management_dept -- ���ъǗ�����
            ,xoha.instruction_dept            instruction_dept            -- �w������
            ,xoha.transfer_location_id        transfer_location_id        -- �U�֐�ID
            ,xoha.transfer_location_code      transfer_location_code      -- �U�֐�
            ,xoha.mixed_sign                  mixed_sign                  -- ���ڋL��
            ,xoha.screen_update_date          screen_update_date          -- ��ʍX�V����
            ,xoha.screen_update_by            screen_update_by            -- ��ʍX�V��
            ,xoha.tightening_date             tightening_date             -- �o�׈˗����ߓ���
            ,xoha.vendor_id                   vendor_id                   -- �����ID
            ,xoha.vendor_code                 vendor_code                 -- �����
            ,xoha.vendor_site_id              vendor_site_id              -- �����T�C�gID
            ,xoha.vendor_site_code            vendor_site_code            -- �����T�C�g
            ,xoha.registered_sequence         registered_sequence         -- �o�^����
            ,xoha.tightening_program_id       tightening_program_id       -- ���߃R���J�����gID
            ,xoha.corrected_tighten_class     corrected_tighten_class     -- ���ߌ�C���敪
      FROM   xxwsh_order_headers_all          xoha                        -- �󒍃w�b�_�A�h�I��
      WHERE  xoha.order_header_id = it_header_id;                         -- IN�p�����[�^.�󒍃w�b�_�A�h�I��ID
--
    -- �󒍖��׃A�h�I���J�[�\��
    CURSOR order_line_cur(ln_header_id NUMBER) IS
      SELECT xola.order_header_id             order_header_id             -- �󒍃w�b�_�A�h�I��ID
            ,xola.order_line_id               order_line_id               -- �󒍖��׃A�h�I��ID
            ,xola.order_line_number           order_line_number           -- ���הԍ�
            ,xola.request_no                  request_no                  -- �˗�No
            ,xola.shipping_inventory_item_id  shipping_inventory_item_id  -- �o�וi��ID
            ,xola.shipping_item_code          shipping_item_code          -- �o�וi��
            ,xola.quantity                    quantity                    -- ����
            ,xola.uom_code                    uom_code                    -- �P��
            ,xola.unit_price                  unit_price                  -- �P��
            ,xola.shipped_quantity            shipped_quantity            -- �o�׎��ѐ���
            ,xola.designated_production_date  designated_production_date  -- �w�萻����
            ,xola.based_request_quantity      based_request_quantity      -- ���_�˗�����
            ,xola.request_item_id             request_item_id             -- �˗��i��ID
            ,xola.request_item_code           request_item_code           -- �˗��i��
            ,xola.ship_to_quantity            ship_to_quantity            -- ���Ɏ��ѐ���
            ,xola.futai_code                  futai_code                  -- �t�уR�[�h
            ,xola.designated_date             designated_date             -- �w����t�i���[�t�j
            ,xola.move_number                 move_number                 -- �ړ�No
            ,xola.po_number                   po_number                   -- ����No
            ,xola.cust_po_number              cust_po_number              -- �ڋq����
            ,xola.pallet_quantity             pallet_quantity             -- �p���b�g��
            ,xola.layer_quantity              layer_quantity              -- �i��
            ,xola.case_quantity               case_quantity               -- �P�[�X��
            ,xola.weight                      weight                      -- �d��
            ,xola.capacity                    capacity                    -- �e��
            ,xola.pallet_qty                  pallet_qty                  -- �p���b�g����
            ,xola.pallet_weight               pallet_weight               -- �p���b�g�d��
            ,xola.reserved_quantity           reserved_quantity           -- ������
            ,xola.automanual_reserve_class    automanual_reserve_class    -- �����蓮�����敪
            ,xola.delete_flag                 delete_flag                 -- �폜�t���O
            ,xola.warning_class               warning_class               -- �x���敪
            ,xola.warning_date                warning_date                -- �x�����t
            ,xola.line_description            line_description            -- �E�v
            ,xola.rm_if_flg                   rm_if_flg                   -- �q�֕ԕi�C���^�t�F�[�X�σt���O
            ,xola.shipping_request_if_flg     shipping_request_if_flg     -- �o�׈˗��C���^�t�F�[�X�σt���O
            ,xola.shipping_result_if_flg      shipping_result_if_flg      -- �o�׎��уC���^�t�F�[�X�σt���O
      FROM   xxwsh_order_lines_all            xola                        -- �󒍖��׃A�h�I��
      WHERE  xola.order_header_id = ln_header_id;                         -- �󒍃w�b�_�A�h�I��ID
--
    -- �ړ����b�g�ڍ׃A�h�I���J�[�\��
    CURSOR mov_lot_dtl_cur(ln_line_id NUMBER) IS
      SELECT xmld.mov_lot_dtl_id            mov_lot_dtl_id            -- ���b�g�ڍ�ID
            ,xmld.mov_line_id               mov_line_id               -- ����ID
            ,xmld.document_type_code        document_type_code        -- �����^�C�v
            ,xmld.record_type_code          record_type_code          -- ���R�[�h�^�C�v
            ,xmld.item_id                   item_id                   -- OPM�i��ID
            ,xmld.item_code                 item_code                 -- �i��
            ,xmld.lot_id                    lot_id                    -- ���b�gID
            ,xmld.lot_no                    lot_no                    -- ���b�gNo
            ,xmld.actual_date               actual_date               -- ���ѓ�
            ,xmld.actual_quantity           actual_quantity           -- ���ѐ���
            ,xmld.automanual_reserve_class  automanual_reserve_class  -- �����蓮�����敪
      FROM   xxinv_mov_lot_details          xmld                      -- �ړ����b�g�ڍ׃A�h�I��
-- Ver1.3 M.Hokkanji Start
     WHERE   xmld.mov_line_id = ln_line_id                            -- �󒍖��׃A�h�I��ID
       AND   xmld.document_type_code IN (cv_document_type_code_10
                                        ,cv_document_type_code_30);   -- �����^�C�v
--      WHERE  xmld.mov_line_id = ln_line_id;                           -- �󒍖��׃A�h�I��ID
-- Ver1.3 M.Hokkanji End
--
    -- *** ���[�J���E���R�[�h ***
    order_header_rec  order_header_cur%ROWTYPE;
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
--
    -- �󒍃w�b�_�A�h�I��ID�擾
    SELECT xxwsh_order_headers_all_s1.NEXTVAL header_id
    INTO   lt_header_id
    FROM   DUAL;
--
    -- �󒍃w�b�_���擾
    OPEN  order_header_cur;
    FETCH order_header_cur INTO order_header_rec;
    CLOSE order_header_cur;
--
    -- ***********************************************
    -- ***  �󒍃w�b�_�A�h�I���R�s�[�쐬����       ***
    -- ***********************************************
    INSERT INTO xxwsh_order_headers_all xoha(
       xoha.order_header_id              -- �󒍃w�b�_�A�h�I��ID
      ,xoha.order_type_id                -- �󒍃^�C�vID
      ,xoha.organization_id              -- �g�DID
      ,xoha.latest_external_flag         -- �ŐV�t���O
      ,xoha.ordered_date                 -- �󒍓�
      ,xoha.customer_id                  -- �ڋqID
      ,xoha.customer_code                -- �ڋq
      ,xoha.deliver_to_id                -- �o�א�ID
      ,xoha.deliver_to                   -- �o�א�
      ,xoha.shipping_instructions        -- �o�׎w��
      ,xoha.career_id                    -- �^���Ǝ�ID
      ,xoha.freight_carrier_code         -- �^���Ǝ�
      ,xoha.shipping_method_code         -- �z���敪
      ,xoha.cust_po_number               -- �ڋq����
      ,xoha.price_list_id                -- ���i�\
      ,xoha.request_no                   -- �˗�No
-- 2008/12/16 D.Nihei Add Start �{�ԏ�Q#759�Ή�
      ,xoha.base_request_no              -- ���˗�No
-- 2008/12/16 D.Nihei Add End
      ,xoha.req_status                   -- �X�e�[�^�X
      ,xoha.delivery_no                  -- �z��No
      ,xoha.prev_delivery_no             -- �O��z��No
      ,xoha.schedule_ship_date           -- �o�ח\���
      ,xoha.schedule_arrival_date        -- ���ח\���
      ,xoha.mixed_no                     -- ���ڌ�No
      ,xoha.collected_pallet_qty         -- �p���b�g�������
      ,xoha.confirm_request_class        -- �����S���m�F�˗��敪
      ,xoha.freight_charge_class         -- �^���敪
      ,xoha.shikyu_instruction_class     -- �x���o�Ɏw���敪
      ,xoha.shikyu_inst_rcv_class        -- �x���w����̋敪
      ,xoha.amount_fix_class             -- �L�����z�m��敪
      ,xoha.takeback_class               -- ����敪
      ,xoha.deliver_from_id              -- �o�׌�ID
      ,xoha.deliver_from                 -- �o�׌��ۊǏꏊ
      ,xoha.head_sales_branch            -- �Ǌ����_
      ,xoha.input_sales_branch           -- ���͋��_
      ,xoha.po_no                        -- ����No
      ,xoha.prod_class                   -- ���i�敪
      ,xoha.item_class                   -- �i�ڋ敪
      ,xoha.no_cont_freight_class        -- �_��O�^���敪
      ,xoha.arrival_time_from            -- ���׎���FROM
      ,xoha.arrival_time_to              -- ���׎���TO
      ,xoha.designated_item_id           -- �����i��ID
      ,xoha.designated_item_code         -- �����i��
      ,xoha.designated_production_date   -- ������
      ,xoha.designated_branch_no         -- �����}��
      ,xoha.slip_number                  -- �����No
      ,xoha.sum_quantity                 -- ���v����
      ,xoha.small_quantity               -- ������
      ,xoha.label_quantity               -- ���x������
      ,xoha.loading_efficiency_weight    -- �d�ʐύڌ���
      ,xoha.loading_efficiency_capacity  -- �e�ϐύڌ���
      ,xoha.based_weight                 -- ��{�d��
      ,xoha.based_capacity               -- ��{�e��
      ,xoha.sum_weight                   -- �ύڏd�ʍ��v
      ,xoha.sum_capacity                 -- �ύڗe�ύ��v
      ,xoha.mixed_ratio                  -- ���ڗ�
      ,xoha.pallet_sum_quantity          -- �p���b�g���v����
      ,xoha.real_pallet_quantity         -- �p���b�g���і���
      ,xoha.sum_pallet_weight            -- ���v�p���b�g�d��
      ,xoha.order_source_ref             -- �󒍃\�[�X�Q��
      ,xoha.result_freight_carrier_id    -- �^���Ǝ�_����ID
      ,xoha.result_freight_carrier_code  -- �^���Ǝ�_����
      ,xoha.result_shipping_method_code  -- �z���敪_����
      ,xoha.result_deliver_to_id         -- �o�א�_����ID
      ,xoha.result_deliver_to            -- �o�א�_����
      ,xoha.shipped_date                 -- �o�ד�
      ,xoha.arrival_date                 -- ���ד�
      ,xoha.weight_capacity_class        -- �d�ʗe�ϋ敪
-- 2008/12/16 D.Nihei Add Start �{�ԏ�Q#759�Ή�
      ,xoha.actual_confirm_class         -- ���ьv��ϋ敪
-- 2008/12/16 D.Nihei Add End
      ,xoha.notif_status                 -- �ʒm�X�e�[�^�X
      ,xoha.prev_notif_status            -- �O��ʒm�X�e�[�^�X
      ,xoha.notif_date                   -- �m��ʒm���{����
      ,xoha.new_modify_flg               -- �V�K�C���t���O
      ,xoha.process_status               -- �����o�߃X�e�[�^�X
      ,xoha.performance_management_dept  -- ���ъǗ�����
      ,xoha.instruction_dept             -- �w������
      ,xoha.transfer_location_id         -- �U�֐�ID
      ,xoha.transfer_location_code       -- �U�֐�
      ,xoha.mixed_sign                   -- ���ڋL��
      ,xoha.screen_update_date           -- ��ʍX�V����
      ,xoha.screen_update_by             -- ��ʍX�V��
      ,xoha.tightening_date              -- �o�׈˗����ߓ���
      ,xoha.vendor_id                    -- �����ID
      ,xoha.vendor_code                  -- �����
      ,xoha.vendor_site_id               -- �����T�C�gID
      ,xoha.vendor_site_code             -- �����T�C�g
      ,xoha.registered_sequence          -- �o�^����
      ,xoha.tightening_program_id        -- ���߃R���J�����gID
      ,xoha.corrected_tighten_class      -- ���ߌ�C���敪
      ,xoha.created_by                   -- �쐬��
      ,xoha.creation_date                -- �쐬��
      ,xoha.last_updated_by              -- �ŏI�X�V��
      ,xoha.last_update_date             -- �ŏI�X�V��
      ,xoha.last_update_login)           -- �ŏI�X�V���O�C��
    VALUES(
       lt_header_id                                  -- �󒍃w�b�_�A�h�I��ID
      ,order_header_rec.order_type_id                -- �󒍃^�C�vID
      ,order_header_rec.organization_id              -- �g�DID
      ,order_header_rec.latest_external_flag         -- �ŐV�t���O
      ,order_header_rec.ordered_date                 -- �󒍓�
      ,order_header_rec.customer_id                  -- �ڋqID
      ,order_header_rec.customer_code                -- �ڋq
      ,order_header_rec.deliver_to_id                -- �o�א�ID
      ,order_header_rec.deliver_to                   -- �o�א�
      ,order_header_rec.shipping_instructions        -- �o�׎w��
      ,order_header_rec.career_id                    -- �^���Ǝ�ID
      ,order_header_rec.freight_carrier_code         -- �^���Ǝ�
      ,order_header_rec.shipping_method_code         -- �z���敪
      ,order_header_rec.cust_po_number               -- �ڋq����
      ,order_header_rec.price_list_id                -- ���i�\
      ,order_header_rec.request_no                   -- �˗�No
-- 2008/12/16 D.Nihei Add Start �{�ԏ�Q#759�Ή�
      ,order_header_rec.base_request_no              -- ���˗�No
-- 2008/12/16 D.Nihei Add End
      ,order_header_rec.req_status                   -- �X�e�[�^�X
      ,order_header_rec.delivery_no                  -- �z��No
      ,order_header_rec.prev_delivery_no             -- �O��z��No
      ,order_header_rec.schedule_ship_date           -- �o�ח\���
      ,order_header_rec.schedule_arrival_date        -- ���ח\���
      ,order_header_rec.mixed_no                     -- ���ڌ�No
      ,order_header_rec.collected_pallet_qty         -- �p���b�g�������
      ,order_header_rec.confirm_request_class        -- �����S���m�F�˗��敪
      ,order_header_rec.freight_charge_class         -- �^���敪
      ,order_header_rec.shikyu_instruction_class     -- �x���o�Ɏw���敪
      ,order_header_rec.shikyu_inst_rcv_class        -- �x���w����̋敪
      ,order_header_rec.amount_fix_class             -- �L�����z�m��敪
      ,order_header_rec.takeback_class               -- ����敪
      ,order_header_rec.deliver_from_id              -- �o�׌�ID
      ,order_header_rec.deliver_from                 -- �o�׌��ۊǏꏊ
      ,order_header_rec.head_sales_branch            -- �Ǌ����_
      ,order_header_rec.input_sales_branch           -- ���͋��_
      ,order_header_rec.po_no                        -- ����No
      ,order_header_rec.prod_class                   -- ���i�敪
      ,order_header_rec.item_class                   -- �i�ڋ敪
      ,order_header_rec.no_cont_freight_class        -- �_��O�^���敪
      ,order_header_rec.arrival_time_from            -- ���׎���FROM
      ,order_header_rec.arrival_time_to              -- ���׎���TO
      ,order_header_rec.designated_item_id           -- �����i��ID
      ,order_header_rec.designated_item_code         -- �����i��
      ,order_header_rec.designated_production_date   -- ������
      ,order_header_rec.designated_branch_no         -- �����}��
      ,order_header_rec.slip_number                  -- �����No
      ,order_header_rec.sum_quantity                 -- ���v����
      ,order_header_rec.small_quantity               -- ������
      ,order_header_rec.label_quantity               -- ���x������
      ,order_header_rec.loading_efficiency_weight    -- �d�ʐύڌ���
      ,order_header_rec.loading_efficiency_capacity  -- �e�ϐύڌ���
      ,order_header_rec.based_weight                 -- ��{�d��
      ,order_header_rec.based_capacity               -- ��{�e��
      ,order_header_rec.sum_weight                   -- �ύڏd�ʍ��v
      ,order_header_rec.sum_capacity                 -- �ύڗe�ύ��v
      ,order_header_rec.mixed_ratio                  -- ���ڗ�
      ,order_header_rec.pallet_sum_quantity          -- �p���b�g���v����
      ,order_header_rec.real_pallet_quantity         -- �p���b�g���і���
      ,order_header_rec.sum_pallet_weight            -- ���v�p���b�g�d��
      ,order_header_rec.order_source_ref             -- �󒍃\�[�X�Q��
      ,order_header_rec.result_freight_carrier_id    -- �^���Ǝ�_����ID
      ,order_header_rec.result_freight_carrier_code  -- �^���Ǝ�_����
      ,order_header_rec.result_shipping_method_code  -- �z���敪_����
      ,order_header_rec.result_deliver_to_id         -- �o�א�_����ID
      ,order_header_rec.result_deliver_to            -- �o�א�_����
      ,order_header_rec.shipped_date                 -- �o�ד�
      ,order_header_rec.arrival_date                 -- ���ד�
      ,order_header_rec.weight_capacity_class        -- �d�ʗe�ϋ敪
-- 2008/12/16 D.Nihei Add Start �{�ԏ�Q#759�Ή�
      ,'N'                                           -- ���ьv��ϋ敪
-- 2008/12/16 D.Nihei Add End
      ,order_header_rec.notif_status                 -- �ʒm�X�e�[�^�X
      ,order_header_rec.prev_notif_status            -- �O��ʒm�X�e�[�^�X
      ,order_header_rec.notif_date                   -- �m��ʒm���{����
      ,order_header_rec.new_modify_flg               -- �V�K�C���t���O
      ,order_header_rec.process_status               -- �����o�߃X�e�[�^�X
      ,order_header_rec.performance_management_dept  -- ���ъǗ�����
      ,order_header_rec.instruction_dept             -- �w������
      ,order_header_rec.transfer_location_id         -- �U�֐�ID
      ,order_header_rec.transfer_location_code       -- �U�֐�
      ,order_header_rec.mixed_sign                   -- ���ڋL��
      ,order_header_rec.screen_update_date           -- ��ʍX�V����
      ,order_header_rec.screen_update_by             -- ��ʍX�V��
      ,order_header_rec.tightening_date              -- �o�׈˗����ߓ���
      ,order_header_rec.vendor_id                    -- �����ID
      ,order_header_rec.vendor_code                  -- �����
      ,order_header_rec.vendor_site_id               -- �����T�C�gID
      ,order_header_rec.vendor_site_code             -- �����T�C�g
      ,order_header_rec.registered_sequence          -- �o�^����
      ,order_header_rec.tightening_program_id        -- ���߃R���J�����gID
      ,order_header_rec.corrected_tighten_class      -- ���ߌ�C���敪
      ,FND_GLOBAL.USER_ID          -- �쐬��
      ,SYSDATE                     -- �쐬��
      ,FND_GLOBAL.USER_ID          -- �ŏI�X�V��
      ,SYSDATE                     -- �ŏI�X�V��
      ,FND_GLOBAL.LOGIN_ID         -- �ŏI�X�V���O�C��
    );
--
    -- ***********************************************
    -- ***  �󒍃w�b�_�A�h�I���ŐV�t���O�X�V����   ***
    -- ***********************************************
    -- �O�񗚗��̍ŐV�t���O���uN�v�ɍX�V����B
    UPDATE xxwsh_order_headers_all xoha
    SET    xoha.latest_external_flag = 'N'                         -- �ŐV�t���O
          ,xoha.last_updated_by      = FND_GLOBAL.USER_ID          -- �ŏI�X�V��
          ,xoha.last_update_date     = SYSDATE                     -- �ŏI�X�V��
          ,xoha.last_update_login    = FND_GLOBAL.LOGIN_ID         -- �ŏI�X�V���O�C��
    WHERE xoha.order_header_id       = order_header_rec.order_header_id;  -- �󒍃w�b�_�A�h�I��ID
--
    <<order_line_loop>>
    FOR  order_line_rec IN order_line_cur(order_header_rec.order_header_id)
    LOOP
      -- �󒍖��׃A�h�I��ID�擾
      SELECT xxwsh_order_lines_all_s1.NEXTVAL line_id
      INTO   lt_line_id
      FROM   DUAL;
--
      -- *********************************************
      -- ***  �󒍖��׃A�h�I���R�s�[�쐬����       ***
      -- *********************************************
      INSERT INTO xxwsh_order_lines_all xola(
         xola.order_line_id                 -- �󒍖��׃A�h�I��ID
        ,xola.order_header_id               -- �󒍃w�b�_�A�h�I��ID
        ,xola.order_line_number             -- ���הԍ�
        ,xola.request_no                    -- �˗�No
        ,xola.shipping_inventory_item_id    -- �o�וi��ID
        ,xola.shipping_item_code            -- �o�וi��
        ,xola.quantity                      -- ����
        ,xola.uom_code                      -- �P��
        ,xola.unit_price                    -- �P��
        ,xola.shipped_quantity              -- �o�׎��ѐ���
        ,xola.designated_production_date    -- �w�萻����
        ,xola.based_request_quantity        -- ���_�˗�����
        ,xola.request_item_id               -- �˗��i��ID
        ,xola.request_item_code             -- �˗��i��
        ,xola.ship_to_quantity              -- ���Ɏ��ѐ���
        ,xola.futai_code                    -- �t�уR�[�h
        ,xola.designated_date               -- �w����t�i���[�t�j
        ,xola.move_number                   -- �ړ�No
        ,xola.po_number                     -- ����No
        ,xola.cust_po_number                -- �ڋq����
        ,xola.pallet_quantity               -- �p���b�g��
        ,xola.layer_quantity                -- �i��
        ,xola.case_quantity                 -- �P�[�X��
        ,xola.weight                        -- �d��
        ,xola.capacity                      -- �e��
        ,xola.pallet_qty                    -- �p���b�g����
        ,xola.pallet_weight                 -- �p���b�g�d��
        ,xola.reserved_quantity             -- ������
        ,xola.automanual_reserve_class      -- �����蓮�����敪
        ,xola.delete_flag                   -- �폜�t���O
        ,xola.warning_class                 -- �x���敪
        ,xola.warning_date                  -- �x�����t
        ,xola.line_description              -- �E�v
        ,xola.rm_if_flg                     -- �q�֕ԕi�C���^�t�F�[�X�σt���O
        ,xola.shipping_request_if_flg       -- �o�׈˗��C���^�t�F�[�X�σt���O
        ,xola.shipping_result_if_flg        -- �o�׎��уC���^�t�F�[�X�σt���O
        ,xola.created_by                    -- �쐬��
        ,xola.creation_date                 -- �쐬��
        ,xola.last_updated_by               -- �ŏI�X�V��
        ,xola.last_update_date              -- �ŏI�X�V��
        ,xola.last_update_login)            -- �ŏI�X�V���O�C��
      VALUES(
         lt_line_id                                   -- �󒍖��׃A�h�I��ID
        ,lt_header_id                                 -- �󒍃w�b�_�A�h�I��ID
        ,order_line_rec.order_line_number             -- ���הԍ�
        ,order_line_rec.request_no                    -- �˗�No
        ,order_line_rec.shipping_inventory_item_id    -- �o�וi��ID
        ,order_line_rec.shipping_item_code            -- �o�וi��
        ,order_line_rec.quantity                      -- ����
        ,order_line_rec.uom_code                      -- �P��
        ,order_line_rec.unit_price                    -- �P��
        ,order_line_rec.shipped_quantity              -- �o�׎��ѐ���
        ,order_line_rec.designated_production_date    -- �w�萻����
        ,order_line_rec.based_request_quantity        -- ���_�˗�����
        ,order_line_rec.request_item_id               -- �˗��i��ID
        ,order_line_rec.request_item_code             -- �˗��i��
        ,order_line_rec.ship_to_quantity              -- ���Ɏ��ѐ���
        ,order_line_rec.futai_code                    -- �t�уR�[�h
        ,order_line_rec.designated_date               -- �w����t�i���[�t�j
        ,order_line_rec.move_number                   -- �ړ�No
        ,order_line_rec.po_number                     -- ����No
        ,order_line_rec.cust_po_number                -- �ڋq����
        ,order_line_rec.pallet_quantity               -- �p���b�g��
        ,order_line_rec.layer_quantity                -- �i��
        ,order_line_rec.case_quantity                 -- �P�[�X��
        ,order_line_rec.weight                        -- �d��
        ,order_line_rec.capacity                      -- �e��
        ,order_line_rec.pallet_qty                    -- �p���b�g����
        ,order_line_rec.pallet_weight                 -- �p���b�g�d��
        ,order_line_rec.reserved_quantity             -- ������
        ,order_line_rec.automanual_reserve_class      -- �����蓮�����敪
        ,order_line_rec.delete_flag                   -- �폜�t���O
        ,order_line_rec.warning_class                 -- �x���敪
        ,order_line_rec.warning_date                  -- �x�����t
        ,order_line_rec.line_description              -- �E�v
        ,order_line_rec.rm_if_flg                     -- �q�֕ԕi�C���^�t�F�[�X�σt���O
        ,order_line_rec.shipping_request_if_flg       -- �o�׈˗��C���^�t�F�[�X�σt���O
-- 2008/12/06 T.Miyata Modify Start #484 �R�s�[�쐬���ɂ�IF����Ă��Ȃ����߁A�o�׎��уC���^�t�F�[�X�σt���O��N�Ƃ���B
--        ,order_line_rec.shipping_result_if_flg        -- �o�׎��уC���^�t�F�[�X�σt���O
        ,'N'                         -- �o�׎��уC���^�t�F�[�X�σt���O
-- 2008/12/06 T.Miyata Modify End #484
        ,FND_GLOBAL.USER_ID          -- �쐬��
        ,SYSDATE                     -- �쐬��
        ,FND_GLOBAL.USER_ID          -- �ŏI�X�V��
        ,SYSDATE                     -- �ŏI�X�V��
        ,FND_GLOBAL.LOGIN_ID         -- �ŏI�X�V���O�C��
      );
--
      -- *********************************************
      -- ***  �ړ����b�g�ڍ׃A�h�I���R�s�[�쐬���� ***
      -- *********************************************
      <<mov_lot_dtl_loop>>
      FOR mov_lot_dtl_rec IN mov_lot_dtl_cur(order_line_rec.order_line_id)
      LOOP
        INSERT INTO xxinv_mov_lot_details xmld(
           xmld.mov_lot_dtl_id              -- ���b�g�ڍ�ID
          ,xmld.mov_line_id                 -- ����ID
          ,xmld.document_type_code          -- �����^�C�v
          ,xmld.record_type_code            -- ���R�[�h�^�C�v
          ,xmld.item_id                     -- OPM�i��ID
          ,xmld.item_code                   -- �i��
          ,xmld.lot_id                      -- ���b�gID
          ,xmld.lot_no                      -- ���b�gNo
          ,xmld.actual_date                 -- ���ѓ�
          ,xmld.actual_quantity             -- ���ѐ���
-- Ver1.3 M.Hokkanji Start
          ,xmld.before_actual_quantity      -- �����O���ѐ���
-- Ver1.3 M.Hokkanji End
          ,xmld.automanual_reserve_class    -- �����蓮�����敪
          ,xmld.created_by                  -- �쐬��
          ,xmld.creation_date               -- �쐬��
          ,xmld.last_updated_by             -- �ŏI�X�V��
          ,xmld.last_update_date            -- �ŏI�X�V��
          ,xmld.last_update_login)          -- �ŏI�X�V���O�C��
        VALUES(
           xxinv_mov_lot_s1.NEXTVAL                    -- ���b�g�ڍ�ID
          ,lt_line_id                                  -- ����ID
          ,mov_lot_dtl_rec.document_type_code          -- �����^�C�v
          ,mov_lot_dtl_rec.record_type_code            -- ���R�[�h�^�C�v
          ,mov_lot_dtl_rec.item_id                     -- OPM�i��ID
          ,mov_lot_dtl_rec.item_code                   -- �i��
          ,mov_lot_dtl_rec.lot_id                      -- ���b�gID
          ,mov_lot_dtl_rec.lot_no                      -- ���b�gNo
          ,mov_lot_dtl_rec.actual_date                 -- ���ѓ�
          ,mov_lot_dtl_rec.actual_quantity             -- ���ѐ���
-- Ver1.3 M.Hokkanji Start
-- EBS�ɓo�^����Ă���f�[�^��ł��������ߎ��ѐ��ʂ��Z�b�g
          ,mov_lot_dtl_rec.actual_quantity             -- �����O���ѐ���
-- Ver1.3 M.Hokkanji End
          ,mov_lot_dtl_rec.automanual_reserve_class    -- �����蓮�����敪
          ,FND_GLOBAL.USER_ID          -- �쐬��
          ,SYSDATE                     -- �쐬��
          ,FND_GLOBAL.USER_ID          -- �ŏI�X�V��
          ,SYSDATE                     -- �ŏI�X�V��
          ,FND_GLOBAL.LOGIN_ID         -- �ŏI�X�V���O�C��
        );
      END LOOP mov_lot_dtl_loop;
    END LOOP order_line_loop;
--
    -- �󒍃w�b�_�A�h�I��ID��Ԃ��B
    RETURN lt_header_id;
--
  EXCEPTION
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      IF (order_header_cur%ISOPEN) THEN
        CLOSE order_header_cur;
      END IF;
      IF (order_line_cur%ISOPEN) THEN
        CLOSE order_line_cur;
      END IF;
--
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END copy_order_data;
--
END xxwsh_common2_pkg;
/
