CREATE OR REPLACE PACKAGE BODY xxwsh420001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH420001C(spec)
 * Description      : �o�׈˗�/�o�׎��э쐬����
 * MD.050           : �o�׎��� T_MD050_BPO_420
 * MD.070           : �o�׈˗��o�׎��э쐬���� T_MD070_BPO_42A
 * Version          : 1.7
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *
 *  input_param_check            A1���̓p�����[�^�`�F�b�N
 *  get_profile                  A2�v���t�@�C���l�擾
 *  get_order_info               A3�󒍃A�h�I�����擾
 *  get_same_request_number      A4����˗�No��������
 *  get_revised order_info       A5�����O�󒍃w�b�_�A�h�I�����擾
 *  create_order_header_info     A6�󒍃w�b�_���̓o�^
 *  create_order_line_info       A7�󒍖��׃��R�[�h�쐬�AA8�󒍖��דo�^
 *  delivery_action_proc         A9�s�b�N�����[�XAPI�N��
 *  get_lot_details              A10���b�g���擾
 *  set_allocate_opm_order       A11�݌Ɋ���API�N��
 *  pick_confirm_proc            �ړ��I�[�_�������
 *  confirm_proc                 A12�o�׊m�FAPI�N��
 *  create_rma_order_header_info A13RMA�󒍃w�b�_���̓o�^
 *  create_rma_order_line_info   A14RMA�󒍖��׃��R�[�h�쐬�AA15RMA�󒍖��דo�^
 *  create_lot_details           A16���b�g���쐬
 *  upd_status                   A17�X�e�[�^�X�X�V
 *  shipping_process             �o�׏��o�^����
 *  return_process               �ԕi���o�^����
 *  ins_mov_lot_details          A18�ړ����b�g�ڍ�(�A�h�I��)�o�^
 *  ins_transaction_interface    A19�������I�[�v���C���^�t�F�[�X�e�[�u���o�^����
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/03/24    1.0   Oracle �k���� ���v ����쐬
 *  2008/05/14    1.1   Oracle �{�c ���j   MD050�w�E������No56���f
 *  2008/05/19    1.2   Oracle �{�c ���j   �˗�No��TO_NUMBER���p�~
 *  2008/05/22    1.3   Oracle �{�c ���j   �󒍖��׍쐬���̒P��NULL�Ή�
 *  2008/06/12    1.4   Oracle �ۉ� ����   �󒍃w�b�_�A���׍X�V���̑Ώ�WHO�J������ǉ�
 *  2008/06/27    1.5   Oracle �ۉ� ����   �󒍖��דo�^���̍폜�t���O��N��ݒ�
 *  2008/09/01    1.6   Oracle �R�� ��_   �ۑ�#64�ύX#176�Ή�
 *  2008/10/10    1.7   Oracle �ɓ� �ЂƂ� �����e�X�g�w�E116�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';    --����
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';    --�x��
  gv_status_error  CONSTANT VARCHAR2(1) := '2';    --���s
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';    --�X�e�[�^�X(����)
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';    --�X�e�[�^�X(�x��)
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';    --�X�e�[�^�X(���s)
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);            -- ��؂蕶��
  gv_exec_user     VARCHAR2(100);             -- ���s���[�U��
  gv_conc_name     VARCHAR2(30);              -- ���s�R���J�����g��
  gv_conc_status   VARCHAR2(30);              -- ���s����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O **
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  check_sub_main_expt         EXCEPTION;     -- �T�u���C���̃G���[
  lock_error_expt             EXCEPTION;     -- ���b�N�G���[
  order_error_expt            EXCEPTION;     -- �󒍏����G���[�i�����o�߃X�e�[�^�X�X�V�����N���̂���)
--
  PRAGMA EXCEPTION_INIT(lock_error_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--
  gv_msg_kbn             CONSTANT VARCHAR2(5)   := 'XXCMN';
  gv_msg_kbn_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH';
--
  gv_pkg_name            CONSTANT VARCHAR2(100) := 'xxwsh420001c';    -- �p�b�P�[�W��
--
  --���b�Z�[�W�ԍ�(�Œ菈��)
  gv_msg_42a_001         CONSTANT VARCHAR2(15)
                         := 'APP-XXCMN-00001';  -- ���[�U�[��
  gv_msg_42a_002         CONSTANT VARCHAR2(15)
                         := 'APP-XXCMN-00002';  -- �R���J�����g��
  gv_msg_42a_003         CONSTANT VARCHAR2(15)
                         := 'APP-XXCMN-00003';  -- �Z�p���[�^
  gv_msg_42a_004         CONSTANT VARCHAR2(15)
                         := 'APP-XXCMN-00012';  -- �����X�e�[�^�X
  gv_msg_42a_005         CONSTANT VARCHAR2(15)
                         := 'APP-XXCMN-10030';  -- �R���J�����g��^�G���[
  gv_msg_42a_006         CONSTANT VARCHAR2(15)
                         := 'APP-XXCMN-10118';  -- �N������
  --���b�Z�[�W�ԍ�(���R���J�����g��p)
  gv_msg_42a_007         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01551';  -- ���̓p�����[�^�\��(�u���b�N)
  gv_msg_42a_008         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01552';  -- ���̓p�����[�^�\��(�o�׌�)
  gv_msg_42a_009         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01553';  -- ���̓p�����[�^�\��(�˗�No)
  gv_msg_42a_010         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01554';  -- ���͌���(�˗�No)
  gv_msg_42a_011         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01555';  -- �V�K�󒍍쐬����
  gv_msg_42a_012         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01556';  -- �����󒍍쐬����
  gv_msg_42a_013         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01557';  -- �����񌏐�
  gv_msg_42a_014         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-01558';  -- �ُ팏��
  gv_msg_42a_015         CONSTANT VARCHAR2(15) 
                         := 'APP-XXWSH-01559';  -- �����������R���J�����g�v��ID
  gv_msg_42a_016         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11551';  -- API�G���[
  gv_msg_42a_017         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11552';  -- �u���b�N�擾�G���[���b�Z�[�W
  gv_msg_42a_018         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11553';  -- �v���t�@�C���擾�G���[
  gv_msg_42a_019         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11554';  -- ���b�N�G���[
  gv_msg_42a_020         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11555';  -- �����������G���[
  gv_msg_42a_021         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11556';  -- �o�׌��擾�G���[���b�Z�[�W
  gv_msg_42a_022         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11557';  -- ����˗�No�����G���[
  gv_msg_42a_023         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11558';  -- �����O�󒍃A�h�I�����擾�G���[
  gv_msg_42a_024         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-11559';  -- �g�p�ړIID�擾�G���[
-- 2008/09/01 Add
  gv_msg_42a_025         CONSTANT VARCHAR2(15)
                         := 'APP-XXWSH-13181';  -- �������G���[���b�Z�[�W
--
  --�g�[�N��(�Œ菈��)
  gv_tkn_status          CONSTANT VARCHAR2(15) := 'STATUS';
  gv_tkn_conc            CONSTANT VARCHAR2(15) := 'CONC';
  gv_tkn_user            CONSTANT VARCHAR2(15) := 'USER';
  gv_tkn_time            CONSTANT VARCHAR2(15) := 'TIME';
  --�g�[�N��(���R���J�����g��p)
  gv_tkn_in_block        CONSTANT VARCHAR2(15) := 'IN_BLOCK';
  gv_tkn_in_shipf        CONSTANT VARCHAR2(15) := 'IN_SHIPF';
  gv_tkn_request_no      CONSTANT VARCHAR2(15) := 'REQUEST_NO';
  gv_tkn_input_cnt       CONSTANT VARCHAR2(15) := 'INPUT_CNT';
  gv_tkn_new_order       CONSTANT VARCHAR2(15) := 'NEW_ORDER';
  gv_tkn_upd_order       CONSTANT VARCHAR2(15) := 'UPD_ORDER';
  gv_tkn_cancell_cnt     CONSTANT VARCHAR2(15) := 'CANCELL_CNT';
  gv_tkn_error_cnt       CONSTANT VARCHAR2(15) := 'ERROR_CNT';
  gv_tkn_error_msg       CONSTANT VARCHAR2(15) := 'ERR_MSG';
  gv_tkn_prof_name       CONSTANT VARCHAR2(15) := 'PROF_NAME';
  gv_tkn_api_name        CONSTANT VARCHAR2(15) := 'API_NAME';
  gv_tkn_meaning         CONSTANT VARCHAR2(15) := 'MEANING';
  gv_tkn_lookup_type     CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';
  gv_tkn_request_id      CONSTANT VARCHAR2(15) := 'REQUEST_ID';
  gv_tkn_order_header_id CONSTANT VARCHAR2(15) := 'ORDER_HEADER_ID';
  gv_tkn_header_id       CONSTANT VARCHAR2(15) := 'HEADER_ID';
  gv_tkn_message_tokun   CONSTANT VARCHAR2(15) := 'MESSAGE_TOKUN';
  gv_tkn_search          CONSTANT VARCHAR2(15) := 'SEARCH';
-- 2008/09/01 Add
  gv_tkn_para_date       CONSTANT VARCHAR2(15) := 'PARA_DATE';
  gv_tkn_param1          CONSTANT VARCHAR2(15) := 'PARAM1';
  gv_tkn_param2          CONSTANT VARCHAR2(15) := 'PARAM2';
  gv_tkn_param3          CONSTANT VARCHAR2(15) := 'PARAM3';
  gv_tkn_param4          CONSTANT VARCHAR2(15) := 'PARAM4';
--
  -- �g�[�N���\���p
  gv_api_name_1          CONSTANT VARCHAR2(30) := '�\��';
  gv_api_name_2          CONSTANT VARCHAR2(30) := '�s�b�N�����[�X�p�b�`�쐬';
  gv_api_name_3          CONSTANT VARCHAR2(30) := '�󒍍쐬';
  gv_api_name_4          CONSTANT VARCHAR2(30) := '�v���Z�X�I�[�_�������';
  gv_api_name_5          CONSTANT VARCHAR2(30) := '�o�׊m�F�̍쐬';
  gv_api_name_6          CONSTANT VARCHAR2(30) := '�s�b�N�����[�X�p�b�`���s';
  gv_message_tokun1      CONSTANT VARCHAR2(30) := '�ڋqID';
  gv_message_tokun2      CONSTANT VARCHAR2(30) := '�p�[�e�B�T�C�gID';
  -- �����������p
  gv_application         CONSTANT VARCHAR2(15) := 'PO';
  gv_program             CONSTANT VARCHAR2(15) := 'RVCTP';
--
  gv_yes                 CONSTANT VARCHAR2(1)
                         := 'Y';                        -- YES_NO�敪�iYES)
  gv_no                  CONSTANT VARCHAR2(1)
                         := 'N';                        -- YES_NO�敪�iNO)
  gv_appl_code           CONSTANT VARCHAR2(15)
                         := 'XXCMN';                    -- �`�F�b�N�Ώۂ̃A�v���P�[�V�����Z�k��
  gv_vappl_code          CONSTANT VARCHAR2(15)
                         := 'AU';                       -- �`�F�b�N�Ώۂ�VIEW�A�v���P�[�V�����Z�k��
  gv_order_type_order    CONSTANT VARCHAR2(15)
                         := 'ORDER';                    -- �󒍃J�e�S��(��)
  gv_order_type_return   CONSTANT VARCHAR2(15)
                         := 'RETURN';                   -- �󒍃J�e�S��(�ԕi)
  gv_lot_ctl_1           CONSTANT VARCHAR2(1)
                         := '1';                        -- ���b�g�Ǘ��i
  gv_new                 CONSTANT VARCHAR2(15)
                         := 'NEW';                      -- �������o�^�Ŏg�p
  gv_pending             CONSTANT VARCHAR2(15)
                         := 'PENDING';                  -- �������o�^�Ŏg�p
  gv_customer            CONSTANT VARCHAR2(15)
                         := 'CUSTOMER';                 -- �������o�^�Ŏg�p
  gv_receive             CONSTANT VARCHAR2(15)
                         := 'RECEIVE';                  -- �������o�^�Ŏg�p
  gv_batch               CONSTANT VARCHAR2(15)
                         := 'BATCH';                    -- �������o�^�Ŏg�p
  gv_deliver             CONSTANT VARCHAR2(15)
                         := 'DELIVER';                  -- �������o�^�Ŏg�p
  gv_rma                 CONSTANT VARCHAR2(15)
                         := 'RMA';                      -- �������o�^�Ŏg�p
  gv_inventory           CONSTANT VARCHAR2(15)
                         := 'INVENTORY';                -- �������o�^�Ŏg�p
  gv_rcv                 CONSTANT VARCHAR2(15)
                         := 'RCV';                      -- �������o�^�Ŏg�p
--
  -- �N�C�b�N�R�[�h�擾�p(���b�N�A�b�v�^�C�v)
  gv_look_up_type_1      CONSTANT VARCHAR2(30)
                         := 'XXCMN_D12';                -- �����u���b�N
  -- �N�C�b�N�R�[�h�l
  gv_order_status_04     CONSTANT VARCHAR2(15)
                         := '04';                       -- �o�׎��ьv��ς�(�o��)
  gv_order_status_08     CONSTANT VARCHAR2(15)
                         := '08';                       -- �o�׎��ьv��ς�(�x��)
  gv_document_type_10    CONSTANT VARCHAR2(15)
                         := '10';                       -- �o�׈˗�
  gv_document_type_30    CONSTANT VARCHAR2(15)
                         := '30';                       -- �x���w��
  gv_record_type_20      CONSTANT VARCHAR2(15)
                         := '20';                       -- �o�Ɏ���
  gv_ship_class_1        CONSTANT VARCHAR2(15)
                         := '1';                        -- �o�׈˗�
  gv_ship_class_2        CONSTANT VARCHAR2(15)
                         := '2';                        -- �x���˗�
  gv_ship_class_3        CONSTANT VARCHAR2(15)
                         := '3';                        -- �q�֕ԕi
--
  --�v���t�@�C��
  gv_pfr_org_id          CONSTANT VARCHAR2(25) := 'ORG_ID';
  gv_pfr_return_reason   CONSTANT VARCHAR2(20) := 'XXWSH_RETURN_REASON';
--
  --��ID�o�^�敪
  gv_status_0            CONSTANT VARCHAR2(1)
                         := '0';                         -- �o�^���Ȃ�
  gv_status_1            CONSTANT VARCHAR2(1)
                         := '1';                         -- �o�^����
  --���[�U��`�ϐ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �󒍃A�h�I����񂩂�擾�����f�[�^���i�[���郌�R�[�h
  TYPE order_rec IS RECORD(
    transaction_type_id
        oe_transaction_types_all.transaction_type_id%TYPE,        -- �󒍃^�C�vID
    transaction_type_code
        oe_transaction_types_all.transaction_type_code%TYPE,      -- �󒍃^�C�v�R�[�h
    order_category_code
        oe_transaction_types_all.order_category_code%TYPE,        -- �󒍃J�e�S��
    shipping_shikyu_class
        oe_transaction_types_all.attribute1%TYPE,                 -- �o�׎x���敪
    order_header_id
        xxwsh_order_headers_all.order_header_id%TYPE,             -- �󒍃w�b�_�A�h�I��ID
    header_id
        xxwsh_order_headers_all.header_id%TYPE,                   -- �󒍃w�b�_ID
    organization_id
        xxwsh_order_headers_all.organization_id%TYPE,             -- �g�DID
    ordered_date
        xxwsh_order_headers_all.ordered_date%TYPE,                -- �󒍓�
    customer_id
        xxwsh_order_headers_all.customer_id%TYPE,                 -- �ڋqID
    customer_code
        xxwsh_order_headers_all.customer_code%TYPE,               -- �ڋq
    deliver_to_id
        xxwsh_order_headers_all.deliver_to_id%TYPE,               -- �o�א�ID
    deliver_to
        xxwsh_order_headers_all.deliver_to%TYPE,                  -- �o�א�
    shipping_instructions
        xxwsh_order_headers_all.shipping_instructions%TYPE,       -- �o�׎w��
    career_id
        xxwsh_order_headers_all.career_id%TYPE,                   -- �^���Ǝ�ID
    freight_carrier_code
        xxwsh_order_headers_all.freight_carrier_code%TYPE,        -- �^���Ǝ�
    shipping_method_code
        xxwsh_order_headers_all.shipping_method_code%TYPE,        -- �z���敪
    cust_po_number
        xxwsh_order_headers_all.cust_po_number%TYPE,              -- �ڋq����
    price_list_id
        xxwsh_order_headers_all.price_list_id%TYPE,               -- ���i�\
    request_no
        xxwsh_order_headers_all.request_no%TYPE,                  -- �˗�NO
    req_status
        xxwsh_order_headers_all.req_status%TYPE,                  -- �X�e�[�^�X
    delivery_no
        xxwsh_order_headers_all.delivery_no%TYPE,                 -- �z��NO
    prev_delivery_no
        xxwsh_order_headers_all.prev_delivery_no%TYPE,            -- �O��z��NO
    schedule_ship_date
        xxwsh_order_headers_all.schedule_ship_date%TYPE,          -- �o�ח\���
    schedule_arrival_date
        xxwsh_order_headers_all.schedule_arrival_date%TYPE,       -- ���ח\���
    mixed_no
        xxwsh_order_headers_all.mixed_no%TYPE,                    -- ���ڌ�NO
    collected_pallet_qty
        xxwsh_order_headers_all.collected_pallet_qty%TYPE,        -- �p���b�g�������
    confirm_request_class
        xxwsh_order_headers_all.confirm_request_class%TYPE,       -- �����S���m�F�˗��敪
    freight_charge_class
        xxwsh_order_headers_all.freight_charge_class%TYPE,        -- �^���敪
    shikyu_instruction_class
        xxwsh_order_headers_all.shikyu_instruction_class%TYPE,    -- �x���o�Ɏw���敪
    shikyu_inst_rcv_class
        xxwsh_order_headers_all.shikyu_inst_rcv_class%TYPE,       -- �x���w����̋敪
    amount_fix_class
        xxwsh_order_headers_all.amount_fix_class%TYPE,            -- �L�����z�m��敪
    takeback_class
        xxwsh_order_headers_all.takeback_class%TYPE,              -- ����敪
    deliver_from_id
        xxwsh_order_headers_all.deliver_from_id%TYPE,             -- �o�׌�ID
    deliver_from
        xxwsh_order_headers_all.deliver_from%TYPE,                -- �o�׌��ۊǏꏊ
    head_sales_branch
        xxwsh_order_headers_all.head_sales_branch%TYPE,           -- �Ǌ����_
    input_sales_branch
        xxwsh_order_headers_all.input_sales_branch%TYPE,          -- ���͋��_
    po_no
        xxwsh_order_headers_all.po_no%TYPE,                       -- ����NO
    prod_class
        xxwsh_order_headers_all.prod_class%TYPE,                  -- ���i�敪
    item_class
        xxwsh_order_headers_all.item_class%TYPE,                  -- �i�ڋ敪
    no_cont_freight_class
        xxwsh_order_headers_all.no_cont_freight_class%TYPE,       -- �_��O�^���敪
    arrival_time_from
        xxwsh_order_headers_all.arrival_time_from%TYPE,           -- ���׎���FROM
    arrival_time_to
        xxwsh_order_headers_all.arrival_time_to%TYPE,             -- ���׎���TO
    designated_item_id
        xxwsh_order_headers_all.designated_item_id%TYPE,          -- �����i��ID
    designated_item_code
        xxwsh_order_headers_all.designated_item_code%TYPE,        -- �����i��
    designated_production_date
        xxwsh_order_headers_all.designated_production_date%TYPE,  -- ������
    designated_branch_no
        xxwsh_order_headers_all.designated_branch_no%TYPE,        -- �����}��
    slip_number
        xxwsh_order_headers_all.slip_number%TYPE,                 -- �����NO
    sum_quantity
        xxwsh_order_headers_all.sum_quantity%TYPE,                -- ���v����
    small_quantity
        xxwsh_order_headers_all.small_quantity%TYPE,              -- ������
    label_quantity
        xxwsh_order_headers_all.label_quantity%TYPE,              -- ���x������
    loading_efficiency_weight
        xxwsh_order_headers_all.loading_efficiency_weight%TYPE,   -- �d�ʐύڌ���
    loading_efficiency_capacity
        xxwsh_order_headers_all.loading_efficiency_capacity%TYPE, -- �e�ϐύڌ���
    based_weight
        xxwsh_order_headers_all.based_weight%TYPE,                -- ��{�d��
    based_capacity
        xxwsh_order_headers_all.based_capacity%TYPE,              -- ��{�e��
    sum_weight
        xxwsh_order_headers_all.sum_weight%TYPE,                  -- �ύڏd�ʍ��v
    sum_capacity
        xxwsh_order_headers_all.sum_capacity%TYPE,                -- �ύڗe�ύ��v
    mixed_ratio
        xxwsh_order_headers_all.mixed_ratio%TYPE,                 -- ���ڗ�
    pallet_sum_quantity
        xxwsh_order_headers_all.pallet_sum_quantity%TYPE,         -- �p���b�g���v����
    real_pallet_quantity
        xxwsh_order_headers_all.real_pallet_quantity%TYPE,        -- �p���b�g���і���
    sum_pallet_weight
        xxwsh_order_headers_all.sum_pallet_weight%TYPE,           -- ���v�p���b�g�d��
    order_source_ref
        xxwsh_order_headers_all.order_source_ref%TYPE,            -- �󒍃\�[�X�Q��
    result_freight_carrier_id
        xxwsh_order_headers_all.result_freight_carrier_id%TYPE,   -- �^���Ǝ�_����ID
    result_freight_carrier_code
        xxwsh_order_headers_all.result_freight_carrier_code%TYPE, -- �^���Ǝ�_����
    result_shipping_method_code
        xxwsh_order_headers_all.result_shipping_method_code%TYPE, -- �z���敪_����
    result_deliver_to_id
        xxwsh_order_headers_all.result_deliver_to_id%TYPE,        -- �o�א�_����ID
    result_deliver_to
        xxwsh_order_headers_all.result_deliver_to%TYPE,           -- �o�א�_����
    shipped_date
        xxwsh_order_headers_all.shipped_date%TYPE,                -- �o�ד�
    arrival_date
        xxwsh_order_headers_all.arrival_date%TYPE,                -- ���ד�
    weight_capacity_class
        xxwsh_order_headers_all.weight_capacity_class%TYPE,       -- �d�ʗe�ϋ敪
    notif_status
        xxwsh_order_headers_all.notif_status%TYPE,                -- �ʒm�X�e�[�^�X
    prev_notif_status
        xxwsh_order_headers_all.prev_notif_status%TYPE,           -- �O��ʒm�X�e�[�^�X
    notif_date
        xxwsh_order_headers_all.notif_date%TYPE,                  -- �m��ʒm���{����
    new_modify_flg
        xxwsh_order_headers_all.new_modify_flg%TYPE,              -- �V�K�C���t���O
    process_status
        xxwsh_order_headers_all.process_status%TYPE,              -- �����o�߃X�e�[�^�X
    performance_management_dept
        xxwsh_order_headers_all.performance_management_dept%TYPE, -- ���ъǗ�����
    instruction_dept
        xxwsh_order_headers_all.instruction_dept%TYPE,            -- �w������
    transfer_location_id
        xxwsh_order_headers_all.transfer_location_id%TYPE,        -- �U�֐�ID
    transfer_location_code
        xxwsh_order_headers_all.transfer_location_code%TYPE,      -- �U�֐�
    mixed_sign
        xxwsh_order_headers_all.mixed_sign%TYPE,                  -- ���ڋL��
    screen_update_date
        xxwsh_order_headers_all.screen_update_date%TYPE,          -- ��ʍX�V����
    screen_update_by
        xxwsh_order_headers_all.screen_update_by%TYPE,            -- ��ʍX�V��
    tightening_date
        xxwsh_order_headers_all.tightening_date%TYPE,             -- �o�׈˗����ߓ���
    vendor_id
        xxwsh_order_headers_all.vendor_id%TYPE,                   -- �����ID
    vendor_code
        xxwsh_order_headers_all.vendor_code%TYPE,                 -- �����
    vendor_site_id
        xxwsh_order_headers_all.vendor_site_id%TYPE,              -- �����T�C�gID
    vendor_site_code
        xxwsh_order_headers_all.vendor_site_code%TYPE,            -- �����T�C�g
    registered_sequence
        xxwsh_order_headers_all.registered_sequence%TYPE,         -- �o�^����
    tightening_program_id
        xxwsh_order_headers_all.tightening_program_id%TYPE,       -- ���߃R���J�����gID
    corrected_tighten_class
        xxwsh_order_headers_all.corrected_tighten_class%TYPE,     -- ���ߌ�C���敪
    order_line_id
        xxwsh_order_lines_all.order_line_id%TYPE,                 -- �󒍖��׃A�h�I��ID
    order_line_number
        xxwsh_order_lines_all.order_line_number%TYPE,             -- ���הԍ�
    line_id
        xxwsh_order_lines_all.line_id%TYPE,                       -- �󒍖���ID
    line_request_no
        xxwsh_order_lines_all.request_no%TYPE,                    -- �˗�No
    shipping_inventory_item_id
        xxwsh_order_lines_all.shipping_inventory_item_id%TYPE,    -- �o�וi��ID
    shipping_item_code
        xxwsh_order_lines_all.shipping_item_code%TYPE,            -- �o�וi��
    quantity
        xxwsh_order_lines_all.quantity%TYPE,                      -- ����
    uom_code
        xxwsh_order_lines_all.uom_code%TYPE,                      -- �P��
    unit_price
        xxwsh_order_lines_all.unit_price%TYPE,                    -- �P��
    shipped_quantity
        xxwsh_order_lines_all.shipped_quantity%TYPE,              -- �o�׎��ѐ���
    line_designated_prod_date
        xxwsh_order_lines_all.designated_production_date%TYPE,    -- �w�萻����
    based_request_quantity
        xxwsh_order_lines_all.based_request_quantity%TYPE,        -- ���_�˗�����
    request_item_id
        xxwsh_order_lines_all.request_item_id%TYPE,               -- �˗��i��ID
    request_item_code
        xxwsh_order_lines_all.request_item_code%TYPE,             -- �˗��i��
    ship_to_quantity
        xxwsh_order_lines_all.ship_to_quantity%TYPE,              -- ���Ɏ��ѐ���
    futai_code
        xxwsh_order_lines_all.futai_code%TYPE,                    -- �t�уR�[�h
    designated_date
        xxwsh_order_lines_all.designated_date%TYPE,               -- �w����t�i���[�t�j
    move_number
        xxwsh_order_lines_all.move_number%TYPE,                   -- �ړ�NO
    po_number
        xxwsh_order_lines_all.po_number%TYPE,                     -- ����NO
    line_cust_po_number
        xxwsh_order_lines_all.cust_po_number%TYPE,                -- �ڋq����
    pallet_quantity
        xxwsh_order_lines_all.pallet_quantity%TYPE,               -- �p���b�g��
    layer_quantity
        xxwsh_order_lines_all.layer_quantity%TYPE,                -- �i��
    case_quantity
        xxwsh_order_lines_all.case_quantity%TYPE,                 -- �P�[�X��
    weight
        xxwsh_order_lines_all.weight%TYPE,                        -- �d��
    capacity
        xxwsh_order_lines_all.capacity%TYPE,                      -- �e��
    pallet_qty
        xxwsh_order_lines_all.pallet_qty%TYPE,                    -- �p���b�g����
    pallet_weight
        xxwsh_order_lines_all.pallet_weight%TYPE,                 -- �p���b�g�d��
    reserved_quantity
        xxwsh_order_lines_all.reserved_quantity%TYPE,             -- ������
    automanual_reserve_class
        xxwsh_order_lines_all.automanual_reserve_class%TYPE,      -- �����蓮�����敪
    warning_class
        xxwsh_order_lines_all.warning_class%TYPE,                 -- �x���敪
    warning_date
        xxwsh_order_lines_all.warning_date%TYPE,                  -- �x�����t
    line_description
        xxwsh_order_lines_all.line_description%TYPE,              -- �E�v
    rm_if_flg
        xxwsh_order_lines_all.rm_if_flg%TYPE,                     -- �q�֕ԕi�C���^�t�F�[�X�σt���O
    shipping_request_if_flg
        xxwsh_order_lines_all.shipping_request_if_flg%TYPE,       -- �o�׈˗��C���^�t�F�[�X�σt���O
    shipping_result_if_flg
        xxwsh_order_lines_all.shipping_result_if_flg%TYPE,        -- �o�׎��уC���^�t�F�[�X�σt���O
    distribution_block
        xxcmn_item_locations_v.distribution_block%TYPE,           -- �u���b�N
    mtl_organization_id
        xxcmn_item_locations_v.mtl_organization_id%TYPE,          -- �݌ɑg�DID
    location_id
        xxcmn_item_locations_v.location_id%TYPE,                  -- ���Ə�ID
    subinventory_code
        xxcmn_item_locations_v.subinventory_code%TYPE,            -- �ۊǏꏊ�R�[�h
    inventory_location_id
        xxcmn_item_locations_v.inventory_location_id%TYPE,        -- �q��ID
    cust_account_id
        xxcmn_cust_accounts_v.cust_account_id%TYPE,               -- �ڋqID
    lot_ctl
        xxcmn_item_mst_v.lot_ctl%TYPE                             -- ���b�g�Ǘ�
  );
  -- �󒍃A�h�I�������i�[����z��
  TYPE order_tbl IS TABLE OF order_rec INDEX BY PLS_INTEGER;
  -- API�����Ŏg�p����󒍖��׏����i�[���郌�R�[�h
  TYPE order_line_rec IS RECORD(
    order_line_id 
        xxwsh_order_lines_all.order_line_id%TYPE,                 -- �󒍖��׃A�h�I��ID
    line_id
        xxwsh_order_lines_all.line_id%TYPE,                       -- �󒍖���ID
    shipped_quantity
        xxwsh_order_lines_all.shipped_quantity%TYPE,              -- �o�׎��ѐ���
    uom_code
        xxwsh_order_lines_all.uom_code%TYPE,                      -- �P��
    shipping_inventory_item_id
        xxwsh_order_lines_all.shipping_inventory_item_id%TYPE,    -- �o�וi��ID
    header_id
        xxwsh_order_headers_all.header_id%TYPE,                   -- �󒍃w�b�_ID
    deliver_from
        xxwsh_order_headers_all.deliver_from%TYPE,                -- �o�׌��ۊǏꏊ
    shipped_date
        xxwsh_order_headers_all.shipped_date%TYPE,                -- �o�ד�
    location_id
        xxcmn_item_locations_v.location_id%TYPE,                  -- ���Ə�ID
    subinventory_code
        xxcmn_item_locations_v.subinventory_code%TYPE,            -- �ۊǏꏊ�R�[�h
    mtl_organization_id
        xxcmn_item_locations_v.mtl_organization_id%TYPE,          -- �݌ɑg�DID
    inventory_location_id
        xxcmn_item_locations_v.inventory_location_id%TYPE,        -- �q��ID
    cust_account_id
        xxcmn_cust_accounts_v.cust_account_id%TYPE,               -- �ڋqID
    site_use_id
        hz_cust_site_uses_all.site_use_id%TYPE,                   -- �g�p�ړIID
    lot_ctl
        xxcmn_item_mst_v.lot_ctl%TYPE                             -- ���b�g�Ǘ�
  );
  TYPE revised_line_rec IS RECORD(
    order_line_id 
        xxwsh_order_lines_all.order_line_id%TYPE,                 -- �󒍖��׃A�h�I��ID
    new_order_line_id
        xxwsh_order_lines_all.order_line_id%TYPE                  -- �V�󒍖��׃A�h�I��ID
  );
  -- API�����Ŏg�p����󒍖��׏����i�[����z��
  TYPE mov_line_id_type
      IS TABLE OF NUMBER
      INDEX BY PLS_INTEGER;    -- �ړ����׊i�[�p�z��
  TYPE order_line_type
      IS TABLE OF order_line_rec
      INDEX BY PLS_INTEGER;    -- �󒍖��׊i�[�p�z��
  TYPE revised_line_type
      IS TABLE OF revised_line_rec
      INDEX BY PLS_INTEGER;    -- �����p�󒍖��׊i�[�p�z��
  -- �݌Ɋ���API�̃p�����[�^���i�[����z��
  TYPE ic_tran_rec_type           
      IS TABLE OF GMI_OM_ALLOC_API_PUB.IC_TRAN_REC_TYPE
      INDEX BY PLS_INTEGER;    -- �݌Ɋ���API�p�z��
  -- �������I�[�v���C���^�t�F�[�X�w�b�_�o�^�p
  TYPE hi_header_inf_id_type      
      IS TABLE OF rcv_headers_interface.header_interface_id%TYPE
      INDEX BY BINARY_INTEGER; -- �w�b�_�C���^�t�F�[�XID
  TYPE hi_ex_receipt_date_type    
      IS TABLE OF rcv_headers_interface.expected_receipt_date%TYPE
      INDEX BY BINARY_INTEGER; -- �����
  TYPE hi_ship_to_org_id_type    
      IS TABLE OF rcv_headers_interface.ship_to_organization_id%TYPE
      INDEX BY BINARY_INTEGER; -- �݌ɑg�DID
  TYPE hi_customer_id_type
      IS TABLE OF rcv_headers_interface.customer_id%TYPE
      INDEX BY BINARY_INTEGER; -- �ڋqID
  TYPE hi_customer_site_id_type
      IS TABLE OF rcv_headers_interface.customer_site_id%TYPE
      INDEX BY BINARY_INTEGER; -- �g�p�ړIID
  -- �������I�[�v���C���^�t�F�[�X���דo�^�p
  TYPE ti_header_inf_id_type      
      IS TABLE OF rcv_transactions_interface.header_interface_id%TYPE
      INDEX BY BINARY_INTEGER; -- �w�b�_�C���^�t�F�[�XID
  TYPE ti_ex_receipt_date_type    
      IS TABLE OF rcv_transactions_interface.expected_receipt_date%TYPE
      INDEX BY BINARY_INTEGER; -- �����
  TYPE ti_transaction_date_type   
      IS TABLE OF rcv_transactions_interface.transaction_date%TYPE
      INDEX BY BINARY_INTEGER; -- �����
  TYPE ti_int_tran_id_type
      IS TABLE OF rcv_transactions_interface.interface_transaction_id%TYPE
      INDEX BY BINARY_INTEGER; -- �������C���^�t�F�[�XID
  TYPE ti_quantity_type           
      IS TABLE OF rcv_transactions_interface.quantity%TYPE
      INDEX BY BINARY_INTEGER; -- ����
  TYPE ti_unit_of_measure_type    
      IS TABLE OF rcv_transactions_interface.unit_of_measure%TYPE
      INDEX BY BINARY_INTEGER; -- �P��
  TYPE ti_item_id_type            
      IS TABLE OF rcv_transactions_interface.item_id%TYPE
      INDEX BY BINARY_INTEGER; -- �i��ID
  TYPE ti_subinventory_type       
      IS TABLE OF rcv_transactions_interface.subinventory%TYPE
      INDEX BY BINARY_INTEGER; -- �ۊǏꏊ�R�[�h
  TYPE ti_locator_id_type
      IS TABLE OF rcv_transactions_interface.locator_id%TYPE
      INDEX BY BINARY_INTEGER; -- �q��ID
  TYPE ti_oe_order_header_id_type 
      IS TABLE OF rcv_transactions_interface.oe_order_header_id%TYPE
      INDEX BY BINARY_INTEGER; -- �󒍃w�b�_ID
  TYPE ti_oe_order_line_id_type   
      IS TABLE OF rcv_transactions_interface.oe_order_line_id%TYPE
      INDEX BY BINARY_INTEGER; -- �󒍖���ID
  TYPE ti_ship_to_location_id_type   
      IS TABLE OF rcv_transactions_interface.ship_to_location_id%TYPE
      INDEX BY BINARY_INTEGER; -- ���Ə�ID
  -- �������I�[�v���C���^�t�F�[�X���b�g�o�^�p
  TYPE tl_tran_inter_id_type      
      IS TABLE OF mtl_transaction_lots_interface.transaction_interface_id%TYPE
      INDEX BY BINARY_INTEGER; -- ���b�g�C���^�t�F�[�XID
  TYPE tl_lot_number_type         
      IS TABLE OF mtl_transaction_lots_interface.lot_number%TYPE
      INDEX BY BINARY_INTEGER; -- ���b�gNo
  TYPE tl_tran_quantity_type      
      IS TABLE OF mtl_transaction_lots_interface.transaction_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- ����
  TYPE tl_primary_quantity_type   
      IS TABLE OF mtl_transaction_lots_interface.primary_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- ����
  TYPE tl_product_tran_id_type    
      IS TABLE OF mtl_transaction_lots_interface.product_transaction_id%TYPE
      INDEX BY BINARY_INTEGER; -- �������C���^�t�F�[�XID
  -- �ړ����b�g�ڍׂɓo�^��������i�[���郌�R�[�h(�o���N�����p)
  TYPE ld_mov_lot_dtl_id_type     
      IS TABLE OF xxinv_mov_lot_details.mov_lot_dtl_id%TYPE
      INDEX BY BINARY_INTEGER; -- ���b�g�ڍ�ID
  TYPE ld_mov_line_id_type        
      IS TABLE OF xxinv_mov_lot_details.mov_line_id%TYPE
      INDEX BY BINARY_INTEGER; -- ����ID
  TYPE ld_document_type_code_type 
      IS TABLE OF xxinv_mov_lot_details.document_type_code%TYPE
      INDEX BY BINARY_INTEGER; -- �����^�C�v
  TYPE ld_record_type_code_type   
      IS TABLE OF xxinv_mov_lot_details.record_type_code%TYPE
      INDEX BY BINARY_INTEGER; -- ���R�[�h�^�C�v
  TYPE ld_item_id_type            
      IS TABLE OF xxinv_mov_lot_details.item_id%TYPE
      INDEX BY BINARY_INTEGER; -- OPM�i��ID
  TYPE ld_item_code_type          
      IS TABLE OF xxinv_mov_lot_details.item_code%TYPE
      INDEX BY BINARY_INTEGER; -- �i��
  TYPE ld_lot_id_type             
      IS TABLE OF xxinv_mov_lot_details.lot_id%TYPE
      INDEX BY BINARY_INTEGER; -- ���b�gID
  TYPE ld_lot_no_type             
      IS TABLE OF xxinv_mov_lot_details.lot_no%TYPE
      INDEX BY BINARY_INTEGER; -- ���b�gNo
  TYPE ld_actual_date_type        
      IS TABLE OF xxinv_mov_lot_details.actual_date%TYPE
      INDEX BY BINARY_INTEGER; -- ���ѓ�
  TYPE ld_actual_quantity_type    
      IS TABLE OF xxinv_mov_lot_details.actual_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- ���ѐ���
  TYPE ld_auto_reserve_class_type 
      IS TABLE OF xxinv_mov_lot_details.automanual_reserve_class%TYPE
      INDEX BY BINARY_INTEGER; -- �����蓮�����敪
  -- �󒍖��׃A�h�I���̎󒍖���ID�X�V�p���R�[�h
  TYPE ol_order_line_id_type      
      IS TABLE OF xxwsh_order_lines_all.order_line_id%TYPE
      INDEX BY BINARY_INTEGER; -- �󒍖��׃A�h�I��ID
  TYPE ol_line_id_type            
      IS TABLE OF xxwsh_order_lines_all.line_id%TYPE
      INDEX BY BINARY_INTEGER; -- �󒍖���ID
  -- �󒍖��׃A�h�I���̐ԓo�^�p���R�[�h(�o���N�����p)
  TYPE ol_order_header_id_type    
      IS TABLE OF xxwsh_order_lines_all.order_header_id%TYPE
      INDEX BY BINARY_INTEGER; -- �󒍃w�b�_�A�h�I��ID
  TYPE ol_order_line_number_type  
      IS TABLE OF xxwsh_order_lines_all.order_line_number%TYPE
      INDEX BY BINARY_INTEGER; -- ���הԍ�
  TYPE ol_header_id_type          
      IS TABLE OF xxwsh_order_lines_all.header_id%TYPE
      INDEX BY BINARY_INTEGER; -- �󒍃w�b�_ID
  TYPE ol_request_no_type         
      IS TABLE OF xxwsh_order_lines_all.request_no%TYPE
      INDEX BY BINARY_INTEGER; -- �˗�No
  TYPE ol_ship_inv_item_id_type   
      IS TABLE OF xxwsh_order_lines_all.shipping_inventory_item_id%TYPE
      INDEX BY BINARY_INTEGER; -- �o�וi��ID
  TYPE ol_ship_item_code_type     
      IS TABLE OF xxwsh_order_lines_all.shipping_item_code%TYPE
      INDEX BY BINARY_INTEGER; -- �o�וi��
  TYPE ol_quantity_type           
      IS TABLE OF xxwsh_order_lines_all.quantity%TYPE
      INDEX BY BINARY_INTEGER; -- ����
  TYPE ol_uom_code_type           
      IS TABLE OF xxwsh_order_lines_all.uom_code%TYPE
      INDEX BY BINARY_INTEGER; -- �P��
  TYPE ol_unit_price_type         
      IS TABLE OF xxwsh_order_lines_all.unit_price%TYPE
      INDEX BY BINARY_INTEGER; -- �P��
  TYPE ol_shipped_quantity_type   
      IS TABLE OF xxwsh_order_lines_all.shipped_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- �o�׎��ѐ���
  TYPE ol_desi_prod_date_type     
      IS TABLE OF xxwsh_order_lines_all.designated_production_date%TYPE
      INDEX BY BINARY_INTEGER; -- �w�萻����
  TYPE ol_base_req_quantity_type  
      IS TABLE OF xxwsh_order_lines_all.based_request_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- ���_�˗�����
  TYPE ol_request_item_id_type    
      IS TABLE OF xxwsh_order_lines_all.request_item_id%TYPE
      INDEX BY BINARY_INTEGER; -- �˗��i��ID
  TYPE ol_request_item_code_type  
      IS TABLE OF xxwsh_order_lines_all.request_item_code%TYPE
      INDEX BY BINARY_INTEGER; -- �˗��i��
  TYPE ol_ship_to_quantity_type   
      IS TABLE OF xxwsh_order_lines_all.ship_to_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- ���Ɏ��ѐ���
  TYPE ol_futai_code_type         
      IS TABLE OF xxwsh_order_lines_all.futai_code%TYPE
      INDEX BY BINARY_INTEGER; -- �t�уR�[�h
  TYPE ol_designated_date_type    
      IS TABLE OF xxwsh_order_lines_all.designated_date%TYPE
      INDEX BY BINARY_INTEGER; -- �w����t�i���[�t�j
  TYPE ol_move_number_type        
      IS TABLE OF xxwsh_order_lines_all.move_number%TYPE
      INDEX BY BINARY_INTEGER; -- �ړ�No
  TYPE ol_po_number_type          
      IS TABLE OF xxwsh_order_lines_all.po_number%TYPE
      INDEX BY BINARY_INTEGER; -- ����No
  TYPE ol_cust_po_number_type     
      IS TABLE OF xxwsh_order_lines_all.cust_po_number%TYPE
      INDEX BY BINARY_INTEGER; -- �ڋq����
  TYPE ol_pallet_quantity_type    
      IS TABLE OF xxwsh_order_lines_all.pallet_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- �p���b�g��
  TYPE ol_layer_quantity_type     
      IS TABLE OF xxwsh_order_lines_all.layer_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- �i��
  TYPE ol_case_quantity_type      
      IS TABLE OF xxwsh_order_lines_all.case_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- �P�[�X��
  TYPE ol_weight_type             
      IS TABLE OF xxwsh_order_lines_all.weight%TYPE
      INDEX BY BINARY_INTEGER; -- �d��
  TYPE ol_capacity_type           
      IS TABLE OF xxwsh_order_lines_all.capacity%TYPE
      INDEX BY BINARY_INTEGER; -- �e��
  TYPE ol_pallet_qty_type         
      IS TABLE OF xxwsh_order_lines_all.pallet_qty%TYPE
      INDEX BY BINARY_INTEGER; -- �p���b�g����
  TYPE ol_pallet_weight_type      
      IS TABLE OF xxwsh_order_lines_all.pallet_weight%TYPE
      INDEX BY BINARY_INTEGER; -- �p���b�g�d��
  TYPE ol_reserved_quantity_type  
      IS TABLE OF xxwsh_order_lines_all.reserved_quantity%TYPE
      INDEX BY BINARY_INTEGER; -- ������
  TYPE ol_auto_rese_class_type    
      IS TABLE OF xxwsh_order_lines_all.automanual_reserve_class%TYPE
      INDEX BY BINARY_INTEGER; -- �����蓮�����敪
  TYPE ol_warning_class_type      
      IS TABLE OF xxwsh_order_lines_all.warning_class%TYPE
      INDEX BY BINARY_INTEGER; -- �x���敪
  TYPE ol_warning_date_type       
      IS TABLE OF xxwsh_order_lines_all.warning_date%TYPE
      INDEX BY BINARY_INTEGER; -- �x�����t
  TYPE ol_line_description_type   
      IS TABLE OF xxwsh_order_lines_all.line_description%TYPE
      INDEX BY BINARY_INTEGER; -- �E�v
  TYPE ol_rm_if_flg_type          
      IS TABLE OF xxwsh_order_lines_all.rm_if_flg%TYPE
      INDEX BY BINARY_INTEGER; -- �q�֕ԕi�C���^�t�F�[�X�σt���O
  TYPE ol_ship_requ_if_flg_type   
      IS TABLE OF xxwsh_order_lines_all.shipping_request_if_flg%TYPE
      INDEX BY BINARY_INTEGER; -- �o�׈˗��C���^�t�F�[�X�σt���O
  TYPE ol_ship_resu_if_flg_type   
      IS TABLE OF xxwsh_order_lines_all.shipping_result_if_flg%TYPE
      INDEX BY BINARY_INTEGER; -- �o�׎��уC���^�t�F�[�X�σt���O
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_new_order_cnt
      NUMBER;                                           -- �V�K�󒍍쐬����
  gn_upd_order_cnt
      NUMBER;                                           -- �����󒍍쐬����
  gn_cancell_cnt
      NUMBER;                                           -- �����񌏐�
  gn_input_cnt
      NUMBER;                                           -- ���͌���
  gn_error_cnt
      NUMBER;                                           -- �G���[����
  gn_org_id
      NUMBER;                                           -- �c�ƒP��ID
  gt_return_reason_code
      oe_order_lines_all.return_reason_code%TYPE;       -- �ԕi���R
  gt_block
      fnd_lookup_values.lookup_code%TYPE;               -- �u���b�N
  gt_deliver_from
      xxwsh_order_headers_all.deliver_from%TYPE;        -- �o�׌��ۊǏꏊ
  gt_request_no
      xxwsh_order_headers_all.request_no%TYPE;          -- �˗�No
  -- �������I�[�v���C���^�t�F�[�X�w�b�_�o�^�p
  gt_header_interface_id
      hi_header_inf_id_type;                            -- �w�b�_�C���^�t�F�[�XID
  gt_expectied_receipt_date
      hi_ex_receipt_date_type;                          -- �����
  gt_ship_to_organization_id
      hi_ship_to_org_id_type;                           -- �݌ɑg�DID
  gt_customer_id
      hi_customer_id_type;                              -- �ڋqID
  gt_customer_site_id
      hi_customer_site_id_type;                         -- �g�p�ړIID
  -- �������I�[�v���C���^�t�F�[�X���דo�^�p
  gt_line_header_interface_id
      ti_header_inf_id_type;                            -- �w�b�_�C���^�t�F�[�XID
  gt_line_exp_receipt_date
      ti_ex_receipt_date_type;                          -- �����
  gt_transaction_date
      ti_transaction_date_type;                         -- �����
  gt_interface_transaction_id
      ti_int_tran_id_type;                              -- �������C���^�t�F�[�XID
  gt_quantity
      ti_quantity_type;                                 -- ����
  gt_unit_of_measure
      ti_unit_of_measure_type;                          -- �P��
  gt_ti_item_id
      ti_item_id_type;                                  -- �i��ID
  gt_subinventory
      ti_subinventory_type;                             -- �ۊǏꏊ�R�[�h
  gt_oe_order_header_id
      ti_oe_order_header_id_type;                       -- �󒍃w�b�_ID
  gt_oe_order_line_id
      ti_oe_order_line_id_type;                         -- �󒍖���ID
  gt_ship_to_location_id
      ti_ship_to_location_id_type;                      -- ���Ə�ID
  gt_locator_id
      ti_locator_id_type;                               -- �q��ID
  -- �������I�[�v���C���^�t�F�[�X���b�g�o�^�p
  gt_transaction_interface_id
      tl_tran_inter_id_type;                            -- ���b�g�C���^�t�F�[�XID
  gt_lot_number
      tl_lot_number_type;                               -- ���b�gNo
  gt_transaction_quantity
      tl_tran_quantity_type;                            -- ����
  gt_primary_quantity
      tl_primary_quantity_type;                         -- ����
  gt_lot_prod_transaction_id
      tl_product_tran_id_type;                          -- �������C���^�t�F�[�XID
  -- �ړ����b�g�ڍ�(�o���NINSERT�p�ϐ�)
  gt_mov_lot_dtl_id
      ld_mov_lot_dtl_id_type;                           -- ���b�g�ڍ�ID
  gt_mov_line_id
      ld_mov_line_id_type;                              -- ����ID
  gt_document_type_code
      ld_document_type_code_type;                       -- �����^�C�v
  gt_record_type_code
      ld_record_type_code_type;                         -- ���R�[�h�^�C�v
  gt_item_id
      ld_item_id_type;                                  -- OPM�i��ID
  gt_item_code
      ld_item_code_type;                                -- �i��
  gt_lot_id
      ld_lot_id_type;                                   -- ���b�gID
  gt_lot_no
      ld_lot_no_type;                                   -- ���b�gNo
  gt_actual_date
      ld_actual_date_type;                              -- ���ѓ�
  gt_actual_quantity
      ld_actual_quantity_type;                          -- ���ѐ���
  gt_automanual_reserve_class
      ld_auto_reserve_class_type;                       -- �����蓮�����敪
  -- �󒍖��׃A�h�I���󒍖���ID�X�V�p(�o���NUPDATE�p�ϐ�)
  gt_order_line_id
      ol_order_line_id_type;                            -- �󒍖��׃A�h�I��ID
  gt_line_id
      ol_line_id_type;                                  -- �󒍖���ID
  -- �����p�ϐ�
  gn_shori_count
      NUMBER;                                           -- A3�擾�f�[�^���݈ʒu���f�p
  gn_lot_count
      NUMBER;                                           -- �ړ����b�g�o�^�p����
  gn_header_if_count
      NUMBER;                                           -- �������I�[�v���C���^�t�F�[�X�w�b�_����
  gn_tran_if_count
      NUMBER;                                           -- �������I�[�v���C���^�t�F�[�X���׌���
  gn_tran_lot_if_count
      NUMBER;                                           -- �������I�[�v���C���^�t�F�[�X���b�g����
  gv_shori_kbn
      VARCHAR2(1);                                      -- �����敪(1:�V�K�o�^��,2:�V�K�o�^�ԕi,
                                                        --          3:������,4:�����ԕi)
  gt_gen_request_no
      xxwsh_order_headers_all.request_no%TYPE;          -- A3�Ŏ擾���ΏۂƂȂ��Ă���˗�No
  gt_header_id
      xxwsh_order_headers_all.header_id%TYPE;           -- �󒍃w�b�_ID(�X�V�p)
  gt_gen_order_header_id
      xxwsh_order_headers_all.order_header_id%TYPE;     -- �󒍃w�b�_�A�h�I��ID(������)
  -- �W��API�l�ێ��p
  gn_req_id
      NUMBER;                                           -- �����������R���J�����gID
  gn_group_id
      NUMBER;                                           -- ����C���^�[�t�F�[�X�O���[�vID
  gv_error_flag
      VARCHAR2(1);                                      -- �G���[���f�t���O
  gv_errbuf
      VARCHAR2(5000);                                   -- �G���[���b�Z�[�W
  gv_errmsg
      VARCHAR2(5000);                                   -- ���[�U�[�E�G���[�E���b�Z�[�W
  -- WHO�J�����p�ϐ�
  gn_user_id
      NUMBER;                                           -- ���O�C�����Ă��郆�[�U�[
  gn_login_id
      NUMBER;                                           -- �ŏI�X�V���O�C��
  gn_conc_request_id
      NUMBER;                                           -- �v��ID
  gn_prog_appl_id
      NUMBER;                                           -- �v���O�����E�A�v���P�[�V����ID
  gn_conc_program_id
      NUMBER;                                           -- �R���J�����g�E�v���O����ID
--
  /***********************************************************************************
   * Procedure Name   : input_param_check
   * Description      : A1���̓p�����[�^�`�F�b�N
   ***********************************************************************************/
  PROCEDURE input_param_check(
    iv_block        IN VARCHAR2,             -- �u���b�N
    iv_deliver_from IN VARCHAR2,             -- �o�׌�
    iv_request_no   IN VARCHAR2,             -- �˗�No
    ov_errbuf       OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'input_param_check'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_count NUMBER;           -- ���݃`�F�b�N�p����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- *********************************************
    -- ***        �u���b�N�̑��݃`�F�b�N         ***
    -- *********************************************
    IF (iv_block IS NOT NULL ) THEN
      SELECT COUNT(xlvv.lookup_code)
      INTO   ln_count
      FROM   xxcmn_lookup_values_v xlvv                      -- �N�C�b�N�R�[�hVIEW
      WHERE  xlvv.lookup_type = gv_look_up_type_1
      AND    xlvv.lookup_code = iv_block
      AND    ROWNUM = 1;
      IF ( ln_count = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,  gv_msg_42a_017,
                                              gv_tkn_in_block, iv_block);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      gt_block := iv_block;
    END IF;
    -- *********************************************
    -- ***        �o�׌����݃`�F�b�N             ***
    -- *********************************************
    IF (iv_deliver_from IS NOT NULL ) THEN
      SELECT COUNT(xilv.mtl_organization_id)
      INTO   ln_count
      FROM   xxcmn_item_locations_v xilv
      WHERE  xilv.segment1 = iv_deliver_from
      AND    ROWNUM = 1;
      IF ( ln_count = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,  gv_msg_42a_021,
                                              gv_tkn_in_shipf, iv_deliver_from);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      gt_deliver_from := iv_deliver_from;
    END IF;
    gt_request_no := iv_request_no;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END input_param_check;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : A2�v���t�@�C���l�擾
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_org_id             NUMBER;                                     -- �c�ƒP��ID
    lt_return_reason_code oe_order_lines_all.return_reason_code%TYPE; -- �ԕi���R
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***       �c�ƒP��ID�擾            ***
    -- ***************************************
    ln_org_id := TO_NUMBER(FND_PROFILE.VALUE(gv_pfr_org_id));
--
    IF (ln_org_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,   gv_msg_42a_018,
                                            gv_tkn_prof_name, gv_pfr_org_id);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gn_org_id := ln_org_id; -- �c�ƒP��ID���Z�b�g
--
    -- ***************************************
    -- ***       �ԕi���R�擾            ***
    -- ***************************************
    lt_return_reason_code := FND_PROFILE.VALUE(gv_pfr_return_reason);
--
    IF (lt_return_reason_code IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,   gv_msg_42a_018,
                                            gv_tkn_prof_name, gv_pfr_return_reason);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    gt_return_reason_code := lt_return_reason_code; -- �ԕi���R���Z�b�g
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_profile;
  /***********************************************************************************
   * Procedure Name   : get_order_info
   * Description      : A3�󒍃A�h�I�����擾
   ***********************************************************************************/
  PROCEDURE get_order_info(
    or_order_info_tbl  OUT NOCOPY order_tbl,    -- �󒍃A�h�I�����i�[�p�z��
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_info'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
-- 2008/09/01 Add ��
    lv_select1          VARCHAR2(32000) DEFAULT NULL;
    lv_select2          VARCHAR2(32000) DEFAULT NULL;
    lv_select_where     VARCHAR2(32000) DEFAULT NULL;
    lv_select_lock      VARCHAR2(32000) DEFAULT NULL;
    lv_select_order     VARCHAR2(32000) DEFAULT NULL;
-- 2008/09/01 Add ��
--
    -- *** ���[�J���E�J�[�\�� ***
-- 2008/09/01 Mod ��
    TYPE   ref_cursor IS REF CURSOR ;
    cur_order_data ref_cursor ;
/*
--
    CURSOR cur_order_data IS
      SELECT xottv1.transaction_type_id,                                -- �󒍃^�C�vID
             xottv1.transaction_type_code,                              -- �󒍃^�C�v�R�[�h
             xottv1.order_category_code,                                -- �󒍃J�e�S��
             xottv1.shipping_shikyu_class,                              -- �o�׎x���敪
             xoha.order_header_id,                                      -- �󒍃w�b�_�A�h�I��ID
             xoha.header_id,                                            -- �󒍃w�b�_ID
             xoha.organization_id,                                      -- �g�DID
             xoha.ordered_date,                                         -- �󒍓�
             xoha.customer_id,                                          -- �ڋqID
             xoha.customer_code,                                        -- �ڋq
             xoha.deliver_to_id,                                        -- �o�א�ID
             xoha.deliver_to,                                           -- �o�א�
             xoha.shipping_instructions,                                -- �o�׎w��
             xoha.career_id,                                            -- �^���Ǝ�ID
             xoha.freight_carrier_code,                                 -- �^���Ǝ�
             xoha.shipping_method_code,                                 -- �z���敪
             xoha.cust_po_number,                                       -- �ڋq����
             xoha.price_list_id,                                        -- ���i�\
             xoha.request_no,                                           -- �˗�NO
             xoha.req_status,                                           -- �X�e�[�^�X
             xoha.delivery_no,                                          -- �z��NO
             xoha.prev_delivery_no,                                     -- �O��z��NO
             xoha.schedule_ship_date,                                   -- �o�ח\���
             xoha.schedule_arrival_date,                                -- ���ח\���
             xoha.mixed_no,                                             -- ���ڌ�NO
             xoha.collected_pallet_qty,                                 -- �p���b�g�������
             xoha.confirm_request_class,                                -- �����S���m�F�˗��敪
             xoha.freight_charge_class,                                 -- �^���敪
             xoha.shikyu_instruction_class,                             -- �x���o�Ɏw���敪
             xoha.shikyu_inst_rcv_class,                                -- �x���w����̋敪
             xoha.amount_fix_class,                                     -- �L�����z�m��敪
             xoha.takeback_class,                                       -- ����敪
             xoha.deliver_from_id,                                      -- �o�׌�ID
             xoha.deliver_from,                                         -- �o�׌��ۊǏꏊ
             xoha.head_sales_branch,                                    -- �Ǌ����_
             xoha.input_sales_branch,                                   -- ���͋��_
             xoha.po_no,                                                -- ����NO
             xoha.prod_class,                                           -- ���i�敪
             xoha.item_class,                                           -- �i�ڋ敪
             xoha.no_cont_freight_class,                                -- �_��O�^���敪
             xoha.arrival_time_from,                                    -- ���׎���FROM
             xoha.arrival_time_to,                                      -- ���׎���TO
             xoha.designated_item_id,                                   -- �����i��ID
             xoha.designated_item_code,                                 -- �����i��
             xoha.designated_production_date,                           -- ������
             xoha.designated_branch_no,                                 -- �����}��
             xoha.slip_number,                                          -- �����NO
             xoha.sum_quantity,                                         -- ���v����
             xoha.small_quantity,                                       -- ������
             xoha.label_quantity,                                       -- ���x������
             xoha.loading_efficiency_weight,                            -- �d�ʐύڌ���
             xoha.loading_efficiency_capacity,                          -- �e�ϐύڌ���
             xoha.based_weight,                                         -- ��{�d��
             xoha.based_capacity,                                       -- ��{�e��
             xoha.sum_weight,                                           -- �ύڏd�ʍ��v
             xoha.sum_capacity,                                         -- �ύڗe�ύ��v
             xoha.mixed_ratio,                                          -- ���ڗ�
             xoha.pallet_sum_quantity,                                  -- �p���b�g���v����
             xoha.real_pallet_quantity,                                 -- �p���b�g���і���
             xoha.sum_pallet_weight,                                    -- ���v�p���b�g�d��
             xoha.order_source_ref,                                     -- �󒍃\�[�X�Q��
             xoha.result_freight_carrier_id,                            -- �^���Ǝ�_����ID
             xoha.result_freight_carrier_code,                          -- �^���Ǝ�_����
             xoha.result_shipping_method_code,                          -- �z���敪_����
             xoha.result_deliver_to_id,                                 -- �o�א�_����ID
             xoha.result_deliver_to,                                    -- �o�א�_����
             xoha.shipped_date,                                         -- �o�ד�
             xoha.arrival_date,                                         -- ���ד�
             xoha.weight_capacity_class,                                -- �d�ʗe�ϋ敪
             xoha.notif_status,                                         -- �ʒm�X�e�[�^�X
             xoha.prev_notif_status,                                    -- �O��ʒm�X�e�[�^�X
             xoha.notif_date,                                           -- �m��ʒm���{����
             xoha.new_modify_flg,                                       -- �V�K�C���t���O
             xoha.process_status,                                       -- �����o�߃X�e�[�^�X
             xoha.performance_management_dept,                          -- ���ъǗ�����
             xoha.instruction_dept,                                     -- �w������
             xoha.transfer_location_id,                                 -- �U�֐�ID
             xoha.transfer_location_code,                               -- �U�֐�
             xoha.mixed_sign,                                           -- ���ڋL��
             xoha.screen_update_date,                                   -- ��ʍX�V����
             xoha.screen_update_by,                                     -- ��ʍX�V��
             xoha.tightening_date,                                      -- �o�׈˗����ߓ���
             xoha.vendor_id,                                            -- �����ID
             xoha.vendor_code,                                          -- �����
             xoha.vendor_site_id,                                       -- �����T�C�gID
             xoha.vendor_site_code,                                     -- �����T�C�g
             xoha.registered_sequence,                                  -- �o�^����
             xoha.tightening_program_id,                                -- ���߃R���J�����gID
             xoha.corrected_tighten_class,                              -- ���ߌ�C���敪
             xola.order_line_id,                                        -- �󒍖��׃A�h�I��ID
             xola.order_line_number,                                    -- ���הԍ�
             xola.line_id,                                              -- �󒍖���ID
             xola.request_no line_request_no,                           -- �˗�No
             xola.shipping_inventory_item_id,                           -- �o�וi��ID
             xola.shipping_item_code,                                   -- �o�וi��
             xola.quantity,                                             -- ����
             xola.uom_code,                                             -- �P��
             xola.unit_price,                                           -- �P��
             xola.shipped_quantity,                                     -- �o�׎��ѐ���
             xola.designated_production_date line_designated_prod_date, -- �w�萻����
             xola.based_request_quantity,                               -- ���_�˗�����
             xola.request_item_id,                                      -- �˗��i��ID
             xola.request_item_code,                                    -- �˗��i��
             xola.ship_to_quantity,                                     -- ���Ɏ��ѐ���
             xola.futai_code,                                           -- �t�уR�[�h
             xola.designated_date,                                      -- �w����t�i���[�t�j
             xola.move_number,                                          -- �ړ�NO
             xola.po_number,                                            -- ����NO
             xola.cust_po_number line_cust_po_number,                   -- �ڋq����
             xola.pallet_quantity,                                      -- �p���b�g��
             xola.layer_quantity,                                       -- �i��
             xola.case_quantity,                                        -- �P�[�X��
             xola.weight,                                               -- �d��
             xola.capacity,                                             -- �e��
             xola.pallet_qty,                                           -- �p���b�g����
             xola.pallet_weight,                                        -- �p���b�g�d��
             xola.reserved_quantity,                                    -- ������
             xola.automanual_reserve_class,                             -- �����蓮�����敪
             xola.warning_class,                                        -- �x���敪
             xola.warning_date,                                         -- �x�����t
             xola.line_description,                                     -- �E�v
             xola.rm_if_flg,                                            -- �q�֕ԕiIF�σt���O
             xola.shipping_request_if_flg,                              -- �o�׈˗�IF�σt���O
             xola.shipping_result_if_flg,                               -- �o�׎���IF�σt���O
             xilv.distribution_block,                                   -- �u���b�N
             xilv.mtl_organization_id,                                  -- �݌ɑg�DID
             xilv.location_id,                                          -- ���Ə�ID
             xilv.subinventory_code,                                    -- �ۊǏꏊ�R�[�h
             xilv.inventory_location_id,                                -- �q��ID
             xcav.cust_account_id,                                      -- �ڋqID
             ximv.lot_ctl                                               -- ���b�g�Ǘ�
      FROM   xxwsh_order_headers_all xoha,                              -- �󒍃w�b�_�A�h�I��
             xxwsh_order_lines_all xola,                                -- �󒍖��׃A�h�I��
             xxwsh_oe_transaction_types_v xottv1,                       -- �󒍃^�C�vVIEW1
             xxcmn_item_locations_v xilv,                               -- OPM�ۊǏꏊ���VIEW
             xxcmn_cust_accounts_v xcav,                                -- �ڋq���VIEW
             xxcmn_item_mst_v ximv                                      -- OPM�i�ڏ��VIEW
      WHERE  xoha.req_status IN (gv_order_status_04,gv_order_status_08)
      AND    xoha.request_no = NVL(gt_request_no,xoha.request_no)
      AND    xoha.deliver_from =  NVL(gt_deliver_from,xoha.deliver_from)
      AND    xilv.segment1 = xoha.deliver_from
      AND    xilv.distribution_block = NVL(gt_block,xilv.distribution_block)
      AND    NVL(xoha.actual_confirm_class,gv_no) = gv_no
      AND    (  (xoha.latest_external_flag = gv_yes)
              OR(xottv1.shipping_shikyu_class = gv_ship_class_3)
             )
      AND    xottv1.transaction_type_id = xoha.order_type_id
      AND    xcav.party_id = xoha.customer_id
      AND    xola.order_header_id = xoha.order_header_id
      AND    NVL(xola.delete_flag,gv_no) = gv_no
      AND    ximv.item_no  = xola.shipping_item_code
      FOR UPDATE OF xoha.order_header_id,xola.order_line_id NOWAIT
      ORDER BY xoha.request_no,xoha.order_header_id,xola.order_line_id;
*/
-- 2008/09/01 Mod ��
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***       �󒍃A�h�I�����擾      ***
    -- ***************************************
-- 2008/09/01 Add ��
    -- �J�[�\���쐬
    lv_select1 := 'SELECT xottv1.transaction_type_id,'                     -- �󒍃^�C�vID
        ||   ' xottv1.transaction_type_code,'                              -- �󒍃^�C�v�R�[�h
        ||   ' xottv1.order_category_code,'                                -- �󒍃J�e�S��
        ||   ' xottv1.shipping_shikyu_class,'                              -- �o�׎x���敪
        ||   ' xoha.order_header_id,'                                      -- �󒍃w�b�_�A�h�I��ID
        ||   ' xoha.header_id,'                                            -- �󒍃w�b�_ID
        ||   ' xoha.organization_id,'                                      -- �g�DID
        ||   ' xoha.ordered_date,'                                         -- �󒍓�
        ||   ' xoha.customer_id,'                                          -- �ڋqID
        ||   ' xoha.customer_code,'                                        -- �ڋq
        ||   ' xoha.deliver_to_id,'                                        -- �o�א�ID
        ||   ' xoha.deliver_to,'                                           -- �o�א�
        ||   ' xoha.shipping_instructions,'                                -- �o�׎w��
        ||   ' xoha.career_id,'                                            -- �^���Ǝ�ID
        ||   ' xoha.freight_carrier_code,'                                 -- �^���Ǝ�
        ||   ' xoha.shipping_method_code,'                                 -- �z���敪
        ||   ' xoha.cust_po_number,'                                       -- �ڋq����
        ||   ' xoha.price_list_id,'                                        -- ���i�\
        ||   ' xoha.request_no,'                                           -- �˗�NO
        ||   ' xoha.req_status,'                                           -- �X�e�[�^�X
        ||   ' xoha.delivery_no,'                                          -- �z��NO
        ||   ' xoha.prev_delivery_no,'                                     -- �O��z��NO
        ||   ' xoha.schedule_ship_date,'                                   -- �o�ח\���
        ||   ' xoha.schedule_arrival_date,'                                -- ���ח\���
        ||   ' xoha.mixed_no,'                                             -- ���ڌ�NO
        ||   ' xoha.collected_pallet_qty,'                                 -- �p���b�g�������
        ||   ' xoha.confirm_request_class,'                                -- �����S���m�F�˗��敪
        ||   ' xoha.freight_charge_class,'                                 -- �^���敪
        ||   ' xoha.shikyu_instruction_class,'                             -- �x���o�Ɏw���敪
        ||   ' xoha.shikyu_inst_rcv_class,'                                -- �x���w����̋敪
        ||   ' xoha.amount_fix_class,'                                     -- �L�����z�m��敪
        ||   ' xoha.takeback_class,'                                       -- ����敪
        ||   ' xoha.deliver_from_id,'                                      -- �o�׌�ID
        ||   ' xoha.deliver_from,'                                         -- �o�׌��ۊǏꏊ
        ||   ' xoha.head_sales_branch,'                                    -- �Ǌ����_
        ||   ' xoha.input_sales_branch,'                                   -- ���͋��_
        ||   ' xoha.po_no,'                                                -- ����NO
        ||   ' xoha.prod_class,'                                           -- ���i�敪
        ||   ' xoha.item_class,'                                           -- �i�ڋ敪
        ||   ' xoha.no_cont_freight_class,'                                -- �_��O�^���敪
        ||   ' xoha.arrival_time_from,'                                    -- ���׎���FROM
        ||   ' xoha.arrival_time_to,'                                      -- ���׎���TO
        ||   ' xoha.designated_item_id,'                                   -- �����i��ID
        ||   ' xoha.designated_item_code,'                                 -- �����i��
        ||   ' xoha.designated_production_date,'                           -- ������
        ||   ' xoha.designated_branch_no,'                                 -- �����}��
        ||   ' xoha.slip_number,'                                          -- �����NO
        ||   ' xoha.sum_quantity,'                                         -- ���v����
        ||   ' xoha.small_quantity,'                                       -- ������
        ||   ' xoha.label_quantity,'                                       -- ���x������
        ||   ' xoha.loading_efficiency_weight,'                            -- �d�ʐύڌ���
        ||   ' xoha.loading_efficiency_capacity,'                          -- �e�ϐύڌ���
        ||   ' xoha.based_weight,'                                         -- ��{�d��
        ||   ' xoha.based_capacity,'                                       -- ��{�e��
        ||   ' xoha.sum_weight,'                                           -- �ύڏd�ʍ��v
        ||   ' xoha.sum_capacity,'                                         -- �ύڗe�ύ��v
        ||   ' xoha.mixed_ratio,'                                          -- ���ڗ�
        ||   ' xoha.pallet_sum_quantity,'                                  -- �p���b�g���v����
        ||   ' xoha.real_pallet_quantity,'                                 -- �p���b�g���і���
        ||   ' xoha.sum_pallet_weight,'                                    -- ���v�p���b�g�d��
        ||   ' xoha.order_source_ref,'                                     -- �󒍃\�[�X�Q��
        ||   ' xoha.result_freight_carrier_id,'                            -- �^���Ǝ�_����ID
        ||   ' xoha.result_freight_carrier_code,'                          -- �^���Ǝ�_����
        ||   ' xoha.result_shipping_method_code,'                          -- �z���敪_����
        ||   ' xoha.result_deliver_to_id,'                                 -- �o�א�_����ID
        ||   ' xoha.result_deliver_to,'                                    -- �o�א�_����
        ||   ' xoha.shipped_date,'                                         -- �o�ד�
        ||   ' xoha.arrival_date,'                                         -- ���ד�
        ||   ' xoha.weight_capacity_class,'                                -- �d�ʗe�ϋ敪
        ||   ' xoha.notif_status,'                                         -- �ʒm�X�e�[�^�X
        ||   ' xoha.prev_notif_status,'                                    -- �O��ʒm�X�e�[�^�X
        ||   ' xoha.notif_date,'                                           -- �m��ʒm���{����
        ||   ' xoha.new_modify_flg,'                                       -- �V�K�C���t���O
        ||   ' xoha.process_status,'                                       -- �����o�߃X�e�[�^�X
        ||   ' xoha.performance_management_dept,'                          -- ���ъǗ�����
        ||   ' xoha.instruction_dept,'                                     -- �w������
        ||   ' xoha.transfer_location_id,'                                 -- �U�֐�ID
        ||   ' xoha.transfer_location_code,'                               -- �U�֐�
        ||   ' xoha.mixed_sign,'                                           -- ���ڋL��
        ||   ' xoha.screen_update_date,'                                   -- ��ʍX�V����
        ||   ' xoha.screen_update_by,'                                     -- ��ʍX�V��
        ||   ' xoha.tightening_date,'                                      -- �o�׈˗����ߓ���
        ||   ' xoha.vendor_id,'                                            -- �����ID
        ||   ' xoha.vendor_code,'                                          -- �����
        ||   ' xoha.vendor_site_id,'                                       -- �����T�C�gID
        ||   ' xoha.vendor_site_code,'                                     -- �����T�C�g
        ||   ' xoha.registered_sequence,'                                  -- �o�^����
        ||   ' xoha.tightening_program_id,'                                -- ���߃R���J�����gID
        ||   ' xoha.corrected_tighten_class,'                              -- ���ߌ�C���敪
        ||   ' xola.order_line_id,'                                        -- �󒍖��׃A�h�I��ID
        ||   ' xola.order_line_number,'                                    -- ���הԍ�
        ||   ' xola.line_id,'                                              -- �󒍖���ID
        ||   ' xola.request_no line_request_no,'                           -- �˗�No
        ||   ' xola.shipping_inventory_item_id,'                           -- �o�וi��ID
        ||   ' xola.shipping_item_code,'                                   -- �o�וi��
        ||   ' xola.quantity,'                                             -- ����
        ||   ' xola.uom_code,'                                             -- �P��
        ||   ' xola.unit_price,'                                           -- �P��
        ||   ' xola.shipped_quantity,'                                     -- �o�׎��ѐ���
        ||   ' xola.designated_production_date line_designated_prod_date,' -- �w�萻����
        ||   ' xola.based_request_quantity,'                               -- ���_�˗�����
        ||   ' xola.request_item_id,'                                      -- �˗��i��ID
        ||   ' xola.request_item_code,'                                    -- �˗��i��
        ||   ' xola.ship_to_quantity,'                                     -- ���Ɏ��ѐ���
        ||   ' xola.futai_code,'                                           -- �t�уR�[�h
        ||   ' xola.designated_date,'                                      -- �w����t�i���[�t�j
        ||   ' xola.move_number,'                                          -- �ړ�NO
        ||   ' xola.po_number,'                                            -- ����NO
        ||   ' xola.cust_po_number line_cust_po_number,'                   -- �ڋq����
        ||   ' xola.pallet_quantity,'                                      -- �p���b�g��
        ||   ' xola.layer_quantity,'                                       -- �i��
        ||   ' xola.case_quantity,'                                        -- �P�[�X��
        ||   ' xola.weight,'                                               -- �d��
        ||   ' xola.capacity,'                                             -- �e��
        ||   ' xola.pallet_qty,'                                           -- �p���b�g����
        ||   ' xola.pallet_weight,'                                        -- �p���b�g�d��
        ||   ' xola.reserved_quantity,'                                    -- ������
        ||   ' xola.automanual_reserve_class,'                             -- �����蓮�����敪
        ||   ' xola.warning_class,'                                        -- �x���敪
        ||   ' xola.warning_date,'                                         -- �x�����t
        ||   ' xola.line_description,'                                     -- �E�v
        ||   ' xola.rm_if_flg,'                                            -- �q�֕ԕiIF�σt���O
        ||   ' xola.shipping_request_if_flg,'                              -- �o�׈˗�IF�σt���O
        ||   ' xola.shipping_result_if_flg,'                               -- �o�׎���IF�σt���O
        ||   ' xilv.distribution_block,'                                   -- �u���b�N
        ||   ' xilv.mtl_organization_id,'                                  -- �݌ɑg�DID
        ||   ' xilv.location_id,'                                          -- ���Ə�ID
        ||   ' xilv.subinventory_code,'                                    -- �ۊǏꏊ�R�[�h
        ||   ' xilv.inventory_location_id,'                                -- �q��ID
        ||   ' xcav.cust_account_id,'                                      -- �ڋqID
        ||   ' ximv.lot_ctl'                                               -- ���b�g�Ǘ�
        ||' FROM   xxwsh_order_headers_all     xoha,'                      -- �󒍃w�b�_�A�h�I��
        ||   '       xxwsh_order_lines_all        xola,'                   -- �󒍖��׃A�h�I��
        ||   '       xxwsh_oe_transaction_types_v xottv1,'                 -- �󒍃^�C�vVIEW1
        ||   '       xxcmn_item_locations_v       xilv,'                   -- OPM�ۊǏꏊ���VIEW
        ||   '       xxcmn_cust_accounts_v        xcav,'                   -- �ڋq���VIEW
        ||   '       xxcmn_item_mst_v             ximv';                   -- OPM�i�ڏ��VIEW
--
    lv_select_where := ' WHERE  xottv1.transaction_type_id = xoha.order_type_id'
        ||   ' AND    xcav.party_id = xoha.customer_id'
        ||   ' AND    xola.order_header_id = xoha.order_header_id'
        ||   ' AND    xilv.segment1 = xoha.deliver_from'
        ||   ' AND    ximv.item_no  = xola.shipping_item_code'
        ||   ' AND    NVL(xoha.actual_confirm_class, '''|| gv_no || ''') = ''' || gv_no || ''''
        ||   ' AND    ((xoha.latest_external_flag = ''' || gv_yes || ''')'
        ||   ' OR      (xottv1.shipping_shikyu_class = ''' || gv_ship_class_3 || '''))'
        ||   ' AND    NVL(xola.delete_flag,'''|| gv_no || ''') = ''' || gv_no || ''''
        ||   ' AND    xoha.req_status IN (''' || gv_order_status_04 || ''','''|| gv_order_status_08 || ''')';
--
    -- �˗�No
    IF (gt_request_no IS NOT NULL) THEN
      lv_select_where := lv_select_where
          || ' AND    xoha.request_no = ''' || gt_request_no || '''';
    END IF;
--
    -- �o�׌��ۊǏꏊ
    IF (gt_deliver_from IS NOT NULL) THEN
      lv_select_where := lv_select_where
          || ' AND    xoha.deliver_from =  ''' || gt_deliver_from || '''';
    END IF;
--
    -- �u���b�N
    IF (gt_block IS NOT NULL) THEN
      lv_select_where := lv_select_where
          || ' AND    xilv.distribution_block = ''' || gt_block || '''';
    END IF;
--
    lv_select_lock  := ' FOR UPDATE OF xoha.order_header_id,xola.order_line_id NOWAIT';
    lv_select_order := ' ORDER BY xoha.request_no,xoha.order_header_id,xola.order_line_id';
-- 2008/09/01 Add ��
    -- �J�[�\���I�[�v��
    BEGIN
-- 2008/09/01 Mod ��
/*
      OPEN cur_order_data;
*/
      OPEN cur_order_data FOR lv_select1 || lv_select_where || lv_select_lock || lv_select_order;
-- 2008/09/01 Mod ��
      -- �o���N�t�F�b�`
      FETCH cur_order_data BULK COLLECT INTO or_order_info_tbl ;
      -- �J�[�\���N���[�Y
      CLOSE cur_order_data ;
    EXCEPTION
      WHEN lock_error_expt THEN -- ���b�N�G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_019
        );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
-- 2008/09/01 Mod ��
/*
    -- �˗�No�P�ʂ̌������擾(A3�̌����͖��גP�ʂ̂���)
    SELECT COUNT(xoha.request_no)
    INTO   gn_input_cnt
    FROM   xxwsh_order_headers_all xoha,                              -- �󒍃w�b�_�A�h�I��
           xxwsh_oe_transaction_types_v xottv1,                       -- �󒍃^�C�vVIEW1
           xxcmn_item_locations_v xilv                                -- OPM�ۊǏꏊ���VIEW
    WHERE  xoha.req_status IN (gv_order_status_04,gv_order_status_08)
    AND    xoha.request_no = NVL(gt_request_no,xoha.request_no)
    AND    xoha.deliver_from = NVL(gt_deliver_from,xoha.deliver_from)
    AND    xilv.segment1 = xoha.deliver_from
    AND    xilv.distribution_block = NVL(gt_block,xilv.distribution_block)
    AND    NVL(xoha.actual_confirm_class,gv_no) = gv_no
    AND    (  (xoha.latest_external_flag = gv_yes)
            OR(xottv1.shipping_shikyu_class = gv_ship_class_3)
           )
    AND    xottv1.transaction_type_id = xoha.order_type_id
    AND EXISTS (
        SELECT xola.order_header_id
        FROM   xxwsh_order_lines_all xola,                                -- �󒍖��׃A�h�I��
               xxcmn_item_mst_v ximv                                      -- OPM�i�ڏ��VIEW
        WHERE xola.order_header_id = xoha.order_header_id
        AND   NVL(xola.delete_flag,gv_no) = gv_no
        AND   ximv.item_no  = xola.shipping_item_code
    );
*/
    lv_select2 := 'SELECT COUNT(xoha.request_no)'
        ||       ' FROM   xxwsh_order_headers_all      xoha,'
        ||       '       xxwsh_oe_transaction_types_v  xottv1,'
        ||       '       xxcmn_item_locations_v        xilv'
        ||       ' WHERE  xoha.req_status IN (''' || gv_order_status_04 || ''','''|| gv_order_status_08 || ''')'
        ||       ' AND    xilv.segment1 = xoha.deliver_from'
        ||       ' AND    xottv1.transaction_type_id = xoha.order_type_id'
        ||       ' AND    NVL(xoha.actual_confirm_class, '''|| gv_no || ''') = ''' || gv_no || ''''
        ||       ' AND    ((xoha.latest_external_flag = ''' || gv_yes || ''')'
        ||       ' OR      (xottv1.shipping_shikyu_class = ''' || gv_ship_class_3 || '''))';
--
    -- �˗�No
    IF (gt_request_no IS NOT NULL) THEN
      lv_select2 := lv_select2 || ' AND    xoha.request_no = ''' || gt_request_no || '''';
    END IF;
--
    -- �o�׌��ۊǏꏊ
    IF (gt_deliver_from IS NOT NULL) THEN
      lv_select2 := lv_select2 || ' AND    xoha.deliver_from = ''' || gt_deliver_from || '''';
    END IF;
--
    -- �u���b�N
    IF (gt_block IS NOT NULL) THEN
      lv_select2 := lv_select2 || ' AND    xilv.distribution_block = ''' || gt_block || '''';
    END IF;
--
    lv_select2 := lv_select2 
        ||       ' AND EXISTS ('
        ||       ' SELECT xola.order_header_id'
        ||       ' FROM   xxwsh_order_lines_all xola,'
        ||       '        xxcmn_item_mst_v      ximv'
        ||       ' WHERE xola.order_header_id = xoha.order_header_id'
        ||       ' AND   NVL(xola.delete_flag,'''|| gv_no || ''') = ''' || gv_no || ''''
        ||       ' AND   ximv.item_no  = xola.shipping_item_code )';
--
    EXECUTE IMMEDIATE lv_select2 INTO gn_input_cnt;
-- 2008/09/01 Mod ��
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cur_order_data%ISOPEN THEN
        CLOSE cur_order_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cur_order_data%ISOPEN THEN
        CLOSE cur_order_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_order_data%ISOPEN THEN
        CLOSE cur_order_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_order_info;
  /***********************************************************************************
   * Procedure Name   : get_same_request_number
   * Description      : A4����˗�No��������
   ***********************************************************************************/
  PROCEDURE get_same_request_number(
    it_request_no
        IN  xxwsh_order_headers_all.request_no%TYPE,            -- ����˗�No
    on_same_request_no
        OUT NOCOPY NUMBER,                                      -- ����˗�No����
    ot_old_order_header_id
        OUT NOCOPY xxwsh_order_headers_all.order_header_id%TYPE,-- �󒍃w�b�_�A�h�I��ID(OLD)
    ov_errbuf
        OUT NOCOPY VARCHAR2,                                    -- �G���[�E���b�Z�[�W --# �Œ� #
    ov_retcode
        OUT NOCOPY VARCHAR2,                                    -- ���^�[���E�R�[�h   --# �Œ� #
    ov_errmsg
        OUT NOCOPY VARCHAR2)                                    -- ���[�U�G���[���b�Z�[�W--# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_same_request_number'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
     ln_return_code         NUMBER;                                      -- �֐��߂�l
     ln_same_request_no     NUMBER;                                      -- ����˗�No����
     lt_old_order_header_id xxwsh_order_headers_all.order_header_id%TYPE;-- �w�b�_�A�h�I��ID(OLD)
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    ln_return_code := xxwsh_common_pkg.get_same_request_number(
                        it_request_no,
                        ln_same_request_no,    -- ����˗�No����
                        lt_old_order_header_id -- �󒍃w�b�_�A�h�I��ID(OLD)
    );
    IF (ln_return_code <> gv_status_normal) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
                     gv_msg_kbn_wsh,
                     gv_msg_42a_022,
                     gv_tkn_request_no,
                     it_request_no
      );
      RAISE global_api_expt;
    END IF;
    on_same_request_no     := ln_same_request_no;     -- ����˗�No����
    ot_old_order_header_id := lt_old_order_header_id; -- �󒍃w�b�_�A�h�I��ID(OLD)
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_same_request_number;
  /***********************************************************************************
   * Procedure Name   : get_revised order_info
   * Description      : A5�����O�󒍃w�b�_�A�h�I�����擾
   ***********************************************************************************/
  PROCEDURE get_revised_order_info(
    it_order_header_id
        IN xxwsh_order_headers_all.order_header_id%TYPE, -- �����O�󒍃w�b�_�A�h�I��ID
    or_order_info_tbl
        OUT NOCOPY order_tbl,                            -- �󒍃A�h�I�����i�[�p�z��
    ov_errbuf
        OUT NOCOPY VARCHAR2,                             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode
        OUT NOCOPY VARCHAR2,                             -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg
        OUT NOCOPY VARCHAR2)                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_revised_order_info'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    CURSOR cur_order_data IS
      SELECT xottv2.transaction_type_id,                                -- �󒍃^�C�vID
             xottv2.transaction_type_code,                              -- �󒍃^�C�v�R�[�h
             xottv2.order_category_code,                                -- �󒍃J�e�S��
             xottv2.shipping_shikyu_class,                              -- �o�׎x���敪
             xoha.order_header_id,                                      -- �󒍃w�b�_�A�h�I��ID
             xoha.header_id,                                            -- �󒍃w�b�_ID
             xoha.organization_id,                                      -- �g�DID
             xoha.ordered_date,                                         -- �󒍓�
             xoha.customer_id,                                          -- �ڋqID
             xoha.customer_code,                                        -- �ڋq
             xoha.deliver_to_id,                                        -- �o�א�ID
             xoha.deliver_to,                                           -- �o�א�
             xoha.shipping_instructions,                                -- �o�׎w��
             xoha.career_id,                                            -- �^���Ǝ�ID
             xoha.freight_carrier_code,                                 -- �^���Ǝ�
             xoha.shipping_method_code,                                 -- �z���敪
             xoha.cust_po_number,                                       -- �ڋq����
             xoha.price_list_id,                                        -- ���i�\
             xoha.request_no,                                           -- �˗�NO
             xoha.req_status,                                           -- �X�e�[�^�X
             xoha.delivery_no,                                          -- �z��NO
             xoha.prev_delivery_no,                                     -- �O��z��NO
             xoha.schedule_ship_date,                                   -- �o�ח\���
             xoha.schedule_arrival_date,                                -- ���ח\���
             xoha.mixed_no,                                             -- ���ڌ�NO
             xoha.collected_pallet_qty,                                 -- �p���b�g�������
             xoha.confirm_request_class,                                -- �����S���m�F�˗��敪
             xoha.freight_charge_class,                                 -- �^���敪
             xoha.shikyu_instruction_class,                             -- �x���o�Ɏw���敪
             xoha.shikyu_inst_rcv_class,                                -- �x���w����̋敪
             xoha.amount_fix_class,                                     -- �L�����z�m��敪
             xoha.takeback_class,                                       -- ����敪
             xoha.deliver_from_id,                                      -- �o�׌�ID
             xoha.deliver_from,                                         -- �o�׌��ۊǏꏊ
             xoha.head_sales_branch,                                    -- �Ǌ����_
             xoha.input_sales_branch,                                   -- ���͋��_
             xoha.po_no,                                                -- ����NO
             xoha.prod_class,                                           -- ���i�敪
             xoha.item_class,                                           -- �i�ڋ敪
             xoha.no_cont_freight_class,                                -- �_��O�^���敪
             xoha.arrival_time_from,                                    -- ���׎���FROM
             xoha.arrival_time_to,                                      -- ���׎���TO
             xoha.designated_item_id,                                   -- �����i��ID
             xoha.designated_item_code,                                 -- �����i��
             xoha.designated_production_date,                           -- ������
             xoha.designated_branch_no,                                 -- �����}��
             xoha.slip_number,                                          -- �����NO
             xoha.sum_quantity,                                         -- ���v����
             xoha.small_quantity,                                       -- ������
             xoha.label_quantity,                                       -- ���x������
             xoha.loading_efficiency_weight,                            -- �d�ʐύڌ���
             xoha.loading_efficiency_capacity,                          -- �e�ϐύڌ���
             xoha.based_weight,                                         -- ��{�d��
             xoha.based_capacity,                                       -- ��{�e��
             xoha.sum_weight,                                           -- �ύڏd�ʍ��v
             xoha.sum_capacity,                                         -- �ύڗe�ύ��v
             xoha.mixed_ratio,                                          -- ���ڗ�
             xoha.pallet_sum_quantity,                                  -- �p���b�g���v����
             xoha.real_pallet_quantity,                                 -- �p���b�g���і���
             xoha.sum_pallet_weight,                                    -- ���v�p���b�g�d��
             xoha.order_source_ref,                                     -- �󒍃\�[�X�Q��
             xoha.result_freight_carrier_id,                            -- �^���Ǝ�_����ID
             xoha.result_freight_carrier_code,                          -- �^���Ǝ�_����
             xoha.result_shipping_method_code,                          -- �z���敪_����
             xoha.result_deliver_to_id,                                 -- �o�א�_����ID
             xoha.result_deliver_to,                                    -- �o�א�_����
             xoha.shipped_date,                                         -- �o�ד�
             xoha.arrival_date,                                         -- ���ד�
             xoha.weight_capacity_class,                                -- �d�ʗe�ϋ敪
             xoha.notif_status,                                         -- �ʒm�X�e�[�^�X
             xoha.prev_notif_status,                                    -- �O��ʒm�X�e�[�^�X
             xoha.notif_date,                                           -- �m��ʒm���{����
             xoha.new_modify_flg,                                       -- �V�K�C���t���O
             xoha.process_status,                                       -- �����o�߃X�e�[�^�X
             xoha.performance_management_dept,                          -- ���ъǗ�����
             xoha.instruction_dept,                                     -- �w������
             xoha.transfer_location_id,                                 -- �U�֐�ID
             xoha.transfer_location_code,                               -- �U�֐�
             xoha.mixed_sign,                                           -- ���ڋL��
             xoha.screen_update_date,                                   -- ��ʍX�V����
             xoha.screen_update_by,                                     -- ��ʍX�V��
             xoha.tightening_date,                                      -- �o�׈˗����ߓ���
             xoha.vendor_id,                                            -- �����ID
             xoha.vendor_code,                                          -- �����
             xoha.vendor_site_id,                                       -- �����T�C�gID
             xoha.vendor_site_code,                                     -- �����T�C�g
             xoha.registered_sequence,                                  -- �o�^����
             xoha.tightening_program_id,                                -- ���߃R���J�����gID
             xoha.corrected_tighten_class,                              -- ���ߌ�C���敪
             xola.order_line_id,                                        -- �󒍖��׃A�h�I��ID
             xola.order_line_number,                                    -- ���הԍ�
             xola.line_id,                                              -- �󒍖���ID
             xola.request_no line_request_no,                           -- �˗�No
             xola.shipping_inventory_item_id,                           -- �o�וi��ID
             xola.shipping_item_code,                                   -- �o�וi��
             xola.quantity,                                             -- ����
             xola.uom_code,                                             -- �P��
             xola.unit_price,                                           -- �P��
             xola.shipped_quantity,                                     -- �o�׎��ѐ���
             xola.designated_production_date line_designated_prod_date, -- �w�萻����
             xola.based_request_quantity,                               -- ���_�˗�����
             xola.request_item_id,                                      -- �˗��i��ID
             xola.request_item_code,                                    -- �˗��i��
             xola.ship_to_quantity,                                     -- ���Ɏ��ѐ���
             xola.futai_code,                                           -- �t�уR�[�h
             xola.designated_date,                                      -- �w����t�i���[�t�j
             xola.move_number,                                          -- �ړ�NO
             xola.po_number,                                            -- ����NO
             xola.cust_po_number line_cust_po_number,                   -- �ڋq����
             xola.pallet_quantity,                                      -- �p���b�g��
             xola.layer_quantity,                                       -- �i��
             xola.case_quantity,                                        -- �P�[�X��
             xola.weight,                                               -- �d��
             xola.capacity,                                             -- �e��
             xola.pallet_qty,                                           -- �p���b�g����
             xola.pallet_weight,                                        -- �p���b�g�d��
             xola.reserved_quantity,                                    -- ������
             xola.automanual_reserve_class,                             -- �����蓮�����敪
             xola.warning_class,                                        -- �x���敪
             xola.warning_date,                                         -- �x�����t
             xola.line_description,                                     -- �E�v
             xola.rm_if_flg,                                            -- �q�֕ԕiIF�σt���O
             xola.shipping_request_if_flg,                              -- �o�׈˗�IF�σt���O
             xola.shipping_result_if_flg,                               -- �o�׎���IF�σt���O
             xilv.distribution_block,                                   -- �u���b�N
             xilv.mtl_organization_id,                                  -- �݌ɑg�DID
             xilv.location_id,                                          -- ���Ə�ID
             xilv.subinventory_code,                                    -- �ۊǏꏊ�R�[�h
             xilv.inventory_location_id,                                -- �q��ID
             xcav.cust_account_id,                                      -- �ڋqID
             ximv.lot_ctl                                               -- ���b�g�Ǘ�
      FROM   xxwsh_order_headers_all xoha,                              -- �󒍃w�b�_�A�h�I��
             xxwsh_order_lines_all xola,                                -- �󒍖��׃A�h�I��
             xxwsh_oe_transaction_types_v xottv1,                       -- �󒍃^�C�vVIEW1
             xxwsh_oe_transaction_types_v xottv2,                       -- �󒍃^�C�vVIEW2
             xxcmn_cust_accounts_v xcav,                                -- �ڋq���VIEW
             xxcmn_item_locations_v xilv,                               -- OPM�ۊǏꏊ���VIEW
             xxcmn_item_mst_v ximv                                      -- OPM�i�ڏ��VIEW
      WHERE  xoha.order_header_id = it_order_header_id
      AND    NVL(xoha.latest_external_flag,gv_no) = gv_no
      AND    xilv.segment1 = xoha.deliver_from
      AND    xottv1.transaction_type_id = xoha.order_type_id
      AND    xottv2.transaction_type_name = xottv1.cancel_order_type
      AND    xcav.party_id = xoha.customer_id
      AND    xola.order_header_id = xoha.order_header_id
      AND    NVL(xola.delete_flag,gv_no) = gv_no
      AND    ximv.item_no  = xola.shipping_item_code;
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***       ����󒍃A�h�I�����擾  ***
    -- ***************************************
    -- �J�[�\���I�[�v��
    OPEN cur_order_data;
    -- �o���N�t�F�b�`
    FETCH cur_order_data BULK COLLECT INTO or_order_info_tbl ;
    -- �J�[�\���N���[�Y
    CLOSE cur_order_data ;
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cur_order_data%ISOPEN THEN
        CLOSE cur_order_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cur_order_data%ISOPEN THEN
        CLOSE cur_order_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_order_data%ISOPEN THEN
        CLOSE cur_order_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_revised_order_info;
  /***********************************************************************************
   * Procedure Name   : create_order_header_info
   * Description      : A6�󒍃w�b�_���̓o�^
   ***********************************************************************************/
  PROCEDURE create_order_header_info(
    iot_order_tbl
        IN OUT order_tbl,                                        -- �󒍏��i�[�z��
    ot_new_order_header_id
        OUT NOCOPY xxwsh_order_headers_all.order_header_id%TYPE, -- �ԗp�V�󒍃w�b�_�A�h�I��ID
    ot_new_header_id
        OUT NOCOPY xxwsh_order_headers_all.header_id%TYPE,       -- �ԗp�V�󒍃w�b�_ID
    ot_shipped_date
        OUT NOCOPY xxwsh_order_headers_all.shipped_date%TYPE,    -- �o�ד�
    ov_standard_api_flag
        OUT NOCOPY NUMBER,                                       -- �W��API���s�t���O
    on_gen_count
        OUT NOCOPY NUMBER,                                       -- ���݂̃f�[�^�̈ʒu��ێ�
    ov_errbuf
        OUT NOCOPY VARCHAR2,                                     -- �G���[�E���b�Z�[�W--# �Œ� #
    ov_retcode
        OUT NOCOPY VARCHAR2,                                     -- ���^�[���E�R�[�h--# �Œ� #
    ov_errmsg
        OUT NOCOPY VARCHAR2)                                     -- ���[�U�G���[���b�Z�[�W--#�Œ�#
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_order_header_info'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_return_status
        VARCHAR2(1) ;                                 -- API�̏����X�e�[�^�X
    ln_msg_count
        NUMBER;                                       -- API�̃G���[���b�Z�[�W����
    lv_msg_data
        VARCHAR2(2000) ;                              -- API�̃G���[���b�Z�[�W
    lv_msg_buf
        VARCHAR2(2000);                               -- API���b�Z�[�W�����p
    lt_new_order_header_id
        xxwsh_order_headers_all.order_header_id%TYPE; -- �V�󒍃w�b�_�A�h�I��ID
    ln_shori_count
        NUMBER;                                       -- �����ʒu����
    ln_line_count
        NUMBER;                                       -- ���׌���(���ѐ��ʂ�0�ȏ�)
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lt_header_rec              OE_ORDER_PUB.HEADER_REC_TYPE;
    lt_header_val_rec          OE_ORDER_PUB.HEADER_VAL_REC_TYPE;
    lt_header_adj_tbl          OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE;
    lt_header_adj_val_tbl      OE_ORDER_PUB.HEADER_ADJ_VAL_TBL_TYPE;
    lt_header_price_att_tbl    OE_ORDER_PUB.HEADER_PRICE_ATT_TBL_TYPE;
    lt_header_adj_att_tbl      OE_ORDER_PUB.HEADER_ADJ_ATT_TBL_TYPE;
    lt_header_adj_assoc_tbl    OE_ORDER_PUB.HEADER_ADJ_ASSOC_TBL_TYPE;
    lt_header_scredit_tbl      OE_ORDER_PUB.HEADER_SCREDIT_TBL_TYPE;
    lt_header_scredit_val_tbl  OE_ORDER_PUB.HEADER_SCREDIT_VAL_TBL_TYPE;
    lt_line_tbl                OE_ORDER_PUB.LINE_TBL_TYPE;
    lt_line_val_tbl            OE_ORDER_PUB.LINE_VAL_TBL_TYPE;
    lt_line_adj_tbl            OE_ORDER_PUB.LINE_ADJ_TBL_TYPE;
    lt_line_adj_val_tbl        OE_ORDER_PUB.LINE_ADJ_VAL_TBL_TYPE;
    lt_line_price_att_tbl      OE_ORDER_PUB.LINE_PRICE_ATT_TBL_TYPE;
    lt_line_adj_att_tbl        OE_ORDER_PUB.LINE_ADJ_ATT_TBL_TYPE;
    lt_line_adj_assoc_tbl      OE_ORDER_PUB.LINE_ADJ_ASSOC_TBL_TYPE;
    lt_line_scredit_tbl        OE_ORDER_PUB.LINE_SCREDIT_TBL_TYPE;
    lt_line_scredit_val_tbl    OE_ORDER_PUB.LINE_SCREDIT_VAL_TBL_TYPE;
    lt_lot_serial_tbl          OE_ORDER_PUB.LOT_SERIAL_TBL_TYPE;
    lt_lot_serial_val_tbl      OE_ORDER_PUB.LOT_SERIAL_VAL_TBL_TYPE;
    lt_action_request_tbl      OE_ORDER_PUB.REQUEST_TBL_TYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    --A3�Ŏ擾�����f�[�^��A5�Ŏ擾�����f�[�^���ɂ�背�R�[�h�̊�l���قȂ�
    IF (gv_shori_kbn IN ('1','3') ) THEN
      ln_shori_count := gn_shori_count;
    ELSE
      ln_shori_count := 1;
    END IF;
--
    on_gen_count     := ln_shori_count; -- ���׍쐬�����Ɍ��݂̈ʒu��n������
    ot_shipped_date  := iot_order_tbl(ln_shori_count).shipped_date; --�o�ד�
--
    -- �󒍖��׍쐬�Ώی����𒲍�
    SELECT count(xola.order_line_id)
    INTO   ln_line_count
    FROM   xxwsh_order_lines_all xola
    WHERE  xola.order_header_id = iot_order_tbl(ln_shori_count).order_header_id
    AND    NVL(xola.delete_flag,gv_no) = gv_no
    AND    NVL(xola.shipped_quantity,0) <> 0;
--
    IF (ln_line_count > 0 ) THEN
--
      ov_standard_api_flag := '1';--�W��API���s�t���O��1(���s)���Z�b�g
      -- OM���b�Z�[�W���X�g�̏�����
      OE_MSG_PUB.INITIALIZE;
      -- API�p�ϐ��ɏ����l���Z�b�g
      lt_header_rec                         := OE_ORDER_PUB.G_MISS_HEADER_REC;
      lt_line_tbl(1)                        := OE_ORDER_PUB.G_MISS_LINE_REC;
      lt_header_rec.operation               := OE_GLOBALS.G_OPR_CREATE;                                                -- [CREATE]
      lt_header_rec.sold_to_org_id          := iot_order_tbl(ln_shori_count).cust_account_id;                          -- �ڋq
      lt_header_rec.org_id                  := gn_org_id;                                                              -- �c�ƒP��
      lt_header_rec.order_type_id           := iot_order_tbl(ln_shori_count).transaction_type_id;                      -- �󒍃^�C�v���Z�b�g
      lt_header_rec.ordered_date            := iot_order_tbl(ln_shori_count).ordered_date;                             -- �󒍓�
--
      IF (iot_order_tbl(ln_shori_count).shipping_shikyu_class <> gv_ship_class_2) THEN
         --�o�׎x���敪���x���˗��ȊO�̏ꍇ
        lt_header_rec.ship_to_party_site_id := iot_order_tbl(ln_shori_count).result_deliver_to_id;                     -- �o�א�ID
      END IF;
--
      lt_header_rec.shipping_instructions   := iot_order_tbl(ln_shori_count).shipping_instructions;                       -- �o�׎w��
      lt_header_rec.cust_po_number          := iot_order_tbl(ln_shori_count).cust_po_number;                              -- �ڋq����
      lt_header_rec.ship_from_org_id        := iot_order_tbl(ln_shori_count).mtl_organization_id;                         -- �݌ɑg�DID
      lt_header_rec.attribute1              := iot_order_tbl(ln_shori_count).request_no;                                  -- �˗�No
      lt_header_rec.attribute2              := iot_order_tbl(ln_shori_count).delivery_no;                                 -- �z��No
      lt_header_rec.attribute3              := iot_order_tbl(ln_shori_count).result_freight_carrier_code;                 -- �^���Ǝ�_����
      lt_header_rec.attribute4              := iot_order_tbl(ln_shori_count).result_shipping_method_code;                 -- �z���敪_����
      lt_header_rec.attribute6              := TO_CHAR(iot_order_tbl(ln_shori_count).schedule_ship_date,'YYYY/MM/DD');    -- �o�ח\���
      lt_header_rec.attribute7              := iot_order_tbl(ln_shori_count).head_sales_branch;                           -- �Ǌ����_
      lt_header_rec.attribute8              := iot_order_tbl(ln_shori_count).deliver_from;                                -- �o�׌�
      lt_header_rec.attribute9              := TO_CHAR(iot_order_tbl(ln_shori_count).shipped_date,'YYYY/MM/DD');          -- �o�ד�
      lt_header_rec.attribute10             := TO_CHAR(iot_order_tbl(ln_shori_count).arrival_date,'YYYY/MM/DD');          -- ���ד�
      lt_header_rec.attribute11             := iot_order_tbl(ln_shori_count).performance_management_dept;                 -- ���ъǗ�����
      lt_header_rec.attribute12             := TO_CHAR(iot_order_tbl(ln_shori_count).schedule_arrival_date,'YYYY/MM/DD'); -- ���ח\���
      -- ***************************************
      -- ***       A6-�󒍍쐬API�N��        ***
      -- ***************************************
--
      OE_ORDER_PUB.PROCESS_ORDER(
        p_api_version_number      => 1.0
      , x_return_status           => lv_return_status
      , x_msg_count               => ln_msg_count
      , x_msg_data                => lv_msg_data
      , p_header_rec              => lt_header_rec
      , p_line_tbl                => lt_line_tbl
      , p_action_request_tbl      => lt_action_request_tbl
      , x_header_rec              => lt_header_rec
      , x_header_val_rec          => lt_header_val_rec
      , x_header_adj_tbl          => lt_header_adj_tbl
      , x_header_adj_val_tbl      => lt_header_adj_val_tbl
      , x_header_price_att_tbl    => lt_header_price_att_tbl
      , x_header_adj_att_tbl      => lt_header_adj_att_tbl
      , x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl
      , x_header_scredit_tbl      => lt_header_scredit_tbl
      , x_header_scredit_val_tbl  => lt_header_scredit_val_tbl
      , x_line_tbl                => lt_line_tbl
      , x_line_val_tbl            => lt_line_val_tbl
      , x_line_adj_tbl            => lt_line_adj_tbl
      , x_line_adj_val_tbl        => lt_line_adj_val_tbl
      , x_line_price_att_tbl      => lt_line_price_att_tbl
      , x_line_adj_att_tbl        => lt_line_adj_att_tbl
      , x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl
      , x_line_scredit_tbl        => lt_line_scredit_tbl
      , x_line_scredit_val_tbl    => lt_line_scredit_val_tbl
      , x_lot_serial_tbl          => lt_lot_serial_tbl
      , x_lot_serial_val_tbl      => lt_lot_serial_val_tbl
      , x_action_request_tbl      => lt_action_request_tbl
      );
--
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
--
        IF (ln_msg_count > 0 ) THEN
          -- ���b�Z�[�W������0���傫���ꍇ�G���[���b�Z�[�W���o��
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            lv_msg_buf := OE_MSG_PUB.GET(p_msg_index => cnt, 
                                         p_encoded   => 'F');
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
        END IF;
--
        --���b�Z�[�W���o�͂������������I������
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_016,
                                              gv_tkn_api_name,
                                              gv_api_name_3,
                                              gv_tkn_error_msg,
                                              lv_msg_data,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        RAISE global_api_expt;
      END IF;
--
      ot_new_header_id := lt_header_rec.header_id;       -- �󒍃w�b�_ID
--
      IF (gv_shori_kbn IN ('1','3') ) THEN
        -- �󒍃w�b�_ID�X�V�p�̃f�[�^�ɓo�^����
        gt_header_id := lt_header_rec.header_id;       -- �󒍃w�b�_ID
      END IF;
--
    ELSE
      ov_standard_api_flag := '0';--�W��API���s�t���O��0(���s���Ȃ�)���Z�b�g
    END IF;
--
    ot_new_order_header_id := iot_order_tbl(ln_shori_count).order_header_id; -- �󒍃w�b�_�A�h�I��ID
--
    IF (gv_shori_kbn = '4') THEN
      --�����ԕi�Ŏ󒍃w�b�_�o�^�ȑO�̏ꍇ�󒍃w�b�_�A�h�I���Ƀf�[�^��o�^
      SELECT xxwsh_order_headers_all_s1.NEXTVAL
      INTO   lt_new_order_header_id
      FROM   dual;
--
      ot_new_order_header_id       := lt_new_order_header_id;
--
      INSERT INTO xxwsh_order_headers_all
        (order_header_id,             -- �󒍃w�b�_�A�h�I��ID
         order_type_id,               -- �󒍃^�C�vID
         organization_id,             -- �g�DID
         header_id,                   -- �󒍃w�b�_ID
         latest_external_flag,        -- �ŐV�t���O
         ordered_date,                -- �󒍓�
         customer_id,                 -- �ڋqID
         customer_code,               -- �ڋq
         deliver_to_id,               -- �o�א�ID
         deliver_to,                  -- �o�א�
         shipping_instructions,       -- �o�׎w��
         career_id,                   -- �^���Ǝ�ID
         freight_carrier_code,        -- �^���Ǝ�
         shipping_method_code,        -- �z���敪
         cust_po_number,              -- �ڋq����
         price_list_id,               -- ���i�\
         request_no,                  -- �˗�No
         req_status,                  -- �X�e�[�^�X
         delivery_no,                 -- �z��No
         prev_delivery_no,            -- �O��z��No
         schedule_ship_date,          -- �o�ח\���
         schedule_arrival_date,       -- ���ח\���
         mixed_no,                    -- ���ڌ�No
         collected_pallet_qty,        -- �p���b�g�������
         confirm_request_class,       -- �����S���m�F�˗��敪
         freight_charge_class,        -- �^���敪
         shikyu_instruction_class,    -- �x���o�Ɏw���敪
         shikyu_inst_rcv_class,       -- �x���w����̋敪
         amount_fix_class,            -- �L�����z�m��敪
         takeback_class,              -- ����敪
         deliver_from_id,             -- �o�׌�ID
         deliver_from,                -- �o�׌��ۊǏꏊ
         head_sales_branch,           -- �Ǌ����_
         input_sales_branch,          -- ���͋��_
         po_no,                       -- ����No
         prod_class,                  -- ���i�敪
         item_class,                  -- �i�ڋ敪
         no_cont_freight_class,       -- �_��O�^���敪
         arrival_time_from,           -- ���׎���FROM
         arrival_time_to,             -- ���׎���TO
         designated_item_id,          -- �����i��ID
         designated_item_code,        -- �����i��
         designated_production_date,  -- ������
         designated_branch_no,        -- �����}��
         slip_number,                 -- �����No
         sum_quantity,                -- ���v����
         small_quantity,              -- ������
         label_quantity,              -- ���x������
         loading_efficiency_weight,   -- �d�ʐύڌ���
         loading_efficiency_capacity, -- �e�ϐύڌ���
         based_weight,                -- ��{�d��
         based_capacity,              -- ��{�e��
         sum_weight,                  -- �ύڏd�ʍ��v
         sum_capacity,                -- �ύڗe�ύ��v
         mixed_ratio,                 -- ���ڗ�
         pallet_sum_quantity,         -- �p���b�g���v����
         real_pallet_quantity,        -- �p���b�g���і���
         sum_pallet_weight,           -- ���v�p���b�g�d��
         order_source_ref,            -- �󒍃\�[�X�Q��
         result_freight_carrier_id,   -- �^���Ǝ�_����ID
         result_freight_carrier_code, -- �^���Ǝ�_����
         result_shipping_method_code, -- �z���敪_����
         result_deliver_to_id,        -- �o�א�_����ID
         result_deliver_to,           -- �o�א�_����
         shipped_date,                -- �o�ד�
         arrival_date,                -- ���ד�
         weight_capacity_class,       -- �d�ʗe�ϋ敪
         actual_confirm_class,        -- ���ьv��ϋ敪
         notif_status,                -- �ʒm�X�e�[�^�X
         prev_notif_status,           -- �O��ʒm�X�e�[�^�X
         notif_date,                  -- �m��ʒm���{����
         new_modify_flg,              -- �V�K�C���t���O
         process_status,              -- �����o�߃X�e�[�^�X
         performance_management_dept, -- ���ъǗ�����
         instruction_dept,            -- �w������
         transfer_location_id,        -- �U�֐�ID
         transfer_location_code,      -- �U�֐�
         mixed_sign,                  -- ���ڋL��
         screen_update_date,          -- ��ʍX�V����
         screen_update_by,            -- ��ʍX�V��
         tightening_date,             -- �o�׈˗����ߓ���
         vendor_id,                   -- �����ID
         vendor_code,                 -- �����
         vendor_site_id,              -- �����T�C�gID
         vendor_site_code,            -- �����T�C�g
         registered_sequence,         -- �o�^����
         tightening_program_id,       -- ���߃R���J�����gID
         corrected_tighten_class,     -- ���ߌ�C���敪
         created_by,                  -- �쐬��
         creation_date,               -- �쐬��
         last_updated_by,             -- �ŏI�X�V��
         last_update_date,            -- �ŏI�X�V��
         last_update_login,           -- �ŏI�X�V���O�C��
         request_id,                  -- �v��ID
         program_application_id,      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         program_id,                  -- �R���J�����g�E�v���O����ID
         program_update_date          -- �v���O�����X�V��
        )VALUES
        (lt_new_order_header_id,
         iot_order_tbl(ln_shori_count).transaction_type_id,
         iot_order_tbl(ln_shori_count).organization_id,
         lt_header_rec.header_id,
         gv_no,
         iot_order_tbl(ln_shori_count).ordered_date,
         iot_order_tbl(ln_shori_count).customer_id,
         iot_order_tbl(ln_shori_count).customer_code,
         iot_order_tbl(ln_shori_count).deliver_to_id,
         iot_order_tbl(ln_shori_count).deliver_to,
         iot_order_tbl(ln_shori_count).shipping_instructions,
         iot_order_tbl(ln_shori_count).career_id,
         iot_order_tbl(ln_shori_count).freight_carrier_code,
         iot_order_tbl(ln_shori_count).shipping_method_code,
         iot_order_tbl(ln_shori_count).cust_po_number,
         iot_order_tbl(ln_shori_count).price_list_id,
         iot_order_tbl(ln_shori_count).request_no,
         iot_order_tbl(ln_shori_count).req_status,
         iot_order_tbl(ln_shori_count).delivery_no,
         iot_order_tbl(ln_shori_count).prev_delivery_no,
         iot_order_tbl(ln_shori_count).schedule_ship_date,
         iot_order_tbl(ln_shori_count).schedule_arrival_date,
         iot_order_tbl(ln_shori_count).mixed_no,
         iot_order_tbl(ln_shori_count).collected_pallet_qty,
         iot_order_tbl(ln_shori_count).confirm_request_class,
         iot_order_tbl(ln_shori_count).freight_charge_class,
         iot_order_tbl(ln_shori_count).shikyu_instruction_class,
         iot_order_tbl(ln_shori_count).shikyu_inst_rcv_class,
         iot_order_tbl(ln_shori_count).amount_fix_class,
         iot_order_tbl(ln_shori_count).takeback_class,
         iot_order_tbl(ln_shori_count).deliver_from_id,
         iot_order_tbl(ln_shori_count).deliver_from,
         iot_order_tbl(ln_shori_count).head_sales_branch,
         iot_order_tbl(ln_shori_count).input_sales_branch,
         iot_order_tbl(ln_shori_count).po_no,
         iot_order_tbl(ln_shori_count).prod_class,
         iot_order_tbl(ln_shori_count).item_class,
         iot_order_tbl(ln_shori_count).no_cont_freight_class,
         iot_order_tbl(ln_shori_count).arrival_time_from,
         iot_order_tbl(ln_shori_count).arrival_time_to,
         iot_order_tbl(ln_shori_count).designated_item_id,
         iot_order_tbl(ln_shori_count).designated_item_code,
         iot_order_tbl(ln_shori_count).designated_production_date,
         iot_order_tbl(ln_shori_count).designated_branch_no,
         iot_order_tbl(ln_shori_count).slip_number,
         iot_order_tbl(ln_shori_count).sum_quantity,
         iot_order_tbl(ln_shori_count).small_quantity,
         iot_order_tbl(ln_shori_count).label_quantity,
         iot_order_tbl(ln_shori_count).loading_efficiency_weight,
         iot_order_tbl(ln_shori_count).loading_efficiency_capacity,
         iot_order_tbl(ln_shori_count).based_weight,
         iot_order_tbl(ln_shori_count).based_capacity,
         iot_order_tbl(ln_shori_count).sum_weight,
         iot_order_tbl(ln_shori_count).sum_capacity,
         iot_order_tbl(ln_shori_count).mixed_ratio,
         iot_order_tbl(ln_shori_count).pallet_sum_quantity,
         iot_order_tbl(ln_shori_count).real_pallet_quantity,
         iot_order_tbl(ln_shori_count).sum_pallet_weight,
         iot_order_tbl(ln_shori_count).order_source_ref,
         iot_order_tbl(ln_shori_count).result_freight_carrier_id,
         iot_order_tbl(ln_shori_count).result_freight_carrier_code,
         iot_order_tbl(ln_shori_count).result_shipping_method_code,
         iot_order_tbl(ln_shori_count).result_deliver_to_id,
         iot_order_tbl(ln_shori_count).result_deliver_to,
         iot_order_tbl(ln_shori_count).shipped_date,
         iot_order_tbl(ln_shori_count).arrival_date,
         iot_order_tbl(ln_shori_count).weight_capacity_class,
         gv_yes,
         iot_order_tbl(ln_shori_count).notif_status,
         iot_order_tbl(ln_shori_count).prev_notif_status,
         iot_order_tbl(ln_shori_count).notif_date,
         iot_order_tbl(ln_shori_count).new_modify_flg,
         iot_order_tbl(ln_shori_count).process_status,
         iot_order_tbl(ln_shori_count).performance_management_dept,
         iot_order_tbl(ln_shori_count).instruction_dept,
         iot_order_tbl(ln_shori_count).transfer_location_id,
         iot_order_tbl(ln_shori_count).transfer_location_code,
         iot_order_tbl(ln_shori_count).mixed_sign,
         iot_order_tbl(ln_shori_count).screen_update_date,
         iot_order_tbl(ln_shori_count).screen_update_by,
         iot_order_tbl(ln_shori_count).tightening_date,
         iot_order_tbl(ln_shori_count).vendor_id,
         iot_order_tbl(ln_shori_count).vendor_code,
         iot_order_tbl(ln_shori_count).vendor_site_id,
         iot_order_tbl(ln_shori_count).vendor_site_code,
         iot_order_tbl(ln_shori_count).registered_sequence,
         iot_order_tbl(ln_shori_count).tightening_program_id,
         iot_order_tbl(ln_shori_count).corrected_tighten_class,
         gn_user_id,
         SYSDATE,
         gn_user_id,
         SYSDATE,
         gn_login_id,
         gn_conc_request_id,
         gn_prog_appl_id,
         gn_conc_program_id,
         SYSDATE
      );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END create_order_header_info;
  /***********************************************************************************
   * Procedure Name   : create_order_line_info
   * Description      : A7�󒍖��׃��R�[�h�쐬�AA8�󒍖��דo�^
   ***********************************************************************************/
  PROCEDURE create_order_line_info(
    it_bef_order_header_id
        IN xxwsh_order_headers_all.order_header_id%TYPE, -- �O�����󒍃w�b�_�A�h�I��ID
    it_new_order_header_id
        IN xxwsh_order_headers_all.order_header_id%TYPE, -- �ԗp�V�󒍃w�b�_�A�h�I��ID
    it_new_header_id
        IN xxwsh_order_headers_all.header_id%TYPE,       -- �ԗp�V�󒍃w�b�_ID
    in_gen_count
        IN NUMBER,                                       -- �󒍏��i�[�z��̌��݂̈ʒu
    iot_order_tbl
        IN OUT order_tbl,                                -- �󒍏��i�[�z��
    ot_order_line_tbl
        OUT NOCOPY order_line_type,                      -- �󒍖��׏��i�[�z��
    ot_revised_line_tbl
        OUT NOCOPY revised_line_type,                    -- �����󒍖��׏��i�[�z��
    ov_errbuf
        OUT NOCOPY VARCHAR2,                             -- �G���[�E���b�Z�[�W --# �Œ� #
    ov_retcode
        OUT NOCOPY VARCHAR2,                             -- ���^�[���E�R�[�h --# �Œ� #
    ov_errmsg
        OUT NOCOPY VARCHAR2)                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_order_line_info'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_line_count                 NUMBER;                               -- ���׌���
    lv_return_status              VARCHAR2(1) ;                         -- API�̏����X�e�[�^�X
    ln_msg_count                  NUMBER;                               -- API�̃G���[���b�Z�[�W����
    lv_msg_data                   VARCHAR2(2000) ;                      -- API�̃G���[���b�Z�[�W
    lv_msg_buf                    VARCHAR2(2000);                       -- API���b�Z�[�W�����p
    ln_shori_count                NUMBER;                               -- �󒍏��̏�������
    lt_input_line_id              oe_order_lines_all.line_id%TYPE;      -- �o�^�p�󒍖���ID
    ln_order_line_count           NUMBER;                               -- �󒍖��דo�^����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    -- *** �A�h�I���o�^�p ***
    lt_order_line_id              ol_order_line_id_type;                -- �󒍖��׃A�h�I��ID
    lt_order_header_id            ol_order_header_id_type;              -- �󒍃w�b�_�A�h�I��ID
    lt_order_line_number          ol_order_line_number_type;            -- ���הԍ�
    lt_header_id                  ol_header_id_type;                    -- �󒍃w�b�_ID
    lt_line_id                    ol_line_id_type;                      -- �󒍖���ID
    lt_request_no                 ol_request_no_type;                   -- �˗�No
    lt_shipping_inventory_item_id ol_ship_inv_item_id_type;             -- �o�וi��ID
    lt_shipping_item_code         ol_ship_item_code_type;               -- �o�וi��
    lt_quantity                   ol_quantity_type;                     -- ����
    lt_uom_code                   ol_uom_code_type;                     -- �P��
    lt_unit_price                 ol_unit_price_type;                   -- �P��
    lt_shippied_quantity          ol_shipped_quantity_type;             -- �o�׎��ѐ���
    lt_designated_production_date ol_desi_prod_date_type;               -- �w�萻����
    lt_based_request_quantity     ol_base_req_quantity_type;            -- ���_�˗�����
    lt_request_item_id            ol_request_item_id_type;              -- �˗��i��ID
    lt_request_item_code          ol_request_item_code_type;            -- �˗��i�ڃR�[�h
    lt_ship_to_quantity           ol_ship_to_quantity_type;             -- ���Ɏ��ѐ���
    lt_futai_code                 ol_futai_code_type;                   -- �t�уR�[�h
    lt_designated_date            ol_designated_date_type;              -- �w����t(���[�t)
    lt_move_number                ol_move_number_type;                  -- �ړ�No
    lt_po_number                  ol_po_number_type;                    -- ����No
    lt_cust_po_number             ol_cust_po_number_type;               -- �ڋq����
    lt_pallet_quantity            ol_pallet_quantity_type;              -- �p���b�g��
    lt_layer_quantity             ol_layer_quantity_type;               -- �i��
    lt_case_quantity              ol_case_quantity_type;                -- �P�[�X��
    lt_weight                     ol_weight_type;                       -- �d��
    lt_capacity                   ol_capacity_type;                     -- �e��
    lt_pallet_qty                 ol_pallet_qty_type;                   -- �p���b�g����
    lt_pallet_weight              ol_pallet_weight_type;                -- �p���b�g�d��
    lt_reserved_quantity          ol_reserved_quantity_type;            -- ������
    lt_automanual_reserve_class   ol_auto_rese_class_type;              -- �����蓮�����敪
    lt_warning_class              ol_warning_class_type;                -- �x���敪
    lt_warning_date               ol_warning_date_type;                 -- �x�����t
    lt_line_description           ol_line_description_type;             -- �E�v
    lt_rm_if_flg                  ol_rm_if_flg_type;                    -- �q�֕ԕiIF�σt���O
    lt_shipping_request_if_flg    ol_ship_requ_if_flg_type;             -- �o�׈˗�IF�σt���O
    lt_shipping_result_if_flg     ol_ship_resu_if_flg_type;             -- �o�׎���IF�σt���O
    -- �󒍖��דo�^�p�z��
    lt_order_line_tbl             OE_ORDER_PUB.LINE_TBL_TYPE;           -- �󒍖��דo�^�p���R�[�h
    lt_header_rec                 OE_ORDER_PUB.HEADER_REC_TYPE;
    lt_header_val_rec             OE_ORDER_PUB.HEADER_VAL_REC_TYPE;
    lt_header_adj_tbl             OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE;
    lt_header_adj_val_tbl         OE_ORDER_PUB.HEADER_ADJ_VAL_TBL_TYPE;
    lt_header_price_att_tbl       OE_ORDER_PUB.HEADER_PRICE_ATT_TBL_TYPE;
    lt_header_adj_att_tbl         OE_ORDER_PUB.HEADER_ADJ_ATT_TBL_TYPE;
    lt_header_adj_assoc_tbl       OE_ORDER_PUB.HEADER_ADJ_ASSOC_TBL_TYPE;
    lt_header_scredit_tbl         OE_ORDER_PUB.HEADER_SCREDIT_TBL_TYPE;
    lt_header_scredit_val_tbl     OE_ORDER_PUB.HEADER_SCREDIT_VAL_TBL_TYPE;
    lt_line_val_tbl               OE_ORDER_PUB.LINE_VAL_TBL_TYPE;
    lt_line_adj_tbl               OE_ORDER_PUB.LINE_ADJ_TBL_TYPE;
    lt_line_adj_val_tbl           OE_ORDER_PUB.LINE_ADJ_VAL_TBL_TYPE;
    lt_line_price_att_tbl         OE_ORDER_PUB.LINE_PRICE_ATT_TBL_TYPE;
    lt_line_adj_att_tbl           OE_ORDER_PUB.LINE_ADJ_ATT_TBL_TYPE;
    lt_line_adj_assoc_tbl         OE_ORDER_PUB.LINE_ADJ_ASSOC_TBL_TYPE;
    lt_line_scredit_tbl           OE_ORDER_PUB.LINE_SCREDIT_TBL_TYPE;
    lt_line_scredit_val_tbl       OE_ORDER_PUB.LINE_SCREDIT_VAL_TBL_TYPE;
    lt_lot_serial_tbl             OE_ORDER_PUB.LOT_SERIAL_TBL_TYPE;
    lt_lot_serial_val_tbl         OE_ORDER_PUB.LOT_SERIAL_VAL_TBL_TYPE;
    lt_action_request_tbl         OE_ORDER_PUB.REQUEST_TBL_TYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    ln_line_count       := 0;             -- ���׌�����������
    ln_order_line_count := 0;
    ln_shori_count := in_gen_count;
    <<order_line_data>> --�󒍍쐬��񃋁[�v����
    LOOP
      IF ((ln_shori_count > iot_order_tbl.LAST)
       OR
          (iot_order_tbl(ln_shori_count).order_header_id <> it_bef_order_header_id)) THEN
        EXIT;
      END IF;
--
      lt_input_line_id := NULL;   -- �Z�b�g�p�󒍖���ID��������
      IF (NVL(iot_order_tbl(ln_shori_count).shipped_quantity,0) <> 0 )THEN
        ln_order_line_count := ln_order_line_count + 1;
        -- �󒍖��דo�^API�p�f�[�^
        lt_order_line_tbl(ln_order_line_count)                      := OE_ORDER_PUB.G_MISS_LINE_REC;                             -- �󒍖��וϐ��̏�����
        SELECT oe_order_lines_s.NEXTVAL
        INTO   lt_order_line_tbl(ln_order_line_count).line_id
        FROM   DUAL;
        lt_input_line_id                                            := lt_order_line_tbl(ln_order_line_count).line_id;
        lt_order_line_tbl(ln_order_line_count).operation            := OE_GLOBALS.G_OPR_CREATE;
        lt_order_line_tbl(ln_order_line_count).header_id            := it_new_header_id;                                         -- �󒍃w�b�_ID
        lt_order_line_tbl(ln_order_line_count).inventory_item_id    := iot_order_tbl(ln_shori_count).shipping_inventory_item_id; -- �o�וi��ID
        lt_order_line_tbl(ln_order_line_count).ordered_quantity     := iot_order_tbl(ln_shori_count).shipped_quantity;           -- �o�׎��ѐ���
        lt_order_line_tbl(ln_order_line_count).unit_selling_price   := NVL(iot_order_tbl(ln_shori_count).unit_price,0);                 -- �P��
        lt_order_line_tbl(ln_order_line_count).unit_list_price      := NVL(iot_order_tbl(ln_shori_count).unit_price,0);                 -- �P��
        lt_order_line_tbl(ln_order_line_count).schedule_ship_date   := iot_order_tbl(ln_shori_count).schedule_ship_date;         -- �o�ח\���
        lt_order_line_tbl(ln_order_line_count).request_date         := SYSDATE;                                                  -- �v����
        lt_order_line_tbl(ln_order_line_count).calculate_price_flag := gv_no;                                                    -- �������i�v�Z�t���O
        lt_order_line_tbl(ln_order_line_count).attribute1           := iot_order_tbl(ln_shori_count).quantity;                   -- ����
        lt_order_line_tbl(ln_order_line_count).attribute2           := iot_order_tbl(ln_shori_count).based_request_quantity;     -- ���_�˗�����
        lt_order_line_tbl(ln_order_line_count).attribute3           := iot_order_tbl(ln_shori_count).request_item_code;          -- �˗��i��
        ot_order_line_tbl(ln_order_line_count).order_line_id        := iot_order_tbl(ln_shori_count).order_line_id;              -- �󒍖��׃A�h�I��ID
        ot_order_line_tbl(ln_order_line_count).line_id              := lt_input_line_id;                                         -- �󒍖���ID
        ot_order_line_tbl(ln_order_line_count).shipped_quantity     := iot_order_tbl(ln_shori_count).shipped_quantity;           -- ���ѐ���
        ot_order_line_tbl(ln_order_line_count).deliver_from         := iot_order_tbl(ln_shori_count).deliver_from;               -- �o�Ɍ��ۊǏꏊ
        ot_order_line_tbl(ln_order_line_count).shipped_date         := iot_order_tbl(ln_shori_count).shipped_date;               -- �o�ד�
        ot_order_line_tbl(ln_order_line_count).uom_code             := iot_order_tbl(ln_shori_count).uom_code;                   -- �P��
        ot_order_line_tbl(ln_order_line_count).lot_ctl              := iot_order_tbl(ln_shori_count).lot_ctl;                    -- ���b�g�Ǘ�
      END IF;
--
      -- ���׌�����+1
      ln_line_count := ln_line_count + 1;
--
      IF (gv_shori_kbn IN ('1','3') ) THEN 
        -- �󒍖���ID�X�V�p�ϐ��ɒl���Z�b�g
        gt_order_line_id(ln_line_count)   := iot_order_tbl(ln_shori_count).order_line_id;                              -- �󒍖��׃A�h�I��ID
        gt_line_id(ln_line_count)         := lt_input_line_id;                                                         -- �󒍖���ID
      END IF;
--
      IF (gv_shori_kbn = '4') THEN 
--
        --�����ԕi�Ŏ󒍖��דo�^�ȑO�̏ꍇ�󒍖��׃A�h�I���o�^�p�f�[�^���쐬
        SELECT xxwsh_order_lines_all_s1.NEXTVAL
        INTO   lt_order_line_id(ln_line_count)
        FROM   dual;
--
        ot_revised_line_tbl(ln_line_count).order_line_id
                                                           := iot_order_tbl(ln_shori_count).order_line_id;
        ot_revised_line_tbl(ln_line_count).new_order_line_id
                                                           := lt_order_line_id(ln_line_count); -- �V�󒍖��׃A�h�I��ID���Z�b�g
        lt_order_header_id(ln_line_count)                  := it_new_order_header_id;
        lt_order_line_number(ln_line_count)                := iot_order_tbl(ln_shori_count).order_line_number;
        lt_header_id(ln_line_count)                        := it_new_header_id;
        lt_line_id(ln_line_count)                          := lt_input_line_id;
        lt_request_no(ln_line_count)                       := iot_order_tbl(ln_shori_count).line_request_no;
        lt_shipping_inventory_item_id(ln_line_count)       := iot_order_tbl(ln_shori_count).shipping_inventory_item_id;
        lt_shipping_item_code(ln_line_count)               := iot_order_tbl(ln_shori_count).shipping_item_code;
        lt_quantity(ln_line_count)                         := iot_order_tbl(ln_shori_count).quantity;
        lt_uom_code(ln_line_count)                         := iot_order_tbl(ln_shori_count).uom_code;
        lt_unit_price(ln_line_count)                       := iot_order_tbl(ln_shori_count).unit_price;
        lt_shippied_quantity(ln_line_count)                := iot_order_tbl(ln_shori_count).shipped_quantity;
        lt_designated_production_date(ln_line_count)       := iot_order_tbl(ln_shori_count).line_designated_prod_date;
        lt_based_request_quantity(ln_line_count)           := iot_order_tbl(ln_shori_count).based_request_quantity;
        lt_request_item_id(ln_line_count)                  := iot_order_tbl(ln_shori_count).request_item_id;
        lt_request_item_code(ln_line_count)                := iot_order_tbl(ln_shori_count).request_item_code;
        lt_ship_to_quantity(ln_line_count)                 := iot_order_tbl(ln_shori_count).ship_to_quantity;
        lt_futai_code(ln_line_count)                       := iot_order_tbl(ln_shori_count).futai_code;
        lt_designated_date(ln_line_count)                  := iot_order_tbl(ln_shori_count).designated_date;
        lt_move_number(ln_line_count)                      := iot_order_tbl(ln_shori_count).move_number;
        lt_po_number(ln_line_count)                        := iot_order_tbl(ln_shori_count).po_number;
        lt_cust_po_number(ln_line_count)                   := iot_order_tbl(ln_shori_count).line_cust_po_number;
        lt_pallet_quantity(ln_line_count)                  := iot_order_tbl(ln_shori_count).pallet_quantity;
        lt_layer_quantity(ln_line_count)                   := iot_order_tbl(ln_shori_count).layer_quantity;
        lt_case_quantity(ln_line_count)                    := iot_order_tbl(ln_shori_count).case_quantity;
        lt_weight(ln_line_count)                           := iot_order_tbl(ln_shori_count).weight;
        lt_capacity(ln_line_count)                         := iot_order_tbl(ln_shori_count).capacity;
        lt_pallet_qty(ln_line_count)                       := iot_order_tbl(ln_shori_count).pallet_qty;
        lt_pallet_weight(ln_line_count)                    := iot_order_tbl(ln_shori_count).pallet_weight;
        lt_reserved_quantity(ln_line_count)                := iot_order_tbl(ln_shori_count).reserved_quantity;
        lt_automanual_reserve_class(ln_line_count)         := iot_order_tbl(ln_shori_count).automanual_reserve_class;
        lt_warning_class(ln_line_count)                    := iot_order_tbl(ln_shori_count).warning_class;
        lt_warning_date(ln_line_count)                     := iot_order_tbl(ln_shori_count).warning_date;
        lt_line_description(ln_line_count)                 := iot_order_tbl(ln_shori_count).line_description;
        lt_rm_if_flg(ln_line_count)                        := iot_order_tbl(ln_shori_count).rm_if_flg;
        lt_shipping_request_if_flg(ln_line_count)          := iot_order_tbl(ln_shori_count).shipping_request_if_flg;
        lt_shipping_result_if_flg(ln_line_count)           := iot_order_tbl(ln_shori_count).shipping_result_if_flg;
      END IF;
      -- �󒍃A�h�I�����[�v������+1
      ln_shori_count := ln_shori_count + 1;
    END LOOP order_line_data;
    --A3�Ŏ擾�����f�[�^�̏ꍇ���݂̃��R�[�h�ԍ���Ԃ�
    IF (gv_shori_kbn IN ('1','3') ) THEN
      gn_shori_count := ln_shori_count;
    END IF;
--
    IF (ln_order_line_count > 0) THEN --���בΏی�����0���ȏ�̏ꍇ
      -- ***************************************
      -- ***       A8-�󒍍쐬API�N��        ***
      -- ***************************************
      -- OM���b�Z�[�W���X�g�̏�����
      OE_MSG_PUB.INITIALIZE;
      lt_action_request_tbl(1)                := OE_ORDER_PUB.G_MISS_REQUEST_REC;
      lt_action_request_tbl(1).entity_code    := OE_GLOBALS.G_ENTITY_HEADER;
      lt_action_request_tbl(1).entity_id      := it_new_header_id;
      lt_action_request_tbl(1).request_type   := OE_GLOBALS.G_BOOK_ORDER;
      OE_ORDER_PUB.PROCESS_ORDER(
        p_api_version_number      => 1.0
      , x_return_status           => lv_return_status
      , x_msg_count               => ln_msg_count
      , x_msg_data                => lv_msg_data
      , p_header_rec              => lt_header_rec
      , p_line_tbl                => lt_order_line_tbl
      , p_action_request_tbl      => lt_action_request_tbl
      , x_header_rec              => lt_header_rec
      , x_header_val_rec          => lt_header_val_rec
      , x_header_adj_tbl          => lt_header_adj_tbl
      , x_header_adj_val_tbl      => lt_header_adj_val_tbl
      , x_header_price_att_tbl    => lt_header_price_att_tbl
      , x_header_adj_att_tbl      => lt_header_adj_att_tbl
      , x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl
      , x_header_scredit_tbl      => lt_header_scredit_tbl
      , x_header_scredit_val_tbl  => lt_header_scredit_val_tbl
      , x_line_tbl                => lt_order_line_tbl
      , x_line_val_tbl            => lt_line_val_tbl
      , x_line_adj_tbl            => lt_line_adj_tbl
      , x_line_adj_val_tbl        => lt_line_adj_val_tbl
      , x_line_price_att_tbl      => lt_line_price_att_tbl
      , x_line_adj_att_tbl        => lt_line_adj_att_tbl
      , x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl
      , x_line_scredit_tbl        => lt_line_scredit_tbl
      , x_line_scredit_val_tbl    => lt_line_scredit_val_tbl
      , x_lot_serial_tbl          => lt_lot_serial_tbl
      , x_lot_serial_val_tbl      => lt_lot_serial_val_tbl
      , x_action_request_tbl      => lt_action_request_tbl
      );
--
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        IF (ln_msg_count > 0 ) THEN
          -- ���b�Z�[�W������0���傫���ꍇ�G���[���b�Z�[�W���o��
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            lv_msg_buf := OE_MSG_PUB.GET(p_msg_index => cnt, 
                                         p_encoded   => 'F');
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
        END IF;
  --
        --���b�Z�[�W���o�͂������������I������
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_016,
                                              gv_tkn_api_name,
                                              gv_api_name_3,
                                              gv_tkn_error_msg,
                                              lv_msg_data,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        RAISE global_api_expt;
      END IF;
    END IF;
    IF (gv_shori_kbn = '4') THEN
      -- ********************************************************
      -- ***      �����ԕi���󒍖��׃A�h�I���ɒ����f�[�^��o�^***
      -- ********************************************************
      FORALL i IN 1..lt_order_line_id.COUNT
        INSERT INTO xxwsh_order_lines_all
          (order_line_id,
           order_header_id,
           order_line_number,
           header_id,
           line_id,
           request_no,
           shipping_inventory_item_id,
           shipping_item_code,
           quantity,
           uom_code,
           unit_price,
           shipped_quantity,
           designated_production_date,
           based_request_quantity,
           request_item_id,
           request_item_code,
           ship_to_quantity,
           futai_code,
           designated_date,
           move_number,
           po_number,
           cust_po_number,
           pallet_quantity,
           layer_quantity,
           case_quantity,
           weight,
           capacity,
           pallet_qty,
           pallet_weight,
           reserved_quantity,
           automanual_reserve_class,
           delete_flag,
           warning_class,
           warning_date,
           line_description,
           rm_if_flg,
           shipping_request_if_flg,
           shipping_result_if_flg,
           created_by,
           creation_date,
           last_updated_by,
           last_update_date,
           last_update_login,
           request_id,
           program_application_id,
           program_id,
           program_update_date)
        VALUES (
           lt_order_line_id(i),              -- �󒍖��׃A�h�I��ID
           lt_order_header_id(i),            -- �󒍃w�b�_�A�h�I��ID
           lt_order_line_number(i),          -- ���הԍ�
           lt_header_id(i),                  -- �󒍃w�b�_ID
           lt_line_id(i),                    -- �󒍖���ID
           lt_request_no(i),                 -- �˗�No
           lt_shipping_inventory_item_id(i), -- �o�וi��ID
           lt_shipping_item_code(i),         -- �o�וi��
           lt_quantity(i),                   -- ����
           lt_uom_code(i),                   -- �P��
           lt_unit_price(i),                 -- �P��
           lt_shippied_quantity(i),          -- �o�׎��ѐ���
           lt_designated_production_date(i), -- �w�萻����
           lt_based_request_quantity(i),     -- ���_�˗�����
           lt_request_item_id(i),            -- �˗��i��ID
           lt_request_item_code(i),          -- �˗��i�ڃR�[�h
           lt_ship_to_quantity(i),           -- ���Ɏ��ѐ���
           lt_futai_code(i),                 -- �t�уR�[�h
           lt_designated_date(i),            -- �w����t(���[�t)
           lt_move_number(i),                -- �ړ�No
           lt_po_number(i),                  -- ����No
           lt_cust_po_number(i),             -- �ڋq����
           lt_pallet_quantity(i),            -- �p���b�g��
           lt_layer_quantity(i),             -- �i��
           lt_case_quantity(i),              -- �P�[�X��
           lt_weight(i),                     -- �d��
           lt_capacity(i),                   -- �e��
           lt_pallet_qty(i),                 -- �p���b�g����
           lt_pallet_weight(i),              -- �p���b�g�d��
           lt_reserved_quantity(i),          -- ������
           lt_automanual_reserve_class(i),   -- �����蓮�����敪
           'N',                              -- �폜�t���O
           lt_warning_class(i),              -- �x���敪
           lt_warning_date(i),               -- �x�����t
           lt_line_description(i),           -- �E�v
           lt_rm_if_flg(i),                  -- �q�֕ԕi�C���^�t�F�[�X�σt���O
           lt_shipping_request_if_flg(i),    -- �o�׈˗��C���^�t�F�[�X�σt���O
           lt_shipping_result_if_flg(i),     -- �o�׎��уC���^�t�F�[�X�σt���O
           gn_user_id,                       -- �쐬��
           SYSDATE,                          -- �쐬��
           gn_user_id,                       -- �ŏI�X�V��
           SYSDATE,                          -- �ŏI�X�V��
           gn_login_id,                      -- �ŏI�X�V���O�C��
           gn_conc_request_id,               -- �v��ID
           gn_prog_appl_id,                  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           gn_conc_program_id,               -- �R���J�����g�E�v���O����ID
           SYSDATE                           -- �v���O�����X�V��
      );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END create_order_line_info;
  /***********************************************************************************
   * Procedure Name   : delivery_action_proc
   * Description      : A9�s�b�N�����[�XAPI�N��
   ***********************************************************************************/
  PROCEDURE delivery_action_proc(
    it_header_id    IN xxwsh_order_headers_all.header_id%TYPE, -- �󒍃w�b�_ID
    ot_del_rows_tbl OUT NOCOPY WSH_UTIL_CORE.ID_TAB_TYPE,      -- ����ID Table
    ov_errbuf       OUT NOCOPY VARCHAR2,                       -- �G���[�E���b�Z�[�W--# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,                       -- ���^�[���E�R�[�h--# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)                       -- ���[�U�[�G���[���b�Z�[�W--# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delivery_action_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    cv_release_mode                   CONSTANT VARCHAR2(15) := 'ONLINE';    -- �s�b�N�����[�X���s�p�����[�^
    -- *** ���[�J���ϐ� ***
--
    lv_return_status                  VARCHAR2(1);                          -- API�̏����X�e�[�^�X
    ln_msg_count                      NUMBER;                               -- API�̃G���[���b�Z�[�W����
    lv_msg_data                       VARCHAR2(2000);                       -- API�̃G���[���b�Z�[�W
    lv_msg_buf                        VARCHAR2(2000);                       -- API���b�Z�[�W�����p
    ln_msg_index_out                  NUMBER;                               -- API�̃G���[���b�Z�[�W(INDEX)
    ln_count                          NUMBER;                               -- �����J�E���g�p
    ln_batch_id                       NUMBER;                               -- �p�b�`ID
    ln_request_id                     NUMBER;                               -- ���N�G�X�gID
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lt_batch_info_rec                 WSH_PICKING_BATCHES_PUB.BATCH_INFO_REC;  -- �s�b�N�����[�X�p
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- *********************************************
    -- ***       A9�s�b�N�����[�X�p�b�`�쐬      ***
    -- *********************************************
    lt_batch_info_rec.order_header_id := it_header_id; -- �󒍃w�b�_ID���w��
    WSH_PICKING_BATCHES_PUB.CREATE_BATCH(
      p_api_version         => 1.0
    , p_init_msg_list       => FND_API.G_TRUE
    , x_return_status       => lv_return_status
    , x_msg_count           => ln_msg_count
    , x_msg_data            => lv_msg_data
    , p_batch_rec           => lt_batch_info_rec
    , x_batch_id            => ln_batch_id
    );
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN -- �G���[�̏ꍇ
      IF (ln_msg_count > 0 ) THEN
        -- ���b�Z�[�W������0���傫���ꍇ�G���[���b�Z�[�W���o��
        <<message_loop>>
        FOR cnt IN 1..ln_msg_count LOOP
          FND_MSG_PUB.GET( 
            p_msg_index      => cnt ,
            p_encoded        => 'F' ,
            p_data           => lv_msg_buf , 
            p_msg_index_out  => ln_msg_index_out
          );
          lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
        END LOOP message_loop;
      END IF;    
      --���b�Z�[�W���o�͂������������I������
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                            gv_msg_42a_016,
                                            gv_tkn_api_name,
                                            gv_api_name_2,
                                            gv_tkn_error_msg,
                                            lv_msg_data,
                                            gv_tkn_request_no,
                                            gt_gen_request_no
      );
      RAISE global_api_expt;
    END IF;
    -- *********************************************
    -- ***       A9�s�b�N�����[�X�p�b�`���s      ***
    -- *********************************************
    WSH_PICKING_BATCHES_PUB.RELEASE_BATCH(
      p_api_version         => 1.0
    , p_init_msg_list       => FND_API.G_TRUE
    , x_return_status       => lv_return_status
    , x_msg_count           => ln_msg_count
    , x_msg_data            => lv_msg_data
    , p_batch_id            => ln_batch_id
    , p_release_mode        => cv_release_mode
    , x_request_id          => ln_request_id
    );
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN -- �G���[�̏ꍇ
      IF (ln_msg_count > 0 ) THEN
        -- ���b�Z�[�W������0���傫���ꍇ�G���[���b�Z�[�W���o��
        <<message_loop>>
        FOR cnt2 IN 1..ln_msg_count LOOP
          FND_MSG_PUB.GET( 
            p_msg_index      => cnt2 ,
            p_encoded        => 'F' ,
            p_data           => lv_msg_buf , 
            p_msg_index_out  => ln_msg_index_out
          );
          lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
        END LOOP message_loop;
      END IF;    
      --���b�Z�[�W���o�͂������������I������
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                            gv_msg_42a_016,
                                            gv_tkn_api_name,
                                            gv_api_name_6,
                                            gv_tkn_error_msg,
                                            lv_msg_data,
                                            gv_tkn_request_no,
                                            gt_gen_request_no
      );
      RAISE global_api_expt;
    END IF;
    -- ����ID�̎擾
    SELECT wda.delivery_id
    INTO   ot_del_rows_tbl(1)
    FROM   wsh_delivery_details wdd,
           wsh_delivery_assignments wda
    WHERE  wdd.org_id = gn_org_id
    AND    wdd.batch_id = ln_batch_id
    AND    wdd.delivery_detail_id = wda.delivery_detail_id
    AND    ROWNUM = 1;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END delivery_action_proc;
  /***********************************************************************************
   * Procedure Name   : get_lot_details
   * Description      : A10���b�g���擾
   ***********************************************************************************/
  PROCEDURE get_lot_details(
    it_order_line_tbl    IN order_line_type,          -- �󒍖��׏��i�[�z��
    it_revised_line_tbl  IN revised_line_type,        -- �����󒍖��׏��i�[�z��
    iv_standard_api_flag IN VARCHAR2,                 -- �W��API���s�t���O
    ot_ic_tran_rec_tbl   OUT NOCOPY ic_tran_rec_type, -- �݌Ɋ���API�p�f�[�^�ꎞ�ۑ��p�z��
    ot_mov_line_id_tbl   OUT NOCOPY mov_line_id_type, -- �ړ�����ID�f�[�^�ꎞ�ۑ��p�z��
    ov_errbuf            OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lot_details'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    cv_action_code_ins    CONSTANT VARCHAR2(6) := 'INSERT';
    -- *** ���[�J���ϐ� ***
    ln_count              NUMBER;                                -- �݌Ɋ���API�p�f�[�^�ꎞ�ۑ��pCOUNT
    ln_mov_count          NUMBER;                                -- �ړ�����ID�ꎞ�ۑ��pCOUNT
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_move_lot_details(
           pt_order_line_id xxwsh_order_lines_all.order_line_id%TYPE
    ) IS SELECT xmld.document_type_code,      -- �����^�C�v
                xmld.record_type_code,        -- ���R�[�h�^�C�v
                xmld.item_id,                 -- OPM�i��ID
                xmld.item_code,               -- �i��
                xmld.lot_no,                  -- ���b�gNo
                xmld.lot_id,                  -- ���b�gID
                xmld.actual_date,             -- ���ѓ�
                xmld.actual_quantity,         -- ���ѐ���
                xmld.automanual_reserve_class -- �����蓮�����敪
         FROM   xxinv_mov_lot_details xmld    -- �ړ����b�g�ڍ�(�A�h�I��)
         WHERE  xmld.mov_line_id = pt_order_line_id
         AND    xmld.document_type_code IN (gv_document_type_10,gv_document_type_30)
         AND    xmld.record_type_code = gv_record_type_20
         AND    xmld.actual_quantity <> 0;
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_revised_lot_details(
           pt_order_line_id xxwsh_order_lines_all.order_line_id%TYPE
    ) IS SELECT xmld.document_type_code,      -- �����^�C�v
                xmld.record_type_code,        -- ���R�[�h�^�C�v
                xmld.item_id,                 -- OPM�i��ID
                xmld.item_code,               -- �i��
                xmld.lot_no,                  -- ���b�gNo
                xmld.lot_id,                  -- ���b�gID
                xmld.actual_date,             -- ���ѓ�
                xmld.actual_quantity,         -- ���ѐ���
                xmld.automanual_reserve_class -- �����蓮�����敪
         FROM   xxinv_mov_lot_details xmld    -- �ړ����b�g�ڍ�(�A�h�I��)
         WHERE  xmld.mov_line_id = pt_order_line_id
         AND    xmld.document_type_code IN (gv_document_type_10,gv_document_type_30)
         AND    xmld.record_type_code = gv_record_type_20;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- *********************************************
    -- ***       ���ׂ��ƂɃ��b�g�����擾      ***
    -- *********************************************
--
    ln_count     := 0;
    ln_mov_count := 0;
--
    IF (iv_standard_api_flag = '1') THEN
      <<order_line_data>>
      FOR i IN 1..it_order_line_tbl.COUNT LOOP  -- ���ׂ̌������[�v
--
        <<move_lot_details_data>>
        FOR rec_move_lot_details IN cur_move_lot_details(it_order_line_tbl(i).order_line_id) LOOP
--
          ln_count := ln_count + 1;
--
          ot_ic_tran_rec_tbl(ln_count).action_code   := cv_action_code_ins;                  -- �\�񓮍�R�[�h;
          ot_ic_tran_rec_tbl(ln_count).line_id       := it_order_line_tbl(i).line_id;        -- �󒍖���ID
          ot_ic_tran_rec_tbl(ln_count).lot_id        := rec_move_lot_details.lot_id;         -- ���b�gID
          ot_ic_tran_rec_tbl(ln_count).trans_qty     := rec_move_lot_details.actual_quantity;-- ���ѐ���
          ot_ic_tran_rec_tbl(ln_count).location      := it_order_line_tbl(i).deliver_from;   -- �o�Ɍ��ۊǏꏊ
          ot_ic_tran_rec_tbl(ln_count).trans_um      := it_order_line_tbl(i).uom_code;       -- �P��
        END LOOP move_lot_details_data;
--
        -- �ړ�����ID�擾
        ln_mov_count := ln_mov_count + 1;
        SELECT wdv.move_order_line_id
        INTO   ot_mov_line_id_tbl(ln_mov_count)
        FROM   wsh_deliverables_v wdv
        WHERE  wdv.org_id = gn_org_id
        AND    wdv.source_line_id = it_order_line_tbl(i).line_id;
--
      END LOOP order_line_data;
    END IF;
--
    IF (gv_shori_kbn = '4') THEN
--
    -- �����敪�������󒍂̏ꍇ�ԕi�p�ړ����b�g�ڍדo�^�f�[�^���쐬����
      <<revised_line_data>>
      FOR cnt IN 1..it_revised_line_tbl.COUNT LOOP  --���ׂ̌������[�v
        <<revised_lot_details_data>>
        FOR revised_lot_details IN cur_revised_lot_details(it_revised_line_tbl(cnt).order_line_id) LOOP
          -- �����敪�������ԕi�̏ꍇ�ԕi�p�ړ����b�g�ڍדo�^�f�[�^���쐬����
          gn_lot_count                              := gn_lot_count +1;
--
          SELECT xxinv_mov_lot_s1.NEXTVAL  --���b�g�ڍ�ID
          INTO   gt_mov_lot_dtl_id(gn_lot_count)
          FROM   dual;
--
          gt_mov_line_id(gn_lot_count)              := it_revised_line_tbl(cnt).new_order_line_id;   -- ����ID
          gt_document_type_code(gn_lot_count)       := revised_lot_details.document_type_code;       -- �����^�C�v
          gt_record_type_code(gn_lot_count)         := revised_lot_details.record_type_code;         -- ���R�[�h�^�C�v
          gt_item_id(gn_lot_count)                  := revised_lot_details.item_id;                  -- OPM�i��ID
          gt_item_code(gn_lot_count)                := revised_lot_details.item_code;                -- �i��
          gt_lot_id(gn_lot_count)                   := revised_lot_details.lot_id;                   -- ���b�gID
          gt_lot_no(gn_lot_count)                   := revised_lot_details.lot_no;                   -- ���b�gNo
          gt_actual_date(gn_lot_count)              := revised_lot_details.actual_date;              -- ���ѓ�
          gt_actual_quantity(gn_lot_count)          := revised_lot_details.actual_quantity;          -- ���ѐ���
          gt_automanual_reserve_class(gn_lot_count) := revised_lot_details.automanual_reserve_class; -- �����蓮�����敪
        END LOOP revised_lot_details_data;
--
      END LOOP revised_line_data;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_lot_details;
  /***********************************************************************************
   * Procedure Name   : set_allocate_opm_order
   * Description      : A11 �݌Ɋ���API�N��
   ***********************************************************************************/
  PROCEDURE set_allocate_opm_order(
    it_ic_tran_rec_tbl IN  ic_tran_rec_type,        -- �݌Ɋ���API�p�f�[�^�ꎞ�ۑ��p�z��
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_allocate_opm_order'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_return_status      VARCHAR2(1);                           -- API�̏����X�e�[�^�X
    ln_msg_count          NUMBER;                                -- API�̃G���[���b�Z�[�W����
    lv_msg_data           VARCHAR2(2000);                        -- API�̃G���[���b�Z�[�W
    lv_msg_buf            VARCHAR2(2000);                        -- API�̃G���[���b�Z�[�W(BUF)
    ln_msg_index_out      NUMBER;                                -- API�̃G���[���b�Z�[�W(INDEX)
--
    -- *** ���[�J���E���R�[�h ***
    lt_ic_tran_rec_type   GMI_OM_ALLOC_API_PUB.IC_TRAN_REC_TYPE; -- �݌Ɋ���API�p�Z�b�g�ϐ�
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- *********************************************
    -- ***     �݌Ɋ���API�N��                   ***
    -- *********************************************
    <<allocate_opm_orders>>
    FOR om_cnt IN 1..it_ic_tran_rec_tbl.COUNT LOOP
      ln_msg_count := 0; --���b�Z�[�W������0�ɏ�����
      --�z��Ńp�����[�^��n���Ȃ����߂��ꂼ��l���Z�b�g
--
      lt_ic_tran_rec_type.action_code := it_ic_tran_rec_tbl(om_cnt).action_code; -- �\�񓮍�R�[�h
      lt_ic_tran_rec_type.line_id     := it_ic_tran_rec_tbl(om_cnt).line_id;     -- �󒍖���ID
      lt_ic_tran_rec_type.lot_id      := it_ic_tran_rec_tbl(om_cnt).lot_id;      -- ���b�gID
      lt_ic_tran_rec_type.trans_qty   := it_ic_tran_rec_tbl(om_cnt).trans_qty;   -- ���ѐ���
      lt_ic_tran_rec_type.location    := it_ic_tran_rec_tbl(om_cnt).location;    -- �o�Ɍ��ۊǏꏊ
      lt_ic_tran_rec_type.trans_um    := it_ic_tran_rec_tbl(om_cnt).trans_um;    -- �P��
--
      GMI_OM_ALLOC_API_PUB.ALLOCATE_OPM_ORDERS (
          p_api_version         => 1.0
        , p_init_msg_list       => FND_API.G_TRUE
        , p_commit              => FND_API.G_FALSE
        , p_tran_rec            => lt_ic_tran_rec_type
        , x_return_status       => lv_return_status
        , x_msg_count           => ln_msg_count
        , x_msg_data            => lv_msg_data
      );
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        IF (ln_msg_count > 0 ) THEN
          -- ���b�Z�[�W������0���傫���ꍇ�G���[���b�Z�[�W���o��
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            FND_MSG_PUB.GET( 
              p_msg_index      => cnt ,
              p_encoded        => 'F' ,
              p_data           => lv_msg_buf , 
              p_msg_index_out  => ln_msg_index_out
            );
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
        END IF;
        --���b�Z�[�W���o�͂������������I������
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_016,
                                              gv_tkn_api_name,
                                              gv_api_name_1,
                                              gv_tkn_error_msg,
                                              lv_msg_data,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        RAISE global_api_expt;
      END IF;
    END LOOP allocate_opm_orders;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END set_allocate_opm_order;
  /***********************************************************************************
   * Procedure Name   : pick_confirm_proc
   * Description      : �ړ��I�[�_�������
   ***********************************************************************************/
  PROCEDURE pick_confirm_proc(
    it_mov_line_id_tbl IN  mov_line_id_type,        -- �ړ�����ID�f�[�^�ꎞ�ۑ��p�z��
    ov_errbuf          OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'pick_confirm_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_return_status      VARCHAR2(1);        -- API�̏����X�e�[�^�X
    ln_msg_count          NUMBER;             -- API�̃G���[���b�Z�[�W����
    lv_msg_data           VARCHAR2(2000);     -- API�̃G���[���b�Z�[�W
    lv_msg_buf            VARCHAR2(2000);     -- API�̃G���[���b�Z�[�W(�o�b�t�@)
    ln_msg_index_out      NUMBER;             -- API�̃G���[���b�Z�[�W�C���f�b�N�X
    lt_mov_line_id        NUMBER;             -- �ړ�����ID
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- *********************************************
    -- ***     �ړ��I�[�_�������                ***
    -- *********************************************
    <<pick_confirm>>
    FOR pick_cnt IN 1..it_mov_line_id_tbl.COUNT LOOP
      ln_msg_count := 0; --���b�Z�[�W������0�ɏ�����
--
      lt_mov_line_id := it_mov_line_id_tbl(pick_cnt);
--
      GMI_PICK_CONFIRM_PUB.PICK_CONFIRM (
          p_api_version         => 1.0
        , p_init_msg_list       => FND_API.G_TRUE
        , p_commit              => FND_API.G_FALSE
        , p_mo_line_id          => lt_mov_line_id
        , p_delivery_detail_id  => NULL
        , p_bk_ordr_if_no_alloc => gv_yes
        , x_return_status       => lv_return_status
        , x_msg_count           => ln_msg_count
        , x_msg_data            => lv_msg_data
      );
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        IF (ln_msg_count > 0 ) THEN
          -- ���b�Z�[�W������0���傫���ꍇ�G���[���b�Z�[�W���o��
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            FND_MSG_PUB.GET( 
              p_msg_index      => cnt ,
              p_encoded        => 'F' ,
              p_data           => lv_msg_buf , 
              p_msg_index_out  => ln_msg_index_out
            );
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
        END IF;
        --���b�Z�[�W���o�͂������������I������
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_016,
                                              gv_tkn_api_name,
                                              gv_api_name_4,
                                              gv_tkn_error_msg,
                                              lv_msg_data,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        RAISE global_api_expt;
      END IF;
    END LOOP pick_confirm;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END pick_confirm_proc;
  /***********************************************************************************
   * Procedure Name   : confirm_proc
   * Description      : A12�o�׊m�FAPI�N��
   ***********************************************************************************/
  PROCEDURE confirm_proc(
    it_del_rows_tbl IN  WSH_UTIL_CORE.ID_TAB_TYPE,                -- ����ID Table
    it_shipped_date IN xxwsh_order_headers_all.shipped_date%TYPE, -- �o�ד�
    ov_errbuf       OUT NOCOPY VARCHAR2,                          -- �G���[�E���b�Z�[�W
    ov_retcode      OUT NOCOPY VARCHAR2,                          -- ���^�[���E�R�[�h
    ov_errmsg       OUT NOCOPY VARCHAR2)                          -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'confirm_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_action_code CONSTANT VARCHAR2(15) := 'CONFIRM';   -- �o�׊m�F�p�����[�^
    cv_action_flag CONSTANT VARCHAR2(15) := 'S';         -- �S�ďo��
--
    -- *** ���[�J���ϐ� ***
--
    lv_return_status              VARCHAR2(1);           -- API�̏����X�e�[�^�X
    ln_msg_count                  NUMBER;                -- API�̃G���[���b�Z�[�W����
    lv_msg_data                   VARCHAR2(2000);        -- API�̃G���[���b�Z�[�W
    lv_msg_buf                    VARCHAR2(2000);        -- API���b�Z�[�W�����p
    ln_msg_index_out              NUMBER;                -- API�̃G���[���b�Z�[�W�E�C���f�b�N�X
    lt_trip_name                  wsh_trips.name%TYPE;
    ln_trip_id                    NUMBER;
-- 2008/10/10 H.Itou Add Start �����e�X�g�w�E116
    lv_sc_defer_interface_flag    VARCHAR2(1);           -- �o�׊m�FAPI��IN�p�����[�^.�C���^�[�t�F�[�XTRIPSTOP�̒x��
-- 2008/10/10 H.Itou Add End
    -- *** ���[�J���E�J�[�\�� ***
--
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
-- 2008/10/10 H.Itou Add Start �����e�X�g�w�E116
    -- ���̓p�����[�^.�˗�No��NULL�̏ꍇ�A�R���J�����g�N��
    IF (gt_request_no IS NULL) THEN
      -- �o�׊m�FAPI��IN�p�����[�^.�C���^�[�t�F�[�XTRIPSTOP�̒x���ɁuY�v��n���B
      lv_sc_defer_interface_flag := gv_yes;
--
    -- ���̓p�����[�^.�˗�No��NULL�łȂ��ꍇ�A��ʂ���̋N��
    ELSE
      -- �o�׊m�FAPI��IN�p�����[�^.�C���^�[�t�F�[�XTRIPSTOP�̒x���ɁuN�v��n���B
      lv_sc_defer_interface_flag := gv_no;
    END IF;
-- 2008/10/10 H.Itou Add End
--
    -- *********************************************
    -- ***       A12�o�׊m�FAPI�N��         ***
    -- *********************************************
    WSH_DELIVERIES_PUB.DELIVERY_ACTION(
      p_api_version_number      => 1.0
    , p_init_msg_list           => FND_API.G_TRUE
    , x_return_status           => lv_return_status
    , x_msg_count               => ln_msg_count
    , x_msg_data                => lv_msg_data
    , p_action_code             => cv_action_code   -- �o�׊m�F
    , p_delivery_id             => it_del_rows_tbl(1)
    , p_sc_action_flag          => cv_action_flag   -- ���ׂďo��
    , p_sc_intransit_flag       => gv_yes           -- �A���s���̃X�e�[�^�X��A������
    , p_sc_close_trip_flag      => gv_yes           -- �A���s�����N���[�Y
    , p_sc_stage_del_flag       => gv_no
-- 2008/10/10 H.Itou Mod Start �����e�X�g�w�E116
--    , p_sc_defer_interface_flag => gv_no            -- �C���^�[�t�F�[�XTRIPSTOP�̒x��
    , p_sc_defer_interface_flag => lv_sc_defer_interface_flag -- �C���^�[�t�F�[�XTRIPSTOP�̒x��
-- 2008/10/10 H.Itou Mod End
    , p_sc_actual_dep_date      => it_shipped_date  -- �o����
    , x_trip_id                 => ln_trip_id
    , x_trip_name               => lt_trip_name
    );
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN -- �G���[�̏ꍇ
      IF (ln_msg_count > 0 ) THEN
        -- ���b�Z�[�W������0���傫���ꍇ�G���[���b�Z�[�W���o��
        <<message_loop>>
        FOR cnt IN 1..ln_msg_count LOOP
          FND_MSG_PUB.GET( 
            p_msg_index      => cnt ,
            p_encoded        => 'F' ,
            p_data           => lv_msg_buf , 
            p_msg_index_out  => ln_msg_index_out
          );
          lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
        END LOOP message_loop;
      END IF;    
      --���b�Z�[�W���o�͂������������I������
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                            gv_msg_42a_016,
                                            gv_tkn_api_name,
                                            gv_api_name_5,
                                            gv_tkn_error_msg,
                                            lv_msg_data,
                                            gv_tkn_request_no,
                                            gt_gen_request_no
      );
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END confirm_proc;
--
  /***********************************************************************************
   * Procedure Name   : create_rma_order_header_info
   * Description      : A13RMA�󒍃w�b�_���̓o�^
   ***********************************************************************************/
  PROCEDURE create_rma_order_header_info(
    iot_order_tbl          
        IN OUT order_tbl,                                        -- �󒍏��i�[�z��
    ot_new_order_header_id
        OUT NOCOPY xxwsh_order_headers_all.order_header_id%TYPE, -- �ԗp�V�󒍃w�b�_�A�h�I��ID
    ot_new_header_id
        OUT NOCOPY xxwsh_order_headers_all.header_id%TYPE,       -- �ԗp�V�󒍃w�b�_ID
    ot_site_use_id
        OUT NOCOPY hz_cust_site_uses_all.site_use_id%TYPE,       -- �����������p�g�p�ړIID
    ov_standard_api_flag
        OUT NOCOPY NUMBER,                                       -- �W��API���s�t���O
    on_gen_count
        OUT NOCOPY NUMBER,                                       -- ���݂̃f�[�^�̈ʒu��ێ�
    ov_errbuf
        OUT NOCOPY VARCHAR2,                                     -- �G���[�E���b�Z�[�W
    ov_retcode
        OUT NOCOPY VARCHAR2,                                     -- ���^�[���E�R�[�h
    ov_errmsg
        OUT NOCOPY VARCHAR2)                                     -- ���[�U�[�E�G���[�E���b�Z�[�W
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_rma_order_header_info'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_return_status           VARCHAR2(1) ;                                 -- API�̏����X�e�[�^�X
    ln_msg_count               NUMBER;                                       -- API�̃G���[���b�Z�[�W����
    lv_msg_data                VARCHAR2(2000) ;                              -- API�̃G���[���b�Z�[�W
    lv_msg_buf                 VARCHAR2(2000);                               -- API���b�Z�[�W�����p
    lt_new_order_header_id     xxwsh_order_headers_all.order_header_id%TYPE; -- �V�󒍃w�b�_�A�h�I��ID
    lt_site_use_id             hz_cust_site_uses_all.site_use_id%TYPE;       -- �g�p�ړIID
    ln_shori_count             NUMBER;                                       -- �����ʒu����
    ln_line_count              NUMBER;                                       -- ���׌���(���ѐ��ʂ�0�ȏ�)
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lt_header_rec              OE_ORDER_PUB.HEADER_REC_TYPE;
    lt_header_val_rec          OE_ORDER_PUB.HEADER_VAL_REC_TYPE;
    lt_header_adj_tbl          OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE;
    lt_header_adj_val_tbl      OE_ORDER_PUB.HEADER_ADJ_VAL_TBL_TYPE;
    lt_header_price_att_tbl    OE_ORDER_PUB.HEADER_PRICE_ATT_TBL_TYPE;
    lt_header_adj_att_tbl      OE_ORDER_PUB.HEADER_ADJ_ATT_TBL_TYPE;
    lt_header_adj_assoc_tbl    OE_ORDER_PUB.HEADER_ADJ_ASSOC_TBL_TYPE;
    lt_header_scredit_tbl      OE_ORDER_PUB.HEADER_SCREDIT_TBL_TYPE;
    lt_header_scredit_val_tbl  OE_ORDER_PUB.HEADER_SCREDIT_VAL_TBL_TYPE;
    lt_line_tbl                OE_ORDER_PUB.LINE_TBL_TYPE;
    lt_line_val_tbl            OE_ORDER_PUB.LINE_VAL_TBL_TYPE;
    lt_line_adj_tbl            OE_ORDER_PUB.LINE_ADJ_TBL_TYPE;
    lt_line_adj_val_tbl        OE_ORDER_PUB.LINE_ADJ_VAL_TBL_TYPE;
    lt_line_price_att_tbl      OE_ORDER_PUB.LINE_PRICE_ATT_TBL_TYPE;
    lt_line_adj_att_tbl        OE_ORDER_PUB.LINE_ADJ_ATT_TBL_TYPE;
    lt_line_adj_assoc_tbl      OE_ORDER_PUB.LINE_ADJ_ASSOC_TBL_TYPE;
    lt_line_scredit_tbl        OE_ORDER_PUB.LINE_SCREDIT_TBL_TYPE;
    lt_line_scredit_val_tbl    OE_ORDER_PUB.LINE_SCREDIT_VAL_TBL_TYPE;
    lt_lot_serial_tbl          OE_ORDER_PUB.LOT_SERIAL_TBL_TYPE;
    lt_lot_serial_val_tbl      OE_ORDER_PUB.LOT_SERIAL_VAL_TBL_TYPE;
    lt_action_request_tbl      OE_ORDER_PUB.REQUEST_TBL_TYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    --A3�Ŏ擾�����f�[�^��A5�Ŏ擾�����f�[�^���ɂ�背�R�[�h�̊�l���قȂ�
    IF (gv_shori_kbn IN ('2','4') ) THEN
      ln_shori_count := gn_shori_count;
    ELSE
      ln_shori_count := 1;
    END IF;
--
    on_gen_count := ln_shori_count; -- ���׍쐬�����Ɍ��݂̈ʒu��n������
    -- �󒍖��׍쐬�Ώی����𒲍�
    SELECT count(xola.order_line_id)
    INTO   ln_line_count
    FROM   xxwsh_order_lines_all xola
    WHERE  xola.order_header_id = iot_order_tbl(ln_shori_count).order_header_id
    AND    NVL(xola.delete_flag,gv_no) = gv_no
    AND    NVL(xola.shipped_quantity,0) <> 0;
--
    IF (ln_line_count > 0 ) THEN
      ov_standard_api_flag := '1';--�W��API���s�t���O��1(���s)���Z�b�g
      -- OM���b�Z�[�W���X�g�̏�����
      OE_MSG_PUB.INITIALIZE;
      -- API�p�ϐ��ɏ����l���Z�b�g
      lt_header_rec                         := OE_ORDER_PUB.G_MISS_HEADER_REC;
      lt_line_tbl(1)                        := OE_ORDER_PUB.G_MISS_LINE_REC;
      lt_header_rec.operation               := OE_GLOBALS.G_OPR_CREATE;                                    --[CREATE]
      lt_header_rec.sold_to_org_id          := iot_order_tbl(ln_shori_count).cust_account_id;              -- �ڋq
      lt_header_rec.org_id                  := gn_org_id;                                                  -- �c�ƒP��
      lt_header_rec.order_type_id           := iot_order_tbl(ln_shori_count).transaction_type_id;          -- �󒍃^�C�v���Z�b�g
      lt_header_rec.ordered_date            := iot_order_tbl(ln_shori_count).ordered_date;                 -- �󒍓�
  --
      IF (iot_order_tbl(ln_shori_count).shipping_shikyu_class <> gv_ship_class_2) THEN 
        -- �o�׎x���敪���x���˗��ȊO�̏ꍇ
        lt_header_rec.ship_to_party_site_id := iot_order_tbl(ln_shori_count).result_deliver_to_id;         -- �o�א�ID
  --
        -- �g�p�ړIID���擾
        BEGIN
  --
          SELECT xcasv.site_use_id
          INTO   lt_site_use_id
          FROM   xxcmn_cust_acct_sites_v xcasv
          WHERE  xcasv.party_site_id = iot_order_tbl(ln_shori_count).result_deliver_to_id;
  --
          ot_site_use_id := lt_site_use_id;
  --
        EXCEPTION
          WHEN OTHERS THEN
            --���b�Z�[�W���o�͂������������I������
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                                  gv_msg_42a_024,
                                                  gv_tkn_message_tokun,
                                                  gv_message_tokun2,
                                                  gv_tkn_search,
                                                  iot_order_tbl(ln_shori_count).result_deliver_to_id
            );
            RAISE global_api_expt;
        END;
  --
      ELSE
  --
        -- �o�׎x���敪���x���˗��̏ꍇ��t���O��'Y'�̃f�[�^���擾
        BEGIN
  --
          SELECT xcasv.site_use_id
          INTO   lt_site_use_id
          FROM   xxcmn_cust_acct_sites_v xcasv
          WHERE  xcasv.cust_account_id = iot_order_tbl(ln_shori_count).cust_account_id
          AND    xcasv.primary_flag = gv_yes;
  --
          ot_site_use_id := lt_site_use_id;
  --
        EXCEPTION
          WHEN OTHERS THEN
            --���b�Z�[�W���o�͂������������I������
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                                  gv_msg_42a_024,
                                                  gv_tkn_message_tokun,
                                                  gv_message_tokun1,
                                                  gv_tkn_search,
                                                  iot_order_tbl(ln_shori_count).cust_account_id
            );
            RAISE global_api_expt;
        END;
  --
      END IF;
  --
      lt_header_rec.shipping_instructions   := iot_order_tbl(ln_shori_count).shipping_instructions;                       -- �o�׎w��
      lt_header_rec.cust_po_number          := iot_order_tbl(ln_shori_count).cust_po_number;                              -- �ڋq����
      lt_header_rec.ship_from_org_id        := iot_order_tbl(ln_shori_count).mtl_organization_id;                         -- �݌ɑg�DID
      lt_header_rec.attribute1              := iot_order_tbl(ln_shori_count).request_no;                                  -- �˗�No
      lt_header_rec.attribute2              := iot_order_tbl(ln_shori_count).delivery_no;                                 -- �z��No
      lt_header_rec.attribute3              := iot_order_tbl(ln_shori_count).result_freight_carrier_code;                 -- �^���Ǝ�_����
      lt_header_rec.attribute4              := iot_order_tbl(ln_shori_count).result_shipping_method_code;                 -- �z���敪_����
      lt_header_rec.attribute6              := TO_CHAR(iot_order_tbl(ln_shori_count).schedule_ship_date,'YYYY/MM/DD');    -- �o�ח\���
      lt_header_rec.attribute7              := iot_order_tbl(ln_shori_count).head_sales_branch;                           -- �Ǌ����_
      lt_header_rec.attribute8              := iot_order_tbl(ln_shori_count).deliver_from;                                -- �o�׌�
      lt_header_rec.attribute9              := TO_CHAR(iot_order_tbl(ln_shori_count).shipped_date,'YYYY/MM/DD');          -- �o�ד�
      lt_header_rec.attribute10             := TO_CHAR(iot_order_tbl(ln_shori_count).arrival_date,'YYYY/MM/DD');          -- ���ד�
      lt_header_rec.attribute11             := iot_order_tbl(ln_shori_count).performance_management_dept;                 -- ���ъǗ�����
      lt_header_rec.attribute12             := TO_CHAR(iot_order_tbl(ln_shori_count).schedule_arrival_date,'YYYY/MM/DD'); -- ���ח\���
  --
      -- ***************************************
      -- ***       A13-RMA�󒍍쐬API�N��        ***
      -- ***************************************
      OE_ORDER_PUB.PROCESS_ORDER(
        p_api_version_number      => 1.0
      , x_return_status           => lv_return_status
      , x_msg_count               => ln_msg_count
      , x_msg_data                => lv_msg_data
      , p_header_rec              => lt_header_rec
      , p_line_tbl                => lt_line_tbl
      , p_action_request_tbl      => lt_action_request_tbl
      , x_header_rec              => lt_header_rec
      , x_header_val_rec          => lt_header_val_rec
      , x_header_adj_tbl          => lt_header_adj_tbl
      , x_header_adj_val_tbl      => lt_header_adj_val_tbl
      , x_header_price_att_tbl    => lt_header_price_att_tbl
      , x_header_adj_att_tbl      => lt_header_adj_att_tbl
      , x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl
      , x_header_scredit_tbl      => lt_header_scredit_tbl
      , x_header_scredit_val_tbl  => lt_header_scredit_val_tbl
      , x_line_tbl                => lt_line_tbl
      , x_line_val_tbl            => lt_line_val_tbl
      , x_line_adj_tbl            => lt_line_adj_tbl
      , x_line_adj_val_tbl        => lt_line_adj_val_tbl
      , x_line_price_att_tbl      => lt_line_price_att_tbl
      , x_line_adj_att_tbl        => lt_line_adj_att_tbl
      , x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl
      , x_line_scredit_tbl        => lt_line_scredit_tbl
      , x_line_scredit_val_tbl    => lt_line_scredit_val_tbl
      , x_lot_serial_tbl          => lt_lot_serial_tbl
      , x_lot_serial_val_tbl      => lt_lot_serial_val_tbl
      , x_action_request_tbl      => lt_action_request_tbl
      );
  --
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        IF (ln_msg_count > 0 ) THEN
          -- ���b�Z�[�W������0���傫���ꍇ�G���[���b�Z�[�W���o��
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            lv_msg_buf := OE_MSG_PUB.GET(p_msg_index => cnt, 
                                         p_encoded   => 'F');
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
        END IF;
        --���b�Z�[�W���o�͂������������I������
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_016,
                                              gv_tkn_api_name,
                                              gv_api_name_3,
                                              gv_tkn_error_msg,
                                              lv_msg_data,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        RAISE global_api_expt;
      END IF;
--
      ot_new_header_id := lt_header_rec.header_id;     -- �󒍃w�b�_ID
      IF (gv_shori_kbn IN ('2','4') ) THEN
        -- �󒍃w�b�_ID�X�V�p�̃f�[�^�ɓo�^����
        gt_header_id := lt_header_rec.header_id;       -- �󒍃w�b�_ID
      END IF;
    ELSE
      ov_standard_api_flag := '0'; --�W��API���s�t���O��0(���s���Ȃ�)���Z�b�g
    END IF;
--
    ot_new_order_header_id := iot_order_tbl(ln_shori_count).order_header_id; -- �󒍃w�b�_�A�h�I��ID
--
    IF (gv_shori_kbn = '3') THEN
      --�����󒍂Ŏ󒍃w�b�_�o�^�ȑO�̏ꍇ�󒍃w�b�_�A�h�I���Ƀf�[�^��o�^
--
      SELECT xxwsh_order_headers_all_s1.NEXTVAL
      INTO   lt_new_order_header_id
      FROM   dual;
--
      ot_new_order_header_id       := lt_new_order_header_id;
--
      INSERT INTO xxwsh_order_headers_all
        (order_header_id,                -- �󒍃w�b�_�A�h�I��ID
         order_type_id,                  -- �󒍃^�C�vID
         organization_id,                -- �g�DID
         header_id,                      -- �󒍃w�b�_ID
         latest_external_flag,           -- �ŐV�t���O
         ordered_date,                   -- �󒍓�
         customer_id,                    -- �ڋqID
         customer_code,                  -- �ڋq
         deliver_to_id,                  -- �o�א�ID
         deliver_to,                     -- �o�א�
         shipping_instructions,          -- �o�׎w��
         career_id,                      -- �^���Ǝ�ID
         freight_carrier_code,           -- �^���Ǝ�
         shipping_method_code,           -- �z���敪
         cust_po_number,                 -- �ڋq����
         price_list_id,                  -- ���i�\
         request_no,                     -- �˗�No
         req_status,                     -- �X�e�[�^�X
         delivery_no,                    -- �z��No
         prev_delivery_no,               -- �O��z��No
         schedule_ship_date,             -- �o�ח\���
         schedule_arrival_date,          -- ���ח\���
         mixed_no,                       -- ���ڌ�No
         collected_pallet_qty,           -- �p���b�g�������
         confirm_request_class,          -- �����S���m�F�˗��敪
         freight_charge_class,           -- �^���敪
         shikyu_instruction_class,       -- �x���o�Ɏw���敪
         shikyu_inst_rcv_class,          -- �x���w����̋敪
         amount_fix_class,               -- �L�����z�m��敪
         takeback_class,                 -- ����敪
         deliver_from_id,                -- �o�׌�ID
         deliver_from,                   -- �o�׌��ۊǏꏊ
         head_sales_branch,              -- �Ǌ����_
         input_sales_branch,             -- ���͋��_
         po_no,                          -- ����No
         prod_class,                     -- ���i�敪
         item_class,                     -- �i�ڋ敪
         no_cont_freight_class,          -- �_��O�^���敪
         arrival_time_from,              -- ���׎���FROM
         arrival_time_to,                -- ���׎���TO
         designated_item_id,             -- �����i��ID
         designated_item_code,           -- �����i��
         designated_production_date,     -- ������
         designated_branch_no,           -- �����}��
         slip_number,                    -- �����No
         sum_quantity,                   -- ���v����
         small_quantity,                 -- ������
         label_quantity,                 -- ���x������
         loading_efficiency_weight,      -- �d�ʐύڌ���
         loading_efficiency_capacity,    -- �e�ϐύڌ���
         based_weight,                   -- ��{�d��
         based_capacity,                 -- ��{�e��
         sum_weight,                     -- �ύڏd�ʍ��v
         sum_capacity,                   -- �ύڗe�ύ��v
         mixed_ratio,                    -- ���ڗ�
         pallet_sum_quantity,            -- �p���b�g���v����
         real_pallet_quantity,           -- �p���b�g���і���
         sum_pallet_weight,              -- ���v�p���b�g�d��
         order_source_ref,               -- �󒍃\�[�X�Q��
         result_freight_carrier_id,      -- �^���Ǝ�_����ID
         result_freight_carrier_code,    -- �^���Ǝ�_����
         result_shipping_method_code,    -- �z���敪_����
         result_deliver_to_id,           -- �o�א�_����ID
         result_deliver_to,              -- �o�א�_����
         shipped_date,                   -- �o�ד�
         arrival_date,                   -- ���ד�
         weight_capacity_class,          -- �d�ʗe�ϋ敪
         actual_confirm_class,           -- ���ьv��ϋ敪
         notif_status,                   -- �ʒm�X�e�[�^�X
         prev_notif_status,              -- �O��ʒm�X�e�[�^�X
         notif_date,                     -- �m��ʒm���{����
         new_modify_flg,                 -- �V�K�C���t���O
         process_status,                 -- �����o�߃X�e�[�^�X
         performance_management_dept,    -- ���ъǗ�����
         instruction_dept,               -- �w������
         transfer_location_id,           -- �U�֐�ID
         transfer_location_code,         -- �U�֐�
         mixed_sign,                     -- ���ڋL��
         screen_update_date,             -- ��ʍX�V����
         screen_update_by,               -- ��ʍX�V��
         tightening_date,                -- �o�׈˗����ߓ���
         vendor_id,                      -- �����ID
         vendor_code,                    -- �����
         vendor_site_id,                 -- �����T�C�gID
         vendor_site_code,               -- �����T�C�g
         registered_sequence,            -- �o�^����
         tightening_program_id,          -- ���߃R���J�����gID
         corrected_tighten_class,        -- ���ߌ�C���敪
         created_by,                     -- �쐬��
         creation_date,                  -- �쐬��
         last_updated_by,                -- �ŏI�X�V��
         last_update_date,               -- �ŏI�X�V��
         last_update_login,              -- �ŏI�X�V���O�C��
         request_id,                     -- �v��ID
         program_application_id,         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         program_id,                     -- �R���J�����g�E�v���O����ID
         program_update_date             -- �v���O�����X�V��
        )VALUES
        (lt_new_order_header_id,
         iot_order_tbl(ln_shori_count).transaction_type_id,
         iot_order_tbl(ln_shori_count).organization_id,
         lt_header_rec.header_id,
         gv_no,
         iot_order_tbl(ln_shori_count).ordered_date,
         iot_order_tbl(ln_shori_count).customer_id,
         iot_order_tbl(ln_shori_count).customer_code,
         iot_order_tbl(ln_shori_count).deliver_to_id,
         iot_order_tbl(ln_shori_count).deliver_to,
         iot_order_tbl(ln_shori_count).shipping_instructions,
         iot_order_tbl(ln_shori_count).career_id,
         iot_order_tbl(ln_shori_count).freight_carrier_code,
         iot_order_tbl(ln_shori_count).shipping_method_code,
         iot_order_tbl(ln_shori_count).cust_po_number,
         iot_order_tbl(ln_shori_count).price_list_id,
         iot_order_tbl(ln_shori_count).request_no,
         iot_order_tbl(ln_shori_count).req_status,
         iot_order_tbl(ln_shori_count).delivery_no,
         iot_order_tbl(ln_shori_count).prev_delivery_no,
         iot_order_tbl(ln_shori_count).schedule_ship_date,
         iot_order_tbl(ln_shori_count).schedule_arrival_date,
         iot_order_tbl(ln_shori_count).mixed_no,
         iot_order_tbl(ln_shori_count).collected_pallet_qty,
         iot_order_tbl(ln_shori_count).confirm_request_class,
         iot_order_tbl(ln_shori_count).freight_charge_class,
         iot_order_tbl(ln_shori_count).shikyu_instruction_class,
         iot_order_tbl(ln_shori_count).shikyu_inst_rcv_class,
         iot_order_tbl(ln_shori_count).amount_fix_class,
         iot_order_tbl(ln_shori_count).takeback_class,
         iot_order_tbl(ln_shori_count).deliver_from_id,
         iot_order_tbl(ln_shori_count).deliver_from,
         iot_order_tbl(ln_shori_count).head_sales_branch,
         iot_order_tbl(ln_shori_count).input_sales_branch,
         iot_order_tbl(ln_shori_count).po_no,
         iot_order_tbl(ln_shori_count).prod_class,
         iot_order_tbl(ln_shori_count).item_class,
         iot_order_tbl(ln_shori_count).no_cont_freight_class,
         iot_order_tbl(ln_shori_count).arrival_time_from,
         iot_order_tbl(ln_shori_count).arrival_time_to,
         iot_order_tbl(ln_shori_count).designated_item_id,
         iot_order_tbl(ln_shori_count).designated_item_code,
         iot_order_tbl(ln_shori_count).designated_production_date,
         iot_order_tbl(ln_shori_count).designated_branch_no,
         iot_order_tbl(ln_shori_count).slip_number,
         iot_order_tbl(ln_shori_count).sum_quantity,
         iot_order_tbl(ln_shori_count).small_quantity,
         iot_order_tbl(ln_shori_count).label_quantity,
         iot_order_tbl(ln_shori_count).loading_efficiency_weight,
         iot_order_tbl(ln_shori_count).loading_efficiency_capacity,
         iot_order_tbl(ln_shori_count).based_weight,
         iot_order_tbl(ln_shori_count).based_capacity,
         iot_order_tbl(ln_shori_count).sum_weight,
         iot_order_tbl(ln_shori_count).sum_capacity,
         iot_order_tbl(ln_shori_count).mixed_ratio,
         iot_order_tbl(ln_shori_count).pallet_sum_quantity,
         iot_order_tbl(ln_shori_count).real_pallet_quantity,
         iot_order_tbl(ln_shori_count).sum_pallet_weight,
         iot_order_tbl(ln_shori_count).order_source_ref,
         iot_order_tbl(ln_shori_count).result_freight_carrier_id,
         iot_order_tbl(ln_shori_count).result_freight_carrier_code,
         iot_order_tbl(ln_shori_count).result_shipping_method_code,
         iot_order_tbl(ln_shori_count).result_deliver_to_id,
         iot_order_tbl(ln_shori_count).result_deliver_to,
         iot_order_tbl(ln_shori_count).shipped_date,
         iot_order_tbl(ln_shori_count).arrival_date,
         iot_order_tbl(ln_shori_count).weight_capacity_class,
         gv_yes,
         iot_order_tbl(ln_shori_count).notif_status,
         iot_order_tbl(ln_shori_count).prev_notif_status,
         iot_order_tbl(ln_shori_count).notif_date,
         iot_order_tbl(ln_shori_count).new_modify_flg,
         iot_order_tbl(ln_shori_count).process_status,
         iot_order_tbl(ln_shori_count).performance_management_dept,
         iot_order_tbl(ln_shori_count).instruction_dept,
         iot_order_tbl(ln_shori_count).transfer_location_id,
         iot_order_tbl(ln_shori_count).transfer_location_code,
         iot_order_tbl(ln_shori_count).mixed_sign,
         iot_order_tbl(ln_shori_count).screen_update_date,
         iot_order_tbl(ln_shori_count).screen_update_by,
         iot_order_tbl(ln_shori_count).tightening_date,
         iot_order_tbl(ln_shori_count).vendor_id,
         iot_order_tbl(ln_shori_count).vendor_code,
         iot_order_tbl(ln_shori_count).vendor_site_id,
         iot_order_tbl(ln_shori_count).vendor_site_code,
         iot_order_tbl(ln_shori_count).registered_sequence,
         iot_order_tbl(ln_shori_count).tightening_program_id,
         iot_order_tbl(ln_shori_count).corrected_tighten_class,
         gn_user_id,
         SYSDATE,
         gn_user_id,
         SYSDATE,
         gn_login_id,
         gn_conc_request_id,
         gn_prog_appl_id,
         gn_conc_program_id,
         SYSDATE
      );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END create_rma_order_header_info;
  /***********************************************************************************
   * Procedure Name   : create_rma_order_line_info
   * Description      : A14RMA�󒍖��׃��R�[�h�쐬�AA15RMA�󒍖��דo�^
   ***********************************************************************************/
  PROCEDURE create_rma_order_line_info(
    it_bef_order_header_id
        IN xxwsh_order_headers_all.order_header_id%TYPE,   -- �O�����󒍃w�b�_�A�h�I��ID
    it_new_order_header_id
        IN xxwsh_order_headers_all.order_header_id%TYPE,   -- �ԗp�V�󒍃w�b�_�A�h�I��ID
    it_new_header_id
        IN xxwsh_order_headers_all.header_id%TYPE,         -- �ԗp�V�󒍃w�b�_ID
    it_site_use_id
        IN hz_cust_site_uses_all.site_use_id%TYPE,         -- �����������p�g�p�ړIID
    in_gen_count
        IN NUMBER,                                         -- �󒍏��i�[�z��̌��݂̈ʒu
    iot_order_tbl
        IN OUT order_tbl,                                  -- �󒍏��i�[�z��
    ot_order_line_tbl
        OUT NOCOPY order_line_type,                        -- �󒍖��׏��i�[�z��
    ot_revised_line_tbl
        OUT NOCOPY revised_line_type,                      -- �����󒍖��׏��i�[�z��
    ov_errbuf
        OUT NOCOPY VARCHAR2,                               -- �G���[�E���b�Z�[�W      --# �Œ� #
    ov_retcode
        OUT NOCOPY VARCHAR2,                               -- ���^�[���E�R�[�h        --# �Œ� #
    ov_errmsg
        OUT NOCOPY VARCHAR2)                               -- ���[�U�[�G���[���b�Z�[�W--# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_rma_order_line_info'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    ln_line_count                 NUMBER;                               -- ���׌���
    lv_return_status              VARCHAR2(1) ;                         -- API�̏����X�e�[�^�X
    ln_msg_count                  NUMBER;                               -- API�̃G���[���b�Z�[�W����
    lv_msg_data                   VARCHAR2(2000) ;                      -- API�̃G���[���b�Z�[�W
    lv_msg_buf                    VARCHAR2(2000);                       -- API���b�Z�[�W�����p
    ln_shori_count                NUMBER;                               -- �󒍏��̏�������
    lt_input_line_id              oe_order_lines_all.line_id%TYPE;      -- �o�^�p�󒍖���ID
    ln_order_line_count           NUMBER;                               -- �󒍖��דo�^����
    -- *** �A�h�I���o�^�p ***
    lt_order_line_id              ol_order_line_id_type;                -- �󒍖��׃A�h�I��ID
    lt_order_header_id            ol_order_header_id_type;              -- �󒍃w�b�_�A�h�I��ID
    lt_order_line_number          ol_order_line_number_type;            -- ���הԍ�
    lt_header_id                  ol_header_id_type;                    -- �󒍃w�b�_ID
    lt_line_id                    ol_line_id_type;                      -- �󒍖���ID
    lt_request_no                 ol_request_no_type;                   -- �˗�No
    lt_shipping_inventory_item_id ol_ship_inv_item_id_type;             -- �o�וi��ID
    lt_shipping_item_code         ol_ship_item_code_type;               -- �o�וi��
    lt_quantity                   ol_quantity_type;                     -- ����
    lt_uom_code                   ol_uom_code_type;                     -- �P��
    lt_unit_price                 ol_unit_price_type;                   -- �P��
    lt_shippied_quantity          ol_shipped_quantity_type;             -- �o�׎��ѐ���
    lt_designated_production_date ol_desi_prod_date_type;               -- �w�萻����
    lt_based_request_quantity     ol_base_req_quantity_type;            -- ���_�˗�����
    lt_request_item_id            ol_request_item_id_type;              -- �˗��i��ID
    lt_request_item_code          ol_request_item_code_type;            -- �˗��i�ڃR�[�h
    lt_ship_to_quantity           ol_ship_to_quantity_type;             -- ���Ɏ��ѐ���
    lt_futai_code                 ol_futai_code_type;                   -- �t�уR�[�h
    lt_designated_date            ol_designated_date_type;              -- �w����t(���[�t)
    lt_move_number                ol_move_number_type;                  -- �ړ�No
    lt_po_number                  ol_po_number_type;                    -- ����No
    lt_cust_po_number             ol_cust_po_number_type;               -- �ڋq����
    lt_pallet_quantity            ol_pallet_quantity_type;              -- �p���b�g��
    lt_layer_quantity             ol_layer_quantity_type;               -- �i��
    lt_case_quantity              ol_case_quantity_type;                -- �P�[�X��
    lt_weight                     ol_weight_type;                       -- �d��
    lt_capacity                   ol_capacity_type;                     -- �e��
    lt_pallet_qty                 ol_pallet_qty_type;                   -- �p���b�g����
    lt_pallet_weight              ol_pallet_weight_type;                -- �p���b�g�d��
    lt_reserved_quantity          ol_reserved_quantity_type;            -- ������
    lt_automanual_reserve_class   ol_auto_rese_class_type;              -- �����蓮�����敪
    lt_warning_class              ol_warning_class_type;                -- �x���敪
    lt_warning_date               ol_warning_date_type;                 -- �x�����t
    lt_line_description           ol_line_description_type;             -- �E�v
    lt_rm_if_flg                  ol_rm_if_flg_type;                    -- �q�֕ԕiIF�σt���O
    lt_shipping_request_if_flg    ol_ship_requ_if_flg_type;             -- �o�׈˗�IF�σt���O
    lt_shipping_result_if_flg     ol_ship_resu_if_flg_type;             -- �o�׎���IF�σt���O
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    -- �󒍖��דo�^�p�z��
    lt_order_line_tbl             OE_ORDER_PUB.LINE_TBL_TYPE;
    lt_header_rec                 OE_ORDER_PUB.HEADER_REC_TYPE;
    lt_header_val_rec             OE_ORDER_PUB.HEADER_VAL_REC_TYPE;
    lt_header_adj_tbl             OE_ORDER_PUB.HEADER_ADJ_TBL_TYPE;
    lt_header_adj_val_tbl         OE_ORDER_PUB.HEADER_ADJ_VAL_TBL_TYPE;
    lt_header_price_att_tbl       OE_ORDER_PUB.HEADER_PRICE_ATT_TBL_TYPE;
    lt_header_adj_att_tbl         OE_ORDER_PUB.HEADER_ADJ_ATT_TBL_TYPE;
    lt_header_adj_assoc_tbl       OE_ORDER_PUB.HEADER_ADJ_ASSOC_TBL_TYPE;
    lt_header_scredit_tbl         OE_ORDER_PUB.HEADER_SCREDIT_TBL_TYPE;
    lt_header_scredit_val_tbl     OE_ORDER_PUB.HEADER_SCREDIT_VAL_TBL_TYPE;
    lt_line_val_tbl               OE_ORDER_PUB.LINE_VAL_TBL_TYPE;
    lt_line_adj_tbl               OE_ORDER_PUB.LINE_ADJ_TBL_TYPE;
    lt_line_adj_val_tbl           OE_ORDER_PUB.LINE_ADJ_VAL_TBL_TYPE;
    lt_line_price_att_tbl         OE_ORDER_PUB.LINE_PRICE_ATT_TBL_TYPE;
    lt_line_adj_att_tbl           OE_ORDER_PUB.LINE_ADJ_ATT_TBL_TYPE;
    lt_line_adj_assoc_tbl         OE_ORDER_PUB.LINE_ADJ_ASSOC_TBL_TYPE;
    lt_line_scredit_tbl           OE_ORDER_PUB.LINE_SCREDIT_TBL_TYPE;
    lt_line_scredit_val_tbl       OE_ORDER_PUB.LINE_SCREDIT_VAL_TBL_TYPE;
    lt_lot_serial_tbl             OE_ORDER_PUB.LOT_SERIAL_TBL_TYPE;
    lt_lot_serial_val_tbl         OE_ORDER_PUB.LOT_SERIAL_VAL_TBL_TYPE;
    lt_action_request_tbl         OE_ORDER_PUB.REQUEST_TBL_TYPE;
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***       RMA�󒍃A�h�I�����擾   ***
    -- ***************************************
    ln_line_count := 0;             -- ���׌�����������
    ln_order_line_count := 0;
    ln_shori_count := in_gen_count;
    <<order_line_data>> --�󒍍쐬��񃋁[�v����
    LOOP
      IF ((ln_shori_count > iot_order_tbl.LAST) OR
          (iot_order_tbl(ln_shori_count).order_header_id <> it_bef_order_header_id)) THEN
        EXIT; -- ���݂̃��[�v�̃f�[�^�����݂��Ȃ��ꍇ�������͑O�̃w�b�_ID�ƌ��݂̃w�b�_ID���قȂ�ꍇ���[�v�𔲂���
      END IF;
      lt_input_line_id := NULL;   -- �Z�b�g�p�󒍖���ID��������
      IF (iot_order_tbl(ln_shori_count).shipped_quantity <> 0 )THEN
        ln_order_line_count := ln_order_line_count + 1;
--
        -- �󒍖��דo�^API�p�f�[�^
        lt_order_line_tbl(ln_order_line_count)                      := OE_ORDER_PUB.G_MISS_LINE_REC;                             -- �󒍖��וϐ��̏�����
        lt_order_line_tbl(ln_order_line_count).operation            := OE_GLOBALS.G_OPR_CREATE;
        -- �󒍖��דo�^API�p�f�[�^
        SELECT oe_order_lines_s.NEXTVAL
        INTO   lt_order_line_tbl(ln_order_line_count).line_id
        FROM   DUAL;
        lt_input_line_id                                            := lt_order_line_tbl(ln_order_line_count).line_id;
        lt_order_line_tbl(ln_order_line_count).header_id            := it_new_header_id;                                         -- �󒍃w�b�_ID
        lt_order_line_tbl(ln_order_line_count).inventory_item_id    := iot_order_tbl(ln_shori_count).shipping_inventory_item_id; -- �o�וi��ID
        lt_order_line_tbl(ln_order_line_count).ordered_quantity     := iot_order_tbl(ln_shori_count).shipped_quantity;           -- �o�׎��ѐ���
        lt_order_line_tbl(ln_order_line_count).schedule_ship_date   := iot_order_tbl(ln_shori_count).schedule_ship_date;         -- �o�ח\���
        lt_order_line_tbl(ln_order_line_count).unit_selling_price   := NVL(iot_order_tbl(ln_shori_count).unit_price,0);          -- �P��
        lt_order_line_tbl(ln_order_line_count).unit_list_price      := NVL(iot_order_tbl(ln_shori_count).unit_price,0);          -- �P��
        lt_order_line_tbl(ln_order_line_count).request_date         := SYSDATE;                                                  -- �v����
        lt_order_line_tbl(ln_order_line_count).attribute1           := iot_order_tbl(ln_shori_count).quantity;                   -- ����
        lt_order_line_tbl(ln_order_line_count).attribute2           := iot_order_tbl(ln_shori_count).based_request_quantity;     -- ���_�˗�����
        lt_order_line_tbl(ln_order_line_count).attribute3           := iot_order_tbl(ln_shori_count).request_item_code;          -- �˗��i��
        lt_order_line_tbl(ln_order_line_count).return_reason_code   := gt_return_reason_code;                                    -- �ԕi���R
        lt_order_line_tbl(ln_order_line_count).calculate_price_flag := gv_no;                                                    -- �������i�v�Z�t���O
        -- �W��API�����p�󒍃f�[�^
        ot_order_line_tbl(ln_order_line_count).order_line_id        := iot_order_tbl(ln_shori_count).order_line_id;              -- �󒍖��׃A�h�I��ID
        ot_order_line_tbl(ln_order_line_count).line_id              := lt_input_line_id;                                         -- �󒍖���ID
        ot_order_line_tbl(ln_order_line_count).lot_ctl              := iot_order_tbl(ln_shori_count).lot_ctl;                    -- ���b�g�Ǘ�
        ot_order_line_tbl(ln_order_line_count).shipped_quantity     := iot_order_tbl(ln_shori_count).shipped_quantity;           -- ���ѐ���
        ot_order_line_tbl(ln_order_line_count).uom_code             := iot_order_tbl(ln_shori_count).uom_code;                   -- �P��
        ot_order_line_tbl(ln_order_line_count).shipping_inventory_item_id 
                                                                    := iot_order_tbl(ln_shori_count).shipping_inventory_item_id; -- �o�וi��ID
        ot_order_line_tbl(ln_order_line_count).shipped_date         := iot_order_tbl(ln_shori_count).shipped_date;               -- �o�ד�
        ot_order_line_tbl(ln_order_line_count).mtl_organization_id
                                                                    := iot_order_tbl(ln_shori_count).mtl_organization_id;        -- �݌ɑg�D
        ot_order_line_tbl(ln_order_line_count).header_id            := it_new_header_id;                                         -- �󒍃w�b�_ID
        ot_order_line_tbl(ln_order_line_count).site_use_id          := it_site_use_id;                                           -- �g�p�ړIID
        ot_order_line_tbl(ln_order_line_count).location_id          := iot_order_tbl(ln_shori_count).location_id;                -- ���Ə�ID
        ot_order_line_tbl(ln_order_line_count).subinventory_code    := iot_order_tbl(ln_shori_count).subinventory_code;          -- �ۊǏꏊ�R�[�h
        ot_order_line_tbl(ln_order_line_count).inventory_location_id
                                                                    := iot_order_tbl(ln_shori_count).inventory_location_id;      -- �q��ID
        ot_order_line_tbl(ln_order_line_count).cust_account_id      := iot_order_tbl(ln_shori_count).cust_account_id;            -- �ڋqID
      END IF;
--
      -- ���׌�����+1
      ln_line_count := ln_line_count + 1;
--
      IF (gv_shori_kbn IN ('2','4') ) THEN 
        -- �󒍖���ID�X�V�p�ϐ��ɒl���Z�b�g(����ID��API���s��ɕʓr�Z�b�g����)
        gt_order_line_id(ln_line_count) := iot_order_tbl(ln_shori_count).order_line_id;
        gt_line_id(ln_line_count)       := lt_input_line_id;
      END IF;
      IF (gv_shori_kbn = '3') THEN
        --�����󒍂̏ꍇ�󒍖��׃A�h�I���o�^�p�f�[�^���쐬
--
        SELECT xxwsh_order_lines_all_s1.NEXTVAL
        INTO   lt_order_line_id(ln_line_count)
        FROM   dual;
--
        ot_revised_line_tbl(ln_line_count).order_line_id
                                                           := iot_order_tbl(ln_shori_count).order_line_id;
        ot_revised_line_tbl(ln_line_count).new_order_line_id
                                                           := lt_order_line_id(ln_line_count); -- �V�󒍖��׃A�h�I��ID���Z�b�g
        lt_order_header_id(ln_line_count)                  := it_new_order_header_id;
        lt_order_line_number(ln_line_count)                := iot_order_tbl(ln_shori_count).order_line_number;
        lt_header_id(ln_line_count)                        := it_new_header_id;
        lt_line_id(ln_line_count)                          := lt_input_line_id;
        lt_request_no(ln_line_count)                       := iot_order_tbl(ln_shori_count).line_request_no;
        lt_shipping_inventory_item_id(ln_line_count)       := iot_order_tbl(ln_shori_count).shipping_inventory_item_id;
        lt_shipping_item_code(ln_line_count)               := iot_order_tbl(ln_shori_count).shipping_item_code;
        lt_quantity(ln_line_count)                         := iot_order_tbl(ln_shori_count).quantity;
        lt_uom_code(ln_line_count)                         := iot_order_tbl(ln_shori_count).uom_code;
        lt_unit_price(ln_line_count)                       := iot_order_tbl(ln_shori_count).unit_price;
        lt_shippied_quantity(ln_line_count)                := iot_order_tbl(ln_shori_count).shipped_quantity;
        lt_designated_production_date(ln_line_count)       := iot_order_tbl(ln_shori_count).line_designated_prod_date;
        lt_based_request_quantity(ln_line_count)           := iot_order_tbl(ln_shori_count).based_request_quantity;
        lt_request_item_id(ln_line_count)                  := iot_order_tbl(ln_shori_count).request_item_id;
        lt_request_item_code(ln_line_count)                := iot_order_tbl(ln_shori_count).request_item_code;
        lt_ship_to_quantity(ln_line_count)                 := iot_order_tbl(ln_shori_count).ship_to_quantity;
        lt_futai_code(ln_line_count)                       := iot_order_tbl(ln_shori_count).futai_code;
        lt_designated_date(ln_line_count)                  := iot_order_tbl(ln_shori_count).designated_date;
        lt_move_number(ln_line_count)                      := iot_order_tbl(ln_shori_count).move_number;
        lt_po_number(ln_line_count)                        := iot_order_tbl(ln_shori_count).po_number;
        lt_cust_po_number(ln_line_count)                   := iot_order_tbl(ln_shori_count).line_cust_po_number;
        lt_pallet_quantity(ln_line_count)                  := iot_order_tbl(ln_shori_count).pallet_quantity;
        lt_layer_quantity(ln_line_count)                   := iot_order_tbl(ln_shori_count).layer_quantity;
        lt_case_quantity(ln_line_count)                    := iot_order_tbl(ln_shori_count).case_quantity;
        lt_weight(ln_line_count)                           := iot_order_tbl(ln_shori_count).weight;
        lt_capacity(ln_line_count)                         := iot_order_tbl(ln_shori_count).capacity;
        lt_pallet_qty(ln_line_count)                       := iot_order_tbl(ln_shori_count).pallet_qty;
        lt_pallet_weight(ln_line_count)                    := iot_order_tbl(ln_shori_count).pallet_weight;
        lt_reserved_quantity(ln_line_count)                := iot_order_tbl(ln_shori_count).reserved_quantity;
        lt_automanual_reserve_class(ln_line_count)         := iot_order_tbl(ln_shori_count).automanual_reserve_class;
        lt_warning_class(ln_line_count)                    := iot_order_tbl(ln_shori_count).warning_class;
        lt_warning_date(ln_line_count)                     := iot_order_tbl(ln_shori_count).warning_date;
        lt_line_description(ln_line_count)                 := iot_order_tbl(ln_shori_count).line_description;
        lt_rm_if_flg(ln_line_count)                        := iot_order_tbl(ln_shori_count).rm_if_flg;
        lt_shipping_request_if_flg(ln_line_count)          := iot_order_tbl(ln_shori_count).shipping_request_if_flg;
        lt_shipping_result_if_flg(ln_line_count)           := iot_order_tbl(ln_shori_count).shipping_result_if_flg;
--
      END IF;
      -- �󒍃A�h�I�����[�v������+1
      ln_shori_count := ln_shori_count + 1;
    END LOOP order_line_data;
--
    --A3�Ŏ擾�����f�[�^�̏ꍇ���݂̃��R�[�h�ԍ���Ԃ�
    IF (gv_shori_kbn IN ('2','4') ) THEN
      gn_shori_count := ln_shori_count;
    END IF;
--
    IF (ln_order_line_count > 0) THEN --���ׂ̑Ώی�����0�����傫���ꍇ�Ɍ㑱�̏������s���B
      -- ***************************************
      -- ***       A15-RMA�󒍍쐬API�N��    ***
      -- ***************************************
      -- OM���b�Z�[�W���X�g�̏�����
      OE_MSG_PUB.INITIALIZE;
      lt_action_request_tbl(1)                := OE_ORDER_PUB.G_MISS_REQUEST_REC;
      lt_action_request_tbl(1).entity_code    := OE_GLOBALS.G_ENTITY_HEADER;
      lt_action_request_tbl(1).entity_id      := it_new_header_id;
      lt_action_request_tbl(1).request_type   := OE_GLOBALS.G_BOOK_ORDER; --�L��
      OE_ORDER_PUB.PROCESS_ORDER(
        p_api_version_number      => 1.0
      , x_return_status           => lv_return_status
      , x_msg_count               => ln_msg_count
      , x_msg_data                => lv_msg_data
      , p_header_rec              => lt_header_rec
      , p_line_tbl                => lt_order_line_tbl
      , p_action_request_tbl      => lt_action_request_tbl
      , x_header_rec              => lt_header_rec
      , x_header_val_rec          => lt_header_val_rec
      , x_header_adj_tbl          => lt_header_adj_tbl
      , x_header_adj_val_tbl      => lt_header_adj_val_tbl
      , x_header_price_att_tbl    => lt_header_price_att_tbl
      , x_header_adj_att_tbl      => lt_header_adj_att_tbl
      , x_header_adj_assoc_tbl    => lt_header_adj_assoc_tbl
      , x_header_scredit_tbl      => lt_header_scredit_tbl
      , x_header_scredit_val_tbl  => lt_header_scredit_val_tbl
      , x_line_tbl                => lt_order_line_tbl
      , x_line_val_tbl            => lt_line_val_tbl
      , x_line_adj_tbl            => lt_line_adj_tbl
      , x_line_adj_val_tbl        => lt_line_adj_val_tbl
      , x_line_price_att_tbl      => lt_line_price_att_tbl
      , x_line_adj_att_tbl        => lt_line_adj_att_tbl
      , x_line_adj_assoc_tbl      => lt_line_adj_assoc_tbl
      , x_line_scredit_tbl        => lt_line_scredit_tbl
      , x_line_scredit_val_tbl    => lt_line_scredit_val_tbl
      , x_lot_serial_tbl          => lt_lot_serial_tbl
      , x_lot_serial_val_tbl      => lt_lot_serial_val_tbl
      , x_action_request_tbl      => lt_action_request_tbl
      );
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        IF (ln_msg_count > 0 ) THEN
          -- ���b�Z�[�W������0���傫���ꍇ�G���[���b�Z�[�W���o��
          <<message_loop>>
          FOR cnt IN 1..ln_msg_count LOOP
            lv_msg_buf := OE_MSG_PUB.GET(p_msg_index => cnt, 
                                         p_encoded   => 'F');
            lv_msg_data := SUBSTRB(lv_msg_data || lv_msg_buf,1,2000);
          END LOOP message_loop;
        END IF;
        --���b�Z�[�W���o�͂������������I������
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                              gv_msg_42a_016,
                                              gv_tkn_api_name,
                                              gv_api_name_3,
                                              gv_tkn_error_msg,
                                              lv_msg_data,
                                              gv_tkn_request_no,
                                              gt_gen_request_no
        );
        RAISE global_api_expt;
      END IF;
    END IF;
    IF (gv_shori_kbn = '3') THEN
      -- ********************************************************
      -- ***      �����󒍎��󒍖��׃A�h�I���ɒ����f�[�^��o�^***
      -- ********************************************************
      FORALL i IN 1..lt_order_line_id.COUNT
        INSERT INTO xxwsh_order_lines_all
          (order_line_id,
           order_header_id,
           order_line_number,
           header_id,
           line_id,
           request_no,
           shipping_inventory_item_id,
           shipping_item_code,
           quantity,
           uom_code,
           unit_price,
           shipped_quantity,
           designated_production_date,
           based_request_quantity,
           request_item_id,
           request_item_code,
           ship_to_quantity,
           futai_code,
           designated_date,
           move_number,
           po_number,
           cust_po_number,
           pallet_quantity,
           layer_quantity,
           case_quantity,
           weight,
           capacity,
           pallet_qty,
           pallet_weight,
           reserved_quantity,
           automanual_reserve_class,
           delete_flag,
           warning_class,
           warning_date,
           line_description,
           rm_if_flg,
           shipping_request_if_flg,
           shipping_result_if_flg,
           created_by,
           creation_date,
           last_updated_by,
           last_update_date,
           last_update_login,
           request_id,
           program_application_id,
           program_id,
           program_update_date)
        VALUES (
           lt_order_line_id(i),              -- �󒍖��׃A�h�I��ID
           lt_order_header_id(i),            -- �󒍃w�b�_�A�h�I��ID
           lt_order_line_number(i),          -- ���הԍ�
           lt_header_id(i),                  -- �󒍃w�b�_ID
           lt_line_id(i),                    -- �󒍖���ID
           lt_request_no(i),                 -- �˗�No
           lt_shipping_inventory_item_id(i), -- �o�וi��ID
           lt_shipping_item_code(i),         -- �o�וi��
           lt_quantity(i),                   -- ����
           lt_uom_code(i),                   -- �P��
           lt_unit_price(i),                 -- �P��
           lt_shippied_quantity(i),          -- �o�׎��ѐ���
           lt_designated_production_date(i), -- �w�萻����
           lt_based_request_quantity(i),     -- ���_�˗�����
           lt_request_item_id(i),            -- �˗��i��ID
           lt_request_item_code(i),          -- �˗��i�ڃR�[�h
           lt_ship_to_quantity(i),           -- ���Ɏ��ѐ���
           lt_futai_code(i),                 -- �t�уR�[�h
           lt_designated_date(i),            -- �w����t(���[�t)
           lt_move_number(i),                -- �ړ�No
           lt_po_number(i),                  -- ����No
           lt_cust_po_number(i),             -- �ڋq����
           lt_pallet_quantity(i),            -- �p���b�g��
           lt_layer_quantity(i),             -- �i��
           lt_case_quantity(i),              -- �P�[�X��
           lt_weight(i),                     -- �d��
           lt_capacity(i),                   -- �e��
           lt_pallet_qty(i),                 -- �p���b�g����
           lt_pallet_weight(i),              -- �p���b�g�d��
           lt_reserved_quantity(i),          -- ������
           lt_automanual_reserve_class(i),   -- �����蓮�����敪
           'N',                             -- �폜�t���O
           lt_warning_class(i),              -- �x���敪
           lt_warning_date(i),               -- �x�����t
           lt_line_description(i),           -- �E�v
           lt_rm_if_flg(i),                  -- �q�֕ԕi�C���^�t�F�[�X�σt���O
           lt_shipping_request_if_flg(i),    -- �o�׈˗��C���^�t�F�[�X�σt���O
           lt_shipping_result_if_flg(i),     -- �o�׎��уC���^�t�F�[�X�σt���O
           gn_user_id,                       -- �쐬��
           SYSDATE,                          -- �쐬��
           gn_user_id,                       -- �ŏI�X�V��
           SYSDATE,                          -- �ŏI�X�V��
           gn_login_id,                      -- �ŏI�X�V���O�C��
           gn_conc_request_id,               -- �v��ID
           gn_prog_appl_id,                  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           gn_conc_program_id,               -- �R���J�����g�E�v���O����ID
           SYSDATE                           -- �v���O�����X�V��
        );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END create_rma_order_line_info;
  /***********************************************************************************
   * Procedure Name   : create_lot_details
   * Description      : A16���b�g���쐬
   ***********************************************************************************/
  PROCEDURE create_lot_details(
    it_order_line_tbl    IN order_line_type,    -- �󒍖��׏��i�[�z��
    it_revised_line_tbl  IN revised_line_type,  -- �����󒍖��׏��i�[�z��
    iv_standard_api_flag IN VARCHAR2,           -- �W��API���s�t���O
    ov_errbuf            OUT NOCOPY VARCHAR2,   -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2)   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_lot_details'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_count              NUMBER;           -- �ړ����b�g�ڍדo�^�p����
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_mov_lot_details(
           pt_order_line_id xxwsh_order_lines_all.order_line_id%TYPE
    ) IS SELECT xmld.document_type_code,      -- �����^�C�v
                xmld.record_type_code,        -- ���R�[�h�^�C�v
                xmld.item_id,                 -- OPM�i��ID
                xmld.item_code,               -- �i��
                xmld.lot_no,                  -- ���b�gNo
                xmld.lot_id,                  -- ���b�gID
                xmld.actual_date,             -- ���ѓ�
                xmld.actual_quantity,         -- ���ѐ���
                xmld.automanual_reserve_class -- �����蓮�����敪
         FROM   xxinv_mov_lot_details xmld    -- �ړ����b�g�ڍ�(�A�h�I��)
         WHERE  xmld.mov_line_id = pt_order_line_id
         AND    xmld.document_type_code IN (gv_document_type_10,gv_document_type_30)
         AND    xmld.record_type_code = gv_record_type_20
         AND    xmld.actual_quantity <> 0;
--
    CURSOR cur_revised_lot_details(
           pt_order_line_id xxwsh_order_lines_all.order_line_id%TYPE
    ) IS SELECT xmld.document_type_code,      -- �����^�C�v
                xmld.record_type_code,        -- ���R�[�h�^�C�v
                xmld.item_id,                 -- OPM�i��ID
                xmld.item_code,               -- �i��
                xmld.lot_no,                  -- ���b�gNo
                xmld.lot_id,                  -- ���b�gID
                xmld.actual_date,             -- ���ѓ�
                xmld.actual_quantity,         -- ���ѐ���
                xmld.automanual_reserve_class -- �����蓮�����敪
         FROM   xxinv_mov_lot_details xmld    -- �ړ����b�g�ڍ�(�A�h�I��)
         WHERE  xmld.mov_line_id = pt_order_line_id
         AND    xmld.document_type_code IN (gv_document_type_10,gv_document_type_30)
         AND    xmld.record_type_code = gv_record_type_20;
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- *********************************************
    -- ***       ���ׂ��ƂɃ��b�g�����擾      ***
    -- *********************************************
--
    IF (iv_standard_api_flag = '1') THEN
      -- �������I�[�v���C���^�t�F�[�X�w�b�_�o�^�p�f�[�^
      gn_header_if_count :=  gn_header_if_count + 1;
--
      SELECT rcv_headers_interface_s.NEXTVAL
      INTO   gt_header_interface_id(gn_header_if_count)
      FROM   dual;
--
      gt_expectied_receipt_date(gn_header_if_count)   := it_order_line_tbl(1).shipped_date;               -- �o�ד�
      gt_ship_to_organization_id(gn_header_if_count)  := it_order_line_tbl(1).mtl_organization_id;        -- �݌ɑg�DID
      gt_customer_id(gn_header_if_count)              := it_order_line_tbl(1).cust_account_id;            -- �ڋqID
      gt_customer_site_id(gn_header_if_count)         := it_order_line_tbl(1).site_use_id;                -- �g�p�ړIID
      <<order_line_data>>
      FOR i IN 1..it_order_line_tbl.COUNT LOOP  --���ׂ̌������[�v
        -- �������I�[�v���C���^�t�F�[�X���ׂ̃f�[�^���쐬
        gn_tran_if_count := gn_tran_if_count + 1;
        gt_line_header_interface_id(gn_tran_if_count) := gt_header_interface_id(gn_header_if_count);      -- �w�b�_�C���^�t�F�[�XID
        gt_line_exp_receipt_date(gn_tran_if_count)    := it_order_line_tbl(i).shipped_date;               -- �o�ד�
        gt_transaction_date(gn_tran_if_count)         := it_order_line_tbl(i).shipped_date;               -- �o�ד�
--
        SELECT rcv_transactions_interface_s.NEXTVAL  -- �������C���^�t�F�[�XID
        INTO   gt_interface_transaction_id(gn_tran_if_count)
        FROM   dual;
--
        gt_quantity(gn_tran_if_count)                 := it_order_line_tbl(i).shipped_quantity;           -- ����
        gt_unit_of_measure(gn_tran_if_count)          := it_order_line_tbl(i).uom_code;                   -- �P��
        gt_ti_item_id(gn_tran_if_count)               := it_order_line_tbl(i).shipping_inventory_item_id; -- �i��ID
        gt_ship_to_location_id(gn_tran_if_count)      := it_order_line_tbl(i).location_id;                -- ���Ə�ID
        gt_subinventory(gn_tran_if_count)             := it_order_line_tbl(i).subinventory_code;          -- �ۊǏꏊ�R�[�h
        gt_locator_id(gn_tran_if_count)               := it_order_line_tbl(i).inventory_location_id;      -- �q��ID
        gt_oe_order_header_id(gn_tran_if_count)       := it_order_line_tbl(i).header_id;                  -- �󒍃w�b�_ID
        gt_oe_order_line_id(gn_tran_if_count)         := it_order_line_tbl(i).line_id;                    -- �󒍖���ID
--
        -- ���ׂ��ƂɈړ����b�g�ڍׂ��Ăяo��
--
        <<move_lot_details_data>>
        FOR rec_move_lot_details IN cur_mov_lot_details(it_order_line_tbl(i).order_line_id) LOOP
--
          IF (it_order_line_tbl(i).lot_ctl =gv_lot_ctl_1) THEN --���b�g�Ǘ��i�̏ꍇ
--
            -- �������I�[�v���C���^�t�F�[�X���b�g�̃f�[�^���쐬
            gn_tran_lot_if_count                             := gn_tran_lot_if_count + 1;
--
            SELECT mtl_material_transactions_s.NEXTVAL  -- ���b�g�C���^�t�F�[�XID
            INTO   gt_transaction_interface_id(gn_tran_lot_if_count)
            FROM   dual;
--
            gt_lot_number(gn_tran_lot_if_count)              := rec_move_lot_details.lot_no;                   -- ���b�gNo
            gt_transaction_quantity(gn_tran_lot_if_count)    := rec_move_lot_details.actual_quantity;          -- ����
            gt_primary_quantity(gn_tran_lot_if_count)        := rec_move_lot_details.actual_quantity;          -- ����
            gt_lot_prod_transaction_id(gn_tran_lot_if_count) := gt_interface_transaction_id(gn_tran_if_count); -- �������C���^�t�F�[�XID
--
          END IF;
        END LOOP move_lot_details_data;
--
      END LOOP order_line_data;
    END IF;
--
    IF (gv_shori_kbn = '3') THEN
    -- �����敪�������󒍂̏ꍇ�ԕi�p�ړ����b�g�ڍדo�^�f�[�^���쐬����
      <<revised_line_data>>
      FOR cnt IN 1..it_revised_line_tbl.COUNT LOOP  --���ׂ̌������[�v
        <<revised_lot_details_data>>
        FOR revised_lot_details IN cur_revised_lot_details(it_revised_line_tbl(cnt).order_line_id) LOOP
          gn_lot_count                              := gn_lot_count +1;
--
          SELECT xxinv_mov_lot_s1.NEXTVAL  -- ���b�g�ڍ�ID
          INTO   gt_mov_lot_dtl_id(gn_lot_count)
          FROM   dual;
--
          gt_mov_line_id(gn_lot_count)              := it_revised_line_tbl(cnt).new_order_line_id;   -- ����ID
          gt_document_type_code(gn_lot_count)       := revised_lot_details.document_type_code;       -- �����^�C�v
          gt_record_type_code(gn_lot_count)         := revised_lot_details.record_type_code;         -- ���R�[�h�^�C�v
          gt_item_id(gn_lot_count)                  := revised_lot_details.item_id;                  -- OPM�i��ID
          gt_item_code(gn_lot_count)                := revised_lot_details.item_code;                -- �i��
          gt_lot_id(gn_lot_count)                   := revised_lot_details.lot_id;                   -- ���b�gID
          gt_lot_no(gn_lot_count)                   := revised_lot_details.lot_no;                   -- ���b�gNo
          gt_actual_date(gn_lot_count)              := revised_lot_details.actual_date;              -- ���ѓ�
          gt_actual_quantity(gn_lot_count)          := revised_lot_details.actual_quantity;          -- ���ѐ���
          gt_automanual_reserve_class(gn_lot_count) := revised_lot_details.automanual_reserve_class; -- �����蓮�����敪
        END LOOP revised_lot_details_data;
--
      END LOOP revised_line_data;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END create_lot_details;
  /***********************************************************************************
   * Procedure Name   : upd_status
   * Description      : A17�X�e�[�^�X�X�V
   ***********************************************************************************/
  PROCEDURE upd_status(
    ov_errbuf       OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_status'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- �󒍃w�b�_�A�h�I�����X�V
    UPDATE xxwsh_order_headers_all
    SET    actual_confirm_class    = gv_yes,             -- ���ьv��ϋ敪
           header_id               = gt_header_id,       -- �󒍃w�b�_ID
           last_updated_by         = gn_user_id,         -- �ŏI�X�V��
           last_update_date        = SYSDATE,            -- �ŏI�X�V��
           last_update_login       = gn_login_id,        -- �ŏI�X�V���O�C��
           request_id              = gn_conc_request_id, -- �v��ID
           program_application_id  = gn_prog_appl_id,    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           program_id              = gn_conc_program_id, -- �R���J�����g�E�v���O����ID
           program_update_date     = SYSDATE             -- �v���O�����X�V��
    WHERE  order_header_id      = gt_gen_order_header_id;
    -- �󒍖��׃A�h�I�����X�V
    FORALL i IN 1 .. gt_order_line_id.COUNT
      UPDATE xxwsh_order_lines_all
      SET  header_id               = gt_header_id,        -- �󒍃w�b�_ID
           line_id                 = gt_line_id(i),       -- �󒍖���ID
           last_updated_by         = gn_user_id,          -- �ŏI�X�V��
           last_update_date        = SYSDATE,             -- �ŏI�X�V��
           last_update_login       = gn_login_id,         -- �ŏI�X�V���O�C��
           request_id              = gn_conc_request_id,  -- �v��ID
           program_application_id  = gn_prog_appl_id,     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           program_id              = gn_conc_program_id,  -- �R���J�����g�E�v���O����ID
           program_update_date     = SYSDATE              -- �v���O�����X�V��
      WHERE  order_line_id     = gt_order_line_id(i);
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END upd_status;
--
  /***********************************************************************************
   * Procedure Name   : shipping_process
   * Description      : �o�׏��o�^����
   ***********************************************************************************/
  PROCEDURE shipping_process(
    iot_order_tbl  IN OUT order_tbl,        -- ������񃌃R�[�h�ϐ�
    ov_errbuf      OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'shipping_process'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_gen_count            NUMBER;                                        -- �󒍏��i�[�z��̌��݂̈ʒu
    lt_new_order_header_id  xxwsh_order_headers_all.order_header_id%TYPE;  -- �V�󒍃w�b�_�A�h�I��ID
    lt_new_header_id        xxwsh_order_headers_all.header_id%TYPE;        -- �V�󒍃w�b�_ID
    lt_shipped_date         xxwsh_order_headers_all.shipped_date%TYPE;     -- �o�ד�
    lv_standard_api_flag    VARCHAR2(1);                                   -- �W��API���s�t���O
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lt_order_line_tbl       order_line_type;                               -- �󒍖��׏��i�[�z��
    lt_del_rows_tbl         WSH_UTIL_CORE.ID_TAB_TYPE;                     -- ����ID
    lt_ic_tran_rec_tbl      ic_tran_rec_type;                              -- �݌Ɋ���API�p�f�[�^�ꎞ�ۑ��p�z��
    lt_mov_line_id_tbl      mov_line_id_type;                              -- �ړ�����ID�f�[�^�ꎞ�ۑ��p�z��
    lt_revised_line_tbl     revised_line_type;                             -- �����󒍖��׏��i�[�z��
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ******************************************
    -- ***  A6 �󒍍쐬API�N��(�󒍃w�b�_�o�^ ***
    -- ******************************************
    create_order_header_info(iot_order_tbl,
                             lt_new_order_header_id,
                             lt_new_header_id,
                             lt_shipped_date,
                             lv_standard_api_flag,
                             ln_gen_count,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg
    );
    IF (lv_retcode  = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ************************************************
    -- ***  A7,8 �󒍍쐬API�N��(�󒍖��׍쐬�A�o�^ ***
    -- ************************************************
    create_order_line_info(iot_order_tbl(ln_gen_count).order_header_id,
                           lt_new_order_header_id,
                           lt_new_header_id,
                           ln_gen_count,
                           iot_order_tbl,
                           lt_order_line_tbl,
                           lt_revised_line_tbl,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (lv_standard_api_flag = '1') THEN
      -- ************************************************
      -- ***  A9 �s�b�N�����[�XAPI�N��                ***
      -- ************************************************
      delivery_action_proc(lt_new_header_id,
                           lt_del_rows_tbl,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ************************************************
    -- ***  A10���b�g���擾                       ***
    -- ************************************************
    get_lot_details(lt_order_line_tbl,
                    lt_revised_line_tbl,
                    lv_standard_api_flag,
                    lt_ic_tran_rec_tbl,
                    lt_mov_line_id_tbl,
                    lv_errbuf,
                    lv_retcode,
                    lv_errmsg
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    IF (lv_standard_api_flag = '1') THEN
      -- ************************************************
      -- ***  A11�݌Ɋ���API�N��                      ***
      -- ************************************************
      set_allocate_opm_order(lt_ic_tran_rec_tbl,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
  --
      -- ************************************************
      -- ***  �ړ��I�[�_�������                      ***
      -- ************************************************
      pick_confirm_proc(lt_mov_line_id_tbl,
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
  --
      -- ************************************************
      -- ***  A12 �o�׊m�FAPI�N��                     ***
      -- ************************************************
      confirm_proc(lt_del_rows_tbl,
                   lt_shipped_date,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg
      );
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END shipping_process;
  /***********************************************************************************
   * Procedure Name   : return_process
   * Description      : �ԕi���o�^����
   ***********************************************************************************/
  PROCEDURE return_process(
    iot_order_tbl IN OUT  order_tbl,       -- ������񃌃R�[�h�ϐ�
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'return_process'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_gen_count            NUMBER;                                        -- �󒍏��i�[�z��̌��݂̈ʒu
    lt_new_order_header_id  xxwsh_order_headers_all.order_header_id%TYPE;  -- �V�󒍃w�b�_�A�h�I��ID
    lt_new_header_id        xxwsh_order_headers_all.header_id%TYPE;        -- �V�󒍃w�b�_ID
    lt_site_use_id          hz_cust_site_uses_all.site_use_id%TYPE;        -- �g�p�ړIID
    lv_standard_api_flag    VARCHAR2(1);                                   -- �W��API���s�t���O
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lt_order_line_tbl       order_line_type;                               -- �󒍖��׏��i�[�z��
    lt_revised_line_tbl     revised_line_type;                             -- �����󒍖��׏��i�[�z��
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- **********************************************
    -- ***  A13 RMA�󒍍쐬API�N��(�󒍃w�b�_�o�^ ***
    -- **********************************************
    create_rma_order_header_info(iot_order_tbl,
                                 lt_new_order_header_id,
                                 lt_new_header_id,
                                 lt_site_use_id,
                                 lv_standard_api_flag,
                                 ln_gen_count,
                                 lv_errbuf,
                                 lv_retcode,
                                 lv_errmsg
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- *****************************************************
    -- ***  A14,15 RMA�󒍍쐬API�N��(�󒍖��׍쐬�A�o�^ ***
    -- *****************************************************
    create_rma_order_line_info(iot_order_tbl(ln_gen_count).order_header_id,
                           lt_new_order_header_id,
                           lt_new_header_id,
                           lt_site_use_id,
                           ln_gen_count,
                           iot_order_tbl,
                           lt_order_line_tbl,
                           lt_revised_line_tbl,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ************************************************
    -- ***  ���b�g���쐬A-16                      ***
    -- ************************************************
    create_lot_details(lt_order_line_tbl,
                       lt_revised_line_tbl,
                       lv_standard_api_flag,
                       lv_errbuf,
                       lv_retcode,
                       lv_errmsg
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END return_process;
--
  /***********************************************************************************
   * Procedure Name   : ins_mov_lot_details
   * Description      : A18�ړ����b�g�ڍ�(�A�h�I��)�o�^
   ***********************************************************************************/
  PROCEDURE ins_mov_lot_details(
    ov_errbuf       OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mov_lot_details'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- �ړ����b�g�ڍ�(�A�h�I��)��o�^
    FORALL i IN 1 .. gn_lot_count
      INSERT INTO xxinv_mov_lot_details(
        mov_lot_dtl_id,
        mov_line_id,
        document_type_code,
        record_type_code,
        item_id,
        item_code,
        lot_id,
        lot_no,
        actual_date,
        actual_quantity,
        automanual_reserve_class,
        created_by,
        creation_date,
        last_updated_by,
        last_update_date,
        last_update_login,
        request_id,
        program_application_id,
        program_id,
        program_update_date
      )VALUES(
        gt_mov_lot_dtl_id(i),           -- ���b�g�ڍ�ID
        gt_mov_line_id(i),              -- ����ID
        gt_document_type_code(i),       -- �����^�C�v
        gt_record_type_code(i),         -- ���R�[�h�^�C�v
        gt_item_id(i),                  -- OPM�i��ID
        gt_item_code(i),                -- �i��
        gt_lot_id(i),                   -- ���b�gID
        gt_lot_no(i),                   -- ���b�gNo
        gt_actual_date(i),              -- ���ѓ�
        gt_actual_quantity(i),          -- ���ѐ���
        gt_automanual_reserve_class(i), -- �����蓮�����敪
        gn_user_id,                     -- �쐬��
        SYSDATE,                        -- �쐬��
        gn_user_id,                     -- �ŏI�X�V��
        SYSDATE,                        -- �ŏI�X�V��
        gn_login_id,                    -- �ŏI�X�V���O�C��
        gn_conc_request_id,             -- �v��ID
        gn_prog_appl_id,                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        gn_conc_program_id,             -- �R���J�����g�E�v���O����ID
        SYSDATE                         -- �v���O�����X�V��
      );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END ins_mov_lot_details;
--
  /***********************************************************************************
   * Procedure Name   : ins_transaction_interface
   * Description      : A19�������I�[�v���C���^�t�F�[�X�e�[�u���o�^����
   ***********************************************************************************/
  PROCEDURE ins_transaction_interface(
    ov_errbuf       OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_transaction_interface'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- �������I�[�v���C���^�t�F�[�X�w�b�_�ɓo�^
    FORALL h_cnt IN 1 .. gn_header_if_count
      INSERT INTO rcv_headers_interface(
        header_interface_id,
        group_id,
        processing_status_code,
        receipt_source_code,
        transaction_type,
        ship_to_organization_id,
        customer_id,
        customer_site_id,
        last_update_date,
        last_updated_by,
        creation_date,
        created_by,
        validation_flag,
        expected_receipt_date,
        last_update_login
      )VALUES(
        gt_header_interface_id(h_cnt),      -- header_interface_id
        gn_group_id,                        -- group_id
        gv_pending,                         -- processing_status_code
        gv_customer,                        -- receipt_source_code
        gv_new,                             -- transaction_type
        gt_ship_to_organization_id(h_cnt),         -- ship_to_organization_id
        gt_customer_id(h_cnt),                     -- customer_id
        gt_customer_site_id(h_cnt),                -- customer_site_id
        SYSDATE,                            -- last_update_date
        gn_user_id,                         -- last_updated_by
        SYSDATE,                            -- creation_date
        gn_user_id,                         -- created_by
        gv_yes,                             -- validation_flag
        gt_expectied_receipt_date(h_cnt),   -- expected_receipt_date
        gn_login_id                         -- last_update_login
      );
    -- �������I�[�v���C���^�t�F�[�X���ׂɓo�^
    FORALL l_cnt IN 1 .. gn_tran_if_count
      INSERT INTO rcv_transactions_interface(
        interface_transaction_id,
        group_id,
        transaction_type,
        transaction_date,
        processing_status_code,
        processing_mode_code,
        transaction_status_code,
        quantity,
        unit_of_measure,
        uom_code,
        auto_transact_code,
        receipt_source_code,
        source_document_code,
        header_interface_id,
        validation_flag,
        item_id,
        subinventory,
        locator_id,
        ship_to_location_id,
        destination_type_code,
        expected_receipt_date,
        oe_order_header_id,
        oe_order_line_id,
        creation_date,
        created_by,
        last_update_date,
        last_updated_by,
        last_update_login
      )VALUES(
        gt_interface_transaction_id(l_cnt), -- interface_transaction_id
        gn_group_id,                        -- group_id
        gv_receive,                         -- transaction_type
        gt_transaction_date(l_cnt),         -- transaction_date
        gv_pending,                         -- processing_status_code
        gv_batch,                           -- processing_mode_code
        gv_pending,                         -- transaction_status_code
        gt_quantity(l_cnt),                 -- quantity
        gt_unit_of_measure(l_cnt),          -- unit_of_measure
        gt_unit_of_measure(l_cnt),          -- uom_code
        gv_deliver,                         -- auto_transact_code
        gv_customer,                        -- receipt_source_code
        gv_rma,                             -- source_document_code
        gt_line_header_interface_id(l_cnt), -- header_interface_id
        gv_yes,                             -- validation_flag
        gt_ti_item_id(l_cnt),               -- item_id
        gt_subinventory(l_cnt),             -- subinventory
        gt_locator_id(l_cnt),               -- locator_id
        gt_ship_to_location_id(l_cnt),      -- ship_to_location_id
        gv_inventory,                       -- destination_type_code
        gt_line_exp_receipt_date(l_cnt),    -- expected_receipt_date
        gt_oe_order_header_id(l_cnt),       -- oe_order_header_id
        gt_oe_order_line_id(l_cnt),         -- oe_order_line_id
        SYSDATE,                            -- creation_date
        gn_user_id,                         -- created_by
        SYSDATE,                            -- last_update_date
        gn_user_id,                         -- last_updated_by
        gn_login_id                         -- last_update_login
      );
    -- �������I�[�v���C���^�t�F�[�X���b�g�ɓo�^
    FORALL lot_cnt IN 1 .. gn_tran_lot_if_count
      INSERT INTO mtl_transaction_lots_interface(
        transaction_interface_id,
        lot_number,
        transaction_quantity,
        primary_quantity,
        product_code,
        product_transaction_id,
        creation_date,
        created_by,
        last_update_date,
        last_updated_by,
        last_update_login
      )VALUES(
        gt_transaction_interface_id(lot_cnt), -- transaction_interface_id
        gt_lot_number(lot_cnt),               -- lot_number
        gt_transaction_quantity(lot_cnt),     -- transaction_quantity
        gt_primary_quantity(lot_cnt),         -- primary_quantity
        gv_rcv,                               -- product_code
        gt_lot_prod_transaction_id(lot_cnt),  -- product_transaction_id
        SYSDATE,                              -- creation_date
        gn_user_id,                           -- created_by
        SYSDATE,                              -- last_update_date
        gn_user_id,                           -- last_updated_by
        gn_login_id                           -- last_update_login
      );
    gn_cancell_cnt := gn_header_if_count; --����ɏ������I������ꍇ�������Z�b�g
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END ins_transaction_interface;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_block        IN VARCHAR2,             --   �u���b�N
    iv_deliver_from IN VARCHAR2,             --   �o�׌�
    iv_request_no   IN VARCHAR2,             --   �˗�No
    ov_errbuf       OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )     
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_param_name   CONSTANT VARCHAR2(100) := '�o�ד�';       -- 2008/09/01 Add
--
    -- *** ���[�J���ϐ� ***
     ln_same_request_no_count NUMBER;                                           -- ����˗�No����
     lt_old_order_header_id   xxwsh_order_headers_all.order_header_id%TYPE;     -- �󒍃w�b�_�A�h�I��ID(OLD)
--
     lt_order_tbl             order_tbl;                                        -- �󒍃f�[�^�i�[�z��
     lt_revised_order_tbl     order_tbl;                                        -- �����O�󒍃A�h�I�����i�[�z��
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_new_order_cnt     := 0;                          -- �V�K�󒍍쐬����
    gn_upd_order_cnt     := 0;                          -- �����󒍍쐬����
    gn_cancell_cnt       := 0;                          -- �����񌏐�
    gn_input_cnt         := 0;                          -- ���͌���
    gn_error_cnt         := 0;                          -- �G���[����
    gn_shori_count       := 0;                          -- A3�擾�f�[�^���݈ʒu���f�p
    gn_lot_count         := 0;                          -- �ړ����b�g�o�^�p����
    gn_header_if_count   := 0;                          -- �������I�[�v���C���^�t�F�[�X�w�b�_����
    gn_tran_if_count     := 0;                          -- �������I�[�v���C���^�t�F�[�X���׌���
    gn_tran_lot_if_count := 0;                          -- �������I�[�v���C���^�t�F�[�X���b�g����
    -- WHO�J�������擾
    gn_user_id           := FND_GLOBAL.USER_ID;         -- ���O�C�����Ă��郆�[�U�[��ID�擾
    gn_login_id          := FND_GLOBAL.LOGIN_ID;        -- �ŏI�X�V���O�C��
    gn_conc_request_id   := FND_GLOBAL.CONC_REQUEST_ID; -- �v��ID
    gn_prog_appl_id      := FND_GLOBAL.PROG_APPL_ID;    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    gn_conc_program_id   := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- A-1���̓p�����[�^�̃`�F�b�N
    -- ===============================
    input_param_check(iv_block,
                      iv_deliver_from,
                      iv_request_no,
                      lv_errbuf,
                      lv_retcode,
                      lv_errmsg
    );
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- A-2�v���t�@�C���̎擾
    -- ===============================
    get_profile(lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- A-3�󒍃A�h�I����񒊏o
    -- ===============================
    get_order_info(lt_order_tbl,
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg
    );
    IF (lv_retcode <> gv_status_normal) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ���͌�����0�����傫���ꍇ�ɏ������s��
    IF (gn_input_cnt > 0) THEN
--2008/09/01 Add ��
      -- ===============================
      -- �o�ד������������ǂ����̃`�F�b�N
      -- ===============================
      <<chk_tbl_loop>>
      FOR i IN lt_order_tbl.FIRST .. lt_order_tbl.LAST LOOP
        -- �o�ד����V�X�e�����t��薢�����̏ꍇ�G���[
        IF (lt_order_tbl(i).shipped_date > TRUNC(SYSDATE)) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                                gv_msg_42a_025,
                                                gv_tkn_para_date,
                                                lv_param_name,
                                                gv_tkn_param1,
                                                lt_order_tbl(i).delivery_no,
                                                gv_tkn_param2,
                                                lt_order_tbl(i).request_no,
                                                gv_tkn_param3,
                                                TO_CHAR(lt_order_tbl(i).shipped_date,'YYYY/MM/DD'),
                                                gv_tkn_param4,
                                                TO_CHAR(lt_order_tbl(i).arrival_date,'YYYY/MM/DD'));
          RAISE check_sub_main_expt;
        END IF;
      END LOOP chk_tbl_loop;
--2008/09/01 Add ��
--
      -- ����C���^�[�t�F�[�X�Ŏg�p����O���[�vID���擾
      SELECT rcv_interface_groups_s.NEXTVAL
      INTO   gn_group_id
      FROM   dual;

      gn_shori_count := 1; -- ���[�v�̊J�n�ʒu���w��

      <<order_data_table>> --�󒍃w�b�_��񃋁[�v����
      LOOP
        -- �w�b�_�P�ʂœo�^���鍀�ڂ�������
        gt_order_line_id.DELETE;                                                -- �󒍖��׃A�h�I��ID
        gt_line_id.DELETE;                                                      -- �󒍖���ID
        gt_header_id := NULL;
        gt_gen_request_no      := lt_order_tbl(gn_shori_count).request_no;      -- �˗�No
        gt_gen_order_header_id := lt_order_tbl(gn_shori_count).order_header_id; -- �󒍃w�b�_�A�h�I��ID
--
        -- ===============================
        -- A-4����˗�No��������
        -- ===============================
        get_same_request_number(lt_order_tbl(gn_shori_count).request_no,         -- �˗�No
                                ln_same_request_no_count,                        -- ����˗�No����
                                lt_old_order_header_id,                          -- �󒍃w�b�_�A�h�I��ID(OLD)
                                lv_errbuf,                                       -- �G���[�E���b�Z�[�W --# �Œ� #
                                lv_retcode,                                      -- ���^�[���E�R�[�h   --# �Œ� #
                                lv_errmsg                                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode <> gv_status_normal) THEN
          RAISE check_sub_main_expt;
        END IF;
--
        IF ( (lt_old_order_header_id = lt_order_tbl(gn_shori_count).order_header_id)
           OR(lt_order_tbl(gn_shori_count).shipping_shikyu_class = gv_ship_class_3)) THEN
--
          --�V�K�o�^�̏ꍇ�������͏o�׎x���敪���q�֕ԕi�̏ꍇ
          IF (lt_order_tbl(gn_shori_count).order_category_code = gv_order_type_order ) THEN
            --�󒍂̏ꍇ
            gv_shori_kbn := '1'; --�V�K�o�^��
--
            --�o�דo�^����
            shipping_process(lt_order_tbl,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg
            );
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE check_sub_main_expt;
            END IF;
--
          ELSE
            --�ԕi�̏ꍇ
            gv_shori_kbn := '2'; --�V�K�o�^�ԕi
--
            --�ԕi�o�^����
            return_process(lt_order_tbl,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg
            );
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE check_sub_main_expt;
            END IF;
--
          END IF;
          gn_new_order_cnt := gn_new_order_cnt + 1;
        ELSE
          --���������̏ꍇ
--
          -- ===================================
          -- A-5�����O�󒍃w�b�_�A�h�I�����擾
          -- ===================================
          get_revised_order_info(lt_old_order_header_id,
                                 lt_revised_order_tbl,
                                 lv_errbuf,
                                 lv_retcode,
                                 lv_errmsg
          );
          IF (lv_retcode <> gv_status_normal) THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                                  gv_msg_42a_023,
                                                  gv_tkn_order_header_id,
                                                  lt_old_order_header_id
            );
            RAISE check_sub_main_expt;
          END IF;
--
          IF (lt_order_tbl(gn_shori_count).order_category_code = gv_order_type_order ) THEN
            gv_shori_kbn := '3'; --�����o�^��
--
            --�󒍂̏ꍇ�ԕi�o�^��o�דo�^
            return_process(lt_revised_order_tbl,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg
            );
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE check_sub_main_expt;
            END IF;
--
            shipping_process(lt_order_tbl,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg
            );
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE check_sub_main_expt;
            END IF;
--
          ELSE
            gv_shori_kbn := '4'; --�����o�^�ԕi
--
            --�ԕi�̏ꍇ�o�דo�^��ԕi�o�^
            shipping_process(lt_revised_order_tbl,
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg
            );
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE check_sub_main_expt;
            END IF;
--
            return_process(lt_order_tbl,
                           lv_errbuf,
                           lv_retcode,
                           lv_errmsg
            );
            IF (lv_retcode <> gv_status_normal) THEN
              RAISE check_sub_main_expt;
            END IF;
--
          END IF;
          gn_upd_order_cnt := gn_upd_order_cnt + 1;
        END IF;
--
        -- ===================================
        -- A-17�X�e�[�^�X�X�V
        -- ===================================
        upd_status(lv_errbuf,
                   lv_retcode,
                   lv_errmsg
        );
        IF (lv_retcode <> gv_status_normal) THEN
          RAISE check_sub_main_expt;
        END IF;
--
        -- ���[�v�����锻�f
        IF (gn_shori_count > lt_order_tbl.LAST ) THEN
          EXIT;
        END IF;
      END LOOP order_data_table;
--
      -- ===================================
      -- A-18�ړ����b�g�ڍ�(�A�h�I��)�o�^
      -- ===================================
      ins_mov_lot_details(lv_errbuf,
                          lv_retcode,
                          lv_errmsg
      );
      IF (lv_retcode <> gv_status_normal) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      IF (gn_header_if_count > 0 ) THEN
        -- ==================================================
        -- A-19�������I�[�v���C���^�t�F�[�X�e�[�u���o�^����
        -- ==================================================
        ins_transaction_interface(
                            lv_errbuf,
                            lv_retcode,
                            lv_errmsg
        );
        IF (lv_retcode <> gv_status_normal) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
      COMMIT;
      IF (gn_cancell_cnt > 0 ) THEN
        -- =====================================
        -- A-20�����������N��
        -- =====================================
        gn_req_id := FND_REQUEST.SUBMIT_REQUEST(
                      application       => gv_application     -- �A�v���P�[�V�����Z�k��
                     ,program           => gv_program         -- �v���O������
                     ,argument1         => gv_batch           -- �����X�e�[�^�X
                     ,argument2         => gn_group_id        -- �p�����[�^�O�Q
                    ) ;
        IF (gn_req_id = 0) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh,
                                                gv_msg_42a_020);
          RAISE check_sub_main_expt;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN check_sub_main_expt THEN
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      gn_error_cnt := gn_error_cnt + 1;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      gn_error_cnt := gn_error_cnt + 1;
      -- �J�[�\�����J���Ă���΃N���[�Y����
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf          OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode         OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_block        IN VARCHAR2,              --   �u���b�N
    iv_deliver_from IN VARCHAR2,              --   �o�׌�
    iv_request_no   IN VARCHAR2               --   �˗�No
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
--
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_42a_001,
                                           gv_tkn_user, gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_42a_002,
                                           gv_tkn_conc, gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,  gv_msg_42a_006,
                                           gv_tkn_time, TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MM:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���擾
    gv_sep_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42a_003);
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(iv_block,        -- �u���b�N
            iv_deliver_from, --�o�׌�
            iv_request_no,   --�˗�No
            lv_errbuf,       -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,      -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_42a_005);
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���̓p�����[�^(�u���b�N)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_007, gv_tkn_in_block,
                                           iv_block);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���̓p�����[�^(�o�׌�)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_008, gv_tkn_in_shipf,
                                           iv_deliver_from);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���̓p�����[�^(�˗�No)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_009,gv_tkn_request_no,
                                           iv_request_no);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���͌����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_010, gv_tkn_input_cnt,
                                           TO_CHAR(gn_input_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�V�K�󒍍쐬�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_011, gv_tkn_new_order,
                                           TO_CHAR(gn_new_order_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�����󒍍쐬�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_012, gv_tkn_upd_order,
                                           TO_CHAR(gn_upd_order_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�����񌏐��o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_013, gv_tkn_cancell_cnt,
                                           TO_CHAR(gn_cancell_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�ُ팏���o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_014, gv_tkn_error_cnt,
                                           TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�����������R���J�����g�v��ID
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_wsh, gv_msg_42a_015, gv_tkn_request_id,
                                           TO_CHAR(gn_req_id));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn,    gv_msg_42a_004,
                                           gv_tkn_status, gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh420001c;
/
