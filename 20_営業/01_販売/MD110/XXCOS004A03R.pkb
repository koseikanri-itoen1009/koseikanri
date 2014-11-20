CREATE OR REPLACE PACKAGE BODY APPS.XXCOS004A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS004A03R (body)
 * Description      : �����v�Z�`�F�b�N���X�g
 * MD.050           : �����v�Z�`�F�b�N���X�g MD050_COS_004_A03
 * Version          : 1.6
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
 *  2009/01/08    1.0   K.Kin            �V�K�쐬
 *  2009/02/04    1.1   K.Kin            [COS_011]������o�b�t�@�����������܂��s��Ή�
 *  2009/02/26    1.2   K.Kin            �폜�����̃R�����g�폜
 *  2009/06/19    1.3   K.Kiriu          [T1_1437]�f�[�^�p�[�W�s��Ή�
 *  2009/09/30    1.4   S.Miyakoshi      [0001378]���[���[�N�e�[�u���̌����ӂ�Ή�
 *  2010/02/23    1.5   K.Atsushiba      [E_�{�ғ�_01670]�ُ�|���Ή�
 *  2012/08/08    1.6   K.Onotsuka       [E_�{�ғ�_09900]���̓p�����[�^�y�і��׃\�[�g�����ǉ��Ή�
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
  global_proc_date_err_expt EXCEPTION;
  global_api_err_expt       EXCEPTION;
  global_call_api_expt      EXCEPTION;
  global_require_param_expt EXCEPTION;
  global_insert_data_expt   EXCEPTION;
  global_delete_data_expt   EXCEPTION;
  global_nodata_expt        EXCEPTION;
  global_get_profile_expt   EXCEPTION;
/* 2012/08/03 Ver1.6 Add Start */
  global_param_date_err_expt  EXCEPTION;
/* 2012/08/03 Ver1.6 Add End */
    --*** �����Ώۃf�[�^���b�N��O ***
  global_data_lock_expt       EXCEPTION;
--
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS004A03R'; -- �p�b�P�[�W��
  --���[�֘A
  cv_conc_name              CONSTANT VARCHAR2(100) := 'XXCOS004A03R';         -- �R���J�����g��
  cv_file_id                CONSTANT VARCHAR2(100) := 'XXCOS004A03R';         -- ���[�h�c
  cv_extension_pdf          CONSTANT VARCHAR2(100) := '.pdf';                 -- �g���q�i�o�c�e�j
  cv_frm_file               CONSTANT VARCHAR2(100) := 'XXCOS004A03S.xml';     -- �t�H�[���l���t�@�C����
  cv_vrq_file               CONSTANT VARCHAR2(100) := 'XXCOS004A03S.vrq';     -- �N�G���[�l���t�@�C����
  cv_output_mode_pdf        CONSTANT VARCHAR2(1)   := '1';                    -- �o�͋敪�i�o�c�e�j
  --�A�v���P�[�V�����Z�k��
  ct_xxcos_appl_short_name  CONSTANT fnd_application.application_short_name%TYPE
                                     := 'XXCOS';                    --�̕��Z�k�A�v����
  --�̕����b�Z�[�W
  ct_msg_lock_err           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00001';         --���b�N�擾�G���[���b�Z�[�W
  ct_msg_get_profile_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00004';         --�v���t�@�C���擾�G���[
  ct_msg_require_param_err  CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00006';         --�K�{���̓p�����[�^���ݒ�G���[
  ct_msg_insert_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00010';         --�f�[�^�o�^�G���[���b�Z�[�W
  ct_msg_delete_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00012';         --�f�[�^�폜�G���[���b�Z�[�W
  ct_msg_select_data_err    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00013';         --�f�[�^�擾�G���[���b�Z�[�W
  ct_msg_process_date_err   CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00014';         --�Ɩ����t�擾�G���[
  ct_msg_call_api_err       CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00017';         --API�ďo�G���[���b�Z�[�W
  ct_msg_nodata_err         CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00018';         --����0���p���b�Z�[�W
  ct_msg_svf_api            CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00041';         --�r�u�e�N���`�o�h
  ct_msg_request            CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00042';         --�v���h�c
  ct_msg_max_date           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00056';          --XXCOS:MAX���t
  ct_msg_profile_name       CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00043';         --�v���t�@�C��
  ct_msg_parameter          CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-11001';         --�p�����[�^�o�̓��b�Z�[�W
  ct_msg_no_add             CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-11002';         --���v�Z
  ct_msg_rpt_wrk_tbl        CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-11003';         --���[���[�N�e�[�u��
  ct_msg_name_err           CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-00055';         --���_�R�[�h
/* 2012/08/03 Ver1.6 Add Start */
  ct_msg_param_data_from    CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-11004';         --�N���iFROM�j
  ct_msg_param_data_to      CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-11005';         --�N���iTO�j
  ct_msg_param_data_err     CONSTANT fnd_new_messages.message_name%TYPE
                                     := 'APP-XXCOS1-11006';         --�N���t�]�G���[
/* 2012/08/03 Ver1.6 Add End */
  --�g�[�N��
  cv_tkn_table              CONSTANT VARCHAR2(100) := 'TABLE';                --�e�[�u��
  cv_tkn_profile            CONSTANT VARCHAR2(100) := 'PROFILE';              --�v���t�@�C��
  cv_tkn_table_name         CONSTANT VARCHAR2(100) := 'TABLE_NAME';           --�e�[�u������
  cv_tkn_key_data           CONSTANT VARCHAR2(100) := 'KEY_DATA';             --�L�[�f�[�^
  cv_tkn_api_name           CONSTANT VARCHAR2(100) := 'API_NAME';             --�`�o�h����
  cv_tkn_param1             CONSTANT VARCHAR2(100) := 'PARAM1';               --��P���̓p�����[�^
  cv_tkn_param2             CONSTANT VARCHAR2(100) := 'PARAM2';               --��Q���̓p�����[�^
/* 2012/08/03 Ver1.6 Add Start */
  cv_tkn_param3             CONSTANT VARCHAR2(100) := 'PARAM3';               --��R���̓p�����[�^
  cv_tkn_param4             CONSTANT VARCHAR2(100) := 'PARAM4';               --��S���̓p�����[�^
  cv_tkn_date_from          CONSTANT VARCHAR2(100) := 'DATE_FROM';            --���t�iFROM�j
  cv_tkn_date_to            CONSTANT VARCHAR2(100) := 'DATE_TO';              --���t�iTO�j
/* 2012/08/03 Ver1.6 Add End */
  cv_tkn_request            CONSTANT VARCHAR2(100) := 'REQUEST';              --�v���h�c
  cv_tkn_profile_name       CONSTANT VARCHAR2(100) := 'PROFILE_NAME';         --�v���t�@�C���l
  cv_tkn_in_param           CONSTANT VARCHAR2(100) := 'IN_PARAM';             --���̓p�����[�^
  --�v���t�@�C������
  ct_prof_org_id            CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'ORG_ID';
  ct_prof_max_date          CONSTANT fnd_profile_options.profile_option_name%TYPE
                                     := 'XXCOS1_MAX_DATE';
  --�N�C�b�N�R�[�h�^�C�v
  ct_sct_cust_type          CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_SHOP_UNCALCULATE_CLASS';  --�N�C�b�N�R�[�h�}�X�^.�^�C�v
  ct_qct_cust_type          CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS1_CUS_CLASS_MST_004_A03';
  ct_qcc_cust_type          CONSTANT fnd_lookup_types.lookup_type%TYPE
                                     := 'XXCOS_004_A03%';
  --�g�p�\�t���O�萔
  ct_enabled_flag_yes       CONSTANT fnd_lookup_values.enabled_flag%TYPE
                                     := 'Y';                              --�g�p�\
  --�X�܃w�b�_�p�t���O
  ct_make_flag_yes          CONSTANT xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE
                                     := 'Y';                              --�쐬�ς�
  ct_make_flag_no           CONSTANT xxcos_shop_digestion_hdrs.sales_result_creation_flag%TYPE
                                     := 'N';                              --���쐬
  --�t�H�[�}�b�g
  cv_fmt_date8              CONSTANT VARCHAR2(8)   := 'RRRRMMDD';
  cv_fmt_date               CONSTANT VARCHAR2(10)  := 'RRRR/MM/DD';
/* 2012/08/03 Ver1.6 Add Start */
  cv_fmt_date7              CONSTANT VARCHAR2(7)   := 'RRRR/MM';
/* 2012/08/03 Ver1.6 Add End */
  cv_fmt_tax                CONSTANT VARCHAR2(7)   := '990.00';
  --�p�[�Z���g�萔
  cv_pr_tax                 CONSTANT VARCHAR2(7)   := '%';
  --�ʒu
  cn_pos_star               CONSTANT NUMBER        := 1;
  --��������
  cn_base_name_length       CONSTANT NUMBER        := 40;
  cn_party_name_length      CONSTANT NUMBER        := 40;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���[���[�N�p�e�[�u���^��`
  TYPE g_rpt_data_ttype
  IS
    TABLE OF
      xxcos_rep_dig_list%ROWTYPE
    INDEX BY PLS_INTEGER
    ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --�p�����[�^
  gv_sales_base_code              VARCHAR2(100);                      -- ���_�R�[�h
  gv_customer_number              VARCHAR2(100);                      -- �ڋq�R�[�h
/* 2012/08/03 Ver1.6 Add Start */
  gd_yyyymm_from                  DATE;                               -- �N���iFrom�j
  gd_yyyymm_to                    DATE;                               -- �N���iTo�j
/* 2012/08/03 Ver1.6 Add End */
  --�����擾
  gd_process_date                 DATE;                               -- �Ɩ����t
  gd_max_date                     DATE;                               -- MAX���t
  gv_no_add                       VARCHAR2(100);                      -- ���v�Z
  --���[���[�N�����e�[�u��
  g_rpt_data_tab                  g_rpt_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    iv_sales_base_code        IN      VARCHAR2,                       -- ���_�R�[�h
    iv_customer_number        IN      VARCHAR2,                       -- �ڋq�R�[�h
/* 2012/08/03 Ver1.6 Add Start */
    iv_yyyymm_from            IN      VARCHAR2,                       -- �N���iFrom�j
    iv_yyyymm_to              IN      VARCHAR2,                       -- �N���iTo�j
/* 2012/08/03 Ver1.6 Add End */
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
    lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_parameter,
        iv_token_name1        => cv_tkn_param1,
        iv_token_value1       => iv_sales_base_code,
        iv_token_name2        => cv_tkn_param2,
        iv_token_value2       => iv_customer_number,
/* 2012/08/03 Ver1.6 Add Start */
        iv_token_name3        => cv_tkn_param3,
        iv_token_value3       => iv_yyyymm_from,
        iv_token_name4        => cv_tkn_param4,
        iv_token_value4       => iv_yyyymm_to
/* 2012/08/03 Ver1.6 Add End */
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
    gv_sales_base_code      := iv_sales_base_code;
    gv_customer_number      := iv_customer_number;
/* 2012/08/03 Ver1.6 Add Start */
    gd_yyyymm_from            := TO_DATE( iv_yyyymm_from, cv_fmt_date7 );
    gd_yyyymm_to              := TO_DATE( iv_yyyymm_to, cv_fmt_date7 );
/* 2012/08/03 Ver1.6 Add End */
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
/* 2012/08/03 Ver1.6 Add Start */
    lv_profile_name2 VARCHAR2(5000);
/* 2012/08/03 Ver1.6 Add End */
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
    IF  ( gd_process_date     IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    --==================================
    -- 2.XXCOS:MAX���t
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
    -- 3.���_�R�[�h�̕K�{�`�F�b�N
    --==================================
    IF ( gv_sales_base_code IS NULL ) THEN
      lv_profile_name         := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_name_err
                                 );
      RAISE global_require_param_expt;
    END IF;
--
    --==================================
    -- 4.���v�Z�擾
    --==================================
    gv_no_add                 := xxccp_common_pkg.get_msg(
                                   iv_application        => ct_xxcos_appl_short_name,
                                   iv_name               => ct_msg_no_add
                                 );
--
/* 2012/08/03 Ver1.6 Add Start */
    --==================================
    -- 5.�N����From��To�`�F�b�N
    --==================================
    IF ( gd_yyyymm_to IS NOT NULL ) THEN
      IF ( gd_yyyymm_from > gd_yyyymm_to ) THEN
        lv_profile_name       := xxccp_common_pkg.get_msg(
                                 iv_application        => ct_xxcos_appl_short_name,
                                 iv_name               => ct_msg_param_data_from
                                 );
        lv_profile_name2      := xxccp_common_pkg.get_msg(
                                 iv_application        => ct_xxcos_appl_short_name,
                                 iv_name               => ct_msg_param_data_to
                                 );
        RAISE global_param_date_err_expt;
      END IF;
    END IF;
--
/* 2012/08/03 Ver1.6 Add End */
  EXCEPTION
    -- *** �Ɩ����t�擾��O�n���h�� ***
    WHEN global_proc_date_err_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_process_date_err
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �v���t�@�C����O�n���h�� ***
    WHEN global_get_profile_expt    THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_get_profile_err,
        iv_token_name1        => cv_tkn_profile,
        iv_token_value1       => lv_profile_name
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** �K�{���̓p�����[�^���ݒ��O�n���h�� ***
    WHEN global_require_param_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
       iv_application        => ct_xxcos_appl_short_name,
       iv_name               => ct_msg_require_param_err,
       iv_token_name1        => cv_tkn_in_param,
       iv_token_value1       => lv_profile_name
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
/* 2012/08/03 Ver1.6 Add Start */
    -- *** ���t�p�����[�^�t�]��O�n���h�� ***
    WHEN global_param_date_err_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_param_data_err,
        iv_token_name1        => cv_tkn_date_from,
        iv_token_value1       => lv_profile_name,
        iv_token_name2        => cv_tkn_date_to,
        iv_token_value2       => lv_profile_name2
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
/* 2012/08/03 Ver1.6 Add End */
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
      SELECT xsdh.digestion_due_date              digestion_due_date,               --�����v�Z���N����
             xsdh.sales_base_code                 sales_base_code,                  --���㋒�_�R�[�h
             hpb.party_name                       sales_base_name,                  --���_����
             xsdh.customer_number                 customer_number,                  --�ڋq�R�[�h
             hpc.party_name                       party_name,                       --�ڋq����
             xsdh.ar_sales_amount                 ar_sales_amount,                  --�X�ܕʔ�����z
             xsdh.check_sales_amount              check_sales_amount,               --�`�F�b�N�p������z
             xsdh.digestion_calc_rate             digestion_calc_rate,              --�����v�Z�|��
             xsdh.master_rate                     master_rate,                      --�}�X�^�|��
             xsdh.uncalculate_class               uncalculate_class,                --���v�Z�敪
             flv.description                      confirmation_message              --�m�F���b�Z�[�W
      FROM   xxcos_shop_digestion_hdrs            xsdh,    -- �X�ܕʗp�����v�Z�w�b�_�e�[�u��
             hz_cust_accounts                     hcaeb,   --�ڋq�}�X�^_���_
             hz_parties                           hpb,     --�p�[�e�B�}�X�^_���_
             hz_cust_accounts                     hcaec,   --�ڋq�}�X�^_�ڋq
             hz_parties                           hpc,     --�p�[�e�B�}�X�^_�ڋq
             fnd_application                      fa,      --�A�v���P�[�V�����}�X�^
             fnd_lookup_types                     flt,     --�N�C�b�N�R�[�h�^�C�v�}�X�^
             fnd_lookup_values                    flv      --�N�C�b�N�R�[�h�l�}�X�^
      WHERE  xsdh.sales_base_code                 = hcaeb.account_number
      AND    hcaeb.party_id                       = hpb.party_id
      AND    EXISTS (SELECT flv.meaning meaning
                     FROM   fnd_application               fa,
                            fnd_lookup_types              flt,
                            fnd_lookup_values             flv
                     WHERE  fa.application_id                             = flt.application_id
                     AND    flt.lookup_type                               = flv.lookup_type
                     AND    fa.application_short_name                     = ct_xxcos_appl_short_name
                     AND    flv.lookup_type                               = ct_qct_cust_type
                     AND    flv.lookup_code                               LIKE ct_qcc_cust_type
                     AND    flv.start_date_active                         <= xsdh.digestion_due_date
                     AND    NVL( flv.end_date_active, gd_max_date )       >= xsdh.digestion_due_date
                     AND    flv.enabled_flag                              = ct_enabled_flag_yes
                     AND    flv.language                                  = USERENV( 'LANG' )
                     AND    flv.meaning                                   = hcaeb.customer_class_code
                    ) --�ڋq�}�X�^.�ڋq�敪 = 1(���_)
      AND    xsdh.cust_account_id                          = hcaec.cust_account_id
      AND    hcaec.party_id                                = hpc.party_id
      AND    fa.application_id                             = flt.application_id
      AND    flt.lookup_type                               = flv.lookup_type
      AND    fa.application_short_name                     = ct_xxcos_appl_short_name
      AND    flv.lookup_type                               = ct_sct_cust_type
      AND    flv.lookup_code                               = xsdh.uncalculate_class
      AND    flv.start_date_active                         <= xsdh.digestion_due_date
      AND    NVL( flv.end_date_active, gd_max_date )       >= xsdh.digestion_due_date
      AND    flv.language                                  = USERENV( 'LANG' )
      AND    flv.enabled_flag                              = ct_enabled_flag_yes
      AND    xsdh.sales_result_creation_flag               = ct_make_flag_no
      AND    xsdh.sales_base_code IN(
                    SELECT
                      gv_sales_base_code sales_base_code
                    FROM
                      DUAL
                    UNION
                    SELECT hcae.account_number account_number      --���_�R�[�h
                    FROM   hz_cust_accounts    hcae,
                           xxcmm_cust_accounts xcae
                    WHERE  hcae.cust_account_id = xcae.customer_id --�ڋq�}�X�^.�ڋqID =�ڋq�A�h�I��.�ڋqID
                    AND    EXISTS (SELECT flv.meaning
                                    FROM   fnd_application               fa,
                                           fnd_lookup_types              flt,
                                           fnd_lookup_values             flv
                                    WHERE  fa.application_id                             = flt.application_id
                                    AND    flt.lookup_type                               = flv.lookup_type
                                    AND    fa.application_short_name                     = ct_xxcos_appl_short_name
                                    AND    flv.lookup_type                               = ct_qct_cust_type
                                    AND    flv.lookup_code                               LIKE ct_qcc_cust_type
                                    AND    flv.start_date_active                         <= xsdh.digestion_due_date
                                    AND    NVL( flv.end_date_active, gd_max_date )       >= xsdh.digestion_due_date
                                    AND    flv.enabled_flag                              = ct_enabled_flag_yes
                                    AND    flv.language                                  = USERENV( 'LANG' )
                                    AND    flv.meaning                                   = hcae.customer_class_code
                                   ) --�ڋq�}�X�^.�ڋq�敪 = 1(���_)
                    AND    xcae.management_base_code = gv_sales_base_code
                                     --�ڋq�ڋq�A�h�I��.�Ǘ������_�R�[�h = IN�p�����_�R�[�h
             )--�X�ܕʗp�����v�Z�w�b�_�e�[�u��.���㋒�_�R�[�h IN
      AND     xsdh.customer_number = NVL( gv_customer_number, xsdh.customer_number )
/* 2012/08/03 Ver1.6 Add Start */
      AND    xsdh.digestion_due_date                       >= TRUNC( gd_yyyymm_from )
      AND    xsdh.digestion_due_date                       <= LAST_DAY( NVL( gd_yyyymm_to, gd_process_date ) );
/* 2012/08/03 Ver1.6 Add End */
--
    -- *** ���[�J���E���R�[�h ***
    l_data_rec                          data_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ln_idx      := 0;
--
    --==================================
    -- 1.�f�[�^�擾
    --==================================
    <<loop_get_data>>
    FOR l_data_rec     IN  data_cur
    LOOP
      -- ���R�[�hID�̎擾
      BEGIN
        SELECT
             xxcos_rep_dig_list_s01.nextval        record_id
        INTO
            ln_record_id
        FROM
            dual
        ;
      END;
      ln_idx                  := ln_idx + 1;
      --
      g_rpt_data_tab(ln_idx).record_id                    := ln_record_id;                     --���R�[�hid
      g_rpt_data_tab(ln_idx).digestion_date               := l_data_rec.digestion_due_date;    --�����v�Z���N����
      g_rpt_data_tab(ln_idx).base_code                    := l_data_rec.sales_base_code;       --���㋒�_�R�[�h
      g_rpt_data_tab(ln_idx).base_name                    := SUBSTRB( l_data_rec.sales_base_name, 
                                                          cn_pos_star, cn_base_name_length );  --���㋒�_����
      g_rpt_data_tab(ln_idx).party_num                    := l_data_rec.customer_number;       --�ڋq�R�[�h
      g_rpt_data_tab(ln_idx).customer_name                := SUBSTRB( l_data_rec.party_name,
                                                          cn_pos_star, cn_party_name_length ); --�ڋq����
      g_rpt_data_tab(ln_idx).shop_sale_amount             := l_data_rec.ar_sales_amount;       --�X�ܕʔ�����z
      g_rpt_data_tab(ln_idx).digest_sale_amount           := l_data_rec.check_sales_amount;    --�`�F�b�N�p������z
-- ************************ 2010/02/23 K.Aatsushiba Var1.5 MOD START ************************ --
      IF  ( l_data_rec.uncalculate_class IN ('0','4' )) THEN
--      IF  ( l_data_rec.uncalculate_class = 0 ) THEN
-- ************************ 2010/02/23 K.Aatsushiba Var1.5 MOD END ************************ --
-- ************************ 2009/09/30 S.Miyakoshi Var1.4 MOD START ************************ --
--            g_rpt_data_tab(ln_idx).account_rate           := TO_CHAR( l_data_rec.digestion_calc_rate, cv_fmt_tax )
--                                                          || cv_pr_tax;
            g_rpt_data_tab(ln_idx).account_rate           := SUBSTRB( TO_CHAR( l_data_rec.digestion_calc_rate, cv_fmt_tax )
                                                          || cv_pr_tax, 1, 8 );
-- ************************ 2009/09/30 S.Miyakoshi Var1.4 MOD  END  ************************ --
      ELSE
            g_rpt_data_tab(ln_idx).account_rate           := gv_no_add;                         --�����v�Z�|��
      END IF;
-- ************************ 2009/09/30 S.Miyakoshi Var1.4 MOD START ************************ --
--      g_rpt_data_tab(ln_idx).setting_account_rate         := TO_CHAR( l_data_rec.master_rate, cv_fmt_tax )
--                                                          || cv_pr_tax;
      g_rpt_data_tab(ln_idx).setting_account_rate         := SUBSTRB( TO_CHAR( l_data_rec.master_rate, cv_fmt_tax )
                                                          || cv_pr_tax, 1, 8 );                --�}�X�^�|��
-- ************************ 2009/09/30 S.Miyakoshi Var1.4 MOD  END  ************************ --
      g_rpt_data_tab(ln_idx).uncalculate_class            := l_data_rec.uncalculate_class;     --���v�Z�敪
      IF  ( l_data_rec.uncalculate_class <> 0 ) THEN
-- ************************ 2009/09/30 S.Miyakoshi Var1.4 MOD START ************************ --
--            g_rpt_data_tab(ln_idx).confirmation_message   := l_data_rec.confirmation_message;  --�m�F���b�Z�[�W
            g_rpt_data_tab(ln_idx).confirmation_message   := SUBSTRB( l_data_rec.confirmation_message, 1, 40 );  --�m�F���b�Z�[�W
-- ************************ 2009/09/30 S.Miyakoshi Var1.4 MOD  END  ************************ --
      END IF;
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
    IF  ( g_rpt_data_tab.COUNT  =  0  ) THEN
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
    -- 1.�����v�Z�`�F�b�N���X�g���[���[�N�e�[�u���o�^����
    --==================================
    <<loop_insert_rpt_wrk_data>>
    BEGIN
      FORALL i IN 1..g_rpt_data_tab.COUNT --SAVE EXCEPTIONS
      INSERT INTO
        xxcos_rep_dig_list
      VALUES
        g_rpt_data_tab(i)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    -- ���팏��
    gn_normal_cnt           := g_rpt_data_tab.COUNT;
--
  EXCEPTION
    WHEN global_insert_data_expt  THEN
      --�e�[�u�����擾
      lv_table_name         := xxccp_common_pkg.get_msg(
                                  iv_application        => ct_xxcos_appl_short_name,
                                  iv_name               => ct_msg_rpt_wrk_tbl
                                );
      --
      ov_errmsg             := xxccp_common_pkg.get_msg(
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
    IF  ( lv_retcode  <> cv_status_normal ) THEN
      RAISE global_call_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_call_api_expt  THEN
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
    lv_profile_name  VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR lock_cur
    IS
      SELECT
        xrdr.record_id        record_id
      FROM
        xxcos_rep_dig_list    xrdr                    --�����v�Z�`�F�b�N���X�g���[�N�e�[�u��
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
          xxcos_rep_dig_list  xrdr
      WHERE
          xrdr.request_id     =   cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --�v��ID������擾
        lv_profile_name           := xxccp_common_pkg.get_msg(
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
                                   iv_application         => ct_xxcos_appl_short_name,
                                   iv_name                => ct_msg_rpt_wrk_tbl
                                 );
      --
      ov_errmsg               := xxccp_common_pkg.get_msg(
                                    iv_application        => ct_xxcos_appl_short_name,
                                    iv_name               => ct_msg_delete_data_err,
                                    iv_token_name1        => cv_tkn_table_name,
                                    iv_token_value1       => lv_table_name,
                                    iv_token_name2        => cv_tkn_key_data,
                                    iv_token_value2       => lv_profile_name
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
    iv_sales_base_code      IN      VARCHAR2,       -- 1.���_
    iv_customer_number      IN      VARCHAR2,       -- 2.�ڋq�R�[�h
/* 2012/08/03 Ver1.6 Add Start */
    iv_yyyymm_from          IN      VARCHAR2,       -- 3.�N���iFrom�j
    iv_yyyymm_to            IN      VARCHAR2,       -- 4.�N���iTo�j
/* 2012/08/03 Ver1.6 Add End */
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
/* 2009/06/19 Ver1.3 Add Start */
    lv_errbuf_svf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
    lv_retcode_svf VARCHAR2(1);     -- ���^�[���E�R�[�h(SVF���s���ʕێ��p)
    lv_errmsg_svf  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W(SVF���s���ʕێ��p)
/* 2009/06/19 Ver1.3 Add End   */

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
      iv_sales_base_code        => iv_sales_base_code,         -- 1.���_
      iv_customer_number        => iv_customer_number,         -- 2.�ڋq�R�[�h
/* 2012/08/03 Ver1.6 Add Start */
      iv_yyyymm_from            => iv_yyyymm_from,             -- 3.�N���iFrom�j
      iv_yyyymm_to              => iv_yyyymm_to,               -- 4.�N���iTo�j
/* 2012/08/03 Ver1.6 Add End */
      ov_errbuf                 => lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode                => lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg                 => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF  ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-1  �p�����[�^�`�F�b�N����
    -- ===============================
    check_parameter(
      ov_errbuf                 => lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode                => lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg                 => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF  ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2  �f�[�^�擾
    -- ===============================
    get_data(
      ov_errbuf               => lv_errbuf,                -- �G���[�E���b�Z�[�W
      ov_retcode              => lv_retcode,               -- ���^�[���E�R�[�h
      ov_errmsg               => lv_errmsg                 -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF  ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  ���[���[�N�e�[�u���o�^
    -- ===============================
    insert_rpt_wrk_data(
      ov_errbuf               => lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode              => lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF  ( lv_retcode = cv_status_normal ) THEN
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
      ov_errbuf               => lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode              => lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
--
/* 2009/06/19 Ver1.3 Mod Start */
--    IF  ( lv_retcode = cv_status_normal ) THEN
--      NULL;
--    ELSE
--      RAISE global_process_expt;
--    END IF;
    --�G���[�ł����[�N�e�[�u�����폜����ׁA�G���[����ێ�
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
/* 2009/06/19 Ver1.3 Mod End   */
--
    -- ===============================
    -- A-3  ���[���[�N�e�[�u���폜
    -- ===============================
    delete_rpt_wrk_data(
      ov_errbuf               => lv_errbuf,                  -- �G���[�E���b�Z�[�W
      ov_retcode              => lv_retcode,                 -- ���^�[���E�R�[�h
      ov_errmsg               => lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W
      );
    IF  ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
/* 2009/06/19 Ver1.3 Add Start */
    COMMIT;
--
    --SVF���s���ʊm�F
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
/* 2009/06/19 Ver1.3 Add Start */
--
    --���ׂO�����̌x���I������
    IF ( g_rpt_data_tab.COUNT   =   0 )   THEN
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
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_sales_base_code      IN      VARCHAR2,       -- 1.���_
    iv_customer_number      IN      VARCHAR2,       -- 2.�ڋq�R�[�h
/* 2012/08/03 Ver1.6 Add Start */
    iv_yyyymm_from          IN      VARCHAR2,       -- 3.�N���iFrom�j
    iv_yyyymm_to            IN      VARCHAR2        -- 4.�N���iTo�j
/* 2012/08/03 Ver1.6 Add End */
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';  -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F�o��
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';     -- �R���J�����g�w�b�_���b�Z�[�W�o�͐�F���O(���[�̂�)
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
      iv_sales_base_code,                -- 1.���_
      iv_customer_number,                -- 2�D�ڋq�R�[�h
/* 2012/08/03 Ver1.6 Add Start */
      iv_yyyymm_from,                    -- 3.�N���iFrom�j
      iv_yyyymm_to,                      -- 4.�N���iTo�j
/* 2012/08/03 Ver1.6 Add End */
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
      which => FND_FILE.LOG,
      buff  => gv_out_msg
    );
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
                     iv_application  => cv_appl_short_name,
                     iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG,
       buff   => gv_out_msg
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
END XXCOS004A03R;
/
