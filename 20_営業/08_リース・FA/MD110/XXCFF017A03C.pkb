CREATE OR REPLACE PACKAGE BODY XXCFF017A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF017A03C(body)
 * Description      : ���̋@���FA�A�g�������[�X(FA)
 * MD.050           : MD050_CFF_017_A03_���̋@���FA�A�g����
 * Version          : 1.0
 *
 * Program List
 * ----------------------------- ----------------------------------------------------------
 *  Name                          Description
 * ----------------------------- ----------------------------------------------------------
 *  init                          ��������                                  (A-1)
 *  get_profile_values            �v���t�@�C���l�擾                        (A-2)
 *  get_period                    ��v���ԃ`�F�b�N                          (A-3)
 *  get_vd_object_add_data        ���̋@�����i���m��j�o�^�f�[�^���o        (A-4)
 *  get_vd_object_trnsf_data      ���̋@�����i�ړ��j�o�^�f�[�^���o          (A-5)
 *  get_vd_object_modify_data     ���̋@�����i�C���j�o�^�f�[�^���o          (A-6)
 *  get_vd_object_ritire_data     ���̋@�����i�����p���m��j�o�^�f�[�^���o  (A-7)
 *  get_deprn_ccid                �������p���CCID�擾                    (A-8-1)
 *  update_vd_object_headers      ���̋@�����Ǘ��̍X�V                      (A-8-2)
 *  update_vd_object_histories    ���̋@���������̍X�V                      (A-8-3)
 *  insert_vd_object_histories    ���̋@���������̍쐬                      (A-8-4)
 *  chk_object_trnsf_data         �ړ��ڍ׏��ύX�`�F�b�N                  (A-8-5)
 *  submain                       ���C�������v���V�[�W��
 *  main                          �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/08/01    1.0   SCSK���H         �V�K�쐬
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
  cv_msg_part                 CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                 CONSTANT VARCHAR2(3) := '.';
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
  --*** ��v���Ԗ��`�F�b�N�G���[
  chk_period_name_expt      EXCEPTION;
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
  lock_expt              EXCEPTION;
  chk_no_data_found_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFF017A03C'; -- �p�b�P�[�W��
  cd_processing_date          CONSTANT DATE          := SYSDATE;        -- ������
  cd_fa_if_date               CONSTANT DATE          := SYSDATE;        -- FA���A�g��
  cd_od_sysdate               CONSTANT DATE          := SYSDATE;        -- �V�X�e�����t
--
  -- ***�A�v���P�[�V�����Z�k��
  cv_msg_kbn_cff   CONSTANT VARCHAR2(5) := 'XXCFF';
--
  -- ***���b�Z�[�W��(�{��)
  cv_msg_017a03_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; -- �v���t�@�C���擾�G���[
  cv_msg_017a03_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; -- ��v���ԃ`�F�b�N�G���[  
  cv_msg_017a03_m_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; -- ���b�N�G���[
  cv_msg_017a03_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00101'; -- �擾�G���[
  cv_msg_017a03_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00214'; -- ���̋@�����i���m��j�쐬���b�Z�[�W
  cv_msg_017a03_m_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00215'; -- ���̋@�����i�ړ��j�쐬���b�Z�[�W
  cv_msg_017a03_m_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00216'; -- ���̋@�����i�C���j�쐬���b�Z�[�W
  cv_msg_017a03_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00217'; -- ���̋@�����i�����p���m��j�쐬���b�Z�[�W
  cv_msg_017a03_m_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; -- �擾�Ώۃf�[�^�������b�Z�[�W
  cv_msg_017a03_m_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00189'; -- �Q�ƃ^�C�v�擾�G���[
  cv_msg_017a03_m_020 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00225'; -- ���̋@����FA�A�g�G���[
  cv_msg_017a03_m_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00228'; -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
  cv_msg_017a03_m_022 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00229'; -- ���̋@����FA�A�g���ړ��t�`�F�b�N�G���[
  cv_msg_017a03_m_023 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00235'; -- ���̋@�����i�ړ��j�ύX���ڂȂ��x��
  cv_msg_017a03_m_024 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00236'; -- �ŐV��v���Ԗ��擾�x��
--
  -- ***���b�Z�[�W��(�g�[�N��)
  cv_msg_017a03_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50076'; -- XXCFF:��ЃR�[�h_�{��
  cv_msg_017a03_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50078'; -- XXCFF:����R�[�h_��������
  cv_msg_017a03_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50228'; -- XXCFF:�䒠���_�Œ莑�Y�䒠
  cv_msg_017a03_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50231'; -- ���̋@�����i���m��j���
  cv_msg_017a03_t_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50260'; -- ���̋@�����Ǘ�
  cv_msg_017a03_t_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50230'; -- �������p����
  cv_msg_017a03_t_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50232'; -- ���̋@�����i�ړ��j���
  cv_msg_017a03_t_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50235'; -- �Œ莑�Y�i�ړ��j���
  cv_msg_017a03_t_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50238'; -- �J�����_���ԃN���[�Y��
  cv_msg_017a03_t_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50233'; -- ���̋@�����i�C���j���
  cv_msg_017a03_t_020 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50236'; -- �Œ莑�Y�i�C���j���
  cv_msg_017a03_t_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50234'; -- ���̋@�����i�����p�j���
  cv_msg_017a03_t_022 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50237'; -- �Œ莑�Y�i�����p�j���
  cv_msg_017a03_t_023 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50256'; -- ���Y�ڍ׏��
  cv_msg_017a03_t_024 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50257'; -- ���̋@���Y�J�e�S���Œ�l
  cv_msg_017a03_t_025 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50261'; -- ���[�J�[�� �@�� �N��
  cv_msg_017a03_t_026 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50240'; -- �@��敪
  cv_msg_017a03_t_027 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50262'; -- ���Ƌ��p��
  cv_msg_017a03_t_028 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50263'; -- �擾���i
  cv_msg_017a03_t_029 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50181'; -- ����
  cv_msg_017a03_t_030 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50264'; -- �ړ���
  cv_msg_017a03_t_031 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50246'; -- �\���n
  cv_msg_017a03_t_032 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50243'; -- �Ǘ�����
  cv_msg_017a03_t_033 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50265'; -- ���Ə�
  cv_msg_017a03_t_034 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50266'; -- �ݒu�ꏊ
  cv_msg_017a03_t_035 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50267'; -- �{��/�H��敪
  cv_msg_017a03_t_036 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50272'; -- ���E���p��
  cv_msg_017a03_t_037 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50093'; -- XXCFF: �����@_����
--
  -- ***�g�[�N����
  cv_tkn_prof        CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_bk_type     CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period      CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_table       CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_info        CONSTANT VARCHAR2(20) := 'INFO';
  cv_tkn_get_data    CONSTANT VARCHAR2(20) := 'GET_DATA';
  cv_tkn_lookup_type CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';
  cv_tkn_param_val1  CONSTANT VARCHAR2(20) := 'PARAM_VAL1';
  cv_tkn_param_val2  CONSTANT VARCHAR2(20) := 'PARAM_VAL2';
  cv_tkn_param_name  CONSTANT VARCHAR2(20) := 'PARAM_NAME';
--
  -- ***�v���t�@�C��
  cv_comp_cd_itoen        CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_ITOEN';     -- ��ЃR�[�h_�{��
  cv_dep_cd_chosei        CONSTANT VARCHAR2(30) := 'XXCFF1_DEP_CD_CHOSEI';        -- ����R�[�h_��������
  cv_fixed_asset_register CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSET_REGISTER'; -- �䒠���_�Œ莑�Y�䒠
  cv_prt_conv_cd_ed       CONSTANT VARCHAR2(30) := 'XXCFF1_PRT_CONV_CD_ED';       -- �����@_����
--
  -- ***�t�@�C���o��
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT'; -- ���b�Z�[�W�o��
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';    -- ���O�o��
--
  -- ***�X�e�[�^�X/�����敪
  cv_status_101    CONSTANT VARCHAR2(3) := '101'; -- ���m��
  cv_status_102    CONSTANT VARCHAR2(3) := '102'; -- �m���
  cv_status_103    CONSTANT VARCHAR2(3) := '103'; -- �ړ�
  cv_status_104    CONSTANT VARCHAR2(3) := '104'; -- �C��
  cv_status_105    CONSTANT VARCHAR2(3) := '105'; -- �����p���m��
  cv_status_106    CONSTANT VARCHAR2(3) := '106'; -- �����p
--
  -- ***�������p��Z�O�����g �_�~�[�l
  cv_sub_acct_dummy CONSTANT VARCHAR2(30) := '00000';     -- �⏕�Ȗ�
  cv_ptnr_cd_dummy  CONSTANT VARCHAR2(30) := '000000000'; -- �ڋq�R�[�h
  cv_busi_cd_dummy  CONSTANT VARCHAR2(30) := '000000';    -- ��ƃR�[�h
  cv_project_dummy  CONSTANT VARCHAR2(30) := '0';         -- �\��1
  cv_future_dummy   CONSTANT VARCHAR2(30) := '0';         -- �\��2
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  TYPE g_object_header_id_ttype        IS TABLE OF xxcff_vd_object_headers.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_internal_id_ttype      IS TABLE OF xxcff_vd_object_headers.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_code_ttype             IS TABLE OF xxcff_vd_object_headers.object_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_owner_company_type_ttype      IS TABLE OF xxcff_vd_object_headers.owner_company_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_department_code_ttype         IS TABLE OF xxcff_vd_object_headers.department_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_machine_type_ttype            IS TABLE OF xxcff_vd_object_headers.machine_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_manufacturer_name_ttype       IS TABLE OF xxcff_vd_object_headers.manufacturer_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_model_ttype                   IS TABLE OF xxcff_vd_object_headers.model%TYPE INDEX BY PLS_INTEGER;
  TYPE g_age_type_ttype                IS TABLE OF xxcff_vd_object_headers.age_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payables_units_ttype          IS TABLE OF xxcff_vd_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;
  TYPE g_fixed_assets_units_ttype      IS TABLE OF xxcff_vd_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;
  TYPE g_transaction_units_ttype       IS TABLE OF xxcff_vd_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;
  TYPE g_date_placed_in_service_ttype  IS TABLE OF xxcff_vd_object_headers.date_placed_in_service%TYPE INDEX BY PLS_INTEGER;
  TYPE g_assets_cost_ttype             IS TABLE OF xxcff_vd_object_headers.assets_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_cost_ttype                    IS TABLE OF xxcff_vd_object_headers.assets_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payables_cost_ttype           IS TABLE OF xxcff_vd_object_headers.assets_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_original_cost_ttype           IS TABLE OF xxcff_vd_object_headers.assets_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_assets_date_ttype             IS TABLE OF xxcff_vd_object_headers.assets_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_cat_attribute2_ttype          IS TABLE OF xxcff_vd_object_headers.assets_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_moved_date_ttype              IS TABLE OF xxcff_vd_object_headers.moved_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_installation_address_ttype    IS TABLE OF xxcff_vd_object_headers.installation_address%TYPE INDEX BY PLS_INTEGER;
  TYPE g_dclr_place_ttype              IS TABLE OF xxcff_vd_object_headers.dclr_place%TYPE INDEX BY PLS_INTEGER;
  TYPE g_location_ttype                IS TABLE OF xxcff_vd_object_headers.location%TYPE INDEX BY PLS_INTEGER;
  TYPE g_date_retired_ttype            IS TABLE OF xxcff_vd_object_headers.date_retired%TYPE INDEX BY PLS_INTEGER;
  TYPE g_proceeds_of_sale_ttype        IS TABLE OF xxcff_vd_object_headers.proceeds_of_sale%TYPE INDEX BY PLS_INTEGER;
  TYPE g_cost_of_removal_ttype         IS TABLE OF xxcff_vd_object_headers.cost_of_removal%TYPE INDEX BY PLS_INTEGER;
  TYPE g_category_ccid_ttype           IS TABLE OF fa_categories.category_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_ccid_ttype              IS TABLE OF gl_code_combinations.code_combination_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_location_ccid_ttype           IS TABLE OF fa_locations.location_id%TYPE INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  g_object_header_id_tab         g_object_header_id_ttype;       -- ����ID
  g_object_internal_id_tab       g_object_internal_id_ttype;     -- ���̋@��������ID
  g_object_code_tab              g_object_code_ttype;            -- �����R�[�h
  g_owner_company_type_tab       g_owner_company_type_ttype;     -- �{��/�H��敪
  g_department_code_tab          g_department_code_ttype;        -- �Ǘ�����
  g_machine_type_tab             g_machine_type_ttype;           -- �@��敪
  g_manufacturer_name_tab        g_manufacturer_name_ttype;      -- ���[�J��
  g_model_tab                    g_model_ttype;                  -- �@��
  g_age_type_tab                 g_age_type_ttype;               -- �N��
  g_payables_units_tab           g_payables_units_ttype;         -- AP����
  g_fixed_assets_units_tab       g_fixed_assets_units_ttype;     -- �P�ʐ���
  g_transaction_units_tab        g_transaction_units_ttype;      -- �P��
  g_date_placed_in_service_tab   g_date_placed_in_service_ttype; -- ���Ƌ��p��
  g_assets_cost_tab              g_assets_cost_ttype;            -- �擾���i
  g_cost_tab                     g_cost_ttype;                   -- �擾���z
  g_payables_cost_tab            g_payables_cost_ttype;          -- ���Y�����擾���z
  g_original_cost_tab            g_original_cost_ttype;          -- �����擾���z
  g_assets_date_tab              g_assets_date_ttype;            -- �擾��
  g_cat_attribute2_tab           g_cat_attribute2_ttype;         -- �J�e�S��DFF2
  g_moved_date_tab               g_moved_date_ttype;             -- �ړ���
  g_installation_address_tab     g_installation_address_ttype;   -- �ݒu�ꏊ
  g_dclr_place_tab               g_dclr_place_ttype;             -- �\���n
  g_location_tab                 g_location_ttype;               -- ���Ə�
  g_date_retired_tab             g_date_retired_ttype;           -- ������p��
  g_proceeds_of_sale_tab         g_proceeds_of_sale_ttype;       -- ���p���z
  g_cost_of_removal_tab          g_cost_of_removal_ttype;        -- �P����p
  g_category_ccid_tab            g_category_ccid_ttype;          -- ���Y�J�e�S��CCID
  g_deprn_ccid_tab               g_deprn_ccid_ttype;             -- �������p���CCID
  g_location_ccid_tab            g_location_ccid_ttype;          -- ���Ə��t���b�N�X�t�B�[���hCCID
--
  -- ***��������
  gn_vd_target_cnt         NUMBER;     -- �������̃��R�[�h
  -- ���̋@����(���m��)�o�^�����ɂ����錏��
  gn_vd_add_target_cnt     NUMBER;     -- �Ώی���
  gn_vd_add_normal_cnt     NUMBER;     -- ���팏��
  gn_vd_add_warn_cnt       NUMBER;     -- �x������
  gn_vd_add_error_cnt      NUMBER;     -- �G���[����
  -- ���̋@����(�ړ�)�o�^�����ɂ����錏��
  gn_vd_trnsf_target_cnt   NUMBER;     -- �Ώی���
  gn_vd_trnsf_normal_cnt   NUMBER;     -- ���팏��
  gn_vd_trnsf_warn_cnt     NUMBER;     -- �x������
  gn_vd_trnsf_error_cnt    NUMBER;     -- �G���[����
  -- ���̋@����(�C��)�o�^�����ɂ����錏��
  gn_vd_modify_target_cnt  NUMBER;     -- �Ώی���
  gn_vd_modify_normal_cnt  NUMBER;     -- ���팏��
  gn_vd_modify_warn_cnt    NUMBER;     -- �x������
  gn_vd_modify_error_cnt   NUMBER;     -- �G���[����
  -- ���̋@����(�����p���m��)�o�^�����ɂ����錏��
  gn_vd_retire_target_cnt  NUMBER;     -- �Ώی���
  gn_vd_retire_normal_cnt  NUMBER;     -- ���팏��
  gn_vd_retire_warn_cnt    NUMBER;     -- �x������
  gn_vd_retire_error_cnt   NUMBER;     -- �G���[����
--
  -- �����l���
  g_init_rec xxcff_common1_pkg.init_rtype;
--
  -- �p�����[�^��v���Ԗ�
  gv_period_name VARCHAR2(100);
--
  -- ***�v���t�@�C���l
  gv_comp_cd_itoen         VARCHAR2(100); -- ��ЃR�[�h_�{��
  gv_dep_cd_chosei         VARCHAR2(100); -- ����R�[�h_��������
  gv_fixed_asset_register  VARCHAR2(100); -- �䒠���_�Œ莑�Y�䒠
  gv_prt_conv_cd_ed        VARCHAR2(100); -- �����@_����
--
  -- �Z�O�����g�l�z��(EBS�W���֐�fnd_flex_ext�p)
  g_segments_tab  fnd_flex_ext.segmentarray;
--
  -- �J�����_���ԃN���[�Y��
  g_cal_per_close_date     DATE;

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
    g_object_header_id_tab.DELETE;
    g_object_internal_id_tab.DELETE;
    g_object_code_tab.DELETE;
    g_owner_company_type_tab.DELETE;
    g_department_code_tab.DELETE;
    g_machine_type_tab.DELETE;
    g_manufacturer_name_tab.DELETE;
    g_model_tab.DELETE;
    g_age_type_tab.DELETE;
    g_payables_units_tab.DELETE;
    g_fixed_assets_units_tab.DELETE;
    g_transaction_units_tab.DELETE;
    g_date_placed_in_service_tab.DELETE;
    g_assets_cost_tab.DELETE;
    g_cost_tab.DELETE;
    g_payables_cost_tab.DELETE;
    g_original_cost_tab.DELETE;
    g_assets_date_tab.DELETE;
    g_cat_attribute2_tab.DELETE;
    g_moved_date_tab.DELETE;
    g_installation_address_tab.DELETE;
    g_dclr_place_tab.DELETE;
    g_location_tab.DELETE;
    g_date_retired_tab.DELETE;
    g_proceeds_of_sale_tab.DELETE;
    g_cost_of_removal_tab.DELETE;
    g_category_ccid_tab.DELETE;
    g_deprn_ccid_tab.DELETE;
    g_location_ccid_tab.DELETE;
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
   * Procedure Name   : insert_vd_object_histories
   * Description      : ���̋@���������̍쐬 (A-8-4)
   ***********************************************************************************/
  PROCEDURE insert_vd_object_histories(
     iv_object_header_id  IN     NUMBER    -- ����ID
    ,iv_object_status     IN     NUMBER    -- �����敪
    ,ov_errbuf            OUT    VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT    VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT    VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_vd_object_histories'; -- �v���O������
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
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
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
    -- ���̋@���������̍쐬
    INSERT INTO xxcff_vd_object_histories(
      object_header_id       -- ����ID
     ,object_code            -- �����R�[�h
     ,history_num            -- ����ԍ�
     ,process_type           -- �����敪
     ,process_date           -- ������
     ,object_status          -- �����X�e�[�^�X
     ,owner_company_type     -- �{��/�H��敪
     ,department_code        -- �Ǘ�����
     ,machine_type           -- �@��敪
     ,manufacturer_name      -- ���[�J��
     ,model                  -- �@��
     ,age_type               -- �N��
     ,customer_code          -- �ڋq�R�[�h
     ,quantity               -- ����
     ,date_placed_in_service -- ���Ƌ��p��
     ,assets_cost            -- �擾���i
     ,month_lease_charge     -- ���z���[�X��
     ,re_lease_charge        -- �ă��[�X��
     ,assets_date            -- �擾��
     ,moved_date             -- �ړ���
     ,installation_place     -- �ݒu��
     ,installation_address   -- �ݒu�ꏊ
     ,dclr_place             -- �\���n
     ,location               -- ���Ə�
     ,date_retired           -- ������p��
     ,proceeds_of_sale       -- ���p���z
     ,cost_of_removal        -- �P����p
     ,retired_flag           -- �����p�m��t���O
     ,ib_if_date             -- �ݒu�x�[�X���A�g��
     ,fa_if_date             -- FA���A�g��
     ,fa_if_flag             -- FA�A�g�t���O
     ,created_by             -- �쐬��
     ,creation_date          -- �쐬��
     ,last_updated_by        -- �ŏI�X�V��
     ,last_update_date       -- �ŏI�X�V��
     ,last_update_login      -- �ŏI�X�V���O�C��
     ,request_id             -- �v��ID
     ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
     ,program_id             -- �R���J�����g�E�v���O����ID
     ,program_update_date    -- �v���O�����X�V��
    )
    SELECT
      voh.object_header_id        -- ����ID
     ,voh.object_code             -- �����R�[�h
     ,(
      SELECT MAX(vohi.history_num) + 1
        FROM xxcff_vd_object_histories vohi
       WHERE voh.object_header_id = vohi.object_header_id
       ) history_num              -- ����ԍ�
     ,iv_object_status            -- �����敪
     ,cd_processing_date          -- ������
     ,voh.object_status           -- �����X�e�[�^�X
     ,voh.owner_company_type      -- �{��/�H��敪
     ,voh.department_code         -- �Ǘ�����
     ,voh.machine_type            -- �@��敪
     ,voh.manufacturer_name       -- ���[�J��
     ,voh.model                   -- �@��
     ,voh.age_type                -- �N��
     ,voh.customer_code           -- �ڋq�R�[�h
     ,voh.quantity                -- ����
     ,voh.date_placed_in_service  -- ���Ƌ��p��
     ,voh.assets_cost             -- �擾���i
     ,month_lease_charge          -- ���z���[�X��
     ,re_lease_charge             -- �ă��[�X��
     ,voh.assets_date             -- �擾��
     ,voh.moved_date              -- �ړ���
     ,voh.installation_place      -- �ݒu��
     ,voh.installation_address    -- �ݒu�ꏊ
     ,voh.dclr_place              -- �\���n
     ,voh.location                -- ���Ə�
     ,voh.date_retired            -- ������p��
     ,voh.proceeds_of_sale        -- ���p���z
     ,voh.cost_of_removal         -- �P����p
     ,voh.retired_flag            -- �����p�m��t���O
     ,voh.ib_if_date              -- �ݒu�x�[�X���A�g��
     ,cd_fa_if_date               -- FA���A�g��
     ,cv_yes                      -- FA�A�g�t���O
     ,cn_created_by               -- �쐬��
     ,cd_creation_date            -- �쐬��
     ,cn_last_updated_by          -- �ŏI�X�V��
     ,cd_last_update_date         -- �ŏI�X�V��
     ,cn_last_update_login        -- �ŏI�X�V���O�C��
     ,cn_request_id               -- �v��ID
     ,cn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
     ,cn_program_id               -- �R���J�����g�E�v���O����ID
     ,cd_program_update_date      -- �v���O�����X�V��
    FROM
           xxcff_vd_object_headers   voh
    WHERE
           voh.object_header_id = iv_object_header_id
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
  END insert_vd_object_histories;
--
  /**********************************************************************************
   * Procedure Name   : update_vd_object_histories
   * Description      : ���̋@���������̍X�V (A-8-3)
   ***********************************************************************************/
  PROCEDURE update_vd_object_histories(
     iv_object_header_id  IN     NUMBER    -- ����ID
    ,iv_object_status     IN     NUMBER    -- �����敪
    ,ov_errbuf            OUT    VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT    VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT    VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_vd_object_histories'; -- �v���O������
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
    cv_no                CONSTANT VARCHAR2(1)   := 'N';
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
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
    -- ���̋@���������̍X�V
    UPDATE xxcff_vd_object_histories
    SET
           fa_if_date             = cd_fa_if_date              -- FA���A�g��
          ,fa_if_flag             = cv_yes                     -- FA�A�g�t���O
          ,last_updated_by        = cn_last_updated_by         -- �ŏI�X�V��
          ,last_update_date       = cd_last_update_date        -- �ŏI�X�V��
          ,last_update_login      = cn_last_update_login       -- �ŏI�X�V���O�C��
          ,request_id             = cn_request_id              -- �v��ID
          ,program_application_id = cn_program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id             = cn_program_id              -- �R���J�����g�E�v���O����ID
          ,program_update_date    = cd_program_update_date     -- �v���O�����X�V��
    WHERE
           object_header_id = iv_object_header_id
    AND    process_type     = iv_object_status
    AND    fa_if_flag       = cv_no
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
  END update_vd_object_histories;
--
  /**********************************************************************************
   * Procedure Name   : update_vd_object_headers
   * Description      : ���̋@�����Ǘ��̍X�V (A-8-2)
   ***********************************************************************************/
  PROCEDURE update_vd_object_headers(
     iv_object_header_id  IN     NUMBER    -- ����ID
    ,iv_object_status     IN     NUMBER    -- �����X�e�[�^�X
    ,ov_errbuf            OUT    VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode           OUT    VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg            OUT    VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_vd_object_headers'; -- �v���O������
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
    -- ���̋@�����Ǘ��̍X�V
    UPDATE xxcff_vd_object_headers
    SET
           object_status          = iv_object_status           -- �����X�e�[�^�X
          ,last_updated_by        = cn_last_updated_by         -- �ŏI�X�V��
          ,last_update_date       = cd_last_update_date        -- �ŏI�X�V��
          ,last_update_login      = cn_last_update_login       -- �ŏI�X�V���O�C��
          ,request_id             = cn_request_id              -- �v��ID
          ,program_application_id = cn_program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id             = cn_program_id              -- �R���J�����g�E�v���O����ID
          ,program_update_date    = cd_program_update_date     -- �v���O�����X�V��
    WHERE
           object_header_id = iv_object_header_id
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
  END update_vd_object_headers;
--
  /**********************************************************************************
   * Procedure Name   : get_deprn_ccid
   * Description      : �������p���CCID�擾 (A-8-1)
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
    cn_segment_count CONSTANT NUMBER := 8; -- �Z�O�����g��
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
    -- �⏕�Ȗڐݒ�
    iot_segments(4) := cv_sub_acct_dummy;
    -- �ڋq�R�[�h�ݒ�
    iot_segments(5) := cv_ptnr_cd_dummy;
    -- ��ƃR�[�h�ݒ�
    iot_segments(6) := cv_busi_cd_dummy;
    -- �\��1�ݒ�
    iot_segments(7) := cv_project_dummy;
    -- �\��2�ݒ�
    iot_segments(8) := cv_future_dummy;
--
    -- CCID�擾�֐��Ăяo��
    lb_ret := fnd_flex_ext.get_combination_id(
                 application_short_name  => g_init_rec.gl_application_short_name -- �A�v���P�[�V�����Z�k��(GL)
                ,key_flex_code           => g_init_rec.id_flex_code              -- �L�[�t���b�N�X�R�[�h
                ,structure_number        => g_init_rec.chart_of_accounts_id      -- ����Ȗڑ̌n�ԍ�
                ,validation_date         => g_init_rec.process_date              -- ���t�`�F�b�N
                ,n_segments              => cn_segment_count                     -- �Z�O�����g��
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
   * Procedure Name   : chk_object_trnsf_data
   * Description      : �ړ��ڍ׏��ύX�`�F�b�N (A-8-5)
   ***********************************************************************************/
  PROCEDURE chk_object_trnsf_data(
     iv_object_code          IN     VARCHAR2                  -- �����R�[�h
    ,iv_dclr_place           IN     VARCHAR2                  -- �\���n
    ,iv_department_code      IN     VARCHAR2                  -- �Ǘ�����
    ,iv_location             IN     VARCHAR2                  -- ���Ə�
    ,iv_installation_address IN     VARCHAR2                  -- �ꏊ
    ,iv_owner_company_type   IN     VARCHAR2                  -- �{�ЍH��敪
    ,iv_modify_flg           OUT    VARCHAR2                  -- �ύX�t���O
    ,ov_errbuf               OUT    VARCHAR2                  -- �G���[�E���b�Z�[�W           --# �Œ� # 
    ,ov_retcode              OUT    VARCHAR2                  -- ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg               OUT    VARCHAR2)                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #

  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_object_trnsf_data'; -- �v���O������
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
    cv_no                CONSTANT VARCHAR2(1)   := 'N';
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
--
    -- *** ���[�J���ϐ� ***
    ln_deprn_ccid_new     gl_code_combinations.code_combination_id%TYPE; -- �ړ��㌸�����p���CCID
    ln_deprn_ccid_org     NUMBER;                                        -- �ړ����������p���CCID
    ln_location_ccid_new  fa_locations.location_id%TYPE;                 -- �ړ��㎖�Ə�CCID
    ln_location_ccid_org  NUMBER;                                        -- �ړ������Ə�CCID
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
    -- �������p���CCID�擾 (A-8-5-1) 
    --==============================================================
    -- A-8-1���Ăяo���A�������p���CCID���擾
    get_deprn_ccid(
       iot_segments     => g_segments_tab     -- �Z�O�����g�l�z��
      ,ot_deprn_ccid    => ln_deprn_ccid_new  -- �������p���CCID
      ,ov_errbuf        => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� # 
      ,ov_retcode       => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- ���Ə�CCID�擾 (A-8-5-2)
    --==============================================================
    xxcff_common1_pkg.chk_fa_location(
       iv_segment1      => iv_dclr_place            -- �\���n
      ,iv_segment2      => iv_department_code       -- �Ǘ�����
      ,iv_segment3      => iv_location              -- ���Ə�
      ,iv_segment4      => iv_installation_address  -- �ꏊ
      ,iv_segment5      => iv_owner_company_type    -- �{�ЍH��敪
      ,on_location_id   => ln_location_ccid_new     -- ���Ə�CCID
      ,ov_errbuf        => lv_errbuf                -- �G���[�E���b�Z�[�W           --# �Œ� # 
      ,ov_retcode       => lv_retcode               -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg        => lv_errmsg                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �ړ����ڍ׏��擾 (A-8-5-3)
    --==============================================================
    SELECT
           fdh.code_combination_id     -- �������p��CCID
          ,fdh.location_id             -- ���Ə�ID
    INTO
           ln_deprn_ccid_org           -- �ړ����������p���CCID
          ,ln_location_ccid_org        -- �ړ������Ə�CCID
    FROM
           fa_additions_b          fab -- ���Y�ڍ׏��
          ,fa_distribution_history fdh -- ���Y�����������
    WHERE
          fab.tag_number = iv_object_code
    AND   fab.asset_id = fdh.asset_id
    AND   fdh.date_ineffective IS NULL
    AND   fdh.book_type_code = gv_fixed_asset_register
    ;
--
    --==============================================================
    -- �ړ��ڍ׏��ύX�`�F�b�N (A-8-5-4)
    --==============================================================
    -- �������p���CCID�̔�r
    IF ( ln_deprn_ccid_org <> ln_deprn_ccid_new ) THEN
      iv_modify_flg := cv_yes;
    ELSE
      IF ( ln_location_ccid_org <> ln_location_ccid_new ) THEN
        iv_modify_flg := cv_yes;
      ELSE
        iv_modify_flg := cv_no;
      END IF;
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
  END chk_object_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : get_vd_object_ritire_data
   * Description      : ���̋@�����i�����p���m��j�o�^�f�[�^���o(A-7)
   ***********************************************************************************/
  PROCEDURE get_vd_object_ritire_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_vd_object_ritire_data'; -- �v���O������
    cv_type_code_sale    CONSTANT VARCHAR2(4)   := 'SALE';                      -- �����p�^�C�v�F���p
    cv_no                CONSTANT VARCHAR2(1)   := 'N';
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
    cv_status            CONSTANT VARCHAR2(7)   := 'PENDING';
    cn_cost_0            CONSTANT NUMBER        := 0;
    cn_count_0          CONSTANT NUMBER        := 0;
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
    lv_warnmsg                VARCHAR2(5000);  -- �x�����b�Z�[�W
    lv_warn_flg               VARCHAR2(1);     -- �x���t���O
    lv_asset_number           VARCHAR2(15);    -- ���Y�ԍ�
    lv_ret_type_code          VARCHAR2(15);    -- �����p�^�C�v
    ln_cost_retired           NUMBER;          -- ������p�擾���i
    ln_proceeds_of_sale       NUMBER;          -- ���p���z
    ln_cost_of_removal        NUMBER;          -- �P����p
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���̋@�����i�����p���m��j�J�[�\��
    CURSOR vd_object_ritire_cur
    IS
      SELECT
             vohe.object_header_id        AS object_header_id        -- ����ID
            ,vohe.object_code             AS object_code             -- �����R�[�h
            ,vohe.date_retired            AS date_retired            -- ���E���p��
            ,vohe.proceeds_of_sale        AS proceeds_of_sale        -- ���p���z
            ,vohe.cost_of_removal         AS cost_of_removal         -- �P����p
      FROM
            xxcff_vd_object_headers  vohe
      WHERE
            vohe.object_header_id in (
                                      SELECT
                                             voh.object_header_id             -- ����ID
                                      FROM
                                             xxcff_vd_object_histories  voh   -- ���̋@��������
                                      WHERE
                                            voh.fa_if_flag   = cv_no         -- FA���A�g
                                        AND voh.process_type = cv_status_105 -- �����p���m��
                                        AND voh.retired_flag = cv_yes        -- �����p�m��t���O
                                      )
      ORDER BY
            vohe.object_code
        FOR UPDATE NOWAIT
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
    OPEN vd_object_ritire_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH vd_object_ritire_cur
    BULK COLLECT INTO  g_object_header_id_tab        -- ����ID
                      ,g_object_code_tab             -- �����R�[�h
                      ,g_date_retired_tab            -- ���E���p��
                      ,g_proceeds_of_sale_tab        -- ���p���z
                      ,g_cost_of_removal_tab         -- �P����p
    ;
    -- �ړ��Ώی����J�E���g
    gn_vd_retire_target_cnt := g_object_header_id_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE vd_object_ritire_cur;
--
    IF ( gn_vd_retire_target_cnt = cn_count_0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_017a03_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_017a03_t_021) -- ���̋@�����i�����p�j���
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���C�����[�v�����C
    --==============================================================
    <<vd_object_trnsf_loop>>
    FOR ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT LOOP
--
      -- �x���t���O������������
      lv_warn_flg := cv_no;
      -- �������̌����擾
      gn_vd_target_cnt := ln_loop_cnt;
--
      --==============================================================
      -- ���ڒl�`�F�b�N�i�����p���m��j (A-7-1)
      --==============================================================
      -- 1.���E���p���̑��݃`�F�b�N������
      IF ( g_date_retired_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��'Y'���Z�b�g
        lv_warn_flg := cv_yes;
        -- �����p���m��X�L�b�v�����J�E���g
        gn_vd_retire_warn_cnt := gn_vd_retire_warn_cnt + 1;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_036)                     -- ���E���p��
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- �����p���̓��t�`�F�b�N����
      -- �����p�������݂���ꍇ
      IF ( g_date_retired_tab(ln_loop_cnt) IS NOT NULL ) THEN
        -- �J�����_���ԃN���[�Y�����擾���Ă��Ȃ��ꍇ
        IF ( g_cal_per_close_date IS NULL ) THEN
          BEGIN
            -- �ŐV�̃J�����_���ԃN���[�Y�����擾
            SELECT
                   MAX(fdp.calendar_period_close_date)               -- �J�����_���ԃN���[�Y��
            INTO
                   g_cal_per_close_date
            FROM   fa_deprn_periods     fdp                          -- �������p����
            WHERE
                   fdp.book_type_code   = gv_fixed_asset_register    -- �䒠���
            AND    fdp.period_close_date IS NOT NULL                 -- �N���[�Y��
            ;
          EXCEPTION
            -- �J�����_���ԃN���[�Y�����擾�ł��Ȃ��ꍇ
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                            ,cv_msg_017a03_m_013     -- �擾�G���[
                                                            ,cv_tkn_table            -- �g�[�N��'TABLE_NAME'
                                                            ,cv_msg_017a03_t_015     -- �������p����
                                                            ,cv_tkn_info             -- �g�[�N��'INFO'
                                                            ,cv_msg_017a03_t_018)    -- �J�����_���ԃN���[�Y��
                                                            ,1
                                                            ,5000);
              RAISE chk_no_data_found_expt;
          END;
        END IF;
        -- �����p�����J�����_���ԃN���[�Y���ȑO�̏ꍇ
        IF ( trunc(g_date_retired_tab(ln_loop_cnt)) <= trunc(g_cal_per_close_date) ) THEN
          -- �x���t���O��'N'�̏ꍇ
          IF ( lv_warn_flg = cv_no ) THEN
            -- �x���t���O��'Y'���Z�b�g
            lv_warn_flg := cv_yes;
            -- �����p���m��X�L�b�v�����J�E���g
            gn_vd_retire_warn_cnt := gn_vd_retire_warn_cnt + 1;
          END IF;
          -- �x�����b�Z�[�W���Z�b�g
          gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                         ,cv_msg_017a03_m_022                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                         ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                         ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                         ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                         ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                         ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                         ,cv_msg_017a03_t_036)                     -- ���E���p��
                                                         ,1
                                                         ,2000);
          -- �x�����b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
        END IF;
      END IF;
--
      -- �x���t���O��'N'�̏ꍇ
      IF ( lv_warn_flg = cv_no ) THEN
        --==============================================================
        -- �Œ莑�Y���擾�i�����p���m��j (A-7-2)
        --==============================================================
        BEGIN
          SELECT 
                 fab.asset_number                  -- ���Y�ԍ�
                ,fb.cost                           -- �擾���i
          INTO
                 lv_asset_number                   -- ���Y�ԍ�
                ,ln_cost_retired                   -- ������p�擾���i
          FROM
                fa_additions_b  fab                -- ���Y�ڍ׏��
               ,fa_books        fb                 -- ���Y�䒠���
          WHERE
                fab.tag_number      = g_object_code_tab(ln_loop_cnt)
          AND   fab.asset_id        = fb.asset_id
          AND   fb.book_type_code   = gv_fixed_asset_register
          AND   fb.date_ineffective IS NULL
          ;
        EXCEPTION
          -- �Œ莑�Y��񂪎擾�ł��Ȃ��ꍇ
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                          ,cv_msg_017a03_m_013     -- �擾�G���[
                                                          ,cv_tkn_table            -- �g�[�N��'TABLE_NAME'
                                                          ,cv_msg_017a03_t_023     -- ���Y�ڍ׏��
                                                          ,cv_tkn_info             -- �g�[�N��'INFO'
                                                          ,cv_msg_017a03_t_022)    -- �Œ莑�Y�i�����p�j���
                                                          ,1
                                                          ,5000);
            RAISE chk_no_data_found_expt;
        END;
--
        -- �����p�^�C�v�̎擾
        IF ( (g_proceeds_of_sale_tab(ln_loop_cnt) = cn_cost_0)
          OR (g_proceeds_of_sale_tab(ln_loop_cnt) IS NULL)) THEN
          -- ���p���z��0�A�܂���NULL�̏ꍇ�A���p�FNULL
          lv_ret_type_code := NULL;
        ELSE
          -- ��L�ȊO�̏ꍇ�A���p�F'SALE'
          lv_ret_type_code := cv_type_code_sale;
        END IF;
        -- ���p���z�̎擾
        IF (g_proceeds_of_sale_tab(ln_loop_cnt) IS NULL) THEN
          -- ���p���z��NULL�̏ꍇ�A0
          ln_proceeds_of_sale := cn_cost_0;
        ELSE
          -- ��L�ȊO�̏ꍇ�AA-7�J�[�\���擾�l
          ln_proceeds_of_sale := g_proceeds_of_sale_tab(ln_loop_cnt);
        END IF;
        -- �P����p�̎擾
        IF (g_cost_of_removal_tab(ln_loop_cnt) IS NULL) THEN
          -- �P����p��NULL�̏ꍇ�A0
          ln_cost_of_removal := cn_cost_0;
        ELSE
          -- ��L�ȊO�̏ꍇ�AA-7�J�[�\���擾�l
          ln_cost_of_removal := g_cost_of_removal_tab(ln_loop_cnt);
        END IF;
--
        --==============================================================
        -- �����pOIF�o�^ (A-7-3)
        --==============================================================
        -- �����pOIF�o�^
        INSERT INTO xx01_retire_oif(
           retire_oif_id                  -- ID
          ,book_type_code                 -- �䒠��
          ,asset_number                   -- ���Y�ԍ�
          ,date_retired                   -- ������p��
          ,posting_flag                   -- �]�L�����׸�
          ,status                         -- �ð��
          ,cost_retired                   -- ������p�擾���i
          ,retirement_type_code           -- �����p�^�C�v
          ,proceeds_of_sale               -- ���p���z
          ,cost_of_removal                -- �P����p
          ,retirement_prorate_convention  -- ������p�N�x���p
          ,created_by                     -- �쐬��
          ,creation_date                  -- �쐬��
          ,last_updated_by                -- �ŏI�X�V��
          ,last_update_date               -- �ŏI�X�V��
          ,last_update_login              -- �ŏI�X�V۸޲�
          ,request_id                     -- ظ���ID
          ,program_application_id         -- ���ع����ID
          ,program_id                     -- ��۸���ID
          ,program_update_date            -- ��۸��эŏI�X�V
        ) VALUES (
           xx01_retire_oif_s.NEXTVAL      -- ID
          ,gv_fixed_asset_register        -- �䒠��
          ,lv_asset_number                -- ���Y�ԍ�
          ,g_date_retired_tab(ln_loop_cnt)  -- ������p��
          ,cv_yes                         -- �]�L�����׸�
          ,cv_status                      -- �ð��
          ,ln_cost_retired                -- ������p�擾���i
          ,lv_ret_type_code               -- �����p�^�C�v
          ,ln_proceeds_of_sale            -- ���p���z
          ,ln_cost_of_removal             -- �P����p
          ,gv_prt_conv_cd_ed              -- ������p�N�x���p
          ,cn_created_by                  -- �쐬��
          ,cd_creation_date               -- �쐬��
          ,cn_last_updated_by             -- �ŏI�X�V��
          ,cd_last_update_date            -- �ŏI�X�V��
          ,cn_last_update_login           -- �ŏI�X�V���O�C��ID
          ,cn_request_id                  -- ���N�G�X�gID
          ,cn_program_application_id      -- �A�v���P�[�V����ID
          ,cn_program_id                  -- �v���O����ID
          ,cd_program_update_date         -- �v���O�����ŏI�X�V��
        )
        ;
--
        --==============================================================
        -- ���̋@�����Ǘ��̍X�V�i�����p���m��j (A-7-4)
        --==============================================================
        update_vd_object_headers(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- ����ID
          ,iv_object_status     => cv_status_106                        -- �����X�e�[�^�X
          ,ov_errbuf            => lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode           => lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg            => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �X�V�Ɏ��s�����ꍇ�A�������~
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- ���̋@���������̍X�V�i�����p���m��j (A-7-5)
        --==============================================================
        update_vd_object_histories(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- ����ID
          ,iv_object_status     => cv_status_105                        -- �����敪
          ,ov_errbuf            => lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode           => lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg            => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �X�V�Ɏ��s�����ꍇ�A�������~
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- ���̋@���������̍쐬�i�����p�j (A-7-6)
        --==============================================================
        insert_vd_object_histories(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- ����ID
          ,iv_object_status     => cv_status_106                        -- �����敪
          ,ov_errbuf            => lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode           => lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg            => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �쐬�Ɏ��s�����ꍇ�A�������~
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ���̋@����(�����p���m��)�o�^�����J�E���g
        gn_vd_retire_normal_cnt := gn_vd_retire_normal_cnt + 1;
--
      END IF;
--
    END LOOP vd_object_trnsf_loop;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      -- �J�[�\���N���[�Y
      IF (vd_object_ritire_cur%ISOPEN) THEN
        CLOSE vd_object_ritire_cur;
      END IF;
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_017a03_m_012  -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,cv_msg_017a03_t_014) -- ���̋@�����Ǘ�
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** �擾�������[�����̃G���[�n���h�� ***
    WHEN chk_no_data_found_expt THEN
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
      IF (vd_object_ritire_cur%ISOPEN) THEN
        CLOSE vd_object_ritire_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (vd_object_ritire_cur%ISOPEN) THEN
        CLOSE vd_object_ritire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (vd_object_ritire_cur%ISOPEN) THEN
        CLOSE vd_object_ritire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_vd_object_ritire_data;
--
  /**********************************************************************************
   * Procedure Name   : get_vd_object_modify_data
   * Description      : ���̋@�����i�C���j�o�^�f�[�^���o(A-6)
   ***********************************************************************************/
  PROCEDURE get_vd_object_modify_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_vd_object_modify_data'; -- �v���O������
    cv_asset_category_id CONSTANT VARCHAR2(24)  := 'XXCFF1_ASSET_CATEGORY_ID';
    cv_no                CONSTANT VARCHAR2(1)   := 'N';
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
    cv_status            CONSTANT VARCHAR2(7)   := 'PENDING';
    cn_period_ctr_0      CONSTANT NUMBER        := 0;
    cn_count_0           CONSTANT NUMBER        := 0;
    cv_date_type         CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
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
    lv_warnmsg                     VARCHAR2(5000);  -- �x�����b�Z�[�W
    lv_warn_flg                    VARCHAR2(1);     -- �x���t���O
    ln_life_in_monsths             NUMBER;          -- �ϗp�N��+����
    lv_description                 VARCHAR2(80);    -- �E�v
    ln_reval_rsv                   NUMBER;          -- �ĕ]���ϗ���
    ln_deprn_exp                   NUMBER;          -- �������p��
    lv_attribute2                  VARCHAR2(10);    -- �J�e�S��DFF02
--
    -- OIF�o�^�p�ϐ�
    ln_asset_id                    NUMBER;          -- ���YID
    lv_asset_number_old            VARCHAR2(15);    -- ���Y�ԍ�
    ld_dpis_old                    DATE;            -- ���Ƌ��p���i�C���O�j
    ln_category_id_old             NUMBER;          -- ���Y�J�e�S��ID�i�C���O�j
    lv_cat_attribute_category_old  VARCHAR2(210);   -- ���Y�J�e�S���R�[�h�i�C���O�j
    lv_amortized_flag              VARCHAR2(3);     -- �C���z���p�t���O
    ld_amortization_start_date     DATE;            -- ���p�J�n��
    lv_asset_number_new            VARCHAR2(15);    -- ���Y�ԍ��i�C����j
    lv_tag_number                  VARCHAR2(15);    -- ���i�[�ԍ�
    ln_category_id_new             NUMBER;          -- ���Y�J�e�S��ID�i�C����j
    lv_serial_number               VARCHAR2(35);    -- �V���A���ԍ�
    ln_asset_key_ccid              NUMBER;          -- ���Y�L�[CCID
    lv_key_segment1                VARCHAR2(30);    -- ���Y�L�[�Z�O�����g1
    lv_key_segment2                VARCHAR2(30);    -- ���Y�L�[�Z�O�����g2
    ln_parent_asset_id             NUMBER;          -- �e���YID
    ln_lease_id                    NUMBER;          -- ���[�XID
    lv_model_number                VARCHAR2(40);    -- ���f��
    lv_in_use_flag                 VARCHAR2(3);     -- �g�p��
    lv_inventorial                 VARCHAR2(3);     -- ���n�I���t���O
    lv_owned_leased                VARCHAR2(15);    -- ���L��
    lv_new_used                    VARCHAR2(4);     -- �V�i/����
    lv_cat_attribute1              VARCHAR2(150);   -- �J�e�S��DFF1
    lv_cat_attribute3              VARCHAR2(150);   -- �J�e�S��DFF3
    lv_cat_attribute4              VARCHAR2(150);   -- �J�e�S��DFF4
    lv_cat_attribute5              VARCHAR2(150);   -- �J�e�S��DFF5
    lv_cat_attribute6              VARCHAR2(150);   -- �J�e�S��DFF6
    lv_cat_attribute7              VARCHAR2(150);   -- �J�e�S��DFF7
    lv_cat_attribute8              VARCHAR2(150);   -- �J�e�S��DFF8
    lv_cat_attribute9              VARCHAR2(150);   -- �J�e�S��DFF9
    lv_cat_attribute10             VARCHAR2(150);   -- �J�e�S��DFF10
    lv_cat_attribute11             VARCHAR2(150);   -- �J�e�S��DFF11
    lv_cat_attribute12             VARCHAR2(150);   -- �J�e�S��DFF12
    lv_cat_attribute13             VARCHAR2(150);   -- �J�e�S��DFF13
    lv_cat_attribute14             VARCHAR2(150);   -- �J�e�S��DFF14
    lv_cat_attribute15             VARCHAR2(150);   -- �J�e�S��DFF15
    lv_cat_attribute16             VARCHAR2(150);   -- �J�e�S��DFF16
    lv_cat_attribute17             VARCHAR2(150);   -- �J�e�S��DFF17
    lv_cat_attribute18             VARCHAR2(150);   -- �J�e�S��DFF18
    lv_cat_attribute19             VARCHAR2(150);   -- �J�e�S��DFF19
    lv_cat_attribute20             VARCHAR2(150);   -- �J�e�S��DFF20
    lv_cat_attribute21             VARCHAR2(150);   -- �J�e�S��DFF21
    lv_cat_attribute22             VARCHAR2(150);   -- �J�e�S��DFF22
    lv_cat_attribute23             VARCHAR2(150);   -- �J�e�S��DFF23
    lv_cat_attribute24             VARCHAR2(150);   -- �J�e�S��DFF24
    lv_cat_attribute25             VARCHAR2(150);   -- �J�e�S��DFF27
    lv_cat_attribute26             VARCHAR2(150);   -- �J�e�S��DFF25
    lv_cat_attribute27             VARCHAR2(150);   -- �J�e�S��DFF26
    lv_cat_attribute28             VARCHAR2(150);   -- �J�e�S��DFF28
    lv_cat_attribute29             VARCHAR2(150);   -- �J�e�S��DFF29
    lv_cat_attribute30             VARCHAR2(150);   -- �J�e�S��DFF30
    lv_cat_attribute_category_new  VARCHAR2(210);   -- ���Y�J�e�S���R�[�h�i�C����j
    ln_salvage_value               NUMBER;          -- �c�����z
    ln_percent_salvage_value       NUMBER;          -- �c�����z%
    ln_allowed_deprn_limit_amount  NUMBER;          -- ���p���x�z
    ln_allowed_deprn_limit         NUMBER;          -- ���p���x��
    ln_ytd_deprn                   NUMBER;          -- �N���p�݌v�z
    ln_deprn_reserve               NUMBER;          -- ���p�݌v�z
    lv_depreciate_flag             VARCHAR2(3);     -- ���p��v��t���O
    lv_deprn_method_code           VARCHAR2(12);    -- ���p���@
    ln_basic_rate                  NUMBER;          -- ���ʏ��p��
    ln_adjusted_rate               NUMBER;          -- �����㏞�p��
    ln_life_years                  NUMBER;          -- �ϗp�N��
    ln_life_months                 NUMBER;          -- ����
    lv_bonus_rule                  VARCHAR2(30);    -- �{�[�i�X���[��
    ln_bonus_ytd_deprn             NUMBER;          -- �{�[�i�X�N���p�݌v�z
    ln_bonus_deprn_reserve         NUMBER;          -- �{�[�i�X���p�݌v�z
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���̋@�����i�C���j�J�[�\��
    CURSOR vd_object_modify_cur
    IS
      SELECT
             vohe.object_header_id        AS object_header_id        -- ����ID
            ,vohe.object_code             AS object_code             -- �����R�[�h
            ,vohe.date_placed_in_service  AS date_placed_in_service  -- ���Ƌ��p��
            ,vohe.manufacturer_name       AS manufacturer_name       -- ���[�J�[
            ,vohe.model                   AS model                   -- �@��
            ,vohe.age_type                AS age_type                -- �N��
            ,vohe.quantity                AS quantity                -- ����
            ,vohe.assets_date             AS assets_date             -- �擾��
            ,vohe.assets_cost             AS assets_cost1            -- �擾���i
            ,vohe.assets_cost             AS assets_cost2            -- �擾���i
      FROM
            xxcff_vd_object_headers  vohe
      WHERE
            vohe.object_header_id in (
                                      SELECT
                                             voh.object_header_id             -- ����ID
                                      FROM
                                             xxcff_vd_object_histories  voh   -- ���̋@��������
                                      WHERE
                                            voh.fa_if_flag   = cv_no         -- FA���A�g
                                        AND voh.process_type = cv_status_104 -- �C��
                                      )
      ORDER BY
            vohe.object_code
        FOR UPDATE NOWAIT
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
    -- ���[�J���ϐ�����������
    ln_life_years                  := NULL;  -- �ϗp�N��
    ln_life_months                 := NULL;  -- ����

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
    OPEN vd_object_modify_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH vd_object_modify_cur
    BULK COLLECT INTO  g_object_header_id_tab        -- ����ID
                      ,g_object_code_tab             -- �����R�[�h
                      ,g_date_placed_in_service_tab  -- ���Ƌ��p��
                      ,g_manufacturer_name_tab       -- ���[�J�[
                      ,g_model_tab                   -- �@��
                      ,g_age_type_tab                -- �N��
                      ,g_transaction_units_tab       -- �P��
                      ,g_cat_attribute2_tab          -- �J�e�S��DFF2
                      ,g_cost_tab                    -- �擾���z
                      ,g_original_cost_tab           -- �����擾���z
    ;
    -- �C���Ώی����J�E���g
    gn_vd_modify_target_cnt := g_object_header_id_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE vd_object_modify_cur;
--
    IF ( gn_vd_modify_target_cnt = cn_count_0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_017a03_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_017a03_t_019) -- ���̋@�����i�C���j���
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���C�����[�v�����B
    --==============================================================
    <<vd_object_modify_loop>>
    FOR ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT LOOP
--
      -- �x���t���O������������
      lv_warn_flg := cv_no;
      -- �������̌����擾
      gn_vd_target_cnt := ln_loop_cnt;
--
      --==============================================================
      -- ���ڒl�`�F�b�N�i�C���j (A-6-1)
      --==============================================================
      -- 1.���Ƌ��p���̑��݃`�F�b�N������
      IF ( g_date_placed_in_service_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��'Y'���Z�b�g
        lv_warn_flg := cv_yes;
        -- �C���X�L�b�v�����J�E���g
        gn_vd_modify_warn_cnt := gn_vd_modify_warn_cnt + 1;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_027)                     -- ���Ƌ��p��
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 2.�E�v�̑��݃`�F�b�N������
      IF ( g_manufacturer_name_tab(ln_loop_cnt)||g_model_tab(ln_loop_cnt)||g_age_type_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- �C���X�L�b�v�����J�E���g
          gn_vd_modify_warn_cnt := gn_vd_modify_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_025)                     -- ���[�J�[�� �@�� �N��
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 3.���ʁi�P�ʁj�̑��݃`�F�b�N������
      IF ( g_transaction_units_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- �C���X�L�b�v�����J�E���g
          gn_vd_modify_warn_cnt := gn_vd_modify_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_029)                     -- ����
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 4.�擾���i�i�擾���z�j�̑��݃`�F�b�N������
      IF ( g_cost_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- �C���X�L�b�v�����J�E���g
          gn_vd_modify_warn_cnt := gn_vd_modify_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_028)                     -- �擾���i
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- �x���t���O��'N'�̏ꍇ
      IF ( lv_warn_flg = cv_no ) THEN
        --==============================================================
        -- �Œ莑�Y���擾�i�C���j (A-6-2)
        --==============================================================
        BEGIN
          SELECT
                 fab.asset_id                    -- ���YID
                ,fab.asset_number                -- ���Y�ԍ�
                ,fb.date_placed_in_service       -- ���Ƌ��p���i�C���O�j
                ,fab.asset_category_id           -- ���Y�J�e�S��ID�i�C���O�j
                ,fab.attribute_category_code     -- ���Y�J�e�S���R�[�h�i�C���O�j
                ,fbc.amortize_flag               -- �C���z���p�t���O
                ,fth.amortization_start_date     -- ���p�J�n��
                ,fab.asset_number                -- ���Y�ԍ��i�C����j
                ,fab.tag_number                  -- ���i�[�ԍ�
                ,fab.asset_category_id           -- ���Y�J�e�S��ID�i�C����j
                ,fab.serial_number               -- �V���A���ԍ�
                ,fab.asset_key_ccid              -- ���Y�L�[CCID
                ,fak.segment1                    -- ���Y�L�[�Z�O�����g1
                ,fak.segment2                    -- ���Y�L�[�Z�O�����g2
                ,fab.parent_asset_id             -- �e���YID
                ,fab.lease_id                    -- ���[�XID
                ,fab.model_number                -- ���f��
                ,fab.in_use_flag                 -- �g�p��
                ,fab.inventorial                 -- ���n�I���t���O
                ,fab.owned_leased                -- ���L��
                ,fab.new_used                    -- �V�i/����
                ,fab.attribute1                  -- �J�e�S��DFF1
                ,fab.attribute3                  -- �J�e�S��DFF3
                ,fab.attribute4                  -- �J�e�S��DFF4
                ,fab.attribute5                  -- �J�e�S��DFF5
                ,fab.attribute6                  -- �J�e�S��DFF6
                ,fab.attribute7                  -- �J�e�S��DFF7
                ,fab.attribute8                  -- �J�e�S��DFF8
                ,fab.attribute9                  -- �J�e�S��DFF9
                ,fab.attribute10                 -- �J�e�S��DFF10
                ,fab.attribute11                 -- �J�e�S��DFF11
                ,fab.attribute12                 -- �J�e�S��DFF12
                ,fab.attribute13                 -- �J�e�S��DFF13
                ,fab.attribute14                 -- �J�e�S��DFF14
                ,fab.attribute15                 -- �J�e�S��DFF15
                ,fab.attribute16                 -- �J�e�S��DFF16
                ,fab.attribute17                 -- �J�e�S��DFF17
                ,fab.attribute18                 -- �J�e�S��DFF18
                ,fab.attribute19                 -- �J�e�S��DFF19
                ,fab.attribute20                 -- �J�e�S��DFF20
                ,fab.attribute21                 -- �J�e�S��DFF21
                ,fab.attribute22                 -- �J�e�S��DFF22
                ,fab.attribute23                 -- �J�e�S��DFF23
                ,fab.attribute24                 -- �J�e�S��DFF24
                ,fab.attribute25                 -- �J�e�S��DFF27
                ,fab.attribute26                 -- �J�e�S��DFF25
                ,fab.attribute27                 -- �J�e�S��DFF26
                ,fab.attribute28                 -- �J�e�S��DFF28
                ,fab.attribute29                 -- �J�e�S��DFF29
                ,fab.attribute30                 -- �J�e�S��DFF30
                ,fab.attribute_category_code     -- ���Y�J�e�S���R�[�h�i�C����j
                ,fb.salvage_value                -- �c�����z
                ,fb.percent_salvage_value        -- �c�����z%
                ,fb.allowed_deprn_limit_amount   -- ���p���x�z
                ,fb.allowed_deprn_limit          -- ���p���x��
                ,fb.depreciate_flag              -- ���p��v��t���O
                ,fb.deprn_method_code            -- ���p���@
                ,fb.basic_rate                   -- ���ʏ��p��
                ,fb.adjusted_rate                -- �����㏞�p��
                ,fb.life_in_months               -- �ϗp�N��+����
                ,fb.bonus_rule                   -- �{�[�i�X���[��
          INTO
                 ln_asset_id                    -- ���YID
                ,lv_asset_number_old            -- ���Y�ԍ�
                ,ld_dpis_old                    -- ���Ƌ��p���i�C���O�j
                ,ln_category_id_old             -- ���Y�J�e�S��ID�i�C���O�j
                ,lv_cat_attribute_category_old  -- ���Y�J�e�S���R�[�h�i�C���O�j
                ,lv_amortized_flag              -- �C���z���p�t���O
                ,ld_amortization_start_date     -- ���p�J�n��
                ,lv_asset_number_new            -- ���Y�ԍ��i�C����j
                ,lv_tag_number                  -- ���i�[�ԍ�
                ,ln_category_id_new             -- ���Y�J�e�S��ID�i�C����j
                ,lv_serial_number               -- �V���A���ԍ�
                ,ln_asset_key_ccid              -- ���Y�L�[CCID
                ,lv_key_segment1                -- ���Y�L�[�Z�O�����g1
                ,lv_key_segment2                -- ���Y�L�[�Z�O�����g2
                ,ln_parent_asset_id             -- �e���YID
                ,ln_lease_id                    -- ���[�XID
                ,lv_model_number                -- ���f��
                ,lv_in_use_flag                 -- �g�p��
                ,lv_inventorial                 -- ���n�I���t���O
                ,lv_owned_leased                -- ���L��
                ,lv_new_used                    -- �V�i/����
                ,lv_cat_attribute1              -- �J�e�S��DFF1
                ,lv_cat_attribute3              -- �J�e�S��DFF3
                ,lv_cat_attribute4              -- �J�e�S��DFF4
                ,lv_cat_attribute5              -- �J�e�S��DFF5
                ,lv_cat_attribute6              -- �J�e�S��DFF6
                ,lv_cat_attribute7              -- �J�e�S��DFF7
                ,lv_cat_attribute8              -- �J�e�S��DFF8
                ,lv_cat_attribute9              -- �J�e�S��DFF9
                ,lv_cat_attribute10             -- �J�e�S��DFF10
                ,lv_cat_attribute11             -- �J�e�S��DFF11
                ,lv_cat_attribute12             -- �J�e�S��DFF12
                ,lv_cat_attribute13             -- �J�e�S��DFF13
                ,lv_cat_attribute14             -- �J�e�S��DFF14
                ,lv_cat_attribute15             -- �J�e�S��DFF15
                ,lv_cat_attribute16             -- �J�e�S��DFF16
                ,lv_cat_attribute17             -- �J�e�S��DFF17
                ,lv_cat_attribute18             -- �J�e�S��DFF18
                ,lv_cat_attribute19             -- �J�e�S��DFF19
                ,lv_cat_attribute20             -- �J�e�S��DFF20
                ,lv_cat_attribute21             -- �J�e�S��DFF21
                ,lv_cat_attribute22             -- �J�e�S��DFF22
                ,lv_cat_attribute23             -- �J�e�S��DFF23
                ,lv_cat_attribute24             -- �J�e�S��DFF24
                ,lv_cat_attribute25             -- �J�e�S��DFF27
                ,lv_cat_attribute26             -- �J�e�S��DFF25
                ,lv_cat_attribute27             -- �J�e�S��DFF26
                ,lv_cat_attribute28             -- �J�e�S��DFF28
                ,lv_cat_attribute29             -- �J�e�S��DFF29
                ,lv_cat_attribute30             -- �J�e�S��DFF30
                ,lv_cat_attribute_category_new  -- ���Y�J�e�S���R�[�h�i�C����j
                ,ln_salvage_value               -- �c�����z
                ,ln_percent_salvage_value       -- �c�����z%
                ,ln_allowed_deprn_limit_amount  -- ���p���x�z
                ,ln_allowed_deprn_limit         -- ���p���x��
                ,lv_depreciate_flag             -- ���p��v��t���O
                ,lv_deprn_method_code           -- ���p���@
                ,ln_basic_rate                  -- ���ʏ��p��
                ,ln_adjusted_rate               -- �����㏞�p��
                ,ln_life_in_monsths             -- �ϗp�N��+����
                ,lv_bonus_rule                  -- �{�[�i�X���[��
          FROM
                fa_additions_b          fab      -- ���Y�ڍ׏��
               ,fa_asset_keywords       fak      -- ���Y�L�[
               ,fa_books                fb       -- ���Y�䒠���
               ,fa_book_controls        fbc      -- ���Y�䒠
               ,fa_transaction_headers  fth      -- ���Y����w�b�_-
          WHERE
                fab.asset_key_ccid           = fak.code_combination_id(+)
          AND   fab.asset_id                 = fb.asset_id
          AND   fb.book_type_code            = fbc.book_type_code(+)
          AND   fb.transaction_header_id_in  = fth.transaction_header_id(+)
          AND   fab.tag_number               = g_object_code_tab(ln_loop_cnt)
          AND   fb.book_type_code            = gv_fixed_asset_register
          AND   fb.date_ineffective          IS NULL
          ;
        EXCEPTION
          -- �Œ莑�Y��񂪎擾�ł��Ȃ��ꍇ
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                          ,cv_msg_017a03_m_013     -- �擾�G���[
                                                          ,cv_tkn_table            -- �g�[�N��'TABLE_NAME'
                                                          ,cv_msg_017a03_t_023     -- ���Y�ڍ׏��
                                                          ,cv_tkn_info             -- �g�[�N��'INFO'
                                                          ,cv_msg_017a03_t_020)    -- �Œ莑�Y�i�C���j���
                                                          ,1
                                                          ,5000);
            RAISE chk_no_data_found_expt;
        END;
--
        -- ���p�݌v�z�E�N���p�݌v�z�E�{�[�i�X���p�݌v�z�E�{�[�i�X�N���p�݌v�z�̎擾
        xx01_conc_util_pkg.query_balances_bonus(
           in_asset_id         => ln_asset_id             -- ���YID
          ,iv_book_type_code   => gv_fixed_asset_register -- XXCFF:�䒠���_�Œ莑�Y�䒠�i�v���t�@�C���l�j
          ,on_deprn_rsv        => ln_deprn_reserve        -- ���p�݌v�z
          ,on_reval_rsv        => ln_reval_rsv            -- �ĕ]���ϗ���
          ,on_ytd_deprn        => ln_ytd_deprn            -- �N���p�݌v�z
          ,on_deprn_exp        => ln_deprn_exp            -- �������p��
          ,on_bonus_deprn_rsv  => ln_bonus_deprn_reserve  -- �{�[�i�X���p�݌v�z
          ,on_bonus_ytd_deprn  => ln_bonus_ytd_deprn      -- �{�[�i�X�N���p�݌v�z
          ,in_period_ctr       => cn_period_ctr_0         -- �Œ�l�F0
        );
--
        -- �ϗp�N��+������NULL�ł͂Ȃ��ꍇ
        IF ( ln_life_in_monsths IS NOT NULL ) THEN
          -- �ϗp�N���̎擾
          ln_life_years  := trunc(ln_life_in_monsths / 12);
          -- �ϗp�����̎擾
          ln_life_months := mod(ln_life_in_monsths, 12);
        END IF;
--
        -- �E�v���擾����
        lv_description := SUBSTRB(g_manufacturer_name_tab(ln_loop_cnt) || ' ' ||
                                  g_model_tab(ln_loop_cnt) || ' ' ||
                                  g_age_type_tab(ln_loop_cnt)
                                  , 1, 80);
--
        --==============================================================
        -- �C��OIF�o�^ (A-6-3)
        --==============================================================
        -- �J�e�S��DFF02�̎擾
        IF (g_cat_attribute2_tab(ln_loop_cnt) IS NULL) THEN
          -- �J�e�S��DFF02(�擾��)��NULL�̎��A���Ƌ��p����YYYY/MM/DD�^�ŃZ�b�g����
          lv_attribute2 := to_char(g_date_placed_in_service_tab(ln_loop_cnt), cv_date_type);
        ELSE
          -- DFF02(�擾��)�����݂��鎞�ADFF02(�擾��)��YYYY/MM/DD�^�ŃZ�b�g����
          lv_attribute2 := to_char(g_cat_attribute2_tab(ln_loop_cnt), cv_date_type);
        END IF;
--
        -- �C��OIF�o�^
        INSERT INTO xx01_adjustment_oif(
           adjustment_oif_id               -- ID
          ,book_type_code                  -- �䒠��
          ,asset_number_old                -- ���Y�ԍ�
          ,dpis_old                        -- ���Ƌ��p���i�C���O�j
          ,category_id_old                 -- ���Y�J�e�S��ID�i�C���O�j
          ,cat_attribute_category_old      -- ���Y�J�e�S���R�[�h�i�C���O�j
          ,dpis_new                        -- ���Ƌ��p���i�C����j
          ,description                     -- �E�v�i�C����j
          ,transaction_units               -- �P��
          ,cat_attribute2                  -- �J�e�S��DFF2
          ,cost                            -- �擾���z
          ,original_cost                   -- �����擾���z
          ,posting_flag                    -- �]�L�`�F�b�N�t���O
          ,status                          -- �X�e�[�^�X
          ,amortized_flag                  -- �C���z���p�t���O
          ,amortization_start_date         -- ���p�J�n��
          ,asset_number_new                -- ���Y�ԍ��i�C����j
          ,tag_number                      -- ���i�[�ԍ�
          ,category_id_new                 -- ���Y�J�e�S��ID�i�C����j
          ,serial_number                   -- �V���A���ԍ�
          ,asset_key_ccid                  -- ���Y�L�[CCID
          ,key_segment1                    -- ���Y�L�[�Z�O�����g1
          ,key_segment2                    -- ���Y�L�[�Z�O�����g2
          ,parent_asset_id                 -- �e���YID
          ,lease_id                        -- ���[�XID
          ,model_number                    -- ���f��
          ,in_use_flag                     -- �g�p��
          ,inventorial                     -- ���n�I���t���O
          ,owned_leased                    -- ���L��
          ,new_used                        -- �V�i/����
          ,cat_attribute1                  -- �J�e�S��DFF1
          ,cat_attribute3                  -- �J�e�S��DFF3
          ,cat_attribute4                  -- �J�e�S��DFF4
          ,cat_attribute5                  -- �J�e�S��DFF5
          ,cat_attribute6                  -- �J�e�S��DFF6
          ,cat_attribute7                  -- �J�e�S��DFF7
          ,cat_attribute8                  -- �J�e�S��DFF8
          ,cat_attribute9                  -- �J�e�S��DFF9
          ,cat_attribute10                 -- �J�e�S��DFF10
          ,cat_attribute11                 -- �J�e�S��DFF11
          ,cat_attribute12                 -- �J�e�S��DFF12
          ,cat_attribute13                 -- �J�e�S��DFF13
          ,cat_attribute14                 -- �J�e�S��DFF14
          ,cat_attribute15                 -- �J�e�S��DFF15
          ,cat_attribute16                 -- �J�e�S��DFF16
          ,cat_attribute17                 -- �J�e�S��DFF17
          ,cat_attribute18                 -- �J�e�S��DFF18
          ,cat_attribute19                 -- �J�e�S��DFF19
          ,cat_attribute20                 -- �J�e�S��DFF20
          ,cat_attribute21                 -- �J�e�S��DFF21
          ,cat_attribute22                 -- �J�e�S��DFF22
          ,cat_attribute23                 -- �J�e�S��DFF23
          ,cat_attribute24                 -- �J�e�S��DFF24
          ,cat_attribute25                 -- �J�e�S��DFF27
          ,cat_attribute26                 -- �J�e�S��DFF25
          ,cat_attribute27                 -- �J�e�S��DFF26
          ,cat_attribute28                 -- �J�e�S��DFF28
          ,cat_attribute29                 -- �J�e�S��DFF29
          ,cat_attribute30                 -- �J�e�S��DFF30
          ,cat_attribute_category_new      -- ���Y�J�e�S���R�[�h�i�C����j
          ,salvage_value                   -- �c�����z
          ,percent_salvage_value           -- �c�����z%
          ,allowed_deprn_limit_amount      -- ���p���x�z
          ,allowed_deprn_limit             -- ���p���x��
          ,ytd_deprn                       -- �N���p�݌v�z
          ,deprn_reserve                   -- ���p�݌v�z
          ,depreciate_flag                 -- ���p��v��t���O
          ,deprn_method_code               -- ���p���@
          ,basic_rate                      -- ���ʏ��p��
          ,adjusted_rate                   -- �����㏞�p��
          ,life_years                      -- �ϗp�N��
          ,life_months                     -- ����
          ,bonus_rule                      -- �{�[�i�X���[��
          ,bonus_ytd_deprn                 -- �{�[�i�X�N���p�݌v�z
          ,bonus_deprn_reserve             -- �{�[�i�X���p�݌v�z
          ,created_by                      -- �쐬��
          ,creation_date                   -- �쐬��
          ,last_updated_by                 -- �ŏI�X�V��
          ,last_update_date                -- �ŏI�X�V��
          ,last_update_login               -- �ŏI�X�V���O�C��ID
          ,request_id                      -- ���N�G�X�gID
          ,program_application_id          -- �A�v���P�[�V����ID
          ,program_id                      -- �v���O����ID
          ,program_update_date             -- �v���O�����ŏI�X�V��
        ) VALUES (
           xx01_adjustment_oif_s.NEXTVAL                           -- ID
          ,gv_fixed_asset_register                                 -- �䒠��
          ,lv_asset_number_old                                     -- ���Y�ԍ�
          ,ld_dpis_old                                             -- ���Ƌ��p���i�C���O�j
          ,ln_category_id_old                                      -- ���Y�J�e�S��ID�i�C���O�j
          ,lv_cat_attribute_category_old                           -- ���Y�J�e�S���R�[�h�i�C���O�j
          ,g_date_placed_in_service_tab(ln_loop_cnt)               -- ���Ƌ��p���i�C����j
          ,lv_description                                          -- �E�v�i�C����j
          ,g_transaction_units_tab(ln_loop_cnt)                    -- �P��
          ,lv_attribute2                                           -- �J�e�S��DFF2
          ,g_cost_tab(ln_loop_cnt)                                 -- �擾���z
          ,g_original_cost_tab(ln_loop_cnt)                        -- �����擾���z
          ,cv_yes                                                  -- �]�L�`�F�b�N�t���O
          ,cv_status                                               -- �X�e�[�^�X
          ,lv_amortized_flag                                       -- �C���z���p�t���O
          ,ld_amortization_start_date                              -- ���p�J�n��
          ,lv_asset_number_new                                     -- ���Y�ԍ��i�C����j
          ,lv_tag_number                                           -- ���i�[�ԍ�
          ,ln_category_id_new                                      -- ���Y�J�e�S��ID�i�C����j
          ,lv_serial_number                                        -- �V���A���ԍ�
          ,ln_asset_key_ccid                                       -- ���Y�L�[CCID
          ,lv_key_segment1                                         -- ���Y�L�[�Z�O�����g1
          ,lv_key_segment2                                         -- ���Y�L�[�Z�O�����g2
          ,ln_parent_asset_id                                      -- �e���YID
          ,ln_lease_id                                             -- ���[�XID
          ,lv_model_number                                         -- ���f��
          ,lv_in_use_flag                                          -- �g�p��
          ,lv_inventorial                                          -- ���n�I���t���O
          ,lv_owned_leased                                         -- ���L��
          ,lv_new_used                                             -- �V�i/����
          ,lv_cat_attribute1                                       -- �J�e�S��DFF1
          ,lv_cat_attribute3                                       -- �J�e�S��DFF3
          ,lv_cat_attribute4                                       -- �J�e�S��DFF4
          ,lv_cat_attribute5                                       -- �J�e�S��DFF5
          ,lv_cat_attribute6                                       -- �J�e�S��DFF6
          ,lv_cat_attribute7                                       -- �J�e�S��DFF7
          ,lv_cat_attribute8                                       -- �J�e�S��DFF8
          ,lv_cat_attribute9                                       -- �J�e�S��DFF9
          ,lv_cat_attribute10                                      -- �J�e�S��DFF10
          ,lv_cat_attribute11                                      -- �J�e�S��DFF11
          ,lv_cat_attribute12                                      -- �J�e�S��DFF12
          ,lv_cat_attribute13                                      -- �J�e�S��DFF13
          ,lv_cat_attribute14                                      -- �J�e�S��DFF14
          ,lv_cat_attribute15                                      -- �J�e�S��DFF15
          ,lv_cat_attribute16                                      -- �J�e�S��DFF16
          ,lv_cat_attribute17                                      -- �J�e�S��DFF17
          ,lv_cat_attribute18                                      -- �J�e�S��DFF18
          ,lv_cat_attribute19                                      -- �J�e�S��DFF19
          ,lv_cat_attribute20                                      -- �J�e�S��DFF20
          ,lv_cat_attribute21                                      -- �J�e�S��DFF21
          ,lv_cat_attribute22                                      -- �J�e�S��DFF22
          ,lv_cat_attribute23                                      -- �J�e�S��DFF23
          ,lv_cat_attribute24                                      -- �J�e�S��DFF24
          ,lv_cat_attribute25                                      -- �J�e�S��DFF27
          ,lv_cat_attribute26                                      -- �J�e�S��DFF25
          ,lv_cat_attribute27                                      -- �J�e�S��DFF26
          ,lv_cat_attribute28                                      -- �J�e�S��DFF28
          ,lv_cat_attribute29                                      -- �J�e�S��DFF29
          ,lv_cat_attribute30                                      -- �J�e�S��DFF30
          ,lv_cat_attribute_category_new                           -- ���Y�J�e�S���R�[�h�i�C����j
          ,ln_salvage_value                                        -- �c�����z
          ,ln_percent_salvage_value                                -- �c�����z%
          ,ln_allowed_deprn_limit_amount                           -- ���p���x�z
          ,ln_allowed_deprn_limit                                  -- ���p���x��
          ,ln_ytd_deprn                                            -- �N���p�݌v�z
          ,ln_deprn_reserve                                        -- ���p�݌v�z
          ,lv_depreciate_flag                                      -- ���p��v��t���O
          ,lv_deprn_method_code                                    -- ���p���@
          ,ln_basic_rate                                           -- ���ʏ��p��
          ,ln_adjusted_rate                                        -- �����㏞�p��
          ,ln_life_years                                           -- �ϗp�N��+����
          ,ln_life_months                                          -- ����
          ,lv_bonus_rule                                           -- �{�[�i�X���[��
          ,ln_bonus_ytd_deprn                                      -- �{�[�i�X�N���p�݌v�z
          ,ln_bonus_deprn_reserve                                  -- �{�[�i�X���p�݌v�z
          ,cn_created_by                                           -- �쐬��
          ,cd_creation_date                                        -- �쐬��
          ,cn_last_updated_by                                      -- �ŏI�X�V��
          ,cd_last_update_date                                     -- �ŏI�X�V��
          ,cn_last_update_login                                    -- �ŏI�X�V���O�C��ID
          ,cn_request_id                                           -- ���N�G�X�gID
          ,cn_program_application_id                               -- �A�v���P�[�V����ID
          ,cn_program_id                                           -- �v���O����ID
          ,cd_program_update_date                                  -- �v���O�����ŏI�X�V��
        )
        ;
--
        --==============================================================
        -- ���̋@���������̍X�V�i�C���j (A-6-4)
        --==============================================================
        update_vd_object_histories(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- ����ID
          ,iv_object_status     => cv_status_104                        -- �����敪
          ,ov_errbuf            => lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode           => lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg            => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �X�V�Ɏ��s�����ꍇ�A�������~
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ���̋@����(�C��)�o�^�����J�E���g
        gn_vd_modify_normal_cnt := gn_vd_modify_normal_cnt + 1;
--
      END IF;
--
    END LOOP vd_object_modify_loop;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      -- �J�[�\���N���[�Y
      IF (vd_object_modify_cur%ISOPEN) THEN
        CLOSE vd_object_modify_cur;
      END IF;
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_017a03_m_012  -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,cv_msg_017a03_t_014) -- ���̋@�����Ǘ�
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** �擾�������[�����̃G���[�n���h�� ***
    WHEN chk_no_data_found_expt THEN
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
      IF (vd_object_modify_cur%ISOPEN) THEN
        CLOSE vd_object_modify_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (vd_object_modify_cur%ISOPEN) THEN
        CLOSE vd_object_modify_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (vd_object_modify_cur%ISOPEN) THEN
        CLOSE vd_object_modify_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_vd_object_modify_data;
--
  /**********************************************************************************
   * Procedure Name   : get_vd_object_trnsf_data
   * Description      : ���̋@�����i�ړ��j�o�^�f�[�^���o(A-5)
   ***********************************************************************************/
  PROCEDURE get_vd_object_trnsf_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_vd_object_trnsf_data'; -- �v���O������
    cv_asset_category_id CONSTANT VARCHAR2(24)  := 'XXCFF1_ASSET_CATEGORY_ID';
    cv_no                CONSTANT VARCHAR2(1)   := 'N';
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
    cv_lang_ja           CONSTANT VARCHAR2(2)   := 'JA';
    cv_status            CONSTANT VARCHAR2(7)   := 'PENDING';
    cn_count_0           CONSTANT NUMBER        := 0;
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
    lv_warnmsg                VARCHAR2(5000);  -- �x�����b�Z�[�W
    lv_warn_flg               VARCHAR2(1);     -- �x���t���O
    lv_asset_number           VARCHAR2(15);    -- ���Y�ԍ�
    lv_comp_cd                VARCHAR2(25);    -- ��ЃR�[�h
    lv_segment4               VARCHAR2(25);    -- �������p���Z�O�����g-����Ȗ�
    lv_modify_flg             VARCHAR2(1);     -- �ύX�t���O
    ln_current_units          NUMBER;          -- �P�ʐ���
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���̋@�����i�ړ��j�J�[�\��
    CURSOR vd_object_trnsf_cur
    IS
      SELECT
             vohe.object_header_id                   AS object_header_id        -- ����ID
            ,vohe.object_code                        AS object_code             -- �����R�[�h
            ,vohe.moved_date                         AS moved_date              -- �ړ���
            ,vohe.machine_type                       AS machine_type            -- �@��敪
            ,vohe.dclr_place                         AS dclr_place              -- �\���n
            ,vohe.department_code                    AS department_code         -- �Ǘ�����
            ,vohe.location                           AS location                -- ���Ə�
            ,substrb(vohe.installation_address,1,30) AS installation_address    -- �ݒu�ꏊ
            ,vohe.owner_company_type                 AS owner_company_type      -- �{�ЍH��敪
      FROM
            xxcff_vd_object_headers  vohe
      WHERE
            vohe.object_header_id in (
                                      SELECT
                                             voh.object_header_id             -- ����ID
                                      FROM
                                             xxcff_vd_object_histories  voh   -- ���̋@��������
                                      WHERE
                                            voh.fa_if_flag   = cv_no         -- FA���A�g
                                        AND voh.process_type = cv_status_103 -- �ړ�
                                      )
      ORDER BY
            vohe.object_code
        FOR UPDATE NOWAIT
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
    OPEN vd_object_trnsf_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH vd_object_trnsf_cur
    BULK COLLECT INTO  g_object_header_id_tab        -- ����ID
                      ,g_object_code_tab             -- �����R�[�h
                      ,g_moved_date_tab              -- �ړ���
                      ,g_machine_type_tab            -- �@��敪
                      ,g_dclr_place_tab              -- �\���n
                      ,g_department_code_tab         -- �Ǘ�����
                      ,g_location_tab                -- ���Ə�
                      ,g_installation_address_tab    -- �ݒu�ꏊ
                      ,g_owner_company_type_tab      -- �{�ЍH��敪
    ;
    -- �ړ��Ώی����J�E���g
    gn_vd_trnsf_target_cnt := g_object_header_id_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE vd_object_trnsf_cur;
--
    IF ( gn_vd_trnsf_target_cnt = cn_count_0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_017a03_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_017a03_t_016) -- ���̋@�����i�ړ��j���
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���C�����[�v�����A
    --==============================================================
    <<vd_object_trnsf_loop>>
    FOR ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT LOOP
--
      -- �x���t���O������������
      lv_warn_flg := cv_no;
      -- �������̌����擾
      gn_vd_target_cnt := ln_loop_cnt;
--
      --==============================================================
      -- ���ڒl�`�F�b�N�i�ړ��j (A-5-1)
      --==============================================================
      -- 1.�ړ����̑��݃`�F�b�N������
      IF ( g_moved_date_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��'Y'���Z�b�g
        lv_warn_flg := cv_yes;
        -- �ړ��X�L�b�v�����J�E���g
        gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_030)                     -- �ړ���
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 2.�@��敪�̑��݃`�F�b�N������
      IF ( g_machine_type_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- �ړ��X�L�b�v�����J�E���g
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_026)                     -- �@��敪
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 3.�\���n�̑��݃`�F�b�N������
      IF ( g_dclr_place_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- �ړ��X�L�b�v�����J�E���g
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_031)                     -- �\���n
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 4.�Ǘ�����̑��݃`�F�b�N������
      IF ( g_department_code_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- �ړ��X�L�b�v�����J�E���g
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_032)                     -- �Ǘ�����
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 5.���Ə��̑��݃`�F�b�N������
      IF ( g_location_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- �ړ��X�L�b�v�����J�E���g
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_033)                     -- ���Ə�
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 6.�ݒu�ꏊ�̑��݃`�F�b�N������
      IF ( g_installation_address_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- �ړ��X�L�b�v�����J�E���g
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_034)                     -- �ݒu�ꏊ
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 7.�{��/�H��敪�̑��݃`�F�b�N������
      IF ( g_owner_company_type_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- �ړ��X�L�b�v�����J�E���g
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_035)                     -- �{��/�H��敪
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- �ړ����̓��t�`�F�b�N����
      -- �ړ��������݂���ꍇ
      IF ( g_moved_date_tab(ln_loop_cnt) IS NOT NULL ) THEN
        -- �J�����_���ԃN���[�Y�����擾���Ă��Ȃ��ꍇ
        IF ( g_cal_per_close_date IS NULL ) THEN
          BEGIN
            -- �ŐV�̃J�����_���ԃN���[�Y�����擾
            SELECT
                   MAX(fdp.calendar_period_close_date)               -- �J�����_���ԃN���[�Y��
            INTO
                   g_cal_per_close_date
            FROM   fa_deprn_periods     fdp                          -- �������p����
            WHERE
                   fdp.book_type_code   = gv_fixed_asset_register    -- �䒠���
            AND    fdp.period_close_date IS NOT NULL                 -- �N���[�Y��
            ;
          EXCEPTION
            -- �J�����_���ԃN���[�Y�����擾�ł��Ȃ��ꍇ
            WHEN NO_DATA_FOUND THEN
                          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                          ,cv_msg_017a03_m_013     -- �擾�G���[
                                                          ,cv_tkn_table            -- �g�[�N��'TABLE_NAME'
                                                          ,cv_msg_017a03_t_015     -- �������p����
                                                          ,cv_tkn_info             -- �g�[�N��'INFO'
                                                          ,cv_msg_017a03_t_018)    -- �J�����_���ԃN���[�Y��
                                                          ,1
                                                          ,5000);
            RAISE chk_no_data_found_expt;
          END;
        END IF;
        -- �ړ������J�����_���ԃN���[�Y���ȑO�̏ꍇ
        IF ( trunc(g_moved_date_tab(ln_loop_cnt)) <= trunc(g_cal_per_close_date) ) THEN
          -- �x���t���O��'N'�̏ꍇ
          IF ( lv_warn_flg = cv_no ) THEN
            -- �x���t���O��'Y'���Z�b�g
            lv_warn_flg := cv_yes;
            -- �ړ��X�L�b�v�����J�E���g
            gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
          END IF;
          -- �x�����b�Z�[�W���Z�b�g
          gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                         ,cv_msg_017a03_m_022                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                         ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                         ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                         ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                         ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                         ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                         ,cv_msg_017a03_t_030)                     -- �ړ���
                                                         ,1
                                                         ,2000);
          -- �x�����b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
        END IF;
      END IF;
--
      -- �x���t���O��'N'�̏ꍇ
      IF ( lv_warn_flg = cv_no ) THEN
        --==============================================================
        -- �Œ莑�Y���擾�i�ړ��j (A-5-2)
        --==============================================================
        BEGIN
          SELECT 
                 fab.asset_number   -- ���Y�ԍ�
                ,fab.current_units  -- �P�ʐ���
          INTO
                 lv_asset_number    -- ���Y�ԍ�
                ,ln_current_units   -- �P�ʐ���
          FROM
                fa_additions_b  fab
               ,fa_books        fb
          WHERE
                fab.tag_number      = g_object_code_tab(ln_loop_cnt)
          AND   fab.asset_id        = fb.asset_id
          AND   fb.book_type_code   = gv_fixed_asset_register
          AND   fb.date_ineffective IS NULL
          ;
        EXCEPTION
          -- �Œ莑�Y��񂪎擾�ł��Ȃ��ꍇ
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                          ,cv_msg_017a03_m_013     -- �擾�G���[
                                                          ,cv_tkn_table            -- �g�[�N��'TABLE_NAME'
                                                          ,cv_msg_017a03_t_023     -- ���Y�ڍ׏��
                                                          ,cv_tkn_info             -- �g�[�N��'INFO'
                                                          ,cv_msg_017a03_t_017)    -- �Œ莑�Y�i�ړ��j���
                                                          ,1
                                                          ,5000);
            RAISE chk_no_data_found_expt;
        END;
--
        --==============================================================
        -- �������p���Z�O�����g�l�擾 (A-5-3)
        --==============================================================
        -- ��ЃR�[�h�ɖ{�ЃR�[�h��ݒ�
        lv_comp_cd := gv_comp_cd_itoen;
--
        -- �������p����̏��p�Ȗڂ��擾
        BEGIN
          SELECT 
                 flv.attribute4   -- ���p�Ȗ�
          INTO
                 lv_segment4      -- ����Ȗ�
          FROM
                fnd_lookup_values  flv
          WHERE
                flv.lookup_type  = cv_asset_category_id
          AND   flv.lookup_code  = g_machine_type_tab(ln_loop_cnt)
          AND   flv.language     = cv_lang_ja
          AND   flv.enabled_flag = cv_yes
          AND   TRUNC(cd_od_sysdate) BETWEEN TRUNC(NVL(flv.start_date_active, cd_od_sysdate)) 
                                         AND TRUNC(NVL(flv.end_date_active, cd_od_sysdate))
          ;
        EXCEPTION
          -- �������p����̏��p�Ȗڂ��擾�ł��Ȃ��ꍇ
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                          ,cv_msg_017a03_m_019     -- �Q�ƃ^�C�v�擾�G���[
                                                          ,cv_tkn_lookup_type      -- �g�[�N��'LOOKUP_TYPE'
                                                          ,cv_msg_017a03_t_024)    -- ���̋@���Y�J�e�S���Œ�l
                                                          ,1
                                                          ,5000);
            RAISE chk_no_data_found_expt;
        END;
--
        --==============================================================
        -- �ړ�OIF�o�^ (A-5-4)
        --==============================================================
--
        -- �Z�O�����g�l�z��ݒ�(SEG1:���) : �{�ЃR�[�h��ݒ�
        g_segments_tab(1) := gv_comp_cd_itoen;
        -- �Z�O�����g�l�z��ݒ�(SEG3:����Ȗ�) : A-5-3�Ŏ擾�������p�Ȗڂ�ݒ�
        g_segments_tab(3) := lv_segment4;
--
        -- �ړ��ڍ׏��ύX�`�F�b�N���ďo�A���̕ύX�L�����`�F�b�N����
        chk_object_trnsf_data(
           iv_object_code          => g_object_code_tab(ln_loop_cnt)          -- �����R�[�h
          ,iv_dclr_place           => g_dclr_place_tab(ln_loop_cnt)           -- �\���n
          ,iv_department_code      => g_department_code_tab(ln_loop_cnt)      -- �Ǘ�����
          ,iv_location             => g_location_tab(ln_loop_cnt)             -- ���Ə�
          ,iv_installation_address => g_installation_address_tab(ln_loop_cnt) -- �ꏊ
          ,iv_owner_company_type   => g_owner_company_type_tab(ln_loop_cnt)   -- �{�ЍH��敪
          ,iv_modify_flg           => lv_modify_flg                           -- �ύX�t���O
          ,ov_errbuf               => lv_errbuf                               -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode              => lv_retcode                              -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg               => lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        -- �ύX������ꍇ
        IF ( lv_modify_flg = cv_yes ) THEN
          -- �ړ�OIF�o�^
          INSERT INTO xx01_transfer_oif(
             transfer_oif_id           -- ID
            ,book_type_code            -- �䒠��
            ,asset_number              -- ���Y�ԍ�
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
            ,created_by                -- �쐬��
            ,creation_date             -- �쐬��
            ,last_updated_by           -- �ŏI�X�V��
            ,last_update_date          -- �ŏI�X�V��
            ,last_update_login         -- �ŏI�X�V���O�C��ID
            ,request_id                -- ���N�G�X�gID
            ,program_application_id    -- �A�v���P�[�V����ID
            ,program_id                -- �v���O����ID
            ,program_update_date       -- �v���O�����ŏI�X�V��
          ) VALUES (
             xx01_transfer_oif_s.NEXTVAL              -- ID
            ,gv_fixed_asset_register                  -- �䒠��
            ,lv_asset_number                          -- ���Y�ԍ�
            ,g_moved_date_tab(ln_loop_cnt)            -- �U�֓�
            ,ln_current_units                         -- �P�ʕύX
            ,cv_yes                                   -- �]�L�`�F�b�N�t���O
            ,cv_status                                -- �X�e�[�^�X
            ,lv_comp_cd                               -- �������p���Z�O�����g-���
            ,gv_dep_cd_chosei                         -- �������p���Z�O�����g-����
            ,lv_segment4                              -- �������p���Z�O�����g-����Ȗ�
            ,cv_sub_acct_dummy                        -- �������p���Z�O�����g-�⏕�Ȗ�
            ,cv_ptnr_cd_dummy                         -- �������p���Z�O�����g-�ڋq
            ,cv_busi_cd_dummy                         -- �������p���Z�O�����g-���
            ,cv_project_dummy                         -- �������p���Z�O�����g-�\��1
            ,cv_future_dummy                          -- �������p���Z�O�����g-�\��2
            ,g_dclr_place_tab(ln_loop_cnt)            -- �\���n
            ,g_department_code_tab(ln_loop_cnt)       -- �Ǘ�����
            ,g_location_tab(ln_loop_cnt)              -- ���Ə�
            ,g_installation_address_tab(ln_loop_cnt)  -- �ꏊ
            ,g_owner_company_type_tab(ln_loop_cnt)    -- �{�ЍH��敪
            ,cn_created_by                            -- �쐬��
            ,cd_creation_date                         -- �쐬��
            ,cn_last_updated_by                       -- �ŏI�X�V��
            ,cd_last_update_date                      -- �ŏI�X�V��
            ,cn_last_update_login                     -- �ŏI�X�V���O�C��ID
            ,cn_request_id                            -- ���N�G�X�gID
            ,cn_program_application_id                -- �A�v���P�[�V����ID
            ,cn_program_id                            -- �v���O����ID
            ,cd_program_update_date                   -- �v���O�����ŏI�X�V��
          )
          ;
        ELSE
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- �ړ��X�L�b�v�����J�E���g
          gn_vd_trnsf_warn_cnt := gn_vd_trnsf_warn_cnt + 1;
          -- �x�����b�Z�[�W���Z�b�g
          gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                         ,cv_msg_017a03_m_023                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                         ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                         ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                         ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                         ,g_object_code_tab(ln_loop_cnt))                     -- ���E���p��
                                                         ,1
                                                         ,2000);
          -- �x�����b�Z�[�W�o��
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
        END IF;
--
        --==============================================================
        -- ���̋@���������̍X�V�i�ړ��j (A-5-5)
        --==============================================================
        update_vd_object_histories(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- ����ID
          ,iv_object_status     => cv_status_103                        -- �����敪
          ,ov_errbuf            => lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode           => lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg            => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �X�V�Ɏ��s�����ꍇ�A�������~
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        -- �x�����Ȃ��ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- ���̋@����(�ړ�)�o�^�����J�E���g
          gn_vd_trnsf_normal_cnt := gn_vd_trnsf_normal_cnt + 1;
        END IF;
--
      END IF;
--
    END LOOP vd_object_trnsf_loop;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      -- �J�[�\���N���[�Y
      IF (vd_object_trnsf_cur%ISOPEN) THEN
        CLOSE vd_object_trnsf_cur;
      END IF;
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_017a03_m_012  -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,cv_msg_017a03_t_014) -- ���̋@�����Ǘ�
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** �擾�������[�����̃G���[�n���h�� ***
    WHEN chk_no_data_found_expt THEN
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
      IF (vd_object_trnsf_cur%ISOPEN) THEN
        CLOSE vd_object_trnsf_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (vd_object_trnsf_cur%ISOPEN) THEN
        CLOSE vd_object_trnsf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (vd_object_trnsf_cur%ISOPEN) THEN
        CLOSE vd_object_trnsf_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_vd_object_trnsf_data;
--
  /**********************************************************************************
   * Procedure Name   : get_vd_object_add_data
   * Description      : ���̋@�����i���m��j�o�^�f�[�^���o(A-4)
   ***********************************************************************************/
  PROCEDURE get_vd_object_add_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_vd_object_add_data'; -- �v���O������
    cv_no                CONSTANT VARCHAR2(1)   := 'N';
    cv_yes               CONSTANT VARCHAR2(1)   := 'Y';
    cv_lang_ja           CONSTANT VARCHAR2(2)   := 'JA';
    cv_asset_category_id CONSTANT VARCHAR2(24)  := 'XXCFF1_ASSET_CATEGORY_ID';
    cv_date_type         CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
    cv_posting_status    CONSTANT VARCHAR2(4)   := 'POST';
    cv_queue_name        CONSTANT VARCHAR2(4)   := 'POST';
    cv_depreciate_flag   CONSTANT VARCHAR2(3)   := 'YES';
    cv_asset_type        CONSTANT VARCHAR2(11)  := 'CAPITALIZED';
    cn_count_0           CONSTANT NUMBER        := 0;
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
    lv_warnmsg                VARCHAR2(5000);  -- �x�����b�Z�[�W
    lv_warn_flg               VARCHAR2(1);     -- �x���t���O
    lv_segment1               VARCHAR2(150);   -- ���
    lv_segment2               VARCHAR2(150);   -- ���p�\��
    lv_segment3               VARCHAR2(150);   -- ���Y����
    lv_segment4               VARCHAR2(150);   -- ���p�Ȗ�
    lv_segment5               VARCHAR2(150);   -- �ϗp�N��
    lv_segment6               VARCHAR2(150);   -- ���p���@
    lv_segment7               VARCHAR2(150);   -- ���[�X���
    lv_description            VARCHAR2(80);    -- �E�v
    lv_attribute2             VARCHAR2(150);   -- DFF02�i�擾���j
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���̋@�����i���m��j�J�[�\��
    CURSOR vd_object_add_cur
    IS
      SELECT
             vohe.object_header_id                    AS object_header_id        -- ����ID
            ,vohe.object_code                         AS object_code             -- �����R�[�h
            ,vohe.manufacturer_name                   AS manufacturer_name       -- ���[�J�[��
            ,vohe.model                               AS model                   -- �@��
            ,vohe.age_type                            AS age_type                -- �N��
            ,vohe.machine_type                        AS machine_type            -- �@��敪
            ,vohe.date_placed_in_service              AS date_placed_in_service  -- ���Ƌ��p��
            ,vohe.assets_cost                         AS assets_cost             -- �擾���z
            ,vohe.quantity                            AS payables_units          -- AP����
            ,vohe.quantity                            AS fixed_assets_units      -- �P�ʐ���
            ,vohe.dclr_place                          AS dclr_place              -- �\���n
            ,vohe.department_code                     AS department_code         -- �Ǘ�����
            ,vohe.location                            AS location                -- ���Ə�
            ,substrb(vohe.installation_address,1,30)  AS installation_address    -- �ݒu�ꏊ
            ,vohe.owner_company_type                  AS owner_company_type      -- �{�ЍH��敪
            ,vohe.assets_cost                         AS payables_cost           -- ���Y�����擾���z
            ,vohe.assets_date                         AS attribute2              -- DFF02�i�擾���j
            ,vohe.object_header_id                    AS attribute14             -- DFF14�i���̋@��������ID�j
      FROM
            xxcff_vd_object_headers  vohe                            -- ���̋@�����Ǘ�
      WHERE
            vohe.object_header_id in (
                                      SELECT
                                             voh.object_header_id             -- ����ID
                                      FROM
                                             xxcff_vd_object_histories  voh   -- ���̋@��������
                                      WHERE
                                             voh.fa_if_flag             =  cv_no                                       -- FA���A�g
                                      AND    voh.process_type           =  cv_status_101                               -- ���m��
                                      AND    voh.date_placed_in_service <= LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) -- ��v����
                                      )
      ORDER BY
            vohe.object_code                                         -- �����R�[�h����
        FOR UPDATE NOWAIT
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
    OPEN vd_object_add_cur;
    -- �f�[�^�̈ꊇ�擾
    FETCH vd_object_add_cur
    BULK COLLECT INTO  g_object_header_id_tab        -- ����ID
                      ,g_object_code_tab             -- �����R�[�h
                      ,g_manufacturer_name_tab       -- ���[�J�[��
                      ,g_model_tab                   -- �@��
                      ,g_age_type_tab                -- �N��
                      ,g_machine_type_tab            -- �@��敪
                      ,g_date_placed_in_service_tab  -- ���Ƌ��p��
                      ,g_assets_cost_tab             -- �擾���z
                      ,g_payables_units_tab          -- AP����
                      ,g_fixed_assets_units_tab      -- �P�ʐ���
                      ,g_dclr_place_tab              -- �\���n
                      ,g_department_code_tab         -- �Ǘ�����
                      ,g_location_tab                -- ���Ə�
                      ,g_installation_address_tab    -- �ݒu�ꏊ
                      ,g_owner_company_type_tab      -- �{�ЍH��敪
                      ,g_payables_cost_tab           -- ���Y�����擾���z
                      ,g_assets_date_tab             -- DFF02�i�擾���j
                      ,g_object_internal_id_tab      -- DFF14�i���̋@��������ID�j
    ;
    -- ���m��Ώی����J�E���g
    gn_vd_add_target_cnt := g_object_header_id_tab.COUNT;
    -- �J�[�\���N���[�Y
    CLOSE vd_object_add_cur;
--
    IF ( gn_vd_add_target_cnt = cn_count_0 ) THEN
      --���b�Z�[�W�̐ݒ�
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_017a03_m_018  -- �擾�Ώۃf�[�^����
                                                     ,cv_tkn_get_data      -- �g�[�N��'GET_DATA'
                                                     ,cv_msg_017a03_t_013) -- ���̋@�����i���m��j���
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
    -- ***************************************
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    --==============================================================
    --���C�����[�v�����@
    --==============================================================
    <<vd_object_add_loop>>
    FOR ln_loop_cnt IN 1 .. g_object_header_id_tab.COUNT LOOP
--
      -- �x���t���O������������
      lv_warn_flg := cv_no;
      -- �������̌����擾
      gn_vd_target_cnt := ln_loop_cnt;
--
      --==============================================================
      -- ���ڒl�`�F�b�N�i���m��j (A-4-1)
      --==============================================================
      -- 1.�E�v�̑��݃`�F�b�N������
      IF ( g_manufacturer_name_tab(ln_loop_cnt)||g_model_tab(ln_loop_cnt)||g_age_type_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��'Y'���Z�b�g
        lv_warn_flg := cv_yes;
        -- ���m��X�L�b�v�����J�E���g
        gn_vd_add_warn_cnt := gn_vd_add_warn_cnt + 1;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_025)                     -- ���[�J�[�� �@�� �N��
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 2.�@��敪�̑��݃`�F�b�N������
      IF ( g_machine_type_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- ���m��X�L�b�v�����J�E���g
          gn_vd_add_warn_cnt := gn_vd_add_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_026)                     -- �@��敪
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 3.���Ƌ��p���̑��݃`�F�b�N������
      IF ( g_date_placed_in_service_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- ���m��X�L�b�v�����J�E���g
          gn_vd_add_warn_cnt := gn_vd_add_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_027)                     -- ���Ƌ��p��
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 4.�擾���i�i�擾���z�j�̑��݃`�F�b�N������
      IF ( g_assets_cost_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- ���m��X�L�b�v�����J�E���g
          gn_vd_add_warn_cnt := gn_vd_add_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_028)                     -- �擾���i
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- 5.���ʁiAP���ʁj�̑��݃`�F�b�N������
      IF ( g_payables_units_tab(ln_loop_cnt) IS NULL ) THEN
        -- �x���t���O��N�̏ꍇ
        IF ( lv_warn_flg = cv_no ) THEN
          -- �x���t���O��'Y'���Z�b�g
          lv_warn_flg := cv_yes;
          -- ���m��X�L�b�v�����J�E���g
          gn_vd_add_warn_cnt := gn_vd_add_warn_cnt + 1;
        END IF;
        -- �x�����b�Z�[�W���Z�b�g
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_021                      -- ���̋@����FA�A�g���ڑ��݃`�F�b�N�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(ln_loop_cnt)      -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(ln_loop_cnt)           -- �����R�[�h
                                                       ,cv_tkn_param_name                        -- �g�[�N��'param_name'
                                                       ,cv_msg_017a03_t_029)                     -- ����
                                                       ,1
                                                       ,2000);
        -- �x�����b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
--
      -- �x���t���O��'N'�̏ꍇ
      IF ( lv_warn_flg = cv_no ) THEN
        --==============================================================
        -- ���Y�J�e�S��CCID�擾 (A-4-2)
        --==============================================================
        -- ���Y�J�e�S���̃Z�O�����g�l���擾����
        BEGIN
          SELECT 
                 attribute1  -- ���
                ,attribute2  -- ���p�\��
                ,attribute3  -- ���Y����
                ,attribute4  -- ���p�Ȗ�
                ,attribute5  -- �ϗp�N��
                ,attribute6  -- ���p���@
                ,attribute7  -- ���[�X���
          INTO
                 lv_segment1  -- ���
                ,lv_segment2  -- ���p�\��
                ,lv_segment3  -- ���Y����
                ,lv_segment4  -- ���p�Ȗ�
                ,lv_segment5  -- �ϗp�N��
                ,lv_segment6  -- ���p���@
                ,lv_segment7  -- ���[�X���
          FROM
                fnd_lookup_values  flv
          WHERE
                flv.lookup_type  = cv_asset_category_id
          AND   flv.lookup_code  = g_machine_type_tab(ln_loop_cnt)
          AND   flv.language     = cv_lang_ja
          AND   flv.enabled_flag = cv_yes
          AND   TRUNC(cd_od_sysdate) BETWEEN TRUNC(NVL(flv.start_date_active, cd_od_sysdate)) 
                                         AND TRUNC(NVL(flv.end_date_active, cd_od_sysdate))
          ;
        EXCEPTION
          -- ���Y�J�e�S���̃Z�O�����g�l�̎擾�������[�����̏ꍇ
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                          ,cv_msg_017a03_m_019     -- �擾�G���[
                                                          ,cv_tkn_lookup_type      -- �g�[�N��'LOOKUP_TYPE'
                                                          ,cv_msg_017a03_t_024)    -- ���̋@���Y�J�e�S���Œ�l
                                                          ,1
                                                          ,5000);
            RAISE chk_no_data_found_expt;
        END;
        -- ���Y�J�e�S���̑g�����`�F�b�N����сA���Y�J�e�S��CCID���擾
        xxcff_common1_pkg.chk_fa_category(
           iv_segment1      => lv_segment1 -- ���
          ,iv_segment2      => lv_segment2 -- ���p�\��
          ,iv_segment3      => lv_segment3 -- ���Y����
          ,iv_segment4      => lv_segment4 -- ���p�Ȗ�
          ,iv_segment5      => lv_segment5 -- �ϗp�N��
          ,iv_segment6      => lv_segment6 -- ���p���@
          ,iv_segment7      => lv_segment7 -- ���[�X���
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
        -- �������p���CCID�擾 (A-4-3)
        --==============================================================
--
        -- �Z�O�����g�l�z��ݒ�(SEG1:���) : �{�ЃR�[�h��ݒ�
        g_segments_tab(1) := gv_comp_cd_itoen;
        -- �Z�O�����g�l�z��ݒ�(SEG3:����Ȗ�) : A-4-2�Ŏ擾�������p�Ȗڂ�ݒ�
        g_segments_tab(3) := lv_segment4;
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
        -- ���Ə�CCID�擾 (A-4-4)
        --==============================================================
        xxcff_common1_pkg.chk_fa_location(
           iv_segment1      => g_dclr_place_tab(ln_loop_cnt)           -- �\���n
          ,iv_segment2      => g_department_code_tab(ln_loop_cnt)      -- �Ǘ�����
          ,iv_segment3      => g_location_tab(ln_loop_cnt)             -- ���Ə�
          ,iv_segment4      => g_installation_address_tab(ln_loop_cnt) -- �ꏊ
          ,iv_segment5      => g_owner_company_type_tab(ln_loop_cnt)   -- �{�ЍH��敪
          ,on_location_id   => g_location_ccid_tab(ln_loop_cnt)        -- ���Ə�CCID
          ,ov_errbuf        => lv_errbuf                               -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode       => lv_retcode                              -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg        => lv_errmsg                               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- �ǉ�OIF�o�^ (A-4-5)
        --==============================================================
        -- �E�v���擾����
        lv_description := SUBSTRB(g_manufacturer_name_tab(ln_loop_cnt) || ' ' ||
                                  g_model_tab(ln_loop_cnt) || ' ' ||
                                  g_age_type_tab(ln_loop_cnt)
                                  , 1, 80);
        -- DFF02(�擾��)�̎擾
        IF (g_assets_date_tab(ln_loop_cnt) IS NULL) THEN
          -- DFF02(�擾��)��NULL�̎��A���Ƌ��p����YYYY/MM/DD�^�ŃZ�b�g����
          lv_attribute2 := to_char(g_date_placed_in_service_tab(ln_loop_cnt), cv_date_type);
        ELSE
          -- DFF02(�擾��)�����݂��鎞�ADFF02(�擾��)��YYYY/MM/DD�^�ŃZ�b�g����
          lv_attribute2 := to_char(g_assets_date_tab(ln_loop_cnt), cv_date_type);
        END IF;
--
        -- �ǉ�OIF�o�^
        INSERT INTO fa_mass_additions(
           mass_addition_id              -- �ǉ�OIF����ID
          ,asset_number                  -- ���Y�ԍ�
          ,tag_number                    -- ���`�[�ԍ�
          ,description                   -- �E�v
          ,asset_category_id             -- ���Y�J�e�S��CCID
          ,book_type_code                -- �䒠
          ,date_placed_in_service        -- ���Ƌ��p��
          ,fixed_assets_cost             -- �擾���z
          ,payables_units                -- AP����
          ,fixed_assets_units            -- �P�ʐ���
          ,expense_code_combination_id   -- �������p���CCID
          ,location_id                   -- ���Ə��t���b�N�X�t�B�[���hCCID
          ,posting_status                -- �]�L�X�e�[�^�X
          ,queue_name                    -- �L���[��
          ,payables_cost                 -- ���Y�����擾���z
          ,depreciate_flag               -- ���p��v��t���O
          ,asset_type                    -- ���Y�^�C�v
          ,attribute2                    -- DFF02�i�擾���j
          ,attribute14                   -- DFF14�i���̋@��������ID�j
          ,last_update_date              -- �ŏI�X�V��
          ,last_updated_by               -- �ŏI�X�V��
          ,created_by                    -- �쐬��ID
          ,creation_date                 -- �쐬��
          ,last_update_login             -- �ŏI�X�V���O�C��ID
        ) VALUES (
           fa_mass_additions_s.NEXTVAL               -- �ǉ�OIF����ID
          ,NULL                                      -- ���Y�ԍ�
          ,g_object_code_tab(ln_loop_cnt)            -- ���`�[�ԍ�
          ,lv_description                            -- �E�v
          ,g_category_ccid_tab(ln_loop_cnt)          -- ���Y�J�e�S��CCID
          ,gv_fixed_asset_register                   -- �䒠
          ,g_date_placed_in_service_tab(ln_loop_cnt) -- ���Ƌ��p��
          ,g_assets_cost_tab(ln_loop_cnt)            -- �擾���z
          ,g_payables_units_tab(ln_loop_cnt)         -- AP����
          ,g_fixed_assets_units_tab(ln_loop_cnt)     -- �P�ʐ���
          ,g_deprn_ccid_tab(ln_loop_cnt)             -- �������p���CCID
          ,g_location_ccid_tab(ln_loop_cnt)          -- ���Ə��t���b�N�X�t�B�[���hCCID
          ,cv_posting_status                         -- �]�L�X�e�[�^�X
          ,cv_queue_name                             -- �L���[��
          ,g_assets_cost_tab(ln_loop_cnt)            -- ���Y�����擾���z
          ,cv_depreciate_flag                        -- ���p��v��t���O
          ,cv_asset_type                             -- ���Y�^�C�v
          ,lv_attribute2                             -- DFF02�i�擾���j
          ,g_object_internal_id_tab(ln_loop_cnt)     -- DFF14�i���̋@��������ID�j
          ,cd_last_update_date                       -- �ŏI�X�V��
          ,cn_last_updated_by                        -- �ŏI�X�V��
          ,cn_created_by                             -- �쐬��ID
          ,cd_creation_date                          -- �쐬��
          ,cn_last_update_login                      -- �ŏI�X�V���O�C��ID
        )
        ;
--
        --==============================================================
        -- ���̋@�����Ǘ��̍X�V�i���m��j (A-4-6)
        --==============================================================
        update_vd_object_headers(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- ����ID
          ,iv_object_status     => cv_status_102                        -- �����X�e�[�^�X
          ,ov_errbuf            => lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode           => lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg            => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �X�V�Ɏ��s�����ꍇ�A�������~
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- ���̋@���������̍X�V�i���m��j (A-4-7)
        --==============================================================
        update_vd_object_histories(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- ����ID
          ,iv_object_status     => cv_status_101                        -- �����敪
          ,ov_errbuf            => lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode           => lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg            => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �X�V�Ɏ��s�����ꍇ�A�������~
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        --==============================================================
        -- ���̋@���������̍쐬�i�m��j (A-4-8)
        --==============================================================
        insert_vd_object_histories(
           iv_object_header_id  => g_object_header_id_tab(ln_loop_cnt)  -- ����ID
          ,iv_object_status     => cv_status_102                        -- �����敪
          ,ov_errbuf            => lv_errbuf                            -- �G���[�E���b�Z�[�W           --# �Œ� # 
          ,ov_retcode           => lv_retcode                           -- ���^�[���E�R�[�h             --# �Œ� #
          ,ov_errmsg            => lv_errmsg                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        -- �쐬�Ɏ��s�����ꍇ�A�������~
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
        -- ���̋@����(���m��)�o�^�����J�E���g
        gn_vd_add_normal_cnt := gn_vd_add_normal_cnt + 1;
--
      END IF;
--
    END LOOP vd_object_add_loop;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ���b�N(�r�W�[)�G���[
      -- �J�[�\���N���[�Y
      IF (vd_object_add_cur%ISOPEN) THEN
        CLOSE vd_object_add_cur;
      END IF;
--
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_017a03_m_012  -- �e�[�u�����b�N�G���[
                                                     ,cv_tkn_table         -- �g�[�N��'TABLE'
                                                     ,cv_msg_017a03_t_014) -- ���̋@�����Ǘ�
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** �擾�������[�����̃G���[�n���h�� ***
    WHEN chk_no_data_found_expt THEN
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
      IF (vd_object_add_cur%ISOPEN) THEN
        CLOSE vd_object_add_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF (vd_object_add_cur%ISOPEN) THEN
        CLOSE vd_object_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF (vd_object_add_cur%ISOPEN) THEN
        CLOSE vd_object_add_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_vd_object_add_data;
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
    cv_yes                   CONSTANT VARCHAR2(1)     := 'Y';
--
    -- *** ���[�J���ϐ� ***
    lv_deprn_run              VARCHAR2(1);  -- ���Y�䒠��
--
    -- *** ���[�J���E�J�[�\�� ***
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
    -- �R���J�����g�p�����[�^���Ȃ��ꍇ
    IF (gv_period_name IS NULL) THEN
      -- �ŐV�̉�v���Ԗ����擾����
      SELECT 
             MAX(fdp.period_name)                              -- �ŐV��v���Ԗ�
      INTO
             gv_period_name
      FROM
             fa_deprn_periods     fdp                          -- �������p����
      WHERE
             fdp.book_type_code   = gv_fixed_asset_register    -- �䒠���
      ;
      -- �ŐV��v���Ԃ��擾�ł��Ȃ��ꍇ
      IF (gv_period_name IS NULL) THEN
        RAISE chk_period_name_expt;
      END IF;
    END IF;

    BEGIN
      -- ��v���ԃ`�F�b�N
      SELECT
             fdp.deprn_run        AS deprn_run      -- �������p���s�t���O
        INTO
             lv_deprn_run
        FROM
             fa_deprn_periods     fdp   -- �������p����
       WHERE
             fdp.book_type_code    = gv_fixed_asset_register
         AND fdp.period_name       = gv_period_name
         AND fdp.period_close_date IS NULL
           ;
    EXCEPTION
      -- ��v���Ԃ̎擾�������[�����̏ꍇ
      WHEN NO_DATA_FOUND THEN
        RAISE chk_period_expt;
    END;
--
    -- �������p�����s����Ă���ꍇ
    IF lv_deprn_run = cv_yes THEN
      RAISE chk_period_expt;
    END IF;
--
  EXCEPTION
    -- *** ��v���Ԗ��擾�G���[�n���h�� ***
    WHEN chk_period_name_expt THEN
      -- �x�����b�Z�[�W���Z�b�g
      gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                     ,cv_msg_017a03_m_024                      -- �ŐV��v���Ԗ��擾�x��
                                                     ,cv_tkn_param_name                        -- �g�[�N��'PARAM_NAME'
                                                     ,gv_fixed_asset_register)                 -- �䒠���
                                                     ,1
                                                     ,2000);
      -- �x�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �I���X�e�[�^�X�͌x���Ƃ���
      ov_retcode := cv_status_warn;
--
    -- *** ��v���ԃ`�F�b�N�G���[�n���h�� ***
    WHEN chk_period_expt THEN
      -- �x�����b�Z�[�W���Z�b�g
      gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- XXCFF
                                                    ,cv_msg_017a03_m_011     -- ��v���ԃ`�F�b�N�G���[
                                                    ,cv_tkn_bk_type          -- �g�[�N��'BOOK_TYPE_CODE'
                                                    ,gv_fixed_asset_register -- ���Y�䒠��
                                                    ,cv_tkn_period           -- �g�[�N��'PERIOD_NAME'
                                                    ,gv_period_name)         -- ��v���Ԗ�
                                                    ,1
                                                    ,5000);
      -- �x�����b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �I���X�e�[�^�X�͌x���Ƃ���
      ov_retcode := cv_status_warn;
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
                                                    ,cv_msg_017a03_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_017a03_t_010) -- XXCFF:��ЃR�[�h_�{��
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
                                                    ,cv_msg_017a03_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_017a03_t_011) -- XXCFF:����R�[�h_��������
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:�䒠���_�Œ莑�Y�䒠
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_fixed_asset_register);
    IF (gv_fixed_asset_register IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_017a03_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_017a03_t_012) -- XXCFF:�䒠���_�Œ莑�Y�䒠
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
                                                    ,cv_msg_017a03_m_010  -- �v���t�@�C���擾�G���[
                                                    ,cv_tkn_prof          -- �g�[�N��'PROF_NAME'
                                                    ,cv_msg_017a03_t_037) -- XXCFF:�����@_����
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
    cn_count_1   CONSTANT NUMBER        := 1;
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
    gn_vd_target_cnt         := 0;
    gn_vd_add_target_cnt     := 0;
    gn_vd_add_normal_cnt     := 0;
    gn_vd_add_warn_cnt       := 0;
    gn_vd_add_error_cnt      := 0;
    gn_vd_trnsf_target_cnt   := 0;
    gn_vd_trnsf_normal_cnt   := 0;
    gn_vd_trnsf_warn_cnt     := 0;
    gn_vd_trnsf_error_cnt    := 0;
    gn_vd_modify_target_cnt  := 0;
    gn_vd_modify_normal_cnt  := 0;
    gn_vd_modify_warn_cnt    := 0;
    gn_vd_modify_error_cnt   := 0;
    gn_vd_retire_target_cnt  := 0;
    gn_vd_retire_normal_cnt  := 0;
    gn_vd_retire_warn_cnt    := 0;
    gn_vd_retire_error_cnt   := 0;
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
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- A-3�Ōx�����Ȃ��ꍇ�A�������p������
    IF (lv_retcode = cv_status_normal) THEN
      -- =========================================
      -- ���̋@�����i���m��j�o�^�f�[�^���o (A-4)
      -- =========================================
      get_vd_object_add_data(
         lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- A-4���G���[�̏ꍇ
      IF (lv_retcode = cv_status_error) THEN
        -- �G���[������1���Ƃ���
        gn_vd_add_error_cnt  := cn_count_1;
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���̋@�����i�ړ��j�o�^�f�[�^���o�� (A-5)
      -- =========================================
      get_vd_object_trnsf_data(
         lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- A-5���G���[�̏ꍇ
      IF (lv_retcode = cv_status_error) THEN
        -- �G���[������1���Ƃ���
        gn_vd_trnsf_error_cnt  := cn_count_1;
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���̋@�����i�C���j�o�^�f�[�^���o (A-6)
      -- =========================================
      get_vd_object_modify_data(
         lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- A-6���G���[�̏ꍇ
      IF (lv_retcode = cv_status_error) THEN
        -- �G���[������1���Ƃ���
        gn_vd_modify_error_cnt  := cn_count_1;
        RAISE global_process_expt;
      END IF;
--
      -- =========================================
      -- ���̋@�����i�����p���m��j�o�^�f�[�^���o (A-7)
      -- =========================================
      get_vd_object_ritire_data(
         lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      -- A-7���G���[�̏ꍇ
      IF (lv_retcode = cv_status_error) THEN
        -- �G���[������1���Ƃ���
        gn_vd_retire_error_cnt  := cn_count_1;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
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
    iv_period_name IN  VARCHAR2       --   1.��v���Ԗ�
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cn_count_0         CONSTANT NUMBER        := 0;
--
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
  /**********************************************************************************
   * Description      : �I������(A-9)
   ***********************************************************************************/
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
      -- �Ώی������J�E���g����Ă���ꍇ
      IF ( gn_vd_target_cnt    > 0 ) THEN
        -- �A�g�G���[�̎��̋@���������o�͂���
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                           -- XXCFF
                                                       ,cv_msg_017a03_m_020                      -- ���̋@����FA�A�g�G���[
                                                       ,cv_tkn_param_val1                        -- �g�[�N��'PARAM_VAL1'
                                                       ,g_object_header_id_tab(gn_vd_target_cnt) -- ����ID
                                                       ,cv_tkn_param_val2                        -- �g�[�N��'PARAM_VAL2'
                                                       ,g_object_code_tab(gn_vd_target_cnt))     -- �����R�[�h
                                                       ,1
                                                       ,2000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
    -- 1���ł��x�����������ꍇ
    ELSIF (gn_vd_add_warn_cnt +
           gn_vd_trnsf_warn_cnt +
           gn_vd_modify_warn_cnt +
           gn_vd_retire_warn_cnt > cn_count_0) THEN
      -- �X�e�[�^�X���x���ɂ���
      lv_retcode := cv_status_warn;
    -- �Ώی�����0���������ꍇ
    ELSIF ( gn_vd_add_target_cnt +
            gn_vd_trnsf_target_cnt +
            gn_vd_modify_target_cnt +
            gn_vd_retire_target_cnt = cn_count_0 ) THEN
      -- �X�e�[�^�X���x���ɂ���
      lv_retcode := cv_status_warn;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --���̋@�����i���m��j�o�^�����ɂ����錏���o��
    --===============================================================
    --���̋@�����i���m��j�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_017a03_m_014
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
                    ,iv_token_value1 => TO_CHAR(gn_vd_add_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_add_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_vd_add_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_add_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --===============================================================
    --���̋@�����i�ړ��j�o�^�����ɂ����錏���o��
    --===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���̋@�����i�ړ��j�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_017a03_m_015
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
                    ,iv_token_value1 => TO_CHAR(gn_vd_trnsf_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_trnsf_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_vd_trnsf_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_trnsf_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --===============================================================
    --���̋@�����i�C���j�o�^�����ɂ����錏���o��
    --===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���̋@�����i�C���j�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_017a03_m_016
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
                    ,iv_token_value1 => TO_CHAR(gn_vd_modify_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_modify_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_vd_modify_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_modify_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --===============================================================
    --���̋@�����i�����p���m��j�o�^�����ɂ����錏���o��
    --===============================================================
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --���̋@�����i�����p���m��j�쐬���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_017a03_m_017
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
                    ,iv_token_value1 => TO_CHAR(gn_vd_retire_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_retire_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_vd_retire_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_vd_retire_error_cnt)
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
END XXCFF017A03C;
/
