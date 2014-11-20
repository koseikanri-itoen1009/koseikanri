CREATE OR REPLACE PACKAGE BODY xxpo940006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO940006C(body)
 * Description      : �x���˗��捞����
 * MD.050           : �����I�����C�� T_MD050_BPO_940
 * MD.070           : �x���˗��捞���� T_MD070_BPO_94F
 * Version          : 1.4
 *
 * Program List
 * -------------------------- ------------------------------------------------------------
 *  Name                       Description
 * -------------------------- ------------------------------------------------------------
 *  init_proc                  �������� (F-1)
 *  get_header_proc            �w�b�_�f�[�^�擾���� (F-2)
 *  get_line_proc              ���׃f�[�^�擾���� (F-3)
 *  chk_essent_proc            �K�{�`�F�b�N���� (F-4)
 *  chk_exist_mst_proc         �}�X�^���݃`�F�b�N���� (F-5)
 *  get_relation_proc          �֘A�f�[�^�擾���� (F-6)
 *  set_data_proc              �o�^�f�[�^�ݒ菈��
 *  calc_load_efficiency_proc  �ύڌ����Z�o
 *  put_header_proc            �󒍃w�b�_�A�h�I���o�^���� (F-7)
 *  put_line_proc              �󒍖��׃A�h�I���o�^���� (F-8)
 *  delete_proc                �f�[�^�폜���� (F-9)
 *  put_dump_msg               �f�[�^�_���v�ꊇ�o�͏���
 *  submain                    ���C�������v���V�[�W��
 *  main                       �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/06/13    1.0   Oracle �Ŗ�      ����쐬
 *  2008/06/30    1.1   Oracle �Ŗ�      �^���敪��w��������t�уR�[�h�A�����l�ݒ�
 *                                       �o�^�X�e�[�^�X�ύX
 *  2008/07/08    1.2   Oracle �R����_  I_S_192�Ή�
 *  2008/07/17    1.3   Oracle �Ŗ�      MD050�w�E����#13�Ή�
 *  2008/07/24    1.4   Oracle �Ŗ�      �����ۑ�#32,�����ύX#166�#173�Ή�
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
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_h_target_cnt  NUMBER;                    -- �Ώی���(�w�b�_)
  gn_l_target_cnt  NUMBER;                    -- �Ώی���(����)
  gn_h_normal_cnt  NUMBER;                    -- ���팏��(�w�b�_)
  gn_l_normal_cnt  NUMBER;                    -- ���팏��(����)
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
  check_lock_expt           EXCEPTION;     -- ���b�N�擾�G���[
  proc_err_expt             EXCEPTION;     -- �����G���[
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxpo940006c';            -- �p�b�P�[�W��
  gv_msg_kbn_xxpo     CONSTANT VARCHAR2(5)   := 'XXPO';                   -- �d���E�L���x��
-- 2008/07/17 v1.3 Start
  gv_msg_kbn_xxcmn    CONSTANT VARCHAR2(5)   := 'XXCMN';                  -- �}�X�^�E�o���E����
  -- ���b�N�A�b�v
  gv_lup_weight_capacity  CONSTANT VARCHAR2(100)   := 'XXCMN_WEIGHT_CAPACITY_CLASS'; -- �d�ʗe�ϋ敪
  gv_lup_freight_class    CONSTANT VARCHAR2(100)   := 'XXWSH_FREIGHT_CLASS';         -- �^���敪
  gv_lup_takeback_class   CONSTANT VARCHAR2(100)   := 'XXWSH_TAKEBACK_CLASS';        -- ����敪
  gv_lup_arrival_time     CONSTANT VARCHAR2(100)   := 'XXWSH_ARRIVAL_TIME';          -- ���׎���
-- 2008/07/17 v1.3 End
  gv_header           CONSTANT VARCHAR2(1)   := '0';                      -- �w�b�_
  gv_line             CONSTANT VARCHAR2(1)   := '1';                      -- ����
  gv_object           CONSTANT VARCHAR2(1)   := '1';                      -- �Ώ�
  gv_we               CONSTANT VARCHAR2(1)   := '1';                      -- �d��
  gv_ca               CONSTANT VARCHAR2(1)   := '2';                      -- �e��
  gv_leaf             CONSTANT VARCHAR2(1)   := '1';                      -- ���[�t
  gv_drink            CONSTANT VARCHAR2(1)   := '2';                      -- �h�����N
  gv_data_class       CONSTANT VARCHAR2(50)  := '�f�[�^���';
  gv_trans_type       CONSTANT VARCHAR2(50)  := '�����敪';
  gv_vendor           CONSTANT VARCHAR2(50)  := '�����';
  gv_arvl_time_from   CONSTANT VARCHAR2(50)  := '���ɓ�FROM';
  gv_arvl_time_to     CONSTANT VARCHAR2(50)  := '���ɓ�TO';
  gv_security_class   CONSTANT VARCHAR2(50)  := '�Z�L�����e�B�敪';
  gv_opminv_close     CONSTANT VARCHAR2(50)  := 'OPM�݌ɉ�v����CLOSE�N���擾�֐�';
  gv_max_ship         CONSTANT VARCHAR2(50)  := '�ő�z���敪�Z�o�֐�';
  gv_unit_price       CONSTANT VARCHAR2(50)  := '�x���P���擾�֐�';
-- 2008/07/24 v1.4 Start
  gv_get_seq_no       CONSTANT VARCHAR2(100) := '�̔Ԋ֐�';
  gv_calc_total_value CONSTANT VARCHAR2(100) := '�ύڌ����`�F�b�N(���v�l�Z�o)';
  gv_tkn_calc_load_ef_we  CONSTANT VARCHAR2(100) := '�ύڌ����`�F�b�N(�ύڌ����Z�o:�d��)';
  gv_tkn_calc_load_ef_ca  CONSTANT VARCHAR2(100) := '�ύڌ����`�F�b�N(�ύڌ����Z�o:�e��)';
-- 2008/07/24 v1.4 End
-- 2008/07/17 v1.3 Start
  gv_oprtn_day        CONSTANT VARCHAR2(50)  := '�ғ����Z�o�֐�';
  gv_msg_comma        CONSTANT VARCHAR2(3)   := ',';
-- 2008/07/17 v1.3 End
--
  -- �v���t�@�C��
  gv_master_org_id    CONSTANT VARCHAR2(50) := 'XXCMN_MASTER_ORG_ID';     -- �}�X�^�g�D
  gv_price_list_id    CONSTANT VARCHAR2(50) := 'XXPO_PRICE_LIST_ID';      -- ��\���i�\
  gv_item_div_id      CONSTANT VARCHAR2(50) := 'XXCMN_ITEM_DIV_SECURITY'; -- ���i�敪(�Z�L�����e�B)
--
  -- �g�[�N��
  gv_tkn_table        CONSTANT VARCHAR2(10) := 'TABLE';
  gv_tkn_para_name    CONSTANT VARCHAR2(10) := 'PARAM_NAME';
  gv_tkn_common_name  CONSTANT VARCHAR2(10) := 'NG_COMMON';
  gv_tkn_date_item1   CONSTANT VARCHAR2(10) := 'ITEM1';
  gv_tkn_date_item2   CONSTANT VARCHAR2(10) := 'ITEM2';
  gv_tkn_count        CONSTANT VARCHAR2(10) := 'CNT';
  gv_tkn_ng_profile   CONSTANT VARCHAR2(10) := 'NG_PROFILE';
-- 2008/07/24 v1.4 Start
  gv_tkn_request_no   CONSTANT VARCHAR2(100) := 'REQUEST_NO';
  gv_tkn_item_no      CONSTANT VARCHAR2(100) := 'ITEM_NO';
-- 2008/07/24 v1.4 End
-- 2008/07/17 v1.3 Start
  gv_tkn_date_item    CONSTANT VARCHAR2(10) := 'ITEM';
-- 2008/07/17 v1.3 End
--
  -- �Ώۖ�
  gv_srhi_name        CONSTANT VARCHAR2(100) := '�x���˗����C���^�t�F�[�X�e�[�u���w�b�_';
  gv_srli_name        CONSTANT VARCHAR2(100) := '�x���˗����C���^�t�F�[�X�e�[�u������';
-- 2008/07/17 v1.3 Start
  gv_weight_capacity      CONSTANT VARCHAR2(100) := '�d�ʗe�ϋ敪';
  gv_req_department       CONSTANT VARCHAR2(100) := '�˗�����';
  gv_instruction_post     CONSTANT VARCHAR2(100) := '�w������';
  gv_freight_charge_class CONSTANT VARCHAR2(100) := '�^���敪';
  gv_takeback_class       CONSTANT VARCHAR2(100) := '����敪';
  gv_arrival_time_from    CONSTANT VARCHAR2(100) := '���׎���FROM';
  gv_arrival_time_to      CONSTANT VARCHAR2(100) := '���׎���TO';
  gv_request_qty          CONSTANT VARCHAR2(100) := '�˗�����';
-- 2008/07/17 v1.3 End
--
  -- ���b�Z�[�W�ԍ�
  -- �v���t�@�C���擾�G���[
  gv_msg_get_prf      CONSTANT VARCHAR2(20) := 'APP-XXPO-10220';
  -- �f�[�^�擾�G���[
  gv_msg_get_data     CONSTANT VARCHAR2(20) := 'APP-XXPO-10229';
  -- ���b�N�擾�G���[
  gv_msg_lock         CONSTANT VARCHAR2(20) := 'APP-XXPO-10216';
  -- �K�{���̓G���[
  gv_msg_essent       CONSTANT VARCHAR2(20) := 'APP-XXPO-10230';
  -- ���݃`�F�b�N�G���[
  gv_msg_exist        CONSTANT VARCHAR2(20) := 'APP-XXPO-10234';
  -- �݌ɉ�v���ԃN���[�Y�`�F�b�N�G���[
  gv_msg_close_period CONSTANT VARCHAR2(20) := 'APP-XXPO-10231';
  -- �i�ڏd���`�F�b�N�G���[
  gv_msg_redundant    CONSTANT VARCHAR2(20) := 'APP-XXPO-10232';
  -- �d���L�����i�ڃ`�F�b�N�G���[
  gv_msg_trans_type   CONSTANT VARCHAR2(20) := 'APP-XXPO-10233';
  -- �p�����[�^�K�{�G���[
  gv_msg_para_essent  CONSTANT VARCHAR2(20) := 'APP-XXPO-10235';
  -- �p�����[�^���t�G���[
  gv_msg_date         CONSTANT VARCHAR2(20) := 'APP-XXPO-10236';
-- 2008/07/17 v1.3 Start
  -- ���t�s���`�F�b�N�G���[
  gv_msg_ship_date    CONSTANT VARCHAR2(20) := 'APP-XXPO-10258';
  -- �d�ʗe�ϋ敪��v�`�F�b�N�G���[
  gv_msg_weight_capacity_agree  CONSTANT VARCHAR2(20) := 'APP-XXPO-10259';
  -- �}�X�^���݃`�F�b�N�G���[
  gv_msg_mst_exist    CONSTANT VARCHAR2(20) := 'APP-XXPO-10260';
  -- �˗����ʕs���G���[
  gv_msg_request_qty  CONSTANT VARCHAR2(20) := 'APP-XXPO-10261';
-- 2008/07/17 v1.3 End
  -- ���ʊ֐��G���[
  gv_msg_common       CONSTANT VARCHAR2(20) := 'APP-XXPO-10237';
--
-- 2008/07/24 v1.4 Start
  gv_msg_xxcmn10604   CONSTANT VARCHAR2(20) := 'APP-XXCMN-10604';
  gv_msg_xxpo10120    CONSTANT VARCHAR2(100) := 'APP-XXPO-10120';
-- 2008/07/24 v1.4 End
-- 2008/07/17 v1.3 Start
  -- ���b�Z�[�W:APP-XXPO-30051 ���̓p�����[�^(���o��)
  gv_msg_xxpo30051    CONSTANT VARCHAR2(100) := 'APP-XXPO-30051';
  -- ���b�Z�[�W:APP-XXCMN-00005 �����f�[�^�i���o���j
  gv_msg_xxcmn00005   CONSTANT VARCHAR2(100) := 'APP-XXCMN-00005';
-- 2008/07/17 v1.3 End
  -- ��������(�w�b�_)
  gv_msg_h_target_cnt CONSTANT VARCHAR2(20) := 'APP-XXPO-10239';
  -- ��������(����)
  gv_msg_l_target_cnt CONSTANT VARCHAR2(20) := 'APP-XXPO-10240';
  -- ��������(�w�b�_)
  gv_msg_h_normal_cnt CONSTANT VARCHAR2(20) := 'APP-XXPO-10241';
  -- ��������(����)
  gv_msg_l_normal_cnt CONSTANT VARCHAR2(20) := 'APP-XXPO-10242';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  ---------------------------------------------
  -- �x���˗����C���^�t�F�[�X�擾(�w�b�_)  --
  ---------------------------------------------
  -- �x���˗����C���^�t�F�[�X�w�b�_ID
  TYPE supply_req_headers_if_id_tbl IS TABLE OF
    xxpo_supply_req_headers_if.supply_req_headers_if_id%TYPE INDEX BY BINARY_INTEGER;
  -- �����敪
  TYPE trans_type_tbl IS TABLE OF
    xxpo_supply_req_headers_if.trans_type%TYPE INDEX BY BINARY_INTEGER;
  -- �d�ʗe�ϋ敪
  TYPE weight_capacity_class_tbl IS TABLE OF
    xxpo_supply_req_headers_if.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;
  -- �˗������R�[�h
  TYPE requested_department_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.requested_department_code%TYPE INDEX BY BINARY_INTEGER;
  -- �w�������R�[�h
  TYPE instruction_post_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.instruction_post_code%TYPE INDEX BY BINARY_INTEGER;
  -- �����R�[�h
  TYPE vendor_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.vendor_code%TYPE INDEX BY BINARY_INTEGER;
  -- �z����R�[�h
  TYPE ship_to_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.ship_to_code%TYPE INDEX BY BINARY_INTEGER;
  -- �o�ɑq�ɃR�[�h
  TYPE shipped_locat_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.shipped_locat_code%TYPE INDEX BY BINARY_INTEGER;
  -- �^���Ǝ҃R�[�h
  TYPE freight_carrier_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;
  -- �o�ɓ�
  TYPE ship_date_tbl IS TABLE OF
    xxpo_supply_req_headers_if.ship_date%TYPE INDEX BY BINARY_INTEGER;
  -- ���ɓ�
  TYPE arvl_date_tbl IS TABLE OF
    xxpo_supply_req_headers_if.arvl_date%TYPE INDEX BY BINARY_INTEGER;
  -- �^���敪
  TYPE freight_charge_class_tbl IS TABLE OF
    xxpo_supply_req_headers_if.freight_charge_class%TYPE INDEX BY BINARY_INTEGER;
  -- ����敪
  TYPE takeback_class_tbl IS TABLE OF
    xxpo_supply_req_headers_if.takeback_class%TYPE INDEX BY BINARY_INTEGER;
  -- ���׎���FROM
  TYPE arrival_time_from_tbl IS TABLE OF
    xxpo_supply_req_headers_if.arrival_time_from%TYPE INDEX BY BINARY_INTEGER;
  -- ���׎���TO
  TYPE arrival_time_to_tbl IS TABLE OF
    xxpo_supply_req_headers_if.arrival_time_to%TYPE INDEX BY BINARY_INTEGER;
  -- ������
  TYPE product_date_tbl IS TABLE OF
    xxpo_supply_req_headers_if.product_date%TYPE INDEX BY BINARY_INTEGER;
  -- �����i�ڃR�[�h
  TYPE producted_item_code_tbl IS TABLE OF
    xxpo_supply_req_headers_if.producted_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- �����ԍ�
  TYPE product_number_tbl IS TABLE OF
    xxpo_supply_req_headers_if.product_number%TYPE INDEX BY BINARY_INTEGER;
  -- �w�b�_�E�v
  TYPE header_description_tbl IS TABLE OF
    xxpo_supply_req_headers_if.header_description%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃w�b�_�A�h�I��ID
  TYPE order_header_id_tbl IS TABLE OF
    xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- �d����ID
  TYPE vendor_id_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_id%TYPE INDEX BY BINARY_INTEGER;
  -- �ڋq�ԍ�
  TYPE customer_num_tbl IS TABLE OF
    xxwsh_order_headers_all.customer_code%TYPE INDEX BY BINARY_INTEGER;
  -- �p�[�e�BID
  TYPE cust_party_id_tbl IS TABLE OF
    xxcmn_cust_accounts_v.party_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���i�\
  TYPE spare2_tbl IS TABLE OF
    xxcmn_vendors_v.spare2%TYPE INDEX BY BINARY_INTEGER;
  -- �ڋqID
  TYPE cust_account_id_tbl IS TABLE OF
    xxwsh_order_headers_all.customer_id%TYPE INDEX BY BINARY_INTEGER;
  -- �d����T�C�gID
  TYPE vendor_site_id_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_site_id%TYPE INDEX BY BINARY_INTEGER;
  -- �q��ID
  TYPE inventory_location_id_tbl IS TABLE OF
    xxwsh_order_headers_all.deliver_from_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���[�t��J�����_
  TYPE leaf_calender_tbl IS TABLE OF
    xxcmn_item_locations_v.leaf_calender%TYPE INDEX BY BINARY_INTEGER;
  -- �h�����N��J�����_
  TYPE drink_calender_tbl IS TABLE OF
    xxcmn_item_locations_v.drink_calender%TYPE INDEX BY BINARY_INTEGER;
  -- �p�[�e�BID
  TYPE carriers_party_id_tbl IS TABLE OF
    xxwsh_order_headers_all.career_id%TYPE INDEX BY BINARY_INTEGER;
  -- �i��ID
  TYPE h_item_id_tbl IS TABLE OF
    xxwsh_order_headers_all.designated_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- ������
  TYPE small_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.small_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ���x������
  TYPE label_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.label_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ���v����
  TYPE sum_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �ő�z���敪
  TYPE ship_method_tbl IS TABLE OF
    xxwsh_order_headers_all.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
  -- �h�����N�ύڏd��
  TYPE drink_deadweight_tbl IS TABLE OF
    xxwsh_order_headers_all.based_weight%TYPE INDEX BY BINARY_INTEGER;
  -- ���[�t�ύڏd��
  TYPE leaf_deadweight_tbl IS TABLE OF
    xxwsh_order_headers_all.based_weight%TYPE INDEX BY BINARY_INTEGER;
  -- �h�����N�ύڗe��
  TYPE drink_loading_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.based_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- ���[�t�ύڗe��
  TYPE leaf_loading_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.based_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- �d�ʐύڌ���
  TYPE load_efficiency_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.loading_efficiency_weight%TYPE INDEX BY BINARY_INTEGER;
  -- �e�ϐύڌ���
  TYPE load_efficiency_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.loading_efficiency_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- ���v�d��
  TYPE h_sum_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_weight%TYPE INDEX BY BINARY_INTEGER;
  -- ���v�e��
  TYPE h_sum_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׈˗�No
  TYPE seq_no_tbl IS TABLE OF
    xxwsh_order_headers_all.request_no%TYPE INDEX BY BINARY_INTEGER;
-- 2008/07/17 v1.3 Start
  -- �w�b�_�f�[�^�_���v
  TYPE lr_h_data_dump_tbl IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
-- 2008/07/17 v1.3 End
--
  ---------------------------------------------
  -- �x���˗����C���^�t�F�[�X�擾(����)  --
  ---------------------------------------------
  -- �x���˗����C���^�t�F�[�X����ID
  TYPE supply_req_lines_if_id_tbl IS TABLE OF
    xxpo_supply_req_lines_if.supply_req_lines_if_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���הԍ�
  TYPE line_number_tbl IS TABLE OF
    xxpo_supply_req_lines_if.line_number%TYPE INDEX BY BINARY_INTEGER;
  -- �i�ڃR�[�h
  TYPE item_code_tbl IS TABLE OF
    xxpo_supply_req_lines_if.item_code%TYPE INDEX BY BINARY_INTEGER;
  -- �t��
  TYPE futai_code_tbl IS TABLE OF
    xxpo_supply_req_lines_if.futai_code%TYPE INDEX BY BINARY_INTEGER;
  -- �˗�����
  TYPE request_qty_tbl IS TABLE OF
    xxpo_supply_req_lines_if.request_qty%TYPE INDEX BY BINARY_INTEGER;
  -- ���דE�v
  TYPE line_description_tbl IS TABLE OF
    xxpo_supply_req_lines_if.line_description%TYPE INDEX BY BINARY_INTEGER;
  -- �w�b�_ID
  TYPE line_headers_id_tbl IS TABLE OF
    xxpo_supply_req_lines_if.supply_req_headers_if_id%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍖��׃A�h�I��ID
  TYPE order_line_id_tbl IS TABLE OF
    xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- �i��ID
  TYPE l_item_id_tbl IS TABLE OF
    xxwsh_order_lines_all.shipping_inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- �P��
  TYPE item_um_tbl IS TABLE OF
    xxwsh_order_lines_all.uom_code%TYPE INDEX BY BINARY_INTEGER;
  -- �o�ד���
  TYPE num_of_deliver_tbl IS TABLE OF
    xxcmn_item_mst_v.num_of_deliver%TYPE INDEX BY BINARY_INTEGER;
  -- ���o�Ɋ��Z�P��
  TYPE conv_unit_tbl IS TABLE OF
    xxcmn_item_mst_v.conv_unit%TYPE INDEX BY BINARY_INTEGER; 
  -- �P�[�X����
  TYPE num_of_cases_tbl IS TABLE OF
    xxcmn_item_mst_v.num_of_cases%TYPE INDEX BY BINARY_INTEGER;
  -- INV�i��ID
  TYPE inventory_item_id_tbl IS TABLE OF
    xxcmn_item_mst_v.inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- �q�ɕi��ID
  TYPE whse_item_id_tbl IS TABLE OF
    xxwsh_order_lines_all.request_item_id%TYPE INDEX BY BINARY_INTEGER; 
  -- �q�ɕi�ڃR�[�h
  TYPE item_no_tbl IS TABLE OF
    xxwsh_order_lines_all.request_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ���b�g
  TYPE lot_ctl_tbl IS TABLE OF
    xxcmn_item_mst_v.lot_ctl%TYPE INDEX BY BINARY_INTEGER;
  -- �P��
  TYPE unit_price_tbl IS TABLE OF
    xxwsh_order_lines_all.unit_price%TYPE INDEX BY BINARY_INTEGER;
  -- ���v�d��
  TYPE l_sum_weight_tbl IS TABLE OF
    xxwsh_order_lines_all.weight%TYPE INDEX BY BINARY_INTEGER;
  -- ���v�e��
  TYPE l_sum_capacity_tbl IS TABLE OF
    xxwsh_order_lines_all.capacity%TYPE INDEX BY BINARY_INTEGER;
-- 2008/07/17 v1.3 Start
  -- �d�ʗe�ϋ敪
  TYPE l_weight_capacity_class IS TABLE OF
    xxcmn_item_mst_v.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;
  -- ���׃f�[�^�_���v
  TYPE lr_l_data_dump_tbl IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
-- 2008/07/17 v1.3 End
--
  ---------------------------------------------
  -- �󒍃w�b�_�A�h�I���o�^                  --
  ---------------------------------------------
  -- �󒍃w�b�_�A�h�I��ID
  TYPE ph_order_header_id_tbl IS TABLE OF
    xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃^�C�vID
  TYPE ph_order_type_id_tbl IS TABLE OF
    xxwsh_order_headers_all.order_type_id%TYPE INDEX BY BINARY_INTEGER;
  -- �g�DID
  TYPE ph_organization_id_tbl IS TABLE OF
    xxwsh_order_headers_all.organization_id%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃w�b�_ID
  TYPE ph_header_id_tbl IS TABLE OF
    xxwsh_order_headers_all.header_id%TYPE INDEX BY BINARY_INTEGER;
  -- �ŐV�t���O
  TYPE ph_latest_external_flag_tbl IS TABLE OF
    xxwsh_order_headers_all.latest_external_flag%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍓�
  TYPE ph_ordered_date_tbl IS TABLE OF
    xxwsh_order_headers_all.ordered_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ڋqID
  TYPE ph_customer_id_tbl IS TABLE OF
    xxwsh_order_headers_all.customer_id%TYPE INDEX BY BINARY_INTEGER;
  -- �ڋq
  TYPE ph_customer_code_tbl IS TABLE OF
    xxwsh_order_headers_all.customer_code%TYPE INDEX BY BINARY_INTEGER;
  -- �o�א�ID
  TYPE ph_deliver_to_id_tbl IS TABLE OF
    xxwsh_order_headers_all.deliver_to_id%TYPE INDEX BY BINARY_INTEGER;
  -- �o�א�
  TYPE ph_deliver_to_tbl IS TABLE OF
    xxwsh_order_headers_all.deliver_to%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׎w��
  TYPE ph_shipping_instructions_tbl IS TABLE OF
    xxwsh_order_headers_all.shipping_instructions%TYPE INDEX BY BINARY_INTEGER;
  -- �^���Ǝ�ID
  TYPE ph_career_id_tbl IS TABLE OF
    xxwsh_order_headers_all.career_id%TYPE INDEX BY BINARY_INTEGER;
  -- �^���Ǝ�
  TYPE ph_freight_carrier_code_tbl IS TABLE OF
    xxwsh_order_headers_all.freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;
  -- �z���敪
  TYPE ph_shipping_method_code_tbl IS TABLE OF
    xxwsh_order_headers_all.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
  -- �ڋq����
  TYPE ph_cust_po_number_tbl IS TABLE OF
    xxwsh_order_headers_all.cust_po_number%TYPE INDEX BY BINARY_INTEGER;
  -- ���i�\
  TYPE ph_price_list_id_tbl IS TABLE OF
    xxwsh_order_headers_all.price_list_id%TYPE INDEX BY BINARY_INTEGER;
  -- �˗�No
  TYPE ph_request_no_tbl IS TABLE OF
    xxwsh_order_headers_all.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- ���˗�No
  TYPE ph_base_request_no_tbl IS TABLE OF
    xxwsh_order_headers_all.base_request_no%TYPE INDEX BY BINARY_INTEGER;
  -- �X�e�[�^�X
  TYPE ph_req_status_tbl IS TABLE OF
    xxwsh_order_headers_all.req_status%TYPE INDEX BY BINARY_INTEGER;
  -- �z��No
  TYPE ph_delivery_no_tbl IS TABLE OF
    xxwsh_order_headers_all.delivery_no%TYPE INDEX BY BINARY_INTEGER;
  -- �O��z��No
  TYPE ph_prev_delivery_no_tbl IS TABLE OF
    xxwsh_order_headers_all.prev_delivery_no%TYPE INDEX BY BINARY_INTEGER;
  -- �o�ח\���
  TYPE ph_schedule_ship_date_tbl IS TABLE OF
    xxwsh_order_headers_all.schedule_ship_date%TYPE INDEX BY BINARY_INTEGER;
  -- ���ח\���
  TYPE ph_schedule_arrival_date_tbl IS TABLE OF
    xxwsh_order_headers_all.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- ���ڌ�No
  TYPE ph_mixed_no_tbl IS TABLE OF
    xxwsh_order_headers_all.mixed_no%TYPE INDEX BY BINARY_INTEGER;
  -- �p���b�g�������
  TYPE ph_collected_pallet_qty_tbl IS TABLE OF
    xxwsh_order_headers_all.collected_pallet_qty%TYPE INDEX BY BINARY_INTEGER;
  -- �����S���m�F�˗��敪
  TYPE ph_confirm_request_class_tbl IS TABLE OF
    xxwsh_order_headers_all.confirm_request_class%TYPE INDEX BY BINARY_INTEGER;
  -- �^���敪
  TYPE ph_freight_charge_class_tbl IS TABLE OF
    xxwsh_order_headers_all.freight_charge_class%TYPE INDEX BY BINARY_INTEGER;
  -- �x���o�Ɏw���敪
  TYPE ph_shikyu_inst_class_tbl IS TABLE OF
    xxwsh_order_headers_all.shikyu_instruction_class%TYPE INDEX BY BINARY_INTEGER;
  -- �x���w����̋敪
  TYPE ph_shikyu_inst_rcv_class_tbl IS TABLE OF
    xxwsh_order_headers_all.shikyu_inst_rcv_class%TYPE INDEX BY BINARY_INTEGER;
  -- �L�����z�m��敪
  TYPE ph_amount_fix_class_tbl IS TABLE OF
    xxwsh_order_headers_all.amount_fix_class%TYPE INDEX BY BINARY_INTEGER;
  -- ����敪
  TYPE ph_takeback_class_tbl IS TABLE OF
    xxwsh_order_headers_all.takeback_class%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׌�ID
  TYPE ph_deliver_from_id_tbl IS TABLE OF
    xxwsh_order_headers_all.deliver_from_id%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׌��ۊǏꏊ
  TYPE ph_deliver_from_tbl IS TABLE OF
    xxwsh_order_headers_all.deliver_from%TYPE INDEX BY BINARY_INTEGER;
  -- �Ǌ����_
  TYPE ph_head_sales_branch_tbl IS TABLE OF
    xxwsh_order_headers_all.head_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- ���͋��_
  TYPE ph_input_sales_branch_tbl IS TABLE OF
    xxwsh_order_headers_all.input_sales_branch%TYPE INDEX BY BINARY_INTEGER;
  -- ����No
  TYPE ph_po_no_tbl IS TABLE OF
    xxwsh_order_headers_all.po_no%TYPE INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE ph_prod_class_tbl IS TABLE OF
    xxwsh_order_headers_all.prod_class%TYPE INDEX BY BINARY_INTEGER;
  -- �i�ڋ敪
  TYPE ph_item_class_tbl IS TABLE OF
    xxwsh_order_headers_all.item_class%TYPE INDEX BY BINARY_INTEGER;
  -- �_��O�^���敪
  TYPE ph_no_cont_freight_class_tbl IS TABLE OF
    xxwsh_order_headers_all.no_cont_freight_class%TYPE INDEX BY BINARY_INTEGER;
  -- ���׎���FROM
  TYPE ph_arrival_time_from_tbl IS TABLE OF
    xxwsh_order_headers_all.arrival_time_from%TYPE INDEX BY BINARY_INTEGER;
  -- ���׎���TO
  TYPE ph_arrival_time_to_tbl IS TABLE OF
    xxwsh_order_headers_all.arrival_time_to%TYPE INDEX BY BINARY_INTEGER;
  -- �����i��ID
  TYPE ph_designated_item_id_tbl IS TABLE OF
    xxwsh_order_headers_all.designated_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- �����i��
  TYPE ph_designated_item_code_tbl IS TABLE OF
    xxwsh_order_headers_all.designated_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ������
  TYPE ph_designated_prod_date_tbl IS TABLE OF
    xxwsh_order_headers_all.designated_production_date%TYPE INDEX BY BINARY_INTEGER;
  -- �����}��
  TYPE ph_designated_branch_no_tbl IS TABLE OF
    xxwsh_order_headers_all.designated_branch_no%TYPE INDEX BY BINARY_INTEGER;
  -- �����No
  TYPE ph_slip_number_tbl IS TABLE OF
    xxwsh_order_headers_all.slip_number%TYPE INDEX BY BINARY_INTEGER;
  -- ���v����
  TYPE ph_sum_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ������
  TYPE ph_small_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.small_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ���x������
  TYPE ph_label_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.label_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �d�ʐύڌ���
  TYPE ph_loading_efficiency_we_tbl IS TABLE OF
    xxwsh_order_headers_all.loading_efficiency_weight%TYPE INDEX BY BINARY_INTEGER;
  -- �e�ϐύڌ���
  TYPE ph_loading_efficiency_ca_tbl IS TABLE OF
    xxwsh_order_headers_all.loading_efficiency_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- ��{�d��
  TYPE ph_based_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.based_weight%TYPE INDEX BY BINARY_INTEGER;
  -- ��{�e��
  TYPE ph_based_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.based_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- �ύڏd�ʍ��v
  TYPE ph_sum_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_weight%TYPE INDEX BY BINARY_INTEGER;
  -- �ύڗe�ύ��v
  TYPE ph_sum_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- ���ڗ�
  TYPE ph_mixed_ratio_tbl IS TABLE OF
    xxwsh_order_headers_all.mixed_ratio%TYPE INDEX BY BINARY_INTEGER;
  -- �p���b�g���v����
  TYPE ph_pallet_sum_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.pallet_sum_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �p���b�g���і���
  TYPE ph_real_pallet_quantity_tbl IS TABLE OF
    xxwsh_order_headers_all.real_pallet_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ���v�p���b�g�d��
  TYPE ph_sum_pallet_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_pallet_weight%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃\�[�X�Q��
  TYPE ph_order_source_ref_tbl IS TABLE OF
    xxwsh_order_headers_all.order_source_ref%TYPE INDEX BY BINARY_INTEGER;
  -- �^���Ǝ�_����ID
  TYPE ph_result_freight_carr_id_tbl IS TABLE OF
    xxwsh_order_headers_all.result_freight_carrier_id%TYPE INDEX BY BINARY_INTEGER;
  -- �^���Ǝ�_����
  TYPE ph_result_fre_carr_code_tbl IS TABLE OF
    xxwsh_order_headers_all.result_freight_carrier_code%TYPE INDEX BY BINARY_INTEGER;
  -- �z���敪_����
  TYPE ph_result_ship_method_code_tbl IS TABLE OF
    xxwsh_order_headers_all.result_shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
  -- �o�א�_����ID
  TYPE ph_result_deliver_to_id_tbl IS TABLE OF
    xxwsh_order_headers_all.result_deliver_to_id%TYPE INDEX BY BINARY_INTEGER;
  -- �o�א�_����
  TYPE ph_result_deliver_to_tbl IS TABLE OF
    xxwsh_order_headers_all.result_deliver_to%TYPE INDEX BY BINARY_INTEGER;
  -- �o�ד�
  TYPE ph_shipped_date_tbl IS TABLE OF
    xxwsh_order_headers_all.shipped_date%TYPE INDEX BY BINARY_INTEGER;
  -- ���ד�
  TYPE ph_arrival_date_tbl IS TABLE OF
    xxwsh_order_headers_all.arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- �d�ʗe�ϋ敪
  TYPE ph_weight_capacity_class_tbl IS TABLE OF
    xxwsh_order_headers_all.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;
  -- ���ьv��ϋ敪
  TYPE ph_actual_confirm_class_tbl IS TABLE OF
    xxwsh_order_headers_all.actual_confirm_class%TYPE INDEX BY BINARY_INTEGER;
  -- �ʒm�X�e�[�^�X
  TYPE ph_notif_status_tbl IS TABLE OF
    xxwsh_order_headers_all.notif_status%TYPE INDEX BY BINARY_INTEGER;
  -- �O��ʒm�X�e�[�^�X
  TYPE ph_prev_notif_status_tbl IS TABLE OF
    xxwsh_order_headers_all.prev_notif_status%TYPE INDEX BY BINARY_INTEGER;
  -- �m��ʒm���{����
  TYPE ph_notif_date_tbl IS TABLE OF
    xxwsh_order_headers_all.notif_date%TYPE INDEX BY BINARY_INTEGER;
  -- �V�K�C���t���O
  TYPE ph_new_modify_flg_tbl IS TABLE OF
    xxwsh_order_headers_all.new_modify_flg%TYPE INDEX BY BINARY_INTEGER;
  -- �����o�߃X�e�[�^�X
  TYPE ph_process_status_tbl IS TABLE OF
    xxwsh_order_headers_all.process_status%TYPE INDEX BY BINARY_INTEGER;
  -- ���ъǗ�����
  TYPE ph_performance_manage_dept_tbl IS TABLE OF
    xxwsh_order_headers_all.performance_management_dept%TYPE INDEX BY BINARY_INTEGER;
  -- �w������
  TYPE ph_instruction_dept_tbl IS TABLE OF
    xxwsh_order_headers_all.instruction_dept%TYPE INDEX BY BINARY_INTEGER;
  -- �U�֐�ID
  TYPE ph_transfer_location_id_tbl IS TABLE OF
    xxwsh_order_headers_all.transfer_location_id%TYPE INDEX BY BINARY_INTEGER;
  -- �U�֐�
  TYPE ph_transfer_location_code_tbl IS TABLE OF
    xxwsh_order_headers_all.transfer_location_code%TYPE INDEX BY BINARY_INTEGER;
  -- ���ڋL��
  TYPE ph_mixed_sign_tbl IS TABLE OF
    xxwsh_order_headers_all.mixed_sign%TYPE INDEX BY BINARY_INTEGER;
  -- ��ʍX�V����
  TYPE ph_screen_update_date_tbl IS TABLE OF
    xxwsh_order_headers_all.screen_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- ��ʍX�V��
  TYPE ph_screen_update_by_tbl IS TABLE OF
    xxwsh_order_headers_all.screen_update_by%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׈˗����ߓ���
  TYPE ph_tightening_date_tbl IS TABLE OF
    xxwsh_order_headers_all.tightening_date%TYPE INDEX BY BINARY_INTEGER;
  -- �����ID
  TYPE ph_vendor_id_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_id%TYPE INDEX BY BINARY_INTEGER;
  -- �����
  TYPE ph_vendor_code_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_code%TYPE INDEX BY BINARY_INTEGER;
  -- �����T�C�gID
  TYPE ph_vendor_site_id_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_site_id%TYPE INDEX BY BINARY_INTEGER;
  -- �����T�C�g
  TYPE ph_vendor_site_code_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_site_code%TYPE INDEX BY BINARY_INTEGER;
  -- �o�^����
  TYPE ph_registered_sequence_tbl IS TABLE OF
    xxwsh_order_headers_all.registered_sequence%TYPE INDEX BY BINARY_INTEGER;
  -- ���߃R���J�����gID
  TYPE ph_tightening_program_id_tbl IS TABLE OF
    xxwsh_order_headers_all.tightening_program_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���ߌ�C���敪
  TYPE ph_corrected_tighten_class_tbl IS TABLE OF
    xxwsh_order_headers_all.corrected_tighten_class%TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE ph_created_by_tbl IS TABLE OF
    xxwsh_order_headers_all.created_by%TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE ph_creation_date_tbl IS TABLE OF
    xxwsh_order_headers_all.creation_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE ph_last_updated_by_tbl IS TABLE OF
    xxwsh_order_headers_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE ph_last_update_date_tbl IS TABLE OF
    xxwsh_order_headers_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V���O�C��
  TYPE ph_last_update_login_tbl IS TABLE OF
    xxwsh_order_headers_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  -- �v��ID
  TYPE ph_request_id_tbl IS TABLE OF
    xxwsh_order_headers_all.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  TYPE ph_program_application_id_tbl IS TABLE OF
    xxwsh_order_headers_all.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- �R���J�����g�E�v���O����ID
  TYPE ph_program_id_tbl IS TABLE OF
    xxwsh_order_headers_all.program_id%TYPE INDEX BY BINARY_INTEGER;
  -- �v���O�����X�V��
  TYPE ph_program_update_date_tbl IS TABLE OF
    xxwsh_order_headers_all.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
  ---------------------------------------------
  -- �󒍖��׃A�h�I���o�^                    --
  ---------------------------------------------
  -- �󒍖��׃A�h�I��ID
  TYPE pl_order_line_id_tbl IS TABLE OF
    xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃w�b�_�A�h�I��ID
  TYPE pl_order_header_id_tbl IS TABLE OF
    xxwsh_order_lines_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���הԍ�
  TYPE pl_order_line_number_tbl IS TABLE OF
    xxwsh_order_lines_all.order_line_number%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃w�b�_ID
  TYPE pl_header_id_tbl IS TABLE OF
    xxwsh_order_lines_all.header_id%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍖���ID
  TYPE pl_line_id_tbl IS TABLE OF
    xxwsh_order_lines_all.line_id%TYPE INDEX BY BINARY_INTEGER;
  -- �˗�No
  TYPE pl_request_no_tbl IS TABLE OF
    xxwsh_order_lines_all.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- �o�וi��ID
  TYPE pl_ship_inv_item_id_tbl IS TABLE OF
    xxwsh_order_lines_all.shipping_inventory_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- �o�וi��
  TYPE pl_shipping_item_code_tbl IS TABLE OF
    xxwsh_order_lines_all.shipping_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ����
  TYPE pl_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �P��
  TYPE pl_uom_code_tbl IS TABLE OF
    xxwsh_order_lines_all.uom_code%TYPE INDEX BY BINARY_INTEGER;
  -- �P��
  TYPE pl_unit_price_tbl IS TABLE OF
    xxwsh_order_lines_all.unit_price%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׎��ѐ���
  TYPE pl_shipped_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.shipped_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �w�萻����
  TYPE pl_designated_prod_date_tbl IS TABLE OF
    xxwsh_order_lines_all.designated_production_date%TYPE INDEX BY BINARY_INTEGER;
  -- ���_�˗�����
  TYPE pl_based_request_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.based_request_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �˗��i��ID
  TYPE pl_request_item_id_tbl IS TABLE OF
    xxwsh_order_lines_all.request_item_id%TYPE INDEX BY BINARY_INTEGER;
  -- �˗��i��
  TYPE pl_request_item_code_tbl IS TABLE OF
    xxwsh_order_lines_all.request_item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ���Ɏ��ѐ���
  TYPE pl_ship_to_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.ship_to_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �t�уR�[�h
  TYPE pl_futai_code_tbl IS TABLE OF
    xxwsh_order_lines_all.futai_code%TYPE INDEX BY BINARY_INTEGER;
  -- �w����t�i���[�t�j
  TYPE pl_designated_date_tbl IS TABLE OF
    xxwsh_order_lines_all.designated_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ړ�No
  TYPE pl_move_number_tbl IS TABLE OF
    xxwsh_order_lines_all.move_number%TYPE INDEX BY BINARY_INTEGER;
  -- ����No
  TYPE pl_po_number_tbl IS TABLE OF
    xxwsh_order_lines_all.po_number%TYPE INDEX BY BINARY_INTEGER;
  -- �ڋq����
  TYPE pl_cust_po_number_tbl IS TABLE OF
    xxwsh_order_lines_all.cust_po_number%TYPE INDEX BY BINARY_INTEGER;
  -- �p���b�g��
  TYPE pl_pallet_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.pallet_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �i��
  TYPE pl_layer_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.layer_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �P�[�X��
  TYPE pl_case_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.case_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �d��
  TYPE pl_weight_tbl IS TABLE OF
    xxwsh_order_lines_all.weight%TYPE INDEX BY BINARY_INTEGER;
  -- �e��
  TYPE pl_capacity_tbl IS TABLE OF
    xxwsh_order_lines_all.capacity%TYPE INDEX BY BINARY_INTEGER;
  -- �p���b�g����
  TYPE pl_pallet_qty_tbl IS TABLE OF
    xxwsh_order_lines_all.pallet_qty%TYPE INDEX BY BINARY_INTEGER;
  -- �p���b�g�d��
  TYPE pl_pallet_weight_tbl IS TABLE OF
    xxwsh_order_lines_all.pallet_weight%TYPE INDEX BY BINARY_INTEGER;
  -- ������
  TYPE pl_reserved_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.reserved_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �����蓮�����敪
  TYPE pl_auto_reserve_class_tbl IS TABLE OF
    xxwsh_order_lines_all.automanual_reserve_class%TYPE INDEX BY BINARY_INTEGER;
  -- �폜�t���O
  TYPE pl_delete_flag_tbl IS TABLE OF
    xxwsh_order_lines_all.delete_flag%TYPE INDEX BY BINARY_INTEGER;
  -- �x���敪
  TYPE pl_warning_class_tbl IS TABLE OF
    xxwsh_order_lines_all.warning_class%TYPE INDEX BY BINARY_INTEGER;
  -- �x�����t
  TYPE pl_warning_date_tbl IS TABLE OF
    xxwsh_order_lines_all.warning_date%TYPE INDEX BY BINARY_INTEGER;
  -- �E�v
  TYPE pl_line_description_tbl IS TABLE OF
    xxwsh_order_lines_all.line_description%TYPE INDEX BY BINARY_INTEGER;
  -- �q�֕ԕi�C���^�t�F�[�X�σt���O
  TYPE pl_rm_if_flg_tbl IS TABLE OF
    xxwsh_order_lines_all.rm_if_flg%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׈˗��C���^�t�F�[�X�σt���O
  TYPE pl_shipping_request_if_flg_tbl IS TABLE OF
    xxwsh_order_lines_all.shipping_request_if_flg%TYPE INDEX BY BINARY_INTEGER;
  -- �o�׎��уC���^�t�F�[�X�σt���O
  TYPE pl_shipping_result_if_flg_tbl IS TABLE OF
    xxwsh_order_lines_all.shipping_result_if_flg%TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE pl_created_by_tbl IS TABLE OF
    xxwsh_order_lines_all.created_by%TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE pl_creation_date_tbl IS TABLE OF
    xxwsh_order_lines_all.creation_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE pl_last_updated_by_tbl IS TABLE OF
    xxwsh_order_lines_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE pl_last_update_date_tbl IS TABLE OF
    xxwsh_order_lines_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V���O�C��
  TYPE pl_last_update_login_tbl IS TABLE OF
    xxwsh_order_lines_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  -- �v��ID
  TYPE pl_request_id_tbl IS TABLE OF
    xxwsh_order_lines_all.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  TYPE pl_program_application_id_tbl IS TABLE OF
    xxwsh_order_lines_all.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- �R���J�����g�E�v���O����ID
  TYPE pl_program_id_tbl IS TABLE OF
    xxwsh_order_lines_all.program_id%TYPE INDEX BY BINARY_INTEGER;
  -- �v���O�����X�V��
  TYPE pl_program_update_date_tbl IS TABLE OF
    xxwsh_order_lines_all.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
-- 2008/07/17 v1.3 Start
  -- �w�b�_���b�Z�[�WPL/SQL�\�^
  TYPE msg_h_ttype       IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
  -- ���׃��b�Z�[�WPL/SQL�\�^
  TYPE msg_l_ttype       IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
-- 2008/07/17 v1.3 End
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
-- 2008/07/17 v1.3 Start
  -- ���̓p�����[�^
  gv_iv_data_class       VARCHAR2(100);      -- 1.�f�[�^���
  gv_iv_trans_type       VARCHAR2(100);      -- 2.�����敪
  gv_iv_req_dept         VARCHAR2(100);      -- 3.�˗�����
  gv_iv_vendor           VARCHAR2(100);      -- 4.�����
  gv_iv_ship_to          VARCHAR2(100);      -- 5.�z����
  gv_iv_arvl_time_from   VARCHAR2(100);      -- 6.���ɓ�FROM
  gv_iv_arvl_time_to     VARCHAR2(100);      -- 7.���ɓ�TO
  gv_iv_security_class   VARCHAR2(100);      -- 8.�Z�L�����e�B�敪
--
-- 2008/07/17 v1.3 End
  -- �R���N�V�����̒�`
  -- �擾�p(�w�b�_)
  gt_sup_req_headers_if_id_tbl        supply_req_headers_if_id_tbl;
  gt_trans_type_tbl                   trans_type_tbl;
  gt_weight_capacity_class_tbl        weight_capacity_class_tbl;
  gt_req_department_code_tbl          requested_department_code_tbl;
  gt_instruction_post_code_tbl        instruction_post_code_tbl;
  gt_vendor_code_tbl                  vendor_code_tbl;
  gt_ship_to_code_tbl                 ship_to_code_tbl;
  gt_shipped_locat_code_tbl           shipped_locat_code_tbl;
  gt_freight_carrier_code_tbl         freight_carrier_code_tbl;
  gt_ship_date_tbl                    ship_date_tbl;
  gt_arvl_date_tbl                    arvl_date_tbl;
  gt_freight_charge_class_tbl         freight_charge_class_tbl;
  gt_takeback_class_tbl               takeback_class_tbl;
  gt_arrival_time_from_tbl            arrival_time_from_tbl;
  gt_arrival_time_to_tbl              arrival_time_to_tbl;
  gt_product_date_tbl                 product_date_tbl;
  gt_producted_item_code_tbl          producted_item_code_tbl;
  gt_product_number_tbl               product_number_tbl;
  gt_header_description_tbl           header_description_tbl;
  gt_order_header_id_tbl              order_header_id_tbl;
  gt_vendor_id_tbl                    vendor_id_tbl;
  gt_customer_num_tbl                 customer_num_tbl;
  gt_cust_party_id_tbl                cust_party_id_tbl;
  gt_spare2_tbl                       spare2_tbl;
  gt_cust_account_id_tbl              cust_account_id_tbl;
  gt_vendor_site_id_tbl               vendor_site_id_tbl;
  gt_inventory_location_id_tbl        inventory_location_id_tbl;
  gt_leaf_calender_tbl                leaf_calender_tbl;
  gt_drink_calender_tbl               drink_calender_tbl;
  gt_carriers_party_id_tbl            carriers_party_id_tbl;
  gt_h_item_id_tbl                    h_item_id_tbl;
  gt_small_quantity_tbl               small_quantity_tbl;
  gt_label_quantity_tbl               label_quantity_tbl;
  gt_sum_quantity_tbl                 sum_quantity_tbl;
  gt_ship_method_tbl                  ship_method_tbl;
  gt_drink_deadweight_tbl             drink_deadweight_tbl;
  gt_leaf_deadweight_tbl              leaf_deadweight_tbl;
  gt_drink_loading_capacity_tbl       drink_loading_capacity_tbl;
  gt_leaf_loading_capacity_tbl        leaf_loading_capacity_tbl;
  gt_load_efficiency_we_tbl           load_efficiency_weight_tbl;
  gt_load_efficiency_ca_tbl           load_efficiency_capacity_tbl;
  gt_h_sum_weight_tbl                 h_sum_weight_tbl;
  gt_h_sum_capacity_tbl               h_sum_capacity_tbl;
  gt_seq_no_tbl                       seq_no_tbl;
-- 2008/07/17 v1.3 Start
  gt_lr_h_data_dump_tbl               lr_h_data_dump_tbl;
-- 2008/07/17 v1.3 End
  -- �擾�p(����)
  gt_supply_req_lines_if_id_tbl       supply_req_lines_if_id_tbl;
  gt_line_number_tbl                  line_number_tbl;
  gt_item_code_tbl                    item_code_tbl;
  gt_futai_code_tbl                   futai_code_tbl;
  gt_request_qty_tbl                  request_qty_tbl;
  gt_line_description_tbl             line_description_tbl;
  gt_line_headers_id_tbl              line_headers_id_tbl;
  gt_order_line_id_tbl                order_line_id_tbl;
  gt_l_item_id_tbl                    l_item_id_tbl;
  gt_item_um_tbl                      item_um_tbl;
  gt_num_of_deliver_tbl               num_of_deliver_tbl;
  gt_conv_unit_tbl                    conv_unit_tbl;
  gt_num_of_cases_tbl                 num_of_cases_tbl;
  gt_inventory_item_id_tbl            inventory_item_id_tbl;
  gt_whse_item_id_tbl                 whse_item_id_tbl;
  gt_item_no_tbl                      item_no_tbl;
  gt_lot_ctl_tbl                      lot_ctl_tbl;
  gt_unit_price_tbl                   unit_price_tbl;
  gt_l_sum_weight_tbl                 l_sum_weight_tbl;
  gt_l_sum_capacity_tbl               l_sum_capacity_tbl;
-- 2008/07/17 v1.3 Start
  gt_l_weight_capacity_class          l_weight_capacity_class;
  gt_lr_l_data_dump_tbl               lr_l_data_dump_tbl;
-- 2008/07/17 v1.3 End
--
  -- �o�^�p(�w�b�_)
  gt_ph_order_header_id_tbl                 ph_order_header_id_tbl;
  gt_ph_order_type_id_tbl                   ph_order_type_id_tbl;
  gt_ph_organization_id_tbl                 ph_organization_id_tbl;
  gt_ph_header_id_tbl                       ph_header_id_tbl;
  gt_ph_latest_external_flag_tbl            ph_latest_external_flag_tbl;
  gt_ph_ordered_date_tbl                    ph_ordered_date_tbl;
  gt_ph_customer_id_tbl                     ph_customer_id_tbl;
  gt_ph_customer_code_tbl                   ph_customer_code_tbl;
  gt_ph_deliver_to_id_tbl                   ph_deliver_to_id_tbl;
  gt_ph_deliver_to_tbl                      ph_deliver_to_tbl;
  gt_ph_shipping_inst_tbl                   ph_shipping_instructions_tbl;
  gt_ph_career_id_tbl                       ph_career_id_tbl;
  gt_ph_freight_carrier_code_tbl            ph_freight_carrier_code_tbl;
  gt_ph_shipping_method_code_tbl            ph_shipping_method_code_tbl;
  gt_ph_cust_po_number_tbl                  ph_cust_po_number_tbl;
  gt_ph_price_list_id_tbl                   ph_price_list_id_tbl;
  gt_ph_request_no_tbl                      ph_request_no_tbl;
  gt_ph_base_request_no_tbl                 ph_base_request_no_tbl;
  gt_ph_req_status_tbl                      ph_req_status_tbl;
  gt_ph_delivery_no_tbl                     ph_delivery_no_tbl;
  gt_ph_prev_delivery_no_tbl                ph_prev_delivery_no_tbl;
  gt_ph_schedule_ship_date_tbl              ph_schedule_ship_date_tbl;
  gt_ph_schedule_arr_date_tbl               ph_schedule_arrival_date_tbl;
  gt_ph_mixed_no_tbl                        ph_mixed_no_tbl;
  gt_ph_collected_pallet_qty_tbl            ph_collected_pallet_qty_tbl;
  gt_ph_confirm_req_class_tbl               ph_confirm_request_class_tbl;
  gt_ph_freight_charge_class_tbl            ph_freight_charge_class_tbl;
  gt_ph_shikyu_inst_class_tbl               ph_shikyu_inst_class_tbl;
  gt_ph_sk_inst_rcv_class_tbl               ph_shikyu_inst_rcv_class_tbl;
  gt_ph_amount_fix_class_tbl                ph_amount_fix_class_tbl;
  gt_ph_takeback_class_tbl                  ph_takeback_class_tbl;
  gt_ph_deliver_from_id_tbl                 ph_deliver_from_id_tbl;
  gt_ph_deliver_from_tbl                    ph_deliver_from_tbl;
  gt_ph_head_sales_branch_tbl               ph_head_sales_branch_tbl;
  gt_ph_input_sales_branch_tbl              ph_input_sales_branch_tbl;
  gt_ph_po_no_tbl                           ph_po_no_tbl;
  gt_ph_prod_class_tbl                      ph_prod_class_tbl;
  gt_ph_item_class_tbl                      ph_item_class_tbl;
  gt_ph_no_cont_fre_class_tbl               ph_no_cont_freight_class_tbl;
  gt_ph_arrival_time_from_tbl               ph_arrival_time_from_tbl;
  gt_ph_arrival_time_to_tbl                 ph_arrival_time_to_tbl;
  gt_ph_designated_item_id_tbl              ph_designated_item_id_tbl;
  gt_ph_designated_item_code_tbl            ph_designated_item_code_tbl;
  gt_ph_designated_prod_date_tbl            ph_designated_prod_date_tbl;
  gt_ph_designated_branch_no_tbl            ph_designated_branch_no_tbl;
  gt_ph_slip_number_tbl                     ph_slip_number_tbl;
  gt_ph_sum_quantity_tbl                    ph_sum_quantity_tbl;
  gt_ph_small_quantity_tbl                  ph_small_quantity_tbl;
  gt_ph_label_quantity_tbl                  ph_label_quantity_tbl;
  gt_ph_load_efficiency_we_tbl              ph_loading_efficiency_we_tbl;
  gt_ph_load_efficiency_ca_tbl              ph_loading_efficiency_ca_tbl;
  gt_ph_based_weight_tbl                    ph_based_weight_tbl;
  gt_ph_based_capacity_tbl                  ph_based_capacity_tbl;
  gt_ph_sum_weight_tbl                      ph_sum_weight_tbl;
  gt_ph_sum_capacity_tbl                    ph_sum_capacity_tbl;
  gt_ph_mixed_ratio_tbl                     ph_mixed_ratio_tbl;
  gt_ph_pallet_sum_quantity_tbl             ph_pallet_sum_quantity_tbl;
  gt_ph_real_pallet_quantity_tbl            ph_real_pallet_quantity_tbl;
  gt_ph_sum_pallet_weight_tbl               ph_sum_pallet_weight_tbl;
  gt_ph_order_source_ref_tbl                ph_order_source_ref_tbl;
  gt_ph_result_fre_carr_id_tbl              ph_result_freight_carr_id_tbl;
  gt_ph_result_fre_carr_code_tbl            ph_result_fre_carr_code_tbl;
  gt_ph_res_ship_meth_code_tbl              ph_result_ship_method_code_tbl;
  gt_ph_result_deliver_to_id_tbl            ph_result_deliver_to_id_tbl;
  gt_ph_result_deliver_to_tbl               ph_result_deliver_to_tbl;
  gt_ph_shipped_date_tbl                    ph_shipped_date_tbl;
  gt_ph_arrival_date_tbl                    ph_arrival_date_tbl;
  gt_ph_weight_ca_class_tbl                 ph_weight_capacity_class_tbl;
  gt_ph_actual_confirm_class_tbl            ph_actual_confirm_class_tbl;
  gt_ph_notif_status_tbl                    ph_notif_status_tbl;
  gt_ph_prev_notif_status_tbl               ph_prev_notif_status_tbl;
  gt_ph_notif_date_tbl                      ph_notif_date_tbl;
  gt_ph_new_modify_flg_tbl                  ph_new_modify_flg_tbl;
  gt_ph_process_status_tbl                  ph_process_status_tbl;
  gt_ph_perform_manage_dept_tbl             ph_performance_manage_dept_tbl;
  gt_ph_instruction_dept_tbl                ph_instruction_dept_tbl;
  gt_ph_transfer_location_id_tbl            ph_transfer_location_id_tbl;
  gt_ph_trans_location_code_tbl             ph_transfer_location_code_tbl;
  gt_ph_mixed_sign_tbl                      ph_mixed_sign_tbl;
  gt_ph_screen_update_date_tbl              ph_screen_update_date_tbl;
  gt_ph_screen_update_by_tbl                ph_screen_update_by_tbl;
  gt_ph_tightening_date_tbl                 ph_tightening_date_tbl;
  gt_ph_vendor_id_tbl                       ph_vendor_id_tbl;
  gt_ph_vendor_code_tbl                     ph_vendor_code_tbl;
  gt_ph_vendor_site_id_tbl                  ph_vendor_site_id_tbl;
  gt_ph_vendor_site_code_tbl                ph_vendor_site_code_tbl;
  gt_ph_registered_sequence_tbl             ph_registered_sequence_tbl;
  gt_ph_tight_program_id_tbl                ph_tightening_program_id_tbl;
  gt_ph_correct_tight_class_tbl             ph_corrected_tighten_class_tbl;
  gt_ph_created_by_tbl                      ph_created_by_tbl;
  gt_ph_creation_date_tbl                   ph_creation_date_tbl;
  gt_ph_last_updated_by_tbl                 ph_last_updated_by_tbl;
  gt_ph_last_update_date_tbl                ph_last_update_date_tbl;
  gt_ph_last_update_login_tbl               ph_last_update_login_tbl;
  gt_ph_request_id_tbl                      ph_request_id_tbl;
  gt_ph_program_appli_id_tbl                ph_program_application_id_tbl;
  gt_ph_program_id_tbl                      ph_program_id_tbl;
  gt_ph_program_up_date_tbl                 ph_program_update_date_tbl;
  -- �o�^�p(����)
  gt_pl_order_line_id_tbl                   pl_order_line_id_tbl;
  gt_pl_order_header_id_tbl                 pl_order_header_id_tbl;
  gt_pl_order_line_number_tbl               pl_order_line_number_tbl;
  gt_pl_header_id_tbl                       pl_header_id_tbl;
  gt_pl_line_id_tbl                         pl_line_id_tbl;
  gt_pl_request_no_tbl                      pl_request_no_tbl;
  gt_pl_ship_inv_item_id_tbl                pl_ship_inv_item_id_tbl;
  gt_pl_shipping_item_code_tbl              pl_shipping_item_code_tbl;
  gt_pl_quantity_tbl                        pl_quantity_tbl;
  gt_pl_uom_code_tbl                        pl_uom_code_tbl;
  gt_pl_unit_price_tbl                      pl_unit_price_tbl;
  gt_pl_shipped_quantity_tbl                pl_shipped_quantity_tbl;
  gt_pl_design_prod_date_tbl                pl_designated_prod_date_tbl;
  gt_pl_based_req_quan_tbl                  pl_based_request_quantity_tbl;
  gt_pl_request_item_id_tbl                 pl_request_item_id_tbl;
  gt_pl_request_item_code_tbl               pl_request_item_code_tbl;
  gt_pl_ship_to_quantity_tbl                pl_ship_to_quantity_tbl;
  gt_pl_futai_code_tbl                      pl_futai_code_tbl;
  gt_pl_designated_date_tbl                 pl_designated_date_tbl;
  gt_pl_move_number_tbl                     pl_move_number_tbl;
  gt_pl_po_number_tbl                       pl_po_number_tbl;
  gt_pl_cust_po_number_tbl                  pl_cust_po_number_tbl;
  gt_pl_pallet_quantity_tbl                 pl_pallet_quantity_tbl;
  gt_pl_layer_quantity_tbl                  pl_layer_quantity_tbl;
  gt_pl_case_quantity_tbl                   pl_case_quantity_tbl;
  gt_pl_weight_tbl                          pl_weight_tbl;
  gt_pl_capacity_tbl                        pl_capacity_tbl;
  gt_pl_pallet_qty_tbl                      pl_pallet_qty_tbl;
  gt_pl_pallet_weight_tbl                   pl_pallet_weight_tbl;
  gt_pl_reserved_quantity_tbl               pl_reserved_quantity_tbl;
  gt_pl_auto_res_class_tbl                  pl_auto_reserve_class_tbl;
  gt_pl_delete_flag_tbl                     pl_delete_flag_tbl;
  gt_pl_warning_class_tbl                   pl_warning_class_tbl;
  gt_pl_warning_date_tbl                    pl_warning_date_tbl;
  gt_pl_line_description_tbl                pl_line_description_tbl;
  gt_pl_rm_if_flg_tbl                       pl_rm_if_flg_tbl;
  gt_pl_ship_req_if_flg_tbl                 pl_shipping_request_if_flg_tbl;
  gt_pl_ship_res_if_flg_tbl                 pl_shipping_result_if_flg_tbl;
  gt_pl_created_by_tbl                      pl_created_by_tbl;
  gt_pl_creation_date_tbl                   pl_creation_date_tbl;
  gt_pl_last_updated_by_tbl                 pl_last_updated_by_tbl;
  gt_pl_last_update_date_tbl                pl_last_update_date_tbl;
  gt_pl_last_update_login_tbl               pl_last_update_login_tbl;
  gt_pl_request_id_tbl                      pl_request_id_tbl;
  gt_pl_program_appli_id_tbl                pl_program_application_id_tbl;
  gt_pl_program_id_tbl                      pl_program_id_tbl;
  gt_pl_program_update_date_tbl             pl_program_update_date_tbl;
--
-- 2008/07/17 v1.3 Start
  -- �w�b�_�f�[�^�_���v�pPL/SQL�\
  normal_h_dump_tab           msg_h_ttype;    -- ����
  -- ���׃f�[�^�_���v�pPL/SQL�\
  normal_l_dump_tab           msg_l_ttype;    -- ����
--
  -- PL/SQL�\�J�E���g
  gn_h_cnt                  NUMBER := 0;  -- ����G���[���b�Z�[�WPL/SQ�\ �w�b�_�J�E���g
  gn_l_cnt                  NUMBER := 0;  -- ����G���[���b�Z�[�WPL/SQ�\ ���׃J�E���g
--
-- 2008/07/17 v1.3 End
  gd_sysdate                DATE;             -- �V�X�e�����t
  gn_user_id                NUMBER;           -- ���[�UID
  gn_login_id               NUMBER;           -- �ŏI�X�V���O�C��
  gn_conc_request_id        NUMBER;           -- �v��ID
  gn_prog_appl_id           NUMBER;           -- �ݶ��āE��۸��т̱��ع����ID
  gn_conc_program_id        NUMBER;           -- �R���J�����g�E�v���O����ID
  gv_before_item_no         VARCHAR2(7);      -- �O���וi��
  gd_standard_date          DATE;             -- �K�p��
--
  -- �J�E���g�ϐ�
  gn_i                      NUMBER;           -- �w�b�_�J�E���g�ϐ�
  gn_j                      NUMBER;           -- ���׃J�E���g�ϐ�
--
  -- �v���t�@�C��
  gv_master_org_prf         VARCHAR2(100);    -- �v���t�@�C���u�}�X�^�g�D�v
  gv_price_list_prf         VARCHAR2(100);    -- �v���t�@�C���u��\���i�\�v
  gv_item_div_prf           VARCHAR2(100);    -- �v���t�@�C���u���i�敪(�Z�L�����e�B)�v
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : �������� (F-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_proc'; -- �v���O������
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
    lv_master_org_prf_name   CONSTANT VARCHAR2(100) := '�}�X�^�g�D';
    lv_price_list_prf_name   CONSTANT VARCHAR2(100) := '��\���i�\';
    lv_item_div_prf_name     CONSTANT VARCHAR2(100) := '���i�敪';
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- �V�X�e�����t�擾
    gd_sysdate := SYSDATE;
    -- WHO�J�������擾
    gn_user_id          := FND_GLOBAL.USER_ID;              -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;             -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;      -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;         -- �ݶ��āE��۸��т̱��ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;      -- �R���J�����g�E�v���O����ID
--
    -- �v���t�@�C���u�}�X�^�g�D�v�擾
    gv_master_org_prf := FND_PROFILE.VALUE(gv_master_org_id);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_master_org_prf IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_get_prf,
                                            gv_tkn_ng_profile,
                                            lv_master_org_prf_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C���u��\���i�\�v�擾
    gv_price_list_prf := FND_PROFILE.VALUE(gv_price_list_id);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_price_list_prf IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_get_prf,
                                            gv_tkn_ng_profile,
                                            lv_price_list_prf_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C���u���i�敪�v�擾
    gv_item_div_prf   := FND_PROFILE.VALUE(gv_item_div_id);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_item_div_prf IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_get_prf,
                                            gv_tkn_ng_profile,
                                            lv_item_div_prf_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END init_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_header_proc
   * Description      : �w�b�_�f�[�^�擾���� (F-2)
   ***********************************************************************************/
  PROCEDURE get_header_proc(
    iv_data_class     IN         VARCHAR2,      -- 1.�f�[�^���
    iv_trans_type     IN         VARCHAR2,      -- 2.�����敪
    iv_req_dept       IN         VARCHAR2,      -- 3.�˗�����
    iv_vendor         IN         VARCHAR2,      -- 4.�����
    iv_ship_to        IN         VARCHAR2,      -- 5.�z����
    iv_arvl_time_from IN         VARCHAR2,      -- 6.���ɓ�FROM
    iv_arvl_time_to   IN         VARCHAR2,      -- 7.���ɓ�TO
    iv_security_class IN         VARCHAR2,      -- 8.�Z�L�����e�B�敪
    ov_errbuf         OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_header_proc'; -- �v���O������
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
    -- �Z�L�����e�B�敪
    cv_sec_itoen  CONSTANT VARCHAR2(100) := '1'; -- �ɓ������[�U�[�^�C�v
    cv_sec_vendor CONSTANT VARCHAR2(100) := '2'; -- ����惆�[�U�[�^�C�v
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  srhi.supply_req_headers_if_id,    -- �x���˗����C���^�t�F�[�X�w�b�_ID
            srhi.trans_type,                  -- �����敪
            srhi.weight_capacity_class,       -- �d�ʗe�ϋ敪
            srhi.requested_department_code,   -- �˗������R�[�h
            srhi.instruction_post_code,       -- �w�������R�[�h
            srhi.vendor_code,                 -- �����R�[�h
            srhi.ship_to_code,                -- �z����R�[�h
            srhi.shipped_locat_code,          -- �o�ɑq�ɃR�[�h
            srhi.freight_carrier_code,        -- �^���Ǝ҃R�[�h
            srhi.ship_date,                   -- �o�ɓ�
            srhi.arvl_date,                   -- ���ɓ�
            srhi.freight_charge_class,        -- �^���敪
            srhi.takeback_class,              -- ����敪
            srhi.arrival_time_from,           -- ���׎���FROM
            srhi.arrival_time_to,             -- ���׎���TO
            srhi.product_date,                -- ������
            srhi.producted_item_code,         -- �����i�ڃR�[�h
            srhi.product_number,              -- �����ԍ�
            srhi.header_description,          -- �w�b�_�E�v
            NULL,                             -- ���v�d��
            NULL,                             -- ���v�e��
            NULL,                             -- ������
            NULL,                             -- ���x������
-- 2008/07/17 v1.3 Start
--            NULL                              -- ���v����
            NULL,                             -- ���v����
            TO_CHAR(srhi.trans_type)                            || gv_msg_comma ||
            srhi.weight_capacity_class                          || gv_msg_comma ||
            srhi.requested_department_code                      || gv_msg_comma ||
            srhi.instruction_post_code                          || gv_msg_comma ||
            srhi.vendor_code                                    || gv_msg_comma ||
            srhi.ship_to_code                                   || gv_msg_comma ||
            srhi.shipped_locat_code                             || gv_msg_comma ||
            srhi.freight_carrier_code                           || gv_msg_comma ||
            TO_CHAR(srhi.ship_date, 'YYYY/MM/DD HH24:MI:SS')    || gv_msg_comma ||
            TO_CHAR(srhi.arvl_date, 'YYYY/MM/DD HH24:MI:SS')    || gv_msg_comma ||
            srhi.freight_charge_class                           || gv_msg_comma ||
            srhi.takeback_class                                 || gv_msg_comma ||
            srhi.arrival_time_from                              || gv_msg_comma ||
            srhi.arrival_time_to                                || gv_msg_comma ||
            TO_CHAR(srhi.product_date, 'YYYY/MM/DD HH24:MI:SS') || gv_msg_comma ||
            srhi.producted_item_code                            || gv_msg_comma ||
            srhi.product_number                                 || gv_msg_comma ||
            srhi.header_description           -- �f�[�^�_���v
-- 2008/07/17 v1.3 End
    BULK COLLECT INTO
            gt_sup_req_headers_if_id_tbl,
            gt_trans_type_tbl,
            gt_weight_capacity_class_tbl,
            gt_req_department_code_tbl,
            gt_instruction_post_code_tbl,
            gt_vendor_code_tbl,
            gt_ship_to_code_tbl,
            gt_shipped_locat_code_tbl,
            gt_freight_carrier_code_tbl,
            gt_ship_date_tbl,
            gt_arvl_date_tbl,
            gt_freight_charge_class_tbl,
            gt_takeback_class_tbl,
            gt_arrival_time_from_tbl,
            gt_arrival_time_to_tbl,
            gt_product_date_tbl,
            gt_producted_item_code_tbl,
            gt_product_number_tbl,
            gt_header_description_tbl,
            gt_h_sum_weight_tbl,
            gt_h_sum_capacity_tbl,
            gt_small_quantity_tbl,
            gt_label_quantity_tbl,
-- 2008/07/17 v1.3 Start
--            gt_sum_quantity_tbl
            gt_sum_quantity_tbl,
            gt_lr_h_data_dump_tbl
-- 2008/07/17 v1.3 End
    FROM    xxpo_supply_req_headers_if    srhi
    WHERE   srhi.data_class                 =   iv_data_class
    AND     srhi.trans_type                 =   iv_trans_type
    AND     srhi.requested_department_code  =   NVL(iv_req_dept,srhi.requested_department_code)
    AND     srhi.vendor_code                =   iv_vendor
    AND     srhi.ship_to_code               =   NVL(iv_ship_to,srhi.ship_to_code)
    AND     srhi.arvl_date                  >=
              FND_DATE.STRING_TO_DATE(iv_arvl_time_from, 'YYYY/MM/DD HH24:MI:SS')
    AND     srhi.arvl_date                  <=
              FND_DATE.STRING_TO_DATE(iv_arvl_time_to, 'YYYY/MM/DD HH24:MI:SS')
    AND     (
              (iv_security_class            =   cv_sec_itoen)
              OR
              (
                (iv_security_class          =   cv_sec_vendor)
                  AND srhi.vendor_code in
                    (SELECT papf.attribute4   vendor_code             -- �����R�[�h(�d����R�[�h)
                    FROM    fnd_user          fu,                             -- ���[�U�[�}�X�^
                            per_all_people_f  papf                            -- �]�ƈ��}�X�^
                    WHERE   -- ** �������� ** --
                            fu.employee_id   = papf.person_id                 -- �]�ƈ�ID
                            -- ** ���o���� ** --
                    AND     papf.effective_start_date <= TRUNC(gd_sysdate)    -- �K�p�J�n��
                    AND     papf.effective_end_date   >= TRUNC(gd_sysdate)    -- �K�p�I����
                    AND     fu.start_date             <= TRUNC(gd_sysdate)    -- �K�p�J�n��
                    AND     (
                              (fu.end_date            IS NULL)                -- �K�p�I����
                              OR
                              (fu.end_date            >= TRUNC(gd_sysdate))
                            )
                    AND     fu.user_id                 = FND_GLOBAL.USER_ID)  -- ���[�U�[ID
              )
            )
    ORDER BY srhi.supply_req_headers_if_id
    FOR UPDATE NOWAIT;
--
    -- ��������(�w�b�_)�J�E���g
    gn_h_target_cnt := gt_sup_req_headers_if_id_tbl.COUNT;
--
    -- �f�[�^�擾�G���[
    IF (gt_sup_req_headers_if_id_tbl.COUNT = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_get_data);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN check_lock_expt THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_lock,
                                            gv_tkn_table,
                                            gv_srhi_name);
      lv_errbuf  := lv_errmsg;
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
  END get_header_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_line_proc
   * Description      : ���׃f�[�^�擾���� (F-3)
   ***********************************************************************************/
  PROCEDURE get_line_proc(
    iv_data_class     IN         VARCHAR2,      -- 1.�f�[�^���
    iv_trans_type     IN         VARCHAR2,      -- 2.�����敪
    iv_req_dept       IN         VARCHAR2,      -- 3.�˗�����
    iv_vendor         IN         VARCHAR2,      -- 4.�����
    iv_ship_to        IN         VARCHAR2,      -- 5.�z����
    iv_arvl_time_from IN         VARCHAR2,      -- 6.���ɓ�FROM
    iv_arvl_time_to   IN         VARCHAR2,      -- 7.���ɓ�TO
    iv_security_class IN         VARCHAR2,      -- 8.�Z�L�����e�B�敪
    ov_errbuf         OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_line_proc'; -- �v���O������
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
    -- �Z�L�����e�B�敪
    cv_sec_itoen  CONSTANT VARCHAR2(100) := '1'; -- �ɓ������[�U�[�^�C�v
    cv_sec_vendor CONSTANT VARCHAR2(100) := '2'; -- ����惆�[�U�[�^�C�v
--
    -- *** ���[�J���ϐ� ***
    -- �v���t�@�C��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT  srli.supply_req_lines_if_id,      -- �x���˗����C���^�t�F�[�X����ID
            srli.item_code,                   -- �i�ڃR�[�h
            srli.futai_code,                  -- �t��
            srli.request_qty,                 -- �˗�����
            srli.line_description,            -- ���דE�v
-- 2008/07/17 v1.3 Start
--            srli.supply_req_headers_if_id     -- �w�b�_ID
            srli.supply_req_headers_if_id,    -- �w�b�_ID
            srli.corporation_name      || gv_msg_comma ||
            srli.data_class            || gv_msg_comma ||
            srli.transfer_branch_no    || gv_msg_comma ||
            TO_CHAR(srli.line_number)  || gv_msg_comma ||
            srli.item_code             || gv_msg_comma ||
            srli.futai_code            || gv_msg_comma ||
            TO_CHAR(srli.request_qty)  || gv_msg_comma ||
            srli.line_description             -- �f�[�^�_���v
-- 2008/07/17 v1.3 End
    BULK COLLECT INTO
            gt_supply_req_lines_if_id_tbl,
            gt_item_code_tbl,
            gt_futai_code_tbl,
            gt_request_qty_tbl,
            gt_line_description_tbl,
-- 2008/07/17 v1.3 Start
--            gt_line_headers_id_tbl
            gt_line_headers_id_tbl,
            gt_lr_l_data_dump_tbl
-- 2008/07/17 v1.3 End
    FROM    xxpo_supply_req_headers_if  srhi,
            xxpo_supply_req_lines_if    srli
    WHERE   srhi.supply_req_headers_if_id   =   srli.supply_req_headers_if_id
    AND     srhi.data_class                 =   iv_data_class
    AND     srhi.trans_type                 =   iv_trans_type
    AND     srhi.requested_department_code  =   NVL(iv_req_dept,srhi.requested_department_code)
    AND     srhi.vendor_code                =   iv_vendor
    AND     srhi.ship_to_code               =   NVL(iv_ship_to,srhi.ship_to_code)
    AND     srhi.arvl_date                  >=
              FND_DATE.STRING_TO_DATE(iv_arvl_time_from, 'YYYY/MM/DD HH24:MI:SS')
    AND     srhi.arvl_date                  <=
              FND_DATE.STRING_TO_DATE(iv_arvl_time_to, 'YYYY/MM/DD HH24:MI:SS')
    AND     (
              (iv_security_class            =   cv_sec_itoen)
              OR
              (
                (iv_security_class          =   cv_sec_vendor)
                  AND srhi.vendor_code in
                    (SELECT papf.attribute4   vendor_code             -- �����R�[�h(�d����R�[�h)
                    FROM    fnd_user          fu,                             -- ���[�U�[�}�X�^
                            per_all_people_f  papf                            -- �]�ƈ��}�X�^
                    WHERE   -- ** �������� ** --
                            fu.employee_id   = papf.person_id                 -- �]�ƈ�ID
                            -- ** ���o���� ** --
                    AND     papf.effective_start_date <= TRUNC(gd_sysdate)    -- �K�p�J�n��
                    AND     papf.effective_end_date   >= TRUNC(gd_sysdate)    -- �K�p�I����
                    AND     fu.start_date             <= TRUNC(gd_sysdate)    -- �K�p�J�n��
                    AND     (
                              (fu.end_date            IS NULL)                -- �K�p�I����
                              OR
                              (fu.end_date            >= TRUNC(gd_sysdate))
                            )
                    AND     fu.user_id                 = FND_GLOBAL.USER_ID)  -- ���[�U�[ID
              )
            )
    ORDER BY srli.supply_req_headers_if_id, srli.item_code
    FOR UPDATE OF srli.supply_req_lines_if_id NOWAIT;
--
    -- ��������(����)�J�E���g
    gn_l_target_cnt := gt_supply_req_lines_if_id_tbl.COUNT;
--
    -- �f�[�^�擾�G���[
    IF (gt_supply_req_lines_if_id_tbl.COUNT = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_get_data);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- ���b�N�G���[
    WHEN check_lock_expt THEN
      lv_errmsg  := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_lock,
                                            gv_tkn_table,
                                            gv_srli_name);
      lv_errbuf  := lv_errmsg;
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
  END get_line_proc;
--
-- 2008/07/17 v1.3 Start
  /**********************************************************************************
   * Procedure Name   : chk_essent_proc
   * Description      : �K�{�`�F�b�N���� (F-4)
   ***********************************************************************************/
/*  PROCEDURE chk_essent_proc(
    iv_header_line_kbn  IN         VARCHAR2,      --   �w�b�_���׋敪
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_essent_proc'; -- �v���O������
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
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- �w�b�_����
    IF (iv_header_line_kbn = gv_header) THEN
      -- ���L���ڂ�NULL�̏ꍇ�A�G���[
      IF (
           (gt_trans_type_tbl(gn_i) IS NULL) OR                    -- �w�b�_������敪�
           (gt_weight_capacity_class_tbl(gn_i) IS NULL) OR         -- �w�b�_��d�ʗe�ϋ敪�
           (gt_req_department_code_tbl(gn_i) IS NULL) OR           -- �w�b�_��˗������R�[�h�
           (gt_vendor_code_tbl(gn_i) IS NULL) OR                   -- �w�b�_������R�[�h�
           (gt_ship_to_code_tbl(gn_i) IS NULL) OR                  -- �w�b�_��z����R�[�h�
           (gt_shipped_locat_code_tbl(gn_i) IS NULL) OR            -- �w�b�_��o�ɑq�ɃR�[�h�
           (gt_arvl_date_tbl(gn_i) IS NULL) OR                     -- �w�b�_����ɓ��
           (
             -- �^���敪����Ώۣ�̏ꍇ
             (gt_freight_charge_class_tbl(gn_i) = gv_object) AND
               (gt_freight_carrier_code_tbl(gn_i) IS NULL)         -- �w�b�_��^���Ǝ҃R�[�h�
           )
         ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_essent);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- ���׍���
    ELSIF (iv_header_line_kbn = gv_line) THEN
      -- ���L���ڂ�NULL�̏ꍇ�A�G���[
      IF (
           (gt_item_code_tbl(gn_j) IS NULL) OR                       -- ���ע�i�ڃR�[�h�
           (gt_request_qty_tbl(gn_j) IS NULL)                        -- ���ע�˗����ʣ
         ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_essent);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
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
  END chk_essent_proc;
*/--
-- 2008/07/17 v1.3 End
  /**********************************************************************************
   * Procedure Name   : chk_exist_mst_proc
   * Description      : �}�X�^���݃`�F�b�N���� (F-5)
   ***********************************************************************************/
  PROCEDURE chk_exist_mst_proc(
    iv_header_line_kbn  IN         VARCHAR2,      --   �w�b�_���׋敪
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_exist_mst_proc'; -- �v���O������
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
    -- �e�[�u��(�r���[)��
    cv_xvv            CONSTANT VARCHAR2(100) := '�d������VIEW';
    cv_xvsv           CONSTANT VARCHAR2(100) := '�d����T�C�g���VIEW';
    cv_xilv           CONSTANT VARCHAR2(100) := 'OPM�ۊǏꏊ���VIEW';
    cv_xcv            CONSTANT VARCHAR2(100) := '�^���Ǝҏ��VIEW';
    cv_ximv           CONSTANT VARCHAR2(100) := 'OPM�i�ڏ��VIEW';
--
    cv_trans_pay      CONSTANT VARCHAR2(1)   := '2';                    -- �����敪��d���L���
    cn_lot_ctl        CONSTANT NUMBER(5,0)   := 1;                      -- �Ǘ��Ώ�
--
    -- *** ���[�J���ϐ� ***
    lv_close_period   VARCHAR2(100);              -- �݌ɉ�v���ԃN���[�Y���t
    ln_cnt            NUMBER;                     -- ���݃J�E���g
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���[�J���ϐ��̏�����
    lv_close_period   := NULL;
    ln_cnt            := 0;
--
    -- �w�b�_����
    IF (iv_header_line_kbn = gv_header) THEN
      ---------------------------------------------
      -- �w�b�_���ڑ��݃`�F�b�N                  --
      ---------------------------------------------
-- 2008/07/17 v1.3 Start
      -- ��d�ʗe�ϋ敪�
      --�J�E���g�ϐ�������
      ln_cnt := 0; 
--
      SELECT  COUNT(1)
      INTO    ln_cnt
      FROM    xxcmn_lookup_values_v 
      WHERE   lookup_type = gv_lup_weight_capacity
      AND     lookup_code = gt_weight_capacity_class_tbl(gn_i)
      AND     ROWNUM      = 1;
--
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_mst_exist,
                                              gv_tkn_date_item,
                                              gv_weight_capacity);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ��˗������R�[�h�
      --�J�E���g�ϐ�������
      ln_cnt := 0; 
--
      SELECT  COUNT(1)
      INTO    ln_cnt
      FROM    xxcmn_locations_v   xlv
      WHERE   xlv.location_code   = gt_req_department_code_tbl(gn_i)
      AND     ROWNUM              = 1;
--
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_mst_exist,
                                              gv_tkn_date_item,
                                              gv_req_department);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ��w�������R�[�h�
--
      IF (gt_instruction_post_code_tbl(gn_i) IS NOT NULL) THEN
        --�J�E���g�ϐ�������
        ln_cnt := 0; 
        SELECT  COUNT(1)
        INTO    ln_cnt
        FROM    xxcmn_locations_v   xlv
        WHERE   xlv.location_code   = gt_instruction_post_code_tbl(gn_i)
        AND     ROWNUM              = 1;
--
        IF (ln_cnt = 0) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_mst_exist,
                                                gv_tkn_date_item,
                                                gv_instruction_post);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      -- ��^���敪�
      --�J�E���g�ϐ�������
      ln_cnt := 0; 
--
      SELECT  COUNT(1)
      INTO    ln_cnt
      FROM    xxcmn_lookup_values_v 
      WHERE   lookup_type = gv_lup_freight_class
      AND     lookup_code = gt_freight_charge_class_tbl(gn_i)
      AND     ROWNUM      = 1;
--
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_mst_exist,
                                              gv_tkn_date_item,
                                              gv_freight_charge_class);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- ����׎���FROM�
      IF (gt_arrival_time_from_tbl(gn_i) IS NOT NULL) THEN
        --�J�E���g�ϐ�������
        ln_cnt := 0; 
--
        SELECT  COUNT(1)
        INTO    ln_cnt
        FROM    xxcmn_lookup_values_v 
        WHERE   lookup_type = gv_lup_arrival_time
        AND     lookup_code = gt_arrival_time_from_tbl(gn_i)
        AND     ROWNUM      = 1;
--
        IF (ln_cnt = 0) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_mst_exist,
                                                gv_tkn_date_item,
                                                gv_arrival_time_from);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      -- ����׎���TO�
      IF (gt_arrival_time_to_tbl(gn_i) IS NOT NULL) THEN
        --�J�E���g�ϐ�������
        ln_cnt := 0; 
--
        SELECT  COUNT(1)
        INTO    ln_cnt
        FROM    xxcmn_lookup_values_v 
        WHERE   lookup_type = gv_lup_arrival_time
        AND     lookup_code = gt_arrival_time_to_tbl(gn_i)
        AND     ROWNUM      = 1;
--
        IF (ln_cnt = 0) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_mst_exist,
                                                gv_tkn_date_item,
                                                gv_arrival_time_to);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      -- �����敪�
      --�J�E���g�ϐ�������
      ln_cnt := 0; 
--
      SELECT  COUNT(1)
      INTO    ln_cnt
      FROM    xxcmn_lookup_values_v 
      WHERE   lookup_type = gv_lup_takeback_class
      AND     lookup_code = gt_takeback_class_tbl(gn_i)
      AND     ROWNUM      = 1;
--
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_mst_exist,
                                              gv_tkn_date_item,
                                              gv_takeback_class);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
-- 2008/07/17 v1.3 End
      -- ������R�[�h�
      BEGIN
        SELECT  xvv.vendor_id,                -- �d����ID
                xvv.customer_num,             -- �ڋq�ԍ�
                xcav.party_id,                -- �p�[�e�BID
                xvv.spare2,                   -- ���i�\
                xcav.cust_account_id          -- �ڋqID
        INTO    gt_vendor_id_tbl(gn_i),
                gt_customer_num_tbl(gn_i),
                gt_cust_party_id_tbl(gn_i),
                gt_spare2_tbl(gn_i),
                gt_cust_account_id_tbl(gn_i)
        FROM    xxcmn_vendors2_v        xvv,  -- �d������VIEW
                xxcmn_cust_accounts2_v  xcav  -- �ڋq���VIEW
        WHERE   xvv.segment1            =  gt_vendor_code_tbl(gn_i)
        AND     xvv.customer_num        =  xcav.account_number
        AND     xvv.start_date_active   <= gd_standard_date
        AND     xvv.end_date_active     >= gd_standard_date
        AND     xcav.start_date_active  <= gd_standard_date
        AND     xcav.end_date_active    >= gd_standard_date;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_exist,
                                                gv_tkn_table,
                                                cv_xvv);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      -- ��z����R�[�h�
      BEGIN
        SELECT  xvsv.vendor_site_id           -- �d����T�C�gID
        INTO    gt_vendor_site_id_tbl(gn_i)
        FROM    xxcmn_vendor_sites2_v   xvsv  -- �d����T�C�g���VIEW
        WHERE   xvsv.vendor_site_code   =  gt_ship_to_code_tbl(gn_i)
        AND     xvsv.vendor_id          =  gt_vendor_id_tbl(gn_i)
        AND     xvsv.start_date_active  <= gd_standard_date
        AND     xvsv.end_date_active    >= gd_standard_date;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_exist,
                                                gv_tkn_table,
                                                cv_xvsv);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      -- ��o�ɑq�ɃR�[�h�
      BEGIN
        SELECT  xilv.inventory_location_id,   -- �q��ID
                xilv.leaf_calender,           -- ���[�t��J�����_
                xilv.drink_calender           -- �h�����N��J�����_
        INTO    gt_inventory_location_id_tbl(gn_i),
                gt_leaf_calender_tbl(gn_i),
                gt_drink_calender_tbl(gn_i)
        FROM    xxcmn_item_locations2_v   xilv  -- OPM�ۊǏꏊ���VIEW
        WHERE   xilv.segment1             =  gt_shipped_locat_code_tbl(gn_i)
        AND     xilv.date_from            <= gd_standard_date
        AND     (
                  (xilv.date_to >= gd_standard_date)
                  OR
                  (xilv.date_to IS NULL)
                );
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_exist,
                                                gv_tkn_table,
                                                cv_xilv);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      -- ��^���Ǝ҃R�[�h�
      -- ���͂���Ă���ꍇ
      IF (gt_freight_carrier_code_tbl(gn_i) IS NOT NULL) THEN
        BEGIN
          SELECT  xcv.party_id                  -- �p�[�e�BID
          INTO    gt_carriers_party_id_tbl(gn_i)
          FROM    xxcmn_carriers2_v       xcv   -- �^���Ǝҏ��VIEW
          WHERE   xcv.party_number        =  gt_freight_carrier_code_tbl(gn_i)
          AND     xcv.start_date_active   <= gd_standard_date
          AND     xcv.end_date_active     >= gd_standard_date;
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                  gv_msg_exist,
                                                  gv_tkn_table,
                                                  cv_xcv);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
--
        END;
--
      END IF;
--
      -- ������i�ڃR�[�h�
      BEGIN
        SELECT  ximv.item_id                  -- �i��ID
        INTO    gt_h_item_id_tbl(gn_i)
        FROM    xxcmn_item_mst2_v       ximv  -- OPM�i�ڏ��VIEW
        WHERE   ximv.item_no            =  gt_producted_item_code_tbl(gn_i)
        AND     ximv.start_date_active  <= gd_standard_date
        AND     ximv.end_date_active    >= gd_standard_date;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_exist,
                                                gv_tkn_table,
                                                cv_ximv);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      ---------------------------------------------
      -- �݌ɉ�v���ԃN���[�Y�`�F�b�N            --
      ---------------------------------------------
      -- ���ʊ֐��OPM�݌ɉ�v����CLOSE�N���擾�֐���Ăяo��
      lv_close_period := xxcmn_common_pkg.get_opminv_close_period;
--
      -- ���ʊ֐��ŃG���[�̏ꍇ
      IF (lv_close_period IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_common,
                                              gv_tkn_common_name,
                                              gv_opminv_close);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- �o�ɓ����N���[�Y�����݌ɉ�v���ԔN���ȑO�̏ꍇ
      IF (TO_CHAR(gt_ship_date_tbl(gn_i), 'YYYYMM') <= lv_close_period) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_close_period);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- ���׍���
    ELSIF (iv_header_line_kbn = gv_line) THEN
      ---------------------------------------------
      -- ���׍��ڑ��݃`�F�b�N                    --
      ---------------------------------------------
-- 2008/07/17 v1.3 Start
      -- ��˗����ʣ
      -- �˗����ʂ�0�������̓}�C�i�X�l�̏ꍇ
      IF (gt_request_qty_tbl(gn_j) <= 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_request_qty);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
-- 2008/07/17 v1.3 End
      -- ��i�ڃR�[�h�
      BEGIN
        SELECT  ximv.item_id,                         -- �i��ID
                ximv.item_um,                         -- �P��
                ximv.num_of_deliver,                  -- �o�ד���
                ximv.conv_unit,                       -- ���o�Ɋ��Z�P��
                ximv.num_of_cases,                    -- �P�[�X����
                ximv.inventory_item_id,               -- INV�i��ID
                ximv.whse_item_id,                    -- �q�ɕi��ID
-- 2008/07/17 v1.3 Start
--                ximv.lot_ctl                          -- ���b�g
                ximv.lot_ctl,                         -- ���b�g
                ximv.weight_capacity_class            -- �d�ʗe�ϋ敪
-- 2008/07/17 v1.3 End
        INTO    gt_l_item_id_tbl(gn_j),
                gt_item_um_tbl(gn_j),
                gt_num_of_deliver_tbl(gn_j),
                gt_conv_unit_tbl(gn_j),
                gt_num_of_cases_tbl(gn_j),
                gt_inventory_item_id_tbl(gn_j),
                gt_whse_item_id_tbl(gn_j),
-- 2008/07/17 v1.3 Start
--                gt_lot_ctl_tbl(gn_j)
                gt_lot_ctl_tbl(gn_j),
                gt_l_weight_capacity_class(gn_j)
-- 2008/07/17 v1.3 End
        FROM    xxcmn_item_mst2_v       ximv
        WHERE   ximv.item_no            =  gt_item_code_tbl(gn_j)
        AND     ximv.start_date_active  <= gd_standard_date
        AND     ximv.end_date_active    >= gd_standard_date;
--
-- 2008/07/17 v1.3 Start
        -- �w�b�_�Ɩ��ׂ̏d�ʗe�ϋ敪���قȂ�ꍇ
        IF (gt_weight_capacity_class_tbl(gn_i) <> gt_l_weight_capacity_class(gn_j)) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_weight_capacity_agree);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
-- 2008/07/17 v1.3 End
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_exist,
                                                gv_tkn_table,
                                                cv_ximv);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      -- �q�ɕi��ID�ɕR�t���q�ɕi�ڃR�[�h���擾
      BEGIN
        SELECT  ximv.item_no                          -- �q�ɕi�ڃR�[�h
        INTO    gt_item_no_tbl(gn_j)
        FROM    xxcmn_item_mst2_v       ximv
        WHERE   ximv.item_id            =  gt_whse_item_id_tbl(gn_j)
        AND     ximv.start_date_active  <= gd_standard_date
        AND     ximv.end_date_active    >= gd_standard_date;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_exist,
                                                gv_tkn_table,
                                                cv_ximv);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      ---------------------------------------------
      -- �i�ڏd���`�F�b�N                        --
      ---------------------------------------------
      -- �i�ڂ��A1�w�b�_�ɕR�t���O���ׂ̕i�ڂƏd������ꍇ
      IF (gv_before_item_no IS NOT NULL) THEN
        IF (gv_before_item_no = gt_item_code_tbl(gn_j)) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_redundant);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        END IF;
--
      ELSE
        gv_before_item_no := gt_item_code_tbl(gn_j);
--
      END IF;
--
      ---------------------------------------------
      -- �d���L�����i�ڃ`�F�b�N                  --
      ---------------------------------------------
      -- �����敪����d���L����̏ꍇ
      IF (
           (gt_trans_type_tbl(gn_i) = cv_trans_pay) AND
           (NVL(gt_lot_ctl_tbl(gn_j), 0) = cn_lot_ctl)
         ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_trans_type);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      END IF;
--
    END IF;
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
  END chk_exist_mst_proc;
--
  /**********************************************************************************
   * Procedure Name   : get_relation_proc
   * Description      : �֘A�f�[�^�擾���� (F-6)
   ***********************************************************************************/
  PROCEDURE get_relation_proc(
    iv_header_line_kbn  IN         VARCHAR2,      --   �w�b�_���׋敪
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_relation_proc'; -- �v���O������
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
    cv_wh         CONSTANT VARCHAR2(2) := '4';   -- �q��
    cv_sup        CONSTANT VARCHAR2(2) := '11';  -- �x����
    cv_request_no CONSTANT VARCHAR2(1) := '6';   -- �o�׈˗�No
    cn_lead_time  CONSTANT NUMBER      := 1;     -- ���[�h�^�C��
--
    -- *** ���[�J���ϐ� ***
    ln_result             NUMBER;               -- �u�ő�z���敪�Z�o�֐��v�Ԃ�l
    ln_unit_price         NUMBER;               -- �u�x���P���擾�֐��v�Ԃ�l
    lv_errmsg_code        VARCHAR2(5000);       -- �G���[���b�Z�[�W�R�[�h
    ln_small_quantity     NUMBER;               -- ������
-- 2008/07/17 v1.3 Start
    ld_oprtn_day          DATE;                 -- �ғ������t
    ln_return             NUMBER;               -- �u�ғ����Z�o�֐��v�Ԃ�l
-- 2008/07/17 v1.3 End
    -- ���g�p
    ln_palette_max_qty    NUMBER;               -- �p���b�g�ő喇��
    ln_sum_pallet_weight  NUMBER;               -- ���v�p���b�g�d��
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���[�J���ϐ��̏�����
    ln_result         := NULL;
    ln_unit_price     := NULL;
    lv_retcode        := NULL;
    lv_errmsg_code    := NULL;
    lv_errmsg         := NULL;
    ln_small_quantity := NULL;
--
    -- �w�b�_����
    IF (iv_header_line_kbn = gv_header) THEN
      ---------------------------------------------
      -- �ő�z���敪�擾                        --
      ---------------------------------------------
      -- �^���敪����Ώۣ�̏ꍇ
      IF (gt_freight_charge_class_tbl(gn_i) = gv_object) THEN
        -- ���ʊ֐��u�ő�z���敪�Z�o�֐��v�Ăяo��
        ln_result := xxwsh_common_pkg.get_max_ship_method
                               (cv_wh,                                      -- �q��'4'
                                gt_shipped_locat_code_tbl(gn_i),            -- �o�ɑq�ɃR�[�h
                                cv_sup,                                     -- �x����'11'
                                gt_ship_to_code_tbl(gn_i),                  -- �z����R�[�h
                                gv_item_div_prf,                            -- ���i�敪
                                gt_weight_capacity_class_tbl(gn_i),         -- �d�ʗe�ϋ敪
                                NULL,                                       -- �����z�ԑΏۋ敪
                                gd_standard_date,                           -- �o�ɓ�
                                gt_ship_method_tbl(gn_i),                   -- �ő�z���敪
                                gt_drink_deadweight_tbl(gn_i),              -- �h�����N�ύڏd��
                                gt_leaf_deadweight_tbl(gn_i),               -- ���[�t�ύڏd��
                                gt_drink_loading_capacity_tbl(gn_i),        -- �h�����N�ύڗe��
                                gt_leaf_loading_capacity_tbl(gn_i),         -- ���[�t�ύڗe��
                                ln_palette_max_qty                          -- �p���b�g�ő喇��
                               );
--
        -- ���ʊ֐��ŃG���[�̏ꍇ
        IF (ln_result = 1) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_common,
                                                gv_tkn_common_name,
                                                gv_max_ship);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      ELSE
        gt_ship_method_tbl(gn_i)              := NULL;
        gt_drink_deadweight_tbl(gn_i)         := NULL;
        gt_leaf_deadweight_tbl(gn_i)          := NULL;
        gt_drink_loading_capacity_tbl(gn_i)   := NULL;
        gt_leaf_loading_capacity_tbl(gn_i)    := NULL;
--
      END IF;
--
-- 2008/07/17 v1.3 Start
      ---------------------------------------------
      -- �o�ɓ��擾                              --
      ---------------------------------------------
      -- �o�ɓ��������͂̏ꍇ
      IF (gt_ship_date_tbl(gn_i) IS NULL) THEN
        -- ���ʊ֐��u�ғ����Z�o�֐��v�Ăяo��
        ln_return := xxwsh_common_pkg.get_oprtn_day
                      (gt_arvl_date_tbl(gn_i),          -- ���ɓ�
                       NULL,                            -- �ۊǑq�ɃR�[�h
                       gt_ship_to_code_tbl(gn_i),       -- �z����R�[�h
                       cn_lead_time,                    -- ���[�h�^�C���1�
                       gv_item_div_prf,                 -- ���i�敪
                       ld_oprtn_day                     -- �ғ������t
                      );
--
        -- ���ʊ֐��ŃG���[�̏ꍇ
        IF (ln_return = 1) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_common,
                                                gv_tkn_common_name,
                                                gv_oprtn_day);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
        -- �擾�������t���o�ד��Ƃ��ĕێ�
        gt_ship_date_tbl(gn_i) := ld_oprtn_day;
--
      -- �o�ɓ������͂���Ă���ꍇ
      ELSE
        -- �o�ɓ������ɓ������������̏ꍇ
        IF (gt_ship_date_tbl(gn_i) > gt_arvl_date_tbl(gn_i)) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_ship_date);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
-- 2008/07/17 v1.3 End
      ---------------------------------------------
      -- �˗�No�擾                              --
      ---------------------------------------------
      -- ���ʊ֐��u�̔Ԋ֐��v�Ăяo��
      xxcmn_common_pkg.get_seq_no
                        (cv_request_no,                 -- �̔Ԕԍ��敪
                         gt_seq_no_tbl(gn_i),           -- �o�׈˗�No
                         lv_errbuf,                     -- �G���[�E���b�Z�[�W
                         lv_retcode,                    -- ���^�[���E�R�[�h
                         lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W
                        );
--
      -- ���ʊ֐��ŃG���[�̏ꍇ
      IF (lv_retcode = '1') THEN
-- 2008/07/24 v1.4 Start
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_common,
                                              gv_tkn_common_name,
                                              gv_get_seq_no);
        lv_errbuf := lv_errmsg;
-- 2008/07/24 v1.4 End
        RAISE global_api_expt;
      END IF;
--
    -- ���׍���
    ELSIF (iv_header_line_kbn = gv_line) THEN
      ---------------------------------------------
      -- �P���擾                                --
      ---------------------------------------------
      -- ���ʊ֐��u�x���P���擾�֐��v�Ăяo��
      ln_unit_price  := xxpo_common2_pkg.get_unit_price
                               (gt_inventory_item_id_tbl(gn_j),     -- INV�i��ID
                                gt_spare2_tbl(gn_i),                -- �����ʉ��i�\ID
                                gv_price_list_prf,                  -- ��\���i�\ID
                                gt_arvl_date_tbl(gn_i)              -- �K�p��(���ɓ�)
                               );
--
      -- ���ʊ֐��ŃG���[�̏ꍇ
      IF (ln_unit_price IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_common,
                                              gv_tkn_common_name,
                                              gv_unit_price);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      ELSE
        gt_unit_price_tbl(gn_j) := ln_unit_price;
      END IF;
--
      ---------------------------------------------
      -- ���v�d�ʥ���v�e�ώ擾                   --
      ---------------------------------------------
      -- �u�ύڌ����`�F�b�N(���v�l�Z�o)�v�Ăяo��
      xxwsh_common910_pkg.calc_total_value
                            (
                             gt_item_code_tbl(gn_j),              -- �i�ڃR�[�h
                             gt_request_qty_tbl(gn_j),            -- �˗�����
                             lv_retcode,                          -- ���^�[���R�[�h
                             lv_errmsg_code,                      -- �G���[���b�Z�[�W�R�[�h
                             lv_errmsg,                           -- �G���[���b�Z�[�W
                             gt_l_sum_weight_tbl(gn_j),           -- ���v�d��
                             gt_l_sum_capacity_tbl(gn_j),         -- ���v�e��
                             ln_sum_pallet_weight                 -- ���v�p���b�g�d��
                            );
--
      -- ���ʊ֐��ŃG���[�̏ꍇ
      IF (lv_retcode = '1') THEN
-- 2008/07/24 v1.4 Start
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                              gv_msg_common,
                                              gv_tkn_common_name,
                                              gv_calc_total_value);
        lv_errbuf := lv_errmsg;
-- 2008/07/24 v1.4 End
        RAISE global_api_expt;
      END IF;
--
      -- �����v�d��
      gt_h_sum_weight_tbl(gn_i) :=
        NVL(gt_h_sum_weight_tbl(gn_i), 0) + gt_l_sum_weight_tbl(gn_j);
--
      -- �����v�e��
      gt_h_sum_capacity_tbl(gn_i) :=
        NVL(gt_h_sum_capacity_tbl(gn_i), 0) + gt_l_sum_capacity_tbl(gn_j);
--
      ---------------------------------------------
      -- �z�Ԋ֘A���̎Z�o                      --
      ---------------------------------------------
      -- ������
-- 2008/07/24 v1.4 Start
/*      -- ���o�Ɋ��Z�P�ʂ��ݒ肳��Ă��āA�P�[�X������NULL�Ⴕ����0�łȂ��ꍇ
      IF (
           (gt_conv_unit_tbl(gn_j) IS NOT NULL) AND
           (gt_num_of_cases_tbl(gn_j) IS NOT NULL) AND
           (gt_num_of_cases_tbl(gn_j) <> '0')
         ) THEN
        ln_small_quantity :=
          ROUND(TO_NUMBER(gt_request_qty_tbl(gn_j) / gt_num_of_cases_tbl(gn_j)));
      ELSE
        ln_small_quantity := gt_request_qty_tbl(gn_j);
      END IF;
*/--
      -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��ꍇ
      IF (gt_conv_unit_tbl(gn_j) IS NOT NULL) THEN
        -- �P�[�X���萔��0���傫���ꍇ
        IF (gt_num_of_cases_tbl(gn_j) > 0) THEN
          -- �P�[�X���萔�������������Z���s���B
          ln_small_quantity
            := CEIL(TO_NUMBER(gt_request_qty_tbl(gn_j) / gt_num_of_cases_tbl(gn_j)));
        ELSIF ((gt_num_of_cases_tbl(gn_j) = 0)
           OR (gt_num_of_cases_tbl(gn_j) IS NULL)) THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg  := SUBSTRB(
                          xxcmn_common_pkg.get_msg(
                            gv_msg_kbn_xxcmn    -- ���W���[��������:XXCMN
                           ,gv_msg_xxcmn10604   -- ���b�Z�[�W:APP-XXCMN-10604 �P�[�X�����G���[
                           ,gv_tkn_request_no
                           ,gt_seq_no_tbl(gn_i)
                           ,gv_tkn_item_no
                           ,gt_item_code_tbl(gn_j))
                           ,1,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      ELSE
        ln_small_quantity := gt_request_qty_tbl(gn_j);
      END IF;
-- 2008/07/24 v1.4 End
      gt_small_quantity_tbl(gn_i) :=
        NVL(gt_small_quantity_tbl(gn_i), 0) + ln_small_quantity;
--
      -- ���x������
      gt_label_quantity_tbl(gn_i) :=
       NVL(gt_label_quantity_tbl(gn_i), 0) + ln_small_quantity;
--
      -- ���v����
      gt_sum_quantity_tbl(gn_i) :=
       NVL(gt_sum_quantity_tbl(gn_i), 0) + gt_request_qty_tbl(gn_j);
--
    END IF;
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
  END get_relation_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_data_proc
   * Description      : �o�^�f�[�^�ݒ菈��
   ***********************************************************************************/
  PROCEDURE set_data_proc(
    iv_header_line_kbn  IN         VARCHAR2,      --   �w�b�_���׋敪
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_data_proc'; -- �v���O������
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
    cv_yes                CONSTANT VARCHAR2(1) := 'Y';      -- ON
    cv_no                 CONSTANT VARCHAR2(1) := 'N';      -- OFF
    cv_transaction_status CONSTANT VARCHAR2(2) := '06';     -- ���͊���
    cv_notif_status       CONSTANT VARCHAR2(2) := '10';     -- ���ʒm
-- 2008/07/17 v1.3 Start
--    cv_out_object         CONSTANT VARCHAR2(1) := '2';      -- �ΏۊO
-- 2008/07/17 v1.3 End

--
    -- *** ���[�J���ϐ� ***
    lv_trans_type          VARCHAR2(80);           -- �����敪��
    ln_transaction_type_id NUMBER;                 -- �󒍃^�C�vID
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���[�J���ϐ��̏�����
    lv_trans_type           := NULL;
    ln_transaction_type_id  := NULL;
--
    -- �w�b�_����
    IF (iv_header_line_kbn = gv_header) THEN
      ---------------------------------------------
      -- �w�b�_�ݒ�                              --
      ---------------------------------------------
      BEGIN
        -- �N�C�b�N�R�[�h��蔭���敪�����擾����B
        SELECT    xlvv.meaning
        INTO      lv_trans_type
        FROM      xxcmn_lookup_values2_v   xlvv
        WHERE     xlvv.lookup_type        = 'XXPO_TRANS_TYPE'
        AND       xlvv.lookup_code        = gt_trans_type_tbl(gn_i)
        AND       (
                    (xlvv.start_date_active <= TRUNC(gd_standard_date))
                    OR
                    (xlvv.start_date_active IS NULL )
                  )
        AND       (
                    (xlvv.end_date_active >= TRUNC(gd_standard_date))
                    OR
                    (xlvv.end_date_active IS NULL )
                  );
--
        -- �󒍃^�C�v���󒍃^�C�vID���擾����B
        SELECT    ottv.transaction_type_id
        INTO      ln_transaction_type_id
        FROM      xxwsh_oe_transaction_types2_v   ottv
        WHERE     ottv.transaction_type_name      =  lv_trans_type
        AND       ottv.start_date_active          <= TRUNC(gd_standard_date)
        AND       NVL(ottv.end_date_active, TO_DATE('99991231', 'YYYYMMDD')) >=
                    TRUNC(gd_standard_date);
--
      EXCEPTION
        -- �f�[�^�擾�G���[
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                                gv_msg_get_data);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      -- �󒍃w�b�_�A�h�I���e�[�u���֓o�^���郌�R�[�h�֒l���Z�b�g
      gt_ph_order_header_id_tbl(gn_i)               :=  gt_order_header_id_tbl(gn_i);
      gt_ph_order_type_id_tbl(gn_i)                 :=  ln_transaction_type_id;
      gt_ph_organization_id_tbl(gn_i)               :=  gv_master_org_prf;
      gt_ph_header_id_tbl(gn_i)                     :=  NULL;
      gt_ph_latest_external_flag_tbl(gn_i)          :=  cv_yes;
      gt_ph_ordered_date_tbl(gn_i)                  :=  gd_sysdate;
      gt_ph_customer_id_tbl(gn_i)                   :=  gt_cust_account_id_tbl(gn_i);
      gt_ph_customer_code_tbl(gn_i)                 :=  gt_customer_num_tbl(gn_i);
      gt_ph_deliver_to_id_tbl(gn_i)                 :=  NULL;
      gt_ph_deliver_to_tbl(gn_i)                    :=  NULL;
      gt_ph_shipping_inst_tbl(gn_i)                 :=  gt_header_description_tbl(gn_i);
      gt_ph_career_id_tbl(gn_i)                     :=  gt_carriers_party_id_tbl(gn_i);
      gt_ph_freight_carrier_code_tbl(gn_i)          :=  gt_freight_carrier_code_tbl(gn_i);
      gt_ph_shipping_method_code_tbl(gn_i)          :=  gt_ship_method_tbl(gn_i);
      gt_ph_cust_po_number_tbl(gn_i)                :=  NULL;
      gt_ph_price_list_id_tbl(gn_i)                 :=  NULL;
      gt_ph_request_no_tbl(gn_i)                    :=  gt_seq_no_tbl(gn_i);
      gt_ph_base_request_no_tbl(gn_i)               :=  NULL;
      gt_ph_req_status_tbl(gn_i)                    :=  cv_transaction_status;
      gt_ph_delivery_no_tbl(gn_i)                   :=  NULL;
      gt_ph_prev_delivery_no_tbl(gn_i)              :=  NULL;
      gt_ph_schedule_ship_date_tbl(gn_i)            :=  gt_ship_date_tbl(gn_i);
      gt_ph_schedule_arr_date_tbl(gn_i)             :=  gt_arvl_date_tbl(gn_i);
      gt_ph_mixed_no_tbl(gn_i)                      :=  NULL;
      gt_ph_collected_pallet_qty_tbl(gn_i)          :=  NULL;
      gt_ph_confirm_req_class_tbl(gn_i)             :=  NULL;
-- 2008/07/17 v1.3 Start
--      gt_ph_freight_charge_class_tbl(gn_i)          :=
--        NVL(gt_freight_charge_class_tbl(gn_i), cv_out_object);
      gt_ph_freight_charge_class_tbl(gn_i)          :=  gt_freight_charge_class_tbl(gn_i);
-- 2008/07/17 v1.3 End
      gt_ph_shikyu_inst_class_tbl(gn_i)             :=  NULL;
      gt_ph_sk_inst_rcv_class_tbl(gn_i)             :=  NULL;
      gt_ph_amount_fix_class_tbl(gn_i)              :=  NULL;
      gt_ph_takeback_class_tbl(gn_i)                :=  gt_takeback_class_tbl(gn_i);
      gt_ph_deliver_from_id_tbl(gn_i)               :=  gt_inventory_location_id_tbl(gn_i);
      gt_ph_deliver_from_tbl(gn_i)                  :=  gt_shipped_locat_code_tbl(gn_i);
      gt_ph_head_sales_branch_tbl(gn_i)             :=  NULL;
      gt_ph_input_sales_branch_tbl(gn_i)            :=  NULL;
      gt_ph_po_no_tbl(gn_i)                         :=  NULL;
      gt_ph_prod_class_tbl(gn_i)                    :=  gv_item_div_prf;
      gt_ph_item_class_tbl(gn_i)                    :=  NULL;
      gt_ph_no_cont_fre_class_tbl(gn_i)             :=  NULL;
      gt_ph_arrival_time_from_tbl(gn_i)             :=  gt_arrival_time_from_tbl(gn_i);
      gt_ph_arrival_time_to_tbl(gn_i)               :=  gt_arrival_time_to_tbl(gn_i);
      gt_ph_designated_item_id_tbl(gn_i)            :=  gt_h_item_id_tbl(gn_i);
      gt_ph_designated_item_code_tbl(gn_i)          :=  gt_producted_item_code_tbl(gn_i);
      gt_ph_designated_prod_date_tbl(gn_i)          :=  gt_product_date_tbl(gn_i);
      gt_ph_designated_branch_no_tbl(gn_i)          :=  gt_product_number_tbl(gn_i);
      gt_ph_slip_number_tbl(gn_i)                   :=  NULL;
      gt_ph_sum_quantity_tbl(gn_i)                  :=  gt_sum_quantity_tbl(gn_i);
      gt_ph_small_quantity_tbl(gn_i)                :=  gt_small_quantity_tbl(gn_i);
      gt_ph_label_quantity_tbl(gn_i)                :=  gt_label_quantity_tbl(gn_i);
      gt_ph_load_efficiency_we_tbl(gn_i)            :=  gt_load_efficiency_we_tbl(gn_i);
      gt_ph_load_efficiency_ca_tbl(gn_i)            :=  gt_load_efficiency_ca_tbl(gn_i);
      -- �d�ʗe�ϋ敪����d�ʣ�̏ꍇ
      IF (gt_weight_capacity_class_tbl(gn_i) = gv_we) THEN
        -- ���i�敪����h�����N��̏ꍇ
        IF (gv_item_div_prf = gv_drink) THEN
          gt_ph_based_weight_tbl(gn_i)              :=  gt_drink_deadweight_tbl(gn_i);
          gt_ph_based_capacity_tbl(gn_i)            :=  NULL;
        -- ���i�敪������[�t��̏ꍇ
        ELSIF (gv_item_div_prf = gv_leaf) THEN
          gt_ph_based_weight_tbl(gn_i)              :=  gt_leaf_deadweight_tbl(gn_i);
          gt_ph_based_capacity_tbl(gn_i)            :=  NULL;
        END IF;
      -- �d�ʗe�ϋ敪����e�ϣ�̏ꍇ
      ELSIF (gt_weight_capacity_class_tbl(gn_i) = gv_ca) THEN
        -- ���i�敪����h�����N��̏ꍇ
        IF (gv_item_div_prf = gv_drink) THEN
          gt_ph_based_weight_tbl(gn_i)              :=  NULL;
          gt_ph_based_capacity_tbl(gn_i)            :=  gt_drink_loading_capacity_tbl(gn_i);
        -- ���i�敪������[�t��̏ꍇ
        ELSIF (gv_item_div_prf = gv_leaf) THEN
          gt_ph_based_weight_tbl(gn_i)              :=  NULL;
          gt_ph_based_capacity_tbl(gn_i)            :=  gt_leaf_loading_capacity_tbl(gn_i);
        END IF;
      END IF;
      gt_ph_sum_weight_tbl(gn_i)                    :=  gt_drink_deadweight_tbl(gn_i);
      gt_ph_sum_capacity_tbl(gn_i)                  :=  gt_h_sum_capacity_tbl(gn_i);
      gt_ph_mixed_ratio_tbl(gn_i)                   :=  NULL;
      gt_ph_pallet_sum_quantity_tbl(gn_i)           :=  NULL;
      gt_ph_real_pallet_quantity_tbl(gn_i)          :=  NULL;
      gt_ph_sum_pallet_weight_tbl(gn_i)             :=  NULL;
      gt_ph_order_source_ref_tbl(gn_i)              :=  NULL;
      gt_ph_result_fre_carr_id_tbl(gn_i)            :=  NULL;
      gt_ph_result_fre_carr_code_tbl(gn_i)          :=  NULL;
      gt_ph_res_ship_meth_code_tbl(gn_i)            :=  NULL;
      gt_ph_result_deliver_to_id_tbl(gn_i)          :=  NULL;
      gt_ph_result_deliver_to_tbl(gn_i)             :=  NULL;
      gt_ph_shipped_date_tbl(gn_i)                  :=  NULL;
      gt_ph_arrival_date_tbl(gn_i)                  :=  NULL;
      gt_ph_weight_ca_class_tbl(gn_i)               :=  gt_weight_capacity_class_tbl(gn_i);
      gt_ph_actual_confirm_class_tbl(gn_i)          :=  NULL;
      gt_ph_notif_status_tbl(gn_i)                  :=  cv_notif_status;
      gt_ph_prev_notif_status_tbl(gn_i)             :=  NULL;
      gt_ph_notif_date_tbl(gn_i)                    :=  NULL;
      gt_ph_new_modify_flg_tbl(gn_i)                :=  NULL;
      gt_ph_process_status_tbl(gn_i)                :=  NULL;
      gt_ph_perform_manage_dept_tbl(gn_i)           :=  gt_req_department_code_tbl(gn_i);
      gt_ph_instruction_dept_tbl(gn_i)              :=
        NVL(gt_instruction_post_code_tbl(gn_i), gt_req_department_code_tbl(gn_i));
      gt_ph_transfer_location_id_tbl(gn_i)          :=  NULL;
      gt_ph_trans_location_code_tbl(gn_i)           :=  NULL;
      gt_ph_mixed_sign_tbl(gn_i)                    :=  NULL;
      gt_ph_screen_update_date_tbl(gn_i)            :=  NULL;
      gt_ph_screen_update_by_tbl(gn_i)              :=  NULL;
      gt_ph_tightening_date_tbl(gn_i)               :=  NULL;
      gt_ph_vendor_id_tbl(gn_i)                     :=  gt_vendor_id_tbl(gn_i);
      gt_ph_vendor_code_tbl(gn_i)                   :=  gt_vendor_code_tbl(gn_i);
      gt_ph_vendor_site_id_tbl(gn_i)                :=  gt_vendor_site_id_tbl(gn_i);
      gt_ph_vendor_site_code_tbl(gn_i)              :=  gt_ship_to_code_tbl(gn_i);
      gt_ph_registered_sequence_tbl(gn_i)           :=  NULL;
      gt_ph_tight_program_id_tbl(gn_i)              :=  NULL;
      gt_ph_correct_tight_class_tbl(gn_i)           :=  NULL;
      gt_ph_created_by_tbl(gn_i)                    :=  gn_user_id;
      gt_ph_creation_date_tbl(gn_i)                 :=  gd_sysdate;
      gt_ph_last_updated_by_tbl(gn_i)               :=  gn_user_id;
      gt_ph_last_update_date_tbl(gn_i)              :=  gd_sysdate;
      gt_ph_last_update_login_tbl(gn_i)             :=  gn_login_id;
      gt_ph_request_id_tbl(gn_i)                    :=  gn_conc_request_id;
      gt_ph_program_appli_id_tbl(gn_i)              :=  gn_prog_appl_id;
      gt_ph_program_id_tbl(gn_i)                    :=  gn_conc_program_id;
      gt_ph_program_up_date_tbl(gn_i)               :=  gd_sysdate;
--
    -- ���׍���
    ELSIF (iv_header_line_kbn = gv_line) THEN
      ---------------------------------------------
      -- ���אݒ�                                --
      ---------------------------------------------
      -- �󒍖��׃A�h�I���e�[�u���֓o�^���郌�R�[�h�֒l���Z�b�g
      gt_pl_order_line_id_tbl(gn_j)                 :=  gt_order_line_id_tbl(gn_j);
      gt_pl_order_header_id_tbl(gn_j)               :=  gt_order_header_id_tbl(gn_i);
      gt_pl_order_line_number_tbl(gn_j)             :=  gt_line_number_tbl(gn_j);
      gt_pl_header_id_tbl(gn_j)                     :=  NULL;
      gt_pl_line_id_tbl(gn_j)                       :=  NULL;
      gt_pl_request_no_tbl(gn_j)                    :=  gt_seq_no_tbl(gn_i);
      gt_pl_ship_inv_item_id_tbl(gn_j)              :=  gt_l_item_id_tbl(gn_j);
      gt_pl_shipping_item_code_tbl(gn_j)            :=  gt_item_code_tbl(gn_j);
      gt_pl_quantity_tbl(gn_j)                      :=  gt_request_qty_tbl(gn_j);
      gt_pl_uom_code_tbl(gn_j)                      :=  gt_item_um_tbl(gn_j);
      gt_pl_unit_price_tbl(gn_j)                    :=  gt_unit_price_tbl(gn_j);
      gt_pl_shipped_quantity_tbl(gn_j)              :=  NULL;
      gt_pl_design_prod_date_tbl(gn_j)              :=  NULL;
      gt_pl_based_req_quan_tbl(gn_j)                :=  gt_request_qty_tbl(gn_j);
      gt_pl_request_item_id_tbl(gn_j)               :=  gt_whse_item_id_tbl(gn_j);
      gt_pl_request_item_code_tbl(gn_j)             :=  gt_item_no_tbl(gn_j);
      gt_pl_ship_to_quantity_tbl(gn_j)              :=  NULL;
      gt_pl_futai_code_tbl(gn_j)                    :=  NVL(gt_futai_code_tbl(gn_j), '0');
      gt_pl_designated_date_tbl(gn_j)               :=  NULL;
      gt_pl_move_number_tbl(gn_j)                   :=  NULL;
      gt_pl_po_number_tbl(gn_j)                     :=  NULL;
      gt_pl_cust_po_number_tbl(gn_j)                :=  NULL;
      gt_pl_pallet_quantity_tbl(gn_j)               :=  NULL;
      gt_pl_layer_quantity_tbl(gn_j)                :=  NULL;
      gt_pl_case_quantity_tbl(gn_j)                 :=  NULL;
      gt_pl_weight_tbl(gn_j)                        :=  gt_l_sum_weight_tbl(gn_j);
      gt_pl_capacity_tbl(gn_j)                      :=  gt_l_sum_capacity_tbl(gn_j);
      gt_pl_pallet_qty_tbl(gn_j)                    :=  NULL;
      gt_pl_pallet_weight_tbl(gn_j)                 :=  NULL;
      gt_pl_reserved_quantity_tbl(gn_j)             :=  NULL;
      gt_pl_auto_res_class_tbl(gn_j)                :=  NULL;
      gt_pl_delete_flag_tbl(gn_j)                   :=  cv_no;
      gt_pl_warning_class_tbl(gn_j)                 :=  NULL;
      gt_pl_warning_date_tbl(gn_j)                  :=  NULL;
      gt_pl_line_description_tbl(gn_j)              :=  gt_line_description_tbl(gn_j);
      gt_pl_rm_if_flg_tbl(gn_j)                     :=  NULL;
      gt_pl_ship_req_if_flg_tbl(gn_j)               :=  NULL;
      gt_pl_ship_res_if_flg_tbl(gn_j)               :=  NULL;
      gt_pl_created_by_tbl(gn_j)                    :=  gn_user_id;
      gt_pl_creation_date_tbl(gn_j)                 :=  gd_sysdate;
      gt_pl_last_updated_by_tbl(gn_j)               :=  gn_user_id;
      gt_pl_last_update_date_tbl(gn_j)              :=  gd_sysdate;
      gt_pl_last_update_login_tbl(gn_j)             :=  gn_login_id;
      gt_pl_request_id_tbl(gn_j)                    :=  gn_conc_request_id;
      gt_pl_program_appli_id_tbl(gn_j)              :=  gn_prog_appl_id;
      gt_pl_program_id_tbl(gn_j)                    :=  gn_conc_program_id;
      gt_pl_program_update_date_tbl(gn_j)           :=  gd_sysdate;
--
    END IF;
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
  END set_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : calc_load_efficiency_proc
   * Description      : �ύڌ����Z�o
   ***********************************************************************************/
  PROCEDURE calc_load_efficiency_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_load_efficiency_proc'; -- �v���O������
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
    cv_wh         CONSTANT VARCHAR2(2) := '4';   -- �q��
    cv_sup        CONSTANT VARCHAR2(2) := '11';  -- �x����
    cv_request_no CONSTANT VARCHAR2(1) := '6';   -- �o�׈˗�No
--
    -- *** ���[�J���ϐ� ***
    lv_errmsg_code        VARCHAR2(5000);       -- �G���[���b�Z�[�W�R�[�h
    lv_loading_over_class VARCHAR2(100);        -- �ύڃI�[�o�[�敪
    -- ���g�p
    lv_ship_methods       VARCHAR2(100);        -- �o�ו��@
    lv_mixed_ship_method  VARCHAR2(100);        -- ���ڔz���敪
-- 2008/07/24 v1.4 Start
    lv_load_efficiency_we VARCHAR2(100);        -- �d�ʐύڌ���
    lv_load_efficiency_ca VARCHAR2(100);        -- �e�ϐύڌ���
-- 2008/07/17 v1.3 End
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
-- 2008/07/24 v1.4 Start
/*    -- �d�ʂ̐ύڌ������擾����
    IF (gt_weight_capacity_class_tbl(gn_i) = gv_we) THEN
      -- �u�ύڌ����`�F�b�N(�ύڌ����Z�o)�v�Ăяo��
      xxwsh_common910_pkg.calc_load_efficiency
                          (
                            gt_h_sum_weight_tbl(gn_i),              -- ���v�d��
                            NULL,                                   -- ���v�e��
                            cv_wh,                                  -- �q��'4'
                            gt_shipped_locat_code_tbl(gn_i),        -- �o�ɑq�ɃR�[�h
                            cv_sup,                                 -- �x����'11'
                            gt_ship_to_code_tbl(gn_i),              -- �z����R�[�h
                            gt_ship_method_tbl(gn_i),               -- �z���敪
                            gv_item_div_prf,                        -- ���i�敪
                            NULL,                                   -- �����z�ԑΏۋ敪
                            gd_standard_date,                       -- ���
                            lv_retcode,                             -- ���^�[���R�[�h
                            lv_errmsg_code,                         -- �G���[���b�Z�[�W�R�[�h
                            lv_errmsg,                              -- �G���[���b�Z�[�W
                            lv_loading_over_class,                  -- �ύڃI�[�o�[�敪
                            lv_ship_methods,                        -- �o�ו��@
                            gt_load_efficiency_we_tbl(gn_i),        -- �d�ʐύڌ���
                            gt_load_efficiency_ca_tbl(gn_i),        -- �e�ϐύڌ���
                            lv_mixed_ship_method                    -- ���ڔz���敪
                          );
--
      -- ���ʊ֐��ŃG���[�̏ꍇ
      IF (lv_retcode = '1') THEN
        RAISE global_api_expt;
      END IF;
--
    -- �e�ς̐ύڌ������擾����
    ELSIF (gt_weight_capacity_class_tbl(gn_i) = gv_ca) THEN
      -- �u�ύڌ����`�F�b�N(�ύڌ����Z�o)�v�Ăяo��
      xxwsh_common910_pkg.calc_load_efficiency
                          (
                            NULL,                                   -- ���v�d��
                            gt_h_sum_capacity_tbl(gn_i),            -- ���v�e��
                            cv_wh,                                  -- �q��'4'
                            gt_shipped_locat_code_tbl(gn_i),        -- �o�ɑq�ɃR�[�h
                            cv_sup,                                 -- �x����'11'
                            gt_ship_to_code_tbl(gn_i),              -- �z����R�[�h
                            gt_ship_method_tbl(gn_i),               -- �z���敪
                            gv_item_div_prf,                        -- ���i�敪
                            NULL,                                   -- �����z�ԑΏۋ敪
                            gd_standard_date,                       -- ���
                            lv_retcode,                             -- ���^�[���R�[�h
                            lv_errmsg_code,                         -- �G���[���b�Z�[�W�R�[�h
                            lv_errmsg,                              -- �G���[���b�Z�[�W
                            lv_loading_over_class,                  -- �ύڃI�[�o�[�敪
                            lv_ship_methods,                        -- �o�ו��@
                            gt_load_efficiency_we_tbl(gn_i),        -- �d�ʐύڌ���
                            gt_load_efficiency_ca_tbl(gn_i),        -- �e�ϐύڌ���
                            lv_mixed_ship_method                    -- ���ڔz���敪
                          );
--
      -- ���ʊ֐��ŃG���[�̏ꍇ
      IF (lv_retcode = '1') THEN
        RAISE global_api_expt;
      END IF;
--
    END IF;
*/--
    -- �d�ʂ̐ύڌ������`�F�b�N����
    IF (gt_weight_capacity_class_tbl(gn_i) = gv_we) THEN
      -- �u�ύڌ����`�F�b�N(�ύڌ����Z�o)�v�Ăяo��
      xxwsh_common910_pkg.calc_load_efficiency
                          (
                            gt_h_sum_weight_tbl(gn_i),              -- ���v�d��
                            NULL,                                   -- ���v�e��
                            cv_wh,                                  -- �q��'4'
                            gt_shipped_locat_code_tbl(gn_i),        -- �o�ɑq�ɃR�[�h
                            cv_sup,                                 -- �x����'11'
                            gt_ship_to_code_tbl(gn_i),              -- �z����R�[�h
                            gt_ship_method_tbl(gn_i),               -- �z���敪
                            gv_item_div_prf,                        -- ���i�敪
                            NULL,                                   -- �����z�ԑΏۋ敪
                            gd_standard_date,                       -- ���
                            lv_retcode,                             -- ���^�[���R�[�h
                            lv_errmsg_code,                         -- �G���[���b�Z�[�W�R�[�h
                            lv_errmsg,                              -- �G���[���b�Z�[�W
                            lv_loading_over_class,                  -- �ύڃI�[�o�[�敪
                            lv_ship_methods,                        -- �o�ו��@
                            lv_load_efficiency_we,                  -- �d�ʐύڌ���
                            lv_load_efficiency_ca,                  -- �e�ϐύڌ���
                            lv_mixed_ship_method                    -- ���ڔz���敪
                          );
--
      -- ���ʊ֐��ŃG���[�̏ꍇ
      IF (lv_retcode = '1') THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_msg_kbn_xxpo            -- ���W���[��������:XXPO
                          ,gv_msg_common             -- ���b�Z�[�W:APP-XXPO-10237 ���ʊ֐��G���[
                          ,gv_tkn_common_name        -- �g�[�N��NG_NAME
                          ,gv_tkn_calc_load_ef_we)   -- �ύڌ����`�F�b�N(�ύڌ����Z�o:�d��)
                          ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- �ύڃI�[�o�[�̏ꍇ
      IF (lv_loading_over_class = '1') THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_msg_kbn_xxpo      -- ���W���[��������:XXPO
                        ,gv_msg_xxpo10120)     -- ���b�Z�[�W:APP-XXPO-10120 �ύڌ����`�F�b�N�G���[
                        ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    -- �e�ς̐ύڌ������`�F�b�N����
    ELSIF (gt_weight_capacity_class_tbl(gn_i) = gv_ca) THEN
      -- �u�ύڌ����`�F�b�N(�ύڌ����Z�o)�v�Ăяo��
      xxwsh_common910_pkg.calc_load_efficiency
                          (
                            NULL,                                   -- ���v�d��
                            gt_h_sum_capacity_tbl(gn_i),            -- ���v�e��
                            cv_wh,                                  -- �q��'4'
                            gt_shipped_locat_code_tbl(gn_i),        -- �o�ɑq�ɃR�[�h
                            cv_sup,                                 -- �x����'11'
                            gt_ship_to_code_tbl(gn_i),              -- �z����R�[�h
                            gt_ship_method_tbl(gn_i),               -- �z���敪
                            gv_item_div_prf,                        -- ���i�敪
                            NULL,                                   -- �����z�ԑΏۋ敪
                            gd_standard_date,                       -- ���
                            lv_retcode,                             -- ���^�[���R�[�h
                            lv_errmsg_code,                         -- �G���[���b�Z�[�W�R�[�h
                            lv_errmsg,                              -- �G���[���b�Z�[�W
                            lv_loading_over_class,                  -- �ύڃI�[�o�[�敪
                            lv_ship_methods,                        -- �o�ו��@
                            lv_load_efficiency_we,                  -- �d�ʐύڌ���
                            lv_load_efficiency_ca,                  -- �e�ϐύڌ���
                            lv_mixed_ship_method                    -- ���ڔz���敪
                          );
--
      -- ���ʊ֐��ŃG���[�̏ꍇ
      IF (lv_retcode = '1') THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_msg_kbn_xxpo            -- ���W���[��������:XXPO
                          ,gv_msg_common             -- ���b�Z�[�W:APP-XXPO-10237 ���ʊ֐��G���[
                          ,gv_tkn_common_name        -- �g�[�N��NG_NAME
                          ,gv_tkn_calc_load_ef_ca)   -- �ύڌ����`�F�b�N(�ύڌ����Z�o:�d��)
                          ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- �ύڃI�[�o�[�̏ꍇ
      IF (lv_loading_over_class = '1') THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_msg_kbn_xxpo      -- ���W���[��������:XXPO
                        ,gv_msg_xxpo10120)     -- ���b�Z�[�W:APP-XXPO-10120 �ύڌ����`�F�b�N�G���[
                        ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    -- �d�ʂ̐ύڌ������擾����
    -- �u�ύڌ����`�F�b�N(�ύڌ����Z�o)�v�Ăяo��
    xxwsh_common910_pkg.calc_load_efficiency
                        (
                          gt_h_sum_weight_tbl(gn_i),              -- ���v�d��
                          NULL,                                   -- ���v�e��
                          cv_wh,                                  -- �q��'4'
                          gt_shipped_locat_code_tbl(gn_i),        -- �o�ɑq�ɃR�[�h
                          cv_sup,                                 -- �x����'11'
                          gt_ship_to_code_tbl(gn_i),              -- �z����R�[�h
                          gt_ship_method_tbl(gn_i),               -- �z���敪
                          gv_item_div_prf,                        -- ���i�敪
                          NULL,                                   -- �����z�ԑΏۋ敪
                          gd_standard_date,                       -- ���
                          lv_retcode,                             -- ���^�[���R�[�h
                          lv_errmsg_code,                         -- �G���[���b�Z�[�W�R�[�h
                          lv_errmsg,                              -- �G���[���b�Z�[�W
                          lv_loading_over_class,                  -- �ύڃI�[�o�[�敪
                          lv_ship_methods,                        -- �o�ו��@
                          gt_load_efficiency_we_tbl(gn_i),        -- �d�ʐύڌ���
                          lv_load_efficiency_ca,                  -- �e�ϐύڌ���
                          lv_mixed_ship_method                    -- ���ڔz���敪
                        );
--
    -- ���ʊ֐��ŃG���[�̏ꍇ
    IF (lv_retcode = '1') THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_msg_kbn_xxpo            -- ���W���[��������:XXPO
                        ,gv_msg_common             -- ���b�Z�[�W:APP-XXPO-10237 ���ʊ֐��G���[
                        ,gv_tkn_common_name        -- �g�[�N��NG_NAME
                        ,gv_tkn_calc_load_ef_we)   -- �ύڌ����`�F�b�N(�ύڌ����Z�o:�d��)
                        ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �e�ς̐ύڌ������擾����
    -- �u�ύڌ����`�F�b�N(�ύڌ����Z�o)�v�Ăяo��
    xxwsh_common910_pkg.calc_load_efficiency
                        (
                          NULL,                                   -- ���v�d��
                          gt_h_sum_capacity_tbl(gn_i),            -- ���v�e��
                          cv_wh,                                  -- �q��'4'
                          gt_shipped_locat_code_tbl(gn_i),        -- �o�ɑq�ɃR�[�h
                          cv_sup,                                 -- �x����'11'
                          gt_ship_to_code_tbl(gn_i),              -- �z����R�[�h
                          gt_ship_method_tbl(gn_i),               -- �z���敪
                          gv_item_div_prf,                        -- ���i�敪
                          NULL,                                   -- �����z�ԑΏۋ敪
                          gd_standard_date,                       -- ���
                          lv_retcode,                             -- ���^�[���R�[�h
                          lv_errmsg_code,                         -- �G���[���b�Z�[�W�R�[�h
                          lv_errmsg,                              -- �G���[���b�Z�[�W
                          lv_loading_over_class,                  -- �ύڃI�[�o�[�敪
                          lv_ship_methods,                        -- �o�ו��@
                          lv_load_efficiency_we,                  -- �d�ʐύڌ���
                          gt_load_efficiency_ca_tbl(gn_i),        -- �e�ϐύڌ���
                          lv_mixed_ship_method                    -- ���ڔz���敪
                        );
--
    -- ���ʊ֐��ŃG���[�̏ꍇ
    IF (lv_retcode = '1') THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_msg_kbn_xxpo            -- ���W���[��������:XXPO
                        ,gv_msg_common             -- ���b�Z�[�W:APP-XXPO-10237 ���ʊ֐��G���[
                        ,gv_tkn_common_name        -- �g�[�N��NG_NAME
                        ,gv_tkn_calc_load_ef_ca)   -- �ύڌ����`�F�b�N(�ύڌ����Z�o:�d��)
                        ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2008/07/17 v1.3 End
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
  END calc_load_efficiency_proc;
--
  /**********************************************************************************
   * Procedure Name   : put_header_proc
   * Description      : �󒍃w�b�_�A�h�I���o�^���� (F-7)
   ***********************************************************************************/
  PROCEDURE put_header_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_header_proc'; -- �v���O������
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
    ln_h_cont   NUMBER;         -- �w�b�_�J�E���g�ϐ�
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    FORALL ln_h_cont IN gt_ph_order_header_id_tbl.FIRST .. gt_ph_order_header_id_tbl.LAST
      INSERT INTO xxwsh_order_headers_all
                 (order_header_id,
                  order_type_id,
                  organization_id,
                  header_id,
                  latest_external_flag,
                  ordered_date,
                  customer_id,
                  customer_code,
                  deliver_to_id,
                  deliver_to,
                  shipping_instructions,
                  career_id,
                  freight_carrier_code,
                  shipping_method_code,
                  cust_po_number,
                  price_list_id,
                  request_no,
                  base_request_no,
                  req_status,
                  delivery_no,
                  prev_delivery_no,
                  schedule_ship_date,
                  schedule_arrival_date,
                  mixed_no,
                  collected_pallet_qty,
                  confirm_request_class,
                  freight_charge_class,
                  shikyu_instruction_class,
                  shikyu_inst_rcv_class,
                  amount_fix_class,
                  takeback_class,
                  deliver_from_id,
                  deliver_from,
                  head_sales_branch,
                  input_sales_branch,
                  po_no,
                  prod_class,
                  item_class,
                  no_cont_freight_class,
                  arrival_time_from,
                  arrival_time_to,
                  designated_item_id,
                  designated_item_code,
                  designated_production_date,
                  designated_branch_no,
                  slip_number,
                  sum_quantity,
                  small_quantity,
                  label_quantity,
                  loading_efficiency_weight,
                  loading_efficiency_capacity,
                  based_weight,
                  based_capacity,
                  sum_weight,
                  sum_capacity,
                  mixed_ratio,
                  pallet_sum_quantity,
                  real_pallet_quantity,
                  sum_pallet_weight,
                  order_source_ref,
                  result_freight_carrier_id,
                  result_freight_carrier_code,
                  result_shipping_method_code,
                  result_deliver_to_id,
                  result_deliver_to,
                  shipped_date,
                  arrival_date,
                  weight_capacity_class,
                  actual_confirm_class,
                  notif_status,
                  prev_notif_status,
                  notif_date,
                  new_modify_flg,
                  process_status,
                  performance_management_dept,
                  instruction_dept,
                  transfer_location_id,
                  transfer_location_code,
                  mixed_sign,
                  screen_update_date,
                  screen_update_by,
                  tightening_date,
                  vendor_id,
                  vendor_code,
                  vendor_site_id,
                  vendor_site_code,
                  registered_sequence,
                  tightening_program_id,
                  corrected_tighten_class,
                  created_by,
                  creation_date,
                  last_updated_by,
                  last_update_date,
                  last_update_login,
                  request_id,
                  program_application_id,
                  program_id,
                  program_update_date)
      VALUES     (gt_ph_order_header_id_tbl(ln_h_cont),
                  gt_ph_order_type_id_tbl(ln_h_cont),
                  gt_ph_organization_id_tbl(ln_h_cont),
                  gt_ph_header_id_tbl(ln_h_cont),
                  gt_ph_latest_external_flag_tbl(ln_h_cont),
                  gt_ph_ordered_date_tbl(ln_h_cont),
                  gt_ph_customer_id_tbl(ln_h_cont),
                  gt_ph_customer_code_tbl(ln_h_cont),
                  gt_ph_deliver_to_id_tbl(ln_h_cont),
                  gt_ph_deliver_to_tbl(ln_h_cont),
                  gt_ph_shipping_inst_tbl(ln_h_cont),
                  gt_ph_career_id_tbl(ln_h_cont),
                  gt_ph_freight_carrier_code_tbl(ln_h_cont),
                  gt_ph_shipping_method_code_tbl(ln_h_cont),
                  gt_ph_cust_po_number_tbl(ln_h_cont),
                  gt_ph_price_list_id_tbl(ln_h_cont),
                  gt_ph_request_no_tbl(ln_h_cont),
                  gt_ph_base_request_no_tbl(ln_h_cont),
                  gt_ph_req_status_tbl(ln_h_cont),
                  gt_ph_delivery_no_tbl(ln_h_cont),
                  gt_ph_prev_delivery_no_tbl(ln_h_cont),
                  gt_ph_schedule_ship_date_tbl(ln_h_cont),
                  gt_ph_schedule_arr_date_tbl(ln_h_cont),
                  gt_ph_mixed_no_tbl(ln_h_cont),
                  gt_ph_collected_pallet_qty_tbl(ln_h_cont),
                  gt_ph_confirm_req_class_tbl(ln_h_cont),
                  gt_ph_freight_charge_class_tbl(ln_h_cont),
                  gt_ph_shikyu_inst_class_tbl(ln_h_cont),
                  gt_ph_sk_inst_rcv_class_tbl(ln_h_cont),
                  gt_ph_amount_fix_class_tbl(ln_h_cont),
                  gt_ph_takeback_class_tbl(ln_h_cont),
                  gt_ph_deliver_from_id_tbl(ln_h_cont),
                  gt_ph_deliver_from_tbl(ln_h_cont),
                  gt_ph_head_sales_branch_tbl(ln_h_cont),
                  gt_ph_input_sales_branch_tbl(ln_h_cont),
                  gt_ph_po_no_tbl(ln_h_cont),
                  gt_ph_prod_class_tbl(ln_h_cont),
                  gt_ph_item_class_tbl(ln_h_cont),
                  gt_ph_no_cont_fre_class_tbl(ln_h_cont),
                  gt_ph_arrival_time_from_tbl(ln_h_cont),
                  gt_ph_arrival_time_to_tbl(ln_h_cont),
                  gt_ph_designated_item_id_tbl(ln_h_cont),
                  gt_ph_designated_item_code_tbl(ln_h_cont),
                  gt_ph_designated_prod_date_tbl(ln_h_cont),
                  gt_ph_designated_branch_no_tbl(ln_h_cont),
                  gt_ph_slip_number_tbl(ln_h_cont),
                  gt_ph_sum_quantity_tbl(ln_h_cont),
                  gt_ph_small_quantity_tbl(ln_h_cont),
                  gt_ph_label_quantity_tbl(ln_h_cont),
                  gt_ph_load_efficiency_we_tbl(ln_h_cont),
                  gt_ph_load_efficiency_ca_tbl(ln_h_cont),
                  gt_ph_based_weight_tbl(ln_h_cont),
                  gt_ph_based_capacity_tbl(ln_h_cont),
                  gt_ph_sum_weight_tbl(ln_h_cont),
                  gt_ph_sum_capacity_tbl(ln_h_cont),
                  gt_ph_mixed_ratio_tbl(ln_h_cont),
                  gt_ph_pallet_sum_quantity_tbl(ln_h_cont),
                  gt_ph_real_pallet_quantity_tbl(ln_h_cont),
                  gt_ph_sum_pallet_weight_tbl(ln_h_cont),
                  gt_ph_order_source_ref_tbl(ln_h_cont),
                  gt_ph_result_fre_carr_id_tbl(ln_h_cont),
                  gt_ph_result_fre_carr_code_tbl(ln_h_cont),
                  gt_ph_res_ship_meth_code_tbl(ln_h_cont),
                  gt_ph_result_deliver_to_id_tbl(ln_h_cont),
                  gt_ph_result_deliver_to_tbl(ln_h_cont),
                  gt_ph_shipped_date_tbl(ln_h_cont),
                  gt_ph_arrival_date_tbl(ln_h_cont),
                  gt_ph_weight_ca_class_tbl(ln_h_cont),
                  gt_ph_actual_confirm_class_tbl(ln_h_cont),
                  gt_ph_notif_status_tbl(ln_h_cont),
                  gt_ph_prev_notif_status_tbl(ln_h_cont),
                  gt_ph_notif_date_tbl(ln_h_cont),
                  gt_ph_new_modify_flg_tbl(ln_h_cont),
                  gt_ph_process_status_tbl(ln_h_cont),
                  gt_ph_perform_manage_dept_tbl(ln_h_cont),
                  gt_ph_instruction_dept_tbl(ln_h_cont),
                  gt_ph_transfer_location_id_tbl(ln_h_cont),
                  gt_ph_trans_location_code_tbl(ln_h_cont),
                  gt_ph_mixed_sign_tbl(ln_h_cont),
                  gt_ph_screen_update_date_tbl(ln_h_cont),
                  gt_ph_screen_update_by_tbl(ln_h_cont),
                  gt_ph_tightening_date_tbl(ln_h_cont),
                  gt_ph_vendor_id_tbl(ln_h_cont),
                  gt_ph_vendor_code_tbl(ln_h_cont),
                  gt_ph_vendor_site_id_tbl(ln_h_cont),
                  gt_ph_vendor_site_code_tbl(ln_h_cont),
                  gt_ph_registered_sequence_tbl(ln_h_cont),
                  gt_ph_tight_program_id_tbl(ln_h_cont),
                  gt_ph_correct_tight_class_tbl(ln_h_cont),
                  gt_ph_created_by_tbl(ln_h_cont),
                  gt_ph_creation_date_tbl(ln_h_cont),
                  gt_ph_last_updated_by_tbl(ln_h_cont),
                  gt_ph_last_update_date_tbl(ln_h_cont),
                  gt_ph_last_update_login_tbl(ln_h_cont),
                  gt_ph_request_id_tbl(ln_h_cont),
                  gt_ph_program_appli_id_tbl(ln_h_cont),
                  gt_ph_program_id_tbl(ln_h_cont),
                  gt_ph_program_up_date_tbl(ln_h_cont));
--
      -- ��������(�w�b�_)�J�E���g
      gn_h_normal_cnt := gt_ph_order_header_id_tbl.COUNT;
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
  END put_header_proc;
--
  /**********************************************************************************
   * Procedure Name   : put_line_proc
   * Description      : �󒍖��׃A�h�I���o�^���� (F-8)
   ***********************************************************************************/
  PROCEDURE put_line_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_line_proc'; -- �v���O������
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
    ln_l_cont   NUMBER;         -- ���׃J�E���g�ϐ�
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    FORALL ln_l_cont IN gt_pl_order_line_id_tbl.FIRST .. gt_pl_order_line_id_tbl.LAST
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
      VALUES     (gt_pl_order_line_id_tbl(ln_l_cont),
                  gt_pl_order_header_id_tbl(ln_l_cont),
                  gt_pl_order_line_number_tbl(ln_l_cont),
                  gt_pl_header_id_tbl(ln_l_cont),
                  gt_pl_line_id_tbl(ln_l_cont),
                  gt_pl_request_no_tbl(ln_l_cont),
                  gt_pl_ship_inv_item_id_tbl(ln_l_cont),
                  gt_pl_shipping_item_code_tbl(ln_l_cont),
                  gt_pl_quantity_tbl(ln_l_cont),
                  gt_pl_uom_code_tbl(ln_l_cont),
                  gt_pl_unit_price_tbl(ln_l_cont),
                  gt_pl_shipped_quantity_tbl(ln_l_cont),
                  gt_pl_design_prod_date_tbl(ln_l_cont),
                  gt_pl_based_req_quan_tbl(ln_l_cont),
                  gt_pl_request_item_id_tbl(ln_l_cont),
                  gt_pl_request_item_code_tbl(ln_l_cont),
                  gt_pl_ship_to_quantity_tbl(ln_l_cont),
                  gt_pl_futai_code_tbl(ln_l_cont),
                  gt_pl_designated_date_tbl(ln_l_cont),
                  gt_pl_move_number_tbl(ln_l_cont),
                  gt_pl_po_number_tbl(ln_l_cont),
                  gt_pl_cust_po_number_tbl(ln_l_cont),
                  gt_pl_pallet_quantity_tbl(ln_l_cont),
                  gt_pl_layer_quantity_tbl(ln_l_cont),
                  gt_pl_case_quantity_tbl(ln_l_cont),
                  gt_pl_weight_tbl(ln_l_cont),
                  gt_pl_capacity_tbl(ln_l_cont),
                  gt_pl_pallet_qty_tbl(ln_l_cont),
                  gt_pl_pallet_weight_tbl(ln_l_cont),
                  gt_pl_reserved_quantity_tbl(ln_l_cont),
                  gt_pl_auto_res_class_tbl(ln_l_cont),
                  gt_pl_delete_flag_tbl(ln_l_cont),
                  gt_pl_warning_class_tbl(ln_l_cont),
                  gt_pl_warning_date_tbl(ln_l_cont),
                  gt_pl_line_description_tbl(ln_l_cont),
                  gt_pl_rm_if_flg_tbl(ln_l_cont),
                  gt_pl_ship_req_if_flg_tbl(ln_l_cont),
                  gt_pl_ship_res_if_flg_tbl(ln_l_cont),
                  gt_pl_created_by_tbl(ln_l_cont),
                  gt_pl_creation_date_tbl(ln_l_cont),
                  gt_pl_last_updated_by_tbl(ln_l_cont),
                  gt_pl_last_update_date_tbl(ln_l_cont),
                  gt_pl_last_update_login_tbl(ln_l_cont),
                  gt_pl_request_id_tbl(ln_l_cont),
                  gt_pl_program_appli_id_tbl(ln_l_cont),
                  gt_pl_program_id_tbl(ln_l_cont),
                  gt_pl_program_update_date_tbl(ln_l_cont));
--
      -- ��������(����)�J�E���g
      gn_l_normal_cnt := gt_pl_order_line_id_tbl.COUNT;
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
  END put_line_proc;
--
  /**********************************************************************************
   * Procedure Name   : delete_proc
   * Description      : �f�[�^�폜���� (F-9)
   ***********************************************************************************/
  PROCEDURE delete_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_proc'; -- �v���O������
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
    ln_dh_cont   NUMBER;         -- �폜�p�w�b�_�J�E���g�ϐ�
    ln_dl_cont   NUMBER;         -- �폜�p���׃J�E���g�ϐ�
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --------------------------------------------------
    -- �x���˗����C���^�t�F�[�X�e�[�u���w�b�_�폜 --
    --------------------------------------------------
    FORALL ln_dh_cont IN gt_sup_req_headers_if_id_tbl.FIRST .. gt_sup_req_headers_if_id_tbl.LAST
      DELETE xxpo_supply_req_headers_if   srhi
      WHERE  srhi.supply_req_headers_if_id = gt_sup_req_headers_if_id_tbl(ln_dh_cont);
--
    --------------------------------------------------
    -- �x���˗����C���^�t�F�[�X�e�[�u�����׍폜 --
    --------------------------------------------------
    FORALL ln_dl_cont IN gt_supply_req_lines_if_id_tbl.FIRST .. gt_supply_req_lines_if_id_tbl.LAST
      DELETE xxpo_supply_req_lines_if   srli
      WHERE  srli.supply_req_lines_if_id  = gt_supply_req_lines_if_id_tbl(ln_dl_cont);
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
  END delete_proc;
--
-- 2008/07/17 v1.3 Start
  /**********************************************************************************
   * Procedure Name   : put_dump_msg
   * Description      : �f�[�^�_���v�ꊇ�o�͏���
   ***********************************************************************************/
  PROCEDURE put_dump_msg(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_dump_msg'; -- �v���O������
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
    cv_header   CONSTANT VARCHAR2(10)   := '(�w�b�_)';
    cv_line     CONSTANT VARCHAR2(10)   := '(����)';
--
    -- *** ���[�J���ϐ� ***
    lv_msg  VARCHAR2(5000);  -- ���b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �f�[�^�_���v�ꊇ�o��
    -- ===============================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- �����f�[�^�i���o���j
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_msg_kbn_xxcmn       -- ���W���[�������́FXXCMN
                  ,gv_msg_xxcmn00005)     -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
                ,1,5000);
--
    lv_msg  := lv_msg || cv_header;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- �w�b�_����f�[�^�_���v
    <<normal_h_dump_loop>>
    FOR ln_cnt_loop IN 1 .. normal_h_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, normal_h_dump_tab(ln_cnt_loop));
    END LOOP normal_h_dump_loop;
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- �����f�[�^�i���o���j
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_msg_kbn_xxcmn       -- ���W���[�������́FXXCMN
                  ,gv_msg_xxcmn00005)     -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
                ,1,5000);
--
    lv_msg  := lv_msg || cv_line;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- ���א���f�[�^�_���v
    <<normal_l_dump_loop>>
    FOR ln_cnt_loop IN 1 .. normal_l_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, normal_l_dump_tab(ln_cnt_loop));
    END LOOP normal_l_dump_loop;
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
  END put_dump_msg;
--
-- 2008/07/17 v1.3 End
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_data_class     IN         VARCHAR2,      -- 1.�f�[�^���
    iv_trans_type     IN         VARCHAR2,      -- 2.�����敪
    iv_req_dept       IN         VARCHAR2,      -- 3.�˗�����
    iv_vendor         IN         VARCHAR2,      -- 4.�����
    iv_ship_to        IN         VARCHAR2,      -- 5.�z����
    iv_arvl_time_from IN         VARCHAR2,      -- 6.���ɓ�FROM
    iv_arvl_time_to   IN         VARCHAR2,      -- 7.���ɓ�TO
    iv_security_class IN         VARCHAR2,      -- 8.�Z�L�����e�B�敪
    ov_errbuf         OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    ln_line_number  NUMBER; -- ���הԍ�
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_h_target_cnt := 0;
    gn_l_target_cnt := 0;
    gn_h_cnt        := 0;
    gn_l_cnt        := 0;
--
-- 2008/07/17 v1.3 Start
    gn_h_cnt        := 0;
    gn_l_cnt        := 0;
--
-- 2008/07/17 v1.3 End
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    ------------------------------------------
    -- �p�����[�^�K�{�`�F�b�N               --
    ------------------------------------------
    -- �f�[�^���
    IF (iv_data_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_para_essent,
                                            gv_tkn_para_name,
                                            gv_data_class);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
    -- �����敪
    ELSIF (iv_trans_type IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_para_essent,
                                            gv_tkn_para_name,
                                            gv_trans_type);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
    -- �����
    ELSIF (iv_vendor IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_para_essent,
                                            gv_tkn_para_name,
                                            gv_vendor);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
--
    -- ���ɓ�FROM
    ELSIF (iv_arvl_time_from IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_para_essent,
                                            gv_tkn_para_name,
                                            gv_arvl_time_from);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
--
    -- ���ɓ�TO
    ELSIF (iv_arvl_time_to IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_para_essent,
                                            gv_tkn_para_name,
                                            gv_arvl_time_to);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
--
    -- �Z�L�����e�B�敪
    ELSIF (iv_security_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_para_essent,
                                            gv_tkn_para_name,
                                            gv_security_class);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
--
    END IF;
--
    ------------------------------------------
    -- �p�����[�^���t�`�F�b�N               --
    ------------------------------------------
    -- ����ɓ�TO�������ɓ�FROM����ȑO�̏ꍇ
    IF (iv_arvl_time_from > iv_arvl_time_to) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                            gv_msg_date,
                                            gv_tkn_date_item1,
                                            gv_arvl_time_from,
                                            gv_tkn_date_item2,
                                            gv_arvl_time_to);
      lv_errbuf := lv_errmsg;
      RAISE proc_err_expt;
--
    END IF;
--
    -- ===============================
    -- �������� (F-1)
    -- ===============================
    init_proc(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- ===============================
    -- �w�b�_�f�[�^�擾���� (F-2)
    -- ===============================
    get_header_proc(
      iv_data_class,      -- 1.�f�[�^���
      iv_trans_type,      -- 2.�����敪
      iv_req_dept,        -- 3.�˗�����
      iv_vendor,          -- 4.�����
      iv_ship_to,         -- 5.�z����
      iv_arvl_time_from,  -- 6.���ɓ�FROM
      iv_arvl_time_to,    -- 7.���ɓ�TO
      iv_security_class,  -- 8.�Z�L�����e�B�敪
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
--
      -- 2008/07/08 Mod ��
      IF (gn_h_target_cnt = 0) THEN
        ov_retcode := gv_status_warn;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        RETURN;
      ELSE
        RAISE proc_err_expt;
      END IF;
      -- 2008/07/08 Mod ��
--
    -- ���b�N�G���[�̏ꍇ�͏����I��
    ELSIF (lv_retcode = gv_status_warn) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���׃f�[�^�擾���� (F-3)
    -- ===============================
    get_line_proc(
      iv_data_class,      -- 1.�f�[�^���
      iv_trans_type,      -- 2.�����敪
      iv_req_dept,        -- 3.�˗�����
      iv_vendor,          -- 4.�����
      iv_ship_to,         -- 5.�z����
      iv_arvl_time_from,  -- 6.���ɓ�FROM
      iv_arvl_time_to,    -- 7.���ɓ�TO
      iv_security_class,  -- 8.�Z�L�����e�B�敪
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    -- ���b�N�G���[�̏ꍇ�͏����I��
    ELSIF (lv_retcode = gv_status_warn) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �J�E���g�ϐ�������
    gn_i := 1;
    gn_j := 1;
--
    <<header_loop>>
    FOR i IN gt_sup_req_headers_if_id_tbl.FIRST .. gt_sup_req_headers_if_id_tbl.LAST LOOP
--
      -- �w�b�_�J�E���g�ϐ�
      gn_i := i;
--
      -- �w�b�_ID�̔�
      SELECT xxwsh_order_headers_all_s1.NEXTVAL 
      INTO gt_order_header_id_tbl(gn_i)
      FROM dual;
--
      -- �K�p���ݒ�
      gd_standard_date  := NVL(gt_ship_date_tbl(gn_i), gt_arvl_date_tbl(gn_i));
--
-- 2008/07/17 v1.3 Start
/*      -- ===============================
      -- �K�{�`�F�b�N���� (F-4)(�w�b�_)
      -- ===============================
      chk_essent_proc(
        gv_header,          -- �w�b�_���׋敪
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
      END IF;
*/--
-- 2008/07/17 v1.3 End
      -- ===============================
      -- �}�X�^���݃`�F�b�N���� (F-5)(�w�b�_)
      -- ===============================
      chk_exist_mst_proc(
        gv_header,          -- �w�b�_���׋敪
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
      END IF;
--
      -- ===============================
      -- �֘A�f�[�^�擾���� (F-6)(�w�b�_)
      -- ===============================
      get_relation_proc(
        gv_header,          -- �w�b�_���׋敪
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
      END IF;
--
      -- �ϐ��̏�����
      ln_line_number    := 0;
      gv_before_item_no := NULL;
--
      <<line_loop>>
      -- ���ׂ����݂��A����w�b�_ID�̊Ԏ��s����B
      WHILE (
              (gt_supply_req_lines_if_id_tbl.COUNT >= gn_j) AND
                (gt_sup_req_headers_if_id_tbl(gn_i)  = gt_line_headers_id_tbl(gn_j))
            ) LOOP
--
        -- ����ID�̔�
        SELECT xxwsh_order_lines_all_s1.NEXTVAL 
        INTO gt_order_line_id_tbl(gn_j) 
        FROM dual;
--
        -- ���הԍ��̍̔�
        IF (ln_line_number = 0) THEN
          -- ����w�b�_��MAX(���הԍ�) + 1���擾
          SELECT NVL( MAX(order_line_number), 0 ) + 1
          INTO   ln_line_number
          FROM   xxwsh_order_lines_all xola
          WHERE  xola.order_header_id   = gt_order_header_id_tbl(gn_i);   --�󒍃w�b�_ID
--
        ELSE
          ln_line_number := ln_line_number + 1;
--
        END IF;
--
        -- ���הԍ��̐ݒ�
        gt_line_number_tbl(gn_j) := ln_line_number;
--
-- 2008/07/17 v1.3 Start
/*        -- ===============================
        -- �K�{�`�F�b�N���� (F-4)(����)
        -- ===============================
        chk_essent_proc(
          gv_line,            -- �w�b�_���׋敪
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
*/--
-- 2008/07/17 v1.3 End
        -- ===============================
        -- �}�X�^���݃`�F�b�N���� (F-5)(����)
        -- ===============================
        chk_exist_mst_proc(
          gv_line,            -- �w�b�_���׋敪
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
        -- ===============================
        -- �֘A�f�[�^�擾���� (F-6)(����)
        -- ===============================
        get_relation_proc(
          gv_line,            -- �w�b�_���׋敪
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
        -- ===============================
        -- �o�^�f�[�^�ݒ菈�� (����)
        -- ===============================
        set_data_proc(
          gv_line,            -- �w�b�_���׋敪
          lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
          lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
          lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
-- 2008/07/17 v1.3 Start
        -- ���햾�׃f�[�^�_���vPL/SQL�\����
        gn_l_cnt := gn_l_cnt + 1;
        normal_l_dump_tab(gn_l_cnt) := gt_lr_l_data_dump_tbl(gn_j);
--
-- 2008/07/17 v1.3 End
        -- ���׃J�E���g�ϐ��C���N�������g
        gn_j := gn_j + 1;
--
      END LOOP line_loop;
--
--      -- �J�E���g�ϐ���������
--      gn_j := 1;
--
      -- ===============================
      -- �ύڌ����Z�o
      -- ===============================
      calc_load_efficiency_proc(
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
      END IF;
--
      -- ===============================
      -- �o�^�f�[�^�ݒ菈�� (�w�b�_)
      -- ===============================
      set_data_proc(
        gv_header,          -- �w�b�_���׋敪
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
      END IF;
--
-- 2008/07/17 v1.3 Start
      -- ����w�b�_�f�[�^�_���vPL/SQL�\����
      gn_h_cnt := gn_h_cnt + 1;
      normal_h_dump_tab(gn_h_cnt) := gt_lr_h_data_dump_tbl(gn_i);
--
-- 2008/07/17 v1.3 End
    END LOOP header_loop;
--
    -- ===============================
    -- �󒍃w�b�_�A�h�I���o�^���� (F-7)
    -- ===============================
    put_header_proc(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- ===============================
    -- �󒍖��׃A�h�I���o�^���� (F-8)
    -- ===============================
    put_line_proc(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- ===============================
    -- �f�[�^�폜���� (F-9)
    -- ===============================
    delete_proc(
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2008/07/17 v1.3 Start
    -- =========================================
    -- �f�[�^�_���v�ꊇ�o�͏���
    -- =========================================
    put_dump_msg(
      lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2008/07/17 v1.3 End
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �e�����ŃG���[�����������ꍇ
    WHEN proc_err_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
--
      -- ===============================
      -- �f�[�^�폜���� (F-9)
      -- ===============================
      delete_proc(
        lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> gv_status_error) THEN
        COMMIT;
      END IF;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
    errbuf            OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_data_class     IN         VARCHAR2,      -- 1.�f�[�^���
    iv_trans_type     IN         VARCHAR2,      -- 2.�����敪
    iv_req_dept       IN         VARCHAR2,      -- 3.�˗�����
    iv_vendor         IN         VARCHAR2,      -- 4.�����
    iv_ship_to        IN         VARCHAR2,      -- 5.�z����
    iv_arvl_time_from IN         VARCHAR2,      -- 6.���ɓ�FROM
    iv_arvl_time_to   IN         VARCHAR2,      -- 7.���ɓ�TO
    iv_security_class IN         VARCHAR2       -- 8.�Z�L�����e�B�敪
  )
--
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
-- 2008/07/17 v1.3 Start
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_msg  VARCHAR2(5000);  -- ���b�Z�[�W
--
-- 2008/07/17 v1.3 Start
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
-- 2008/07/17 v1.3 Start
    -- ���̓p�����[�^�擾
    gv_iv_data_class       := iv_data_class;      -- 1.�f�[�^���
    gv_iv_trans_type       := iv_trans_type;      -- 2.�����敪
    gv_iv_req_dept         := iv_req_dept;        -- 3.�˗�����
    gv_iv_vendor           := iv_vendor;          -- 4.�����
    gv_iv_ship_to          := iv_ship_to;         -- 5.�z����
    gv_iv_arvl_time_from   := iv_arvl_time_from;  -- 6.���ɓ�FROM
    gv_iv_arvl_time_to     := iv_arvl_time_to;    -- 7.���ɓ�TO
    gv_iv_security_class   := iv_security_class;  -- 8.�Z�L�����e�B�敪
--
    -- ===============================
    -- ���̓p�����[�^�o��
    -- ===============================
    -- ��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ���̓p�����[�^(���o��)
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_msg_kbn_xxpo      -- ���W���[�������́FXXPO
                  ,gv_msg_xxpo30051)    -- ���b�Z�[�W:APP-XXPO-30051 ���̓p�����[�^(���o��)
                ,1,5000);
--
    -- ���̓p�����[�^���o���o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- ���̓p�����[�^(�J���}��؂�)
    lv_msg := gv_iv_data_class     || gv_msg_comma || -- 1.�f�[�^���
              gv_iv_trans_type     || gv_msg_comma || -- 2.�����敪
              gv_iv_req_dept       || gv_msg_comma || -- 3.�˗�����
              gv_iv_vendor         || gv_msg_comma || -- 4.�����
              gv_iv_ship_to        || gv_msg_comma || -- 5.�z����
              gv_iv_arvl_time_from || gv_msg_comma || -- 6.���ɓ�FROM
              gv_iv_arvl_time_to   || gv_msg_comma || -- 7.���ɓ�TO
              gv_iv_security_class;                   -- 8.�Z�L�����e�B�敪
--
    -- ���̓p�����[�^�o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- ��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
-- 2008/07/17 v1.3 End
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      iv_data_class,      -- 1.�f�[�^���
      iv_trans_type,      -- 2.�����敪
      iv_req_dept,        -- 3.�˗�����
      iv_vendor,          -- 4.�����
      iv_ship_to,         -- 5.�z����
      iv_arvl_time_from,  -- 6.���ɓ�FROM
      iv_arvl_time_to,    -- 7.���ɓ�TO
      iv_security_class,  -- 8.�Z�L�����e�B�敪
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
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
    ------------------------------------------
    -- �w�b�_�Ɩ��ׂ𕪂��ďo��             --
    ------------------------------------------
    --���������o��(�w�b�_)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                           gv_msg_h_target_cnt,
                                           gv_tkn_count,
                                           TO_CHAR(gn_h_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��(����)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                           gv_msg_l_target_cnt,
                                           gv_tkn_count,
                                           TO_CHAR(gn_l_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��(�w�b�_)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                           gv_msg_h_normal_cnt,
                                           gv_tkn_count,
                                           TO_CHAR(gn_h_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��(����)
    gv_out_msg := xxcmn_common_pkg.get_msg(gv_msg_kbn_xxpo,
                                           gv_msg_l_normal_cnt,
                                           gv_tkn_count,
                                           TO_CHAR(gn_l_normal_cnt));
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
END xxpo940006c;
/
