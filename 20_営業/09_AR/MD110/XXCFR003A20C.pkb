CREATE OR REPLACE PACKAGE BODY APPS.XXCFR003A20C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCFR003A20C(body)
 * Description      : �X�ܕʖ��׏o��
 * MD.050           : MD050_CFR_003_A20_�X�ܕʖ��׏o��
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  exe_svf                SVF�N��(A-2)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------
 *  2015/07/23    1.0   SCSK ���H ���O   �V�K�쐬
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCFR003A20';             -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_application              CONSTANT VARCHAR2(5)  := 'XXCFR';                   -- �A�v���P�[�V����
  -- ���[��
  cv_svf_name                 CONSTANT VARCHAR2(20) := 'XXCFR003A20';             -- ���[��
  -- ���b�Z�[�W
  cv_msg_xxcfr_00011          CONSTANT VARCHAR2(16) := 'APP-XXCFR1-00011';        -- API�G���[���b�Z�[�W
  cv_msg_xxcfr_00024          CONSTANT VARCHAR2(16) := 'APP-XXCFR1-00024';        -- ���[�O�����O���b�Z�[�W
  cv_msg_xxcfr_00152          CONSTANT VARCHAR2(16) := 'APP-XXCFR1-00152';        -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_xxcfr_00153          CONSTANT VARCHAR2(16) := 'APP-XXCFR1-00153';        -- �������^�C�v��`�Ȃ��G���[���b�Z�[�W
  -- �g�[�N���R�[�h
  cv_tkn_param1               CONSTANT VARCHAR2(30) := 'PARAM1';                  -- �p�����[�^���P
  cv_tkn_param2               CONSTANT VARCHAR2(30) := 'PARAM2';                  -- �p�����[�^���Q
  cv_tkn_param3               CONSTANT VARCHAR2(30) := 'PARAM3';                  -- �p�����[�^���R
  cv_tkn_param4               CONSTANT VARCHAR2(30) := 'PARAM4';                  -- �p�����[�^���S
  cv_tkn_lookup_type          CONSTANT VARCHAR2(30) := 'LOOKUP_TYPE';             -- �Q�ƃ^�C�v
  cv_tkn_lookup_code          CONSTANT VARCHAR2(30) := 'LOOKUP_CODE';             -- �Q�ƃR�[�h
  cv_tkn_api                  CONSTANT VARCHAR2(30) := 'API_NAME';                -- API��
  -- ���{�ꎫ��
  cv_dict_svf                 CONSTANT VARCHAR2(30) := 'CFR000A00004';            -- SVF�N��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_report_type              IN  VARCHAR2  -- ���[�敪
   ,iv_bill_type                IN  VARCHAR2  -- �������^�C�v
   ,in_org_request_id           IN  NUMBER    -- ���s���v��ID
   ,in_target_cnt               IN  NUMBER    -- �Ώی���
   ,ov_svf_file_xml             OUT VARCHAR2  -- ���[�t�H�[���t�@�C����
   ,ov_svf_file_vrq             OUT VARCHAR2  -- ���[�N�G���[�t�@�C����
   ,ov_errbuf                   OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                  OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- *** ���[�J���萔 ***
    -- �Q�ƃ^�C�v
    cv_xxcfr_bill_type          CONSTANT VARCHAR2(19) := 'XXCFR1_BILL_TYPE';     -- �������^�C�v
    -- �L��
    cv_enabled_flag             CONSTANT VARCHAR2(1)  := 'Y';                    -- �L��
    -- ���[�g���q
    cv_xml                      CONSTANT VARCHAR2(4)  := '.xml';                 -- �t�H�[���t�@�C��
    cv_vrq                      CONSTANT VARCHAR2(4)  := '.vrq';                 -- �N�G���[�t�@�C��
--
    -- *** ���[�J���ϐ� ***
    lv_param_msg                VARCHAR2(5000);                         -- �p�����[�^�o�͗p
    lv_file_id                  VARCHAR2(3);                            -- ���[ID
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
                        iv_application   => cv_application              -- �A�v���P�[�V����
                      , iv_name          => cv_msg_xxcfr_00152          -- ���b�Z�[�W�R�[�h
                      , iv_token_name1   => cv_tkn_param1               -- �g�[�N���R�[�h�P
                      , iv_token_value1  => iv_report_type              -- ���[�敪
                      , iv_token_name2   => cv_tkn_param2               -- �g�[�N���R�[�h�Q
                      , iv_token_value2  => iv_bill_type                -- �������^�C�v
                      , iv_token_name3   => cv_tkn_param3               -- �g�[�N���R�[�h�R
                      , iv_token_value3  => TO_CHAR(in_org_request_id)  -- ���s���v��ID
                      , iv_token_name4   => cv_tkn_param4               -- �g�[�N���R�[�h�S
                      , iv_token_value4  => TO_CHAR(in_target_cnt)      -- ��������
                    );
    -- ���O
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    -- ���O��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================
    -- ���[ID�擾
    --==================================
    BEGIN
      SELECT flvv.meaning AS file_id
      INTO   lv_file_id
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type  = cv_xxcfr_bill_type
      AND    flvv.lookup_code  = iv_bill_type
      AND    flvv.enabled_flag = cv_enabled_flag
      AND    TRUNC(NVL(flvv.start_date_active, SYSDATE)) <= TRUNC(SYSDATE)
      AND    TRUNC(NVL(flvv.end_date_active,   SYSDATE)) >= TRUNC(SYSDATE)
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg   := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application         -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_msg_xxcfr_00153     -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_lookup_type     -- �g�[�N���R�[�h1
                         , iv_token_value1 => cv_xxcfr_bill_type     -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_lookup_code     -- �g�[�N���R�[�h2
                         , iv_token_value2 => iv_bill_type           -- �g�[�N���l2
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- �t�@�C�����ҏW
    --==================================
    -- ���[�t�H�[���t�@�C�����ҏW
    ov_svf_file_xml := cv_svf_name || lv_file_id || cv_xml;
    -- ���[�N�G���[�t�@�C�����ҏW
    ov_svf_file_vrq := cv_svf_name || lv_file_id || cv_vrq;
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
   * Procedure Name   : exe_svf
   * Description      : SVF�N��(A-2)
   ***********************************************************************************/
  PROCEDURE exe_svf(
     iv_report_type         IN  VARCHAR2                 -- ���[�敪
    ,iv_svf_form_nm         IN  VARCHAR2                 -- ���[�t�H�[���t�@�C����
    ,iv_svf_query_nm        IN  VARCHAR2                 -- ���[�N�G���[�t�@�C����
    ,in_org_request_id      IN  NUMBER                   -- ���s���v��ID
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'exe_svf';     -- �v���O������
----#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
    -- ���t����
    cv_yyyymmdd            CONSTANT VARCHAR2(10) := 'YYYYMMDD';                -- YYYYMMDD�^
    -- SVF����
    cv_condition_request   CONSTANT VARCHAR2(13) := '[REQUEST_ID]=';           -- SVF����
    -- �R���J�����g�v���O������
    cv_conc_name           CONSTANT VARCHAR2(12) := 'XXCFR003A20C';            -- �R���J�����g�v���O������
--
    -- *** ���[�J���ϐ� ***
    lv_svf_file_name   VARCHAR2(50);
    lv_svf_param1      VARCHAR2(50);
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
    lv_svf_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �t�@�C�����̐ݒ�
    lv_svf_file_name := cv_svf_name
                       || TO_CHAR (cd_creation_date, cv_yyyymmdd)
                       || TO_CHAR (cn_request_id);
--
    -- SVF���o�����̐ݒ�
    lv_svf_param1 := cv_condition_request || TO_CHAR( in_org_request_id );
--
    -- ==========================================================
    -- �R���J�����g�E�v���O����������у��O�C���E���[�U���擾
    -- ==========================================================
    BEGIN
      SELECT  fcp.concurrent_program_name   AS conc_name  --�R���J�����g�E�v���O������
             ,xx00_global_pkg.user_name     AS user_name  --���O�C���E���[�U��
             ,xx00_global_pkg.resp_name     AS resp_name  --�E�Ӗ�
      INTO    lv_conc_name
             ,lv_user_name
             ,lv_resp_name
      FROM    fnd_concurrent_programs    fcp
      WHERE   fcp.concurrent_program_id = cn_program_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_conc_name := cv_conc_name;
    END;
--
    -- ===============================
    -- SVF�N��
    -- ===============================
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_svf_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_conc_name    => lv_conc_name          -- �R���J�����g��
     ,iv_file_name    => lv_svf_file_name      -- �o�̓t�@�C����
     ,iv_file_id      => cv_svf_name           -- ���[ID
     ,iv_output_mode  => iv_report_type        -- �o�͋敪
     ,iv_frm_file     => iv_svf_form_nm        -- ���[�t�H�[���t�@�C����
     ,iv_vrq_file     => iv_svf_query_nm       -- ���[�N�G���[�t�@�C����
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ���O�C���E���[�U��
     ,iv_resp_name    => lv_resp_name          -- ���O�C���E���[�U�̐E�Ӗ�
     ,iv_doc_name     => NULL                  -- ������
     ,iv_printer_name => NULL                  -- �v�����^��
     ,iv_request_id   => cn_request_id         -- �v��ID
     ,iv_nodata_msg   => NULL                  -- �f�[�^�Ȃ����b�Z�[�W
     ,iv_svf_param1   => lv_svf_param1         -- SVF���o����1
     );
--
    -- SVF�N��API�̌Ăяo���̓G���[��
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg( cv_application       -- 'XXCFR'
                                                     ,cv_msg_xxcfr_00011   -- API�G���[
                                                     ,cv_tkn_api           -- �g�[�N��'API_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        cv_application
                                                       ,cv_dict_svf 
                                                      )  -- SVF�N��
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| lv_errbuf ||cv_msg_part|| lv_svf_errmsg;
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
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_report_type              IN  VARCHAR2  -- ���[�敪
   ,iv_bill_type                IN  VARCHAR2  -- �������^�C�v
   ,in_org_request_id           IN  NUMBER    -- ���s���v��ID
   ,in_target_cnt               IN  NUMBER    -- �Ώی���
   ,ov_errbuf                   OUT VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode                  OUT VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg                   OUT VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- ���[�U�[��`���[�J���ϐ�
    -- ===============================
    lv_svf_file_xml             VARCHAR2(100) DEFAULT NULL;             -- ���[�t�H�[���t�@�C����
    lv_svf_file_vrq             VARCHAR2(100) DEFAULT NULL;             -- ���[�N�G���[�t�@�C����
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
    -- �J�E���^�̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
       iv_report_type    => iv_report_type    -- ���[�敪
      ,iv_bill_type      => iv_bill_type      -- �������^�C�v
      ,in_org_request_id => in_org_request_id -- ���s���v��ID
      ,in_target_cnt     => in_target_cnt     -- �Ώی���
      ,ov_svf_file_xml   => lv_svf_file_xml   -- ���[�t�H�[���t�@�C����
      ,ov_svf_file_vrq   => lv_svf_file_vrq   -- ���[�N�G���[�t�@�C����
      ,ov_errbuf         => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode        => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg         => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- �������������̏ꍇ�A�Ώی����J�E���g
    gn_target_cnt := in_target_cnt;
--
    -- ===============================
    -- SVF�N��(A-2)
    -- ===============================
    exe_svf(
       iv_report_type    => iv_report_type    -- ���[�敪
      ,iv_svf_form_nm    => lv_svf_file_xml   -- ���[�t�H�[���t�@�C����
      ,iv_svf_query_nm   => lv_svf_file_vrq   -- ���[�N�G���[�t�@�C����
      ,in_org_request_id => in_org_request_id -- ���s���v��ID
      ,ov_errbuf         => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode        => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg         => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ���������J�E���g
    gn_normal_cnt := in_target_cnt;
    -- ����������0���̏ꍇ
    IF ( gn_normal_cnt = 0 ) THEN
      -- �x���I��
      ov_retcode := cv_status_warn;
      --���b�Z�[�W�ҏW
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_application              -- �A�v���P�[�V����
                     , iv_name          => cv_msg_xxcfr_00024          -- ���b�Z�[�W�R�[�h
                   );
      -- ���O
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
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
    errbuf                      OUT VARCHAR2  -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                     OUT VARCHAR2  -- �G���[�R�[�h     #�Œ�#
   ,iv_report_type              IN  VARCHAR2  -- ���[�敪
   ,iv_bill_type                IN  VARCHAR2  -- �������^�C�v
   ,in_org_request_id           IN  NUMBER    -- ���s���v��ID
   ,in_target_cnt               IN  NUMBER    -- �Ώی���
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
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
        iv_report_type              -- ���[�敪
      , iv_bill_type                -- �������^�C�v
      , in_org_request_id           -- ���s���v��ID
      , in_target_cnt               -- �Ώی���
      , lv_errbuf                   -- �G���[�E���b�Z�[�W           --# �Œ� #
      , lv_retcode                  -- ���^�[���E�R�[�h             --# �Œ� #
      , lv_errmsg                   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================
    -- �I������(A-3)
    -- ===============================
    -- ��s
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- �G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      -- �����̐ݒ�
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      -- ���O
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf
      );
      --
    END IF;
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
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_normal_msg
                     );
    ELSIF( lv_retcode = cv_status_warn ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_warn_msg
                     );
    ELSIF( lv_retcode = cv_status_error ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_msg
                     );
    END IF;
--
    -- �I�����b�Z�[�W�o��
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
END XXCFR003A20C;
/
