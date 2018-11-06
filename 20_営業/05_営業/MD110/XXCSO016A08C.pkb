CREATE OR REPLACE PACKAGE BODY APPS.XXCSO016A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO016A08C(bosy)
 * Description      : �������p�z���𕨌��ʌ������p�z���e�[�u���ɓo�^���܂��B
 *
 * MD.050           : MD050_CSO_016_A08_�����ʌ������p�z�X�V
 *
 * Version          : 1.00
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        �������� (A-1)
 *  get_profile_info            �v���t�@�C���l�擾 (A-2)
 *  delete_object_deprn_data    �����ʌ������p�z���e�[�u���폜 (A-3)
 *  insert_object_deprn_data    �����ʌ������p�z���o�^ (A-4)
 *  create_csv_rec              �����ʌ������p�z���CSV�o�� (A-5)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                  �I������ (A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018-10-31    1.0   Yazaki.Eiji        �V�K�쐬
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- �Ώی���
  gn_normal_cnt             NUMBER;                    -- ���팏��
  gn_error_cnt              NUMBER;                    -- �G���[����
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
  -- ���b�N�G���[
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ���o�ΏۂȂ��G���[
  no_data_expt EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A08C';                   -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';                          -- �A�v���P�[�V�����Z�k��
  cv_app_name_ccp        CONSTANT VARCHAR2(5)   := 'XXCCP';                          -- �A�h�I���F���ʁEIF�̈�
--
  -- ���蕶��
  cv_dqu                     CONSTANT VARCHAR2(1)     := '"';                         -- �����񊇂�
  cv_comma                   CONSTANT VARCHAR2(1)     := ',';                         -- �J���}
  -- ���[�X�敪
  cv_fin_lease_kbn           CONSTANT VARCHAR2(1)     := '1';                        -- ���[�X�敪�FFIN���[�X�䒠
  cv_fixed_assets_lease_kbn  CONSTANT VARCHAR2(1)     := '4';                        -- ���[�X�敪�F�Œ莑�Y�䒠
--
  -- ***��񒊏o�p
  cv_flag_y              CONSTANT VARCHAR2(1)  := 'Y';
  cv_flag_n              CONSTANT VARCHAR2(1)  := 'N';
  ct_language            CONSTANT fnd_lookup_values.language%TYPE      := USERENV('LANG');
  ct_adj_type_expense    CONSTANT fa_adjustments.adjustment_type%TYPE  := 'EXPENSE'; -- �����^�C�v
--
  -- ���b�Z�[�W�R�[�h
  cv_msg_ccp_90008    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';     -- �R���J�����g���̓p�����[�^�Ȃ����b�Z�[�W
  cv_msg_cso_00014    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';     -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_cso_00278    CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00278';     -- ���b�N�G���[���b�Z�[�W
  cv_msg_cso_00072    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00072';     -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_cso_00399    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00399';     -- �Ώی���0�����b�Z�[�W
  cv_msg_cso_00886    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00886';     -- �f�[�^�o�^�G���[
  cv_msg_cso_00016    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00016';     -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_cso_00888    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00888';     -- �����ʌ������p�z���CSV�o�̓w�b�_�m�[�g
  cv_msg_ccp_90000    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';     -- �Ώی������b�Z�[�W
  cv_msg_ccp_90001    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';     -- �����������b�Z�[�W
  cv_msg_ccp_90002    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';     -- �G���[�������b�Z�[�W
  cv_msg_ccp_90004    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';     -- ����I�����b�Z�[�W
  cv_msg_ccp_90005    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';     -- �x���I�����b�Z�[�W
  cv_msg_ccp_90006    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';     -- �G���[�I���S���[���o�b�N���b�Z�[�W
--
  -- �g�[�N���R�[�h
  cv_tkn_err_msg      CONSTANT VARCHAR2(20) := 'ERR_MSG';               -- SQL�G���[���b�Z�[�W
  cv_tkn_err_msg2     CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';           -- SQL�G���[���b�Z�[�W2
  cv_tkn_prof_name    CONSTANT VARCHAR2(20) := 'PROF_NAME';             -- �v���t�@�C����
  cv_tkn_proc_name    CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';       -- ���o������
  cv_tkn_table        CONSTANT VARCHAR2(20) := 'TABLE';                 -- �e�[�u����
  cv_tkn_count        CONSTANT VARCHAR2(20) := 'COUNT';                 -- ��������
--
  -- DEBUG_LOG�p���b�Z�[�W
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< �V�X�e�����t�擾���� >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'lv_sysdate          = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< ���[���o�b�N���܂��� >>' ;
--
  -- ***�v���t�@�C��
  cv_fin_lease_books          CONSTANT VARCHAR2(40) := 'XXCFF1_FIN_LEASE_BOOKS';     -- �䒠��_FIN���[�X�䒠
  cv_fixed_assets_books       CONSTANT VARCHAR2(40) := 'XXCFF1_FIXED_ASSETS_BOOKS';  -- �䒠��
  cv_prof_fin_lease_books     CONSTANT VARCHAR2(40) := 'XXCFF:�䒠��_FIN���[�X�䒠'; -- �v���t�@�C��:FIN���[�X�䒠
  cv_prof_fixed_assets_books  CONSTANT VARCHAR2(40) := 'XXCFF:�䒠��';               -- �v���t�@�C��:�Œ莑�Y�䒠
--
  cv_table_name       CONSTANT VARCHAR2(100) := '�����ʌ������p�z���e�[�u��'; -- �����ʌ������p�z���e�[�u��
  cv_proc_name        CONSTANT VARCHAR2(100) := '�����ʌ������p�z���';         -- �����ʌ������p�z���
--
  -- ***���t����
  cv_yyyymm              CONSTANT VARCHAR2(7)  := 'YYYY-MM';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --
  -- ***�o���N�t�F�b�`�p��`
  TYPE g_lease_kbn_ttype              IS TABLE OF XXCSO_object_deprn.lease_kbn%TYPE INDEX BY PLS_INTEGER;
  TYPE g_period_name_ttype            IS TABLE OF XXCSO_object_deprn.period_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_header_id_ttype       IS TABLE OF XXCSO_object_deprn.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_code_ttype            IS TABLE OF XXCSO_object_deprn.object_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_class_ttype            IS TABLE OF XXCSO_object_deprn.lease_class%TYPE INDEX BY PLS_INTEGER;
  TYPE g_machine_type_ttype           IS TABLE OF XXCSO_object_deprn.machine_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_header_id_ttype     IS TABLE OF XXCSO_object_deprn.contract_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_number_ttype        IS TABLE OF XXCSO_object_deprn.contract_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_id_ttype       IS TABLE OF XXCSO_object_deprn.contract_line_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_num_ttype      IS TABLE OF XXCSO_object_deprn.contract_line_num%TYPE INDEX BY PLS_INTEGER;
  TYPE g_asset_id_ttype               IS TABLE OF XXCSO_object_deprn.asset_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_asset_number_ttype           IS TABLE OF XXCSO_object_deprn.asset_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_deprn_amount_ttype           IS TABLE OF XXCSO_object_deprn.deprn_amount%TYPE INDEX BY PLS_INTEGER;
--
  -- ***�o���N�t�F�b�`�p��` �����ʌ������p�z���e�[�u��
  TYPE g_t_depreciation_id_ttype        IS TABLE OF XXCSO_object_deprn.depreciation_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_lease_kbn_ttype              IS TABLE OF XXCSO_object_deprn.lease_kbn%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_period_name_ttype            IS TABLE OF XXCSO_object_deprn.period_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_object_header_id_ttype       IS TABLE OF XXCSO_object_deprn.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_object_code_ttype            IS TABLE OF XXCSO_object_deprn.object_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_lease_class_ttype            IS TABLE OF XXCSO_object_deprn.lease_class%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_machine_type_ttype           IS TABLE OF XXCSO_object_deprn.machine_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_contract_header_id_ttype     IS TABLE OF XXCSO_object_deprn.contract_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_contract_number_ttype        IS TABLE OF XXCSO_object_deprn.contract_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_contract_line_id_ttype       IS TABLE OF XXCSO_object_deprn.contract_line_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_contract_line_num_ttype      IS TABLE OF XXCSO_object_deprn.contract_line_num%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_asset_id_ttype               IS TABLE OF XXCSO_object_deprn.asset_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_asset_number_ttype           IS TABLE OF XXCSO_object_deprn.asset_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_deprn_amount_ttype           IS TABLE OF XXCSO_object_deprn.deprn_amount%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_created_by_ttype             IS TABLE OF XXCSO_object_deprn.created_by%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_creation_date_ttype          IS TABLE OF XXCSO_object_deprn.creation_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_last_updated_by_ttype        IS TABLE OF XXCSO_object_deprn.last_updated_by%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_last_update_date_ttype       IS TABLE OF XXCSO_object_deprn.last_update_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_last_update_login_ttype      IS TABLE OF XXCSO_object_deprn.last_update_login%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_request_id_ttype             IS TABLE OF XXCSO_object_deprn.request_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_program_appli_id_ttype       IS TABLE OF XXCSO_object_deprn.program_application_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_program_id_ttype             IS TABLE OF XXCSO_object_deprn.program_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_t_program_update_date_ttype    IS TABLE OF XXCSO_object_deprn.program_update_date%TYPE INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ***�o���N�t�F�b�`�p��`
  g_lease_kbn_tab               g_lease_kbn_ttype;
  g_period_name_tab             g_period_name_ttype;
  g_object_header_id_tab        g_object_header_id_ttype;
  g_object_code_tab             g_object_code_ttype;
  g_lease_class_tab             g_lease_class_ttype;
  g_machine_type_tab            g_machine_type_ttype;
  g_contract_header_id_tab      g_contract_header_id_ttype;
  g_contract_number_tab         g_contract_number_ttype;
  g_contract_line_id_tab        g_contract_line_id_ttype;
  g_contract_line_num_tab       g_contract_line_num_ttype;
  g_asset_id_tab                g_asset_id_ttype;
  g_asset_number_tab            g_asset_number_ttype;
  g_deprn_amount_tab            g_deprn_amount_ttype;
--
  -- ***�o���N�t�F�b�`�p��`  �����ʌ������p�z���e�[�u��
  g_t_depreciation_id_tab         g_t_depreciation_id_ttype;
  g_t_lease_kbn_tab               g_t_lease_kbn_ttype;
  g_t_period_name_tab             g_t_period_name_ttype;
  g_t_object_header_id_tab        g_t_object_header_id_ttype;
  g_t_object_code_tab             g_t_object_code_ttype;
  g_t_lease_class_tab             g_t_lease_class_ttype;
  g_t_machine_type_tab            g_t_machine_type_ttype;
  g_t_contract_header_id_tab      g_t_contract_header_id_ttype;
  g_t_contract_number_tab         g_t_contract_number_ttype;
  g_t_contract_line_id_tab        g_t_contract_line_id_ttype;
  g_t_contract_line_num_tab       g_t_contract_line_num_ttype;
  g_t_asset_id_tab                g_t_asset_id_ttype;
  g_t_asset_number_tab            g_t_asset_number_ttype;
  g_t_deprn_amount_tab            g_t_deprn_amount_ttype;
  g_t_created_by_tab              g_t_created_by_ttype;
  g_t_creation_date_tab           g_t_creation_date_ttype;
  g_t_last_updated_by_tab         g_t_last_updated_by_ttype;
  g_t_last_update_date_tab        g_t_last_update_date_ttype;
  g_t_last_update_login_tab       g_t_last_update_login_ttype;
  g_t_request_id_tab              g_t_request_id_ttype;
  g_t_program_application_id_tab  g_t_program_appli_id_ttype;
  g_t_program_id_tab              g_t_program_id_ttype;
  g_t_program_update_date_tab     g_t_program_update_date_ttype;
--
  -- �v���t�@�C���l
  gv_fin_lease_books           VARCHAR2(100);    -- FIN���[�X�䒠��
  gv_fixed_assets_books        VARCHAR2(100);    -- �Œ莑�Y�䒠��
--
  -- �ŐV��v���Ԗ�
  gv_max_period_name           VARCHAR2(100);    -- �ŐV��v���Ԗ�
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
    g_lease_kbn_tab.DELETE;           -- ���[�X�敪
    g_period_name_tab.DELETE;         -- ��v���Ԗ�
    g_object_header_id_tab.DELETE;    -- ��������ID
    g_object_code_tab.DELETE;         -- �����R�[�h
    g_lease_class_tab.DELETE;         -- ���[�X���
    g_machine_type_tab.DELETE;        -- �@��敪
    g_contract_header_id_tab.DELETE;  -- �_�����ID
    g_contract_number_tab.DELETE;     -- �_��ԍ�
    g_contract_line_id_tab.DELETE;    -- �_�񖾍ד���ID
    g_contract_line_num_tab.DELETE;   -- �_�񖾍הԍ�
    g_asset_id_tab.DELETE;            -- ���YID
    g_asset_number_tab.DELETE;        -- ���Y�ԍ�
    g_deprn_amount_tab.DELETE;        -- �������p�z
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
   * Procedure Name   : delete_collections_tbl
   * Description      : �R���N�V�����폜
   ***********************************************************************************/
  PROCEDURE delete_collections_tbl(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_collections_tbl'; -- �v���O������
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
    g_t_depreciation_id_tab.DELETE;        -- �������p�zID
    g_t_lease_kbn_tab.DELETE;              -- ���[�X�敪
    g_t_period_name_tab.DELETE;            -- ��v���Ԗ�
    g_t_object_header_id_tab.DELETE;       -- ��������ID
    g_t_object_code_tab.DELETE;            -- �����R�[�h
    g_t_lease_class_tab.DELETE;            -- ���[�X���
    g_t_machine_type_tab.DELETE;           -- �@��敪
    g_t_contract_header_id_tab.DELETE;     -- �_�����ID
    g_t_contract_number_tab.DELETE;        -- �_��ԍ�
    g_t_contract_line_id_tab.DELETE;       -- �_�񖾍ד���ID
    g_t_contract_line_num_tab.DELETE;      -- �_�񖾍הԍ�
    g_t_asset_id_tab.DELETE;               -- ���YID
    g_t_asset_number_tab.DELETE;           -- ���Y�ԍ�
    g_t_deprn_amount_tab.DELETE;           -- �������p�z
    g_t_created_by_tab.DELETE;             -- �쐬��
    g_t_creation_date_tab.DELETE;          -- �쐬��
    g_t_last_updated_by_tab.DELETE;        -- �ŏI�X�V��
    g_t_last_update_date_tab.DELETE;       -- �ŏI�X�V��
    g_t_last_update_login_tab.DELETE;      -- �ŏI�X�V���O�C��
    g_t_request_id_tab.DELETE;             -- �v��ID
    g_t_program_application_id_tab.DELETE; -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    g_t_program_id_tab.DELETE;             -- �R���J�����g�E�v���O����ID
    g_t_program_update_date_tab.DELETE;    -- �v���O�����X�V��
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
  END delete_collections_tbl;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h              --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';             -- �v���O������
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
    lv_sysdate           VARCHAR2(100);    -- �V�X�e�����t
    lv_init_msg          VARCHAR2(5000);   -- �G���[���b�Z�[�W���i�[
    lv_csv_header        VARCHAR2(5000);   -- CSV�w�b�_���ڏo�͗p
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
    -- �V�X�e�����t�擾
    lv_sysdate := TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS');
    -- �擾�����V�X�e�����t�����O�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || lv_sysdate || CHR(10) ||
                 ''
    );
    -- ���̓p�����[�^�Ȃ����b�Z�[�W�o��
    lv_init_msg   := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name_ccp       --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_msg_ccp_90008      --���b�Z�[�W�R�[�h
                     );
    --���b�Z�[�W�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''           || CHR(10) ||   -- ��s�̑}��
                 lv_init_msg  || CHR(10) ||
                 ''                           -- ��s�̑}��
    );
    -- CSV�w�b�_���ڏo��
    lv_csv_header := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_cso_00888    -- ���b�Z�[�W�R�[�h
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_csv_header
    );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : �v���t�@�C���l�擾 (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_profile_info';            -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �v���t�@�C���l���擾
    -- ===============================
--
    -- �䒠��_FIN���[�X�䒠
    gv_fin_lease_books := FND_PROFILE.VALUE(cv_fin_lease_books);
    IF (gv_fin_lease_books IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_cso_00014             -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_name             -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_prof_fin_lease_books      -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �䒠��
    gv_fixed_assets_books := FND_PROFILE.VALUE(cv_fixed_assets_books);
    IF (gv_fixed_assets_books IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  -- �A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_cso_00014             -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_prof_name             -- �g�[�N���R�[�h1
                    ,iv_token_value1 => cv_prof_fixed_assets_books   -- �g�[�N���l1
                   );
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
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : delete_object_deprn_data
   * Description      : �����ʌ������p�z���e�[�u���폜(A-3)
   ***********************************************************************************/
--
  PROCEDURE delete_object_deprn_data(
     ov_errbuf            OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_object_deprn_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf             VARCHAR2(5000);      -- �G���[�E���b�Z�[�W
    lv_retcode            VARCHAR2(1);         -- ���^�[���E�R�[�h
    lv_errmsg             VARCHAR2(5000);      -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    --  ���b�N�擾�p
    CURSOR  lock_cur
    IS
      SELECT  xod.ROWID            lock_rowid      -- ���b�N�p�[����
      FROM    xxcso_object_deprn   xod             -- �����ʌ������p�z���e�[�u��
      WHERE   xod.period_name = gv_max_period_name -- ��v���Ԗ�
      FOR UPDATE NOWAIT;
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
  -- �ő��v���Ԏ擾
    SELECT  MAX(fdp.period_name)    max_period_name                           -- �ő��v����
    INTO    gv_max_period_name                                                -- ��v���Ԗ�
    FROM    fa_deprn_periods        fdp                                       -- �������p����
    WHERE   fdp.book_type_code IN(gv_fin_lease_books ,gv_fixed_assets_books)  -- ���Y�䒠�R�[�h
    AND     fdp.deprn_run  = cv_flag_y;                                       -- �������p���s�t���O
--
    --== �����ʌ������p�z���e�[�u�����b�N ==--
      --  ���b�N�p�J�[�\���I�[�v��
      OPEN  lock_cur;
      --  ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_cur;
--
    BEGIN
    -- �ő��v���ԃf�[�^�폜
      DELETE FROM
        xxcso_object_deprn  xod                          -- �����ʌ������p�z���e�[�u��
      WHERE   xod.period_name = gv_max_period_name;      -- ��v���Ԗ�
--
    EXCEPTION
      WHEN OTHERS THEN
      -- �f�[�^�폜�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name         -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_cso_00072     -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table         -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_table_name        -- �G���[�����̃e�[�u����
                     ,iv_token_name2  => cv_tkn_err_msg2      -- �g�[�N���R�[�h2
                     ,iv_token_value2 => SQLERRM              -- �g�[�N���l2
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END;
---
  EXCEPTION
    -- ���b�N�G���[
    WHEN lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name              -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_cso_00278         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_table_name            -- �G���[�����̃e�[�u����
                     ,iv_token_name2  => cv_tkn_err_msg           -- �g�[�N���R�[�h2
                     ,iv_token_value2 => SQLERRM                  -- �g�[�N���l2
                    );
      lv_errbuf := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
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
  END delete_object_deprn_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_object_deprn_data
   * Description      : �����ʌ������p�z���o�^ (A-4)
   ***********************************************************************************/
  PROCEDURE insert_object_deprn_data(
    ov_errbuf         OUT    VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT    VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT    VARCHAR2)      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_object_deprn_data'; -- �v���O������
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
--
    -- *** ���[�J���萔 ***
  -- ***�Q�ƃ^�C�v
    cv_xxcff1_lease_class_check  CONSTANT VARCHAR2(30)   := 'XXCFF1_LEASE_CLASS_CHECK'; -- ���[�X��ʃ`�F�b�N
    cv_xxcff1_asset_category_id  CONSTANT VARCHAR2(30)  := 'XXCFF1_ASSET_CATEGORY_ID';  -- �Q�ƃ^�C�v�F���̋@���Y�J�e�S���Œ�l
--
    cv_attribute9_1           CONSTANT VARCHAR2(1)    := '1';                        -- DFF9�F1
    cv_attribute9_3           CONSTANT VARCHAR2(1)    := '3';                        -- DFF9�F3
--
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �����ʌ������p�f�[�^���o�J�[�\��
    CURSOR gl_get_object_deprn_cur
    IS
      SELECT xod.lease_kbn             lease_kbn                  -- ���[�X�敪
            ,xod.period_name           period_name                -- ��v���Ԗ�
            ,xod.object_header_id      object_header_id           -- ��������ID
            ,xod.object_code           object_code                -- �����R�[�h
            ,xod.lease_class           lease_class                -- ���[�X���
            ,xod.machine_type          machine_type               -- �@��敪
            ,xod.contract_header_id    contract_header_id         -- �_�����ID
            ,xod.contract_number       contract_number            -- �_��ԍ�
            ,xod.contract_line_id      contract_line_id           -- �_�񖾍ד���ID
            ,xod.contract_line_num     contract_line_num          -- �_�񖾍הԍ�
            ,xod.asset_id              asset_id                   -- ���YID
            ,xod.asset_number          asset_number               -- ���Y�ԍ�
            ,SUM(xod.deprn_amount)     deprn_amount               -- �������p�z
      FROM  (SELECT
                    /*+ 
                        LEADING(fdp fdd fab)
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(fdd FA_DEPRN_DETAIL_N2)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xcl XXCFF_CONTRACT_LINES_PK)
                        INDEX(obh XXCFF_OBJECT_HEADERS_PK)
                        INDEX(gcc GL_CODE_COMBINATIONS_N4)
                        INDEX(xch XXCFF_CONTRACT_HEADERS_PK)
                     */
                    cv_fin_lease_kbn          lease_kbn           -- ���[�X�敪
                   ,fdp.period_name           period_name         -- ��v���Ԗ�
                   ,obh.object_header_id      object_header_id    -- ��������ID
                   ,obh.object_code           object_code         -- �����R�[�h
                   ,obh.lease_class           lease_class         -- ���[�X���
                   ,NULL                      machine_type        -- �@��敪
                   ,xch.contract_header_id    contract_header_id  -- �_�����ID
                   ,xch.contract_number       contract_number     -- �_��ԍ�
                   ,xcl.contract_line_id      contract_line_id    -- �_�񖾍ד���ID
                   ,xcl.contract_line_num     contract_line_num   -- �_�񖾍הԍ�
                   ,fab.asset_id              asset_id            -- ���YID
                   ,fab.asset_number          asset_number        -- ���Y�ԍ�
                   ,fdd.deprn_amount - fdd.deprn_adjustment_amount  deprn_amount    -- �������p�z
             FROM
                   fa_deprn_detail            fdd       -- �������p�ڍ׏��
                  ,fa_additions_b             fab       -- ���Y�ڍ׏��
                  ,fa_deprn_periods           fdp       -- �������p����
                  ,gl_code_combinations       gcc       -- ����Ȗڑg�����}�X�^
                  ,xxcff_object_headers       obh       -- ���[�X����
                  ,xxcff_contract_headers     xch       -- ���[�X�_��w�b�_
                  ,xxcff_contract_lines       xcl       -- ���[�X�_�񖾍�
             WHERE    fab.asset_id                                  = fdd.asset_id                    -- ��������ID
             AND      fdp.book_type_code                            = gv_fin_lease_books              -- ���Y�䒠�R�[�h
             AND      fdp.book_type_code                            = fdd.book_type_code              -- ���Y�䒠�R�[�h
             AND      fdp.period_counter                            = fdd.period_counter              -- ��v����
             AND      fdd.deprn_expense_je_line_num                 IS NOT NULL                       -- �������p�x���ڍהԍ�
             AND      fdd.deprn_expense_ccid                        = gcc.code_combination_id         -- �b�b�h�c
             AND      gv_max_period_name                            = fdp.period_name                 -- �ŐV��v����
             AND      xcl.object_header_id                          = obh.object_header_id            -- ����ID
             AND      TO_NUMBER(fab.attribute10)                    = xcl.contract_line_id            -- �_�񖾍ד���ID
             AND      xcl.contract_header_id                        = xch.contract_header_id          -- �_�����ID
             AND      (obh.lease_class ,gcc.segment3 ,gcc.segment4) IN (SELECT
                                                                               /*+ 
                                                                                   LEADING(flv xlcv.ffvs xlcv.ffvt xlcv.ffv)
                                                                                   INDEX(flv FND_LOOKUP_VALUES_U2)
                                                                                   INDEX(xlcv.ffv FND_FLEX_VALUES_N1)
                                                                                   INDEX(xlcv.ffvt FND_FLEX_VALUES_TL_U1)
                                                                                   INDEX(xlcv.ffvs FND_FLEX_VALUE_SETS_U2)
                                                                                */
                                                                               xlcv.lease_class_code  lease_class_code -- ���[�X��ʃR�[�h
                                                                              ,xlcv.deprn_acct        deprn_acct       -- �U�֌�����Ȗ�
                                                                              ,xlcv.deprn_sub_acct    deprn_sub_acct   -- �U�֌��⏕�Ȗ�
                                                                        FROM   xxcff_lease_class_v   xlcv  -- ���[�X��ʃr���[
                                                                              ,fnd_lookup_values     flv   -- ���[�X��ʃ`�F�b�N
                                                                        WHERE  flv.lookup_code                              = xlcv.lease_class_code
                                                                        AND    flv.lookup_type                              = cv_xxcff1_lease_class_check
                                                                        AND    flv.attribute1                               = cv_flag_y
                                                                        AND    flv.language                                 = ct_language
                                                                        AND    flv.enabled_flag                             = cv_flag_y
                                                                        AND    LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
                                                                                                                                AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
                                                                       )
             UNION ALL
             SELECT
                    /*+ 
                        LEADING(b)
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(faj FA_ADJUSTMENTS_N4)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xcl XXCFF_CONTRACT_LINES_PK)
                        INDEX(obh XXCFF_OBJECT_HEADERS_PK)
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                        INDEX(xch XXCFF_CONTRACT_HEADERS_PK)
                     */
                    cv_fin_lease_kbn          lease_kbn           -- ���[�X�敪
                   ,fdp.period_name           period_name         -- ��v���Ԗ�
                   ,obh.object_header_id      object_header_id    -- ��������ID
                   ,obh.object_code           object_code         -- �����R�[�h
                   ,obh.lease_class           lease_class         -- ���[�X���
                   ,NULL                      machine_type        -- �@��敪
                   ,xch.contract_header_id    contract_header_id  -- �_�����ID
                   ,xch.contract_number       contract_number     -- �_��ԍ�
                   ,xcl.contract_line_id      contract_line_id    -- �_�񖾍ד���ID
                   ,xcl.contract_line_num     contract_line_num   -- �_�񖾍הԍ�
                   ,fab.asset_id              asset_id            -- ���YID
                   ,fab.asset_number          asset_number        -- ���Y�ԍ�
                   ,faj.adjustment_amount     deprn_amount        -- �������p�z
             FROM
                   fa_adjustments             faj       -- ���Y�������
                  ,fa_additions_b             fab       -- ���Y�ڍ׏��
                  ,fa_deprn_periods           fdp       -- �������p����
                  ,gl_code_combinations       gcc       -- ����Ȗڑg�����}�X�^
                  ,xxcff_object_headers       obh       -- ���[�X����
                  ,(SELECT
                           /*+ 
                               QB_NAME(b)
                               LEADING(flv xlcv.ffvs xlcv.ffvt xlcv.ffv)
                               INDEX(flv FND_LOOKUP_VALUES_U2)
                               INDEX(xlcv.ffv FND_FLEX_VALUES_N1)
                               INDEX(xlcv.ffvt FND_FLEX_VALUES_TL_U1)
                               INDEX(xlcv.ffvs FND_FLEX_VALUE_SETS_U2)
                            */
                           xlcv.lease_class_code  lease_class_code -- ���[�X��ʃR�[�h
                          ,xlcv.deprn_acct        deprn_acct       -- �U�֌�����Ȗ�
                          ,xlcv.deprn_sub_acct    deprn_sub_acct   -- �U�֌��⏕�Ȗ�
                    FROM   xxcff_lease_class_v   xlcv  -- ���[�X��ʃr���[
                          ,fnd_lookup_values     flv   -- ���[�X��ʃ`�F�b�N
                    WHERE  flv.lookup_code                              = xlcv.lease_class_code
                    AND    flv.lookup_type                              = cv_xxcff1_lease_class_check
                    AND    flv.attribute1                               = cv_flag_y
                    AND    flv.language                                 = ct_language
                    AND    flv.enabled_flag                             = cv_flag_y
                    AND    LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
                                                                            AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
                   )                          xlcv2
                  ,xxcff_contract_headers     xch       -- ���[�X�_��w�b�_
                  ,xxcff_contract_lines       xcl       -- ���[�X�_�񖾍�
             WHERE    fab.asset_id                  = faj.asset_id                    -- ��������ID
             AND      fdp.book_type_code            = gv_fin_lease_books              -- ���Y�䒠�R�[�h
             AND      fdp.book_type_code            = faj.book_type_code              -- ���Y�䒠�R�[�h
             AND      fdp.period_counter            = faj.period_counter_created      -- ��v����
             AND      faj.adjustment_type           = ct_adj_type_expense             -- �����^�C�v�FEXPENSE
             AND      faj.code_combination_id      = gcc.code_combination_id          -- �b�b�h�c
             AND      gcc.segment3                  = xlcv2.deprn_acct                -- �U�֌�����Ȗ�
             AND      gcc.segment4                  = xlcv2.deprn_sub_acct            -- �U�֌��⏕����Ȗ�
             AND      gv_max_period_name            = fdp.period_name                 -- �ŐV��v����
             AND      xcl.object_header_id          = obh.object_header_id            -- ����ID
             AND      TO_NUMBER(fab.attribute10)    = xcl.contract_line_id            -- �_�񖾍ד���ID
             AND      xcl.contract_header_id        = xch.contract_header_id          -- �_�����ID
             AND      obh.lease_class               = xlcv2.lease_class_code          -- ���[�X���
             UNION ALL
             SELECT
                    /*+ 
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(flv FND_LOOKUP_VALUES_U2)
                        INDEX(fdd FA_DEPRN_DETAIL_N2)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xvoh XXCFF_VD_OBJECT_HEADERS_U01)
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     */
                    cv_fixed_assets_lease_kbn lease_kbn           -- ���[�X�敪
                   ,fdp.period_name           period_name         -- ��v���Ԗ�
                   ,xvoh.object_header_id     object_header_id    -- ��������ID
                   ,xvoh.object_code          object_code         -- �����R�[�h
                   ,xvoh.lease_class          lease_class         -- ���[�X���
                   ,xvoh.machine_type         machine_type        -- �@��敪
                   ,NULL                      contract_header_id  -- �_�����ID
                   ,NULL                      contract_number     -- �_��ԍ�
                   ,NULL                      contract_line_id    -- �_�񖾍ד���ID
                   ,NULL                      contract_line_num   -- �_�񖾍הԍ�
                   ,fab.asset_id              asset_id            -- ���YID
                   ,fab.asset_number          asset_number        -- ���Y�ԍ�
                   ,fdd.deprn_amount - fdd.deprn_adjustment_amount  deprn_amount    -- �������p�z
             FROM
                   fa_deprn_detail            fdd       -- �������p�ڍ׏��
                  ,fa_additions_b             fab       -- ���Y�ڍ׏��
                  ,fa_deprn_periods           fdp       -- �������p����
                  ,gl_code_combinations       gcc       -- ����Ȗڑg�����}�X�^
                  ,xxcff_vd_object_headers    xvoh      -- ���̋@����
                  ,fnd_lookup_values          flv       -- ���̋@���Y�J�e�S���Œ�l
             WHERE    fab.asset_id                  = fdd.asset_id                    -- ��������ID
             AND      fdp.book_type_code            = gv_fixed_assets_books           -- ���Y�䒠�R�[�h
             AND      fdp.book_type_code            = fdd.book_type_code              -- �䒠�䒠�R�[�h
             AND      fdp.period_counter            = fdd.period_counter              -- ��v����
             AND      fdd.deprn_expense_je_line_num IS NOT NULL                       -- �������p�x���ڍהԍ�
             AND      fdd.deprn_expense_ccid        = gcc.code_combination_id         -- �b�b�h�c
             AND      gcc.segment3                  = flv.attribute4                  -- �U�֌�����Ȗ�
             AND      gcc.segment4                  = flv.attribute8                  -- �U�֌��⏕����Ȗ�
             AND      gv_max_period_name            = fdp.period_name                 -- �ŐV��v����
             AND      fab.tag_number                = xvoh.object_code                -- �����R�[�h
             AND      xvoh.machine_type             = flv.lookup_code                 -- ���̋@���Y�J�e�S���Œ�l
             AND      flv.lookup_type               = cv_xxcff1_asset_category_id
             AND      flv.attribute9                IN (cv_attribute9_1 ,cv_attribute9_3)
             AND      flv.language                  = ct_language
             AND      flv.enabled_flag              = cv_flag_y
             AND      LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
                                                                       AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
             UNION ALL
             SELECT
                    /*+ 
                        INDEX(fdp FA_DEPRN_PERIODS_U1)
                        INDEX(flv FND_LOOKUP_VALUES_U2)
                        INDEX(faj FA_ADJUSTMENTS_N4)
                        INDEX(fab FA_ADDITIONS_B_U1)
                        INDEX(xvoh XXCFF_VD_OBJECT_HEADERS_U01)
                        INDEX(gcc GL_CODE_COMBINATIONS_U1)
                     */
                    cv_fixed_assets_lease_kbn lease_kbn           -- ���[�X�敪
                   ,fdp.period_name           period_name         -- ��v���Ԗ�
                   ,xvoh.object_header_id     object_header_id    -- ��������ID
                   ,xvoh.object_code          object_code         -- �����R�[�h
                   ,xvoh.lease_class          lease_class         -- ���[�X���
                   ,xvoh.machine_type         machine_type        -- �@��敪
                   ,NULL                      contract_header_id  -- �_�����ID
                   ,NULL                      contract_number     -- �_��ԍ�
                   ,NULL                      contract_line_id    -- �_�񖾍ד���ID
                   ,NULL                      contract_line_num   -- �_�񖾍הԍ�
                   ,fab.asset_id              asset_id            -- ���YID
                   ,fab.asset_number          asset_number        -- ���Y�ԍ�
                   ,faj.adjustment_amount     deprn_amount        -- �������p�z
             FROM
                   fa_adjustments             faj       -- ���Y�������
                  ,fa_additions_b             fab       -- ���Y�ڍ׏��
                  ,fa_deprn_periods           fdp       -- �������p����
                  ,gl_code_combinations       gcc       -- ����Ȗڑg�����}�X�^
                  ,xxcff_vd_object_headers    xvoh      -- ���̋@����
                  ,fnd_lookup_values          flv       -- ���̋@���Y�J�e�S���Œ�l
             WHERE    fab.asset_id                  = faj.asset_id                    -- ��������ID
             AND      fdp.book_type_code            = gv_fixed_assets_books           -- ���Y�䒠�R�[�h
             AND      fdp.book_type_code            = faj.book_type_code              -- �䒠�䒠�R�[�h
             AND      fdp.period_counter            = faj.period_counter_created      -- ��v����
             AND      faj.adjustment_type           = ct_adj_type_expense             -- �����^�C�v
             AND      gv_max_period_name            = fdp.period_name                 -- �ŐV��v����
             AND      fab.tag_number                = xvoh.object_code                -- �����R�[�h
             AND      faj.code_combination_id      = gcc.code_combination_id          -- �b�b�h�c
             AND      gcc.segment3                  = flv.attribute4                  -- �U�֌�����Ȗ�
             AND      gcc.segment4                  = flv.attribute8                  -- �U�֌��⏕����Ȗ�
             AND      xvoh.machine_type             = flv.lookup_code                --  ���̋@���Y�J�e�S���Œ�l
             AND      flv.lookup_type               = cv_xxcff1_asset_category_id
             AND      flv.attribute9                IN (cv_attribute9_1 ,cv_attribute9_3)
             AND      flv.language                  = ct_language
             AND      flv.enabled_flag              = cv_flag_y
             AND      LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)) BETWEEN NVL(flv.start_date_active, LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
                                                                       AND     NVL(flv.end_date_active  , LAST_DAY(TO_DATE(gv_max_period_name ,cv_yyyymm)))
             ) xod
      GROUP BY xod.lease_kbn
              ,xod.period_name
              ,xod.object_header_id
              ,xod.object_code
              ,xod.lease_class
              ,xod.machine_type
              ,xod.contract_header_id
              ,xod.contract_number
              ,xod.contract_line_id
              ,xod.contract_line_num
              ,xod.asset_id
              ,xod.asset_number
--
      ;
    g_gl_get_object_deprn_rec  gl_get_object_deprn_cur%ROWTYPE;
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
--
    -- �������p�z�f�[�^�̎擾
    OPEN  gl_get_object_deprn_cur;
    FETCH gl_get_object_deprn_cur
    BULK COLLECT INTO
                      g_lease_kbn_tab            -- ���[�X�敪
                     ,g_period_name_tab          -- ��v���Ԗ�
                     ,g_object_header_id_tab     -- ��������ID
                     ,g_object_code_tab          -- �����R�[�h
                     ,g_lease_class_tab          -- ���[�X���
                     ,g_machine_type_tab         -- �@��敪
                     ,g_contract_header_id_tab   -- �_�����ID
                     ,g_contract_number_tab      -- �_��ԍ�
                     ,g_contract_line_id_tab     -- �_�񖾍ד���ID
                     ,g_contract_line_num_tab    -- �_�񖾍הԍ�
                     ,g_asset_id_tab             -- ���YID
                     ,g_asset_number_tab         -- ���Y�ԍ�
                     ,g_deprn_amount_tab         -- �������p�z
                     ;
    --�Ώی����J�E���g
    gn_target_cnt := g_lease_kbn_tab.COUNT;
    CLOSE gl_get_object_deprn_cur;
--
    BEGIN
      -- �擾����������0���̏ꍇ
      IF ( gn_target_cnt = 0 ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_app_name      -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_cso_00399 -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
      -- �擾����������1���ȏ�̏ꍇ
      ELSE
        <<gl_get_object_deprn_loop>>
        FOR ln_loop_cnt IN 1 .. gn_target_cnt LOOP
--
          -- �����ʌ������p�z���e�[�u���֓o�^
          INSERT INTO xxcso_object_deprn(
             depreciation_id             -- �������p�zID
            ,lease_kbn                  -- ���[�X�敪
            ,period_name                -- ��v���Ԗ�
            ,object_header_id           -- ��������ID
            ,object_code                -- �����R�[�h
            ,lease_class                -- ���[�X���
            ,machine_type               -- �@��敪
            ,contract_header_id         -- �_�����ID
            ,contract_number            -- �_��ԍ�
            ,contract_line_id           -- �_�񖾍ד���ID
            ,contract_line_num          -- �_�񖾍הԍ�
            ,asset_id                   -- ���YID
            ,asset_number               -- ���Y�ԍ�
            ,deprn_amount               -- �������p�z
            ,created_by                 -- �쐬��
            ,creation_date              -- �쐬��
            ,last_updated_by            -- �ŏI�X�V��
            ,last_update_date           -- �ŏI�X�V��
            ,last_update_login          -- �ŏI�X�V���O�C��
            ,request_id                 -- �v��ID
            ,program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,program_id                 -- �R���J�����g�E�v���O����ID
            ,program_update_date        -- �v���O�����X�V��
          ) VALUES (
             xxcso_object_deprn_s01.nextval               -- �������p�zID
            ,g_lease_kbn_tab(ln_loop_cnt)                 -- ���[�X�敪��v
            ,g_period_name_tab(ln_loop_cnt)               -- ��v���Ԗ��d��
            ,g_object_header_id_tab(ln_loop_cnt)          -- ��������ID
            ,g_object_code_tab(ln_loop_cnt)               -- �����R�[�h
            ,g_lease_class_tab(ln_loop_cnt)               -- ���[�X���
            ,g_machine_type_tab(ln_loop_cnt)              -- �@��敪
            ,g_contract_header_id_tab(ln_loop_cnt)        -- �_�����ID
            ,g_contract_number_tab(ln_loop_cnt)           -- �_��ԍ�
            ,g_contract_line_id_tab(ln_loop_cnt)          -- �_�񖾍ד���ID
            ,g_contract_line_num_tab(ln_loop_cnt)         -- �_�񖾍הԍ�
            ,g_asset_id_tab(ln_loop_cnt)                  -- ���YID
            ,g_asset_number_tab(ln_loop_cnt)              -- ���Y�ԍ�
            ,g_deprn_amount_tab(ln_loop_cnt)              -- �������p�z
            ,cn_created_by                                -- �쐬��
            ,cd_creation_date                             -- �쐬��
            ,cn_last_updated_by                           -- �ŏI�X�V��
            ,cd_last_update_date                          -- �ŏI�X�V��
            ,cn_last_update_login                         -- �ŏI�X�V���O�C��
            ,cn_request_id                                -- �v��ID
            ,cn_program_application_id                    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����
            ,cn_program_id                                -- �R���J�����g�E�v���O����ID
            ,cd_program_update_date                       -- �v���O�����X�V��
          );
--
        END LOOP gl_get_object_deprn_loop;
--
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
               ,iv_name         => cv_msg_cso_00886        --���b�Z�[�W�R�[�h
               ,iv_token_name1  => cv_tkn_table            --�g�[�N���R�[�h1
               ,iv_token_value1 => cv_table_name           --�g�[�N���l1
               ,iv_token_name2  => cv_tkn_err_msg2         --�g�[�N���R�[�h2
               ,iv_token_value2 => SQLERRM                 --�g�[�N���l2
              );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
--
    END;
--
  EXCEPTION
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
  END insert_object_deprn_data;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : �����ʌ������p�z���CSV�o�� (A-5)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
    ov_errbuf       OUT NOCOPY VARCHAR2,               -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,               -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2                -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'create_csv_rec';       -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--_
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_op_str                                 VARCHAR2(5000)  := NULL; -- �o�͕�����i�[�p�ϐ�
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR gl_get_object_deprn_tbl_cur
    IS
      SELECT xod.depreciation_id           depreciation_id           -- �������p�zID
            ,xod.lease_kbn                 lease_kbn                 -- ���[�X�敪
            ,xod.period_name               period_name               -- ��v���Ԗ�
            ,xod.object_header_id          object_header_id          -- ��������ID
            ,xod.object_code               object_code               -- �����R�[�h
            ,xod.lease_class               lease_class               -- ���[�X���
            ,xod.machine_type              machine_type              -- �@��敪
            ,xod.contract_header_id        contract_header_id        -- �_�����ID
            ,xod.contract_number           contract_number           -- �_��ԍ�
            ,xod.contract_line_id          contract_line_id          -- �_�񖾍ד���ID
            ,xod.contract_line_num         contract_line_num         -- �_�񖾍הԍ�
            ,xod.asset_id                  asset_id                  -- ���YID
            ,xod.asset_number              asset_number              -- ���Y�ԍ�
            ,xod.deprn_amount              deprn_amount              -- �������p�z
            ,xod.created_by                created_by                -- �쐬��
            ,xod.creation_date             creation_date             -- �쐬��
            ,xod.last_updated_by           last_updated_by           -- �ŏI�X�V��
            ,xod.last_update_date          last_update_date          -- �ŏI�X�V��
            ,xod.last_update_login         last_update_login         -- �ŏI�X�V���O�C��
            ,xod.request_id                request_id                -- �v��ID
            ,xod.program_application_id    program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            ,xod.program_id                program_id                -- �R���J�����g�E�v���O����ID
            ,xod.program_update_date       program_update_date       -- �v���O�����X�V��
      FROM   xxcso_object_deprn   xod                                -- �����ʌ������p�z���e�[�u��
      WHERE  xod.period_name = gv_max_period_name                    -- �ŐV��v����
      ORDER BY xod.lease_kbn
              ,xod.lease_class
              ,xod.object_code
      ;
    g_gl_get_object_deprn_tbl_rec  gl_get_object_deprn_tbl_cur%ROWTYPE;
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
    --==============================================================
    --�R���N�V�����폜
    --==============================================================
    delete_collections_tbl(
       lv_errbuf         -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode        -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ================================================
    -- �����ʌ������p�z���e�[�u���̃f�[�^�擾(A-5-1)
    -- ================================================
--
    BEGIN
      OPEN  gl_get_object_deprn_tbl_cur;
      FETCH gl_get_object_deprn_tbl_cur
      BULK COLLECT INTO
                       g_t_depreciation_id_tab           -- �������p�zID
                      ,g_t_lease_kbn_tab                 -- ���[�X�敪
                      ,g_t_period_name_tab               -- ��v���Ԗ�
                      ,g_t_object_header_id_tab          -- ��������ID
                      ,g_t_object_code_tab               -- �����R�[�h
                      ,g_t_lease_class_tab               -- ���[�X���
                      ,g_t_machine_type_tab              -- �@��敪
                      ,g_t_contract_header_id_tab        -- �_�����ID
                      ,g_t_contract_number_tab           -- �_��ԍ�
                      ,g_t_contract_line_id_tab          -- �_�񖾍ד���ID
                      ,g_t_contract_line_num_tab         -- �_�񖾍הԍ�
                      ,g_t_asset_id_tab                  -- ���YID
                      ,g_t_asset_number_tab              -- ���Y�ԍ�
                      ,g_t_deprn_amount_tab              -- �������p�z
                      ,g_t_created_by_tab                -- �쐬��
                      ,g_t_creation_date_tab             -- �쐬��
                      ,g_t_last_updated_by_tab           -- �ŏI�X�V��
                      ,g_t_last_update_date_tab          -- �ŏI�X�V��
                      ,g_t_last_update_login_tab         -- �ŏI�X�V���O�C��
                      ,g_t_request_id_tab                -- �v��ID
                      ,g_t_program_application_id_tab    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
                      ,g_t_program_id_tab                -- �R���J�����g�E�v���O����ID
                      ,g_t_program_update_date_tab       -- �v���O�����X�V��
                      ;
      CLOSE gl_get_object_deprn_tbl_cur;
--
    EXCEPTION
      WHEN OTHERS THEN
      --�����ʌ������p�z���e�[�u�����o�G���[���b�Z�[�W
        lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_app_name               -- �A�v���P�[�V�����Z�k��
                            ,iv_name         => cv_msg_cso_00016          -- ���b�Z�[�W�R�[�h
                            ,iv_token_name1  => cv_tkn_proc_name          -- �g�[�N���R�[�h1
                            ,iv_token_value1 => cv_proc_name              -- �g�[�N���l1
                            ,iv_token_name2  => cv_tkn_err_msg2           -- �g�[�N���R�[�h2
                            ,iv_token_value2 => SQLERRM                   -- �g�[�N���l2
                );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;--
    END;
  -- �擾����������1���ȏ�̏ꍇ
    <<gl_get_object_deprn_tbl_loop>>
    FOR g_gl_get_object_deprn_tbl_rec IN gl_get_object_deprn_tbl_cur
    LOOP
    -- ===============================
    -- CSV�t�@�C���o��(A-5-2)
    -- ===============================
--
      --�o�͕�����쐬
      lv_op_str :=                          cv_dqu || g_gl_get_object_deprn_tbl_rec.depreciation_id         || cv_dqu ;   -- �������p�zID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.lease_kbn               || cv_dqu ;   -- ���[�X�敪
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.period_name             || cv_dqu ;   -- ��v���Ԗ�
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.object_header_id        || cv_dqu ;   -- ��������ID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.object_code             || cv_dqu ;   -- �����R�[�h
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.lease_class             || cv_dqu ;   -- ���[�X���
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.machine_type            || cv_dqu ;   -- �@��敪
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.contract_header_id      || cv_dqu ;   -- �_�����ID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.contract_number         || cv_dqu ;   -- �_��ԍ�
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.contract_line_id        || cv_dqu ;   -- �_�񖾍ד���ID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.contract_line_num       || cv_dqu ;   -- �_�񖾍הԍ�
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.asset_id                || cv_dqu ;   -- ���YID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.asset_number            || cv_dqu ;   -- ���Y�ԍ�
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.deprn_amount            || cv_dqu ;   -- �������p�z
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.created_by              || cv_dqu ;   -- �쐬��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.creation_date           || cv_dqu ;   -- �쐬��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.last_updated_by         || cv_dqu ;   -- �ŏI�X�V��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.last_update_date        || cv_dqu ;   -- �ŏI�X�V��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.last_update_login       || cv_dqu ;   -- �ŏI�X�V���O�C��
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.request_id              || cv_dqu ;   -- �v��ID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.program_application_id  || cv_dqu ;   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.program_id              || cv_dqu ;   -- �R���J�����g�E�v���O����ID
      lv_op_str := lv_op_str || cv_comma || cv_dqu || g_gl_get_object_deprn_tbl_rec.program_update_date     || cv_dqu ;   -- �v���O�����X�V��
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_op_str
      );
      -- ��������
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP gl_get_object_deprn_tbl_loop;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf        OUT NOCOPY VARCHAR2,      -- �G���[�E���b�Z�[�W            --# �Œ� #
     ov_retcode       OUT NOCOPY VARCHAR2,      -- ���^�[���E�R�[�h              --# �Œ� #
     ov_errmsg        OUT NOCOPY VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W    --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';           -- �v���O������
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
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ================================
    -- A-1.��������
    -- ================================
    init(
      ov_errbuf           => lv_errbuf,        -- �G���[�E���b�Z�[�W            --# �Œ� #
      ov_retcode          => lv_retcode,       -- ���^�[���E�R�[�h              --# �Œ� #
      ov_errmsg           => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-2.�v���t�@�C���l�擾
    -- =================================================
    get_profile_info(
       ov_errbuf      => lv_errbuf,      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ov_retcode     => lv_retcode,     -- ���^�[���E�R�[�h              --# �Œ� #
       ov_errmsg      => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-3.�����ʌ������p�z���e�[�u���폜
    -- =================================================
--
    delete_object_deprn_data(
       ov_errbuf    => lv_errbuf,    -- �G���[�E���b�Z�[�W            --# �Œ� #
       ov_retcode   => lv_retcode,   -- ���^�[���E�R�[�h              --# �Œ� #
       ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-4.�����ʌ������p�z���o�^
    -- =================================================
--
    insert_object_deprn_data(
       ov_errbuf    => lv_errbuf,     -- �G���[�E���b�Z�[�W            --# �Œ� #
       ov_retcode   => lv_retcode,    -- ���^�[���E�R�[�h              --# �Œ� #
       ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      RAISE no_data_expt;
    END IF;
--
    -- =================================================
    -- A-5.�����ʌ������p�z���CSV�o��
    -- =================================================
--
    create_csv_rec(
       ov_errbuf    => lv_errbuf,      -- �G���[�E���b�Z�[�W            --# �Œ� #
       ov_retcode   => lv_retcode,    -- ���^�[���E�R�[�h              --# �Œ� #
       ov_errmsg    => lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ���o�ΏۂȂ���O(�x���j�n���h�� ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
    cv_prg_name           CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
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
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF lv_retcode IN (cv_status_error ,cv_status_warn)  THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                   --�G���[���b�Z�[�W
      );
    END IF;
--
    -- =======================
    -- A-8.�I������
    -- =======================
    --��s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --===============================================================
    -- �G���[���̏o�͌����ݒ�
    --===============================================================
    IF (lv_retcode = cv_status_error) THEN
      -- �����������[���ɃN���A����
      gn_normal_cnt      := 0;
      -- �G���[������1��ݒ肷��
      gn_error_cnt       := 1;
    END IF;
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_msg_ccp_90006;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_ccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg3 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg3 || CHR(10) ||
                   ''
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ���[���o�b�N�������Ƃ����O�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg3 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCSO016A08C;
/
