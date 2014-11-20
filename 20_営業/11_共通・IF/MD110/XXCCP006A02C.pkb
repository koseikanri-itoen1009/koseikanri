CREATE OR REPLACE PACKAGE BODY XXCCP006A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP006A02C(body)
 * Description      : ���I�p�����[�^�R���J�����g�Ή�
 * MD.050           : ���I�p�����[�^�R���J�����g�Ή� MD050_CCP_006_A02
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  get_profile_name       �v���t�@�C�����擾�v���V�[�W��
 *  last                   �I������
 *  get_format_info        �t�H�[�}�b�g���擾
 *  submit_concurrent      �R���J�����g�N������
 *  edit_param_processdate �p�����[�^�ҏW����(processdate!)
 *  edit_param_asterisk    �p�����[�^�ҏW����(*)
 *  edit_param_time        �p�����[�^�ҏW����(�f�t�H���g�^�C�v�F���ݎ���)
 *  edit_param_date        �p�����[�^�ҏW����(�f�t�H���g�^�C�v�F���ݓ�)
 *  edit_param_sql         �p�����[�^�ҏW����(�f�t�H���g�^�C�v�FSQL��)
 *  get_edit_param_info    ���I�p�����[�^�l�Z�o����
 *  init                   ��������
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2009/01/13     1.0  Masakazu Yamashita  main�V�K�쐬
 *  2009/03/10     1.1  Masayuki.Sano       �����e�X�g����s���Ή�
 *                                          �E���b�Z�[�W�\���s���Ή�
 *                                          �E�R���J�����g�̋N���p�����[�^98�ȏ㎞�̏����ύX
 *                                          �E*DEFAULT*���̏����ǉ�
 *                                          �E$FLEX$�̑Ή�
 *                                          �E�擾����WHERE��̐擪��"WHERE "�Ŏn�܂�ꍇ�A
 *                                            "WHERE "���폜
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
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCCP006A02C'; -- �p�b�P�[�W��
--
  -- �V�X�e�����t
  cd_sysdate       CONSTANT DATE := SYSDATE;
--
  ------------------------------
  -- ���b�Z�[�W�֘A
  ------------------------------
  -- ���b�Z�[�W�R�[�h
  cv_application                 CONSTANT VARCHAR2(10) := 'XXCCP';                   -- �A�h�I���F���ʁEIF�̈�
-- 2009/03/10 UPDATE START
--  cv_msg_app_name                CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10002';        -- �A�v���P�[�V�����Z�k�����b�Z�[�W�o��
--  cv_msg_prg_name                CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10003';        -- �R���J�����g�Z�k�����b�Z�[�W�o��
--  cv_msg_param                   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10005';        -- �������b�Z�[�W�o��
--  cv_msg_target_req              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10006';        -- �N���Ώۗv��ID���b�Z�[�W�o��
  cv_msg_app_name                CONSTANT VARCHAR2(20) := 'APP-XXCCP1-00002';        -- �A�v���P�[�V�����Z�k�����b�Z�[�W�o��
  cv_msg_prg_name                CONSTANT VARCHAR2(20) := 'APP-XXCCP1-00003';        -- �R���J�����g�Z�k�����b�Z�[�W�o��
  cv_msg_param                   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-00005';        -- �������b�Z�[�W�o��
  cv_msg_target_req              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-00006';        -- �N���Ώۗv��ID���b�Z�[�W�o��
-- 2009/03/10 UPDATE END
  cv_msg_target_status_abnormal  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10026';        -- �R���J�����g�X�e�[�^�X�ُ�I��
  cv_msg_target_status_err       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10028';        -- �R���J�����g�G���[�I��
  cv_msg_target_status_warning   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10030';        -- �R���J�����g�G���[�I��
  cv_msg_concurrent_fail         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10022';        -- �N���ΏۃR���J�����g�̋N�����s�G���[
  cv_msg_concurrent_status_fail  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10023';        -- �R���J�����g�X�e�[�^�X�擾���s�G���[
  cv_msg_no_data_value_set       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10035';        -- �\���؂̒l���s���b�Z�[�W
  cv_msg_too_many_value_set      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10036';        -- �\���؂̒l���������b�Z�[�W
  cv_msg_no_data_default_value   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10033';        -- �f�t�H���g�l�O�����b�Z�[�W
  cv_msg_too_many_default_value  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10034';        -- �f�t�H���g�l���������b�Z�[�W
  cv_msg_param_not_found         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10038';        -- �p�����[�^0�G���[
-- 2009/03/10 ADD START
  cv_msg_param_max_over          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10059';        -- �p�����[�^���������߃G���[���b�Z�[�W
-- 2009/03/10 ADD END
  cv_msg_app_name_err            CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10020';        -- �A�v���P�[�V���������̓G���[
  cv_msg_prg_name_err            CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10021';        -- �R���J�����g�����̓G���[
  cv_msg_no_found_profile        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10032';        -- �v���t�@�C���擾�G���[���b�Z�[�W2
  cv_msg_no_format_data          CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10058';        -- �f�t�H���g�^�C�v�F���ݓ��E���ݎ����̓��t�����擾�G���[
  cv_msg_target_rec              CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';        -- �Ώی������b�Z�[�W
  cv_msg_success_rec             CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';        -- �����������b�Z�[�W
  cv_msg_error_rec               CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';        -- �G���[�������b�Z�[�W
  cv_msg_warn_rec                CONSTANT VARCHAR2(20) := 'APP-XXCCP1-00001';        -- �x���������b�Z�[�W
  cv_msg_normal                  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';        -- ����I�����b�Z�[�W
  cv_msg_warn                    CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90005';        -- �x���I�����b�Z�[�W
  cv_msg_error                   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-10008';        -- �G���[�I�����b�Z�[�W
  -- ���b�Z�[�W�g�[�N��
  cv_msg_tkn1                    CONSTANT VARCHAR2(20) := 'COLUMN_SEQ_NUM';
  cv_msg_tkn2                    CONSTANT VARCHAR2(20) := 'DYNAM_SQL';
  cv_msg_tkn3                    CONSTANT VARCHAR2(20) := 'REQ_ID';
  cv_msg_tkn4                    CONSTANT VARCHAR2(20) := 'PHASE';
  cv_msg_tkn5                    CONSTANT VARCHAR2(20) := 'STATUS';
  cv_msg_tkn6                    CONSTANT VARCHAR2(20) := 'PROFILE_NAME';
  cv_msg_tkn7                    CONSTANT VARCHAR2(20) := 'NUMBER';
  cv_msg_tkn8                    CONSTANT VARCHAR2(20) := 'PARAM_VALUE';
  cv_msg_tkn9                    CONSTANT VARCHAR2(20) := 'AP_SHORT_NAME';
  cv_msg_tkn10                   CONSTANT VARCHAR2(20) := 'CONC_SHORT_NAME';
  cv_msg_cnt_token               CONSTANT VARCHAR2(20) := 'COUNT';
  ------------------------------
  -- �R���J�����g�ҋ@�֐��X�e�[�^�X
  ------------------------------
  cv_phase_complete              CONSTANT VARCHAR2(20) := 'COMPLETE';                -- �t�F�[�Y�F����
  cv_phase_normal                CONSTANT VARCHAR2(20) := 'NORMAL';                  -- �t�F�[�Y�F����
  cv_phase_error                 CONSTANT VARCHAR2(20) := 'ERROR';                   -- �t�F�[�Y�F�G���[
  cv_phase_warning               CONSTANT VARCHAR2(20) := 'WARNING';                 -- �t�F�[�Y�F�x��
  ------------------------------
  -- ���̓p�����[�^�l
  ------------------------------
  cv_default                     CONSTANT VARCHAR2(20) := 'DEFAULT';
  cv_datetime                    CONSTANT VARCHAR2(20) := 'DATETIME';
  cv_date                        CONSTANT VARCHAR2(20) := 'DATE';
  cv_time                        CONSTANT VARCHAR2(20) := 'TIME';
  cv_asterisk                    CONSTANT VARCHAR2(20)  := '*';
  cv_processdate                 CONSTANT VARCHAR2(20) := 'PROCESSDATE!';
  ------------------------------
  -- �f�t�H���g�^�C�v
  ------------------------------
  cv_default_type_sql            CONSTANT VARCHAR2(20) := 'S';                       -- SQL��
  cv_default_type_pro            CONSTANT VARCHAR2(20) := 'P';                       -- �v���t�@�C��
  cv_default_type_date           CONSTANT VARCHAR2(20) := 'D';                       -- ���ݓ�
  cv_default_type_time           CONSTANT VARCHAR2(20) := 'T';                       -- ���ݎ���
  ------------------------------
  -- �v���t�@�C����
  ------------------------------
  -- XXCCP:���I�p�����[�^�R���J�����g�X�e�[�^�X�Ď��Ԋu
  cv_profile_watch_time          CONSTANT VARCHAR2(30) := 'XXCCP1_DYNAM_CONC_WATCH_TIME';
  ------------------------------
  -- �Œ蕶��
  ------------------------------
  cv_profile                     CONSTANT VARCHAR2(20) := ':$PROFILES$.';
  cv_srs                         CONSTANT VARCHAR2(20) := '$SRS$.';
-- 2009/03/10 ADD START
  cv_flex                        CONSTANT VARCHAR2(20) := ':$FLEX$.';
  cv_single_quote                CONSTANT VARCHAR2(2)  := '''';
-- 2009/03/10 ADD END
  ------------------------------
  -- �����^�C�v
  ------------------------------
  cv_format_type_y               CONSTANT VARCHAR2(1) := 'Y';                        -- �W������
  cv_format_type_x               CONSTANT VARCHAR2(1) := 'X';                        -- �W����
  cv_format_type_d               CONSTANT VARCHAR2(1) := 'D';                        -- ���t
  cv_format_type_t               CONSTANT VARCHAR2(1) := 'T';                        -- ����
  cv_format_type_i               CONSTANT VARCHAR2(1) := 'I';                        -- ����
  cv_format_type_c               CONSTANT VARCHAR2(1) := 'C';                        -- ����
  ------------------------------
  -- ���t����
  ------------------------------
  cv_format1                     CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
  cv_format2                     CONSTANT VARCHAR2(30) := 'DD-MON-YYYY HH24:MI:SS';
  cv_format3                     CONSTANT VARCHAR2(30) := 'DD-MON-RR HH24:MI:SS';
  cv_format4                     CONSTANT VARCHAR2(30) := 'DD-MON-YYYY HH24:MI';
  cv_format5                     CONSTANT VARCHAR2(30) := 'DD-MON-RR HH24:MI';
  cv_format6                     CONSTANT VARCHAR2(30) := 'HH24:MI:SS';
  cv_format7                     CONSTANT VARCHAR2(30) := 'HH24:MI';
  cv_format8                     CONSTANT VARCHAR2(30) := 'HH:MI:SS';
  cv_format9                     CONSTANT VARCHAR2(30) := 'HH:MI';
  cv_format10                    CONSTANT VARCHAR2(30) := 'DD-MON-YYYY';
  cv_format11                    CONSTANT VARCHAR2(30) := 'DD-MON-RR';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE g_args_info_ttype IS TABLE OF VARCHAR2(1000) INDEX BY BINARY_INTEGER ;        -- ���̓p�����[�^
  TYPE g_edit_param_info_ttype IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER ;  -- �ҏW��p�����[�^
-- 2009/03/10 ADD START
  TYPE g_param_info_rtype IS RECORD(
     default_type          fnd_descr_flex_col_usage_vl.default_type%TYPE          -- �f�t�H���g�^�C�v
    ,default_value         fnd_descr_flex_col_usage_vl.default_value%TYPE         -- �f�t�H���g�l
    ,set_id                fnd_descr_flex_col_usage_vl.flex_value_set_id%TYPE     -- �l�Z�b�gID
    ,seq_num               fnd_descr_flex_col_usage_vl.column_seq_num%TYPE        -- ����
    ,flex_value_set_name   fnd_flex_value_sets.flex_value_set_name%TYPE           -- �l�Z�b�g��
  ) ;
  TYPE g_param_info_ttype IS TABLE OF g_param_info_rtype INDEX BY BINARY_INTEGER ;
-- 2009/03/10 ADD END
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_target_req_id NUMBER DEFAULT NULL;
--
-- 2009/03/10 ADD START
  /**********************************************************************************
   * Procedure Name   : replace_data
   * Description      : ���ʏ����F�u�������i$FLEX$�p�j
  ***********************************************************************************/
  PROCEDURE replace_data(
    iv_before_data           IN  VARCHAR2,                            -- 1.�u���O�̕�����
    iv_search_val            IN  VARCHAR2,                            -- 2.����������
    iv_replace_val           IN  VARCHAR2,                            -- 3.�u��������
    ov_after_data            OUT VARCHAR2,                            -- 4.�u����̕�����
    ov_errbuf                OUT VARCHAR2,                            -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,                            -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'replace_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���萔 ***
    cv_underscore               CONSTANT VARCHAR2(1) := '_';          -- �A���_�[�X�R�A
    cv_space                    CONSTANT VARCHAR2(1) := ' ';          -- ���p�X�y�[�X
--
    -- *** ���[�J���ϐ� ***
    lv_rep_value_tmp            VARCHAR2(5000);                       -- �u���Ώۂ̕�����(�ꎞ�i�[�p)
    lv_rep_idx                  NUMBER;                               -- �u���J�n�ʒu
    lv_rep_next_char            VARCHAR2(1);                          -- �u���Ώۂ̎��̕���
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �����ݒ�
    lv_rep_idx       := 1;
    lv_rep_value_tmp := iv_before_data;
--
    -- �u������
    <<replace_loop>>
    WHILE ( INSTRB(lv_rep_value_tmp, iv_search_val, lv_rep_idx) > 0 ) LOOP
      -- 1) ":$FLEX$.<�l�Z�b�g��>"�̈ʒu���擾����B
      lv_rep_idx       := INSTRB(lv_rep_value_tmp, iv_search_val, lv_rep_idx);
--
      -- 2) ":$FLEX$.<�l�Z�b�g��>"�̈ʒu�̎��̕������擾
      lv_rep_next_char := NVL(SUBSTRB(lv_rep_value_tmp, lv_rep_idx + LENGTHB(iv_search_val), 1), cv_space);
--
      -- 3) ���̓p�����[�^�֒u������B(�����F":$FLEX$.<�l�Z�b�g��>"�̈ʒu�̎��̕��������p�p��,'_'�ȊO)
      IF ( NOT ( xxccp_common_pkg.chk_alphabet_number_only(lv_rep_next_char) OR lv_rep_next_char = cv_underscore ) ) THEN
        lv_rep_value_tmp :=   SUBSTRB(lv_rep_value_tmp, 1 ,lv_rep_idx - 1) 
                           || iv_replace_val
                           || SUBSTRB(lv_rep_value_tmp, lv_rep_idx + LENGTHB(iv_search_val));
      END IF;
--
      -- 4) �ʒu��+1����
      lv_rep_idx := lv_rep_idx + 1;
    END LOOP replace_loop;
--
    -- �u�����ʂ��o�͐�Ɋi�[
    ov_after_data := lv_rep_value_tmp;
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
  END replace_data;
-- 2009/03/10 ADD END
--
  /**********************************************************************************
   * Procedure Name   : get_profile_name
   * Description      : �v���t�@�C�����̎擾����
  ***********************************************************************************/
  PROCEDURE get_profile_name(
    iv_value                 IN  VARCHAR2,                                           -- 1.���͒l
    ov_value                 OUT VARCHAR2,                                           -- 2.�ԋp�l
    ov_errbuf                OUT VARCHAR2,                                           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,                                           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)                                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_name'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    ln_position   NUMBER DEFAULT 0;
    lv_value_wk   VARCHAR2(2000) DEFAULT NULL;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ln_position := INSTR(iv_value, cv_profile);
--
    lv_value_wk := SUBSTR(REPLACE(iv_value, CHR(10), ' '), ln_position + LENGTH(cv_profile));
    ov_value := RTRIM(SUBSTR(lv_value_wk, 1, INSTR(lv_value_wk, ' ') - 1), ')');
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
  END get_profile_name;
--
  /**********************************************************************************
   * Procedure Name   : last
   * Description      : �I������
   ***********************************************************************************/
  PROCEDURE last(
    iv_app_name              IN  VARCHAR2,                                           -- 1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_prg_name              IN  VARCHAR2,                                           -- 2.�N���ΏۃR���J�����g�Z�k��
    in_target_param_cnt      IN  NUMBER,                                             -- 3.�N���ΏۃR���J�����g�p�����[�^��
    i_edit_param_info_tab    IN  g_edit_param_info_ttype,                            -- 4.�ҏW��p�����[�^
    iv_errbuf                IN  VARCHAR2,                                           -- 5.�G���[�E���b�Z�[�W
    iv_retcode               IN  VARCHAR2,                                           -- 6.���^�[���E�R�[�h
    iv_errmsg                IN  VARCHAR2,                                           -- 7.���[�U�[�E�G���[�E���b�Z�[�W
    ov_errbuf                OUT VARCHAR2,                                           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,                                           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)                                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'last'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    lv_message_code    VARCHAR2(100) DEFAULT NULL;   -- �I�����b�Z�[�W�R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------
    -- �p�����[�^�o��
    ------------------------------
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --�A�v���P�[�V�����Z�k�����b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_app_name
                    ,iv_token_name1  => cv_msg_tkn9
                    ,iv_token_value1 => iv_app_name);
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�R���J�����g�Z�k�����b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_prg_name
                    ,iv_token_name1  => cv_msg_tkn10
                    ,iv_token_value1 => iv_prg_name);
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�������b�Z�[�W�o��
    IF ( in_target_param_cnt > 0 ) THEN
      <<param_cnt_loop>>
      FOR i IN 1..in_target_param_cnt LOOP
        gv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                        ,iv_name         => cv_msg_param
                        ,iv_token_name1  => cv_msg_tkn7
                        ,iv_token_value1 => TO_CHAR(i)
                        ,iv_token_name2  => cv_msg_tkn8
                        ,iv_token_value2 => i_edit_param_info_tab(i));
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => gv_out_msg
        );
      END LOOP param_cnt_loop;
    END IF;
--
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    ------------------------------
    -- �N���Ώۗv��ID�o��
    ------------------------------
    --�N���Ώۗv��ID���b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_target_req
                    ,iv_token_name1  => cv_msg_tkn3
                    ,iv_token_value1 => gn_target_req_id);
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
    ------------------------------
    -- �G���[�ڍ׏o��
    ------------------------------
    --�G���[�o��
    IF ( iv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => iv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => iv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    ------------------------------
    -- ���������o��
    ------------------------------
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_target_rec
                    ,iv_token_name1  => cv_msg_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_success_rec
                    ,iv_token_name1  => cv_msg_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_error_rec
                    ,iv_token_name1  => cv_msg_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_warn_rec
                    ,iv_token_name1  => cv_msg_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --�I�����b�Z�[�W
    IF (iv_retcode = cv_status_normal) THEN
      lv_message_code := cv_msg_normal;
    ELSIF(iv_retcode = cv_status_warn) THEN
      lv_message_code := cv_msg_warn;
    ELSIF(iv_retcode = cv_status_error) THEN
      lv_message_code := cv_msg_error;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- �X�e�[�^�X�Z�b�g
    ov_retcode := iv_retcode;
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
  END last;
--
  /**********************************************************************************
   * Procedure Name   : get_format_info
   * Description      : �������擾
   ***********************************************************************************/
  PROCEDURE get_format_info(
    it_set_id                IN  fnd_descr_flex_col_usage_vl.flex_value_set_id%TYPE, -- 1.�l�Z�b�gID
    ot_format_type           OUT fnd_flex_value_sets.format_type%TYPE,               -- 2.�����^�C�v
    ot_maximum_size          OUT fnd_flex_value_sets.maximum_size%TYPE,              -- 3.�ő�T�C�Y
    ov_errbuf                OUT VARCHAR2,                                           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,                                           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)                                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_format_info'; -- �v���O������
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
    -- �������̎擾
    SELECT ffvs.format_type        AS format_type
          ,ffvs.maximum_size       AS maximum_size
    INTO   ot_format_type
          ,ot_maximum_size
    FROM   fnd_flex_value_sets     ffvs
    WHERE  ffvs.flex_value_set_id  = it_set_id
    ;
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
  END get_format_info;
--
  /**********************************************************************************
   * Procedure Name   : submit_concurrent
   * Description      : �R���J�����g�N������
   ***********************************************************************************/
  PROCEDURE submit_concurrent(
    iv_application           IN  VARCHAR2,                                           -- 1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_program               IN  VARCHAR2,                                           -- 2.�N���ΏۃR���J�����g�Z�k��
    i_edit_param_info_tab    IN  g_edit_param_info_ttype,                            -- 3.�ҏW��p�����[�^
    ov_errbuf                OUT VARCHAR2,                                           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,                                           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)                                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_concurrent'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    ln_req_id                NUMBER DEFAULT 0 ;          -- �v��ID
    lb_complete              BOOLEAN;
    lv_phase                 VARCHAR2(30) DEFAULT NULL;
    lv_status                VARCHAR2(30) DEFAULT NULL;
    lv_dev_phase             VARCHAR2(30) DEFAULT NULL;
    lv_dev_status            VARCHAR2(30) DEFAULT NULL;
    lv_message               VARCHAR2(30) DEFAULT NULL;
--
    lv_watch_time            VARCHAR2(255) DEFAULT NULL;
    -- *** ���[�J���E��O���� ***
    submit_err_expt          EXCEPTION;
    submit_warn_expt         EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���I�p�����[�^�R���J�����g�X�e�[�^�X�Ď��Ԋu�̎擾
    lv_watch_time := FND_PROFILE.VALUE(cv_profile_watch_time);
--
    IF ( lv_watch_time IS NULL ) THEN
      -- �v���t�@�C���擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_application,
                   iv_name        => cv_msg_no_found_profile,
                   iv_token_name1  => cv_msg_tkn6,
                   iv_token_value1 => cv_profile_watch_time);
--
      lv_errbuf := lv_errmsg;
--
      RAISE submit_err_expt;
--
    END IF;
--
    -- �R���J�����g���s
    ln_req_id := FND_REQUEST.SUBMIT_REQUEST(
                   application => iv_application,
                   program     => iv_program,
                   description => NULL,
                   start_time  => NULL,
                   sub_request => NULL,
                   argument1   => i_edit_param_info_tab(1),
                   argument2   => i_edit_param_info_tab(2),
                   argument3   => i_edit_param_info_tab(3),
                   argument4   => i_edit_param_info_tab(4),
                   argument5   => i_edit_param_info_tab(5),
                   argument6   => i_edit_param_info_tab(6),
                   argument7   => i_edit_param_info_tab(7),
                   argument8   => i_edit_param_info_tab(8),
                   argument9   => i_edit_param_info_tab(9),
                   argument10  => i_edit_param_info_tab(10),
                   argument11  => i_edit_param_info_tab(11),
                   argument12  => i_edit_param_info_tab(12),
                   argument13  => i_edit_param_info_tab(13),
                   argument14  => i_edit_param_info_tab(14),
                   argument15  => i_edit_param_info_tab(15),
                   argument16  => i_edit_param_info_tab(16),
                   argument17  => i_edit_param_info_tab(17),
                   argument18  => i_edit_param_info_tab(18),
                   argument19  => i_edit_param_info_tab(19),
                   argument20  => i_edit_param_info_tab(20),
                   argument21  => i_edit_param_info_tab(21),
                   argument22  => i_edit_param_info_tab(22),
                   argument23  => i_edit_param_info_tab(23),
                   argument24  => i_edit_param_info_tab(24),
                   argument25  => i_edit_param_info_tab(25),
                   argument26  => i_edit_param_info_tab(26),
                   argument27  => i_edit_param_info_tab(27),
                   argument28  => i_edit_param_info_tab(28),
                   argument29  => i_edit_param_info_tab(29),
                   argument30  => i_edit_param_info_tab(30),
                   argument31  => i_edit_param_info_tab(31),
                   argument32  => i_edit_param_info_tab(32),
                   argument33  => i_edit_param_info_tab(33),
                   argument34  => i_edit_param_info_tab(34),
                   argument35  => i_edit_param_info_tab(35),
                   argument36  => i_edit_param_info_tab(36),
                   argument37  => i_edit_param_info_tab(37),
                   argument38  => i_edit_param_info_tab(38),
                   argument39  => i_edit_param_info_tab(39),
                   argument40  => i_edit_param_info_tab(40),
                   argument41  => i_edit_param_info_tab(41),
                   argument42  => i_edit_param_info_tab(42),
                   argument43  => i_edit_param_info_tab(43),
                   argument44  => i_edit_param_info_tab(44),
                   argument45  => i_edit_param_info_tab(45),
                   argument46  => i_edit_param_info_tab(46),
                   argument47  => i_edit_param_info_tab(47),
                   argument48  => i_edit_param_info_tab(48),
                   argument49  => i_edit_param_info_tab(49),
                   argument50  => i_edit_param_info_tab(50),
                   argument51  => i_edit_param_info_tab(51),
                   argument52  => i_edit_param_info_tab(52),
                   argument53  => i_edit_param_info_tab(53),
                   argument54  => i_edit_param_info_tab(54),
                   argument55  => i_edit_param_info_tab(55),
                   argument56  => i_edit_param_info_tab(56),
                   argument57  => i_edit_param_info_tab(57),
                   argument58  => i_edit_param_info_tab(58),
                   argument59  => i_edit_param_info_tab(59),
                   argument60  => i_edit_param_info_tab(60),
                   argument61  => i_edit_param_info_tab(61),
                   argument62  => i_edit_param_info_tab(62),
                   argument63  => i_edit_param_info_tab(63),
                   argument64  => i_edit_param_info_tab(64),
                   argument65  => i_edit_param_info_tab(65),
                   argument66  => i_edit_param_info_tab(66),
                   argument67  => i_edit_param_info_tab(67),
                   argument68  => i_edit_param_info_tab(68),
                   argument69  => i_edit_param_info_tab(69),
                   argument70  => i_edit_param_info_tab(70),
                   argument71  => i_edit_param_info_tab(71),
                   argument72  => i_edit_param_info_tab(72),
                   argument73  => i_edit_param_info_tab(73),
                   argument74  => i_edit_param_info_tab(74),
                   argument75  => i_edit_param_info_tab(75),
                   argument76  => i_edit_param_info_tab(76),
                   argument77  => i_edit_param_info_tab(77),
                   argument78  => i_edit_param_info_tab(78),
                   argument79  => i_edit_param_info_tab(79),
                   argument80  => i_edit_param_info_tab(80),
                   argument81  => i_edit_param_info_tab(81),
                   argument82  => i_edit_param_info_tab(82),
                   argument83  => i_edit_param_info_tab(83),
                   argument84  => i_edit_param_info_tab(84),
                   argument85  => i_edit_param_info_tab(85),
                   argument86  => i_edit_param_info_tab(86),
                   argument87  => i_edit_param_info_tab(87),
                   argument88  => i_edit_param_info_tab(88),
                   argument89  => i_edit_param_info_tab(89),
                   argument90  => i_edit_param_info_tab(90),
                   argument91  => i_edit_param_info_tab(91),
                   argument92  => i_edit_param_info_tab(92),
                   argument93  => i_edit_param_info_tab(93),
                   argument94  => i_edit_param_info_tab(94),
                   argument95  => i_edit_param_info_tab(95),
                   argument96  => i_edit_param_info_tab(96),
                   argument97  => i_edit_param_info_tab(97),
                   argument98  => i_edit_param_info_tab(98));
--
    IF ( ln_req_id = 0 ) THEN
--
      -- �N���ΏۃR���J�����g�̋N�����s�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_application,
                    iv_name        => cv_msg_concurrent_fail);
--
      lv_errbuf := lv_errmsg;
--
      RAISE submit_err_expt;
--
    ELSE
--
      -- ���O�o�͗p�v��ID�Z�b�g
      gn_target_req_id := ln_req_id;
      -- �R�~�b�g����
      COMMIT;
--
      -- �Ώی����J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
    END IF;
--
    -- �R���J�����g�����҂�
    lb_complete := FND_CONCURRENT.WAIT_FOR_REQUEST(
                     request_id      =>  ln_req_id,
                     interval        =>  TO_NUMBER(lv_watch_time),
                     max_wait        =>  NULL,
                     phase           =>  lv_phase,
                     status          =>  lv_status,
                     dev_phase       =>  lv_dev_phase,
                     dev_status      =>  lv_dev_status,
                     message         =>  lv_message);
--
    IF ( lb_complete = FALSE ) THEN
--
      -- �R���J�����g�X�e�[�^�X�擾���s�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_concurrent_status_fail,
                     iv_token_name1  => cv_msg_tkn3,
                     iv_token_value1 => ln_req_id);
--
      lv_errbuf := lv_errmsg;
--
      RAISE submit_err_expt;
--
    ELSIF ( lv_dev_phase <> cv_phase_complete ) THEN
--
      -- �R���J�����g�X�e�[�^�X�ُ�I���G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_target_status_abnormal,
                     iv_token_name1  => cv_msg_tkn3,
                     iv_token_value1 => ln_req_id,
                     iv_token_name2  => cv_msg_tkn4,
                     iv_token_value2 => lv_dev_phase,
                     iv_token_name3  => cv_msg_tkn5,
                     iv_token_value3 => lv_dev_status);
--
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      lv_errbuf := lv_errmsg;
--
      RAISE submit_err_expt;
--
    ELSE
      IF ( lv_dev_status = cv_phase_error ) THEN
        -- �R���J�����g�G���[�I���G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_target_status_err,
                     iv_token_name1  => cv_msg_tkn3,
                     iv_token_value1 => ln_req_id,
                     iv_token_name2  => cv_msg_tkn4,
                     iv_token_value2 => lv_dev_phase,
                     iv_token_name3  => cv_msg_tkn5,
                     iv_token_value3 => lv_dev_status);
--
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
--
        lv_errbuf := lv_errmsg;
--
        RAISE submit_err_expt;
--
      ELSIF ( lv_dev_status = cv_phase_warning ) THEN
--
        -- �R���J�����g�x���I���G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_target_status_warning,
                     iv_token_name1  => cv_msg_tkn3,
                     iv_token_value1 => ln_req_id,
                     iv_token_name2  => cv_msg_tkn4,
                     iv_token_value2 => lv_dev_phase,
                     iv_token_name3  => cv_msg_tkn5,
                     iv_token_value3 => lv_dev_status);
--
        -- �x�������J�E���g
        gn_warn_cnt := gn_warn_cnt + 1;
--
        lv_errbuf := lv_errmsg;
--
        RAISE submit_warn_expt;
--
      ELSIF ( lv_dev_status = cv_phase_normal ) THEN
        -- ���팏���J�E���g
        gn_normal_cnt := gn_normal_cnt + 1;
--
      ELSE
--
        -- �R���J�����g�ُ�I���G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_target_status_abnormal,
                     iv_token_name1  => cv_msg_tkn3,
                     iv_token_value1 => ln_req_id,
                     iv_token_name2  => cv_msg_tkn4,
                     iv_token_value2 => lv_dev_phase,
                     iv_token_name3  => cv_msg_tkn5,
                     iv_token_value3 => lv_dev_status);
--
        -- �G���[�����J�E���g
        gn_error_cnt := gn_error_cnt + 1;
--
        lv_errbuf := lv_errmsg;
--
        RAISE submit_err_expt;
--
      END IF;
    END IF;
--
  EXCEPTION
--
    -- *** �R���J�����g�N��������O�n���h�� ***
    WHEN submit_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN submit_warn_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END submit_concurrent;
--
  /**********************************************************************************
   * Procedure Name   : edit_param_processdate
   * Description      : �p�����[�^�ҏW����(PROCESSDATE!�̏ꍇ)
   ***********************************************************************************/
  PROCEDURE edit_param_processdate(
    iv_args                  IN  VARCHAR2,                                           -- 1.���̓p�����[�^
    ov_edit_value            OUT VARCHAR2,                                           -- 2.�ҏW��p�����[�^
    ov_errbuf                OUT VARCHAR2,                                           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,                                           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)                                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_param_processdate'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    ld_date                  DATE;                               -- �Ɩ����t
    lv_format                VARCHAR2(100) DEFAULT NULL;         -- �t�H�[�}�b�g
    ln_position              NUMBER DEFAULT 0;                   -- �����ʒu
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �Ɩ����t�擾
    ld_date := xxccp_common_pkg2.get_process_date;
--
    -- �����擾
    ln_position := INSTR(iv_args, cv_processdate);
    lv_format := REPLACE(REPLACE(SUBSTR(iv_args, ln_position + LENGTH(cv_processdate)),'('),')');
--
    -- ���t�Z�o
    ov_edit_value := TO_CHAR(ld_date, lv_format);
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
  END edit_param_processdate;
--
  /**********************************************************************************
   * Procedure Name   : edit_param_asterisk
   * Description      : �p�����[�^�ҏW����(*--*�̏ꍇ)
   ***********************************************************************************/
  PROCEDURE edit_param_asterisk(
    it_set_id                IN  fnd_descr_flex_col_usage_vl.flex_value_set_id%TYPE,   -- 1.�l�Z�b�gID
    it_seq_num               IN  fnd_descr_flex_col_usage_vl.column_seq_num%TYPE,      -- 2.�p�����[�^����
    iv_args                  IN  VARCHAR2,                                             -- 3.���̓p�����[�^
-- 2009/03/10 ADD START
    i_param_info_tab         IN  g_param_info_ttype,                                   -- 4.�p�����[�^��`���
    i_edit_param_info_tab    IN  g_edit_param_info_ttype,                              -- 5.�ҏW��p�����[�^
    in_target_param_cnt      IN  NUMBER,                                               -- 6.�p�����[�^��
-- 2009/03/10 ADD END
    ov_edit_value            OUT VARCHAR2,                                             -- 7.�ҏW�l
    ov_errbuf                OUT VARCHAR2,                                             -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,                                             -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)                                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_param_asterisk'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    -- �\���؏��
    lt_id_column_name           fnd_flex_validation_tables.id_column_name%TYPE;               -- ID����
    lt_value_column_name        fnd_flex_validation_tables.value_column_name%TYPE;            -- �l����
    lt_application_table_name   fnd_flex_validation_tables.application_table_name%TYPE;       -- �Q�ƃe�[�u����
    lt_additional_where_clause  fnd_flex_validation_tables.additional_where_clause%TYPE;      -- WHERE�����
--
    -- �v���t�@�C�����
    lt_profile_name_t           fnd_profile_options.profile_option_name%TYPE DEFAULT NULL;    -- �v���t�@�C����(�Q�ƃe�[�u��)
    lv_profile_value_t          VARCHAR2(255) DEFAULT NULL;                                   -- �v���t�@�C���l(�Q�ƃe�[�u��)
    lt_profile_name_w           fnd_profile_options.profile_option_name%TYPE DEFAULT NULL;    -- �v���t�@�C����(WHERE����)
    lv_profile_value_w          VARCHAR2(255) DEFAULT NULL;                                   -- �v���t�@�C���l(WHERE����)
--
    -- ���ISQL�p
    lv_edit_select              VARCHAR2(10000) DEFAULT NULL;                                 -- SELECT��
    lv_edit_table               VARCHAR2(10000) DEFAULT NULL;                                 -- �Q�ƃe�[�u��
    lv_edit_where               VARCHAR2(10000) DEFAULT NULL;                                 -- WHERE�����
    lv_edit_where_tmp           VARCHAR2(10000) DEFAULT NULL;                                 -- WHERE�����
    lv_sql                      VARCHAR2(32767) DEFAULT NULL;                                 -- SQL��
    li_cid                      INTEGER;
    li_row                      INTEGER;
    l_sql_val_tab               DBMS_SQL.VARCHAR2_TABLE;
--
    -- *** ���[�J���E��O���� ***
    edit_param_asterisk_expt    EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------
    -- �\���؏��擾
    ------------------------------
    SELECT  ffvt.id_column_name           AS id_column_name              -- ID����
           ,ffvt.value_column_name        AS value_column_name           -- �l����
           ,ffvt.application_table_name   AS application_table_name      -- �Q�ƃe�[�u����
           ,ffvt.additional_where_clause  AS additional_where_clause     -- WHERE�����
    INTO    lt_id_column_name
           ,lt_value_column_name
           ,lt_application_table_name
           ,lt_additional_where_clause
    FROM   fnd_flex_validation_tables     ffvt                           -- �l�Z�b�g
    WHERE  ffvt.flex_value_set_id         = it_set_id
    ;
--
    ------------------------------
    -- SQL������
    ------------------------------
    -- SELECT��ҏW
    IF ( lt_id_column_name IS NULL ) THEN
      lv_edit_select := lt_value_column_name;
    ELSE
      lv_edit_select := lt_id_column_name;
    END IF;
--
    -- �Q�ƃe�[�u�����ҏW
    IF ( INSTR(lt_application_table_name, cv_profile) > 0 ) THEN
      -- �v���t�@�C�����̎擾
      get_profile_name(
        iv_value         => lt_application_table_name,
        ov_value         => lt_profile_name_t,
        ov_errbuf        => lv_errbuf,
        ov_retcode       => lv_retcode,
        ov_errmsg        => lv_errmsg);
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE edit_param_asterisk_expt;
      END IF;
--
      -- �v���t�@�C���l�擾
      lv_profile_value_t := FND_PROFILE.VALUE(lt_profile_name_t);
--
      -- �u������
      lv_edit_table := REPLACE(lt_application_table_name, cv_profile || lt_profile_name_t, '''' || lv_profile_value_t || '''');
--
    ELSE
      lv_edit_table := lt_application_table_name;
    END IF;
--
    -- WHERE������ҏW
    IF ( lt_additional_where_clause IS NULL ) THEN
--
      lv_edit_where := NULL;
--
    ELSE
--
      lv_edit_where_tmp := REPLACE(SUBSTR(lt_additional_where_clause, 1, 10000), CHR(10), ' ');
--
      IF ( INSTR(UPPER(LTRIM(lv_edit_where_tmp)), 'ORDER BY') = 1 ) THEN
        -- WHERE�����������AORDER BY��̂ݐݒ肳��Ă���ꍇ
        lv_edit_where := lv_edit_where_tmp;
--
      ELSE
-- 2009/03/10 ADD START
        IF ( INSTR(UPPER(LTRIM(lv_edit_where_tmp)), 'WHERE ') = 1 ) THEN
          -- �擪��"WHERE "�����݂���ꍇ�A�폜
          lv_edit_where_tmp := SUBSTR(LTRIM(lv_edit_where_tmp), 6);
        END IF;
-- 2009/03/10 ADD END
--
        IF ( INSTR(lv_edit_where_tmp, cv_profile) > 0 ) THEN
          -- �v���t�@�C�����̎擾
          get_profile_name(
            iv_value         => lv_edit_where_tmp,
            ov_value         => lt_profile_name_w,
            ov_errbuf        => lv_errbuf,
            ov_retcode       => lv_retcode,
            ov_errmsg        => lv_errmsg);
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_param_asterisk_expt;
          END IF;
--
          -- �v���t�@�C���l�擾
          lv_profile_value_w := FND_PROFILE.VALUE(lt_profile_name_w);
--
          -- �u������
          lv_edit_where := ' AND ' || REPLACE(lv_edit_where_tmp, cv_profile || lt_profile_name_w, lv_profile_value_w);
--
        ELSE
          lv_edit_where := ' AND ' || lv_edit_where_tmp;
        END IF;
--
      END IF;
--
    END IF;
--
-- 2009/03/10 ADD START
    ------------------------------
    -- :$FLEX$.<�l�Z�b�g��>�̒u��
    ------------------------------
    IF (    ( INSTR(lv_edit_select, cv_flex) > 0 )
         OR ( INSTR(lv_edit_table, cv_flex) > 0 )
         OR ( INSTR(lt_value_column_name, cv_flex) > 0 )
         OR ( INSTR(lv_edit_where, cv_flex) > 0 ) )
    THEN
      <<flex_change_loop>>
      FOR i IN 1..in_target_param_cnt LOOP
        -- SELECT���":$FLEX$.<�l�Z�b�g��>"�����݂���ꍇ�A�ҏW��̒l�ɒu��
        IF ( INSTR(lv_edit_select, cv_flex || i_param_info_tab(i).flex_value_set_name) > 0 ) THEN
           -- �u������
         replace_data(
             iv_before_data   => lv_edit_select
            ,iv_search_val    => cv_flex || i_param_info_tab(i).flex_value_set_name
            ,iv_replace_val   => cv_single_quote || i_edit_param_info_tab(i) || cv_single_quote
            ,ov_after_data    => lv_edit_select
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          -- �G���[����
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_param_asterisk_expt;
          END IF;
        END IF;
--
        -- FROM���":$FLEX$.<�l�Z�b�g��>"�����݂���ꍇ�A�ҏW��̒l�ɒu��
        IF ( INSTR(lv_edit_table, cv_flex || i_param_info_tab(i).flex_value_set_name) > 0 ) THEN
          -- �u������
          replace_data(
             iv_before_data   => lv_edit_table
            ,iv_search_val    => cv_flex || i_param_info_tab(i).flex_value_set_name
            ,iv_replace_val   => cv_single_quote || i_edit_param_info_tab(i) || cv_single_quote
            ,ov_after_data    => lv_edit_table
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          -- �G���[����
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_param_asterisk_expt;
          END IF;
        END IF;
--
        -- VALUE_COLUMN_NAME��":$FLEX$.<�l�Z�b�g��>"�����݂���ꍇ�A�ҏW��̒l�ɒu��
        IF ( INSTR(lt_value_column_name, cv_flex || i_param_info_tab(i).flex_value_set_name) > 0 ) THEN
          -- �u������
          replace_data(
             iv_before_data   => lt_value_column_name
            ,iv_search_val    => cv_flex || i_param_info_tab(i).flex_value_set_name
            ,iv_replace_val   => cv_single_quote || i_edit_param_info_tab(i) || cv_single_quote
            ,ov_after_data    => lt_value_column_name
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          -- �G���[����
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_param_asterisk_expt;
          END IF;
        END IF;
--
        -- WHERE��ȍ~��":$FLEX$.<�l�Z�b�g��>"�����݂���ꍇ�A�ҏW��̒l�ɒu��
        IF ( INSTR(lv_edit_where, cv_flex || i_param_info_tab(i).flex_value_set_name) > 0 ) THEN
          -- �u������
          replace_data(
             iv_before_data   => lv_edit_where
            ,iv_search_val    => cv_flex || i_param_info_tab(i).flex_value_set_name
            ,iv_replace_val   => cv_single_quote || i_edit_param_info_tab(i) || cv_single_quote
            ,ov_after_data    => lv_edit_where
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          -- �G���[����
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_param_asterisk_expt;
          END IF;
        END IF;
      END LOOP flex_change_loop ;
    END IF;
-- 2009/03/10 ADD END
--
    -- SQL�쐬
    lv_sql :=    ' SELECT '|| lv_edit_select
              || ' FROM '  || lv_edit_table
              || ' WHERE ' || lt_value_column_name || ' = ''' || REPLACE(iv_args, cv_asterisk) || ''''
                           || lv_edit_where;
--
    ------------------------------
    -- SQL�����s
    ------------------------------
    li_cid := DBMS_SQL.open_cursor;
    DBMS_SQL.parse(li_cid, lv_sql, DBMS_SQL.native);
    DBMS_SQL.define_array(li_cid, 1, l_sql_val_tab, 2, 1);
    li_row := DBMS_SQL.execute(li_cid);
    li_row := DBMS_SQL.fetch_rows(li_cid);
    DBMS_SQL.column_value(li_cid, 1, l_sql_val_tab);
--
    IF ( l_sql_val_tab.COUNT = 0 ) THEN
--
      -- �\���؂̒l���s�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_no_data_value_set,
                     iv_token_name1  => cv_msg_tkn1,
                     iv_token_value1 => it_seq_num,
                     iv_token_name2  => cv_msg_tkn2,
                     iv_token_value2 => lv_sql);
--
      lv_errbuf := lv_errmsg;
--
      RAISE edit_param_asterisk_expt;
--
    ELSIF ( l_sql_val_tab.COUNT = 1 ) THEN
--
      -- ���펞
      ov_edit_value := l_sql_val_tab(1);
--
    ELSE
--
      -- �\���؂̒l�������G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_too_many_value_set,
                     iv_token_name1  => cv_msg_tkn1,
                     iv_token_value1 => it_seq_num,
                     iv_token_name2  => cv_msg_tkn2,
                     iv_token_value2 => lv_sql);
--
      lv_errbuf := lv_errmsg;
--
      RAISE edit_param_asterisk_expt;
--
    END IF;
--
    -- �J�[�\���N���[�Y
    DBMS_SQL.close_cursor(li_cid);
--
  EXCEPTION
    
    -- *** �p�����[�^�ҏW������O�n���h�� ****
    WHEN edit_param_asterisk_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- �J�[�\���N���[�Y
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- �J�[�\���N���[�Y
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- �J�[�\���N���[�Y
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END edit_param_asterisk;
--
  /**********************************************************************************
   * PROCEDURE        : edit_param_time
   * Description      : �p�����[�^�ҏW����(�f�t�H���g�^�C�v�F���ݎ���)
   ***********************************************************************************/
  PROCEDURE edit_param_time(
    it_no                    IN  fnd_descr_flex_col_usage_vl.column_seq_num%TYPE,    -- 1.�p�����[�^����
    it_set_id                IN  fnd_descr_flex_col_usage_vl.flex_value_set_id%TYPE, -- 2.�l�Z�b�gID
    ov_edit_value            OUT VARCHAR2,                                           -- 3.�ҏW��l
    ov_errbuf                OUT VARCHAR2,                                           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,                                           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)                                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_param_time'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    lt_format_type           fnd_flex_value_sets.format_type%TYPE DEFAULT NULL;      -- �����^�C�v
    lt_maximum_size          fnd_flex_value_sets.maximum_size%TYPE DEFAULT NULL;     -- �ő�T�C�Y
    lv_format                VARCHAR2(100) DEFAULT NULL;                             -- ����
--
    -- *** ���[�J���E��O���� ***
    edit_param_time_expt      EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------
    -- �������̎擾
    ------------------------------
    get_format_info(
      it_set_id        => it_set_id,
      ot_format_type   => lt_format_type,
      ot_maximum_size  => lt_maximum_size,
      ov_errbuf        => lv_errbuf,
      ov_retcode       => lv_retcode,
      ov_errmsg        => lv_errmsg);
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE edit_param_time_expt;
    END IF;
--
    ------------------------------
    -- ���t�����擾
    ------------------------------
    IF ( lt_format_type = cv_format_type_y ) THEN
--
      ov_edit_value := TO_CHAR(cd_sysdate, cv_format1);
--
    ELSIF ( lt_format_type = cv_format_type_t ) THEN
--
      IF ( lt_maximum_size = 20 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format2);
--
      ELSIF ( lt_maximum_size = 18 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format3);
--
      ELSIF ( lt_maximum_size = 17 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format4);
--
      ELSIF ( lt_maximum_size = 15 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format5);
--
      END IF;
--
    ELSIF ( lt_format_type = cv_format_type_i ) THEN
--
      IF ( lt_maximum_size = 8 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format6);
--
      END IF;
--
      IF ( lt_maximum_size = 5 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format7);
--
      END IF;
--
    ELSIF ( lt_format_type = cv_format_type_c ) THEN
--
      IF ( lt_maximum_size >= 20 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format2);
--
      ELSIF ( lt_maximum_size = 18 OR lt_maximum_size = 19 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format3);
--
      ELSIF ( lt_maximum_size = 17 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format4);
--
      ELSIF ( lt_maximum_size = 15 OR lt_maximum_size = 16 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format5);
--
      ELSIF ( lt_maximum_size >= 8 AND lt_maximum_size <= 14 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format8);
--
      ELSIF ( lt_maximum_size >= 5 AND lt_maximum_size <= 7 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format9);
--
      ELSE
--
        ov_edit_value := NULL;
--
      END IF;
--
    ELSE
--
      -- ���t�����擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_no_format_data,
                     iv_token_name1  => cv_msg_tkn7,
                     iv_token_value1 => it_no);
--
      lv_errbuf := lv_errmsg;
--
      RAISE edit_param_time_expt ;
    END IF;
--
--
  EXCEPTION
    -- *** �p�����[�^�ҏW����(�f�t�H���g�^�C�v�F���ݎ���)������O�n���h�� ****
    WHEN edit_param_time_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END edit_param_time;
--
  /**********************************************************************************
   * PROCEDURE Name   : edit_param_date
   * Description      : �p�����[�^�ҏW����(�f�t�H���g�^�C�v�F���ݓ�)
   ***********************************************************************************/
  PROCEDURE edit_param_date(
    it_no                    IN  fnd_descr_flex_col_usage_vl.column_seq_num%TYPE,    -- 1.�p�����[�^����
    it_set_id                IN  fnd_descr_flex_col_usage_vl.flex_value_set_id%TYPE, -- 2.�l�Z�b�gID
    ov_edit_value            OUT VARCHAR2,                                           -- 3.�ԋp�l
    ov_errbuf                OUT VARCHAR2,                                           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,                                           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)                                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_param_date'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    lt_format_type           fnd_flex_value_sets.format_type%TYPE DEFAULT NULL;      -- �����^�C�v
    lt_maximum_size          fnd_flex_value_sets.maximum_size%TYPE DEFAULT NULL;     -- �ő�T�C�Y
    lv_format                VARCHAR2(100) DEFAULT NULL;                             -- ����
--
    -- *** ���[�J���E��O���� ***
    edit_param_date_expt      EXCEPTION;
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
    ------------------------------
    -- �������̎擾
    ------------------------------
    get_format_info(
      it_set_id        => it_set_id,
      ot_format_type   => lt_format_type,
      ot_maximum_size  => lt_maximum_size,
      ov_errbuf        => lv_errbuf,
      ov_retcode       => lv_retcode,
      ov_errmsg        => lv_errmsg);
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE edit_param_date_expt;
    END IF;
--
    ------------------------------
    -- ���t�����擾
    ------------------------------
    IF ( lt_format_type = cv_format_type_x ) THEN
--
      ov_edit_value := TO_CHAR(TRUNC(cd_sysdate), cv_format1);
--
    ELSIF ( lt_format_type = cv_format_type_y ) THEN
--
      ov_edit_value := TO_CHAR(cd_sysdate, cv_format1);
--
    ELSIF ( lt_format_type = cv_format_type_d ) THEN
--
      IF ( lt_maximum_size = 11 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format10);
--
      END IF;
--
      IF ( lt_maximum_size = 9 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format11);
--
      END IF;
--
    ELSIF ( lt_format_type = cv_format_type_c ) THEN
--
      IF ( lt_maximum_size >= 11 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format10);
--
      ELSIF ( lt_maximum_size = 9 OR lt_maximum_size = 10 ) THEN
--
        ov_edit_value := TO_CHAR(cd_sysdate, cv_format11);
--
      ELSE
--
        ov_edit_value := NULL;
--
      END IF;
--
    ELSE
--
      -- ���t�����擾�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_no_format_data,
                     iv_token_name1  => cv_msg_tkn7,
                     iv_token_value1 => it_no);
--
      lv_errbuf := lv_errmsg;
--
      RAISE edit_param_date_expt ;
--
    END IF;
--
--
  EXCEPTION
    -- *** �p�����[�^�ҏW����(�f�t�H���g�^�C�v�F���ݓ�)������O�n���h�� ****
    WHEN edit_param_date_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END edit_param_date;
--
  /**********************************************************************************
   * Procedure Name   : edit_param_sql
   * Description      : �p�����[�^�ҏW����(�f�t�H���g�^�C�v�FSQL)
   ***********************************************************************************/
  PROCEDURE edit_param_sql(
    it_default_value         IN  fnd_descr_flex_col_usage_vl.default_value%TYPE,     -- 1.�f�t�H���g�l
    it_col_num               IN  fnd_descr_flex_col_usage_vl.column_seq_num%TYPE,    -- 2.����
-- 2009/03/10 ADD START
    i_param_info_tab         IN  g_param_info_ttype,                                 -- 3.�p�����[�^��`���
    i_edit_param_info_tab    IN  g_edit_param_info_ttype,                            -- 4.�ҏW��p�����[�^
    in_target_param_cnt      IN  NUMBER,                                             -- 5.�p�����[�^��
-- 2009/03/10 ADD END
    ov_edit_value            OUT VARCHAR2,                                           -- 6.�ҏW�l
    ov_errbuf                OUT VARCHAR2,                                           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode               OUT VARCHAR2,                                           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                OUT VARCHAR2)                                           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_param_sql'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    ln_position_pro          NUMBER DEFAULT 0 ;                                              -- '$PROFILE$'�����񌟍��ʒu
    lt_default_value_tmp     fnd_descr_flex_col_usage_vl.default_value%TYPE DEFAULT NULL ;   -- ���[�N�f�t�H���g�l
    lt_profile_name          fnd_profile_options.profile_option_name%TYPE DEFAULT NULL ;     -- �v���t�@�C����
    lv_profile_value         VARCHAR2(255) DEFAULT NULL;                                     -- �v���t�@�C���ԋp�l
--
    -- ���ISQL�p
    li_cid                   INTEGER;
    li_row                   INTEGER;
    lv_sql                   VARCHAR2(32767) DEFAULT NULL;
    l_sql_val_tab            DBMS_SQL.VARCHAR2_TABLE;
--
    -- *** ���[�J���E��O���� ***
    edit_param_sql_expt      EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------
    -- SQL������
    ------------------------------
    ln_position_pro := INSTR(it_default_value, cv_profile) ;
--
    IF ( ln_position_pro > 0 ) THEN
--
      get_profile_name(
        iv_value         => it_default_value,
        ov_value         => lt_profile_name,
        ov_errbuf        => lv_errbuf,
        ov_retcode       => lv_retcode,
        ov_errmsg        => lv_errmsg);
--
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE edit_param_sql_expt;
      END IF;
--
      -- �v���t�@�C���l�擾
      lv_profile_value := FND_PROFILE.VALUE(
                            name => lt_profile_name);
      -- SQL���쐬
      lv_sql := REPLACE(it_default_value, cv_profile || lt_profile_name, '''' || lv_profile_value || '''');
    ELSE
      lv_sql := it_default_value ;
    END IF ;
-- 2009/03/10 ADD START
    ------------------------------
    -- :$FLEX$.<�l�Z�b�g��>�̒u��
    ------------------------------
    IF INSTR(lv_sql, cv_flex) > 0 THEN
      <<change_flex_loop>>
      FOR i IN 1..in_target_param_cnt LOOP
        -- �f�t�H���gSQL��":$FLEX$.<�l�Z�b�g��>"�����݂���ꍇ�A�ҏW��̒l�ɒu��
        IF ( INSTR(lv_sql, cv_flex || i_param_info_tab(i).flex_value_set_name) > 0 ) THEN
          -- �u������
          replace_data(
             iv_before_data   => lv_sql
            ,iv_search_val    => cv_flex || i_param_info_tab(i).flex_value_set_name
            ,iv_replace_val   => cv_single_quote || i_edit_param_info_tab(i) || cv_single_quote
            ,ov_after_data    => lv_sql
            ,ov_errbuf        => lv_errbuf
            ,ov_retcode       => lv_retcode
            ,ov_errmsg        => lv_errmsg
          );
          --�G���[����
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE edit_param_sql_expt;
          END IF;
        END IF;
      END LOOP change_flex_loop ;
    END IF;
-- 2009/03/10 ADD END
--
    ------------------------------
    -- SQL���s
    ------------------------------
    li_cid := DBMS_SQL.open_cursor;
    DBMS_SQL.parse(li_cid, lv_sql, DBMS_SQL.native);
    DBMS_SQL.define_array(li_cid, 1, l_sql_val_tab, 2, 1);
    li_row := DBMS_SQL.execute(li_cid);
    li_row := DBMS_SQL.fetch_rows(li_cid);
    DBMS_SQL.column_value(li_cid, 1, l_sql_val_tab);
--
    IF ( l_sql_val_tab.COUNT = 0 ) THEN
--
      -- �f�t�H���g�l0���G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_no_data_default_value,
                     iv_token_name1  => cv_msg_tkn1,
                     iv_token_value1 => it_col_num,
                     iv_token_name2  => cv_msg_tkn2,
                     iv_token_value2 => lv_sql);
--
      lv_errbuf := lv_errmsg;
--
      RAISE edit_param_sql_expt ;
--
    ELSIF ( l_sql_val_tab.COUNT = 1 ) THEN
--
      ov_edit_value := l_sql_val_tab(1);
--
    ELSE
--
      -- �f�t�H���g�l�������G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application,
                     iv_name         => cv_msg_too_many_default_value,
                     iv_token_name1  => cv_msg_tkn1,
                     iv_token_value1 => it_col_num,
                     iv_token_name2  => cv_msg_tkn2,
                     iv_token_value2 => lv_sql);
--
      lv_errbuf := lv_errmsg;
--
      RAISE edit_param_sql_expt ;
--
    END IF;
--
    -- �J�[�\���N���[�Y
    DBMS_SQL.close_cursor(li_cid);
--
  EXCEPTION
    -- *** �p�����[�^�ҏW����(�f�t�H���g�^�C�v�FSQL)������O�n���h�� ****
    WHEN edit_param_sql_expt THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- �J�[�\���N���[�Y
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- �J�[�\���N���[�Y
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- �J�[�\���N���[�Y
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF ( DBMS_SQL.is_open(li_cid) ) THEN
        -- �J�[�\���N���[�Y
        DBMS_SQL.close_cursor(li_cid);
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END edit_param_sql;
--
  /**********************************************************************************
   * Procedure Name   : get_edit_param_info
   * Description      : ���I�p�����[�^�l�Z�o����
   ***********************************************************************************/
  PROCEDURE get_edit_param_info(
    iv_app_name            IN     VARCHAR2,                                          -- 1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_prg_name            IN     VARCHAR2,                                          -- 2.�N���΃R���J�����g�Z�k��
    i_args_info_tab        IN     g_args_info_ttype,                                 -- 3.���̓p�����[�^
    io_edit_param_info_tab IN OUT g_edit_param_info_ttype,                           -- 4.�ҏW��p�����[�^
    on_target_param_cnt    OUT    NUMBER,                                            -- 5.�p�����[�^��
    ov_errbuf              OUT    VARCHAR2,                                          -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode             OUT    VARCHAR2,                                          -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg              OUT    VARCHAR2)                                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_edit_param_info'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- *** ���[�J���ϐ� ***
    lv_edit_value            VARCHAR2(2000) DEFAULT NULL ;                          -- �ҏW��p�����[�^
--
-- 2009/03/10 UPDATE START
--    TYPE l_param_info_rtype IS RECORD(
--       default_type          fnd_descr_flex_col_usage_vl.default_type%TYPE          -- �f�t�H���g�^�C�v
--      ,default_value         fnd_descr_flex_col_usage_vl.default_value%TYPE         -- �f�t�H���g�l
--      ,set_id                fnd_descr_flex_col_usage_vl.flex_value_set_id%TYPE     -- �l�Z�b�gID
--      ,seq_num               fnd_descr_flex_col_usage_vl.column_seq_num%TYPE        -- ����
--    ) ;
--    TYPE l_param_info_ttype IS TABLE OF l_param_info_rtype INDEX BY BINARY_INTEGER ;
--    l_param_info_tab         l_param_info_ttype ;
   l_param_info_tab            g_param_info_ttype ;
-- 2009/03/10 UPDATE END
--
    -- *** ���[�J���E��O���� ***
    get_param_info_expt      EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------
    -- �p�����[�^��`���擾
    ------------------------------
    SELECT fdfcuv.default_type              AS default_type                          -- �f�t�H���g�^�C�v
          ,fdfcuv.default_value             AS default_value                         -- �f�t�H���g�l
          ,fdfcuv.flex_value_set_id         AS flex_value_set_id                     -- �l�Z�b�gID
          ,fdfcuv.column_seq_num            AS column_seq_num                        -- ����
-- 2009/03/10 ADD START
          ,ffvs.flex_value_set_name         AS flex_value_set_name                   -- �l�Z�b�g��
-- 2009/03/10 ADD END
--
    BULK COLLECT INTO l_param_info_tab
--
    FROM   fnd_concurrent_programs_vl       fcpv                                     -- �R���J�����g�}�X�^
          ,fnd_application_vl               fav                                      -- �A�v���P�[�V�����}�X�^
          ,fnd_descr_flex_col_usage_vl      fdfcuv                                   -- �R���J�����g�p�����[�^�}�X�^
-- 2009/03/10 ADD START
          ,fnd_flex_value_sets              ffvs                                     -- �l�Z�b�g��`�}�X�^
-- 2009/03/10 ADD END
    WHERE fav.application_short_name        = iv_app_name
      AND fav.application_id                = fcpv.application_id
      AND fcpv.concurrent_program_name      = iv_prg_name
      AND fcpv.application_id               = fdfcuv.application_id
      AND fdfcuv.descriptive_flexfield_name = cv_srs || fcpv.concurrent_program_name
      AND fdfcuv.enabled_flag               = 'Y'
-- 2009/03/10 ADD START
      AND fdfcuv.flex_value_set_id          = ffvs.flex_value_set_id
-- 2009/03/10 ADD END
    ORDER BY fdfcuv.column_seq_num
    ;
--
    -- �p�����[�^���̃Z�b�g
    on_target_param_cnt := l_param_info_tab.COUNT;
--
    IF ( on_target_param_cnt = 0 ) THEN
--
      -- �p�����[�^0�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_application,
                     iv_name        => cv_msg_param_not_found);
--
      lv_errbuf := lv_errmsg;
--
      RAISE get_param_info_expt ;
    END IF ;
--
-- 2009/03/10 ADD START
    IF ( l_param_info_tab.COUNT > i_args_info_tab.COUNT ) THEN
      -- �p�����[�^���������̌��ɕύX
      on_target_param_cnt := i_args_info_tab.COUNT;
      -- �p�����[�^���������߃G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_application,
                     iv_name        => cv_msg_param_max_over);
      lv_errbuf := lv_errmsg;
      RAISE get_param_info_expt ;
    END IF;
-- 2009/03/10 ADD END
--
    ------------------------------
    -- �p�����[�^�ҏW����
    ------------------------------
    <<param_cnt_loop>>
    FOR i IN 1..l_param_info_tab.COUNT LOOP
--
      -- ������
      lv_edit_value := NULL;
--
-- 2009/03/10 UPDATE START
--      IF ( i_args_info_tab(i) = cv_default) THEN
      IF ( i_args_info_tab(i) = cv_default OR i_args_info_tab(i) = cv_asterisk || cv_default || cv_asterisk ) THEN
-- 2009/03/10 UPDATE END
--
        IF ( l_param_info_tab(i).default_type = cv_default_type_sql ) THEN
          -- �f�t�H���g�^�C�v�FSQL
-- 2009/03/10 UPDATE START
--          edit_param_sql(
--            it_default_value => l_param_info_tab(i).default_value,                   -- �f�t�H���g�l
--            it_col_num       => l_param_info_tab(i).seq_num,                         -- ��������
--            ov_edit_value    => lv_edit_value,                                       -- �ҏW��p�����[�^
--            ov_errbuf        => lv_errbuf,                                           -- �G���[�E���b�Z�[�W           --# �Œ� #
--            ov_retcode       => lv_retcode,                                          -- ���^�[���E�R�[�h             --# �Œ� #
--            ov_errmsg        => lv_errmsg);                                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          edit_param_sql(
            it_default_value      => l_param_info_tab(i).default_value,              -- �f�t�H���g�l
            it_col_num            => l_param_info_tab(i).seq_num,                    -- ��������
            ov_edit_value         => lv_edit_value,                                  -- �ҏW��p�����[�^
            i_param_info_tab      => l_param_info_tab,                               -- �p�����[�^��`���
            i_edit_param_info_tab => io_edit_param_info_tab,                         -- �ҏW��p�����[�^
            in_target_param_cnt   => i - 1,                                          -- �p�����[�^��
            ov_errbuf             => lv_errbuf,                                      -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode            => lv_retcode,                                     -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg             => lv_errmsg);                                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
-- 2009/03/10 UPDATE END
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE get_param_info_expt;
          END IF;
--
        ELSIF ( l_param_info_tab(i).default_type = cv_default_type_pro ) THEN
          -- �f�t�H���g�^�C�v�F�v���t�@�C��
          lv_edit_value := FND_PROFILE.VALUE(l_param_info_tab(i).default_value);
--
        ELSIF ( l_param_info_tab(i).default_type = cv_default_type_date ) THEN
          -- �f�t�H���g�^�C�v�F���ݓ�
          edit_param_date(
            it_no            => l_param_info_tab(i).seq_num,                         -- �p�����[�^����
            it_set_id        => l_param_info_tab(i).set_id,                          -- �l�Z�b�gID
            ov_edit_value    => lv_edit_value,                                       -- �ҏW��p�����[�^
            ov_errbuf        => lv_errbuf,                                           -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode       => lv_retcode,                                          -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg        => lv_errmsg);                                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE get_param_info_expt;
          END IF;
--
        ELSIF ( l_param_info_tab(i).default_type = cv_default_type_time ) THEN
          -- �f�t�H���g�^�C�v�F���ݎ���
          edit_param_time(
            it_no            => l_param_info_tab(i).seq_num,                         -- �p�����[�^����
            it_set_id        => l_param_info_tab(i).set_id,                          -- �l�Z�b�gID
            ov_edit_value    => lv_edit_value,                                       -- �ҏW��p�����[�^
            ov_errbuf        => lv_errbuf,                                           -- �G���[�E���b�Z�[�W           --# �Œ� #
            ov_retcode       => lv_retcode,                                          -- ���^�[���E�R�[�h             --# �Œ� #
            ov_errmsg        => lv_errmsg);                                          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE get_param_info_expt;
          END IF;
--
        END IF ;
--
      ELSIF ( i_args_info_tab(i) = cv_datetime ) THEN
        -- ����n�̒l��'DATETIME'
        lv_edit_value := TO_CHAR(cd_sysdate, cv_format2);
--
      ELSIF ( i_args_info_tab(i) = cv_date ) THEN
        -- ����n�̒l��'DATE'
        lv_edit_value := TO_CHAR(cd_sysdate, cv_format10);
--
      ELSIF ( i_args_info_tab(i) = cv_time ) THEN
        -- ����n�̒l��'TIME'
        lv_edit_value := TO_CHAR(cd_sysdate, cv_format6);
--
-- 2009/03/10 DELETE START
--      ELSIF ( SUBSTR( i_args_info_tab(i), 1, 1) = cv_asterisk AND SUBSTR( i_args_info_tab(i), -1, 1) = cv_asterisk ) THEN
--        -- ����n�̒l��'*'�Ŋ����Ă���
--        edit_param_asterisk(
--          it_set_id        => l_param_info_tab(i).set_id,                            -- �l�Z�b�gID
--          it_seq_num       => l_param_info_tab(i).seq_num,                           -- �p�����[�^����
--          iv_args          => i_args_info_tab(i),                                    -- ���̓p�����[�^
--          ov_edit_value    => lv_edit_value,                                         -- �ҏW��p�����[�^
--          ov_errbuf        => lv_errbuf,                                             -- �G���[�E���b�Z�[�W           --# �Œ� #
--          ov_retcode       => lv_retcode,                                            -- ���^�[���E�R�[�h             --# �Œ� #
--          ov_errmsg        => lv_errmsg);                                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--        IF ( lv_retcode = cv_status_error ) THEN
--          RAISE get_param_info_expt;
--        END IF;
-- 2009/03/10 UPDATE END
--
      ELSIF ( INSTR( i_args_info_tab(i), cv_processdate) = 1 ) THEN
        -- ����n�̒l��'PROCESSDATE!'�Ŏn�܂��Ă���
        edit_param_processdate(
          iv_args          => i_args_info_tab(i),                                    -- ���̓p�����[�^
          ov_edit_value    => lv_edit_value,                                         -- �ҏW��p�����[�^
          ov_errbuf        => lv_errbuf,                                             -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode       => lv_retcode,                                            -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg        => lv_errmsg);                                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE get_param_info_expt;
          END IF;
--
      ELSE
        lv_edit_value := i_args_info_tab(i);
      END IF ;
--
-- 2009/03/10 ADD START
      IF ( SUBSTR( i_args_info_tab(i), 1, 1) = cv_asterisk AND SUBSTR( i_args_info_tab(i), -1, 1) = cv_asterisk ) THEN
        -- ����n�̒l��'*'�Ŋ����Ă���ꍇ�A�\���؂����s
        edit_param_asterisk(
          it_set_id             => l_param_info_tab(i).set_id,                     -- �l�Z�b�gID
          it_seq_num            => l_param_info_tab(i).seq_num,                    -- �p�����[�^����
          iv_args               => lv_edit_value,                                  -- ���̓p�����[�^
          i_param_info_tab      => l_param_info_tab,                               -- �p�����[�^��`���
          i_edit_param_info_tab => io_edit_param_info_tab,                         -- �ҏW��p�����[�^
          in_target_param_cnt   => i - 1,                                          -- �p�����[�^��
          ov_edit_value         => lv_edit_value,                                  -- �ҏW��p�����[�^
          ov_errbuf             => lv_errbuf,                                      -- �G���[�E���b�Z�[�W           --# �Œ� #
          ov_retcode            => lv_retcode,                                     -- ���^�[���E�R�[�h             --# �Œ� #
          ov_errmsg             => lv_errmsg);                                     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE get_param_info_expt;
          END IF;
--
      END IF ;
-- 2009/03/10 ADD END
      -- �ҏW��p�����[�^�Z�b�g
      io_edit_param_info_tab(i) := lv_edit_value;
--
    END LOOP param_cnt_loop ;
--
--
  EXCEPTION
    -- *** �N���ΏۃR���J�����g���擾������O�n���h�� ****
    WHEN get_param_info_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END get_edit_param_info;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_app_name   IN  VARCHAR2,     --   1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_prg_name   IN  VARCHAR2,     --   2.�N���΃R���J�����g�Z�k��
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
    -- *** ���[�J���E��O���� ***
    param_chk_expt           EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    ------------------------------
    -- �K�{�`�F�b�N
    ------------------------------
    -- �N���ΏۃA�v���P�[�V�����Z�k��
    IF ( iv_app_name IS NULL ) THEN
--
      -- �����̓G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_application,
                     iv_name        => cv_msg_app_name_err);
--
      lv_errbuf := lv_errmsg;
--
      RAISE param_chk_expt ;
    END IF ;
--
    -- �N���ΏۃR���J�����g�Z�k��
    IF ( iv_prg_name IS NULL ) THEN
--
      -- �����̓G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_application,
                     iv_name        => cv_msg_prg_name_err);
--
      lv_errbuf := lv_errmsg;
--
      RAISE param_chk_expt ;
    END IF ;
--
  EXCEPTION
    -- *** �p�����[�^�`�F�b�N��O�n���h�� ****
    WHEN param_chk_expt THEN
      ov_errmsg  := lv_errmsg ;
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
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_app_name   IN     VARCHAR2,           --  1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_prg_name   IN     VARCHAR2,           --  2.�N���ΏۃR���J�����g�Z�k��
    iv_args1      IN     VARCHAR2,           --  3.����1
    iv_args2      IN     VARCHAR2,           --  4.����2
    iv_args3      IN     VARCHAR2,           --  5.����3
    iv_args4      IN     VARCHAR2,           --  6.����4
    iv_args5      IN     VARCHAR2,           --  7.����5
    iv_args6      IN     VARCHAR2,           --  8.����6
    iv_args7      IN     VARCHAR2,           --  9.����7
    iv_args8      IN     VARCHAR2,           -- 10.����8
    iv_args9      IN     VARCHAR2,           -- 11.����9
    iv_args10     IN     VARCHAR2,           -- 12.����10
    iv_args11     IN     VARCHAR2,           -- 13.����11
    iv_args12     IN     VARCHAR2,           -- 14.����12
    iv_args13     IN     VARCHAR2,           -- 15.����13
    iv_args14     IN     VARCHAR2,           -- 16.����14
    iv_args15     IN     VARCHAR2,           -- 17.����15
    iv_args16     IN     VARCHAR2,           -- 18.����16
    iv_args17     IN     VARCHAR2,           -- 19.����17
    iv_args18     IN     VARCHAR2,           -- 20.����18
    iv_args19     IN     VARCHAR2,           -- 21.����19
    iv_args20     IN     VARCHAR2,           -- 22.����20
    iv_args21     IN     VARCHAR2,           -- 23.����21
    iv_args22     IN     VARCHAR2,           -- 24.����22
    iv_args23     IN     VARCHAR2,           -- 25.����23
    iv_args24     IN     VARCHAR2,           -- 26.����24
    iv_args25     IN     VARCHAR2,           -- 27.����25
    iv_args26     IN     VARCHAR2,           -- 28.����26
    iv_args27     IN     VARCHAR2,           -- 29.����27
    iv_args28     IN     VARCHAR2,           -- 30.����28
    iv_args29     IN     VARCHAR2,           -- 31.����29
    iv_args30     IN     VARCHAR2,           -- 32.����30
    iv_args31     IN     VARCHAR2,           -- 33.����31
    iv_args32     IN     VARCHAR2,           -- 34.����32
    iv_args33     IN     VARCHAR2,           -- 35.����33
    iv_args34     IN     VARCHAR2,           -- 36.����34
    iv_args35     IN     VARCHAR2,           -- 37.����35
    iv_args36     IN     VARCHAR2,           -- 38.����36
    iv_args37     IN     VARCHAR2,           -- 39.����37
    iv_args38     IN     VARCHAR2,           -- 40.����38
    iv_args39     IN     VARCHAR2,           -- 41.����39
    iv_args40     IN     VARCHAR2,           -- 42.����40
    iv_args41     IN     VARCHAR2,           -- 43.����41
    iv_args42     IN     VARCHAR2,           -- 44.����42
    iv_args43     IN     VARCHAR2,           -- 45.����43
    iv_args44     IN     VARCHAR2,           -- 46.����44
    iv_args45     IN     VARCHAR2,           -- 47.����45
    iv_args46     IN     VARCHAR2,           -- 48.����46
    iv_args47     IN     VARCHAR2,           -- 49.����47
    iv_args48     IN     VARCHAR2,           -- 50.����48
    iv_args49     IN     VARCHAR2,           -- 51.����49
    iv_args50     IN     VARCHAR2,           -- 52.����50
    iv_args51     IN     VARCHAR2,           -- 53.����51
    iv_args52     IN     VARCHAR2,           -- 54.����52
    iv_args53     IN     VARCHAR2,           -- 55.����53
    iv_args54     IN     VARCHAR2,           -- 56.����54
    iv_args55     IN     VARCHAR2,           -- 57.����55
    iv_args56     IN     VARCHAR2,           -- 58.����56
    iv_args57     IN     VARCHAR2,           -- 59.����57
    iv_args58     IN     VARCHAR2,           -- 60.����58
    iv_args59     IN     VARCHAR2,           -- 61.����59
    iv_args60     IN     VARCHAR2,           -- 62.����60
    iv_args61     IN     VARCHAR2,           -- 63.����61
    iv_args62     IN     VARCHAR2,           -- 64.����62
    iv_args63     IN     VARCHAR2,           -- 65.����63
    iv_args64     IN     VARCHAR2,           -- 66.����64
    iv_args65     IN     VARCHAR2,           -- 67.����65
    iv_args66     IN     VARCHAR2,           -- 68.����66
    iv_args67     IN     VARCHAR2,           -- 69.����67
    iv_args68     IN     VARCHAR2,           -- 70.����68
    iv_args69     IN     VARCHAR2,           -- 71.����69
    iv_args70     IN     VARCHAR2,           -- 72.����70
    iv_args71     IN     VARCHAR2,           -- 73.����71
    iv_args72     IN     VARCHAR2,           -- 74.����72
    iv_args73     IN     VARCHAR2,           -- 75.����73
    iv_args74     IN     VARCHAR2,           -- 76.����74
    iv_args75     IN     VARCHAR2,           -- 77.����75
    iv_args76     IN     VARCHAR2,           -- 78.����76
    iv_args77     IN     VARCHAR2,           -- 79.����77
    iv_args78     IN     VARCHAR2,           -- 80.����78
    iv_args79     IN     VARCHAR2,           -- 81.����79
    iv_args80     IN     VARCHAR2,           -- 82.����80
    iv_args81     IN     VARCHAR2,           -- 83.����81
    iv_args82     IN     VARCHAR2,           -- 84.����82
    iv_args83     IN     VARCHAR2,           -- 85.����83
    iv_args84     IN     VARCHAR2,           -- 86.����84
    iv_args85     IN     VARCHAR2,           -- 87.����85
    iv_args86     IN     VARCHAR2,           -- 88.����86
    iv_args87     IN     VARCHAR2,           -- 89.����87
    iv_args88     IN     VARCHAR2,           -- 90.����88
    iv_args89     IN     VARCHAR2,           -- 91.����89
    iv_args90     IN     VARCHAR2,           -- 92.����90
    iv_args91     IN     VARCHAR2,           -- 93.����91
    iv_args92     IN     VARCHAR2,           -- 94.����92
    iv_args93     IN     VARCHAR2,           -- 95.����93
    iv_args94     IN     VARCHAR2,           -- 96.����94
    iv_args95     IN     VARCHAR2,           -- 97.����95
    iv_args96     IN     VARCHAR2,           -- 98.����96
    iv_args97     IN     VARCHAR2,           -- 99.����97
    iv_args98     IN     VARCHAR2,           --100.����98
    ov_errbuf     OUT    VARCHAR2,           -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT    VARCHAR2,           -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT    VARCHAR2)           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    ln_target_param_cnt     NUMBER                                                        DEFAULT 0 ;    -- �p�����[�^��
    lt_app_id               fnd_descr_flex_col_usage_vl.application_id%TYPE               DEFAULT NULL ; -- �A�v���P�[�V����ID
    lt_field_name           fnd_descr_flex_col_usage_vl.descriptive_flexfield_name%TYPE   DEFAULT NULL ; -- �t�B�[���h��
    l_args_info_tab         g_args_info_ttype ;                                                          -- ���̓p�����[�^
    l_edit_param_info_tab   g_edit_param_info_ttype;                                                     -- �ҏW��p�����[�^
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
    --  ���̓p�����[�^�Z�b�g
    -- ===============================
    l_args_info_tab(1)  := iv_args1 ;
    l_args_info_tab(2)  := iv_args2 ;
    l_args_info_tab(3)  := iv_args3 ;
    l_args_info_tab(4)  := iv_args4 ;
    l_args_info_tab(5)  := iv_args5 ;
    l_args_info_tab(6)  := iv_args6 ;
    l_args_info_tab(7)  := iv_args7 ;
    l_args_info_tab(8)  := iv_args8 ;
    l_args_info_tab(9)  := iv_args9 ;
    l_args_info_tab(10) := iv_args10 ;
    l_args_info_tab(11) := iv_args11 ;
    l_args_info_tab(12) := iv_args12 ;
    l_args_info_tab(13) := iv_args13 ;
    l_args_info_tab(14) := iv_args14 ;
    l_args_info_tab(15) := iv_args15 ;
    l_args_info_tab(16) := iv_args16 ;
    l_args_info_tab(17) := iv_args17 ;
    l_args_info_tab(18) := iv_args18 ;
    l_args_info_tab(19) := iv_args19 ;
    l_args_info_tab(20) := iv_args20 ;
    l_args_info_tab(21) := iv_args21 ;
    l_args_info_tab(22) := iv_args22 ;
    l_args_info_tab(23) := iv_args23 ;
    l_args_info_tab(24) := iv_args24 ;
    l_args_info_tab(25) := iv_args25 ;
    l_args_info_tab(26) := iv_args26 ;
    l_args_info_tab(27) := iv_args27 ;
    l_args_info_tab(28) := iv_args28 ;
    l_args_info_tab(29) := iv_args29 ;
    l_args_info_tab(30) := iv_args30 ;
    l_args_info_tab(31) := iv_args31 ;
    l_args_info_tab(32) := iv_args32 ;
    l_args_info_tab(33) := iv_args33 ;
    l_args_info_tab(34) := iv_args34 ;
    l_args_info_tab(35) := iv_args35 ;
    l_args_info_tab(36) := iv_args36 ;
    l_args_info_tab(37) := iv_args37 ;
    l_args_info_tab(38) := iv_args38 ;
    l_args_info_tab(39) := iv_args39 ;
    l_args_info_tab(40) := iv_args40 ;
    l_args_info_tab(41) := iv_args41 ;
    l_args_info_tab(42) := iv_args42 ;
    l_args_info_tab(43) := iv_args43 ;
    l_args_info_tab(44) := iv_args44 ;
    l_args_info_tab(45) := iv_args45 ;
    l_args_info_tab(46) := iv_args46 ;
    l_args_info_tab(47) := iv_args47 ;
    l_args_info_tab(48) := iv_args48 ;
    l_args_info_tab(49) := iv_args49 ;
    l_args_info_tab(50) := iv_args50 ;
    l_args_info_tab(51) := iv_args51 ;
    l_args_info_tab(52) := iv_args52 ;
    l_args_info_tab(53) := iv_args53 ;
    l_args_info_tab(54) := iv_args54 ;
    l_args_info_tab(55) := iv_args55 ;
    l_args_info_tab(56) := iv_args56 ;
    l_args_info_tab(57) := iv_args57 ;
    l_args_info_tab(58) := iv_args58 ;
    l_args_info_tab(59) := iv_args59 ;
    l_args_info_tab(60) := iv_args60 ;
    l_args_info_tab(61) := iv_args61 ;
    l_args_info_tab(62) := iv_args62 ;
    l_args_info_tab(63) := iv_args63 ;
    l_args_info_tab(64) := iv_args64 ;
    l_args_info_tab(65) := iv_args65 ;
    l_args_info_tab(66) := iv_args66 ;
    l_args_info_tab(67) := iv_args67 ;
    l_args_info_tab(68) := iv_args68 ;
    l_args_info_tab(69) := iv_args69 ;
    l_args_info_tab(70) := iv_args70 ;
    l_args_info_tab(71) := iv_args71 ;
    l_args_info_tab(72) := iv_args72 ;
    l_args_info_tab(73) := iv_args73 ;
    l_args_info_tab(74) := iv_args74 ;
    l_args_info_tab(75) := iv_args75 ;
    l_args_info_tab(76) := iv_args76 ;
    l_args_info_tab(77) := iv_args77 ;
    l_args_info_tab(78) := iv_args78 ;
    l_args_info_tab(79) := iv_args79 ;
    l_args_info_tab(80) := iv_args80 ;
    l_args_info_tab(81) := iv_args81 ;
    l_args_info_tab(82) := iv_args82 ;
    l_args_info_tab(83) := iv_args83 ;
    l_args_info_tab(84) := iv_args84 ;
    l_args_info_tab(85) := iv_args85 ;
    l_args_info_tab(86) := iv_args86 ;
    l_args_info_tab(87) := iv_args87 ;
    l_args_info_tab(88) := iv_args88 ;
    l_args_info_tab(89) := iv_args89 ;
    l_args_info_tab(90) := iv_args90 ;
    l_args_info_tab(91) := iv_args91 ;
    l_args_info_tab(92) := iv_args92 ;
    l_args_info_tab(93) := iv_args93 ;
    l_args_info_tab(94) := iv_args94 ;
    l_args_info_tab(95) := iv_args95 ;
    l_args_info_tab(96) := iv_args96 ;
    l_args_info_tab(97) := iv_args97 ;
    l_args_info_tab(98) := iv_args98 ;
--
    -- ===============================
    --  �ώ��p�����[�^�����l�Z�b�g
    -- ===============================
    <<param_zan_loop>>
    FOR j IN 1..98 LOOP
      -- �uCHR(0)�v���Z�b�g
      l_edit_param_info_tab(j) := CHR(0);
    END LOOP param_zan_loop;
--
    -- ===============================
    --  ��������
    -- ===============================
    init(
      iv_app_name => iv_app_name,                           -- �N���ΏۃA�v���P�[�V�����Z�k��
      iv_prg_name => iv_prg_name,                           -- �N���ΏۃR���J�����g�Z�k��
      ov_errbuf   => lv_errbuf,                             -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode  => lv_retcode,                            -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg   => lv_errmsg);                            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ===============================
    --  ���I�p�����[�^�l�Z�o����
    -- ===============================
    IF (lv_retcode = cv_status_normal) THEN
      get_edit_param_info(
        iv_app_name            => iv_app_name,              -- �N���ΏۃA�v���P�[�V�����Z�k��
        iv_prg_name            => iv_prg_name,              -- �N���ΏۃR���J�����g�Z�k��
        i_args_info_tab        => l_args_info_tab,          -- ���̓p�����[�^
        io_edit_param_info_tab => l_edit_param_info_tab,    -- �ҏW��p�����[�^
        on_target_param_cnt    => ln_target_param_cnt,      -- �p�����[�^��
        ov_errbuf              => lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode             => lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg              => lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
--
    -- ===============================
    --  �R���J�����g�N������
    -- ===============================
    IF (lv_retcode = cv_status_normal) THEN
      submit_concurrent(
        iv_application         => iv_app_name,              -- �N���ΏۃA�v���P�[�V�����Z�k��
        iv_program             => iv_prg_name,              -- �N���ΏۃR���J�����g�Z�k��
        i_edit_param_info_tab  => l_edit_param_info_tab,    -- �ҏW��p�����[�^
        ov_errbuf              => lv_errbuf,                -- �G���[�E���b�Z�[�W           --# �Œ� #
        ov_retcode             => lv_retcode,               -- ���^�[���E�R�[�h             --# �Œ� #
        ov_errmsg              => lv_errmsg);               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    END IF;
--
    -- ===============================
    --  �I������
    -- ===============================
    last(
      iv_app_name            => iv_app_name,                -- �N���ΏۃA�v���P�[�V�����Z�k��
      iv_prg_name            => iv_prg_name,                -- �N���ΏۃR���J�����g�Z�k��
      in_target_param_cnt    => ln_target_param_cnt,        -- �N���ΏۃR���J�����g�p�����[�^��
      i_edit_param_info_tab  => l_edit_param_info_tab,      -- �ҏW��p�����[�^
      iv_errbuf              => lv_errbuf,                  -- �G���[���b�Z�[�W
      iv_retcode             => lv_retcode,                 -- ���^�[���E�R�[�h
      iv_errmsg              => lv_errmsg,                  -- ���[�U�[�E�G���[�E���b�Z�[�W
      ov_errbuf              => lv_errbuf,                  -- �G���[�E���b�Z�[�W           --# �Œ� #
      ov_retcode             => lv_retcode,                 -- ���^�[���E�R�[�h             --# �Œ� #
      ov_errmsg              => lv_errmsg);                 -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      ov_retcode := lv_retcode;
--
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
    errbuf        OUT    VARCHAR2,                        --  �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,                        --  �G���[�R�[�h     #�Œ�#
    iv_app_name   IN     VARCHAR2 DEFAULT NULL,           --  1.�N���ΏۃA�v���P�[�V�����Z�k��
    iv_prg_name   IN     VARCHAR2 DEFAULT NULL,           --  2.�N���ΏۃR���J�����g�Z�k��
    iv_args1      IN     VARCHAR2 DEFAULT CHR(0),         --  3.����1
    iv_args2      IN     VARCHAR2 DEFAULT CHR(0),         --  4.����2
    iv_args3      IN     VARCHAR2 DEFAULT CHR(0),         --  5.����3
    iv_args4      IN     VARCHAR2 DEFAULT CHR(0),         --  6.����4
    iv_args5      IN     VARCHAR2 DEFAULT CHR(0),         --  7.����5
    iv_args6      IN     VARCHAR2 DEFAULT CHR(0),         --  8.����6
    iv_args7      IN     VARCHAR2 DEFAULT CHR(0),         --  9.����7
    iv_args8      IN     VARCHAR2 DEFAULT CHR(0),         -- 10.����8
    iv_args9      IN     VARCHAR2 DEFAULT CHR(0),         -- 11.����9
    iv_args10     IN     VARCHAR2 DEFAULT CHR(0),         -- 12.����10
    iv_args11     IN     VARCHAR2 DEFAULT CHR(0),         -- 13.����11
    iv_args12     IN     VARCHAR2 DEFAULT CHR(0),         -- 14.����12
    iv_args13     IN     VARCHAR2 DEFAULT CHR(0),         -- 15.����13
    iv_args14     IN     VARCHAR2 DEFAULT CHR(0),         -- 16.����14
    iv_args15     IN     VARCHAR2 DEFAULT CHR(0),         -- 17.����15
    iv_args16     IN     VARCHAR2 DEFAULT CHR(0),         -- 18.����16
    iv_args17     IN     VARCHAR2 DEFAULT CHR(0),         -- 19.����17
    iv_args18     IN     VARCHAR2 DEFAULT CHR(0),         -- 20.����18
    iv_args19     IN     VARCHAR2 DEFAULT CHR(0),         -- 21.����19
    iv_args20     IN     VARCHAR2 DEFAULT CHR(0),         -- 22.����20
    iv_args21     IN     VARCHAR2 DEFAULT CHR(0),         -- 23.����21
    iv_args22     IN     VARCHAR2 DEFAULT CHR(0),         -- 24.����22
    iv_args23     IN     VARCHAR2 DEFAULT CHR(0),         -- 25.����23
    iv_args24     IN     VARCHAR2 DEFAULT CHR(0),         -- 26.����24
    iv_args25     IN     VARCHAR2 DEFAULT CHR(0),         -- 27.����25
    iv_args26     IN     VARCHAR2 DEFAULT CHR(0),         -- 28.����26
    iv_args27     IN     VARCHAR2 DEFAULT CHR(0),         -- 29.����27
    iv_args28     IN     VARCHAR2 DEFAULT CHR(0),         -- 30.����28
    iv_args29     IN     VARCHAR2 DEFAULT CHR(0),         -- 31.����29
    iv_args30     IN     VARCHAR2 DEFAULT CHR(0),         -- 32.����30
    iv_args31     IN     VARCHAR2 DEFAULT CHR(0),         -- 33.����31
    iv_args32     IN     VARCHAR2 DEFAULT CHR(0),         -- 34.����32
    iv_args33     IN     VARCHAR2 DEFAULT CHR(0),         -- 35.����33
    iv_args34     IN     VARCHAR2 DEFAULT CHR(0),         -- 36.����34
    iv_args35     IN     VARCHAR2 DEFAULT CHR(0),         -- 37.����35
    iv_args36     IN     VARCHAR2 DEFAULT CHR(0),         -- 38.����36
    iv_args37     IN     VARCHAR2 DEFAULT CHR(0),         -- 39.����37
    iv_args38     IN     VARCHAR2 DEFAULT CHR(0),         -- 40.����38
    iv_args39     IN     VARCHAR2 DEFAULT CHR(0),         -- 41.����39
    iv_args40     IN     VARCHAR2 DEFAULT CHR(0),         -- 42.����40
    iv_args41     IN     VARCHAR2 DEFAULT CHR(0),         -- 43.����41
    iv_args42     IN     VARCHAR2 DEFAULT CHR(0),         -- 44.����42
    iv_args43     IN     VARCHAR2 DEFAULT CHR(0),         -- 45.����43
    iv_args44     IN     VARCHAR2 DEFAULT CHR(0),         -- 46.����44
    iv_args45     IN     VARCHAR2 DEFAULT CHR(0),         -- 47.����45
    iv_args46     IN     VARCHAR2 DEFAULT CHR(0),         -- 48.����46
    iv_args47     IN     VARCHAR2 DEFAULT CHR(0),         -- 49.����47
    iv_args48     IN     VARCHAR2 DEFAULT CHR(0),         -- 50.����48
    iv_args49     IN     VARCHAR2 DEFAULT CHR(0),         -- 51.����49
    iv_args50     IN     VARCHAR2 DEFAULT CHR(0),         -- 52.����50
    iv_args51     IN     VARCHAR2 DEFAULT CHR(0),         -- 53.����51
    iv_args52     IN     VARCHAR2 DEFAULT CHR(0),         -- 54.����52
    iv_args53     IN     VARCHAR2 DEFAULT CHR(0),         -- 55.����53
    iv_args54     IN     VARCHAR2 DEFAULT CHR(0),         -- 56.����54
    iv_args55     IN     VARCHAR2 DEFAULT CHR(0),         -- 57.����55
    iv_args56     IN     VARCHAR2 DEFAULT CHR(0),         -- 58.����56
    iv_args57     IN     VARCHAR2 DEFAULT CHR(0),         -- 59.����57
    iv_args58     IN     VARCHAR2 DEFAULT CHR(0),         -- 60.����58
    iv_args59     IN     VARCHAR2 DEFAULT CHR(0),         -- 61.����59
    iv_args60     IN     VARCHAR2 DEFAULT CHR(0),         -- 62.����60
    iv_args61     IN     VARCHAR2 DEFAULT CHR(0),         -- 63.����61
    iv_args62     IN     VARCHAR2 DEFAULT CHR(0),         -- 64.����62
    iv_args63     IN     VARCHAR2 DEFAULT CHR(0),         -- 65.����63
    iv_args64     IN     VARCHAR2 DEFAULT CHR(0),         -- 66.����64
    iv_args65     IN     VARCHAR2 DEFAULT CHR(0),         -- 67.����65
    iv_args66     IN     VARCHAR2 DEFAULT CHR(0),         -- 68.����66
    iv_args67     IN     VARCHAR2 DEFAULT CHR(0),         -- 69.����67
    iv_args68     IN     VARCHAR2 DEFAULT CHR(0),         -- 70.����68
    iv_args69     IN     VARCHAR2 DEFAULT CHR(0),         -- 71.����69
    iv_args70     IN     VARCHAR2 DEFAULT CHR(0),         -- 72.����70
    iv_args71     IN     VARCHAR2 DEFAULT CHR(0),         -- 73.����71
    iv_args72     IN     VARCHAR2 DEFAULT CHR(0),         -- 74.����72
    iv_args73     IN     VARCHAR2 DEFAULT CHR(0),         -- 75.����73
    iv_args74     IN     VARCHAR2 DEFAULT CHR(0),         -- 76.����74
    iv_args75     IN     VARCHAR2 DEFAULT CHR(0),         -- 77.����75
    iv_args76     IN     VARCHAR2 DEFAULT CHR(0),         -- 78.����76
    iv_args77     IN     VARCHAR2 DEFAULT CHR(0),         -- 79.����77
    iv_args78     IN     VARCHAR2 DEFAULT CHR(0),         -- 80.����78
    iv_args79     IN     VARCHAR2 DEFAULT CHR(0),         -- 81.����79
    iv_args80     IN     VARCHAR2 DEFAULT CHR(0),         -- 82.����80
    iv_args81     IN     VARCHAR2 DEFAULT CHR(0),         -- 83.����81
    iv_args82     IN     VARCHAR2 DEFAULT CHR(0),         -- 84.����82
    iv_args83     IN     VARCHAR2 DEFAULT CHR(0),         -- 85.����83
    iv_args84     IN     VARCHAR2 DEFAULT CHR(0),         -- 86.����84
    iv_args85     IN     VARCHAR2 DEFAULT CHR(0),         -- 87.����85
    iv_args86     IN     VARCHAR2 DEFAULT CHR(0),         -- 88.����86
    iv_args87     IN     VARCHAR2 DEFAULT CHR(0),         -- 89.����87
    iv_args88     IN     VARCHAR2 DEFAULT CHR(0),         -- 90.����88
    iv_args89     IN     VARCHAR2 DEFAULT CHR(0),         -- 91.����89
    iv_args90     IN     VARCHAR2 DEFAULT CHR(0),         -- 92.����90
    iv_args91     IN     VARCHAR2 DEFAULT CHR(0),         -- 93.����91
    iv_args92     IN     VARCHAR2 DEFAULT CHR(0),         -- 94.����92
    iv_args93     IN     VARCHAR2 DEFAULT CHR(0),         -- 95.����93
    iv_args94     IN     VARCHAR2 DEFAULT CHR(0),         -- 96.����94
    iv_args95     IN     VARCHAR2 DEFAULT CHR(0),         -- 97.����95
    iv_args96     IN     VARCHAR2 DEFAULT CHR(0),         -- 98.����96
    iv_args97     IN     VARCHAR2 DEFAULT CHR(0),         -- 99.����97
    iv_args98     IN     VARCHAR2 DEFAULT CHR(0)          --100.����98
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
      iv_app_name,       --  1.�N���ΏۃA�v���P�[�V�����Z�k��
      iv_prg_name,       --  2.�N���ΏۃR���J�����g�Z�k��
      iv_args1,          --  3.����1
      iv_args2,          --  4.����2
      iv_args3,          --  5.����3
      iv_args4,          --  6.����4
      iv_args5,          --  7.����5
      iv_args6,          --  8.����6
      iv_args7,          --  9.����7
      iv_args8,          -- 10.����8
      iv_args9,          -- 11.����9
      iv_args10,         -- 12.����10
      iv_args11,         -- 13.����11
      iv_args12,         -- 14.����12
      iv_args13,         -- 15.����13
      iv_args14,         -- 16.����14
      iv_args15,         -- 17.����15
      iv_args16,         -- 18.����16
      iv_args17,         -- 19.����17
      iv_args18,         -- 20.����18
      iv_args19,         -- 21.����19
      iv_args20,         -- 22.����20
      iv_args21,         -- 23.����21
      iv_args22,         -- 24.����22
      iv_args23,         -- 25.����23
      iv_args24,         -- 26.����24
      iv_args25,         -- 27.����25
      iv_args26,         -- 28.����26
      iv_args27,         -- 29.����27
      iv_args28,         -- 30.����28
      iv_args29,         -- 31.����29
      iv_args30,         -- 32.����30
      iv_args31,         -- 33.����31
      iv_args32,         -- 34.����32
      iv_args33,         -- 35.����33
      iv_args34,         -- 36.����34
      iv_args35,         -- 37.����35
      iv_args36,         -- 38.����36
      iv_args37,         -- 39.����37
      iv_args38,         -- 40.����38
      iv_args39,         -- 41.����39
      iv_args40,         -- 42.����40
      iv_args41,         -- 43.����41
      iv_args42,         -- 44.����42
      iv_args43,         -- 45.����43
      iv_args44,         -- 46.����44
      iv_args45,         -- 47.����45
      iv_args46,         -- 48.����46
      iv_args47,         -- 49.����47
      iv_args48,         -- 50.����48
      iv_args49,         -- 51.����49
      iv_args50,         -- 52.����50
      iv_args51,         -- 53.����51
      iv_args52,         -- 54.����52
      iv_args53,         -- 55.����53
      iv_args54,         -- 56.����54
      iv_args55,         -- 57.����55
      iv_args56,         -- 58.����56
      iv_args57,         -- 59.����57
      iv_args58,         -- 60.����58
      iv_args59,         -- 61.����59
      iv_args60,         -- 62.����60
      iv_args61,         -- 63.����61
      iv_args62,         -- 64.����62
      iv_args63,         -- 65.����63
      iv_args64,         -- 66.����64
      iv_args65,         -- 67.����65
      iv_args66,         -- 68.����66
      iv_args67,         -- 69.����67
      iv_args68,         -- 70.����68
      iv_args69,         -- 71.����69
      iv_args70,         -- 72.����70
      iv_args71,         -- 73.����71
      iv_args72,         -- 74.����72
      iv_args73,         -- 75.����73
      iv_args74,         -- 76.����74
      iv_args75,         -- 77.����75
      iv_args76,         -- 78.����76
      iv_args77,         -- 79.����77
      iv_args78,         -- 80.����78
      iv_args79,         -- 81.����79
      iv_args80,         -- 82.����80
      iv_args81,         -- 83.����81
      iv_args82,         -- 84.����82
      iv_args83,         -- 85.����83
      iv_args84,         -- 86.����84
      iv_args85,         -- 87.����85
      iv_args86,         -- 88.����86
      iv_args87,         -- 89.����87
      iv_args88,         -- 90.����88
      iv_args89,         -- 91.����89
      iv_args90,         -- 92.����90
      iv_args91,         -- 93.����91
      iv_args92,         -- 94.����92
      iv_args93,         -- 95.����93
      iv_args94,         -- 96.����94
      iv_args95,         -- 97.����95
      iv_args96,         -- 98.����96
      iv_args97,         -- 99.����97
      iv_args98,         --100.����98
      lv_errbuf,         -- �G���[�E���b�Z�[�W
      lv_retcode,        -- ���^�[���E�R�[�h
      lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
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
END XXCCP006A02C;
/
