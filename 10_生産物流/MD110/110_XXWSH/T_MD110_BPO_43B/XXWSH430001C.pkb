CREATE OR REPLACE PACKAGE BODY xxwsh430001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh430001c(body)
 * Description      : �q�֕ԕi���C���^�[�t�F�[�X
 * MD.050           : �q�֕ԕi T_MD050_BPO_430
 * MD.070           : �q�֕ԕi���C���^�[�t�F�[�X T_MD070_BPO_43B
 * Version          : 1.10
 *
 * Program List
 * -------------------------  ----------------------------------------------------------
 *  Name                      Description
 * -------------------------  ----------------------------------------------------------
 *  get_profile               �v���t�@�C���擾���� (A-1)
 *  get_reserve_interface     �q�֕ԕi�C���^�[�t�@�C�X��񒊏o���� (A-2)
 *  check_master              �}�X�^���݃`�F�b�N���� (A-3)
 *  check_stock               �݌ɉ�v���ԃ`�F�b�N���� (A-4)
 *  get_order_type            �֘A�f�[�^�擾���� (A-5)
 *  get_order_all_tbl         ����˗�No��񒊏o���� (A-6)
 *  set_del_headers           �q�֕ԕi�ŏ����(�w�b�_)�쐬���� (A-7)
 *  set_del_lines             �q�֕ԕi�ŏ����(����)�쐬���� (A-8)
 *  set_order_headers         �q�֕ԕi���(�w�b�_)�쐬���� (A-9)
 *  set_latest_external_flag  �ŐV�t���O�X�V���쐬���� (A-10)
 *  set_order_lines           �q�֕ԕi���(����)�쐬���� (A-11)
 *  set_upd_order_headers     �q�֕ԕi�X�V���(�w�b�_)�쐬���� (A-12)
 *  set_upd_order_lines       �q�֕ԕi�X�V���(����)�쐬���� (A-13)
 *  ins_order                 �q�֕ԕi���o�^���� (A-14)
 *  sum_lines_quantity        �q�֕ԕi���o���v���� (A-15)
 *  upd_headers_sum_quantity  �q�֕ԕi���ēo�^���� (A-16)
 *  del_reserve_interface     �q�֕ԕi�C���^�[�t�F�[�X���폜���� (A-17)
 *  submain                   ���C�������v���V�[�W��
 *  main                      �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/07    1.0   ORACLE���c����   ����쐬
 *  2008/05/16    1.1   ORACLE�Γn���a   �}�X�^��View�Q�Ƃ���悤�ύX
 *                                       �󒍖��׃A�h�I���̏o�וi��ID�^�˗��i��ID��
 *                                       inventory_item_id���Z�b�g����悤�ύX
 *  2008/05/20    1.2   ORACLE�Ŗ����\   �����ύX�v��#106�Ή�
 *  2008/06/19    1.3   ORACLE�Γn���a   �t���O�̃f�t�H���g�l���Z�b�g
 *  2008/08/07    1.4   ORACLE�R����_   �ۑ�#32,�ۑ�#67�ύX#174�Ή�
 *  2008/10/10    1.5   ORACLE��������   T_S_474�Ή�
 *  2008/11/25    1.6   ORACLE�g������   �{�Ԗ⍇��#243�Ή�
 *  2008/12/22    1.7   ORACLE�Ŗ����\   �{�Ԗ⍇��#743�Ή�
 *  2009/01/06    1.8   Yuko Kawano      �{�Ԗ⍇��#908�Ή�
 *  2009/01/13    1.9   Hitomi Itou      �{�Ԗ⍇��#981�Ή�
 *  2009/01/15    1.10  Masayoshi Uehara �{�Ԗ⍇��#1019�Ή�
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
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
--
--################################  �Œ蕔 END   ###############################
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
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
--###########################  �Œ蕔 END   ############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  no_data_expt           EXCEPTION;        -- �����Ώۃf�[�^0���i�x���j
  lock_expt              EXCEPTION;        -- ���b�N�擾��O
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name          CONSTANT VARCHAR2(100) := 'xxwsh430001c';            -- �p�b�P�[�W��
  gv_xxwsh             CONSTANT VARCHAR2(100) := 'XXWSH';                   -- �A�v���P�[�V�����Z�k��
  gv_reserve_interface CONSTANT VARCHAR2(100) := 'xxwsh_reserve_interface'; -- �q�֕ԕi�C���^�[�t�F�[�X
  --gv_cate_return       CONSTANT VARCHAR2(10)  := '�ԕi';                    -- �󒍃J�e�S�� �ԕi
  --gv_cate_order        CONSTANT VARCHAR2(10)  := '�q��';                    -- �󒍃J�e�S�� ��
  gv_cate_return       CONSTANT VARCHAR2(10)  := 'RETURN';                  -- �󒍃J�e�S�� �ԕi
  gv_cate_order        CONSTANT VARCHAR2(10)  := 'ORDER';                   -- �󒍃J�e�S�� ��
  gv_flag_on           CONSTANT VARCHAR2(1)   := 'Y';
  gv_flag_off          CONSTANT VARCHAR2(1)   := 'N';
--
  -- ���b�Z�[�W
  -- �v���t�@�C���擾�G���[���b�Z�[�W
  gv_xxwsh_noprof_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11601';
  -- �J�e�S���G���[
  gv_xxwsh_category_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11602';
  -- �}�X�^�`�F�b�N�G���[
  gv_xxwsh_mst_chk_err          CONSTANT VARCHAR2(100) := 'APP-XXWSH-11603';
  -- ���b�N�G���[
  gv_xxwsh_table_lock_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-11604';
  -- �Ώۃf�[�^����
  gv_xxwsh_nodata_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11605';
  -- ����`�[No���w�b�_����G���[���b�Z�[�W
  gv_xxwsh_invoice_no_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-11606';
  -- �݌ɉ�v���ԃG���[���b�Z�[�W
  gv_xxwsh_stock_from_err       CONSTANT VARCHAR2(100) := 'APP-XXWSH-11607';
  -- �݌ɉ�v���Ԏ擾�G���[���b�Z�[�W
  gv_xxwsh_stock_get_err        CONSTANT VARCHAR2(100) := 'APP-XXWSH-11608';
  -- ���i�敪�擾�G���[
  gv_xxwsh_prod_get_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11609';
  -- �w�b�_���ڕύX�G���[
  gv_xxwsh_hd_upd_err           CONSTANT VARCHAR2(100) := 'APP-XXWSH-11610';
  -- �󒍃^�C�v�擾�G���[���b�Z�[�W
  gv_xxwsh_type_get_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11611';
  -- �������݃G���[���b�Z�[�W
  gv_xxwsh_num_mix_err          CONSTANT VARCHAR2(100) := 'APP-XXWSH-11612';
  -- ���ʊ֐��˗�No�ϊ��G���[���b�Z�[�W
  gv_xxwsh_request_no_conv_err  CONSTANT VARCHAR2(100) := 'APP-XXWSH-11613';
  -- ���ʊ֐��e�[�u���폜�G���[���b�Z�[�W
  gv_xxwsh_truncate_err         CONSTANT VARCHAR2(100) := 'APP-XXWSH-11614';
  -- ���ʊ֐�OPM�݌ɉ�v����CLOSE�N���擾�G���[���b�Z�[�W
  gv_xxwsh_closeym_err          CONSTANT VARCHAR2(100) := 'APP-XXWSH-11615';
  -- ���͌���(�q�֕ԕi�C���^�[�t�F�[�X�j)
  gv_xxwsh_input_reserve_cnt    CONSTANT VARCHAR2(100) := 'APP-XXWSH-11616';
  -- �q�֕ԕi���쐬����(�󒍃w�b�_�A�h�I���P��)
  gv_xxwsh_output_headers_cnt   CONSTANT VARCHAR2(100) := 'APP-XXWSH-11617';
  -- �q�֕ԕi���쐬����(�󒍖��׃A�h�I���P��)
  gv_xxwsh_output_lines_cnt     CONSTANT VARCHAR2(100) := 'APP-XXWSH-11618';
  -- �q�֕ԕi���쐬����(�ړ����b�g�ڍגP��)
  gv_xxwsh_output_lot_cnt       CONSTANT VARCHAR2(100) := 'APP-XXWSH-11623';
  -- �q�֕ԕi�ŏ����쐬����(�󒍃w�b�_�A�h�I���P��)
  gv_xxwsh_output_del_hd_cnt    CONSTANT VARCHAR2(100) := 'APP-XXWSH-11619';
  -- �q�֕ԕi�ŏ����쐬����(�󒍖��׃A�h�I���P��)
  gv_xxwsh_output_del_ln_cnt    CONSTANT VARCHAR2(100) := 'APP-XXWSH-11620';
  -- �q�֕ԕi�ŏ����쐬����(�ړ����b�g�ڍגP��)
  gv_xxwsh_output_del_lot_cnt   CONSTANT VARCHAR2(100) := 'APP-XXWSH-11624';
  -- �q�֕ԕi�X�V���쐬����(�󒍃w�b�_�A�h�I���P��)
  gv_xxwsh_output_upd_hd_cnt    CONSTANT VARCHAR2(100) := 'APP-XXWSH-11621';
  -- �q�֕ԕi�X�V���쐬����(�󒍖��׃A�h�I���P��)
  gv_xxwsh_output_upd_ln_cnt    CONSTANT VARCHAR2(100) := 'APP-XXWSH-11622';
--
  -- �g�[�N��
  gv_tkn_cnt           CONSTANT VARCHAR2(100) := 'CNT';
  gv_tkn_table         CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_colmun        CONSTANT VARCHAR2(100) := 'COLMUN';
  gv_tkn_prof_name     CONSTANT VARCHAR2(100) := 'PROF_NAME';
  gv_tkn_ctg_name      CONSTANT VARCHAR2(100) := 'CTG_NAME';
  gv_tkn_den_no        CONSTANT VARCHAR2(100) := 'DEN_NO';
  gv_tkn_input_item    CONSTANT VARCHAR2(100) := 'INPUT_ITEM';
  gv_tkn_arrival_date  CONSTANT VARCHAR2(100) := 'ARRIVAL_DATE';
--
  --�v���t�@�C��
  gv_prf_org_id      CONSTANT VARCHAR2(50) := 'XXCMN_MASTER_ORG_ID';    -- �}�X�^�[�g�DID
  gv_prf_max_date    CONSTANT VARCHAR2(50) := 'XXCMN_MAX_DATE';         -- MAX���t
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �q�֕ԕi�C���^�[�t�F�[�X���i�[�p(A-1)
  TYPE reserve_interface_rec IS RECORD(
    recorded_year      xxwsh_reserve_interface.recorded_year%TYPE,     -- �v��N��
    input_base_code    xxwsh_reserve_interface.input_base_code%TYPE,   -- ���͋��_�R�[�h
    receive_base_code  xxwsh_reserve_interface.receive_base_code%TYPE, -- ���苒�_�R�[�ho
    invoice_class_1    xxwsh_reserve_interface.invoice_class_1%TYPE,   -- �`��P
    recorded_date      xxwsh_reserve_interface.recorded_date%TYPE,     -- �v����t(����)
    invoice_no         xxwsh_reserve_interface.invoice_no%TYPE,        -- �`�[No
    item_no            ic_item_mst_b.item_no%TYPE,                     -- �i�ڃR�[�h
    quantity_total     xxwsh_reserve_interface.quantity%TYPE           -- ����
  );
--
  TYPE reserve_interface_tbl IS TABLE OF reserve_interface_rec INDEX BY PLS_INTEGER;
--
  -- �󒍃w�b�_�A�h�I���E�󒍖��׃A�h�I���i�[�p(A-6)
  TYPE order_all_rec IS RECORD(
     hd_order_header_id       xxwsh_order_headers_all.order_header_id%TYPE,       -- �󒍃w�b�_�A�h�I��ID
     hd_order_type_id         xxwsh_order_headers_all.order_type_id%TYPE,         -- �󒍃^�C�vID
     hd_organization_id       xxwsh_order_headers_all.organization_id%TYPE,       -- �g�DID
     hd_latest_external_flag  xxwsh_order_headers_all.latest_external_flag%TYPE,  -- �ŐV�t���O
     hd_ordered_date          xxwsh_order_headers_all.ordered_date%TYPE,          -- �󒍓�
     hd_customer_id           xxwsh_order_headers_all.customer_id%TYPE,           -- �ڋqID
     hd_customer_code         xxwsh_order_headers_all.customer_code%TYPE,         -- �ڋq
     hd_deliver_to_id         xxwsh_order_headers_all.deliver_to_id%TYPE,         -- �o�א�ID
     hd_deliver_to            xxwsh_order_headers_all.deliver_to%TYPE,            -- �o�א�
     hd_shipping_instructions xxwsh_order_headers_all.shipping_instructions%TYPE, -- �o�׎w��
     hd_request_no            xxwsh_order_headers_all.request_no%TYPE,            -- �˗�No
     hd_req_status            xxwsh_order_headers_all.req_status%TYPE,            -- �X�e�[�^�X
     hd_schedule_ship_date    xxwsh_order_headers_all.schedule_ship_date%TYPE,    -- �o�ח\���
     hd_schedule_arrival_date xxwsh_order_headers_all.schedule_arrival_date%TYPE, -- ���ח\���
     hd_deliver_from_id       xxwsh_order_headers_all.deliver_from_id%TYPE,       -- �o�׌�ID
     hd_deliver_from          xxwsh_order_headers_all.deliver_from%TYPE,          -- �o�׌��ۊǏꏊ
     hd_head_sales_branch     xxwsh_order_headers_all.head_sales_branch%TYPE,     -- �Ǌ����_
     hd_prod_class            xxwsh_order_headers_all.prod_class%TYPE,            -- ���i�敪
     hd_sum_quantity          xxwsh_order_headers_all.sum_quantity%TYPE,          -- ���v����
     hd_result_deliver_to_id  xxwsh_order_headers_all.result_deliver_to_id%TYPE,  -- �o�א�_����ID
     hd_result_deliver_to     xxwsh_order_headers_all.result_deliver_to%TYPE,     -- �o�א�_����
     hd_shipped_date          xxwsh_order_headers_all.shipped_date%TYPE,          -- �o�ד�
     hd_arrival_date          xxwsh_order_headers_all.arrival_date%TYPE,          -- ���ד�
--2008/08/07 Add ��
     hd_actual_confirm_class  xxwsh_order_headers_all.actual_confirm_class%TYPE,  -- ���ьv��ϋ敪
--2008/08/07 Add ��
     hd_perform_management_dept xxwsh_order_headers_all.performance_management_dept%TYPE, -- ���ъǗ�����
     hd_registered_sequence    xxwsh_order_headers_all.registered_sequence%TYPE,  -- �o�^����
     hd_created_by             xxwsh_order_headers_all.created_by%TYPE,           -- �쐬��
     hd_creation_date          xxwsh_order_headers_all.creation_date%TYPE,        -- �쐬��
     hd_last_updated_by        xxwsh_order_headers_all.last_updated_by%TYPE,      -- �ŏI�X�V��
     hd_last_update_date       xxwsh_order_headers_all.last_update_date%TYPE,     -- �ŏI�X�V��
     hd_last_update_login      xxwsh_order_headers_all.last_update_login%TYPE,    -- �ŏI�X�V���O�C��
     hd_request_id             xxwsh_order_headers_all.request_id%TYPE,           -- �v��ID
     hd_program_application_id xxwsh_order_headers_all.program_application_id%TYPE,-- �A�v���P�[�V����ID
     hd_program_id             xxwsh_order_headers_all.program_id%TYPE,           -- �R���J�����g�E�v���O����ID
     hd_program_update_date    xxwsh_order_headers_all.program_update_date%TYPE,  -- �v���O�����X�V��
--
     ln_order_line_id          xxwsh_order_lines_all.order_line_id%TYPE,          -- �󒍖��׃A�h�I��ID
     ln_order_header_id        xxwsh_order_lines_all.order_header_id%TYPE,        -- �󒍃w�b�_�A�h�I��ID
     ln_order_line_number      xxwsh_order_lines_all.order_line_number%TYPE,      -- ���הԍ�
     ln_request_no             xxwsh_order_lines_all.request_no%TYPE,             -- �˗�No
     ln_shipping_inventory_item_id xxwsh_order_lines_all.shipping_inventory_item_id%TYPE, -- �o�וi��ID
     ln_shipping_item_code     xxwsh_order_lines_all.shipping_item_code%TYPE,     -- �o�וi��
     ln_quantity               xxwsh_order_lines_all.quantity%TYPE,               -- ����
     ln_add_quantity           xxwsh_order_lines_all.quantity%TYPE,               -- ���Z�p����
     ln_uom_code               xxwsh_order_lines_all.uom_code%TYPE,               -- �P��
     ln_shipped_quantity       xxwsh_order_lines_all.shipped_quantity%TYPE,       -- �o�׎��ѐ���
     ln_based_request_quantity xxwsh_order_lines_all.based_request_quantity%TYPE, -- ���_�˗�����
     ln_request_item_id        xxwsh_order_lines_all.request_item_id%TYPE,        -- �˗��i��ID
     ln_request_item_code      xxwsh_order_lines_all.request_item_code%TYPE,      -- �˗��i��
     ln_rm_if_flg              xxwsh_order_lines_all.rm_if_flg%TYPE,              -- �q�֕ԕi�C���^�t�F�[�X�σt���O
     ln_created_by             xxwsh_order_lines_all.created_by%TYPE,             -- �쐬��
     ln_creation_date          xxwsh_order_lines_all.creation_date%TYPE,          -- �쐬��
     ln_last_updated_by        xxwsh_order_lines_all.last_updated_by%TYPE,        -- �ŏI�X�V��
     ln_last_update_date       xxwsh_order_lines_all.last_update_date%TYPE,       -- �ŏI�X�V��
     ln_last_update_login      xxwsh_order_lines_all.last_update_login%TYPE,      -- �ŏI�X�V���O�C��
     ln_request_id             xxwsh_order_lines_all.request_id%TYPE,             -- �v��ID
     ln_program_application_id xxwsh_order_lines_all.program_application_id%TYPE, -- �A�v���P�[�V����ID
     ln_program_id             xxwsh_order_lines_all.program_id%TYPE,             -- �R���J�����g�E�v���O����ID
     ln_program_update_date    xxwsh_order_lines_all.program_update_date%TYPE,    -- �v���O�����X�V��
--
     lo_mov_lot_dtl_id           xxinv_mov_lot_details.mov_lot_dtl_id%TYPE,       -- ���b�g�ڍ�ID
     lo_mov_line_id              xxinv_mov_lot_details.mov_line_id%TYPE,          -- ����ID
     lo_document_type_code       xxinv_mov_lot_details.document_type_code%TYPE,   -- �����^�C�v
     lo_record_type_code         xxinv_mov_lot_details.record_type_code%TYPE,     -- ���R�[�h�^�C�v
     lo_item_id                  xxinv_mov_lot_details.item_id%TYPE,              -- OPM�i��ID
     lo_item_code                xxinv_mov_lot_details.item_code%TYPE,            -- �i��
     lo_lot_id                   xxinv_mov_lot_details.lot_id%TYPE,               -- ���b�gID
     lo_lot_no                   xxinv_mov_lot_details.lot_no%TYPE,               -- ���b�gNo
     lo_actual_date              xxinv_mov_lot_details.actual_date%TYPE,          -- ���ѓ�
     lo_actual_quantity          xxinv_mov_lot_details.actual_quantity%TYPE,      -- ���ѐ���
     lo_automanual_reserve_class xxinv_mov_lot_details.automanual_reserve_class%TYPE, -- �����蓮�����敪
     lo_created_by               xxinv_mov_lot_details.created_by%TYPE,           -- �쐬��
     lo_creation_date            xxinv_mov_lot_details.creation_date%TYPE,        -- �쐬��
     lo_last_updated_by          xxinv_mov_lot_details.last_updated_by%TYPE,      -- �ŏI�X�V��
     lo_last_update_date         xxinv_mov_lot_details.last_update_date%TYPE,     -- �ŏI�X�V��
     lo_last_update_login        xxinv_mov_lot_details.last_update_login%TYPE,    -- �ŏI�X�V���O�C��
     lo_request_id               xxinv_mov_lot_details.request_id%TYPE,           -- �v��ID
     lo_program_application_id   xxinv_mov_lot_details.program_application_id%TYPE, -- �A�v���P�[�V����ID
     lo_program_id               xxinv_mov_lot_details.program_id%TYPE,           -- �R���J�����g�E�v���O����ID
     lo_program_update_date      xxinv_mov_lot_details.program_update_date%TYPE   -- �v���O�����X�V��
  );
--
  TYPE order_all_tbl IS TABLE OF order_all_rec INDEX BY PLS_INTEGER;
--
  -- �󒍃w�b�_�A�h�I��
  -- �󒍃w�b�_�A�h�I��ID
  TYPE xoh_order_header_id
    IS TABLE OF xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃^�C�vID
  TYPE xoh_order_type_id
    IS TABLE OF xxwsh_order_headers_all.order_type_id%TYPE INDEX BY BINARY_INTEGER;
  -- �g�DID
  TYPE xoh_organization_id
    IS TABLE OF xxwsh_order_headers_all.organization_id%TYPE INDEX BY BINARY_INTEGER;
  -- �ŐV�t���O
  TYPE xoh_latest_external_flag
    IS TABLE OF xxwsh_order_headers_all.latest_external_flag%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍓�
  TYPE xoh_ordered_date
    IS TABLE OF xxwsh_order_headers_all.ordered_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ڋqID
  TYPE xoh_customer_id
    IS TABLE OF xxwsh_order_headers_all.customer_id%TYPE INDEX BY BINARY_INTEGER;
  -- �ڋq
  TYPE xoh_customer_code
    IS TABLE OF xxwsh_order_headers_all.customer_code%TYPE INDEX BY BINARY_INTEGER;
  -- �o�א�ID
  TYPE xoh_deliver_to_id
    IS TABLE OF xxwsh_order_headers_all.deliver_to_id%TYPE INDEX BY BINARY_INTEGER;
  -- �o�א�
  TYPE xoh_deliver_to
    IS TABLE OF xxwsh_order_headers_all.deliver_to%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׎w��
  TYPE xoh_shipping_instructions
    IS TABLE OF xxwsh_order_headers_all.shipping_instructions%TYPE INDEX BY BINARY_INTEGER;
  -- �˗�No
  TYPE xoh_request_no
    IS TABLE OF xxwsh_order_headers_all.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- �X�e�[�^�X
  TYPE xoh_req_status
    IS TABLE OF xxwsh_order_headers_all.req_status%TYPE INDEX BY BINARY_INTEGER;
  -- �o�ח\���
  TYPE xoh_schedule_ship_date
    IS TABLE OF xxwsh_order_headers_all.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;
  -- ���ח\���
  TYPE xoh_schedule_arrival_date
    IS TABLE OF xxwsh_order_headers_all.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׌�ID
  TYPE xoh_deliver_from_id
    IS TABLE OF xxwsh_order_headers_all.deliver_from_id%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׌��ۊǏꏊ
  TYPE xoh_deliver_from
    IS TABLE OF xxwsh_order_headers_all.deliver_from%TYPE INDEX BY BINARY_INTEGER;
  -- �Ǌ����_
  TYPE xoh_head_sales_branch
    IS TABLE OF xxwsh_order_headers_all.head_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE xoh_prod_class
    IS TABLE OF xxwsh_order_headers_all.prod_class%TYPE INDEX BY BINARY_INTEGER;
  -- ���v����
  TYPE xoh_sum_quantity
    IS TABLE OF xxwsh_order_headers_all.sum_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �o�א�_����ID
  TYPE xoh_result_deliver_to_id
    IS TABLE OF xxwsh_order_headers_all.result_deliver_to_id%TYPE INDEX BY BINARY_INTEGER;
  -- �o�א�_����
  TYPE xoh_result_deliver_to
    IS TABLE OF xxwsh_order_headers_all.result_deliver_to%TYPE INDEX BY BINARY_INTEGER;
  -- �o�ד�
  TYPE xoh_shipped_date
    IS TABLE OF xxwsh_order_headers_all.shipped_date%TYPE INDEX BY BINARY_INTEGER;
  -- ���ד�
  TYPE xoh_arrival_date
    IS TABLE OF xxwsh_order_headers_all.arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- ���ъǗ�����
  TYPE xoh_perform_management_dept
    IS TABLE OF xxwsh_order_headers_all.performance_management_dept%TYPE INDEX BY BINARY_INTEGER;
  -- �o�^����
  TYPE xoh_registered_sequence
    IS TABLE OF xxwsh_order_headers_all.registered_sequence%TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE xoh_created_by
    IS TABLE OF xxwsh_order_headers_all.created_by%TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE xoh_creation_date
    IS TABLE OF xxwsh_order_headers_all.creation_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE xoh_last_updated_by
    IS TABLE OF xxwsh_order_headers_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE xoh_last_update_date
    IS TABLE OF xxwsh_order_headers_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V���O�C��
  TYPE xoh_last_update_login
    IS TABLE OF xxwsh_order_headers_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  -- �v��ID
  TYPE xoh_request_id
    IS TABLE OF xxwsh_order_headers_all.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  TYPE xoh_program_application_id
    IS TABLE OF xxwsh_order_headers_all.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- �R���J�����g�E�v���O����ID
  TYPE xoh_program_id
    IS TABLE OF xxwsh_order_headers_all.program_id%TYPE INDEX BY BINARY_INTEGER;
  -- �v���O�����X�V��
  TYPE xoh_program_update_date
    IS TABLE OF xxwsh_order_headers_all.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
-- �󒍃w�b�_�A�h�I���ꊇ�o�^�p
  gt_xoh_order_header_id         xoh_order_header_id;             -- �󒍃w�b�_�A�h�I��ID
  gt_xoh_order_type_id           xoh_order_type_id;               -- �󒍃^�C�vID
  gt_xoh_organization_id         xoh_organization_id;             -- �g�DID
  gt_xoh_latest_external_flag    xoh_latest_external_flag;        -- �ŐV�t���O
  gt_xoh_ordered_date            xoh_ordered_date;                -- �󒍓�
  gt_xoh_customer_id             xoh_customer_id;                 -- �ڋqID
  gt_xoh_customer_code           xoh_customer_code;               -- �ڋq
  gt_xoh_deliver_to_id           xoh_deliver_to_id;               -- �o�א�ID
  gt_xoh_deliver_to              xoh_deliver_to;                  -- �o�א�
  gt_xoh_shipping_instructions   xoh_shipping_instructions;       -- �o�׎w��
  gt_xoh_request_no              xoh_request_no;                  -- �˗�No
  gt_xoh_req_status              xoh_req_status;                  -- �X�e�[�^�X
  gt_xoh_schedule_ship_date      xoh_schedule_ship_date;          -- �o�ח\���
  gt_xoh_schedule_arrival_date   xoh_schedule_arrival_date;       -- ���ח\���
  gt_xoh_deliver_from_id         xoh_deliver_from_id;             -- �o�׌�ID
  gt_xoh_deliver_from            xoh_deliver_from;                -- �o�׌��ۊǏꏊ
  gt_xoh_head_sales_branch       xoh_head_sales_branch;           -- �Ǌ����_
  gt_xoh_prod_class              xoh_prod_class;                  -- ���i�敪
  gt_xoh_sum_quantity            xoh_sum_quantity;                -- ���v����
  gt_xoh_result_deliver_to_id    xoh_result_deliver_to_id;        -- �o�א�_����ID
  gt_xoh_result_deliver_to       xoh_result_deliver_to;           -- �o�א�_����
  gt_xoh_shipped_date            xoh_shipped_date;                -- �o�ד�
  gt_xoh_arrival_date            xoh_arrival_date;                -- ���ד�
  gt_xoh_perform_management_dept xoh_perform_management_dept;     -- ���ъǗ�����
  gt_xoh_registered_sequence     xoh_registered_sequence;         -- �o�^����
  gt_xoh_created_by              xoh_created_by;                  -- �쐬��
  gt_xoh_creation_date           xoh_creation_date;               -- �쐬��
  gt_xoh_last_updated_by         xoh_last_updated_by;             -- �ŏI�X�V��
  gt_xoh_last_update_date        xoh_last_update_date;            -- �ŏI�X�V��
  gt_xoh_last_update_login       xoh_last_update_login;           -- �ŏI�X�V���O�C��
  gt_xoh_request_id              xoh_request_id;                  -- �v��ID
  gt_xoh_program_application_id  xoh_program_application_id;      -- �A�v���P�[�V����ID
  gt_xoh_program_id              xoh_program_id;                  -- �R���J�����g�E�v���O����ID
  gt_xoh_program_update_date     xoh_program_update_date;         -- �v���O�����X�V��
--
  -- �󒍖��׃A�h�I��
  -- �󒍖��׃A�h�I��ID
  TYPE xol_order_line_id
    IS TABLE OF xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃w�b�_�A�h�I��ID
  TYPE xol_order_header_id
    IS TABLE OF xxwsh_order_lines_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���הԍ�
  TYPE xol_order_line_number
    IS TABLE OF xxwsh_order_lines_all.order_line_number%TYPE INDEX BY BINARY_INTEGER;
  -- �˗�No
  TYPE xol_request_no
    IS TABLE OF xxwsh_order_lines_all.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- �o�וi��ID
  TYPE xol_shipping_item_id
    IS TABLE OF xxwsh_order_lines_all.shipping_inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- �o�וi��
  TYPE xol_shipping_item_code
    IS TABLE OF xxwsh_order_lines_all.shipping_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ����
  TYPE xol_quantity
    IS TABLE OF xxwsh_order_lines_all.quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �P��
  TYPE xol_uom_code
    IS TABLE OF xxwsh_order_lines_all.uom_code%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׎��ѐ���
  TYPE xol_shipped_quantity
    IS TABLE OF xxwsh_order_lines_all.shipped_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ���_�˗�����
  TYPE xol_based_request_quantity
    IS TABLE OF xxwsh_order_lines_all.based_request_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �˗��i��ID
  TYPE xol_request_item_id
    IS TABLE OF xxwsh_order_lines_all.request_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- �˗��i��
  TYPE xol_request_item_code
    IS TABLE OF xxwsh_order_lines_all.request_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- �q�֕ԕi�C���^�t�F�[�X�σt���O
  TYPE xol_rm_if_flg
    IS TABLE OF xxwsh_order_lines_all.rm_if_flg%TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE xol_created_by
    IS TABLE OF xxwsh_order_lines_all.created_by%TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE xol_creation_date
    IS TABLE OF xxwsh_order_lines_all.creation_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE xol_last_updated_by
    IS TABLE OF xxwsh_order_lines_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE xol_last_update_date
    IS TABLE OF xxwsh_order_lines_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V���O�C��
  TYPE xol_last_update_login
    IS TABLE OF xxwsh_order_lines_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  -- �v��ID
  TYPE xol_request_id
    IS TABLE OF xxwsh_order_lines_all.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  TYPE xol_program_application_id
    IS TABLE OF xxwsh_order_lines_all.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- �R���J�����g�E�v���O����ID
  TYPE xol_program_id
    IS TABLE OF xxwsh_order_lines_all.program_id%TYPE INDEX BY BINARY_INTEGER;
  -- �v���O�����X�V��
  TYPE xol_program_update_date
    IS TABLE OF xxwsh_order_lines_all.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
-- �󒍖��׃A�h�I���ꊇ�o�^�p
  gt_xol_order_line_id           xol_order_line_id;              -- �󒍖��׃A�h�I��ID
  gt_xol_order_header_id         xol_order_header_id;            -- �󒍃w�b�_�A�h�I��ID
  gt_xol_order_line_number       xol_order_line_number;          -- ���הԍ�
  gt_xol_request_no              xol_request_no;                 -- �˗�No
  gt_xol_shipping_item_id        xol_shipping_item_id;           -- �o�וi��ID
  gt_xol_shipping_item_code      xol_shipping_item_code;         -- �o�וi��
  gt_xol_quantity                xol_quantity;                   -- ����
  gt_xol_uom_code                xol_uom_code;                   -- �P��
  gt_xol_shipped_quantity        xol_shipped_quantity;           -- �o�׎��ѐ���
  gt_xol_based_request_quantity  xol_based_request_quantity;     -- ���_�˗�����
  gt_xol_request_item_id         xol_request_item_id;            -- �˗��i��ID
  gt_xol_request_item_code       xol_request_item_code;          -- �˗��i��
  gt_xol_rm_if_flg               xol_rm_if_flg;                  -- �q�֕ԕi�C���^�t�F�[�X�σt���O
  gt_xol_created_by              xol_created_by;                 -- �쐬��
  gt_xol_creation_date           xol_creation_date;              -- �쐬��
  gt_xol_last_updated_by         xol_last_updated_by;            -- �ŏI�X�V��
  gt_xol_last_update_date        xol_last_update_date;           -- �ŏI�X�V��
  gt_xol_last_update_login       xol_last_update_login;          -- �ŏI�X�V���O�C��
  gt_xol_request_id              xol_request_id;                 -- �v��ID
  gt_xol_program_application_id  xol_program_application_id;     -- �A�v���P�[�V����ID
  gt_xol_program_id              xol_program_id;                 -- �R���J�����g�E�v���O����ID
  gt_xol_program_update_date     xol_program_update_date;        -- �v���O�����X�V��
--
  -- �ړ����b�g�ڍ�
  -- ���b�g�ڍ�ID
  TYPE xml_mov_lot_dtl_id
    IS TABLE OF xxinv_mov_lot_details.mov_lot_dtl_id%TYPE INDEX BY BINARY_INTEGER;
  -- ����ID
  TYPE xml_mov_line_id
    IS TABLE OF xxinv_mov_lot_details.mov_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- �����^�C�v
  TYPE xml_document_type_code
    IS TABLE OF xxinv_mov_lot_details.mov_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���R�[�h�^�C�v
  TYPE xml_record_type_code
    IS TABLE OF xxinv_mov_lot_details.record_type_code%TYPE INDEX BY BINARY_INTEGER;
  -- OPM�i��ID
  TYPE xml_item_id
    IS TABLE OF xxinv_mov_lot_details.item_id%TYPE INDEX BY BINARY_INTEGER;
  -- �i��
  TYPE xml_item_code
    IS TABLE OF xxinv_mov_lot_details.item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ���b�gID
  TYPE xml_lot_id
    IS TABLE OF xxinv_mov_lot_details.lot_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���b�gNo
  TYPE xml_lot_no
    IS TABLE OF xxinv_mov_lot_details.lot_no%TYPE INDEX BY BINARY_INTEGER;
  -- ���ѓ�
  TYPE xml_actual_date
    IS TABLE OF xxinv_mov_lot_details.actual_date%TYPE INDEX BY BINARY_INTEGER;
  -- ���ѐ���
  TYPE xml_actual_quantity
    IS TABLE OF xxinv_mov_lot_details.actual_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �����蓮�����敪
  TYPE xml_automanual_rsv_class
    IS TABLE OF xxinv_mov_lot_details.automanual_reserve_class%TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE xml_created_by
    IS TABLE OF xxinv_mov_lot_details.created_by%TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE xml_creation_date
    IS TABLE OF xxinv_mov_lot_details.creation_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE xml_last_updated_by
    IS TABLE OF xxinv_mov_lot_details.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE xml_last_update_date
    IS TABLE OF xxinv_mov_lot_details.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V���O�C��
  TYPE xml_last_update_login
    IS TABLE OF xxinv_mov_lot_details.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  -- �v��ID
  TYPE xml_request_id
    IS TABLE OF xxinv_mov_lot_details.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- �A�v���P�[�V����ID
  TYPE xml_program_application_id
    IS TABLE OF xxinv_mov_lot_details.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- �R���J�����g�E�v���O����ID
  TYPE xml_program_id
    IS TABLE OF xxinv_mov_lot_details.program_id%TYPE INDEX BY BINARY_INTEGER;
  -- �v���O�����X�V��
  TYPE xml_program_update_date
    IS TABLE OF xxinv_mov_lot_details.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
-- �ړ����b�g�ڍ׈ꊇ�o�^�p
  gt_xml_mov_lot_dtl_id            xml_mov_lot_dtl_id;            -- ���b�g�ڍ�ID
  gt_xml_mov_line_id               xml_mov_line_id;               -- ����ID
  gt_xml_document_type_code        xml_document_type_code;        -- �����^�C�v
  gt_xml_record_type_code          xml_record_type_code;          -- ���R�[�h�^�C�v
  gt_xml_item_id                   xml_item_id;                   -- OPM�i��ID
  gt_xml_item_code                 xml_item_code;                 -- �i��
  gt_xml_lot_id                    xml_lot_id;                    -- ���b�gID
  gt_xml_lot_no                    xml_lot_no;                    -- ���b�gNo
  gt_xml_actual_date               xml_actual_date;               -- ���ѓ�
  gt_xml_actual_quantity           xml_actual_quantity;           -- ���ѐ���
  gt_xml_automanual_rsv_class      xml_automanual_rsv_class;      -- �����蓮�����敪
  gt_xml_created_by                xml_created_by;                -- �쐬��
  gt_xml_creation_date             xml_creation_date;             -- �쐬��
  gt_xml_last_updated_by           xml_last_updated_by;           -- �ŏI�X�V��
  gt_xml_last_update_date          xml_last_update_date;          -- �ŏI�X�V��
  gt_xml_last_update_login         xml_last_update_login;         -- �ŏI�X�V���O�C��
  gt_xml_request_id                xml_request_id;                -- �v��ID
  gt_xml_program_application_id    xml_program_application_id;    -- �A�v���P�[�V����ID
  gt_xml_program_id                xml_program_id;                -- �R���J�����g�E�v���O����ID
  gt_xml_program_update_date       xml_program_update_date;       -- �v���O�����X�V��
--
  -- �󒍃w�b�_�A�h�I�� �ŐV�t���O �ꊇ�X�V�p
  gt_xoh_a10_order_header_id     xoh_order_header_id;        -- �󒍃w�b�_�A�h�I��ID
  gt_xoh_a10_last_updated_by     xoh_last_updated_by;        -- �ŏI�X�V��
  gt_xoh_a10_last_update_date    xoh_last_update_date;       -- �ŏI�X�V��
  gt_xoh_a10_last_update_login   xoh_last_update_login;      -- �ŏI�X�V���O�C��
  gt_xoh_a10_request_id          xoh_request_id;             -- �v��ID
  gt_xoh_a10_program_appli_id    xoh_program_application_id; -- �A�v���P�[�V����ID
  gt_xoh_a10_program_id          xoh_program_id;             -- �R���J�����g�E�v���O����ID
  gt_xoh_a10_program_update_date xoh_program_update_date;    -- �v���O�����X�V��
--
  -- �󒍃w�b�_�A�h�I�� �󒍃^�C�v�E�o�^���� �ꊇ�X�V�p
  gt_xoh_a12_order_header_id      xoh_order_header_id;        -- �󒍃w�b�_�A�h�I��ID
  gt_xoh_a12_order_type_id        xoh_order_type_id;          -- �󒍃^�C�vID
  gt_xoh_a12_last_updated_by      xoh_last_updated_by;        -- �ŏI�X�V��
  gt_xoh_a12_last_update_date     xoh_last_update_date;       -- �ŏI�X�V��
  gt_xoh_a12_last_update_login    xoh_last_update_login;      -- �ŏI�X�V���O�C��
  gt_xoh_a12_request_id           xoh_request_id;             -- �v��ID
  gt_xoh_a12_program_appli_id     xoh_program_application_id; -- �A�v���P�[�V����ID
  gt_xoh_a12_program_id           xoh_program_id;             -- �R���J�����g�E�v���O����ID
  gt_xoh_a12_program_update_date  xoh_program_update_date;    -- �v���O�����X�V��
--
  -- �󒍖��׃A�h�I�� ���ʁE���_�˗����� �ꊇ�X�V�p
  gt_xol_a13_order_line_id       xol_order_line_id;           -- �󒍖��׃A�h�I��ID
  gt_xol_a13_order_header_id     xol_order_header_id;         -- �󒍃w�b�_�A�h�I��ID
  gt_xol_a13_order_line_number   xol_order_line_number;       -- ���הԍ�
  gt_xol_a13_request_no          xol_request_no;              -- �˗�No
  gt_xol_a13_shipping_item_id    xol_shipping_item_id;        -- �o�וi��ID
  gt_xol_a13_shipping_item_code  xol_shipping_item_code;      -- �o�וi��
  gt_xol_a13_quantity            xol_quantity;                -- ����
  gt_xol_a13_uom_code            xol_uom_code;                -- �P��
  gt_xol_a13_shipped_quantity    xol_shipped_quantity;        -- �o�׎��ѐ���
  gt_xol_a13_based_req_quant     xol_based_request_quantity;  -- ���_�˗�����
  gt_xol_a13_request_item_id     xol_request_item_id;         -- �˗��i��ID
  gt_xol_a13_request_item_code   xol_request_item_code;       -- �˗��i��
  gt_xol_a13_rm_if_flg           xol_rm_if_flg;               -- �q�֕ԕi�C���^�t�F�[�X�σt���O
  gt_xol_a13_created_by          xol_created_by;              -- �쐬��
  gt_xol_a13_creation_date       xol_creation_date;           -- �쐬��
  gt_xol_a13_last_updated_by     xol_last_updated_by;         -- �ŏI�X�V��
  gt_xol_a13_last_update_date    xol_last_update_date;        -- �ŏI�X�V��
  gt_xol_a13_last_update_login   xol_last_update_login;       -- �ŏI�X�V���O�C��
  gt_xol_a13_request_id          xol_request_id;              -- �v��ID
  gt_xol_a13_program_appli_id    xol_program_application_id;  -- �A�v���P�[�V����ID
  gt_xol_a13_program_id          xol_program_id;              -- �R���J�����g�E�v���O����ID
  gt_xol_a13_program_update_date xol_program_update_date;     -- �v���O�����X�V��
--
  -- �󒍃w�b�_�A�h�I��ID �ۑ��p
  gt_xoh_a7_13_order_header_id         xoh_order_header_id;  -- �󒍃w�b�_�A�h�I��ID
--
  -- �󒍃w�b�_�A�h�I�� ���v���� �ꊇ�X�V�p
  gt_xoh_a15_order_header_id     xoh_order_header_id;        -- �󒍃w�b�_�A�h�I��ID
  gt_xoh_a15_sum_quantity        xoh_sum_quantity;           -- ���v����
  gt_xoh_a15_last_updated_by     xoh_last_updated_by;        -- �ŏI�X�V��
  gt_xoh_a15_last_update_date    xoh_last_update_date;       -- �ŏI�X�V��
  gt_xoh_a15_last_update_login   xoh_last_update_login;      -- �ŏI�X�V���O�C��
  gt_xoh_a15_request_id          xoh_request_id;             -- �v��ID
  gt_xoh_a15_program_appli_id    xoh_program_application_id; -- �A�v���P�[�V����ID
  gt_xoh_a15_program_id          xoh_program_id;             -- �R���J�����g�E�v���O����ID
  gt_xoh_a15_program_update_date xoh_program_update_date;    -- �v���O�����X�V��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_input_reserve_cnt  NUMBER; -- ���͌���(�q�֕ԕi�C���^�[�t�F�[�X)
--
  gn_output_headers_cnt NUMBER; -- �q�֕ԕi���쐬����(�󒍃w�b�_�A�h�I���P��)
  gn_output_lines_cnt   NUMBER; -- �q�֕ԕi���쐬����(�󒍖��׃A�h�I���P��)
  gn_output_lot_cnt     NUMBER; -- �q�֕ԕi���쐬����(�ړ����b�g�ڍ�)
--
  gn_output_del_hd_cnt  NUMBER; -- �q�֕ԕi�ŏ����쐬����(�󒍃w�b�_�A�h�I���P��)
  gn_output_del_ln_cnt  NUMBER; -- �q�֕ԕi�ŏ����쐬����(�󒍖��׃A�h�I���P��)
  gn_output_del_lot_cnt NUMBER; -- �q�֕ԕi�ŏ����쐬����(�ړ����b�g�ڍגP��)
--
  gn_output_upd_hd_cnt  NUMBER; -- �q�֕ԕi�X�V���쐬����(�󒍃w�b�_�A�h�I���P��)
  gn_output_upd_ln_cnt  NUMBER; -- �q�֕ԕi�X�V���쐬����(�󒍖��׃A�h�I���P��)
--
  gt_reserve_interface_tbl reserve_interface_tbl; -- �q�֕ԕi�C���^�[�t�F�[�X�i�[�p
  gt_order_all_tbl         order_all_tbl;  -- �󒍃w�b�_�A�h�I���E�󒍖��׃A�h�I���E�ړ����b�g�ڍ׊i�[�p
--
  gv_org_id                VARCHAR2(150);         -- �}�X�^�[�g�DID
  gv_max_date              VARCHAR2(150);         -- MAX���t
--
  gt_request_no          xxwsh_order_headers_all.request_no%TYPE;          -- �ϊ���˗�No
  gt_registered_sequence xxwsh_order_headers_all.registered_sequence%TYPE; -- �o�^����
--
  -- ����^�C�vID(�ԕi)
  gt_transact_type_id_return  xxwsh_oe_transaction_types_v.transaction_type_id%TYPE;
  -- ����^�C�vID(��)
  gt_transact_type_id_order   xxwsh_oe_transaction_types_v.transaction_type_id%TYPE;
--
  -- �󒍃^�C�v(�V�K/����).����^�C�vID
  gt_new_transaction_type_id  xxwsh_oe_transaction_types_v.transaction_type_id%TYPE;
  -- �󒍃^�C�v(�V�K/����).�󒍃J�e�S��
  gt_new_transaction_catg_code  xxwsh_oe_transaction_types_v.transaction_type_code%TYPE;
  -- �󒍃^�C�v(�ŏ�).����^�C�vID
  gt_del_transaction_type_id  xxwsh_oe_transaction_types_v.transaction_type_id%TYPE;
  -- �󒍃^�C�v(�ŏ�).�󒍃J�e�S��
  gt_del_transaction_catg_code  xxwsh_oe_transaction_types_v.transaction_type_code%TYPE;
--
  -- OPM�i�ڏ��VIEW.�i��ID
  gt_item_id               xxcmn_item_mst_v.item_id%TYPE;
  -- OPM�i�ڏ��VIEW.�P��
  gt_item_um               xxcmn_item_mst_v.item_um%TYPE;
  -- �q�֕ԕi�C���^�[�t�F�[�X.�`�[No
  gt_invoice_no            xxwsh_reserve_interface.invoice_no%TYPE;
  -- �i�ڃJ�e�S�����VIEW3.���i�敪
  gt_item_class            xxcmn_item_categories3_v.prod_class_code%TYPE;
  -- OPM�ۊǏꏊ�}�X�^.�ۊǑq��ID(�o�׌�ID)
  gt_inventory_location_id mtl_item_locations.inventory_location_id%TYPE;
  -- �p�[�e�B�T�C�g���VIEW.�p�[�e�BID(���_ID)
  gt_party_id              xxcmn_party_sites_v.party_id%TYPE;
  -- �p�[�e�B�T�C�g���VIEW.�p�[�e�B�T�C�gID(�o�א�ID)
  gt_party_site_id         xxcmn_party_sites_v.party_site_id%TYPE;
  -- �p�[�e�B�T�C�g���VIEW.�T�C�g�ԍ�(�o�א�)
  gt_party_site_number     xxcmn_party_sites_v.party_site_number%TYPE;
--
  gn_idx_hd      NUMBER;  -- �z��C���f�b�N�X �󒍃w�b�_�A�h�I�� �ꊇ�o�^�p
  gn_idx_ln      NUMBER;  -- �z��C���f�b�N�X �󒍖��׃A�h�I�� �ꊇ�o�^�p
  gn_idx_lot     NUMBER;  -- �z��C���f�b�N�X �ړ����b�g�ڍ� �ꊇ�o�^�p
--
  gn_idx_hd_a10  NUMBER;  -- �z��C���f�b�N�X �󒍃w�b�_�A�h�I�� �ŐV�t���O �ꊇ�X�V�p
  gn_idx_hd_a12  NUMBER;  -- �z��C���f�b�N�X �󒍃w�b�_�A�h�I�� �󒍃^�C�v�E�o�^���� �ꊇ�X�V�p
  gn_idx_ln_a13  NUMBER;  -- �z��C���f�b�N�X �󒍖��׃A�h�I�� ���ʁE���_�˗����� �ꊇ�X�V�p
  gn_idx_hd_a15  NUMBER;  -- �z��C���f�b�N�X �󒍃w�b�_�A�h�I�� ���v���� �ꊇ�X�V�p
--
  gn_seq_hd      NUMBER;  -- �V�[�P���X(�󒍃w�b�_�A�h�I��.�󒍃w�b�_�A�h�I��ID)
  gn_seq_a9      NUMBER;  -- �V�[�P���X A-9�Őݒ肵���󒍃w�b�_�A�h�I��ID
  gn_seq_a12     NUMBER;  -- A-12�Őݒ肵���󒍃w�b�_�A�h�I��ID
--
  gt_line_number_a11  xxwsh_order_lines_all.order_line_number%TYPE; -- A-11�ŃZ�b�g���閾�הԍ�
--
  gt_sum_quantity     xxwsh_reserve_interface.quantity%TYPE;        -- ���Z����
--
  gb_posi_flg  BOOLEAN;   -- ���א��ʃ`�F�b�N�t���O ����>=0�̏ꍇTRUE
  gb_nega_flg  BOOLEAN;   -- ���א��ʃ`�F�b�N�t���O ����< 0�̏ꍇTRUE
--
  gb_a11_flg   BOOLEAN;    -- A-11-2���s�����ǂ����𐧌䂷��t���O
--
  gt_user_id         xxwsh_order_headers_all.created_by%TYPE;             -- �쐬��(�ŏI�X�V��)
  gt_sysdate         xxwsh_order_headers_all.creation_date%TYPE;          -- �쐬��(�ŏI�X�V��)
  gt_login_id        xxwsh_order_headers_all.last_update_login%TYPE;      -- �ŏI�X�V���O�C��
  gt_conc_request_id xxwsh_order_headers_all.request_id%TYPE;             -- �v��ID
  gt_prog_appl_id    xxwsh_order_headers_all.program_application_id%TYPE; -- �A�v���P�[�V����ID
  gt_conc_program_id xxwsh_order_headers_all.program_id%TYPE; -- �R���J�����g�E�v���O����ID
--
--
  /**********************************************************************************
   * Procedure Name   : get_profile
   * Description      : �v���t�@�C���擾���� (A-1)
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_profile';  -- �v���O������
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
    -- *** ���[�J���萔 ***
    cv_org_id       CONSTANT VARCHAR2(30) := '�}�X�^�[�g�DID';
    cv_max_date     CONSTANT VARCHAR2(30) := 'MAX���t';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************************
    -- *** �v���t�@�C���擾�F�}�X�^�[�g�DID
    -- **************************************************
    gv_org_id := TRIM(FND_PROFILE.VALUE(gv_prf_org_id));
--
    IF (gv_org_id IS NULL) THEN  -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_noprof_err,
        gv_tkn_prof_name,
        cv_org_id);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** �v���t�@�C���擾�FMAX���t
    -- **************************************************
    gv_max_date := TRIM(FND_PROFILE.VALUE(gv_prf_max_date));
--
    IF (gv_max_date IS NULL) THEN  -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_noprof_err,
        gv_tkn_prof_name,
        cv_max_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_profile;
--
--
  /**********************************************************************************
   * Procedure Name   : get_reserve_interface
   * Description      : �q�֕ԕi�C���^�[�t�F�[�X��񒊏o���� (A-2)
   ***********************************************************************************/
  PROCEDURE get_reserve_interface(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_reserve_interface';  -- �v���O������
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
    -- *** ���[�J���萔 ***
    cv_xxwsh_reserve_interface CONSTANT VARCHAR2(50) := '�q�֕ԕi�C���^�[�t�F�[�X';
--
    -- *** ���[�J���ϐ� ***
    lb_rtn_cd      BOOLEAN;                                  -- ���ʊ֐��̃��^�[���R�[�h
    lt_invoice_no  xxwsh_reserve_interface.invoice_no%TYPE;  -- �`�[No
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************************
    -- *** �q�֕ԕi�C���^�[�t�F�[�X �e�[�u�����b�N
    -- **************************************************
    lb_rtn_cd := xxcmn_common_pkg.get_tbl_lock(gv_xxwsh, gv_reserve_interface);
--
    IF (NOT lb_rtn_cd) THEN         -- ���ʊ֐��̃��^�[���R�[�h���G���[�̏ꍇ
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_table_lock_err,
        gv_tkn_table,
        cv_xxwsh_reserve_interface);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** �q�֕ԕi�C���^�[�t�F�[�X��񑶍݃`�F�b�N
    -- **************************************************
    SELECT COUNT(xri.reserve_interface_id) AS cnt  -- ����
    INTO   gn_input_reserve_cnt                    -- ���͌���(�q�֕ԕi�C���^�[�t�F�[�X)
    FROM   xxwsh_reserve_interface  xri;           -- �q�֕ԕi�C���^�[�t�F�[�X
--
    IF (gn_input_reserve_cnt < 1) THEN             -- 1�������݂��Ȃ��ꍇ�̓G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_nodata_err);
      lv_errbuf := lv_errmsg;
      RAISE no_data_expt;
    END IF;
--
    -- **************************************************
    -- *** ����`�[No���w�b�_����`�F�b�N
    -- **************************************************
    BEGIN
      SELECT MIN(xri_grp.invoice_no) AS min_invoice_no -- �d�����Ă���`�[No�̍ł�����������
      INTO   lt_invoice_no
      FROM
        (SELECT   xri.invoice_no,                         -- �`�[No
                  xri.recorded_year,                      -- �v��N��
                  xri.input_base_code,                    -- ���͋��_�R�[�h
                  xri.receive_base_code,                  -- ���苒�_�R�[�h
                  xri.recorded_date                       -- �v����t�i�����j
         FROM     xxwsh_reserve_interface  xri            -- �q�֕ԕi�C���^�[�t�F�[�X
         GROUP BY xri.invoice_no,                         -- �`�[No
                  xri.recorded_year,                      -- �v��N��
                  xri.input_base_code,                    -- ���͋��_�R�[�h
                  xri.receive_base_code,                  -- ���苒�_�R�[�h
                  xri.recorded_date                       -- �v����t�i�����j
        ) xri_grp
      GROUP BY xri_grp.invoice_no                         -- �`�[No���Ƃ̌���
      HAVING COUNT(xri_grp.invoice_no) >= 2;              -- �`�[No���Ƃ̌���>����`�[No��2���ȏ�
--
      -- �`�[No���擾�ł����ꍇ�́A����`�[No���w�b�_����G���[
      IF (lt_invoice_no IS NOT NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_invoice_no_err,
          gv_tkn_den_no,
          lt_invoice_no);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- �擾�f�[�^�Ȃ��̏ꍇ�͏d�����Ă��Ȃ�����OK
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;  -- �������Ȃ�
    END;
--
    -- **************************************************
    -- *** �q�֕ԕi�C���^�[�t�F�[�X��񒊏o
    -- **************************************************
    SELECT xri2.recorded_year,                     -- �v��N��
           xri2.input_base_code,                   -- ���͋��_�R�[�h
           xri2.receive_base_code,                 -- ���苒�_�R�[�h
           xri2.invoice_class_1,                   -- �`��P
           xri2.recorded_date,                     -- �v����t(����)
           xri2.invoice_no,                        -- �`�[No
           xri2.item_no,                           -- �i�ڃR�[�h(OPM�i�ڏ��VIEW)
           xri2.quantity_total                     -- ����
    BULK COLLECT INTO gt_reserve_interface_tbl
    FROM (SELECT xri.recorded_year,                -- �v��N��
                 xri.input_base_code,              -- ���͋��_�R�[�h
                 xri.receive_base_code,            -- ���苒�_�R�[�h
                 xri.invoice_class_1,              -- �`��P
                 xri.recorded_date,                -- �v����t(����)
                 xri.invoice_no,                   -- �`�[No
                 xim.item_no,                      -- �i�ڃR�[�h(OPM�i�ڏ��VIEW)
/* 2008/08/07 Mod ��
                 SUM(NVL(xri.case_amount_of_content,0) * TO_NUMBER(NVL(xim.num_of_cases,'0'))
2008/08/07 Mod �� */
                 SUM(NVL(xri.case_amount_of_content,0)
                   * TO_NUMBER(DECODE(NVL(xim.num_of_cases,'0'),'0','1',xim.num_of_cases))
                   + NVL(xri.quantity,0))
                              OVER (PARTITION BY xri.invoice_no, -- �`�[No
                                                 xri.item_code   -- �i�ڃR�[�h�G���g���[���Ƃ�
                                   ) AS quantity_total,          -- �T�}���[���Đ��ʂ����߂�
                 ROW_NUMBER() OVER (PARTITION BY xri.invoice_no, -- �`�[No
                                                 xri.item_code   -- �i�ڃR�[�h�G���g���[���Ƃ�
                                    ORDER BY     xri.invoice_class_1  -- �`��P(����)
                                   ) AS rank
          FROM   xxwsh_reserve_interface  xri,      -- �q�֕ԕi�C���^�[�t�F�[�X
                 xxcmn_item_mst_v         xim       -- OPM�i�ڏ��VIEW���O������
          WHERE  xri.item_code = xim.item_no(+)     -- �i�ڃR�[�h
         ) xri2
    WHERE xri2.rank = 1 -- �`�[No�E�i�ڃR�[�h�G���g���[���Ƃɓ`��P���ŏ��l�̃��R�[�h�𒊏o
    ORDER BY xri2.invoice_no,   -- �`�[No
             xri2.item_no;      -- �i�ڃR�[�h(OPM�i�ڏ��VIEW)
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
    WHEN no_data_expt THEN     -- �����Ώۃf�[�^0���i�x���j
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_reserve_interface;
--
--
  /**********************************************************************************
   * Procedure Name   : check_master
   * Description      : �}�X�^���݃`�F�b�N���� (A-3)
   ***********************************************************************************/
  PROCEDURE check_master(
    it_invoice_no         IN  xxwsh_reserve_interface.invoice_no%TYPE,        -- 1.�`�[No
    it_item_no            IN  ic_item_mst_b.item_no%TYPE,                     -- 2.�i�ڃR�[�h
    it_receive_base_code  IN  xxwsh_reserve_interface.receive_base_code%TYPE, -- 3.���苒�_�R�[�h
    it_input_base_code    IN  xxwsh_reserve_interface.input_base_code%TYPE,   -- 4.���͋��_�R�[�h
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'check_master'; -- �v���O������
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
    -- *** ���[�J���萔 ***
    cv_xxwsh_col_item_no           VARCHAR2(50) := '�i��';
    cv_xxwsh_tbl_item_no           VARCHAR2(50) := '�i�ڃ}�X�^';
    cv_xxwsh_tbl_item_class        VARCHAR2(50) := '���i�敪';
    cv_xxwsh_col_receive_base      VARCHAR2(50) := '�[����i�o�׌��j';
    cv_xxwsh_tbl_receive_base      VARCHAR2(50) := 'OPM�ۊǏꏊ�}�X�^';
    cv_xxwsh_col_input_base        VARCHAR2(50) := '���͋��_';
    cv_xxwsh_tbl_input_base        VARCHAR2(50) := '�ڋq�}�X�^';
--
    -- *** ���[�J���ϐ� ***
    lt_item_class xxcmn_item_categories3_v.prod_class_code%TYPE; -- �i�ڃJ�e�S�����VIEW3.���i�敪
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************************
    -- *** �i��ID�E�P�ʂ̎擾
    -- **************************************************
    BEGIN
--      SELECT imv.item_id,                 -- �i��ID
      SELECT imv.inventory_item_id,                 -- �i��ID
             imv.item_um                  -- �P��
      INTO   gt_item_id,
             gt_item_um
      FROM   xxcmn_item_mst_v  imv        -- �i�ڃ}�X�^���VIEW
      WHERE  imv.item_no = it_item_no;    -- �i�ڃR�[�h
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN             -- �}�X�^�ɑ��݂��Ȃ��ꍇ�̓G���[(�i�ڑ��݃`�F�b�N)
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_mst_chk_err,
          gv_tkn_colmun,
          cv_xxwsh_col_item_no,
          gv_tkn_table,
          cv_xxwsh_tbl_item_no);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- **************************************************
    -- *** ���i�敪�`�F�b�N
    -- **************************************************
    BEGIN
      SELECT icv.prod_class_code                  -- ���i�敪
      INTO   lt_item_class
      FROM   xxcmn_item_categories3_v  icv        -- �i�ڃJ�e�S�����VIEW3
      WHERE  icv.item_no = it_item_no;            -- �i�ڃR�[�h
--
      IF (lt_item_class IS NULL) THEN             -- ���i�敪�ɒl���o�^����Ă��Ȃ��ꍇ�̓G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_prod_get_err,
          gv_tkn_input_item,
          it_item_no);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      IF (gt_invoice_no = it_invoice_no) THEN       -- �`�[No�������ꍇ
        IF (gt_item_class <> lt_item_class) THEN    -- ����`�[No���ŏ��i�敪���قȂ�ꍇ�̓G���[
          lv_errmsg := xxcmn_common_pkg.get_msg(
            gv_xxwsh,
            gv_xxwsh_category_err,
            gv_tkn_ctg_name,
            cv_xxwsh_tbl_item_class);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      ELSE                                           -- �`�[No���ς�����ꍇ
        gt_invoice_no := it_invoice_no;              -- �`�[No��ޔ�
        gt_item_class := lt_item_class;              -- ���i�敪��ޔ�
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                      -- �}�X�^�ɑ��݂��Ȃ��ꍇ�̓G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_prod_get_err,
          gv_tkn_input_item,
          it_item_no);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- **************************************************
    -- *** �[����i�o�׌��j�`�F�b�N
    -- **************************************************
    BEGIN
      SELECT mil.inventory_location_id            -- �ۊǑq��ID
      INTO   gt_inventory_location_id
--      FROM   mtl_item_locations  mil              -- OPM�ۊǏꏊ�}�X�^
      FROM   xxcmn_item_locations_v  mil          -- OPM�ۊǏꏊ���View
      WHERE  mil.segment1 = it_receive_base_code; -- �ۊǑq�ɃR�[�h=���苒�_�R�[�h
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                 -- �}�X�^�ɑ��݂��Ȃ��ꍇ�̓G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_mst_chk_err,
          gv_tkn_colmun,
          cv_xxwsh_col_receive_base,
          gv_tkn_table,
          cv_xxwsh_tbl_receive_base);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- **************************************************
    -- *** ���͋��_�`�F�b�N
    -- **************************************************
    BEGIN
      SELECT xps.party_id,                              -- �p�[�e�BID�i���_ID�j
             xps.party_site_id,                         -- �p�[�e�B�T�C�gID�i�o�א�ID�j
             xps.party_site_number                      -- �T�C�g�ԍ��i�o�א�j
      INTO   gt_party_id,
             gt_party_site_id,
             gt_party_site_number
--      FROM   hz_parties           hzp,                  -- �p�[�e�B�}�X�^
      FROM   xxcmn_cust_accounts_v    hzp,                  -- �ڋq���View
             xxcmn_cust_acct_sites_v  xps                   -- �ڋq�T�C�g���VIEW
      WHERE  hzp.party_number = it_input_base_code      -- �g�D�ԍ�=���͋��_�R�[�h
        AND  hzp.party_id     = xps.party_id            -- �p�[�e�BID
        AND  xps.primary_flag = 'Y';                    -- ��t���O
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                       -- �}�X�^�ɑ��݂��Ȃ��ꍇ�̓G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_mst_chk_err,
          gv_tkn_colmun,
          cv_xxwsh_col_input_base,
          gv_tkn_table,
          cv_xxwsh_tbl_input_base);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_master;
--
--
  /**********************************************************************************
   * Procedure Name   : check_stock
   * Description      : �݌ɉ�v���ԃ`�F�b�N���� (A-4)
   ***********************************************************************************/
  PROCEDURE check_stock(
    it_recorded_date      IN  xxwsh_reserve_interface.recorded_date%TYPE,    -- 1.�v����t(����)
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'check_stock';  -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_close_date     VARCHAR2(6);  -- OPM�݌ɉ�v����CLOSE�N��(yyyymm)
    lv_recorded_date  VARCHAR2(6);  -- �v����t�i�����j(yyyymm)
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************************
    -- *** OPM�݌ɉ�v����CLOSE�N���擾
    -- **************************************************
    -- �v����t�i�����j��N���ɕϊ�
    lv_recorded_date := TO_CHAR(it_recorded_date,'yyyymm');
    -- ���ʊ֐�����OPM�݌ɉ�v����CLOSE�N�����擾
    lv_close_date := xxcmn_common_pkg.get_opminv_close_period;
--
    IF (lv_close_date IS NULL) THEN             -- CLOSE�N���擾�G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_closeym_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    IF (lv_close_date >= lv_recorded_date) THEN -- CLOSE�N��>=�v����t�i�����j�̏ꍇ�̓G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_stock_from_err,
        gv_tkn_arrival_date,
        lv_recorded_date);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- CLOSE�N��=�v���t�@�C������擾����MAX���t�̏ꍇ�̓G���[
    IF (lv_close_date = SUBSTRB(gv_max_date,1,4) || SUBSTRB(gv_max_date,6,2)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_stock_get_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_stock;
--
--
  /**********************************************************************************
   * Procedure Name   : get_order_type
   * Description      : �֘A�f�[�^�擾���� (A-5)
   ***********************************************************************************/
  PROCEDURE get_order_type(
    it_invoice_class_1    IN  xxwsh_reserve_interface.invoice_class_1%TYPE,        -- 1.�`��P
    it_invoice_no         IN  xxwsh_reserve_interface.invoice_no%TYPE,             -- 2.�`�[No
    it_recorded_date      IN  xxwsh_reserve_interface.recorded_date%TYPE,          -- 3.�v����t�i�����j2008/10/10 v1.5 M.Hirafuku ADD
    it_item_no            IN  ic_item_mst_b.item_no%TYPE,                          -- 4.�i�ڃR�[�h      2008/10/10 v1.5 M.Hirafuku ADD
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,               -- 5.����            2008/10/10 v1.5 M.Hirafuku ADD
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_order_type';  -- �v���O������
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
    -- *** ���[�J���萔 ***
    cv_status_normal  CONSTANT NUMBER := 0;         -- ����I��
    cv_inbound        CONSTANT VARCHAR2(1) := '1';  -- �ϊ��敪�F���_�����InBound�p
    -- 2008/10/10 v1.5 M.Hirafuku ADD ST
    cv_lot_no       CONSTANT VARCHAR2(10) := '9999999999';                 -- ���b�gNo
-- 2008/11/25 v1.6 T.Yoshimoto Mod Start �{��#243
    --cv_attribute1   CONSTANT VARCHAR2(10) := '2000/01/01';                 -- �����N����
    cv_attribute1   CONSTANT VARCHAR2(10) := '1900/01/01';                 -- �����N����
-- 2008/11/25 v1.6 T.Yoshimoto Mod End �{��#243
    cv_attribute2   CONSTANT VARCHAR2(4)  := 'ZZZZ';                       -- �ŗL�L��
    cv_attribute3   CONSTANT VARCHAR2(10) := '2099/12/31';                 -- �ܖ�����
    cv_attribute23  CONSTANT VARCHAR2(2)  := '50';                         -- ���b�g�X�e�[�^�X
    cv_cons_lot_ctl CONSTANT VARCHAR2(1)  := '1';                          -- �u���b�g�Ǘ��i�v
    cv_errmsg       CONSTANT VARCHAR2(30) := '���b�g�쐬�Ɏ��s���܂����B'; -- API�G���[���b�Z�[�W
    -- 2008/10/10 v1.5 M.Hirafuku ADD ED
--
    -- *** ���[�J���ϐ� ***
    ln_rtn_cd     NUMBER;        -- ���ʊ֐��̃��^�[���R�[�h
    ln_dummy      NUMBER;
--
    -- 2008/10/10 v1.5 M.Hirafuku ADD ST
--    lt_item_no       ic_item_mst_b.item_no%TYPE;
    lb_return_status BOOLEAN;
    lr_create_lot    GMIGAPI.lot_rec_typ;
    lt_dm_cnt        NUMBER := 0;
    lt_lot_chk       NUMBER := 0;
    or_lot_mst       ic_lots_mst%ROWTYPE;
    or_lot_cpg       ic_lots_cpg%ROWTYPE;
    or_return        VARCHAR2(1);                             -- ���^�[���X�e�[�^�X
    or_msg_cnt       NUMBER;                                  -- ���b�Z�[�W����
    or_msg_data      VARCHAR2(10000);                         -- ���b�Z�[�W
    -- 2008/10/10 v1.5 M.Hirafuku ADD ED
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************************
    -- *** �󒍃^�C�vID���o����
    -- **************************************************
    BEGIN
      gt_transact_type_id_return := NULL;    -- ����^�C�vID(�ԕi)
      gt_transact_type_id_order  := NULL;    -- ����^�C�vID(��)
--
      -- �݌Ɏ���p(�󒍃J�e�S��=�ԕi)�̎���^�C�vID���擾
      SELECT xtv.transaction_type_id         -- ����^�C�vID
      INTO   gt_transact_type_id_return
      FROM   xxwsh_oe_transaction_types_v  xtv,  -- �󒍃^�C�vView
             xxwsh_shipping_class_v        xsv   -- �o�׋敪View
      WHERE  xtv.transaction_type_name = xsv.order_transaction_type_name  -- ����^�C�v���Ō���
        AND  xtv.order_category_code   = gv_cate_return                   -- ����^�C�v��=�ԕi
        AND  xsv.invoice_class_1       = it_invoice_class_1;
--
      -- �݌ɕ��o�p(�󒍃J�e�S��=��)�̎���^�C�vID���擾
      SELECT xtv.transaction_type_id         -- ����^�C�vID
      INTO   gt_transact_type_id_order
      FROM   xxwsh_oe_transaction_types_v  xtv,  -- �󒍃^�C�vView
             xxwsh_shipping_class_v        xsv   -- �o�׋敪View
      WHERE  xtv.cancel_order_type     = xsv.order_transaction_type_name  -- ����^�C�v���Ō���
        AND  xtv.order_category_code   = gv_cate_order                    -- ����^�C�v��=��
        AND  xsv.invoice_class_1       = it_invoice_class_1;
--
      -- �l���ݒ肳��Ă��Ȃ��ꍇ�̓G���[
      IF ((gt_transact_type_id_return IS NULL)
--      OR  (gt_transact_type_id_order IS NULL)) THEN
      AND  (gt_transact_type_id_order IS NULL)) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_type_get_err);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN      -- �擾�ł��Ȃ������ꍇ�̓G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(
          gv_xxwsh,
          gv_xxwsh_type_get_err);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- **************************************************
    -- *** �˗�No���o����
    -- **************************************************
    gt_request_no := NULL;     -- ���ʊ֐��œ`�[No(9��)���˗�No(12��)�ɕϊ�����
    ln_rtn_cd := xxwsh_common_pkg.convert_request_number(
      cv_inbound,              -- �ϊ��敪
      it_invoice_no,           -- �ϊ��O�`�[No
      gt_request_no);          -- �ϊ���˗�No
--
    IF ((ln_rtn_cd <> cv_status_normal)        -- ���ʊ֐��̃��^�[���R�[�h���G���[�̏ꍇ
    OR  (gt_request_no IS NULL)) THEN          -- �ϊ���˗�No��NULL�̏ꍇ�̓G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_request_no_conv_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- **************************************************
    -- *** �_�~�[���b�g�ݒ菈�� 2008/10/10 v1.5 M.Hirafuku ADD ST
    -- **************************************************
    lb_return_status :=GMIGUTL.SETUP(FND_GLOBAL.USER_NAME);
    -- �u�ԕi�vA-2�Ŏ擾��������>=0(��)�̏ꍇ
    IF (it_quantity_total >= 0) THEN
--
      -- �_�~�[���b�g���݃`�F�b�N
      SELECT COUNT(*)
      INTO   lt_dm_cnt
      FROM   ic_lots_mst ilm        -- OPM���b�g�}�X�^
            ,xxcmn_item_mst2_v ximv -- OPM�i�ڏ��VIEW2
      WHERE ilm.lot_no              = cv_lot_no
      AND   ilm.item_id             = ximv.item_id
      AND   ximv.lot_ctl            = cv_cons_lot_ctl
      AND   ximv.inventory_item_id  = gt_item_id
      AND   ximv.start_date_active <= TRUNC(it_recorded_date)
      AND   ximv.end_date_active   >= TRUNC(it_recorded_date);
--
      -- �_�~�[���b�g�쐬
      IF (lt_dm_cnt <= 0) THEN
--
        -- ���b�g�Ǘ��i�`�F�b�N
        SELECT COUNT(*)
        INTO   lt_lot_chk
        FROM   xxcmn_item_mst2_v ximv -- OPM�i�ڏ��VIEW2
        WHERE ximv.lot_ctl            = cv_cons_lot_ctl
        AND   ximv.inventory_item_id  = gt_item_id
        AND   ximv.start_date_active <= TRUNC(it_recorded_date)
        AND   ximv.end_date_active   >= TRUNC(it_recorded_date);
--
        -- ���b�g�Ǘ��̏ꍇ
        IF (lt_lot_chk > 0) THEN
--
          -- �ݒ�l
          lr_create_lot.item_no     := it_item_no;           -- �i��No
          lr_create_lot.lot_no      := cv_lot_no;            -- ���b�gNo
          lr_create_lot.attribute1  := cv_attribute1;        -- �����N����
          lr_create_lot.attribute2  := cv_attribute2;        -- �ŗL�L��
          lr_create_lot.attribute3  := cv_attribute3;        -- �ܖ�����
          lr_create_lot.attribute23 := cv_attribute23;       -- ���b�g�X�e�[�^�X
          lr_create_lot.user_name   := FND_GLOBAL.USER_NAME; -- ���[�U
          lr_create_lot.lot_created := SYSDATE;              -- �쐬�N����
-- 2008/12/22 v1.7 ADD START
          lr_create_lot.expaction_date := TO_DATE('2099/12/31', 'YYYY/MM/DD');
          lr_create_lot.expire_date    := TO_DATE('2099/12/31', 'YYYY/MM/DD');
-- 2008/12/22 v1.7 ADD END
--
          --���b�g�쐬API
          GMIPAPI.CREATE_LOT(
             p_api_version      => 3.0                          -- IN  NUMBER
            ,p_init_msg_list    => FND_API.G_FALSE              -- IN  VARCHAR2 default fnd_api.g_false
            ,p_commit           => FND_API.G_FALSE              -- IN  VARCHAR2 default fnd_api.g_false
            ,p_validation_level => FND_API.G_VALID_LEVEL_FULL   -- IN  NUMBER   default fnd_api.g_valid_level_full
            ,p_lot_rec          => lr_create_lot                -- IN  GMIGAPI.lot_rec_typ
            ,x_ic_lots_mst_row  => or_lot_mst                   -- OUT ic_lots_mst%ROWTYPE
            ,x_ic_lots_cpg_row  => or_lot_cpg                   -- OUT ic_lots_cpg%ROWTYPE
            ,x_return_status    => or_return                    -- OUT VARCHAR2
            ,x_msg_count        => or_msg_cnt                   -- OUT NUMBER
            ,x_msg_data         => or_msg_data                  -- OUT VARCHAR2
          );
--
          -- API�G���[
          IF (or_return <> FND_API.G_RET_STS_SUCCESS) THEN
            lv_errbuf  := or_msg_data;
            lv_errmsg  := ov_errmsg || cv_errmsg;
            RAISE global_api_expt;
          END IF;
--
        END IF;
--
      END IF;
    END IF;
    -- 2008/10/10 v1.5 M.Hirafuku ADD ED
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_order_type;
--
--
  /**********************************************************************************
   * Procedure Name   : get_order_all_tbl
   * Description      : ����˗�No���o���� (A-6)
   ***********************************************************************************/
  PROCEDURE get_order_all_tbl(
    it_recorded_date      IN  xxwsh_reserve_interface.recorded_date%TYPE,     -- 1.�v����t�i�����j
    it_receive_base_code  IN  xxwsh_reserve_interface.receive_base_code%TYPE, -- 2.���苒�_�R�[�h
    it_input_base_code    IN  xxwsh_reserve_interface.input_base_code%TYPE,   -- 3.���͋��_�R�[�h
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'get_order_all_tbl';  -- �v���O������
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
    -- *** ���[�J���萔 ***
    cv_xxwsh_reserve_interface CONSTANT VARCHAR2(50) := '�q�֕ԕi�C���^�[�t�F�[�X';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***********************************************************
    -- *** ����˗�No�̎󒍃w�b�_�A�h�I���E�󒍖��׃A�h�I�����o
    -- ***********************************************************
    gt_order_all_tbl.DELETE;
--
    SELECT  xoh.order_header_id            AS xoh_order_header_id,            -- �󒍃w�b�_�A�h�I��ID
            xoh.order_type_id              AS xoh_order_type_id,              -- �󒍃^�C�vID
            xoh.organization_id            AS xoh_organization_id,            -- �g�DID
            xoh.latest_external_flag       AS xoh_latest_external_flag,       -- �ŐV�t���O
            xoh.ordered_date               AS xoh_ordered_date,               -- �󒍓�
            xoh.customer_id                AS xoh_customer_id,                -- �ڋqID
            xoh.customer_code              AS xoh_customer_code,              -- �ڋq
            xoh.deliver_to_id              AS xoh_deliver_to_id,              -- �o�א�ID
            xoh.deliver_to                 AS xoh_deliver_to,                 -- �o�א�
            xoh.shipping_instructions      AS xoh_shipping_instructions,      -- �o�׎w��
            xoh.request_no                 AS xoh_request_no,                 -- �˗�No
            xoh.req_status                 AS xoh_req_status,                 -- �X�e�[�^�X
            xoh.schedule_ship_date         AS xoh_schedule_ship_date,         -- �o�ח\���
            xoh.schedule_arrival_date      AS xoh_schedule_arrival_date,      -- ���ח\���
            xoh.deliver_from_id            AS xoh_deliver_from_id,            -- �o�׌�ID
            xoh.deliver_from               AS xoh_deliver_from,               -- �o�׌��ۊǏꏊ
            xoh.head_sales_branch          AS xoh_head_sales_branch,          -- �Ǌ����_
            xoh.prod_class                 AS xoh_prod_class,                 -- ���i�敪
            xoh.sum_quantity               AS xoh_sum_quantity,               -- ���v����
            xoh.result_deliver_to_id       AS xoh_result_deliver_to_id,       -- �o�א�_����ID
            xoh.result_deliver_to          AS xoh_result_deliver_to,          -- �o�א�_����
            xoh.shipped_date               AS xoh_shipped_date,               -- �o�ד�
            xoh.arrival_date               AS xoh_arrival_date,               -- ���ד�
--2008/08/07 Add ��
            xoh.actual_confirm_class       AS xoh_actual_confirm_class,       -- ���ьv��ϋ敪
--2008/08/07 Add ��
            xoh.perform_managerment_dept   AS xoh_perform_managerment_dept,   -- ���ъǗ�����
            xoh.registered_sequence        AS xoh_registered_sequence,        -- �o�^����
            xoh.created_by                 AS xoh_created_by,                 -- �쐬��
            xoh.creation_date              AS xoh_creation_date,              -- �쐬��
            xoh.last_updated_by            AS xoh_last_updated_by,            -- �ŏI�X�V��
            xoh.last_update_date           AS xoh_last_update_date,           -- �ŏI�X�V��
            xoh.last_update_login          AS xoh_last_update_login,          -- �ŏI�X�V���O�C��
            xoh.request_id                 AS xoh_request_id,                 -- �v��ID
            xoh.program_application_id     AS xoh_program_application_id,     -- �A�v���P�[�V����ID
            xoh.program_id                 AS xoh_program_id,                 -- �R���J�����g�E�v���O����ID
            xoh.program_update_date        AS xoh_program_update_date,        -- �v���O�����X�V��
--
            xol.order_line_id              AS xol_order_line_id,              -- �󒍖��׃A�h�I��ID
            xol.order_header_id            AS xol_order_header_id,            -- �󒍃w�b�_�A�h�I��ID
            xol.order_line_number          AS xol_order_line_number,          -- ���הԍ�
            xol.request_no                 AS xol_request_no,                 -- �˗�No
            xol.shipping_inventory_item_id AS xol_shipping_inventory_item_id, -- �o�וi��ID
            xol.shipping_item_code         AS xol_shipping_item_code,         -- �o�וi��
            xol.quantity                   AS xol_quantity,                   -- ����
            CASE
              --WHEN (xoh.transaction_type_name = gv_cate_return)  -- �󒍃^�C�v��=�ԕi�̏ꍇ
              WHEN (xoh.order_category_code = gv_cate_return)  -- �󒍃J�e�S��=�ԕi�̏ꍇ
                THEN xol.quantity
              --WHEN (xoh.transaction_type_name = gv_cate_order )  -- �󒍃^�C�v��=�󒍂̏ꍇ
--2009/01/06 Y.Kawano Mod Start #908
--              WHEN (xoh.order_category_code = gv_cate_return)  -- �󒍃J�e�S��=�󒍂̏ꍇ
              WHEN (xoh.order_category_code = gv_cate_order)  -- �󒍃J�e�S��=�󒍂̏ꍇ
--2009/01/06 Y.Kawano Mod End   #908
                THEN xol.quantity * -1
              ELSE 0
            END                          AS add_quantity,                 -- ���Z�p����
            xol.uom_code                 AS xol_uom_code,                 -- �P��
            xol.shipped_quantity         AS xol_shipped_quantity,         -- �o�׎��ѐ���
            xol.based_request_quantity   AS xol_based_request_quantity,   -- ���_�˗�����
            xol.request_item_id          AS xol_request_item_id,          -- �˗��i��ID
            xol.request_item_code        AS xol_request_item_code,        -- �˗��i��
            xol.rm_if_flg                AS xol_rm_if_flg,                -- �q�֕ԕi�C���^�t�F�[�X�σt���O
            xol.created_by               AS xol_created_by,               -- �쐬��
            xol.creation_date            AS xol_creation_date,            -- �쐬��
            xol.last_updated_by          AS xol_last_updated_by,          -- �ŏI�X�V��
            xol.last_update_date         AS xol_last_update_date,         -- �ŏI�X�V��
            xol.last_update_login        AS xol_last_update_login,        -- �ŏI�X�V���O�C��
            xol.request_id               AS xol_request_id,               -- �v��ID
            xol.program_application_id   AS xol_program_application_id,   -- �A�v���P�[�V����ID
            xol.program_id               AS xol_program_id,               -- �R���J�����g�E�v���O����ID
            xol.program_update_date      AS xol_program_update_date,      -- �v���O�����X�V��
--
            xml.mov_lot_dtl_id           AS xml_mov_lot_dtl_id,           -- ���b�g�ڍ�ID
            xml.mov_line_id              AS xml_mov_line_id,              -- ����ID
            xml.document_type_code       AS xml_document_type_code,       -- �����^�C�v
            xml.record_type_code         AS xml_record_type_code,         -- ���R�[�h�^�C�v
            xml.item_id                  AS xml_item_id,                  -- OPM�i��ID
            xml.item_code                AS xml_item_code,                -- �i��
            xml.lot_id                   AS xml_lot_id,                   -- ���b�gID
            xml.lot_no                   AS xml_lot_no,                   -- ���b�gNo
            xml.actual_date              AS xml_actual_date,              -- ���ѓ�
            xml.actual_quantity          AS xml_actual_quantity,          -- ���ѐ���
            xml.automanual_reserve_class AS xml_automanual_rsv_class,     -- �����蓮�����敪
            xml.created_by               AS xml_created_by,               -- �쐬��
            xml.creation_date            AS xml_creation_date,            -- �쐬��
            xml.last_updated_by          AS xml_last_updated_by,          -- �ŏI�X�V��
            xml.last_update_date         AS xml_last_update_date,         -- �ŏI�X�V��
            xml.last_update_login        AS xml_last_update_login,        -- �ŏI�X�V���O�C��
            xml.request_id               AS xml_request_id,               -- �v��ID
            xml.program_application_id   AS xml_program_application_id,   -- �A�v���P�[�V����ID
            xml.program_id               AS xml_program_id,               -- �R���J�����g�E�v���O����ID
            xml.program_update_date      AS xml_program_update_date       -- �v���O�����X�V��
    BULK COLLECT INTO gt_order_all_tbl
    FROM
      (
      SELECT oha.order_header_id             AS order_header_id,          -- �󒍃w�b�_�A�h�I��ID
             oha.header_id                   AS header_id,                -- �󒍃w�b�_ID
             oha.order_type_id               AS order_type_id,            -- �󒍃^�C�vID
             oha.organization_id             AS organization_id,          -- �g�DID
             oha.latest_external_flag        AS latest_external_flag,     -- �ŐV�t���O
             oha.ordered_date                AS ordered_date,             -- �󒍓�
             oha.customer_id                 AS customer_id,              -- �ڋqID
             oha.customer_code               AS customer_code,            -- �ڋq
             oha.deliver_to_id               AS deliver_to_id,            -- �o�א�ID
             oha.deliver_to                  AS deliver_to,               -- �o�א�
             oha.shipping_instructions       AS shipping_instructions,    -- �o�׎w��
             oha.request_no                  AS request_no,               -- �˗�No
             oha.req_status                  AS req_status,               -- �X�e�[�^�X
             oha.schedule_ship_date          AS schedule_ship_date,       -- �o�ח\���
             oha.schedule_arrival_date       AS schedule_arrival_date,    -- ���ח\���
             oha.deliver_from_id             AS deliver_from_id,          -- �o�׌�ID
             oha.deliver_from                AS deliver_from,             -- �o�׌��ۊǏꏊ
             oha.head_sales_branch           AS head_sales_branch,        -- �Ǌ����_
             oha.prod_class                  AS prod_class,               -- ���i�敪
             oha.sum_quantity                AS sum_quantity,             -- ���v����
             oha.result_deliver_to_id        AS result_deliver_to_id,     -- �o�א�_����ID
             oha.result_deliver_to           AS result_deliver_to,        -- �o�א�_����
             oha.shipped_date                AS shipped_date,             -- �o�ד�
             oha.arrival_date                AS arrival_date,             -- ���ד�
--2008/08/07 Add ��
             oha.actual_confirm_class        AS actual_confirm_class,     -- ���ьv��ϋ敪
--2008/08/07 Add ��
             oha.performance_management_dept AS perform_managerment_dept, -- ���ъǗ�����
             oha.registered_sequence         AS registered_sequence,      -- �o�^����
             oha.created_by                  AS created_by,               -- �쐬��
             oha.creation_date               AS creation_date,            -- �쐬��
             oha.last_updated_by             AS last_updated_by,          -- �ŏI�X�V��
             oha.last_update_date            AS last_update_date,         -- �ŏI�X�V��
             oha.last_update_login           AS last_update_login,        -- �ŏI�X�V���O�C��
             oha.request_id                  AS request_id,               -- �v��ID
             oha.program_application_id      AS program_application_id,   -- �A�v���P�[�V����ID
             oha.program_id                  AS program_id,               -- �R���J�����g�E�v���O����ID
             oha.program_update_date         AS program_update_date,      -- �v���O�����X�V��
             ROW_NUMBER() OVER (PARTITION BY oha.request_no               -- �˗�No���Ƃ�
                                ORDER BY     oha.registered_sequence DESC -- �o�^����(�~��)
                               ) AS rank,
             ott.order_category_code         AS order_category_code       -- �󒍃J�e�S��
      FROM   xxwsh_order_headers_all       oha,                  -- �󒍃w�b�_�A�h�I��
             xxwsh_oe_transaction_types_v  ott                   -- �󒍃^�C�vVIEW
      WHERE  oha.request_no           = gt_request_no            -- �˗�No=A-5�Ŏ擾�����ϊ���˗�No
        AND  oha.latest_external_flag = gv_flag_on               -- �ŐV�t���O='Y'
        AND  oha.order_type_id        = ott.transaction_type_id  -- �󒍃^�C�vID=����^�C�vID
      )  xoh,
      xxwsh_order_lines_all  xol,                                -- �󒍖��׃A�h�I��
      xxinv_mov_lot_details  xml                                 -- �ړ����b�g�ڍ�
    WHERE xoh.rank      = 1                                      -- �o�^�������ő�̃��R�[�h�𒊏o
      AND xoh.order_header_id = xol.order_header_id              -- �󒍃w�b�_�A�h�I��ID=�󒍃w�b�_�A�h�I��ID
      AND xol.order_line_id   = xml.mov_line_id(+)               -- �󒍖��׃A�h�I��ID=����ID
    ORDER BY xol.shipping_item_code;                             -- �o�וi��(����)
--
    -- ����˗�No�̈˗����o�^����Ă���ꍇ(���o�^�ł����Ă��G���[�ɂ͂��Ȃ�)
    IF (gt_order_all_tbl.COUNT > 0) THEN    -- ���o�ł����ꍇ
--
      -- *****************************************************************************
      -- *** �q�֕ԕi�C���^�[�t�F�[�X�ƒ��o�����󒍃w�b�_�A�h�I���̍��ڔ�r�`�F�b�N
      -- *****************************************************************************
      --�v����t(����)�Əo�ח\����A���苒�_�Əo�׌��ۊǏꏊ�A���͋��_�ƊǊ����_
      IF ((it_recorded_date     <> gt_order_all_tbl(1).hd_schedule_ship_date)
      OR  (it_receive_base_code <> gt_order_all_tbl(1).hd_deliver_from)
      OR  (it_input_base_code   <> gt_order_all_tbl(1).hd_head_sales_branch)) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(           -- �l���قȂ��Ă���ꍇ�̓G���[
            gv_xxwsh,
            gv_xxwsh_hd_upd_err);
          lv_errbuf :=  lv_errmsg;
          RAISE global_api_expt;
      END IF;
--
      -- *************************************************
      -- *** �󒍃^�C�v�̕␳
      -- *************************************************
      BEGIN
        gt_new_transaction_type_id := NULL;
        --gt_new_transaction_type_name := NULL;
        gt_del_transaction_type_id := NULL;
        --gt_del_transaction_type_name := NULL;
        --
        gt_new_transaction_catg_code := NULL;
        gt_del_transaction_catg_code := NULL;
--
        SELECT otnew.transaction_type_id,           -- �󒍃^�C�v(�V�K/����).����^�C�vID
               --otnew.transaction_type_name,         -- �󒍃^�C�v(�V�K/����).�󒍃J�e�S��
               otnew.order_category_code,
               otdel.transaction_type_id,           -- �󒍃^�C�v(�ŏ�).����^�C�vID
               --otdel.transaction_type_name,          -- �󒍃^�C�v(�ŏ�).�󒍃J�e�S��
               otdel.order_category_code
        INTO   gt_new_transaction_type_id,
               --gt_new_transaction_type_name,
               gt_new_transaction_catg_code,
               gt_del_transaction_type_id,
               --gt_del_transaction_type_name,
               gt_del_transaction_catg_code
        FROM   xxwsh_oe_transaction_types_v  otnew,     -- �󒍃^�C�v(�V�K/����)
               xxwsh_oe_transaction_types_v  otdel      -- �󒍃^�C�v(�ŏ�)
               -- �󒍃^�C�v(�V�K/����).����^�C�vID=A-6�Ŏ擾�����󒍃^�C�vID
        WHERE  otnew.transaction_type_id   = gt_order_all_tbl(1).hd_order_type_id
               -- �󒍃^�C�v(�ŏ�).����^�C�v=�󒍃^�C�v(�V�K/����).����󒍃^�C�v(DFF5)
          AND  otdel.transaction_type_name = otnew.cancel_order_type;
--
        IF ((gt_new_transaction_type_id IS NULL)
--        OR  (gt_new_transaction_type_name IS NULL)
        OR  (gt_new_transaction_catg_code IS NULL)
        OR  (gt_del_transaction_type_id IS NULL)
--        OR  (gt_del_transaction_type_name IS NULL)) THEN  -- �擾�ł��Ȃ������ꍇ�̓G���[
        OR  (gt_del_transaction_catg_code IS NULL)) THEN  -- �擾�ł��Ȃ������ꍇ�̓G���[
          lv_errmsg := xxcmn_common_pkg.get_msg(
            gv_xxwsh,
            gv_xxwsh_type_get_err);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN           -- �󒍃^�C�v�����݂��Ȃ��ꍇ�̓G���[
          lv_errmsg := xxcmn_common_pkg.get_msg(
            gv_xxwsh,
            gv_xxwsh_type_get_err);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
      END;
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
    WHEN lock_expt THEN       -- ���b�N�擾�G���[
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_table_lock_err,
        gv_tkn_table,
        cv_xxwsh_reserve_interface);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_order_all_tbl;
--
--
  /**********************************************************************************
   * Procedure Name   : set_del_headers
   * Description      : �q�֕ԕi�ŏ����(�w�b�_)�쐬���� (A-7)
   ***********************************************************************************/
  PROCEDURE set_del_headers(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'set_del_headers';  -- �v���O������
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
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �q�֕ԕi�ŏ����쐬����(�󒍃w�b�_�A�h�I���P��)
    gn_output_del_hd_cnt := gn_output_del_hd_cnt + 1;
--
    SELECT xxwsh_order_headers_all_s1.NEXTVAL          -- �V�[�P���X�擾
    INTO   gn_seq_hd                                   -- �󒍃w�b�_�A�h�I��ID
    FROM   dual;
--
    gn_idx_hd := gn_idx_hd + 1;  -- �z��C���f�b�N�X �󒍃w�b�_�A�h�I�� �ꊇ�o�^�p
--
    -- �󒍃w�b�_�A�h�I��ID<--�V�[�P���X
    gt_xoh_order_header_id(gn_idx_hd)         := gn_seq_hd;
    -- �󒍃^�C�vID<--A-6�Ŏ擾�����󒍃^�C�v(�ŏ�).����^�C�vID
    gt_xoh_order_type_id(gn_idx_hd)           := gt_del_transaction_type_id;
    -- �g�DID
    gt_xoh_organization_id(gn_idx_hd)         := gt_order_all_tbl(1).hd_organization_id;
    -- �ŐV�t���O<--'N'
    gt_xoh_latest_external_flag(gn_idx_hd)    := gv_flag_off;
    -- �󒍓�
    gt_xoh_ordered_date(gn_idx_hd)            := gt_order_all_tbl(1).hd_ordered_date;
    -- �ڋqID
    gt_xoh_customer_id(gn_idx_hd)             := gt_order_all_tbl(1).hd_customer_id;
    -- �ڋq
    gt_xoh_customer_code(gn_idx_hd)           := gt_order_all_tbl(1).hd_customer_code;
    -- �o�א�ID
    gt_xoh_deliver_to_id(gn_idx_hd)           := gt_order_all_tbl(1).hd_deliver_to_id;
    -- �o�א�
    gt_xoh_deliver_to(gn_idx_hd)              := gt_order_all_tbl(1).hd_deliver_to;
    -- �o�׎w��
    gt_xoh_shipping_instructions(gn_idx_hd)   := gt_order_all_tbl(1).hd_shipping_instructions;
    -- �˗�No
    gt_xoh_request_no(gn_idx_hd)              := gt_order_all_tbl(1).hd_request_no;
    -- �X�e�[�^�X
    gt_xoh_req_status(gn_idx_hd)              := gt_order_all_tbl(1).hd_req_status;
    -- �o�ח\���
    gt_xoh_schedule_ship_date(gn_idx_hd)      := gt_order_all_tbl(1).hd_schedule_ship_date;
    -- ���ח\���
    gt_xoh_schedule_arrival_date(gn_idx_hd)   := gt_order_all_tbl(1).hd_schedule_arrival_date;
    -- �o�׌�ID
    gt_xoh_deliver_from_id(gn_idx_hd)         := gt_order_all_tbl(1).hd_deliver_from_id;
    -- �o�׌��ۊǏꏊ
    gt_xoh_deliver_from(gn_idx_hd)            := gt_order_all_tbl(1).hd_deliver_from;
    -- �Ǌ����_
    gt_xoh_head_sales_branch(gn_idx_hd)       := gt_order_all_tbl(1).hd_head_sales_branch;
    -- ���i�敪
    gt_xoh_prod_class(gn_idx_hd)              := gt_order_all_tbl(1).hd_prod_class;
    -- ���v����
    gt_xoh_sum_quantity(gn_idx_hd)            := gt_order_all_tbl(1).hd_sum_quantity;
    -- �o�א�_����ID
    gt_xoh_result_deliver_to_id(gn_idx_hd)    := gt_order_all_tbl(1).hd_result_deliver_to_id;
    -- �o�א�_����
    gt_xoh_result_deliver_to(gn_idx_hd)       := gt_order_all_tbl(1).hd_result_deliver_to;
    -- �o�ד�
    gt_xoh_shipped_date(gn_idx_hd)            := gt_order_all_tbl(1).hd_shipped_date;
    -- ���ד�
    gt_xoh_arrival_date(gn_idx_hd)            := gt_order_all_tbl(1).hd_arrival_date;
    -- ���ъǗ�����
    gt_xoh_perform_management_dept(gn_idx_hd) := gt_order_all_tbl(1).hd_perform_management_dept;
--
    gt_registered_sequence                    := gt_order_all_tbl(1).hd_registered_sequence + 1;
    -- �o�^����<--A-6�Ŏ擾�����o�^���� + 1
    gt_xoh_registered_sequence(gn_idx_hd)     := gt_registered_sequence;
--
    gt_xoh_created_by(gn_idx_hd)              := gt_user_id;           -- �쐬��
    gt_xoh_creation_date(gn_idx_hd)           := gt_sysdate;           -- �쐬��
    gt_xoh_last_updated_by(gn_idx_hd)         := gt_user_id;           -- �ŏI�X�V��
    gt_xoh_last_update_date(gn_idx_hd)        := gt_sysdate;           -- �ŏI�X�V��
    gt_xoh_last_update_login(gn_idx_hd)       := gt_login_id;          -- �ŏI�X�V���O�C��
    gt_xoh_request_id(gn_idx_hd)              := gt_conc_request_id;   -- �v��ID
    gt_xoh_program_application_id(gn_idx_hd)  := gt_prog_appl_id;      -- �A�v���P�[�V����ID
    gt_xoh_program_id(gn_idx_hd)              := gt_conc_program_id;   -- �R���J�����g�E�v���O����ID
    gt_xoh_program_update_date(gn_idx_hd)     := gt_sysdate;           -- �v���O�����X�V��
--
    -- A-15�ɂ����Ď󒍃w�b�_�A�h�I���̍��v���ʂ��Čv�Z���čX�V���邽�߂ɂ����Ŏ󒍃w�b�_�A�h�I��ID��ޔ�����
    gn_idx_hd_a15 := gn_idx_hd_a15 + 1;
    gt_xoh_a7_13_order_header_id(gn_idx_hd_a15) := gn_seq_hd; -- �󒍃w�b�_�A�h�I��ID
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_del_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : set_del_lines
   * Description      : �q�֕ԕi�ŏ����(����)�쐬���� (A-8)
   ***********************************************************************************/
  PROCEDURE set_del_lines(
    in_idx                IN  NUMBER,              -- 1.�z��C���f�b�N�X
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'set_del_lines';  -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_seq      NUMBER;            --�V�[�P���X�i�󒍖��ׁj
    ln_seq_lot  NUMBER;            --�V�[�P���X�i�ړ����b�g�ڍׁj
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--  ---------- �󒍖��� ---------------------------------------------
--
    -- �q�֕ԕi�ŏ����쐬����(�󒍖��׃A�h�I���P��)
    gn_output_del_ln_cnt := gn_output_del_ln_cnt + 1;
--
    SELECT xxwsh_order_lines_all_s1.NEXTVAL              -- �V�[�P���X�擾
    INTO   ln_seq                                        -- �󒍖��׃A�h�I��ID
    FROM   dual;
--
    -- �z��C���f�b�N�X �󒍖��׃A�h�I�� �ꊇ�o�^�p
    gn_idx_ln := gn_idx_ln + 1;
--
    -- �󒍖��׃A�h�I��ID<--�V�[�P���X
    gt_xol_order_line_id(gn_idx_ln)       := ln_seq;
    -- �󒍃w�b�_�A�h�I��ID<--A-7�Ŏ擾�����V�[�P���X
    gt_xol_order_header_id(gn_idx_ln)     := gn_seq_hd;
    -- ���הԍ�
    gt_xol_order_line_number(gn_idx_ln)   := gt_order_all_tbl(in_idx).ln_order_line_number;
    -- �˗�No
    gt_xol_request_no(gn_idx_ln)          := gt_order_all_tbl(in_idx).ln_request_no;
    -- �o�וi��ID
    gt_xol_shipping_item_id(gn_idx_ln) := gt_order_all_tbl(in_idx).ln_shipping_inventory_item_id;
    -- �o�וi��
    gt_xol_shipping_item_code(gn_idx_ln)  := gt_order_all_tbl(in_idx).ln_shipping_item_code;
    -- ����
    gt_xol_quantity(gn_idx_ln)            := gt_order_all_tbl(in_idx).ln_quantity;
    -- �P��
    gt_xol_uom_code(gn_idx_ln)            := gt_order_all_tbl(in_idx).ln_uom_code;
    -- �o�׎��ѐ���
    gt_xol_shipped_quantity(gn_idx_ln)    := gt_order_all_tbl(in_idx).ln_shipped_quantity;
     -- ���_�˗�����
    gt_xol_based_request_quantity(gn_idx_ln) := gt_order_all_tbl(in_idx).ln_based_request_quantity;
    -- �˗��i��ID
    gt_xol_request_item_id(gn_idx_ln)   := gt_order_all_tbl(in_idx).ln_request_item_id;
    -- �˗��i��
    gt_xol_request_item_code(gn_idx_ln) := gt_order_all_tbl(in_idx).ln_request_item_code;
    -- �q�֕ԕi�C���^�t�F�[�X�σt���O
    gt_xol_rm_if_flg(gn_idx_ln)               := gt_order_all_tbl(in_idx).ln_rm_if_flg;
--
    gt_xol_created_by(gn_idx_ln)              := gt_user_id;          -- �쐬��
    gt_xol_creation_date(gn_idx_ln)           := gt_sysdate;          -- �쐬��
    gt_xol_last_updated_by(gn_idx_ln)         := gt_user_id;          -- �ŏI�X�V��
    gt_xol_last_update_date(gn_idx_ln)        := gt_sysdate;          -- �ŏI�X�V��
    gt_xol_last_update_login(gn_idx_ln)       := gt_login_id;         -- �ŏI�X�V���O�C��
    gt_xol_request_id(gn_idx_ln)              := gt_conc_request_id;  -- �v��ID
    gt_xol_program_application_id(gn_idx_ln)  := gt_prog_appl_id;     -- �A�v���P�[�V����ID
    gt_xol_program_id(gn_idx_ln)              := gt_conc_program_id;  -- �R���J�����g�E�v���O����ID
    gt_xol_program_update_date(gn_idx_ln)     := gt_sysdate;          -- �v���O�����X�V��
--
--  ---------- �ړ����b�g�ڍ� -------------------------------------------------------
--
    -- �q�֕ԕi�ŏ����쐬����(�ړ����b�g�ڍגP��)
    gn_output_del_lot_cnt := gn_output_del_lot_cnt + 1;
--
    SELECT xxinv_mov_lot_s1.NEXTVAL              -- �V�[�P���X�擾
    INTO   ln_seq_lot                            -- ���b�g�ڍ�ID
    FROM   dual;
--
    -- �z��C���f�b�N�X �ړ����b�g�ڍ� �ꊇ�o�^�p
    gn_idx_lot := gn_idx_lot + 1;
--
    -- ���b�g�ڍ�ID
    gt_xml_mov_lot_dtl_id(gn_idx_lot)       := ln_seq_lot; -- �V�[�P���X�Ŏ擾�����l
    -- ����ID
    gt_xml_mov_line_id(gn_idx_lot)          := ln_seq;    -- �󒍖��׃A�h�I��ID�ɃZ�b�g�����l
    -- �����^�C�v
    gt_xml_document_type_code(gn_idx_lot)   := gt_order_all_tbl(in_idx).lo_document_type_code;
    -- ���R�[�h�^�C�v
    gt_xml_record_type_code(gn_idx_lot)     := gt_order_all_tbl(in_idx).lo_record_type_code;
    -- OPM�i��ID
    gt_xml_item_id(gn_idx_lot)              := gt_order_all_tbl(in_idx).lo_item_id;
    -- �i��
    gt_xml_item_code(gn_idx_lot)            := gt_order_all_tbl(in_idx).lo_item_code;
    -- ���b�gID
    gt_xml_lot_id(gn_idx_lot)               := gt_order_all_tbl(in_idx).lo_lot_id;
    -- ���b�gNo
    gt_xml_lot_no(gn_idx_lot)               := gt_order_all_tbl(in_idx).lo_lot_no;
    -- ���ѓ�
    gt_xml_actual_date(gn_idx_lot)          := gt_order_all_tbl(in_idx).lo_actual_date;
    -- ���ѐ���
    gt_xml_actual_quantity(gn_idx_lot)      := gt_order_all_tbl(in_idx).lo_actual_quantity;
    -- �����蓮�����敪
    gt_xml_automanual_rsv_class(gn_idx_lot) := gt_order_all_tbl(in_idx).lo_automanual_reserve_class;
--
    gt_xml_created_by(gn_idx_lot)              := gt_user_id;          -- �쐬��
    gt_xml_creation_date(gn_idx_lot)           := gt_sysdate;          -- �쐬��
    gt_xml_last_updated_by(gn_idx_lot)         := gt_user_id;          -- �ŏI�X�V��
    gt_xml_last_update_date(gn_idx_lot)        := gt_sysdate;          -- �ŏI�X�V��
    gt_xml_last_update_login(gn_idx_lot)       := gt_login_id;         -- �ŏI�X�V���O�C��
    gt_xml_request_id(gn_idx_lot)              := gt_conc_request_id;  -- �v��ID
    gt_xml_program_application_id(gn_idx_lot)  := gt_prog_appl_id;     -- �A�v���P�[�V����ID
    gt_xml_program_id(gn_idx_lot)              := gt_conc_program_id;  -- �R���J�����g�E�v���O����ID
    gt_xml_program_update_date(gn_idx_lot)     := gt_sysdate;          -- �v���O�����X�V��
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_del_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : set_order_headers
   * Description      : �q�֕ԕi���(�w�b�_)�쐬���� (A-9)
   ***********************************************************************************/
  PROCEDURE set_order_headers(
    in_idx                IN  NUMBER,                                         -- 1.�z��C���f�b�N�X
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,          -- 2.����
    it_recorded_date      IN  xxwsh_reserve_interface.recorded_date%TYPE,     -- 3.�v����t(����)
    it_receive_base_code  IN  xxwsh_reserve_interface.receive_base_code%TYPE, -- 4.���苒�_�R�[�h
    it_input_base_code    IN  xxwsh_reserve_interface.input_base_code%TYPE,   -- 5.���͋��_�R�[�h
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'set_order_headers';  -- �v���O������
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
    -- *** ���[�J���萔 ***
    cv_req_status_tightening  CONSTANT VARCHAR2(2) := '03';      -- ���ߍς�
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �q�֕ԕi���쐬����(�󒍃w�b�_�A�h�I���P��)
    gn_output_headers_cnt := gn_output_headers_cnt + 1;
--
    -- �z��C���f�b�N�X �󒍃w�b�_�A�h�I�� �ꊇ�o�^�p
    gn_idx_hd := gn_idx_hd + 1;
--
    SELECT xxwsh_order_headers_all_s1.NEXTVAL      -- �V�[�P���X�擾
    INTO   gn_seq_a9                               -- �󒍃w�b�_�A�h�I��ID
    FROM   dual;
--
    --A-6�œ���˗�No�����o�ł��Ȃ������ꍇ
    IF (gt_order_all_tbl.COUNT = 0) THEN
      -- �󒍃w�b�_�A�h�I��ID<--�V�[�P���X
      gt_xoh_order_header_id(gn_idx_hd) := gn_seq_a9;
--
      -- A-2�Ŏ擾��������>=0(��)�̏ꍇ
      IF (it_quantity_total >= 0) THEN
        -- �󒍃^�C�vID<--A-5�Ŏ擾�������(��)�^�C�vID(�ԕi)
        gt_xoh_order_type_id(gn_idx_hd) := gt_transact_type_id_return;
        -- A-2�Ŏ擾��������<0(��)�̏ꍇ
      ELSE
        -- �󒍃^�C�vID<--A-5�Ŏ擾�������(��)�^�C�vID(��)
        gt_xoh_order_type_id(gn_idx_hd) := gt_transact_type_id_order;
      END IF;
--
      -- �g�DID<--A-1�Ŏ擾�����v���t�@�C��.�}�X�^�g�DID
      gt_xoh_organization_id(gn_idx_hd)         := gv_org_id;
      -- �ŐV�t���O
      gt_xoh_latest_external_flag(gn_idx_hd)    := gv_flag_on;
      -- �󒍓�<--A-2�Ŏ擾�����v����t(����)
      gt_xoh_ordered_date(gn_idx_hd)            := it_recorded_date;
      -- �ڋqID<--A-3�Ŏ擾�������_ID
      gt_xoh_customer_id(gn_idx_hd)             := gt_party_id;
      -- �ڋq<--A-2�Ŏ擾�������͋��_�R�[�h
      gt_xoh_customer_code(gn_idx_hd)           := it_input_base_code;
      -- �o�א�ID<--A-3�Ŏ擾�����o�א�ID
      gt_xoh_deliver_to_id(gn_idx_hd)           := gt_party_site_id;
      -- �o�א�<--A-3�Ŏ擾�����o�א�
      gt_xoh_deliver_to(gn_idx_hd)              := gt_party_site_number;
      -- �o�׎w��<--NULL
      gt_xoh_shipping_instructions(gn_idx_hd)   := NULL;
      -- �˗�No<--A-5�ŕϊ������ϊ���˗�No
      gt_xoh_request_no(gn_idx_hd)              := gt_request_no;
      -- �X�e�[�^�X<--���ߍς�
      gt_xoh_req_status(gn_idx_hd)              := cv_req_status_tightening;
      -- �o�ח\���<--A-2�Ŏ擾�����v����t(����)
      gt_xoh_schedule_ship_date(gn_idx_hd)      := it_recorded_date;
      -- ���ח\���<--A-2�Ŏ擾�����v����t(����)
      gt_xoh_schedule_arrival_date(gn_idx_hd)   := it_recorded_date;
      -- �o�׌�ID<--A-3�Ŏ擾�����o�׌�ID(�ۊǑq��ID)
      gt_xoh_deliver_from_id(gn_idx_hd)         := gt_inventory_location_id;
      -- �o�׌��ۊǏꏊ<--A-2�Ŏ擾�������苒�_�R�[�h
      gt_xoh_deliver_from(gn_idx_hd)            := it_receive_base_code;
      -- �Ǌ����_<--A-2�Ŏ擾�������͋��_�R�[�h
      gt_xoh_head_sales_branch(gn_idx_hd)       := it_input_base_code;
      -- ���i�敪<--A-3�Ŏ擾�������i�敪
      gt_xoh_prod_class(gn_idx_hd)              := gt_item_class;
      gt_xoh_sum_quantity(gn_idx_hd)            := NULL;   -- ���v����<--NULL
      gt_xoh_result_deliver_to_id(gn_idx_hd)    := NULL;   -- �o�א�_����ID<--NULL
      gt_xoh_result_deliver_to(gn_idx_hd)       := NULL;   -- �o�א�_����<--NULL
      gt_xoh_shipped_date(gn_idx_hd)            := NULL;   -- �o�ד�<--NULL
      gt_xoh_arrival_date(gn_idx_hd)            := NULL;   -- ���ד�<--NULL
      gt_xoh_perform_management_dept(gn_idx_hd) := NULL;   -- ���ъǗ�����<--NULL
      gt_xoh_registered_sequence(gn_idx_hd)     := 1;      -- �o�^����<--1
--
    --A-6�œ���˗�No�����o�ł����ꍇ
    ELSE
      -- �󒍃w�b�_�A�h�I��ID<--�V�[�P���X
      gt_xoh_order_header_id(gn_idx_hd) := gn_seq_a9;
--
      -- ���Z����>=0(��)�̏ꍇ
      IF (gt_sum_quantity >= 0) THEN
        -- A-6�Ŏ擾�����󒍃^�C�v(�V�K/����).�󒍃J�e�S��=�ԕi�̏ꍇ
--        IF (gt_new_transaction_type_name = gv_cate_return) THEN
        IF (gt_new_transaction_catg_code = gv_cate_return) THEN
          -- �󒍃^�C�vID<--A-6�Ŏ擾�����󒍃^�C�v(�V�K/����).����^�C�vID
          gt_xoh_order_type_id(gn_idx_hd) := gt_new_transaction_type_id;
        -- A-6�Ŏ擾�����󒍃^�C�v(�V�K/����).�󒍃J�e�S��=�󒍂̏ꍇ
--        ELSIF (gt_new_transaction_type_name = gv_cate_order) THEN
        ELSIF (gt_new_transaction_catg_code = gv_cate_order) THEN
          -- �󒍃^�C�vID<--A-6�Ŏ擾�����󒍃^�C�v(�ŏ�).����^�C�vID
          gt_xoh_order_type_id(gn_idx_hd) := gt_del_transaction_type_id;
        END IF;
      -- ���Z����<0(��)�̏ꍇ
      ELSE
        -- A-6�Ŏ擾�����󒍃^�C�v(�V�K/����).�󒍃J�e�S��=�ԕi�̏ꍇ
--        IF (gt_new_transaction_type_name = gv_cate_return) THEN
        IF (gt_new_transaction_catg_code = gv_cate_return) THEN
          -- �󒍃^�C�vID<--A-6�Ŏ擾�����󒍃^�C�v(�ŏ�).����^�C�vID
          gt_xoh_order_type_id(gn_idx_hd) := gt_del_transaction_type_id;
        -- A-6�Ŏ擾�����󒍃^�C�v(�V�K/����).�󒍃J�e�S��=�󒍂̏ꍇ
--        ELSIF (gt_new_transaction_type_name = gv_cate_order) THEN
        ELSIF (gt_new_transaction_catg_code = gv_cate_order) THEN
          -- �󒍃^�C�vID<--A-6�Ŏ擾�����󒍃^�C�v(�V�K/����).����^�C�vID
          gt_xoh_order_type_id(gn_idx_hd) := gt_new_transaction_type_id;
        END IF;
      END IF;
--
      -- �g�DID
      gt_xoh_organization_id(gn_idx_hd)       := gt_order_all_tbl(in_idx).hd_organization_id;
      -- �ŐV�t���O
      gt_xoh_latest_external_flag(gn_idx_hd)  := gv_flag_on;
      -- �󒍓�
      gt_xoh_ordered_date(gn_idx_hd)          := gt_order_all_tbl(in_idx).hd_ordered_date;
      -- �ڋqID
      gt_xoh_customer_id(gn_idx_hd)           := gt_order_all_tbl(in_idx).hd_customer_id;
      -- �ڋq
      gt_xoh_customer_code(gn_idx_hd)         := gt_order_all_tbl(in_idx).hd_customer_code;
      -- �o�א�ID
      gt_xoh_deliver_to_id(gn_idx_hd)         := gt_order_all_tbl(in_idx).hd_deliver_to_id;
      -- �o�א�
      gt_xoh_deliver_to(gn_idx_hd)            := gt_order_all_tbl(in_idx).hd_deliver_to;
      -- �o�׎w��
      gt_xoh_shipping_instructions(gn_idx_hd) := gt_order_all_tbl(in_idx).hd_shipping_instructions;
      -- �˗�No
      gt_xoh_request_no(gn_idx_hd)            := gt_order_all_tbl(in_idx).hd_request_no;
      -- �X�e�[�^�X
      gt_xoh_req_status(gn_idx_hd)            := gt_order_all_tbl(in_idx).hd_req_status;
      -- �o�ח\���
      gt_xoh_schedule_ship_date(gn_idx_hd)    := gt_order_all_tbl(in_idx).hd_schedule_ship_date;
      -- ���ח\���
      gt_xoh_schedule_arrival_date(gn_idx_hd) := gt_order_all_tbl(in_idx).hd_schedule_arrival_date;
      -- �o�׌�ID
      gt_xoh_deliver_from_id(gn_idx_hd)       := gt_order_all_tbl(in_idx).hd_deliver_from_id;
      -- �o�׌��ۊǏꏊ
      gt_xoh_deliver_from(gn_idx_hd)          := gt_order_all_tbl(in_idx).hd_deliver_from;
      -- �Ǌ����_
      gt_xoh_head_sales_branch(gn_idx_hd)     := gt_order_all_tbl(in_idx).hd_head_sales_branch;
      -- ���i�敪
      gt_xoh_prod_class(gn_idx_hd)            := gt_order_all_tbl(in_idx).hd_prod_class;
      -- ���v����<--NULL
      gt_xoh_sum_quantity(gn_idx_hd)          := NULL;
      -- �o�א�_����ID
      gt_xoh_result_deliver_to_id(gn_idx_hd)  := gt_order_all_tbl(in_idx).hd_result_deliver_to_id;
      -- �o�א�_����
      gt_xoh_result_deliver_to(gn_idx_hd)     := gt_order_all_tbl(in_idx).hd_result_deliver_to;
      -- �o�ד�
      gt_xoh_shipped_date(gn_idx_hd)          := gt_order_all_tbl(in_idx).hd_shipped_date;
      -- ���ד�
      gt_xoh_arrival_date(gn_idx_hd)          := gt_order_all_tbl(in_idx).hd_arrival_date;
      -- ���ъǗ�����
      gt_xoh_perform_management_dept(gn_idx_hd) := gt_order_all_tbl(in_idx).hd_perform_management_dept;
      gt_registered_sequence                    := gt_registered_sequence + 1;
      -- �o�^����<--A-7�ō쐬�����o�^���� + 1
      gt_xoh_registered_sequence(gn_idx_hd)     := gt_registered_sequence;
    END IF;
--
    gt_xoh_created_by(gn_idx_hd)             := gt_user_id;         -- �쐬��
    gt_xoh_creation_date(gn_idx_hd)          := gt_sysdate;         -- �쐬��
    gt_xoh_last_updated_by(gn_idx_hd)        := gt_user_id;         -- �ŏI�X�V��
    gt_xoh_last_update_date(gn_idx_hd)       := gt_sysdate;         -- �ŏI�X�V��
    gt_xoh_last_update_login(gn_idx_hd)      := gt_login_id;        -- �ŏI�X�V���O�C��
    gt_xoh_request_id(gn_idx_hd)             := gt_conc_request_id; -- �v��ID
    gt_xoh_program_application_id(gn_idx_hd) := gt_prog_appl_id;    -- �A�v���P�[�V����ID
    gt_xoh_program_id(gn_idx_hd)             := gt_conc_program_id; -- �R���J�����g�E�v���O����ID
    gt_xoh_program_update_date(gn_idx_hd)    := gt_sysdate;         -- �v���O�����X�V��
--
    -- A-15�ɂ����Ď󒍃w�b�_�A�h�I���̍��v���ʂ��Čv�Z���čX�V���邽�߂ɂ����Ŏ󒍃w�b�_�A�h�I��ID��ޔ�����
    gn_idx_hd_a15 := gn_idx_hd_a15 + 1;
    gt_xoh_a7_13_order_header_id(gn_idx_hd_a15) := gn_seq_a9; -- �󒍃w�b�_�A�h�I��ID
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_order_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : set_latest_external_flag
   * Description      : �ŐV�t���O�X�V���쐬���� (A-10)
   ***********************************************************************************/
  PROCEDURE set_latest_external_flag(
    in_idx                IN  NUMBER,              -- 1.�z��C���f�b�N�X
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_latest_external_flag';  -- �v���O������
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
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �z��C���f�b�N�X �󒍃w�b�_�A�h�I�� �ŐV�t���O �ꊇ�X�V�p
    gn_idx_hd_a10 := gn_idx_hd_a10 + 1;
--
    -- �󒍃w�b�_�A�h�I��ID
    gt_xoh_a10_order_header_id(gn_idx_hd_a10) := gt_order_all_tbl(in_idx).hd_order_header_id;
    gt_xoh_a10_last_updated_by(gn_idx_hd_a10) := gt_user_id;         -- �ŏI�X�V��
    gt_xoh_a10_last_update_date(gn_idx_hd_a10)  := gt_sysdate;         -- �ŏI�X�V��
    gt_xoh_a10_last_update_login(gn_idx_hd_a10) := gt_login_id;        -- �ŏI�X�V���O�C��
    gt_xoh_a10_request_id(gn_idx_hd_a10)        := gt_conc_request_id; -- �v��ID
    gt_xoh_a10_program_appli_id(gn_idx_hd_a10)  := gt_prog_appl_id;    -- �A�v���P�[�V����ID
    gt_xoh_a10_program_id(gn_idx_hd_a10)        := gt_conc_program_id; -- �v���O����ID
    gt_xoh_a10_program_update_date(gn_idx_hd_a10) := gt_sysdate;         -- �v���O�����X�V��
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_latest_external_flag;
--
--
  /**********************************************************************************
   * Procedure Name   : set_order_lines
   * Description      : �q�֕ԕi���(����)�쐬���� (A-11)
   ***********************************************************************************/
  PROCEDURE set_order_lines(
    in_idx                IN  NUMBER,                                     -- 1.�z��C���f�b�N�X
    it_item_no            IN  ic_item_mst_b.item_no%TYPE,                 -- 2.�i�ڃR�[�h
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,      -- 3.����
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'set_order_lines';  -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_seq         NUMBER;  -- �V�[�P���X�i�󒍖��ׁj
    ln_seq_lot     NUMBER;  -- �V�[�P���X�i�ړ����b�g�ڍׁj
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �q�֕ԕi���쐬����(�󒍖��׃A�h�I���P��)
    gn_output_lines_cnt := gn_output_lines_cnt + 1;
--
    SELECT xxwsh_order_lines_all_s1.NEXTVAL         -- �V�[�P���X�擾
    INTO   ln_seq                                   -- �󒍖��׃A�h�I��ID
    FROM   dual;
--
    --A-6�œ���˗�No�����o�ł��Ȃ������ꍇ
    IF (gt_order_all_tbl.COUNT = 0) THEN
--
      -- �z��C���f�b�N�X �󒍖��׃A�h�I�� �ꊇ�o�^�p
      gn_idx_ln := gn_idx_ln + 1;
--
      -- �󒍖��׃A�h�I��ID<--�V�[�P���X
      gt_xol_order_line_id(gn_idx_ln)           := ln_seq;
      -- �󒍃w�b�_�A�h�I��ID<--A-9�Őݒ肵���󒍃w�b�_�A�h�I��ID
      gt_xol_order_header_id(gn_idx_ln)         := gn_seq_a9;
      -- ���הԍ�<--�w�b�_�P�ʂ�1����̔�
      gt_line_number_a11                        := gt_line_number_a11 + 1;
      gt_xol_order_line_number(gn_idx_ln)       := gt_line_number_a11;
      -- �˗�No<--A-5�ŕϊ������ϊ���˗�No
      gt_xol_request_no(gn_idx_ln)              := gt_request_no;
      -- �o�וi��ID<--A-3�Ŏ擾�����i��ID
      gt_xol_shipping_item_id(gn_idx_ln)        := gt_item_id;
      -- �o�וi��<--A-2�Ŏ擾�����i�ڃR�[�h
      gt_xol_shipping_item_code(gn_idx_ln)      := it_item_no;
      -- ����<--A-2�Ŏ擾�������ʂ̐�Βl
      gt_xol_quantity(gn_idx_ln)                := ABS(it_quantity_total);
      -- �P��<--A-3�Ŏ擾�����P��
      gt_xol_uom_code(gn_idx_ln)                := gt_item_um;
      -- �o�׎��ѐ���<--NULL
      gt_xol_shipped_quantity(gn_idx_ln)        := NULL;
      -- ���_�˗�����<--A-2�Ŏ擾�������ʂ̐�Βl
      gt_xol_based_request_quantity(gn_idx_ln)  := ABS(it_quantity_total);
      -- �˗��i��ID<--A-3�Ŏ擾�����i��ID
      gt_xol_request_item_id(gn_idx_ln)         := gt_item_id;
      -- �˗��i��<--A-2�Ŏ擾�����i�ڃR�[�h
      gt_xol_request_item_code(gn_idx_ln)       := it_item_no;
      -- �q�֕ԕi�C���^�t�F�[�X�σt���O<--NULL
      gt_xol_rm_if_flg(gn_idx_ln)               := NULL;
--
      gt_xol_created_by(gn_idx_ln)             := gt_user_id;         -- �쐬��
      gt_xol_creation_date(gn_idx_ln)          := gt_sysdate;         -- �쐬��
      gt_xol_last_updated_by(gn_idx_ln)        := gt_user_id;         -- �ŏI�X�V��
      gt_xol_last_update_date(gn_idx_ln)       := gt_sysdate;         -- �ŏI�X�V��
      gt_xol_last_update_login(gn_idx_ln)      := gt_login_id;        -- �ŏI�X�V���O�C��
      gt_xol_request_id(gn_idx_ln)             := gt_conc_request_id; -- �v��ID
      gt_xol_program_application_id(gn_idx_ln) := gt_prog_appl_id;    -- �A�v���P�[�V����ID
      gt_xol_program_id(gn_idx_ln)             := gt_conc_program_id; -- �R���J�����g�E�v���O����ID
      gt_xol_program_update_date(gn_idx_ln)    := gt_sysdate;         -- �v���O�����X�V��
--
      --���א��ʃ`�F�b�N
-- mod start 2009/01/15 ver1.10 by M.Uehara
--      IF (it_quantity_total >= 0) THEN   -- A-2�Ŏ擾��������>=0�̏ꍇ
--        gb_posi_flg := TRUE;
--      ELSE                               -- A-2�Ŏ擾��������<0�̏ꍇ
--        gb_nega_flg := TRUE;
--      END IF;
      IF (it_quantity_total > 0) THEN   -- A-2�Ŏ擾��������>0�̏ꍇ
        gb_posi_flg := TRUE;
      ELSIF (it_quantity_total < 0) THEN   -- A-2�Ŏ擾��������<0�̏ꍇ
        gb_nega_flg := TRUE;
      END IF;
-- mod end 2009/01/15 ver1.10 by M.Uehara
--
    --***************************************************************************************
    --A-6�œ���˗�No�����o�ł����ꍇ
    ELSE
--
      -------------�󒍖���---------------------------------------------------------------
--
      -- �z��C���f�b�N�X �󒍖��׃A�h�I�� �ꊇ�o�^�p
      gn_idx_ln := gn_idx_ln + 1;
--
      -- �󒍖��׃A�h�I��ID<--�V�[�P���X
      gt_xol_order_line_id(gn_idx_ln) := ln_seq;
--
      -- �󒍃w�b�_�A�h�I��ID<--A-9�Őݒ肵���󒍃w�b�_�A�h�I��ID
      gt_xol_order_header_id(gn_idx_ln)        := gn_seq_a9;
      -- ���הԍ�<--�w�b�_�P�ʂ�1����̔�
      gt_line_number_a11                       := gt_line_number_a11 + 1;
      gt_xol_order_line_number(gn_idx_ln)      := gt_line_number_a11;
      -- �˗�No<--A-5�ŕϊ������ϊ���˗�No
      gt_xol_request_no(gn_idx_ln)             := gt_request_no;
      -- �o�וi��ID<--A-6�Ŏ擾�����o�וi��ID
      gt_xol_shipping_item_id(gn_idx_ln) := gt_order_all_tbl(in_idx).ln_shipping_inventory_item_id;
      -- �o�וi��<--A-6�Ŏ擾�����i�ڃR�[�h
      gt_xol_shipping_item_code(gn_idx_ln) := gt_order_all_tbl(in_idx).ln_shipping_item_code;
      -- ����<--A-18�ŎZ�o�������Z���ʂ̐�Βl
      gt_xol_quantity(gn_idx_ln)               := ABS(gt_sum_quantity);
      -- �P��<--A-6�Ŏ擾�����P��
      gt_xol_uom_code(gn_idx_ln)               := gt_order_all_tbl(in_idx).ln_uom_code;
      -- �o�׎��ѐ���<--A-6�Ŏ擾�����o�׎��ѐ���
      gt_xol_shipped_quantity(gn_idx_ln)       := gt_order_all_tbl(in_idx).ln_shipped_quantity;
      -- ���_�˗�����<--A-18�ŎZ�o�������Z���ʂ̐�Βl
      gt_xol_based_request_quantity(gn_idx_ln) := ABS(gt_sum_quantity);
      -- �˗��i��ID<--A-6�Ŏ擾�����˗��i��ID
      gt_xol_request_item_id(gn_idx_ln)        := gt_order_all_tbl(in_idx).ln_request_item_id;
      -- �˗��i��<--A-6�Ŏ擾�����˗��i��
      gt_xol_request_item_code(gn_idx_ln)      := gt_order_all_tbl(in_idx).ln_request_item_code;
      -- �q�֕ԕi�C���^�t�F�[�X�σt���O<--NULL
      gt_xol_rm_if_flg(gn_idx_ln)              := NULL;
--
      gt_xol_created_by(gn_idx_ln)             := gt_user_id;          -- �쐬��
      gt_xol_creation_date(gn_idx_ln)          := gt_sysdate;          -- �쐬��
      gt_xol_last_updated_by(gn_idx_ln)        := gt_user_id;          -- �ŏI�X�V��
      gt_xol_last_update_date(gn_idx_ln)       := gt_sysdate;          -- �ŏI�X�V��
      gt_xol_last_update_login(gn_idx_ln)      := gt_login_id;         -- �ŏI�X�V���O�C��
      gt_xol_request_id(gn_idx_ln)             := gt_conc_request_id;  -- �v��ID
      gt_xol_program_application_id(gn_idx_ln) := gt_prog_appl_id;     -- �A�v���P�[�V����ID
      gt_xol_program_id(gn_idx_ln)             := gt_conc_program_id;  -- �R���J�����g�E�v���O����ID
      gt_xol_program_update_date(gn_idx_ln)    := gt_sysdate;          -- �v���O�����X�V��
--
      --���א��ʃ`�F�b�N
-- mod start 2009/01/15 ver1.10 by M.Uehara
--      IF (gt_sum_quantity >= 0) THEN     -- A-18�ŎZ�o�������Z����>=0�̏ꍇ
--        gb_posi_flg := TRUE;
--      ELSE                               -- A-18�ŎZ�o�������Z����<0�̏ꍇ
--        gb_nega_flg := TRUE;
--      END IF;
      IF (gt_sum_quantity > 0) THEN     -- A-18�ŎZ�o�������Z����>=�̏ꍇ
        gb_posi_flg := TRUE;
      ELSIF (gt_sum_quantity < 0) THEN   -- A-18�ŎZ�o�������Z����<0�̏ꍇ
        gb_nega_flg := TRUE;
      END IF;
-- mod end 2009/01/15 ver1.10 by M.Uehara
--
      -------------�ړ����b�g�ڍ�-------------------------------------------------------
--
    -- �q�֕ԕi���쐬����(�ړ����b�g�ڍגP��)
    gn_output_lot_cnt := gn_output_lot_cnt + 1;
--
      SELECT xxinv_mov_lot_s1.NEXTVAL              -- �V�[�P���X�擾
      INTO   ln_seq_lot                            -- ���b�g�ڍ�ID
      FROM   dual;
--
      -- �z��C���f�b�N�X �ړ����b�g�ڍ� �ꊇ�o�^�p
      gn_idx_lot := gn_idx_lot + 1;
--
      -- ���b�g�ڍ�ID
      gt_xml_mov_lot_dtl_id(gn_idx_lot)       := ln_seq_lot; -- �V�[�P���X�Ŏ擾�����l
      -- ����ID
      gt_xml_mov_line_id(gn_idx_lot)          := ln_seq;    -- �󒍖��׃A�h�I��ID�ɃZ�b�g�����l
      -- �����^�C�v
      gt_xml_document_type_code(gn_idx_lot)   := gt_order_all_tbl(in_idx).lo_document_type_code;
      -- ���R�[�h�^�C�v
      gt_xml_record_type_code(gn_idx_lot)     := gt_order_all_tbl(in_idx).lo_record_type_code;
      -- OPM�i��ID
      gt_xml_item_id(gn_idx_lot)              := gt_order_all_tbl(in_idx).lo_item_id;
      -- �i��
      gt_xml_item_code(gn_idx_lot)            := gt_order_all_tbl(in_idx).lo_item_code;
      -- ���b�gID
      gt_xml_lot_id(gn_idx_lot)               := gt_order_all_tbl(in_idx).lo_lot_id;
      -- ���b�gNo
      gt_xml_lot_no(gn_idx_lot)               := gt_order_all_tbl(in_idx).lo_lot_no;
      -- ���ѓ�
      gt_xml_actual_date(gn_idx_lot)          := gt_order_all_tbl(in_idx).lo_actual_date;
      -- ���ѐ���
      gt_xml_actual_quantity(gn_idx_lot)      := gt_order_all_tbl(in_idx).lo_actual_quantity;
      -- �����蓮�����敪
      gt_xml_automanual_rsv_class(gn_idx_lot) := gt_order_all_tbl(in_idx).lo_automanual_reserve_class;
--
      gt_xml_created_by(gn_idx_lot)              := gt_user_id;          -- �쐬��
      gt_xml_creation_date(gn_idx_lot)           := gt_sysdate;          -- �쐬��
      gt_xml_last_updated_by(gn_idx_lot)         := gt_user_id;          -- �ŏI�X�V��
      gt_xml_last_update_date(gn_idx_lot)        := gt_sysdate;          -- �ŏI�X�V��
      gt_xml_last_update_login(gn_idx_lot)       := gt_login_id;         -- �ŏI�X�V���O�C��
      gt_xml_request_id(gn_idx_lot)              := gt_conc_request_id;  -- �v��ID
      gt_xml_program_application_id(gn_idx_lot)  := gt_prog_appl_id;     -- �A�v���P�[�V����ID
      gt_xml_program_id(gn_idx_lot)              := gt_conc_program_id;  -- �R���J�����g�E�v���O����ID
      gt_xml_program_update_date(gn_idx_lot)     := gt_sysdate;          -- �v���O�����X�V��
--
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_order_lines;
--
--
  /**********************************************************************************
   * Procedure Name   : set_order_lines_2
   * Description      : �q�֕ԕi���(����)�쐬���� (A-11-2)
   ***********************************************************************************/
  PROCEDURE set_order_lines_2(
    it_item_no            IN  ic_item_mst_b.item_no%TYPE,                 -- 1.�i�ڃR�[�h
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,      -- 2.����
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'set_order_lines_2';  -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_seq          NUMBER;  -- �V�[�P���X�i�󒍖��ׁj
    ln_seq_lot      NUMBER;  -- �V�[�P���X�i�ړ����b�g�ڍׁj
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �q�֕ԕi���쐬����(�󒍖��׃A�h�I���P��)
    gn_output_lines_cnt := gn_output_lines_cnt + 1;
--
    -- �z��C���f�b�N�X �󒍖��׃A�h�I�� �ꊇ�o�^�p
    gn_idx_ln := gn_idx_ln + 1;
--
    SELECT xxwsh_order_lines_all_s1.NEXTVAL         -- �V�[�P���X�擾
    INTO   ln_seq                                   -- �󒍖��׃A�h�I��ID
    FROM   dual;
--
    -- �󒍖��׃A�h�I��ID<--�V�[�P���X
    gt_xol_order_line_id(gn_idx_ln)           := ln_seq;
    -- �󒍃w�b�_�A�h�I��ID<--A-9�Őݒ肵���󒍃w�b�_�A�h�I��ID
    gt_xol_order_header_id(gn_idx_ln)         := gn_seq_a9;
    -- ���הԍ�<--�w�b�_�P�ʂ�1����̔�
    gt_line_number_a11                        := gt_line_number_a11 + 1;
    gt_xol_order_line_number(gn_idx_ln)       := gt_line_number_a11;
    -- �˗�No<--A-5�ŕϊ������ϊ���˗�No
    gt_xol_request_no(gn_idx_ln)              := gt_request_no;
    -- �o�וi��ID<--A-3�Ŏ擾�����i��ID
    gt_xol_shipping_item_id(gn_idx_ln)        := gt_item_id;
    -- �o�וi��<--A-2�Ŏ擾�����i�ڃR�[�h
    gt_xol_shipping_item_code(gn_idx_ln)      := it_item_no;
    -- ����<--A-2�Ŏ擾�������ʂ̐�Βl
    gt_xol_quantity(gn_idx_ln)                := ABS(it_quantity_total);
    -- �P��<--A-3�Ŏ擾�����P��
    gt_xol_uom_code(gn_idx_ln)                := gt_item_um;
    -- �o�׎��ѐ���<--NULL
    gt_xol_shipped_quantity(gn_idx_ln)        := NULL;
    -- ���_�˗�����<--A-2�Ŏ擾�������ʂ̐�Βl
    gt_xol_based_request_quantity(gn_idx_ln)  := ABS(it_quantity_total);
    -- �˗��i��ID<--A-3�Ŏ擾�����i��ID
    gt_xol_request_item_id(gn_idx_ln)         := gt_item_id;
    -- �˗��i��<--A-2�Ŏ擾�����i�ڃR�[�h
    gt_xol_request_item_code(gn_idx_ln)       := it_item_no;
    -- �q�֕ԕi�C���^�t�F�[�X�σt���O<--NULL
    gt_xol_rm_if_flg(gn_idx_ln)               := NULL;
--
    gt_xol_created_by(gn_idx_ln)             := gt_user_id;         -- �쐬��
    gt_xol_creation_date(gn_idx_ln)          := gt_sysdate;         -- �쐬��
    gt_xol_last_updated_by(gn_idx_ln)        := gt_user_id;         -- �ŏI�X�V��
    gt_xol_last_update_date(gn_idx_ln)       := gt_sysdate;         -- �ŏI�X�V��
    gt_xol_last_update_login(gn_idx_ln)      := gt_login_id;        -- �ŏI�X�V���O�C��
    gt_xol_request_id(gn_idx_ln)             := gt_conc_request_id; -- �v��ID
    gt_xol_program_application_id(gn_idx_ln) := gt_prog_appl_id;    -- �A�v���P�[�V����ID
    gt_xol_program_id(gn_idx_ln)             := gt_conc_program_id; -- �R���J�����g�E�v���O����ID
    gt_xol_program_update_date(gn_idx_ln)    := gt_sysdate;         -- �v���O�����X�V��
--
    --���א��ʃ`�F�b�N
-- mod start 2009/01/15 ver1.10 by M.Uehara
--    IF (it_quantity_total >= 0) THEN   -- A-2�Ŏ擾��������>=0�̏ꍇ
--      gb_posi_flg := TRUE;
--    ELSE                               -- A-2�Ŏ擾��������<0�̏ꍇ
--      gb_nega_flg := TRUE;
--    END IF;
    IF (it_quantity_total > 0) THEN   -- A-2�Ŏ擾��������>0�̏ꍇ
      gb_posi_flg := TRUE;
    ELSIF (it_quantity_total < 0) THEN  -- A-2�Ŏ擾��������<0�̏ꍇ
      gb_nega_flg := TRUE;
    END IF;
-- mod end 2009/01/15 ver1.10 by M.Uehara
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_order_lines_2;
--
--
  /**********************************************************************************
   * Procedure Name   : set_upd_order_headers
   * Description      : �q�֕ԕi�X�V���(�w�b�_)�쐬���� (A-12)
   ***********************************************************************************/
  PROCEDURE set_upd_order_headers(
    in_idx                IN  NUMBER,                                     -- 1.�z��C���f�b�N�X
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,      -- 2.����
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'set_upd_order_headers';  -- �v���O������
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
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �q�֕ԕi�X�V���쐬����(�󒍃w�b�_�A�h�I���P��)
    gn_output_upd_hd_cnt := gn_output_upd_hd_cnt + 1;
--
    -- �z��C���f�b�N�X �󒍃w�b�_�A�h�I�� �ꊇ�o�^�p
    gn_idx_hd_a12 := gn_idx_hd_a12 + 1;
--
    -- �󒍃w�b�_�A�h�I��ID
    gn_seq_a12 := gt_order_all_tbl(in_idx).hd_order_header_id;  -- A-13�A�Ŏg�p���邽�߃��[�N�ɑޔ�
    gt_xoh_a12_order_header_id(gn_idx_hd_a12) := gn_seq_a12;
--
    -- ���Z����>=0(��)�̏ꍇ
    IF (gt_sum_quantity >= 0) THEN
      -- A-6�Ŏ擾�����󒍃^�C�v(�V�K/����).�󒍃J�e�S��=�ԕi�̏ꍇ
--      IF (gt_new_transaction_type_name = gv_cate_return) THEN
      IF (gt_new_transaction_catg_code = gv_cate_return) THEN
        -- �󒍃^�C�vID<--A-6�Ŏ擾�����󒍃^�C�v(�V�K/����).����^�C�vID
        gt_xoh_a12_order_type_id(gn_idx_hd_a12) := gt_new_transaction_type_id;
      -- A-6�Ŏ擾�����󒍃^�C�v(�V�K/����).�󒍃J�e�S��=�󒍂̏ꍇ
--      ELSIF (gt_new_transaction_type_name = gv_cate_order) THEN
      ELSIF (gt_new_transaction_catg_code = gv_cate_order) THEN
        -- �󒍃^�C�vID<--A-6�Ŏ擾�����󒍃^�C�v(�ŏ�).����^�C�vID
        gt_xoh_a12_order_type_id(gn_idx_hd_a12) := gt_del_transaction_type_id;
      END IF;
    ELSE      -- ���Z����<0(��)�̏ꍇ
      -- A-6�Ŏ擾�����󒍃^�C�v(�V�K/����).�󒍃J�e�S��=�ԕi�̏ꍇ
--      IF (gt_new_transaction_type_name = gv_cate_return) THEN
      IF (gt_new_transaction_catg_code = gv_cate_return) THEN
        -- �󒍃^�C�vID<--A-6�Ŏ擾�����󒍃^�C�v(�ŏ�).����^�C�vID
        gt_xoh_a12_order_type_id(gn_idx_hd_a12) := gt_del_transaction_type_id;
      -- A-6�Ŏ擾�����󒍃^�C�v(�V�K/����).�󒍃J�e�S��=�󒍂̏ꍇ
--      ELSIF (gt_new_transaction_type_name = gv_cate_order) THEN
      ELSIF (gt_new_transaction_catg_code = gv_cate_order) THEN
        -- �󒍃^�C�vID<--A-6�Ŏ擾�����󒍃^�C�v(�V�K/����).����^�C�vID
        gt_xoh_a12_order_type_id(gn_idx_hd_a12) := gt_new_transaction_type_id;
      END IF;
    END IF;
--
    gt_xoh_a12_last_updated_by(gn_idx_hd_a12)     := gt_user_id;         -- �ŏI�X�V��
    gt_xoh_a12_last_update_date(gn_idx_hd_a12)    := gt_sysdate;         -- �ŏI�X�V��
    gt_xoh_a12_last_update_login(gn_idx_hd_a12)   := gt_user_id;         -- �ŏI�X�V���O�C��
    gt_xoh_a12_request_id(gn_idx_hd_a12)          := gt_conc_request_id; -- �v��ID
    gt_xoh_a12_program_appli_id(gn_idx_hd_a12)    := gt_prog_appl_id;    -- �A�v���P�[�V����ID
    gt_xoh_a12_program_id(gn_idx_hd_a12)          := gt_conc_program_id; -- �R���J�����g�E�v���O����ID
    gt_xoh_a12_program_update_date(gn_idx_hd_a12) := gt_sysdate;         -- �v���O�����X�V��
--
    -- A-15�ɂ����Ď󒍃w�b�_�A�h�I���̍��v���ʂ��Čv�Z���čX�V���邽�߂ɂ����Ŏ󒍃w�b�_�A�h�I��ID��ޔ�����
    gn_idx_hd_a15 := gn_idx_hd_a15 + 1;
    gt_xoh_a7_13_order_header_id(gn_idx_hd_a15) := gn_seq_a12; -- �󒍃w�b�_�A�h�I��ID
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_upd_order_headers;
--
--
  /**********************************************************************************
   * Procedure Name   : set_upd_order_lines_upd
   * Description      : �q�֕ԕi�X�V���(����)�쐬���� (A-13�@)  ����i�ڂ̖��׍X�V
   ***********************************************************************************/
  PROCEDURE set_upd_order_lines_upd(
    in_idx                IN  NUMBER,                                     -- 1.�z��C���f�b�N�X
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,      -- 2.����
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'set_upd_order_lines_upd';  -- �v���O������
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
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �q�֕ԕi�X�V���쐬����(�󒍖��׃A�h�I���P��)
    gn_output_upd_ln_cnt := gn_output_upd_ln_cnt + 1;
--
    -- �z��C���f�b�N�X �󒍖��׃A�h�I�� ���ʁE���_�˗����� �ꊇ�X�V�p
    gn_idx_ln_a13 := gn_idx_ln_a13 + 1;
--
    -- �󒍃w�b�_�A�h�I��ID<--A-12�őޔ������󒍃w�b�_�A�h�I��ID
    gt_xol_a13_order_header_id(gn_idx_ln_a13)     := gn_seq_a12;
    -- �󒍖��׃A�h�I��ID<--A-6�Ŏ擾�����󒍖��׃A�h�I��ID
    gt_xol_a13_order_line_id(gn_idx_ln_a13)       := gt_order_all_tbl(in_idx).ln_order_line_id;
    -- ����<--A-18�ŎZ�o�������Z���ʂ̐�Βl
    gt_xol_a13_quantity(gn_idx_ln_a13)            := ABS(gt_sum_quantity);
    -- ���_�˗�����<--A-18�ŎZ�o�������Z���ʂ̐�Βl
    gt_xol_a13_based_req_quant(gn_idx_ln_a13)     := ABS(gt_sum_quantity);
    gt_xol_a13_last_updated_by(gn_idx_ln_a13)     := gt_user_id;         -- �ŏI�X�V��
    gt_xol_a13_last_update_date(gn_idx_ln_a13)    := gt_sysdate;         -- �ŏI�X�V��
    gt_xol_a13_last_update_login(gn_idx_ln_a13)   := gt_login_id;        -- �ŏI�X�V���O�C��
    gt_xol_a13_request_id(gn_idx_ln_a13)          := gt_conc_request_id; -- �v��ID
    gt_xol_a13_program_appli_id(gn_idx_ln_a13)    := gt_prog_appl_id;    -- �A�v���P�[�V����ID
    gt_xol_a13_program_id(gn_idx_ln_a13)          := gt_conc_program_id; -- �R���J�����g�E�v���O����ID
    gt_xol_a13_program_update_date(gn_idx_ln_a13) := gt_sysdate;         -- �v���O�����X�V��
--
    --���א��ʃ`�F�b�N
-- mod start 2009/01/15 ver1.10 by M.Uehara
--    IF (gt_sum_quantity >= 0) THEN  -- A-18�ŎZ�o�������Z����>=0�̏ꍇ
--      gb_posi_flg := TRUE;
--    ELSE                            -- A-18�ŎZ�o�������Z����<0�̏ꍇ
--      gb_nega_flg := TRUE;
--    END IF;
    IF (gt_sum_quantity > 0) THEN  -- A-18�ŎZ�o�������Z����>0�̏ꍇ
      gb_posi_flg := TRUE;
    ELSIF (gt_sum_quantity < 0) THEN -- A-18�ŎZ�o�������Z����<0�̏ꍇ
      gb_nega_flg := TRUE;
    END IF;
-- mod end 2009/01/15 ver1.10 by M.Uehara
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_upd_order_lines_upd;
--
--
  /**********************************************************************************
   * Procedure Name   : set_upd_order_lines_ins
   * Description      : �q�֕ԕi�X�V���(����)�쐬���� (A-13�A) ����i�ڂ��Ȃ��̂Ŗ��ׂ̐V�K�쐬
   ***********************************************************************************/
  PROCEDURE set_upd_order_lines_ins(
    in_idx                IN  NUMBER,                                     -- 1.�z��C���f�b�N�X
    it_quantity_total     IN  xxwsh_reserve_interface.quantity%TYPE,      -- 2.����
    it_item_no            IN  ic_item_mst_b.item_no%TYPE,                 -- 3.�i�ڃR�[�h
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'set_upd_order_lines_ins';  -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_seq           NUMBER;     -- �V�[�P���X�i�󒍖��ׁj
    ln_seq_lot       NUMBER;     -- �V�[�P���X�i�ړ����b�g�ڍׁj
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �q�֕ԕi���쐬����(�󒍖��׃A�h�I���P��)
    gn_output_lines_cnt := gn_output_lines_cnt + 1;
--
    -- �z��C���f�b�N�X �󒍖��׃A�h�I�� �ꊇ�o�^�p
    gn_idx_ln := gn_idx_ln + 1;
--
    SELECT xxwsh_order_lines_all_s1.NEXTVAL         -- �V�[�P���X�擾
    INTO   ln_seq                                   -- �󒍖��׃A�h�I��ID
    FROM   dual;
--
    -- �󒍖��׃A�h�I��ID<--�V�[�P���X
    gt_xol_order_line_id(gn_idx_ln)       := ln_seq;
    -- �󒍃w�b�_�A�h�I��ID<--A-12�őޔ������󒍃w�b�_�A�h�I��ID
    gt_xol_order_header_id(gn_idx_ln)     := gn_seq_a12;
    -- ���הԍ�<--�w�b�_�P�ʂ�1����̔�
    gt_line_number_a11 := gt_line_number_a11 + 1;
    gt_xol_order_line_number(gn_idx_ln) := gt_line_number_a11;
    -- �˗�No<--A-5�ŕϊ������ϊ���˗�No
    gt_xol_request_no(gn_idx_ln)          := gt_request_no;
    -- �o�וi��ID<--A-3�Ŏ擾�����o�וi��ID
    gt_xol_shipping_item_id(gn_idx_ln)    := gt_item_id;
    -- �o�וi��<--A-2�Ŏ擾�����i�ڃR�[�h
    gt_xol_shipping_item_code(gn_idx_ln)  := it_item_no;
    -- ����<--A-12�Ŏ擾�������ʂ̐�Βl
    gt_xol_quantity(gn_idx_ln)            := ABS(it_quantity_total);
    -- �P��<--A-3�Ŏ擾�����P��
    gt_xol_uom_code(gn_idx_ln)            := gt_item_um;
    -- �o�׎��ѐ���<--NULL
    gt_xol_shipped_quantity(gn_idx_ln)    := NULL;
    -- ���_�˗�����<--A-2�Ŏ擾�������ʂ̐�Βl
    gt_xol_based_request_quantity(gn_idx_ln) := ABS(it_quantity_total);
    -- �˗��i��ID<--A-3�Ŏ擾�����˗��i��ID
    gt_xol_request_item_id(gn_idx_ln)     := gt_item_id;
    -- �˗��i��<--A-2�Ŏ擾�����˗��i��
    gt_xol_request_item_code(gn_idx_ln)   := it_item_no;
    -- �q�֕ԕi�C���^�t�F�[�X�σt���O<--NULL
    gt_xol_rm_if_flg(gn_idx_ln)           := NULL;
    gt_xol_created_by(gn_idx_ln)          := gt_user_id;           -- �쐬��
    gt_xol_creation_date(gn_idx_ln)       := gt_sysdate;           -- �쐬��
    gt_xol_last_updated_by(gn_idx_ln)     := gt_user_id;           -- �ŏI�X�V��
    gt_xol_last_update_date(gn_idx_ln)    := gt_sysdate;           -- �ŏI�X�V��
    gt_xol_last_update_login(gn_idx_ln)   := gt_login_id;          -- �ŏI�X�V���O�C��
    gt_xol_request_id(gn_idx_ln)          := gt_conc_request_id;   -- �v��ID
    gt_xol_program_application_id(gn_idx_ln) := gt_prog_appl_id;   -- �A�v���P�[�V����ID
    gt_xol_program_id(gn_idx_ln)          := gt_conc_program_id;   -- �R���J�����g�E�v���O����ID
    gt_xol_program_update_date(gn_idx_ln) := gt_sysdate;           -- �v���O�����X�V��
--
    --���א��ʃ`�F�b�N
    IF (it_quantity_total >= 0) THEN   -- A-2�Ŏ擾��������>=0�̏ꍇ
      gb_posi_flg := TRUE;
    ELSE                               -- A-2�Ŏ擾��������<0�̏ꍇ
      gb_nega_flg := TRUE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END set_upd_order_lines_ins;
--
--
  /**********************************************************************************
   * Procedure Name   : ins_order
   * Description      : �q�֕ԕi���o�^���� (A-14)
   ***********************************************************************************/
  PROCEDURE ins_order(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'ins_order';  -- �v���O������
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
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************************
    -- *** �󒍃w�b�_�A�h�I�� �ꊇ�o�^
    -- **************************************************
    <<ins_headers_loop>>
    FORALL i IN 1 .. gt_xoh_order_header_id.COUNT
      INSERT INTO xxwsh_order_headers_all              -- �󒍃w�b�_�A�h�I��
        (order_header_id                               -- �󒍃w�b�_�A�h�I��ID
        ,order_type_id                                 -- �󒍃^�C�vID
        ,organization_id                               -- �g�DID
        ,latest_external_flag                          -- �ŐV�t���O
        ,ordered_date                                  -- �󒍓�
        ,customer_id                                   -- �ڋqID
        ,customer_code                                 -- �ڋq
        ,deliver_to_id                                 -- �o�א�ID
        ,deliver_to                                    -- �o�א�
        ,shipping_instructions                         -- �o�׎w��
        ,request_no                                    -- �˗�No
        ,req_status                                    -- �X�e�[�^�X
        ,schedule_ship_date                            -- �o�ח\���
        ,schedule_arrival_date                         -- ���ח\���
        ,deliver_from_id                               -- �o�׌�ID
        ,deliver_from                                  -- �o�׌��ۊǏꏊ
        ,head_sales_branch                             -- �Ǌ����_
        ,prod_class                                    -- ���i�敪
        ,sum_quantity                                  -- ���v����
        ,result_deliver_to_id                          -- �o�א�_����ID
        ,result_deliver_to                             -- �o�א�_����
        ,shipped_date                                  -- �o�ד�
        ,arrival_date                                  -- ���ד�
-- 2009/01/13 H.Itou Add Start �{�ԏ�Q#981�Ή�
        ,actual_confirm_class                          -- ���ьv��ϋ敪
-- 2009/01/13 H.Itou Add End
        ,performance_management_dept                   -- ���ъǗ�����
        ,registered_sequence                           -- �o�^����
        ,created_by                                    -- �쐬��
        ,creation_date                                 -- �쐬��
        ,last_updated_by                               -- �ŏI�X�V��
        ,last_update_date                              -- �ŏI�X�V��
        ,last_update_login                             -- �ŏI�X�V���O�C��
        ,request_id                                    -- �v��ID
        ,program_application_id                        -- �A�v���P�[�V����ID
        ,program_id                                    -- �R���J�����g�E�v���O����ID
        ,program_update_date                           -- �v���O�����X�V��
        )
      VALUES
        (gt_xoh_order_header_id(i)                     -- �󒍃w�b�_�A�h�I��ID
        ,gt_xoh_order_type_id(i)                       -- �󒍃^�C�vID
        ,gt_xoh_organization_id(i)                     -- �g�DID
        ,gt_xoh_latest_external_flag(i)                -- �ŐV�t���O
        ,gt_xoh_ordered_date(i)                        -- �󒍓�
        ,gt_xoh_customer_id(i)                         -- �ڋqID
        ,gt_xoh_customer_code(i)                       -- �ڋq
        ,gt_xoh_deliver_to_id(i)                       -- �o�א�ID
        ,gt_xoh_deliver_to(i)                          -- �o�א�
        ,gt_xoh_shipping_instructions(i)               -- �o�׎w��
        ,gt_xoh_request_no(i)                          -- �˗�No
        ,gt_xoh_req_status(i)                          -- �X�e�[�^�X
        ,gt_xoh_schedule_ship_date(i)                  -- �o�ח\���
        ,gt_xoh_schedule_arrival_date(i)               -- ���ח\���
        ,gt_xoh_deliver_from_id(i)                     -- �o�׌�ID
        ,gt_xoh_deliver_from(i)                        -- �o�׌��ۊǏꏊ
        ,gt_xoh_head_sales_branch(i)                   -- �Ǌ����_
        ,gt_xoh_prod_class(i)                          -- ���i�敪
        ,gt_xoh_sum_quantity(i)                        -- ���v����
        ,gt_xoh_result_deliver_to_id(i)                -- �o�א�_����ID
        ,gt_xoh_result_deliver_to(i)                   -- �o�א�_����
        ,gt_xoh_shipped_date(i)                        -- �o�ד�
        ,gt_xoh_arrival_date(i)                        -- ���ד�
-- 2009/01/13 H.Itou Add Start �{�ԏ�Q#981�Ή�
        ,gv_flag_off                                   -- ���ьv��ϋ敪
-- 2009/01/13 H.Itou Add End
        ,gt_xoh_perform_management_dept(i)             -- ���ъǗ�����
        ,gt_xoh_registered_sequence(i)                 -- �o�^����
        ,gt_xoh_created_by(i)                          -- �쐬��
        ,gt_xoh_creation_date(i)                       -- �쐬��
        ,gt_xoh_last_updated_by(i)                     -- �ŏI�X�V��
        ,gt_xoh_last_update_date(i)                    -- �ŏI�X�V��
        ,gt_xoh_last_update_login(i)                   -- �ŏI�X�V���O�C��
        ,gt_xoh_request_id(i)                          -- �v��ID
        ,gt_xoh_program_application_id(i)              -- �A�v���P�[�V����ID
        ,gt_xoh_program_id(i)                          -- �R���J�����g�E�v���O����ID
        ,gt_xoh_program_update_date(i)                 -- �v���O�����X�V��
      );
--
    -- **************************************************
    -- *** �󒍖��׃A�h�I�� �ꊇ�o�^
    -- **************************************************
    <<ins_lines_loop>>
    FORALL i IN 1 .. gt_xol_order_line_id.COUNT
      INSERT INTO xxwsh_order_lines_all                 -- �󒍖��׃A�h�I��
        (order_line_id                                  -- �󒍖��׃A�h�I��ID
        ,order_header_id                                -- �󒍃w�b�_�A�h�I��ID
        ,order_line_number                              -- ���הԍ�
        ,request_no                                     -- �˗�No
        ,shipping_inventory_item_id                     -- �o�וi��ID
        ,shipping_item_code                             -- �o�וi��
        ,quantity                                       -- ����
        ,uom_code                                       -- �P��
        ,shipped_quantity                               -- �o�׎��ѐ���
        ,based_request_quantity                         -- ���_�˗�����
        ,request_item_id                                -- �˗��i��ID
        ,request_item_code                              -- �˗��i��
        ,delete_flag                                    -- �폜�t���O
        ,rm_if_flg                                      -- �q�֕ԕi�C���^�t�F�[�X�σt���O
        ,created_by                                     -- �쐬��
        ,creation_date                                  -- �쐬��
        ,last_updated_by                                -- �ŏI�X�V��
        ,last_update_date                               -- �ŏI�X�V��
        ,last_update_login                              -- �ŏI�X�V���O�C��
        ,request_id                                     -- �v��ID
        ,program_application_id                         -- �A�v���P�[�V����ID
        ,program_id                                     -- �R���J�����g�E�v���O����ID
        ,program_update_date                            -- �v���O�����X�V��
        )
      VALUES
        (gt_xol_order_line_id(i)                        -- �󒍖��׃A�h�I��ID
        ,gt_xol_order_header_id(i)                      -- �󒍃w�b�_�A�h�I��ID
        ,gt_xol_order_line_number(i)                    -- ���הԍ�
        ,gt_xol_request_no(i)                           -- �˗�No
        ,gt_xol_shipping_item_id(i)                     -- �o�וi��ID
        ,gt_xol_shipping_item_code(i)                   -- �o�וi��
        ,gt_xol_quantity(i)                             -- ����
        ,gt_xol_uom_code(i)                             -- �P��
        ,gt_xol_shipped_quantity(i)                     -- �o�׎��ѐ���
        ,gt_xol_based_request_quantity(i)               -- ���_�˗�����
        ,gt_xol_request_item_id(i)                      -- �˗��i��ID
        ,gt_xol_request_item_code(i)                    -- �˗��i��
        ,gv_flag_off                                    -- �폜�t���O
        ,gv_flag_off                                    -- �q�֕ԕi�C���^�t�F�[�X�σt���O
        --,gt_xol_rm_if_flg(i)                            -- �q�֕ԕi�C���^�t�F�[�X�σt���O
        ,gt_xol_created_by(i)                           -- �쐬��
        ,gt_xol_creation_date(i)                        -- �쐬��
        ,gt_xol_last_updated_by(i)                      -- �ŏI�X�V��
        ,gt_xol_last_update_date(i)                     -- �ŏI�X�V��
        ,gt_xol_last_update_login(i)                    -- �ŏI�X�V���O�C��
        ,gt_xol_request_id(i)                           -- �v��ID
        ,gt_xol_program_application_id(i)               -- �A�v���P�[�V����ID
        ,gt_xol_program_id(i)                           -- �R���J�����g�E�v���O����ID
        ,gt_xol_program_update_date(i)                  -- �v���O�����X�V��
       );
--
    -- **************************************************
    -- *** �ړ����b�g�ڍ� �ꊇ�o�^
    -- **************************************************
    <<ins_lot_loop>>
    FORALL i IN 1 .. gt_xml_mov_lot_dtl_id.COUNT
      INSERT INTO xxinv_mov_lot_details                 -- �ړ����b�g�ڍ�
        (mov_lot_dtl_id                                 -- ���b�g�ڍ�ID
        ,mov_line_id                                    -- ����ID
        ,document_type_code                             -- �����^�C�v
        ,record_type_code                               -- ���R�[�h�^�C�v
        ,item_id                                        -- OPM�i��ID
        ,item_code                                      -- �i��
        ,lot_id                                         -- ���b�gID
        ,lot_no                                         -- ���b�gNo
        ,actual_date                                    -- ���ѓ�
        ,actual_quantity                                -- ���ѐ���
        ,automanual_reserve_class                       -- �����蓮�����敪
        ,created_by                                     -- �쐬��
        ,creation_date                                  -- �쐬��
        ,last_updated_by                                -- �ŏI�X�V��
        ,last_update_date                               -- �ŏI�X�V��
        ,last_update_login                              -- �ŏI�X�V���O�C��
        ,request_id                                     -- �v��ID
        ,program_application_id                         -- �A�v���P�[�V����ID
        ,program_id                                     -- �R���J�����g�E�v���O����ID
        ,program_update_date                            -- �v���O�����X�V��
        )
      VALUES
        (gt_xml_mov_lot_dtl_id(i)                       -- ���b�g�ڍ�ID
        ,gt_xml_mov_line_id(i)                          -- ����ID
        ,gt_xml_document_type_code(i)                   -- �����^�C�v
        ,gt_xml_record_type_code(i)                     -- ���R�[�h�^�C�v
        ,gt_xml_item_id(i)                              -- OPM�i��ID
        ,gt_xml_item_code(i)                            -- �i��
        ,gt_xml_lot_id(i)                               -- ���b�gID
        ,gt_xml_lot_no(i)                               -- ���b�gNo
        ,gt_xml_actual_date(i)                          -- ���ѓ�
        ,gt_xml_actual_quantity(i)                      -- ���ѐ���
        ,gt_xml_automanual_rsv_class(i)                 -- �����蓮�����敪
        ,gt_xml_created_by(i)                           -- �쐬��
        ,gt_xml_creation_date(i)                        -- �쐬��
        ,gt_xml_last_updated_by(i)                      -- �ŏI�X�V��
        ,gt_xml_last_update_date(i)                     -- �ŏI�X�V��
        ,gt_xml_last_update_login(i)                    -- �ŏI�X�V���O�C��
        ,gt_xml_request_id(i)                           -- �v��ID
        ,gt_xml_program_application_id(i)               -- �A�v���P�[�V����ID
        ,gt_xml_program_id(i)                           -- �R���J�����g�E�v���O����ID
        ,gt_xml_program_update_date(i)                  -- �v���O�����X�V��
       );
--
    -- **************************************************
    -- *** �󒍃w�b�_�A�h�I�� �ŐV�t���O �ꊇ�X�V
    -- **************************************************
    <<upd_headers_a10_loop>>
    FORALL i IN 1 .. gt_xoh_a10_order_header_id.COUNT
      UPDATE
        xxwsh_order_headers_all  xoh                                   -- �󒍃w�b�_�A�h�I��
      SET
        xoh.latest_external_flag   = gv_flag_off                       -- �ŐV�t���O<--'N'
       ,xoh.last_updated_by        = gt_xoh_a10_last_updated_by(i)     -- �ŏI�X�V��
       ,xoh.last_update_date       = gt_xoh_a10_last_update_date(i)    -- �ŏI�X�V��
       ,xoh.last_update_login      = gt_xoh_a10_last_update_login(i)   -- �ŏI�X�V���O�C��
       ,xoh.request_id             = gt_xoh_a10_request_id(i)          -- �v��ID
       ,xoh.program_application_id = gt_xoh_a10_program_appli_id(i)    -- �A�v���P�[�V����ID
       ,xoh.program_id             = gt_xoh_a10_program_id(i)          -- �R���J�����g�E�v���O����ID
       ,xoh.program_update_date    = gt_xoh_a10_program_update_date(i) -- �v���O�����X�V��
      WHERE
        xoh.order_header_id = gt_xoh_a10_order_header_id(i);           -- �󒍃w�b�_�A�h�I��ID
--
    -- *********************************************************
    -- *** �󒍃w�b�_�A�h�I�� �󒍃^�C�v�E�o�^���� �ꊇ�X�V
    -- *********************************************************
    <<upd_headers_a12_loop>>
    FORALL i IN 1 .. gt_xoh_a12_order_header_id.COUNT
      UPDATE
          xxwsh_order_headers_all  xoh    -- �󒍃w�b�_�A�h�I��
      SET
         xoh.order_type_id          = gt_xoh_a12_order_type_id(i)       -- �󒍃^�C�vID
        ,xoh.last_updated_by        = gt_xoh_a12_last_updated_by(i)     -- �ŏI�X�V��
        ,xoh.last_update_date       = gt_xoh_a12_last_update_date(i)    -- �ŏI�X�V��
        ,xoh.last_update_login      = gt_xoh_a12_last_update_login(i)   -- �ŏI�X�V���O�C��
        ,xoh.request_id             = gt_xoh_a12_request_id(i)          -- �v��ID
        ,xoh.program_application_id = gt_xoh_a12_program_appli_id(i)    -- �A�v���P�[�V����ID
        ,xoh.program_id             = gt_xoh_a12_program_id(i)          -- �R���J�����g�E�v���O����ID
        ,xoh.program_update_date    = gt_xoh_a12_program_update_date(i) -- �v���O�����X�V��
      WHERE
        xoh.order_header_id = gt_xoh_a12_order_header_id(i);            -- �󒍃w�b�_�A�h�I��ID
--
    -- *********************************************************
    -- *** �󒍖��׃A�h�I�� ���ʁE���_�˗����� �ꊇ�X�V
    -- *********************************************************
    <<upd_lines_a13_loop>>
    FORALL i IN 1 .. gt_xol_a13_order_line_id.COUNT
      UPDATE
        xxwsh_order_lines_all  xol     -- �󒍖��׃A�h�I��
      SET
         xol.quantity               = gt_xol_a13_quantity(i)             -- ����
        ,xol.based_request_quantity = gt_xol_a13_based_req_quant(i)      -- ���_�˗�����
        ,xol.last_updated_by        = gt_xol_a13_last_updated_by(i)      -- �ŏI�X�V��
        ,xol.last_update_date       = gt_xol_a13_last_update_date(i)     -- �ŏI�X�V��
        ,xol.last_update_login      = gt_xol_a13_last_update_login(i)    -- �ŏI�X�V���O�C��
        ,xol.request_id             = gt_xol_a13_request_id(i)           -- �v��ID
        ,xol.program_application_id = gt_xol_a13_program_appli_id(i)     -- �A�v���P�[�V����ID
        ,xol.program_id             = gt_xol_a13_program_id(i)           -- �R���J�����g�E�v���O����ID
        ,xol.program_update_date    = gt_xol_a13_program_update_date(i)  -- �v���O�����X�V��
      WHERE
            xol.order_header_id = gt_xol_a13_order_header_id(i)          -- �󒍃w�b�_�A�h�I��ID
        AND xol.order_line_id   = gt_xol_a13_order_line_id(i);           -- �󒍖��׃A�h�I��ID
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_order;
--
--
  /**********************************************************************************
   * Procedure Name   : sum_lines_quantity
   * Description      : �q�֕ԕi���o�E���v���� (A-15)
   ***********************************************************************************/
  PROCEDURE sum_lines_quantity(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'sum_lines_quantity';  -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_sum_quantity  xxwsh_order_headers_all.sum_quantity%TYPE; -- �󒍃w�b�_�A�h�I��.���v����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************************
    -- *** �󒍃w�b�_�A�h�I���̍��v���ʂ����߂�
    -- **************************************************
    <<sum_quantity_loop>>
    FOR i IN 1 .. gt_xoh_a7_13_order_header_id.COUNT
    LOOP
      SELECT SUM(xol.quantity) AS quantity  -- �󒍖��׃A�h�I���̐��ʂ����v
      INTO   lt_sum_quantity
      FROM   xxwsh_order_headers_all  xoh,                          -- �󒍃w�b�_�A�h�I��
             xxwsh_order_lines_all    xol                           -- �󒍖��׃A�h�I��
      WHERE  xoh.order_header_id = gt_xoh_a7_13_order_header_id(i)  -- �󒍃w�b�_�A�h�I��ID
        AND  xoh.order_header_id = xol.order_header_id;              -- �󒍃w�b�_ID
--
      gt_xoh_a15_order_header_id(i) := gt_xoh_a7_13_order_header_id(i); -- �󒍃w�b�_�A�h�I��ID
      gt_xoh_a15_sum_quantity(i)        := lt_sum_quantity;    -- ���v����
      gt_xoh_a15_last_updated_by(i)     := gt_user_id;         -- �ŏI�X�V��
      gt_xoh_a15_last_update_date(i)    := gt_sysdate;         -- �ŏI�X�V��
      gt_xoh_a15_last_update_login(i)   := gt_login_id;        -- �ŏI�X�V���O�C��
      gt_xoh_a15_request_id(i)          := gt_conc_request_id; -- �v��ID
      gt_xoh_a15_program_appli_id(i)    := gt_prog_appl_id;    -- �A�v���P�[�V����ID
      gt_xoh_a15_program_id(i)          := gt_conc_program_id; -- �R���J�����g�E�v���O����ID
      gt_xoh_a15_program_update_date(i) := gt_sysdate;         -- �v���O�����X�V��
--
    END LOOP sum_quantity_loop;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END sum_lines_quantity;
--
--
  /**********************************************************************************
   * Procedure Name   : upd_headers_sum_quantity
   * Description      : �q�֕ԕi���ēo�^���� (A-16)
   ***********************************************************************************/
  PROCEDURE upd_headers_sum_quantity(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'upd_headers_sum_quantity'; -- �v���O������
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
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************************
    -- *** �󒍃w�b�_�A�h�I�� ���v���� �ꊇ�X�V
    -- **************************************************
    <<upd_headers_loop>>
    FORALL i IN 1 .. gt_xoh_a15_order_header_id.COUNT
      UPDATE
        xxwsh_order_headers_all  xoh                                   -- �󒍃w�b�_�A�h�I��
      SET
        xoh.sum_quantity           = gt_xoh_a15_sum_quantity(i),       -- ���v����
        xoh.last_updated_by        = gt_xoh_a15_last_updated_by(i),    -- �ŏI�X�V��
        xoh.last_update_date       = gt_xoh_a15_last_update_date(i),   -- �ŏI�X�V��
        xoh.last_update_login      = gt_xoh_a15_last_update_login(i),  -- �ŏI�X�V���O�C��
        xoh.request_id             = gt_xoh_a15_request_id(i),         -- �v��ID
        xoh.program_application_id = gt_xoh_a15_program_appli_id(i),   -- �A�v���P�[�V����ID
        xoh.program_id             = gt_xoh_a15_program_id(i),         -- �R���J�����g�E�v���O����ID
        xoh.program_update_date    = gt_xoh_a15_program_update_date(i) -- �v���O�����X�V��
      WHERE
        xoh.order_header_id = gt_xoh_a15_order_header_id(i);           -- �󒍃w�b�_�A�h�I��ID
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_headers_sum_quantity;
--
--
  /**********************************************************************************
   * Procedure Name   : del_reserve_interface
   * Description      : �q�֕ԕi�C���^�[�t�F�[�X���폜���� (A-17)
   ***********************************************************************************/
  PROCEDURE del_reserve_interface(
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100) := 'del_reserve_interface';  -- �v���O������
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
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_rtn_cd      BOOLEAN;         -- ���ʊ֐��̃��^�[���R�[�h
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- **************************************************
    -- *** �q�֕ԕi�C���^�[�t�F�[�X���폜
    -- **************************************************
    lb_rtn_cd := xxcmn_common_pkg.del_all_data(gv_xxwsh, gv_reserve_interface);
--
    IF (NOT lb_rtn_cd) THEN          -- ���ʊ֐��̃��^�[���R�[�h���G���[�̏ꍇ
      lv_errmsg := xxcmn_common_pkg.get_msg(
        gv_xxwsh,
        gv_xxwsh_truncate_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_reserve_interface;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf            OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    cv_req_status_confirm  CONSTANT VARCHAR2(2) := '04';    -- �o�׎��ьv���
--
    -- *** ���[�J���ϐ� ***
    lv_cntmsg              VARCHAR2(5000);     -- �����o�͗p���b�Z�[�W
--
    lt_req_statu           xxwsh_order_headers_all.req_status%TYPE;   -- �X�e�[�^�X
--
    lt_invoice_no_a2       xxwsh_reserve_interface.invoice_no%TYPE;   -- �O��A-2�`�[No
    lt_invoice_no_a6       xxwsh_order_headers_all.request_no%TYPE;   -- �O��A-6�`�[No
--
    ln_idx_a6              NUMBER;
--
    lb_break_flg_a2        BOOLEAN;       -- A-2�`�[No���u���C�N�����ꍇ��TRUE
    lb_break_flg_a6        BOOLEAN;       -- A-6�`�[No���u���C�N�����ꍇ��TRUE
--
    lb_a13upd_flg          BOOLEAN;       -- A-13�@�Ŗ��ׂ�UPDATE�����ꍇ(����i�ڂ��������ꍇ)��TRUE
--
--2008/08/07 Add ��
    lt_actual_class        xxwsh_order_headers_all.actual_confirm_class%TYPE;
--2008/08/07 Add ��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
    gn_input_reserve_cnt  := 0;  -- ���͌���(�q�֕ԕi�C���^�[�t�F�[�X)
--
    gn_output_headers_cnt := 0;  -- �q�֕ԕi���쐬����(�󒍃w�b�_�A�h�I���P��)
    gn_output_lines_cnt   := 0;  -- �q�֕ԕi���쐬����(�󒍖��׃A�h�I���P��)
    gn_output_lot_cnt     := 0;  -- �q�֕ԕi���쐬����(�ړ����b�g�ڍ�)
--
    gn_output_del_hd_cnt  := 0;  -- �q�֕ԕi�ŏ����쐬����(�󒍃w�b�_�A�h�I���P��)
    gn_output_del_ln_cnt  := 0;  -- �q�֕ԕi�ŏ����쐬����(�󒍖��׃A�h�I���P��)
    gn_output_del_lot_cnt := 0;  -- �q�֕ԕi�ŏ����쐬����(�ړ����b�g�ڍגP��)
--
    gn_output_upd_hd_cnt  := 0;  -- �q�֕ԕi�X�V���쐬����(�󒍃w�b�_�A�h�I���P��)
    gn_output_upd_ln_cnt  := 0;  -- �q�֕ԕi�X�V���쐬����(�󒍖��׃A�h�I���P��)
--
    gn_idx_hd     := 0;  -- �z��C���f�b�N�X �󒍃w�b�_�A�h�I�� �ꊇ�o�^�p
    gn_idx_ln     := 0;  -- �z��C���f�b�N�X �󒍖��׃A�h�I�� �ꊇ�o�^�p
    gn_idx_lot    := 0;  -- �z��C���f�b�N�X �ړ����b�g�ڍ� �ꊇ�o�^�p
--
    gn_idx_hd_a10 := 0;  -- �z��C���f�b�N�X �󒍃w�b�_�A�h�I�� �ŐV�t���O �ꊇ�X�V�p
    gn_idx_hd_a12 := 0;  -- �z��C���f�b�N�X �󒍃w�b�_�A�h�I�� �󒍃^�C�v�E�o�^���� �ꊇ�X�V�p
    gn_idx_ln_a13 := 0;  -- �z��C���f�b�N�X �󒍖��׃A�h�I�� ���ʁE���_�˗����� �ꊇ�X�V�p
    gn_idx_hd_a15 := 0;  -- �z��C���f�b�N�X �󒍃w�b�_�A�h�I�� ���v���� �ꊇ�X�V�p
--
    gt_registered_sequence := 0; -- �o�^����
    gt_line_number_a11     := 0; -- A-11�ŃZ�b�g���閾�הԍ�
    gt_sum_quantity        := 0; -- ���Z����
--
    -- ���[�J���ϐ��̏�����
    lt_invoice_no_a2 := ' ';       -- �O��A-2�`�[No������
    lt_invoice_no_a6 := ' ';       -- �O��A-6�`�[No������
--
    -- WHO�J�����̐ݒ�
    gt_user_id          := FND_GLOBAL.USER_ID;         -- �쐬��(�ŏI�X�V��)
    gt_sysdate          := SYSDATE;                    -- �쐬��(�ŏI�X�V��)
    gt_login_id         := FND_GLOBAL.LOGIN_ID;        -- �ŏI�X�V���O�C��
    gt_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID; -- �v��ID
    gt_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;    -- �A�v���P�[�V����ID
    gt_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID; -- �R���J�����g�E�v���O����ID
--
--
--------------------------------------------------------------------------------------
--  A-7�AA-8�AA-9�AA-10�AA-11�AA-11-2��ʂ鏈��(MD050�t���[�ł����B�̏���)�̌��O�_
--  �ȉ��̎��s��̂悤�ɂȂ�悤�ɍ쐬���܂���
-- I/F            ��                        ��
-- #10 30001    #10 30001                    #10 30001
-- #10 30003    #10 30002    --(���s��)--->  #10 30002
-- #20 30001    #10 30004                    #10 30003
--              #20 30002                    #10 30004
--                                           #20 30001
--                                           #20 30002
--
-- ��I/F��#10 30003�A#20 30001���ǂ�����Ď󒍂ɏo�͂��邩�����ł���(A-11-2�ŏo�͂���悤�ɂ��܂���)
-- ��I/F��#10 30001�A#10 30003��#10���A�����Ă���p�^�[�������ł���(�u���C�N������o�͂���悤�ɂ��܂���)
--
-- A-11�AA-11-2���ǂ̂悤�ɒʂ������|�C���g�Ǝv���܂�
-- lb_break_flg_a6�Agb_a11_flg�̂Q�̃t���O�Ő��䂵�Ă��܂��̂�
-- ��L�t���O������ON/OFF�����̂��𒆐S�ɒǂ��Ă����΂悢�Ǝv���܂�
--
--------------------------------------------------------------------------------------
--
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- �v���t�@�C���擾���� (A-1)
    -- ===============================
    get_profile(
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- �q�֕ԕi�C���^�[�t�@�C�X��񒊏o���� (A-2)
    -- ==============================================
    get_reserve_interface(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_warn)                     -- �x��
    OR (lv_retcode = gv_status_error) THEN               -- �G���[
      RAISE global_process_expt;
    END IF;
--
    <<gt_reserve_interface_tbl_loop>>
    FOR i IN gt_reserve_interface_tbl.FIRST .. gt_reserve_interface_tbl.LAST LOOP
--
      -- ===============================
      -- �ϐ��E�t���O�̏�����
      -- ===============================
       lb_a13upd_flg := FALSE;
--
      -- ===============================
      -- �O��A-2�`�[No�Ƃ̃u���C�N����
      -- ===============================
      --�O��A-2�`�[No�ƈقȂ�ꍇ
      -- A-2�`�[No���u���C�N�����ꍇ
      IF (gt_reserve_interface_tbl(i).invoice_no <> lt_invoice_no_a2) THEN
        lb_break_flg_a2 := TRUE;
        lb_break_flg_a6 := TRUE;
-- del start 2009/01/15 ver1.10 by M.Uehara
--
--        -- �ǂݍ���A-2�`�[No��O��A-2�`�[No�Ƃ��đޔ�
--        lt_invoice_no_a2 := gt_reserve_interface_tbl(i).invoice_no;
-- del start 2009/01/15 ver1.10 by M.Uehara
--
        -- ���א��ʃ`�F�b�N
        IF  (gb_posi_flg)
        AND (gb_nega_flg) THEN -- ����A-2�`�[No���Ŗ��ׂ̐��ʂɐ������������݂��Ă���ꍇ�̓G���[
-- mod start 2009/01/15 ver1.10 by M.Uehara
--          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_xxwsh_num_mix_err);
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxwsh,gv_xxwsh_num_mix_err,'invoice_no',lt_invoice_no_a2);
-- mod end 2009/01/15 ver1.10 by M.Uehara
          lv_errbuf := lv_errmsg;
          lv_retcode := gv_status_error;
          RAISE global_process_expt;
        ELSE                            -- �G���[���Ȃ���Ζ��׃`�F�b�N�t���O��������
          gb_posi_flg := FALSE;         -- �����p�t���O
          gb_nega_flg := FALSE;         -- �����p�t���O
        END IF;
-- add start 2009/01/15 ver1.10 by M.Uehara
--
        -- �ǂݍ���A-2�`�[No��O��A-2�`�[No�Ƃ��đޔ�
        lt_invoice_no_a2 := gt_reserve_interface_tbl(i).invoice_no;
-- add end 2009/01/15 ver1.10 by M.Uehara
--
      --�O��A-2�`�[No�Ɠ����ꍇ
      ELSE
        lb_break_flg_a2 := FALSE;
        lb_break_flg_a6 := FALSE;
      END IF;
--
      -- ===============================
      -- �}�X�^���݃`�F�b�N���� (A-3)
      -- ===============================
      check_master(
        gt_reserve_interface_tbl(i).invoice_no,            -- 1.A-2�`�[No
        gt_reserve_interface_tbl(i).item_no,               -- 2.�i�ڃR�[�h
        gt_reserve_interface_tbl(i).receive_base_code,     -- 3.���苒�_�R�[�h
        gt_reserve_interface_tbl(i).input_base_code,       -- 4.���͋��_�R�[�h
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �݌ɉ�v���ԃ`�F�b�N���� (A-4)
      -- ===============================
      check_stock(
        gt_reserve_interface_tbl(i).recorded_date,         -- 1.�v����t(����)
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �֘A�f�[�^�擾���� (A-5)
      -- ===============================
      get_order_type(
        gt_reserve_interface_tbl(i).invoice_class_1,       -- 1.�`��P
        gt_reserve_interface_tbl(i).invoice_no,            -- 2.A-2�`�[No
        gt_reserve_interface_tbl(i).recorded_date,         -- 3.�v����t(����) 2008/10/10 v1.5 M.Hirafuku ADD
        gt_reserve_interface_tbl(i).item_no,               -- 4.�i�ڃR�[�h     2008/10/10 v1.5 M.Hirafuku ADD
        gt_reserve_interface_tbl(i).quantity_total,        -- 5.����           2008/10/10 v1.5 M.Hirafuku ADD
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ����˗�No��񒊏o���� (A-6)
      -- ===============================
      get_order_all_tbl(
        gt_reserve_interface_tbl(i).recorded_date,         -- 1.�v����t�i�����j
        gt_reserve_interface_tbl(i).receive_base_code,     -- 2.���苒�_�R�[�h
        gt_reserve_interface_tbl(i).input_base_code,       -- 3.���͋��_�R�[�h
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ����˗�No��񂪒��o�ł����ꍇ
      IF (gt_order_all_tbl.COUNT > 0) THEN
--
        gb_a11_flg := FALSE;  -- �t���O������
--
        <<gt_order_all_tbl_loop>>
        FOR j IN gt_order_all_tbl.FIRST .. gt_order_all_tbl.LAST LOOP
--
          ln_idx_a6 := j;      -- LOOP�̊O��A-13�A��index�̒l���g�p���邽�ߕϐ��ɑޔ�
--
          -- ===========================================
          -- ���Z���ʂ̎Z�o (A-18)
          -- ===========================================
          -- ���Z����<--A-2�Ŏ擾�������� + A-6�Ŏ擾�������Z�p����
          gt_sum_quantity := gt_reserve_interface_tbl(i).quantity_total
            +  gt_order_all_tbl(ln_idx_a6).ln_add_quantity;
--
          -- �o�׎��ьv��ς̏ꍇ
          -- LOOP�𔲂�������ŏo�׎��ьv��ς��ۂ��̔��肪�K�v�Ȃ̂ł����ŕϐ��ɑޔ����Ă���
          lt_req_statu := gt_order_all_tbl(ln_idx_a6).hd_req_status;
--2008/08/07 Add ��
          lt_actual_class := gt_order_all_tbl(ln_idx_a6).hd_actual_confirm_class;
--2008/08/07 Add ��
/* 2008/08/07 Mod ��
          IF (lt_req_statu = cv_req_status_confirm) THEN
2008/08/07 Mod �� */
          -- �o�׎��ьv��ϊ����ьv��ϋ敪='Y'�̏ꍇ
          IF ((lt_req_statu = cv_req_status_confirm) AND (lt_actual_class = gv_flag_on)) THEN
--
            IF (lb_break_flg_a2) THEN  -- A-2�`�[No���u���C�N�����ꍇ(�O��A-2�`�[No�ƈقȂ�ꍇ)
              -- �����ł�A-2�`�[No�u���C�N�t���O�����������Ȃ��ŉ�����
              -- ===========================================
              -- �q�֕ԕi�ŏ����(�w�b�_)�쐬���� (A-7)
              -- ===========================================
              IF (ln_idx_a6 = 1) THEN
                set_del_headers(
                  lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
              END IF;
            END IF;
--
            IF (lb_break_flg_a6) THEN  -- A-6�`�[No���u���C�N�����ꍇ(�O��A-6�`�[No�ƈقȂ�ꍇ)
              -- �����ł�A-6�`�[No�u���C�N�t���O�����������Ȃ��ŉ�����
              -- ===========================================
              -- �q�֕ԕi�ŏ����(����)�쐬���� (A-8)
              -- ===========================================
              set_del_lines(
                ln_idx_a6,                                         -- 1.�z��C���f�b�N�X
                lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
           END IF;
--
           IF (lb_break_flg_a2) THEN      -- A-2�`�[No���u���C�N�����ꍇ(�O��A-2�`�[No�ƈقȂ�ꍇ)
--
              lb_break_flg_a2 := FALSE;   -- A-2�`�[No�u���C�N�t���O������
              gt_line_number_a11 := 0;    -- A-11�ŃZ�b�g���閾�הԍ�(�w�b�_�P�ʂ�1����̔�)
--
              -- ===========================================
              -- �q�֕ԕi���(�w�b�_)�쐬���� (A-9)
              -- ===========================================
              set_order_headers(
                ln_idx_a6,                                         -- 1.�z��C���f�b�N�X
                gt_reserve_interface_tbl(i).quantity_total,        -- 2.����
                gt_reserve_interface_tbl(i).recorded_date,         -- 3.�v����t(����)
                gt_reserve_interface_tbl(i).receive_base_code,     -- 4.���苒�_�R�[�h
                gt_reserve_interface_tbl(i).input_base_code,       -- 5.���͋��_�R�[�h
                lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
--
              -- ===========================================
              -- �ŐV�t���O�X�V���쐬���� (A-10)
              -- ===========================================
              set_latest_external_flag(
                ln_idx_a6,                                         -- 1.�z��C���f�b�N�X
                lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
--
            -- A-2�Ŏ擾�����i�ڃR�[�h=A-6�Ŏ擾�����o�וi�ڂ̏ꍇ
            IF (gt_reserve_interface_tbl(i).item_no = gt_order_all_tbl(ln_idx_a6).ln_shipping_item_code) THEN
              -- A-2�Ŏ擾�����i�ڂ�A-6�Ŏ擾�����i�ڂɂȂ��ꍇA-2�Ŏ擾�����i�ڂ��쐬���邽�߂̃t���O
              gb_a11_flg := TRUE;    -- A-11-2���s�����ǂ����𐧌䂷��t���O
            END IF;
--
            IF (lb_break_flg_a6) THEN  -- A-6�`�[No���u���C�N�����ꍇ(�O��A-6�`�[No�ƈقȂ�ꍇ)
              -- �����ł�A-6�`�[No�u���C�N�t���O�����������Ȃ��ŉ�����
              -- ===========================================
              -- �q�֕ԕi���(����)�쐬���� (A-11)
              -- ===========================================
              set_order_lines(
                ln_idx_a6,                                         -- 1.�z��C���f�b�N�X
                gt_reserve_interface_tbl(i).item_no,               -- 2.�i�ڃR�[�h
                gt_reserve_interface_tbl(i).quantity_total,        -- 3.����
                lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
--
            -- A-2�Ŏ擾�����i�ڂ�A-6�Ŏ擾�����i�ڂɂȂ��ꍇA-2�Ŏ擾�����i�ڂ��쐬����
            IF (j = gt_order_all_tbl.LAST) THEN
              IF (gb_a11_flg = FALSE) THEN         -- A-2�Ŏ擾�����i�ڂ�A-6�Ŏ擾�����i�ڂɂȂ��ꍇ
--
                set_order_lines_2(
                  gt_reserve_interface_tbl(i).item_no,               -- 1.�i�ڃR�[�h
                  gt_reserve_interface_tbl(i).quantity_total,        -- 2.����
                  lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                  lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                  lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
                IF (lv_retcode = gv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
--
              END IF;
            END IF;
--
          -- =======================================================================================
          -- �o�׎��ьv��ςłȂ��ꍇ
          ELSE
            IF (lb_break_flg_a2) THEN   -- A-2�`�[No���u���C�N�����ꍇ(�O��A-2�`�[No�ƈقȂ�ꍇ)
--
              lb_break_flg_a2 := FALSE;    -- A-2�`�[No�u���C�N�t���O������
--
              -- ===========================================
              -- �q�֕ԕi�X�V���(�w�b�_)�쐬���� (A-12)
              -- ===========================================
              set_upd_order_headers(
                ln_idx_a6,                                         -- 1.�z��C���f�b�N�X
                gt_reserve_interface_tbl(i).quantity_total,        -- 2.����
                lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
--
            -- ===========================================
            -- �q�֕ԕi�X�V���(����)�쐬���� (A-13�@)
            -- ===========================================
            -- A-2�Ŏ擾�����i�ڃR�[�h=A-6�Ŏ擾�����o�וi�ڂ̏ꍇ�͍X�V
            -- �����i�ڂ��Ȃ���΂����ł͉������Ȃ�
            IF (gt_reserve_interface_tbl(i).item_no = gt_order_all_tbl(ln_idx_a6).ln_shipping_item_code) THEN
--
              set_upd_order_lines_upd(
                ln_idx_a6,                                         -- 1.�z��C���f�b�N�X
                gt_reserve_interface_tbl(i).quantity_total,        -- 2.����
                lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
                lb_a13upd_flg := TRUE;  -- �����i�ڂ�����΃t���O��ON�ɂ���
--
              IF (lv_retcode = gv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
--
          END IF;
--
        END LOOP gt_order_all_tbl_loop;
--
        -- ===========================================
        -- �q�֕ԕi�X�V���(����)�쐬���� (A-13�A)
        -- ===========================================
        -- �o�׎��ьv��ςłȂ��ꍇ�ŁAA-2�Ŏ擾�����i�ڂ�A-6�Ŏ擾�����i�ڂɂȂ������ꍇ
        -- �����i�ڂ��Ȃ��̂ł����ŐV�K�ɖ��ׂ��쐬����
        IF (lt_req_statu <> cv_req_status_confirm) AND
           (NOT lb_a13upd_flg) THEN
--
          set_upd_order_lines_ins( -- �����œn�����̂�A-6�ł͂Ȃ�A-2�Ŏ擾�����ق��Ȃ̂Œ��ӁI
            ln_idx_a6,                                         -- 1.�z��C���f�b�N�X
            gt_reserve_interface_tbl(i).quantity_total,        -- 2.����
            gt_reserve_interface_tbl(i).item_no,               -- 3.�i�ڃR�[�h
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
      -- ===========================================================================================
      -- ����˗�No��񂪒��o�ł��Ȃ������ꍇ
      ELSE
        IF (lb_break_flg_a2) THEN      -- A-2�`�[No���u���C�N�����ꍇ(�O��A-2�`�[No�ƈقȂ�ꍇ)
--
          lb_break_flg_a2 := FALSE;    -- A-2�`�[No�u���C�N�t���O������
          gt_line_number_a11 := 0;  -- A-11�ŃZ�b�g���閾�הԍ�(�w�b�_�P�ʂ�1����̔�)
--
          -- ===========================================
          -- �q�֕ԕi���(�w�b�_)�쐬���� (A-9)
          -- ===========================================
          set_order_headers(
            ln_idx_a6,                                         -- 1.�z��C���f�b�N�X
            gt_reserve_interface_tbl(i).quantity_total,        -- 2.����
            gt_reserve_interface_tbl(i).recorded_date,         -- 3.�v����t(����)
            gt_reserve_interface_tbl(i).receive_base_code,     -- 4.���苒�_�R�[�h
            gt_reserve_interface_tbl(i).input_base_code,       -- 5.���͋��_�R�[�h
            lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
            lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
            lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ===========================================
        -- �q�֕ԕi���(����)�쐬���� (A-11)
        -- ===========================================
        set_order_lines(
          ln_idx_a6,                                         -- 1.�z��C���f�b�N�X
          gt_reserve_interface_tbl(i).item_no,               -- 2.�i�ڃR�[�h
          gt_reserve_interface_tbl(i).quantity_total,        -- 3.����
          lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END LOOP gt_reserve_interface_tbl_loop;
--
    -- ===============================
    -- �q�֕ԕi���o�^���� (A-14)
    -- ===============================
    ins_order(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �q�֕ԕi���o���v���� (A-15)
    -- ===============================
    sum_lines_quantity(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �q�֕ԕi���ēo�^���� (A-16)
    -- ===============================
    upd_headers_sum_quantity(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- �q�֕ԕi�C���^�[�t�F�[�X���폜���� (A-17)
    -- =============================================
    del_reserve_interface(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := lv_retcode;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT NOCOPY VARCHAR2      -- ���^�[���E�R�[�h    --# �Œ� #
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error)
    OR (lv_retcode = gv_status_warn) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
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
    --���������o��
--
    -- ���͌���(�q�֕ԕi�C���^�[�t�F�[�X)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_input_reserve_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_input_reserve_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �q�֕ԕi���쐬����(�󒍃w�b�_�A�h�I���P��)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_headers_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_headers_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �q�֕ԕi���쐬����(�󒍖��׃A�h�I���P��)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_lines_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_lines_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �q�֕ԕi���쐬����(�ړ����b�g�ڍגP��)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_lot_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_lot_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �q�֕ԕi�ŏ����쐬����(�󒍃w�b�_�A�h�I���P��)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_del_hd_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_del_hd_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �q�֕ԕi�ŏ����쐬����(�󒍖��׃A�h�I���P��)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_del_ln_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_del_ln_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �q�֕ԕi�ŏ����쐬����(�ړ����b�g�ڍגP��)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_del_lot_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_del_lot_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �q�֕ԕi�X�V���쐬����(�󒍃w�b�_�A�h�I���P��)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_upd_hd_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_upd_hd_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    -- �q�֕ԕi�X�V���쐬����(�󒍖��׃A�h�I���P��)
    gv_out_msg := xxcmn_common_pkg.get_msg(
      gv_xxwsh,
      gv_xxwsh_output_upd_ln_cnt,
      gv_tkn_cnt,
      TO_CHAR(gn_output_upd_ln_cnt));
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
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
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh430001c;
/
