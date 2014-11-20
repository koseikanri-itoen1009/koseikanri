create or replace PACKAGE BODY XXCOS014A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A10C(spec)
 * Description      : �a���VD�[�i�`�[�f�[�^�쐬
 * MD.050           : �a���VD�[�i�`�[�f�[�^�쐬 (MD050_COS_014_A10)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  create_header          �w�b�_���R�[�h�쐬����(A-2)
 *  get_data               �f�[�^�擾����(A-3)
 *  out_csv_header         CSV�w�b�_���R�[�h�쐬����(A-4)
 *  out_csv_data           �f�[�^���R�[�h�쐬����(A-5)
 *  out_csv_footer         �t�b�^���R�[�h�쐬����(A-6)
 *  delete_work_tbl        ���[�N�e�[�u���폜����(A-8)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/03/06    1.0   S.Nakanishi      �V�K�쐬
 *  2009/03/19    1.1   S.Nakanishi      ��QNo.159�Ή�
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
  ct_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  ct_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  resource_busy_expt      EXCEPTION;                                          --���b�N�G���[
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
  --
  delete_tbl_expt         EXCEPTION;                                          --�e�[�u���폜�G���[
  --
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOS014A10C';                  --�p�b�P�[�W��
--
  cv_apl_name      CONSTANT VARCHAR2(100) := 'XXCOS';                         --�A�v���P�[�V������
--
  --�v���t�@�C��
  ct_prf_if_header          CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_HEADER';           --XXCCP:�w�b�_���R�[�h���ʎq
  ct_prf_if_data            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_DATA';             --XXCCP:�f�[�^���R�[�h���ʎq
  ct_prf_if_footer          CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_FOOTER';           --XXCCP:�t�b�^���R�[�h���ʎq
  ct_prf_rep_outbound_dir   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_REP_OUTBOUND_DIR_OM'; --XXCOS:���[OUTBOUND�o�̓f�B���N�g��(EBS�݌ɊǗ�)
  ct_prf_utl_max_linesize   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_UTL_MAX_LINESIZE';    --XXCOS:UTL_MAX�s�T�C�Y
  --
  --���b�Z�[�W
  ct_msg_fopen_err          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00009';         --�t�@�C���I�[�v���G���[���b�Z�[�W
  ct_msg_if_header          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00094';         --XXCCP:�w�b�_���R�[�h���ʎq
  ct_msg_if_footer          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00096';         --XXCCP:�t�b�^���R�[�h���ʎq
  ct_msg_rep_outbound_dir   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00112';         --XXCOS:���[OUTBOUND�o�̓f�B���N�g��
  ct_msg_utl_max_linesize   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00099';         --XXCOS:UTL_MAX�s�T�C�Y
  ct_msg_delete_data        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012';         --�f�[�^�폜�G���[
  cv_msg_nodata             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';         --�Ώۃf�[�^�Ȃ����b�Z�[�W
  ct_msg_get_err            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064';         --�擾�G���[
  ct_msg_prf                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';         --�v���t�@�C���擾�G���[
  ct_msg_input_parameters1  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13651';         --�p�����[�^�o�̓��b�Z�[�W1
  ct_msg_input_parameters2  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13652';         --�p�����[�^�o�̓��b�Z�[�W2
  ct_msg_file_name          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00130';         --�t�@�C�����o�̓��b�Z�[�W
  ct_msg_work_tab_name      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13653';         --������.�a���VD�[�i�`�[���[�N�e�[�u��
  ct_msg_group_id           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13654';         --������.�O���[�vID
  ct_msg_if_data            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00095';         --XXCCP:�f�[�^���R�[�h���ʎq
  ct_msg_resource_busy_err  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';         --���b�N�G���[���b�Z�[�W
--
  --�g�[�N��
  cv_tkn_filename           CONSTANT VARCHAR2(100) := 'FILE_NAME';            --�t�@�C����
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE_NAME';           --�e�[�u����
  cv_tkn_table2             CONSTANT VARCHAR2(20)  := 'TABLE';                --�e�[�u��
  cv_key_data               CONSTANT VARCHAR2(20)  := 'KEY_DATA';             --�ҏW���ꂽ�L�[���
  cv_tkn_prm1               CONSTANT VARCHAR2(6)   := 'PARAM1';               --���̓p�����[�^1
  cv_tkn_prm2               CONSTANT VARCHAR2(6)   := 'PARAM2';               --���̓p�����[�^2
  cv_tkn_prm3               CONSTANT VARCHAR2(6)   := 'PARAM3';               --���̓p�����[�^3
  cv_tkn_prm4               CONSTANT VARCHAR2(6)   := 'PARAM4';               --���̓p�����[�^4
  cv_tkn_prm5               CONSTANT VARCHAR2(6)   := 'PARAM5';               --���̓p�����[�^5
  cv_tkn_prm6               CONSTANT VARCHAR2(6)   := 'PARAM6';               --���̓p�����[�^6
  cv_tkn_prm7               CONSTANT VARCHAR2(6)   := 'PARAM7';               --���̓p�����[�^7
  cv_tkn_prm8               CONSTANT VARCHAR2(6)   := 'PARAM8';               --���̓p�����[�^8
  cv_tkn_prm9               CONSTANT VARCHAR2(6)   := 'PARAM9';               --���̓p�����[�^9
  cv_tkn_prm10              CONSTANT VARCHAR2(7)   := 'PARAM10';              --���̓p�����[�^10
  cv_tkn_prm11              CONSTANT VARCHAR2(7)   := 'PARAM11';              --���̓p�����[�^11
  cv_tkn_prf                CONSTANT VARCHAR2(7)   := 'PROFILE';              --�v���t�@�C��
  cv_tkn_key                CONSTANT VARCHAR2(8)   := 'KEY_DATA';             --�L�[���
--
  --���̑�
       cv_utl_file_mode     CONSTANT VARCHAR2(1)  := 'w';                     --UTL_FILE.�I�[�v�����[�h
       cv_date_fmt          CONSTANT VARCHAR2(8)  := 'YYYYMMDD';              --���t����
       cv_time_fmt          CONSTANT VARCHAR2(8)  := 'HH24MISS';              --����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  --���̓p�����[�^�i�[���R�[�h
  TYPE g_input_rtype IS RECORD (
    user_id                  NUMBER                                           --���[�UID
   ,chain_code               xxcmm_cust_accounts.edi_chain_code%TYPE          --EDI�`�F�[���X�R�[�h
   ,base_code                xxcmm_cust_accounts.delivery_base_code%TYPE      --���_�R�[�h
   ,base_name                hz_parties.party_name%TYPE                       --���_��
   ,chain_name               hz_parties.party_name%TYPE                       --�`�F�[���X��
   ,report_code              xxcos_report_forms_register.report_code%TYPE     --���[�R�[�h
   ,report_mode              xxcos_report_forms_register.report_name%TYPE     --���[�l��
   ,ebs_business_series_code VARCHAR2(100)                                    --�Ɩ��n��R�[�h
   ,file_name                VARCHAR2(100)                                    --�t�@�C����
   ,report_type_code         xxcos_report_forms_register.data_type_code%TYPE  --���[��ʃR�[�h
   ,rep_group_id             NUMBER                                           --�O���[�vID
    );
--
  --�v���t�@�C���l�i�[���R�[�h
    TYPE g_prf_rtype IS RECORD (
    if_header                fnd_profile_option_values.profile_option_value%TYPE   --�w�b�_���R�[�h���ʎq
   ,if_data                  fnd_profile_option_values.profile_option_value%TYPE   --�f�[�^���R�[�h���ʎq
   ,if_footer                fnd_profile_option_values.profile_option_value%TYPE   --�t�b�^���R�[�h���ʎq
   ,rep_outbound_dir         fnd_profile_option_values.profile_option_value%TYPE   --�o�̓f�B���N�g��
   ,utl_max_linesize         fnd_profile_option_values.profile_option_value%TYPE   --UTL_FILE�ő�s�T�C�Y
   );
--
  --���̑����i�[���R�[�h
  TYPE g_other_rtype IS RECORD (
    proc_date                VARCHAR2(8)                                      --������
   ,proc_time                VARCHAR2(6)                                      --��������
   ,organization_id          NUMBER                                           --�݌ɑg�DID
   ,csv_header               VARCHAR2(32767)                                  --CSV�w�b�_
   ,process_date             DATE                                             --�Ɩ����t
  );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  g_input_rec                g_input_rtype;                                   --���̓p�����[�^���
  gf_file_handle             UTL_FILE.FILE_TYPE;                              --�t�@�C���n���h��
  g_prf_rec                  g_prf_rtype;                                     --�v���t�@�C�����
  g_record_layout_tab        xxcos_common2_pkg.g_record_layout_ttype;         --���C�A�E�g��`���
  g_other_rec                g_other_rtype;                                   --���̑����
  gb_delete                  boolean := TRUE;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_siege                   CONSTANT VARCHAR2(1)   := CHR(34);                                  --�_�u���N�H�[�e�[�V����
  cv_file_format             CONSTANT VARCHAR2(1)   := xxcos_common2_pkg.gv_file_type_variable;  --�݌�
  cv_layout_class            CONSTANT VARCHAR2(1)   := xxcos_common2_pkg.gv_layout_class_order;  --���C�A�E�g�敪
  cv_delimiter               CONSTANT VARCHAR2(1)   := CHR(44);                                  --�J���}
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
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
    lb_error                                 BOOLEAN;                                      --�G���[�L��t���O
    lt_tkn                                   fnd_new_messages.message_text%TYPE;           --���b�Z�[�W�p������
--
    -- *** ���[�J���E�J�[�\�� ***
--
    lv_errbuf_all                            VARCHAR2(32767);                              --���O�o�̓��b�Z�[�W�i�[�ϐ�

    -- *** ���[�J���E���R�[�h ***
--
    l_prf_rec g_prf_rtype;
    l_other_rec g_other_rtype;
    l_record_layout_tab xxcos_common2_pkg.g_record_layout_ttype;
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
    --�󔒍s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --==============================================================
    -- �R���J�����g�v���O�������͍��ڂ̏o��
    --==============================================================
--
    --���̓p�����[�^1010�̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_input_parameters1
                                          ,cv_tkn_prm1 , g_input_rec.file_name                --�t�@�C����
                                          ,cv_tkn_prm2 , g_input_rec.chain_code               --EDI�`�F�[���X�R�[�h
                                          ,cv_tkn_prm3 , g_input_rec.report_code              --���[�R�[�h
                                          ,cv_tkn_prm4 , g_input_rec.user_id                  --���[�UID
                                          ,cv_tkn_prm5 , g_input_rec.base_code                --���_�R�[�h
                                          ,cv_tkn_prm6 , g_input_rec.base_name                --���_��
                                          ,cv_tkn_prm7 , g_input_rec.chain_name               --�`�F�[���X��
                                          ,cv_tkn_prm8 , g_input_rec.report_type_code         --���[��ʃR�[�h
                                          ,cv_tkn_prm9 , g_input_rec.ebs_business_series_code --�Ɩ��n��R�[�h
                                          ,cv_tkn_prm10, g_input_rec.report_mode              --���[�l��
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --���̓p�����[�^11�̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_input_parameters2
                                          ,cv_tkn_prm11, g_input_rec.rep_group_id                  --�O���[�vID
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�󔒍s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --==============================================================
    -- �o�̓t�@�C�����̏o��
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                    cv_apl_name
                   ,ct_msg_file_name
                   ,cv_tkn_filename
                   ,g_input_rec.file_name
                  );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�󔒍s�̏o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --==============================================================
    -- 3.1�v���t�@�C���̎擾(XXCCP:�w�b�_���R�[�h���ʎq)
    --==============================================================
    l_prf_rec.if_header := FND_PROFILE.VALUE(ct_prf_if_header);
    IF (l_prf_rec.if_header IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_header);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
    END IF;
--
    --==============================================================
    -- 3.2�v���t�@�C���̎擾(XXCCP:�f�[�^���R�[�h���ʎq)
    --==============================================================
    l_prf_rec.if_data := FND_PROFILE.VALUE(ct_prf_if_data);
    IF (l_prf_rec.if_data IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_data);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
    END IF;
--
    --==============================================================
    -- 3.3�v���t�@�C���̎擾(XXCCP:�t�b�^���R�[�h���ʎq)
    --==============================================================
    l_prf_rec.if_footer := FND_PROFILE.VALUE(ct_prf_if_footer);
    IF (l_prf_rec.if_footer IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_footer);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
    END IF;
--
    --==============================================================
    -- 3.4�v���t�@�C���̎擾(XXCOS:���[OUTBOUND�o�̓f�B���N�g��)
    --==============================================================
    l_prf_rec.rep_outbound_dir := FND_PROFILE.VALUE(ct_prf_rep_outbound_dir);
    IF (l_prf_rec.rep_outbound_dir IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_rep_outbound_dir);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
    END IF;
--
    --==============================================================
    -- 3.5 �v���t�@�C���̎擾(XXCOS:UTL_MAX�s�T�C�Y)
    --==============================================================
    l_prf_rec.utl_max_linesize := FND_PROFILE.VALUE(ct_prf_utl_max_linesize);
    IF (l_prf_rec.utl_max_linesize IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_utl_max_linesize);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
    END IF;
    --==============================================================
    --4.���C�A�E�g��`���̎擾
    --==============================================================
    xxcos_common2_pkg.get_layout_info(
      cv_file_format                              --�t�@�C���`��
     ,cv_layout_class                             --���C�A�E�g�敪
     ,l_record_layout_tab                         --���C�A�E�g��`���
     ,l_other_rec.csv_header                      --CSV�w�b�_
     ,lv_errbuf                                   --�G���[���b�Z�[�W
     ,lv_retcode                                  --���^�[���R�[�h
     ,lv_errmsg                                   --���[�U�E�G���[���b�Z�[�W
    );
    IF (lv_retcode != cv_status_normal) THEN
      lb_error := TRUE;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
    END IF;
--
    IF (lb_error) THEN
      lv_errmsg := NULL;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --5.���������擾
    --==============================================================
    l_other_rec.proc_date := TO_CHAR(SYSDATE, cv_date_fmt);
    l_other_rec.proc_time := TO_CHAR(SYSDATE, cv_time_fmt);
    l_other_rec.process_date := TRUNC(xxccp_common_pkg2.get_process_date);
--
    --==============================================================
    --�O���[�o���ϐ��̃Z�b�g
    --==============================================================
    g_prf_rec := l_prf_rec;
    g_other_rec := l_other_rec;
    g_record_layout_tab := l_record_layout_tab;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf_all,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : create_header
   * Description      : �w�b�_���R�[�h�쐬����(A-2)
   ***********************************************************************************/
  PROCEDURE create_header(
    ov_errbuf     OUT VARCHAR2,     --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_header'; -- �v���O������
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
    lv_if_header VARCHAR2(32767);
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
    -- �t�@�C���I�[�v��
    --==============================================================
    BEGIN
      gf_file_handle := UTL_FILE.FOPEN(
                          g_prf_rec.rep_outbound_dir
                         ,g_input_rec.file_name
                         ,cv_utl_file_mode
                         ,g_prf_rec.utl_max_linesize
                        );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_fopen_err
                      ,cv_tkn_filename
                      ,g_input_rec.file_name
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- �w�b�_���R�[�h�ݒ�l�擾
    --==============================================================
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      g_prf_rec.if_header                      --�t�^�敪
     ,g_input_rec.ebs_business_series_code             --�h�e���Ɩ��n��R�[�h
     ,g_input_rec.base_code                            --���_�R�[�h
     ,g_input_rec.base_name                            --���_����
     ,g_input_rec.chain_code                           --�`�F�[���X�R�[�h
     ,g_input_rec.chain_name                           --�`�F�[���X����
     ,g_input_rec.report_type_code                     --�f�[�^��R�[�h
     ,g_input_rec.report_code                          --���[�R�[�h
     ,g_input_rec.report_mode                          --���[�\����
     ,g_record_layout_tab.COUNT                        --���ڐ�
     ,NULL                                             --�f�[�^����
     ,lv_retcode                                       --���^�[���R�[�h
     ,lv_if_header                                     --�o�͒l
     ,lv_errbuf                                        --�G���[���b�Z�[�W
     ,lv_errmsg                                        --���[�U�[�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- �w�b�_���R�[�h�o��
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle,lv_if_header);
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END create_header;
--
  /**********************************************************************************
   * Procedure Name   : out_csv_header
   * Description      : CSV�w�b�_���R�[�h�쐬����(A-4)
   ***********************************************************************************/
  PROCEDURE out_csv_header(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_header'; -- �v���O������
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
   lv_csv_header VARCHAR2(32767);
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
    --CSV�w�b�_���R�[�h�̐擪�Ƀf�[�^���R�[�h���ʎq��t��
    lv_csv_header := cv_siege || g_prf_rec.if_data || cv_siege || cv_delimiter ||
                     g_other_rec.csv_header;
--
    --CSV�w�b�_���R�[�h�̏o��
    UTL_FILE.PUT_LINE(gf_file_handle, g_other_rec.csv_header);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_csv_header;
--
  /**********************************************************************************
   * Procedure Name   : out_csv_data
   * Description      : �f�[�^���R�[�h�쐬����(A-5)
   ***********************************************************************************/
  PROCEDURE out_csv_data(
    i_data_tab    IN  xxcos_common2_pkg.g_layout_ttype
   ,ov_errbuf     OUT NOCOPY VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_data'; -- �v���O������
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
    lv_data_record         VARCHAR2(32767);
    lv_key_info            VARCHAR2(100);
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
    --==============================================================
    --�f�[�^���R�[�h�ҏW
    --==============================================================
--
    xxcos_common2_pkg.makeup_data_record(
      i_data_tab                --�o�̓f�[�^���
     ,cv_file_format            --�t�@�C���`��
     ,g_record_layout_tab       --���C�A�E�g��`���
     ,g_prf_rec.if_data         --�f�[�^���R�[�h���ʎq
     ,lv_data_record            --�f�[�^���R�[�h
     ,lv_errbuf                 --�G���[���b�Z�[�W
     ,lv_retcode                --���^�[���R�[�h
     ,lv_errmsg                 --���[�U�E�G���[���b�Z�[�W
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�f�[�^���R�[�h�o��
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle,lv_data_record);
--
    --==============================================================
    --���R�[�h�����C���N�������g
    --==============================================================
    gn_target_cnt := gn_target_cnt + 1;
    gn_normal_cnt := gn_normal_cnt + 1;
--
  END out_csv_data;
  /**********************************************************************************
   * Procedure Name   : out_csv_footer
   * Description      : �t�b�^���R�[�h�쐬����(A-6)
   ***********************************************************************************/
  PROCEDURE out_csv_footer(
    ov_errbuf     OUT NOCOPY VARCHAR2     --�G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv_footer'; -- �v���O������
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
    lv_footer_record VARCHAR2(32767);
    ln_target_cnt    NUMBER;
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
    IF gn_target_cnt > 0 THEN
      ln_target_cnt := gn_target_cnt + 1;--�Ώۃf�[�^����+CSV�w�b�_���R�[�h��1��
    ELSE
      ln_target_cnt := 0;
    END IF;
--
    --==============================================================
    --�t�b�^���R�[�h�擾
    --==============================================================
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      g_prf_rec.if_footer         --�t�^�敪
     ,NULL                        --IF���Ɩ��n��R�[�h
     ,NULL                        --���_�R�[�h
     ,NULL                        --���_����
     ,NULL                        --�`�F�[���X�R�[�h
     ,NULL                        --�`�F�[���X����
     ,NULL                        --�f�[�^��R�[�h
     ,NULL                        --���[�R�[�h
     ,NULL                        --���[�\����
     ,NULL                        --���ڐ�
     ,ln_target_cnt               --���R�[�h����(+ CSV�w�b�_���R�[�h)
     ,lv_retcode                  --���^�[���R�[�h
     ,lv_footer_record            --�o�͒l
     ,lv_errbuf
     ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --�t�b�^���R�[�h�o��
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle, lv_footer_record);
--
    --==============================================================
    --�t�@�C���N���[�Y
    --==============================================================
    UTL_FILE.FCLOSE(gf_file_handle);
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END out_csv_footer;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_tbl
   * Description      : ���[�N�e�[�u���폜����(A-8)
   ***********************************************************************************/
  PROCEDURE delete_work_tbl(
    iv_group_id    IN  NUMBER  ,      --�O���[�vID
    ov_errbuf     OUT VARCHAR2,       --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,       --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)       --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_work_tbl'; -- �v���O������
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
    lv_key_info            VARCHAR2(100);
    lv_table_name          VARCHAR2(30);
    lt_tkn                 fnd_new_messages.message_text%TYPE;         --���b�Z�[�W�p������
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
     DELETE from xxcos_deposit_vd_slip_work                 xdvsw                  --�a���VD�[�i�`�[���[�N�e�[�u��
     WHERE  xdvsw.group_id = iv_group_id;
--
     COMMIT;
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    --*** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      lt_tkn :=xxccp_common_pkg.get_msg(
                     iv_application   => cv_apl_name
                    ,iv_name          => ct_msg_group_id
                    );
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf                --�G���[�E���b�Z�[�W
       ,ov_retcode     => lv_retcode               --���^�[���E�R�[�h
       ,ov_errmsg      => lv_errmsg                --���[�U�[�E�G���[�E���b�Z�[�W
       ,ov_key_info    => lv_key_info              --�L�[���
       ,iv_item_name1  => lt_tkn                   --�O���[�vID
       ,iv_data_value1 => iv_group_id
   );
     --
     --���b�Z�[�W����
     lv_table_name:= xxccp_common_pkg.get_msg(
                     iv_application   => cv_apl_name
                    ,iv_name          => ct_msg_work_tab_name
                    );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_delete_data
                    ,cv_tkn_table
                    ,lv_table_name
                    ,cv_tkn_key
                    ,lv_key_info
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_work_tbl;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : �f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2,     --�G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lt_tkn                        fnd_new_messages.message_text%TYPE;         --���b�Z�[�W�p������
    lb_error                      BOOLEAN;
  --�e�[�u����`
    l_data_tab                 xxcos_common2_pkg.g_layout_ttype;              --�o�̓f�[�^���
  --
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_data_record
    IS
      SELECT
            '01'                                       medium_class               --�}�̋敪
           ,g_input_rec.report_type_code               data_type_code             --�f�[�^��R�[�h
           ,'00'                                       file_no                    --�t�@�C��No
           ,g_other_rec.proc_date                      process_date               --������
           ,g_other_rec.proc_time                      process_time               --��������
           ,g_input_rec.base_code                      base_code                  --���_�i����j�R�[�h
           ,g_input_rec.report_code                    report_code                --���[�R�[�h
           ,g_input_rec.report_mode                    report_show_name           --���[�\����
           ,xdvsw.company_name                         company_name               --�Ж��i�����j
           ,xdvsw.shop_code                            shop_code                  --�X�R�[�h
           ,xdvsw.shop_name                            shop_name                  --�X���i�����j
           ,TO_CHAR(xdvsw.order_date,cv_time_fmt)      order_date                 --������
           ,'00000000'                                 result_delivery_date       --���[�i��
           ,TO_CHAR(xdvsw.delivery_date,cv_time_fmt)   shop_delivery_date         --�X�ܔ[�i��
           ,xdvsw.invoice_class                        invoice_class              --�`�[�敪
           ,xdvsw.classification_code                  big_classification_code    --�啪�ރR�[�h
           ,xdvsw.invoice_number                       invoice_number             --�`�[�ԍ�
           ,xdvsw.vendor_code                          vendor_code                --�����R�[�h
           ,xdvsw.vendor_name                          vendor_name                --����於�i�����j
           ,xdvsw.sum_amount_title                     f1_column                  --F-1��
           ,xdvsw.sum_amount                           f2_column                  --F-2��
           ,xdvsw.line_no                              line_no                    --�sNo
           ,xdvsw.product_code                         product_code2              --���i�R�[�h2
           ,xdvsw.item_name                            product_name               --���i���i�����j
           ,xdvsw.item_name_upper                      product_name1_alt          --���i��1(�J�i)
           ,xdvsw.item_name_lower_l                    product_name2_alt          --���i��2(�J�i)
           ,xdvsw.item_name_lower_r                    item_standard2             --�K�i2(item_name_lower_r)
           ,xdvsw.quantity                             sum_order_qty              --��������(���v�A�o��)'quantity'
           ,'0'                                        sum_shipping_qty           --�o�א��ʁi���v�A�o���j
           ,xdvsw.unit_price                           order_unit_price           --���P��
           ,xdvsw.unit_price                           shipping_unit_price        --���P���i�o�ׁj
           ,xdvsw.cost_amoount                         order_cost_amt             --�������z�i�����j
           ,'0'                                        shipping_cost_amt          --�������z�i�o�ׁj
           ,xdvsw.selling_price                        selling_price              --���P��
           ,xdvsw.selling_amount                       order_price_amt            --�������z�i�����j
           ,'0'                                        shipping_price_amt         --�������z�i�o�ׁj
           ,xdvsw.sum_quantity                         invoice_sum_order_qty      --�i�`�[�v�j�������ʁi���v�A�o���j
           ,'0'                                        invoice_sum_shipping_qty   --�i�`�[�v�j�o�א��ʁi���v�A�o���j
           ,xdvsw.sum_cost_amount                      invoice_order_cost_amt     --�i�`�[�v�j�������z�i�����j
           ,'0'                                        invoice_shipping_cost_amt  --�i�`�[�v�j�������z�i�o�ׁj
           ,xdvsw.sum_selling_amount                   invoice_order_price_amt    --�i�`�[�v�j�������z�i�����j
           ,'0'                                        invoice_shipping_price_amt --�i�`�[�v�j�������z�i�o�ׁj
      FROM  xxcos_deposit_vd_slip_work                 xdvsw                      
      WHERE xdvsw.group_id  = g_input_rec.rep_group_id
      --���b�N
      FOR UPDATE OF xdvsw.group_id NOWAIT;--
--
    -- *** ���[�J���E���R�[�h ***
    l_other_rec                g_other_rtype;          --���̑����
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    lb_error := FALSE;
--
    --==============================================================
    --�f�[�^���R�[�h���擾
    --==============================================================
    OPEN cur_data_record;
--
    <<data_record_loop>>
    LOOP
      FETCH cur_data_record INTO
        l_data_tab('MEDIUM_CLASS')                     --�}�̋敪
       ,l_data_tab('DATA_TYPE_CODE')                   --�f�[�^��R�[�h
       ,l_data_tab('FILE_NO')                          --�t�@�C��No
       ,l_data_tab('PROCESS_DATE')                     --������
       ,l_data_tab('PROCESS_TIME')                     --��������
       ,l_data_tab('BASE_CODE')                        --���_�i����j�R�[�h
       ,l_data_tab('REPORT_CODE')                      --���[�R�[�h
       ,l_data_tab('REPORT_SHOW_NAME')                 --���[�\����
       ,l_data_tab('COMPANY_NAME')                     --�Ж��i�����j
       ,l_data_tab('SHOP_CODE')                        --�X�R�[�h
       ,l_data_tab('SHOP_NAME')                        --�X���i�����j
       ,l_data_tab('ORDER_DATE')                       --������
       ,l_data_tab('RESULT_DELIVERY_DATE')             --���[�i��
       ,l_data_tab('SHOP_DELIVERY_DATE')               --�X�ܔ[�i��
       ,l_data_tab('INVOICE_CLASS')                    --�`�[�敪
       ,l_data_tab('BIG_CLASSIFICATION_CODE')          --�啪�ރR�[�h
       ,l_data_tab('INVOICE_NUMBER')                   --�`�[�ԍ�
       ,l_data_tab('VENDOR_CODE')                      --�����R�[�h
       ,l_data_tab('VENDOR_NAME')                      --����於�i�����j
       ,l_data_tab('F1_COLUMN')                        --F-1��
       ,l_data_tab('F2_COLUMN')                        --F-2��
       ,l_data_tab('LINE_NO')                          --�sNo
       ,l_data_tab('PRODUCT_CODE2')                    --���i�R�[�h2
       ,l_data_tab('PRODUCT_NAME')                     --���i���i�����j
       ,l_data_tab('PRODUCT_NAME1_ALT')                --���i��1(�J�i)
       ,l_data_tab('PRODUCT_NAME2_ALT')                --���i��2(�J�i)
       ,l_data_tab('ITEM_STANDARD2')                   --�K�i2(item_name_lower_r)
       ,l_data_tab('SUM_ORDER_QTY')                    --��������(���v�A�o��)'quantity'
       ,l_data_tab('SUM_SHIPPING_QTY')                 --�o�א��ʁi���v�A�o���j
       ,l_data_tab('ORDER_UNIT_PRICE')                 --���P��
       ,l_data_tab('SHIPPING_UNIT_PRICE')              --���P���i�o�ׁj
       ,l_data_tab('ORDER_COST_AMT')                   --�������z�i�����j
       ,l_data_tab('SHIPPING_COST_AMT')                --�������z�i�o�ׁj
       ,l_data_tab('SELLING_PRICE')                    --���P��
       ,l_data_tab('ORDER_PRICE_AMT')                  --�������z�i�����j
       ,l_data_tab('SHIPPING_PRICE_AMT')               --�������z�i�o�ׁj
       ,l_data_tab('INVOICE_SUM_ORDER_QTY')            --�i�`�[�v�j�������ʁi���v�A�o���j
       ,l_data_tab('INVOICE_SUM_SHIPPING_QTY')         --�i�`�[�v�j�o�א��ʁi���v�A�o���j
       ,l_data_tab('INVOICE_ORDER_COST_AMT')           --�i�`�[�v�j�������z�i�����j
       ,l_data_tab('INVOICE_SHIPPING_COST_AMT')        --�i�`�[�v�j�������z�i�o�ׁj
       ,l_data_tab('INVOICE_ORDER_PRICE_AMT')          --�i�`�[�v�j�������z�i�����j
       ,l_data_tab('INVOICE_SHIPPING_PRICE_AMT')       --�i�`�[�v�j�������z�i�o�ׁj
      ;
      EXIT WHEN cur_data_record%NOTFOUND;
--
      --==============================================================
      --CSV�w�b�_���R�[�h�쐬����(A-4)
      --==============================================================
      IF (cur_data_record%ROWCOUNT = 1) THEN
        out_csv_header(
          lv_errbuf
         ,lv_retcode
         ,lv_errmsg
        );
      END IF;
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --�f�[�^���R�[�h�쐬����(A-5)
      --==============================================================
      out_csv_data(
                   l_data_tab
                  ,lv_errbuf
                  ,lv_retcode
                  ,lv_errmsg
                           );
     IF (lv_retcode = cv_status_error) THEN
       RAISE global_api_expt;
     END IF;
--
    END LOOP data_record_loop;
--
IF (cur_data_record%ROWCOUNT = 0) THEN
      ov_retcode := cv_status_error;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name
                    ,iv_name         => cv_msg_nodata
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
--
END IF;
    --==============================================================
    --�t�b�^���R�[�h�쐬����(A-6)
    --==============================================================
    out_csv_footer(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
--
    CLOSE cur_data_record;
--
  EXCEPTION
--
    WHEN resource_busy_expt THEN
      gb_delete := false;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_work_tab_name);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_resource_busy_err
                    ,cv_tkn_table2
                    ,lt_tkn
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
  --#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    --==============================================================
    --��������(A-1)
    --==============================================================
    init(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --�w�b�_���R�[�h�쐬����(A-2)
    --==============================================================
    create_header(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --�f�[�^���R�[�h�擾����(A-3)
    --==============================================================
    get_data(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ov_retcode     := lv_retcode;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
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
    errbuf                      OUT VARCHAR2,       --�G���[�E���b�Z�[�W  --# �Œ� #
    retcode                     OUT VARCHAR2,       --���^�[���E�R�[�h    --# �Œ� #
    iv_file_name                IN VARCHAR2,        -- 1.�t�@�C����
    iv_chain_code               IN VARCHAR2,        -- 2.�`�F�[���X�R�[�h
    iv_report_code              IN VARCHAR2,        -- 3.���[�R�[�h
    in_user_id                  IN NUMBER,          -- 4.���[�U�[ID
    iv_base_code                IN VARCHAR2,        -- 5.���_�R�[�h
    iv_base_name                IN VARCHAR2,        -- 6.���_��
    iv_chain_name               IN VARCHAR2,        -- 7.�`�F�[���X��
    iv_report_type_code         IN VARCHAR2,        -- 8.���[��ʃR�[�h
    iv_ebs_business_series_code IN VARCHAR2,        -- 9.�Ɩ��n��R�[�h
    iv_report_mode              IN VARCHAR2,        --10.���[�l��
--
    in_group_id                 IN NUMBER           --12.�O���[�vID
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
    lv_retcode_del     VARCHAR2(1);
    --
    l_input_rec        g_input_rtype;
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
    -- ���̓p�����[�^�̃Z�b�g
    -- ===============================================
    l_input_rec.file_name                := iv_file_name;                     -- 1.�t�@�C����
    l_input_rec.chain_code               := iv_chain_code;                    -- 2.�`�F�[���X�R�[�h
    l_input_rec.report_code              := iv_report_code;                   -- 3.���[�R�[�h
    l_input_rec.user_id                  := in_user_id;                       -- 4.���[�UID
    l_input_rec.base_code                := iv_base_code;                     -- 5.���_�R�[�h
    l_input_rec.base_name                := iv_base_name;                     -- 6.���_��
    l_input_rec.chain_name               := iv_chain_name;                    -- 7.�`�F�[���X��
    l_input_rec.report_type_code         := iv_report_type_code;              -- 8.���[��ʃR�[�h
    l_input_rec.ebs_business_series_code := iv_ebs_business_series_code;      -- 9.�Ɩ��n��R�[�h
    l_input_rec.report_mode              := iv_report_mode;                   --10.���[�l��
    l_input_rec.rep_group_id             := in_group_id;                      --12.�O���[�vID
--
    g_input_rec := l_input_rec;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
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
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    IF (lv_retcode != cv_status_warn AND gb_delete = TRUE) THEN
      --==============================================================
      --���[�N�e�[�u���폜����(A-8)
      --==============================================================
      delete_work_tbl(
       g_input_rec.rep_group_id
       ,lv_errbuf
       ,lv_retcode_del
       ,lv_errmsg
      );
      IF ( lv_retcode_del = cv_status_error ) THEN
        gn_normal_cnt := 0;
        gn_error_cnt := gn_target_cnt;
              FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      lv_retcode := cv_status_error;
      END IF;
    END IF;
--

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
  --�e�[�u���폜��O�n���h��
      WHEN delete_tbl_expt THEN
      errbuf  := lv_errmsg;
      retcode := cv_status_error;
      ROLLBACK;
  --
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCOS014A10C;
