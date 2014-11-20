CREATE OR REPLACE PACKAGE BODY XXCOS006A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS006A04R (body)
 * Description      : �o�׈˗���
 * MD.050           : �o�׈˗��� MD050_COS_006_A04
 * Version          : 1.3
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
 *  2008/11/07    1.0   K.Kakishita      �V�K�쐬
 *  2009/02/26    1.1   K.Kakishita      ���[�R���J�����g�N����̃��[�N�e�[�u���폜������
 *                                       �R�����g�����O���B
 *  2009/03/03    1.2   N.Maeda          �s�v�Ȓ萔�̍폜
 *                                       ( ct_qct_cus_class_mst , ct_qcc_cus_class_mst1 )
 *  2009/04/01    1.3   N.Maeda          �yST��QNo.T1-0085�Ή��z
 *                                       ��݌ɕi�ڂ�񒊏o�f�[�^�֕ύX
 *                                       �yST��QNo.T1-0049�Ή��z
 *                                       ���l�f�[�^�擾�J�������̏C��
 *                                       description�ւ̃Z�b�g���e���C��
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
  global_proc_date_err_expt   EXCEPTION;
  global_api_err_expt         EXCEPTION;
  global_call_api_expt        EXCEPTION;
  global_date_reversal_expt   EXCEPTION;
  global_insert_data_expt     EXCEPTION;
  global_delete_data_expt     EXCEPTION;
  global_nodata_expt          EXCEPTION;
  global_get_profile_expt     EXCEPTION;
  --*** �����Ώۃf�[�^���b�N��O ***
  global_data_lock_expt       EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100) := 'XXCOS006A04R';          -- �p�b�P�[�W��
  --���[�֘A
  cv_conc_name              CONSTANT  VARCHAR2(100) := 'XXCOS006A04R';          -- �R���J�����g��
  cv_file_id                CONSTANT  VARCHAR2(100) := 'XXCOS006A04R';          -- ���[�h�c
  cv_extension_pdf          CONSTANT  VARCHAR2(100) := '.pdf';                  -- �g���q�i�o�c�e�j
  cv_frm_file               CONSTANT  VARCHAR2(100) := 'XXCOS006A04S.xml';      -- �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT  VARCHAR2(100) := 'XXCOS006A04S.vrq';      -- �N�G���[�l���t�@�C����
  cv_output_mode_pdf        CONSTANT  VARCHAR2(1)   := '1';                     -- �o�͋敪�i�o�c�e�j
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name  CONSTANT  fnd_application.application_short_name%TYPE
                                      := 'XXCOS';                     --�̕��Z�k�A�v����
  ct_xxwsh_appl_short_name  CONSTANT  fnd_application.application_short_name%TYPE
                                      := 'XXWSH';                     --�Z�k�A�v����
  --�̕����b�Z�[�W
  ct_msg_lock_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00001';          --���b�N�擾�G���[���b�Z�[�W
  ct_msg_get_profile_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00004';          --�v���t�@�C���擾�G���[
  ct_msg_date_reversal_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00005';          --���t�t�]�G���[
  ct_msg_insert_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00010';          --�f�[�^�o�^�G���[���b�Z�[�W
  ct_msg_delete_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00012';          --�f�[�^�폜�G���[���b�Z�[�W
  ct_msg_select_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00013';          --�f�[�^�擾�G���[���b�Z�[�W
  ct_msg_process_date_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00014';          --�Ɩ����t�擾�G���[
  ct_msg_call_api_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00017';          --API�ďo�G���[���b�Z�[�W
  ct_msg_nodata_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00018';          --����0���p���b�Z�[�W
  ct_msg_svf_api            CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00041';          --�r�u�e�N���`�o�h
  ct_msg_request            CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00042';          --�v���h�c
  ct_msg_org_id             CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00047';          --MO:�c�ƒP��
  ct_msg_max_date           CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00056';          --XXCOS:MAX���t
  ct_msg_company_name       CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-00058';          --XXCOS:��Ж�
  ct_msg_parameter          CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11451';          --�p�����[�^�o�̓��b�Z�[�W
  ct_msg_ord_dt_from        CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11452';          --�󒍓�(From)
  ct_msg_ord_dt_to          CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11453';          --�󒍓�(To)
  ct_msg_rpt_wrk_tbl        CONSTANT  fnd_new_messages.message_name%TYPE
                                      := 'APP-XXCOS1-11454';          --���[���[�N�e�[�u��
  --�g�[�N��
  cv_tkn_table              CONSTANT  VARCHAR2(100) := 'TABLE';                 --�e�[�u��
  cv_tkn_date_from          CONSTANT  VARCHAR2(100) := 'DATE_FROM';             --���t�iFrom)
  cv_tkn_date_to            CONSTANT  VARCHAR2(100) := 'DATE_TO';               --���t�iTo)
  cv_tkn_profile            CONSTANT  VARCHAR2(100) := 'PROFILE';               --�v���t�@�C��
  cv_tkn_table_name         CONSTANT  VARCHAR2(100) := 'TABLE_NAME';            --�e�[�u������
  cv_tkn_key_data           CONSTANT  VARCHAR2(100) := 'KEY_DATA';              --�L�[�f�[�^
  cv_tkn_api_name           CONSTANT  VARCHAR2(100) := 'API_NAME';              --�`�o�h����
  cv_tkn_param1             CONSTANT  VARCHAR2(100) := 'PARAM1';                --��P���̓p�����[�^
  cv_tkn_param2             CONSTANT  VARCHAR2(100) := 'PARAM2';                --��Q���̓p�����[�^
  cv_tkn_param3             CONSTANT  VARCHAR2(100) := 'PARAM3';                --��R���̓p�����[�^
  cv_tkn_request            CONSTANT  VARCHAR2(100) := 'REQUEST';               --�v���h�c
  --�v���t�@�C������
  ct_prof_org_id            CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'ORG_ID';
  ct_prof_max_date          CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_MAX_DATE';
  ct_prof_company_name      CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                      := 'XXCOS1_COMPANY_NAME';
  --�N�C�b�N�R�[�h�^�C�v
  ct_qct_order_type         CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_TRAN_TYPE_MST_006_A04';
  ct_qct_order_source       CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_ODR_SRC_MST_006_A04';
  ct_qct_hokanbasyo_type    CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_HOKAN_TYPE_MST_006_A04';
  ct_qct_arrival_time       CONSTANT  fnd_lookup_types.lookup_type%TYPE
                                      := 'XXWSH_ARRIVAL_TIME';
  ct_xxcos1_no_inv_item_code CONSTANT fnd_lookup_types.lookup_type%TYPE
                                      := 'XXCOS1_NO_INV_ITEM_CODE';
  --�N�C�b�N�R�[�h
  ct_qcc_order_type         CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_006_A04%';
  ct_qcc_order_source       CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_006_A04%';
  ct_qcc_hokanbasyo_type    CONSTANT  fnd_lookup_values.lookup_code%TYPE
                                      := 'XXCOS_006_A04%';
  --�g�p�\�t���O�萔
  ct_enabled_flag_yes       CONSTANT  fnd_lookup_values.enabled_flag%TYPE
                                      := 'Y';                         --�g�p�\
  --�󒍃w�b�_�X�e�[�^�X
  ct_hdr_status_booked      CONSTANT  oe_order_headers_all.flow_status_code%TYPE
                                      := 'BOOKED';                    --�L����
  --�󒍖��׃X�e�[�^�X
  ct_ln_status_closed       CONSTANT  oe_order_lines_all.flow_status_code%TYPE
                                      := 'CLOSED';                    --�N���[�Y
  ct_ln_status_cancelled    CONSTANT  oe_order_lines_all.flow_status_code%TYPE
                                      := 'CANCELLED';                 --���
  --�g�p�ړI
  ct_site_use_code_ship_to  CONSTANT  hz_cust_site_uses_all.site_use_code%TYPE
                                      := 'SHIP_TO';                   --�o�א�
  --�󒍃^�C�v�R�[�h
  ct_tran_type_code_order   CONSTANT  oe_transaction_types_all.transaction_type_code%TYPE
                                      := 'ORDER';                     --ORDEDR
  --���Z���f�t�H���g
  ct_conv_rate_default      CONSTANT  mtl_uom_class_conversions.conversion_rate%TYPE
                                      := 1;                           --���Z��
  --���݃t���O
  cv_exists_flag_yes        CONSTANT  VARCHAR2(1)   := 'Y';           --���݂���
  --�t�H�[�}�b�g
  cv_fmt_date8              CONSTANT  VARCHAR2(8)   := 'RRRRMMDD';
  cv_fmt_date               CONSTANT  VARCHAR2(10)  := 'RRRR/MM/DD';
  cv_fmt_datetime           CONSTANT  VARCHAR2(21)  := 'RRRR/MM/DD HH24:MI:SS';
  --�����萔
  cv_hyphen                 CONSTANT  VARCHAR2(1)   := '-';           --�n�C�t��
  cv_space                  CONSTANT  VARCHAR2(1)   := ' ';           --�X�y�[�X
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���[���[�N�p�e�[�u���^��`
  TYPE g_rpt_data_ttype
  IS
    TABLE OF
      xxcos_rep_deli_req%ROWTYPE
    INDEX BY PLS_INTEGER
    ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�p�����[�^
  gt_ship_from_subinv_code            mtl_secondary_inventories.secondary_inventory_name%TYPE;
                                                                      -- �o�׌��ۊǏꏊ
  gd_ordered_date_from                DATE;                           -- �󒍓�(From)
  gd_ordered_date_to                  DATE;                           -- �󒍓�(To)
  --�����擾
  gd_process_date                     DATE;                           -- �Ɩ����t
  gn_org_id                           NUMBER;                         -- �c�ƒP��
  gd_max_date                         DATE;                           -- MAX���t
  gv_company_name                     VARCHAR2(30);                   -- ��Ж�
  --���[���[�N�����e�[�u��
  g_rpt_data_tab                      g_rpt_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ship_from_subinv_code  IN      VARCHAR2,       -- 1.�o�׌��q��
    iv_ordered_date_from      IN      VARCHAR2,       -- 2.�󒍓��iFrom�j
    iv_ordered_date_to        IN      VARCHAR2,       -- 3.�󒍓��iTo�j
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    --==================================
    -- 1.�p�����[�^�o��
    --==================================
    lv_errmsg                 := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_parameter,
                                   iv_token_name1        => cv_tkn_param1,
                                   iv_token_value1       => iv_ship_from_subinv_code,
                                   iv_token_name2        => cv_tkn_param2,
                                   iv_token_value2       => iv_ordered_date_from,
                                   iv_token_name3        => cv_tkn_param3,
                                   iv_token_value3       => iv_ordered_date_to
                                 );
    --
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => lv_errmsg
    );
    --1�s��
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => NULL
    );
--
    --==================================
    -- 2.�p�����[�^�ϊ�
    --==================================
    gt_ship_from_subinv_code  := iv_ship_from_subinv_code;
    gd_ordered_date_from      := TO_DATE( iv_ordered_date_from, cv_fmt_datetime );
    gd_ordered_date_to        := TO_DATE( iv_ordered_date_to, cv_fmt_datetime );
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
--
    -- *** ���[�J���ϐ� ***
    lv_org_id        VARCHAR2(5000);
    lv_max_date      VARCHAR2(5000);
    lv_profile_name  VARCHAR2(5000);
    lv_ord_dt_from   VARCHAR2(5000);
    lv_ord_dt_to     VARCHAR2(5000);
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
    --==================================
    -- 1.�Ɩ����t�擾
    --==================================
    gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    --==================================
    -- 2.MO:�c�ƒP��
    --==================================
    lv_org_id                 := FND_PROFILE.VALUE( ct_prof_org_id );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_org_id IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_org_id,
                                   iv_token_value1       => ct_prof_org_id
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gn_org_id                 := TO_NUMBER( lv_org_id );
--
    --==================================
    -- 3.XXCOS:MAX���t
    --==================================
    lv_max_date               := FND_PROFILE.VALUE( ct_prof_max_date );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_max_date  IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_max_date
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    gd_max_date               := TO_DATE( lv_max_date, cv_fmt_date );
--
    --==================================
    -- 4.XXCOS:��Ж�
    --==================================
    gv_company_name           := FND_PROFILE.VALUE( ct_prof_company_name );
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( gv_company_name IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_company_name
                                 );
      --
      RAISE global_get_profile_expt;
    END IF;
--
    --==================================
    -- 5.�p�����[�^�`�F�b�N
    --==================================
    IF ( gd_ordered_date_from > gd_ordered_date_to ) THEN
      RAISE global_date_reversal_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_process_date_err
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C����O�n���h�� ***
    WHEN global_get_profile_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_get_profile_err,
                                   iv_token_name1        => cv_tkn_profile,
                                   iv_token_value1       => lv_profile_name
                                 );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���t�t�]��O�n���h�� ***
    WHEN global_date_reversal_expt THEN
      lv_ord_dt_from          := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_ord_dt_from
                                 );
      lv_ord_dt_to            := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_ord_dt_to
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_date_reversal_err,
                                   iv_token_name1        => cv_tkn_date_from,
                                   iv_token_value1       => lv_ord_dt_from,
                                   iv_token_name2        => cv_tkn_date_to,
                                   iv_token_value2       => lv_ord_dt_to
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
--
    -- *** ���[�J���ϐ� ***
    ln_idx           NUMBER;
    ln_record_id     NUMBER;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR data_cur
    IS
      SELECT
        oola.subinventory                   subinventory,                 --�ۊǏꏊ
        msi.description                     deliver_from_locat_name,      --�o�׌��ۊǏꏊ����
        xca.delivery_base_code              delivery_base_code,           --�[�i���_�R�[�h
        xla.location_name                   delivery_base_name,           --�[�i���_��
        xla.zip                             delivery_base_post_no,        --�[�i���_�X�֔ԍ�
        xla.address_line1                   delivery_base_address,        --�[�i���_�Z��
        xla.phone                           delivery_base_telephone_no,   --�[�i���_�d�b�ԍ�
        xla.fax                             delivery_base_fax_no,         --�[�i���_FAX�ԍ�
        ooha.order_number                   order_number,                 --�`�[NO
        TRUNC( ooha.ordered_date )          ordered_date,                 --�o�׈˗���
        TRUNC( oola.schedule_ship_date )    schedule_ship_date,           --�o�ד�
        oola.request_date                   request_date,                 --����
        oola.attribute8                     requested_time_from,          --���Ԏw��(From)
        oola.attribute9                     requested_time_to,            --���Ԏw��(To)
        hca.account_number                  delivery_to_code,             --�z����R�[�h
        hp.party_name                       delivery_to_name,             --�z���於
        hl.city                             delivery_to_city,             --�z����s���{��
        hl.state                            delivery_to_state,            --�z����s����
        hl.address1                         delivery_to_address1,         --�z����Z���P
        hl.address2                         delivery_to_address2,         --�z����Z���Q
        hl.address_lines_phonetic           delivery_to_tel,              --�d�b�ԍ�
        ooha.shipping_instructions          shipping_instructions,        --�o�׎w��
        oola.line_number                    line_number,                  --���הԍ�
        msib.segment1                       item_code,                    --�i�ڃR�[�h
        msib.description                    description,                  --�E�v
        NVL( mucc.conversion_rate, ct_conv_rate_default )
                                            conversion_rate,              --���Z�l
        oola.ordered_quantity               ordered_quantity,             --�󒍐���
        oola.order_quantity_uom             order_quantity_uom,           --�󒍒P��
        oola.attribute7                     remark                        --���l
      FROM
        oe_order_headers_all                ooha,                         --�󒍃w�b�_�e�[�u��
        oe_order_lines_all                  oola,                         --�󒍖��׃e�[�u��
        oe_order_sources                    oos,                          --�󒍃\�[�X�}�X�^
        oe_transaction_types_all            otta,                         --�󒍃^�C�v�}�X�^
        oe_transaction_types_tl             ottt,                         --�󒍃^�C�v�}�X�^
        hr_locations_all                    hla,                          --���Ə��}�X�^
        xxcmn_locations_all                 xla,                          --���Ə��A�h�I���}�X�^
        hz_cust_accounts                    hca,                          --�ڋq�}�X�^
        xxcmm_cust_accounts                 xca,                          --�A�J�E���g�A�h�I���}�X�^
        hz_cust_site_uses_all               hcsua,                        --�ڋq�g�p�ړI�}�X�^
        hz_cust_acct_sites_all              hcasa,                        --�ڋq���ݒn�}�X�^
        hz_party_sites                      hps,                          --�p�[�e�B�T�C�g�}�X�^
        hz_parties                          hp,                           --�p�[�e�B�}�X�^
        hz_locations                        hl,                           --�ڋq���Ə��}�X�^
        mtl_system_items_b                  msib,                         --�i�ڃ}�X�^
        mtl_uom_class_conversions           mucc,                         --�P�ʕϊ��}�X�^
        mtl_secondary_inventories           msi                           --�ۊǏꏊ�}�X�^
      WHERE
        ooha.header_id                      = oola.header_id
      AND ooha.order_type_id                = otta.transaction_type_id
      AND otta.transaction_type_id          = ottt.transaction_type_id
      AND otta.transaction_type_code        = ct_tran_type_code_order
      AND EXISTS(
            SELECT
              cv_exists_flag_yes            exists_flag
            FROM
              fnd_application               fa,
              fnd_lookup_types              flt,
              fnd_lookup_values             flv
            WHERE
              fa.application_id             = flt.application_id
            AND flt.lookup_type             = flv.lookup_type
            AND fa.application_short_name   = ct_xxcos_appl_short_name
            AND flv.lookup_type             = ct_qct_order_type
            AND flv.lookup_code             LIKE ct_qcc_order_type
            AND flv.meaning                 = ottt.name
            AND TRUNC( ooha.ordered_date )  >= flv.start_date_active
            AND TRUNC( ooha.ordered_date )  <= NVL( flv.end_date_active, gd_max_date )
            AND flv.enabled_flag            = ct_enabled_flag_yes
            AND flv.language                = USERENV( 'LANG' )
            AND ROWNUM                      = 1
          )
      AND ottt.language                     = USERENV( 'LANG' )
      AND ooha.order_source_id              = oos.order_source_id
      AND EXISTS(
            SELECT
              cv_exists_flag_yes            exists_flag
            FROM
              fnd_application               fa,
              fnd_lookup_types              flt,
              fnd_lookup_values             flv
            WHERE
              fa.application_id             = flt.application_id
            AND flt.lookup_type             = flv.lookup_type
            AND fa.application_short_name   = ct_xxcos_appl_short_name
            AND flv.lookup_type             = ct_qct_order_source
            AND flv.lookup_code             LIKE ct_qcc_order_source
            AND flv.meaning                 = oos.name
            AND TRUNC( ooha.ordered_date )  >= flv.start_date_active
            AND TRUNC( ooha.ordered_date )  <= NVL( flv.end_date_active, gd_max_date )
            AND flv.enabled_flag            = ct_enabled_flag_yes
            AND flv.language                = USERENV( 'LANG' )
            AND ROWNUM                      = 1
          )
      AND ooha.flow_status_code             = ct_hdr_status_booked
      AND oola.flow_status_code             NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )
      AND TRUNC( ooha.ordered_date )        >= gd_ordered_date_from
      AND TRUNC( ooha.ordered_date )        <= NVL( gd_ordered_date_to, gd_max_date )
      AND oola.subinventory                 = msi.secondary_inventory_name
      AND oola.ship_from_org_id             = msi.organization_id
      AND oola.subinventory                 = NVL( gt_ship_from_subinv_code, oola.subinventory )
      AND EXISTS(
            SELECT
              cv_exists_flag_yes            exists_flag
            FROM
              fnd_application               fa,
              fnd_lookup_types              flt,
              fnd_lookup_values             flv
            WHERE
              fa.application_id             = flt.application_id
            AND flt.lookup_type             = flv.lookup_type
            AND fa.application_short_name   = ct_xxcos_appl_short_name
            AND flv.lookup_type             = ct_qct_hokanbasyo_type
            AND flv.lookup_code             LIKE ct_qcc_hokanbasyo_type
            AND flv.meaning                 = msi.attribute13
            AND TRUNC( ooha.ordered_date )  >= flv.start_date_active
            AND TRUNC( ooha.ordered_date )  <= NVL( flv.end_date_active, gd_max_date )
            AND flv.enabled_flag            = ct_enabled_flag_yes
            AND flv.language                = USERENV( 'LANG' )
            AND ROWNUM                      = 1
          )
      AND oola.sold_to_org_id               = hca.cust_account_id
      AND hca.cust_account_id               = xca.customer_id
      AND hca.party_id                      = hp.party_id
      AND xca.delivery_base_code            = hla.location_code
      AND hla.location_id                   = xla.location_id
      AND EXISTS(
            SELECT
              cv_exists_flag_yes            exists_flag
            FROM
              xxcos_login_base_info_v       xlbiv
            WHERE
              xlbiv.base_code               = xca.delivery_base_code
            AND ROWNUM                      = 1
          )
      AND oola.ship_to_org_id               = hcsua.site_use_id
      AND hcsua.site_use_code               = ct_site_use_code_ship_to
      AND hcsua.cust_acct_site_id           = hcasa.cust_acct_site_id
      AND hcasa.party_site_id               = hps.party_site_id
      AND hps.location_id                   = hl.location_id
      AND oola.inventory_item_id            = msib.inventory_item_id
      AND oola.ship_from_org_id             = msib.organization_id
      AND mucc.inventory_item_id (+)        = oola.inventory_item_id
      AND mucc.to_uom_code (+)              = oola.order_quantity_uom
      AND ooha.org_id                       = gn_org_id
      AND TRUNC( ooha.ordered_date )        >= xla.start_date_active
      AND TRUNC( ooha.ordered_date )        <= NVL( xla.end_date_active, ooha.ordered_date )
      AND msib.segment1 NOT IN (
            SELECT  look_val.lookup_code
            FROM    fnd_lookup_values     look_val,
                    fnd_lookup_types_tl   types_tl,
                    fnd_lookup_types      types,
                    fnd_application_tl    appl,
                    fnd_application       app
            WHERE   appl.application_id   = types.application_id
            AND     app.application_id    = appl.application_id
            AND     types_tl.lookup_type  = look_val.lookup_type
            AND     types.lookup_type     = types_tl.lookup_type
            AND     types.security_group_id   = types_tl.security_group_id
            AND     types.view_application_id = types_tl.view_application_id
            AND     types_tl.language = USERENV( 'LANG' )
            AND     look_val.language = USERENV( 'LANG' )
            AND     appl.language     = USERENV( 'LANG' )
            AND     app.application_short_name = ct_xxcos_appl_short_name
            AND     gd_process_date      >= look_val.start_date_active
            AND     gd_process_date      <= NVL(look_val.end_date_active, gd_max_date)
            AND     look_val.enabled_flag = ct_enabled_flag_yes
            AND     look_val.lookup_type = ct_xxcos1_no_inv_item_code )
      ;
--
      --====================================================
      -- ���Ԏw�蕶����擾
      --====================================================
      CURSOR xat_cur(
        iv_request_time      IN         VARCHAR2,
        id_ordered_date      IN         DATE
      )
      IS
        SELECT
          flv.lookup_code               lookup_code,
          flv.description               description
        FROM
          fnd_application               fa,
          fnd_lookup_types              flt,
          fnd_lookup_values             flv
        WHERE
          fa.application_id             = flt.application_id
        AND flt.lookup_type             = flv.lookup_type
        AND fa.application_short_name   = ct_xxwsh_appl_short_name
        AND flt.lookup_type             = ct_qct_arrival_time
        AND flv.lookup_code             = iv_request_time
        AND id_ordered_date             >= flv.start_date_active
        AND id_ordered_date             <= NVL( flv.end_date_active, gd_max_date )
        AND flv.language                = USERENV( 'LANG' )
        AND flv.enabled_flag            = ct_enabled_flag_yes
        AND ROWNUM                      = 1
        ;
    -- *** ���[�J���E���R�[�h ***
    l_data_rec                          data_cur%ROWTYPE;
    l_xat_rec                           xat_cur%ROWTYPE;
    l_xatf_rec                          xat_cur%ROWTYPE;
    l_xatt_rec                          xat_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ln_idx          := 0;
--
    --==================================
    -- 1.�f�[�^�擾
    --==================================
    <<loop_get_data>>
    FOR l_data_rec IN data_cur
    LOOP
      -- ���R�[�hID�̎擾
      BEGIN
        SELECT
          xxcos_rep_deli_req_s01.NEXTVAL          redord_id
        INTO
          ln_record_id
        FROM
          dual
        ;
      END;
      --
      ln_idx                  := ln_idx + 1;
      --�����e�[�u���Z�b�g
      g_rpt_data_tab(ln_idx).record_id                    := ln_record_id;
      g_rpt_data_tab(ln_idx).despatching_code             := l_data_rec.subinventory;
      g_rpt_data_tab(ln_idx).company_name                 := gv_company_name;
      g_rpt_data_tab(ln_idx).deliver_from_locat_name      := SUBSTRB( l_data_rec.deliver_from_locat_name, 1, 40 );
      g_rpt_data_tab(ln_idx).base_code                    := l_data_rec.delivery_base_code;
      g_rpt_data_tab(ln_idx).base_name                    := l_data_rec.delivery_base_name;
      g_rpt_data_tab(ln_idx).base_post_no                 := l_data_rec.delivery_base_post_no;
      g_rpt_data_tab(ln_idx).base_address                 := l_data_rec.delivery_base_address;
      g_rpt_data_tab(ln_idx).base_telephone_no            := l_data_rec.delivery_base_telephone_no;
      g_rpt_data_tab(ln_idx).base_fax_no                  := l_data_rec.delivery_base_fax_no;
      g_rpt_data_tab(ln_idx).entry_number                 := l_data_rec.order_number;
      g_rpt_data_tab(ln_idx).delivery_requested_date      := l_data_rec.ordered_date;
      g_rpt_data_tab(ln_idx).shipped_date                 := l_data_rec.schedule_ship_date;
      g_rpt_data_tab(ln_idx).arrival_date                 := l_data_rec.request_date;
      --���Ԏw��(From)
      l_xatf_rec    := l_xat_rec;
      FOR xat_rec IN xat_cur(
                       iv_request_time      => l_data_rec.requested_time_from,
                       id_ordered_date      => l_data_rec.ordered_date
                     )
      LOOP
        l_xatf_rec  := xat_rec;
      END LOOP;
      --���Ԏw��(To)
      l_xatt_rec    := l_xat_rec;
      FOR xat_rec IN xat_cur(
                       iv_request_time      => l_data_rec.requested_time_to,
                       id_ordered_date      => l_data_rec.ordered_date
                     )
      LOOP
        l_xatt_rec  := xat_rec;
      END LOOP;
      --���Ԏw��
      IF ( ( TRIM( l_xatf_rec.description ) IS NULL )
        AND ( TRIM( l_xatt_rec.description ) IS NULL ) )
      THEN
        g_rpt_data_tab(ln_idx).requested_time             := NULL;
      ELSE
        g_rpt_data_tab(ln_idx).requested_time             := LPAD(
                                                               NVL( TRIM( l_xatf_rec.description ), cv_space ),
                                                               5
                                                             ) || cv_hyphen || TRIM( l_xatt_rec.description );
      END IF;
      g_rpt_data_tab(ln_idx).delivery_code                := l_data_rec.delivery_to_code;
      g_rpt_data_tab(ln_idx).deliver_to_name              := SUBSTRB( l_data_rec.delivery_to_name, 1, 60 );
      g_rpt_data_tab(ln_idx).delivery_address             := SUBSTRB(
                                                               l_data_rec.delivery_to_state ||
                                                               l_data_rec.delivery_to_city ||
                                                               l_data_rec.delivery_to_address1 ||
                                                               l_data_rec.delivery_to_address2,
                                                               1, 60
                                                             );
      g_rpt_data_tab(ln_idx).telephone_no                 := SUBSTRB( l_data_rec.delivery_to_tel, 1, 15 );
      g_rpt_data_tab(ln_idx).description                  := SUBSTRB( l_data_rec.shipping_instructions, 1, 80 );
      g_rpt_data_tab(ln_idx).order_line_number            := l_data_rec.line_number;
      g_rpt_data_tab(ln_idx).item_code                    := l_data_rec.item_code;
      g_rpt_data_tab(ln_idx).item_name                    := l_data_rec.description;
      g_rpt_data_tab(ln_idx).content                      := l_data_rec.conversion_rate;
      g_rpt_data_tab(ln_idx).shipment_quantity            := l_data_rec.ordered_quantity;
      g_rpt_data_tab(ln_idx).shipment_uom                 := l_data_rec.order_quantity_uom;
      g_rpt_data_tab(ln_idx).remarks_column               := l_data_rec.remark;
      g_rpt_data_tab(ln_idx).created_by                   := cn_created_by;
      g_rpt_data_tab(ln_idx).creation_date                := cd_creation_date;
      g_rpt_data_tab(ln_idx).last_updated_by              := cn_last_updated_by;
      g_rpt_data_tab(ln_idx).last_update_date             := cd_last_update_date;
      g_rpt_data_tab(ln_idx).last_update_login            := cn_last_update_login;
      g_rpt_data_tab(ln_idx).request_id                   := cn_request_id;
      g_rpt_data_tab(ln_idx).program_application_id       := cn_program_application_id;
      g_rpt_data_tab(ln_idx).program_id                   := cn_program_id;
      g_rpt_data_tab(ln_idx).program_update_date          := cd_program_update_date;
      --
    END LOOP loop_get_data;
--
    IF ( g_rpt_data_tab.COUNT = 0 ) THEN
      NULL;
    ELSE
      --�Ώی���
      gn_target_cnt           := g_rpt_data_tab.COUNT;
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
    -- 1.�o�׈˗������[���[�N�e�[�u���o�^����
    --==================================
    <<loop_insert_rpt_wrk_data>>
    BEGIN
      FORALL i IN 1..g_rpt_data_tab.COUNT --SAVE EXCEPTIONS
        INSERT INTO
          xxcos_rep_deli_req
        VALUES
          g_rpt_data_tab(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    -- ���팏��
    gn_normal_cnt             := g_rpt_data_tab.COUNT;
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
    lv_api_name      VARCHAR2(5000);
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
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    --==================================
    -- 1.����0���p���b�Z�[�W�擾
    --==================================
    lv_nodata_msg             := xxccp_common_pkg.get_msg(
                                   iv_application          => ct_xxcos_appl_short_name,
                                   iv_name                 => ct_msg_nodata_err
                                 );
    --�o�̓t�@�C���ҏW
    lv_file_name              := cv_file_id ||
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
      lv_api_name             := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_svf_api
                                 );
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_call_api_err,
                                   iv_token_name1        => cv_tkn_api_name,
                                   iv_token_value1       => lv_api_name
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
      SELECT
        xrdr.record_id        record_id
      FROM
        xxcos_rep_deli_req    xrdr                    --�o�׈˗������[���[�N�e�[�u��
      WHERE
        xrdr.request_id       = cn_request_id         --�v��ID
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
      DELETE FROM
        xxcos_rep_deli_req    xrdr
      WHERE
        xrdr.request_id       = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�v��ID������擾
        lv_key_info           := xxccp_common_pkg.get_msg(
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
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_rpt_wrk_tbl
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
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
      --�e�[�u�����擾
      lv_table_name           := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_rpt_wrk_tbl
                                 );
--
      ov_errmsg               := xxccp_common_pkg.get_msg(
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
    iv_ship_from_subinv_code  IN      VARCHAR2,       -- 1.�o�׌��q��
    iv_ordered_date_from      IN      VARCHAR2,       -- 2.�󒍓��iFrom�j
    iv_ordered_date_to        IN      VARCHAR2,       -- 3.�󒍓��iTo�j
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
      iv_ship_from_subinv_code  => iv_ship_from_subinv_code,    -- 1.�o�׌��q��
      iv_ordered_date_from      => iv_ordered_date_from,        -- 2.�󒍓��iFrom�j
      iv_ordered_date_to        => iv_ordered_date_to,          -- 3.�󒍓��iTo�j
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
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
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
    --���ׂO�����̌x���I������
    IF ( g_rpt_data_tab.COUNT = 0 ) THEN
      ov_retcode := cv_status_warn;
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_ship_from_subinv_code  IN      VARCHAR2,       -- 1.�o�׌��q��
    iv_ordered_date_from      IN      VARCHAR2,       -- 2.�󒍓��iFrom�j
    iv_ordered_date_to        IN      VARCHAR2        -- 3.�󒍓��iTo�j
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
      iv_ship_from_subinv_code,          -- 1.�o�׌��q��
      iv_ordered_date_from,              -- 2.�󒍓��iFrom�j
      iv_ordered_date_to,                -- 3.�󒍓��iTo�j
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode <> cv_status_normal) THEN
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG,
        buff    => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
        which   => FND_FILE.LOG,
        buff    => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
      which   => FND_FILE.LOG,
      buff    => NULL
    );
    --�Ώی����o��
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_target_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_success_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_error_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => cv_skip_rec_msg,
                     iv_token_name1  => cv_cnt_token,
                     iv_token_value1 => TO_CHAR( gn_warn_cnt )
                   );
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
    --1�s��
    FND_FILE.PUT_LINE(
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
    gv_out_msg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name,
                     iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
      which   => FND_FILE.LOG,
      buff    => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF ( retcode = cv_status_error) THEN
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
END XXCOS006A04R;
/
