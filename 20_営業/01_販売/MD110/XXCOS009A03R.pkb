CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A03R (body)
 * Description      : ��������`�F�b�N���X�g
 * MD.050           : ��������`�F�b�N���X�g MD050_COS_009_A03
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  check_parameter        �p�����[�^�`�F�b�N(A-2)
 *  get_data               �Ώۃf�[�^�擾(A-3)
 *  check_cost             �c�ƌ����`�F�b�N(A-4)
 *  insert_rpt_wrk_data    ���[���[�N�e�[�u���o�^(A-5)
 *  execute_svf            SVF�N��(A-6)
 *  delete_rpt_wrk_data    ���[���[�N�e�[�u���폜(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   H.Ri             �V�K�쐬
 *  2009/02/17    1.1   H.Ri             get_msg�̃p�b�P�[�W���C��
 *  2009/04/21    1.2   K.Kiriu          [T1_0444]���ьv��҃R�[�h�̌����s���Ή�
 *  2009/06/17    1.3   N.Nishimura      [T1_1439]�Ώی���0�����A����I���Ƃ���
 *  2009/06/25    1.4   N.Nishimura      [T1_1437]�f�[�^�p�[�W�s��Ή�
 *  2009/08/11    1.5   N.Maeda          [0000865]PT�Ή�
 *  2009/08/13    1.5   N.Maeda          [0000865]���r���[�w�E�Ή�
 *  2009/09/02    1.6   M.Sano           [0001227]PT�Ή�
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** ��v���ԋ敪�擾��O ***
  global_acc_period_cls_get_expt    EXCEPTION;
  --*** ��v���Ԏ擾��O ***
  global_account_period_get_expt    EXCEPTION;
  --*** �����`�F�b�N��O ***
  global_format_chk_expt            EXCEPTION;
  --*** ���t�t�]�`�F�b�N��O ***
  global_date_rever_chk_expt        EXCEPTION;
  --*** ���t�͈̓`�F�b�N��O ***
  global_date_range_chk_expt        EXCEPTION;
  --*** �Ώۃf�[�^�擾��O ***
  global_data_get_expt              EXCEPTION;
  --*** �c�ƌ����擾��O ***
  global_sale_cost_get_expt         EXCEPTION;
  --*** �����Ώۃf�[�^�o�^��O ***
  global_data_insert_expt           EXCEPTION;
  --*** SVF�N����O ***
  global_svf_excute_expt            EXCEPTION;
  --*** �Ώۃf�[�^���b�N��O ***
  global_data_lock_expt             EXCEPTION;
  --*** �Ώۃf�[�^�폜��O ***
  global_data_delete_expt           EXCEPTION;
  
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS009A03R';         -- �p�b�P�[�W��
  cv_conc_name              CONSTANT  VARCHAR2(100) := 'XXCOS009A03R';         -- �R���J�����g��
  --���[�o�͊֘A
  cv_report_id              CONSTANT  VARCHAR2(100) := 'XXCOS009A03R';         -- ���[�h�c
  cv_frm_file               CONSTANT  VARCHAR2(100) := 'XXCOS009A03S.xml';     -- �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT  VARCHAR2(100) := 'XXCOS009A03S.vrq';     -- �N�G���[�l���t�@�C����
  cv_output_mode            CONSTANT  VARCHAR2(1)   := '1';                    -- �o�͋敪(PDF)
  cv_extension              CONSTANT  VARCHAR2(100) := '.pdf';                 -- �g���q(PDF)
  cv_xxcos_short_name       CONSTANT  VARCHAR2(100) := 'XXCOS';                -- �̕��̈�Z�k�A�v����
  cv_xxccp_short_name       CONSTANT  VARCHAR2(100) := 'XXCCP';                -- ���ʗ̈�Z�k�A�v����
  cv_xxcoi_short_name       CONSTANT  VARCHAR2(100) := 'XXCOI';                -- �݌ɗ̈�Z�k�A�v����
  --���b�Z�[�W
  cv_msg_format_check_err   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00002';    -- ���t�����`�F�b�N�G���[���b�Z�[�W
  cv_msg_acc_cls_get_err    CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11858';    -- ��v���ԋ敪�擾�G���[���b�Z�[�W
  cv_msg_acc_perd_get_err   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00026';    -- ��v���Ԏ擾�G���[���b�Z�[�W
  cv_msg_date_rever_err     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00005';    -- ���t�t�]�G���[���b�Z�[�W
  cv_msg_date_range_err     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11851';    -- ���t�͈̓G���[���b�Z�[�W
  cv_msg_para_output_note   CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11853';    -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_sale_cost_get_err  CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11852';    -- �c�ƌ����擾�G���[���b�Z�[�W
  cv_msg_insert_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00010';    -- �f�[�^�o�^�G���[���b�Z�[�W
  cv_msg_no_data_err        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00018';    -- ����0���G���[���b�Z�[�W
  cv_msg_select_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00013';    -- �f�[�^���o�G���[���b�Z�[�W
  cv_msg_lock_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00001';    -- ���b�N�擾�G���[���b�Z�[�W
  cv_msg_delete_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00012';    -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_api_err            CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00017';    -- API�G���[���b�Z�[�W
  cv_msg_parameter          CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11853';    -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_org_cd_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOI1-00005';    -- �݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_org_id_err         CONSTANT  VARCHAR2(100) :=  'APP-XXCOI1-00006';    -- �݌ɑg�DID�擾�G���[���b�Z�[�W
  cv_msg_proc_date_err      CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_prof_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00004';    -- �v���t�@�C���擾�G���[���b�Z�[�W
  --�g�[�N����
  cv_tkn_nm_account         CONSTANT  VARCHAR2(100) :=  'ACCOUNT_NAME';        --��v���Ԏ�ʖ���
  cv_tkn_nm_para_date       CONSTANT  VARCHAR2(100) :=  'PARA_DATE';           --�[�i��(FROM)�܂��͔[�i��(TO)
  cv_tkn_nm_base_code       CONSTANT  VARCHAR2(100) :=  'BASE_CODE';           --���㋒�_�R�[�h
  cv_tkn_nm_date_from       CONSTANT  VARCHAR2(100) :=  'DATE_FROM';           --�[�i��(FROM)
  cv_tkn_nm_date_to         CONSTANT  VARCHAR2(100) :=  'DATE_TO';             --�[�i��(TO)
  cv_tkn_nm_sale_emp        CONSTANT  VARCHAR2(100) :=  'SALE_EMP';            --�c�ƒS��
  cv_tkn_nm_ship_to         CONSTANT  VARCHAR2(100) :=  'SHIP_TO';             --�o�א�
  cv_tkn_nm_date_min        CONSTANT  VARCHAR2(100) :=  'DATE_MIN';            --��v���ԑO��
  cv_tkn_nm_date_max        CONSTANT  VARCHAR2(100) :=  'DATE_MAX';            --��v���ԓ���
  cv_tkn_nm_item_code       CONSTANT  VARCHAR2(100) :=  'HINMOKU';             --�i�ڃR�[�h
  cv_tkn_nm_table_name      CONSTANT  VARCHAR2(100) :=  'TABLE_NAME';          --�e�[�u������
  cv_tkn_nm_table_lock      CONSTANT  VARCHAR2(100) :=  'TABLE';               --�e�[�u������(���b�N�G���[���p)
  cv_tkn_nm_key_data        CONSTANT  VARCHAR2(100) :=  'KEY_DATA';            --�L�[�f�[�^
  cv_tkn_nm_api_name        CONSTANT  VARCHAR2(100) :=  'API_NAME';            --API����
  cv_tkn_nm_profile1        CONSTANT  VARCHAR2(100) :=  'PROFILE';             --�v���t�@�C����(�̔��̈�)
  cv_tkn_nm_profile2        CONSTANT  VARCHAR2(100) :=  'PRO_TOK';             --�v���t�@�C����(�݌ɗ̈�)
  cv_tkn_nm_org_cd          CONSTANT  VARCHAR2(100) :=  'ORG_CODE_TOK';        --�݌ɑg�D�R�[�h
  cv_tkn_nm_acc_type        CONSTANT  VARCHAR2(100) :=  'TYPE';                --��v���ԋ敪�Q�ƃ^�C�v
  --�g�[�N���l
  cv_msg_vl_acc_cls_ar      CONSTANT  VARCHAR2(100) :=  'AR';                  --AR
  cv_msg_vl_date_from       CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11854';    --�[�i��FROM
  cv_msg_vl_date_to         CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11855';    --�[�i��TO
  cv_msg_vl_table_name1     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11856';    --���[���[�N�e�[�u����
  cv_msg_vl_table_name2     CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-11857';    --�̔����уe�[�u����
  cv_msg_vl_api_name        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00041';    --API����
  cv_msg_vl_key_request_id  CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00088';    --�v��ID
  cv_msg_vl_min_date        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00120';    --MIN���t
  cv_msg_vl_max_date        CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00056';    --MAX���t
  --���t�t�H�[�}�b�g
  cv_yyyymmdd               CONSTANT  VARCHAR2(100) :=  'YYYYMMDD';            --YYYYMMDD�^
  cv_yyyy_mm_dd             CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD';          --YYYY/MM/DD�^
  cv_yyyy_mm                CONSTANT  VARCHAR2(100) :=  'YYYY/MM';             --YYYY/MM�^
  --�N�C�b�N�R�[�h�Q�Ɨp
  --�g�p�\�t���O�萔
  ct_enabled_flg_y          CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                                    :=  'Y';                   --�g�p�\
  cv_lang                   CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );     --����
  cv_type_acc               CONSTANT  VARCHAR2(100) :=  'XXCOS1_ACCOUNT_PERIOD';  --��v���Ԃ̎��
  cv_diff_y                 CONSTANT  VARCHAR2(100) :=  'Y';                   --Y
  cv_ord_src_type           CONSTANT  VARCHAR2(100) :=  'XXCOS1_ODR_SRC_MST_009_A03';
                                                                               --�󒍃\�[�X�̃N�C�b�N�^�C�v
  cv_ord_src_code           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A03%';      --�󒍃\�[�X�̃N�C�b�N�R�[�h
  cv_mk_org_type            CONSTANT  VARCHAR2(100) :=  'XXCOS1_MK_ORG_CLS_MST_009_A03';
                                                                               --�쐬���敪�̃N�C�b�N�^�C�v
  cv_mk_org_code1           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A03_1%';    --�쐬���敪�̃N�C�b�N�R�[�h(OM��)
  cv_mk_org_code2           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A03_2%';    --�쐬���敪�̃N�C�b�N�R�[�h
                                                                               --(���i�ʔ���v�Z)
  cv_sl_cls_type            CONSTANT  VARCHAR2(100) :=  'XXCOS1_SALE_CLASS_MST_009_A03';
                                                                               --����敪�̃N�C�b�N�^�C�v
  cv_sl_cls_code1           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A03_1%';    --����敪�̃N�C�b�N�R�[�h
                                                                               --(���^�A���{�A�L����`��)
  cv_sl_cls_code2           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A03_2%';    --����敪�̃N�C�b�N�R�[�h(�����EVD����)
  cv_no_inv_item_type       CONSTANT  VARCHAR2(100) := 'XXCOS1_NO_INV_ITEM_CODE';
                                                                               --��݌ɕi�ڂ̃N�C�b�N�^�C�v
  cv_cus_cls_type           CONSTANT  VARCHAR2(100) :=  'XXCOS1_CUS_CLASS_MST_009_A03';
                                                                               --�ڋq�敪�̃N�C�b�N�^�C�v
  cv_cus_cls_code           CONSTANT  VARCHAR2(100) :=  'XXCOS_009_A03%';      --�ڋq�敪�̃N�C�b�N�R�[�h
  --�v���t�@�C���֘A
  cv_prof_org               CONSTANT  VARCHAR2(100) :=  'XXCOI1_ORGANIZATION_CODE';
                                                                               -- �v���t�@�C����(�݌ɑg�D�R�[�h)
  cv_prof_min_date          CONSTANT  VARCHAR2(100) :=  'XXCOS1_MIN_DATE';     -- �v���t�@�C����(MIN���t)
  cv_prof_max_date          CONSTANT  VARCHAR2(100) :=  'XXCOS1_MAX_DATE';     -- �v���t�@�C����(MAX���t)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --��������`�F�b�N���X�g���[���[�N�e�[�u���^
  TYPE g_rpt_data_ttype IS TABLE OF xxcos_rep_cost_div_list%ROWTYPE INDEX BY BINARY_INTEGER;
  --�i�ڃR�[�h�e�[�u���^
  TYPE g_item_cd_ttype  IS TABLE OF xxcos_sales_exp_lines.item_code%TYPE INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  g_report_data_tab         g_rpt_data_ttype;                                   --���[�f�[�^�R���N�V����
  g_err_item_cd_tab         g_item_cd_ttype;                                    --�c�ƌ������ݒ�̕i�ڃR�[�h
  gt_org_id                 mtl_parameters.organization_id%TYPE;                --�݌ɑg�DID
  gd_proc_date              DATE;                                               --�Ɩ����t
  gd_min_date               DATE;                                               --MIN���t
  gd_max_date               DATE;                                               --MAX���t
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_sale_base_code   IN  VARCHAR2,     --   ���㋒�_�R�[�h
    iv_dlv_date_from    IN  VARCHAR2,     --   �[�i��(FROM)
    iv_dlv_date_to      IN  VARCHAR2,     --   �[�i��(TO)
    iv_sale_emp_code    IN  VARCHAR2,     --   �c�ƒS���҃R�[�h
    iv_ship_to_code     IN  VARCHAR2,     --   �o�א�R�[�h
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_para_msg   VARCHAR2(5000);                         -- �p�����[�^�o�̓��b�Z�[�W
    lt_org_cd     mtl_parameters.organization_code%TYPE;  -- �݌ɑg�D�R�[�h
    lv_date_item  VARCHAR2(100);                          -- MIN���t/MAX���t
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
    --========================================
    -- 1.�p�����[�^�o�͏���
    --========================================
    lv_para_msg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_parameter,
        iv_token_name1        =>  cv_tkn_nm_base_code,
        iv_token_value1       =>  iv_sale_base_code,
        iv_token_name2        =>  cv_tkn_nm_date_from,
        iv_token_value2       =>  iv_dlv_date_from,
        iv_token_name3        =>  cv_tkn_nm_date_to,
        iv_token_value3       =>  iv_dlv_date_to,
        iv_token_name4        =>  cv_tkn_nm_sale_emp,
        iv_token_value4       =>  iv_sale_emp_code,
        iv_token_name5        =>  cv_tkn_nm_ship_to,
        iv_token_value5       =>  iv_ship_to_code
      );
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
    --========================================
    -- 2.�݌ɑg�D�R�[�h�擾����
    --========================================
    lt_org_cd := FND_PROFILE.VALUE( cv_prof_org );
    IF ( lt_org_cd IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcoi_short_name,
        iv_name               =>  cv_msg_org_cd_err,
        iv_token_name1        =>  cv_tkn_nm_profile2,
        iv_token_value1       =>  cv_prof_org
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 3.�݌ɑg�DID�擾����
    --========================================
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_cd );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcoi_short_name,
        iv_name               =>  cv_msg_org_id_err,
        iv_token_name1        =>  cv_tkn_nm_org_cd,
        iv_token_value1       =>  lt_org_cd
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 4.�Ɩ����t�擾����
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
    -- 5.MIN���t�擾����
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
    -- 6.MAX���t�擾����
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
--#################################  �Œ��O������ START   ####################################
--
  EXCEPTION
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
    iv_dlv_date_from    IN  VARCHAR2,     --   �[�i��(FROM)
    iv_dlv_date_to      IN  VARCHAR2,     --   �[�i��(TO)
    od_dlv_date_from    OUT DATE,         --   �[�i��(FROM)_�`�F�b�NOK
    od_dlv_date_to      OUT DATE,         --   �[�i��(TO)_�`�F�b�NOK
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lt_account_cls       fnd_lookup_values.meaning%TYPE;   --��v�敪
    ld_acc_date_from     DATE;                             --��v����(FROM)
    ld_acc_date_to       DATE;                             --��v����(TO)
    ld_dlv_date_from     DATE;                             --�[�i��(FROM)
    ld_dlv_date_to       DATE;                             --�[�i��(TO)
    lv_check_item        VARCHAR2(100);                    --�[�i��(FROM)���͔[�i��(TO)����
    lv_check_item1       VARCHAR2(100);                    --�[�i��(FROM)����
    lv_check_item2       VARCHAR2(100);                    --�[�i��(TO)����
    ld_acc_date_from_ym  DATE;                             --��v����(FROM)_�N��
    ld_acc_date_pre_ym   DATE;                             --��v���ԑO��_�N��
    ld_dlv_date_from_ym  DATE;                             --�[�i��(FROM)_�N��
    ld_dlv_date_to_ym    DATE;                             --�[�i��(TO)_�N��
    lv_acc_status        VARCHAR2(100);                    --��v���ԃX�e�[�^�X
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
    --��v�敪�擾
    BEGIN
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
      SELECT  look_val.meaning            acc_cls
      INTO    lt_account_cls
      FROM    fnd_lookup_values           look_val
      WHERE   look_val.language           = cv_lang
      AND     look_val.lookup_type        = cv_type_acc
      AND     look_val.attribute1         = cv_diff_y
      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
      AND     look_val.enabled_flag       = ct_enabled_flg_y
      AND     rownum                      = 1
      ;
--
--      SELECT  look_val.meaning            acc_cls
--      INTO    lt_account_cls
--      FROM    fnd_lookup_values           look_val,
--              fnd_lookup_types_tl         types_tl,
--              fnd_lookup_types            types,
--              fnd_application_tl          appl,
--              fnd_application             app
--      WHERE   appl.application_id         = types.application_id
--      AND     app.application_id          = appl.application_id
--      AND     types_tl.lookup_type        = look_val.lookup_type
--      AND     types.lookup_type           = types_tl.lookup_type
--      AND     types.security_group_id     = types_tl.security_group_id
--      AND     types.view_application_id   = types_tl.view_application_id
--      AND     types_tl.language           = cv_lang
--      AND     look_val.language           = cv_lang
--      AND     appl.language               = cv_lang
--      AND     app.application_short_name  = cv_xxcos_short_name
--      AND     look_val.lookup_type        = cv_type_acc
--      AND     look_val.attribute1         = cv_diff_y
--      AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--      AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--      AND     look_val.enabled_flag       = ct_enabled_flg_y
--      AND     rownum                      = 1
--      ;
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_acc_period_cls_get_expt;
    END;
    --��v���ԏ��擾
    xxcos_common_pkg.get_account_period(
      iv_account_period     =>  lt_account_cls,           --��v�敪
      id_base_date          =>  NULL,                     --���
      ov_status             =>  lv_acc_status,            --��v���ԃX�e�[�^�X
      od_start_date         =>  ld_acc_date_from,         --��v(FROM)
      od_end_date           =>  ld_acc_date_to,           --��v(TO)
      ov_errbuf             =>  lv_errbuf,                --�G���[���b�Z�[�W
      ov_retcode            =>  lv_retcode,               --���^�[���R�[�h
      ov_errmsg             =>  lv_errmsg                 --���[�U�E�G���[�E���b�Z�[�W
    );
    --��v���ԏ��擾���s
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_account_period_get_expt;
    END IF;
--
    --�[�i��(FROM)�����`�F�b�N
    ld_dlv_date_from := FND_DATE.STRING_TO_DATE( iv_dlv_date_from, cv_yyyy_mm_dd );
    IF ( ld_dlv_date_from IS NULL ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_date_from
      );
      RAISE global_format_chk_expt;
    END IF;
    --�[�i��(TO)�����`�F�b�N
    ld_dlv_date_to := FND_DATE.STRING_TO_DATE( iv_dlv_date_to, cv_yyyy_mm_dd );
    IF ( ld_dlv_date_to IS NULL ) THEN
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_date_to
      );
      RAISE global_format_chk_expt;
    END IF;
--
    --�[�i��(FROM)�^�[�i��(TO)���t�t�]�`�F�b�N
    IF ( ld_dlv_date_from > ld_dlv_date_to ) THEN
      RAISE global_date_rever_chk_expt;
    END IF;
--
    --��v����(FROM)�N���擾
    ld_acc_date_from_ym := FND_DATE.STRING_TO_DATE( TO_CHAR( ld_acc_date_from, cv_yyyy_mm ), cv_yyyy_mm );
    --��v���ԑO���擾
    ld_acc_date_pre_ym := ADD_MONTHS( ld_acc_date_from_ym, -1 );
    --�[�i��(FROM)���t�͈̓`�F�b�N
    ld_dlv_date_from_ym := FND_DATE.STRING_TO_DATE( TO_CHAR( ld_dlv_date_from, cv_yyyy_mm ), cv_yyyy_mm );
    IF ( ld_dlv_date_from_ym >= ld_acc_date_pre_ym AND ld_dlv_date_from_ym <= ld_acc_date_from_ym ) THEN
      NULL;
    ELSE
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_date_from
      );
      RAISE global_date_range_chk_expt;
    END IF;
    --�[�i��(TO)���t�͈̓`�F�b�N
    ld_dlv_date_to_ym := FND_DATE.STRING_TO_DATE( TO_CHAR( ld_dlv_date_to, cv_yyyy_mm ), cv_yyyy_mm );
    IF ( ld_dlv_date_to_ym >= ld_acc_date_pre_ym AND ld_dlv_date_to_ym <= ld_acc_date_from_ym ) THEN
      NULL;
    ELSE
      lv_check_item         :=  xxccp_common_pkg.get_msg(
        iv_application      =>  cv_xxcos_short_name,
        iv_name             =>  cv_msg_vl_date_to
      );
      RAISE global_date_range_chk_expt;
    END IF;
--
    --�`�F�b�NOK
    od_dlv_date_from := ld_dlv_date_from;
    od_dlv_date_to   := ld_dlv_date_to;
--
  EXCEPTION
    -- *** ��v���ԋ敪�擾��O�n���h�� ***
    WHEN global_acc_period_cls_get_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_acc_cls_get_err,
        iv_token_name1        =>  cv_tkn_nm_account,
        iv_token_value1       =>  cv_msg_vl_acc_cls_ar,
        iv_token_name2        =>  cv_tkn_nm_acc_type,
        iv_token_value2       =>  cv_type_acc
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** ��v���Ԏ擾��O�n���h�� ***
    WHEN global_account_period_get_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_acc_perd_get_err,
        iv_token_name1        =>  cv_tkn_nm_account,
        iv_token_value1       =>  cv_msg_vl_acc_cls_ar
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
    -- *** ���t�t�]�`�F�b�N��O�n���h�� ***
    WHEN global_date_rever_chk_expt THEN
      lv_check_item1          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_date_from
      );
      lv_check_item2          :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_date_to
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
    -- *** ���t�͈̓`�F�b�N��O�n���h�� ***
    WHEN global_date_range_chk_expt THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_date_range_err,
        iv_token_name1        =>  cv_tkn_nm_para_date,
        iv_token_value1       =>  lv_check_item,
        iv_token_name2        =>  cv_tkn_nm_date_min,
        iv_token_value2       =>  TO_CHAR( ld_acc_date_pre_ym, cv_yyyy_mm ),
        iv_token_name3        =>  cv_tkn_nm_date_max,
        iv_token_value3       =>  TO_CHAR( ld_acc_date_from_ym, cv_yyyy_mm )
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
    iv_sale_base_code   IN  VARCHAR2,     --   ���㋒�_�R�[�h
    id_dlv_date_from    IN  DATE,         --   �[�i��(FROM)
    id_dlv_date_to      IN  DATE,         --   �[�i��(TO)
    iv_sale_emp_code    IN  VARCHAR2,     --   �c�ƒS���҃R�[�h
    iv_ship_to_code     IN  VARCHAR2,     --   �o�א�R�[�h
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_tkn_vl_table_name      VARCHAR2(100);
    ln_idx                    NUMBER;                                 --���C�����[�v�J�E���g
    ln_err_item_idx           NUMBER;                                 --�c�ƌ������ݒ胋�[�v�J�E���g
    lt_record_id              xxcos_rep_cost_div_list.record_id%TYPE; --���R�[�hID
    lb_ext_flg                BOOLEAN;                                --�G���[�i�ڃR�[�h�ݒ�σt���O
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR data_cur
    IS
      --�쐬�����󒍌n�@�\��SQL
      SELECT  
-- 2009/09/02 Ver.1.6 Add Start
        /*+
          LEADING ( lbiv.obc.fu )
          INDEX   ( lbiv.obc.fu fnd_user_u1)
          USE_NL  ( lbiv.obc.papf )
          INDEX   ( lbiv.obc.papf per_people_f_pk)
          USE_NL  ( lbiv.obc.ppt )
          INDEX   ( lbiv.obc.ppt per_person_types_pk)
          USE_NL  ( lbiv.obc.paaf )
          INDEX   ( lbiv.obc.paaf per_assignments_f_n12)
          USE_NL  ( lbiv.xca )
          INDEX   ( lbiv.xca xxcmm_cust_accounts_pk )
          USE_NL  ( seh )
          INDEX   ( seh xxcos_sales_exp_headers_n01 )
        */
-- 2009/09/02 Ver.1.6 Add End
        seh.sales_base_code               base_code,        --���㋒�_�R�[�h
        lbiv.base_name                    base_name,        --���㋒�_��
        seh.results_employee_code         emp_code,         --�c�ƒS���҃R�[�h
/* 2009/04/21 Ver1.2 Mod Start */
--        riv.employee_name                 emp_name,         --�c�ƒS���Җ�
        papf.per_information18 || ' ' || papf.per_information19
                                          emp_name,         --�c�ƒS���Җ�
/* 2009/04/21 Ver1.2 Mod End   */
        seh.ship_to_customer_code         ship_to_cd,       --�o�א�R�[�h
        hp.party_name                     ship_to_nm,       --�o�א於
        seh.delivery_date                 dlv_date,         --�[�i��
        seh.dlv_invoice_number            dlv_slip_num,     --�[�i�`�[�ԍ�
        sel.item_code                     item_cd,          --�i�ڃR�[�h
        ximb.item_short_name              item_nm,          --�i�ږ�
        sel.standard_qty                  quantity,         --����
        sel.standard_uom_code             unit,             --�P��
        sel.standard_unit_price_excluded  dlv_price,        --�[�i�P��
        sel.business_cost                 biz_cost          --�c�ƌ���
      FROM    
        xxcos_sales_exp_headers seh,                        --�̔����уw�b�_
        xxcos_sales_exp_lines   sel,                        --�̔����і���
        oe_order_sources        oos,                        --�󒍃\�[�X�}�X�^
        xxcos_login_base_info_v lbiv,                       --���O�C�����[�U���_�r���[
/* 2009/04/21 Ver1.2 Mod Start */
--        xxcos_rs_info_v         riv,                        --�c�ƈ����r���[
        per_all_people_f        papf,                       --�]�ƈ��}�X�^
/* 2009/04/21 Ver1.2 Mod End   */
        hz_cust_accounts        hca,                        --�ڋq�}�X�^
        hz_parties              hp,                         --�p�[�e�B
        mtl_system_items_b      msib,                       --Disc�i�ڃ}�X�^
        ic_item_mst_b           iimb,                       --OPM�i�ڃ}�X�^
        xxcmn_item_mst_b        ximb                        --OPM�i�ڃA�h�I��
      WHERE seh.sales_exp_header_id = sel.sales_exp_header_id                         --�̔����уw�b�_ID
      AND   seh.order_source_id     = oos.order_source_id                             --�󒍃\�[�XID
      --�󒍃\�[�X�̃N�C�b�N�Q��
      AND   EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_ord_src_type
              AND     look_val.lookup_code        LIKE cv_ord_src_code
              AND     look_val.meaning            = oos.name
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_ord_src_type
--              AND     look_val.lookup_code        LIKE cv_ord_src_code
--              AND     look_val.meaning            = oos.name
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                  )
      --�쐬���敪�̃N�C�b�N�Q��
      AND   EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_mk_org_type
              AND     look_val.lookup_code        LIKE cv_mk_org_code1
              AND     look_val.meaning            = seh.create_class
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_mk_org_type
--              AND     look_val.lookup_code        LIKE cv_mk_org_code1
--              AND     look_val.meaning            = seh.create_class
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                  )
      --����敪�̃N�C�b�N�Q��
      AND   NOT EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_sl_cls_type
              AND     look_val.lookup_code        LIKE cv_sl_cls_code1
              AND     look_val.meaning            = sel.sales_class
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_sl_cls_type
--              AND     look_val.lookup_code        LIKE cv_sl_cls_code1
--              AND     look_val.meaning            = sel.sales_class
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                  )
      --��݌ɕi�ڃR�[�h�̃N�C�b�N�Q��
      AND   NOT EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_no_inv_item_type
              AND     look_val.lookup_code        = sel.item_code
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_no_inv_item_type
--              AND     look_val.lookup_code        = sel.item_code
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                      )
      --���㋒�_�R�[�h���i����
-- ******** 2009/08/13 1.5 N.Maeda MOD START *********** --
-- 2009/09/02 Ver.1.6 Mod Start
      AND   ( ( iv_sale_base_code IS NULL )
--      AND   ( ( iv_sale_base_code IS NULL AND EXISTS( SELECT 'Y'
--                                                      FROM   xxcos_login_base_info_v lbiv1
--                                                      WHERE  seh.sales_base_code = lbiv1.base_code ) )
-- 2009/09/02 Ver.1.6 Mod End
        OR ( iv_sale_base_code IS NOT NULL AND iv_sale_base_code = seh.sales_base_code ) )
--      AND   1 = (
--                 CASE
--                  WHEN iv_sale_base_code IS NULL AND EXISTS( SELECT 'Y' 
--                                                             FROM   xxcos_login_base_info_v lbiv1 
--                                                             WHERE  seh.sales_base_code = lbiv1.base_code 
--                                                           ) THEN
--                    1
--                  WHEN iv_sale_base_code IS NOT NULL AND iv_sale_base_code = seh.sales_base_code THEN
--                    1
--                  ELSE
--                    0
--                 END
--                )
-- ******** 2009/08/13 1.5 N.Maeda MOD END *********** --
      --�[�i�����i����
      AND   seh.delivery_date >= id_dlv_date_from 
      AND   seh.delivery_date <= id_dlv_date_to
      --�c�ƒS�����i����
-- ******** 2009/08/13 1.5 N.Maeda MOD START *********** --
      AND  ( ( iv_sale_emp_code IS NULL )
             OR ( iv_sale_emp_code IS NOT NULL AND iv_sale_emp_code = seh.results_employee_code ) )
--      AND   1 = (
--                 CASE
--/* 2009/04/21 Ver1.2 Mod Start */
----                  WHEN iv_sale_emp_code IS NULL AND EXISTS( SELECT 'Y' 
----                                                            FROM   xxcos_rs_info_v riv1 
----                                                            WHERE  seh.sales_base_code       = riv1.base_code 
----                                                            AND    seh.results_employee_code = riv1.employee_number
----                                                            AND    seh.delivery_date >= riv1.effective_start_date
----                                                            AND    seh.delivery_date <= riv1.effective_end_date
----                                                          ) THEN
--                  WHEN iv_sale_emp_code IS NULL THEN
--/* 2009/04/21 Ver1.2 Mod End   */
--                    1
--                  WHEN iv_sale_emp_code IS NOT NULL AND iv_sale_emp_code = seh.results_employee_code THEN
--                    1
--                  ELSE
--                    0
--                 END
--                )
-- ******** 2009/08/13 1.5 N.Maeda MOD END *********** --
      --�o�א���i����
-- ******** 2009/08/13 1.5 N.Maeda MOD START *********** --
      AND ( ( iv_ship_to_code IS NULL AND EXISTS( SELECT 'Y' 
                                                  FROM   hz_cust_accounts    hca1,
                                                         xxcmm_cust_accounts xca1,
                                                         fnd_lookup_values   look_val
                                                  WHERE  hca1.cust_account_id  = xca1.customer_id 
                                                  AND    seh.sales_base_code   = xca1.sale_base_code
                                                  AND    look_val.language     = cv_lang
                                                  AND    look_val.lookup_type  = cv_cus_cls_type
                                                  AND    look_val.lookup_code  LIKE cv_cus_cls_code
                                                  AND    look_val.meaning      = hca1.customer_class_code
                                                  AND    gd_proc_date >= NVL( look_val.start_date_active, gd_min_date )
                                                  AND    gd_proc_date <= NVL( look_val.end_date_active, gd_max_date )
                                                  AND    look_val.enabled_flag = ct_enabled_flg_y
                                                  AND    seh.ship_to_customer_code = hca1.account_number ) )
            OR ( iv_ship_to_code IS NOT NULL AND iv_ship_to_code = seh.ship_to_customer_code ) )
--      AND   1 = (
--                 CASE
--                  WHEN iv_ship_to_code IS NULL 
--                    AND EXISTS( 
--                               SELECT 'Y' 
--                               FROM   hz_cust_accounts hca1,
--                                      xxcmm_cust_accounts xca1
--                               WHERE  hca1.cust_account_id  = xca1.customer_id 
--                               AND    seh.sales_base_code   = xca1.sale_base_code
--                               AND    EXISTS (
---- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
--                                             SELECT  'X'                         
--                                             FROM    fnd_lookup_values           look_val
--                                             WHERE   look_val.language           = cv_lang
--                                             AND     look_val.lookup_type        = cv_cus_cls_type
--                                             AND     look_val.lookup_code        LIKE cv_cus_cls_code
--                                             AND     look_val.meaning            = hca1.customer_class_code
--                                             AND     gd_proc_date >= NVL( look_val.start_date_active, gd_min_date )
--                                             AND     gd_proc_date <= NVL( look_val.end_date_active, gd_max_date )
--                                             AND     look_val.enabled_flag       = ct_enabled_flg_y
----
----                                             SELECT  'X'                         
----                                             FROM    fnd_lookup_values           look_val,
----                                                     fnd_lookup_types_tl         types_tl,
----                                                     fnd_lookup_types            types,
----                                                     fnd_application_tl          appl,
----                                                     fnd_application             app
----                                             WHERE   appl.application_id         = types.application_id
----                                             AND     app.application_id          = appl.application_id
----                                             AND     types_tl.lookup_type        = look_val.lookup_type
----                                             AND     types.lookup_type           = types_tl.lookup_type
----                                             AND     types.security_group_id     = types_tl.security_group_id
----                                             AND     types.view_application_id   = types_tl.view_application_id
----                                             AND     types_tl.language           = cv_lang
----                                             AND     look_val.language           = cv_lang
----                                             AND     appl.language               = cv_lang
----                                             AND     app.application_short_name  = cv_xxcos_short_name
----                                             AND     look_val.lookup_type        = cv_cus_cls_type
----                                             AND     look_val.lookup_code        LIKE cv_cus_cls_code
----                                             AND     look_val.meaning            = hca1.customer_class_code
----                                             AND     gd_proc_date >= NVL( look_val.start_date_active, gd_min_date )
----                                             AND     gd_proc_date <= NVL( look_val.end_date_active, gd_max_date )
----                                             AND     look_val.enabled_flag       = ct_enabled_flg_y
---- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
--                                             )
--                               AND    seh.ship_to_customer_code = hca1.account_number
--                              ) THEN
--                    1
--                  WHEN iv_ship_to_code IS NOT NULL AND iv_ship_to_code = seh.ship_to_customer_code THEN
--                    1
--                  ELSE
--                    0
--                 END
--                )
-- ******** 2009/08/13 1.5 N.Maeda MOD END *********** --
            --�c�ƌ��� IS NULL OR �[�i�P�� < �c�ƌ���
      AND   ( sel.business_cost IS NULL OR NVL( sel.standard_unit_price_excluded, 0 ) < sel.business_cost )
      AND   seh.sales_base_code       = lbiv.base_code            --���㋒�_�R�[�h
/* 2009/04/21 Ver1.2 Mod Start */
--      AND   seh.sales_base_code       = riv.base_code
--      AND   seh.results_employee_code = riv.employee_number       --�c�ƒS���҃R�[�h
--      AND   seh.delivery_date         >= riv.effective_start_date --�[�i��>=�c�ƈ����r���[.�K�p�J�n��
--      AND   seh.delivery_date         <= riv.effective_end_date   --�[�i��<=�c�ƈ����r���[.�K�p�I����
      AND   seh.results_employee_code = papf.employee_number       --�]�ƈ��R�[�h
      AND   seh.delivery_date         >= papf.effective_start_date --�[�i��>=�]�ƈ��}�X�^.�K�p�J�n��
      AND   seh.delivery_date         <= papf.effective_end_date   --�[�i��<=�]�ƈ��}�X�^.�K�p�I����
/* 2009/04/21 Ver1.2 Mod End   */
      AND   seh.ship_to_customer_code = hca.account_number        --�o�א�R�[�h
      AND   hca.party_id              = hp.party_id               --�p�[�e�B�[ID
      AND   sel.item_code             = msib.segment1             --�i�ڃR�[�h
      AND   msib.organization_id      = gt_org_id                 --�݌ɑg�DID
      AND   msib.segment1             = iimb.item_no              --OPM�i�ڃR�[�h
      AND   iimb.item_id              = ximb.item_id              --OPM�A�h�I���i��ID
      AND   seh.delivery_date         >= ximb.start_date_active   --�[�i��>=OPM�i�ڃA�h�I��.�K�p�J�n��
      AND   seh.delivery_date         <= ximb.end_date_active     --�[�i��<=OPM�i�ڃA�h�I��.�K�p�I����
      UNION ALL
      --�쐬���������v�Z�̏��i�ʔ���v�Z�i�S�ݓX�E�C���V���b�v�^���X�E���c�j�@�\��SQL
      SELECT  
-- 2009/09/02 Ver.1.6 Add Start
        /*+
          LEADING ( lbiv.obc.fu )
          INDEX   ( lbiv.obc.fu fnd_user_u1)
          USE_NL  ( lbiv.obc.papf )
          INDEX   ( lbiv.obc.papf per_people_f_pk)
          USE_NL  ( lbiv.obc.ppt )
          INDEX   ( lbiv.obc.ppt per_person_types_pk)
          USE_NL  ( lbiv.obc.paaf )
          INDEX   ( lbiv.obc.paaf per_assignments_f_n12)
          USE_NL  ( lbiv.xca )
          INDEX   ( lbiv.xca xxcmm_cust_accounts_pk )
          USE_NL  ( seh )
          INDEX   ( seh xxcos_sales_exp_headers_n01 )
        */
-- 2009/09/02 Ver.1.6 Add End
        seh.sales_base_code               base_code,        --���㋒�_�R�[�h
        lbiv.base_name                    base_name,        --���㋒�_��
        seh.results_employee_code         emp_code,         --�c�ƒS���҃R�[�h
/* 2009/04/21 Ver1.2 Mod Start */
--        riv.employee_name                 emp_name,         --�c�ƒS���Җ�
        papf.per_information18 || ' ' || papf.per_information19
                                          emp_name,         --�c�ƒS���Җ�
/* 2009/04/21 Ver1.2 Mod End   */
        seh.ship_to_customer_code         ship_to_cd,       --�o�א�R�[�h
        hp.party_name                     ship_to_nm,       --�o�א於
        seh.delivery_date                 dlv_date,         --�[�i��
        seh.dlv_invoice_number            dlv_slip_num,     --�[�i�`�[�ԍ�
        sel.item_code                     item_cd,          --�i�ڃR�[�h
        ximb.item_short_name              item_nm,          --�i�ږ�
        sel.standard_qty                  quantity,         --����
        sel.standard_uom_code             unit,             --�P��
        sel.standard_unit_price_excluded  dlv_price,        --�[�i�P��
        sel.business_cost                 biz_cost          --�c�ƌ���
      FROM    
        xxcos_sales_exp_headers seh,                        --�̔����уw�b�_
        xxcos_sales_exp_lines   sel,                        --�̔����і���
        xxcos_login_base_info_v lbiv,                       --���O�C�����[�U���_�r���[
/* 2009/04/21 Ver1.2 Mod Start */
--        xxcos_rs_info_v         riv,                        --�c�ƈ����r���[
        per_all_people_f        papf,                       --�]�ƈ��}�X�^
/* 2009/04/21 Ver1.2 Mod End   */
        hz_cust_accounts        hca,                        --�ڋq�}�X�^
        hz_parties              hp,                         --�p�[�e�B
        mtl_system_items_b      msib,                       --Disc�i�ڃ}�X�^
        ic_item_mst_b           iimb,                       --OPM�i�ڃ}�X�^
        xxcmn_item_mst_b        ximb                        --OPM�i�ڃA�h�I��
      WHERE seh.sales_exp_header_id = sel.sales_exp_header_id                         --�̔����уw�b�_ID
      --�쐬���敪�̃N�C�b�N�Q��
      AND   EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_mk_org_type
              AND     look_val.lookup_code        LIKE cv_mk_org_code2
              AND     look_val.meaning            = seh.create_class
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_mk_org_type
--              AND     look_val.lookup_code        LIKE cv_mk_org_code2
--              AND     look_val.meaning            = seh.create_class
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                  )
      --����敪�̃N�C�b�N�Q��
      AND   EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_sl_cls_type
              AND     look_val.lookup_code        LIKE cv_sl_cls_code2
              AND     look_val.meaning            = sel.sales_class
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_sl_cls_type
--              AND     look_val.lookup_code        LIKE cv_sl_cls_code2
--              AND     look_val.meaning            = sel.sales_class
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                  )
      --��݌ɕi�ڃR�[�h�̃N�C�b�N�Q��
      AND   NOT EXISTS(
-- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
              SELECT  'Y'                         ext_flg
              FROM    fnd_lookup_values           look_val
              WHERE   look_val.language           = cv_lang
              AND     look_val.lookup_type        = cv_no_inv_item_type
              AND     look_val.lookup_code        = sel.item_code
              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
              AND     look_val.enabled_flag       = ct_enabled_flg_y
--
--              SELECT  'Y'                         ext_flg
--              FROM    fnd_lookup_values           look_val,
--                      fnd_lookup_types_tl         types_tl,
--                      fnd_lookup_types            types,
--                      fnd_application_tl          appl,
--                      fnd_application             app
--              WHERE   appl.application_id         = types.application_id
--              AND     app.application_id          = appl.application_id
--              AND     types_tl.lookup_type        = look_val.lookup_type
--              AND     types.lookup_type           = types_tl.lookup_type
--              AND     types.security_group_id     = types_tl.security_group_id
--              AND     types.view_application_id   = types_tl.view_application_id
--              AND     types_tl.language           = cv_lang
--              AND     look_val.language           = cv_lang
--              AND     appl.language               = cv_lang
--              AND     app.application_short_name  = cv_xxcos_short_name
--              AND     look_val.lookup_type        = cv_no_inv_item_type
--              AND     look_val.lookup_code        = sel.item_code
--              AND     gd_proc_date                >= NVL( look_val.start_date_active, gd_min_date )
--              AND     gd_proc_date                <= NVL( look_val.end_date_active, gd_max_date )
--              AND     look_val.enabled_flag       = ct_enabled_flg_y
-- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
                      )
      --���㋒�_�R�[�h���i����
-- ******** 2009/08/13 1.5 N.Maeda MOD START *********** --
-- 2009/09/02 Ver.1.6 Mod Start
      AND  ( ( iv_sale_base_code IS NULL )
--      AND  ( ( iv_sale_base_code IS NULL AND EXISTS( SELECT 'Y' 
--                                                     FROM   xxcos_login_base_info_v lbiv1 
--                                                     WHERE  seh.sales_base_code = lbiv1.base_code ) )
-- 2009/09/02 Ver.1.6 Mod End
             OR ( iv_sale_base_code IS NOT NULL AND iv_sale_base_code = seh.sales_base_code ) )
--      AND   1 = (
--                 CASE
--                  WHEN iv_sale_base_code IS NULL AND EXISTS( SELECT 'Y' 
--                                                             FROM   xxcos_login_base_info_v lbiv1 
--                                                             WHERE  seh.sales_base_code = lbiv1.base_code 
--                                                           ) THEN
--                    1
--                  WHEN iv_sale_base_code IS NOT NULL AND iv_sale_base_code = seh.sales_base_code THEN
--                    1
--                  ELSE
--                    0
--                 END
--                )
-- ******** 2009/08/13 1.5 N.Maeda MOD END *********** --
      --�[�i�����i����
      AND   seh.delivery_date >= id_dlv_date_from 
      AND   seh.delivery_date <= id_dlv_date_to
      --�c�ƒS�����i����
-- ******** 2009/08/13 1.5 N.Maeda MOD START *********** --
      AND   ( ( iv_sale_emp_code IS NULL )
              OR ( iv_sale_emp_code IS NOT NULL AND iv_sale_emp_code = seh.results_employee_code ) )
--      AND   1 = (
--                 CASE
--/* 2009/04/21 Ver1.2 Mod Start */
----                  WHEN iv_sale_emp_code IS NULL AND EXISTS( SELECT 'Y' 
----                                                            FROM   xxcos_rs_info_v riv1 
----                                                            WHERE  seh.sales_base_code       = riv1.base_code 
----                                                            AND    seh.results_employee_code = riv1.employee_number
----                                                            AND    seh.delivery_date >= riv1.effective_start_date
----                                                           AND    seh.delivery_date <= riv1.effective_end_date
----                                                          ) THEN
--                  WHEN iv_sale_emp_code IS NULL THEN
--/* 2009/04/21 Ver1.2 Mod End   */
--                    1
--                  WHEN iv_sale_emp_code IS NOT NULL AND iv_sale_emp_code = seh.results_employee_code THEN
--                    1
--                  ELSE
--                    0
--                 END
--                )
-- ******** 2009/08/13 1.5 N.Maeda MOD END *********** --
      --�o�א���i����
-- ******** 2009/08/13 1.5 N.Maeda MOD START *********** --
      AND  ( ( iv_ship_to_code IS NULL AND EXISTS( SELECT 'Y' 
                                                   FROM   hz_cust_accounts    hca1,
                                                          xxcmm_cust_accounts xca1,
                                                          fnd_lookup_values   look_val
                                                   WHERE  hca1.cust_account_id  = xca1.customer_id 
                                                   AND    seh.sales_base_code   = xca1.sale_base_code
                                                   AND    look_val.language     = cv_lang
                                                   AND    look_val.lookup_type = cv_cus_cls_type
                                                   AND    look_val.lookup_code LIKE cv_cus_cls_code
                                                   AND    look_val.meaning     = hca1.customer_class_code
                                                   AND    gd_proc_date >= NVL( look_val.start_date_active, gd_min_date )
                                                   AND    gd_proc_date <= NVL( look_val.end_date_active, gd_max_date )
                                                   AND    look_val.enabled_flag = ct_enabled_flg_y
                                                   AND    seh.ship_to_customer_code = hca1.account_number ) )
             OR ( iv_ship_to_code IS NOT NULL AND iv_ship_to_code = seh.ship_to_customer_code ) )
--      AND   1 = (
--                 CASE
--                  WHEN iv_ship_to_code IS NULL 
--                    AND EXISTS( 
--                               SELECT 'Y' 
--                               FROM   hz_cust_accounts hca1,
--                                      xxcmm_cust_accounts xca1
--                               WHERE  hca1.cust_account_id  = xca1.customer_id 
--                               AND    seh.sales_base_code   = xca1.sale_base_code
--                               AND    EXISTS (
---- ******** 2009/08/11 1.5 N.Maeda MOD START *********** --
--                                             SELECT  'X'                         
--                                             FROM    fnd_lookup_values           look_val
--                                             WHERE   look_val.language           = cv_lang
--                                             AND     look_val.lookup_type        = cv_cus_cls_type
--                                             AND     look_val.lookup_code        LIKE cv_cus_cls_code
--                                             AND     look_val.meaning            = hca1.customer_class_code
--                                             AND     gd_proc_date >= NVL( look_val.start_date_active, gd_min_date )
--                                             AND     gd_proc_date <= NVL( look_val.end_date_active, gd_max_date )
--                                             AND     look_val.enabled_flag       = ct_enabled_flg_y
----
----                                             SELECT  'X'                         
----                                             FROM    fnd_lookup_values           look_val,
----                                                     fnd_lookup_types_tl         types_tl,
----                                                     fnd_lookup_types            types,
----                                                     fnd_application_tl          appl,
----                                                     fnd_application             app
----                                             WHERE   appl.application_id         = types.application_id
----                                             AND     app.application_id          = appl.application_id
----                                             AND     types_tl.lookup_type        = look_val.lookup_type
----                                             AND     types.lookup_type           = types_tl.lookup_type
----                                             AND     types.security_group_id     = types_tl.security_group_id
----                                             AND     types.view_application_id   = types_tl.view_application_id
----                                             AND     types_tl.language           = cv_lang
----                                             AND     look_val.language           = cv_lang
----                                             AND     appl.language               = cv_lang
----                                             AND     app.application_short_name  = cv_xxcos_short_name
----                                             AND     look_val.lookup_type        = cv_cus_cls_type
----                                             AND     look_val.lookup_code        LIKE cv_cus_cls_code
----                                             AND     look_val.meaning            = hca1.customer_class_code
----                                             AND     gd_proc_date >= NVL( look_val.start_date_active, gd_min_date )
----                                             AND     gd_proc_date <= NVL( look_val.end_date_active, gd_max_date )
----                                             AND     look_val.enabled_flag       = ct_enabled_flg_y
---- ******** 2009/08/11 1.5 N.Maeda MOD END *********** --
--                                             )
--                               AND    seh.ship_to_customer_code = hca1.account_number
--                              ) THEN
--                    1
--                  WHEN iv_ship_to_code IS NOT NULL AND iv_ship_to_code = seh.ship_to_customer_code THEN
--                    1
--                  ELSE
--                    0
--                 END
--                )
-- ******** 2009/08/13 1.5 N.Maeda MOD END *********** --
            --�c�ƌ��� IS NULL OR �[�i�P�� < �c�ƌ���
      AND   ( sel.business_cost IS NULL OR NVL( sel.standard_unit_price_excluded, 0 ) < sel.business_cost )
      AND   seh.sales_base_code       = lbiv.base_code            --���㋒�_�R�[�h
/* 2009/04/21 Ver1.2 Mod Start */
--      AND   seh.sales_base_code       = riv.base_code
--      AND   seh.results_employee_code = riv.employee_number       --�c�ƒS���҃R�[�h
--      AND   seh.delivery_date         >= riv.effective_start_date --�[�i��>=�c�ƈ����r���[.�K�p�J�n��
--      AND   seh.delivery_date         <= riv.effective_end_date   --�[�i��<=�c�ƈ����r���[.�K�p�I����
      AND   seh.results_employee_code = papf.employee_number       --�]�ƈ��R�[�h
      AND   seh.delivery_date         >= papf.effective_start_date --�[�i��>=�]�ƈ��}�X�^.�K�p�J�n��
      AND   seh.delivery_date         <= papf.effective_end_date   --�[�i��<=�]�ƈ��}�X�^.�K�p�I����
/* 2009/04/21 Ver1.2 Mod End   */
      AND   seh.ship_to_customer_code = hca.account_number        --�o�א�R�[�h
      AND   hca.party_id              = hp.party_id               --�p�[�e�B�[ID
      AND   sel.item_code             = msib.segment1             --�i�ڃR�[�h
      AND   msib.organization_id      = gt_org_id                 --�݌ɑg�DID
      AND   msib.segment1             = iimb.item_no              --OPM�i�ڃR�[�h
      AND   iimb.item_id              = ximb.item_id              --OPM�A�h�I���i��ID
      AND   seh.delivery_date         >= ximb.start_date_active   --�[�i��>=OPM�i�ڃA�h�I��.�K�p�J�n��
      AND   seh.delivery_date         <= ximb.end_date_active     --�[�i��<=OPM�i�ڃA�h�I��.�K�p�I����
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_data_rec                data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --���[�v�J�E���g������
    ln_idx          := 0;
    ln_err_item_idx := 0;
    --�t���O������
    lb_ext_flg      := FALSE;
    --�Ώۃf�[�^�擾
    <<loop_get_data>>
    FOR l_data_rec IN data_cur LOOP
      -- ���R�[�hID�̎擾
      BEGIN
        SELECT
          xxcos_rep_cost_div_list_s01.NEXTVAL     redord_id
        INTO
          lt_record_id
        FROM
          dual
        ;
      END;
      --
      ln_idx := ln_idx + 1;
      g_report_data_tab(ln_idx).record_id              := lt_record_id;                --���R�[�hID
      g_report_data_tab(ln_idx).base_code              := l_data_rec.base_code;        --���_�R�[�h
      g_report_data_tab(ln_idx).base_name              := l_data_rec.base_name;        --���_����
      g_report_data_tab(ln_idx).dlv_date_start         := id_dlv_date_from;            --�[�i���J�n
      g_report_data_tab(ln_idx).dlv_date_end           := id_dlv_date_to;              --�[�i���I��
      g_report_data_tab(ln_idx).employee_base_code     := l_data_rec.emp_code;         --�c�ƒS���҃R�[�h
      g_report_data_tab(ln_idx).employee_base_name     := SUBSTRB( l_data_rec.emp_name, 1, 14 );
                                                                                       --�c�ƒS���Җ�
      g_report_data_tab(ln_idx).deliver_to_code        := l_data_rec.ship_to_cd;       --�o�א�R�[�h
      g_report_data_tab(ln_idx).deliver_to_name        := SUBSTRB( l_data_rec.ship_to_nm, 1, 30 );
                                                                                       --�o�א於
      g_report_data_tab(ln_idx).dlv_date               := l_data_rec.dlv_date;         --�[�i��
      g_report_data_tab(ln_idx).dlv_invoice_number     := l_data_rec.dlv_slip_num;     --�[�i�`�[�ԍ�
      g_report_data_tab(ln_idx).item_code              := l_data_rec.item_cd;          --�i�ڃR�[�h
      g_report_data_tab(ln_idx).order_item_name        := l_data_rec.item_nm;          --�󒍕i��
      g_report_data_tab(ln_idx).quantity               := l_data_rec.quantity;         --����
      g_report_data_tab(ln_idx).uom_code               := l_data_rec.unit;             --�P��
      g_report_data_tab(ln_idx).dlv_unit_price         := l_data_rec.dlv_price;        --�[�i�P��
      g_report_data_tab(ln_idx).sale_amount            := l_data_rec.quantity * l_data_rec.dlv_price;
                                                                                       --������z
      g_report_data_tab(ln_idx).created_by             := cn_created_by;               --�쐬��
      g_report_data_tab(ln_idx).creation_date          := cd_creation_date;            --�쐬��
      g_report_data_tab(ln_idx).last_updated_by        := cn_last_updated_by;          --�ŏI�X�V��
      g_report_data_tab(ln_idx).last_update_date       := cd_last_update_date;         --�ŏI�X�V��
      g_report_data_tab(ln_idx).last_update_login      := cn_last_update_login;        --�ŏI�X�V۸޲�
      g_report_data_tab(ln_idx).request_id             := cn_request_id;               --�v��ID
      g_report_data_tab(ln_idx).program_application_id := cn_program_application_id;   --�ݶ��ĥ��۸��ѥ���ع����ID
      g_report_data_tab(ln_idx).program_id             := cn_program_id;               --�ݶ��ĥ��۸���ID
      g_report_data_tab(ln_idx).program_update_date    := cd_program_update_date;      --��۸��эX�V��
      --�c�ƌ�����s�`�F�b�N
      IF ( l_data_rec.biz_cost IS NULL ) THEN
        --�x�������v��
        gn_warn_cnt := gn_warn_cnt + 1;
        --�t���O�N���A
        lb_ext_flg  := FALSE;
        --�Y���i�ڃR�[�h�̐ݒ�σ`�F�b�N
        <<loop_search>>
        FOR ln_search IN 1 .. g_err_item_cd_tab.COUNT LOOP
          IF ( g_err_item_cd_tab(ln_search) = l_data_rec.item_cd ) THEN
            lb_ext_flg := TRUE;
            EXIT;
          END IF;
        END LOOP loop_search;
        --�Y���i�ڃR�[�h�����ݒ�̏ꍇ�A�ݒ��
        IF ( lb_ext_flg = FALSE ) THEN
          ln_err_item_idx                    := ln_err_item_idx + 1;
          --�c�ƌ������ݒ�̕i�ڃR�[�h���W�񂵂ĕێ�
          g_err_item_cd_tab(ln_err_item_idx) := l_data_rec.item_cd;
        END IF;
      END IF;
    END LOOP loop_get_data;
--
    --���������J�E���g
    gn_target_cnt := g_report_data_tab.COUNT;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : check_cost
   * Description      : �c�ƌ����`�F�b�N(A-4)
   ***********************************************************************************/
  PROCEDURE check_cost(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_cost'; -- �v���O������
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
    ln_cnt      NUMBER;          -- �G���[�i�ڃR�[�h����
    lv_warnmsg  VARCHAR2(5000);  -- ���[�U�[�E�x���E���b�Z�[�W
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
    --�c�ƌ����擾�G���[���b�Z�[�W�o��
    ln_cnt := g_err_item_cd_tab.COUNT;
    <<msg_out_loop>>
    FOR ln_inx IN 1..ln_cnt LOOP
      --���b�Z�[�W�擾
      lv_warnmsg              :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_sale_cost_get_err,
        iv_token_name1        =>  cv_tkn_nm_item_code,
        iv_token_value1       =>  g_err_item_cd_tab(ln_inx)
      );
      --���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_warnmsg --���[�U�[�E�x���E���b�Z�[�W
      );
    END LOOP msg_out_loop;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END check_cost;
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���o�^(A-5)
   ***********************************************************************************/
  PROCEDURE insert_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_rpt_wrk_data'; -- �v���O������
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
    lv_tkn_vl_table_name      VARCHAR2(100);      --�Ώۃe�[�u����
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
    --���[���[�N�e�[�u���o�^����
    BEGIN
      FORALL ln_cnt IN g_report_data_tab.FIRST .. g_report_data_tab.LAST
        INSERT INTO 
          xxcos_rep_cost_div_list
        VALUES
          g_report_data_tab(ln_cnt)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_data_insert_expt;
    END;
--
    --���팏���擾
    gn_normal_cnt := g_report_data_tab.COUNT;
--
  EXCEPTION
    --*** �����Ώۃf�[�^�o�^��O ***
    WHEN global_data_insert_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name1
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_insert_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  NULL
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : SVF�N��(A-6)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- �v���O������
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
    lv_nodata_msg       VARCHAR2(5000);   --����0���p���b�Z�[�W
    lv_file_name        VARCHAR2(100);    --�o�̓t�@�C����
    lv_tkn_vl_api_name  VARCHAR2(100);    --API��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --����0���p���b�Z�[�W�擾
    lv_nodata_msg           :=  xxccp_common_pkg.get_msg(
      iv_application        =>  cv_xxcos_short_name,
      iv_name               =>  cv_msg_no_data_err
    );
--
    --�o�̓t�@�C�����ҏW
    lv_file_name := cv_report_id || TO_CHAR( SYSDATE, cv_yyyymmdd ) || TO_CHAR( cn_request_id ) || cv_extension;
--
    --SVF�N��
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              =>  lv_retcode,
      ov_errbuf               =>  lv_errbuf,
      ov_errmsg               =>  lv_errmsg,
      iv_conc_name            =>  cv_conc_name,
      iv_file_name            =>  lv_file_name,
      iv_file_id              =>  cv_report_id,
      iv_output_mode          =>  cv_output_mode,
      iv_frm_file             =>  cv_frm_file,
      iv_vrq_file             =>  cv_vrq_file,
      iv_org_id               =>  NULL,
      iv_user_name            =>  NULL,
      iv_resp_name            =>  NULL,
      iv_doc_name             =>  NULL,
      iv_printer_name         =>  NULL,
      iv_request_id           =>  TO_CHAR( cn_request_id ),
      iv_nodata_msg           =>  lv_nodata_msg,
      iv_svf_param1           =>  NULL,
      iv_svf_param2           =>  NULL,
      iv_svf_param3           =>  NULL,
      iv_svf_param4           =>  NULL,
      iv_svf_param5           =>  NULL,
      iv_svf_param6           =>  NULL,
      iv_svf_param7           =>  NULL,
      iv_svf_param8           =>  NULL,
      iv_svf_param9           =>  NULL,
      iv_svf_param10          =>  NULL,
      iv_svf_param11          =>  NULL,
      iv_svf_param12          =>  NULL,
      iv_svf_param13          =>  NULL,
      iv_svf_param14          =>  NULL,
      iv_svf_param15          =>  NULL
    );
    --SVF�N�����s
    IF  ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_svf_excute_expt;
    END IF;
--
  EXCEPTION
    --*** SVF�N����O ***
    WHEN global_svf_excute_expt THEN
      lv_tkn_vl_api_name      :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_api_name
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_api_err,
        iv_token_name1        =>  cv_tkn_nm_api_name,
        iv_token_value1       =>  lv_tkn_vl_api_name
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
  END execute_svf;
--
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���폜(A-7)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- �v���O������
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
    lv_key_info               VARCHAR2(5000);     --�L�[���
    lv_tkn_vl_key_request_id  VARCHAR2(100);      --�v��ID�̕���
    lv_tkn_vl_table_name      VARCHAR2(100);      --�Ώۃe�[�u����
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur
    IS
      SELECT cdl.record_id rec_id
      FROM   xxcos_rep_cost_div_list cdl       --��������`�F�b�N���X�g���[���[�N�e�[�u��
      WHERE cdl.request_id = cn_request_id     --�v��ID
      FOR UPDATE NOWAIT
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
    --�Ώۃf�[�^���b�N
    BEGIN
      -- ���b�N�p�J�[�\���I�[�v��
      OPEN lock_cur;
      -- ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_cur;
    EXCEPTION
      --�Ώۃf�[�^���b�N��O
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
    --�Ώۃf�[�^�폜
    BEGIN
      DELETE FROM 
        xxcos_rep_cost_div_list cdl            --��������`�F�b�N���X�g���[���[�N�e�[�u��
      WHERE cdl.request_id = cn_request_id     --�v��ID
      ;
    EXCEPTION
     --�Ώۃf�[�^�폜���s
     WHEN OTHERS THEN
      lv_tkn_vl_key_request_id  :=  xxccp_common_pkg.get_msg(
        iv_application          =>  cv_xxcos_short_name,
        iv_name                 =>  cv_msg_vl_key_request_id
      );
      xxcos_common_pkg.makeup_key_info(
        iv_item_name1         =>  lv_tkn_vl_key_request_id,   --�v��ID�̕���
        iv_data_value1        =>  TO_CHAR( cn_request_id ),   --�v��ID
        ov_key_info           =>  lv_key_info,                --�ҏW���ꂽ�L�[���
        ov_errbuf             =>  lv_errbuf,                  --�G���[���b�Z�[�W
        ov_retcode            =>  lv_retcode,                 --���^�[���R�[�h
        ov_errmsg             =>  lv_errmsg                   --���[�U�E�G���[�E���b�Z�[�W
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_data_delete_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      -- �J�[�\���I�[�v�����A�N���[�Y��
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name1
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_lock_err,
        iv_token_name1        =>  cv_tkn_nm_table_lock,
        iv_token_value1       =>  lv_tkn_vl_table_name
      );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** �����Ώۃf�[�^�폜��O�n���h�� ***
    WHEN global_data_delete_expt THEN
      lv_tkn_vl_table_name    :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_vl_table_name1
      );
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_delete_err,
        iv_token_name1        =>  cv_tkn_nm_table_name,
        iv_token_value1       =>  lv_tkn_vl_table_name,
        iv_token_name2        =>  cv_tkn_nm_key_data,
        iv_token_value2       =>  lv_key_info
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
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_sale_base_code   IN  VARCHAR2,     --   ���㋒�_�R�[�h
    iv_dlv_date_from    IN  VARCHAR2,     --   �[�i��(FROM)
    iv_dlv_date_to      IN  VARCHAR2,     --   �[�i��(TO)
    iv_sale_emp_code    IN  VARCHAR2,     --   �c�ƒS���҃R�[�h
    iv_ship_to_code     IN  VARCHAR2,     --   �o�א�R�[�h
    ov_errbuf           OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_dlv_date_from    DATE;         --   �[�i��(FROM)
    ld_dlv_date_to      DATE;         --   �[�i��(TO)
--
--2009/06/25  Ver1.4 T1_1437  Add start
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h(SVF���s���ʕێ��p)
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
--2009/06/25  Ver1.4 T1_1437  Add end
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ===============================
    -- A-1  ��������
    -- ===============================
    init(
      iv_sale_base_code,  -- ���㋒�_�R�[�h
      iv_dlv_date_from,   -- �[�i��(FROM)
      iv_dlv_date_to,     -- �[�i��(TO)
      iv_sale_emp_code,   -- �c�ƒS���҃R�[�h
      iv_ship_to_code,    -- �o�א�R�[�h
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      iv_dlv_date_from,   -- �[�i��(FROM)
      iv_dlv_date_to,     -- �[�i��(TO)
      ld_dlv_date_from,   -- �[�i��(FROM)_�`�F�b�NOK
      ld_dlv_date_to,     -- �[�i��(TO)_�`�F�b�NOK
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      iv_sale_base_code,  -- ���㋒�_�R�[�h
      ld_dlv_date_from,   -- �[�i��(FROM)
      ld_dlv_date_to,     -- �[�i��(TO)
      iv_sale_emp_code,   -- �c�ƒS���҃R�[�h
      iv_ship_to_code,    -- �o�א�R�[�h
      lv_errbuf,          -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,         -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-4  �c�ƌ����`�F�b�N
    -- ===============================
    IF ( g_err_item_cd_tab.COUNT > 0 ) THEN
     check_cost(
       lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
       lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
       lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     IF ( lv_retcode = cv_status_normal ) THEN
       NULL;
     ELSE
       RAISE global_process_expt;
     END IF;
    END IF;
--
    -- ===============================
    -- A-5  ���[���[�N�e�[�u���o�^
    -- ===============================
    insert_rpt_wrk_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-6  SVF�N��
    -- ===============================
    execute_svf(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
-- 2009/06/25  Ver1.4  T1_1437  Mod Start
--    IF ( lv_retcode = cv_status_normal ) THEN
--      NULL;
--    ELSE
--      RAISE global_process_expt;
--    END IF;
    --
    --�G���[�ł����[�N�e�[�u�����폜����ׁA�G���[����ێ�
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
-- 2009/06/25  Ver1.4 T1_1437  Mod End
--
    -- ===============================
    -- A-7  ���[���[�N�e�[�u���폜
    -- ===============================
    delete_rpt_wrk_data(
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
-- 2009/06/25  Ver1.4 T1_1437  Add start
    --�G���[�̏ꍇ�A���[���o�b�N����̂ł����ŃR�~�b�g
    COMMIT;
--
    --SVF���s���ʊm�F
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
-- 2009/06/25  Ver1.4 T1_1437  Add End
--
    --����0�����^�c�ƌ����`�F�b�N�G���[���X�e�[�^�X���䏈��
--****************************** 2009/06/17 1.3 N.Nishimura MOD START ******************************--
--    IF ( gn_target_cnt = 0 OR gn_warn_cnt > 0 ) THEN
    IF ( gn_target_cnt <> 0 ) THEN
--****************************** 2009/06/17 1.3 N.Nishimura MOD  END  ******************************--
      ov_retcode := cv_status_warn;
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
    errbuf              OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_sale_base_code   IN  VARCHAR2,      --   ���㋒�_�R�[�h
    iv_dlv_date_from    IN  VARCHAR2,      --   �[�i��(FROM)
    iv_dlv_date_to      IN  VARCHAR2,      --   �[�i��(TO)
    iv_sale_emp_code    IN  VARCHAR2,      --   �c�ƒS���҃R�[�h
    iv_ship_to_code     IN  VARCHAR2       --   �o�א�R�[�h
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
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
       iv_sale_base_code
      ,iv_dlv_date_from
      ,iv_dlv_date_to
      ,iv_sale_emp_code
      ,iv_ship_to_code
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
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
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
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
END XXCOS009A03R;
/
