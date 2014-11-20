CREATE OR REPLACE PACKAGE BODY APPS.XXCOS011A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS011A11C (body)
 * Description      : �ʏ��i�̔����тd�c�h�f�[�^�쐬
 * MD.050           : �ʏ��i�̔����тd�c�h�f�[�^�쐬 MD050_COS_011_A11
 * Version          : 1.2
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                 ��������(A-1)
 *  get_busines_date     �ΏۋƖ����t�Z�o����(A-2)
 *  output_header        �t�@�C����������(A-3)
 *  get_sales_exp_data   �̔����я�񒊏o(A-4)
 *  make_sale_data       �t�@�C���f�[�^���^����(A-5�AA-6)
 *  output_footer        �t�@�C���I������(A-7)
 *  update_sale_header   �̔����уw�b�_�e�[�u���t���O�X�V(A-8)
 *  update_sale_cancel   �̔����уw�b�_�e�[�u���t���O�X�V�u�����v(A-9)
 *  submain              ���C�������v���V�[�W��
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/02/25    1.0   Oukou            �V�K�쐬
 *  2011/03/25    1.1   Oukou            [E_�{�ғ�_06945]�ʏ��i�̔����э쐬�̓��e�̑Ή�
 *  2011/04/07    1.2   Oukou            [E_�{�ғ�_07120]���{�f�[�^��ΏۊO�ɂ���Ή�
 *****************************************************************************************/
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- �x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  -- ���t
  cd_sysdate                CONSTANT DATE        := SYSDATE;                            -- �V�X�e�����t
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
  gn_warn_cnt      NUMBER;                    -- �x������
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCOS011A11C';                 -- �p�b�P�[�W��
--
  cv_xxcos_short_name             CONSTANT VARCHAR2(10)  := 'XXCOS';                        -- �A�v���P�[�V������
--
  --�v���t�@�C��
  ct_prf_max_linesize             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_UTL_MAX_LINESIZE';     -- XXCOS:�t�@�C���ɏo�͂���1�s��MAX���T�C�Y
  ct_prf_outbound_dir             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_EDI_OUTBOUND_OM_DIR';  -- XXCOS:EDI�󒍌n�A�E�g�o�E���h�p�f�B���N�g���p�X
  ct_prf_item_file                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SPECIFIC_ITEM_FILE';   -- XXCOS:�ʏ��i�̔����уt�@�C����
  ct_prf_comp_code                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SPECIFIC_COMP_CODE';   -- XXCOS:�ʏ��i�̔����щ�ЃR�[�h
  ct_prf_org_code                 CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SPECIFIC_ORG_CODE';    -- XXCOS:�ʏ��i�̔����ёg�D�R�[�h
  ct_prf_start_date               CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SPECIFIC_START_DATE';  -- XXCOS:�ʏ��i�̔����ёΏۊJ�n���t
  ct_prf_past_day                 CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SPECIFIC_PAST_DAY';    -- XXCOS:�ʏ��i�̔����ёΏۓ���
  cv_prf_org_id                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                      -- MO:�c�ƒP��
/* 2011/03/25 Ver1.1 ADD Start */
  ct_prf_if_header                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_HEADER';            -- XXCCP:IF���R�[�h�敪_�w�b�_
  ct_prf_dept_code                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BIZ_MAN_DEPT_CODE';    -- XXCOS:�Ɩ��Ǘ����R�[�h
  ct_prf_specific_chain_code      CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_SPECIFIC_CHAIN_CODE';  -- XXCOS:�ʏ��i�̔����їp�`�F�[���X�R�[�h
  ct_prf_parallel_process_num     CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_PARALLEL_PROCESS_NUM'; -- XXCOS:�ʏ��i�̔����їp���񏈗��ԍ�
/* 2011/03/25 Ver1.1 ADD End   */
  --
  --���b�Z�[�W
  ct_msg_param_out_err            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14151';  -- �p�����[�^�o�̓��b�Z�[�W
  ct_msg_param_date_err           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14152';  -- �p�����[�^���t�����G���[���b�Z�[�W
  ct_msg_param_mode_err           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14153';  -- �p�����[�^���s�敪�G���[���b�Z�[�W
  ct_msg_outbound_dir             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14154';  -- ���b�Z�[�W�p������.�f�B���N�g���p�X
  ct_msg_item_file                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14155';  -- ���b�Z�[�W�p������.�t�@�C����
  ct_msg_max_linesize             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14156';  -- ���b�Z�[�W�p������.UTL_MAX�s�T�C�Y
  ct_msg_comp_code                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14157';  -- ���b�Z�[�W�p������.��ЃR�[�h
  ct_msg_org_code                 CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14158';  -- ���b�Z�[�W�p������.�g�D�R�[�h
  ct_msg_start_date               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14159';  -- ���b�Z�[�W�p������.�ΏۊJ�n���t
  ct_msg_past_day                 CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14160';  -- ���b�Z�[�W�p������.�Ώۓ���
  ct_msg_file                     CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14161';  -- ���b�Z�[�W�p������.�ʏ��i�̔����уt�@�C��
  ct_msg_mst_chk_warm             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14162';  -- �}�X�^���ږ��ݒ�x�����b�Z�[�W
  ct_msg_data_count               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14163';  -- �����������b�Z�[�W
  ct_msg_non_business_date        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11601';  -- �Ɩ����t�擾�G���[
  ct_msg_notfound_profile         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';  -- �v���t�@�C���擾�G���[
  cv_msg_file_name                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00044';  -- �t�@�C�����o��
  cv_msg_lock_err                 CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';  -- ���b�N�G���[
  cv_msg_file_o_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00009';  -- �t�@�C���I�[�v���G���[
  cv_msg_data_get_err             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00013';  -- �f�[�^���o�G���[
  cv_msg_no_target_err            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';  -- �Ώۃf�[�^�Ȃ��G���[
  cv_msg_sale_exp_head_tab        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12364';  -- �̔����уw�b�_�e�[�u��(����)
  cv_msg_upd_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';  -- �f�[�^�X�V�G���[
  cv_msg_non_business_date        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11601';  -- �Ɩ����t�擾�G���[
  cv_msg_org_id                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00047';  -- MO:�c�ƒP��
/* 2011/03/25 Ver1.1 ADD Start */
  ct_msg_f_h                      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00104';  -- XXCCP:IF���R�[�h�敪_�w�b�_(����)
  ct_msg_dept_c                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12358';  -- XXCOS:�Ɩ��Ǘ����R�[�h(����)
  ct_msg_specific_chain_code      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14164';  -- XXCOS:�ʏ��i�̔����їp�`�F�[���X�R�[�h(����)
  ct_msg_parallel_process_num     CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-14165';  -- XXCOS:�ʏ��i�̔����їp���񏈗��ԍ�(����)
  ct_msg_base_code_err            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00035';  -- ���_���擾�G���[
  ct_msg_chain_inf_err            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00036';  -- �`�F�[���X���擾�G���[
  ct_msg_proc_err                 CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00037';  -- ���ʊ֐��G���[
  ct_msg_table_tkn1               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00046';  -- �N�C�b�N�R�[�h(����)
  ct_msg_data_type_c              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12362';  -- �f�[�^��R�[�h(����)
  ct_msg_mst_chk_err              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10002';  -- �}�X�^�`�F�b�N�G���[
/* 2011/03/25 Ver1.1 ADD End   */
  --
  -- �g�[�N��
  cv_tkn_profile                  CONSTANT VARCHAR2(20)  := 'PROFILE';           -- �v���t�@�C����
  cv_tkn_filename                 CONSTANT VARCHAR2(100) := 'FILE_NAME';         -- �t�@�C����
  cv_tkn_table                    CONSTANT VARCHAR2(20)  := 'TABLE';             -- �e�[�u��
  cv_tkn_table_name               CONSTANT VARCHAR2(20)  := 'TABLE_NAME';        -- �e�[�u����
  cv_tkn_key_data                 CONSTANT VARCHAR2(20)  := 'KEY_DATA';          -- �L�[���
  cv_tkn_customer_code            CONSTANT VARCHAR2(20)  := 'CUSTOMER_CODE';     -- �ڋq�R�[�h
  cv_tkn_delivery_date            CONSTANT VARCHAR2(20)  := 'DELIVERY_DATE';     -- �[�i��
  cv_tkn_item_code                CONSTANT VARCHAR2(20)  := 'ITEM_CODE';         -- �i�ڃR�[�h
  cv_tkn_address                  CONSTANT VARCHAR2(20)  := 'ADDRESS';           -- �n��R�[�h
  cv_tkn_industry_div             CONSTANT VARCHAR2(20)  := 'INDUSTRY_DIV';      -- �Ǝ�
  cv_tkn_prm1                     CONSTANT VARCHAR2(6)   := 'PARAM1';            -- ���̓p�����[�^1
  cv_tkn_prm2                     CONSTANT VARCHAR2(6)   := 'PARAM2';            -- ���̓p�����[�^2
  cv_tkn_count1                   CONSTANT VARCHAR2(20)  := 'COUNT1';            -- ��������1
  cv_tkn_count2                   CONSTANT VARCHAR2(20)  := 'COUNT2';            -- ��������2
  cv_tkn_count3                   CONSTANT VARCHAR2(20)  := 'COUNT3';            -- ��������3
  cv_tkn_count4                   CONSTANT VARCHAR2(20)  := 'COUNT4';            -- ��������4
/* 2011/03/25 Ver1.1 ADD Start */
  cv_tkn_base_code                CONSTANT VARCHAR2(20)  := 'CODE';              -- ���_�R�[�h
  cv_tkn_chain_code               CONSTANT VARCHAR2(20)  := 'CHAIN_SHOP_CODE';   -- �`�F�[���X�R�[�h
  cv_tkn_column                   CONSTANT VARCHAR2(20)  := 'COLMUN';            -- �J������
  cv_tkn_err_msg                  CONSTANT VARCHAR2(20)  := 'ERRMSG';            -- �G���[���b�Z�[�W��
/* 2011/03/25 Ver1.1 ADD End   */
  --
  -- �N�C�b�N�R�[�h�^�C�v
  cv_lt_edi_specific_item         CONSTANT VARCHAR2(30)  := 'XXCOS1_EDI_SPECIFIC_ITEM';      -- �i�ڃR�[�h
  cv_lt_edi_specific_industry     CONSTANT VARCHAR2(30)  := 'XXCOS1_EDI_SPECIFIC_INDUSTRY';  -- �Ǝ�R�[�h
/* 2011/04/07 Ver1.2 ADD Start */
  cv_lt_edi_specific_sale_class   CONSTANT VARCHAR2(30)  := 'XXCOS1_EDI_SPECIFIC_SALE_CLASS';  -- �ʏ��i�̔����є���敪
/* 2011/04/07 Ver1.2 ADD END   */
  --
  -- ���̑�
  cv_lang                         CONSTANT VARCHAR2(5)   := USERENV('LANG');     -- ����
  cv_utl_file_mode                CONSTANT VARCHAR2(1)   := 'w';                 -- UTL_FILE.�I�[�v�����[�h
  cv_date_format_sl               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';        -- ���t�t�H�[�}�b�g(�N�����X���b�V���t��)
  cv_date_format                  CONSTANT VARCHAR2(8)   := 'YYYYMMDD';          -- ���t�t�H�[�}�b�g
  cv_blank                        CONSTANT VARCHAR2(1)   := '';                  -- �󕶎�
  cv_y                            CONSTANT VARCHAR2(1)   := 'Y';                 -- �Œ�l�FY
  cv_n                            CONSTANT VARCHAR2(1)   := 'N';                 -- �Œ�l�FN
  cn_x                            CONSTANT VARCHAR2(1)   := 'X';                 -- �Œ�l�F46(NUMBER)
  cv_0                            CONSTANT VARCHAR2(1)   := '0';                 -- �Œ�l�F0
/* 2011/03/25 Ver1.1 ADD Start */
  cv_1                            CONSTANT VARCHAR2(1)   := '1';                 -- �Œ�l�F1
  -- �ڋq�}�X�^�擾�p�Œ�l
  cv_cust_code_chain              CONSTANT VARCHAR2(2)   := '18';                -- �ڋq�敪(�`�F�[���X)
  cv_status_a                     CONSTANT VARCHAR2(1)   := 'A';                 -- �X�e�[�^�X
  cv_data_type                    CONSTANT VARCHAR2(50)  := 'XXCOS1_DATA_TYPE_CODE';    -- �f�[�^��
  cv_data_type_code               CONSTANT VARCHAR2(3)   := '180';                      -- �̔�����
/* 2011/03/25 Ver1.1 ADD End   */ 
  cv_run_class_cd_create          CONSTANT VARCHAR2(1)   := '1';                 -- ���s�敪�F�u�쐬�v
  cv_run_class_cd_cancel          CONSTANT VARCHAR2(1)   := '2';                 -- ���s�敪�F�u�����v
  cv_run_class_cd_resend          CONSTANT VARCHAR2(1)   := '3';                 -- ���s�敪�F�u�đ��M�v
  cv_cust_status                  CONSTANT VARCHAR2(1)   := 'A';                 -- �ڋq���ݒn�X�e�[�^�X�uA�v
  cv_industry_div                 CONSTANT VARCHAR2(2)   := '00';                -- �Ǝ�F�u00�v
  cn_0                            CONSTANT NUMBER        := 0;                   -- �Œ�l�F0(NUMBER)
  cn_1                            CONSTANT NUMBER        := 1;                   -- �Œ�l�F1(NUMBER)
  cn_46                           CONSTANT NUMBER        := 46;                  -- �Œ�l�F46(NUMBER)
--
  -- ===================================
  -- ���[�U�[��`�O���[�o��RECORD�^�錾
  -- ===================================
  -- �̔����я��
  TYPE g_sales_data_rtype IS RECORD(
     orig_delivery_date          xxcos_sales_exp_headers.orig_delivery_date%TYPE
    ,ship_to_customer_code       xxcos_sales_exp_headers.ship_to_customer_code%TYPE
    ,item_code                   xxcos_sales_exp_lines.item_code%TYPE
    ,standard_qty                xxcos_sales_exp_lines.standard_qty%TYPE
    ,address3                    hz_locations.address3%TYPE
    ,industry_div_flg            xxcmm_cust_accounts.industry_div%TYPE
    ,industry_div                xxcmm_cust_accounts.industry_div%TYPE
    ,item_name                   fnd_lookup_values.meaning%TYPE
    );
  -- �̔����я��i�X�V�j
  TYPE g_sales_update_rtype IS RECORD(
     orig_delivery_date          xxcos_sales_exp_headers.orig_delivery_date%TYPE
    ,ship_to_customer_code       xxcos_sales_exp_headers.ship_to_customer_code%TYPE
    );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o��TABLE�^
  -- ===============================
  -- �̔����я��
  TYPE g_sales_data_ttype    IS TABLE OF g_sales_data_rtype INDEX BY BINARY_INTEGER;
  -- �̔����уw�b�_�X�V
  TYPE g_sales_update_ttype  IS TABLE OF g_sales_update_rtype INDEX BY BINARY_INTEGER;
  TYPE g_header_id_ttype     IS TABLE OF xxcos_sales_exp_headers.sales_exp_header_id%TYPE INDEX BY BINARY_INTEGER;
  TYPE g_cust_code_ttype     IS TABLE OF xxcos_sales_exp_headers.ship_to_customer_code%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_business_date                DATE;                                                     -- �Ɩ����t
  gd_business_date_start          DATE;                                                     -- �ΏۊJ�n�Ɩ����t
  gd_business_date_end            DATE;                                                     -- �ΏۏI���Ɩ����t
  gf_file_handle                  UTL_FILE.FILE_TYPE;                                       -- �t�@�C���n���h��
  gt_max_linesize                 fnd_profile_option_values.profile_option_value%TYPE;      -- MAX���R�[�h�T�C�Y
  gt_org_id                       fnd_profile_option_values.profile_option_value%TYPE;      -- �c�ƒP��
  gt_outbound_dir                 fnd_profile_option_values.profile_option_value%TYPE;      -- �o�͐�f�B���N�g��
  gt_item_file                    fnd_profile_option_values.profile_option_value%TYPE;      -- �o�̓t�@�C����
  gt_org_code                     fnd_profile_option_values.profile_option_value%TYPE;      -- �g�D�R�[�h
  gt_comp_code                    fnd_profile_option_values.profile_option_value%TYPE;      -- ��ЃR�[�h
  gt_start_date                   fnd_profile_option_values.profile_option_value%TYPE;      -- �ʏ��i�̔����ёΏۊJ�n���t
  gt_past_day                     fnd_profile_option_values.profile_option_value%TYPE;      -- �ʏ��i�̔����ёΏۓ���
  gt_sale_data_tbl                g_sales_data_ttype;                                       -- �̔����ђ��o�f�[�^�i�[
  gt_sale_update_tbl              g_sales_update_ttype;                                     -- �̔����эX�V�f�[�^�i�[
  gt_sale_update_rec              g_sales_update_rtype;                                     -- �̔����эX�V�f�[�^�i�[
  gt_update_header_id             g_header_id_ttype;                                        -- �̔����эX�V�f�[�^�i�[�i�w�b�_ID�j
  gt_update_cust_code             g_cust_code_ttype;                                        -- �̔����эX�V�f�[�^�i�[�i�ڋq�R�[�h�j
/* 2011/03/25 Ver1.1 ADD Start */
  gt_if_header                    fnd_profile_option_values.profile_option_value%TYPE;      -- IF���R�[�h�敪_�w�b�_
  gt_dept_code                    fnd_profile_option_values.profile_option_value%TYPE;      -- �Ɩ��Ǘ����R�[�h
  gt_specific_chain_code          fnd_profile_option_values.profile_option_value%TYPE;      -- �ʏ��i�̔����їp�`�F�[���X�R�[�h
  gt_parallel_process_num         fnd_profile_option_values.profile_option_value%TYPE;      -- �ʏ��i�̔����їp���񏈗��ԍ�
  gt_sales_base_name              hz_parties.party_name%TYPE;                               -- ���_��
  gt_chain_name                   hz_parties.party_name%TYPE;                               -- �`�F�[���X��
  gt_data_type_code               xxcos_lookup_values_v.lookup_code%TYPE;                   -- �f�[�^��R�[�h
  gt_from_series                  xxcos_lookup_values_v.attribute1%TYPE;                    -- IF���Ɩ��n��R�[�h
/* 2011/03/25 Ver1.1 ADD End   */
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  -- ���R�[�h���b�N�G���[
  record_lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( record_lock_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_act_mode   IN  VARCHAR2     -- ���s�敪�F�u1:�쐬�v�u2:�����v�u3:�đ��M�v
   ,iv_date       IN  VARCHAR2     -- ���M��
   ,ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_profile_name   VARCHAR2(100) DEFAULT NULL;  -- �v���t�@�C����
/* 2011/03/25 Ver1.1 ADD Start */
    lv_tkn_name1      VARCHAR2(50)  DEFAULT NULL;  -- �g�[�N���擾�p1
    lv_tkn_name2      VARCHAR2(50)  DEFAULT NULL;  -- �g�[�N���擾�p2
/* 2011/03/25 Ver1.1 ADD End   */
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
    -- ===============================
    -- �R���J�����g�v���O�������͍��ڂ̏o��
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(cv_xxcos_short_name
         ,ct_msg_param_out_err
         ,cv_tkn_prm1
         ,iv_act_mode        -- ���s�敪
         ,cv_tkn_prm2
         ,iv_date            -- ���M��
         );
    --
    -- ===============================
    --  �R���J�����g�E���b�Z�[�W�o��
    -- ===============================
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    --
    -- ===============================
    --  �Ɩ����t�擾
    -- ===============================
    gd_business_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_business_date IS NULL ) THEN
      -- �Ɩ����t���擾�ł��Ȃ��ꍇ
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => cv_msg_non_business_date    -- ���b�Z�[�W
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    --  �c�ƒP��
    -- ===============================
    gt_org_id := FND_PROFILE.VALUE(
      name => cv_prf_org_id);
    --
    IF ( gt_org_id IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(�c�ƒP��)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
        ,iv_name        => cv_msg_org_id                -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => ct_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ===============================
    --  �o�͐�f�B���N�g���擾
    -- ===============================
    gt_outbound_dir := FND_PROFILE.VALUE(
      name => ct_prf_outbound_dir);
    --
    IF ( gt_outbound_dir IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(�o�͐�f�B���N�g��)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
        ,iv_name        => ct_msg_outbound_dir          -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => ct_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    --  �o�̓t�@�C�����擾
    -- ===============================
    gt_item_file := FND_PROFILE.VALUE(
      name => ct_prf_item_file);
    --
    IF ( gt_item_file IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(�o�̓t�@�C����)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
        ,iv_name        => ct_msg_item_file             -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => ct_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    --  MAX���R�[�h�T�C�Y�擾
    -- ===============================
    gt_max_linesize := FND_PROFILE.VALUE(
      name => ct_prf_max_linesize);
    --
    IF ( gt_max_linesize IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(MAX���R�[�h�T�C�Y)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
        ,iv_name        => ct_msg_max_linesize          -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => ct_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    --  ��ЃR�[�h�擾
    -- ===============================
    gt_comp_code := FND_PROFILE.VALUE(
      name => ct_prf_comp_code);
    --
    IF ( gt_comp_code IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(��ЃR�[�h)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
        ,iv_name        => ct_msg_comp_code             -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => ct_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    --  �g�D�R�[�h�擾
    -- ===============================
    gt_org_code := FND_PROFILE.VALUE(
      name => ct_prf_org_code);
    --
    IF ( gt_org_code IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(�g�D�R�[�h)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
        ,iv_name        => ct_msg_org_code              -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => ct_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    --  �ʏ��i�̔����ёΏۊJ�n���t�擾
    -- ===============================
    gt_start_date := FND_PROFILE.VALUE(
      name => ct_prf_start_date);
    --
    IF ( gt_start_date IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(�ʏ��i�̔����ёΏۊJ�n���t)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
        ,iv_name        => ct_msg_start_date            -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => ct_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    --  �ʏ��i�̔����ёΏۓ����擾
    -- ===============================
    gt_past_day := FND_PROFILE.VALUE(
      name => ct_prf_past_day);
    --
    IF ( gt_past_day IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(��ЃR�[�h)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
        ,iv_name        => ct_msg_past_day              -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => ct_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
/* 2011/03/25 Ver1.1 ADD Start */
    -- ===============================
    --  IF���R�[�h�敪_�w�b�_�擾
    -- ===============================
    gt_if_header := FND_PROFILE.VALUE(
      name => ct_prf_if_header);
    --
    IF ( gt_if_header IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(IF���R�[�h�敪_�w�b�_)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
        ,iv_name        => ct_msg_f_h                   -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => ct_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- �Ɩ��Ǘ����R�[�h�擾
    -- ===============================
    gt_dept_code := FND_PROFILE.VALUE(
      name => ct_prf_dept_code);
    --
    IF ( gt_dept_code IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(�Ɩ��Ǘ����R�[�h)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
        ,iv_name        => ct_msg_dept_c                -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => ct_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- �ʏ��i�̔����їp�`�F�[���X�R�[�h
    -- ===============================
    gt_specific_chain_code := FND_PROFILE.VALUE(
      name => ct_prf_specific_chain_code);
    --
    IF ( gt_specific_chain_code IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(�ʏ��i�̔����їp�`�F�[���X�R�[�h)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
        ,iv_name        => ct_msg_specific_chain_code   -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => ct_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- �ʏ��i�̔����їp���񏈗��ԍ�
    -- ===============================
    gt_parallel_process_num := FND_PROFILE.VALUE(
      name => ct_prf_parallel_process_num);
    --
    IF ( gt_parallel_process_num IS NULL ) THEN
      -- �v���t�@�C�����擾�ł��Ȃ��ꍇ
      -- �v���t�@�C�����擾(�ʏ��i�̔����їp���񏈗��ԍ�)
      lv_profile_name := xxccp_common_pkg.get_msg(
         iv_application => cv_xxcos_short_name          -- �A�v���P�[�V�����Z�k��
        ,iv_name        => ct_msg_parallel_process_num  -- ���b�Z�[�WID
      );
      -- ���b�Z�[�W�쐬
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name         -- �A�v���P�[�V�����Z�k��
        ,iv_name         => ct_msg_notfound_profile     -- ���b�Z�[�W
        ,iv_token_name1  => cv_tkn_profile              -- �g�[�N��1��
        ,iv_token_value1 => lv_profile_name);           -- �g�[�N��1�l
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- ���_���擾
    -- ===============================
    BEGIN
      SELECT  hp.party_name       sales_base_name      -- ���_��
      INTO    gt_sales_base_name
      FROM    hz_cust_accounts    hca                  -- ���_(�ڋq)
             ,hz_parties          hp                   -- ���_(�p�[�e�B)
      WHERE   hca.party_id             = hp.party_id   -- ����(���_(�ڋq) = ���_(�p�[�e�B))
      AND     hca.account_number       = gt_dept_code  -- �Ɩ��Ǘ����R�[�h
      AND     hca.customer_class_code  = cv_1          -- �ڋq�敪=1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name      -- �A�v���P�[�V����
          ,iv_name         => ct_msg_base_code_err     -- ���_���擾�G���[
          ,iv_token_name1  => cv_tkn_base_code         -- �g�[�N���R�[�h1
          ,iv_token_value1 => gt_dept_code);           -- �Ɩ��Ǘ����R�[�h
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- ===============================
    -- �`�F�[���X���擾
    -- ===============================
    BEGIN
      SELECT  hp.party_name                chain_name              -- �`�F�[���X��
      INTO    gt_chain_name
      FROM    hz_cust_accounts             hca                     -- �ڋq�}�X�^
             ,xxcmm_cust_accounts          xca                     -- �ڋq�A�h�I���}�X�^
             ,hz_parties                   hp                      -- �p�[�e�B�}�X�^
      WHERE   hca.cust_account_id       =  xca.customer_id         -- ����(�ڋq = �ڋq�A�h�I��)
      AND     hca.party_id              =  hp.party_id             -- ����(�ڋq = �p�[�e�B)
      AND     xca.edi_chain_code        =  gt_specific_chain_code  -- �`�F�[���X�R�[�h
      AND     hca.customer_class_code   =  cv_cust_code_chain      -- �ڋq�敪(�`�F�[���X)
      AND     hca.status                =  cv_status_a             -- �X�e�[�^�X(�L��)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
           iv_application  => cv_xxcos_short_name        -- �A�v���P�[�V����
          ,iv_name         => ct_msg_chain_inf_err       -- �`�F�[���X���擾�G���[
          ,iv_token_name1  => cv_tkn_chain_code          -- �g�[�N���R�[�h1
          ,iv_token_value1 => gt_specific_chain_code);   -- �`�F�[���X�R�[�h
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- ===============================
    -- �f�[�^����擾
    -- ===============================
    BEGIN
      SELECT  xlvv.meaning     meaning                       -- �f�[�^��
             ,xlvv.attribute1  attribute1                    -- IF���Ɩ��n��R�[�h
      INTO    gt_data_type_code
             ,gt_from_series
      FROM    xxcos_lookup_values_v xlvv
      WHERE   xlvv.lookup_type  = cv_data_type               -- �f�[�^��
      AND     xlvv.lookup_code  = cv_data_type_code          -- �u180�v
      AND     (
                ( xlvv.start_date_active IS NULL )
                OR
                ( xlvv.start_date_active <= gd_business_date )
              )
      AND     (
                ( xlvv.end_date_active   IS NULL )
                OR
                ( xlvv.end_date_active >= gd_business_date )
              )  -- �Ɩ����t��FROM-TO��
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                           iv_application =>  cv_xxcos_short_name
                          ,iv_name        =>  ct_msg_data_type_c    --�u�f�[�^��R�[�h�v
                        );
        lv_tkn_name2 := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_short_name
                          ,iv_name         => ct_msg_table_tkn1     --�u�N�C�b�N�R�[�h�v
                        );
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_xxcos_short_name     -- �A�v���P�[�V����
                        ,iv_name         => ct_msg_mst_chk_err      -- �}�X�^�`�F�b�N�G���[
                        ,iv_token_name1  => cv_tkn_column           -- �g�[�N���R�[�h�P
                        ,iv_token_value1 => lv_tkn_name1            -- �f�[�^��R�[�h
                        ,iv_token_name2  => cv_tkn_table            -- �g�[�N���R�[�h�Q
                        ,iv_token_value2 => lv_tkn_name2            -- �N�C�b�N�R�[�h�e�[�u��
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
/* 2011/03/25 Ver1.1 ADD End   */
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
   * Procedure Name   : get_busines_date
   * Description      : �ΏۋƖ����t�Z�o����(A-2)
   ***********************************************************************************/
  PROCEDURE get_busines_date(
    iv_act_mode      IN  VARCHAR2,     -- ���s�敪�F�u1:�쐬�v�u2:�����v�u3:�đ��M�v
    iv_date          IN  VARCHAR2,     -- ���M��
    ov_errbuf        OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_busines_date'; -- �v���O������
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
    IF ( iv_act_mode = cv_run_class_cd_create ) THEN
      -- �p�����[�^.���s�敪���u1:�쐬�v�̏ꍇ
      IF ( iv_date IS NULL ) THEN
        -- �p�����[�^.���M����NULL�̏ꍇ
        gd_business_date_start := gd_business_date - TO_NUMBER(gt_past_day);
        gd_business_date_end   := gd_business_date;
      ELSE
        -- �p�����[�^.���M����NULL�ȊO�̏ꍇ
        gd_business_date_start := gd_business_date - TO_NUMBER(gt_past_day);
        gd_business_date_end   := TO_DATE(iv_date, cv_date_format_sl);      
      END IF;
    ELSIF ( iv_act_mode = cv_run_class_cd_cancel ) THEN
      -- �p�����[�^.���s�敪���u2:�����v�̏ꍇ
      gd_business_date_start := gd_business_date - TO_NUMBER(gt_past_day);
      gd_business_date_end   := TO_DATE(iv_date, cv_date_format_sl);        
    ELSE
      -- �p�����[�^.���s�敪���u3:�đ��M�v�̏ꍇ
      gd_business_date_start := gd_business_date - TO_NUMBER(gt_past_day);
      gd_business_date_end   := TO_DATE(iv_date, cv_date_format_sl);          
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
  END get_busines_date;
--
  /**********************************************************************************
   * Procedure Name   : output_header
   * Description      : �t�@�C����������(A-3)
   ***********************************************************************************/
  PROCEDURE output_header(
    ov_errbuf     OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_header';           -- �v���O������
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
    lv_header_output  VARCHAR2(5000) DEFAULT NULL;        --IF�w�b�_�[�o�͗p
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
        -- �o�̓t�@�C�����̏o��
    -- ===============================
    gv_out_msg := xxccp_common_pkg.get_msg(
          cv_xxcos_short_name
         ,cv_msg_file_name
         ,cv_tkn_filename
         ,gt_item_file
         );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
--
    -- ===============================
    -- �t�@�C���I�[�v��
    -- ===============================
    BEGIN
      gf_file_handle := UTL_FILE.FOPEN(
                          gt_outbound_dir
                         ,gt_item_file
                         ,cv_utl_file_mode
                         ,gt_max_linesize
                        );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_xxcos_short_name
                      ,cv_msg_file_o_err
                      ,cv_tkn_filename
                      ,gt_item_file
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
    --
/* 2011/03/25 Ver1.1 ADD Start */
    -- ===============================
    -- ���ʊ֐��Ăяo��
    -- ===============================
    --EDI�w�b�_�E�t�b�^�t�^
    xxccp_ifcommon_pkg.add_edi_header_footer(
      iv_add_area        =>  gt_if_header             --�t�^�敪
     ,iv_from_series     =>  gt_from_series           --IF���Ɩ��n��R�[�h
     ,iv_base_code       =>  gt_dept_code             --���_�R�[�h(�Ɩ��������R�[�h)
     ,iv_base_name       =>  gt_sales_base_name       --���_����
     ,iv_chain_code      =>  gt_specific_chain_code   --�`�F�[���X�R�[�h
     ,iv_chain_name      =>  gt_chain_name            --�`�F�[���X����
     ,iv_data_kind       =>  gt_data_type_code        --�f�[�^��R�[�h
     ,iv_row_number      =>  gt_parallel_process_num  --���񏈗��ԍ�
     ,in_num_of_records  =>  NULL                     --���R�[�h����
     ,ov_retcode         =>  lv_retcode
     ,ov_output          =>  lv_header_output
     ,ov_errbuf          =>  lv_errbuf
     ,ov_errmsg          =>  lv_errmsg
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
         iv_application  => cv_xxcos_short_name   --�A�v���P�[�V����
        ,iv_name         => ct_msg_proc_err       --���ʊ֐��G���[
        ,iv_token_name1  => cv_tkn_err_msg        --�g�[�N���R�[�h�P
        ,iv_token_value1 => lv_errmsg);           --���ʊ֐��̃G���[���b�Z�[�W
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- ===============================
    -- ���ʊ֐��Ăяo��
    -- ===============================
    UTL_FILE.PUT_LINE(
      file   => gf_file_handle    --�t�@�C���n���h��
     ,buffer => lv_header_output  --�o�͕���(�f�[�^)
    );
/* 2011/03/25 Ver1.1 ADD End   */
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
  END output_header;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp_data
   * Description      : �̔����я�񒊏o(A-4)
   ***********************************************************************************/
  PROCEDURE get_sales_exp_data(
    iv_act_mode      IN  VARCHAR2,     -- ���s�敪�F�u1:�쐬�v�u2:�����v�u3:�đ��M�v
    iv_date          IN  VARCHAR2,     -- ���M��
    ov_errbuf        OUT VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_exp_data'; -- �v���O������
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
    lv_table_name       VARCHAR2(50);    -- �e�[�u����
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �̔����я��(�쐬)
    CURSOR sale_data_create_cur
    IS
      SELECT /*+ LEADING(xseh)
             INDEX(xseh xxcos_sales_exp_headers_n06)
             USE_NL(xseh xsel flv)
             USE_NL(xseh hca)
             USE_NL(hca xca hcas hps hpa hlo flv1) */
             xseh.orig_delivery_date            orig_delivery_date         -- �[�i��
            ,xseh.ship_to_customer_code         ship_to_customer_code      -- �ڋq�R�[�h
            ,xsel.item_code                     item_code                  -- �i�ڃR�[�h
            ,NVL(xsel.standard_qty, cn_0)       standard_qty               -- ����
            ,hlo.address3                       address3                   -- �n��R�[�h
            ,DECODE(xca.industry_div, NULL, xca.industry_div,
                    NVL(flv1.description1, cv_industry_div))
                                                industry_div_flg           -- �Ǝ펯�ʃt���O
            ,xca.industry_div                   industry_div               -- �Ǝ�
            ,SUBSTRB(flv.meaning, cn_1, cn_46)  item_name                  -- �i��
      FROM   hz_cust_accounts                   hca                        -- �ڋq�}�X�^
            ,hz_cust_acct_sites_all             hcas                       -- �ڋq�T�C�g�}�X�^
            ,hz_parties                         hpa                        -- �p�[�e�B�}�X�^
            ,hz_party_sites                     hps                        -- �p�[�e�B�T�C�g�}�X�^
            ,hz_locations                       hlo                        -- �ڋq���Ə��}�X�^
            ,xxcmm_cust_accounts                xca                        -- �ڋq�A�h�I��
            ,fnd_lookup_values                  flv                        -- LookUp�Q�ƃe�[�u��
            ,xxcos_sales_exp_headers            xseh                       -- �̔����уw�b�_
            ,xxcos_sales_exp_lines              xsel                       -- �̔����і���
            ,(
              SELECT flv2.lookup_code  lookup_code1
                    ,flv2.meaning      meaning1
                    ,flv2.description  description1
              FROM   fnd_lookup_values flv2
              WHERE  flv2.lookup_type     = cv_lt_edi_specific_industry
                AND  flv2.language        = cv_lang
                AND  flv2.enabled_flag    = cv_y
                AND  gd_business_date    >= NVL(flv2.start_date_active, gd_business_date)
                AND  gd_business_date    <= NVL(flv2.end_date_active, gd_business_date)
             )  flv1
/* 2011/04/07 Ver1.2 ADD Start */
            ,(
              SELECT flv4.lookup_code  lookup_code      -- ����敪
              FROM   fnd_lookup_values flv4
              WHERE  flv4.lookup_type     = cv_lt_edi_specific_sale_class
                AND  flv4.language        = cv_lang
                AND  flv4.enabled_flag    = cv_y
                AND  gd_business_date    >= NVL(flv4.start_date_active, gd_business_date)
                AND  gd_business_date    <= NVL(flv4.end_date_active, gd_business_date)
             )  flv3
/* 2011/04/07 Ver1.2 ADD END   */
      WHERE xseh.sales_exp_header_id       = xsel.sales_exp_header_id
        AND xseh.item_sales_send_flag      IS NULL
        AND xseh.business_date             >= gd_business_date_start
        AND xseh.business_date             <= gd_business_date_end
        AND xseh.orig_delivery_date        >= TO_DATE(gt_start_date, cv_date_format_sl)
        AND flv.lookup_type                = cv_lt_edi_specific_item
        AND flv.language                   = cv_lang
        AND flv.enabled_flag               = cv_y
        AND gd_business_date               >= NVL(flv.start_date_active, gd_business_date)
        AND gd_business_date               <= NVL(flv.end_date_active, gd_business_date)
        AND xsel.item_code                 = flv.lookup_code
        AND hca.account_number             = xseh.ship_to_customer_code
        AND hca.cust_account_id            = xca.customer_id
        AND hca.party_id                   = hpa.party_id
        AND hpa.party_id                   = hps.party_id
        AND hca.cust_account_id            = hcas.cust_account_id
        AND hcas.party_site_id             = hps.party_site_id
        AND hcas.org_id                    = gt_org_id
        AND hcas.status                    = cv_cust_status
        AND hps.location_id                = hlo.location_id
        AND xca.industry_div               = flv1.lookup_code1(+)
/* 2011/04/07 Ver1.2 ADD Start */
        AND xsel.sales_class                = flv3.lookup_code
/* 2011/04/07 Ver1.2 ADD END   */
      ORDER BY xseh.orig_delivery_date
               ,hlo.address3
               ,DECODE(xca.industry_div, NULL, xca.industry_div,
                       NVL(flv1.description1, cv_industry_div))
               ,xsel.item_code
               ,xseh.ship_to_customer_code
      FOR UPDATE OF xseh.sales_exp_header_id NOWAIT
      ;
    --
    -- �̔����я��(�đ��M)
    CURSOR sale_data_resend_cur(id_date  IN  DATE)
    IS
      SELECT /*+ LEADING(xseh)
             INDEX(xseh xxcos_sales_exp_headers_n06)
             USE_NL(xseh xsel flv)
             USE_NL(xseh hca)
             USE_NL(hca xca hcas hps hpa hlo flv1) */
             xseh.orig_delivery_date            orig_delivery_date         -- �[�i��
            ,xseh.ship_to_customer_code         ship_to_customer_code      -- �ڋq�R�[�h
            ,xsel.item_code                     item_code                  -- �i�ڃR�[�h
            ,NVL(xsel.standard_qty, cn_0)       standard_qty               -- ����
            ,hlo.address3                       address3                   -- �n��R�[�h
            ,DECODE(xca.industry_div, NULL, xca.industry_div,
                    NVL(flv1.description1, cv_industry_div))
                                                industry_div_flg           -- �Ǝ펯�ʃt���O
            ,xca.industry_div                   industry_div               -- �Ǝ�
            ,SUBSTRB(flv.meaning, cn_1, cn_46)  item_name                  -- �i��
      FROM   hz_cust_accounts                   hca                        -- �ڋq�}�X�^
            ,hz_cust_acct_sites_all             hcas                       -- �ڋq�T�C�g�}�X�^
            ,hz_parties                         hpa                        -- �p�[�e�B�}�X�^
            ,hz_party_sites                     hps                        -- �p�[�e�B�T�C�g�}�X�^
            ,hz_locations                       hlo                        -- �ڋq���Ə��}�X�^
            ,xxcmm_cust_accounts                xca                        -- �ڋq�A�h�I��
            ,fnd_lookup_values                  flv                        -- LookUp�Q�ƃe�[�u��
            ,xxcos_sales_exp_headers            xseh                       -- �̔����уw�b�_
            ,xxcos_sales_exp_lines              xsel                       -- �̔����і���
            ,(
              SELECT flv2.lookup_code  lookup_code1
                    ,flv2.meaning      meaning1
                    ,flv2.description  description1
              FROM   fnd_lookup_values flv2
              WHERE  flv2.lookup_type     = cv_lt_edi_specific_industry
                AND  flv2.language        = cv_lang
                AND  flv2.enabled_flag    = cv_y
                AND  gd_business_date    >= NVL(flv2.start_date_active, gd_business_date)
                AND  gd_business_date    <= NVL(flv2.end_date_active, gd_business_date)
             )  flv1
/* 2011/04/07 Ver1.2 ADD Start */
            ,(
              SELECT flv4.lookup_code  lookup_code
              FROM   fnd_lookup_values flv4
              WHERE  flv4.lookup_type     = cv_lt_edi_specific_sale_class
                AND  flv4.language        = cv_lang
                AND  flv4.enabled_flag    = cv_y
                AND  gd_business_date    >= NVL(flv4.start_date_active, gd_business_date)
                AND  gd_business_date    <= NVL(flv4.end_date_active, gd_business_date)
             )  flv3
/* 2011/04/07 Ver1.2 ADD END   */
      WHERE xseh.sales_exp_header_id       = xsel.sales_exp_header_id
        AND xseh.item_sales_send_flag      IS NULL
        AND xseh.business_date             >= gd_business_date_start
        AND xseh.business_date             <= gd_business_date_end
        AND xseh.orig_delivery_date        >= TO_DATE(gt_start_date, cv_date_format_sl)
        AND flv.lookup_type                = cv_lt_edi_specific_item
        AND flv.language                   = cv_lang
        AND flv.enabled_flag               = cv_y
        AND gd_business_date               >= NVL(flv.start_date_active, gd_business_date)
        AND gd_business_date               <= NVL(flv.end_date_active, gd_business_date)
        AND xsel.item_code                 = flv.lookup_code
        AND hca.account_number             = xseh.ship_to_customer_code
        AND hca.cust_account_id            = xca.customer_id
        AND hca.party_id                   = hpa.party_id
        AND hpa.party_id                   = hps.party_id
        AND hca.cust_account_id            = hcas.cust_account_id
        AND hcas.party_site_id             = hps.party_site_id
        AND hcas.org_id                    = gt_org_id
        AND hcas.status                    = cv_cust_status
        AND hps.location_id                = hlo.location_id
        AND xca.industry_div               = flv1.lookup_code1(+)
        AND xseh.item_sales_send_date      = id_date
/* 2011/04/07 Ver1.2 ADD Start */
        AND xsel.sales_class                = flv3.lookup_code
/* 2011/04/07 Ver1.2 ADD END   */
      ORDER BY xseh.orig_delivery_date
               ,hlo.address3
               ,DECODE(xca.industry_div, NULL, xca.industry_div,
                       NVL(flv1.description1, cv_industry_div))
               ,xsel.item_code
               ,xseh.ship_to_customer_code
      FOR UPDATE OF xseh.sales_exp_header_id NOWAIT
      ;
  --
      -- *** ���[�J���E���R�[�h ***
  --
      -- *** ���[�J����O ***
      sale_data_expt              EXCEPTION;   -- �f�[�^���o�G���[
      lock_expt                   EXCEPTION;   -- ���b�N�G���[
  --
    BEGIN
  --
  --##################  �Œ�X�e�[�^�X�������� START   ###################
  --
      ov_retcode := cv_status_normal;
  --
  --###########################  �Œ蕔 END   ############################
  --
      BEGIN
        IF ( iv_act_mode = cv_run_class_cd_create ) THEN
          -- �p�����[�^.���s�敪���u1:�쐬�v�̏ꍇ
          -- �J�[�\���I�[�v��
          OPEN sale_data_create_cur;
          --
          -- ���R�[�h�Ǎ���
          FETCH sale_data_create_cur BULK COLLECT INTO gt_sale_data_tbl;
          --
          -- ���o�����ݒ�
          gn_target_cnt := gt_sale_data_tbl.COUNT;
          --
          -- �J�[�\���E�N���[�Y
          CLOSE sale_data_create_cur;
        ELSIF ( iv_act_mode = cv_run_class_cd_resend ) THEN
          -- �p�����[�^.���s�敪���u3:�đ��M�v�̏ꍇ
          -- �J�[�\���I�[�v��
          OPEN sale_data_resend_cur(TO_DATE(iv_date, cv_date_format_sl));
          --
          -- ���R�[�h�Ǎ���
          FETCH sale_data_resend_cur BULK COLLECT INTO gt_sale_data_tbl;
          --
          -- ���o�����ݒ�
          gn_target_cnt := gt_sale_data_tbl.COUNT;
          --
          -- �J�[�\���E�N���[�Y
          CLOSE sale_data_resend_cur;
        END IF;
      EXCEPTION
        -- ���b�N�G���[
        WHEN record_lock_expt THEN
          RAISE lock_expt;
        WHEN OTHERS THEN
          -- ���o�Ɏ��s�����ꍇ
          lv_errbuf := SQLERRM;
          RAISE sale_data_expt;
      END;
      --
      -- ���o�����`�F�b�N
      IF ( gn_target_cnt = cn_0 ) THEN
        -- ���o�f�[�^�������ꍇ
        IF ( sale_data_create_cur%ISOPEN ) THEN
          CLOSE sale_data_create_cur;
        END IF;
        IF ( sale_data_resend_cur%ISOPEN ) THEN
          CLOSE sale_data_create_cur;
        END IF;
        -- ���b�Z�[�W�쐬
        gv_out_msg := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_no_target_err
        );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
        );
      END IF;
  --
    EXCEPTION
  --
      WHEN lock_expt THEN
        --*** ���b�N�G���[ ***
        IF ( sale_data_create_cur%ISOPEN ) THEN
          CLOSE sale_data_create_cur;
        END IF;
        IF ( sale_data_resend_cur%ISOPEN ) THEN
          CLOSE sale_data_create_cur;
        END IF;
        -- ���b�Z�[�W������擾
        lv_table_name := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_sale_exp_head_tab
        );
        -- ���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_lock_err
         ,iv_token_name1  => cv_tkn_table
         ,iv_token_value1 => lv_table_name
        );
        --
        ov_errmsg  := lv_errmsg;                                                  --# �C�� #
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
        ov_retcode := cv_status_error;                                            --# �C�� #
        --
      WHEN sale_data_expt THEN
        --*** �f�[�^���o�G���[ ***
        IF ( sale_data_create_cur%ISOPEN ) THEN
          CLOSE sale_data_create_cur;
        END IF;
        IF ( sale_data_resend_cur%ISOPEN ) THEN
          CLOSE sale_data_create_cur;
        END IF;
        -- ���b�Z�[�W������擾
        lv_table_name := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_sale_exp_head_tab
        );
        -- ���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_data_get_err
         ,iv_token_name1  => cv_tkn_table_name
         ,iv_token_value1 => lv_table_name
         ,iv_token_name2  => cv_tkn_key_data
         ,iv_token_value2 => cv_blank
        );
        --
        ov_errmsg  := lv_errmsg;                                                  --# �C�� #
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;                                            --# �C�� #
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
  END get_sales_exp_data;
--
  /**********************************************************************************
   * Procedure Name   : make_sale_data
   * Description      : �t�@�C���f�[�^���^����(A-5�AA-6)
   ***********************************************************************************/
  PROCEDURE make_sale_data(
    ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_sale_data'; -- �v���O������
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
    cv_minus         CONSTANT VARCHAR2(1)  := '-';                                   -- �}�C�i�X
    cv_space_1       CONSTANT VARCHAR2(1)  := SUBSTRB(LPAD('X', 2, ' '), 1, 1);      -- 1�����X�y�[�X
    cv_space_2       CONSTANT VARCHAR2(2)  := SUBSTRB(LPAD('X', 3, ' '), 1, 2);      -- 2�����X�y�[�X
    cv_space_4       CONSTANT VARCHAR2(4)  := SUBSTRB(LPAD('X', 5, ' '), 1, 4);      -- 4�����X�y�[�X
    cv_space_14      CONSTANT VARCHAR2(14) := SUBSTRB(LPAD('X', 15, ' '), 1, 14);    -- 14�����X�y�[�X
    cv_space_40      CONSTANT VARCHAR2(40) := SUBSTRB(LPAD('X', 41, ' '), 1, 40);    -- 40�����X�y�[�X
    cv_space_46      CONSTANT VARCHAR2(46) := SUBSTRB(LPAD('X', 47, ' '), 1, 46);    -- 46�����X�y�[�X
    cv_zero_7        CONSTANT VARCHAR2(7)  := '0000000';                             -- 7��0
    cv_zero_5        CONSTANT VARCHAR2(5)  := '00000';                               -- 5��0
--
    -- *** ���[�J���ϐ� ***
    ln_quantity      NUMBER;                              -- ���v����
    ln_seq           NUMBER;                              -- �Y���p(A-8�̏����p)
    ln_cnt           NUMBER;                              -- �X�V�ڋq����
    ln_normal_cnt    NUMBER;                              -- ��������
    ln_warn_cnt      NUMBER;                              -- �x������
    lv_upd_flg       VARCHAR2(1);                         -- �f�[�^�ҏW�t���O
    lv_data_record   VARCHAR2(32767);                     -- �ҏW��̃f�[�^�擾�p
    l_date_rec       g_sales_data_rtype;                  -- �o�̓f�[�^���R�[�h
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
    ln_seq        := cn_0;
    ln_normal_cnt := cn_0;
    ln_warn_cnt   := cn_0;
    l_date_rec    := gt_sale_data_tbl(cn_1);
    -- ���v����
    ln_quantity   := NVL(l_date_rec.standard_qty, 0);
    -- �X�V�Ώیڋq�ҏW
    ln_cnt := cn_1;
    gt_update_cust_code(ln_cnt) := l_date_rec.ship_to_customer_code;
    --
    -- �̔����уf�[�^�擾
    <<sale_loop>>
    FOR ln_idx IN 2..gt_sale_data_tbl.COUNT LOOP
      IF ( l_date_rec.address3 = cv_zero_5
           OR l_date_rec.address3 IS NULL
           OR l_date_rec.industry_div_flg IS NULL ) THEN
        -- �n��R�[�h���f00000�f�܂��n��R�[�h�A�Ǝ킪�ݒ肳��Ă��Ȃ��ꍇ
        IF (( NVL(gt_sale_data_tbl(ln_idx).address3, cn_x) != NVL(l_date_rec.address3, cn_x)
             OR gt_sale_data_tbl(ln_idx).industry_div_flg != l_date_rec.industry_div_flg
             OR gt_sale_data_tbl(ln_idx).orig_delivery_date != l_date_rec.orig_delivery_date
             OR gt_sale_data_tbl(ln_idx).item_code != l_date_rec.item_code )
            OR
            ( NVL(gt_sale_data_tbl(ln_idx).address3, cn_x) = NVL(l_date_rec.address3, cn_x)
             AND gt_sale_data_tbl(ln_idx).industry_div_flg = l_date_rec.industry_div_flg
             AND gt_sale_data_tbl(ln_idx).orig_delivery_date = l_date_rec.orig_delivery_date
             AND gt_sale_data_tbl(ln_idx).item_code = l_date_rec.item_code 
             AND gt_sale_data_tbl(ln_idx).ship_to_customer_code != l_date_rec.ship_to_customer_code )) THEN
          -- �ڋq�R�[�h���O���R�[�h�f�[�^�Ɠ���̏ꍇ
          -- ���b�Z�[�W�쐬(�}�X�^���ږ��ݒ�)
          gv_out_msg := xxccp_common_pkg.get_msg(
            iv_application  => cv_xxcos_short_name
           ,iv_name         => ct_msg_mst_chk_warm
           ,iv_token_name1  => cv_tkn_customer_code
           ,iv_token_value1 => l_date_rec.ship_to_customer_code
           ,iv_token_name2  => cv_tkn_delivery_date
           ,iv_token_value2 => TO_CHAR(l_date_rec.orig_delivery_date, cv_date_format_sl)
           ,iv_token_name3  => cv_tkn_item_code
           ,iv_token_value3 => l_date_rec.item_code
           ,iv_token_name4  => cv_tkn_address
           ,iv_token_value4 => l_date_rec.address3
           ,iv_token_name5  => cv_tkn_industry_div
           ,iv_token_value5 => l_date_rec.industry_div
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
          -- �x���������Z
          ln_warn_cnt := ln_warn_cnt + cn_1;
        END IF;
        -- ���v����
        ln_quantity := gt_sale_data_tbl(ln_idx).standard_qty;
        -- �X�V�Ώیڋq�ҏW
        ln_cnt := cn_1;
        gt_update_cust_code(ln_cnt) := gt_sale_data_tbl(ln_idx).ship_to_customer_code;
      ELSE
        IF ( NVL(gt_sale_data_tbl(ln_idx).address3, cn_x) = NVL(l_date_rec.address3, cn_x)
             AND gt_sale_data_tbl(ln_idx).industry_div_flg = l_date_rec.industry_div_flg
             AND gt_sale_data_tbl(ln_idx).orig_delivery_date = l_date_rec.orig_delivery_date
             AND gt_sale_data_tbl(ln_idx).item_code = l_date_rec.item_code) THEN
          -- �n��R�[�h�A�Ǝ�A�[�i���A�i�ڂ��O���R�[�h�Ɠ���̏ꍇ
          -- ���v����
          ln_quantity := ln_quantity + gt_sale_data_tbl(ln_idx).standard_qty;
          -- 
          IF ( gt_sale_data_tbl(ln_idx).ship_to_customer_code != l_date_rec.ship_to_customer_code ) THEN
            -- �X�V�Ώیڋq�ҏW
            ln_cnt := ln_cnt + cn_1;
            gt_update_cust_code(ln_cnt) := gt_sale_data_tbl(ln_idx).ship_to_customer_code;
          END IF;
        ELSE
          -- ���v���ʂ�0�ȊO
          IF ( ln_quantity != cn_0 ) THEN
            -- ===============================
            -- �f�[�^���^(A-5)
            -- ===============================
            --
            lv_data_record := NULL;
            --�o�̓f�[�^�ݒ�
            lv_data_record := RPAD(gt_comp_code, 12, cv_space_1)                          ||      -- ��ЃR�[�h
                              RPAD(gt_org_code, 8, cv_space_1)                            ||      -- �g�D�R�[�h
                              cv_space_4                                                  ||      -- �\���P
                              cv_space_14                                                 ||      -- ��Ж���
                              cv_space_14                                                 ||      -- �g�D����
                              RPAD(l_date_rec.address3, 12, cv_space_1)                   ||      -- ���Ӑ�R�[�h
                              cv_space_2                                                  ||      -- �\���Q
                              cv_space_14                                                 ||      -- �d�b�ԍ�
                              cv_space_40                                                 ||      -- ���Ӑ於��
                              cv_space_46                                                 ||      -- ���Ӑ�Z��
                              RPAD(l_date_rec.item_code, 16, cv_space_1)                  ||      -- ���i�R�[�h
                              RPAD(l_date_rec.item_name, 46, cv_space_1)                  ||      -- ���i����
                              TO_CHAR(l_date_rec.orig_delivery_date, cv_date_format)      ||      -- �[�i��
                              RPAD(l_date_rec.industry_div_flg, 2, cv_space_1)            ||      -- ���ʃt���O
                              cv_space_1                                                  ||      -- �P�[�X���ʕ���
                              cv_zero_7                                                   ||      -- �P�[�X����
                              CASE 
                                WHEN ln_quantity < cn_0 THEN cv_minus ELSE cv_space_1
                              END                                                         ||      -- �o�����ʕ���
                              LPAD(TO_CHAR(ABS(ln_quantity)), 7, cv_0)                    ||      -- �o������
                              cv_space_2                                                          -- �\���R
            ;
            -- ===============================
            -- �t�@�C���o��(A-6)
            -- ===============================
            UTL_FILE.PUT_LINE(
              file   => gf_file_handle  --�t�@�C���n���h��
             ,buffer => lv_data_record  --�o�͕���(�f�[�^)
            );
            --
            -- �����������Z
            ln_normal_cnt := ln_normal_cnt + cn_1;
            --
          END IF;
          --
          -- �X�V����(A-8)�Ŏg�p����f�[�^�̕ҏW
          FOR i IN 1..ln_cnt LOOP
            lv_upd_flg := cv_y;
            FOR j IN 1..ln_seq LOOP
              IF ( gt_sale_update_tbl(j).orig_delivery_date = l_date_rec.orig_delivery_date 
                   AND gt_sale_update_tbl(j).ship_to_customer_code = gt_update_cust_code(i) ) THEN
                lv_upd_flg := cv_n;
                EXIT;
              END IF;
            END LOOP;
            IF ( lv_upd_flg = cv_y ) THEN
              ln_seq := ln_seq + cn_1;
              gt_sale_update_rec.ship_to_customer_code := gt_update_cust_code(i);
              gt_sale_update_rec.orig_delivery_date := l_date_rec.orig_delivery_date;
              gt_sale_update_tbl(ln_seq) := gt_sale_update_rec;
            END IF;
          END LOOP;
          -- ���v����
          ln_quantity := gt_sale_data_tbl(ln_idx).standard_qty;
          -- �X�V�Ώیڋq�ҏW
          ln_cnt := cn_1;
          gt_update_cust_code(ln_cnt) := gt_sale_data_tbl(ln_idx).ship_to_customer_code;
        END IF;
      END IF;
      --
      l_date_rec := gt_sale_data_tbl(ln_idx);
    END LOOP sale_loop;
    --
    IF ( l_date_rec.address3 = cv_zero_5
         OR l_date_rec.address3 IS NULL 
         OR l_date_rec.industry_div_flg IS NULL ) THEN
      -- �n��R�[�h���f00000�f�܂��n��R�[�h�A�Ǝ킪�ݒ肳��Ă��Ȃ��ꍇ
      -- ���b�Z�[�W�쐬(�}�X�^���ږ��ݒ�)
      gv_out_msg := xxccp_common_pkg.get_msg(
        iv_application  => cv_xxcos_short_name
       ,iv_name         => ct_msg_mst_chk_warm
       ,iv_token_name1  => cv_tkn_customer_code
       ,iv_token_value1 => l_date_rec.ship_to_customer_code
       ,iv_token_name2  => cv_tkn_delivery_date
       ,iv_token_value2 => TO_CHAR(l_date_rec.orig_delivery_date, cv_date_format_sl)
       ,iv_token_name3  => cv_tkn_item_code
       ,iv_token_value3 => l_date_rec.item_code
       ,iv_token_name4  => cv_tkn_address
       ,iv_token_value4 => l_date_rec.address3
       ,iv_token_name5  => cv_tkn_industry_div
       ,iv_token_value5 => l_date_rec.industry_div
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      -- �x���������Z
      ln_warn_cnt := ln_warn_cnt + cn_1;
    ELSE
      IF ( ln_quantity != cn_0 ) THEN
        -- ���v���ʂ�0�ȊO
        -- ===============================
        -- �f�[�^���^(A-5)
        -- ===============================
        lv_data_record := NULL;
        --�o�̓f�[�^�ݒ�
        lv_data_record := RPAD(gt_comp_code, 12, cv_space_1)                          ||      -- ��ЃR�[�h
                          RPAD(gt_org_code, 8, cv_space_1)                            ||      -- �g�D�R�[�h
                          cv_space_4                                                  ||      -- �\���P
                          cv_space_14                                                 ||      -- ��Ж���
                          cv_space_14                                                 ||      -- �g�D����
                          RPAD(l_date_rec.address3, 12, cv_space_1)                   ||      -- ���Ӑ�R�[�h
                          cv_space_2                                                  ||      -- �\���Q
                          cv_space_14                                                 ||      -- �d�b�ԍ�
                          cv_space_40                                                 ||      -- ���Ӑ於��
                          cv_space_46                                                 ||      -- ���Ӑ�Z��
                          RPAD(l_date_rec.item_code, 16, cv_space_1)                  ||      -- ���i�R�[�h
                          RPAD(l_date_rec.item_name, 46, cv_space_1)                  ||      -- ���i����
                          TO_CHAR(l_date_rec.orig_delivery_date, cv_date_format)      ||      -- �[�i��
                          RPAD(l_date_rec.industry_div_flg, 2, cv_space_1)            ||      -- ���ʃt���O
                          cv_space_1                                                  ||      -- �P�[�X���ʕ���
                          cv_zero_7                                                   ||      -- �P�[�X����
                          CASE 
                            WHEN ln_quantity < cn_0 THEN cv_minus ELSE cv_space_1
                          END                                                         ||      -- �o�����ʕ���
                          LPAD(TO_CHAR(ABS(ln_quantity)), 7, cv_0)                    ||      -- �o������
                          cv_space_2                                                          -- �\���R
        ;
        -- ===============================
        -- �t�@�C���o��(A-6)
        -- ===============================
        UTL_FILE.PUT_LINE(
          file   => gf_file_handle  --�t�@�C���n���h��
         ,buffer => lv_data_record  --�o�͕���(�f�[�^)
        );
        -- �����������Z
        ln_normal_cnt := ln_normal_cnt + cn_1;
        --
      END IF;
      --
      -- �X�V����(A-8)�Ŏg�p����f�[�^�̕ҏW
      FOR i IN 1..ln_cnt LOOP
        lv_upd_flg := cv_y;
        FOR j IN 1..ln_seq LOOP
          IF ( gt_sale_update_tbl(j).orig_delivery_date = l_date_rec.orig_delivery_date 
               AND gt_sale_update_tbl(j).ship_to_customer_code = gt_update_cust_code(i) ) THEN
            lv_upd_flg := cv_n;
            EXIT;
          END IF;
        END LOOP;
        IF ( lv_upd_flg = cv_y ) THEN
          ln_seq := ln_seq + cn_1;
          gt_sale_update_rec.ship_to_customer_code := gt_update_cust_code(i);
          gt_sale_update_rec.orig_delivery_date := l_date_rec.orig_delivery_date;
          gt_sale_update_tbl(ln_seq) := gt_sale_update_rec;
        END IF;
      END LOOP;
    END IF;
    --
    -- ���������̐ݒ�
    gn_normal_cnt := ln_normal_cnt;
    -- �x�������̐ݒ�
    gn_warn_cnt   := ln_warn_cnt;
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
      -- ���������̐ݒ�
      gn_normal_cnt := cn_0;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END make_sale_data;
--
  /**********************************************************************************
   * Procedure Name   : output_footer
   * Description      : �t�@�C����������(A-7)
   ***********************************************************************************/
  PROCEDURE output_footer(
    ov_errbuf     OUT VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_footer';           -- �v���O������
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
    --�t�@�C���N���[�Y
    -- ===============================
    UTL_FILE.FCLOSE(
      file => gf_file_handle
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
      -- ���������̐ݒ�
      gn_normal_cnt := cn_0;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_footer;
--
  /**********************************************************************************
   * Procedure Name   : update_sale_header
   * Description      : �̔����уw�b�_�e�[�u���t���O�X�V�u���M�ρv(A-8)
   ***********************************************************************************/
  PROCEDURE update_sale_header(
    iv_act_mode   IN  VARCHAR2     -- ���s�敪�F�u1:�쐬�v�u2:�����v�u3:�đ��M�v
   ,iv_date       IN  VARCHAR2     -- ���M��
   ,ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_sale_header';           -- �v���O������
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
    lv_tkn_name fnd_new_messages.message_text%TYPE;     --�g�[�N���擾�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      -- �̔����уw�b�_TBL�t���O�X�V�i���M�ρj
      <<sale_update>>
      FOR i IN  1.. gt_sale_update_tbl.COUNT LOOP
        UPDATE  xxcos_sales_exp_headers         xseh  --�̔����уw�b�_
        SET     xseh.item_sales_send_date       = DECODE(iv_act_mode,
                                                         cv_run_class_cd_create, gd_business_date,
                                                         cv_run_class_cd_resend, TO_DATE(iv_date, cv_date_format_sl))
                                                                             -- ���i�ʔ̔����ё��M��
               ,xseh.item_sales_send_flag       = cv_y                       -- ���i�ʔ̔����ё��M�σt���O
               ,xseh.last_updated_by            = cn_last_updated_by         -- �ŏI�X�V��
               ,xseh.last_update_date           = cd_last_update_date        -- �ŏI�X�V��
               ,xseh.last_update_login          = cn_last_update_login       -- �ŏI�X�V���O�C��
               ,xseh.request_id                 = cn_request_id              -- �v��ID
               ,xseh.program_application_id     = cn_program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               ,xseh.program_id                 = cn_program_id              -- �R���J�����g�E�v���O����ID
               ,xseh.program_update_date        = cd_program_update_date     -- �v���O�����X�V��
        WHERE   xseh.item_sales_send_flag       IS NULL
        AND     xseh.ship_to_customer_code      = gt_sale_update_tbl(i).ship_to_customer_code
        AND     xseh.orig_delivery_date         = gt_sale_update_tbl(i).orig_delivery_date
        AND     xseh.business_date              >= gd_business_date_start
        AND     xseh.business_date              <= gd_business_date_end
        AND     xseh.orig_delivery_date         >= TO_DATE(gt_start_date, cv_date_format_sl)
        ;
      END LOOP sale_update;
    EXCEPTION
      WHEN OTHERS THEN
        --�g�[�N���擾
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_name          -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_sale_exp_head_tab     -- �̔����уw�b�_�e�[�u��
                       );
        --���b�Z�[�W�쐬
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_name  -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_upd_err       -- �f�[�^�X�V�G���[
                         ,iv_token_name1  => cv_tkn_table_name    -- �g�[�N���R�[�h�P
                         ,iv_token_value1 => lv_tkn_name          -- �̔����уw�b�_
                         ,iv_token_name2  => cv_tkn_key_data      -- �g�[�N���R�[�h�Q
                         ,iv_token_value2 => NULL                 -- NULL
                       );
        lv_errbuf   := SQLERRM;
        -- ��s�o��
        FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
        ,buff   => NULL
        );
        -- ���������̐ݒ�
        gn_normal_cnt := cn_0;
        --
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
      -- ���������̐ݒ�
      gn_normal_cnt := cn_0;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END update_sale_header;
--
  /**********************************************************************************
   * Procedure Name   : update_sale_cancel
   * Description      : �̔����уw�b�_�e�[�u���t���O�X�V�u�����v(A-9)
   ***********************************************************************************/
  PROCEDURE update_sale_cancel(
    iv_act_mode   IN  VARCHAR2     -- ���s�敪�F�u1:�쐬�v�u2:�����v�u3:�đ��M�v
   ,iv_date       IN  VARCHAR2     -- ���M��
   ,ov_errbuf     OUT VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_sale_cancel';           -- �v���O������
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
    lv_tkn_name fnd_new_messages.message_text%TYPE;     --�g�[�N���擾�p
--
    -- *** ���[�J���E�J�[�\�� ***
    --���M�ς̔̔����я��
    CURSOR sale_update_data_cur
    IS
      SELECT  /*+ INDEX(xseh xxcos_sales_exp_headers_n06) */
              xseh.sales_exp_header_id  header_id   --�w�b�_ID
      FROM    xxcos_sales_exp_headers   xseh        --�̔����уw�b�_
      WHERE   xseh.item_sales_send_flag  = cv_y                                         -- ���i�ʔ̔����ё��M�σt���O
      AND     xseh.item_sales_send_date  = TO_DATE(iv_date, cv_date_format_sl)    -- ���i�ʔ̔����ё��M��
      AND     xseh.business_date         >= gd_business_date_start
      AND     xseh.business_date         <= gd_business_date_end
      FOR UPDATE NOWAIT;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J����O ***
    upd_sale_data_expt          EXCEPTION;   -- �f�[�^�X�V�G���[
    lock_expt                   EXCEPTION;   -- ���b�N�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
      -- ���b�N�擾�A�f�[�^�擾
      OPEN  sale_update_data_cur;
      FETCH sale_update_data_cur BULK COLLECT INTO gt_update_header_id;
      -- ���o�����擾
      gn_target_cnt := sale_update_data_cur%ROWCOUNT;
      -- �N���[�Y
      CLOSE sale_update_data_cur;
      -- ���o�����`�F�b�N
      IF ( gn_target_cnt = cn_0 ) THEN
        -- ���o�f�[�^�������ꍇ
        IF ( sale_update_data_cur%ISOPEN ) THEN
          CLOSE sale_update_data_cur;
        END IF;
        -- ���b�Z�[�W�쐬
        gv_out_msg := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_no_target_err
        );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
        );
      ELSE     
        -- �̔����уw�b�_TBL�t���O�X�V�i���M�ρj
        UPDATE  /*+ INDEX(xseh xxcos_sales_exp_headers_n06) */
                xxcos_sales_exp_headers      xseh  --�̔����уw�b�_
        SET     xseh.item_sales_send_flag    = NULL                       -- ���i�ʔ̔����ё��M�σt���O
               ,xseh.last_updated_by         = cn_last_updated_by         -- �ŏI�X�V��
               ,xseh.last_update_date        = cd_last_update_date        -- �ŏI�X�V��
               ,xseh.last_update_login       = cn_last_update_login       -- �ŏI�X�V���O�C��
               ,xseh.request_id              = cn_request_id              -- �v��ID
               ,xseh.program_application_id  = cn_program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
               ,xseh.program_id              = cn_program_id              -- �R���J�����g�E�v���O����ID
               ,xseh.program_update_date     = cd_program_update_date     -- �v���O�����X�V��
         WHERE xseh.item_sales_send_flag     = cv_y                                      -- ���i�ʔ̔����ё��M�σt���O
           AND xseh.item_sales_send_date     = TO_DATE(iv_date, cv_date_format_sl)    -- ���i�ʔ̔����ё��M��
           AND xseh.business_date            >= gd_business_date_start
           AND xseh.business_date            <= gd_business_date_end
        ;
      END IF; 
    EXCEPTION
      WHEN record_lock_expt THEN
        --*** ���b�N�G���[ ***
        IF ( sale_update_data_cur%ISOPEN ) THEN
          CLOSE sale_update_data_cur;
        END IF;
        --�g�[�N���擾
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_name          -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_sale_exp_head_tab     -- �̔����уw�b�_�e�[�u��
                       );
        -- ���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application  => cv_xxcos_short_name
         ,iv_name         => cv_msg_lock_err
         ,iv_token_name1  => cv_tkn_table
         ,iv_token_value1 => lv_tkn_name
        );
        --
        ov_errmsg  := lv_errmsg;                                                  --# �C�� #
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
        ov_retcode := cv_status_error;                                            --# �C�� #
        --
      WHEN OTHERS THEN
        IF ( sale_update_data_cur%ISOPEN ) THEN
          CLOSE sale_update_data_cur;
        END IF;
        --�g�[�N���擾
        lv_tkn_name := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_name          -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_sale_exp_head_tab     -- �̔����уw�b�_�e�[�u��
                       );
        --���b�Z�[�W�쐬
        lv_errmsg   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcos_short_name  -- �A�v���P�[�V����
                         ,iv_name         => cv_msg_upd_err       -- �f�[�^�X�V�G���[
                         ,iv_token_name1  => cv_tkn_table_name    -- �g�[�N���R�[�h�P
                         ,iv_token_value1 => lv_tkn_name          -- �̔����уw�b�_
                         ,iv_token_name2  => cv_tkn_key_data      -- �g�[�N���R�[�h�Q
                         ,iv_token_value2 => NULL                 -- NULL
                       );
        lv_errbuf   := SQLERRM;
        RAISE global_api_expt;                                        --# �C�� #
    END;
--
    --���팏���̐ݒ�
    gn_normal_cnt := gn_target_cnt;
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
  END update_sale_cancel;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE submain(
    iv_act_mode       IN  VARCHAR2,  -- ���s�敪�F�u1:�쐬�v�u2:�����v�u3:�đ��M�v
    iv_date           IN  VARCHAR2,  -- ���M��
    ov_errbuf         OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_no_target_msg      VARCHAR2(5000);  --�ΏۂȂ����b�Z�[�W�擾�p
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ==============================================================
    -- ��������(A1)
    -- ==============================================================
    init(
      iv_act_mode   =>  iv_act_mode
     ,iv_date       =>  iv_date
     ,ov_errbuf     =>  lv_errbuf
     ,ov_retcode    =>  lv_retcode
     ,ov_errmsg     =>  lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- ==============================================================
    -- �ΏۋƖ����t�Z�o����(A2)
    -- ==============================================================
    get_busines_date(
      iv_act_mode   =>  iv_act_mode
     ,iv_date       =>  iv_date
     ,ov_errbuf     =>  lv_errbuf
     ,ov_retcode    =>  lv_retcode
     ,ov_errmsg     =>  lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --
    IF ( iv_act_mode = cv_run_class_cd_create OR iv_act_mode = cv_run_class_cd_resend ) THEN
      -- �p�����[�^.���s�敪���u1:�쐬�v�܂��́u3:�đ��M�v�̏ꍇ
      --
      -- ==============================================================
      -- �t�@�C����������(A-3)
      -- ==============================================================
      output_header(
        ov_errbuf     =>  lv_errbuf
       ,ov_retcode    =>  lv_retcode
       ,ov_errmsg     =>  lv_errmsg
      );
      IF (lv_retcode != cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      --
      -- ==============================================================
      -- �̔����я�񒊏o(A-4)
      -- ==============================================================
      get_sales_exp_data(
        iv_act_mode   =>  iv_act_mode
       ,iv_date       =>  iv_date
       ,ov_errbuf     =>  lv_errbuf
       ,ov_retcode    =>  lv_retcode
       ,ov_errmsg     =>  lv_errmsg
      );
      IF (lv_retcode != cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      --
      IF ( gn_target_cnt != cn_0) THEN
        -- �Ώۃf�[�^�����o���ꂽ�ꍇ
        --
        -- ==============================================================
        -- �t�@�C���f�[�^���^����(A-5�AA-6)
        -- ==============================================================
        make_sale_data(
          ov_errbuf     =>  lv_errbuf
         ,ov_retcode    =>  lv_retcode
         ,ov_errmsg     =>  lv_errmsg
        );
        IF (lv_retcode != cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ==============================================================
        -- �̔����уw�b�_�e�[�u���t���O�X�V�u���M�ρv(A-8)
        -- ==============================================================
        update_sale_header(
          iv_act_mode   =>  iv_act_mode
         ,iv_date       =>  iv_date
         ,ov_errbuf     =>  lv_errbuf
         ,ov_retcode    =>  lv_retcode
         ,ov_errmsg     =>  lv_errmsg
        );
        IF (lv_retcode != cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      -- ==============================================================
      -- �t�@�C���I������(A-7)
      -- ==============================================================
      output_footer(
        ov_errbuf     =>  lv_errbuf
       ,ov_retcode    =>  lv_retcode
       ,ov_errmsg     =>  lv_errmsg
      );
      IF (lv_retcode != cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
      --
    ELSE
      -- �p�����[�^.���s�敪���u2:�����v�̏ꍇ
      --
      -- ==============================================================
      -- �̔����уw�b�_�e�[�u���t���O�X�V�u�����v(A-9)
      -- ==============================================================
      update_sale_cancel(
        iv_act_mode   =>  iv_act_mode
       ,iv_date       =>  iv_date
       ,ov_errbuf     =>  lv_errbuf
       ,ov_retcode    =>  lv_retcode
       ,ov_errmsg     =>  lv_errmsg
      );
      IF (lv_retcode != cv_status_normal) THEN
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
    errbuf           OUT    VARCHAR2,         -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode          OUT    VARCHAR2,         -- ���^�[���E�R�[�h    --# �Œ� #
    iv_act_mode      IN     VARCHAR2,         -- 1.���s�敪�i�쐬/����/�đ��M�j
    iv_date          IN     VARCHAR2          -- 2.���M��
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
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- �x���������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_act_mode        -- ���s�敪�i�쐬/����/�đ��M�j
      ,iv_date            -- ���M��
      ,lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================================
    -- �I������
    -- ===============================================
    -- �G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �G���[������ݒ�
      gn_error_cnt := cn_1;
    ELSE
      IF (gn_warn_cnt > 0) THEN
        lv_retcode := cv_status_warn;
      END IF;
    END IF;
--
    -- ��s�o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
    );
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => ct_msg_data_count
                    ,iv_token_name1  => cv_tkn_count1
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                    ,iv_token_name2  => cv_tkn_count2
                    ,iv_token_value2 => TO_CHAR(gn_normal_cnt)
                    ,iv_token_name3  => cv_tkn_count3
                    ,iv_token_value3 => TO_CHAR(gn_warn_cnt)
                    ,iv_token_name4  => cv_tkn_count4
                    ,iv_token_value4 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �I�����b�Z�[�W
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
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCOS011A11C;
/
