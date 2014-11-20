CREATE OR REPLACE PACKAGE BODY XXCFF013A20C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF013A20C(body)
 * Description      : FA�A�h�I��IF
 * MD.050           : MD050_CFF_013_A20_FA�A�h�I��IF
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                         ��������                             (A-1)
 *  get_profile_values           �v���t�@�C���l�擾                   (A-2)
 *  get_period                   ��v���ԃ`�F�b�N                     (A-3)
 *  get_les_trn_add_data         ���[�X���(�ǉ�)�o�^�f�[�^���o       (A-4)
 *  proc_les_trn_add_data        ���[�X���(�ǉ�)�f�[�^����           (A-5)�`(A-10)
 *  get_deprn_method             ���p���@�擾                         (A-8)
 *  insert_les_trn_add_data      ���[�X���(�ǉ�)�o�^                 (A-9)
 *  update_ctrct_line_acct_flag  ���[�X�_�񖾍ח��� ��vIF�t���O�X�V  (A-10)
 *  get_les_trn_trnsf_data       ���[�X���(�U��)�o�^�f�[�^���o       (A-11)
 *  proc_les_trn_trnsf_data      ���[�X���(�U��)�f�[�^����           (A-12)�`(A-16)
 *  lock_trnsf_data              ���[�X���(�U��)�f�[�^���b�N����     (A-12)
 *  insert_les_trn_trnsf_data    ���[�X���(�U��)�o�^                 (A-15)
 *  update_trnsf_data_acct_flag  ���[�X�_�񖾍ח��� ��vIF�t���O�X�V  (A-16)
 *  get_deprn_ccid               �������p���CCID�擾               (A-7,A-14)
 *  get_les_trn_retire_data      ���[�X���(���)�o�^�f�[�^���o       (A-17)
 *  insert_les_trn_ritire_data   ���[�X���(���)�o�^                 (A-18)
 *  update_ritire_data_acct_flag ���[�X�_�񖾍ח��� ��vIF�t���O�X�V  (A-19)
 *  get_les_trns_data            FAOIF�o�^�f�[�^���o                  (A-20)
 *  insert_add_oif               �ǉ�OIF�o�^                          (A-21)
 *  insert_trnsf_oif             �U��OIF�o�^                          (A-22)
 *  insert_retire_oif            ���E���pOIF�o�^                      (A-23)
 *  update_les_trns_fa_if_flag   ���[�X��� FA�A�g�t���O�X�V          (A-24)
 *  submain                      ���C�������v���V�[�W��
 *  main                         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   SCS�n�ӊw        �V�K�쐬
 *  2008/02/23    1.1   SCS�n�ӊw        [��QCFF_047]�����p�f�[�^���o�����s��Ή�
 *  2009/04/23    1.2   SCS�E��S��      [��QT1_0759]
 *                                       �@���Y�J�e�S��CCID�擾�����ɂ�����ϗp�N���ɁA
 *                                         ���[�X���ԁi���[�X�_��̎x����/12�j��ݒ��ݒ肷��B
 *                                       �A���p���@���擾���ɁA���Y�J�e�S�����p��e�[�u���̌v�Z����
 *                                         ���擾���A�ǉ�OIF�̌v�Z�����֐ݒ肷��B
 *  2009/05/19    1.3   SCS�E��S��      [��QT1_0893]
 *                                       �@���[�X�@�l�ő䒠�Ō������p�̌v�Z���s���Ȃ��B
 *  2009/05/29    1.4   SCS���S��      [��QT1_0893]�ǋL
 *                                       �@���[�X���(�ǉ�)�o�^���̎��Ƌ��p����
 *                                         ���[�X�J�n����ݒ肷��B
 *  2009/06/16    1.5   SCS�����S��      [��QT1_1428]
 *                                       �@���Y�J�e�S��CCID�擾���W�b�N��
 *                                       �p�����[�^�F���Y����̒l��NULL�l�Œ�ɕύX
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
  --*** ��v���ԃ`�F�b�N�G���[
  chk_period_expt           EXCEPTION;
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFF013A20C'; -- �p�b�P�[�W��
--
  -- ***�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cmn   CONSTANT VARCHAR2(5) := 'XXCMN';
  cv_msg_kbn_ccp   CONSTANT VARCHAR2(5) := 'XXCCP';
  cv_msg_kbn_cff   CONSTANT VARCHAR2(5) := 'XXCFF';
--
  -- ***���b�Z�[�W��(�{��)
  cv_msg_013a20_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; --�v���t�@�C���擾�G���[
  cv_msg_013a20_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; --��v���ԃ`�F�b�N�G���[
  cv_msg_013a20_m_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; --���b�N�G���[
  cv_msg_013a20_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00101'; --���p���@�擾�G���[
  cv_msg_013a20_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00153'; --���[�X���(�ǉ�)�쐬���b�Z�[�W
  cv_msg_013a20_m_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00154'; --���[�X���(�U��)�쐬���b�Z�[�W
  cv_msg_013a20_m_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00155'; --���[�X���(���)�쐬���b�Z�[�W
  cv_msg_013a20_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00156'; --FAOIF�쐬���b�Z�[�W
  cv_msg_013a20_m_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; --�擾�Ώۃf�[�^����
  
--
  -- ***���b�Z�[�W��(�g�[�N��)
  cv_msg_013a20_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50076'; --XXCFF:��ЃR�[�h_�{��
  cv_msg_013a20_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50077'; --XXCFF:��ЃR�[�h_���ǉ�v
  cv_msg_013a20_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50078'; --XXCFF:����R�[�h_��������
  cv_msg_013a20_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50079'; --XXCFF:�ڋq�R�[�h_��`�Ȃ�
  cv_msg_013a20_t_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50080'; --XXCFF:��ƃR�[�h_��`�Ȃ�
  cv_msg_013a20_t_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50081'; --XXCFF:�\��1�R�[�h_��`�Ȃ�
  cv_msg_013a20_t_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50082'; --XXCFF:�\��2�R�[�h_��`�Ȃ�
  cv_msg_013a20_t_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50083'; --XXCFF:���Y�J�e�S��_���p���@
  cv_msg_013a20_t_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50084'; --XXCFF:�\���n_�\���Ȃ�
  cv_msg_013a20_t_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50085'; --XXCFF:���Ə�_��`�Ȃ�
  cv_msg_013a20_t_020 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50086'; --XXCFF:�ꏊ_��`�Ȃ�
  cv_msg_013a20_t_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50087'; --XXCFF: �����@_����
  cv_msg_013a20_t_022 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50093'; --XXCFF: �����@_����
  cv_msg_013a20_t_023 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50094'; --���[�X�_�񖾍ח���
  cv_msg_013a20_t_024 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50095'; --XXCFF: �{�ЍH��敪_�{��
  cv_msg_013a20_t_025 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50096'; --XXCFF: �{�ЍH��敪_�H��
  cv_msg_013a20_t_026 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50097'; --���p���@
  cv_msg_013a20_t_027 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50098'; --�_�񖾍ד���ID
  cv_msg_013a20_t_028 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50099'; --���Y�J�e�S��CCID
  cv_msg_013a20_t_029 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50023'; --���[�X��������
  cv_msg_013a20_t_030 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50112'; --���[�X���
  cv_msg_013a20_t_031 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50142'; --���[�X����i�ǉ��j���
  cv_msg_013a20_t_032 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50143'; --���[�X����i�U�ցj���
  cv_msg_013a20_t_033 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50144'; --���[�X����i���j���
  cv_msg_013a20_t_034 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50145'; --FAOIF�A�g���
--
  -- ***�g�[�N����
  -- �v���t�@�C����
  cv_tkn_prof     CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_bk_type  CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period   CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_table    CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_info     CONSTANT VARCHAR2(20) := 'INFO';
  cv_tkn_get_data CONSTANT VARCHAR2(20) := 'GET_DATA';
--
  -- ***�v���t�@�C��
--
  -- ��ЃR�[�h_�{��
  cv_comp_cd_itoen        CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_ITOEN';
  -- ��ЃR�[�h_���ǉ�v
  cv_comp_cd_sagara       CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_SAGARA';
  -- ����R�[�h_��������
  cv_dep_cd_chosei        CONSTANT VARCHAR2(30) := 'XXCFF1_DEP_CD_CHOSEI';
  -- �ڋq�R�[�h_��`�Ȃ�
  cv_ptnr_cd_dammy        CONSTANT VARCHAR2(30) := 'XXCFF1_PTNR_CD_DAMMY';
  -- ��ƃR�[�h_��`�Ȃ�
  cv_busi_cd_dammy        CONSTANT VARCHAR2(30) := 'XXCFF1_BUSI_CD_DAMMY';
  -- �\��1�R�[�h_��`�Ȃ�
  cv_project_dammy        CONSTANT VARCHAR2(30) := 'XXCFF1_PROJECT_DAMMY';
  -- �\��2�R�[�h_��`�Ȃ�
  cv_future_dammy         CONSTANT VARCHAR2(30) := 'XXCFF1_FUTURE_DAMMY';
  -- ���Y�J�e�S��_���p���@
  cv_cat_dprn_lease       CONSTANT VARCHAR2(30) := 'XXCFF1_CAT_DPRN_LEASE';
  -- �\���n_�\���Ȃ�
  cv_dclr_place_no_report CONSTANT VARCHAR2(30) := 'XXCFF1_DCLR_PLACE_NO_REPORT';
  -- ���Ə�_��`�Ȃ�
  cv_mng_place_dammy      CONSTANT VARCHAR2(30) := 'XXCFF1_MNG_PLACE_DAMMY';
  -- �ꏊ_��`�Ȃ�
  cv_place_dammy          CONSTANT VARCHAR2(30) := 'XXCFF1_PLACE_DAMMY';
  -- �����@_����
  cv_prt_conv_cd_st       CONSTANT VARCHAR2(30) := 'XXCFF1_PRT_CONV_CD_ST';
  -- �����@_����
  cv_prt_conv_cd_ed       CONSTANT VARCHAR2(30) := 'XXCFF1_PRT_CONV_CD_ED';
  -- �{�ЍH��敪_�{��
  cv_own_comp_itoen       CONSTANT VARCHAR2(30) := 'XXCFF1_OWN_COMP_ITOEN';
  -- �{�ЍH��敪_�H��
  cv_own_comp_sagara      CONSTANT VARCHAR2(30) := 'XXCFF1_OWN_COMP_SAGARA';
--
  -- ***�t�@�C���o��
--
  -- ���b�Z�[�W�o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';
  -- ���O�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';
--
  -- ***�_��X�e�[�^�X
  -- �_��
  cv_ctrt_ctrt           CONSTANT VARCHAR2(3) := '202';
  -- ���ύX
  cv_ctrt_info_change    CONSTANT VARCHAR2(3) := '209';
  -- ����
  cv_ctrt_manryo         CONSTANT VARCHAR2(3) := '204';
  -- ���r���(���ȓs��)
  cv_ctrt_cancel_jiko    CONSTANT VARCHAR2(3) := '206';
  -- ���r���(�ی��Ή�)
  cv_ctrt_cancel_hoken   CONSTANT VARCHAR2(3) := '207';
  -- ���r���(����)
  cv_ctrt_cancel_manryo  CONSTANT VARCHAR2(3) := '208';
--
  -- ***�����X�e�[�^�X
  -- �ړ�
  cv_obj_move        CONSTANT VARCHAR2(3) := '105';
--
  -- ***���[�X���
  cv_lease_kind_fin  CONSTANT VARCHAR2(1) := '0';  -- Fin���[�X
  cv_lease_kind_lfin CONSTANT VARCHAR2(1) := '2';  -- ��Fin���[�X
--
  -- ***��vIF�t���O
  cv_if_yet  CONSTANT VARCHAR2(1) := '1';  -- �����M
  cv_if_aft  CONSTANT VARCHAR2(1) := '2';  -- �A�g��
--
  -- ***���[�X�敪
  cv_original  CONSTANT VARCHAR2(1) := '1';  -- ���_��
--
-- T1_0759 2009/04/23 ADD START --
  -- ***����
  cv_months  CONSTANT NUMBER(2) := 12;  
-- T1_0759 2009/04/23 ADD END   --
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  TYPE g_deprn_run_ttype             IS TABLE OF fa_deprn_periods.deprn_run%TYPE INDEX BY PLS_INTEGER;
  TYPE g_book_type_code_ttype        IS TABLE OF fa_deprn_periods.book_type_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_header_id_ttype    IS TABLE OF xxcff_contract_histories.contract_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_id_ttype      IS TABLE OF xxcff_contract_histories.contract_line_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_header_id_ttype      IS TABLE OF xxcff_contract_histories.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_history_num_ttype           IS TABLE OF xxcff_contract_histories.history_num%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_class_ttype           IS TABLE OF xxcff_contract_headers.lease_class%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_kind_ttype            IS TABLE OF xxcff_contract_histories.lease_kind%TYPE INDEX BY PLS_INTEGER;
  TYPE g_asset_category_ttype        IS TABLE OF xxcff_contract_histories.asset_category%TYPE INDEX BY PLS_INTEGER;
  TYPE g_comments_ttype              IS TABLE OF xxcff_contract_headers.comments%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_years_ttype         IS TABLE OF xxcff_contract_headers.payment_years%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_date_ttype         IS TABLE OF xxcff_contract_headers.contract_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_original_cost_ttype         IS TABLE OF xxcff_contract_histories.original_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_quantity_ttype              IS TABLE OF xxcff_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;
  TYPE g_department_code_ttype       IS TABLE OF xxcff_object_headers.department_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_owner_company_ttype         IS TABLE OF xxcff_object_headers.owner_company%TYPE INDEX BY PLS_INTEGER;
  TYPE g_les_asset_acct_ttype        IS TABLE OF xxcff_lease_class_v.les_asset_acct%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_acct_ttype            IS TABLE OF xxcff_lease_class_v.deprn_acct%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_sub_acct_ttype        IS TABLE OF xxcff_lease_class_v.deprn_sub_acct%TYPE INDEX BY PLS_INTEGER;
  TYPE g_category_ccid_ttype         IS TABLE OF fa_categories.category_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_location_ccid_ttype         IS TABLE OF fa_locations.location_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_ccid_ttype            IS TABLE OF gl_code_combinations.code_combination_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_method_ttype          IS TABLE OF fa_category_book_defaults.deprn_method%TYPE INDEX BY PLS_INTEGER;
  TYPE g_asset_number_ttype          IS TABLE OF fa_additions_b.asset_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_segment_ttype               IS TABLE OF gl_code_combinations.segment1%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_match_flag_ttype    IS TABLE OF xxcff_pay_planning.payment_match_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_fa_transaction_id_ttype     IS TABLE OF xxcff_fa_transactions.fa_transaction_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_frequency_ttype     IS TABLE OF xxcff_contract_headers.payment_frequency%TYPE INDEX BY PLS_INTEGER;
  TYPE g_life_in_months_ttype        IS TABLE OF xxcff_contract_histories.life_in_months%TYPE INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  g_deprn_run_tab                       g_deprn_run_ttype;
  g_book_type_code_tab                  g_book_type_code_ttype;
  g_contract_header_id_tab              g_contract_header_id_ttype;
  g_contract_line_id_tab                g_contract_line_id_ttype;
  g_object_header_id_tab                g_object_header_id_ttype;
  g_history_num_tab                     g_history_num_ttype;
  g_lease_class_tab                     g_lease_class_ttype;
  g_lease_kind_tab                      g_lease_kind_ttype;
  g_asset_category_tab                  g_asset_category_ttype;
  g_comments_tab                        g_comments_ttype;
  g_payment_years_tab                   g_payment_years_ttype;
  g_contract_date_tab                   g_contract_date_ttype;
  g_original_cost_tab                   g_original_cost_ttype;
  g_quantity_tab                        g_quantity_ttype;
  g_department_code_tab                 g_department_code_ttype;
  g_owner_company_tab                   g_owner_company_ttype;
  g_les_asset_acct_tab                  g_les_asset_acct_ttype;
  g_deprn_acct_tab                      g_deprn_acct_ttype;
  g_deprn_sub_acct_tab                  g_deprn_sub_acct_ttype;
  g_category_ccid_tab                   g_category_ccid_ttype;
  g_location_ccid_tab                   g_location_ccid_ttype;
  g_deprn_ccid_tab                      g_deprn_ccid_ttype;
  g_deprn_method_tab                    g_deprn_method_ttype;
  g_asset_number_tab                    g_asset_number_ttype;
  g_trnsf_from_comp_cd_tab              g_segment_ttype;
  g_trnsf_to_comp_cd_tab                g_segment_ttype;
  g_payment_match_flag_tab              g_payment_match_flag_ttype;
  g_fa_transaction_id_tab               g_fa_transaction_id_ttype;
  g_payment_frequency_tab               g_payment_frequency_ttype;
  g_life_in_months_tab                  g_life_in_months_ttype;
--
  -- ***��������
  -- ���[�X���(�ǉ�)�o�^�����ɂ����錏��
  gn_les_add_target_cnt    NUMBER;     -- �Ώی���
  gn_les_add_normal_cnt    NUMBER;     -- ���팏��
  gn_les_add_error_cnt     NUMBER;     -- �G���[����
  -- ���[�X���(�U��)�o�^�����ɂ����錏��
  gn_les_trnsf_target_cnt  NUMBER;     -- �Ώی���
  gn_les_trnsf_normal_cnt  NUMBER;     -- ���팏��
  gn_les_trnsf_error_cnt   NUMBER;     -- �G���[����
  -- ���[�X���(���)�o�^�����ɂ����錏��
  gn_les_retire_target_cnt NUMBER;     -- �Ώی���
  gn_les_retire_normal_cnt NUMBER;     -- ���팏��
  gn_les_retire_error_cnt  NUMBER;     -- �G���[����
  -- FAOIF�o�^�����ɂ����錏��
  gn_fa_oif_target_cnt     NUMBER;     -- �Ώی���
  gn_fa_oif_error_cnt      NUMBER;     -- �G���[����
  -- �ǉ�OIF�o�^����
  gn_add_oif_ins_cnt       NUMBER;
  -- �U��OIF�o�^����
  gn_trnsf_oif_ins_cnt     NUMBER;
  -- ���OIF�o�^����
  gn_retire_oif_ins_cnt    NUMBER;
--
  -- �����l���
  g_init_rec xxcff_common1_pkg.init_rtype;
--
  -- �p�����[�^��v���Ԗ�
  gv_period_name VARCHAR2(100);
  -- ���Y�J�e�S��CCID
  gt_category_id  fa_categories.category_id%TYPE;
  -- ���Ə�CCID
  gt_location_id  fa_locations.location_id%TYPE;
--
  -- ***�v���t�@�C���l
  -- ��ЃR�[�h_�{��
  gv_comp_cd_itoen         VARCHAR2(100);
  -- ��ЃR�[�h_���ǉ�v
  gv_comp_cd_sagara        VARCHAR2(100);
  -- ����R�[�h_��������
  gv_dep_cd_chosei         VARCHAR2(100);
  -- �ڋq�R�[�h_��`�Ȃ�
  gv_ptnr_cd_dammy         VARCHAR2(100);
  -- ��ƃR�[�h_��`�Ȃ�
  gv_busi_cd_dammy         VARCHAR2(100);
  -- �\��1�R�[�h_��`�Ȃ�
  gv_project_dammy         VARCHAR2(100);
  -- �\��2�R�[�h_��`�Ȃ�
  gv_future_dammy          VARCHAR2(100);
  -- ���Y�J�e�S��_���p���@
  gv_cat_dprn_lease        VARCHAR2(100);
  -- �\���n_�\���Ȃ�
  gv_dclr_place_no_report  VARCHAR2(100);
  -- ���Ə�_��`�Ȃ�
  gv_mng_place_dammy       VARCHAR2(100);
  -- �ꏊ_��`�Ȃ�
  gv_place_dammy           VARCHAR2(100);
  -- �����@_����
  gv_prt_conv_cd_st        VARCHAR2(100);
  -- �����@_����
  gv_prt_conv_cd_ed        VARCHAR2(100);
  -- �{�ЍH��敪_�{��
  gv_own_comp_itoen        VARCHAR2(100);
  -- �{�ЍH��敪_�H��
  gv_own_comp_sagara       VARCHAR2(100);
--
  -- �Z�O�����g�l�z��(EBS�W���֐�fnd_flex_ext�p)
  g_segments_tab  fnd_flex_ext.segmentarray;
--
  /**********************************************************************************
   * Procedure Name   : delete_collections
   * Description      : �R���N�V�����폜
   ***********************************************************************************/
  PROCEDURE delete_collections(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_collections'; -- �v���O������
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
    --�R���N�V���������z��̍폜
    g_deprn_run_tab.DELETE;
    g_book_type_code_tab.DELETE;
    g_contract_header_id_tab.DELETE;
    g_contract_line_id_tab.DELETE;
    g_object_header_id_tab.DELETE;
    g_history_num_tab.DELETE;
    g_lease_class_tab.DELETE;
    g_lease_kind_tab.DELETE;
    g_asset_category_tab.DELETE;
    g_comments_tab.DELETE;
    g_payment_years_tab.DELETE;
    g_contract_date_tab.DELETE;
    g_original_cost_tab.DELETE;
    g_quantity_tab.DELETE;
    g_department_code_tab.DELETE;
    g_owner_company_tab.DELETE;
    g_les_asset_acct_tab.DELETE;
    g_deprn_acct_tab.DELETE;
    g_deprn_sub_acct_tab.DELETE;
    g_category_ccid_tab.DELETE;
    g_location_ccid_tab.DELETE;
    g_deprn_ccid_tab.DELETE;
    g_deprn_method_tab.DELETE;
    g_asset_number_tab.DELETE;
    g_trnsf_from_comp_cd_tab.DELETE;
    g_trnsf_to_comp_cd_tab.DELETE;
    g_payment_match_flag_tab.DELETE;
    g_fa_transaction_id_tab.DELETE;
    g_payment_frequency_tab.DELETE;
    g_life_in_months_tab.DELETE;
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
  END delete_collections;
--
  /**********************************************************************************
   * Procedure Name   : update_les_trns_fa_if_flag
   * Description      : ���[�X��� FA�A�g�t���O�X�V (A-24)
   ***********************************************************************************/
  PROCEDURE update_les_trns_fa_if_flag(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_les_trns_fa_if_flag'; -- �v���O������
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
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_fa_transaction_id_tab.COUNT
      UPDATE xxcff_fa_transactions
      SET
             fa_if_flag             = cv_if_aft                 -- FA�A�g�t���O 
            ,fa_if_date             = g_init_rec.process_date   -- �v���
            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id             -- �v��ID
            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE
             fa_transaction_id      = g_fa_transaction_id_tab(ln_loop_cnt)
      ;
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
  END update_les_trns_fa_if_flag;
--
  /**********************************************************************************
   * Procedure Name   : insert_retire_oif
   * Description      : ���E���pOIF�o�^ (A-23)
   ***********************************************************************************/
  PROCEDURE insert_retire_oif(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_retire_oif'; -- �v���O������
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
    INSERT INTO xx01_retire_oif(
      retire_oif_id                   -- RETIRE_OIF_ID
     ,book_type_code                  -- �䒠��
     ,asset_number                    -- ���Y�ԍ�
     ,created_by                      -- �쐬��
     ,creation_date                   -- �쐬��
     ,last_updated_by                 -- �ŏI�X�V��
     ,last_update_date                -- �ŏI�X�V��
     ,last_update_login               -- �ŏI�X�V۸޲�
     ,request_id                      -- ظ���ID
     ,program_application_id          -- ���ع����ID
     ,program_id                      -- ��۸���ID
     ,program_update_date             -- ��۸��эŏI�X�V��
     ,date_retired                    -- ������p��
     ,posting_flag                    -- �]�L�����׸�
     ,status                          -- �ð��
     ,cost_retired                    -- ������p�擾���i
     ,proceeds_of_sale                -- ���p���z
     ,cost_of_removal                 -- �P����p
     ,retirement_prorate_convention   -- ������p�N�x���p
    )
    SELECT
      xx01_retire_oif_s.NEXTVAL           -- ID
     ,xxcff_fa_trn.book_type_code         -- �䒠
     ,xxcff_fa_trn.asset_number           -- ���Y�ԍ�
     ,cn_created_by                       -- �쐬��ID
     ,cd_creation_date                    -- �쐬��
     ,cn_last_updated_by                  -- �ŏI�X�V��
     ,cd_last_update_date                 -- �ŏI�X�V��
     ,cn_last_update_login                -- �ŏI�X�V���O�C��ID
     ,cn_request_id                       -- ���N�G�X�gID
     ,cn_program_application_id           -- �A�v���P�[�V����ID
     ,cn_program_id                       -- �v���O����ID
     ,cd_program_update_date              -- �v���O�����ŏI�X�V��
     ,xxcff_fa_trn.retirement_date        -- ������p��
     ,'Y'                                 -- �]�L�`�F�b�N�t���O
     ,'PENDING'                           -- �X�e�[�^�X
     ,xxcff_fa_trn.cost_retired           -- ������p�擾���i
     ,0                                   -- ���p���z
     ,0                                   -- �P����p
     ,xxcff_fa_trn.ret_prorate_convention -- ������p�N�x���p
    FROM
          xxcff_fa_transactions  xxcff_fa_trn
    WHERE
          xxcff_fa_trn.period_name      = gv_period_name
      AND xxcff_fa_trn.fa_if_flag       = cv_if_yet
      AND xxcff_fa_trn.transaction_type = 3 -- ���
    ;
--
    -- ���OIF�o�^�����J�E���g
    gn_retire_oif_ins_cnt := SQL%ROWCOUNT;
--
-- T1_0893 2009/05/19 ADD START --
-- ���[�X���Y�䒠�̏ꍇ�̓��[�X�@�l�ł̃f�[�^���쐬����B
    INSERT INTO xx01_retire_oif(
      retire_oif_id                   -- RETIRE_OIF_ID
     ,book_type_code                  -- �䒠��
     ,asset_number                    -- ���Y�ԍ�
     ,created_by                      -- �쐬��
     ,creation_date                   -- �쐬��
     ,last_updated_by                 -- �ŏI�X�V��
     ,last_update_date                -- �ŏI�X�V��
     ,last_update_login               -- �ŏI�X�V۸޲�
     ,request_id                      -- ظ���ID
     ,program_application_id          -- ���ع����ID
     ,program_id                      -- ��۸���ID
     ,program_update_date             -- ��۸��эŏI�X�V��
     ,date_retired                    -- ������p��
     ,posting_flag                    -- �]�L�����׸�
     ,status                          -- �ð��
     ,cost_retired                    -- ������p�擾���i
     ,proceeds_of_sale                -- ���p���z
     ,cost_of_removal                 -- �P����p
     ,retirement_prorate_convention   -- ������p�N�x���p
    )
    SELECT
      xx01_retire_oif_s.NEXTVAL           -- ID
     ,xlkv.book_type_code_tax             -- �䒠
     ,xxcff_fa_trn.asset_number           -- ���Y�ԍ�
     ,cn_created_by                       -- �쐬��ID
     ,cd_creation_date                    -- �쐬��
     ,cn_last_updated_by                  -- �ŏI�X�V��
     ,cd_last_update_date                 -- �ŏI�X�V��
     ,cn_last_update_login                -- �ŏI�X�V���O�C��ID
     ,cn_request_id                       -- ���N�G�X�gID
     ,cn_program_application_id           -- �A�v���P�[�V����ID
     ,cn_program_id                       -- �v���O����ID
     ,cd_program_update_date              -- �v���O�����ŏI�X�V��
     ,xxcff_fa_trn.retirement_date        -- ������p��
     ,'Y'                                 -- �]�L�`�F�b�N�t���O
     ,'PENDING'                           -- �X�e�[�^�X
     ,xxcff_fa_trn.cost_retired           -- ������p�擾���i
     ,0                                   -- ���p���z
     ,0                                   -- �P����p
     ,xxcff_fa_trn.ret_prorate_convention -- ������p�N�x���p
    FROM
          xxcff_fa_transactions  xxcff_fa_trn
         ,xxcff_contract_lines   xxcff_co_line
         ,xxcff_lease_kind_v     xlkv
    WHERE
          xxcff_fa_trn.period_name        = gv_period_name
      AND xxcff_fa_trn.fa_if_flag         = cv_if_yet
      AND xxcff_fa_trn.transaction_type   = 3                     -- ���
      AND xxcff_fa_trn.contract_header_id = xxcff_co_line.contract_header_id
      AND xxcff_fa_trn.contract_line_id   = xxcff_co_line.contract_line_id
      AND xxcff_co_line.lease_kind        = xlkv.lease_kind_code  -- fin���[�X 
      AND xlkv.lease_kind_code            = cv_lease_kind_fin     -- fin���[�X
    ;
--
    -- ���OIF�o�^�����J�E���g
    gn_retire_oif_ins_cnt := gn_retire_oif_ins_cnt + SQL%ROWCOUNT;
--
-- T1_0893 2009/05/19 ADD END   --
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
  END insert_retire_oif;
--
  /**********************************************************************************
   * Procedure Name   : insert_trnsf_oif
   * Description      : �U��OIF�o�^ (A-22)
   ***********************************************************************************/
  PROCEDURE insert_trnsf_oif(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_trnsf_oif'; -- �v���O������
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
    INSERT INTO xx01_transfer_oif(
      transfer_oif_id           -- ID
     ,book_type_code            -- �䒠��
     ,asset_number              -- ���Y�ԍ�
     ,created_by                -- �쐬��
     ,creation_date             -- �쐬��
     ,last_updated_by           -- �ŏI�X�V��
     ,last_update_date          -- �ŏI�X�V��
     ,last_update_login         -- �ŏI�X�V���O�C��ID
     ,request_id                -- ���N�G�X�gID
     ,program_application_id    -- �A�v���P�[�V����ID
     ,program_id                -- �v���O����ID
     ,program_update_date       -- �v���O�����ŏI�X�V��
     ,transaction_date_entered  -- �U�֓�
     ,transaction_units         -- �P�ʕύX
     ,posting_flag              -- �]�L�`�F�b�N�t���O
     ,status                    -- �X�e�[�^�X
     ,segment1                  -- �������p���Z�O�����g-���
     ,segment2                  -- �������p���Z�O�����g-����
     ,segment3                  -- �������p���Z�O�����g-����Ȗ�
     ,segment4                  -- �������p���Z�O�����g-�⏕�Ȗ�
     ,segment5                  -- �������p���Z�O�����g-�ڋq
     ,segment6                  -- �������p���Z�O�����g-���
     ,segment7                  -- �������p���Z�O�����g-�\��1
     ,segment8                  -- �������p���Z�O�����g-�\��2
     ,loc_segment1              -- �\���n
     ,loc_segment2              -- �Ǘ�����
     ,loc_segment3              -- ���Ə�
     ,loc_segment4              -- �ꏊ
     ,loc_segment5              -- �{�ЍH��敪
    )
    SELECT
      xx01_transfer_oif_s.NEXTVAL         -- ID
     ,xxcff_fa_trn.book_type_code         -- �䒠
     ,xxcff_fa_trn.asset_number           -- ���Y�ԍ�
     ,cn_created_by                       -- �쐬��ID
     ,cd_creation_date                    -- �쐬��
     ,cn_last_updated_by                  -- �ŏI�X�V��
     ,cd_last_update_date                 -- �ŏI�X�V��
     ,cn_last_update_login                -- �ŏI�X�V���O�C��ID
     ,cn_request_id                       -- ���N�G�X�gID
     ,cn_program_application_id           -- �A�v���P�[�V����ID
     ,cn_program_id                       -- �v���O����ID
     ,cd_program_update_date              -- �v���O�����ŏI�X�V��
     ,xxcff_fa_trn.transfer_date          -- �U�֓�
     ,xxcff_fa_trn.quantity               -- �P�ʕύX(����)
     ,'Y'                                 -- �]�L�`�F�b�N�t���O
     ,'PENDING'                           -- �X�e�[�^�X
     ,xxcff_fa_trn.dprn_company_code      -- �������p���Z�O�����g-���
     ,xxcff_fa_trn.dprn_department_code   -- �������p���Z�O�����g-����
     ,xxcff_fa_trn.dprn_account_code      -- �������p���Z�O�����g-����Ȗ�
     ,xxcff_fa_trn.dprn_sub_account_code  -- �������p���Z�O�����g-�⏕�Ȗ�
     ,xxcff_fa_trn.dprn_customer_code     -- �������p���Z�O�����g-�ڋq
     ,xxcff_fa_trn.dprn_enterprise_code   -- �������p���Z�O�����g-���
     ,xxcff_fa_trn.dprn_reserve_1         -- �������p���Z�O�����g-�\��1
     ,xxcff_fa_trn.dprn_reserve_2         -- �������p���Z�O�����g-�\��2
     ,xxcff_fa_trn.dclr_place             -- �\���n
     ,xxcff_fa_trn.department_code        -- �Ǘ�����
     ,xxcff_fa_trn.location_name          -- ���Ə�
     ,xxcff_fa_trn.location_place         -- �ꏊ
     ,xxcff_fa_trn.owner_company          -- �{�ЍH��敪
    FROM
          xxcff_fa_transactions  xxcff_fa_trn
    WHERE
          xxcff_fa_trn.period_name      = gv_period_name
      AND xxcff_fa_trn.fa_if_flag       = cv_if_yet
      AND xxcff_fa_trn.transaction_type = 2              -- �U��
    ;
--
    -- �U��OIF�o�^�����J�E���g
    gn_trnsf_oif_ins_cnt := SQL%ROWCOUNT;
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
  END insert_trnsf_oif;
--
  /**********************************************************************************
   * Procedure Name   : insert_add_oif
   * Description      : �ǉ�OIF�o�^ (A-21)
   ***********************************************************************************/
  PROCEDURE insert_add_oif(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_add_oif'; -- �v���O������
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
    INSERT INTO fa_mass_additions(
       mass_addition_id              -- ID
      ,description                   -- �E�v
      ,asset_category_id             -- ���Y�J�e�S��CCID
      ,book_type_code                -- �䒠
      ,date_placed_in_service        -- ���Ƌ��p��
      ,fixed_assets_cost             -- �擾���z
      ,payables_units                -- AP����
      ,fixed_assets_units            -- ���Y����
      ,expense_code_combination_id   -- �������p���CCID
      ,location_id                   -- ���Ə��t���b�N�X�t�B�[���hCCID
      ,last_update_date              -- �ŏI�X�V��
      ,last_updated_by               -- �ŏI�X�V��
      ,posting_status                -- �]�L�X�e�[�^�X
      ,queue_name                    -- �L���[��
      ,payables_cost                 -- ���Y�����擾���z
      ,depreciate_flag               -- ���p��v��t���O
      ,asset_type                    -- ���Y�^�C�v
      ,created_by                    -- �쐬��ID
      ,creation_date                 -- �쐬��
      ,last_update_login             -- �ŏI�X�V���O�C��ID
      ,attribute10                   -- ���[�X�_�񖾍ד���ID
      ,deprn_method_code             -- ���p���@
      ,life_in_months                -- �v�Z����
    )
    SELECT
      fa_mass_additions_s.NEXTVAL              -- ID
      ,xxcff_fa_trn.description                -- �E�v
      ,xxcff_fa_trn.category_id                -- ���Y�J�e�S��CCID
      ,xxcff_fa_trn.book_type_code             -- �䒠
      ,xxcff_fa_trn.date_placed_in_service     -- ���Ƌ��p��
      ,xxcff_fa_trn.original_cost              -- �擾���z
      ,xxcff_fa_trn.quantity                   -- AP����
      ,xxcff_fa_trn.quantity                   -- ���Y����
      ,xxcff_fa_trn.dprn_code_combination_id   -- �������p���CCID
      ,xxcff_fa_trn.location_id                -- ���Ə��t���b�N�X�t�B�[���hCCID
      ,cd_last_update_date                     -- �ŏI�X�V��
      ,cn_last_updated_by                      -- �ŏI�X�V��
      ,'POST'                                  -- �]�L�X�e�[�^�X
      ,'POST'                                  -- �L���[��
      ,xxcff_fa_trn.original_cost              -- ���Y�����擾���z
      ,'YES'                                   -- ���p��v��t���O
      ,'CAPITALIZED'                           -- ���Y�^�C�v
      ,cn_created_by                           -- �쐬��ID
      ,cd_creation_date                        -- �쐬��
      ,cn_last_update_login                    -- �ŏI�X�V���O�C��ID
      ,xxcff_fa_trn.contract_line_id           -- ���[�X�_�񖾍ד���ID
      ,xxcff_fa_trn.deprn_method               -- ���p���@
      ,xxcff_fa_trn.payment_frequency          -- �v�Z����(�x����)
    FROM
          xxcff_fa_transactions  xxcff_fa_trn
    WHERE
          xxcff_fa_trn.period_name      = gv_period_name
      AND xxcff_fa_trn.fa_if_flag       = cv_if_yet
      AND xxcff_fa_trn.transaction_type = 1         -- �ǉ�
    ;
--
    -- �ǉ�OIF�o�^�����J�E���g
    gn_add_oif_ins_cnt := SQL%ROWCOUNT;
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
  END insert_add_oif;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trns_data
   * Description      : FAOIF�o�^�f�[�^���o (A-20)
   ***********************************************************************************/
  PROCEDURE get_les_trns_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trns_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X����J�[�\��
    CURSOR les_trns_cur
    IS
      SELECT
             xxcff_fa_trn.fa_transaction_id  AS fa_transaction_id  -- ���[�X�������ID
      FROM
            xxcff_fa_transactions   xxcff_fa_trn    -- ���[�X���
      WHERE
            xxcff_fa_trn.period_name      = gv_period_name
        AND xxcff_fa_trn.fa_if_flag       = cv_if_yet
        FOR UPDATE OF xxcff_fa_trn.fa_transaction_id
        NOWAIT
      ;
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
    --==============================================================
    --�R���N�V�����폜
    --==============================================================
    delete_collections(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --==============================================================
    --���C���f�[�^���o
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN les_trns_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH les_trns_cur
    BULK COLLECT INTO  g_fa_transaction_id_tab -- ���[�X�������ID
    ;
    -- �Ώی����J�E���g
    gn_fa_oif_target_cnt := g_fa_transaction_id_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE les_trns_cur;
--
    IF ( gn_fa_oif_target_cnt = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_013a20_t_034) -- FAOIF�A�g���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      -- �J�[�\���N���[�Y
      IF (les_trns_cur%ISOPEN) THEN
        CLOSE les_trns_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_013a20_m_012  -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,cv_msg_013a20_t_030) -- ���[�X���
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trns_cur%ISOPEN) THEN
        CLOSE les_trns_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trns_cur%ISOPEN) THEN
        CLOSE les_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (les_trns_cur%ISOPEN) THEN
        CLOSE les_trns_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_les_trns_data;
--
  /**********************************************************************************
   * Procedure Name   : update_ritire_data_acct_flag
   * Description      : ���[�X�_�񖾍ח��� ��vIF�t���O�X�V (A-19)
   ***********************************************************************************/
  PROCEDURE update_ritire_data_acct_flag(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_ritire_data_acct_flag'; -- �v���O������
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
      <<update_loop>>
      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
        UPDATE xxcff_contract_histories
        SET
               accounting_if_flag     = cv_if_aft                 -- ��vif�t���O 2(�A�g��)
              ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
              ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
              ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
              ,request_id             = cn_request_id             -- �v��ID
              ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
              ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
              ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
        WHERE
               contract_line_id = g_contract_line_id_tab(ln_loop_cnt)
          AND  history_num      = g_history_num_tab(ln_loop_cnt)
        ;
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
  END update_ritire_data_acct_flag;
--
  /**********************************************************************************
   * Procedure Name   : insert_les_trn_ritire_data
   * Description      : ���[�X���(���)�o�^ (A-18)
   ***********************************************************************************/
  PROCEDURE insert_les_trn_ritire_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_les_trn_ritire_data'; -- �v���O������
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
    IF (gn_les_retire_target_cnt > 0) THEN
--
      <<inert_loop>>
      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
        INSERT INTO xxcff_fa_transactions (
           fa_transaction_id                 -- ���[�X�������ID
          ,contract_header_id                -- �_�����ID
          ,contract_line_id                  -- �_�񖾍ד���ID
          ,object_header_id                  -- ��������ID
          ,period_name                       -- ��v����
          ,transaction_type                  -- ����^�C�v
          ,book_type_code                    -- ���Y�䒠��
          ,asset_number                      -- ���Y�ԍ�
          ,lease_class                       -- ���[�X���
          ,department_code                   -- �Ǘ�����
          ,owner_company                     -- �{�ЍH��敪
          ,retirement_date                   -- ���p��
          ,cost_retired                      -- �����p�E�擾���i
          ,ret_prorate_convention            -- ���E���p�N�x���p
          ,fa_if_flag                        -- FA�A�g�t���O
          ,gl_if_flag                        -- GL�A�g�t���O
          ,created_by                        -- �쐬��
          ,creation_date                     -- �쐬��
          ,last_updated_by                   -- �ŏI�X�V��
          ,last_update_date                  -- �ŏI�X�V��
          ,last_update_login                 -- �ŏI�X�V۸޲�
          ,request_id                        -- �v��ID
          ,program_application_id            -- �ݶ��ĥ��۸��ѥ���ع����ID
          ,program_id                        -- �ݶ��ĥ��۸���ID
          ,program_update_date               -- ��۸��эX�V��
        )
        VALUES (
           xxcff_fa_transactions_s1.NEXTVAL             -- ���[�X�������ID
          ,g_contract_header_id_tab(ln_loop_cnt)        -- �_�����ID
          ,g_contract_line_id_tab(ln_loop_cnt)          -- �_�񖾍ד���ID
          ,g_object_header_id_tab(ln_loop_cnt)          -- ��������ID
          ,gv_period_name                               -- ��v����
          ,3                                            -- ����^�C�v
          ,g_book_type_code_tab(ln_loop_cnt)            -- ���Y�䒠��
          ,g_asset_number_tab(ln_loop_cnt)              -- ���Y�ԍ�
          ,g_lease_class_tab(ln_loop_cnt)               -- ���[�X���
          ,g_department_code_tab(ln_loop_cnt)           -- �Ǘ�����
          ,g_owner_company_tab(ln_loop_cnt)             -- �{�ЍH��敪
          ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))  -- ���p��
          ,g_original_cost_tab(ln_loop_cnt)             -- �����p�E�擾���i
          ,DECODE(g_payment_match_flag_tab(ln_loop_cnt)
                    ,0 , gv_prt_conv_cd_st
                    ,1 , gv_prt_conv_cd_ed)             -- ���E���p�N�x���p
          ,cv_if_yet                                    -- FA�A�g�t���O
          ,cv_if_yet                                    -- GL�A�g�t���O
          ,cn_created_by                                -- �쐬��
          ,cd_creation_date                             -- �쐬��
          ,cn_last_updated_by                           -- �ŏI�X�V��
          ,cd_last_update_date                          -- �ŏI�X�V��
          ,cn_last_update_login                         -- �ŏI�X�V۸޲�
          ,cn_request_id                                -- �v��ID
          ,cn_program_application_id                    -- �ݶ��ĥ��۸��ѥ���ع����ID
          ,cn_program_id                                -- �ݶ��ĥ��۸���ID
          ,cd_program_update_date                       -- ��۸��эX�V��
        );
--
        -- ���������J�E���g
        gn_les_retire_normal_cnt := SQL%ROWCOUNT;
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
  END insert_les_trn_ritire_data;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trn_retire_data
   * Description      : ���[�X���(���)�o�^�f�[�^���o (A-17)
   ***********************************************************************************/
  PROCEDURE get_les_trn_retire_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trn_retire_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X���(���)�J�[�\��
    CURSOR les_trn_retire_cur
    IS
      SELECT
             ctrct_hist.contract_header_id        AS contract_header_id  -- �_�����ID
            ,ctrct_hist.contract_line_id          AS contract_line_id    -- �_�񖾍ד���ID
            ,ctrct_hist.object_header_id          AS object_header_id    -- ��������ID
            ,ctrct_hist.history_num               AS history_num         -- �ύX����No
            ,ctrct_hist.original_cost             AS original_cost       -- �擾���i
            ,faadds.asset_number                  AS asset_number        -- ���Y�ԍ�
            ,les_kind.book_type_code              AS book_type_code      -- ���Y�䒠��
            ,NVL(pay_plan.payment_match_flag,1)   AS payment_match_flag  -- �ƍ��ς݃t���O
            ,obj_head.department_code             AS department_code     -- �Ǘ�����
            ,obj_head.owner_company               AS owner_company       -- �{�ЍH��敪
            ,ctrct_head.lease_class               AS lease_class         -- ���[�X���
      FROM
            xxcff_contract_histories  ctrct_hist    -- ���[�X�_�񖾍ח���
           ,xxcff_contract_headers    ctrct_head    -- ���[�X�_��
           ,xxcff_object_headers      obj_head      -- ���[�X����
           ,xxcff_lease_kind_v        les_kind      -- ���[�X��ރr���[
           ,fa_additions_b            faadds        -- ���Y�ڍ׏��
           ,xxcff_pay_planning        pay_plan      -- ���[�X�x���v��
      WHERE
            ctrct_hist.contract_status     IN ( cv_ctrt_manryo
                                               ,cv_ctrt_cancel_jiko
                                               ,cv_ctrt_cancel_hoken
                                               ,cv_ctrt_cancel_manryo
                                               )      -- ����,
                                                      -- ���r���(���ȓs��),���r���(�ی��Ή�),���r���(����)

        AND ctrct_hist.accounting_if_flag   = cv_if_yet                               -- �����M
        AND ctrct_hist.lease_kind           IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,��Fin
        AND ctrct_hist.contract_header_id   = ctrct_head.contract_header_id
        AND ctrct_hist.object_header_id     = obj_head.object_header_id
        AND ctrct_head.lease_type           = cv_original                             -- ���_��
        AND ctrct_hist.contract_line_id     = faadds.attribute10
        AND ctrct_hist.lease_kind           = les_kind.lease_kind_code
        AND ctrct_hist.contract_line_id     = pay_plan.contract_line_id(+)
        AND pay_plan.period_name(+)         = gv_period_name
        FOR UPDATE OF ctrct_hist.contract_header_id
        NOWAIT
      ;
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
    --==============================================================
    --�R���N�V�����폜
    --==============================================================
    delete_collections(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --==============================================================
    --���C���f�[�^���o
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN les_trn_retire_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH les_trn_retire_cur
    BULK COLLECT INTO  g_contract_header_id_tab -- �_�����ID
                      ,g_contract_line_id_tab   -- �_�񖾍ד���ID
                      ,g_object_header_id_tab   -- ��������ID
                      ,g_history_num_tab        -- �ύX����No
                      ,g_original_cost_tab      -- �擾���i
                      ,g_asset_number_tab       -- ���Y�ԍ�
                      ,g_book_type_code_tab     -- ���Y�䒠��
                      ,g_payment_match_flag_tab -- �ƍ��ς݃t���O
                      ,g_department_code_tab    -- �Ǘ�����
                      ,g_owner_company_tab      -- �{�ЍH��敪
                      ,g_lease_class_tab        -- ���[�X���
    ;
    -- �����Ώی���
    gn_les_retire_target_cnt := g_contract_header_id_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE les_trn_retire_cur;
--
    IF ( gn_les_retire_target_cnt = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_013a20_t_033) -- ���[�X����i���j���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      -- �J�[�\���N���[�Y
      IF (les_trn_retire_cur%ISOPEN) THEN
        CLOSE les_trn_retire_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_013a20_m_012  -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,cv_msg_013a20_t_023) -- ���[�X�_�񖾍ח���
                                                     ,1
                                                     ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_retire_cur%ISOPEN) THEN
        CLOSE les_trn_retire_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_retire_cur%ISOPEN) THEN
        CLOSE les_trn_retire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_retire_cur%ISOPEN) THEN
        CLOSE les_trn_retire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_les_trn_retire_data;
--
  /**********************************************************************************
   * Procedure Name   : get_deprn_ccid
   * Description      : �������p���CCID�擾 (A-7,A-14)
   ***********************************************************************************/
  PROCEDURE get_deprn_ccid(
     iot_segments  IN OUT fnd_flex_ext.segmentarray                     -- 1.�Z�O�����g�l�z��
    ,ot_deprn_ccid OUT    gl_code_combinations.code_combination_id%TYPE -- 2.�������p���CCID
    ,ov_errbuf     OUT    VARCHAR2                                      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT    VARCHAR2                                      --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT    VARCHAR2)                                     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deprn_ccid'; -- �v���O������
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
    -- �֐����^�[���R�[�h
    lb_ret BOOLEAN;
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
    -- ����R�[�h�ݒ�
    iot_segments(2) := gv_dep_cd_chosei;
    -- �ڋq�R�[�h�ݒ�
    iot_segments(5) := gv_ptnr_cd_dammy;
    -- ��ƃR�[�h�ݒ�
    iot_segments(6) := gv_busi_cd_dammy;
    -- �\��1�ݒ�
    iot_segments(7) := gv_project_dammy;
    -- �\��2�ݒ�
    iot_segments(8) := gv_future_dammy;
--
    -- CCID�擾�֐��Ăяo��
    lb_ret := fnd_flex_ext.get_combination_id(
                 application_short_name  => g_init_rec.gl_application_short_name -- �A�v���P�[�V�����Z�k��(GL)
                ,key_flex_code           => g_init_rec.id_flex_code              -- �L�[�t���b�N�X�R�[�h
                ,structure_number        => g_init_rec.chart_of_accounts_id      -- ����Ȗڑ̌n�ԍ�
                ,validation_date         => g_init_rec.process_date              -- ���t�`�F�b�N
                ,n_segments              => 8                                    -- �Z�O�����g��
                ,segments                => iot_segments                         -- �Z�O�����g�l�z��
                ,combination_id          => ot_deprn_ccid                        -- CCID
                );
    IF NOT lb_ret THEN
      lv_errmsg := fnd_flex_ext.get_message;
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
  END get_deprn_ccid;
--
  /**********************************************************************************
   * Procedure Name   : update_trnsf_data_acct_flag
   * Description      : ���[�X�_�񖾍ח��� ��vIF�t���O�X�V (A-16)
   ***********************************************************************************/
  PROCEDURE update_trnsf_data_acct_flag(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_trnsf_data_acct_flag'; -- �v���O������
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
    --==============================================================
    --���[�X���������X�V
    --==============================================================
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT
      UPDATE xxcff_object_histories
      SET
             accounting_if_flag     = cv_if_aft                 -- ��vif�t���O 2(�A�g��)
            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id             -- �v��ID
            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE
            object_header_id     = g_object_header_id_tab(ln_loop_cnt)
        AND object_status        =  cv_obj_move    -- �ړ�
        AND accounting_if_flag   =  cv_if_yet      -- �����M
        AND accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
      ;
--
    --==============================================================
    --���[�X�_�񖾍ח����X�V
    --==============================================================
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
      UPDATE xxcff_contract_histories
      SET
             accounting_if_flag     = cv_if_aft                 -- ��vif�t���O 2(�A�g��)
            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id             -- �v��ID
            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE
             contract_line_id   = g_contract_line_id_tab(ln_loop_cnt)
         AND contract_status    =  cv_ctrt_info_change  -- ���ύX
         AND accounting_if_flag =  cv_if_yet            -- �����M
         AND accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
      ;
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
  END update_trnsf_data_acct_flag;
--
  /**********************************************************************************
   * Procedure Name   : insert_les_trn_trnsf_data
   * Description      : ���[�X���(�U��)�o�^ (A-15)
   ***********************************************************************************/
  PROCEDURE insert_les_trn_trnsf_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_les_trn_trnsf_data'; -- �v���O������
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
    IF (gn_les_trnsf_target_cnt > 0) THEN
--
      <<inert_loop>>
      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
        INSERT INTO xxcff_fa_transactions (
           fa_transaction_id                 -- ���[�X�������ID
          ,contract_header_id                -- �_�����ID
          ,contract_line_id                  -- �_�񖾍ד���ID
          ,object_header_id                  -- ��������ID
          ,period_name                       -- ��v����
          ,transaction_type                  -- ����^�C�v
          ,movement_type                     -- �ړ��^�C�v
          ,book_type_code                    -- ���Y�䒠��
          ,asset_number                      -- ���Y�ԍ�
          ,lease_class                       -- ���[�X���
          ,quantity                          -- ����
          ,dprn_company_code                 -- ��F_��ЃR�[�h
          ,dprn_department_code              -- ��F_����R�[�h
          ,dprn_account_code                 -- ��F_����ȖڃR�[�h
          ,dprn_sub_account_code             -- ��F_�⏕�ȖڃR�[�h
          ,dprn_customer_code                -- ��F_�ڋq�R�[�h
          ,dprn_enterprise_code              -- ��F_��ƃR�[�h
          ,dprn_reserve_1                    -- ��F_�\��1
          ,dprn_reserve_2                    -- ��F_�\��2
          ,dclr_place                        -- �\���n
          ,department_code                   -- �Ǘ�����R�[�h
          ,location_name                     -- ���Ə�
          ,location_place                    -- �ꏊ
          ,owner_company                     -- �{�Ё^�H��
          ,transfer_date                     -- �U�֓�
          ,fa_if_flag                        -- FA�A�g�t���O
          ,gl_if_flag                        -- GL�A�g�t���O
          ,created_by                        -- �쐬��
          ,creation_date                     -- �쐬��
          ,last_updated_by                   -- �ŏI�X�V��
          ,last_update_date                  -- �ŏI�X�V��
          ,last_update_login                 -- �ŏI�X�V۸޲�
          ,request_id                        -- �v��ID
          ,program_application_id            -- �ݶ��ĥ��۸��ѥ���ع����ID
          ,program_id                        -- �ݶ��ĥ��۸���ID
          ,program_update_date               -- ��۸��эX�V��
        )
        VALUES (
           xxcff_fa_transactions_s1.NEXTVAL            -- ���[�X�������ID
          ,g_contract_header_id_tab(ln_loop_cnt)       -- �_�����ID
          ,g_contract_line_id_tab(ln_loop_cnt)         -- �_�񖾍ד���ID
          ,g_object_header_id_tab(ln_loop_cnt)         -- ��������ID
          ,gv_period_name                              -- ��v����
          ,2                                           -- ����^�C�v
          ,DECODE(g_trnsf_to_comp_cd_tab(ln_loop_cnt)
                    ,gv_comp_cd_sagara , 1
                    ,gv_comp_cd_itoen  , 2)            -- �ړ��^�C�v
          ,g_book_type_code_tab(ln_loop_cnt)           -- ���Y�䒠��
          ,g_asset_number_tab(ln_loop_cnt)             -- ���Y�ԍ�
          ,g_lease_class_tab(ln_loop_cnt)              -- ���[�X���
          ,g_quantity_tab(ln_loop_cnt)                 -- ����
          ,g_trnsf_to_comp_cd_tab(ln_loop_cnt)         -- ��F_��ЃR�[�h
          ,gv_dep_cd_chosei                            -- ��F_����R�[�h
          ,g_deprn_acct_tab(ln_loop_cnt)               -- ��F_����ȖڃR�[�h
          ,g_deprn_sub_acct_tab(ln_loop_cnt)           -- ��F_�⏕�ȖڃR�[�h
          ,gv_ptnr_cd_dammy                            -- ��F_�ڋq�R�[�h
          ,gv_busi_cd_dammy                            -- ��F_��ƃR�[�h
          ,gv_project_dammy                            -- ��F_�\��1
          ,gv_future_dammy                             -- ��F_�\��2
          ,gv_dclr_place_no_report                     -- �\���n
          ,g_department_code_tab(ln_loop_cnt)          -- �Ǘ�����R�[�h
          ,gv_mng_place_dammy                          -- ���Ə�
          ,gv_place_dammy                              -- �ꏊ
          ,g_owner_company_tab(ln_loop_cnt)            -- �{�Ё^�H��
          ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) -- �U�֓�
          ,cv_if_yet                                   -- FA�A�g�t���O
          ,cv_if_yet                                   -- GL�A�g�t���O
          ,cn_created_by                               -- �쐬��
          ,cd_creation_date                            -- �쐬��
          ,cn_last_updated_by                          -- �ŏI�X�V��
          ,cd_last_update_date                         -- �ŏI�X�V��
          ,cn_last_update_login                        -- �ŏI�X�V۸޲�
          ,cn_request_id                               -- �v��ID
          ,cn_program_application_id                   -- �ݶ��ĥ��۸��ѥ���ع����ID
          ,cn_program_id                               -- �ݶ��ĥ��۸���ID
          ,cd_program_update_date                      -- ��۸��эX�V��
        );
--
      --���������J�E���g
      gn_les_trnsf_normal_cnt := SQL%ROWCOUNT;
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
  END insert_les_trn_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : lock_trnsf_data
   * Description      : ���[�X���(�U��)�f�[�^���b�N���� (A-12)
   ***********************************************************************************/
  PROCEDURE lock_trnsf_data(
    it_object_header_id IN xxcff_contract_histories.object_header_id%TYPE
   ,it_contract_line_id IN xxcff_contract_histories.contract_line_id%TYPE
   ,ov_errbuf           OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
   ,ov_retcode          OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
   ,ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'lock_trnsf_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���b�N�p�J�[�\��(��������)
    CURSOR lock_obj_trnsf_data (in_object_header_id NUMBER)
    IS
      SELECT
             obj_hist.object_header_id     AS object_header_id  -- ��������ID
      FROM
            xxcff_object_histories    obj_hist      -- ���[�X��������
      WHERE
             obj_hist.object_header_id     =  in_object_header_id
         AND obj_hist.object_status        =  cv_obj_move    -- �ړ�
         AND obj_hist.accounting_if_flag   =  cv_if_yet      -- �����M
         AND obj_hist.accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
         FOR UPDATE NOWAIT
         ;
--
    -- ���b�N�p�J�[�\��(�_�񖾍ח���)
    CURSOR lock_ctrct_trnsf_data (in_contract_line_id NUMBER)
    IS
      SELECT
             ctrct_hist.contract_line_id     AS contract_line_id  -- ��������ID
      FROM
            xxcff_contract_histories    ctrct_hist      -- ���[�X�_�񖾍ח���
      WHERE
             ctrct_hist.contract_line_id   =  in_contract_line_id
         AND ctrct_hist.contract_status    =  cv_ctrt_info_change  -- ���ύX
         AND ctrct_hist.accounting_if_flag =  cv_if_yet            -- �����M
         AND ctrct_hist.accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
         FOR UPDATE NOWAIT
         ;
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
    --==============================================================
    --���b�N�����˕��������f�[�^
    --==============================================================
    BEGIN
--
      -- �J�[�\���I�[�v��
      OPEN lock_obj_trnsf_data (it_object_header_id);
      -- �J�[�\���N���[�Y
      CLOSE lock_obj_trnsf_data;
--
    EXCEPTION
      WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
        -- �J�[�\���N���[�Y
        IF (lock_obj_trnsf_data%ISOPEN) THEN
          CLOSE lock_obj_trnsf_data;
        END IF;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_012  -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,cv_msg_013a20_t_029) -- ���[�X��������
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
    --==============================================================
    --���b�N�����ˌ_�񖾍ח����f�[�^
    --==============================================================
    BEGIN
--
      -- �J�[�\���I�[�v��
      OPEN lock_ctrct_trnsf_data (it_contract_line_id);
      -- �J�[�\���N���[�Y
      CLOSE lock_ctrct_trnsf_data;
--
    EXCEPTION
      WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
        -- �J�[�\���N���[�Y
        IF (lock_ctrct_trnsf_data%ISOPEN) THEN
          CLOSE lock_ctrct_trnsf_data;
        END IF;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_012  -- �e�[�u�����b�N�G���[
                                                       ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                       ,cv_msg_013a20_t_023) -- ���[�X�_�񖾍ח���
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (lock_obj_trnsf_data%ISOPEN) THEN
        CLOSE lock_obj_trnsf_data;
      END IF;
      IF (lock_ctrct_trnsf_data%ISOPEN) THEN
        CLOSE lock_ctrct_trnsf_data;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (lock_obj_trnsf_data%ISOPEN) THEN
        CLOSE lock_obj_trnsf_data;
      END IF;
      IF (lock_ctrct_trnsf_data%ISOPEN) THEN
        CLOSE lock_ctrct_trnsf_data;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (lock_obj_trnsf_data%ISOPEN) THEN
        CLOSE lock_obj_trnsf_data;
      END IF;
      IF (lock_ctrct_trnsf_data%ISOPEN) THEN
        CLOSE lock_ctrct_trnsf_data;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END lock_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_les_trn_trnsf_data�i���[�v���j
   * Description      : ���[�X���(�U��)�f�[�^���� (A-12)�`(A-16)
   ***********************************************************************************/
  PROCEDURE proc_les_trn_trnsf_data(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_les_trn_trnsf_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���C�����[�v�����A
    --==============================================================
    <<proc_les_trn_trnsf_data>>
    FOR ln_loop_cnt IN 1 .. g_contract_header_id_tab.COUNT LOOP
--
      --==============================================================
      --���o�Ώۃf�[�^���b�N (A-12)
      --==============================================================
      lock_trnsf_data(
         it_object_header_id    => g_object_header_id_tab(ln_loop_cnt) -- ��������ID
        ,it_contract_line_id    => g_contract_line_id_tab(ln_loop_cnt) -- �_�񖾍ד���ID
        ,ov_errbuf              => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode             => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg              => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --���Ə�CCID�擾 (A-13)
      --==============================================================
      xxcff_common1_pkg.chk_fa_location(
         iv_segment2      => g_department_code_tab(ln_loop_cnt) -- �Ǘ�����
        ,iv_segment5      => g_owner_company_tab(ln_loop_cnt)   -- �{�ЍH��敪
        ,on_location_id   => g_location_ccid_tab(ln_loop_cnt)   -- ���Ə�CCID
        ,ov_errbuf        => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode       => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�������p���CCID�擾 (A-15)
      --==============================================================
--
      -- �Z�O�����g�l�z��ݒ�(SEG1:���)
      g_segments_tab(1) :=  g_trnsf_to_comp_cd_tab(ln_loop_cnt);
--
      -- �Z�O�����g�l�z��ݒ�(SEG3:����Ȗ�)
      g_segments_tab(3) := g_deprn_acct_tab(ln_loop_cnt);
      -- �Z�O�����g�l�z��ݒ�(SEG4:�⏕�Ȗ�)
      g_segments_tab(4) := g_deprn_sub_acct_tab(ln_loop_cnt);
--
      -- �������p���CCID�擾
      get_deprn_ccid(
         iot_segments     => g_segments_tab                  -- �Z�O�����g�l�z��
        ,ot_deprn_ccid    => g_deprn_ccid_tab(ln_loop_cnt)   -- �������p���CCID
        ,ov_errbuf        => lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode       => lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_les_trn_trnsf_data;
--
    -- =========================================
    -- ���[�X���(�U��)�o�^ (A-15)
    -- =========================================
    insert_les_trn_trnsf_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- ���o�Ώۃf�[�^ ��vIF�t���O�X�V (A-16)
    -- ==============================================
    update_trnsf_data_acct_flag(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END proc_les_trn_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trn_trnsf_data
   * Description      : ���[�X���(�U��)�o�^�f�[�^���o (A-11)
   ***********************************************************************************/
  PROCEDURE get_les_trn_trnsf_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trn_trnsf_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X���(�U��)�J�[�\��
    CURSOR les_trn_trnsf_cur
    IS
      SELECT
             ctrct_line.contract_header_id                      AS contract_header_id -- �_�����ID
            ,ctrct_line.contract_line_id                        AS contract_line_id   -- �_�񖾍ד���ID
            ,ctrct_line.object_header_id                        AS object_header_id   -- ��������ID
            ,ctrct_head.contract_date                           AS contract_date      -- ���[�X�_���
            ,obj_head.department_code                           AS department_code    -- �Ǘ�����
            ,obj_head.owner_company                             AS owner_company      -- �{�ЍH��敪
            ,1                                                  AS quantity           -- ����
            ,ctrct_head.lease_class                             AS lease_class        -- ���[�X���
            ,faadds.asset_number                                AS asset_number       -- ���Y�ԍ�
            ,les_kind.book_type_code                            AS book_type_code     -- ���Y�䒠��
            ,les_class.deprn_acct                               AS deprn_acct         -- �������p����
            ,les_class.deprn_sub_acct                           AS deprn_sub_acct     -- �������p�⏕����
            ,gcc.segment1                                       AS trnsf_from_comp_cd -- �U�֌���ЃR�[�h
            ,DECODE(obj_head.owner_company
                      ,gv_own_comp_itoen  , gv_comp_cd_itoen
                      ,gv_own_comp_sagara , gv_comp_cd_sagara)  AS trnsf_to_comp_cd   -- �U�֐��ЃR�[�h

            ,NULL                                               AS location_ccid      -- ���Ə�CCID
            ,NULL                                               AS deprn_ccid         -- �������p���CCID
      FROM
            xxcff_object_headers      obj_head      -- ���[�X����
           ,xxcff_contract_lines      ctrct_line    -- ���[�X�_�񖾍�
           ,xxcff_contract_headers    ctrct_head    -- ���[�X�_��
           ,fa_additions_b            faadds        -- ���Y�ڍ׏��
           ,fa_distribution_history   fadist_hist   -- ���Y�����������
           ,gl_code_combinations      gcc           -- GL�g����
           ,xxcff_lease_class_v       les_class     -- ���[�X��ʃr���[
           ,xxcff_lease_kind_v        les_kind      -- ���[�X��ރr���[
           ,( 
              SELECT  lse_trnsf_hist_data.object_header_id
                     ,lse_trnsf_hist_data.contract_line_id
              FROM (
                     SELECT
                             obj_hist.object_header_id   AS object_header_id
                            ,ctrct_line.contract_line_id AS contract_line_id
                     FROM
                           xxcff_object_histories  obj_hist    -- ���[�X��������
                          ,xxcff_contract_lines    ctrct_line  -- ���[�X�_�񖾍�
                          ,xxcff_contract_headers  ctrct_head  -- ���[�X�_��
                     WHERE 
                           obj_hist.object_header_id   = ctrct_line.object_header_id
                       AND ctrct_line.contract_status  IN ( cv_ctrt_ctrt
                                                           ,cv_ctrt_manryo
                                                           ,cv_ctrt_cancel_jiko
                                                           ,cv_ctrt_cancel_hoken
                                                           ,cv_ctrt_cancel_manryo
                                                           ) -- �_��
                                                             -- ����
                                                             -- ���r���(���ȓs��),���r���(�ی��Ή�),���r���(����)
                       AND obj_hist.object_status        = cv_obj_move  -- �ړ�
                       AND obj_hist.accounting_if_flag   = cv_if_yet    -- �����M
                       AND obj_hist.accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
                       AND ctrct_head.contract_header_id = ctrct_line.contract_header_id
                       AND ctrct_head.lease_type         =  cv_original                            -- ���_��
                       AND ctrct_line.lease_kind         IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,��Fin
                       AND obj_hist.re_lease_times       = ctrct_head.re_lease_times
                     UNION ALL
                     SELECT
                             ctrct_hist.object_header_id   AS object_header_id
                            ,ctrct_hist.contract_line_id   AS contract_line_id
                     FROM
                           xxcff_contract_headers    ctrct_head  -- ���[�X�_��
                          ,xxcff_contract_histories  ctrct_hist  -- ���[�X�_�񖾍ח���
                     WHERE 
                           ctrct_head.contract_header_id   =  ctrct_hist.contract_header_id
                       AND ctrct_head.lease_type           =  cv_original                            -- ���_��
                       AND ctrct_hist.lease_kind           IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,��Fin
                       AND ctrct_hist.contract_status      =  cv_ctrt_info_change                    -- ���ύX
                       AND ctrct_hist.accounting_if_flag   =  cv_if_yet                              -- �����M
                       AND ctrct_hist.accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
                       ) lse_trnsf_hist_data -- �C�����C���r���[(�����ړ������E�_����ύX����)
              GROUP BY
                 lse_trnsf_hist_data.object_header_id
                ,lse_trnsf_hist_data.contract_line_id
            ) lse_trnsf_hist
      WHERE
            ctrct_line.contract_line_id     =  lse_trnsf_hist.contract_line_id
        AND ctrct_line.object_header_id     =  lse_trnsf_hist.object_header_id
        AND ctrct_line.object_header_id     =  obj_head.object_header_id
        AND ctrct_line.contract_header_id   =  ctrct_head.contract_header_id
        AND ctrct_line.lease_kind           IN (cv_lease_kind_fin,cv_lease_kind_lfin) -- Fin,��Fin
        AND ctrct_line.lease_kind           =  les_kind.lease_kind_code
        AND ctrct_head.lease_type           =  cv_original                            -- ���_��
        AND ctrct_head.lease_class          =  les_class.lease_class_code
        AND ctrct_line.contract_line_id     =  faadds.attribute10
        AND faadds.asset_id                 =  fadist_hist.asset_id
        AND fadist_hist.book_type_code      =  les_kind.book_type_code
        AND fadist_hist.date_ineffective    IS NULL
        AND fadist_hist.code_combination_id =  gcc.code_combination_id
        AND DECODE(obj_head.owner_company
                     ,gv_own_comp_itoen  , gv_comp_cd_itoen
                     ,gv_own_comp_sagara , gv_comp_cd_sagara) <> gcc.segment1

        ;
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
    --==============================================================
    --�R���N�V�����폜
    --==============================================================
    delete_collections(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --==============================================================
    --���C���f�[�^���o
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN les_trn_trnsf_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH les_trn_trnsf_cur
    BULK COLLECT INTO  g_contract_header_id_tab -- �_�����ID
                      ,g_contract_line_id_tab   -- �_�񖾍ד���ID
                      ,g_object_header_id_tab   -- ��������ID
                      ,g_contract_date_tab      -- ���[�X�_���
                      ,g_department_code_tab    -- �Ǘ�����
                      ,g_owner_company_tab      -- �{�ЍH��敪
                      ,g_quantity_tab           -- ����
                      ,g_lease_class_tab        -- ���[�X���
                      ,g_asset_number_tab       -- ���Y�ԍ�
                      ,g_book_type_code_tab     -- ���Y�䒠��
                      ,g_deprn_acct_tab         -- �������p����
                      ,g_deprn_sub_acct_tab     -- �������p�⏕����
                      ,g_trnsf_from_comp_cd_tab -- �U�֌���ЃR�[�h
                      ,g_trnsf_to_comp_cd_tab   -- �U�֐��ЃR�[�h
                      ,g_location_ccid_tab      -- ���Ə�CCID
                      ,g_deprn_ccid_tab         -- �������p���CCID
    ;
    -- �Ώی����J�E���g
    gn_les_trnsf_target_cnt := g_contract_header_id_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE les_trn_trnsf_cur;
--
    IF ( gn_les_trnsf_target_cnt = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_013a20_t_032) -- ���[�X����i�U�ցj���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_trnsf_cur%ISOPEN) THEN
        CLOSE les_trn_trnsf_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_trnsf_cur%ISOPEN) THEN
        CLOSE les_trn_trnsf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_trnsf_cur%ISOPEN) THEN
        CLOSE les_trn_trnsf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_les_trn_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : update_ctrct_line_acct_flag
   * Description      : ���[�X�_�񖾍ח��� ��vIF�t���O�X�V (A-10)
   ***********************************************************************************/
  PROCEDURE update_ctrct_line_acct_flag(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_ctrct_line_acct_flag'; -- �v���O������
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
    --==============================================================
    --���[�X���������X�V
    --==============================================================
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT
      UPDATE xxcff_object_histories
      SET
             accounting_if_flag     = cv_if_aft                 -- ��vif�t���O 2(�A�g��)
            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id             -- �v��ID
            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE
            object_header_id     =  g_object_header_id_tab(ln_loop_cnt)
        AND object_status        =  cv_obj_move   -- �ړ�
        AND accounting_if_flag   =  cv_if_yet    -- �����M
        AND accounting_date      <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
      ;
--
    --==============================================================
    --���[�X�_�񖾍ח����X�V
    --==============================================================
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
      UPDATE xxcff_contract_histories
      SET
             accounting_if_flag     = cv_if_aft                 -- ��vif�t���O 2(�A�g��)
            ,last_updated_by        = cn_last_updated_by        -- �ŏI�X�V��
            ,last_update_date       = cd_last_update_date       -- �ŏI�X�V��
            ,last_update_login      = cn_last_update_login      -- �ŏI�X�V���O�C��
            ,request_id             = cn_request_id             -- �v��ID
            ,program_application_id = cn_program_application_id -- �R���J�����g�v���O�����A�v���P�[�V����
            ,program_id             = cn_program_id             -- �R���J�����g�v���O����ID
            ,program_update_date    = cd_program_update_date    -- �v���O�����X�V��
      WHERE
             contract_line_id   =  g_contract_line_id_tab(ln_loop_cnt)
         AND contract_status    IN (cv_ctrt_ctrt,cv_ctrt_info_change)  -- �_��,���ύX
         AND accounting_if_flag =  cv_if_yet                           -- �����M
         AND accounting_date    <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
      ;
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
  END update_ctrct_line_acct_flag;
--
  /**********************************************************************************
   * Procedure Name   : insert_les_trn_add_data
   * Description      : ���[�X���(�ǉ�)�o�^ (A-9)
   ***********************************************************************************/
  PROCEDURE insert_les_trn_add_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_les_trn_add_data'; -- �v���O������
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
    IF (gn_les_add_target_cnt > 0) THEN
--
      <<inert_loop>>
      FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
        INSERT INTO xxcff_fa_transactions (
           fa_transaction_id                 -- ���[�X�������ID
          ,contract_header_id                -- �_�����ID
          ,contract_line_id                  -- �_�񖾍ד���ID
          ,object_header_id                  -- ��������ID
          ,period_name                       -- ��v����
          ,transaction_type                  -- ����^�C�v
          ,book_type_code                    -- ���Y�䒠��
          ,description                       -- �E�v
          ,category_id                       -- ���Y�J�e�S��CCID
          ,asset_category                    -- ���Y���
          ,asset_account                     -- ���Y����
          ,deprn_account                     -- ���p�Ȗ�
          ,lease_class                       -- ���[�X���
          ,dprn_code_combination_id          -- �������p���CCID
          ,location_id                       -- ���Ə�CCID
          ,department_code                   -- �Ǘ�����R�[�h
          ,owner_company                     -- �{�ЍH��敪
          ,date_placed_in_service            -- ���Ƌ��p��
          ,original_cost                     -- �擾���z
          ,quantity                          -- ����
          ,deprn_method                      -- ���p���@
          ,payment_frequency                 -- �v�Z����(�x����)
          ,fa_if_flag                        -- FA�A�g�t���O
          ,gl_if_flag                        -- GL�A�g�t���O
          ,created_by                        -- �쐬��
          ,creation_date                     -- �쐬��
          ,last_updated_by                   -- �ŏI�X�V��
          ,last_update_date                  -- �ŏI�X�V��
          ,last_update_login                 -- �ŏI�X�V۸޲�
          ,request_id                        -- �v��ID
          ,program_application_id            -- �ݶ��ĥ��۸��ѥ���ع����ID
          ,program_id                        -- �ݶ��ĥ��۸���ID
          ,program_update_date               -- ��۸��эX�V��
        )
        VALUES (
           xxcff_fa_transactions_s1.NEXTVAL       -- ���[�X�������ID
          ,g_contract_header_id_tab(ln_loop_cnt)  -- �_�����ID
          ,g_contract_line_id_tab(ln_loop_cnt)    -- �_�񖾍ד���ID
          ,g_object_header_id_tab(ln_loop_cnt)    -- ��������ID
          ,gv_period_name                         -- ��v����
          ,1                                      -- ����^�C�v(�ǉ�)
          ,g_book_type_code_tab(ln_loop_cnt)      -- ���Y�䒠��
          ,g_comments_tab(ln_loop_cnt)            -- �E�v
          ,g_category_ccid_tab(ln_loop_cnt)       -- ���Y�J�e�S��CCID
          ,g_asset_category_tab(ln_loop_cnt)      -- ���Y���
          ,g_les_asset_acct_tab(ln_loop_cnt)      -- ���Y����
          ,g_deprn_acct_tab(ln_loop_cnt)          -- ���p�Ȗ�
          ,g_lease_class_tab(ln_loop_cnt)         -- ���[�X���
          ,g_deprn_ccid_tab(ln_loop_cnt)          -- �������p���CCID
          ,g_location_ccid_tab(ln_loop_cnt)       -- ���Ə�CCID
          ,g_department_code_tab(ln_loop_cnt)     -- �Ǘ�����R�[�h
          ,g_owner_company_tab(ln_loop_cnt)       -- �{�ЍH��敪
          ,g_contract_date_tab(ln_loop_cnt)       -- ���Ƌ��p��
          ,g_original_cost_tab(ln_loop_cnt)       -- �擾���z
          ,g_quantity_tab(ln_loop_cnt)            -- ����
          ,g_deprn_method_tab(ln_loop_cnt)        -- ���p���@
          ,g_payment_frequency_tab(ln_loop_cnt)   -- �v�Z����(�x����)
          ,cv_if_yet                              -- FA�A�g�t���O
          ,cv_if_yet                              -- GL�A�g�t���O
          ,cn_created_by                          -- �쐬��
          ,cd_creation_date                       -- �쐬��
          ,cn_last_updated_by                     -- �ŏI�X�V��
          ,cd_last_update_date                    -- �ŏI�X�V��
          ,cn_last_update_login                   -- �ŏI�X�V۸޲�
          ,cn_request_id                          -- �v��ID
          ,cn_program_application_id              -- �ݶ��ĥ��۸��ѥ���ع����ID
          ,cn_program_id                          -- �ݶ��ĥ��۸���ID
          ,cd_program_update_date                 -- ��۸��эX�V��
        );
--
       --���������J�E���g
       gn_les_add_normal_cnt := SQL%ROWCOUNT;
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
  END insert_les_trn_add_data;
--
  /**********************************************************************************
   * Procedure Name   : get_deprn_method
   * Description      : ���p���@�擾 (A-8)
   ***********************************************************************************/
  PROCEDURE get_deprn_method(
     it_contract_line_id   IN  xxcff_contract_histories.contract_line_id%TYPE  -- 1.�_�񖾍�ID
    ,it_category_ccid      IN  fa_categories.category_id%TYPE                  -- 2.���Y�J�e�S��CCID
    ,it_lease_kind         IN  xxcff_contract_histories.lease_kind%TYPE        -- 3.���[�X���
    ,it_contract_date      IN  xxcff_contract_headers.contract_date%TYPE       -- 4.���[�X�_���
    ,ot_deprn_method       OUT fa_category_book_defaults.deprn_method%TYPE     -- 5.���p���@
-- T1_0759 2009/04/23 ADD START --
    ,ot_life_in_months     OUT fa_category_book_defaults.life_in_months%TYPE   -- 6.�v�Z����
-- T1_0759 2009/04/23 ADD END   --
    ,ov_errbuf             OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode            OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg             OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_deprn_method'; -- �v���O������
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
    -- ���b�Z�[�W�p������(�_�񖾍ד���ID)
    lv_str_ctrt_line_id VARCHAR2(50);
    -- ���b�Z�[�W�p������(���Y�J�e�S��CCID)
    lv_str_cat_ccid     VARCHAR2(50);
    -- �G���[�L�[���
    lv_error_key        VARCHAR2(5000);
    -- ���Y�䒠��
    lt_book_type_code xxcff_lease_kind_v.book_type_code%TYPE;
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
    BEGIN
      SELECT
             cat_deflt.deprn_method   AS deprn_method     -- ���p���@
            ,les_kind.book_type_code  AS book_type_code   -- ���Y�䒠��
-- T1_0759 2009/04/23 ADD START --
            ,cat_deflt.life_in_months AS life_in_months   -- �v�Z����
-- T1_0759 2009/04/23 ADD END   --
      INTO
             ot_deprn_method                     -- ���p���@
            ,lt_book_type_code                   -- ���Y�䒠��
-- T1_0759 2009/04/23 ADD START --
            ,ot_life_in_months                   -- �v�Z����
-- T1_0759 2009/04/23 ADD END   --

      FROM
             fa_categories_b            cat       -- ���Y�J�e�S���}�X�^
            ,fa_category_book_defaults  cat_deflt -- ���Y�J�e�S�����p�
            ,xxcff_lease_kind_v         les_kind  -- ���[�X��ރr���[
      WHERE
             cat.category_id           = it_category_ccid
        AND  cat.category_id           = cat_deflt.category_id
        AND  cat_deflt.book_type_code  = les_kind.book_type_code
        AND  les_kind.lease_kind_code  = it_lease_kind
        AND  cat_deflt.start_dpis     <= it_contract_date
        AND  NVL(cat_deflt.end_dpis,
                   it_contract_date)  >= it_contract_date
        ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --���b�Z�[�W�p������擾
        lv_str_ctrt_line_id := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                                ,cv_msg_013a20_t_027) -- �g�[�N��(�_�񖾍ד���ID)
                                                                ,1
                                                                ,5000);
        lv_str_cat_ccid := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                            ,cv_msg_013a20_t_028) -- �g�[�N��(���Y�J�e�S��CCID)
                                                            ,1
                                                            ,5000);
        --�G���[�L�[���쐬(�����񌋍�)
        lv_error_key :=         lv_str_ctrt_line_id ||'='|| it_contract_line_id
                        ||','|| lv_str_cat_ccid     ||'='|| it_category_ccid;
--
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_013a20_m_013  -- ���p���@�擾�G���[
                                                      ,cv_tkn_table         -- �g�[�N��'TABLE_NAME'
                                                      ,cv_msg_013a20_t_026  -- ���p���@
                                                      ,cv_tkn_info          -- �g�[�N��'INFO'
                                                      ,lv_error_key)        -- �G���[�L�[���
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
  END get_deprn_method;
--
  /**********************************************************************************
   * Procedure Name   : proc_les_trn_add_data�i���[�v���j
   * Description      : ���[�X���(�ǉ�)�f�[�^���� (A-5)�`(A-10)
   ***********************************************************************************/
  PROCEDURE proc_les_trn_add_data(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h                    --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2)    --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_les_trn_add_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
-- T1_0759 2009/04/23 ADD START --
    ln_lease_period  NUMBER(4);
-- T1_0759 2009/04/23 ADD END   --
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���C�����[�v�����@
    --==============================================================
    <<les_trn_add_loop>>
    FOR ln_loop_cnt IN 1 .. g_contract_header_id_tab.COUNT LOOP
--
      --==============================================================
      --���Y�J�e�S��CCID�擾 (A-5)
      --==============================================================
-- T1_0759 2009/04/23 ADD START --
      --���[�X���Ԃ��Z�o����
      ln_lease_period := g_payment_frequency_tab(ln_loop_cnt)  / cv_months;
-- T1_0759 2009/04/23 ADD END   --
      xxcff_common1_pkg.chk_fa_category(
         iv_segment1      => g_asset_category_tab(ln_loop_cnt) -- ���Y���
-- T1_1428 MOD START 2009/06/16 Ver1.5 by Yuuki Nakamura
--      ,iv_segment3      => g_les_asset_acct_tab(ln_loop_cnt) -- ���Y����
        ,iv_segment3      => NULL                              -- ���Y����
-- T1_1428 MOD END 2009/06/16 Ver1.5 by Yuuki Nakamura
        ,iv_segment4      => g_deprn_acct_tab(ln_loop_cnt)     -- ���p�Ȗ�
-- T1_0759 2009/04/23 MOD START --
--      ,iv_segment5      => g_life_in_months_tab(ln_loop_cnt) -- �ϗp�N��
        ,iv_segment5      => ln_lease_period                   -- ���[�X����
-- T1_0759 2009/04/23 MOD END   --
        ,iv_segment7      => g_lease_class_tab(ln_loop_cnt)    -- ���[�X���
        ,on_category_id   => g_category_ccid_tab(ln_loop_cnt)  -- ���Y�J�e�S��CCID
        ,ov_errbuf        => lv_errbuf                         -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode       => lv_retcode                        -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg                         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --���Ə�CCID�擾 (A-6)
      --==============================================================
      xxcff_common1_pkg.chk_fa_location(
         iv_segment2      => g_department_code_tab(ln_loop_cnt) -- �Ǘ�����
        ,iv_segment5      => g_owner_company_tab(ln_loop_cnt)   -- �{�ЍH��敪
        ,on_location_id   => g_location_ccid_tab(ln_loop_cnt)   -- ���Ə�CCID
        ,ov_errbuf        => lv_errbuf                          -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode       => lv_retcode                         -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�������p���CCID�擾 (A-7)
      --==============================================================
--
      -- �Z�O�����g�l�z��ݒ�(SEG1:���)
      IF g_owner_company_tab(ln_loop_cnt) = gv_own_comp_itoen THEN
        -- �{�ЃR�[�h�ݒ�
        g_segments_tab(1) := gv_comp_cd_itoen;
      ELSE
        -- �H��R�[�h�ݒ�
        g_segments_tab(1) := gv_comp_cd_sagara;
      END IF;
--
      -- �Z�O�����g�l�z��ݒ�(SEG3:����Ȗ�)
      g_segments_tab(3) := g_deprn_acct_tab(ln_loop_cnt);
      -- �Z�O�����g�l�z��ݒ�(SEG4:�⏕�Ȗ�)
      g_segments_tab(4) := g_deprn_sub_acct_tab(ln_loop_cnt);
--
      -- �������p���CCID�擾
      get_deprn_ccid(
         iot_segments     => g_segments_tab                  -- �Z�O�����g�l�z��
        ,ot_deprn_ccid    => g_deprn_ccid_tab(ln_loop_cnt)   -- �������p���CCID
        ,ov_errbuf        => lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode       => lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg        => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --���p���@�擾 (A-8)
      --==============================================================
      get_deprn_method(
         it_contract_line_id  => g_contract_line_id_tab(ln_loop_cnt)  -- �_�񖾍ד���ID
        ,it_category_ccid     => g_category_ccid_tab(ln_loop_cnt)     -- ���Y�J�e�S��CCID
        ,it_lease_kind        => g_lease_kind_tab(ln_loop_cnt)        -- ���[�X���
        ,it_contract_date     => g_contract_date_tab(ln_loop_cnt)     -- ���[�X�_���
        ,ot_deprn_method      => g_deprn_method_tab(ln_loop_cnt)      -- ���p���@
-- T1_0759 2009/04/23 ADD START --
        ,ot_life_in_months    => g_payment_frequency_tab(ln_loop_cnt) -- �v�Z����
-- T1_0759 2009/04/23 ADD END   --
        ,ov_errbuf            => lv_errbuf                           -- �G���[�E���b�Z�[�W           --# �Œ� # 
        ,ov_retcode           => lv_retcode                          -- ���^�[���E�R�[�h             --# �Œ� #
        ,ov_errmsg            => lv_errmsg                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP les_trn_add_loop;
--
    -- =========================================
    -- ���[�X���(�ǉ�)�o�^ (A-9)
    -- =========================================
    insert_les_trn_add_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- =========================================
    -- ���[�X�_�񖾍ח��� ��vIF�t���O�X�V (A-10)
    -- =========================================
    update_ctrct_line_acct_flag(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END proc_les_trn_add_data;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trn_add_data
   * Description      : ���[�X���(�ǉ�)�o�^�f�[�^���o (A-4)
   ***********************************************************************************/
  PROCEDURE get_les_trn_add_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trn_add_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���[�X���(�ǉ�)�J�[�\��
    CURSOR les_trn_add_cur
    IS
      SELECT
             ctrct_hist.contract_header_id AS contract_header_id  -- �_�����ID
            ,ctrct_hist.contract_line_id   AS contract_line_id    -- �_�񖾍ד���ID
            ,obj_head.object_header_id     AS object_header_id    -- ��������ID
            ,ctrct_hist.history_num        AS history_num         -- �ύX����No
            ,ctrct_head.lease_class        AS lease_class         -- ���[�X���
            ,ctrct_hist.lease_kind         AS lease_kind          -- ���[�X���
            ,les_kind.book_type_code       AS book_type_code      -- ���Y�䒠��
            ,ctrct_hist.asset_category     AS asset_category      -- ���Y���
            ,ctrct_head.comments           AS comments            -- ����
            ,ctrct_head.payment_years      AS payment_years       -- �N��(���[�X����)
            ,ctrct_hist.life_in_months     AS life_in_months      -- �@��ϗp�N��
-- T1_0893 2009/05/29 MOD START --
--          ,ctrct_head.contract_date      AS contract_date       -- ���[�X�_���
            ,ctrct_head.lease_start_date   AS contract_date       -- ���[�X�J�n��
-- T1_0893 2009/05/29 MOD END   --
            ,ctrct_hist.original_cost      AS original_cost       -- �擾���i
            ,1                             AS quantity            -- ����
            ,obj_head.department_code      AS department_code     -- �Ǘ�����
            ,obj_head.owner_company        AS owner_company       -- �{�ЍH��敪
            ,les_class.les_asset_acct      AS les_asset_acct      -- ���Y����
            ,les_class.deprn_acct          AS deprn_acct          -- �������p����
            ,les_class.deprn_sub_acct      AS deprn_sub_acct      -- �������p�⏕����
            ,ctrct_head.payment_frequency  AS payment_frequency   -- �x����
            ,NULL                          AS category_ccid       -- ���Y�J�e�S��CCID
            ,NULL                          AS location_ccid       -- ���Ə�CCID
            ,NULL                          AS deprn_ccid          -- �������p���CCID
            ,NULL                          AS deprn_method        -- ���p���@
      FROM
            xxcff_contract_histories  ctrct_hist
           ,xxcff_contract_headers    ctrct_head
           ,xxcff_object_headers      obj_head
           ,xxcff_lease_class_v       les_class
           ,xxcff_lease_kind_v        les_kind
      WHERE
            ctrct_hist.object_header_id   =   obj_head.object_header_id
        AND ctrct_head.lease_class        =   les_class.lease_class_code
        AND ctrct_hist.contract_header_id =   ctrct_head.contract_header_id
        AND ctrct_hist.contract_status    =   cv_ctrt_ctrt                            -- �_��
        AND ctrct_hist.lease_kind         IN  (cv_lease_kind_fin, cv_lease_kind_lfin) -- Fin,��Fin
        AND ctrct_hist.lease_kind         =   les_kind.lease_kind_code
        AND ctrct_hist.accounting_if_flag =   cv_if_yet                               -- �����M
        AND ctrct_head.first_payment_date <=  LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM'))
        FOR UPDATE OF ctrct_hist.contract_header_id
        NOWAIT
      ;
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
    --==============================================================
    --�R���N�V�����폜
    --==============================================================
    delete_collections(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --==============================================================
    --���C���f�[�^���o
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN les_trn_add_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH les_trn_add_cur
    BULK COLLECT INTO  g_contract_header_id_tab -- �_�����ID
                      ,g_contract_line_id_tab   -- �_�񖾍ד���ID
                      ,g_object_header_id_tab   -- ��������ID
                      ,g_history_num_tab        -- �ύX����No
                      ,g_lease_class_tab        -- ���[�X���
                      ,g_lease_kind_tab         -- ���[�X���
                      ,g_book_type_code_tab     -- ���Y�䒠��
                      ,g_asset_category_tab     -- ���Y���
                      ,g_comments_tab           -- ����
                      ,g_payment_years_tab      -- �N��(���[�X����)
                      ,g_life_in_months_tab     -- �@��ϗp�N��
                      ,g_contract_date_tab      -- ���[�X�_���
                      ,g_original_cost_tab      -- �擾���i
                      ,g_quantity_tab           -- ����
                      ,g_department_code_tab    -- �Ǘ�����
                      ,g_owner_company_tab      -- �{�ЍH��敪
                      ,g_les_asset_acct_tab     -- ���Y����
                      ,g_deprn_acct_tab         -- �������p����
                      ,g_deprn_sub_acct_tab     -- �������p�⏕����
                      ,g_payment_frequency_tab  -- �x����
                      ,g_category_ccid_tab      -- ���Y�J�e�S��CCID
                      ,g_location_ccid_tab      -- ���Ə�CCID
                      ,g_deprn_ccid_tab         -- �������p���CCID
                      ,g_deprn_method_tab       -- �������p���@
    ;
    --�Ώی����J�E���g
    gn_les_add_target_cnt := g_contract_header_id_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE les_trn_add_cur;
--
    IF ( gn_les_add_target_cnt = 0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_013a20_t_031) -- ���[�X����i�ǉ��j���
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --���O(�V�X�e���Ǘ��җp���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --���b�Z�[�W(���[�U�p���b�Z�[�W)�o��
        ,buff   => lv_warnmsg
      );
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      -- �J�[�\���N���[�Y
      IF (les_trn_add_cur%ISOPEN) THEN
        CLOSE les_trn_add_cur;
      END IF;
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_013a20_m_012  -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,cv_msg_013a20_t_023) -- ���[�X�_�񖾍ח���
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_add_cur%ISOPEN) THEN
        CLOSE les_trn_add_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_add_cur%ISOPEN) THEN
        CLOSE les_trn_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (les_trn_add_cur%ISOPEN) THEN
        CLOSE les_trn_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_les_trn_add_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : ��v���ԃ`�F�b�N(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- �v���O������
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
    -- ���Y�䒠��
    lv_book_type_code VARCHAR(100);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR period_cur
    IS
      SELECT
             fdp.deprn_run        AS deprn_run      -- �������p���s�t���O
            ,fdp.book_type_code   AS book_type_code -- ���Y�䒠��
        FROM
             fa_deprn_periods     fdp   -- �������p����
            ,xxcff_lease_kind_v   xlk   -- ���[�X��ރr���[
       WHERE
             xlk.lease_kind_code IN (cv_lease_kind_fin, cv_lease_kind_lfin)
         AND fdp.book_type_code  =  xlk.book_type_code
         AND fdp.period_name     =  gv_period_name
           ;
--
    -- *** ���[�J���E���R�[�h ***
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
    -- �J�[�\���I�[�v��
    OPEN period_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH period_cur
    BULK COLLECT INTO  g_deprn_run_tab      -- �������p���s�t���O
                      ,g_book_type_code_tab -- ���Y�䒠��
    ;
    -- �J�[�\���N���[�Y
    CLOSE period_cur;
--
    -- ��v���Ԃ̎擾�������[�����˃G���[
    IF g_deprn_run_tab.COUNT = 0 THEN
      RAISE chk_period_expt;
    END IF;
--
    <<chk_period_loop>>
    FOR ln_loop_cnt IN 1 .. g_deprn_run_tab.COUNT LOOP
--
      -- �������p�����s����Ă���˃G���[
      IF g_deprn_run_tab(ln_loop_cnt) = 'Y' THEN
        lv_book_type_code := g_book_type_code_tab(ln_loop_cnt);
        RAISE chk_period_expt;
      END IF;
--
    END LOOP chk_period_loop;
--
  EXCEPTION
--
    -- *** ��v���ԃ`�F�b�N�G���[�n���h�� ***
    WHEN chk_period_expt THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_011  -- ��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_bk_type       -- �g�[�N��'BOOK_TYPE_CODE'
                                                    ,lv_book_type_code    -- ���Y�䒠��
                                                    ,cv_tkn_period        -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)      -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : �v���t�@�C���擾����(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- XXCFF:��ЃR�[�h_�{��
    gv_comp_cd_itoen := FND_PROFILE.VALUE(cv_comp_cd_itoen);
    IF (gv_comp_cd_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_010) -- XXCFF:��ЃR�[�h_�{��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:��ЃR�[�h_���ǉ�v
    gv_comp_cd_sagara := FND_PROFILE.VALUE(cv_comp_cd_sagara);
    IF (gv_comp_cd_sagara IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_011) -- XXCFF:��ЃR�[�h_���ǉ�v
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:����R�[�h_��������
    gv_dep_cd_chosei := FND_PROFILE.VALUE(cv_dep_cd_chosei);
    IF (gv_dep_cd_chosei IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_012) -- XXCFF:����R�[�h_��������
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�ڋq�R�[�h_��`�Ȃ�
    gv_ptnr_cd_dammy := FND_PROFILE.VALUE(cv_ptnr_cd_dammy);
    IF (gv_ptnr_cd_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_013) -- XXCFF:�ڋq�R�[�h_��`�Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:��ƃR�[�h_��`�Ȃ�
    gv_busi_cd_dammy := FND_PROFILE.VALUE(cv_busi_cd_dammy);
    IF (gv_busi_cd_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_014) -- XXCFF:��ƃR�[�h_��`�Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�\��1�R�[�h_��`�Ȃ�
    gv_project_dammy := FND_PROFILE.VALUE(cv_project_dammy);
    IF (gv_project_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_015) -- XXCFF:�\��1�R�[�h_��`�Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�\��2�R�[�h_��`�Ȃ�
    gv_future_dammy := FND_PROFILE.VALUE(cv_future_dammy);
    IF (gv_future_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_016) -- XXCFF:�\��2�R�[�h_��`�Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:���Y�J�e�S��_���p���@
    gv_cat_dprn_lease := FND_PROFILE.VALUE(cv_cat_dprn_lease);
    IF (gv_cat_dprn_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_017) -- XXCFF:���Y�J�e�S��_���p���@
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�\���n_�\���Ȃ�
    gv_dclr_place_no_report := FND_PROFILE.VALUE(cv_dclr_place_no_report);
    IF (gv_dclr_place_no_report IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_018) -- XXCFF:�\���n_�\���Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:���Ə�_�\���Ȃ�
    gv_mng_place_dammy := FND_PROFILE.VALUE(cv_mng_place_dammy);
    IF (gv_mng_place_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_019) -- XXCFF:���Ə�_�\���Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�ꏊ_�\���Ȃ�
    gv_place_dammy := FND_PROFILE.VALUE(cv_place_dammy);
    IF (gv_place_dammy IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_020) -- XXCFF:�ꏊ_�\���Ȃ�
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�����@_����
    gv_prt_conv_cd_st := FND_PROFILE.VALUE(cv_prt_conv_cd_st);
    IF (gv_prt_conv_cd_st IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_021) -- XXCFF:�����@_����
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�����@_����
    gv_prt_conv_cd_ed := FND_PROFILE.VALUE(cv_prt_conv_cd_ed);
    IF (gv_prt_conv_cd_ed IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_022) -- XXCFF:�����@_����
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�{�ЍH��敪_�{��
    gv_own_comp_itoen := FND_PROFILE.VALUE(cv_own_comp_itoen);
    IF (gv_own_comp_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_024) -- XXCFF:�{�ЍH��敪_�{��
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�{�ЍH��敪_�H��
    gv_own_comp_sagara := FND_PROFILE.VALUE(cv_own_comp_sagara);
    IF (gv_own_comp_sagara IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_013a20_t_025) -- XXCFF:�{�ЍH��敪_�H��
                                                    ,1
                                                    ,5000);
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
    IF (lv_retcode <> ov_retcode) THEN
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
    IF (lv_retcode <> ov_retcode) THEN
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
    IF (lv_retcode <> ov_retcode) THEN
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     -- 1.��v���Ԗ�
    ov_errbuf       OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt            := 0;
    gn_normal_cnt            := 0;
    gn_error_cnt             := 0;
    gn_warn_cnt              := 0;
    gn_les_add_target_cnt    := 0;
    gn_les_add_normal_cnt    := 0;
    gn_les_add_error_cnt     := 0;
    gn_les_trnsf_target_cnt  := 0;
    gn_les_trnsf_normal_cnt  := 0;
    gn_les_trnsf_error_cnt   := 0;
    gn_les_retire_target_cnt := 0;
    gn_les_retire_normal_cnt := 0;
    gn_les_retire_error_cnt  := 0;
    gn_fa_oif_target_cnt     := 0;
    gn_fa_oif_error_cnt      := 0;
    gn_add_oif_ins_cnt       := 0;
    gn_trnsf_oif_ins_cnt     := 0;
    gn_retire_oif_ins_cnt    := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- IN�p�����[�^(��v���Ԗ�)���O���[�o���ϐ��ɐݒ�
    gv_period_name := iv_period_name;
--
    -- ===============================
    -- �������� (A-1)
    -- ===============================
    init(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �v���t�@�C���l�擾 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��v���ԃ`�F�b�N (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���[�X���(�ǉ�)�o�^�f�[�^���o (A-4)
    -- =========================================
    get_les_trn_add_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���[�X���(�ǉ�)�f�[�^���� (A-5)�`(A-10)
    -- =========================================
    proc_les_trn_add_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���[�X���(�U��)�o�^�f�[�^���o (A-11)
    -- =========================================
    get_les_trn_trnsf_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���[�X���(�U��)�f�[�^���� (A-12)�`(A-16)
    -- =========================================
    proc_les_trn_trnsf_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���[�X���(���)�o�^�f�[�^���o (A-17)
    -- =========================================
    get_les_trn_retire_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���[�X���(���)�o�^ (A-18)
    -- =========================================
    insert_les_trn_ritire_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- ���[�X�_�񖾍ח��� ��vIF�t���O�X�V (A-19)
    -- ==============================================
    update_ritire_data_acct_flag(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- FAOIF�o�^�f�[�^���o (A-20)
    -- =========================================
    get_les_trns_data(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �ǉ�OIF�o�^ (A-21)
    -- =========================================
    insert_add_oif(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- �U��OIF�o�^ (A-22)
    -- =========================================
    insert_trnsf_oif(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- ���E���pOIF�o�^ (A-23)
    -- =========================================
    insert_retire_oif(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==============================================
    -- ���[�X��� FA�A�g�t���O�X�V (A-24)
    -- ==============================================
    update_les_trns_fa_if_flag(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
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
  PROCEDURE main(
    errbuf         OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode        OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_period_name IN  VARCHAR2       -- 1.��v���Ԗ�
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
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
       iv_period_name -- ��v���Ԗ�
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --�G���[���̏o�͌����ݒ�
    --===============================================================
    IF (lv_retcode <> cv_status_normal) THEN
      -- �����������[���ɃN���A����
      gn_les_add_normal_cnt    := 0;
      gn_les_trnsf_normal_cnt  := 0;
      gn_les_retire_normal_cnt := 0;
      gn_add_oif_ins_cnt       := 0;
      gn_trnsf_oif_ins_cnt     := 0;
      gn_retire_oif_ins_cnt    := 0;
      -- �G���[�����ɑΏی�����ݒ肷��
      gn_les_add_error_cnt    := gn_les_add_target_cnt;
      gn_les_trnsf_error_cnt  := gn_les_trnsf_target_cnt;
      gn_les_retire_error_cnt := gn_les_retire_target_cnt;
      gn_fa_oif_error_cnt     := gn_fa_oif_target_cnt;
      
    END IF;
--
    --===============================================================
    --���[�X���(�ǉ�)�o�^�����ɂ����錏���o��
    --===============================================================
    --���[�X���(�ǉ�)�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_014
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_add_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_add_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_add_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --===============================================================
    --���[�X���(�U��)�o�^�����ɂ����錏���o��
    --===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���[�X���(�U��)�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_015
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trnsf_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trnsf_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trnsf_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --===============================================================
    --���[�X���(���)�o�^�����ɂ����錏���o��
    --===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���[�X���(���)�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_016
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_retire_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_retire_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_retire_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --===============================================================
    --FAOIF�o�^�����ɂ����錏���o��
    --===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --FAOIF�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_017
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_fa_oif_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_add_oif_ins_cnt + gn_trnsf_oif_ins_cnt + gn_retire_oif_ins_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_fa_oif_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
END XXCFF013A20C;
/
