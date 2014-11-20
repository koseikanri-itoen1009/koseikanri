CREATE OR REPLACE PACKAGE BODY APPS.XXCOS012A04R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS012A04R (body)
 * Description      : �s�b�N���X�g�i�o�׌��ۊǏꏊ�E���i�ʁj
 * MD.050           : �s�b�N���X�g�i�o�׌��ۊǏꏊ�E���i�ʁj MD050_COS_012_A04
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-0)
 *  check_parameter        �p�����[�^�`�F�b�N����(A-1)
 *  get_data               �f�[�^�擾(A-2)
 *  insert_rpt_wrk_data    ���[���[�N�e�[�u���o�^(A-3)
 *  execute_svf            �r�u�e�N��(A-4)
 *  delete_rpt_wrk_data    ���[���[�N�e�[�u���폜(A-5)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2013/07/02    1.0   K.Kiriu          �V�K�쐬
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  global_proc_date_err_expt EXCEPTION;
  global_call_api_expt      EXCEPTION;
  global_date_reversal_expt EXCEPTION;
  global_insert_data_expt   EXCEPTION;
  global_delete_data_expt   EXCEPTION;
  global_get_profile_expt   EXCEPTION;
  global_lookup_code_expt   EXCEPTION;
  --*** �����Ώۃf�[�^���b�N��O ***
  global_data_lock_expt     EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS012A04R';          -- �p�b�P�[�W��
--
  cv_conc_name              CONSTANT VARCHAR2(100) := 'XXCOS012A04R';          -- �R���J�����g��
  cv_file_id                CONSTANT VARCHAR2(100) := 'XXCOS012A04R';          -- ���[�h�c
  cv_extension_pdf          CONSTANT VARCHAR2(100) := '.pdf';                  -- �g���q�i�o�c�e�j
  cv_frm_file               CONSTANT VARCHAR2(100) := 'XXCOS012A04S.xml';      -- �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT VARCHAR2(100) := 'XXCOS012A04S.vrq';      -- �N�G���[�l���t�@�C����
  cv_output_mode_pdf        CONSTANT VARCHAR2(1)   := '1';                     -- �o�͋敪�i�o�c�e�j
--
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name  CONSTANT fnd_application.application_short_name%TYPE
                                     := 'XXCOS';                      --�̕��Z�k�A�v����
  ct_xxcoi_short_name       CONSTANT fnd_application.application_short_name%TYPE
                                     := 'XXCOI';                      --�݌ɗ̈�Z�k�A�v����
  --�̕����b�Z�[�W
  ct_msg_lock_err           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00001';           --���b�N�擾�G���[���b�Z�[�W
  ct_msg_get_profile_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00004';           --�v���t�@�C���擾�G���[
  ct_msg_date_reversal_err  CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00005';           --���t�t�]�G���[
  ct_msg_insert_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00010';           --�f�[�^�o�^�G���[���b�Z�[�W
  ct_msg_delete_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00012';           --�f�[�^�폜�G���[���b�Z�[�W
  ct_msg_select_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00013';           --�f�[�^�擾�G���[���b�Z�[�W
  ct_msg_process_date_err   CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00014';           --�Ɩ����t�擾�G���[
  ct_msg_call_api_err       CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00017';           --API�ďo�G���[���b�Z�[�W
  ct_msg_nodata_err         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00018';           --����0���p���b�Z�[�W
  ct_msg_svf_api            CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00041';           --�r�u�e�N���`�o�h
  ct_msg_request            CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00042';           --�v���h�c
  ct_msg_org_id             CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00047';           --MO:�c�ƒP��
  ct_msg_max_date           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00056';           --XXCOS:MAX���t
  ct_msg_case_uom_code      CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00057';           --XXCOS:�P�[�X�P�ʃR�[�h
  ct_msg_parameter          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-14701';           --�p�����[�^�o�̓��b�Z�[�W
  ct_msg_req_dt_from        CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12702';           --����(From)
  ct_msg_req_dt_to          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12703';           --����(To)
  ct_msg_rpt_wrk_tbl        CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-14702';           --���[���[�N�e�[�u��
  ct_msg_bargain_cls_tblnm  CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12705';           --��ԓ����敪�N�C�b�N�R�[�h�}�X�^
  ct_msg_teiban_get_err     CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00186';           --��ԏ��擾�G���[
  ct_msg_tokuban_get_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00187';           --���ԏ��擾�G���[
  cv_msg_org_cd_err         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOI1-00005';           --�݌ɑg�D�R�[�h�擾�G���[���b�Z�[�W
  cv_msg_org_id_err         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOI1-00006';           --�݌ɑg�DID�擾�G���[���b�Z�[�W
  ct_msg_get_hon_uom        CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-12706';           --XXCOS:�{�P�ʃR�[�h(���b�Z�[�W������)
  --�g�[�N��
  cv_tkn_table              CONSTANT VARCHAR2(100) := 'TABLE';        -- �e�[�u��
  cv_tkn_date_from          CONSTANT VARCHAR2(100) := 'DATE_FROM';    -- ���t�iFrom)
  cv_tkn_date_to            CONSTANT VARCHAR2(100) := 'DATE_TO';      -- ���t�iTo)
  cv_tkn_profile            CONSTANT VARCHAR2(100) := 'PROFILE';      -- �v���t�@�C��
  cv_tkn_table_name         CONSTANT VARCHAR2(100) := 'TABLE_NAME';   -- �e�[�u������
  cv_tkn_key_data           CONSTANT VARCHAR2(100) := 'KEY_DATA';     -- �L�[�f�[�^
  cv_tkn_api_name           CONSTANT VARCHAR2(100) := 'API_NAME';     -- �`�o�h����
  cv_tkn_param1             CONSTANT VARCHAR2(100) := 'PARAM1';       -- ��P���̓p�����[�^
  cv_tkn_param2             CONSTANT VARCHAR2(100) := 'PARAM2';       -- ��Q���̓p�����[�^
  cv_tkn_param3             CONSTANT VARCHAR2(100) := 'PARAM3';       -- ��R���̓p�����[�^
  cv_tkn_param4             CONSTANT VARCHAR2(100) := 'PARAM4';       -- ��S���̓p�����[�^
  cv_tkn_param5             CONSTANT VARCHAR2(100) := 'PARAM5';       -- ��T���̓p�����[�^
  cv_tkn_param6             CONSTANT VARCHAR2(100) := 'PARAM6';       -- ��U���̓p�����[�^
  cv_tkn_param7             CONSTANT VARCHAR2(100) := 'PARAM7';       -- ��V���̓p�����[�^
  cv_tkn_request            CONSTANT VARCHAR2(100) := 'REQUEST';      -- �v���h�c
  cv_tkn_nm_profile2        CONSTANT VARCHAR2(100) := 'PRO_TOK';      -- �v���t�@�C����(�݌ɗ̈�)
  cv_tkn_nm_org_cd          CONSTANT VARCHAR2(100) := 'ORG_CODE_TOK'; -- �݌ɑg�D�R�[�h
  --�v���t�@�C������
  ct_prof_org_id            CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'ORG_ID';                     -- MO: �c�ƒP��
  ct_prof_max_date          CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'XXCOS1_MAX_DATE';            -- XXCOS:MAX���t
  ct_prof_case_uom_code     CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'XXCOS1_CASE_UOM_CODE';       -- XXCOS:�P�[�X�P�ʃR�[�h
  cv_prof_org               CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'XXCOI1_ORGANIZATION_CODE';   -- XXCOI:�݌ɑg�D�R�[�h
  ct_hon_uom_code           CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'XXCOS1_HON_UOM_CODE';        -- XXCOS:�{�P�ʃR�[�h
  --�N�C�b�N�R�[�h�^�C�v
  ct_qct_order_type         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_TRAN_TYPE_MST_012_A03';
  ct_qct_order_source       CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_ODR_SRC_MST_012_A03';
  ct_qct_sale_class         CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_SALE_CLASS_MST_012_A03';
  ct_qct_sale_class_default CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_SALE_CLASS_MST';
  ct_qct_bargain_class      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_BARGAIN_CLASS';
  ct_qct_cus_class_mst      CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_CUS_CLASS_MST_012_A03';
  ct_qct_edi_item_err_type  CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_EDI_ITEM_ERR_TYPE';
  ct_xxcos1_no_inv_item_code CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_NO_INV_ITEM_CODE';
  --�N�C�b�N�R�[�h
  ct_qcc_order_type         CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_012_A03%';
  ct_qcc_ord_src_manual     CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_012_A03_1%';
  ct_qcc_ord_src_edi        CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_012_A03_2%';
  ct_qcc_sale_class         CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_012_A03_';
  ct_qcc_sale_class_default CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_%';
  ct_qcc_cus_class_mst1     CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_012_A03_1%';
  ct_qcc_cus_class_mst2     CONSTANT fnd_lookup_values.lookup_code%TYPE
                                     := 'XXCOS_012_A03_2%';
  --�}���`����������
  cv_multi                  CONSTANT VARCHAR2(1)   := '%';
  --�Q�ƃ^�C�v�g�p�\�t���O�萔
  ct_enabled_flag_yes       CONSTANT fnd_lookup_values.enabled_flag%TYPE
                                     := 'Y';                          --�g�p�\
  --����R�[�h
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE
                                     := USERENV('LANG');              --JA
  --���t�����t�H�[�}�b�g
  cv_fmt_date8              CONSTANT VARCHAR2(8)    := 'RRRRMMDD';
  cv_fmt_date               CONSTANT VARCHAR2(30)   := 'RRRR/MM/DD';
  cv_fmt_datetime           CONSTANT VARCHAR2(30)   := 'RRRR/MM/DD HH24:MI:SS';
  --���݃t���O
  cv_exists_flag_yes        CONSTANT VARCHAR2(1)    := 'Y';           --���݂���
  --�d�c�h�i�ڃG���[�t���O
  cv_edi_item_err_flag_yes  CONSTANT VARCHAR2(1)    := 'Y';           --�G���[�ł���
  cv_edi_item_err_flag_no   CONSTANT VARCHAR2(1)    := 'N';           --�G���[�łȂ�
  --��ԓ����敪
  cv_bargain_class_all      CONSTANT VARCHAR2(2)    := '00';          --�S��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���[���[�N�p�e�[�u���^��`
  TYPE g_rpt_data_ttype
  IS
    TABLE OF
      xxcos_rep_pick_sale_car%ROWTYPE
    INDEX BY PLS_INTEGER
    ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�p�����[�^
  gt_login_base_code                  hz_cust_accounts.account_number%TYPE;                     --���_
  gt_subinventory_code                mtl_secondary_inventories.secondary_inventory_name%TYPE;  --�o�׌��ۊǏꏊ
  gd_request_date_from                DATE;                                                     --����(From)
  gd_request_date_to                  DATE;                                                     --����(To)
  gt_bargain_class                    fnd_lookup_values.lookup_code%TYPE;                       --��ԓ����敪
  gt_bargain_class_name               fnd_lookup_values.meaning%TYPE;                           --��ԓ����敪�i�w�b�_�j����
  gv_sales_output_type                VARCHAR2(1);                                              --����Ώۏo�͋敪
  gd_edi_received_date                DATE;                                                     --EDI��M��
  --�����擾
  gd_process_date                     DATE;                                                     --�Ɩ����t
  gn_org_id                           NUMBER;                                                   --�c�ƒP��
  gd_max_date                         DATE;                                                     --MAX���t
  gt_case_uom_code                    mtl_units_of_measure_tl.uom_code%TYPE;                    --�P�[�X�P�ʃR�[�h
  --���[���[�N�����e�[�u��
  g_rpt_data_tab                      g_rpt_data_ttype;
  --����}�X�^�̃N�C�b�N�R�[�h�����p
  gt_qcc_sale_class                   fnd_lookup_values.lookup_code%TYPE;     --����敪�p
  gt_teiban_code                      fnd_lookup_values.lookup_code%TYPE;     --��ԓ����敪(���)
  gt_teiban_name                      fnd_lookup_values.meaning%TYPE;         --��ԓ����敪��(���)
  gt_tokuban_code                     fnd_lookup_values.lookup_code%TYPE;     --��ԓ����敪(����)
  gt_tokuban_name                     fnd_lookup_values.meaning%TYPE;         --��ԓ����敪��(����)
  gt_org_id                           mtl_parameters.organization_id%TYPE;    --�݌ɑg�DID
  gv_hon_uom_code                     VARCHAR2(128);                          --�{�P�ʃR�[�h
--
  -- ===============================
  -- ���[�U�[��`�֐�
  -- ===============================
  --�������r
  FUNCTION comp_char(
    iv_arg1                   IN      VARCHAR2,
    iv_arg2                   IN      VARCHAR2)
  RETURN BOOLEAN
  IS
  BEGIN
    IF ( ( iv_arg1 IS NULL ) AND ( iv_arg2 IS NULL ) ) THEN
        RETURN TRUE;
    ELSIF ( ( iv_arg1 IS NULL ) AND ( iv_arg2 IS NOT NULL ) ) THEN
        RETURN FALSE;
    ELSIF ( ( iv_arg1 IS NOT NULL ) AND ( iv_arg2 IS NULL ) ) THEN
        RETURN FALSE;
    ELSE
      IF ( iv_arg1 = iv_arg2 ) THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    END IF;
  END;
  --���t��r
  FUNCTION comp_date(
    id_arg1                   IN      DATE,
    id_arg2                   IN      DATE)
  RETURN BOOLEAN
  IS
  BEGIN
    IF ( ( id_arg1 IS NULL ) AND ( id_arg2 IS NULL ) ) THEN
        RETURN TRUE;
    ELSIF ( ( id_arg1 IS NULL ) AND ( id_arg2 IS NOT NULL ) ) THEN
        RETURN FALSE;
    ELSIF ( ( id_arg1 IS NOT NULL ) AND ( id_arg2 IS NULL ) ) THEN
        RETURN FALSE;
    ELSE
      IF ( id_arg1 = id_arg2 ) THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    END IF;
  END;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_login_base_code        IN   VARCHAR2,     -- 1.���_
    iv_subinventory           IN   VARCHAR2,     -- 2.�o�׌��ۊǏꏊ
    iv_request_date_from      IN   VARCHAR2,     -- 3.�����iFrom�j
    iv_request_date_to        IN   VARCHAR2,     -- 4.�����iTo�j
    iv_bargain_class          IN   VARCHAR2,     -- 5.��ԓ����敪
    iv_sales_output_type      IN   VARCHAR2,     -- 6.����Ώۋ敪
    iv_edi_received_date      IN   VARCHAR2,     -- 7.EDI��M��
    ov_errbuf                 OUT  VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT  VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT  VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���ԁi�ŏ��A�ő�)
    cv_time_min  CONSTANT VARCHAR2(8)  := '00:00:00';
    cv_time_max  CONSTANT VARCHAR2(8)  := '23:59:59';
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
    --==================================
    -- 1.�p�����[�^�o��
    --==================================
    lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application        => ct_xxcos_appl_short_name,
                    iv_name               => ct_msg_parameter,
                    iv_token_name1        => cv_tkn_param1,
                    iv_token_value1       => iv_login_base_code,
                    iv_token_name2        => cv_tkn_param2,
                    iv_token_value2       => iv_subinventory,
                    iv_token_name3        => cv_tkn_param3,
                    iv_token_value3       => iv_request_date_from,
                    iv_token_name4        => cv_tkn_param4,
                    iv_token_value4       => iv_request_date_to,
                    iv_token_name5        => cv_tkn_param5,
                    iv_token_value5       => iv_bargain_class,
                    iv_token_name6        => cv_tkn_param6,
                    iv_token_value6       => iv_sales_output_type,
                    iv_token_name7        => cv_tkn_param7,
                    iv_token_value7       => iv_edi_received_date
                  );
    --
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => lv_errmsg
    );
    --1�s��
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => NULL
    );
--
    --==================================
    -- 2.�p�����[�^�ϊ�
    --==================================
    gt_login_base_code        := iv_login_base_code;
    gt_subinventory_code      := iv_subinventory;
    gd_request_date_from      := TO_DATE( iv_request_date_from || cv_time_min, cv_fmt_datetime );
    gd_request_date_to        := TO_DATE( iv_request_date_to   || cv_time_max, cv_fmt_datetime );
    gt_bargain_class          := iv_bargain_class;
    gv_sales_output_type      := iv_sales_output_type;
    -- EDI��M��
    IF ( iv_edi_received_date IS NOT NULL )THEN
      gd_edi_received_date    := TO_DATE( iv_edi_received_date || cv_time_min, cv_fmt_datetime );
    ELSE
      gd_edi_received_date    := NULL;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : check_parameter
   * Description      : �p�����[�^�`�F�b�N����(A-1)
   ***********************************************************************************/
  PROCEDURE check_parameter(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_parameter';        -- �v���O������
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
    --��ԁE��������p
    cv_teiban_flag_yes        CONSTANT VARCHAR2(1)  := 'Y';  --���
    cv_teiban_flag_no         CONSTANT VARCHAR2(1)  := 'N';  --����
--
    -- *** ���[�J���ϐ� ***
    lv_org_id        VARCHAR2(5000);
    lv_max_date      VARCHAR2(5000);
    lv_profile_name  VARCHAR2(5000);
    lv_req_dt_from   VARCHAR2(5000);
    lv_req_dt_to     VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
    lt_org_cd        mtl_parameters.organization_code%TYPE;  -- �݌ɑg�D�R�[�h
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
    --==================================
    -- 1.�Ɩ����t�擾
    --==================================
    gd_process_date  :=  xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    --==================================
    -- 2.MO:�c�ƒP��
    --==================================
    lv_org_id  := FND_PROFILE.VALUE( ct_prof_org_id );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_org_id IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name  := xxccp_common_pkg.get_msg(
                            iv_application  => ct_xxcos_appl_short_name,
                            iv_name         => ct_msg_org_id
                          );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_org_id  := TO_NUMBER( lv_org_id );
--
    --==================================
    -- 3.XXCOS:MAX���t
    --==================================
    lv_max_date := FND_PROFILE.VALUE( ct_prof_max_date );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_max_date IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name  := xxccp_common_pkg.get_msg(
                            iv_application  => ct_xxcos_appl_short_name,
                            iv_name         => ct_msg_max_date
                          );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_max_date  := TO_DATE( lv_max_date, cv_fmt_date );
--
    --==================================
    -- 4.XXCOS:�P�[�X�P�ʃR�[�h
    --==================================
    gt_case_uom_code  := FND_PROFILE.VALUE( ct_prof_case_uom_code );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gt_case_uom_code IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name  := xxccp_common_pkg.get_msg(
                            iv_application  => ct_xxcos_appl_short_name,
                            iv_name         => ct_msg_case_uom_code
                          );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    --========================================
    -- 5.XXCOS:�{�P�ʃR�[�h�̎擾
    --========================================
    gv_hon_uom_code := FND_PROFILE.VALUE( ct_hon_uom_code );
    -- XXCOS:�{�P�ʃR�[�h�̎擾���ł��Ȃ��ꍇ�̃G���[�ҏW
    IF ( gv_hon_uom_code IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name  := xxccp_common_pkg.get_msg(
                            iv_application   =>  ct_xxcos_appl_short_name,
                            iv_name          =>  ct_msg_get_hon_uom
                          );
      RAISE global_get_profile_expt;
    END IF;
--
    --==================================
    -- 6.�p�����[�^�`�F�b�N
    --==================================
    IF ( gd_request_date_from > gd_request_date_to ) THEN
      RAISE global_date_reversal_expt;
    END IF;
--
    --==================================
    -- 7.��ԓ����敪�i�w�b�_�j�擾
    --==================================
    IF ( gt_bargain_class = cv_bargain_class_all ) THEN
      --�����̒�ԓ����敪���S�Ă̏ꍇ�A��ԓ����敪�i�w�b�_�j���̂�NULL
      gt_bargain_class_name  := NULL;
    ELSE
      BEGIN
        SELECT flv.meaning  bargain_class_name
        INTO   gt_bargain_class_name
        FROM   fnd_lookup_values  flv
        WHERE  flv.lookup_type    = ct_qct_bargain_class
        AND    flv.lookup_code    = gt_bargain_class
        AND    gd_process_date    >= flv.start_date_active
        AND    gd_process_date    <= NVL( flv.end_date_active, gd_max_date )
        AND    flv.language       = ct_lang
        AND    flv.enabled_flag   = ct_enabled_flag_yes
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_table_name  := xxccp_common_pkg.get_msg(
                              iv_application        => ct_xxcos_appl_short_name,
                              iv_name               => ct_msg_bargain_cls_tblnm
                            );
          RAISE global_lookup_code_expt;
      END;
    END IF;
--
    -- ==================================
    -- 8.��ԓ����敪���(���)�擾
    -- ==================================
    -- ��Ԗ���-�R�[�h�擾
    BEGIN
      SELECT  flv.meaning               teiban_name    -- �u��ԁv
             ,flv.lookup_code           teiban_code    -- �u01�v
      INTO    gt_teiban_name
             ,gt_teiban_code
      FROM    fnd_lookup_values         flv                             --�N�C�b�N�R�[�h�}�X�^
      WHERE   flv.lookup_type           = ct_qct_bargain_class
      AND     flv.attribute1            = cv_teiban_flag_yes
      AND     gd_process_date          >= flv.start_date_active
      AND     gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
      AND     flv.language              = ct_lang
      AND     flv.enabled_flag          = ct_enabled_flag_yes;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name,
                         iv_name          => ct_msg_teiban_get_err
                       );
        lv_errbuf := lv_errbuf;
        RAISE global_api_expt;
    END;
--
    -- ==================================
    -- 9.��ԓ����敪���(����)�擾
    -- ==================================
    -- ��������-�R�[�h�擾
    BEGIN
      SELECT  flv.meaning               tokuban_name    -- �u���ԁv
             ,flv.lookup_code           tokuban_code    -- �u02�v
      INTO    gt_tokuban_name
             ,gt_tokuban_code
      FROM    fnd_lookup_values         flv                             --�N�C�b�N�R�[�h�}�X�^
      WHERE   flv.lookup_type           = ct_qct_bargain_class
      AND     flv.attribute1            = cv_teiban_flag_no
      AND     gd_process_date          >= flv.start_date_active
      AND     gd_process_date          <= NVL( flv.end_date_active, gd_max_date )
      AND     flv.language              = ct_lang
      AND     flv.enabled_flag          = ct_enabled_flag_yes;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name,
                         iv_name          => ct_msg_tokuban_get_err
                       );
        lv_errbuf := lv_errbuf;
        RAISE global_api_expt;
    END;
--
    --========================================
    -- 10.�݌ɑg�D�R�[�h�擾����
    --========================================
    lt_org_cd := FND_PROFILE.VALUE( cv_prof_org );
    IF ( lt_org_cd IS NULL ) THEN
      lv_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application        =>  ct_xxcoi_short_name,
                       iv_name               =>  cv_msg_org_cd_err,
                       iv_token_name1        =>  cv_tkn_nm_profile2,
                       iv_token_value1       =>  cv_prof_org
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --========================================
    -- 11.�݌ɑg�DID�擾����
    --========================================
    gt_org_id := xxcoi_common_pkg.get_organization_id( lt_org_cd );
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application        =>  ct_xxcoi_short_name,
                       iv_name               =>  cv_msg_org_id_err,
                       iv_token_name1        =>  cv_tkn_nm_org_cd,
                       iv_token_value1       =>  lt_org_cd
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        => ct_xxcos_appl_short_name,
                      iv_name               => ct_msg_process_date_err
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C����O�n���h�� ***
    WHEN global_get_profile_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        => ct_xxcos_appl_short_name,
                      iv_name               => ct_msg_get_profile_err,
                      iv_token_name1        => cv_tkn_profile,
                      iv_token_value1       => lv_profile_name
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���t�t�]��O�n���h�� ***
    WHEN global_date_reversal_expt THEN
      lv_req_dt_from  := xxccp_common_pkg.get_msg(
                           iv_application        => ct_xxcos_appl_short_name,
                           iv_name               => ct_msg_req_dt_from
                         );
      lv_req_dt_to    := xxccp_common_pkg.get_msg(
                           iv_application        => ct_xxcos_appl_short_name,
                           iv_name               => ct_msg_req_dt_to
                         );
      ov_errmsg       := xxccp_common_pkg.get_msg(
                           iv_application        => ct_xxcos_appl_short_name,
                           iv_name               => ct_msg_date_reversal_err,
                           iv_token_name1        => cv_tkn_date_from,
                           iv_token_value1       => lv_req_dt_from,
                           iv_token_name2        => cv_tkn_date_to,
                           iv_token_value2       => lv_req_dt_to
                         );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �N�C�b�N�R�[�h�}�X�^��O�n���h�� ***
    WHEN global_lookup_code_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        => ct_xxcos_appl_short_name,
                      iv_name               => ct_msg_select_data_err,
                      iv_token_name1        => cv_tkn_table_name,
                      iv_token_value1       => lv_table_name,
                      iv_token_name2        => cv_tkn_key_data,
                      iv_token_value2       => NULL
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   #######################################
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
  END check_parameter;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �f�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ct_conv_rate_default    CONSTANT mtl_uom_class_conversions.conversion_rate%TYPE      := 0;         --���Z���f�t�H���g
    --�󒍃^�C�v
    ct_tran_type_code_line  CONSTANT oe_transaction_types_all.transaction_type_code%TYPE := 'LINE';    --�󒍃^�C�v�i���ׁj
    ct_tran_type_code_order CONSTANT oe_transaction_types_all.transaction_type_code%TYPE := 'ORDER';   --�󒍃^�C�v�i�w�b�_�j
    --�󒍃w�b�_�X�e�[�^�X
    ct_hdr_status_booked    CONSTANT oe_order_headers_all.flow_status_code%TYPE          := 'BOOKED';  --�L����
    ct_hdr_status_entered   CONSTANT oe_order_headers_all.flow_status_code%TYPE          := 'ENTERED'; --���͍�
    --�󒍖��׃X�e�[�^�X
    ct_ln_status_closed     CONSTANT oe_order_lines_all.flow_status_code%TYPE            := 'CLOSED';  --�N���[�Y
    ct_ln_status_cancelled  CONSTANT oe_order_lines_all.flow_status_code%TYPE            := 'CANCELLED';  --���
    --�f�[�^��R�[�h
    ct_data_type_code_edi   CONSTANT xxcos_edi_headers.data_type_code%TYPE               := '11';      --EDI��
    ct_data_type_code_shop  CONSTANT xxcos_edi_headers.data_type_code%TYPE               := '12';      --�X�ܕʎ�
    --�ۊǏꏊ����
    cv_subinv_car           CONSTANT VARCHAR2(1)   := '5';   --�c�Ǝ�
    --���敪
    cv_info_class_01        CONSTANT VARCHAR2(2)   := '01';  --���敪�F�u01�v
    cv_info_class_02        CONSTANT VARCHAR2(2)   := '02';  --���敪�F�u02�v
    cv_info_class_04        CONSTANT VARCHAR2(2)   := '04';  --���敪�F�u04�v
    --����Ώۏo�͋敪
    cv_sales_output_type_1  CONSTANT VARCHAR2(2)   := '1';   --����Ώۏo�͋敪�F�u1�v(�Ώ�)
    cv_sales_output_type_2  CONSTANT VARCHAR2(2)   := '2';   --����Ώۏo�͋敪�F�u2�v(�ΏۊO)
--
    -- *** ���[�J���ϐ� ***
    ln_idx                      NUMBER;
    ln_record_id                NUMBER;
    --�W�v�p�ϐ�
    ln_quantity                 NUMBER;
    --�P�ʊ��Z�p�ϐ�
    lt_item_code                mtl_system_items_b.segment1%TYPE;
    lt_organization_code        mtl_parameters.organization_code%TYPE;
    lt_inventory_item_id        mtl_system_items_b.inventory_item_id%TYPE;
    lt_organization_id          mtl_system_items_b.organization_id%TYPE;
    lt_after_uom_code           mtl_units_of_measure_tl.uom_code%TYPE;
    ln_after_quantity           NUMBER;
    ln_content                  NUMBER;
    --�L�[�u���C�N�ϐ�
    lt_key_base_code            xxcmm_cust_accounts.delivery_base_code%TYPE;             --���_�R�[�h
    lt_key_base_name            hz_parties.party_name%TYPE;                              --���_����
    lt_key_subinventory         mtl_secondary_inventories.secondary_inventory_name%TYPE; --�o�׌��ۊǏꏊ
    lt_key_subinventory_name    mtl_secondary_inventories.description%TYPE;              --�o�׌��ۊǏꏊ��
    lt_key_schedule_ship_date   oe_order_lines_all.schedule_ship_date%TYPE;              --�o�ד�
    lt_key_request_date         oe_order_lines_all.request_date%TYPE;                    --����
    lt_key_chain_store_code     xxcmm_cust_accounts.chain_store_code%TYPE;               --�`�F�[���X�R�[�h
    lt_key_store_code           xxcmm_cust_accounts.store_code%TYPE;                     --�X�܃R�[�h
    lt_key_cust_code            hz_cust_accounts.account_number%TYPE;                    --�ڋq�R�[�h
    lt_key_cust_name            hz_parties.party_name%TYPE;                              --�ڋq��
    lt_key_bargain_class_name   fnd_lookup_values.description%TYPE;                      --��ԓ����敪����(����)
    lt_key_slip_no              oe_order_headers_all.cust_po_number%TYPE;                --�`�[NO
    lt_key_item_code            mtl_system_items_b.segment1%TYPE;                        --���i�R�[�h
    lt_key_item_name            mtl_system_items_b.description%TYPE;                     --���i��
    lv_key_edi_item_err_flag    VARCHAR(1);                                              --�d�c�h�G���[�t���O
    lt_key_item_code2           xxcos_edi_lines.product_code2%TYPE;                      --���i�R�[�h�Q
    lt_key_item_name2           xxcos_rep_pick_sale_car.item_name%TYPE;                  --���i���Q
    lt_key_case_content         mtl_uom_class_conversions.conversion_rate%TYPE;          --�P�[�X����
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR data_cur
    IS
      SELECT /*+
               LEADING(rpdpi)
               USE_NL(rpdpi xeiet mucc)
             */
             rpdpi.base_code                       base_code,                      --���_�R�[�h
             rpdpi.base_name                       base_name,                      --���_����
             rpdpi.subinventory                    subinventory,                   --�o�׌��ۊǏꏊ
             rpdpi.subinventory_name               subinventory_name,              --�o�׌��ۊǏꏊ��
             rpdpi.chain_store_code                chain_store_code,               --�`�F�[���X�R�[�h
             rpdpi.schedule_ship_date              schedule_ship_date,             --�o�ד�
             rpdpi.request_date                    request_date,                   --����
             rpdpi.inventory_item_id               inventory_item_id,              --�i��ID
             rpdpi.organization_id                 organization_id,                --�݌ɑg�DID
             rpdpi.item_code                       item_code,                      --���i�R�[�h
             rpdpi.item_name                       item_name,                      --���i��
             DECODE(  xeiet.lookup_code
                     ,NULL, NULL
                     ,rpdpi.product_code2 
             )                                     item_code2,                     --���i�R�[�h�Q
             DECODE(  xeiet.lookup_code
                     ,NULL, NULL
                     ,rpdpi.product_name2_alt
             )                                     item_name2,                     --���i���Q
             DECODE(  xeiet.lookup_code
                     ,NULL, cv_edi_item_err_flag_no
                     ,cv_edi_item_err_flag_yes
             )                                     edi_item_err_flag,              --�d�c�h�i�ڃG���[�t���O
             NVL( mucc.conversion_rate, ct_conv_rate_default )
                                                   case_content,                   --�P�[�X����
             CASE
               WHEN ( xeiet.lookup_code IS NOT NULL AND rpdpi.sales_output_type = cv_sales_output_type_2 ) THEN
                 gv_hon_uom_code
               ELSE 
                 rpdpi.order_quantity_uom                              --�P�ʃ}�X�^
             END                                   order_quantity_uom,             --�󒍒P�ʃR�[�h
             rpdpi.ordered_quantity                ordered_quantity,               --�󒍐���
             rpdpi.store_code                      store_code,                     --�X�܃R�[�h
             rpdpi.cust_code                       cust_code,                      --�ڋq�R�[�h
             rpdpi.cust_name                       cust_name,                      --�ڋq��
             rpdpi.slip_no                         slip_no,                        --�`�[NO
             rpdpi.bargain_class_name              bargain_class_name              --��ԓ����敪����
      FROM   mtl_uom_class_conversions             mucc,                           --�P�ʕϊ��}�X�^
             (
               SELECT  flv.lookup_code             lookup_code,        --EDI�i�ڃG���[�^�C�v
                       flv.start_date_active       start_date_active,  --�L���J�n��
                       NVL( flv.end_date_active, gd_max_date )
                                                   end_date_active     --�L���I����
               FROM    fnd_lookup_values   flv                         --�N�C�b�N�R�[�h�}�X�^
               WHERE   flv.lookup_type     = ct_qct_edi_item_err_type
               AND     flv.language        = ct_lang
               AND     flv.enabled_flag    = ct_enabled_flag_yes
             ) xeiet,                                                  --EDI�i�ڃG���[�^�C�v�}�X�^
             (
               --***** �󒍁iOnline�j*****
               SELECT  /*+
                         LEADING( xca1 hca1 hp1 oola otta2 ottt2 scdm ooha otta ottt )
                         USE_NL( xca1 hca1 hp1 oola otta2 ottt2 xeh ooha otta ottt xel hca2 hp2 )
                       */
                       xca1.delivery_base_code           base_code,                      --���_�R�[�h
                       hp2.party_name                    base_name,                      --���_����
                       oola.subinventory                 subinventory,                   --�o�׌��ۊǏꏊ
                       msi.description                   subinventory_name,              --�o�׌��ۊǏꏊ��
                       xca1.chain_store_code             chain_store_code,               --�`�F�[���X�R�[�h
                       TRUNC( oola.schedule_ship_date )  schedule_ship_date,             --�o�ד�
                       TRUNC( oola.request_date )        request_date,                   --����
                       msib.inventory_item_id            inventory_item_id,              --�i��ID
                       msib.organization_id              organization_id,                --�݌ɑg�DID
                       msib.segment1                     item_code,                      --���i�R�[�h
                       msib.description                  item_name,                      --���i��
                       NULL                              product_code2,                  --���i�R�[�h�Q
                       NULL                              product_name2_alt,              --���i���Q
                       ooha.ordered_date                 ordered_date,                   --�󒍓�
                       oola.order_quantity_uom           order_quantity_uom,             --�󒍒P�ʃR�[�h
                       oola.ordered_quantity             ordered_quantity,               --�󒍐���
                       xca1.store_code                   store_code,                     --�X�܃R�[�h
                       hca1.account_number               cust_code,                      --�ڋq�R�[�h
                       hp1.party_name                    cust_name,                      --�ڋq��
                       ooha.cust_po_number               slip_no,                        --�`�[NO
                       scm.sale_class_name               bargain_class_name,             --��ԓ����敪����
                       cv_sales_output_type_1            sales_output_type               --����Ώۋ敪(�Ώ�)
               FROM    xxcmm_cust_accounts               xca1,                   --�ڋq�A�h�I���y�ڋq�z
                       hz_cust_accounts                  hca1,                   --�ڋq�y�ڋq�z
                       hz_parties                        hp1,                    --�p�[�e�B�y�ڋq�z
                       oe_order_lines_all                oola,                   --�󒍖���
                       oe_transaction_types_all          otta2,                  --�󒍃^�C�v�y���ׁz
                       oe_transaction_types_tl           ottt2,                  --�󒍃^�C�v�|��y���ׁz
                       mtl_secondary_inventories         msi,                    --�ۊǏꏊ�}�X�^
                       mtl_system_items_b                msib,                   --�i�ڃ}�X�^
                       oe_order_headers_all              ooha,                   --�󒍃w�b�_
                       oe_order_sources                  oos,                    --�󒍃\�[�X
                       oe_transaction_types_all          otta,                   --�󒍃^�C�v�y�w�b�_�z
                       oe_transaction_types_tl           ottt,                   --�󒍃^�C�v�|��y�w�b�_�z
                       hz_cust_accounts                  hca2,                   --�ڋq�y���_�z
                       hz_parties                        hp2,                    --�p�[�e�B�y���_�z
                       (
                         SELECT  flv.meaning                   line_type_name,       --���׃^�C�v��
                                 flv.attribute1                sale_class_default,   --����敪�����l
                                 flv.start_date_active         start_date_active,    --�L���J�n��
                                 NVL( flv.end_date_active, gd_max_date )
                                                               end_date_active       --�L���I����
                         FROM    fnd_lookup_values  flv                              --�N�C�b�N�R�[�h�}�X�^
                         WHERE   flv.lookup_type    =    ct_qct_sale_class_default
                         AND     flv.lookup_code    LIKE ct_qcc_sale_class_default
                         AND     flv.language       =    ct_lang
                         AND     flv.enabled_flag   =    ct_enabled_flag_yes
                       ) scdm,   --����敪�����l�}�X�^(����敪�����͂̏ꍇ�A���׃^�C�v���甄��敪�̏����l���擾)
                       (
                         SELECT  flv.meaning                   sale_class,           --����敪
                                 flv.description               sale_class_name,      --����敪��
                                 flv.start_date_active         start_date_active,    --�L���J�n��
                                 NVL( flv.end_date_active, gd_max_date )
                                                               end_date_active       --�L���I����
                         FROM    fnd_lookup_values             flv                   --�N�C�b�N�R�[�h�}�X�^
                         WHERE   flv.lookup_type    =    ct_qct_sale_class
                         AND     flv.lookup_code    LIKE ct_qcc_sale_class || cv_multi
                         AND     flv.language       =    ct_lang
                         AND     flv.enabled_flag   =    ct_enabled_flag_yes
                       ) scm    --����敪�}�X�^�i���̎擾�j
               WHERE   gd_edi_received_date        IS NULL  -- �p�����[�^�uEDI��M���v���w�肳��Ă��Ȃ����ƁB
               AND     (
                         ( gv_sales_output_type IS NULL )
                         OR
                         ( gv_sales_output_type  = cv_sales_output_type_1 )
                       )    --�p�����[�^�u����Ώہv���uNULL�v���u�Ώہv
               AND     xca1.delivery_base_code      =      gt_login_base_code   --�[�i���_���p�����[�^�u�[�i���_�v
               AND     xca1.chain_store_code        IS NOT NULL                 --�`�F�[���X�̂�
               AND     xca1.customer_id             =      hca1.cust_account_id
               AND     hca1.party_id                =      hp1.party_id
               AND     hca1.cust_account_id         =      oola.sold_to_org_id  --�󒍖��ׂƌڋqID�Ō���
               AND     oola.request_date            >=     gd_request_date_from --�[�i�\������p�����[�^�u����(From)�v�ȍ~
               AND     oola.request_date            <=     gd_request_date_to   --�[�i�\������p�����[�^�u����(To)�v�ȑO
               AND     oola.flow_status_code        NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )  --���׃X�e�[�^�X��CLOSED,CANCELLED
               AND     (
                         ( ( gt_subinventory_code IS NOT NULL ) AND ( oola.subinventory = gt_subinventory_code ) )
                         OR
                         (
                           ( gt_subinventory_code IS NULL )
                           AND
                           ( EXISTS ( SELECT cv_exists_flag_yes   exists_flag
                                      FROM   mtl_secondary_inventories msis
                                      WHERE  msis.secondary_inventory_name = oola.subinventory
                                      AND    msis.organization_id          = gt_org_id
                                      AND    msis.attribute7               = gt_login_base_code --���_�R�[�h���p�����[�^�u�[�i���_�v
                                      AND    msis.attribute13              = cv_subinv_car      --�ۊǏꏊ���ނ��u�c�Ǝԁv
                                    )
                           )
                         )
                       )    --�p�����[�^�u�o�א�ۊǏꏊ�v��NULL�ŋ��_�̏o�׌��ۊǏꏊ(�c�Ǝ�)���A�w�肳�ꂽ�o�א�ۊǏꏊ
               AND     EXISTS(
                         SELECT  cv_exists_flag_yes   exists_flag
                         FROM    fnd_lookup_values    flv                             --�N�C�b�N�R�[�h�}�X�^
                         WHERE   flv.lookup_type        =    ct_qct_sale_class
                         AND     flv.lookup_code        LIKE gt_qcc_sale_class
                         AND     flv.meaning            =    NVL( oola.attribute5, scdm.sale_class_default )
                         AND     TRUNC( ooha.ordered_date )  >= flv.start_date_active
                         AND TRUNC( ooha.ordered_date )      <= NVL( flv.end_date_active, gd_max_date )
                         AND flv.language               = ct_lang
                         AND flv.enabled_flag           = ct_enabled_flag_yes
                       )    --�p�����[�^�u��ԓ����敪�v���󒍖��ׂ̔���敪���A����
               AND     oola.line_type_id            =      otta2.transaction_type_id
               AND     otta2.transaction_type_code  =      ct_tran_type_code_line   --�󒍃^�C�v�y���ׁz���uLINE�v
               AND     otta2.transaction_type_id    =      ottt2.transaction_type_id
               AND     ottt2.language               =      ct_lang
               AND     oola.subinventory            =      msi.secondary_inventory_name
               AND     oola.ship_from_org_id        =      msi.organization_id
               AND     oola.inventory_item_id       =      msib.inventory_item_id
               AND     oola.ship_from_org_id        =      msib.organization_id
               AND     NOT EXISTS (
                         SELECT  cv_exists_flag_yes    exists_flag
                         FROM    fnd_lookup_values     flvs1
                         WHERE   flvs1.lookup_type  = ct_xxcos1_no_inv_item_code
                         AND     flvs1.lookup_code  = msib.segment1
                         AND     TRUNC( ooha.ordered_date ) >= flvs1.start_date_active
                         AND     TRUNC( ooha.ordered_date ) <= NVL(flvs1.end_date_active, gd_max_date)
                         AND     flvs1.enabled_flag = ct_enabled_flag_yes
                         AND     flvs1.language     = ct_lang
                       )    --��݌ɕi�ȊO
               AND     oola.header_id               =      ooha.header_id
               AND     ooha.org_id                  =      gn_org_id                --ORG_ID���c��
               AND     ooha.flow_status_code        =      ct_hdr_status_booked     --�󒍃w�b�_�X�e�[�^�X���uBOOKED�v
               AND     (
                         ( ooha.global_attribute3 IS NULL )
                         OR
                         ( ooha.global_attribute3 IN ( cv_info_class_01, cv_info_class_02 ) )
                       )    --���敪���uNULL�v�u01�v�u02�v
               AND     ooha.order_source_id         =      oos.order_source_id
               AND     EXISTS(
                         SELECT  cv_exists_flag_yes   exists_flag
                         FROM    fnd_lookup_values    flvs2  --�N�C�b�N�R�[�h�}�X�^
                         WHERE   flvs2.lookup_type      =    ct_qct_order_source
                         AND     flvs2.lookup_code      LIKE ct_qcc_ord_src_manual
                         AND     flvs2.meaning          =    oos.name
                         AND     TRUNC( ooha.ordered_date ) >= flvs2.start_date_active
                         AND     TRUNC( ooha.ordered_date ) <= NVL( flvs2.end_date_active, gd_max_date )
                         AND     flvs2.language         =    ct_lang
                         AND     flvs2.enabled_flag     =    ct_enabled_flag_yes
                       )    --�󒍃w�b�_�̎󒍃\�[�X���uOnline�v
               AND     ooha.order_type_id           =      otta.transaction_type_id
               AND     otta.transaction_type_code   =      ct_tran_type_code_order   --�󒍃^�C�v�y�w�b�_�z���uORDERED�v
               AND     otta.transaction_type_id     =      ottt.transaction_type_id
               AND     ottt.language                =      ct_lang
               AND     EXISTS(
                         SELECT  cv_exists_flag_yes   exists_flag
                         FROM    fnd_lookup_values    flvs3  --�N�C�b�N�R�[�h�}�X�^
                         WHERE   flvs3.lookup_type      =    ct_qct_order_type
                         AND     flvs3.lookup_code      LIKE ct_qcc_order_type
                         AND     flvs3.meaning          =    ottt.name
                         AND     TRUNC( ooha.ordered_date ) >= flvs3.start_date_active
                         AND     TRUNC( ooha.ordered_date ) <= NVL( flvs3.end_date_active, gd_max_date )
                         AND     flvs3.enabled_flag     =    ct_enabled_flag_yes
                         AND     flvs3.language         =    ct_lang
                       )    --�󒍃^�C�v�y�w�b�_�z���u00_�ʏ�󒍁v
               AND     xca1.delivery_base_code      =      hca2.account_number
               AND     EXISTS(
                         SELECT  cv_exists_flag_yes   exists_flag
                         FROM    fnd_lookup_values    flvs4   --�N�C�b�N�R�[�h�}�X�^
                         WHERE   flvs4.lookup_type        =    ct_qct_cus_class_mst
                         AND     flvs4.lookup_code        LIKE ct_qcc_cus_class_mst1
                         AND     flvs4.meaning            =    hca2.customer_class_code
                         AND     TRUNC( ooha.ordered_date ) >= flvs4.start_date_active
                         AND     TRUNC( ooha.ordered_date ) <= NVL( flvs4.end_date_active, gd_max_date )
                         AND     flvs4.enabled_flag       =    ct_enabled_flag_yes
                         AND     flvs4.language           =    ct_lang
                       )    --�ڋq�y���_�z�̌ڋq�敪���u���_�v
               AND     hca2.party_id                =      hp2.party_id
               AND     ottt2.name                   =      scdm.line_type_name
               AND     TRUNC( ooha.ordered_date )  >=      scdm.start_date_active
               AND     TRUNC( ooha.ordered_date )  <=      scdm.end_date_active
               AND     scm.sale_class               =      NVL( oola.attribute5, scdm.sale_class_default )
               AND     TRUNC( ooha.ordered_date )  >=      scm.start_date_active
               AND     TRUNC( ooha.ordered_date )  <=      scm.end_date_active
               UNION ALL
               --***** �󒍁iEDI�󒍁j*****
               SELECT  /*+
                         LEADING( xca1 hca1 hp1 oola otta2 ottt2 scdm ooha otta ottt )
                         USE_NL( xca1 hca1 hp1 oola otta2 ottt2 scdm ooha otta ottt xel hca2 hp2 )
                       */
                       xca1.delivery_base_code           base_code,                      --���_�R�[�h
                       hp2.party_name                    base_name,                      --���_����
                       oola.subinventory                 subinventory,                   --�o�׌��ۊǏꏊ
                       msi.description                   subinventory_name,              --�o�׌��ۊǏꏊ��
                       xca1.chain_store_code             chain_store_code,               --�`�F�[���X�R�[�h
                       TRUNC( oola.schedule_ship_date )  schedule_ship_date,             --�o�ד�
                       TRUNC( oola.request_date )        request_date,                   --����
                       msib.inventory_item_id            inventory_item_id,              --�i��ID
                       msib.organization_id              organization_id,                --�݌ɑg�DID
                       msib.segment1                     item_code,                      --���i�R�[�h
                       msib.description                  item_name,                      --���i��
                       xel.product_code2                 product_code2,                  --���i�R�[�h�Q
                       NVL( xel.product_name2_alt || xel.item_standard2
                          , xel.product_name1_alt || xel.item_standard1 )
                                                         product_name2_alt,              --���i���Q
                       ooha.ordered_date                 ordered_date,                   --�󒍓�
                       oola.order_quantity_uom           order_quantity_uom,             --�󒍒P�ʃR�[�h
                       oola.ordered_quantity             ordered_quantity,               --�󒍐���
                       xca1.store_code                   store_code,                     --�X�܃R�[�h
                       hca1.account_number               cust_code,                      --�ڋq�R�[�h
                       hp1.party_name                    cust_name,                      --�ڋq��
                       ooha.cust_po_number               slip_no,                        --�`�[NO
                       CASE
                         WHEN ( xeh.ar_sale_class = gt_teiban_code ) THEN  -- ��Ԃ̏ꍇ
                           gt_teiban_name
                         WHEN ( xeh.ar_sale_class = gt_tokuban_code ) THEN -- ���Ԃ̏ꍇ
                           gt_tokuban_name
                         ELSE                                              -- ���̑��̏ꍇ
                           NULL
                       END                               bargain_class_name,             --��ԓ����敪����
                       cv_sales_output_type_1            sales_output_type               --����Ώۋ敪(�Ώ�)
               FROM    xxcmm_cust_accounts               xca1,                   --�ڋq�A�h�I���y�ڋq�z
                       hz_cust_accounts                  hca1,                   --�ڋq�y�ڋq�z
                       hz_parties                        hp1,                    --�p�[�e�B�y�ڋq�z
                       oe_order_lines_all                oola,                   --�󒍖��׃e�[�u��
                       xxcos_edi_headers                 xeh,                    --EDI�w�b�_���
                       xxcos_edi_lines                   xel,                    --EDI���׏��
                       oe_transaction_types_all          otta2,                  --�󒍃^�C�v�y���ׁz
                       oe_transaction_types_tl           ottt2,                  --�󒍃^�C�v�|��y���ׁz
                       mtl_secondary_inventories         msi,                    --�ۊǏꏊ�}�X�^
                       oe_order_headers_all              ooha,                   --�󒍃w�b�_
                       oe_order_sources                  oos,                    --�󒍃\�[�X
                       oe_transaction_types_all          otta,                   --�󒍃^�C�v�y�w�b�_�z
                       oe_transaction_types_tl           ottt,                   --�󒍃^�C�v�|��y�w�b�_�z
                       mtl_system_items_b                msib,                   --�i�ڃ}�X�^
                       hz_cust_accounts                  hca2,                   --�ڋq�y���_�z
                       hz_parties                        hp2,                    --�p�[�e�B�y���_�z
                       (
                         SELECT flv.meaning                   line_type_name,      --���׃^�C�v��
                                flv.attribute1                sale_class_default,  --����敪�����l
                                flv.start_date_active         start_date_active,   --�L���J�n��
                                NVL( flv.end_date_active, gd_max_date )
                                                              end_date_active      --�L���I����
                         FROM   fnd_lookup_values  flv                             --�N�C�b�N�R�[�h�}�X�^
                         WHERE  flv.lookup_type      =    ct_qct_sale_class_default
                         AND    flv.lookup_code      LIKE ct_qcc_sale_class_default
                         AND    flv.language         =    ct_lang
                         AND    flv.enabled_flag     =    ct_enabled_flag_yes
                       ) scdm   --����敪�����l�}�X�^(����敪�����͂̏ꍇ�A���׃^�C�v���甄��敪�̏����l���擾)
               WHERE   (
                         ( gv_sales_output_type IS NULL )
                         OR
                         ( gv_sales_output_type  = cv_sales_output_type_1 )
                       )    --�p�����[�^�u����Ώہv���uNULL�v���u�Ώہv
               AND     xca1.delivery_base_code       =      gt_login_base_code   --�[�i���_���p�����[�^�u�[�i���_�v
               AND     xca1.chain_store_code         IS NOT NULL                  --�`�F�[���X�̂�
               AND     xca1.customer_id              =      hca1.cust_account_id
               AND     hca1.party_id                 =      hp1.party_id
               AND     hca1.cust_account_id          =      oola.sold_to_org_id  --�󒍖��ׂƌڋqID�Ō���
               AND     oola.request_date             >=     gd_request_date_from --�[�i�\������p�����[�^�u����(From)�v�ȍ~
               AND     oola.request_date             <=     gd_request_date_to   --�[�i�\������p�����[�^�u����(To)�v�ȑO
               AND     oola.flow_status_code         NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )  --���׃X�e�[�^�X��CLOSED,CANCELLED
               AND     (
                         ( ( gt_subinventory_code IS NOT NULL ) AND ( oola.subinventory = gt_subinventory_code ) )
                         OR
                         (
                           ( gt_subinventory_code IS NULL )
                           AND
                           ( EXISTS ( SELECT cv_exists_flag_yes   exists_flag
                                      FROM   mtl_secondary_inventories msis
                                      WHERE  msis.secondary_inventory_name = oola.subinventory
                                      AND    msis.organization_id          = gt_org_id
                                      AND    msis.attribute7               = gt_login_base_code --���_�R�[�h���p�����[�^�u�[�i���_�v
                                      AND    msis.attribute13              = cv_subinv_car      --�ۊǏꏊ���ނ��u�c�Ǝԁv
                                    )
                           )
                         )
                       )    --�p�����[�^�u�o�א�ۊǏꏊ�v��NULL�ŋ��_�̏o�׌��ۊǏꏊ(�c�Ǝ�)���A�w�肳�ꂽ�o�א�ۊǏꏊ
               AND     oola.orig_sys_document_ref      = xeh.order_connection_number
               AND     xeh.data_type_code              IN ( ct_data_type_code_edi, ct_data_type_code_shop )
               AND     (
                         (      ( gt_bargain_class <> cv_bargain_class_all ) 
                            AND ( gt_bargain_class = xeh.ar_sale_class )
                         )
                         OR
                         ( gt_bargain_class = cv_bargain_class_all )
                       )    --�p�����[�^�u��ԓ����敪�v��EDI�w�b�_�̓����敪���A����
               AND     (
                         ( gd_edi_received_date IS NULL )
                         OR
                         (
                               ( xeh.edi_received_date >= gd_edi_received_date )
                           AND ( xeh.edi_received_date <  gd_edi_received_date + 1 )
                         )
                       )    -- �p�����[�^�uEDI��M���v��NULL���A�w�肳�ꂽEDI��M��
               AND     xeh.edi_header_info_id            = xel.edi_header_info_id
               AND     oola.orig_sys_line_ref            = xel.order_connection_line_number
               AND     oola.line_type_id            =      otta2.transaction_type_id
               AND     otta2.transaction_type_code  =      ct_tran_type_code_line   --�󒍃^�C�v�y���ׁz���uLINE�v
               AND     otta2.transaction_type_id    =      ottt2.transaction_type_id
               AND     ottt2.language               =      ct_lang
               AND     oola.subinventory            =      msi.secondary_inventory_name
               AND     oola.ship_from_org_id        =      msi.organization_id
               AND     oola.inventory_item_id       =      msib.inventory_item_id
               AND     oola.ship_from_org_id        =      msib.organization_id
               AND     (  NOT EXISTS (
                            SELECT  cv_exists_flag_yes    exists_flag
                            FROM    fnd_lookup_values     flvs1
                            WHERE   flvs1.lookup_type  = ct_xxcos1_no_inv_item_code
                            AND     flvs1.lookup_code  = msib.segment1
                            AND     TRUNC( ooha.ordered_date ) >= flvs1.start_date_active
                            AND     TRUNC( ooha.ordered_date ) <= NVL(flvs1.end_date_active, gd_max_date)
                            AND     flvs1.enabled_flag = ct_enabled_flag_yes
                            AND     flvs1.language     = ct_lang
                          )
                          OR
                          EXISTS(
                            SELECT  cv_exists_flag_yes    exists_flag
                            FROM    fnd_lookup_values     flvs2
                            WHERE   flvs2.lookup_type  = ct_qct_edi_item_err_type
                            AND     flvs2.lookup_code  = msib.segment1
                            AND     TRUNC( ooha.ordered_date ) >= flvs2.start_date_active
                            AND     TRUNC( ooha.ordered_date ) <= NVL(flvs2.end_date_active, gd_max_date)
                            AND     flvs2.enabled_flag = ct_enabled_flag_yes
                            AND     flvs2.language     = ct_lang
                          )
                       )    --��݌ɕi�ȊO���AEDI�G���[�i��
               AND     oola.header_id                =      ooha.header_id
               AND     ooha.org_id                   =      gn_org_id               --ORG_ID���c��
               AND     ooha.flow_status_code         IN     ( ct_hdr_status_booked, ct_hdr_status_entered ) --�󒍃w�b�_�X�e�[�^�X���uBOOKED�v���uENTERED�v
               AND     (
                         ( ooha.global_attribute3 IS NULL )
                         OR
                         ( ooha.global_attribute3  = cv_info_class_02 )
                       )    --���敪���uNULL�v�u02�v
               AND     ooha.order_source_id           =      oos.order_source_id
               AND     EXISTS(
                         SELECT cv_exists_flag_yes   exists_flag
                         FROM   fnd_lookup_values    flvs3  --�N�C�b�N�R�[�h�}�X�^
                         WHERE  flvs3.lookup_type        =    ct_qct_order_source
                         AND    flvs3.lookup_code        LIKE ct_qcc_ord_src_edi
                         AND    flvs3.meaning            =    oos.name
                         AND    TRUNC( ooha.ordered_date ) >= flvs3.start_date_active
                         AND    TRUNC( ooha.ordered_date ) <= NVL( flvs3.end_date_active, gd_max_date )
                         AND    flvs3.enabled_flag       =    ct_enabled_flag_yes
                         AND    flvs3.language           =    ct_lang
                       )    --�󒍃w�b�_�̎󒍃\�[�X���uEDI�󒍁v
               AND     ooha.order_type_id           =      otta.transaction_type_id
               AND     otta.transaction_type_code   =      ct_tran_type_code_order   --�󒍃^�C�v�y�w�b�_�z���uORDERED�v
               AND     otta.transaction_type_id     =      ottt.transaction_type_id
               AND     ottt.language                =      ct_lang
               AND     EXISTS(
                         SELECT cv_exists_flag_yes   exists_flag
                         FROM   fnd_lookup_values    flvs4   --�N�C�b�N�R�[�h�}�X�^
                         WHERE  flvs4.lookup_type        =    ct_qct_order_type
                         AND    flvs4.lookup_code        LIKE ct_qcc_order_type
                         AND    flvs4.meaning            =    ottt.name
                         AND    TRUNC( ooha.ordered_date ) >= flvs4.start_date_active
                         AND    TRUNC( ooha.ordered_date ) <= NVL( flvs4.end_date_active, gd_max_date )
                         AND    flvs4.enabled_flag       =    ct_enabled_flag_yes
                         AND    flvs4.language           =    ct_lang
                       )    --�󒍃^�C�v�y�w�b�_�z���u00_�ʏ�󒍁v
               AND     xca1.delivery_base_code      =      hca2.account_number
               AND     EXISTS(
                         SELECT cv_exists_flag_yes   exists_flag
                         FROM   fnd_lookup_values    flvs5  --�N�C�b�N�R�[�h�}�X�^
                         WHERE  flvs5.lookup_type        =    ct_qct_cus_class_mst
                         AND    flvs5.lookup_code        LIKE ct_qcc_cus_class_mst1
                         AND    flvs5.meaning            =    hca2.customer_class_code
                         AND    TRUNC( ooha.ordered_date ) >= flvs5.start_date_active
                         AND    TRUNC( ooha.ordered_date ) <= NVL( flvs5.end_date_active, gd_max_date )
                         AND    flvs5.enabled_flag       =   ct_enabled_flag_yes
                         AND    flvs5.language           =   ct_lang
                       )    --�ڋq�y���_�z�̌ڋq�敪���u���_�v
               AND     hca2.party_id                =      hp2.party_id
               AND     scdm.line_type_name          =      ottt2.name
               AND     TRUNC( ooha.ordered_date )  >=      scdm.start_date_active
               AND     TRUNC( ooha.ordered_date )  <=      scdm.end_date_active
               UNION ALL
               --***** EDI�󒍁i�W���󒍂Ȃ��j*****
               SELECT  /*+
                         LEADING( xca1 )
                         USE_NL( xca1 xeh hca1 hp1 hca2 hp2 xel msi )
                       */
                       xca1.delivery_base_code           base_code,                      --���_�R�[�h
                       hp2.party_name                    base_name,                      --���_����
                       xca1.ship_storage_code            subinventory,                   --�o�׌��ۊǏꏊ
                       msi.description                   subinventory_name,              --�o�׌��ۊǏꏊ��
                       xeh.edi_chain_code                chain_store_code,               --�`�F�[���X�R�[�h
                       NULL                              schedule_ship_date,             --�o�ד�
                       TRUNC( NVL( xeh.shop_delivery_date
                                 , NVL( xeh.center_delivery_date
                                      , NVL( xeh.order_date
                                           , xeh.creation_date ) ) ) )
                                                         request_date,                   --����
                       msib.inventory_item_id            inventory_item_id,              --�i��ID
                       msib.organization_id              organization_id,                --�݌ɑg�DID
                       msib.segment1                     item_code,                      --���i�R�[�h
                       msib.description                  item_name,                      --���i��
                       xel.product_code2                 product_code2,                  --���i�R�[�h�Q
                       NVL( xel.product_name2_alt || xel.item_standard2
                          , xel.product_name1_alt || xel.item_standard1 )
                                                         product_name2_alt,              --���i���Q
                       NVL( xeh.order_date ,xeh.creation_date )
                                                         ordered_date,                   --�󒍓�
                       xel.line_uom                      order_quantity_uom,             --�󒍒P�ʃR�[�h
                       xel.sum_order_qty                 ordered_quantity,               --�󒍐���
                       xca1.store_code                   store_code,                     --�X�܃R�[�h
                       hca1.account_number               cust_code,                      --�ڋq�R�[�h
                       hp1.party_name                    cust_name,                      --�ڋq��
                       xeh.invoice_number                slip_no,                        --�`�[NO
                       CASE
                         WHEN ( xeh.ar_sale_class = gt_teiban_code ) THEN  -- ��Ԃ̏ꍇ
                           gt_teiban_name
                         WHEN ( xeh.ar_sale_class = gt_tokuban_code ) THEN -- ���Ԃ̏ꍇ
                           gt_tokuban_name
                         ELSE                                              -- ���̑��̏ꍇ
                           NULL
                       END                               bargain_class_name,     --��ԓ����敪����
                       cv_sales_output_type_2            sales_output_type       --����Ώۋ敪(�ΏۊO)
               FROM    xxcmm_cust_accounts               xca1,                   --�ڋq�A�h�I���y�ڋq�z
                       hz_cust_accounts                  hca1,                   --�ڋq�y�ڋq�z
                       hz_parties                        hp1,                    --�p�[�e�B�y�ڋq�z
                       xxcos_edi_headers                 xeh,                    --EDI�w�b�_���
                       hz_cust_accounts                  hca2,                   --�ڋq�y���_�z
                       hz_parties                        hp2,                    --�p�[�e�B�y���_�z
                       mtl_secondary_inventories         msi,                    --�ۊǏꏊ�}�X�^
                       xxcos_edi_lines                   xel,                    --EDI���׏��
                       mtl_system_items_b                msib                    --�i�ڃ}�X�^
               WHERE   (
                         ( gv_sales_output_type IS NULL )
                         OR
                         ( gv_sales_output_type  = cv_sales_output_type_2 )
                       )    --�p�����[�^�u����Ώہv���uNULL�v���u�ΏۊO�v
               AND     xca1.delivery_base_code      =      gt_login_base_code        --�[�i���_���p�����[�^�u�[�i���_�v
               AND     xca1.chain_store_code        IS NOT NULL                      --�`�F�[���X�̂�
               AND     (
                         ( ( gt_subinventory_code IS NOT NULL ) AND ( xca1.ship_storage_code = gt_subinventory_code ) )
                         OR
                         (
                           ( gt_subinventory_code IS NULL )
                           AND
                           ( EXISTS ( SELECT cv_exists_flag_yes   exists_flag
                                      FROM   mtl_secondary_inventories msis
                                      WHERE  msis.secondary_inventory_name = xca1.ship_storage_code
                                      AND    msis.organization_id          = gt_org_id
                                      AND    msis.attribute7               = gt_login_base_code --���_�R�[�h���p�����[�^�u�[�i���_�v
                                      AND    msis.attribute13              = cv_subinv_car      --�ۊǏꏊ���ނ��u�c�Ǝԁv
                                    )
                           )
                         )
                       )    --�p�����[�^�u�o�א�ۊǏꏊ�v��NULL�ŋ��_�̏o�׌��ۊǏꏊ(�c�Ǝ�)���A�w�肳�ꂽ�o�א�ۊǏꏊ
               AND     xca1.customer_id             =      hca1.cust_account_id
               AND     hca1.party_id                =      hp1.party_id
               AND     xca1.customer_code           =      xeh.conv_customer_code
               AND     xeh.data_type_code           =      ct_data_type_code_edi    -- EDI�w�b�_�̃f�[�^��F11
               AND     (
                         (
                                ( cv_bargain_class_all  <> gt_bargain_class )
                            AND ( xeh.ar_sale_class      = gt_bargain_class )
                         )
                         OR
                         ( cv_bargain_class_all        = gt_bargain_class )
                       )    --�p�����[�^�u��ԓ����敪�v��EDI�w�b�_�̓����敪���A����
               AND     xeh.info_class                  =    cv_info_class_04        --���敪�u04�v
               AND     NVL( xeh.shop_delivery_date
                          , NVL( xeh.center_delivery_date
                               , NVL( xeh.order_date, xeh.creation_date ) ) )
                                                      >= gd_request_date_from       --�Y���̓��t���p�����[�^�u����(From)�v�ȍ~
               AND     NVL( xeh.shop_delivery_date
                          , NVL( xeh.center_delivery_date
                               , NVL( xeh.order_date, xeh.creation_date ) ) )
                                                      <= gd_request_date_to         --�Y���̓��t���p�����[�^�u����(To)�v�ȑO
               AND     (
                         ( gd_edi_received_date IS NULL )
                         OR
                         (
                               ( xeh.edi_received_date >= gd_edi_received_date )
                           AND ( xeh.edi_received_date <  gd_edi_received_date + 1 )
                         )
                       )    -- �p�����[�^�uEDI��M���v��NULL���AEDI�w�b�_��EDI��M�����w�肳�ꂽEDI��M��
               AND     xca1.delivery_base_code      = hca2.account_number
               AND EXISTS(
                     SELECT cv_exists_flag_yes   exists_flag
                     FROM   fnd_lookup_values    flvs1
                     WHERE  flvs1.lookup_type        =    ct_qct_cus_class_mst
                     AND    flvs1.lookup_code        LIKE ct_qcc_cus_class_mst1
                     AND    flvs1.meaning            =    hca2.customer_class_code
                     AND    TRUNC( NVL( xeh.order_date ,xeh.creation_date ) )
                                                     >= flvs1.start_date_active
                     AND    TRUNC( NVL( xeh.order_date ,xeh.creation_date ) )
                                                     <= NVL( flvs1.end_date_active, gd_max_date )
                     AND    flvs1.enabled_flag          = ct_enabled_flag_yes
                     AND    flvs1.language              = ct_lang
                   )    --�ڋq�y���_�z�̌ڋq�敪���u���_�v
               AND hp2.party_id                    = hca2.party_id
               AND msi.secondary_inventory_name    = xca1.ship_storage_code
               AND msi.organization_id             = gt_org_id                       -- �݌ɑg�DID
               AND xeh.edi_header_info_id          = xel.edi_header_info_id
               AND msib.segment1                   = xel.item_code
               AND msib.organization_id            = gt_org_id                       -- �݌ɑg�DID
               AND (  NOT EXISTS (
                            SELECT cv_exists_flag_yes    exists_flag
                            FROM   fnd_lookup_values     flvs2
                            WHERE  flvs2.lookup_type  = ct_xxcos1_no_inv_item_code
                            AND    flvs2.lookup_code  = msib.segment1
                            AND    TRUNC( NVL( xeh.order_date ,xeh.creation_date ) )
                                                        >= flvs2.start_date_active
                            AND    TRUNC( NVL( xeh.order_date ,xeh.creation_date ) )
                                                        <= NVL( flvs2.end_date_active, gd_max_date )
                            AND    flvs2.enabled_flag = ct_enabled_flag_yes
                            AND    flvs2.language     = ct_lang
                       )                                                             -- EDI�i�ڃR�[�h�͍݌ɕi��
                       OR EXISTS(
                            SELECT cv_exists_flag_yes    exists_flag
                            FROM   fnd_lookup_values     flvs3
                            WHERE  flvs3.lookup_type  = ct_qct_edi_item_err_type    -- �^�C�v:XXCOS1_EDI_ITEM_ERR_TYPE
                            AND    flvs3.lookup_code  = msib.segment1               -- �R�[�h:�i�ڃR�[�h
                            AND    TRUNC( NVL( xeh.order_date ,xeh.creation_date ) )   -- �K�p�J�n���`�I����
                                                        >= flvs3.start_date_active  --       : EDI�w�b�_.������ or �쐬��
                            AND    TRUNC( NVL( xeh.order_date ,xeh.creation_date ) )
                                                        <= NVL(flvs3.end_date_active, gd_max_date)
                            AND    flvs3.enabled_flag = ct_enabled_flag_yes
                            AND    flvs3.language     = ct_lang
                       )
                   )    --��݌ɕi�ȊO���AEDI�G���[�i��
             ) rpdpi
      WHERE rpdpi.inventory_item_id                   =  mucc.inventory_item_id(+)
      AND   gt_case_uom_code                          =  mucc.to_uom_code(+)
      AND   TRUNC( rpdpi.ordered_date )               <  NVL( mucc.disable_date(+), gd_max_date )
      AND   rpdpi.item_code                           =  xeiet.lookup_code(+)
      AND   TRUNC( rpdpi.ordered_date )               >= xeiet.start_date_active(+)
      AND   TRUNC( rpdpi.ordered_date )               <= xeiet.end_date_active(+)
      ORDER BY
        rpdpi.subinventory,                                                   --�o�׌��ۊǏꏊ
        rpdpi.schedule_ship_date,                                             --�o�ד�
        rpdpi.request_date,                                                   --����
        -- �G���[�i�ڂ̏ꍇ�́A���i�R�[�h�Q�ŏW�v���s���ׁA�\�[�g������ʂɂ���B
        -- ������i�ڂ̏ꍇ�́A���i�R�[�h�Q�A���i���Q��NULL
        edi_item_err_flag,                                                    --�d�c�h�i�ڃG���[�t���O
        item_code2,                                                           --���i�R�[�h�Q
        item_name2,                                                           --���i���Q
        rpdpi.item_code,                                                      --���i�R�[�h
        rpdpi.chain_store_code,                                               --�`�F�[���X�R�[�h
        rpdpi.store_code,                                                     --�X�܃R�[�h
        rpdpi.cust_name,                                                      --�ڋq��
        rpdpi.cust_code,                                                      --�ڋq�R�[�h
        rpdpi.slip_no,                                                        --�`�[NO
        rpdpi.bargain_class_name                                              --��ԓ����敪����(����)
      ;
--
    -- *** ���[�J���E���R�[�h ***
    l_data_rec                          data_cur%ROWTYPE;
--
    -- *** ���[�J���E�v���V�[�W�� ***
    --======================================
    --�L�[�u���C�N����(�����e�[�u���l)�Z�b�g
    --======================================
    PROCEDURE set_key_item
    IS
    BEGIN
      lt_key_base_code                := l_data_rec.base_code;          --���_�R�[�h
      lt_key_base_name                := l_data_rec.base_name;          --���_��
      lt_key_subinventory             := l_data_rec.subinventory;       --�o�׌��ۊǏꏊ
      lt_key_subinventory_name        := l_data_rec.subinventory_name;  --�o�׌��ۊǏꏊ��
      lt_key_chain_store_code         := l_data_rec.chain_store_code;   --�`�F�[���X�R�[�h
      lt_key_store_code               := l_data_rec.store_code;         --�X�܃R�[�h
      lt_key_cust_code                := l_data_rec.cust_code;          --�ڋq�R�[�h
      lt_key_cust_name                := l_data_rec.cust_name;          --�ڋq��
      lt_key_bargain_class_name       := l_data_rec.bargain_class_name; --��ԓ����敪����(����)
      lt_key_slip_no                  := l_data_rec.slip_no;            --�`�[NO
      lt_key_schedule_ship_date       := l_data_rec.schedule_ship_date; --�o�ד�
      lt_key_request_date             := l_data_rec.request_date;       --����
      lt_key_item_code                := l_data_rec.item_code;          --���i�R�[�h
      lt_key_item_name                := l_data_rec.item_name;          --���i��
      lv_key_edi_item_err_flag        := l_data_rec.edi_item_err_flag;  --EDI�i�ڃG���[�t���O
      lt_key_item_code2               := l_data_rec.item_code2;         --���i�R�[�h�Q
      lt_key_item_name2               := l_data_rec.item_name2;         --���i���Q
      lt_key_case_content             := l_data_rec.case_content;       --�P�[�X����
    END;
--
    --==================================
    --�����e�[�u���Z�b�g
    --==================================
    PROCEDURE set_internal_table
    IS
    BEGIN
      -- ���R�[�hID�̎擾
      SELECT  xxcos_rep_pick_sale_car_s01.NEXTVAL  record_id
      INTO    ln_record_id
      FROM    dual
      ;
      --
      ln_idx := ln_idx + 1;
      --���R�[�hID
      g_rpt_data_tab(ln_idx).record_id                    := ln_record_id;
      --���_�R�[�h
      g_rpt_data_tab(ln_idx).base_code                    := lt_key_base_code;
      --���_���i40�o�C�g�ɃJ�b�g�j
      g_rpt_data_tab(ln_idx).base_name                    := SUBSTRB( lt_key_base_name, 1, 40 ); 
      --�o�׌��ۊǏꏊ
      g_rpt_data_tab(ln_idx).whse_code                    := lt_key_subinventory;
      --�o�׌��ۊǏꏊ��
      g_rpt_data_tab(ln_idx).whse_name                    := lt_key_subinventory_name;
      --�`�F�[���X�R�[�h
      g_rpt_data_tab(ln_idx).chain_code                   := lt_key_chain_store_code;
      --�X�܃R�[�h
      g_rpt_data_tab(ln_idx).shop_code                    := lt_key_store_code;
      --�ڋq���i54�o�C�g�ɃJ�b�g�j
      g_rpt_data_tab(ln_idx).cust_name                    := SUBSTRB( lt_key_cust_name, 1, 54 );
      --�`�[No
      g_rpt_data_tab(ln_idx).entry_number                 := SUBSTRB( lt_key_slip_no, 1, 12 );
      --�o�ד�
      g_rpt_data_tab(ln_idx).shipped_date                 := lt_key_schedule_ship_date;
      --����
      g_rpt_data_tab(ln_idx).arrival_date                 := lt_key_request_date;
      --��ԓ����敪�i�w�b�_�j������
      g_rpt_data_tab(ln_idx).regular_sale_class_head      := SUBSTRB( gt_bargain_class_name, 1, 4 );
      --���i�R�[�h�i16�o�C�g�ɃJ�b�g�j
      g_rpt_data_tab(ln_idx).item_code                    := SUBSTRB(
                                                               CASE
                                                                 WHEN ( lv_key_edi_item_err_flag = cv_edi_item_err_flag_yes )
                                                                 THEN
                                                                   lt_key_item_code2
                                                                 ELSE
                                                                   lt_key_item_code
                                                               END
                                                               , 1, 16
                                                             );
      --���i���i40�o�C�g�ɃJ�b�g�j
      g_rpt_data_tab(ln_idx).item_name                    := SUBSTRB(
                                                               CASE
                                                                 WHEN ( lv_key_edi_item_err_flag = cv_edi_item_err_flag_yes )
                                                                 THEN
                                                                   lt_key_item_name2
                                                                 ELSE
                                                                   lt_key_item_name
                                                               END
                                                               , 1, 40
                                                             );
      --����
      g_rpt_data_tab(ln_idx).content                      := lt_key_case_content;
      --�����ɂ��P�[�X�ƃo����ҏW
      IF ( g_rpt_data_tab(ln_idx).content = 0 ) THEN
        g_rpt_data_tab(ln_idx).case_num                   := 0;
        g_rpt_data_tab(ln_idx).indivi                     := ln_quantity;
      ELSE
        g_rpt_data_tab(ln_idx).case_num                   := TRUNC( ln_quantity / lt_key_case_content );
        g_rpt_data_tab(ln_idx).indivi                     := MOD( ln_quantity, lt_key_case_content );
      END IF;
      --����
      g_rpt_data_tab(ln_idx).quantity                     := ln_quantity;
      --��ԓ����敪��
      g_rpt_data_tab(ln_idx).regular_sale_class_line      := SUBSTRB( lt_key_bargain_class_name, 1, 4 );
      --EDI�󒍓� ������
      g_rpt_data_tab(ln_idx).edi_received_date            := gd_edi_received_date;
      --WHO�J����
      g_rpt_data_tab(ln_idx).created_by                   := cn_created_by;
      g_rpt_data_tab(ln_idx).creation_date                := cd_creation_date;
      g_rpt_data_tab(ln_idx).last_updated_by              := cn_last_updated_by;
      g_rpt_data_tab(ln_idx).last_update_date             := cd_last_update_date;
      g_rpt_data_tab(ln_idx).last_update_login            := cn_last_update_login;
      g_rpt_data_tab(ln_idx).request_id                   := cn_request_id;
      g_rpt_data_tab(ln_idx).program_application_id       := cn_program_application_id;
      g_rpt_data_tab(ln_idx).program_id                   := cn_program_id;
      g_rpt_data_tab(ln_idx).program_update_date          := cd_program_update_date;
    END;
--
    --==================================
    --�P�ʊ��Z
    --==================================
    PROCEDURE add_conv_quantity
    IS
    BEGIN
      --�Z�b�g
      lt_item_code                := NULL;
      lt_organization_code        := NULL;
      lt_inventory_item_id        := l_data_rec.inventory_item_id;
      lt_organization_id          := l_data_rec.organization_id;
      lt_after_uom_code           := NULL;
      --�P�ʊ��Z
      xxcos_common_pkg.get_uom_cnv(
        iv_before_uom_code        => l_data_rec.order_quantity_uom,   -- ���Z�O�P�ʃR�[�h
        in_before_quantity        => l_data_rec.ordered_quantity,     -- ���Z�O����
        iov_item_code             => lt_item_code,                    -- �i�ڃR�[�h
        iov_organization_code     => lt_organization_code,            -- �݌ɑg�D�R�[�h
        ion_inventory_item_id     => lt_inventory_item_id,            -- �i�ڂh�c
        ion_organization_id       => lt_organization_id,              -- �݌ɑg�D�h�c
        iov_after_uom_code        => lt_after_uom_code,               -- ���Z��P�ʃR�[�h
        on_after_quantity         => ln_after_quantity,               -- ���Z�㐔��
        on_content                => ln_content,                      -- ����
        ov_errbuf                 => lv_errbuf,                       -- �G���[�E���b�Z�[�W�G���[       #�Œ�#
        ov_retcode                => lv_retcode,                      -- ���^�[���E�R�[�h               #�Œ�#
        ov_errmsg                 => lv_errmsg                        -- ���[�U�[�E�G���[�E���b�Z�[�W   #�Œ�#
      );
      --
      IF ( ov_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --���ʏW�v
      ln_quantity := ln_quantity + ln_after_quantity;
    END;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 0.���ڏ�����
    --==================================
    --
    ln_idx := 0;
    --�u���[�N�L�[������
    lt_key_subinventory        := NULL;  --�o�׌��ۊǏꏊ
    lt_key_schedule_ship_date  := NULL;  --�o�ד�
    lt_key_request_date        := NULL;  --����
    lv_key_edi_item_err_flag   := NULL;  --�d�c�h�i�ڃG���[�t���O
    lt_key_item_code2          := NULL;  --���i�R�[�h�Q
    lt_key_item_name2          := NULL;  --���i���Q
    lt_key_item_code           := NULL;  --���i�R�[�h
    lt_key_chain_store_code    := NULL;  --�`�F�[���X�R�[�h
    lt_key_store_code          := NULL;  --�X�܃R�[�h
    lt_key_cust_code           := NULL;  --�ڋq�R�[�h
    lt_key_cust_name           := NULL;  --�ڋq��
    lt_key_slip_no             := NULL;  --�`�[NO
    lt_key_bargain_class_name  := NULL;  --��ԓ����敪���́i���ׁj
    --
    ln_quantity := 0;
    --
    --����敪����}�X�^_012_A03�̏�������
    IF ( gt_bargain_class = cv_bargain_class_all ) THEN
      --����
      gt_qcc_sale_class := ct_qcc_sale_class || cv_multi;
    ELSE
      --�w�肠��
      gt_qcc_sale_class := ct_qcc_sale_class || gt_bargain_class || cv_multi;
    END IF;
    --
    --==================================
    -- 1.�f�[�^�擾
    --==================================
    <<loop_get_data>>
    FOR l_get_data_rec IN data_cur
    LOOP
      l_data_rec := l_get_data_rec;
      --���񃋁[�v�̃u���[�N�L�[�ݒ�
      IF (  ( lt_key_subinventory         IS NULL )           --�o�׌��ۊǏꏊ
        AND ( lt_key_schedule_ship_date   IS NULL )           --�o�ד�
        AND ( lt_key_request_date         IS NULL )           --����
        AND ( lv_key_edi_item_err_flag    IS NULL )           --�d�c�h�i�ڃG���[�t���O
        AND ( lt_key_item_code2           IS NULL )           --���i�R�[�h�Q
        AND ( lt_key_item_code            IS NULL )           --���i�R�[�h
        AND ( lt_key_chain_store_code     IS NULL )           --�`�F�[���X�R�[�h
        AND ( lt_key_store_code           IS NULL )           --�X�܃R�[�h
        AND ( lt_key_cust_code            IS NULL )           --�ڋq�R�[�h
        AND ( lt_key_cust_name            IS NULL )           --�ڋq��
        AND ( lt_key_slip_no              IS NULL )           --�`�[NO
        AND ( lt_key_bargain_class_name   IS NULL ) )         --��ԓ����敪����
      THEN
        --�L�[�u���C�N���ڃZ�b�g
        set_key_item;
        --���Z���ʉ��Z
        add_conv_quantity;
      ELSE
        --�u���[�N����
        IF (  ( comp_char( lt_key_subinventory,       l_data_rec.subinventory ) )           --�o�׌��ۊǏꏊ
          AND ( comp_date( lt_key_schedule_ship_date, l_data_rec.schedule_ship_date ) )     --�o�ד�
          AND ( comp_date( lt_key_request_date,       l_data_rec.request_date ) )           --����
          AND ( comp_char( lv_key_edi_item_err_flag,  l_data_rec.edi_item_err_flag ) )      --�d�c�h�i�ڃG���[�t���O
          AND ( comp_char( lt_key_item_code2,         l_data_rec.item_code2 ) )             --���i�R�[�h�Q
          AND (
                ( comp_char( lt_key_item_code, l_data_rec.item_code ) )                     --���i�R�[�h
                OR
                ( comp_char( cv_edi_item_err_flag_yes, l_data_rec.edi_item_err_flag ) )     --�G���[�i�ڂ͏��i�R�[�h�Ⴂ�����Z
              )
          AND ( comp_char( lt_key_chain_store_code,   l_data_rec.chain_store_code ) )       --�`�F�[���X�R�[�h
          AND ( comp_char( lt_key_store_code,         l_data_rec.store_code ) )             --�X�܃R�[�h
          AND ( comp_char( lt_key_cust_code,          l_data_rec.cust_code ) )              --�ڋq�R�[�h
          AND ( comp_char( lt_key_cust_name,          l_data_rec.cust_name ) )              --�ڋq��
          AND ( comp_char( lt_key_slip_no,            l_data_rec.slip_no ) )                --�`�[NO
          AND ( comp_char( lt_key_bargain_class_name, l_data_rec.bargain_class_name ) ) )   --��ԓ����敪����(����)
        THEN
          --���Z���ʉ��Z
          add_conv_quantity;
        ELSE
          --�����e�[�u���Z�b�g
          set_internal_table;
          --������
          ln_quantity := 0;
          --�L�[�u���C�N���ڃZ�b�g
          set_key_item;
          --���Z����
          add_conv_quantity;
        END IF;
--
      END IF;
--
    END LOOP loop_get_data;
--
    --==================================
    -- 2.�L�[�u���C�N���ڂ̃`�F�b�N
    --==================================
      IF (  ( lt_key_subinventory         IS NULL )           --�o�׌��ۊǏꏊ
        AND ( lt_key_schedule_ship_date   IS NULL )           --�o�ד�
        AND ( lt_key_request_date         IS NULL )           --����
        AND ( lv_key_edi_item_err_flag    IS NULL )           --�d�c�h�i�ڃG���[�t���O
        AND ( lt_key_item_code2           IS NULL )           --���i�R�[�h�Q
        AND ( lt_key_item_code            IS NULL )           --���i�R�[�h
        AND ( lt_key_chain_store_code     IS NULL )           --�`�F�[���X�R�[�h
        AND ( lt_key_store_code           IS NULL )           --�X�܃R�[�h
        AND ( lt_key_cust_code            IS NULL )           --�ڋq�R�[�h
        AND ( lt_key_cust_name            IS NULL )           --�ڋq��
        AND ( lt_key_slip_no              IS NULL )           --�`�[NO
        AND ( lt_key_bargain_class_name   IS NULL ) )         --��ԓ����敪����
      THEN
        NULL;
    ELSE
      --�����e�[�u���Z�b�g
      set_internal_table;
    END IF;
--
    IF ( g_rpt_data_tab.COUNT = 0 ) THEN
      NULL;
    ELSE
      --�Ώی���
      gn_target_cnt := g_rpt_data_tab.COUNT;
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
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���o�^(A-3)
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
    lv_key_info      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    --==================================
    -- 1.���[���[�N�e�[�u���o�^����
    --==================================
    <<loop_insert_rpt_wrk_data>>
    BEGIN
      FORALL i IN 1..g_rpt_data_tab.COUNT
      INSERT INTO
        xxcos_rep_pick_sale_car
      VALUES
        g_rpt_data_tab(i)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    -- ���팏��
    gn_normal_cnt := g_rpt_data_tab.COUNT;
--
  EXCEPTION
    WHEN global_insert_data_expt THEN
      --�e�[�u�����擾
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_rpt_wrk_tbl
                                 );
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_insert_data_err,
                                   iv_token_name1        => cv_tkn_table_name,
                                   iv_token_value1       => lv_table_name,
                                   iv_token_name2        => cv_tkn_key_data,
                                   iv_token_value2       => NULL
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END insert_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : �r�u�e�N��(A-4)
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
    lv_nodata_msg    VARCHAR2(5000);
    lv_file_name     VARCHAR2(5000);
    lv_svf_api       VARCHAR2(5000);
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
    --==================================
    -- 1.����0���p���b�Z�[�W�擾
    --==================================
    lv_nodata_msg  := xxccp_common_pkg.get_msg(
                        iv_application          => ct_xxcos_appl_short_name,
                        iv_name                 => ct_msg_nodata_err
                      );
--
    lv_file_name   := cv_file_id ||
                        TO_CHAR( SYSDATE, cv_fmt_date8 ) ||
                        TO_CHAR( cn_request_id ) ||
                        cv_extension_pdf
                      ;
    --==================================
    -- 2.SVF�N��
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_retcode              => lv_retcode,
      ov_errbuf               => lv_errbuf,
      ov_errmsg               => lv_errmsg,
      iv_conc_name            => cv_conc_name,
      iv_file_name            => lv_file_name,
      iv_file_id              => cv_file_id,
      iv_output_mode          => cv_output_mode_pdf,
      iv_frm_file             => cv_frm_file,
      iv_vrq_file             => cv_vrq_file,
      iv_org_id               => NULL,
      iv_user_name            => NULL,
      iv_resp_name            => NULL,
      iv_doc_name             => NULL,
      iv_printer_name         => NULL,
      iv_request_id           => TO_CHAR( cn_request_id ),
      iv_nodata_msg           => lv_nodata_msg,
      iv_svf_param1           => NULL,
      iv_svf_param2           => NULL,
      iv_svf_param3           => NULL,
      iv_svf_param4           => NULL,
      iv_svf_param5           => NULL,
      iv_svf_param6           => NULL,
      iv_svf_param7           => NULL,
      iv_svf_param8           => NULL,
      iv_svf_param9           => NULL,
      iv_svf_param10          => NULL,
      iv_svf_param11          => NULL,
      iv_svf_param12          => NULL,
      iv_svf_param13          => NULL,
      iv_svf_param14          => NULL,
      iv_svf_param15          => NULL
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_call_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_call_api_expt THEN
      lv_svf_api              := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_svf_api
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_call_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_svf_api
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END execute_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : ���[���[�N�e�[�u���폜(A-5)
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
    lv_key_info      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur
    IS
      SELECT xrpsc.request_id  request_id
      FROM   xxcos_rep_pick_sale_car  xrpsc    --�s�b�N���X�g_�o�׌��ۊǏꏊ_���i�ʒ��[���[�N�e�[�u��
      WHERE  xrpsc.request_id = cn_request_id  --�v��ID
      FOR UPDATE NOWAIT
      ;
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.���[���[�N�e�[�u���f�[�^���b�N
    --==================================
    BEGIN
      -- ���b�N�p�J�[�\���I�[�v��
      OPEN lock_cur;
      -- ���b�N�p�J�[�\���N���[�Y
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 2.���[���[�N�e�[�u���폜
    --==================================
    BEGIN
      DELETE FROM xxcos_rep_pick_sale_car  xrpsc
      WHERE  xrpsc.request_id = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�v��ID������擾
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application        => ct_xxcos_appl_short_name,
                         iv_name               => ct_msg_request,
                         iv_token_name1        => cv_tkn_request,
                         iv_token_value1       => TO_CHAR( cn_request_id )
                       );
--
        RAISE global_delete_data_expt;
    END;
--
  EXCEPTION
    -- *** �����Ώۃf�[�^���b�N��O�n���h�� ***
    WHEN global_data_lock_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      --�e�[�u�����擾
      lv_table_name  := xxccp_common_pkg.get_msg(
                          iv_application        => ct_xxcos_appl_short_name,
                          iv_name               => ct_msg_rpt_wrk_tbl
                        );
--
      ov_errmsg      := xxccp_common_pkg.get_msg(
                          iv_application        => ct_xxcos_appl_short_name,
                          iv_name               => ct_msg_lock_err,
                          iv_token_name1        => cv_tkn_table,
                          iv_token_value1       => lv_table_name
                        );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_delete_data_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      lv_table_name  := xxccp_common_pkg.get_msg(
                          iv_application        => ct_xxcos_appl_short_name,
                          iv_name               => ct_msg_rpt_wrk_tbl
                        );
      ov_errmsg      := xxccp_common_pkg.get_msg(
                          iv_application        => ct_xxcos_appl_short_name,
                          iv_name               => ct_msg_delete_data_err,
                          iv_token_name1        => cv_tkn_table_name,
                          iv_token_value1       => lv_table_name,
                          iv_token_name2        => cv_tkn_key_data,
                          iv_token_value2       => lv_key_info
                        );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
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
    iv_login_base_code        IN  VARCHAR2,     -- 1.���_
    iv_subinventory           IN  VARCHAR2,     -- 2.�o�׌��ۊǏꏊ
    iv_request_date_from      IN  VARCHAR2,     -- 3.�����iFrom�j
    iv_request_date_to        IN  VARCHAR2,     -- 4.�����iTo�j
    iv_bargain_class          IN  VARCHAR2,     -- 5.��ԓ����敪
    iv_sales_output_type      IN  VARCHAR2,     -- 6.����Ώۋ敪
    iv_edi_received_date      IN  VARCHAR2,     -- 7.EDI��M��
    ov_errbuf                 OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                 OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h(SVF���s���ʕێ��p)
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
--
--###########################  �Œ蕔 END   ####################################
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt             := 0;
    gn_normal_cnt             := 0;
    gn_error_cnt              := 0;
    gn_warn_cnt               := 0;
--
    -- ===============================
    -- A-0  ��������
    -- ===============================
    init(
      iv_login_base_code        => iv_login_base_code,          -- 1.���_
      iv_subinventory           => iv_subinventory,             -- 2.�o�׌��ۊǏꏊ
      iv_request_date_from      => iv_request_date_from,        -- 3.�����iFrom�j
      iv_request_date_to        => iv_request_date_to,          -- 4.�����iTo�j
      iv_bargain_class          => iv_bargain_class,            -- 5.��ԓ����敪
      iv_sales_output_type      => iv_sales_output_type,        -- 6.����Ώۋ敪
      iv_edi_received_date      => iv_edi_received_date,        -- 7.EDI��M��
      ov_errbuf                 => lv_errbuf,                   -- �G���[�E���b�Z�[�W
      ov_retcode                => lv_retcode,                  -- ���^�[���E�R�[�h
      ov_errmsg                 => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-1  �p�����[�^�`�F�b�N����
    -- ===============================
    check_parameter(
      ov_errbuf                 => lv_errbuf,                   -- �G���[�E���b�Z�[�W
      ov_retcode                => lv_retcode,                  -- ���^�[���E�R�[�h
      ov_errmsg                 => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  �f�[�^�擾
    -- ===============================
    get_data(
      ov_errbuf                 => lv_errbuf,                   -- �G���[�E���b�Z�[�W
      ov_retcode                => lv_retcode,                  -- ���^�[���E�R�[�h
      ov_errmsg                 => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  ���[���[�N�e�[�u���o�^
    -- ===============================
    insert_rpt_wrk_data(
      ov_errbuf                 => lv_errbuf,                   -- �G���[�E���b�Z�[�W
      ov_retcode                => lv_retcode,                  -- ���^�[���E�R�[�h
      ov_errmsg                 => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
    -- ===============================
    -- A-4  �r�u�e�N��
    -- ===============================
    execute_svf(
      ov_errbuf                 => lv_errbuf,                   -- �G���[�E���b�Z�[�W
      ov_retcode                => lv_retcode,                  -- ���^�[���E�R�[�h
      ov_errmsg                 => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    --�G���[�ł����[�N�e�[�u�����폜����ׁA�G���[����ێ�
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
--
    -- ===============================
    -- A-3  ���[���[�N�e�[�u���폜
    -- ===============================
    delete_rpt_wrk_data(
      ov_errbuf                 => lv_errbuf,                   -- �G���[�E���b�Z�[�W
      ov_retcode                => lv_retcode,                  -- ���^�[���E�R�[�h
      ov_errmsg                 => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    COMMIT;
--
    --SVF���s���ʊm�F
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
--
    --���ׂO�����̌x���I������
    IF ( g_rpt_data_tab.COUNT = 0 ) THEN
      ov_retcode  := cv_status_warn;
    END IF;
--
  EXCEPTION
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
    errbuf                    OUT  VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                   OUT  VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_login_base_code        IN   VARCHAR2,      -- 1.���_
    iv_subinventory           IN   VARCHAR2,      -- 2.�o�׌��ۊǏꏊ
    iv_request_date_from      IN   VARCHAR2,      -- 3.�����iFrom�j
    iv_request_date_to        IN   VARCHAR2,      -- 4.�����iTo�j
    iv_bargain_class          IN   VARCHAR2,      -- 5.��ԓ����敪
    iv_sales_output_type      IN   VARCHAR2,      -- 6.����Ώۋ敪
    iv_edi_received_date      IN   VARCHAR2       -- 7.EDI��M��
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
      iv_which    => cv_log_header_log,
      ov_retcode  => lv_retcode,
      ov_errbuf   => lv_errbuf,
      ov_errmsg   => lv_errmsg
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
       iv_login_base_code                  -- 1.���_
      ,iv_subinventory                     -- 2.�o�׌��ۊǏꏊ
      ,iv_request_date_from                -- 3.�����iFrom�j
      ,iv_request_date_to                  -- 4.�����iTo�j
      ,iv_bargain_class                    -- 5.��ԓ����敪
      ,iv_sales_output_type                -- 6.����Ώۋ敪
      ,iv_edi_received_date                -- 7.EDI��M��
      ,lv_errbuf                           --   �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                          --   ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                           --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG,
        buff    => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG,
        buff    => lv_errbuf --�G���[���b�Z�[�W
      );
      --�����J�E���g
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
      which   => FND_FILE.LOG,
      buff    => NULL
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_target_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_success_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_error_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --1�s��
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => NULL
    );
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
    fnd_file.put_line(
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
END XXCOS012A04R;
/
