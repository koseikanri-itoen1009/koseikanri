create or replace
PACKAGE BODY XXCFF004A30C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF004A30C(body)
 * Description      : ���[�X�����ꕔ�C���E�ړ��E���A�b�v���[�h
 * MD.050           : MD050_CFF_004_A30_���[�X�����ꕔ�C���E�ړ��E���A�b�v���[�h
 * Version          : 1.5
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         ��������                                  (A-1)
 *  get_for_validation           �Ó����`�F�b�N�p�̒l�擾                  (A-2)
 *  get_upload_data              �t�@�C���A�b�v���[�hIF�f�[�^�擾          (A-3)
 *  divide_item                  �f���~�^�������ڕ���                      (A-4)
 *  check_item_value             ���ڒl�`�F�b�N                            (A-5)
 *  ins_maintenance_wk           ���[�X���������e�i���X�e�[�u���쐬        (A-6)
 *  get_maintenance_wk           ���[�X���������e�i���X�e�[�u���擾        (A-7)
 *  check_object_exist           ���[�X�������݃`�F�b�N                    (A-8)
 *  check_mst_owner_company      �}�X�^�`�F�b�N(�{�ЍH��)                  (A-9)
 *  check_mst_department         �}�X�^�`�F�b�N(�Ǘ�����)                  (A-10)
 *  check_mst_cancellation_class �}�X�^�`�F�b�N(�����)                  (A-11)
 *  check_mst_lease_class        �}�X�^�`�F�b�N(���[�X���)                (A-12)
 *  check_mst_bond_accep_flag    �}�X�^�`�F�b�N(�؏����)                  (A-13)
 *  validate_bond_accep_flag     �Ó����`�F�b�N(�؏����)                  (A-14)
 *  call_facmn_chk_object_term   FA���ʊ֐�(�����R�[�h���`�F�b�N)        (A-15)
 *  check_cancellation_cancel    ���L�����Z���`�F�b�N                    (A-16)
 *  call_facmn_chk_paychked      FA���ʊ֐�(�x���ƍ��σ`�F�b�N)            (A-17)
 *  lock_object_tbl              ���[�X�����e�[�u�����b�N�擾(�ʏ�)        (A-18)
 *  lock_object_tbl_other        ���[�X�����e�[�u�����b�N�擾(���̑�)      (A-19)
 *  lock_object_hist_tbl         ���[�X���������e�[�u�����b�N�擾          (A-20)
 *  lock_ctrct_relation_tbl      ���[�X�_��֘A�e�[�u�����b�N�擾          (A-21)
 *  call_fa_common               FA���ʊ֐��N������(�ʏ�)                  (A-22)
 *  call_fa_common_other         FA���ʊ֐��N������(���̑�)                (A-23)
 *  call_facmn_chk_location      FA���ʊ֐�(���Ə��}�X�^�`�F�b�N)          (A-24)
 *
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0  SCS ���c         �V�K�쐬
 *  2009/02/10    1.1  SCS ���c         ���O�̏o�͐悪����Ă����ӏ����C��
 *  2009/02/18    1.2  SCS ���c         �؏���̂̏������A���łɏ؏���̍ς̃��R�[�h��
 *                                       �ւ��Ă͏������s��Ȃ��l�Ƀ`�F�b�N��ǉ�����
 *  2009/02/19    1.3  SCS ���c         �ڋq�R�[�h��ǉ�
 *  2009/02/23    1.4  SCS ���c         �_��X�e�[�^�X��204:�����̍ۂ̑Ή���ǉ�
 *  2009/05/18    1.5  SCS ����         [��QT1_0721]�f���~�^���������f�[�^�i�[�z��̌�����ύX
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
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
  -- ���b�N(�r�W�[)�G���[
  lock_expt             EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF004A30C'; -- �p�b�P�[�W��
--
  cv_csv_delimiter   CONSTANT VARCHAR2(1) := ','; --�J���}
  cv_const_y         CONSTANT VARCHAR2(1) := 'Y'; --'Y'
--
  --�؏���̃t���O
  cv_bond_acceptance_flag_0  CONSTANT VARCHAR2(1) := '0';  --�����
  cv_bond_acceptance_flag_1  CONSTANT VARCHAR2(1) := '1';  --��̍�
--
  --�����
  cv_cancel_class_1  CONSTANT VARCHAR2(1) := '1';  --���m��(���ȓs��)
  cv_cancel_class_2  CONSTANT VARCHAR2(1) := '2';  --���m��(�ی��Ή�)
  cv_cancel_class_3  CONSTANT VARCHAR2(1) := '3';  --���\��
  cv_cancel_class_4  CONSTANT VARCHAR2(1) := '4';  --���\��(���ȓs��)
  cv_cancel_class_5  CONSTANT VARCHAR2(1) := '5';  --���\��(�ی��Ή�)
  cv_cancel_class_9  CONSTANT VARCHAR2(1) := '9';  --���L�����Z��
--
  --���敪
  cv_cancel_type_1   CONSTANT VARCHAR2(1) := '1';  --���ȓs��
  cv_cancel_type_2   CONSTANT VARCHAR2(1) := '2';  --�ی��Ή�
--
  --�����X�e�[�^�X
  cv_ob_status_101   CONSTANT VARCHAR2(3) := '101';  --���_��
  cv_ob_status_108   CONSTANT VARCHAR2(3) := '108';  --���r���\��
--
  --�_��X�e�[�^�X
  cv_ct_status_204   CONSTANT VARCHAR2(3) := '204';  --����
--
  --�啪��
  cv_major_division_30  CONSTANT VARCHAR2(2) := '30';
  cv_major_division_40  CONSTANT VARCHAR2(2) := '40';
  cv_major_division_50  CONSTANT VARCHAR2(2) := '50';
  cv_major_division_60  CONSTANT VARCHAR2(2) := '60';
--
  --������
  cv_small_class_7      CONSTANT VARCHAR2(2) := '7';
  cv_small_class_8      CONSTANT VARCHAR2(2) := '8';
  cv_small_class_9      CONSTANT VARCHAR2(2) := '9';
  cv_small_class_10     CONSTANT VARCHAR2(2) := '10';
--
  --�������[�h
  cv_exce_mode_adj   CONSTANT VARCHAR2(20) := 'ADJUSTMENT';    -- �C��
  cv_exce_mode_chg   CONSTANT VARCHAR2(20) := 'CHANGE';        -- �ύX
--  cv_exce_mode_mov   CONSTANT VARCHAR2(20) := 'MOVE';          -- �ړ�
  cv_exce_mode_dis   CONSTANT VARCHAR2(20) := 'DISSOLUTION';   -- ���L�����Z��
  cv_exce_mode_can   CONSTANT VARCHAR2(20) := 'CANCELLATION';  -- ���m��
--
    --�����/�؏���̃t���O�̏������ʃt���O
  cv_proc_flag_tbl   CONSTANT VARCHAR2(3) := 'TBL'; --����ʂɒl�����݂���ꍇ�̏���
  cv_proc_flag_csv   CONSTANT VARCHAR2(3) := 'CSV'; --�؏���̂ɒl�����݂���ꍇ�̏���
--
  -- ***�o�̓^�C�v
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';      --�o��(���[�U���b�Z�[�W�p�o�͐�)
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';         --���O(�V�X�e���Ǘ��җp�o�͐�)
--
  -- ***�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff   CONSTANT VARCHAR2(5) := 'XXCFF'; --�A�h�I���F��v�E���[�X�EFA�̈�
  cv_msg_kbn_ccp   CONSTANT VARCHAR2(5) := 'XXCCP'; --���ʂ̃��b�Z�[�W

  -- ***���b�Z�[�W��(�{��)
  cv_msg_name1     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00094'; --���ʊ֐��G���[
  cv_msg_name2     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00095'; --���ʊ֐����b�Z�[�W
  cv_msg_name3     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00124'; --���ڒl�`�F�b�N�G���[
  cv_msg_name4     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00176'; --�����R�[�h�d���G���[
  cv_msg_name5     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00123'; --���݃`�F�b�N�G���[
  cv_msg_name6     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00129'; --�؏���̍σ`�F�b�N�G���[
  cv_msg_name7     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00136'; --�X�e�[�^�X�G���[
  cv_msg_name8     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007'; --���b�N�G���[
  cv_msg_name9     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00128'; --���L�����Z���`�F�b�N�G���[
  cv_msg_name10    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00120'; --�x���ƍ��ς݃G���[
  cv_msg_name11    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00104'; --�폜�G���[
  cv_msg_name12    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00159'; --�����G���[�Ώ�
--
  cv_msg_name29    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00167'; --�A�b�v���[�h�����o�̓��b�Z�[�W
  cv_msg_name30    CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000'; --�Ώی������b�Z�[�W
  cv_msg_name31    CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001'; --�����������b�Z�[�W
  cv_msg_name32    CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002'; --�G���[�������b�Z�[�W
  cv_msg_name33    CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90003'; --�X�L�b�v�������b�Z�[�W
--
  -- ***���b�Z�[�W��(�g�[�N��)
  cv_tkn_val1      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50130'; --��������
  cv_tkn_val2      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50131'; --BLOB�f�[�^�ϊ��p�֐�
  cv_tkn_val3      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50165'; --�f���~�^���������֐�
  cv_tkn_val4      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50166'; --���ڃ`�F�b�N
  cv_tkn_val5      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50012'; --�{�ЍH��
  cv_tkn_val6      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50011'; --�Ǘ�����R�[�h
  cv_tkn_val7      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50141'; --���Ə��}�X�^�`�F�b�N
  cv_tkn_val8      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50017'; --���[�X���
  cv_tkn_val9      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50014'; --���[�X�����e�[�u��
  cv_tkn_val10     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50023'; --���[�X���������e�[�u��
  cv_tkn_val11     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50169'; --���[�X�������쐬�i�o�b�`�j
  cv_tkn_val12     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50170'; --�����
  cv_tkn_val13     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50173'; --���[�X�_��֘A
  cv_tkn_val14     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50015'; --���[�X�������쐬
  cv_tkn_val15     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50021'; --�؏���̃t���O
  cv_tkn_val16     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50174'; --���[�X���������e�i���X�e�[�u��
  cv_tkn_val17     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50175'; --�t�@�C���A�b�v���[�hI/F�e�[�u��
  cv_tkn_val18     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50176'; --���[�X�����ꕔ�C���E�ړ��E���
  cv_tkn_val19     CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50185'; --�����R�[�h���`�F�b�N
--
  -- ***�g�[�N����
  -- �v���t�@�C����
  cv_tkn_name1     CONSTANT VARCHAR2(100) := 'FUNC_NAME';   --���ʊ֐���
  cv_tkn_name2     CONSTANT VARCHAR2(100) := 'COLUMN_NAME'; --���ږ�
  cv_tkn_name3     CONSTANT VARCHAR2(100) := 'COLUMN_INFO'; --���ڏ��
  cv_tkn_name4     CONSTANT VARCHAR2(100) := 'OBJECT_CODE'; --�����R�[�h
  cv_tkn_name5     CONSTANT VARCHAR2(100) := 'COLUMN_DATA'; --���ڃf�[�^
  cv_tkn_name6     CONSTANT VARCHAR2(100) := 'ERR_MSG';     --�G���[���b�Z�[�W
  cv_tkn_name7     CONSTANT VARCHAR2(100) := 'TABLE_NAME';  --�e�[�u��
  cv_tkn_name8     CONSTANT VARCHAR2(100) := 'INFO';        --���b�Z�[�W
  cv_tkn_name9     CONSTANT VARCHAR2(100) := 'FILE_NAME';   -- �t�@�C�����g�[�N��
  cv_tkn_name10    CONSTANT VARCHAR2(100) := 'CSV_NAME';    -- CSV�t�@�C�����g�[�N��
--
  -- ***�v���t�@�C������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  --�������ڕ�����f�[�^�i�[�z��
  --[��QT1_0721]MOD START
  --TYPE g_load_data_ttype           IS TABLE OF VARCHAR2(200) INDEX BY PLS_INTEGER;
  TYPE g_load_data_ttype           IS TABLE OF VARCHAR2(600) INDEX BY PLS_INTEGER;
  --[��QT1_0721]MOD END
--
  -- ***�o���N�t�F�b�`�p��`
--
  --�Ó����`�F�b�N�p�̒l�擾�p��`
  TYPE g_column_desc_ttype         IS TABLE OF xxcff_object_adj_upload_v.column_desc%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_ttype          IS TABLE OF xxcff_object_adj_upload_v.byte_count%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_decimal_ttype  IS TABLE OF xxcff_object_adj_upload_v.byte_count_decimal%TYPE INDEX BY PLS_INTEGER;
  TYPE g_pay_match_flag_name_ttype IS TABLE OF xxcff_object_adj_upload_v.payment_match_flag_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_item_attribute_ttype      IS TABLE OF xxcff_object_adj_upload_v.item_attribute%TYPE INDEX BY PLS_INTEGER;
--
  --���[�X���������e�i���X�e�[�u���擾�p��`
  TYPE g_object_header_id_ttype      IS TABLE OF xxcff_object_headers.object_header_id%TYPE INDEX BY PLS_INTEGER;         --��������ID
  TYPE g_contract_header_id_ttype    IS TABLE OF xxcff_contract_headers.contract_header_id%TYPE INDEX BY PLS_INTEGER;     --�_�����ID
  TYPE g_contract_line_id_ttype      IS TABLE OF xxcff_contract_lines.contract_line_id%TYPE INDEX BY PLS_INTEGER;         --�_�񖾍ד���ID
  TYPE g_contract_status_ttype       IS TABLE OF xxcff_contract_lines.contract_status%TYPE INDEX BY PLS_INTEGER;          --�_��X�e�[�^�X
  TYPE g_cancellation_class_ttype    IS TABLE OF xxcff_maintenance_work.cancellation_class%TYPE INDEX BY PLS_INTEGER;     --�����
  TYPE g_object_code_ttype           IS TABLE OF xxcff_maintenance_work.object_code%TYPE INDEX BY PLS_INTEGER;            --�����R�[�h
  TYPE g_bond_acceptance_flag_ttype  IS TABLE OF xxcff_maintenance_work.bond_acceptance_flag%TYPE INDEX BY PLS_INTEGER;   --�؏���̃t���O
  TYPE g_lease_class_ttype           IS TABLE OF xxcff_object_headers.lease_class%TYPE INDEX BY PLS_INTEGER;              --���[�X���
  TYPE g_lease_type_ttype            IS TABLE OF xxcff_object_headers.lease_type%TYPE INDEX BY PLS_INTEGER;               --���[�X�敪
  TYPE g_re_lease_times_ttype        IS TABLE OF xxcff_object_headers.re_lease_times%TYPE INDEX BY PLS_INTEGER;           --�ă��[�X��
  TYPE g_po_number_ttype             IS TABLE OF xxcff_object_headers.po_number%TYPE INDEX BY PLS_INTEGER;                --�����ԍ�
  TYPE g_registration_number_ttype   IS TABLE OF xxcff_object_headers.registration_number%TYPE INDEX BY PLS_INTEGER;      --�o�^�ԍ�
  TYPE g_age_type_ttype              IS TABLE OF xxcff_object_headers.age_type%TYPE INDEX BY PLS_INTEGER;                 --�N��
  TYPE g_model_ttype                 IS TABLE OF xxcff_object_headers.model%TYPE INDEX BY PLS_INTEGER;                    --�@��
  TYPE g_serial_number_ttype         IS TABLE OF xxcff_object_headers.serial_number%TYPE INDEX BY PLS_INTEGER;            --�@��
  TYPE g_quantity_ttype              IS TABLE OF xxcff_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;                 --����
  TYPE g_manufacturer_name_ttype     IS TABLE OF xxcff_object_headers.manufacturer_name%TYPE INDEX BY PLS_INTEGER;        --���[�J�[��
  TYPE g_department_code_ttype       IS TABLE OF xxcff_object_headers.department_code%TYPE INDEX BY PLS_INTEGER;          --�Ǘ�����R�[�h
  TYPE g_owner_company_ttype         IS TABLE OF xxcff_object_headers.owner_company%TYPE INDEX BY PLS_INTEGER;            --�{�ЍH��(�{�Ё^�H��)
  TYPE g_installation_address_ttype  IS TABLE OF xxcff_object_headers.installation_address%TYPE INDEX BY PLS_INTEGER;     --���ݒu�ꏊ
  TYPE g_installation_place_ttype    IS TABLE OF xxcff_object_headers.installation_place%TYPE INDEX BY PLS_INTEGER;       --���ݒu��
  TYPE g_chassis_number_ttype        IS TABLE OF xxcff_object_headers.chassis_number%TYPE INDEX BY PLS_INTEGER;           --�ԑ�ԍ�
  TYPE g_re_lease_flag_ttype         IS TABLE OF xxcff_object_headers.re_lease_flag%TYPE INDEX BY PLS_INTEGER;            --�ă��[�X�v�t���O
  TYPE g_cancellation_type_ttype     IS TABLE OF xxcff_object_headers.cancellation_type%TYPE INDEX BY PLS_INTEGER;        --���敪
  TYPE g_cancellation_date_ttype     IS TABLE OF xxcff_object_headers.cancellation_date%TYPE INDEX BY PLS_INTEGER;        --���r����
  TYPE g_dissolution_date_ttype      IS TABLE OF xxcff_object_headers.dissolution_date%TYPE INDEX BY PLS_INTEGER;         --���r���L�����Z����
  TYPE g_bond_acceptance_date_ttype  IS TABLE OF xxcff_object_headers.bond_acceptance_date%TYPE INDEX BY PLS_INTEGER;     --�؏���̓�
  TYPE g_expiration_date_ttype       IS TABLE OF xxcff_object_headers.expiration_date%TYPE INDEX BY PLS_INTEGER;          --������
  TYPE g_object_status_ttype         IS TABLE OF xxcff_object_headers.object_status%TYPE INDEX BY PLS_INTEGER;            --�����X�e�[�^�X
  TYPE g_active_flag_ttype           IS TABLE OF xxcff_object_headers.active_flag%TYPE INDEX BY PLS_INTEGER;              --�����L���t���O
  TYPE g_info_sys_if_date_ttype      IS TABLE OF xxcff_object_headers.info_sys_if_date%TYPE INDEX BY PLS_INTEGER;         --���[�X�Ǘ����A�g��
  TYPE g_generation_date_ttype       IS TABLE OF xxcff_object_headers.generation_date%TYPE INDEX BY PLS_INTEGER;          --������
  TYPE g_customer_code_ttype         IS TABLE OF xxcff_object_headers.customer_code%TYPE INDEX BY PLS_INTEGER;            --�ڋq�R�[�h
--
  --�}�X�^�`�F�b�N�p��`
  TYPE g_mst_check_ttype             IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
--
  --���b�N�擾�p��`
  TYPE g_small_class_ttype           IS TABLE OF xxcff_obj_ins_status_v.small_class%TYPE INDEX BY PLS_INTEGER;            --������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- �����l���
  g_init_rec                     xxcff_common1_pkg.init_rtype;
--
  --�t�@�C���A�b�v���[�hIF�f�[�^
  g_file_upload_if_data_tab      xxccp_common_pkg2.g_file_data_tbl;
--
  --�������ڕ�����f�[�^�i�[�z��
  g_load_data_tab                g_load_data_ttype;
--
  --CSV�̕����R�[�h��ێ�
  g_csv_object_code              VARCHAR2(100);
--
  -- ***�o���N�t�F�b�`�p��`
--
  --�Ó����`�F�b�N�p�̒l�擾�p��`
  g_column_desc_tab              g_column_desc_ttype;
  g_byte_count_tab               g_byte_count_ttype;
  g_byte_count_decimal_tab       g_byte_count_decimal_ttype;
  g_pay_match_flag_name_tab      g_pay_match_flag_name_ttype;
  g_item_attribute_tab           g_item_attribute_ttype;
--
  --���[�X���������e�i���X�e�[�u���擾�p��`
  g_object_header_id_tab         g_object_header_id_ttype;     --��������ID
  g_contract_header_id_tab       g_contract_header_id_ttype;   --�_�����ID
  g_contract_line_id_tab         g_contract_line_id_ttype;     --�_�񖾍ד���ID
  g_contract_status_tab          g_contract_status_ttype;      --�_��X�e�[�^�X
  g_cancellation_class_tab       g_cancellation_class_ttype;   --�����
  g_object_code_tab              g_object_code_ttype;          --�����R�[�h
  g_bond_acceptance_flag_xmw_tab g_bond_acceptance_flag_ttype; --�؏���̃t���O(�����e�i���X�e�[�u��)
  g_lease_class_tab              g_lease_class_ttype;          --���[�X���
  g_lease_type_tab               g_lease_type_ttype;           --���[�X�敪
  g_re_lease_times_tab           g_re_lease_times_ttype;       --�ă��[�X��
  g_po_number_tab                g_po_number_ttype;            --�����ԍ�
  g_registration_number_tab      g_registration_number_ttype;  --�o�^�ԍ�
  g_age_type_tab                 g_age_type_ttype;             --�N��
  g_model_tab                    g_model_ttype;                --�@��
  g_serial_number_tab            g_serial_number_ttype;        --�@��
  g_quantity_tab                 g_quantity_ttype;             --����
  g_manufacturer_name_tab        g_manufacturer_name_ttype;    --���[�J�[��
  g_department_code_tab          g_department_code_ttype;      --�Ǘ�����R�[�h
  g_owner_company_tab            g_owner_company_ttype;        --�{�ЍH��(�{�Ё^�H��)
  g_installation_address_tab     g_installation_address_ttype; --���ݒu�ꏊ
  g_installation_place_tab       g_installation_place_ttype;   --���ݒu��
  g_chassis_number_tab           g_chassis_number_ttype;       --�ԑ�ԍ�
  g_re_lease_flag_tab            g_re_lease_flag_ttype;        --�ă��[�X�v�t���O
  g_cancellation_type_tab        g_cancellation_type_ttype;    --���敪
  g_cancellation_date_tab        g_cancellation_date_ttype;    --���r����
  g_dissolution_date_tab         g_dissolution_date_ttype;     --���r���L�����Z����
  g_bond_acceptance_flag_tab     g_bond_acceptance_flag_ttype; --�؏���̃t���O(�����e�[�u��)
  g_bond_acceptance_date_tab     g_bond_acceptance_date_ttype; --�؏���̓�
  g_expiration_date_tab          g_expiration_date_ttype;      --������
  g_object_status_tab            g_object_status_ttype;        --�����X�e�[�^�X
  g_active_flag_tab              g_active_flag_ttype;          --�����L���t���O
  g_info_sys_if_date_tab         g_info_sys_if_date_ttype;     --���[�X�Ǘ����A�g��
  g_generation_date_tab          g_generation_date_ttype;      --������
  g_customer_code_tab            g_customer_code_ttype;        --�ڋq�R�[�h
--
  --���[�X�������쐬�p��`
  g_re_lease_times_ob_tab        g_re_lease_times_ttype;       --�ă��[�X��
  g_small_class_ob_tab           g_small_class_ttype;          --������
--
  --�}�X�^�`�F�b�N�p��`
  g_mst_check_tab                g_mst_check_ttype;
--
  --���b�N�擾�p��`
  g_object_header_id_lock_tab    g_object_header_id_ttype;     --��������ID
  g_contract_line_id_lock_tab    g_contract_line_id_ttype;     --�_�񖾍ד���ID
--
  --���b�N�t���O
  gb_lock_ob_flag                BOOLEAN;
  gb_lock_ob_hist_flag           BOOLEAN;
  --�G���[�t���O
  gb_err_flag                    BOOLEAN;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- �v���O������
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
    lv_file_name    xxccp_mrp_file_ul_interface.file_name%TYPE; -- �擾�t�@�C����
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
      --�A�b�v���[�hCSV�t�@�C�����擾
      SELECT
              xfu.file_name
      INTO
              lv_file_name
      FROM
              xxccp_mrp_file_ul_interface  xfu
      WHERE
              xfu.file_id = in_file_id;

      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG      --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
       ,buff   => xxccp_common_pkg.get_msg(cv_msg_kbn_cff, cv_msg_name29
                                          ,cv_tkn_name9,   cv_tkn_val18
                                          ,cv_tkn_name10,    lv_file_name)
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => xxccp_common_pkg.get_msg(cv_msg_kbn_cff, cv_msg_name29
                                           ,cv_tkn_name9,   cv_tkn_val18
                                           ,cv_tkn_name10,    lv_file_name)
      );
--
    --�@�R���J�����g�p�����[�^��\��
--
    -- �R���J�����g�p�����[�^�l�o��(�o�͂̕\��)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- �R���J�����g�p�����[�^�l�o��(���O)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- �o�͋敪
      ,ov_errbuf        => lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode       => lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --�A�����l���̎擾
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- �����l���
      ,ov_errbuf   => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�B�����l���̎擾�����ŁA���^�[���R�[�h������ȊO�̏ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name1                         -- ���ʊ֐��G���[
                                                    ,cv_tkn_name1                         -- �g�[�N��'FUNC_NAME'
                                                    ,cv_tkn_val1 )                        -- ��������
                                                    || cv_msg_part
                                                    || lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
                                                    ,1
                                                    ,5000);
--      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_for_validation
   * Description      : �Ó����`�F�b�N�p�̒l�擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_for_validation(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_for_validation'; -- �v���O������
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
    CURSOR get_validate_cur
    IS
      SELECT
              xoa.column_desc              AS column_desc
             ,xoa.byte_count               AS byte_count
             ,xoa.byte_count_decimal       AS byte_count_decimal
             ,xoa.payment_match_flag_name  AS payment_match_flag_name
             ,xoa.item_attribute           AS item_attribute
        FROM
              xxcff_object_adj_upload_v  xoa --���[�X�����ꕔ�C���r���[
       ORDER BY
              xoa.code ASC
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�J�[�\���̃I�[�v��
    OPEN get_validate_cur;
    FETCH get_validate_cur
    BULK COLLECT INTO g_column_desc_tab          --���ږ���
                     ,g_byte_count_tab           --�o�C�g��
                     ,g_byte_count_decimal_tab   --�o�C�g��_�����_�ȉ�
                     ,g_pay_match_flag_name_tab  --�K�{�t���O
                     ,g_item_attribute_tab       --���ڑ���
    ;
--
    --�J�[�\���̃N���[�Y
    CLOSE get_validate_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( get_validate_cur%ISOPEN ) THEN
        CLOSE get_validate_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_for_validation;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : �t�@�C���A�b�v���[�hIF�f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�t�@�C���A�b�v���[�hIF�f�[�^���擾
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id                 -- �t�@�C��ID
     ,ov_file_data => g_file_upload_if_data_tab  -- �ϊ���VARCHAR2�f�[�^
     ,ov_errbuf    => lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name1                         -- ���ʊ֐��G���[
                                                    ,cv_tkn_name1                         -- �g�[�N��'FUNC_NAME'
                                                    ,cv_tkn_val2 )                        -- BLOB�f�[�^�ϊ��p�֐�
                                                    || cv_msg_part
                                                    || lv_errmsg                          --���ʊ֐���װү����
                                                    ,1
                                                    ,5000)
      ;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : �f���~�^�������ڕ�������(A-4)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_loop_cnt_1 IN  NUMBER,       --  ���[�v�J�E���^1
    in_loop_cnt_2 IN  NUMBER,       --  ���[�v�J�E���^2
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_item'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�f���~�^���������̋��ʊ֐��̌ďo
    g_load_data_tab(in_loop_cnt_2) := xxccp_common_pkg.char_delim_partition(
                                        g_file_upload_if_data_tab(in_loop_cnt_1) --������������(�擾�f�[�^)
                                       ,cv_csv_delimiter                         --�f���~�^����
                                       ,in_loop_cnt_2                            --�ԋp�Ώ�INDEX
    );
    --�������̕����R�[�h��ێ�
    IF ( in_loop_cnt_2 = 1 ) THEN
      g_csv_object_code := g_load_data_tab(in_loop_cnt_2);
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      --�G���[�t���O��TRUE�ɂ���
      gb_err_flag := TRUE;
      --�G���[���b�Z�[�W���o�͂���
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name1                         -- ���ʊ֐��G���[
                                                    ,cv_tkn_name1                         -- �g�[�N��'FUNC_NAME'
                                                    ,cv_tkn_val3 )                        -- �f���~�^���������֐�
                                                    ,1
                                                    ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_errmsg
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END divide_item;
--
  /**********************************************************************************
   * Procedure Name   : check_item_value
   * Description      : ���ڒl�`�F�b�N����(A-5)
   ***********************************************************************************/
  PROCEDURE check_item_value(
    in_loop_cnt_2 IN  NUMBER,       -- ���[�v�J�E���^2
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_value'; -- �v���O������
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
    lv_warn_msg  VARCHAR2(5000); --�x�����b�Z�[�W
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���ڒl�`�F�b�N���s��
--
    --���ڃ`�F�b�N�̋��ʊ֐��̌ďo
    xxccp_common_pkg2.upload_item_check(
       iv_item_name    => g_column_desc_tab(in_loop_cnt_2)          -- ���ږ���
      ,iv_item_value   => g_load_data_tab(in_loop_cnt_2)            -- ���ڂ̒l
      ,in_item_len     => g_byte_count_tab(in_loop_cnt_2)           -- �o�C�g��/���ڂ̒���
      ,in_item_decimal => g_byte_count_decimal_tab(in_loop_cnt_2)   -- �o�C�g��_�����_�ȉ�/���ڂ̒����i�����_�ȉ��j
      ,iv_item_nullflg => g_pay_match_flag_name_tab(in_loop_cnt_2)  -- �K�{�t���O
      ,iv_item_attr    => g_item_attribute_tab(in_loop_cnt_2)       -- ���ڑ���
      ,ov_errbuf       => lv_errbuf                               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode                              -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --���^�[���R�[�h���x���̏ꍇ
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name1                         -- ���ʊ֐��G���[
                                                      ,cv_tkn_name1                         -- �g�[�N��'FUNC_NAME'
                                                      ,cv_tkn_val4  )                       -- ���ʊ֐���
                                                      ,1
                                                      ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warn_msg
      );
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name2                         -- ���ʊ֐����b�Z�[�W
                                                    ,cv_tkn_name6                         -- �g�[�N��'ERR_MSG'
                                                    ,lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W
                                                   )
                                                   || xxccp_common_pkg.get_msg(
                                                        cv_msg_kbn_cff                   --XXCFF
                                                       ,cv_msg_name12                    --�����G���[�Ώ�
                                                       ,cv_tkn_name4                     --�g�[�N��'OBJECT_CODE'
                                                       ,g_csv_object_code                -- CSV�̕����R�[�h
                                                      )
                                                    ,1
                                                    ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_errmsg
      );
      --�G���[�t���O��TRUE�ɂ���
      gb_err_flag := TRUE;
      --�����p���ׁ̈A���^�[���R�[�h��������
      lv_retcode := cv_status_normal;
    --���^�[���R�[�h���G���[�̏ꍇ
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_item_value;
--
  /**********************************************************************************
   * Procedure Name   : ins_maintenance_wk
   * Description      : ���[�X���������e�i���X�e�[�u���쐬����(A-6)
   ***********************************************************************************/
  PROCEDURE ins_maintenance_wk(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_maintenance_wk'; -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�X���������e�i���X�e�[�u��(���������e�i���X���[�N)�쐬
    INSERT INTO xxcff_maintenance_work (
      file_id                 --�t�@�C��ID
     ,object_code             --�����R�[�h
     ,owner_company           --�{�ЍH��
     ,department_code         --�Ǘ�����R�[�h
     ,registration_number     --�o�^�ԍ�
     ,po_number               --�����ԍ�
     ,manufacturer_name       --���[�J�[��
     ,model                   --�@��
     ,serial_number           --�@��
     ,age_type                --�N��
     ,quantity                --����
     ,chassis_number          --�ԑ�ԍ�
     ,installation_address    --���ݒu�ꏊ
     ,installation_place      --���ݒu��
     ,cancellation_class      --�����
     ,bond_acceptance_flag    --�؏���̃t���O
     ,created_by              --�쐬��
     ,creation_date           --�쐬��
     ,last_updated_by         --�ŏI�X�V��
     ,last_update_date        --�ŏI�X�V��
     ,last_update_login       --�ŏI�X�V۸޲�
     ,request_id              --�v��ID
     ,program_application_id  --�ݶ��ĥ��۸��ѥ���ع����ID
     ,program_id              --�ݶ��ĥ��۸���ID
     ,program_update_date     --��۸��эX�V��
    )
    VALUES (
      in_file_id                 --�t�@�C��ID
     ,g_load_data_tab(1)         --�����R�[�h
     ,g_load_data_tab(2)         --�{�ЍH��
     ,g_load_data_tab(3)         --�Ǘ�����
     ,g_load_data_tab(4)         --�o�^�ԍ�
     ,g_load_data_tab(5)         --�����ԍ�
     ,g_load_data_tab(6)         --���[�J�[��
     ,g_load_data_tab(7)         --�@��
     ,g_load_data_tab(8)         --�@��
     ,g_load_data_tab(9)         --�N��
     ,g_load_data_tab(10)        --����
     ,g_load_data_tab(11)        --�ԑ�ԍ�
     ,g_load_data_tab(12)        --���ݒu�ꏊ
     ,g_load_data_tab(13)        --���ݒu��
     ,g_load_data_tab(14)        --�����
     ,g_load_data_tab(15)        --�؏����
     ,cn_created_by              --�쐬��
     ,cd_creation_date           --�쐬��
     ,cn_last_updated_by         --�ŏI�X�V��
     ,cd_last_update_date        --�ŏI�X�V��
     ,cn_last_update_login       --�ŏI�X�V���O�C��
     ,cn_request_id              --�v��ID
     ,cn_program_application_id  --�ݶ��ĥ��۸��ѥ���ع����ID
     ,cn_program_id              --�R���J�����g��v���O����ID
     ,cd_program_update_date     --�v���O�����X�V��
    );
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      --�o�^���G���[(�����R�[�h�d��)�̏ꍇ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name4                         -- �����R�[�h�d���G���[(���[�N�e�[�u��)
                                                    ,cv_tkn_name4                         -- �g�[�N��'OBJECT_CODE'
                                                    ,g_load_data_tab(1) )                 -- �����R�[�h
                                                    ,1
                                                    ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END ins_maintenance_wk;
--
  /**********************************************************************************
   * Procedure Name   : get_maintenance_wk
   * Description      : ���[�X���������e�i���X�e�[�u���擾����(A-7)
   ***********************************************************************************/
  PROCEDURE get_maintenance_wk(
    in_file_id    IN  NUMBER,       -- 1.�t�@�C��ID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_maintenance_wk'; -- �v���O������
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
    CURSOR get_maintenance_wk_cur
    IS
      SELECT
              xoh.object_header_id         AS object_header_id          --��������ID
             ,xca.contract_header_id       AS contract_header_id        --�_�����ID
             ,xca.contract_line_id         AS contract_line_id          --�_�񖾍ד���ID
             ,DECODE (xoh.object_status, '101', xca.contract_status
                                              , NVL(xca.contract_status, cv_ct_status_204))
                                           AS contract_status
             ,xmw.cancellation_class       AS cancellation_class        --�����
             ,xmw.object_code              AS object_code               --�����R�[�h
             ,xmw.bond_acceptance_flag     AS bond_acceptance_flag_xmw  --�؏���̃t���O
             ,xoh.lease_class              AS lease_class               --���[�X���
             ,xoh.lease_type               AS lease_type                --���[�X�敪
             ,xoh.re_lease_times           AS re_lease_times            --�ă��[�X��
             ,NVL(xmw.po_number, xoh.po_number)                        AS po_number             --�����ԍ�
             ,NVL(xmw.registration_number, xoh.registration_number)    AS registration_number   --�o�^�ԍ�
             ,NVL(xmw.age_type, xoh.age_type)                          AS age_type              --�N��
             ,NVL(xmw.model, xoh.model)                                AS model                 --�@��
             ,NVL(xmw.serial_number, xoh.serial_number)                AS serial_number         --�@��
             ,NVL(xmw.quantity, xoh.quantity)                          AS quantity              --����
             ,NVL(xmw.manufacturer_name, xoh.manufacturer_name)        AS manufacturer_name     --���[�J�[��
             ,NVL(xmw.department_code, xoh.department_code)            AS department_code       --�Ǘ�����R�[�h
             ,NVL(xmw.owner_company, xoh.owner_company)                AS owner_company         --�{�ЍH��(�{�Ё^�H��)
             ,NVL(xmw.installation_address, xoh.installation_address)  AS installation_address  --���ݒu�ꏊ
             ,NVL(xmw.installation_place, xoh.installation_place)      AS installation_place    --���ݒu��
             ,NVL(xmw.chassis_number, xoh.chassis_number)              AS chassis_number        --�ԑ�ԍ�
             ,xoh.re_lease_flag            AS re_lease_flag             --�ă��[�X�v�t���O
             ,xoh.cancellation_type        AS cancellation_type         --���敪
             ,xoh.cancellation_date        AS cancellation_date         --���r����
             ,xoh.dissolution_date         AS dissolution_date          --���r���L�����Z����
             ,xoh.bond_acceptance_flag     AS bond_acceptance_flag      --�؏���̃t���O
             ,xoh.bond_acceptance_date     AS bond_acceptance_date      --�؏���̓�
             ,xoh.expiration_date          AS expiration_date           --������
             ,xoh.object_status            AS object_status             --�����X�e�[�^�X
             ,xoh.active_flag              AS active_flag               --�����L���t���O
             ,xoh.info_sys_if_date         AS info_sys_if_date          --���[�X�Ǘ����A�g��
             ,xoh.generation_date          AS generation_date           --������
             ,xoh.customer_code            AS customer_code             --�ڋq�R�[�h
        FROM
              xxcff_maintenance_work  xmw  --���������e�i���X���[�N(���[�X���������e�i���X�e�[�u��)
             ,xxcff_object_headers    xoh  --���[�X����
             ,(SELECT
                       xch.contract_header_id
                      ,xcl.contract_line_id
                      ,xcl.contract_status
                      ,xcl.object_header_id
                      ,xch.re_lease_times
                 FROM
                       xxcff_contract_headers  xch  --���[�X�_��
                      ,xxcff_contract_lines    xcl  --���[�X�_�񖾍�
                WHERE
                       xch.contract_header_id  = xcl.contract_header_id  --�_�����ID
              )                       xca
       WHERE
              xmw.object_code         = xoh.object_code(+)      --�����R�[�h
         AND  xoh.object_header_id    = xca.object_header_id(+) --��������ID
         AND  xoh.re_lease_times      = xca.re_lease_times(+)   --�ă��[�X��
         AND  xmw.file_id             = in_file_id              --�t�@�C��ID
       ORDER BY
              xmw.object_code ASC
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�X���������e�i���X���[�N�擾
    OPEN get_maintenance_wk_cur;  --�J�[�\���̃I�[�v��
    FETCH get_maintenance_wk_cur
    BULK COLLECT INTO g_object_header_id_tab         --��������ID
                     ,g_contract_header_id_tab       --�_�����ID
                     ,g_contract_line_id_tab         --�_�񖾍ד���ID
                     ,g_contract_status_tab          --�_��X�e�[�^�X
                     ,g_cancellation_class_tab       --�����
                     ,g_object_code_tab              --�����R�[�h
                     ,g_bond_acceptance_flag_xmw_tab --�؏���̃t���O(�����e�i���X�e�[�u��)
                     ,g_lease_class_tab              --���[�X���
                     ,g_lease_type_tab               --���[�X�敪
                     ,g_re_lease_times_tab           --�ă��[�X��
                     ,g_po_number_tab                --�����ԍ�
                     ,g_registration_number_tab      --�o�^�ԍ�
                     ,g_age_type_tab                 --�N��
                     ,g_model_tab                    --�@��
                     ,g_serial_number_tab            --�@��
                     ,g_quantity_tab                 --����
                     ,g_manufacturer_name_tab        --���[�J�[��
                     ,g_department_code_tab          --�Ǘ�����R�[�h
                     ,g_owner_company_tab            --�{�ЍH��(�{�Ё^�H��)
                     ,g_installation_address_tab     --���ݒu�ꏊ
                     ,g_installation_place_tab       --���ݒu��
                     ,g_chassis_number_tab           --�ԑ�ԍ�
                     ,g_re_lease_flag_tab            --�ă��[�X�v�t���O
                     ,g_cancellation_type_tab        --���敪
                     ,g_cancellation_date_tab        --���r����
                     ,g_dissolution_date_tab         --���r���L�����Z����
                     ,g_bond_acceptance_flag_tab     --�؏���̃t���O(�����e�[�u��)
                     ,g_bond_acceptance_date_tab     --�؏���̓�
                     ,g_expiration_date_tab          --������
                     ,g_object_status_tab            --�����X�e�[�^�X
                     ,g_active_flag_tab              --�����L���t���O
                     ,g_info_sys_if_date_tab         --���[�X�Ǘ����A�g��
                     ,g_generation_date_tab          --������
                     ,g_customer_code_tab            --�ڋq�R�[�h
    ;
    CLOSE get_maintenance_wk_cur;  --�J�[�\���̃N���[�Y
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( get_maintenance_wk_cur%ISOPEN ) THEN
        CLOSE get_maintenance_wk_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_maintenance_wk;
--
  /**********************************************************************************
   * Procedure Name   : check_object_exist
   * Description      : ���[�X�������݃`�F�b�N����(A-8)
   ***********************************************************************************/
  PROCEDURE check_object_exist(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_object_exist'; -- �v���O������
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
    lv_warn_msg    VARCHAR2(5000);      --�x�����b�Z�[�W
    ln_normal_cnt  PLS_INTEGER := 0;    --����J�E���^�[
    ln_error_cnt   PLS_INTEGER := 0;    --�G���[�J�E���^�[
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ��������ID��NULL�ł͂Ȃ����`�F�b�N
    <<chk_exist_loop>>
    FOR ln_loop_cnt IN g_object_code_tab.FIRST .. g_object_code_tab.LAST LOOP
      IF ( g_object_header_id_tab(ln_loop_cnt) IS NULL ) THEN
        lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                        ,cv_msg_name5                         -- ���݃`�F�b�N�G���[
                                                        ,cv_tkn_name5                         -- �g�[�N��'COLUMN_DATA'
                                                        ,g_object_code_tab(ln_loop_cnt) )     -- �����R�[�h
                                                        ,1
                                                        ,5000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
          ,buff   => lv_warn_msg
        );
        --�G���[�J�E���^�C���N�������g
        ln_error_cnt  := ( ln_error_cnt + 1 );
      END IF;
    END LOOP chk_exist_loop;
--
    --��������ID��NULL�̃f�[�^�����݂����ꍇ
    IF ( ln_error_cnt <> 0 ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_object_exist;
--
  /**********************************************************************************
   * Procedure Name   : check_mst_owner_company
   * Description      : �}�X�^�`�F�b�N(�{�ЍH��)����(A-9)
   ***********************************************************************************/
  PROCEDURE check_mst_owner_company(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_mst_owner_company'; -- �v���O������
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
    lv_warn_msg  VARCHAR2(5000); --�x�����b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR check_cur
    IS
      SELECT
              NULL
        FROM
              xxcff_owner_company_v  xocv  --�{�ЍH��r���[
       WHERE
              xocv.owner_company_code = g_owner_company_tab(in_loop_cnt_3)
         AND  xocv.enabled_flag       = cv_const_y
         AND  (   ( xocv.start_date_active IS NULL )
               OR ( xocv.start_date_active <= g_init_rec.process_date )   )
         AND  (   ( xocv.end_date_active IS NULL )
               OR ( xocv.end_date_active >= g_init_rec.process_date )   )
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �}�X�^�`�F�b�N(�{��/�H��)
    OPEN check_cur;
    FETCH check_cur
    BULK COLLECT INTO g_mst_check_tab
    ;
--
    --�Ώۃf�[�^���Ȃ��ꍇ
    IF ( check_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name3                         -- ���ڒl�`�F�b�N�G���[
                                                      ,cv_tkn_name2                         -- �g�[�N��'COLUMN_NAME'
                                                      ,cv_tkn_val5                          -- �{�ЍH��
                                                      ,cv_tkn_name3                         -- �g�[�N��'COLUMN_INFO'
                                                      ,g_owner_company_tab(in_loop_cnt_3)   -- �{�ЍH��(�l)
                                                     )
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --�����G���[�Ώ�
                                                         ,cv_tkn_name4                     --�g�[�N��'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- �����R�[�h
                                                        )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warn_msg
      );
      --�G���[�t���O��TRUE�ɂ���
      gb_err_flag := TRUE;
    END IF;
--
    CLOSE check_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( check_cur%ISOPEN ) THEN
        CLOSE check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_mst_owner_company;
--
  /**********************************************************************************
   * Procedure Name   : check_mst_department
   * Description      : �}�X�^�`�F�b�N(�Ǘ�����)����(A-10)
   ***********************************************************************************/
  PROCEDURE check_mst_department(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_mst_department'; -- �v���O������
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
    lv_warn_msg  VARCHAR2(5000); --�x�����b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR check_cur
    IS
      SELECT
              NULL
        FROM
              xxcff_department_v  xdv  --�Ǘ�����r���[
       WHERE
              xdv.department_code  = g_department_code_tab(in_loop_cnt_3) --�Ǘ�����R�[�h
         AND  xdv.enabled_flag     = cv_const_y                           --�L���t���O
         AND  (   ( xdv.start_date_active IS NULL )
               OR ( xdv.start_date_active <= g_init_rec.process_date )   )
         AND  (   ( xdv.end_date_active IS NULL )
               OR ( xdv.end_date_active >= g_init_rec.process_date )   )
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �}�X�^�`�F�b�N(�Ǘ�����)
    OPEN check_cur;
    FETCH check_cur
    BULK COLLECT INTO g_mst_check_tab
    ;
--
    --�Ώۃf�[�^���Ȃ��ꍇ
    IF ( check_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name3                         -- ���ڒl�`�F�b�N�G���[
                                                      ,cv_tkn_name2                         -- �g�[�N��'COLUMN_NAME'
                                                      ,cv_tkn_val6                          -- �Ǘ�����R�[�h
                                                      ,cv_tkn_name4                         -- �g�[�N��'OBJECT_CODE'
                                                      ,g_object_code_tab(in_loop_cnt_3)     -- �����R�[�h
                                                      ,cv_tkn_name3                         -- �g�[�N��'COLUMN_INFO'
                                                      ,g_department_code_tab(in_loop_cnt_3) -- �Ǘ�����R�[�h(�l)
                                                     )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warn_msg
      );
      --�G���[�t���O��TRUE�ɂ���
      gb_err_flag := TRUE;
    END IF;
--
    CLOSE check_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( check_cur%ISOPEN ) THEN
        CLOSE check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_mst_department;
--
  /**********************************************************************************
   * Procedure Name   : check_mst_cancellation_class
   * Description      : �}�X�^�`�F�b�N(�����)����(A-11)
   ***********************************************************************************/
  PROCEDURE check_mst_cancellation_class(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_mst_cancellation_class'; -- �v���O������
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
    lv_warn_msg  VARCHAR2(5000); --�x�����b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR check_cur
    IS
      SELECT
              NULL
        FROM
              xxcff_cancellation_class_v  xccv  --����ʃr���[
       WHERE
              xccv.cancellation_class_code  = g_cancellation_class_tab(in_loop_cnt_3)  --����ʃR�[�h
         AND  xccv.enabled_flag             = cv_const_y                               --�L���t���O
         AND  (   ( xccv.start_date_active IS NULL )
               OR ( xccv.start_date_active <= g_init_rec.process_date )   )
         AND  (   ( xccv.end_date_active IS NULL )
               OR ( xccv.end_date_active >= g_init_rec.process_date )   )
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �}�X�^�`�F�b�N(�����)
    OPEN check_cur;
    FETCH check_cur
    BULK COLLECT INTO g_mst_check_tab
    ;
--
    --�Ώۃf�[�^���Ȃ��ꍇ
    IF ( check_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                          -- XXCFF
                                                      ,cv_msg_name3                            -- ���ڒl�`�F�b�N�G���[
                                                      ,cv_tkn_name2                            -- �g�[�N��'COLUMN_NAME'
                                                      ,cv_tkn_val12                            -- �����
                                                      ,cv_tkn_name4                            -- �g�[�N��'OBJECT_CODE'
                                                      ,g_object_code_tab(in_loop_cnt_3)        -- �����R�[�h
                                                      ,cv_tkn_name3                            -- �g�[�N��'COLUMN_INFO'
                                                      ,g_cancellation_class_tab(in_loop_cnt_3) -- ����ʃR�[�h(�l)
                                                     )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warn_msg
      );
      --�G���[�t���O��TRUE�ɂ���
      gb_err_flag := TRUE;
    END IF;
--
    CLOSE check_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( check_cur%ISOPEN ) THEN
        CLOSE check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_mst_cancellation_class;
--
  /**********************************************************************************
   * Procedure Name   : check_mst_lease_class
   * Description      : �}�X�^�`�F�b�N(���[�X���)����(A-12)
   ***********************************************************************************/
  PROCEDURE check_mst_lease_class(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_mst_lease_class'; -- �v���O������
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
    lv_warn_msg  VARCHAR2(5000); --�x�����b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR check_cur
    IS
      SELECT
              NULL
        FROM
              xxcff_lease_class_v  xlcv  --���[�X��ʃr���[
       WHERE
              xlcv.lease_class_code = g_lease_class_tab(in_loop_cnt_3)     --���[�X��ʃR�[�h
         AND  xlcv.vdsh_flag        IS NULL                                --���̋@_SH�t���O
         AND  xlcv.enabled_flag     = cv_const_y                           --�L���t���O
         AND  (   ( xlcv.start_date_active IS NULL )
               OR ( xlcv.start_date_active <= g_init_rec.process_date )   )
         AND  (   ( xlcv.end_date_active IS NULL )
               OR ( xlcv.end_date_active >= g_init_rec.process_date )   )
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �}�X�^�`�F�b�N(���[�X���)
    OPEN check_cur;
    FETCH check_cur
    BULK COLLECT INTO g_mst_check_tab
    ;
--
    --�Ώۃf�[�^���Ȃ��ꍇ
    IF ( check_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name3                         -- ���ڒl�`�F�b�N�G���[
                                                      ,cv_tkn_name2                         -- �g�[�N��'COLUMN_NAME'
                                                      ,cv_tkn_val8                          -- ���[�X���
                                                      ,cv_tkn_name4                         -- �g�[�N��'OBJECT_CODE'
                                                      ,g_object_code_tab(in_loop_cnt_3)     -- �����R�[�h
                                                      ,cv_tkn_name3                         -- �g�[�N��'COLUMN_INFO'
                                                      ,g_lease_class_tab(in_loop_cnt_3)     -- ���[�X���(�l)
                                                     )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warn_msg
      );
      --�G���[�t���O��TRUE�ɂ���
      gb_err_flag := TRUE;
    END IF;
--
    CLOSE check_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( check_cur%ISOPEN ) THEN
        CLOSE check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_mst_lease_class;
--
  /**********************************************************************************
   * Procedure Name   : check_mst_bond_accep_flag
   * Description      : �}�X�^�`�F�b�N(�؏����)����(A-13)
   ***********************************************************************************/
  PROCEDURE check_mst_bond_accep_flag(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_mst_bond_accep_flag'; -- �v���O������
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
    lv_warn_msg  VARCHAR2(5000); --�x�����b�Z�[�W
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR check_cur
    IS
      SELECT
              NULL
        FROM
              xxcff_bond_acceptance_flag_v  xbav  --�؏���̃t���O�r���[
       WHERE
              xbav.bond_acceptance_flag_code
                = NVL(g_bond_acceptance_flag_xmw_tab(in_loop_cnt_3), 0 )    --�؏���̃t���O�R�[�h
         AND  xbav.enabled_flag  =  cv_const_y                              --�L���t���O
         AND  (   ( xbav.start_date_active IS NULL )
               OR ( xbav.start_date_active <= g_init_rec.process_date )   )
         AND  (   ( xbav.end_date_active IS NULL )
               OR ( xbav.end_date_active >= g_init_rec.process_date )   )
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �}�X�^�`�F�b�N(�؏����)
    OPEN check_cur;
    FETCH check_cur
    BULK COLLECT INTO g_mst_check_tab
    ;
--
    --�Ώۃf�[�^���Ȃ��ꍇ
    IF ( check_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name3                         -- ���ڒl�`�F�b�N�G���[
                                                      ,cv_tkn_name2                         -- �g�[�N��'COLUMN_NAME'
                                                      ,cv_tkn_val15                         -- �؏���̃t���O
                                                      ,cv_tkn_name4                         -- �g�[�N��'OBJECT_CODE'
                                                      ,g_object_code_tab(in_loop_cnt_3)     -- �����R�[�h
                                                      ,cv_tkn_name3                         -- �g�[�N��'COLUMN_INFO'
                                                      ,g_bond_acceptance_flag_xmw_tab(in_loop_cnt_3) -- �؏���̃t���O
                                                     )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warn_msg
      );
      --�G���[�t���O��TRUE�ɂ���
      gb_err_flag := TRUE;
    END IF;
--
    CLOSE check_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( check_cur%ISOPEN ) THEN
        CLOSE check_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_mst_bond_accep_flag;
--
  /**********************************************************************************
   * Procedure Name   : validate_bond_accep_flag
   * Description      : �Ó����`�F�b�N(�؏����)����(A-14)
   ***********************************************************************************/
  PROCEDURE validate_bond_accep_flag(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_bond_accep_flag'; -- �v���O������
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
    lv_warn_msg  VARCHAR2(5000); --�x�����b�Z�[�W
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �Ó����`�F�b�N(�؏����) - �؏���̃t���O(�����e�[�u��)�� '1' �łȂ�����
    IF ( g_bond_acceptance_flag_tab(in_loop_cnt_3) = cv_bond_acceptance_flag_1 ) THEN
--
      --�Ó����`�F�b�N�G���[
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name6                         -- �؏���̍σ`�F�b�N�G���[
                                                     )
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --�����G���[�Ώ�
                                                         ,cv_tkn_name4                     --�g�[�N��'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- �����R�[�h
                                                        )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warn_msg
      );
      --�G���[�t���O��TRUE�ɂ���
      gb_err_flag := TRUE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END validate_bond_accep_flag;
--
  /**********************************************************************************
   * Procedure Name   : call_facmn_chk_object_term
   * Description      : FA���ʊ֐�(�����R�[�h���`�F�b�N)����(A-15)
   ***********************************************************************************/
  PROCEDURE call_facmn_chk_object_term(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_facmn_chk_object_term'; -- �v���O������
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
    lv_warn_msg  VARCHAR2(5000); --�x�����b�Z�[�W
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- FA���ʊ֐�(�����R�[�h���`�F�b�N)
    xxcff_common2_pkg.chk_object_term(
      iv_term_appl_chk_flg  => cv_const_y                            --���\���`�F�b�N�t���O
     ,in_object_header_id   => g_object_header_id_tab(in_loop_cnt_3) --��������ID
     ,ov_errbuf    => lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --���ς݁A�������͖����̏�Ԃ̃��R�[�h�ׁ̈A�؏���̂�NOT NULL�Ɛ���
    IF ( lv_retcode = cv_status_warn ) THEN
      --�����p���ׁ̈A���ʊ֐��̖߂�l���x���̏ꍇ�̓X�e�[�^�X�𐳏�ɖ߂�
      lv_retcode := cv_status_normal;
    --���ʊ֐��Ŗ߂�l������̏ꍇ�A����Ԃ̃��R�[�h�ł͂Ȃ��ׁA�`�F�b�N�G���[
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name1                         -- ���ʊ֐��G���[
                                                      ,cv_tkn_name1                         -- �g�[�N��'FUNC_NAME'
                                                      ,cv_tkn_val19 )                       -- �����R�[�h���`�F�b�N
                                                      ,1
                                                      ,5000)
      ;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warn_msg
      );
      --�G���[�t���O��TRUE�ɂ���
      gb_err_flag := TRUE;
    ELSE
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END call_facmn_chk_object_term;
--
  /**********************************************************************************
   * Procedure Name   : check_cancellation_cancel
   * Description      : ���L�����Z���`�F�b�N����(A-16)
   ***********************************************************************************/
  PROCEDURE check_cancellation_cancel(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_cancellation_cancel'; -- �v���O������
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
    lv_warn_msg  VARCHAR2(5000); --�x�����b�Z�[�W
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ����ʂ����L�����Z���A����CSV�t�@�C���̏؏���̂���̍ς̏ꍇ(�s��)
    IF ( ( g_cancellation_class_tab(in_loop_cnt_3) = cv_cancel_class_9 )
     AND ( g_bond_acceptance_flag_xmw_tab(in_loop_cnt_3) = cv_bond_acceptance_flag_1 ) )
    THEN
      --���L�����Z���`�F�b�N�G���[
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name9                         -- ���L�����Z���`�F�b�N�G���[
                                                     )
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --�����G���[�Ώ�
                                                         ,cv_tkn_name4                     --�g�[�N��'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- �����R�[�h
                                                        )
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warn_msg
      );
      --�G���[�t���O��TRUE�ɂ���
      gb_err_flag := TRUE;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_cancellation_cancel;
--
  /**********************************************************************************
   * Procedure Name   : call_facmn_chk_paychked
   * Description      : FA���ʊ֐�(�x���ƍ��σ`�F�b�N)����(A-17)
   ***********************************************************************************/
  PROCEDURE call_facmn_chk_paychked(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_facmn_chk_paychked'; -- �v���O������
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
    lv_warn_msg  VARCHAR2(5000); --�x�����b�Z�[�W
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- FA���ʊ֐�(�x���ƍ��σ`�F�b�N)
    xxcff_common2_pkg.payment_match_chk(
      in_line_id   => g_contract_line_id_tab(in_loop_cnt_3)  --�_�񖾍ד���ID
     ,ov_errbuf    => lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff  -- XXCFF
                                                      ,cv_msg_name10 ) -- �x���ƍ��ς݃G���[
                                                      ,1
                                                      ,5000)
      ;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warn_msg
      );
      --�G���[�t���O��TRUE�ɂ���
      gb_err_flag := TRUE;
      --�����p���ׁ̈A���ʊ֐��̖߂�l���x���̏ꍇ�̓X�e�[�^�X�𐳏�ɖ߂�
      lv_retcode := cv_status_normal;
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END call_facmn_chk_paychked;
--
  /**********************************************************************************
   * Procedure Name   : lock_object_tbl
   * Description      : ���[�X�����e�[�u�����b�N�擾(�ʏ�)����(A-18)
   ***********************************************************************************/
  PROCEDURE lock_object_tbl(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_object_tbl'; -- �v���O������
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
    lv_warn_msg VARCHAR2(5000); --�x�����b�Z�[�W�o�͗p�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur
    IS
      SELECT
              xoh.object_header_id  AS object_header_id  --��������ID
             ,xoh.re_lease_times    AS re_lease_times    --�ă��[�X��
        FROM
              xxcff_object_headers    xoh --���[�X����
       WHERE NOT EXISTS
              (SELECT
                       NULL
                 FROM
                       xxcff_object_status_v  xosv  --���[�X�����X�e�[�^�X�r���[
                WHERE
                       xosv.object_status_code = xoh.object_status          --�����X�e�[�^�X
                  AND  xosv.no_adjusts_flag    = cv_const_y                 --�C���s�t���O
              )
         AND  xoh.object_header_id = g_object_header_id_tab(in_loop_cnt_3)  --��������ID
         FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�X�����e�[�u�����b�N�擾(�ʏ�)
    OPEN lock_cur;
    FETCH lock_cur
    BULK COLLECT INTO  g_object_header_id_lock_tab  --��������ID
                      ,g_re_lease_times_ob_tab      --�ă��[�X��
    ;
    --�Ώۃf�[�^�Ȃ��̏ꍇ
    IF ( lock_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name7 )                       -- �X�e�[�^�X�G���[
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --�����G���[�Ώ�
                                                         ,cv_tkn_name4                     --�g�[�N��'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- �����R�[�h
                                                        )
                                                      ,1
                                                      ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warn_msg
      );
      RAISE global_api_expt;
    ELSE
      --�����e�[�u���̃��b�N������Ɏ擾�ł��Ă���ꍇ
      gb_lock_ob_flag := TRUE;
    END IF;
--
    --�J�[�\���̃N���[�Y
    CLOSE lock_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_name8         -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_name7         -- �g�[�N��'TABLE_NAME'
                                                     ,cv_tkn_val9 )        -- ���[�X�����e�[�u��
                                                     ,1
                                                     ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END lock_object_tbl;
--
  /**********************************************************************************
   * Procedure Name   : lock_object_tbl_other
   * Description      : ���[�X�����e�[�u�����b�N�擾(���̑�)����(A-19)
   ***********************************************************************************/
  PROCEDURE lock_object_tbl_other(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    iv_proc_flag  IN  VARCHAR2,     --  �؏���̃t���O�̎擾�����ʃt���O
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_object_tbl_other'; -- �v���O������
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
    lv_major_division  VARCHAR2(2); --�啪��
    lv_warn_msg VARCHAR2(5000);     --�x�����b�Z�[�W�o�͗p�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur
    IS
      SELECT
              xoh.object_header_id  --��������ID
             ,xoh.re_lease_times    --�ă��[�X��
             ,xoiv.small_class      --������
        FROM
              xxcff_object_headers    xoh  --���[�X����
             ,xxcff_obj_ins_status_v  xoiv --���[�X�����o�^�X�e�[�^�X�r���[
       WHERE
              xoh.object_header_id = g_object_header_id_tab(in_loop_cnt_3)      --��������ID
         AND  xoh.object_status    = xoiv.object_status                         --�����X�e�[�^�X
         AND  xoiv.large_class     = lv_major_division                          --�啪��
         AND  NVL(xoiv.constract_status, g_contract_status_tab(in_loop_cnt_3))
                = g_contract_status_tab(in_loop_cnt_3)                          --�_��X�e�[�^�X
         FOR UPDATE OF xoh.object_header_id NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �啪�ނ̐ݒ�
    IF ( iv_proc_flag = cv_proc_flag_tbl ) THEN
      --����ʂ̏����̏ꍇ�A����ʂ̒l�ɂ��ݒ�
      lv_major_division := CASE g_cancellation_class_tab(in_loop_cnt_3)
                             WHEN cv_cancel_class_1 THEN cv_major_division_50 --���m��(���ȓs��)
                             WHEN cv_cancel_class_2 THEN cv_major_division_50 --���m��(�ی��Ή�)
                             WHEN cv_cancel_class_3 THEN cv_major_division_30 --���\��
                             WHEN cv_cancel_class_4 THEN cv_major_division_30 --���\��(���ȓs��)
                             WHEN cv_cancel_class_5 THEN cv_major_division_30 --���\��(�ی��Ή�)
                             WHEN cv_cancel_class_9 THEN cv_major_division_40 --���L�����Z��
                           END;
    ELSIF ( iv_proc_flag = cv_proc_flag_csv ) THEN
      --�؏���̏����̏ꍇ
      lv_major_division := cv_major_division_60;
    END IF;
--
    -- ���[�X�����e�[�u�����b�N�擾(���̑�)
    OPEN lock_cur;
    FETCH lock_cur
    BULK COLLECT INTO  g_object_header_id_lock_tab  --��������ID
                      ,g_re_lease_times_ob_tab      --�ă��[�X��
                      ,g_small_class_ob_tab         --������
    ;
    IF ( lock_cur%ROWCOUNT = 0 ) THEN
      lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name7 )                       -- �X�e�[�^�X�G���[
                                                     || xxccp_common_pkg.get_msg(
                                                          cv_msg_kbn_cff                   --XXCFF
                                                         ,cv_msg_name12                    --�����G���[�Ώ�
                                                         ,cv_tkn_name4                     --�g�[�N��'OBJECT_CODE'
                                                         ,g_object_code_tab(in_loop_cnt_3) -- �����R�[�h
                                                        )
                                                      ,1
                                                      ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warn_msg
      );
      RAISE global_api_expt;
    ELSE
      --�����e�[�u���̃��b�N������Ɏ擾�ł��Ă���ꍇ
      gb_lock_ob_flag := TRUE;
    END IF;
--
    --�J�[�\���̃N���[�Y
    CLOSE lock_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --���@�\���ŁA�s���b�N�擾�ς݂̏ꍇ�̓X�L�b�v
      IF ( gb_lock_ob_flag ) THEN
        NULL;
      ELSE
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_name8         -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_name7         -- �g�[�N��'TABLE_NAME'
                                                       ,cv_tkn_val9 )        -- ���[�X�����e�[�u��
                                                       ,1
                                                       ,5000);
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
      END IF;
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END lock_object_tbl_other;
--
  /**********************************************************************************
   * Procedure Name   : lock_object_hist_tbl
   * Description      : ���[�X���������e�[�u�����b�N�擾����(A-20)
   ***********************************************************************************/
  PROCEDURE lock_object_hist_tbl(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_object_hist_tbl'; -- �v���O������
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
    CURSOR lock_cur
    IS
      SELECT
              xoht.object_header_id
        FROM
              xxcff_object_histories  xoht  --���[�X��������
       WHERE
              xoht.object_header_id = g_object_header_id_tab(in_loop_cnt_3)
         FOR UPDATE NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�X���������e�[�u�����b�N
    OPEN lock_cur;
    FETCH lock_cur
    BULK COLLECT INTO  g_object_header_id_lock_tab  --��������ID
    ;
    IF ( lock_cur%ROWCOUNT = 0 ) THEN
      NULL;
    ELSE
      --���������e�[�u���̃��b�N������Ɏ擾�ł��Ă���ꍇ
      gb_lock_ob_hist_flag := TRUE;
    END IF;
--
    --�J�[�\���̃N���[�Y
    CLOSE lock_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --���@�\���ŁA�s���b�N�擾�ς݂̏ꍇ�̓X�L�b�v
      IF ( gb_lock_ob_hist_flag ) THEN
        NULL;
      ELSE
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_name8         -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_name7         -- �g�[�N��'TABLE_NAME'
                                                       ,cv_tkn_val10 )       -- ���[�X���������e�[�u��
                                                       ,1
                                                       ,5000);
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
      END IF;
--
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END lock_object_hist_tbl;
--
  /**********************************************************************************
   * Procedure Name   : lock_ctrct_relation_tbl
   * Description      : ���[�X�_��֘A�e�[�u�����b�N�擾����(A-21)
   ***********************************************************************************/
  PROCEDURE lock_ctrct_relation_tbl(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_ctrct_relation_tbl'; -- �v���O������
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
    CURSOR lock_cur
    IS
      SELECT
              xcl.contract_line_id  --�_�񖾍ד���ID
        FROM
              xxcff_contract_headers  xch --���[�X�_��
             ,xxcff_contract_lines    xcl --���[�X�_�񖾍�
             ,xxcff_pay_planning      xpp --���[�X�x���v��
       WHERE
              xch.contract_header_id = xcl.contract_header_id                --�_�����ID
         AND  xcl.contract_line_id   = xpp.contract_line_id                  --�_�񖾍ד���ID
         AND  xch.re_lease_times     = g_re_lease_times_ob_tab(1)            --�ă��[�X��(A-18,A-19�Ŏ擾)
         AND  xcl.object_header_id   = g_object_header_id_tab(in_loop_cnt_3) --��������ID
         FOR UPDATE OF xcl.contract_line_id, xpp.contract_line_id NOWAIT
    ;
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�X�_��֘A�e�[�u��(���[�X�_�񖾍׃e�[�u���A���[�X�x���v��e�[�u��)�̃��b�N
    OPEN lock_cur;
    FETCH lock_cur
    BULK COLLECT INTO  g_contract_line_id_lock_tab  --�_�񖾍ד���ID
    ;
    --�J�[�\���̃N���[�Y
    CLOSE lock_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_name8         -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_name7         -- �g�[�N��'TABLE_NAME'
                                                     ,cv_tkn_val13 )       -- ���[�X�_��֘A
                                                     ,1
                                                     ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END lock_ctrct_relation_tbl;
--
  /**********************************************************************************
   * Procedure Name   : call_fa_common
   * Description      : FA���ʊ֐��N������(�ʏ�)����(A-22)
   ***********************************************************************************/
  PROCEDURE call_fa_common(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_fa_common'; -- �v���O������
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
    --���[�X�������
    l_ob_rec                       xxcff_common3_pkg.object_data_rtype;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�X�������ݒ�
    l_ob_rec.object_header_id     := g_object_header_id_tab(in_loop_cnt_3);     -- ��������ID
    l_ob_rec.object_code          := g_object_code_tab(in_loop_cnt_3);          -- �����R�[�h
    l_ob_rec.lease_class          := g_lease_class_tab(in_loop_cnt_3);          -- ���[�X���
    l_ob_rec.lease_type           := g_lease_type_tab(in_loop_cnt_3);           -- ���[�X�敪
    l_ob_rec.re_lease_times       := g_re_lease_times_tab(in_loop_cnt_3);       -- �ă��[�X��
    l_ob_rec.po_number            := g_po_number_tab(in_loop_cnt_3);            -- �����ԍ�
    l_ob_rec.registration_number  := g_registration_number_tab(in_loop_cnt_3);  -- �o�^�ԍ�
    l_ob_rec.age_type             := g_age_type_tab(in_loop_cnt_3);             -- �N��
    l_ob_rec.model                := g_model_tab(in_loop_cnt_3);                -- �@��
    l_ob_rec.serial_number        := g_serial_number_tab(in_loop_cnt_3);        -- �@��
    l_ob_rec.quantity             := g_quantity_tab(in_loop_cnt_3);             -- ����
    l_ob_rec.manufacturer_name    := g_manufacturer_name_tab(in_loop_cnt_3);    -- ���[�J�[��
    l_ob_rec.department_code      := g_department_code_tab(in_loop_cnt_3);      -- �Ǘ�����R�[�h
    l_ob_rec.owner_company        := g_owner_company_tab(in_loop_cnt_3);        -- �{�Ё^�H��
    l_ob_rec.installation_address := g_installation_address_tab(in_loop_cnt_3); -- ���ݒu�ꏊ
    l_ob_rec.installation_place   := g_installation_place_tab(in_loop_cnt_3);   -- ���ݒu��
    l_ob_rec.chassis_number       := g_chassis_number_tab(in_loop_cnt_3);       -- �ԑ�ԍ�
    l_ob_rec.re_lease_flag        := g_re_lease_flag_tab(in_loop_cnt_3);        -- �ă��[�X�v�t���O
    l_ob_rec.cancellation_type    := g_cancellation_type_tab(in_loop_cnt_3);    -- ���敪
    l_ob_rec.cancellation_date    := g_cancellation_date_tab(in_loop_cnt_3);    -- ���r����
    l_ob_rec.dissolution_date     := g_dissolution_date_tab(in_loop_cnt_3);     -- ���r���L�����Z����
    l_ob_rec.bond_acceptance_flag := g_bond_acceptance_flag_tab(in_loop_cnt_3); -- �؏���̃t���O(�����e�[�u��)
    l_ob_rec.bond_acceptance_date := g_bond_acceptance_date_tab(in_loop_cnt_3); -- �؏���̓�
    l_ob_rec.expiration_date      := g_expiration_date_tab(in_loop_cnt_3);      -- ������
--    l_ob_rec.object_status        := g_object_status_tab(in_loop_cnt_3);        -- �����X�e�[�^�X
    l_ob_rec.active_flag          := g_active_flag_tab(in_loop_cnt_3);          -- �����L���t���O
    l_ob_rec.info_sys_if_date     := g_info_sys_if_date_tab(in_loop_cnt_3);     -- ���[�X�Ǘ����A�g��
    l_ob_rec.generation_date      := g_generation_date_tab(in_loop_cnt_3);      -- ������
    l_ob_rec.customer_code        := g_customer_code_tab(in_loop_cnt_3);        -- �ڋq�R�[�h
    -- �ȉ��AWHO�J�������
    l_ob_rec.created_by             := cn_created_by;              --�쐬��
    l_ob_rec.creation_date          := cd_creation_date;           --�쐬��
    l_ob_rec.last_updated_by        := cn_last_updated_by;         --�ŏI�X�V��
    l_ob_rec.last_update_date       := cd_last_update_date;        --�ŏI�X�V��
    l_ob_rec.last_update_login      := cn_last_update_login;       --�ŏI�X�V���O�C��
    l_ob_rec.request_id             := cn_request_id;              --�v��ID
    l_ob_rec.program_application_id := cn_program_application_id;  --�ݶ��ĥ��۸��ѥ���ع����ID
    l_ob_rec.program_id             := cn_program_id;              -- �ݶ��ĥ��۸���ID
    l_ob_rec.program_update_date    := cd_program_update_date;     -- ��۸��эX�V��
--
    --���ʊ֐� ���[�X�������쐬�i�o�b�`�j �̌ďo
    xxcff_common3_pkg.create_ob_bat(
      io_object_data_rec        => l_ob_rec          --���[�X�������
     ,ov_errbuf                 => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode                => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                 => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name1                         -- ���ʊ֐��G���[
                                                    ,cv_tkn_name1                         -- �g�[�N��'FUNC_NAME'
                                                    ,cv_tkn_val11 )                       -- ���[�X�������쐬�i�o�b�`�j
                                                    || cv_msg_part
                                                    || lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    ELSE
      --���������̃C���N�������g
      gn_normal_cnt := ( gn_normal_cnt + 1 );
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END call_fa_common;
--
  /**********************************************************************************
   * Procedure Name   : call_fa_common_other
   * Description      : FA���ʊ֐��N������(���̑�)����(A-23)
   ***********************************************************************************/
  PROCEDURE call_fa_common_other(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    iv_proc_flag  IN  VARCHAR2,     --  �؏���̃t���O�̎擾�����ʃt���O
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_fa_common_other'; -- �v���O������
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
    --���[�X�������
    l_ob_rec                       xxcff_common3_pkg.object_data_rtype;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���[�X�������ݒ�
    l_ob_rec.object_header_id     := g_object_header_id_tab(in_loop_cnt_3);     -- ��������ID
    l_ob_rec.object_code          := g_object_code_tab(in_loop_cnt_3);          -- �����R�[�h
    l_ob_rec.lease_class          := g_lease_class_tab(in_loop_cnt_3);          -- ���[�X���
    l_ob_rec.lease_type           := g_lease_type_tab(in_loop_cnt_3);           -- ���[�X�敪
    l_ob_rec.re_lease_times       := g_re_lease_times_tab(in_loop_cnt_3);       -- �ă��[�X��
    l_ob_rec.po_number            := g_po_number_tab(in_loop_cnt_3);            -- �����ԍ�
    l_ob_rec.registration_number  := g_registration_number_tab(in_loop_cnt_3);  -- �o�^�ԍ�
    l_ob_rec.age_type             := g_age_type_tab(in_loop_cnt_3);             -- �N��
    l_ob_rec.model                := g_model_tab(in_loop_cnt_3);                -- �@��
    l_ob_rec.serial_number        := g_serial_number_tab(in_loop_cnt_3);        -- �@��
    l_ob_rec.quantity             := g_quantity_tab(in_loop_cnt_3);             -- ����
    l_ob_rec.manufacturer_name    := g_manufacturer_name_tab(in_loop_cnt_3);    -- ���[�J�[��
    l_ob_rec.department_code      := g_department_code_tab(in_loop_cnt_3);      -- �Ǘ�����R�[�h
    l_ob_rec.owner_company        := g_owner_company_tab(in_loop_cnt_3);        -- �{�Ё^�H��
    l_ob_rec.installation_address := g_installation_address_tab(in_loop_cnt_3); -- ���ݒu�ꏊ
    l_ob_rec.installation_place   := g_installation_place_tab(in_loop_cnt_3);   -- ���ݒu��
    l_ob_rec.chassis_number       := g_chassis_number_tab(in_loop_cnt_3);       -- �ԑ�ԍ�
    l_ob_rec.re_lease_flag        := g_re_lease_flag_tab(in_loop_cnt_3);        -- �ă��[�X�v�t���O
    l_ob_rec.cancellation_type    := CASE iv_proc_flag
                                       WHEN  cv_proc_flag_csv
                                         THEN g_cancellation_type_tab(in_loop_cnt_3)
                                       WHEN  cv_proc_flag_tbl
                                         THEN
                                           CASE g_cancellation_class_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_1 THEN cv_cancel_type_1
                                             WHEN  cv_cancel_class_2 THEN cv_cancel_type_2
                                             WHEN  cv_cancel_class_3 THEN g_cancellation_type_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_4 THEN cv_cancel_type_1
                                             WHEN  cv_cancel_class_5 THEN cv_cancel_type_2
                                             WHEN  cv_cancel_class_9 THEN NULL
                                           END
                                     END;                                       -- ���敪
    l_ob_rec.cancellation_date    := CASE iv_proc_flag
                                       WHEN  cv_proc_flag_csv
                                         THEN g_cancellation_date_tab(in_loop_cnt_3)
                                       WHEN  cv_proc_flag_tbl
                                         THEN
                                           CASE g_cancellation_class_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_1 THEN g_init_rec.process_date
                                             WHEN  cv_cancel_class_2 THEN g_init_rec.process_date
                                             WHEN  cv_cancel_class_3 THEN g_cancellation_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_4 THEN g_cancellation_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_5 THEN g_cancellation_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_9 THEN g_cancellation_date_tab(in_loop_cnt_3)
                                           END
                                     END;                                       -- ���r����
    l_ob_rec.dissolution_date     :=  CASE iv_proc_flag
                                       WHEN  cv_proc_flag_csv
                                         THEN g_dissolution_date_tab(in_loop_cnt_3)
                                       WHEN  cv_proc_flag_tbl
                                         THEN
                                           CASE g_cancellation_class_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_1 THEN g_dissolution_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_2 THEN g_dissolution_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_3 THEN g_dissolution_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_4 THEN g_dissolution_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_5 THEN g_dissolution_date_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_9 THEN g_init_rec.process_date
                                           END
                                     END;                                       -- ���r���L�����Z����
    l_ob_rec.bond_acceptance_flag := CASE iv_proc_flag
                                       WHEN  cv_proc_flag_csv
                                         THEN g_bond_acceptance_flag_xmw_tab(in_loop_cnt_3)  --����ݽð��ق��擾
                                       WHEN  cv_proc_flag_tbl
                                         THEN g_bond_acceptance_flag_tab(in_loop_cnt_3)      --�����e�[�u�����擾
                                     END;                                       --�؏���̃t���O
    l_ob_rec.bond_acceptance_date := CASE iv_proc_flag
                                       WHEN  cv_proc_flag_csv
                                         THEN g_init_rec.process_date
                                       WHEN  cv_proc_flag_tbl
                                         THEN g_bond_acceptance_date_tab(in_loop_cnt_3)
                                     END;                                       -- �؏���̓�
    l_ob_rec.expiration_date      := g_expiration_date_tab(in_loop_cnt_3);      -- ������
    l_ob_rec.object_status        := CASE iv_proc_flag
                                       WHEN  cv_proc_flag_tbl
                                         THEN
                                           CASE g_cancellation_class_tab(in_loop_cnt_3)
                                             WHEN  cv_cancel_class_3 THEN cv_ob_status_108
                                             WHEN  cv_cancel_class_4 THEN cv_ob_status_108
                                             WHEN  cv_cancel_class_5 THEN cv_ob_status_108
                                           END
                                     END;                                       -- �����X�e�[�^�X
    l_ob_rec.active_flag          := g_active_flag_tab(in_loop_cnt_3);          -- �����L���t���O
    l_ob_rec.info_sys_if_date     := g_info_sys_if_date_tab(in_loop_cnt_3);     -- ���[�X�Ǘ����A�g��
    l_ob_rec.generation_date      := g_generation_date_tab(in_loop_cnt_3);      -- ������
    l_ob_rec.customer_code        := g_customer_code_tab(in_loop_cnt_3);        -- �ڋq�R�[�h
    -- �ȉ��AWHO�J�������
    l_ob_rec.created_by             := cn_created_by;              --�쐬��
    l_ob_rec.creation_date          := cd_creation_date;           --�쐬��
    l_ob_rec.last_updated_by        := cn_last_updated_by;         --�ŏI�X�V��
    l_ob_rec.last_update_date       := cd_last_update_date;        --�ŏI�X�V��
    l_ob_rec.last_update_login      := cn_last_update_login;       --�ŏI�X�V���O�C��
    l_ob_rec.request_id             := cn_request_id;              --�v��ID
    l_ob_rec.program_application_id := cn_program_application_id;  --�ݶ��ĥ��۸��ѥ���ع����ID
    l_ob_rec.program_id             := cn_program_id;              -- �ݶ��ĥ��۸���ID
    l_ob_rec.program_update_date    := cd_program_update_date;     -- ��۸��эX�V��
--
    --���ʊ֐� ���[�X�������쐬 �̌ďo
    xxcff_common3_pkg.create_ob_det(
      io_object_data_rec        => l_ob_rec                --���[�X�������
     ,iv_exce_mode              => CASE g_small_class_ob_tab(1) --�yA-19�z�ɂĎ擾����������
                                     WHEN cv_small_class_7  THEN cv_exce_mode_adj
                                     WHEN cv_small_class_8  THEN cv_exce_mode_dis
                                     WHEN cv_small_class_9  THEN cv_exce_mode_can
                                     WHEN cv_small_class_10 THEN cv_exce_mode_chg
                                   END
     ,ov_errbuf                 => lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode                => lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg                 => lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name1                         -- ���ʊ֐��G���[
                                                    ,cv_tkn_name1                         -- �g�[�N��'FUNC_NAME'
                                                    ,cv_tkn_val14 )                       -- ���[�X�������쐬
                                                    || cv_msg_part
                                                    || lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    ELSE
      --���������̃C���N�������g
      gn_normal_cnt := ( gn_normal_cnt + 1 );
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END call_fa_common_other;
--
  /**********************************************************************************
   * Procedure Name   : call_facmn_chk_location
   * Description      : FA���ʊ֐�(���Ə��}�X�^�`�F�b�N)����(A-24)
   ***********************************************************************************/
  PROCEDURE call_facmn_chk_location(
    in_loop_cnt_3 IN  NUMBER,       --  ���[�v�J�E���^3
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_facmn_chk_location'; -- �v���O������
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
    ln_location_id  NUMBER(15);
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- ���Ə��}�X�^�̑g�ݍ��킹�`�F�b�N
    xxcff_common1_pkg.chk_fa_location(
      iv_segment2     => g_department_code_tab(in_loop_cnt_3)  -- �Ǘ�����R�[�h
     ,iv_segment5     => g_owner_company_tab(in_loop_cnt_3)    -- �{�ЍH��
     ,on_location_id  => ln_location_id                        -- ���Ə�ID
     ,ov_errbuf    => lv_errbuf                  -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode                 -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff  -- XXCFF
                                                    ,cv_msg_name1    -- ���ʊ֐��G���[
                                                    ,cv_tkn_name1    -- �g�[�N��'FUNC_NAME'
                                                    ,cv_tkn_val7  )  -- ���Ə��}�X�^�`�F�b�N
                                                    || cv_msg_part
                                                    || lv_errmsg     -- ���ʊ֐���װү����
                                                    ,1
                                                    ,5000)
      ;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END call_facmn_chk_location;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER,       -- 1.�t�@�C��ID
    iv_file_format  IN   VARCHAR2,     -- 2.�t�@�C���t�H�[�}�b�g
    ov_errbuf       OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT  VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
--
    -- ���[�v���̃J�E���g
    ln_loop_cnt_1  NUMBER;
    ln_loop_cnt_2  NUMBER;
--
    --�f�[�^�擾������(A-1�`A-6)�ŃG���[�����������������J�E���g
    ln_error_cnt   PLS_INTEGER;
--
    --�ړ��E�C�����ڂ̑��݃`�F�b�N�p
    l_all_null_tbl         g_mst_check_ttype; --�ړ��E�C������ �L:1 / ��:0
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt               := 0;
    gn_normal_cnt               := 0;
    gn_error_cnt                := 0;
    gn_warn_cnt                 := 0;
--
    ln_loop_cnt_1               := 0;
    ln_loop_cnt_2               := 0;
--
    ln_error_cnt                := 0;
--
    gb_lock_ob_flag             := FALSE; --���b�N�t���O(����):FALSE
    gb_lock_ob_hist_flag        := FALSE; --���b�N�t���O(��������):FALSE
    gb_err_flag                 := FALSE; --�G���[�t���O:FALSE
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    -- ============================================
    -- A-1�D��������
    -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-1�̌ďo(submain)');--���p��
--
    -- ���ʏ�������(�����l���̎擾)�̌Ăяo��
    init(
       in_file_id        -- 1.�t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2�D�Ó����`�F�b�N�p�̒l�擾
    -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-2�̌ďo(submain)');--���p��
--
    get_for_validation(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3�D�t�@�C���A�b�v���[�hIF�f�[�^�擾
    -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-3�̌ďo(submain)');--���p��
--
    get_upload_data(
       in_file_id        -- 1.�t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --���C�����[�v�@
    <<MAIN_LOOP_1>>
      FOR ln_loop_cnt_1 IN g_file_upload_if_data_tab.FIRST .. g_file_upload_if_data_tab.LAST LOOP --���[�v�X�^�[�g
--fnd_file.put_line(fnd_file.log,'��debug:'||'���C�����[�v�@�J�n');--���p��
--
        --�P�s�ڂ̏ꍇ�J�����s�̏����ƂȂ�ׁA�X�L�b�v���ĂQ�s�ڂ̏����ɑJ�ڂ���
        IF ( ln_loop_cnt_1 <> 1 ) THEN
          --���C�����[�v�A�J�E���^�̃��Z�b�g
          ln_loop_cnt_2 := 0;
--
          --���C�����[�v�A
          <<MAIN_LOOP_2>>
          FOR ln_loop_cnt_2 IN g_column_desc_tab.FIRST .. g_column_desc_tab.LAST LOOP
--fnd_file.put_line(fnd_file.log,'��debug:'||'���C�����[�v�A�J�n');--���p��
--
            -- ============================================
            -- A-4�D�f���~�^�������ڕ���
            -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-4�̌ďo(submain)');--���p��
            divide_item(
               ln_loop_cnt_1     -- ���[�v�J�E���^1
              ,ln_loop_cnt_2     -- ���[�v�J�E���^2
              ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
            IF ( gb_err_flag ) THEN
              EXIT MAIN_LOOP_2;
            END IF;
--
            --���ڂ�NULL�ł͂Ȃ��ꍇ�̂݁AA-5�̃`�F�b�N���s��
            IF ( g_load_data_tab(ln_loop_cnt_2) IS NOT NULL ) THEN
              -- ============================================
              -- A-5�D���ڒl�`�F�b�N
              -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-5�̌ďo(submain)');--���p��
              check_item_value(
                 ln_loop_cnt_2     -- ���[�v�J�E���^2
                ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
                ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
--
--fnd_file.put_line(fnd_file.log,'��debug:'||'���C�����[�v�A�̏I�[');--���p��
          END LOOP MAIN_LOOP_2;
--
          --�G���[�t���O��TRUE�Ȃ�A-6�̏������X�L�b�v
          IF ( gb_err_flag = FALSE ) THEN
            -- ============================================
            -- A-6�D���[�X���������e�i���X�e�[�u���쐬
            -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-6�̌ďo(submain)');--���p��
              ins_maintenance_wk(
                 in_file_id        -- 1.�t�@�C��ID
                ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
                ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          --�G���[�t���O��TRUE
          IF ( gb_err_flag ) THEN
            --�G���[�������v���X�P
            ln_error_cnt := ( ln_error_cnt + 1 );
            --�������p���ׁ̈A�G���[�t���O��߂�
            gb_err_flag := FALSE;
          ELSE
            --�G���[�łȂ��ꍇ�A�ړ��E�C�����ڂ�NULL�`�F�b�N
            IF ( ( g_load_data_tab(2)  IS NOT NULL )    --�{�ЍH��
              OR ( g_load_data_tab(3)  IS NOT NULL )    --�Ǘ�����
              OR ( g_load_data_tab(4)  IS NOT NULL )    --�o�^�ԍ�
              OR ( g_load_data_tab(5)  IS NOT NULL )    --�����ԍ�
              OR ( g_load_data_tab(6)  IS NOT NULL )    --���[�J�[��
              OR ( g_load_data_tab(7)  IS NOT NULL )    --�@��
              OR ( g_load_data_tab(8)  IS NOT NULL )    --�@��
              OR ( g_load_data_tab(9)  IS NOT NULL )    --�N��
              OR ( g_load_data_tab(10) IS NOT NULL )    --����
              OR ( g_load_data_tab(11) IS NOT NULL )    --�ԑ�ԍ�
              OR ( g_load_data_tab(12) IS NOT NULL )    --���ݒu�ꏊ
              OR ( g_load_data_tab(13) IS NOT NULL ) )  --���ݒu��
             THEN
              --�ړ��E�C�����ڂ�1�ł����݂���ꍇ
              l_all_null_tbl( ln_loop_cnt_1 - 1 ) := 1;
            ELSE
              --�ړ��E�C�����ڂ��S��NULL�̏ꍇ
              l_all_null_tbl( ln_loop_cnt_1 - 1 ) := 0;
            END IF;
          END IF;
--
        END IF; --�P�s��(�J�����s)�̏ꍇ�A�������X�L�b�v_�I��
--
--fnd_file.put_line(fnd_file.log,'��debug:'||'���C�����[�v�@�̏I�[');--���p��
    END LOOP MAIN_LOOP_1;
--
    --1���ł��G���[�����݂���ꍇ�͋����I��
    IF ( ln_error_cnt <> 0 ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-7�D���[�X���������e�i���X�e�[�u���擾
    -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-7�̌ďo(submain)');--���p��
--
    get_maintenance_wk(
       in_file_id        -- 1.�t�@�C��ID
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --A-7�Ŏ擾������0���̏ꍇ�A�Ȍ�̏������X�L�b�v
    IF ( g_object_header_id_tab.COUNT <> 0 ) THEN
--
      -- ============================================
      -- A-8�D���[�X�������݃`�F�b�N
      -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-8�̌ďo(submain)');--���p��
--
      check_object_exist(
         lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      --���C�����[�v�B
      <<MAIN_LOOP_3>>
      FOR ln_loop_cnt_3 IN g_object_code_tab.FIRST .. g_object_code_tab.LAST LOOP
--fnd_file.put_line(fnd_file.log,'��debug:'||'���C�����[�v�B�J�n');--���p��
        --�ړ��A�C���p�̍��ڂ�NOT NULL�̏ꍇ
        IF ( l_all_null_tbl(ln_loop_cnt_3) = 1 ) THEN
--
          --�Ώی����̃C���N�������g
          gn_target_cnt := ( gn_target_cnt + 1 );
--
          -- ============================================
          -- A-9�D�}�X�^�`�F�b�N(�{�ЍH��)
          -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-9�̌ďo(submain)');--���p��
--
          check_mst_owner_company(
             ln_loop_cnt_3     -- ���[�v�J�E���^3
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-10�D�}�X�^�`�F�b�N(�Ǘ�����)
          -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-10�̌ďo(submain)');--���p��
--
          check_mst_department(
             ln_loop_cnt_3     -- ���[�v�J�E���^3
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-24�DFA���ʊ֐�(���Ə��}�X�^�`�F�b�N)
          -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-24�̌ďo(submain)');--���p��
--
          call_facmn_chk_location(
             ln_loop_cnt_3     -- ���[�v�J�E���^3
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-12�D�}�X�^�`�F�b�N(���[�X���)
          -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-12�̌ďo(submain)');--���p��
--
          check_mst_lease_class(
             ln_loop_cnt_3     -- ���[�v�J�E���^3
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-14�D�Ó����`�F�b�N(�؏����)
          -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-14�̌ďo(submain)');--���p��
--
          validate_bond_accep_flag(
             ln_loop_cnt_3     -- ���[�v�J�E���^3
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          --�G���[�t���O��TRUE�Ȃ����ʂ̃`�F�b�N�܂ŃX�L�b�v
          IF ( gb_err_flag = FALSE ) THEN
--
            -- ============================================
            -- A-18�D���[�X�����e�[�u�����b�N�擾(�ʏ�)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-18�̌ďo(submain)');--���p��
--
            lock_object_tbl(
               ln_loop_cnt_3     -- ���[�v�J�E���^3
              ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            --�����X�e�[�^�X���u���_��v�̎��̂݁AA-20�̏������s��
            IF ( g_object_status_tab(ln_loop_cnt_3) = cv_ob_status_101 ) THEN
              -- ============================================
              -- A-20�D���[�X���������e�[�u�����b�N�擾
              -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-20�̌ďo(submain)');--���p��
--
              lock_object_hist_tbl(
                 ln_loop_cnt_3     -- ���[�v�J�E���^3
                ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
                ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
--
            -- ============================================
            -- A-22�DFA���ʊ֐��N������(�ʏ�)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-22�̌ďo(submain)');--���p��
--
            call_fa_common(
               ln_loop_cnt_3     -- ���[�v�J�E���^3
              ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;  --�G���[�t���O��TRUE
        END IF;  --�ړ��A�C���p�̍��ڂ�NOT NULL�̏ꍇ
--
        --�G���[�t���O��TRUE�̏ꍇ�A�G���[�J�E���^���C���N�������g
        IF ( gb_err_flag ) THEN
          gn_error_cnt := ( gn_error_cnt + 1 );
          gb_err_flag  := FALSE; --����ʏ����ׁ̈A������
        END IF;
--
        --����ʂ̃`�F�b�N
        IF ( g_cancellation_class_tab(ln_loop_cnt_3) IS NOT NULL ) THEN
--
          --�Ώی����̃C���N�������g
          gn_target_cnt := ( gn_target_cnt + 1 );
--
          -- ============================================
          -- A-11�D�}�X�^�`�F�b�N(�����)
          -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-11�̌ďo(submain)');--���p��
--
          check_mst_cancellation_class(
             ln_loop_cnt_3     -- ���[�v�J�E���^3
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          --����ʂ��u���L�����Z���v�̎��AA-14�̏��������s
          IF ( g_cancellation_class_tab(ln_loop_cnt_3) = cv_cancel_class_9 ) THEN
            -- ============================================
            -- A-14�D�Ó����`�F�b�N(�؏����)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-14�̌ďo(submain)');--���p��
--
            validate_bond_accep_flag(
               ln_loop_cnt_3     -- ���[�v�J�E���^3
              ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- ============================================
          -- A-16�D���L�����Z���`�F�b�N
          -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-16�̌ďo(submain)');--���p��
--
          check_cancellation_cancel(
             ln_loop_cnt_3     -- ���[�v�J�E���^3
            ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          --����ʂ����m��E�_�񖾍ד���ID��NULL�ł͂Ȃ��ꍇ�AA-17�̏������s��
          IF ( ( g_cancellation_class_tab(ln_loop_cnt_3) IN ( cv_cancel_class_1, cv_cancel_class_2 ) )
           AND ( g_contract_line_id_tab(ln_loop_cnt_3) IS NOT NULL ) ) THEN
            -- ============================================
            -- A-17�DFA���ʊ֐�(�x���ƍ��σ`�F�b�N)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-17�̌ďo(submain)');--���p��
--
            call_facmn_chk_paychked(
               ln_loop_cnt_3     -- ���[�v�J�E���^3
              ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          --�G���[�t���O��TRUE�Ȃ�؏���̂̃`�F�b�N�܂ŃX�L�b�v
          IF ( gb_err_flag = FALSE ) THEN
            -- ============================================
            -- A-19�D���[�X�����e�[�u�����b�N�擾(���̑�)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-19�̌ďo(submain)');--���p��
--
            lock_object_tbl_other(
               ln_loop_cnt_3     -- ���[�v�J�E���^3
              ,cv_proc_flag_tbl  -- �����/�؏���̃t���O�̏������ʃt���O
              ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ============================================
            -- A-20�D���[�X���������e�[�u�����b�N�擾
            -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-20�̌ďo(submain)');--���p��
--
            lock_object_hist_tbl(
               ln_loop_cnt_3     -- ���[�v�J�E���^3
              ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            --����ʂ����m��̏ꍇ�AA-21�̏������s��
            IF ( g_cancellation_class_tab(ln_loop_cnt_3) IN ( cv_cancel_class_1, cv_cancel_class_2 ) ) THEN
              -- ============================================
              -- A-21�D���[�X�_��֘A�e�[�u�����b�N�擾
              -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-21�̌ďo(submain)');--���p��
--
              lock_ctrct_relation_tbl(
                 ln_loop_cnt_3     -- ���[�v�J�E���^3
                ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
                ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
            END IF; --����ʂ����m��̏ꍇ
--
            -- ============================================
            -- A-23�DFA���ʊ֐��N������(���̑�)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-23�̌ďo(submain)');--���p��
--
            call_fa_common_other(
               ln_loop_cnt_3     -- ���[�v�J�E���^3
              ,cv_proc_flag_tbl  -- �����/�؏���̃t���O�̏������ʃt���O
              ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;  --�G���[�t���O��TRUE
        END IF;  --����ʂ̃`�F�b�N
--
        --�G���[�t���O��TRUE�̏ꍇ�A�G���[�J�E���^���C���N�������g
        IF ( gb_err_flag ) THEN
          gn_error_cnt := ( gn_error_cnt + 1 );
          gb_err_flag  := FALSE; --�؏���̏����ׁ̈A������
        END IF;
--
        --�؏���̂̃`�F�b�N
        IF ( g_bond_acceptance_flag_xmw_tab(ln_loop_cnt_3) IS NOT NULL ) THEN
          IF ( g_bond_acceptance_flag_xmw_tab(ln_loop_cnt_3) <> cv_bond_acceptance_flag_0 ) THEN
--
            --�Ώی����̃C���N�������g
            gn_target_cnt := ( gn_target_cnt + 1 );
--
            -- ============================================
            -- A-13�D�}�X�^�`�F�b�N(�؏����)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-13�̌ďo(submain)');--���p��
--
            check_mst_bond_accep_flag(
               ln_loop_cnt_3     -- ���[�v�J�E���^3
              ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ============================================
            -- A-14�D�Ó����`�F�b�N(�؏����)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-14�̌ďo(submain)');--���p��
--
            validate_bond_accep_flag(
               ln_loop_cnt_3     -- ���[�v�J�E���^3
              ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ============================================
            -- A-15�DFA���ʊ֐�(�����R�[�h���`�F�b�N)
            -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-15�̌ďo(submain)');--���p��
--
            call_facmn_chk_object_term(
               ln_loop_cnt_3     -- ���[�v�J�E���^3
              ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
              ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
              ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            --�G���[�t���O��TRUE�Ȃ珈�����X�L�b�v
            IF ( gb_err_flag = FALSE ) THEN
              -- ============================================
              -- A-19�D���[�X�����e�[�u�����b�N�擾(���̑�)
              -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-19(5/5)�̌ďo(submain)');--���p��
--
              lock_object_tbl_other(
                 ln_loop_cnt_3     -- ���[�v�J�E���^3
                ,cv_proc_flag_csv  --�����/�؏���̃t���O�̏������ʃt���O
                ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
                ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
--
              -- ============================================
              -- A-20�D���[�X���������e�[�u�����b�N�擾
              -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-20(5/5)�̌ďo(submain)');--���p��
--
              lock_object_hist_tbl(
                 ln_loop_cnt_3     -- ���[�v�J�E���^3
                ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
                ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
--
              -- ============================================
              -- A-23�DFA���ʊ֐��N������(���̑�)
              -- ============================================
--fnd_file.put_line(fnd_file.log,'��debug:'||'A-23(5/5)�̌ďo(submain)');--���p��
--
              call_fa_common_other(
                 ln_loop_cnt_3     -- ���[�v�J�E���^3
                ,cv_proc_flag_csv  -- �����/�؏���̃t���O�̏������ʃt���O
                ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
                ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
                ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
--
            END IF; --�G���[�t���O��TRUE
          END IF; --�؏��`�F�b�N
        END IF; --�؏���̂�NULL�`�F�b�N
--
        --�G���[�t���O��TRUE�̏ꍇ�A�G���[�J�E���^���C���N�������g
        IF ( gb_err_flag ) THEN
          gn_error_cnt := ( gn_error_cnt + 1 );
          gb_err_flag  := FALSE; --�ړ��E�C�������ׁ̈A������
        END IF;
--fnd_file.put_line(fnd_file.log,'��debug:'||'���C�����[�v�B�̏I�[');--���p��
      END LOOP MAIN_LOOP_3;
--
    ELSE
      --A-7�܂ŏ������J�ڂ��擾������0���̏ꍇ�A�e�[�u���̕R�t�������������׃G���[
      gn_error_cnt := gn_target_cnt;
    END IF;  --A-7�Ŏ擾������0���̏ꍇ
--
    --1���ł��G���[�����݂���ꍇ�͋����I��
    IF ( gn_error_cnt <> 0 ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ***
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
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
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT   VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    in_file_id       IN    NUMBER,          -- 1.�t�@�C��ID(�K�{)
    iv_file_format   IN    VARCHAR2         -- 2.�t�@�C���t�H�[�}�b�g(�K�{)
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
      ,iv_which   => cv_file_type_out
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       in_file_id      -- 1.�t�@�C��ID
      ,iv_file_format  -- 2.�t�@�C���t�H�[�}�b�g
      ,lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ============================================
    -- A-50�D�I������
    -- ============================================
--
    IF (  lv_retcode <> cv_status_normal ) THEN
      --�@����ȊO�̏ꍇ�A���[���o�b�N�𔭍s
      ROLLBACK;
    ELSE
      --����̏ꍇ
      BEGIN
        --�A���[�X���������e�i���X���[�N(���������e�i���X���[�N)���폜
        DELETE FROM
          xxcff_maintenance_work  --���[�X���������e�i���X���[�N(���������e�i���X���[�N)
        WHERE
          file_id = in_file_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --�B���b�Z�[�W�̐ݒ�
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff            -- 'XXCFF'
                                                         ,cv_msg_name11             -- �폜�G���[
                                                         ,cv_tkn_name7              -- �g�[�N��'TABLE_NAME'
                                                         ,cv_tkn_val16              -- ���������e�i���X���[�N
                                                         ,cv_tkn_name8              -- �g�[�N��'INFO'
                                                         ,SUBSTRB(SQLERRM,1,2000) ) -- ���b�Z�[�W
                                                         ,1
                                                         ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          RAISE global_api_others_expt;
      END;
    END IF;
--
      BEGIN
        --�C�t�@�C���A�b�v���[�hI/F�e�[�u�����폜
        DELETE FROM
          xxccp_mrp_file_ul_interface  --�t�@�C���A�b�v���[�hI/F�e�[�u��
        WHERE
          file_id = in_file_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          --�D���b�Z�[�W�̐ݒ�
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff            -- 'XXCFF'
                                                         ,cv_msg_name11             -- �폜�G���[
                                                         ,cv_tkn_name7              -- �g�[�N��'TABLE_NAME'
                                                         ,cv_tkn_val17              -- �t�@�C���A�b�v���[�hI/F�e�[�u��
                                                         ,cv_tkn_name8              -- �g�[�N��'INFO'
                                                         ,SUBSTRB(SQLERRM,1,2000) ) -- ���b�Z�[�W
                                                         ,1
                                                         ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
          );
          errbuf     := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          RAISE global_api_others_expt;
      END;
      --�E�R�~�b�g�𔭍s
      IF ( lv_retcode <> cv_status_normal ) THEN
        COMMIT;
      END IF;
--
    --�F���ʂ̃��O���b�Z�[�W�̏o��
    -- ===============================================
    -- �G���[���̏o�͌����ݒ�
    -- ===============================================
    IF (( lv_retcode <> cv_status_normal ) OR ( gn_error_cnt <> 0 )) THEN
      -- ���������Ƀ[�������Z�b�g����
      gn_normal_cnt := 0;
--
      --�����I�������ꍇ(�G���[�ɂȂ����������G���[�J�E���g�ɃC���N�������g����Ă��Ȃ�)
      IF ( gn_error_cnt = 0 ) THEN
        IF ( gn_target_cnt = 0 ) THEN  --�Ώی��������擾�̏ꍇ
          NULL;
        ELSE
          gn_error_cnt := 1;
          gn_warn_cnt  := ( gn_target_cnt - gn_error_cnt );
        END IF;
      ELSE
        --�X�L�b�v�������Z�b�g����
        gn_warn_cnt   := ( gn_target_cnt - gn_error_cnt );
      END IF;
    END IF;
--
    -- ===============================================================
    -- ���ʂ̃��O���b�Z�[�W�̏o��
    -- ===============================================================
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_name30
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_name31
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_name32
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_msg_name33
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --���ʂ̃��O���b�Z�[�W�̏o�͏I��
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�I�����b�Z�[�W�̐ݒ�A�o��(�G,�H)
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCFF004A30C;
/
