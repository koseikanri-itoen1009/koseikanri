CREATE OR REPLACE PACKAGE BODY XXCFO020A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A04C(body)
 * Description      : �L���x���d��IF�쐬
 * MD.050           : �L���x���d��IF�쐬<MD050_CFO_020_A04>
 * Version          : 1.8
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  check_period_name      ��v���ԃ`�F�b�N(A-2)
 *  get_gl_interface_data  �d��OIF��񒊏o(A-3,4)
 *  ins_gl_interface       �d��OIF�o�^(���������E�L���x���E������E��������(A-5,6))
 *  upd_inv_trn_data       ���Y����f�[�^�X�V(A-7)
 *  ins_mfg_if_control     �A�g�Ǘ��e�[�u���o�^(A-8)
 *  upd_gl_interface       �d��OIF�X�V(A-10)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-10-30    1.0   T.Kobori         �V�K�쐬
 *  2015-01-22    1.1   A.Uchida         �V�X�e���e�X�g��Q�Ή�
 *                                       �E�U�֏o�ׂŁA�قȂ�i�ڋ敪�̕i�ڂ֐U�ւ��s���Ă���ꍇ�A
 *                                         �˗��i�ڂ̋敪���Q�Ƃ���B
 *                                       �E�d��OIF�́u�d�󖾍דE�v�v�ɐݒ肷��l���C���B
 *  2015-02-18    1.2   A.Uchida         �V�X�e���e�X�g��Q#44�A#46�A#47�Ή�
 *                                       �E#44:�d����P�ʂŎd����쐬����悤�C��
 *                                       �E#46:����ł̌v�Z���@���C��
 *  2015-11-18    1.3   Y.Shoji          E_�{�ғ�_13335�Ή�
 *  2017-12-05    1.4   S.Niki           E_�{�ғ�_14674�Ή�
 *                                       �E������������̏ꍇ�A�ŃR�[�h��NULL��ݒ�B
 *  2019-07-26    1.5   Y.Shoji          E_�{�ғ�_15786�Ή�
 *  2019-08-01    1.6   N.Miyamoto       E_�{�ғ�_15601 ���Y_�y���ŗ��Ή�
 *                                         �E�ŗ���i�ڂ��Ƃɏ���ŗ��r���[����擾����悤�d�l�ύX
 *  2020-05-27    1.7   S.Kuwako         E_�{�ғ�_16386�y��v�z�L���x��(�ԕi����)
 *  2024-11-19    1.8   R.Oikawa         E_�{�ғ�_19497�y��v�z���Y�C���{�C�X�Ή�
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
  gn_target_cnt    NUMBER DEFAULT 0;       -- �Ώی���
  gn_normal_cnt    NUMBER DEFAULT 0;       -- ���팏��
  gn_error_cnt     NUMBER DEFAULT 0;       -- �G���[����
  gn_warn_cnt      NUMBER DEFAULT 0;       -- �X�L�b�v����
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO020A04C';
  -- �A�v���P�[�V�����Z�k��
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcfo          CONSTANT VARCHAR2(10)  := 'XXCFO';                     -- XXCFO
--
  -- ����
  cv_lang                     CONSTANT VARCHAR2(50)  := USERENV( 'LANG' );
  -- ���b�Z�[�W�R�[�h
  cv_msg_cfo_00001            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00001';        -- �v���t�@�C�����擾�G���[���b�Z�[�W
  cv_msg_cfo_00019            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00019';        -- ���b�N�G���[
  cv_msg_cfo_00024            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00024';        -- �o�^�G���[���b�Z�[�W
  cv_msg_cfo_10035            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10035';        -- �f�[�^�擾�G���[���b�Z�[�W
  cv_msg_cfo_10042            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10042';        -- �f�[�^�X�V�G���[
  cv_msg_cfo_10043            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10043';        -- �Ώۃf�[�^�����G���[
  cv_msg_cfo_10047            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10047';        -- ���ʊ֐��G���[
  cv_msg_cfo_10052            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10052';        -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
  cv_msg_ccp_90000            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';        -- �Ώی������b�Z�[�W
  cv_msg_ccp_90001            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';        -- �����������b�Z�[�W
  cv_msg_ccp_90002            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';        -- �G���[�������b�Z�[�W
  cv_msg_ccp_90003            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';        -- �X�L�b�v�������b�Z�[�W
  cv_msg_ccp_90004            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';        -- ����I�����b�Z�[�W
  cv_msg_ccp_90005            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';        -- �x���I�����b�Z�[�W
  cv_msg_ccp_90006            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';        -- �G���[�I���S���[���o�b�N
-- 2019/08/01 Ver1.6 Add Start
  cv_msg_cfo_11155            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-11155';        -- �ŃR�[�h
-- 2019/08/01 Ver1.6 Add End
--
  -- �g�[�N��
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';              -- �g�[�N���F�p�����[�^��
  cv_tkn_param_val            CONSTANT VARCHAR2(20)  := 'PARAM_VAL';               -- �g�[�N���F�p�����[�^�l
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';               -- �g�[�N���F�v���t�@�C����
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';                  -- �g�[�N���FSQL�G���[���b�Z�[�W
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';                   -- �g�[�N���F�e�[�u����
  cv_tkn_data                 CONSTANT VARCHAR2(20)  := 'DATA';                    -- �g�[�N���F�f�[�^
  cv_tkn_item                 CONSTANT VARCHAR2(20)  := 'ITEM';                    -- �g�[�N���F�A�C�e��
  cv_tkn_key                  CONSTANT VARCHAR2(20)  := 'KEY';                     -- �g�[�N���F�L�[
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                   -- �g�[�N���F����
  -- CCID
  cv_tkn_process_date         CONSTANT VARCHAR2(20)  := 'PROCESS_DATE';            -- �g�[�N���F������
  cv_tkn_com_code             CONSTANT VARCHAR2(20)  := 'COM_CODE';                -- �g�[�N���F��ЃR�[�h
  cv_tkn_dept_code            CONSTANT VARCHAR2(20)  := 'DEPT_CODE';               -- �g�[�N���F����R�[�h
  cv_tkn_acc_code             CONSTANT VARCHAR2(20)  := 'ACC_CODE';                -- �g�[�N���F����ȖڃR�[�h
  cv_tkn_ass_code             CONSTANT VARCHAR2(20)  := 'ASS_CODE';                -- �g�[�N���F�⏕�ȖڃR�[�h
  cv_tkn_cust_code            CONSTANT VARCHAR2(20)  := 'CUST_CODE';               -- �g�[�N���F�ڋq�R�[�h
  cv_tkn_ent_code             CONSTANT VARCHAR2(20)  := 'ENT_CODE';                -- �g�[�N���F��ƃR�[�h
  cv_tkn_res1_code            CONSTANT VARCHAR2(20)  := 'RES1_CODE';               -- �g�[�N���F�\���P�R�[�h
  cv_tkn_res2_code            CONSTANT VARCHAR2(20)  := 'RES2_CODE';               -- �g�[�N���F�\���Q�R�[�h
--
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_SHIPMENT';             -- �d��p�^�[���F�o�׎��ѕ\
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_CATEGORY_MFG_FEE_PAY';     -- XXCFO:�d��J�e�S��_�L���o��
-- 2019/08/01 Ver1.6 Del Start
--  cv_profile_name_03          CONSTANT VARCHAR2(50)  := 'XXCMN_CONSUMPTION_TAX_RATE';         -- XXCMN:��������
-- 2019/08/01 Ver1.6 Del End
  cv_profile_name_04          CONSTANT VARCHAR2(50)  := 'XXCMN_ITEM_CATEGORY_ITEM_CLASS';     -- XXCMN:�i�ڋ敪
  cv_profile_name_05          CONSTANT VARCHAR2(50)  := 'XXCMN_ITEM_CATEGORY_PROD_CLASS';     -- XXCMN:���i�敪
  cv_profile_name_06          CONSTANT VARCHAR2(50)  := 'XXCMN_ITEM_CATEGORY_CROWD_CODE';     -- XXCMN:�Q�R�[�h
-- 2019/08/01 Ver1.6 Add Start
  cv_profile_name_07          CONSTANT VARCHAR2(50)  := 'ORG_ID';                             -- MO: �c�ƒP��
-- 2019/08/01 Ver1.6 Add End
--
  cv_file_type_out            CONSTANT VARCHAR2(20)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(20)  := 'LOG';
--
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- �t���O:N
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- �t���O:Y
--
  -- ���b�Z�[�W�o�͒l
  cv_msg_out_data_01         CONSTANT VARCHAR2(30)  := '�d��OIF';
  cv_msg_out_data_02         CONSTANT VARCHAR2(30)  := '�󒍖���';
  cv_msg_out_data_03         CONSTANT VARCHAR2(30)  := '�A�g�Ǘ��e�[�u��';
  -- 2015.01.22 Ver1.1 Mod Start
--  cv_msg_out_data_04         CONSTANT VARCHAR2(30)  := '�d����T�C�g�A�h�I���}�X�^';
  cv_msg_out_data_04         CONSTANT VARCHAR2(30)  := '�d����}�X�^';
  -- 2015.01.22 Ver1.1 Mod End
  cv_msg_out_data_05         CONSTANT VARCHAR2(30)  := 'AP�ŋ��R�[�h�}�X�^';
  --
  cv_msg_out_item_01         CONSTANT VARCHAR2(30)  := '�󒍃w�b�_ID,�󒍖���ID';
  cv_msg_out_item_02         CONSTANT VARCHAR2(30)  := '�d����T�C�gID';
-- 2019/08/01 Ver1.6 Del Start
--  cv_msg_out_item_03         CONSTANT VARCHAR2(30)  := '���Y�ŗ�';
-- 2019/08/01 Ver1.6 Del End
--
  -- �d��p�^�[���m�F�p
  cv_ptn_siwake_01            CONSTANT VARCHAR2(1)   := '1';
  cv_line_no_01               CONSTANT VARCHAR2(1)   := '1';
  cv_line_no_02               CONSTANT VARCHAR2(1)   := '2';
  cv_line_no_03               CONSTANT VARCHAR2(1)   := '3';
  cv_line_no_04               CONSTANT VARCHAR2(1)   := '4';
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  cv_dt_format                CONSTANT VARCHAR2(30) := 'YYYYMMDD HH24:MI:SS';
  cv_d_format                 CONSTANT VARCHAR2(30) := 'YYYYMMDD';
  cv_e_time                   CONSTANT VARCHAR2(10) := ' 23:59:59';
  cv_fdy                      CONSTANT VARCHAR2(02) := '01';           --�������t
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�v���t�@�C���擾
  gn_org_id_sales             NUMBER        DEFAULT NULL;    -- �g�DID (�c��)
  gv_company_code_mfg         VARCHAR2(100) DEFAULT NULL;    -- ��ЃR�[�h�i�H��j
  gv_aff5_customer_dummy      VARCHAR2(100) DEFAULT NULL;    -- �ڋq�R�[�h_�_�~�[�l
  gv_aff6_company_dummy       VARCHAR2(100) DEFAULT NULL;    -- ��ƃR�[�h_�_�~�[�l
  gv_aff7_preliminary1_dummy  VARCHAR2(100) DEFAULT NULL;    -- �\��1_�_�~�[�l
  gv_aff8_preliminary2_dummy  VARCHAR2(100) DEFAULT NULL;    -- �\��2_�_�~�[�l
  gv_je_invoice_source_mfg    VARCHAR2(100) DEFAULT NULL;    -- �d��\�[�X_���Y�V�X�e��
  gn_org_id_mfg               NUMBER        DEFAULT NULL;    -- �g�DID (���Y)
  gn_sales_set_of_bks_id      NUMBER        DEFAULT NULL;    -- �c�ƃV�X�e����v����ID
  gv_sales_set_of_bks_name    VARCHAR2(100) DEFAULT NULL;    -- �c�ƃV�X�e����v���떼
  gv_currency_code            VARCHAR2(100) DEFAULT NULL;    -- �c�ƃV�X�e���@�\�ʉ݃R�[�h
  gd_process_date             DATE          DEFAULT NULL;    -- �Ɩ����t
  gv_je_ptn_shipment          VARCHAR2(100) DEFAULT NULL;    -- �d��p�^�[���F�o�׎��ѕ\
  gv_je_category_mfg_fee_pay  VARCHAR2(100) DEFAULT NULL;    -- XXCFO: �d��J�e�S��_�L���o��
--
  gd_target_date_from         DATE          DEFAULT NULL;    -- ���o�Ώۓ��tFROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- ���o�Ώۓ��tTO
  gd_target_date_last         DATE          DEFAULT NULL;    -- ��v����_�ŏI��
  gv_period_name              VARCHAR2(7);                   -- IN�p����v����
--
  gt_attribute8               gl_interface.attribute8%TYPE;  -- �d��P�ʁF�Q�ƍ���1(�d��L�[)
  gv_description_dr           VARCHAR2(100) DEFAULT NULL;    -- �d��P�ʁF�E�v�i�ؕ��j
--
  -- ===============================
  -- ���[�U�[��`�v���C�x�[�g�^
  -- ===============================
--
  -- �L���x�����z���i�[�p
  TYPE g_gl_interface_rec IS RECORD
    (
      tax_rate                NUMBER                         -- ����ŗ�
     ,misyu_kin               NUMBER                         -- ��������
     ,jitu_kin                NUMBER                         -- �L���x��
     ,kari_kin                NUMBER                         -- �����
     ,tax_kin                 NUMBER                         -- ��������
     ,tax_code                NUMBER                         -- �ŃR�[�h�i�c�Ɓj
     ,tax_ccid                NUMBER                         -- ����Ŋ���CCID
    );
  TYPE g_gl_interface_ttype IS TABLE OF g_gl_interface_rec INDEX BY PLS_INTEGER;
--
  -- ���Y����f�[�^�X�V�L�[�i�[�p
  TYPE g_oe_order_lines_all_rec IS RECORD
    (
     header_id                 NUMBER    -- �󒍃w�b�_ID
    ,line_id                   NUMBER    -- �󒍖���ID
    );
  TYPE g_oe_order_lines_all_ttype IS TABLE OF g_oe_order_lines_all_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�v���C�x�[�g�ϐ�
  -- ===============================
--
  -- �L���x�����z���i�[�pPL/SQL�\
  g_gl_interface_tab                          g_gl_interface_ttype;
  -- ���Y����f�[�^�X�V�L�[�i�[�pPL/SQL�\
  g_oe_order_lines_all_tab                    g_oe_order_lines_all_ttype;
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
    -- 1.(1)  �p�����[�^�o��
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
    -- 2.(1)  �Ɩ��������t�A�v���t�@�C���l�̎擾
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
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.(2)  �v���t�@�C���l�̎擾
    --==============================================================
    -- �d��p�^�[���F�o�׎��ѕ\
    gv_je_ptn_shipment  := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_je_ptn_shipment IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application    => cv_appl_name_xxcfo      -- �A�v���P�[�V�����Z�k���FXXCFO
                    , iv_name           => cv_msg_cfo_00001        -- ���b�Z�[�W�FAPP-XXCFO-00001 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_prof_name        -- �g�[�N���FPROFILE_NAME
                    , iv_token_value1   => cv_profile_name_01
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO: �d��J�e�S��_�L���o��
    gv_je_category_mfg_fee_pay  := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_je_category_mfg_fee_pay IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application    => cv_appl_name_xxcfo      -- �A�v���P�[�V�����Z�k���FXXCFO
                    , iv_name           => cv_msg_cfo_00001        -- ���b�Z�[�W�FAPP-XXCFO-00001 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_prof_name        -- �g�[�N���FPROFILE_NAME
                    , iv_token_value1   => cv_profile_name_02
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2019/08/01 Ver1.6 Add Start
    -- MO: �c�ƒP��
    gn_org_id_sales  := TO_NUMBER(FND_PROFILE.VALUE( cv_profile_name_07 ));
    IF( gn_org_id_sales IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application    => cv_appl_name_xxcfo      -- �A�v���P�[�V�����Z�k���FXXCFO
                    , iv_name           => cv_msg_cfo_00001        -- ���b�Z�[�W�FAPP-XXCFO-00001 �v���t�@�C���擾�G���[
                    , iv_token_name1    => cv_tkn_prof_name        -- �g�[�N���FPROFILE_NAME
                    , iv_token_value1   => cv_profile_name_07
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2019/08/01 Ver1.6 Add End
    -- ���̓p�����[�^�̉�v���Ԃ���A���o�Ώۓ��tFROM-TO���Z�o
    gd_target_date_from  := TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format);
    gd_target_date_to    := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
    -- ���̓p�����[�^�̉�v���Ԃ���A�d��OIF�o�^�p�Ɋi�[
    gv_period_name       := iv_period_name;
    gd_target_date_last  := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format));
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
   * Procedure Name   : ins_gl_interface
   * Description      :�d��OIF�o�^(���������E�������ŁE�L���x���E�����(A-5,6))
   ***********************************************************************************/
  PROCEDURE ins_gl_interface(
    in_prc_mode         IN  NUMBER,                                                   --   1.�������[�h
    it_department_code  IN  xxwsh_order_headers_all.performance_management_dept%TYPE, --   2.����R�[�h
    it_item_class_code  IN  mtl_categories_b.segment1%TYPE,                           --   3.�i�ڋ敪
    -- 2015-01-22 Ver1.1 Mod Start
--    it_vendor_site_code IN  xxwsh_order_headers_all.vendor_site_code%TYPE,            --   4.�o�א�R�[�h
--    it_vendor_site_name IN  xxcmn_vendor_sites_all.vendor_site_short_name%TYPE,       --   5.�o�א於
    it_vendor_code      IN  po_vendors.segment1%TYPE,                                 --   4.�o�א�R�[�h
    it_vendor_name      IN  xxcmn_vendors.vendor_name%TYPE,                           --   5.�o�א於
    -- 2015-01-22 Ver1.1 Mod End
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'ins_gl_interface'; -- �v���O������
    cv_status_new        CONSTANT VARCHAR2(3)   := 'NEW';              -- �X�e�[�^�X
    cv_actual_flag       CONSTANT VARCHAR2(1)   := 'A';                -- �c���^�C�v
    cv_attribute2        CONSTANT VARCHAR2(1)   := '1';                -- �ېŔ���F����
-- 2015.11.18 Ver1.3 Add Start
    cv_item_prod_code_1      CONSTANT VARCHAR2(1)   := '1';            -- ���i�敪�F���[�t
    cv_item_prod_code_2      CONSTANT VARCHAR2(1)   := '2';            -- ���i�敪�F�h�����N
-- 2015.11.18 Ver1.3 Add End
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
    cn_group_id_1        CONSTANT NUMBER        := 1;
--
    -- *** ���[�J���ϐ� ***
    lv_company_code          VARCHAR2(100) DEFAULT NULL;                 -- ���
    lv_department_code       VARCHAR2(100) DEFAULT NULL;                 -- ����
    lv_account_title         VARCHAR2(100) DEFAULT NULL;                 -- ����Ȗ�
    lv_account_subsidiary    VARCHAR2(100) DEFAULT NULL;                 -- �⏕�Ȗ�
    lv_description           VARCHAR2(100) DEFAULT NULL;                 -- �E�v
    ln_ccid                  NUMBER        DEFAULT NULL;                 -- CCID
    lt_entered_dr            gl_interface.entered_dr%TYPE DEFAULT 0;     -- �ؕ����z
    lt_entered_cr            gl_interface.entered_cr%TYPE DEFAULT 0;     -- �ݕ����z
    lv_line_no               VARCHAR2(100) DEFAULT NULL;                 -- �s�ԍ�
    ln_cnt                   NUMBER        DEFAULT 0;                    -- �ŗ��J�E���g����
-- 2015.11.18 Ver1.3 Add Start
    lv_prod_class_code       VARCHAR2(1)   DEFAULT NULL;                 -- ���i�敪
-- 2015.11.18 Ver1.3 Add End
-- 2019/08/01 Ver1.6 Add Start
    lv_tax_code              VARCHAR2(100) DEFAULT NULL;                 -- �ŃR�[�h
-- 2019/08/01 Ver1.6 Add End
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
-- 2015.11.18 Ver1.3 Add Start
--
    -- ������
    lv_prod_class_code := NULL;
-- 2015.11.18 Ver1.3 Add End
--
    --�������[�h���u���������v�̏ꍇ
    IF in_prc_mode = 1 THEN 
      -- �s�ԍ���ݒ�
      lv_line_no := cv_line_no_01;
--
      -- �d��OIF�̃V�[�P���X���̔�
-- 2015.11.18 Ver1.3 Mod Start
--      SELECT TO_CHAR(xxcfo_gl_je_key_s1.NEXTVAL)
      SELECT TO_CHAR(xxcfo_gl_je_key_s1.NEXTVAL)  attribute8
-- 2015.11.18 Ver1.3 Mod End
      INTO   gt_attribute8
      FROM   DUAL;
--
    --�������[�h���u�������Łv�̏ꍇ
    ELSIF in_prc_mode = 2 THEN
      lv_line_no := cv_line_no_02;
--
    --�������[�h���u�L���x���v�̏ꍇ
    ELSIF in_prc_mode = 3 THEN
      lv_line_no := cv_line_no_03;
--
    --�������[�h���u������v�̏ꍇ
-- 2015.11.18 Ver1.3 Mod Start
--    ELSIF in_prc_mode = 4 THEN
    --�u���[�t�v�̏ꍇ
    ELSIF in_prc_mode = 41 THEN
      -- ���i�敪�F1
      lv_prod_class_code := cv_item_prod_code_1;
      -- �s�ԍ��F4
      lv_line_no         := cv_line_no_04;
--
    --�u�h�����N�v�̏ꍇ
    ELSIF in_prc_mode = 42 THEN
      -- ���i�敪�F2
      lv_prod_class_code := cv_item_prod_code_2;
      -- �s�ԍ��F4
-- 2015.11.18 Ver1.3 Mod End
      lv_line_no := cv_line_no_04;
    END IF;
--
    -- �L���x���d��̉Ȗڏ������ʊ֐��Ŏ擾
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_shipment               -- (IN)���[
      , iv_class_code               =>  it_item_class_code               -- (IN)�i�ڋ敪
-- 2015.11.18 Ver1.3 Mod Start
--      , iv_prod_class               =>  NULL                             -- (IN)���i�敪
      , iv_prod_class               =>  lv_prod_class_code               -- (IN)���i�敪
-- 2015.11.18 Ver1.3 Mod End
      , iv_reason_code              =>  NULL                             -- (IN)���R�R�[�h
      , iv_ptn_siwake               =>  cv_ptn_siwake_01                 -- (IN)�d��p�^�[�� �F1
      , iv_line_no                  =>  lv_line_no                       -- (IN)�s�ԍ� �F1�E2�E3�E4
      , iv_gloif_dr_cr              =>  NULL                             -- (IN)�ؕ��E�ݕ�
      , iv_warehouse_code           =>  NULL                             -- (IN)�q�ɃR�[�h
      , ov_company_code             =>  lv_company_code                  -- (OUT)���
      , ov_department_code          =>  lv_department_code               -- (OUT)����
      , ov_account_title            =>  lv_account_title                 -- (OUT)����Ȗ�
      , ov_account_subsidiary       =>  lv_account_subsidiary            -- (OUT)�⏕�Ȗ�
      , ov_description              =>  lv_description                   -- (OUT)�E�v
      , ov_retcode                  =>  lv_retcode                       -- ���^�[���R�[�h
      , ov_errbuf                   =>  lv_errbuf                        -- �G���[���b�Z�[�W
      , ov_errmsg                   =>  lv_errmsg                        -- ���[�U�[�E�G���[���b�Z�[�W
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --�������[�h���u�������Łv�ȊO�̏ꍇ
    IF in_prc_mode <> 2 THEN
      -- �L���x���d���CCID���擾
      ln_ccid := xxcok_common_pkg.get_code_combination_id_f(
                          id_proc_date => gd_target_date_last              -- ������
                        , iv_segment1  => lv_company_code                  -- ��ЃR�[�h
                        , iv_segment2  => lv_department_code               -- ����R�[�h
                        , iv_segment3  => lv_account_title                 -- ����ȖڃR�[�h
                        , iv_segment4  => lv_account_subsidiary            -- �⏕�ȖڃR�[�h
                        , iv_segment5  => gv_aff5_customer_dummy           -- �ڋq�R�[�h�_�~�[�l
                        , iv_segment6  => gv_aff6_company_dummy            -- ��ƃR�[�h�_�~�[�l
                        , iv_segment7  => gv_aff7_preliminary1_dummy       -- �\��1�_�~�[�l
                        , iv_segment8  => gv_aff8_preliminary2_dummy       -- �\��2�_�~�[�l
                        );
      IF ( ln_ccid IS NULL ) THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcfo
                        , iv_name         => cv_msg_cfo_10052            -- ����Ȗ�ID�iCCID�j�擾�G���[���b�Z�[�W
                        , iv_token_name1  => cv_tkn_process_date
                        , iv_token_value1 => gd_target_date_last         -- ������
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
    END IF;
--
    -- =================================================
    -- ����ŗ����ƂɁA �d��OIF�o�^���������[�v
    -- =================================================
    << insert_loop >>
    FOR ln_cnt IN 1..g_gl_interface_tab.COUNT LOOP
--
      -- ������
      lt_entered_dr    := 0;       -- �ؕ����z
      lt_entered_cr    := 0;       -- �ݕ����z
--
      -- ===============================
      -- �ŋ��}�X�^�����擾
      -- ===============================
      BEGIN
-- 2015.11.18 Ver1.3 Mod Start
--        SELECT atc.name                                -- �ŋ��R�[�h(�c��)
--              ,atc.tax_code_combination_id             -- ����Ŋ���CCID
        SELECT atc.name                        tax_code        -- �ŋ��R�[�h(�c��)
              ,atc.tax_code_combination_id     tax_ccid        -- ����Ŋ���CCID
-- 2015.11.18 Ver1.3 Mod End
        INTO   g_gl_interface_tab(ln_cnt).tax_code
              ,g_gl_interface_tab(ln_cnt).tax_ccid
        FROM   ap_tax_codes atc                                           -- AP�ŋ��R�[�h�}�X�^
        WHERE  atc.attribute2      = cv_attribute2                        -- �ېŏW�v�敪�F�ېŔ���(����)
-- 2019/08/01 Ver1.6 Mod Start
--        AND    atc.attribute4      = g_gl_interface_tab(ln_cnt).tax_rate  -- ���Y�ŗ�
        AND    atc.name            = g_gl_interface_tab(ln_cnt).tax_code    -- �ŃR�[�h
        AND    atc.org_id          = gn_org_id_sales                        -- �g�DID(�c��)
-- 2019/08/01 Ver1.6 Mod End
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg    := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcfo
                          , iv_name         => cv_msg_cfo_10035        -- �f�[�^�擾�G���[
                          , iv_token_name1  => cv_tkn_data
                          , iv_token_value1 => cv_msg_out_data_05      -- AP�ŋ��R�[�h�}�X�^
                          , iv_token_name2  => cv_tkn_item
-- 2019/08/01 Ver1.6 Mod Start
--                          , iv_token_value2 => cv_msg_out_item_03      -- ���Y�ŗ�
                          , iv_token_value2 => cv_msg_cfo_11155
-- 2019/08/01 Ver1.6 Mod End
                          , iv_token_name3  => cv_tkn_key
-- 2019/08/01 Ver1.6 Mod Start
--                          , iv_token_value3 => g_gl_interface_tab(ln_cnt).tax_rate
                          , iv_token_value3 => g_gl_interface_tab(ln_cnt).tax_code
-- 2019/08/01 Ver1.6 Mod End
                          );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      --�������[�h���u���������v�̏ꍇ
      IF in_prc_mode = 1 THEN 
        --���z���}�C�i�X�̏ꍇ�A�ݕ����z�́u���������v��ݒ�
        IF g_gl_interface_tab(ln_cnt).misyu_kin < 0 THEN
          lt_entered_cr   := ROUND(ABS(g_gl_interface_tab(ln_cnt).misyu_kin));
        ELSE
          lt_entered_dr   := ROUND(g_gl_interface_tab(ln_cnt).misyu_kin);
        END IF;
        --�ؕ��̓K�p��ێ�����
        gv_description_dr := lv_description;
-- 2019/08/01 Ver1.6 Add Start
        --�ŃR�[�h����x�ޔ�
        lv_tax_code := g_gl_interface_tab(ln_cnt).tax_code;
-- 2019/08/01 Ver1.6 Add End
-- 2017.12.05 Ver1.4 Add Start
        --�ŋ��R�[�h(�c��)��NULL��ݒ�
        g_gl_interface_tab(ln_cnt).tax_code := NULL;
-- 2017.12.05 Ver1.4 Add End
--
      --�������[�h���u�������Łv�̏ꍇ
      ELSIF in_prc_mode = 2 THEN
        --���z���}�C�i�X�̏ꍇ�A�ؕ����z�́u�������Łv��ݒ�
        IF g_gl_interface_tab(ln_cnt).tax_kin < 0 THEN
          lt_entered_dr   := ROUND(ABS(g_gl_interface_tab(ln_cnt).tax_kin));
        ELSE
          lt_entered_cr   := ROUND(g_gl_interface_tab(ln_cnt).tax_kin);
        END IF;
        -- �ŋ��}�X�^��CCID��ݒ�
        ln_ccid := g_gl_interface_tab(ln_cnt).tax_ccid;
--
      --�������[�h���u�L���x���v�̏ꍇ
      ELSIF in_prc_mode = 3 THEN
        --���z���}�C�i�X�̏ꍇ�A�ؕ����z�́u�L���x���v��ݒ�
        IF g_gl_interface_tab(ln_cnt).jitu_kin < 0 THEN
          lt_entered_dr   := ABS(g_gl_interface_tab(ln_cnt).jitu_kin);
        ELSE
          lt_entered_cr   := g_gl_interface_tab(ln_cnt).jitu_kin;
        END IF;
 --
      --�������[�h���u������v�̏ꍇ
-- 2015.11.18 Ver1.3 Mod Start
--      ELSIF in_prc_mode = 4 THEN
      ELSIF in_prc_mode IN (41, 42) THEN
-- 2015.11.18 Ver1.3 Mod End
        --���z���}�C�i�X�̏ꍇ�A�ؕ����z�́u������v��ݒ�
        IF g_gl_interface_tab(ln_cnt).kari_kin < 0 THEN
          lt_entered_dr   := ABS(g_gl_interface_tab(ln_cnt).kari_kin);
        ELSE
          lt_entered_cr   := g_gl_interface_tab(ln_cnt).kari_kin;
        END IF;
      END IF;
--
      --==============================================================
      -- �d��OIF�o�^(���������E�������ŁE�L���x���E�����(A-5,6))
      --==============================================================
--
      -- �ؕ��܂��͑ݕ��̋��z���u0�v�ȊO�̏ꍇ�A�d����쐬
      IF lt_entered_dr <> 0 OR lt_entered_cr <> 0 THEN
--
        BEGIN
          INSERT INTO gl_interface(
            status
           ,set_of_books_id
           ,accounting_date
           ,currency_code
           ,date_created
           ,created_by
           ,actual_flag
           ,user_je_category_name
           ,user_je_source_name
           ,code_combination_id
           ,entered_dr
           ,entered_cr
           ,reference1
           ,reference2
           ,reference4
           ,reference5
           ,reference10
           ,period_name
           ,request_id
           ,attribute1
           ,attribute3
           ,attribute4
           ,attribute5
           ,attribute8
           ,context
           ,group_id
          )VALUES (
            cv_status_new                   -- �X�e�[�^�X
           ,gn_sales_set_of_bks_id          -- ��v����ID
           ,gd_target_date_last             -- �L����
           ,gv_currency_code                -- �ʉ݃R�[�h
           ,SYSDATE                         -- �V�K�쐬��
           ,cn_created_by                   -- �V�K�쐬��
           ,cv_actual_flag                  -- �c���^�C�v
           ,gv_je_category_mfg_fee_pay      -- �d��J�e�S����
           ,gv_je_invoice_source_mfg        -- �d��\�[�X��
           ,ln_ccid                         -- CCID
           ,lt_entered_dr                   -- �ؕ����z
           ,lt_entered_cr                   -- �ݕ����z
           ,gv_je_category_mfg_fee_pay || '_' || gv_period_name
                                            -- �o�b�`��
           ,gv_je_category_mfg_fee_pay || '_' || gv_period_name
                                            -- �o�b�`�E�v
           ,gt_attribute8                   -- �d��
           -- 2015-01-22 Ver1.1 Mod Start
--           ,gv_description_dr || '_' || it_department_code || '_' || it_vendor_site_code || ' ' || it_vendor_site_name
           ,gv_description_dr || '_' || it_department_code || '_' || it_vendor_code || ' ' || it_vendor_name
                                            -- ���t�@�����X5�i�d�󖼓E�v�j
--           ,lv_description || it_vendor_site_code || it_vendor_site_name
           ,it_vendor_code || '_' || lv_description || '_' || it_vendor_name
           -- 2015-01-22 Ver1.1 Mod End
                                            -- ���t�@�����X10�i�d�󖾍דE�v�j
           ,gv_period_name                  -- ��v���Ԗ�
           ,cn_request_id                   -- �v��ID
           ,g_gl_interface_tab(ln_cnt).tax_code
                                            -- ����1�i����ŃR�[�h�j
           ,NULL                            -- ����3�i�`�[�ԍ��j
           ,it_department_code              -- ����4�i�N�[����j
           ,NULL                            -- ����5�i���[�UID�j
           ,gt_attribute8                   -- �Q�ƍ���1(�d��L�[)
           ,gv_sales_set_of_bks_name        -- �R���e�L�X�g
           ,cn_group_id_1
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_name_xxcfo
                            , iv_name         => cv_msg_cfo_00024              -- �o�^�G���[���b�Z�[�W
                            , iv_token_name1  => cv_tkn_table
                            , iv_token_value1 => cv_msg_out_data_01            -- �d��OIF
                            , iv_token_name2  => cv_tkn_errmsg
                            , iv_token_value2 => SQLERRM                       -- SQL�G���[
                            );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
--
      END IF;
--
-- 2019/08/01 Ver1.6 Add Start
      --�������[�h�u���������v��NULL�ɂ����ŃR�[�h�����ɖ߂�
      IF ( g_gl_interface_tab(ln_cnt).tax_code IS NULL ) THEN
        g_gl_interface_tab(ln_cnt).tax_code := lv_tax_code;
      END IF;
--
-- 2019/08/01 Ver1.6 Add End
    END LOOP insert_loop;
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
  END ins_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : upd_inv_trn_data
   * Description      : ���Y����f�[�^�X�V(A-7)
   ***********************************************************************************/
  PROCEDURE upd_inv_trn_data(
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
    ln_upd_cnt      NUMBER;
    lt_header_id    oe_order_lines_all.header_id%TYPE;
    lt_line_id      oe_order_lines_all.line_id%TYPE;
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
    -- �󒍖��ׂɕR�t���L�[�̒l��ݒ�i�d��L�[�j
    -- =========================================================
    << lock_loop >>
    FOR ln_upd_cnt IN 1..g_oe_order_lines_all_tab.COUNT LOOP
      BEGIN
        -- �󒍖��ׂɑ΂��čs���b�N���擾
-- 2015.11.18 Ver1.3 Mod Start
--        SELECT oola.header_id,oola.line_id
        SELECT oola.header_id   header_id
              ,oola.line_id     line_id
-- 2015.11.18 Ver1.3 Mod End
        INTO   lt_header_id,lt_line_id
        FROM   oe_order_lines_all oola
        WHERE  oola.header_id      = g_oe_order_lines_all_tab(ln_upd_cnt).header_id
        AND    oola.line_id        = g_oe_order_lines_all_tab(ln_upd_cnt).line_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcfo                  -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_00019                    -- ���b�N�G���[
                    , iv_token_name1  => cv_tkn_table                        -- �e�[�u��
                    , iv_token_value1 => cv_msg_out_data_02                  -- �󒍖���
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
    END LOOP lock_loop;
--
    BEGIN
      FORALL ln_upd_cnt IN 1..g_oe_order_lines_all_tab.COUNT
        -- ����f�[�^�����ʂ����ӂȒl���󒍖��ׂɍX�V
        UPDATE oe_order_lines_all oola
        SET    oola.attribute4     = gt_attribute8                  -- �u�d��OIF�o�^�v�ō̔Ԃ����Q�ƍ���1 (�d��L�[)
        WHERE  oola.header_id      = g_oe_order_lines_all_tab(ln_upd_cnt).header_id
        AND    oola.line_id        = g_oe_order_lines_all_tab(ln_upd_cnt).line_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcfo                  -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_10042
                  , iv_token_name1  => cv_tkn_data                         -- �f�[�^
                  , iv_token_value1 => cv_msg_out_data_02                  -- �󒍖���
                  , iv_token_name2  => cv_tkn_item                         -- �A�C�e��
                  , iv_token_value2 => cv_msg_out_item_01                  -- �󒍃w�b�_ID,�󒍖���ID
                  , iv_token_name3  => cv_tkn_key                          -- �L�[
                  , iv_token_value3 => g_oe_order_lines_all_tab(ln_upd_cnt).header_id || ',' || g_oe_order_lines_all_tab(ln_upd_cnt).line_id
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- ���팏���J�E���g
    gn_normal_cnt := gn_normal_cnt + g_oe_order_lines_all_tab.COUNT;
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
   * Procedure Name   : get_gl_interface_data
   * Description      : �d��OIF��񒊏o(A-3,4)
   ***********************************************************************************/
  PROCEDURE get_gl_interface_data(
    iv_period_name      IN  VARCHAR2,      -- 1.��v����
    ov_errbuf           OUT VARCHAR2,      -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,      -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_interface_data'; -- �v���O������
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
    cn_prc_mode1             CONSTANT NUMBER        := 1;                -- �������[�h�i���������j
    cn_prc_mode2             CONSTANT NUMBER        := 2;                -- �������[�h�i�������Łj
    cn_prc_mode3             CONSTANT NUMBER        := 3;                -- �������[�h�i�L���x���j
-- 2015.11.18 Ver1.3 Mod Start
--    cn_prc_mode4             CONSTANT NUMBER        := 4;                -- �������[�h�i������j
    cn_prc_mode41            CONSTANT NUMBER        := 41;               -- �������[�h�i������i���[�t�j�j
    cn_prc_mode42            CONSTANT NUMBER        := 42;               -- �������[�h�i������i�h�����N�j�j
-- 2015.11.18 Ver1.3 Mod End
    cn_completed_ind         CONSTANT NUMBER        := 1;                -- �����t���O
    cv_doc_type_porc         CONSTANT VARCHAR2(30)  := 'PORC';           -- �w���֘A
    cv_doc_type_omso         CONSTANT VARCHAR2(30)  := 'OMSO';           -- �󒍊֘A
    cv_source_document_code  CONSTANT VARCHAR2(30)  := 'RMA';            -- RMA
    cv_req_status            CONSTANT VARCHAR2(2)   := '08';             -- �o�׈˗��X�e�[�^�X�F�o�׎��ьv���
    cv_document_type_code    CONSTANT VARCHAR2(2)   := '30';             -- �����^�C�v�F�x���˗�
    cv_rec_type_stck         CONSTANT VARCHAR2(2)   := '20';             -- ���R�[�h�^�C�v�F�o�Ɏ���
    cv_shikyu_class          CONSTANT VARCHAR2(1)   := '2';              -- �o�׎x���敪�F�x��
    cv_zaiko_class           CONSTANT VARCHAR2(1)   := '1';              -- �݌ɒ����敪�F1�i���݌ɒ����j
    cv_item_class_code_1     CONSTANT VARCHAR2(1)   := '1';              -- �i�ڋ敪�F����
    cv_item_class_code_2     CONSTANT VARCHAR2(1)   := '2';              -- �i�ڋ敪�F����
    cv_item_class_code_4     CONSTANT VARCHAR2(1)   := '4';              -- �i�ڋ敪�F�����i
    cv_item_class_code_5     CONSTANT VARCHAR2(1)   := '5';              -- �i�ڋ敪�F���i
    cv_item_prod_code_1      CONSTANT VARCHAR2(1)   := '1';              -- ���i�敪�F���[�t
    cv_item_prod_code_2      CONSTANT VARCHAR2(1)   := '2';              -- ���i�敪�F�h�����N
    cv_dealings_div_1        CONSTANT VARCHAR2(3)   := '103';            -- ����敪�F�L��
    cv_dealings_div_2        CONSTANT VARCHAR2(3)   := '105';            -- ����敪�F�U�֗L��
    cv_dealings_div_3        CONSTANT VARCHAR2(3)   := '108';            -- ����敪�F���i�U�֗L��
--
    -- *** ���[�J���ϐ� ***
    ln_count                 NUMBER        DEFAULT 0;                                  -- ���o�����̃J�E���g
    ln_tax_cnt               NUMBER        DEFAULT 0;                                  -- �ŗ��J�E���g�i�ŗ��̎�ސ��j
    ln_out_count             NUMBER        DEFAULT 0;                                  -- ����u���[�N�L�[�����̃J�E���g
-- 2019/08/01 Ver1.6 Del Start
--    ln_tax_rate_jdge         NUMBER        DEFAULT 0;                                  -- ����ŗ�(����p)
-- 2019/08/01 Ver1.6 Del End
-- 2015.11.18 Ver1.3 Add Start
    ln_kari_kin_1            NUMBER        DEFAULT 0;                                  -- ������i���[�t�j
    ln_kari_kin_2            NUMBER        DEFAULT 0;                                  -- ������i�h�����N�j
-- 2015.11.18 Ver1.3 Add End
    ld_opminv_date           DATE          DEFAULT NULL;                               -- OPM�݌ɉ�v���Ԃ̏I����
    lt_department_code       xxwsh_order_headers_all.performance_management_dept%TYPE; -- �d��P�ʁF����R�[�h
    lt_item_class_code       mtl_categories_b.segment1%TYPE;                           -- �d��P�ʁF�i�ڋ敪
    -- 2015-01-22 Ver1.1 Mod Start
--    lt_vendor_site_code      xxwsh_order_headers_all.vendor_site_code%TYPE;            -- �d��P�ʁF�o�א�R�[�h
--    lt_vendor_site_name      xxcmn_vendor_sites_all.vendor_site_short_name%TYPE;       -- �d��P�ʁF�o�א於
    lt_vendor_code           po_vendors.segment1%TYPE;                                 -- �d��P�ʁF�o�א�R�[�h
    lt_vendor_name           xxcmn_vendors.vendor_name%TYPE;                           -- �d��P�ʁF�o�א於
    -- 2015-01-22 Ver1.1 Mod End
    lt_vendor_site_id        xxwsh_order_headers_all.vendor_site_id%TYPE;              -- �d��P�ʁF�o�א�ID
    -- 2015-02-18 Ver1.2 #44 Add Start
    lt_vendor_id             xxwsh_order_headers_all.vendor_id%TYPE;                    -- �d��P�ʁF�d����ID
-- 2019/08/01 Ver1.6 Add Start
    lt_tax_code              VARCHAR2(10);                                              -- �ŃR�[�h
-- 2019/08/01 Ver1.6 Add End
    -- 2015-02-18 Ver1.2 #44 Add End
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- ���o�J�[�\���iSELECT���@�`�G��UNION ALL�j
    CURSOR get_gl_interface_cur
    IS
-- 2019/08/01 Ver1.6 Mod Start
--      SELECT
      SELECT /*+ PUSH_PRED(xitrv) */
-- 2019/08/01 Ver1.6 Mod End
             ROUND((CASE trn.attribute15
                       WHEN '1' THEN trn.stnd_unit_price
                       ELSE DECODE(trn.lot_ctl
                                  ,1,trn.unit_ploce
                                  ,trn.stnd_unit_price)
                     END) * trn.trans_qty
             )                                                      AS jitu_kin                     --�L���x��
            ,(ROUND(trn.UNIT_PRICE * trn.trans_qty)
              - ROUND((CASE trn.attribute15
                        WHEN '1' THEN trn.stnd_unit_price
                        ELSE DECODE(trn.lot_ctl
                                   ,1,trn.unit_ploce
                                   ,trn.stnd_unit_price)
                      END) * trn.trans_qty
             ))                                                     AS kari_kin                     --�����
             -- 2015-02-18 Ver1.2 #46 Mod Start
--            ,((trn.UNIT_PRICE * trn.trans_qty)
            ,ROUND((trn.UNIT_PRICE * trn.trans_qty)
             -- 2015-02-18 Ver1.2 #46 Mod End
-- 2019/08/01 Ver1.6 Mod Start
--              * DECODE( NVL(TO_NUMBER(trn.tax_rate),0),0,0,(TO_NUMBER(trn.tax_rate)/100) )
              * DECODE( NVL(TO_NUMBER(xitrv.tax),0),0,0,(TO_NUMBER(xitrv.tax)/100) )
-- 2019/08/01 Ver1.6 Mod End
             )                                                      AS tax_kin                      --��������
-- 2019/08/01 Ver1.6 Mod Start
--            ,trn.tax_rate                                           AS tax_rate                     --�ŗ�
            ,xitrv.tax_code_sales_ex                                AS tax_code                     --�ŃR�[�h
-- 2019/08/01 Ver1.6 Mod End
            ,trn.department_code                                    AS department_code              --����
            ,trn.vendor_site_id                                     AS vendor_site_id               --�o�א�ID
            ,trn.vendor_site_code                                   AS vendor_site_code             --�o�א�
            ,trn.item_class_code                                    AS item_class_code              --�i�ڋ敪
            ,trn.header_id                                          AS header_id                    --�󒍃w�b�_ID
            ,trn.line_id                                            AS line_id                      --�󒍖���ID
             -- 2015-02-18 Ver1.2 #44 Add Start
            ,trn.vendor_id                                          AS vendor_id                    --�d����ID
             -- 2015-02-18 Ver1.2 #44 Add End
-- 2015.11.18 Ver1.3 Add Start
            ,trn.prod_class_code                                    AS prod_class_code              -- ���i�敪
-- 2015.11.18 Ver1.3 Add End
      FROM(
          --�@�x���˗��E�d���L��(�����E���ށE�����i)
-- 2019/08/01 Ver1.6 Mod Start
--          SELECT /*+ LEADING(flv xoha ooha otta xola wdd itp xrpm iimb gic mcb xmld oola ilm xlc) 
          SELECT /*+ LEADING(    xoha ooha otta xola wdd itp xrpm iimb gic mcb xmld oola ilm xlc) 
-- 2019/08/01 Ver1.6 Mod End
                     USE_NL (    xoha ooha otta xola wdd itp xrpm iimb gic mcb xmld oola ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
-- 2015.11.18 Ver1.3 Mod Start
--               ,(select nvl(xsup.stnd_unit_price, 0)
--                 from   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
--                 where  iimb.item_id      = xsup.item_id(+)
--                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
               ,(SELECT nvl(xsup.stnd_unit_price, 0)  stnd_unit_price
                 FROM   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
                 WHERE  iimb.item_id      = xsup.item_id(+)
                 AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
-- 2015.11.18 Ver1.3 Mod End
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
-- 2019/08/01 Ver1.6 Mod Start
--               ,flv.lookup_code                                                                   AS tax_rate
               ,itp.item_id                                                                       AS item_id
-- 2020/05/27 Ver1.7 Mod Start
--               ,xoha.arrival_date                                                                 AS target_date
               ,NVL( xoha.sikyu_return_date,xoha.arrival_date )                                   AS target_date
-- 2020/05/27 Ver1.7 Mod End
-- 2019/08/01 Ver1.6 Mod End
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
                -- 2015-02-18 Ver1.2 #44 Add Start
               ,xoha.vendor_id                                                                    AS vendor_id
                -- 2015-02-18 Ver1.2 #44 Add End
-- 2015.11.18 Ver1.3 Add Start
               ,xicv.prod_class_code                                                              AS prod_class_code
-- 2015.11.18 Ver1.3 Add End
          FROM  oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
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
-- 2019/08/01 Ver1.6 Del Start
--               ,fnd_lookup_values           flv                      --lookup�\
-- 2019/08/01 Ver1.6 Del End
               ,gmi_item_categories         gic                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb                      --�i�ڃJ�e�S���}�X�^
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --�ŐV�t���O�FY
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --���׍폜�t���O�FN
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --�����^�C�v�F�x���˗�
          AND    xmld.record_type_code             = cv_rec_type_stck           --���R�[�h�^�C�v�F�o�Ɏ���
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    otta.attribute4                   = cv_zaiko_class             --�݌ɒ����敪�F1�i���݌ɒ����j
          AND    wdd.source_header_id              = xola.header_id
          AND    wdd.source_line_id                = xola.line_id
          AND    itp.line_detail_id                = wdd.delivery_detail_id
          AND    itp.doc_type                      = cv_doc_type_omso           --�󒍊֘A
          AND    itp.completed_ind                 = cn_completed_ind           --�����t���O�F�ŐV
          AND    gic.item_id                       = itp.item_id
          AND    gic.category_set_id               = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic.category_id                   = mcb.category_id
          AND    mcb.segment1                      in (cv_item_class_code_1,cv_item_class_code_2,cv_item_class_code_4) --�i�ڋ敪�F�����E���ޥ�����i
          AND    xrpm.item_div_origin              IS NULL
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.dealings_div                 = cv_dealings_div_1          --����敪�F�L��
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          AND    xola.shipping_item_code           = xola.request_item_code
          AND    xicv.item_id                      = iimb.item_id
-- 2019/08/01 Ver1.6 Del Start
--          AND    flv.lookup_type                   = cv_profile_name_03
--          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
---- 2015.11.18 Ver1.3 Mod Start
----                                                   AND     flv.end_date_active
--                                                   AND     NVL(flv.end_date_active, xoha.arrival_date)
---- 2015.11.18 Ver1.3 Mod End
--          AND    flv.language                      = cv_lang
-- 2019/08/01 Ver1.6 Del End
          UNION ALL
          --�A�x���ԕi(�����E���ށE�����i)
-- 2019/08/01 Ver1.6 Mod Start
--          SELECT /*+ LEADING(flv xoha ooha otta xola rsl itp gic mcb iimb xrpm xmld oola ilm xlc) 
          SELECT /*+ LEADING(    xoha ooha otta xola rsl itp gic mcb iimb xrpm xmld oola ilm xlc) 
-- 2019/08/01 Ver1.6 Mod End
                     USE_NL (    xoha ooha otta xola rsl itp gic mcb iimb xrpm xmld oola ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
-- 2015.11.18 Ver1.3 Mod Start
--               ,(select nvl(xsup.stnd_unit_price, 0)
--                 from   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
--                 where  iimb.item_id      = xsup.item_id(+)
--                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
               ,(SELECT nvl(xsup.stnd_unit_price, 0)  stnd_unit_price
                 FROM   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
                 WHERE  iimb.item_id      = xsup.item_id(+)
                 AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
-- 2015.11.18 Ver1.3 Mod End
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
-- 2019/08/01 Ver1.6 Mod Start
--               ,flv.lookup_code                                                                   AS tax_rate
               ,itp.item_id                                                                       AS item_id
               ,xoha.sikyu_return_date                                                            AS target_date
-- 2019/08/01 Ver1.6 Mod End
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
                -- 2015-02-18 Ver1.2 #44 Add Start
               ,xoha.vendor_id                                                                    AS vendor_id
                -- 2015-02-18 Ver1.2 #44 Add End
-- 2015.11.18 Ver1.3 Add Start
               ,xicv.prod_class_code                                                              AS prod_class_code
-- 2015.11.18 Ver1.3 Add End
          FROM  oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
               ,oe_order_lines_all          oola                     --�󒍖���(�W��)
               ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
               ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
               ,oe_transaction_types_all    otta                     --�󒍃^�C�v
               ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
               ,rcv_shipment_lines          rsl                      --�������
               ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
               ,ic_item_mst_b               iimb                     --OPM�i�ڃ}�X�^
               ,xxcmn_item_categories5_v    xicv                     --OPM�i�ڃJ�e�S���������View5
               ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
               ,xxcmn_lot_cost              xlc                      --���b�g�ʌ����A�h�I��
               ,xxcmn_rcv_pay_mst           xrpm                     --�󕥋敪�A�h�I���}�X�^
-- 2019/08/01 Ver1.6 Del Start
--               ,fnd_lookup_values           flv                      --lookup�\
-- 2019/08/01 Ver1.6 Del End
               ,gmi_item_categories         gic                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb                      --�i�ڃJ�e�S���}�X�^
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --�ŐV�t���O�FY
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --���׍폜�t���O�FN
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --�����^�C�v�F�x���˗�
          AND    xmld.record_type_code             = cv_rec_type_stck           --���R�[�h�^�C�v�F�o�Ɏ���
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    otta.attribute4                   = cv_zaiko_class             --�݌ɒ����敪�F1�i���݌ɒ����j
          AND    rsl.oe_order_header_id            = xola.header_id
          AND    rsl.oe_order_line_id              = xola.line_id
          AND    itp.doc_id                        = rsl.shipment_header_id
          AND    itp.doc_line                      = rsl.line_num
          AND    itp.doc_type                      = cv_doc_type_porc           --�w���֘A
          AND    itp.completed_ind                 = cn_completed_ind           --�����t���O
          AND    gic.item_id                       = itp.item_id
          AND    gic.category_set_id               = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic.category_id                   = mcb.category_id
          AND    mcb.segment1                      in (cv_item_class_code_1,cv_item_class_code_2,cv_item_class_code_4) --�i�ڋ敪�F�����E���ޥ�����i
          AND    xrpm.item_div_origin              IS NULL
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.source_document_code         = cv_source_document_code    --RMA
          AND    xrpm.dealings_div                 = cv_dealings_div_1          --����敪�F�L��
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          AND    xola.shipping_item_code           = xola.request_item_code
          AND    xicv.item_id                      = iimb.item_id
-- 2019/08/01 Ver1.6 Del Start
--          AND    flv.lookup_type                   = cv_profile_name_03
--          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
---- 2015.11.18 Ver1.3 Mod Start
----                                                   AND     flv.end_date_active
--                                                   AND     NVL(flv.end_date_active, xoha.arrival_date)
---- 2015.11.18 Ver1.3 Mod End
--          AND    flv.language                      = cv_lang
-- 2019/08/01 Ver1.6 Del End
          UNION ALL
          --�B�x���˗��E�d���L��(���i)
-- 2019/08/01 Ver1.6 Mod Start
--          SELECT /*+ LEADING(flv xoha ooha otta xola wdd itp xrpm xmld oola gic mcb iimb ilm xlc) 
          SELECT /*+ LEADING(    xoha ooha otta xola wdd itp xrpm xmld oola gic mcb iimb ilm xlc) 
-- 2019/08/01 Ver1.6 Mod End
                     USE_NL (    xoha ooha otta xola wdd itp xrpm xmld oola gic mcb iimb ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
-- 2015.11.18 Ver1.3 Mod Start
--               ,(select nvl(xsup.stnd_unit_price, 0)
--                 from   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
--                 where  iimb.item_id      = xsup.item_id(+)
--                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
               ,(SELECT nvl(xsup.stnd_unit_price, 0)  stnd_unit_price
                 FROM   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
                 WHERE  iimb.item_id      = xsup.item_id(+)
                 AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
-- 2015.11.18 Ver1.3 Mod End
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
-- 2019/08/01 Ver1.6 Mod Start
--               ,flv.lookup_code                                                                   AS tax_rate
               ,itp.item_id                                                                       AS item_id
-- 2020/05/27 Ver1.7 Mod Start
--               ,xoha.arrival_date                                                                 AS target_date
               ,NVL( xoha.sikyu_return_date,xoha.arrival_date )                                   AS target_date
-- 2020/05/27 Ver1.7 Mod End
-- 2019/08/01 Ver1.6 Mod End
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
                -- 2015-02-18 Ver1.2 #44 Add Start
               ,xoha.vendor_id                                                                    AS vendor_id
                -- 2015-02-18 Ver1.2 #44 Add End
-- 2015.11.18 Ver1.3 Add Start
               ,xicv.prod_class_code                                                              AS prod_class_code
-- 2015.11.18 Ver1.3 Add End
          FROM  oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
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
-- 2019/08/01 Ver1.6 Del Start
--               ,fnd_lookup_values           flv                      --lookup�\
-- 2019/08/01 Ver1.6 Del End
               ,gmi_item_categories         gic                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb                      --�i�ڃJ�e�S���}�X�^
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --�ŐV�t���O�FY
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --���׍폜�t���O�FN
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --�����^�C�v�F�x���˗�
          AND    xmld.record_type_code             = cv_rec_type_stck           --���R�[�h�^�C�v�F�o�Ɏ���
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    otta.attribute4                   = cv_zaiko_class             --�݌ɒ����敪�F1�i���݌ɒ����j
          AND    wdd.source_header_id              = xola.header_id
          AND    wdd.source_line_id                = xola.line_id
          AND    itp.line_detail_id                = wdd.delivery_detail_id
          AND    itp.doc_type                      = cv_doc_type_omso           --�󒍊֘A
          AND    itp.completed_ind                 = cn_completed_ind           --�����t���O�F�ŐV
          AND    gic.item_id                       = itp.item_id
          AND    gic.category_set_id               = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic.category_id                   = mcb.category_id
          AND    mcb.segment1                      = cv_item_class_code_5       --�i�ڋ敪�F���i
          AND    xrpm.item_div_origin              = mcb.segment1
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.dealings_div                 = cv_dealings_div_1          --����敪�F�L��
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          AND    xola.shipping_item_code           = xola.request_item_code
          AND    xicv.item_id                      = iimb.item_id
-- 2019/08/01 Ver1.6 Del Start
--          AND    flv.lookup_type                   = cv_profile_name_03
--          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
---- 2015.11.18 Ver1.3 Mod Start
----                                                   AND     flv.end_date_active
--                                                   AND     NVL(flv.end_date_active, xoha.arrival_date)
---- 2015.11.18 Ver1.3 Mod End
--          AND    flv.language                      = cv_lang
-- 2019/08/01 Ver1.6 Del End
          UNION ALL
          --�C�x���ԕi(���i)
-- 2019/08/01 Ver1.6 Mod Start
--          SELECT /*+ LEADING(flv xoha ooha otta xola rsl itp xrpm xmld oola gic mcb iimb ilm xlc) 
          SELECT /*+ LEADING(    xoha ooha otta xola rsl itp xrpm xmld oola gic mcb iimb ilm xlc) 
-- 2019/08/01 Ver1.6 Mod End
                     USE_NL (    xoha ooha otta xola rsl itp xrpm xmld oola gic mcb iimb ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
-- 2015.11.18 Ver1.3 Mod Start
--               ,(select nvl(xsup.stnd_unit_price, 0)
--                 from   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
--                 where  iimb.item_id      = xsup.item_id(+)
--                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
               ,(SELECT nvl(xsup.stnd_unit_price, 0)  stnd_unit_price
                 FROM   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
                 WHERE  iimb.item_id      = xsup.item_id(+)
                 AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
-- 2015.11.18 Ver1.3 Mod End
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
-- 2019/08/01 Ver1.6 Mod Start
--               ,flv.lookup_code                                                                   AS tax_rate
               ,itp.item_id                                                                       AS item_id
               ,xoha.sikyu_return_date                                                            AS target_date
-- 2019/08/01 Ver1.6 Mod End
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
                -- 2015-02-18 Ver1.2 #44 Add Start
               ,xoha.vendor_id                                                                    AS vendor_id
                -- 2015-02-18 Ver1.2 #44 Add End
-- 2015.11.18 Ver1.3 Add Start
               ,xicv.prod_class_code                                                              AS prod_class_code
-- 2015.11.18 Ver1.3 Add End
          FROM  oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
               ,oe_order_lines_all          oola                     --�󒍖���(�W��)
               ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
               ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
               ,oe_transaction_types_all    otta                     --�󒍃^�C�v
               ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
               ,rcv_shipment_lines          rsl                      --�������
               ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
               ,ic_item_mst_b               iimb                     --OPM�i�ڃ}�X�^
               ,xxcmn_item_categories5_v    xicv                     --OPM�i�ڃJ�e�S���������View5
               ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
               ,xxcmn_lot_cost              xlc                      --���b�g�ʌ����A�h�I��
               ,xxcmn_rcv_pay_mst           xrpm                     --�󕥋敪�A�h�I���}�X�^
-- 2019/08/01 Ver1.6 Del Start
--               ,fnd_lookup_values           flv                      --lookup�\
-- 2019/08/01 Ver1.6 Del End
               ,gmi_item_categories         gic                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb                      --�i�ڃJ�e�S���}�X�^
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --�ŐV�t���O�FY
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --���׍폜�t���O�FN
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --�����^�C�v�F�x���˗�
          AND    xmld.record_type_code             = cv_rec_type_stck           --���R�[�h�^�C�v�F�o�Ɏ���
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    otta.attribute4                   = cv_zaiko_class             --�݌ɒ����敪�F1�i���݌ɒ����j
          AND    rsl.oe_order_header_id            = xola.header_id
          AND    rsl.oe_order_line_id              = xola.line_id
          AND    itp.doc_id                        = rsl.shipment_header_id
          AND    itp.doc_line                      = rsl.line_num
          AND    itp.doc_type                      = cv_doc_type_porc           --�w���֘A
          AND    itp.completed_ind                 = cn_completed_ind           --�����t���O
          AND    gic.item_id                       = itp.item_id
          AND    gic.category_set_id               = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic.category_id                   = mcb.category_id
          AND    mcb.segment1                      = cv_item_class_code_5       --�i�ڋ敪�F���i
          AND    xrpm.item_div_origin              = mcb.segment1
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.source_document_code         = cv_source_document_code    --RMA
          AND    xrpm.dealings_div                 = cv_dealings_div_1          --����敪�F�L��
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          AND    xola.shipping_item_code           = xola.request_item_code
          AND    xicv.item_id                      = iimb.item_id
-- 2019/08/01 Ver1.6 Del Start
--          AND    flv.lookup_type                   = cv_profile_name_03
--          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
---- 2015.11.18 Ver1.3 Mod Start
----                                                   AND     flv.end_date_active
--                                                   AND     NVL(flv.end_date_active, xoha.arrival_date)
---- 2015.11.18 Ver1.3 Mod End
--          AND    flv.language                      = cv_lang
-- 2019/08/01 Ver1.6 Del End
          UNION ALL
          --�D�x���˗��E�d���L��(�U�֗L��)
-- 2019/08/01 Ver1.6 Mod Start
--          SELECT /*+ LEADING(flv xoha ooha otta xola iimb gic1 mcb1 wdd itp xrpm gic2 mcb2 xmld oola ilm xlc) 
          SELECT /*+ LEADING(    xoha ooha otta xola iimb gic1 mcb1 wdd itp xrpm gic2 mcb2 xmld oola ilm xlc) 
-- 2019/08/01 Ver1.6 Mod End
                     USE_NL (    xoha ooha otta xola iimb gic1 mcb1 wdd itp xrpm gic2 mcb2 xmld oola ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
-- 2015.11.18 Ver1.3 Mod Start
--               ,(select nvl(xsup.stnd_unit_price, 0)
--                 from   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
--                 where  iimb.item_id      = xsup.item_id(+)
--                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
               ,(SELECT nvl(xsup.stnd_unit_price, 0)  stnd_unit_price
                 FROM   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
                 WHERE  iimb.item_id      = xsup.item_id(+)
                 AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
-- 2015.11.18 Ver1.3 Mod End
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
-- 2019/08/01 Ver1.6 Mod Start
--               ,flv.lookup_code                                                                   AS tax_rate
               ,itp.item_id                                                                       AS item_id
-- 2020/05/27 Ver1.7 Mod Start
--               ,xoha.arrival_date                                                                 AS target_date
               ,NVL( xoha.sikyu_return_date,xoha.arrival_date )                                   AS target_date
-- 2020/05/27 Ver1.7 Mod End
-- 2019/08/01 Ver1.6 Mod End
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
                -- 2015-02-18 Ver1.2 #44 Add Start
               ,xoha.vendor_id                                                                    AS vendor_id
                -- 2015-02-18 Ver1.2 #44 Add End
-- 2015.11.18 Ver1.3 Add Start
               ,xicv.prod_class_code                                                              AS prod_class_code
-- 2015.11.18 Ver1.3 Add End
          FROM  oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
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
-- 2019/08/01 Ver1.6 Del Start
--               ,fnd_lookup_values           flv                      --lookup�\
-- 2019/08/01 Ver1.6 Del End
               ,gmi_item_categories         gic1                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb1                      --�i�ڃJ�e�S���}�X�^
               ,gmi_item_categories         gic2                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb2                      --�i�ڃJ�e�S���}�X�^
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --�ŐV�t���O�FY
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --���׍폜�t���O�FN
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --�����^�C�v�F�x���˗�
          AND    xmld.record_type_code             = cv_rec_type_stck           --���R�[�h�^�C�v�F�o�Ɏ���
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    otta.attribute4                   = cv_zaiko_class             --�݌ɒ����敪�F1�i���݌ɒ����j
          AND    wdd.source_header_id              = xola.header_id
          AND    wdd.source_line_id                = xola.line_id
          AND    itp.line_detail_id                = wdd.delivery_detail_id
          AND    itp.doc_type                      = cv_doc_type_omso           --�󒍊֘A
          AND    itp.completed_ind                 = cn_completed_ind           --�����t���O�F�ŐV
          AND    gic1.item_id                      = iimb.item_id
          AND    gic1.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic1.category_id                  = mcb1.category_id
          AND    mcb1.segment1                     = cv_item_class_code_5       --�i�ڋ敪�F���i
          AND    xrpm.item_div_ahead               = mcb1.segment1
          AND    gic2.item_id                      = itp.item_id 
          AND    gic2.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic2.category_id                  = mcb2.category_id
          AND    mcb2.segment1                     IN (cv_item_class_code_1,cv_item_class_code_2,cv_item_class_code_4) --�i�ڋ敪�F�����E���ޥ�����i
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.dealings_div                 = cv_dealings_div_2          --����敪�F�U�֗L��
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          -- 2015-01-22 Ver1.1 Mod Start
--          AND    xicv.item_no                      = xola.shipping_item_code
          AND    xicv.item_id                      = iimb.item_id
          -- 2015-01-22 Ver1.1 Mod End
-- 2019/08/01 Ver1.6 Del Start
--          AND    flv.lookup_type                   = cv_profile_name_03
--          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
---- 2015.11.18 Ver1.3 Mod Start
----                                                   AND     flv.end_date_active
--                                                   AND     NVL(flv.end_date_active, xoha.arrival_date)
---- 2015.11.18 Ver1.3 Mod End
--          AND    flv.language                      = cv_lang
-- 2019/08/01 Ver1.6 Del End
          UNION ALL
          --�E�x���ԕi(�U�֗L��)
-- 2019/08/01 Ver1.6 Mod Start
--          SELECT /*+ LEADING(flv xoha ooha otta xola iimb gic1 mcb1 rsl itp xrpm gic2 mcb2 xmld oola ilm xlc) 
          SELECT /*+ LEADING(    xoha ooha otta xola iimb gic1 mcb1 rsl itp xrpm gic2 mcb2 xmld oola ilm xlc) 
-- 2019/08/01 Ver1.6 Mod End
                     USE_NL (    xoha ooha otta xola iimb gic1 mcb1 rsl itp xrpm gic2 mcb2 xmld oola ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
-- 2015.11.18 Ver1.3 Mod Start
--               ,(select nvl(xsup.stnd_unit_price, 0)
--                 from   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
--                 where  iimb.item_id      = xsup.item_id(+)
--                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
               ,(SELECT nvl(xsup.stnd_unit_price, 0)  stnd_unit_price
                 FROM   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
                 WHERE  iimb.item_id      = xsup.item_id(+)
                 AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
-- 2015.11.18 Ver1.3 Mod End
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
-- 2019/08/01 Ver1.6 Mod Start
--               ,flv.lookup_code                                                                   AS tax_rate
               ,itp.item_id                                                                       AS item_id
               ,xoha.sikyu_return_date                                                            AS target_date
-- 2019/08/01 Ver1.6 Mod End
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
                -- 2015-02-18 Ver1.2 #44 Add Start
               ,xoha.vendor_id                                                                    AS vendor_id
                -- 2015-02-18 Ver1.2 #44 Add End
-- 2015.11.18 Ver1.3 Add Start
               ,xicv.prod_class_code                                                              AS prod_class_code
-- 2015.11.18 Ver1.3 Add End
          FROM  oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
               ,oe_order_lines_all          oola                     --�󒍖���(�W��)
               ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
               ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
               ,oe_transaction_types_all    otta                     --�󒍃^�C�v
               ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
               ,rcv_shipment_lines          rsl                      --�������
               ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
               ,ic_item_mst_b               iimb                     --OPM�i�ڃ}�X�^
               ,xxcmn_item_categories5_v    xicv                     --OPM�i�ڃJ�e�S���������View5
               ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
               ,xxcmn_lot_cost              xlc                      --���b�g�ʌ����A�h�I��
               ,xxcmn_rcv_pay_mst           xrpm                     --�󕥋敪�A�h�I���}�X�^
-- 2019/08/01 Ver1.6 Del Start
--               ,fnd_lookup_values           flv                      --lookup�\
-- 2019/08/01 Ver1.6 Del End
               ,gmi_item_categories         gic1                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb1                      --�i�ڃJ�e�S���}�X�^
               ,gmi_item_categories         gic2                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb2                      --�i�ڃJ�e�S���}�X�^
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --�ŐV�t���O�FY
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --���׍폜�t���O�FN
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --�����^�C�v�F�x���˗�
          AND    xmld.record_type_code             = cv_rec_type_stck           --���R�[�h�^�C�v�F�o�Ɏ���
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    otta.attribute4                   = cv_zaiko_class             --�݌ɒ����敪�F1�i���݌ɒ����j
          AND    rsl.oe_order_header_id            = xola.header_id
          AND    rsl.oe_order_line_id              = xola.line_id
          AND    itp.doc_id                        = rsl.shipment_header_id
          AND    itp.doc_line                      = rsl.line_num
          AND    itp.doc_type                      = cv_doc_type_porc           --�w���֘A
          AND    itp.completed_ind                 = cn_completed_ind           --�����t���O
          AND    gic1.item_id                      = iimb.item_id
          AND    gic1.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic1.category_id                  = mcb1.category_id
          AND    mcb1.segment1                     = cv_item_class_code_5       --�i�ڋ敪�F���i
          AND    xrpm.item_div_ahead               = mcb1.segment1
          AND    gic2.item_id                      = itp.item_id 
          AND    gic2.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic2.category_id                  = mcb2.category_id
          AND    mcb2.segment1                     IN (cv_item_class_code_1,cv_item_class_code_2,cv_item_class_code_4) --�i�ڋ敪�F�����E���ޥ�����i
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.source_document_code         = cv_source_document_code    --RMA
          AND    xrpm.dealings_div                 = cv_dealings_div_2          --����敪�F�U�֗L��
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          -- 2015-01-22 Ver1.1 Mod Start
--          AND    xicv.item_no                      = xola.shipping_item_code
          AND    xicv.item_id                      = iimb.item_id
          -- 2015-01-22 Ver1.1 Mod End
-- 2019/08/01 Ver1.6 Del Start
--          AND    flv.lookup_type                   = cv_profile_name_03
--          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
---- 2015.11.18 Ver1.3 Mod Start
----                                                   AND     flv.end_date_active
--                                                   AND     NVL(flv.end_date_active, xoha.arrival_date)
---- 2015.11.18 Ver1.3 Mod End
--          AND    flv.language                      = cv_lang
-- 2019/08/01 Ver1.6 Del End
          UNION ALL
          --�F�x���˗��E�d���L��(���i�U�֗L��)
-- 2019/08/01 Ver1.6 Mod Start
--          SELECT /*+ LEADING(flv xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 gic3 mcb3 rsl itp xrpm gic4 mcb4 gic5 mcb5 xmld oola ilm xlc) 
          SELECT /*+ LEADING(    xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 gic3 mcb3 rsl itp xrpm gic4 mcb4 gic5 mcb5 xmld oola ilm xlc) 
-- 2019/08/01 Ver1.6 Mod End
                     USE_NL (    xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 gic3 mcb3 rsl itp xrpm gic4 mcb4 gic5 mcb5 xmld oola ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
-- 2015.11.18 Ver1.3 Mod Start
--               ,(select nvl(xsup.stnd_unit_price, 0)
--                 from   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
--                 where  iimb.item_id      = xsup.item_id(+)
--                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
               ,(SELECT nvl(xsup.stnd_unit_price, 0)  stnd_unit_price
                 FROM   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
                 WHERE  iimb.item_id      = xsup.item_id(+)
                 AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
-- 2015.11.18 Ver1.3 Mod End
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
-- 2019/08/01 Ver1.6 Mod Start
--               ,flv.lookup_code                                                                   AS tax_rate
               ,itp.item_id                                                                       AS item_id
-- 2020/05/27 Ver1.7 Mod Start
--               ,xoha.arrival_date                                                                 AS target_date
               ,NVL( xoha.sikyu_return_date,xoha.arrival_date )                                   AS target_date
-- 2020/05/27 Ver1.7 Mod End
-- 2019/08/01 Ver1.6 Mod End
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
                -- 2015-02-18 Ver1.2 #44 Add Start
               ,xoha.vendor_id                                                                    AS vendor_id
                -- 2015-02-18 Ver1.2 #44 Add End
-- 2015.11.18 Ver1.3 Add Start
               ,xicv.prod_class_code                                                              AS prod_class_code
-- 2015.11.18 Ver1.3 Add End
          FROM  oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
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
-- 2019/08/01 Ver1.6 Del Start
--               ,fnd_lookup_values           flv                      --lookup�\
-- 2019/08/01 Ver1.6 Del End
               ,gmi_item_categories         gic1                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb1                      --�i�ڃJ�e�S���}�X�^
               ,gmi_item_categories         gic2                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb2                      --�i�ڃJ�e�S���}�X�^
               ,gmi_item_categories         gic3                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb3                      --�i�ڃJ�e�S���}�X�^
               ,gmi_item_categories         gic4                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb4                      --�i�ڃJ�e�S���}�X�^
               ,gmi_item_categories         gic5                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb5                      --�i�ڃJ�e�S���}�X�^
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --�ŐV�t���O�FY
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --���׍폜�t���O�FN
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --�����^�C�v�F�x���˗�
          AND    xmld.record_type_code             = cv_rec_type_stck           --���R�[�h�^�C�v�F�o�Ɏ���
          AND    oola.header_id                    = xola.header_ID
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    otta.attribute4                   = cv_zaiko_class             --�݌ɒ����敪�F1�i���݌ɒ����j
          AND    wdd.source_header_id              = xola.header_id
          AND    wdd.source_line_id                = xola.line_id
          AND    itp.line_detail_id                = wdd.delivery_detail_id
          AND    itp.doc_type                      = cv_doc_type_omso           --�󒍊֘A
          AND    itp.completed_ind                 = cn_completed_ind           --�����t���O�F�ŐV
          AND    gic1.item_id                      = iimb.item_id
          AND    gic1.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_05))
          AND    gic1.category_id                  = mcb1.category_id
          AND    mcb1.segment1                     = cv_item_prod_code_1        --���i�敪�F���[�t
          AND    gic2.item_id                      = iimb.item_id
          AND    gic2.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic2.category_id                  = mcb2.category_id
          AND    mcb2.segment1                     = cv_item_class_code_5       --�i�ڋ敪�F���i
          AND    gic3.item_id                      = iimb.item_id
          AND    gic3.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_06))
          AND    gic3.category_id                  = mcb3.category_id
          AND    gic4.item_id                      = itp.item_id 
          AND    gic4.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic4.category_id                  = mcb4.category_id
          AND    mcb4.segment1                     = cv_item_class_code_5       --�i�ڋ敪�F���i
          AND    gic5.item_id                      = itp.item_id
          AND    gic5.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_05))
          AND    gic5.category_id                  = mcb5.category_id
          AND    mcb5.segment1                     = cv_item_prod_code_2        --���i�敪�F�h�����N
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.dealings_div                 = cv_dealings_div_3          --����敪�F���i�U�֗L��
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          -- 2015-01-22 Ver1.1 Mod Start
--          AND    xicv.item_no                      = xola.shipping_item_code
          AND    xicv.item_id                      = iimb.item_id
          -- 2015-01-22 Ver1.1 Mod End
-- 2019/08/01 Ver1.6 Del Start
--          AND    flv.lookup_type                   = cv_profile_name_03
--          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
---- 2015.11.18 Ver1.3 Mod Start
----                                                   AND     flv.end_date_active
--                                                   AND     NVL(flv.end_date_active, xoha.arrival_date)
---- 2015.11.18 Ver1.3 Mod End
--          AND    flv.language                      = cv_lang
-- 2019/08/01 Ver1.6 Del End
          UNION ALL
          --�G�x���ԕi(���i�U�֗L��)
-- 2019/08/01 Ver1.6 Mod Start
--          SELECT /*+ LEADING(flv xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp xrpm gic3 mcb3 gic4 mcb4 xmld oola ilm xlc) 
          SELECT /*+ LEADING(    xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp xrpm gic3 mcb3 gic4 mcb4 xmld oola ilm xlc) 
-- 2019/08/01 Ver1.6 Mod End
                     USE_NL (    xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp xrpm gic3 mcb3 gic4 mcb4 xmld oola ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
-- 2015.11.18 Ver1.3 Mod Start
--               ,(select nvl(xsup.stnd_unit_price, 0)
--                 from   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
--                 where  iimb.item_id      = xsup.item_id(+)
--                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
               ,(SELECT nvl(xsup.stnd_unit_price, 0)  stnd_unit_price
                 FROM   xxcmn_stnd_unit_price_v     xsup             --�W���������u������
                 WHERE  iimb.item_id      = xsup.item_id(+)
                 AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
-- 2015.11.18 Ver1.3 Mod End
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
-- 2019/08/01 Ver1.6 Mod Start
--               ,flv.lookup_code                                                                   AS tax_rate
               ,itp.item_id                                                                       AS item_id
               ,xoha.sikyu_return_date                                                            AS target_date
-- 2019/08/01 Ver1.6 Mod End
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
                -- 2015-02-18 Ver1.2 #44 Add Start
               ,xoha.vendor_id                                                                    AS vendor_id
                -- 2015-02-18 Ver1.2 #44 Add End
-- 2015.11.18 Ver1.3 Add Start
               ,xicv.prod_class_code                                                              AS prod_class_code
-- 2015.11.18 Ver1.3 Add End
          FROM  oe_order_headers_all        ooha                     --�󒍃w�b�_(�W��)
               ,oe_order_lines_all          oola                     --�󒍖���(�W��)
               ,xxwsh_order_headers_all     xoha                     --�󒍃w�b�_�A�h�I��
               ,xxwsh_order_lines_all       xola                     --�󒍖��׃A�h�I��
               ,oe_transaction_types_all    otta                     --�󒍃^�C�v
               ,xxinv_mov_lot_details       xmld                     --�ړ����b�g�ڍ׃A�h�I��
               ,rcv_shipment_lines          rsl                      --�������
               ,ic_tran_pnd                 itp                      --OPM�ۗ��݌Ƀg�����U�N�V�����\
               ,ic_item_mst_b               iimb                     --OPM�i�ڃ}�X�^
               ,xxcmn_item_categories5_v    xicv                     --OPM�i�ڃJ�e�S���������View5
               ,ic_lots_mst                 ilm                      --OPM���b�g�}�X�^
               ,xxcmn_lot_cost              xlc                      --���b�g�ʌ����A�h�I��
               ,xxcmn_rcv_pay_mst           xrpm                     --�󕥋敪�A�h�I���}�X�^
-- 2019/08/01 Ver1.6 Del Start
--               ,fnd_lookup_values           flv                      --lookup�\
-- 2019/08/01 Ver1.6 Del End
               ,gmi_item_categories         gic1                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb1                      --�i�ڃJ�e�S���}�X�^
               ,gmi_item_categories         gic2                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb2                      --�i�ڃJ�e�S���}�X�^
               ,gmi_item_categories         gic3                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb3                      --�i�ڃJ�e�S���}�X�^
               ,gmi_item_categories         gic4                      --OPM�i�ڃJ�e�S������
               ,mtl_categories_b            mcb4                      --�i�ڃJ�e�S���}�X�^
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --�ŐV�t���O�FY
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --�o�׈˗��X�e�[�^�X�F�o�׎��ьv���
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --���׍폜�t���O�FN
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --�����^�C�v�F�x���˗�
          AND    xmld.record_type_code             = cv_rec_type_stck           --���R�[�h�^�C�v�F�o�Ɏ���
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    otta.attribute4                   = cv_zaiko_class             --�݌ɒ����敪�F1�i���݌ɒ����j
          AND    rsl.oe_order_header_id            = xola.header_id
          AND    rsl.oe_order_line_id              = xola.line_id
          AND    itp.doc_id                        = rsl.shipment_header_id
          AND    itp.doc_line                      = rsl.line_num
          AND    itp.doc_type                      = cv_doc_type_porc           --�w���֘A
          AND    itp.completed_ind                 = cn_completed_ind           --�����t���O
          AND    gic1.item_id                      = iimb.item_id
          AND    gic1.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_05))
          AND    gic1.category_id                  = mcb1.category_id
          AND    mcb1.segment1                     = cv_item_prod_code_1        --���i�敪�F���[�t
          AND    gic2.item_id                      = iimb.item_id
          AND    gic2.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic2.category_id                  = mcb2.category_id
          AND    mcb2.segment1                     = cv_item_class_code_5       --�i�ڋ敪�F���i
          AND    gic3.item_id                      = itp.item_id 
          AND    gic3.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic3.category_id                  = mcb3.category_id
          AND    mcb3.segment1                     = cv_item_class_code_5       --�i�ڋ敪�F���i
          AND    gic4.item_id                      = itp.item_id
          AND    gic4.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_05))
          AND    gic4.category_id                  = mcb4.category_id
          AND    mcb4.segment1                     = cv_item_prod_code_2        --���i�敪�F�h�����N
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --�o�׎x���敪�F�x��
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.source_document_code         = cv_source_document_code    --RMA
          AND    xrpm.dealings_div                 = cv_dealings_div_3          --����敪�F���i�U�֗L��
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          -- 2015-01-22 Ver1.1 Mod Start
--          AND    xicv.item_no                      = xola.shipping_item_code
          AND    xicv.item_id                      = iimb.item_id
          -- 2015-01-22 Ver1.1 Mod End
-- 2019/08/01 Ver1.6 Del Start
--          AND    flv.lookup_type                   = cv_profile_name_03
--          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
---- 2015.11.18 Ver1.3 Mod Start
----                                                   AND     flv.end_date_active
--                                                   AND     NVL(flv.end_date_active, xoha.arrival_date)
---- 2015.11.18 Ver1.3 Mod End
--          AND    flv.language                      = cv_lang
-- 2019/08/01 Ver1.6 Del End
          ) trn
-- 2019/08/01 Ver1.6 Add Start
         ,xxcmm_item_tax_rate_v                    xitrv                     -- ����ŗ����VIEW
      WHERE      xitrv.item_id                     = trn.item_id
      AND        trn.target_date                   BETWEEN NVL(xitrv.start_date_active, trn.target_date)
                                                   AND     NVL(xitrv.end_date_active,   trn.target_date)
-- 2019/08/01 Ver1.6 Add End
      ORDER BY
                department_code                   -- ����
                -- 2015-02-18 Ver1.2 #44 Mod Start
--               ,vendor_site_id                    -- �o�א�
               ,vendor_id                         -- �d����
                -- 2015-02-18 Ver1.2 #44 Mod End
               ,item_class_code                   -- �i�ڋ敪
-- 2019/08/01 Ver1.6 Mod Start
--               ,tax_rate                          -- �ŗ�
               ,tax_code                          -- �ŃR�[�h
-- 2019/08/01 Ver1.6 Mod End
               ,header_id                         -- �󒍃w�b�_ID
               ,line_id                           -- �󒍖���ID
    ;
    -- GL�d��OIF���i�[�pPL/SQL�\
    TYPE gl_interface_ttype IS TABLE OF get_gl_interface_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gl_interface_tab                    gl_interface_ttype;
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
    -- ���ʊ֐�����OPM�݌ɉ�v����CLOSE�N�����擾���A�I������ݒ�
-- 2019.07.26 Ver1.5 Mod Start
--    ld_opminv_date := LAST_DAY(TO_DATE(xxcmn_common_pkg.get_opminv_close_period ||
--                            cv_fdy || cv_e_time,cv_dt_format));
    ld_opminv_date := LAST_DAY(TO_DATE(xxcmn_common_pkg.get_opminv_close_period || cv_fdy,cv_d_format));
-- 2019.07.26 Ver1.5 Mod End
--
    -- ===============================
    -- 1.���o�J�[�\�����t�F�b�`���A���[�v�������s��
    -- ===============================
    -- �I�[�v��
    OPEN get_gl_interface_cur;
    -- �o���N�t�F�b�`
    FETCH get_gl_interface_cur BULK COLLECT INTO gl_interface_tab;
    -- �J�[�\���N���[�Y
    IF ( get_gl_interface_cur%ISOPEN ) THEN
      CLOSE get_gl_interface_cur;
    END IF;
--
    <<main_loop>>
    FOR ln_count in 1..gl_interface_tab.COUNT LOOP
--
      -- �u���C�N�L�[���O���R�[�h�ƈႤ�ꍇ�A�O���R�[�h�̓o�^���s��(1���R�[�h�ڂ͑ΏۊO)
      IF ( ( NVL(lt_department_code,gl_interface_tab(ln_count).department_code)  <> gl_interface_tab(ln_count).department_code )
        -- 2015-02-18 Ver1.2 #44 Mod Start
--        OR ( NVL(lt_vendor_site_id,gl_interface_tab(ln_count).vendor_site_id)    <> gl_interface_tab(ln_count).vendor_site_id )
        OR ( NVL(lt_vendor_id,gl_interface_tab(ln_count).vendor_id)    <> gl_interface_tab(ln_count).vendor_id )
-- 2019/08/01 Ver1.6 Add Start
        OR ( NVL(lt_tax_code,gl_interface_tab(ln_count).tax_code)    <> gl_interface_tab(ln_count).tax_code )
-- 2019/08/01 Ver1.6 Add End
        -- 2015-02-18 Ver1.2 #44 Mod End
        OR ( NVL(lt_item_class_code,gl_interface_tab(ln_count).item_class_code)  <> gl_interface_tab(ln_count).item_class_code ) )
-- 2019/08/01 Ver1.6 Del Start
--        AND g_gl_interface_tab(ln_tax_cnt).misyu_kin <> 0
-- 2019/08/01 Ver1.6 Del End
      THEN
-- 2019/08/01 Ver1.6 Add Start
        IF ( g_gl_interface_tab(ln_tax_cnt).misyu_kin <> 0 ) THEN
-- 2019/08/01 Ver1.6 Add End
--
          -- ===============================
          -- �o�א�����擾
          -- ===============================
          BEGIN
            -- 2015-01-22 Ver1.1 Mod Start
--          SELECT xvsa.vendor_site_short_name                  -- �d���旪��
--          INTO   lt_vendor_site_name
--          FROM   xxcmn_vendor_sites_all xvsa                  -- �d����T�C�g�A�h�I���}�X�^
--          WHERE  xvsa.vendor_site_id = lt_vendor_site_id      -- �d����T�C�gID
--          AND    NVL(xvsa.start_date_active,ld_opminv_date) <= ld_opminv_date
--          AND    NVL(xvsa.end_date_active,ld_opminv_date)   >= ld_opminv_date
--          ;
-- 2015.11.18 Ver1.3 Mod Start
--          SELECT pv.segment1
--                ,xv.vendor_name
            SELECT pv.segment1       vendor_code
                  ,xv.vendor_name    vendor_name
-- 2015.11.18 Ver1.3 Mod End
            INTO   lt_vendor_code
                  ,lt_vendor_name
            FROM   po_vendors           pv
                  ,po_vendor_sites_all  pvsa
                  ,xxcmn_vendors        xv
            WHERE  pvsa.vendor_site_id = lt_vendor_site_id
            AND    pv.vendor_id        = pvsa.vendor_id
            AND    pv.vendor_id        = xv.vendor_id
            AND    ld_opminv_date      BETWEEN xv.start_date_active
                                       AND     NVL(xv.end_date_active,trunc(sysdate))
            AND    ld_opminv_date      <= NVL(pv.end_date_active,ld_opminv_date);
            -- 2015-01-22 Ver1.1 Mod End
--
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg    := xxccp_common_pkg.get_msg(
                                iv_application  => cv_appl_name_xxcfo
                              , iv_name         => cv_msg_cfo_10035        -- �f�[�^�擾�G���[
                              , iv_token_name1  => cv_tkn_data
                              , iv_token_value1 => cv_msg_out_data_04      -- �d����T�C�g�A�h�I���}�X�^
                              , iv_token_name2  => cv_tkn_item
                              , iv_token_value2 => cv_msg_out_item_02      -- �d����T�C�gID
                              , iv_token_name3  => cv_tkn_key
                              , iv_token_value3 => lt_vendor_site_id
                              );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
--
          -- ===============================
          -- �d��OIF�o�^(��������(A-5))
          -- ===============================
          ins_gl_interface(
            in_prc_mode              => cn_prc_mode1,        -- 1.�������[�h�i���������j
            it_department_code       => lt_department_code,  -- 2.����R�[�h
            it_item_class_code       => lt_item_class_code,  -- 3.�i�ڋ敪
            -- 2015-01-22 Ver1.1 Mod Start
--            it_vendor_site_code      => lt_vendor_site_code, -- 4.�o�א�R�[�h
--            it_vendor_site_name      => lt_vendor_site_name, -- 5.�o�א於
            it_vendor_code           => lt_vendor_code,      -- 4.�o�א�R�[�h
            it_vendor_name           => lt_vendor_name,      -- 5.�o�א於
            -- 2015-01-22 Ver1.1 Mod End
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- �d��OIF�o�^(��������(A-6))
          -- ===============================
          ins_gl_interface(
            in_prc_mode              => cn_prc_mode2,        -- 1.�������[�h�i�������Łj
            it_department_code       => lt_department_code,  -- 2.����R�[�h
            it_item_class_code       => lt_item_class_code,  -- 3.�i�ڋ敪
            -- 2015-01-22 Ver1.1 Mod Start
--            it_vendor_site_code      => lt_vendor_site_code, -- 4.�o�א�R�[�h
--            it_vendor_site_name      => lt_vendor_site_name, -- 5.�o�א於
            it_vendor_code           => lt_vendor_code,      -- 4.�o�א�R�[�h
            it_vendor_name           => lt_vendor_name,      -- 5.�o�א於
            -- 2015-01-22 Ver1.1 Mod End
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- �d��OIF�o�^(�L���x��(A-6))
          -- ===============================
          ins_gl_interface(
            in_prc_mode              => cn_prc_mode3,        -- 1.�������[�h�i�L���x���j
            it_department_code       => lt_department_code,  -- 2.����R�[�h
            it_item_class_code       => lt_item_class_code,  -- 3.�i�ڋ敪
            -- 2015-01-22 Ver1.1 Mod Start
--            it_vendor_site_code      => lt_vendor_site_code, -- 4.�o�א�R�[�h
--            it_vendor_site_name      => lt_vendor_site_name, -- 5.�o�א於
            it_vendor_code           => lt_vendor_code,      -- 4.�o�א�R�[�h
            it_vendor_name           => lt_vendor_name,      -- 5.�o�א於
            -- 2015-01-22 Ver1.1 Mod End
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
-- 2015.11.18 Ver1.3 Mod Start
--        -- ===============================
--        -- �d��OIF�o�^(�����(A-6))
--        -- ===============================
--        ins_gl_interface(
--          in_prc_mode              => cn_prc_mode4,        -- 1.�������[�h�i������j
--          it_department_code       => lt_department_code,  -- 2.����R�[�h
--          it_item_class_code       => lt_item_class_code,  -- 3.�i�ڋ敪
--          -- 2015-01-22 Ver1.1 Mod Start
----          it_vendor_site_code      => lt_vendor_site_code, -- 4.�o�א�R�[�h
----          it_vendor_site_name      => lt_vendor_site_name, -- 5.�o�א於
--          it_vendor_code           => lt_vendor_code,      -- 4.�o�א�R�[�h
--          it_vendor_name           => lt_vendor_name,      -- 5.�o�א於
--          -- 2015-01-22 Ver1.1 Mod End
--          ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
--          ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
--          ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
----
--        IF (lv_retcode <> cv_status_normal) THEN
--          RAISE global_process_expt;
--        END IF;
          -- ������i���[�t�j��0�ȊO�̏ꍇ
          IF ( ln_kari_kin_1 <> 0 ) THEN
            -- ������i���[�t�j��ݒ�
            g_gl_interface_tab(ln_tax_cnt).kari_kin    := ln_kari_kin_1;
--
            -- ===============================
            -- �d��OIF�o�^(������i���[�t�j(A-6))
            -- ===============================
            ins_gl_interface(
              in_prc_mode              => cn_prc_mode41,       -- 1.�������[�h�i������i���[�t�j�j
              it_department_code       => lt_department_code,  -- 2.����R�[�h
              it_item_class_code       => lt_item_class_code,  -- 3.�i�ڋ敪
              it_vendor_code           => lt_vendor_code,      -- 4.�o�א�R�[�h
              it_vendor_name           => lt_vendor_name,      -- 5.�o�א於
              ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
              ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
              ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- ������i�h�����N�j��0�ȊO�̏ꍇ
          IF ( ln_kari_kin_2 <> 0 ) THEN
            -- ������i�h�����N�j��ݒ�
            g_gl_interface_tab(ln_tax_cnt).kari_kin    := ln_kari_kin_2;
--
            -- ===============================
            -- �d��OIF�o�^(������i�h�����N�j(A-6))
            -- ===============================
            ins_gl_interface(
              in_prc_mode              => cn_prc_mode42,       -- 1.�������[�h�i������i�h�����N�j�j
              it_department_code       => lt_department_code,  -- 2.����R�[�h
              it_item_class_code       => lt_item_class_code,  -- 3.�i�ڋ敪
              it_vendor_code           => lt_vendor_code,      -- 4.�o�א�R�[�h
              it_vendor_name           => lt_vendor_name,      -- 5.�o�א於
              ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
              ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
              ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
-- 2015.11.18 Ver1.3 Mod End
--
          -- ===============================
          -- ���Y����f�[�^�X�V(A-7)
          -- ===============================
          upd_inv_trn_data(
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
-- 2019/08/01 Ver1.6 Add Start
        END IF;
-- 2019/08/01 Ver1.6 Add End
--
        -- �d��P�ʂ̏������ϐ��̏����������{
        lt_department_code         := NULL;                -- �d��P�ʁF����R�[�h
        lt_item_class_code         := NULL;                -- �d��P�ʁF�i�ڋ敪
        -- 2015-01-22 Ver1.1 Mod Start
--        lt_vendor_site_code        := NULL;                -- �d��P�ʁF�o�א�R�[�h
--        lt_vendor_site_name        := NULL;                -- �d��P�ʁF�o�א於
        lt_vendor_code             := NULL;                -- �d��P�ʁF�o�א�R�[�h
        lt_vendor_name             := NULL;                -- �d��P�ʁF�o�א於
        -- 2015-01-22 Ver1.1 Mod End
        lt_vendor_site_id          := NULL;                -- �d��P�ʁF�o�א�ID
        gt_attribute8              := NULL;                -- �d��P�ʁF�Q�ƍ��ڂP(�d��L�[)
        gv_description_dr          := NULL;                -- �d��P�ʁF�E�v�i�ؕ��j
        -- 2015-02-18 Ver1.2 #44 Add Start
        lt_vendor_id               := NULL;                -- �d��P�ʁF�d����ID
-- 2019/08/01 Ver1.6 Add Start
        lt_tax_code                := NULL;                -- �ŃR�[�h
-- 2019/08/01 Ver1.6 Add End
        -- 2015-02-18 Ver1.2 #44 Add End
-- 2015.11.18 Ver1.3 Add Start
        ln_kari_kin_1              := 0;                   -- ������i���[�t�j
        ln_kari_kin_2              := 0;                   -- ������i�h�����N�j
-- 2015.11.18 Ver1.3 Add End
--
-- 2019/08/01 Ver1.6 Del Start
--        ln_tax_rate_jdge           := 0;                   -- ����ŗ�(����p)
-- 2019/08/01 Ver1.6 Del End
        ln_tax_cnt                 := 0;
        ln_out_count               := 0;
        g_gl_interface_tab.DELETE;                         -- �L���x�����z���i�[�pPL/SQL�\
        g_oe_order_lines_all_tab.DELETE;                   -- �d��OIF���i�[�pPL/SQL�\
      END IF;
--
      -- �u�������Łv�܂��́u�L���x���v�܂��́u������v�̋��z��0�ȊO�̏ꍇ
      IF (gl_interface_tab(ln_count).tax_kin <> 0
          OR gl_interface_tab(ln_count).jitu_kin <> 0
          OR gl_interface_tab(ln_count).kari_kin <> 0 ) THEN
        -- �����Ώی����J�E���g
        gn_target_cnt := gn_target_cnt +1;
--
-- 2019/08/01 Ver1.6 Del Start
--        -- ����ŗ����Ƃ̐ςݏグ���s���B
--        IF (NVL(ln_tax_rate_jdge,0) = 0) THEN
--          ln_tax_cnt := 1;
--          g_gl_interface_tab(ln_tax_cnt).tax_rate    := gl_interface_tab(ln_count).tax_rate;    -- �d��P�ʁF�ŃR�[�h
--        --
--        ELSIF (NVL(ln_tax_rate_jdge,0) <> gl_interface_tab(ln_count).tax_rate) THEN
--          ln_tax_cnt := NVL(ln_tax_cnt,0) + 1;
--          g_gl_interface_tab(ln_tax_cnt).tax_rate    := gl_interface_tab(ln_count).tax_rate;    -- �d��P�ʁF�ŃR�[�h
--        --
--        END IF;
-- 2019/08/01 Ver1.6 Del End
-- 2019/08/01 Ver1.6 Add Start
        ln_tax_cnt := 1;
        g_gl_interface_tab(ln_tax_cnt).tax_code    := gl_interface_tab(ln_count).tax_code;    -- �d��P�ʁF�ŃR�[�h
-- 2019/08/01 Ver1.6 Add End
        -- ����ŗ����Ƃɋ��z�̐ςݏグ���s��
        g_gl_interface_tab(ln_tax_cnt).jitu_kin    := NVL(g_gl_interface_tab(ln_tax_cnt).jitu_kin,0) + gl_interface_tab(ln_count).jitu_kin;       -- �d��P�ʁF�L���x��
-- 2015.11.18 Ver1.3 Mod Start
--        g_gl_interface_tab(ln_tax_cnt).kari_kin    := NVL(g_gl_interface_tab(ln_tax_cnt).kari_kin,0) + gl_interface_tab(ln_count).kari_kin;       -- �d��P�ʁF�����
        -- ���i�敪�F���[�t�̏ꍇ
        IF ( gl_interface_tab(ln_count).prod_class_code = cv_item_prod_code_1 ) THEN
          ln_kari_kin_1 := ln_kari_kin_1 + gl_interface_tab(ln_count).kari_kin;       -- �d��P�ʁF������i���[�t�j
        -- ���i�敪�F�h�����N�̏ꍇ
        ELSE
          ln_kari_kin_2 := ln_kari_kin_2 + gl_interface_tab(ln_count).kari_kin;       -- �d��P�ʁF������i�h�����N�j
        END IF;
-- 2015.11.18 Ver1.3 Mod End
        g_gl_interface_tab(ln_tax_cnt).tax_kin     := NVL(g_gl_interface_tab(ln_tax_cnt).tax_kin,0) + gl_interface_tab(ln_count).tax_kin;         -- �d��P�ʁF�����
        g_gl_interface_tab(ln_tax_cnt).misyu_kin   := g_gl_interface_tab(ln_tax_cnt).jitu_kin
-- 2015.11.18 Ver1.3 Mod Start
--                                                      + g_gl_interface_tab(ln_tax_cnt).kari_kin
                                                      + ln_kari_kin_1
                                                      + ln_kari_kin_2
-- 2015.11.18 Ver1.3 Mod End
                                                      + g_gl_interface_tab(ln_tax_cnt).tax_kin;      -- �d��P�ʁF��������
--
-- 2019/08/01 Ver1.6 Del Start
--        -- ����ŗ�(����p)��ێ�
--        ln_tax_rate_jdge                           := gl_interface_tab(ln_count).tax_rate;
-- 2019/08/01 Ver1.6 Del End
--
        -- �d��P�ʂ̏���ێ�
        lt_department_code           := gl_interface_tab(ln_count).department_code;                 -- �d��P�ʁF����
        lt_vendor_site_id            := gl_interface_tab(ln_count).vendor_site_id;                  -- �d��P�ʁF�o�א�ID
        lt_item_class_code           := gl_interface_tab(ln_count).item_class_code;                 -- �d��P�ʁF�i�ڋ敪
        -- 2015-02-18 Ver1.2 #44 Add Start
        lt_vendor_id                 :=gl_interface_tab(ln_count).vendor_id;                   -- �d��P�ʁF�d����ID
        -- 2015-02-18 Ver1.2 #44 Add End
-- 2019/08/01 Ver1.6 Add Start
        lt_tax_code                  := gl_interface_tab(ln_count).tax_code;                        -- �ŃR�[�h
-- 2019/08/01 Ver1.6 Add End
--
        -- �u���ID�v��z��ɕێ�
        ln_out_count :=  ln_out_count + 1;
        g_oe_order_lines_all_tab(ln_out_count).header_id := gl_interface_tab(ln_count).header_id;    -- �d��P�ʁF�󒍃w�b�_ID
        g_oe_order_lines_all_tab(ln_out_count).line_id   := gl_interface_tab(ln_count).line_id;      -- �d��P�ʁF�󒍖���ID
--
      ELSE
        -- �X�L�b�v�����J�E���g
        gn_warn_cnt := gn_warn_cnt +1;
      END IF;
--
      -- �ŏI���R�[�h�̏ꍇ
      IF ln_count = gl_interface_tab.COUNT AND g_gl_interface_tab(ln_tax_cnt).misyu_kin <> 0 THEN
--
        -- ===============================
        -- �o�א�����擾
        -- ===============================
        BEGIN
          -- 2015-01-22 Ver1.1 Mod End
--          SELECT xvsa.vendor_site_short_name                  -- �d���旪��
--          INTO   lt_vendor_site_name
--          FROM   xxcmn_vendor_sites_all xvsa                  -- �d����T�C�g�A�h�I���}�X�^
--          WHERE  xvsa.vendor_site_id = lt_vendor_site_id      -- �d����T�C�gID
--          AND    NVL(xvsa.start_date_active,ld_opminv_date) <= ld_opminv_date
--          AND    NVL(xvsa.end_date_active,ld_opminv_date)   >= ld_opminv_date
--          ;
-- 2015.11.18 Ver1.3 Mod Start
--          SELECT pv.segment1
--                ,xv.vendor_short_name
          SELECT pv.segment1           vendor_code
                ,xv.vendor_short_name  vendor_name
-- 2015.11.18 Ver1.3 Mod End
          INTO   lt_vendor_code
                ,lt_vendor_name
          FROM   po_vendors           pv
                ,po_vendor_sites_all  pvsa
                ,xxcmn_vendors        xv
          WHERE  pvsa.vendor_site_id = lt_vendor_site_id
          AND    pv.vendor_id        = pvsa.vendor_id
          AND    pv.vendor_id        = xv.vendor_id
          AND    ld_opminv_date      BETWEEN xv.start_date_active
                                     AND     NVL(xv.end_date_active,trunc(sysdate))
          AND    ld_opminv_date      <= NVL(pv.end_date_active,ld_opminv_date);
          -- 2015-01-22 Ver1.1 Mod End
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_name_xxcfo
                            , iv_name         => cv_msg_cfo_10035        -- �f�[�^�擾�G���[
                            , iv_token_name1  => cv_tkn_data
                            , iv_token_value1 => cv_msg_out_data_04      -- �d����T�C�g�A�h�I���}�X�^
                            , iv_token_name2  => cv_tkn_item
                            , iv_token_value2 => cv_msg_out_item_02      -- �d����T�C�gID
                            , iv_token_name3  => cv_tkn_key
                            , iv_token_value3 => lt_vendor_site_id
                            );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
--
        -- ===============================
        -- �d��OIF�o�^(��������(A-5))
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode1,        -- 1.�������[�h�i���������j
          it_department_code       => lt_department_code,  -- 2.����R�[�h
          it_item_class_code       => lt_item_class_code,  -- 3.�i�ڋ敪
          -- 2015-01-22 Ver1.1 Mod Start
--          it_vendor_site_code      => lt_vendor_site_code, -- 4.�o�א�R�[�h
--          it_vendor_site_name      => lt_vendor_site_name, -- 5.�o�א於
          it_vendor_code           => lt_vendor_code,      -- 4.�o�א�R�[�h
          it_vendor_name           => lt_vendor_name,      -- 5.�o�א於
          -- 2015-01-22 Ver1.1 Mod End
          ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- �d��OIF�o�^(��������(A-6))
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode2,        -- 1.�������[�h�i�������Łj
          it_department_code       => lt_department_code,  -- 2.����R�[�h
          it_item_class_code       => lt_item_class_code,  -- 3.�i�ڋ敪
          -- 2015-01-22 Ver1.1 Mod Start
--          it_vendor_site_code      => lt_vendor_site_code, -- 4.�o�א�R�[�h
--          it_vendor_site_name      => lt_vendor_site_name, -- 5.�o�א於
          it_vendor_code           => lt_vendor_code,      -- 4.�o�א�R�[�h
          it_vendor_name           => lt_vendor_name,      -- 5.�o�א於
          -- 2015-01-22 Ver1.1 Mod End
          ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- �d��OIF�o�^(�L���x��(A-6))
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode3,        -- 1.�������[�h�i�L���x���j
          it_department_code       => lt_department_code,  -- 2.����R�[�h
          it_item_class_code       => lt_item_class_code,  -- 3.�i�ڋ敪
          -- 2015-01-22 Ver1.1 Mod Start
--          it_vendor_site_code      => lt_vendor_site_code, -- 4.�o�א�R�[�h
--          it_vendor_site_name      => lt_vendor_site_name, -- 5.�o�א於
          it_vendor_code           => lt_vendor_code,      -- 4.�o�א�R�[�h
          it_vendor_name           => lt_vendor_name,      -- 5.�o�א於
          -- 2015-01-22 Ver1.1 Mod End
          ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
-- 2015.11.18 Ver1.3 Mod Start
--        -- ===============================
--        -- �d��OIF�o�^(�����(A-6))
--        -- ===============================
--        ins_gl_interface(
--          in_prc_mode              => cn_prc_mode4,        -- 1.�������[�h�i������j
--          it_department_code       => lt_department_code,  -- 2.����R�[�h
--          it_item_class_code       => lt_item_class_code,  -- 3.�i�ڋ敪
--          -- 2015-01-22 Ver1.1 Mod Start
----          it_vendor_site_code      => lt_vendor_site_code, -- 4.�o�א�R�[�h
----          it_vendor_site_name      => lt_vendor_site_name, -- 5.�o�א於
--          it_vendor_code           => lt_vendor_code,      -- 4.�o�א�R�[�h
--          it_vendor_name           => lt_vendor_name,      -- 5.�o�א於
--          -- 2015-01-22 Ver1.1 Mod End
--          ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
--          ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
--          ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
----
--        IF (lv_retcode <> cv_status_normal) THEN
--          RAISE global_process_expt;
--        END IF;
        -- ������i���[�t�j��0�ȊO�̏ꍇ
        IF ( ln_kari_kin_1 <> 0 ) THEN
          -- ������i���[�t�j��ݒ�
          g_gl_interface_tab(ln_tax_cnt).kari_kin    := ln_kari_kin_1;
--
          -- ===============================
          -- �d��OIF�o�^(������i���[�t�j(A-6))
          -- ===============================
          ins_gl_interface(
            in_prc_mode              => cn_prc_mode41,       -- 1.�������[�h�i������i���[�t�j�j
            it_department_code       => lt_department_code,  -- 2.����R�[�h
            it_item_class_code       => lt_item_class_code,  -- 3.�i�ڋ敪
            it_vendor_code           => lt_vendor_code,      -- 4.�o�א�R�[�h
            it_vendor_name           => lt_vendor_name,      -- 5.�o�א於
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ������i�h�����N�j��0�ȊO�̏ꍇ
        IF ( ln_kari_kin_2 <> 0 ) THEN
          -- ������i�h�����N�j��ݒ�
          g_gl_interface_tab(ln_tax_cnt).kari_kin    := ln_kari_kin_2;
--
          -- ===============================
          -- �d��OIF�o�^(������i�h�����N�j(A-6))
          -- ===============================
          ins_gl_interface(
            in_prc_mode              => cn_prc_mode42,       -- 1.�������[�h�i������i�h�����N�j�j
            it_department_code       => lt_department_code,  -- 2.����R�[�h
            it_item_class_code       => lt_item_class_code,  -- 3.�i�ڋ敪
            it_vendor_code           => lt_vendor_code,      -- 4.�o�א�R�[�h
            it_vendor_name           => lt_vendor_name,      -- 5.�o�א於
            ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
-- 2015.11.18 Ver1.3 Mod End
--
        -- ===============================
        -- ���Y����f�[�^�X�V(A-7)
        -- ===============================
        upd_inv_trn_data(
          ov_errbuf                => lv_errbuf,        -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode               => lv_retcode,       -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg                => lv_errmsg);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
    END LOOP main_loop;
--
    -- �Ώۃf�[�^�����݂��Ȃ��ꍇ�A�G���[
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_name_xxcfo  -- 'XXCFO'
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
      IF ( get_gl_interface_cur%ISOPEN ) THEN
        CLOSE get_gl_interface_cur;
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
      IF ( get_gl_interface_cur%ISOPEN ) THEN
        CLOSE get_gl_interface_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_gl_interface_data;
--
-- ver1.8 ADD START
  /**********************************************************************************
   * Procedure Name   : upd_gl_interface
   * Description      : �d��OIF�X�V(A-10)
   ***********************************************************************************/
  PROCEDURE upd_gl_interface(
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'upd_gl_interface'; -- �v���O������
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
    cv_sum_flag_0         CONSTANT  VARCHAR2(1) := '0';      -- �ؕ����T�}���[
    cv_sum_flag_1         CONSTANT  VARCHAR2(1) := '1';      -- �ݕ����T�}���[
    -- *** ���[�J���ϐ� ***
    lv_sum_flag                     VARCHAR2(1) := NULL;
    lv_max_ref_key                  gl_interface.reference4%TYPE;
    ln_adjust_amount                NUMBER      := 0;        -- ���z���[�N
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR get_gl_interface_cur
    IS
      -- �d����E����E�ŗ��P�ʂŋ��z���擾
      SELECT SUBSTRB(gi.reference10,1,4) AS vendor_code,    -- �d����
             gi.attribute4               AS dept_code,      -- ����
             gi.attribute1               AS tax_code,       -- �ŃR�[�h
             (SELECT atc.tax_rate tax_rate
              FROM   ap_tax_codes atc
              WHERE  atc.name    = gi.attribute1
              AND    atc.org_id  = gn_org_id_sales
             )                           AS tax_rate,       -- �ŗ�
             SUM(NVL(gi.entered_dr,0))   AS sum_entered_dr, -- �ؕ�
             SUM(NVL(gi.entered_cr,0))   AS sum_entered_cr  -- �ݕ�
      FROM   gl_interface gi
      WHERE  gi.user_je_source_name = gv_je_invoice_source_mfg
      AND    gi.request_id          = cn_request_id
      AND    gi.attribute1 IS NOT NULL                      -- ���������ȊO
      AND    NOT EXISTS (
                         SELECT 1
                         FROM   ap_tax_codes atc2
                         WHERE  atc2.org_id  = gn_org_id_sales
                         AND    atc2.tax_code_combination_id = gi.code_combination_id
                        )                                   -- �ŋ��s�͑ΏۊO
      GROUP BY SUBSTRB(gi.reference10,1,4),
               gi.attribute4,
               gi.attribute1
      ;
    get_gl_interface_rec get_gl_interface_cur%ROWTYPE;
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
    <<gl_oif_loop>>
    FOR get_gl_interface_rec IN get_gl_interface_cur LOOP
      -- �W�v����J��������
      SELECT DISTINCT
             CASE gi.entered_cr
               WHEN 0 THEN cv_sum_flag_1   -- �ݕ����T�}���[
               ELSE cv_sum_flag_0          -- �ؕ����T�}���[
             END sum_flag
      INTO   lv_sum_flag
      FROM   gl_interface gi
      WHERE  gi.user_je_source_name      = gv_je_invoice_source_mfg
      AND    gi.request_id               = cn_request_id
      AND    substrb(gi.reference10,1,4) = get_gl_interface_rec.vendor_code  -- �d����
      AND    gi.attribute4               = get_gl_interface_rec.dept_code    -- ����R�[�h
      AND    gi.attribute1 IS NULL                                           -- ��������
      ;
--
      -- MAX�d��L�[���擾
      SELECT MAX(reference4)    max_ref_key    --�d��
      INTO   lv_max_ref_key
      FROM   gl_interface gi
      WHERE  gi.user_je_source_name      = gv_je_invoice_source_mfg
      AND    gi.request_id               = cn_request_id
      AND    substrb(gi.reference10,1,4) = get_gl_interface_rec.vendor_code  -- �d����
      AND    gi.attribute4               = get_gl_interface_rec.dept_code    -- ����R�[�h
      AND    gi.attribute1               = get_gl_interface_rec.tax_code     -- �ŃR�[�h
      ;
--
      -- ���z�m�F
      IF ( lv_sum_flag = cv_sum_flag_0 ) THEN
        -- �W����z����Ŋz�Z�o - �Ϗグ���Ŋz �ō��z�����邩�m�F
        SELECT ( ROUND( ( get_gl_interface_rec.sum_entered_dr - get_gl_interface_rec.sum_entered_cr )
                 * (get_gl_interface_rec.tax_rate / 100))
               ) 
               - SUM(gi.entered_dr)  AS  adjust_amount
        INTO   ln_adjust_amount
        FROM   gl_interface     gi
        WHERE  gi.user_je_source_name      = gv_je_invoice_source_mfg
        AND    gi.request_id               = cn_request_id
        AND    substrb(gi.reference10,1,4) = get_gl_interface_rec.vendor_code  -- �d����
        AND    gi.attribute4               = get_gl_interface_rec.dept_code    -- ����R�[�h
        AND    gi.attribute1               = get_gl_interface_rec.tax_code     -- �ŃR�[�h
        AND    EXISTS (
                       SELECT 1
                       FROM   ap_tax_codes atc
                       WHERE  atc.org_id  = gn_org_id_sales
                       AND    atc.tax_code_combination_id = gi.code_combination_id
                      )                                                        -- CCID
        ;
--
        -- ���z������ꍇ�A�Ŋz�𒲐�
        IF ( ln_adjust_amount <> 0 ) THEN
          UPDATE gl_interface gi
          SET    gi.entered_dr = gi.entered_dr + ln_adjust_amount
          WHERE  gi.user_je_source_name  = gv_je_invoice_source_mfg
          AND    gi.request_id           = cn_request_id
          AND    gi.reference4           = lv_max_ref_key
          AND    EXISTS (
                         SELECT 1
                         FROM   ap_tax_codes atc
                         WHERE  atc.org_id  = gn_org_id_sales
                         AND    atc.tax_code_combination_id = gi.code_combination_id
                        )
          ;
--
          -- ���������𒲐�
          UPDATE gl_interface gi
          SET    gi.entered_cr = gi.entered_cr + ln_adjust_amount
          WHERE  gi.user_je_source_name  = gv_je_invoice_source_mfg
          AND    gi.request_id           = cn_request_id
          AND    gi.reference4           = lv_max_ref_key
          AND    gi.attribute1 IS NULL
          ;
        END IF;
      ELSE
        -- �W����z����Ŋz�Z�o - �Ϗグ���Ŋz �ō��z�����邩�m�F
        SELECT ( ROUND( ( get_gl_interface_rec.sum_entered_cr - get_gl_interface_rec.sum_entered_dr )
                 * (get_gl_interface_rec.tax_rate / 100))
               ) 
               - SUM(gi.entered_cr)  AS  adjust_amount
        INTO   ln_adjust_amount
        FROM   gl_interface     gi
        WHERE  gi.user_je_source_name      = gv_je_invoice_source_mfg
        AND    gi.request_id               = cn_request_id
        AND    substrb(gi.reference10,1,4) = get_gl_interface_rec.vendor_code  -- �d����
        AND    gi.attribute4               = get_gl_interface_rec.dept_code    -- ����R�[�h
        AND    gi.attribute1               = get_gl_interface_rec.tax_code     -- �ŃR�[�h
        AND    EXISTS (
                       SELECT 1
                       FROM   ap_tax_codes atc
                       WHERE  atc.org_id  = gn_org_id_sales
                       AND    atc.tax_code_combination_id = gi.code_combination_id
                      )                                                        -- CCID
        ;
        -- ���z������ꍇ�͋��z���X�V
        IF ( ln_adjust_amount <> 0 ) THEN
          -- �Ŋz�𒲐�
          UPDATE gl_interface gi
          SET    gi.entered_cr = gi.entered_cr + ln_adjust_amount
          WHERE  gi.user_je_source_name  = gv_je_invoice_source_mfg
          AND    gi.request_id           = cn_request_id
          AND    gi.reference4           = lv_max_ref_key           -- �d��L�[
          AND    EXISTS (
                         SELECT 1
                         FROM   ap_tax_codes atc
                         WHERE  atc.org_id  = gn_org_id_sales
                         AND    atc.tax_code_combination_id = gi.code_combination_id
                        )
          ;
--
          -- ���������𒲐�
          UPDATE gl_interface gi
          SET    gi.entered_dr = gi.entered_dr + ln_adjust_amount
          WHERE  gi.user_je_source_name  = gv_je_invoice_source_mfg
          AND    gi.request_id           = cn_request_id
          AND    gi.reference4           = lv_max_ref_key           -- �d��L�[
          AND    gi.attribute1 IS NULL
          ;
        END IF;
      END IF;
    END LOOP gl_oif_loop;
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
  END upd_gl_interface;
-- ver1.8 ADD END
  /**********************************************************************************
   * Procedure Name   : ins_mfg_if_control
   * Description      : �A�g�Ǘ��e�[�u���o�^(A-8)
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
         cv_pkg_name                         -- �@�\�� 'XXCFO020A04C'
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
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcfo
                        , iv_name         => cv_msg_cfo_00024              -- �o�^�G���[���b�Z�[�W
                        , iv_token_name1  => cv_tkn_table
                        , iv_token_value1 => cv_msg_out_data_03            -- �A�g�Ǘ��e�[�u��
                        , iv_token_name2  => cv_tkn_errmsg
                        , iv_token_value2 => SQLERRM                       -- SQL�G���[
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
    -- �d��OIF��񒊏o(A-3,4)
    -- ===============================
    get_gl_interface_data(
      iv_period_name           => iv_period_name,       -- 1.��v����
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
-- ver1.8 ADD START
    -- ===============================
    -- �d��OIF�X�V(A-10)
    -- ===============================
    upd_gl_interface(
      ov_errbuf                => lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode               => lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg                => lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
-- ver1.8 ADD END
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
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
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
       iv_period_name                              -- 1.��v����
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ��v�`�[���W���F�ُ�I�����̌����ݒ�
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_error_cnt    := 1;
      gn_warn_cnt     := 0;
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
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_ccp_90003
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
                     iv_application  => cv_appl_name_xxccp
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
END XXCFO020A04C;
/
