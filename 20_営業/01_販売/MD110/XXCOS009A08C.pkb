CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOS009A08C (body)
 * Description      : �ėp�G���[���X�g
 * MD.050           : �ėp�G���[���X�g MD050_COS_009_A08
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_data               �Ώۃf�[�^�擾(A-2)
 *  edit_output_msg        ���b�Z�[�W�ҏW�o��(A-3)
 *  delete_gen_err_list    �ėp�G���[���X�g�폜(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/09/02    1.0   T.Ishiwata       �V�K�쐬
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cn_per_business_group_id  CONSTANT NUMBER      := fnd_global.per_business_group_id;   --PER_BUSINESS_GROUP_ID
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
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
--
  --*** ���b�N�G���[��O�n���h�� ***
  global_data_lock_expt     EXCEPTION;
  --*** ���O�̂ݏo�͗�O ***
  global_api_expt_log       EXCEPTION;
  --*** �Ώۃf�[�^�����G���[��O�n���h�� ***
  global_no_data_expt       EXCEPTION;
  --
  -- ���b�N�G���[
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                    CONSTANT  VARCHAR2(100) :=  'XXCOS009A08C';        -- �p�b�P�[�W��
  cv_xxcos_short_name            CONSTANT  VARCHAR2(100) :=  'XXCOS';               -- �̕��̈�Z�k�A�v����
  cv_xxccp_short_name            CONSTANT  VARCHAR2(100) :=  'XXCCP';               -- ���ʗ̈�Z�k�A�v����
  --���b�Z�[�W
  cv_msg_lock_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00001';    -- ���b�N�擾�G���[���b�Z�[�W
  cv_msg_no_data                 CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00003';    -- �Ώۃf�[�^�Ȃ����b�Z�[�W
  cv_msg_prof_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00004';    -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_msg_delete_err              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00012';    -- �f�[�^�폜�G���[���b�Z�[�W
  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_msg_parameter               CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-15019';    -- �p�����[�^�o�̓��b�Z�[�W
  cv_msg_out_rec                 CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-15020';    -- �������b�Z�[�W
  --���b�Z�[�W�p������
  cv_str_purge_term              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-15021';    -- XXCOS:�ėp�G���[���X�g�폜����
  --�G���[���X�g�p���b�Z�[�W
  cv_gmsg_process_date           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00215';    -- �������t�o�̓��b�Z�[�W
  cv_gmsg_prog_name              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-15003';    -- ������
  cv_gmsg_line1                  CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-15001';    -- ��؂���P
  cv_gmsg_line2                  CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-15002';    -- ��؂���P
--
  --�g�[�N����
  cv_tkn_nm_table_name           CONSTANT  VARCHAR2(100) :=  'TABLE_NAME';          -- �e�[�u������
  cv_tkn_nm_table_lock           CONSTANT  VARCHAR2(100) :=  'TABLE';               -- �e�[�u������(���b�N�G���[���p)
  cv_tkn_nm_key_data             CONSTANT  VARCHAR2(100) :=  'KEY_DATA';            -- �L�[�f�[�^
  cv_tkn_nm_profile1             CONSTANT  VARCHAR2(100) :=  'PROFILE';             -- �v���t�@�C����(�̔��̈�) 
  cv_tkn_nm_param1               CONSTANT  VARCHAR2(100) :=  'PARAM1';              -- ���̓p�����[�^�P
  cv_tkn_nm_param2               CONSTANT  VARCHAR2(100) :=  'PARAM2';              -- ���̓p�����[�^�Q
  cv_tkn_nm_param3               CONSTANT  VARCHAR2(100) :=  'PARAM3';              -- ���̓p�����[�^�R
  cv_tkn_nm_conc_name            CONSTANT  VARCHAR2(100) :=  'CONC_NAME';           -- �R���J�����g��
  cv_tkn_nm_fdate                CONSTANT  VARCHAR2(100) :=  'FDATE';               -- �������t
  cv_tkn_nm_msg_count            CONSTANT  VARCHAR2(100) :=  'MSG_COUNT';           -- �G���[���b�Z�[�W����
  cv_tkn_nm_del_count            CONSTANT  VARCHAR2(100) :=  'DEL_COUNT';           -- �ėp�G���[���X�g�폜����
  --�g�[�N���l
  cv_msg_vl_table_xgel           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00213';    -- �ėp�G���[���X�g�e�[�u��
--
  --�N�C�b�N�R�[�h�Q�Ɨp
  --�Q�ƃ^�C�v��
  cv_type_xgel_prgm              CONSTANT  VARCHAR2(100) :=  'XXCOS1_GEN_ERR_LIST_PRGM';      --�ėp�G���[���X�g�Ώۃv���O����
  cv_type_xgel_errmsg            CONSTANT  VARCHAR2(100) :=  'XXCOS1_GEN_ERR_LIST_ERRMSG';    --�ėp�G���[���X�g�ΏۃG���[���b�Z�[�W
  --�g�p�\�t���O�萔
  ct_enabled_flg_y               CONSTANT  fnd_lookup_values.enabled_flag%TYPE 
                                                         :=  'Y';       --�g�p�\
  cv_lang                        CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );               --����
--
  -- �v���t�@�C��
  ct_prof_errlist_purge_term     CONSTANT  fnd_profile_options.profile_option_name%TYPE 
                                                         := 'XXCOS1_GEN_ERRLIST_PURGE_TERM';  -- XXCOS:�ėp�G���[���X�g�폜����
--
  --���t�t�H�[�}�b�g
  cv_yyyy_mm_dd                  CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD';            --YYYY/MM/DD�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_proc_date                DATE;                                              --�Ɩ����t
  gn_purge_term               NUMBER;                                            --�ėp�G���[���X�g�폜����
  gn_delete_cnt               NUMBER;                                            --�폜����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���E�J�[�\��
  -- ===============================
  -- �ėp�G���[���X�g�e�[�u�����o�J�[�\��
  CURSOR gen_err_list_cur(
            iv_base_code     VARCHAR2
           ,id_process_date  DATE
           ,iv_conc_name     VARCHAR2
           )
  IS
    SELECT
       xgel.gen_err_list_id                  AS gen_err_list_id                          -- �ėp�G���[���X�gID
      ,xgel.base_code                        AS base_code                                -- ���_�R�[�h
      ,xgel.concurrent_program_name          AS concurrent_program_name                  -- �R���J�����g��
      ,flv1.description                      AS concurrent_program_desc                  -- �R���J�����g����
      ,xgel.business_date                    AS business_date                            -- �������t
      ,xgel.message_name                     AS message_name                             -- ���b�Z�[�W��
      ,xgel.message_text                     AS message_text                             -- ���b�Z�[�W
      ,flv1.attribute1                       AS func_message_name                        -- �@�\���b�Z�[�W��
      ,flv2.attribute1                       AS message_title_name                       -- ���b�Z�[�W�^�C�g����
    FROM
       xxcos_gen_err_list        xgel                                                    -- �ėp�G���[���X�g
      ,fnd_lookup_values         flv1                                                    -- �N�C�b�N�R�[�h�F�ėp�G���[���X�g�Ώۃv���O����
      ,fnd_lookup_values         flv2                                                    -- �N�C�b�N�R�[�h�F�ėp�G���[���X�g�ΏۃG���[���b�Z�[�W
    WHERE
        xgel.base_code                    = iv_base_code                                 -- ���̓p�����[�^�u���_�R�[�h�v
    AND xgel.business_date                = id_process_date                              -- ���̓p�����[�^�u�������t�v
    AND (
          ( iv_conc_name IS NULL )
         OR
          ( iv_conc_name IS NOT NULL
            AND
            xgel.concurrent_program_name  = iv_conc_name                                 -- ���̓p�����[�^�u�@�\���v
          )
        )
    --
    -- �Ώۋ@�\�̍i����
    AND xgel.concurrent_program_name      = flv1.meaning
    AND flv1.lookup_type                  = cv_type_xgel_prgm                            -- �N�C�b�N�R�[�h�F�ėp�G���[���X�g�Ώۃv���O����
    AND gd_proc_date                     >= NVL( flv1.start_date_active, gd_proc_date )
    AND gd_proc_date                     <= NVL( flv1.end_date_active,   gd_proc_date )
    AND flv1.enabled_flag                 = ct_enabled_flg_y
    AND flv1.language                     = cv_lang
    --
    -- �Ώۃ��b�Z�[�W�̍i����
    AND flv2.meaning                      = xgel.concurrent_program_name || '_' || xgel.message_name
    AND flv2.lookup_type                  = cv_type_xgel_errmsg                          -- �N�C�b�N�R�[�h�F�ėp�G���[���X�g�ΏۃG���[���b�Z�[�W
    AND gd_proc_date                     >= NVL( flv2.start_date_active, gd_proc_date )
    AND gd_proc_date                     <= NVL( flv2.end_date_active,   gd_proc_date )
    AND flv2.enabled_flag                 = ct_enabled_flg_y
    AND flv2.language                     = cv_lang
    ORDER BY
       xgel.concurrent_program_name
      ,xgel.message_name
      ,xgel.gen_err_list_id
  ;
--
  --�擾�f�[�^�i�[�ϐ���`
  TYPE g_gen_err_list_ttype IS TABLE OF gen_err_list_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_gen_err_list_tab       g_gen_err_list_ttype;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code                    IN     VARCHAR2,  -- ���_�R�[�h
    iv_process_date                 IN     VARCHAR2,  -- �������t
    iv_conc_name                    IN     VARCHAR2,  -- �@�\��
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    lv_para_msg            VARCHAR2(5000);                         -- �p�����[�^�o�̓��b�Z�[�W
    lv_purge_term          NUMBER;                                 -- �ėp�G���[���X�g�폜����
    lv_profile_name        fnd_new_messages.message_text%TYPE;     -- �v���t�@�C����
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
    --========================================
    -- �p�����[�^�o�͏���
    --========================================
    lv_para_msg             :=  xxccp_common_pkg.get_msg(
      iv_application        =>  cv_xxcos_short_name,
      iv_name               =>  cv_msg_parameter,
      iv_token_name1        =>  cv_tkn_nm_param1,
      iv_token_value1       =>  iv_base_code,
      iv_token_name2        =>  cv_tkn_nm_param2,
      iv_token_value2       =>  iv_process_date,
      iv_token_name3        =>  cv_tkn_nm_param3,
      iv_token_value3       =>  iv_conc_name
    );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
--
    --1�s��
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  NULL
    );
--
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
    --==================================
    -- XXCOS:�ėp�G���[���X�g�폜����
    --==================================
    lv_purge_term := FND_PROFILE.VALUE( ct_prof_errlist_purge_term );
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF ( lv_purge_term IS NULL ) THEN
      --�v���t�@�C����������擾
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application => cv_xxcos_short_name,
        iv_name        => cv_str_purge_term
      );
      --�v���t�@�C����������擾
      lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcos_short_name,
        iv_name               => cv_msg_prof_err,
        iv_token_name1        => cv_tkn_nm_profile1,
        iv_token_value1       => lv_profile_name
      );
      lv_errbuf    := lv_errmsg;
      RAISE global_api_expt_log;
    ELSE
      gn_purge_term := TO_NUMBER(lv_purge_term);
    END IF;
    --
--
    --========================================
    -- �Ɩ����t�擾����
    --========================================
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt_log;
    END IF;
--
  EXCEPTION
    -- *** ���O����o�͗p��O�n���h�� ***
    WHEN global_api_expt_log THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
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
   * Procedure Name   : get_data
   * Description      : �����Ώۃf�[�^�擾(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_base_code                    IN     VARCHAR2,  -- ���_�R�[�h
    id_process_date                 IN     DATE,      -- �������t
    iv_conc_name                    IN     VARCHAR2,  -- �@�\��
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
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
    --�Ώۃf�[�^�擾
    OPEN  gen_err_list_cur(
             iv_base_code                                     -- ���_�R�[�h
            ,id_process_date                                  -- �������t
            ,iv_conc_name                                     -- �@�\��
            );
    FETCH gen_err_list_cur BULK COLLECT INTO gt_gen_err_list_tab;
    CLOSE gen_err_list_cur;
--
    --���������J�E���g
    gn_target_cnt := gt_gen_err_list_tab.COUNT;
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
      IF ( gen_err_list_cur%ISOPEN ) THEN
        CLOSE gen_err_list_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_output_msg
   * Description      : ���b�Z�[�W�ҏW�o��(A-3)
   ***********************************************************************************/
  PROCEDURE edit_output_msg(
    iv_base_code                    IN     VARCHAR2,  -- ���_�R�[�h
    id_process_date                 IN     DATE,      -- �������t
    iv_conc_name                    IN     VARCHAR2,  -- �@�\��
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_output_msg'; -- �v���O������
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
    lv_past_conc_name  xxcos_gen_err_list.concurrent_program_name%TYPE;
    lv_past_msg_title  xxcos_gen_err_list.message_name%TYPE;
    lv_gen_msg         VARCHAR2(5000);
    lv_gmsg_line1      fnd_new_messages.message_text%TYPE;
    lv_gmsg_line2      fnd_new_messages.message_text%TYPE;
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
  --
    --========================================
    -- �ϐ��̏�����
    --========================================
    lv_past_conc_name := NULL;
    lv_past_msg_title := NULL;
    --
    --========================================
    -- ��؂���̎擾
    --========================================
    -- ��؂���P
    lv_gmsg_line1 :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_xxcos_short_name
                       ,iv_name         =>  cv_gmsg_line1
                      );
    -- ��؂���Q
    lv_gmsg_line2 :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_xxcos_short_name
                       ,iv_name         =>  cv_gmsg_line2
                      );
    --
    --
    --========================================
    -- �G���[���b�Z�[�W�̕ҏW�Əo��
    --========================================
    --�ėp�G���[���X�g�e�[�u���̓��e��ҏW���āu�o�́v�֏o��
    <<edit_output_msg>>
    FOR i IN 1..gt_gen_err_list_tab.COUNT LOOP
      -- �@�\���b�Z�[�W�̏o�́F1���or�@�\���ς�����ꍇ
      IF ( i = 1 OR lv_past_conc_name != gt_gen_err_list_tab(i).concurrent_program_name ) THEN
        --��s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        -- �������̏o��
        lv_gen_msg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_xxcos_short_name
                       ,iv_name         =>  cv_gmsg_prog_name
                       ,iv_token_name1  =>  cv_tkn_nm_conc_name
                       ,iv_token_value1 =>  gt_gen_err_list_tab(i).concurrent_program_desc
                       );
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_gen_msg
        );
        --��s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        -- ��؂���P�̏o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_gmsg_line1
        );
        --
        -- �@�\���b�Z�[�W�̏o��
        lv_gen_msg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_xxcos_short_name
                       ,iv_name         =>  gt_gen_err_list_tab(i).func_message_name
                       );
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_gen_msg
        );
        -- ��؂���P�̏o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_gmsg_line1
        );
        --
        --
      END IF;
      --
      -- ���b�Z�[�W�^�C�g���̏o��
      -- ���[�v��1��ځA�܂���A-2�Ŏ擾�����G���[���́u�R���J�����g���v���O��ƕς�����ꍇ�A
      -- �܂���A-2�Ŏ擾�����G���[���́u���b�Z�[�W�^�C�g���v���O��ƕς�����ꍇ�A
      IF(i = 1 OR lv_past_conc_name != gt_gen_err_list_tab(i).concurrent_program_name 
               OR lv_past_msg_title != gt_gen_err_list_tab(i).message_title_name      ) THEN      
        --��s�}��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        --
        -- ���b�Z�[�W�^�C�g���̏o��
        lv_gen_msg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_xxcos_short_name
                       ,iv_name         =>  gt_gen_err_list_tab(i).message_title_name
                       );
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_gen_msg
        );
        -- ��؂���Q�̏o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_gmsg_line2
        );
        --      
      END IF;
      --
      -- ���b�Z�[�W�̏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gt_gen_err_list_tab(i).message_text
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      --
      -- �R���J�����g�v���O�������̑ޔ�
      lv_past_conc_name := gt_gen_err_list_tab(i).concurrent_program_name;
      -- ���b�Z�[�W�^�C�g���̑ޔ�
      lv_past_msg_title := gt_gen_err_list_tab(i).message_title_name;
    END LOOP edit_output_msg;
  --
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
  END edit_output_msg;
--
  /**********************************************************************************
   * Procedure Name   : delete_gen_err_list
   * Description      : �ėp�G���[���X�g�폜(A-4)
   ***********************************************************************************/
  PROCEDURE delete_gen_err_list(
    iv_base_code                    IN     VARCHAR2,  -- ���_�R�[�h
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_gen_err_list'; -- �v���O������
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
    lv_table_name fnd_new_messages.message_text%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR gen_err_list_del_cur
      IS
        SELECT xgel.ROWID
        FROM   xxcos_gen_err_list xgel
        WHERE  xgel.base_code      =   iv_base_code
          AND  xgel.business_date <= (gd_proc_date - gn_purge_term)
        FOR UPDATE NOWAIT;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--  �ϐ��̏�����
    gn_delete_cnt := 0;
--
--
    -- ===============================
    -- ���b�N�̎擾
    -- ===============================
    BEGIN
      OPEN  gen_err_list_del_cur;
      CLOSE gen_err_list_del_cur;
    EXCEPTION
      -- *** ���b�N�G���[�n���h�� ***
      WHEN global_data_lock_expt THEN
        IF ( gen_err_list_del_cur%ISOPEN ) THEN
          CLOSE gen_err_list_del_cur;
        END IF;
        lv_table_name := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcos_short_name  -- �A�v���P�[�V�����Z�k��
                           ,iv_name        => cv_msg_vl_table_xgel -- ���b�Z�[�W�R�[�h
                         );
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_lock_err         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_nm_table_lock    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_table_name           -- �g�[�N���l1
                     );
        --
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- �ėp�G���[���X�g�̍폜
    -- ===============================
    BEGIN
      DELETE 
      FROM   xxcos_gen_err_list xgel
      WHERE  xgel.base_code      =   iv_base_code
        AND  xgel.business_date <= (gd_proc_date - gn_purge_term)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcos_short_name  -- �A�v���P�[�V�����Z�k��
                           ,iv_name        => cv_msg_vl_table_xgel -- ���b�Z�[�W�R�[�h
                         );
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_delete_err       -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_nm_table_name    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => lv_table_name           -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_nm_key_data      -- �g�[�N���R�[�h1
                       ,iv_token_value2 => SQLERRM                 -- �g�[�N���l1
                     );
        --
        RAISE global_api_expt;
    END;
    -- �����̊i�[
    gn_delete_cnt := SQL%ROWCOUNT;
    --
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
      IF ( gen_err_list_del_cur%ISOPEN ) THEN
        CLOSE gen_err_list_del_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END delete_gen_err_list;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code                    IN     VARCHAR2,  -- ���_�R�[�h
    iv_process_date                 IN     VARCHAR2,  -- �������t
    iv_conc_name                    IN     VARCHAR2,  -- �@�\��
    ov_errbuf                       OUT    VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                      OUT    VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                       OUT    VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ld_process_date                   DATE;            -- �������t
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
    gn_delete_cnt := 0;
--
    -- ===============================
    -- A-1  ��������
    -- ===============================
    init(
       iv_base_code                    -- ���_�R�[�h
      ,iv_process_date                 -- �������t
      ,iv_conc_name                    -- �@�\��
      ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ���̓p�����[�^�u�������t�v��DATE�^�ɕϊ�
    ld_process_date := TO_DATE( iv_process_date, cv_yyyy_mm_dd );
--
    -- ===============================
    -- A-2  �Ώۃf�[�^�擾
    -- ===============================
    get_data(
       iv_base_code                    -- ���_�R�[�h
      ,ld_process_date                 -- �������t
      ,iv_conc_name                    -- �@�\��
      ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  ���b�Z�[�W�ҏW�o��
    -- ===============================
    -- �G���[���b�Z�[�W������1���ȏ�̂Ƃ��̂�
    IF( gn_target_cnt  > 0 ) THEN
      edit_output_msg(
         iv_base_code                    -- ���_�R�[�h
        ,ld_process_date                 -- �������t
        ,iv_conc_name                    -- �@�\��
        ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- A-4  �ėp�G���[���X�g�폜
    -- ===============================
    delete_gen_err_list(
       iv_base_code                    -- ���_�R�[�h
      ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- �G���[���b�Z�[�W������0��
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_no_data
      );
      RAISE global_no_data_expt;
    END IF;
--
  EXCEPTION
    -- *** �Ώ�0����O�n���h�� ***
    WHEN global_no_data_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg, 1, 5000 );
      -- ���^�[���R�[�h���ꎞ�I�Ɍx���ɂ���
      ov_retcode := cv_status_warn;
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
    errbuf                          OUT    VARCHAR2,         -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                         OUT    VARCHAR2,         -- ���^�[���E�R�[�h    --# �Œ� #
    iv_base_code                    IN     VARCHAR2,         --   ���_�R�[�h
    iv_process_date                 IN     VARCHAR2,         --   �������t
    iv_conc_name                    IN     VARCHAR2          --   �@�\��
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
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
       iv_base_code                    -- ���_�R�[�h
      ,iv_process_date                 -- �������t
      ,iv_conc_name                    -- �@�\��
      ,lv_errbuf                       -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode                      -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF ( lv_retcode <> cv_status_normal ) THEN
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
    --
    -- ===============================================
    -- �X�e�[�^�X�̍X�V
    -- ===============================================
    IF (lv_retcode <> cv_status_error ) THEN
      IF   ( gn_target_cnt > 0 ) THEN
        -- �G���[���b�Z�[�W���P���ȏ゠��ꍇ�̓X�e�[�^�X���x��
        lv_retcode := cv_status_warn;
      ELSIF( gn_target_cnt = 0 ) THEN
        -- �G���[���b�Z�[�W���O���̏ꍇ�̓X�e�[�^�X�𐳏�
        lv_retcode := cv_status_normal;
      END IF;
    ELSE
      -- �G���[�����ݒ�
      gn_error_cnt := gn_error_cnt + 1;
    END IF;
    --
    --
    -- ===============================================
    -- �����o��
    -- ===============================================
    -- �G���[���b�Z�[�W�����ƍ폜�����̏o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_out_rec
                    ,iv_token_name1  => cv_tkn_nm_msg_count
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                    ,iv_token_name2  => cv_tkn_nm_del_count
                    ,iv_token_value2 => TO_CHAR( gn_delete_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
        --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================
    -- �I�����b�Z�[�W�o��
    -- ===============================================
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
       which  => FND_FILE.OUTPUT
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
END XXCOS009A08C;
/
