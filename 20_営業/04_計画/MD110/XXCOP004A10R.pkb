CREATE OR REPLACE PACKAGE BODY APPS.XXCOP004A10R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOP004A10R(body)
 * Description      : ����v����ёΔ�\
 * MD.050           : MD050_COP_004_A10_����v����ёΔ�\
 * Version          : 1.0
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  init                        ��������(A-1)
 *  get_target_base_code        �Ώۋ��_�擾�i�z�����_�j(A-2)
 *  get_forecast_info           ����v�搔�擾����(A-3)
 *  get_stock_comp_info         ���Ɋm�F��(���_����)�擾����(A-4)
 *  get_stock_order_comp_info   �˗��ϐ�(���_���Ɂ|���_������)�擾����(A-5)
 *  get_stock_fact_ship_info    �˗��ϐ�(���_���Ɂ|�H�ꖢ�o��)�擾����(A-6)
 *  get_ship_comp_info          ����v��ϐ��擾����(A-7)
 *  get_ship_order_comp_info    �˗��ϐ�(����)�擾����(A-8)
 *  svf_call                    SVF�N��(A-9)
 *  del_rep_work_data           ���[���[�N�e�[�u���폜����(A-10)
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                              �I������
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2013/12/10    1.0   S.Niki           �V�K�쐬
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
  -- ��������
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
  global_lock_expt          EXCEPTION;  -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20)   := 'XXCOP004A10R';       -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_application              CONSTANT VARCHAR2(5)    := 'XXCOP';              -- �A�v���P�[�V����:XXCOP
  -- �v���t�@�C��
  cv_itou_ou_mfg              CONSTANT VARCHAR2(30)   := 'XXCOI1_ITOE_OU_MFG';       -- ���Y�c�ƒP�ʎ擾����
  cv_sales_org_code           CONSTANT VARCHAR2(30)   := 'XXCOP1_SALES_ORG_CODE';    -- �c�Ƒg�D�R�[�h
  cv_item_div_h               CONSTANT VARCHAR2(30)   := 'XXCOS1_ITEM_DIV_H';        -- �J�e�S���Z�b�g��(�{�Џ��i�敪)
  cv_policy_group_code        CONSTANT VARCHAR2(30)   := 'XXCOS1_POLICY_GROUP_CODE'; -- �J�e�S���Z�b�g��(����Q�R�[�h)
  -- ���b�Z�[�W
  cv_msg_xxcop_00065          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00065';   -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_xxcop_00002          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00002';   -- �v���t�@�C���l�擾���s�G���[
  cv_msg_xxcop_00013          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00013';   -- �}�X�^�`�F�b�N�G���[
  cv_msg_xxcop_00016          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00016';   -- API�N���G���[
  cv_msg_xxcop_00027          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00027';   -- �o�^�����G���[���b�Z�[�W
  cv_msg_xxcop_00028          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00028';   -- �X�V�����G���[���b�Z�[�W
  cv_msg_xxcop_00042          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00042';   -- �폜�����G���[���b�Z�[�W
  cv_msg_xxcop_00080          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00080';   -- �g�D�R�[�h�m�[�g
  cv_msg_xxcop_00081          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00081';   -- �g�D�p�����[�^�m�[�g
  cv_msg_xxcop_00094          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00094';   -- ���Y�c�ƒP�ʃm�[�g
  cv_msg_xxcop_00095          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-00095';   -- �g�D�}�X�^�m�[�g
  cv_msg_xxcop_10072          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-10072';   -- ����v����ёΔ�\���[���[�N�e�[�u���m�[�g
  cv_msg_xxcop_10073          CONSTANT VARCHAR2(16)   := 'APP-XXCOP1-10073';   -- ����v����ёΔ�\�p�����[�^�o�̓��b�Z�[�W
  -- �g�[�N���R�[�h
  cv_tkn_profile              CONSTANT VARCHAR2(20)   := 'PROF_NAME';          -- �v���t�@�C��
  cv_tkn_table                CONSTANT VARCHAR2(20)   := 'TABLE';              -- �e�[�u����
  cv_tkn_item                 CONSTANT VARCHAR2(20)   := 'ITEM';               -- ����
  cv_tkn_value                CONSTANT VARCHAR2(20)   := 'VALUE';              -- ���ڒl
  cv_tkn_prg_name             CONSTANT VARCHAR2(20)   := 'PRG_NAME';           -- �v���O������
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)   := 'ERR_MSG';            -- �G���[���e�ڍ�
  cv_tkn_target_month         CONSTANT VARCHAR2(20)   := 'TARGET_MONTH';       -- �Ώ۔N��
  cv_tkn_forecast_type        CONSTANT VARCHAR2(20)   := 'FORECAST_TYPE';      -- �v��敪
  cv_tkn_prod_class_code      CONSTANT VARCHAR2(20)   := 'PROD_CLASS_CODE';    -- ���i�敪
  cv_tkn_base_code            CONSTANT VARCHAR2(20)   := 'BASE_CODE';          -- ���_
  cv_tkn_crowd_class_code     CONSTANT VARCHAR2(20)   := 'CROWD_CLASS_CODE';   -- ����Q�R�[�h
  cv_tkn_item_code            CONSTANT VARCHAR2(20)   := 'ITEM_CODE';          -- �i�ڃR�[�h
  -- �N�C�b�N�R�[�h
  cv_flag_y                   CONSTANT VARCHAR2(1)    := 'Y';                  -- �L��
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE
                                                      := USERENV('LANG');
  -- ���t����
  cv_format_yyyymmdd          CONSTANT VARCHAR2(10)   := 'YYYY/MM/DD';
  cv_format_yyyymm            CONSTANT VARCHAR2(6)    := 'YYYYMM';
  cv_format_yyyy              CONSTANT VARCHAR2(4)    := 'YYYY';
  cv_format_mm                CONSTANT VARCHAR2(2)    := 'MM';
  cv_format_dd                CONSTANT VARCHAR2(2)    := 'DD';
  cv_format_std               CONSTANT VARCHAR2(18)   := 'YYYY/MM/DD HH24:MI';
  cv_format_svf               CONSTANT VARCHAR2(8)    := 'YYYYMMDD';
  -- �l�Z�b�g
  cv_flex_forecast_type       CONSTANT VARCHAR2(30)   := 'XXCOP1_FORECAST_TYPE';
  -- �N�C�b�N�R�[�h
  cv_lkup_exc_order_type      CONSTANT VARCHAR2(30)   := 'XXCOI1_EXCLUDE_ORDER_TYPE';
  -- API��(���b�Z�[�W�g�[�N���l)
  cv_api_err_msg_tkn_val      CONSTANT VARCHAR2(50)   := 'XXCCP_SVFCOMMON_PKG.SUBMIT_SVF_REQUEST';
  -- ���l
  cn_0                        CONSTANT NUMBER         := 0;
  cn_1                        CONSTANT NUMBER         := 1;
  cn_2                        CONSTANT NUMBER         := 2;
  cn_3                        CONSTANT NUMBER         := 3;
  cn_100                      CONSTANT NUMBER         := 100;
  cn_minus                    CONSTANT NUMBER         := -1;
  -- ���i�敪
  cv_ctg_leaf                 CONSTANT VARCHAR2(1)    := '1';                  -- ���[�t
  cv_ctg_drink                CONSTANT VARCHAR2(1)    := '2';                  -- �h�����N
  -- ���Ɋm�F�t���O
  cv_store_check_y            CONSTANT VARCHAR2(1)    := 'Y';                  -- ���Ɋm�F��
  cv_store_check_n            CONSTANT VARCHAR2(1)    := 'N';                  -- ���ɖ��m�F
  -- �T�}���[�f�[�^�t���O
  cv_summary_data_y           CONSTANT VARCHAR2(1)    := 'Y';                  -- �T�}���[�f�[�^
  -- �o�׃X�e�[�^�X
  cv_req_status_01            CONSTANT VARCHAR2(2)    := '01';                 -- ���͒�
  cv_req_status_02            CONSTANT VARCHAR2(2)    := '02';                 -- ���_�m��
  cv_req_status_03            CONSTANT VARCHAR2(2)    := '03';                 -- ���ߍς�
  cv_req_status_04            CONSTANT VARCHAR2(2)    := '04';                 -- �o�׎��ьv���
  -- �o�׎x���敪
  cv_ship_order               CONSTANT VARCHAR2(1)    := '1';                  -- �o�׈˗�
  -- �݌ɒ����敪
  cv_stock_etc                CONSTANT VARCHAR2(1)    := '1';                  -- �݌ɒ����ȊO
  cv_stock_adjm               CONSTANT VARCHAR2(1)    := '2';                  -- �݌ɒ���
  -- �󒍃J�e�S���R�[�h
  cv_order_ctg_return         CONSTANT VARCHAR2(6)    := 'RETURN';             -- �ԕi
  -- �ڋq�敪
  cv_customer_class_base      CONSTANT VARCHAR2(1)    := '1';                  -- �ڋq�敪�i���_�j
  cv_customer_class_cust      CONSTANT VARCHAR2(2)    := '10';                 -- �ڋq�敪�i�ڋq�j
  -- �q�Ƀ^�C�v
  cv_wh_type_base             CONSTANT VARCHAR2(1)    := '0';                  -- ���_�q��
  -- �폜�t���O
  cv_delete_flag_n            CONSTANT VARCHAR2(1)    := 'N';                  -- �폜�ȊO
  -- �ŐV�t���O
  cv_latest_ext_flag_y        CONSTANT VARCHAR2(1)    := 'Y';                  -- �ŐV
  -- ���ьv��t���O
  cv_act_conf_class_y         CONSTANT VARCHAR2(1)    := 'Y';                  -- ���ьv���
  -- ���[�o�͊֘A
  cv_report_id                CONSTANT VARCHAR2(100)  := 'XXCOP004A10R';       -- ���[ID
  cv_frm_file                 CONSTANT VARCHAR2(100)  := 'XXCOP004A10S.xml';   -- �t�H�[���l���t�@�C����
  cv_vrq_file                 CONSTANT VARCHAR2(100)  := 'XXCOP004A10S.vrq';   -- �N�G���[�l���t�@�C����
  cv_output_mode              CONSTANT VARCHAR2(1)    := '1';                  -- �o�͋敪(PDF)
  cv_extension_pdf            CONSTANT VARCHAR2(100)  := '.pdf';               -- �g���q(PDF)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���[�o�͑Ώۋ��_���R�[�h�^
  TYPE target_base_trec IS RECORD(
      base_code              hz_cust_accounts.account_number %TYPE  -- ���_�R�[�h
    , base_name              xxcmn_parties.party_short_name  %TYPE  -- ���_��
    );
--
  -- ���[�o�͑Ώۋ��_PL/SQL�\
  TYPE target_base_ttype IS
    TABLE OF target_base_trec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �v���t�@�C���l�i�[�p
  gd_process_date             DATE         DEFAULT NULL;                       -- �Ɩ����t
  gt_itou_ou_mfg              hr_organization_units.name%TYPE;                 -- ���Y�c�ƒP�ʎ擾����
  gt_itou_ou_id               hr_organization_units.organization_id%TYPE;      -- ���Y�g�DID
  gt_sales_org_code           mtl_parameters.organization_code%TYPE;           -- �c�Ƒg�D�R�[�h
  gt_sales_org_id             mtl_parameters.organization_id%TYPE;             -- �c�Ƒg�DID
  gt_item_div_h               mtl_category_sets_vl.category_set_name%TYPE;     -- �J�e�S���Z�b�g��(�{�Џ��i�敪)
  gt_policy_group_code        mtl_category_sets_vl.category_set_name%TYPE;     -- �J�e�S���Z�b�g��(����Q�R�[�h)
  -- ���̓p�����[�^�i�[�p
  gv_target_month             VARCHAR2(6);                                     -- �Ώ۔N��
  gv_prod_class_code          VARCHAR2(1);                                     -- ���i�敪
  gv_base_code                VARCHAR2(4);                                     -- ���_�R�[�h
  gv_forecast_type            VARCHAR2(2);                                     -- �v��敪
  gv_crowd_class_code         VARCHAR2(4);                                     -- ����Q�R�[�h
  gv_item_code                VARCHAR2(7);                                     -- �i�ڃR�[�h
  gt_prod_class_name          xxcop_prod_categories1_v.prod_class_name%TYPE;   -- ���i�敪��
  gt_forecast_type_name       fnd_flex_values_tl.description%TYPE;             -- �v��敪��
  -- �g�[�N���l�i�[�p
  gv_tkn_vl1                  VARCHAR2(5000);    -- �G���[���b�Z�[�W�p�g�[�N��1
  gv_tkn_vl2                  VARCHAR2(5000);    -- �G���[���b�Z�[�W�p�g�[�N��2
  -- �o�͑Ώۃf�[�^�i�[�p
  g_target_base_tbl           target_base_ttype; -- ���[�o�͑Ώۋ��_
--
  -- ===============================
  -- �O���[�o���J�[�\��
  -- ===============================
  -- ���R�[�h��`
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      ov_errbuf           OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode          OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg           OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���ϐ� ***
    lv_param_msg       VARCHAR2(5000);                 -- �p�����[�^�[�o�͗p
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
    -- 1�D�v��敪���擾
    --==============================================================
    -- ���̓p�����[�^����v��敪�����擾
    BEGIN
      SELECT ffvt.description  AS forecast_type_name  -- �v��敪��
      INTO   gt_forecast_type_name
      FROM   fnd_flex_values      ffv
           , fnd_flex_values_tl   ffvt
           , fnd_flex_value_sets  ffvs
      WHERE  ffv.flex_value_id        = ffvt.flex_value_id
      AND    ffvt.language            = ct_lang
      AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name = cv_flex_forecast_type
      AND    ffv.flex_value           = gv_forecast_type
      AND    ffv.enabled_flag         = cv_flag_y
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gt_forecast_type_name := NULL;
    END;
--
    --==============================================================
    -- 2�D���i�敪���擾
    --==============================================================
    -- ���̓p�����[�^���珤�i�敪�����擾
    BEGIN
      SELECT xpcv.prod_class_name  AS prod_class_name  -- ���i�敪��
      INTO   gt_prod_class_name
      FROM   xxcop_prod_categories1_v  xpcv
      WHERE  xpcv.prod_class_code     = gv_prod_class_code
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gt_prod_class_name := NULL;
    END;
--
    --==============================================================
    -- 3�D�R���J�����g���̓p�����[�^���b�Z�[�W�o��
    --==============================================================
    -- ���b�Z�[�W�ҏW
    lv_param_msg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_application            -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_xxcop_10073        -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_target_month       -- �g�[�N���R�[�h1
                      ,iv_token_value1  => gv_target_month           -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_forecast_type      -- �g�[�N���R�[�h2
                      ,iv_token_value2  => gt_forecast_type_name     -- �g�[�N���l2
                      ,iv_token_name3   => cv_tkn_prod_class_code    -- �g�[�N���R�[�h3
                      ,iv_token_value3  => gt_prod_class_name        -- �g�[�N���l3
                      ,iv_token_name4   => cv_tkn_base_code          -- �g�[�N���R�[�h4
                      ,iv_token_value4  => gv_base_code              -- �g�[�N���l4
                      ,iv_token_name5   => cv_tkn_crowd_class_code   -- �g�[�N���R�[�h5
                      ,iv_token_value5  => gv_crowd_class_code       -- �g�[�N���l5
                      ,iv_token_name6   => cv_tkn_item_code          -- �g�[�N���R�[�h6
                      ,iv_token_value6  => gv_item_code              -- �g�[�N���l6
                    );
    --
    -- ���̓p�����[�^�����O�֏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    --
    -- ��s�o��
    FND_FILE.PUT_LINE(
        which => FND_FILE.LOG
      , buff  => ''
    );
--
    --==============================================================
    -- 4�D�Ɩ����t�擾
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_application         -- �A�v���P�[�V�����Z�k��
                     ,iv_name        => cv_msg_xxcop_00065     -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 5�D�v���t�@�C���擾
    --==============================================================
    -------------------------
    -- ���Y�c�ƒP�ʎ擾����
    -------------------------
    BEGIN
      gt_itou_ou_mfg := fnd_profile.value(cv_itou_ou_mfg);
    EXCEPTION
      WHEN OTHERS THEN
        gt_itou_ou_mfg := NULL;
    END;
    -- ���Y�c�ƒP�ʎ擾���̂��擾�o���Ȃ��ꍇ
    IF ( gt_itou_ou_mfg IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcop_00002   -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_itou_ou_mfg       -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ------------------
    -- �c�Ƒg�D�R�[�h
    ------------------
    BEGIN
      gt_sales_org_code := fnd_profile.value(cv_sales_org_code);
    EXCEPTION
      WHEN OTHERS THEN
        gt_sales_org_code := NULL;
    END;
    -- �c�Ƒg�D�R�[�h���擾�o���Ȃ��ꍇ
    IF ( gt_sales_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcop_00002   -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_sales_org_code    -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ----------------------------------
    -- �J�e�S���Z�b�g��(�{�Џ��i�敪)
    ----------------------------------
    BEGIN
      gt_item_div_h := fnd_profile.value(cv_item_div_h);
    EXCEPTION
      WHEN OTHERS THEN
        gt_item_div_h := NULL;
    END;
    -- �J�e�S���Z�b�g��(�{�Џ��i�敪)���擾�o���Ȃ��ꍇ
    IF ( gt_item_div_h IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcop_00002   -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_item_div_h        -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ----------------------------------
    -- �J�e�S���Z�b�g��(����Q�R�[�h)
    ----------------------------------
    BEGIN
      gt_policy_group_code := fnd_profile.value(cv_policy_group_code);
    EXCEPTION
      WHEN OTHERS THEN
        gt_policy_group_code := NULL;
    END;
    -- �J�e�S���Z�b�g��(����Q�R�[�h)���擾�o���Ȃ��ꍇ
    IF ( gt_policy_group_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application       -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcop_00002   -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_policy_group_code -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 6�D���Y�g�DID�擾
    --==============================================================
    BEGIN
      SELECT hou.organization_id AS organization_id
      INTO   gt_itou_ou_id
      FROM   hr_organization_units hou
      WHERE  hou.name = gt_itou_ou_mfg  -- ���Y�c�ƒP�ʎ擾����
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gt_itou_ou_id := NULL;
    END;
    -- ���Y�g�DID���擾�o���Ȃ��ꍇ
    IF ( gt_itou_ou_id IS NULL ) THEN
      -- �g�[�N���l��ݒ�
      gv_tkn_vl1  := xxccp_common_pkg.get_msg(cv_application, cv_msg_xxcop_00094);
      gv_tkn_vl2  := xxccp_common_pkg.get_msg(cv_application, cv_msg_xxcop_00095);
      -- �}�X�^�`�F�b�N�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcop_00013    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item           -- �g�[�N���R�[�h1
                     ,iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_value          -- �g�[�N���R�[�h2
                     ,iv_token_value2 => gt_itou_ou_mfg        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_table          -- �g�[�N���R�[�h3
                     ,iv_token_value3 => gv_tkn_vl2            -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 7�D�c�Ƒg�DID�擾
    --==============================================================
    BEGIN
      SELECT mp.organization_id  AS organization_id
      INTO   gt_sales_org_id
      FROM   mtl_parameters mp
      WHERE  mp.organization_code = gt_sales_org_code  -- �c�Ƒg�D�R�[�h
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gt_sales_org_id := NULL;
    END;
    -- �c�Ƒg�DID���擾�o���Ȃ��ꍇ
    IF ( gt_sales_org_id IS NULL ) THEN
      -- �g�[�N���l��ݒ�
      gv_tkn_vl1  := xxccp_common_pkg.get_msg(cv_application, cv_msg_xxcop_00080);
      gv_tkn_vl2  := xxccp_common_pkg.get_msg(cv_application, cv_msg_xxcop_00081);
      -- �}�X�^�`�F�b�N�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_xxcop_00013    -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item           -- �g�[�N���R�[�h1
                     ,iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_value          -- �g�[�N���R�[�h2
                     ,iv_token_value2 => gt_sales_org_code     -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_table          -- �g�[�N���R�[�h3
                     ,iv_token_value3 => gv_tkn_vl2            -- �g�[�N���l3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
   * Procedure Name   : get_target_base_code
   * Description      : �Ώۋ��_�擾�i�z�����_�j�iA-2�j
   ***********************************************************************************/
  PROCEDURE get_target_base_code(
      ov_errbuf           OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode          OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg           OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_base_code'; -- �v���O������
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
    --  �Ǘ������_�{�z�����_���o
    --==============================================================
    -- �ڋq�}�X�^����z�����_���擾
    SELECT hca.account_number   AS base_code    -- ���_�R�[�h
         , xp.party_short_name  AS base_name    -- ���_��
    BULK COLLECT
    INTO   g_target_base_tbl
    FROM   hz_cust_accounts   hca   -- �ڋq�}�X�^
    ,      xxcmn_parties      xp    -- �p�[�e�B�A�h�I���}�X�^
    WHERE  hca.customer_class_code  =  cv_customer_class_base  -- ���_
    AND (  hca.account_number       =  gv_base_code
      OR   hca.cust_account_id  IN (SELECT xca.customer_id  AS customer_id
                                    FROM   xxcmm_cust_accounts  xca -- �ڋq�ǉ����
                                    WHERE  xca.management_base_code = gv_base_code  -- �Ǘ������_�R�[�h
                                   )
        )
    AND    xp.party_id         (+)  =  hca.party_id
    AND    xp.start_date_active(+) <= gd_process_date
    AND    xp.end_date_active  (+) >= gd_process_date
    ORDER BY hca.account_number
    ;
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
  END get_target_base_code;
--
  /**********************************************************************************
   * Procedure Name   : get_forecast_info
   * Description      : ����v�搔�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_forecast_info(
      iv_base_code        IN  VARCHAR2  -- ���_�R�[�h
    , iv_base_name        IN  VARCHAR2  -- ���_��
    , ov_errbuf           OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode          OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg           OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_forecast_info'; -- �v���O������
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
    -- *** ���[�J���J�[�\�� ***
    -- ����v����J�[�\��
    CURSOR get_forecast_info_cur
    IS
      SELECT /*+
               LEADING(mfda mfde xic1v)
             */
             TO_CHAR(mfda.forecast_date ,cv_format_yyyymm)   AS target_date
           , mfde.attribute3                                 AS base_code
           , xic1v.item_no                                   AS item_code
           , item_short_name                                 AS item_name
           , xic1v.prod_class_code                           AS prod_class_code
           , xic1v.prod_class_name                           AS prod_class_name
           , xic1v.crowd_class_code                          AS crowd_class_code
           , SUBSTRB(xic1v.crowd_class_code ,cn_1 ,cn_3)     AS crowd_class_code3
           , SUM(TO_NUMBER(mfda.attribute6))                 AS forecast_qty
      FROM   mrp_forecast_dates       mfda  -- �t�H�[�L���X�g���t
           , mrp_forecast_designators mfde  -- �t�H�[�L���X�g��
           , xxcop_item_categories1_v xic1v -- �v��_�i�ڃJ�e�S���r���[1
      WHERE  mfde.forecast_designator = mfda.forecast_designator
      AND    mfde.organization_id     = mfda.organization_id
      AND    mfda.organization_id     = xic1v.organization_id
      AND    xic1v.inventory_item_id  = mfda.inventory_item_id
      AND    mfda.forecast_date      >= TO_DATE(gv_target_month ,cv_format_yyyymm)            -- ���̓p�����[�^.�Ώ۔N��
      AND    mfda.forecast_date      <= LAST_DAY(TO_DATE(gv_target_month ,cv_format_yyyymm))  -- ���̓p�����[�^.�Ώ۔N��
      AND    mfde.attribute3          = iv_base_code                                          -- ���̓p�����[�^.���_�R�[�h
      AND    mfde.attribute1          = gv_forecast_type                                      -- ���̓p�����[�^.�v��敪
      AND    xic1v.start_date_active <= gd_process_date
      AND    xic1v.end_date_active   >= gd_process_date
      AND    xic1v.prod_class_code    = NVL(gv_prod_class_code ,xic1v.prod_class_code)        -- ���̓p�����[�^.���i�敪
      AND    xic1v.crowd_class_code   = NVL(gv_crowd_class_code ,xic1v.crowd_class_code)      -- ���̓p�����[�^.����Q�R�[�h
      AND    xic1v.item_no            = NVL(gv_item_code ,xic1v.item_no)                      -- ���̓p�����[�^.�i�ڃR�[�h
      GROUP BY TO_CHAR(mfda.forecast_date ,cv_format_yyyymm)
             , mfde.attribute3
             , xic1v.item_no
             , xic1v.item_short_name
             , xic1v.prod_class_code
             , xic1v.prod_class_name
             , xic1v.crowd_class_code
             , SUBSTRB(xic1v.crowd_class_code ,cn_1 ,cn_3)
      ;
    -- ���R�[�h��`
    get_forecast_info_rec      get_forecast_info_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===================================
    --  ����v����擾
    -- ===================================
    -- �J�[�\��OPEN
    OPEN get_forecast_info_cur;
    LOOP
      FETCH get_forecast_info_cur INTO get_forecast_info_rec;
      EXIT WHEN get_forecast_info_cur%NOTFOUND;
      -- ===================================
      --  ���[���s�p���[�N�e�[�u���o�^
      -- ===================================
      BEGIN
        INSERT INTO xxcop_rep_forecast_comp_list(
          target_month                             -- 01�F�Ώ۔N��
        , process_date                             -- 02�F�Ɩ����t
        , prod_class_code                          -- 03�F���i�敪
        , prod_class_name                          -- 04�F���i�敪��
        , base_code                                -- 05�F���_�R�[�h
        , base_name                                -- 06�F���_��
        , forecast_type                            -- 07�F�v��敪
        , forecast_type_name                       -- 08�F�v��敪��
        , crowd_class_code                         -- 09�F����Q�R�[�h
        , crowd_class_code3                        -- 10�F����Q�R�[�h(��3��)
        , item_code                                -- 11�F�i�ڃR�[�h
        , item_name                                -- 12�F�i�ږ�
        , forecast_qty                             -- 13�F����v�搔
        , stock_comp_qty                           -- 14�F���Ɋm�F���i���_���Ɂj
        , stock_order_comp_qty                     -- 15�F�˗��ϐ��i���_���Ɂj
        , ship_comp_qty                            -- 16�F����v��ϐ��i�����j
        , ship_order_comp_qty                      -- 17�F�˗��ϐ��i�����j
        , created_by                               -- 18�F�쐬��
        , creation_date                            -- 19�F�쐬��
        , last_updated_by                          -- 20�F�ŏI�X�V��
        , last_update_date                         -- 21�F�ŏI�X�V��
        , last_update_login                        -- 22�F�ŏI�X�V���O�C��
        , request_id                               -- 23�F�v��ID
        , program_application_id                   -- 24�F�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        , program_id                               -- 25�F�R���J�����g�E�v���O����ID
        , program_update_date                      -- 26�F�v���O�����X�V��
        )VALUES(
          gv_target_month                          -- 01
        , gd_process_date                          -- 02
        , get_forecast_info_rec.prod_class_code    -- 03
        , get_forecast_info_rec.prod_class_name    -- 04
        , get_forecast_info_rec.base_code          -- 05
        , iv_base_name                             -- 06
        , gv_forecast_type                         -- 07
        , gt_forecast_type_name                    -- 08
        , get_forecast_info_rec.crowd_class_code   -- 09
        , get_forecast_info_rec.crowd_class_code3  -- 10
        , get_forecast_info_rec.item_code          -- 11
        , get_forecast_info_rec.item_name          -- 12
        , get_forecast_info_rec.forecast_qty       -- 13
        , cn_0                                     -- 14
        , cn_0                                     -- 15
        , cn_0                                     -- 16
        , cn_0                                     -- 17
        , cn_created_by                            -- 18
        , SYSDATE                                  -- 19
        , cn_last_updated_by                       -- 20
        , SYSDATE                                  -- 21
        , cn_last_update_login                     -- 22
        , cn_request_id                            -- 23
        , cn_program_application_id                -- 24
        , cn_program_id                            -- 25
        , SYSDATE                                  -- 26
        );
      --
      EXCEPTION
        WHEN OTHERS THEN
          -- �g�[�N���l��ݒ�
          gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
          -- �o�^�����G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcop_00027    -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
    END LOOP;
    CLOSE get_forecast_info_cur;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\��CLOSE
      IF (get_forecast_info_cur%ISOPEN) THEN
        CLOSE get_forecast_info_cur;
      END IF;
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
  END get_forecast_info;
--
  /**********************************************************************************
   * Procedure Name   : get_stock_comp_info
   * Description      : ���Ɋm�F��(���_����)�擾����(A-4)
   ***********************************************************************************/
  PROCEDURE get_stock_comp_info(
      iv_base_code        IN  VARCHAR2  -- ���_�R�[�h
    , iv_base_name        IN  VARCHAR2  -- ���_��
    , ov_errbuf           OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode          OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg           OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_comp_info'; -- �v���O������
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
    ln_dummy   NUMBER;         -- �_�~�[�ϐ�
--
    -- *** ���[�J���J�[�\�� ***
    -- ���Ɋm�F��(���_����)�擾�J�[�\��
    CURSOR get_stock_comp_info_cur
    IS
      SELECT /*
              + LEADING(xsi)
             */
             TO_CHAR(xsi.slip_date ,cv_format_yyyymm)    AS target_month
           , xsi.base_code                               AS base_code
           , xsi.item_code                               AS item_code
           , ximb.item_short_name                        AS item_name
           , xacv1.segment1                              AS prod_class_code
           , xacv1.description                           AS prod_class_name
           , xacv2.segment1                              AS crowd_class_code
           , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)         AS crowd_class_code3
           , CASE
               -- ���[�t�̏ꍇ�A�m�F���ʑ��o�����������_�ȉ�1�ʂŐ؂�̂�
               WHEN xacv1.segment1 = cv_ctg_leaf
                 THEN
                   TRUNC(SUM(xsi.check_summary_qty), cn_0)
               -- �h�����N�̏ꍇ�A�m�F���ʃP�[�X���������_�ȉ�1�ʂŐ؂�̂�
               WHEN xacv1.segment1 = cv_ctg_drink
                 THEN
                   TRUNC(SUM(xsi.check_case_qty), cn_0)
             END                                         AS stock_comp_qty
      FROM   xxcoi_storage_information xsi   -- ���ɏ��ꎞ�\
           , mtl_system_items_b        msib  -- Disc�i��
           , xxcmn_item_mst_b          ximb  -- OPM�i�ڃA�h�I��
           , ic_item_mst_b             iimb  -- OPM�i��
           , mtl_item_categories       mic1  -- �J�e�S������
           , xxcop_all_categories_v    xacv1 -- �S�i�ڃJ�e�S���r���[
           , mtl_item_categories       mic2  -- �J�e�S������
           , xxcop_all_categories_v    xacv2 -- �S�i�ڃJ�e�S���r���[
      WHERE  msib.segment1           = xsi.item_code
      AND    msib.organization_id    = gt_sales_org_id        -- �c�Ƒg�D
      AND    msib.segment1           = iimb.item_no
      AND    iimb.item_id            = ximb.item_id
      AND    ximb.start_date_active <= gd_process_date
      AND    ximb.end_date_active   >= gd_process_date
      AND    mic1.inventory_item_id  = msib.inventory_item_id
      AND    mic1.organization_id    = msib.organization_id
      AND    mic1.category_set_id    = xacv1.category_set_id
      AND    mic1.category_id        = xacv1.category_id
      AND    xacv1.category_set_name = gt_item_div_h          -- �{�Џ��i�敪
      AND    mic2.inventory_item_id  = msib.inventory_item_id
      AND    mic2.organization_id    = msib.organization_id
      AND    mic2.category_set_id    = xacv2.category_set_id
      AND    mic2.category_id        = xacv2.category_id
      AND    xacv2.category_set_name = gt_policy_group_code   -- ����Q�R�[�h
      AND    xsi.store_check_flag    = cv_store_check_y       -- ���Ɋm�F��
      AND    xsi.summary_data_flag   = cv_summary_data_y      -- �T�}���[�f�[�^
      AND    xsi.slip_date          >= TO_DATE(gv_target_month, cv_format_yyyymm)           -- ���̓p�����[�^.�Ώ۔N��
      AND    xsi.slip_date          <= LAST_DAY(TO_DATE(gv_target_month, cv_format_yyyymm)) -- ���̓p�����[�^.�Ώ۔N��
      AND    xsi.base_code           = iv_base_code                                         -- ���̓p�����[�^.���_
      AND    xsi.item_code           = NVL(gv_item_code, xsi.item_code)                     -- ���̓p�����[�^.�i�ڃR�[�h
      AND    xacv1.segment1          = NVL(gv_prod_class_code  ,xacv1.segment1)             -- ���̓p�����[�^.���i�敪
      AND    xacv2.segment1          = NVL(gv_crowd_class_code ,xacv2.segment1)             -- ���̓p�����[�^.����Q�R�[�h
      GROUP BY TO_CHAR(xsi.slip_date, cv_format_yyyymm)
             , xsi.base_code
             , xsi.item_code
             , ximb.item_short_name
             , xacv1.segment1
             , xacv1.description
             , xacv2.segment1
             , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)
      ;
    -- ���R�[�h��`
    get_stock_comp_info_rec   get_stock_comp_info_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===================================
    --  ���Ɋm�F��(���_����)�擾
    -- ===================================
    -- �J�[�\��OPEN
    OPEN get_stock_comp_info_cur;
    LOOP
      FETCH get_stock_comp_info_cur INTO get_stock_comp_info_rec;
      EXIT WHEN get_stock_comp_info_cur%NOTFOUND;
      --
      -- ======================================
      --  ���[���s�p���[�N�e�[�u�����݃`�F�b�N
      -- ======================================
      BEGIN
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcop_rep_forecast_comp_list xrfcl
        WHERE  xrfcl.target_month = get_stock_comp_info_rec.target_month
        AND    xrfcl.base_code    = get_stock_comp_info_rec.base_code
        AND    xrfcl.item_code    = get_stock_comp_info_rec.item_code
        AND    xrfcl.request_id   = cn_request_id
        ;
        -- ======================================
        --  ���[���s�p���[�N�e�[�u���X�V
        -- ======================================
        UPDATE xxcop_rep_forecast_comp_list xrfcl
        SET    xrfcl.stock_comp_qty = xrfcl.stock_comp_qty
                                    + get_stock_comp_info_rec.stock_comp_qty
        WHERE  xrfcl.target_month   = get_stock_comp_info_rec.target_month
        AND    xrfcl.base_code      = get_stock_comp_info_rec.base_code
        AND    xrfcl.item_code      = get_stock_comp_info_rec.item_code
        AND    xrfcl.request_id     = cn_request_id
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  ���[���s�p���[�N�e�[�u���o�^
          -- ===================================
          BEGIN
            INSERT INTO xxcop_rep_forecast_comp_list(
              target_month                               -- 01�F�Ώ۔N��
            , process_date                               -- 02�F�Ɩ����t
            , prod_class_code                            -- 03�F���i�敪
            , prod_class_name                            -- 04�F���i�敪��
            , base_code                                  -- 05�F���_�R�[�h
            , base_name                                  -- 06�F���_��
            , forecast_type                              -- 07�F�v��敪
            , forecast_type_name                         -- 08�F�v��敪��
            , crowd_class_code                           -- 09�F����Q�R�[�h
            , crowd_class_code3                          -- 10�F����Q�R�[�h(��3��)
            , item_code                                  -- 11�F�i�ڃR�[�h
            , item_name                                  -- 12�F�i�ږ�
            , forecast_qty                               -- 13�F����v�搔
            , stock_comp_qty                             -- 14�F���Ɋm�F���i���_���Ɂj
            , stock_order_comp_qty                       -- 15�F�˗��ϐ��i���_���Ɂj
            , ship_comp_qty                              -- 16�F����v��ϐ��i�����j
            , ship_order_comp_qty                        -- 17�F�˗��ϐ��i�����j
            , created_by                                 -- 18�F�쐬��
            , creation_date                              -- 19�F�쐬��
            , last_updated_by                            -- 20�F�ŏI�X�V��
            , last_update_date                           -- 21�F�ŏI�X�V��
            , last_update_login                          -- 22�F�ŏI�X�V���O�C��
            , request_id                                 -- 23�F�v��ID
            , program_application_id                     -- 24�F�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            , program_id                                 -- 25�F�R���J�����g�E�v���O����ID
            , program_update_date                        -- 26�F�v���O�����X�V��
            ) VALUES(
              gv_target_month                            -- 01
            , gd_process_date                            -- 02
            , get_stock_comp_info_rec.prod_class_code    -- 03
            , get_stock_comp_info_rec.prod_class_name    -- 04
            , get_stock_comp_info_rec.base_code          -- 05
            , iv_base_name                               -- 06
            , gv_forecast_type                           -- 07
            , gt_forecast_type_name                      -- 08
            , get_stock_comp_info_rec.crowd_class_code   -- 09
            , get_stock_comp_info_rec.crowd_class_code3  -- 10
            , get_stock_comp_info_rec.item_code          -- 11
            , get_stock_comp_info_rec.item_name          -- 12
            , cn_0                                       -- 13
            , get_stock_comp_info_rec.stock_comp_qty     -- 14
            , cn_0                                       -- 15
            , cn_0                                       -- 16
            , cn_0                                       -- 17
            , cn_created_by                              -- 18
            , SYSDATE                                    -- 19
            , cn_last_updated_by                         -- 20
            , SYSDATE                                    -- 21
            , cn_last_update_login                       -- 22
            , cn_request_id                              -- 23
            , cn_program_application_id                  -- 24
            , cn_program_id                              -- 25
            , SYSDATE                                    -- 26
            );
            -- �Ώی����J�E���g
            gn_target_cnt := gn_target_cnt + 1;
          --
          EXCEPTION
            WHEN OTHERS THEN
              -- �g�[�N���l��ݒ�
              gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
              -- �o�^�����G���[���b�Z�[�W
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_xxcop_00027    -- ���b�Z�[�W�R�[�h
                             , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                             , iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        WHEN OTHERS THEN
          -- �g�[�N���l��ݒ�
          gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
          -- �X�V�����G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcop_00028    -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      --
      END;
    END LOOP;
--
    CLOSE get_stock_comp_info_cur;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\��CLOSE
      IF (get_stock_comp_info_cur%ISOPEN) THEN
        CLOSE get_stock_comp_info_cur;
      END IF;
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
  END get_stock_comp_info;
--
  /**********************************************************************************
   * Procedure Name   : get_stock_order_comp_info
   * Description      : �˗��ϐ�(���_���Ɂ|���_������)�擾����(A-5)
   ***********************************************************************************/
  PROCEDURE get_stock_order_comp_info(
      iv_base_code        IN  VARCHAR2  -- ���_�R�[�h
    , iv_base_name        IN  VARCHAR2  -- ���_��
    , ov_errbuf           OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode          OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg           OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_stock_order_comp_info'; -- �v���O������
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
    ln_dummy   NUMBER;         -- �_�~�[�ϐ�
--
    -- *** ���[�J���J�[�\�� ***
    -- �˗��ϐ�(���_���Ɂ|���_������)�擾�J�[�\��
    CURSOR get_stock_order_comp_info_cur
    IS
      SELECT /*+
               LEADING(xsi)
             */
             TO_CHAR(xsi.slip_date ,cv_format_yyyymm)    AS target_month
           , xsi.base_code                               AS base_code
           , xsi.item_code                               AS item_code
           , ximb.item_short_name                        AS item_name
           , xacv1.segment1                              AS prod_class_code
           , xacv1.description                           AS prod_class_name
           , xacv2.segment1                              AS crowd_class_code
           , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)         AS crowd_class_code3
           , CASE
               -- ���[�t�̏ꍇ�A�o�ɐ��ʑ��o�����������_�ȉ�1�ʂŐ؂�̂�
               WHEN xacv1.segment1 = cv_ctg_leaf
                 THEN
                   TRUNC(SUM(xsi.ship_summary_qty), cn_0)
               -- �h�����N�̏ꍇ�A�o�ɐ��ʃP�[�X���������_�ȉ�1�ʂŐ؂�̂�
               WHEN xacv1.segment1 = cv_ctg_drink
                 THEN
                   TRUNC(SUM(xsi.ship_case_qty), cn_0)
             END                                         AS stock_order_comp_qty
      FROM   xxcoi_storage_information xsi   -- ���ɏ��ꎞ�\
           , mtl_system_items_b        msib  -- Disc�i��
           , xxcmn_item_mst_b          ximb  -- OPM�i�ڃA�h�I��
           , ic_item_mst_b             iimb  -- OPM�i��
           , mtl_item_categories       mic1  -- �J�e�S������
           , xxcop_all_categories_v    xacv1 -- �S�i�ڃJ�e�S���r���[
           , mtl_item_categories       mic2  -- �J�e�S������
           , xxcop_all_categories_v    xacv2 -- �S�i�ڃJ�e�S���r���[
      WHERE  msib.segment1           = xsi.item_code
      AND    msib.organization_id    = gt_sales_org_id        -- �c�Ƒg�D
      AND    msib.segment1           = iimb.item_no
      AND    iimb.item_id            = ximb.item_id
      AND    ximb.start_date_active <= gd_process_date
      AND    ximb.end_date_active   >= gd_process_date
      AND    mic1.inventory_item_id  = msib.inventory_item_id
      AND    mic1.organization_id    = msib.organization_id
      AND    mic1.category_set_id    = xacv1.category_set_id
      AND    mic1.category_id        = xacv1.category_id
      AND    xacv1.category_set_name = gt_item_div_h          -- �{�Џ��i�敪
      AND    mic2.inventory_item_id  = msib.inventory_item_id
      AND    mic2.organization_id    = msib.organization_id
      AND    mic2.category_set_id    = xacv2.category_set_id
      AND    mic2.category_id        = xacv2.category_id
      AND    xacv2.category_set_name = gt_policy_group_code   -- ����Q�R�[�h
      AND    xsi.store_check_flag    = cv_store_check_n       -- ���ɖ��m�F
      AND    xsi.summary_data_flag   = cv_summary_data_y      -- �T�}���[�f�[�^
      AND    xsi.req_status          = cv_req_status_04       -- �o�׎��ьv���
      AND    xsi.slip_date          >= TO_DATE(gv_target_month ,cv_format_yyyymm)           -- ���̓p�����[�^.�Ώ۔N��
      AND    xsi.slip_date          <= LAST_DAY(TO_DATE(gv_target_month ,cv_format_yyyymm)) -- ���̓p�����[�^.�Ώ۔N��
      AND    xsi.base_code           = iv_base_code                                         -- ���̓p�����[�^.���_
      AND    xsi.item_code           = NVL(gv_item_code ,xsi.item_code)                     -- ���̓p�����[�^.���i�R�[�h
      AND    xacv1.segment1          = NVL(gv_prod_class_code  ,xacv1.segment1)             -- ���̓p�����[�^.���i�敪
      AND    xacv2.segment1          = NVL(gv_crowd_class_code ,xacv2.segment1)             -- ���̓p�����[�^.����Q�R�[�h
      GROUP BY TO_CHAR(xsi.slip_date, cv_format_yyyymm)
             , xsi.base_code
             , xsi.item_code
             , ximb.item_short_name
             , xacv1.segment1
             , xacv1.description
             , xacv2.segment1
             , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)
      ;
    -- ���R�[�h��`
    get_stock_order_comp_info_rec   get_stock_order_comp_info_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===================================
    --  �˗��ϐ�(���_���Ɂ|���_������)�擾
    -- ===================================
    -- �J�[�\��OPEN
    OPEN get_stock_order_comp_info_cur;
    LOOP
      FETCH get_stock_order_comp_info_cur INTO get_stock_order_comp_info_rec;
      EXIT WHEN get_stock_order_comp_info_cur%NOTFOUND;
      --
      -- ======================================
      --  ���[���s�p���[�N�e�[�u�����݃`�F�b�N
      -- ======================================
      BEGIN
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcop_rep_forecast_comp_list xrfcl
        WHERE  xrfcl.target_month = get_stock_order_comp_info_rec.target_month
        AND    xrfcl.base_code    = get_stock_order_comp_info_rec.base_code
        AND    xrfcl.item_code    = get_stock_order_comp_info_rec.item_code
        AND    xrfcl.request_id   = cn_request_id
        ;
        -- ======================================
        --  ���[���s�p���[�N�e�[�u���X�V
        -- ======================================
        UPDATE xxcop_rep_forecast_comp_list xrfcl
        SET    xrfcl.stock_order_comp_qty = xrfcl.stock_order_comp_qty
                                          + get_stock_order_comp_info_rec.stock_order_comp_qty
        WHERE  xrfcl.target_month         = get_stock_order_comp_info_rec.target_month
        AND    xrfcl.base_code            = get_stock_order_comp_info_rec.base_code
        AND    xrfcl.item_code            = get_stock_order_comp_info_rec.item_code
        AND    xrfcl.request_id           = cn_request_id
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  ���[���s�p���[�N�e�[�u���o�^
          -- ===================================
          BEGIN
            INSERT INTO xxcop_rep_forecast_comp_list(
              target_month                                        -- 01�F�Ώ۔N��
            , process_date                                        -- 02�F�Ɩ����t
            , prod_class_code                                     -- 03�F���i�敪
            , prod_class_name                                     -- 04�F���i�敪��
            , base_code                                           -- 05�F���_�R�[�h
            , base_name                                           -- 06�F���_��
            , forecast_type                                       -- 07�F�v��敪
            , forecast_type_name                                  -- 08�F�v��敪��
            , crowd_class_code                                    -- 09�F����Q�R�[�h
            , crowd_class_code3                                   -- 10�F����Q�R�[�h(��3��)
            , item_code                                           -- 11�F�i�ڃR�[�h
            , item_name                                           -- 12�F�i�ږ�
            , forecast_qty                                        -- 13�F����v�搔
            , stock_comp_qty                                      -- 14�F���Ɋm�F���i���_���Ɂj
            , stock_order_comp_qty                                -- 15�F�˗��ϐ��i���_���Ɂj
            , ship_comp_qty                                       -- 16�F����v��ϐ��i�����j
            , ship_order_comp_qty                                 -- 17�F�˗��ϐ��i�����j
            , created_by                                          -- 18�F�쐬��
            , creation_date                                       -- 19�F�쐬��
            , last_updated_by                                     -- 20�F�ŏI�X�V��
            , last_update_date                                    -- 21�F�ŏI�X�V��
            , last_update_login                                   -- 22�F�ŏI�X�V���O�C��
            , request_id                                          -- 23�F�v��ID
            , program_application_id                              -- 24�F�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            , program_id                                          -- 25�F�R���J�����g�E�v���O����ID
            , program_update_date                                 -- 26�F�v���O�����X�V��
            ) VALUES(
              gv_target_month                                     -- 01
            , gd_process_date                                     -- 02
            , get_stock_order_comp_info_rec.prod_class_code       -- 03
            , get_stock_order_comp_info_rec.prod_class_name       -- 04
            , get_stock_order_comp_info_rec.base_code             -- 05
            , iv_base_name                                        -- 06
            , gv_forecast_type                                    -- 07
            , gt_forecast_type_name                               -- 08
            , get_stock_order_comp_info_rec.crowd_class_code      -- 09
            , get_stock_order_comp_info_rec.crowd_class_code3     -- 10
            , get_stock_order_comp_info_rec.item_code             -- 11
            , get_stock_order_comp_info_rec.item_name             -- 12
            , cn_0                                                -- 13
            , cn_0                                                -- 14
            , get_stock_order_comp_info_rec.stock_order_comp_qty  -- 15
            , cn_0                                                -- 16
            , cn_0                                                -- 17
            , cn_created_by                                       -- 18
            , SYSDATE                                             -- 19
            , cn_last_updated_by                                  -- 20
            , SYSDATE                                             -- 21
            , cn_last_update_login                                -- 22
            , cn_request_id                                       -- 23
            , cn_program_application_id                           -- 24
            , cn_program_id                                       -- 25
            , SYSDATE                                             -- 26
            );
            -- �Ώی����J�E���g
            gn_target_cnt := gn_target_cnt + 1;
          --
          EXCEPTION
            WHEN OTHERS THEN
              -- �g�[�N���l��ݒ�
              gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
              -- �o�^�����G���[���b�Z�[�W
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_xxcop_00027    -- ���b�Z�[�W�R�[�h
                             , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                             , iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        WHEN OTHERS THEN
          -- �g�[�N���l��ݒ�
          gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
          -- �X�V�����G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcop_00028    -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      --
      END;
    END LOOP;
--
    CLOSE get_stock_order_comp_info_cur;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\��CLOSE
      IF (get_stock_order_comp_info_cur%ISOPEN) THEN
        CLOSE get_stock_order_comp_info_cur;
      END IF;
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
  END get_stock_order_comp_info;
--
  /**********************************************************************************
   * Procedure Name   : get_stock_fact_ship_info
   * Description      : �˗��ϐ�(���_���Ɂ|�H�ꖢ�o��)�擾����(A-6)
   ***********************************************************************************/
  PROCEDURE get_stock_fact_ship_info(
      iv_base_code        IN  VARCHAR2  -- ���_�R�[�h
    , iv_base_name        IN  VARCHAR2  -- ���_��
    , ov_errbuf           OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode          OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg           OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_comp_info'; -- �v���O������
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
    ln_dummy   NUMBER;         -- �_�~�[�ϐ�
--
    -- *** ���[�J���J�[�\�� ***
    -- �˗��ϐ�(���_���Ɂ|�H�ꖢ�o��)�擾�J�[�\��
    CURSOR get_stock_fact_ship_info_cur
    IS
      SELECT /*+
               LEADING(ottt otta xoha hps hca)
             */
             TO_CHAR(xoha.schedule_arrival_date ,cv_format_yyyymm)  AS target_month
           , xca.sale_base_code                                     AS base_code
           , iimb.item_no                                           AS item_code
           , ximb.item_short_name                                   AS item_name
           , xacv1.segment1                                         AS prod_class_code
           , xacv1.description                                      AS prod_class_name
           , xacv2.segment1                                         AS crowd_class_code
           , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)                    AS crowd_class_code3
           , CASE
               -- ���[�t�̏ꍇ�A���ʂ������_�ȉ�1�ʂŐ؂�̂�
               WHEN xacv1.segment1 = cv_ctg_leaf
                 THEN
                   TRUNC(SUM(NVL(xola.quantity, cn_0)
                             -- �󒍃J�e�S���R�[�h�Ő�������ݒ�
                             * DECODE(otta.order_category_code
                                    , cv_order_ctg_return  -- RETURN�̏ꍇ�A�}�C�i�X���|����
                                    , cn_minus
                                    , cn_1
                               )
                         )
                   , cn_0
                   )
               -- �h�����N�̏ꍇ�A���ʂ��P�[�X���Z�������_�ȉ�1�ʂŐ؂�̂�
               WHEN xacv1.segment1 = cv_ctg_drink
                 THEN
                   TRUNC(SUM(NVL(xola.quantity, cn_0) / NVL(TO_NUMBER(iimb.attribute11) ,cn_1)
                             -- �󒍃J�e�S���R�[�h�Ő�������ݒ�
                             * DECODE(otta.order_category_code
                                    , cv_order_ctg_return  -- RETURN�̏ꍇ�A�}�C�i�X���|����
                                    , cn_minus
                                    , cn_1
                               )
                         )
                   , cn_0
                   )
             END                                                    AS stock_order_comp_qty
      FROM   xxwsh_order_headers_all   xoha  -- �󒍃w�b�_�A�h�I��
           , xxwsh_order_lines_all     xola  -- �󒍖��׃A�h�I��
           , mtl_system_items_b        msib  -- Disc�i�ڃ}�X�^
           , xxcmn_item_mst_b          ximb  -- OPM�i�ڃA�h�I���}�X�^
           , ic_item_mst_b             iimb  -- OPM�i�ڃ}�X�^
           , mtl_item_categories       mic1  -- �J�e�S������
           , xxcop_all_categories_v    xacv1 -- �S�i�ڃJ�e�S���r���[
           , mtl_item_categories       mic2  -- �J�e�S������
           , xxcop_all_categories_v    xacv2 -- �S�i�ڃJ�e�S���r���[
           , oe_transaction_types_all  otta  -- ����^�C�v
           , oe_transaction_types_tl   ottt  -- ����^�C�v�ڍ�
           , hz_party_sites            hps   -- �p�[�e�B�T�C�g
           , hz_cust_accounts          hca   -- �ڋq�}�X�^
           , xxcmm_cust_accounts       xca   -- �ڋq�ǉ����
           , hz_locations              hl    -- ���Ə��}�X�^
      WHERE  xoha.order_header_id        = xola.order_header_id
      AND    xola.request_item_id        = msib.inventory_item_id
      AND    msib.segment1               = iimb.item_no
      AND    iimb.item_id                = ximb.item_id
      AND    xoha.order_type_id          = ottt.transaction_type_id
      AND    ottt.transaction_type_id    = otta.transaction_type_id
      AND    hps.party_id                = hca.party_id
      AND    hca.cust_account_id         = xca.customer_id
      AND    msib.organization_id        = gt_sales_org_id        -- �c�Ƒg�DID
      AND    mic1.inventory_item_id      = msib.inventory_item_id
      AND    mic1.organization_id        = msib.organization_id
      AND    mic1.category_set_id        = xacv1.category_set_id
      AND    mic1.category_id            = xacv1.category_id
      AND    xacv1.category_set_name     = gt_item_div_h          -- �{�Џ��i�敪
      AND    mic2.inventory_item_id      = msib.inventory_item_id
      AND    mic2.organization_id        = msib.organization_id
      AND    mic2.category_set_id        = xacv2.category_set_id
      AND    mic2.category_id            = xacv2.category_id
      AND    xacv2.category_set_name     = gt_policy_group_code   -- ����Q�R�[�h
      AND    otta.org_id                 = gt_itou_ou_id          -- ���Y�g�DID
      AND    otta.attribute1             = cv_ship_order          -- �o�׈˗�
      AND    NVL(otta.attribute4 ,cv_stock_etc)
                                        <> cv_stock_adjm          -- �݌ɒ����ȊO
      AND    ottt.language               = ct_lang
      AND    hps.location_id             = hl.location_id
      AND    SUBSTRB(hl.province, cn_1, cn_1)
                                         = cv_wh_type_base        -- ���_�q��
      AND    hca.customer_class_code     = cv_customer_class_base -- �ڋq�敪�F���_
      AND    NVL(xola.delete_flag, cv_delete_flag_n)
                                         = cv_delete_flag_n       -- N�F�폜�ȊO
      AND    xoha.latest_external_flag   = cv_latest_ext_flag_y   -- Y�F�ŐV
      AND    xca.sale_base_code          = iv_base_code           -- ���̓p�����[�^.���_
      AND    iimb.item_no                = NVL(gv_item_code ,iimb.item_no) -- ���̓p�����[�^.�i�ڃR�[�h
      AND    xoha.req_status             IN (cv_req_status_01      -- 01�F���͒�
                                           , cv_req_status_02      -- 02�F���_�m��
                                           , cv_req_status_03)     -- 03�F���ߍς�
      AND    xoha.deliver_to_id          = hps.party_site_id
      AND    ximb.start_date_active     <= gd_process_date
      AND    ximb.end_date_active       >= gd_process_date
      AND    xoha.schedule_arrival_date >= TO_DATE(gv_target_month, cv_format_yyyymm)           -- ���̓p�����[�^.�Ώ۔N��
      AND    xoha.schedule_arrival_date <= LAST_DAY(TO_DATE(gv_target_month, cv_format_yyyymm)) -- ���̓p�����[�^.�Ώ۔N��
      AND    xacv1.segment1              = NVL(gv_prod_class_code  ,xacv1.segment1)             -- ���̓p�����[�^.���i�敪
      AND    xacv2.segment1              = NVL(gv_crowd_class_code ,xacv2.segment1)             -- ���̓p�����[�^.����Q�R�[�h
      AND NOT EXISTS ( SELECT '1'  AS dummy
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type        = cv_lkup_exc_order_type -- ���ɏ�񒊏o�ΏۊO�󒍃^�C�v
                       AND    flv.enabled_flag       = cv_flag_y
                       AND    flv.language           = ct_lang
                       AND    flv.start_date_active <= gd_process_date
                       AND    NVL(flv.end_date_active ,gd_process_date)
                                                    >= gd_process_date
                       AND    ottt.name              = flv.meaning
                     )
      GROUP BY TO_CHAR(xoha.schedule_arrival_date ,cv_format_yyyymm)
             , xca.sale_base_code
             , iimb.item_no
             , ximb.item_short_name
             , xacv1.segment1
             , xacv1.description
             , xacv2.segment1
             , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)
             , otta.order_category_code
      ;
    -- ���R�[�h��`
    get_stock_fact_ship_info_rec   get_stock_fact_ship_info_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===================================
    --  �˗��ϐ�(���_���Ɂ|�H�ꖢ�o��)�擾
    -- ===================================
    -- �J�[�\��OPEN
    OPEN get_stock_fact_ship_info_cur;
    LOOP
      FETCH get_stock_fact_ship_info_cur INTO get_stock_fact_ship_info_rec;
      EXIT WHEN get_stock_fact_ship_info_cur%NOTFOUND;
      --
      -- ======================================
      --  ���[���s�p���[�N�e�[�u�����݃`�F�b�N
      -- ======================================
      BEGIN
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcop_rep_forecast_comp_list xrfcl
        WHERE  xrfcl.target_month = get_stock_fact_ship_info_rec.target_month
        AND    xrfcl.base_code    = get_stock_fact_ship_info_rec.base_code
        AND    xrfcl.item_code    = get_stock_fact_ship_info_rec.item_code
        AND    xrfcl.request_id   = cn_request_id
        ;
        -- ======================================
        --  ���[���s�p���[�N�e�[�u���X�V
        -- ======================================
        UPDATE xxcop_rep_forecast_comp_list xrfcl
        SET    xrfcl.stock_order_comp_qty = xrfcl.stock_order_comp_qty
                                          + get_stock_fact_ship_info_rec.stock_order_comp_qty
        WHERE  xrfcl.target_month         = get_stock_fact_ship_info_rec.target_month
        AND    xrfcl.base_code            = get_stock_fact_ship_info_rec.base_code
        AND    xrfcl.item_code            = get_stock_fact_ship_info_rec.item_code
        AND    xrfcl.request_id           = cn_request_id
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  ���[���s�p���[�N�e�[�u���o�^
          -- ===================================
          BEGIN
            INSERT INTO xxcop_rep_forecast_comp_list(
              target_month                                       -- 01�F�Ώ۔N��
            , process_date                                       -- 02�F�Ɩ����t
            , prod_class_code                                    -- 03�F���i�敪
            , prod_class_name                                    -- 04�F���i�敪��
            , base_code                                          -- 05�F���_�R�[�h
            , base_name                                          -- 06�F���_��
            , forecast_type                                      -- 07�F�v��敪
            , forecast_type_name                                 -- 08�F�v��敪��
            , crowd_class_code                                   -- 09�F����Q�R�[�h
            , crowd_class_code3                                  -- 10�F����Q�R�[�h(��3��)
            , item_code                                          -- 11�F�i�ڃR�[�h
            , item_name                                          -- 12�F�i�ږ�
            , forecast_qty                                       -- 13�F����v�搔
            , stock_comp_qty                                     -- 14�F���Ɋm�F���i���_���Ɂj
            , stock_order_comp_qty                               -- 15�F�˗��ϐ��i���_���Ɂj
            , ship_comp_qty                                      -- 16�F����v��ϐ��i�����j
            , ship_order_comp_qty                                -- 17�F�˗��ϐ��i�����j
            , created_by                                         -- 18�F�쐬��
            , creation_date                                      -- 19�F�쐬��
            , last_updated_by                                    -- 20�F�ŏI�X�V��
            , last_update_date                                   -- 21�F�ŏI�X�V��
            , last_update_login                                  -- 22�F�ŏI�X�V���O�C��
            , request_id                                         -- 23�F�v��ID
            , program_application_id                             -- 24�F�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            , program_id                                         -- 25�F�R���J�����g�E�v���O����ID
            , program_update_date                                -- 26�F�v���O�����X�V��
            ) VALUES(
              gv_target_month                                    -- 01
            , gd_process_date                                    -- 02
            , get_stock_fact_ship_info_rec.prod_class_code       -- 03
            , get_stock_fact_ship_info_rec.prod_class_name       -- 04
            , get_stock_fact_ship_info_rec.base_code             -- 05
            , iv_base_name                                       -- 06
            , gv_forecast_type                                   -- 07
            , gt_forecast_type_name                              -- 08
            , get_stock_fact_ship_info_rec.crowd_class_code      -- 09
            , get_stock_fact_ship_info_rec.crowd_class_code3     -- 10
            , get_stock_fact_ship_info_rec.item_code             -- 11
            , get_stock_fact_ship_info_rec.item_name             -- 12
            , cn_0                                               -- 13
            , cn_0                                               -- 14
            , get_stock_fact_ship_info_rec.stock_order_comp_qty  -- 15
            , cn_0                                               -- 16
            , cn_0                                               -- 17
            , cn_created_by                                      -- 18
            , SYSDATE                                            -- 19
            , cn_last_updated_by                                 -- 20
            , SYSDATE                                            -- 21
            , cn_last_update_login                               -- 22
            , cn_request_id                                      -- 23
            , cn_program_application_id                          -- 24
            , cn_program_id                                      -- 25
            , SYSDATE                                            -- 26
            );
            -- �Ώی����J�E���g
            gn_target_cnt := gn_target_cnt + 1;
          --
          EXCEPTION
            WHEN OTHERS THEN
              -- �g�[�N���l��ݒ�
              gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
              -- �o�^�����G���[���b�Z�[�W
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_xxcop_00027    -- ���b�Z�[�W�R�[�h
                             , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                             , iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        WHEN OTHERS THEN
          -- �g�[�N���l��ݒ�
          gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
          -- �X�V�����G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcop_00028    -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      --
      END;
    END LOOP;
--
    CLOSE get_stock_fact_ship_info_cur;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\��CLOSE
      IF (get_stock_fact_ship_info_cur%ISOPEN) THEN
        CLOSE get_stock_fact_ship_info_cur;
      END IF;
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
  END get_stock_fact_ship_info;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_comp_info
   * Description      : ����v��ϐ��擾����(A-7)
   ***********************************************************************************/
  PROCEDURE get_ship_comp_info(
      iv_base_code        IN  VARCHAR2  -- ���_�R�[�h
    , iv_base_name        IN  VARCHAR2  -- ���_��
    , ov_errbuf           OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode          OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg           OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_comp_info'; -- �v���O������
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
    ln_dummy   NUMBER;         -- �_�~�[�ϐ�
--
    -- *** ���[�J���J�[�\�� ***
    -- ����v��ϐ��擾�J�[�\��
    CURSOR get_ship_comp_info_cur
    IS
      SELECT /*+
               LEADING(ottt otta xoha hps hca)
             */
             TO_CHAR(xoha.arrival_date ,cv_format_yyyymm)  AS target_month
           , xca.sale_base_code                            AS base_code
           , iimb.item_no                                  AS item_code
           , ximb.item_short_name                          AS item_name
           , xacv1.segment1                                AS prod_class_code
           , xacv1.description                             AS prod_class_name
           , xacv2.segment1                                AS crowd_class_code
           , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)           AS crowd_class_code3
           , CASE
               -- ���[�t�̏ꍇ�A�o�׎��ѐ��ʂ������_�ȉ�1�ʂŐ؂�̂�
               WHEN xacv1.segment1 = cv_ctg_leaf
                 THEN
                   TRUNC(SUM(NVL(xola.shipped_quantity, cn_0)
                             -- �󒍃J�e�S���R�[�h�Ő�������ݒ�
                             * DECODE(otta.order_category_code
                                    , cv_order_ctg_return  -- RETURN�̏ꍇ�A�}�C�i�X���|����
                                    , cn_minus
                                    , cn_1
                               )
                         )
                   , cn_0
                   )
               -- �h�����N�̏ꍇ�A�o�׎��ѐ��ʂ��P�[�X���Z�������_�ȉ�1�ʂŐ؂�̂�
               WHEN xacv1.segment1 = cv_ctg_drink
                 THEN
                   TRUNC(SUM(NVL(xola.shipped_quantity, cn_0) / NVL(TO_NUMBER(iimb.attribute11) ,cn_1)
                             -- �󒍃J�e�S���R�[�h�Ő�������ݒ�
                             * DECODE(otta.order_category_code
                                    , cv_order_ctg_return  -- RETURN�̏ꍇ�A�}�C�i�X���|����
                                    , cn_minus
                                    , cn_1
                               )
                         )
                   , cn_0
                   )
             END                                           AS ship_comp_qty
      FROM   xxwsh_order_headers_all   xoha  -- �󒍃w�b�_�A�h�I��
           , xxwsh_order_lines_all     xola  -- �󒍖��׃A�h�I��
           , mtl_system_items_b        msib  -- Disc�i�ڃ}�X�^
           , xxcmn_item_mst_b          ximb  -- OPM�i�ڃA�h�I���}�X�^
           , ic_item_mst_b             iimb  -- OPM�i�ڃ}�X�^
           , mtl_item_categories       mic1  -- �J�e�S������
           , xxcop_all_categories_v    xacv1 -- �S�i�ڃJ�e�S���r���[
           , mtl_item_categories       mic2  -- �J�e�S������
           , xxcop_all_categories_v    xacv2 -- �S�i�ڃJ�e�S���r���[
           , oe_transaction_types_all  otta  -- ����^�C�v
           , oe_transaction_types_tl   ottt  -- ����^�C�v�ڍ�
           , hz_party_sites            hps   -- �p�[�e�B�T�C�g
           , hz_cust_accounts          hca   -- �ڋq�}�X�^
           , xxcmm_cust_accounts       xca   -- �ڋq�ǉ����
      WHERE  xoha.order_header_id        = xola.order_header_id
      AND    xola.request_item_id        = msib.inventory_item_id
      AND    msib.segment1               = iimb.item_no
      AND    iimb.item_id                = ximb.item_id
      AND    xoha.order_type_id          = ottt.transaction_type_id
      AND    ottt.transaction_type_id    = otta.transaction_type_id
      AND    hps.party_id                = hca.party_id
      AND    hca.cust_account_id         = xca.customer_id
      AND    msib.organization_id        = gt_sales_org_id         -- �c�Ƒg�DID
      AND    mic1.inventory_item_id      = msib.inventory_item_id
      AND    mic1.organization_id        = msib.organization_id
      AND    mic1.category_set_id        = xacv1.category_set_id
      AND    mic1.category_id            = xacv1.category_id
      AND    xacv1.category_set_name     = gt_item_div_h           -- �{�Џ��i�敪
      AND    mic2.inventory_item_id      = msib.inventory_item_id
      AND    mic2.organization_id        = msib.organization_id
      AND    mic2.category_set_id        = xacv2.category_set_id
      AND    mic2.category_id            = xacv2.category_id
      AND    xacv2.category_set_name     = gt_policy_group_code    -- ����Q�R�[�h
      AND    otta.org_id                 = gt_itou_ou_id           -- ���Y�g�DID
      AND    otta.attribute1             = cv_ship_order           -- �o�׈˗�
      AND    NVL(otta.attribute4 ,cv_stock_etc)
                                        <> cv_stock_adjm           -- �݌ɒ����ȊO
      AND    ottt.language               = ct_lang
      AND    hca.customer_class_code     = cv_customer_class_cust  -- �ڋq�敪�F�ڋq
      AND    NVL(xola.delete_flag, cv_delete_flag_n)
                                         = cv_delete_flag_n        -- N�F�폜�ȊO
      AND    xoha.latest_external_flag   = cv_latest_ext_flag_y    -- Y�F�ŐV
      AND    xca.sale_base_code          = iv_base_code            -- ���̓p�����[�^.���_
      AND    iimb.item_no                = NVL(gv_item_code ,iimb.item_no)
                                                                   -- ���̓p�����[�^.�i�ڃR�[�h
      AND    xoha.req_status             = cv_req_status_04        -- 04�F�o�׎��ьv���
      AND    xoha.actual_confirm_class   = cv_act_conf_class_y     -- Y�F���ьv���
      AND    xoha.result_deliver_to_id   = hps.party_site_id
      AND    ximb.start_date_active     <= gd_process_date
      AND    ximb.end_date_active       >= gd_process_date
      AND    xoha.arrival_date          >= TO_DATE(gv_target_month, cv_format_yyyymm)           -- ���̓p�����[�^.�Ώ۔N��
      AND    xoha.arrival_date          <= LAST_DAY(TO_DATE(gv_target_month, cv_format_yyyymm)) -- ���̓p�����[�^.�Ώ۔N��
      AND    xacv1.segment1              = NVL(gv_prod_class_code  ,xacv1.segment1)             -- ���̓p�����[�^.���i�敪
      AND    xacv2.segment1              = NVL(gv_crowd_class_code ,xacv2.segment1)             -- ���̓p�����[�^.����Q�R�[�h
      AND NOT EXISTS ( SELECT '1'  AS dummy
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type        = cv_lkup_exc_order_type -- ���ɏ�񒊏o�ΏۊO�󒍃^�C�v
                       AND    flv.enabled_flag       = cv_flag_y
                       AND    flv.language           = ct_lang
                       AND    flv.start_date_active <= gd_process_date
                       AND    NVL(flv.end_date_active ,gd_process_date)
                                                    >= gd_process_date
                       AND    ottt.name              = flv.meaning
                     )
      GROUP BY TO_CHAR(xoha.arrival_date ,cv_format_yyyymm)
             , xca.sale_base_code
             , iimb.item_no
             , ximb.item_short_name
             , xacv1.segment1
             , xacv1.description
             , xacv2.segment1
             , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)
             , otta.order_category_code
      ;
    -- ���R�[�h��`
    get_ship_comp_info_rec   get_ship_comp_info_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===================================
    --  ����v��ϐ��擾
    -- ===================================
    -- �J�[�\��OPEN
    OPEN get_ship_comp_info_cur;
    LOOP
      FETCH get_ship_comp_info_cur INTO get_ship_comp_info_rec;
      EXIT WHEN get_ship_comp_info_cur%NOTFOUND;
      --
      -- ======================================
      --  ���[���s�p���[�N�e�[�u�����݃`�F�b�N
      -- ======================================
      BEGIN
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcop_rep_forecast_comp_list xrfcl
        WHERE  xrfcl.target_month = get_ship_comp_info_rec.target_month
        AND    xrfcl.base_code    = get_ship_comp_info_rec.base_code
        AND    xrfcl.item_code    = get_ship_comp_info_rec.item_code
        AND    xrfcl.request_id   = cn_request_id
        ;
        -- ======================================
        --  ���[���s�p���[�N�e�[�u���X�V
        -- ======================================
        UPDATE xxcop_rep_forecast_comp_list xrfcl
        SET    xrfcl.ship_comp_qty        = xrfcl.ship_comp_qty
                                          + get_ship_comp_info_rec.ship_comp_qty
        WHERE  xrfcl.target_month         = get_ship_comp_info_rec.target_month
        AND    xrfcl.base_code            = get_ship_comp_info_rec.base_code
        AND    xrfcl.item_code            = get_ship_comp_info_rec.item_code
        AND    xrfcl.request_id           = cn_request_id
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  ���[���s�p���[�N�e�[�u���o�^
          -- ===================================
          BEGIN
            INSERT INTO xxcop_rep_forecast_comp_list(
              target_month                              -- 01�F�Ώ۔N��
            , process_date                              -- 02�F�Ɩ����t
            , prod_class_code                           -- 03�F���i�敪
            , prod_class_name                           -- 04�F���i�敪��
            , base_code                                 -- 05�F���_�R�[�h
            , base_name                                 -- 06�F���_��
            , forecast_type                             -- 07�F�v��敪
            , forecast_type_name                        -- 08�F�v��敪��
            , crowd_class_code                          -- 09�F����Q�R�[�h
            , crowd_class_code3                         -- 10�F����Q�R�[�h(��3��)
            , item_code                                 -- 11�F�i�ڃR�[�h
            , item_name                                 -- 12�F�i�ږ�
            , forecast_qty                              -- 13�F����v�搔
            , stock_comp_qty                            -- 14�F���Ɋm�F���i���_���Ɂj
            , stock_order_comp_qty                      -- 15�F�˗��ϐ��i���_���Ɂj
            , ship_comp_qty                             -- 16�F����v��ϐ��i�����j
            , ship_order_comp_qty                       -- 17�F�˗��ϐ��i�����j
            , created_by                                -- 18�F�쐬��
            , creation_date                             -- 19�F�쐬��
            , last_updated_by                           -- 20�F�ŏI�X�V��
            , last_update_date                          -- 21�F�ŏI�X�V��
            , last_update_login                         -- 22�F�ŏI�X�V���O�C��
            , request_id                                -- 23�F�v��ID
            , program_application_id                    -- 24�F�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            , program_id                                -- 25�F�R���J�����g�E�v���O����ID
            , program_update_date                       -- 26�F�v���O�����X�V��
            ) VALUES(
              gv_target_month                           -- 01
            , gd_process_date                           -- 02
            , get_ship_comp_info_rec.prod_class_code    -- 03
            , get_ship_comp_info_rec.prod_class_name    -- 04
            , get_ship_comp_info_rec.base_code          -- 05
            , iv_base_name                              -- 06
            , gv_forecast_type                          -- 07
            , gt_forecast_type_name                     -- 08
            , get_ship_comp_info_rec.crowd_class_code   -- 09
            , get_ship_comp_info_rec.crowd_class_code3  -- 10
            , get_ship_comp_info_rec.item_code          -- 11
            , get_ship_comp_info_rec.item_name          -- 12
            , cn_0                                      -- 13
            , cn_0                                      -- 14
            , cn_0                                      -- 15
            , get_ship_comp_info_rec.ship_comp_qty      -- 16
            , cn_0                                      -- 17
            , cn_created_by                             -- 18
            , SYSDATE                                   -- 19
            , cn_last_updated_by                        -- 20
            , SYSDATE                                   -- 21
            , cn_last_update_login                      -- 22
            , cn_request_id                             -- 23
            , cn_program_application_id                 -- 24
            , cn_program_id                             -- 25
            , SYSDATE                                   -- 26
            );
            -- �Ώی����J�E���g
            gn_target_cnt := gn_target_cnt + 1;
          --
          EXCEPTION
            WHEN OTHERS THEN
              -- �g�[�N���l��ݒ�
              gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
              -- �o�^�����G���[���b�Z�[�W
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_xxcop_00027    -- ���b�Z�[�W�R�[�h
                             , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                             , iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        WHEN OTHERS THEN
          -- �g�[�N���l��ݒ�
          gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
          -- �X�V�����G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcop_00028    -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      --
      END;
    END LOOP;
--
    CLOSE get_ship_comp_info_cur;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\��CLOSE
      IF (get_ship_comp_info_cur%ISOPEN) THEN
        CLOSE get_ship_comp_info_cur;
      END IF;
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
  END get_ship_comp_info;
--
  /**********************************************************************************
   * Procedure Name   : get_ship_order_comp_info
   * Description      : �˗��ϐ�(����)�擾����(A-8)
   ***********************************************************************************/
  PROCEDURE get_ship_order_comp_info(
      iv_base_code        IN  VARCHAR2  -- ���_�R�[�h
    , iv_base_name        IN  VARCHAR2  -- ���_��
    , ov_errbuf           OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode          OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg           OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_order_comp_info'; -- �v���O������
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
    ln_dummy   NUMBER;         -- �_�~�[�ϐ�
--
    -- *** ���[�J���J�[�\�� ***
    -- �˗��ϐ�(����)�擾�J�[�\��
    CURSOR get_ship_order_comp_info_cur
    IS
      SELECT /*+
               LEADING(ottt otta xoha hps hca)
             */
             TO_CHAR(xoha.schedule_arrival_date ,cv_format_yyyymm)  AS target_month
           , xca.sale_base_code                                     AS base_code
           , iimb.item_no                                           AS item_code
           , ximb.item_short_name                                   AS item_name
           , xacv1.segment1                                         AS prod_class_code
           , xacv1.description                                      AS prod_class_name
           , xacv2.segment1                                         AS crowd_class_code
           , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)                    AS crowd_class_code3
           , CASE
               -- ���[�t�̏ꍇ�A���ʂ������_�ȉ�1�ʂŐ؂�̂�
               WHEN xacv1.segment1 = cv_ctg_leaf
                 THEN
                   TRUNC(SUM(NVL(xola.quantity, cn_0)
                             -- �󒍃J�e�S���R�[�h�Ő�������ݒ�
                             * DECODE(otta.order_category_code
                                    , cv_order_ctg_return  -- RETURN�̏ꍇ�A�}�C�i�X���|����
                                    , cn_minus
                                    , cn_1
                               )
                         )
                   , cn_0
                   )
               -- �h�����N�̏ꍇ�A���ʂ��P�[�X���Z�������_�ȉ�1�ʂŐ؂�̂�
               WHEN xacv1.segment1 = cv_ctg_drink
                 THEN
                   TRUNC(SUM(NVL(xola.quantity, cn_0) / NVL(TO_NUMBER(iimb.attribute11) ,cn_1)
                             -- �󒍃J�e�S���R�[�h�Ő�������ݒ�
                             * DECODE(otta.order_category_code
                                    , cv_order_ctg_return  -- RETURN�̏ꍇ�A�}�C�i�X���|����
                                    , cn_minus
                                    , cn_1
                               )
                         )
                   , cn_0
                   )
             END                                                    AS ship_order_comp_qty
      FROM   xxwsh_order_headers_all   xoha  -- �󒍃w�b�_�A�h�I��
           , xxwsh_order_lines_all     xola  -- �󒍖��׃A�h�I��
           , mtl_system_items_b        msib  -- Disc�i�ڃ}�X�^
           , xxcmn_item_mst_b          ximb  -- OPM�i�ڃA�h�I���}�X�^
           , ic_item_mst_b             iimb  -- OPM�i�ڃ}�X�^(�q�i��)
           , mtl_item_categories       mic1  -- �J�e�S������
           , xxcop_all_categories_v    xacv1 -- �S�i�ڃJ�e�S���r���[
           , mtl_item_categories       mic2  -- �J�e�S������
           , xxcop_all_categories_v    xacv2 -- �S�i�ڃJ�e�S���r���[
           , oe_transaction_types_all  otta  -- ����^�C�v
           , oe_transaction_types_tl   ottt  -- ����^�C�v�ڍ�
           , hz_party_sites            hps   -- �p�[�e�B�T�C�g
           , hz_cust_accounts          hca   -- �ڋq�}�X�^
           , xxcmm_cust_accounts       xca   -- �ڋq�ǉ����
      WHERE  xoha.order_header_id        = xola.order_header_id
      AND    xola.request_item_id        = msib.inventory_item_id
      AND    msib.segment1               = iimb.item_no
      AND    iimb.item_id                = ximb.item_id
      AND    xoha.order_type_id          = ottt.transaction_type_id
      AND    ottt.transaction_type_id    = otta.transaction_type_id
      AND    hps.party_id                = hca.party_id
      AND    hca.cust_account_id         = xca.customer_id
      AND    msib.organization_id        = gt_sales_org_id         -- �c�Ƒg�DID
      AND    mic1.inventory_item_id      = msib.inventory_item_id
      AND    mic1.organization_id        = msib.organization_id
      AND    mic1.category_set_id        = xacv1.category_set_id
      AND    mic1.category_id            = xacv1.category_id
      AND    xacv1.category_set_name     = gt_item_div_h           -- �{�Џ��i�敪
      AND    mic2.inventory_item_id      = msib.inventory_item_id
      AND    mic2.organization_id        = msib.organization_id
      AND    mic2.category_set_id        = xacv2.category_set_id
      AND    mic2.category_id            = xacv2.category_id
      AND    xacv2.category_set_name     = gt_policy_group_code    -- ����Q�R�[�h
      AND    otta.org_id                 = gt_itou_ou_id           -- ���Y�g�DID
      AND    otta.attribute1             = cv_ship_order           -- �o�׈˗�
      AND    NVL(otta.attribute4 ,cv_stock_etc)
                                        <> cv_stock_adjm           -- �݌ɒ����ȊO
      AND    ottt.language               = ct_lang
      AND    hca.customer_class_code     = cv_customer_class_cust  -- �ڋq�敪�F�ڋq
      AND    NVL(xola.delete_flag, cv_delete_flag_n)
                                         = cv_delete_flag_n        -- N�F�폜�ȊO
      AND    xoha.latest_external_flag   = cv_latest_ext_flag_y    -- Y�F�ŐV
      AND    xca.sale_base_code          = iv_base_code            -- ���̓p�����[�^.���_
      AND    iimb.item_no                = NVL(gv_item_code ,iimb.item_no)
                                                                   -- ���̓p�����[�^.�i�ڃR�[�h
      AND    xoha.req_status             IN (cv_req_status_01      -- 01�F���͒�
                                           , cv_req_status_02      -- 02�F���_�m��
                                           , cv_req_status_03)     -- 03�F���ߍς�
      AND    xoha.deliver_to_id          = hps.party_site_id
      AND    ximb.start_date_active     <= gd_process_date
      AND    ximb.end_date_active       >= gd_process_date
      AND    xoha.schedule_arrival_date >= TO_DATE(gv_target_month, cv_format_yyyymm)           -- ���̓p�����[�^.�Ώ۔N��
      AND    xoha.schedule_arrival_date <= LAST_DAY(TO_DATE(gv_target_month, cv_format_yyyymm)) -- ���̓p�����[�^.�Ώ۔N��
      AND    xacv1.segment1              = NVL(gv_prod_class_code  ,xacv1.segment1)             -- ���̓p�����[�^.���i�敪
      AND    xacv2.segment1              = NVL(gv_crowd_class_code ,xacv2.segment1)             -- ���̓p�����[�^.����Q�R�[�h
      AND NOT EXISTS ( SELECT '1'  AS dummy
                       FROM   fnd_lookup_values flv
                       WHERE  flv.lookup_type        = cv_lkup_exc_order_type -- ���ɏ�񒊏o�ΏۊO�󒍃^�C�v
                       AND    flv.enabled_flag       = cv_flag_y
                       AND    flv.language           = ct_lang
                       AND    flv.start_date_active <= gd_process_date
                       AND    NVL(flv.end_date_active, gd_process_date)
                                                    >= gd_process_date
                       AND    ottt.name              = flv.meaning
                     )
      GROUP BY TO_CHAR(xoha.schedule_arrival_date ,cv_format_yyyymm)
             , xca.sale_base_code
             , iimb.item_no
             , ximb.item_short_name
             , xacv1.segment1
             , xacv1.description
             , xacv2.segment1
             , SUBSTRB(xacv2.segment1 ,cn_1 ,cn_3)
             , otta.order_category_code
      ;
    -- ���R�[�h��`
    get_ship_order_comp_info_rec   get_ship_order_comp_info_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===================================
    --  �˗��ϐ�(����)�擾
    -- ===================================
    -- �J�[�\��OPEN
    OPEN get_ship_order_comp_info_cur;
    LOOP
      FETCH get_ship_order_comp_info_cur INTO get_ship_order_comp_info_rec;
      EXIT WHEN get_ship_order_comp_info_cur%NOTFOUND;
      --
      -- ======================================
      --  ���[���s�p���[�N�e�[�u�����݃`�F�b�N
      -- ======================================
      BEGIN
        SELECT 1  AS dummy
        INTO   ln_dummy
        FROM   xxcop_rep_forecast_comp_list xrfcl
        WHERE  xrfcl.target_month = get_ship_order_comp_info_rec.target_month
        AND    xrfcl.base_code    = get_ship_order_comp_info_rec.base_code
        AND    xrfcl.item_code    = get_ship_order_comp_info_rec.item_code
        AND    xrfcl.request_id   = cn_request_id
        ;
        -- ======================================
        --  ���[���s�p���[�N�e�[�u���X�V
        -- ======================================
        UPDATE xxcop_rep_forecast_comp_list xrfcl
        SET    xrfcl.ship_order_comp_qty  = xrfcl.ship_order_comp_qty
                                          + get_ship_order_comp_info_rec.ship_order_comp_qty
        WHERE  xrfcl.target_month         = get_ship_order_comp_info_rec.target_month
        AND    xrfcl.base_code            = get_ship_order_comp_info_rec.base_code
        AND    xrfcl.item_code            = get_ship_order_comp_info_rec.item_code
        AND    xrfcl.request_id           = cn_request_id
        ;
      --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- ===================================
          --  ���[���s�p���[�N�e�[�u���o�^
          -- ===================================
          BEGIN
            INSERT INTO xxcop_rep_forecast_comp_list(
              target_month                                      -- 01�F�Ώ۔N��
            , process_date                                      -- 02�F�Ɩ����t
            , prod_class_code                                   -- 03�F���i�敪
            , prod_class_name                                   -- 04�F���i�敪��
            , base_code                                         -- 05�F���_�R�[�h
            , base_name                                         -- 06�F���_��
            , forecast_type                                     -- 07�F�v��敪
            , forecast_type_name                                -- 08�F�v��敪��
            , crowd_class_code                                  -- 09�F����Q�R�[�h
            , crowd_class_code3                                 -- 10�F����Q�R�[�h(��3��)
            , item_code                                         -- 11�F�i�ڃR�[�h
            , item_name                                         -- 12�F�i�ږ�
            , forecast_qty                                      -- 13�F����v�搔
            , stock_comp_qty                                    -- 14�F���Ɋm�F���i���_���Ɂj
            , stock_order_comp_qty                              -- 15�F�˗��ϐ��i���_���Ɂj
            , ship_comp_qty                                     -- 16�F����v��ϐ��i�����j
            , ship_order_comp_qty                               -- 17�F�˗��ϐ��i�����j
            , created_by                                        -- 18�F�쐬��
            , creation_date                                     -- 19�F�쐬��
            , last_updated_by                                   -- 20�F�ŏI�X�V��
            , last_update_date                                  -- 21�F�ŏI�X�V��
            , last_update_login                                 -- 22�F�ŏI�X�V���O�C��
            , request_id                                        -- 23�F�v��ID
            , program_application_id                            -- 24�F�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            , program_id                                        -- 25�F�R���J�����g�E�v���O����ID
            , program_update_date                               -- 26�F�v���O�����X�V��
            ) VALUES(
              gv_target_month                                   -- 01
            , gd_process_date                                   -- 02
            , get_ship_order_comp_info_rec.prod_class_code      -- 03
            , get_ship_order_comp_info_rec.prod_class_name      -- 04
            , get_ship_order_comp_info_rec.base_code            -- 05
            , iv_base_name                                      -- 06
            , gv_forecast_type                                  -- 07
            , gt_forecast_type_name                             -- 08
            , get_ship_order_comp_info_rec.crowd_class_code     -- 09
            , get_ship_order_comp_info_rec.crowd_class_code3    -- 10
            , get_ship_order_comp_info_rec.item_code            -- 11
            , get_ship_order_comp_info_rec.item_name            -- 12
            , cn_0                                              -- 13
            , cn_0                                              -- 14
            , cn_0                                              -- 15
            , cn_0                                              -- 16
            , get_ship_order_comp_info_rec.ship_order_comp_qty  -- 17
            , cn_created_by                                     -- 18
            , SYSDATE                                           -- 19
            , cn_last_updated_by                                -- 20
            , SYSDATE                                           -- 21
            , cn_last_update_login                              -- 22
            , cn_request_id                                     -- 23
            , cn_program_application_id                         -- 24
            , cn_program_id                                     -- 25
            , SYSDATE                                           -- 26
            );
            -- �Ώی����J�E���g
            gn_target_cnt := gn_target_cnt + 1;
          --
          EXCEPTION
            WHEN OTHERS THEN
              -- �g�[�N���l��ݒ�
              gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
              -- �o�^�����G���[���b�Z�[�W
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                             , iv_name         => cv_msg_xxcop_00027    -- ���b�Z�[�W�R�[�h
                             , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                             , iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        WHEN OTHERS THEN
          -- �g�[�N���l��ݒ�
          gv_tkn_vl1  := xxccp_common_pkg.get_msg( cv_application, cv_msg_xxcop_10072 );
          -- �X�V�����G���[���b�Z�[�W
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application        -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcop_00028    -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_table          -- �g�[�N���R�[�h1
                         , iv_token_value1 => gv_tkn_vl1            -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      --
      END;
    END LOOP;
--
    CLOSE get_ship_order_comp_info_cur;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- �J�[�\��CLOSE
      IF (get_ship_order_comp_info_cur%ISOPEN) THEN
        CLOSE get_ship_order_comp_info_cur;
      END IF;
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
  END get_ship_order_comp_info;
--
  /**********************************************************************************
   * Procedure Name   : svf_call
   * Description      : SVF�N��(A-9)
   ***********************************************************************************/
  PROCEDURE svf_call(
     ov_errbuf   OUT VARCHAR2            --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode  OUT VARCHAR2            --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg   OUT VARCHAR2            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'svf_call'; -- �v���O������
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
    lv_api_errmsg    VARCHAR2(5000); -- API���b�Z�[�W�p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --�o�̓t�@�C�����ҏW
    lv_file_name  := cv_pkg_name                                || -- �v���O����ID
                     TO_CHAR(cd_creation_date ,cv_format_svf)   || -- ���t
                     TO_CHAR(cn_request_id)                     || -- �v��ID
                     cv_extension_pdf                              -- �g���q(PDF)
                     ;
--
    -- SVF���[���ʊ֐�(SVF�R���J�����g�̋N���j
    xxccp_svfcommon_pkg.submit_svf_request(
          ov_retcode       =>  lv_retcode              -- ���^�[���R�[�h
        , ov_errbuf        =>  lv_api_errmsg           -- �G���[���b�Z�[�W
        , ov_errmsg        =>  lv_errmsg               -- ���[�U�[�E�G���[���b�Z�[�W
        , iv_conc_name     =>  cv_pkg_name             -- �R���J�����g��
        , iv_file_name     =>  lv_file_name            -- �o�̓t�@�C����
        , iv_file_id       =>  cv_pkg_name             -- ���[ID
        , iv_output_mode   =>  cv_output_mode          -- �o�͋敪
        , iv_frm_file      =>  cv_frm_file             -- �t�H�[���l���t�@�C����
        , iv_vrq_file      =>  cv_vrq_file             -- �N�G���[�l���t�@�C����
        , iv_org_id        =>  fnd_global.org_id       -- ORG_ID
        , iv_user_name     =>  cn_created_by           -- ���O�C���E���[�U��
        , iv_resp_name     =>  fnd_global.resp_name    -- ���O�C���E���[�U�̐E�Ӗ�
        , iv_doc_name      =>  NULL                    -- ������
        , iv_printer_name  =>  NULL                    -- �v�����^��
        , iv_request_id    =>  cn_request_id           -- �v��ID
        , iv_nodata_msg    =>  NULL                    -- �f�[�^�Ȃ����b�Z�[�W
        , iv_svf_param1    =>  NULL                    -- svf�σp�����[�^1
        , iv_svf_param2    =>  NULL                    -- svf�σp�����[�^2
        , iv_svf_param3    =>  NULL                    -- svf�σp�����[�^3
        , iv_svf_param4    =>  NULL                    -- svf�σp�����[�^4
        , iv_svf_param5    =>  NULL                    -- svf�σp�����[�^5
        , iv_svf_param6    =>  NULL                    -- svf�σp�����[�^6
        , iv_svf_param7    =>  NULL                    -- svf�σp�����[�^7
        , iv_svf_param8    =>  NULL                    -- svf�σp�����[�^8
        , iv_svf_param9    =>  NULL                    -- svf�σp�����[�^9
        , iv_svf_param10   =>  NULL                    -- svf�σp�����[�^10
        , iv_svf_param11   =>  NULL                    -- svf�σp�����[�^11
        , iv_svf_param12   =>  NULL                    -- svf�σp�����[�^12
        , iv_svf_param13   =>  NULL                    -- svf�σp�����[�^13
        , iv_svf_param14   =>  NULL                    -- svf�σp�����[�^14
        , iv_svf_param15   =>  NULL                    -- svf�σp�����[�^15
        );
--
    -- �G���[�n���h�����O
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_application
                   ,iv_name         => cv_msg_xxcop_00016
                   ,iv_token_name1  => cv_tkn_prg_name
                   ,iv_token_value1 => cv_api_err_msg_tkn_val
                   ,iv_token_name2  => cv_tkn_errmsg
                   ,iv_token_value2 => lv_api_errmsg
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
  END svf_call;
--
  /**********************************************************************************
   * Procedure Name   : del_rep_work_data
   * Description      : ���[���s�p���[�N�e�[�u���폜����(A-10)
   ***********************************************************************************/
  PROCEDURE del_rep_work_data(
     ov_errbuf   OUT VARCHAR2            --   �G���[�E���b�Z�[�W           --# �Œ� #
   , ov_retcode  OUT VARCHAR2            --   ���^�[���E�R�[�h             --# �Œ� #
   , ov_errmsg   OUT VARCHAR2            --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_work_data'; -- �v���O������
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
    BEGIN
      -- ���[���s�p���[�N�e�[�u���̍폜
      DELETE
      FROM   xxcop_rep_forecast_comp_list   xrfcl
      WHERE  xrfcl.request_id = cn_request_id
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        -- �g�[�N���l��ݒ�
        gv_tkn_vl1  := xxccp_common_pkg.get_msg(cv_application, cv_msg_xxcop_10072);
        -- �폜�G���[
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application      -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_xxcop_00042  -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table        -- �g�[�N���R�[�h1
                       ,iv_token_value1 => gv_tkn_vl1          -- �g�[�N���l1
                       );
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
  END del_rep_work_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
      ov_errbuf            OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
    , ov_retcode           OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
    , ov_errmsg            OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    , iv_target_month      IN  VARCHAR2  -- 1.�Ώ۔N��
    , iv_forecast_type     IN  VARCHAR2  -- 2.�v��敪
    , iv_prod_class_code   IN  VARCHAR2  -- 3.���i�敪
    , iv_base_code         IN  VARCHAR2  -- 4.���_
    , iv_crowd_class_code  IN  VARCHAR2  -- 5.����Q�R�[�h
    , iv_item_code         IN  VARCHAR2  -- 6.�i�ڃR�[�h
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
    lv_errbuf            VARCHAR2(5000)   DEFAULT NULL;              -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1)      DEFAULT cv_status_normal;  -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000)   DEFAULT NULL;              -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt        := 0;
    gn_normal_cnt        := 0;
    gn_error_cnt         := 0;
--
    -- �O���[�o���ϐ��ɓ��̓p�����[�^��ݒ�
    gv_target_month      := iv_target_month;      -- �Ώ۔N��
    gv_forecast_type     := iv_forecast_type;     -- �v��敪
    gv_prod_class_code   := iv_prod_class_code;   -- ���i�敪
    gv_base_code         := iv_base_code;         -- ���_
    gv_crowd_class_code  := iv_crowd_class_code;  -- ����Q�R�[�h
    gv_item_code         := iv_item_code;         -- �i�ڃR�[�h
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================================
    -- ��������(A-1)
    -- ===============================================
    init(
        ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W             --# �Œ� #
      , ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h               --# �Œ� #
      , ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �Ώۋ��_�擾�i�z�����_�j�iA-2�j
    -- ===============================================
    get_target_base_code(
        ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W             --# �Œ� #
      , ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h               --# �Œ� #
      , ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    );
    -- �I���p�����[�^����
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    <<get_target_base_loop>>
    FOR i IN 1..g_target_base_tbl.COUNT LOOP
--
      -- ===============================================
      -- ����v�搔�擾�����iA-3�j
      -- ===============================================
      get_forecast_info(
        iv_base_code => g_target_base_tbl(i).base_code  -- ���_�R�[�h
      , iv_base_name => g_target_base_tbl(i).base_name  -- ���_��
      , ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W             --# �Œ� #
      , ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h               --# �Œ� #
      , ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
      );
      -- �I���p�����[�^����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- ���Ɋm�F��(���_����)�擾����(A-4)
      -- ===============================================
      get_stock_comp_info(
        iv_base_code => g_target_base_tbl(i).base_code  -- ���_�R�[�h
      , iv_base_name => g_target_base_tbl(i).base_name  -- ���_��
      , ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W             --# �Œ� #
      , ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h               --# �Œ� #
      , ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
      );
      -- �I���p�����[�^����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- �˗��ϐ�(���_���Ɂ|���_������)�擾����(A-5)
      -- ===============================================
      get_stock_order_comp_info(
        iv_base_code => g_target_base_tbl(i).base_code  -- ���_�R�[�h
      , iv_base_name => g_target_base_tbl(i).base_name  -- ���_��
      , ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W             --# �Œ� #
      , ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h               --# �Œ� #
      , ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
      );
      -- �I���p�����[�^����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- �˗��ϐ�(���_���Ɂ|�H�ꖢ�o��)�擾����(A-6)
      -- ===============================================
      get_stock_fact_ship_info(
        iv_base_code => g_target_base_tbl(i).base_code  -- ���_�R�[�h
      , iv_base_name => g_target_base_tbl(i).base_name  -- ���_��
      , ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W             --# �Œ� #
      , ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h               --# �Œ� #
      , ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
      );
      -- �I���p�����[�^����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- ����v��ϐ��擾����(A-7)
      -- ===============================================
      get_ship_comp_info(
        iv_base_code => g_target_base_tbl(i).base_code  -- ���_�R�[�h
      , iv_base_name => g_target_base_tbl(i).base_name  -- ���_��
      , ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W             --# �Œ� #
      , ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h               --# �Œ� #
      , ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
      );
      -- �I���p�����[�^����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
----
      -- ===============================================
      -- �˗��ϐ�(����)�擾����(A-8)
      -- ===============================================
      get_ship_order_comp_info(
        iv_base_code => g_target_base_tbl(i).base_code  -- ���_�R�[�h
      , iv_base_name => g_target_base_tbl(i).base_name  -- ���_��
      , ov_errbuf    => lv_errbuf     -- �G���[�E���b�Z�[�W             --# �Œ� #
      , ov_retcode   => lv_retcode    -- ���^�[���E�R�[�h               --# �Œ� #
      , ov_errmsg    => lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
      );
      -- �I���p�����[�^����
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP get_target_base_loop;
--
    -- SVF�N���O�ɃR�~�b�g���s�Ȃ�
    COMMIT;
--
    -- ===============================================
    -- SVF�N��(A-9)
    -- ===============================================
    svf_call(
       lv_errbuf                                     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                                    -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �I���p�����[�^����
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
      errbuf               OUT VARCHAR2  -- �G���[�E���b�Z�[�W #�Œ�#
    , retcode              OUT VARCHAR2  -- ���^�[���E�R�[�h   #�Œ�#
    , iv_target_month      IN  VARCHAR2  -- 1.�Ώ۔N��
    , iv_forecast_type     IN  VARCHAR2  -- 2.�v��敪
    , iv_prod_class_code   IN  VARCHAR2  -- 3.���i�敪
    , iv_base_code         IN  VARCHAR2  -- 4.���_
    , iv_crowd_class_code  IN  VARCHAR2  -- 5.����Q�R�[�h
    , iv_item_code         IN  VARCHAR2  -- 6.�i�ڃR�[�h
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
    -- �A�v���P�[�V�����Z�k��
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- �A�h�I���F���ʁEIF�̈�
    -- ���b�Z�[�W
    cv_target_rec_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    -- �g�[�N��
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
        ov_errbuf           => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
      , ov_retcode          => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
      , ov_errmsg           => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      , iv_target_month     => iv_target_month    -- 1.�Ώ۔N��
      , iv_forecast_type    => iv_forecast_type   -- 2.�v��敪
      , iv_prod_class_code  => iv_prod_class_code -- 3.���i�敪
      , iv_base_code        => iv_base_code       -- 4.���_
      , iv_crowd_class_code => iv_crowd_class_code-- 5.����Q�R�[�h
      , iv_item_code        => iv_item_code       -- 6.�i�ڃR�[�h
    );
--
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      -- �G���[����ROLLBACK
      ROLLBACK;
      -- �G���[�����ݒ�
      gn_error_cnt := 1;
    END IF;
--
    -- ===============================================
    -- ���[���s�p���[�N�e�[�u���폜����(A-10)
    -- ===============================================
    del_rep_work_data(
        ov_errbuf  => lv_errbuf  -- �G���[�E���b�Z�[�W
      , ov_retcode => lv_retcode -- ���^�[���E�R�[�h
      , ov_errmsg  => lv_errmsg  -- ���[�U�[�E�G���[�E���b�Z�[�W 
    );
    -- �G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000)
      );
      -- �G���[����ROLLBACK
      ROLLBACK;
      -- �G���[�����ݒ�
      gn_error_cnt := 1;
    END IF;
    -- ���[���s�p���[�N�e�[�u���폜��COMMIT
    COMMIT;
    --
    -- �G���[���������݂���ꍇ
    IF ( gn_error_cnt > 0 ) THEN
      -- �G���[���̌����ݒ�
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      -- �I���X�e�[�^�X���G���[�ɂ���
      lv_retcode := cv_status_error;
    ELSE
      -- ���팏���ݒ�
      gn_normal_cnt := gn_target_cnt;
      -- �I���X�e�[�^�X�𐳏�ɂ���
      lv_retcode := cv_status_normal;
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- �Ώی����o��
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
    -- ���������o��
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
    -- �G���[�����o��
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
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
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
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCOP004A10R;
/
