CREATE OR REPLACE PACKAGE BODY XXCFO020A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A05C(body)
 * Description      : �󕥁i�o�ׁj�d��IF�쐬
 * MD.050           : �󕥁i�o�ׁj�d��IF�쐬<MD050_CFO_020_A05>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  check_period_name      ��v���ԃ`�F�b�N(A-2)
 *  get_journal_oif_data   �d��OIF��񒊏o(A-3),�d��OIF���ҏW(A-4)
 *  ins_journal_oif        �d��OIF�o�^(A-5)
 *  upd_inv_trn_data       ���Y����f�[�^�X�V(A-6)
 *  ins_mfg_if_control     �A�g�Ǘ��e�[�u���o�^(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO020A05C';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_short_name_cmn      CONSTANT VARCHAR2(10)  := 'XXCMN';
  cv_appl_short_name_cfo      CONSTANT VARCHAR2(10)  := 'XXCFO';
--
  -- ���b�Z�[�W�R�[�h
  cv_msg_cfo_00001            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00001';        -- �v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00019            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00019';        -- ���b�N�G���[
  cv_msg_cfo_00024            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00024';        -- �o�^�G���[���b�Z�[�W
  cv_msg_cfo_10042            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10042';        -- �f�[�^�X�V�G���[
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
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_REC_PAY';        -- XXCFO:�d��p�^�[��_�󕥎c���\
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_CATEGORY_ MFG_OMSO'; -- XXCFO:�������\�[�X�i�H��j
--
  cv_gloif_cr                 CONSTANT VARCHAR2(2)   := 'CR';                        -- �ݕ�
  cv_gloif_dr                 CONSTANT VARCHAR2(2)   := 'DR';                        -- �ؕ�
--
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- �t���O:N
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- �t���O:Y
--
  -- ���b�Z�[�W�o�͒l
  cv_mesg_out_data_01         CONSTANT VARCHAR2(20)  := '�󒍖���';
  --
  cv_mesg_out_item_01         CONSTANT VARCHAR2(24)  := '�󒍃w�b�_ID�A�󒍖���ID';
  --
  cv_mesg_out_table_01        CONSTANT VARCHAR2(20)  := '�d��OIF';
  cv_mesg_out_table_02        CONSTANT VARCHAR2(20)  := '�󒍖���';
  cv_mesg_out_table_03        CONSTANT VARCHAR2(20)  := '�A�g�Ǘ��e�[�u��';
--
  -- ���t�����ϊ��֘A
  cv_fdy                      CONSTANT VARCHAR2(02) := '01';                       --�������t
  cv_d_format                 CONSTANT VARCHAR2(30) := 'YYYYMMDD';
  cv_e_time                   CONSTANT VARCHAR2(10) := ' 23:59:59';
  cv_dt_format                CONSTANT VARCHAR2(30) := 'YYYYMMDD HH24:MI:SS';
  cv_process_no_01          CONSTANT VARCHAR2(2)   := '01';                        -- ���_�o��(����)���A���_�o��(���i)���A�U�֏o��_�o��(���i)���A���(�q�֕ԕi)���
  cv_process_no_02          CONSTANT VARCHAR2(2)   := '02';                        -- ���o ������U�֕��i���i�ցj
  cv_process_no_03          CONSTANT VARCHAR2(2)   := '03';                        -- ���o ������U�ցi�h�����N�j
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
  gv_je_category_mfg_omso     VARCHAR2(100) DEFAULT NULL;    -- XXCFO:�d��J�e�S��_�󕥁i�o�ׁj
  gd_process_date             DATE          DEFAULT NULL;    -- �Ɩ����t
--
  gv_period_name              VARCHAR2(7)   DEFAULT NULL;    -- ���̓p�����[�^�D��v����
  gd_target_date_from         DATE          DEFAULT NULL;    -- ���o�Ώۓ��tFROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- ���o�Ώۓ��tTO
--
  gn_price_all                NUMBER        DEFAULT 0;       -- �������P�ʁF���z
  gv_dealings_div_hdr         VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF����敪
  gv_item_class_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�i�ڋ敪
  gv_prod_class_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF���i�敪
--
  gv_mfg_vendor_name          VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�d���於�i���Y�j
  gv_invoice_num              VARCHAR2(100) DEFAULT NULL;    -- �������P�ʁF�������ԍ�
--
  -- ===============================
  -- ���[�U�[��`�v���C�x�[�g�^
  -- ===============================
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
  -- ���Y����f�[�^�X�V���i�[�pPL/SQL�\
  g_oe_order_lines_tab            g_oe_order_lines_ttype;
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
    -- XXCFO: �d��J�e�S��_�󕥁i�o�ׁj
    gv_je_category_mfg_omso  := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_je_category_mfg_omso IS NULL ) THEN
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
    iv_process_no IN  VARCHAR2,
    in_je_key     IN  NUMBER  DEFAULT NULL,  -- �d��L�[
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
    -- �d��p�^�[���m�F�p�E����敪
    cv_dealings_div_hdr_101     CONSTANT VARCHAR2(3)   := '101';         -- ���_�o��
    cv_dealings_div_hdr_102     CONSTANT VARCHAR2(3)   := '102';         -- ���i�o��
    cv_dealings_div_hdr_201     CONSTANT VARCHAR2(3)   := '201';         -- �q��
    cv_dealings_div_hdr_203     CONSTANT VARCHAR2(3)   := '203';         -- �ԕi
    -- �d��p�^�[���m�F�p�E���i�敪
    cv_prod_class_1             CONSTANT VARCHAR2(1)   := '1';           -- ���[�t
    cv_prod_class_2             CONSTANT VARCHAR2(1)   := '2';           -- �h�����N
    -- �d��p�^�[���ݒ�p
    cv_ptn_siwake_01            CONSTANT VARCHAR2(1)   := '1';
    cv_ptn_siwake_02            CONSTANT VARCHAR2(1)   := '2';
    cv_ptn_siwake_03            CONSTANT VARCHAR2(1)   := '3';
    cv_ptn_siwake_04            CONSTANT VARCHAR2(1)   := '4';                              -- �d��p�^�[���F4
    -- �d��OIF�o�^�p
    cv_status_new               CONSTANT VARCHAR2(3)   := 'NEW';         -- �X�e�[�^�X
    cv_actual_flag_a            CONSTANT VARCHAR2(1)   := 'A';           -- �c���^�C�v
    cn_group_id_1               CONSTANT NUMBER        := 1;
--
    -- *** ���[�J���ϐ� ***
    lv_ptn_siwake               VARCHAR2(1)       DEFAULT NULL;     -- �d��p�^�[��
    lv_company_code             VARCHAR2(100)     DEFAULT NULL;     -- ���
    lv_department_code          VARCHAR2(100)     DEFAULT NULL;     -- ����
    lv_account_title            VARCHAR2(100)     DEFAULT NULL;     -- ����Ȗ�
    lv_account_subsidiary       VARCHAR2(100)     DEFAULT NULL;     -- �⏕�Ȗ�
    lv_description_dr           VARCHAR2(100)     DEFAULT NULL;     -- �ؕ��E�v
    lv_description_cr           VARCHAR2(100)     DEFAULT NULL;     -- �ݕ��E�v
    lv_reference1               VARCHAR2(100)     DEFAULT NULL;     -- �Q�ƍ���1�i�o�b�`���j
    lv_reference2               VARCHAR2(100)     DEFAULT NULL;     -- �Q�ƍ���2�i�o�b�`�E�v�j
    lv_reference4               VARCHAR2(100)     DEFAULT NULL;     -- �Q�ƍ���4�i�d�󖼁j
    ln_entered_dr               NUMBER            DEFAULT NULL;     -- �ؕ����z
    ln_entered_cr               NUMBER            DEFAULT NULL;     -- �ݕ����z
    ln_code_combination_id      NUMBER            DEFAULT NULL;     -- CCID
    ln_gl_je_key                NUMBER            DEFAULT NULL;     -- �d��L�[
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
    -- �d��p�^�[�����擾
    -- ===============================
    IF iv_process_no = cv_process_no_01 THEN
      -- ����敪���f101�f�i���_�o�ׁj�̏ꍇ
      IF ( gv_dealings_div_hdr = cv_dealings_div_hdr_101 ) THEN
        -- �u3�v��ݒ�
        lv_ptn_siwake := cv_ptn_siwake_03;
      -- ����敪���f102�f�i���i�o�ׁj�����i�敪���f1�f�i���[�t�j�̏ꍇ
      ELSIF ( gv_dealings_div_hdr = cv_dealings_div_hdr_102 )
        AND ( gv_prod_class_code_hdr = cv_prod_class_1 ) THEN
        -- �u3�v��ݒ�
        lv_ptn_siwake := cv_ptn_siwake_03;
      -- ����敪���f102�f�i���i�o�ׁj�����i�敪���f2�f�i�h�����N�j�̏ꍇ
      ELSIF ( gv_dealings_div_hdr = cv_dealings_div_hdr_102 )
        AND ( gv_prod_class_code_hdr = cv_prod_class_2 ) THEN
        -- �u2�v��ݒ�
        lv_ptn_siwake := cv_ptn_siwake_02;
      -- ����敪���f201�f�i�q�ցj�����i�敪���f1�f�i���[�t�j�̏ꍇ
      ELSIF ( gv_dealings_div_hdr = cv_dealings_div_hdr_201 )
        AND ( gv_prod_class_code_hdr = cv_prod_class_1 ) THEN
        -- �u1�v��ݒ�
        lv_ptn_siwake := cv_ptn_siwake_01;
      -- ����敪���f201�f�i�q�ցj�����i�敪���f2�f�i�h�����N�j�̏ꍇ
      ELSIF ( gv_dealings_div_hdr = cv_dealings_div_hdr_201 )
        AND ( gv_prod_class_code_hdr = cv_prod_class_2 ) THEN
        -- �u1�v��ݒ�
        lv_ptn_siwake := cv_ptn_siwake_01;
      -- ����敪���f203�f�i�ԕi�j�̏ꍇ
      ELSIF ( gv_dealings_div_hdr = cv_dealings_div_hdr_203 ) THEN
        -- �u2�v��ݒ�
        lv_ptn_siwake := cv_ptn_siwake_02;
      -- 
      END IF;
    ELSIF iv_process_no = cv_process_no_02 THEN
      lv_ptn_siwake := cv_ptn_siwake_04;
      --
    ELSIF iv_process_no = cv_process_no_03 THEN
      lv_ptn_siwake := cv_ptn_siwake_02;
--
    END IF;
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
      , iv_ptn_siwake               =>  lv_ptn_siwake               -- (IN)�d��p�^�[��
      , iv_line_no                  =>  NULL                        -- (IN)�s�ԍ�
      , iv_gloif_dr_cr              =>  cv_gloif_dr                 -- (IN)�ؕ��FDR
      , iv_warehouse_code           =>  NULL                        -- (IN)�q�ɃR�[�h
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
                  id_proc_date => TRUNC(gd_target_date_to)          -- ������
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
                      , iv_token_value1 => TRUNC(gd_target_date_to)    -- ������
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
    -- �d��L�[�̎擾
    IF in_je_key IS NULL THEN
      ln_gl_je_key  := xxcfo_gl_je_key_s1.NEXTVAL;
    ELSE
      ln_gl_je_key  := in_je_key;
    END IF;
    -- �Q�ƍ���1�i�o�b�`���j�̎擾
    lv_reference1 := gv_je_category_mfg_omso || cv_under_score || gv_period_name;
    -- �Q�ƍ���2�i�o�b�`�E�v�j�̎擾
    lv_reference2 := gv_je_category_mfg_omso || cv_under_score || gv_period_name;
    -- �Q�ƍ���4�i�d�󖼁j�̎擾
    lv_reference4 := ln_gl_je_key;
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
       ,gv_je_category_mfg_omso      -- �d��J�e�S����
       ,gv_je_invoice_source_mfg     -- �d��\�[�X��
       ,ln_code_combination_id       -- CCID
       ,cn_request_id                -- �v��ID
       ,ln_entered_dr                -- �ؕ����z
       ,ln_entered_cr                -- �ݕ����z
       ,lv_reference1                -- �Q�ƍ���1 �o�b�`���Q�ƍ���1�o�b�`��
       ,lv_reference2                -- �Q�ƍ���2 �o�b�`�E�v�Q�ƍ���2
       ,lv_reference4                -- �Q�ƍ���4 �d�󖼎Q�ƍ���4
       ,lv_description_dr            -- �Q�ƍ���5 �d�󖼓E�v
       ,lv_description_dr            -- �Q�ƍ���10 �d�󖾍דE�v
       ,gv_period_name               -- ��v���Ԗ�
       ,NULL                         -- DFF1 �ŋ敪
       ,NULL                         -- DFF3 �`�[�ԍ�
       ,lv_department_code           -- DFF4 �N�[����
       ,NULL                         -- DFF5 �`�[���͎�
       ,ln_gl_je_key                 -- DFF8 �̔����уw�b�_ID
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
      , iv_ptn_siwake               =>  lv_ptn_siwake               -- (IN)�d��p�^�[��
      , iv_line_no                  =>  NULL                        -- (IN)�s�ԍ�
      , iv_gloif_dr_cr              =>  cv_gloif_cr                 -- (IN)�ݕ��FCR
      , iv_warehouse_code           =>  NULL                        -- (IN)�q�ɃR�[�h
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
                  id_proc_date => TRUNC(gd_target_date_to)          -- ������
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
                      , iv_token_value1 => TRUNC(gd_target_date_to)    -- ������
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
       ,gv_je_category_mfg_omso      -- �d��J�e�S����
       ,gv_je_invoice_source_mfg     -- �d��\�[�X��
       ,ln_code_combination_id       -- CCID
       ,cn_request_id                -- �v��ID
       ,ln_entered_dr                -- �ؕ����z
       ,ln_entered_cr                -- �ݕ����z
       ,lv_reference1                -- �Q�ƍ���1 �o�b�`��
       ,lv_reference2                -- �Q�ƍ���2 �o�b�`�E�v
       ,lv_reference4                -- �Q�ƍ���4 �d��
       ,lv_description_dr            -- �Q�ƍ���5 �d�󖼓E�v
       ,lv_description_cr            -- �Q�ƍ���10 �d�󖾍דE�v
       ,gv_period_name               -- ��v���Ԗ�
       ,NULL                         -- DFF1 �ŋ敪
       ,NULL                         -- DFF3 �`�[�ԍ�
       ,lv_department_code           -- DFF4 �N�[����
       ,NULL                         -- DFF5 �`�[���͎�
       ,ln_gl_je_key                 -- DFF8 �̔����уw�b�_ID
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
   * Procedure Name   : upd_inv_trn_data
   * Description      : ���Y����f�[�^�X�V(A-6)
   ***********************************************************************************/
  PROCEDURE upd_inv_trn_data(
    in_je_key     IN  NUMBER  DEFAULT NULL,  -- �d��L�[
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_inv_trn_data'; -- �v���O������
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
    lt_header_id      oe_order_lines_all.header_id%TYPE;
    lt_liner_id       oe_order_lines_all.line_id%TYPE;
    ln_upd_je_key     NUMBER;
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
    -- �󒍖��׃e�[�u���ɑ΂��čs���b�N���擾
    -- =========================================================
    << lock_loop >>
    FOR ln_upd_cnt IN 1..g_oe_order_lines_tab.COUNT LOOP
      BEGIN
        SELECT oola.header_id
              ,oola.line_id
        INTO   lt_header_id
              ,lt_liner_id
        FROM   oe_order_lines_all oola
        WHERE  oola.header_id = g_oe_order_lines_tab(ln_upd_cnt).header_id
        AND    oola.line_id   = g_oe_order_lines_tab(ln_upd_cnt).line_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_tkn_table                        -- �e�[�u��
                    , iv_token_value1 => cv_mesg_out_table_02                -- �󒍖���
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP lock_loop;
--
    BEGIN
      -- �d��L�[�ݒ�ς݂̏ꍇ�͌��̒l�ōX�V
      IF in_je_key IS NOT NULL THEN
        ln_upd_je_key := in_je_key;
      ELSE
        ln_upd_je_key := xxcfo_gl_je_key_s1.CURRVAL;
      END IF;
--
      FORALL ln_upd_cnt IN 1..g_oe_order_lines_tab.COUNT
        -- ����f�[�^�����ʂ����ӂȒl���󒍖��ׂɍX�V
        UPDATE oe_order_lines_all oola
        SET    oola.attribute4        = ln_upd_je_key               -- �d��L�[
              ,last_update_date       = SYSDATE
              ,last_updated_by        = cn_last_updated_by
              ,last_update_login      = cn_last_update_login
              ,program_application_id = cn_program_application_id
              ,program_id             = cn_program_id
              ,program_update_date    = SYSDATE
              ,request_id             = cn_request_id
        WHERE  oola.header_id = g_oe_order_lines_tab(ln_upd_cnt).header_id
        AND    oola.line_id   = g_oe_order_lines_tab(ln_upd_cnt).line_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_10042
                  , iv_token_name1  => cv_tkn_data                         -- �f�[�^
                  , iv_token_value1 => cv_mesg_out_data_01                 -- �󒍖���
                  , iv_token_name2  => cv_tkn_item                         -- �A�C�e��
                  , iv_token_value2 => cv_mesg_out_item_01                 -- �󒍃w�b�_ID�A�󒍖���ID
                  , iv_token_name3  => cv_tkn_key                          -- �L�[
                  , iv_token_value3 => '�u' || g_oe_order_lines_tab(ln_upd_cnt).header_id || '�v�A�u'
                                            || g_oe_order_lines_tab(ln_upd_cnt).line_id   || '�v'
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ���팏���J�E���g
    gn_normal_cnt := gn_normal_cnt + g_oe_order_lines_tab.COUNT;
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
  END upd_inv_trn_data;
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
    cv_req_status_4           CONSTANT VARCHAR2(2)   := '04';                             -- �o�׈˗��X�e�[�^�X�F�o�׎��ьv���
    cv_document_type_code_10  CONSTANT VARCHAR2(2)   := '10';                             -- �����^�C�v�F�o�׈˗�
    cv_record_type_code_20    CONSTANT VARCHAR2(2)   := '20';                             -- ���R�[�h�^�C�v�F�o�Ɏ���
    cv_ship_prov_1            CONSTANT VARCHAR2(1)   := '1';                              -- �o�׎x���敪�F�o��
    cv_ship_prov_3            CONSTANT VARCHAR2(1)   := '3';                              -- �o�׎x���敪�F�q�֕ԕi
    cv_inv_adjust_1           CONSTANT VARCHAR2(1)   := '1';                              -- �݌ɒ����敪�F1�i���݌ɒ����j
    cv_doc_type_omso          CONSTANT VARCHAR2(4)   := 'OMSO';                           -- �����^�C�v�FOMSO
    cv_doc_type_porc          CONSTANT VARCHAR2(4)   := 'PORC';                           -- �����^�C�v�FPORC
    cv_cat_crowd_code         CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_CATEGORY_CROWD_CODE'; -- �J�e�S���Z�b�gID1
    cv_cat_item_class         CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_CATEGORY_ITEM_CLASS'; -- �J�e�S���Z�b�gID2
    cv_segment1_2             CONSTANT VARCHAR2(1)   := '2';                              -- �Z�O�����g1�F����
    cv_segment1_5             CONSTANT VARCHAR2(1)   := '5';                              -- �Z�O�����g5�F���i
    cv_dealings_div_101       CONSTANT VARCHAR2(3)   := '101';                            -- ����敪�F���ޏo��
    cv_dealings_div_102       CONSTANT VARCHAR2(3)   := '102';                            -- ����敪�F���i�o��
    cv_dealings_div_112       CONSTANT VARCHAR2(3)   := '112';                            -- ����敪�F�U�֏o��_�o��
    cv_dealings_div_201       CONSTANT VARCHAR2(3)   := '201';                            -- ����敪�F�q��
    cv_dealings_div_203       CONSTANT VARCHAR2(3)   := '203';                            -- ����敪�F�ԕi
    cv_prod_class_code_1      CONSTANT VARCHAR2(1)   := '1';                              -- ���i�敪�F���[�t
    cv_prod_class_code_2      CONSTANT VARCHAR2(1)   := '2';                              -- ���i�敪�F�h�����N
    cv_source_doc_code_rma    CONSTANT VARCHAR2(3)   := 'RMA';                            -- �\�[�X�����FRMA
    cv_dealings_div_106       CONSTANT VARCHAR2(3)   := '106';                            -- ����敪�F�U�֗L��_���o
    cv_dealings_div_113       CONSTANT VARCHAR2(3)   := '113';                            -- ����敪�F�U�֏o��_���o
    cv_item_class_code_1      CONSTANT VARCHAR2(1)   := '1';                              -- �i�ڋ敪�F����
    cv_inv_adjust_2           CONSTANT VARCHAR2(1)   := '2';                              -- �݌ɒ����敪�F2�i���݌ɒ����ȊO�j
    cv_latest_external_flag_y CONSTANT VARCHAR2(1)   := 'Y';                              -- �ŐV�t���O�FY
    cv_req_status_8           CONSTANT VARCHAR2(2)   := '08';                             -- �o�׈˗��X�e�[�^�X�F�o�׎��ьv���
    cn_completed_ind_1        CONSTANT NUMBER        := 1;                                -- �����t���O�F�P
--
    -- *** ���[�J���ϐ� ***
    ln_count                 NUMBER       DEFAULT 0;                                     -- ���o�����̃J�E���g
    ln_out_count             NUMBER       DEFAULT 0;                                     -- ����u���[�N�L�[�����̃J�E���g
    ln_je_key                NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���o�J�[�\���iSELECT���@�`�E��UNION ALL�j
    CURSOR get_journal_oif_data_cur
    IS
      -- ���o�@�i���_�o��(����)���j
      SELECT  /*+ LEADING(xoha ooha otta xola wdd itp xrpm gic2 mcb2 iimb gic mcb xmld oola ilm xlc)
                  USE_NL (     ooha otta xola wdd itp xrpm gic2 mcb2 iimb gic mcb xmld oola ilm xlc)
                  INDEX  (xoha XXWSH_OH_N32)    */
              ROUND((CASE iimb.attribute15
                        WHEN '1' THEN (SELECT NVL(xsup.stnd_unit_price, 0) 
                                       FROM   xxcmn_stnd_unit_price_v     xsup     -- �W���������u������
                                       WHERE  xsup.item_id = iimb.item_id
                                       AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                                AND     NVL(xsup.end_date_active, xoha.arrival_date))
                        ELSE DECODE(iimb.lot_ctl
                                   ,1,NVL(xlc.unit_ploce, 0)
                                   ,(SELECT NVL(xsup.stnd_unit_price, 0) 
                                     FROM   xxcmn_stnd_unit_price_v     xsup     -- �W���������u������
                                     WHERE  xsup.item_id = iimb.item_id
                                     AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                               AND     NVL(xsup.end_date_active, xoha.arrival_date)))
                     END) * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))
              )                                          AS price           -- ���z
             ,xrpm.dealings_div                          AS dealings_div    -- ����敪
             ,xicv.item_class_code                       AS item_class_code -- �i�ڋ敪
             ,xicv.prod_class_code                       AS prod_class_code -- ���i�敪
             ,oola.header_id                             AS header_id       -- �󒍃w�b�_ID
             ,oola.line_id                               AS line_id         -- �󒍖���ID
             ,oola.attribute4                            AS  je_key         -- �d��L�[
      FROM    oe_order_headers_all        ooha                     -- �󒍃w�b�_(�W��)
             ,oe_order_lines_all          oola                     -- �󒍖���(�W��)
             ,xxwsh_order_headers_all     xoha                     -- �󒍃w�b�_�A�h�I��
             ,xxwsh_order_lines_all       xola                     -- �󒍖��׃A�h�I��
             ,oe_transaction_types_all    otta                     -- �󒍃^�C�v
             ,xxinv_mov_lot_details       xmld                     -- �ړ����b�g�ڍ׃A�h�I��
             ,wsh_delivery_details        wdd                      -- �o�ה�������
             ,ic_tran_pnd                 itp                      -- OPM�ۗ��݌Ƀg�����U�N�V�����\
             ,ic_item_mst_b               iimb                     -- OPM�i�ڃ}�X�^
             ,xxcmn_item_categories5_v    xicv                     -- OPM�i�ڃJ�e�S���������View5
             ,ic_lots_mst                 ilm                      -- OPM���b�g�}�X�^
             ,xxcmn_lot_cost              xlc                      -- ���b�g�ʌ����A�h�I��
             ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
             ,gmi_item_categories         gic                      -- OPM�i�ڃJ�e�S������
             ,mtl_categories_b            mcb                      -- �i�ڃJ�e�S���}�X�^
             ,gmi_item_categories         gic2                     -- OPM�i�ڃJ�e�S������2
             ,mtl_categories_b            mcb2                     -- �i�ڃJ�e�S���}�X�^2
      WHERE  xoha.latest_external_flag         = cv_flag_y                                       -- �ŐV�t���O�FY
      AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                               AND     gd_target_date_to                         -- ���ד��F�݌ɉ�v���ԓ�
      AND    xoha.req_status                   = cv_req_status_4                                 -- �o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.org_id                       = gn_org_id_mfg                                   -- ���YORG ID
      AND    xola.order_header_id              = xoha.order_header_id
      AND    NVL(xola.delete_flag ,'N')        = cv_flag_n                                       -- ���׍폜�t���O�FN
      AND    xmld.mov_line_id                  = xola.order_line_id
      AND    xmld.document_type_code           = cv_document_type_code_10                        -- �����^�C�v�F�o�׈˗�
      AND    xmld.record_type_code             = cv_record_type_code_20                          -- ���R�[�h�^�C�v�F�o�Ɏ���
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    oola.header_id                    = xola.header_id
      AND    oola.line_id                      = xola.line_id
      AND    otta.transaction_type_id          = ooha.order_type_id
      AND    otta.attribute1                   = cv_ship_prov_1                                  -- �o�׎x���敪�F�o��
      AND    otta.attribute4                   = cv_inv_adjust_1                                 -- �݌ɒ����敪�F1�i���݌ɒ����j
      AND    wdd.source_header_id              = xola.header_id
      AND    wdd.source_line_id                = xola.line_id
      AND    itp.line_detail_id                = wdd.delivery_detail_id
      AND    itp.doc_type                      = cv_doc_type_omso                                -- �����^�C�v�FOMSO
      AND    itp.completed_ind                 = cn_completed_ind_1                              -- �����t���O�F1
      AND    gic.item_id                       = itp.item_id
      AND    gic.category_set_id               = TO_NUMBER(fnd_profile.value(cv_cat_crowd_code)) -- �J�e�S���Z�b�gID1�FXXCMN_ITEM_CATEGORY_CROWD_CODE
      AND    gic.category_id                   = mcb.category_id
      AND    gic2.item_id                      = itp.item_id
      AND    gic2.category_set_id              = TO_NUMBER(fnd_profile.value(cv_cat_item_class)) -- �J�e�S���Z�b�gID2�FXXCMN_ITEM_CATEGORY_ITEM_CLASS
      AND    gic2.category_id                  = mcb2.category_id
      AND    mcb2.segment1                     = cv_segment1_2                                   -- �Z�O�����g1�F����
      AND    xrpm.ship_prov_rcv_pay_category   IS NULL
      AND    xrpm.shipment_provision_div       = otta.attribute1
      AND    xrpm.doc_type                     = itp.doc_type
      AND    xrpm.dealings_div                 = cv_dealings_div_101                             -- ����敪�F���ޏo��
      AND    xrpm.break_col_01                 IS NOT NULL
      AND    xrpm.item_div_origin              IS NULL
      AND    xrpm.item_div_ahead               IS NULL
      AND    xmld.item_id                      = ilm.item_id
      AND    xmld.lot_id                       = ilm.lot_id
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xola.shipping_item_code           = xola.request_item_code
      AND    iimb.item_id                      = itp.item_id
      AND    xicv.item_id                      = iimb.item_id
      AND    xicv.prod_class_code              = cv_prod_class_code_1                            -- ���i�敪�F���[�t
      UNION ALL
      -- ���o�A���_�o��(���i)���
      SELECT  /*+ LEADING(xoha ooha otta xola wdd itp xrpm gic2 mcb2 gic mcb xmld oola ilm iimb xlc) 
                  USE_NL      (ooha otta xola wdd itp xrpm gic2 mcb2 gic mcb xmld oola ilm iimb xlc) 
                  INDEX  (xoha XXWSH_OH_N32)    */
              ROUND((CASE iimb.attribute15
                        WHEN '1' THEN (SELECT NVL(xsup.stnd_unit_price, 0) 
                                       FROM   xxcmn_stnd_unit_price_v     xsup     -- �W���������u������
                                       WHERE  xsup.item_id = itp.item_id
                                       AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                                AND     NVL(xsup.end_date_active, xoha.arrival_date))
                        ELSE DECODE(iimb.lot_ctl
                                   ,1,NVL(xlc.unit_ploce, 0)
                                   ,(SELECT NVL(xsup.stnd_unit_price, 0) 
                                     FROM   xxcmn_stnd_unit_price_v     xsup     -- �W���������u������
                                     WHERE  xsup.item_id = itp.item_id
                                     AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                               AND     NVL(xsup.end_date_active, xoha.arrival_date)) )
                     END) * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))
              )                                          AS price           -- ���z
             ,xrpm.dealings_div                          AS dealings_div    -- ����敪
             ,xicv.item_class_code                       AS item_class_code -- �i�ڋ敪
             ,xicv.prod_class_code                       AS prod_class_code -- ���i�敪
             ,oola.header_id                             AS header_id       -- �󒍃w�b�_ID
             ,oola.line_id                               AS line_id         -- �󒍖���ID
             ,oola.attribute4                            AS  je_key         -- �d��L�[
      FROM    oe_order_headers_all        ooha                     -- �󒍃w�b�_(�W��)
             ,oe_order_lines_all          oola                     -- �󒍖���(�W��)
             ,xxwsh_order_headers_all     xoha                     -- �󒍃w�b�_�A�h�I��
             ,xxwsh_order_lines_all       xola                     -- �󒍖��׃A�h�I��
             ,oe_transaction_types_all    otta                     -- �󒍃^�C�v
             ,xxinv_mov_lot_details       xmld                     -- �ړ����b�g�ڍ׃A�h�I��
             ,wsh_delivery_details        wdd                      -- �o�ה�������
             ,ic_tran_pnd                 itp                      -- OPM�ۗ��݌Ƀg�����U�N�V�����\
             ,ic_item_mst_b               iimb                     -- OPM�i�ڃ}�X�^
             ,xxcmn_item_categories5_v    xicv                     -- OPM�i�ڃJ�e�S���������View5
             ,ic_lots_mst                 ilm                      -- OPM���b�g�}�X�^
             ,xxcmn_lot_cost              xlc                      -- ���b�g�ʌ����A�h�I��
             ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
             ,gmi_item_categories         gic                      -- OPM�i�ڃJ�e�S������
             ,mtl_categories_b            mcb                      -- �i�ڃJ�e�S���}�X�^
             ,gmi_item_categories         gic2                     -- OPM�i�ڃJ�e�S������2
             ,mtl_categories_b            mcb2                     -- �i�ڃJ�e�S���}�X�^2
      WHERE  xoha.latest_external_flag         = cv_flag_y                                       -- �ŐV�t���O�FY
      AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                               AND     gd_target_date_to                         -- ���ד��F�݌ɉ�v���ԓ�
      AND    xoha.req_status                   = cv_req_status_4                                 -- �o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.org_id                       = gn_org_id_mfg                                   -- ���YORG ID
      AND    xola.order_header_id              = xoha.order_header_id
      AND    NVL(xola.delete_flag ,'N')        = cv_flag_n                                       -- ���׍폜�t���O�FN
      AND    xmld.mov_line_id                  = xola.order_line_id
      AND    xmld.document_type_code           = cv_document_type_code_10                        -- �����^�C�v�F�o�׈˗�
      AND    xmld.record_type_code             = cv_record_type_code_20                          -- ���R�[�h�^�C�v�F�o�Ɏ���
      AND    oola.header_id                    = xola.header_id
      AND    oola.line_id                      = xola.line_id
      AND    otta.transaction_type_id          = ooha.order_type_id
      AND    otta.attribute1                   = cv_ship_prov_1                                  -- �o�׎x���敪�F�o��
      AND    otta.attribute4                   = cv_inv_adjust_1                                 -- �݌ɒ����敪�F1�i���݌ɒ����j
      AND    wdd.source_header_id              = xola.header_id
      AND    wdd.source_line_id                = xola.line_id
      AND    itp.line_detail_id                = wdd.delivery_detail_id
      AND    itp.doc_type                      = cv_doc_type_omso                                -- �����^�C�v�FOMSO
      AND    itp.completed_ind                 = cn_completed_ind_1                              -- �����t���O�F1
      AND    gic.item_id                       = itp.item_id
      AND    gic.category_set_id               = TO_NUMBER(fnd_profile.value(cv_cat_crowd_code)) -- �J�e�S���Z�b�gID1�FXXCMN_ITEM_CATEGORY_CROWD_CODE
      AND    gic.category_id                   = mcb.category_id
      AND    gic2.item_id                      = itp.item_id
      AND    gic2.category_set_id              = TO_NUMBER(fnd_profile.value(cv_cat_item_class)) -- �J�e�S���Z�b�gID2�FXXCMN_ITEM_CATEGORY_ITEM_CLASS
      AND    gic2.category_id                  = mcb2.category_id
      AND    mcb2.segment1                     = cv_segment1_5                                   -- �Z�O�����g1�F���i
      AND    xrpm.item_div_origin              = mcb2.segment1
      AND    xrpm.ship_prov_rcv_pay_category   IS NULL
      AND    xrpm.shipment_provision_div       = otta.attribute1
      AND    xrpm.doc_type                     = itp.doc_type
      AND    xrpm.dealings_div                 = cv_dealings_div_102                             -- ����敪�F���i�o��
      AND    xrpm.break_col_02                 IS NOT NULL
      AND    xmld.item_id                      = ilm.item_id
      AND    xmld.lot_id                       = ilm.lot_id
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    iimb.item_id                      = ilm.item_id
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xola.shipping_item_code           = xola.request_item_code
      AND    xicv.item_id                      = ilm.item_id
      AND    xicv.prod_class_code              in (cv_prod_class_code_1, cv_prod_class_code_2)  --���[�t�E�h�����N
      UNION ALL
      -- ���o�B�U�֏o��_�o��(���i)���
      SELECT  /*+ LEADING(xoha ooha otta xola wdd itp xrpm iimb gic2 mcb2 gic mcb gic3 mcb3 xmld oola ilm xlc) 
                  USE_NL      (ooha otta xola wdd itp xrpm iimb gic2 mcb2 gic mcb gic3 mcb3 xmld oola ilm xlc) 
                  INDEX  (xoha XXWSH_OH_N32)    */
              ROUND((CASE iimb.attribute15
                        WHEN '1' THEN (SELECT NVL(xsup.stnd_unit_price, 0) 
                                       FROM   xxcmn_stnd_unit_price_v     xsup     -- �W���������u������
                                       WHERE  xsup.item_id = iimb.item_id
                                       AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                                AND     NVL(xsup.end_date_active, xoha.arrival_date))
                        ELSE DECODE(iimb.lot_ctl
                                   ,1,NVL(xlc.unit_ploce, 0)
                                   ,(SELECT NVL(xsup.stnd_unit_price, 0) 
                                     FROM   xxcmn_stnd_unit_price_v     xsup     -- �W���������u������
                                     WHERE  xsup.item_id = iimb.item_id
                                     AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                               AND     NVL(xsup.end_date_active, xoha.arrival_date)) )
                     END) * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))
              )                                          AS price           -- ���z
             ,cv_dealings_div_102                        AS dealings_div    -- ����敪�F���i�o�ׁi�Œ�)
             ,xicv.item_class_code                       AS item_class_code -- �i�ڋ敪
             ,xicv.prod_class_code                       AS prod_class_code -- ���i�敪
             ,oola.header_id                             AS header_id       -- �󒍃w�b�_ID
             ,oola.line_id                               AS line_id         -- �󒍖���ID
             ,oola.attribute4                            AS  je_key         -- �d��L�[
      FROM    oe_order_headers_all        ooha                     -- �󒍃w�b�_(�W��)
             ,oe_order_lines_all          oola                     -- �󒍖���(�W��)
             ,xxwsh_order_headers_all     xoha                     -- �󒍃w�b�_�A�h�I��
             ,xxwsh_order_lines_all       xola                     -- �󒍖��׃A�h�I��
             ,oe_transaction_types_all    otta                     -- �󒍃^�C�v
             ,xxinv_mov_lot_details       xmld                     -- �ړ����b�g�ڍ׃A�h�I��
             ,wsh_delivery_details        wdd                      -- �o�ה�������
             ,ic_tran_pnd                 itp                      -- OPM�ۗ��݌Ƀg�����U�N�V�����\
             ,ic_item_mst_b               iimb                     -- OPM�i�ڃ}�X�^
             ,xxcmn_item_categories5_v    xicv                     -- OPM�i�ڃJ�e�S���������View5
             ,ic_lots_mst                 ilm                      -- OPM���b�g�}�X�^
             ,xxcmn_lot_cost              xlc                      -- ���b�g�ʌ����A�h�I��
             ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
             ,gmi_item_categories         gic                      -- OPM�i�ڃJ�e�S������
             ,mtl_categories_b            mcb                      -- �i�ڃJ�e�S���}�X�^
             ,gmi_item_categories         gic2                     -- OPM�i�ڃJ�e�S������2
             ,mtl_categories_b            mcb2                     -- �i�ڃJ�e�S���}�X�^2
             ,gmi_item_categories         gic3                     -- OPM�i�ڃJ�e�S������3
             ,mtl_categories_b            mcb3                     -- �i�ڃJ�e�S���}�X�^3
      WHERE  xoha.latest_external_flag         = cv_flag_y                                       -- �ŐV�t���O�FY
      AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                               AND     gd_target_date_to                         -- ���ד��F�݌ɉ�v���ԓ�
      AND    xoha.req_status                   = cv_req_status_4                                 -- �o�׈˗��X�e�[�^�X�F�o�׎��ьv���
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.org_id                       = gn_org_id_mfg                                   -- ���YORG ID
      AND    xola.order_header_id              = xoha.order_header_id
      AND    NVL(xola.delete_flag ,'N')        = cv_flag_n                                       -- ���׍폜�t���O�FN
      AND    xmld.mov_line_id                  = xola.order_line_id
      AND    xmld.document_type_code           = cv_document_type_code_10                        -- �����^�C�v�F�o�׈˗�
      AND    xmld.record_type_code             = cv_record_type_code_20                          -- ���R�[�h�^�C�v�F�o�Ɏ���
      AND    oola.header_id                    = xola.header_id
      AND    oola.line_id                      = xola.line_id
      AND    otta.transaction_type_id          = ooha.order_type_id
      AND    otta.attribute1                   = cv_ship_prov_1                                  -- �o�׎x���敪�F�o��
      AND    otta.attribute4                   = cv_inv_adjust_1                                 -- �݌ɒ����敪�F1�i���݌ɒ����j
      AND    wdd.source_header_id              = xola.header_id
      AND    wdd.source_line_id                = xola.line_id
      AND    itp.line_detail_id                = wdd.delivery_detail_id
      AND    itp.doc_type                      = cv_doc_type_omso                                -- �����^�C�v�FOMSO
      AND    itp.completed_ind                 = cn_completed_ind_1                              -- �����t���O�F1
      AND    gic.item_id                       = iimb.item_id
      AND    gic.category_set_id               = TO_NUMBER(fnd_profile.value(cv_cat_crowd_code)) -- �J�e�S���Z�b�gID1�FXXCMN_ITEM_CATEGORY_CROWD_CODE
      AND    gic.category_id                   = mcb.category_id
      AND    gic2.item_id                      = iimb.item_id
      AND    gic2.category_set_id              = TO_NUMBER(fnd_profile.value(cv_cat_item_class)) -- �J�e�S���Z�b�gID2�FXXCMN_ITEM_CATEGORY_ITEM_CLASS
      AND    gic2.category_id                  = mcb2.category_id
      AND    mcb2.segment1                     = cv_segment1_5                                   -- �Z�O�����g1�F���i
      AND    xrpm.item_div_ahead               = mcb2.segment1
      AND    gic3.item_id                      = itp.item_id
      AND    gic3.category_set_id              = TO_NUMBER(fnd_profile.value(cv_cat_item_class)) -- �J�e�S���Z�b�gID2�FXXCMN_ITEM_CATEGORY_ITEM_CLASS
      AND    gic3.category_id                  = mcb3.category_id
      AND    xrpm.shipment_provision_div       = otta.attribute1
      AND    xrpm.doc_type                     = itp.doc_type
      AND    xrpm.dealings_div                 = cv_dealings_div_112                             -- ����敪�F�U�֏o��_�o��
      AND    xrpm.break_col_02                 IS NOT NULL
      AND    xmld.item_id                      = ilm.item_id
      AND    xmld.lot_id                       = ilm.lot_id
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    iimb.item_no                      = xola.request_item_code
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xola.shipping_item_code           <> xola.request_item_code
      AND    xicv.item_id                      = iimb.item_id
      AND    xicv.prod_class_code              in (cv_prod_class_code_1, cv_prod_class_code_2)  --���[�t�E�h�����N
      UNION ALL
      -- ���o�C���(�q�֕ԕi)���
      SELECT  /*+ LEADING(xoha ooha otta xola rsl itp xrpm iimb gic2 mcb2 gic mcb gic3 mcb3 xmld oola ilm xlc) 
                  USE_NL      (ooha otta xola rsl itp xrpm iimb gic2 mcb2 gic mcb gic3 mcb3 xmld oola ilm xlc) 
                  INDEX  (xoha XXWSH_OH_N32)    */
              ROUND((CASE iimb.attribute15
                        WHEN '1' THEN (SELECT NVL(xsup.stnd_unit_price, 0) 
                                       FROM   xxcmn_stnd_unit_price_v     xsup     -- �W���������u������
                                       WHERE  xsup.item_id = itp.item_id
                                       AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                                AND     NVL(xsup.end_date_active, xoha.arrival_date))
                        ELSE DECODE(iimb.lot_ctl
                                   ,1,NVL(xlc.unit_ploce, 0)
                                   ,(SELECT NVL(xsup.stnd_unit_price, 0) 
                                     FROM   xxcmn_stnd_unit_price_v     xsup     -- �W���������u������
                                     WHERE  xsup.item_id = itp.item_id
                                     AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                               AND     NVL(xsup.end_date_active, xoha.arrival_date)) )
                     END) * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))
              )                                          AS price           -- ���z
             ,xrpm.dealings_div                          AS dealings_div    -- ����敪
             ,xicv.item_class_code                       AS item_class_code -- �i�ڋ敪
             ,xicv.prod_class_code                       AS prod_class_code -- ���i�敪
             ,oola.header_id                             AS header_id       -- �󒍃w�b�_ID
             ,oola.line_id                               AS line_id         -- �󒍖���ID
             ,oola.attribute4                            AS  je_key         -- �d��L�[
      FROM    oe_order_headers_all        ooha                     -- �󒍃w�b�_(�W��)
             ,oe_order_lines_all          oola                     -- �󒍖���(�W��)
             ,xxwsh_order_headers_all     xoha                     -- �󒍃w�b�_�A�h�I��
             ,xxwsh_order_lines_all       xola                     -- �󒍖��׃A�h�I��
             ,oe_transaction_types_all    otta                     -- �󒍃^�C�v
             ,xxinv_mov_lot_details       xmld                     -- �ړ����b�g�ڍ׃A�h�I��
             ,rcv_shipment_lines          rsl                      -- �������
             ,ic_tran_pnd                 itp                      -- OPM�ۗ��݌Ƀg�����U�N�V�����\
             ,ic_item_mst_b               iimb                     -- OPM�i�ڃ}�X�^
             ,xxcmn_item_categories5_v    xicv                     -- OPM�i�ڃJ�e�S���������View5
             ,ic_lots_mst                 ilm                      -- OPM���b�g�}�X�^
             ,xxcmn_lot_cost              xlc                      -- ���b�g�ʌ����A�h�I��
             ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
             ,gmi_item_categories         gic                      -- OPM�i�ڃJ�e�S������
             ,mtl_categories_b            mcb                      -- �i�ڃJ�e�S���}�X�^
             ,gmi_item_categories         gic2                     -- OPM�i�ڃJ�e�S������2
             ,mtl_categories_b            mcb2                     -- �i�ڃJ�e�S���}�X�^2
      WHERE  xoha.latest_external_flag         = cv_flag_y                                       -- �ŐV�t���O�FY
      AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                               AND     gd_target_date_to                         -- ���ד��F�݌ɉ�v���ԓ�
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.org_id                       = gn_org_id_mfg                                   -- ���YORG ID
      AND    xola.order_header_id              = xoha.order_header_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                                       -- ���׍폜�t���O�FN
      AND    xmld.mov_line_id                  = xola.order_line_id
      AND    xmld.document_type_code           = cv_document_type_code_10                        -- �����^�C�v�F�o�׈˗�
      AND    xmld.record_type_code             = cv_record_type_code_20                          -- ���R�[�h�^�C�v�F�o�Ɏ���
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    oola.header_id                    = xola.header_id
      AND    oola.line_id                      = xola.line_id
      AND    otta.transaction_type_id          = ooha.order_type_id
      AND    otta.attribute1                   = cv_ship_prov_3                                  -- �o�׎x���敪�F�q�֕ԕi
      AND    otta.attribute4                   = cv_inv_adjust_1                                 -- �݌ɒ����敪�F1�i���݌ɒ����j
      AND    rsl.oe_order_header_id            = xola.HEADER_ID
      AND    rsl.oe_order_line_id              = xola.LINE_ID
      AND    itp.doc_id                        = rsl.shipment_header_id
      AND    itp.doc_line                      = rsl.line_num
      AND    itp.doc_type                      = cv_doc_type_porc                                -- �����^�C�v�FPORC
      AND    itp.completed_ind                 = cn_completed_ind_1                              -- �����t���O�F1
      AND    iimb.item_no                      = xola.shipping_item_code
      AND    gic.item_id                       = iimb.item_id
      AND    gic.category_set_id               = TO_NUMBER(fnd_profile.value(cv_cat_crowd_code)) -- �J�e�S���Z�b�gID1�FXXCMN_ITEM_CATEGORY_CROWD_CODE
      AND    gic.category_id                   = mcb.category_id
      AND    gic2.item_id                      = iimb.item_id
      AND    gic2.category_set_id              = TO_NUMBER(fnd_profile.value(cv_cat_item_class)) -- �J�e�S���Z�b�gID2�FXXCMN_ITEM_CATEGORY_ITEM_CLASS
      AND    gic2.category_id                  = mcb2.category_id
      AND    mcb2.segment1                     = cv_segment1_5                                   -- �Z�O�����g1�F���i
      AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
      AND    xrpm.shipment_provision_div       = otta.attribute1
      AND    xrpm.doc_type                     = itp.doc_type
      AND    xrpm.source_document_code         = cv_source_doc_code_rma                          -- �\�[�X�����FRMA
      AND    xrpm.dealings_div                 in (cv_dealings_div_201, cv_dealings_div_203)     -- ����敪�F�q�֕ԕi
      AND    xrpm.break_col_02                 IS NOT NULL
      AND    xmld.item_id                      = ilm.item_id
      AND    xmld.lot_id                       = ilm.lot_id
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xicv.ITEM_ID                      = iimb.item_id
      AND    ( (xrpm.dealings_div              = cv_dealings_div_201                             -- ����敪�F�q��
          AND   xicv.prod_class_code           in (cv_prod_class_code_1, cv_prod_class_code_2))  -- ���i�敪�F���[�t�E�h�����N
        OR     (xrpm.dealings_div              = cv_dealings_div_203                             -- ����敪�F�ԕi
          AND   xicv.prod_class_code           = cv_prod_class_code_1)                           -- ���i�敪�F���[�t
             )
      UNION ALL
      -- ���o�D���(�q�֕ԕi����)���
      SELECT  /*+ LEADING(xoha ooha otta xrpm xola wdd itp xmld oola ilm xlc iimb) 
                        USE_NL(ooha otta xrpm xola wdd itp xmld oola ilm xlc iimb xola oola xicv gic mcb gic2 mcb2 xsup)
                  INDEX  (xoha XXWSH_OH_N32)    */
              ROUND((CASE iimb.attribute15
                        WHEN '1' THEN (SELECT NVL(xsup.stnd_unit_price, 0) 
                                       FROM   xxcmn_stnd_unit_price_v     xsup     -- �W���������u������
                                       WHERE  xsup.item_id = itp.item_id
                                       AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                                AND     NVL(xsup.end_date_active, xoha.arrival_date))
                        ELSE DECODE(iimb.lot_ctl
                                   ,1,NVL(xlc.unit_ploce, 0)
                                   ,(SELECT NVL(xsup.stnd_unit_price, 0) 
                                     FROM   xxcmn_stnd_unit_price_v     xsup     -- �W���������u������
                                     WHERE  xsup.item_id = itp.item_id
                                     AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                               AND     NVL(xsup.end_date_active, xoha.arrival_date)) )
                     END) * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))
              )                                          AS price           -- ���z
             ,xrpm.dealings_div                          AS dealings_div    -- ����敪
             ,xicv.ITEM_CLASS_CODE                       AS item_class_code -- �i�ڋ敪
             ,xicv.prod_class_code                       AS prod_class_code -- ���i�敪
             ,oola.HEADER_ID                             AS header_id       -- �󒍃w�b�_ID
             ,oola.LINE_ID                               AS line_id         -- �󒍖���ID
             ,oola.attribute4                            AS  je_key         -- �d��L�[
      FROM    oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
             ,oe_order_lines_all          oola                     --�󒍖���(�W��)
             ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
             ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
             ,oe_transaction_types_all    otta                     --�󒍃^�C�v
             ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
             ,wsh_delivery_details        wdd                      --�o�ה�������
             ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
             ,ic_item_mst_b               iimb                     --OPM�i�ڃ}�X�^
             ,xxcmn_item_categories5_v    xicv                     --OPM�i�ڃJ�e�S���������View5
             ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
             ,xxcmn_lot_cost              xlc                      --���b�g�ʌ����A�h�I��
             ,xxcmn_rcv_pay_mst           xrpm                     --�󕥋敪�A�h�I���}�X�^
             ,gmi_item_categories         gic                      --OPM�i�ڃJ�e�S������
             ,MTL_CATEGORIES_B            mcb                      --�i�ڃJ�e�S���}�X�^
             ,gmi_item_categories         gic2                     --OPM�i�ڃJ�e�S������2
             ,MTL_CATEGORIES_B            mcb2                     --�i�ڃJ�e�S���}�X�^2
      WHERE   xoha.latest_external_flag         = cv_flag_y   --�ŐV�t���O�FY
      AND     xoha.arrival_date                 BETWEEN gd_target_date_from
                                                AND     gd_target_date_to
      AND     ooha.header_id                    = xoha.header_id
      AND     ooha.org_id                       = gn_org_id_mfg
      AND     xola.order_header_id              = xoha.order_header_id
      AND     NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n   --���׍폜�t���O�FN
      AND     xmld.mov_line_id                  = xola.order_line_id
      AND     xmld.document_type_code           = cv_document_type_code_10      --�����^�C�v�F�o�׈˗�
      AND     xmld.RECORD_TYPE_CODE             = cv_record_type_code_20      --���R�[�h�^�C�v�F�o�Ɏ���
      AND     xmld.item_id                      = itp.item_id
      AND     xmld.lot_id                       = itp.lot_id
      AND     oola.HEADER_ID                    = xola.HEADER_ID
      AND     oola.LINE_ID                      = xola.LINE_ID
      AND     otta.transaction_type_id          = ooha.order_type_id
      AND     otta.attribute1                   = cv_ship_prov_3   --�o�׎x���敪�F�q�֕ԕi
      AND   ((otta.attribute4                  <> cv_inv_adjust_2)   --�݌ɒ����敪�F2�ȊO
        OR   (otta.attribute4       IS NULL ))
      AND     wdd.source_header_id              = xola.HEADER_ID
      AND     wdd.source_line_id                = xola.LINE_ID
      AND     itp.line_detail_id                = wdd.delivery_detail_id
      AND     itp.doc_type                      = cv_doc_type_omso
      AND     itp.completed_ind                 = cn_completed_ind_1
      AND     iimb.item_no                      = xola.shipping_item_code
      AND     gic.item_id                       = iimb.item_id
      AND     gic.category_set_id               = TO_NUMBER(FND_PROFILE.VALUE(cv_cat_crowd_code))
      AND     gic.category_id                   = mcb.category_id
      AND     gic2.item_id                      = iimb.item_id
      AND     gic2.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_cat_item_class))
      AND     gic2.category_id                  = mcb2.category_id
      AND     mcb2.segment1                     = cv_segment1_5        --���i
      AND     xrpm.ship_prov_rcv_pay_category   = otta.attribute11
      AND     xrpm.shipment_provision_div       = otta.attribute1
      AND     xrpm.doc_type                     = itp.doc_type
      AND     xrpm.dealings_div                 in (cv_dealings_div_201,cv_dealings_div_203)  --�q�֕ԕi
      AND     xrpm.break_col_02                 IS NOT NULL
      AND     xmld.item_id                      = ilm.item_id
      AND     xmld.lot_id                       = ilm.lot_id
      AND     ilm.item_id                       = xlc.item_id(+)
      AND     ilm.lot_id                        = xlc.lot_id(+)
      AND     xicv.ITEM_ID                      = iimb.item_id
      AND   ((xrpm.dealings_div               = cv_dealings_div_201
        AND   xicv.prod_class_code   in (cv_prod_class_code_1,cv_prod_class_code_2))
        OR   (xrpm.dealings_div     = cv_dealings_div_203
        AND   xicv.prod_class_code   = cv_prod_class_code_1))
      ORDER BY  dealings_div          -- ����敪
               ,item_class_code       -- �i�ڋ敪
               ,prod_class_code       -- ���i�敪
               ,je_key                -- �d��L�[
    ;
    -- GL�d��OIF���i�[�pPL/SQL�\
    TYPE journal_oif_data_ttype IS TABLE OF get_journal_oif_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data_tab                    journal_oif_data_ttype;
--
    --
    CURSOR get_journal_oif_data5_cur
    IS
      -- ���o�D���o ������U�֕��i���i�ցj
      SELECT /*+ LEADING(xoha xola wdd itp ooha otta)
                 USE_NL (     xola wdd itp ooha otta xicv1.iimb xicv1.gic_s xicv1.mcb_s xicv1.mct_s xicv1.gic_h xicv1.mcb_h xicv1.mct_h xrpm 
                         xicv2.iimb xicv2.gic_s xicv2.mcb_s xicv2.mct_s xicv2.gic_h xicv2.mcb_h xicv2.mct_h oola ilm)  
                 INDEX  (xoha XXWSH_OH_N32)    */
       ROUND( NVL(itp.trans_qty, 0)             *
              TO_NUMBER(NVL(ilm.attribute7, 0)) *
              TO_NUMBER(xrpm.rcv_pay_div) )        AS  price            -- ���z
            ,oola.header_id                        AS  header_id        -- �󒍃w�b�_ID
            ,oola.line_id                          AS  line_id          -- �󒍖���ID
            ,oola.attribute4                       AS  je_key           -- �d��L�[
      FROM   ic_tran_pnd                 itp                      -- �ۗ��݌Ƀg�����U�N�V����
            ,xxwsh_order_headers_all     xoha                     -- �󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all       xola                     -- �󒍖��׃A�h�I��
            ,wsh_delivery_details        wdd                      -- ��������
            ,oe_order_headers_all        ooha                     -- �󒍃w�b�_(�W��)
            ,oe_order_lines_all          oola                     -- �󒍖���(�W��)
            ,oe_transaction_types_all    otta                     -- �󒍃^�C�v
            ,xxcmn_rcv_pay_mst           xrpm                     -- �󕥋敪�A�h�I���}�X�^
            ,xxcmn_item_categories5_v    xicv1                    -- OPM�i�ڃJ�e�S���������View5 1
            ,xxcmn_item_categories5_v    xicv2                    -- OPM�i�ڃJ�e�S���������View5 2
            ,ic_lots_mst                 ilm                      -- OPM���b�g�}�X�^
      WHERE  itp.doc_type                = cv_doc_type_omso                     -- �����^�C�v
      AND    itp.completed_ind           = cn_completed_ind_1                   -- �����t���O
      AND    xoha.arrival_date           >= gd_target_date_from                 -- �J�n��
      AND    xoha.arrival_date           <= gd_target_date_to                   -- �I����
      AND    xoha.req_status             = cv_req_status_4                      -- �˗��X�e�[�^�X:�o�׎��ьv���
      AND    xoha.latest_external_flag   = cv_latest_external_flag_y            -- �ŐV�t���O�FY
      AND    xoha.order_header_id        = xola.order_header_id
      AND    ooha.header_id              = xoha.header_id
      AND    oola.header_id              = xola.header_id
      AND    oola.line_id                = xola.line_id
      AND    otta.transaction_type_id    = ooha.order_type_id
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ( xrpm.ship_prov_rcv_pay_category IS NULL
        OR     xrpm.ship_prov_rcv_pay_category = otta.attribute11 )
      AND    otta.attribute4             <> cv_inv_adjust_2                     -- �݌ɒ����敪�F2�i���݌ɒ����ȊO�j
      AND    xrpm.dealings_div           = cv_dealings_div_113                  -- ����敪�i�U�֏o��_���o�j
      AND    xrpm.doc_type               = itp.doc_type
      AND    xicv1.item_id               = itp.item_id
      AND    xicv1.item_class_code       = cv_item_class_code_1                 -- ����
      AND    xicv1.prod_class_code       = cv_prod_class_code_1                 -- ���[�t
      AND    xicv2.item_no               = xola.request_item_code
      AND    xicv2.item_class_code       = xrpm.item_div_ahead
      AND    wdd.delivery_detail_id      = itp.line_detail_id
      AND    wdd.source_header_id        = xoha.header_id
      AND    wdd.source_line_id          = xola.line_id
      AND    ilm.lot_id                  = itp.lot_id
      AND    ilm.item_id                 = itp.item_id
      ;
    -- GL�d��OIF���5�i�[�pPL/SQL�\
    TYPE journal_oif_data5_ttype IS TABLE OF get_journal_oif_data5_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data5_tab                     journal_oif_data5_ttype;
--
    -- ���o ������U�ցi�h�����N�j
    CURSOR get_journal_oif_data10_1_cur
    IS
      -- ���o�E-1������U�ցi�U�֏o�Ɂj�o�ו�  
      SELECT /*+ LEADING(xoha xola wdd itp ooha otta)
                 USE_NL (     xola wdd itp ooha otta xicv1.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xrpm 
                         xicv2.iimb xicv2.gic_s xicv2.mcb_s xicv2.mct_s xicv2.gic_h xicv2.mcb_h xicv2.mct_h oola ilm)  
                 INDEX  (xoha XXWSH_OH_N32)    */
             ROUND( NVL(itp.trans_qty, 0)             * 
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS   price        -- ���z
            ,oola.header_id                              AS   header_id    -- �󒍃w�b�_ID
            ,oola.line_id                                AS   line_id      -- �󒍖���ID
            ,oola.attribute4                             AS   je_key       -- �d��L�[
      FROM   ic_tran_pnd                  itp                      -- �ۗ��݌Ƀg�����U�N�V����
            ,xxwsh_order_headers_all      xoha                     -- �󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all        xola                     -- �󒍖��׃A�h�I��
            ,wsh_delivery_details         wdd                      -- ��������
            ,oe_order_headers_all         ooha                     -- �󒍃w�b�_(�W��)
            ,oe_order_lines_all           oola                     -- �󒍖���(�W��)
            ,oe_transaction_types_all     otta                     -- �󒍃^�C�v
            ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
            ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
            ,xxcmn_item_categories5_v     xicv2                    -- OPM�i�ڃJ�e�S���������View5 2
            ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
      WHERE  itp.doc_type                     = cv_doc_type_omso                      -- �����^�C�v
      AND    itp.completed_ind                = cn_completed_ind_1                    -- �����t���O
      AND    xoha.arrival_date               >= gd_target_date_from                  -- �J�n��
      AND    xoha.arrival_date               <= gd_target_date_to                    -- �I����
      AND    xoha.req_status                  = cv_req_status_8                       -- �o�׎��ьv���
      AND    xoha.latest_external_flag        = cv_latest_external_flag_y             -- �ŐV�t���O�FY
      AND    xoha.order_header_id             = xola.order_header_id
      AND    ooha.header_id                   = xoha.header_id
      AND    oola.header_id                   = xola.header_id
      AND    oola.line_id                     = xola.line_id
      AND    otta.transaction_type_id         = ooha.order_type_id
      AND    xrpm.shipment_provision_div      = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category  = otta.attribute11
      AND    otta.attribute4                  <> cv_inv_adjust_2                     -- �݌ɒ����ȊO
      AND    xrpm.dealings_div                = cv_dealings_div_106                  -- ����敪�F�U�֗L��_���o
      AND    xrpm.doc_type                    = itp.doc_type
      AND    xicv.item_id                     = itp.item_id
      AND    xicv.item_class_code             = cv_item_class_code_1                 -- ����
      AND    xicv.prod_class_code             = cv_prod_class_code_2                 -- �h�����N
      AND    xicv2.item_no                    = xola.request_item_code
      AND    xicv2.item_class_code            = xrpm.item_div_ahead
      AND    wdd.delivery_detail_id           = itp.line_detail_id
      AND    wdd.source_header_id             = ooha.header_id
      AND    wdd.source_line_id               = xola.line_id
      AND    ilm.lot_id                       = itp.lot_id
      AND    ilm.item_id                      = itp.item_id
      UNION ALL
      -- ���o�E-2������U�ցi�U�֏o�Ɂj�ԕi�󒍁i�����j��
      SELECT /*+ LEADING(xoha xola rsl itp ooha otta)
                 USE_NL (     xola rsl itp ooha otta xicv1.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xrpm 
                         xicv2.iimb xicv2.gic_s xicv2.mcb_s xicv2.mct_s xicv2.gic_h xicv2.mcb_h xicv2.mct_h oola ilm)  
                 INDEX  (xoha XXWSH_OH_N32)    */
             ROUND( NVL(itp.trans_qty, 0)             * 
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS   price        -- ���z
            ,oola.header_id                              AS   header_id    -- �󒍃w�b�_ID
            ,oola.line_id                                AS   line_id      -- �󒍖���ID
            ,oola.attribute4                             AS   je_key       -- �d��L�[
      FROM   ic_tran_pnd                  itp                      -- �ۗ��݌Ƀg�����U�N�V����
            ,xxwsh_order_headers_all      xoha                     -- �󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all        xola                     -- �󒍖��׃A�h�I��
            ,rcv_shipment_lines           rsl                      -- �������
            ,oe_order_headers_all         ooha                     -- �󒍃w�b�_(�W��)
            ,oe_order_lines_all           oola                     -- �󒍖���(�W��)
            ,oe_transaction_types_all     otta                     -- �󒍃^�C�v
            ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
            ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
            ,xxcmn_item_categories5_v     xicv2                    -- OPM�i�ڃJ�e�S���������View5 2
            ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
      WHERE  itp.doc_type                     = cv_doc_type_porc                      -- �����^�C�v
      AND    itp.completed_ind                = cn_completed_ind_1                    -- �����t���O
      AND    xoha.arrival_date                >= gd_target_date_from                  -- �J�n��
      AND    xoha.arrival_date                <= gd_target_date_to                    -- �I����
      AND    xoha.req_status                  = cv_req_status_8                       -- �o�׎��ьv���
      AND    xoha.latest_external_flag        = cv_latest_external_flag_y             -- �ŐV�t���O�FY
      AND    xoha.order_header_id             = xola.order_header_id
      AND    ooha.header_id                   = xoha.header_id
      AND    oola.header_id                   = xola.header_id
      AND    oola.line_id                     = xola.line_id
      AND    otta.transaction_type_id         = ooha.order_type_id
      AND    xrpm.shipment_provision_div      = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category  = otta.attribute11
      AND    otta.attribute4                  <> cv_inv_adjust_2                     -- �݌ɒ����ȊO
      AND    xrpm.dealings_div                = cv_dealings_div_106                  -- ����敪�F�U�֗L��_���o
      AND    xrpm.doc_type                    = itp.doc_type
      AND    xrpm.source_document_code        = cv_source_doc_code_rma
      AND    xicv.item_id                     = itp.item_id
      AND    xicv.item_class_code             = cv_item_class_code_1                 -- ����
      AND    xicv.prod_class_code             = cv_prod_class_code_2                 -- �h�����N
      AND    xicv2.item_no                    = xola.request_item_code
      AND    xicv2.item_class_code            = xrpm.item_div_ahead
      AND    rsl.shipment_header_id           = itp.doc_id
      AND    rsl.line_num                     = itp.doc_line
      AND    rsl.oe_order_header_id           = xoha.header_id
      AND    rsl.oe_order_line_id             = xola.line_id
      AND    ilm.lot_id                       = itp.lot_id
      AND    ilm.item_id                      = itp.item_id;
--
    -- GL�d��OIF���10�i�[�pPL/SQL�\
    TYPE journal_oif_data10_1_ttype IS TABLE OF get_journal_oif_data10_1_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data10_1_tab                     journal_oif_data10_1_ttype;
--
    CURSOR get_journal_oif_data10_2_cur
    IS
      -- ���o�E-3������U�ցi���i�ցj�o�ו�
      SELECT /*+ LEADING(xoha xola wdd itp ooha otta)
                 USE_NL (     xola wdd itp ooha otta xicv1.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xrpm 
                         xicv2.iimb xicv2.gic_s xicv2.mcb_s xicv2.mct_s xicv2.gic_h xicv2.mcb_h xicv2.mct_h oola ilm)  
                 INDEX  (xoha XXWSH_OH_N32)    */
             ROUND( NVL(itp.trans_qty, 0)             * 
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS   price        -- ���z
            ,oola.header_id                              AS   header_id    -- �󒍃w�b�_ID
            ,oola.line_id                                AS   line_id      -- �󒍖���ID
            ,oola.attribute4                             AS   je_key       -- �d��L�[
      FROM   ic_tran_pnd                  itp                      -- �ۗ��݌Ƀg�����U�N�V����
            ,xxwsh_order_headers_all      xoha                     -- �󒍃w�b�_�A�h�I��
            ,xxwsh_order_lines_all        xola                     -- �󒍖��׃A�h�I��
            ,wsh_delivery_details         wdd                      -- ��������
            ,oe_order_headers_all         ooha                     -- �󒍃w�b�_(�W��)
            ,oe_order_lines_all           oola                     -- �󒍖���(�W��)
            ,oe_transaction_types_all     otta                     -- �󒍃^�C�v
            ,xxcmn_rcv_pay_mst            xrpm                     -- �󕥋敪�A�h�I���}�X�^
            ,xxcmn_item_categories5_v     xicv                     -- OPM�i�ڃJ�e�S���������View5
            ,xxcmn_item_categories5_v     xicv2                    -- OPM�i�ڃJ�e�S���������View5 2
            ,ic_lots_mst                  ilm                      -- OPM���b�g�}�X�^
      WHERE  itp.doc_type                     = cv_doc_type_omso                      -- �����^�C�v
      AND    itp.completed_ind                = cn_completed_ind_1                    -- �����t���O
      AND    xoha.arrival_date                >= gd_target_date_from                  -- �J�n��
      AND    xoha.arrival_date                <= gd_target_date_to                    -- �I����
      AND    xoha.req_status                  = cv_req_status_4                       -- �o�׎��ьv���
      AND    xoha.latest_external_flag        = cv_latest_external_flag_y             -- �ŐV�t���O�FY
      AND    xoha.order_header_id             = xola.order_header_id
      AND    ooha.header_id                   = xoha.header_id
      AND    oola.header_id                   = xola.header_id
      AND    oola.line_id                     = xola.line_id
      AND    otta.transaction_type_id         = ooha.order_type_id
      AND    xrpm.shipment_provision_div      = otta.attribute1
      AND    otta.attribute4                  <> cv_inv_adjust_2                     -- �݌ɒ����ȊO
      AND    xrpm.dealings_div                = cv_dealings_div_113                  -- ����敪�F�U�֏o��_���o
      AND    xrpm.doc_type                    = itp.doc_type
      AND    xicv.item_id                     = itp.item_id
      AND    xicv.item_class_code             = cv_item_class_code_1                 -- ����
      AND    xicv.prod_class_code             = cv_prod_class_code_2                 -- �h�����N
      AND    xicv2.item_no                    = xola.request_item_code
      AND    xicv2.item_class_code            = xrpm.item_div_ahead
      AND    wdd.delivery_detail_id           = itp.line_detail_id
      AND    wdd.source_header_id             = ooha.header_id
      AND    wdd.source_line_id               = xola.line_id
      AND    ilm.lot_id                       = itp.lot_id
      AND    ilm.item_id                      = itp.item_id
      ;
    -- GL�d��OIF���10�i�[�pPL/SQL�\
    TYPE journal_oif_data10_2_ttype IS TABLE OF get_journal_oif_data10_2_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data10_2_tab                     journal_oif_data10_2_ttype;
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
    -- �D���o ������U�֕��i���i�ցj
    -- ===============================
    -- ������
    g_oe_order_lines_tab.DELETE;                     -- ���Y����f�[�^�X�V���i�[�pPL/SQL�\�̏�����
    ln_out_count           := 0;                     -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
    gn_price_all           := 0;                     -- ���z
    gv_item_class_code_hdr := cv_item_class_code_1;  -- �i�ڋ敪�F����
    gv_prod_class_code_hdr := cv_prod_class_code_1;  -- ���i�敪�F���[�t
--
    -- ===============================
    -- ���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_journal_oif_data5_cur;
    -- �o���N�t�F�b�`
    FETCH get_journal_oif_data5_cur BULK COLLECT INTO journal_oif_data5_tab;
    -- �J�[�\���N���[�Y
    IF ( get_journal_oif_data5_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data5_cur;
    END IF;
--
    <<main_loop5>>
    FOR ln_count in 1..journal_oif_data5_tab.COUNT LOOP
--
      -- �����Ώی�����ݒ�
      gn_target_cnt := gn_target_cnt + 1;
      -- �Ώی������J�E���g(���Y����f�[�^�X�V�p)
      ln_out_count  := ln_out_count + 1;
      -- �u�󒍃w�b�_ID�v�A�u�󒍖���ID�v��ێ�
      g_oe_order_lines_tab(ln_out_count).header_id := journal_oif_data5_tab(ln_count).header_id;
      g_oe_order_lines_tab(ln_out_count).line_id   := journal_oif_data5_tab(ln_count).line_id;
      -- ���z�����Z
      gn_price_all  := gn_price_all + journal_oif_data5_tab(ln_count).price;
      -- �d��L�[��ێ�
      ln_je_key     := NULL;
--
    END LOOP main_loop5;
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
        iv_process_no            => cv_process_no_02, -- �����ԍ��F2
        in_je_key                => ln_je_key,        -- �d��L�[
        ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���Y����f�[�^�X�V(A-6)
      -- ===============================
      upd_inv_trn_data(
        in_je_key                => ln_je_key,        -- �d��L�[
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
    -- �E-1�A�E-2���o ������U�ցi�h�����N�j���̂P
    -- ===============================
    -- ������
    g_oe_order_lines_tab.DELETE;                     -- ���Y����f�[�^�X�V���i�[�pPL/SQL�\�̏�����
    ln_out_count           := 0;                     -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
    gn_price_all           := 0;                     -- ���z
    gv_item_class_code_hdr := cv_item_class_code_1;  -- �i�ڋ敪�F����
    gv_prod_class_code_hdr := cv_prod_class_code_2;  -- ���i�敪�F�h�����N
--
    -- ===============================
    -- ���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_journal_oif_data10_1_cur;
    -- �o���N�t�F�b�`
    FETCH get_journal_oif_data10_1_cur BULK COLLECT INTO journal_oif_data10_1_tab;
    -- �J�[�\���N���[�Y
    IF ( get_journal_oif_data10_1_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data10_1_cur;
    END IF;
--
    <<main_loop10>>
    FOR ln_count in 1..journal_oif_data10_1_tab.COUNT LOOP
--
      -- �����Ώی�����ݒ�
      gn_target_cnt := gn_target_cnt + 1;
      -- �Ώی������J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
      ln_out_count  := ln_out_count + 1;
      -- �u�󒍃w�b�_ID�v�A�u�󒍖���ID�v��ێ�
      g_oe_order_lines_tab(ln_out_count).header_id := journal_oif_data10_1_tab(ln_count).header_id;
      g_oe_order_lines_tab(ln_out_count).line_id   := journal_oif_data10_1_tab(ln_count).line_id;
      -- ���z�����Z
      gn_price_all  := gn_price_all + journal_oif_data10_1_tab(ln_count).price;
      -- �d��L�[��ێ�
      ln_je_key     := NULL;
--
    END LOOP main_loop10;
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
        iv_process_no            => cv_process_no_03, -- �����ԍ��F3
        in_je_key                => ln_je_key,        -- �d��L�[
        ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���Y����f�[�^�X�V(A-6)
      -- ===============================
      upd_inv_trn_data(
        in_je_key                => ln_je_key,        -- �d��L�[
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
    -- �E-3���o ������U�ցi�h�����N�j���̂Q
    -- ===============================
    -- ������
    g_oe_order_lines_tab.DELETE;                     -- ���Y����f�[�^�X�V���i�[�pPL/SQL�\�̏�����
    ln_out_count           := 0;                     -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
    gn_price_all           := 0;                     -- ���z
    gv_item_class_code_hdr := cv_item_class_code_1;  -- �i�ڋ敪�F����
    gv_prod_class_code_hdr := cv_prod_class_code_2;  -- ���i�敪�F�h�����N
--
    -- ===============================
    -- ���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_journal_oif_data10_2_cur;
    -- �o���N�t�F�b�`
    FETCH get_journal_oif_data10_2_cur BULK COLLECT INTO journal_oif_data10_2_tab;
    -- �J�[�\���N���[�Y
    IF ( get_journal_oif_data10_2_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data10_2_cur;
    END IF;
--
    <<main_loop10>>
    FOR ln_count in 1..journal_oif_data10_2_tab.COUNT LOOP
--
      -- �����Ώی�����ݒ�
      gn_target_cnt := gn_target_cnt + 1;
      -- �Ώی������J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
      ln_out_count  := ln_out_count + 1;
      -- �u�󒍃w�b�_ID�v�A�u�󒍖���ID�v��ێ�
      g_oe_order_lines_tab(ln_out_count).header_id := journal_oif_data10_2_tab(ln_count).header_id;
      g_oe_order_lines_tab(ln_out_count).line_id   := journal_oif_data10_2_tab(ln_count).line_id;
      -- ���z�����Z
      gn_price_all  := gn_price_all + journal_oif_data10_2_tab(ln_count).price;
      -- �d��L�[��ێ�
      ln_je_key     := NULL;
--
    END LOOP main_loop10;
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
        iv_process_no            => cv_process_no_03, -- �����ԍ��F3
        in_je_key                => ln_je_key,        -- �d��L�[
        ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- ���Y����f�[�^�X�V(A-6)
      -- ===============================
      upd_inv_trn_data(
        in_je_key                => ln_je_key,        -- �d��L�[
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
    -- �@�A�B�C���o
    -- ===============================
    -- ������
    g_oe_order_lines_tab.DELETE;                     -- ���Y����f�[�^�X�V���i�[�pPL/SQL�\�̏�����
    ln_out_count           := 0;                     -- �J�E���g(���Y�����ڍ׃f�[�^�X�V�p)
    gn_price_all           := 0;                     -- ���z
    gv_dealings_div_hdr    := NULL;
    gv_item_class_code_hdr := NULL;
    gv_prod_class_code_hdr := NULL;
    ln_je_key              := NULL;
--
    -- ===============================
    -- 1.���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_journal_oif_data_cur;
    -- �o���N�t�F�b�`
    FETCH get_journal_oif_data_cur BULK COLLECT INTO journal_oif_data_tab;
    -- �J�[�\���N���[�Y
    IF ( get_journal_oif_data_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data_cur;
    END IF;
--
    <<main_loop>>
    FOR ln_count in 1..journal_oif_data_tab.COUNT LOOP
--
      -- �����Ώی�����ݒ�
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �u���C�N�L�[���O���R�[�h�ƈႤ�ꍇ�A�O���R�[�h�̓o�^���s��(1���R�[�h�ڂ͑ΏۊO)
      IF ( ( NVL(gv_dealings_div_hdr, journal_oif_data_tab(ln_count).dealings_div )      <> journal_oif_data_tab(ln_count).dealings_div )
        OR ( NVL(gv_item_class_code_hdr,journal_oif_data_tab(ln_count).item_class_code ) <> journal_oif_data_tab(ln_count).item_class_code )
        OR ( NVL(gv_prod_class_code_hdr,journal_oif_data_tab(ln_count).prod_class_code ) <> journal_oif_data_tab(ln_count).prod_class_code )
        OR ( NVL(ln_je_key, -1) <> NVL(journal_oif_data_tab(ln_count).je_key, -1) AND ln_count > 1 ) ) THEN
        -- ���z��0�̏ꍇ�AA-5,A-6�̏��������Ȃ�
        IF ( gn_price_all = 0 ) THEN
          -- �X�L�b�v�����ɑΏی����������Z
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 2.�d��OIF�o�^(A-5)
          -- ===============================
          ins_journal_oif(
            iv_process_no            => cv_process_no_01, -- �����ԍ��F1
            in_je_key                => ln_je_key,        -- �d��L�[
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 3.���Y����f�[�^�X�V(A-6)
          -- ===============================
          upd_inv_trn_data(
            in_je_key                => ln_je_key,        -- �d��L�[
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
        -- 4.�������P�ʂ̏������ϐ��̏����������{
        -- ===============================
        ln_out_count     := 0;       -- �J�E���g(���Y����f�[�^�X�V�p)
        gn_price_all     := 0;       -- ���z
        g_oe_order_lines_tab.DELETE; -- ���Y����f�[�^�X�V���i�[�pPL/SQL�\�̏�����
      END IF;
--
      -- �Ώی������J�E���g(���Y����f�[�^�X�V�p)
      ln_out_count :=  ln_out_count + 1;
      -- ���z�����Z
      gn_price_all     := gn_price_all + journal_oif_data_tab(ln_count).price;
      -- �u�󒍃w�b�_ID�v�A�u�󒍖���ID�v��ێ�
      g_oe_order_lines_tab(ln_out_count).header_id := journal_oif_data_tab(ln_count).header_id;
      g_oe_order_lines_tab(ln_out_count).line_id   := journal_oif_data_tab(ln_count).line_id;
      -- �u���[�N�L�[��ێ�
      gv_dealings_div_hdr    := journal_oif_data_tab(ln_count).dealings_div;
      gv_item_class_code_hdr := journal_oif_data_tab(ln_count).item_class_code;
      gv_prod_class_code_hdr := journal_oif_data_tab(ln_count).prod_class_code;
      ln_je_key              := journal_oif_data_tab(ln_count).je_key;
--
      -- �ŏI���R�[�h�̏ꍇ
      IF ( ln_count = journal_oif_data_tab.COUNT ) THEN
        -- ���z��0�̏ꍇ�AA-5,A-6�̏��������Ȃ�
        IF ( gn_price_all = 0 ) THEN
          -- �X�L�b�v�����ɑΏی����������Z
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 2.�d��OIF�o�^(A-5)
          -- ===============================
          ins_journal_oif(
            iv_process_no            => cv_process_no_01, -- �����ԍ��F1
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 3.���Y����f�[�^�X�V(A-6)
          -- ===============================
          upd_inv_trn_data(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
    END LOOP main_loop;
--
    -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�A�G���[
    IF ( gn_target_cnt = 0 ) THEN
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
      IF ( get_journal_oif_data_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data_cur;
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
      IF ( get_journal_oif_data_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data_cur;
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
         cv_pkg_name                         -- �@�\�� 'XXCFO020A05C'
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
                  , iv_token_value1 => cv_mesg_out_table_03                    -- �A�g�Ǘ��e�[�u��
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
    -- �A�g�Ǘ��e�[�u���o�^(A-7)
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
END XXCFO020A05C;
/
