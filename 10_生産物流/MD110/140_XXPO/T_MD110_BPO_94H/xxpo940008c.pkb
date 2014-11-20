create or replace PACKAGE BODY xxpo940008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940008c(body)
 * Description      : ���b�g�������捞����
 * MD.050           : �����I�����C�� T_MD050_BPO_940
 * MD.070           : ���b�g�������捞���� T_MD070_BPO_94H
 * Version          : 1.3
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  init_proc                   ��������(H-1)
 *  check_can_enc_qty           �������ʃ`�F�b�N����(H-2)
 *  get_data                    �Ώۃf�[�^�擾����(H-3)
 *  check_data                  �擾�f�[�^�`�F�b�N����(H-4)
 *  get_other_data              �֘A�f�[�^�擾����(H-5)
 *  ins_mov_lot_details         �ړ����b�g�ڍ�(�A�h�I��)�o�^����(H-6)
 *  ins_order_lines_all         �󒍖���(�A�h�I��)�o�^����(H-7)
 *  ins_order_headers_all       �󒍃w�b�_(�A�h�I��)�o�^����(H-8)
 *  del_lot_reserve_if          �f�[�^�폜����(H-9)
 *  put_dump_msg                �f�[�^�_���v�ꊇ�o�͏���(H-10)
 *  set_order_header_data_proc  �󒍃w�b�_�X�V�f�[�^�ݒ菈��
 *  set_order_line_data_proc    �󒍖��׍X�V�f�[�^�ݒ菈��
 *  set_mov_lot_data_proc       �ړ����b�g�ڍדo�^�f�[�^�ݒ菈��
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/06/19    1.0  Oracle �g�c�Ď�   ����쐬
 *  2008/07/22    1.1  Oracle �g�c�Ď�   �����ۑ�#32�A#66�A�����ύX#166�Ή�
 *  2008/07/29    1.2  Oracle �g�c�Ď�   ST�s��Ή�(�̔ԂȂ�)
 *  2008/08/22    1.3  Oracle �R����_   T_TE080_BPO_940 �w�E4,�w�E5,�w�E17�Ή�
 *
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
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
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
  gn_target_cnt    NUMBER;                    -- �Ώی���(���b�g�������IF)
  gn_h_normal_cnt  NUMBER;                    -- ���팏��(�󒍃w�b�_)
  gn_l_normal_cnt  NUMBER;                    -- ���팏��(�󒍖���)
  gn_m_normal_cnt  NUMBER;                    -- ���팏��(�ړ����b�g�ڍ�)
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
  -- ���b�N�擾�G���[
  check_lock_expt           EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt                EXCEPTION;  -- ���b�N�擾��O
  proc_err_expt            EXCEPTION;     -- �����G���[
--
    PRAGMA EXCEPTION_INIT(lock_expt, -54); -- ���b�N�擾��O
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name             CONSTANT VARCHAR2(100) := 'xxpo940008c'; -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  gv_xxpo                 CONSTANT VARCHAR2(5) := 'XXPO';   -- ���W���[��������:XXPO
  gv_xxcmn                CONSTANT VARCHAR2(5) := 'XXCMN';  -- ���W���[��������:XXCMN
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10002       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002'; -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
  gv_msg_xxcmn10019       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10019'; -- ���b�Z�[�W:APP-XXCMN-10019 ���b�N�G���[
  gv_msg_xxpo10234        CONSTANT VARCHAR2(100) := 'APP-XXPO-10234';  -- ���b�Z�[�W:APP-XXPO-10234  ���݃`�F�b�N�G���[
  gv_msg_xxcmn00005       CONSTANT VARCHAR2(100) := 'APP-XXCMN-00005'; -- ���b�Z�[�W:APP-XXCMN-00005 �����f�[�^�i���o���j
  gv_msg_xxpo10252        CONSTANT VARCHAR2(100) := 'APP-XXPO-10252';  -- ���b�Z�[�W:APP-XXPO-10252  �x���f�[�^�i���o���j
  gv_msg_xxpo10007        CONSTANT VARCHAR2(100) := 'APP-XXPO-10007';  -- ���b�Z�[�W:APP-XXPO-10007  �f�[�^�o�^�G���[
  gv_msg_xxpo10025        CONSTANT VARCHAR2(100) := 'APP-XXPO-10025';  -- ���b�Z�[�W:APP-XXPO-10025  �R���J�����g�o�^�G���[
  gv_msg_xxpo10120        CONSTANT VARCHAR2(100) := 'APP-XXPO-10120';  -- ���b�Z�[�W:APP-XXPO-10226  �ύڌ����`�F�b�N�G���[
  gv_msg_xxcmn10109       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10109'; -- ���b�Z�[�W:APP-XXCMN-10109 �����\�݌ɐ����ߒʒm���[�j���O
  gv_msg_xxcmn10018       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10018'; -- ���b�Z�[�W:APP-XXCMN-10018 API�G���[
  gv_msg_xxpo10229        CONSTANT VARCHAR2(100) := 'APP-XXPO-10229';  -- ���b�Z�[�W:APP-XXPO-10229  �f�[�^�擾�G���[
  gv_msg_xxpo10237        CONSTANT VARCHAR2(100) := 'APP-XXPO-10237';  -- ���b�Z�[�W:APP-XXPO-10237  ���ʊ֐��G���[
  gv_msg_xxpo10156        CONSTANT VARCHAR2(100) := 'APP-XXPO-10156';  -- ���b�Z�[�W:APP-XXPO-10156  �v���t�@�C���擾�G���[
  gv_msg_xxpo10235        CONSTANT VARCHAR2(100) := 'APP-XXPO-10235';  -- ���b�Z�[�W:APP-XXPO-10235  �p�����[�^�K�{�G���[
  gv_msg_xxpo10236        CONSTANT VARCHAR2(100) := 'APP-XXPO-10236';  -- ���b�Z�[�W:APP-XXPO-10236  �p�����[�^���t�G���[
  gv_msg_xxpo10255        CONSTANT VARCHAR2(100) := 'APP-XXPO-10255';  -- ���b�Z�[�W:APP-XXPO-10255  ���l0�ȉ��G���[
  gv_msg_xxpo30051        CONSTANT VARCHAR2(100) := 'APP-XXPO-30051';  -- ���b�Z�[�W:APP-XXPO-30051  ���̓p�����[�^(���o��)
  gv_msg_xxpo10262        CONSTANT VARCHAR2(100) := 'APP-XXPO-10262';  -- ���b�Z�[�W:APP-XXPO-10262  �������s���G���[
  gv_msg_xxcmn10604       CONSTANT VARCHAR2(100) := 'APP-XXCMN-10604'; -- ���b�Z�[�W:APP-XXCMN-10604 �P�[�X�����G���[
  gv_msg_xxpo10267        CONSTANT VARCHAR2(100) := 'APP-XXPO-10267';  -- ���b�Z�[�W:APP-XXPO-10267  ���b�g�X�e�[�^�X�G���[ 2008/08/22 Add
--
  -- �g�[�N��
  gv_tkn_ng_profile       CONSTANT VARCHAR2(100) := 'NG_PROFILE';
  gv_tkn_table            CONSTANT VARCHAR2(100) := 'TABLE';
  gv_tkn_location         CONSTANT VARCHAR2(100) := 'LOCATION';
  gv_tkn_item             CONSTANT VARCHAR2(100) := 'ITEM';
  gv_tkn_lot              CONSTANT VARCHAR2(100) := 'LOT';
  gv_tkn_api_name         CONSTANT VARCHAR2(100) := 'API_NAME';
  gv_tkn_common_name      CONSTANT VARCHAR2(100) := 'NG_COMMON';
  gv_tkn_name             CONSTANT VARCHAR2(100) := 'NAME';
  gv_tkn_ship_type        CONSTANT VARCHAR2(100) := 'SHIP_TYPE';
  gv_tkn_ship_to          CONSTANT VARCHAR2(100) := 'SHIP_TO';
  gv_tkn_revdate          CONSTANT VARCHAR2(100) := 'REVDATE';
  gv_tkn_arrival_date     CONSTANT VARCHAR2(100) := 'ARRIVAL_DATE';
  gv_tkn_standard_date    CONSTANT VARCHAR2(100) := 'STANDARD_DATE';
  gv_tkn_para_name        CONSTANT VARCHAR2(100) := 'PARAM_NAME';
  gv_tkn_date_item1       CONSTANT VARCHAR2(100) := 'ITEM1';
  gv_tkn_date_item2       CONSTANT VARCHAR2(100) := 'ITEM2';
  gv_tkn_request_no       CONSTANT VARCHAR2(100) := 'REQUEST_NO';
  gv_tkn_item_no          CONSTANT VARCHAR2(100) := 'ITEM_NO';
  gv_tkn_lot_no           CONSTANT VARCHAR2(100) := 'LOT_NO';             -- 2008/08/22 Add
-- 
  -- �g�[�N������
  gv_tkn_prod_class_code     CONSTANT VARCHAR2(100) := 'XXCMN:���i�敪(�Z�L�����e�B)';
  gv_item_div_id             CONSTANT VARCHAR2(100) := 'XXCMN_ITEM_DIV_SECURITY';
  gv_tkn_lot_reserve_if      CONSTANT VARCHAR2(100) := '���b�g�������C���^�t�F�[�X';
  gv_tkn_xxpo_headers_all    CONSTANT VARCHAR2(100) := '�󒍃w�b�_(�A�h�I��)';
  gv_tkn_xxpo_lines_all      CONSTANT VARCHAR2(100) := '�󒍖���(�A�h�I��)';
  gv_tkn_xxinv_mov_lot_details  CONSTANT VARCHAR2(100) := '�ړ����b�g�ڍ�(�A�h�I��)';
  gv_tkn_chk_can_qty         CONSTANT VARCHAR2(100) := '�����\���Z�o';
  gv_tkn_calc_total_value    CONSTANT VARCHAR2(100) := '�ύڌ����`�F�b�N(���v�l�Z�o)';
  gv_tkn_calc_load_ef_we     CONSTANT VARCHAR2(100) := '�ύڌ����`�F�b�N(�ύڌ����Z�o:�d��)';
  gv_tkn_calc_load_ef_ca     CONSTANT VARCHAR2(100) := '�ύڌ����`�F�b�N(�ύڌ����Z�o:�e��)';
  gv_tkn_cancel_car_sche     CONSTANT VARCHAR2(100) := '�z�ԉ����֐�';
  gv_tkn_xxcmn_lookup_values2   CONSTANT VARCHAR2(100) := '�N�C�b�N�R�[�h���VIEW2';
  gv_tkn_reserve_qty         CONSTANT VARCHAR2(100) := '��������';
  gv_tkn_date                CONSTANT VARCHAR2(100) := '�Ώۃf�[�^';
--
  gv_max_ship                CONSTANT VARCHAR2(100)  := '�ő�z���敪�Z�o�֐�';
  gv_deliver_from            CONSTANT VARCHAR2(100)  := '�z����';
  gv_data_class              CONSTANT VARCHAR2(100)  := '�f�[�^���';
  gv_deliver_from_s          CONSTANT VARCHAR2(100)  := '�q��';
  gv_shippe_date_from        CONSTANT VARCHAR2(100)  := '�o�ɓ�FROM';
  gv_shippe_date_to          CONSTANT VARCHAR2(100)  := '�o�ɓ�TO';
  gv_instruction_dept        CONSTANT VARCHAR2(100)  := '�w������';
  gv_security_class          CONSTANT VARCHAR2(100)  := '�Z�L�����e�B�敪';
--
  -- �Z�L�����e�B�敪
  gv_security_kbn_in         CONSTANT VARCHAR2(1) := '1'; -- �Z�L�����e�B�敪 �ɓ������[�U�[
  gv_security_kbn_out        CONSTANT VARCHAR2(1) := '4'; -- �Z�L�����e�B�敪 ���m�u�����[�U�[
--
  -- ���t����
  gv_yyyymmdd                CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';
  gv_yyyymmddhh24miss        CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
--
  -- �����蓮�����敪
  gv_am_reserve_class_ma     CONSTANT VARCHAR2(2) := '10'; -- �蓮
  gv_am_reserve_class_au     CONSTANT VARCHAR2(2) := '20'; -- ����
--
  -- �����^�C�v
  gv_document_type_ship_req  CONSTANT VARCHAR2(2) := '30'; -- �x���˗�
--
  -- ���R�[�h�^�C�v
  gv_record_type_inst        CONSTANT VARCHAR2(2) := '10'; -- �w��
--
  -- �����^�C�v
  gv_we               CONSTANT VARCHAR2(1)   := '1';       -- �d��
  gv_ca               CONSTANT VARCHAR2(1)   := '2';       -- �e��
  gv_object           CONSTANT VARCHAR2(1)   := '1';       -- �Ώ�
--
  -- �i�ڋ敪
  gv_item_class_code_prod         CONSTANT VARCHAR2(1) := '5'; -- �i�ڋ敪:���i
  gv_item_class_code_half_prod    CONSTANT VARCHAR2(1) := '4'; -- �i�ڋ敪:�����i
--
  -- ���i�敪
  gv_prod_class_code_leaf    CONSTANT VARCHAR2(1) := '1'; -- ���i�敪:���[�t
  gv_prod_class_code_drink   CONSTANT VARCHAR2(1) := '2'; -- ���i�敪:�h�����N
-- ST�s��Ή� modify 2008/07/29 start
  -- �^���敪
  gv_freight_charge_class_on      CONSTANT VARCHAR2(1) := '1'; -- �^���敪:�Ώ�
  gv_freight_charge_class_off     CONSTANT VARCHAR2(1) := '0'; -- �^���敪:�ΏۊO
-- ST�s��Ή� modify 2008/07/29 end
--
  -- API���^�[���E�R�[�h
  gv_api_ret_cd_normal       CONSTANT VARCHAR2(1) := 'S'; -- API���^�[���E�R�[�h:����I��
--
  -- �t���O
  gv_flg_y     CONSTANT VARCHAR2(1) := 'Y';  -- �t���O:Y
  gv_flg_n     CONSTANT VARCHAR2(1) := 'N';  -- �t���O:N
  gv_flg_on    CONSTANT VARCHAR2(1) := '1';  -- �t���O:1
  gv_flg_off   CONSTANT VARCHAR2(1) := '0';  -- �t���O:0
--
  -- �󒍃w�b�_/�󒍖��׋敪(�������W�b�N�p)
  gv_header           CONSTANT VARCHAR2(1)   := '0';      -- �w�b�_
  gv_line             CONSTANT VARCHAR2(1)   := '1';      -- ����
--
  -- �X�e�[�^�X
  gv_transaction_status_04   CONSTANT VARCHAR2(2) := '05';  -- ���͒�
  gv_transaction_status_06   CONSTANT VARCHAR2(2) := '06';  -- ���͊���
  gv_transaction_status_07   CONSTANT VARCHAR2(2) := '07';  -- ��̍�
  gv_transaction_status_08   CONSTANT VARCHAR2(2) := '08';  -- �o�׎��ьv���
  gv_transaction_status_99   CONSTANT VARCHAR2(2) := '99';  -- ����F99
--
  -- �ڋq�敪
  gv_customer_class_code_1     CONSTANT NUMBER       := 1;    -- �ڋq�敪:1(���_)
--
  -- �N�C�b�N�R�[�h
  gv_lookup_type_xsm           CONSTANT VARCHAR2(17) := 'XXCMN_SHIP_METHOD';  -- �z���敪
--
  -- �Ɩ����
  gv_supply                    CONSTANT VARCHAR2(1)  := '2';                -- �x��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���b�Z�[�WPL/SQL�\�^
  TYPE msg_ttype         IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- �󒍖��׎w�����ʍX�V�t���O
  TYPE gt_pl_up_flg_type         IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
  -- �󒍖��w�b�_�w�����ʍX�V�t���O
  TYPE gt_ph_up_flg_type         IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
  -- �ő�z���敪
  TYPE gt_ship_method_tbl_type   IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;
  -- �����敪
  --TYPE gt_small_amount_class_tbl_type   IS TABLE OF VARCHAR2(10) INDEX BY BINARY_INTEGER;
--
  ---------------------------------------------
  -- ���b�g�������C���^�t�F�[�X�擾       --
  ---------------------------------------------
  -- ���b�g�������C���^�t�F�[�X�w�b�_ID
  TYPE lr_lot_reserve_if_id_tbl IS TABLE OF
    xxpo_lot_reserve_if.lot_reserve_if_id%TYPE INDEX BY BINARY_INTEGER;
  -- �˗�No.
  TYPE lr_request_no_tbl IS TABLE OF
    xxpo_lot_reserve_if.request_no%TYPE INDEX BY BINARY_INTEGER;
  -- �i�ڃR�[�h
  TYPE lr_item_code_tbl IS TABLE OF
    xxpo_lot_reserve_if.item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ���דE�v
  TYPE lr_line_description_tbl IS TABLE OF
    xxpo_lot_reserve_if.line_description%TYPE INDEX BY BINARY_INTEGER;
  -- ���b�gNo.
  TYPE lr_lot_no_tbl IS TABLE OF
    xxpo_lot_reserve_if.lot_no%TYPE INDEX BY BINARY_INTEGER;
  -- ��������
  TYPE lr_reserved_quantity_tbl IS TABLE OF
    xxpo_lot_reserve_if.reserved_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ����ID
  TYPE lr_order_line_id_tbl IS TABLE OF
    xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- �������ʍ��v
  TYPE lr_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.quantity%TYPE INDEX BY BINARY_INTEGER;
  -- ���b�gID
  TYPE lr_lot_id_tbl IS TABLE OF
    ic_lots_mst.lot_id%TYPE INDEX BY BINARY_INTEGER;
  -- �i��ID
  TYPE lr_item_id_tbl IS TABLE OF
    xxcmn_item_mst2_v.item_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���o�Ɋ��Z�P��
  TYPE lr_conv_unit_tbl IS TABLE OF
    xxcmn_item_mst2_v.conv_unit%TYPE INDEX BY BINARY_INTEGER;
  -- �P�[�X���萔
  TYPE lr_num_of_cases_tbl IS TABLE OF
    xxcmn_item_mst2_v.num_of_cases%TYPE INDEX BY BINARY_INTEGER;
  -- �z����ID
  TYPE lr_deliver_to_id_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_site_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���͕ۊǑq�ɃR�[�h
  TYPE lr_deliver_from_tbl IS TABLE OF
    xxwsh_order_headers_all.deliver_from%TYPE INDEX BY BINARY_INTEGER;
  -- ���ח\���
  TYPE lr_sche_arrival_date_tbl IS TABLE OF
    xxwsh_order_headers_all.schedule_arrival_date%TYPE INDEX BY BINARY_INTEGER;
  -- �o�ד�
  TYPE lr_shipped_date_tbl IS TABLE OF
    xxwsh_order_headers_all.shipped_date%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃w�b�_�A�h�I��ID
  TYPE lr_order_header_id_tbl IS TABLE OF
    xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- �����N����(OPM���b�g�}�X�^)
  TYPE lr_lot_date_tbl IS TABLE OF
    ic_lots_mst.attribute1%TYPE INDEX BY BINARY_INTEGER;
  -- ���i�敪
  TYPE lr_prod_class_code_tbl IS TABLE OF
    xxcmn_item_categories4_v.prod_class_code%TYPE INDEX BY BINARY_INTEGER;
  -- �i�ڋ敪
  TYPE lr_item_class_code_tbl IS TABLE OF
    xxcmn_item_categories4_v.item_class_code%TYPE INDEX BY BINARY_INTEGER;
  -- �z����R�[�h
  TYPE lr_deliver_to_tbl IS TABLE OF
    xxwsh_order_headers_all.vendor_site_code%TYPE INDEX BY BINARY_INTEGER;
  -- �d�ʗe�ϋ敪
  TYPE lr_we_ca_class_tbl IS TABLE OF
    xxwsh_order_headers_all.weight_capacity_class%TYPE INDEX BY BINARY_INTEGER;
  -- �f�[�^�_���v
  TYPE lr_data_dump_tbl IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
  -- �z���敪
  TYPE lr_shipping_method_code_tbl IS TABLE OF
    xxwsh_order_headers_all.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
-- ST�s��Ή� modify 2008/07/29 start
  -- �^���敪
  TYPE lr_freight_charge_class_tbl IS TABLE OF
    xxwsh_order_headers_all.freight_charge_class%TYPE INDEX BY BINARY_INTEGER;
-- ST�s��Ή� modify 2008/07/29 end
-- 2008/08/22 Add ��
  -- ���b�g
  TYPE lr_lot_ctl_tbl IS TABLE OF
    xxcmn_item_mst2_v.lot_ctl%TYPE INDEX BY BINARY_INTEGER;
-- 2008/08/22 Add ��
--
  ---------------------------------------------
  -- �ړ����b�g�ڍ׃A�h�I���擾              --
  ---------------------------------------------
  -- ���b�g�ڍ�ID
  TYPE mr_mov_lot_dtl_id_tbl IS TABLE OF
    xxinv_mov_lot_details.mov_lot_dtl_id%TYPE INDEX BY BINARY_INTEGER;
--
  ---------------------------------------------
  -- �󒍃w�b�_�A�h�I���X�V                  --
  ---------------------------------------------
  -- �󒍃w�b�_�A�h�I��ID
  TYPE ph_order_header_id_tbl IS TABLE OF
    xxwsh_order_headers_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- �˗�No.
  TYPE ph_request_no_tbl IS TABLE OF
    xxwsh_order_headers_all.request_no%TYPE INDEX BY BINARY_INTEGER;
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
  TYPE ph_load_efficiency_we_tbl IS TABLE OF
    xxwsh_order_headers_all.loading_efficiency_weight%TYPE INDEX BY BINARY_INTEGER;
  -- �e�ϐύڌ���
  TYPE ph_load_efficiency_ca_tbl IS TABLE OF
    xxwsh_order_headers_all.loading_efficiency_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- �ύڏd�ʍ��v
  TYPE ph_sum_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_weight%TYPE INDEX BY BINARY_INTEGER;
  -- �ύڗe�ύ��v
  TYPE ph_sum_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- �p���b�g���v�d��
  TYPE ph_sum_pallet_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.sum_pallet_weight%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE ph_last_updated_by_tbl IS TABLE OF
    xxwsh_order_headers_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE ph_last_update_date_tbl IS TABLE OF
    xxwsh_order_headers_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V���O�C��
  TYPE ph_last_update_login_tbl IS TABLE OF
    xxwsh_order_headers_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
-- 2008/08/22 Add ��
  -- ��{�d��
  TYPE ph_based_weight_tbl IS TABLE OF
    xxwsh_order_headers_all.based_weight%TYPE INDEX BY BINARY_INTEGER;
  -- ��{�e��
  TYPE ph_based_capacity_tbl IS TABLE OF
    xxwsh_order_headers_all.based_capacity%TYPE INDEX BY BINARY_INTEGER;
  -- �z���敪
  TYPE ph_shipping_method_cd_tbl IS TABLE OF
    xxwsh_order_headers_all.shipping_method_code%TYPE INDEX BY BINARY_INTEGER;
-- 2008/08/22 Add ��
--
  ---------------------------------------------
  -- �󒍖��׃A�h�I���X�V                    --
  ---------------------------------------------
  -- �󒍖��׃A�h�I��ID
  TYPE pl_order_line_id_tbl IS TABLE OF
    xxwsh_order_lines_all.order_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- �󒍃w�b�_�A�h�I��ID
  TYPE pl_order_header_id_tbl IS TABLE OF
    xxwsh_order_lines_all.order_header_id%TYPE INDEX BY BINARY_INTEGER;
  -- ����
  TYPE pl_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �d��
  TYPE pl_weight_tbl IS TABLE OF
    xxwsh_order_lines_all.weight%TYPE INDEX BY BINARY_INTEGER;
  -- �e��
  TYPE pl_capacity_tbl IS TABLE OF
    xxwsh_order_lines_all.capacity%TYPE INDEX BY BINARY_INTEGER;
  -- �p���b�g�d��
  TYPE pl_pallet_weight_tbl IS TABLE OF
    xxwsh_order_lines_all.pallet_weight%TYPE INDEX BY BINARY_INTEGER;
  -- ������
  TYPE pl_reserved_quantity_tbl IS TABLE OF
    xxwsh_order_lines_all.reserved_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �����蓮�����敪
  TYPE pl_auto_reserve_class_tbl IS TABLE OF
    xxwsh_order_lines_all.automanual_reserve_class%TYPE INDEX BY BINARY_INTEGER;
  -- �E�v
  TYPE pl_line_description_tbl IS TABLE OF
    xxwsh_order_lines_all.line_description%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE pl_last_updated_by_tbl IS TABLE OF
    xxwsh_order_lines_all.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE pl_last_update_date_tbl IS TABLE OF
    xxwsh_order_lines_all.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V���O�C��
  TYPE pl_last_update_login_tbl IS TABLE OF
    xxwsh_order_lines_all.last_update_login%TYPE INDEX BY BINARY_INTEGER;
--
  ---------------------------------------------
  -- �ړ����b�g�ڍ�(�A�h�I��)�X�V                    --
  ---------------------------------------------
  -- ���b�g�ڍ�ID
  TYPE pm_mov_lot_dtl_id_tbl IS TABLE OF
    xxinv_mov_lot_details.mov_lot_dtl_id%TYPE INDEX BY BINARY_INTEGER;
  -- �ڍ�ID
  TYPE pm_mov_line_id_tbl IS TABLE OF
    xxinv_mov_lot_details.mov_line_id%TYPE INDEX BY BINARY_INTEGER;
  -- �����^�C�v
  TYPE pm_document_type_code_tbl IS TABLE OF
    xxinv_mov_lot_details.document_type_code%TYPE INDEX BY BINARY_INTEGER;
  -- ���R�[�h�^�C�v
  TYPE pm_record_type_code_tbl IS TABLE OF
    xxinv_mov_lot_details.record_type_code%TYPE INDEX BY BINARY_INTEGER;
  -- OPM�i��ID
  TYPE pm_item_id_tbl IS TABLE OF
    xxinv_mov_lot_details.item_id%TYPE INDEX BY BINARY_INTEGER;
  -- �i�ڃR�[�h
  TYPE pm_item_code_tbl IS TABLE OF
    xxinv_mov_lot_details.item_code%TYPE INDEX BY BINARY_INTEGER;
  -- ���b�gID
  TYPE pm_lot_id_tbl IS TABLE OF
    xxinv_mov_lot_details.lot_id%TYPE INDEX BY BINARY_INTEGER;
  -- ���b�gNo.
  TYPE pm_lot_no_tbl IS TABLE OF
    xxinv_mov_lot_details.lot_no%TYPE INDEX BY BINARY_INTEGER;
  -- ���ѓ�
  TYPE pm_actual_date_tbl IS TABLE OF
    xxinv_mov_lot_details.actual_date%TYPE INDEX BY BINARY_INTEGER;
  -- ���ѐ���
  TYPE pm_actual_quantity_tbl IS TABLE OF
    xxinv_mov_lot_details.actual_quantity%TYPE INDEX BY BINARY_INTEGER;
  -- �����蓮�����敪
  TYPE pm_auma_reserve_class_tbl IS TABLE OF
    xxinv_mov_lot_details.automanual_reserve_class%TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE pm_created_by_tbl IS TABLE OF
    xxinv_mov_lot_details.created_by%TYPE INDEX BY BINARY_INTEGER;
  -- �쐬��
  TYPE pm_creation_date_tbl IS TABLE OF
    xxinv_mov_lot_details.creation_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE pm_last_updated_by_tbl IS TABLE OF
    xxinv_mov_lot_details.last_updated_by%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V��
  TYPE pm_last_update_date_tbl IS TABLE OF
    xxinv_mov_lot_details.last_update_date%TYPE INDEX BY BINARY_INTEGER;
  -- �ŏI�X�V���O�C��
  TYPE pm_last_update_login_tbl IS TABLE OF
    xxinv_mov_lot_details.last_update_login%TYPE INDEX BY BINARY_INTEGER;
  -- �v��ID
  TYPE pm_request_id_tbl IS TABLE OF
    xxinv_mov_lot_details.request_id%TYPE INDEX BY BINARY_INTEGER;
  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  TYPE pm_program_app_id_tbl IS TABLE OF
    xxinv_mov_lot_details.program_application_id%TYPE INDEX BY BINARY_INTEGER;
  -- �R���J�����g�E�v���O����ID
  TYPE pm_program_id_tbl IS TABLE OF
    xxinv_mov_lot_details.program_id%TYPE INDEX BY BINARY_INTEGER;
  -- �v���O�����X�V��
  TYPE pm_program_update_date_tbl IS TABLE OF
    xxinv_mov_lot_details.program_update_date%TYPE INDEX BY BINARY_INTEGER;
--
  -- ���b�g�������IF�擾�p
  gt_lr_lot_reserve_if_id_tbl         lr_lot_reserve_if_id_tbl;
  gt_lr_request_no_tbl                lr_request_no_tbl;
  gt_lr_item_code_tbl                 lr_item_code_tbl;
  gt_lr_line_description_tbl          lr_line_description_tbl;
  gt_lr_lot_no_tbl                    lr_lot_no_tbl;
  gt_lr_reserved_quantity_tbl         lr_reserved_quantity_tbl;
  gt_lr_order_line_id_tbl             lr_order_line_id_tbl;
  gt_lr_quantity_tbl                  lr_quantity_tbl;
  gt_lr_lot_id_tbl                    lr_lot_id_tbl;
  gt_lr_item_id_tbl                   lr_item_id_tbl;
  gt_lr_conv_unit_tbl                 lr_conv_unit_tbl;
  gt_lr_num_of_cases_tbl              lr_num_of_cases_tbl;
  gt_lr_deliver_to_id_tbl             lr_deliver_to_id_tbl;
  gt_lr_deliver_from_tbl              lr_deliver_from_tbl;
  gt_lr_sche_arrival_date_tbl         lr_sche_arrival_date_tbl;
  gt_lr_shipped_date_tbl              lr_shipped_date_tbl;  
  gt_lr_order_header_id_tbl           lr_order_header_id_tbl;
  gt_lr_lot_date_tbl                  lr_lot_date_tbl;
  gt_lr_prod_class_code_tbl           lr_prod_class_code_tbl;
  gt_lr_item_class_code_tbl           lr_item_class_code_tbl;
  gt_lr_deliver_to_tbl                lr_deliver_to_tbl;
  gt_lr_we_ca_class_tbl               lr_we_ca_class_tbl;
  gt_lr_data_dump_tbl                 lr_data_dump_tbl;
  gt_lr_shipping_method_code_tbl      lr_shipping_method_code_tbl;
-- ST�s��Ή� modify 2008/07/29 start
  gt_lr_freight_charge_class_tbl      lr_freight_charge_class_tbl;
-- ST�s��Ή� modify 2008/07/29 end
-- 2008/08/22 Add ��
  gt_lr_lot_ctl_tbl                   lr_lot_ctl_tbl;
-- 2008/08/22 Add ��
--
  -- �ړ����b�g�ڍ׎擾�p
  gt_mr_mov_lot_dtl_id_tbl            mr_mov_lot_dtl_id_tbl;
--
  -- �X�V�p(�󒍃w�b�_�A�h�I��)
  gt_ph_order_header_id_tbl                 ph_order_header_id_tbl;
  gt_ph_request_no_tbl                      ph_request_no_tbl;
  gt_ph_sum_quantity_tbl                    ph_sum_quantity_tbl;
  gt_ph_small_quantity_tbl                  ph_small_quantity_tbl;
  gt_ph_label_quantity_tbl                  ph_label_quantity_tbl;
  gt_ph_load_efficiency_we_tbl              ph_load_efficiency_we_tbl;
  gt_ph_load_efficiency_ca_tbl              ph_load_efficiency_ca_tbl;
  gt_ph_sum_weight_tbl                      ph_sum_weight_tbl;
  gt_ph_sum_capacity_tbl                    ph_sum_capacity_tbl;
  gt_ph_last_updated_by_tbl                 ph_last_updated_by_tbl;
  gt_ph_last_update_date_tbl                ph_last_update_date_tbl;
  gt_ph_last_update_login_tbl               ph_last_update_login_tbl;
  gt_ph_sum_pallet_weight_tbl               ph_sum_pallet_weight_tbl;
  --�X�V�p(�󒍖��׃A�h�I��)
  gt_pl_order_line_id_tbl                   pl_order_line_id_tbl;
  gt_pl_order_header_id_tbl                 pl_order_header_id_tbl;
  gt_pl_quantity_tbl                        pl_quantity_tbl;
  gt_pl_weight_tbl                          pl_weight_tbl;
  gt_pl_capacity_tbl                        pl_capacity_tbl;
  gt_pl_reserved_quantity_tbl               pl_reserved_quantity_tbl;
  gt_pl_auto_reserve_class_tbl              pl_auto_reserve_class_tbl;
  gt_pl_line_description_tbl                pl_line_description_tbl;
  gt_pl_last_updated_by_tbl                 pl_last_updated_by_tbl;
  gt_pl_last_update_date_tbl                pl_last_update_date_tbl;
  gt_pl_last_update_login_tbl               pl_last_update_login_tbl;
  gt_pl_pallet_weight_tbl                   pl_pallet_weight_tbl;
  -- �o�^�p(�ړ����b�g�ڍ׃A�h�I��)
  gt_pm_mov_lot_dtl_id_tbl                  pm_mov_lot_dtl_id_tbl;
  gt_pm_mov_line_id_tbl                     pm_mov_line_id_tbl;
  gt_pm_document_type_code_tbl              pm_document_type_code_tbl;
  gt_pm_record_type_code_tbl                pm_record_type_code_tbl;
  gt_pm_item_id_tbl                         pm_item_id_tbl;
  gt_pm_item_code_tbl                       pm_item_code_tbl;
  gt_pm_lot_id_tbl                          pm_lot_id_tbl;
  gt_pm_lot_no_tbl                          pm_lot_no_tbl;
  gt_pm_actual_date_tbl                     pm_actual_date_tbl;
  gt_pm_actual_quantity_tbl                 pm_actual_quantity_tbl;
  gt_pm_auma_reserve_class_tbl              pm_auma_reserve_class_tbl;
  gt_pm_created_by_tbl                      pm_created_by_tbl;
  gt_pm_creation_date_tbl                   pm_creation_date_tbl;
  gt_pm_last_updated_by_tbl                 pm_last_updated_by_tbl;
  gt_pm_last_update_date_tbl                pm_last_update_date_tbl;
  gt_pm_last_update_login_tbl               pm_last_update_login_tbl;
  gt_pm_request_id_tbl                      pm_request_id_tbl;
  gt_pm_program_app_id_tbl                  pm_program_app_id_tbl;
  gt_pm_program_id_tbl                      pm_program_id_tbl;
  gt_pm_program_update_date_tbl             pm_program_update_date_tbl;
--
  gt_pl_up_flg                gt_pl_up_flg_type;
  gt_ph_up_flg                gt_ph_up_flg_type;
  gt_ship_method_tbl          gt_ship_method_tbl_type;
  --gt_small_amount_class_tbl   gt_small_amount_class_tbl_type;
--
  -- �f�[�^�_���v�pPL/SQL�\
  warn_dump_tab          msg_ttype; -- �x��
  normal_dump_tab        msg_ttype; -- ����
--
  gv_min_date                 VARCHAR2(10);            -- �ŏ����t
  gv_max_date                 VARCHAR2(10);            -- �ő���t
--
  -- PL/SQL�\�J�E���g
  gn_warn_msg_cnt           NUMBER := 0; -- �x���G���[���b�Z�[�WPL/SQ�\ �J�E���g
  gn_normal_cnt             NUMBER := 0; -- ����G���[���b�Z�[�WPL/SQ�\ �J�E���g
--
  -- �J�E���g�ϐ�
  gn_i                      NUMBER;           -- �J�E���g�ϐ�(�ړ����b�g�ڍגP��)
  gn_j                      NUMBER;           -- �J�E���g�ϐ�(�󒍖��גP��)
  gn_k                      NUMBER;           -- �J�E���g�ϐ�(�󒍃w�b�_�P��)
  -- ���ʍ��v�p�ϐ�
  gn_lot_sum                NUMBER;           -- ���ʍ��v�p�ϐ�(���b�g�P��)
--
  gd_sysdate                DATE;             -- �V�X�e�����t
  gn_user_id                NUMBER;           -- ���[�UID
  gn_login_id               NUMBER;           -- �ŏI�X�V���O�C��
  gn_conc_request_id        NUMBER;           -- �v��ID
  gn_prog_appl_id           NUMBER;           -- �ݶ��āE��۸��т̱��ع����ID
  gn_conc_program_id        NUMBER;           -- �R���J�����g�E�v���O����ID
--
  -- �v���t�@�C���E�I�v�V����
  gv_item_div_prf           VARCHAR2(100);    -- �v���t�@�C���u���i�敪(�Z�L�����e�B)�v
--
  -- �u���C�N�p�ϐ�
  gv_pre_order_header_id    xxwsh_order_headers_all.order_header_id%TYPE;
--
  -- ���דK�p�ێ��p�ϐ�
  gv_line_description       xxwsh_order_lines_all.line_description%TYPE;
--
  -- ===================================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===================================
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : ��������(H-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_max_date_name CONSTANT VARCHAR2(100) := 'MAX���t';
    lv_min_date_name CONSTANT VARCHAR2(100) := 'MIN���t';
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
    -- �V�X�e�����t�擾
    gd_sysdate := SYSDATE;
    -- WHO�J�������擾
    gn_user_id          := FND_GLOBAL.USER_ID;              -- ���[�UID
    gn_login_id         := FND_GLOBAL.LOGIN_ID;             -- �ŏI�X�V���O�C��
    gn_conc_request_id  := FND_GLOBAL.CONC_REQUEST_ID;      -- �v��ID
    gn_prog_appl_id     := FND_GLOBAL.PROG_APPL_ID;         -- �ݶ��āE��۸��т̱��ع����ID
    gn_conc_program_id  := FND_GLOBAL.CONC_PROGRAM_ID;      -- �R���J�����g�E�v���O����ID
--
    -- ===========================
    -- �v���t�@�C���I�v�V�����擾
    -- ===========================
--
    -- �v���t�@�C���u���i�敪�v�擾
    gv_item_div_prf   := FND_PROFILE.VALUE(gv_item_div_id);
--
    -- =========================================
    -- �v���t�@�C���I�v�V�����擾�G���[�`�F�b�N
    -- =========================================
--
    IF (gv_item_div_prf IS NULL) THEN 
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn                   -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10002          -- ���b�Z�[�W:APP-XXCMN-10002 �v���t�@�C���擾�G���[
                       ,gv_tkn_ng_profile          -- �g�[�N��:NG�v���t�@�C����
                       ,gv_tkn_prod_class_code)    -- XXCMN:���i�敪
                     ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�ő���t�擾
    gv_max_date := SUBSTR(FND_PROFILE.VALUE('XXCMN_MAX_DATE'),1,10);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_max_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10156,
                                            gv_tkn_name,
                                            lv_max_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --�ŏ����t�擾
    gv_min_date := SUBSTR(FND_PROFILE.VALUE('XXCMN_MIN_DATE'),1,10);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_min_date IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10156,
                                            gv_tkn_name,
                                            lv_min_date_name);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  /**********************************************************************************
   * Procedure Name   : check_can_enc_qty
   * Description      : �����\���`�F�b�N����(H-2)
   ***********************************************************************************/
  PROCEDURE check_can_enc_qty(
    iv_data_class        IN         VARCHAR2,      -- 1.�f�[�^���
    iv_deliver_from      IN         VARCHAR2,      -- 2.�q��
    iv_shipped_date_from IN         VARCHAR2,      -- 3.�o�ɓ�FROM
    iv_shipped_date_to   IN         VARCHAR2,      -- 4.�o�ɓ�TO
    iv_instruction_dept  IN         VARCHAR2,      -- 5.�w������
    iv_security_kbn      IN         VARCHAR2,      -- 6.�Z�L�����e�B�敪
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_can_enc_qty'; -- �v���O������
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
    ln_can_enc_qty           NUMBER;            -- �����\��
    ln_check_qty             NUMBER;            -- �`�F�b�N�p�ϐ�
    lv_inventory_location_id   xxcmn_item_locations_v.inventory_location_id%TYPE; -- OPM�ۊǑq��ID
    lv_whse_name               xxcmn_item_locations_v.whse_name%TYPE;             -- �q�ɃR�[�h
    lv_item_id                 ic_lots_mst.item_id%TYPE;                          -- �i��ID
    lv_item_no                 xxcmn_item_mst2_v.item_no%TYPE;                    -- �i�ڃR�[�h
    lv_lot_id                  ic_lots_mst.lot_id%TYPE;                           -- ���b�gID
    lv_lot_no                  ic_lots_mst.lot_no%TYPE;                           -- ���b�gNo
    lv_shipped_date            xxwsh_order_headers_all.shipped_date%TYPE;         -- �o�ɗ\���
    lv_item_class_code         xxcmn_item_categories4_v.item_class_code%TYPE;     -- �i�ڋ敪
    lv_prod_class_code         xxcmn_item_categories4_v.prod_class_code%TYPE;     -- ���i�敪
    lv_conv_unit               xxcmn_item_mst2_v.conv_unit%TYPE;                  -- ���o�Ɋ��Z�P��
    lv_num_of_cases            xxcmn_item_mst2_v.num_of_cases%TYPE;               -- �P�[�X���萔
    lv_sum_reserved_quantity   xxpo_lot_reserve_if.reserved_quantity%TYPE;        -- �������ʍ��v
    lv_sum_quantity            xxwsh_order_lines_all.quantity%TYPE;               -- �w�����ʍ��v
--
    -- *** ���[�J���E�J�[�\�� ***
  -- �����\���`�F�b�N�J�[�\��
    CURSOR chk_can_enc_qty_cur
    IS
      SELECT ilm.item_id                   item_id                -- �i��ID
            ,ximv2.item_no                 item_no                -- �i�ڃR�[�h
            ,ilm.lot_id                    lot_id                 -- ���b�gID
            ,ilm.lot_no                    lot_no                 -- ���b�gNo
            ,xlris.sum_reserved_quantity   sum_reserved_quantity  -- �������ʍ��v
            ,xlris.inventory_location_id   inventory_location_id  -- �ۊǑq��ID
            ,xlris.whse_name               whse_name              -- �q�ɖ�(���b�Z�[�W�o�͗p)
            ,xlris.shipped_date            shipped_date           -- �o�ד�
      FROM  (SELECT xlri.item_code
                   ,xlri.lot_no
                   ,xilv.inventory_location_id
                   ,xilv.whse_name
                   ,NVL(xoha.shipped_date, xoha.schedule_ship_date) shipped_date
                   ,SUM(xlri.reserved_quantity) sum_reserved_quantity
             FROM   xxpo_lot_reserve_if        xlri                  -- ���b�g�������IF
                   ,xxwsh_order_headers_all    xoha                  -- �󒍃w�b�_�A�h�I��
                   ,xxwsh_order_lines_all      xola                  -- �󒍖��׃A�h�I��
                   ,xxcmn_item_locations2_v    xilv                  -- OPM�ۊǏꏊ���VIEW2
                   ,xxcmn_item_locations2_v    xilv2                 -- OPM�ۊǏꏊ���VIEW2
                   ,xxcmn_item_mst2_v          ximv                  -- OPM�i�ڏ��VIEW2
             WHERE  xlri.request_no            = xola.request_no(+)
             AND    xlri.item_code             = xola.shipping_item_code(+)
             AND    xola.order_header_id       = xoha.order_header_id
             AND    xoha.deliver_from          = xilv.segment1
             AND    xilv.frequent_whse         = xilv2.segment1(+)
             AND    xlri.data_class            = iv_data_class
             AND    xola.shipping_inventory_item_id = ximv.inventory_item_id
             AND    ximv.start_date_active    <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
             AND    ximv.end_date_active      >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
             AND    xilv.date_from            <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
             AND    (xilv.date_to             >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
               OR   xilv.date_to IS NULL)
             AND    xilv.disable_date IS NULL
             AND    xilv2.date_from           <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
             AND    (xilv2.date_to            >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
               OR   xilv2.date_to IS NULL)
             AND    xilv2.disable_date IS NULL
             AND    xola.delete_flag           = gv_flg_n
             AND    xoha.latest_external_flag  = gv_flg_y
             AND    xilv.segment1              = iv_deliver_from
             AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) >= FND_DATE.STRING_TO_DATE(iv_shipped_date_from, gv_yyyymmddhh24miss)
             AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) <= FND_DATE.STRING_TO_DATE(iv_shipped_date_to, gv_yyyymmddhh24miss)
             AND    xoha.instruction_dept      = iv_instruction_dept
             AND   ((iv_security_kbn        = gv_security_kbn_in)   -- �Z�L�����e�B�敪 1:�ɓ������[�U�[
               OR  (((iv_security_kbn       = gv_security_kbn_out)  -- �Z�L�����e�B�敪 4:���m�u�����[�U�[
                 AND ((xilv.segment1 IN (             -- ���O�C�����[�U�[�̕ۊǏꏊ�Ɠ����ۊǏꏊ
                   SELECT xilv3.segment1    segment1                      -- �����R�[�h(�d����R�[�h)
                   FROM   fnd_user           fu                           -- ���[�U�[�}�X�^
                         ,per_all_people_f   papf                         -- �]�ƈ��}�X�^
                         ,xxcmn_item_locations2_v xilv3                   -- OPM�ۊǏꏊ���VIEW2
                   WHERE  -- ** �������� ** --
                          fu.employee_id   = papf.person_id               -- �]�ƈ�ID
                          -- ** ���o���� ** --
                   AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- �K�p�J�n��
                   AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- �K�p�I����
                   AND    fu.start_date             <= TRUNC(SYSDATE)     -- �K�p�J�n��
                   AND  ((fu.end_date               IS NULL)              -- �K�p�I����
                     OR  (fu.end_date               >= TRUNC(SYSDATE)))
                   AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ���[�U�[ID
                   AND    papf.attribute4            = xilv3.purchase_code))
                OR (xilv.frequent_whse_code IN (   -- ���O�C�����[�U�[�̕ۊǏꏊ����Ǒq�ɂƂ���ۊǏꏊ
                   SELECT xilv3.segment1    segment1                      -- �����R�[�h(�d����R�[�h)
                   FROM   fnd_user           fu                           -- ���[�U�[�}�X�^
                         ,per_all_people_f   papf                         -- �]�ƈ��}�X�^
                         ,xxcmn_item_locations2_v xilv3                   -- OPM�ۊǏꏊ���VIEW2
                   WHERE  -- ** �������� ** --
                          fu.employee_id   = papf.person_id               -- �]�ƈ�ID
                          -- ** ���o���� ** --
                   AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- �K�p�J�n��
                   AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- �K�p�I����
                   AND    fu.start_date             <= TRUNC(SYSDATE)     -- �K�p�J�n��
                   AND  ((fu.end_date               IS NULL)              -- �K�p�I����
                     OR  (fu.end_date               >= TRUNC(SYSDATE)))
                   AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ���[�U�[ID
                   AND    papf.attribute4            = xilv3.purchase_code)))))) 
             AND    xoha.req_status            >= gv_transaction_status_07
             AND    xoha.req_status            < gv_transaction_status_08
             GROUP BY xlri.item_code, xlri.lot_no, xilv.inventory_location_id, xilv.whse_name, xoha.shipped_date, xoha.schedule_ship_date) xlris
          ,xxcmn_item_mst2_v           ximv2                 -- OPM�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v    xicv                  -- OPM�i�ڃJ�e�S���������VIEW4
          ,ic_lots_mst                 ilm                   -- OPM���b�g�}�X�^
    WHERE
           xlris.item_code            = ximv2.item_no(+)
    AND    xlris.lot_no               = ilm.lot_no
    AND    ximv2.item_id              = xicv.item_id
    AND    ilm.item_id                = ximv2.item_id
    AND    ximv2.start_date_active    <= xlris.shipped_date
    AND    ximv2.end_date_active      >= xlris.shipped_date;
--
    -- �J�[�\���p���R�[�h
    chk_cur  chk_can_enc_qty_cur%ROWTYPE;
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
--
    -- =========================================
    -- �����\���`�F�b�N����
    -- =========================================
    BEGIN
--
      OPEN chk_can_enc_qty_cur;
      FETCH chk_can_enc_qty_cur INTO chk_cur;
      
      WHILE (chk_can_enc_qty_cur%FOUND)
        LOOP
        lv_inventory_location_id   := chk_cur.inventory_location_id;
        lv_whse_name               := chk_cur.whse_name;
        lv_item_id                 := chk_cur.item_id;
        lv_lot_id                  := chk_cur.lot_id;
        lv_item_no                 := chk_cur.item_no;
        lv_lot_no                  := chk_cur.lot_no;
        lv_shipped_date            := chk_cur.shipped_date;
        lv_sum_reserved_quantity   := chk_cur.sum_reserved_quantity;
--
        BEGIN
          SELECT NVL(SUM(xmld.actual_quantity), 0)
          INTO  lv_sum_quantity
          FROM   xxpo_lot_reserve_if        xlri                  -- ���b�g�������IF
                ,xxwsh_order_headers_all    xoha                  -- �󒍃w�b�_�A�h�I��
                ,xxwsh_order_lines_all      xola                  -- �󒍖��׃A�h�I��
                ,xxcmn_item_locations2_v    xilv                  -- OPM�ۊǏꏊ���VIEW2
                ,xxcmn_item_locations2_v    xilv2                 -- OPM�ۊǏꏊ���VIEW2
                ,xxcmn_item_mst2_v          ximv                  -- OPM�i�ڏ��VIEW2
                ,xxinv_mov_lot_details      xmld                  -- �ړ����b�g�ڍ׃A�h�I��
          WHERE  xlri.request_no            = xola.request_no(+)
          AND    xlri.item_code             = xola.shipping_item_code(+)
          AND    xola.order_line_id         = xmld.mov_line_id
          AND    xola.order_header_id       = xoha.order_header_id
          AND    xoha.deliver_from          = xilv.segment1
          AND    xilv.frequent_whse         = xilv2.segment1(+)
          AND    xlri.data_class            = iv_data_class
          AND    xlri.item_code             = lv_item_no
          AND    xlri.lot_no                = lv_lot_no
          AND    xmld.lot_no                = lv_lot_no
          AND    xilv.inventory_location_id = lv_inventory_location_id
          AND    NVL(xoha.shipped_date, xoha.schedule_ship_date) = lv_shipped_date
          AND    xola.shipping_inventory_item_id = ximv.inventory_item_id
          AND    ximv.start_date_active    <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
          AND    ximv.end_date_active      >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
          AND    xilv.date_from            <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
          AND    (xilv.date_to             >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
            OR   xilv.date_to IS NULL)
          AND    xilv.disable_date IS NULL
          AND    xilv2.date_from           <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
          AND    (xilv2.date_to            >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
            OR   xilv2.date_to IS NULL)
          AND    xilv2.disable_date IS NULL
          AND    xola.delete_flag           = gv_flg_n
          AND    xoha.latest_external_flag  = gv_flg_y
          AND    xilv.segment1              = iv_deliver_from
          AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) >= FND_DATE.STRING_TO_DATE(iv_shipped_date_from, gv_yyyymmddhh24miss)
          AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) <= FND_DATE.STRING_TO_DATE(iv_shipped_date_to, gv_yyyymmddhh24miss)
          AND    xoha.instruction_dept      = iv_instruction_dept
          AND   ((iv_security_kbn        = gv_security_kbn_in)   -- �Z�L�����e�B�敪 1:�ɓ������[�U�[
            OR  (((iv_security_kbn       = gv_security_kbn_out)  -- �Z�L�����e�B�敪 4:���m�u�����[�U�[
              AND ((xilv.segment1 IN (             -- ���O�C�����[�U�[�̕ۊǏꏊ�Ɠ����ۊǏꏊ
                SELECT xilv3.segment1    segment1                      -- �����R�[�h(�d����R�[�h)
                FROM   fnd_user           fu                           -- ���[�U�[�}�X�^
                      ,per_all_people_f   papf                         -- �]�ƈ��}�X�^
                      ,xxcmn_item_locations2_v xilv3                   -- OPM�ۊǏꏊ���VIEW2
                WHERE  -- ** �������� ** --
                       fu.employee_id   = papf.person_id               -- �]�ƈ�ID
                       -- ** ���o���� ** --
                AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- �K�p�J�n��
                AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- �K�p�I����
                AND    fu.start_date             <= TRUNC(SYSDATE)     -- �K�p�J�n��
                AND  ((fu.end_date               IS NULL)              -- �K�p�I����
                  OR  (fu.end_date               >= TRUNC(SYSDATE)))
                AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ���[�U�[ID
                AND    papf.attribute4            = xilv3.purchase_code))
             OR (xilv.frequent_whse_code IN (   -- ���O�C�����[�U�[�̕ۊǏꏊ����Ǒq�ɂƂ���ۊǏꏊ
                SELECT xilv3.segment1    segment1                      -- �����R�[�h(�d����R�[�h)
                FROM   fnd_user           fu                           -- ���[�U�[�}�X�^
                      ,per_all_people_f   papf                         -- �]�ƈ��}�X�^
                      ,xxcmn_item_locations2_v xilv3                   -- OPM�ۊǏꏊ���VIEW2
                WHERE  -- ** �������� ** --
                       fu.employee_id   = papf.person_id               -- �]�ƈ�ID
                       -- ** ���o���� ** --
                AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- �K�p�J�n��
                AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- �K�p�I����
                AND    fu.start_date             <= TRUNC(SYSDATE)     -- �K�p�J�n��
                AND  ((fu.end_date               IS NULL)              -- �K�p�I����
                  OR  (fu.end_date               >= TRUNC(SYSDATE)))
                AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ���[�U�[ID
                AND    papf.attribute4            = xilv3.purchase_code)))))) 
          AND    xoha.req_status            >= gv_transaction_status_07
          AND    xoha.req_status            < gv_transaction_status_08
          GROUP BY xlri.item_code, xlri.lot_no, xilv.inventory_location_id, xoha.shipped_date, xoha.schedule_ship_date;
        EXCEPTION
          WHEN OTHERS THEN
            lv_sum_quantity := 0;
        END;
--
        -- �����\���Z�o
        ln_can_enc_qty := xxcmn_common_pkg.get_can_enc_qty(
                                           lv_inventory_location_id,  -- OPM�ۊǑq��ID
                                           lv_item_id,                -- OPM�i��ID
                                           lv_lot_id,                 -- ���b�gID
                                           lv_shipped_date);          -- �o�ɗ\���
--
        -- �W�v�����������ʂƈ����\��(�����������𑫂�����)���`�F�b�N
        -- (�����������Ƃ́A����ړ����b�g�ڍ׏��̐􂢑ւ����s���ׁA�󒍖��ׂ̐��ʂ��S���X�V�����̂ŁA
        --  ���݂̎󒍖��ׂ̎w�����ʂ̍��v�ƂȂ�)
        IF (lv_sum_reserved_quantity > ln_can_enc_qty + lv_sum_quantity) THEN
          -- �x�����b�Z�[�W�o��
          lv_errmsg  := SUBSTRB(
                          xxcmn_common_pkg.get_msg(
                            gv_xxcmn                 -- ���W���[��������:XXCMN
                           ,gv_msg_xxcmn10109        -- ���b�Z�[�W:APP-XXCMN-10109 �����\�݌ɐ����ߒʒm���[�j���O
                           ,gv_tkn_location          -- �g�[�N��:LOCATION
                           ,lv_whse_name             -- �q�ɖ�
                           ,gv_tkn_item              -- �g�[�N��:ITEM
                           ,lv_item_no               -- �i�ڃR�[�h
                           ,gv_tkn_lot               -- �g�[�N��:LOT
                           ,lv_lot_no)               -- ���b�gID
                           ,1,5000);
--
          -- �x���_���vPL/SQL�\�Ɍx�����b�Z�[�W���Z�b�g
          gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
          warn_dump_tab(gn_warn_msg_cnt) := lv_errmsg;
--
          -- ���^�[���E�R�[�h�Ɍx�����Z�b�g
          ov_retcode := gv_status_warn;
        END IF;
--
        FETCH chk_can_enc_qty_cur INTO chk_cur;
--
      END LOOP;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxcmn               -- ���W���[��������:XXCMN
                         ,gv_msg_xxcmn10018      -- ���b�Z�[�W:APP-XXCMN-10018 API�G���[
                         ,gv_tkn_api_name        -- �g�[�N��API_NAME
                         ,gv_tkn_chk_can_qty)    -- �����\���Z�o
                       ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END check_can_enc_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �f�[�^�擾���� (H-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_data_class        IN         VARCHAR2,      -- 1.�f�[�^���
    iv_deliver_from      IN         VARCHAR2,      -- 2.�q��
    iv_shipped_date_from IN         VARCHAR2,      -- 3.�o�ɓ�FROM
    iv_shipped_date_to   IN         VARCHAR2,      -- 4.�o�ɓ�TO
    iv_instruction_dept  IN         VARCHAR2,      -- 5.�w������
    iv_security_kbn      IN         VARCHAR2,      -- 6.�Z�L�����e�B�敪
    ov_errbuf            OUT NOCOPY VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           IN OUT NOCOPY VARCHAR2,   -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- �v���O������
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
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    SELECT xlri.lot_reserve_if_id            -- ���b�g�������C���^�t�F�[�XID
          ,xlri.request_no                   -- �˗�No.
          ,xlri.item_code                    -- �i�ڃR�[�h
          ,xlri.line_description             -- ���דE�v
          ,xlri.lot_no                       -- ���b�gNo.
          ,xlri.reserved_quantity            -- ��������
          ,xola.order_line_id                -- ����ID
          ,xola.quantity                     -- �������ʍ��v
          ,ilm.lot_id                        -- ���b�gID
          ,ximv.item_id                      -- �i��ID
          ,ximv.conv_unit                    -- ���o�Ɋ��Z�P��
          ,ximv.num_of_cases                 -- �P�[�X���萔
          ,xoha.vendor_site_id               -- �z����ID
          ,xoha.deliver_from                 -- ���͕ۊǑq�ɃR�[�h
          ,xoha.schedule_arrival_date        -- ���ח\���
          ,NVL(xoha.shipped_date, xoha.schedule_ship_date) -- �o�ד�
          ,xoha.order_header_id              -- �󒍃w�b�_�A�h�I��ID
          ,ilm.attribute1                    -- �����N����(OPM���b�g�}�X�^)
          ,xicv.prod_class_code              -- ���i�敪
          ,xicv.item_class_code              -- �i�ڋ敪
          ,xoha.vendor_site_code             -- �z����R�[�h
          ,xoha.weight_capacity_class        -- �d�ʗe�ϋ敪
          ,xoha.shipping_method_code         -- �z���敪
-- ST�s��Ή� modify 2008/07/29 start
          ,xoha.freight_charge_class         -- �^���敪
-- ST�s��Ή� modify 2008/07/29 end
-- 2008/08/22 Add ��
          ,ximv.lot_ctl                      -- ���b�g
-- 2008/08/22 Add ��
          ,xlri.corporation_name                || gv_msg_comma ||
           xlri.data_class                      || gv_msg_comma ||
           xlri.transfer_branch_no              || gv_msg_comma ||
           xlri.request_no                      || gv_msg_comma ||
           xlri.item_code                       || gv_msg_comma ||
           xlri.line_description                || gv_msg_comma ||
           xlri.lot_no                          || gv_msg_comma ||
           TO_CHAR(xlri.reserved_quantity)     -- �f�[�^�_���v
    BULK COLLECT INTO
            gt_lr_lot_reserve_if_id_tbl,
            gt_lr_request_no_tbl,
            gt_lr_item_code_tbl,
            gt_lr_line_description_tbl,
            gt_lr_lot_no_tbl,
            gt_lr_reserved_quantity_tbl,
            gt_lr_order_line_id_tbl,
            gt_lr_quantity_tbl,
            gt_lr_lot_id_tbl,
            gt_lr_item_id_tbl,
            gt_lr_conv_unit_tbl,
            gt_lr_num_of_cases_tbl,
            gt_lr_deliver_to_id_tbl,
            gt_lr_deliver_from_tbl,
            gt_lr_sche_arrival_date_tbl,
            gt_lr_shipped_date_tbl,
            gt_lr_order_header_id_tbl,
            gt_lr_lot_date_tbl,
            gt_lr_prod_class_code_tbl,
            gt_lr_item_class_code_tbl,
            gt_lr_deliver_to_tbl,
            gt_lr_we_ca_class_tbl,
            gt_lr_shipping_method_code_tbl,
-- ST�s��Ή� modify 2008/07/29 start
            gt_lr_freight_charge_class_tbl,
-- ST�s��Ή� modify 2008/07/29 end
-- 2008/08/22 Add ��
            gt_lr_lot_ctl_tbl,
-- 2008/08/22 Add ��
            gt_lr_data_dump_tbl
    FROM   xxpo_lot_reserve_if         xlri                  -- ���b�g�������C���^�t�F�[�X
          ,xxwsh_order_headers_all     xoha                  -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all       xola                  -- �󒍖��׃A�h�I��
          ,xxcmn_item_mst2_v           ximv                  -- OPM�i�ڏ��VIEW2
          ,xxcmn_item_mst2_v           ximv2                 -- OPM�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v    xicv                  -- OPM�i�ڃJ�e�S���������VIEW4
          ,xxcmn_item_locations2_v     xilv                  -- OPM�ۊǏꏊ���VIEW2
          ,xxcmn_item_locations2_v     xilv2                 -- OPM�ۊǏꏊ���VIEW2
          ,ic_lots_mst                 ilm                   -- OPM���b�g�}�X�^
-- 2008/08/22 Mod ��
/*
    WHERE
    -- ** �������� ** --
           xlri.request_no            = xola.request_no(+)
    AND    xlri.item_code             = xola.shipping_item_code(+)
    AND    xlri.item_code             = ximv.item_no(+)
    AND    xola.order_header_id       = xoha.order_header_id
    AND    xoha.deliver_from          = xilv.segment1
    AND    xilv.frequent_whse         = xilv2.segment1(+)
    AND    xola.shipping_inventory_item_id = ximv2.inventory_item_id
    AND    ximv.item_id               = xicv.item_id
    AND    xlri.lot_no                = ilm.lot_no
    AND    ilm.item_id                = ximv.item_id
    AND    ximv.start_date_active    <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    ximv.end_date_active      >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    ximv2.start_date_active   <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    ximv2.end_date_active     >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    xilv.date_from            <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    (xilv.date_to             >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
      OR   xilv.date_to IS NULL)
    AND    xilv.disable_date IS NULL
    AND    xilv2.date_from           <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    (xilv2.date_to            >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
      OR   xilv2.date_to IS NULL)
    AND    xilv2.disable_date IS NULL
    -- ** ���o���� ** --
    AND    xola.delete_flag           = gv_flg_n
    AND    xoha.latest_external_flag  = gv_flg_y
    AND    xlri.data_class            = iv_data_class
    AND    xilv.segment1              = iv_deliver_from
    AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) >= FND_DATE.STRING_TO_DATE(iv_shipped_date_from, gv_yyyymmddhh24miss)
    AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) <= FND_DATE.STRING_TO_DATE(iv_shipped_date_to, gv_yyyymmddhh24miss)
    AND    xoha.instruction_dept      = iv_instruction_dept
    AND   ((iv_security_kbn        = gv_security_kbn_in)   -- �Z�L�����e�B�敪 1:�ɓ������[�U�[
      OR  (((iv_security_kbn       = gv_security_kbn_out)  -- �Z�L�����e�B�敪 4:���m�u�����[�U�[
        AND ((xilv.segment1 IN (             -- ���O�C�����[�U�[�̕ۊǏꏊ�Ɠ����ۊǏꏊ
              SELECT xilv3.segment1    segment1                      -- �����R�[�h(�d����R�[�h)
              FROM   fnd_user           fu                           -- ���[�U�[�}�X�^
                    ,per_all_people_f   papf                         -- �]�ƈ��}�X�^
                    ,xxcmn_item_locations2_v xilv3                   -- OPM�ۊǏꏊ���VIEW2
              WHERE  -- ** �������� ** --
                     fu.employee_id   = papf.person_id               -- �]�ƈ�ID
                     -- ** ���o���� ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- �K�p�I����
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND  ((fu.end_date               IS NULL)              -- �K�p�I����
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ���[�U�[ID
              AND    papf.attribute4            = xilv3.purchase_code))
          OR (xilv.frequent_whse_code IN (   -- ���O�C�����[�U�[�̕ۊǏꏊ����Ǒq�ɂƂ���ۊǏꏊ
              SELECT xilv3.segment1    segment1                      -- �����R�[�h(�d����R�[�h)
              FROM   fnd_user           fu                           -- ���[�U�[�}�X�^
                    ,per_all_people_f   papf                         -- �]�ƈ��}�X�^
                    ,xxcmn_item_locations2_v xilv3                   -- OPM�ۊǏꏊ���VIEW2
              WHERE  -- ** �������� ** --
                     fu.employee_id   = papf.person_id               -- �]�ƈ�ID
                     -- ** ���o���� ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- �K�p�I����
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND  ((fu.end_date               IS NULL)              -- �K�p�I����
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ���[�U�[ID
              AND    papf.attribute4            = xilv3.purchase_code)))))) 
    AND    xoha.req_status            >= gv_transaction_status_07
    AND    xoha.req_status            < gv_transaction_status_08
*/
    WHERE
    -- ** �������� ** --
           xlri.request_no            = xola.request_no(+)
    AND    xlri.item_code             = xola.shipping_item_code(+)
    AND    xlri.item_code             = ximv.item_no(+)
    AND    xola.order_header_id       = xoha.order_header_id(+)
    AND    xoha.deliver_from          = xilv.segment1(+)
    AND    xilv.frequent_whse         = xilv2.segment1(+)
    AND    xola.shipping_inventory_item_id = ximv2.inventory_item_id(+)
    AND    ximv.item_id               = xicv.item_id
    AND    xlri.lot_no                = ilm.lot_no
    AND    ilm.item_id                = ximv.item_id
    AND   (xola.request_no IS NULL
     OR    (ximv.start_date_active    <= NVL(xoha.shipped_date, xoha.schedule_ship_date)
    AND     ximv.end_date_active      >= NVL(xoha.shipped_date, xoha.schedule_ship_date)))
    AND   (xola.request_no IS NULL
     OR    (ximv2.start_date_active   <= NVL(xoha.shipped_date, xoha.schedule_ship_date)
    AND     ximv2.end_date_active     >= NVL(xoha.shipped_date, xoha.schedule_ship_date)))
    AND   (xola.request_no IS NULL
     OR    (xilv.date_from            <= NVL(xoha.shipped_date, xoha.schedule_ship_date)
    AND     (xilv.date_to             >= NVL(xoha.shipped_date, xoha.schedule_ship_date)
      OR    xilv.date_to IS NULL)
    AND     xilv.disable_date IS NULL))
    AND   (xola.request_no IS NULL
     OR    (xilv2.date_from           <= NVL(xoha.shipped_date, xoha.schedule_ship_date)
    AND     (xilv2.date_to            >= NVL(xoha.shipped_date, xoha.schedule_ship_date)
      OR    xilv2.date_to IS NULL)
    AND     xilv2.disable_date IS NULL))
    -- ** ���o���� ** --
    AND   (xola.request_no IS NULL
     OR    xola.delete_flag           = gv_flg_n)
    AND   (xola.request_no IS NULL
     OR    xoha.latest_external_flag  = gv_flg_y)
    AND    xlri.data_class            = iv_data_class
    AND   (xola.request_no IS NULL
     OR    xilv.segment1              = iv_deliver_from)
    AND   (xola.request_no IS NULL
     OR    NVL(xoha.shipped_date, xoha.schedule_ship_date) >= FND_DATE.STRING_TO_DATE(iv_shipped_date_from, gv_yyyymmddhh24miss))
    AND   (xola.request_no IS NULL
     OR    NVL(xoha.shipped_date, xoha.schedule_ship_date) <= FND_DATE.STRING_TO_DATE(iv_shipped_date_to, gv_yyyymmddhh24miss))
    AND   (xola.request_no IS NULL
     OR    xoha.instruction_dept      = iv_instruction_dept)
    AND   (xola.request_no IS NULL
     OR   ((iv_security_kbn        = gv_security_kbn_in)   -- �Z�L�����e�B�敪 1:�ɓ������[�U�[
      OR  (((iv_security_kbn       = gv_security_kbn_out)  -- �Z�L�����e�B�敪 4:���m�u�����[�U�[
        AND ((xilv.segment1 IN (             -- ���O�C�����[�U�[�̕ۊǏꏊ�Ɠ����ۊǏꏊ
              SELECT xilv3.segment1    segment1                      -- �����R�[�h(�d����R�[�h)
              FROM   fnd_user           fu                           -- ���[�U�[�}�X�^
                    ,per_all_people_f   papf                         -- �]�ƈ��}�X�^
                    ,xxcmn_item_locations2_v xilv3                   -- OPM�ۊǏꏊ���VIEW2
              WHERE  -- ** �������� ** --
                     fu.employee_id   = papf.person_id               -- �]�ƈ�ID
                     -- ** ���o���� ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- �K�p�I����
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND  ((fu.end_date               IS NULL)              -- �K�p�I����
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ���[�U�[ID
              AND    papf.attribute4            = xilv3.purchase_code))
          OR (xilv.frequent_whse_code IN (   -- ���O�C�����[�U�[�̕ۊǏꏊ����Ǒq�ɂƂ���ۊǏꏊ
              SELECT xilv3.segment1    segment1                      -- �����R�[�h(�d����R�[�h)
              FROM   fnd_user           fu                           -- ���[�U�[�}�X�^
                    ,per_all_people_f   papf                         -- �]�ƈ��}�X�^
                    ,xxcmn_item_locations2_v xilv3                   -- OPM�ۊǏꏊ���VIEW2
              WHERE  -- ** �������� ** --
                     fu.employee_id   = papf.person_id               -- �]�ƈ�ID
                     -- ** ���o���� ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- �K�p�I����
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND  ((fu.end_date               IS NULL)              -- �K�p�I����
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ���[�U�[ID
              AND    papf.attribute4            = xilv3.purchase_code)))))))
    AND   (xola.request_no IS NULL
     OR    xoha.req_status  >= gv_transaction_status_07)
    AND   (xola.request_no IS NULL
     OR    xoha.req_status  < gv_transaction_status_08)
-- 2008/08/22 Mod ��
    ORDER BY xoha.order_header_id, xola.order_line_id, xlri.lot_no
    FOR UPDATE OF xoha.order_header_id, xola.order_line_id, xlri.lot_reserve_if_id NOWAIT;
--
    -- ���������J�E���g
    gn_target_cnt := gt_lr_lot_reserve_if_id_tbl.COUNT;
--
    -- �f�[�^�擾�G���[
    IF (gt_lr_lot_reserve_if_id_tbl.COUNT = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10229);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --=========================
    --�ړ����b�g�ڍ׃��b�N����
    --=========================
    SELECT   xmld.mov_lot_dtl_id
    BULK COLLECT INTO
           gt_mr_mov_lot_dtl_id_tbl
    FROM   xxpo_lot_reserve_if         xlri                  -- ���b�g�������C���^�t�F�[�X
          ,xxwsh_order_headers_all     xoha                  -- �󒍃w�b�_�A�h�I��
          ,xxwsh_order_lines_all       xola                  -- �󒍖��׃A�h�I��
          ,xxcmn_item_mst2_v           ximv                  -- OPM�i�ڏ��VIEW2
          ,xxcmn_item_mst2_v           ximv2                 -- OPM�i�ڏ��VIEW2
          ,xxcmn_item_categories4_v    xicv                  -- OPM�i�ڃJ�e�S���������VIEW4
          ,xxcmn_item_locations2_v     xilv                  -- OPM�ۊǏꏊ���VIEW2
          ,xxcmn_item_locations2_v     xilv2                 -- OPM�ۊǏꏊ���VIEW2
          ,ic_lots_mst                 ilm                   -- OPM���b�g�}�X�^
          ,xxinv_mov_lot_details       xmld                  -- �ړ����b�g�ڍ׃A�h�I��
    WHERE
           xlri.request_no            = xola.request_no(+)
    AND    xlri.item_code             = xola.shipping_item_code(+)
    AND    xlri.item_code             = ximv.item_no(+)
    AND    xola.order_header_id       = xoha.order_header_id
    AND    xoha.deliver_from          = xilv.segment1
    AND    xilv.frequent_whse         = xilv2.segment1(+)
    AND    xola.shipping_inventory_item_id = ximv2.inventory_item_id
    AND    ximv.item_id               = xicv.item_id
    AND    xlri.lot_no                = ilm.lot_no
    AND    ilm.item_id                = ximv.item_id
    AND    ximv.start_date_active    <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    ximv.end_date_active      >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    ximv2.start_date_active   <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    ximv2.end_date_active     >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    xilv.date_from            <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    (xilv.date_to             >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
      OR   xilv.date_to IS NULL)
    AND    xilv.disable_date IS NULL
    AND    xilv2.date_from           <= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
    AND    (xilv2.date_to            >= NVL(xoha.shipped_date, (xoha.schedule_ship_date))
      OR   xilv2.date_to IS NULL)
    AND    xilv2.disable_date IS NULL
    AND    xola.delete_flag           = gv_flg_n
    AND    xoha.latest_external_flag  = gv_flg_y
    AND    xlri.data_class            = iv_data_class
    AND    xilv.segment1              = iv_deliver_from
    AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) >= FND_DATE.STRING_TO_DATE(iv_shipped_date_from, gv_yyyymmddhh24miss)
    AND    NVL(xoha.shipped_date, (xoha.schedule_ship_date)) <= FND_DATE.STRING_TO_DATE(iv_shipped_date_to, gv_yyyymmddhh24miss)
    AND    xoha.instruction_dept      = iv_instruction_dept
    AND   ((iv_security_kbn        = gv_security_kbn_in)   -- �Z�L�����e�B�敪 1:�ɓ������[�U�[
      OR  (((iv_security_kbn       = gv_security_kbn_out)  -- �Z�L�����e�B�敪 4:���m�u�����[�U�[
        AND ((xilv.segment1 IN (             -- ���O�C�����[�U�[�̕ۊǏꏊ�Ɠ����ۊǏꏊ
              SELECT xilv3.segment1    segment1                      -- �����R�[�h(�d����R�[�h)
              FROM   fnd_user           fu                           -- ���[�U�[�}�X�^
                    ,per_all_people_f   papf                         -- �]�ƈ��}�X�^
                    ,xxcmn_item_locations2_v xilv3                   -- OPM�ۊǏꏊ���VIEW2
              WHERE  -- ** �������� ** --
                     fu.employee_id   = papf.person_id               -- �]�ƈ�ID
                     -- ** ���o���� ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- �K�p�I����
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND  ((fu.end_date               IS NULL)              -- �K�p�I����
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ���[�U�[ID
              AND    papf.attribute4            = xilv3.purchase_code))
          OR (xilv.frequent_whse_code IN (   -- ���O�C�����[�U�[�̕ۊǏꏊ����Ǒq�ɂƂ���ۊǏꏊ
              SELECT xilv3.segment1    segment1                      -- �����R�[�h(�d����R�[�h)
              FROM   fnd_user           fu                           -- ���[�U�[�}�X�^
                    ,per_all_people_f   papf                         -- �]�ƈ��}�X�^
                    ,xxcmn_item_locations2_v xilv3                   -- OPM�ۊǏꏊ���VIEW2
              WHERE  -- ** �������� ** --
                     fu.employee_id   = papf.person_id               -- �]�ƈ�ID
                     -- ** ���o���� ** --
              AND    papf.effective_start_date <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND    papf.effective_end_date   >= TRUNC(SYSDATE)     -- �K�p�I����
              AND    fu.start_date             <= TRUNC(SYSDATE)     -- �K�p�J�n��
              AND  ((fu.end_date               IS NULL)              -- �K�p�I����
                OR  (fu.end_date               >= TRUNC(SYSDATE)))
              AND    fu.user_id                 = FND_GLOBAL.USER_ID -- ���[�U�[ID
              AND    papf.attribute4            = xilv3.purchase_code)))))) 
    AND    xoha.req_status            >= gv_transaction_status_07
    AND    xoha.req_status            < gv_transaction_status_08
    AND    xmld.mov_line_id           = xola.order_line_id
    FOR UPDATE OF xmld.mov_lot_dtl_id NOWAIT;
--
  EXCEPTION
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
    -- ���b�N�G���[
    WHEN check_lock_expt THEN
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxcmn               -- ���W���[��������:XXCMN
                       ,gv_msg_xxcmn10019      -- ���b�Z�[�W:APP-XXCMN-10019 ���b�N�G���[
                       ,gv_tkn_table           -- �g�[�N��TABLE
                       ,gv_tkn_date)           -- "�Ώۃf�[�^"
                       ,1,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : check_data
   * Description      : �擾�f�[�^�`�F�b�N����(H-4)
   ***********************************************************************************/
  PROCEDURE check_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    IN OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data'; -- �v���O������    -- �e�[�u��(�r���[)��
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_errmsg_code     VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W�E�R�[�h
    on_result          NUMBER;          -- ��������
    od_reversal_date   DATE;            -- �t�]���t
    od_standard_date   DATE;            -- ����t
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
--
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_cnt NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
    ln_cnt     := 0;
--
--###########################  �Œ蕔 END   ############################
--
-- 2008/08/22 Del ��
/*
    -- ===========================
    -- �������s���`�F�b�N
    -- ===========================
    -- �{���K�{�ł��郍�b�gNo���A�˗�No.�A�i�ڃR�[�h�̕R�t���łƂ�Ȃ������ꍇ�A
    -- ���b�g�������IF�e�[�u���Ɏ󒍖��ׂ̑S�Ă̏�񂪐ݒ肳��Ă��Ȃ��Ɣ��f���A�G���[�Ƃ���B
    SELECT COUNT(1)
    INTO   ln_cnt
    FROM   xxwsh_order_headers_all xoha
          ,xxwsh_order_lines_all   xola
          ,xxpo_lot_reserve_if     xlri
    WHERE  xoha.request_no         = gt_lr_request_no_tbl(gn_i)  -- �˗�No.
    AND    xoha.order_header_id    = xola.order_header_id        -- �󒍃w�b�_ID
    AND    xola.request_no         = xlri.request_no(+)          -- �˗�No.
    AND    xola.shipping_item_code = xlri.item_code(+)           -- �i�ڃR�[�h
    AND    xlri.lot_no             IS NULL                       -- ���b�gNo
    AND    xola.delete_flag           = gv_flg_n
    AND    xoha.latest_external_flag  = gv_flg_y
    AND    ROWNUM                  = 1
    ;
--
    -- 1���ȏ�̏ꍇ�A�G���[
    IF (ln_cnt > 0) THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo               -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10262     -- ���b�Z�[�W:APP-XXPO-10234 �������s���G���[
                       ,gv_tkn_item          -- �g�[�N��:ITEM
                       ,gt_lr_request_no_tbl(gn_i))    -- �󒍃w�b�_�A�h�I��
                       ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
*/
-- 2008/08/22 Del ��
    -- ===========================
    -- �󒍃w�b�_�A�h�I�����݃`�F�b�N
    -- ===========================
    SELECT COUNT(1)
    INTO   ln_cnt
    FROM   xxwsh_order_headers_all xoha  -- �󒍃w�b�_�A�h�I��
    WHERE  xoha.request_no = gt_lr_request_no_tbl(gn_i)          -- �˗�No.
    AND    ROWNUM         = 1
    ;
    -- 0���̏ꍇ�A�G���[
    IF (ln_cnt = 0) THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo               -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10234     -- ���b�Z�[�W:APP-XXPO-10234 ���݃`�F�b�N�G���[
                       ,gv_tkn_table          -- �g�[�N��:TABLE
                       ,gv_tkn_xxpo_headers_all)    -- �󒍃w�b�_�A�h�I��
                       ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
--
    -- ===========================
    -- �󒍖��׃A�h�I�����݃`�F�b�N
    -- ===========================
    SELECT COUNT(1)
    INTO   ln_cnt
    FROM   xxwsh_order_lines_all xola  -- �󒍖��׃A�h�I��
    WHERE  xola.request_no = gt_lr_request_no_tbl(gn_i)          -- �˗�No.
    AND    xola.shipping_item_code = gt_lr_item_code_tbl(gn_i)           -- �i�ڃR�[�h
    AND    ROWNUM         = 1
    ;
    -- 0���̏ꍇ�A�G���[
    IF (ln_cnt = 0) THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10234       -- ���b�Z�[�W:APP-XXPO-10234 ���݃`�F�b�N�G���[
                       ,gv_tkn_table           -- �g�[�N��:TABLE
                       ,gv_tkn_xxpo_lines_all) -- �󒍖��׃A�h�I��
                       ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
--
-- 2008/08/22 Add ��
    -- ===========================
    -- �������s���`�F�b�N
    -- ===========================
    -- �{���K�{�ł��郍�b�gNo���A�˗�No.�A�i�ڃR�[�h�̕R�t���łƂ�Ȃ������ꍇ�A
    -- ���b�g�������IF�e�[�u���Ɏ󒍖��ׂ̑S�Ă̏�񂪐ݒ肳��Ă��Ȃ��Ɣ��f���A�G���[�Ƃ���B
    SELECT COUNT(1)
    INTO   ln_cnt
    FROM   xxwsh_order_headers_all xoha
          ,xxwsh_order_lines_all   xola
          ,xxpo_lot_reserve_if     xlri
    WHERE  xoha.request_no         = gt_lr_request_no_tbl(gn_i)  -- �˗�No.
    AND    xoha.order_header_id    = xola.order_header_id        -- �󒍃w�b�_ID
    AND    xola.request_no         = xlri.request_no(+)          -- �˗�No.
    AND    xola.shipping_item_code = xlri.item_code(+)           -- �i�ڃR�[�h
    AND    xlri.lot_no             IS NULL                       -- ���b�gNo
    AND    xola.delete_flag           = gv_flg_n
    AND    xoha.latest_external_flag  = gv_flg_y
    AND    ROWNUM                  = 1
    ;
--
    -- 1���ȏ�̏ꍇ�A�G���[
    IF (ln_cnt > 0) THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo               -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10262     -- ���b�Z�[�W:APP-XXPO-10234 �������s���G���[
                       ,gv_tkn_item          -- �g�[�N��:ITEM
                       ,gt_lr_request_no_tbl(gn_i))    -- �󒍃w�b�_�A�h�I��
                       ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END IF;
-- 2008/08/22 Add ��
--
-- 2008/08/22 Add ��
    -- ���b�g�Ǘ��i�̏ꍇ
    IF (gt_lr_lot_ctl_tbl(gn_i) = gv_flg_on) THEN
      -- ===========================
      -- ���b�g�X�e�[�^�X�`�F�b�N
      -- ===========================
      SELECT COUNT(1)
      INTO   ln_cnt
      FROM   ic_lots_mst           ilm,     -- ���b�g�}�X�^
             xxcmn_lot_status_v    xlsv     -- ���b�g�X�e�[�^�X�r���[
      WHERE  xlsv.lot_status(+)           = ilm.attribute23
      AND    ilm.lot_id                   = gt_lr_lot_id_tbl(gn_i)
      AND    ilm.attribute1              >= gt_lr_lot_date_tbl(gn_i)   -- �w�萻����
      AND    xlsv.pay_provision_m_reserve = gv_flg_y                   -- �L���x��(�蓮����)
      AND    ROWNUM         = 1
      ;
      -- 0���̏ꍇ�A�G���[
      IF (ln_cnt = 0) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(
                        gv_xxpo                  -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10267         -- ���b�Z�[�W:APP-XXPO-10267 ���b�g�X�e�[�^�X�G���[
                       ,gv_tkn_lot_no            -- �g�[�N��:LOT_NO
                       ,gt_lr_lot_no_tbl(gn_i)); -- ���b�gNo
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      END IF;
    END IF;
-- 2008/08/22 Add ��
--
    -- ===========================
    -- �������ʃ`�F�b�N(0�A�}�C�i�X�`�F�b�N)
    -- ===========================
    IF (gt_lr_reserved_quantity_tbl(gn_i) <= 0) THEN
      lv_errmsg  := SUBSTRB(
                      xxcmn_common_pkg.get_msg(
                        gv_xxpo                -- ���W���[��������:XXPO
                       ,gv_msg_xxpo10255       -- ���b�Z�[�W:APP-XXPO-10255 ���l0�ȉ��G���[
                       ,gv_tkn_item            -- �g�[�N��:ITEM
                       ,gv_tkn_reserve_qty)    -- ��������
                       ,1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END check_data;
--
  /**********************************************************************************
   * Procedure Name   : get_other_data
   * Description      : �֘A�f�[�^�擾����(H-5)
   ***********************************************************************************/
  PROCEDURE get_other_data(
    iv_type       IN  VARCHAR2,     --   �w�b�_/���׋敪
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    IN OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_other_data'; -- �v���O������
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
    ln_result             NUMBER;               -- �u�ő�z���敪�Z�o�֐��v�Ԃ�l
    lv_errmsg_code        VARCHAR2(5000);       -- �G���[���b�Z�[�W�R�[�h
    ln_small_quantity     NUMBER;               -- ������
    ln_sum_quantity       NUMBER;               -- �������ʍ��v
    -- ���g�p
    ln_palette_max_qty              NUMBER;        -- �p���b�g�ő喇��
    ln_drink_deadweight_tbl         NUMBER;        -- �h�����N�ύڏd��
    ln_leaf_deadweight_tbl          NUMBER;        -- ���[�t�ύڏd��
    ln_drink_loading_capacity_tbl   NUMBER;        -- �h�����N�ύڗe��
    ln_leaf_loading_capacity_tbl    NUMBER;        -- ���[�t�ύڗe��
    ln_sum_pallet_weight            NUMBER;        -- ���v�p���b�g�d��
    ln_sum_weight                   NUMBER;        -- ���v�d��
    ln_sum_capacity                 NUMBER;        -- ���v�e��
    lv_load_efficiency_we           NUMBER;        -- �d�ʐύڌ���
    lv_load_efficiency_ca           NUMBER;        -- �e�ϐύڌ���
    lv_loading_over_class           VARCHAR2(100); -- �ύڃI�[�o�[�敪
    lv_ship_methods                 VARCHAR2(100); -- �o�ו��@
    lv_mixed_ship_method            VARCHAR2(100); -- ���ڔz���敪
    lv_small_amount_class           VARCHAR2(1);   -- �����敪
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���[�J���ϐ��̏�����
    ln_result         := NULL;
    lv_retcode        := NULL;
    lv_errmsg_code    := NULL;
    lv_errmsg         := NULL;
    ln_small_quantity := NULL;
    ln_sum_quantity   := NULL;

--
    IF (iv_type = gv_header) THEN
      -- ST�s� modify 2008/07/29 start
      -- �^���敪��ON�̏ꍇ�̂݁A�擾�B
      IF (gt_lr_freight_charge_class_tbl(gn_i) = gv_freight_charge_class_on) THEN
        ---------------------------------------------
        -- �ő�z���敪�擾                        --
        ---------------------------------------------
        -- ���ʊ֐��u�ő�z���敪�Z�o�֐��v�Ăяo��
        ln_result := xxwsh_common_pkg.get_max_ship_method
                               (cv_wh,                                      -- �q��'4'
                                gt_lr_deliver_from_tbl(gn_i),               -- ���͑q�ɃR�[�h
                                cv_sup,                                     -- �x����'11'
                                gt_lr_deliver_to_tbl(gn_i),                 -- �z����R�[�h
                                gv_item_div_prf,                            -- ���i�敪
                                gt_lr_we_ca_class_tbl(gn_i),                -- �d�ʗe�ϋ敪
                                NULL,                                       -- �����z�ԑΏۋ敪
                                gt_lr_shipped_date_tbl(gn_i),               -- �o�ɗ\���
                                gt_ship_method_tbl(gn_k),                   -- �ő�z���敪
                                ln_drink_deadweight_tbl,                    -- �h�����N�ύڏd��
                                ln_leaf_deadweight_tbl,                     -- ���[�t�ύڏd��
                                ln_drink_loading_capacity_tbl,              -- �h�����N�ύڗe��
                                ln_leaf_loading_capacity_tbl,               -- ���[�t�ύڗe��
                                ln_palette_max_qty                          -- �p���b�g�ő喇��
                               );
--
        -- ���ʊ֐��ŃG���[�̏ꍇ
        IF (ln_result = 1) THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                                gv_msg_xxpo10237,
                                                gv_tkn_common_name,
                                                gv_max_ship);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      -- �s�v�ׁ̈A�폜
      /*-- �����敪�̐ݒ�
      BEGIN
        SELECT attribute6
        INTO   lv_small_amount_class
        FROM   xxcmn_lookup_values2_v
        WHERE  lookup_type = gv_lookup_type_xsm
        AND    lookup_code = gt_ship_method_tbl(gn_k);
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                                gv_msg_xxpo10234,
                                                gv_tkn_table,
                                                gv_tkn_xxcmn_lookup_values2);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
      END;
--
      gt_small_amount_class_tbl(gn_k) := lv_small_amount_class;*/
-- ST�s��Ή� modify 2008/07/29 end
--
      -- �ϐ��̏�����(�������W�b�N�p)
      gt_ph_sum_weight_tbl(gn_k)        := NULL;
      gt_ph_sum_capacity_tbl(gn_k)      := NULL;
      gt_ph_sum_pallet_weight_tbl(gn_k) := NULL;
      gt_ph_small_quantity_tbl(gn_k)    := NULL;
      gt_ph_label_quantity_tbl(gn_k)    := NULL;
      gt_ph_sum_quantity_tbl(gn_k)      := NULL;
--
      -- �w�����ʍX�V�t���O�̏����ݒ�(�w�b�_�p)
      gt_ph_up_flg(gn_k) := gv_flg_off;
--
    ELSIF (iv_type = gv_line) THEN
      -- �w�����ʍX�V�t���O�̐ݒ�
      IF (gn_lot_sum <> gt_lr_quantity_tbl(gn_i)) THEN
        gt_ph_up_flg(gn_k) := gv_flg_on;
        gt_pl_up_flg(gn_j) := gv_flg_on;
        -- �w�����ʂ̐ݒ�
        ln_sum_quantity    := gn_lot_sum;
      ELSE
        gt_pl_up_flg(gn_j) := gv_flg_off;
        -- �w�����ʂ̐ݒ�
        ln_sum_quantity    := gt_lr_quantity_tbl(gn_i);
      END IF;
--
      ---------------------------------------------
      -- ���v�d�ʥ���v�e�ώ擾                   --
      ---------------------------------------------
      -- �u�ύڌ����`�F�b�N(���v�l�Z�o)�v�Ăяo��
      xxwsh_common910_pkg.calc_total_value
                            (
                             gt_lr_item_code_tbl(gn_i),            -- �i�ڃR�[�h
                             ln_sum_quantity,                      -- �������ʍ��v
                             lv_retcode,                           -- ���^�[���R�[�h
                             lv_errmsg_code,                       -- �G���[���b�Z�[�W�R�[�h
                             lv_errmsg,                            -- �G���[���b�Z�[�W
                             gt_pl_weight_tbl(gn_j),               -- ���v�d��
                             gt_pl_capacity_tbl(gn_j),             -- ���v�e��
                             gt_pl_pallet_weight_tbl(gn_j)         -- ���v�p���b�g�d��
                            );
--
      -- ���ʊ֐��ŃG���[�̏ꍇ
      IF (lv_retcode = '1') THEN
        -- �G���[���O�o��
        xxcmn_common_pkg.put_api_log(
          lv_errbuf     -- �G���[�E���b�Z�[�W
         ,lv_retcode    -- ���^�[���E�R�[�h
         ,lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(
                        xxcmn_common_pkg.get_msg(
                          gv_xxpo                     -- ���W���[��������:XXPO
                         ,gv_msg_xxpo10237            -- ���b�Z�[�W:APP-XXPO-10237 ���ʊ֐��G���[
                         ,gv_tkn_common_name          -- �g�[�N��NG_NAME
                         ,gv_tkn_calc_total_value)    -- �ύڌ����`�F�b�N(���v�l�Z�o)
                         ,1,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
      -- �����v�d��
      gt_ph_sum_weight_tbl(gn_k) :=
        NVL(gt_ph_sum_weight_tbl(gn_k), 0) + NVL(gt_pl_weight_tbl(gn_j), 0);
--
      -- �����v�e��
      gt_ph_sum_capacity_tbl(gn_k) :=
        NVL(gt_ph_sum_capacity_tbl(gn_k), 0) + NVL(gt_pl_capacity_tbl(gn_j), 0);
--
      -- ���p���b�g�d��
      gt_ph_sum_pallet_weight_tbl(gn_k) :=
        NVL(gt_ph_sum_pallet_weight_tbl(gn_k), 0) + NVL(gt_pl_pallet_weight_tbl(gn_j), 0);
--
      ---------------------------------------------
      -- �z�Ԋ֘A���̎Z�o                      --
      ---------------------------------------------
      -- ������
      -- ���o�Ɋ��Z�P�ʂ��ݒ肳��Ă��āA�P�[�X������NULL�Ⴕ����0�łȂ��ꍇ
      -- �����ۑ�#32,66 2008/07/22 modify start
      --IF (
      --     (gt_lr_conv_unit_tbl(gn_i) IS NOT NULL) AND
      --     (gt_lr_num_of_cases_tbl(gn_i) IS NOT NULL) AND
      --     (gt_lr_num_of_cases_tbl(gn_i) <> '0')
      --   ) THEN
      --  ln_small_quantity :=
      --    ROUND(TO_NUMBER(ln_sum_quantity / gt_lr_num_of_cases_tbl(gn_i)));
      --ELSE
      --  ln_small_quantity := ln_sum_quantity;
      --END IF;
      -- ���o�Ɋ��Z�P�ʂ�NULL�łȂ��ꍇ
      IF (gt_lr_conv_unit_tbl(gn_i) IS NOT NULL) THEN
        -- �P�[�X���萔��0���傫���ꍇ
        IF (gt_lr_num_of_cases_tbl(gn_i) > 0) THEN
          -- �P�[�X���萔�������������Z���s���B
          ln_small_quantity := CEIL(TO_NUMBER(ln_sum_quantity / gt_lr_num_of_cases_tbl(gn_i)));
        ELSIF (gt_lr_num_of_cases_tbl(gn_i) = 0
            OR gt_lr_num_of_cases_tbl(gn_i) IS NULL) THEN
          -- �G���[���b�Z�[�W�擾
          lv_errmsg  := SUBSTRB(
                          xxcmn_common_pkg.get_msg(
                            gv_xxcmn                   -- ���W���[��������:XXCMN
                           ,gv_msg_xxcmn10604          -- ���b�Z�[�W:APP-XXCMN-10604 �P�[�X�����G���[
                           ,gv_tkn_request_no
                           ,gt_lr_request_no_tbl(gn_i)
                           ,gv_tkn_item_no
                           ,gt_lr_item_code_tbl(gn_i))
                           ,1,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      ELSE
        ln_small_quantity := ln_sum_quantity;
      END IF;
      -- �����ۑ�#32,66 2008/07/22 modify end
--
      gt_ph_small_quantity_tbl(gn_k) :=
        NVL(gt_ph_small_quantity_tbl(gn_k), 0) + ln_small_quantity;
--
      -- ���x������
      gt_ph_label_quantity_tbl(gn_k) :=
       NVL(gt_ph_label_quantity_tbl(gn_k), 0) + ln_small_quantity;
--
      -- ���v����
      gt_pl_quantity_tbl(gn_j)          := NVL(ln_sum_quantity, 0);
      gt_pl_reserved_quantity_tbl(gn_j) := NVL(ln_sum_quantity, 0);
      gt_ph_sum_quantity_tbl(gn_k)      :=
       NVL(gt_ph_sum_quantity_tbl(gn_k), 0) +  NVL(ln_sum_quantity, 0);
--
      -- ���ׂ��ŏI���R�[�h���A����w�b�_ID�̍ŏI���R�[�h�̏ꍇ���s����B
      IF (
           (gt_lr_lot_reserve_if_id_tbl.COUNT  = gn_i) OR
           (gt_lr_order_header_id_tbl(gn_i) <> gt_lr_order_header_id_tbl(gn_i + 1))
         ) THEN
--
        -- ST�s� modify 2008/07/29 start
        -- �^���敪��ON�̏ꍇ�̂݁A�擾�B
        IF (gt_lr_freight_charge_class_tbl(gn_i) = gv_freight_charge_class_on) THEN
          ---------------------------------------------
          -- �ύڌ����Z�o                            --
          ---------------------------------------------
          -- �ύڏd�ʍ��v
          ln_sum_weight := gt_ph_sum_weight_tbl(gn_k);
          -- �ύڗe�ύ��v
          ln_sum_capacity := gt_ph_sum_capacity_tbl(gn_k);
--
        -- �����ύX#166 2008/07/22 modify start
          -- �d�ʂ̐ύڌ������擾����
          IF (gt_lr_we_ca_class_tbl(gn_i) = gv_we) THEN
--
            -- �u�ύڌ����`�F�b�N(�ύڌ����Z�o)�v�Ăяo��
            xxwsh_common910_pkg.calc_load_efficiency
                                (
                                  ln_sum_weight,                          -- ���v�d��
                                  NULL,                                   -- ���v�e��
                                  cv_wh,                                  -- �q��'4'
                                  gt_lr_deliver_from_tbl(gn_i),           -- �o�ɑq�ɃR�[�h
                                  cv_sup,                                 -- �x����'11'
                                  gt_lr_deliver_to_tbl(gn_i),             -- �z����R�[�h
                                  gt_ship_method_tbl(gn_k),               -- �z���敪
                                  gv_item_div_prf,                        -- ���i�敪
                                  NULL,                                   -- �����z�ԑΏۋ敪
                                  TRUNC(SYSDATE),                         -- ���
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
               -- �G���[���O�o��
               xxcmn_common_pkg.put_api_log(
                 lv_errbuf     -- �G���[�E���b�Z�[�W
                ,lv_retcode    -- ���^�[���E�R�[�h
                ,lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
              -- �G���[���b�Z�[�W�擾
              lv_errmsg  := SUBSTRB(
                              xxcmn_common_pkg.get_msg(
                                gv_xxpo                   -- ���W���[��������:XXPO
                               ,gv_msg_xxpo10237          -- ���b�Z�[�W:APP-XXPO-10237 ���ʊ֐��G���[
                               ,gv_tkn_common_name        -- �g�[�N��NG_NAME
                               ,gv_tkn_calc_load_ef_we)   -- �ύڌ����`�F�b�N(�ύڌ����Z�o:�d��)
                               ,1,5000);
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            END IF;
--
            -- �ύڃI�[�o�[�̏ꍇ
            IF (lv_loading_over_class = gv_flg_on) THEN
              -- �G���[���O�o��
              xxcmn_common_pkg.put_api_log(
               ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
              ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
              ,ov_errmsg     => lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
              -- �G���[���b�Z�[�W�擾
              lv_errmsg  := SUBSTRB(
                             xxcmn_common_pkg.get_msg(
                               gv_xxpo               -- ���W���[��������:XXPO
                              ,gv_msg_xxpo10120)     -- ���b�Z�[�W:APP-XXPO-10120 �ύڌ����`�F�b�N�G���[
                              ,1,5000);
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            END IF;
--
          -- �e�ς̐ύڌ������擾����
          ELSIF (gt_lr_we_ca_class_tbl(gn_i) = gv_ca) THEN
--
            -- �u�ύڌ����`�F�b�N(�ύڌ����Z�o)�v�Ăяo��
            xxwsh_common910_pkg.calc_load_efficiency
                                (
                                  NULL,                                   -- ���v�d��
                                  ln_sum_capacity,                        -- ���v�e��
                                  cv_wh,                                  -- �q��'4'
                                  gt_lr_deliver_from_tbl(gn_i),           -- �o�ɑq�ɃR�[�h
                                  cv_sup,                                 -- �x����'11'
                                  gt_lr_deliver_to_tbl(gn_i),             -- �z����R�[�h
                                  gt_ship_method_tbl(gn_k),               -- �z���敪
                                  gv_item_div_prf,                        -- ���i�敪
                                  NULL,                                   -- �����z�ԑΏۋ敪
                                  TRUNC(SYSDATE),                         -- ���
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
              -- �G���[���O�o��
              xxcmn_common_pkg.put_api_log(
                lv_errbuf     -- �G���[�E���b�Z�[�W
               ,lv_retcode    -- ���^�[���E�R�[�h
               ,lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
              -- �G���[���b�Z�[�W�擾
              lv_errmsg  := SUBSTRB(
                              xxcmn_common_pkg.get_msg(
                                gv_xxpo                   -- ���W���[��������:XXPO
                               ,gv_msg_xxpo10237          -- ���b�Z�[�W::APP-XXPO-10237 ���ʊ֐��G���[
                               ,gv_tkn_common_name        -- �g�[�N��NG_NAME
                               ,gv_tkn_calc_load_ef_ca)   -- �ύڌ����`�F�b�N(�ύڌ����Z�o:�e��)
                               ,1,5000);
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            END IF;
--
            -- �ύڃI�[�o�[�̏ꍇ
            IF (lv_loading_over_class = gv_flg_on) THEN
              -- �G���[���O�o��
              xxcmn_common_pkg.put_api_log(
               ov_errbuf     => lv_errbuf     -- �G���[�E���b�Z�[�W
              ,ov_retcode    => lv_retcode    -- ���^�[���E�R�[�h
              ,ov_errmsg     => lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
              -- �G���[���b�Z�[�W�擾
              lv_errmsg  := SUBSTRB(
                             xxcmn_common_pkg.get_msg(
                               gv_xxpo               -- ���W���[��������:XXPO
                              ,gv_msg_xxpo10120)     -- ���b�Z�[�W:APP-XXPO-10120 �ύڌ����`�F�b�N�G���[
                              ,1,5000);
              lv_errbuf := lv_errmsg;
              RAISE global_api_expt;
            END IF;
--
          END IF;
--
          -- �u�ύڌ����`�F�b�N(�ύڌ����Z�o)�v�Ăяo��
          xxwsh_common910_pkg.calc_load_efficiency
                              (
                                ln_sum_weight,                        -- ���v�d��
                                NULL,                                 -- ���v�e��
                                cv_wh,                                -- �q��'4'
                                gt_lr_deliver_from_tbl(gn_i),         -- �o�ɑq�ɃR�[�h
                                cv_sup,                               -- �x����'11'
                                gt_lr_deliver_to_tbl(gn_i),           -- �z����R�[�h
                                gt_lr_shipping_method_code_tbl(gn_i), -- �z���敪
                                gv_item_div_prf,                      -- ���i�敪
                                NULL,                                 -- �����z�ԑΏۋ敪
                                TRUNC(SYSDATE),                       -- ���
                                lv_retcode,                           -- ���^�[���R�[�h
                                lv_errmsg_code,                       -- �G���[���b�Z�[�W�R�[�h
                                lv_errmsg,                            -- �G���[���b�Z�[�W
                                lv_loading_over_class,                -- �ύڃI�[�o�[�敪
                                lv_ship_methods,                      -- �o�ו��@
                                gt_ph_load_efficiency_we_tbl(gn_k),   -- �d�ʐύڌ���
                                lv_load_efficiency_ca,                -- �e�ϐύڌ���
                                lv_mixed_ship_method                  -- ���ڔz���敪
                              );
--
          -- ���ʊ֐��ŃG���[�̏ꍇ
          IF (lv_retcode = '1') THEN
            -- �G���[���O�o��
            xxcmn_common_pkg.put_api_log(
              lv_errbuf     -- �G���[�E���b�Z�[�W
             ,lv_retcode    -- ���^�[���E�R�[�h
             ,lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
            -- �G���[���b�Z�[�W�擾
            lv_errmsg  := SUBSTRB(
                            xxcmn_common_pkg.get_msg(
                              gv_xxpo                   -- ���W���[��������:XXPO
                             ,gv_msg_xxpo10237          -- ���b�Z�[�W::APP-XXPO-10237 ���ʊ֐��G���[
                             ,gv_tkn_common_name        -- �g�[�N��NG_NAME
                             ,gv_tkn_calc_load_ef_we)   -- �ύڌ����`�F�b�N(�ύڌ����Z�o:�d��)
                             ,1,5000);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
--
          -- �u�ύڌ����`�F�b�N(�ύڌ����Z�o)�v�Ăяo��
          xxwsh_common910_pkg.calc_load_efficiency
                              (
                                NULL,                                 -- ���v�d��
                                ln_sum_capacity,                      -- ���v�e��
                                cv_wh,                                -- �q��'4'
                                gt_lr_deliver_from_tbl(gn_i),         -- �o�ɑq�ɃR�[�h
                                cv_sup,                               -- �x����'11'
                                gt_lr_deliver_to_tbl(gn_i),           -- �z����R�[�h
                                gt_lr_shipping_method_code_tbl(gn_i), -- �z���敪
                                gv_item_div_prf,                      -- ���i�敪
                                NULL,                                 -- �����z�ԑΏۋ敪
                                TRUNC(SYSDATE),                       -- ���
                                lv_retcode,                           -- ���^�[���R�[�h
                                lv_errmsg_code,                       -- �G���[���b�Z�[�W�R�[�h
                                lv_errmsg,                            -- �G���[���b�Z�[�W
                                lv_loading_over_class,                -- �ύڃI�[�o�[�敪
                                lv_ship_methods,                      -- �o�ו��@
                                lv_load_efficiency_we,                -- �d�ʐύڌ���
                                gt_ph_load_efficiency_ca_tbl(gn_k),   -- �e�ϐύڌ���
                                lv_mixed_ship_method                  -- ���ڔz���敪
                              );
--
          -- ���ʊ֐��ŃG���[�̏ꍇ
          IF (lv_retcode = '1') THEN
            -- �G���[���O�o��
            xxcmn_common_pkg.put_api_log(
              lv_errbuf     -- �G���[�E���b�Z�[�W
             ,lv_retcode    -- ���^�[���E�R�[�h
             ,lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
            -- �G���[���b�Z�[�W�擾
            lv_errmsg  := SUBSTRB(
                            xxcmn_common_pkg.get_msg(
                              gv_xxpo                   -- ���W���[��������:XXPO
                             ,gv_msg_xxpo10237          -- ���b�Z�[�W:APP-XXPO-10237 ���ʊ֐��G���[
                             ,gv_tkn_common_name        -- �g�[�N��NG_NAME
                             ,gv_tkn_calc_load_ef_ca)   -- �ύڌ����`�F�b�N(�ύڌ����Z�o:�e��)
                             ,1,5000);
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          END IF;
        -- �����ύX#166 2008/07/22 modify end
--
        ELSE
          -- �^���敪OFF�̏ꍇ�A�ύڌ�����NULL��ݒ肷��B
          gt_ph_load_efficiency_we_tbl(gn_k) := NULL;
          gt_ph_load_efficiency_ca_tbl(gn_k) := NULL;
--
        END IF;
        -- ST�s� modify 2008/07/29 end
--
      END IF;
--
    END IF;
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
  END get_other_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_mov_lot_details
   * Description      : �ړ����b�g�ڍ�(�A�h�I��)�o�^����(H-6)
   ***********************************************************************************/
  PROCEDURE ins_mov_lot_details(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    IN OUT VARCHAR2,     --   ���^�[���E�R�[�h          --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mov_lot_details'; -- �v���O������
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
    ln_count   NUMBER;           -- �J�E���g�ϐ�
    ln_pm_cont   NUMBER;         -- �J�E���g�ϐ�
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �Ώۃf�[�^��􂢑ւ�����ׁA�폜����B
    FORALL ln_count IN gt_pm_mov_lot_dtl_id_tbl.FIRST .. gt_pm_mov_lot_dtl_id_tbl.LAST
      DELETE xxinv_mov_lot_details xmld      -- �ړ����b�g�ڍ�
      WHERE  xmld.mov_line_id = gt_pm_mov_line_id_tbl(ln_count)
      AND    xmld.document_type_code = gt_pm_document_type_code_tbl(ln_count)
      AND    xmld.record_type_code = gt_pm_record_type_code_tbl(ln_count);
--
    ---------------------------------------------
    -- �ړ����b�g�ڍדo�^����                  --
    ---------------------------------------------
    -- �ړ����b�g�ڍ׃A�h�I���e�[�u���֓o�^���郌�R�[�h�֒l���Z�b�g
    FORALL ln_pm_cont IN gt_pm_mov_lot_dtl_id_tbl.FIRST .. gt_pm_mov_lot_dtl_id_tbl.LAST
      INSERT INTO xxinv_mov_lot_details
                 (mov_lot_dtl_id,
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
                  program_update_date)
      VALUES     (
                  gt_pm_mov_lot_dtl_id_tbl(ln_pm_cont),
                  gt_pm_mov_line_id_tbl(ln_pm_cont),
                  gt_pm_document_type_code_tbl(ln_pm_cont),
                  gt_pm_record_type_code_tbl(ln_pm_cont),
                  gt_pm_item_id_tbl(ln_pm_cont),
                  gt_pm_item_code_tbl(ln_pm_cont),
                  gt_pm_lot_id_tbl(ln_pm_cont),
                  gt_pm_lot_no_tbl(ln_pm_cont),
                  gt_pm_actual_date_tbl(ln_pm_cont),
                  gt_pm_actual_quantity_tbl(ln_pm_cont),
                  gt_pm_auma_reserve_class_tbl(ln_pm_cont),
                  gt_pm_created_by_tbl(ln_pm_cont),
                  gt_pm_creation_date_tbl(ln_pm_cont),
                  gt_pm_last_updated_by_tbl(ln_pm_cont),
                  gt_pm_last_update_date_tbl(ln_pm_cont),
                  gt_pm_last_update_login_tbl(ln_pm_cont),
                  gt_pm_request_id_tbl(ln_pm_cont),
                  gt_pm_program_app_id_tbl(ln_pm_cont),
                  gt_pm_program_id_tbl(ln_pm_cont),
                  gt_pm_program_update_date_tbl(ln_pm_cont));
--
      -- ��������(�ړ����b�g�ڍ�)�J�E���g
      gn_m_normal_cnt := gt_pm_mov_lot_dtl_id_tbl.COUNT;
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
  END ins_mov_lot_details;
--
  /**********************************************************************************
   * Procedure Name   : ins_order_lines_all
   * Description      : �󒍖��׃A�h�I��(�A�h�I��)�o�^����(H-7)
   ***********************************************************************************/
  PROCEDURE ins_order_lines_all(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    IN OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_order_lines_all'; -- �v���O������
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
    ln_pl_cont   NUMBER;         -- �J�E���g�ϐ�
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ---------------------------------------------
    -- �󒍖��׍X�V����                        --
    ---------------------------------------------
    FORALL ln_pl_cont IN gt_pl_order_line_id_tbl.FIRST .. gt_pl_order_line_id_tbl.LAST
      UPDATE xxwsh_order_lines_all
      SET    reserved_quantity           = gt_pl_reserved_quantity_tbl(ln_pl_cont),
             weight                      = DECODE(gt_pl_up_flg(ln_pl_cont)
                                                 ,gv_flg_on
                                                 ,gt_pl_weight_tbl(ln_pl_cont)
                                                 ,weight),
             capacity                    = DECODE(gt_pl_up_flg(ln_pl_cont)
                                                 ,gv_flg_on
                                                 ,gt_pl_capacity_tbl(ln_pl_cont)
                                                 ,capacity),
             quantity                    = DECODE(gt_pl_up_flg(ln_pl_cont)
                                                 ,gv_flg_on
                                                 ,gt_pl_quantity_tbl(ln_pl_cont)
                                                 ,quantity),
             automanual_reserve_class    = gt_pl_auto_reserve_class_tbl(ln_pl_cont),
             line_description            = NVL(gt_pl_line_description_tbl(ln_pl_cont)
                                              ,line_description),
             last_updated_by             = gt_pl_last_updated_by_tbl(ln_pl_cont),
             last_update_date            = gt_pl_last_update_date_tbl(ln_pl_cont),
             last_update_login           = gt_pl_last_update_login_tbl(ln_pl_cont)
      WHERE  order_line_id = gt_pl_order_line_id_tbl(ln_pl_cont);
--
      -- ��������(�󒍖���)�J�E���g
      gn_l_normal_cnt := gt_pl_order_line_id_tbl.COUNT;
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
  END ins_order_lines_all;
--
  /**********************************************************************************
   * Procedure Name   : ins_order_headers_all
   * Description      : �󒍃w�b�_�A�h�I��(�A�h�I��)�o�^����(H-8)
   ***********************************************************************************/
  PROCEDURE ins_order_headers_all(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    IN OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_order_headers_all'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(2);     -- ���^�[���E�R�[�h
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
    ln_ph_cont   NUMBER;         -- �J�E���g�ϐ�
    i            NUMBER;         -- �J�E���g�ϐ�
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    ---------------------------------------------
    -- �z�ԉ�������                            --
    ---------------------------------------------
    <<data_loop>>
    FOR i IN gt_ph_order_header_id_tbl.FIRST .. gt_ph_order_header_id_tbl.LAST LOOP
      -- �w�����ʍX�V�t���O��ON�̏ꍇ�̂݁A�z�ԉ������s���B
      IF (gt_ph_up_flg(i) = gv_flg_on) THEN
        -- �u�z�ԉ����֐��v�Ăяo��
        lv_retcode := xxwsh_common_pkg.cancel_careers_schedule
                                   (
                                    gv_supply,                -- �Ɩ����("�x��")
                                    gt_ph_request_no_tbl(i),  -- �˗�No.
                                    lv_errmsg                 -- �G���[���b�Z�[�W
                                   );
--
        -- ���ʊ֐��ŃG���[�̏ꍇ
        IF (lv_retcode <> '0') THEN
          -- �G���[���O�o��
          xxcmn_common_pkg.put_api_log(
            lv_errbuf     -- �G���[�E���b�Z�[�W
           ,lv_retcode    -- ���^�[���E�R�[�h
           ,lv_errmsg);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
          -- �G���[���b�Z�[�W�擾
          lv_errmsg  := SUBSTRB(
                          xxcmn_common_pkg.get_msg(
                                 gv_xxpo                   -- ���W���[��������:XXPO
                                 ,gv_msg_xxpo10237          -- ���b�Z�[�W:APP-XXPO-10237 ���ʊ֐��G���[
                                 ,gv_tkn_common_name        -- �g�[�N��NG_NAME
                                 ,gv_tkn_cancel_car_sche)   -- �z�ԉ����֐�
                                 ,1,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      END IF;
    END LOOP data_loop;
--
    ---------------------------------------------
    -- �󒍃w�b�_�X�V����                      --
    ---------------------------------------------
    FORALL ln_ph_cont IN gt_ph_order_header_id_tbl.FIRST .. gt_ph_order_header_id_tbl.LAST
      UPDATE xxwsh_order_headers_all
      SET    sum_quantity                = gt_ph_sum_quantity_tbl(ln_ph_cont),
             small_quantity              = gt_ph_small_quantity_tbl(ln_ph_cont),
             label_quantity              = gt_ph_label_quantity_tbl(ln_ph_cont),
             loading_efficiency_weight   = gt_ph_load_efficiency_we_tbl(ln_ph_cont),
             loading_efficiency_capacity = gt_ph_load_efficiency_ca_tbl(ln_ph_cont),
             sum_weight                  = gt_ph_sum_weight_tbl(ln_ph_cont),
             sum_capacity                = gt_ph_sum_capacity_tbl(ln_ph_cont),
             last_updated_by             = gt_ph_last_updated_by_tbl(ln_ph_cont),
             last_update_date            = gt_ph_last_update_date_tbl(ln_ph_cont),
             last_update_login           = gt_ph_last_update_login_tbl(ln_ph_cont)
      WHERE  order_header_id = gt_ph_order_header_id_tbl(ln_ph_cont)
      AND    gt_ph_up_flg(ln_ph_cont) = gv_flg_on;
--
      -- ��������(�󒍃w�b�_)�J�E���g
      gn_h_normal_cnt := gt_ph_order_header_id_tbl.COUNT;
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
  END ins_order_headers_all;
--
  /**********************************************************************************
   * Procedure Name   : del_lot_reserve_if
   * Description      : �f�[�^�폜����(H-9)
   ***********************************************************************************/
  PROCEDURE del_lot_reserve_if(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    IN OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_lot_reserve_if'; -- �v���O������
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
--###########################  �Œ蕔 END   ############################
--
    FORALL ln_count IN 1..gt_lr_lot_reserve_if_id_tbl.COUNT
      DELETE xxpo_lot_reserve_if xlri      -- ���b�g�������C���^�t�F�[�X
      WHERE  xlri.lot_reserve_if_id = gt_lr_lot_reserve_if_id_tbl(ln_count);
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
  END del_lot_reserve_if;
--
  /**********************************************************************************
   * Procedure Name   : put_dump_msg
   * Description      : �f�[�^�_���v�ꊇ�o�͏���(H-10)
   ***********************************************************************************/
  PROCEDURE put_dump_msg(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    IN OUT VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
                   gv_xxcmn               -- ���W���[�������́FXXCMN
                  ,gv_msg_xxcmn00005)     -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
                ,1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- ����f�[�^�_���v
    <<normal_dump_loop>>
    FOR ln_cnt_loop IN 1 .. normal_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, normal_dump_tab(ln_cnt_loop));
    END LOOP normal_dump_loop;
--
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_sep_msg);
--
    -- �x���f�[�^�f�[�^�i���o���j
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxpo               -- ���W���[�������́FXXCMN
                  ,gv_msg_xxpo10252)     -- ���b�Z�[�W�FAPP-XXPO-10252 �x���f�[�^�i���o���j
                ,1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_msg);
--
    -- �x���f�[�^�_���v
    <<warn_dump_loop>>
    FOR ln_cnt_loop IN 1 .. warn_dump_tab.COUNT
    LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, warn_dump_tab(ln_cnt_loop));
    END LOOP warn_dump_loop;
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
  /**********************************************************************************
   * Procedure Name   : set_order_header_data_proc
   * Description      : �󒍃w�b�_�X�V�f�[�^�ݒ菈��
   ***********************************************************************************/
  PROCEDURE set_order_header_data_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          IN OUT NOCOPY VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_order_header_data_proc'; -- �v���O������
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
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���[�J���ϐ��̏�����-
    -- �󒍃w�b�_�A�h�I���e�[�u���֓o�^���郌�R�[�h�֒l���Z�b�g
    gt_ph_order_header_id_tbl(gn_k)               :=  gt_lr_order_header_id_tbl(gn_i);
    gt_ph_request_no_tbl(gn_k)                    :=  gt_lr_request_no_tbl(gn_i);
    /* ���ʂȂǂ͊֘A�f�[�^�擾�Ŏ擾����B */
    gt_ph_last_updated_by_tbl(gn_k)               :=  gn_user_id;
    gt_ph_last_update_date_tbl(gn_k)              :=  gd_sysdate;
    gt_ph_last_update_login_tbl(gn_k)             :=  gn_login_id;
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
  END set_order_header_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_order_line_data_proc
   * Description      : �󒍖��׍X�V�f�[�^�ݒ菈��
   ***********************************************************************************/
  PROCEDURE set_order_line_data_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          IN OUT NOCOPY VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_order_line_data_proc'; -- �v���O������
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
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���[�J���ϐ��̏�����
--
    -- �󒍖��׃A�h�I���e�[�u���֓o�^���郌�R�[�h�֒l���Z�b�g
    gt_pl_order_line_id_tbl(gn_j)               :=  gt_lr_order_line_id_tbl(gn_i);
    gt_pl_auto_reserve_class_tbl(gn_j)          :=  gv_am_reserve_class_au;
    /* ���ʂȂǂ͊֘A�f�[�^�擾�Ŏ擾����B */
    gt_pl_line_description_tbl(gn_j)            :=  gt_lr_line_description_tbl(gn_i);
    gt_pl_last_updated_by_tbl(gn_j)             :=  gn_user_id;
    gt_pl_last_update_date_tbl(gn_j)            :=  gd_sysdate;
    gt_pl_last_update_login_tbl(gn_j)           :=  gn_login_id;
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
  END set_order_line_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : set_mov_lot_data_proc
   * Description      : �ړ����b�g�ڍדo�^�f�[�^�ݒ菈��
   ***********************************************************************************/
  PROCEDURE set_mov_lot_data_proc(
    ov_errbuf           OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          IN OUT NOCOPY VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_mov_lot_data_proc'; -- �v���O������
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
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���[�J���ϐ��̏�����
--
    -- ���b�g�ڍ�ID�̔�
    SELECT xxinv_mov_lot_s1.NEXTVAL 
    INTO gt_pm_mov_lot_dtl_id_tbl(gn_i)
    FROM dual;
--
    -- �ړ����b�g�ڍ׃A�h�I���e�[�u���֓o�^���郌�R�[�h�֒l���Z�b�g
    gt_pm_mov_line_id_tbl(gn_i)                     :=  gt_lr_order_line_id_tbl(gn_i);
    gt_pm_document_type_code_tbl(gn_i)              :=  gv_document_type_ship_req;
    gt_pm_record_type_code_tbl(gn_i)                :=  gv_record_type_inst;
    gt_pm_item_id_tbl(gn_i)                         :=  gt_lr_item_id_tbl(gn_i);
    gt_pm_item_code_tbl(gn_i)                       :=  gt_lr_item_code_tbl(gn_i);
    gt_pm_lot_id_tbl(gn_i)                          :=  gt_lr_lot_id_tbl(gn_i);
    gt_pm_lot_no_tbl(gn_i)                          :=  gt_lr_lot_no_tbl(gn_i);
    gt_pm_actual_date_tbl(gn_i)                     :=  gt_lr_shipped_date_tbl(gn_i);
    gt_pm_actual_quantity_tbl(gn_i)                 :=  gt_lr_reserved_quantity_tbl(gn_i);
    gt_pm_auma_reserve_class_tbl(gn_i)              :=  gv_am_reserve_class_au;
    gt_pm_created_by_tbl(gn_i)                      :=  gn_user_id;
    gt_pm_creation_date_tbl(gn_i)                   :=  gd_sysdate;
    gt_pm_last_updated_by_tbl(gn_i)                 :=  gn_user_id;
    gt_pm_last_update_date_tbl(gn_i)                :=  gd_sysdate;
    gt_pm_last_update_login_tbl(gn_i)               :=  gn_login_id;
    gt_pm_request_id_tbl(gn_i)                      :=  gn_conc_request_id;
    gt_pm_program_app_id_tbl(gn_i)                  :=  gn_prog_appl_id;
    gt_pm_program_id_tbl(gn_i)                      :=  gn_conc_program_id;
    gt_pm_program_update_date_tbl(gn_i)             :=  gd_sysdate;
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
  END set_mov_lot_data_proc;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                 OUT VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2,    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    iv_data_class             IN  VARCHAR2,    --   �f�[�^���
    iv_deliver_from           IN  VARCHAR2,    --   �q��
    iv_shipped_date_from      IN  VARCHAR2,    --   �o�ɓ�FROM
    iv_shipped_date_to        IN  VARCHAR2,    --   �o�ɓ�TO
    iv_instruction_dept       IN  VARCHAR2,    --   �w������
    iv_security_kbn           IN  VARCHAR2)    --   �Z�L�����e�B�敪
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
    lvv_retcode VARCHAR2(1);    -- ���^�[���E�R�[�h
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt          := 0;          -- �Ώی���(���b�g�������IF)
    gn_h_normal_cnt        := 0;          -- ���팏��(�󒍃w�b�_)
    gn_l_normal_cnt        := 0;          -- ���팏��(�󒍖���)
    gn_m_normal_cnt        := 0;          -- ���팏��(�ړ����b�g�ڍ�)
    gn_warn_msg_cnt        := 0;
    gn_normal_cnt          := 0;
    
    gn_i                   := 0;
    gn_j                   := 0;
    gn_k                   := 0;
    gn_lot_sum             := 0;
    gv_line_description    := NULL;
--
    -- �u���C�N�p�ϐ�
    gv_pre_order_header_id       := 0;
--
    ------------------------------------------
    -- �p�����[�^�K�{�`�F�b�N               --
    ------------------------------------------
    IF (iv_data_class IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10235,
                                            gv_tkn_para_name,
                                            gv_data_class);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    -- �q��
    ELSIF (iv_deliver_from IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10235,
                                            gv_tkn_para_name,
                                            gv_deliver_from_s);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    -- �o�ɓ�FROM
    ELSIF (iv_shipped_date_from IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10235,
                                            gv_tkn_para_name,
                                            gv_shippe_date_from);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
--
    -- �o�ɓ�TO
    ELSIF (iv_shipped_date_to IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10235,
                                            gv_tkn_para_name,
                                            gv_shippe_date_to);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
--
    -- �w������
    ELSIF (iv_instruction_dept IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10235,
                                            gv_tkn_para_name,
                                            gv_instruction_dept);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
--
    -- �Z�L�����e�B�敪
    ELSIF (iv_security_kbn IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10235,
                                            gv_tkn_para_name,
                                            gv_security_class);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
--
    END IF;
--
    ------------------------------------------
    -- �p�����[�^���t�`�F�b�N               --
    ------------------------------------------
    -- ��o�ɓ�TO�����o�ɓ�FROM����ȑO�̏ꍇ
    IF (iv_shipped_date_from > iv_shipped_date_to) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxpo,
                                            gv_msg_xxpo10236,
                                            gv_tkn_date_item1,
                                            gv_shippe_date_from,
                                            gv_tkn_date_item2,
                                            gv_shippe_date_to);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
--
    END IF;
--
    -- =========================================
    -- ��������(H-1)
    -- =========================================
    init_proc(
      lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �����\���`�F�b�N����(H-2)
    -- =========================================
    check_can_enc_qty(
      iv_data_class,           -- 1.�f�[�^���
      iv_deliver_from,         -- 2.�q��
      iv_shipped_date_from,    -- 3.�o�ɓ�FROM
      iv_shipped_date_to,      -- 4.�o�ɓ�TO
      iv_instruction_dept,     -- 5.�w������
      iv_security_kbn,         -- 6.�Z�L�����e�B�敪
      lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �Ώۃf�[�^�擾����(H-3)
    -- =========================================
    get_data(
      iv_data_class,           -- 1.�f�[�^���
      iv_deliver_from,         -- 2.�q��
      iv_shipped_date_from,    -- 3.�o�ɓ�FROM
      iv_shipped_date_to,      -- 4.�o�ɓ�TO
      iv_instruction_dept,     -- 5.�w������
      iv_security_kbn,         -- 6.�Z�L�����e�B�敪
      lv_errbuf,               -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,              -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);              -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
--
      IF (gn_target_cnt = 0) THEN
        ov_retcode := gv_status_warn;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
        RETURN;
      END IF;
--
      RAISE global_process_expt;
    END IF;
--
    <<data_loop>>
    FOR i IN gt_lr_lot_reserve_if_id_tbl.FIRST .. gt_lr_lot_reserve_if_id_tbl.LAST LOOP
--
      -- �ړ����b�g�ڍדo�^���̃J�E���g
      gn_i := gn_i + 1;
--
      -- =========================================
      -- �擾�f�[�^�`�F�b�N����(H-4)
      -- =========================================
      check_data(
        lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      -- �G���[�̏ꍇ�A�����I��
      IF (lv_retcode = gv_status_error) THEN
        RAISE proc_err_expt;
--
      -- ����/�x���̏ꍇ
      ELSE
--
        -- ���ʍ��v�p�ϐ��Ɉ�������(���b�g�������IF)��ݒ�
        gn_lot_sum := gn_lot_sum + gt_lr_reserved_quantity_tbl(gn_i);
--
        -- �󒍃w�b�_�A�h�I��ID���O�񃌃R�[�h�ƈقȂ�ꍇ�A�󒍃w�b�_�A�h�I�������Z�b�g����B
        IF ( gt_lr_order_header_id_tbl(gn_i) <> gv_pre_order_header_id) THEN
--
          -- �󒍃w�b�_�o�^���̃J�E���g�B
          gn_k := gn_k + 1 ;
--
          -- =========================================
          -- �֘A�f�[�^�擾����(H-5)
          -- =========================================
          get_other_data(
            gv_header                           -- �w�b�_�敪
           ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- �G���[�̏ꍇ�A�����I��
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
          
          -- =========================================
          -- �󒍃w�b�_�A�h�I���o�^�f�[�^�ݒ菈��
          -- =========================================
          set_order_header_data_proc(
            lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- �󒍃w�b�_�A�h�I��ID���Đݒ肷��B
          gv_pre_order_header_id := gt_lr_order_header_id_tbl(gn_i);
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
        END IF;
--
        -- ���דE�v�ێ����e�̍X�V
        IF (gt_lr_line_description_tbl(gn_i) IS NOT NULL) THEN
          gv_line_description := gt_lr_line_description_tbl(gn_i);
        END IF;
--
        -- ���ׂ��ŏI���R�[�h���A���ꖾ��ID�̍ŏI���R�[�h�̏ꍇ���s����B
        IF ((gt_lr_order_line_id_tbl.COUNT  = gn_i) OR
             (gt_lr_order_line_id_tbl(gn_i) <> gt_lr_order_line_id_tbl(gn_i + 1))
           ) THEN
--
--
          -- �󒍖��דo�^���̃J�E���g�B
          gn_j := gn_j + 1 ;
--
          -- =========================================
          -- �֘A�f�[�^�擾����(H-5)
          -- =========================================
          get_other_data(
            gv_line                             -- ���׋敪
           ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- �G���[�̏ꍇ�A�����I��
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
          
          -- =========================================
          -- �󒍖��׃A�h�I���o�^�f�[�^�ݒ菈��
          -- =========================================
          set_order_line_data_proc(
            lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
           ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
           ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          -- ���ʍ��v�p�ϐ����N���A����B
          gn_lot_sum           := 0;
--
          -- ���דE�v�ێ����e���N���A����B
          gv_line_description  := NULL;
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE proc_err_expt;
          END IF;
--
        END IF;
--
        -- =========================================
        -- �ړ����b�g�ڍ׃A�h�I���o�^�f�[�^�ݒ菈��
        -- =========================================
        set_mov_lot_data_proc(
          lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE proc_err_expt;
        END IF;
--
        -- ����f�[�^�_���vPL/SQL�\����
        gn_normal_cnt := gn_normal_cnt + 1;
        normal_dump_tab(gn_normal_cnt) := gt_lr_data_dump_tbl(gn_i);
--
      END IF;
--
    END LOOP data_loop;
--
    -- =========================================
    -- �ړ����b�g�ڍ�(�A�h�I��)�o�^����(H-6)
    -- =========================================
    ins_mov_lot_details(
      lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- =========================================
    -- �󒍖���(�A�h�I��)�o�^����(H-7)
    -- =========================================
    ins_order_lines_all(
      lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- =========================================
    -- �󒍃w�b�_(�A�h�I��)�o�^����(H-8)
    -- =========================================
    ins_order_headers_all(
      lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- =========================================
    -- �f�[�^�폜����(H-9)
    -- =========================================
    del_lot_reserve_if(
      lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ�A�����I��
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    -- =========================================
    -- �f�[�^�_���v�ꊇ�o�͏���(H-10)
    -- =========================================
    put_dump_msg(
      lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- �G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE proc_err_expt;
    END IF;
--
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    -- �e�����ŃG���[�����������ꍇ
    WHEN proc_err_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      lvv_retcode := gv_status_normal;
--
      -- =========================================
      -- �f�[�^�폜����(H-9)
      -- =========================================
      del_lot_reserve_if(
        lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lvv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lvv_retcode <> gv_status_error) THEN
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
    errbuf                    OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                   OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_data_class             IN  VARCHAR2,      --   �f�[�^���
    iv_deliver_from           IN  VARCHAR2,      --   �q��
    iv_shipped_date_from      IN  VARCHAR2,      --   �o�ɓ�FROM
    iv_shipped_date_to        IN  VARCHAR2,      --   �o�ɓ�TO
    iv_instruction_dept       IN  VARCHAR2,      --   �w������
    iv_security_kbn           IN  VARCHAR2       --   �Z�L�����e�B�敪
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
    lv_msg     VARCHAR2(5000);  -- �p�����[�^�o�͗p
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
    -- ===============================
    -- ���̓p�����[�^�o��
    -- ===============================
    -- ��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ���̓p�����[�^(���o��)
    lv_msg  := SUBSTRB(
                 xxcmn_common_pkg.get_msg(
                   gv_xxpo              -- ���W���[�������́FXXPO
                  ,gv_msg_xxpo30051)    -- ���b�Z�[�W:APP-XXPO-30051 ���̓p�����[�^(���o��)
                ,1,5000);
--
    -- ���̓p�����[�^���o���o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- ���̓p�����[�^(�J���}��؂�)
    lv_msg := iv_data_class             || gv_msg_comma || -- �f�[�^���
              iv_deliver_from           || gv_msg_comma || -- �q��
              iv_shipped_date_from      || gv_msg_comma || -- �o�ɓ�FROM
              iv_shipped_date_to        || gv_msg_comma || -- �o�ɓ�TO
              iv_instruction_dept       || gv_msg_comma || -- �w������
              iv_security_kbn;                             -- �Z�L�����e�B�敪
--
    -- ���̓p�����[�^�o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    -- ��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf,                  -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                 -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg,                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      iv_data_class,              -- �f�[�^���
      iv_deliver_from,            -- �q��
      iv_shipped_date_from,       -- �o�ɓ�FROM
      iv_shipped_date_to,         -- �o�ɓ�TO
      iv_instruction_dept,        -- �w������
      iv_security_kbn             -- �Z�L�����e�B�敪
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
    --��������(���b�g�������IF)�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXPO','APP-XXPO-30027','COUNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --��������(�󒍃w�b�_)�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXPO','APP-XXPO-10246','CNT',TO_CHAR(gn_h_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
    --��������(�󒍖���)�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXPO','APP-XXPO-10247','CNT',TO_CHAR(gn_l_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
    --��������(�ړ����b�g�ڍ�)�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXPO','APP-XXPO-10248','CNT',TO_CHAR(gn_m_normal_cnt));
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
END xxpo940008c;
/
