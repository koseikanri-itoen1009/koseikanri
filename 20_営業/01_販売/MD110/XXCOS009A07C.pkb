CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOS009A07C (body)
 * Description      : �󒍈ꗗ�t�@�C���o��
 * MD.050           : �󒍈ꗗ�t�@�C���o�� MD050_COS_009_A07
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  check_parameter        �p�����[�^�`�F�b�N(A-2)
 *  get_data               �Ώۃf�[�^�擾(A-3)
 *  output_data            �f�[�^�o��(A-4)
 *  update_order_line_data �󒍖��׏o�͍ςݍX�V�iEDI�捞�̂݁j(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/06/23    1.0   S.Miyakoshi      �V�K�쐬
 *  2010/08/03    1.1   K.Kiriu          [E_�{�ғ�_04125]�o�͍��ڂ̕ύX
 *  2011/02/04    1.2   OuKou            [E_�{�ғ�_04871]�o�͍��ڂ̒ǉ�
 *  2012/09/28    1.3   M.Takasaki       [E_�{�ғ�_10114]�p�t�H�[�}���X���P
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cn_per_business_group_id  CONSTANT NUMBER      := fnd_global.per_business_group_id;   --PER_BUSINESS_GROUP_ID
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** �󒍃\�[�X��ʎ擾��O ***
  global_order_source_get_expt      EXCEPTION;
  --*** �����`�F�b�N��O ***
  global_format_chk_expt            EXCEPTION;
  --*** �����Ώۃf�[�^�X�V��O ***
  global_data_update_expt           EXCEPTION;
  --*** �Ώۃf�[�^���b�N��O ***
  global_data_lock_expt             EXCEPTION;
  --*** EDI���[���t�w��Ȃ���O ***
  global_edi_date_chk_expt          EXCEPTION;
  --*** ��M�� ���t�t�]�`�F�b�N��O ***
  global_date_rever_ocd_chk_expt    EXCEPTION;
  --*** �[�i�� ���t�t�]�`�F�b�N��O ***
  global_date_rever_odh_chk_expt    EXCEPTION;
  --*** �Ώ�0����O ***
  global_no_data_expt               EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT  VARCHAR2(100) :=  'XXCOS009A07C';        -- �p�b�P�[�W��
  cv_xxcos_short_name            CONSTANT  VARCHAR2(100) :=  'XXCOS';               -- �̕��̈�Z�k�A�v����
  cv_xxccp_short_name            CONSTANT  VARCHAR2(100) :=  'XXCCP';               -- ���ʗ̈�Z�k�A�v����
  --���b�Z�[�W
  cv_str_profile_nm              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00047';    -- MO:�c�ƒP��
  cv_msg_format_check_err        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00002';    -- ���t�����`�F�b�N�G���[���b�Z�[�W
  cv_msg_date_rever_err          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00005';    -- ���t�t�]�G���[���b�Z�[�W
  cv_msg_update_err              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00011';    -- �f�[�^�X�V�G���[���b�Z�[�W
  cv_msg_lock_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00001';    -- ���b�N�擾�G���[���b�Z�[�W
  cv_msg_no_data                 CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00003';    -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_prof_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00004';    -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_order_source            CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14103';    -- �󒍃\�[�X�擾�G���[���b�Z�[�W
  cv_msg_parameter1              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14104';    -- �p�����[�^�o�̓��b�Z�[�W(EDI�p)�i�V�K�j
  cv_msg_parameter2              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14105';    -- �p�����[�^�o�̓��b�Z�[�W(EDI�p)�i�ďo�́j
  cv_msg_edi_date_err            CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14110';    -- EDI���t�w��Ȃ��G���[
  --�g�[�N����
  cv_tkn_nm_para_date            CONSTANT  VARCHAR2(100) :=  'PARA_DATE';                     --�󒍓�(FROM)�܂��͎󒍓�(TO)
  cv_tkn_nm_order_source         CONSTANT  VARCHAR2(100) :=  'ORDER_SOURCE_ID';               --�󒍃\�[�X
  cv_tkn_nm_base_code            CONSTANT  VARCHAR2(100) :=  'DELIVERY_BASE_CODE';            --�[�i���_�R�[�h
  cv_tkn_nm_date_from            CONSTANT  VARCHAR2(100) :=  'DATE_FROM';                     --(FROM)
  cv_tkn_nm_date_to              CONSTANT  VARCHAR2(100) :=  'DATE_TO';                       --(TO)
  cv_tkn_nm_s_ordered_date_f_t   CONSTANT  VARCHAR2(100) :=  'SCHEDULE_ORDERED_DATE_FROM_TO'; --�[�i�\���(FROM),(TO)
  cv_tkn_nm_table_name           CONSTANT  VARCHAR2(100) :=  'TABLE_NAME';                    --�e�[�u������
  cv_tkn_nm_table_lock           CONSTANT  VARCHAR2(100) :=  'TABLE';                         --�e�[�u������(���b�N�G���[���p)
  cv_tkn_nm_key_data             CONSTANT  VARCHAR2(100) :=  'KEY_DATA';                      --�L�[�f�[�^
  cv_tkn_nm_profile1             CONSTANT  VARCHAR2(100) :=  'PROFILE';                       --�v���t�@�C����(�̔��̈�)
  cv_tkn_nm_rep_out_type         CONSTANT  VARCHAR2(100) :=  'REPORT_OUTPUT_TYPE';            --���[�o�͋敪
  cv_tkn_nm_chain_code           CONSTANT  VARCHAR2(100) :=  'CHAIN_CODE';                    --�`�F�[���X�R�[�h
  cv_tkn_nm_order_c_date_f_t     CONSTANT  VARCHAR2(100) :=  'ORDER_CREATION_DATE_FROM_TO';   --��M��(FROM),(TO)
  cv_tkn_nm_order_source_name    CONSTANT  VARCHAR2(100) :=  'ORDER_SOURCE_NAME';             --�󒍃\�[�X��
  --�g�[�N���l
  cv_msg_vl_table_ooha           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14101';    --�󒍃e�[�u��
  cv_msg_vl_table_oola           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14102';    --�󒍖��׃e�[�u��
  cv_msg_vl_min_date             CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00120';    --MIN���t
  cv_msg_vl_max_date             CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00056';    --MAX���t
  cv_msg_vl_order_c_date_from    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14106';    --��M��(FROM)
  cv_msg_vl_order_c_date_to      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14107';    --��M��(TO)
  cv_msg_vl_order_date_h_from    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14108';    --�[�i��(FROM)
  cv_msg_vl_order_date_h_to      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14109';    --�[�i��(TO)
  cv_msg_vl_order_source_edi     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14111';    --EDI�捞
  cv_msg_flag_out                CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-14112';    --EDI�[�i�\�著�M�σt���O���́i�ΏۊO�j
  --�󒍖��׃X�e�[�^�X
  ct_ln_status_cancelled         CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CANCELLED';  --���
  --���t�t�H�[�}�b�g
  cv_yyyy_mm_dd                  CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD';            --YYYY/MM/DD�^
  cv_yyyy_mm                     CONSTANT  VARCHAR2(100) :=  'YYYY/MM';               --YYYY/MM�^
  cv_yyyymmddhhmiss              CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD HH24:MI:SS'; --YYYYMMDDHHMISS�^
  cv_hhmiss                      CONSTANT  VARCHAR2(100) :=  'HH24:MI:SS';            --HHMISS�^
  --�N�C�b�N�R�[�h�Q�Ɨp
  --�g�p�\�t���O�萔
  ct_enabled_flg_y               CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                                         :=  'Y';                             --�g�p�\
  cv_lang                        CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );               --����
  cv_type_ost                    CONSTANT  VARCHAR2(100) :=  'XXCOS1_ODR_SRC_TYPE';           --�󒍃\�[�X���
  cv_type_esf                    CONSTANT  VARCHAR2(100) :=  'XXCOS1_EDI_SEND_FLAG';          --EDI���M�t���O
  cv_type_ecl                    CONSTANT  VARCHAR2(100) :=  'XXCOS1_EDI_CONTROL_LIST';       --EDI������
  cv_type_head                   CONSTANT  VARCHAR2(100) :=  'XXCOS1_EXCEL_OUTPUT_HEAD';      --�G�N�Z���o�͗p���o��
  cv_code_ost_009_a07            CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A07%';                --�󒍃\�[�X�̃N�C�b�N�R�[�h
  cv_code_eoh_009a07             CONSTANT  VARCHAR2(100) :=  '009A07%';                       --�G�N�Z���o�͗p���o���̃N�C�b�N�R�[�h
  cv_diff_y                      CONSTANT  VARCHAR2(100) :=  'Y';                             --Y
  --�v���t�@�C���֘A
  cv_prof_min_date               CONSTANT  VARCHAR2(100) :=  'XXCOS1_MIN_DATE';               -- �v���t�@�C����(MIN���t)
  cv_prof_max_date               CONSTANT  VARCHAR2(100) :=  'XXCOS1_MAX_DATE';               -- �v���t�@�C����(MAX���t)
  --MO:�c�ƒP��
  ct_prof_org_id                 CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';
  --���敪
  cv_target_order_01             CONSTANT  VARCHAR2(100) :=  '01';      -- �󒍍쐬�Ώ�01
  --�o�͋敪
  cv_output_type_new             CONSTANT  VARCHAR2(1)   :=  '1';       -- �V�K�o��
  --�N�C�b�N�R�[�h�FEDI������̒��o����
  cv_order_schedule              CONSTANT  VARCHAR2(2)   :=  '21';      -- �[�i�\��
  --�󒍃J�e�S��
  cv_occ_mixed                   CONSTANT  VARCHAR2(10)  :=  'MIXED';   -- MIXED
  cv_occ_order                   CONSTANT  VARCHAR2(10)  :=  'ORDER';   -- ORDER
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���o��
  TYPE g_head_ttype IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY BINARY_INTEGER;
  --�󒍖��׃e�[�u���X�V�pROWID�^
  TYPE g_lines_rowid_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_oola_rowid_tab           g_lines_rowid_ttype;                               --����ROWID
  gd_proc_date                DATE;                                              --�Ɩ����t
  gd_min_date                 DATE;                                              --MIN���t
  gd_max_date                 DATE;                                              --MAX���t
  gn_org_id                   NUMBER;                                            --�c�ƒP��
  gv_order_source_edi_chk     oe_order_sources.name%TYPE;                        --�󒍃\�[�X�iEDI�捞�j
  gv_msg_flag_out             VARCHAR2(10);                                      --EDI�[�i�\�著�M�σt���O�F�ΏۊO
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  -- �󒍃\�[�X�^�C�v�FEDI�捞�̏ꍇ
  CURSOR data_edi_cur(
           icp_order_source             VARCHAR2, -- �󒍃\�[�X
           icp_delivery_base_code       VARCHAR2, -- �[�i���_�R�[�h
           icp_output_type              VARCHAR2, -- �o�͋敪
           icp_chain_code               VARCHAR2, -- �`�F�[���X�R�[�h
           icp_order_creation_date_from DATE,     -- ��M��(FROM)
           icp_order_creation_date_to   DATE,     -- ��M��(TO)
           icp_ordered_date_h_from      DATE,     -- �[�i��(FROM)
           icp_ordered_date_h_to        DATE)     -- �[�i��(TO)
  IS
    SELECT
      /*+
-- MOD DATE:2012/09/28 AUTHOR:M.Takasaki VER�F1.3 CONTENT:E_�{�ғ�_10114 START
--         LEADING(xca)
--         INDEX(xca XXCMM_CUST_ACCOUNTS_N21)
--         INDEX(ooha OE_ORDER_HEADERS_N2)
--         USE_NL(ecl)
         LEADING(xca xeh ooha)
         INDEX(xca XXCMM_CUST_ACCOUNTS_N21)
         INDEX(xeh XXCOS_EDI_HEADERS_N09)
         INDEX(ooha OE_ORDER_HEADERS_N7)
-- MOD DATE:2012/09/28 AUTHOR:M.Takasaki VER�F1.3 CONTENT:E_�{�ғ�_10114 END
      */
       xeh.medium_class                      AS medium_class                 -- �}�̋敪
      ,xeh.data_type_code                    AS data_type_code               -- �f�[�^��R�[�h
      ,xeh.file_no                           AS file_no                      -- �t�@�C���m��
      ,xeh.info_class                        AS info_class                   -- ���敪
      ,TO_CHAR(xeh.process_date, cv_yyyy_mm_dd)
                                             AS process_date                 -- ������
      ,xeh.process_time                      AS process_time                 -- ��������
      ,xeh.base_code                         AS base_code                    -- ���_�i����j�R�[�h
      ,xeh.base_name                         AS base_name                    -- ���_���i�������j
      ,xeh.edi_chain_code                    AS edi_chain_code               -- �d�c�h�`�F�[���X�R�[�h
      ,xeh.edi_chain_name                    AS edi_chain_name               -- �d�c�h�`�F�[���X���i�����j
      ,xeh.chain_code                        AS chain_code                   -- �`�F�[���X�R�[�h
      ,xeh.chain_name                        AS chain_name                   -- �`�F�[���X���i�����j
      ,xeh.report_code                       AS report_code                  -- ���[�R�[�h
      ,xeh.report_show_name                  AS report_show_name             -- ���[�\����
      ,xeh.customer_code                     AS customer_code                -- �ڋq�R�[�h
      ,xeh.customer_name                     AS customer_name                -- �ڋq���i�����j
      ,xeh.company_code                      AS company_code                 -- �ЃR�[�h
      ,xeh.company_name                      AS company_name                 -- �Ж��i�����j
      ,xeh.company_name_alt                  AS company_name_alt             -- �Ж��i�J�i�j
      ,xeh.shop_code                         AS shop_code                    -- �X�R�[�h
      ,xeh.shop_name                         AS shop_name                    -- �X���i�����j
      ,xeh.shop_name_alt                     AS shop_name_alt                -- �X���i�J�i�j
/* 2010/08/03 Ver1.1 Mod Start */
--      ,xeh.delivery_center_code              AS delivery_center_code         -- �[���Z���^�[�R�[�h
--      ,xeh.delivery_center_name              AS delivery_center_name         -- �[���Z���^�[���i�����j
      ,NVL( xeh.delivery_center_code, xca.deli_center_code )
                                             AS delivery_center_code         -- �[���Z���^�[�R�[�h
      ,NVL( xeh.delivery_center_name, xca.deli_center_name )
                                             AS delivery_center_name         -- �[���Z���^�[���i�����j
/* 2010/08/03 Ver1.1 Mod End   */
      ,xeh.delivery_center_name_alt          AS delivery_center_name_alt     -- �[���Z���^�[���i�J�i�j
      ,TO_CHAR(xeh.order_date, cv_yyyy_mm_dd)
                                             AS order_date                   -- ������
      ,TO_CHAR(xeh.center_delivery_date, cv_yyyy_mm_dd)
                                             AS center_delivery_date         -- �Z���^�[�[�i��
      ,TO_CHAR(xeh.result_delivery_date, cv_yyyy_mm_dd)
                                             AS result_delivery_date         -- ���[�i��
      ,TO_CHAR(xeh.shop_delivery_date, cv_yyyy_mm_dd)
                                             AS shop_delivery_date           -- �X�ܔ[�i��
      ,xeh.invoice_class                     AS invoice_class                -- �`�[�敪
      ,xeh.small_classification_code         AS small_classification_code    -- �����ރR�[�h
      ,xeh.small_classification_name         AS small_classification_name    -- �����ޖ�
      ,xeh.middle_classification_code        AS middle_classification_code   -- �����ރR�[�h
      ,xeh.middle_classification_name        AS middle_classification_name   -- �����ޖ�
      ,xeh.big_classification_code           AS big_classification_code      -- �啪�ރR�[�h
      ,xeh.big_classification_name           AS big_classification_name      -- �啪�ޖ�
      ,xeh.other_party_department_code       AS other_party_department_code  -- ����敔��R�[�h
      ,xeh.other_party_order_number          AS other_party_order_number     -- ����攭���ԍ�
      ,xeh.invoice_number                    AS invoice_number               -- �`�[�ԍ�
      ,xeh.check_digit                       AS check_digit                  -- �`�F�b�N�f�W�b�g
      ,xeh.order_no_ebs                      AS order_no_ebs                 -- �󒍂m���i�d�a�r�j
      ,xeh.ar_sale_class                     AS ar_sale_class                -- �����敪
      ,xeh.delivery_classe                   AS delivery_classe              -- �z���敪
      ,xeh.opportunity_no                    AS opportunity_no               -- �ւm��
/* 2010/08/03 Ver1.1 Mod Start */
--      ,xeh.area_code                         AS area_code                    -- �n��R�[�h
--      ,xeh.area_name                         AS area_name                    -- �n�於�i�����j
--      ,xeh.area_name_alt                     AS area_name_alt                -- �n�於�i�J�i�j
      ,NVL( xeh.area_code, xca.edi_district_code )
                                             AS area_code                    -- �n��R�[�h
      ,NVL( xeh.area_name, xca.edi_district_name )
                                             AS area_name                    -- �n�於�i�����j
      ,NVL( xeh.area_name_alt, xca.edi_district_kana )
                                             AS area_name_alt                -- �n�於�i�J�i�j
/* 2010/08/03 Ver1.1 Mod End   */
      ,xeh.vendor_code                       AS vendor_code                  -- �����R�[�h
      ,xeh.vendor_name                       AS vendor_name                  -- ����於�i�����j
      ,xeh.vendor_name1_alt                  AS vendor_name1_alt             -- ����於�P�i�J�i�j
      ,xeh.vendor_name2_alt                  AS vendor_name2_alt             -- ����於�Q�i�J�i�j
      ,xeh.vendor_tel                        AS vendor_tel                   -- �����s�d�k
      ,xeh.vendor_charge                     AS vendor_charge                -- �����S����
      ,xeh.vendor_address                    AS vendor_address               -- �����Z���i�����j
      ,xeh.sub_distribution_center_code      AS sub_distribution_center_code -- �T�u�����Z���^�[�R�[�h
      ,xeh.sub_distribution_center_name      AS sub_distribution_center_name -- �T�u�����Z���^�[�R�[�h��
      ,xeh.eos_handwriting_class             AS eos_handwriting_class        -- �d�n�r�E�菑�敪
      ,xeh.a1_column                         AS a1_column                    -- �`�|�P��
      ,xeh.b1_column                         AS b1_column                    -- �a�|�P��
      ,xeh.c1_column                         AS c1_column                    -- �b�|�P��
      ,xeh.d1_column                         AS d1_column                    -- �c�|�P��
      ,xeh.e1_column                         AS e1_column                    -- �d�|�P��
      ,xeh.a2_column                         AS a2_column                    -- �`�|�Q��
      ,xeh.b2_column                         AS b2_column                    -- �a�|�Q��
      ,xeh.c2_column                         AS c2_column                    -- �b�|�Q��
      ,xeh.d2_column                         AS d2_column                    -- �c�|�Q��
      ,xeh.e2_column                         AS e2_column                    -- �d�|�Q��
      ,xeh.a3_column                         AS a3_column                    -- �`�|�R��
      ,xeh.b3_column                         AS b3_column                    -- �a�|�R��
      ,xeh.c3_column                         AS c3_column                    -- �b�|�R��
      ,xeh.d3_column                         AS d3_column                    -- �c�|�R��
      ,xeh.e3_column                         AS e3_column                    -- �d�|�R��
      ,xeh.f1_column                         AS f1_column                    -- �e�|�P��
      ,xeh.g1_column                         AS g1_column                    -- �f�|�P��
      ,xeh.h1_column                         AS h1_column                    -- �g�|�P��
      ,xeh.i1_column                         AS i1_column                    -- �h�|�P��
      ,xeh.j1_column                         AS j1_column                    -- �i�|�P��
      ,xeh.k1_column                         AS k1_column                    -- �j�|�P��
      ,xeh.l1_column                         AS l1_column                    -- �k�|�P��
      ,xeh.f2_column                         AS f2_column                    -- �e�|�Q��
      ,xeh.g2_column                         AS g2_column                    -- �f�|�Q��
      ,xeh.h2_column                         AS h2_column                    -- �g�|�Q��
      ,xeh.i2_column                         AS i2_column                    -- �h�|�Q��
      ,xeh.j2_column                         AS j2_column                    -- �i�|�Q��
      ,xeh.k2_column                         AS k2_column                    -- �j�|�Q��
      ,xeh.l2_column                         AS l2_column                    -- �k�|�Q��
      ,xeh.f3_column                         AS f3_column                    -- �e�|�R��
      ,xeh.g3_column                         AS g3_column                    -- �f�|�R��
      ,xeh.h3_column                         AS h3_column                    -- �g�|�R��
      ,xeh.i3_column                         AS i3_column                    -- �h�|�R��
      ,xeh.j3_column                         AS j3_column                    -- �i�|�R��
      ,xeh.k3_column                         AS k3_column                    -- �j�|�R��
      ,xeh.l3_column                         AS l3_column                    -- �k�|�R��
      ,xeh.chain_peculiar_area_header        AS chain_peculiar_area_header   -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
      ,xel.line_no                           AS line_no                      -- �s�m��
      ,xel.stockout_class                    AS stockout_class               -- ���i�敪
      ,xel.stockout_reason                   AS stockout_reason              -- ���i���R
      ,xel.product_code_itouen               AS product_code_itouen          -- ���i�R�[�h�i�ɓ����j
      ,xel.product_code1                     AS product_code1                -- ���i�R�[�h�P
      ,xel.product_code2                     AS product_code2                -- ���i�R�[�h�Q
      ,xel.jan_code                          AS jan_code                     -- �i�`�m�R�[�h
      ,xel.itf_code                          AS itf_code                     -- �h�s�e�R�[�h
      ,xel.extension_itf_code                AS extension_itf_code           -- �����h�s�e�R�[�h
      ,xel.case_product_code                 AS case_product_code            -- �P�[�X���i�R�[�h
      ,xel.ball_product_code                 AS ball_product_code            -- �{�[�����i�R�[�h
      ,xel.prod_class                        AS prod_class                   -- ���i�敪
      ,xel.product_name                      AS product_name                 -- ���i���i�����j
      ,xel.product_name1_alt                 AS product_name1_alt            -- ���i���P�i�J�i�j
      ,xel.product_name2_alt                 AS product_name2_alt            -- ���i���Q�i�J�i�j
      ,xel.item_standard1                    AS item_standard1               -- �K�i�P
      ,xel.item_standard2                    AS item_standard2               -- �K�i�Q
      ,xel.qty_in_case                       AS qty_in_case                  -- ����
      ,xel.num_of_cases                      AS num_of_cases                 -- �P�[�X����
      ,xel.num_of_ball                       AS num_of_ball                  -- �{�[������
      ,xel.item_color                        AS item_color                   -- �F
      ,xel.item_size                         AS item_size                    -- �T�C�Y
      ,xel.order_uom_qty                     AS order_uom_qty                -- �����P�ʐ�
      ,xel.uom_code                          AS uom_code                     -- �P��
      ,xel.indv_order_qty                    AS indv_order_qty               -- �������ʁi�o���j
      ,xel.case_order_qty                    AS case_order_qty               -- �������ʁi�P�[�X�j
      ,xel.ball_order_qty                    AS ball_order_qty               -- �������ʁi�{�[���j
      ,xel.sum_order_qty                     AS sum_order_qty                -- �������ʁi���v�A�o���j
      ,xel.indv_shipping_qty                 AS indv_shipping_qty            -- �o�א��ʁi�o���j
      ,xel.case_shipping_qty                 AS case_shipping_qty            -- �o�א��ʁi�P�[�X�j
      ,xel.ball_shipping_qty                 AS ball_shipping_qty            -- �o�א��ʁi�{�[���j
      ,xel.pallet_shipping_qty               AS pallet_shipping_qty          -- �o�א��ʁi�p���b�g�j
      ,xel.sum_shipping_qty                  AS sum_shipping_qty             -- �o�א��ʁi���v�A�o���j
      ,xel.indv_stockout_qty                 AS indv_stockout_qty            -- ���i���ʁi�o���j
      ,xel.case_stockout_qty                 AS case_stockout_qty            -- ���i���ʁi�P�[�X�j
      ,xel.ball_stockout_qty                 AS ball_stockout_qty            -- ���i���ʁi�{�[���j
      ,xel.sum_stockout_qty                  AS sum_stockout_qty             -- ���i���ʁi���v�A�o���j
      ,xel.case_qty                          AS case_qty                     -- �P�[�X����
      ,xel.fold_container_indv_qty           AS fold_container_indv_qty      -- �I���R���i�o���j����
      ,xel.order_unit_price                  AS order_unit_price             -- ���P���i�����j
      ,xel.shipping_unit_price               AS shipping_unit_price          -- ���P���i�o�ׁj
      ,xel.order_cost_amt                    AS order_cost_amt               -- �������z�i�����j
      ,xel.shipping_cost_amt                 AS shipping_cost_amt            -- �������z�i�o�ׁj
      ,xel.stockout_cost_amt                 AS stockout_cost_amt            -- �������z�i���i�j
      ,xel.selling_price                     AS selling_price                -- ���P��
      ,xel.order_price_amt                   AS order_price_amt              -- �������z�i�����j
      ,xel.shipping_price_amt                AS shipping_price_amt           -- �������z�i�o�ׁj
      ,xel.stockout_price_amt                AS stockout_price_amt           -- �������z�i���i�j
      ,xel.chain_peculiar_area_line          AS chain_peculiar_area_line     -- �`�F�[���X�ŗL�G���A�i���ׁj
      ,CASE xeh.edi_chain_code
         WHEN ecl.chain_code
           THEN dsf.meaning
         ELSE gv_msg_flag_out
       END                                   AS edi_delivery_schedule_flag   -- EDI�[�i�\�著�M�σt���O
      ,oola.rowid                            AS row_id                       -- rowid
-- ADD DATE:2011/02/04 AUTHOR:OUKOU VER�F1.2 CONTENT:E_�{�ғ�_04871 START
      ,xel.general_succeeded_item1           AS general_succeeded_item1      -- �ėp���p�����ڂP
      ,xel.general_succeeded_item2           AS general_succeeded_item2      -- �ėp���p�����ڂQ
      ,xel.general_succeeded_item3           AS general_succeeded_item3      -- �ėp���p�����ڂR
      ,xel.general_succeeded_item4           AS general_succeeded_item4      -- �ėp���p�����ڂS
      ,xel.general_succeeded_item5           AS general_succeeded_item5      -- �ėp���p�����ڂT
      ,xel.general_succeeded_item6           AS general_succeeded_item6      -- �ėp���p�����ڂU
      ,xel.general_succeeded_item7           AS general_succeeded_item7      -- �ėp���p�����ڂV
      ,xel.general_succeeded_item8           AS general_succeeded_item8      -- �ėp���p�����ڂW
      ,xel.general_succeeded_item9           AS general_succeeded_item9      -- �ėp���p�����ڂX
      ,xel.general_succeeded_item10          AS general_succeeded_item10     -- �ėp���p�����ڂP�O0
-- ADD DATE:2011/02/04 AUTHOR:OUKOU VER�F1.2 CONTENT:E_�{�ғ�_04871 END
    FROM
       oe_order_headers_all      ooha    -- �󒍃w�b�_
      ,oe_order_lines_all        oola    -- �󒍖���
      ,oe_order_sources          oos     -- �󒍃\�[�X
      ,xxcmm_cust_accounts       xca     -- �ڋq�A�h�I��
      ,xxcos_edi_headers         xeh     -- EDI�w�b�_
      ,xxcos_edi_lines           xel     -- EDI����
      ,( SELECT  flv.attribute1  chain_code
         FROM    fnd_lookup_values  flv
         WHERE   flv.language         = cv_lang
         AND     flv.lookup_type      = cv_type_ecl
         AND     flv.attribute2       = cv_order_schedule
         AND     gd_proc_date        >= NVL( flv.start_date_active, gd_min_date )
         AND     gd_proc_date        <= NVL( flv.end_date_active, gd_max_date )
         AND     flv.enabled_flag     = ct_enabled_flg_y
         GROUP BY flv.attribute1
       )                         ecl     -- �N�C�b�N�R�[�h�FEDI������
      ,( SELECT  flv.lookup_code lookup_code
                ,flv.meaning     meaning
         FROM    fnd_lookup_values  flv
         WHERE   flv.language         = cv_lang
         AND     flv.lookup_type      = cv_type_esf
         AND     gd_proc_date        >= NVL( flv.start_date_active, gd_min_date )
         AND     gd_proc_date        <= NVL( flv.end_date_active, gd_max_date )
         AND     flv.enabled_flag     = ct_enabled_flg_y
       )                         dsf     -- �N�C�b�N�R�[�h�FEDI�[�i�\�著�M�σt���O
    WHERE
    -- �󒍃w�b�_.�󒍓��̔N�����Ɩ����t�|�P�̔N��
        TO_CHAR( TRUNC( NVL( ooha.ordered_date, gd_proc_date ) ), cv_yyyy_mm ) 
     >= TO_CHAR( ADD_MONTHS( TRUNC( gd_proc_date ), -1 ), cv_yyyy_mm )
    -- ���敪 = NULL OR 01
    AND (
          ooha.global_attribute3 IS NULL
        OR
          ooha.global_attribute3 = cv_target_order_01
        )
    -- �g�DID
    AND ooha.org_id                       = gn_org_id
    -- �󒍃w�b�_.�\�[�XID���󒍃\�[�X.�\�[�XID
    AND ooha.order_source_id              = oos.order_source_id
    -- �󒍃\�[�X���́iEDI�󒍁A�≮CSV�A����CSV�AOnline�j
    AND oos.name IN ( 
      SELECT  flv.attribute1
      FROM    fnd_lookup_values  flv
      WHERE   flv.language         = cv_lang
      AND     flv.lookup_type      = cv_type_ost
      AND     flv.lookup_code      LIKE cv_code_ost_009_a07
      AND     gd_proc_date        >= NVL( flv.start_date_active, gd_min_date )
      AND     gd_proc_date        <= NVL( flv.end_date_active, gd_max_date )
      AND     flv.enabled_flag     = ct_enabled_flg_y
      --�󒍃\�[�X�iEDI�捞�ECSV�捞�E�N�C�b�N�󒍓��́j
      AND     flv.description = icp_order_source
    )
    -- �󒍃w�b�_.�ڋqID = �ڋq�}�X�^�A�h�I��.�ڋqID
    AND ooha.sold_to_org_id        = xca.customer_id
    -- �ڋq�}�X�^�A�h�I��.�[�i���_�R�[�h=�p�����[�^.���_�R�[�h
    AND xca.delivery_base_code     = icp_delivery_base_code
-- ADD DATE:2012/09/28 AUTHOR:M.Takasaki VER�F1.3 CONTENT:E_�{�ғ�_10114 START
    -- EDI�w�b�_.�ϊ���ڋq�R�[�h = �ڋq�A�h�I��.�ڋq�R�[�h
    AND xeh.conv_customer_code     = xca.customer_code
-- ADD DATE:2012/09/28 AUTHOR:M.Takasaki VER�F1.3 CONTENT:E_�{�ғ�_10114 END
    -- �󒍃w�b�_.�󒍃w�b�_ID���󒍖���.�󒍃w�b�_ID
    AND ooha.header_id             = oola.header_id
    -- �󒍖���.�X�e�[�^�X�����
    AND oola.flow_status_code NOT IN ( ct_ln_status_cancelled )
    -- �󒍃w�b�_.�O���V�X�e���󒍔ԍ���EDI�w�b�_.�󒍊֘A�ԍ�
    AND ooha.orig_sys_document_ref = xeh.order_connection_number
    -- EDI�w�b�_.EDI�w�b�_ID��EDI����.EDI�w�b�_ID
    AND xeh.edi_header_info_id     = xel.edi_header_info_id
    -- �󒍖���.�O���V�X�e���󒍖��הԍ���EDI����.�󒍊֘A���הԍ�
    AND oola.orig_sys_line_ref     = xel.order_connection_line_number
    AND ( 
      --�V�K�o�͂̏ꍇ
      ( icp_output_type = cv_output_type_new
        --�t�@�C���o�͓� IS NULL
        AND oola.global_attribute6 IS NULL
      )
      OR
      --�ďo�͂̏ꍇ
      ( icp_output_type <> cv_output_type_new
        --�t�@�C���o�͓� IS NOT NULL
        AND oola.global_attribute6 IS NOT NULL
        --�ڋq�}�X�^.�`�F�[���X�R�[�h���p�����[�^.�`�F�[���X�R�[�h
        AND (  icp_chain_code IS NULL
            OR xca.chain_store_code = icp_chain_code
            )
        AND (
          --�p�����[�^��M����NLLL
          (
            icp_order_creation_date_from IS NULL
            AND icp_order_creation_date_to IS NULL
          )
          --�p�����[�^��M���ɐݒ肠��
          OR (
            --�󒍃w�b�_.�쐬�����p�����[�^.��M���iFROM�j
            TRUNC( ooha.creation_date )     >= 
                TRUNC( icp_order_creation_date_from )
            --�󒍃w�b�_.�쐬�����p�����[�^.��M���iTO�j
            AND TRUNC( ooha.creation_date ) <= TRUNC( icp_order_creation_date_to )
          )
        )
        AND (
          --�p�����[�^�[�i����NLLL
          (
            icp_ordered_date_h_from IS NULL
            AND icp_ordered_date_h_to IS NULL
          )
          --�p�����[�^�[�i���ɐݒ肠��
          OR (
            --�󒍃w�b�_.�[�i�\������p�����[�^.�[�i���iFROM�j
            TRUNC( ooha.request_date )     >= 
                TRUNC( icp_ordered_date_h_from )
            --�󒍃w�b�_.�[�i���\������p�����[�^.�[�i���iTO�j
            AND TRUNC( ooha.request_date ) <= TRUNC( icp_ordered_date_h_to )
          )
        )
      )
    )
    -- EDI�[�i�\�著�M�σt���O�̖��̎擾
    AND xeh.edi_delivery_schedule_flag = dsf.lookup_code
    -- EDI��������[�i�\��𔻒�
    AND ecl.chain_code(+) = xeh.edi_chain_code
    -- �󒍃J�e�S��
    AND ooha.order_category_code in ( cv_occ_mixed, cv_occ_order )
    ORDER BY
       xca.chain_store_code  -- �`�F�[���X�R�[�h
      ,xca.store_code        -- �X�܃R�[�h
      ,ooha.request_date     -- �[�i��(�w�b�_)
      ,ooha.cust_po_number   -- �ڋq�����ԍ�
      ,ooha.order_number     -- �󒍔ԍ�
      ,oola.line_number      -- �󒍖��הԍ�
    FOR UPDATE OF
       ooha.header_id        -- �󒍃w�b�_.�w�b�_ID
      ,oola.line_id          -- �󒍖���.����ID
    NOWAIT
    ;
--
  --�擾�f�[�^�i�[�ϐ���`
  TYPE g_out_file_ttype IS TABLE OF data_edi_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_out_file_tab       g_out_file_ttype;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_order_source                 IN     VARCHAR2,  -- �󒍃\�[�X
    iv_delivery_base_code           IN     VARCHAR2,  -- �[�i���_�R�[�h
    iv_output_type                  IN     VARCHAR2,  -- �o�͋敪
    iv_chain_code                   IN     VARCHAR2,  -- �`�F�[���X�R�[�h
    iv_order_creation_date_from     IN     VARCHAR2,  -- ��M��(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,  -- ��M��(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,  -- �[�i��(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,  -- �[�i��(TO)
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- �v���O������
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
    lv_para_msg            VARCHAR2(5000);                         -- �p�����[�^�o�̓��b�Z�[�W
    lv_date_item           VARCHAR2(100);                          -- MIN���t/MAX���t
    lv_profile_name        VARCHAR2(100);                          -- �c�ƒP��
    lv_token_value1        VARCHAR2(100);                          -- �G���[���b�Z�[�W�ɏo�͂���g�[�N���l
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
    --========================================
    -- �p�����[�^�o�͏���
    --========================================
    IF ( iv_output_type = cv_output_type_new ) THEN   --EDI�i�V�K�j
      lv_para_msg             :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_parameter1,
        iv_token_name1        =>  cv_tkn_nm_order_source,
        iv_token_value1       =>  iv_order_source,
        iv_token_name2        =>  cv_tkn_nm_base_code,
        iv_token_value2       =>  iv_delivery_base_code,
        iv_token_name3        =>  cv_tkn_nm_rep_out_type,
        iv_token_value3       =>  iv_output_type
      );
    ELSE  --EDI�i�ďo�́j
      lv_para_msg             :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_parameter2,
        iv_token_name1        =>  cv_tkn_nm_order_source,
        iv_token_value1       =>  iv_order_source,
        iv_token_name2        =>  cv_tkn_nm_base_code,
        iv_token_value2       =>  iv_delivery_base_code,
        iv_token_name3        =>  cv_tkn_nm_rep_out_type,
        iv_token_value3       =>  iv_output_type,
        iv_token_name4        =>  cv_tkn_nm_chain_code,
        iv_token_value4       =>  iv_chain_code,
        iv_token_name5        =>  cv_tkn_nm_order_c_date_f_t,
        iv_token_value5       =>  iv_order_creation_date_from || ',' || iv_order_creation_date_to,
        iv_token_name6        =>  cv_tkn_nm_s_ordered_date_f_t,
        iv_token_value6       =>  iv_ordered_date_h_from || ',' || iv_ordered_date_h_to
      );
    END IF;
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================
    -- MO:�c�ƒP��
    --==================================
    gn_org_id := FND_PROFILE.VALUE( ct_prof_org_id );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gn_org_id IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application => cv_xxcos_short_name,
        iv_name        => cv_str_profile_nm
      );
      --�v���t�@�C����������擾
      lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcos_short_name,
        iv_name               => cv_msg_prof_err,
        iv_token_name1        => cv_tkn_nm_profile1,
        iv_token_value1       => lv_profile_name
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- �Ɩ����t�擾����
    --========================================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- MIN���t�擾����
    --========================================
    gd_min_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_min_date ), cv_yyyy_mm_dd );
    IF ( gd_min_date IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_min_date
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile1,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- MAX���t�擾����
    --========================================
    gd_max_date := FND_DATE.STRING_TO_DATE( FND_PROFILE.VALUE( cv_prof_max_date ), cv_yyyy_mm_dd );
    IF ( gd_max_date IS NULL ) THEN
      lv_date_item            :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_max_date
      );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_prof_err,
        iv_token_name1        =>  cv_tkn_nm_profile1,
        iv_token_value1       =>  lv_date_item
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- �󒍃\�[�X��ʎ擾�̑O����
    --========================================
    BEGIN
      --EDI�捞 �󒍃\�[�X�̖��̂��擾
      SELECT  flv.description        order_source_edi
      INTO    gv_order_source_edi_chk
      FROM    fnd_lookup_values  flv
      WHERE   flv.language        = cv_lang
      AND     flv.lookup_type     = cv_type_ost
      AND     flv.lookup_code     LIKE cv_code_ost_009_a07
      AND     flv.attribute2      = cv_diff_y               --EDI�捞
      AND     gd_proc_date       >= NVL( flv.start_date_active, gd_min_date )
      AND     gd_proc_date       <= NVL( flv.end_date_active,   gd_max_date )
      AND     flv.enabled_flag    = ct_enabled_flg_y
      AND     rownum              = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_token_value1 := xxccp_common_pkg.get_msg(
          iv_application        =>  cv_xxcos_short_name,
          iv_name               =>  cv_msg_vl_order_source_edi
        );
        RAISE global_order_source_get_expt;
    END;
--
    --========================================
    -- EDI�[�i�\�著�M�σt���O���́i�ΏۊO�j�̎擾
    --========================================
    gv_msg_flag_out := xxccp_common_pkg.get_msg(
                         iv_application        =>  cv_xxcos_short_name,
                         iv_name               =>  cv_msg_flag_out
                       );
--
  EXCEPTION
    -- *** �󒍃\�[�X��ʎ擾��O�n���h�� ***
    WHEN global_order_source_get_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_order_source,
        iv_token_name1        =>  cv_tkn_nm_order_source_name,
        iv_token_value1       =>  lv_token_value1
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : check_parameter
   * Description      : �p�����[�^�`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    iv_order_source                 IN     VARCHAR2,     --   �󒍃\�[�X
    iv_output_type                  IN     VARCHAR2,     --   �o�͋敪
    iv_order_creation_date_from     IN     VARCHAR2,     --   ��M��(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,     --   ��M��(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,     --   �[�i��(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,     --   �[�i��(TO)
    od_order_creation_date_from     OUT    DATE,         --   ��M��(FROM)_�`�F�b�NOK
    od_order_creation_date_to       OUT    DATE,         --   ��M��(TO)_�`�F�b�NOK
    od_ordered_date_h_from          OUT    DATE,         --   �[�i��(FROM)_�`�F�b�NOK
    od_ordered_date_h_to            OUT    DATE,         --   �[�i��(TO)_�`�F�b�NOK
    ov_errbuf                       OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter'; -- �v���O������
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
    lv_check_item                    VARCHAR2(100);      -- ��M��(FROM)���͎�M��(TO)����
    lv_check_item1                   VARCHAR2(100);      -- ��M��(FROM)����
    lv_check_item2                   VARCHAR2(100);      -- ��M��(TO)����
    ld_order_creation_date_from      DATE;               -- ��M��(FROM)_�`�F�b�NOK
    ld_order_creation_date_to        DATE;               -- ��M��(TO)_�`�F�b�NOK
    ld_ordered_date_h_from           DATE;               -- �[�i��(�w�b�_)(FROM)_�`�F�b�NOK
    ld_ordered_date_h_to             DATE;               -- �[�i��(�w�b�_)(TO)_�`�F�b�NOK
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
    --EDI�ďo�͎��̓��t�`�F�b�N
    IF ( iv_order_source = gv_order_source_edi_chk ) AND ( iv_output_type <> cv_output_type_new ) THEN
      --��M���A�[�i���̂��Â�̓��̓`�F�b�N
      IF ( iv_order_creation_date_from IS NULL ) AND ( iv_order_creation_date_to IS NULL )
        AND ( iv_ordered_date_h_from IS NULL ) AND ( iv_ordered_date_h_to IS NULL )
      THEN
        RAISE global_edi_date_chk_expt;
      END IF;
      --��M��(FROM)�K�{�`�F�b�N
      IF ( ( iv_order_creation_date_from IS NULL ) AND ( iv_order_creation_date_to IS NOT NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_c_date_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --��M��(TO)�K�{�`�F�b�N
      IF ( ( iv_order_creation_date_from IS NOT NULL ) AND ( iv_order_creation_date_to IS NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_c_date_to
        );
        RAISE global_format_chk_expt;
      END IF;
      --��M��(FROM)�A��M��(TO)�������͂��ꂽ�ꍇ
      IF ( ( iv_order_creation_date_from IS NOT NULL ) AND ( iv_order_creation_date_to IS NOT NULL ) ) THEN
        --��M��(FROM)�����`�F�b�N
        ld_order_creation_date_from := FND_DATE.STRING_TO_DATE( iv_order_creation_date_from, cv_yyyy_mm_dd );
        IF ( ld_order_creation_date_from IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_c_date_from
          );
          RAISE global_format_chk_expt;
        END IF;
        --��M��(TO)�����`�F�b�N
        ld_order_creation_date_to := FND_DATE.STRING_TO_DATE( iv_order_creation_date_to, cv_yyyy_mm_dd );
        IF ( ld_order_creation_date_to IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_c_date_to
          );
          RAISE global_format_chk_expt;
        END IF;
        --��M��(FROM)�^--��M��(TO)���t�t�]�`�F�b�N
        IF ( ld_order_creation_date_from > ld_order_creation_date_to ) THEN
          RAISE global_date_rever_ocd_chk_expt;
        END IF;
      END IF;
--
      --�[�i��(FROM)�K�{�`�F�b�N
      IF ( ( iv_ordered_date_h_from IS NULL ) AND ( iv_ordered_date_h_to IS NOT NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_date_h_from
        );
        RAISE global_format_chk_expt;
      END IF;
      --�[�i��(TO)�K�{�`�F�b�N
      IF ( ( iv_ordered_date_h_from IS NOT NULL ) AND ( iv_ordered_date_h_to IS NULL ) ) THEN
        lv_check_item         :=  xxccp_common_pkg.get_msg(
          iv_application      =>  cv_xxcos_short_name,
          iv_name             =>  cv_msg_vl_order_date_h_to
        );
        RAISE global_format_chk_expt;
      END IF;
      --�[�i��(FROM)�A�[�i��(TO)�������͂��ꂽ�ꍇ
      IF ( ( iv_ordered_date_h_from IS NOT NULL ) AND ( iv_ordered_date_h_to IS NOT NULL ) ) THEN
        --�[�i��(FROM)�����`�F�b�N
        ld_ordered_date_h_from := FND_DATE.STRING_TO_DATE( iv_ordered_date_h_from, cv_yyyy_mm_dd );
        IF ( ld_ordered_date_h_from IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_date_h_from
          );
          RAISE global_format_chk_expt;
        END IF;
        --�[�i��(TO)�����`�F�b�N
        ld_ordered_date_h_to := FND_DATE.STRING_TO_DATE( iv_ordered_date_h_to, cv_yyyy_mm_dd );
        IF ( ld_ordered_date_h_to IS NULL ) THEN
          lv_check_item         :=  xxccp_common_pkg.get_msg(
            iv_application      =>  cv_xxcos_short_name,
            iv_name             =>  cv_msg_vl_order_date_h_to
          );
          RAISE global_format_chk_expt;
        END IF;
        --�[�i��(FROM)�^--�[�i��(TO)���t�t�]�`�F�b�N
        IF ( ld_ordered_date_h_from > ld_ordered_date_h_to ) THEN
          RAISE global_date_rever_odh_chk_expt;
        END IF;
      END IF;
--
    END IF;
--
--
    --�`�F�b�NOK
    od_order_creation_date_from   := ld_order_creation_date_from;
    od_order_creation_date_to     := ld_order_creation_date_to;
    od_ordered_date_h_from        := ld_ordered_date_h_from;
    od_ordered_date_h_to          := ld_ordered_date_h_to;
--
  EXCEPTION
    -- *** �����`�F�b�N��O�n���h�� ***
    WHEN global_format_chk_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_format_check_err,
        iv_token_name1        =>  cv_tkn_nm_para_date,
        iv_token_value1       =>  lv_check_item
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- ***EDI���t�w��Ȃ���O�n���h�� ***
    WHEN global_edi_date_chk_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_edi_date_err
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- ***��M�� ���t�t�]�`�F�b�N��O�n���h�� ***
    WHEN global_date_rever_ocd_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_c_date_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_c_date_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- ***�[�i�� ���t�t�]�`�F�b�N��O�n���h�� ***
    WHEN global_date_rever_odh_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_date_h_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_order_date_h_to
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_rever_err,
        iv_token_name1        =>  cv_tkn_nm_date_from,
        iv_token_value1       =>  lv_check_item1,
        iv_token_name2        =>  cv_tkn_nm_date_to,
        iv_token_value2       =>  lv_check_item2
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �����Ώۃf�[�^�擾(A-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_order_source                 IN     VARCHAR2,     --   �󒍃\�[�X
    iv_delivery_base_code           IN     VARCHAR2,     --   �[�i���_�R�[�h
    iv_output_type                  IN     VARCHAR2,     --   �o�͋敪
    iv_chain_code                   IN     VARCHAR2,     --   �`�F�[���X�R�[�h
    id_order_creation_date_from     IN     DATE,         --   ��M��(FROM)
    id_order_creation_date_to       IN     DATE,         --   ��M��(TO)
    id_ordered_date_h_from          IN     DATE,         --   �[�i��(FROM)
    id_ordered_date_h_to            IN     DATE,         --   �[�i��(TO)
    ov_errbuf                       OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_tkn_vl_table_name      VARCHAR2(100);                          --�e�[�u������(����)
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
    --�Ώۃf�[�^�擾
    OPEN  data_edi_cur(
            iv_order_source,                -- �󒍃\�[�X
            iv_delivery_base_code,          -- �[�i���_�R�[�h
            iv_output_type,                 -- �o�͋敪
            iv_chain_code,                  -- �`�F�[���X�R�[�h
            id_order_creation_date_from,    -- ��M��(FROM)
            id_order_creation_date_to,      -- ��M��(TO)
            id_ordered_date_h_from,         -- �[�i��(FROM)
            id_ordered_date_h_to);          -- �[�i��(TO)
    FETCH data_edi_cur BULK COLLECT INTO gt_out_file_tab;
    CLOSE data_edi_cur;
--
    --���������J�E���g
    gn_target_cnt := gt_out_file_tab.COUNT;
--
  EXCEPTION
--
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      IF ( data_edi_cur%ISOPEN ) THEN
        CLOSE data_edi_cur;
      END IF;
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_ooha
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_lock_err,
        iv_token_name1        =>  cv_tkn_nm_table_lock,
        iv_token_value1       =>  lv_tkn_vl_table_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( data_edi_cur%ISOPEN ) THEN
        CLOSE data_edi_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : output_data
   * Description      : �f�[�^�o��(A-4)
   ***********************************************************************************/
  PROCEDURE output_data(
    iv_order_source                 IN     VARCHAR2,  --   �󒍃\�[�X
    iv_delivery_base_code           IN     VARCHAR2,  --   �[�i���_�R�[�h
    iv_output_type                  IN     VARCHAR2,  --   �o�͋敪
    iv_chain_code                   IN     VARCHAR2,  --   �`�F�[���X�R�[�h
    iv_order_creation_date_from     IN     VARCHAR2,  --   ��M��(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,  --   ��M��(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,  --   �[�i��(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,  --   �[�i��(TO)
    ov_errbuf                       OUT    VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_data'; -- �v���O������
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
    lv_delimit    CONSTANT  VARCHAR2(10) := '	';    -- ��؂蕶��
    lv_colon      CONSTANT  VARCHAR2(10) := ':';    -- ���������̋�؂蕶��
--
    -- *** ���[�J���ϐ� ***
    lv_line_data            VARCHAR2(5000);         -- OUTPUT�f�[�^�ҏW�p
    lv_out_process_time     VARCHAR2(10);           -- �ҏW��̏�������
--
    -- *** ���[�J���E�J�[�\�� ***
    --���o���擾�p�J�[�\��
    CURSOR head_cur
    IS
      SELECT  flv.description  head
      FROM    fnd_lookup_values flv
      WHERE   flv.language      = cv_lang
      AND     flv.lookup_type   = cv_type_head
      AND     lookup_code    LIKE cv_code_eoh_009a07
      AND     gd_proc_date     >= NVL( flv.start_date_active, gd_min_date )
      AND     gd_proc_date     <= NVL( flv.end_date_active,   gd_max_date )
      AND     flv.enabled_flag  = ct_enabled_flg_y
      ORDER BY
              flv.lookup_code
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
    -- *** ���[�J���E�e�[�u�� ***
    lt_head_tab g_head_ttype;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ----------------------
    --�f�[�^���o���o��
    ----------------------
    --�f�[�^�̌��o�����擾
    OPEN  head_cur;
    FETCH head_cur BULK COLLECT INTO lt_head_tab;
    CLOSE head_cur;
--
    --�f�[�^�̌��o����ҏW
    <<data_head_output>>
    FOR i IN 1..lt_head_tab.COUNT LOOP
      IF ( i = 1 ) THEN
        lv_line_data := lt_head_tab(i);
      ELSE
        lv_line_data := lv_line_data || lv_delimit || lt_head_tab(i);
      END IF;
    END LOOP data_head_output;
--
    --�f�[�^�̌��o�����o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_line_data
    );
--
    ----------------------
    --�f�[�^�o��
    ----------------------
    --�f�[�^���擾
    <<data_output>>
    FOR i IN 1..gt_out_file_tab.COUNT LOOP
      --������
      lv_line_data        := NULL;
      lv_out_process_time := NULL;
      --���������̕ҏW
      IF( gt_out_file_tab(i).process_time IS NULL) THEN
        NULL;
      ELSE
        lv_out_process_time := SUBSTR( gt_out_file_tab(i).process_time, 1, 2 ) || lv_colon ||   -- ��
                               SUBSTR( gt_out_file_tab(i).process_time, 3, 2 ) || lv_colon ||   -- ��
                               SUBSTR( gt_out_file_tab(i).process_time, 5, 2 );                 -- �b
      END IF;
      --�f�[�^��ҏW
      lv_line_data :=                  gt_out_file_tab(i).medium_class                 -- �}�̋敪
                      || lv_delimit || gt_out_file_tab(i).data_type_code               -- �f�[�^��R�[�h
                      || lv_delimit || gt_out_file_tab(i).file_no                      -- �t�@�C���m��
                      || lv_delimit || gt_out_file_tab(i).info_class                   -- ���敪
                      || lv_delimit || gt_out_file_tab(i).process_date                 -- ������
                      || lv_delimit || lv_out_process_time                             -- ��������
                      || lv_delimit || gt_out_file_tab(i).base_code                    -- ���_�i����j�R�[�h
                      || lv_delimit || gt_out_file_tab(i).base_name                    -- ���_���i�������j
                      || lv_delimit || gt_out_file_tab(i).edi_chain_code               -- �d�c�h�`�F�[���X�R�[�h
                      || lv_delimit || gt_out_file_tab(i).edi_chain_name               -- �d�c�h�`�F�[���X���i�����j
                      || lv_delimit || gt_out_file_tab(i).chain_code                   -- �`�F�[���X�R�[�h
                      || lv_delimit || gt_out_file_tab(i).chain_name                   -- �`�F�[���X���i�����j
                      || lv_delimit || gt_out_file_tab(i).report_code                  -- ���[�R�[�h
                      || lv_delimit || gt_out_file_tab(i).report_show_name             -- ���[�\����
                      || lv_delimit || gt_out_file_tab(i).customer_code                -- �ڋq�R�[�h
                      || lv_delimit || gt_out_file_tab(i).customer_name                -- �ڋq���i�����j
                      || lv_delimit || gt_out_file_tab(i).company_code                 -- �ЃR�[�h
                      || lv_delimit || gt_out_file_tab(i).company_name                 -- �Ж��i�����j
                      || lv_delimit || gt_out_file_tab(i).company_name_alt             -- �Ж��i�J�i�j
                      || lv_delimit || gt_out_file_tab(i).shop_code                    -- �X�R�[�h
                      || lv_delimit || gt_out_file_tab(i).shop_name                    -- �X���i�����j
                      || lv_delimit || gt_out_file_tab(i).shop_name_alt                -- �X���i�J�i�j
                      || lv_delimit || gt_out_file_tab(i).delivery_center_code         -- �[���Z���^�[�R�[�h
                      || lv_delimit || gt_out_file_tab(i).delivery_center_name         -- �[���Z���^�[���i�����j
                      || lv_delimit || gt_out_file_tab(i).delivery_center_name_alt     -- �[���Z���^�[���i�J�i�j
                      || lv_delimit || gt_out_file_tab(i).order_date                   -- ������
                      || lv_delimit || gt_out_file_tab(i).center_delivery_date         -- �Z���^�[�[�i��
                      || lv_delimit || gt_out_file_tab(i).result_delivery_date         -- ���[�i��
                      || lv_delimit || gt_out_file_tab(i).shop_delivery_date           -- �X�ܔ[�i��
                      || lv_delimit || gt_out_file_tab(i).invoice_class                -- �`�[�敪
                      || lv_delimit || gt_out_file_tab(i).small_classification_code    -- �����ރR�[�h
                      || lv_delimit || gt_out_file_tab(i).small_classification_name    -- �����ޖ�
                      || lv_delimit || gt_out_file_tab(i).middle_classification_code   -- �����ރR�[�h
                      || lv_delimit || gt_out_file_tab(i).middle_classification_name   -- �����ޖ�
                      || lv_delimit || gt_out_file_tab(i).big_classification_code      -- �啪�ރR�[�h
                      || lv_delimit || gt_out_file_tab(i).big_classification_name      -- �啪�ޖ�
                      || lv_delimit || gt_out_file_tab(i).other_party_department_code  -- ����敔��R�[�h
                      || lv_delimit || gt_out_file_tab(i).other_party_order_number     -- ����攭���ԍ�
                      || lv_delimit || gt_out_file_tab(i).invoice_number               -- �`�[�ԍ�
                      || lv_delimit || gt_out_file_tab(i).check_digit                  -- �`�F�b�N�f�W�b�g
                      || lv_delimit || gt_out_file_tab(i).order_no_ebs                 -- �󒍂m���i�d�a�r�j
                      || lv_delimit || gt_out_file_tab(i).ar_sale_class                -- �����敪
                      || lv_delimit || gt_out_file_tab(i).delivery_classe              -- �z���敪
                      || lv_delimit || gt_out_file_tab(i).opportunity_no               -- �ւm��
                      || lv_delimit || gt_out_file_tab(i).area_code                    -- �n��R�[�h
                      || lv_delimit || gt_out_file_tab(i).area_name                    -- �n�於�i�����j
                      || lv_delimit || gt_out_file_tab(i).area_name_alt                -- �n�於�i�J�i�j
                      || lv_delimit || gt_out_file_tab(i).vendor_code                  -- �����R�[�h
                      || lv_delimit || gt_out_file_tab(i).vendor_name                  -- ����於�i�����j
                      || lv_delimit || gt_out_file_tab(i).vendor_name1_alt             -- ����於�P�i�J�i�j
                      || lv_delimit || gt_out_file_tab(i).vendor_name2_alt             -- ����於�Q�i�J�i�j
                      || lv_delimit || gt_out_file_tab(i).vendor_tel                   -- �����s�d�k
                      || lv_delimit || gt_out_file_tab(i).vendor_charge                -- �����S����
                      || lv_delimit || gt_out_file_tab(i).vendor_address               -- �����Z���i�����j
                      || lv_delimit || gt_out_file_tab(i).sub_distribution_center_code -- �T�u�����Z���^�[�R�[�h
                      || lv_delimit || gt_out_file_tab(i).sub_distribution_center_name -- �T�u�����Z���^�[�R�[�h��
                      || lv_delimit || gt_out_file_tab(i).eos_handwriting_class        -- �d�n�r�E�菑�敪
                      || lv_delimit || gt_out_file_tab(i).a1_column                    -- �`�|�P��
                      || lv_delimit || gt_out_file_tab(i).b1_column                    -- �a�|�P��
                      || lv_delimit || gt_out_file_tab(i).c1_column                    -- �b�|�P��
                      || lv_delimit || gt_out_file_tab(i).d1_column                    -- �c�|�P��
                      || lv_delimit || gt_out_file_tab(i).e1_column                    -- �d�|�P��
                      || lv_delimit || gt_out_file_tab(i).a2_column                    -- �`�|�Q��
                      || lv_delimit || gt_out_file_tab(i).b2_column                    -- �a�|�Q��
                      || lv_delimit || gt_out_file_tab(i).c2_column                    -- �b�|�Q��
                      || lv_delimit || gt_out_file_tab(i).d2_column                    -- �c�|�Q��
                      || lv_delimit || gt_out_file_tab(i).e2_column                    -- �d�|�Q��
                      || lv_delimit || gt_out_file_tab(i).a3_column                    -- �`�|�R��
                      || lv_delimit || gt_out_file_tab(i).b3_column                    -- �a�|�R��
                      || lv_delimit || gt_out_file_tab(i).c3_column                    -- �b�|�R��
                      || lv_delimit || gt_out_file_tab(i).d3_column                    -- �c�|�R��
                      || lv_delimit || gt_out_file_tab(i).e3_column                    -- �d�|�R��
                      || lv_delimit || gt_out_file_tab(i).f1_column                    -- �e�|�P��
                      || lv_delimit || gt_out_file_tab(i).g1_column                    -- �f�|�P��
                      || lv_delimit || gt_out_file_tab(i).h1_column                    -- �g�|�P��
                      || lv_delimit || gt_out_file_tab(i).i1_column                    -- �h�|�P��
                      || lv_delimit || gt_out_file_tab(i).j1_column                    -- �i�|�P��
                      || lv_delimit || gt_out_file_tab(i).k1_column                    -- �j�|�P��
                      || lv_delimit || gt_out_file_tab(i).l1_column                    -- �k�|�P��
                      || lv_delimit || gt_out_file_tab(i).f2_column                    -- �e�|�Q��
                      || lv_delimit || gt_out_file_tab(i).g2_column                    -- �f�|�Q��
                      || lv_delimit || gt_out_file_tab(i).h2_column                    -- �g�|�Q��
                      || lv_delimit || gt_out_file_tab(i).i2_column                    -- �h�|�Q��
                      || lv_delimit || gt_out_file_tab(i).j2_column                    -- �i�|�Q��
                      || lv_delimit || gt_out_file_tab(i).k2_column                    -- �j�|�Q��
                      || lv_delimit || gt_out_file_tab(i).l2_column                    -- �k�|�Q��
                      || lv_delimit || gt_out_file_tab(i).f3_column                    -- �e�|�R��
                      || lv_delimit || gt_out_file_tab(i).g3_column                    -- �f�|�R��
                      || lv_delimit || gt_out_file_tab(i).h3_column                    -- �g�|�R��
                      || lv_delimit || gt_out_file_tab(i).i3_column                    -- �h�|�R��
                      || lv_delimit || gt_out_file_tab(i).j3_column                    -- �i�|�R��
                      || lv_delimit || gt_out_file_tab(i).k3_column                    -- �j�|�R��
                      || lv_delimit || gt_out_file_tab(i).l3_column                    -- �k�|�R��
                      || lv_delimit || gt_out_file_tab(i).chain_peculiar_area_header   -- �`�F�[���X�ŗL�G���A�i�w�b�_�[�j
                      || lv_delimit || gt_out_file_tab(i).line_no                      -- �s�m��
                      || lv_delimit || gt_out_file_tab(i).stockout_class               -- ���i�敪
                      || lv_delimit || gt_out_file_tab(i).stockout_reason              -- ���i���R
                      || lv_delimit || gt_out_file_tab(i).product_code_itouen          -- ���i�R�[�h�i�ɓ����j
                      || lv_delimit || gt_out_file_tab(i).product_code1                -- ���i�R�[�h�P
                      || lv_delimit || gt_out_file_tab(i).product_code2                -- ���i�R�[�h�Q
                      || lv_delimit || gt_out_file_tab(i).jan_code                     -- �i�`�m�R�[�h
                      || lv_delimit || gt_out_file_tab(i).itf_code                     -- �h�s�e�R�[�h
                      || lv_delimit || gt_out_file_tab(i).extension_itf_code           -- �����h�s�e�R�[�h
                      || lv_delimit || gt_out_file_tab(i).case_product_code            -- �P�[�X���i�R�[�h
                      || lv_delimit || gt_out_file_tab(i).ball_product_code            -- �{�[�����i�R�[�h
                      || lv_delimit || gt_out_file_tab(i).prod_class                   -- ���i�敪
                      || lv_delimit || gt_out_file_tab(i).product_name                 -- ���i���i�����j
                      || lv_delimit || gt_out_file_tab(i).product_name1_alt            -- ���i���P�i�J�i�j
                      || lv_delimit || gt_out_file_tab(i).product_name2_alt            -- ���i���Q�i�J�i�j
                      || lv_delimit || gt_out_file_tab(i).item_standard1               -- �K�i�P
                      || lv_delimit || gt_out_file_tab(i).item_standard2               -- �K�i�Q
                      || lv_delimit || gt_out_file_tab(i).qty_in_case                  -- ����
                      || lv_delimit || gt_out_file_tab(i).num_of_cases                 -- �P�[�X����
                      || lv_delimit || gt_out_file_tab(i).num_of_ball                  -- �{�[������
                      || lv_delimit || gt_out_file_tab(i).item_color                   -- �F
                      || lv_delimit || gt_out_file_tab(i).item_size                    -- �T�C�Y
                      || lv_delimit || gt_out_file_tab(i).order_uom_qty                -- �����P�ʐ�
                      || lv_delimit || gt_out_file_tab(i).uom_code                     -- �P��
                      || lv_delimit || gt_out_file_tab(i).indv_order_qty               -- �������ʁi�o���j
                      || lv_delimit || gt_out_file_tab(i).case_order_qty               -- �������ʁi�P�[�X�j
                      || lv_delimit || gt_out_file_tab(i).ball_order_qty               -- �������ʁi�{�[���j
                      || lv_delimit || gt_out_file_tab(i).sum_order_qty                -- �������ʁi���v�A�o���j
                      || lv_delimit || gt_out_file_tab(i).indv_shipping_qty            -- �o�א��ʁi�o���j
                      || lv_delimit || gt_out_file_tab(i).case_shipping_qty            -- �o�א��ʁi�P�[�X�j
                      || lv_delimit || gt_out_file_tab(i).ball_shipping_qty            -- �o�א��ʁi�{�[���j
                      || lv_delimit || gt_out_file_tab(i).pallet_shipping_qty          -- �o�א��ʁi�p���b�g�j
                      || lv_delimit || gt_out_file_tab(i).sum_shipping_qty             -- �o�א��ʁi���v�A�o���j
                      || lv_delimit || gt_out_file_tab(i).indv_stockout_qty            -- ���i���ʁi�o���j
                      || lv_delimit || gt_out_file_tab(i).case_stockout_qty            -- ���i���ʁi�P�[�X�j
                      || lv_delimit || gt_out_file_tab(i).ball_stockout_qty            -- ���i���ʁi�{�[���j
                      || lv_delimit || gt_out_file_tab(i).sum_stockout_qty             -- ���i���ʁi���v�A�o���j
                      || lv_delimit || gt_out_file_tab(i).case_qty                     -- �P�[�X����
                      || lv_delimit || gt_out_file_tab(i).fold_container_indv_qty      -- �I���R���i�o���j����
                      || lv_delimit || gt_out_file_tab(i).order_unit_price             -- ���P���i�����j
                      || lv_delimit || gt_out_file_tab(i).shipping_unit_price          -- ���P���i�o�ׁj
                      || lv_delimit || gt_out_file_tab(i).order_cost_amt               -- �������z�i�����j
                      || lv_delimit || gt_out_file_tab(i).shipping_cost_amt            -- �������z�i�o�ׁj
                      || lv_delimit || gt_out_file_tab(i).stockout_cost_amt            -- �������z�i���i�j
                      || lv_delimit || gt_out_file_tab(i).selling_price                -- ���P��
                      || lv_delimit || gt_out_file_tab(i).order_price_amt              -- �������z�i�����j
                      || lv_delimit || gt_out_file_tab(i).shipping_price_amt           -- �������z�i�o�ׁj
                      || lv_delimit || gt_out_file_tab(i).stockout_price_amt           -- �������z�i���i�j
                      || lv_delimit || gt_out_file_tab(i).chain_peculiar_area_line     -- �`�F�[���X�ŗL�G���A�i���ׁj
                      || lv_delimit || gt_out_file_tab(i).edi_delivery_schedule_flag   -- EDI�[�i�\�著�M�σt���O
-- ADD DATE:2011/02/04 AUTHOR:OUKOU VER�F1.2 CONTENT:E_�{�ғ�_04871 START
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item1      -- �ėp���p�����ڂP
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item2      -- �ėp���p�����ڂQ
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item3      -- �ėp���p�����ڂR
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item4      -- �ėp���p�����ڂS
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item5      -- �ėp���p�����ڂT
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item6      -- �ėp���p�����ڂU
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item7      -- �ėp���p�����ڂV
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item8      -- �ėp���p�����ڂW
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item9      -- �ėp���p�����ڂX
                      || lv_delimit || gt_out_file_tab(i).general_succeeded_item10     -- �ėp���p�����ڂP�O
-- ADD DATE:2011/02/04 AUTHOR:OUKOU VER�F1.2 CONTENT:E_�{�ғ�_04871 END
                      ;
--
      --�󒍖��׃e�[�u���X�V�̂��߂�ROWID���i�[
      gt_oola_rowid_tab(i) := gt_out_file_tab(i).row_id;
--
      --�f�[�^���o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_line_data
      );
--
      --���������J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP data_output;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( head_cur%ISOPEN ) THEN
        CLOSE head_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_data;
--
  /**********************************************************************************
   * Procedure Name   : update_order_line_data
   * Description      : �󒍖��׏o�͍ςݍX�V�iEDI�捞�̂݁j(A-5)
   ***********************************************************************************/
  PROCEDURE update_order_line_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_order_line_data'; -- �v���O������
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
    ld_output_date         CONSTANT DATE := SYSDATE;  -- �t�@�C���o�͓���
--
    -- *** ���[�J���ϐ� ***
    lv_tkn_vl_table_name   VARCHAR2(100);             --�Ώۃe�[�u����
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
    --�󒍖��׃e�[�u���X�V����
    BEGIN
      FORALL ln_cnt IN 1..gt_oola_rowid_tab.COUNT
        UPDATE 
          oe_order_lines_all      oola
        SET
          oola.global_attribute6      = TO_CHAR( ld_output_date, cv_yyyymmddhhmiss ), -- �t�@�C���o�͓���
          oola.last_updated_by        = cn_last_updated_by,                           -- �ŏI�X�V��
          oola.last_update_date       = cd_last_update_date,                          -- �ŏI�X�V��
          oola.last_update_login      = cn_last_update_login,                         -- �ŏI�X�V���O�C��
          oola.request_id             = cn_request_id,                                -- �v��ID
          oola.program_application_id = cn_program_application_id,                    -- �R���J�����g�E�v���O�����E�A�v��ID
          oola.program_id             = cn_program_id,                                -- �R���J�����g�E�v���O����ID
          oola.program_update_date    = cd_program_update_date                        -- �v���O�����X�V��
        WHERE
          oola.rowid                  = gt_oola_rowid_tab( ln_cnt );                  -- �󒍖���ROWID
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SQLERRM;
        RAISE global_data_update_expt;
    END;
--
  EXCEPTION
    --*** �����Ώۃf�[�^�X�V��O ***
    WHEN global_data_update_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_oola
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_update_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  NULL
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||cv_msg_part||lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END update_order_line_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_order_source                 IN     VARCHAR2,  -- �󒍃\�[�X
    iv_delivery_base_code           IN     VARCHAR2,  -- �[�i���_�R�[�h
    iv_output_type                  IN     VARCHAR2,  -- �o�͋敪
    iv_chain_code                   IN     VARCHAR2,  -- �`�F�[���X�R�[�h
    iv_order_creation_date_from     IN     VARCHAR2,  -- ��M��(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,  -- ��M��(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,  -- �[�i��(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2,  -- �[�i��(TO)
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_order_creation_date_from       DATE;            -- ��M��(FROM)_�`�F�b�NOK
    ld_order_creation_date_to         DATE;            -- ��M��(TO)_�`�F�b�NOK
    ld_ordered_date_h_from            DATE;            -- �[�i��(�w�b�_)(FROM)_�`�F�b�NOK
    ld_ordered_date_h_to              DATE;            -- �[�i��(�w�b�_)(TO)_�`�F�b�NOK
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
--
    -- ===============================
    -- A-1  ���������i�v���t�@�C���擾�j
    -- ===============================
    init(
      iv_order_source,              -- �󒍃\�[�X
      iv_delivery_base_code,        -- �[�i���_�R�[�h
      iv_output_type,               -- �o�͋敪
      iv_chain_code,                -- �`�F�[���X�R�[�h
      iv_order_creation_date_from,  -- ��M��(FROM)
      iv_order_creation_date_to,    -- ��M��(TO)
      iv_ordered_date_h_from,       -- �[�i��(FROM)
      iv_ordered_date_h_to,         -- �[�i��(TO)
      lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  �p�����[�^�`�F�b�N
    -- ===============================
    check_parameter(
      iv_order_source,              -- �󒍃\�[�X
      iv_output_type,               -- �o�͋敪
      iv_order_creation_date_from,  -- ��M��(FROM)
      iv_order_creation_date_to,    -- ��M��(TO)
      iv_ordered_date_h_from,       -- �[�i��(FROM)
      iv_ordered_date_h_to,         -- �[�i��(TO)
      ld_order_creation_date_from,  -- ��M��(FROM)_�`�F�b�NOK
      ld_order_creation_date_to,    -- ��M��(TO)_�`�F�b�NOK
      ld_ordered_date_h_from,       -- �[�i��(FROM)_�`�F�b�NOK
      ld_ordered_date_h_to,         -- �[�i��(TO)_�`�F�b�NOK
      lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  �Ώۃf�[�^�擾
    -- ===============================
    get_data(
      iv_order_source,              -- �󒍃\�[�X
      iv_delivery_base_code,        -- �[�i���_�R�[�h
      iv_output_type,               -- �o�͋敪
      iv_chain_code,                -- �`�F�[���X�R�[�h
      ld_order_creation_date_from,  -- ��M��(FROM)_�`�F�b�NOK
      ld_order_creation_date_to,    -- ��M��(TO)_�`�F�b�NOK
      ld_ordered_date_h_from,       -- �[�i��(FROM)_�`�F�b�NOK
      ld_ordered_date_h_to,         -- �[�i��(TO)_�`�F�b�NOK
      lv_errbuf,                    -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,                   -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- �Ώی�����0��
    IF ( gn_target_cnt = 0 ) THEN
      RAISE global_no_data_expt;
    END IF;
--
    -- ===============================
    -- A-4  �f�[�^�o��
    -- ===============================
    output_data(
       iv_order_source                 => iv_order_source                -- �󒍃\�[�X
      ,iv_delivery_base_code           => iv_delivery_base_code          -- �[�i���_�R�[�h
      ,iv_output_type                  => iv_output_type                 -- �o�͋敪
      ,iv_chain_code                   => iv_chain_code                  -- �`�F�[���X�R�[�h
      ,iv_order_creation_date_from     => ld_order_creation_date_from    -- ��M��(FROM)
      ,iv_order_creation_date_to       => ld_order_creation_date_to      -- ��M��(TO)
      ,iv_ordered_date_h_from          => ld_ordered_date_h_from         -- �[�i��(FROM)
      ,iv_ordered_date_h_to            => ld_ordered_date_h_to           -- �[�i��(TO)
      ,ov_errbuf                       => lv_errbuf                      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode                      => lv_retcode                     -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg                       => lv_errmsg                      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-5  �󒍖��׏o�͍ςݍX�V�iEDI�捞�V�K�̂݁j
    -- ===============================
    IF ( iv_order_source = gv_order_source_edi_chk ) 
      AND ( iv_output_type = cv_output_type_new ) THEN
      update_order_line_data(
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ώ�0����O�n���h�� ***
    WHEN global_no_data_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_no_data
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf                          OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                         OUT    VARCHAR2,  -- ���^�[���E�R�[�h    --# �Œ� #
    iv_order_source                 IN     VARCHAR2,  -- �󒍃\�[�X
    iv_delivery_base_code           IN     VARCHAR2,  -- �[�i���_�R�[�h
    iv_output_type                  IN     VARCHAR2,  -- �o�͋敪
    iv_chain_code                   IN     VARCHAR2,  -- �`�F�[���X�R�[�h
    iv_order_creation_date_from     IN     VARCHAR2,  -- ��M��(FROM)
    iv_order_creation_date_to       IN     VARCHAR2,  -- ��M��(TO)
    iv_ordered_date_h_from          IN     VARCHAR2,  -- �[�i��(FROM)
    iv_ordered_date_h_to            IN     VARCHAR2   -- �[�i��(TO)
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O
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
       iv_which   => cv_log_header_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_order_source                 -- �󒍃\�[�X
      ,iv_delivery_base_code           -- �[�i���_�R�[�h
      ,iv_output_type                  -- �o�͋敪
      ,iv_chain_code                   -- �`�F�[���X�R�[�h
      ,iv_order_creation_date_from     -- ��M��(FROM)
      ,iv_order_creation_date_to       -- ��M��(TO)
      ,iv_ordered_date_h_from          -- �[�i��(FROM)
      ,iv_ordered_date_h_to            -- �[�i��(TO)
      ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
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
    --
    --�G���[�̏ꍇ�A���������N���A
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
    END IF;
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS009A07C;
/
