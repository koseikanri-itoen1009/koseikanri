CREATE OR REPLACE PACKAGE BODY XXCFF016A35C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2012. All rights reserved.
 *
 * Package Name     : XXCFF016A35C(body)
 * Description      : ���[�X�_�񃁃��e�i���X
 * MD.050           : MD050_CFF_016_A35_���[�X�_�񃁃��e�i���X
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  chk_input_param        ���̓p�����[�^�`�F�b�N����(A-2)
 *  upd_comments           �����X�V����(A-3)
 *  submit_csv_conc        �b�r�u�o�͏���(A-4)
 *  ins_bk_table           �f�[�^�o�b�N�A�b�v����(A-5)
 *  upd_contract_headers   ���[�X�_��w�b�_�X�V����(A-6)
 *  get_contract_data      ���[�X�_�񖾍׃f�[�^�擾����(A-7)
 *  upd_contract_lines     ���[�X��ޔ���^���[�X�_�񖾍׍X�V����(A-8)
 *  ins_contract_histories ���[�X�_�񖾍ח���o�^����(A-9)
 *  create_pay_planning    �x���v��č쐬�^�t���O�X�V����(A-10)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/12    1.0   SCSK�J��         �V�K�쐬
 *  2013/02/12    1.1   SCSK����         �uE_�{�ғ�_09967�v�Ή�
 *  2013/02/27    1.2   SCSK����         �uE_�{�ғ�_09967�v�Ή� ���̓p�����[�^�`�F�b�N�ǉ�
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
  data_lock_expt            EXCEPTION;        -- ���R�[�h���b�N�G���[
  PRAGMA EXCEPTION_INIT(data_lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCFF016A35C';           -- �p�b�P�[�W��
  cv_appl_short_name_xxcff        CONSTANT VARCHAR2(100) := 'XXCFF';                  -- �A�v���P�[�V�����Z�k���i�A�h�I���F��v�E���[�X�EFA�̈�j
  cv_appl_short_name_xxccp        CONSTANT VARCHAR2(100) := 'XXCCP';                  -- �A�v���P�[�V�����Z�k���i�A�h�I���F���ʁEIF�̈�j
  cv_which_log                    CONSTANT VARCHAR2(100) := 'LOG';                    -- �R���J�����g���O�o�͐�
  cv_format_datetime              CONSTANT VARCHAR2(100) := 'YYYY/MM/DD HH24:MI:SS';  -- ��������
  cv_format_date                  CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';             -- ���t����
  cv_wide_space                   CONSTANT VARCHAR2(100) := '�@';                     -- �S�p�X�y�[�X
  cv_lease_kind_code_fin          CONSTANT VARCHAR2(100) := '0';                      -- ���[�X��ރR�[�h�FFin���[�X
  cv_contract_status_contract     CONSTANT VARCHAR2(100) := '202';                    -- �_��X�e�[�^�X�F�_��
  cv_contract_status_release      CONSTANT VARCHAR2(100) := '203';                    -- �_��X�e�[�^�X�F�ă��[�X
  cv_contract_status_maintenance  CONSTANT VARCHAR2(100) := '210';                    -- �_��X�e�[�^�X�F�f�[�^�����e�i���X
  cv_payment_type_month           CONSTANT VARCHAR2(100) := '0';                      -- �p�x�F��
  cv_payment_type_year            CONSTANT VARCHAR2(100) := '1';                      -- �p�x�F�N
  cn_max_payment_frequency_year   CONSTANT NUMBER := 50;                              -- �ő�x���񐔁i�p�x�F�N�j
  cn_max_payment_frequency_month  CONSTANT NUMBER := 600;                             -- �ő�x���񐔁i�p�x�F���j
  cv_conc_dev_status_error        CONSTANT VARCHAR2(100) := 'ERROR';                  -- �R���J�����g�X�e�[�^�X�F�ُ�
  cv_conc_dev_status_warning      CONSTANT VARCHAR2(100) := 'WARNING';                -- �R���J�����g�X�e�[�^�X�F�x��
  cv_trunc_format_month           CONSTANT VARCHAR2(100) := 'MM';                     -- TRUNC�����i���Ő؂�̂āi�����j�j
  cv_acct_if_flag_not_send        CONSTANT VARCHAR2(100) := '1';                      -- ��v�h�e�t���O�F�����M
  cv_acct_if_flag_sent            CONSTANT VARCHAR2(100) := '2';                      -- ��v�h�e�t���O�F���M��
  cv_payment_match_flag_matched   CONSTANT VARCHAR2(100) := '1';                      -- �ƍ��σt���O�F�ƍ���
  cv_pay_plan_shori_type_create   CONSTANT VARCHAR2(100) := '1';                      -- �x���v��쐬�����敪�F�o�^
-- Add 2013/02/27 Ver1.2 Start
  cv_payment_frequency_3          CONSTANT NUMBER := 3;                               -- �x���񐔁i�ŏI�x�������o�p��3��j
-- Add 2013/02/27 Ver1.2 End
  -- ���b�Z�[�W
  cv_msg_param_output             CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00206';       -- �p�����[�^�o�͗p
  cv_msg_common_err               CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00094';       -- ���ʊ֐��G���[
  cv_msg                          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00095';       -- �G���[���b�Z�[�W
  cv_msg_period_name_err          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00186';       -- ��v���Ԏ擾�G���[
  cv_msg_profile_err              CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00020';       -- �v���t�@�C���擾�G���[
  cv_msg_null_err                 CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00157';       -- �K�{�`�F�b�N�G���[
  cv_msg_all_null_err             CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00207';       -- �����e�i���X���ڒl�����̓G���[
  cv_msg_param_type_err           CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00200';       -- �p�����[�^�^�E�����G���[
  cv_msg_date_format_err          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00118';       -- ���t�_���G���[
  cv_msg_data_notfound_err        CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00062';       -- �擾�Ώۃf�[�^����
  cv_msg_lease_date_err           CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00201';       -- ���[�X�J�n���E���[�X�I�������փG���[
  cv_msg_payment_frequency_err    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00202';       -- �x���񐔑Ó����`�F�b�N�G���[
  cv_msg_date_context_err         CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00203';       -- ���t�Ó����`�F�b�N�G���[
  cv_msg_second_payment_date_err  CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00204';       -- 2��ڎx�����Ó����`�F�b�N�G���[
  cv_msg_data_lock_err            CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00007';       -- ���b�N�G���[
  cv_msg_update_err               CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00205';       -- �X�V�G���[
  cv_msg_conc_submit_err          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00197';       -- �R���J�����g���s�G���[
  cv_msg_conc_wait_err            CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00198';       -- �R���J�����g�ҋ@�G���[
  cv_msg_conc_proc_err            CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00199';       -- �R���J�����g�����G���[
  cv_msg_insert_err               CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00102';       -- �o�^�G���[
  cv_msg_select_err               CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00101';       -- �擾�G���[
  cv_msg_process_date_err         CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00092';       -- �Ɩ����t�擾�G���[
-- Add 2013/02/27 Ver1.2 Start
  cv_msg_last_payment_date_err    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00031';       -- �x�����Ó����G���[�i�ŏI�x�����j
-- Add 2013/02/27 Ver1.2 End
  -- �g�[�N��
  cv_tkn_param_name               CONSTANT VARCHAR2(100) := 'PARAM_NAME';             -- �p�����[�^�_����
  cv_tkn_param_val                CONSTANT VARCHAR2(100) := 'PARAM_VAL';              -- �p�����[�^���͒l
  cv_tkn_func_name                CONSTANT VARCHAR2(100) := 'FUNC_NAME';              -- �֐���
  cv_tkn_err_msg                  CONSTANT VARCHAR2(100) := 'ERR_MSG';                -- �G���[���b�Z�[�W
  cv_tkn_prof_name                CONSTANT VARCHAR2(100) := 'PROF_NAME';              -- �v���t�@�C����
  cv_tkn_input                    CONSTANT VARCHAR2(100) := 'INPUT';                  -- ���͒l
  cv_tkn_frequency                CONSTANT VARCHAR2(100) := 'FREQUENCY';              -- ��
  cv_tkn_date_object1             CONSTANT VARCHAR2(100) := 'DATE_OBJECT1';           -- ���t���ڂP
  cv_tkn_date_object2             CONSTANT VARCHAR2(100) := 'DATE_OBJECT2';           -- ���t���ڂQ
  cv_tkn_onward                   CONSTANT VARCHAR2(100) := 'ONWARD';                 -- �`�ȍ~
  cv_tkn_table_name               CONSTANT VARCHAR2(100) := 'TABLE_NAME';             -- �e�[�u���_����
  cv_tkn_syori                    CONSTANT VARCHAR2(100) := 'SYORI';                  -- �R���J�����g�_����
  cv_tkn_request_id               CONSTANT VARCHAR2(100) := 'REQUEST_ID';             -- �v��ID
  cv_tkn_info                     CONSTANT VARCHAR2(100) := 'INFO';                   -- ���
  -- �g�[�N���l
  cv_val_api_nm_put_log_param     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50210';       -- �R���J�����g�p�����[�^�o�͏���
  cv_val_api_nm_lease_kind        CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50207';       -- ���[�X��ޔ���
  cv_val_api_nm_create_pay_plan   CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50209';       -- ���[�X�x���v��쐬
  cv_val_contract_number          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50040';       -- �_��ԍ�
  cv_val_lease_company            CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50043';       -- ���[�X���
  cv_val_update_reason            CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50199';       -- �X�V���R
  cv_val_lease_start_date         CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50046';       -- ���[�X�J�n��
  cv_val_lease_end_date           CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50051';       -- ���[�X�I����
  cv_val_payment_frequency        CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50033';       -- �x����
  cv_val_contract_date            CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50134';       -- ���[�X�_���
  cv_val_first_payment_date       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50052';       -- ����x����
  cv_val_second_payment_date      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50053';       -- 2��ڎx����
  cv_val_third_payment_date       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50054';       -- 3��ڈȍ~�x����
  cv_val_comments                 CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50045';       -- ����
  cv_val_contract_number_colon    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50211';       -- �_��ԍ��F
  cv_val_lease_company_colon      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50212';       -- ���[�X��ЁF
  cv_val_contract_hdr_id_colon    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50213';       -- �_�����ID�F
  cv_val_contract_line_id_colon   CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50214';       -- �_�񖾍ד���ID�F
  cv_val_period_name_colon        CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50215';       -- ��v���ԁF
  cv_val_process_date             CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50216';       -- �Ɩ����t
  cv_val_two_months_after         CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50217';       -- ���X��
  cv_val_nex_year                 CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50218';       -- ���N�x
  cv_val_cont_hdr_tab_nm          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50219';       -- ���[�X�_��w�b�_
  cv_val_cont_line_tab_nm         CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50220';       -- ���[�X�_�񖾍�
  cv_val_cont_hdr_bk_tab_nm       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50221';       -- ���[�X�_��w�b�_BK
  cv_val_cont_line_bk_tab_nm      CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50200';       -- ���[�X�_�񖾍�BK
  cv_val_pay_plan_bk_tab_nm       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50201';       -- ���[�X�x���v��BK
  cv_val_cont_line_hist_tab_nm    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50094';       -- ���[�X�_�񖾍ח���
  cv_val_pay_plan_tab_nm          CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50088';       -- ���[�X�x���v��
  cv_val_prg_contract_csv         CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50203';       -- ���[�X�_��f�[�^CSV�o��
  cv_val_prg_object_csv           CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50204';       -- ���[�X�����f�[�^CSV�o��
  cv_val_prg_pay_planning_csv     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50205';       -- ���[�X�x���v��f�[�^CSV�o��
  cv_val_prg_accounting_csv       CONSTANT VARCHAR2(100) := 'APP-XXCFF1-50206';       -- ���[�X��v����CSV�o��
  -- �v���t�@�C��
  cv_prof_interval                CONSTANT VARCHAR2(100) := 'XXCOS1_INTERVAL';        -- XXCOS:�ҋ@�Ԋu
  cv_prof_max_wait                CONSTANT VARCHAR2(100) := 'XXCOS1_MAX_WAIT';        -- XXCOS:�ő�ҋ@����
  -- �v���O����
  cv_prg_contract_csv             CONSTANT VARCHAR2(100) := 'XXCCP008A01C';           -- ���[�X�_��f�[�^CSV�o��
  cv_prg_object_csv               CONSTANT VARCHAR2(100) := 'XXCCP008A02C';           -- ���[�X�����f�[�^CSV�o��
  cv_prg_pay_planning_csv         CONSTANT VARCHAR2(100) := 'XXCCP008A03C';           -- ���[�X�x���v��f�[�^CSV�o��
  cv_prg_accounting_csv           CONSTANT VARCHAR2(100) := 'XXCCP008A04C';           -- ���[�X��v����CSV�o��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- ���̓p�����[�^�i�[�p
  gv_param_contract_number      xxcff_contract_headers.contract_number%TYPE;          -- 1. �_��ԍ�  �i�K�{�j
  gv_param_lease_company        xxcff_contract_headers.lease_company%TYPE;            -- 2. ���[�X��Ёi�K�{�j
  gv_param_update_reason        xxcff_contract_histories.update_reason%TYPE;          -- 3. �X�V���R  �i�K�{�j
  gd_param_lease_start_date     xxcff_contract_headers.lease_start_date%TYPE;         -- 4. ���[�X�J�n��
  gd_param_lease_end_date       xxcff_contract_headers.lease_end_date%TYPE;           -- 5. ���[�X�I����
  gn_param_payment_frequency    xxcff_contract_headers.payment_frequency%TYPE;        -- 6. �x����
  gd_param_contract_date        xxcff_contract_headers.contract_date%TYPE;            -- 7. �_���
  gd_param_first_payment_date   xxcff_contract_headers.first_payment_date%TYPE;       -- 8. ����x����
  gd_param_second_payment_date  xxcff_contract_headers.second_payment_date%TYPE;      -- 9. �Q��ڎx����
  gn_param_third_payment_date   xxcff_contract_headers.third_payment_date%TYPE;       -- 10.�R��ڈȍ~�x����
  gv_param_comments             xxcff_contract_headers.comments%TYPE;                 -- 11.����
  --
  gv_period_name                fa_deprn_periods.period_name%TYPE;                    -- ���[�X�䒠�I�[�v������
  gd_calendar_period_close_date fa_deprn_periods.calendar_period_close_date%TYPE;     -- ���[�X�䒠�I�[�v�����Ԃ̃J�����_�I����
  gn_interval                   NUMBER;                                               -- �R���J�����g�ҋ@�Ԋu
  gn_max_wait                   NUMBER;                                               -- �R���J�����g�ő�ҋ@����
  gd_process_date               DATE;                                                 -- �Ɩ����t
  gn_rec_no                     NUMBER;                                               -- ���[�X�_�񖾍׏��e�[�u�����[�v�J�E���^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  -- ���[�X�_��w�b�_���
  CURSOR g_cont_hdr_cur(
    iv_contract_number  IN  VARCHAR2  -- �_��ԍ�
   ,iv_lease_company    IN  VARCHAR2  -- ���[�X���
  )
  IS
    SELECT  xch.contract_header_id    AS  contract_header_id  -- �_�����ID
           ,xch.contract_number       AS  contract_number     -- �_��ԍ�
           ,xch.lease_company         AS  lease_company       -- ���[�X���
-- Add 2013/02/12 Ver1.1 Start
           ,xch.contract_date         AS  contract_date       -- ���[�X�_���
-- Add 2013/02/12 Ver1.1 End
           ,xch.payment_frequency     AS  payment_frequency   -- �x����
           ,xch.payment_type          AS  payment_type        -- �p�x
           ,xch.lease_start_date      AS  lease_start_date    -- ���[�X�J�n��
           ,xch.lease_end_date        AS  lease_end_date      -- ���[�X�I����
           ,xch.first_payment_date    AS  first_payment_date  -- ����x����
           ,xch.second_payment_date   AS  second_payment_date -- 2��ڎx����
    FROM    xxcff_contract_headers    xch                     -- ���[�X�_��w�b�_
    WHERE   xch.contract_number     = iv_contract_number      -- �_��ԍ�
    AND     xch.lease_company       = iv_lease_company        -- ���[�X���
    AND     EXISTS
              ( SELECT  'X'
                FROM    xxcff_contract_lines    xcl           -- ���[�X�_�񖾍�
                WHERE   xcl.contract_header_id  = xch.contract_header_id            -- �_�����ID
                AND     xcl.contract_status     IN  ( cv_contract_status_contract
                                                    , cv_contract_status_release )  -- �_��X�e�[�^�X�i�_��, �ă��[�X�j
              )
    AND     ROWNUM = 1  -- �w�b�_���̂ݎ擾���邽�ߎ擾���R�[�h�͂P��
  ;
  -- ���[�X�_��w�b�_��񃌃R�[�h�^
  g_cont_hdr_rec      g_cont_hdr_cur%ROWTYPE;
--
  -- ���[�X�_�񖾍׏��
  CURSOR g_cont_line_cur(
    in_contract_header_id   IN  NUMBER  -- �_�����ID
  )
  IS
    SELECT  xch.contract_header_id    AS  contract_header_id    -- �_�����ID
           ,xch.contract_number       AS  contract_number       -- �_��ԍ�
           ,xch.lease_company         AS  lease_company         -- ���[�X���
           ,xch.contract_date         AS  contract_date         -- ���[�X�_���
           ,xch.payment_frequency     AS  payment_frequency     -- �x����
           ,xcl.contract_line_id      AS  contract_line_id      -- �_�񖾍ד���ID
           ,xcl.first_charge          AS  first_charge          -- ���񌎊z���[�X��_���[�X��
           ,xcl.first_tax_charge      AS  first_tax_charge      -- �������Ŋz_���[�X��
           ,xcl.second_charge         AS  second_charge         -- 2��ڈȍ~���z���[�X��_���[�X��
           ,xcl.first_deduction       AS  first_deduction       -- ���񌎊z���[�X��_�T���z
           ,xcl.second_deduction      AS  second_deduction      -- 2��ڈȍ~���z���[�X��_�T���z
           ,xcl.estimated_cash_price  AS  estimated_cash_price  -- ���ό����w�����z
           ,xcl.life_in_months        AS  life_in_months        -- �@��ϗp�N��
           ,xoh.object_header_id      AS  object_header_id      -- ��������ID
           ,xoh.object_code           AS  object_code           -- �����R�[�h
           ,xoh.lease_type            AS  lease_type            -- ���[�X�敪
    FROM    xxcff_contract_headers    xch                       -- ���[�X�_��w�b�_
           ,xxcff_contract_lines      xcl                       -- ���[�X�_�񖾍�
           ,xxcff_object_headers      xoh                       -- ���[�X����
    WHERE   xch.contract_header_id    = xcl.contract_header_id  -- �_�����ID
    AND     xcl.object_header_id      = xoh.object_header_id    -- ��������ID
    AND     xch.contract_header_id    = in_contract_header_id   -- �_�����ID
    AND     xcl.contract_status       IN  ( cv_contract_status_contract
                                          , cv_contract_status_release )  -- �_��X�e�[�^�X�i�_��, �ă��[�X
    FOR UPDATE OF xcl.contract_line_id NOWAIT                   -- ���[�X�_�񖾍׃��b�N
  ;
  -- ���[�X�_�񖾍׏�񃌃R�[�h�^
  g_cont_line_rec     g_cont_line_cur%ROWTYPE;
  -- ���[�X�_�񖾍׏��e�[�u���^
  TYPE g_cont_line_ttype IS TABLE OF g_cont_line_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_cont_line_tab     g_cont_line_ttype;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_contract_number      IN  VARCHAR2    -- 1. �_��ԍ�
   ,iv_lease_company        IN  VARCHAR2    -- 2. ���[�X���
   ,iv_update_reason        IN  VARCHAR2    -- 3. �X�V���R
   ,iv_lease_start_date     IN  VARCHAR2    -- 4. ���[�X�J�n��
   ,iv_lease_end_date       IN  VARCHAR2    -- 5. ���[�X�I����
   ,iv_payment_frequency    IN  VARCHAR2    -- 6. �x����
   ,iv_contract_date        IN  VARCHAR2    -- 7. �_���
   ,iv_first_payment_date   IN  VARCHAR2    -- 8. ����x����
   ,iv_second_payment_date  IN  VARCHAR2    -- 9. �Q��ڎx����
   ,iv_third_payment_date   IN  VARCHAR2    -- 10.�R��ڈȍ~�x����
   ,iv_comments             IN  VARCHAR2    -- 11.����
   ,ov_errbuf               OUT VARCHAR2    --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode              OUT VARCHAR2    --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg               OUT VARCHAR2)   --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_msg     VARCHAR2(5000);  -- ���b�Z�[�W
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
    -- ============================================
    -- �R���J�����g�p�����[�^�o�͏���
    --
    -- �����ʊ֐��Fxxcff_common1_pkg.put_log_param�ł�
    --   �p�����[�^��10�܂ł����o�͂ł��Ȃ����߁A���O�ŏo�͂���
    -- ============================================
    FND_FILE.PUT_LINE(FND_FILE.LOG, '');
    --
    -- 1. �_��ԍ�
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          => cv_msg_param_output          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1   => cv_tkn_param_name            -- �g�[�N���R�[�h1
                  ,iv_token_value1  => cv_val_contract_number       -- �g�[�N���l1
                  ,iv_token_name2   => cv_tkn_param_val             -- �g�[�N���R�[�h2
                  ,iv_token_value2  => iv_contract_number           -- �g�[�N���l2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 2. ���[�X���
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          => cv_msg_param_output          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1   => cv_tkn_param_name            -- �g�[�N���R�[�h1
                  ,iv_token_value1  => cv_val_lease_company         -- �g�[�N���l1
                  ,iv_token_name2   => cv_tkn_param_val             -- �g�[�N���R�[�h2
                  ,iv_token_value2  => iv_lease_company             -- �g�[�N���l2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 3. �X�V���R
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          => cv_msg_param_output          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1   => cv_tkn_param_name            -- �g�[�N���R�[�h1
                  ,iv_token_value1  => cv_val_update_reason         -- �g�[�N���l1
                  ,iv_token_name2   => cv_tkn_param_val             -- �g�[�N���R�[�h2
                  ,iv_token_value2  => iv_update_reason             -- �g�[�N���l2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 4. ���[�X�J�n��
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          => cv_msg_param_output          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1   => cv_tkn_param_name            -- �g�[�N���R�[�h1
                  ,iv_token_value1  => cv_val_lease_start_date      -- �g�[�N���l1
                  ,iv_token_name2   => cv_tkn_param_val             -- �g�[�N���R�[�h2
                  ,iv_token_value2  => TO_CHAR(TO_DATE(iv_lease_start_date, cv_format_datetime), cv_format_date)  -- �g�[�N���l2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 5. ���[�X�I����
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          => cv_msg_param_output          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1   => cv_tkn_param_name            -- �g�[�N���R�[�h1
                  ,iv_token_value1  => cv_val_lease_end_date        -- �g�[�N���l1
                  ,iv_token_name2   => cv_tkn_param_val             -- �g�[�N���R�[�h2
                  ,iv_token_value2  => TO_CHAR(TO_DATE(iv_lease_end_date, cv_format_datetime), cv_format_date)  -- �g�[�N���l2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 6. �x����
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          => cv_msg_param_output          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1   => cv_tkn_param_name            -- �g�[�N���R�[�h1
                  ,iv_token_value1  => cv_val_payment_frequency     -- �g�[�N���l1
                  ,iv_token_name2   => cv_tkn_param_val             -- �g�[�N���R�[�h2
                  ,iv_token_value2  => iv_payment_frequency         -- �g�[�N���l2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 7. �_���
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          => cv_msg_param_output          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1   => cv_tkn_param_name            -- �g�[�N���R�[�h1
                  ,iv_token_value1  => cv_val_contract_date         -- �g�[�N���l1
                  ,iv_token_name2   => cv_tkn_param_val             -- �g�[�N���R�[�h2
                  ,iv_token_value2  => TO_CHAR(TO_DATE(iv_contract_date, cv_format_datetime), cv_format_date) -- �g�[�N���l2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 8. ����x����
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          => cv_msg_param_output          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1   => cv_tkn_param_name            -- �g�[�N���R�[�h1
                  ,iv_token_value1  => cv_val_first_payment_date    -- �g�[�N���l1
                  ,iv_token_name2   => cv_tkn_param_val             -- �g�[�N���R�[�h2
                  ,iv_token_value2  => TO_CHAR(TO_DATE(iv_first_payment_date, cv_format_datetime), cv_format_date)  -- �g�[�N���l2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 9. �Q��ڎx����
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          => cv_msg_param_output          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1   => cv_tkn_param_name            -- �g�[�N���R�[�h1
                  ,iv_token_value1  => cv_val_second_payment_date   -- �g�[�N���l1
                  ,iv_token_name2   => cv_tkn_param_val             -- �g�[�N���R�[�h2
                  ,iv_token_value2  => TO_CHAR(TO_DATE(iv_second_payment_date, cv_format_datetime), cv_format_date) -- �g�[�N���l2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 10.�R��ڈȍ~�x����
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          => cv_msg_param_output          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1   => cv_tkn_param_name            -- �g�[�N���R�[�h1
                  ,iv_token_value1  => cv_val_third_payment_date    -- �g�[�N���l1
                  ,iv_token_name2   => cv_tkn_param_val             -- �g�[�N���R�[�h2
                  ,iv_token_value2  => iv_third_payment_date        -- �g�[�N���l2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    -- 11.����
    lv_msg := xxccp_common_pkg.get_msg(
                   iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                  ,iv_name          => cv_msg_param_output          -- ���b�Z�[�W�R�[�h
                  ,iv_token_name1   => cv_tkn_param_name            -- �g�[�N���R�[�h1
                  ,iv_token_value1  => cv_val_comments              -- �g�[�N���l1
                  ,iv_token_name2   => cv_tkn_param_val             -- �g�[�N���R�[�h2
                  ,iv_token_value2  => iv_comments                  -- �g�[�N���l2
                 );
    FND_FILE.PUT_LINE(FND_FILE.LOG, lv_msg);
    --
    FND_FILE.PUT_LINE(FND_FILE.LOG, '');
--
    -- ============================================
    -- ���[�X�䒠�I�[�v�����Ԏ擾
    -- ============================================
    BEGIN
      SELECT  fdp.period_name             AS  period_name                 -- ���Ԗ���
             ,calendar_period_close_date  AS  calendar_period_close_date  -- �J�����_�I����
      INTO    gv_period_name                                  -- ���[�X�䒠�I�[�v������
             ,gd_calendar_period_close_date                   -- ���[�X�䒠�I�[�v�����Ԃ̃J�����_�I����
      FROM    fa_deprn_periods      fdp                       -- �������p����
             ,xxcff_lease_kind_v    xlkv                      -- ���[�X��ރr���[
      WHERE   fdp.book_type_code    = xlkv.book_type_code     -- ���Y�䒠�R�[�h
      AND     xlkv.lease_kind_code  = cv_lease_kind_code_fin  -- ���[�X��ރR�[�h�iFin���[�X�j
      AND     fdp.period_close_date IS NULL                   -- �I�[�v������
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_period_name_err     -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- �v���t�@�C���l�̎擾
    -- ============================================
    -- XXCOS:�ҋ@�Ԋu
    gn_interval := TO_NUMBER(fnd_profile.value(cv_prof_interval));
    --
    IF (gn_interval IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_profile_err         -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_prof_name           -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_prof_interval           -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- XXCOS:�ő�ҋ@����
    gn_max_wait := TO_NUMBER(fnd_profile.value(cv_prof_max_wait));
    --
    IF (gn_max_wait IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_profile_err         -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_prof_name           -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_prof_max_wait           -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �Ɩ����t�擾
    -- ============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_process_date_err    -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_input_param
   * Description      : ���̓p�����[�^�`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE chk_input_param(
    iv_contract_number      IN  VARCHAR2    -- 1. �_��ԍ�
   ,iv_lease_company        IN  VARCHAR2    -- 2. ���[�X���
   ,iv_update_reason        IN  VARCHAR2    -- 3. �X�V���R
   ,iv_lease_start_date     IN  VARCHAR2    -- 4. ���[�X�J�n��
   ,iv_lease_end_date       IN  VARCHAR2    -- 5. ���[�X�I����
   ,iv_payment_frequency    IN  VARCHAR2    -- 6. �x����
   ,iv_contract_date        IN  VARCHAR2    -- 7. �_���
   ,iv_first_payment_date   IN  VARCHAR2    -- 8. ����x����
   ,iv_second_payment_date  IN  VARCHAR2    -- 9. �Q��ڎx����
   ,iv_third_payment_date   IN  VARCHAR2    -- 10.�R��ڈȍ~�x����
   ,iv_comments             IN  VARCHAR2    -- 11.����
   ,ov_errbuf               OUT VARCHAR2    --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode              OUT VARCHAR2    --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg               OUT VARCHAR2)   --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_input_param'; -- �v���O������
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
    ln_db_cnt             NUMBER;
-- Add 2013/02/27 Ver1.2 Start
    ld_last_payment_date      DATE; -- �ŏI�x����
    lt_param_lease_start_date xxcff_contract_headers.lease_start_date%TYPE;
    lt_param_lease_end_date   xxcff_contract_headers.lease_end_date%TYPE;
-- Add 2013/02/27 Ver1.2 End
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
    -- ============================================
    -- �K�{�`�F�b�N
    -- ============================================
    -- 1. �_��ԍ�
    IF (iv_contract_number IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_null_err            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_val_contract_number     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 2. ���[�X���
    IF (iv_lease_company IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_null_err            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_val_lease_company       -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- 3. �X�V���R
    IF (iv_update_reason IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_null_err            -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_val_update_reason       -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- �����e�i���X���ڂ����ׂĖ����͂̏ꍇ
    IF (  iv_lease_start_date     IS NULL   -- 4. ���[�X�J�n��
      AND iv_lease_end_date       IS NULL   -- 5. ���[�X�I����
      AND iv_payment_frequency    IS NULL   -- 6. �x����
      AND iv_contract_date        IS NULL   -- 7. �_���
      AND iv_first_payment_date   IS NULL   -- 8. ����x����
      AND iv_second_payment_date  IS NULL   -- 9. �Q��ڎx����
      AND iv_third_payment_date   IS NULL   -- 10.�R��ڈȍ~�x����
      AND iv_comments             IS NULL   -- 11.����
    )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_all_null_err            -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;

--
    -- ============================================
    -- �^�^�����`�F�b�N
    -- �i�`�F�b�N�Ɠ����ɓ��̓p�����[�^���O���[�o���ϐ��֊i�[����j
    -- ============================================
    -- 1. �_��ԍ�
    BEGIN
      gv_param_contract_number := iv_contract_number;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_param_type_err      -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_contract_number     -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 2. ���[�X���
    BEGIN
      gv_param_lease_company := iv_lease_company;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_param_type_err      -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_lease_company       -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 3. �X�V���R
    BEGIN
      gv_param_update_reason := iv_update_reason;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_param_type_err      -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_update_reason       -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 4. ���[�X�J�n��
    BEGIN
      gd_param_lease_start_date := TO_DATE(iv_lease_start_date, cv_format_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_date_format_err     -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_lease_start_date    -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 5. ���[�X�I����
    BEGIN
      gd_param_lease_end_date := TO_DATE(iv_lease_end_date, cv_format_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_date_format_err     -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_lease_end_date      -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 6. �x����
    BEGIN
      gn_param_payment_frequency := iv_payment_frequency;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_param_type_err      -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_payment_frequency   -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 7. �_���
    BEGIN
      gd_param_contract_date := TO_DATE(iv_contract_date, cv_format_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_date_format_err     -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_contract_date       -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 8. ����x����
    BEGIN
      gd_param_first_payment_date := TO_DATE(iv_first_payment_date, cv_format_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_date_format_err     -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_first_payment_date  -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 9. �Q��ڎx����
    BEGIN
      gd_param_second_payment_date := TO_DATE(iv_second_payment_date, cv_format_datetime);
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_date_format_err     -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_second_payment_date -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 10.�R��ڈȍ~�x����
    BEGIN
      gn_param_third_payment_date := iv_third_payment_date;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_param_type_err      -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_third_payment_date  -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --
    -- 11.����
    BEGIN
      gv_param_comments := iv_comments;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_param_type_err      -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_input               -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_comments            -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- ���݃`�F�b�N�^�Ώۃf�[�^�擾
    -- ============================================
    -- ���[�X�_��w�b�_���̎擾
    OPEN  g_cont_hdr_cur(
      iv_contract_number  =>  gv_param_contract_number  -- �_��ԍ�
     ,iv_lease_company    =>  gv_param_lease_company    -- ���[�X���
    );
    FETCH g_cont_hdr_cur INTO  g_cont_hdr_rec;
    ln_db_cnt := g_cont_hdr_cur%ROWCOUNT;
    CLOSE g_cont_hdr_cur;
    --
    -- �Ώۃf�[�^�Ȃ�
    IF (ln_db_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_data_notfound_err     -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �u���[�X�J�n���v�^�u���[�X�I�����v���փ`�F�b�N
    -- ============================================
    -- ����������͂�����ꍇ�A�G���[
    IF (    ( gd_param_lease_start_date IS NOT NULL )
       AND  ( gd_param_lease_end_date   IS NOT NULL ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_lease_date_err        -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �u�x���񐔁v�Ó����`�F�b�N
    -- ============================================
    -- �x���񐔂ɓ��͂���
    IF (gn_param_payment_frequency IS NOT NULL) THEN
--
      -- �p�x �� �N�̏ꍇ�A�x���� �� 50 �ŃG���[
      IF (    ( g_cont_hdr_rec.payment_type = cv_payment_type_year )
         AND  ( gn_param_payment_frequency  > cn_max_payment_frequency_year ) )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff                 -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_payment_frequency_err             -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_frequency                         -- �g�[�N���R�[�h1
                      ,iv_token_value1  => TO_CHAR(cn_max_payment_frequency_year)   -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      -- �p�x �� ���̏ꍇ�A�x���� �� 600 �ŃG���[
      ELSIF (   ( g_cont_hdr_rec.payment_type = cv_payment_type_month )
            AND ( gn_param_payment_frequency  > cn_max_payment_frequency_month ) )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff                 -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_payment_frequency_err             -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_frequency                         -- �g�[�N���R�[�h1
                      ,iv_token_value1  => TO_CHAR(cn_max_payment_frequency_month)  -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      ELSE
        NULL;
      END IF;
    END IF;
--
-- Add 2013/02/27 Ver1.2 Start
    -- ============================================
    -- �u���[�X�J�n���v�܂��́u���[�X�I�����v�̓��o
    -- ============================================
    -- ���̓p�����[�^�u���[�X�J�n���v�u���[�X�I�����v�u�x���񐔁v�̂����ꂩ�P�ł��ݒ肳��Ă���ꍇ�̂�
    IF ( ( gd_param_lease_start_date  IS NOT NULL )
      OR ( gd_param_lease_end_date    IS NOT NULL )
      OR ( gn_param_payment_frequency IS NOT NULL ) )
    THEN
      -- ���̓p�����[�^�ޔ�
      lt_param_lease_start_date := gd_param_lease_start_date;
      lt_param_lease_end_date   := gd_param_lease_end_date;
      --
      -- ���̓p�����[�^�u���[�X�J�n���v��NULL�̏ꍇ
      IF ( gd_param_lease_start_date IS NOT NULL ) THEN
        -- ���[�X�I����
        gd_param_lease_end_date := CASE g_cont_hdr_rec.payment_type      -- �p�x
                                     WHEN cv_payment_type_month THEN     -- ��
                                       ( ADD_MONTHS(gd_param_lease_start_date, NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency)) - 1 )
                                     WHEN cv_payment_type_year  THEN     -- �N
                                       ( ADD_MONTHS(gd_param_lease_start_date, 12 * NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency)) - 1 )
                                   END;
      -- ���̓p�����[�^�u���[�X�J�n���v��NULL�̏ꍇ
      ELSE
        --
        -- ���̓p�����[�^�u�x���񐔁v��NULL�̏ꍇ
        IF ( gn_param_payment_frequency IS NOT NULL ) THEN
          --
          -- ���̓p�����[�^�u���[�X�I�����v��NULL�̏ꍇ
          IF ( gd_param_lease_end_date IS NOT NULL ) THEN
            -- ���[�X�J�n��
            gd_param_lease_start_date := CASE g_cont_hdr_rec.payment_type     -- �p�x
                                          WHEN cv_payment_type_month THEN     -- ��
                                            ( ADD_MONTHS(gd_param_lease_end_date, -1  * gn_param_payment_frequency) + 1 )
                                          WHEN cv_payment_type_year  THEN     -- �N
                                            ( ADD_MONTHS(gd_param_lease_end_date, -12 * gn_param_payment_frequency) + 1 )
                                         END;
          -- ���̓p�����[�^�u���[�X�I�����v��NULL�̏ꍇ
          ELSE
            -- ���[�X�J�n��
            gd_param_lease_start_date := g_cont_hdr_rec.lease_start_date;
            -- ���[�X�I����
            gd_param_lease_end_date   := CASE g_cont_hdr_rec.payment_type      -- �p�x
                                           WHEN cv_payment_type_month THEN     -- ��
                                             ( ADD_MONTHS(gd_param_lease_start_date, gn_param_payment_frequency) - 1 )
                                           WHEN cv_payment_type_year  THEN     -- �N
                                             ( ADD_MONTHS(gd_param_lease_start_date, 12 * gn_param_payment_frequency) - 1 )
                                         END;
          END IF;
        -- ���̓p�����[�^�u�x���񐔁v��NULL�̏ꍇ
        ELSE
          --
          -- ���̓p�����[�^�u���[�X�I�����v��NULL�̏ꍇ
          IF ( gd_param_lease_end_date IS NOT NULL ) THEN
            -- ���[�X�J�n��
            gd_param_lease_start_date := CASE g_cont_hdr_rec.payment_type     -- �p�x
                                          WHEN cv_payment_type_month THEN     -- ��
                                            ( ADD_MONTHS(gd_param_lease_end_date, -1  * g_cont_hdr_rec.payment_frequency) + 1 )
                                          WHEN cv_payment_type_year  THEN     -- �N
                                            ( ADD_MONTHS(gd_param_lease_end_date, -12 * g_cont_hdr_rec.payment_frequency) + 1 )
                                         END;
          -- ���̓p�����[�^�u���[�X�I�����v��NULL�̏ꍇ
          ELSE
            -- ���[�X�J�n��
            gd_param_lease_start_date := g_cont_hdr_rec.lease_start_date;
            -- ���[�X�I����
            gd_param_lease_end_date   := g_cont_hdr_rec.lease_end_date;
          END IF;
          --
        END IF;
        --
      END IF;
      --
    END IF;
-- Add 2013/02/27 Ver1.2 End
--
    -- ============================================
    -- �u���[�X�_����v�Ó����`�F�b�N
    -- ============================================
    -- ���[�X�_����ɓ��͂���
-- Del 2013/02/12 Ver1.1 Start
--    IF (gd_param_contract_date IS NOT NULL) THEN
-- Del 2013/02/12 Ver1.1 End
--
      -- ���[�X�_��� �� �Ɩ����t �̏ꍇ�A�G���[
      IF (gd_param_contract_date > gd_process_date) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_date_context_err    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_date_object1        -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_contract_date       -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_date_object2        -- �g�[�N���R�[�h2
                      ,iv_token_value2  => cv_val_process_date        -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- ���[�X�_��� �� ���[�X�J�n�� �̏ꍇ�A�G���[
-- Mod 2013/02/12 Ver1.1 Start
--      IF ( gd_param_contract_date >
      IF (NVL(gd_param_contract_date, g_cont_hdr_rec.contract_date) >
-- Mod 2013/02/12 Ver1.1 End
            NVL(gd_param_lease_start_date, g_cont_hdr_rec.lease_start_date) )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_date_context_err    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_date_object1        -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_contract_date       -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_date_object2        -- �g�[�N���R�[�h2
                      ,iv_token_value2  => cv_val_lease_start_date    -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- ���[�X�_��� �� ����x���� �̏ꍇ�A�G���[
-- Mod 2013/02/12 Ver1.1 Start
--      IF ( gd_param_contract_date >
      IF (NVL(gd_param_contract_date, g_cont_hdr_rec.contract_date) >
-- Mod 2013/02/12 Ver1.1 End
            NVL(gd_param_first_payment_date, g_cont_hdr_rec.first_payment_date) )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_date_context_err    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_date_object1        -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_contract_date       -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_date_object2        -- �g�[�N���R�[�h2
                      ,iv_token_value2  => cv_val_first_payment_date  -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
-- Del 2013/02/12 Ver1.1 Start
--    END IF;
-- Del 2013/02/12 Ver1.1 End
--
    -- ============================================
    -- �u����x�����v�Ó����`�F�b�N
    -- ============================================
    -- ����x�����ɓ��͂���
-- Del 2013/02/12 Ver1.1 Start
--    IF (gd_param_first_payment_date IS NOT NULL) THEN
-- Del 2013/02/12 Ver1.1 End
-- Add 2013/02/27 Ver1.2 Start
    -- ���[�X�J�n�� �� ����x���� �̏ꍇ�A�G���[
    IF ( NVL(gd_param_lease_start_date, g_cont_hdr_rec.lease_start_date) >
           NVL(gd_param_first_payment_date, g_cont_hdr_rec.first_payment_date) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_date_context_err    -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_date_object1        -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_val_lease_start_date    -- �g�[�N���l1
                    ,iv_token_name2   => cv_tkn_date_object2        -- �g�[�N���R�[�h2
                    ,iv_token_value2  => cv_val_first_payment_date  -- �g�[�N���l2
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
-- Add 2013/02/27 Ver1.2 End
--
      -- ����x���� �� �Q��ڎx���� �̏ꍇ�A�G���[
-- Mod 2013/02/12 Ver1.1 Start
--      IF ( gd_param_first_payment_date >
      IF ( NVL(gd_param_first_payment_date, g_cont_hdr_rec.first_payment_date) >
-- Mod 2013/02/12 Ver1.1 End
            NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date) )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_date_context_err    -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_date_object1        -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_first_payment_date  -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_date_object2        -- �g�[�N���R�[�h2
                      ,iv_token_value2  => cv_val_second_payment_date -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
-- Del 2013/02/12 Ver1.1 Start
--    END IF;
-- Del 2013/02/12 Ver1.1 End
--
    -- ============================================
    -- �u�Q��ڎx�����v�Ó����`�F�b�N
    -- ============================================
    -- �Q��ڎx�����ɓ��͂���
-- Del 2013/02/12 Ver1.1 Start
--    IF (gd_param_second_payment_date IS NOT NULL) THEN
-- Del 2013/02/12 Ver1.1 End
--
      -- �p�x �� ���̏ꍇ
      IF (g_cont_hdr_rec.payment_type = cv_payment_type_month) THEN
--
        -- �Q��ڎx����������x�����̗��X���ȍ~�ŃG���[
-- Mod 2013/02/12 Ver1.1 Start
--        IF ( gd_param_second_payment_date >=
        IF ( NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date) >=
-- Mod 2013/02/12 Ver1.1 End
               ADD_MONTHS( NVL(gd_param_first_payment_date, g_cont_hdr_rec.first_payment_date), 2 ) )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appl_short_name_xxcff         -- �A�v���P�[�V�����Z�k��
                        ,iv_name          => cv_msg_second_payment_date_err   -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   => cv_tkn_onward                    -- �g�[�N���R�[�h1
                        ,iv_token_value1  => cv_val_two_months_after          -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
      -- �p�x �� �N�̏ꍇ
      ELSIF (g_cont_hdr_rec.payment_type = cv_payment_type_year) THEN
--
        -- �Q��ڎx����������x�����̗��N�x�ȍ~�ŃG���[
-- Mod 2013/02/12 Ver1.1 Start
--        IF ( gd_param_second_payment_date >=
        IF ( NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date) >=
-- Mod 2013/02/12 Ver1.1 End
               ADD_MONTHS( NVL(gd_param_first_payment_date, g_cont_hdr_rec.first_payment_date), 12 ) )
        THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appl_short_name_xxcff         -- �A�v���P�[�V�����Z�k��
                        ,iv_name          => cv_msg_second_payment_date_err   -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   => cv_tkn_onward                    -- �g�[�N���R�[�h1
                        ,iv_token_value1  => cv_val_nex_year                  -- �g�[�N���l1
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
      END IF;
-- Del 2013/02/12 Ver1.1 Start
--    END IF;
-- Del 2013/02/12 Ver1.1 End
-- Add 2013/02/27 Ver1.2 Start
    -- �x���񐔁�3�̏ꍇ
    IF ( NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency) < cv_payment_frequency_3 ) THEN
      -- �ŏI�x����
      ld_last_payment_date := NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date);
    ELSE
      -- �������ȊO�̏ꍇ
      IF ( NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date) <>
             LAST_DAY(NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date)) )
      THEN
        -- �ŏI�x����
        ld_last_payment_date := CASE g_cont_hdr_rec.payment_type      -- �p�x
                                  WHEN cv_payment_type_month THEN     -- ��
                                    ( ADD_MONTHS(NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date), NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency) - 2 ) )
                                  WHEN cv_payment_type_year  THEN     -- �N
                                    ( ADD_MONTHS(NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date), ( NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency) - 2 ) * 12 ) )
                                END;
      --������
      ELSE
        -- �ŏI�x����
        ld_last_payment_date := CASE g_cont_hdr_rec.payment_type      -- �p�x
                                  WHEN cv_payment_type_month THEN     -- ��
                                    ( ADD_MONTHS(NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date), NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency) - 2 ) )
                                  WHEN cv_payment_type_year  THEN     -- �N
                                    ( LAST_DAY(ADD_MONTHS(NVL(gd_param_second_payment_date, g_cont_hdr_rec.second_payment_date), ( NVL(gn_param_payment_frequency, g_cont_hdr_rec.payment_frequency) - 2 ) * 12 ) ) )
                                END;
      END IF;
      --
    END IF;
    --
    -- �ŏI�x���������[�X�I��������ŃG���[
    IF ( ld_last_payment_date > NVL(gd_param_lease_end_date, g_cont_hdr_rec.lease_end_date) ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_last_payment_date_err -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --
    -- ���̓p�����[�^�߂�
    gd_param_lease_start_date := lt_param_lease_start_date;
    gd_param_lease_end_date   := lt_param_lease_end_date;
-- Add 2013/02/27 Ver1.2 End
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
  END chk_input_param;
--
  /**********************************************************************************
   * Procedure Name   : upd_comments
   * Description      : �����X�V����(A-3)
   ***********************************************************************************/
  PROCEDURE upd_comments(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_comments'; -- �v���O������
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
    ln_upd_cnt          NUMBER;           -- �X�V����
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- ���[�X�_��w�b�_���b�N�J�[�\��
    CURSOR cont_hdr_lock_cur(
      in_contract_header_id   IN  NUMBER  -- �_�����ID
    )
    IS
      SELECT  'X'
      FROM    xxcff_contract_headers  xch                     -- ���[�X�_��w�b�_
      WHERE   xch.contract_header_id  = in_contract_header_id -- �_�����ID
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
    -- �Ώی����ݒ�
    gn_target_cnt := 1;
--
    -- ============================================
    -- ���[�X�_��w�b�_���b�N
    -- ============================================
    BEGIN
      OPEN  cont_hdr_lock_cur(
        in_contract_header_id => g_cont_hdr_rec.contract_header_id    -- �_�����ID
      );
      CLOSE cont_hdr_lock_cur;
    --
    EXCEPTION
      WHEN data_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_data_lock_err         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_table_name            -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_cont_hdr_tab_nm       -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- ���[�X�_��w�b�_.���� �X�V
    -- ============================================
    BEGIN
      UPDATE  xxcff_contract_headers  -- ���[�X�_��w�b�_
      SET     comments                = gv_param_comments         -- ����
             ,last_updated_by         = cn_last_updated_by        -- �ŏI�X�V��
             ,last_update_date        = cd_last_update_date       -- �ŏI�X�V��
             ,last_update_login       = cn_last_update_login      -- �ŏI�X�V���O�C��
             ,request_id              = cn_request_id             -- �v��ID
             ,program_application_id  = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
             ,program_id              = cn_program_id             -- �R���J�����g�E�v���O����ID
             ,program_update_date     = cd_program_update_date    -- �v���O�����X�V��
      WHERE   contract_header_id      = g_cont_hdr_rec.contract_header_id -- �_�����ID
      ;
      -- ���������ݒ�
      ln_upd_cnt    := SQL%ROWCOUNT;
      gn_normal_cnt := ln_upd_cnt;    -- ���팏��
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_update_err            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_table_name            -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_cont_hdr_tab_nm       -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_info                  -- �g�[�N���R�[�h2
                      ,iv_token_value2  => SQLERRM                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
  END upd_comments;
--
  /**********************************************************************************
   * Procedure Name   : submit_csv_conc
   * Description      : �b�r�u�o�͏���(A-4)
   ***********************************************************************************/
  PROCEDURE submit_csv_conc(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_csv_conc'; -- �v���O������
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
    ln_request_id             NUMBER;          -- �v��ID
    lb_wait_result            BOOLEAN;         -- �R���J�����g�ҋ@����
    lv_phase                  VARCHAR2(50);
    lv_status                 VARCHAR2(50);
    lv_dev_phase              VARCHAR2(50);
    lv_dev_status             VARCHAR2(50);
    lv_message                VARCHAR2(5000);
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
    -- ============================================
    -- �@ ���[�X�_��f�[�^CSV�o�� �N��
    -- ============================================
    ln_request_id := fnd_request.submit_request(
      application  => cv_appl_short_name_xxccp  -- Application
     ,program      => cv_prg_contract_csv       -- Program
     ,description  => NULL                      -- Description
     ,start_time   => NULL                      -- Start_time
     ,sub_request  => FALSE                     -- Sub_request
     ,argument1    => gv_param_contract_number  -- 1. �_��ԍ�
     ,argument2    => gv_param_lease_company    -- 2. ���[�X���
     ,argument3    => NULL                      -- 3. �����R�[�h1
     ,argument4    => NULL                      -- 4. �����R�[�h2
     ,argument5    => NULL                      -- 5. �����R�[�h3
     ,argument6    => NULL                      -- 6. �����R�[�h4
     ,argument7    => NULL                      -- 7. �����R�[�h5
     ,argument8    => NULL                      -- 8. �����R�[�h6
     ,argument9    => NULL                      -- 9. �����R�[�h7
     ,argument10   => NULL                      -- 10.�����R�[�h8
     ,argument11   => NULL                      -- 11.�����R�[�h9
     ,argument12   => NULL                      -- 12.�����R�[�h10
    );
--
    -- �N�����s
    IF (ln_request_id = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_conc_submit_err     -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_syori               -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_val_prg_contract_csv    -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
--
    --�R���J�����g�̏I���ҋ@
    lb_wait_result := fnd_concurrent.wait_for_request(
      request_id   => ln_request_id   -- Request_id
     ,interval     => gn_interval     -- Interval
     ,max_wait     => gn_max_wait     -- Max_wait
     ,phase        => lv_phase        -- Phase
     ,status       => lv_status       -- Status
     ,dev_phase    => lv_dev_phase    -- Dev_phase
     ,dev_status   => lv_dev_status   -- Dev_status
     ,message      => lv_message      -- Message
    );
--
    -- �R���J�����g�ҋ@���s
    IF (lb_wait_result = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_conc_wait_err       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_request_id          -- �g�[�N���R�[�h1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �R���J�����g�ُ�I��
    IF (lv_dev_status = cv_conc_dev_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_conc_proc_err       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_request_id          -- �g�[�N���R�[�h1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �A ���[�X�����f�[�^CSV�o�� �N��
    -- ============================================
    ln_request_id := fnd_request.submit_request(
      application  => cv_appl_short_name_xxccp  -- Application
     ,program      => cv_prg_object_csv         -- Program
     ,description  => NULL                      -- Description
     ,start_time   => NULL                      -- Start_time
     ,sub_request  => FALSE                     -- Sub_request
     ,argument1    => gv_param_contract_number  -- 1. �_��ԍ�
     ,argument2    => gv_param_lease_company    -- 2. ���[�X���
     ,argument3    => NULL                      -- 3. �����R�[�h1
     ,argument4    => NULL                      -- 4. �����R�[�h2
     ,argument5    => NULL                      -- 5. �����R�[�h3
     ,argument6    => NULL                      -- 6. �����R�[�h4
     ,argument7    => NULL                      -- 7. �����R�[�h5
     ,argument8    => NULL                      -- 8. �����R�[�h6
     ,argument9    => NULL                      -- 9. �����R�[�h7
     ,argument10   => NULL                      -- 10.�����R�[�h8
     ,argument11   => NULL                      -- 11.�����R�[�h9
     ,argument12   => NULL                      -- 12.�����R�[�h10
    );
--
    -- �N�����s
    IF (ln_request_id = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_conc_submit_err     -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_syori               -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_val_prg_object_csv      -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
--
    --�R���J�����g�̏I���ҋ@
    lb_wait_result := fnd_concurrent.wait_for_request(
      request_id   => ln_request_id   -- Request_id
     ,interval     => gn_interval     -- Interval
     ,max_wait     => gn_max_wait     -- Max_wait
     ,phase        => lv_phase        -- Phase
     ,status       => lv_status       -- Status
     ,dev_phase    => lv_dev_phase    -- Dev_phase
     ,dev_status   => lv_dev_status   -- Dev_status
     ,message      => lv_message      -- Message
    );
--
    -- �R���J�����g�ҋ@���s
    IF (lb_wait_result = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_conc_wait_err       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_request_id          -- �g�[�N���R�[�h1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �R���J�����g�ُ�I��
    IF (lv_dev_status = cv_conc_dev_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_conc_proc_err       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_request_id          -- �g�[�N���R�[�h1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �B ���[�X�x���v��f�[�^CSV�o�� �N��
    -- ============================================
    ln_request_id := fnd_request.submit_request(
      application  => cv_appl_short_name_xxccp  -- Application
     ,program      => cv_prg_pay_planning_csv   -- Program
     ,description  => NULL                      -- Description
     ,start_time   => NULL                      -- Start_time
     ,sub_request  => FALSE                     -- Sub_request
     ,argument1    => gv_param_contract_number  -- 1. �_��ԍ�
     ,argument2    => gv_param_lease_company    -- 2. ���[�X���
     ,argument3    => NULL                      -- 3. �����R�[�h1
     ,argument4    => NULL                      -- 4. �����R�[�h2
     ,argument5    => NULL                      -- 5. �����R�[�h3
     ,argument6    => NULL                      -- 6. �����R�[�h4
     ,argument7    => NULL                      -- 7. �����R�[�h5
     ,argument8    => NULL                      -- 8. �����R�[�h6
     ,argument9    => NULL                      -- 9. �����R�[�h7
     ,argument10   => NULL                      -- 10.�����R�[�h8
     ,argument11   => NULL                      -- 11.�����R�[�h9
     ,argument12   => NULL                      -- 12.�����R�[�h10
    );
--
    -- �N�����s
    IF (ln_request_id = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_conc_submit_err       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_syori                 -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_val_prg_pay_planning_csv  -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
--
    --�R���J�����g�̏I���ҋ@
    lb_wait_result := fnd_concurrent.wait_for_request(
      request_id   => ln_request_id   -- Request_id
     ,interval     => gn_interval     -- Interval
     ,max_wait     => gn_max_wait     -- Max_wait
     ,phase        => lv_phase        -- Phase
     ,status       => lv_status       -- Status
     ,dev_phase    => lv_dev_phase    -- Dev_phase
     ,dev_status   => lv_dev_status   -- Dev_status
     ,message      => lv_message      -- Message
    );
--
    -- �R���J�����g�ҋ@���s
    IF (lb_wait_result = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_conc_wait_err       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_request_id          -- �g�[�N���R�[�h1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �R���J�����g�ُ�I��
    IF (lv_dev_status = cv_conc_dev_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_conc_proc_err       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_request_id          -- �g�[�N���R�[�h1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �C ���[�X��v����CSV�o�� �N��
    -- ============================================
    ln_request_id := fnd_request.submit_request(
      application  => cv_appl_short_name_xxccp  -- Application
     ,program      => cv_prg_accounting_csv     -- Program
     ,description  => NULL                      -- Description
     ,start_time   => NULL                      -- Start_time
     ,sub_request  => FALSE                     -- Sub_request
     ,argument1    => gv_param_contract_number  -- 1. �_��ԍ�
     ,argument2    => gv_param_lease_company    -- 2. ���[�X���
     ,argument3    => NULL                      -- 3. �����R�[�h1
     ,argument4    => NULL                      -- 4. �����R�[�h2
     ,argument5    => NULL                      -- 5. �����R�[�h3
     ,argument6    => NULL                      -- 6. �����R�[�h4
     ,argument7    => NULL                      -- 7. �����R�[�h5
     ,argument8    => NULL                      -- 8. �����R�[�h6
     ,argument9    => NULL                      -- 9. �����R�[�h7
     ,argument10   => NULL                      -- 10.�����R�[�h8
     ,argument11   => NULL                      -- 11.�����R�[�h9
     ,argument12   => NULL                      -- 12.�����R�[�h10
    );
--
    -- �N�����s
    IF (ln_request_id = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_conc_submit_err       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_syori                 -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_val_prg_accounting_csv    -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --�R���J�����g�N���̂��߃R�~�b�g
    COMMIT;
--
    --�R���J�����g�̏I���ҋ@
    lb_wait_result := fnd_concurrent.wait_for_request(
      request_id   => ln_request_id   -- Request_id
     ,interval     => gn_interval     -- Interval
     ,max_wait     => gn_max_wait     -- Max_wait
     ,phase        => lv_phase        -- Phase
     ,status       => lv_status       -- Status
     ,dev_phase    => lv_dev_phase    -- Dev_phase
     ,dev_status   => lv_dev_status   -- Dev_status
     ,message      => lv_message      -- Message
    );
--
    -- �R���J�����g�ҋ@���s
    IF (lb_wait_result = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_conc_wait_err       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_request_id          -- �g�[�N���R�[�h1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- �R���J�����g�ُ�I��
    IF (lv_dev_status = cv_conc_dev_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_conc_proc_err       -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_request_id          -- �g�[�N���R�[�h1
                    ,iv_token_value1  => TO_CHAR(ln_request_id)     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
  END submit_csv_conc;
--
  /**********************************************************************************
   * Procedure Name   : ins_bk_table
   * Description      : �f�[�^�o�b�N�A�b�v����(A-5)
   ***********************************************************************************/
  PROCEDURE ins_bk_table(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_bk_table'; -- �v���O������
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
    ln_run_line_num         xxcff_contract_headers_bk.run_line_num%TYPE;  -- �ő���s�}�ԁ{�P
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
    -- ============================================
    -- �@ �u���[�X�_��w�b�_�v�o�b�N�A�b�v����
    -- ============================================
--
    -- ���s��v���ԁC�_�񂲂Ƃ́u�ő���s�}�ԁ{�P�v���擾
    SELECT  NVL(MAX(xchb.run_line_num), 0) + 1  AS  run_line_num          -- ���s�}��
    INTO    ln_run_line_num                                               -- �ő���s�}�ԁ{�P
    FROM    xxcff_contract_headers_bk   xchb                              -- ���[�X�_��w�b�_�a�j
    WHERE   xchb.run_period_name      = gv_period_name                    -- ���s��v����
    AND     xchb.contract_header_id   = g_cont_hdr_rec.contract_header_id -- �_�����ID
    ;
--
    -- ���[�X�_��w�b�_�a�j �o�^����
    BEGIN
      INSERT INTO xxcff_contract_headers_bk   -- ���[�X�_��w�b�_�a�j
      (
        contract_header_id      -- �_�����ID
       ,contract_number         -- �_��ԍ�
       ,lease_class             -- ���[�X���
       ,lease_type              -- ���[�X�敪
       ,lease_company           -- ���[�X���
       ,re_lease_times          -- �ă��[�X��
       ,comments                -- ����
       ,contract_date           -- ���[�X�_���
       ,payment_frequency       -- �x����
       ,payment_type            -- �p�x
       ,payment_years           -- �N��
       ,lease_start_date        -- ���[�X�J�n��
       ,lease_end_date          -- ���[�X�I����
       ,first_payment_date      -- ����x����
       ,second_payment_date     -- 2��ڎx����
       ,third_payment_date      -- 3��ڈȍ~�x����
       ,start_period_name       -- ��p�v��J�n��v����
       ,lease_payment_flag      -- ���[�X�x���v�抮���t���O
       ,tax_code                -- �ŋ��R�[�h
       ,run_period_name         -- ���s��v����
       ,run_line_num            -- ���s�}��
       ,created_by              -- �쐬��
       ,creation_date           -- �쐬��
       ,last_updated_by         -- �ŏI�X�V��
       ,last_update_date        -- �ŏI�X�V��
       ,last_update_login       -- �ŏI�X�V���O�C��
       ,request_id              -- �v��ID
       ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id              -- �R���J�����g�E�v���O����ID
       ,program_update_date     -- �v���O�����X�V��
      )
      SELECT
          xch.contract_header_id        -- �_�����ID
         ,xch.contract_number           -- �_��ԍ�
         ,xch.lease_class               -- ���[�X���
         ,xch.lease_type                -- ���[�X�敪
         ,xch.lease_company             -- ���[�X���
         ,xch.re_lease_times            -- �ă��[�X��
         ,xch.comments                  -- ����
         ,xch.contract_date             -- ���[�X�_���
         ,xch.payment_frequency         -- �x����
         ,xch.payment_type              -- �p�x
         ,xch.payment_years             -- �N��
         ,xch.lease_start_date          -- ���[�X�J�n��
         ,xch.lease_end_date            -- ���[�X�I����
         ,xch.first_payment_date        -- ����x����
         ,xch.second_payment_date       -- 2��ڎx����
         ,xch.third_payment_date        -- 3��ڈȍ~�x����
         ,xch.start_period_name         -- ��p�v��J�n��v����
         ,xch.lease_payment_flag        -- ���[�X�x���v�抮���t���O
         ,xch.tax_code                  -- �ŋ��R�[�h
         ,gv_period_name                -- ���s��v����
         ,ln_run_line_num               -- ���s�}��
         ,xch.created_by                -- �쐬��
         ,xch.creation_date             -- �쐬��
         ,xch.last_updated_by           -- �ŏI�X�V��
         ,xch.last_update_date          -- �ŏI�X�V��
         ,xch.last_update_login         -- �ŏI�X�V���O�C��
         ,xch.request_id                -- �v��ID
         ,xch.program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,xch.program_id                -- �R���J�����g�E�v���O����ID
         ,xch.program_update_date       -- �v���O�����X�V��
      FROM
          xxcff_contract_headers  xch   -- ���[�X�_��w�b�_
      WHERE
          xch.contract_header_id  = g_cont_hdr_rec.contract_header_id   -- �_�����ID
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_insert_err          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_table_name          -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_cont_hdr_bk_tab_nm  -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_info                -- �g�[�N���R�[�h2
                      ,iv_token_value2  => SQLERRM                    -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- �A �u���[�X�_�񖾍ׁv�o�b�N�A�b�v����
    -- ============================================
    BEGIN
      INSERT INTO xxcff_contract_lines_bk -- ���[�X�_�񖾍ׂa�j
      (
        contract_line_id              -- �_�񖾍ד���ID
       ,contract_header_id            -- �_�����ID
       ,contract_line_num             -- �_��}��
       ,contract_status               -- �_��X�e�[�^�X
       ,first_charge                  -- ���񌎊z���[�X��_���[�X��
       ,first_tax_charge              -- �������Ŋz_���[�X��
       ,first_total_charge            -- ����v_���[�X��
       ,second_charge                 -- 2��ڈȍ~���z���[�X��_���[�X��
       ,second_tax_charge             -- 2��ڈȍ~����Ŋz_���[�X��
       ,second_total_charge           -- 2��ڈȍ~�v_���[�X��
       ,first_deduction               -- ���񌎊z���[�X��_�T���z
       ,first_tax_deduction           -- ���񌎊z����Ŋz_�T���z
       ,first_total_deduction         -- ����v_�T���z
       ,second_deduction              -- 2��ڈȍ~���z���[�X��_�T���z
       ,second_tax_deduction          -- 2��ڈȍ~����Ŋz_�T���z
       ,second_total_deduction        -- 2��ڈȍ~�v_�T���z
       ,gross_charge                  -- ���z���[�X��_���[�X��
       ,gross_tax_charge              -- ���z�����_���[�X��
       ,gross_total_charge            -- ���z�v_���[�X��
       ,gross_deduction               -- ���z���[�X��_�T���z
       ,gross_tax_deduction           -- ���z�����_�T���z
       ,gross_total_deduction         -- ���z�v_�T���z
       ,lease_kind                    -- ���[�X���
       ,estimated_cash_price          -- ���ό����w�����z
       ,present_value_discount_rate   -- ���݉��l������
       ,present_value                 -- ���݉��l
       ,life_in_months                -- �@��ϗp�N��
       ,original_cost                 -- �擾���z
       ,calc_interested_rate          -- �v�Z���q��
       ,object_header_id              -- ��������ID
       ,asset_category                -- ���Y���
       ,expiration_date               -- ������
       ,cancellation_date             -- ���r����
       ,vd_if_date                    -- ���[�X�_����A�g��
       ,info_sys_if_date              -- ���[�X�Ǘ����A�g��
       ,first_installation_address    -- ����ݒu�ꏊ
       ,first_installation_place      -- ����ݒu��
       ,run_period_name               -- ���s��v����
       ,run_line_num                  -- ���s�}��
       ,created_by                    -- �쐬��
       ,creation_date                 -- �쐬��
       ,last_updated_by               -- �ŏI�X�V��
       ,last_update_date              -- �ŏI�X�V��
       ,last_update_login             -- �ŏI�X�V���O�C��
       ,request_id                    -- �v��ID
       ,program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                    -- �R���J�����g�E�v���O����ID
       ,program_update_date           -- �v���O�����X�V��
      )
      SELECT
          xcl.contract_line_id              -- �_�񖾍ד���ID
         ,xcl.contract_header_id            -- �_�����ID
         ,xcl.contract_line_num             -- �_��}��
         ,xcl.contract_status               -- �_��X�e�[�^�X
         ,xcl.first_charge                  -- ���񌎊z���[�X��_���[�X��
         ,xcl.first_tax_charge              -- �������Ŋz_���[�X��
         ,xcl.first_total_charge            -- ����v_���[�X��
         ,xcl.second_charge                 -- 2��ڈȍ~���z���[�X��_���[�X��
         ,xcl.second_tax_charge             -- 2��ڈȍ~����Ŋz_���[�X��
         ,xcl.second_total_charge           -- 2��ڈȍ~�v_���[�X��
         ,xcl.first_deduction               -- ���񌎊z���[�X��_�T���z
         ,xcl.first_tax_deduction           -- ���񌎊z����Ŋz_�T���z
         ,xcl.first_total_deduction         -- ����v_�T���z
         ,xcl.second_deduction              -- 2��ڈȍ~���z���[�X��_�T���z
         ,xcl.second_tax_deduction          -- 2��ڈȍ~����Ŋz_�T���z
         ,xcl.second_total_deduction        -- 2��ڈȍ~�v_�T���z
         ,xcl.gross_charge                  -- ���z���[�X��_���[�X��
         ,xcl.gross_tax_charge              -- ���z�����_���[�X��
         ,xcl.gross_total_charge            -- ���z�v_���[�X��
         ,xcl.gross_deduction               -- ���z���[�X��_�T���z
         ,xcl.gross_tax_deduction           -- ���z�����_�T���z
         ,xcl.gross_total_deduction         -- ���z�v_�T���z
         ,xcl.lease_kind                    -- ���[�X���
         ,xcl.estimated_cash_price          -- ���ό����w�����z
         ,xcl.present_value_discount_rate   -- ���݉��l������
         ,xcl.present_value                 -- ���݉��l
         ,xcl.life_in_months                -- �@��ϗp�N��
         ,xcl.original_cost                 -- �擾���z
         ,xcl.calc_interested_rate          -- �v�Z���q��
         ,xcl.object_header_id              -- ��������ID
         ,xcl.asset_category                -- ���Y���
         ,xcl.expiration_date               -- ������
         ,xcl.cancellation_date             -- ���r����
         ,xcl.vd_if_date                    -- ���[�X�_����A�g��
         ,xcl.info_sys_if_date              -- ���[�X�Ǘ����A�g��
         ,xcl.first_installation_address    -- ����ݒu�ꏊ
         ,xcl.first_installation_place      -- ����ݒu��
         ,gv_period_name                    -- ���s��v����
         ,ln_run_line_num                   -- ���s�}��
         ,xcl.created_by                    -- �쐬��
         ,xcl.creation_date                 -- �쐬��
         ,xcl.last_updated_by               -- �ŏI�X�V��
         ,xcl.last_update_date              -- �ŏI�X�V��
         ,xcl.last_update_login             -- �ŏI�X�V���O�C��
         ,xcl.request_id                    -- �v��ID
         ,xcl.program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,xcl.program_id                    -- �R���J�����g�E�v���O����ID
         ,xcl.program_update_date           -- �v���O�����X�V��
      FROM
          xxcff_contract_lines    xcl       -- ���[�X�_�񖾍�
      WHERE
          xcl.contract_header_id  = g_cont_hdr_rec.contract_header_id   -- �_�����ID
      AND xcl.contract_status     IN  ( cv_contract_status_contract
                                      , cv_contract_status_release )    -- �_��X�e�[�^�X�i�_��, �ă��[�X�j
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_insert_err          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_table_name          -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_cont_line_bk_tab_nm -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_info                -- �g�[�N���R�[�h2
                      ,iv_token_value2  => SQLERRM                    -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- �B �u���[�X�x���v��v�o�b�N�A�b�v����
    -- ============================================
    BEGIN
      INSERT INTO xxcff_pay_planning_bk   -- ���[�X�x���v��a�j
      (
        contract_line_id        -- �_�񖾍ד���ID
       ,payment_frequency       -- �x����
       ,contract_header_id      -- �_�����ID
       ,period_name             -- ��v����
       ,payment_date            -- �x����
       ,lease_charge            -- ���[�X��
       ,lease_tax_charge        -- ���[�X��_�����
       ,lease_deduction         -- ���[�X�T���z
       ,lease_tax_deduction     -- ���[�X�T���z_�����
       ,op_charge               -- �n�o���[�X��
       ,op_tax_charge           -- �n�o���[�X���z_�����
       ,fin_debt                -- �e�h�m���[�X���z
       ,fin_tax_debt            -- �e�h�m���[�X���z_�����
       ,fin_interest_due        -- �e�h�m���[�X�x������
       ,fin_debt_rem            -- �e�h�m���[�X���c
       ,fin_tax_debt_rem        -- �e�h�m���[�X���c_�����
       ,accounting_if_flag      -- ��v�h�e�t���O
       ,payment_match_flag      -- �ƍ��σt���O
       ,run_period_name         -- ���s��v����
       ,run_line_num            -- ���s�}��
       ,created_by              -- �쐬��
       ,creation_date           -- �쐬��
       ,last_updated_by         -- �ŏI�X�V��
       ,last_update_date        -- �ŏI�X�V��
       ,last_update_login       -- �ŏI�X�V���O�C��
       ,request_id              -- �v��ID
       ,program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id              -- �R���J�����g�E�v���O����ID
       ,program_update_date     -- �v���O�����X�V��
      )
      SELECT
          xpp.contract_line_id        -- �_�񖾍ד���ID
         ,xpp.payment_frequency       -- �x����
         ,xpp.contract_header_id      -- �_�����ID
         ,xpp.period_name             -- ��v����
         ,xpp.payment_date            -- �x����
         ,xpp.lease_charge            -- ���[�X��
         ,xpp.lease_tax_charge        -- ���[�X��_�����
         ,xpp.lease_deduction         -- ���[�X�T���z
         ,xpp.lease_tax_deduction     -- ���[�X�T���z_�����
         ,xpp.op_charge               -- �n�o���[�X��
         ,xpp.op_tax_charge           -- �n�o���[�X���z_�����
         ,xpp.fin_debt                -- �e�h�m���[�X���z
         ,xpp.fin_tax_debt            -- �e�h�m���[�X���z_�����
         ,xpp.fin_interest_due        -- �e�h�m���[�X�x������
         ,xpp.fin_debt_rem            -- �e�h�m���[�X���c
         ,xpp.fin_tax_debt_rem        -- �e�h�m���[�X���c_�����
         ,xpp.accounting_if_flag      -- ��v�h�e�t���O
         ,xpp.payment_match_flag      -- �ƍ��σt���O
         ,gv_period_name              -- ���s��v����
         ,ln_run_line_num             -- ���s�}��
         ,xpp.created_by              -- �쐬��
         ,xpp.creation_date           -- �쐬��
         ,xpp.last_updated_by         -- �ŏI�X�V��
         ,xpp.last_update_date        -- �ŏI�X�V��
         ,xpp.last_update_login       -- �ŏI�X�V���O�C��
         ,xpp.request_id              -- �v��ID
         ,xpp.program_application_id  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,xpp.program_id              -- �R���J�����g�E�v���O����ID
         ,xpp.program_update_date     -- �v���O�����X�V��
      FROM
          xxcff_pay_planning    xpp   -- ���[�X�x���v��
      WHERE
          EXISTS
            (  SELECT  'X'
               FROM    xxcff_contract_lines    xcl   -- ���[�X�_�񖾍�
               WHERE   xcl.contract_line_id    = xpp.contract_line_id               -- �_�񖾍ד���ID
               AND     xcl.contract_header_id  = g_cont_hdr_rec.contract_header_id  -- �_�����ID
               AND     xcl.contract_status     IN  ( cv_contract_status_contract
                                                   , cv_contract_status_release )   -- �_��X�e�[�^�X�i�_��, �ă��[�X�j
            )
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_insert_err          -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_table_name          -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_pay_plan_bk_tab_nm -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_info                -- �g�[�N���R�[�h2
                      ,iv_token_value2  => SQLERRM                    -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
  END ins_bk_table;
--
  /**********************************************************************************
   * Procedure Name   : upd_contract_headers
   * Description      : ���[�X�_��w�b�_�X�V����(A-6)
   ***********************************************************************************/
  PROCEDURE upd_contract_headers(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_contract_headers'; -- �v���O������
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
    ld_lease_start_date       xxcff_contract_headers.lease_start_date%TYPE;   -- ���[�X�J�n��
    ln_payment_frequency      xxcff_contract_headers.payment_frequency%TYPE;  -- �x����
    ld_lease_end_date         xxcff_contract_headers.lease_end_date%TYPE;     -- ���[�X�I����
    --
    ln_payment_years          xxcff_contract_headers.payment_years%TYPE;      -- �N��
--
    -- *** ���[�J���E�J�[�\�� ***
    -- ���[�X�_��w�b�_���b�N�J�[�\��
    CURSOR cont_hdr_lock_cur(
      in_contract_header_id   IN  NUMBER  -- �_�����ID
    )
    IS
      SELECT  'X'
      FROM    xxcff_contract_headers  xch                     -- ���[�X�_��w�b�_
      WHERE   xch.contract_header_id  = in_contract_header_id -- �_�����ID
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
    -- ============================================
    -- �X�V�l��ϐ��Ɋi�[
    -- �i���[�X�J�n���A�x���񐔁A���[�X�I�����j
    -- ============================================
--
    -- ���̓p�����[�^�u���[�X�J�n���v��NULL�̏ꍇ
    IF (gd_param_lease_start_date IS NOT NULL) THEN
--
      -- ���̓p�����[�^�u�x���񐔁v��NULL�̏ꍇ
      IF (gn_param_payment_frequency IS NOT NULL) THEN
--
        -- ���[�X�J�n��
        ld_lease_start_date  := gd_param_lease_start_date;
        -- �x����
        ln_payment_frequency := gn_param_payment_frequency;
        -- ���[�X�I����
        ld_lease_end_date    := CASE g_cont_hdr_rec.payment_type      -- �p�x
                                  WHEN cv_payment_type_month THEN     -- ��
                                    ( ADD_MONTHS(ld_lease_start_date, ln_payment_frequency) - 1 )
                                  WHEN cv_payment_type_year  THEN     -- �N
                                    ( ADD_MONTHS(ld_lease_start_date, 12 * ln_payment_frequency) - 1 )
                                END;
--
      -- ���̓p�����[�^�u�x���񐔁v��NULL�̏ꍇ
      ELSE
--
        -- ���[�X�J�n��
        ld_lease_start_date  := gd_param_lease_start_date;
        -- �x����
        ln_payment_frequency := g_cont_hdr_rec.payment_frequency;
        -- ���[�X�I����
        ld_lease_end_date    := CASE g_cont_hdr_rec.payment_type      -- �p�x
                                  WHEN cv_payment_type_month THEN     -- ��
                                    ( ADD_MONTHS(ld_lease_start_date, ln_payment_frequency) - 1 )
                                  WHEN cv_payment_type_year  THEN     -- �N
                                    ( ADD_MONTHS(ld_lease_start_date, 12 * ln_payment_frequency) - 1 )
                                END;
      END IF;
--
    -- ���̓p�����[�^�u���[�X�J�n���v��NULL�̏ꍇ
    ELSE
--
      -- ���̓p�����[�^�u�x���񐔁v��NULL�̏ꍇ
      IF (gn_param_payment_frequency IS NOT NULL) THEN
--
        -- ���̓p�����[�^�u���[�X�I�����v��NULL�̏ꍇ
        IF (gd_param_lease_end_date IS NOT NULL) THEN
--
          -- ���[�X�J�n��
          ld_lease_start_date  := CASE g_cont_hdr_rec.payment_type      -- �p�x
                                    WHEN cv_payment_type_month THEN     -- ��
                                      ( ADD_MONTHS(gd_param_lease_end_date, -1  * gn_param_payment_frequency) + 1 )
                                    WHEN cv_payment_type_year  THEN     -- �N
                                      ( ADD_MONTHS(gd_param_lease_end_date, -12 * gn_param_payment_frequency) + 1 )
                                  END;
          -- �x����
          ln_payment_frequency := gn_param_payment_frequency;
          -- ���[�X�I����
          ld_lease_end_date    := gd_param_lease_end_date;
--
        -- ���̓p�����[�^�u���[�X�I�����v��NULL�̏ꍇ
        ELSE
--
          -- ���[�X�J�n��
          ld_lease_start_date  := g_cont_hdr_rec.lease_start_date;
          -- �x����
          ln_payment_frequency := gn_param_payment_frequency;
          -- ���[�X�I����
          ld_lease_end_date    := CASE g_cont_hdr_rec.payment_type      -- �p�x
                                    WHEN cv_payment_type_month THEN     -- ��
                                      ( ADD_MONTHS(ld_lease_start_date, ln_payment_frequency) - 1 )
                                    WHEN cv_payment_type_year  THEN     -- �N
                                      ( ADD_MONTHS(ld_lease_start_date, 12 * ln_payment_frequency) - 1 )
                                  END;
        END IF;
--
      -- ���̓p�����[�^�u�x���񐔁v��NULL�̏ꍇ
      ELSE
--
        -- ���̓p�����[�^�u���[�X�I�����v��NULL�̏ꍇ
        IF (gd_param_lease_end_date IS NOT NULL) THEN
--
          -- ���[�X�J�n��
          ld_lease_start_date  := CASE g_cont_hdr_rec.payment_type      -- �p�x
                                    WHEN cv_payment_type_month THEN     -- ��
                                      ( ADD_MONTHS(gd_param_lease_end_date, -1  * g_cont_hdr_rec.payment_frequency) + 1 )
                                    WHEN cv_payment_type_year  THEN     -- �N
                                      ( ADD_MONTHS(gd_param_lease_end_date, -12 * g_cont_hdr_rec.payment_frequency) + 1 )
                                  END;
          -- �x����
          ln_payment_frequency := g_cont_hdr_rec.payment_frequency;
          -- ���[�X�I����
          ld_lease_end_date    := gd_param_lease_end_date;
--
        -- ���̓p�����[�^�u���[�X�I�����v��NULL�̏ꍇ
        ELSE
--
          -- ���[�X�J�n��
          ld_lease_start_date  := g_cont_hdr_rec.lease_start_date;
          -- �x����
          ln_payment_frequency := g_cont_hdr_rec.payment_frequency;
          -- ���[�X�I����
          ld_lease_end_date    := g_cont_hdr_rec.lease_end_date;
--
        END IF;
--
      END IF;
--
    END IF;
--
    -- ============================================
    -- �X�V�l��ϐ��Ɋi�[�i�N���j
    -- ============================================
    -- �N��
    ln_payment_years := CASE g_cont_hdr_rec.payment_type    -- �p�x
                          WHEN cv_payment_type_month THEN   -- ��
                            CEIL(ln_payment_frequency / 12) -- �x���񐔁��P�Q�i�����_�ȉ��؂�グ�j
                          WHEN cv_payment_type_year  THEN   -- �N
                            ln_payment_frequency            -- �x����
                        END;
--
--
    -- ============================================
    -- ���[�X�_��w�b�_���b�N����
    -- ============================================
    BEGIN
      OPEN  cont_hdr_lock_cur(
        in_contract_header_id => g_cont_hdr_rec.contract_header_id    -- �_�����ID
      );
      CLOSE cont_hdr_lock_cur;
    --
    EXCEPTION
      WHEN data_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_data_lock_err         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_table_name            -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_cont_hdr_tab_nm       -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ============================================
    -- ���[�X�_��w�b�_ �X�V����
    -- ============================================
    BEGIN
      UPDATE
          xxcff_contract_headers  -- ���[�X�_��w�b�_
      SET
          comments                = NVL(gv_param_comments, comments)                        -- ����
         ,contract_date           = NVL(gd_param_contract_date, contract_date)              -- ���[�X�_���
         ,payment_frequency       = ln_payment_frequency                                    -- �x����
         ,payment_years           = ln_payment_years                                        -- �N��
         ,lease_start_date        = ld_lease_start_date                                     -- ���[�X�J�n��
         ,lease_end_date          = ld_lease_end_date                                       -- ���[�X�I����
         ,first_payment_date      = NVL(gd_param_first_payment_date,  first_payment_date)   -- ����x����
         ,second_payment_date     = NVL(gd_param_second_payment_date, second_payment_date)  -- 2��ڎx����
         ,third_payment_date      = NVL(gn_param_third_payment_date,  third_payment_date)   -- 3��ڈȍ~�x����
         ,last_updated_by         = cn_last_updated_by                                      -- �ŏI�X�V��
         ,last_update_date        = cd_last_update_date                                     -- �ŏI�X�V��
         ,last_update_login       = cn_last_update_login                                    -- �ŏI�X�V���O�C��
         ,request_id              = cn_request_id                                           -- �v��ID
         ,program_application_id  = cn_program_application_id                               -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id              = cn_program_id                                           -- �R���J�����g�E�v���O����ID
         ,program_update_date     = cd_program_update_date                                  -- �v���O�����X�V��
      WHERE
          contract_header_id      = g_cont_hdr_rec.contract_header_id -- �_�����ID
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_update_err            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_table_name            -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_cont_hdr_tab_nm       -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_info                  -- �g�[�N���R�[�h2
                      ,iv_token_value2  => SQLERRM                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
  END upd_contract_headers;
--
  /**********************************************************************************
   * Procedure Name   : get_contract_data
   * Description      : ���[�X�_�񖾍׃f�[�^�擾����(A-7)
   ***********************************************************************************/
  PROCEDURE get_contract_data(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_contract_data'; -- �v���O������
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
    -- ============================================
    -- ���[�X�_�񖾍׏��擾
    -- �i���[�X�_�񖾍׃��b�N���s�Ȃ��j
    -- ============================================
    BEGIN
      OPEN  g_cont_line_cur(
        in_contract_header_id => g_cont_hdr_rec.contract_header_id  -- �_�����ID
      );
      FETCH g_cont_line_cur BULK COLLECT INTO g_cont_line_tab;
      CLOSE g_cont_line_cur;
    --
    EXCEPTION
      -- ���[�X�_�񖾍׃��b�N�G���[
      WHEN data_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_data_lock_err         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_table_name            -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_cont_line_tab_nm      -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- �Ώۃf�[�^�Ȃ�
    IF (g_cont_line_tab.COUNT = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff       -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_data_notfound_err       -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
  END get_contract_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_contract_lines
   * Description      : ���[�X��ޔ���^���[�X�_�񖾍׍X�V����(A-8)
   ***********************************************************************************/
  PROCEDURE upd_contract_lines(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_contract_lines'; -- �v���O������
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
    ln_first_charge                 xxcff_contract_lines.first_charge%TYPE;   -- ���񌎊z���[�X���i�T����j
    ln_second_charge                xxcff_contract_lines.second_charge%TYPE;  -- �Q��ڈȍ~���z���[�X���i�T����j
    ld_contract_ym                  DATE;                                     -- �_��N��
    --
    lv_lease_kind                   VARCHAR2(1000);    -- 8.���[�X���
    ln_present_value_discount_rate  NUMBER;            -- 9.���݉��l������
    ln_present_value                NUMBER;            -- 10.���݉��l
    ln_original_cost                NUMBER;            -- 11.�擾���z
    ln_calc_interested_rate         NUMBER;            -- 12.�v�Z���q��
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
    -- ============================================
    -- �T���ナ�[�X���Z�o
    -- ============================================
    -- ���񌎊z���[�X���i�T����j
    ln_first_charge  := g_cont_line_tab(gn_rec_no).first_charge  - NVL(g_cont_line_tab(gn_rec_no).first_deduction, 0);
    -- �Q��ڈȍ~���z���[�X���i�T����j
    ln_second_charge := g_cont_line_tab(gn_rec_no).second_charge - NVL(g_cont_line_tab(gn_rec_no).second_deduction, 0);
--
    -- ============================================
    -- �_��N���Z�o
    -- ============================================
    -- �_��N�� �� ���[�X�_����̌���
    ld_contract_ym := TRUNC(g_cont_line_tab(gn_rec_no).contract_date, cv_trunc_format_month);
--
--
    -- ============================================
    -- ���[�X��ޔ��菈��
    -- ============================================
    XXCFF003A03C.main(
      iv_lease_type                  => g_cont_line_tab(gn_rec_no).lease_type           -- 1. ���[�X�敪�i���_��C�ă��[�X�_��j
     ,in_payment_frequency           => g_cont_line_tab(gn_rec_no).payment_frequency    -- 2. �x����
     ,in_first_charge                => ln_first_charge                                 -- 3. ���񌎊z���[�X��
     ,in_second_charge               => ln_second_charge                                -- 4. 2��ڈȍ~���z���[�X��
     ,in_estimated_cash_price        => g_cont_line_tab(gn_rec_no).estimated_cash_price -- 5. ���ό����w�����z
     ,in_life_in_months              => g_cont_line_tab(gn_rec_no).life_in_months       -- 6. �@��ϗp�N��
     ,id_contract_ym                 => ld_contract_ym                                  -- 7. �_��N��
     --
     ,ov_lease_kind                  => lv_lease_kind                                   -- 8. ���[�X��ށiFin���[�X�COp���[�X�C��Fin���[�X�j
     ,on_present_value_discount_rate => ln_present_value_discount_rate                  -- 9. ���݉��l������
     ,on_present_value               => ln_present_value                                -- 10.���݉��l
     ,on_original_cost               => ln_original_cost                                -- 11.�擾���z
     ,on_calc_interested_rate        => ln_calc_interested_rate                         -- 12.�v�Z���q��
     ,ov_errbuf                      => lv_errbuf                                       -- �G���[�E���b�Z�[�W
     ,ov_retcode                     => lv_retcode                                      -- ���^�[���E�R�[�h
     ,ov_errmsg                      => lv_errmsg                                       -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_common_err          -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_func_name           -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_val_api_nm_lease_kind   -- �g�[�N���l1
                   )
                || xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff   -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg                     -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_err_msg             -- �g�[�N���R�[�h1
                    ,iv_token_value1  => lv_errbuf                  -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- ���[�X�_�񖾍׍X�V
    -- �i���[�X��ޔ��茋�ʂ̔��f�Ƌ��z���̍X�V�j
    -- ============================================
    BEGIN
      UPDATE
          xxcff_contract_lines        -- ���[�X�_�񖾍�
      SET
          -- ���z���[�X��_���[�X��
          gross_charge                = first_charge + second_charge * ( g_cont_line_tab(gn_rec_no).payment_frequency - 1 )
          -- ���z�����_���[�X��
         ,gross_tax_charge            = first_tax_charge + second_tax_charge * ( g_cont_line_tab(gn_rec_no).payment_frequency - 1 )
          -- ���z�v_���[�X��
         ,gross_total_charge          = first_total_charge + second_total_charge * ( g_cont_line_tab(gn_rec_no).payment_frequency - 1 )
          --
         ,present_value               = ln_present_value                -- ���݉��l
         ,original_cost               = ln_original_cost                -- �擾���z
         ,calc_interested_rate        = ln_calc_interested_rate         -- �v�Z���q��
         ,present_value_discount_rate = ln_present_value_discount_rate  -- ���݉��l������
          --
         ,last_updated_by             = cn_last_updated_by              -- �ŏI�X�V��
         ,last_update_date            = cd_last_update_date             -- �ŏI�X�V��
         ,last_update_login           = cn_last_update_login            -- �ŏI�X�V���O�C��
         ,request_id                  = cn_request_id                   -- �v��ID
         ,program_application_id      = cn_program_application_id       -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id                  = cn_program_id                   -- �R���J�����g�E�v���O����ID
         ,program_update_date         = cd_program_update_date          -- �v���O�����X�V��
      WHERE
          contract_header_id          = g_cont_line_tab(gn_rec_no).contract_header_id   -- �_�����ID
      AND contract_line_id            = g_cont_line_tab(gn_rec_no).contract_line_id     -- �_�񖾍ד���ID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_update_err            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_table_name            -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_cont_line_tab_nm      -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_info                  -- �g�[�N���R�[�h2
                      ,iv_token_value2  => SQLERRM                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
  END upd_contract_lines;
--
  /**********************************************************************************
   * Procedure Name   : ins_contract_histories
   * Description      : ���[�X�_�񖾍ח���o�^����(A-9)
   ***********************************************************************************/
  PROCEDURE ins_contract_histories(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_contract_histories'; -- �v���O������
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
    -- ============================================
    -- ���[�X�_�񖾍ח���o�^
    -- ============================================
    BEGIN
      INSERT INTO xxcff_contract_histories  -- ���[�X�_�񖾍ח���
      (
        contract_header_id            -- �_�����ID
       ,contract_line_id              -- �_�񖾍ד���ID
       ,history_num                   -- �ύX����NO
       ,contract_status               -- �_��X�e�[�^�X
       ,first_charge                  -- ���񌎊z���[�X��_���[�X��
       ,first_tax_charge              -- �������Ŋz_���[�X��
       ,first_total_charge            -- ����v_���[�X��
       ,second_charge                 -- 2��ڈȍ~���z���[�X��_���[�X��
       ,second_tax_charge             -- 2��ڈȍ~����Ŋz_���[�X��
       ,second_total_charge           -- 2��ڈȍ~�v_���[�X��
       ,first_deduction               -- ���񌎊z���[�X��_�T���z
       ,first_tax_deduction           -- ���񌎊z����Ŋz_�T���z
       ,first_total_deduction         -- ����v_�T���z
       ,second_deduction              -- 2��ڈȍ~���z���[�X��_�T���z
       ,second_tax_deduction          -- 2��ڈȍ~����Ŋz_�T���z
       ,second_total_deduction        -- 2��ڈȍ~�v_�T���z
       ,gross_charge                  -- ���z���[�X��_���[�X��
       ,gross_tax_charge              -- ���z�����_���[�X��
       ,gross_total_charge            -- ���z�v_���[�X��
       ,gross_deduction               -- ���z���[�X��_�T���z
       ,gross_tax_deduction           -- ���z�����_�T���z
       ,gross_total_deduction         -- ���z�v_�T���z
       ,lease_kind                    -- ���[�X���
       ,estimated_cash_price          -- ���ό����w�����z
       ,present_value_discount_rate   -- ���݉��l������
       ,present_value                 -- ���݉��l
       ,life_in_months                -- �@��ϗp�N��
       ,original_cost                 -- �擾���z
       ,calc_interested_rate          -- �v�Z���q��
       ,object_header_id              -- ��������ID
       ,asset_category                -- ���Y���
       ,expiration_date               -- ������
       ,cancellation_date             -- ���r����
       ,vd_if_date                    -- ���[�X�_����A�g��
       ,info_sys_if_date              -- ���[�X�Ǘ����A�g��
       ,first_installation_address    -- ����ݒu�ꏊ
       ,first_installation_place      -- ����ݒu��
       ,accounting_date               -- �v���
       ,accounting_if_flag            -- ��v�h�e�t���O
       ,description                   -- �E�v
       ,update_reason                 -- �X�V���R
       ,period_name                   -- ��v����
       ,created_by                    -- �쐬��
       ,creation_date                 -- �쐬��
       ,last_updated_by               -- �ŏI�X�V��
       ,last_update_date              -- �ŏI�X�V��
       ,last_update_login             -- �ŏI�X�V���O�C��
       ,request_id                    -- �v��ID
       ,program_application_id        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,program_id                    -- �R���J�����g�E�v���O����ID
       ,program_update_date           -- �v���O�����X�V��
      )
      SELECT
          xcl.contract_header_id                -- �_�����ID
         ,xcl.contract_line_id                  -- �_�񖾍ד���ID
         ,xxcff_contract_histories_s1.NEXTVAL   -- �ύX����NO
         ,cv_contract_status_maintenance        -- �_��X�e�[�^�X�i210�F�f�[�^�����e�i���X�j
         ,xcl.first_charge                      -- ���񌎊z���[�X��_���[�X��
         ,xcl.first_tax_charge                  -- �������Ŋz_���[�X��
         ,xcl.first_total_charge                -- ����v_���[�X��
         ,xcl.second_charge                     -- 2��ڈȍ~���z���[�X��_���[�X��
         ,xcl.second_tax_charge                 -- 2��ڈȍ~����Ŋz_���[�X��
         ,xcl.second_total_charge               -- 2��ڈȍ~�v_���[�X��
         ,xcl.first_deduction                   -- ���񌎊z���[�X��_�T���z
         ,xcl.first_tax_deduction               -- ���񌎊z����Ŋz_�T���z
         ,xcl.first_total_deduction             -- ����v_�T���z
         ,xcl.second_deduction                  -- 2��ڈȍ~���z���[�X��_�T���z
         ,xcl.second_tax_deduction              -- 2��ڈȍ~����Ŋz_�T���z
         ,xcl.second_total_deduction            -- 2��ڈȍ~�v_�T���z
         ,xcl.gross_charge                      -- ���z���[�X��_���[�X��
         ,xcl.gross_tax_charge                  -- ���z�����_���[�X��
         ,xcl.gross_total_charge                -- ���z�v_���[�X��
         ,xcl.gross_deduction                   -- ���z���[�X��_�T���z
         ,xcl.gross_tax_deduction               -- ���z�����_�T���z
         ,xcl.gross_total_deduction             -- ���z�v_�T���z
         ,xcl.lease_kind                        -- ���[�X���
         ,xcl.estimated_cash_price              -- ���ό����w�����z
         ,xcl.present_value_discount_rate       -- ���݉��l������
         ,xcl.present_value                     -- ���݉��l
         ,xcl.life_in_months                    -- �@��ϗp�N��
         ,xcl.original_cost                     -- �擾���z
         ,xcl.calc_interested_rate              -- �v�Z���q��
         ,xcl.object_header_id                  -- ��������ID
         ,xcl.asset_category                    -- ���Y���
         ,xcl.expiration_date                   -- ������
         ,xcl.cancellation_date                 -- ���r����
         ,xcl.vd_if_date                        -- ���[�X�_����A�g��
         ,xcl.info_sys_if_date                  -- ���[�X�Ǘ����A�g��
         ,xcl.first_installation_address        -- ����ݒu�ꏊ
         ,xcl.first_installation_place          -- ����ݒu��
         ,gd_calendar_period_close_date         -- �v����i���[�X�䒠�I�[�v�����Ԃ̃J�����_�I�����j
         ,cv_acct_if_flag_sent                  -- ��v�h�e�t���O�i2�F���M�ρj
         ,NULL                                  -- �E�v
         ,gv_param_update_reason                -- �X�V���R�i�p�����[�^�u�X�V���R�v�j
         ,gv_period_name                        -- ��v���ԁi���[�X�䒠�I�[�v�����ԁj
         ,xcl.created_by                        -- �쐬��
         ,xcl.creation_date                     -- �쐬��
         ,xcl.last_updated_by                   -- �ŏI�X�V��
         ,xcl.last_update_date                  -- �ŏI�X�V��
         ,xcl.last_update_login                 -- �ŏI�X�V���O�C��
         ,xcl.request_id                        -- �v��ID
         ,xcl.program_application_id            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,xcl.program_id                        -- �R���J�����g�E�v���O����ID
         ,xcl.program_update_date               -- �v���O�����X�V��
      FROM
          xxcff_contract_lines    xcl           -- ���[�X�_�񖾍�
      WHERE
          xcl.contract_header_id  = g_cont_line_tab(gn_rec_no).contract_header_id   -- �_�����ID
      AND xcl.contract_line_id    = g_cont_line_tab(gn_rec_no).contract_line_id     -- �_�񖾍ד���ID
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff       -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_insert_err              -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_table_name              -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_cont_line_hist_tab_nm   -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_info                    -- �g�[�N���R�[�h2
                      ,iv_token_value2  => SQLERRM                        -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
  END ins_contract_histories;
--
  /**********************************************************************************
   * Procedure Name   : create_pay_planning
   * Description      : �x���v��č쐬�^�t���O�X�V����(A-10)
   ***********************************************************************************/
  PROCEDURE create_pay_planning(
    ov_errbuf     OUT VARCHAR2      --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2      --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_pay_planning'; -- �v���O������
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
    lv_payment_match_flag       xxcff_pay_planning.payment_match_flag%TYPE; -- �ƍ��σt���O�i����v���ԁj
    --
    lv_str_contract_line_id     VARCHAR2(100);
    lv_str_period_name          VARCHAR2(100);
    lv_error_key                VARCHAR2(5000);
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
    -- ============================================
    -- �I�[�v�����Ԃ̎x���v��.�ƍ��σt���O��ޔ�
    -- ============================================
    BEGIN
      SELECT  xpp.payment_match_flag  AS  payment_match_flag  -- �ƍ��σt���O
      INTO    lv_payment_match_flag                           -- �ƍ��σt���O�i����v���ԁj
      FROM    xxcff_pay_planning      xpp                     -- ���[�X�x���v��
      WHERE   xpp.contract_line_id    = g_cont_line_tab(gn_rec_no).contract_line_id -- �_�񖾍ד���ID
      AND     xpp.period_name         = gv_period_name                              -- ��v����
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �I�[�v�����Ԃ̎x���v��f�[�^�����݂��Ȃ��ꍇ���������s
        lv_payment_match_flag := NULL;
    END;
--
    -- ============================================
    -- �x���v��쐬����
    -- ============================================
    XXCFF003A05C.main(
      iv_shori_type       => cv_pay_plan_shori_type_create                -- 1.�����敪
     ,in_contract_line_id => g_cont_line_tab(gn_rec_no).contract_line_id  -- 2.�_�񖾍ד���ID
     ,ov_errbuf           => lv_errbuf                                    -- �G���[�E���b�Z�[�W
     ,ov_retcode          => lv_retcode                                   -- ���^�[���E�R�[�h
     ,ov_errmsg           => lv_errmsg                                    -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
--
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff       -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg_common_err              -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_func_name               -- �g�[�N���R�[�h1
                    ,iv_token_value1  => cv_val_api_nm_create_pay_plan  -- �g�[�N���l1
                   )
                || xxccp_common_pkg.get_msg(
                     iv_application   => cv_appl_short_name_xxcff       -- �A�v���P�[�V�����Z�k��
                    ,iv_name          => cv_msg                         -- ���b�Z�[�W�R�[�h
                    ,iv_token_name1   => cv_tkn_err_msg                 -- �g�[�N���R�[�h1
                    ,iv_token_value1  => lv_errbuf                      -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- �x���v��u��v�h�e�t���O�v�u�ƍ��σt���O�v�X�V����
    -- ============================================
--
    -- �I�[�v�����Ԃ̎x���v��f�[�^�����݂���ꍇ
    IF (lv_payment_match_flag IS NOT NULL) THEN
--
      -- �@�I�[�v�����Ԃ̎x���v��X�V
      BEGIN
        UPDATE
            xxcff_pay_planning      -- ���[�X�x���v��
        SET
            accounting_if_flag      = cv_acct_if_flag_not_send  -- ��v�h�e�t���O�i1�F�����M�j
           ,payment_match_flag      = lv_payment_match_flag     -- �ƍ��σt���O�i�X�V�O�̒l�j
           ,last_updated_by         = cn_last_updated_by        -- �ŏI�X�V��
           ,last_update_date        = cd_last_update_date       -- �ŏI�X�V��
           ,last_update_login       = cn_last_update_login      -- �ŏI�X�V���O�C��
           ,request_id              = cn_request_id             -- �v��ID
           ,program_application_id  = cn_program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,program_id              = cn_program_id             -- �R���J�����g�E�v���O����ID
           ,program_update_date     = cd_program_update_date    -- �v���O�����X�V��
        WHERE
            contract_line_id        = g_cont_line_tab(gn_rec_no).contract_line_id -- �_�񖾍ד���ID
        AND period_name             = gv_period_name                              -- ��v���ԁi�I�[�v�����ԁj
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                        ,iv_name          => cv_msg_update_err            -- ���b�Z�[�W�R�[�h
                        ,iv_token_name1   => cv_tkn_table_name            -- �g�[�N���R�[�h1
                        ,iv_token_value1  => cv_val_pay_plan_tab_nm       -- �g�[�N���l1
                        ,iv_token_name2   => cv_tkn_info                  -- �g�[�N���R�[�h2
                        ,iv_token_value2  => SQLERRM                      -- �g�[�N���l2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
    END IF;
--
    -- �A�I�[�v�����Ԃ��O�̎x���v��X�V
    BEGIN
      UPDATE
          xxcff_pay_planning      -- ���[�X�x���v��
      SET
          accounting_if_flag      = cv_acct_if_flag_sent          -- ��v�h�e�t���O�i2�F���M�ρj
         ,payment_match_flag      = cv_payment_match_flag_matched -- �ƍ��σt���O�i1�F�ƍ��ρj
         ,last_updated_by         = cn_last_updated_by            -- �ŏI�X�V��
         ,last_update_date        = cd_last_update_date           -- �ŏI�X�V��
         ,last_update_login       = cn_last_update_login          -- �ŏI�X�V���O�C��
         ,request_id              = cn_request_id                 -- �v��ID
         ,program_application_id  = cn_program_application_id     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
         ,program_id              = cn_program_id                 -- �R���J�����g�E�v���O����ID
         ,program_update_date     = cd_program_update_date        -- �v���O�����X�V��
      WHERE
          contract_line_id        = g_cont_line_tab(gn_rec_no).contract_line_id -- �_�񖾍ד���ID
      AND period_name             < gv_period_name                              -- ��v���ԁi�I�[�v�����Ԃ��O�j
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_appl_short_name_xxcff     -- �A�v���P�[�V�����Z�k��
                      ,iv_name          => cv_msg_update_err            -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1   => cv_tkn_table_name            -- �g�[�N���R�[�h1
                      ,iv_token_value1  => cv_val_pay_plan_tab_nm       -- �g�[�N���l1
                      ,iv_token_name2   => cv_tkn_info                  -- �g�[�N���R�[�h2
                      ,iv_token_value2  => SQLERRM                      -- �g�[�N���l2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    -- ���b�Z�[�W�o�͂�����K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg  := lv_errmsg;                                                  --# �C�� #
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
  END create_pay_planning;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_contract_number      IN  VARCHAR2    -- 1. �_��ԍ�  �i�K�{�j
   ,iv_lease_company        IN  VARCHAR2    -- 2. ���[�X��Ёi�K�{�j
   ,iv_update_reason        IN  VARCHAR2    -- 3. �X�V���R  �i�K�{�j
   ,iv_lease_start_date     IN  VARCHAR2    -- 4. ���[�X�J�n��
   ,iv_lease_end_date       IN  VARCHAR2    -- 5. ���[�X�I����
   ,iv_payment_frequency    IN  VARCHAR2    -- 6. �x����
   ,iv_contract_date        IN  VARCHAR2    -- 7. �_���
   ,iv_first_payment_date   IN  VARCHAR2    -- 8. ����x����
   ,iv_second_payment_date  IN  VARCHAR2    -- 9. �Q��ڎx����
   ,iv_third_payment_date   IN  VARCHAR2    -- 10.�R��ڈȍ~�x����
   ,iv_comments             IN  VARCHAR2    -- 11.����
   ,ov_errbuf               OUT VARCHAR2    --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode              OUT VARCHAR2    --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg               OUT VARCHAR2)   --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;   -- �Ώی���
    gn_normal_cnt := 0;   -- ���팏��
    gn_error_cnt  := 0;   -- �G���[����
    gn_warn_cnt   := 0;   -- �X�L�b�v����
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
       iv_contract_number     =>  iv_contract_number      -- 1. �_��ԍ�
      ,iv_lease_company       =>  iv_lease_company        -- 2. ���[�X���
      ,iv_update_reason       =>  iv_update_reason        -- 3. �X�V���R
      ,iv_lease_start_date    =>  iv_lease_start_date     -- 4. ���[�X�J�n��
      ,iv_lease_end_date      =>  iv_lease_end_date       -- 5. ���[�X�I����
      ,iv_payment_frequency   =>  iv_payment_frequency    -- 6. �x����
      ,iv_contract_date       =>  iv_contract_date        -- 7. �_���
      ,iv_first_payment_date  =>  iv_first_payment_date   -- 8. ����x����
      ,iv_second_payment_date =>  iv_second_payment_date  -- 9. �Q��ڎx����
      ,iv_third_payment_date  =>  iv_third_payment_date   -- 10.�R��ڈȍ~�x����
      ,iv_comments            =>  iv_comments             -- 11.����
      ,ov_errbuf              =>  lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode             =>  lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg              =>  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ���̓p�����[�^�`�F�b�N����(A-2)
    -- ===============================================
    chk_input_param(
       iv_contract_number     =>  iv_contract_number      -- 1. �_��ԍ�
      ,iv_lease_company       =>  iv_lease_company        -- 2. ���[�X���
      ,iv_update_reason       =>  iv_update_reason        -- 3. �X�V���R
      ,iv_lease_start_date    =>  iv_lease_start_date     -- 4. ���[�X�J�n��
      ,iv_lease_end_date      =>  iv_lease_end_date       -- 5. ���[�X�I����
      ,iv_payment_frequency   =>  iv_payment_frequency    -- 6. �x����
      ,iv_contract_date       =>  iv_contract_date        -- 7. �_���
      ,iv_first_payment_date  =>  iv_first_payment_date   -- 8. ����x����
      ,iv_second_payment_date =>  iv_second_payment_date  -- 9. �Q��ڎx����
      ,iv_third_payment_date  =>  iv_third_payment_date   -- 10.�R��ڈȍ~�x����
      ,iv_comments            =>  iv_comments             -- 11.����
      ,ov_errbuf              =>  lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode             =>  lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg              =>  lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- �u�����v�݂̂̃f�[�^�����e�i���X�̏ꍇ
    IF (  gd_param_lease_start_date     IS NULL       -- 4. ���[�X�J�n��
      AND gd_param_lease_end_date       IS NULL       -- 5. ���[�X�I����
      AND gn_param_payment_frequency    IS NULL       -- 6. �x����
      AND gd_param_contract_date        IS NULL       -- 7. �_���
      AND gd_param_first_payment_date   IS NULL       -- 8. ����x����
      AND gd_param_second_payment_date  IS NULL       -- 9. �Q��ڎx����
      AND gn_param_third_payment_date   IS NULL       -- 10.�R��ڈȍ~�x����
      AND gv_param_comments             IS NOT NULL   -- 11.����
    )
    THEN
--
      -- ===============================================
      -- �����X�V����(A-3)
      -- ===============================================
      upd_comments(
        ov_errbuf   => lv_errbuf    --   �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode  => lv_retcode   --   ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg   => lv_errmsg    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSE
        -- �X�V�ɐ��������ꍇ�A�ȍ~�̏����͍s�Ȃ킸�v���O�������I������
        RETURN;
      END IF;
    END IF;
--
--
    -- ===============================================
    -- �b�r�u�o�͏����i�����e�i���X���{�O�j(A-4)
    -- ===============================================
    submit_csv_conc(
      ov_errbuf   => lv_errbuf    --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode  => lv_retcode   --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg   => lv_errmsg    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- �f�[�^�o�b�N�A�b�v����(A-5)
    -- ===============================================
    ins_bk_table(
      ov_errbuf   => lv_errbuf    --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode  => lv_retcode   --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg   => lv_errmsg    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ���[�X�_��w�b�_�X�V����(A-6)
    -- ===============================================
    upd_contract_headers(
      ov_errbuf   => lv_errbuf    --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode  => lv_retcode   --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg   => lv_errmsg    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ���[�X�_�񖾍׃f�[�^�擾����(A-7)
    -- ===============================================
    get_contract_data(
      ov_errbuf   => lv_errbuf    --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode  => lv_retcode   --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg   => lv_errmsg    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- �Ώی����i�[
    gn_target_cnt := g_cont_line_tab.COUNT;
--
--
    -- ���[�X�_�񖾍׃f�[�^���[�v
    <<contract_line_loop>>
    FOR i IN 1..g_cont_line_tab.COUNT LOOP
--
      -- �J�E���^���O���[�o���ϐ��Ɋi�[
      gn_rec_no := i;
--
      -- ===============================================
      -- ���[�X��ޔ���^���[�X�_�񖾍׍X�V����(A-8)
      -- ===============================================
      upd_contract_lines(
        ov_errbuf   => lv_errbuf    --   �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode  => lv_retcode   --   ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg   => lv_errmsg    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- ���[�X�_�񖾍ח���o�^����(A-9)
      -- ===============================================
      ins_contract_histories(
        ov_errbuf   => lv_errbuf    --   �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode  => lv_retcode   --   ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg   => lv_errmsg    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- �x���v��č쐬�^�t���O�X�V����(A-10)
      -- ===============================================
      create_pay_planning(
        ov_errbuf   => lv_errbuf    --   �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode  => lv_retcode   --   ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg   => lv_errmsg    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ���팏���J�E���g
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP contract_line_loop;
--
--
    -- ===============================================
    -- �b�r�u�o�͏����i�����e�i���X���{��j(A-11)
    -- ===============================================
    submit_csv_conc(
      ov_errbuf   => lv_errbuf    --   �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode  => lv_retcode   --   ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg   => lv_errmsg    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
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
    errbuf                  OUT VARCHAR2,   --    �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                 OUT VARCHAR2,   --    ���^�[���E�R�[�h    --# �Œ� #
    iv_contract_number      IN  VARCHAR2,   -- 1. �_��ԍ�  �i�K�{�j
    iv_lease_company        IN  VARCHAR2,   -- 2. ���[�X��Ёi�K�{�j
    iv_update_reason        IN  VARCHAR2,   -- 3. �X�V���R  �i�K�{�j
    iv_lease_start_date     IN  VARCHAR2,   -- 4. ���[�X�J�n��
    iv_lease_end_date       IN  VARCHAR2,   -- 5. ���[�X�I����
    iv_payment_frequency    IN  VARCHAR2,   -- 6. �x����
    iv_contract_date        IN  VARCHAR2,   -- 7. �_���
    iv_first_payment_date   IN  VARCHAR2,   -- 8. ����x����
    iv_second_payment_date  IN  VARCHAR2,   -- 9. �Q��ڎx����
    iv_third_payment_date   IN  VARCHAR2,   -- 10.�R��ڈȍ~�x����
    iv_comments             IN  VARCHAR2    -- 11.����
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
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_which_log
      ,ov_retcode => lv_retcode
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
       iv_contract_number     =>  iv_contract_number      -- 1. �_��ԍ�
      ,iv_lease_company       =>  iv_lease_company        -- 2. ���[�X���
      ,iv_update_reason       =>  iv_update_reason        -- 3. �X�V���R
      ,iv_lease_start_date    =>  iv_lease_start_date     -- 4. ���[�X�J�n��
      ,iv_lease_end_date      =>  iv_lease_end_date       -- 5. ���[�X�I����
      ,iv_payment_frequency   =>  iv_payment_frequency    -- 6. �x����
      ,iv_contract_date       =>  iv_contract_date        -- 7. �_���
      ,iv_first_payment_date  =>  iv_first_payment_date   -- 8. ����x����
      ,iv_second_payment_date =>  iv_second_payment_date  -- 9. �Q��ڎx����
      ,iv_third_payment_date  =>  iv_third_payment_date   -- 10.�R��ڈȍ~�x����
      ,iv_comments            =>  iv_comments             -- 11.����
      ,ov_errbuf              =>  lv_errbuf     -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode             =>  lv_retcode    -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg              =>  lv_errmsg     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    -- ===============================================
    -- �I������(A-12)
    -- ===============================================
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �G���[�����i�Œ�l�F1�j
      gn_error_cnt := 1;
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
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
    --���������o��
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
    --�G���[�����o��
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
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
END XXCFF016A35C;
/
