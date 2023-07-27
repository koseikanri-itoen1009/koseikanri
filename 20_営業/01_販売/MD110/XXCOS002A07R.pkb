CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A07R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS002A07R(body)
 * Description      : �x���_�[����E�����ƍ��\
 * MD.050           : MD050_COS_002_A07_�x���_�[����E�����ƍ��\
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  ins_get_sales_exp_data �̔����я��擾���ꎞ�\�o�^����(A-2)
 *                         �̔����я��擾�����[���[�N�e�[�u���o�^����(A-3)
 *  upd_get_payment_data   �������擾����(A-4)
 *                         ���[���[�N�e�[�u���o�^�E�X�V�����i�������j(A-5)
 *  upd_get_balance_data   �ޑK�i�c���j���擾����(A-6)
 *                         ���[���[�N�e�[�u���X�V�����i�ޑK�i�c���j���j(A-7)
 *  upd_get_check_data     �ޑK�i�x���j���擾����(A-8)
 *                         ���[���[�N�e�[�u���X�V�����i�ޑK�i�x���j���j(A-9)
 *  upd_get_return_data    �ޑK�i�߂��j���擾����(A-10)
 *                         ���[���[�N�e�[�u���X�V�����i�ޑK�i�߂��j���j(A-11)
 *  del_rep_work_no_0_data ���[���[�N�e�[�u�����폜�����i0�ȊO�j(A-12)
 *  upd_rep_work_data      ���[���[�N�e�[�u���X�V�����i�ޑK���A�������j(A-13)
 *  exe_svf                SVF�N������(A-14)
 *  del_rep_work_data      ���[���[�N�e�[�u�����폜����(A-15)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-16)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/12    1.0   K.Nakamura       �V�K�쐬
 *  2013/02/20    1.1   K.Nakamura       E_�{�ғ�_09040 T4��Q�Ή�
 *  2013/03/18    1.2   K.Nakamura       E_�{�ғ�_09040 T4��Q�Ή�
 *  2022/12/29    1.3   T.Mizutani       E_�{�ғ�_18765 SaaS�Ή�
 *  2023/04/26    1.4   T.Mizutani       E_�{�ғ�_18060 ���̋@�ڋq�ʗ��v�Ǘ� �Ή�
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
  global_lock_expt            EXCEPTION; -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCOS002A07R';            -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_application              CONSTANT VARCHAR2(5)  := 'XXCOS';                   -- �A�v���P�[�V����
  cv_appl_short_name          CONSTANT VARCHAR2(5)  := 'XXCCP';                   -- �A�h�I���F���ʁEIF�̈�
  -- SVF�p����
  cv_frm_name                 CONSTANT VARCHAR2(16) := 'XXCOS002A07S.xml';        -- �t�H�[���l����
  cv_vrq_name                 CONSTANT VARCHAR2(16) := 'XXCOS002A07S.vrq';        -- �N�G���[��
  cv_extension_pdf            CONSTANT VARCHAR2(4)  := '.pdf';                    -- �g���q(PDF)
  cv_output_mode_pdf          CONSTANT VARCHAR2(1)  := '1';                       -- �o�͋敪
  -- �v���t�@�C��
  cv_account_code_pay         CONSTANT VARCHAR2(30) := 'XXCOS1_ACCOUNT_CODE_PAY';       -- XXCOS�F����ȖڃR�[�h�i���a������������j
  cv_vd_sales_pay_chk_month   CONSTANT VARCHAR2(30) := 'XXCOS1_VD_SALES_PAY_CHK_MONTH'; -- XXCOS�F�x���_�[����E�����ƍ��\�O��J�E���^�擾�Ώی���
  cv_set_of_books_id          CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';              -- ��v����ID
  -- �Q�ƃ^�C�v
  cv_change_account           CONSTANT VARCHAR2(30) := 'XXCFO1_CHANGE_ACCOUNT';   -- XXCFO�F�ޑK����ȖڃR�[�h
  -- ���b�Z�[�W
  cv_msg_xxcos_00001          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00001';        -- �f�[�^���b�N�G���[
  cv_msg_xxcos_00004          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00004';        -- �v���t�@�C���擾�G���[
  cv_msg_xxcos_00010          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00010';        -- �f�[�^�o�^�G���[
  cv_msg_xxcos_00011          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00011';        -- �f�[�^�X�V�G���[
  cv_msg_xxcos_00012          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00012';        -- �f�[�^�폜�G���[
  cv_msg_xxcos_00014          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00014';        -- �Ɩ����t�擾�G���[
  cv_msg_xxcos_00017          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00017';        -- API�G���[���b�Z�[�W
  cv_msg_xxcos_00018          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00018';        -- ����0�����b�Z�[�W
  cv_msg_xxcos_00041          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00041';        -- SVF�N��API
  cv_msg_xxcos_14501          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14501';        -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_xxcos_14502          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14502';        -- �x���_�[����E�����ƍ��\���[���[�N�e�[�u��
  cv_msg_xxcos_14503          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14503';        -- �x���_�[����E�����ƍ��\�ꎞ�\
  -- �g�[�N���R�[�h
  cv_tkn_api_name             CONSTANT VARCHAR2(20) := 'API_NAME';                -- API��
  cv_tkn_key_data             CONSTANT VARCHAR2(20) := 'KEY_DATA';                -- �G���[���
  cv_tkn_param1               CONSTANT VARCHAR2(20) := 'PARAM1';                  -- �p�����[�^���P
  cv_tkn_param2               CONSTANT VARCHAR2(20) := 'PARAM2';                  -- �p�����[�^���Q
  cv_tkn_param3               CONSTANT VARCHAR2(20) := 'PARAM3';                  -- �p�����[�^���R
  cv_tkn_param4               CONSTANT VARCHAR2(20) := 'PARAM4';                  -- �p�����[�^���S
  cv_tkn_param5               CONSTANT VARCHAR2(20) := 'PARAM5';                  -- �p�����[�^���T
  cv_tkn_param6               CONSTANT VARCHAR2(20) := 'PARAM6';                  -- �p�����[�^���U
  cv_tkn_param7               CONSTANT VARCHAR2(20) := 'PARAM7';                  -- �p�����[�^���V
  cv_tkn_param8               CONSTANT VARCHAR2(20) := 'PARAM8';                  -- �p�����[�^���W
  cv_tkn_profile              CONSTANT VARCHAR2(20) := 'PROFILE';                 -- �v���t�@�C����
  cv_tkn_table_name           CONSTANT VARCHAR2(20) := 'TABLE_NAME';              -- �e�[�u����
  cv_tkn_table                CONSTANT VARCHAR2(20) := 'TABLE';                   -- �e�[�u����
  -- ���t�t�H�[�}�b�g
  cv_format_yyyymm1           CONSTANT VARCHAR2(7)  := 'YYYY-MM';                 -- YYYY-MM�t�H�[�}�b�g
  cv_format_yyyymm2           CONSTANT VARCHAR2(7)  := 'YYYY/MM';                 -- YYYY/MM�t�H�[�}�b�g
  cv_format_yyyymm3           CONSTANT VARCHAR2(6)  := 'YYYYMM';                  -- YYYYMM�t�H�[�}�b�g
  cv_format_yyyymmdd1         CONSTANT VARCHAR2(8)  := 'YYYYMMDD';                -- YYYYMMDD�t�H�[�}�b�g
  cv_format_yyyymmdd2         CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';              -- YYYY/MM/DD�t�H�[�}�b�g
  cv_format_yyyymmddhh24miss  CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';   -- YYYY/MM/DD HH24:MI:SS�t�H�[�}�b�g
  -- �ڋq�v�o�͋敪
  cv_cust_sum_out_div_0       CONSTANT VARCHAR2(1)  := '0';                       -- 0���܂ݑS�ďo��
  cv_cust_sum_out_div_1       CONSTANT VARCHAR2(1)  := '1';                       -- 0�ȊO�̂��̂��o��
  -- ����敪
  cv_create_class_3           CONSTANT VARCHAR2(1)  := '3';                       -- �x���_�[����
  -- �ڋq�敪
  cv_customer_class_code_1    CONSTANT VARCHAR2(1)  := '1';                       -- ���_
  cv_customer_class_code_10   CONSTANT VARCHAR2(2)  := '10';                      -- �ڋq
  -- �Ƒԏ�����
  cv_business_low_type_24     CONSTANT VARCHAR2(2)  := '24';                      -- �t��VD����
  cv_business_low_type_25     CONSTANT VARCHAR2(2)  := '25';                      -- �t��VD
  -- �d��\�[�X
  cv_je_source_gl             CONSTANT VARCHAR2(1)  := '1';                       -- GL�������
  cv_je_source_ap             CONSTANT VARCHAR2(10) := 'Payables';                -- ���|�Ǘ�
  -- �d��J�e�S��
  cv_je_categories_ap         CONSTANT VARCHAR2(20) := 'Purchase Invoices';       -- �d��������
  -- �X�e�[�^�X
  cv_result_flag              CONSTANT VARCHAR2(1)  := 'A';                       -- ����
  cv_status_p                 CONSTANT VARCHAR2(1)  := 'P';                       -- �]�L��
  cv_application_short_name1  CONSTANT VARCHAR2(5)  := 'SQLGL';                   -- GL
  cv_application_short_name2  CONSTANT VARCHAR2(2)  := 'AR';                      -- AR
  cv_adjustment_period_flag   CONSTANT VARCHAR2(1)  := 'N';                       -- �����d��Ȃ�
  -- ��񒊏o�p
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                       -- 'Y'
  cv_desc_flexfield_name      CONSTANT VARCHAR2(25) := 'HZ_ORG_PROFILES_GROUP';   -- HZ_ORG_PROFILES_GROUP
  cv_desc_flex_context_code   CONSTANT VARCHAR2(10) := 'RESOURCE';                -- RESOURCE
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE
                                                    := USERENV('LANG');
-- 2023/04/23 Ver1.4 Add Start
  cv_period_start_saas        CONSTANT VARCHAR2(7)  := '2023-07';                 -- SaaS�J�n��v����
-- 2023/04/23 Ver1.4 Add End
  -- ���O�p
  cv_proc_end                 CONSTANT VARCHAR2(3)  := 'END';
  cv_proc_cnt                 CONSTANT VARCHAR2(5)  := 'COUNT';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ����Ȗ�
  gv_msg_xxcos_14502          VARCHAR2(50)  DEFAULT NULL; -- �Œ蕶���F�x���_�[����E�����ƍ��\���[���[�N�e�[�u��
  gv_msg_xxcos_14503          VARCHAR2(50)  DEFAULT NULL; -- �Œ蕶���F�x���_�[����E�����ƍ��\�ꎞ�\
  gv_account_code_pay         VARCHAR2(5)   DEFAULT NULL; -- XXCOS�F����ȖڃR�[�h�i���a������������j
  gn_vd_sales_pay_chk_month   NUMBER        DEFAULT NULL; -- XXCOS�F�x���_�[����E�����ƍ��\�O��J�E���^�擾�Ώی���
  gn_set_of_books_id          NUMBER        DEFAULT NULL; -- ��v����ID
  gn_cnt                      NUMBER        DEFAULT 0;    -- �����i�ϐ��i�[�p�j
  gn_ins_cnt                  NUMBER        DEFAULT 0;    -- �����i�o�^����p�j
  gd_from_date                DATE          DEFAULT NULL; -- �N�����iFrom�j
  gd_to_date                  DATE          DEFAULT NULL; -- �N�����iTo�j
  gd_from_pre_counter         DATE          DEFAULT NULL; -- �O��J�E���^�N�����iFrom�j
  gd_process_date             DATE          DEFAULT NULL; -- �Ɩ����t
  --
  TYPE g_year_months_ttype     IS TABLE OF xxcos_rep_vd_sales_pay_chk.year_months%TYPE   INDEX BY BINARY_INTEGER;
  TYPE g_base_code_ttype       IS TABLE OF xxcos_rep_vd_sales_pay_chk.base_code%TYPE     INDEX BY BINARY_INTEGER;
  TYPE g_employee_code_ttype   IS TABLE OF xxcos_rep_vd_sales_pay_chk.employee_code%TYPE INDEX BY BINARY_INTEGER;
  TYPE g_dlv_by_code_ttype     IS TABLE OF xxcos_rep_vd_sales_pay_chk.dlv_by_code%TYPE   INDEX BY BINARY_INTEGER;
  TYPE g_customer_code_ttype   IS TABLE OF xxcos_rep_vd_sales_pay_chk.customer_code%TYPE INDEX BY BINARY_INTEGER;
  TYPE g_delivery_date_ttype   IS TABLE OF xxcos_rep_vd_sales_pay_chk.delivery_date%TYPE INDEX BY BINARY_INTEGER;
  TYPE g_amount_ttype          IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  g_year_months_tab           g_year_months_ttype;
  g_base_code_tab             g_base_code_ttype;
  g_employee_code_tab         g_employee_code_ttype;
  g_dlv_by_code_tab           g_dlv_by_code_ttype;
  g_customer_code_tab         g_customer_code_ttype;
  g_delivery_date_tab         g_delivery_date_ttype;
  g_amount_tab                g_amount_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_manager_flag     IN  VARCHAR2, -- �Ǘ��҃t���O
    iv_yymm_from        IN  VARCHAR2, -- �N���iFrom�j
    iv_yymm_to          IN  VARCHAR2, -- �N���iTo�j
    iv_base_code        IN  VARCHAR2, -- ���_�R�[�h
    iv_dlv_by_code      IN  VARCHAR2, -- �c�ƈ��R�[�h
    iv_cust_code        IN  VARCHAR2, -- �ڋq�R�[�h
    iv_overs_and_shorts IN  VARCHAR2, -- �����ߕs��
    iv_counter_error    IN  VARCHAR2, -- �J�E���^�덷
    ov_errbuf           OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_param_msg              VARCHAR2(5000); -- �p�����[�^�[�o�͗p
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
    -- �p�����[�^�o��
    --==============================================================
    --���b�Z�[�W�ҏW
    lv_param_msg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_application      -- �A�v���P�[�V����
                      ,iv_name          => cv_msg_xxcos_14501  -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_param1       -- �g�[�N���R�[�h�P
                      ,iv_token_value1  => iv_manager_flag     -- �Ǘ��҃t���O
                      ,iv_token_name2   => cv_tkn_param2       -- �g�[�N���R�[�h�Q
                      ,iv_token_value2  => iv_yymm_from        -- �N���iFrom�j
                      ,iv_token_name3   => cv_tkn_param3       -- �g�[�N���R�[�h�R
                      ,iv_token_value3  => iv_yymm_to          -- �N���iTo�j
                      ,iv_token_name4   => cv_tkn_param4       -- �g�[�N���R�[�h�S
                      ,iv_token_value4  => iv_base_code        -- ���_�R�[�h
                      ,iv_token_name5   => cv_tkn_param5       -- �g�[�N���R�[�h�T
                      ,iv_token_value5  => iv_dlv_by_code      -- �c�ƈ��R�[�h
                      ,iv_token_name6   => cv_tkn_param6       -- �g�[�N���R�[�h�U
                      ,iv_token_value6  => iv_cust_code        -- �ڋq�R�[�h
                      ,iv_token_name7   => cv_tkn_param7       -- �g�[�N���R�[�h�V
                      ,iv_token_value7  => iv_overs_and_shorts -- �����ߕs��
                      ,iv_token_name8   => cv_tkn_param8       -- �g�[�N���R�[�h�W
                      ,iv_token_value8  => iv_counter_error    -- �J�E���^�덷
                    );
    --���O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    --���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================
    -- �Ɩ����t�擾
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name        => cv_msg_xxcos_00014 -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- �v���t�@�C���̎擾
    --==================================
    -- XXCOS�F����ȖڃR�[�h�i���a������������j
    gv_account_code_pay := FND_PROFILE.VALUE( cv_account_code_pay );
    -- �v���t�@�C���l��NULL�̏ꍇ
    IF ( gv_account_code_pay IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application      -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcos_00004  -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_profile      -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_account_code_pay -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    BEGIN
      -- XXCOS�F�x���_�[����E�����ƍ��\�O��J�E���^�擾�Ώی���
      gn_vd_sales_pay_chk_month := TO_NUMBER( FND_PROFILE.VALUE( cv_vd_sales_pay_chk_month ) );
    EXCEPTION
      -- �v���t�@�C���l�����l�ȊO�̏ꍇ
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcos_00004
                       , iv_token_name1  => cv_tkn_profile
                       , iv_token_value1 => cv_vd_sales_pay_chk_month
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- �v���t�@�C���l��NULL�̏ꍇ
    IF ( gn_vd_sales_pay_chk_month IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcos_00004 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_profile     -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_vd_sales_pay_chk_month -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    BEGIN
      -- ��v����ID
      gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_set_of_books_id ) );
    EXCEPTION
      -- �v���t�@�C���l�����l�ȊO�̏ꍇ
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcos_00004
                       , iv_token_name1  => cv_tkn_profile
                       , iv_token_value1 => cv_set_of_books_id
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- �v���t�@�C���l��NULL�̏ꍇ
    IF ( gn_set_of_books_id IS NULL ) THEN
      -- �v���t�@�C���擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_msg_xxcos_00004 -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_profile     -- �g�[�N���R�[�h1
                     , iv_token_value1 => cv_set_of_books_id -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �N���iFrom�j�A�N���iTo�j�A�O��J�E���^�N���iFrom�j��DATE�^�ŕێ�
    gd_from_date        := TO_DATE(iv_yymm_from, cv_format_yyyymm2);
    gd_to_date          := LAST_DAY(TO_DATE(iv_yymm_to, cv_format_yyyymm2));
    gd_from_pre_counter := ADD_MONTHS(gd_from_date, (gn_vd_sales_pay_chk_month * -1));
--
    -- �Œ蕶���擾
    gv_msg_xxcos_14502 := xxccp_common_pkg.get_msg(
                              iv_application => cv_application     -- �A�v���P�[�V�����Z�k��
                            , iv_name        => cv_msg_xxcos_14502 -- �x���_�[����E�����ƍ��\���[���[�N�e�[�u��
                          );
    gv_msg_xxcos_14503 := xxccp_common_pkg.get_msg(
                              iv_application => cv_application     -- �A�v���P�[�V�����Z�k��
                            , iv_name        => cv_msg_xxcos_14503 -- �x���_�[����E�����ƍ��\�ꎞ�\
                          );
--
  EXCEPTION
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
   * Procedure Name   : ins_get_sales_exp_data
   * Description      : �̔����я��擾���ꎞ�\�o�^����(A-2)�A�̔����я��擾�����[���[�N�e�[�u���o�^����(A-3)
   ***********************************************************************************/
  PROCEDURE ins_get_sales_exp_data(
    iv_base_code                IN  VARCHAR2, -- ���_�R�[�h
    iv_dlv_by_code              IN  VARCHAR2, -- �c�ƈ��R�[�h
    iv_cust_code                IN  VARCHAR2, -- �ڋq�R�[�h
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_get_sales_exp_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
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
    -- �̔����я��擾���ꎞ�\�o�^����
    --==============================================================
    -- ���_�̂ݎw�肳��Ă���ꍇ�i�c�ƈ��A�ڋq �w��Ȃ��j
    IF  ( ( iv_dlv_by_code IS NULL ) AND ( iv_cust_code IS NULL ) ) THEN
      BEGIN
        INSERT INTO xxcos_tmp_vd_sales_pay_chk(
            sales_base_code        -- ���㋒�_�R�[�h
          , employee_code          -- �S���c�ƈ��R�[�h
          , dlv_by_code            -- �[�i�҃R�[�h
          , ship_to_customer_code  -- �ڋq�R�[�h
          , customer_name          -- �ڋq��
          , pre_counter            -- �O��J�E���^
          , delivery_date          -- �[�i��
          , standard_qty           -- �{��
          , current_counter        -- ����J�E���^
          , pure_amount            -- ����i���юҁj
          , change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
          , change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
          , created_by             -- �쐬��
          , creation_date          -- �쐬��
          , last_updated_by        -- �ŏI�X�V��
          , last_update_date       -- �ŏI�X�V��
          , last_update_login      -- �ŏI�X�V���O�C��
          , request_id             -- �v��ID
          , program_application_id -- �v���O�����A�v���P�[�V����ID
          , program_id             -- �v���O����ID
          , program_update_date    -- �v���O�����X�V��
        )
        SELECT /*+ LEADING(xseh1 hca hp hop hopeb efdfce fa xsel1)
                   USE_NL(xseh1 hca hp hop hopeb efdfce fa xsel1)
                   INDEX(xseh1 XXCOS_SALES_EXP_HEADERS_N01)
                */
               xseh1.sales_base_code                AS sales_base_code        -- ���㋒�_�R�[�h
             , hopeb.c_ext_attr1                    AS employee_code          -- �S���c�ƈ��R�[�h
             , xseh1.dlv_by_code                    AS dlv_by_code            -- �[�i�҃R�[�h
             , xseh1.ship_to_customer_code          AS ship_to_customer_code  -- �ڋq�R�[�h
             , hp.party_name                        AS customer_name          -- �ڋq��
             , NVL(
               ( SELECT TO_NUMBER(MAX(xseh3.dlv_invoice_number)) AS dlv_invoice_number
                 FROM   xxcos_sales_exp_headers                     xseh3
                 WHERE  xseh3.ship_to_customer_code = xseh1.ship_to_customer_code
                 AND    xseh3.cust_gyotai_sho       IN ( cv_business_low_type_24, cv_business_low_type_25 )
                 AND    xseh3.create_class          = cv_create_class_3
                 AND    xseh3.delivery_date         = ( SELECT MAX(xseh2.delivery_date) AS delivery_date
                                                        FROM   xxcos_sales_exp_headers     xseh2
                                                        WHERE  xseh2.ship_to_customer_code = xseh1.ship_to_customer_code
                                                        AND    xseh2.delivery_date        >= gd_from_pre_counter
                                                        AND    xseh2.delivery_date         < xseh1.delivery_date
                                                        AND    xseh2.cust_gyotai_sho       IN ( cv_business_low_type_24, cv_business_low_type_25 )
                                                        AND    xseh2.create_class          = cv_create_class_3
                                                      )
               ), 0)                                AS pre_counter            -- �O��J�E���^
             , xseh1.delivery_date                  AS delivery_date          -- ���t
             , SUM(xsel1.standard_qty)              AS standard_qty           -- �{��
             , TO_NUMBER(xseh1.dlv_invoice_number)  AS current_counter        -- ����J�E���^
-- 2013/03/18 Ver1.2 Mod Start
--             , SUM(xsel1.pure_amount)               AS pure_amount            -- ����i���юҁj
             , SUM(xsel1.sale_amount)               AS pure_amount            -- ����i���юҁj
-- 2013/03/18 Ver1.2 Mod End
             , TO_NUMBER(xseh1.change_out_time_100) AS change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
             , TO_NUMBER(xseh1.change_out_time_10)  AS change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
             , cn_created_by                        AS created_by             -- �쐬��
             , cd_creation_date                     AS creation_date          -- �쐬��
             , cn_last_updated_by                   AS last_updated_by        -- �ŏI�X�V��
             , cd_last_update_date                  AS last_update_date       -- �ŏI�X�V��
             , cn_last_update_login                 AS last_update_login      -- �ŏI�X�V���O�C��
             , cn_request_id                        AS request_id             -- �v��ID
             , cn_program_application_id            AS program_application_id -- �v���O�����A�v���P�[�V����ID
             , cn_program_id                        AS program_id             -- �v���O����ID
             , cd_program_update_date               AS program_update_date    -- �v���O�����X�V��
        FROM   xxcos_sales_exp_headers     xseh1
             , xxcos_sales_exp_lines       xsel1
             , hz_cust_accounts            hca
             , hz_parties                  hp
             , hz_organization_profiles    hop
             , hz_org_profiles_ext_b       hopeb
             , ego_fnd_dsc_flx_ctx_ext     efdfce
             , fnd_application             fa
        WHERE  xseh1.sales_exp_header_id                      = xsel1.sales_exp_header_id
        AND    xseh1.delivery_date                           >= gd_from_date
        AND    xseh1.delivery_date                           <= gd_to_date
        AND    xseh1.sales_base_code                          = iv_base_code
        AND    xseh1.cust_gyotai_sho                          IN ( cv_business_low_type_24, cv_business_low_type_25 )
        AND    xseh1.create_class                             = cv_create_class_3
        AND    xseh1.ship_to_customer_code                    = hca.account_number
        AND    hca.customer_class_code                        = cv_customer_class_code_10
        AND    hca.party_id                                   = hp.party_id
        AND    hp.party_id                                    = hop.party_id
        AND    hop.effective_end_date IS NULL
        AND    hop.organization_profile_id                    = hopeb.organization_profile_id
        AND    hopeb.attr_group_id                            = efdfce.attr_group_id
        AND    efdfce.descriptive_flexfield_name              = cv_desc_flexfield_name
        AND    efdfce.descriptive_flex_context_code           = cv_desc_flex_context_code
        AND    efdfce.application_id                          = fa.application_id
        AND    fa.application_short_name                      = cv_application_short_name2
        AND    NVL( hopeb.d_ext_attr1, xseh1.delivery_date ) <= xseh1.delivery_date
        AND    NVL( hopeb.d_ext_attr2, xseh1.delivery_date ) >= xseh1.delivery_date
        GROUP BY
               xseh1.sales_base_code
             , hopeb.c_ext_attr1
             , xseh1.dlv_by_code
             , xseh1.ship_to_customer_code
             , hp.party_name
             , xseh1.delivery_date
             , xseh1.dlv_invoice_number
             , xseh1.change_out_time_100
             , xseh1.change_out_time_10
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcos_00010 -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_msg_xxcos_14503 -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                         , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    -- �c�ƈ����w�肳��Ă���ꍇ�i�ڋq �w��Ȃ��j
    ELSIF  ( ( iv_dlv_by_code IS NOT NULL ) AND ( iv_cust_code IS NULL ) ) THEN
      BEGIN
        INSERT INTO xxcos_tmp_vd_sales_pay_chk(
            sales_base_code        -- ���㋒�_�R�[�h
          , employee_code          -- �S���c�ƈ��R�[�h
          , dlv_by_code            -- �[�i�҃R�[�h
          , ship_to_customer_code  -- �ڋq�R�[�h
          , customer_name          -- �ڋq��
          , pre_counter            -- �O��J�E���^
          , delivery_date          -- �[�i��
          , standard_qty           -- �{��
          , current_counter        -- ����J�E���^
          , pure_amount            -- ����i���юҁj
          , change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
          , change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
          , created_by             -- �쐬��
          , creation_date          -- �쐬��
          , last_updated_by        -- �ŏI�X�V��
          , last_update_date       -- �ŏI�X�V��
          , last_update_login      -- �ŏI�X�V���O�C��
          , request_id             -- �v��ID
          , program_application_id -- �v���O�����A�v���P�[�V����ID
          , program_id             -- �v���O����ID
          , program_update_date    -- �v���O�����X�V��
        )
        SELECT /*+ LEADING(xseh1 hca hp hop hopeb efdfce fa xsel1)
                   USE_NL(xseh1 hca hp hop hopeb efdfce fa xsel1)
                   INDEX(xseh1 XXCOS_SALES_EXP_HEADERS_N01)
                */
               xseh1.sales_base_code                AS sales_base_code        -- ���_�R�[�h
             , hopeb.c_ext_attr1                    AS employee_code          -- �S���c�ƈ��R�[�h
             , xseh1.dlv_by_code                    AS dlv_by_code            -- �[�i�҃R�[�h
             , xseh1.ship_to_customer_code          AS ship_to_customer_code  -- �ڋq�R�[�h
             , hp.party_name                        AS customer_name          -- �ڋq��
             , NVL(
               ( SELECT TO_NUMBER(MAX(xseh3.dlv_invoice_number)) AS dlv_invoice_number
                 FROM   xxcos_sales_exp_headers                     xseh3
                 WHERE  xseh3.ship_to_customer_code = xseh1.ship_to_customer_code
                 AND    xseh3.cust_gyotai_sho       IN ( cv_business_low_type_24, cv_business_low_type_25 )
                 AND    xseh3.create_class          = cv_create_class_3
                 AND    xseh3.delivery_date         = ( SELECT MAX(xseh2.delivery_date) AS delivery_date
                                                        FROM   xxcos_sales_exp_headers     xseh2
                                                        WHERE  xseh2.ship_to_customer_code = xseh1.ship_to_customer_code
                                                        AND    xseh2.delivery_date        >= gd_from_pre_counter
                                                        AND    xseh2.delivery_date         < xseh1.delivery_date
                                                        AND    xseh2.cust_gyotai_sho       IN ( cv_business_low_type_24, cv_business_low_type_25 )
                                                        AND    xseh2.create_class          = cv_create_class_3
                                                      )
               ), 0)                                AS pre_counter            -- �O��J�E���^
             , xseh1.delivery_date                  AS delivery_date          -- ���t
             , SUM(xsel1.standard_qty)              AS standard_qty           -- �{��
             , TO_NUMBER(xseh1.dlv_invoice_number)  AS current_counter        -- ����J�E���^
-- 2013/03/18 Ver1.2 Mod Start
--             , SUM(xsel1.pure_amount)               AS pure_amount            -- ����i���юҁj
             , SUM(xsel1.sale_amount)               AS pure_amount            -- ����i���юҁj
-- 2013/03/18 Ver1.2 Mod End
             , TO_NUMBER(xseh1.change_out_time_100) AS change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
             , TO_NUMBER(xseh1.change_out_time_10)  AS change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
             , cn_created_by                        AS created_by             -- �쐬��
             , cd_creation_date                     AS creation_date          -- �쐬��
             , cn_last_updated_by                   AS last_updated_by        -- �ŏI�X�V��
             , cd_last_update_date                  AS last_update_date       -- �ŏI�X�V��
             , cn_last_update_login                 AS last_update_login      -- �ŏI�X�V���O�C��
             , cn_request_id                        AS request_id             -- �v��ID
             , cn_program_application_id            AS program_application_id -- �v���O�����A�v���P�[�V����ID
             , cn_program_id                        AS program_id             -- �v���O����ID
             , cd_program_update_date               AS program_update_date    -- �v���O�����X�V��
        FROM   xxcos_sales_exp_headers     xseh1
             , xxcos_sales_exp_lines       xsel1
             , hz_cust_accounts            hca
             , hz_parties                  hp
             , hz_organization_profiles    hop
             , hz_org_profiles_ext_b       hopeb
             , ego_fnd_dsc_flx_ctx_ext     efdfce
             , fnd_application             fa
        WHERE  xseh1.sales_exp_header_id                      = xsel1.sales_exp_header_id
        AND    xseh1.delivery_date                           >= gd_from_date
        AND    xseh1.delivery_date                           <= gd_to_date
        AND    xseh1.sales_base_code                          = iv_base_code
        AND    xseh1.cust_gyotai_sho                          IN ( cv_business_low_type_24, cv_business_low_type_25 )
        AND    xseh1.create_class                             = cv_create_class_3
        AND    xseh1.ship_to_customer_code                    = hca.account_number
        AND    hca.customer_class_code                        = cv_customer_class_code_10
        AND    hca.party_id                                   = hp.party_id
        AND    hp.party_id                                    = hop.party_id
        AND    hop.effective_end_date IS NULL
        AND    hop.organization_profile_id                    = hopeb.organization_profile_id
        AND    hopeb.attr_group_id                            = efdfce.attr_group_id
        AND    hopeb.c_ext_attr1                              = iv_dlv_by_code
        AND    efdfce.descriptive_flexfield_name              = cv_desc_flexfield_name
        AND    efdfce.descriptive_flex_context_code           = cv_desc_flex_context_code
        AND    efdfce.application_id                          = fa.application_id
        AND    fa.application_short_name                      = cv_application_short_name2
        AND    NVL( hopeb.d_ext_attr1, xseh1.delivery_date ) <= xseh1.delivery_date
        AND    NVL( hopeb.d_ext_attr2, xseh1.delivery_date ) >= xseh1.delivery_date
        GROUP BY
               xseh1.sales_base_code
             , hopeb.c_ext_attr1
             , xseh1.dlv_by_code
             , xseh1.ship_to_customer_code
             , hp.party_name
             , xseh1.delivery_date
             , xseh1.dlv_invoice_number
             , xseh1.change_out_time_100
             , xseh1.change_out_time_10
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcos_00010 -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_msg_xxcos_14503 -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                         , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    -- �ڋq���w�肳��Ă���ꍇ�i�c�ƈ� �w�肠��A�w��Ȃ��̂ǂ���ł��悢�j
    ELSIF ( iv_cust_code IS NOT NULL ) THEN
      BEGIN
        INSERT INTO xxcos_tmp_vd_sales_pay_chk(
            sales_base_code        -- ���㋒�_�R�[�h
          , employee_code          -- �S���c�ƈ��R�[�h
          , dlv_by_code            -- �[�i�҃R�[�h
          , ship_to_customer_code  -- �ڋq�R�[�h
          , customer_name          -- �ڋq��
          , pre_counter            -- �O��J�E���^
          , delivery_date          -- �[�i��
          , standard_qty           -- �{��
          , current_counter        -- ����J�E���^
          , pure_amount            -- ����i���юҁj
          , change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
          , change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
          , created_by             -- �쐬��
          , creation_date          -- �쐬��
          , last_updated_by        -- �ŏI�X�V��
          , last_update_date       -- �ŏI�X�V��
          , last_update_login      -- �ŏI�X�V���O�C��
          , request_id             -- �v��ID
          , program_application_id -- �v���O�����A�v���P�[�V����ID
          , program_id             -- �v���O����ID
          , program_update_date    -- �v���O�����X�V��
        )
        SELECT /*+ LEADING(xseh1 hca hp hop hopeb efdfce fa xsel1)
                   USE_NL(xseh1 hca hp hop hopeb efdfce fa xsel1)
                   INDEX(xseh1 XXCOS_SALES_EXP_HEADERS_N08)
                */
               xseh1.sales_base_code                AS sales_base_code        -- ���_�R�[�h
             , hopeb.c_ext_attr1                    AS employee_code          -- �S���c�ƈ��R�[�h
             , xseh1.dlv_by_code                    AS dlv_by_code            -- �[�i�҃R�[�h
             , xseh1.ship_to_customer_code          AS ship_to_customer_code  -- �ڋq�R�[�h
             , hp.party_name                        AS customer_name          -- �ڋq��
             , NVL(
               ( SELECT TO_NUMBER(MAX(xseh3.dlv_invoice_number)) AS dlv_invoice_number
                 FROM   xxcos_sales_exp_headers                     xseh3
                 WHERE  xseh3.ship_to_customer_code = xseh1.ship_to_customer_code
                 AND    xseh3.cust_gyotai_sho       IN ( cv_business_low_type_24, cv_business_low_type_25 )
                 AND    xseh3.create_class          = cv_create_class_3
                 AND    xseh3.delivery_date         = ( SELECT MAX(xseh2.delivery_date) AS delivery_date
                                                        FROM   xxcos_sales_exp_headers     xseh2
                                                        WHERE  xseh2.ship_to_customer_code = xseh1.ship_to_customer_code
                                                        AND    xseh2.delivery_date        >= gd_from_pre_counter
                                                        AND    xseh2.delivery_date         < xseh1.delivery_date
                                                        AND    xseh2.cust_gyotai_sho       IN ( cv_business_low_type_24, cv_business_low_type_25 )
                                                        AND    xseh2.create_class          = cv_create_class_3
                                                      )
               ), 0)                                AS pre_counter            -- �O��J�E���^
             , xseh1.delivery_date                  AS delivery_date          -- ���t
             , SUM(xsel1.standard_qty)              AS standard_qty           -- �{��
             , TO_NUMBER(xseh1.dlv_invoice_number)  AS current_counter        -- ����J�E���^
-- 2013/03/18 Ver1.2 Mod Start
--             , SUM(xsel1.pure_amount)               AS pure_amount            -- ����i���юҁj
             , SUM(xsel1.sale_amount)               AS pure_amount            -- ����i���юҁj
-- 2013/03/18 Ver1.2 Mod End
             , TO_NUMBER(xseh1.change_out_time_100) AS change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
             , TO_NUMBER(xseh1.change_out_time_10)  AS change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
             , cn_created_by                        AS created_by             -- �쐬��
             , cd_creation_date                     AS creation_date          -- �쐬��
             , cn_last_updated_by                   AS last_updated_by        -- �ŏI�X�V��
             , cd_last_update_date                  AS last_update_date       -- �ŏI�X�V��
             , cn_last_update_login                 AS last_update_login      -- �ŏI�X�V���O�C��
             , cn_request_id                        AS request_id             -- �v��ID
             , cn_program_application_id            AS program_application_id -- �v���O�����A�v���P�[�V����ID
             , cn_program_id                        AS program_id             -- �v���O����ID
             , cd_program_update_date               AS program_update_date    -- �v���O�����X�V��
        FROM   xxcos_sales_exp_headers     xseh1
             , xxcos_sales_exp_lines       xsel1
             , hz_cust_accounts            hca
             , hz_parties                  hp
             , hz_organization_profiles    hop
             , hz_org_profiles_ext_b       hopeb
             , ego_fnd_dsc_flx_ctx_ext     efdfce
             , fnd_application             fa
        WHERE  xseh1.sales_exp_header_id                      = xsel1.sales_exp_header_id
        AND    xseh1.delivery_date                           >= gd_from_date
        AND    xseh1.delivery_date                           <= gd_to_date
        AND    xseh1.sales_base_code                          = iv_base_code
        AND    xseh1.ship_to_customer_code                    = iv_cust_code
        AND    xseh1.cust_gyotai_sho                          IN ( cv_business_low_type_24, cv_business_low_type_25 )
        AND    xseh1.create_class                             = cv_create_class_3
        AND    xseh1.ship_to_customer_code                    = hca.account_number
        AND    hca.customer_class_code                        = cv_customer_class_code_10
        AND    hca.party_id                                   = hp.party_id
        AND    hp.party_id                                    = hop.party_id
        AND    hop.effective_end_date IS NULL
        AND    hop.organization_profile_id                    = hopeb.organization_profile_id
        AND    hopeb.attr_group_id                            = efdfce.attr_group_id
        AND    hopeb.c_ext_attr1                              = NVL(iv_dlv_by_code, hopeb.c_ext_attr1)
        AND    efdfce.descriptive_flexfield_name              = cv_desc_flexfield_name
        AND    efdfce.descriptive_flex_context_code           = cv_desc_flex_context_code
        AND    efdfce.application_id                          = fa.application_id
        AND    fa.application_short_name                      = cv_application_short_name2
        AND    NVL( hopeb.d_ext_attr1, xseh1.delivery_date ) <= xseh1.delivery_date
        AND    NVL( hopeb.d_ext_attr2, xseh1.delivery_date ) >= xseh1.delivery_date
        GROUP BY
               xseh1.sales_base_code
             , hopeb.c_ext_attr1
             , xseh1.dlv_by_code
             , xseh1.ship_to_customer_code
             , hp.party_name
             , xseh1.delivery_date
             , xseh1.dlv_invoice_number
             , xseh1.change_out_time_100
             , xseh1.change_out_time_10
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcos_00010 -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_msg_xxcos_14503 -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                         , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
    END IF;
    --
    -- �o�^�����m�F
    gn_ins_cnt := SQL%ROWCOUNT;
--
    -- �����I�����������O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || '1' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_ins_cnt
    );
    -- ���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- �o�^�����ꍇ
    IF ( gn_ins_cnt > 0 ) THEN
      --==============================================================
      -- �̔����я��擾�����[���[�N�e�[�u���o�^����(A-3)
      --==============================================================
      BEGIN
        INSERT INTO xxcos_rep_vd_sales_pay_chk(
            year_months            -- �N��
          , base_code              -- ���_�R�[�h
          , base_name              -- ���_��
          , employee_code          -- �S���c�ƈ��R�[�h
          , employee_name          -- �S���c�ƈ���
          , dlv_by_code            -- �[�i�҃R�[�h
          , dlv_by_code_disp       -- �[�i�҃R�[�h�i�\���p�j
          , dlv_by_name            -- �[�i�Җ�
          , dlv_by_name_disp       -- �[�i�Җ��i�\���p�j
          , customer_code          -- �ڋq�R�[�h
          , customer_name          -- �ڋq��
          , pre_counter            -- �O��J�E���^
          , delivery_date          -- ���t
          , standard_qty           -- �{��
          , current_counter        -- ����J�E���^
          , error                  -- �덷
          , sales_amount           -- ����i���юҁj
          , payment_amount         -- �����i���юҁj
          , overs_and_shorts       -- �ߕs���i����[�����j
          , change_balance         -- �ޑK�i�c���j
          , change_pay             -- �ޑK�i�x���j
          , change_return          -- �ޑK�i�߂��j
          , change                 -- �ޑK
          , change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
          , change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
          , created_by             -- �쐬��
          , creation_date          -- �쐬��
          , last_updated_by        -- �ŏI�X�V��
          , last_update_date       -- �ŏI�X�V��
          , last_update_login      -- �ŏI�X�V���O�C��
          , request_id             -- �v��ID
          , program_application_id -- �v���O�����A�v���P�[�V����ID
          , program_id             -- �v���O����ID
          , program_update_date    -- �v���O�����X�V��
        )
        SELECT /*+ USE_NL(xtvspc hca hp papf1 papf2)
                */
               TO_CHAR(xtvspc.delivery_date, cv_format_yyyymm3)   AS year_months            -- �N��
             , xtvspc.sales_base_code                             AS base_code              -- ���_�R�[�h
             , hp.party_name                                      AS base_name              -- ���_��
             , xtvspc.employee_code                               AS employee_code          -- �S���c�ƈ��R�[�h
             , papf1.full_name                                    AS employee_name          -- �S���c�ƈ���
             , xtvspc.dlv_by_code                                 AS dlv_by_code            -- �[�i�҃R�[�h
             , xtvspc.dlv_by_code                                 AS dlv_by_code_disp       -- �[�i�҃R�[�h�i�\���p�j
             , papf2.full_name                                    AS dlv_by_name            -- �[�i�Җ�
             , papf2.full_name                                    AS dlv_by_name_disp       -- �[�i�Җ��i�\���p�j
             , xtvspc.ship_to_customer_code                       AS customer_code          -- �ڋq�R�[�h
             , xtvspc.customer_name                               AS customer_name          -- �ڋq��
             , xtvspc.pre_counter                                 AS pre_counter            -- �O��J�E���^
             , TO_CHAR(xtvspc.delivery_date, cv_format_yyyymmdd2) AS delivery_date          -- ���t
             , SUM(xtvspc.standard_qty)                           AS standard_qty           -- �{��
             , MAX(xtvspc.current_counter)                        AS current_counter        -- ����J�E���^
             , ( MAX(xtvspc.current_counter)
               - xtvspc.pre_counter
               - SUM(xtvspc.standard_qty) )                       AS error                  -- �덷
             , SUM(xtvspc.pure_amount)                            AS sales_amount           -- ����i���юҁj
             , 0                                                  AS payment_amount         -- �����i���юҁj
             , 0                                                  AS overs_and_shorts       -- �ߕs���i����[�����j
             , 0                                                  AS change_balance         -- �ޑK�i�c���j
             , 0                                                  AS change_pay             -- �ޑK�i�x���j
             , 0                                                  AS change_return          -- �ޑK�i�߂��j
             , 0                                                  AS change                 -- �ޑK
             , SUM(xtvspc.change_out_time_100)                    AS change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
             , SUM(xtvspc.change_out_time_10)                     AS change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
             , cn_created_by                                      AS created_by             -- �쐬��
             , cd_creation_date                                   AS creation_date          -- �쐬��
             , cn_last_updated_by                                 AS last_updated_by        -- �ŏI�X�V��
             , cd_last_update_date                                AS last_update_date       -- �ŏI�X�V��
             , cn_last_update_login                               AS last_update_login      -- �ŏI�X�V���O�C��
             , cn_request_id                                      AS request_id             -- �v��ID
             , cn_program_application_id                          AS program_application_id -- �v���O�����A�v���P�[�V����ID
             , cn_program_id                                      AS program_id             -- �v���O����ID
             , cd_program_update_date                             AS program_update_date    -- �v���O�����X�V��
        FROM   xxcos_tmp_vd_sales_pay_chk  xtvspc
             , hz_cust_accounts            hca
             , hz_parties                  hp
             , per_all_people_f            papf1
             , per_all_people_f            papf2
        WHERE  xtvspc.sales_base_code  = hca.account_number
        AND    hca.party_id            = hp.party_id
        AND    hca.customer_class_code = cv_customer_class_code_1
        AND    xtvspc.employee_code    = papf1.employee_number
        AND    xtvspc.delivery_date   >= papf1.effective_start_date
        AND    xtvspc.delivery_date   <= papf1.effective_end_date
        AND    xtvspc.dlv_by_code      = papf2.employee_number
        AND    xtvspc.delivery_date   >= papf2.effective_start_date
        AND    xtvspc.delivery_date   <= papf2.effective_end_date
        GROUP BY
               xtvspc.sales_base_code
             , hp.party_name
             , xtvspc.employee_code
             , papf1.full_name
             , xtvspc.dlv_by_code
             , papf2.full_name
             , xtvspc.ship_to_customer_code
             , xtvspc.customer_name
             , xtvspc.pre_counter
             , xtvspc.delivery_date
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcos_00010 -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                         , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- �����I�����������O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_prg_name || ' ' || cv_proc_end || '2' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                               || ' ' || cv_proc_cnt || cv_msg_part || SQL%ROWCOUNT
      );
      -- ���O��s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
--
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
  END ins_get_sales_exp_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_get_payment_data
   * Description      : �������擾����(A-4)�A���[���[�N�e�[�u���o�^�E�X�V�����i�������j(A-5)
   ***********************************************************************************/
  PROCEDURE upd_get_payment_data(
    iv_base_code                IN  VARCHAR2, -- ���_�R�[�h
-- 2013/03/18 Ver1.2 Add Start
    iv_dlv_by_code              IN  VARCHAR2, -- �c�ƈ��R�[�h
    iv_cust_code                IN  VARCHAR2, -- �ڋq�R�[�h
-- 2013/03/18 Ver1.2 Add End
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_get_payment_data'; -- �v���O������
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
-- 2013/02/20 Ver1.1 Add Start
    -- *** ���[�J���ϐ� ***
    lt_dlv_by_code            xxcos_rep_vd_sales_pay_chk.dlv_by_code%TYPE DEFAULT NULL; -- �[�i�҃R�[�h
-- 2013/02/20 Ver1.1 Add End
    -- *** ���[�J���J�[�\�� ***
    -- �������擾�J�[�\���i���_�̂ݎw�肳��Ă���ꍇ�i�c�ƈ��A�ڋq �w��Ȃ��j�j
    CURSOR get_payment_cur
    IS
-- 2013/02/20 Ver1.1 Mod Start
--      SELECT /*+ LEADING(gcc gjl xrvspc gjh)
      SELECT /*+ LEADING(gcc gjl gjh)
-- 2013/02/20 Ver1.1 Mod End
                 USE_NL(gcc gjl gjh)
              */
             TO_CHAR(TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months    -- �N��
           , gcc.segment2                                                                           AS segment2       -- ����
           , gjl.jgzz_recon_ref                                                                     AS jgzz_recon_ref -- �����Q�Ɓi�ڋq�j
-- 2013/02/20 Ver1.1 Add Start
           , gjh.default_effective_date                                                             AS default_effective_date -- GL�L����
-- 2013/02/20 Ver1.1 Add End
           , SUM(NVL(gjl.accounted_dr,0) - NVL(gjl.accounted_cr,0))                                 AS payment_amount -- ��������
      FROM   gl_je_headers              gjh
           , gl_je_lines                gjl
           , gl_code_combinations       gcc
      WHERE  gjh.je_header_id                                            = gjl.je_header_id
      AND    gjl.code_combination_id                                     = gcc.code_combination_id
      AND    gcc.segment2                                                = iv_base_code
      AND    gcc.segment3                                                = gv_account_code_pay
      AND    gjl.jgzz_recon_ref IS NOT NULL
      AND    gjl.status                                                  = cv_status_p
      AND    gjh.actual_flag                                             = cv_result_flag
      AND    gjh.je_source                                               = cv_je_source_gl
      AND    gjh.set_of_books_id                                         = gn_set_of_books_id
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
-- 2013/02/20 Ver1.1 Del Start
--      AND EXISTS (
--                   SELECT 1
--                   FROM   xxcos_rep_vd_sales_pay_chk xrvspc
--                   WHERE  xrvspc.customer_code = gjl.jgzz_recon_ref
--                   AND    xrvspc.request_id    = cn_request_id
--                 )
-- 2013/02/20 Ver1.1 Del End
      GROUP BY
             gjh.period_name
           , gcc.segment2
           , gjl.jgzz_recon_ref
-- 2013/02/20 Ver1.1 Add Start
           , gjh.default_effective_date
-- 2013/02/20 Ver1.1 Add End
    ;
-- 2013/03/18 Ver1.2 Add Start
    -- �������擾�J�[�\���i���_�݂̂̎w��ȊO�j
    CURSOR get_payment_cur2
    IS
      SELECT /*+ LEADING(gcc gjl gjh hca hp hop hopeb efdfce fa)
                 USE_NL(gcc gjl gjh hca hp hop hopeb efdfce fa)
              */
             TO_CHAR(TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months    -- �N��
           , gcc.segment2                                                                           AS segment2       -- ����
           , gjl.jgzz_recon_ref                                                                     AS jgzz_recon_ref -- �����Q�Ɓi�ڋq�j
           , gjh.default_effective_date                                                             AS default_effective_date -- GL�L����
           , SUM(NVL(gjl.accounted_dr,0) - NVL(gjl.accounted_cr,0))                                 AS payment_amount -- ��������
      FROM   gl_je_headers              gjh
           , gl_je_lines                gjl
           , gl_code_combinations       gcc
           , hz_cust_accounts           hca
           , hz_parties                 hp
           , hz_organization_profiles   hop
           , hz_org_profiles_ext_b      hopeb
           , ego_fnd_dsc_flx_ctx_ext    efdfce
           , fnd_application            fa
      WHERE  gjh.je_header_id                                            = gjl.je_header_id
      AND    gjl.code_combination_id                                     = gcc.code_combination_id
      AND    gcc.segment2                                                = iv_base_code
      AND    gcc.segment3                                                = gv_account_code_pay
      AND    gjl.jgzz_recon_ref                                          = NVL( iv_cust_code, gjl.jgzz_recon_ref )
      AND    gjl.status                                                  = cv_status_p
      AND    gjh.actual_flag                                             = cv_result_flag
      AND    gjh.je_source                                               = cv_je_source_gl
      AND    gjh.set_of_books_id                                         = gn_set_of_books_id
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
      AND    gjl.jgzz_recon_ref                                          = hca.account_number
      AND    hca.customer_class_code                                     = cv_customer_class_code_10
      AND    hca.party_id                                                = hp.party_id
      AND    hp.party_id                                                 = hop.party_id
      AND    hop.effective_end_date IS NULL
      AND    hop.organization_profile_id                                 = hopeb.organization_profile_id
      AND    hopeb.attr_group_id                                         = efdfce.attr_group_id
      AND    hopeb.c_ext_attr1                                           = NVL( iv_dlv_by_code, hopeb.c_ext_attr1 )
      AND    efdfce.descriptive_flexfield_name                           = cv_desc_flexfield_name
      AND    efdfce.descriptive_flex_context_code                        = cv_desc_flex_context_code
      AND    efdfce.application_id                                       = fa.application_id
      AND    fa.application_short_name                                   = cv_application_short_name2
      AND    NVL( hopeb.d_ext_attr1, gjh.default_effective_date )       <= gjh.default_effective_date
      AND    NVL( hopeb.d_ext_attr2, gjh.default_effective_date )       >= gjh.default_effective_date
      GROUP BY
             gjh.period_name
           , gcc.segment2
           , gjl.jgzz_recon_ref
           , gjh.default_effective_date
    ;
-- 2013/03/18 Ver1.2 Add End
    --
    get_payment_rec           get_payment_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    gn_cnt := 0;
-- 2013/02/20 Ver1.1 Del Start
--    g_year_months_tab.DELETE;
--    g_base_code_tab.DELETE;
--    g_customer_code_tab.DELETE;
--    g_amount_tab.DELETE;
-- 2013/02/20 Ver1.1 Del End
    --
-- 2013/03/18 Ver1.2 Add Start
    -- ���_�̂ݎw�肳��Ă���ꍇ
    IF  ( ( iv_dlv_by_code IS NULL ) AND ( iv_cust_code IS NULL ) ) THEN
-- 2013/03/18 Ver1.2 Add End
      --==============================================================
      -- ������񏈗�����
      --==============================================================
      -- �J�[�\���I�[�v��
      OPEN get_payment_cur;
      --
      <<payment_loop>>
      LOOP
      FETCH get_payment_cur INTO get_payment_rec;
        --
        -- �Ώۃf�[�^�����̓��[�v�𔲂���
        EXIT WHEN get_payment_cur%NOTFOUND;
        --
        -- ���O�p����
        gn_cnt                      := gn_cnt + 1;
-- 2013/02/20 Ver1.1 Mod Start
--      g_year_months_tab(gn_cnt)   := get_payment_rec.year_months;
--      g_base_code_tab(gn_cnt)     := get_payment_rec.segment2;
--      g_customer_code_tab(gn_cnt) := get_payment_rec.jgzz_recon_ref;
--      g_amount_tab(gn_cnt)        := get_payment_rec.payment_amount;
--      --
--    END LOOP payment_loop;
--    --
--    -- �J�[�\���N���[�Y
--    CLOSE get_payment_cur;
--
--    --==============================================================
--    -- ���[���[�N�e�[�u���o�^�E�X�V�����i�������j
--    --==============================================================
--    BEGIN
--      FORALL i IN g_year_months_tab.FIRST .. g_year_months_tab.COUNT
--        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
--        SET    xrvspc.overs_and_shorts = g_amount_tab(i) -- �ߕs���i����[�����j
--        WHERE  xrvspc.year_months      = g_year_months_tab(i)
--        AND    xrvspc.base_code        = g_base_code_tab(i)
--        AND    xrvspc.customer_code    = g_customer_code_tab(i)
--        AND    xrvspc.request_id       = cn_request_id
--        ;
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
--                       , iv_name         => cv_msg_xxcos_00011 -- ���b�Z�[�W�R�[�h
--                       , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
--                       , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
--                       , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
--                       , iv_token_value2 => SQLERRM            -- �g�[�N���l2
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--    END;
--
        -- ������
        lt_dlv_by_code := NULL;
        --
        --==============================================================
        -- �o�^�E�X�V�m�F
        --==============================================================
        BEGIN
          SELECT MAX(xrvspc.dlv_by_code)    AS dlv_by_code
          INTO   lt_dlv_by_code
          FROM   xxcos_rep_vd_sales_pay_chk xrvspc
          WHERE  xrvspc.year_months   = get_payment_rec.year_months
          AND    xrvspc.base_code     = get_payment_rec.segment2
          AND    xrvspc.customer_code = get_payment_rec.jgzz_recon_ref
          AND    xrvspc.delivery_date = TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2)
          AND    xrvspc.request_id    = cn_request_id
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lt_dlv_by_code := NULL;
        END;
--
        -- �Ώۖ����͓o�^
        IF ( lt_dlv_by_code IS NULL ) THEN
          --==============================================================
          -- �o�^�Ώۊm�F�i���[���[�N�e�[�u���ɑΏۂ̌ڋq�����݂��邩�j
          --==============================================================
          BEGIN
            SELECT MAX(xrvspc.dlv_by_code)    AS dlv_by_code
            INTO   lt_dlv_by_code
            FROM   xxcos_rep_vd_sales_pay_chk xrvspc
            WHERE  xrvspc.year_months   = get_payment_rec.year_months
            AND    xrvspc.base_code     = get_payment_rec.segment2
            AND    xrvspc.customer_code = get_payment_rec.jgzz_recon_ref
            AND    xrvspc.request_id    = cn_request_id
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_dlv_by_code := NULL;
          END;
          --
          -- ���݂��Ȃ��ꍇ�A�ڋq����S���c�ƈ����擾���ēo�^
          IF ( lt_dlv_by_code IS NULL ) THEN
            --==============================================================
            -- ���[���[�N�e�[�u���o�^�����i�������j�ڋq�Ȃ�
            --==============================================================
            BEGIN
              INSERT INTO xxcos_rep_vd_sales_pay_chk(
                  year_months            -- �N��
                , base_code              -- ���_�R�[�h
                , base_name              -- ���_��
                , employee_code          -- �S���c�ƈ��R�[�h
                , employee_name          -- �S���c�ƈ���
                , dlv_by_code            -- �[�i�҃R�[�h
                , dlv_by_code_disp       -- �[�i�҃R�[�h�i�\���p�j
                , dlv_by_name            -- �[�i�Җ�
                , dlv_by_name_disp       -- �[�i�Җ��i�\���p�j
                , customer_code          -- �ڋq�R�[�h
                , customer_name          -- �ڋq��
                , pre_counter            -- �O��J�E���^
                , delivery_date          -- ���t
                , standard_qty           -- �{��
                , current_counter        -- ����J�E���^
                , error                  -- �덷
                , sales_amount           -- ����i���юҁj
                , payment_amount         -- �����i���юҁj
                , overs_and_shorts       -- �ߕs���i����[�����j
                , change_balance         -- �ޑK�i�c���j
                , change_pay             -- �ޑK�i�x���j
                , change_return          -- �ޑK�i�߂��j
                , change                 -- �ޑK
                , change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
                , change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
                , created_by             -- �쐬��
                , creation_date          -- �쐬��
                , last_updated_by        -- �ŏI�X�V��
                , last_update_date       -- �ŏI�X�V��
                , last_update_login      -- �ŏI�X�V���O�C��
                , request_id             -- �v��ID
                , program_application_id -- �v���O�����A�v���P�[�V����ID
                , program_id             -- �v���O����ID
                , program_update_date    -- �v���O�����X�V��
              )
              SELECT /*+ LEADING(hca1 hp1 hop hopeb efdfce fa papf)
                         USE_NL(hca1 hp1 hop hopeb efdfce fa papf)
                      */
                     get_payment_rec.year_months                                          AS year_months            -- �N��
                   , get_payment_rec.segment2                                             AS base_code              -- ���_�R�[�h
                   , ( SELECT hp2.party_name   AS party_name
                       FROM   hz_cust_accounts hca2
                            , hz_parties       hp2
                       WHERE  hca2.party_id            = hp2.party_id
                       AND    hca2.customer_class_code = cv_customer_class_code_1
                       AND    hca2.account_number      = get_payment_rec.segment2 )       AS base_name              -- ���_��
                   , hopeb.c_ext_attr1                                                    AS employee_code          -- �S���c�ƈ��R�[�h
                   , papf.full_name                                                       AS employee_name          -- �S���c�ƈ���
                   , NULL                                                                 AS dlv_by_code            -- �[�i�҃R�[�h
                   , NULL                                                                 AS dlv_by_code_disp       -- �[�i�҃R�[�h�i�\���p�j
                   , NULL                                                                 AS dlv_by_name            -- �[�i�Җ�
                   , NULL                                                                 AS dlv_by_name_disp       -- �[�i�Җ��i�\���p�j
                   , get_payment_rec.jgzz_recon_ref                                       AS customer_code          -- �ڋq�R�[�h
                   , hp1.party_name                                                       AS customer_name          -- �ڋq��
                   , NULL                                                                 AS pre_counter            -- �O��J�E���^
                   , TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2) AS delivery_date          -- ���t
                   , NULL                                                                 AS standard_qty           -- �{��
                   , NULL                                                                 AS current_counter        -- ����J�E���^
                   , NULL                                                                 AS error                  -- �덷
                   , NULL                                                                 AS sales_amount           -- ����i���юҁj
                   , NULL                                                                 AS payment_amount         -- �����i���юҁj
                   , get_payment_rec.payment_amount                                       AS overs_and_shorts       -- �ߕs���i����[�����j
                   , NULL                                                                 AS change_balance         -- �ޑK�i�c���j
                   , NULL                                                                 AS change_pay             -- �ޑK�i�x���j
                   , NULL                                                                 AS change_return          -- �ޑK�i�߂��j
                   , NULL                                                                 AS change                 -- �ޑK
                   , NULL                                                                 AS change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
                   , NULL                                                                 AS change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
                   , cn_created_by                                                        AS created_by             -- �쐬��
                   , cd_creation_date                                                     AS creation_date          -- �쐬��
                   , cn_last_updated_by                                                   AS last_updated_by        -- �ŏI�X�V��
                   , cd_last_update_date                                                  AS last_update_date       -- �ŏI�X�V��
                   , cn_last_update_login                                                 AS last_update_login      -- �ŏI�X�V���O�C��
                   , cn_request_id                                                        AS request_id             -- �v��ID
                   , cn_program_application_id                                            AS program_application_id -- �v���O�����A�v���P�[�V����ID
                   , cn_program_id                                                        AS program_id             -- �v���O����ID
                   , cd_program_update_date                                               AS program_update_date    -- �v���O�����X�V��
              FROM   per_all_people_f            papf
                   , hz_cust_accounts            hca1
                   , hz_parties                  hp1
                   , hz_organization_profiles    hop
                   , hz_org_profiles_ext_b       hopeb
                   , ego_fnd_dsc_flx_ctx_ext     efdfce
                   , fnd_application             fa
              WHERE  hca1.account_number                                               = get_payment_rec.jgzz_recon_ref
              AND    hca1.customer_class_code                                          = cv_customer_class_code_10
              AND    hca1.party_id                                                     = hp1.party_id
              AND    hp1.party_id                                                      = hop.party_id
              AND    hop.effective_end_date IS NULL
              AND    hop.organization_profile_id                                       = hopeb.organization_profile_id
              AND    hopeb.attr_group_id                                               = efdfce.attr_group_id
              AND    efdfce.descriptive_flexfield_name                                 = cv_desc_flexfield_name
              AND    efdfce.descriptive_flex_context_code                              = cv_desc_flex_context_code
              AND    efdfce.application_id                                             = fa.application_id
              AND    fa.application_short_name                                         = cv_application_short_name2
              AND    NVL( hopeb.d_ext_attr1, get_payment_rec.default_effective_date ) <= get_payment_rec.default_effective_date
              AND    NVL( hopeb.d_ext_attr2, get_payment_rec.default_effective_date ) >= get_payment_rec.default_effective_date
              AND    hopeb.c_ext_attr1                                                 = papf.employee_number
              AND    papf.effective_start_date                                        <= get_payment_rec.default_effective_date
              AND    papf.effective_end_date                                          >= get_payment_rec.default_effective_date
              ;
            EXCEPTION
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                               , iv_name         => cv_msg_xxcos_00010 -- ���b�Z�[�W�R�[�h
                               , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                               , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                               , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                               , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                             );
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
            END;
            --
          -- ���݂���ꍇ�A���[���[�N�e�[�u�������ɓo�^
          ELSIF ( lt_dlv_by_code IS NOT NULL ) THEN
            --==============================================================
            -- ���[���[�N�e�[�u���o�^�����i�������j�ڋq����
            --==============================================================
            BEGIN
              INSERT INTO xxcos_rep_vd_sales_pay_chk(
                  year_months            -- �N��
                , base_code              -- ���_�R�[�h
                , base_name              -- ���_��
                , employee_code          -- �S���c�ƈ��R�[�h
                , employee_name          -- �S���c�ƈ���
                , dlv_by_code            -- �[�i�҃R�[�h
                , dlv_by_code_disp       -- �[�i�҃R�[�h�i�\���p�j
                , dlv_by_name            -- �[�i�Җ�
                , dlv_by_name_disp       -- �[�i�Җ��i�\���p�j
                , customer_code          -- �ڋq�R�[�h
                , customer_name          -- �ڋq��
                , pre_counter            -- �O��J�E���^
                , delivery_date          -- ���t
                , standard_qty           -- �{��
                , current_counter        -- ����J�E���^
                , error                  -- �덷
                , sales_amount           -- ����i���юҁj
                , payment_amount         -- �����i���юҁj
                , overs_and_shorts       -- �ߕs���i����[�����j
                , change_balance         -- �ޑK�i�c���j
                , change_pay             -- �ޑK�i�x���j
                , change_return          -- �ޑK�i�߂��j
                , change                 -- �ޑK
                , change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
                , change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
                , created_by             -- �쐬��
                , creation_date          -- �쐬��
                , last_updated_by        -- �ŏI�X�V��
                , last_update_date       -- �ŏI�X�V��
                , last_update_login      -- �ŏI�X�V���O�C��
                , request_id             -- �v��ID
                , program_application_id -- �v���O�����A�v���P�[�V����ID
                , program_id             -- �v���O����ID
                , program_update_date    -- �v���O�����X�V��
              )
              SELECT xrvspc.year_months                                                   AS year_months            -- �N��
                   , xrvspc.base_code                                                     AS base_code              -- ���_�R�[�h
                   , xrvspc.base_name                                                     AS base_name              -- ���_��
                   , xrvspc.employee_code                                                 AS employee_code          -- �S���c�ƈ��R�[�h
                   , xrvspc.employee_name                                                 AS employee_name          -- �S���c�ƈ���
                   , xrvspc.dlv_by_code                                                   AS dlv_by_code            -- �[�i�҃R�[�h
                   , xrvspc.dlv_by_code_disp                                              AS dlv_by_code_disp       -- �[�i�҃R�[�h�i�\���p�j
                   , xrvspc.dlv_by_name                                                   AS dlv_by_name            -- �[�i�Җ�
                   , xrvspc.dlv_by_name_disp                                              AS dlv_by_name_disp       -- �[�i�Җ��i�\���p�j
                   , xrvspc.customer_code                                                 AS customer_code          -- �ڋq�R�[�h
                   , xrvspc.customer_name                                                 AS customer_name          -- �ڋq��
                   , NULL                                                                 AS pre_counter            -- �O��J�E���^
                   , TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2) AS delivery_date          -- ���t
                   , NULL                                                                 AS standard_qty           -- �{��
                   , NULL                                                                 AS current_counter        -- ����J�E���^
                   , NULL                                                                 AS error                  -- �덷
                   , NULL                                                                 AS sales_amount           -- ����i���юҁj
                   , NULL                                                                 AS payment_amount         -- �����i���юҁj
                   , get_payment_rec.payment_amount                                       AS overs_and_shorts       -- �ߕs���i����[�����j
                   , NULL                                                                 AS change_balance         -- �ޑK�i�c���j
                   , NULL                                                                 AS change_pay             -- �ޑK�i�x���j
                   , NULL                                                                 AS change_return          -- �ޑK�i�߂��j
                   , NULL                                                                 AS change                 -- �ޑK
                   , NULL                                                                 AS change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
                   , NULL                                                                 AS change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
                   , cn_created_by                                                        AS created_by             -- �쐬��
                   , cd_creation_date                                                     AS creation_date          -- �쐬��
                   , cn_last_updated_by                                                   AS last_updated_by        -- �ŏI�X�V��
                   , cd_last_update_date                                                  AS last_update_date       -- �ŏI�X�V��
                   , cn_last_update_login                                                 AS last_update_login      -- �ŏI�X�V���O�C��
                   , cn_request_id                                                        AS request_id             -- �v��ID
                   , cn_program_application_id                                            AS program_application_id -- �v���O�����A�v���P�[�V����ID
                   , cn_program_id                                                        AS program_id             -- �v���O����ID
                   , cd_program_update_date                                               AS program_update_date    -- �v���O�����X�V��
              FROM   xxcos_rep_vd_sales_pay_chk xrvspc
              WHERE  xrvspc.year_months   = get_payment_rec.year_months
              AND    xrvspc.base_code     = get_payment_rec.segment2
              AND    xrvspc.customer_code = get_payment_rec.jgzz_recon_ref
              AND    xrvspc.dlv_by_code   = lt_dlv_by_code
              AND    xrvspc.request_id    = cn_request_id
              AND    ROWNUM               = 1
              ;
            EXCEPTION
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                               , iv_name         => cv_msg_xxcos_00010 -- ���b�Z�[�W�R�[�h
                               , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                               , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                               , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                               , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                             );
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
            END;
          END IF;
        -- �Ώۂ���͍X�V
        ELSIF ( lt_dlv_by_code IS NOT NULL ) THEN
          --==============================================================
          -- ���[���[�N�e�[�u���o�^�E�X�V�����i�������j
          --==============================================================
          BEGIN
            UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
            SET    xrvspc.overs_and_shorts = get_payment_rec.payment_amount -- �ߕs���i����[�����j
            WHERE  xrvspc.year_months      = get_payment_rec.year_months
            AND    xrvspc.base_code        = get_payment_rec.segment2
            AND    xrvspc.customer_code    = get_payment_rec.jgzz_recon_ref
            AND    xrvspc.delivery_date    = TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2)
            AND    xrvspc.dlv_by_code      = lt_dlv_by_code
            AND    xrvspc.request_id       = cn_request_id
            ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_xxcos_00011 -- ���b�Z�[�W�R�[�h
                             , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                             , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                             , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                             , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
          --
        END IF;
        --
      END LOOP payment_loop;
      --
      -- �J�[�\���N���[�Y
      CLOSE get_payment_cur;
      --
-- 2013/02/20 Ver1.1 Mod End
-- 2013/03/18 Ver1.2 Add Start
    -- ���_�̂ݎw��ȊO�̏ꍇ
    ELSE
      --==============================================================
      -- ������񏈗�����
      --==============================================================
      -- �J�[�\���I�[�v��
      OPEN get_payment_cur2;
      --
      <<payment_loop>>
      LOOP
      FETCH get_payment_cur2 INTO get_payment_rec;
        --
        -- �Ώۃf�[�^�����̓��[�v�𔲂���
        EXIT WHEN get_payment_cur2%NOTFOUND;
        --
        -- ���O�p����
        gn_cnt                      := gn_cnt + 1;
        -- ������
        lt_dlv_by_code := NULL;
        --
        --==============================================================
        -- �o�^�E�X�V�m�F
        --==============================================================
        BEGIN
          SELECT MAX(xrvspc.dlv_by_code)    AS dlv_by_code
          INTO   lt_dlv_by_code
          FROM   xxcos_rep_vd_sales_pay_chk xrvspc
          WHERE  xrvspc.year_months   = get_payment_rec.year_months
          AND    xrvspc.base_code     = get_payment_rec.segment2
          AND    xrvspc.customer_code = get_payment_rec.jgzz_recon_ref
          AND    xrvspc.delivery_date = TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2)
          AND    xrvspc.request_id    = cn_request_id
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lt_dlv_by_code := NULL;
        END;
--
        -- �Ώۖ����͓o�^
        IF ( lt_dlv_by_code IS NULL ) THEN
          --==============================================================
          -- �o�^�Ώۊm�F�i���[���[�N�e�[�u���ɑΏۂ̌ڋq�����݂��邩�j
          --==============================================================
          BEGIN
            SELECT MAX(xrvspc.dlv_by_code)    AS dlv_by_code
            INTO   lt_dlv_by_code
            FROM   xxcos_rep_vd_sales_pay_chk xrvspc
            WHERE  xrvspc.year_months   = get_payment_rec.year_months
            AND    xrvspc.base_code     = get_payment_rec.segment2
            AND    xrvspc.customer_code = get_payment_rec.jgzz_recon_ref
            AND    xrvspc.request_id    = cn_request_id
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_dlv_by_code := NULL;
          END;
          --
          -- ���݂��Ȃ��ꍇ�A�ڋq����S���c�ƈ����擾���ēo�^
          IF ( lt_dlv_by_code IS NULL ) THEN
            --==============================================================
            -- ���[���[�N�e�[�u���o�^�����i�������j�ڋq�Ȃ�
            --==============================================================
            BEGIN
              INSERT INTO xxcos_rep_vd_sales_pay_chk(
                  year_months            -- �N��
                , base_code              -- ���_�R�[�h
                , base_name              -- ���_��
                , employee_code          -- �S���c�ƈ��R�[�h
                , employee_name          -- �S���c�ƈ���
                , dlv_by_code            -- �[�i�҃R�[�h
                , dlv_by_code_disp       -- �[�i�҃R�[�h�i�\���p�j
                , dlv_by_name            -- �[�i�Җ�
                , dlv_by_name_disp       -- �[�i�Җ��i�\���p�j
                , customer_code          -- �ڋq�R�[�h
                , customer_name          -- �ڋq��
                , pre_counter            -- �O��J�E���^
                , delivery_date          -- ���t
                , standard_qty           -- �{��
                , current_counter        -- ����J�E���^
                , error                  -- �덷
                , sales_amount           -- ����i���юҁj
                , payment_amount         -- �����i���юҁj
                , overs_and_shorts       -- �ߕs���i����[�����j
                , change_balance         -- �ޑK�i�c���j
                , change_pay             -- �ޑK�i�x���j
                , change_return          -- �ޑK�i�߂��j
                , change                 -- �ޑK
                , change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
                , change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
                , created_by             -- �쐬��
                , creation_date          -- �쐬��
                , last_updated_by        -- �ŏI�X�V��
                , last_update_date       -- �ŏI�X�V��
                , last_update_login      -- �ŏI�X�V���O�C��
                , request_id             -- �v��ID
                , program_application_id -- �v���O�����A�v���P�[�V����ID
                , program_id             -- �v���O����ID
                , program_update_date    -- �v���O�����X�V��
              )
              SELECT /*+ LEADING(hca1 hp1 hop hopeb efdfce fa papf)
                         USE_NL(hca1 hp1 hop hopeb efdfce fa papf)
                      */
                     get_payment_rec.year_months                                          AS year_months            -- �N��
                   , get_payment_rec.segment2                                             AS base_code              -- ���_�R�[�h
                   , ( SELECT hp2.party_name   AS party_name
                       FROM   hz_cust_accounts hca2
                            , hz_parties       hp2
                       WHERE  hca2.party_id            = hp2.party_id
                       AND    hca2.customer_class_code = cv_customer_class_code_1
                       AND    hca2.account_number      = get_payment_rec.segment2 )       AS base_name              -- ���_��
                   , hopeb.c_ext_attr1                                                    AS employee_code          -- �S���c�ƈ��R�[�h
                   , papf.full_name                                                       AS employee_name          -- �S���c�ƈ���
                   , NULL                                                                 AS dlv_by_code            -- �[�i�҃R�[�h
                   , NULL                                                                 AS dlv_by_code_disp       -- �[�i�҃R�[�h�i�\���p�j
                   , NULL                                                                 AS dlv_by_name            -- �[�i�Җ�
                   , NULL                                                                 AS dlv_by_name_disp       -- �[�i�Җ��i�\���p�j
                   , get_payment_rec.jgzz_recon_ref                                       AS customer_code          -- �ڋq�R�[�h
                   , hp1.party_name                                                       AS customer_name          -- �ڋq��
                   , NULL                                                                 AS pre_counter            -- �O��J�E���^
                   , TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2) AS delivery_date          -- ���t
                   , NULL                                                                 AS standard_qty           -- �{��
                   , NULL                                                                 AS current_counter        -- ����J�E���^
                   , NULL                                                                 AS error                  -- �덷
                   , NULL                                                                 AS sales_amount           -- ����i���юҁj
                   , NULL                                                                 AS payment_amount         -- �����i���юҁj
                   , get_payment_rec.payment_amount                                       AS overs_and_shorts       -- �ߕs���i����[�����j
                   , NULL                                                                 AS change_balance         -- �ޑK�i�c���j
                   , NULL                                                                 AS change_pay             -- �ޑK�i�x���j
                   , NULL                                                                 AS change_return          -- �ޑK�i�߂��j
                   , NULL                                                                 AS change                 -- �ޑK
                   , NULL                                                                 AS change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
                   , NULL                                                                 AS change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
                   , cn_created_by                                                        AS created_by             -- �쐬��
                   , cd_creation_date                                                     AS creation_date          -- �쐬��
                   , cn_last_updated_by                                                   AS last_updated_by        -- �ŏI�X�V��
                   , cd_last_update_date                                                  AS last_update_date       -- �ŏI�X�V��
                   , cn_last_update_login                                                 AS last_update_login      -- �ŏI�X�V���O�C��
                   , cn_request_id                                                        AS request_id             -- �v��ID
                   , cn_program_application_id                                            AS program_application_id -- �v���O�����A�v���P�[�V����ID
                   , cn_program_id                                                        AS program_id             -- �v���O����ID
                   , cd_program_update_date                                               AS program_update_date    -- �v���O�����X�V��
              FROM   per_all_people_f            papf
                   , hz_cust_accounts            hca1
                   , hz_parties                  hp1
                   , hz_organization_profiles    hop
                   , hz_org_profiles_ext_b       hopeb
                   , ego_fnd_dsc_flx_ctx_ext     efdfce
                   , fnd_application             fa
              WHERE  hca1.account_number                                               = get_payment_rec.jgzz_recon_ref
              AND    hca1.customer_class_code                                          = cv_customer_class_code_10
              AND    hca1.party_id                                                     = hp1.party_id
              AND    hp1.party_id                                                      = hop.party_id
              AND    hop.effective_end_date IS NULL
              AND    hop.organization_profile_id                                       = hopeb.organization_profile_id
              AND    hopeb.attr_group_id                                               = efdfce.attr_group_id
              AND    efdfce.descriptive_flexfield_name                                 = cv_desc_flexfield_name
              AND    efdfce.descriptive_flex_context_code                              = cv_desc_flex_context_code
              AND    efdfce.application_id                                             = fa.application_id
              AND    fa.application_short_name                                         = cv_application_short_name2
              AND    NVL( hopeb.d_ext_attr1, get_payment_rec.default_effective_date ) <= get_payment_rec.default_effective_date
              AND    NVL( hopeb.d_ext_attr2, get_payment_rec.default_effective_date ) >= get_payment_rec.default_effective_date
              AND    hopeb.c_ext_attr1                                                 = papf.employee_number
              AND    papf.effective_start_date                                        <= get_payment_rec.default_effective_date
              AND    papf.effective_end_date                                          >= get_payment_rec.default_effective_date
              ;
            EXCEPTION
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                               , iv_name         => cv_msg_xxcos_00010 -- ���b�Z�[�W�R�[�h
                               , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                               , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                               , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                               , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                             );
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
            END;
            --
          -- ���݂���ꍇ�A���[���[�N�e�[�u�������ɓo�^
          ELSIF ( lt_dlv_by_code IS NOT NULL ) THEN
            --==============================================================
            -- ���[���[�N�e�[�u���o�^�����i�������j�ڋq����
            --==============================================================
            BEGIN
              INSERT INTO xxcos_rep_vd_sales_pay_chk(
                  year_months            -- �N��
                , base_code              -- ���_�R�[�h
                , base_name              -- ���_��
                , employee_code          -- �S���c�ƈ��R�[�h
                , employee_name          -- �S���c�ƈ���
                , dlv_by_code            -- �[�i�҃R�[�h
                , dlv_by_code_disp       -- �[�i�҃R�[�h�i�\���p�j
                , dlv_by_name            -- �[�i�Җ�
                , dlv_by_name_disp       -- �[�i�Җ��i�\���p�j
                , customer_code          -- �ڋq�R�[�h
                , customer_name          -- �ڋq��
                , pre_counter            -- �O��J�E���^
                , delivery_date          -- ���t
                , standard_qty           -- �{��
                , current_counter        -- ����J�E���^
                , error                  -- �덷
                , sales_amount           -- ����i���юҁj
                , payment_amount         -- �����i���юҁj
                , overs_and_shorts       -- �ߕs���i����[�����j
                , change_balance         -- �ޑK�i�c���j
                , change_pay             -- �ޑK�i�x���j
                , change_return          -- �ޑK�i�߂��j
                , change                 -- �ޑK
                , change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
                , change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
                , created_by             -- �쐬��
                , creation_date          -- �쐬��
                , last_updated_by        -- �ŏI�X�V��
                , last_update_date       -- �ŏI�X�V��
                , last_update_login      -- �ŏI�X�V���O�C��
                , request_id             -- �v��ID
                , program_application_id -- �v���O�����A�v���P�[�V����ID
                , program_id             -- �v���O����ID
                , program_update_date    -- �v���O�����X�V��
              )
              SELECT xrvspc.year_months                                                   AS year_months            -- �N��
                   , xrvspc.base_code                                                     AS base_code              -- ���_�R�[�h
                   , xrvspc.base_name                                                     AS base_name              -- ���_��
                   , xrvspc.employee_code                                                 AS employee_code          -- �S���c�ƈ��R�[�h
                   , xrvspc.employee_name                                                 AS employee_name          -- �S���c�ƈ���
                   , xrvspc.dlv_by_code                                                   AS dlv_by_code            -- �[�i�҃R�[�h
                   , xrvspc.dlv_by_code_disp                                              AS dlv_by_code_disp       -- �[�i�҃R�[�h�i�\���p�j
                   , xrvspc.dlv_by_name                                                   AS dlv_by_name            -- �[�i�Җ�
                   , xrvspc.dlv_by_name_disp                                              AS dlv_by_name_disp       -- �[�i�Җ��i�\���p�j
                   , xrvspc.customer_code                                                 AS customer_code          -- �ڋq�R�[�h
                   , xrvspc.customer_name                                                 AS customer_name          -- �ڋq��
                   , NULL                                                                 AS pre_counter            -- �O��J�E���^
                   , TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2) AS delivery_date          -- ���t
                   , NULL                                                                 AS standard_qty           -- �{��
                   , NULL                                                                 AS current_counter        -- ����J�E���^
                   , NULL                                                                 AS error                  -- �덷
                   , NULL                                                                 AS sales_amount           -- ����i���юҁj
                   , NULL                                                                 AS payment_amount         -- �����i���юҁj
                   , get_payment_rec.payment_amount                                       AS overs_and_shorts       -- �ߕs���i����[�����j
                   , NULL                                                                 AS change_balance         -- �ޑK�i�c���j
                   , NULL                                                                 AS change_pay             -- �ޑK�i�x���j
                   , NULL                                                                 AS change_return          -- �ޑK�i�߂��j
                   , NULL                                                                 AS change                 -- �ޑK
                   , NULL                                                                 AS change_out_time_100    -- �ޑK�؂ꎞ�ԁi���j100�~
                   , NULL                                                                 AS change_out_time_10     -- �ޑK�؂ꎞ�ԁi���j10�~
                   , cn_created_by                                                        AS created_by             -- �쐬��
                   , cd_creation_date                                                     AS creation_date          -- �쐬��
                   , cn_last_updated_by                                                   AS last_updated_by        -- �ŏI�X�V��
                   , cd_last_update_date                                                  AS last_update_date       -- �ŏI�X�V��
                   , cn_last_update_login                                                 AS last_update_login      -- �ŏI�X�V���O�C��
                   , cn_request_id                                                        AS request_id             -- �v��ID
                   , cn_program_application_id                                            AS program_application_id -- �v���O�����A�v���P�[�V����ID
                   , cn_program_id                                                        AS program_id             -- �v���O����ID
                   , cd_program_update_date                                               AS program_update_date    -- �v���O�����X�V��
              FROM   xxcos_rep_vd_sales_pay_chk xrvspc
              WHERE  xrvspc.year_months   = get_payment_rec.year_months
              AND    xrvspc.base_code     = get_payment_rec.segment2
              AND    xrvspc.customer_code = get_payment_rec.jgzz_recon_ref
              AND    xrvspc.dlv_by_code   = lt_dlv_by_code
              AND    xrvspc.request_id    = cn_request_id
              AND    ROWNUM               = 1
              ;
            EXCEPTION
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                               , iv_name         => cv_msg_xxcos_00010 -- ���b�Z�[�W�R�[�h
                               , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                               , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                               , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                               , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                             );
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
            END;
          END IF;
        -- �Ώۂ���͍X�V
        ELSIF ( lt_dlv_by_code IS NOT NULL ) THEN
          --==============================================================
          -- ���[���[�N�e�[�u���o�^�E�X�V�����i�������j
          --==============================================================
          BEGIN
            UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
            SET    xrvspc.overs_and_shorts = get_payment_rec.payment_amount -- �ߕs���i����[�����j
            WHERE  xrvspc.year_months      = get_payment_rec.year_months
            AND    xrvspc.base_code        = get_payment_rec.segment2
            AND    xrvspc.customer_code    = get_payment_rec.jgzz_recon_ref
            AND    xrvspc.delivery_date    = TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2)
            AND    xrvspc.dlv_by_code      = lt_dlv_by_code
            AND    xrvspc.request_id       = cn_request_id
            ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_xxcos_00011 -- ���b�Z�[�W�R�[�h
                             , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                             , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                             , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                             , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
          --
        END IF;
        --
      END LOOP payment_loop;
      --
      -- �J�[�\���N���[�Y
      CLOSE get_payment_cur2;
      --
    END IF;
--
    -- �o�^�����m�F
    gn_ins_cnt := gn_ins_cnt + gn_cnt;
-- 2013/03/18 Ver1.2 Add End
--
    -- �����I�����������O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_cnt
    );
    -- ���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( get_payment_cur%ISOPEN ) THEN
        CLOSE get_payment_cur;
-- 2013/03/18 Ver1.2 Add Start
      ELSIF ( get_payment_cur2%ISOPEN ) THEN
        CLOSE get_payment_cur2;
-- 2013/03/18 Ver1.2 Add End
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_get_payment_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_get_balance_data
   * Description      : �ޑK�i�c���j���擾����(A-6)�A���[���[�N�e�[�u���X�V�����i�ޑK�i�c���j���j(A-7)
   ***********************************************************************************/
  PROCEDURE upd_get_balance_data(
    iv_base_code                IN  VARCHAR2, -- ���_�R�[�h
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_get_balance_data'; -- �v���O������
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
    -- *** ���[�J���J�[�\�� ***
    -- �ޑK�i�c���j���擾�J�[�\��
    CURSOR get_change_balance_cur
    IS
      SELECT /*+ LEADING(gcc xrvspc gb flv fa gps)
                 USE_NL(gcc gb flv fa gps)
              */
             TO_CHAR(TO_DATE(SUBSTRB(gb.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months    -- �N��
           , gcc.segment2                                                                          AS segment2       -- ����
           , gcc.segment5                                                                          AS segment5       -- �ڋq
           , SUM(gb.begin_balance_dr - gb.begin_balance_cr)                                        AS change_balance -- ����ޑK�c��
      FROM   gl_balances          gb
           , gl_code_combinations gcc
           , gl_period_statuses   gps
           , fnd_application      fa
           , fnd_lookup_values    flv
      WHERE  gb.code_combination_id                                     = gcc.code_combination_id
      AND    gps.set_of_books_id                                        = gb.set_of_books_id
      AND    gps.period_name                                            = gb.period_name
      AND    gps.application_id                                         = fa.application_id
      AND    gps.adjustment_period_flag                                 = cv_adjustment_period_flag
      AND    fa.application_short_name                                  = cv_application_short_name1
      AND    gb.set_of_books_id                                         = gn_set_of_books_id
      AND    gb.actual_flag                                             = cv_result_flag
      AND    TO_DATE(SUBSTRB(gb.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(gb.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
-- 2023/04/26 Ver1.4 Add Start
      AND    gb.period_name                                             < cv_period_start_saas
-- 2023/04/26 Ver1.4 Add End
      AND    gcc.segment3                                               = flv.lookup_code
      AND    flv.lookup_type                                            = cv_change_account
      AND    flv.language                                               = ct_lang
      AND    gcc.segment2                                               = iv_base_code
      AND EXISTS (
                   SELECT 1
                   FROM   xxcos_rep_vd_sales_pay_chk xrvspc
                   WHERE  xrvspc.customer_code = gcc.segment5
                   AND    xrvspc.request_id    = cn_request_id
                 )
      GROUP BY
             gb.period_name
           , gcc.segment2
           , gcc.segment5
-- 2022/12/29 Ver1.3 Add Start
      UNION
      SELECT
             TO_CHAR(TO_DATE(SUBSTRB(xgbe.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months    -- �N��
           , xgbe.segment2                                                                           AS segment2       -- ����
           , xgbe.segment5                                                                           AS segment5       -- �ڋq
           , SUM(xgbe.begin_balance_dr - xgbe.begin_balance_cr)                                      AS change_balance -- ����ޑK�c��
      FROM   xxcfo_gl_balances_erp xgbe                    -- GL�c��_ERP�e�[�u��
           , gl_period_statuses   gps                      -- ��v���ԃX�e�[�^�X
           , fnd_application      fa                       -- �A�v���P�[�V����
-- 2023/04/26 Ver1.4 Add Start
           , fnd_lookup_values    flv
-- 2023/04/26 Ver1.4 Add End
           , gl_sets_of_books     gsob                     -- ��v����e�[�u��
      WHERE  gsob.set_of_books_id                                       = gn_set_of_books_id
      AND    xgbe.set_of_books_name                                     = gsob.name
      AND    gps.set_of_books_id                                        = gsob.set_of_books_id
      AND    gps.period_name                                            = xgbe.period_name
      AND    gps.application_id                                         = fa.application_id
      AND    gps.adjustment_period_flag                                 = cv_adjustment_period_flag   -- 'N'
      AND    fa.application_short_name                                  = cv_application_short_name1  -- 'SQLGL'
      AND    TO_DATE(SUBSTRB(xgbe.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(xgbe.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
-- 2023/04/26 Ver1.4 Add Start
      AND    xgbe.period_name                                          >= cv_period_start_saas
      AND    xgbe.segment3                                              = flv.lookup_code
      AND    flv.lookup_type                                            = cv_change_account
      AND    flv.language                                               = ct_lang
-- 2023/04/26 Ver1.4 Add End
      AND    xgbe.segment2                                              = iv_base_code
      AND EXISTS (
                   SELECT 1
                   FROM   xxcos_rep_vd_sales_pay_chk xrvspc
                   WHERE  xrvspc.customer_code = xgbe.segment5
                   AND    xrvspc.request_id    = cn_request_id
                 )
      GROUP BY
             xgbe.period_name
           , xgbe.segment2
           , xgbe.segment5
-- 2022/12/29 Ver1.3 Add End
    ;
    --
    get_change_balance_rec    get_change_balance_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    gn_cnt := 0;
    g_year_months_tab.DELETE;
    g_base_code_tab.DELETE;
    g_customer_code_tab.DELETE;
    g_amount_tab.DELETE;
    --
    --==============================================================
    -- �ޑK�i�c���j���擾����
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN get_change_balance_cur;
    --
    <<change_balance_loop>>
    LOOP
    FETCH get_change_balance_cur INTO get_change_balance_rec;
      --
      -- �Ώۃf�[�^�����̓��[�v�𔲂���
      EXIT WHEN get_change_balance_cur%NOTFOUND;
      --
      -- �X�V���R�[�h���̊i�[
      gn_cnt                      := gn_cnt + 1;
      g_year_months_tab(gn_cnt)   := get_change_balance_rec.year_months;
      g_base_code_tab(gn_cnt)     := get_change_balance_rec.segment2;
      g_customer_code_tab(gn_cnt) := get_change_balance_rec.segment5;
      g_amount_tab(gn_cnt)        := get_change_balance_rec.change_balance;
      --
    END LOOP change_balance_loop;
    --
    -- �J�[�\���N���[�Y
    CLOSE get_change_balance_cur;
--
    --==============================================================
    -- ���[���[�N�e�[�u���X�V�����i�ޑK�i�c���j���j
    --==============================================================
    BEGIN
      FORALL i IN g_year_months_tab.FIRST .. g_year_months_tab.COUNT
        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
        SET    xrvspc.change_balance = g_amount_tab(i) -- �ޑK�i�c���j
        WHERE  xrvspc.year_months    = g_year_months_tab(i)
        AND    xrvspc.base_code      = g_base_code_tab(i)
        AND    xrvspc.customer_code  = g_customer_code_tab(i)
        AND    xrvspc.request_id     = cn_request_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcos_00011 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                       , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �����I�����������O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_cnt
    );
    -- ���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( get_change_balance_cur%ISOPEN ) THEN
        CLOSE get_change_balance_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_get_balance_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_get_check_data
   * Description      : �ޑK�i�x���j���擾����(A-8)�A���[���[�N�e�[�u���X�V�����i�ޑK�i�x���j���j(A-9)
   ***********************************************************************************/
  PROCEDURE upd_get_check_data(
    iv_base_code                IN  VARCHAR2, -- ���_�R�[�h
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_get_check_data'; -- �v���O������
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
    -- *** ���[�J���J�[�\�� ***
    -- �ޑK�i�x���j���擾�J�[�\��
    CURSOR get_change_pay_cur
    IS
      SELECT /*+ LEADING(gjh gjl gcc flv xrvspc xipm)
                 USE_NL(gjh gjl gcc flv xrvspc xipm)
                 INDEX(gjh GL_JE_HEADERS_N2)
              */
             TO_CHAR(TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months -- �N��
           , gcc.segment2                                                                           AS segment2    -- ����
           , gcc.segment5                                                                           AS segment5    -- �ڋq
           , TO_CHAR(xipm.check_date, cv_format_yyyymmdd2)                                          AS check_date  -- �x����
           , SUM(NVL(gjl.accounted_dr,0) - NVL(gjl.accounted_cr,0))                                 AS change_pay  -- �ޑK�x���z
      FROM   gl_je_headers             gjh
           , gl_je_lines               gjl
           , gl_code_combinations      gcc
           , fnd_lookup_values         flv
           , xxcos_invoice_payments_mv xipm
      WHERE  gjh.je_header_id                                            = gjl.je_header_id
      AND    TO_NUMBER(gjl.reference_2)                                  = xipm.invoice_id
      AND    gjl.code_combination_id                                     = gcc.code_combination_id
      AND    gcc.segment2                                                = iv_base_code
      AND    gcc.segment3                                                = flv.lookup_code
      AND    flv.lookup_type                                             = cv_change_account
      AND    flv.language                                                = ct_lang
      AND    gjl.status                                                  = cv_status_p
      AND    gjh.actual_flag                                             = cv_result_flag
      AND    gjh.je_source                                               = cv_je_source_ap
      AND    gjh.je_category                                             = cv_je_categories_ap
      AND    gjh.set_of_books_id                                         = gn_set_of_books_id
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
      AND EXISTS (
                   SELECT 1
                   FROM   xxcos_rep_vd_sales_pay_chk xrvspc
                   WHERE  xrvspc.customer_code = gcc.segment5
                   AND    xrvspc.request_id    = cn_request_id
                 )
      GROUP BY
             gjh.period_name
           , gcc.segment2
           , gcc.segment5
           , xipm.check_date
-- 2022/12/29 Ver1.3 Add Start
      UNION
      SELECT 
             TO_CHAR(TO_DATE(SUBSTRB(xgjle.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months -- �N��
           , xgjle.segment2                                                                           AS segment2    -- ����
           , xgjle.segment5                                                                           AS segment5    -- �ڋq
           , TO_CHAR(xgjle.check_date, cv_format_yyyymmdd2)                                           AS check_date  -- �x����
           , SUM(NVL(xgjle.accounted_dr,0) - NVL(xgjle.accounted_cr,0))                               AS change_pay  -- �ޑK�x���z
      FROM   xxcfo_gl_je_lines_erp   xgjle     -- GL�d�󖾍�_ERP�e�[�u��
           , gl_sets_of_books        gsob      -- ��v����e�[�u��
      WHERE  xgjle.segment2                                               = iv_base_code
      AND    xgjle.je_source                                              = cv_je_source_ap
      AND    xgjle.je_category                                            = cv_je_categories_ap
      AND    xgjle.set_of_books_name                                      = gsob.name
      AND    gsob.set_of_books_id                                         = gn_set_of_books_id
      AND    TO_DATE(SUBSTRB(xgjle.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(xgjle.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
      AND EXISTS (
                   SELECT 1
                   FROM   xxcos_rep_vd_sales_pay_chk xrvspc
                   WHERE  xrvspc.customer_code = xgjle.segment5
                   AND    xrvspc.request_id    = cn_request_id
                 )
      GROUP BY
             xgjle.period_name
           , xgjle.segment2
           , xgjle.segment5
           , xgjle.check_date
-- 2022/12/29 Ver1.3 Add End
    ;
    --
    get_change_pay_rec        get_change_pay_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    gn_cnt := 0;
    g_year_months_tab.DELETE;
    g_base_code_tab.DELETE;
    g_customer_code_tab.DELETE;
    g_delivery_date_tab.DELETE;
    g_amount_tab.DELETE;
    --
    --==============================================================
    -- �ޑK�i�x���j���擾����
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN get_change_pay_cur;
    --
    <<change_pay_loop>>
    LOOP
    FETCH get_change_pay_cur INTO get_change_pay_rec;
      --
      -- �Ώۃf�[�^�����̓��[�v�𔲂���
      EXIT WHEN get_change_pay_cur%NOTFOUND;
      --
      -- �X�V���R�[�h���̊i�[
      gn_cnt                      := gn_cnt + 1;
      g_year_months_tab(gn_cnt)   := get_change_pay_rec.year_months;
      g_base_code_tab(gn_cnt)     := get_change_pay_rec.segment2;
      g_customer_code_tab(gn_cnt) := get_change_pay_rec.segment5;
      g_delivery_date_tab(gn_cnt) := get_change_pay_rec.check_date;
      g_amount_tab(gn_cnt)        := get_change_pay_rec.change_pay;
      --
    END LOOP change_pay_loop;
    --
    -- �J�[�\���N���[�Y
    CLOSE get_change_pay_cur;
    --
--
    --==============================================================
    -- ���[���[�N�e�[�u���X�V�����i�ޑK�i�x���j���j
    --==============================================================
    BEGIN
      FORALL i IN g_year_months_tab.FIRST .. g_year_months_tab.COUNT
        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
        SET    xrvspc.change_pay                                   = xrvspc.change_pay + g_amount_tab(i) -- �ޑK�i�x���j
        WHERE  xrvspc.year_months                                  = g_year_months_tab(i)
        AND    xrvspc.base_code                                    = g_base_code_tab(i)
        AND    xrvspc.customer_code                                = g_customer_code_tab(i)
        AND    TO_DATE(xrvspc.delivery_date, cv_format_yyyymmdd2) >= TO_DATE(g_delivery_date_tab(i), cv_format_yyyymmdd2)
        AND    xrvspc.request_id                                   = cn_request_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcos_00011 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                       , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �����I�����������O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_cnt
    );
    -- ���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( get_change_pay_cur%ISOPEN ) THEN
        CLOSE get_change_pay_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_get_check_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_get_return_data
   * Description      : �ޑK�i�߂��j���擾����(A-10)�A���[���[�N�e�[�u���X�V�����i�ޑK�i�߂��j���j(A-11)
   ***********************************************************************************/
  PROCEDURE upd_get_return_data(
    iv_base_code                IN  VARCHAR2, -- ���_�R�[�h
    ov_errbuf                   OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                  OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                   OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_get_return_data'; -- �v���O������
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
    -- *** ���[�J���J�[�\�� ***
    -- �ޑK�i�߂��j���擾�J�[�\��
    CURSOR get_change_return_cur
    IS
      SELECT /*+ LEADING(gcc flv xrvspc gjl gjh)
                 USE_NL(gcc gjl gjh)
              */
             TO_CHAR(TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months    -- �N��
           , gcc.segment2                                                                           AS segment2       -- ����
           , gcc.segment5                                                                           AS segment5       -- �ڋq
           , TO_CHAR(gjl.effective_date, cv_format_yyyymmdd2)                                       AS effective_date -- GL�L����
           , SUM(NVL(gjl.accounted_dr,0) - NVL(gjl.accounted_cr,0))                                 AS change_return  -- �ޑK�d����z
      FROM   gl_je_headers           gjh
           , gl_je_lines             gjl
           , gl_code_combinations    gcc
           , fnd_lookup_values       flv
      WHERE  gjh.je_header_id                                            = gjl.je_header_id
      AND    gjl.code_combination_id                                     = gcc.code_combination_id
      AND    gcc.segment2                                                = iv_base_code
      AND    gcc.segment3                                                = flv.lookup_code
      AND    flv.lookup_type                                             = cv_change_account
      AND    flv.language                                                = ct_lang
      AND    gjl.status                                                  = cv_status_p
      AND    gjh.actual_flag                                             = cv_result_flag
      AND    gjh.je_source                                              <> cv_je_source_ap
      AND    gjh.je_category                                            <> cv_je_categories_ap
      AND    gjh.set_of_books_id                                         = gn_set_of_books_id
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
      AND EXISTS (
                   SELECT 1
                   FROM   xxcos_rep_vd_sales_pay_chk xrvspc
                   WHERE  xrvspc.customer_code = gcc.segment5
                   AND    xrvspc.request_id    = cn_request_id
                 )
      GROUP BY
             gjh.period_name
           , gcc.segment2
           , gcc.segment5
           , gjl.effective_date
-- 2022/12/29 Ver1.3 Add Start
      UNION
      SELECT 
             TO_CHAR(TO_DATE(SUBSTRB(xgjle.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months    -- �N��
           , xgjle.segment2                                                                           AS segment2       -- ����
           , xgjle.segment5                                                                           AS segment5       -- �ڋq
           , TO_CHAR(xgjle.effective_date, cv_format_yyyymmdd2)                                       AS effective_date -- GL�L����
           , SUM(NVL(xgjle.accounted_dr,0) - NVL(xgjle.accounted_cr,0))                               AS change_return  -- �ޑK�d����z
      FROM   xxcfo_gl_je_lines_erp   xgjle     -- GL�d�󖾍�_ERP�e�[�u��
           , gl_sets_of_books        gsob      -- ��v����e�[�u��
      WHERE  xgjle.segment2                                               = iv_base_code
      AND    xgjle.je_source                                              <> cv_je_source_ap
      AND    xgjle.je_category                                            <> cv_je_categories_ap
      AND    xgjle.set_of_books_name                                      = gsob.name
      AND    gsob.set_of_books_id                                         = gn_set_of_books_id
      AND    TO_DATE(SUBSTRB(xgjle.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(xgjle.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
      AND EXISTS (
                   SELECT 1
                   FROM   xxcos_rep_vd_sales_pay_chk xrvspc
                   WHERE  xrvspc.customer_code = xgjle.segment5
                   AND    xrvspc.request_id    = cn_request_id
                 )
      GROUP BY
             xgjle.period_name
           , xgjle.segment2
           , xgjle.segment5
           , xgjle.effective_date
-- 2022/12/29 Ver1.3 Add End
    ;
    --
    get_change_return_rec     get_change_return_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    gn_cnt := 0;
    g_year_months_tab.DELETE;
    g_base_code_tab.DELETE;
    g_customer_code_tab.DELETE;
    g_delivery_date_tab.DELETE;
    g_amount_tab.DELETE;
    --
    --==============================================================
    -- �ޑK�i�߂��j���擾����
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN get_change_return_cur;
    --
    <<change_return_loop>>
    LOOP
    FETCH get_change_return_cur INTO get_change_return_rec;
      --
      -- �Ώۃf�[�^�����̓��[�v�𔲂���
      EXIT WHEN get_change_return_cur%NOTFOUND;
      --
      -- �X�V���R�[�h���̊i�[
      gn_cnt                      := gn_cnt + 1;
      g_year_months_tab(gn_cnt)   := get_change_return_rec.year_months;
      g_base_code_tab(gn_cnt)     := get_change_return_rec.segment2;
      g_customer_code_tab(gn_cnt) := get_change_return_rec.segment5;
      g_delivery_date_tab(gn_cnt) := get_change_return_rec.effective_date;
      g_amount_tab(gn_cnt)        := get_change_return_rec.change_return;
      --
    END LOOP change_return_loop;
    --
    -- �J�[�\���N���[�Y
    CLOSE get_change_return_cur;
--
    --==============================================================
    -- ���[���[�N�e�[�u���X�V�����i�ޑK�i�߂��j���j
    --==============================================================
    BEGIN
      FORALL i IN g_year_months_tab.FIRST .. g_year_months_tab.COUNT
        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
        SET    xrvspc.change_return                                = xrvspc.change_return + g_amount_tab(i) -- �ޑK�i�߂��j
        WHERE  xrvspc.year_months                                  = g_year_months_tab(i)
        AND    xrvspc.base_code                                    = g_base_code_tab(i)
        AND    xrvspc.customer_code                                = g_customer_code_tab(i)
        AND    TO_DATE(xrvspc.delivery_date, cv_format_yyyymmdd2) >= TO_DATE(g_delivery_date_tab(i), cv_format_yyyymmdd2)
        AND    xrvspc.request_id                                   = cn_request_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcos_00011 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                       , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �����I�����������O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_cnt
    );
    -- ���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( get_change_return_cur%ISOPEN ) THEN
        CLOSE get_change_return_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_get_return_data;
--
  /**********************************************************************************
   * Procedure Name   : del_rep_work_no_0_data
   * Description      : ���[���[�N�e�[�u�����폜�����i0�ȊO�j(A-12)
   ***********************************************************************************/
  PROCEDURE del_rep_work_no_0_data(
    iv_overs_and_shorts IN  VARCHAR2, -- �����ߕs��
    iv_counter_error    IN  VARCHAR2, -- �J�E���^�덷
    ov_errbuf           OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_work_no_0_data'; -- �v���O������
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
    -- *** ���[�J���J�[�\�� ***
    -- �����폜�Ώێ擾�J�[�\��
    CURSOR get_rep_xrvspc_1_cur
    IS
      SELECT xrvspc.customer_code       AS customer_code
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.request_id          = cn_request_id
      GROUP BY
             xrvspc.customer_code
-- 2013/03/18 Ver1.2 Mod Start
---- 2013/02/20 Ver1.1 Mod Start
----      HAVING ( ( SUM(xrvspc.overs_and_shorts) = 0 ) OR ( SUM(xrvspc.error) = 0 ) )
--      HAVING ( ( SUM(xrvspc.overs_and_shorts) = 0 ) OR ( SUM(NVL(xrvspc.error,0)) = 0 ) )
---- 2013/02/20 Ver1.1 Mod End
      HAVING ( ( SUM(xrvspc.overs_and_shorts) = 0 ) AND ( SUM(NVL(xrvspc.error,0)) = 0 ) )
-- 2013/03/18 Ver1.2 Mod End
    ;
    -- �����ߕs���폜�Ώێ擾�J�[�\��
    CURSOR get_rep_xrvspc_2_cur
    IS
      SELECT xrvspc.customer_code       AS customer_code
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.request_id          = cn_request_id
      GROUP BY
             xrvspc.customer_code
      HAVING SUM(xrvspc.overs_and_shorts) = 0
    ;
    -- �덷�폜�Ώێ擾�J�[�\��
    CURSOR get_rep_xrvspc_3_cur
    IS
      SELECT xrvspc.customer_code       AS customer_code
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.request_id          = cn_request_id
      GROUP BY
             xrvspc.customer_code
-- 2013/02/20 Ver1.1 Mod Start
--      HAVING SUM(xrvspc.error) = 0
      HAVING SUM(NVL(xrvspc.error,0)) = 0
-- 2013/02/20 Ver1.1 Mod End
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
    -- ������
    g_customer_code_tab.DELETE;
    --
    --==============================================================
    -- ���[���[�N�e�[�u�����擾�����i0�ȊO�j
    --==============================================================
    -- �����ߕs����1(0�ȊO�̂��̂��o��)���A�덷��1(0�ȊO�̂��̂��o��)�̏ꍇ
    IF ( ( iv_overs_and_shorts = cv_cust_sum_out_div_1 ) AND ( iv_counter_error = cv_cust_sum_out_div_1 ) ) THEN
      -- �I�[�v��
      OPEN get_rep_xrvspc_1_cur;
      --
      FETCH get_rep_xrvspc_1_cur BULK COLLECT INTO g_customer_code_tab;
      -- �N���[�Y
      CLOSE get_rep_xrvspc_1_cur;
      --
    -- �����ߕs����0(0���܂ݑS�ďo��)���A�덷��1(0�ȊO�̂��̂��o��)�̏ꍇ
    ELSIF ( ( iv_overs_and_shorts = cv_cust_sum_out_div_0 ) AND ( iv_counter_error = cv_cust_sum_out_div_1 ) ) THEN
      -- �I�[�v��
      OPEN get_rep_xrvspc_3_cur;
      --
      FETCH get_rep_xrvspc_3_cur BULK COLLECT INTO g_customer_code_tab;
      -- �N���[�Y
      CLOSE get_rep_xrvspc_3_cur;
      --
    -- �����ߕs����1(0�ȊO�̂��̂��o��)���A�덷��0(0���܂ݑS�ďo��)�̏ꍇ
    ELSIF ( ( iv_overs_and_shorts = cv_cust_sum_out_div_1 ) AND ( iv_counter_error = cv_cust_sum_out_div_0 ) ) THEN
      -- �I�[�v��
      OPEN get_rep_xrvspc_2_cur;
      --
      FETCH get_rep_xrvspc_2_cur BULK COLLECT INTO g_customer_code_tab;
      -- �N���[�Y
      CLOSE get_rep_xrvspc_2_cur;
      --
    END IF;
--
    -- �����I�����������O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || '1' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || g_customer_code_tab.COUNT
    );
    -- ���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --
    -- �폜�Ώۃf�[�^�����݂���ꍇ
    IF ( g_customer_code_tab.COUNT > 0 ) THEN
      --==============================================================
      -- ���[���[�N�e�[�u�����폜�����i0�ȊO�j
      --==============================================================
      BEGIN
        FORALL i IN g_customer_code_tab.FIRST .. g_customer_code_tab.COUNT
          DELETE FROM xxcos_rep_vd_sales_pay_chk xrvspc
          WHERE       xrvspc.customer_code = g_customer_code_tab(i)
          AND         xrvspc.request_id    = cn_request_id
          ;
          --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcos_00012 -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                         , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- �����I�����������O�֏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_prg_name || ' ' || cv_proc_end || '2' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
      );
      -- ���O��s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
--
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( get_rep_xrvspc_1_cur%ISOPEN ) THEN
        CLOSE get_rep_xrvspc_1_cur;
      ELSIF ( get_rep_xrvspc_2_cur%ISOPEN ) THEN
        CLOSE get_rep_xrvspc_2_cur;
      ELSIF ( get_rep_xrvspc_3_cur%ISOPEN ) THEN
        CLOSE get_rep_xrvspc_3_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_rep_work_no_0_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_rep_work_data
   * Description      : ���[���[�N�e�[�u���X�V�����i�ޑK���A�������j(A-13)
   ***********************************************************************************/
  PROCEDURE upd_rep_work_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_rep_work_data'; -- �v���O������
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
-- 2013/02/20 Ver1.1 Add Start
    -- *** ���[�J���ϐ� ***
    lt_dlv_by_code            xxcos_rep_vd_sales_pay_chk.dlv_by_code%TYPE DEFAULT NULL; -- �[�i�҃R�[�h
-- 2013/02/20 Ver1.1 Add End
--
    -- *** ���[�J���J�[�\�� ***
-- 2013/02/20 Ver1.1 Del Start
--    -- �X�V�p�J�[�\��
--    CURSOR upd_disp_cur
--    IS
--      SELECT xrvspc.year_months         AS year_months     -- �N��
--           , xrvspc.employee_code       AS employee_code   -- �c�ƈ��R�[�h
--           , xrvspc.dlv_by_code         AS dlv_by_code     -- �[�i�҃R�[�h
--           , xrvspc.customer_code       AS customer_code   -- �ڋq�R�[�h
--           , xrvspc.delivery_date       AS delivery_date   -- �[�i��
--      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
--      WHERE  xrvspc.request_id = cn_request_id
--      ORDER BY
--             year_months
--           , employee_code
--           , dlv_by_code
--           , customer_code
--           , delivery_date
--    ;
--    --
--    upd_disp_rec              upd_disp_cur%ROWTYPE;
-- 2013/02/20 Ver1.1 Del End
-- 2013/02/20 Ver1.1 Add Start
    -- �ޑK�N���A�p�J�[�\��1�i�ߕs���̂ݕ\�����R�[�h�̒ޑK��NULL�ɃN���A�j
    CURSOR upd_change_cur1
    IS
      SELECT xrvspc.year_months         AS year_months     -- �N��
           , xrvspc.employee_code       AS employee_code   -- �c�ƈ��R�[�h
           , xrvspc.customer_code       AS customer_code   -- �ڋq�R�[�h
           , xrvspc.delivery_date       AS delivery_date   -- �[�i��
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.pre_counter IS NULL
      AND    xrvspc.request_id = cn_request_id
    ;
    --
    upd_change_rec1           upd_change_cur1%ROWTYPE;
    --
    -- �ޑK�N���A�p�J�[�\��2�i����ڋq�E�[�i���Ŕ[�i�҂����Ⴗ�郌�R�[�h�̕Е���0�ɃN���A�j
    CURSOR upd_change_cur2
    IS
      SELECT xrvspc.year_months         AS year_months     -- �N��
           , xrvspc.employee_code       AS employee_code   -- �c�ƈ��R�[�h
           , xrvspc.customer_code       AS customer_code   -- �ڋq�R�[�h
           , xrvspc.delivery_date       AS delivery_date   -- �[�i��
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.request_id = cn_request_id
      GROUP BY
             xrvspc.year_months
           , xrvspc.employee_code
           , xrvspc.customer_code
           , xrvspc.delivery_date
      HAVING COUNT(1) > 1
    ;
    --
    upd_change_rec2           upd_change_cur2%ROWTYPE;
-- 2013/02/20 Ver1.1 Add End
--
-- 2013/02/20 Ver1.1 Del Start
--    -- *** ���[�J���ϐ� ***
--    lt_year_months            xxcos_rep_vd_sales_pay_chk.year_months%TYPE   DEFAULT NULL; -- �N���i����p�j
--    lt_employee_code          xxcos_rep_vd_sales_pay_chk.employee_code%TYPE DEFAULT NULL; -- �c�ƈ��R�[�h�i����p�j
--    lt_dlv_by_code            xxcos_rep_vd_sales_pay_chk.dlv_by_code%TYPE   DEFAULT NULL; -- �[�i�҃R�[�h�i����p�j
-- 2013/02/20 Ver1.1 Del End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ������
    gn_cnt := 0;
-- 2013/02/20 Ver1.1 Del Start
--    g_year_months_tab.DELETE;
--    g_employee_code_tab.DELETE;
--    g_customer_code_tab.DELETE;
--    g_delivery_date_tab.DELETE;
--    --
--    --==============================================================
--    -- �[�i�ҏ��i�\���p�j�擾����
--    --==============================================================
--    -- �J�[�\���I�[�v��
--    OPEN upd_disp_cur;
--    --
--    <<get_disp_loop>>
--    LOOP
--    FETCH upd_disp_cur INTO upd_disp_rec;
--      --
--      -- �Ώۃf�[�^�����̓��[�v�𔲂���
--      EXIT WHEN upd_disp_cur%NOTFOUND;
--      --
--      -- ���񃌃R�[�h�A�܂��͔N���E�c�ƈ��E�[�i�҂̂����ꂩ���ύX�����ꍇ
--      IF ( ( g_year_months_tab.COUNT = 0 )
--        OR ( upd_disp_rec.year_months   <> lt_year_months )
--        OR ( upd_disp_rec.employee_code <> lt_employee_code )
--        OR ( upd_disp_rec.dlv_by_code <> lt_dlv_by_code ) )
--      THEN
--        -- ����p���R�[�h�l�ݒ�
--        lt_year_months   := upd_disp_rec.year_months;
--        lt_employee_code := upd_disp_rec.employee_code;
--        lt_dlv_by_code   := upd_disp_rec.dlv_by_code;
--        -- �[�i�҂�\�����郌�R�[�h���̊i�[
--        gn_cnt                      := gn_cnt + 1;
--        g_year_months_tab(gn_cnt)   := upd_disp_rec.year_months;
--        g_employee_code_tab(gn_cnt) := upd_disp_rec.employee_code;
--        g_dlv_by_code_tab(gn_cnt)   := upd_disp_rec.dlv_by_code;
--        g_customer_code_tab(gn_cnt) := upd_disp_rec.customer_code;
--        g_delivery_date_tab(gn_cnt) := upd_disp_rec.delivery_date;
--        --
--      END IF;
--      --
--    END LOOP get_disp_loop;
--    --
--    -- �J�[�\���N���[�Y
--    CLOSE upd_disp_cur;
----
--    --==============================================================
--    -- ���[���[�N�e�[�u���X�V�����i�[�i�ҏ��j
--    --==============================================================
--    BEGIN
--      FORALL i IN g_year_months_tab.FIRST .. g_year_months_tab.COUNT
--        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
--          SET  xrvspc.dlv_by_code_disp = NULL -- �[�i�҃R�[�h�i�\���p�j
--             , xrvspc.dlv_by_name_disp = NULL -- �[�i�Җ��i�\���p�j
--        WHERE  xrvspc.year_months   = g_year_months_tab(i)
--        AND    xrvspc.employee_code = g_employee_code_tab(i)
--        AND    xrvspc.dlv_by_code   = g_dlv_by_code_tab(i)
--        AND    xrvspc.request_id    = cn_request_id
--        AND    NOT EXISTS (
--                           SELECT 1
--                           FROM   xxcos_rep_vd_sales_pay_chk xrvspc1
--                           WHERE  xrvspc1.year_months   = xrvspc.year_months
--                           AND    xrvspc1.employee_code = xrvspc.employee_code
--                           AND    xrvspc1.dlv_by_code   = xrvspc.dlv_by_code
--                           AND    xrvspc1.customer_code = xrvspc.customer_code
--                           AND    xrvspc1.delivery_date = xrvspc.delivery_date
--                           AND    xrvspc1.request_id    = xrvspc.request_id
--                           AND    xrvspc1.year_months   = g_year_months_tab(i)
--                           AND    xrvspc1.employee_code = g_employee_code_tab(i)
--                           AND    xrvspc1.dlv_by_code   = g_dlv_by_code_tab(i)
--                           AND    xrvspc1.customer_code = g_customer_code_tab(i)
--                           AND    xrvspc1.delivery_date = g_delivery_date_tab(i)
--                           AND    xrvspc1.request_id    = cn_request_id
--                         )
--        ;
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
--                       , iv_name         => cv_msg_xxcos_00011 -- ���b�Z�[�W�R�[�h
--                       , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
--                       , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
--                       , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
--                       , iv_token_value2 => SQLERRM            -- �g�[�N���l2
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--    END;
--    --
----
--    -- �����I�����������O�֏o��
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => cv_prg_name || ' ' || cv_proc_end || '1' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
--    );
--    -- ���O��s
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => ''
--    );
-- 2013/02/20 Ver1.1 Del End
--
    --==============================================================
    -- ���[���[�N�e�[�u���X�V�����i�ޑK���A�������j
    --==============================================================
    BEGIN
      UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
        SET  xrvspc.payment_amount = xrvspc.sales_amount - xrvspc.overs_and_shorts                    -- �����i���юҁj
           , xrvspc.change         = xrvspc.change_balance + xrvspc.change_pay + xrvspc.change_return -- �ޑK
      WHERE  xrvspc.request_id     = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcos_00011 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                       , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                       , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                       , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �����I�����������O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || '2' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
    );
    -- ���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
-- 2013/02/20 Ver1.1 Add Start
    --==============================================================
    -- �ޑK�N���A���1�擾����
    --==============================================================
    -- �J�[�\���I�[�v��
    OPEN upd_change_cur1;
    --
    <<clear_change1_loop>>
    LOOP
    FETCH upd_change_cur1 INTO upd_change_rec1;
      --
      -- �Ώۃf�[�^�����̓��[�v�𔲂���
      EXIT WHEN upd_change_cur1%NOTFOUND;
      --
      -- ���O�p����
      gn_cnt := gn_cnt + 1;
      --
      --==============================================================
      -- ���[���[�N�e�[�u���X�V�����i�ޑK�N���A���1�j
      --==============================================================
      BEGIN
        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
          SET  xrvspc.change        = NULL -- �ޑK
        WHERE  xrvspc.year_months   = upd_change_rec1.year_months
        AND    xrvspc.employee_code = upd_change_rec1.employee_code
        AND    xrvspc.customer_code = upd_change_rec1.customer_code
        AND    xrvspc.delivery_date = upd_change_rec1.delivery_date
        AND    xrvspc.request_id    = cn_request_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcos_00011 -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                         , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
    END LOOP clear_change1_loop;
    --
    -- �J�[�\���N���[�Y
    CLOSE upd_change_cur1;
--
    -- �����I�����������O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || '3' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_cnt
    );
    -- ���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- �ޑK�N���A���2�擾����
    --==============================================================
    -- ������
    gn_cnt := 0;
    -- �J�[�\���I�[�v��
    OPEN upd_change_cur2;
    --
    <<clear_change2_loop>>
    LOOP
    FETCH upd_change_cur2 INTO upd_change_rec2;
      --
      -- �Ώۃf�[�^�����̓��[�v�𔲂���
      EXIT WHEN upd_change_cur2%NOTFOUND;
      --
      -- ������
      lt_dlv_by_code := NULL;
      -- ���O�p����
      gn_cnt := gn_cnt + 1;
      --
      --==============================================================
      -- �N���A�ΏۊO�[�i�҃R�[�h�擾����
      --==============================================================
      SELECT MAX(xrvspc.dlv_by_code)    AS dlv_by_code
      INTO   lt_dlv_by_code
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.year_months   = upd_change_rec2.year_months
      AND    xrvspc.employee_code = upd_change_rec2.employee_code
      AND    xrvspc.customer_code = upd_change_rec2.customer_code
      AND    xrvspc.delivery_date = upd_change_rec2.delivery_date
      AND    xrvspc.request_id    = cn_request_id
      ;
      --==============================================================
      -- ���[���[�N�e�[�u���X�V�����i�ޑK�N���A���2�j
      --==============================================================
      BEGIN
        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
          SET  xrvspc.change         = 0 -- �ޑK
        WHERE  xrvspc.year_months    = upd_change_rec2.year_months
        AND    xrvspc.employee_code  = upd_change_rec2.employee_code
        AND    xrvspc.dlv_by_code   <> lt_dlv_by_code
        AND    xrvspc.customer_code  = upd_change_rec2.customer_code
        AND    xrvspc.delivery_date  = upd_change_rec2.delivery_date
        AND    xrvspc.request_id     = cn_request_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcos_00011 -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                         , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
    END LOOP clear_change2_loop;
    --
    -- �J�[�\���N���[�Y
    CLOSE upd_change_cur2;
--
    -- �����I�����������O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || '4' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_cnt
    );
    -- ���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
-- 2013/02/20 Ver1.1 Add End
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- 2013/02/20 Ver1.1 Del Start
--      IF ( upd_disp_cur%ISOPEN ) THEN
--        CLOSE upd_disp_cur;
--      END IF;
-- 2013/02/20 Ver1.1 Del End
-- 2013/02/20 Ver1.1 Add Start
      IF ( upd_change_cur1%ISOPEN ) THEN
        CLOSE upd_change_cur1;
      END IF;
      IF ( upd_change_cur2%ISOPEN ) THEN
        CLOSE upd_change_cur2;
      END IF;
-- 2013/02/20 Ver1.1 Add End
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_rep_work_data;
--
  /**********************************************************************************
   * Procedure Name   : exe_svf
   * Description      : SVF�N������(A-14)
   ***********************************************************************************/
  PROCEDURE exe_svf(
     ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ,ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
    ,ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exe_svf'; -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    lv_nodata_msg    VARCHAR2(5000); -- 0�����b�Z�[�W
    lv_file_name     VARCHAR2(5000); -- �t�@�C����
    lv_msg_tnk       VARCHAR2(100);  -- ���b�Z�[�W�g�[�N���p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ����0���p���b�Z�[�W�擾
    lv_nodata_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_msg_xxcos_00018 --���b�Z�[�W�R�[�h
                      );
    --�o�̓t�@�C�����ҏW
    lv_file_name  := cv_pkg_name                                      || -- �v���O����ID(�p�b�P�[�W��)
                     TO_CHAR( cd_creation_date, cv_format_yyyymmdd1 ) || -- ���t
                     TO_CHAR( cn_request_id )                         || -- �v��ID
                     cv_extension_pdf                                    -- �g���q(PDF)
                     ;
    --==================================
    -- SVF�N��
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_retcode      => lv_retcode               -- ���^�[���R�[�h
      , ov_errbuf       => lv_errbuf                -- �G���[���b�Z�[�W
      , ov_errmsg       => lv_errmsg                -- ���[�U�[�E�G���[���b�Z�[�W
      , iv_conc_name    => cv_pkg_name              -- �R���J�����g��
      , iv_file_name    => lv_file_name             -- �o�̓t�@�C����
      , iv_file_id      => cv_pkg_name              -- ���[ID
      , iv_output_mode  => cv_output_mode_pdf       -- �o�͋敪
      , iv_frm_file     => cv_frm_name              -- �t�H�[���l���t�@�C����
      , iv_vrq_file     => cv_vrq_name              -- �N�G���[�l���t�@�C����
      , iv_org_id       => NULL                     -- ORG_ID
      , iv_user_name    => NULL                     -- ���O�C���E���[�U��
      , iv_resp_name    => NULL                     -- ���O�C���E���[�U�̐E�Ӗ�
      , iv_doc_name     => NULL                     -- ������
      , iv_printer_name => NULL                     -- �v�����^��
      , iv_request_id   => TO_CHAR( cn_request_id ) -- �v��ID
      , iv_nodata_msg   => lv_nodata_msg            -- �f�[�^�Ȃ����b�Z�[�W
      , iv_svf_param1   => NULL                     -- svf�σp�����[�^1
      , iv_svf_param2   => NULL                     -- svf�σp�����[�^2
      , iv_svf_param3   => NULL                     -- svf�σp�����[�^3
      , iv_svf_param4   => NULL                     -- svf�σp�����[�^4
      , iv_svf_param5   => NULL                     -- svf�σp�����[�^5
      , iv_svf_param6   => NULL                     -- svf�σp�����[�^6
      , iv_svf_param7   => NULL                     -- svf�σp�����[�^7
      , iv_svf_param8   => NULL                     -- svf�σp�����[�^8
      , iv_svf_param9   => NULL                     -- svf�σp�����[�^9
      , iv_svf_param10  => NULL                     -- svf�σp�����[�^10
      , iv_svf_param11  => NULL                     -- svf�σp�����[�^11
      , iv_svf_param12  => NULL                     -- svf�σp�����[�^12
      , iv_svf_param13  => NULL                     -- svf�σp�����[�^13
      , iv_svf_param14  => NULL                     -- svf�σp�����[�^14
      , iv_svf_param15  => NULL                     -- svf�σp�����[�^15
    );
    --SVF�������ʊm�F
    IF  ( lv_retcode  <> cv_status_normal ) THEN
      -- �g�[�N���擾
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                        iv_application => cv_application     -- �A�v���P�[�V�����Z�k��
                      , iv_name        => cv_msg_xxcos_00041 -- SVF�N��API
                    );
      -- ���b�Z�[�W�擾
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_xxcos_00017 -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_api_name    -- �g�[�N���R�[�h1
                      , iv_token_value1 => lv_msg_tnk         -- �g�[�N���l1
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END exe_svf;
--
  /**********************************************************************************
   * Procedure Name   : del_rep_work_data
   * Description      : ���[���[�N�e�[�u�����폜����(A-15)
   ***********************************************************************************/
  PROCEDURE del_rep_work_data(
    ov_errbuf        OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_work_data'; -- �v���O������
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
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- �x���_�[����E�����ƍ��\���[���[�N�e�[�u�����b�N�p�J�[�\��
    CURSOR lock_rep_table_cur
    IS
      SELECT 1
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.request_id = cn_request_id
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
    --=========================================
    -- �x���_�[����E�����ƍ��\���[���[�N�e�[�u�����b�N
    --=========================================
    BEGIN
      -- �I�[�v��
      OPEN lock_rep_table_cur;
      -- �N���[�Y
      CLOSE lock_rep_table_cur;
      --
    EXCEPTION
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                       , iv_name         => cv_msg_xxcos_00001 -- ���b�Z�[�W�R�[�h
                       , iv_token_name1  => cv_tkn_table       -- �g�[�N���R�[�h1
                       , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --=========================================
    -- �x���_�[����E�����ƍ��\���[���[�N�e�[�u���폜
    --=========================================
    BEGIN
      DELETE FROM xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE       xrvspc.request_id = cn_request_id
      ;
    EXCEPTION
       WHEN OTHERS THEN
         lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- �A�v���P�[�V�����Z�k��
                        , iv_name         => cv_msg_xxcos_00012 -- ���b�Z�[�W�R�[�h
                        , iv_token_name1  => cv_tkn_table_name  -- �g�[�N���R�[�h1
                        , iv_token_value1 => gv_msg_xxcos_14502 -- �g�[�N���l1
                        , iv_token_name2  => cv_tkn_key_data    -- �g�[�N���R�[�h2
                        , iv_token_value2 => SQLERRM            -- �g�[�N���l2
                      );
         lv_errbuf := lv_errmsg;
         RAISE global_process_expt;
    END;
--
    -- �����I�����������O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
    );
    -- ���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- �G���[�ƂȂ����Ƃ��AROLLBACK�����̂ł����ŃR�~�b�g
    COMMIT;
    -- ���������擾
    gn_normal_cnt := gn_target_cnt;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( lock_rep_table_cur%ISOPEN ) THEN
        CLOSE lock_rep_table_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_rep_work_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_manager_flag     IN  VARCHAR2, -- �Ǘ��҃t���O
    iv_yymm_from        IN  VARCHAR2, -- �N���iFrom�j
    iv_yymm_to          IN  VARCHAR2, -- �N���iTo�j
    iv_base_code        IN  VARCHAR2, -- ���_�R�[�h
    iv_dlv_by_code      IN  VARCHAR2, -- �c�ƈ��R�[�h
    iv_cust_code        IN  VARCHAR2, -- �ڋq�R�[�h
    iv_overs_and_shorts IN  VARCHAR2, -- �����ߕs��
    iv_counter_error    IN  VARCHAR2, -- �J�E���^�덷
    ov_errbuf           OUT VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_errbuf_svf             VARCHAR2(5000);  -- �G���[�E���b�Z�[�W(SVF�G���[���ޔ�p)
    lv_retcode_svf            VARCHAR2(1);     -- ���^�[���E�R�[�h(SVF�G���[���ޔ�p)
    lv_errmsg_svf             VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W(SVF�G���[���ޔ�p)
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
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
        iv_manager_flag     -- �Ǘ��҃t���O
      , iv_yymm_from        -- �N���iFrom�j
      , iv_yymm_to          -- �N���iTo�j
      , iv_base_code        -- ���_�R�[�h
      , iv_dlv_by_code      -- �c�ƈ��R�[�h
      , iv_cust_code        -- �ڋq�R�[�h
      , iv_overs_and_shorts -- �����ߕs��
      , iv_counter_error    -- �J�E���^�덷
      , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �̔����я��擾����(A-2)�A���[���[�N�e�[�u���o�^�����i�̔����я��j(A-3)
    -- ===============================
    ins_get_sales_exp_data(
        iv_base_code                -- ���_�R�[�h
      , iv_dlv_by_code              -- �c�ƈ��R�[�h
      , iv_cust_code                -- �ڋq�R�[�h
      , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2013/03/18 Ver1.2 Mod Start
--    -- 1���ȏ㒠�[���[�N�e�[�u���ɓo�^�����ꍇ
--    IF ( gn_ins_cnt > 0 ) THEN
--      --
--      -- ===============================
--      -- �������擾����(A-4)�A���[���[�N�e�[�u���o�^�E�X�V�����i�������j(A-5)
--      -- ===============================
--      upd_get_payment_data(
--          iv_base_code                -- ���_�R�[�h
--        , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
--        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
--        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--      );
--      --
--      IF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
    -- ===============================
    -- �������擾����(A-4)�A���[���[�N�e�[�u���o�^�E�X�V�����i�������j(A-5)
    -- ===============================
    upd_get_payment_data(
        iv_base_code                -- ���_�R�[�h
      , iv_dlv_by_code              -- �c�ƈ��R�[�h
      , iv_cust_code                -- �ڋq�R�[�h
      , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- 1���ȏ㒠�[���[�N�e�[�u���ɓo�^�����ꍇ
    IF ( gn_ins_cnt > 0 ) THEN
      --
-- 2013/03/18 Ver1.2 Mod End
--
      -- ===============================
      -- �ޑK�i�c���j���擾����(A-6)�A���[���[�N�e�[�u���X�V�����i�ޑK�i�c���j���j(A-7)
      -- ===============================
      upd_get_balance_data(
          iv_base_code                -- ���_�R�[�h
        , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �ޑK�i�x���j���擾����(A-8)�A���[���[�N�e�[�u���X�V�����i�ޑK�i�x���j���j(A-9)
      -- ===============================
      upd_get_check_data(
          iv_base_code                -- ���_�R�[�h
        , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- �ޑK�i�߂��j���擾����(A-10)���[���[�N�e�[�u���X�V�����i�ޑK�i�߂��j���j(A-11)
      -- ===============================
      upd_get_return_data(
          iv_base_code                -- ���_�R�[�h
        , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- �����ߕs���܂��̓J�E���^�덷��'1'�i0�ȊO�̂��̂��o�́j�̏ꍇ
      IF ( ( iv_overs_and_shorts = cv_cust_sum_out_div_1 )
        OR ( iv_counter_error    = cv_cust_sum_out_div_1 ) )
      THEN
        -- ===============================
        -- ���[���[�N�e�[�u�����폜�����i0�ȊO�j(A-12)
        -- ===============================
        del_rep_work_no_0_data(
            iv_overs_and_shorts -- �����ߕs��
          , iv_counter_error    -- �J�E���^�덷
          , lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
          , lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
          , lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
--
      -- ===============================
      -- ���[���[�N�e�[�u���X�V�����i�ޑK���A�������j(A-13)
      -- ===============================
      upd_rep_work_data(
          lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- �Ώی����擾
    SELECT COUNT(1)                   AS cnt
    INTO   gn_target_cnt
    FROM   xxcos_rep_vd_sales_pay_chk xrvspc
    WHERE  xrvspc.request_id = cn_request_id
    ;
--
    -- COMMIT���s
    COMMIT;
--
    -- ===============================
    -- SVF�N������(A-14)
    -- ===============================
    exe_svf(
        lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      --���[�N�폜�ׁ̈A���ʂ�ޔ�
      lv_errbuf_svf  := lv_errbuf;
      lv_retcode_svf := lv_retcode;
      lv_errmsg_svf  := lv_errmsg;
    END IF;
--
    -- ���[���[�N�e�[�u���Ƀf�[�^�����݂���ꍇ
    IF ( gn_target_cnt > 0 ) THEN
      -- ===============================
      -- ���[���[�N�e�[�u�����폜����(A-15)
      -- ===============================
      del_rep_work_data(
          lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
        , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
        , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
    END IF;
--
    -- SVF���s���ʔ��f
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf     := lv_errbuf_svf;
      lv_errmsg     := lv_errmsg_svf;
      RAISE global_process_expt;
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
    errbuf              OUT VARCHAR2, -- �G���[���b�Z�[�W #�Œ�#
    retcode             OUT VARCHAR2, -- �G���[�R�[�h     #�Œ�#
    iv_manager_flag     IN  VARCHAR2, -- �Ǘ��҃t���O
    iv_yymm_from        IN  VARCHAR2, -- �N���iFrom�j
    iv_yymm_to          IN  VARCHAR2, -- �N���iTo�j
    iv_base_code        IN  VARCHAR2, -- ���_�R�[�h
    iv_dlv_by_code      IN  VARCHAR2, -- �c�ƈ��R�[�h
    iv_cust_code        IN  VARCHAR2, -- �ڋq�R�[�h
    iv_overs_and_shorts IN  VARCHAR2, -- �����ߕs��
    iv_counter_error    IN  VARCHAR2  -- �J�E���^�덷
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_log_header_log  CONSTANT VARCHAR2(3)   := 'LOG';              -- ���O
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
        iv_manager_flag             -- �Ǘ��҃t���O
      , iv_yymm_from                -- �N���iFrom�j
      , iv_yymm_to                  -- �N���iTo�j
      , iv_base_code                -- ���_�R�[�h
      , iv_dlv_by_code              -- �c�ƈ��R�[�h
      , iv_cust_code                -- �ڋq�R�[�h
      , iv_overs_and_shorts         -- �����ߕs��
      , iv_counter_error            -- �J�E���^�덷
      , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      --
      gn_target_cnt  := 0;
      gn_normal_cnt  := 0;
      gn_error_cnt   := 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
--
    -- �Ώۃf�[�^0����
    IF ( ( gn_target_cnt = 0 ) AND ( gn_error_cnt = 0 ) ) THEN
      -- �x���I��
      lv_retcode := cv_status_warn;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
END XXCOS002A07R;
/
