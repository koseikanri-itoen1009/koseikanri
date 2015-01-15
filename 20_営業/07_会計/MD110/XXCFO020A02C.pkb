CREATE OR REPLACE PACKAGE BODY XXCFO020A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A02C(body)
 * Description      : �󕥎���i���Y�j�d��IF�쐬
 * MD.050           : �󕥎���i���Y�j�d��IF�쐬<MD050_CFO_020_A02>
 * Version          : 1.0
 *
 * Program List
 * ------------------------------- ----------------------------------------------------------
 *  Name                           Description
 * ------------------------------- ----------------------------------------------------------
 *  init                           ��������(A-1)
 *  check_period_name              ��v���ԃ`�F�b�N(A-2)
 *  get_journal_oif_data           �d��OIF��񒊏o(A-3),�d��OIF���ҏW(A-4)
 *  ins_journal_oif                �d��OIF�o�^(A-5)
 *  upd_gme_material_details_data  ���Y�����ڍ׃f�[�^�X�V(A-6)
 *  ins_mfg_if_control             �A�g�Ǘ��e�[�u���o�^(A-7)
 *  submain                        ���C�������v���V�[�W��
 *  main                           �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-10-30    1.0   Y.Shoji          �V�K�쐬
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO020A02C';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_cmn      CONSTANT VARCHAR2(10)  := 'XXCMN';
  cv_appl_short_name_cfo      CONSTANT VARCHAR2(10)  := 'XXCFO';
--
  -- ���b�Z�[�W�R�[�h
  cv_msg_cfo_00001            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00001';        -- �v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00019            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00019';        -- ���b�N�G���[
  cv_msg_cfo_10020            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10020';        -- �X�V�G���[
  cv_msg_cfo_00024            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00024';        -- �o�^�G���[���b�Z�[�W
  cv_msg_cfo_10043            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10043';        -- �Ώۃf�[�^�����G���[
  cv_msg_cfo_10047            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10047';        -- ���ʊ֐��G���[
  cv_msg_cfo_10052            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10052';        -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
--
  -- �g�[�N��
  cv_tkn_prof_name            CONSTANT VARCHAR2(10)  := 'PROF_NAME';               -- �g�[�N���F�v���t�@�C����
  cv_tkn_table                CONSTANT VARCHAR2(10)  := 'TABLE';                   -- �g�[�N���F�e�[�u��
  cv_tkn_errmsg               CONSTANT VARCHAR2(10)  := 'ERRMSG';                  -- �g�[�N���F�G���[���e
  cv_tkn_data                 CONSTANT VARCHAR2(10)  := 'DATA';                    -- �g�[�N���F�f�[�^
  cv_tkn_item                 CONSTANT VARCHAR2(10)  := 'ITEM';                    -- �g�[�N���F�i��
  cv_tkn_key                  CONSTANT VARCHAR2(10)  := 'KEY';                     -- �g�[�N���F�L�[
  cv_tkn_err_msg              CONSTANT VARCHAR2(10)  := 'ERR_MSG';                 -- �g�[�N���F�G���[���b�Z�[�W
  -- CCID�p�g�[�N��
  cv_tkn_process_date         CONSTANT VARCHAR2(12)  := 'PROCESS_DATE';            -- �g�[�N���F������
  cv_tkn_com_code             CONSTANT VARCHAR2(10)  := 'COM_CODE';                -- �g�[�N���F��ЃR�[�h
  cv_tkn_dept_code            CONSTANT VARCHAR2(10)  := 'DEPT_CODE';               -- �g�[�N���F����R�[�h
  cv_tkn_acc_code             CONSTANT VARCHAR2(10)  := 'ACC_CODE';                -- �g�[�N���F����ȖڃR�[�h
  cv_tkn_ass_code             CONSTANT VARCHAR2(10)  := 'ASS_CODE';                -- �g�[�N���F�⏕�ȖڃR�[�h
  cv_tkn_cust_code            CONSTANT VARCHAR2(10)  := 'CUST_CODE';               -- �g�[�N���F�ڋq�R�[�h�_�~�[�l
  cv_tkn_ent_code             CONSTANT VARCHAR2(10)  := 'ENT_CODE';                -- �g�[�N���F��ƃR�[�h�_�~�[�l
  cv_tkn_res1_code            CONSTANT VARCHAR2(10)  := 'RES1_CODE';               -- �g�[�N���F�\��1�_�~�[�l
  cv_tkn_res2_code            CONSTANT VARCHAR2(10)  := 'RES2_CODE';               -- �g�[�N���F�\��2�_�~�[�l
--
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
--
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_REC_PAY';         -- XXCFO:�d��p�^�[��_�󕥎c���\
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_CATEGORY_MFG_BATCH';  -- XXCFO:�d��J�e�S��_�󕥁i���Y�j
--
  cv_gloif_cr                 CONSTANT VARCHAR2(2)   := 'CR';                        -- �ݕ�
  cv_gloif_dr                 CONSTANT VARCHAR2(2)   := 'DR';                        -- �ؕ�
--
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- �t���O:N
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- �t���O:Y
--
  cv_process_no_01            CONSTANT VARCHAR2(2)   := '01';                        -- (1)��� ������U�֕��i�����i���猴���ցj
  cv_process_no_02            CONSTANT VARCHAR2(2)   := '02';                        -- (2)���Y���o
  cv_process_no_03            CONSTANT VARCHAR2(2)   := '03';                        -- (3)���ꕥ�o
  cv_process_no_04            CONSTANT VARCHAR2(2)   := '04';                        -- (4)��Z�b�g���o
  cv_process_no_06            CONSTANT VARCHAR2(2)   := '06';                        -- (5)���o ������U�֕��i�����E�����i�ցj
  cv_process_no_07            CONSTANT VARCHAR2(2)   := '07';                        -- (6)�I�����Ձi�����A���ށA�����i�j
--
  -- ���b�Z�[�W�o�͒l
  cv_mesg_out_data_01         CONSTANT VARCHAR2(20)  := '�󒍖���';
  --
  cv_mesg_out_item_01         CONSTANT VARCHAR2(24)  := '�󒍃w�b�_ID�A�󒍖���ID';
  --
  cv_mesg_out_table_01        CONSTANT VARCHAR2(20)  := '�d��OIF';
  cv_mesg_out_table_02        CONSTANT VARCHAR2(20)  := '���Y�����ڍ�';
  cv_mesg_out_table_03        CONSTANT VARCHAR2(20)  := '�󒍖���';
  cv_mesg_out_table_04        CONSTANT VARCHAR2(20)  := '�A�g�Ǘ��e�[�u��';
--
  -- ���t�����ϊ��֘A
  cv_fdy                      CONSTANT VARCHAR2(02) := '01';                       --�������t
  cv_d_format                 CONSTANT VARCHAR2(30) := 'YYYYMMDD';
  cv_m_format                 CONSTANT VARCHAR2(30) := 'YYYYMM';
  cv_e_time                   CONSTANT VARCHAR2(10) := ' 23:59:59';
  cv_dt_format                CONSTANT VARCHAR2(30) := 'YYYYMMDD HH24:MI:SS';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�v���t�@�C���擾
  gn_org_id_mfg               NUMBER        DEFAULT NULL;    -- �g�DID (���Y)
  gn_sales_set_of_bks_id      NUMBER        DEFAULT NULL;    -- �c�ƃV�X�e����v����ID
  gv_company_code_mfg         VARCHAR2(100) DEFAULT NULL;    -- ��ЃR�[�h�i�H��j
  gv_aff5_customer_dummy      VARCHAR2(100) DEFAULT NULL;    -- �ڋq�R�[�h_�_�~�[�l
  gv_aff6_company_dummy       VARCHAR2(100) DEFAULT NULL;    -- ��ƃR�[�h_�_�~�[�l
  gv_aff7_preliminary1_dummy  VARCHAR2(100) DEFAULT NULL;    -- �\��1_�_�~�[�l
  gv_aff8_preliminary2_dummy  VARCHAR2(100) DEFAULT NULL;    -- �\��2_�_�~�[�l
  gv_je_invoice_source_mfg    VARCHAR2(100) DEFAULT NULL;    -- �d��\�[�X_���Y�V�X�e��
  gv_sales_set_of_bks_name    VARCHAR2(100) DEFAULT NULL;    -- �c�ƃV�X�e����v���떼
  gv_currency_code            VARCHAR2(100) DEFAULT NULL;    -- �c�ƃV�X�e���@�\�ʉ݃R�[�h
  gv_je_ptn_rec_pay           VARCHAR2(100) DEFAULT NULL;    -- XXCFO:�d��p�^�[��_�󕥎c���\
  gv_je_category_mfg_batch    VARCHAR2(100) DEFAULT NULL;    -- XXCFO:�d��J�e�S��_�󕥁i���Y�j
  gd_process_date             DATE          DEFAULT NULL;    -- �Ɩ����t
--
  gv_period_name              VARCHAR2(7)   DEFAULT NULL;    -- ���̓p�����[�^�D��v���ԁiYYYY-MM�j
  gv_period_name2             VARCHAR2(6)   DEFAULT NULL;    -- ���̓p�����[�^�D��v���ԁiYYYYMM�j�̑O��
  gv_period_name3             VARCHAR2(6)   DEFAULT NULL;    -- ���̓p�����[�^�D��v���ԁiYYYYMM�j
  gd_target_date_from         DATE          DEFAULT NULL;    -- ���o�Ώۓ��tFROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- ���o�Ώۓ��tTO
--
  gn_price_all                NUMBER        DEFAULT 0;       -- �������P�ʁF���z
  gv_item_class_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�i�ڋ敪
  gv_prod_class_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF���i�敪
  gv_ptn_siwake               VARCHAR2(100) DEFAULT NULL;    -- �d��p�^�[��
  gv_whse_code                VARCHAR2(100) DEFAULT NULL;    -- �q�ɃR�[�h
  gv_warehouse_code           VARCHAR2(100) DEFAULT NULL;    -- �q�ɃR�[�h�i����Ȗڎ擾�p�j
  gv_process_no               VARCHAR2(2)   DEFAULT NULL;    -- �����ԍ�
--
  -- ===============================
  -- ���[�U�[��`�v���C�x�[�g�^
  -- ===============================
  -- ���Y�����ڍ׃f�[�^�X�V���i�[�p
  TYPE g_gme_material_details_rec IS RECORD
    (
      material_detail_id      NUMBER                         -- ���Y�����ڍ�ID
    );
  TYPE g_gme_material_details_ttype IS TABLE OF g_gme_material_details_rec INDEX BY PLS_INTEGER;
--
  -- ���Y����f�[�^�X�V���i�[�p
  TYPE g_oe_order_lines_rec IS RECORD
    (
      header_id               NUMBER                         -- �󒍃w�b�_ID
     ,line_id                 NUMBER                         -- �󒍖���ID
    );
  TYPE g_oe_order_lines_ttype IS TABLE OF g_oe_order_lines_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�v���C�x�[�g�ϐ�
  -- ===============================
  -- ���Y�����ڍ׃f�[�^�X�V���i�[�pPL/SQL�\
  g_gme_material_details_tab      g_gme_material_details_ttype;
--
  -- ===============================
  -- �O���[�o����O
  -- ===============================
--
  global_lock_expt                   EXCEPTION; -- ���b�N(�r�W�[)�G���[
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --==============================================================
    -- 1  �p�����[�^�o��
    --==============================================================
    -- ���b�Z�[�W�o��
    xxcfr_common_pkg.put_log_param(
        iv_which                    =>  cv_file_type_out    -- ���b�Z�[�W�o��
      , iv_conc_param1              =>  iv_period_name      -- 1.��v����
      , ov_errbuf                   =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                  =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                   =>  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ���O�o��
    xxcfr_common_pkg.put_log_param(
        iv_which                    =>  cv_file_type_log    -- ���O�o��
      , iv_conc_param1              =>  iv_period_name      -- 1.��v����
      , ov_errbuf                   =>  lv_errbuf           -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                  =>  lv_retcode          -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                   =>  lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2-1  �Ɩ��������t�A�v���t�@�C���l�̎擾
    --==============================================================
    xxcfo_common_pkg3.init_proc(
        ov_company_code_mfg         =>  gv_company_code_mfg         -- ��ЃR�[�h�i�H��j
      , ov_aff5_customer_dummy      =>  gv_aff5_customer_dummy      -- �ڋq�R�[�h_�_�~�[�l
      , ov_aff6_company_dummy       =>  gv_aff6_company_dummy       -- ��ƃR�[�h_�_�~�[�l
      , ov_aff7_preliminary1_dummy  =>  gv_aff7_preliminary1_dummy  -- �\��1_�_�~�[�l
      , ov_aff8_preliminary2_dummy  =>  gv_aff8_preliminary2_dummy  -- �\��2_�_�~�[�l
      , ov_je_invoice_source_mfg    =>  gv_je_invoice_source_mfg    -- �d��\�[�X_���Y�V�X�e��
      , on_org_id_mfg               =>  gn_org_id_mfg               -- ���YORG_ID
      , on_sales_set_of_bks_id      =>  gn_sales_set_of_bks_id      -- �c�ƃV�X�e����v����ID
      , ov_sales_set_of_bks_name    =>  gv_sales_set_of_bks_name    -- �c�ƃV�X�e����v���떼
      , ov_currency_code            =>  gv_currency_code            -- �c�ƃV�X�e���@�\�ʉ݃R�[�h
      , od_process_date             =>  gd_process_date             -- �Ɩ����t
      , ov_errbuf                   =>  lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                  =>  lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                   =>  lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo -- �A�v���P�[�V�����Z�k��
                , iv_name         => cv_msg_cfo_10047       -- ���b�Z�[�W�FAPP-XXCFO1-10047
                , iv_token_name1  => cv_tkn_err_msg         -- �g�[�N���R�[�h
                , iv_token_value1 => lv_errmsg);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2-2  �v���t�@�C���l�̎擾
    --==============================================================
    -- XXCFO:�d��p�^�[��_�󕥎c���\
    gv_je_ptn_rec_pay  := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_je_ptn_rec_pay IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cfo  -- �A�v���P�[�V�����Z�k���FXXCFO ��v
                    , iv_name           => cv_msg_cfo_00001        -- ���b�Z�[�W�FAPP-XXCFO-10001 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_prof_name        -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_01
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO: �d��J�e�S��_�󕥁i���Y�j
    gv_je_category_mfg_batch  := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_je_category_mfg_batch IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cfo  -- �A�v���P�[�V�����Z�k���FXXCFO ��v
                    , iv_name           => cv_msg_cfo_00001        -- ���b�Z�[�W�FAPP-XXCFO-10001 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_prof_name        -- �g�[�N���FNG_PROFILE
                    , iv_token_value1   => cv_profile_name_02
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ���̓p�����[�^�̉�v���Ԃ���A���o�Ώۓ��tFROM-TO���Z�o
    gd_target_date_from  := TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format);
    gd_target_date_to    := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
    -- ���̓p�����[�^�̉�v���Ԃ��Z�b�g
    gv_period_name       := iv_period_name;
    gv_period_name2      := TO_CHAR(ADD_MONTHS(TO_DATE(REPLACE(iv_period_name,'-') ,cv_m_format), -1), cv_m_format);
    gv_period_name3      := REPLACE(iv_period_name,'-');
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : check_period_name
   * Description      : ��v���ԃ`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE check_period_name(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_period_name'; -- �v���O������
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
    -- 1.  �d��쐬�p��v���ԃ`�F�b�N
    --==============================================================
    xxcfo_common_pkg3.chk_period_status(
        iv_period_name                  => iv_period_name              -- ��v���ԁiYYYY-MM)
      , in_sales_set_of_bks_id          => gn_sales_set_of_bks_id      -- ��v����ID
      , ov_errbuf                       => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       => lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo -- �A�v���P�[�V�����Z�k��
                , iv_name         => cv_msg_cfo_10047       -- ���b�Z�[�W�FAPP-XXCFO1-10047
                , iv_token_name1  => cv_tkn_err_msg         -- �g�[�N���R�[�h
                , iv_token_value1 => lv_errmsg);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.  �d��쐬�pGL�A�g�`�F�b�N
    --==============================================================
    xxcfo_common_pkg3.chk_gl_if_status(
        iv_period_name                  => iv_period_name              -- ��v���ԁiYYYY-MM)
      , in_sales_set_of_bks_id          => gn_sales_set_of_bks_id      -- ��v����ID
      , iv_func_name                    => cv_pkg_name                 -- �@�\���i�R���J�����g�Z�k���j
      , ov_errbuf                       => lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode                      => lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg                       => lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo -- �A�v���P�[�V�����Z�k��
                , iv_name         => cv_msg_cfo_10047       -- ���b�Z�[�W�FAPP-XXCFO1-10047
                , iv_token_name1  => cv_tkn_err_msg         -- �g�[�N���R�[�h
                , iv_token_value1 => lv_errmsg);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END check_period_name;
--
  /**********************************************************************************
   * Procedure Name   : ins_journal_oif
   * Description      : �d��OIF�o�^(A-5)
   ***********************************************************************************/
  PROCEDURE ins_journal_oif(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_journal_oif'; -- �v���O������
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
    cv_under_score              CONSTANT VARCHAR2(1)   := '_';           -- ���p�A���_�[�X�R�A
    cv_half_space               CONSTANT VARCHAR2(1)   := ' ';           -- ���p�X�y�[�X
    cv_status_new               CONSTANT VARCHAR2(3)   := 'NEW';         -- �X�e�[�^�X
    cv_actual_flag_a            CONSTANT VARCHAR2(1)   := 'A';           -- �c���^�C�v
    cn_group_id_1               CONSTANT NUMBER        := 1;
--
    -- *** ���[�J���ϐ� ***
    lv_company_code             VARCHAR2(100)     DEFAULT NULL;     -- ���
    lv_department_code          VARCHAR2(100)     DEFAULT NULL;     -- ����
    lv_account_title            VARCHAR2(100)     DEFAULT NULL;     -- ����Ȗ�
    lv_account_subsidiary       VARCHAR2(100)     DEFAULT NULL;     -- �⏕�Ȗ�
    lv_description_dr           VARCHAR2(100)     DEFAULT NULL;     -- �ؕ��E�v
    lv_description_cr           VARCHAR2(100)     DEFAULT NULL;     -- �ݕ��E�v
    lv_whse_name                VARCHAR2(100)     DEFAULT NULL;     -- �q�ɖ���
    lv_reference1               VARCHAR2(100)     DEFAULT NULL;     -- �Q�ƍ���1�i�o�b�`���j
    lv_reference2               VARCHAR2(100)     DEFAULT NULL;     -- �Q�ƍ���2�i�o�b�`�E�v�j
    lv_reference4               VARCHAR2(100)     DEFAULT NULL;     -- �Q�ƍ���4�i�d�󖼁j
    lv_reference5               VARCHAR2(100)     DEFAULT NULL;     -- �Q�ƍ���5�i�d�󖼓E�v�j�̎擾
    lv_gl_je_key                VARCHAR2(100)     DEFAULT NULL;     -- �d��L�[
    ln_entered_dr               NUMBER            DEFAULT NULL;     -- �ؕ����z
    ln_entered_cr               NUMBER            DEFAULT NULL;     -- �ݕ����z
    ln_code_combination_id      NUMBER            DEFAULT NULL;     -- CCID
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
    -- ===============================
    -- 1.���ʊ֐��i����Ȗڐ����@�\�j�E�ؕ��FDR
    -- ===============================
    -- ���ʊ֐����R�[������
    xxcfo020a06c.get_siwake_account_title(
        ov_retcode                  =>  lv_retcode                  -- ���^�[���R�[�h
      , ov_errbuf                   =>  lv_errbuf                   -- �G���[���b�Z�[�W
      , ov_errmsg                   =>  lv_errmsg                   -- ���[�U�[�E�G���[���b�Z�[�W
      , ov_company_code             =>  lv_company_code             -- (OUT)���
      , ov_department_code          =>  lv_department_code          -- (OUT)����
      , ov_account_title            =>  lv_account_title            -- (OUT)����Ȗ�
      , ov_account_subsidiary       =>  lv_account_subsidiary       -- (OUT)�⏕�Ȗ�
      , ov_description              =>  lv_description_dr           -- (OUT)�E�v
      , iv_report                   =>  gv_je_ptn_rec_pay           -- (IN)���[
      , iv_class_code               =>  gv_item_class_code_hdr      -- (IN)�i�ڋ敪
      , iv_prod_class               =>  gv_prod_class_code_hdr      -- (IN)���i�敪
      , iv_reason_code              =>  NULL                        -- (IN)���R�R�[�h
      , iv_ptn_siwake               =>  gv_ptn_siwake               -- (IN)�d��p�^�[��
      , iv_line_no                  =>  NULL                        -- (IN)�s�ԍ�
      , iv_gloif_dr_cr              =>  cv_gloif_dr                 -- (IN)�ؕ��FDR
      , iv_warehouse_code           =>  gv_warehouse_code           -- (IN)�q�ɃR�[�h
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo         -- �A�v���P�[�V�����Z�k��
                , iv_name         => cv_msg_cfo_10047               -- ���b�Z�[�W�FAPP-XXCFO1-10047
                , iv_token_name1  => cv_tkn_err_msg                 -- �g�[�N���R�[�h
                , iv_token_value1 => lv_errmsg
                );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 2.���ʊ֐��iCCID�擾�j�E�ؕ��FDR
    -- ===============================
    -- CCID���擾
    ln_code_combination_id := xxcok_common_pkg.get_code_combination_id_f(
                  id_proc_date => gd_target_date_to                 -- ������
                , iv_segment1  => lv_company_code                   -- ��ЃR�[�h
                , iv_segment2  => lv_department_code                -- ����R�[�h
                , iv_segment3  => lv_account_title                  -- ����ȖڃR�[�h
                , iv_segment4  => lv_account_subsidiary             -- �⏕�ȖڃR�[�h
                , iv_segment5  => gv_aff5_customer_dummy            -- �ڋq�R�[�h�_�~�[�l
                , iv_segment6  => gv_aff6_company_dummy             -- ��ƃR�[�h�_�~�[�l
                , iv_segment7  => gv_aff7_preliminary1_dummy        -- �\��1�_�~�[�l
                , iv_segment8  => gv_aff8_preliminary2_dummy        -- �\��2�_�~�[�l
    );
    IF ( ln_code_combination_id IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo
                      , iv_name         => cv_msg_cfo_10052            -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
                      , iv_token_name1  => cv_tkn_process_date
                      , iv_token_value1 => gd_target_date_to           -- ������
                      , iv_token_name2  => cv_tkn_com_code
                      , iv_token_value2 => lv_company_code             -- ��ЃR�[�h
                      , iv_token_name3  => cv_tkn_dept_code
                      , iv_token_value3 => lv_department_code          -- ����R�[�h
                      , iv_token_name4  => cv_tkn_acc_code
                      , iv_token_value4 => lv_account_title            -- ����ȖڃR�[�h
                      , iv_token_name5  => cv_tkn_ass_code
                      , iv_token_value5 => lv_account_subsidiary       -- �⏕�ȖڃR�[�h
                      , iv_token_name6  => cv_tkn_cust_code
                      , iv_token_value6 => gv_aff5_customer_dummy      -- �ڋq�R�[�h�_�~�[�l
                      , iv_token_name7  => cv_tkn_ent_code
                      , iv_token_value7 => gv_aff6_company_dummy       -- ��ƃR�[�h�_�~�[�l
                      , iv_token_name8  => cv_tkn_res1_code
                      , iv_token_value8 => gv_aff7_preliminary1_dummy  -- �\��1�_�~�[�l
                      , iv_token_name9  => cv_tkn_res2_code
                      , iv_token_value9 => gv_aff8_preliminary2_dummy  -- �\��2�_�~�[�l
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �ؕ����z�E�ݕ����z�̐ݒ�
    -- ===============================
    -- ���z���}�C�i�X�̏ꍇ
    IF ( gn_price_all < 0 ) THEN
      ln_entered_dr := 0;                 -- �ؕ����z
      ln_entered_cr := gn_price_all * -1; -- �ݕ����z
    -- ���z���}�C�i�X�ł͂Ȃ��ꍇ
    ELSIF ( gn_price_all >= 0 ) THEN
      ln_entered_dr := gn_price_all; -- �ؕ����z
      ln_entered_cr := 0;            -- �ݕ����z
    END IF;
--
    -- �Q�ƍ���1�i�o�b�`���j�̎擾
    lv_reference1 := gv_je_category_mfg_batch || cv_under_score || gv_period_name;
    -- �Q�ƍ���2�i�o�b�`�E�v�j�̎擾
    lv_reference2 := gv_je_category_mfg_batch || cv_under_score || gv_period_name;
    -- �Q�ƍ���4�i�d�󖼁j�̎擾
    lv_reference4 := xxcfo_gl_je_key_s1.NEXTVAL;
--
    -- �Q�ƍ���5�i�d�󖼓E�v�j�̎擾
    -- �����v�̏ꍇ
    IF ( gv_process_no IN ( cv_process_no_01
                           ,cv_process_no_03 
                           ,cv_process_no_06 ) ) THEN
      -- �d�󖼓E�v�̐ݒ�
      lv_reference5 := lv_description_dr;
    -- �q�ɕʂ̏ꍇ
    ELSIF ( gv_process_no IN ( cv_process_no_02
                              ,cv_process_no_04
                              ,cv_process_no_07 ) ) THEN
      -- �q�ɖ��̂��擾
      SELECT iwm.whse_name   AS whse_name     -- �q�ɖ���
      INTO   lv_whse_name
      FROM   ic_whse_mst     iwm              -- OPM�q�Ƀ}�X�^
      WHERE  iwm.whse_code = gv_whse_code
      ;
      -- �d�󖼓E�v�̐ݒ�
      lv_reference5 := lv_description_dr || cv_under_score || gv_whse_code || cv_half_space || lv_whse_name;
    END IF;
--
    -- �Q�ƍ���10 �d�󖾍דE�v�̎擾
    -- (2)���Y���o�̏ꍇ
    IF ( gv_process_no = cv_process_no_02 ) THEN
      -- �d�󖾍דE�v�̐ݒ�
      lv_description_dr := lv_description_dr || cv_half_space || gv_whse_code || lv_whse_name;
    -- (4)��Z�b�g���o�̏ꍇ
    ELSIF ( gv_process_no = cv_process_no_04 ) THEN
      -- �d�󖾍דE�v�̐ݒ�
      lv_description_dr := lv_description_dr || cv_half_space || lv_department_code;
    END IF;
--
    -- DFF8�̎擾
    IF ( gv_process_no = cv_process_no_07 ) THEN
      lv_gl_je_key  := NULL;
    ELSE
      lv_gl_je_key  := lv_reference4;
    END IF;
--
    -- ===============================
    -- 3.�d��OIF�o�^�E�ؕ��FDR
    -- ===============================
    BEGIN
      INSERT INTO gl_interface(
        status                       -- �X�e�[�^�X
       ,set_of_books_id              -- ��v����ID
       ,accounting_date              -- �L����
       ,currency_code                -- �ʉ݃R�[�h
       ,date_created                 -- �V�K�쐬���t
       ,created_by                   -- �V�K�쐬��ID
       ,actual_flag                  -- �c���^�C�v
       ,user_je_category_name        -- �d��J�e�S����
       ,user_je_source_name          -- �d��\�[�X��
       ,code_combination_id          -- CCID
       ,request_id                   -- �v��ID
       ,entered_dr                   -- �ؕ����z
       ,entered_cr                   -- �ݕ����z
       ,reference1                   -- �Q�ƍ���1 �o�b�`��
       ,reference2                   -- �Q�ƍ���2 �o�b�`�E�v
       ,reference4                   -- �Q�ƍ���4 �d��
       ,reference5                   -- �Q�ƍ���5 �d�󖼓E�v
       ,reference10                  -- �Q�ƍ���10 �d�󖾍דE�v
       ,period_name                  -- ��v���Ԗ�
       ,attribute1                   -- DFF1 �ŋ敪
       ,attribute3                   -- DFF3 �`�[�ԍ�
       ,attribute4                   -- DFF4 �N�[����
       ,attribute5                   -- DFF5 �`�[���͎�
       ,attribute8                   -- DFF8 �̔����уw�b�_ID
       ,context                      -- �R���e�L�X�g
       ,group_id
      )VALUES (
        cv_status_new                -- �X�e�[�^�X
       ,gn_sales_set_of_bks_id       -- ��v����ID
       ,TRUNC(gd_target_date_to)     -- �L����
       ,gv_currency_code             -- �ʉ݃R�[�h
       ,cd_creation_date             -- �V�K�쐬���t
       ,cn_created_by                -- �V�K�쐬��ID
       ,cv_actual_flag_a             -- �c���^�C�v
       ,gv_je_category_mfg_batch     -- �d��J�e�S����
       ,gv_je_invoice_source_mfg     -- �d��\�[�X��
       ,ln_code_combination_id       -- CCID
       ,cn_request_id                -- �v��ID
       ,ln_entered_dr                -- �ؕ����z
       ,ln_entered_cr                -- �ݕ����z
       ,lv_reference1                -- �Q�ƍ���1 �o�b�`��
       ,lv_reference2                -- �Q�ƍ���2 �o�b�`�E�v
       ,lv_reference4                -- �Q�ƍ���4 �d��
       ,lv_reference5                -- �Q�ƍ���5 �d�󖼓E�v
       ,lv_description_dr            -- �Q�ƍ���10 �d�󖾍דE�v
       ,gv_period_name               -- ��v���Ԗ�
       ,NULL                         -- DFF1 �ŋ敪
       ,NULL                         -- DFF3 �`�[�ԍ�
       ,lv_department_code           -- DFF4 �N�[����
       ,NULL                         -- DFF5 �`�[���͎�
       ,lv_gl_je_key                 -- DFF8 �̔����уw�b�_ID
       ,gv_sales_set_of_bks_name     -- �R���e�L�X�g
       ,cn_group_id_1
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_00024
                  , iv_token_name1  => cv_tkn_table                            -- �e�[�u��
                  , iv_token_value1 => cv_mesg_out_table_01                    -- AP������OIF�w�b�_�[
                  , iv_token_name2  => cv_tkn_errmsg                           -- �G���[���e
                  , iv_token_value2 => SQLERRM
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ===============================
    -- 1.���ʊ֐��i����Ȗڐ����@�\�j�E�ݕ��FCR
    -- ===============================
    -- ���ʊ֐����R�[������
    xxcfo020a06c.get_siwake_account_title(
        ov_retcode                  =>  lv_retcode                  -- ���^�[���R�[�h
      , ov_errbuf                   =>  lv_errbuf                   -- �G���[���b�Z�[�W
      , ov_errmsg                   =>  lv_errmsg                   -- ���[�U�[�E�G���[���b�Z�[�W
      , ov_company_code             =>  lv_company_code             -- (OUT)���
      , ov_department_code          =>  lv_department_code          -- (OUT)����
      , ov_account_title            =>  lv_account_title            -- (OUT)����Ȗ�
      , ov_account_subsidiary       =>  lv_account_subsidiary       -- (OUT)�⏕�Ȗ�
      , ov_description              =>  lv_description_cr           -- (OUT)�E�v
      , iv_report                   =>  gv_je_ptn_rec_pay           -- (IN)���[
      , iv_class_code               =>  gv_item_class_code_hdr      -- (IN)�i�ڋ敪
      , iv_prod_class               =>  gv_prod_class_code_hdr      -- (IN)���i�敪
      , iv_reason_code              =>  NULL                        -- (IN)���R�R�[�h
      , iv_ptn_siwake               =>  gv_ptn_siwake               -- (IN)�d��p�^�[��
      , iv_line_no                  =>  NULL                        -- (IN)�s�ԍ�
      , iv_gloif_dr_cr              =>  cv_gloif_cr                 -- (IN)�ݕ��FCR
      , iv_warehouse_code           =>  gv_warehouse_code           -- (IN)�q�ɃR�[�h
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo         -- �A�v���P�[�V�����Z�k��
                , iv_name         => cv_msg_cfo_10047               -- ���b�Z�[�W�FAPP-XXCFO1-10047
                , iv_token_name1  => cv_tkn_err_msg                 -- �g�[�N���R�[�h
                , iv_token_value1 => lv_errmsg
                );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 2.���ʊ֐��iCCID�擾�j�E�ݕ��FCR
    -- ===============================
    -- CCID���擾
    ln_code_combination_id := xxcok_common_pkg.get_code_combination_id_f(
                  id_proc_date => gd_target_date_to                 -- ������
                , iv_segment1  => lv_company_code                   -- ��ЃR�[�h
                , iv_segment2  => lv_department_code                -- ����R�[�h
                , iv_segment3  => lv_account_title                  -- ����ȖڃR�[�h
                , iv_segment4  => lv_account_subsidiary             -- �⏕�ȖڃR�[�h
                , iv_segment5  => gv_aff5_customer_dummy            -- �ڋq�R�[�h�_�~�[�l
                , iv_segment6  => gv_aff6_company_dummy             -- ��ƃR�[�h�_�~�[�l
                , iv_segment7  => gv_aff7_preliminary1_dummy        -- �\��1�_�~�[�l
                , iv_segment8  => gv_aff8_preliminary2_dummy        -- �\��2�_�~�[�l
    );
    IF ( ln_code_combination_id IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo
                      , iv_name         => cv_msg_cfo_10052            -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
                      , iv_token_name1  => cv_tkn_process_date
                      , iv_token_value1 => gd_target_date_to           -- ������
                      , iv_token_name2  => cv_tkn_com_code
                      , iv_token_value2 => lv_company_code             -- ��ЃR�[�h
                      , iv_token_name3  => cv_tkn_dept_code
                      , iv_token_value3 => lv_department_code          -- ����R�[�h
                      , iv_token_name4  => cv_tkn_acc_code
                      , iv_token_value4 => lv_account_title            -- ����ȖڃR�[�h
                      , iv_token_name5  => cv_tkn_ass_code
                      , iv_token_value5 => lv_account_subsidiary       -- �⏕�ȖڃR�[�h
                      , iv_token_name6  => cv_tkn_cust_code
                      , iv_token_value6 => gv_aff5_customer_dummy      -- �ڋq�R�[�h�_�~�[�l
                      , iv_token_name7  => cv_tkn_ent_code
                      , iv_token_value7 => gv_aff6_company_dummy       -- ��ƃR�[�h�_�~�[�l
                      , iv_token_name8  => cv_tkn_res1_code
                      , iv_token_value8 => gv_aff7_preliminary1_dummy  -- �\��1�_�~�[�l
                      , iv_token_name9  => cv_tkn_res2_code
                      , iv_token_value9 => gv_aff8_preliminary2_dummy  -- �\��2�_�~�[�l
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �ؕ����z�E�ݕ����z�̐ݒ�
    -- ===============================
    -- ���z���}�C�i�X�̏ꍇ
    IF ( gn_price_all < 0 ) THEN
      ln_entered_dr := gn_price_all * -1; -- �ؕ����z
      ln_entered_cr := 0;                 -- �ݕ����z
    -- ���z���}�C�i�X�ł͂Ȃ��ꍇ
    ELSIF ( gn_price_all >= 0 ) THEN
      ln_entered_dr := 0;            -- �ؕ����z
      ln_entered_cr := gn_price_all; -- �ݕ����z
    END IF;
--
    -- (2)���Y���o�̏ꍇ
    IF ( gv_process_no = cv_process_no_02 ) THEN
      -- �d�󖾍דE�v�̐ݒ�
      lv_description_cr := lv_description_cr || cv_half_space || gv_whse_code || lv_whse_name;
    -- (4)��Z�b�g���o�̏ꍇ
    ELSIF ( gv_process_no = cv_process_no_04 ) THEN
      -- �d�󖾍דE�v�̐ݒ�
      lv_description_cr := lv_description_cr || cv_half_space || lv_department_code;
    END IF;
--
    -- ===============================
    -- 3.�d��OIF�o�^�E�ݕ��FCR
    -- ===============================
    BEGIN
      INSERT INTO gl_interface(
        status                       -- �X�e�[�^�X
       ,set_of_books_id              -- ��v����ID
       ,accounting_date              -- �L����
       ,currency_code                -- �ʉ݃R�[�h
       ,date_created                 -- �V�K�쐬���t
       ,created_by                   -- �V�K�쐬��ID
       ,actual_flag                  -- �c���^�C�v
       ,user_je_category_name        -- �d��J�e�S����
       ,user_je_source_name          -- �d��\�[�X��
       ,code_combination_id          -- CCID
       ,request_id                   -- �v��ID
       ,entered_dr                   -- �ؕ����z
       ,entered_cr                   -- �ݕ����z
       ,reference1                   -- �Q�ƍ���1 �o�b�`��
       ,reference2                   -- �Q�ƍ���2 �o�b�`�E�v
       ,reference4                   -- �Q�ƍ���4 �d��
       ,reference5                   -- �Q�ƍ���5 �d�󖼓E�v
       ,reference10                  -- �Q�ƍ���10 �d�󖾍דE�v
       ,period_name                  -- ��v���Ԗ�
       ,attribute1                   -- DFF1 �ŋ敪
       ,attribute3                   -- DFF3 �`�[�ԍ�
       ,attribute4                   -- DFF4 �N�[����
       ,attribute5                   -- DFF5 �`�[���͎�
       ,attribute8                   -- DFF8 �̔����уw�b�_ID
       ,context                      -- �R���e�L�X�g
       ,group_id
      )VALUES (
        cv_status_new                -- �X�e�[�^�X
       ,gn_sales_set_of_bks_id       -- ��v����ID
       ,TRUNC(gd_target_date_to)     -- �L����
       ,gv_currency_code             -- �ʉ݃R�[�h
       ,cd_creation_date             -- �V�K�쐬���t
       ,cn_created_by                -- �V�K�쐬��ID
       ,cv_actual_flag_a             -- �c���^�C�v
       ,gv_je_category_mfg_batch     -- �d��J�e�S����
       ,gv_je_invoice_source_mfg     -- �d��\�[�X��
       ,ln_code_combination_id       -- CCID
       ,cn_request_id                -- �v��ID
       ,ln_entered_dr                -- �ؕ����z
       ,ln_entered_cr                -- �ݕ����z
       ,lv_reference1                -- �Q�ƍ���1 �o�b�`��
       ,lv_reference2                -- �Q�ƍ���2 �o�b�`�E�v
       ,lv_reference4                -- �Q�ƍ���4 �d��
       ,lv_reference5                -- �Q�ƍ���5 �d�󖼓E�v
       ,lv_description_cr            -- �Q�ƍ���10 �d�󖾍דE�v
       ,gv_period_name               -- ��v���Ԗ�
       ,NULL                         -- DFF1 �ŋ敪
       ,NULL                         -- DFF3 �`�[�ԍ�
       ,lv_department_code           -- DFF4 �N�[����
       ,NULL                         -- DFF5 �`�[���͎�
       ,lv_gl_je_key                 -- DFF8 �̔����уw�b�_ID
       ,gv_sales_set_of_bks_name     -- �R���e�L�X�g
       ,cn_group_id_1
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_00024
                  , iv_token_name1  => cv_tkn_table                            -- �e�[�u��
                  , iv_token_value1 => cv_mesg_out_table_01                    -- AP������OIF�w�b�_�[
                  , iv_token_name2  => cv_tkn_errmsg                           -- �G���[���e
                  , iv_token_value2 => SQLERRM
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END ins_journal_oif;
--
  /**********************************************************************************
   * Procedure Name   : upd_gme_material_details_data
   * Description      : ���Y�����ڍ׃f�[�^�X�V(A-6)
   ***********************************************************************************/
  PROCEDURE upd_gme_material_details_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_gme_material_details_data'; -- �v���O������
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
    ln_upd_cnt    NUMBER;
    lt_material_detail_id      gme_material_details.material_detail_id%TYPE;
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
    -- =========================================================
    -- ���Y�����ڍ׃e�[�u���ɑ΂��čs���b�N���擾
    -- =========================================================
    << lock_loop >>
    FOR ln_upd_cnt IN 1..g_gme_material_details_tab.COUNT LOOP
      BEGIN
        SELECT gmd.material_detail_id
        INTO   lt_material_detail_id
        FROM   gme_material_details gmd
        WHERE  gmd.material_detail_id = g_gme_material_details_tab(ln_upd_cnt).material_detail_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_tkn_table                        -- �e�[�u��
                    , iv_token_value1 => cv_mesg_out_table_02                -- ���Y�����ڍ�
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP lock_loop;
--
    BEGIN
      FORALL ln_upd_cnt IN 1..g_gme_material_details_tab.COUNT
        -- ����f�[�^�����ʂ����ӂȒl�𐶎Y�����ڍׂɍX�V
        UPDATE gme_material_details gmd
        SET    gmd.attribute27  = xxcfo_gl_je_key_s1.CURRVAL             -- �uA-5.�d��OIF�o�^�v�ō̔Ԃ����Q�ƍ���1 (�d��L�[)
        WHERE  gmd.material_detail_id = g_gme_material_details_tab(ln_upd_cnt).material_detail_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_10020
                  , iv_token_name1  => cv_tkn_table                        -- �e�[�u��
                  , iv_token_value1 => cv_mesg_out_table_02                -- ���Y�����ڍ�
                  , iv_token_name2  => cv_tkn_errmsg                       -- �A�C�e��
                  , iv_token_value2 => SQLERRM                             -- SQL�G���[���b�Z�[�W
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ���팏���J�E���g
    gn_normal_cnt := gn_normal_cnt + g_gme_material_details_tab.COUNT;
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
  END upd_gme_material_details_data;
--
  /**********************************************************************************
   * Procedure Name   : get_journal_oif_data
   * Description      : �d��OIF��񒊏o(A-3)
                        �d��OIF���ҏW(A-4)
   ***********************************************************************************/
  PROCEDURE get_journal_oif_data(
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_journal_oif_data'; -- �v���O������
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
    cn_price_all_0             CONSTANT NUMBER        := 0;                                -- ���z�F0
    cn_completed_ind_1         CONSTANT NUMBER        := 1;                                -- �����t���O�F1
    cn_trans_qty_0             CONSTANT NUMBER        := 0;                                -- ���ʁF0
    cn_rcv_pay_div_1           CONSTANT NUMBER        := 1;                                -- �󕥋敪�F1
    cn_rcv_pay_div_minus_1     CONSTANT NUMBER        := -1;                               -- �󕥋敪�F-1
    cv_line_type_1             CONSTANT VARCHAR2(1)   := '1';                              -- �����i
    cv_line_type_minus_1       CONSTANT VARCHAR2(2)   := '-1';                             -- �����i
    cv_req_status_4            CONSTANT VARCHAR2(2)   := '04';                             -- �o�׈˗��X�e�[�^�X�F�o�׎��ьv���
    cv_req_status_8            CONSTANT VARCHAR2(2)   := '08';                             -- �o�׈˗��X�e�[�^�X�F�o�׎��ьv���
    cv_latest_external_flag_y  CONSTANT VARCHAR2(1)   := 'Y';                              -- �ŐV�t���O�FY
    cv_document_type_code_10   CONSTANT VARCHAR2(2)   := '10';                             -- �����^�C�v�F�o�׈˗�
    cv_record_type_code_20     CONSTANT VARCHAR2(2)   := '20';                             -- ���R�[�h�^�C�v�F�o�Ɏ���
    cv_ship_prov_1             CONSTANT VARCHAR2(1)   := '1';                              -- �o�׎x���敪�F�o��
    cv_ship_prov_3             CONSTANT VARCHAR2(1)   := '3';                              -- �o�׎x���敪�F�q�֕ԕi
    cv_inv_adjust_1            CONSTANT VARCHAR2(1)   := '1';                              -- �݌ɒ����敪�F1�i���݌ɒ����j
    cv_ship_prov_div_1         CONSTANT VARCHAR2(1)   := '1';                              -- �o�׎x���敪�F1
    cv_ship_prov_div_2         CONSTANT VARCHAR2(1)   := '2';                              -- �o�׎x���敪�F2
    cv_doc_type_prod           CONSTANT VARCHAR2(4)   := 'PROD';                           -- �����^�C�v�FPROD
    cv_doc_type_omso           CONSTANT VARCHAR2(4)   := 'OMSO';                           -- �����^�C�v�FOMSO
    cv_doc_type_porc           CONSTANT VARCHAR2(4)   := 'PORC';                           -- �����^�C�v�FPORC
    cv_doc_type_xfer           CONSTANT VARCHAR2(4)   := 'XFER';                           -- �����^�C�v�FXFER
    cv_doc_type_trni           CONSTANT VARCHAR2(4)   := 'TRNI';                           -- �����^�C�v�FTRNI
    cv_doc_type_adji           CONSTANT VARCHAR2(4)   := 'ADJI';                           -- �����^�C�v�FADJI
    cv_cat_crowd_code          CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_CATEGORY_CROWD_CODE'; -- �J�e�S���Z�b�gID1
    cv_cat_item_class          CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_CATEGORY_ITEM_CLASS'; -- �J�e�S���Z�b�gID2
    cv_type_whse_cafe_roast    CONSTANT VARCHAR2(30)  := 'XXCFO1_WHSE_CAFE_ROAST';         -- �R�[�q�[�����q�ɂ̈ꗗ
    cv_type_package_cost_whse  CONSTANT VARCHAR2(30)  := 'XXCFO1_PACKAGE_COST_WHSE';       -- ��ޗ���q�Ƀ��X�g
    cv_segment1_2              CONSTANT VARCHAR2(1)   := '2';                              -- �Z�O�����g1�F����
    cv_segment1_5              CONSTANT VARCHAR2(1)   := '5';                              -- �Z�O�����g5�F���i
    cv_dealings_div_101        CONSTANT VARCHAR2(3)   := '101';                            -- ����敪�F���ޏo��
    cv_dealings_div_103        CONSTANT VARCHAR2(3)   := '103';                            -- ����敪�F�L��
    cv_dealings_div_106        CONSTANT VARCHAR2(3)   := '106';                            -- ����敪�F�U�֗L��_���o
    cv_dealings_div_113        CONSTANT VARCHAR2(3)   := '113';                            -- ����敪�F�U�֏o��_���o
    cv_dealings_div_301        CONSTANT VARCHAR2(3)   := '301';                            -- ����敪�F����
    cv_dealings_div_302        CONSTANT VARCHAR2(3)   := '302';                            -- ����敪�F���g
    cv_dealings_div_303        CONSTANT VARCHAR2(3)   := '303';                            -- ����敪�F���g�ō�
    cv_dealings_div_304        CONSTANT VARCHAR2(3)   := '304';                            -- ����敪�F�Đ�
    cv_dealings_div_306        CONSTANT VARCHAR2(3)   := '306';                            -- ����敪�F�Đ��ō�
    cv_dealings_div_307        CONSTANT VARCHAR2(3)   := '307';                            -- ����敪�F�Z�b�g
    cv_dealings_div_308        CONSTANT VARCHAR2(3)   := '308';                            -- ����敪�F�i��U��
    cv_dealings_div_309        CONSTANT VARCHAR2(3)   := '309';                            -- ����敪�F�i��U��
    cv_dealings_div_310        CONSTANT VARCHAR2(3)   := '310';                            -- ����敪�F�u�����h���g
    cv_dealings_div_504        CONSTANT VARCHAR2(3)   := '504';                            -- ����敪�F�p�p
    cv_dealings_div_509        CONSTANT VARCHAR2(3)   := '509';                            -- ����敪�F���{
    cv_prod_class_code_1       CONSTANT VARCHAR2(1)   := '1';                              -- ���i�敪�F���[�t
    cv_prod_class_code_2       CONSTANT VARCHAR2(1)   := '2';                              -- ���i�敪�F�h�����N
    cv_item_class_code_1       CONSTANT VARCHAR2(1)   := '1';                              -- �i�ڋ敪�F����
    cv_item_class_code_2       CONSTANT VARCHAR2(1)   := '2';                              -- �i�ڋ敪�F����
    cv_item_class_code_4       CONSTANT VARCHAR2(1)   := '4';                              -- �i�ڋ敪�F�����i
    cv_item_class_code_5       CONSTANT VARCHAR2(1)   := '5';                              -- �i�ڋ敪�F���i
    cv_source_doc_code_rma     CONSTANT VARCHAR2(3)   := 'RMA';                            -- �\�[�X�����FRMA
    cv_routing_class_70        CONSTANT VARCHAR2(2)   := '70';                             -- �H���敪�F�i�ڐU�ֈȊO
    cv_ptn_siwake_01           CONSTANT VARCHAR2(1)   := '1';                              -- �d��p�^�[���F1
    cv_ptn_siwake_02           CONSTANT VARCHAR2(1)   := '2';                              -- �d��p�^�[���F2
    cv_ptn_siwake_03           CONSTANT VARCHAR2(1)   := '3';                              -- �d��p�^�[���F3
    cv_ptn_siwake_04           CONSTANT VARCHAR2(1)   := '4';                              -- �d��p�^�[���F4
    cv_ptn_siwake_05           CONSTANT VARCHAR2(1)   := '5';                              -- �d��p�^�[���F5
    cv_ptn_siwake_06           CONSTANT VARCHAR2(1)   := '6';                              -- �d��p�^�[���F6
    cv_ptn_siwake_07           CONSTANT VARCHAR2(1)   := '7';                              -- �d��p�^�[���F7
    cv_att1_0                  CONSTANT VARCHAR2(1)   := '0';                              -- DFF1�F0
    cv_att1_1                  CONSTANT VARCHAR2(1)   := '1';                              -- DFF1�F1
    cv_att1_2                  CONSTANT VARCHAR2(1)   := '2';                              -- DFF1�F2
    cv_att3_1                  CONSTANT VARCHAR2(1)   := '1';                              -- DFF3�F1
    cv_att4_2                  CONSTANT VARCHAR2(1)   := '2';                              -- DFF4�F2
    cv_lookup_code_zzz         CONSTANT VARCHAR2(3)   := 'ZZZ';                            -- �Q�ƃR�[�h�FZZZ
    cv_reason_code_x122        CONSTANT VARCHAR2(4)   := 'X122';                           -- ���R�R�[�h�i�ړ����сj
    cv_reason_code_x123        CONSTANT VARCHAR2(4)   := 'X123';                           -- ���R�R�[�h�i�ړ����ђ����j
    cv_reason_code_x201        CONSTANT VARCHAR2(4)   := 'X201';                           -- ���R�R�[�h�i�݌ɒ����j
    cv_reason_code_x911        CONSTANT VARCHAR2(4)   := 'X911';                           -- ���R�R�[�h
    cv_reason_code_x912        CONSTANT VARCHAR2(4)   := 'X912';                           -- ���R�R�[�h
    cv_reason_code_x921        CONSTANT VARCHAR2(4)   := 'X921';                           -- ���R�R�[�h
    cv_reason_code_x922        CONSTANT VARCHAR2(4)   := 'X922';                           -- ���R�R�[�h
    cv_reason_code_x931        CONSTANT VARCHAR2(4)   := 'X931';                           -- ���R�R�[�h
    cv_reason_code_x932        CONSTANT VARCHAR2(4)   := 'X932';                           -- ���R�R�[�h
    cv_reason_code_x941        CONSTANT VARCHAR2(4)   := 'X941';                           -- ���R�R�[�h
    cv_reason_code_x942        CONSTANT VARCHAR2(4)   := 'X942';                           -- ���R�R�[�h�i�َ��i�ڕ��o
    cv_reason_code_x943        CONSTANT VARCHAR2(4)   := 'X943';                           -- ���R�R�[�h�i�َ��i�ڎ��
    cv_reason_code_x950        CONSTANT VARCHAR2(4)   := 'X950';                           -- ���R�R�[�h�i���̑�����j
    cv_reason_code_x951        CONSTANT VARCHAR2(4)   := 'X951';                           -- ���R�R�[�h�i���̑����o�j
    cv_reason_code_x952        CONSTANT VARCHAR2(4)   := 'X952';                           -- ���R�R�[�h
    cv_reason_code_x953        CONSTANT VARCHAR2(4)   := 'X953';                           -- ���R�R�[�h
    cv_reason_code_x954        CONSTANT VARCHAR2(4)   := 'X954';                           -- ���R�R�[�h
    cv_reason_code_x955        CONSTANT VARCHAR2(4)   := 'X955';                           -- ���R�R�[�h
    cv_reason_code_x956        CONSTANT VARCHAR2(4)   := 'X956';                           -- ���R�R�[�h
    cv_reason_code_x957        CONSTANT VARCHAR2(4)   := 'X957';                           -- ���R�R�[�h
    cv_reason_code_x958        CONSTANT VARCHAR2(4)   := 'X958';                           -- ���R�R�[�h
    cv_reason_code_x959        CONSTANT VARCHAR2(4)   := 'X959';                           -- ���R�R�[�h
    cv_reason_code_x960        CONSTANT VARCHAR2(4)   := 'X960';                           -- ���R�R�[�h
    cv_reason_code_x961        CONSTANT VARCHAR2(4)   := 'X961';                           -- ���R�R�[�h
    cv_reason_code_x962        CONSTANT VARCHAR2(4)   := 'X962';                           -- ���R�R�[�h
    cv_reason_code_x963        CONSTANT VARCHAR2(4)   := 'X963';                           -- ���R�R�[�h
    cv_reason_code_x964        CONSTANT VARCHAR2(4)   := 'X964';                           -- ���R�R�[�h
    cv_reason_code_x965        CONSTANT VARCHAR2(4)   := 'X965';                           -- ���R�R�[�h
    cv_reason_code_x966        CONSTANT VARCHAR2(4)   := 'X966';                           -- ���R�R�[�h
    cv_reason_code_x988        CONSTANT VARCHAR2(4)   := 'X988';                           -- ���R�R�[�h�i�l������j
    cv_date_format_yyyymm      CONSTANT VARCHAR2(6)   := 'YYYYMM';                         -- YYYYMM�`��
--
    -- *** ���[�J���ϐ� ***
    ln_count                 NUMBER       DEFAULT 0;                                     -- ���o�����̃J�E���g
    ln_out_count             NUMBER       DEFAULT 0;                                     -- ����u���[�N�L�[�����̃J�E���g
    ln_count_whse_data       NUMBER       DEFAULT 0;                                     -- �Ώۑq�Ɍ����̃J�E���g
    lv_data7_flag            VARCHAR2(1)  DEFAULT NULL;                                  -- (7)(8)(9)�I�����Ձi�����A�����i�A���ށj�p�f�[�^�L���t���O
    lv_whse_data_flag        VARCHAR2(1)  DEFAULT NULL;                                  -- �Ώۑq�Ƀ`�F�b�N�t���O
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���o�J�[�\��1
    CURSOR get_journal_oif_data1_cur
    IS
      -- (1)��� ������U�֕��i�����i���猴���ցj
      SELECT /*+ LEADING(itp xrpm grb xicv gmd gbh ilm) */
             ROUND( NVL(itp.trans_qty, 0)             *
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS  price               -- ���z
            ,gmd.material_detail_id                      AS  material_detail_id  -- ���Y�����ڍ�ID
      FROM   ic_tran_pnd                 itp                      -- �ۗ��݌Ƀg�����U�N�V����
            ,gme_batch_header            gbh                      -- ���Y�o�b�`�w�b�_
            ,gme_material_details        gmd                      -- ���Y�����ڍ�
            ,gmd_routings_b              grb                      -- �H���}�X�^
            ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
            ,xxcmn_item_categories5_v    xicv                     -- OPM�i�ڃJ�e�S���������View5
            ,ic_lots_mst                 ilm                      -- OPM���b�g�}�X�^
      WHERE  itp.doc_type         = cv_doc_type_prod                        -- �����^�C�v
      AND    itp.completed_ind    = cn_completed_ind_1                      -- �����t���O
      AND    itp.trans_date       >= gd_target_date_from                    -- �J�n��
      AND    itp.trans_date       <= gd_target_date_to                      -- �I����
      AND    xrpm.dealings_div    = cv_dealings_div_308                     -- �i��U��
      AND    xrpm.doc_type        = itp.doc_type
      AND    xrpm.line_type       = itp.line_type
      AND    xrpm.routing_class   = grb.routing_class
      AND    xrpm.line_type       = cv_line_type_1                          -- �����i
      AND    xicv.item_id         = itp.item_id
      AND    xicv.item_class_code = cv_item_class_code_1                    -- �����������i���
      AND    xicv.prod_class_code = cv_prod_class_code_1                    -- ���[�t
      AND    gmd.batch_id         = itp.doc_id
      AND    gmd.line_no          = itp.doc_line
      AND    gmd.line_type        = itp.line_type
      AND    gmd.batch_id         = gbh.batch_id
      AND    gbh.routing_id       = grb.routing_id
      AND    ilm.lot_id           = itp.lot_id
      AND    ilm.item_id          = itp.item_id
      AND    EXISTS (
                      SELECT 1
                      FROM   gme_material_details        gmd2      -- ���Y�����ڍ�2
                            ,xxcmn_item_categories5_v    xicv2     -- OPM�i�ڃJ�e�S���������View5 2
                      WHERE  gmd2.batch_id  = gmd.batch_id
                      AND    gmd2.line_no   = gmd.line_no
                      AND    gmd2.line_type = cv_line_type_minus_1          -- �����i
                      AND    xicv2.item_id  = gmd2.item_id
                      AND    xicv2.item_class_code = xrpm.item_div_origin   -- �i�ڋ敪�i�U�֌��j
                      )
      AND    EXISTS (
                      SELECT 1
                      FROM   gme_material_details        gmd3      -- ���Y�����ڍ�3
                            ,xxcmn_item_categories5_v    xicv3     -- OPM�i�ڃJ�e�S���������View5 3
                      WHERE  gmd3.batch_id  = gmd.batch_id
                      AND    gmd3.line_no   = gmd.line_no
                      AND    gmd3.line_type = cv_line_type_1                -- �����i
                      AND    xicv3.item_id  = gmd3.item_id
                      AND    xicv3.item_class_code = xrpm.item_div_ahead    -- �i�ڋ敪�i�U�֐�j
                      )
      ;
    -- GL�d��OIF���1�i�[�pPL/SQL�\
    TYPE journal_oif_data1_ttype IS TABLE OF get_journal_oif_data1_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data1_tab                    journal_oif_data1_ttype;
--
    -- ���o�J�[�\��2_1
    CURSOR get_journal_oif_data2_1_cur
    IS
      -- �i2�j���Y���o
      -- �@�R�[�q�[�����q�ɁiF30�j�ȊO�̏ꍇ
      -- ���Y���o�i�Đ��j�{���Y���o�i�u�����h���g�j�{���Y���o�i�Đ����g�j��
      SELECT /*+ LEADING(itp xrpm grb xicv gmd gbh ilm flvv) */
             ROUND( NVL(itp.trans_qty, 0)             *
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS  price                -- ���z
            ,itp.whse_code                               AS  whse_code            -- �q�ɃR�[�h
            ,gmd.material_detail_id                      AS  material_detail_id   -- ���Y�����ڍ�ID
      FROM   ic_tran_pnd                 itp                      -- �ۗ��݌Ƀg�����U�N�V����
            ,gme_batch_header            gbh                      -- ���Y�o�b�`�w�b�_
            ,gme_material_details        gmd                      -- ���Y�����ڍ�
            ,gmd_routings_b              grb                      -- �H���}�X�^
            ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
            ,xxcmn_item_categories5_v    xicv                     -- OPM�i�ڃJ�e�S���������View5
            ,ic_lots_mst                 ilm                      -- OPM���b�g�}�X�^
      WHERE  itp.doc_type           = cv_doc_type_prod                     -- �����^�C�v
      AND    itp.completed_ind      = cn_completed_ind_1                   -- �����t���O
      AND    itp.trans_date         >= gd_target_date_from                 -- �J�n��
      AND    itp.trans_date         <= gd_target_date_to                   -- �I����
      AND    xrpm.dealings_div      in ( cv_dealings_div_302         -- ���g
                                        ,cv_dealings_div_303         -- ���g�ō�
                                        ,cv_dealings_div_304         -- �Đ�
                                        ,cv_dealings_div_306         -- �Đ��ō�
                                        ,cv_dealings_div_310         -- �u�����h���g
                                       )                                   -- ����敪
      AND    xrpm.doc_type          = itp.doc_type
      AND    xrpm.line_type         = itp.line_type
      AND    xrpm.routing_class     = grb.routing_class
      AND    xrpm.line_type         = cv_line_type_minus_1                 -- �����i
      AND    xicv.item_id           = itp.item_id
      AND    xicv.item_class_code   = cv_item_class_code_1                 -- �����������o
      AND    xicv.prod_class_code   = cv_prod_class_code_1                 -- ���[�t
      AND    gmd.batch_id           = itp.doc_id
      AND    gmd.line_no            = itp.doc_line
      AND    gmd.line_type          = itp.line_type
      AND    gmd.batch_id           = gbh.batch_id
      AND    ( ( gmd.attribute5     IS NULL
          AND    xrpm.hit_in_div    IS NULL )
        OR     gmd.attribute5       = xrpm.hit_in_div )
      AND    gbh.routing_id         = grb.routing_id
      AND    ilm.lot_id             = itp.lot_id
      AND    ilm.item_id            = itp.item_id
      AND    NOT EXISTS (
                         SELECT 1
                         FROM   fnd_lookup_values_vl        flvv                     -- �Q�ƃ^�C�v
                         WHERE  flvv.lookup_type       = cv_type_whse_cafe_roast     -- �R�[�q�[�����q�ɂ̈ꗗ
                         AND    itp.whse_code          = flvv.lookup_code
                         AND    flvv.START_DATE_ACTIVE <= gd_target_date_from        -- �J�n��
                         AND    flvv.END_DATE_ACTIVE   >= gd_target_date_to          -- �I����
                        )
      UNION ALL
      -- ���Y����i�u�����h���g�j��
      SELECT /*+ LEADING(itp xrpm grb xicv gmd gbh ilm flvv) */
             ROUND( NVL(itp.trans_qty, 0)             *
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div)       *
                    -1)                                  AS  price                -- ���z
            ,itp.whse_code                               AS  whse_code            -- �q�ɃR�[�h
            ,gmd.material_detail_id                      AS  material_detail_id   -- ���Y�����ڍ�ID
      FROM   ic_tran_pnd                 itp                      -- �ۗ��݌Ƀg�����U�N�V����
            ,gme_batch_header            gbh                      -- ���Y�o�b�`�w�b�_
            ,gme_material_details        gmd                      -- ���Y�����ڍ�
            ,gmd_routings_b              grb                      -- �H���}�X�^
            ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
            ,xxcmn_item_categories5_v    xicv                     -- OPM�i�ڃJ�e�S���������View5
            ,ic_lots_mst                 ilm                      -- OPM���b�g�}�X�^
      WHERE  itp.doc_type           = cv_doc_type_prod                     -- �����^�C�v
      AND    itp.completed_ind      = cn_completed_ind_1                   -- �����t���O
      AND    itp.trans_date         >= gd_target_date_from                 -- �J�n��
      AND    itp.trans_date         <= gd_target_date_to                   -- �I����
      AND    xrpm.dealings_div      = cv_dealings_div_302                  -- ����敪(���g)
      AND    xrpm.doc_type          = itp.doc_type
      AND    xrpm.line_type         = itp.line_type
      AND    xrpm.routing_class     = grb.routing_class
      AND    itp.line_type          = cv_line_type_1                       -- �����i
      AND    xicv.item_id           = itp.item_id
      AND    xicv.item_class_code   = cv_item_class_code_1                 -- �����������o
      AND    xicv.prod_class_code   = cv_prod_class_code_1                 -- ���[�t
      AND    gmd.batch_id           = itp.doc_id
      AND    gmd.line_no            = itp.doc_line
      AND    gmd.line_type          = itp.line_type
      AND    gmd.batch_id           = gbh.batch_id
      AND    gbh.routing_id         = grb.routing_id
      AND    ilm.lot_id             = itp.lot_id
      AND    ilm.item_id            = itp.item_id
      AND    NOT EXISTS (
                         SELECT 1
                         FROM   fnd_lookup_values_vl        flvv                     -- �Q�ƃ^�C�v
                         WHERE  flvv.lookup_type       = cv_type_whse_cafe_roast     -- �R�[�q�[�����q�ɂ̈ꗗ
                         AND    itp.whse_code          = flvv.lookup_code
                         AND    flvv.START_DATE_ACTIVE <= gd_target_date_from        -- �J�n��
                         AND    flvv.END_DATE_ACTIVE   >= gd_target_date_to          -- �I����
                        )
      ORDER BY whse_code
      ;
    -- GL�d��OIF���2_1�i�[�pPL/SQL�\
    TYPE journal_oif_data2_1_ttype IS TABLE OF get_journal_oif_data2_1_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data2_1_tab                    journal_oif_data2_1_ttype;
--
    -- ���o�J�[�\��2_2
    CURSOR get_journal_oif_data2_2_cur
    IS
      -- (2)���Y���o�A�R�[�q�[�����q�ɁiF30�j
      SELECT /*+ LEADING(itp xrpm grb xicv gmd gbh ilm flvv) */
             ROUND( NVL(itp.trans_qty, 0)             *
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS  price                -- ���z
            ,itp.whse_code                               AS  whse_code            -- �q�ɃR�[�h
            ,gmd.material_detail_id                      AS  material_detail_id   -- ���Y�����ڍ�ID
      FROM   ic_tran_pnd                 itp                      -- �ۗ��݌Ƀg�����U�N�V����
            ,gme_batch_header            gbh                      -- ���Y�o�b�`�w�b�_
            ,gme_material_details        gmd                      -- ���Y�����ڍ�
            ,gmd_routings_b              grb                      -- �H���}�X�^
            ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
            ,xxcmn_item_categories5_v    xicv                     -- OPM�i�ڃJ�e�S���������View5
            ,ic_lots_mst                 ilm                      -- OPM���b�g�}�X�^
            ,fnd_lookup_values_vl        flvv                     -- �Q�ƃ^�C�v
      WHERE  itp.doc_type         = cv_doc_type_prod                     -- �����^�C�v
      AND    itp.completed_ind    = cn_completed_ind_1                   -- �����t���O
      AND    itp.trans_date       >= gd_target_date_from                 -- �J�n��
      AND    itp.trans_date       <= gd_target_date_to                   -- �I����
      AND    xrpm.dealings_div    in ( cv_dealings_div_304         -- �Đ�
                                      ,cv_dealings_div_306         -- �Đ��ō�
                                     )                                   -- ����敪
      AND    xrpm.doc_type        = itp.doc_type
      AND    xrpm.line_type       = itp.line_type
      AND    xrpm.routing_class   = grb.routing_class
      AND    xrpm.line_type       = cv_line_type_minus_1                 -- �����i
      AND    xicv.item_id         = itp.item_id
      AND    xicv.item_class_code = cv_item_class_code_1                 -- �����������o
      AND    xicv.prod_class_code = cv_prod_class_code_1                 -- ���[�t
      AND    gmd.batch_id         = itp.doc_id
      AND    gmd.line_no          = itp.doc_line
      AND    gmd.line_type        = itp.line_type
      AND    gmd.batch_id         = gbh.batch_id
      AND    ( ( gmd.attribute5   IS NULL
          AND    xrpm.hit_in_div  IS NULL )
        OR     gmd.attribute5     = xrpm.hit_in_div )
      AND    gbh.routing_id       = grb.routing_id
      AND    ilm.lot_id           = itp.lot_id
      AND    ilm.item_id          = itp.item_id
      AND    flvv.lookup_type     = cv_type_whse_cafe_roast                -- �R�[�q�[�����q�ɂ̈ꗗ
      AND    itp.whse_code        = flvv.lookup_code
      AND    flvv.start_date_active <= gd_target_date_from                 -- �J�n��
      AND    flvv.end_date_active   >= gd_target_date_to                   -- �I����
      ORDER BY whse_code
      ;
    -- GL�d��OIF���2_2�i�[�pPL/SQL�\
    TYPE journal_oif_data2_2_ttype IS TABLE OF get_journal_oif_data2_2_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data2_2_tab                    journal_oif_data2_2_ttype;
--
    -- ���o�J�[�\��3
    CURSOR get_journal_oif_data3_cur
    IS
      -- (3)���ꕥ�o
      SELECT /*+ LEADING(itp xrpm grb iimb xicv gmd gbh ilm xsup)
                 USE_NL(xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h) */
             ROUND((CASE iimb.attribute15
                      WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                      ELSE DECODE(iimb.lot_ctl
                                 ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                 ,NVL(xsup.stnd_unit_price, 0))
                    END) * NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div)
             )                                    AS  price               -- ���z
            ,xicv.prod_class_code                 AS  prod_class_code     -- ���i�敪
            ,xicv.item_class_code                 AS  item_class_code     -- �i�ڋ敪
            ,gmd.material_detail_id               AS  material_detail_id  -- ���Y�����ڍ�ID
      FROM   ic_tran_pnd                 itp                      -- �ۗ��݌Ƀg�����U�N�V����
            ,gme_batch_header            gbh                      -- ���Y�o�b�`�w�b�_
            ,gme_material_details        gmd                      -- ���Y�����ڍ�
            ,gmd_routings_b              grb                      -- �H���}�X�^
            ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
            ,ic_item_mst_b               iimb                     -- OPM�i�ڃ}�X�^
            ,xxcmn_item_categories5_v    xicv                     -- OPM�i�ڃJ�e�S���������View5
            ,ic_lots_mst                 ilm                      -- OPM���b�g�}�X�^
            ,xxcmn_stnd_unit_price_v     xsup                     -- �W���������u������
      WHERE  itp.doc_type         = cv_doc_type_prod                                   -- �����^�C�v
      AND    itp.completed_ind    = cn_completed_ind_1                                 -- �����t���O
      AND    itp.trans_date       >= gd_target_date_from                               -- �J�n��
      AND    itp.trans_date       <= gd_target_date_to                                 -- �I����
      AND    xrpm.dealings_div    = cv_dealings_div_301                                -- ����敪�i����j
      AND    xrpm.doc_type        = itp.doc_type
      AND    xrpm.line_type       = itp.line_type
      AND    xrpm.routing_class   = grb.routing_class
      AND    xrpm.line_type       = cv_line_type_minus_1                               -- �����i
      AND    iimb.item_id         = itp.item_id
      AND    xicv.item_id         = iimb.item_id
      AND    ( (xicv.prod_class_code = cv_prod_class_code_1                            -- ���[�t
          AND   xicv.item_class_code in (cv_item_class_code_1, cv_item_class_code_2) ) -- �����A����
        OR     (xicv.prod_class_code = cv_prod_class_code_2                            -- �h�����N
          AND   xicv.item_class_code = cv_item_class_code_1) )                         -- ����
      AND    gmd.batch_id         = itp.doc_id
      AND    gmd.line_no          = itp.doc_line
      AND    gmd.line_type        = itp.line_type
      AND    gmd.batch_id         = gbh.batch_id
      AND    gbh.routing_id       = grb.routing_id
      AND    ilm.lot_id           = itp.lot_id
      AND    ilm.item_id          = itp.item_id
      AND    itp.item_id          = xsup.item_id(+)
      AND    itp.trans_date       BETWEEN NVL(xsup.start_date_active(+), itp.trans_date)
                                  AND     NVL(xsup.end_date_active(+), itp.trans_date)
      ORDER BY xicv.prod_class_code, xicv.item_class_code
      ;
    -- GL�d��OIF���3�i�[�pPL/SQL�\
    TYPE journal_oif_data3_ttype IS TABLE OF get_journal_oif_data3_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data3_tab                     journal_oif_data3_ttype;
--
    -- ���o�J�[�\��4
    CURSOR get_journal_oif_data4_cur
    IS
      -- (4)��Z�b�g���o
      -- �@���ہE���� �ȊO��
      SELECT /*+ LEADING(itp) 
                 USE_NL(xrpm grb xicv gmd gbh xsup flvv) */
             ROUND( NVL(itp.trans_qty, 0)        *
                    NVL(xsup.stnd_unit_price, 0) *
                    TO_NUMBER(xrpm.rcv_pay_div) )    AS  price               -- ���z
            ,itp.whse_code                           AS  whse_code           -- �q�ɃR�[�h
            ,gmd.material_detail_id                  AS  material_detail_id  -- ���Y�����ڍ�ID
      FROM   ic_tran_pnd                 itp                      -- �ۗ��݌Ƀg�����U�N�V����
            ,gme_batch_header            gbh                      -- ���Y�o�b�`�w�b�_
            ,gme_material_details        gmd                      -- ���Y�����ڍ�
            ,gmd_routings_b              grb                      -- �H���}�X�^
            ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
            ,xxcmn_item_categories5_v    xicv                     -- OPM�i�ڃJ�e�S���������View5
            ,xxcmn_stnd_unit_price_v     xsup                     -- �W���������u������
            ,fnd_lookup_values_vl        flvv                     -- �Q�ƃ^�C�v
      WHERE  itp.doc_type           = cv_doc_type_prod                     -- �����^�C�v
      AND    itp.completed_ind      = cn_completed_ind_1                   -- �����t���O
      AND    itp.trans_date         >= gd_target_date_from                 -- �J�n��
      AND    itp.trans_date         <= gd_target_date_to                   -- �I����
      AND    xrpm.dealings_div      = cv_dealings_div_307                  -- ����敪�i�Z�b�g�j
      AND    xrpm.doc_type          = itp.doc_type
      AND    xrpm.line_type         = itp.line_type
      AND    xrpm.routing_class     = grb.routing_class
      AND    xrpm.line_type         = cv_line_type_minus_1                 -- �����i
      AND    xicv.item_id           = itp.item_id
      AND    xicv.item_class_code   = cv_item_class_code_2                 -- ����
      AND    xicv.prod_class_code   = cv_prod_class_code_1                 -- ���[�t
      AND    gmd.batch_id           = itp.doc_id
      AND    gmd.line_no            = itp.doc_line
      AND    gmd.line_type          = itp.line_type
      AND    gmd.batch_id           = gbh.batch_id
      AND    gbh.routing_id         = grb.routing_id
      AND    xsup.item_id           = itp.item_id
      AND    itp.trans_date         BETWEEN NVL(xsup.start_date_active, itp.trans_date)
                                    AND     NVL(xsup.end_date_active, itp.trans_date)
      AND    flvv.lookup_type       = cv_type_package_cost_whse            -- ��ޗ���q�Ƀ��X�g
      AND    itp.whse_code          = flvv.lookup_code
      AND    flvv.attribute1        = cv_att1_1                            -- ���ہA����ȊO
      AND    flvv.START_DATE_ACTIVE <= gd_target_date_from                 -- �J�n��
      AND    flvv.END_DATE_ACTIVE   >= gd_target_date_to                   -- �I����
      UNION ALL
      -- �A���ە�
      SELECT /*+ LEADING(itp) 
                 USE_NL(xrpm grb xicv gmd gbh xsup flvv) */
             ROUND( NVL(itp.trans_qty, 0)        *
                    NVL(xsup.stnd_unit_price, 0) *
                    TO_NUMBER(xrpm.rcv_pay_div) )    AS  price               -- ���z
            ,itp.whse_code                           AS  whse_code           -- �q�ɃR�[�h
            ,gmd.material_detail_id                  AS  material_detail_id  -- ���Y�����ڍ�ID
      FROM   ic_tran_pnd                 itp                      -- �ۗ��݌Ƀg�����U�N�V����
            ,gme_batch_header            gbh                      -- ���Y�o�b�`�w�b�_
            ,gme_material_details        gmd                      -- ���Y�����ڍ�
            ,gmd_routings_b              grb                      -- �H���}�X�^
            ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
            ,xxcmn_item_categories5_v    xicv                     -- OPM�i�ڃJ�e�S���������View5
            ,xxcmn_stnd_unit_price_v     xsup                     -- �W���������u������
      WHERE  itp.doc_type           = cv_doc_type_prod                     -- �����^�C�v
      AND    itp.completed_ind      = cn_completed_ind_1                   -- �����t���O
      AND    itp.trans_date         >= gd_target_date_from                 -- �J�n��
      AND    itp.trans_date         <= gd_target_date_to                   -- �I����
      AND    xrpm.dealings_div      = cv_dealings_div_307                  -- ����敪(�Z�b�g)
      AND    xrpm.doc_type          = itp.doc_type
      AND    xrpm.line_type         = itp.line_type
      AND    xrpm.routing_class     = grb.routing_class
      AND    xrpm.line_type         = cv_line_type_minus_1                 -- �����i
      AND    xicv.item_id           = itp.item_id
      AND    xicv.item_class_code   = cv_item_class_code_2                 -- ����
      AND    xicv.prod_class_code   = cv_prod_class_code_1                 -- ���[�t
      AND    gmd.batch_id           = itp.doc_id
      AND    gmd.line_no            = itp.doc_line
      AND    gmd.line_type          = itp.line_type
      AND    gmd.batch_id           = gbh.batch_id
      AND    gbh.routing_id         = grb.routing_id
      AND    xsup.item_id           = itp.item_id
      AND    itp.trans_date         BETWEEN NVL(xsup.start_date_active, itp.trans_date)
                                    AND     NVL(xsup.end_date_active, itp.trans_date)
      AND    NOT EXISTS (
                     SELECT 1
                     FROM   fnd_lookup_values_vl flvv
                     WHERE  flvv.lookup_type       = cv_type_package_cost_whse    -- ��ޗ���q�Ƀ��X�g
                     AND    flvv.attribute1        IS NOT NULL
                     AND    itp.whse_code          = flvv.lookup_code
                     AND    flvv.lookup_code       <> cv_lookup_code_zzz
                     AND    flvv.start_date_active <= gd_target_date_from            -- �J�n��
                     AND    flvv.end_date_active   >= gd_target_date_to              -- �I����
                    )
      ORDER BY whse_code
      ;
    -- GL�d��OIF���4�i�[�pPL/SQL�\
    TYPE journal_oif_data4_ttype IS TABLE OF get_journal_oif_data4_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data4_tab                     journal_oif_data4_ttype;
--
    -- ���o�J�[�\��6 �����X6�Ԗڂ̒��o�J�[�\������������
    CURSOR get_journal_oif_data6_cur
    IS
      -- (5)���o ������U�֕��i�����E�����i�ցj
      SELECT /*+ LEADING(itp) 
                 USE_NL(xrpm grb xicv gmd gbh ilm gmd2 xicv2 gmd3 xicv3) */
             ROUND( NVL(itp.trans_qty, 0)             *
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS  price               -- ���z
            ,gmd.material_detail_id                      AS  material_detail_id  -- ���Y�����ڍ�ID
      FROM   ic_tran_pnd                 itp                      -- �ۗ��݌Ƀg�����U�N�V����
            ,gme_batch_header            gbh                      -- ���Y�o�b�`�w�b�_
            ,gme_material_details        gmd                      -- ���Y�����ڍ�
            ,gmd_routings_b              grb                      -- �H���}�X�^
            ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
            ,xxcmn_item_categories5_v    xicv                     -- OPM�i�ڃJ�e�S���������View5
            ,ic_lots_mst                 ilm                      -- OPM���b�g�}�X�^
      WHERE  itp.doc_type          = cv_doc_type_prod                     -- �����^�C�v
      AND    itp.completed_ind     = cn_completed_ind_1                   -- �����t���O
      AND    itp.trans_date        >= gd_target_date_from                 -- �J�n��
      AND    itp.trans_date        <= gd_target_date_to                   -- �I����
      AND    xrpm.dealings_div     = cv_dealings_div_308                  -- ����敪�i�i��U�ցj
      AND    xrpm.doc_type         = itp.doc_type
      AND    xrpm.line_type        = itp.line_type
      AND    xrpm.routing_class    = grb.routing_class
      AND    xrpm.line_type        = cv_line_type_minus_1                 -- �����i
      AND    xicv.item_id          = itp.item_id
      AND    xicv.item_class_code  = cv_item_class_code_1                 -- �����𓊓��E���o
      AND    xicv.prod_class_code  = cv_prod_class_code_1                 -- ���[�t
      AND    gmd.batch_id          = itp.doc_id
      AND    gmd.line_no           = itp.doc_line
      AND    gmd.line_type         = itp.line_type
      AND    gmd.batch_id          = gbh.batch_id
      AND    gbh.routing_id        = grb.routing_id
      AND    ilm.lot_id            = itp.lot_id
      AND    ilm.item_id           = itp.item_id
      AND    exists (
                     SELECT 1
                     FROM   gme_material_details        gmd2        -- ���Y�����ڍ�
                           ,xxcmn_item_categories5_v    xicv2       -- OPM�i�ڃJ�e�S���������View5 2
                     WHERE  gmd2.batch_id          = gmd.batch_id
                     AND    gmd2.line_no           = gmd.line_no
                     AND    gmd2.line_type         = cv_line_type_minus_1      -- �����i
                     AND    xicv2.item_id          = gmd2.item_id
                     AND    xicv2.item_class_code  = xrpm.item_div_origin
                    )
      AND    exists (
                     SELECT 1
                     FROM   gme_material_details        gmd3        -- ���Y�����ڍ�
                           ,xxcmn_item_categories5_v    xicv3       -- OPM�i�ڃJ�e�S���������View5 2
                     WHERE  gmd3.batch_id          = gmd.batch_id
                     AND    gmd3.line_no           = gmd.line_no
                     AND    gmd3.line_type         = cv_line_type_1            -- �����i
                     AND    xicv3.item_id          = gmd3.item_id
                     AND    xicv3.item_class_code  = xrpm.item_div_ahead
                    )
      ;
    -- GL�d��OIF���6�i�[�pPL/SQL�\
    TYPE journal_oif_data6_ttype IS TABLE OF get_journal_oif_data6_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data6_tab                     journal_oif_data6_ttype;
--
    -- ���o�J�[�\��7 �����X7�Ԗڂ̒��o�J�[�\������������
    CURSOR get_journal_oif_data7_cur
    IS
      -- (6-8)�I�����Ձi�����A���ށA�����i�j
      SELECT SUM(tbl.price)         AS  price            -- ���z
            ,tbl.whse_code          AS  whse_code        -- �q�ɃR�[�h
            ,tbl.prod_class_code    AS  prod_class_code  -- ���i�敪
            ,tbl.item_class_code    AS  item_class_code  -- �i�ڋ敪
      FROM   (
              -- �@����݌Ɋz�̎Z�o
              SELECT /*+ LEADING(xsims)
                         USE_NL(iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND(   NVL(xsims.monthly_stock, 0)  *
                             (CASE iimb.attribute15
                                WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                                ELSE DECODE(iimb.lot_ctl
                                           ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                           ,NVL(xsup.stnd_unit_price, 0))
                              END)
                     )  +  
                     ROUND( (NVL(xsims.cargo_stock, 0)   -
                             NVL(xsims.cargo_stock_not_stn, 0) ) *
                             (CASE iimb.attribute15
                                WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                                ELSE DECODE(iimb.lot_ctl
                                           ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                           ,NVL(xsup.stnd_unit_price, 0))
                              END)
                     )                                                 AS  price            -- ���z
                    ,xsims.whse_code                                   AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                              AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                              AS  item_class_code  -- �i�ڋ敪
              FROM   xxinv_stc_inventory_month_stck  xsims                -- �I�������݌�
                    ,xxcmn_item_categories5_v        xicv                 -- OPM�i�ڃJ�e�S���������View5
                    ,ic_item_mst_b                   iimb                 -- OPM�i�ڃ}�X�^
                    ,ic_lots_mst                     ilm                  -- OPM���b�g�}�X�^
                    ,ic_whse_mst                     iwm                  -- �q�Ƀ}�X�^
                    ,xxcmn_stnd_unit_price_v         xsup                 -- �W���������u������
              WHERE  xsims.whse_code      = iwm.whse_code
              AND    iwm.attribute1       = cv_att1_0                         -- �ɓ����Ǘ��݌�
              AND    iimb.item_id         = xsims.item_id
              AND    iimb.item_id         = xicv.item_id
              AND    xicv.item_class_code <> cv_item_class_code_5
              AND    ilm.lot_id           = xsims.lot_id
              AND    ilm.item_id          = xsims.item_id
              AND    xsims.invent_ym      = gv_period_name2                   -- �p�����[�^.��v�N���̑O��
              AND    xsims.item_id        = xsup.item_id(+)
              AND    gd_target_date_from  >= xsup.start_date_active(+)
              AND    gd_target_date_from  <= xsup.end_date_active(+)
              UNION ALL
              -- �A�ړ����сi�ϑ�����j
              SELECT /*+ LEADING(itp)
                         USE_NL(itp xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup)
                         PUSH_PRED(itp) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- ���z
                    ,itp.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM  (SELECT /*+ LEADING(xmrih xmril ixm) 
                                USE_NL(xmrih xmril ixm itp2) */
                            itp2.item_id                AS item_id
                           ,itp2.lot_id                 AS lot_id
                           ,itp2.doc_type               AS doc_type
                           ,itp2.reason_code            AS reason_code
                           ,itp2.trans_qty              AS trans_qty
                           ,itp2.whse_code              AS whse_code
                           ,xmrih.actual_arrival_date   AS actual_arrival_date
                     FROM   ic_tran_pnd                  itp2   -- OPM�ۗ��݌Ƀg�����U�N�V�����\2
                           ,ic_xfer_mst                  ixm    -- �]���}�X�^
                           ,xxinv_mov_req_instr_lines    xmril  -- �ړ��˗��w�����׃A�h�I��
                           ,xxinv_mov_req_instr_headers  xmrih  -- �ړ��˗��w���w�b�_�A�h�I��
                     WHERE  itp2.doc_type              = cv_doc_type_xfer              -- �����^�C�v
                     AND    itp2.reason_code           = cv_reason_code_x122           -- ���R�R�[�h�i�ړ����сj
                     AND    itp2.completed_ind         = cn_completed_ind_1            -- �����t���O
                     AND    itp2.doc_id                = ixm.transfer_id
                     AND    ixm.attribute1             = TO_CHAR(xmril.mov_line_id)
                     AND    xmrih.mov_hdr_id           = xmril.mov_hdr_id
                     AND    xmrih.actual_arrival_date  >= gd_target_date_from          -- �J�n��
                     AND    xmrih.actual_arrival_date  <= gd_target_date_to            -- �I����
                    )                             itp                      -- OPM�ۗ��݌Ƀg�����U�N�V�����\
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                    ,ic_whse_mst                  iwm                      -- �q�Ƀ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
              WHERE  iimb.item_id               = itp.item_id
              AND    ilm.lot_id                 = itp.lot_id
              AND    ilm.item_id                = itp.item_id
              AND    xrpm.doc_type              = itp.doc_type
              AND    xrpm.reason_code           = itp.reason_code
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xrpm.rcv_pay_div           = (
                                                   case
                                                     WHEN itp.trans_qty >= cn_trans_qty_0 THEN cn_rcv_pay_div_1
                                                     ELSE cn_rcv_pay_div_minus_1
                                                   END
                                                  )
              AND    xicv.item_id               = itp.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    itp.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                             -- �ɓ����݌ɊǗ��q��
              AND    itp.item_id                = xsup.item_id(+)
              AND    itp.actual_arrival_date    >= xsup.start_date_active(+)
              AND    itp.actual_arrival_date    <= xsup.end_date_active(+)
              UNION ALL
              -- �B�ړ����сi�ϑ��Ȃ��j
              SELECT /*+ LEADING(itc)
                         USE_NL(itc xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup)
                         PUSH_PRED(itc) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itc.trans_qty, 0)
                     )                                           AS  price            -- ���z
                    ,itc.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM  (SELECT /*+ LEADING(xmrih xmril ijm iaj)
                                USE_NL(xmrih xmril ijm iaj itc2) */
                            itc2.item_id                AS item_id
                           ,itc2.lot_id                 AS lot_id
                           ,itc2.doc_type               AS doc_type
                           ,itc2.reason_code            AS reason_code
                           ,itc2.trans_qty              AS trans_qty
                           ,itc2.whse_code              AS whse_code
                           ,xmrih.actual_arrival_date   AS actual_arrival_date
                     FROM   ic_tran_cmp                  itc2                     -- �����݌Ƀg�����U�N�V����
                           ,ic_adjs_jnl                  iaj                      -- �݌ɒ����W���[�i��
                           ,ic_jrnl_mst                  ijm                      -- �W���[�i���}�X�^
                           ,xxinv_mov_req_instr_lines    xmril                    -- �ړ��˗��w�����׃A�h�I��
                           ,xxinv_mov_req_instr_headers  xmrih                    -- �ړ��˗��w���w�b�_�A�h�I��
                     WHERE  itc2.doc_type               = cv_doc_type_trni                      -- �����^�C�v�i�ϑ��Ȃ����сj
                     AND    itc2.reason_code            = cv_reason_code_x122                   -- ���R�R�[�h�i�ړ����сj
                     AND    itc2.doc_type               = iaj.trans_type
                     AND    itc2.doc_id                 = iaj.doc_id
                     AND    itc2.doc_line               = iaj.doc_line
                     AND    ijm.journal_id              = iaj.journal_id
                     AND    ijm.attribute1              = TO_CHAR(xmril.mov_line_id)
                     AND    xmrih.mov_hdr_id            = xmril.mov_hdr_id
                     AND    xmrih.actual_arrival_date   >= gd_target_date_from                  -- �J�n��
                     AND    xmrih.actual_arrival_date   <= gd_target_date_to                    -- �I����
                    )                             itc                      -- �����݌Ƀg�����U�N�V����
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                    ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
              WHERE  iimb.item_id               = itc.item_id
              AND    ilm.lot_id                 = itc.lot_id
              AND    ilm.item_id                = itc.item_id
              AND    xrpm.doc_type              = itc.doc_type
              AND    xrpm.reason_code           = itc.reason_code
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xrpm.rcv_pay_div           = (
                                                   CASE
                                                     WHEN itc.trans_qty >= cn_trans_qty_0 THEN cn_rcv_pay_div_1
                                                     ELSE cn_rcv_pay_div_minus_1
                                                   END
                                                  )
              AND    xicv.item_id               = itc.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    itc.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                             -- �ɓ����݌ɊǗ��q��
              AND    itc.item_id                = xsup.item_id(+)
              AND    itc.actual_arrival_date    >= xsup.start_date_active(+)
              AND    itc.actual_arrival_date    <= xsup.end_date_active(+)
              UNION ALL
              -- �C-1�݌ɒ����i�d����ԕi�������j
              SELECT /*+ LEADING(itc)
                         USE_NL(xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itc.trans_qty, 0)
                     )                                           AS  price            -- ���z
                    ,itc.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM   ic_tran_cmp                  itc                      -- �����݌Ƀg�����U�N�V����
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                    ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
              WHERE  itc.doc_type               = cv_doc_type_adji          -- �����^�C�v�i�݌ɒ����j
              AND    itc.reason_code            IN ( cv_reason_code_x911
                                                    ,cv_reason_code_x912
                                                    ,cv_reason_code_x921
                                                    ,cv_reason_code_x922
                                                    ,cv_reason_code_x931
                                                    ,cv_reason_code_x932
                                                    ,cv_reason_code_x941
                                                    ,cv_reason_code_x952
                                                    ,cv_reason_code_x953
                                                    ,cv_reason_code_x954
                                                    ,cv_reason_code_x955
                                                    ,cv_reason_code_x956
                                                    ,cv_reason_code_x957
                                                    ,cv_reason_code_x958
                                                    ,cv_reason_code_x959
                                                    ,cv_reason_code_x960
                                                    ,cv_reason_code_x961
                                                    ,cv_reason_code_x962
                                                    ,cv_reason_code_x963
                                                    ,cv_reason_code_x964
                                                    ,cv_reason_code_x965
                                                    ,cv_reason_code_x966)   -- ���R�R�[�h
              AND    itc.trans_date             >= gd_target_date_from      -- �J�n��
              AND    itc.trans_date             <= gd_target_date_to        -- �I����
              AND    iimb.item_id               = itc.item_id
              AND    ilm.lot_id                 = itc.lot_id
              AND    ilm.item_id                = itc.item_id
              AND    xrpm.doc_type              = itc.doc_type
              AND    xrpm.reason_code           = itc.reason_code
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xicv.item_id               = itc.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    itc.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                 -- �ɓ����݌ɊǗ��q��
              AND    itc.item_id                = xsup.item_id(+)
              AND    itc.trans_date             >= xsup.start_date_active(+)
              AND    itc.trans_date             <= xsup.end_date_active(+)
              UNION ALL
              -- �C-2�݌ɒ����i�d����ԕi�j
              SELECT SUM(ROUND(tbl4.trans_qty * tbl4.unit_price))    AS  price            -- ���z
                    ,tbl4.whse_code                                  AS  whse_code        -- �q�ɃR�[�h
                    ,tbl4.prod_class_code                            AS  prod_class_code  -- ���i�敪
                    ,tbl4.item_class_code                            AS  item_class_code  -- �i�ڋ敪
              FROM   (
                      SELECT /*+ LEADING(itc)
                                 USE_NL(xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                             SUM(NVL(itc.trans_qty, 0))                AS  trans_qty        -- ����
                            ,(CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                             END)                                      AS  unit_price       -- �P��
                            ,itc.whse_code                             AS  whse_code        -- �q�ɃR�[�h
                            ,xicv.prod_class_code                      AS  prod_class_code  -- ���i�敪
                            ,xicv.item_class_code                      AS  item_class_code  -- �i�ڋ敪
                            ,ijm.attribute1                            AS  txns_id          -- ���ID
                      FROM   ic_tran_cmp                  itc                      -- �����݌Ƀg�����U�N�V����
                            ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                            ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                            ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                            ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                            ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                            ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
                            ,ic_adjs_jnl                  iaj                      -- �݌ɒ����W���[�i��
                            ,ic_jrnl_mst                  ijm                      -- �W���[�i���}�X�^
                      WHERE  itc.doc_type               = cv_doc_type_adji                   -- �����^�C�v�i�݌ɒ����j
                      AND    itc.reason_code            = cv_reason_code_x201                -- ���R�R�[�h
                      AND    itc.trans_date             >= gd_target_date_from               -- �J�n��
                      AND    itc.trans_date             <= gd_target_date_to                 -- �I����
                      AND    iaj.trans_type             = itc.doc_type
                      AND    iaj.doc_id                 = itc.doc_id
                      AND    iaj.doc_line               = itc.doc_line
                      AND    ijm.journal_id             = iaj.journal_id
                      AND    iimb.item_id               = itc.item_id
                      AND    ilm.lot_id                 = itc.lot_id
                      AND    ilm.item_id                = itc.item_id
                      AND    xrpm.doc_type              = itc.doc_type
                      AND    xrpm.reason_code           = itc.reason_code
                      AND    xrpm.break_col_01          IS NOT NULL
                      AND    xicv.item_id               = itc.item_id
                      AND    xicv.item_class_code       <> cv_item_class_code_5
                      AND    itc.whse_code              = iwm.whse_code
                      AND    iwm.attribute1             = cv_att1_0                           -- �ɓ����݌ɊǗ��q��
                      AND    itc.item_id                = xsup.item_id(+)
                      AND    itc.trans_date             >= xsup.start_date_active(+)
                      AND    itc.trans_date             <= xsup.end_date_active(+)
                      GROUP BY (CASE iimb.attribute15
                                WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                                ELSE DECODE(iimb.lot_ctl
                                           ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                           ,NVL(xsup.stnd_unit_price, 0))
                               END)
                               , itc.whse_code, xicv.prod_class_code, xicv.item_class_code
                               , ijm.attribute1
                     ) tbl4
              GROUP BY tbl4.whse_code, tbl4.prod_class_code, tbl4.item_class_code
              UNION ALL
              -- �D�݌ɒ����i�l������j
              SELECT /*+ LEADING(itc)
                         USE_NL(xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itc.trans_qty, 0)
                     )                                           AS  price            -- ���z
                    ,itc.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM   ic_tran_cmp                  itc                      -- �����݌Ƀg�����U�N�V����
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                    ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
              WHERE  itc.doc_type               = cv_doc_type_adji        -- �����^�C�v�i�݌ɒ����j
              AND    itc.reason_code            = cv_reason_code_x988     -- ���R�R�[�h�i�l������j
              AND    itc.trans_date             >= gd_target_date_from    -- �J�n��
              AND    itc.trans_date             <= gd_target_date_to      -- �I����
              AND    iimb.item_id               = itc.item_id
              AND    ilm.lot_id                 = itc.lot_id
              AND    ilm.item_id                = itc.item_id
              AND    xrpm.doc_type              = itc.doc_type
              AND    xrpm.reason_code           = itc.reason_code
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xicv.item_id               = itc.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    itc.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0               -- �ɓ����݌ɊǗ��q��
              AND    itc.item_id                = xsup.item_id(+)
              AND    itc.trans_date             >= xsup.start_date_active(+)
              AND    itc.trans_date             <= xsup.end_date_active(+)
              UNION ALL
              -- �E�݌ɒ����i�ړ����ђ����j
              SELECT /*+ LEADING(itc)
                         USE_NL(iimb ilm xrpm xicv iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup)
                         PUSH_PRED(itc) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itc.trans_qty, 0)
                     )                                           AS  price            -- ���z
                    ,itc.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM   (
                      SELECT /*+ LEADING(xmrih xmril ijm iaj)
                                 USE_NL(xmrih xmril ijm iaj itc2) */
                             itc2.item_id               AS item_id
                            ,itc2.lot_id                AS lot_id
                            ,itc2.doc_type              AS doc_type
                            ,itc2.reason_code           AS reason_code
                            ,itc2.trans_qty             AS trans_qty
                            ,itc2.whse_code             AS whse_code
                            ,xmrih.actual_arrival_date  AS actual_arrival_date
                      FROM   ic_tran_cmp                  itc2                     -- �����݌Ƀg�����U�N�V����
                            ,xxinv_mov_req_instr_headers  xmrih                    -- �ړ��˗��w���w�b�_�A�h�I��
                            ,xxinv_mov_req_instr_lines    xmril                    -- �ړ��˗��w�����׃A�h�I��
                            ,ic_jrnl_mst                  ijm                      -- �W���[�i���}�X�^
                            ,ic_adjs_jnl                  iaj                      -- �݌ɒ����W���[�i��
                      WHERE  itc2.doc_type               = cv_doc_type_adji         -- �����^�C�v�i�݌ɒ����j
                      AND    itc2.reason_code            = cv_reason_code_x123      -- ���R�R�[�h�i�ړ����ђ����j
                      AND    xmrih.actual_arrival_date   >= gd_target_date_from     -- �J�n��
                      AND    xmrih.actual_arrival_date   <= gd_target_date_to       -- �I����
                      AND    xmrih.mov_hdr_id            = xmril.mov_hdr_id
                      AND    itc2.doc_type               = iaj.trans_type
                      AND    itc2.doc_id                 = iaj.doc_id
                      AND    itc2.doc_line               = iaj.doc_line
                      AND    ijm.journal_id              = iaj.journal_id
                      AND    ijm.attribute1              = TO_CHAR(xmril.mov_line_id)
                     )                            itc                      -- �����݌Ƀg�����U�N�V����
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                    ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
              WHERE  iimb.item_id               = itc.item_id
              AND    ilm.lot_id                 = itc.lot_id
              AND    ilm.item_id                = itc.item_id
              AND    xrpm.doc_type              = itc.doc_type
              AND    xrpm.reason_code           = itc.reason_code
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xrpm.rcv_pay_div           = (
                                                   CASE
                                                     WHEN itc.trans_qty >= cn_trans_qty_0 THEN cn_rcv_pay_div_minus_1
                                                     ELSE cn_rcv_pay_div_1
                                                   END
                                                  )
              AND    xicv.item_id               = itc.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    itc.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                        -- �ɓ����݌ɊǗ��q��
              AND    itc.item_id                = xsup.item_id(+)
              AND    itc.actual_arrival_date    >= xsup.start_date_active(+)
              AND    itc.actual_arrival_date    <= xsup.end_date_active(+)
              UNION ALL
              -- �F�݌ɒ����i�َ��i�ڎ��/���o�A���̑����/���o�j
              SELECT /*+ LEADING(itc)
                         USE_NL(xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itc.trans_qty, 0)
                     )                                           AS  price            -- ���z
                    ,itc.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM   ic_tran_cmp                  itc                      -- �����݌Ƀg�����U�N�V����
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                    ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
              WHERE  itc.doc_type               = cv_doc_type_adji           -- �����^�C�v�i�݌ɒ����j
              AND    itc.reason_code            IN ( cv_reason_code_x942     -- ���R�R�[�h�i�َ��i�ڕ��o�j
                                                    ,cv_reason_code_x943     -- ���R�R�[�h�i�َ��i�ڎ���j
                                                    ,cv_reason_code_x950     -- ���R�R�[�h�i���̑�����j
                                                    ,cv_reason_code_x951)    -- ���R�R�[�h�i���̑����o�j
              AND    itc.trans_date             >= gd_target_date_from       -- �J�n��
              AND    itc.trans_date             <= gd_target_date_to         -- �I����
              AND    iimb.item_id               = itc.item_id
              AND    ilm.lot_id                 = itc.lot_id
              AND    ilm.item_id                = itc.item_id
              AND    xrpm.doc_type              = itc.doc_type
              AND    xrpm.reason_code           = itc.reason_code
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xicv.item_id               = itc.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    itc.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                  -- �ɓ����݌ɊǗ��q��
              AND    itc.item_id                = xsup.item_id(+)
              AND    itc.trans_date             >= xsup.start_date_active(+)
              AND    itc.trans_date             <= xsup.end_date_active(+)
              UNION ALL
              -- �G�o�b�`�i�i�ڐU�ֈȊO�j
              SELECT /*+ LEADING(itp xrpm)
                         USE_NL(xrpm grb gmd gbh iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- ���z
                    ,itp.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM   ic_tran_pnd                  itp                      -- �ۗ��݌Ƀg�����U�N�V����
                    ,gme_batch_header             gbh                      -- ���Y�o�b�`�w�b�_
                    ,gme_material_details         gmd                      -- ���Y�����ڍ�
                    ,gmd_routings_b               grb                      -- �H���}�X�^
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                    ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
              WHERE  itp.doc_type               = cv_doc_type_prod        -- �����^�C�v
              AND    itp.completed_ind          = cn_completed_ind_1      -- �����t���O
              AND    itp.trans_date             >= gd_target_date_from    -- �J�n��
              AND    itp.trans_date             <= gd_target_date_to      -- �I����
              AND    xrpm.doc_type              = itp.doc_type
              AND    xrpm.line_type             = itp.line_type
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xrpm.routing_class         = grb.routing_class
              AND    grb.routing_class          <> cv_routing_class_70       -- �i�ڐU�ֈȊO
              AND    xicv.item_id               = itp.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    ( ( gmd.attribute5         IS NULL
                  AND    xrpm.hit_in_div        IS NULL )
                OR     gmd.attribute5           = xrpm.hit_in_div )
              AND    gmd.batch_id               = itp.doc_id
              AND    gmd.line_no                = itp.doc_line
              AND    gmd.line_type              = itp.line_type
              AND    gmd.batch_id               = gbh.batch_id
              AND    gbh.routing_id             = grb.routing_id
              AND    ilm.lot_id                 = itp.lot_id
              AND    ilm.item_id                = itp.item_id
              AND    itp.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                  -- �ɓ����݌ɊǗ��q��
              AND    iimb.item_id               = itp.item_id
              AND    itp.item_id                = xsup.item_id(+)
              AND    itp.trans_date             >= xsup.start_date_active(+)
              AND    itp.trans_date             <= xsup.end_date_active(+)
              UNION ALL
              -- �H���Y�o�b�`�i�i�ڐU�ցj
              SELECT /*+ LEADING(itp xrpm)
                         USE_NL(xrpm grb gmd gbh iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h) */
                     ROUND(NVL(itp.trans_qty, 0) *
                           TO_NUMBER(NVL(ilm.attribute7, 0)) )   AS  price            -- ���z
                    ,itp.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM   ic_tran_pnd                  itp                      -- �ۗ��݌Ƀg�����U�N�V����
                    ,gme_batch_header             gbh                      -- ���Y�o�b�`�w�b�_
                    ,gme_material_details         gmd                      -- ���Y�����ڍ�
                    ,gmd_routings_b               grb                      -- �H���}�X�^
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
              WHERE  itp.doc_type               = cv_doc_type_prod                      -- �����^�C�v
              AND    itp.completed_ind          = cn_completed_ind_1                    -- �����t���O
              AND    itp.trans_date             >= gd_target_date_from      -- �J�n��
              AND    itp.trans_date             <= gd_target_date_to        -- �I����
              AND    itp.reverse_id             IS NULL
              AND    xrpm.dealings_div          IN (cv_dealings_div_308,
                                                    cv_dealings_div_309)    -- ����敪(�i��U�ցj
              AND    xrpm.doc_type              = itp.doc_type
              AND    xrpm.line_type             = itp.line_type
              AND    xrpm.routing_class         = grb.routing_class
              AND    xicv.item_id               = itp.item_id
              AND    xicv.item_class_code       IN (cv_item_class_code_1
                                                   ,cv_item_class_code_4)   -- �����A�����i
              AND    gmd.batch_id               = itp.doc_id
              AND    gmd.line_no                = itp.doc_line
              AND    gmd.line_type              = itp.line_type
              AND    gmd.batch_id               = gbh.batch_id
              AND    ( ( gmd.attribute5         IS NULL
                  AND    xrpm.hit_in_div        IS NULL )
                OR     gmd.attribute5           = xrpm.hit_in_div )
              AND    gbh.routing_id             = grb.routing_id
              AND    ilm.lot_id                 = itp.lot_id
              AND    ilm.item_id                = itp.item_id
              AND    EXISTS (
                             SELECT /*+ LEADING(gmd2)
                                        USE_NL(gmd2 xicv2.iimb xicv2.gic_h xicv2.mcb_h xicv2.mct_h xicv2.gic_s xicv2.mcb_s xicv2.mct_s) */
                                    1
                             FROM   gme_material_details         gmd2   -- ���Y�����ڍ�2
                                   ,xxcmn_item_categories5_v     xicv2  -- OPM�i�ڃJ�e�S���������View5 2
                             WHERE  gmd2.batch_id         = gmd.batch_id
                             AND    gmd2.line_no          = gmd.line_no
                             AND    gmd2.line_type        = cv_line_type_minus_1   -- �����i
                             AND    xicv2.item_id         = gmd2.item_id
                             AND    xicv2.item_class_code = xrpm.item_div_origin
                            )
              AND    EXISTS (
                             SELECT /*+ LEADING(gmd3)
                                        USE_NL(gmd3 xicv3.iimb xicv3.gic_h xicv3.mcb_h xicv3.mct_h xicv3.gic_s xicv3.mcb_s xicv3.mct_s) */
                                    1
                             FROM   gme_material_details         gmd3   -- ���Y�����ڍ�3
                                   ,xxcmn_item_categories5_v     xicv3  -- OPM�i�ڃJ�e�S���������View5 3
                             WHERE  gmd3.batch_id         = gmd.batch_id
                             AND    gmd3.line_no          = gmd.line_no
                             AND    gmd3.line_type        = cv_line_type_1         -- �����i
                             AND    xicv3.item_id         = gmd3.item_id
                             AND    xicv3.item_class_code = xrpm.item_div_ahead
                            )
              AND    itp.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                        -- �ɓ����݌ɊǗ��q��
              UNION ALL
              -- �I�i�ԕi�j�F�L���x��/���_���ޏo��
              SELECT /*+ LEADING(xoha ooha otta xrpm)
                         USE_NL(itp rsl xola ooha otta xrpm)
                         USE_NL(iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- ���z
                    ,itp.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM   ic_tran_pnd                  itp                      -- �ۗ��݌Ƀg�����U�N�V����
                    ,xxwsh_order_headers_all      xoha                     -- �󒍃w�b�_�A�h�I��
                    ,xxwsh_order_lines_all        xola                     -- �󒍖��׃A�h�I��
                    ,rcv_shipment_lines           rsl                      -- �������
                    ,oe_order_headers_all         ooha                     -- �󒍃w�b�_(�W��)
                    ,oe_transaction_types_all     otta                     -- �󒍃^�C�v
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                    ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
              WHERE  itp.doc_type                = cv_doc_type_porc                        -- �����^�C�v
              AND    itp.completed_ind           = cn_completed_ind_1                      -- �����t���O
              AND    xoha.arrival_date           >= gd_target_date_from                    -- �J�n��
              AND    xoha.arrival_date           <= gd_target_date_to                      -- �I����
              AND    xoha.req_status             IN (cv_req_status_4, cv_req_status_8)
              AND    xoha.latest_external_flag   = cv_latest_external_flag_y               -- �ŐV�t���O�FY
              AND    xoha.order_header_id        = xola.order_header_id
              AND    xola.request_item_code      = xola.shipping_item_code
              AND    ooha.header_id              = xoha.header_id
              AND    otta.transaction_type_id    = ooha.order_type_id
              AND    xrpm.shipment_provision_div = otta.attribute1
              AND    xrpm.shipment_provision_div = DECODE(xoha.req_status, cv_req_status_4, cv_ship_prov_div_1
                                                                         , cv_req_status_8, cv_ship_prov_div_2)
              AND    ( xrpm.ship_prov_rcv_pay_category IS NULL
                OR     xrpm.ship_prov_rcv_pay_category = otta.attribute11 )
              AND    otta.attribute4             <> cv_att4_2                              -- �݌ɒ����ȊO
              AND    xrpm.dealings_div           IN (cv_dealings_div_101                   -- ���ޏo��
                                                    ,cv_dealings_div_103)                  -- �L��
              AND    xrpm.doc_type               = itp.doc_type
              AND    xrpm.source_document_code   = cv_source_doc_code_rma
              AND    xrpm.item_div_ahead         IS NULL
              AND    xrpm.item_div_origin        IS NULL
              AND    xicv.item_id                = itp.item_id
              AND    xicv.item_class_code        <> cv_item_class_code_5
              AND    rsl.shipment_header_id      = itp.doc_id
              AND    rsl.line_num                = itp.doc_line
              AND    rsl.oe_order_header_id      = xoha.header_id
              AND    rsl.oe_order_line_id        = xola.line_id
              AND    ilm.lot_id                  = itp.lot_id
              AND    ilm.item_id                 = itp.item_id
              AND    itp.whse_code               = iwm.whse_code
              AND    iwm.attribute1              = cv_att1_0                               -- �ɓ����݌ɊǗ��q��
              AND    iimb.item_id                = itp.item_id
              AND    itp.item_id                 = xsup.item_id(+)
              AND    itp.trans_date              >= xsup.start_date_active(+)
              AND    itp.trans_date              <= xsup.end_date_active(+)
              UNION ALL
              -- �J�i�ԕi�j�F�U�֗L��_���o
              SELECT /*+ LEADING(xoha ooha otta xrpm)
                         USE_NL(ooha otta xrpm rsl xola itp iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup)
                         USE_NL(xicv2.iimb xicv2.gic_s xicv2.mcb_s xicv2.mct_s xicv2.gic_h xicv2.mcb_h xicv2.mct_h) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- ���z
                    ,itp.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM   ic_tran_pnd                  itp                      -- �ۗ��݌Ƀg�����U�N�V����
                    ,xxwsh_order_headers_all      xoha                     -- �󒍃w�b�_�A�h�I��
                    ,xxwsh_order_lines_all        xola                     -- �󒍖��׃A�h�I��
                    ,rcv_shipment_lines           rsl                      -- �������
                    ,oe_order_headers_all         ooha                     -- �󒍃w�b�_(�W��)
                    ,oe_transaction_types_all     otta                     -- �󒍃^�C�v
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,xxcmn_item_categories5_v     xicv2                    -- OPM�i�ڃJ�e�S���������View5 2
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                    ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
              WHERE  itp.doc_type                     = cv_doc_type_porc                      -- �����^�C�v
              AND    itp.completed_ind                = cn_completed_ind_1                    -- �����t���O
              AND    xoha.arrival_date                >= gd_target_date_from                  -- �J�n��
              AND    xoha.arrival_date                <= gd_target_date_to                    -- �I����
              AND    xoha.req_status                  IN (cv_req_status_4, cv_req_status_8)
              AND    xoha.latest_external_flag        = cv_latest_external_flag_y             -- �ŐV�t���O�FY
              AND    xoha.order_header_id             = xola.order_header_id
              AND    ooha.header_id                   = xoha.header_id
              AND    otta.transaction_type_id         = ooha.order_type_id
              AND    xrpm.shipment_provision_div      = otta.attribute1
              AND    xrpm.shipment_provision_div      = DECODE(xoha.req_status, cv_req_status_4, cv_ship_prov_div_1
                                                                               ,cv_req_status_8, cv_ship_prov_div_2)
              AND    xrpm.ship_prov_rcv_pay_category  = otta.attribute11
              AND    otta.attribute4                  <> cv_att4_2                           -- �݌ɒ����ȊO
              AND    xrpm.dealings_div                = cv_dealings_div_106                  -- ����敪�F�U�֗L��_���o
              AND    xrpm.doc_type                    = itp.doc_type
              AND    xrpm.source_document_code        = cv_source_doc_code_rma
              AND    xrpm.break_col_01                IS NOT NULL
              AND    xicv.item_id                     = itp.item_id
              AND    xicv.item_class_code             <> cv_item_class_code_5
              AND    xicv2.item_no                    = xola.request_item_code
              AND    xrpm.item_div_ahead              = xicv2.item_class_code
              AND    rsl.shipment_header_id           = itp.doc_id
              AND    rsl.line_num                     = itp.doc_line
              AND    rsl.oe_order_header_id           = xoha.header_id
              AND    rsl.oe_order_line_id             = xola.line_id
              AND    ilm.lot_id                       = itp.lot_id
              AND    ilm.item_id                      = itp.item_id
              AND    itp.whse_code                    = iwm.whse_code
              AND    iwm.attribute1                   = cv_att1_0                            -- �ɓ����݌ɊǗ��q��
              AND    iimb.item_id                     = itp.item_id
              AND    itp.item_id                      = xsup.item_id(+)
              AND    itp.trans_date                   >= xsup.start_date_active(+)
              AND    itp.trans_date                   <= xsup.end_date_active(+)
              UNION ALL
              -- �K�������
              SELECT SUM(ROUND(tbl14.trans_qty * tbl14.unit_price))   AS  price            -- ���z
                    ,tbl14.whse_code                                  AS  whse_code        -- �q�ɃR�[�h
                    ,tbl14.prod_class_code                            AS  prod_class_code  -- ���i�敪
                    ,tbl14.item_class_code                            AS  item_class_code  -- �i�ڋ敪
              FROM   (
                      SELECT /*+ LEADING(itp)
                                 USE_NL(rt rsl xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                             SUM(NVL(itp.trans_qty, 0))          AS  trans_qty        -- ����
                            ,(CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                             END)                                AS  unit_price       -- �P��
                            ,itp.whse_code                       AS  whse_code        -- �q�ɃR�[�h
                            ,xicv.prod_class_code                AS  prod_class_code  -- ���i�敪
                            ,xicv.item_class_code                AS  item_class_code  -- �i�ڋ敪
                            ,rsl.attribute1                      AS  txns_id          -- ���ID
                      FROM   ic_tran_pnd                  itp                      -- �ۗ��݌Ƀg�����U�N�V����
                            ,rcv_shipment_lines           rsl                      -- �������
                            ,rcv_transactions             rt                       -- ������
                            ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                            ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                            ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                            ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                            ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                            ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
                      WHERE  itp.doc_type                     = cv_doc_type_porc                      -- �����^�C�v
                      AND    itp.completed_ind                = cn_completed_ind_1                    -- �����t���O
                      AND    itp.trans_date                   >= gd_target_date_from                  -- �J�n��
                      AND    itp.trans_date                   <= gd_target_date_to                    -- �I����
                      AND    ilm.lot_id                       = itp.lot_id
                      AND    ilm.item_id                      = itp.item_id
                      AND    xicv.item_id                     = itp.item_id
                      AND    xicv.item_class_code             <> cv_item_class_code_5
                      AND    rsl.shipment_header_id           = itp.doc_id
                      AND    rsl.line_num                     = itp.doc_line
                      AND    rt.transaction_id                = itp.line_id
                      AND    rt.shipment_line_id              = rsl.shipment_line_id
                      AND    xrpm.doc_type                    = itp.doc_type
                      AND    xrpm.source_document_code        = rsl.source_document_code
                      AND    xrpm.transaction_type            = rt.transaction_type
                      AND    xrpm.break_col_01                IS NOT NULL
                      AND    itp.whse_code                    = iwm.whse_code
                      AND    iwm.attribute1                   = cv_att1_0                             -- �ɓ����݌ɊǗ��q��
                      AND    iimb.item_id                     = itp.item_id
                      AND    itp.item_id                      = xsup.item_id(+)
                      AND    itp.trans_date                   >= xsup.start_date_active(+)
                      AND    itp.trans_date                   <= xsup.end_date_active(+)
                      GROUP BY (CASE iimb.attribute15
                                WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                                ELSE DECODE(iimb.lot_ctl
                                           ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                           ,NVL(xsup.stnd_unit_price, 0))
                                END)
                               , itp.whse_code, xicv.prod_class_code, xicv.item_class_code
                               ,rsl.attribute1
                     ) tbl14
              GROUP BY tbl14.whse_code, tbl14.prod_class_code, tbl14.item_class_code
              UNION ALL
              -- �L�L���x��/���_���ޏo��
              SELECT /*+ LEADING(xoha ooha otta xrpm)
                         USE_NL(wdd xola ooha otta xrpm itp)
                         USE_NL(iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- ���z
                    ,itp.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM   ic_tran_pnd                  itp                      -- �ۗ��݌Ƀg�����U�N�V����
                    ,xxwsh_order_headers_all      xoha                     -- �󒍃w�b�_�A�h�I��
                    ,xxwsh_order_lines_all        xola                     -- �󒍖��׃A�h�I��
                    ,wsh_delivery_details         wdd                      -- �o�ה�������
                    ,oe_order_headers_all         ooha                     -- �󒍃w�b�_(�W��)
                    ,oe_transaction_types_all     otta                     -- �󒍃^�C�v
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                    ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
              WHERE  itp.doc_type                     = cv_doc_type_omso                        -- �����^�C�v
              AND    itp.completed_ind                = cn_completed_ind_1                      -- �����t���O
              AND    xoha.arrival_date               >= gd_target_date_from                     -- �J�n��
              AND    xoha.arrival_date               <= gd_target_date_to                       -- �I����
              AND    xoha.req_status                  IN (cv_req_status_4, cv_req_status_8)
              AND    xoha.latest_external_flag        = cv_latest_external_flag_y               -- �ŐV�t���O�FY
              AND    xoha.order_header_id             = xola.order_header_id
              AND    ooha.header_id                   = xoha.header_id
              AND    xola.request_item_code           = xola.shipping_item_code
              AND    otta.transaction_type_id         = ooha.order_type_id
              AND    xrpm.shipment_provision_div      = otta.attribute1
              AND    xrpm.shipment_provision_div      = DECODE(xoha.req_status, cv_req_status_4, cv_ship_prov_div_1
                                                                               ,cv_req_status_8, cv_ship_prov_div_2)
              AND    ( xrpm.ship_prov_rcv_pay_category  IS NULL
                OR     xrpm.ship_prov_rcv_pay_category  = otta.attribute11 )
              AND    xrpm.break_col_01                IS NOT NULL
              AND    otta.attribute4                  <> cv_att4_2                              -- �݌ɒ����ȊO
              AND    otta.attribute1                  IN (cv_att1_1, cv_att1_2)
              AND    xrpm.dealings_div                IN (cv_dealings_div_101
                                                         ,cv_dealings_div_103)                  -- ����敪�F���ޏo�ׁA�L��
              AND    xrpm.doc_type                    = itp.doc_type
              AND    xrpm.item_div_ahead              IS NULL
              AND    xrpm.item_div_origin             IS NULL
              AND    xicv.item_id                     = itp.item_id
              AND    xicv.item_class_code             <> cv_item_class_code_5
              AND    wdd.delivery_detail_id           = itp.line_detail_id
              AND    wdd.source_header_id             = ooha.header_id
              AND    wdd.source_line_id               = xola.line_id
              AND    ilm.lot_id                       = itp.lot_id
              AND    ilm.item_id                      = itp.item_id
              AND    itp.whse_code                    = iwm.whse_code
              AND    iwm.attribute1                   = cv_att1_0                               -- �ɓ����݌ɊǗ��q��
              AND    iimb.item_id                     = itp.item_id
              AND    itp.item_id                      = xsup.item_id(+)
              AND    itp.trans_date                   >= xsup.start_date_active(+)
              AND    itp.trans_date                   <= xsup.end_date_active(+)
              UNION ALL
              -- �M�U�֗L��_���o
              SELECT /*+ LEADING(xoha ooha otta xrpm)
                         USE_NL(wdd xola ooha otta xrpm itp)
                         USE_NL(iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- ���z
                    ,itp.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM   ic_tran_pnd                  itp                      -- �ۗ��݌Ƀg�����U�N�V����
                    ,xxwsh_order_headers_all      xoha                     -- �󒍃w�b�_�A�h�I��
                    ,xxwsh_order_lines_all        xola                     -- �󒍖��׃A�h�I��
                    ,wsh_delivery_details         wdd                      -- ��������
                    ,oe_order_headers_all         ooha                     -- �󒍃w�b�_(�W��)
                    ,oe_transaction_types_all     otta                     -- �󒍃^�C�v
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                    ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
              WHERE  itp.doc_type                     = cv_doc_type_omso                      -- �����^�C�v
              AND    itp.completed_ind                = cn_completed_ind_1                    -- �����t���O
              AND    xoha.arrival_date                >= gd_target_date_from                  -- �J�n��
              AND    xoha.arrival_date                <= gd_target_date_to                    -- �I����
              AND    xoha.req_status                  = cv_req_status_8                       -- �o�׎��ьv���
              AND    xoha.latest_external_flag        = cv_latest_external_flag_y             -- �ŐV�t���O�FY
              AND    xoha.order_header_id             = xola.order_header_id
              AND    ooha.header_id                   = xoha.header_id
              AND    otta.transaction_type_id         = ooha.order_type_id
              AND    xrpm.shipment_provision_div      = otta.attribute1
              AND    xrpm.ship_prov_rcv_pay_category  = otta.attribute11
              AND    otta.attribute4                  <> cv_att4_2                            -- �݌ɒ����ȊO
              AND    otta.attribute1                  = cv_att1_2
              AND    xrpm.doc_type                    = itp.doc_type
              AND    xrpm.dealings_div                = cv_dealings_div_106                   -- ����敪�F�U�֗L��_���o
              AND    xrpm.shipment_provision_div      = DECODE(xoha.req_status, cv_req_status_4, cv_ship_prov_div_1
                                                                               ,cv_req_status_8, cv_ship_prov_div_2)
              AND    xrpm.break_col_01                IS NOT NULL
              AND    xicv.item_id                     = itp.item_id
              AND    xicv.item_class_code             <> cv_item_class_code_5
              AND    wdd.delivery_detail_id           = itp.line_detail_id
              AND    wdd.source_header_id             = ooha.header_id
              AND    wdd.source_line_id               = xola.line_id
              AND    ilm.lot_id                       = itp.lot_id
              AND    ilm.item_id                      = itp.item_id
              AND    itp.whse_code                    = iwm.whse_code
              AND    iwm.attribute1                   = cv_att1_0                             -- �ɓ����݌ɊǗ��q��
              AND    iimb.item_id                     = itp.item_id
              AND    itp.item_id                      = xsup.item_id(+)
              AND    itp.trans_date                   >= xsup.start_date_active(+)
              AND    itp.trans_date                   <= xsup.end_date_active(+)
              AND    EXISTS (SELECT /*+ USE_NL(xicv2.iimb xicv2.gic_h xicv2.mcb_h xicv2.mct_h xicv2.gic_s xicv2.mcb_s xicv2.mct_s) */
                                    1
                             FROM   xxcmn_item_categories5_v     xicv2
                             WHERE  xicv2.item_no         = xola.request_item_code
                             AND    xicv2.item_class_code = cv_item_class_code_5)
              UNION ALL
              -- �N�U�֏o��_���o
              SELECT /*+ LEADING(xoha ooha otta xrpm)
                         USE_NL(wdd xola ooha otta xrpm itp)
                         USE_NL(iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- ���z
                    ,itp.whse_code                               AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                        AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                        AS  item_class_code  -- �i�ڋ敪
              FROM   ic_tran_pnd                  itp                      -- �ۗ��݌Ƀg�����U�N�V����
                    ,xxwsh_order_headers_all      xoha                     -- �󒍃w�b�_�A�h�I��
                    ,xxwsh_order_lines_all        xola                     -- �󒍖��׃A�h�I��
                    ,wsh_delivery_details         wdd                      -- ��������
                    ,oe_order_headers_all         ooha                     -- �󒍃w�b�_(�W��)
                    ,oe_transaction_types_all     otta                     -- �󒍃^�C�v
                    ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
                    ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
                    ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
                    ,ic_whse_mst                  iwm                      -- OPM�q�Ƀ}�X�^
                    ,ic_item_mst_b                iimb                     -- OPM�i�ڃ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup                     -- �W���������u������
              WHERE  itp.doc_type                     = cv_doc_type_omso                      -- �����^�C�v
              AND    itp.completed_ind                = cn_completed_ind_1                    -- �����t���O
              AND    xoha.arrival_date               >= gd_target_date_from                   -- �J�n��
              AND    xoha.arrival_date               <= gd_target_date_to                     -- �I����
              AND    xoha.req_status                  = cv_req_status_4                       -- �o�׎��ьv���
              AND    xoha.latest_external_flag        = cv_latest_external_flag_y             -- �ŐV�t���O�FY
              AND    xoha.order_header_id             = xola.order_header_id
              AND    ooha.header_id                   = xoha.header_id
              AND    otta.transaction_type_id         = ooha.order_type_id
              AND    xrpm.shipment_provision_div      = otta.attribute1
              AND    otta.attribute4                  <> cv_att4_2                            -- �݌ɒ����ȊO
              AND    otta.attribute1                  = cv_att1_1
              AND    xrpm.doc_type                    = itp.doc_type
              AND    xrpm.dealings_div                = cv_dealings_div_113                   -- ����敪�F�U�֏o��_���o
              AND    xrpm.shipment_provision_div      = DECODE(xoha.req_status, cv_req_status_4, cv_ship_prov_div_1
                                                                               ,cv_req_status_8, cv_ship_prov_div_2)
              AND    xrpm.break_col_01                IS NOT NULL
              AND    xicv.item_id                     = itp.item_id
              AND    xicv.item_class_code             <> cv_item_class_code_5
              AND    wdd.delivery_detail_id           = itp.line_detail_id
              AND    wdd.source_header_id             = ooha.header_id
              AND    wdd.source_line_id               = xola.line_id
              AND    ilm.lot_id                       = itp.lot_id
              AND    ilm.item_id                      = itp.item_id
              AND    itp.whse_code                    = iwm.whse_code
              AND    iwm.attribute1                   = cv_att1_0                             -- �ɓ����݌ɊǗ��q��
              AND    iimb.item_id                     = itp.item_id
              AND    itp.item_id                      = xsup.item_id(+)
              AND    itp.trans_date                   >= xsup.start_date_active(+)
              AND    itp.trans_date                   <= xsup.end_date_active(+)
              AND    EXISTS (SELECT /*+ USE_NL(xicv2.iimb xicv2.gic_h xicv2.mcb_h xicv2.mct_h xicv2.gic_s xicv2.mcb_s xicv2.mct_s) */
                                    1
                             FROM   xxcmn_item_categories5_v     xicv2
                             WHERE  xicv2.item_no         = xola.request_item_code
                             AND    xicv2.item_class_code = cv_item_class_code_5)
              UNION ALL
              -- �O�������I�����z�̎Z�o
              SELECT /*+ LEADING(xsirs1)
                   USE_NL(iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xlc) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1
                                         ,TO_NUMBER(NVL(xlc.unit_ploce, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(xsirs1.qty, 0) * -1 )   AS  price            -- ���z
                    ,xsirs1.invent_whse_code                   AS  whse_code        -- �I���q�ɃR�[�h
                    ,xicv.prod_class_code                      AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                      AS  item_class_code  -- �i�ڋ敪
              FROM   (SELECT  /*+ INDEX(xsirs XXINV_SIR_N06) 
                                  INDEX(iwm2 IC_WHSE_MST_PK) */
                               xsirs.invent_whse_code                  AS  invent_whse_code   -- �I���q�ɃR�[�h
                              ,xsirs.item_id                           AS  item_id            -- �i��ID
                              ,xsirs.lot_id                            AS  lot_id             -- ���b�gID
                              ,SUM(ROUND(NVL(xsirs.case_amt,0) * 
                                         NVL(xsirs.content,0) + 
                                         NVL(xsirs.loose_amt,0), 3))   AS  qty                -- ����
                              ,xsirs.invent_date                       AS  invent_date        -- �I����
                      FROM    xxinv_stc_inventory_result  xsirs                              -- �I�����ʃe�[�u��
                             ,ic_whse_mst                 iwm2                               -- OPM�q�Ƀ}�X�^
                      WHERE  xsirs.invent_date  >= gd_target_date_from
                      AND    xsirs.invent_date  <= gd_target_date_to
                      AND    iwm2.whse_code     = xsirs.invent_whse_code
                      AND    iwm2.attribute1    = cv_att1_0               -- �ɓ����݌ɊǗ��q��
                      GROUP BY xsirs.invent_whse_code, xsirs.item_id, xsirs.lot_id, xsirs.invent_date
                     )                            xsirs1            -- �I�����ʃe�[�u��1
                    ,xxcmn_item_categories5_v     xicv              -- OPM�i�ڃJ�e�S���������View5
                    ,xxcmn_lot_cost               xlc               -- ���b�g�ʌ����A�h�I��
                    ,ic_whse_mst                  iwm               -- OPM�q�Ƀ}�X�^
                    ,ic_item_mst_b                iimb              -- OPM�i�ڃ}�X�^
                    ,xxcmn_stnd_unit_price_v      xsup              -- �W���������u������
              WHERE  xsirs1.invent_whse_code  = iwm.whse_code
              AND    iwm.attribute1           = cv_att1_0                 -- �ɓ����݌ɊǗ��q��
              AND    xlc.lot_id(+)            = xsirs1.lot_id
              AND    xlc.item_id(+)           = xsirs1.item_id
              AND    xsirs1.invent_date       >= gd_target_date_from
              AND    xsirs1.invent_date       <= gd_target_date_to
              AND    xicv.item_id             = xsirs1.item_id
              AND    xicv.item_class_code     <> cv_item_class_code_5
              AND    xsirs1.item_id           = iimb.item_id
              AND    xsirs1.item_id           = xsup.item_id(+)
              AND    xsirs1.invent_date       >= xsup.start_date_active(+)
              AND    xsirs1.invent_date       <= xsup.end_date_active(+)
              UNION ALL
              -- �P�����ϑ����݌Ɋz�̎Z�o
              SELECT /*+ LEADING(xsims ) 
                         USE_NL(iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xlc) */
                     ROUND(-1                                  * 
                           (NVL(xsims.cargo_stock, 0)   -
                            NVL(xsims.cargo_stock_not_stn, 0)) *
                           (CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1
                                         ,TO_NUMBER(NVL(xlc.unit_ploce, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END)     )                               AS  price            -- ���z
                    ,xsims.whse_code                                 AS  whse_code        -- �q�ɃR�[�h
                    ,xicv.prod_class_code                            AS  prod_class_code  -- ���i�敪
                    ,xicv.item_class_code                            AS  item_class_code  -- �i�ڋ敪
              FROM   xxinv_stc_inventory_month_stck       xsims             -- �I�������݌�
                    ,xxcmn_item_categories5_v             xicv              -- OPM�i�ڃJ�e�S���������View5 1
                    ,xxcmn_lot_cost                       xlc               -- ���b�g�ʌ���
                    ,ic_whse_mst                          iwm               -- OPM�q�Ƀ}�X�^
                    ,ic_item_mst_b                        iimb              -- OPM�i�ڃ}�X�^
                    ,xxcmn_stnd_unit_price_v              xsup              -- �W���������u������
              WHERE  xsims.whse_code        = iwm.whse_code
              AND    iwm.attribute1         = cv_att1_0           -- �ɓ����Ǘ��݌�
              AND    xlc.lot_id(+)          = xsims.lot_id
              AND    xlc.item_id(+)         = xsims.item_id
              AND    xsims.invent_ym        = gv_period_name3
              AND    xicv.item_id           = xsims.item_id
              AND    xicv.item_class_code   <> cv_item_class_code_5
              AND    xsims.item_id           = iimb.item_id
              AND    xsims.item_id           = xsup.item_id(+)
              AND    TO_DATE(xsims.invent_ym,cv_date_format_yyyymm) >= xsup.start_date_active(+)
              AND    TO_DATE(xsims.invent_ym,cv_date_format_yyyymm) <= xsup.end_date_active(+)
             ) tbl
      GROUP BY tbl.whse_code, tbl.prod_class_code, tbl.item_class_code
      ORDER BY tbl.whse_code, tbl.prod_class_code, tbl.item_class_code
      ;
    -- GL�d��OIF���7�i�[�pPL/SQL�\
    TYPE journal_oif_data7_ttype IS TABLE OF get_journal_oif_data7_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data7_tab                     journal_oif_data7_ttype;
--
    -- �i�ڋ敪�F�����i�̏ꍇ�̑Ώۑq�ɒ��o�J�[�\��
    CURSOR get_cost_whse_data_cur
    IS
      SELECT flvv.lookup_code     AS whse_data   -- �q�ɃR�[�h
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type       = cv_type_package_cost_whse
      AND    flvv.attribute3        = cv_att3_1
      AND    flvv.start_date_active <= gd_target_date_from
      AND    flvv.end_date_active   >= gd_target_date_to
      ;
    -- �����i�Ώۑq�Ɋi�[�pPL/SQL�\
    TYPE cost_whse_data_ttype IS TABLE OF get_cost_whse_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
    cost_whse_data_tab                    cost_whse_data_ttype;
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
--
    -- ===============================
    -- (1)��� ������U�֕��i�����i���猴���ցj
    -- ===============================
--
    -- ������
    g_gme_material_details_tab.DELETE;               -- ���Y�����ڍ׃f�[�^�X�V���i�[�pPL/SQL�\�̏�����
    gv_process_no          := cv_process_no_01;      -- �����ԍ��F(1)��� ������U�֕��i�����i���猴���ցj
    gv_item_class_code_hdr := cv_item_class_code_1;  -- �i�ڋ敪�F����
    gv_prod_class_code_hdr := cv_prod_class_code_1;  -- ���i�敪�F���[�t
    gv_ptn_siwake          := cv_ptn_siwake_06;      -- �d��p�^�[���F6�i�����i���猴���ւ̕i��ړ��j
--
    -- ===============================
    -- ���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_journal_oif_data1_cur;
    -- �o���N�t�F�b�`
    FETCH get_journal_oif_data1_cur BULK COLLECT INTO journal_oif_data1_tab;
    -- �J�[�\���N���[�Y
    IF ( get_journal_oif_data1_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data1_cur;
    END IF;
--
    -- ���C�����[�v1
    <<main_loop1>>
    FOR ln_count in 1..journal_oif_data1_tab.COUNT LOOP
--
      -- �����Ώی�����ݒ�
      gn_target_cnt := gn_target_cnt + 1;
      -- �Ώی������J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
      ln_out_count  := ln_out_count + 1;
      -- �u���Y�����ڍ�ID�v��ێ�
      g_gme_material_details_tab(ln_out_count).material_detail_id := journal_oif_data1_tab(ln_count).material_detail_id;
      -- ���z�����Z
      gn_price_all  := gn_price_all + journal_oif_data1_tab(ln_count).price;
--
    END LOOP main_loop1;
--
    -- ���z��0�̏ꍇ�AA-5,A-6�̏��������Ȃ�
    IF ( gn_price_all = 0 ) THEN
      -- �X�L�b�v�����ɑΏی����������Z
      gn_warn_cnt := gn_warn_cnt + ln_out_count;
    ELSE
      -- ===============================
      -- �d��OIF�o�^(A-5)
      -- ===============================
      ins_journal_oif(
        ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���Y�����ڍ׃f�[�^�X�V(A-6)
      -- ===============================
      upd_gme_material_details_data(
        ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- �i2�j���Y���o �@�R�[�q�[�����q�ɁiF30�j�ȊO
    -- ===============================
    -- ������
    g_gme_material_details_tab.DELETE;               -- ���Y�����ڍ׃f�[�^�X�V���i�[�pPL/SQL�\�̏�����
    gv_whse_code           := NULL;                  -- �q�ɃR�[�h
    ln_out_count           := 0;                     -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
    gn_price_all           := 0;                     -- ���z
    gv_process_no          := cv_process_no_02;      -- �����ԍ��F(2)���Y���o
    gv_item_class_code_hdr := cv_item_class_code_1;  -- �i�ڋ敪�F����
    gv_prod_class_code_hdr := cv_prod_class_code_1;  -- ���i�敪�F���[�t
    gv_ptn_siwake          := cv_ptn_siwake_01;      -- �d��p�^�[���F1
--
    -- ===============================
    -- ���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_journal_oif_data2_1_cur;
    -- �o���N�t�F�b�`
    FETCH get_journal_oif_data2_1_cur BULK COLLECT INTO journal_oif_data2_1_tab;
    -- �J�[�\���N���[�Y
    IF ( get_journal_oif_data2_1_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data2_1_cur;
    END IF;
--
    <<main_loop2_1>>
    FOR ln_count in 1..journal_oif_data2_1_tab.COUNT LOOP
--
      -- �����Ώی�����ݒ�
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �q�ɃR�[�h���O���R�[�h�ƈႤ�ꍇ�A�O���R�[�h�̓o�^���s��(1���R�[�h�ڂ͑ΏۊO)
      IF ( NVL(gv_whse_code, journal_oif_data2_1_tab(ln_count).whse_code ) <> journal_oif_data2_1_tab(ln_count).whse_code ) THEN
        -- ���z��0�̏ꍇ�AA-5,A-6�̏��������Ȃ�
        IF ( gn_price_all = 0 ) THEN
          -- �X�L�b�v�����ɑΏی����������Z
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- �d��OIF�o�^(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- ���Y�����ڍ׃f�[�^�X�V(A-6)
          -- ===============================
          upd_gme_material_details_data(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- �q�ɒP�ʂ̏������ϐ��̏����������{
        -- ===============================
        ln_out_count     := 0;              -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
        gn_price_all     := 0;              -- ���z
        g_gme_material_details_tab.DELETE;  -- ���Y�����ڍ׃f�[�^�X�V���i�[�pPL/SQL�\�̏�����
      END IF;
--
      -- �Ώی������J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
      ln_out_count  := ln_out_count + 1;
      -- �u���Y�����ڍ�ID�v��ێ�
      g_gme_material_details_tab(ln_out_count).material_detail_id := journal_oif_data2_1_tab(ln_count).material_detail_id;
      -- ���z�����Z
      gn_price_all  := gn_price_all + journal_oif_data2_1_tab(ln_count).price;
      -- �q�ɃR�[�h��ێ�
      gv_whse_code  := journal_oif_data2_1_tab(ln_count).whse_code;
--
      -- �ŏI���R�[�h�̏ꍇ
      IF ( ln_count = journal_oif_data2_1_tab.COUNT ) THEN
        -- ���z��0�̏ꍇ�AA-5,A-6�̏��������Ȃ�
        IF ( gn_price_all = 0 ) THEN
          -- �X�L�b�v�����ɑΏی����������Z
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- �d��OIF�o�^(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- ���Y�����ڍ׃f�[�^�X�V(A-6)
          -- ===============================
          upd_gme_material_details_data(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop2_1;
--
    -- ===============================
    -- �i2�j���Y���o �A�R�[�q�[�����q�ɁiF30�j
    -- ===============================
    -- ������
    g_gme_material_details_tab.DELETE;               -- ���Y�����ڍ׃f�[�^�X�V���i�[�pPL/SQL�\�̏�����
    gv_whse_code           := NULL;                  -- �q�ɃR�[�h
    ln_out_count           := 0;                     -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
    gn_price_all           := 0;                     -- ���z
    gv_process_no          := cv_process_no_02;      -- �����ԍ��F(2)���Y���o
    gv_item_class_code_hdr := cv_item_class_code_1;  -- �i�ڋ敪�F����
    gv_prod_class_code_hdr := cv_prod_class_code_1;  -- ���i�敪�F���[�t
    gv_ptn_siwake          := cv_ptn_siwake_02;      -- �d��p�^�[���F2
--
    -- ===============================
    -- ���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_journal_oif_data2_2_cur;
    -- �o���N�t�F�b�`
    FETCH get_journal_oif_data2_2_cur BULK COLLECT INTO journal_oif_data2_2_tab;
    -- �J�[�\���N���[�Y
    IF ( get_journal_oif_data2_2_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data2_2_cur;
    END IF;
--
    <<main_loop2_2>>
    FOR ln_count in 1..journal_oif_data2_2_tab.COUNT LOOP
--
      -- �����Ώی�����ݒ�
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �q�ɃR�[�h���O���R�[�h�ƈႤ�ꍇ�A�O���R�[�h�̓o�^���s��(1���R�[�h�ڂ͑ΏۊO)
      IF ( NVL(gv_whse_code, journal_oif_data2_2_tab(ln_count).whse_code ) <> journal_oif_data2_2_tab(ln_count).whse_code ) THEN
        -- ���z��0�̏ꍇ�AA-5,A-6�̏��������Ȃ�
        IF ( gn_price_all = 0 ) THEN
          -- �X�L�b�v�����ɑΏی����������Z
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- �d��OIF�o�^(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- ���Y�����ڍ׃f�[�^�X�V(A-6)
          -- ===============================
          upd_gme_material_details_data(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- �q�ɒP�ʂ̏������ϐ��̏����������{
        -- ===============================
        ln_out_count     := 0;              -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
        gn_price_all     := 0;              -- ���z
        g_gme_material_details_tab.DELETE;  -- ���Y�����ڍ׃f�[�^�X�V���i�[�pPL/SQL�\�̏�����
      END IF;
--
      -- �Ώی������J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
      ln_out_count  := ln_out_count + 1;
      -- �u���Y�����ڍ�ID�v��ێ�
      g_gme_material_details_tab(ln_out_count).material_detail_id := journal_oif_data2_2_tab(ln_count).material_detail_id;
      -- ���z�����Z
      gn_price_all  := gn_price_all + journal_oif_data2_2_tab(ln_count).price;
      -- �q�ɃR�[�h��ێ�
      gv_whse_code  := journal_oif_data2_2_tab(ln_count).whse_code;
--
      -- �ŏI���R�[�h�̏ꍇ
      IF ( ln_count = journal_oif_data2_2_tab.COUNT ) THEN
        -- ���z��0�̏ꍇ�AA-5,A-6�̏��������Ȃ�
        IF ( gn_price_all = 0 ) THEN
          -- �X�L�b�v�����ɑΏی����������Z
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- �d��OIF�o�^(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- ���Y�����ڍ׃f�[�^�X�V(A-6)
          -- ===============================
          upd_gme_material_details_data(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop2_2;
--
    -- ===============================
    -- �i3�j���ꕥ�o
    -- ===============================
    -- ������
    g_gme_material_details_tab.DELETE;            -- ���Y�����ڍ׃f�[�^�X�V���i�[�pPL/SQL�\�̏�����
    gv_whse_code            := NULL;              -- �q�ɃR�[�h
    ln_out_count            := 0;                 -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
    gn_price_all            := 0;                 -- ���z
    gv_process_no           := cv_process_no_03;  -- �����ԍ��F�i3�j���ꕥ�o
    gv_whse_code            := NULL;              -- �q�ɃR�[�h
    gv_item_class_code_hdr  := NULL;              -- �i�ڋ敪
    gv_prod_class_code_hdr  := NULL;              -- ���i�敪
    gv_ptn_siwake           := NULL;              -- �d��p�^�[��
--
    -- ===============================
    -- ���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_journal_oif_data3_cur;
    -- �o���N�t�F�b�`
    FETCH get_journal_oif_data3_cur BULK COLLECT INTO journal_oif_data3_tab;
    -- �J�[�\���N���[�Y
    IF ( get_journal_oif_data3_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data3_cur;
    END IF;
--
    <<main_loop3>>
    FOR ln_count in 1..journal_oif_data3_tab.COUNT LOOP
--
      -- �����Ώی�����ݒ�
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �i�ڃR�[�h�����i�R�[�h���O���R�[�h�ƈႤ�ꍇ�A�O���R�[�h�̓o�^���s��(1���R�[�h�ڂ͑ΏۊO)
      IF ( ( NVL(gv_item_class_code_hdr, journal_oif_data3_tab(ln_count).item_class_code ) <> journal_oif_data3_tab(ln_count).item_class_code )
       OR  ( NVL(gv_prod_class_code_hdr, journal_oif_data3_tab(ln_count).prod_class_code ) <> journal_oif_data3_tab(ln_count).prod_class_code ) ) THEN
        -- ���z��0�̏ꍇ�AA-5,A-6�̏��������Ȃ�
        IF ( gn_price_all = 0 ) THEN
          -- �X�L�b�v�����ɑΏی����������Z
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- �d��OIF�o�^(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- ���Y�����ڍ׃f�[�^�X�V(A-6)
          -- ===============================
          upd_gme_material_details_data(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- �i�ڋ敪�E���i�敪�P�ʂ̏������ϐ��̏����������{
        -- ===============================
        ln_out_count     := 0;              -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
        gn_price_all     := 0;              -- ���z
        g_gme_material_details_tab.DELETE;  -- ���Y�����ڍ׃f�[�^�X�V���i�[�pPL/SQL�\�̏�����
      END IF;
--
      -- �Ώی������J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
      ln_out_count  := ln_out_count + 1;
      -- �u���Y�����ڍ�ID�v��ێ�
      g_gme_material_details_tab(ln_out_count).material_detail_id := journal_oif_data3_tab(ln_count).material_detail_id;
      -- ���z�����Z
      gn_price_all  := gn_price_all + journal_oif_data3_tab(ln_count).price;
      -- �i�ڋ敪��ێ�
      gv_item_class_code_hdr  := journal_oif_data3_tab(ln_count).item_class_code;
      -- ���i�敪��ێ�
      gv_prod_class_code_hdr  := journal_oif_data3_tab(ln_count).prod_class_code;
      -- ����Ȗڐ����p�̒l���Z�b�g
      -- ���i�敪�F���[�t�A�i�ڋ敪�F�����̏ꍇ
      IF    ( gv_prod_class_code_hdr = cv_prod_class_code_1 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_1 ) THEN
        -- �d��p�^�[���F3�i������ ����i�������j�j
        gv_ptn_siwake          := cv_ptn_siwake_03;
      -- ���i�敪�F�h�����N�A�i�ڋ敪�F�����̏ꍇ
      ELSIF ( gv_prod_class_code_hdr = cv_prod_class_code_2 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_1 ) THEN
        -- �d��p�^�[���F1�i������ ����i��؁j�j
        gv_ptn_siwake          := cv_ptn_siwake_01;
      -- ���i�敪�F���[�t�A�i�ڋ敪�F���ނ̏ꍇ
      ELSIF ( gv_prod_class_code_hdr = cv_prod_class_code_1 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_2 ) THEN
        -- �d��p�^�[���F2�i���[�t���� �H��g�p���j
        gv_ptn_siwake          := cv_ptn_siwake_02;
      END IF;
--
      -- �ŏI���R�[�h�̏ꍇ
      IF ( ln_count = journal_oif_data3_tab.COUNT ) THEN
        -- ���z��0�̏ꍇ�AA-5,A-6�̏��������Ȃ�
        IF ( gn_price_all = 0 ) THEN
          -- �X�L�b�v�����ɑΏی����������Z
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- �d��OIF�o�^(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- ���Y�����ڍ׃f�[�^�X�V(A-6)
          -- ===============================
          upd_gme_material_details_data(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop3;
--
    -- ===============================
    -- (4)��Z�b�g���o
    -- ===============================
    -- ������
    g_gme_material_details_tab.DELETE;                -- ���Y�����ڍ׃f�[�^�X�V���i�[�pPL/SQL�\�̏�����
    gv_whse_code            := NULL;                  -- �q�ɃR�[�h
    ln_out_count            := 0;                     -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
    gn_price_all            := 0;                     -- ���z
    gv_process_no           := cv_process_no_04;      -- �����ԍ��F(4)��Z�b�g���o
    gv_item_class_code_hdr  := cv_item_class_code_2;  -- �i�ڋ敪�F����
    gv_prod_class_code_hdr  := cv_prod_class_code_1;  -- ���i�敪�F���[�t
    gv_ptn_siwake           := cv_ptn_siwake_01;      -- �d��p�^�[���F1�i���[�t���� �H��g�p���j
--
    -- ===============================
    -- ���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_journal_oif_data4_cur;
    -- �o���N�t�F�b�`
    FETCH get_journal_oif_data4_cur BULK COLLECT INTO journal_oif_data4_tab;
    -- �J�[�\���N���[�Y
    IF ( get_journal_oif_data4_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data4_cur;
    END IF;
--
    <<main_loop4>>
    FOR ln_count in 1..journal_oif_data4_tab.COUNT LOOP
--
      -- �����Ώی�����ݒ�
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �q�ɃR�[�h���O���R�[�h�ƈႤ�ꍇ�A�O���R�[�h�̓o�^���s��(1���R�[�h�ڂ͑ΏۊO)
      IF ( NVL(gv_whse_code, journal_oif_data4_tab(ln_count).whse_code ) <> journal_oif_data4_tab(ln_count).whse_code ) THEN
        -- ���z��0�̏ꍇ�AA-5,A-6�̏��������Ȃ�
        IF ( gn_price_all = 0 ) THEN
          -- �X�L�b�v�����ɑΏی����������Z
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- �d��OIF�o�^(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- ���Y�����ڍ׃f�[�^�X�V(A-6)
          -- ===============================
          upd_gme_material_details_data(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- �q�ɒP�ʂ̏������ϐ��̏����������{
        -- ===============================
        ln_out_count     := 0;              -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
        gn_price_all     := 0;              -- ���z
        g_gme_material_details_tab.DELETE;  -- ���Y�����ڍ׃f�[�^�X�V���i�[�pPL/SQL�\�̏�����
      END IF;
--
      -- �Ώی������J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
      ln_out_count  := ln_out_count + 1;
      -- �u���Y�����ڍ�ID�v��ێ�
      g_gme_material_details_tab(ln_out_count).material_detail_id := journal_oif_data4_tab(ln_count).material_detail_id;
      -- ���z�����Z
      gn_price_all  := gn_price_all + journal_oif_data4_tab(ln_count).price;
      -- �q�ɃR�[�h��ێ�
      gv_whse_code  := journal_oif_data4_tab(ln_count).whse_code;
--
      -- �ŏI���R�[�h�̏ꍇ
      IF ( ln_count = journal_oif_data4_tab.COUNT ) THEN
        -- ���z��0�̏ꍇ�AA-5,A-6�̏��������Ȃ�
        IF ( gn_price_all = 0 ) THEN
          -- �X�L�b�v�����ɑΏی����������Z
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- �d��OIF�o�^(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- ���Y�����ڍ׃f�[�^�X�V(A-6)
          -- ===============================
          upd_gme_material_details_data(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop4;
--
    -- ===============================
    -- (5)���o ������U�֕��i�����E�����i�ցj ���J�[�\�������ύX�ƂȂ������߁A�����ԍ��A�J�[�\���̔ԍ���6�ƂȂ��Ă���
    -- ===============================
    -- ������
    g_gme_material_details_tab.DELETE;               -- ���Y�����ڍ׃f�[�^�X�V���i�[�pPL/SQL�\�̏�����
    gv_whse_code           := NULL;                  -- �q�ɃR�[�h
    ln_out_count           := 0;                     -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
    gn_price_all           := 0;                     -- ���z
    gv_process_no          := cv_process_no_06;      -- �����ԍ��F(5)���o ������U�֕��i�����E�����i�ցj
    gv_item_class_code_hdr := cv_item_class_code_1;  -- �i�ڋ敪�F����
    gv_prod_class_code_hdr := cv_prod_class_code_1;  -- ���i�敪�F���[�t
    gv_ptn_siwake          := cv_ptn_siwake_05;      -- �d��p�^�[���F5�i�����𔼐��i�Ɉړ��U�ցj
--
    -- ===============================
    -- ���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_journal_oif_data6_cur;
    -- �o���N�t�F�b�`
    FETCH get_journal_oif_data6_cur BULK COLLECT INTO journal_oif_data6_tab;
    -- �J�[�\���N���[�Y
    IF ( get_journal_oif_data6_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data6_cur;
    END IF;
--
    <<main_loop6>>
    FOR ln_count in 1..journal_oif_data6_tab.COUNT LOOP
--
      -- �����Ώی�����ݒ�
      gn_target_cnt := gn_target_cnt + 1;
      -- �Ώی������J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
      ln_out_count  := ln_out_count + 1;
      -- �u���Y�����ڍ�ID�v��ێ�
      g_gme_material_details_tab(ln_out_count).material_detail_id := journal_oif_data6_tab(ln_count).material_detail_id;
      -- ���z�����Z
      gn_price_all  := gn_price_all + journal_oif_data6_tab(ln_count).price;
--
    END LOOP main_loop6;
--
    -- ���z��0�̏ꍇ�AA-5,A-6�̏��������Ȃ�
    IF ( gn_price_all = 0 ) THEN
      -- �X�L�b�v�����ɑΏی����������Z
      gn_warn_cnt := gn_warn_cnt + ln_out_count;
    ELSE
      -- ===============================
      -- �d��OIF�o�^(A-5)
      -- ===============================
      ins_journal_oif(
        ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���Y�����ڍ׃f�[�^�X�V(A-6)
      -- ===============================
      upd_gme_material_details_data(
        ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- (6)(7)(8)�I�����Ձi�����A�����i�A���ށj ���J�[�\�������ύX�ƂȂ������߁A�����ԍ��A�J�[�\���̔ԍ���7�ƂȂ��Ă���
    -- ===============================
    -- ������
    lv_data7_flag           := cv_flag_n;         -- �f�[�^�L���t���O
    lv_whse_data_flag       := cv_flag_n;         -- �Ώۑq�Ƀ`�F�b�N�t���O
    ln_out_count            := 0;                 -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
    gn_price_all            := 0;                 -- ���z
    gv_process_no           := cv_process_no_07;  -- �����ԍ��F�i6�j�I�����Ձi�����A�����i�A���ށj
    gv_warehouse_code       := NULL;              -- �q�ɃR�[�h�i����Ȗڎ擾�p�j
    gv_whse_code            := NULL;              -- �q�ɃR�[�h
    gv_item_class_code_hdr  := NULL;              -- �i�ڋ敪
    gv_prod_class_code_hdr  := NULL;              -- ���i�敪
    gv_ptn_siwake           := NULL;              -- �d��p�^�[��
--
    -- ===============================
    -- ���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_journal_oif_data7_cur;
    -- �o���N�t�F�b�`
    FETCH get_journal_oif_data7_cur BULK COLLECT INTO journal_oif_data7_tab;
    -- �J�[�\���N���[�Y
    IF ( get_journal_oif_data7_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data7_cur;
    END IF;
--
    -- �i�ڋ敪�F�����i�̏ꍇ�̑Ώۑq�ɂ��擾����
    -- �I�[�v��
    OPEN get_cost_whse_data_cur;
    -- �o���N�t�F�b�`
    FETCH get_cost_whse_data_cur BULK COLLECT INTO cost_whse_data_tab;
    -- �J�[�\���N���[�Y
    IF ( get_cost_whse_data_cur%ISOPEN ) THEN
      CLOSE get_cost_whse_data_cur;
    END IF;
--
    -- �Ώۑq�ɂ����݂��Ȃ��ꍇ�A�G���[
    IF ( cost_whse_data_tab.COUNT = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                , iv_name         => cv_msg_cfo_10043
                );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF; 
--
    <<main_loop7>>
    FOR ln_count in 1..journal_oif_data7_tab.COUNT LOOP
--
      -- �q�ɃR�[�h�A�i�ڃR�[�h�A���i�R�[�h���O���R�[�h�ƈႤ�ꍇ�A�O���R�[�h�̓o�^���s��(1���R�[�h�ڂ͑ΏۊO)
      IF ( ( NVL(gv_whse_code, journal_oif_data7_tab(ln_count).whse_code)                  <> journal_oif_data7_tab(ln_count).whse_code )
       OR  ( NVL(gv_item_class_code_hdr, journal_oif_data7_tab(ln_count).item_class_code ) <> journal_oif_data7_tab(ln_count).item_class_code )
       OR  ( NVL(gv_prod_class_code_hdr, journal_oif_data7_tab(ln_count).prod_class_code ) <> journal_oif_data7_tab(ln_count).prod_class_code ) ) THEN
        -- ���z��0�ł͂Ȃ��ꍇ�AA-5�̏���������
        IF ( gn_price_all <> 0 ) THEN
          -- ===============================
          -- �d��OIF�o�^(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- �q�ɃR�[�h�E�i�ڋ敪�E���i�敪�P�ʂ̏������ϐ��̏����������{
        -- ===============================
        ln_out_count     := 0;              -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
        gn_price_all     := 0;              -- ���z
      END IF;
--
      -- �f�[�^�L���t���O�����Ă�
      lv_data7_flag := cv_flag_y;
      -- �Ώۑq�ɗL���t���O�𗎂Ƃ�
      lv_whse_data_flag := cv_flag_n;
      -- ���z�����Z
      gn_price_all  := gn_price_all + journal_oif_data7_tab(ln_count).price;
      -- �q�ɃR�[�h��ێ�
      gv_whse_code  := journal_oif_data7_tab(ln_count).whse_code;
      -- �q�ɃR�[�h�i����Ȗڎ擾�p�j��ێ�
      gv_warehouse_code  := journal_oif_data7_tab(ln_count).whse_code;
      -- �i�ڋ敪��ێ�
      gv_item_class_code_hdr  := journal_oif_data7_tab(ln_count).item_class_code;
      -- ���i�敪��ێ�
      gv_prod_class_code_hdr  := journal_oif_data7_tab(ln_count).prod_class_code;
      -- �d��p�^�[�����Z�b�g
      -- ���i�敪�F���[�t�A�i�ڋ敪�F�����̏ꍇ
      IF    ( gv_prod_class_code_hdr = cv_prod_class_code_1 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_1 ) THEN
        -- �d��p�^�[���F7�i���[�t�����[�������j
        gv_ptn_siwake          := cv_ptn_siwake_07;
      -- ���i�敪�F�h�����N�A�i�ڋ敪�F�����̏ꍇ
      ELSIF ( gv_prod_class_code_hdr = cv_prod_class_code_2 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_1 ) THEN
        -- �d��p�^�[���F3�i�h�����N�����[�������j
        gv_ptn_siwake          := cv_ptn_siwake_03;
      -- ���i�敪�F���[�t�A�i�ڋ敪�F�����i�̏ꍇ
      ELSIF ( gv_prod_class_code_hdr = cv_prod_class_code_1 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_4 ) THEN
        -- �d��p�^�[���F1�i�����i�[�������j
        gv_ptn_siwake          := cv_ptn_siwake_01;
      -- ���i�敪�F���[�t�A�i�ڋ敪�F���ނ̏ꍇ
      ELSIF ( gv_prod_class_code_hdr = cv_prod_class_code_1 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_2 ) THEN
        -- �d��p�^�[���F4�i���[�t���ޒ[�������j
        gv_ptn_siwake          := cv_ptn_siwake_04;
      -- ���i�敪�F�h�����N�A�i�ڋ敪�F���ނ̏ꍇ
      ELSIF ( gv_prod_class_code_hdr = cv_prod_class_code_2 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_2 ) THEN
        -- �d��p�^�[���F1�i�h�����N���ޒ[�������j
        gv_ptn_siwake          := cv_ptn_siwake_01;
      END IF;
--
      -- ���i�敪�F�h�����N�A�i�ڋ敪�F�����i�̏ꍇ
      IF    ( gv_prod_class_code_hdr = cv_prod_class_code_2 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_4 ) THEN
        -- ���z��0�ɂ���i�d��ΏۊO�j
        gn_price_all := cn_price_all_0;
      END IF;
--
      -- �i�ڋ敪�F�����i�̏ꍇ�A�Ώۑq�ɂ��`�F�b�N����
      IF ( gv_item_class_code_hdr = cv_item_class_code_4 ) THEN
        <<loop7_1>>
        FOR ln_count_whse_data in 1..cost_whse_data_tab.COUNT LOOP
          -- �Ώۑq�ɂ̏ꍇ
          IF ( gv_whse_code = cost_whse_data_tab(ln_count_whse_data).whse_data) THEN
            -- �Ώۑq�Ƀ`�F�b�N�t���O�𗧂Ă�
            lv_whse_data_flag := cv_flag_y;
          END IF;
        END LOOP loop7_1;
        -- �Ώۑq�ɂł͂Ȃ��ꍇ
        IF ( lv_whse_data_flag = cv_flag_n ) THEN
          -- ���z��0�ɂ���i�d��ΏۊO�j
          gn_price_all := cn_price_all_0;
        END IF;
      END IF;
--
      -- �ŏI���R�[�h�̏ꍇ
      IF ( ln_count = journal_oif_data7_tab.COUNT ) THEN
        -- ���z��0�̏ꍇ�AA-5�̏��������Ȃ�
        IF ( gn_price_all = 0 ) THEN
          -- �X�L�b�v�����ɑΏی����������Z
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- �d��OIF�o�^(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop7;
--
    -- �����Ώۃf�[�^�����݂��Ȃ��ꍇ�A�G���[
    IF ( gn_target_cnt = 0 AND lv_data7_flag = cv_flag_n) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                , iv_name         => cv_msg_cfo_10043
                );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF; 
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( get_journal_oif_data1_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data1_cur;
      END IF;
      IF ( get_journal_oif_data2_1_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data2_1_cur;
      END IF;
      IF ( get_journal_oif_data2_2_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data2_2_cur;
      END IF;
      IF ( get_journal_oif_data3_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data3_cur;
      END IF;
      IF ( get_journal_oif_data4_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data4_cur;
      END IF;
      IF ( get_journal_oif_data6_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data6_cur;
      END IF;
      IF ( get_journal_oif_data7_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data7_cur;
      END IF;
      IF ( get_cost_whse_data_cur%ISOPEN ) THEN
        CLOSE get_cost_whse_data_cur;
      END IF;
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
      -- �J�[�\���N���[�Y
      IF ( get_journal_oif_data1_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data1_cur;
      END IF;
      IF ( get_journal_oif_data2_1_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data2_1_cur;
      END IF;
      IF ( get_journal_oif_data2_2_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data2_2_cur;
      END IF;
      IF ( get_journal_oif_data3_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data3_cur;
      END IF;
      IF ( get_journal_oif_data4_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data4_cur;
      END IF;
      IF ( get_journal_oif_data6_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data6_cur;
      END IF;
      IF ( get_journal_oif_data7_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data7_cur;
      END IF;
      IF ( get_cost_whse_data_cur%ISOPEN ) THEN
        CLOSE get_cost_whse_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_journal_oif_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_mfg_if_control
   * Description      : �A�g�Ǘ��e�[�u���o�^(A-7)
   ***********************************************************************************/
  PROCEDURE ins_mfg_if_control(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mfg_if_control'; -- �v���O������
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
    -- =====================================
    -- �A�g�Ǘ��e�[�u���ɓo�^
    -- =====================================
    BEGIN
      INSERT INTO xxcfo_mfg_if_control(
         program_name                        -- �@�\��
        ,set_of_books_id                     -- ��v����ID
        ,period_name                         -- ��v����
        ,gl_process_flag                     -- GL�]���t���O
        --WHO�J����
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      )VALUES(
         cv_pkg_name                         -- �@�\�� 'XXCFO020A02C'
        ,gn_sales_set_of_bks_id              -- ��v����ID
        ,iv_period_name                      -- ��v����
        ,cv_flag_y                           -- GL�]���t���O
        ,cn_created_by
        ,cd_creation_date
        ,cn_last_updated_by
        ,cd_last_update_date
        ,cn_last_update_login
        ,cn_request_id
        ,cn_program_application_id
        ,cn_program_id
        ,cd_program_update_date
       );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_00024
                  , iv_token_name1  => cv_tkn_table                            -- �e�[�u��
                  , iv_token_value1 => cv_mesg_out_table_04                    -- �A�g�Ǘ��e�[�u��
                  , iv_token_name2  => cv_tkn_errmsg                           -- �G���[���e
                  , iv_token_value2 => SQLERRM
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
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
  END ins_mfg_if_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_error_cnt    := 0;
    gn_warn_cnt     := 0;
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
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ��v���ԃ`�F�b�N(A-2)
    -- ===============================
    check_period_name(
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �d��OIF��񒊏o(A-3)
    -- �d��OIF���ҏW(A-4)
    -- ===============================
    get_journal_oif_data(
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �A�g�Ǘ��e�[�u���o�^(A-8)
    -- ===============================
    ins_mfg_if_control(
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
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
    errbuf              OUT VARCHAR2,      -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,      -- ���^�[���E�R�[�h    --# �Œ� #
    iv_period_name      IN  VARCHAR2       -- 1.��v����
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
       iv_period_name                              -- 1.��v����
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
    END IF;
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
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
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
END XXCFO020A02C;
/
