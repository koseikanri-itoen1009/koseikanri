create or replace
PACKAGE BODY XXCFF013A19C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF013A19C(body)
 * Description      : ���[�X�_�񌎎��X�V
 * MD.050           : MD050_CFF_013_A19_���[�X�_�񌎎��X�V
 * Version          : 1.6
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         ��������                                  (A-1)
 *  chk_period_name              ��v���ԃ`�F�b�N                          (A-2)
 *  get_profile_values           �v���t�@�C���l�擾                        (A-10)
 *  get_ctrcted_les_info         �_��(�ă��[�X�_��)�ς݃��[�X�_���񒊏o  (A-3)
 *  update_cted_ct_status        �_��X�e�[�^�X�X�V                        (A-4)
 *  get_object_ctrct_info        �i�ă��[�X�v�ہj�����_���񒊏o          (A-5)
 *  update_ct_status             �_��X�e�[�^�X�X�V                        (A-6)
 *  update_ob_status             �����X�e�[�^�X�X�V                        (A-7)
 *  update_payplan_acct_flag     �x���v��̉�vIF�t���O(�ƍ��s��)�X�V      (A-8)
 *
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/12    1.0   SCS ���c         �V�K�쐬
 *  2009/02/05    1.1   SCS ���c         �_��ς݃��[�X�_����𒊏o���������'�w���v
 *                                       ����'����'�w���v���ԈȑO'�ɏC��
 *  2009/02/10    1.2   SCS ���c         ���O�̏o�͐悪����Ă����ӏ����C��
 *  2009/02/25    1.3   SCS ���c         �i�ă��[�X�v�ہj�����_���񒊏o�̏�����'�ă��[
 *                                       �X��'��ǉ�
 *  2009/08/28    1.4   SCS �n��         [�����e�X�g��Q0001058(PT�Ή�)]
 *  2013/07/24    1.5   SCSK ����        [E_�{�ғ�_10871]����ő��őΉ�
 *  2018/09/07    1.6   SCSK ���H        [E_�{�ғ�_14830]IFRS�ǉ��Ή�
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFF013A19C'; -- �p�b�P�[�W��
--
  -- ***�o�̓^�C�v
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';      --�o��(���[�U���b�Z�[�W�p�o�͐�)
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';         --���O(�V�X�e���Ǘ��җp�o�͐�)
--
  -- ***�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff   CONSTANT VARCHAR2(5) := 'XXCFF'; --�A�h�I���F��v�E���[�X�EFA�̈�
  cv_msg_kbn_ccp   CONSTANT VARCHAR2(5) := 'XXCCP'; --���ʂ̃��b�Z�[�W

  -- ***���b�Z�[�W��(�{��)
  cv_msg_name1     CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; --�R���J�����g���̓p�����[�^�Ȃ�
  cv_msg_name2     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; --�擾�Ώۃf�[�^����
  cv_msg_name3     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; --���b�N�G���[
  cv_msg_name4     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; --��v���ԃ`�F�b�N�G���[
  cv_msg_name5     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00131'; --�_��ς݃��[�X�_��X�V�������b�Z�[�W
  cv_msg_name6     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00133'; --�ă��[�X�v�����̃X�e�[�^�X�X�V�������b�Z�[�W
  cv_msg_name7     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00135'; --�ƍ��s�X�V�������b�Z�[�W
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
  cv_msg_name8     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; --�v���t�@�C���擾�G���[
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
--
  -- ***���b�Z�[�W��(�g�[�N��)
  cv_tkn_val1      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50132'; --�_��(�ă��[�X�_��)�ς݃��[�X�_����
  cv_tkn_val2      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50133'; --�i�ă��[�X�v�ہj�����_����
  cv_tkn_val3      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50030'; --���[�X�_�񖾍׃e�[�u��
  cv_tkn_val4      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50088'; --���[�X�x���v��
  cv_tkn_val5      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00062'; --�Ώۃf�[�^������܂���ł����B(�g�[�N���g�p)
  cv_tkn_val6      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50014'; --���[�X�����e�[�u��
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
  cv_tkn_val7      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50324'; -- XXCFF:�䒠��_IFRS���[�X�䒠
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
--
  -- ***�g�[�N����
  -- �v���t�@�C����
  cv_tkn_name1     CONSTANT VARCHAR2(100) := 'BOOK_TYPE_CODE'; --���Y�䒠��
  cv_tkn_name2     CONSTANT VARCHAR2(100) := 'PERIOD_NAME';    --��v���Ԗ�
  cv_tkn_name3     CONSTANT VARCHAR2(100) := 'GET_DATA';       --�擾�f�[�^
  cv_tkn_name4     CONSTANT VARCHAR2(100) := 'TABLE_NAME';     --�e�[�u��
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
  cv_tkn_name5     CONSTANT VARCHAR2(100) := 'PROF_NAME';      --�v���t�@�C����
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
--
  -- ***�v���t�@�C������
--
  -- ***���[�X���
  cv_les_kind_fin        CONSTANT VARCHAR2(1) := '0'; --Fin���[�X
  cv_les_kind_old_fin    CONSTANT VARCHAR2(1) := '2'; --��Fin���[�X
--
  -- ***�_��X�e�[�^�X
  cv_ctrct_st_reg            CONSTANT VARCHAR2(3) := '201'; --�o�^�ς�
  cv_ctrct_st_ctrct          CONSTANT VARCHAR2(3) := '202'; --�_��
  cv_ctrct_st_reles          CONSTANT VARCHAR2(3) := '203'; --�ă��[�X
  cv_ctrct_st_term           CONSTANT VARCHAR2(3) := '204'; --����
  cv_ctrct_st_mid_term       CONSTANT VARCHAR2(3) := '208'; --���r���(����)
--
  -- ***�����X�e�[�^�X
  cv_object_st_ctrcted       CONSTANT VARCHAR2(3) := '102'; --�_���
  cv_object_st_reles_wait    CONSTANT VARCHAR2(3) := '103'; --�ă��[�X��
  cv_object_st_reles_ctrcted CONSTANT VARCHAR2(3) := '104'; --�ă��[�X�_���
  cv_object_st_term          CONSTANT VARCHAR2(3) := '107'; --����
  cv_object_st_mid_term_appl CONSTANT VARCHAR2(3) := '108'; --���r���\��
  cv_object_st_mid_term      CONSTANT VARCHAR2(3) := '112'; --���r���(����)
--
  -- ***���[�X�敪
  cv_les_sec_original        CONSTANT VARCHAR2(1) := '1'; --���_��
  cv_les_sec_reles           CONSTANT VARCHAR2(1) := '2'; --�ă��[�X�_��
--
  -- ***�ă��[�X�v�t���O
  cv_reles_flag_nes          CONSTANT VARCHAR2(1) := '0'; --�ă��[�X�v
  cv_reles_flag_unnes        CONSTANT VARCHAR2(1) := '1'; --�ă��[�X��
--
  -- ***��vIF�t���O
  cv_acct_if_flag_unsent     CONSTANT VARCHAR2(1) := '1'; --�����M
  cv_acct_if_flag_dis_pymh   CONSTANT VARCHAR2(1) := '3'; --�ƍ��s��
--
  -- ***�ƍ��ς݃t���O
  cv_paymtch_flag_unadmin  CONSTANT VARCHAR2(1) := '0'; --���ƍ�
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
--
  -- ***�v���t�@�C��
  cv_ifrs_lease_books         CONSTANT VARCHAR2(35) := 'XXCFF1_IFRS_LEASE_BOOKS';  -- �䒠��_IFRS���[�X�䒠
--
  -- ***�Q�ƃ^�C�v
  cv_xxcff1_lease_class_check CONSTANT VARCHAR2(30) := 'XXCFF1_LEASE_CLASS_CHECK'; -- ���[�X��ʃ`�F�b�N
--
  -- ***����
  ct_language               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- ***�t���O����p
  cv_flg_y                    CONSTANT VARCHAR2(1)  := 'Y';
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ***�o���N�t�F�b�`�p��`
--
  --��v���ԃ`�F�b�N�p��`
  TYPE g_period_close_date_ttype      IS TABLE OF fa_deprn_periods.period_close_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_book_type_code_ttype         IS TABLE OF fa_deprn_periods.book_type_code%TYPE INDEX BY PLS_INTEGER;
--
  --�_��ς݃��[�X�_���񒊏o�J�[�\���p��`(�i�ă��[�X�v�ہj�����_���񒊏o�J�[�\���Ƌ��p���܂�)
  TYPE g_lease_type_ttype             IS TABLE OF xxcff_contract_headers.lease_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_header_id_ttype     IS TABLE OF xxcff_contract_lines.contract_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_id_ttype       IS TABLE OF xxcff_contract_lines.contract_line_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_num_ttype      IS TABLE OF xxcff_contract_lines.contract_line_num%TYPE INDEX BY PLS_INTEGER;
  TYPE g_first_charge_ttype           IS TABLE OF xxcff_contract_lines.first_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_first_tax_charge_ttype       IS TABLE OF xxcff_contract_lines.first_tax_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_first_total_charge_ttype     IS TABLE OF xxcff_contract_lines.first_total_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_second_charge_ttype          IS TABLE OF xxcff_contract_lines.second_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_second_tax_charge_ttype      IS TABLE OF xxcff_contract_lines.second_tax_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_second_total_charge_ttype    IS TABLE OF xxcff_contract_lines.second_total_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_first_deduction_ttype        IS TABLE OF xxcff_contract_lines.first_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_first_tax_deduction_ttype    IS TABLE OF xxcff_contract_lines.first_tax_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_first_total_deduction_ttype  IS TABLE OF xxcff_contract_lines.first_total_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_second_deduction_ttype       IS TABLE OF xxcff_contract_lines.second_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_second_tax_deduction_ttype   IS TABLE OF xxcff_contract_lines.second_tax_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_second_total_deduction_ttype 
    IS TABLE OF xxcff_contract_lines.second_total_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_gross_charge_ttype           IS TABLE OF xxcff_contract_lines.gross_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_gross_tax_charge_ttype       IS TABLE OF xxcff_contract_lines.gross_tax_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_gross_total_charge_ttype     IS TABLE OF xxcff_contract_lines.gross_total_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_gross_deduction_ttype        IS TABLE OF xxcff_contract_lines.gross_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_gross_tax_deduction_ttype    IS TABLE OF xxcff_contract_lines.gross_tax_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_gross_total_deduction_ttype  IS TABLE OF xxcff_contract_lines.gross_total_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_kind_ttype             IS TABLE OF xxcff_contract_lines.lease_kind%TYPE INDEX BY PLS_INTEGER;
  TYPE g_estimated_cash_price_ttype   IS TABLE OF xxcff_contract_lines.estimated_cash_price%TYPE INDEX BY PLS_INTEGER;
  TYPE g_prsnt_val_discnt_rate_ttype
    IS TABLE OF xxcff_contract_lines.present_value_discount_rate%TYPE INDEX BY PLS_INTEGER;
  TYPE g_present_value_ttype          IS TABLE OF xxcff_contract_lines.present_value%TYPE INDEX BY PLS_INTEGER;
  TYPE g_life_in_months_ttype         IS TABLE OF xxcff_contract_lines.life_in_months%TYPE INDEX BY PLS_INTEGER;
  TYPE g_original_cost_ttype          IS TABLE OF xxcff_contract_lines.original_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_calc_interested_rate_ttype   IS TABLE OF xxcff_contract_lines.calc_interested_rate%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_header_id_ttype       IS TABLE OF xxcff_contract_lines.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_asset_category_ttype         IS TABLE OF xxcff_contract_lines.asset_category%TYPE INDEX BY PLS_INTEGER;
  TYPE g_expiration_date_ttype        IS TABLE OF xxcff_contract_lines.expiration_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_cancellation_date_ttype      IS TABLE OF xxcff_contract_lines.cancellation_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_vd_if_date_ttype             IS TABLE OF xxcff_contract_lines.vd_if_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_info_sys_if_date_ttype       IS TABLE OF xxcff_contract_lines.info_sys_if_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_fst_inst_address_ttype
    IS TABLE OF xxcff_contract_lines.first_installation_address%TYPE INDEX BY PLS_INTEGER;
  TYPE g_fst_inst_place_ttype
    IS TABLE OF xxcff_contract_lines.first_installation_place%TYPE INDEX BY PLS_INTEGER;
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
  TYPE g_tax_code_ttype               IS TABLE OF xxcff_contract_lines.tax_code%TYPE INDEX BY PLS_INTEGER;
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
--
  --�i�ă��[�X�v�ہj�����_���񒊏o�J�[�\���p��`
  TYPE g_lease_end_date_ttype         IS TABLE OF xxcff_contract_headers.lease_end_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_code_ttype            IS TABLE OF xxcff_object_headers.object_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_class_ttype            IS TABLE OF xxcff_object_headers.lease_class%TYPE INDEX BY PLS_INTEGER;
  TYPE g_re_lease_times_ttype         IS TABLE OF xxcff_object_headers.re_lease_times%TYPE INDEX BY PLS_INTEGER;
  TYPE g_po_number_ttype              IS TABLE OF xxcff_object_headers.po_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_registration_number_ttype    IS TABLE OF xxcff_object_headers.registration_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_age_type_ttype               IS TABLE OF xxcff_object_headers.age_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_model_ttype                  IS TABLE OF xxcff_object_headers.model%TYPE INDEX BY PLS_INTEGER;
  TYPE g_serial_number_ttype          IS TABLE OF xxcff_object_headers.serial_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_quantity_ttype               IS TABLE OF xxcff_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;
  TYPE g_manufacturer_name_ttype      IS TABLE OF xxcff_object_headers.manufacturer_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_department_code_ttype        IS TABLE OF xxcff_object_headers.department_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_owner_company_ttype          IS TABLE OF xxcff_object_headers.owner_company%TYPE INDEX BY PLS_INTEGER;
  TYPE g_installation_address_ttype   IS TABLE OF xxcff_object_headers.installation_address%TYPE INDEX BY PLS_INTEGER;
  TYPE g_installation_place_ttype     IS TABLE OF xxcff_object_headers.installation_place %TYPE INDEX BY PLS_INTEGER;
  TYPE g_chassis_number_ttype         IS TABLE OF xxcff_object_headers.chassis_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_re_lease_flag_ttype          IS TABLE OF xxcff_object_headers.re_lease_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_cancellation_type_ttype      IS TABLE OF xxcff_object_headers.cancellation_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_cancellation_date_ob_ttype   IS TABLE OF xxcff_object_headers.cancellation_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_dissolution_date_ttype       IS TABLE OF xxcff_object_headers.dissolution_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_bond_acceptance_flag_ttype   IS TABLE OF xxcff_object_headers.bond_acceptance_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_bond_acceptance_date_ttype   IS TABLE OF xxcff_object_headers.bond_acceptance_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_expiration_date_ob_ttype     IS TABLE OF xxcff_object_headers.expiration_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_status_ttype          IS TABLE OF xxcff_object_headers.object_status%TYPE INDEX BY PLS_INTEGER;
  TYPE g_active_flag_ttype            IS TABLE OF xxcff_object_headers.active_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_info_sys_if_date_ob_ttype    IS TABLE OF xxcff_object_headers.info_sys_if_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_generation_date_ttype        IS TABLE OF xxcff_object_headers.generation_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_customer_code_ttype          IS TABLE OF xxcff_object_headers.customer_code%TYPE INDEX BY PLS_INTEGER;

  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  --�_��ς݃��[�X�_����X�e�[�^�X�X�V�����ɂ����錏��(A-3)
  gn_ctrcted_les_target_cnt      NUMBER;    --�Ώی���
  gn_ctrcted_les_normal_cnt      NUMBER;    --���팏��
  gn_ctrcted_les_error_cnt       NUMBER;    --�G���[����
--
  --�i�ă��[�X�v�j�����_����X�e�[�^�X�X�V�����ɂ����錏��(A-5)
  gn_reles_nes_target_cnt        NUMBER;    --�Ώی���
  gn_reles_nes_normal_cnt        NUMBER;    --���팏��
  gn_reles_nes_error_cnt         NUMBER;    --�G���[����
--
  --�ƍ��s�X�V�����ɂ����錏��(A-14)
  gn_acct_flag_target_cnt        NUMBER;    --�Ώی���
  gn_acct_flag_normal_cnt        NUMBER;    --���팏��
  gn_acct_flag_error_cnt         NUMBER;    --�G���[����
--
  -- �����l���
  g_init_rec                     xxcff_common1_pkg.init_rtype;
--
  --���[�X�_�񖾍׏��
  g_ct_lin_rec                   xxcff_common4_pkg.cont_lin_data_rtype;
--
  --���[�X�_�񖾍ח������
  g_ct_lin_his_rec               xxcff_common4_pkg.cont_his_data_rtype;
--
  --���[�X�����������
  g_ob_his_rec                   xxcff_common3_pkg.object_data_rtype;
--
  --�p�����[�^��v����
  gv_period_name                 VARCHAR2(100);
--
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
  -- ***�v���t�@�C���l
  -- �䒠��_IFRS���[�X�䒠
  gv_ifrs_lease_books      VARCHAR2(100);
--
  -- ���[�X���菈��
  gv_lease_class_att7      VARCHAR2(1);
--
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
  -- ***�o���N�t�F�b�`�p��`
--
  --��v���ԃ`�F�b�N�p��`
  g_period_close_date_tab                g_period_close_date_ttype;
  g_book_type_code_tab                   g_book_type_code_ttype;
--
  --�_��ς݃��[�X�_���񒊏o�J�[�\���p��`(�i�ă��[�X�v�ہj�����_���񒊏o�J�[�\���Ƃ̋��p���܂�)
  g_lease_type_tab                       g_lease_type_ttype;
  g_contract_header_id_tab               g_contract_header_id_ttype;
  g_contract_line_id_tab                 g_contract_line_id_ttype;
  g_contract_line_num_tab                g_contract_line_num_ttype;
  g_first_charge_tab                     g_first_charge_ttype;
  g_first_tax_charge_tab                 g_first_tax_charge_ttype;
  g_first_total_charge_tab               g_first_total_charge_ttype;
  g_second_charge_tab                    g_second_charge_ttype;
  g_second_tax_charge_tab                g_second_tax_charge_ttype;
  g_second_total_charge_tab              g_second_total_charge_ttype;
  g_first_deduction_tab                  g_first_deduction_ttype;
  g_first_tax_deduction_tab              g_first_tax_deduction_ttype;
  g_first_total_deduction_tab            g_first_total_deduction_ttype;
  g_second_deduction_tab                 g_second_deduction_ttype;
  g_second_tax_deduction_tab             g_second_tax_deduction_ttype;
  g_second_total_deduction_tab           g_second_total_deduction_ttype;
  g_gross_charge_tab                     g_gross_charge_ttype;
  g_gross_tax_charge_tab                 g_gross_tax_charge_ttype;
  g_gross_total_charge_tab               g_gross_total_charge_ttype;
  g_gross_deduction_tab                  g_gross_deduction_ttype;
  g_gross_tax_deduction_tab              g_gross_tax_deduction_ttype;
  g_gross_total_deduction_tab            g_gross_total_deduction_ttype;
  g_lease_kind_tab                       g_lease_kind_ttype;
  g_estimated_cash_price_tab             g_estimated_cash_price_ttype;
  g_prsnt_val_discnt_rate_tab            g_prsnt_val_discnt_rate_ttype;
  g_present_value_tab                    g_present_value_ttype;
  g_life_in_months_tab                   g_life_in_months_ttype;
  g_original_cost_tab                    g_original_cost_ttype;
  g_calc_interested_rate_tab             g_calc_interested_rate_ttype;
  g_object_header_id_tab                 g_object_header_id_ttype;
  g_asset_category_tab                   g_asset_category_ttype;
  g_expiration_date_tab                  g_expiration_date_ttype;
  g_cancellation_date_tab                g_cancellation_date_ttype;
  g_vd_if_date_tab                       g_vd_if_date_ttype;
  g_info_sys_if_date_tab                 g_info_sys_if_date_ttype;
  g_fst_inst_address_tab                 g_fst_inst_address_ttype;
  g_fst_inst_place_tab                   g_fst_inst_place_ttype;
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
  g_tax_code_tab                         g_tax_code_ttype;
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
--
  --�i�ă��[�X�v�ہj�����_���񒊏o�J�[�\���p��`
  g_lease_end_date_tab                   g_lease_end_date_ttype;
  g_object_code_tab                      g_object_code_ttype;
  g_lease_class_tab                      g_lease_class_ttype;
  g_re_lease_times_tab                   g_re_lease_times_ttype;
  g_po_number_tab                        g_po_number_ttype;
  g_registration_number_tab              g_registration_number_ttype;
  g_age_type_tab                         g_age_type_ttype;
  g_model_tab                            g_model_ttype;
  g_serial_number_tab                    g_serial_number_ttype;
  g_quantity_tab                         g_quantity_ttype;
  g_manufacturer_name_tab                g_manufacturer_name_ttype;
  g_department_code_tab                  g_department_code_ttype;
  g_owner_company_tab                    g_owner_company_ttype;
  g_installation_address_tab             g_installation_address_ttype;
  g_installation_place                   g_installation_place_ttype;
  g_chassis_number_tab                   g_chassis_number_ttype;
  g_re_lease_flag_tab                    g_re_lease_flag_ttype;
  g_cancellation_type_tab                g_cancellation_type_ttype;
  g_cancellation_date_ob_tab             g_cancellation_date_ob_ttype;
  g_dissolution_date_tab                 g_dissolution_date_ttype;
  g_bond_acceptance_flag_tab             g_bond_acceptance_flag_ttype;
  g_bond_acceptance_date_tab             g_bond_acceptance_date_ttype;
  g_expiration_date_ob_tab               g_expiration_date_ob_ttype;
  g_object_status_tab                    g_object_status_ttype;
  g_active_flag_tab                      g_active_flag_ttype;
  g_info_sys_if_date_ob_tab              g_info_sys_if_date_ob_ttype;
  g_generation_date_tab                  g_generation_date_ttype;
  g_customer_code_tab                    g_customer_code_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
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
    -- �����l���̎擾
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- �����l���
      ,ov_errbuf   => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode  => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg   => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
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
   * Procedure Name   : chk_period_name
   * Description      : ��v���ԃ`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE chk_period_name(
    iv_period_name  IN   VARCHAR2,     -- 1.��v���Ԗ�
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
    iv_book_type_code IN VARCHAR2,     -- 2.�䒠��
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
    ov_errbuf       OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT  VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period_name'; -- �v���O������
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
    CURSOR period_cur
    IS
      SELECT
              fdp.period_close_date   AS period_close_dt  --���ԃN���[�Y��
             ,fdp.book_type_code      AS book_type_code   --���Y�䒠��
        FROM
-- 2018/09/07 Ver.1.6 Y.Shoji MOD Start
--              xxcff_lease_kind_v  xlk  --���[�X��ރr���[
--             ,fa_deprn_periods    fdp  --�������p����
              fa_deprn_periods    fdp  --�������p����
-- 2018/09/07 Ver.1.6 Y.Shoji MOD End
       WHERE
-- 2018/09/07 Ver.1.6 Y.Shoji MOD Start
--              xlk.lease_kind_code IN ( cv_les_kind_fin, cv_les_kind_old_fin )
--         AND  xlk.book_type_code  = fdp.book_type_code
              fdp.book_type_code  = iv_book_type_code
-- 2018/09/07 Ver.1.6 Y.Shoji MOD End
         AND  fdp.period_name     = iv_period_name
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
    --�e���Y�䒠�ɂ����ĉ�v���Ԃ��I�[�v���ł��邱�Ƃ��`�F�b�N
--
    --�J�[�\���̃I�[�v��
    OPEN period_cur;
    FETCH period_cur
    BULK COLLECT INTO  g_period_close_date_tab  --���ԃN���[�Y��
                      ,g_book_type_code_tab     --���Y�䒠��
    ;
    --�Y�������̕ێ�
    IF ( period_cur%ROWCOUNT = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name4                         -- ��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_name1                         -- �g�[�N��'BOOK_TYPE_CODE'
                                                    ,cv_tkn_val5                          -- ���Y�䒠��->�Ȃ�
                                                    ,cv_tkn_name2                         -- �g�[�N��'PERIOD_NAME'
                                                    ,iv_period_name)                      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    --�J�[�\���̃N���[�Y
    CLOSE period_cur;
--
    <<chk_period_name_loop>>
    FOR ln_loop_cnt IN g_period_close_date_tab.FIRST .. g_period_close_date_tab.LAST LOOP
      --���ԃN���[�Y����NULL�łȂ������ꍇ
      IF ( g_period_close_date_tab(ln_loop_cnt) IS NOT NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name4                         -- ��v���ԃ`�F�b�N�G���[
                                                      ,cv_tkn_name1                         -- �g�[�N��'BOOK_TYPE_CODE'
                                                      ,g_book_type_code_tab(ln_loop_cnt)    -- ���Y�䒠��
                                                      ,cv_tkn_name2                         -- �g�[�N��'PERIOD_NAME'
                                                      ,iv_period_name)                      -- ��v���Ԗ�
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END LOOP chk_period_name_loop;
--
    --�O���[�o���ϐ��ɐݒ�
    gv_period_name := iv_period_name;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN                           --*** ���ʊ֐��R�����g ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      IF ( period_cur%ISOPEN ) THEN
        CLOSE period_cur;
      END IF;
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
  END chk_period_name;
--
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : �v���t�@�C���l�擾(A-10)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    iv_book_type_code IN  VARCHAR2,     --   1.�䒠��
    ov_errbuf         OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- �v���O������
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
    -- ���[�X���菈��
    cv_lease_class_att7_1      CONSTANT VARCHAR2(1)  := '1'; -- 1:FIN���[�X
    cv_lease_class_att7_2      CONSTANT VARCHAR2(1)  := '2'; -- 2:IFRS���[�X
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
    -- XXCFF:�䒠��_IFRS���[�X�䒠
    gv_ifrs_lease_books := FND_PROFILE.VALUE(cv_ifrs_lease_books);
    IF (gv_ifrs_lease_books IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_name8         -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_name5         -- �g�[�N��'PROF_NAME'
                                                    ,cv_tkn_val7)         -- XXCFF:�䒠��_IFRS���[�X�䒠
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --IFRS���[�X�䒠�̏ꍇ
    IF ( iv_book_type_code = gv_ifrs_lease_books ) THEN
      -- ���[�X���菈��=2
      gv_lease_class_att7 := cv_lease_class_att7_2;
    --IFRS���[�X�䒠�ȊO�̏ꍇ
    ELSE
      -- ���[�X���菈��=1
      gv_lease_class_att7 := cv_lease_class_att7_1;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
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
--#####################################  �Œ蕔 END   ##########################################
--
  END get_profile_values;
--
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
  /**********************************************************************************
   * Procedure Name   : get_ctrcted_les_info
   * Description      : �_��(�ă��[�X�_��)�ς݃��[�X�_���񒊏o����(A-3)
   ***********************************************************************************/
  PROCEDURE get_ctrcted_les_info(
    ov_errbuf       OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT  VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ctrcted_les_info'; -- �v���O������
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
    lv_warnmsg  VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
    --�_��ς݃��[�X�_���񒊏o�J�[�\��(���[�X�敪�v)
    CURSOR ctrcted_les_info_cur
    IS
      SELECT
-- 0001058 2009/08/28 ADD START --
            /*+
              LEADING(XCL)
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
              USE_NL(XCL XOH XCH)
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
              INDEX(XCL XXCFF_CONTRACT_LINES_N01)
              INDEX(XCH XXCFF_CONTRACT_HEADERS_PK)
              INDEX(XOH XXCFF_OBJECT_HEADERS_PK)
            */
-- 0001058 2009/08/28 ADD END --
              xch.lease_type                  AS lease_type                  --���[�X�敪(A-4�g�p)
             ,xcl.contract_header_id          AS contract_header_id          --�_�����ID
             ,xcl.contract_line_id            AS contract_line_id            --�_�񖾍ד���ID
             ,xcl.contract_line_num           AS contract_line_num           --�_��}��(A-4�g�p)
             ,xcl.first_charge                AS first_charge                --���񌎊z���[�X��_���[�X��
             ,xcl.first_tax_charge            AS first_tax_charge            --�������Ŋz_���[�X��
             ,xcl.first_total_charge          AS first_total_charge          --����v_���[�X��
             ,xcl.second_charge               AS second_charge               --2��ڈȍ~���z���[�X��_���[�X��
             ,xcl.second_tax_charge           AS second_tax_charge           --2��ڈȍ~����Ŋz_���[�X��
             ,xcl.second_total_charge         AS second_total_charge         --2��ڈȍ~�v_���[�X��
             ,xcl.first_deduction             AS first_deduction             --���񌎊z���[�X��_�T���z
             ,xcl.first_tax_deduction         AS first_tax_deduction         --���񌎊z����Ŋz_�T���z
             ,xcl.first_total_deduction       AS first_total_deduction       --����v_�T���z
             ,xcl.second_deduction            AS second_deduction            --2��ڈȍ~���z���[�X��_�T���z
             ,xcl.second_tax_deduction        AS second_tax_deduction        --2��ڈȍ~����Ŋz_�T���z
             ,xcl.second_total_deduction      AS second_total_deduction      --2��ڈȍ~�v_�T���z
             ,xcl.gross_charge                AS gross_charge                --���z���[�X��_���[�X��
             ,xcl.gross_tax_charge            AS gross_tax_charge            --���z�����_���[�X��
             ,xcl.gross_total_charge          AS gross_total_charge          --���z�v_���[�X��
             ,xcl.gross_deduction             AS gross_deduction             --���z���[�X��_�T���z
             ,xcl.gross_tax_deduction         AS gross_tax_deduction         --���z�����_�T���z
             ,xcl.gross_total_deduction       AS gross_total_deduction       --���z�v_�T���z
             ,xcl.lease_kind                  AS lease_kind                  --���[�X���
             ,xcl.estimated_cash_price        AS estimated_cash_price        --���ό����w�����z
             ,xcl.present_value_discount_rate AS present_value_discount_rate --���݉��l������
             ,xcl.present_value               AS present_value               --���݉��l
             ,xcl.life_in_months              AS life_in_months              --�@��ϗp�N��
             ,xcl.original_cost               AS original_cost               --�擾���z
             ,xcl.calc_interested_rate        AS calc_interested_rate        --�v�Z���q��
             ,xcl.object_header_id            AS object_header_id            --��������ID
             ,xcl.asset_category              AS asset_category              --���Y���
             ,xcl.expiration_date             AS expiration_date             --������
             ,xcl.cancellation_date           AS cancellation_date           --���r����
             ,xcl.vd_if_date                  AS vd_if_date                  --���[�X�_����A�g��
             ,xcl.info_sys_if_date            AS info_sys_if_date            --���[�X�Ǘ����A�g��
             ,xcl.first_installation_address  AS first_installation_address  --����ݒu�ꏊ
             ,xcl.first_installation_place    AS first_installation_place    --����ݒu��
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
             ,xcl.tax_code                    AS tax_code                    --�ŋ��R�[�h
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
        FROM
              xxcff_contract_lines    xcl --���[�X�_�񖾍�
             ,xxcff_object_headers    xoh --���[�X����
             ,xxcff_contract_headers  xch --���[�X�_��
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
             ,fnd_lookup_values       flv -- �Q�ƕ\
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
       WHERE
              xcl.object_header_id   = xoh.object_header_id           --��������ID
         AND  xcl.contract_header_id = xch.contract_header_id         --�_�����ID
         AND  xcl.contract_status    = cv_ctrct_st_reg                --�_��X�e�[�^�X:�o�^�ς�
         AND  TO_CHAR(xch.first_payment_date, 'YYYYMM') <= 
                TO_CHAR(TO_DATE(gv_period_name, 'YYYY-MM'), 'YYYYMM') --����x����
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
         AND  xch.lease_class        = flv.lookup_code
         AND  flv.lookup_type        = cv_xxcff1_lease_class_check   -- ���[�X��ʃ`�F�b�N
         AND  flv.attribute7         = gv_lease_class_att7           -- ���[�X���菈��
         AND  flv.language           = ct_language
         AND  flv.enabled_flag       = cv_flg_y
         AND  TO_DATE(gv_period_name,'YYYY-MM') BETWEEN NVL(flv.start_date_active, TO_DATE(gv_period_name,'YYYY-MM'))
                                                AND     NVL(flv.end_date_active  , TO_DATE(gv_period_name,'YYYY-MM'))
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
         FOR UPDATE OF xcl.contract_header_id NOWAIT    
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
    --�J�[�\�����I�[�v��
    OPEN ctrcted_les_info_cur;
    --�f�[�^�̈ꊇ�擾
    FETCH ctrcted_les_info_cur
    BULK COLLECT INTO  g_lease_type_tab                   --���[�X�敪
                      ,g_contract_header_id_tab           --�_�����ID
                      ,g_contract_line_id_tab             --�_�񖾍ד���ID
                      ,g_contract_line_num_tab            --�_��}��
                      ,g_first_charge_tab                 --���񌎊z���[�X��_���[�X��
                      ,g_first_tax_charge_tab             --�������Ŋz_���[�X��
                      ,g_first_total_charge_tab           --����v_���[�X��
                      ,g_second_charge_tab                --2��ڈȍ~���z���[�X��_���[�X��
                      ,g_second_tax_charge_tab            --2��ڈȍ~����Ŋz_���[�X��
                      ,g_second_total_charge_tab          --2��ڈȍ~�v_���[�X��
                      ,g_first_deduction_tab              --���񌎊z���[�X��_�T���z
                      ,g_first_tax_deduction_tab          --���񌎊z����Ŋz_�T���z
                      ,g_first_total_deduction_tab        --����v_�T���z
                      ,g_second_deduction_tab             --2��ڈȍ~���z���[�X��_�T���z
                      ,g_second_tax_deduction_tab         --2��ڈȍ~����Ŋz_�T���z
                      ,g_second_total_deduction_tab       --2��ڈȍ~�v_�T���z
                      ,g_gross_charge_tab                 --���z���[�X��_���[�X��
                      ,g_gross_tax_charge_tab             --���z�����_���[�X��
                      ,g_gross_total_charge_tab           --���z�v_���[�X��
                      ,g_gross_deduction_tab              --���z���[�X��_�T���z
                      ,g_gross_tax_deduction_tab          --���z�����_�T���z
                      ,g_gross_total_deduction_tab        --���z�v_�T���z
                      ,g_lease_kind_tab                   --���[�X���
                      ,g_estimated_cash_price_tab         --���ό����w�����z
                      ,g_prsnt_val_discnt_rate_tab        --���݉��l������
                      ,g_present_value_tab                --���݉��l
                      ,g_life_in_months_tab               --�@��ϗp�N��
                      ,g_original_cost_tab                --�擾���z
                      ,g_calc_interested_rate_tab         --�v�Z���q��
                      ,g_object_header_id_tab             --��������ID
                      ,g_asset_category_tab               --���Y���
                      ,g_expiration_date_tab              --������
                      ,g_cancellation_date_tab            --���r����
                      ,g_vd_if_date_tab                   --���[�X�_����A�g��
                      ,g_info_sys_if_date_tab             --���[�X�Ǘ����A�g��
                      ,g_fst_inst_address_tab             --����ݒu�ꏊ
                      ,g_fst_inst_place_tab               --����ݒu��
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
                      ,g_tax_code_tab                     --�ŋ��R�[�h
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
    ;
    --�Ώی�����0���̏ꍇ
    IF ( ctrcted_les_info_cur%ROWCOUNT = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff    -- XXCFF
                                                     ,cv_msg_name2      -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_name3      -- �g�[�N��'GET_DATA'
                                                     ,cv_tkn_val1)      -- �_��(�ă��[�X�_��)�ς݃��[�X�_����
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    ELSE
      --�����Ώی����J�E���^�[�C���N�������g
      gn_ctrcted_les_target_cnt := g_contract_header_id_tab.COUNT;
    END IF;
--
    --�J�[�\�����N���[�Y
    CLOSE ctrcted_les_info_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      IF ( ctrcted_les_info_cur%ISOPEN ) THEN
        CLOSE ctrcted_les_info_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_name3         -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_name4         -- �g�[�N��'TABLE'
                                                     ,cv_tkn_val3)         -- ���[�X�_�񖾍׃e�[�u��
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_ctrcted_les_info;
--
  /**********************************************************************************
   * Procedure Name   : update_cted_ct_status
   * Description      : �_��X�e�[�^�X�X�V����(A-4)
   ***********************************************************************************/
  PROCEDURE update_cted_ct_status(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_cted_ct_status'; -- �v���O������
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
    IF ( gn_ctrcted_les_target_cnt <> 0 ) THEN
      --���C�����[�v�@
--
      --1.���[�X�_�񖾍ׂ̌_��X�e�[�^�X�X�V
      <<update_loop>> --�_��X�e�[�^�X�X�V���[�v
      FORALL ln_loop_cnt IN g_contract_line_id_tab.FIRST .. g_contract_line_id_tab.LAST
        UPDATE
                xxcff_contract_lines
           SET
                contract_status = DECODE(g_lease_type_tab(ln_loop_cnt)
                                           ,cv_les_sec_original, cv_ctrct_st_ctrct
                                           ,cv_les_sec_reles,    cv_ctrct_st_reles
                                        )                           --�_��X�e�[�^�X
               ,last_updated_by        = cn_last_updated_by         --�ŏI�X�V��
               ,last_update_date       = cd_last_update_date        --�ŏI�X�V��
               ,last_update_login      = cn_last_update_login       --�ŏI�X�V���O�C��
               ,request_id             = cn_request_id              --�v��ID
               ,program_application_id = cn_program_application_id  --�ݶ��ĥ��۸��ѥ���ع����ID
               ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
               ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
         WHERE
                contract_line_id = g_contract_line_id_tab(ln_loop_cnt)
        ;
      --�_��X�e�[�^�X�X�V���[�v �I��
--
      --2.���[�X�_�񖾍ח����̗����f�[�^�쐬
--
      --���[�X�_�񖾍ח�����񃌃R�[�h�̐ݒ�
      g_ct_lin_his_rec.accounting_date     := LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM'));  --�v���
      g_ct_lin_his_rec.accounting_if_flag  := cv_acct_if_flag_unsent;                        --��vIF�t���O
--
      <<insert_hist_loop>> --���[�X�_�񖾍ח���o�^���[�v
      FOR ln_loop_cnt IN g_contract_line_id_tab.FIRST .. g_contract_line_id_tab.LAST LOOP
--
        --���[�X�_�񖾍׏�񃌃R�[�h�̐ݒ�
        g_ct_lin_rec.contract_header_id     := g_contract_header_id_tab(ln_loop_cnt);    --�_�����ID
        g_ct_lin_rec.contract_line_id       := g_contract_line_id_tab(ln_loop_cnt);      --�_�񖾍ד���ID
        g_ct_lin_rec.contract_line_num      := g_contract_line_num_tab(ln_loop_cnt);     --�_��}��
        g_ct_lin_rec.contract_status        := CASE g_lease_type_tab(ln_loop_cnt)        --�_��X�e�[�^�X
                                                 WHEN  cv_les_sec_original THEN cv_ctrct_st_ctrct
                                                 WHEN  cv_les_sec_reles    THEN cv_ctrct_st_reles
                                               END;
        g_ct_lin_rec.first_charge           := g_first_charge_tab(ln_loop_cnt);          --���񌎊z���[�X��_���[�X��
        g_ct_lin_rec.first_tax_charge       := g_first_tax_charge_tab(ln_loop_cnt);      --�������Ŋz_���[�X��
        g_ct_lin_rec.first_total_charge     := g_first_total_charge_tab(ln_loop_cnt);    --����v_���[�X��
        g_ct_lin_rec.second_charge          := g_second_charge_tab(ln_loop_cnt);         --2��ڈȍ~���z���[�X��_���[�X��
        g_ct_lin_rec.second_tax_charge      := g_second_tax_charge_tab(ln_loop_cnt);     --2��ڈȍ~����Ŋz_���[�X��
        g_ct_lin_rec.second_total_charge    := g_second_total_charge_tab(ln_loop_cnt);   --2��ڈȍ~�v_���[�X��
        g_ct_lin_rec.first_deduction        := g_first_deduction_tab(ln_loop_cnt);       --���񌎊z���[�X��_�T���z
        g_ct_lin_rec.first_tax_deduction    := g_first_tax_deduction_tab(ln_loop_cnt);   --���񌎊z����Ŋz_�T���z
        g_ct_lin_rec.first_total_deduction  := g_first_total_deduction_tab(ln_loop_cnt); --����v_�T���z
        g_ct_lin_rec.second_deduction       := g_second_deduction_tab(ln_loop_cnt);      --2��ڈȍ~���z���[�X��_�T���z
        g_ct_lin_rec.second_tax_deduction   := g_second_tax_deduction_tab(ln_loop_cnt);  --2��ڈȍ~����Ŋz_�T���z
        g_ct_lin_rec.second_total_deduction := g_second_total_deduction_tab(ln_loop_cnt);      --2��ڈȍ~�v_�T���z
        g_ct_lin_rec.gross_charge           := g_gross_charge_tab(ln_loop_cnt);          --���z���[�X��_���[�X��
        g_ct_lin_rec.gross_tax_charge       := g_gross_tax_charge_tab(ln_loop_cnt);      --���z�����_���[�X��
        g_ct_lin_rec.gross_total_charge     := g_gross_total_charge_tab(ln_loop_cnt);    --���z�v_���[�X��
        g_ct_lin_rec.gross_deduction        := g_gross_deduction_tab(ln_loop_cnt);       --���z���[�X��_�T���z
        g_ct_lin_rec.gross_tax_deduction    := g_gross_tax_deduction_tab(ln_loop_cnt);   --���z�����_�T���z
        g_ct_lin_rec.gross_total_deduction  := g_gross_total_deduction_tab(ln_loop_cnt); --���z�v_�T���z
        g_ct_lin_rec.lease_kind             := g_lease_kind_tab(ln_loop_cnt);            --���[�X���
        g_ct_lin_rec.estimated_cash_price   := g_estimated_cash_price_tab(ln_loop_cnt);  --���ό����w�����z
        g_ct_lin_rec.present_value_discount_rate := g_prsnt_val_discnt_rate_tab(ln_loop_cnt);  --���݉��l������
        g_ct_lin_rec.present_value          := g_present_value_tab(ln_loop_cnt);         --���݉��l
        g_ct_lin_rec.life_in_months         := g_life_in_months_tab(ln_loop_cnt);        --�@��ϗp�N��
        g_ct_lin_rec.original_cost          := g_original_cost_tab(ln_loop_cnt);         --�擾���z
        g_ct_lin_rec.calc_interested_rate   := g_calc_interested_rate_tab(ln_loop_cnt);  --�v�Z���q��
        g_ct_lin_rec.object_header_id       := g_object_header_id_tab(ln_loop_cnt);      --��������ID
        g_ct_lin_rec.asset_category         := g_asset_category_tab(ln_loop_cnt);        --���Y���
        g_ct_lin_rec.expiration_date        := g_expiration_date_tab(ln_loop_cnt);       --������
        g_ct_lin_rec.cancellation_date      := g_cancellation_date_tab(ln_loop_cnt);     --���r����
        g_ct_lin_rec.vd_if_date             := g_vd_if_date_tab(ln_loop_cnt);            --���[�X�_����A�g��
        g_ct_lin_rec.info_sys_if_date       := g_info_sys_if_date_tab(ln_loop_cnt);      --���[�X�Ǘ����A�g��
        g_ct_lin_rec.first_installation_address  := g_fst_inst_address_tab(ln_loop_cnt); --����ݒu�ꏊ
        g_ct_lin_rec.first_installation_place    := g_fst_inst_place_tab(ln_loop_cnt);   --����ݒu��
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
        g_ct_lin_rec.tax_code               := g_tax_code_tab(ln_loop_cnt);              --�ŋ��R�[�h
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
        -- �ȉ��AWHO�J�������
        g_ct_lin_rec.created_by             := cn_created_by;              --�쐬��
        g_ct_lin_rec.creation_date          := cd_creation_date;           --�쐬��
        g_ct_lin_rec.last_updated_by        := cn_last_updated_by;         --�ŏI�X�V��
        g_ct_lin_rec.last_update_date       := cd_last_update_date;        --�ŏI�X�V��
        g_ct_lin_rec.last_update_login      := cn_last_update_login;       --�ŏI�X�V���O�C��
        g_ct_lin_rec.request_id             := cn_request_id;              --�v��ID
        g_ct_lin_rec.program_application_id := cn_program_application_id;  --�ݶ��ĥ��۸��ѥ���ع����ID
        g_ct_lin_rec.program_id             := cn_program_id;              --�R���J�����g��v���O����ID
        g_ct_lin_rec.program_update_date    := cd_program_update_date;     --�v���O�����X�V��
--
        --���ʊ֐� ���[�X�_�񗚗�o�^ �̌ďo
        xxcff_common4_pkg.insert_co_his(
          io_contract_lin_data_rec  => g_ct_lin_rec      -- �_�񖾍׏��
         ,io_contract_his_data_rec  => g_ct_lin_his_rec  -- �_�񗚗����
         ,ov_errbuf                 => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode                => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                 => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
        ELSE
          gn_ctrcted_les_normal_cnt := ln_loop_cnt;
        END IF;
--
      END LOOP insert_hist_loop; --���[�X�_�񖾍ח���o�^���[�v�I��
      --���C�����[�v�@ �I��
    END IF;
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
  END update_cted_ct_status;
--
  /**********************************************************************************
   * Procedure Name   : get_object_ctrct_info
   * Description      : �i�ă��[�X�v�ہj�����_���񒊏o����(A-5)
   ***********************************************************************************/
  PROCEDURE get_object_ctrct_info(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_object_ctrct_info'; -- �v���O������
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
    lv_warnmsg  VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
    --�i�ă��[�X�v�ہj�����_���񒊏o�J�[�\��
    CURSOR reles_ob_ctrct_info_cur
    IS
      SELECT
-- 0001058 2009/08/28 ADD START --
            /*+
              LEADING(XCH)
              INDEX(XCH XXCFF_CONTRACT_HEADERS_N03)
              INDEX(XCL XXCFF_CONTRACT_LINES_U01)
              INDEX(XOH XXCFF_OBJECT_HEADERS_PK)
            */
-- 0001058 2009/08/28 ADD END --
              xch.lease_end_date              AS lease_end_date              --���[�X�I����
             ,xcl.contract_header_id          AS contract_header_id          --�_�����ID
             ,xcl.contract_line_id            AS contract_line_id            --�_�񖾍ד���ID
             ,xcl.contract_line_num           AS contract_line_num           --�_��}��(A-6�g�p)
             ,xcl.first_charge                AS first_charge                --���񌎊z���[�X��_���[�X��
             ,xcl.first_tax_charge            AS first_tax_charge            --�������Ŋz_���[�X��
             ,xcl.first_total_charge          AS first_total_charge          --����v_���[�X��
             ,xcl.second_charge               AS second_charge               --2��ڈȍ~���z���[�X��_���[�X��
             ,xcl.second_tax_charge           AS second_tax_charge           --2��ڈȍ~����Ŋz_���[�X��
             ,xcl.second_total_charge         AS second_total_charge         --2��ڈȍ~�v_���[�X��
             ,xcl.first_deduction             AS first_deduction             --���񌎊z���[�X��_�T���z
             ,xcl.first_tax_deduction         AS first_tax_deduction         --���񌎊z����Ŋz_�T���z
             ,xcl.first_total_deduction       AS first_total_deduction       --����v_�T���z
             ,xcl.second_deduction            AS second_deduction            --2��ڈȍ~���z���[�X��_�T���z
             ,xcl.second_tax_deduction        AS second_tax_deduction        --2��ڈȍ~����Ŋz_�T���z
             ,xcl.second_total_deduction      AS second_total_deduction      --2��ڈȍ~�v_�T���z
             ,xcl.gross_charge                AS gross_charge                --���z���[�X��_���[�X��
             ,xcl.gross_tax_charge            AS gross_tax_charge            --���z�����_���[�X��
             ,xcl.gross_total_charge          AS gross_total_charge          --���z�v_���[�X��
             ,xcl.gross_deduction             AS gross_deduction             --���z���[�X��_�T���z
             ,xcl.gross_tax_deduction         AS gross_tax_deduction         --���z�����_�T���z
             ,xcl.gross_total_deduction       AS gross_total_deduction       --���z�v_�T���z
             ,xcl.lease_kind                  AS lease_kind                  --���[�X���
             ,xcl.estimated_cash_price        AS estimated_cash_price        --���ό����w�����z
             ,xcl.present_value_discount_rate AS present_value_discount_rate --���݉��l������
             ,xcl.present_value               AS present_value               --���݉��l
             ,xcl.life_in_months              AS life_in_months              --�@��ϗp�N��
             ,xcl.original_cost               AS original_cost               --�擾���z
             ,xcl.calc_interested_rate        AS calc_interested_rate        --�v�Z���q��
             ,xcl.object_header_id            AS object_header_id            --��������ID
             ,xcl.asset_category              AS asset_category              --���Y���
             ,xcl.expiration_date             AS expiration_date             --������
             ,xcl.cancellation_date           AS cancellation_date           --���r����
             ,xcl.vd_if_date                  AS vd_if_date                  --���[�X�_����A�g��
             ,xcl.info_sys_if_date            AS info_sys_if_date            --���[�X�Ǘ����A�g��
             ,xcl.first_installation_address  AS first_installation_address  --����ݒu�ꏊ
             ,xcl.first_installation_place    AS first_installation_place    --����ݒu��
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
             ,xcl.tax_code                    AS tax_code                    --�ŋ��R�[�h
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
             ,xoh.object_code                 AS object_code                 --�����R�[�h
             ,xoh.lease_class                 AS lease_class                 --���[�X���
             ,xoh.lease_type                  AS lease_type                  --���[�X�敪
             ,xoh.re_lease_times              AS re_lease_times              --�ă��[�X��
             ,xoh.po_number                   AS po_number                   --�����ԍ�
             ,xoh.registration_number         AS registration_number         --�o�^�ԍ�
             ,xoh.age_type                    AS age_type                    --�N��
             ,xoh.model                       AS model                       --�@��
             ,xoh.serial_number               AS serial_number               --�@��
             ,xoh.quantity                    AS quantity                    --����
             ,xoh.manufacturer_name           AS manufacturer_name           --���[�J�[��
             ,xoh.department_code             AS department_code             --�Ǘ�����R�[�h
             ,xoh.owner_company               AS owner_company               --�{�Ё^�H��
             ,xoh.installation_address        AS installation_address        --���ݒu�ꏊ
             ,xoh.installation_place          AS installation_place          --���ݒu��
             ,xoh.chassis_number              AS chassis_number              --�ԑ�ԍ�
             ,xoh.re_lease_flag               AS re_lease_flag               --�ă��[�X�v�t���O
             ,xoh.cancellation_type           AS cancellation_type           --���敪
             ,xoh.cancellation_date           AS cancellation_date           --���r����
             ,xoh.dissolution_date            AS dissolution_date            --���r���L�����Z����
             ,xoh.bond_acceptance_flag        AS bond_acceptance_flag        --�؏���̃t���O
             ,xoh.bond_acceptance_date        AS bond_acceptance_date        --�؏���̓�
             ,xoh.expiration_date             AS expiration_date             --������
             ,xoh.object_status               AS object_status               --�����X�e�[�^�X
             ,xoh.active_flag                 AS active_flag                 --�����L���t���O
             ,xoh.info_sys_if_date            AS info_sys_if_date            --���[�X�Ǘ����A�g��
             ,xoh.generation_date             AS generation_date             --������
             ,xoh.customer_code               AS customer_code               --�ڋq�R�[�h
        FROM
              xxcff_contract_lines    xcl --���[�X�_�񖾍�
             ,xxcff_object_headers    xoh --���[�X����
             ,xxcff_contract_headers  xch --���[�X�_��
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
             ,fnd_lookup_values       flv -- �Q�ƕ\
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
       WHERE
              xcl.object_header_id   = xoh.object_header_id           --��������ID
         AND  xcl.contract_header_id = xch.contract_header_id         --�_�����ID
-- 0001058 2009/08/28 MOD START --
--         AND  TO_CHAR(xch.lease_end_date, 'YYYYMM') = 
--                TO_CHAR(TO_DATE(gv_period_name, 'YYYY-MM'), 'YYYYMM') --���[�X�I����
         AND  xch.lease_end_date    BETWEEN TO_DATE(gv_period_name || '-01','YYYY-MM-DD')
                                    AND     LAST_DAY(TO_DATE(gv_period_name || '-01','YYYY-MM-DD')) --���[�X�I����
-- 0001058 2009/08/28 MOD END --
         AND  xoh.object_status                                       --�����X�e�[�^�X
                IN (cv_object_st_ctrcted, cv_object_st_reles_ctrcted, cv_object_st_mid_term_appl)
         AND  xoh.re_lease_times     = xch.re_lease_times             --�ă��[�X��
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
         AND  xch.lease_class        = flv.lookup_code
         AND  flv.lookup_type        = cv_xxcff1_lease_class_check   -- ���[�X��ʃ`�F�b�N
         AND  flv.attribute7         = gv_lease_class_att7           -- ���[�X���菈��
         AND  flv.language           = ct_language
         AND  flv.enabled_flag       = cv_flg_y
         AND  TO_DATE(gv_period_name,'YYYY-MM') BETWEEN NVL(flv.start_date_active, TO_DATE(gv_period_name,'YYYY-MM'))
                                                AND     NVL(flv.end_date_active  , TO_DATE(gv_period_name,'YYYY-MM'))
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
         FOR UPDATE OF xcl.contract_header_id, xoh.object_code NOWAIT
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
    --�J�[�\�����I�[�v��
    OPEN reles_ob_ctrct_info_cur;
    --�f�[�^�̈ꊇ�擾
    FETCH reles_ob_ctrct_info_cur
    BULK COLLECT INTO  g_lease_end_date_tab               --���[�X�I����
                      ,g_contract_header_id_tab           --�_�����ID
                      ,g_contract_line_id_tab             --�_�񖾍ד���ID
                      ,g_contract_line_num_tab            --�_��}��
                      ,g_first_charge_tab                 --���񌎊z���[�X��_���[�X��
                      ,g_first_tax_charge_tab             --�������Ŋz_���[�X��
                      ,g_first_total_charge_tab           --����v_���[�X��
                      ,g_second_charge_tab                --2��ڈȍ~���z���[�X��_���[�X��
                      ,g_second_tax_charge_tab            --2��ڈȍ~����Ŋz_���[�X��
                      ,g_second_total_charge_tab          --2��ڈȍ~�v_���[�X��
                      ,g_first_deduction_tab              --���񌎊z���[�X��_�T���z
                      ,g_first_tax_deduction_tab          --���񌎊z����Ŋz_�T���z
                      ,g_first_total_deduction_tab        --����v_�T���z
                      ,g_second_deduction_tab             --2��ڈȍ~���z���[�X��_�T���z
                      ,g_second_tax_deduction_tab         --2��ڈȍ~����Ŋz_�T���z
                      ,g_second_total_deduction_tab       --2��ڈȍ~�v_�T���z
                      ,g_gross_charge_tab                 --���z���[�X��_���[�X��
                      ,g_gross_tax_charge_tab             --���z�����_���[�X��
                      ,g_gross_total_charge_tab           --���z�v_���[�X��
                      ,g_gross_deduction_tab              --���z���[�X��_�T���z
                      ,g_gross_tax_deduction_tab          --���z�����_�T���z
                      ,g_gross_total_deduction_tab        --���z�v_�T���z
                      ,g_lease_kind_tab                   --���[�X���
                      ,g_estimated_cash_price_tab         --���ό����w�����z
                      ,g_prsnt_val_discnt_rate_tab        --���݉��l������
                      ,g_present_value_tab                --���݉��l
                      ,g_life_in_months_tab               --�@��ϗp�N��
                      ,g_original_cost_tab                --�擾���z
                      ,g_calc_interested_rate_tab         --�v�Z���q��
                      ,g_object_header_id_tab             --��������ID
                      ,g_asset_category_tab               --���Y���
                      ,g_expiration_date_tab              --������
                      ,g_cancellation_date_tab            --���r����
                      ,g_vd_if_date_tab                   --���[�X�_����A�g��
                      ,g_info_sys_if_date_tab             --���[�X�Ǘ����A�g��
                      ,g_fst_inst_address_tab             --����ݒu�ꏊ
                      ,g_fst_inst_place_tab               --����ݒu��
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
                      ,g_tax_code_tab                     --�ŋ��R�[�h
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
                      ,g_object_code_tab                  --�����R�[�h
                      ,g_lease_class_tab                  --���[�X���
                      ,g_lease_type_tab                   --���[�X�敪
                      ,g_re_lease_times_tab               --�ă��[�X��
                      ,g_po_number_tab                    --�����ԍ�
                      ,g_registration_number_tab          --�o�^�ԍ�
                      ,g_age_type_tab                     --�N��
                      ,g_model_tab                        --�@��
                      ,g_serial_number_tab                --�@��
                      ,g_quantity_tab                     --����
                      ,g_manufacturer_name_tab            --���[�J�[��
                      ,g_department_code_tab              --�Ǘ�����R�[�h
                      ,g_owner_company_tab                --�{�Ё^�H��
                      ,g_installation_address_tab         --���ݒu�ꏊ
                      ,g_installation_place               --���ݒu��
                      ,g_chassis_number_tab               --�ԑ�ԍ�
                      ,g_re_lease_flag_tab                --�ă��[�X�v�t���O
                      ,g_cancellation_type_tab            --���敪
                      ,g_cancellation_date_ob_tab         --���r����
                      ,g_dissolution_date_tab             --���r���L�����Z����
                      ,g_bond_acceptance_flag_tab         --�؏���̃t���O
                      ,g_bond_acceptance_date_tab         --�؏���̓�
                      ,g_expiration_date_ob_tab           --������
                      ,g_object_status_tab                --�����X�e�[�^�X
                      ,g_active_flag_tab                  --�����L���t���O
                      ,g_info_sys_if_date_ob_tab          --���[�X�Ǘ����A�g��
                      ,g_generation_date_tab              --������
                      ,g_customer_code_tab                --�ڋq�R�[�h
    ;
    --�Ώی�����0���̏ꍇ
    IF ( reles_ob_ctrct_info_cur%ROWCOUNT = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff    -- XXCFF
                                                     ,cv_msg_name2      -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_name3      -- �g�[�N��'GET_DATA'
                                                     ,cv_tkn_val2)      -- �i�ă��[�X�v�ہj�����_����
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    ELSE
      --�����Ώی����J�E���^�[�C���N�������g
      gn_reles_nes_target_cnt := g_contract_header_id_tab.COUNT;
    END IF;
--
    --�J�[�\�����N���[�Y
    CLOSE reles_ob_ctrct_info_cur;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      IF ( reles_ob_ctrct_info_cur%ISOPEN ) THEN
        CLOSE reles_ob_ctrct_info_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_name3         -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_name4         -- �g�[�N��'TABLE'
                                                     ,(xxccp_common_pkg.get_msg(cv_msg_kbn_cff       -- 'XXCFF'
                                                                               ,cv_tkn_val3) || ', ' ||
                                                       xxccp_common_pkg.get_msg(cv_msg_kbn_cff       -- 'XXCFF'
                                                                               ,cv_tkn_val6)
                                                      )
                                                    )
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_object_ctrct_info;
--
  /**********************************************************************************
   * Procedure Name   : update_ct_status
   * Description      : �_��X�e�[�^�X�X�V����(A-6)
   ***********************************************************************************/
  PROCEDURE update_ct_status(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_ct_status'; -- �v���O������
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
    IF ( gn_reles_nes_target_cnt <> 0 ) THEN
      --���C�����[�v�A
--
      --1.���[�X�_�񖾍ׂ̌_��X�e�[�^�X�X�V(A-6)
      <<update_loop>> --�_��X�e�[�^�X�X�V���[�v
      FORALL ln_loop_cnt IN g_contract_header_id_tab.FIRST .. g_contract_header_id_tab.LAST
        UPDATE
                xxcff_contract_lines
           SET
                contract_status = DECODE(g_object_status_tab(ln_loop_cnt)
                                           ,cv_object_st_mid_term_appl, cv_ctrct_st_mid_term
                                                                      , cv_ctrct_st_term
                                        )                                   --�_��X�e�[�^�X
               ,expiration_date        = g_lease_end_date_tab(ln_loop_cnt)  --������
               ,last_updated_by        = cn_last_updated_by         --�ŏI�X�V��
               ,last_update_date       = cd_last_update_date        --�ŏI�X�V��
               ,last_update_login      = cn_last_update_login       --�ŏI�X�V���O�C��
               ,request_id             = cn_request_id              --�v��ID
               ,program_application_id = cn_program_application_id  --�ݶ��ĥ��۸��ѥ���ع����ID
               ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
               ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
         WHERE
                contract_line_id = g_contract_line_id_tab(ln_loop_cnt)
        ;
      --�_��X�e�[�^�X�X�V���[�v �I��
--
      --2.���[�X�_�񖾍ח����̗����f�[�^�쐬
--
      --���[�X�_�񖾍ח�����񃌃R�[�h�̐ݒ�(A-6)
      g_ct_lin_his_rec.accounting_date     := LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM'));  --�v���
      g_ct_lin_his_rec.accounting_if_flag  := cv_acct_if_flag_unsent;                        --��vIF�t���O
--
      <<insert_hist_loop>> --���[�X�_�񖾍ח���o�^���[�v(A-6)
      FOR ln_loop_cnt IN g_contract_line_id_tab.FIRST .. g_contract_line_id_tab.LAST LOOP
--
        --���[�X�_�񖾍׏�񃌃R�[�h�̐ݒ�
        g_ct_lin_rec.contract_header_id     := g_contract_header_id_tab(ln_loop_cnt);      --�_�����ID
        g_ct_lin_rec.contract_line_id       := g_contract_line_id_tab(ln_loop_cnt);      --�_�񖾍ד���ID
        g_ct_lin_rec.contract_line_num      := g_contract_line_num_tab(ln_loop_cnt);      --�_��}��
        g_ct_lin_rec.contract_status        := CASE g_object_status_tab(ln_loop_cnt)      --�_��X�e�[�^�X
                                                 WHEN  cv_object_st_mid_term_appl THEN cv_ctrct_st_mid_term
                                                 ELSE                                  cv_ctrct_st_term
                                               END;
        g_ct_lin_rec.first_charge           := g_first_charge_tab(ln_loop_cnt);          --���񌎊z���[�X��_���[�X��
        g_ct_lin_rec.first_tax_charge       := g_first_tax_charge_tab(ln_loop_cnt);      --�������Ŋz_���[�X��
        g_ct_lin_rec.first_total_charge     := g_first_total_charge_tab(ln_loop_cnt);    --����v_���[�X��
        g_ct_lin_rec.second_charge          := g_second_charge_tab(ln_loop_cnt);         --2��ڈȍ~���z���[�X��_���[�X��
        g_ct_lin_rec.second_tax_charge      := g_second_tax_charge_tab(ln_loop_cnt);     --2��ڈȍ~����Ŋz_���[�X��
        g_ct_lin_rec.second_total_charge    := g_second_total_charge_tab(ln_loop_cnt);   --2��ڈȍ~�v_���[�X��
        g_ct_lin_rec.first_deduction        := g_first_deduction_tab(ln_loop_cnt);       --���񌎊z���[�X��_�T���z
        g_ct_lin_rec.first_tax_deduction    := g_first_tax_deduction_tab(ln_loop_cnt);   --���񌎊z����Ŋz_�T���z
        g_ct_lin_rec.first_total_deduction  := g_first_total_deduction_tab(ln_loop_cnt); --����v_�T���z
        g_ct_lin_rec.second_deduction       := g_second_deduction_tab(ln_loop_cnt);      --2��ڈȍ~���z���[�X��_�T���z
        g_ct_lin_rec.second_tax_deduction   := g_second_tax_deduction_tab(ln_loop_cnt);  --2��ڈȍ~����Ŋz_�T���z
        g_ct_lin_rec.second_total_deduction := g_second_total_deduction_tab(ln_loop_cnt);      --2��ڈȍ~�v_�T���z
        g_ct_lin_rec.gross_charge           := g_gross_charge_tab(ln_loop_cnt);          --���z���[�X��_���[�X��
        g_ct_lin_rec.gross_tax_charge       := g_gross_tax_charge_tab(ln_loop_cnt);      --���z�����_���[�X��
        g_ct_lin_rec.gross_total_charge     := g_gross_total_charge_tab(ln_loop_cnt);    --���z�v_���[�X��
        g_ct_lin_rec.gross_deduction        := g_gross_deduction_tab(ln_loop_cnt);       --���z���[�X��_�T���z
        g_ct_lin_rec.gross_tax_deduction    := g_gross_tax_deduction_tab(ln_loop_cnt);   --���z�����_�T���z
        g_ct_lin_rec.gross_total_deduction  := g_gross_total_deduction_tab(ln_loop_cnt); --���z�v_�T���z
        g_ct_lin_rec.lease_kind             := g_lease_kind_tab(ln_loop_cnt);            --���[�X���
        g_ct_lin_rec.estimated_cash_price   := g_estimated_cash_price_tab(ln_loop_cnt);  --���ό����w�����z
        g_ct_lin_rec.present_value_discount_rate := g_prsnt_val_discnt_rate_tab(ln_loop_cnt);  --���݉��l������
        g_ct_lin_rec.present_value          := g_present_value_tab(ln_loop_cnt);         --���݉��l
        g_ct_lin_rec.life_in_months         := g_life_in_months_tab(ln_loop_cnt);        --�@��ϗp�N��
        g_ct_lin_rec.original_cost          := g_original_cost_tab(ln_loop_cnt);         --�擾���z
        g_ct_lin_rec.calc_interested_rate   := g_calc_interested_rate_tab(ln_loop_cnt);  --�v�Z���q��
        g_ct_lin_rec.object_header_id       := g_object_header_id_tab(ln_loop_cnt);      --��������ID
        g_ct_lin_rec.asset_category         := g_asset_category_tab(ln_loop_cnt);        --���Y���
        g_ct_lin_rec.expiration_date        := g_lease_end_date_tab(ln_loop_cnt);        --������
        g_ct_lin_rec.cancellation_date      := g_cancellation_date_tab(ln_loop_cnt);     --���r����
        g_ct_lin_rec.vd_if_date             := g_vd_if_date_tab(ln_loop_cnt);            --���[�X�_����A�g��
        g_ct_lin_rec.info_sys_if_date       := g_info_sys_if_date_tab(ln_loop_cnt);      --���[�X�Ǘ����A�g��
        g_ct_lin_rec.first_installation_address  := g_fst_inst_address_tab(ln_loop_cnt); --����ݒu�ꏊ
        g_ct_lin_rec.first_installation_place    := g_fst_inst_place_tab(ln_loop_cnt);   --����ݒu��
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
        g_ct_lin_rec.tax_code               := g_tax_code_tab(ln_loop_cnt);              --�ŋ��R�[�h
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
        -- �ȉ��AWHO�J�������
        g_ct_lin_rec.created_by             := cn_created_by;              --�쐬��
        g_ct_lin_rec.creation_date          := cd_creation_date;           --�쐬��
        g_ct_lin_rec.last_updated_by        := cn_last_updated_by;         --�ŏI�X�V��
        g_ct_lin_rec.last_update_date       := cd_last_update_date;        --�ŏI�X�V��
        g_ct_lin_rec.last_update_login      := cn_last_update_login;       --�ŏI�X�V���O�C��
        g_ct_lin_rec.request_id             := cn_request_id;              --�v��ID
        g_ct_lin_rec.program_application_id := cn_program_application_id;  --�ݶ��ĥ��۸��ѥ���ع����ID
        g_ct_lin_rec.program_id             := cn_program_id;              --�R���J�����g��v���O����ID
        g_ct_lin_rec.program_update_date    := cd_program_update_date;     --�v���O�����X�V��
--
        --���ʊ֐� ���[�X�_�񗚗�o�^ �̌ďo(A-6)
        xxcff_common4_pkg.insert_co_his(
          io_contract_lin_data_rec  => g_ct_lin_rec      -- �_�񖾍׏��
         ,io_contract_his_data_rec  => g_ct_lin_his_rec  -- �_�񗚗����
         ,ov_errbuf                 => lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode                => lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg                 => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
        ELSE
          gn_reles_nes_normal_cnt := ln_loop_cnt;
        END IF;
--
      END LOOP insert_hist_loop; --���[�X�_�񖾍ח���o�^���[�v�I��(A-6)
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
  END update_ct_status;
--
  /**********************************************************************************
   * Procedure Name   : update_ob_status
   * Description      : �����X�e�[�^�X�X�V����(A-7)
   ***********************************************************************************/
  PROCEDURE update_ob_status(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_ob_status'; -- �v���O������
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
    IF ( gn_reles_nes_target_cnt <> 0 ) THEN
--
      --1.���[�X�����̕����X�e�[�^�X�X�V
      <<update_loop>> --���[�X�����̕����X�e�[�^�X�X�V���[�v
      FORALL ln_loop_cnt IN g_object_header_id_tab.FIRST .. g_object_header_id_tab.LAST
        UPDATE
                xxcff_object_headers
           SET
                object_status   = CASE g_object_status_tab(ln_loop_cnt)         --�����X�e�[�^�X
                                    WHEN  cv_object_st_mid_term_appl THEN
                                      cv_object_st_mid_term
                                    ELSE
                                      DECODE(g_re_lease_flag_tab(ln_loop_cnt)
                                               ,cv_reles_flag_nes      , cv_object_st_reles_wait
                                               ,cv_reles_flag_unnes    , cv_object_st_term
                                            )
                                  END
               ,lease_type      = CASE                                          --���[�X�敪
                                    WHEN  (g_object_status_tab(ln_loop_cnt) <> cv_object_st_mid_term_appl)
                                             AND g_re_lease_flag_tab(ln_loop_cnt) = cv_reles_flag_nes THEN
                                      cv_les_sec_reles
                                    ELSE
                                      g_lease_type_tab(ln_loop_cnt)
                                  END
               ,expiration_date = CASE
                                    WHEN  (g_object_status_tab(ln_loop_cnt) <> cv_object_st_mid_term_appl)
                                             AND g_re_lease_flag_tab(ln_loop_cnt) = cv_reles_flag_nes THEN
                                      g_expiration_date_ob_tab(ln_loop_cnt)
                                    ELSE
                                      g_lease_end_date_tab(ln_loop_cnt)         --������ 
                                  END
               ,re_lease_times  = CASE                                          --�ă��[�X��
                                    WHEN (g_object_status_tab(ln_loop_cnt) <> cv_object_st_mid_term_appl)
                                             AND g_re_lease_flag_tab(ln_loop_cnt) = cv_reles_flag_nes THEN
                                      (g_re_lease_times_tab(ln_loop_cnt) + 1)
                                    ELSE
                                      g_re_lease_times_tab(ln_loop_cnt)
                                  END
               ,last_updated_by        = cn_last_updated_by         --�ŏI�X�V��
               ,last_update_date       = cd_last_update_date        --�ŏI�X�V��
               ,last_update_login      = cn_last_update_login       --�ŏI�X�V���O�C��
               ,request_id             = cn_request_id              --�v��ID
               ,program_application_id = cn_program_application_id  --�ݶ��ĥ��۸��ѥ���ع����ID
               ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
               ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
         WHERE
                object_header_id = g_object_header_id_tab(ln_loop_cnt)
        ;
      --���[�X�����̕����X�e�[�^�X�X�V���[�v �I��
--
      --2.���[�X���������̗����f�[�^�쐬
--
      <<insert_hist_loop>> --���[�X��������o�^���[�v
      FOR ln_loop_cnt IN g_object_header_id_tab.FIRST .. g_object_header_id_tab.LAST LOOP
--
        --���[�X������񃌃R�[�h�̐ݒ�
        g_ob_his_rec.object_header_id       := g_object_header_id_tab(ln_loop_cnt);      --��������ID
        g_ob_his_rec.object_code            := g_object_code_tab(ln_loop_cnt);           --�����R�[�h
        g_ob_his_rec.lease_class            := g_lease_class_tab(ln_loop_cnt);           --���[�X���
        g_ob_his_rec.lease_type             := CASE                                      --���[�X�敪
                                                 WHEN  (g_object_status_tab(ln_loop_cnt) <> cv_object_st_mid_term_appl)
                                                           AND g_re_lease_flag_tab(ln_loop_cnt) = cv_reles_flag_nes THEN
                                                   cv_les_sec_reles
                                                 ELSE
                                                   g_lease_type_tab(ln_loop_cnt)
                                               END;
        g_ob_his_rec.re_lease_times         := CASE                                      --�ă��[�X��
                                                 WHEN (g_object_status_tab(ln_loop_cnt) <> cv_object_st_mid_term_appl)
                                                          AND g_re_lease_flag_tab(ln_loop_cnt) = cv_reles_flag_nes THEN
                                                   (g_re_lease_times_tab(ln_loop_cnt) + 1)
                                                 ELSE
                                                   g_re_lease_times_tab(ln_loop_cnt)
                                               END;
        g_ob_his_rec.po_number              := g_po_number_tab(ln_loop_cnt);             --�����ԍ�
        g_ob_his_rec.registration_number    := g_registration_number_tab(ln_loop_cnt);   --�o�^�ԍ�
        g_ob_his_rec.age_type               := g_age_type_tab(ln_loop_cnt);              --�N��
        g_ob_his_rec.model                  := g_model_tab(ln_loop_cnt);                 --�@��
        g_ob_his_rec.serial_number          := g_serial_number_tab(ln_loop_cnt);         --�@��
        g_ob_his_rec.quantity               := g_quantity_tab(ln_loop_cnt);              --����
        g_ob_his_rec.manufacturer_name      := g_manufacturer_name_tab(ln_loop_cnt);     --���[�J�[��
        g_ob_his_rec.department_code        := g_department_code_tab(ln_loop_cnt);       --�Ǘ�����R�[�h
        g_ob_his_rec.owner_company          := g_owner_company_tab(ln_loop_cnt);         --�{�Ё^�H��
        g_ob_his_rec.installation_address   := g_installation_address_tab(ln_loop_cnt);  --���ݒu�ꏊ
        g_ob_his_rec.installation_place     := g_installation_place(ln_loop_cnt);        --���ݒu��
        g_ob_his_rec.chassis_number         := g_chassis_number_tab(ln_loop_cnt);        --�ԑ�ԍ�
        g_ob_his_rec.re_lease_flag          := g_re_lease_flag_tab(ln_loop_cnt);         --�ă��[�X�v�t���O
        g_ob_his_rec.cancellation_type      := g_cancellation_type_tab(ln_loop_cnt);     --���敪
        g_ob_his_rec.cancellation_date      := g_cancellation_date_ob_tab(ln_loop_cnt);  --���r����
        g_ob_his_rec.dissolution_date       := g_dissolution_date_tab(ln_loop_cnt);      --���r���L�����Z����
        g_ob_his_rec.bond_acceptance_flag   := g_bond_acceptance_flag_tab(ln_loop_cnt);  --�؏���̃t���O
        g_ob_his_rec.bond_acceptance_date   := g_bond_acceptance_date_tab(ln_loop_cnt);  --�؏���̓�
        g_ob_his_rec.expiration_date        := CASE
                                                 WHEN  (g_object_status_tab(ln_loop_cnt) <> cv_object_st_mid_term_appl)
                                                           AND g_re_lease_flag_tab(ln_loop_cnt) = cv_reles_flag_nes THEN
                                                   g_expiration_date_ob_tab(ln_loop_cnt)
                                                 ELSE
                                                   g_lease_end_date_tab(ln_loop_cnt)     --������ 
                                               END;
        g_ob_his_rec.object_status          := CASE g_object_status_tab(ln_loop_cnt)     --�����X�e�[�^�X
                                                 WHEN  cv_object_st_mid_term_appl THEN
                                                   cv_object_st_mid_term
                                                 ELSE
                                                   CASE g_re_lease_flag_tab(ln_loop_cnt)
                                                     WHEN  cv_reles_flag_nes    THEN  cv_object_st_reles_wait
                                                     WHEN  cv_reles_flag_unnes  THEN  cv_object_st_term
                                                   END
                                               END;
        g_ob_his_rec.active_flag            := g_active_flag_tab(ln_loop_cnt);           --�����L���t���O
        g_ob_his_rec.info_sys_if_date       := g_info_sys_if_date_ob_tab(ln_loop_cnt);   --���[�X�Ǘ����A�g��
        g_ob_his_rec.generation_date        := g_generation_date_tab(ln_loop_cnt);       --������
        g_ob_his_rec.customer_code          := g_customer_code_tab(ln_loop_cnt);         --�ڋq�R�[�h
        -- �ȉ��AWHO�J�������
        g_ob_his_rec.created_by             := cn_created_by;              --�쐬��
        g_ob_his_rec.creation_date          := cd_creation_date;           --�쐬��
        g_ob_his_rec.last_updated_by        := cn_last_updated_by;         --�ŏI�X�V��
        g_ob_his_rec.last_update_date       := cd_last_update_date;        --�ŏI�X�V��
        g_ob_his_rec.last_update_login      := cn_last_update_login;       --�ŏI�X�V���O�C��
        g_ob_his_rec.request_id             := cn_request_id;              --�v��ID
        g_ob_his_rec.program_application_id := cn_program_application_id;  --�ݶ��ĥ��۸��ѥ���ع����ID
        g_ob_his_rec.program_id             := cn_program_id;              --�R���J�����g��v���O����ID
        g_ob_his_rec.program_update_date    := cd_program_update_date;     --�v���O�����X�V��
--
        --���ʊ֐� ���[�X��������o�^ �̌ďo
        xxcff_common3_pkg.insert_ob_his(
          io_object_data_rec  => g_ob_his_rec  -- �������
         ,ov_errbuf           => lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode          => lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg           => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
        ELSE
          gn_reles_nes_normal_cnt := ln_loop_cnt;
        END IF;
--
      END LOOP insert_hist_loop; --���[�X�_�񖾍ח���o�^���[�v�I��
      --���C�����[�v�A �I��
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
  END update_ob_status;
--
  /**********************************************************************************
   * Procedure Name   : update_payplan_acct_flag
   * Description      : �x���v��̉�vIF�t���O(�ƍ��s��)�X�V����(A-8)
   ***********************************************************************************/
  PROCEDURE update_payplan_acct_flag(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_payplan_acct_flag'; -- �v���O������
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
    --���[�X�x���v�惍�b�N�ׂ̈̃J�[�\��
    CURSOR lock_pay_plan_cur
    IS
    SELECT
-- 2018/09/07 Ver.1.6 Y.Shoji MOD Start
--            xpp.contract_line_id
             /*+
              LEADING(XPP)
              USE_NL(XPP XCH)
              INDEX(XCH XXCFF_CONTRACT_HEADERS_PK)
             */
            xpp.contract_line_id  contract_line_id
-- 2018/09/07 Ver.1.6 Y.Shoji MOD End
      FROM
            xxcff_pay_planning  xpp  --���[�X�x���v��
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
           ,xxcff_contract_headers  xch --���[�X�_��
           ,fnd_lookup_values       flv -- �Q�ƕ\
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
     WHERE
            xpp.period_name        = gv_period_name
       AND  xpp.payment_match_flag = cv_paymtch_flag_unadmin
       AND  xpp.accounting_if_flag = cv_acct_if_flag_unsent  --��vIF�t���O
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
       AND  xpp.contract_header_id = xch.contract_header_id  --�_�����ID
       AND  xch.lease_class        = flv.lookup_code
       AND  flv.lookup_type        = cv_xxcff1_lease_class_check   -- ���[�X��ʃ`�F�b�N
       AND  flv.attribute7         = gv_lease_class_att7           -- ���[�X���菈��
       AND  flv.language           = ct_language
       AND  flv.enabled_flag       = cv_flg_y
       AND  TO_DATE(gv_period_name,'YYYY-MM') BETWEEN NVL(flv.start_date_active, TO_DATE(gv_period_name,'YYYY-MM'))
                                              AND     NVL(flv.end_date_active  , TO_DATE(gv_period_name,'YYYY-MM'))
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
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
    --1.���[�X�x���v��e�[�u���̃��b�N���擾
    OPEN lock_pay_plan_cur;
    FETCH lock_pay_plan_cur
    BULK COLLECT INTO g_contract_line_id_tab
    ;
    gn_acct_flag_target_cnt := lock_pay_plan_cur%ROWCOUNT;
    CLOSE lock_pay_plan_cur;
--
    --2.���[�X�x���v��̉�vIF�t���O���X�V
-- 2018/09/07 Ver.1.6 Y.Shoji MOD Start
--    UPDATE
--            xxcff_pay_planning
--       SET
--            accounting_if_flag     = cv_acct_if_flag_dis_pymh
--           ,last_updated_by        = cn_last_updated_by         --�ŏI�X�V��
--           ,last_update_date       = cd_last_update_date        --�ŏI�X�V��
--           ,last_update_login      = cn_last_update_login       --�ŏI�X�V���O�C��
--           ,request_id             = cn_request_id              --�v��ID
--           ,program_application_id = cn_program_application_id  --�ݶ��ĥ��۸��ѥ���ع����ID
--           ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
--           ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
--     WHERE
--            period_name            = gv_period_name
--       AND  payment_match_flag     = cv_paymtch_flag_unadmin
--       AND  accounting_if_flag     = cv_acct_if_flag_unsent  --��vIF�t���O
--    ;
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
      UPDATE
              xxcff_pay_planning
         SET
              accounting_if_flag     = cv_acct_if_flag_dis_pymh
             ,last_updated_by        = cn_last_updated_by         --�ŏI�X�V��
             ,last_update_date       = cd_last_update_date        --�ŏI�X�V��
             ,last_update_login      = cn_last_update_login       --�ŏI�X�V���O�C��
             ,request_id             = cn_request_id              --�v��ID
             ,program_application_id = cn_program_application_id  --�ݶ��ĥ��۸��ѥ���ع����ID
             ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
             ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
       WHERE
              period_name            = gv_period_name
         AND  payment_match_flag     = cv_paymtch_flag_unadmin
         AND  accounting_if_flag     = cv_acct_if_flag_unsent  --��vIF�t���O
         AND  contract_line_id       = g_contract_line_id_tab(ln_loop_cnt)
      ;
-- 2018/09/07 Ver.1.6 Y.Shoji MOD End
--
    gn_acct_flag_normal_cnt := gn_acct_flag_target_cnt;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      IF ( lock_pay_plan_cur%ISOPEN ) THEN
        CLOSE lock_pay_plan_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_name3         -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_name4         -- �g�[�N��'TABLE'
                                                     ,cv_tkn_val4)         -- ���[�X�x���v��
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_payplan_acct_flag;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN   VARCHAR2,     -- 1.��v���Ԗ�
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
    iv_book_type_code IN   VARCHAR2,   -- 2.�䒠��
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
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
    gn_ctrcted_les_target_cnt   := 0;
    gn_ctrcted_les_normal_cnt   := 0;
    gn_ctrcted_les_error_cnt    := 0;
    gn_reles_nes_target_cnt     := 0;
    gn_reles_nes_normal_cnt     := 0;
    gn_reles_nes_error_cnt      := 0;
    gn_acct_flag_target_cnt     := 0;
    gn_acct_flag_normal_cnt     := 0;
    gn_acct_flag_error_cnt      := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    -- ============================================
    -- A-1�D��������
    -- ============================================
--
    -- ���ʏ�������(�����l���̎擾)�̌Ăяo��
    init(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2�D��v���ԃ`�F�b�N
    -- ============================================
--
    chk_period_name(
       iv_period_name    -- 1.��v���Ԗ�
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
      ,iv_book_type_code -- 2.�䒠��
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
    -- ============================================
    -- A-10�D�v���t�@�C���l�擾
    -- ============================================
--
    get_profile_values(
       iv_book_type_code -- 1.�䒠��
      ,lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
    -- ============================================
    -- A-3�D�_��(�ă��[�X�_��)�ς݃��[�X�_���񒊏o
    -- ============================================
--
    get_ctrcted_les_info(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4�D�_��X�e�[�^�X�X�V
    -- ============================================
--
    update_cted_ct_status(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-5�D�i�ă��[�X�v�ہj�����_���񒊏o
    -- ============================================
--
    get_object_ctrct_info(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-6�D�_��X�e�[�^�X�X�V
    -- ============================================
--
    update_ct_status(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-7�D�����X�e�[�^�X�X�V
    -- ============================================
--
    update_ob_status(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-8�D�x���v��̉�vIF�t���O(�ƍ��s��)�X�V����
    -- ============================================
--
    update_payplan_acct_flag(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
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
-- 2018/09/07 Ver.1.6 Y.Shoji MOD Start
--    iv_period_name   IN    VARCHAR2         -- 1.��v���Ԗ�
    iv_period_name    IN   VARCHAR2,        -- 1.��v���Ԗ�
    iv_book_type_code IN   VARCHAR2         -- 2.�䒠��
-- 2018/09/07 Ver.1.6 Y.Shoji MOD End
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
       iv_period_name     -- 1.��v���Ԗ�
-- 2018/09/07 Ver.1.6 Y.Shoji ADD Start
      ,iv_book_type_code  -- 2.�䒠��
-- 2018/09/07 Ver.1.6 Y.Shoji ADD End
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
    -- A-15�D�I������
    -- ============================================
--
    --���ʂ̃��O���b�Z�[�W�̏o�͊J�n
    -- ===============================================
    -- �G���[���̏o�͌����ݒ�
    -- ===============================================
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���������Ƀ[�������Z�b�g����
      gn_ctrcted_les_normal_cnt   := 0;
      gn_reles_nes_normal_cnt     := 0;
      gn_acct_flag_normal_cnt     := 0;
--
      -- �G���[�������Z�b�g����
      gn_ctrcted_les_error_cnt    := gn_ctrcted_les_target_cnt;
      gn_reles_nes_error_cnt      := gn_reles_nes_target_cnt;
      gn_acct_flag_error_cnt      := gn_acct_flag_target_cnt;
    END IF;
--
    -- ===============================================================
    -- �_��ς݃��[�X�_����X�e�[�^�X�X�V�����ɂ����錏���o��
    -- ===============================================================
    --�_��ς݃��[�X�_��X�e�[�^�X�X�V�������b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_name5
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ctrcted_les_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ctrcted_les_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ctrcted_les_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
--
    -- ===============================================================
    -- �ă��[�X�v�����̃X�e�[�^�X�X�V�����ɂ����錏���o��
    -- ===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�ă��[�X�v�����̃X�e�[�^�X�X�V�������b�Z�[�W
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_name6
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_reles_nes_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_reles_nes_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_reles_nes_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
--
    -- ===============================================================
    -- �ƍ��s�X�V�����ɂ����錏���o��
    -- ===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --�ƍ��s�X�V�������b�Z�[�W
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_name7
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_acct_flag_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_acct_flag_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --���ʂ̃��b�Z�[�W
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_acct_flag_error_cnt)
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
    --
    --�I�����b�Z�[�W
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
       which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
      ,buff   => gv_out_msg
    );
    --
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
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
END XXCFF013A19C;
/
