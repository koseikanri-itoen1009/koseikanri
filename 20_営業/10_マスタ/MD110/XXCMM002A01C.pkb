CREATE OR REPLACE PACKAGE BODY XXCMM002A01C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMM002A01C(body)
 * Description      : �Ј��f�[�^�捞����
 * MD.050           : MD050_CMM_002_A01_�Ј��f�[�^�捞
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init_get_profile       �v���t�@�C���擾�v���V�[�W��
 *  init_file_lock         �t�@�C�����b�N�����v���V�[�W��
 *  init                   �����������s���v���V�[�W��(A-2)
 *  check_aff_bumon        AFF����}�X�^���݃`�F�b�N�����v���V�[�W��
 *  get_location_id        ���[�U�[ID���擾�����݃`�F�b�N���s���v���V�[�W��
 *  in_if_check_emp        �f�[�^�A�g�Ώۃ`�F�b�N�����v���V�[�W��
 *  in_if_check            �f�[�^�Ó����`�F�b�N�����v���V�[�W��(A-4)
 *  check_fnd_user         ���[�U�[ID�擾�����v���V�[�W��
 *  check_fnd_lookup       �R�[�h�e�[�u���i�Q�ƃ}�X�^�j���݃t�@���N�V����
 *  check_code             �R�[�h���݃`�F�b�N����
 *  get_fnd_responsibility �E�ӁE�Ǘ��ҏ��̎擾�����v���V�[�W��(A-7)
 *  check_insert           �Ј��f�[�^�o�^���`�F�b�N�����v���V�[�W��(A-5)
 *  check_update           �Ј��f�[�^�X�V���`�F�b�N�����v���V�[�W��(A-6)
 *  add_report             �Ј��f�[�^�G���[���i�[����(A-11)
 *  disp_report            ���|�[�g�p�f�[�^���o�͂���v���V�[�W��
 *  insert_resp_all        ���[�U�[�E�Ӄ}�X�^�̓o�^�������s���v���V�[�W��
 *  update_resp_all        ���[�U�[�E�Ӄ}�X�^�̍X�V�������s���v���V�[�W��
 *  delete_resp_all        ���[�U�[�E�Ӄ}�X�^�̃f�[�^�𖳌�������v���V�[�W��
 *  get_service_id         �T�[�r�X����ID�̎擾���s���v���V�[�W��
 *  get_person_type        �p�[�\���^�C�v�̎擾���s���v���V�[�W��
 *  changes_proc           �ٓ��������s���v���V�[�W��
 *  retire_proc            �ސE�������s���v���V�[�W��
 *  re_hire_proc           �Čٗp�������s���v���V�[�W��
 *  re_hire_ass_proc       �Čٗp����(�A�T�C�������g�}�X�^)���s���v���V�[�W��
 *  insert_proc            �V�K�Ј��̓o�^���s���v���V�[�W��
 *  update_proc            �����Ј��̍X�V���s���v���V�[�W��
 *  delete_proc            �ސE�҂̍Čٗp���s���v���V�[�W��
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/09    1.0   SCS �H�� �^��    ����쐬
 *  2009/03/09    1.1   SCS �|�� ����    ����I���������ACSV�t�@�C�����폜����悤�ɕύX
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2

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
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);             -- ���s���[�U��
  gv_conc_name     VARCHAR2(30);              -- ���s�R���J�����g��
  gv_conc_status   VARCHAR2(30);              -- ��������
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
  gn_skip_cnt      NUMBER;                    -- �X�L�b�v����

--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  global_process2_expt      EXCEPTION;
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
  lock_expt                   EXCEPTION;     -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_appl_short_name   CONSTANT VARCHAR2(10) := 'XXCMM';             -- �A�h�I���F�}�X�^
  cv_common_short_name CONSTANT VARCHAR2(10) := 'XXCCP';             -- �A�h�I���F���ʁEIF
  cv_pkg_name          CONSTANT VARCHAR2(15) := 'XXCMM002A01C';      -- �p�b�P�[�W��

  -- �X�V�敪������킷�X�e�[�^�X(masters_rec.proc_flg)
  gv_sts_error     CONSTANT VARCHAR2(1) := 'E';   --�X�e�[�^�X(�X�V���~)
  gv_sts_thru      CONSTANT VARCHAR2(1) := 'S';   --�X�e�[�^�X(�ύX�Ȃ�)
  gv_sts_update    CONSTANT VARCHAR2(1) := 'U';   --�X�e�[�^�X(�����Ώ�)
  -- �A�g�敪�E���Г��A�g�敪�E�ސE�A�g�E�E�ӎ����A�g������킷�X�e�[�^�X(masters_rec.proc_kbn,ymd_kbn,retire_kbn,resp_kbn,location_id_kbn)
  gv_sts_yes       CONSTANT VARCHAR2(1) := 'Y';   --�X�e�[�^�X(�A�g�Ώ�)
  -- �E�ӎ����A�g(masters_rec.resp_kbn)
  gv_sts_no        CONSTANT VARCHAR2(1) := 'N';   --�X�e�[�^�X(�����E�ӕs��)
--
  -- ���Ј���Ԃ�����킷�X�e�[�^�X(masters_rec.emp_kbn)
  gv_kbn_new       CONSTANT VARCHAR2(1) := 'I';   --�X�e�[�^�X(���f�[�^�Ȃ��F�V�K�Ј�)
  gv_kbn_employee  CONSTANT VARCHAR2(1) := 'U';   --�X�e�[�^�X(�����Ј�)
  gv_kbn_retiree   CONSTANT VARCHAR2(1) := 'D';   --�X�e�[�^�X(�ސE��)
--
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
  gv_flg_on        CONSTANT VARCHAR2(1) := '1';
  gv_const_y       CONSTANT VARCHAR2(1) := 'Y';
--
  gv_def_sex       CONSTANT VARCHAR2(1) := 'M';
  gv_owner         CONSTANT VARCHAR2(4) := 'CUST';
  gv_info_category CONSTANT VARCHAR2(2) := 'JP';
  gv_in_if_name    CONSTANT VARCHAR2(100)   := 'xxcmm_in_people_if';
  gv_upd_mode      CONSTANT VARCHAR2(15)    := 'CORRECTION';
  gv_user_person_type    CONSTANT VARCHAR2(10) := '�]�ƈ�';
  gv_user_person_type_ex CONSTANT VARCHAR2(10) := '�ސE��';
--
  --���b�Z�[�W�ԍ�
  --���ʃ��b�Z�[�W�ԍ�
--
  -- ���b�Z�[�W�ԍ�(�}�X�^)
  cv_file_data_no_err  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';  -- �Ώۃf�[�^�������b�Z�[�W
  cv_prf_get_err       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';  -- �v���t�@�C���擾�G���[
  cv_file_pass_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00003';  -- �t�@�C���p�X�s���G���[
  cv_file_priv_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00007';  -- �t�@�C���A�N�Z�X�����G���[
  cv_file_lock_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00008';  -- ���b�N�擾NG���b�Z�[�W
  cv_csv_file_err      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00219';  -- CSV�t�@�C�����݃`�F�b�N
  cv_api_err           CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00014';  -- API�G���[(�R���J�����g)
  cv_shozoku_err       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00015';  -- �o�^�O�����R�[�h
  cv_dup_val_err       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00016';  -- ���[�U�[�o�^���̏d���`�F�b�N�G���[
  cv_not_found_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00017';  -- ���[�U�[�X�V���̑��݃`�F�b�N�G���[
  cv_process_date_err  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00018';  -- �Ɩ����t�擾�G���[
  cv_no_data_err       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00025';  -- �}�X�^���݃`�F�b�N�G���[
  cv_log_err_msg       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00039';  -- ���O�o�͎��s���b�Z�[�W
  cv_data_check_err    CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00200';  -- �捞�`�F�b�N�G���[
  cv_st_ymd_err1       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00201';  -- ���Г��ߋ����t���ύX�G��
  cv_st_ymd_err2       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00202';  -- ���Г����ސE���G���[
  cv_st_ymd_err3       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00210';  -- ���Г��������t�Ј��i�o�^�X�V�s�j�G���[
  cv_retiree_err1      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00203';  -- �ސE�ҏ��ύX�G���[
  cv_retiree_err2      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00204';  -- �Čٗp���G���[
--  cv_out_resp_msg      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00206';  -- �E�ӎ��������ĕs�\(����)
  cv_rep_msg           CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00207';  -- �G���[�̏������ʃ��X�g�̌��o��
  -- ���b�Z�[�W�ԍ�(���ʁEIF)
  cv_target_rec_msg    CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
  cv_success_rec_msg   CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
  cv_error_rec_msg     CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
  cv_skip_rec_msg      CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
  cv_normal_msg        CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
  cv_warn_msg          CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
  cv_error_msg         CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
  cv_file_name         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-05102'; -- �t�@�C�������b�Z�[�W
  cv_input_no_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; -- �R���J�����g���̓p�����[�^�Ȃ�

  --�v���t�@�C��
  cv_prf_dir           CONSTANT VARCHAR2(30) := 'XXCMM1_JINJI_IN_DIR';  -- �l��(INBOUND)�A�g�pCSV�t�@�C���ۊǏꏊ
  cv_prf_fil           CONSTANT VARCHAR2(30) := 'XXCMM1_002A01_IN_FILE';  -- �l���A�g�p�Ј��f�[�^�捞�pCSV�t�@�C���o�͐�
  cv_prf_supervisor    CONSTANT VARCHAR2(30) := 'XXCMM1_002A01_SUPERVISOR_CD'; -- �Ǘ��ҏ]�ƈ��ԍ�
  cv_prf_default       CONSTANT VARCHAR2(30) := 'XXCMM1_002A01_DEFAULT_CD';   -- �f�t�H���g��p����
  cv_prf_password      CONSTANT VARCHAR2(30) := 'XXCMM1_002A01_PASSWORD';  -- �����p�X���[�h

  -- �g�[�N��
  cv_cnt_token          CONSTANT VARCHAR2(10) := 'COUNT';              -- �������b�Z�[�W�p�g�[�N����
  cv_tkn_ng_profile     CONSTANT VARCHAR2(15) := 'NG_PROFILE';         -- �G���[�v���t�@�C����
  cv_tkn_ng_word        CONSTANT VARCHAR2(10) := 'NG_WORD';            -- �G���[���ږ�
  cv_tkn_ng_data        CONSTANT VARCHAR2(10) := 'NG_DATA';            -- �G���[�f�[�^
  cv_tkn_ng_table       CONSTANT VARCHAR2(10) := 'NG_TABLE';           -- �G���[�e�[�u��
  cv_tkn_ng_code        CONSTANT VARCHAR2(10) := 'NG_CODE';            -- �G���[�R�[�h
  cv_tkn_ng_user        CONSTANT VARCHAR2(10) := 'NG_USER';            -- �G���[�Ј��ԍ�
  cv_tkn_ng_err         CONSTANT VARCHAR2(10) := 'NG_ERR';             -- �G���[���e
  cv_tkn_filename       CONSTANT VARCHAR2(10) := 'FILE_NAME';          -- �t�@�C����
  cv_tkn_apiname        CONSTANT VARCHAR2(10) := 'API_NAME';           -- API��
  cv_prf_dir_nm         CONSTANT VARCHAR2(20) := 'CSV�t�@�C���o�͐�';  -- �v���t�@�C��;
  cv_prf_fil_nm         CONSTANT VARCHAR2(20) := 'CSV�t�@�C����';      -- �v���t�@�C��;
  cv_prf_supervisor_nm  CONSTANT VARCHAR2(20) := '�Ǘ��ҏ]�ƈ��ԍ�';   -- �v���t�@�C��;
  cv_prf_supervisor_nm2 CONSTANT VARCHAR2(40) := '�Ǘ��ҏ]�ƈ��ԍ�(�]�ƈ����o�^�f�[�^)'; -- �v���t�@�C��;
  cv_prf_default_nm     CONSTANT VARCHAR2(20) := '�f�t�H���g��p����'; -- �v���t�@�C��;
  cv_prf_password_nm    CONSTANT VARCHAR2(20) := '�����p�X���[�h';     -- �v���t�@�C��;
  cv_xxcmm1_in_if_nm            CONSTANT VARCHAR2(20) := '�Ј��C���^�t�F�[�X';   -- �t�@�C����
  cv_per_all_people_f_nm        CONSTANT VARCHAR2(20) := '�]�ƈ��}�X�^';         -- �t�@�C����
  cv_per_all_assignments_f_nm   CONSTANT VARCHAR2(30) := '�A�T�C�������g�}�X�^'; -- �t�@�C����
  cv_fnd_user_nm                CONSTANT VARCHAR2(20) := '���[�U�[�}�X�^';       -- �t�@�C����
  cv_fnd_user_resp_group_a_nm   CONSTANT VARCHAR2(20) := '���[�U�[�E�Ӄ}�X�^';   -- �t�@�C����
  cv_employee_nm        CONSTANT VARCHAR2(10) := '�Ј��ԍ�';            -- ���ږ�
  cv_employee_err_nm    CONSTANT VARCHAR2(20) := '�Ј��ԍ��d��';        -- ���ږ�
  cv_data_err           CONSTANT VARCHAR2(20) := '�f�[�^�ُ�';          -- ���ږ�

  --�Q�ƃR�[�h�}�X�^.�^�C�v(fnd_lookup_values_vl.lookup_type)
  cv_flv_license        CONSTANT VARCHAR2(30) := 'XXCMM_QUALIFICATION_CODE';    -- ���i�e�[�u��
  cv_flv_job_post       CONSTANT VARCHAR2(30) := 'XXCMM_POSITION_CODE';         -- �E�ʃe�[�u��
  cv_flv_job_duty       CONSTANT VARCHAR2(30) := 'XXCMM_JOB_CODE';              -- �E���e�[�u��
  cv_flv_job_type       CONSTANT VARCHAR2(30) := 'XXCMM_OCCUPATIONAL_CODE';     -- �E��e�[�u��
  cv_flv_job_system     CONSTANT VARCHAR2(30) := 'XXCMM_002A01_**';  -- �K�p�J�����Ԑ��e�[�u��
  cv_flv_consent        CONSTANT VARCHAR2(30) := 'XXCMM_002A01_**';  -- ���F�敪�e�[�u��
  cv_flv_agent          CONSTANT VARCHAR2(30) := 'XXCMM_002A01_**';  -- ��s�敪�e�[�u��
  cv_flv_responsibility CONSTANT VARCHAR2(30) := 'XXCMM1_002A01_RESP';  -- �E�ӎ��������e�[�u��
--
  -- �e�[�u����
  cd_sysdate           DATE := SYSDATE;     -- �����J�n����(YYYYMMDDHH24MISS)
  cd_process_date      DATE;                -- �Ɩ����t(YYYYMMDD)
  cc_process_date      CHAR(8);             -- �Ɩ����t(YYYYMMDD)
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �e�}�X�^�ւ̔��f�����ɕK�v�ȃf�[�^���i�[���郌�R�[�h
  TYPE masters_rec IS RECORD(
--   -- �]�ƈ��C���^�t�F�[�X
    -- �敪
    proc_flg                VARCHAR2(1),  -- �X�V�敪('U':�����Ώ�(gv_sts_update),'E':�X�V�s�\(gv_sts_error),'S':�ύX�Ȃ�(gv_sts_thru))
    proc_kbn                VARCHAR2(1),  -- �A�g�敪('Y':�A�g����f�[�^)
    emp_kbn                 VARCHAR2(1),  -- �Ј����('I':�V�K�Ј�(gv_kbn_new)�A'U'�F�����Ј�(gv_kbn_employee)�A'D'�F�ސE��(gv_kbn_retiree))
    ymd_kbn                 VARCHAR2(1),  -- ���Г��A�g�敪('Y':���t�ύX�f�[�^)
    retire_kbn              VARCHAR2(1),  -- �ސE�敪('Y':�ސE����f�[�^)
    resp_kbn                VARCHAR2(1),  -- �E�ӁE�Ǘ��ҕύX�敪('Y':�ύX����f�[�^,'N':���������s��,NULL�F�ύX���Ȃ�)
    location_id_kbn         VARCHAR2(1),  -- ���Ə��ύX�敪('Y':�ύX����)
    row_err_message         VARCHAR2(1000),  -- �x�����b�Z�[�W
    -- �Ј��捞�C���^�t�F�[�X
    employee_number         xxcmm_in_people_if.employee_number%type,    --�Ј��ԍ�
    hire_date               xxcmm_in_people_if.hire_date%type,          --���ДN����
    actual_termination_date xxcmm_in_people_if.actual_termination_date%type,--�ސE�N����
    last_name_kanji         xxcmm_in_people_if.last_name_kanji%type,    --������
    first_name_kanji        xxcmm_in_people_if.first_name_kanji%type,   --������
    last_name               xxcmm_in_people_if.last_name%type,          --�J�i��
    first_name              xxcmm_in_people_if.first_name%type,         --�J�i��
    sex                     xxcmm_in_people_if.sex%type,                --����
    employee_division       xxcmm_in_people_if.employee_division%type,  --�Ј��E�O���ϑ��敪
    location_code           xxcmm_in_people_if.location_code%type,      --�����R�[�h�i�V�j
    change_code             xxcmm_in_people_if.change_code%type,        --�ٓ����R�R�[�h
    announce_date           xxcmm_in_people_if.announce_date%type,      --���ߓ�
    office_location_code    xxcmm_in_people_if.office_location_code%type, --�Ζ��n���_�R�[�h�i�V�j
    license_code            xxcmm_in_people_if.license_code%type,       --���i�R�[�h�i�V�j
    license_name            xxcmm_in_people_if.license_name%type,       --���i���i�V�j
    job_post                xxcmm_in_people_if.job_post%type,           --�E�ʃR�[�h�i�V�j
    job_post_name           xxcmm_in_people_if.job_post_name%type,      --�E�ʖ��i�V�j
    job_duty                xxcmm_in_people_if.job_duty%type,           --�E���R�[�h�i�V�j
    job_duty_name           xxcmm_in_people_if.job_duty_name%type,      --�E�����i�V�j
    job_type                xxcmm_in_people_if.job_type%type,           --�E��R�[�h�i�V�j
    job_type_name           xxcmm_in_people_if.job_type_name%type,      --�E�햼�i�V�j
    job_system              xxcmm_in_people_if.job_system%type,         --�K�p�J�����Ԑ��R�[�h�i�V�j
    job_system_name         xxcmm_in_people_if.job_system_name%type,    --�K�p�J�����i�V�j
    job_post_order          xxcmm_in_people_if.job_post_order%type,     --�E�ʕ����R�[�h�i�V�j
    consent_division        xxcmm_in_people_if.consent_division%type,   --���F�敪�i�V�j
    agent_division          xxcmm_in_people_if.agent_division%type,     --��s�敪�i�V�j
    office_location_code_old xxcmm_in_people_if.office_location_code_old%type,--�Ζ��n���_�R�[�h�i���j
    location_code_old       xxcmm_in_people_if.location_code_old%type,  --�����R�[�h�i���j
    license_code_old        xxcmm_in_people_if.license_code_old%type,   --���i�R�[�h�i���j
    license_code_name_old   xxcmm_in_people_if.license_code_name_old%type,--���i���i���j
    job_post_old            xxcmm_in_people_if.job_post_old%type,       --�E�ʃR�[�h�i���j
    job_post_name_old       xxcmm_in_people_if.job_post_name_old%type,  --�E�ʖ��i���j
    job_duty_old            xxcmm_in_people_if.job_duty_old%type,       --�E���R�[�h�i���j
    job_duty_name_old       xxcmm_in_people_if.job_duty_name_old%type,  --�E�����i���j
    job_type_old            xxcmm_in_people_if.job_type_old%type,       --�E��R�[�h�i���j
    job_type_name_old       xxcmm_in_people_if.job_type_name_old%type,  --�E�햼�i���j
    job_system_old          xxcmm_in_people_if.job_system_old%type,     --�K�p�J�����Ԑ��R�[�h�i���j
    job_system_name_old     xxcmm_in_people_if.job_system_name_old%type,--�K�p�J�����i���j
    job_post_order_old      xxcmm_in_people_if.job_post_order_old%type, --�E�ʕ����R�[�h�i���j
    consent_division_old    xxcmm_in_people_if.consent_division_old%type, --���F�敪�i���j
    agent_division_old      xxcmm_in_people_if.agent_division_old%type, --��s�敪�i���j
    -- �]�ƈ��}�X�^
    person_id               per_all_people_f.person_id%TYPE,                --�]�ƈ�ID
    hire_date_old           per_all_people_f.effective_start_date%type,     --����_���ДN����
    pap_version             per_all_people_f.object_version_number%TYPE,    --�o�[�W�����ԍ�
    -- �A�T�C�������g�}�X�^
    assignment_id           per_all_assignments_f.assignment_id%TYPE,       --�A�T�C�������gID
    assignment_number       per_all_assignments_f.assignment_number%TYPE,   --�A�T�C�������g�ԍ�
    effective_start_date    per_all_assignments_f.effective_start_date%TYPE,--�o�^�N����
    effective_end_date      per_all_assignments_f.effective_end_date%TYPE,  --�o�^�����N����
    location_id             per_all_assignments_f.location_id%TYPE,         --���Ə�
    supervisor_id           per_all_assignments_f.supervisor_id%TYPE,       --�Ǘ���
    paa_version             per_all_assignments_f.object_version_number%TYPE, --�o�[�W�����ԍ�
    -- ���[�U�}�X�^
    user_id                 fnd_user.user_id%TYPE,                            --���[�U�[ID
    -- �T�[�r�X���ԃ}�X�^
    period_of_service_id    per_periods_of_service.period_of_service_id%TYPE, --�T�[�r�XID
    ppos_version            per_periods_of_service.object_version_number%TYPE --�o�[�W�����ԍ�
  );

--
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE masters_tbl IS TABLE OF masters_rec INDEX BY BINARY_INTEGER;
--
  -- �e�}�X�^�̃f�[�^���i�[���郌�R�[�h
  TYPE check_rec IS RECORD(
    -- �]�ƈ��}�X�^
    person_id               per_all_people_f.person_id%type,             -- �]�ƈ�ID
    effective_start_date    per_all_people_f.effective_start_date%type,  -- �o�^�N����
    last_name               per_all_people_f.last_name%type,             -- �J�i��
    employee_number         per_all_people_f.employee_number%type,       -- �]�ƈ��ԍ�
    first_name              per_all_people_f.first_name%type,            -- �J�i��
    sex                     per_all_people_f.sex%type,                   -- ����
    employee_division       per_all_people_f.attribute3%type,            -- �]�ƈ��敪
    license_code            per_all_people_f.attribute7%type,            -- ���i�R�[�h�i�V�j
    license_name            per_all_people_f.attribute8%type,            -- ���i���i�V�j
    job_post                per_all_people_f.attribute11%type,           -- �E�ʃR�[�h�i�V�j
    job_post_name           per_all_people_f.attribute12%type,           -- �E�ʖ��i�V�j
    job_duty                per_all_people_f.attribute15%type,           -- �E���R�[�h�i�V�j
    job_duty_name           per_all_people_f.attribute16%type,           -- �E�����i�V�j
    job_type                per_all_people_f.attribute19%type,           -- �E��R�[�h�i�V�j
    job_type_name           per_all_people_f.attribute20%type,           -- �E�햼�i�V�j
    license_code_old        per_all_people_f.attribute9%type,            -- ���i�R�[�h�i���j
    license_code_name_old   per_all_people_f.attribute10%type,           -- ���i���i���j
    job_post_old            per_all_people_f.attribute13%type,           -- �E�ʃR�[�h�i���j
    job_post_name_old       per_all_people_f.attribute14%type,           -- �E�ʖ��i���j
    job_duty_old            per_all_people_f.attribute17%type,           -- �E���R�[�h�i���j
    job_duty_name_old       per_all_people_f.attribute18%type,           -- �����i���j
    job_type_old            per_all_people_f.attribute21%type,           -- �E��R�[�h�i���j
    job_type_name_old       per_all_people_f.attribute22%type,           -- �E�햼�i���j
    pap_location_id         per_all_people_f.attribute28%type,           -- �N�[����
    last_name_kanji         per_all_people_f.per_information18%type,     -- ������
    first_name_kanji        per_all_people_f.per_information19%type,     -- ������
    pap_version             per_all_people_f.object_version_number%type, -- �o�[�W�����ԍ�
    -- �A�T�C�������g�}�X�^
    assignment_id           per_all_assignments_f.assignment_id%type,    -- �A�T�C�������gID
    assignment_number       per_all_assignments_f.assignment_number%type,-- �A�T�C�������g�ԍ�
    paa_effective_start_date per_all_assignments_f.effective_start_date%type, -- �o�^�N����
    paa_effective_end_date  per_all_assignments_f.effective_end_date%type, -- �o�^�����N����
    location_id             per_all_assignments_f.location_id%type,      -- ���Ə�
    supervisor_id           per_all_assignments_f.supervisor_id%type,    -- �Ǘ���
    change_code             per_all_assignments_f.ass_attribute1%type,   -- �ٓ����R�R�[�h
    announce_date           per_all_assignments_f.ass_attribute2%type,   -- ���ߓ�
    office_location_code    per_all_assignments_f.ass_attribute3%type,   -- �Ζ��n���_�R�[�h�i�V�j
    office_location_code_old per_all_assignments_f.ass_attribute4%type,  -- �Ζ��n���_�R�[�h�i���j
    location_code           per_all_assignments_f.ass_attribute5%type,   -- ���_�R�[�h�i�V�j
    location_code_old       per_all_assignments_f.ass_attribute6%type,   -- ���_�R�[�h�i���j
    job_system              per_all_assignments_f.ass_attribute7%type,   -- �K�p�J�����Ԑ��R�[�h�i�V�j
    job_system_name         per_all_assignments_f.ass_attribute8%type,   -- �K�p�J�����i�V�j
    job_system_old          per_all_assignments_f.ass_attribute9%type,   -- �K�p�J�����Ԑ��R�[�h�i���j
    job_system_name_old     per_all_assignments_f.ass_attribute10%type,  -- �K�p�J�����i���j
    job_post_order          per_all_assignments_f.ass_attribute11%type,  -- �E�ʕ����R�[�h�i�V�j
    job_post_order_old      per_all_assignments_f.ass_attribute12%type,  -- �E�ʕ����R�[�h�i���j
    consent_division        per_all_assignments_f.ass_attribute13%type,  -- ���F�敪�i�V�j
    consent_division_old    per_all_assignments_f.ass_attribute14%type,  -- ���F�敪�i���j
    agent_division          per_all_assignments_f.ass_attribute15%type,  -- ��s�敪�i�V�j
    agent_division_old      per_all_assignments_f.ass_attribute16%type,  -- ��s�敪�i���j
    paa_version             per_all_assignments_f.object_version_number%type, -- �o�[�W�����ԍ�(�A�T�C�������g)
    -- �]�ƈ��T�[�r�X���ԃ}�X�^
    period_of_service_id    per_periods_of_service.period_of_service_id%type, -- �T�[�r�XID
    actual_termination_date per_periods_of_service.actual_termination_date%type, -- �ސE�N����
    ppos_version            per_periods_of_service.object_version_number%type
  );
  lr_check_rec  check_rec;  -- �}�X�^�擾�f�[�^�i�[�G���A

  -- �o�͂��郍�O���i�[���郌�R�[�h
  TYPE report_rec IS RECORD(
    -- �敪(master�Ɠ���)
    proc_flg                 VARCHAR2(1),  -- �X�V�敪('U':�����Ώ�,'E':�X�V�s�\,'S':�ύX�Ȃ�)
    -- �o�͓��e(�Ј��C���^�[�t�F�[�X�Ɠ���)
    employee_number          xxcmm_in_people_if.employee_number%type,    --�Ј��ԍ�
    hire_date                xxcmm_in_people_if.hire_date%type,          --���ДN����
    actual_termination_date  xxcmm_in_people_if.actual_termination_date%type,--�ސE�N����
    last_name_kanji          xxcmm_in_people_if.last_name_kanji%type,    --������
    first_name_kanji         xxcmm_in_people_if.first_name_kanji%type,   --������
    last_name                xxcmm_in_people_if.last_name%type,          --�J�i��
    first_name               xxcmm_in_people_if.first_name%type,         --�J�i��
    sex                      xxcmm_in_people_if.sex%type,                --����
    employee_division        xxcmm_in_people_if.employee_division%type,  --�Ј��E�O���ϑ��敪
    location_code            xxcmm_in_people_if.location_code%type,      --�����R�[�h�i�V�j
    change_code              xxcmm_in_people_if.change_code%type,        --�ٓ����R�R�[�h
    announce_date            xxcmm_in_people_if.announce_date%type,      --���ߓ�
    office_location_code     xxcmm_in_people_if.office_location_code%type, --�Ζ��n���_�R�[�h�i�V�j
    license_code             xxcmm_in_people_if.license_code%type,       --���i�R�[�h�i�V�j
    license_name             xxcmm_in_people_if.license_name%type,       --���i���i�V�j
    job_post                 xxcmm_in_people_if.job_post%type,           --�E�ʃR�[�h�i�V�j
    job_post_name            xxcmm_in_people_if.job_post_name%type,      --�E�ʖ��i�V�j
    job_duty                 xxcmm_in_people_if.job_duty%type,           --�E���R�[�h�i�V�j
    job_duty_name            xxcmm_in_people_if.job_duty_name%type,      --�E�����i�V�j
    job_type                 xxcmm_in_people_if.job_type%type,           --�E��R�[�h�i�V�j
    job_type_name            xxcmm_in_people_if.job_type_name%type,      --�E�햼�i�V�j
    job_system               xxcmm_in_people_if.job_system%type,         --�K�p�J�����Ԑ��R�[�h�i�V�j
    job_system_name          xxcmm_in_people_if.job_system_name%type,    --�K�p�J�����i�V�j
    job_post_order           xxcmm_in_people_if.job_post_order%type,     --�E�ʕ����R�[�h�i�V�j
    consent_division         xxcmm_in_people_if.consent_division%type,   --���F�敪�i�V�j
    agent_division           xxcmm_in_people_if.agent_division%type,     --��s�敪�i�V�j
    office_location_code_old xxcmm_in_people_if.office_location_code_old%type,--�Ζ��n���_�R�[�h�i���j
    location_code_old        xxcmm_in_people_if.location_code_old%type,  --�����R�[�h�i���j
    license_code_old         xxcmm_in_people_if.license_code_old%type,   --���i�R�[�h�i���j
    license_code_name_old    xxcmm_in_people_if.license_code_name_old%type,--���i���i���j
    job_post_old             xxcmm_in_people_if.job_post_old%type,       --�E�ʃR�[�h�i���j
    job_post_name_old        xxcmm_in_people_if.job_post_name_old%type,  --�E�ʖ��i���j
    job_duty_old             xxcmm_in_people_if.job_duty_old%type,       --�E���R�[�h�i���j
    job_duty_name_old        xxcmm_in_people_if.job_duty_name_old%type,  --�E�����i���j
    job_type_old             xxcmm_in_people_if.job_type_old%type,       --�E��R�[�h�i���j
    job_type_name_old        xxcmm_in_people_if.job_type_name_old%type,  --�E�햼�i���j
    job_system_old           xxcmm_in_people_if.job_system_old%type,     --�K�p�J�����Ԑ��R�[�h�i���j
    job_system_name_old      xxcmm_in_people_if.job_system_name_old%type,--�K�p�J�����i���j
    job_post_order_old       xxcmm_in_people_if.job_post_order_old%type, --�E�ʕ����R�[�h�i���j
    consent_division_old     xxcmm_in_people_if.consent_division_old%type, --���F�敪�i���j
    agent_division_old       xxcmm_in_people_if.agent_division_old%type, --��s�敪�i���j
--
    message                   VARCHAR2(1000)
  );
--
  -- �o�͂��郌�|�[�g���i�[���錋���z��
  TYPE report_normal_tbl IS TABLE OF report_rec INDEX BY BINARY_INTEGER;
  TYPE report_warn_tbl IS TABLE OF report_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_if             NUMBER;     -- �Ј��C���^�[�t�F�[�X�J�E���g
  gn_rep_n_cnt      NUMBER;     -- ���|�[�g����(����)
  gn_rep_w_cnt      NUMBER;     -- ���|�[�g����(�x��)

  gv_bisiness_grp_id    per_person_types.business_group_id%TYPE;    -- �r�W�l�X�O���[�vID(�]�ƈ�)
  gv_bisiness_grp_id_ex per_person_types.business_group_id%TYPE;    -- �r�W�l�X�O���[�vID(�ސE��)
  gv_person_type        per_person_types.person_type_id%TYPE;       -- �p�[�\���^�C�v(�]�ƈ�)
  gv_person_type_ex     per_person_types.person_type_id%TYPE;       -- �p�[�\���^�C�v(�ސE��)

--�v���t�@�C��
  gv_directory      VARCHAR2(255);         -- �v���t�@�C���E�t�@�C���p�X��
  gv_file_name      VARCHAR2(255);         -- �v���t�@�C���E�t�@�C����
  gv_supervisor     VARCHAR2(255);         -- �v���t�@�C���E�Ǘ��ҏ]�ƈ��ԍ�
  gv_default        VARCHAR2(255);         -- �v���t�@�C���E�f�t�H���g��p����
  gv_password       VARCHAR2(255);         -- �v���t�@�C���E�����p�X���[�h
  gn_person_id      NUMBER(10);            -- ���̧�يǗ��ҏ]�ƈ��ԍ����p�[�\��ID�ɕϊ�
  gn_person_start   DATE;                  -- ���̧�يǗ��҂̓��ДN����
--
  gf_file_hand      UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾

  gt_mst_tbl        masters_tbl;           -- �����z��̒�`
  gt_report_normal_tbl  report_normal_tbl; -- �����z��̒�`
  gt_report_warn_tbl    report_warn_tbl;     -- �����z��̒�`
--
  -- �萔
  gn_created_by               NUMBER;                     -- �쐬��
  gd_creation_date            DATE;                       -- �쐬��
  gd_last_update_date         DATE;                       -- �ŏI�X�V��
  gn_last_update_by           NUMBER;                     -- �ŏI�X�V��
  gn_last_update_login        NUMBER;                     -- �ŏI�X�V���O�C��
  gn_request_id               NUMBER;                     -- �v��ID
  gn_program_application_id   NUMBER;                     -- �v���O�����A�v���P�[�V����ID
  gn_program_id               NUMBER;                     -- �v���O����ID
  gd_program_update_date      DATE;                       -- �v���O�����X�V��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
--

  -- �Ј��C���^�t�F�[�X
  CURSOR gc_xip_cur
  IS
    SELECT xip.employee_number
    FROM   xxcmm_in_people_if xip    -- �]�ƈ��}�X�^
    FOR UPDATE OF xip.employee_number NOWAIT;

  -- �]�ƈ��}�X�^
  CURSOR gc_ppf_cur
  IS
    SELECT pap.person_id
    FROM   per_all_people_f pap    -- �]�ƈ��}�X�^
    WHERE  EXISTS
          (SELECT xip.employee_number
           FROM   xxcmm_in_people_if xip    -- �Ј��C���^�t�F�[�X
           WHERE  xip.employee_number = pap.employee_number)
    FOR UPDATE OF pap.person_id NOWAIT;
--
  -- �A�T�C�������g�}�X�^
  CURSOR gc_paf_cur
  IS
    SELECT paa.assignment_id
    FROM   per_all_assignments_f paa    -- �A�T�C�������g�}�X�^
    WHERE  EXISTS
          (SELECT pap.person_id
           FROM   per_all_people_f pap    -- �]�ƈ��}�X�^
           WHERE  EXISTS
                 (SELECT xip.employee_number
                  FROM   xxcmm_in_people_if xip    -- �Ј��C���^�t�F�[�X
                  WHERE  xip.employee_number = pap.employee_number)
           AND    pap.person_id = paa.person_id)
    FOR UPDATE OF paa.assignment_id NOWAIT;
--
  -- ���[�U�[�}�X�^
  CURSOR gc_fu_cur
  IS
    SELECT fu.user_id
    FROM   fnd_user fu    -- ���[�U�[�}�X�^
    WHERE  EXISTS
          (SELECT pap.person_id
           FROM   per_all_people_f pap    -- �]�ƈ��}�X�^
           WHERE  EXISTS
                 (SELECT xip.employee_number
                  FROM   xxcmm_in_people_if xip    -- �Ј��C���^�t�F�[�X
                  WHERE  xip.employee_number = pap.employee_number)
           AND    pap.person_id = fu.employee_id)
    FOR UPDATE OF fu.user_id NOWAIT;
--
  -- ���[�U�[�E�Ӄ}�X�^
  CURSOR gc_fug_cur
  IS
    SELECT fug.user_id
    FROM   fnd_user_resp_groups_all fug    -- ���[�U�[�E�Ӄ}�X�^
    WHERE  EXISTS
          (SELECT fu.user_id
           FROM   fnd_user fu    -- ���[�U�[�}�X�^
           WHERE  EXISTS
                 (SELECT pap.person_id
                  FROM   per_all_people_f pap    -- �]�ƈ��}�X�^
                  WHERE  EXISTS
                        (SELECT xip.employee_number
                         FROM   xxcmm_in_people_if xip    -- �Ј��C���^�t�F�[�X
                         WHERE  xip.employee_number = pap.employee_number)
                  AND    pap.person_id = fu.employee_id)
           AND    fu.user_id = fug.user_id)
    FOR UPDATE OF fug.user_id NOWAIT;
--
  /***********************************************************************************
   * Procedure Name   : init_get_profile
   * Description      : �v���t�@�C����菉���l���擾���܂��B
   ***********************************************************************************/
  PROCEDURE init_get_profile(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_get_profile'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_token_value1  VARCHAR2(40);
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
    -- �Ј��f�[�^�捞�pCSV�t�@�C���ۊǏꏊ�̎擾
    gv_directory := fnd_profile.value(cv_prf_dir);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_directory IS NULL) THEN
      lv_token_value1 := cv_prf_dir_nm;
      RAISE global_process_expt;
    END IF;
--
    -- �Ј��f�[�^�捞�p�t�@�C�����擾
    gv_file_name := FND_PROFILE.VALUE(cv_prf_fil);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_file_name IS NULL) THEN
      lv_token_value1 := cv_prf_fil_nm;
      RAISE global_process_expt;
    END IF;
--
    -- �Ǘ��ҏ]�ƈ��ԍ��擾
    gv_supervisor := fnd_profile.value(cv_prf_supervisor);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_supervisor IS NULL) THEN
      lv_token_value1 := cv_prf_supervisor_nm;
      RAISE global_process_expt;
    ELSE
      -- �擾�Ǘ��҂̏]�ƈ��ԍ����擾
      BEGIN
        SELECT paa.person_id,
               ppos.date_start
        INTO   gn_person_id,
               gn_person_start
        FROM   per_all_assignments_f paa,                           -- �A�T�C�������g�}�X�^
               per_periods_of_service ppos,                         -- �]�ƈ��T�[�r�X���ԃ}�X�^
               per_all_people_f pap                                 -- �]�ƈ��}�X�^
        WHERE  pap.employee_number = gv_supervisor                  -- �]�ƈ��ԍ�
        AND    pap.person_id = paa.person_id                        -- �]�ƈ�ID
        AND    paa.period_of_service_id = ppos.period_of_service_id -- �T�[�r�XID
        AND    pap.effective_start_date = ppos.date_start           -- �o�^�N����
        AND    ppos.actual_termination_date IS NULL;                -- �ސE��
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            lv_token_value1 := cv_prf_supervisor_nm2;
            RAISE global_process_expt;
        WHEN OTHERS THEN
            RAISE global_api_others_expt;
      END;
    END IF;
--
    -- �f�t�H���g��p����擾
    gv_default := FND_PROFILE.VALUE(cv_prf_default);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_default IS NULL) THEN
      lv_token_value1 := cv_prf_default_nm;
      RAISE global_process_expt;
    END IF;
--
    -- �����p�X���[�h�擾
    gv_password := FND_PROFILE.VALUE(cv_prf_password);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_password IS NULL) THEN
      lv_token_value1 := cv_prf_password_nm;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN                   --*** �v���t�@�C���擾�G���[ ***--
      -- *** �C�ӂŗ�O�������L�q���� ****
      lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_prf_get_err
                   ,iv_token_name1  => cv_tkn_ng_profile
                   ,iv_token_value1 => lv_token_value1
                  );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                   --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# �C�� #
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
  END init_get_profile;
--
  /***********************************************************************************
   * Procedure Name   : init_file_lock
   * Description      : �t�@�C�����b�N�������s���܂��B
   ***********************************************************************************/
  PROCEDURE init_file_lock(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_file_lock'; -- �v���O������
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
    lv_token_value1  VARCHAR2(40);
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
    -- �Ј��C���^�t�F�[�X
    BEGIN
      OPEN gc_xip_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_token_value1 := cv_xxcmm1_in_if_nm;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    CLOSE gc_xip_cur;
--
    -- �]�ƈ��}�X�^
    BEGIN
      OPEN gc_ppf_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_token_value1 := cv_per_all_people_f_nm;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    CLOSE gc_ppf_cur;
--
    -- �A�T�C�������g�}�X�^
    BEGIN
      OPEN gc_paf_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_token_value1 := cv_per_all_assignments_f_nm;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    CLOSE gc_paf_cur;
--
    -- ���[�U�[�}�X�^
    BEGIN
      OPEN gc_fu_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_token_value1 := cv_fnd_user_nm;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    CLOSE gc_fu_cur;
--
    -- ���[�U�[�E�Ӄ}�X�^
    BEGIN
      OPEN gc_fug_cur;
    EXCEPTION
      WHEN lock_expt THEN
        lv_token_value1 := cv_fnd_user_resp_group_a_nm;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    CLOSE gc_fug_cur;

    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN global_process_expt THEN                           --*** �t�@�C�����b�N�G���[ ***--
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_file_lock_err
                  ,iv_token_name1  => cv_tkn_ng_table
                  ,iv_token_value1 => lv_token_value1
                 );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
      IF (gc_xip_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
         CLOSE gc_xip_cur;
      END IF;

    -- �]�ƈ��}�X�^
      IF (gc_ppf_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
         CLOSE gc_ppf_cur;
      END IF;

    -- �A�T�C�������g�}�X�^
      IF (gc_ppf_cur%ISOPEN) THEN
         -- �J�[�\���̃N���[�Y
         CLOSE gc_ppf_cur;
      END IF;
--
    -- ���[�U�[�}�X�^
      IF (gc_fu_cur%ISOPEN) THEN
         -- �J�[�\���̃N���[�Y
        CLOSE gc_fu_cur;
      END IF;
--
    -- ���[�U�[�E�Ӄ}�X�^
      IF (gc_fug_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
        CLOSE gc_fug_cur;
      END IF;
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
      IF (gc_xip_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
         CLOSE gc_xip_cur;
      END IF;

    -- �]�ƈ��}�X�^
      IF (gc_ppf_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
         CLOSE gc_ppf_cur;
      END IF;

    -- �A�T�C�������g�}�X�^
      IF (gc_ppf_cur%ISOPEN) THEN
         -- �J�[�\���̃N���[�Y
         CLOSE gc_ppf_cur;
      END IF;
--
    -- ���[�U�[�}�X�^
      IF (gc_fu_cur%ISOPEN) THEN
         -- �J�[�\���̃N���[�Y
        CLOSE gc_fu_cur;
      END IF;
--
    -- ���[�U�[�E�Ӄ}�X�^
      IF (gc_fug_cur%ISOPEN) THEN
      -- �J�[�\���̃N���[�Y
        CLOSE gc_fug_cur;
      END IF;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END init_file_lock;
--
  /***********************************************************************************
   * Procedure Name   : check_aff_bumon
   * Description      : AFF����}�X�^�`�F�b�N�����i�Ɩ����t���_�E�ߋ��f�[�^���݁j
   ***********************************************************************************/
  PROCEDURE check_aff_bumon(
    iv_bumon      IN  VARCHAR2,     --   �`�F�b�N�Ώۃf�[�^
    iv_flg        IN  VARCHAR2,     --   �Ɩ����t���_�ł�AFF����''�A�ߋ����܂߂�AFF����'A'
    iv_token      IN  VARCHAR2,     --   �G���[���̃g�[�N��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_aff_bumon'; -- �v���O������
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
    lv_bumon    VARCHAR2(4);
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
    IF  iv_flg IS NULL THEN
      BEGIN
    -- AFF����i����K�w�r���[�j
        SELECT xhd.cur_dpt_cd
        INTO   lv_bumon
        FROM   xxcmm_hierarchy_dept_v xhd
        WHERE  xhd.cur_dpt_cd = iv_bumon   -- �ŉ��w����R�[�h������
        AND    ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bumon := NULL; -- �Y���f�[�^�Ȃ�
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    ELSE
      BEGIN
    -- AFF����i�S����K�w�r���[�j
        SELECT xhd.cur_dpt_cd
        INTO   lv_bumon
        FROM   xxcmm_hierarchy_dept_all_v xhd
        WHERE  xhd.cur_dpt_cd = iv_bumon   -- �ŉ��w����R�[�h������
        AND    ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_bumon := NULL; -- �Y���f�[�^�Ȃ�
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
--
    IF (lv_bumon IS NULL) THEN
      -- �}�X�^���݃`�F�b�N�G���[
      lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                    ,iv_name         => cv_no_data_err
                    ,iv_token_name1  => cv_tkn_ng_word
                    ,iv_token_value1 => iv_token
                    ,iv_token_name2  => cv_tkn_ng_code
                    ,iv_token_value2 => iv_bumon
                    );
      RAISE global_api_expt;
    END IF;

    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
--#################################  �Œ��O������ START   ####################################
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
--####################################  �Œ蕔 END   ##########################################
--
  END check_aff_bumon;
--
  /***********************************************************************************
   * Procedure Name   : get_location_id
   * Description      : ���P�[�V����ID(���Ə�)�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_location_id(
    ir_masters_rec IN OUT masters_rec,  -- 1.�`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_location_id'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    cv_office_location  CONSTANT VARCHAR2(30) := '�Ζ��n���_�R�[�h(�V)'; -- ���ږ�
    cv_locations_all_nm CONSTANT VARCHAR2(20) := '���Ə��}�X�^';         -- �t�@�C����
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
    BEGIN
    -- ���Ə��}�X�^
      SELECT hla.location_id
      INTO   ir_masters_rec.location_id  -- ���P�[�V����ID
      FROM   hr_locations_all hla        -- ���Ə��}�X�^
      WHERE  hla.location_code  = ir_masters_rec.office_location_code; -- �Ζ��n���_�R�[�h(�V)

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- �}�X�^���݃`�F�b�N�G���[
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_no_data_err
                    ,iv_token_name1  => cv_tkn_ng_word
                    ,iv_token_value1 => cv_locations_all_nm
                    ,iv_token_name2  => cv_tkn_ng_code
                    ,iv_token_value2 => cv_office_location||ir_masters_rec.location_code
                   );
        RAISE global_process_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN global_process_expt THEN                          --*** �x��(�X�V�s�f�[�^) ***--
      ov_errmsg  := lv_errmsg;                                                 --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# �C�� # �x��
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
--#####################################  �Œ蕔 END   #############################################
--
  END get_location_id;
--
  /***********************************************************************************
   * Procedure Name   : in_if_check_emp
   * Description      : �f�[�^�A�g�Ώۃ`�F�b�N
   ***********************************************************************************/
  PROCEDURE in_if_check_emp(
    ir_masters_rec IN OUT masters_rec,  -- 1.�`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'in_if_check_emp'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
    -- �]�ƈ��}�X�^/�A�T�C�������g�}�X�^/�]�ƈ��T�[�r�X���ԃ}�X�^(��check_rec�Ɠ������тɂ���j
    CURSOR gc_per_cur(lv_emp in varchar2)
    IS
      SELECT pap.person_id            person_id,            --�]�ƈ�ID
             pap.effective_start_date effective_start_date, --�o�^�N����
             pap.last_name            last_name,            --�J�i��
             pap.employee_number      employee_number,      --�]�ƈ��ԍ�
             pap.first_name           first_name,           --�J�i��
             pap.sex                  sex,                  --����
             pap.attribute3           employee_division,    --�]�ƈ��敪
             pap.attribute7           license_code,         --���i�R�[�h�i�V�j
             pap.attribute8           license_name,         --���i���i�V�j
             pap.attribute11          job_post,             --�E�ʃR�[�h�i�V�j
             pap.attribute12          job_post_name,        --�E�ʖ��i�V�j
             pap.attribute15          job_duty,             --�E���R�[�h�i�V�j
             pap.attribute16          job_duty_name,        --�E�����i�V�j
             pap.attribute19          job_type,             --�E��R�[�h�i�V�j
             pap.attribute20          job_type_name,        --�E�햼�i�V�j
             pap.attribute9           license_code_old,     --���i�R�[�h�i���j
             pap.attribute10          license_code_name_old,--���i���i���j
             pap.attribute13          job_post_old,         --�E�ʃR�[�h�i���j
             pap.attribute14          job_post_name_old,    --�E�ʖ��i���j
             pap.attribute17          job_duty_old,         --�E���R�[�h�i���j
             pap.attribute18          job_duty_name_old,    --�����i���j
             pap.attribute21          job_type_old,         --�E��R�[�h�i���j
             pap.attribute22          job_type_name_old,    --�E�햼�i���j
             pap.attribute28          pap_location_code,    --�N�[����
             pap.per_information18    last_name_kanji,      --������
             pap.per_information19    first_name_kanji,     --������
             pap.object_version_number pap_version,         --�o�[�W�����ԍ�
             paa.assignment_id        assignment_id,        --�A�T�C�������gID
             paa.assignment_number    assignment_number,    --�A�T�C�������g�ԍ�
             paa.effective_start_date paa_effective_start_date,--�o�^�N����
             paa.effective_end_date   paa_effective_end_date,--�o�^�����N����
             paa.location_id          location_id,          --���Ə�
             paa.supervisor_id        supervisor_id,        --�Ǘ���
             paa.ass_attribute1       change_code,          --�ٓ����R�R�[�h
             paa.ass_attribute2       announce_date,        --���ߓ�
             paa.ass_attribute3       office_location_code, --�Ζ��n���_�R�[�h�i�V�j
             paa.ass_attribute4       office_location_code_old,--�Ζ��n���_�R�[�h�i���j
             paa.ass_attribute5       location_code,        --���_�R�[�h�i�V�j
             paa.ass_attribute6       location_code_old,    --���_�R�[�h�i���j
             paa.ass_attribute7       job_system,           --�K�p�J�����Ԑ��R�[�h�i�V�j
             paa.ass_attribute8       job_system_name,      --�K�p�J�����i�V�j
             paa.ass_attribute9       job_system_old,       --�K�p�J�����Ԑ��R�[�h�i���j
             paa.ass_attribute10      job_system_name_old,  --�K�p�J�����i���j
             paa.ass_attribute11      job_post_order,       --�E�ʕ����R�[�h�i�V�j
             paa.ass_attribute12      job_post_order_old,   --�E�ʕ����R�[�h�i���j
             paa.ass_attribute13      consent_division,     --���F�敪�i�V�j
             paa.ass_attribute14      consent_division_old, --���F�敪�i���j
             paa.ass_attribute15      agent_division,       --��s�敪�i�V�j
             paa.ass_attribute16      agent_division_old,   --��s�敪�i���j
             paa.object_version_number paa_version,         --�o�[�W�����ԍ�(�A�T�C�������g)
             ppos.period_of_service_id period_of_service_id,--�T�[�r�XID
             ppos.actual_termination_date actual_termination_date,--�ސE�N����
             ppos.object_version_number ppos_version        --�o�[�W�����ԍ�(�T�[�r�X���ԃ}�X�^)
      FROM   per_periods_of_service ppos,                   -- �]�ƈ��T�[�r�X���ԃ}�X�^
             per_all_assignments_f paa,                     -- �A�T�C�������g�}�X�^
             per_all_people_f pap                           -- �]�ƈ��}�X�^
      WHERE  pap.employee_number = lv_emp

      AND    pap.current_emp_or_apl_flag = gv_const_y             -- �����t���O
      AND    pap.person_id = paa.person_id                        -- �]�ƈ�ID
      AND    paa.period_of_service_id = ppos.period_of_service_id -- �T�[�r�XID
      AND    pap.effective_start_date = ppos.date_start           -- �o�^�N����(���Г�)
      ORDER BY pap.person_id,pap.effective_start_date desc ,pap.effective_end_date
    ;
--
    -- *** ���[�J���E���R�[�h ***
    gc_per_rec gc_per_cur%ROWTYPE;
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
    -- �V�K�Ј��o�^����
    lr_check_rec.employee_number := NULL;     -- �Ј��R�[�h
    <<per_loop>>
      FOR gc_per_rec IN gc_per_cur(ir_masters_rec.employee_number) LOOP
      lr_check_rec := gc_per_rec;
      EXIT;
    END LOOP per_loop;
--
    IF lr_check_rec.employee_number IS NULL THEN
      ir_masters_rec.emp_kbn  := gv_kbn_new;  -- �V�K�Ј�
      ir_masters_rec.proc_kbn := gv_sts_yes;  -- �A�g�f�[�^
      ir_masters_rec.ymd_kbn  := NULL;        -- ���t�ύX�Ȃ�
      ir_masters_rec.resp_kbn := gv_sts_yes;  -- �E�ӁE�Ǘ��� �ύX
      ir_masters_rec.location_id_kbn := gv_sts_yes;  -- ���Ə� �ύX
      lr_check_rec.license_code := NULL;     -- ���i�R�[�h�i�V�j
      lr_check_rec.job_post := NULL;         -- �E�ʃR�[�h�i�V�j
      lr_check_rec.job_duty := NULL;         -- �E���R�[�h�i�V�j
      lr_check_rec.job_type := NULL;         -- �E��R�[�h�i�V�j
      lr_check_rec.job_system := NULL;       -- �K�p�J�����Ԑ��R�[�h�i�V�j
      lr_check_rec.job_post_order := NULL;   -- �E�ʕ����R�[�h�i�V�j
      lr_check_rec.consent_division := NULL; -- ���F�敪�i�V�j
      lr_check_rec.agent_division := NULL;   -- ��s�敪�i�V�j
      IF (ir_masters_rec.actual_termination_date IS NOT NULL) THEN
        ir_masters_rec.retire_kbn  := gv_sts_yes; -- �ސE�f�[�^
      END IF;
      --���Ə��}�X�^�`�F�b�N(���P�[�V����ID�̎擾)
      get_location_id(
          ir_masters_rec
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_others_expt;
      END IF;
    END IF;
--
    IF (ir_masters_rec.emp_kbn IS NULL) THEN
      -- �A�g�O�̑ސE����NULL�̏ꍇ
      IF (lr_check_rec.actual_termination_date IS NULL) THEN
        ir_masters_rec.emp_kbn  := gv_kbn_employee;  -- �����Ј�
        IF (ir_masters_rec.actual_termination_date IS NOT NULL) THEN
          ir_masters_rec.retire_kbn  := gv_sts_yes;  -- �ސE�f�[�^
        END IF;
      ELSE
        ir_masters_rec.emp_kbn  := gv_kbn_retiree;  -- �ސE��
        ir_masters_rec.retire_kbn  := NULL;  --�ސE�����Ȃ�
      END IF;

      -- ���ДN�����E�ސE�N�����ȊO�̃f�[�^���ٔ��f
      IF (lr_check_rec.employee_number||lr_check_rec.last_name_kanji||lr_check_rec.first_name_kanji
        ||lr_check_rec.last_name||lr_check_rec.first_name||lr_check_rec.sex||lr_check_rec.employee_division
        ||lr_check_rec.location_code||lr_check_rec.change_code
        ||lr_check_rec.announce_date||lr_check_rec.office_location_code||lr_check_rec.license_code||lr_check_rec.license_name
        ||lr_check_rec.job_post||lr_check_rec.job_post_name||lr_check_rec.job_duty||lr_check_rec.job_duty_name
        ||lr_check_rec.job_type||lr_check_rec.job_type_name||lr_check_rec.job_system||lr_check_rec.job_system_name
        ||lr_check_rec.job_post_order||lr_check_rec.consent_division||lr_check_rec.agent_division
        ||lr_check_rec.office_location_code_old||lr_check_rec.location_code_old||lr_check_rec.license_code_old||lr_check_rec.license_code_name_old
        ||lr_check_rec.job_post_old||lr_check_rec.job_post_name_old||lr_check_rec.job_duty_old||lr_check_rec.job_duty_name_old
        ||lr_check_rec.job_type_old||lr_check_rec.job_type_name_old||lr_check_rec.job_system_old||lr_check_rec.job_system_name_old
        ||lr_check_rec.job_post_order_old||lr_check_rec.consent_division_old||lr_check_rec.agent_division_old)
          =
         (ir_masters_rec.employee_number||ir_masters_rec.last_name_kanji||ir_masters_rec.first_name_kanji
        ||ir_masters_rec.last_name||ir_masters_rec.first_name||ir_masters_rec.sex||ir_masters_rec.employee_division
        ||ir_masters_rec.location_code||ir_masters_rec.change_code
        ||ir_masters_rec.announce_date||ir_masters_rec.office_location_code||ir_masters_rec.license_code||ir_masters_rec.license_name
        ||ir_masters_rec.job_post||ir_masters_rec.job_post_name||ir_masters_rec.job_duty||ir_masters_rec.job_duty_name
        ||ir_masters_rec.job_type||ir_masters_rec.job_type_name||ir_masters_rec.job_system||ir_masters_rec.job_system_name
        ||ir_masters_rec.job_post_order||ir_masters_rec.consent_division||ir_masters_rec.agent_division
        ||ir_masters_rec.office_location_code_old||ir_masters_rec.location_code_old||ir_masters_rec.license_code_old||ir_masters_rec.license_code_name_old
        ||ir_masters_rec.job_post_old||ir_masters_rec.job_post_name_old||ir_masters_rec.job_duty_old||ir_masters_rec.job_duty_name_old
        ||ir_masters_rec.job_type_old||ir_masters_rec.job_type_name_old||ir_masters_rec.job_system_old||ir_masters_rec.job_system_name_old
        ||ir_masters_rec.job_post_order_old||ir_masters_rec.consent_division_old||ir_masters_rec.agent_division_old) THEN

        ir_masters_rec.proc_kbn := NULL;  -- �A�g�Ȃ��i���قȂ��j
        ir_masters_rec.resp_kbn := NULL;  -- �E�ӁE�Ǘ��ҕύX�Ȃ�
        ir_masters_rec.location_id_kbn := NULL;  -- ���Ə� �ύX�Ȃ�
      ELSE
        ir_masters_rec.proc_kbn := gv_sts_yes;  -- �A�g�f�[�^�i���ق���j
        -- �����R�[�h�i���_�R�[�h�j�̕ύX���f
        IF (lr_check_rec.location_code <> ir_masters_rec.location_code) THEN
          ir_masters_rec.resp_kbn := gv_sts_yes;  -- �E�ӁE�Ǘ��ҕύX����
        END IF;
        -- �Ζ��n���_�R�[�h(�V)�̕ύX���f
        IF (lr_check_rec.office_location_code <> ir_masters_rec.office_location_code) THEN
          ir_masters_rec.location_id_kbn := gv_sts_yes;  -- ���Ə� �ύX
        END IF;
      END IF;
--
      --���Ə��}�X�^�`�F�b�N(���P�[�V����ID�̎擾) (�Čٗp�����Ŏg�p����ׁA���Ə��͎擾���Ă���)
      get_location_id(
        ir_masters_rec
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_others_expt;
      END IF;
--
      -- ���ДN�������ٔ��f
      IF (lr_check_rec.effective_start_date = ir_masters_rec.hire_date) THEN
        ir_masters_rec.ymd_kbn  := NULL;  -- ���Г��ύX�Ȃ�
      ELSE
        ir_masters_rec.ymd_kbn  := gv_sts_yes;  -- ���Г��ύX
      END IF;

      -- �f�[�^�o�^�ɕK�v�ȃf�[�^�i�[
      -- �]�ƈ��}�X�^
      ir_masters_rec.person_id            := lr_check_rec.person_id;     -- �]�ƈ�ID
      ir_masters_rec.pap_version          := lr_check_rec.pap_version;   -- �o�[�W�����ԍ�
      ir_masters_rec.hire_date_old        := lr_check_rec.effective_start_date;   -- ����_���ДN����
      -- �A�T�C�������g�}�X�^
      ir_masters_rec.assignment_id        := lr_check_rec.assignment_id;     -- �A�T�C�������gID
      ir_masters_rec.assignment_number    := lr_check_rec.assignment_number; -- �A�T�C�������g�ԍ�
      ir_masters_rec.supervisor_id        := lr_check_rec.supervisor_id;     -- �Ǘ���
      ir_masters_rec.effective_start_date := lr_check_rec.paa_effective_start_date;  -- �o�^�N����
      ir_masters_rec.effective_end_date   := lr_check_rec.paa_effective_end_date;    -- �o�^�����N����
      ir_masters_rec.paa_version          := lr_check_rec.paa_version;       -- �o�[�W�����ԍ�
      -- �T�[�r�X���ԃ}�X�^
      ir_masters_rec.period_of_service_id := lr_check_rec.period_of_service_id;  -- �T�[�r�XID
      ir_masters_rec.ppos_version         := lr_check_rec.ppos_version;          -- �o�[�W�����ԍ�

    END IF;

    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN global_process_expt THEN                          --*** �x��(�X�V�s�f�[�^) ***--
      ov_errmsg  := lv_errmsg;                                                 --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# �C�� # �x��
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
--#####################################  �Œ蕔 END   #############################################
--
  END in_if_check_emp;
--
  /**********************************************************************************
   * Procedure Name   : in_if_check
   * Description      : �f�[�^�Ó����`�F�b�N����(A-4)
   ***********************************************************************************/
  PROCEDURE in_if_check(
    ir_masters_rec IN OUT masters_rec,  -- 1.�`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'in_if_check'; -- �v���O������
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
    cv_ymd_err_nm       CONSTANT VARCHAR2(20) := '���ДN�������ݒ�';    -- ���ږ�
    cv_hire_date_nm     CONSTANT VARCHAR2(20) := '���ДN����';          -- ���ږ�
    cv_retire_date_nm   CONSTANT VARCHAR2(20) := '�ސE�N����';          -- ���ږ�
    cv_last_name_err_nm CONSTANT VARCHAR2(20) := '�J�i�����ݒ�';        -- ���ږ�
    cv_last_name_nm     CONSTANT VARCHAR2(10) := '�J�i��';              -- ���ږ�
    cv_first_name_nm    CONSTANT VARCHAR2(10) := '�J�i��';              -- ���ږ�
    cv_last_kanji_nm    CONSTANT VARCHAR2(10) := '������';              -- ���ږ�
    cv_first_kanji_nm   CONSTANT VARCHAR2(10) := '������';              -- ���ږ�
    cv_announce_date_nm CONSTANT VARCHAR2(20) := '���ߓ�';              -- ���ږ�
    cv_announce_date_nm1 CONSTANT VARCHAR2(20) := '���ߓ����ݒ�';       -- ���ږ�
    cv_announce_date_nm2 CONSTANT VARCHAR2(20) := '���ߓ��������t';     -- ���ږ�
    cv_sex_nm           CONSTANT VARCHAR2(10) := '����';                -- ���ږ�
    cv_division_nm      CONSTANT VARCHAR2(20) := '�Ј��E�O���ϑ��敪';  -- ���ږ�
    cv_location_cd      CONSTANT VARCHAR2(20) := '�����R�[�h';          -- ���ږ�
    cv_office_location  CONSTANT VARCHAR2(20) := '�Ζ��n���_�R�[�h';    -- ���ږ�
    cv_new              CONSTANT VARCHAR2(10) := '(�V)';                -- ���ږ�
    cv_old              CONSTANT VARCHAR2(10) := '(��)';                -- ���ږ�

    cv_all              CONSTANT VARCHAR2(1) := 'A';
--
    -- *** ���[�J���ϐ� ***
    lv_token_value2  VARCHAR2(30);
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
      --���ДN����
    IF (ir_masters_rec.hire_date IS NULL) THEN
       lv_token_value2 := cv_ymd_err_nm; -- '���ДN�������ݒ�'
       RAISE global_process_expt;
    ELSIF (ir_masters_rec.hire_date) > cd_sysdate THEN -- ���ДN�����ƃV�X�e�����t�̔�r
       lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_st_ymd_err3
                    ,iv_token_name1  => cv_tkn_ng_word
                    ,iv_token_value1 => cv_employee_nm -- '�Ј��ԍ�'
                    ,iv_token_name2  => cv_tkn_ng_user
                    ,iv_token_value2 => ir_masters_rec.employee_number
                    );
       RAISE global_process2_expt;
    ELSIF (LENGTHB(TO_CHAR(ir_masters_rec.hire_date,'YYYYMMDD')) <> 8) THEN -- ���t�Ó����`�F�b�N
       lv_token_value2 := cv_hire_date_nm; -- '���ДN����'
       RAISE global_process_expt;
    END IF;

    --�ސE�N����
    IF (ir_masters_rec.actual_termination_date IS NOT NULL) THEN
      IF (LENGTHB(TO_CHAR(ir_masters_rec.actual_termination_date,'YYYYMMDD')) <> 8) THEN -- ���t�Ó����`�F�b�N
        lv_token_value2 := cv_retire_date_nm; -- '�ސE�N����'
        RAISE global_process_expt;
      ELSIF (ir_masters_rec.hire_date > ir_masters_rec.actual_termination_date) THEN -- ���ДN�����ƑސE�N�����̔�r
        lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                     ,iv_name         => cv_st_ymd_err2
                     ,iv_token_name1  => cv_tkn_ng_word
                     ,iv_token_value1 => cv_employee_nm -- '�Ј��ԍ�'
                     ,iv_token_name2  => cv_tkn_ng_user
                     ,iv_token_value2 => ir_masters_rec.employee_number
                     );
        RAISE global_process2_expt;
      END IF;
    END IF;

    --�J�i���E�J�i��
    IF (ir_masters_rec.last_name IS NULL) then
      lv_token_value2 := cv_last_name_err_nm;  -- '�J�i�����ݒ�';
      RAISE global_process_expt;
    ELSIF (NOT xxccp_common_pkg.chk_single_byte_kana(ir_masters_rec.last_name)) THEN -- ���p�J�^�J�i�`�F�b�N
      lv_token_value2 := cv_last_name_nm;  -- '�J�i��';
      RAISE global_process_expt;
    ELSIF (xxccp_common_pkg.chk_single_byte_kana(ir_masters_rec.first_name) = FALSE) THEN -- ���p�J�^�J�i�`�F�b�N�iNULL����j
      lv_token_value2 := cv_first_name_nm; -- '�J�i��'
      RAISE global_process_expt;
    END IF;

    --�������E������
    IF (xxccp_common_pkg.chk_double_byte(ir_masters_rec.last_name_kanji) = FALSE) THEN
      lv_token_value2 := cv_last_kanji_nm; -- '������'
      RAISE global_process_expt;
    ELSIF (xxccp_common_pkg.chk_double_byte(ir_masters_rec.first_name_kanji) = FALSE) THEN
      lv_token_value2 := cv_first_kanji_nm; -- '������'
      RAISE global_process_expt;
    END IF;

    --���ߓ�
    IF (ir_masters_rec.announce_date IS NULL) THEN
      lv_token_value2 := cv_announce_date_nm1; -- '���ߓ����ݒ�'
      RAISE global_process_expt;
    ELSIF (xxccp_common_pkg.chk_number(ir_masters_rec.announce_date) = FALSE) THEN -- ���p�����`�F�b�N�iNULL����j
      lv_token_value2 := cv_announce_date_nm; -- '���ߓ�'
      RAISE global_process_expt;
    ELSIF (LENGTHB(ir_masters_rec.announce_date) <> 8) THEN -- ���t�Ó����`�F�b�N
      lv_token_value2 := cv_announce_date_nm; -- '���ߓ�'
      RAISE global_process_expt;
    ELSIF (ir_masters_rec.announce_date > cc_process_date) THEN
      lv_token_value2 := cv_announce_date_nm2; -- '���ߓ��������t'
      RAISE global_process_expt;
    END IF;

    --����
    IF (ir_masters_rec.sex NOT IN ('M','F')) THEN
      lv_token_value2 := cv_sex_nm; -- '����'
      RAISE global_process_expt;
    END IF;

    --�Ј��E�O���ϑ��敪
    IF (ir_masters_rec.employee_division NOT IN ('1','2')) THEN
      lv_token_value2 := cv_division_nm; -- '�Ј��E�O���ϑ��敪'
      RAISE global_process_expt;
    END IF;

    --�����R�[�h(�V)
    IF (ir_masters_rec.location_code IS NULL) THEN
      lv_token_value2 := cv_location_cd||cv_new; -- '�����R�[�h(�V)'
      RAISE global_process_expt;
    ELSE
      check_aff_bumon(      --AFF����R�[�h���݃`�F�b�N
        ir_masters_rec.location_code
        ,NULL                 -- �Ɩ����t���_�ł̎g�p����
        ,cv_location_cd||cv_new  -- �G���[�p�g�[�N��:'�����R�[�h(�V)'
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process2_expt;
      END IF;
    END IF;

    --�Ζ��n���_�R�[�h(�V)
    IF (ir_masters_rec.office_location_code IS NULL) THEN
      lv_token_value2 := cv_office_location||cv_new; -- '�Ζ��n���_�R�[�h(�V)'
      RAISE global_process_expt;
    ELSE
      check_aff_bumon(            --AFF����R�[�h���݃`�F�b�N
        ir_masters_rec.office_location_code
        ,NULL                         -- �Ɩ����t���_�ł̎g�p����
        ,cv_office_location||cv_new   -- �G���[�p�g�[�N��:'�Ζ��n���_�R�[�h(�V)'
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process2_expt;
      END IF;
    END IF;
--
    --�����R�[�h(��)
    IF (ir_masters_rec.location_code_old IS NOT NULL) THEN
      check_aff_bumon(    --AFF����R�[�h���݃`�F�b�N
         ir_masters_rec.location_code_old
        ,cv_all               -- �S����ł̃`�F�b�N
        ,cv_location_cd||cv_old  -- �G���[�p�g�[�N��:'�����R�[�h(��)'
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process2_expt;
      END IF;
    END IF;

    --�Ζ��n���_�R�[�h(��)
    IF (ir_masters_rec.office_location_code_old IS NOT NULL) THEN
      check_aff_bumon(            --AFF����R�[�h���݃`�F�b�N
         ir_masters_rec.office_location_code_old
        ,cv_all                       -- �S����ł̃`�F�b�N
        ,cv_office_location||cv_old   -- �G���[�p�g�[�N��:'�Ζ��n���_�R�[�h(��)'
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process2_expt;
      END IF;
    END IF;

    -- �f�[�^�A�g�Ώۃ`�F�b�N
    in_if_check_emp(
       ir_masters_rec
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_warn) THEN
      RAISE global_process2_expt;
    ELSIF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;

    --==============================================================
    --���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN global_process_expt THEN                           --*** �x��1(�X�V�s�f�[�^) ***--
      lv_errmsg  := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_data_check_err
                   ,iv_token_name1  => cv_tkn_ng_user
                   ,iv_token_value1 => ir_masters_rec.employee_number
                   ,iv_token_name2  => cv_tkn_ng_err
                   ,iv_token_value2 => lv_token_value2
                   );
      ov_errmsg  := lv_errmsg;                                                 --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# �C�� # �x��
    WHEN global_process2_expt THEN                          --*** �x��2(�X�V�s�f�[�^) ***--
      ov_errmsg  := lv_errmsg;                                                 --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# �C�� # �x��
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
  END in_if_check;
--
  /***********************************************************************************
   * Procedure Name   : check_fnd_user
   * Description      : ���[�U�[ID���擾�����݃`�F�b�N���s���܂��B
   ***********************************************************************************/
  PROCEDURE check_fnd_user(
    ir_masters_rec IN OUT masters_rec,  -- 1.�`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_fnd_user'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
    BEGIN
      -- ���[�U�[�}�X�^
      SELECT fu.user_id
      INTO   ir_masters_rec.user_id
      FROM   fnd_user fu,          -- ���[�U�[�}�X�^
             per_all_people_f pap  -- �]�ƈ��}�X�^
      WHERE  pap.employee_number = ir_masters_rec.employee_number
      AND    pap.person_id       = fu.employee_id
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ir_masters_rec.user_id := NULL; -- �Y���f�[�^�Ȃ�
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   #############################################
--
  END check_fnd_user;
--
  /***********************************************************************************
   * Procedure Name   : check_fnd_lookup
   * Description      : �Q�ƃR�[�h�}�X�^ ���擾����
   ***********************************************************************************/
  PROCEDURE check_fnd_lookup(
    iv_type       IN  VARCHAR2,     -- 1.�^�C�v
    iv_code       IN  VARCHAR2,     -- 2.�Q�ƃR�[�h
    iv_token      IN  VARCHAR2,     -- 3.�G���[���̃g�[�N��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_fnd_lookup'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_flg  VARCHAR2(1) := NULL;
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
    BEGIN
      -- �Q�ƃR�[�h�e�[�u��
      SELECT '1'
      INTO   lv_flg
      FROM   fnd_lookup_values_vl flv  -- �Q�ƃR�[�h�e�[�u��
      WHERE  flv.lookup_type = iv_type
      AND    flv.lookup_code = iv_code
      AND    flv.enabled_flag = gv_const_y
      AND    NVL(flv.start_date_active,cd_process_date) <= cd_process_date
      AND    NVL(flv.end_date_active,cd_process_date) >= cd_process_date
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN       -- �Y���f�[�^�Ȃ�
        NULL;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    IF (lv_flg IS NULL) THEN
      -- �}�X�^���݃`�F�b�N�G���[
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_no_data_err
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => iv_token
                  ,iv_token_name2  => cv_tkn_ng_code
                  ,iv_token_value2 => iv_code
                 );
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    WHEN global_process_expt THEN                          --*** �x��(�X�V�s�f�[�^) ***--
      ov_errmsg  := lv_errmsg;                                                 --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# �C�� # �x��
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
--#####################################  �Œ蕔 END   #############################################
--
  END check_fnd_lookup;
--
  /***********************************************************************************
   * Procedure Name   : check_code
   * Description      : �R�[�h���݃`�F�b�N����
   ***********************************************************************************/
  PROCEDURE check_code(
    ir_masters_rec IN OUT masters_rec,  -- 1.�`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_code'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    lv_license_nm     CONSTANT VARCHAR2(30) := '���i�R�[�h(�V)';  -- ���i��
    lv_job_post_nm    CONSTANT VARCHAR2(30) := '�E�ʃR�[�h(�V)';  -- �E�ʃR�[�h
    lv_job_duty_nm    CONSTANT VARCHAR2(30) := '�E���R�[�h(�V)';  -- �E���R�[�h
    lv_job_type_nm    CONSTANT VARCHAR2(30) := '�E��R�[�h(�V)';  -- �E��R�[�h
    lv_job_system_nm  CONSTANT VARCHAR2(30) := '�K�p�J�����Ԑ��R�[�h(�V)';  -- �K�p�J�����Ԑ��R�[�h
    lv_post_order_nm  CONSTANT VARCHAR2(30) := '�E�ʕ����R�[�h(�V)';  -- �E�ʕ����R�[�h
    lv_consent_nm     CONSTANT VARCHAR2(30) := '���F�敪(�V)';  -- ���F�敪
    lv_agent_nm       CONSTANT VARCHAR2(30) := '��s�敪(�V)';  -- ��s�敪
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
    -- ���i�R�[�h(�V)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.license_code IS NOT NULL))
      OR (NVL(ir_masters_rec.license_code,' ') <> NVL(lr_check_rec.license_code,' '))) THEN
      -- �Q�ƃR�[�h�}�X�^ ���擾����
      check_fnd_lookup(
         cv_flv_license
        ,ir_masters_rec.license_code
        ,lv_license_nm
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_normal) THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- �E�ӁE�Ǘ��ҕύX����
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �E�ʃR�[�h(�V)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_post IS NOT NULL))
      OR (NVL(ir_masters_rec.job_post,' ') <> NVL(lr_check_rec.job_post,' '))) THEN
      -- �Q�ƃR�[�h�}�X�^ ���擾����
      check_fnd_lookup(
         cv_flv_job_post
        ,ir_masters_rec.job_post
        ,lv_job_post_nm
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_normal) THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- �E�ӁE�Ǘ��ҕύX����
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �E���R�[�h(�V)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_duty IS NOT NULL))
      OR (NVL(ir_masters_rec.job_duty,' ') <> NVL(lr_check_rec.job_duty,' '))) THEN
      -- �Q�ƃR�[�h�}�X�^ ���擾����
      check_fnd_lookup(
         cv_flv_job_duty
        ,ir_masters_rec.job_duty
        ,lv_job_duty_nm
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_normal) THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- �E�ӁE�Ǘ��ҕύX����
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �E��R�[�h(�V)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_type IS NOT NULL))
      OR (NVL(ir_masters_rec.job_type,' ') <> NVL(lr_check_rec.job_type,' '))) THEN
      -- �Q�ƃR�[�h�}�X�^ ���擾����
      check_fnd_lookup(
         cv_flv_job_type
        ,ir_masters_rec.job_type
        ,lv_job_type_nm
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_normal) THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- �E�ӁE�Ǘ��ҕύX����
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �E�ʕ����R�[�h(�V)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_post_order IS NOT NULL))
      OR (NVL(ir_masters_rec.job_post_order,' ') <> NVL(lr_check_rec.job_post_order,' '))) THEN
      -- ���l(0�`99)�ȊO�̓G���[
      IF (ir_masters_rec.job_post_order >= ' 0')
        AND (ir_masters_rec.job_post_order <= '99') THEN
        ir_masters_rec.resp_kbn := gv_sts_yes;  -- �E�ӁE�Ǘ��ҕύX����
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_data_check_err
                    ,iv_token_name1  => cv_tkn_ng_user
                    ,iv_token_value1 => ir_masters_rec.employee_number
                    ,iv_token_name2  => cv_tkn_ng_err
                    ,iv_token_value2 => lv_post_order_nm
                   );
        RAISE global_process_expt;
      END IF;
    END IF;
--
--�������Q�ƃR�[�h�}�X�^�ɐݒ肷�鍀�ڂɂȂ����ꍇ�A�������火��������������������
/*
    -- �K�p�J�����Ԑ��R�[�h(�V)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.job_system IS NOT NULL))
      OR (NVL(ir_masters_rec.job_system,' ') <> NVL(lr_check_rec.job_system,' '))) THEN
      -- �Q�ƃR�[�h�}�X�^ ���擾����
      check_fnd_lookup(
         cv_flv_job_system
        ,ir_masters_rec.job_system
        ,lv_job_system_nm
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_normal) THEN
        NULL;
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ���F�敪(�V)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.consent_division IS NOT NULL))
      OR (NVL(ir_masters_rec.consent_division,' ') <> NVL(lr_check_rec.consent_division,' '))) THEN
      -- �Q�ƃR�[�h�}�X�^ ���擾����
      check_fnd_lookup(
         cv_flv_agent
        ,ir_masters_rec.consent_division
        ,lv_consent_nm
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_normal) THEN
        NULL;
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- ��s�敪(�V)
    IF (((ir_masters_rec.emp_kbn = gv_kbn_new) AND (ir_masters_rec.agent_division IS NOT NULL))
      OR (NVL(ir_masters_rec.agent_division,' ') <> NVL(lr_check_rec.agent_division,' '))) THEN
      -- �Q�ƃR�[�h�}�X�^ ���擾����
      check_fnd_lookup(
         cv_flv_job_type
        ,ir_masters_rec.agent_division
        ,lv_agent_nm
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_normal) THEN
        NULL;
      ELSIF (lv_retcode = cv_status_warn) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
*/
--�������������������������������������܂ō폜��������������������
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN global_process_expt THEN                           --*** �x��(�X�V�s�f�[�^) ***--
      ov_errmsg  := lv_errmsg;                                                 --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# �C�� # �x��
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
--#####################################  �Œ蕔 END   #############################################
--
  END check_code;
--
  /***********************************************************************************
   * Procedure Name   : get_fnd_responsibility(A-7)
   * Description      : �E�ӁE�Ǘ��ҏ��̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_fnd_responsibility(
    ir_masters_rec IN OUT masters_rec,  -- 1.�`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fnd_responsibility'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_level1  CONSTANT VARCHAR2(2):= 'L1';  -- ���x���P
    cv_level2  CONSTANT VARCHAR2(2):= 'L2';  -- ���x���Q
    cv_level3  CONSTANT VARCHAR2(2):= 'L3';  -- ���x���R
    cv_level4  CONSTANT VARCHAR2(2):= 'L4';  -- ���x���S
    cv_level5  CONSTANT VARCHAR2(2):= 'L5';  -- ���x���T
    cv_level6  CONSTANT VARCHAR2(2):= 'L6';  -- ���x���U
    cv_all     CONSTANT VARCHAR2(1):= '-';   -- �S�R�[�g�Ώ�
--
    -- *** ���[�J���ϐ� ***
    lv_location_cd  VARCHAR2(60);  -- �ŉ��w����R�[�h
    lv_location_cd1 VARCHAR2(60);  -- �P�K�w�ڕ���R�[�h
    lv_location_cd2 VARCHAR2(60);  -- �Q�K�w�ڕ���R�[�h
    lv_location_cd3 VARCHAR2(60);  -- �R�K�w�ڕ���R�[�h
    lv_location_cd4 VARCHAR2(60);  -- �S�K�w�ڕ���R�[�h
    lv_location_cd5 VARCHAR2(60);  -- �T�K�w�ڕ���R�[�h
    lv_location_cd6 VARCHAR2(60);  -- �U�K�w�ڕ���R�[�h
    ln_resp_cnt     NUMBER := 0;
    ln_person_cnt   NUMBER := 0;
    ln_post_order   NUMBER := NULL;
    ln_application_id           fnd_responsibility.application_id%TYPE;     -- �A�v���P�[�V����ID
    lv_responsibility_key       fnd_responsibility.responsibility_key%TYPE; -- �E�ӃL�[
    lv_application_short_name   fnd_application.application_short_name%TYPE;-- �A�v���P�[�V������
    ld_st_date      DATE;
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �E�ӎ��������J�[�\��
    CURSOR resp_cur
    IS
      SELECT flv.description        responsibility_id,  -- �E��ID
             flv.attribute1         location_level,     -- �K�w���x��
             flv.attribute2         location            -- ���_�R�[�h
      FROM   fnd_lookup_values_vl flv   -- �Q�ƃR�[�h�}�X�^
      WHERE  flv.lookup_type = cv_flv_responsibility  -- �E�ӎ��������e�[�u��
      AND    flv.enabled_flag = gv_const_y
      AND    NVL(flv.start_date_active,ld_st_date) <= ld_st_date
      AND    NVL(flv.end_date_active,ld_st_date) >= ld_st_date
      AND   ((NVL(flv.attribute3,cv_all) = cv_all) OR
             (NVL(flv.attribute3,cv_all) = ir_masters_rec.license_code)) -- ���i�R�[�h
      AND   ((NVL(flv.attribute4,cv_all) = cv_all) OR
             (NVL(flv.attribute4,cv_all) = ir_masters_rec.job_post))     -- �E�ʃR�[�h
      AND   ((NVL(flv.attribute5,cv_all) = cv_all) OR
             (NVL(flv.attribute5,cv_all) = ir_masters_rec.job_duty))     -- �E���R�[�h
      AND   ((NVL(flv.attribute6,cv_all) = cv_all)  OR
             (NVL(flv.attribute6,cv_all) = ir_masters_rec.job_type))     -- �E��R�[�h
      ORDER BY flv.attribute1,flv.attribute2;
--
    -- �Ǘ��Ҋ����J�[�\��
    CURSOR person_cur
    IS
      SELECT paa.person_id                  person_id,
             TO_NUMBER(paa.ass_attribute11) post_order
      FROM   per_periods_of_service ppos,               -- �]�ƈ��T�[�r�X���ԃ}�X�^
             per_all_assignments_f paa                  -- �A�T�C�������g�}�X�^
      WHERE  paa.ass_attribute3 = ir_masters_rec.office_location_code   -- �Ζ��n���_�R�[�h(�V)
      AND    TO_NUMBER(NVL(paa.ass_attribute11,'99')) > 0               -- �E�ʕ����R�[�h�i�V)
      AND    TO_NUMBER(NVL(paa.ass_attribute11,'99')) <= TO_NUMBER(ir_masters_rec.job_post_order)
      AND    paa.period_of_service_id = ppos.period_of_service_id       -- �T�[�r�XID
      AND    ppos.date_start <= ir_masters_rec.hire_date -- ���Г�
      AND    NVL(ppos.actual_termination_date ,ir_masters_rec.hire_date) >= ir_masters_rec.hire_date -- �ސE��
      ORDER BY post_order;
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

-- �E�ӂ̎擾
-- �E�ӂ̎擾���Ɏg�p������t
    --�V�K�Ј��E�Čٗp���͓��Г��ɂĐE�ӌ����^�����Ј���
    IF (ir_masters_rec.ymd_kbn  = gv_sts_yes)       -- ���Г��ύX
    OR (ir_masters_rec.emp_kbn  = gv_kbn_new) THEN  -- �V�K�Ј�
      ld_st_date := ir_masters_rec.hire_date;
    ELSIF (ir_masters_rec.actual_termination_date IS NULL)
       OR (TO_DATE(ir_masters_rec.announce_date,'YYYYMMDD') < ir_masters_rec.actual_termination_date) THEN
      ld_st_date := TO_DATE(ir_masters_rec.announce_date,'YYYYMMDD');
    ELSE
      ld_st_date := ir_masters_rec.actual_termination_date;
    END IF;

    BEGIN
    -- AFF����i����K�w�r���[�j
      SELECT xhd.cur_dpt_cd,        -- �ŉ��w����R�[�h
             xhd.dpt1_cd,           -- �P�K�w�ڕ���R�[�h
             xhd.dpt2_cd,           -- �Q�K�w�ڕ���R�[�h
             xhd.dpt3_cd,           -- �R�K�w�ڕ���R�[�h
             xhd.dpt4_cd,           -- �S�K�w�ڕ���R�[�h
             xhd.dpt5_cd,           -- �T�K�w�ڕ���R�[�h
             xhd.dpt6_cd            -- �U�K�w�ڕ���R�[�h
      INTO   lv_location_cd,
             lv_location_cd1,
             lv_location_cd2,
             lv_location_cd3,
             lv_location_cd4,
             lv_location_cd5,
             lv_location_cd6
      FROM   xxcmm_hierarchy_dept_v xhd
      WHERE  xhd.cur_dpt_cd = ir_masters_rec.location_code   -- �ŉ��w����R�[�h������
      AND    ROWNUM = 1;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    <<resp_loop>>
    FOR resp_rec IN resp_cur LOOP
      IF (resp_rec.location_level = cv_level1 AND resp_rec.location = lv_location_cd1)
        OR (resp_rec.location_level = cv_level2 AND resp_rec.location = lv_location_cd2)
        OR (resp_rec.location_level = cv_level3 AND resp_rec.location = lv_location_cd3)
        OR (resp_rec.location_level = cv_level4 AND resp_rec.location = lv_location_cd4)
        OR (resp_rec.location_level = cv_level5 AND resp_rec.location = lv_location_cd5)
        OR (resp_rec.location_level = cv_level6 AND resp_rec.location = lv_location_cd6) THEN

        BEGIN
          -- �E�Ӄ}�X�^���݃`�F�b�N
          SELECT fres.application_id,
                  fres.responsibility_key,
                  fapp.application_short_name
          INTO   ln_application_id,
                  lv_responsibility_key,
                  lv_application_short_name
          FROM   fnd_application    fapp,
                  fnd_responsibility fres                    -- �E�Ӄ}�X�^
          WHERE  fres.responsibility_id  = TO_NUMBER(resp_rec.responsibility_id)
          AND    NVL(fres.start_date,ld_st_date)  <= ld_st_date
          AND    NVL(fres.end_date,ld_st_date)  >= ld_st_date
          AND    fapp.application_id = fres.application_id
          AND    ROWNUM = 1;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ln_application_id := NULL;
            lv_responsibility_key := NULL;
            lv_application_short_name := NULL;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;

        IF ln_application_id IS NOT NULL THEN
          BEGIN
            -- �E�ӎ����������[�N�֑Ҕ�
            INSERT INTO xxcmm_wk_people_resp(
                employee_number,
                responsibility_id,
                user_id,
                employee_kbn,
                responsibility_key,
                application_id,
                application_short_name,
                start_date,
                end_date
            )VALUES(
                ir_masters_rec.employee_number,
                TO_NUMBER(resp_rec.responsibility_id),
                ir_masters_rec.user_id,
                ir_masters_rec.emp_kbn,
                lv_responsibility_key,
                ln_application_id,
                lv_application_short_name,
                ld_st_date,
                ir_masters_rec.actual_termination_date
            );
        ln_resp_cnt := ln_resp_cnt + 1;
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN  -- �����Ј��ԍ��ɓ����E�ӂ����݂����ꍇ�́Askip����
              ln_application_id := NULL;
              lv_responsibility_key := NULL;
              lv_application_short_name := NULL;
            WHEN OTHERS THEN
              RAISE global_api_others_expt;
          END;
        END IF;
      END IF;
    END LOOP resp_loop;

    IF (ln_resp_cnt = 0) THEN
/*  --�E�ӂ��������Ȃ��������̌x���G���[�͂Ȃ��i�R�����g�ɂ��Ă����j
        -- �����E�ӊ����ĕs���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_out_resp_msg
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '�Ј��ԍ�'
                  ,iv_token_name2  => cv_tkn_ng_user
                  ,iv_token_value2 => ir_masters_rec.employee_number
                 );
      ir_status_rec.row_err_message   := iv_message;
      ir_status_rec.row_level_status  := cv_status_normal;  --�����p��
*/
      ir_masters_rec.resp_kbn := gv_sts_no;  -- �E�ӎ����A�g�s��
    END IF;
--
-- �Ǘ��ҏ��̎擾
    IF (ir_masters_rec.hire_date >= gn_person_start) THEN
      ir_masters_rec.supervisor_id := gn_person_id; --�v���t�@�C���̐ݒ肳�ꂽ�Ј���person_id�������ݒ�
    END IF;
    <<person_loop>>
    FOR person_rec IN person_cur  LOOP
      ln_person_cnt := ln_person_cnt + 1;
      -- �Ǘ��҂ɕ�����1�Ԃ̎Ј���ݒ�
      IF (ln_person_cnt = 1) THEN
        -- ����1�Ԃ�person_id���{�l�ȊO�̏ꍇ�Aperson_id��ݒ�
        IF (person_rec.person_id <> ir_masters_rec.person_id)
          OR (ir_masters_rec.person_id IS NULL ) THEN         -- �V�K�Ј�
          ir_masters_rec.supervisor_id := person_rec.person_id;
          EXIT person_loop;
        END IF;
      ELSE  --2���ڂ�EXIT����
        -- ����1�Ԃ���������ꍇ�A�{�l�ȊO��ݒ�
        IF (person_rec.post_order = ln_post_order)
          AND (person_rec.person_id <> ir_masters_rec.person_id) THEN
            ir_masters_rec.supervisor_id := person_rec.person_id;
        END IF;
        EXIT person_loop;
      END IF;
      ln_post_order := person_rec.post_order;

    END LOOP person_loop;

    -- �Ǘ��҂��{�l�������ꍇ��NULL��ݒ�
    IF (ir_masters_rec.supervisor_id = ir_masters_rec.person_id) THEN
      ir_masters_rec.supervisor_id := NULL;
    END IF;
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   #############################################
--
  END get_fnd_responsibility;
--
  /***********************************************************************************
   * Procedure Name   : check_insert
   * Description      : �Ј��f�[�^�o�^���`�F�b�N����(A-5)
   ***********************************************************************************/
  PROCEDURE check_insert(
    ir_masters_rec IN OUT masters_rec,  -- 1.�`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_insert'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
    -- ���[�U�}�X�^���݃`�F�b�N
    check_fnd_user(
       ir_masters_rec
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���[�U�擾�G���[
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    -- ���[�U�o�^�σG���[
    ELSIF (ir_masters_rec.user_id IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_dup_val_err
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '�Ј��ԍ�'
                  ,iv_token_name2  => cv_tkn_ng_data
                  ,iv_token_value2 => ir_masters_rec.employee_number
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;

    -- �R�[�h�`�F�b�N����(���i�E�E�ʁE�E���E�E��E�K�p�J�����Ԑ��E���F�敪�E��s�敪)
    check_code(
       ir_masters_rec
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_normal) THEN     -- ����
      NULL;
    ELSIF (lv_retcode = cv_status_warn) THEN    -- �R�[�h���o�^�G���[
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_error) THEN   -- ���̑��̃G���[
      RAISE global_api_expt;
    END IF;
--
    -- =================================
    -- �E�ӁE�Ǘ��ҏ��̎擾����(A-7)
    -- =================================
    get_fnd_responsibility(
       ir_masters_rec
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN  -- SQL�G���[�̂�
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN global_process_expt THEN                           --*** �x��(�X�V�s�f�[�^) ***--
      ov_errmsg  := lv_errmsg;                                                 --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# �C�� # �x��
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
--#####################################  �Œ蕔 END   #############################################
--
  END check_insert;
--
  /***********************************************************************************
   * Procedure Name   : check_update
   * Description      : �X�V�p�f�[�^�̃`�F�b�N�������s���܂��B(A-6)
   ***********************************************************************************/
  PROCEDURE check_update(
    ir_masters_rec IN OUT masters_rec,  -- 1.�`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_update'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
    -- ���[�U�}�X�^���݃`�F�b�N
    check_fnd_user(
       ir_masters_rec
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );

    -- ���[�U�擾�G���[
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    -- ���[�U���o�^�G���[
    ELSIF (ir_masters_rec.user_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_not_found_err
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '�Ј��ԍ�'
                  ,iv_token_name2  => cv_tkn_ng_data
                  ,iv_token_value2 => ir_masters_rec.employee_number
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;

    -- �Ј��C���^�t�F�[�X.���Г����A�T�C�������g�}�X�^.�o�^�N����
    IF (ir_masters_rec.hire_date < lr_check_rec.paa_effective_start_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_st_ymd_err1
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '�Ј��ԍ�'
                  ,iv_token_name2  => cv_tkn_ng_user
                  ,iv_token_value2 => ir_masters_rec.employee_number
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �Ј��C���^�t�F�[�X.�ސE�N�������A�T�C�������g�}�X�^.�o�^�N�����̏ꍇ�A�G���[
    IF (ir_masters_rec.actual_termination_date < lr_check_rec.paa_effective_start_date) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_st_ymd_err2
                  ,iv_token_name1  => cv_tkn_ng_word
                  ,iv_token_value1 => cv_employee_nm    -- '�Ј��ԍ�'
                  ,iv_token_name2  => cv_tkn_ng_user
                  ,iv_token_value2 => ir_masters_rec.employee_number
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �ސE�҂̏ꍇ
    IF (ir_masters_rec.emp_kbn = gv_kbn_retiree) THEN
      -- �A�g�敪���fY�f(���ДN�����E�ސE�N�����ȊO�Ƀf�[�^���ق�����)�̏ꍇ�A
      IF (ir_masters_rec.proc_kbn = gv_sts_yes) THEN
        --�Ј��C���^�t�F�[�X.���Г��ɍ��ق��Ȃ��ꍇ�G���[�i�ސE�҂̏��ύX�̓G���[�j
        IF (ir_masters_rec.hire_date = lr_check_rec.paa_effective_start_date) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_retiree_err1
                      ,iv_token_name1  => cv_tkn_ng_word
                      ,iv_token_value1 => cv_employee_nm    -- '�Ј��ԍ�'
                      ,iv_token_name2  => cv_tkn_ng_user
                      ,iv_token_value2 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        ELSE
          -- �Ј��C���^�t�F�[�X.���Г����T�[�r�X���ԃ}�X�^.�ސE���̏ꍇ�A�Čٗp�f�[�^
          -- �Čٗp�̏ꍇ�́A�E�ӁE�Ǘ��ҕύX�������s���i�V�K�Ј��ɓ��l�j
          IF (ir_masters_rec.hire_date > lr_check_rec.actual_termination_date) THEN
            ir_masters_rec.ymd_kbn := gv_sts_yes;   -- ���Г��A�g�敪('Y':���t�ύX�f�[�^)
            ir_masters_rec.resp_kbn := gv_sts_yes;   -- �E�ӁE�Ǘ��ҕύX�敪('Y':���t�ύX�f�[�^)
          ELSE
          -- �Ј��C���^�t�F�[�X.���Г����T�[�r�X���ԃ}�X�^.�ސE���̏ꍇ�A�G���[�Ƃ��܂��B
            lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_retiree_err2
                        ,iv_token_name1  => cv_tkn_ng_word
                        ,iv_token_value1 => cv_employee_nm  -- '�Ј��ԍ�'
                        ,iv_token_name2  => cv_tkn_ng_user
                        ,iv_token_value2 => ir_masters_rec.employee_number
                        );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
    END IF;

    -- ���i�E�E�ʁE�E���E�E��E�K�p�J�����Ԑ��E�E�ʕ����E���F�敪�E��s�敪�ɍ���������ꍇ�A�R�[�h�`�F�b�N���s��
    IF ((ir_masters_rec.license_code||ir_masters_rec.job_post||ir_masters_rec.job_duty||ir_masters_rec.job_type
      ||ir_masters_rec.job_system||ir_masters_rec.job_post_order
      ||ir_masters_rec.consent_division||ir_masters_rec.agent_division)
      <> (lr_check_rec.license_code||lr_check_rec.job_post||lr_check_rec.job_duty||lr_check_rec.job_type
      ||lr_check_rec.job_system||lr_check_rec.job_post_order
      ||lr_check_rec.consent_division||lr_check_rec.agent_division)) THEN
      -- �R�[�h�`�F�b�N����(���i�E�E�ʁE�E���E�E��E�K�p�J�����Ԑ��E�E�ʕ����E���F�敪�E��s�敪)
      check_code(
         ir_masters_rec
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_normal) THEN     -- ����
        NULL;
      ELSIF (lv_retcode = cv_status_warn) THEN    -- �R�[�h���o�^�G���[
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_error) THEN   -- ���̑��̃G���[
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- =================================
    -- �E�ӁE�Ǘ��ҏ��̎擾����(A-7)
    -- =================================
    IF (ir_masters_rec.resp_kbn = gv_sts_yes) THEN  -- �E�ӁE�Ǘ��ҕύX����
      get_fnd_responsibility(
         ir_masters_rec
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN  -- SQL�G���[�̂�
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
    -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN global_process_expt THEN                           --*** �x��(�X�V�s�f�[�^) ***--
      ir_masters_rec.proc_flg := gv_sts_error;  -- �X�V�s�\
      ir_masters_rec.row_err_message := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                 --# �C�� #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;                                            --# �C�� # �x��
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
--#####################################  �Œ蕔 END   #############################################
--
  END check_update;
--
  /***********************************************************************************
   * Procedure Name   : add_report
   * Description      : �Ј��f�[�^�̃��O�o�͏����i�[���܂��B(A-11)
   ***********************************************************************************/
  PROCEDURE add_report(
    ir_masters_rec IN OUT masters_rec,  -- 1.�`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'add_report'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_report_rec report_rec;
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
    -- ���|�[�g���R�[�h�ɒl��ݒ�
    lr_report_rec.employee_number          := ir_masters_rec.employee_number;    --�Ј��ԍ�
    lr_report_rec.hire_date                := ir_masters_rec.hire_date;          --���ДN����
    lr_report_rec.actual_termination_date  := ir_masters_rec.actual_termination_date;--�ސE�N����
    lr_report_rec.last_name_kanji          := ir_masters_rec.last_name_kanji;    --������
    lr_report_rec.first_name_kanji         := ir_masters_rec.first_name_kanji;   --������
    lr_report_rec.last_name                := ir_masters_rec.last_name;          --�J�i��
    lr_report_rec.first_name               := ir_masters_rec.first_name;         --�J�i��
    lr_report_rec.sex                      := ir_masters_rec.sex;               --����
    lr_report_rec.employee_division        := ir_masters_rec.employee_division;  --�Ј��E�O���ϑ��敪
    lr_report_rec.location_code            := ir_masters_rec.location_code;      --�����R�[�h�i�V�j
    lr_report_rec.change_code              := ir_masters_rec.change_code;        --�ٓ����R�R�[�h
    lr_report_rec.announce_date            := ir_masters_rec.announce_date;      --���ߓ�
    lr_report_rec.office_location_code     := ir_masters_rec.office_location_code; --�Ζ��n���_�R�[�h�i�V�j
    lr_report_rec.license_code             := ir_masters_rec.license_code;       --���i�R�[�h�i�V�j
    lr_report_rec.license_name             := ir_masters_rec.license_name;       --���i���i�V�j
    lr_report_rec.job_post                 := ir_masters_rec.job_post;           --�E�ʃR�[�h�i�V�j
    lr_report_rec.job_post_name            := ir_masters_rec.job_post_name;      --�E�ʖ��i�V�j
    lr_report_rec.job_duty                 := ir_masters_rec.job_duty;           --�E���R�[�h�i�V�j
    lr_report_rec.job_duty_name            := ir_masters_rec.job_duty_name;      --�E�����i�V�j
    lr_report_rec.job_type                 := ir_masters_rec.job_type;           --�E��R�[�h�i�V�j
    lr_report_rec.job_type_name            := ir_masters_rec.job_type_name;      --�E�햼�i�V�j
    lr_report_rec.job_system               := ir_masters_rec.job_system;         --�K�p�J�����Ԑ��R�[�h�i�V�j
    lr_report_rec.job_system_name          := ir_masters_rec.job_system_name;    --�K�p�J�����i�V�j
    lr_report_rec.job_post_order           := ir_masters_rec.job_post_order;     --�E�ʕ����R�[�h�i�V�j
    lr_report_rec.consent_division         := ir_masters_rec.consent_division;   --���F�敪�i�V�j
    lr_report_rec.agent_division           := ir_masters_rec.agent_division;     --��s�敪�i�V�j
    lr_report_rec.office_location_code_old := ir_masters_rec.office_location_code_old; --�Ζ��n���_�R�[�h�i���j
    lr_report_rec.location_code_old        := ir_masters_rec.location_code_old;  --�����R�[�h�i���j
    lr_report_rec.license_code_old         := ir_masters_rec.license_code_old;   --���i�R�[�h�i���j
    lr_report_rec.license_code_name_old    := ir_masters_rec.license_code_name_old;--���i���i���j
    lr_report_rec.job_post_old             := ir_masters_rec.job_post_old;       --�E�ʃR�[�h�i���j
    lr_report_rec.job_post_name_old        := ir_masters_rec.job_post_name_old;  --�E�ʖ��i���j
    lr_report_rec.job_duty_old             := ir_masters_rec.job_duty_old;       --�E���R�[�h�i���j
    lr_report_rec.job_duty_name_old        := ir_masters_rec.job_duty_name_old;  --�E�����i���j
    lr_report_rec.job_type_old             := ir_masters_rec.job_type_old;       --�E��R�[�h�i���j
    lr_report_rec.job_type_name_old        := ir_masters_rec.job_type_name_old;  --�E�햼�i���j
    lr_report_rec.job_system_old           := ir_masters_rec.job_system_old;     --�K�p�J�����Ԑ��R�[�h�i���j
    lr_report_rec.job_system_name_old      := ir_masters_rec.job_system_name_old;--�K�p�J�����i���j
    lr_report_rec.job_post_order_old       := ir_masters_rec.job_post_order_old; --�E�ʕ����R�[�h�i���j
    lr_report_rec.consent_division_old     := ir_masters_rec.consent_division_old; --���F�敪�i���j
    lr_report_rec.agent_division_old       := ir_masters_rec.agent_division_old; --��s�敪�i���j

    lr_report_rec.message                  := ir_masters_rec.row_err_message;
--
    -- ���|�[�g�e�[�u���ɒǉ�
    IF  ir_masters_rec.proc_flg = gv_sts_update THEN
      gt_report_normal_tbl(gn_normal_cnt) := lr_report_rec;
    ELSIF  ir_masters_rec.proc_flg = gv_sts_error THEN
      gt_report_warn_tbl(gn_warn_cnt) := lr_report_rec;
    END IF;

--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   #############################################
--
  END add_report;
--
  /***********************************************************************************
   * Procedure Name   : disp_report
   * Description      : ���|�[�g�p�f�[�^���o�͂��܂��B(C-11)
   ***********************************************************************************/
  PROCEDURE disp_report(
    iv_disp_kbn    IN VARCHAR2,     -- 1.�\���Ώۋ敪(cv_status_normal:����,cv_status_warn:�x��)
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'disp_report'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_normal     CONSTANT VARCHAR2(20) := '<<����f�[�^>>';  -- ���o��
    cv_warning    CONSTANT VARCHAR2(20) := '<<�x���f�[�^>>';  -- ���o��
    cv_errmsg     CONSTANT VARCHAR2(20) := ' [�G���[���b�Z�[�W]';  -- �G���[���b�Z�[�W
    lv_sep_com    CONSTANT VARCHAR2(1)  := ',';     -- �J���}
--
    -- *** ���[�J���ϐ� ***
    lv_dspbuf     VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
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
    -- ���O���o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name
                 ,iv_name         => cv_rep_msg
                );

    IF (iv_disp_kbn = cv_status_warn) THEN
      -- ���O���o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff => cv_warning --���o���P
      );
     FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => gv_out_msg --���o���Q
      );
      <<report_w_loop>>
      FOR ln_disp_cnt IN 1..gn_warn_cnt LOOP
        lv_dspbuf := gt_report_warn_tbl(ln_disp_cnt).employee_number||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).hire_date||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).actual_termination_date||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).last_name_kanji||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).first_name_kanji||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).last_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).first_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).sex||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).employee_division||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).location_code||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).change_code||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).announce_date||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).office_location_code||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).license_code||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).license_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_duty||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_duty_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_type||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_type_name||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_system||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_system_name ||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_order||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).consent_division||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).agent_division||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).office_location_code_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).location_code_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).license_code_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).license_code_name_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_name_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_duty_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_duty_name_old ||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_type_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_type_name_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_system_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_system_name_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).job_post_order_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).consent_division_old||lv_sep_com||
                    gt_report_warn_tbl(ln_disp_cnt).agent_division_old||
                    cv_errmsg||gt_report_warn_tbl(ln_disp_cnt).message
                    ;
        -- ���O�o��
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
           ,buff => lv_dspbuf --�x���f�[�^���O
        );
        -- �o�̓��b�Z�[�W
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gt_report_warn_tbl(ln_disp_cnt).message
        );
      END LOOP report_w_loop;
      -- �󔒍s
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;

    IF (iv_disp_kbn = cv_status_normal) THEN
      -- ���O���o��
      FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff => cv_normal --���o���P
      );
     FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => gv_out_msg --���o���Q
      );
      <<report_n_loop>>
      FOR ln_disp_cnt IN 1..gn_normal_cnt LOOP
        lv_dspbuf := gt_report_normal_tbl(ln_disp_cnt).employee_number||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).hire_date||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).actual_termination_date||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).last_name_kanji||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).first_name_kanji||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).last_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).first_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).sex||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).employee_division||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).location_code||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).change_code||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).announce_date||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).office_location_code||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).license_code||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).license_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_duty||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_duty_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_type||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_type_name||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_system||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_system_name ||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_order||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).consent_division||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).agent_division||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).office_location_code_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).location_code_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).license_code_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).license_code_name_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_name_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_duty_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_duty_name_old ||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_type_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_type_name_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_system_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_system_name_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).job_post_order_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).consent_division_old||lv_sep_com||
                    gt_report_normal_tbl(ln_disp_cnt).agent_division_old
                    ;
        FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
           ,buff => lv_dspbuf --����f�[�^���O
        );
      END LOOP report_n_loop;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   #############################################
--
  END disp_report;
--
  /***********************************************************************************
   * Procedure Name   : update_resp_all
   * Description      : ���[�U�E�Ӄ}�X�^�̍X�V�������s���܂��B
   ***********************************************************************************/
  PROCEDURE update_resp_all(
    ir_masters_rec IN OUT masters_rec,  -- 1.�`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_resp_all'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_retcd                 NUMBER;
    lb_retst                 BOOLEAN;
    ln_responsibility_id     fnd_user_resp_groups_all.responsibility_id%TYPE;
    ln_responsibility_app_id fnd_user_resp_groups_all.responsibility_application_id%TYPE;
    ln_security_group_id     fnd_user_resp_groups_all.security_group_id%TYPE;
    ld_start_date            fnd_user_resp_groups_all.start_date%TYPE;
    ld_start_date_u          fnd_user_resp_groups_all.start_date%TYPE;
--
    lv_api_name              VARCHAR2(200);
    lv_update_flg            VARCHAR2(1);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- �E�ӎ����������[�N
    CURSOR wk_pr1_cur
    IS
      SELECT xwpr.employee_number       employee_number,
             xwpr.responsibility_id     responsibility_id,
             xwpr.user_id               user_id,
             xwpr.responsibility_key    responsibility_key,
             xwpr.application_short_name    application_short_name,
             xwpr.start_date            start_date,
             xwpr.end_date              end_date
      FROM   xxcmm_wk_people_resp xwpr
      WHERE  xwpr.employee_number = ir_masters_rec.employee_number
      AND    xwpr.responsibility_id > 0
      ORDER BY xwpr.employee_number,xwpr.responsibility_id;

    -- ���[�U�[�E�Ӄ}�X�^
    CURSOR furg_cur(in_responsibility_id in number)
    IS
      SELECT fug.responsibility_application_id  responsibility_application_id,
             fug.security_group_id              security_group_id
      FROM   fnd_user_resp_groups_all fug                  -- ���[�U�[�E�Ӄ}�X�^
      WHERE  fug.user_id           = ir_masters_rec.user_id
      AND    fug.responsibility_id = in_responsibility_id
      AND    ROWNUM = 1;

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

    <<wk_pr1_loop>>
    FOR wk_pr1_rec IN wk_pr1_cur LOOP
      lv_update_flg := NULL;
      <<furg_rec_loop>>
      FOR furg_rec IN furg_cur(wk_pr1_rec.responsibility_id) LOOP
        EXIT WHEN furg_cur%NOTFOUND;

        BEGIN
          FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT(
             USER_ID                       => wk_pr1_rec.user_id
            ,RESPONSIBILITY_ID             => wk_pr1_rec.responsibility_id
            ,RESPONSIBILITY_APPLICATION_ID => furg_rec.responsibility_application_id
            ,SECURITY_GROUP_ID             => furg_rec.security_group_id
            ,START_DATE                    => wk_pr1_rec.start_date
            ,END_DATE                      => wk_pr1_rec.end_date
            ,DESCRIPTION                   => gv_const_y
          );
          lv_update_flg := gv_flg_on;
        EXCEPTION
          WHEN OTHERS THEN
            lv_api_name := 'FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT';
            lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_api_err
                        ,iv_token_name1  => cv_tkn_apiname
                        ,iv_token_value1 => lv_api_name
                        ,iv_token_name2  => cv_tkn_ng_word
                        ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                        ,iv_token_name3  => cv_tkn_ng_data
                        ,iv_token_value3 => ir_masters_rec.employee_number
                        );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END LOOP furg_rec_loop;

      IF lv_update_flg IS NULL THEN
         -- �V�K�Ј��E�ӓo�^
      -- ���[�U�E�Ӄ}�X�^
        BEGIN
          FND_USER_RESP_GROUPS_API.LOAD_ROW(
            X_USER_NAME         => wk_pr1_rec.employee_number
           ,X_RESP_KEY          => wk_pr1_rec.responsibility_key
           ,X_APP_SHORT_NAME    => wk_pr1_rec.application_short_name
           ,X_SECURITY_GROUP    => 'STANDARD'
           ,X_OWNER             => gn_created_by
           ,X_START_DATE        => TO_CHAR(wk_pr1_rec.start_date,'YYYY/MM/DD')
           ,X_END_DATE          => TO_CHAR(wk_pr1_rec.end_date,'YYYY/MM/DD')
           ,X_DESCRIPTION       => NULL
           ,X_LAST_UPDATE_DATE  => SYSDATE
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_api_name := 'FND_USER_RESP_GROUPS_API.LOAD_ROW';
            lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_api_err
                        ,iv_token_name1  => cv_tkn_apiname
                        ,iv_token_value1 => lv_api_name
                        ,iv_token_name2  => cv_tkn_ng_word
                        ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                        ,iv_token_name3  => cv_tkn_ng_data
                        ,iv_token_value3 => wk_pr1_rec.employee_number
                        );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END IF;
    END LOOP wk_pr1_loop;

    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** API�֐��G���[��(�֐��g�p����) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
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
--#####################################  �Œ蕔 END   #############################################
--
  END update_resp_all;
--
  /***********************************************************************************
   * Procedure Name   : delete_resp_all
   * Description      : ���[�U�[�E�Ӄ}�X�^�̃f�[�^�̖��������s���܂��B
   ***********************************************************************************/
  PROCEDURE delete_resp_all(
    ir_masters_rec IN OUT masters_rec,  -- 1.�`�F�b�N�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_resp_all'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_user_id                  fnd_user_resp_groups_all.user_id%TYPE;
    ln_responsibility_id        fnd_user_resp_groups_all.responsibility_id%TYPE;
    ln_responsibility_app_id    fnd_user_resp_groups_all.responsibility_application_id%TYPE;
    ln_security_group_id        fnd_user_resp_groups_all.security_group_id%TYPE;
    ld_start_date               fnd_user_resp_groups_all.start_date%TYPE;
--
    lv_api_name                 VARCHAR2(200); -- �G���[�g�[�N���p
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR fug_cur
    IS
      SELECT fug.user_id            user_id,
             fug.responsibility_id  responsibility_id,
             fug.responsibility_application_id  responsibility_application_id,
             fug.security_group_id  security_group_id,
             fug.start_date         start_date
      FROM   fnd_user_resp_groups_all fug                      -- ���[�U�[�E�Ӄ}�X�^
      WHERE  fug.user_id = ir_masters_rec.user_id;
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
    <<fug_cur_loop>>
    FOR fug_rec IN fug_cur LOOP
--
      BEGIN
        -- API�N��
        FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT(
            USER_ID                       => fug_rec.user_id
           ,RESPONSIBILITY_ID             => fug_rec.responsibility_id
           ,RESPONSIBILITY_APPLICATION_ID => fug_rec.responsibility_application_id
           ,SECURITY_GROUP_ID             => fug_rec.security_group_id
           ,START_DATE                    => fug_rec.start_date
           ,END_DATE                      => cd_process_date
           ,DESCRIPTION                   => gv_const_y
        );
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP fug_cur_loop;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** API�֐��G���[��(�֐��g�p����) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
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
--#####################################  �Œ蕔 END   #############################################
--
  END delete_resp_all;
--
  /***********************************************************************************
   * Procedure Name   : insert_resp_all
   * Description      : ���[�U�E�Ӄ}�X�^�ւ̓o�^���s���܂��B
   ***********************************************************************************/
  PROCEDURE insert_resp_all(
    iv_emp_number  IN VARCHAR2, -- 1.�Ј��ԍ�
    iv_resp_key    IN VARCHAR2, -- 2.�E�ӃL�[
    iv_app_name    IN VARCHAR2, -- 3.�A�v���P�[�V������
    iv_st_date     IN DATE,     -- 4.�L����(��)
    iv_en_date     IN DATE,     -- 5.�L����(��)
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_resp_all'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_api_name                 VARCHAR2(200); -- �G���[�g�[�N���p
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
    BEGIN

      -- ���[�U�E�Ӄ}�X�^
      FND_USER_RESP_GROUPS_API.LOAD_ROW(
        X_USER_NAME         => iv_emp_number
       ,X_RESP_KEY          => iv_resp_key
       ,X_APP_SHORT_NAME    => iv_app_name
       ,X_SECURITY_GROUP    => 'STANDARD'
       ,X_OWNER             => gn_created_by
       ,X_START_DATE        => TO_CHAR(iv_st_date,'YYYY/MM/DD')
       ,X_END_DATE          => TO_CHAR(iv_en_date,'YYYY/MM/DD')
       ,X_DESCRIPTION       => NULL
       ,X_LAST_UPDATE_DATE  => SYSDATE
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_RESP_GROUPS_API.LOAD_ROW';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => iv_emp_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** API�֐��G���[��(�֐��g�p����) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
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
--#####################################  �Œ蕔 END   #############################################
--
  END insert_resp_all;
--
  /***********************************************************************************
   * Procedure Name   : get_service_id
   * Description      : �T�[�r�X����ID�̎擾���s���܂��B(�ސE�����O���̎擾)
   ***********************************************************************************/
  PROCEDURE get_service_id(
    ir_masters_rec IN OUT masters_rec,  -- 1.�ސE�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_service_id'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
--  �ސE�����Ɏg�p�i�ސE�O�̑Ώۏ]�ƈ��̻��޽ID�����߂�j
    SELECT ppos.period_of_service_id,           -- �T�[�r�XID
           ppos.object_version_number           -- ���޽����Ͻ����ް�ޮ�
    INTO   ir_masters_rec.period_of_service_id,
           ir_masters_rec.ppos_version
    FROM   per_periods_of_service ppos,         -- �T�[�r�X���ԃ}�X�^
           per_all_people_f pap                   -- �]�ƈ��}�X�^
    WHERE  ppos.person_id = ir_masters_rec.person_id
    AND    ppos.actual_termination_date IS NULL
    AND    ROWNUM = 1;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   #############################################
--
  END get_service_id;
--
  /***********************************************************************************
   * Procedure Name   : get_person_type
   * Description      : �p�[�\���^�C�v�̎擾���s���܂��B
   ***********************************************************************************/
  PROCEDURE get_person_type(
    iv_user_person_type   IN VARCHAR2, -- 1.�p�[�\���^�C�v
    ov_person_type_id    OUT VARCHAR2, -- 2.�p�[�\���^�C�vID
    ov_business_group_id OUT VARCHAR2, -- 3.�r�W�l�X�O���[�vID
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_person_type'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
    -- ===============================
    -- �p�[�\���^�C�v�̎擾
    -- ===============================
    BEGIN
      SELECT ppt.person_type_id,
             ppt.business_group_id
      INTO   ov_person_type_id,
             ov_business_group_id
      FROM   per_person_types ppt     -- �p�[�\���^�C�v�}�X�^
      WHERE  ppt.user_person_type = iv_user_person_type
      AND    ROWNUM = 1;
    EXCEPTION
      -- �f�[�^�Ȃ��̏ꍇ���p��
      WHEN NO_DATA_FOUND THEN
        ov_person_type_id    := NULL;
        ov_business_group_id := NULL;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   #############################################
--
  END get_person_type;
--
  /***********************************************************************************
   * Procedure Name   : changes_proc
   * Description      : �ٓ��������s���v���V�[�W��
   ***********************************************************************************/
  PROCEDURE changes_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.�ٓ��Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'changes_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    -- HR_PERSON_API.UPDATE_PERSON
    lv_full_name                per_all_people_f.full_name%TYPE;
    ln_comment_id               per_all_people_f.comment_id%TYPE;
    lb_name_combination_warning BOOLEAN;
    lb_assign_payroll_warning   BOOLEAN;
    lb_orig_hire_warning        BOOLEAN;
--
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG
    lv_concatenated_segments    VARCHAR2(200);
    ln_soft_coding_keyflex_id   per_all_assignments_f.soft_coding_keyflex_id%type;
    lb_no_managers_warning      BOOLEAN;
    lb_other_manager_warning    BOOLEAN;

    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_special_ceiling_step_id      per_all_assignments_f.special_ceiling_step_id%type;
    ln_people_group_id              per_all_assignments_f.people_group_id%type;
    lv_group_name                   VARCHAR2(200);
    lb_org_now_no_manager_warning   BOOLEAN;
    lb_spp_delete_warning           BOOLEAN;
    lv_entries_changes_warn         VARCHAR2(1);
    lb_tax_district_changed_warn    BOOLEAN;

    lv_api_name                   VARCHAR2(200); -- �G���[�g�[�N���p
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

    -- �]�ƈ��}�X�^(API)
    BEGIN

      HR_PERSON_API.UPDATE_PERSON(
         P_VALIDATE                =>  FALSE
        ,P_EFFECTIVE_DATE          =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE   =>  gv_upd_mode                      -- 'CORRECTION'
        ,P_PERSON_ID               =>  ir_masters_rec.person_id         -- �]�ƈ�ID
        ,P_OBJECT_VERSION_NUMBER   =>  ir_masters_rec.pap_version       -- �]�ƈ�Ͻ��ް�ޮ�(IN/OUT)
        ,P_PERSON_TYPE_ID          =>  gv_person_type                   -- �p�[�\���^�C�v
        ,P_LAST_NAME               =>  ir_masters_rec.last_name         -- �J�i��
        ,P_EMPLOYEE_NUMBER         =>  ir_masters_rec.employee_number   -- �Ј��ԍ�(IN/OUT)
        ,P_FIRST_NAME              =>  ir_masters_rec.first_name        -- �J�i��
        ,P_SEX                     =>  ir_masters_rec.sex               -- ����
        ,P_ATTRIBUTE3              =>  ir_masters_rec.employee_division -- �]�ƈ��敪
        ,P_ATTRIBUTE7              =>  ir_masters_rec.license_code      -- ���i�R�[�h�i�V�j
        ,P_ATTRIBUTE8              =>  ir_masters_rec.license_name      -- ���i���i�V�j
        ,P_ATTRIBUTE9              =>  ir_masters_rec.license_code_old  -- ���i�R�[�h�i���j
        ,P_ATTRIBUTE10             =>  ir_masters_rec.license_code_name_old -- ���i���i���j
        ,P_ATTRIBUTE11             =>  ir_masters_rec.job_post          -- �E�ʃR�[�h�i�V�j
        ,P_ATTRIBUTE12             =>  ir_masters_rec.job_post_name     -- �E�ʖ��i�V�j
        ,P_ATTRIBUTE13             =>  ir_masters_rec.job_post_old      -- �E�ʃR�[�h�i���j
        ,P_ATTRIBUTE14             =>  ir_masters_rec.job_post_name_old -- �E�ʖ��i���j
        ,P_ATTRIBUTE15             =>  ir_masters_rec.job_duty          -- �E���R�[�h�i�V�j
        ,P_ATTRIBUTE16             =>  ir_masters_rec.job_duty_name     -- �E�����i�V�j
        ,P_ATTRIBUTE17             =>  ir_masters_rec.job_duty_old      -- �E���R�[�h�i���j
        ,P_ATTRIBUTE18             =>  ir_masters_rec.job_duty_name_old -- �E�����i���j
        ,P_ATTRIBUTE19             =>  ir_masters_rec.job_type          -- �E��R�[�h�i�V�j
        ,P_ATTRIBUTE20             =>  ir_masters_rec.job_type_name     -- �E�햼�i�V�j
        ,P_ATTRIBUTE21             =>  ir_masters_rec.job_type_old      -- �E��R�[�h�i���j
        ,P_ATTRIBUTE22             =>  ir_masters_rec.job_type_name_old -- �E�햼�i���j
        ,P_ATTRIBUTE28             =>  ir_masters_rec.location_code     -- �N�[����(�����R�[�h�i�V�j)
        ,P_ATTRIBUTE29             =>  ir_masters_rec.location_code     -- �Ɖ�͈�(�����R�[�h�i�V�j)
        ,P_ATTRIBUTE30             =>  ir_masters_rec.location_code     -- ���F�Ҕ͈�(�����R�[�h�i�V�j)
        ,P_PER_INFORMATION_CATEGORY => gv_info_category                 -- 'JP'
        ,P_PER_INFORMATION18       =>  ir_masters_rec.last_name_kanji   -- ������
        ,P_PER_INFORMATION19       =>  ir_masters_rec.first_name_kanji  -- ������
        ,P_EFFECTIVE_START_DATE    =>  ir_masters_rec.effective_start_date -- OUT(�o�^�N����)
        ,P_EFFECTIVE_END_DATE      =>  ir_masters_rec.effective_end_date   -- OUT(�o�^�����N����)
        ,P_FULL_NAME               =>  lv_full_name                        -- OUT
        ,P_COMMENT_ID              =>  ln_comment_id                       -- OUT
        ,P_NAME_COMBINATION_WARNING => lb_name_combination_warning         -- OUT
        ,P_ASSIGN_PAYROLL_WARNING  =>  lb_assign_payroll_warning           -- OUT
        ,P_ORIG_HIRE_WARNING       =>  lb_orig_hire_warning                -- OUT
        );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_PERSON_API.UPDATE_PERSON';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �A�T�C�������g�}�X�^(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG(
         P_VALIDATE               =>  FALSE
        ,P_EFFECTIVE_DATE         =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE  =>  gv_upd_mode                       -- 'CORRECTION'
        ,P_ASSIGNMENT_ID          =>  ir_masters_rec.assignment_id      -- �������ID(�������擾)
        ,P_OBJECT_VERSION_NUMBER  =>  ir_masters_rec.paa_version        -- �������Ͻ��ް�ޮݔԍ�(IN/OUT)
        ,P_SUPERVISOR_ID          =>  ir_masters_rec.supervisor_id      -- �Ǘ���
        ,P_ASSIGNMENT_NUMBER      =>  ir_masters_rec.assignment_number  -- ������Ĕԍ�(�������擾)
        ,P_DEFAULT_CODE_COMB_ID   =>  gv_default                        -- ���̧�ٵ�߼��.��̫�Ĕ�p����
        ,P_ASS_ATTRIBUTE1         =>  ir_masters_rec.change_code        -- �ٓ����R�R�[�h
        ,P_ASS_ATTRIBUTE2         =>  ir_masters_rec.announce_date      -- ���ߓ�
        ,P_ASS_ATTRIBUTE3         =>  ir_masters_rec.office_location_code -- �Ζ��n���_�R�[�h�i�V�j
        ,P_ASS_ATTRIBUTE4         =>  ir_masters_rec.office_location_code_old -- �Ζ��n���_�R�[�h�i���j
        ,P_ASS_ATTRIBUTE5         =>  ir_masters_rec.location_code      -- ���_�R�[�h�i�V�j
        ,P_ASS_ATTRIBUTE6         =>  ir_masters_rec.location_code_old  -- ���_�R�[�h�i���j
        ,P_ASS_ATTRIBUTE7         =>  ir_masters_rec.job_system         -- �K�p�J�����Ԑ��R�[�h�i�V�j
        ,P_ASS_ATTRIBUTE8         =>  ir_masters_rec.job_system_name    -- �K�p�J�����i�V�j
        ,P_ASS_ATTRIBUTE9         =>  ir_masters_rec.job_system_old     -- �K�p�J�����Ԑ��R�[�h�i���j
        ,P_ASS_ATTRIBUTE10        =>  ir_masters_rec.job_system_name_old -- �K�p�J�����i���j
        ,P_ASS_ATTRIBUTE11        =>  ir_masters_rec.job_post_order     -- �E�ʕ����R�[�h�i�V�j
        ,P_ASS_ATTRIBUTE12        =>  ir_masters_rec.job_post_order_old -- �E�ʕ����R�[�h�i���j
        ,P_ASS_ATTRIBUTE13        =>  ir_masters_rec.consent_division   -- ���F�敪�i�V�j
        ,P_ASS_ATTRIBUTE14        =>  ir_masters_rec.consent_division_old -- ���F�敪�i���j
        ,P_ASS_ATTRIBUTE15        =>  ir_masters_rec.agent_division     -- ��s�敪�i�V�j
        ,P_ASS_ATTRIBUTE16        =>  ir_masters_rec.agent_division_old -- ��s�敪�i���j
        ,P_ASS_ATTRIBUTE17        =>  NULL                              -- �����A�g�p���t�i���̋@�j
        ,P_ASS_ATTRIBUTE18        =>  NULL                              -- �����A�g�p���t�i���[�j
        ,P_CONCATENATED_SEGMENTS  =>  lv_concatenated_segments          -- OUT
        ,P_SOFT_CODING_KEYFLEX_ID =>  ln_soft_coding_keyflex_id         -- IN/OUT
        ,P_COMMENT_ID             =>  ln_comment_id                     -- OUT
        ,P_EFFECTIVE_START_DATE   =>  ir_masters_rec.effective_start_date -- OUT�i�o�^�N�����j
        ,P_EFFECTIVE_END_DATE     =>  ir_masters_rec.effective_end_date -- OUT�i�o�^�����N�����j
        ,P_NO_MANAGERS_WARNING    =>  lb_no_managers_warning            -- OUT
        ,P_OTHER_MANAGER_WARNING  =>  lb_other_manager_warning          -- OUT
    );

    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;

    IF (ir_masters_rec.location_id_kbn = gv_sts_yes) THEN  -- ���Ə� �ύX����
      -- �A�T�C�������g�}�X�^(API)
      BEGIN
        HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
           P_VALIDATE                      =>  FALSE
          ,P_EFFECTIVE_DATE                =>  SYSDATE
          ,P_DATETRACK_UPDATE_MODE         =>  gv_upd_mode                      -- 'CORRECTION'
          ,P_ASSIGNMENT_ID                 =>  ir_masters_rec.assignment_id     -- �������ID(�������擾)
          ,P_LOCATION_ID                   =>  ir_masters_rec.location_id       -- ���Ə�(�Ζ��n���_�R�[�h�ύX���j
          ,P_OBJECT_VERSION_NUMBER         =>  ir_masters_rec.paa_version       -- �������Ͻ��ް�ޮݔԍ�(IN/OUT)
          ,P_SPECIAL_CEILING_STEP_ID       =>  ln_special_ceiling_step_id       -- OUT
          ,P_PEOPLE_GROUP_ID               =>  ln_people_group_id               -- OUT
          ,P_GROUP_NAME                    =>  lv_group_name                    -- OUT
          ,P_EFFECTIVE_START_DATE          =>  ir_masters_rec.effective_start_date --OUT�i�o�^�N�����j
          ,P_EFFECTIVE_END_DATE            =>  ir_masters_rec.effective_end_date -- OUT�i�o�^�����N�����j
          ,P_ORG_NOW_NO_MANAGER_WARNING    =>  lb_org_now_no_manager_warning    -- OUT
          ,P_OTHER_MANAGER_WARNING         =>  lb_other_manager_warning         -- OUT
          ,P_SPP_DELETE_WARNING            =>  lb_spp_delete_warning            -- OUT
          ,P_ENTRIES_CHANGED_WARNING       =>  lv_entries_changes_warn          -- OUT
          ,P_TAX_DISTRICT_CHANGED_WARNING  =>  lb_tax_district_changed_warn     -- OUT
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** API�֐��G���[��(�֐��g�p����) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
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
--#####################################  �Œ蕔 END   #############################################
--
  END changes_proc;
--
  /***********************************************************************************
   * Procedure Name   : retire_proc
   * Description      : �ސE�������s���v���V�[�W��
   ***********************************************************************************/
  PROCEDURE retire_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.�ސE�Ώۃf�[�^
    ir_retire_date IN OUT DATE,         -- 2.�ސE����ݒ�
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'retire_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    -- HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP
    ld_last_std_process_date    DATE;
    lb_supervisor_warn          BOOLEAN;
    lb_event_warn               BOOLEAN;
    lb_interview_warn           BOOLEAN;
    lb_review_warn              BOOLEAN;
    lb_recruiter_warn           BOOLEAN;
    lb_asg_future_changes_warn  BOOLEAN;
    lv_entries_changed_warn     VARCHAR2(200);
    lb_pay_proposal_warn        BOOLEAN;
    lb_dod_warn                 BOOLEAN;

    -- HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP(
    lb_org_now_no_manager_warning   BOOLEAN;
    lb_asg_future_changes_warning   BOOLEAN;
    lv_entries_changed_warning      VARCHAR2(1);
--
    lv_api_name                 VARCHAR2(200); -- �G���[�g�[�N���p
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
    -- �T�[�r�X����ID�擾
    get_service_id(
       ir_masters_rec
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �T�[�r�X����ID�擾�G���[
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    BEGIN
      -- �]�ƈ��}�X�^(API)
      HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP(
        P_VALIDATE                   => FALSE
       ,P_EFFECTIVE_DATE             => (ir_retire_date - 1)                    -- �o�^�����N����
       ,P_PERIOD_OF_SERVICE_ID       => ir_masters_rec.period_of_service_id     -- �T�[�r�XID
       ,P_OBJECT_VERSION_NUMBER      => ir_masters_rec.ppos_version             -- ���޽����Ͻ��ް�ޮݔԍ�
       ,P_ACTUAL_TERMINATION_DATE    => ir_retire_date                          -- �ސE��
       ,P_LAST_STANDARD_PROCESS_DATE => ir_retire_date                          -- �ŏI���^������
       ,P_PERSON_TYPE_ID             => gv_person_type_ex                       -- �p�[�\���^�C�v(�ސE��)
       ,P_LAST_STD_PROCESS_DATE_OUT  => ld_last_std_process_date    -- OUT
       ,P_SUPERVISOR_WARNING         => lb_supervisor_warn          -- OUT
       ,P_EVENT_WARNING              => lb_event_warn               -- OUT
       ,P_INTERVIEW_WARNING          => lb_interview_warn           -- OUT
       ,P_REVIEW_WARNING             => lb_review_warn              -- OUT
       ,P_RECRUITER_WARNING          => lb_recruiter_warn           -- OUT
       ,P_ASG_FUTURE_CHANGES_WARNING => lb_asg_future_changes_warn  -- OUT
       ,P_ENTRIES_CHANGED_WARNING    => lv_entries_changed_warn     -- OUT
       ,P_PAY_PROPOSAL_WARNING       => lb_pay_proposal_warn        -- OUT
       ,P_DOD_WARNING                => lb_dod_warn                 -- OUT
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EX_EMPLOYEE_API.ACTUAL_TERMINATION_EMP';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    BEGIN
      HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP(
        P_VALIDATE                      => FALSE
       ,P_PERIOD_OF_SERVICE_ID          => ir_masters_rec.period_of_service_id  -- ���޽ID
       ,P_OBJECT_VERSION_NUMBER         => ir_masters_rec.ppos_version          -- ���޽����Ͻ��ް�ޮݔԍ�
       ,P_FINAL_PROCESS_DATE            => ir_retire_date    -- �ސE��(IN/OUT)�iP_ACTUAL_TERMINATION_DATE�Ɠ�������ݒ�j
       ,P_ORG_NOW_NO_MANAGER_WARNING    => lb_org_now_no_manager_warning    -- OUT
       ,P_ASG_FUTURE_CHANGES_WARNING    => lb_asg_future_changes_warning    -- OUT
       ,P_ENTRIES_CHANGED_WARNING       => lv_entries_changed_warning   -- OUT
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EX_EMPLOYEE_API.FINAL_PROCESS_EMP';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    IF ir_masters_rec.emp_kbn = gv_kbn_new THEN  -- �V�K�Ј���insert_proc�ɂčX�V
      NULL;
    ELSE
      -- ���[�U�}�X�^(API)
      BEGIN
        FND_USER_PKG.UPDATEUSER(
           X_USER_NAME            => ir_masters_rec.employee_number -- �Ј��ԍ�
          ,X_OWNER                => gv_owner                       -- 'CUST'
          ,X_END_DATE             => ir_retire_date                 -- �L�����i���j
        );
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'FND_USER_PKG.UPDATEUSER';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** API�֐��G���[��(�֐��g�p����) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
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
--#####################################  �Œ蕔 END   #############################################
--
  END retire_proc;
--
  /***********************************************************************************
   * Procedure Name   : re_hire_proc
   * Description      : �ސE�҂��Čٗp�o�^���s���v���V�[�W��
   ***********************************************************************************/
  PROCEDURE re_hire_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.�Čٗp�Ώۃf�[�^
    ir_retire_date IN DATE,             -- 2.�ސE��
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 're_hire_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    -- HR_EX_EMPLOYEE_API.RE_HIRE_EX_EMPLOYEE
    ln_assignment_sequence      per_all_assignments_f.assignment_sequence%TYPE;
    lb_assign_payroll_warning   BOOLEAN;
--
    -- �ސE�f�[�^�̑Ҕ�(PERSON_TYPE_ID:'EMP')
    ln_assignment_id_old        per_all_assignments_f.assignment_id%TYPE;
    ld_effective_start_date_old per_all_assignments_f.effective_start_date%TYPE;
--
    lv_api_name                 VARCHAR2(200); -- �G���[�g�[�N���p
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
    -- ���[�U���݃`�F�b�N
    check_fnd_user(
       ir_masters_rec
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ���[�U�擾�G���[
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;

    -- �]�ƈ��}�X�^�̑ސE�ヌ�R�[�h�̎擾�iPERSON_TYPE_ID:EX_EMP �̃��R�[�h���Čٗp���R�[�h�ɍX�V�j
    BEGIN
      SELECT object_version_number
      INTO   ir_masters_rec.pap_version
      FROM   per_all_people_f pap           -- �]�ƈ��}�X�^
      WHERE  pap.person_id = ir_masters_rec.person_id           -- �p�[�\��ID
      AND    pap.effective_start_date = (ir_retire_date + 1)    -- �o�^�N����(���Г�)
      AND    pap.effective_end_date >= (ir_retire_date + 1)     -- �o�^�����N����
      ;
    EXCEPTION
      WHEN OTHERS THEN
          RAISE global_api_others_expt;
    END;
--
    -- �]�ƈ��}�X�^�̗������R�[�h�̑Ҕ�
    ln_assignment_id_old        := ir_masters_rec.assignment_id;
    ld_effective_start_date_old := ir_masters_rec.effective_start_date;

    BEGIN
      -- �]�ƈ��}�X�^(API) -- �Čٗp --
      HR_EMPLOYEE_API.RE_HIRE_EX_EMPLOYEE(
        P_VALIDATE                  => FALSE
       ,P_HIRE_DATE                 =>  ir_masters_rec.hire_date    -- �Ј����̪��.���ДN����
       ,P_PERSON_ID                 =>  ir_masters_rec.person_id    -- �]�ƈ�ID
       ,P_PER_OBJECT_VERSION_NUMBER =>  ir_masters_rec.pap_version  -- �]�ƈ�Ͻ��ް�ޮݔԍ�(IN/OUT)
       ,P_PERSON_TYPE_ID            =>  gv_person_type              -- �p�[�\���^�C�v
       ,P_REHIRE_REASON             =>  NULL
       ,P_ASSIGNMENT_ID             =>  ir_masters_rec.assignment_id        -- OUT�i�V�������ID�j
       ,P_ASG_OBJECT_VERSION_NUMBER =>  ir_masters_rec.paa_version          -- OUT�i�V�������Ͻ��ް�ޮݔԍ��j
       ,P_PER_EFFECTIVE_START_DATE  =>  ir_masters_rec.effective_start_date -- OUT�i�V�o�^�N�����j
       ,P_PER_EFFECTIVE_END_DATE    =>  ir_masters_rec.effective_end_date   -- OUT�i�V�o�^�����N�����j
       ,P_ASSIGNMENT_SEQUENCE       =>  ln_assignment_sequence              -- OUT
       ,P_ASSIGNMENT_NUMBER         =>  ir_masters_rec.assignment_number    -- OUT�i�V������Ĕԍ��j
       ,P_ASSIGN_PAYROLL_WARNING    =>  lb_assign_payroll_warning           -- OUT
        );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EMPLOYEE_API.RE_HIRE_EX_EMPLOYEE';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;

    -- �A�T�C�������g�}�X�^�ɐV���R�[�h���쐬���ꂽ�ꍇ(UPDATE�ł͂Ȃ��������쐬 assignment_sequence�ඳ�ı���)
    IF ir_masters_rec.assignment_id <> ln_assignment_id_old THEN
      -- ���̋@�E�c�ƒ��[���ɁA�X�V���R�[�h�Ƃ��ĂQ���R�[�h��������ׁA���f�[�^��
      -- �����A�g�p���t�i���̋@�j�����A�g�p���t�i���[�j�ɍX�V���t���Z�b�g���������
      BEGIN
        UPDATE per_all_assignments_f
        SET    ASS_ATTRIBUTE17 = TO_CHAR(gd_last_update_date,'YYYYMMDD HH24:MI:SS')
              ,ASS_ATTRIBUTE18 = TO_CHAR(gd_last_update_date,'YYYYMMDD HH24:MI:SS')
        WHERE  assignment_id        = ln_assignment_id_old
        AND    effective_start_date = ld_effective_start_date_old
        AND    effective_end_date   >= ld_effective_start_date_old
        ;
      EXCEPTION
        WHEN OTHERS THEN
            RAISE global_api_others_expt;
      END;
    END IF;

    -- �A�T�C�������g�}�X�^�E�T�[�r�X���ԃ}�X�^�̐V���擾
    --(�Čٗp�����ł�updatemode���Ȃ��ׁA�������Ͻ��E���޽����Ͻ��������Ƃ��č쐬�����B�����Ď擾����j
    BEGIN
      SELECT paa.period_of_service_id,
             ppos.object_version_number
      INTO   ir_masters_rec.period_of_service_id,
             ir_masters_rec.ppos_version
      FROM   per_all_assignments_f paa,     -- �A�T�C�������g�}�X�^
             per_periods_of_service ppos    -- �]�ƈ��T�[�r�X���ԃ}�X�^
      WHERE  paa.assignment_id    = ir_masters_rec.assignment_id        -- �V�A�T�C�������gID
      AND    effective_start_date = ir_masters_rec.effective_start_date -- �o�^�N����
      AND    effective_end_date   = ir_masters_rec.effective_end_date   -- �o�^�����N����
      AND    ppos.period_of_service_id = paa.period_of_service_id;  -- �T�[�r�XID
    EXCEPTION
      WHEN OTHERS THEN
          RAISE global_api_others_expt;
    END;
--
    -- �Čٗp�����㎞�͎��Ə��̍X�V���s��
    ir_masters_rec.location_id_kbn := gv_sts_yes;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** API�֐��G���[��(�֐��g�p����) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
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
--#####################################  �Œ蕔 END   #############################################
--
  END re_hire_proc;
--
  /***********************************************************************************
   * Procedure Name   : re_hire_ass_proc
   * Description      : �Čٗp�o�^���s�����Ј��̃A�T�C�������g��o�^����v���V�[�W��
   ***********************************************************************************/
  PROCEDURE re_hire_ass_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.�Čٗp�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 're_hire_ass_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG
    lv_concatenated_segments    VARCHAR2(200);
    ln_soft_coding_keyflex_id   per_all_assignments_f.soft_coding_keyflex_id%type;
    ln_comment_id               per_all_people_f.comment_id%TYPE;
    lb_no_managers_warning      BOOLEAN;
    lb_other_manager_warning    BOOLEAN;

    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_special_ceiling_step_id      per_all_assignments_f.special_ceiling_step_id%type;
    ln_people_group_id              per_all_assignments_f.people_group_id%type;
    lv_group_name                   VARCHAR2(200);
    lb_org_now_no_manager_warning   BOOLEAN;
    lb_spp_delete_warning           BOOLEAN;
    lv_entries_changes_warn         VARCHAR2(1);
    lb_tax_district_changed_warn    BOOLEAN;

    lv_api_name                   VARCHAR2(200); -- �G���[�g�[�N���p
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
    -- �A�T�C�������g�}�X�^(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG(
         P_VALIDATE               =>  FALSE
        ,P_EFFECTIVE_DATE         =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE  =>  gv_upd_mode                       -- 'CORRECTION'
        ,P_ASSIGNMENT_ID          =>  ir_masters_rec.assignment_id      -- �������ID(�������擾)
        ,P_OBJECT_VERSION_NUMBER  =>  ir_masters_rec.paa_version        -- �������Ͻ��ް�ޮݔԍ�(IN/OUT)
        ,P_SUPERVISOR_ID          =>  ir_masters_rec.supervisor_id      -- �Ǘ���
        ,P_ASSIGNMENT_NUMBER      =>  ir_masters_rec.assignment_number  -- ������Ĕԍ�(�������擾)
        ,P_DEFAULT_CODE_COMB_ID   =>  gv_default                        -- ���̧�ٵ�߼��.��̫�Ĕ�p����
        ,P_ASS_ATTRIBUTE1         =>  ir_masters_rec.change_code        -- �ٓ����R�R�[�h
        ,P_ASS_ATTRIBUTE2         =>  ir_masters_rec.announce_date      -- ���ߓ�
        ,P_ASS_ATTRIBUTE3         =>  ir_masters_rec.office_location_code -- �Ζ��n���_�R�[�h�i�V�j
        ,P_ASS_ATTRIBUTE4         =>  ir_masters_rec.office_location_code_old -- �Ζ��n���_�R�[�h�i���j
        ,P_ASS_ATTRIBUTE5         =>  ir_masters_rec.location_code      -- ���_�R�[�h�i�V�j
        ,P_ASS_ATTRIBUTE6         =>  ir_masters_rec.location_code_old  -- ���_�R�[�h�i���j
        ,P_ASS_ATTRIBUTE7         =>  ir_masters_rec.job_system         -- �K�p�J�����Ԑ��R�[�h�i�V�j
        ,P_ASS_ATTRIBUTE8         =>  ir_masters_rec.job_system_name    -- �K�p�J�����i�V�j
        ,P_ASS_ATTRIBUTE9         =>  ir_masters_rec.job_system_old     -- �K�p�J�����Ԑ��R�[�h�i���j
        ,P_ASS_ATTRIBUTE10        =>  ir_masters_rec.job_system_name_old -- �K�p�J�����i���j
        ,P_ASS_ATTRIBUTE11        =>  ir_masters_rec.job_post_order     -- �E�ʕ����R�[�h�i�V�j
        ,P_ASS_ATTRIBUTE12        =>  ir_masters_rec.job_post_order_old -- �E�ʕ����R�[�h�i���j
        ,P_ASS_ATTRIBUTE13        =>  ir_masters_rec.consent_division   -- ���F�敪�i�V�j
        ,P_ASS_ATTRIBUTE14        =>  ir_masters_rec.consent_division_old -- ���F�敪�i���j
        ,P_ASS_ATTRIBUTE15        =>  ir_masters_rec.agent_division     -- ��s�敪�i�V�j
        ,P_ASS_ATTRIBUTE16        =>  ir_masters_rec.agent_division_old -- ��s�敪�i���j
        ,P_CONCATENATED_SEGMENTS  =>  lv_concatenated_segments          -- OUT
        ,P_SOFT_CODING_KEYFLEX_ID =>  ln_soft_coding_keyflex_id         -- IN/OUT
        ,P_COMMENT_ID             =>  ln_comment_id                     -- OUT
        ,P_EFFECTIVE_START_DATE   =>  ir_masters_rec.effective_start_date -- OUT�i�o�^�N�����j
        ,P_EFFECTIVE_END_DATE     =>  ir_masters_rec.effective_end_date -- OUT�i�o�^�����N�����j
        ,P_NO_MANAGERS_WARNING    =>  lb_no_managers_warning            -- OUT
        ,P_OTHER_MANAGER_WARNING  =>  lb_other_manager_warning          -- OUT
    );

    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;

    -- �A�T�C�������g�}�X�^(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
          P_VALIDATE                      =>  FALSE
        ,P_EFFECTIVE_DATE                =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE         =>  gv_upd_mode                      -- 'CORRECTION'
        ,P_ASSIGNMENT_ID                 =>  ir_masters_rec.assignment_id     -- �������ID(�������擾)
        ,P_LOCATION_ID                   =>  ir_masters_rec.location_id       -- ���Ə�(�Ζ��n���_�R�[�h�ύX���j
        ,P_OBJECT_VERSION_NUMBER         =>  ir_masters_rec.paa_version       -- �������Ͻ��ް�ޮݔԍ�(IN/OUT)
        ,P_SPECIAL_CEILING_STEP_ID       =>  ln_special_ceiling_step_id       -- OUT
        ,P_PEOPLE_GROUP_ID               =>  ln_people_group_id               -- OUT
        ,P_GROUP_NAME                    =>  lv_group_name                    -- OUT
        ,P_EFFECTIVE_START_DATE          =>  ir_masters_rec.effective_start_date --OUT�i�o�^�N�����j
        ,P_EFFECTIVE_END_DATE            =>  ir_masters_rec.effective_end_date -- OUT�i�o�^�����N�����j
        ,P_ORG_NOW_NO_MANAGER_WARNING    =>  lb_org_now_no_manager_warning    -- OUT
        ,P_OTHER_MANAGER_WARNING         =>  lb_other_manager_warning         -- OUT
        ,P_SPP_DELETE_WARNING            =>  lb_spp_delete_warning            -- OUT
        ,P_ENTRIES_CHANGED_WARNING       =>  lv_entries_changes_warn          -- OUT
        ,P_TAX_DISTRICT_CHANGED_WARNING  =>  lb_tax_district_changed_warn     -- OUT
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;

--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** API�֐��G���[��(�֐��g�p����) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
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
--#####################################  �Œ蕔 END   #############################################
--
  END re_hire_ass_proc;
--
  /***********************************************************************************
   * Procedure Name   : insert_proc
   * Description      : �V�K�Ј��̓o�^���s���v���V�[�W��
   ***********************************************************************************/
  PROCEDURE insert_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.�o�^�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- HR_EMPLOYEE_API.CREATE_EMPLOYEE
    lv_full_name                per_all_people_f.full_name%type;  -- �t���l�[��
    ln_per_comment_id           per_all_people_f.comment_id%type;
    ln_assignment_sequence      per_all_assignments_f.assignment_sequence%type;
    lb_name_combination_warning BOOLEAN;
    lb_assign_payroll_warning   BOOLEAN;
    lb_orig_hire_warning        BOOLEAN;

    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG
    lv_concatenated_segments    VARCHAR2(200);
    ln_soft_coding_keyflex_id   per_all_assignments_f.soft_coding_keyflex_id%type;
    ln_comment_id               per_all_people_f.comment_id%TYPE;
    lb_no_managers_warning      BOOLEAN;

    -- HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA
    ln_people_group_id              per_all_assignments_f.people_group_id%type;
    ln_special_ceiling_step_id      per_all_assignments_f.special_ceiling_step_id %type;
    lv_group_name                   VARCHAR2(200);
    lb_org_now_no_manager_warning   BOOLEAN;
    lb_other_manager_warning        BOOLEAN;
    lb_spp_delete_warning           BOOLEAN;
    lv_entries_changes_warn         VARCHAR2(200);
    lb_tax_district_changed_warn    BOOLEAN;
--
    lv_api_name                   VARCHAR2(200); -- �G���[�g�[�N���p
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
    -- �V�K�o�^�Ј�

    -- �]�ƈ��}�X�^(API)
    BEGIN
--
      HR_EMPLOYEE_API.CREATE_EMPLOYEE(
         P_VALIDATE                  =>  FALSE
        ,P_HIRE_DATE                 =>  ir_masters_rec.hire_date            -- ���ДN����
        ,P_BUSINESS_GROUP_ID         =>  gv_bisiness_grp_id                  -- �r�W�l�X�O���[�vID
        ,P_LAST_NAME                 =>  ir_masters_rec.last_name            -- �J�i��
        ,P_SEX                       =>  ir_masters_rec.sex                  -- ����
        ,P_PERSON_TYPE_ID            =>  gv_person_type                      -- �p�[�\���^�C�v
        ,P_EMPLOYEE_NUMBER           =>  ir_masters_rec.employee_number      -- �Ј��ԍ�
        ,P_FIRST_NAME                =>  ir_masters_rec.first_name           -- �J�i��
        ,P_ATTRIBUTE3                =>  ir_masters_rec.employee_division    -- �]�ƈ��敪
        ,P_ATTRIBUTE7                =>  ir_masters_rec.license_code         -- ���i�R�[�h�i�V�j
        ,P_ATTRIBUTE8                =>  ir_masters_rec.license_name         -- ���i���i�V�j
        ,P_ATTRIBUTE9                =>  ir_masters_rec.license_code_old     -- ���i�R�[�h�i���j
        ,P_ATTRIBUTE10               =>  ir_masters_rec.license_code_name_old -- ���i���i���j
        ,P_ATTRIBUTE11               =>  ir_masters_rec.job_post             -- �E�ʃR�[�h�i�V�j
        ,P_ATTRIBUTE12               =>  ir_masters_rec.job_post_name        -- �E�ʖ��i�V�j
        ,P_ATTRIBUTE13               =>  ir_masters_rec.job_post_old         -- �E�ʃR�[�h�i���j
        ,P_ATTRIBUTE14               =>  ir_masters_rec.job_post_name_old    -- �E�ʖ��i���j
        ,P_ATTRIBUTE15               =>  ir_masters_rec.job_duty             -- �E���R�[�h�i�V�j
        ,P_ATTRIBUTE16               =>  ir_masters_rec.job_duty_name        -- �E�����i�V�j
        ,P_ATTRIBUTE17               =>  ir_masters_rec.job_duty_old         -- �E���R�[�h�i���j
        ,P_ATTRIBUTE18               =>  ir_masters_rec.job_duty_name_old    -- �E�����i���j
        ,P_ATTRIBUTE19               =>  ir_masters_rec.job_type             -- �E��R�[�h�i�V�j
        ,P_ATTRIBUTE20               =>  ir_masters_rec.job_type_name        -- �E�햼�i�V�j
        ,P_ATTRIBUTE21               =>  ir_masters_rec.job_type_old         -- �E��R�[�h�i���j
        ,P_ATTRIBUTE22               =>  ir_masters_rec.job_type_name_old    -- �E�햼�i���j
        ,P_ATTRIBUTE28               =>  ir_masters_rec.location_code        -- �N�[����(�����R�[�h�i�V�j)
        ,P_ATTRIBUTE29               =>  ir_masters_rec.location_code        -- �Ɖ�͈�(�����R�[�h�i�V�j)
        ,P_ATTRIBUTE30               =>  ir_masters_rec.location_code        -- ���F�Ҕ͈�(�����R�[�h�i�V�j)
        ,P_PER_INFORMATION_CATEGORY  =>  gv_info_category                    -- 'JP'
        ,P_PER_INFORMATION18         =>  ir_masters_rec.last_name_kanji      -- ������
        ,P_PER_INFORMATION19         =>  ir_masters_rec.first_name_kanji     -- ������
        ,P_PERSON_ID                 =>  ir_masters_rec.person_id            -- OUT�i�]�ƈ�ID�j
        ,P_ASSIGNMENT_ID             =>  ir_masters_rec.assignment_id        -- OUT�i�������ID�j
        ,P_PER_OBJECT_VERSION_NUMBER =>  ir_masters_rec.pap_version          -- OUT�i�]�ƈ�Ͻ��ް�ޮݔԍ��j
        ,P_ASG_OBJECT_VERSION_NUMBER =>  ir_masters_rec.paa_version          -- OUT�i�������Ͻ��ް�ޮݔԍ��j
        ,P_PER_EFFECTIVE_START_DATE  =>  ir_masters_rec.effective_start_date -- OUT�i�o�^�N�����j
        ,P_PER_EFFECTIVE_END_DATE    =>  ir_masters_rec.effective_end_date   -- OUT�i�o�^�����N�����j
        ,P_FULL_NAME                 =>  lv_full_name                        -- OUT�i�t���l�[���j
        ,P_PER_COMMENT_ID            =>  ln_per_comment_id                   -- OUT
        ,P_ASSIGNMENT_SEQUENCE       =>  ln_assignment_sequence              -- OUT
        ,P_ASSIGNMENT_NUMBER         =>  ir_masters_rec.assignment_number    -- OUT�i������Ĕԍ��j
        ,P_NAME_COMBINATION_WARNING  =>  lb_name_combination_warning         -- OUT
        ,P_ASSIGN_PAYROLL_WARNING    =>  lb_assign_payroll_warning           -- OUT
        ,P_ORIG_HIRE_WARNING         =>  lb_orig_hire_warning                -- OUT
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_EMPLOYEE_API.CREATE_EMPLOYEE';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �A�T�C�������g�}�X�^(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG(
         P_VALIDATE              =>  FALSE
        ,P_EFFECTIVE_DATE        =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE =>  gv_upd_mode                             -- 'CORRECTION'
        ,P_ASSIGNMENT_ID         =>  ir_masters_rec.assignment_id            -- HR_EMPLOYEE_API.CREATE_EMPLOYEE�̏o�͍��ڂ�P_ASSIGNMENT_ID
        ,P_OBJECT_VERSION_NUMBER =>  ir_masters_rec.paa_version              -- IN/OUT(�������Ͻ��ް�ޮݔԍ�)
        ,P_SUPERVISOR_ID         =>  ir_masters_rec.supervisor_id            -- �Ǘ���
        ,P_ASSIGNMENT_NUMBER     =>  ir_masters_rec.assignment_number        -- HR_EMPLOYEE_API.CREATE_EMPLOYEE�̏o�͍��ڂ�P_ASSIGNMENT_NUMBER
        ,P_DEFAULT_CODE_COMB_ID  =>  gv_default                              -- ���̧�ٵ�߼��.��̫�Ĕ�p����
        ,P_ASS_ATTRIBUTE1        =>  ir_masters_rec.change_code              -- �ٓ����R�R�[�h
        ,P_ASS_ATTRIBUTE2        =>  ir_masters_rec.announce_date            -- ���ߓ�
        ,P_ASS_ATTRIBUTE3        =>  ir_masters_rec.office_location_code     -- �Ζ��n���_�R�[�h�i�V�j
        ,P_ASS_ATTRIBUTE4        =>  ir_masters_rec.office_location_code_old -- �Ζ��n���_�R�[�h�i���j
        ,P_ASS_ATTRIBUTE5        =>  ir_masters_rec.location_code            -- ���_�R�[�h�i�V�j
        ,P_ASS_ATTRIBUTE6        =>  ir_masters_rec.location_code_old        -- ���_�R�[�h�i���j
        ,P_ASS_ATTRIBUTE7        =>  ir_masters_rec.job_system               -- �K�p�J�����Ԑ��R�[�h�i�V�j
        ,P_ASS_ATTRIBUTE8        =>  ir_masters_rec.job_system_name          -- �K�p�J�����i�V�j
        ,P_ASS_ATTRIBUTE9        =>  ir_masters_rec.job_system_old           -- �K�p�J�����Ԑ��R�[�h�i���j
        ,P_ASS_ATTRIBUTE10       =>  ir_masters_rec.job_system_name_old      -- �K�p�J�����i���j
        ,P_ASS_ATTRIBUTE11       =>  ir_masters_rec.job_post_order           -- �E�ʕ����R�[�h�i�V�j
        ,P_ASS_ATTRIBUTE12       =>  ir_masters_rec.job_post_order_old       -- �E�ʕ����R�[�h�i���j
        ,P_ASS_ATTRIBUTE13       =>  ir_masters_rec.consent_division         -- ���F�敪�i�V�j
        ,P_ASS_ATTRIBUTE14       =>  ir_masters_rec.consent_division_old     -- ���F�敪�i���j
        ,P_ASS_ATTRIBUTE15       =>  ir_masters_rec.agent_division           -- ��s�敪�i�V�j
        ,P_ASS_ATTRIBUTE16       =>  ir_masters_rec.agent_division_old       -- ��s�敪�i���j
        ,P_ASS_ATTRIBUTE17       =>  NULL                                    -- �����A�g�p���t�i���̋@�j
        ,P_ASS_ATTRIBUTE18       =>  NULL                                    -- �����A�g�p���t�i���[�j
        ,P_CONCATENATED_SEGMENTS  => lv_concatenated_segments           -- OUT
        ,P_SOFT_CODING_KEYFLEX_ID => ln_soft_coding_keyflex_id          -- IN/OUT
        ,P_COMMENT_ID             => ln_comment_id                      -- OUT
        ,P_EFFECTIVE_START_DATE   => ir_masters_rec.effective_start_date -- OUT�i�o�^�N�����j
        ,P_EFFECTIVE_END_DATE     => ir_masters_rec.effective_end_date   -- OUT�i�o�^�����N�����j
        ,P_NO_MANAGERS_WARNING    => lb_no_managers_warning             -- OUT
        ,P_OTHER_MANAGER_WARNING  => lb_other_manager_warning           -- OUT
        );

    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;

    -- �A�T�C�������g�}�X�^(API)
    BEGIN
      HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA(
         P_VALIDATE                      =>  FALSE
        ,P_EFFECTIVE_DATE                =>  SYSDATE
        ,P_DATETRACK_UPDATE_MODE         =>  gv_upd_mode                        -- 'CORRECTION'
        ,P_ASSIGNMENT_ID                 =>  ir_masters_rec.assignment_id       -- �������ID(�������擾)
        ,P_LOCATION_ID                   =>  ir_masters_rec.location_id         -- ���Ə�(�Ζ��n���_�R�[�h���狁�߂�ID�j
        ,P_OBJECT_VERSION_NUMBER         =>  ir_masters_rec.paa_version         -- �������Ͻ��ް�ޮݔԍ�(IN/OUT)
        ,P_SPECIAL_CEILING_STEP_ID       =>  ln_special_ceiling_step_id         -- OUT
        ,P_PEOPLE_GROUP_ID               =>  ln_people_group_id                 -- OUT
        ,P_GROUP_NAME                    =>  lv_group_name                      -- OUT
        ,P_EFFECTIVE_START_DATE          =>  ir_masters_rec.effective_start_date --OUT�i�o�^�N�����j
        ,P_EFFECTIVE_END_DATE            =>  ir_masters_rec.effective_end_date  -- OUT�i�o�^�����N�����j
        ,P_ORG_NOW_NO_MANAGER_WARNING    =>  lb_org_now_no_manager_warning      -- OUT
        ,P_OTHER_MANAGER_WARNING         =>  lb_other_manager_warning           -- OUT
        ,P_SPP_DELETE_WARNING            =>  lb_spp_delete_warning              -- OUT
        ,P_ENTRIES_CHANGED_WARNING       =>  lv_entries_changes_warn            -- OUT
        ,P_TAX_DISTRICT_CHANGED_WARNING  =>  lb_tax_district_changed_warn       -- OUT
      );
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'HR_ASSIGNMENT_API.UPDATE_EMP_ASG_CRITERIA';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;

--
    -- �ސE���� (�ސE�敪=�fY�f�j** �V�K�o�^�Ј��f�[�^�ɑސE�N�������ݒ肳��Ă���ꍇ **
    IF ir_masters_rec.retire_kbn = gv_sts_yes THEN
      retire_proc(
        ir_masters_rec
       ,ir_masters_rec.actual_termination_date  -- �ސE��
       ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );

      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;

    -- ���[�U�}�X�^(API)
    -- �V�K�o�^�f�[�^�őސE�N�������ݒ肳��Ă���ꍇ�ɂ��Ή�
    BEGIN
      ir_masters_rec.user_id := FND_USER_PKG.CREATEUSERID(
                                X_USER_NAME             => ir_masters_rec.employee_number -- �Ј��ԍ�
                               ,X_OWNER                 => gv_owner --'CUST'
                               ,X_UNENCRYPTED_PASSWORD  => gv_password -- ���̧��
                               ,X_START_DATE            => ir_masters_rec.hire_date -- ���ДN����
                               ,X_END_DATE              => ir_masters_rec.actual_termination_date -- �ސE�N����
                               ,X_DESCRIPTION           => ir_masters_rec.last_name -- �J�i��
                               ,X_EMPLOYEE_ID           => ir_masters_rec.person_id --HR_EMPLOYEE_API.CREATE_EMPLOYEE�̏o�͍��ڂ�P_PERSON_ID
                               );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_api_name := 'FND_USER_PKG.CREATEUSERID';
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_api_err
                    ,iv_token_name1  => cv_tkn_apiname
                    ,iv_token_value1 => lv_api_name
                    ,iv_token_name2  => cv_tkn_ng_word
                    ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                    ,iv_token_name3  => cv_tkn_ng_data
                    ,iv_token_value3 => ir_masters_rec.employee_number
                    );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** API�֐��G���[��(�֐��g�p����) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
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
--#####################################  �Œ蕔 END   #############################################
--
  END insert_proc;
--
  /***********************************************************************************
   * Procedure Name   : update_proc
   * Description      : �����Ј��̍X�V���s���v���V�[�W��
   ***********************************************************************************/
  PROCEDURE update_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.�ٓ��Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    lv_api_name                 VARCHAR2(200); -- �G���[�g�[�N���p
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
    -- �����Ј��̓��ДN�����̕ύX(���Г��A�g�敪 = 'Y'�j
      -- 1.���ДN������ސE�N�����Ƃ��Đݒ肵�A�ސE�������s���B
      -- 2.�V���ДN�����ōČٗp�������s���B
    IF ir_masters_rec.ymd_kbn = gv_sts_yes THEN
      -- �ސE����
      retire_proc(
        ir_masters_rec
       ,ir_masters_rec.hire_date_old   -- �ސE���Ɋ������Г��Z�b�g
       ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;

      -- �Čٗp����
      re_hire_proc(
        ir_masters_rec
       ,ir_masters_rec.hire_date_old        -- �ސE���Ɋ������Г����Z�b�g
       ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;
    END IF;

    -- �����Ј��̏��ύX(�A�g�敪 = 'Y'�j
    IF ir_masters_rec.proc_kbn = gv_sts_yes THEN
      -- �ٓ�����
      changes_proc(
        ir_masters_rec
       ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;
    -- �����Ј��̏��ύX�Ȃ��̏ꍇ�A�Čٗp�����p���������s�� (�A�g�敪 = NULL,���Г��ύX�敪 = 'Y')
       -- �ސE���������̃f�[�^�͍X�V�͍s��Ȃ�
    ELSIF ir_masters_rec.ymd_kbn = gv_sts_yes THEN
      -- �Čٗp(�A�T�C�������g�}�X�^)����
      re_hire_ass_proc(
        ir_masters_rec
       ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;
    END IF;

    -- �ސE�N�������ݒ肳��Ă���ꍇ(�ސE�敪=�fY�f�j
    IF ir_masters_rec.retire_kbn = gv_sts_yes THEN
      retire_proc(
        ir_masters_rec
       ,ir_masters_rec.actual_termination_date  -- �ސE�����Z�b�g
       ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );

      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    IF  (ir_masters_rec.resp_kbn = gv_sts_yes)
     OR (ir_masters_rec.retire_kbn = gv_sts_yes) THEN  --�ސE��
      --���[�U�E�Ӄ}�X�^�̖�����
      delete_resp_all(
        ir_masters_rec
       ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--
      -- ���[�U�E�Ӄ}�X�^�X�V
      IF (ir_masters_rec.resp_kbn = gv_sts_yes) THEN
      --���[�U�E�Ӄ}�X�^�̐ݒ�
        update_resp_all(
          ir_masters_rec
         ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END IF;
      END IF;
--
    -- �ސE�N�������ݒ肳��Ă��Ȃ��ꍇ(�ސE�敪=NULL�jEND_DATE��NULL�ɐݒ�
    -- (�ސE����Ă���ꍇ�́Aretire_proc�ōX�V�ς�)
    IF (ir_masters_rec.retire_kbn IS NULL) THEN
   -- ���[�U�}�X�^(API)
      BEGIN
        FND_USER_PKG.UPDATEUSER(
          X_USER_NAME             =>  ir_masters_rec.employee_number  -- �Ј��ԍ�
         ,X_OWNER                 =>  gv_owner                        --'CUST'
         ,X_START_DATE            =>  ir_masters_rec.hire_date        -- ���ДN����
         ,X_END_DATE              =>  FND_USER_PKG.NULL_DATE          -- �L�����iNULL�j
        );
  --
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'FND_USER_PKG.UPDATEUSER';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;

    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    -- *** API�֐��G���[��(�֐��g�p����) ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf||SQLERRM,1,5000);
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
--#####################################  �Œ蕔 END   #############################################
--
  END update_proc;
--
  /***********************************************************************************
   * Procedure Name   : delete_proc
   * Description      : �ސE�҂̏������s���v���V�[�W��
   ***********************************************************************************/
  PROCEDURE delete_proc(
    ir_masters_rec IN OUT masters_rec,  -- 1.�ސE�Ώۃf�[�^
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_proc'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    lv_api_name                 VARCHAR2(200); -- �G���[�g�[�N���p
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
    -- �Čٗp����
    re_hire_proc(
      ir_masters_rec
     ,ir_masters_rec.effective_end_date   -- �ސE���Ɋ����ސE���Z�b�g
     ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
     ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );

    IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
    END IF;

    -- �����Ј��̏��ύX(�A�g�敪 = 'Y'�j
    IF (ir_masters_rec.proc_kbn = gv_sts_yes) THEN
      -- �ٓ�����
      changes_proc(
        ir_masters_rec
       ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;
    -- �����Ј��̏��ύX�Ȃ��̏ꍇ�A�Čٗp�����p���������s��(�A�g�敪 = NULL�j
    ELSE
      -- �Čٗp(�A�T�C�������g�}�X�^)����
      re_hire_ass_proc(
        ir_masters_rec
       ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;
    END IF;

    IF (ir_masters_rec.retire_kbn = gv_sts_yes) THEN
      -- �ސE����
      retire_proc(
        ir_masters_rec
       ,ir_masters_rec.actual_termination_date  -- �ސE���Z�b�g
       ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );

      IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
      END IF;

    END IF;
--
    -- ���[�U�E�Ӄ}�X�^(API)
    IF  (ir_masters_rec.resp_kbn = gv_sts_yes) THEN -- �ސE�҂͐E�Ӗ��ݒ�(delete_resp_all�͕s�v)
      -- ���[�U�E�Ӄ}�X�^�X�V
      update_resp_all(
        ir_masters_rec
       ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
       ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- �ސE�N�������ݒ肳��Ă��Ȃ��ꍇ(�ސE�敪=NULL�jEND_DATE��NULL�ɐݒ�
    -- (�ސE����Ă���ꍇ�́Aretire_proc�ōX�V�ς�)
    IF (ir_masters_rec.retire_kbn IS NULL) THEN
      -- ���[�U�}�X�^(API)
      BEGIN
        FND_USER_PKG.UPDATEUSER(
          X_USER_NAME             =>  ir_masters_rec.employee_number  -- �Ј��ԍ�
         ,X_OWNER                 =>  gv_owner                        --'CUST'
         ,X_START_DATE            =>  ir_masters_rec.hire_date        -- ���ДN����
         ,X_END_DATE              =>  FND_USER_PKG.NULL_DATE          -- �L�����iNULL�j
        );
  --
      EXCEPTION
        WHEN OTHERS THEN
          lv_api_name := 'FND_USER_PKG.UPDATEUSER';
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_api_err
                      ,iv_token_name1  => cv_tkn_apiname
                      ,iv_token_value1 => lv_api_name
                      ,iv_token_name2  => cv_tkn_ng_word
                      ,iv_token_value2 => cv_employee_nm    -- '�Ј��ԍ�'
                      ,iv_token_name3  => cv_tkn_ng_data
                      ,iv_token_value3 => ir_masters_rec.employee_number
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
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
--#####################################  �Œ蕔 END   #############################################
--
  END delete_proc;
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-2)
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
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_file_chk   BOOLEAN;   --���݃`�F�b�N����
    lv_file_size  NUMBER;    --�t�@�C���T�C�Y
    lv_block_size NUMBER;    --�u���b�N�T�C�Y
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
    -- ===============================
    -- �R���J�����g���b�Z�[�W�o��
    -- ===============================
    --���̓p�����[�^�Ȃ����b�Z�[�W�o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_input_no_msg
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

    -- ===============================
    -- �v���t�@�C���擾
    -- ===============================
    init_get_profile(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- CSV�t�@�C�����݃`�F�b�N
    -- ===============================
    UTL_FILE.FGETATTR(gv_directory,
                      gv_file_name,
                      lv_file_chk,
                      lv_file_size,
                      lv_block_size
    );
    -- �t�@�C�������݂��Ȃ��ꍇ�G���[
    IF (NOT lv_file_chk) THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_csv_file_err
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �E�ӎ����������[�N�폜����
    -- ===============================
    DELETE xxcmm.xxcmm_wk_people_resp;
--
    -- ===============================
    -- �Ɩ����t�̎擾
    -- ===============================
    cd_process_date := xxccp_common_pkg2.get_process_date;   -- �Ɩ����t --# �Œ� #
--
    IF (cd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_process_date_err
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    cc_process_date := TO_CHAR(cd_process_date,'YYYYMMDD');
--
    -- ===============================
    -- �p�[�\���^�C�v�̎擾
    -- ===============================
    -- �]�ƈ�
    get_person_type(
       gv_user_person_type
      ,gv_person_type
      ,gv_bisiness_grp_id
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �p�[�\���^�C�vID�擾�G���[
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;

    -- �ސE��
    get_person_type(
       gv_user_person_type_ex
      ,gv_person_type_ex
      ,gv_bisiness_grp_id_ex
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �p�[�\���^�C�vID�擾�G���[
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �Ј��C���^�t�F�[�X�O���`�F�b�N
    -- ===============================
    BEGIN
      SELECT 1
      INTO   gn_target_cnt
      FROM   xxcmm_in_people_if xip     -- �Ј��C���^�t�F�[�X
      WHERE  ROWNUM = 1;
    EXCEPTION
      -- �f�[�^�Ȃ��̏ꍇ�G���[
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_file_data_no_err
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- ===============================
    -- �t�@�C�����b�N����
    -- ===============================
    init_file_lock(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- �����ݒ菈��
    -- ===============================
--
    -- WHO�J�����̎擾
    gn_created_by             := FND_GLOBAL.USER_ID;           -- �쐬��
    gd_creation_date          := SYSDATE;                      -- �쐬��
    gn_last_update_by         := FND_GLOBAL.USER_ID;           -- �ŏI�X�V��
    gd_last_update_date       := SYSDATE;                      -- �ŏI�X�V��
    gn_last_update_login      := FND_GLOBAL.LOGIN_ID;          -- �ŏI�X�V���O�C��
    gn_request_id             := FND_GLOBAL.CONC_REQUEST_ID;   -- �v��ID
    gn_program_application_id := FND_GLOBAL.PROG_APPL_ID;      -- �v���O�����A�v���P�[�V����ID
    gn_program_id             := FND_GLOBAL.CONC_PROGRAM_ID;   -- �v���O����ID
    gd_program_update_date    := SYSDATE;                      -- �v���O�����X�V��
--
  EXCEPTION
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
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
--#####################################  �Œ蕔 END   #############################################
--
  END init;
--
  /***********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
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
    lr_masters_rec masters_rec; -- �����Ώۃf�[�^�i�[���R�[�h
--
    lt_insert_masters masters_tbl; -- �e�}�X�^�֓o�^����f�[�^
    lt_update_masters masters_tbl; -- �e�}�X�^�֍X�V����f�[�^
    lt_delete_masters masters_tbl; -- �e�}�X�^�֍폜����f�[�^
--
    ln_insert_cnt NUMBER;          -- �o�^����
    ln_update_cnt NUMBER;          -- �X�V����
    ln_delete_cnt NUMBER;          -- �폜����
    ln_exec_cnt   NUMBER;
    ln_log_cnt    NUMBER;
    lc_flg        CHAR(1) := ' ';  -- �d���f�[�^�p�t���O
    lb_retcd      BOOLEAN;         -- ��������
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
    -- �Ј��捞�C���^�[�t�F�[�X
    CURSOR in_if_cur
    IS
      SELECT xip.employee_number        employee_number,
             xip.hire_date              hire_date,
             xip.actual_termination_date  actual_termination_date,
             xip.last_name_kanji        last_name_kanji,
             xip.first_name_kanji       first_name_kanji,
             xip.last_name              last_name,
             xip.first_name             first_name,
             UPPER(xip.sex)             sex,
             NVL(xip.employee_division,'1')  employee_division,
             xip.location_code          location_code,
             xip.change_code            change_code,
             xip.announce_date          announce_date,
             xip.office_location_code   office_location_code,
             xip.license_code           license_code,
             xip.license_name           license_name,
             xip.job_post               job_post,
             xip.job_post_name          job_post_name,
             xip.job_duty               job_duty,
             xip.job_duty_name          job_duty_name,
             xip.job_type               job_type,
             xip.job_type_name          job_type_name,
             xip.job_system             job_system,
             xip.job_system_name        job_system_name,
             xip.job_post_order         job_post_order,
             xip.consent_division       consent_division,
             xip.agent_division         agent_division,
             xip.office_location_code_old  office_location_code_old,
             xip.location_code_old      location_code_old,
             xip.license_code_old       license_code_old,
             xip.license_code_name_old  license_code_name_old,
             xip.job_post_old           job_post_old,
             xip.job_post_name_old      job_post_name_old,
             xip.job_duty_old           job_duty_old,
             xip.job_duty_name_old      job_duty_name_old,
             xip.job_type_old           job_type_old,
             xip.job_type_name_old      job_type_name_old,
             xip.job_system_old         job_system_old,
             xip.job_system_name_old    job_system_name_old,
             xip.job_post_order_old     job_post_order_old,
             xip.consent_division_old   consent_division_old,
             xip.agent_division_old     agent_division_old
      FROM   xxcmm_in_people_if xip
      ORDER BY xip.employee_number;

--
    -- �E�ӎ����������[�N
    CURSOR wk_pr2_cur(lv_emp_kbn IN VARCHAR2)
    IS
      SELECT xwpr.employee_number,
             xwpr.responsibility_id,
             xwpr.user_id,
             xwpr.employee_kbn,
             xwpr.responsibility_key,
             xwpr.application_short_name,
             xwpr.start_date,
             xwpr.end_date
      FROM   xxcmm_wk_people_resp xwpr
      WHERE  xwpr.employee_kbn = lv_emp_kbn
      ORDER BY xwpr.employee_number,xwpr.responsibility_id;

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
    gn_target_cnt := 0; -- ��������
    gn_normal_cnt := 0; -- ��������
    gn_warn_cnt   := 0; -- �x������
    gn_error_cnt  := 0; -- �G���[����
    gn_skip_cnt   := 0; -- �X�L�b�v����
    gn_rep_n_cnt  := 0; -- ���|�[�g��
    gn_rep_w_cnt  := 0; -- ���|�[�g��
    ln_insert_cnt := 0;
    ln_update_cnt := 0;
    ln_delete_cnt := 0;
    gn_if := 0; -- �Ј��C���^�[�t�F�[�X����
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������(A-2)
    -- ===============================
    init(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
--
    -- ===============================
    -- �Ј��C���^�t�F�[�X���擾(A-3)
    -- ===============================
--
    -- IF�����̏�����
    gn_target_cnt := 0;

    <<in_if_loop>>
    FOR in_if_rec IN in_if_cur LOOP
      -- �X�e�[�^�X�̏�����
      gt_mst_tbl(gn_if).proc_flg := NULL;   -- �X�V�敪
      gt_mst_tbl(gn_if).proc_kbn := NULL;   -- �A�g�敪
      gt_mst_tbl(gn_if).emp_kbn := NULL;    -- �Ј����
      gt_mst_tbl(gn_if).ymd_kbn := NULL;    -- ���Г��A�g�敪
      gt_mst_tbl(gn_if).retire_kbn := NULL; -- �ސE�敪
      gt_mst_tbl(gn_if).resp_kbn := NULL;   -- �E�ӁE�Ǘ��ҕύX�敪

      -- �ޔ��������R�[�h�Ǝ����R�[�h�Ƃ̔�r��ɁA�ޔ����R�[�h��o�^�X�V�G���A�Ɋi�[(�Ј��ԍ��d���f�[�^�͍X�V���Ȃ���)
      IF (gn_target_cnt = 0) THEN
        NULL;
      ELSE
        IF (gt_mst_tbl(gn_if).employee_number <> in_if_rec.employee_number) THEN
          IF (lc_flg <> gv_flg_on) THEN
            NULL;  --����������
          ELSE
            lc_flg := ' ';
            lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_short_name
                        ,iv_name         => cv_data_check_err
                        ,iv_token_name1  => cv_tkn_ng_user
                        ,iv_token_value1 => gt_mst_tbl(gn_if).employee_number
                        ,iv_token_name2  => cv_tkn_ng_err
                        ,iv_token_value2 => cv_employee_err_nm  -- '�Ј��ԍ��d��'
                       );
            gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- �X�V�s�\
            gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
          END IF;
        ELSE
          lc_flg := gv_flg_on;
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_data_check_err
                      ,iv_token_name1  => cv_tkn_ng_user
                      ,iv_token_value1 => gt_mst_tbl(gn_if).employee_number
                      ,iv_token_name2  => cv_tkn_ng_err
                      ,iv_token_value2 => cv_employee_err_nm  -- '�Ј��ԍ��d��'
                     );
          gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- �X�V�s�\
          gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
        END IF;
      END IF;

      IF (gt_mst_tbl(gn_if).proc_flg IS NULL) AND (gn_target_cnt > 0) THEN
        -- ===============================
        -- �f�[�^�Ó����`�F�b�N����(A-4)
        -- ===============================
        in_if_check(
           gt_mst_tbl(gn_if)  -- �Ҕ��G���A
          ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        --�G���[�����i�������~�j
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        --�x�������i�x���f�[�^�X�V�s�E���f�[�^�����p���j
        ELSIF (lv_retcode = cv_status_warn) THEN
          gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- �X�V�s�\
          gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
        --���폈���F�ٓ��Ȃ��Ј��f�[�^�iSKIP�j
        ELSIF ((gt_mst_tbl(gn_if).proc_kbn IS NULL)         -- �A�g�Ȃ�
          AND (gt_mst_tbl(gn_if).ymd_kbn IS NULL)           -- ���Г��ύX�Ȃ�
          AND (gt_mst_tbl(gn_if).retire_kbn IS NULL)) THEN  -- �ސE�����Ȃ�
          gt_mst_tbl(gn_if).proc_flg := gv_sts_thru; -- �ύX�Ȃ�
--
        --���폈���F�V�K�Ј��f�[�^�i�o�^�j
        ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_new) THEN  -- �V�K�Ј�
          -- =================================
          -- �Ј��f�[�^�o�^���`�F�b�N����(A-5)
          -- =================================
          check_insert(
             gt_mst_tbl(gn_if)  -- �Ҕ��G���A
            ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          --�G���[�����i�������~�j
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          --�x�������i�x���f�[�^�X�V�s�E���f�[�^�����p���j
          ELSIF (lv_retcode = cv_status_warn) THEN
            gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- �X�V�s�\
            gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
          --���폈���F�V�K�Ј��f�[�^�i�o�^�j
          ELSE
            -- =================================
            -- �Ј��f�[�^�o�^���i�[����(A-8)
            -- =================================
            gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- �����Ώ�
            ln_insert_cnt := ln_insert_cnt + 1;
            lt_insert_masters(ln_insert_cnt) := gt_mst_tbl(gn_if);
          END IF;
--
        --���폈���F�����Ј��ٓ��f�[�^�E�ސE�Ј��Čٗp�f�[�^�i�X�V�j
        ELSE --(emp_kbn 'U'�F�����Ј��A'D'�F�ސE��)
          -- =================================
          -- �Ј��f�[�^�X�V���`�F�b�N����(A-6)
          -- =================================
          check_update(
             gt_mst_tbl(gn_if)  -- �Ҕ��G���A
            ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
            ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
            ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
          );
          --�G���[�����i�������~�j
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          --�x�������i�x���f�[�^�X�V�s�E���f�[�^�����p���j
          ELSIF (lv_retcode = cv_status_warn) THEN
            gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- �X�V�s�\
            gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
          --���폈���F�ٓ��Ȃ��iSKIP�j
          ELSIF (gt_mst_tbl(gn_if).proc_flg  = gv_sts_thru) THEN
            NULL;
          --���폈���F�����Ј��f�[�^�i�X�V�j
          ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_employee) THEN
            -- =================================
            -- �Ј��f�[�^�X�V���i�[����(A-9)
            -- =================================
            gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- �����Ώ�
            ln_update_cnt := ln_update_cnt + 1;
            lt_update_masters(ln_update_cnt) := gt_mst_tbl(gn_if);
          --���폈���F�ސE�Ј��f�[�^�i�X�V�j
          ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_retiree) THEN
            -- =================================
            -- �Ј��f�[�^�폜���i�[����(A-10)
            -- =================================
            gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- �����Ώ�
            ln_delete_cnt := ln_delete_cnt + 1;
            lt_delete_masters(ln_delete_cnt) := gt_mst_tbl(gn_if);
          END IF;
        END IF;
      END IF;

      -- �����̃J�E���g�A�b�v�i�ُ펞�ȊO�A��������=gn_skip_cnt + gn_normal_cnt + gn_warn_cnt �j
      -- �ٓ��Ȃ������i�X�L�b�v�j���J�E���g�A�b�v
      IF (gt_mst_tbl(gn_if).proc_flg = gv_sts_thru) THEN  -- �ٓ��Ȃ��f�[�^
        gn_skip_cnt := gn_skip_cnt + 1;
      -- �X�V�Ώی����i����j���J�E���g�A�b�v
      ELSIF (gt_mst_tbl(gn_if).proc_flg = gv_sts_update) THEN  -- �X�V�Ώ�
        gn_normal_cnt := gn_normal_cnt + 1;
      -- �X�V�Ώی����i�ُ�j���J�E���g�A�b�v
      ELSIF (gt_mst_tbl(gn_if).proc_flg = gv_sts_error) THEN  -- �X�V�s�\
        gn_warn_cnt := gn_warn_cnt + 1;
      -- �ُ팏�����J�E���g�A�b�v
      ELSE
        gn_error_cnt := gn_error_cnt +1;
      END IF;
--
      -- ==================================
      -- �Ј��f�[�^�G���[���i�[����(A-11)
      -- ==================================
      add_report(
        gt_mst_tbl(gn_if)  -- �Ҕ��G���A
--          ,lt_report_tbl
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
      END IF;
--

      -- �Ј��捞�C���^�t�F�[�X�̓��e���`�F�b�N�e�[�u���ɑҔ�(�����͂�������n�܂�)
      gn_target_cnt := gn_target_cnt + 1; -- ���������J�E���g�A�b�v
      BEGIN
        gn_if := gn_if + 1;
        gt_mst_tbl(gn_if).employee_number          := in_if_rec.employee_number;    --�Ј��ԍ�
        gt_mst_tbl(gn_if).hire_date                := in_if_rec.hire_date;          --���ДN����
        gt_mst_tbl(gn_if).actual_termination_date  := in_if_rec.actual_termination_date;--�ސE�N����
        gt_mst_tbl(gn_if).last_name_kanji          := in_if_rec.last_name_kanji;    --������
        gt_mst_tbl(gn_if).first_name_kanji         := in_if_rec.first_name_kanji;   --������
        gt_mst_tbl(gn_if).last_name                := in_if_rec.last_name;          --�J�i��
        gt_mst_tbl(gn_if).first_name               := in_if_rec.first_name;         --�J�i��
        gt_mst_tbl(gn_if).sex                      := UPPER(in_if_rec.sex);         --����
        gt_mst_tbl(gn_if).employee_division        := NVL(in_if_rec.employee_division,'1');  --�Ј��E�O���ϑ��敪
        gt_mst_tbl(gn_if).location_code            := in_if_rec.location_code;      --�����R�[�h�i�V�j
        gt_mst_tbl(gn_if).change_code              := in_if_rec.change_code;        --�ٓ����R�R�[�h
        gt_mst_tbl(gn_if).announce_date            := in_if_rec.announce_date;      --���ߓ�
        gt_mst_tbl(gn_if).office_location_code     := in_if_rec.office_location_code; --�Ζ��n���_�R�[�h�i�V�j
        gt_mst_tbl(gn_if).license_code             := in_if_rec.license_code;       --���i�R�[�h�i�V�j
        gt_mst_tbl(gn_if).license_name             := in_if_rec.license_name;       --���i���i�V�j
        gt_mst_tbl(gn_if).job_post                 := in_if_rec.job_post;           --�E�ʃR�[�h�i�V�j
        gt_mst_tbl(gn_if).job_post_name            := in_if_rec.job_post_name;      --�E�ʖ��i�V�j
        gt_mst_tbl(gn_if).job_duty                 := in_if_rec.job_duty;           --�E���R�[�h�i�V�j
        gt_mst_tbl(gn_if).job_duty_name            := in_if_rec.job_duty_name;      --�E�����i�V�j
        gt_mst_tbl(gn_if).job_type                 := in_if_rec.job_type;           --�E��R�[�h�i�V�j
        gt_mst_tbl(gn_if).job_type_name            := in_if_rec.job_type_name;      --�E�햼�i�V�j
        gt_mst_tbl(gn_if).job_system               := in_if_rec.job_system;         --�K�p�J�����Ԑ��R�[�h�i�V�j
        gt_mst_tbl(gn_if).job_system_name          := in_if_rec.job_system_name;    --�K�p�J�����i�V�j
        gt_mst_tbl(gn_if).job_post_order           := in_if_rec.job_post_order;     --�E�ʕ����R�[�h�i�V�j
        gt_mst_tbl(gn_if).consent_division         := in_if_rec.consent_division;   --���F�敪�i�V�j
        gt_mst_tbl(gn_if).agent_division           := in_if_rec.agent_division;     --��s�敪�i�V�j
        gt_mst_tbl(gn_if).office_location_code_old := in_if_rec.office_location_code_old; --�Ζ��n���_�R�[�h�i���j
        gt_mst_tbl(gn_if).location_code_old        := in_if_rec.location_code_old;  --�����R�[�h�i���j
        gt_mst_tbl(gn_if).license_code_old         := in_if_rec.license_code_old;   --���i�R�[�h�i���j
        gt_mst_tbl(gn_if).license_code_name_old    := in_if_rec.license_code_name_old;--���i���i���j
        gt_mst_tbl(gn_if).job_post_old             := in_if_rec.job_post_old;       --�E�ʃR�[�h�i���j
        gt_mst_tbl(gn_if).job_post_name_old        := in_if_rec.job_post_name_old;  --�E�ʖ��i���j
        gt_mst_tbl(gn_if).job_duty_old             := in_if_rec.job_duty_old;       --�E���R�[�h�i���j
        gt_mst_tbl(gn_if).job_duty_name_old        := in_if_rec.job_duty_name_old;  --�E�����i���j
        gt_mst_tbl(gn_if).job_type_old             := in_if_rec.job_type_old;       --�E��R�[�h�i���j
        gt_mst_tbl(gn_if).job_type_name_old        := in_if_rec.job_type_name_old;  --�E�햼�i���j
        gt_mst_tbl(gn_if).job_system_old           := in_if_rec.job_system_old;     --�K�p�J�����Ԑ��R�[�h�i���j
        gt_mst_tbl(gn_if).job_system_name_old      := in_if_rec.job_system_name_old;--�K�p�J�����i���j
        gt_mst_tbl(gn_if).job_post_order_old       := in_if_rec.job_post_order_old; --�E�ʕ����R�[�h�i���j
        gt_mst_tbl(gn_if).consent_division_old     := in_if_rec.consent_division_old; --���F�敪�i���j
        gt_mst_tbl(gn_if).agent_division_old       := in_if_rec.agent_division_old; --��s�敪�i���j
        gt_mst_tbl(gn_if).proc_flg := NULL;   -- �X�V�敪
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_data_check_err
                      ,iv_token_name1  => cv_tkn_ng_user
                      ,iv_token_value1 => gt_mst_tbl(gn_if).employee_number
                      ,iv_token_name2  => cv_tkn_ng_err
                      ,iv_token_value2 => cv_data_err  -- '�f�[�^�ُ�'
                     );
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END LOOP in_if_loop;
--
    -- �ŏI�f�[�^�`�F�b�N����(in_if_loop�̓��e�Ɠ��l)
    -- �X�e�[�^�X�̏�����
    gt_mst_tbl(gn_if).proc_kbn := NULL;   -- �A�g�敪
    gt_mst_tbl(gn_if).emp_kbn := NULL;    -- �Ј����
    gt_mst_tbl(gn_if).ymd_kbn := NULL;    -- ���Г��A�g�敪
    gt_mst_tbl(gn_if).retire_kbn := NULL; -- �ސE�敪
    gt_mst_tbl(gn_if).proc_flg := NULL;   -- �X�V�敪
    -- �Ј��f�[�^�d���`�F�b�N�i�O�̃f�[�^�Ɠ����ꍇ�j
    IF (lc_flg = gv_flg_on) THEN
      lc_flg := ' ';
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_data_check_err
                  ,iv_token_name1  => cv_tkn_ng_user
                  ,iv_token_value1 => gt_mst_tbl(gn_if).employee_number
                  ,iv_token_name2  => cv_tkn_ng_err
                  ,iv_token_value2 => cv_employee_err_nm  -- '�Ј��ԍ��d��'
                  );
      gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- �X�V�s�\
      gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
    ELSE
      -- ===============================
      -- �f�[�^�Ó����`�F�b�N����(A-4)
      -- ===============================
      in_if_check(
         gt_mst_tbl(gn_if)  -- �Ҕ��G���A
        ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      --�G���[�����i�������~�j
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_api_expt;
--
      --�x�������i�x���f�[�^�X�V�s�E���f�[�^�����p���j
      ELSIF (lv_retcode = cv_status_warn) THEN
        gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- �X�V�s�\
        gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
--
      --���폈���F�ٓ��Ȃ��Ј��f�[�^�iSKIP�j
      ELSIF ((gt_mst_tbl(gn_if).proc_kbn IS NULL)         -- �A�g�Ȃ�
        AND (gt_mst_tbl(gn_if).ymd_kbn IS NULL)           -- ���Г��ύX�Ȃ�
        AND (gt_mst_tbl(gn_if).retire_kbn IS NULL)) THEN  -- �ސE�����Ȃ�
        gt_mst_tbl(gn_if).proc_flg := gv_sts_thru; -- �ύX�Ȃ�
--
      --���폈���F�V�K�Ј��f�[�^�i�o�^�j
      ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_new) THEN  -- �V�K�Ј�
        -- =================================
        -- �Ј��f�[�^�o�^���`�F�b�N����(A-5)
        -- =================================
        check_insert(
           gt_mst_tbl(gn_if)  -- �Ҕ��G���A
          ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --�G���[�����i�������~�j
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        --�x�������i�x���f�[�^�X�V�s�E���f�[�^�����p���j
        ELSIF (lv_retcode = cv_status_warn) THEN
          gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- �X�V�s�\
          gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
        --���폈���F�V�K�Ј��f�[�^�i�o�^�j
        ELSE
          -- =================================
          -- �Ј��f�[�^�o�^���i�[����(A-8)
          -- =================================
          gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- �����Ώ�
          ln_insert_cnt := ln_insert_cnt + 1;
          lt_insert_masters(ln_insert_cnt) := gt_mst_tbl(gn_if);
        END IF;

      --���폈���F�����Ј��ٓ��f�[�^�E�ސE�Ј��Čٗp�f�[�^�i�X�V�j
      ELSE --(emp_kbn 'U'�F�����Ј��A'D'�F�ސE��)
        -- =================================
        -- �Ј��f�[�^�X�V���`�F�b�N����(A-6)
        -- =================================
        check_update(
           gt_mst_tbl(gn_if)  -- �Ҕ��G���A
          ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        --�G���[�����i�������~�j
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        --�x�������i�x���f�[�^�X�V�s�E���f�[�^�����p���j
        ELSIF (lv_retcode = cv_status_warn) THEN
          gt_mst_tbl(gn_if).proc_flg := gv_sts_error;  -- �X�V�s�\
          gt_mst_tbl(gn_if).row_err_message := lv_errmsg;
        --���폈���F�����Ј��f�[�^�i�X�V�j
        ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_employee) THEN
          -- =================================
          -- �Ј��f�[�^�X�V���i�[����(A-9)
          -- =================================
          gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- �����Ώ�
          ln_update_cnt := ln_update_cnt + 1;
          lt_update_masters(ln_update_cnt) := gt_mst_tbl(gn_if);
        --���폈���F�ٓ��Ȃ��iSKIP�j
        ELSIF (gt_mst_tbl(gn_if).proc_flg  = gv_sts_thru) THEN
          NULL;
        --���폈���F�ސE�Ј��f�[�^�i�X�V�j
        ELSIF (gt_mst_tbl(gn_if).emp_kbn  = gv_kbn_retiree) THEN
          -- =================================
          -- �Ј��f�[�^�폜���i�[����(A-10)
          -- =================================
          gt_mst_tbl(gn_if).proc_flg := gv_sts_update;  -- �����Ώ�
          ln_delete_cnt := ln_delete_cnt + 1;
          lt_delete_masters(ln_delete_cnt) := gt_mst_tbl(gn_if);
        END IF;
      END IF;
    END IF;

    -- �����̃J�E���g�A�b�v�i�ُ펞�ȊO�A��������=gn_skip_cnt + gn_normal_cnt + gn_warn_cnt �j
    -- �ٓ��Ȃ������i�X�L�b�v�j���J�E���g�A�b�v
    IF (gt_mst_tbl(gn_if).proc_flg = gv_sts_thru) THEN  -- �ٓ��Ȃ��f�[�^
      gn_skip_cnt := gn_skip_cnt + 1;
    -- �X�V�Ώی����i����j���J�E���g�A�b�v
    ELSIF (gt_mst_tbl(gn_if).proc_flg = gv_sts_update) THEN  -- �X�V�Ώ�
      gn_normal_cnt := gn_normal_cnt + 1;
    -- �X�V�Ώی����i�ُ�j���J�E���g�A�b�v
    ELSIF (gt_mst_tbl(gn_if).proc_flg = gv_sts_error) THEN  -- �X�V�s�\
      gn_warn_cnt := gn_warn_cnt + 1;
    -- �ُ팏�����J�E���g�A�b�v
    ELSE
      gn_error_cnt := gn_error_cnt +1;
    END IF;
--
    -- ==================================
    -- �Ј��f�[�^�G���[���i�[����(A-11)
    -- ==================================
    add_report(
      gt_mst_tbl(gn_if)  -- �Ҕ��G���A
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ================================
    -- �Ј��f�[�^���f����(A-12)
    -- ================================
--
    IF (ln_insert_cnt > 0) THEN
      -- �V�K�Ј��o�^����
      <<lt_insert_masters_loop>>
      FOR ln_cnt IN 1 .. ln_insert_cnt LOOP
        -- �V�K�Ј��o�^����
        insert_proc(
           lt_insert_masters(ln_cnt)
          ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END LOOP lt_insert_masters_loop;

      -- �V�K�Ј��̐E�ӂ͎Ј��E�ӎ����������[�N���ꊇ�o�^
      <<wk_pr2_loop>>
      FOR wk_pr2_rec IN wk_pr2_cur(gv_kbn_new) LOOP
      -- �V�K�Ј��o�^����
        insert_resp_all(
            wk_pr2_rec.employee_number
          ,wk_pr2_rec.responsibility_key
          ,wk_pr2_rec.application_short_name
          ,wk_pr2_rec.start_date
          ,wk_pr2_rec.end_date
          ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END LOOP wk_pr2_loop;
    END IF;
--
    IF (ln_update_cnt > 0) THEN
      -- �����Ј��X�V����
      <<lt_update_masters_loop>>
      FOR ln_cnt IN 1 .. ln_update_cnt LOOP
        -- �����Ј��ٓ�����
        update_proc(
           lt_update_masters(ln_cnt)
          ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END LOOP lt_update_masters_loop;
    END IF;
--
    IF (ln_delete_cnt > 0) THEN
      -- �ސE�ҍČٗp����
      <<lt_delete_masters_loop>>
      FOR ln_cnt IN 1..ln_delete_cnt LOOP
        -- �ސE�ҏ���
        delete_proc(
           lt_delete_masters(ln_cnt)
          ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
          ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
          ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_api_expt;
        END IF;
      END LOOP lt_update_masters_loop;
    END IF;
--
    -- ������
    ov_retcode := cv_status_normal;

    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
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
      -- �J�[�\�����J���Ă����
--
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
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
  )
  IS
--
--###########################  �Œ蕔 START   ###########################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    cv_normal     CONSTANT VARCHAR2(20) := '����f�[�^��';  -- ���b�Z�[�W
    cv_warning    CONSTANT VARCHAR2(20) := '�x���f�[�^��';  -- ���b�Z�[�W
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h

    lv_msgbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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

--###########################  �Œ蕔 END   #############################
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
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = cv_status_error) THEN
      --�G���[�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --�G���[���b�Z�[�W
      );
      --��s�}��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      --�ُ�G���[���́A���������O���A�X�L�b�v�����O���A�G���[�����P���ƌŒ�\��
      gn_normal_cnt := 0;
      gn_warn_cnt := 0;
      gn_error_cnt := 1;
      gn_skip_cnt := 0;
    ELSE
      IF (gn_normal_cnt > 0) THEN
      -- ���O�o�͏���(�����f�[�^�o��)
        disp_report(
          cv_status_normal
         ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_log_err_msg
                       ,iv_token_name1  => cv_tkn_ng_word
                       ,iv_token_value1 => cv_normal    -- '����f�[�^��'
                      );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
          lv_retcode := cv_status_normal;
        END IF;
      END IF;
--
    -- ���O�o�́E�������ʏo�� ����(�x���f�[�^�o�́F���X�V)
      IF (gn_warn_cnt > 0) THEN
        disp_report(
          cv_status_warn
         ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
         ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          gv_out_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name
                       ,iv_name         => cv_log_err_msg
                       ,iv_token_name1  => cv_tkn_ng_word
                       ,iv_token_value1 => cv_warning    -- '�x���f�[�^��'
                      );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => gv_out_msg
          );
        END IF;
        -- ���[�j���O�f�[�^������ꍇ�́A����f�[�^�L���Ă����[�j���O�I������B
        lv_retcode := cv_status_warn;
      END IF;
      --�x���������G���[�����Ƃ��Đݒ�
      gn_error_cnt := gn_warn_cnt;
    END IF;
--
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
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
                  iv_application  => cv_common_short_name
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
                  iv_application  => cv_common_short_name
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
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_skip_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
                  iv_application  => cv_common_short_name
                 ,iv_name         => lv_message_code
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );

    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ�E���팏���O���̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error)
    OR (gn_normal_cnt = 0) THEN
      ROLLBACK;
    END IF;

    -- ===============================
    -- CSV�t�@�C���폜����
    -- ===============================
    IF (retcode = cv_status_normal) THEN
      UTL_FILE.FREMOVE(gv_directory,   -- �o�͐�
                       gv_file_name    -- CSV�t�@�C����
      );
    END IF;

    -- ===============================
    -- �E�ӎ����������[�N�폜����
    -- ===============================
    DELETE xxcmm.xxcmm_wk_people_resp;

    -- ===============================
    -- �Ј��C���^�t�F�[�X�폜����
    -- ===============================
    DELETE xxcmm_in_people_if;
--
    COMMIT;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
--      UTL_FILE.FREMOVE(gv_directory,   -- �o�͐�
--                       gv_file_name    -- CSV�t�@�C����
--      );
      DELETE xxcmm_in_people_if;
      DELETE xxcmm_wk_people_resp;
      COMMIT;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
--      UTL_FILE.FREMOVE(gv_directory,   -- �o�͐�
--                       gv_file_name    -- CSV�t�@�C����
--      );
      DELETE xxcmm_in_people_if;
      DELETE xxcmm_wk_people_resp;
      COMMIT;
  END main;
--
--#####################################  �Œ蕔 END   #############################################
--
END XXCMM002A01C;
/
