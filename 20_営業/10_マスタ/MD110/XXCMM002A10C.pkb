CREATE OR REPLACE PACKAGE BODY APPS.XXCMM002A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCMM002A10C (body)
 * Description      : �Ј��f�[�^IF���o_EBS�R���J�����g
 * MD.050           : T_MD050_CMM_002_A10_�Ј��f�[�^IF���o_EBS�R���J�����g
 * Version          : 1.21
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  nvl_for_hdl            HDL�pNVL
 *  init                   ��������(A-1)
 *  output_worker          �]�ƈ����̒��o�E�t�@�C���o�͏���(A-2)
 *  output_user            ���[�U�[���̒��o�E�t�@�C���o�͏���(A-3)
 *  output_worker2         �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�̒��o�E�t�@�C���o�͏���(A-4)
 *  output_emp_bank_acct   �]�ƈ��o��������̒��o�E�t�@�C���o�͏���(A-5)
 *  output_emp_info        �Ј��������̒��o�E�t�@�C���o�͏����iPaaS�����p�j(A-6)
 *  update_mng_tbl         �Ǘ��e�[�u���o�^�E�X�V����(A-7)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2023-01-12    1.0   Y.Ooyama         �V�K�쐬
 *  2023-01-16    1.1   Y.Ooyama         E054
 *  2023-01-23    1.2   Y.Ooyama         E055, E056
 *  2023-01-29    1.3   Y.Ooyama         �O�������e�X�g�s��Ή��iNo.0010�j
 *  2023-01-30    1.4   F.Hasebe         �O�������e�X�g�s��Ή��iNo.0012�j
 *  2023-01-31    1.5   Y.Ooyama         �O�������e�X�g�s��Ή��iNo.0013�j
 *  2023-01-31    1.6   Y.Ooyama         �O�������e�X�g�s��Ή��iNo.0014�j
 *  2023-02-16    1.7   Y.Ooyama         �J���c�ۑ�No.12�i�O�������e�X�g�s�No.0006�j
 *  2023-02-27    1.8   Y.Ooyama         �V�i���I�e�X�g�s�No.0035
 *  2023-03-02    1.9   Y.Ooyama         �V�i���I�e�X�g�s�No.0053
 *  2023-03-03    1.10  Y.Ooyama         �V�i���I�e�X�g�s�No.0057
 *  2023-03-06    1.11  Y.Ooyama         �V�i���I�e�X�g�s�No.0028
 *  2023-03-15    1.12  Y.Ooyama         �V�i���I�e�X�g�s�No.0085
 *  2023-03-22    1.13  Y.Ooyama         �V�i���I�e�X�g�s�No.0093
 *  2023-04-18    1.14  T.Mizutani       PT�e�X�g�s�No.0009
 *  2023-05-22    1.15  F.Hasebe         �V�X�e�������e�X�gNo.5�C���Ή�
 *  2023-06-05    1.16  F.Hasebe         ����ToDoNo.50�C���Ή�
 *  2023-07-11    1.17  F.Hasebe         E_�{�ғ�_19324�Ή�
 *  2023-07-06    1.18  F.Hasebe         E_�{�ғ�_19314�Ή�
 *  2023-09-21    1.19  Y.Koh            E_�{�ғ�_19311�y�}�X�^�zERP��s���� �Ή�
 *  2023-12-22    1.20  K.Sudo           E_�{�ғ�_19379�y�}�X�^�z�V�K�]�ƈ����ʃt���O�̏������Ή�
 *  2024-01-30    1.21  K.Sudo           E_�{�ғ�_19791�y�}�X�^�z�o������R�Â��iERP)
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
  -- ���b�N�G���[��O
  global_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
  -- �t�@�C���o�͎���O
  global_fileout_expt       EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_fileout_expt, -20010);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCMM002A10C'; -- �p�b�P�[�W��
--
  -- �A�v���P�[�V�����Z�k��
  cv_appl_xxcmm             CONSTANT VARCHAR2(5)   := 'XXCMM';              -- �A�h�I���F�}�X�^�E�}�X�^�̈�
  cv_appl_xxccp             CONSTANT VARCHAR2(5)   := 'XXCCP';              -- �A�h�I���F���ʁEIF�̈�
  cv_appl_xxcoi             CONSTANT VARCHAR2(5)   := 'XXCOI';              -- �A�h�I���F�݌ɗ̈�
--
  -- ���t����
  cv_datetime_fmt           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_date_fmt               CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
  -- �Œ蕶��
  cv_slash                  CONSTANT VARCHAR2(1)   := '/';
  cv_comma                  CONSTANT VARCHAR2(1)   := ',';
  cv_pipe                   CONSTANT VARCHAR2(1)   := '|';
  cv_space                  CONSTANT VARCHAR2(1)   := ' ';
  cv_hyphen                 CONSTANT VARCHAR2(1)   := '-';
--
  cv_open_mode_w            CONSTANT VARCHAR2(1)   := 'W';                  -- �������݃��[�h
  cn_max_linesize           CONSTANT BINARY_INTEGER := 32767;               -- �t�@�C���T�C�Y
--
  cv_emp_kbn_internal       CONSTANT VARCHAR2(1)   := '1';                  -- �]�ƈ��敪�F1(����)
  cv_emp_kbn_external       CONSTANT VARCHAR2(1)   := '2';                  -- �]�ƈ��敪�F2(�O��)
  cv_emp_kbn_dummy          CONSTANT VARCHAR2(1)   := '4';                  -- �]�ƈ��敪�F4(�_�~�[)
  cv_vd_type_employee       CONSTANT VARCHAR2(8)   := 'EMPLOYEE';
  cv_wk_terms_suffix        CONSTANT VARCHAR2(2)   := 'WT';
  cv_wt                     CONSTANT VARCHAR2(2)   := 'WT';
  cv_itoen_email_suffix     CONSTANT VARCHAR2(3)   := 'ing';
  cv_itoen_email_domain     CONSTANT VARCHAR2(12)  := '@itoen.co.jp';
  cv_y                      CONSTANT VARCHAR2(1)   := 'Y';
  cv_n                      CONSTANT VARCHAR2(1)   := 'N';
  cv_act_cd_termination     CONSTANT VARCHAR2(11)  := 'TERMINATION';
  cv_act_cd_hire            CONSTANT VARCHAR2(4)   := 'HIRE';
  cv_act_cd_rehire          CONSTANT VARCHAR2(6)   := 'REHIRE';
  cv_act_cd_mng_chg         CONSTANT VARCHAR2(14)  := 'MANAGER_CHANGE';
  cv_meta_merge             CONSTANT VARCHAR2(5)   := 'MERGE';
  cv_meta_delete            CONSTANT VARCHAR2(6)   := 'DELETE';
  cv_ebs                    CONSTANT VARCHAR2(3)   := 'EBS';
  cv_jp                     CONSTANT VARCHAR2(2)   := 'JP';
  cv_global                 CONSTANT VARCHAR2(6)   := 'GLOBAL';
  cv_w1                     CONSTANT VARCHAR2(2)   := 'W1';
  cv_sales_le               CONSTANT VARCHAR2(8)   := 'SALES-LE';
  cv_sales_bu               CONSTANT VARCHAR2(8)   := 'SALES-BU';
  cv_wk_type_e              CONSTANT VARCHAR2(1)   := 'E';
  cv_sys_per_type_emp       CONSTANT VARCHAR2(3)   := 'EMP';
  cv_ass_type_et            CONSTANT VARCHAR2(2)   := 'ET';
  cv_per_type_employee      CONSTANT VARCHAR2(8)   := 'Employee';
  cv_seq_1                  CONSTANT VARCHAR2(1)   := '1';
  cv_ass_status_act         CONSTANT VARCHAR2(14)  := 'ACTIVE_PROCESS';
  cv_sup_type_line_manager  CONSTANT VARCHAR2(12)  := 'LINE_MANAGER';
  cv_proc_type_dept         CONSTANT VARCHAR2(1)   := '2';                  -- �����敪�F2(����)
  cv_acct_type_sup          CONSTANT VARCHAR2(8)   := 'SUPPLIER';
-- Ver1.1 Add Start
  cv_yen                    CONSTANT VARCHAR2(3)  := 'JPY';
-- Ver1.1 Add End
--
  cv_cls_worker             CONSTANT VARCHAR2(6)   := 'Worker';
  cv_cls_per_name           CONSTANT VARCHAR2(10)  := 'PersonName';
  cv_cls_per_legi           CONSTANT VARCHAR2(21)  := 'PersonLegislativeData';
  cv_cls_per_email          CONSTANT VARCHAR2(11)  := 'PersonEmail';
  cv_cls_wk_rel             CONSTANT VARCHAR2(16)  := 'WorkRelationship';
  cv_cls_per_user           CONSTANT VARCHAR2(21)  := 'PersonUserInformation';
  cv_cls_wk_terms           CONSTANT VARCHAR2(9)   := 'WorkTerms';
  cv_cls_user               CONSTANT VARCHAR2(4)   := 'User';
  cv_cls_assignment         CONSTANT VARCHAR2(10)  := 'Assignment';
  cv_cls_ass_super          CONSTANT VARCHAR2(20)  := 'AssignmentSupervisor';
  cv_per_persons_dff        CONSTANT VARCHAR2(20)  := 'ITO_SALES_USE_ITEM';
  cv_per_asg_df             CONSTANT VARCHAR2(20)  := 'ITO_SALES_USE_ITEM';
--
  -- ���o�ΏۊO�]�ƈ��ԍ�
  cv_not_get_emp1           CONSTANT VARCHAR2(10)  := '99983';
  cv_not_get_emp2           CONSTANT VARCHAR2(10)  := '99984';
  cv_not_get_emp3           CONSTANT VARCHAR2(10)  := '99985';
  cv_not_get_emp4           CONSTANT VARCHAR2(10)  := '99989';
  cv_not_get_emp5           CONSTANT VARCHAR2(10)  := '99997';
  cv_not_get_emp6           CONSTANT VARCHAR2(10)  := '99998';
  cv_not_get_emp7           CONSTANT VARCHAR2(10)  := '99999';
  cv_not_get_emp8           CONSTANT VARCHAR2(10)  := 'XXSCV_2';
--
  -- �f�[�^�^�C�v��NVL�ϊ��l
  cv_nvl_v                  CONSTANT VARCHAR2(5)   := '#NULL';
  cv_nvl_d                  CONSTANT VARCHAR2(10)  := '4712/01/01';
  cv_nvl_n                  CONSTANT VARCHAR2(10)  := '-999999991';
--
  -- �v���t�@�C��
  -- XXCMM:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
  cv_prf_out_file_dir       CONSTANT VARCHAR2(30)  := 'XXCMM1_OIC_OUT_FILE_DIR';
  -- XXCMM:�]�ƈ����A�g�f�[�^�t�@�C�����iOIC�A�g�j
  cv_prf_wrk_out_file       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_W_OUT_FILE_FIL';
  -- XXCMM:�]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  cv_prf_wrk2_out_file      CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_W2_OUT_FILE_FIL';
  -- XXCMM:���[�U�[���A�g�f�[�^�t�@�C�����iOIC�A�g�j
  cv_prf_usr_out_file       CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_U_OUT_FILE_FIL';
-- Ver1.2(E055) Add Start
  -- XXCMM:���[�U�[���i�폜�j�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  cv_prf_usr2_out_file      CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_U2_OUT_FILE_FIL';
-- Ver1.2(E055) Add End
  -- XXCMM:PaaS�����p�̐V�K���[�U�[���t�@�C�����iOIC�A�g�j
  cv_prf_new_usr_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_NU_OUT_FILE_FIL';
  -- XXCMM:PaaS�����p�̏]�ƈ��o��������t�@�C�����iOIC�A�g�j
  cv_prf_emp_bnk_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_EBA_OUT_FILE_FIL';
  -- XXCMM:PaaS�����p�̎Ј��������t�@�C�����iOIC�A�g�j
  cv_prf_emp_inf_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_EDI_OUT_FILE_FIL';
  -- XXCMM:�Ј��f�[�^IF���񌟍�������iOIC�A�g�j
  cv_prf_1st_srch_date      CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_1ST_SC_DATE';
-- Ver1.15 Del Start
--  -- XXCMM:ERP_Cloud�����p�X���[�h�iOIC�A�g�j
--  cv_prf_password           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_PASSWORD';
-- Ver1.15 Del End
  -- XXCMM:�f�t�H���g��p����̊���ȖځiOIC�A�g�j
  cv_prf_def_account_cd     CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_DEF_ACCOUNT_CD';
  -- XXCMM:�f�t�H���g��p����̕⏕�ȖځiOIC�A�g�j
  cv_prf_def_sub_acct_cd    CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_DEF_SUB_ACCT_CD';
-- Ver1.17 Add Start
  -- XXCMM:PaaS�����p�̐V���Ј����t�@�C�����iOIC�A�g�j
  cv_prf_new_emp_out_file   CONSTANT VARCHAR2(30)  := 'XXCMM1_002A10_NE_OUT_FILE_FIL';
-- Ver1.17 Add End
--
  -- ���b�Z�[�W��
  cv_input_param_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60001';       -- �p�����[�^�o�̓��b�Z�[�W
  cv_prof_get_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';       -- �v���t�@�C���擾�G���[���b�Z�[�W
  cv_dir_path_get_err_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCOI1-00029';       -- �f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
  cv_to_date_err_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60029';       -- ���t�^�ϊ��G���[���b�Z�[�W
  cv_if_file_name_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60003';       -- IF�t�@�C�����o�̓��b�Z�[�W
  cv_file_exist_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60004';       -- ����t�@�C�����݃G���[���b�Z�[�W
  cv_lock_err_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00008';       -- ���b�N�G���[���b�Z�[�W
  cv_proc_date_get_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00018';       -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_process_date_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60005';       -- ���������o�̓��b�Z�[�W
  cv_search_trgt_cnt_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60006';       -- �����ΏہE�������b�Z�[�W
  cv_file_open_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00487';       -- �t�@�C���I�[�v���G���[���b�Z�[�W
  cv_file_write_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00488';       -- �t�@�C���������݃G���[���b�Z�[�W
  cv_file_trgt_cnt_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60007';       -- �t�@�C���o�͑ΏہE�������b�Z�[�W
  cv_insert_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00054';       -- �}���G���[���b�Z�[�W
  cv_update_err_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00055';       -- �X�V�G���[���b�Z�[�W
  cv_proc_date_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60050';       -- �Ɩ����t�o�̓��b�Z�[�W
  cv_if_date_msg            CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60051';       -- �A�g���t�o�̓��b�Z�[�W
--
  -- ���b�Z�[�W��(�g�[�N��)
  cv_rec_proc_date_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60030';       -- �Ɩ����t�i���J�o���p�j
  cv_oic_proc_mng_tbl_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60008';       -- OIC�A�g�����Ǘ��e�[�u��
  cv_oic_emp_info_tbl_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60031';       -- OIC�Ј��������e�[�u��
  cv_oic_emp_inf_bk_tbl_msg CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60032';       -- OIC�Ј��������o�b�N�A�b�v�e�[�u��
  cv_oic_wk_hiera_dept_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60047';       -- ����K�w���[�N
  cv_worker_msg             CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60033';       -- �A�Ǝ�
  cv_per_name_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60044';       -- �l��
  cv_per_legi_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60045';       -- �l���ʎd�l�f�[�^
  cv_per_email_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60046';       -- �lE���[��
  cv_work_relation_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60034';       -- �ٗp�֌W�i�ސE�ҁj
  cv_new_user_info_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60035';       -- ���[�U�[���i�V�K�j
  cv_new_user_info_paas_msg CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60049';       -- ���[�U�[���i�V�K�jPaaS�p
  cv_work_term_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60036';       -- �ٗp����
  cv_assignment_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60037';       -- �A�T�C�����g���
  cv_user_info_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60038';       -- ���[�U�[���
-- Ver1.2(E055) Add Start
  cv_user2_info_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60052';       -- ���[�U�[���i�폜�j
-- Ver1.2(E055) Add End
  cv_sup_assignment_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60039';       -- �A�T�C�����g���i�㒷�j
  cv_work_relation_2_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60040';       -- �ٗp�֌W�i�V�K�̗p�ސE�ҁj
  cv_emp_bank_acct_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60041';       -- �]�ƈ��o��������
  cv_emp_info_msg           CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-60042';       -- �Ј��������
--
  -- �g�[�N����
  cv_tkn_param_name         CONSTANT VARCHAR2(30)  := 'PARAM_NAME';             -- �g�[�N����(PARAM_NAME)
  cv_tkn_param_val          CONSTANT VARCHAR2(30)  := 'PARAM_VAL';              -- �g�[�N����(PARAM_VAL)
  cv_tkn_ng_profile         CONSTANT VARCHAR2(30)  := 'NG_PROFILE';             -- �g�[�N����(NG_PROFILE)
  cv_tkn_dir_tok            CONSTANT VARCHAR2(30)  := 'DIR_TOK';                -- �g�[�N����(DIR_TOK)
  cv_tkn_item               CONSTANT VARCHAR2(30)  := 'ITEM';                   -- �g�[�N����(ITEM)
  cv_tkn_value              CONSTANT VARCHAR2(30)  := 'VALUE';                  -- �g�[�N����(VALUE)
  cv_tkn_format             CONSTANT VARCHAR2(30)  := 'FORMAT';                 -- �g�[�N����(FORMAT)
  cv_tkn_file_name          CONSTANT VARCHAR2(30)  := 'FILE_NAME';              -- �g�[�N����(FILE_NAME)
  cv_tkn_ng_table           CONSTANT VARCHAR2(30)  := 'NG_TABLE';               -- �g�[�N����(NG_TABLE)
  cv_tkn_date1              CONSTANT VARCHAR2(30)  := 'DATE1';                  -- �g�[�N����(DATE1)
  cv_tkn_date2              CONSTANT VARCHAR2(30)  := 'DATE2';                  -- �g�[�N����(DATE2)
  cv_tkn_date               CONSTANT VARCHAR2(30)  := 'DATE';                   -- �g�[�N����(DATE)
  cv_tkn_target             CONSTANT VARCHAR2(30)  := 'TARGET';                 -- �g�[�N����(TARGET)
  cv_tkn_count              CONSTANT VARCHAR2(30)  := 'COUNT';                  -- �g�[�N����(COUNT)
  cv_tkn_table              CONSTANT VARCHAR2(30)  := 'TABLE';                  -- �g�[�N����(TABLE)
  cv_tkn_err_msg            CONSTANT VARCHAR2(30)  := 'ERR_MSG';                -- �g�[�N����(ERR_MSG)
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(30)  := 'SQLERRM';                -- �g�[�N����(SQLERRM)
-- Ver1.2(E056) Add Start
  cv_site_code_comp         CONSTANT VARCHAR2(10)  := '���';
-- Ver1.2(E056) Add End
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �v���t�@�C���l
  -- XXCMM:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
  gt_prf_val_out_file_dir       fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:�]�ƈ����A�g�f�[�^�t�@�C�����iOIC�A�g�j
  gt_prf_val_wrk_out_file       fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:�]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  gt_prf_val_wrk2_out_file      fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:���[�U�[���A�g�f�[�^�t�@�C�����iOIC�A�g�j
  gt_prf_val_usr_out_file       fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.2(E055) Add Start
  -- XXCMM:���[�U�[���i�폜�j�A�g�f�[�^�t�@�C�����iOIC�A�g�j
  gt_prf_val_usr2_out_file      fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.2(E055) Add End
  -- XXCMM:PaaS�����p�̐V�K���[�U�[���t�@�C�����iOIC�A�g�j
  gt_prf_val_new_usr_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:PaaS�����p�̏]�ƈ��o��������t�@�C�����iOIC�A�g�j
  gt_prf_val_emp_bnk_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:PaaS�����p�̎Ј��������t�@�C�����iOIC�A�g�j
  gt_prf_val_emp_inf_out_file   fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:�Ј��f�[�^IF���񌟍�������iOIC�A�g�j
  gt_prf_val_1st_srch_date      fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.15 Del Start
--  -- XXCMM:ERP_Cloud�����p�X���[�h�iOIC�A�g�j
--  gt_prf_val_password           fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.15 Del End
  -- XXCMM:�f�t�H���g��p����̊���ȖځiOIC�A�g�j
  gt_prf_val_def_account_cd     fnd_profile_option_values.profile_option_value%TYPE;
  -- XXCMM:�f�t�H���g��p����̕⏕�ȖځiOIC�A�g�j
  gt_prf_val_def_sub_acct_cd    fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.17 Add Start
  -- XXCMM:PaaS�����p�̐V���Ј����t�@�C�����iOIC�A�g�j
  gt_prf_val_new_emp_out_file   fnd_profile_option_values.profile_option_value%TYPE;
-- Ver1.17 Add End
--
  -- OIC�A�g�����Ǘ��e�[�u���̓o�^�E�X�V�f�[�^
  gt_conc_program_name          fnd_concurrent_programs.concurrent_program_name%TYPE;    -- �R���J�����g�v���O������
  gt_pre_process_date           xxccp_oic_if_process_mng.pre_process_date%TYPE;          -- �O�񏈗�����
  gv_first_proc_flag            VARCHAR2(1);                                             -- ���񏈗��t���O(Y/N)
  gt_cur_process_date           xxccp_oic_if_process_mng.pre_process_date%TYPE;          -- ���񏈗�����
--
  gt_if_dest_date               DATE;                                                    -- �A�g���t
  gv_str_pre_process_date       VARCHAR2(19);                                            -- �O�񏈗������i������j
-- Ver1.18 Add Start
  gv_str_cur_process_date       VARCHAR2(19);                                            -- ���񏈗������i������j
-- Ver1.18 Add End
--
  -- �t�@�C���n���h��
  gf_wrk_file_handle            UTL_FILE.FILE_TYPE;         -- �]�ƈ����A�g�f�[�^�t�@�C��
  gf_wrk2_file_handle           UTL_FILE.FILE_TYPE;         -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
  gf_usr_file_handle            UTL_FILE.FILE_TYPE;         -- ���[�U�[���A�g�f�[�^�t�@�C��
-- Ver1.2(E055) Add Start
  gf_usr2_file_handle           UTL_FILE.FILE_TYPE;         -- ���[�U�[���i�폜�j�A�g�f�[�^�t�@�C��
-- Ver1.2(E055) Add End
  gf_new_usr_file_handle        UTL_FILE.FILE_TYPE;         -- PaaS�����p�̐V�K���[�U�[���t�@�C��
  gf_emp_bnk_file_handle        UTL_FILE.FILE_TYPE;         -- PaaS�����p�̏]�ƈ��o��������t�@�C��
  gf_emp_inf_file_handle        UTL_FILE.FILE_TYPE;         -- PaaS�����p�̎Ј��������t�@�C��
-- Ver1.17 Add Start
  gf_new_emp_file_handle        UTL_FILE.FILE_TYPE;         -- PaaS�����p�̐V���Ј����t�@�C��
-- Ver1.17 Add End
--
  -- �ʌ���
  -- ���o����
  gn_get_wk_cnt                 NUMBER;                     -- �A�ƎҒ��o����
  gn_get_per_name_cnt           NUMBER;                     -- �l�����o����
  gn_get_per_legi_cnt           NUMBER;                     -- �l���ʎd�l�f�[�^���o����
  gn_get_per_email_cnt          NUMBER;                     -- �lE���[�����o����
  gn_get_wk_rel_cnt             NUMBER;                     -- �ٗp�֌W�i�ސE�ҁj���o����
  gn_get_new_user_cnt           NUMBER;                     -- ���[�U�[���i�V�K�j���o����
  gn_get_new_user_paas_cnt      NUMBER;                     -- ���[�U�[���i�V�K�jPaaS�p���o����
  gn_get_wk_terms_cnt           NUMBER;                     -- �ٗp�������o����
  gn_get_ass_cnt                NUMBER;                     -- �A�T�C�����g��񒊏o����
  gn_get_user_cnt               NUMBER;                     -- ���[�U�[��񒊏o����
-- Ver1.2(E055) Add Start
  gn_get_user2_cnt              NUMBER;                     -- ���[�U�[���i�폜�j���o����
-- Ver1.2(E055) Add End
  gn_get_ass_sup_cnt            NUMBER;                     -- �A�T�C�����g���i�㒷�j���o����
  gn_get_wk_rel2_cnt            NUMBER;                     -- �ٗp�֌W�i�V�K�̗p�ސE�ҁj���o����
  gn_get_bank_acc_cnt           NUMBER;                     -- �]�ƈ��o�������񒊏o����
  gn_get_emp_info_cnt           NUMBER;                     -- �Ј�������񒊏o����
  -- �o�͌���
  gn_out_wk_cnt                 NUMBER;                     -- �]�ƈ����A�g�f�[�^�t�@�C���o�͌���
  gn_out_p_new_user_cnt         NUMBER;                     -- PaaS�����p�̐V�K���[�U�[���t�@�C���o�͌���
  gn_out_user_cnt               NUMBER;                     -- ���[�U�[���A�g�f�[�^�t�@�C���o�͌���
-- Ver1.2(E055) Add Start
  gn_out_user2_cnt              NUMBER;                     -- ���[�U�[���i�폜�j�A�g�f�[�^�t�@�C���o�͌���
-- Ver1.2(E055) Add End
  gn_out_wk2_cnt                NUMBER;                     -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C���o�͌���
  gn_out_p_bank_acct_cnt        NUMBER;                     -- PaaS�����p�̏]�ƈ��o��������t�@�C���o�͌���
  gn_out_p_emp_info_cnt         NUMBER;                     -- PaaS�����p�̎Ј��������t�@�C���o�͌���
-- Ver1.17 Add Start
  gn_out_p_new_emp_cnt          NUMBER;                     -- PaaS�����p�̐V���Ј����t�@�C���o�͌���
-- Ver1.17 Add End
--  
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
--
--
  /**********************************************************************************
   * Function Name    : nvl_for_hdl
   * Description      : HDL�pNVL
   ***********************************************************************************/
  FUNCTION nvl_for_hdl(
              iv_string          IN VARCHAR2,     -- �Ώە�����
              iv_new_reg_flag    IN VARCHAR2,     -- �V�K�o�^�t���O
              iv_nvl_string      IN VARCHAR2      -- NVL�ϊ��l
           )
    RETURN VARCHAR2
  IS
  --
    -- *** ���[�J���萔 ***
    cv_prg_name         CONSTANT VARCHAR2(100) := 'nvl_for_hdl';
--
    -- *** ���[�J���ϐ� ***
  --
  BEGIN
--
    IF ( iv_new_reg_flag = cv_n ) THEN
      -- �V�K�o�^�łȂ��i�X�V�j�̏ꍇ
      IF ( iv_string IS NULL) THEN
        -- �Ώە�����NULL�̏ꍇ�ANVL�ϊ��l��ԋp
        RETURN iv_nvl_string;
      END IF;
    END IF;
--
    RETURN iv_string;
--
  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END nvl_for_hdl;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_proc_date_for_recovery  IN  VARCHAR2,     --   �Ɩ����t�i���J�o���p�j
    ov_errbuf                  OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode                 OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg                  OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lv_msg               VARCHAR2(3000);
    lt_dir_path          all_directories.directory_path%TYPE;    -- �f�B���N�g���p�X
    ld_1st_srch_date     DATE;                                   -- �Ј��f�[�^IF���񌟍������
    lb_fexists           BOOLEAN;                                -- �t�@�C�������݂��邩�ǂ���
    ln_file_length       NUMBER;                                 -- �t�@�C����
    ln_block_size        NUMBER;                                 -- �u���b�N�T�C�Y
    ld_process_date      DATE;                                   -- �Ɩ����t�iDB�j
    ln_prf_idx           NUMBER;                                 -- �v���t�@�C���p�C���f�b�N�X
    ln_file_name_idx     NUMBER;                                 -- �t�@�C�����p�C���f�b�N�X
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    -- �v���t�@�C���p���R�[�h
    TYPE l_prf_rtype IS RECORD
    (
      prf_name           VARCHAR2(30)
    , prf_value          fnd_profile_option_values.profile_option_value%TYPE
    );
    -- �v���t�@�C���p�e�[�u��
    TYPE l_prf_ttype IS TABLE OF l_prf_rtype INDEX BY BINARY_INTEGER;
    l_prf_tab    l_prf_ttype;
--
    -- �t�@�C�����p�e�[�u��
    TYPE l_file_name_ttype IS TABLE OF fnd_profile_option_values.profile_option_value%TYPE INDEX BY BINARY_INTEGER;
    l_file_name_tab      l_file_name_ttype;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- 1.���̓p�����[�^�̏o��
    -- ==============================================================
    -- ���̓p�����[�^���F�Ɩ����t�i���J�o���p�j
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
              , iv_name         => cv_input_param_msg        -- ���b�Z�[�W���F�p�����[�^�o�̓��b�Z�[�W
              , iv_token_name1  => cv_tkn_param_name         -- �g�[�N����1�FPARAM_NAME
              , iv_token_value1 => cv_rec_proc_date_msg      -- �g�[�N���l1�F�Ɩ����t�i���J�o���p�j
              , iv_token_name2  => cv_tkn_param_val          -- �g�[�N����2�FPARAM_VAL
              , iv_token_value2 => iv_proc_date_for_recovery -- �g�[�N���l2�F�p�����[�^�l
              );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
    --
    -- �p�����[�^�o�̓��b�Z�[�W�����O(LOG)�ɂ��o��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
    , buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
    , buff   => ''
    );
    --
    -- ==============================================================
    -- 2.�v���t�@�C���l�̎擾
    -- ==============================================================
    ln_prf_idx := 0;
    --
    -- 1.XXCMM:OIC�A�g�f�[�^�t�@�C���i�[�f�B���N�g����
    gt_prf_val_out_file_dir := FND_PROFILE.VALUE( cv_prf_out_file_dir );
    -- �v���t�@�C���p�e�[�u���ɐݒ�
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_out_file_dir;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_out_file_dir;
    --
    -- 2.XXCMM:�]�ƈ����A�g�f�[�^�t�@�C�����iOIC�A�g�j
    gt_prf_val_wrk_out_file := FND_PROFILE.VALUE( cv_prf_wrk_out_file );
    -- �v���t�@�C���p�e�[�u���ɐݒ�
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_wrk_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_wrk_out_file;
    --
    -- 3.XXCMM:�]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C�����iOIC�A�g�j
    gt_prf_val_wrk2_out_file := FND_PROFILE.VALUE( cv_prf_wrk2_out_file );
    -- �v���t�@�C���p�e�[�u���ɐݒ�
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_wrk2_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_wrk2_out_file;
    --
    -- 4.XXCMM:���[�U�[���A�g�f�[�^�t�@�C�����iOIC�A�g�j
    gt_prf_val_usr_out_file := FND_PROFILE.VALUE( cv_prf_usr_out_file );
    -- �v���t�@�C���p�e�[�u���ɐݒ�
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_usr_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_usr_out_file;
-- Ver1.2(E055) Add Start
    --
    -- 5.XXCMM:���[�U�[���i�폜�j�A�g�f�[�^�t�@�C�����iOIC�A�g�j
    gt_prf_val_usr2_out_file := FND_PROFILE.VALUE( cv_prf_usr2_out_file );
    -- �v���t�@�C���p�e�[�u���ɐݒ�
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_usr2_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_usr2_out_file;
-- Ver1.2(E055) Add End
    --
    -- 6.XXCMM:PaaS�����p�̐V�K���[�U�[���t�@�C�����iOIC�A�g�j
    gt_prf_val_new_usr_out_file := FND_PROFILE.VALUE( cv_prf_new_usr_out_file );
    -- �v���t�@�C���p�e�[�u���ɐݒ�
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_new_usr_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_new_usr_out_file;
    --
    -- 7.XXCMM:PaaS�����p�̏]�ƈ��o��������t�@�C�����iOIC�A�g�j
    gt_prf_val_emp_bnk_out_file := FND_PROFILE.VALUE( cv_prf_emp_bnk_out_file );
    -- �v���t�@�C���p�e�[�u���ɐݒ�
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_emp_bnk_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_emp_bnk_out_file;
    --
    -- 8.XXCMM:PaaS�����p�̎Ј��������t�@�C�����iOIC�A�g�j
    gt_prf_val_emp_inf_out_file := FND_PROFILE.VALUE( cv_prf_emp_inf_out_file );
    -- �v���t�@�C���p�e�[�u���ɐݒ�
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_emp_inf_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_emp_inf_out_file;
    --
    -- 9.XXCMM:�Ј��f�[�^IF���񌟍�������iOIC�A�g�j
    gt_prf_val_1st_srch_date := FND_PROFILE.VALUE( cv_prf_1st_srch_date );
    -- �v���t�@�C���p�e�[�u���ɐݒ�
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_1st_srch_date;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_1st_srch_date;
    --
-- Ver1.15 Del Start
--    -- 10.XXCMM:ERP_Cloud�����p�X���[�h�iOIC�A�g�j
--    gt_prf_val_password := FND_PROFILE.VALUE( cv_prf_password );
--    -- �v���t�@�C���p�e�[�u���ɐݒ�
--    ln_prf_idx := ln_prf_idx + 1;
--    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_password;
--    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_password;
--    --
-- Ver1.15 Del End
    -- 11.XXCMM:�f�t�H���g��p����̊���ȖځiOIC�A�g�j
    gt_prf_val_def_account_cd := FND_PROFILE.VALUE( cv_prf_def_account_cd );
    -- �v���t�@�C���p�e�[�u���ɐݒ�
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_def_account_cd;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_def_account_cd;
    --
    -- 12.XXCMM:�f�t�H���g��p����̕⏕�ȖځiOIC�A�g�j
    gt_prf_val_def_sub_acct_cd := FND_PROFILE.VALUE( cv_prf_def_sub_acct_cd );
    -- �v���t�@�C���p�e�[�u���ɐݒ�
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_def_sub_acct_cd;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_def_sub_acct_cd;
    --
-- Ver1.17 Add Start
    -- 13.XXCMM:PaaS�����p�̐V���Ј����t�@�C�����iOIC�A�g�j
    gt_prf_val_new_emp_out_file := FND_PROFILE.VALUE( cv_prf_new_emp_out_file );
    -- �v���t�@�C���p�e�[�u���ɐݒ�
    ln_prf_idx := ln_prf_idx + 1;
    l_prf_tab(ln_prf_idx).prf_name  := cv_prf_new_emp_out_file;
    l_prf_tab(ln_prf_idx).prf_value := gt_prf_val_new_emp_out_file;
    --
-- Ver1.17 Add End
    -- �v���t�@�C���l�`�F�b�N
    <<prf_chk_loop>>
    FOR i IN 1..l_prf_tab.COUNT LOOP
      -- �v���t�@�C���l��NULL�̏ꍇ
      IF ( l_prf_tab(i).prf_value IS NULL ) THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcmm              -- �A�v���P�[�V�����Z�k���FXXCMM
                      , iv_name         => cv_prof_get_err_msg        -- ���b�Z�[�W���F�v���t�@�C���擾�G���[���b�Z�[�W
                      , iv_token_name1  => cv_tkn_ng_profile          -- �g�[�N����1�FNG_PROFILE
                      , iv_token_value1 => l_prf_tab(i).prf_name      -- �g�[�N���l1�F�v���t�@�C��
                      );
        lv_errbuf :=  lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END LOOP prf_chk_loop;
--
    -- ==============================================================
    -- 3.�f�B���N�g���p�X�擾
    -- ==============================================================
    BEGIN
      SELECT
          RTRIM( ad.directory_path , cv_slash )   AS  directory_path        -- �f�B���N�g���p�X
      INTO
          lt_dir_path
      FROM
          all_directories  ad     -- �f�B���N�g�����
      WHERE
          ad.directory_name = gt_prf_val_out_file_dir
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcoi             -- �A�v���P�[�V�����Z�k���FXXCOI
                      , iv_name         => cv_dir_path_get_err_msg   -- ���b�Z�[�W���F�f�B���N�g���t���p�X�擾�G���[���b�Z�[�W
                      , iv_token_name1  => cv_tkn_dir_tok            -- �g�[�N����1�FDIR_TOK
                      , iv_token_value1 => gt_prf_val_out_file_dir   -- �g�[�N���l1�F�f�B���N�g����
                      );
        --
        lv_errmsg :=  lv_errbuf;
        RAISE  global_process_expt;
    END;
--
    -- ==============================================================
    -- 4.�v���t�@�C���l�u�Ј��f�[�^IF���񌟍�������v�̓��t�^�ϊ�
    -- ==============================================================
    BEGIN
      ld_1st_srch_date := TO_DATE( gt_prf_val_1st_srch_date , cv_datetime_fmt );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                      , iv_name         => cv_to_date_err_msg        -- ���b�Z�[�W���F���t�^�ϊ��G���[���b�Z�[�W
                      , iv_token_name1  => cv_tkn_item               -- �g�[�N����1�FITEM
                      , iv_token_value1 => cv_prf_1st_srch_date      -- �g�[�N���l1�F�v���t�@�C����
                      , iv_token_name2  => cv_tkn_value              -- �g�[�N����2�FVALUE
                      , iv_token_value2 => gt_prf_val_1st_srch_date  -- �g�[�N���l2�F�v���t�@�C���l
                      , iv_token_name3  => cv_tkn_format             -- �g�[�N����3�FFORMAT
                      , iv_token_value3 => cv_datetime_fmt           -- �g�[�N���l3�F�ϊ�����
                      );
        --
        lv_errmsg :=  lv_errbuf;
        RAISE  global_process_expt;
    END;
--
    -- ==============================================================
    -- 5.IF�t�@�C�����̏o��
    -- ==============================================================
    ln_file_name_idx := 0;
    --
    -- �]�ƈ����A�g�f�[�^�t�@�C����
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_wrk_out_file;
    --
    -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C����
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_wrk2_out_file;
    --
    -- ���[�U�[���A�g�f�[�^�t�@�C����
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_usr_out_file;
-- Ver1.2(E055) Add Start
    --
    -- ���[�U�[���i�폜�j�A�g�f�[�^�t�@�C����
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_usr2_out_file;
-- Ver1.2(E055) Add End
    --
    -- PaaS�����p�̐V�K���[�U�[���t�@�C����
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_new_usr_out_file;
    --
    -- PaaS�����p�̏]�ƈ��o��������t�@�C����
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_emp_bnk_out_file;
    --
    -- PaaS�����p�̎Ј��������t�@�C����
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_emp_inf_out_file;
    --
-- Ver1.17 Add Start
    -- PaaS�����p�̐V���Ј����t�@�C����
    ln_file_name_idx := ln_file_name_idx + 1;
    l_file_name_tab(ln_file_name_idx) := gt_prf_val_new_emp_out_file;
    --
-- Ver1.17 Add End
    <<file_name_out_loop>>
    FOR i IN 1..l_file_name_tab.COUNT LOOP
      --
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                , iv_name         => cv_if_file_name_msg       -- ���b�Z�[�W���FIF�t�@�C�����o�̓��b�Z�[�W
                , iv_token_name1  => cv_tkn_file_name          -- �g�[�N����1�FFILE_NAME
                , iv_token_value1 => lt_dir_path
                                       || cv_slash
                                       || l_file_name_tab(i)   -- �g�[�N���l1�F�f�B���N�g���p�X�{�t�@�C����
                );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
      );
    END LOOP file_name_out_loop;
    --
    -- ��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ==============================================================
    -- 6.�t�@�C�����݃`�F�b�N
    -- ==============================================================
    <<file_exist_chk_loop>>
    FOR i IN 1..l_file_name_tab.COUNT LOOP
      --
      UTL_FILE.FGETATTR(
        location     => gt_prf_val_out_file_dir
      , filename     => l_file_name_tab(i)
      , fexists      => lb_fexists
      , file_length  => ln_file_length
      , block_size   => ln_block_size
      );
      --
      IF ( lb_fexists = TRUE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k��
                     , iv_name        => cv_file_exist_err_msg     -- ���b�Z�[�W�R�[�h
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END LOOP file_exist_chk_loop;
--
    -- ==============================================================
    -- 7.�R���J�����g�v���O�������A����ёO�񏈗������̎擾
    -- ==============================================================
    SELECT
        fcp.concurrent_program_name                    AS conc_program_name        -- �R���J�����g�v���O������
      , NVL(xoipm.pre_process_date, ld_1st_srch_date)  AS pre_process_date         -- �O�񏈗�����
      , (CASE
           WHEN xoipm.pre_process_date IS NOT NULL THEN
             cv_n
           ELSE
             cv_y
         END)                                          AS first_proc_flag          -- ���񏈗��t���O
    INTO
        gt_conc_program_name
      , gt_pre_process_date
      , gv_first_proc_flag
    FROM
        fnd_concurrent_programs    fcp       -- �R���J�����g�v���O����
      , xxccp_oic_if_process_mng   xoipm     -- OIC�A�g�����Ǘ��e�[�u��
    WHERE
        fcp.concurrent_program_id   = cn_program_id
    AND fcp.concurrent_program_name = xoipm.program_name(+)
    FOR UPDATE OF xoipm.pre_process_date NOWAIT
    ;
--
    -- ==============================================================
    -- 8.���񏈗������̎擾
    -- ==============================================================
    gt_cur_process_date := SYSDATE;
--
    -- ==============================================================
    -- 9.�O��E���񏈗������̏o��
    -- ==============================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
              , iv_name         => cv_process_date_msg       -- ���b�Z�[�W���F���������o�̓��b�Z�[�W
              , iv_token_name1  => cv_tkn_date1              -- �g�[�N����1�FDATE1
              , iv_token_value1 => TO_CHAR(
                                     gt_pre_process_date
                                   , cv_datetime_fmt
                                   )                         -- �g�[�N���l1�F�O�񏈗�����
              , iv_token_name2  => cv_tkn_date2              -- �g�[�N����2�FDATE2
              , iv_token_value2 => TO_CHAR(
                                     gt_cur_process_date
                                   , cv_datetime_fmt
                                   )                         -- �g�[�N���l2�F���񏈗�����
              );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ==============================================================
    -- 10.�Ɩ����t�̎擾
    -- ==============================================================
    ld_process_date := xxccp_common_pkg2.get_process_date;
--
    IF ( ld_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                   , iv_name         => cv_proc_date_get_err_msg  -- ���b�Z�[�W���F�Ɩ����t�擾�G���[���b�Z�[�W
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
              , iv_name         => cv_proc_date_msg          -- ���b�Z�[�W���F�Ɩ����t�o�̓��b�Z�[�W
              , iv_token_name1  => cv_tkn_date               -- �g�[�N����1�FDATE
              , iv_token_value1 => TO_CHAR(
                                     ld_process_date
                                   , cv_date_fmt
                                   )                         -- �g�[�N���l1�F�Ɩ����t�i�e�[�u���j
              );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ==============================================================
    -- 11.�A�g���t�̐ݒ�
    -- ==============================================================
    IF ( iv_proc_date_for_recovery IS NOT NULL ) THEN
      gt_if_dest_date := TO_DATE( iv_proc_date_for_recovery , cv_datetime_fmt ) + 1;
    ELSE
      gt_if_dest_date := ld_process_date + 1;
    END IF;
    --
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
              , iv_name         => cv_if_date_msg            -- ���b�Z�[�W���F�A�g���t�o�̓��b�Z�[�W
              , iv_token_name1  => cv_tkn_date               -- �g�[�N����1�FDATE
              , iv_token_value1 => TO_CHAR(
                                     gt_if_dest_date
                                   , cv_date_fmt
                                   )                         -- �g�[�N���l1�F�A�g���t
              );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_msg
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- ==============================================================
    -- 12.�O�񏈗������i������j�̐ݒ�
    -- �i�]�ƈ��}�X�^�A�A�T�C�����g�}�X�^��DFF�����p�j
    -- ==============================================================
    gv_str_pre_process_date := TO_CHAR( gt_pre_process_date , cv_datetime_fmt );
--
    -- ==============================================================
    -- 13.�t�@�C���I�[�v��
    -- ==============================================================
    BEGIN
      -- �]�ƈ����A�g�f�[�^�t�@�C��
      gf_wrk_file_handle      := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_wrk_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
      --
      -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
      gf_wrk2_file_handle     := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_wrk2_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
      --
      -- ���[�U�[���A�g�f�[�^�t�@�C��
      gf_usr_file_handle      := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_usr_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
-- Ver1.2(E055) Add Start
      --
      -- ���[�U�[���i�폜�j�A�g�f�[�^�t�@�C��
      gf_usr2_file_handle     := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_usr2_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
-- Ver1.2(E055) Add End
      --
      -- PaaS�����p�̐V�K���[�U�[���t�@�C��
      gf_new_usr_file_handle  := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_new_usr_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
      --
      -- PaaS�����p�̏]�ƈ��o��������t�@�C��
      gf_emp_bnk_file_handle  := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_emp_bnk_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
      --
      -- PaaS�����p�̎Ј��������t�@�C��
      gf_emp_inf_file_handle  := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_emp_inf_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
-- Ver1.17 Add Start
      --
      -- PaaS�����p�̐V���Ј����t�@�C��
      gf_new_emp_file_handle  := UTL_FILE.FOPEN(
                                   location     => gt_prf_val_out_file_dir
                                 , filename     => gt_prf_val_new_emp_out_file
                                 , open_mode    => cv_open_mode_w
                                 , max_linesize => cn_max_linesize
                                 );
-- Ver1.17 Add End
  EXCEPTION
    WHEN OTHERS THEN
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                     , iv_name         => cv_file_open_err_msg      -- ���b�Z�[�W���F�t�@�C���I�[�v���G���[���b�Z�[�W
                     , iv_token_name1  => cv_tkn_sqlerrm            -- �g�[�N����1�FSQLERRM
                     , iv_token_value1 => SQLERRM                   -- �g�[�N���l1�FSQLERRM
                     )
                   , 1
                   , 5000
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
--
-- Ver1.18 Add Start
    -- ==============================================================
    -- 14.���񏈗������i������j�̐ݒ�
    -- �i�]�ƈ��}�X�^�A�A�T�C�����g�}�X�^��DFF�����p�j
    -- ==============================================================
    gv_str_cur_process_date := TO_CHAR( gt_cur_process_date , cv_datetime_fmt );
--
-- Ver1.18 Add Start
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                   , iv_name         => cv_lock_err_msg           -- ���b�Z�[�W���F���b�N�G���[���b�Z�[�W
                   , iv_token_name1  => cv_tkn_ng_table           -- �g�[�N����1�FNG_TABLE
                   , iv_token_value1 => cv_oic_proc_mng_tbl_msg   -- �g�[�N���l1�FOIC�A�g�����Ǘ��e�[�u��
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
--
  /**********************************************************************************
   * Procedure Name   : output_worker
   * Description      : �]�ƈ����̒��o�E�t�@�C���o�͏���(A-2)
   ***********************************************************************************/
  PROCEDURE output_worker(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_worker';       -- �v���O������
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
    lv_wt_header_wrk     VARCHAR2(1);
    lv_wt_header_wrk2    VARCHAR2(1);
    lv_ass_header_wrk    VARCHAR2(1);
    lv_ass_header_wrk2   VARCHAR2(1);
--
    ------------------------------------
    --�w�b�_�[�s(Worker)
    ------------------------------------
    cv_worker_header     CONSTANT VARCHAR2(10000) :=
                    'METADATA'                                                     --  1 : METADATA
      || cv_pipe || 'Worker'                                                       --  2 : Worker
      || cv_pipe || 'FLEX:PER_PERSONS_DFF'                                         --  3 : FLEX:PER_PERSONS_DFF�i�R���e�L�X�g�j
      || cv_pipe || 'PersonNumber'                                                 --  4 : PersonNumber�i�l�ԍ��j
      || cv_pipe || 'EffectiveStartDate'                                           --  5 : EffectiveStartDate�i�L���J�n���j
      || cv_pipe || 'ActionCode'                                                   --  6 : ActionCode�i�����R�[�h�j
      || cv_pipe || 'StartDate'                                                    --  7 : StartDate�i�J�n���j
                                                                                   --      (��PER_PERSONS_DFF=ITO_SALES_USE_ITEM)
      || cv_pipe || 'point(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'                    --  8 : point�i�|�C���g)
      || cv_pipe || 'qualificationCode(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'        --  9 : qualificationCode�i���i�R�[�h)
      || cv_pipe || 'employeeClass(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'            -- 10 : employeeClass�i�]�ƈ��敪)
      || cv_pipe || 'vendorCode(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 11 : vendorCode�i�d����R�[�h)
      || cv_pipe || 'representativeCarrier(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'    -- 12 : representativeCarrier�i�^���Ǝ�)
      || cv_pipe || 'vendorsSiteCode(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 13 : vendorsSiteCode�i�d����T�C�g�R�[�h)
      || cv_pipe || 'qualificationCodeNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 14 : qualificationCodeNew�i���i�R�[�h�i�V�j)
      || cv_pipe || 'qualificationNameNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 15 : qualificationNameNew�i���i���i�V�j)
      || cv_pipe || 'qualificationCodeOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 16 : qualificationCodeOld�i���i�R�[�h�i���j)
      || cv_pipe || 'qualificationNameOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 17 : qualificationNameOld�i���i���i���j)
      || cv_pipe || 'positionCodeNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 18 : positionCodeNew�i�E�ʃR�[�h�i�V�j)
      || cv_pipe || 'positionNameNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 19 : positionNameNew�i�E�ʖ��i�V�j)
      || cv_pipe || 'positionCodeOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 20 : positionCodeOld�i�E�ʃR�[�h�i���j)
      || cv_pipe || 'positionNameOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 21 : positionNameOld�i�E�ʖ��i���j)
      || cv_pipe || 'jobCodeNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 22 : jobCodeNew�i�E���R�[�h�i�V�j)
      || cv_pipe || 'jobNameNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 23 : jobNameNew�i�E�����i�V�j)
      || cv_pipe || 'jobCodeOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 24 : jobCodeOld�i�E���R�[�h�i���j)
      || cv_pipe || 'jobNameOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'               -- 25 : jobNameOld�i�E�����i���j)
      || cv_pipe || 'occupationalCodeNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'      -- 26 : occupationalCodeNew�i�E��R�[�h�i�V�j)
      || cv_pipe || 'occupationalNameNew(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'      -- 27 : occupationalNameNew�i�E�햼�i�V�j)
      || cv_pipe || 'occupationalCodeOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'      -- 28 : occupationalCodeOld�i�E��R�[�h�i���j)
      || cv_pipe || 'occupationalNameOld(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'      -- 29 : occupationalNameOld�i�E�햼�i���j)
      || cv_pipe || 'DepartmentChild(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'          -- 30 : DepartmentChild�i��������)
      || cv_pipe || 'referrenceDepartment(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'     -- 31 : referrenceDepartment�i�Ɖ�͈�)
      || cv_pipe || 'approvalDepartment(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'       -- 32 : approvalDepartment�i���F�Ҕ͈�)
      || cv_pipe || 'paymentMethod(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'            -- 33 : paymentMethod�i�x�����@)
      || cv_pipe || 'inquiryBaseCodeP(PER_PERSONS_DFF=ITO_SALES_USE_ITEM)'         -- 34 : inquiryBaseCodeP�i�⍇���S�����_�R�[�h)
                                                                                   --      (��PER_PERSONS_DFF=ITO_SALES_USE_ITEM)
      || cv_pipe || 'SourceSystemOwner'                                            -- 35 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      || cv_pipe || 'SourceSystemId'                                               -- 36 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
    ;
    --
    ------------------------------------
    --�w�b�_�[�s(PersonName)
    ------------------------------------
    cv_per_name_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'PersonName'                       --  2 : PersonName
      || cv_pipe || 'PersonNumber'                     --  3 : PersonNumber�i�l�ԍ��j
      || cv_pipe || 'NameType'                         --  4 : NameType�i���O�^�C�v�j
      || cv_pipe || 'EffectiveStartDate'               --  5 : EffectiveStartDate�i�L���J�n���j
      || cv_pipe || 'LegislationCode'                  --  6 : LegislationCode�i���ʎd�l�R�[�h�j
      || cv_pipe || 'FirstName'                        --  7 : FirstName�i���j
      || cv_pipe || 'LastName'                         --  8 : LastName�i���j
      || cv_pipe || 'NameInformation1'                 --  9 : NameInformation1�i���O���1�j
      || cv_pipe || 'NameInformation2'                 -- 10 : NameInformation2�i���O���2�j
      || cv_pipe || 'SourceSystemOwner'                -- 11 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      || cv_pipe || 'SourceSystemId'                   -- 12 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
    ;
    --
    ------------------------------------
    --�w�b�_�[�s(PersonLegislativeData)
    ------------------------------------
    cv_per_legi_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         -- 1 : METADATA
      || cv_pipe || 'PersonLegislativeData'            -- 2 : PersonLegislativeData
      || cv_pipe || 'PersonNumber'                     -- 3 : PersonNumber�i�l�ԍ��j
      || cv_pipe || 'LegislationCode'                  -- 4 : LegislationCode�i���ʎd�l�R�[�h�j
      || cv_pipe || 'EffectiveStartDate'               -- 5 : EffectiveStartDate�i�L���J�n���j
      || cv_pipe || 'Sex'                              -- 6 : Sex�i���ʁj
      || cv_pipe || 'SourceSystemOwner'                -- 7 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      || cv_pipe || 'SourceSystemId'                   -- 8 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
    ;
    --
    ------------------------------------
    --�w�b�_�[�s(PersonEmail)
    ------------------------------------
    cv_per_email_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         -- 1 : METADATA
      || cv_pipe || 'PersonEmail'                      -- 2 : PersonEmail
      || cv_pipe || 'EmailAddress'                     -- 3 : EmailAddress�iE���[���E�A�h���X�j
      || cv_pipe || 'EmailType'                        -- 4 : EmailType�iE���[���E�^�C�v�j
      || cv_pipe || 'PersonNumber'                     -- 5 : PersonNumber�i�l�ԍ��j
      || cv_pipe || 'DateFrom'                         -- 6 : DateFrom�i���t: ���j
      || cv_pipe || 'SourceSystemOwner'                -- 7 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      || cv_pipe || 'SourceSystemId'                   -- 8 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
    ;
    --
    ------------------------------------
    --�w�b�_�[�s(WorkRelationship)
    ------------------------------------
    cv_wk_rel_header      CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'WorkRelationship'                 --  2 : WorkRelationship
      || cv_pipe || 'PersonNumber'                     --  3 : PersonNumber�i�l�ԍ��j
      || cv_pipe || 'WorkerType'                       --  4 : WorkerType�i�A�Ǝ҃^�C�v�j
      || cv_pipe || 'DateStart'                        --  5 : DateStart�i�J�n���j
      || cv_pipe || 'LegalEmployerName'                --  6 : LegalEmployerName�i�ٗp��j
      || cv_pipe || 'PrimaryFlag'                      --  7 : PrimaryFlag�i�v���C�}���ٗp�j
      || cv_pipe || 'ActualTerminationDate'            --  8 : ActualTerminationDate�i���ёސE���j
      || cv_pipe || 'TerminateWorkRelationshipFlag'    --  9 : TerminateWorkRelationshipFlag�i�ٗp�֌W�̏I���j
      || cv_pipe || 'ReverseTerminationFlag'           -- 10 : ReverseTerminationFlag�i�ސE�̎���j
      || cv_pipe || 'ActionCode'                       -- 11 : ActionCode�i�����R�[�h�j
      || cv_pipe || 'SourceSystemOwner'                -- 12 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      || cv_pipe || 'SourceSystemId'                   -- 13 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
    ;
    --
    ------------------------------------
    --�w�b�_�[�s(PersonUserInformation)
    ------------------------------------
    cv_per_user_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         -- 1 : METADATA
      || cv_pipe || 'PersonUserInformation'            -- 2 : PersonUserInformation
      || cv_pipe || 'UserName'                         -- 3 : UserName�i���[�U�[���j
      || cv_pipe || 'PersonNumber'                     -- 4 : PersonNumber�i�l�ԍ��j
      || cv_pipe || 'StartDate'                        -- 5 : StartDate�i�J�n���j
      || cv_pipe || 'GeneratedUserAccountFlag'         -- 6 : GeneratedUserAccountFlag�i�����σ��[�U�[�E�A�J�E���g�j
      || cv_pipe || 'SendCredentialsEmailFlag'         -- 7 : SendCredentialsEmailFlag�i���i�ؖ�E���[���̑��M�j
    ;
    --
    ------------------------------------
    --�w�b�_�[�s(WorkTerms)
    ------------------------------------
    cv_wk_terms_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'WorkTerms'                        --  2 : WorkTerms
      || cv_pipe || 'AssignmentNumber'                 --  3 : AssignmentNumber�i�A�T�C�����g�ԍ��j
      || cv_pipe || 'PersonNumber'                     --  4 : PersonNumber�i�l�ԍ��j
      || cv_pipe || 'WorkerType'                       --  5 : WorkerType�i�A�Ǝ҃^�C�v�j
      || cv_pipe || 'DateStart'                        --  6 : DateStart�i�J�n���j
      || cv_pipe || 'LegalEmployerName'                --  7 : LegalEmployerName�i�ٗp�喼�j
      || cv_pipe || 'EffectiveLatestChange'            --  8 : EffectiveLatestChange�i�L���ŏI�ύX�j
      || cv_pipe || 'EffectiveStartDate'               --  9 : EffectiveStartDate�i�L���J�n���j
      || cv_pipe || 'EffectiveSequence'                -- 10 : EffectiveSequence�i�L�������j
      || cv_pipe || 'AssignmentStatusTypeCode'         -- 11 : AssignmentStatusTypeCode�i�A�T�C�����g�E�X�e�[�^�X�E�^�C�v�j
      || cv_pipe || 'AssignmentType'                   -- 12 : AssignmentType�i�A�T�C�����g�E�^�C�v�j
      || cv_pipe || 'AssignmentName'                   -- 13 : AssignmentName�i�A�T�C�����g���j
      || cv_pipe || 'SystemPersonType'                 -- 14 : SystemPersonType�i�V�X�e��Person�^�C�v�j
      || cv_pipe || 'BusinessUnitShortCode'            -- 15 : BusinessUnitShortCode�i�r�W�l�X�E���j�b�g�j
      || cv_pipe || 'ActionCode'                       -- 16 : ActionCode�i�����R�[�h�j
      || cv_pipe || 'PrimaryWorkTermsFlag'             -- 17 : PrimaryWorkTermsFlag�i�ٗp�֌W�̃v���C�}���ٗp�����j
      || cv_pipe || 'SourceSystemOwner'                -- 18 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      || cv_pipe || 'SourceSystemId'                   -- 19 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
    ;
    --
    ------------------------------------
    --�w�b�_�[�s(Assignment)
    ------------------------------------
    cv_ass_header        CONSTANT VARCHAR2(10000) :=
                    'METADATA'                                                --  1 : METADATA
      || cv_pipe || 'Assignment'                                              --  2 : Assignment
      || cv_pipe || 'FLEX:PER_ASG_DF'                                         --  3 : FLEX:PER_ASG_DF�i�R���e�L�X�g�j
      || cv_pipe || 'AssignmentNumber'                                        --  4 : AssignmentNumber�i�A�T�C�����g�ԍ��j
      || cv_pipe || 'WorkTermsNumber'                                         --  5 : WorkTermsNumber�i�Ζ������ԍ��j
      || cv_pipe || 'EffectiveLatestChange'                                   --  6 : EffectiveLatestChange�i�L���ŏI�ύX�j
      || cv_pipe || 'EffectiveStartDate'                                      --  7 : EffectiveStartDate�i�L���J�n���j
      || cv_pipe || 'EffectiveSequence'                                       --  8 : EffectiveSequence�i�L�������j
      || cv_pipe || 'PersonTypeCode'                                          --  9 : PersonTypeCode�iPerson�^�C�v�j
      || cv_pipe || 'AssignmentStatusTypeCode'                                -- 10 : AssignmentStatusTypeCode�i�A�T�C�����g�E�X�e�[�^�X�E�^�C�v�j
      || cv_pipe || 'AssignmentType'                                          -- 11 : AssignmentType�i�A�T�C�����g�E�^�C�v�j
      || cv_pipe || 'SystemPersonType'                                        -- 12 : SystemPersonType�i�V�X�e��Person�^�C�v�j
      || cv_pipe || 'AssignmentName'                                          -- 13 : AssignmentName�i�A�T�C�����g���j
      || cv_pipe || 'JobCode'                                                 -- 14 : JobCode�i�W���u�E�R�[�h�j
      || cv_pipe || 'DefaultExpenseAccount'                                   -- 15 : DefaultExpenseAccount�i�f�t�H���g��p����j
      || cv_pipe || 'BusinessUnitShortCode'                                   -- 16 : BusinessUnitShortCode�i�r�W�l�X�E���j�b�g�j
      || cv_pipe || 'ManagerFlag'                                             -- 17 : ManagerFlag�i�}�l�[�W���j
      || cv_pipe || 'LocationCode'                                            -- 18 : LocationCode�i���Ə��R�[�h�j
      || cv_pipe || 'PersonNumber'                                            -- 19 : PersonNumber�i�l�ԍ��j
      || cv_pipe || 'ActionCode'                                              -- 20 : ActionCode�i�����R�[�h�j
      || cv_pipe || 'WorkerType'                                              -- 21 : WorkerType�i�A�Ǝ҃^�C�v�j
      || cv_pipe || 'DepartmentName'                                          -- 22 : DepartmentName�i����j
      || cv_pipe || 'DateStart'                                               -- 23 : DateStart�i�J�n���j
      || cv_pipe || 'LegalEmployerName'                                       -- 24 : LegalEmployerName�i�ٗp�喼�j
      || cv_pipe || 'PrimaryAssignmentFlag'                                   -- 25 : PrimaryAssignmentFlag�i�ٗp�֌W�̃v���C�}���E�A�T�C�����g�j
                                                                              --      (��PER_ASG_DF=ITO_SALES_USE_ITEM)
      || cv_pipe || 'transferReasonCode(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 26 : transferReasonCode�i�ٓ����R�R�[�h)
      || cv_pipe || 'announceDate(PER_ASG_DF=ITO_SALES_USE_ITEM)'             -- 27 : announceDate�i���ߓ�)
      || cv_pipe || 'workLocDepartmentNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'     -- 28 : workLocDepartmentNew�i�Ζ��n���_�R�[�h�i�V�j)
      || cv_pipe || 'workLocDepartmentOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'     -- 29 : workLocDepartmentOld�i�Ζ��n���_�R�[�h�i���j)
      || cv_pipe || 'departmentNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'            -- 30 : departmentNew�i���_�R�[�h�i�V�j�j
      || cv_pipe || 'departmentOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'            -- 31 : departmentOld�i���_�R�[�h�i���j)
      || cv_pipe || 'appWorkTimeCodeNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 32 : appWorkTimeCodeNew�i�K�p�J�����Ԑ��R�[�h�i�V�j)
      || cv_pipe || 'appWorkTimeNameNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 33 : appWorkTimeNameNew�i�K�p�J�����i�V�j)
      || cv_pipe || 'appWorkTimeCodeOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 34 : appWorkTimeCodeOld�i�K�p�J�����Ԑ��R�[�h�i���j)
      || cv_pipe || 'appWorkTimeNameOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'       -- 35 : appWorkTimeNameOld�i�K�p�J�����i���j)
      || cv_pipe || 'positionSortCodeNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'      -- 36 : positionSortCodeNew�i�E�ʕ����R�[�h�i�V�j)
      || cv_pipe || 'positionSortCodeOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'      -- 37 : positionSortCodeOld�i�E�ʕ����R�[�h�i���j)
      || cv_pipe || 'approvalClassNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'         -- 38 : approvalClassNew�i���F�敪�i�V�j)
      || cv_pipe || 'approvalClassOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'         -- 39 : approvalClassOld�i���F�敪�i���j�j
      || cv_pipe || 'alternateClassNew(PER_ASG_DF=ITO_SALES_USE_ITEM)'        -- 40 : alternateClassNew�i��s�敪�i�V�j)
      || cv_pipe || 'alternateClassOld(PER_ASG_DF=ITO_SALES_USE_ITEM)'        -- 41 : alternateClassOld�i��s�敪�i���j)
      || cv_pipe || 'transferDateVend(PER_ASG_DF=ITO_SALES_USE_ITEM)'         -- 42 : transferDateVend�i�����A�g�p���t�i���̋@�j)
      || cv_pipe || 'transferDateRep(PER_ASG_DF=ITO_SALES_USE_ITEM)'          -- 43 : transferDateRep�i�����A�g�p���t�i���[�j)
                                                                              --      (��PER_ASG_DF=ITO_SALES_USE_ITEM)
      || cv_pipe || 'SourceSystemOwner'                                       -- 44 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      || cv_pipe || 'SourceSystemId'                                          -- 45 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
    ;
--
    -- *** ���[�J���ϐ� ***
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- �o�͓��e
--
    -- *** ���[�J���E�J�[�\�� ***
    --------------------------------------
    -- �A�Ǝ҂̒��o�J�[�\��
    --------------------------------------
    CURSOR worker_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- �]�ƈ��ԍ�
        , (SELECT
               TO_CHAR(MIN(papf3.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f     papf3  -- �]�ƈ��}�X�^
           WHERE
               papf3.person_id = papf.person_id
          )                                                 AS effective_start_date       -- �L���J�n��
-- Ver1.8 Mod Start
--        , TO_CHAR(papf.start_date, cv_date_fmt)             AS start_date                 -- �J�n��
        , (SELECT
               TO_CHAR(MIN(papf4.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f     papf4  -- �]�ƈ��}�X�^
           WHERE
               papf4.person_id = papf.person_id
          )                                                 AS start_date                 -- �J�n��
-- Ver1.8 Mod Start
        , papf.attribute1                                   AS attribute1                 -- �|�C���g
        , papf.attribute2                                   AS attribute2                 -- ���i�R�[�h
        , papf.attribute3                                   AS attribute3                 -- �]�ƈ��敪
        , papf.attribute4                                   AS attribute4                 -- �d����R�[�h
        , papf.attribute5                                   AS attribute5                 -- �^���Ǝ�
        , papf.attribute6                                   AS attribute6                 -- �d����T�C�g�R�[�h
        , papf.attribute7                                   AS attribute7                 -- ���i�R�[�h�i�V�j
        , papf.attribute8                                   AS attribute8                 -- ���i���i�V�j
        , papf.attribute9                                   AS attribute9                 -- ���i�R�[�h�i���j
        , papf.attribute10                                  AS attribute10                -- ���i���i���j
        , papf.attribute11                                  AS attribute11                -- �E�ʃR�[�h�i�V�j
        , papf.attribute12                                  AS attribute12                -- �E�ʖ��i�V�j
        , papf.attribute13                                  AS attribute13                -- �E�ʃR�[�h�i���j
        , papf.attribute14                                  AS attribute14                -- �E�ʖ��i���j
        , papf.attribute15                                  AS attribute15                -- �E���R�[�h�i�V�j
        , papf.attribute16                                  AS attribute16                -- �E�����i�V�j
        , papf.attribute17                                  AS attribute17                -- �E���R�[�h�i���j
        , papf.attribute18                                  AS attribute18                -- �E�����i���j
        , papf.attribute19                                  AS attribute19                -- �E��R�[�h�i�V�j
        , papf.attribute20                                  AS attribute20                -- �E�햼�i�V�j
        , papf.attribute21                                  AS attribute21                -- �E��R�[�h�i���j
        , papf.attribute22                                  AS attribute22                -- �E�햼�i���j
        , papf.attribute28                                  AS attribute28                -- ��������
        , papf.attribute29                                  AS attribute29                -- �Ɖ�͈�
        , papf.attribute30                                  AS attribute30                -- ���F�Ҕ͈�
        , pvsa.pay_group_lookup_code                        AS pay_group_lookup_code      -- �x���O���[�v
        , pvsa.attribute5                                   AS inquiry_base_code_p        -- �⍇���S�����_�R�[�h
        , papf.person_id                                    AS person_id                  -- �lID
        , (CASE
             WHEN papf.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- �V�K�o�^�t���O
      FROM
          per_all_people_f     papf  -- �]�ƈ��}�X�^
        , po_vendors           pv    -- �d����}�X�^
        , po_vendor_sites_all  pvsa  -- �d����T�C�g�}�X�^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
      AND pv.vendor_id                  = pvsa.vendor_id(+)
-- Ver1.2(E056) Add Start
      AND pvsa.vendor_site_code(+)      = cv_site_code_comp
-- Ver1.2(E056) Add End
-- Ver1.18 Mod Start
--      AND (   papf.last_update_date >= gt_pre_process_date
---- Ver1.13 Mod Start
----           OR papf.attribute23      >= gv_str_pre_process_date)
--           OR papf.attribute23      >= gv_str_pre_process_date
--           OR pvsa.last_update_date >= gt_pre_process_date
--          )
---- Ver1.13 Mod End
      AND (   
              (     papf.last_update_date >= gt_pre_process_date
                AND papf.last_update_date <  gt_cur_process_date
              )
           OR (
                    papf.attribute23      >= gv_str_pre_process_date
                AND papf.attribute23      <  gv_str_cur_process_date
              )
           OR (
                    pvsa.last_update_date >= gt_pre_process_date
                AND pvsa.last_update_date <  gt_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- �l���̒��o�J�[�\��
    --------------------------------------
    CURSOR per_name_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- �]�ƈ��ԍ�
        , (SELECT
               TO_CHAR(MIN(papf3.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f  papf3  -- �]�ƈ��}�X�^
           WHERE
               papf3.person_id = papf.person_id
          )                                                 AS effective_start_date       -- �L���J�n��
        , papf.person_id                                    AS person_id                  -- �lID
        , papf.first_name                                   AS first_name                 -- ��
        , papf.last_name                                    AS last_name                  -- ��
        , papf.per_information18                            AS per_information18          -- ������
        , papf.per_information19                            AS per_information19          -- ������
        , (CASE
             WHEN papf.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- �V�K�o�^�t���O
      FROM
          per_all_people_f       papf   -- �]�ƈ��}�X�^
        , po_vendors             pv     -- �d����}�X�^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
-- Ver1.18 Mod Start
--      AND (   papf.last_update_date >= gt_pre_process_date
--           OR papf.attribute23      >= gv_str_pre_process_date)
      AND (   
              (     papf.last_update_date >= gt_pre_process_date
                AND papf.last_update_date <  gt_cur_process_date
              )
           OR (
                    papf.attribute23      >= gv_str_pre_process_date
                AND papf.attribute23      <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- �l���ʎd�l�f�[�^�̒��o�J�[�\��
    --------------------------------------
    CURSOR per_legi_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- �]�ƈ��ԍ�
        , (SELECT
               TO_CHAR(MIN(papf3.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f  papf3  -- �]�ƈ��}�X�^
           WHERE
               papf3.person_id = papf.person_id
          )                                                 AS effective_start_date       -- �L���J�n��
        , papf.person_id                                    AS person_id                  -- �lID
        , papf.sex                                          AS sex                        -- ����
        , (CASE
             WHEN papf.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- �V�K�o�^�t���O
      FROM
          per_all_people_f       papf   -- �]�ƈ��}�X�^
        , po_vendors             pv     -- �d����}�X�^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2  -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
-- Ver1.18 Mod Start
--      AND (   papf.last_update_date >= gt_pre_process_date
--           OR papf.attribute23      >= gv_str_pre_process_date)
      AND (   
              (     papf.last_update_date >= gt_pre_process_date
                AND papf.last_update_date <  gt_cur_process_date
              )
           OR (
                    papf.attribute23      >= gv_str_pre_process_date
                AND papf.attribute23      <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- �lE���[���̒��o�J�[�\��
    --------------------------------------
    CURSOR per_email_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- �]�ƈ��ԍ�
        , (SELECT
               TO_CHAR(MIN(papf3.effective_start_date), cv_date_fmt)
           FROM
               per_all_people_f  papf3  -- �]�ƈ��}�X�^
           WHERE
               papf3.person_id = papf.person_id
           )                                                AS effective_start_date       -- �L���J�n��
        , papf.person_id                                    AS person_id                  -- �lID
        , (cv_itoen_email_suffix ||
           papf.employee_number  ||
           cv_itoen_email_domain)                           AS email_address              -- E���[���E�A�h���X
      FROM
          per_all_people_f       papf   -- �]�ƈ��}�X�^
        , po_vendors             pv     -- �d����}�X�^
      WHERE
-- Ver1.10 Mod Start
--          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external)  -- �]�ƈ��敪�i1:�����A2:�O���j
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
-- Ver1.10 Mod End
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
               )
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
-- Ver1.18 Mod Start
---- Ver1.10 Mod Start
----      AND (   papf.last_update_date >= gt_pre_process_date
----           OR papf.attribute23      >= gv_str_pre_process_date)
--      AND papf.creation_date >= gt_pre_process_date
---- Ver1.10 Mod End
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- �ٗp�֌W�i�ސE�ҁj�̒��o�J�[�\��
    --------------------------------------
    CURSOR wk_rel_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- �]�ƈ��ԍ�
        , TO_CHAR(ppos.date_start, cv_date_fmt)             AS date_start                 -- �J�n��
        , (CASE 
             WHEN xoedi.person_id IS NOT NULL THEN
               TO_CHAR(ppos.actual_termination_date, cv_date_fmt)
             ELSE 
               NULL
           END)                                             AS actual_termination_date    -- ���ёސE��
        , (CASE 
             WHEN (xoedi.person_id IS NOT NULL
                   AND  ppos.actual_termination_date IS NOT NULL) THEN
               cv_y
             ELSE 
               NULL
           END)                                             AS terminate_work_rel_flag    -- �ٗp�֌W�̏I��
        , (CASE 
             WHEN (xoedi.actual_termination_date IS NOT NULL
                   AND  ppos.actual_termination_date IS NULL) THEN
               cv_y
             ELSE 
               NULL
           END)                                             AS reverse_termination_flag   -- �ސE�̎��
        , (CASE 
             WHEN (xoedi.person_id IS NOT NULL
                   AND  ppos.actual_termination_date IS NOT NULL) THEN
               cv_act_cd_termination
-- Ver1.4 Add Start
             WHEN  xoedi_new.person_id IS NOT NULL THEN
               cv_act_cd_rehire
-- Ver1.4 Add End
             ELSE
               cv_act_cd_hire
           END)                                             AS action_code                -- �����R�[�h
        , ppos.period_of_service_id                         AS period_of_service_id       -- �A�Ə��ID
        , (CASE
             WHEN ppos.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- �V�K�o�^�t���O
      FROM
           per_all_people_f              papf      -- �]�ƈ��}�X�^
         , per_all_assignments_f         paaf      -- �A�T�C�����g�}�X�^
         , per_periods_of_service        ppos      -- �A�Ə��
         , xxcmm_oic_emp_diff_info       xoedi     -- OIC�Ј��������e�[�u��
-- Ver1.4 Add Start
         , xxcmm_oic_emp_diff_info       xoedi_new -- OIC�Ј��������e�[�u���y�V�K�z
-- Ver1.4 Add End
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id            = paaf.person_id
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.person_id            = xoedi.person_id(+)
      AND ppos.date_start           = xoedi.date_start(+)
-- Ver1.4 Add Start
      AND ppos.person_id            = xoedi_new.person_id(+)
-- Ver1.4 Add End
-- Ver1.18 Mod Start
--      AND ppos.last_update_date     >= gt_pre_process_date      
      AND (
                ppos.last_update_date >= gt_pre_process_date
            AND ppos.last_update_date <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
        , ppos.date_start ASC
    ;
--
    --------------------------------------
    -- ���[�U�[���i�V�K�j�̒��o�J�[�\��
    --------------------------------------
    CURSOR new_user_cur
    IS
      -- ���[�U�[�}�X�^�����݂���ꍇ
      SELECT
          fu.user_name                                      AS user_name                    -- ���[�U�[��
        , papf.employee_number                              AS employee_number              -- �]�ƈ��ԍ�
        , TO_CHAR(fu.start_date, cv_date_fmt)               AS start_date                   -- �J�n��
        , cv_y                                              AS generated_user_account_flag  -- �����σ��[�U�[�E�A�J�E���g
      FROM
          per_all_people_f     papf  -- �]�ƈ��}�X�^
        , fnd_user             fu    -- ���[�U�[�}�X�^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id     = fu.employee_id
-- Ver1.18 Mod Start
--      AND papf.creation_date >= gt_pre_process_date
--      AND fu.creation_date   >= gt_pre_process_date
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
          )
      AND (
                fu.creation_date   >= gt_pre_process_date
            AND fu.creation_date   <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      --
      UNION ALL
      -- ���[�U�[�}�X�^�����݂��Ȃ��ꍇ
      SELECT
          papf.employee_number                              AS user_name                    -- ���[�U�[��
        , papf.employee_number                              AS employee_number              -- �]�ƈ��ԍ�
        , TO_CHAR(gt_if_dest_date, cv_date_fmt)             AS start_date                   -- �J�n��
        , cv_n                                              AS generated_user_account_flag  -- �����σ��[�U�[�E�A�J�E���g
      FROM
          per_all_people_f     papf  -- �]�ƈ��}�X�^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND NOT EXISTS (
              SELECT
                  1 AS flag
              FROM
                  fnd_user  fu    -- ���[�U�[�}�X�^
              WHERE
                  fu.employee_id = papf.person_id
          )
-- Ver 1.2(E055) Mod Start
--      AND (papf.last_update_date >= gt_pre_process_date
--           OR
--           papf.attribute23 >= gv_str_pre_process_date
--           OR
--           EXISTS (
--               SELECT
--                   1 AS flag
--               FROM 
--                   per_all_assignments_f   paaf  -- �A�T�C�����g�}�X�^
--               WHERE
--                   paaf.person_id = papf.person_id
--               AND (paaf.last_update_date >= gt_pre_process_date
--                    OR
--                    paaf.ass_attribute19  >= gv_str_pre_process_date))
--          )
-- Ver1.18 Mod Start
--      AND papf.creation_date >= gt_pre_process_date
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
          )
-- Ver1.18 Mod Start
-- Ver 1.2(E055) Mod End
      --
      ORDER BY
          employee_number ASC
    ;
--
    --------------------------------------
    -- �ٗp�����̒��o�J�[�\��
    --------------------------------------
    CURSOR wk_terms_cur
    IS
      SELECT
          (paaf.assignment_number || cv_wk_terms_suffix)    AS assignment_number          -- �A�T�C�����g�ԍ�
        , papf.employee_number                              AS employee_number            -- �]�ƈ��ԍ�
-- Ver1.4 Mod Start
--        , TO_CHAR(papf.start_date, cv_date_fmt)             AS start_date                 -- �J�n��
        , TO_CHAR(ppos.date_start, cv_date_fmt)             AS start_date                 -- �J�n��
-- Ver1.4 Mod End
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               TO_CHAR(paaf.effective_start_date, cv_date_fmt)
             ELSE
               TO_CHAR(gt_if_dest_date, cv_date_fmt)  -- �A�g���t
           END)                                             AS effective_start_date       -- �L���J�n��
        , paaf.assignment_number                            AS assignment_name            -- �A�T�C�����g��
        , (cv_wt || paaf.assignment_id)                     AS source_system_id           -- �\�[�X�E�V�X�e��ID
        , (CASE
             WHEN xoedi_new.person_id IS NULL THEN
               cv_act_cd_hire
             WHEN xoedi.person_id IS NULL THEN
               cv_act_cd_rehire
             ELSE
               cv_act_cd_mng_chg
           END)                                             AS action_code                -- �����R�[�h
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               cv_n
             WHEN NVL(xoedi.sup_assignment_number, '@') <> NVL(paaf_sup.assignment_number, '@') THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS sup_chg_flag               -- �㒷�ύX�t���O
      FROM
          per_all_people_f            papf      -- �]�ƈ��}�X�^
        , per_all_assignments_f       paaf      -- �A�T�C�����g�}�X�^
        , per_periods_of_service      ppos      -- �A�Ə��
        , xxcmm_oic_emp_diff_info     xoedi_new -- OIC�Ј��������e�[�u���y�V�K�z
        , xxcmm_oic_emp_diff_info     xoedi     -- OIC�Ј��������e�[�u��
        , (SELECT
               paaf_s.person_id           AS person_id           -- �lID
             , paaf_s.assignment_number   AS assignment_number   -- �A�T�C�����g�ԍ�
           FROM
               per_all_assignments_f    paaf_s  -- �A�T�C�����g�}�X�^(�㒷)
             , per_periods_of_service   ppos_s  -- �A�Ə��(�㒷)
           WHERE
               paaf_s.period_of_service_id = ppos_s.period_of_service_id
           AND ppos_s.actual_termination_date IS NULL
          )                           paaf_sup  -- �A�T�C�����g�}�X�^(�㒷)
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id = paaf.person_id
      AND paaf.effective_start_date = 
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f   paaf2  -- �A�T�C�����g�}�X�^
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.person_id            = xoedi_new.person_id(+)
      AND ppos.person_id            = xoedi.person_id(+)
      AND ppos.date_start           = xoedi.date_start(+)
      AND paaf.supervisor_id        = paaf_sup.person_id(+)
      AND (   ppos.actual_termination_date IS NULL
           OR xoedi.person_id IS NULL)
-- Ver1.18 Mod Start
--      AND (   paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date)
      AND (   
              (     paaf.last_update_date >= gt_pre_process_date
                AND paaf.last_update_date <  gt_cur_process_date
              )
           OR (
                    paaf.ass_attribute19  >= gv_str_pre_process_date
                AND paaf.ass_attribute19  <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    --------------------------------------
    -- �A�T�C�����g�̒��o�J�[�\��
    --------------------------------------
    CURSOR ass_cur
    IS
      SELECT
          paaf.assignment_number                            AS assignment_number          -- �A�T�C�����g�ԍ�
        , (paaf.assignment_number || cv_wk_terms_suffix)    AS work_terms_number          -- �Ζ������ԍ�
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               TO_CHAR(paaf.effective_start_date, cv_date_fmt)
             ELSE
               TO_CHAR(gt_if_dest_date, cv_date_fmt)  -- �A�g���t
           END)                                             AS effective_start_date       -- �L���J�n��
        , paaf.assignment_type                              AS assignment_type            -- �A�T�C�����g�E�^�C�v
        , pjd.segment3                                      AS job_code                   -- ��E�R�[�h
        , (CASE
             WHEN gcc.code_combination_id IS NOT NULL THEN
               (gcc.segment1               || cv_hyphen ||
                gcc.segment2               || cv_hyphen ||
                gt_prf_val_def_account_cd  || cv_hyphen ||
                gt_prf_val_def_sub_acct_cd || cv_hyphen ||
                gcc.segment5               || cv_hyphen ||
                gcc.segment6               || cv_hyphen ||
                gcc.segment7               || cv_hyphen ||
                gcc.segment8
               )
             ELSE
               NULL
           END)                                             AS default_expense_account    -- �f�t�H���g��p����
        , (CASE
             WHEN
               (SELECT
                    COUNT(1)  AS cnt
                FROM 
                    per_all_assignments_f   paaf_staff  -- �A�T�C�����g�}�X�^(����)
                  , per_periods_of_service  ppos_staff  -- �A�Ə��(����)
                WHERE 
                    paaf_staff.supervisor_id        = paaf.person_id
                AND paaf_staff.period_of_service_id = ppos_staff.period_of_service_id
                AND ppos_staff.actual_termination_date IS NULL
               ) > 0 THEN 
               cv_y
             ELSE
               NULL
           END)                                             AS manager_flag               -- �}�l�[�W��
        , hla.location_code                                 AS location_code              -- ���Ə��R�[�h
        , papf.employee_number                              AS employee_number            -- �]�ƈ��ԍ�
-- Ver1.4 Mod Start
--        , TO_CHAR(papf.start_date, cv_date_fmt)             AS start_date                 -- �J�n��
        , TO_CHAR(ppos.date_start, cv_date_fmt)             AS start_date                 -- �J�n��
-- Ver1.4 Mod End
        , paaf.primary_flag                                 AS primary_flag               -- �v���C�}���E�t���O
        , paaf.ass_attribute1                               AS ass_attribute1             -- �ٓ����R�R�[�h
        , paaf.ass_attribute2                               AS ass_attribute2             -- ���ߓ�
        , paaf.ass_attribute3                               AS ass_attribute3             -- �Ζ��n���_�R�[�h(�V)
        , paaf.ass_attribute4                               AS ass_attribute4             -- �Ζ��n���_�R�[�h(��)
        , paaf.ass_attribute5                               AS ass_attribute5             -- ���_�R�[�h(�V)
        , paaf.ass_attribute6                               AS ass_attribute6             -- ���_�R�[�h(��)
        , paaf.ass_attribute7                               AS ass_attribute7             -- �K�p�J�����Ԑ��R�[�h(�V)
        , paaf.ass_attribute8                               AS ass_attribute8             -- �K�p�J����(�V)
        , paaf.ass_attribute9                               AS ass_attribute9             -- �K�p�J�����Ԑ��R�[�h(��)
        , paaf.ass_attribute10                              AS ass_attribute10            -- �K�p�J����(��)
        , paaf.ass_attribute11                              AS ass_attribute11            -- �E�ʕ����R�[�h(�V)
        , paaf.ass_attribute12                              AS ass_attribute12            -- �E�ʕ����R�[�h(��)
        , paaf.ass_attribute13                              AS ass_attribute13            -- ���F�敪(�V)
        , paaf.ass_attribute14                              AS ass_attribute14            -- ���F�敪(��)
        , paaf.ass_attribute15                              AS ass_attribute15            -- ��s�敪(�V)
        , paaf.ass_attribute16                              AS ass_attribute16            -- ��s�敪(��)
        , paaf.ass_attribute17                              AS ass_attribute17            -- �����A�g�p���t(���̋@)
        , paaf.ass_attribute18                              AS ass_attribute18            -- �����A�g�p���t(���[)
        , paaf.assignment_id                                AS source_system_id           -- �\�[�X�E�V�X�e��ID
        , (CASE
             WHEN paaf.creation_date >= gt_pre_process_date THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS new_reg_flag               -- �V�K�o�^�t���O
        , (CASE
             WHEN xoedi_new.person_id IS NULL THEN
               cv_act_cd_hire
             WHEN xoedi.person_id IS NULL THEN
               cv_act_cd_rehire
             ELSE
               cv_act_cd_mng_chg
           END)                                             AS action_code                -- �����R�[�h
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               cv_n
             WHEN NVL(xoedi.sup_assignment_number, '@') <> NVL(paaf_sup.assignment_number, '@') THEN
               cv_y
             ELSE
               cv_n
           END)                                             AS sup_chg_flag               -- �㒷�ύX�t���O
      FROM
          per_all_people_f            papf      -- �]�ƈ��}�X�^
        , per_all_assignments_f       paaf      -- �A�T�C�����g�}�X�^
        , per_jobs                    pj        -- ��E�}�X�^
        , per_job_definitions         pjd       -- ��E��`�}�X�^
        , hr_locations_all            hla       -- ���Ə��}�X�^
        , gl_code_combinations        gcc       -- ����Ȗڑg����
        , per_periods_of_service      ppos      -- �A�Ə��
        , xxcmm_oic_emp_diff_info     xoedi_new -- OIC�Ј��������e�[�u���y�V�K�z
        , xxcmm_oic_emp_diff_info     xoedi     -- OIC�Ј��������e�[�u��
        , (SELECT
               paaf_s.person_id           AS person_id           -- �lID
             , paaf_s.assignment_number   AS assignment_number   -- �A�T�C�����g�ԍ�
           FROM
               per_all_assignments_f    paaf_s  -- �A�T�C�����g�}�X�^(�㒷)
             , per_periods_of_service   ppos_s  -- �A�Ə��(�㒷)
           WHERE
               paaf_s.period_of_service_id = ppos_s.period_of_service_id
           AND ppos_s.actual_termination_date IS NULL
          )                           paaf_sup  -- �A�T�C�����g�}�X�^(�㒷)
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
             (SELECT
                  MAX(papf2.effective_start_date)
              FROM
                  per_all_people_f  papf2 -- �]�ƈ��}�X�^
              WHERE
                  papf2.person_id = papf.person_id
             )
      AND papf.person_id = paaf.person_id
      AND paaf.effective_start_date = 
             (SELECT
                  MAX(paaf2.effective_start_date)
              FROM
                  per_all_assignments_f  paaf2  -- �A�T�C�����g�}�X�^
              WHERE
                  paaf2.person_id = paaf.person_id
             )
      AND paaf.job_id               = pj.job_id(+)
      AND pj.job_definition_id      = pjd.job_definition_id(+)
      AND paaf.default_code_comb_id = gcc.code_combination_id(+)
      AND paaf.location_id          = hla.location_id(+)
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.person_id            = xoedi_new.person_id(+)
      AND ppos.person_id            = xoedi.person_id(+)
      AND ppos.date_start           = xoedi.date_start(+)
      AND paaf.supervisor_id        = paaf_sup.person_id(+)
      AND (   ppos.actual_termination_date IS NULL
           OR xoedi.person_id IS NULL)
-- Ver1.18 Mod Start
--      AND (   paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date)
           
      AND (   
              (     paaf.last_update_date >= gt_pre_process_date
                AND paaf.last_update_date <  gt_cur_process_date
              )
           OR (
                    paaf.ass_attribute19  >= gv_str_pre_process_date
                AND paaf.ass_attribute19  <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          paaf.assignment_number ASC
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_worker_rec       worker_cur%ROWTYPE;        -- �A�Ǝ҂̒��o�J�[�\�����R�[�h
    l_per_name_rec     per_name_cur%ROWTYPE;      -- �l���̒��o�J�[�\�����R�[�h
    l_per_legi_rec     per_legi_cur%ROWTYPE;      -- �l���ʎd�l�f�[�^�̒��o�J�[�\�����R�[�h
    l_per_email_rec    per_email_cur%ROWTYPE;     -- �lE���[���̒��o�J�[�\�����R�[�h
    l_wk_rel_rec       wk_rel_cur%ROWTYPE;        -- �ٗp�֌W�i�ސE�ҁj�̒��o�J�[�\�����R�[�h
    l_new_user_rec     new_user_cur%ROWTYPE;      -- ���[�U�[���i�V�K�j�̒��o�J�[�\�����R�[�h
    l_wk_terms_rec     wk_terms_cur%ROWTYPE;      -- �ٗp�����̒��o�J�[�\�����R�[�h
    l_ass_rec          ass_cur%ROWTYPE;           -- �A�T�C�����g�̒��o�J�[�\�����R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���[�J���ϐ��̏�����
    lv_wt_header_wrk   := cv_n;
    lv_wt_header_wrk2  := cv_n;
    lv_ass_header_wrk  := cv_n;
    lv_ass_header_wrk2 := cv_n;
--
    -- ==============================================================
    -- �A�Ǝ҂̒��o(A-2-1)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN worker_cur;
    <<output_worker_loop>>
    LOOP
      --
      FETCH worker_cur INTO l_worker_rec;
      EXIT WHEN worker_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_wk_cnt := gn_get_wk_cnt + 1;
      --
      -- ==============================================================
      -- �A�Ǝ҂̃t�@�C���o��(A-2-2)
      -- ==============================================================
      -- �w�b�_�[�s�̍쐬�i����̂݁j
      IF ( gn_get_wk_cnt = 1 ) THEN
        --
        BEGIN
          -- �w�b�_�[�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                           , cv_worker_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- �f�[�^�s�̍쐬
      lv_file_data := cv_meta_merge;                                                 --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_worker;                      --  2 : Worker
      lv_file_data := lv_file_data || cv_pipe || cv_per_persons_dff;                 --  3 : FLEX:PER_PERSONS_DFF�i�R���e�L�X�g�j
      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.employee_number;       --  4 : PersonNumber�i�l�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.effective_start_date;  --  5 : EffectiveStartDate�i�L���J�n���j
      lv_file_data := lv_file_data || cv_pipe || cv_act_cd_hire;                     --  6 : ActionCode�i�����R�[�h�j
      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.start_date;            --  7 : StartDate�i�J�n���j
                                                                                     --      (��PER_PERSONS_DFF=ITO_SALES_USE_ITEM)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute1
                                 , l_worker_rec.new_reg_flag
-- Ver1.3 Mod Start
--                                 , cv_nvl_n
                                 , cv_nvl_v
-- Ver1.3 Mod End
                                 );                                                  --  8 : point�i�|�C���g)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute2
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  --  9 : qualificationCode�i���i�R�[�h)

      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.attribute3;            -- 10 : employeeClass�i�]�ƈ��敪)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute4
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 11 : vendorCode�i�d����R�[�h)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute5
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 12 : representativeCarrier�i�^���Ǝ�)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute6
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 13 : vendorsSiteCode�i�d����T�C�g�R�[�h)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute7
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 14 : qualificationCodeNew�i���i�R�[�h�i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute8
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 15 : qualificationNameNew�i���i���i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute9
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 16 : qualificationCodeOld�i���i�R�[�h�i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute10
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 17 : qualificationNameOld�i���i���i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute11
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 18 : positionCodeNew�i�E�ʃR�[�h�i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute12
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 19 : positionNameNew�i�E�ʖ��i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute13
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 20 : positionCodeOld�i�E�ʃR�[�h�i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute14
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 21 : positionNameOld�i�E�ʖ��i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute15
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 22 : jobCodeNew�i�E���R�[�h�i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute16
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 23 : jobNameNew�i�E�����i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute17
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 24 : jobCodeOld�i�E���R�[�h�i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute18
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 25 : jobNameOld�i�E�����i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute19
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 26 : occupationalCodeNew�i�E��R�[�h�i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute20
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 27 : occupationalNameNew�i�E�햼�i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute21
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 28 : occupationalCodeOld�i�E��R�[�h�i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute22
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 29 : occupationalNameOld�i�E�햼�i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute28
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 30 : DepartmentChild�i��������)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute29
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 31 : referrenceDepartment�i�Ɖ�͈�)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.attribute30
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 32 : approvalDepartment�i���F�Ҕ͈�)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.pay_group_lookup_code
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 33 : paymentMethod�i�x�����@)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_worker_rec.inquiry_base_code_p
                                 , l_worker_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                  -- 34 : inquiryBaseCodeP�i�⍇���S�����_�R�[�h)
                                                                                     --      (��PER_PERSONS_DFF=ITO_SALES_USE_ITEM)
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                             -- 35 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      lv_file_data := lv_file_data || cv_pipe || l_worker_rec.person_id;             -- 36 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
      --
      BEGIN
        -- �f�[�^�s�̃t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , lv_file_data
                         );
        -- �o�͌����J�E���g�A�b�v
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_worker_loop;
--
    -- ���o������1���ȏ゠��ꍇ
    IF ( gn_get_wk_cnt > 0 ) THEN
      BEGIN
        -- ��s���t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE worker_cur;
--
--
    -- ==============================================================
    -- �l���̒��o(A-2-3)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN per_name_cur;
    <<output_per_name_loop>>
    LOOP
      --
      FETCH per_name_cur INTO l_per_name_rec;
      EXIT WHEN per_name_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_per_name_cnt := gn_get_per_name_cnt + 1;
      --
      -- ==============================================================
      -- �l���̃t�@�C���o��(A-2-4)
      -- ==============================================================
      -- �w�b�_�[�s�̍쐬�i����̂݁j
      IF ( gn_get_per_name_cnt = 1 ) THEN
        --
        BEGIN
          -- �w�b�_�[�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                           , cv_per_name_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- �f�[�^�s�̍쐬
      lv_file_data := cv_meta_merge;                                                      --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_per_name;                         --  2 : PersonName
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.employee_number;          --  3 : PersonNumber�i�l�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || cv_global;                               --  4 : NameType�i���O�^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.effective_start_date;     --  5 : EffectiveStartDate�i�L���J�n���j
      lv_file_data := lv_file_data || cv_pipe || cv_jp;                                   --  6 : LegislationCode�i���ʎd�l�R�[�h�j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_per_name_rec.first_name
                                 , l_per_name_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       --  7 : FirstName�i���j
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.last_name;                --  8 : LastName�i���j
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.per_information18;        --  9 : NameInformation1�i���O���1�j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_per_name_rec.per_information19
                                 , l_per_name_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 10 : NameInformation2�i���O���2�j
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 11 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      lv_file_data := lv_file_data || cv_pipe || l_per_name_rec.person_id;                -- 12 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
      --
      BEGIN
        -- �f�[�^�s�̃t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , lv_file_data
                         );
        -- �o�͌����J�E���g�A�b�v
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_per_name_loop;
    --
    -- ���o������1���ȏ゠��ꍇ
    IF ( gn_get_per_name_cnt > 0 ) THEN
      BEGIN
        -- ��s�}��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE per_name_cur;
--
--
    -- ==============================================================
    -- �l���ʎd�l�f�[�^�̒��o(A-2-5)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN per_legi_cur;
    <<output_per_legi_loop>>
    LOOP
      --
      FETCH per_legi_cur INTO l_per_legi_rec;
      EXIT WHEN per_legi_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_per_legi_cnt := gn_get_per_legi_cnt + 1;
      --
      -- ==============================================================
      -- �l���ʎd�l�f�[�^�̃t�@�C���o��(A-2-6)
      -- ==============================================================
      -- �w�b�_�[�s�̍쐬�i����̂݁j
      IF ( gn_get_per_legi_cnt = 1 ) THEN
        --
        BEGIN
          -- �w�b�_�[�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                           , cv_per_legi_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- �f�[�^�s�̍쐬
      lv_file_data := cv_meta_merge;                                                      -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_per_legi;                         -- 2 : PersonLegislativeData
      lv_file_data := lv_file_data || cv_pipe || l_per_legi_rec.employee_number;          -- 3 : PersonNumber�i�l�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || cv_jp;                                   -- 4 : LegislationCode�i���ʎd�l�R�[�h�j
      lv_file_data := lv_file_data || cv_pipe || l_per_legi_rec.effective_start_date;     -- 5 : EffectiveStartDate�i�L���J�n���j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_per_legi_rec.sex
                                 , l_per_legi_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 6 : Sex�i���ʁj
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 7 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      lv_file_data := lv_file_data || cv_pipe || l_per_legi_rec.person_id;                -- 8 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
      --
      BEGIN
        -- �f�[�^�s�̃t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , lv_file_data
                         );
        -- �o�͌����J�E���g�A�b�v
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_per_legi_loop;
--
    -- ���o������1���ȏ゠��ꍇ
    IF ( gn_get_per_legi_cnt > 0 ) THEN
      BEGIN
        -- ��s���t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE per_legi_cur;
--
--
    -- ==============================================================
    -- �lE���[���̒��o(A-2-7)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN per_email_cur;
    <<output_per_email_loop>>
    LOOP
      --
      FETCH per_email_cur INTO l_per_email_rec;
      EXIT WHEN per_email_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_per_email_cnt := gn_get_per_email_cnt + 1;
      --
      -- ==============================================================
      -- �lE���[���̃t�@�C���o��(A-2-8)
      -- ==============================================================
      -- �w�b�_�[�s�̍쐬�i����̂݁j
      IF ( gn_get_per_email_cnt = 1 ) THEN
        --
        BEGIN
          -- �w�b�_�[�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                           , cv_per_email_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- �f�[�^�s�̍쐬
      lv_file_data := cv_meta_merge;                                                      -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_per_email;                        -- 2 : PersonEmail
      lv_file_data := lv_file_data || cv_pipe || l_per_email_rec.email_address;           -- 3 : EmailAddress�iE���[���E�A�h���X�j
      lv_file_data := lv_file_data || cv_pipe || cv_w1;                                   -- 4 : EmailType�iE���[���E�^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || l_per_email_rec.employee_number;         -- 5 : PersonNumber�i�l�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || l_per_email_rec.effective_start_date;    -- 6 : DateFrom�i���t: ���j
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 7 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      lv_file_data := lv_file_data || cv_pipe || l_per_email_rec.person_id;               -- 8 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
      --
      BEGIN
        -- �f�[�^�s�̃t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , lv_file_data
                         );
        -- �o�͌����J�E���g�A�b�v
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_per_email_loop;
--
    -- ���o������1���ȏ゠��ꍇ
    IF ( gn_get_per_email_cnt > 0 ) THEN
      BEGIN
        -- ��s���t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE per_email_cur;
--
--
    -- ==============================================================
    -- �ٗp�֌W�i�ސE�ҁj�̒��o(A-2-9)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN wk_rel_cur;
    <<output_wk_rel_loop>>
    LOOP
      --
      FETCH wk_rel_cur INTO l_wk_rel_rec;
      EXIT WHEN wk_rel_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_wk_rel_cnt := gn_get_wk_rel_cnt + 1;
      --
      -- ==============================================================
      -- �ٗp�֌W�i�ސE�ҁj�̃t�@�C���o��(A-2-10)
      -- ==============================================================
      -- �w�b�_�[�s�̍쐬�i����̂݁j
      IF ( gn_get_wk_rel_cnt = 1 ) THEN
        --
        BEGIN
          -- �w�b�_�[�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                           , cv_wk_rel_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- �f�[�^�s�̍쐬
      lv_file_data := cv_meta_merge;                                                      --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_wk_rel;                           --  2 : WorkRelationship
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel_rec.employee_number;            --  3 : PersonNumber�i�l�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || cv_wk_type_e;                            --  4 : WorkerType�i�A�Ǝ҃^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel_rec.date_start;                 --  5 : DateStart�i�J�n���j
      lv_file_data := lv_file_data || cv_pipe || cv_sales_le;                             --  6 : LegalEmployerName�i�ٗp��j
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  7 : PrimaryFlag�i�v���C�}���ٗp�j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_wk_rel_rec.actual_termination_date
                                 , l_wk_rel_rec.new_reg_flag
                                 , cv_nvl_d
                                 );                                                       --  8 : ActualTerminationDate�i���ёސE���j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_wk_rel_rec.terminate_work_rel_flag
                                 , l_wk_rel_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       --  9 : TerminateWorkRelationshipFlag�i�ٗp�֌W�̏I���j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_wk_rel_rec.reverse_termination_flag
                                 , l_wk_rel_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 10 : ReverseTerminationFlag�i�ސE�̎���j
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel_rec.action_code;                -- 11 : ActionCode�i�����R�[�h�j
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 12 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel_rec.period_of_service_id;       -- 13 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
      --
      BEGIN
        -- �f�[�^�s�̃t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , lv_file_data
                         );
        -- �o�͌����J�E���g�A�b�v
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_wk_rel_loop;
--
    -- ���o������1���ȏ゠��ꍇ
    IF ( gn_get_wk_rel_cnt > 0 ) THEN
      BEGIN
        -- ��s���t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE wk_rel_cur;
--
--
    -- ==============================================================
    -- ���[�U�[���i�V�K�j�̒��o(A-2-11)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN new_user_cur;
    <<output_new_user_loop>>
    LOOP
      --
      FETCH new_user_cur INTO l_new_user_rec;
      EXIT WHEN new_user_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_new_user_cnt      := gn_get_new_user_cnt + 1;
-- Ver1.15 Del Start
--      gn_get_new_user_paas_cnt := gn_get_new_user_paas_cnt + 1;
-- Ver1.15 Del End
      --
      -- ==============================================================
      -- ���[�U�[���i�V�K�j�̃t�@�C���o��(A-2-12)
      -- ==============================================================
      -- �w�b�_�[�s�̍쐬�i����̂݁j
      IF ( gn_get_new_user_cnt = 1 ) THEN
        --
        BEGIN
          -- �w�b�_�[�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                           , cv_per_user_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- �f�[�^�s�̍쐬
      lv_file_data := cv_meta_merge;                                                          -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_per_user;                             -- 2 : PersonUserInformation
      lv_file_data := lv_file_data || cv_pipe || l_new_user_rec.user_name;                    -- 3 : UserName�i���[�U�[���j
      lv_file_data := lv_file_data || cv_pipe || l_new_user_rec.employee_number;              -- 4 : PersonNumber�i�l�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || l_new_user_rec.start_date;                   -- 5 : StartDate�i�J�n���j
      lv_file_data := lv_file_data || cv_pipe || l_new_user_rec.generated_user_account_flag;  -- 6 : GeneratedUserAccountFlag�i�����σ��[�U�[�E�A�J�E���g�j
      lv_file_data := lv_file_data || cv_pipe || cv_n;                                        -- 7 : SendCredentialsEmailFlag�i���i�ؖ�E���[���̑��M�j
      --
      BEGIN
        -- �f�[�^�s�̃t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , lv_file_data
                         );
        -- �o�͌����J�E���g�A�b�v
        gn_out_wk_cnt := gn_out_wk_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
      --
-- Ver1.15 Del Start
--      -- ==============================================================
--      -- PaaS�����p�̐V�K���[�U�[���̃t�@�C���o��(A-2-13)
--      -- ==============================================================
--      IF (l_new_user_rec.generated_user_account_flag = cv_y) THEN
--        -- �����σ��[�U�[�E�A�J�E���g��Y�̏ꍇ�i���[�U�[�}�X�^�����݂���ꍇ�j
--        -- �f�[�^�s�̍쐬
--        lv_file_data := xxccp_oiccommon_pkg.to_csv_string( l_new_user_rec.user_name , cv_space );  -- 1 : ���[�U�[��
--        lv_file_data := lv_file_data || cv_comma ||
--                        xxccp_oiccommon_pkg.to_csv_string( gt_prf_val_password      , cv_space );  -- 2 : �����p�X���[�h
--        --
--        BEGIN
--          -- �f�[�^�s�̃t�@�C���o��
--          UTL_FILE.PUT_LINE( gf_new_usr_file_handle  -- PaaS�����p�̐V�K���[�U�[���t�@�C��
--                           , lv_file_data
--                           );
--          -- �o�͌����J�E���g�A�b�v
--          gn_out_p_new_user_cnt := gn_out_p_new_user_cnt + 1;
--        EXCEPTION
--          WHEN OTHERS THEN
--            RAISE global_fileout_expt;
--        END;
--      ELSE
--        -- �����σ��[�U�[�E�A�J�E���g��N�̏ꍇ�i���[�U�[�}�X�^�����݂��Ȃ��ꍇ�j
--        -- �X�L�b�v�������J�E���g�A�b�v
--        gn_warn_cnt := gn_warn_cnt + 1;
--      END IF;
-- Ver1.15 Del End
    --
    END LOOP output_new_user_loop;
--
    -- ���o������1���ȏ゠��ꍇ
    IF ( gn_get_new_user_cnt > 0 ) THEN
      BEGIN
        -- ��s���t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE new_user_cur;
--
--
    -- ==============================================================
    -- �ٗp�����̒��o(A-2-14)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN wk_terms_cur;
    <<output_wk_terms_loop>>
    LOOP
      --
      FETCH wk_terms_cur INTO l_wk_terms_rec;
      EXIT WHEN wk_terms_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_wk_terms_cnt := gn_get_wk_terms_cnt + 1;
      --
      -- ==============================================================
      -- �ٗp�����̃t�@�C���o��(A-2-15)
      -- ==============================================================
      -- �w�b�_�[�s�̍쐬
      BEGIN
        IF ( l_wk_terms_rec.sup_chg_flag = cv_n AND lv_wt_header_wrk = cv_n ) THEN
          -- �㒷�ύX�Ȃ��A���w�b�_�[�s�����쐬�̏ꍇ
          -- �w�b�_�[�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                           , cv_wk_terms_header
                           );
          --
          -- �w�b�_�[�s�쐬��
          lv_wt_header_wrk := cv_y;
        ELSIF ( l_wk_terms_rec.sup_chg_flag = cv_y AND lv_wt_header_wrk2 = cv_n ) THEN
          -- �㒷�ύX����A���w�b�_�[�s�����쐬�̏ꍇ
          -- �w�b�_�[�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
                           , cv_wk_terms_header
                           );
          --
          -- �w�b�_�[�s�쐬��
          lv_wt_header_wrk2 := cv_y;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
      --
      -- �f�[�^�s�̍쐬
      lv_file_data := cv_meta_merge;                                                      --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_wk_terms;                         --  2 : WorkTerms
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.assignment_number;        --  3 : AssignmentNumber�i�A�T�C�����g�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.employee_number;          --  4 : PersonNumber�i�l�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || cv_wk_type_e;                            --  5 : WorkerType�i�A�Ǝ҃^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.start_date;               --  6 : DateStart�i�J�n���j
      lv_file_data := lv_file_data || cv_pipe || cv_sales_le;                             --  7 : LegalEmployerName�i�ٗp�喼�j
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  8 : EffectiveLatestChange�i�L���ŏI�ύX�j
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.effective_start_date;     --  9 : EffectiveStartDate�i�L���J�n���j
      lv_file_data := lv_file_data || cv_pipe || cv_seq_1;                                -- 10 : EffectiveSequence�i�L�������j
      lv_file_data := lv_file_data || cv_pipe || cv_ass_status_act;                       -- 11 : AssignmentStatusTypeCode�i�A�T�C�����g�E�X�e�[�^�X�E�^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || cv_ass_type_et;                          -- 12 : AssignmentType�i�A�T�C�����g�E�^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.assignment_name;          -- 13 : AssignmentName�i�A�T�C�����g���j
      lv_file_data := lv_file_data || cv_pipe || cv_sys_per_type_emp;                     -- 14 : SystemPersonType�i�V�X�e��Person�^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || cv_sales_bu;                             -- 15 : BusinessUnitShortCode�i�r�W�l�X�E���j�b�g�j
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.action_code;              -- 16 : ActionCode�i�����R�[�h�j
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    -- 17 : PrimaryWorkTermsFlag�i�ٗp�֌W�̃v���C�}���ٗp�����j
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 18 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      lv_file_data := lv_file_data || cv_pipe || l_wk_terms_rec.source_system_id;         -- 19 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
      --
      BEGIN
        IF ( l_wk_terms_rec.sup_chg_flag = cv_n ) THEN
          -- �㒷�ύX�Ȃ�
          -- �f�[�^�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                           , lv_file_data
                           );
          -- �o�͌����J�E���g�A�b�v
          gn_out_wk_cnt := gn_out_wk_cnt + 1;
        ELSE
          -- �㒷�ύX����
          -- �f�[�^�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
                           , lv_file_data
                           );
          -- �o�͌����J�E���g�A�b�v
          gn_out_wk2_cnt := gn_out_wk2_cnt + 1;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_wk_terms_loop;
--
    BEGIN
      -- �w�b�_�[�s���o�͂��Ă���ꍇ
      IF ( lv_wt_header_wrk = cv_y ) THEN
        -- ��s���t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                         , ''
                         );
      END IF;
      --
      IF ( lv_wt_header_wrk2 = cv_y ) THEN
        -- ��s���t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
                         , ''
                         );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_fileout_expt;
    END;
--
    -- �J�[�\���N���[�Y
    CLOSE wk_terms_cur;
--
--
    -- ==============================================================
    -- �A�T�C�����g���̒��o(A-2-16)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN ass_cur;
    <<output_ass_loop>>
    LOOP
      --
      FETCH ass_cur INTO l_ass_rec;
      EXIT WHEN ass_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_ass_cnt := gn_get_ass_cnt + 1;
      --
      -- ==============================================================
      -- �A�T�C�����g���̃t�@�C���o��(A-2-17)
      -- ==============================================================
      -- �w�b�_�[�s�̍쐬
      BEGIN
        IF ( l_ass_rec.sup_chg_flag = cv_n AND lv_ass_header_wrk = cv_n ) THEN
          -- �㒷�ύX�Ȃ��A���w�b�_�[�s�����쐬�̏ꍇ
          -- �w�b�_�[�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                           , cv_ass_header
                           );
          --
          -- �w�b�_�[�s�쐬��
          lv_ass_header_wrk := cv_y;
        ELSIF ( l_ass_rec.sup_chg_flag = cv_y AND lv_ass_header_wrk2 = cv_n ) THEN
          -- �㒷�ύX����A���w�b�_�[�s�����쐬�̏ꍇ
          -- �w�b�_�[�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
                           , cv_ass_header
                           );
          --
          -- �w�b�_�[�s�쐬��
          lv_ass_header_wrk2 := cv_y;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
      --
      -- �f�[�^�s�̍쐬
      lv_file_data :=                            cv_meta_merge;                           --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_assignment;                       --  2 : Assignment
      lv_file_data := lv_file_data || cv_pipe || cv_per_asg_df;                           --  3 : FLEX:PER_ASG_DF�i�R���e�L�X�g�j
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.assignment_number;             --  4 : AssignmentNumber�i�A�T�C�����g�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.work_terms_number;             --  5 : WorkTermsNumber�i�Ζ������ԍ��j
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  6 : EffectiveLatestChange�i�L���ŏI�ύX�j
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.effective_start_date;          --  7 : EffectiveStartDate�i�L���J�n���j
      lv_file_data := lv_file_data || cv_pipe || cv_seq_1;                                --  8 : EffectiveSequence�i�L�������j
      lv_file_data := lv_file_data || cv_pipe || cv_per_type_employee;                    --  9 : PersonTypeCode�iPerson�^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || cv_ass_status_act;                       -- 10 : AssignmentStatusTypeCode�i�A�T�C�����g�E�X�e�[�^�X�E�^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.assignment_type;               -- 11 : AssignmentType�i�A�T�C�����g�E�^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || cv_sys_per_type_emp;                     -- 12 : SystemPersonType�i�V�X�e��Person�^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.assignment_number;             -- 13 : AssignmentName�i�A�T�C�����g���j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.job_code
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 14 : JobCode�i�W���u�E�R�[�h�j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.default_expense_account
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 15 : DefaultExpenseAccount�i�f�t�H���g��p����j
      lv_file_data := lv_file_data || cv_pipe || cv_sales_bu;                             -- 16 : BusinessUnitShortCode�i�r�W�l�X�E���j�b�g�j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.manager_flag
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 17 : ManagerFlag�i�}�l�[�W���j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.location_code
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 18 : LocationCode�i���Ə��R�[�h�j
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.employee_number;               -- 19 : PersonNumber�i�l�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.action_code;                   -- 20 : ActionCode�i�����R�[�h�j
      lv_file_data := lv_file_data || cv_pipe || cv_wk_type_e;                            -- 21 : WorkerType�i�A�Ǝ҃^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || NULL;                                    -- 22 : DepartmentName�i����j
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.start_date;                    -- 23 : DateStart�i�J�n���j
      lv_file_data := lv_file_data || cv_pipe || cv_sales_le;                             -- 24 : LegalEmployerName�i�ٗp�喼�j
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.primary_flag;                  -- 25 : PrimaryAssignmentFlag�i�ٗp�֌W�̃v���C�}���E�A�T�C�����g�j
                                                                                          --      (��PER_ASG_DF=ITO_SALES_USE_ITEM)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute1
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 26 : transferReasonCode�i�ٓ����R�R�[�h)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute2
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 27 : announceDate�i���ߓ�)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute3
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 28 : workLocDepartmentNew�i�Ζ��n���_�R�[�h�i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute4
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 29 : workLocDepartmentOld�i�Ζ��n���_�R�[�h�i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute5
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 30 : departmentNew�i���_�R�[�h�i�V�j�j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute6
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 31 : departmentOld�i���_�R�[�h�i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute7
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 32 : appWorkTimeCodeNew�i�K�p�J�����Ԑ��R�[�h�i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute8
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 33 : appWorkTimeNameNew�i�K�p�J�����i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute9
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 34 : appWorkTimeCodeOld�i�K�p�J�����Ԑ��R�[�h�i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute10
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 35 : appWorkTimeNameOld�i�K�p�J�����i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute11
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 36 : positionSortCodeNew�i�E�ʕ����R�[�h�i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute12
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 37 : positionSortCodeOld�i�E�ʕ����R�[�h�i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute13
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 38 : approvalClassNew�i���F�敪�i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute14
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 39 : approvalClassOld�i���F�敪�i���j�j
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute15
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 40 : alternateClassNew�i��s�敪�i�V�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute16
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 41 : alternateClassOld�i��s�敪�i���j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute17
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 42 : transferDateVend�i�����A�g�p���t�i���̋@�j)
      lv_file_data := lv_file_data || cv_pipe || 
                      nvl_for_hdl( l_ass_rec.ass_attribute18
                                 , l_ass_rec.new_reg_flag
                                 , cv_nvl_v
                                 );                                                       -- 43 : transferDateRep�i�����A�g�p���t�i���[�j)
                                                                                          --      (��PER_ASG_DF=ITO_SALES_USE_ITEM)
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 44 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      lv_file_data := lv_file_data || cv_pipe || l_ass_rec.source_system_id;              -- 45 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
      --
      BEGIN
        IF ( l_ass_rec.sup_chg_flag = cv_n ) THEN
          -- �㒷�ύX�Ȃ�
          -- �f�[�^�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk_file_handle  -- �]�ƈ����A�g�f�[�^�t�@�C��
                           , lv_file_data
                           );
          -- �o�͌����J�E���g�A�b�v
          gn_out_wk_cnt := gn_out_wk_cnt + 1;
        ELSE
          -- �㒷�ύX����
          -- �f�[�^�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
                           , lv_file_data
                           );
          -- �o�͌����J�E���g�A�b�v
          gn_out_wk2_cnt := gn_out_wk2_cnt + 1;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_ass_loop;
--
    BEGIN
      -- �w�b�_�[�s���o�͂��Ă���ꍇ
      IF ( lv_ass_header_wrk2 = cv_y ) THEN
        -- ��s���t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
                         , ''
                         );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_fileout_expt;
    END;
--
    -- �J�[�\���N���[�Y
    CLOSE ass_cur;
--
--
  EXCEPTION
    -- *** �t�@�C���o�͎���O�n���h�� ***
    WHEN global_fileout_expt THEN
      -- �J�[�\���N���[�Y
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                     , iv_name         => cv_file_write_err_msg     -- ���b�Z�[�W���F�t�@�C���������݃G���[���b�Z�[�W
                     , iv_token_name1  => cv_tkn_sqlerrm            -- �g�[�N����1�FSQLERRM
                     , iv_token_value1 => SQLERRM                   -- �g�[�N���l1�FSQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( worker_cur%ISOPEN )    THEN CLOSE worker_cur;    END IF;
      IF ( per_name_cur%ISOPEN )  THEN CLOSE per_name_cur;  END IF;
      IF ( per_legi_cur%ISOPEN )  THEN CLOSE per_legi_cur;  END IF;
      IF ( per_email_cur%ISOPEN ) THEN CLOSE per_email_cur; END IF;
      IF ( wk_rel_cur%ISOPEN )    THEN CLOSE wk_rel_cur;    END IF;
      IF ( new_user_cur%ISOPEN )  THEN CLOSE new_user_cur;  END IF;
      IF ( wk_terms_cur%ISOPEN )  THEN CLOSE wk_terms_cur;  END IF;
      IF ( ass_cur%ISOPEN )       THEN CLOSE ass_cur;       END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_worker;
--
--
  /**********************************************************************************
   * Procedure Name   : output_user
   * Description      : ���[�U�[���̒��o�E�t�@�C���o�͏���(A-3)
   ***********************************************************************************/
  PROCEDURE output_user(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_user';       -- �v���O������
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
    ------------------------------------
    --�w�b�_�[�s(User)
    ------------------------------------
    cv_user_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'          -- 1 : METADATA
      || cv_pipe || 'User'              -- 2 : User
      || cv_pipe || 'PersonNumber'      -- 3 : PersonNumber�i�l�ԍ��j
      || cv_pipe || 'Username'          -- 4 : Username�i���[�U�[���j
      || cv_pipe || 'Suspended'         -- 5 : Suspended�i��~�j
    ;
-- Ver1.2(E055) Add Start
    --
    ------------------------------------
    --�w�b�_�[�s(User2)
    ------------------------------------
    cv_user2_header  CONSTANT VARCHAR2(3000) :=
                    'METADATA'               -- 1 : METADATA
      || cv_pipe || 'User'                   -- 2 : User
      || cv_pipe || 'PersonNumber'           -- 3 : PersonNumber�i�l�ԍ��j
      || cv_pipe || 'CredentialsEmailSent'   -- 4 : CredentialsEmailSent�i���i�ؖ�E���[�����M�ρj
    ;
-- Ver1.2(E055) Add End
--
    -- *** ���[�J���ϐ� ***
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- �o�͓��e
-- Ver1.17 Add Start
    lv_new_emp_flag      VARCHAR2(1);                        -- �V���Ј��t���O
-- Ver1.17 Add End
--
    -- *** ���[�J���E�J�[�\�� ***
    --------------------------------------
    -- ���[�U�[�̒��o�J�[�\��
    --------------------------------------
    CURSOR user_cur
    IS
      SELECT
          papf.employee_number          AS employee_number      -- �]�ƈ��ԍ�
        , fu.user_name                  AS user_name            -- ���[�U�[��
        , (CASE
             WHEN fu.end_date <= gt_if_dest_date THEN
               cv_y
             ELSE
               cv_n
           END)                         AS suspended            -- ��~
-- Ver1.17 Add Start
        , papf.person_id                AS person_id            -- �lID
-- Ver1.17 Add End
      FROM
          per_all_people_f  papf  -- �]�ƈ��}�X�^
        , fnd_user          fu    -- ���[�U�[�}�X�^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id       = fu.employee_id
      AND NOT EXISTS
              (SELECT
                   1  AS flag
               FROM
                   xxcmm_oic_emp_diff_info   xoedi -- OIC�Ј��������e�[�u��
               WHERE
                   xoedi.person_id  = papf.person_id
               AND xoedi.user_name IS NULL
              )
-- Ver1.18 Mod Start
--      AND (   fu.last_update_date >= gt_pre_process_date
--           OR fu.end_date         = gt_if_dest_date)
      AND (   
            (     fu.last_update_date >= gt_pre_process_date
              AND fu.last_update_date <  gt_cur_process_date
            )
           OR     fu.end_date         = gt_if_dest_date
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
-- Ver1.2(E055) Add Start
    --
    --------------------------------------
    -- ���[�U�[�i�폜�j�̒��o�J�[�\��
    --------------------------------------
    CURSOR user2_cur
    IS
      SELECT
          papf.employee_number          AS employee_number      -- �]�ƈ��ԍ�
      FROM
          per_all_people_f         papf  -- �]�ƈ��}�X�^
-- Ver1.13 Add Start
        , po_vendors               pv    -- �d����}�X�^
        , po_vendor_sites_all      pvsa  -- �d����T�C�g�}�X�^
-- Ver1.13 Add End
        , per_all_assignments_f    paaf  -- �A�T�C�������g�}�X�^
        , per_periods_of_service   ppos  -- �A�Ə��
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
-- Ver1.13 Add Start
      AND papf.person_id                = pv.employee_id(+)
      AND pv.vendor_type_lookup_code(+) = cv_vd_type_employee
      AND pv.vendor_id                  = pvsa.vendor_id(+)
      AND pvsa.vendor_site_code(+)      = cv_site_code_comp
-- Ver1.13 Add End
      AND papf.person_id            = paaf.person_id
      AND paaf.effective_start_date =
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f  paaf2  -- �A�T�C�����g�}�X�^
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND NOT EXISTS (
              SELECT
                  1 AS flag
              FROM
                  fnd_user  fu    -- ���[�U�[�}�X�^
              WHERE
                  fu.employee_id = papf.person_id
          )
-- Ver1.5 Mod Start
--      AND papf.creation_date < gt_pre_process_date
--      AND (   papf.last_update_date >= gt_pre_process_date
--           OR papf.attribute23      >= gv_str_pre_process_date
--           OR paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date
--           OR ppos.last_update_date >= gt_pre_process_date
--          )
      AND (
            (    papf.creation_date >= gt_pre_process_date
             AND (   paaf.supervisor_id IS NOT NULL
                  OR actual_termination_date IS NOT NULL
                 )
            ) OR (
                 papf.creation_date < gt_pre_process_date
             AND (   papf.last_update_date >= gt_pre_process_date
                  OR papf.attribute23      >= gv_str_pre_process_date
-- Ver1.13 Add Start
                  OR pvsa.last_update_date >= gt_pre_process_date
-- Ver1.13 Add End
                  OR paaf.last_update_date >= gt_pre_process_date
                  OR paaf.ass_attribute19  >= gv_str_pre_process_date
                  OR ppos.last_update_date >= gt_pre_process_date
                 )
            )
          )
-- Ver1.5 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
--
    --------------------------------------
    -- �V���Ј����̒��o�J�[�\��
    --------------------------------------
    CURSOR new_emp_cur (
             in_person_id IN NUMBER
    )
    IS
      SELECT
          fu.user_name                                      AS user_name                    -- ���[�U�[��
        , papf.employee_number                              AS employee_number              -- �]�ƈ��ԍ�
        , TO_CHAR(fu.start_date, cv_date_fmt)               AS start_date                   -- �J�n��
        , cv_y                                              AS generated_user_account_flag  -- �����σ��[�U�[�E�A�J�E���g
        , papf.person_id                                    AS person_id                    -- �lID
      FROM
          per_all_people_f     papf  -- �]�ƈ��}�X�^
        , fnd_user             fu    -- ���[�U�[�}�X�^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id     = fu.employee_id
-- Ver1.18 Mod Start
--      AND papf.creation_date >= gt_pre_process_date
--      AND fu.creation_date   >= gt_pre_process_date
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
           )
      AND ( 
                fu.creation_date   >= gt_pre_process_date
            AND fu.creation_date   <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      AND papf.person_id = in_person_id
      ORDER BY
          employee_number ASC
    ;
-- Ver1.17 Add End
--
    -- *** ���[�J���E���R�[�h ***
    l_user_rec     user_cur%ROWTYPE;    -- ���[�U�[�̒��o�J�[�\�����R�[�h
-- Ver1.2(E055) Add Start
    l_user2_rec    user2_cur%ROWTYPE;   -- ���[�U�[�i�폜�j�̒��o�J�[�\�����R�[�h
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
    l_new_emp_rec  new_emp_cur%ROWTYPE; -- �V���Ј����̒��o�J�[�\�����R�[�h
-- Ver1.17 Add End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- ���[�U�[���̒��o(A-3-1)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN user_cur;
    <<output_user_loop>>
    LOOP
      --
      FETCH user_cur INTO l_user_rec;
      EXIT WHEN user_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_user_cnt := gn_get_user_cnt + 1;
      --
-- Ver1.17 Del Start
--      -- ==============================================================
--      -- ���[�U�[���̃t�@�C���o��(A-3-2)
--      -- ==============================================================
      -- �w�b�_�[�s�̍쐬�i����̂݁j
--      IF ( gn_get_user_cnt = 1 ) THEN
--        --
--        BEGIN
--          -- �w�b�_�[�s�̃t�@�C���o��
--          UTL_FILE.PUT_LINE( gf_usr_file_handle  -- ���[�U�[���A�g�f�[�^�t�@�C��
--                           , cv_user_header
--                           );
--        EXCEPTION
--          WHEN OTHERS THEN
--            RAISE global_fileout_expt;
--        END;
--      END IF;
-- Ver1.17 Del End
      --
      -- �f�[�^�s�̍쐬
      lv_file_data := cv_meta_merge;                                                      -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_user;                             -- 2 : User
      lv_file_data := lv_file_data || cv_pipe || l_user_rec.employee_number;              -- 3 : PersonNumber�i�l�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || l_user_rec.user_name;                    -- 4 : Username�i���[�U�[���j
      lv_file_data := lv_file_data || cv_pipe || l_user_rec.suspended;                    -- 5 : Suspended�i��~�j
      --
-- Ver1.17 Mod Start
--      BEGIN
--        -- �f�[�^�s�̃t�@�C���o��
--        UTL_FILE.PUT_LINE( gf_usr_file_handle  -- ���[�U�[���A�g�f�[�^�t�@�C��
--                         , lv_file_data
--                         );
--        -- �o�͌����J�E���g�A�b�v
--        gn_out_user_cnt := gn_out_user_cnt + 1;
      -- ==============================================================
      -- �V���Ј����̒��o(A-3-2)
      -- ==============================================================
-- Ver1.20 Add Start
      lv_new_emp_flag := cv_n;
-- Ver1.20 Add End

      -- �J�[�\���I�[�v��
      OPEN new_emp_cur (
             l_user_rec.person_id
           );
      <<output_new_emp_loop>>
      LOOP
        --
        FETCH new_emp_cur INTO l_new_emp_rec;
        EXIT WHEN new_emp_cur%NOTFOUND;
        --
          lv_new_emp_flag := cv_y;
          -- ��v����ꍇY�t���O�����Ă�
      END LOOP output_new_emp_loop;
--
      -- �J�[�\���N���[�Y
      CLOSE new_emp_cur;
--
      -- ==============================================================
      -- ���[�U�[���̃t�@�C���o��(A-3-3)
      -- ==============================================================
      BEGIN
        IF ( lv_new_emp_flag = cv_y ) THEN
          -- �f�[�^�s�̃t�@�C���o�͂��Ȃ�
          gn_get_user_cnt := gn_get_user_cnt - 1;
        ELSE
          -- �w�b�_�[�s�̍쐬�i2��ڈȍ~�͏o�͂��Ȃ��j
          IF ( gn_get_user_cnt = 1 ) THEN
            --
            BEGIN
              -- �w�b�_�[�s�̃t�@�C���o��
              UTL_FILE.PUT_LINE( gf_usr_file_handle  -- ���[�U�[���A�g�f�[�^�t�@�C��
                               , cv_user_header
                               );
            EXCEPTION
              WHEN OTHERS THEN
                RAISE global_fileout_expt;
            END;
          END IF;         
          -- �f�[�^�s�̃t�@�C���o�͂���
          UTL_FILE.PUT_LINE( gf_usr_file_handle  -- ���[�U�[���A�g�f�[�^�t�@�C��
                           , lv_file_data
                           );
          -- �o�͌����J�E���g�A�b�v
          gn_out_user_cnt := gn_out_user_cnt + 1;
        END IF;
-- Ver1.17 Mod End
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_user_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE user_cur;
--
-- Ver1.14 Del Start
---- Ver1.2(E055) Add Start
--    -- ==============================================================
--    -- ���[�U�[���i�폜�j�̒��o(A-3-3)
--    -- ==============================================================
--    -- �J�[�\���I�[�v��
--    OPEN user2_cur;
--    <<output_user2_loop>>
--    LOOP
--      --
--      FETCH user2_cur INTO l_user2_rec;
--      EXIT WHEN user2_cur%NOTFOUND;
--      --
--      -- ���o�����J�E���g�A�b�v
--      gn_get_user2_cnt := gn_get_user2_cnt + 1;
--      --
--      -- ==============================================================
--      -- ���[�U�[���i�폜�j�̃t�@�C���o��(A-3-4)
--      -- ==============================================================
--      -- �w�b�_�[�s�̍쐬�i����̂݁j
--      IF ( gn_get_user2_cnt = 1 ) THEN
--        --
--        BEGIN
--          -- �w�b�_�[�s�̃t�@�C���o��
--          UTL_FILE.PUT_LINE( gf_usr2_file_handle  -- ���[�U�[���i�폜�j�A�g�f�[�^�t�@�C��
--                           , cv_user2_header
--                           );
--        EXCEPTION
--          WHEN OTHERS THEN
--            RAISE global_fileout_expt;
--        END;
--      END IF;
--      --
--      -- �f�[�^�s�̍쐬
--      lv_file_data := cv_meta_delete;                                                     -- 1 : METADATA
--      lv_file_data := lv_file_data || cv_pipe || cv_cls_user;                             -- 2 : User
--      lv_file_data := lv_file_data || cv_pipe || l_user2_rec.employee_number;             -- 3 : PersonNumber�i�l�ԍ��j
--      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    -- 4 : CredentialsEmailSent�i���i�ؖ�E���[�����M�ρj
--      --
--      BEGIN
--        -- �f�[�^�s�̃t�@�C���o��
--        UTL_FILE.PUT_LINE( gf_usr2_file_handle  -- ���[�U�[���i�폜�j�A�g�f�[�^�t�@�C��
--                         , lv_file_data
--                         );
--        -- �o�͌����J�E���g�A�b�v
--        gn_out_user2_cnt := gn_out_user2_cnt + 1;
--      EXCEPTION
--        WHEN OTHERS THEN
--          RAISE global_fileout_expt;
--      END;
--    --
--    END LOOP output_user2_loop;
----
--    -- �J�[�\���N���[�Y
--    CLOSE user2_cur;
---- Ver1.2(E055) Add End
-- Ver1.14 Del End
--
  EXCEPTION
    -- *** �t�@�C���o�͎���O�n���h�� ***
    WHEN global_fileout_expt THEN
      -- �J�[�\���N���[�Y
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- �J�[�\���N���[�Y
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
      END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- �J�[�\���N���[�Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                     , iv_name         => cv_file_write_err_msg     -- ���b�Z�[�W���F�t�@�C���������݃G���[���b�Z�[�W
                     , iv_token_name1  => cv_tkn_sqlerrm            -- �g�[�N����1�FSQLERRM
                     , iv_token_value1 => SQLERRM                   -- �g�[�N���l1�FSQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- �J�[�\���N���[�Y
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
      END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- �J�[�\���N���[�Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- �J�[�\���N���[�Y
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
     END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- �J�[�\���N���[�Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- �J�[�\���N���[�Y
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
      END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- �J�[�\���N���[�Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( user_cur%ISOPEN ) THEN
        CLOSE user_cur;
      END IF;
-- Ver1.2(E055) Add Start
      -- �J�[�\���N���[�Y
      IF ( user2_cur%ISOPEN ) THEN
        CLOSE user2_cur;
      END IF;
-- Ver1.2(E055) Add End
-- Ver1.17 Add Start
      -- �J�[�\���N���[�Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_user;
--
--
  /**********************************************************************************
   * Procedure Name   : output_worker2
   * Description      : �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�̒��o�E�t�@�C���o�͏���(A-4)
   ***********************************************************************************/
  PROCEDURE output_worker2(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_worker2';       -- �v���O������
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
    ------------------------------------
    --�w�b�_�[�s(AssignmentSupervisor)
    ------------------------------------
    cv_ass_sup_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'AssignmentSupervisor'             --  2 : AssignmentSupervisor
      || cv_pipe || 'AssignmentNumber'                 --  3 : AssignmentNumber�i�A�T�C�����g�ԍ��j
      || cv_pipe || 'ManagerType'                      --  4 : ManagerType�i�^�C�v�j
      || cv_pipe || 'ManagerAssignmentNumber'          --  5 : ManagerAssignmentNumber�i�㒷�A�T�C�����g�ԍ��j
      || cv_pipe || 'EffectiveStartDate'               --  6 : EffectiveStartDate�i�L���J�n���j
      || cv_pipe || 'PrimaryFlag'                      --  7 : PrimaryFlag�i�v���C�}���j
      || cv_pipe || 'NewManagerType'                   --  8 : NewManagerType�i�V�K�㒷�^�C�v�j
      || cv_pipe || 'NewManagerAssignmentNumber'       --  9 : NewManagerAssignmentNumber�i�V�K�㒷�A�T�C�����g�ԍ��j
    ;
    --
    ------------------------------------
    --�w�b�_�[�s(WorkRelationship)
    ------------------------------------
    cv_wk_rel_header   CONSTANT VARCHAR2(3000) :=
                    'METADATA'                         --  1 : METADATA
      || cv_pipe || 'WorkRelationship'                 --  2 : WorkRelationship
      || cv_pipe || 'PersonNumber'                     --  3 : PersonNumber�i�l�ԍ��j
      || cv_pipe || 'WorkerType'                       --  4 : WorkerType�i�A�Ǝ҃^�C�v�j
      || cv_pipe || 'DateStart'                        --  5 : DateStart�i�J�n���j
      || cv_pipe || 'LegalEmployerName'                --  6 : LegalEmployerName�i�ٗp��j
      || cv_pipe || 'PrimaryFlag'                      --  7 : PrimaryFlag�i�v���C�}���ٗp�j
      || cv_pipe || 'ActualTerminationDate'            --  8 : ActualTerminationDate�i���ёސE���j
      || cv_pipe || 'TerminateWorkRelationshipFlag'    --  9 : TerminateWorkRelationshipFlag�i�ٗp�֌W�̏I���j
      || cv_pipe || 'ReverseTerminationFlag'           -- 10 : ReverseTerminationFlag�i�ސE�̎���j
      || cv_pipe || 'ActionCode'                       -- 11 : ActionCode�i�����R�[�h�j
      || cv_pipe || 'SourceSystemOwner'                -- 12 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      || cv_pipe || 'SourceSystemId'                   -- 13 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
    ;
--
    -- *** ���[�J���ϐ� ***
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- �o�͓��e
--
    -- *** ���[�J���E�J�[�\�� ***
    --------------------------------------
    -- �A�T�C�����g�㒷�̒��o�J�[�\��
    --------------------------------------
    CURSOR ass_sup_cur
    IS
      SELECT
          (CASE
             WHEN (xoedi.sup_assignment_number IS NOT NULL
                   AND paaf_sup.assignment_number IS NULL) THEN
               cv_meta_delete
             ELSE
               cv_meta_merge
           END)                                             AS metadata                   -- METADATA
        , paaf.assignment_number                            AS assignment_number          -- �A�T�C�����g�ԍ�
        , (CASE
-- Ver1.6 Mod Start
--             WHEN (xoedi.sup_assignment_number IS NOT NULL
--                   AND paaf_sup.assignment_number IS NULL) THEN
             WHEN xoedi.sup_assignment_number IS NOT NULL THEN
-- Ver1.6 Mod End
               xoedi.sup_assignment_number
             ELSE 
               paaf_sup.assignment_number
           END)                                             AS sup_ass_number             -- �㒷�A�T�C�����g�ԍ�
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               TO_CHAR(paaf.effective_start_date, cv_date_fmt)
             ELSE
               TO_CHAR(gt_if_dest_date, cv_date_fmt)  -- �A�g���t
           END)                                             AS effective_start_date       -- �L���J�n��

        , (CASE
             WHEN (xoedi.sup_assignment_number IS NOT NULL
                   AND paaf_sup.assignment_number IS NOT NULL) THEN
               cv_sup_type_line_manager
             ELSE 
               NULL
           END)                                             AS new_sup_type               -- �V�K�㒷�^�C�v
        , (CASE
             WHEN (xoedi.sup_assignment_number IS NOT NULL
                   AND paaf_sup.assignment_number IS NOT NULL) THEN
               paaf_sup.assignment_number
             ELSE 
               NULL
           END)                                             AS new_sup_ass_number         -- �V�K�㒷�A�T�C�����g�ԍ�
      FROM
          per_all_people_f            papf  -- �]�ƈ��}�X�^
        , per_all_assignments_f       paaf  -- �A�T�C�����g�}�X�^
        , per_periods_of_service      ppos  -- �A�Ə��
        , xxcmm_oic_emp_diff_info     xoedi -- OIC�Ј��������e�[�u��
        , (SELECT
               paaf_s.person_id           AS person_id           -- �lID
             , paaf_s.assignment_number   AS assignment_number   -- �A�T�C�����g�ԍ�
           FROM
               per_all_assignments_f    paaf_s  -- �A�T�C�����g�}�X�^(�㒷)
             , per_periods_of_service   ppos_s  -- �A�Ə��(�㒷)
           WHERE
               paaf_s.period_of_service_id = ppos_s.period_of_service_id
           AND ppos_s.actual_termination_date IS NULL
          )                           paaf_sup  -- �A�T�C�����g�}�X�^(�㒷)
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id = paaf.person_id
      AND paaf.effective_start_date = 
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f  paaf2  -- �A�T�C�����g�}�X�^
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.person_id            = xoedi.person_id(+)
      AND ppos.date_start           = xoedi.date_start(+)
      AND paaf.supervisor_id        = paaf_sup.person_id(+)
      AND (   xoedi.sup_assignment_number IS NOT NULL
           OR paaf.supervisor_id IS NOT NULL)
-- Ver1.12 Add Start
      AND (   ppos.actual_termination_date IS NULL
           OR xoedi.person_id IS NULL)
-- Ver1.12 Add End
-- Ver1.18 Mod Start
--      AND (   paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date)
           
      AND (
              (     paaf.last_update_date >= gt_pre_process_date
                AND paaf.last_update_date <  gt_cur_process_date
              )
           OR (
                    paaf.ass_attribute19  >= gv_str_pre_process_date
                AND paaf.ass_attribute19  <  gv_str_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
        paaf.assignment_number ASC
    ;
--
    --------------------------------------
    -- �ٗp�֌W�i�V�K�̗p�ސE�ҁj�̒��o�J�[�\��
    --------------------------------------
    CURSOR wk_rel2_cur
    IS
      SELECT
          papf.employee_number                              AS employee_number            -- �]�ƈ��ԍ�
        , TO_CHAR(ppos.date_start, cv_date_fmt)             AS date_start                 -- �J�n��
        , TO_CHAR(ppos.actual_termination_date
                  , cv_date_fmt)                            AS actual_termination_date    -- ���ёސE��
        , ppos.period_of_service_id                         AS period_of_service_id       -- �A�Ə��ID
      FROM
          per_all_people_f              papf  -- �]�ƈ��}�X�^
        , per_all_assignments_f         paaf  -- �A�T�C�����g�}�X�^
        , per_periods_of_service        ppos  -- �A�Ə��
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f        papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id = paaf.person_id
      AND paaf.effective_start_date = 
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f   paaf2  -- �A�T�C�����g�}�X�^
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND ppos.actual_termination_date IS NOT NULL
      AND NOT EXISTS
              (SELECT
                   1  AS flag
               FROM
                   xxcmm_oic_emp_diff_info   xoedi -- OIC�Ј��������e�[�u��
               WHERE
                   xoedi.person_id  = ppos.person_id
               AND xoedi.date_start = ppos.date_start
              )
-- Ver1.18 Mod Start
--      AND ppos.last_update_date >= gt_pre_process_date
      AND (
                ppos.last_update_date >= gt_pre_process_date
            AND ppos.last_update_date <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_ass_sup_rec      ass_sup_cur%ROWTYPE;    -- �A�T�C�����g�㒷�̒��o�J�[�\�����R�[�h
    l_wk_rel2_rec      wk_rel2_cur%ROWTYPE;    -- �ٗp�֌W�i�V�K�̗p�ސE�ҁj�̒��o�J�[�\�����R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- �A�T�C�����g���i�㒷�j�̒��o(A-4-1)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN ass_sup_cur;
    <<output_ass_sup_loop>>
    LOOP
      --
      FETCH ass_sup_cur INTO l_ass_sup_rec;
      EXIT WHEN ass_sup_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_ass_sup_cnt := gn_get_ass_sup_cnt + 1;
      --
      -- ==============================================================
      -- �A�T�C�����g���i�㒷�j�̃t�@�C���o��(A-4-2)
      -- ==============================================================
      -- �w�b�_�[�s�̍쐬�i����̂݁j
      IF ( gn_get_ass_sup_cnt = 1 ) THEN
        --
        BEGIN
          -- �w�b�_�[�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
                           , cv_ass_sup_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- �f�[�^�s�̍쐬
      lv_file_data := l_ass_sup_rec.metadata;                                             -- 1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_ass_super;                        -- 2 : AssignmentSupervisor
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.assignment_number;         -- 3 : AssignmentNumber�i�A�T�C�����g�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || cv_sup_type_line_manager;                -- 4 : ManagerType�i�^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.sup_ass_number;            -- 5 : ManagerAssignmentNumber�i�㒷�A�T�C�����g�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.effective_start_date;      -- 6 : EffectiveStartDate�i�L���J�n���j
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    -- 7 : PrimaryFlag�i�v���C�}���j
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.new_sup_type;              -- 8 : NewManagerType�i�V�K�㒷�^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || l_ass_sup_rec.new_sup_ass_number;        -- 9 : NewManagerAssignmentNumber�i�V�K�㒷�A�T�C�����g�ԍ��j
      --
      BEGIN
        -- �f�[�^�s�̃t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
                         , lv_file_data
                         );
        -- �o�͌����J�E���g�A�b�v
        gn_out_wk2_cnt := gn_out_wk2_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_ass_sup_loop;
--
    -- ���o������1���ȏ゠��ꍇ
    IF ( gn_get_ass_sup_cnt > 0 ) THEN
      BEGIN
        -- ��s���t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
                         , ''
                         );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    END IF;
--
    -- �J�[�\���N���[�Y
    CLOSE ass_sup_cur;
--
--
    -- ==============================================================
    -- �ٗp�֌W�i�V�K�̗p�ސE�ҁj�̒��o(A-4-3)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN wk_rel2_cur;
    <<output_wk_rel2_loop>>
    LOOP
      --
      FETCH wk_rel2_cur INTO l_wk_rel2_rec;
      EXIT WHEN wk_rel2_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_wk_rel2_cnt := gn_get_wk_rel2_cnt + 1;
      --
      -- ==============================================================
      -- �ٗp�֌W�i�V�K�̗p�ސE�ҁj�̃t�@�C���o��(A-4-4)
      -- ==============================================================
      -- �w�b�_�[�s�̍쐬�i����̂݁j
      IF ( gn_get_wk_rel2_cnt = 1 ) THEN
        --
        BEGIN
          -- �w�b�_�[�s�̃t�@�C���o��
          UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
                           , cv_wk_rel_header
                           );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      END IF;
      --
      -- �f�[�^�s�̍쐬
      lv_file_data := cv_meta_merge;                                                      --  1 : METADATA
      lv_file_data := lv_file_data || cv_pipe || cv_cls_wk_rel;                           --  2 : WorkRelationship
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel2_rec.employee_number;           --  3 : PersonNumber�i�l�ԍ��j
      lv_file_data := lv_file_data || cv_pipe || cv_wk_type_e;                            --  4 : WorkerType�i�A�Ǝ҃^�C�v�j
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel2_rec.date_start;                --  5 : DateStart�i�J�n���j
      lv_file_data := lv_file_data || cv_pipe || cv_sales_le;                             --  6 : LegalEmployerName�i�ٗp��j
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  7 : PrimaryFlag�i�v���C�}���ٗp�j
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel2_rec.actual_termination_date;   --  8 : ActualTerminationDate�i���ёސE���j
      lv_file_data := lv_file_data || cv_pipe || cv_y;                                    --  9 : TerminateWorkRelationshipFlag�i�ٗp�֌W�̏I���j
      lv_file_data := lv_file_data || cv_pipe || NULL;                                    -- 10 : ReverseTerminationFlag�i�ސE�̎���j
      lv_file_data := lv_file_data || cv_pipe || cv_act_cd_termination;                   -- 11 : ActionCode�i�����R�[�h�j
      lv_file_data := lv_file_data || cv_pipe || cv_ebs;                                  -- 12 : SourceSystemOwner�i�\�[�X�E�V�X�e�����L�ҁj
      lv_file_data := lv_file_data || cv_pipe || l_wk_rel2_rec.period_of_service_id;      -- 13 : SourceSystemId�i�\�[�X�E�V�X�e��ID�j
      --
      BEGIN
        -- �f�[�^�s�̃t�@�C���o��
        UTL_FILE.PUT_LINE( gf_wrk2_file_handle  -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
                         , lv_file_data
                         );
        -- �o�͌����J�E���g�A�b�v
        gn_out_wk2_cnt := gn_out_wk2_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_wk_rel2_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE wk_rel2_cur;
--
  EXCEPTION
    -- *** �t�@�C���o�͎���O�n���h�� ***
    WHEN global_fileout_expt THEN
      -- �J�[�\���N���[�Y
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                     , iv_name         => cv_file_write_err_msg     -- ���b�Z�[�W���F�t�@�C���������݃G���[���b�Z�[�W
                     , iv_token_name1  => cv_tkn_sqlerrm            -- �g�[�N����1�FSQLERRM
                     , iv_token_value1 => SQLERRM                   -- �g�[�N���l1�FSQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( ass_sup_cur%ISOPEN ) THEN
        CLOSE ass_sup_cur;
      END IF;
      --
      IF ( wk_rel2_cur%ISOPEN ) THEN
        CLOSE wk_rel2_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_worker2;
--
--
  /**********************************************************************************
   * Procedure Name   : output_emp_bank_acct
   * Description      : �]�ƈ��o��������̒��o�E�t�@�C���o�͏���(A-5)
   ***********************************************************************************/
  PROCEDURE output_emp_bank_acct(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_emp_bank_acct';       -- �v���O������
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- �o�͓��e
--
    -- *** ���[�J���E�J�[�\�� ***
    --------------------------------------
    -- �]�ƈ��o��������̒��o�J�[�\��
    --------------------------------------
    CURSOR bank_acc_cur
    IS
-- Ver1.21 Mod Start
--      SELECT
--          papf.employee_number          AS employee_number         -- �]�ƈ��ԍ�
--        , abb.bank_number               AS bank_number             -- ��s�ԍ�
--        , abb.bank_num                  AS bank_num                -- ��s�x�X�ԍ�
--        , abb.bank_name                 AS bank_name               -- ��s��
--        , abb.bank_branch_name          AS bank_branch_name        -- ��s�x�X��
--        , abaa.bank_account_type        AS bank_account_type       -- �������
--        , abaa.bank_account_num         AS bank_account_num        -- �����ԍ�
---- Ver1.1 Mod Start
----        , abb.country                   AS country                 -- ��
----        , abaa.currency_code            AS currency_code           -- �ʉ݃R�[�h
--        , NVL(abb.country, cv_jp)       AS country                 -- ��
---- Ver1.7 Mod Start
----        , NVL(abaa.currency_code, cv_yen) AS currency_code         -- �ʉ݃R�[�h
--        , cv_nvl_v                      AS currency_code           -- �ʉ݃R�[�h
---- Ver1.7 Mod End
---- Ver1.1 Mod End
--        , abaa.account_holder_name      AS account_holder_name     -- �������`�l
--        , abaa.account_holder_name_alt  AS account_holder_name_alt -- �������`�l�J�i
--        , (CASE
--             WHEN abaa.inactive_date <= gt_if_dest_date THEN
--               cv_y
--             ELSE
---- Ver1.9 Mod Start
----               NULL
--               cv_n
---- Ver1.9 Mod End
--           END)                         AS inactive_flag           -- ��A�N�e�B�u
--        , (CASE
--             WHEN ROW_NUMBER() OVER(
--                    PARTITION BY abb.bank_number
--                               , abb.bank_num
---- Ver1.11 Add Start
--                               , abb.bank_name
--                               , abb.bank_branch_name
---- Ver1.11 Add End
--                               , abaa.bank_account_type
--                               , abaa.bank_account_num
---- Ver1.1 Mod Start
----                               , abaa.currency_code
----                               , abb.country
--                               , NVL(abaa.currency_code, cv_yen)
--                               , NVL(abb.country, cv_jp)
---- Ver1.1 Mod End
--                    ORDER BY  abb.bank_number
--                            , abb.bank_num
---- Ver1.11 Add Start
--                            , abb.bank_name
--                            , abb.bank_branch_name
---- Ver1.11 Add End
--                            , abaa.bank_account_type
--                            , abaa.bank_account_num
---- Ver1.1 Mod Start
----                            , abaa.currency_code
----                            , abb.country
--                            , NVL(abaa.currency_code, cv_yen)
--                            , NVL(abb.country, cv_jp)
---- Ver1.1 Mod End
--                            , abaua.bank_account_uses_id
--                  ) = 1 THEN
--               cv_y
--             ELSE
--               cv_n
--           END)                         AS primary_flag             -- �v���C�}���t���O
--        , abaua.primary_flag            AS expense_primary_flag     -- �o��v���C�}���t���O
--      FROM
--          per_all_people_f           papf  -- �]�ƈ��}�X�^
--        , po_vendors                 pv    -- �d����}�X�^
--        , po_vendor_sites_all        pvsa  -- �d����T�C�g�}�X�^
--        , ap_bank_accounts_all       abaa  -- ��s�����}�X�^
--        , ap_bank_branches           abb   -- ��s�x�X�}�X�^
--        , ap_bank_account_uses_all   abaua -- ��s�����g�p�}�X�^ 
--      WHERE
--          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A4:�_�~�[�j
---- Ver1.9 Add Start
--      AND papf.attribute4 IS NULL    -- �d����R�[�h
--      AND papf.attribute5 IS NULL    -- �^���Ǝ�
---- Ver1.9 Add End
--      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
--                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
--      AND papf.effective_start_date = 
--              (SELECT
--                   MAX(papf2.effective_start_date)
--               FROM
--                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
--               WHERE
--                   papf2.person_id = papf.person_id
--              )
--      AND papf.person_id                 = pv.employee_id
--      AND pv.vendor_type_lookup_code     = cv_vd_type_employee
--      AND pv.vendor_id                   = pvsa.vendor_id
---- Ver1.2(E056) Add Start
--      AND pvsa.vendor_site_code          = cv_site_code_comp
---- Ver1.2(E056) Add End
--      AND pvsa.vendor_id                 = abaua.vendor_id
--      AND pvsa.vendor_site_id            = abaua.vendor_site_id
--      AND abaua.external_bank_account_id = abaa.bank_account_id
--      AND abaa.account_type              = cv_acct_type_sup
--      AND abaa.bank_branch_id            = abb.bank_branch_id
---- Ver1.18 Mod Start
----      AND (   abaua.creation_date   >= gt_pre_process_date
----           OR abaa.last_update_date >= gt_pre_process_date
----           OR abaa.inactive_date    =  gt_if_dest_date)
--      AND (
--               (      abaua.creation_date   >= gt_pre_process_date
--                  AND abaua.creation_date   <  gt_cur_process_date
--               )
--           OR  (
--                      abaa.last_update_date >= gt_pre_process_date
--                  AND abaa.last_update_date <  gt_cur_process_date
--               )
---- Ver1.19 Add Start
--           OR  (
--                      abb.last_update_date  >= gt_pre_process_date
--                  AND abb.last_update_date  <  gt_cur_process_date
--               )
---- Ver1.19 Add End
--           OR         abaa.inactive_date    =  gt_if_dest_date
--          )
---- Ver1.18 Mod End
--      ORDER BY
--          abb.bank_number
--        , abb.bank_num
---- Ver1.11 Add Start
--        , abb.bank_name
--        , abb.bank_branch_name
---- Ver1.11 Add End
--        , abaa.bank_account_type
--        , abaa.bank_account_num
---- Ver1.1 Mod Start
----        , abaa.currency_code
----        , abb.country
--        , NVL(abaa.currency_code, cv_yen)
--        , NVL(abb.country, cv_jp)
---- Ver1.1 Mod End
--        , abaua.bank_account_uses_id

      SELECT
          abset.employee_number          AS employee_number         -- 1.�]�ƈ��ԍ�
        , abset.bank_number              AS bank_number             -- 2.��s�ԍ�
        , abset.bank_num                 AS bank_num                -- 3.��s�x�X�ԍ�
        , abset.bank_name                AS bank_name               -- 4.��s��
        , abset.bank_branch_name         AS bank_branch_name        -- 5.��s�x�X��
        , abset.bank_account_type        AS bank_account_type       -- 6.�������
        , abset.bank_account_num         AS bank_account_num        -- 7.�����ԍ�
        , abset.country                  AS country                 -- 8.���R�[�h
        , abset.currency_code            AS currency_code           -- 9.�ʉ݃R�[�h
        , abset.account_holder_name      AS account_holder_name     -- 10.�������`�l
        , abset.account_holder_name_alt  AS account_holder_name_alt -- 11.�������`�l�J�i
        , abset.inactive_flag            AS inactive_flag           -- 12.��A�N�e�B�u
        , abset.primary_flag             AS primary_flag            -- 13.�v���C�}���t���O
        , abset.expense_primary_flag     AS expense_primary_flag    -- 14.�o��v���C�}���t���O
      FROM
          (
            SELECT
                papf.employee_number          AS employee_number         -- 1.�]�ƈ��ԍ�
              , abb.bank_number               AS bank_number             -- 2.��s�ԍ�
              , abb.bank_num                  AS bank_num                -- 3.��s�x�X�ԍ�
              , abb.bank_name                 AS bank_name               -- 4.��s��
              , abb.bank_branch_name          AS bank_branch_name        -- 5.��s�x�X��
              , abaa.bank_account_type        AS bank_account_type       -- 6.�������
              , abaa.bank_account_num         AS bank_account_num        -- 7.�����ԍ�
              , NVL(abb.country, cv_jp)       AS country                 -- 8.���R�[�h
              , cv_nvl_v                      AS currency_code           -- 9.�ʉ݃R�[�h
              , abaa.account_holder_name      AS account_holder_name     -- 10.�������`�l
              , abaa.account_holder_name_alt  AS account_holder_name_alt -- 11.�������`�l�J�i
              , (CASE
                   WHEN abaa.inactive_date <= gt_if_dest_date THEN
                     cv_y
                   ELSE
                     cv_n
                 END)                         AS inactive_flag           -- 12.��A�N�e�B�u
              , (CASE
                   WHEN ROW_NUMBER() OVER(
                          PARTITION BY abb.bank_number
                                     , abb.bank_num
                                     , abb.bank_name
                                     , abb.bank_branch_name
                                     , abaa.bank_account_type
                                     , abaa.bank_account_num
                                     , NVL(abaa.currency_code, cv_yen)
                                     , NVL(abb.country, cv_jp)
                          ORDER BY  abb.bank_number
                                  , abb.bank_num
                                  , abb.bank_name
                                  , abb.bank_branch_name
                                  , abaa.bank_account_type
                                  , abaa.bank_account_num
                                  , NVL(abaa.currency_code, cv_yen)
                                  , NVL(abb.country, cv_jp)
                                  , abaua.bank_account_uses_id
                        ) = 1 THEN
                     cv_y
                   ELSE
                     cv_n
                 END)                         AS primary_flag             -- 13.�v���C�}���t���O
              , abaua.primary_flag            AS expense_primary_flag     -- 14.�o��v���C�}���t���O
              , abaua.bank_account_uses_id    AS bank_account_uses_id     -- 15.�������[�U�[ID
              , abaua.creation_date           AS abaua_creation_date      -- 16.��s�����g�p�}�X�^�̍쐬���t
              , abaa.last_update_date         AS abaa_last_update_date    -- 17.��s�����}�X�^�̍ŏI�X�V��
              , abb.last_update_date          AS abb_last_update_date     -- 18.��s�x�X�}�X�^�̍ŏI�X�V��
              , abaa.inactive_date            AS abaa_inactive_date       -- 19.��s�����}�X�^�̖�����
            FROM
                per_all_people_f           papf  -- �]�ƈ��}�X�^
              , po_vendors                 pv    -- �d����}�X�^
              , po_vendor_sites_all        pvsa  -- �d����T�C�g�}�X�^
              , ap_bank_accounts_all       abaa  -- ��s�����}�X�^
              , ap_bank_branches           abb   -- ��s�x�X�}�X�^
              , ap_bank_account_uses_all   abaua -- ��s�����g�p�}�X�^ 
            WHERE
                papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A4:�_�~�[�j
            AND papf.attribute4 IS NULL    -- �d����R�[�h
            AND papf.attribute5 IS NULL    -- �^���Ǝ�
            AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                             cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
            AND papf.effective_start_date = 
                    (SELECT
                         MAX(papf2.effective_start_date)
                     FROM
                         per_all_people_f  papf2  -- �]�ƈ��}�X�^
                     WHERE
                         papf2.person_id = papf.person_id
                    )
            AND papf.person_id                 = pv.employee_id
            AND pv.vendor_type_lookup_code     = cv_vd_type_employee
            AND pv.vendor_id                   = pvsa.vendor_id
            AND pvsa.vendor_site_code          = cv_site_code_comp
            AND pvsa.vendor_id                 = abaua.vendor_id
            AND pvsa.vendor_site_id            = abaua.vendor_site_id
            AND abaua.external_bank_account_id = abaa.bank_account_id
            AND abaa.account_type              = cv_acct_type_sup
            AND abaa.bank_branch_id            = abb.bank_branch_id
          )  abset  -- ��s�����֘A�e�[�u��
      WHERE
          (
               (      abset.abaua_creation_date   >= gt_pre_process_date
                  AND abset.abaua_creation_date   <  gt_cur_process_date
               )
           OR  (
                      abset.abaa_last_update_date >= gt_pre_process_date
                  AND abset.abaa_last_update_date <  gt_cur_process_date
               )
           OR  (
                      abset.abb_last_update_date  >= gt_pre_process_date
                  AND abset.abb_last_update_date  <  gt_cur_process_date
               )
           OR         abset.abaa_inactive_date    =  gt_if_dest_date
          )
      ORDER BY
          abset.bank_number
        , abset.bank_num
        , abset.bank_name
        , abset.bank_branch_name
        , abset.bank_account_type
        , abset.bank_account_num
        , abset.currency_code
        , abset.country
        , abset.bank_account_uses_id
-- Ver1.21 Mod End
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_bank_acc_rec      bank_acc_cur%ROWTYPE;    -- �]�ƈ��o��������̒��o�J�[�\�����R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- �]�ƈ��o��������̒��o(A-5-1)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN bank_acc_cur;
    <<output_bank_acc_loop>>
    LOOP
      --
      FETCH bank_acc_cur INTO l_bank_acc_rec;
      EXIT WHEN bank_acc_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_bank_acc_cnt := gn_get_bank_acc_cnt + 1;
      --
      -- ==============================================================
      -- �]�ƈ��o��������̃t�@�C���o��(A-5-2)
      -- ==============================================================
      -- �f�[�^�s�̍쐬
      lv_file_data := xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.employee_number         , cv_space );  --  1 : �]�ƈ��ԍ�
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_number             , cv_space );  --  2 : ��s�ԍ�
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_num                , cv_space );  --  3 : ��s�x�X�ԍ�
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_name               , cv_space );  --  4 : ��s��
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_branch_name        , cv_space );  --  5 : ��s�x�X��
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_account_type       , cv_space );  --  6 : �������
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.bank_account_num        , cv_space );  --  7 : �����ԍ�
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.country                 , cv_space );  --  8 : ���R�[�h
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.currency_code           , cv_space );  --  9 : �ʉ݃R�[�h
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.account_holder_name     , cv_space );  -- 10 : �������`�l
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.account_holder_name_alt , cv_space );  -- 11 : �J�i�������`
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.inactive_flag           , cv_space );  -- 12 : ��A�N�e�B�u
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.primary_flag            , cv_space );  -- 13 : �v���C�}���t���O
      lv_file_data := lv_file_data || cv_comma ||
                      xxccp_oiccommon_pkg.to_csv_string( l_bank_acc_rec.expense_primary_flag    , cv_space );  -- 14 : �o��v���C�}���t���O
      --
      BEGIN
        -- �f�[�^�s�̃t�@�C���o��
        UTL_FILE.PUT_LINE( gf_emp_bnk_file_handle  -- PaaS�����p�̏]�ƈ��o��������t�@�C��
                         , lv_file_data
                         );
        -- �o�͌����J�E���g�A�b�v
        gn_out_p_bank_acct_cnt := gn_out_p_bank_acct_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_fileout_expt;
      END;
    --
    END LOOP output_bank_acc_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE bank_acc_cur;
--
  EXCEPTION
    -- *** �t�@�C���o�͎���O�n���h�� ***
    WHEN global_fileout_expt THEN
      -- �J�[�\���N���[�Y
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                     , iv_name         => cv_file_write_err_msg     -- ���b�Z�[�W���F�t�@�C���������݃G���[���b�Z�[�W
                     , iv_token_name1  => cv_tkn_sqlerrm            -- �g�[�N����1�FSQLERRM
                     , iv_token_value1 => SQLERRM                   -- �g�[�N���l1�FSQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( bank_acc_cur%ISOPEN ) THEN
        CLOSE bank_acc_cur;
      END IF;
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_emp_bank_acct;
--
--
  /**********************************************************************************
   * Procedure Name   : output_emp_info
   * Description      : �Ј��������̒��o�E�t�@�C���o�͏����iPaaS�����p�j(A-6)
   ***********************************************************************************/
  PROCEDURE output_emp_info(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_emp_info';       -- �v���O������
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
    lv_file_data         VARCHAR2(30000) DEFAULT NULL;       -- �o�͓��e
-- Ver1.17 Add Start
    lv_new_emp_flag      VARCHAR2(1);                        -- �V���Ј��t���O
-- Ver1.17 Add End
--
    -- *** ���[�J���E�J�[�\�� ***
    --------------------------------------
    -- �Ј��������̒��o�J�[�\��
    --------------------------------------
    CURSOR emp_info_cur
    IS
      SELECT
          fu.user_name                      AS user_name                    -- ���[�U�[��
        , papf.employee_number              AS employee_number              -- �]�ƈ��ԍ�
        , papf.person_id                    AS person_id                    -- �lID
        , papf.last_name                    AS last_name                    -- �J�i��
        , papf.first_name                   AS first_name                   -- �J�i��
        , papf.attribute28                  AS location_code                -- ���_�R�[�h
        , papf.attribute7                   AS license_code                 -- ���i�R�[�h(�V)
        , papf.attribute11                  AS job_post                     -- �E�ʃR�[�h(�V)
        , papf.attribute15                  AS job_duty                     -- �E���R�[�h(�V)
        , papf.attribute19                  AS job_type                     -- �E��R�[�h(�V)
        , xwhd.dpt1_cd                      AS dpt1_cd                      -- 1�K�w�ڕ���R�[�h
        , xwhd.dpt2_cd                      AS dpt2_cd                      -- 2�K�w�ڕ���R�[�h
        , xwhd.dpt3_cd                      AS dpt3_cd                      -- 3�K�w�ڕ���R�[�h
        , xwhd.dpt4_cd                      AS dpt4_cd                      -- 4�K�w�ڕ���R�[�h
        , xwhd.dpt5_cd                      AS dpt5_cd                      -- 5�K�w�ڕ���R�[�h
        , xwhd.dpt6_cd                      AS dpt6_cd                      -- 6�K�w�ڕ���R�[�h
        , paaf_sup.assignment_number        AS sup_assignment_number        -- �㒷�A�T�C�����g�ԍ�
        , ppos.date_start                   AS date_start                   -- �J�n��
        , ppos.actual_termination_date      AS actual_termination_date      -- �ސE��
        , (CASE
             WHEN (fu.user_id IS NULL OR
                   (xoedi.person_id IS NOT NULL AND xoedi.user_name IS NULL)) THEN
               cv_n
             WHEN xoedi.person_id IS NULL THEN
               cv_y
             ELSE
               (CASE
                  WHEN (   papf.last_name             <> xoedi.last_name
                        OR NVL(papf.first_name , '@') <> NVL(xoedi.first_name,    '@')
                        OR NVL(papf.attribute28, '@') <> NVL(xoedi.location_code, '@')
                        OR NVL(papf.attribute7,  '@') <> NVL(xoedi.license_code,  '@')
                        OR NVL(papf.attribute11, '@') <> NVL(xoedi.job_post,      '@')
                        OR NVL(papf.attribute15, '@') <> NVL(xoedi.job_duty,      '@')
                        OR NVL(papf.attribute19, '@') <> NVL(xoedi.job_type,      '@')
-- Ver1.16 Add Start
                        OR ppos.date_start            <> xoedi.date_start
-- Ver1.16 Add End
                       ) THEN
                    cv_y
                  ELSE
                    cv_n
                END)
           END)                             AS roll_change_flag             -- ���[���ύX�t���O
        , (CASE
             WHEN xoedi.person_id IS NULL THEN
               cv_y
             ELSE
               (CASE
                  WHEN (   NVL(xwhd.dpt1_cd, '@')                 <> NVL(xoedi.dpt1_cd,   '@')
                        OR NVL(xwhd.dpt2_cd, '@')                 <> NVL(xoedi.dpt2_cd,   '@')
                        OR NVL(xwhd.dpt3_cd, '@')                 <> NVL(xoedi.dpt3_cd,   '@')
                        OR NVL(xwhd.dpt4_cd, '@')                 <> NVL(xoedi.dpt4_cd,   '@')
                        OR NVL(xwhd.dpt5_cd, '@')                 <> NVL(xoedi.dpt5_cd,   '@')
                        OR NVL(xwhd.dpt6_cd, '@')                 <> NVL(xoedi.dpt6_cd,   '@')
                        OR NVL(paaf_sup.assignment_number,   '@') <> NVL(xoedi.sup_assignment_number,   '@')
                        OR ppos.date_start                        <> xoedi.date_start
                        OR NVL(ppos.actual_termination_date, gt_cur_process_date) <> NVL(xoedi.actual_termination_date, gt_cur_process_date)
                       ) THEN
                    cv_y 
                  ELSE
                    cv_n
                END)
           END)                             AS other_change_flag            -- ���̑��ύX�t���O
        , xoedi.person_id                   AS xoedi_person_id              -- �lID�i�Ј��������j
        , xoedi.last_name                   AS pre_last_name                -- �O��J�i��
        , xoedi.first_name                  AS pre_first_name               -- �O��J�i��
        , xoedi.location_code               AS pre_location_code            -- �O�񋒓_�R�[�h
        , xoedi.license_code                AS pre_license_code             -- �O�񎑊i�R�[�h
        , xoedi.job_post                    AS pre_job_post                 -- �O��E�ʃR�[�h
        , xoedi.job_duty                    AS pre_job_duty                 -- �O��E���R�[�h
        , xoedi.job_type                    AS pre_job_type                 -- �O��E��R�[�h
        , xoedi.dpt1_cd                     AS pre_dpt1_cd                  -- �O��1�K�w�ڕ���R�[�h
        , xoedi.dpt2_cd                     AS pre_dpt2_cd                  -- �O��2�K�w�ڕ���R�[�h
        , xoedi.dpt3_cd                     AS pre_dpt3_cd                  -- �O��3�K�w�ڕ���R�[�h
        , xoedi.dpt4_cd                     AS pre_dpt4_cd                  -- �O��4�K�w�ڕ���R�[�h
        , xoedi.dpt5_cd                     AS pre_dpt5_cd                  -- �O��5�K�w�ڕ���R�[�h
        , xoedi.dpt6_cd                     AS pre_dpt6_cd                  -- �O��6�K�w�ڕ���R�[�h
        , xoedi.sup_assignment_number       AS pre_sup_assignment_number    -- �O��㒷�A�T�C�����g�ԍ�
        , xoedi.date_start                  AS pre_date_start               -- �O��J�n��
        , xoedi.actual_termination_date     AS pre_actual_termination_date  -- �O��ސE��
      FROM
          xxcmm_oic_emp_diff_info  xoedi     -- OIC�Ј��������e�[�u��
        , fnd_user                 fu        -- ���[�U�[�}�X�^
        , per_all_people_f         papf      -- �]�ƈ��}�X�^
        , (SELECT
               xwhd_sub.cur_dpt_cd          AS cur_dpt_cd               -- �ŉ��w����R�[�h
             , xwhd_sub.dpt1_cd             AS dpt1_cd                  -- �P�K�w�ڕ���R�[�h
             , xwhd_sub.dpt2_cd             AS dpt2_cd                  -- �Q�K�w�ڕ���R�[�h
             , xwhd_sub.dpt3_cd             AS dpt3_cd                  -- �R�K�w�ڕ���R�[�h
             , xwhd_sub.dpt4_cd             AS dpt4_cd                  -- �S�K�w�ڕ���R�[�h
             , xwhd_sub.dpt5_cd             AS dpt5_cd                  -- �T�K�w�ڕ���R�[�h
             , xwhd_sub.dpt6_cd             AS dpt6_cd                  -- �U�K�w�ڕ���R�[�h
             , ROW_NUMBER() OVER(
                 PARTITION BY xwhd_sub.cur_dpt_cd
                 ORDER BY xwhd_sub.cur_dpt_cd
               )                            AS row_num                  -- �s�ԍ��i�ŉ��w����R�[�h�P�ʁj
           FROM
               xxcmm_wk_hiera_dept xwhd_sub  -- ����K�w���[�N
           WHERE
               xwhd_sub.process_kbn = cv_proc_type_dept
          )                        xwhd      -- ����K�w���[�N
        , per_all_assignments_f    paaf      -- �A�T�C�������g�}�X�^
        , (SELECT
               paaf_s.person_id             AS person_id                -- �lID
              ,paaf_s.assignment_number     AS assignment_number        -- �A�T�C�����g�ԍ�
           FROM
               per_all_assignments_f    paaf_s  -- �A�T�C�����g�}�X�^(�㒷)
              ,per_periods_of_service   ppos_s  -- �A�Ə��(�㒷)
           WHERE
               paaf_s.period_of_service_id = ppos_s.period_of_service_id
           AND ppos_s.actual_termination_date IS NULL
          )                           paaf_sup  -- �A�T�C�����g�}�X�^(�㒷)
        , per_periods_of_service      ppos      -- �A�Ə��
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.person_id = fu.employee_id(+)
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f       papf2  -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.attribute28          = xwhd.cur_dpt_cd(+)
      AND xwhd.row_num(+)           = 1
      AND papf.person_id            = paaf.person_id
      AND paaf.effective_start_date =
              (SELECT
                   MAX(paaf2.effective_start_date)
               FROM
                   per_all_assignments_f  paaf2  -- �A�T�C�����g�}�X�^
               WHERE
                   paaf2.person_id = paaf.person_id
              )
      AND paaf.period_of_service_id = ppos.period_of_service_id
      AND paaf.supervisor_id        = paaf_sup.person_id(+)
      AND papf.employee_number      = xoedi.employee_number(+)
-- Ver1.18 Mod Start
--      AND (   papf.last_update_date >= gt_pre_process_date
--           OR papf.attribute23      >= gv_str_pre_process_date
--           OR paaf.last_update_date >= gt_pre_process_date
--           OR paaf.ass_attribute19  >= gv_str_pre_process_date
--           OR ppos.last_update_date >= gt_pre_process_date
--          )
      AND (   
              (     papf.last_update_date >= gt_pre_process_date
                AND papf.last_update_date <  gt_cur_process_date
            )
           OR (
                    papf.attribute23 >= gv_str_pre_process_date
                AND papf.attribute23 <  gv_str_cur_process_date
              )
           OR (
                    paaf.last_update_date >= gt_pre_process_date
                AND paaf.last_update_date <  gt_cur_process_date
              )
           OR (
                    paaf.ass_attribute19 >= gv_str_pre_process_date
                AND paaf.ass_attribute19 <  gv_str_cur_process_date
              )
           OR (
                    ppos.last_update_date >= gt_pre_process_date
                AND ppos.last_update_date <  gt_cur_process_date
              )
          )
-- Ver1.18 Mod End
      ORDER BY
          papf.employee_number ASC
      FOR UPDATE OF xoedi.person_id NOWAIT
    ;
--
-- Ver1.17 Add Start
    --------------------------------------
    -- �V���Ј����̒��o�J�[�\��
    --------------------------------------
    CURSOR new_emp_cur (
             in_person_id IN NUMBER
    )
    IS
      SELECT
          fu.user_name                                      AS user_name                    -- ���[�U�[��
        , papf.employee_number                              AS employee_number              -- �]�ƈ��ԍ�
        , TO_CHAR(fu.start_date, cv_date_fmt)               AS start_date                   -- �J�n��
        , cv_y                                              AS generated_user_account_flag  -- �����σ��[�U�[�E�A�J�E���g
        , papf.person_id                                    AS person_id                    -- �lID
      FROM
          per_all_people_f     papf  -- �]�ƈ��}�X�^
        , fnd_user             fu    -- ���[�U�[�}�X�^
      WHERE
          papf.attribute3 IN (cv_emp_kbn_internal, cv_emp_kbn_external , cv_emp_kbn_dummy)  -- �]�ƈ��敪�i1:�����A2:�O���A4:�_�~�[�j
      AND papf.attribute4 IS NULL    -- �d����R�[�h
      AND papf.attribute5 IS NULL    -- �^���Ǝ�
      AND papf.employee_number NOT IN (cv_not_get_emp1, cv_not_get_emp2, cv_not_get_emp3, cv_not_get_emp4, 
                                       cv_not_get_emp5, cv_not_get_emp6, cv_not_get_emp7, cv_not_get_emp8)  -- �]�ƈ��ԍ�
      AND papf.effective_start_date = 
              (SELECT
                   MAX(papf2.effective_start_date)
               FROM
                   per_all_people_f  papf2 -- �]�ƈ��}�X�^
               WHERE
                   papf2.person_id = papf.person_id
              )
      AND papf.person_id     = fu.employee_id
-- Ver1.18 Mod Start
--      AND papf.creation_date >= gt_pre_process_date
--      AND fu.creation_date   >= gt_pre_process_date
      AND (
                papf.creation_date >= gt_pre_process_date
            AND papf.creation_date <  gt_cur_process_date
          )
      AND (
                fu.creation_date   >= gt_pre_process_date
            AND fu.creation_date   <  gt_cur_process_date
          )
-- Ver1.18 Mod End
      AND papf.person_id = in_person_id
      ORDER BY
          employee_number ASC
    ;
--
-- Ver1.7 Add End
    -- *** ���[�J���E���R�[�h ***
    l_emp_info_rec      emp_info_cur%ROWTYPE;    -- �Ј��������̒��o�J�[�\�����R�[�h
-- Ver1.17 Add Start
    l_new_emp_rec       new_emp_cur%ROWTYPE;     -- �V���Ј����̒��o�J�[�\�����R�[�h
-- Ver1.17 Add End
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==============================================================
    -- ����K�w���[�N�i�ꎞ�\�j�̓o�^(A-6-1)
    -- ==============================================================
    BEGIN
      --
      INSERT INTO xxcmm_wk_hiera_dept (
          cur_dpt_cd                              -- �ŉ��w����R�[�h
        , dpt1_cd                                 -- �P�K�w�ڕ���R�[�h
        , dpt2_cd                                 -- �Q�K�w�ڕ���R�[�h
        , dpt3_cd                                 -- �R�K�w�ڕ���R�[�h
        , dpt4_cd                                 -- �S�K�w�ڕ���R�[�h
        , dpt5_cd                                 -- �T�K�w�ڕ���R�[�h
        , dpt6_cd                                 -- �U�K�w�ڕ���R�[�h
        , process_kbn                             -- �����敪
      )
      SELECT
          xhdv.cur_dpt_cd     AS cur_dpt_cd       -- �ŉ��w����R�[�h
        , xhdv.dpt1_cd        AS dpt1_cd          -- �P�K�w�ڕ���R�[�h
        , xhdv.dpt2_cd        AS dpt2_cd          -- �Q�K�w�ڕ���R�[�h
        , xhdv.dpt3_cd        AS dpt3_cd          -- �R�K�w�ڕ���R�[�h
        , xhdv.dpt4_cd        AS dpt4_cd          -- �S�K�w�ڕ���R�[�h
        , xhdv.dpt5_cd        AS dpt5_cd          -- �T�K�w�ڕ���R�[�h
        , xhdv.dpt6_cd        AS dpt6_cd          -- �U�K�w�ڕ���R�[�h
        , cv_proc_type_dept   AS process_kbn      -- �����敪
      FROM
          xxcmm_hierarchy_dept_v  xhdv  -- ����K�w�r���[
      ;
    EXCEPTION
      WHEN OTHERS THEN
        -- �o�^�Ɏ��s�����ꍇ
        lv_errmsg := SUBSTRB(
                       xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                       , iv_name         => cv_insert_err_msg         -- ���b�Z�[�W���F�}���G���[���b�Z�[�W
                       , iv_token_name1  => cv_tkn_table              -- �g�[�N����1�FTABLE
                       , iv_token_value1 => cv_oic_wk_hiera_dept_msg  -- �g�[�N���l1�F����K�w���[�N
                       , iv_token_name2  => cv_tkn_err_msg            -- �g�[�N����2�FERR_MSG
                       , iv_token_value2 => SQLERRM                   -- �g�[�N���l2�FSQLERRM
                       )
                     , 1
                     , 5000
                     );
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ==============================================================
    -- �Ј��������̒��o(A-6-2)
    -- ==============================================================
    -- �J�[�\���I�[�v��
    OPEN emp_info_cur;
    <<output_emp_info_loop>>
    LOOP
      --
      FETCH emp_info_cur INTO l_emp_info_rec;
      EXIT WHEN emp_info_cur%NOTFOUND;
      --
      -- ���o�����J�E���g�A�b�v
      gn_get_emp_info_cnt := gn_get_emp_info_cnt + 1;
      --
      IF ( l_emp_info_rec.roll_change_flag = cv_y ) THEN
        -- ���[���ύX�t���O��Y�̏ꍇ
        --
-- Ver1.17 Del Start
        -- ==============================================================
        -- �Ј��������̃t�@�C���o��(A-6-3)
        -- ==============================================================
-- Ver1.17 Del End
        -- �f�[�^�s�̍쐬
        lv_file_data := xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.user_name       , cv_space );  --  1 : ���[�U�[��
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.employee_number , cv_space );  --  2 : �]�ƈ��ԍ�
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.last_name       , cv_space );  --  3 : �J�i��
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.first_name      , cv_space );  --  4 : �J�i��
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.location_code   , cv_space );  --  5 : ���_�R�[�h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.license_code    , cv_space );  --  6 : ���i�R�[�h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.job_post        , cv_space );  --  7 : �E�ʃR�[�h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.job_duty        , cv_space );  --  8 : �E���R�[�h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.job_type        , cv_space );  --  9 : �E��R�[�h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt1_cd         , cv_space );  -- 10 : �P�K�w�ڕ���R�[�h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt2_cd         , cv_space );  -- 11 : �Q�K�w�ڕ���R�[�h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt3_cd         , cv_space );  -- 12 : �R�K�w�ڕ���R�[�h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt4_cd         , cv_space );  -- 13 : �S�K�w�ڕ���R�[�h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt5_cd         , cv_space );  -- 14 : �T�K�w�ڕ���R�[�h
        lv_file_data := lv_file_data || cv_comma ||
                        xxccp_oiccommon_pkg.to_csv_string( l_emp_info_rec.dpt6_cd         , cv_space );  -- 15 : �U�K�w�ڕ���R�[�h
        --
-- Ver1.17 Mod Start
--        BEGIN
--         -- �f�[�^�s�̃t�@�C���o��
--          UTL_FILE.PUT_LINE( gf_emp_inf_file_handle  -- PaaS�����p�̎Ј��������t�@�C��
--                           , lv_file_data
--                           );
--          -- �o�͌����J�E���g�A�b�v
--          gn_out_p_emp_info_cnt := gn_out_p_emp_info_cnt + 1;
    -- ==============================================================
    -- �V���Ј����̒��o(A-6-3)
    -- ==============================================================
-- Ver1.20 Add Start
      lv_new_emp_flag := cv_n;
-- Ver1.20 Add End

      -- �J�[�\���I�[�v��
      OPEN new_emp_cur (
             l_emp_info_rec.person_id
           );
      <<output_new_emp_loop>>
      LOOP
        --
        FETCH new_emp_cur INTO l_new_emp_rec;
        EXIT WHEN new_emp_cur%NOTFOUND;
        --
        -- emp_info_cur��new_emp_cur���r
--        IF ( l_emp_info_rec.person_id = l_new_emp_rec.person_id ) THEN
          lv_new_emp_flag := cv_y;
          -- ��v����ꍇY�t���O�����Ă�
--        END IF;
      END LOOP output_new_emp_loop;
--
      -- �J�[�\���N���[�Y
      CLOSE new_emp_cur;
        -- ==============================================================
        -- �Ј��������̃t�@�C���o��(A-6-4)
        -- ==============================================================
        BEGIN
          IF ( lv_new_emp_flag = cv_y ) THEN
            -- �f�[�^�s�̃t�@�C���o��
            UTL_FILE.PUT_LINE( gf_new_emp_file_handle  -- PaaS�����p�̐V���Ј����t�@�C��
                             , lv_file_data
                             );
            -- �o�͌����J�E���g�A�b�v
            gn_out_p_new_emp_cnt := gn_out_p_new_emp_cnt + 1;
          ELSE
            UTL_FILE.PUT_LINE( gf_emp_inf_file_handle  -- PaaS�����p�̎Ј��������t�@�C��
                             , lv_file_data
                             );
            -- �o�͌����J�E���g�A�b�v
            gn_out_p_emp_info_cnt := gn_out_p_emp_info_cnt + 1;
          END IF;
          --
-- Ver1.17 Mod End
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_fileout_expt;
        END;
      --
      ELSE
        -- ���[���ύX�t���O��N�̏ꍇ
        -- �X�L�b�v�������J�E���g�A�b�v
        gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
      --
      --
-- Ver1.17 Mod Start
--      -- ==============================================================
--      -- OIC�Ј��������e�[�u���̓o�^�E�X�V����(A-6-4)
--      -- ==============================================================
      -- ==============================================================
      -- OIC�Ј��������e�[�u���̓o�^�E�X�V����(A-6-5)
      -- ==============================================================
-- Ver1.17 Mod End
      IF (    l_emp_info_rec.roll_change_flag  = cv_y
           OR l_emp_info_rec.other_change_flag = cv_y ) THEN
        -- ���[���ύX�t���O��Y�A�܂��́A���̑��ύX�t���O��Y�̏ꍇ
        --
        IF ( l_emp_info_rec.xoedi_person_id IS NULL ) THEN
          -- �lID�i�Ј��������j��NULL�̏ꍇ
          --
          BEGIN
            -- OIC�Ј��������e�[�u���̓o�^
            INSERT INTO xxcmm_oic_emp_diff_info (
                person_id                                     -- �lID
              , employee_number                               -- �]�ƈ��ԍ�
              , user_name                                     -- ���[�U�[��
              , last_name                                     -- �J�i��
              , first_name                                    -- �J�i��
              , location_code                                 -- ���_�R�[�h
              , license_code                                  -- ���i�R�[�h
              , job_post                                      -- �E�ʃR�[�h
              , job_duty                                      -- �E���R�[�h
              , job_type                                      -- �E��R�[�h
              , dpt1_cd                                       -- �P�K�w�ڕ���R�[�h
              , dpt2_cd                                       -- �Q�K�w�ڕ���R�[�h
              , dpt3_cd                                       -- �R�K�w�ڕ���R�[�h
              , dpt4_cd                                       -- �S�K�w�ڕ���R�[�h
              , dpt5_cd                                       -- �T�K�w�ڕ���R�[�h
              , dpt6_cd                                       -- �U�K�w�ڕ���R�[�h
              , sup_assignment_number                         -- �㒷�A�T�C�����g�ԍ�
              , date_start                                    -- �J�n��
              , actual_termination_date                       -- �ސE��
              , created_by                                    -- �쐬��
              , creation_date                                 -- �쐬��
              , last_updated_by                               -- �ŏI�X�V��
              , last_update_date                              -- �ŏI�X�V��
              , last_update_login                             -- �ŏI�X�V���O�C��
              , request_id                                    -- �v��ID
              , program_application_id                        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              , program_id                                    -- �R���J�����g�E�v���O����ID
              , program_update_date                           -- �v���O�����X�V��
            ) VALUES (
                l_emp_info_rec.person_id                      -- �lID
              , l_emp_info_rec.employee_number                -- �]�ƈ��ԍ�
              , l_emp_info_rec.user_name                      -- ���[�U�[��
              , l_emp_info_rec.last_name                      -- �J�i��
              , l_emp_info_rec.first_name                     -- �J�i��
              , l_emp_info_rec.location_code                  -- ���_�R�[�h
              , l_emp_info_rec.license_code                   -- ���i�R�[�h
              , l_emp_info_rec.job_post                       -- �E�ʃR�[�h
              , l_emp_info_rec.job_duty                       -- �E���R�[�h
              , l_emp_info_rec.job_type                       -- �E��R�[�h
              , l_emp_info_rec.dpt1_cd                        -- �P�K�w�ڕ���R�[�h
              , l_emp_info_rec.dpt2_cd                        -- �Q�K�w�ڕ���R�[�h
              , l_emp_info_rec.dpt3_cd                        -- �R�K�w�ڕ���R�[�h
              , l_emp_info_rec.dpt4_cd                        -- �S�K�w�ڕ���R�[�h
              , l_emp_info_rec.dpt5_cd                        -- �T�K�w�ڕ���R�[�h
              , l_emp_info_rec.dpt6_cd                        -- �U�K�w�ڕ���R�[�h
              , l_emp_info_rec.sup_assignment_number          -- �㒷�A�T�C�����g�ԍ�
              , l_emp_info_rec.date_start                     -- �J�n��
              , l_emp_info_rec.actual_termination_date        -- �ސE��
              , cn_created_by                                 -- �쐬��
              , cd_creation_date                              -- �쐬��
              , cn_last_updated_by                            -- �ŏI�X�V��
              , cd_last_update_date                           -- �ŏI�X�V��
              , cn_last_update_login                          -- �ŏI�X�V���O�C��
              , cn_request_id                                 -- �v��ID
              , cn_program_application_id                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
              , cn_program_id                                 -- �R���J�����g�E�v���O����ID
              , cd_program_update_date                        -- �v���O�����X�V��
            );
          EXCEPTION
            WHEN OTHERS THEN
              -- �o�^�Ɏ��s�����ꍇ
              lv_errmsg := SUBSTRB(
                             xxccp_common_pkg.get_msg(
                               iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                             , iv_name         => cv_insert_err_msg         -- ���b�Z�[�W���F�}���G���[���b�Z�[�W
                             , iv_token_name1  => cv_tkn_table              -- �g�[�N����1�FTABLE
                             , iv_token_value1 => cv_oic_emp_info_tbl_msg   -- �g�[�N���l1�FOIC�Ј��������e�[�u��
                             , iv_token_name2  => cv_tkn_err_msg            -- �g�[�N����2�FERR_MSG
                             , iv_token_value2 => SQLERRM                   -- �g�[�N���l2�FSQLERRM
                             )
                           , 1
                           , 5000
                           );
              lv_errbuf  := lv_errmsg;
              RAISE global_process_expt;
          END;
        --
        ELSE
          -- �lID�i�Ј��������j��NOT NULL�̏ꍇ
          --
          BEGIN
            -- OIC�Ј��������e�[�u���̍X�V
            UPDATE
                xxcmm_oic_emp_diff_info  xoedi  -- OIC�Ј��������e�[�u��
            SET
                xoedi.last_name                = l_emp_info_rec.last_name                   -- �J�i��
              , xoedi.first_name               = l_emp_info_rec.first_name                  -- �J�i��
              , xoedi.location_code            = l_emp_info_rec.location_code               -- ���_�R�[�h
              , xoedi.license_code             = l_emp_info_rec.license_code                -- ���i�R�[�h
              , xoedi.job_post                 = l_emp_info_rec.job_post                    -- �E�ʃR�[�h
              , xoedi.job_duty                 = l_emp_info_rec.job_duty                    -- �E���R�[�h
              , xoedi.job_type                 = l_emp_info_rec.job_type                    -- �E��R�[�h
              , xoedi.dpt1_cd                  = l_emp_info_rec.dpt1_cd                     -- �P�K�w�ڕ���R�[�h
              , xoedi.dpt2_cd                  = l_emp_info_rec.dpt2_cd                     -- �Q�K�w�ڕ���R�[�h
              , xoedi.dpt3_cd                  = l_emp_info_rec.dpt3_cd                     -- �R�K�w�ڕ���R�[�h
              , xoedi.dpt4_cd                  = l_emp_info_rec.dpt4_cd                     -- �S�K�w�ڕ���R�[�h
              , xoedi.dpt5_cd                  = l_emp_info_rec.dpt5_cd                     -- �T�K�w�ڕ���R�[�h
              , xoedi.dpt6_cd                  = l_emp_info_rec.dpt6_cd                     -- �U�K�w�ڕ���R�[�h
              , xoedi.sup_assignment_number    = l_emp_info_rec.sup_assignment_number       -- �㒷�A�T�C�����g�ԍ�
              , xoedi.date_start               = l_emp_info_rec.date_start                  -- �J�n��
              , xoedi.actual_termination_date  = l_emp_info_rec.actual_termination_date     -- �ސE��
              , xoedi.last_update_date         = cd_last_update_date                        -- �ŏI�X�V��
              , xoedi.last_updated_by          = cn_last_updated_by                         -- �ŏI�X�V��
              , xoedi.last_update_login        = cn_last_update_login                       -- �ŏI�X�V���O�C��
              , xoedi.request_id               = cn_request_id                              -- �v��ID
              , xoedi.program_application_id   = cn_program_application_id                  -- �v���O�����A�v���P�[�V����ID
              , xoedi.program_id               = cn_program_id                              -- �v���O����ID
              , xoedi.program_update_date      = cd_program_update_date                     -- �v���O�����X�V��
            WHERE
                xoedi.person_id                = l_emp_info_rec.xoedi_person_id             -- �lID�i�Ј��������j
            ;
          EXCEPTION
            WHEN OTHERS THEN
              -- �X�V�Ɏ��s�����ꍇ
              lv_errmsg := SUBSTRB(
                             xxccp_common_pkg.get_msg(
                               iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                             , iv_name         => cv_update_err_msg         -- ���b�Z�[�W���F�X�V�G���[���b�Z�[�W
                             , iv_token_name1  => cv_tkn_table              -- �g�[�N����1�FTABLE
                             , iv_token_value1 => cv_oic_emp_info_tbl_msg   -- �g�[�N���l1�FOIC�Ј��������e�[�u��
                             , iv_token_name2  => cv_tkn_err_msg            -- �g�[�N����2�FERR_MSG
                             , iv_token_value2 => SQLERRM                   -- �g�[�N���l2�FSQLERRM
                             )
                           , 1
                           , 5000
                           );
              lv_errbuf  := lv_errmsg;
              RAISE global_process_expt;
          END;
        END IF;
      END IF;
      --
      --
-- Ver1.17 Mod Start
--      -- ==============================================================
--      -- OIC�Ј��������o�b�N�A�b�v�e�[�u���̓o�^����(A-6-5)
--      -- ==============================================================
      -- ==============================================================
      -- OIC�Ј��������o�b�N�A�b�v�e�[�u���̓o�^����(A-6-6)
      -- ==============================================================

-- Ver1.17 Mod End
      IF (    l_emp_info_rec.roll_change_flag  = cv_y
           OR l_emp_info_rec.other_change_flag = cv_y ) THEN
        -- ���[���ύX�t���O��Y�A�܂��́A���̑��ύX�t���O��Y�̏ꍇ
        --
        BEGIN
          -- OIC�Ј��������o�b�N�A�b�v�e�[�u���̓o�^
          INSERT INTO xxcmm_oic_emp_diff_info_bk (
              person_id                                     -- �lID
            , employee_number                               -- �]�ƈ��ԍ�
            , user_name                                     -- ���[�U�[��
            , pre_last_name                                 -- �O��J�i��
            , pre_first_name                                -- �O��J�i��
            , pre_location_code                             -- �O�񋒓_�R�[�h
            , pre_license_code                              -- �O�񎑊i�R�[�h
            , pre_job_post                                  -- �O��E�ʃR�[�h
            , pre_job_duty                                  -- �O��E���R�[�h
            , pre_job_type                                  -- �O��E��R�[�h
            , pre_dpt1_cd                                   -- �O��P�K�w�ڕ���R�[�h
            , pre_dpt2_cd                                   -- �O��Q�K�w�ڕ���R�[�h
            , pre_dpt3_cd                                   -- �O��R�K�w�ڕ���R�[�h
            , pre_dpt4_cd                                   -- �O��S�K�w�ڕ���R�[�h
            , pre_dpt5_cd                                   -- �O��T�K�w�ڕ���R�[�h
            , pre_dpt6_cd                                   -- �O��U�K�w�ڕ���R�[�h
            , pre_sup_assignment_number                     -- �O��㒷�A�T�C�����g�ԍ�
            , pre_date_start                                -- �O��J�n��
            , pre_actual_termination_date                   -- �O��ސE��
            , last_name                                     -- �J�i��
            , first_name                                    -- �J�i��
            , location_code                                 -- ���_�R�[�h
            , license_code                                  -- ���i�R�[�h
            , job_post                                      -- �E�ʃR�[�h
            , job_duty                                      -- �E���R�[�h
            , job_type                                      -- �E��R�[�h
            , dpt1_cd                                       -- �P�K�w�ڕ���R�[�h
            , dpt2_cd                                       -- �Q�K�w�ڕ���R�[�h
            , dpt3_cd                                       -- �R�K�w�ڕ���R�[�h
            , dpt4_cd                                       -- �S�K�w�ڕ���R�[�h
            , dpt5_cd                                       -- �T�K�w�ڕ���R�[�h
            , dpt6_cd                                       -- �U�K�w�ڕ���R�[�h
            , sup_assignment_number                         -- �㒷�A�T�C�����g�ԍ�
            , date_start                                    -- �J�n��
            , actual_termination_date                       -- �ސE��
            , created_by                                    -- �쐬��
            , creation_date                                 -- �쐬��
            , last_updated_by                               -- �ŏI�X�V��
            , last_update_date                              -- �ŏI�X�V��
            , last_update_login                             -- �ŏI�X�V���O�C��
            , request_id                                    -- �v��ID
            , program_application_id                        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            , program_id                                    -- �R���J�����g�E�v���O����ID
            , program_update_date                           -- �v���O�����X�V��
          ) VALUES (
              l_emp_info_rec.person_id                      -- �lID
            , l_emp_info_rec.employee_number                -- �]�ƈ��ԍ�
            , l_emp_info_rec.user_name                      -- ���[�U�[��
            , l_emp_info_rec.pre_last_name                  -- �O��J�i��
            , l_emp_info_rec.pre_first_name                 -- �O��J�i��
            , l_emp_info_rec.pre_location_code              -- �O�񋒓_�R�[�h
            , l_emp_info_rec.pre_license_code               -- �O�񎑊i�R�[�h
            , l_emp_info_rec.pre_job_post                   -- �O��E�ʃR�[�h
            , l_emp_info_rec.pre_job_duty                   -- �O��E���R�[�h
            , l_emp_info_rec.pre_job_type                   -- �O��E��R�[�h
            , l_emp_info_rec.pre_dpt1_cd                    -- �O��P�K�w�ڕ���R�[�h
            , l_emp_info_rec.pre_dpt2_cd                    -- �O��Q�K�w�ڕ���R�[�h
            , l_emp_info_rec.pre_dpt3_cd                    -- �O��R�K�w�ڕ���R�[�h
            , l_emp_info_rec.pre_dpt4_cd                    -- �O��S�K�w�ڕ���R�[�h
            , l_emp_info_rec.pre_dpt5_cd                    -- �O��T�K�w�ڕ���R�[�h
            , l_emp_info_rec.pre_dpt6_cd                    -- �O��U�K�w�ڕ���R�[�h
            , l_emp_info_rec.pre_sup_assignment_number      -- �O��㒷�A�T�C�����g�ԍ�
            , l_emp_info_rec.pre_date_start                 -- �O��J�n��
            , l_emp_info_rec.pre_actual_termination_date    -- �O��ސE��
            , l_emp_info_rec.last_name                      -- �J�i��
            , l_emp_info_rec.first_name                     -- �J�i��
            , l_emp_info_rec.location_code                  -- ���_�R�[�h
            , l_emp_info_rec.license_code                   -- ���i�R�[�h
            , l_emp_info_rec.job_post                       -- �E�ʃR�[�h
            , l_emp_info_rec.job_duty                       -- �E���R�[�h
            , l_emp_info_rec.job_type                       -- �E��R�[�h
            , l_emp_info_rec.dpt1_cd                        -- �P�K�w�ڕ���R�[�h
            , l_emp_info_rec.dpt2_cd                        -- �Q�K�w�ڕ���R�[�h
            , l_emp_info_rec.dpt3_cd                        -- �R�K�w�ڕ���R�[�h
            , l_emp_info_rec.dpt4_cd                        -- �S�K�w�ڕ���R�[�h
            , l_emp_info_rec.dpt5_cd                        -- �T�K�w�ڕ���R�[�h
            , l_emp_info_rec.dpt6_cd                        -- �U�K�w�ڕ���R�[�h
            , l_emp_info_rec.sup_assignment_number          -- �㒷�A�T�C�����g�ԍ�
            , l_emp_info_rec.date_start                     -- �J�n��
            , l_emp_info_rec.actual_termination_date        -- �ސE��
            , cn_created_by                                 -- �쐬��
            , cd_creation_date                              -- �쐬��
            , cn_last_updated_by                            -- �ŏI�X�V��
            , cd_last_update_date                           -- �ŏI�X�V��
            , cn_last_update_login                          -- �ŏI�X�V���O�C��
            , cn_request_id                                 -- �v��ID
            , cn_program_application_id                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
            , cn_program_id                                 -- �R���J�����g�E�v���O����ID
            , cd_program_update_date                        -- �v���O�����X�V��
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- �o�^�Ɏ��s�����ꍇ
            lv_errmsg := SUBSTRB(
                           xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                           , iv_name         => cv_insert_err_msg         -- ���b�Z�[�W���F�}���G���[���b�Z�[�W
                           , iv_token_name1  => cv_tkn_table              -- �g�[�N����1�FTABLE
                           , iv_token_value1 => cv_oic_emp_inf_bk_tbl_msg -- �g�[�N���l1�FOIC�Ј��������o�b�N�A�b�v�e�[�u��
                           , iv_token_name2  => cv_tkn_err_msg            -- �g�[�N����2�FERR_MSG
                           , iv_token_value2 => SQLERRM                   -- �g�[�N���l2�FSQLERRM
                           )
                         , 1
                         , 5000
                         );
            lv_errbuf  := lv_errmsg;
            RAISE global_process_expt;
        END;
      END IF;
    --
    END LOOP output_emp_info_loop;
--
    -- �J�[�\���N���[�Y
    CLOSE emp_info_cur;
--
  EXCEPTION
    -- *** ���b�N�G���[��O�n���h�� ***
    WHEN global_lock_expt THEN
      -- �J�[�\���N���[�Y
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- �J�[�\���N���[�Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                   , iv_name         => cv_lock_err_msg           -- ���b�Z�[�W���F���b�N�G���[���b�Z�[�W
                   , iv_token_name1  => cv_tkn_ng_table           -- �g�[�N����1�FNG_TABLE
                   , iv_token_value1 => cv_oic_emp_info_tbl_msg   -- �g�[�N���l1�FOIC�Ј��������
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** �t�@�C���o�͎���O�n���h�� ***
    WHEN global_fileout_expt THEN
      -- �J�[�\���N���[�Y
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- �J�[�\���N���[�Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      lv_errmsg := SUBSTRB(
                     xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                     , iv_name         => cv_file_write_err_msg     -- ���b�Z�[�W���F�t�@�C���������݃G���[���b�Z�[�W
                     , iv_token_name1  => cv_tkn_sqlerrm            -- �g�[�N����1�FSQLERRM
                     , iv_token_value1 => SQLERRM                   -- �g�[�N���l1�FSQLERRM
                     )
                   , 1
                   , 5000
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �J�[�\���N���[�Y
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- �J�[�\���N���[�Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      -- �J�[�\���N���[�Y
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- �J�[�\���N���[�Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �J�[�\���N���[�Y
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- �J�[�\���N���[�Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �J�[�\���N���[�Y
      IF ( emp_info_cur%ISOPEN ) THEN
        CLOSE emp_info_cur;
      END IF;
-- Ver1.17 Add Start
      -- �J�[�\���N���[�Y
      IF ( new_emp_cur%ISOPEN ) THEN
        CLOSE new_emp_cur;
      END IF;
-- Ver1.17 Add End
      --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_emp_info;
--
--
  /**********************************************************************************
   * Procedure Name   : update_mng_tbl
   * Description      : �Ǘ��e�[�u���o�^�E�X�V����(A-7)
   ***********************************************************************************/
  PROCEDURE update_mng_tbl(
    ov_errbuf     OUT VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_mng_tbl';       -- �v���O������
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
    IF ( gv_first_proc_flag = cv_y ) THEN
      -- ���񏈗��t���O��Y�̏ꍇ
      --
      BEGIN
        -- OIC�A�g�����Ǘ��e�[�u���̓o�^
        INSERT INTO xxccp_oic_if_process_mng (
            program_name                -- �v���O������
          , pre_process_date            -- �O�񏈗�����
          , created_by                  -- �쐬��
          , creation_date               -- �쐬��
          , last_updated_by             -- �ŏI�X�V��
          , last_update_date            -- �ŏI�X�V��
          , last_update_login           -- �ŏI�X�V���O�C��
          , request_id                  -- �v��ID
          , program_application_id      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , program_id                  -- �R���J�����g�E�v���O����ID
          , program_update_date         -- �v���O�����X�V��
        ) VALUES (
            gt_conc_program_name        -- �v���O������
          , gt_cur_process_date         -- �O�񏈗�����
          , cn_created_by               -- �쐬��
          , cd_creation_date            -- �쐬��
          , cn_last_updated_by          -- �ŏI�X�V��
          , cd_last_update_date         -- �ŏI�X�V��
          , cn_last_update_login        -- �ŏI�X�V���O�C��
          , cn_request_id               -- �v��ID
          , cn_program_application_id   -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          , cn_program_id               -- �R���J�����g�E�v���O����ID
          , cd_program_update_date      -- �v���O�����X�V��
        );
      EXCEPTION
        WHEN OTHERS THEN
          -- �o�^�Ɏ��s�����ꍇ
          lv_errmsg := SUBSTRB(
                         xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                         , iv_name         => cv_insert_err_msg         -- ���b�Z�[�W���F�}���G���[���b�Z�[�W
                         , iv_token_name1  => cv_tkn_table              -- �g�[�N����1�FTABLE
                         , iv_token_value1 => cv_oic_proc_mng_tbl_msg   -- �g�[�N���l1�FOIC�A�g�����Ǘ��e�[�u��
                         , iv_token_name2  => cv_tkn_err_msg            -- �g�[�N����2�FERR_MSG
                         , iv_token_value2 => SQLERRM                   -- �g�[�N���l2�FSQLERRM
                         )
                       , 1
                       , 5000
                       );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    --
    ELSE
      --
      -- ���񏈗��t���O��N�̏ꍇ
      BEGIN
        -- OIC�A�g�����Ǘ��e�[�u���̍X�V
        UPDATE
            xxccp_oic_if_process_mng  xoipm  -- OIC�A�g�����Ǘ��e�[�u��
        SET
            xoipm.pre_process_date       = gt_cur_process_date          -- �O�񏈗�����
          , xoipm.last_update_date       = cd_last_update_date          -- �ŏI�X�V��
          , xoipm.last_updated_by        = cn_last_updated_by           -- �ŏI�X�V��
          , xoipm.last_update_login      = cn_last_update_login         -- �ŏI�X�V���O�C��
          , xoipm.request_id             = cn_request_id                -- �v��ID
          , xoipm.program_application_id = cn_program_application_id    -- �v���O�����A�v���P�[�V����ID
          , xoipm.program_id             = cn_program_id                -- �v���O����ID
          , xoipm.program_update_date    = cd_program_update_date       -- �v���O�����X�V��
        WHERE
            xoipm.program_name           = gt_conc_program_name         -- �v���O������
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- �X�V�Ɏ��s�����ꍇ
          lv_errmsg := SUBSTRB(
                         xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                         , iv_name         => cv_update_err_msg         -- ���b�Z�[�W���F�X�V�G���[���b�Z�[�W
                         , iv_token_name1  => cv_tkn_table              -- �g�[�N����1�FTABLE
                         , iv_token_value1 => cv_oic_proc_mng_tbl_msg   -- �g�[�N���l1�FOIC�A�g�����Ǘ��e�[�u��
                         , iv_token_name2  => cv_tkn_err_msg            -- �g�[�N����2�FERR_MSG
                         , iv_token_value2 => SQLERRM                   -- �g�[�N���l2�FSQLERRM
                         )
                       , 1
                       , 5000
                       );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END update_mng_tbl;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_proc_date_for_recovery  IN   VARCHAR2,       -- 1.�Ɩ����t�i���J�o���p�j
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
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
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
    -- �ʌ����̏�����
    -- ���o����
    gn_get_wk_cnt             := 0;     -- �A�ƎҒ��o����
    gn_get_per_name_cnt       := 0;     -- �l�����o����
    gn_get_per_legi_cnt       := 0;     -- �l���ʎd�l�f�[�^���o����
    gn_get_per_email_cnt      := 0;     -- �lE���[�����o����
    gn_get_wk_rel_cnt         := 0;     -- �ٗp�֌W�i�ސE�ҁj���o����
    gn_get_new_user_cnt       := 0;     -- ���[�U�[���i�V�K�j���o����
    gn_get_new_user_paas_cnt  := 0;     -- ���[�U�[���i�V�K�jPaaS�p���o����
    gn_get_wk_terms_cnt       := 0;     -- �ٗp�������o����
    gn_get_ass_cnt            := 0;     -- �A�T�C�����g��񒊏o����
    gn_get_user_cnt           := 0;     -- ���[�U�[��񒊏o����
-- Ver1.2(E055) Add Start
    gn_get_user2_cnt          := 0;     -- ���[�U�[���i�폜�j���o����
-- Ver1.2(E055) Add End
    gn_get_ass_sup_cnt        := 0;     -- �A�T�C�����g���i�㒷�j���o����
    gn_get_wk_rel2_cnt        := 0;     -- �ٗp�֌W�i�V�K�̗p�ސE�ҁj���o����
    gn_get_bank_acc_cnt       := 0;     -- �]�ƈ��o�������񒊏o����
    gn_get_emp_info_cnt       := 0;     -- �Ј�������񒊏o����
    -- �o�͌���
    gn_out_wk_cnt             := 0;     -- �]�ƈ����A�g�f�[�^�t�@�C���o�͌���
    gn_out_p_new_user_cnt     := 0;     -- PaaS�����p�̐V�K���[�U�[���t�@�C���o�͌���
    gn_out_user_cnt           := 0;     -- ���[�U�[���A�g�f�[�^�t�@�C���o�͌���
-- Ver1.2(E055) Add Start
    gn_out_user2_cnt          := 0;     -- ���[�U�[���i�폜�j�A�g�f�[�^�t�@�C���o�͌���
-- Ver1.2(E055) Add End
    gn_out_wk2_cnt            := 0;     -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C���o�͌���
    gn_out_p_bank_acct_cnt    := 0;     -- PaaS�����p�̏]�ƈ��o��������t�@�C���o�͌���
    gn_out_p_emp_info_cnt     := 0;     -- PaaS�����p�̎Ј��������t�@�C���o�͌���
-- Ver1.17 Add Start
    gn_out_p_new_emp_cnt      := 0;     -- PaaS�����p�̐V���Ј����t�@�C���o�͌���
-- Ver1.17 Add End
--
    --
    --===============================================
    -- ��������(A-1)
    --===============================================
    init(
      iv_proc_date_for_recovery => iv_proc_date_for_recovery  -- �Ɩ����t�i���J�o���p�jID
    , ov_errbuf                 => lv_errbuf                  -- �G���[�E���b�Z�[�W
    , ov_retcode                => lv_retcode                 -- ���^�[���E�R�[�h
    , ov_errmsg                 => lv_errmsg                  -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- �]�ƈ����̒��o�E�t�@�C���o�͏���(A-2)
    --================================================================
    output_worker(
      ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
    , ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
    , ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- ���[�U�[���̒��o�E�t�@�C���o�͏���(A-3)
    --================================================================
    output_user(
      ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
    , ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
    , ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�̒��o�E�t�@�C���o�͏���(A-4)
    --================================================================
    output_worker2(
      ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
    , ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
    , ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- �]�ƈ��o��������̒��o�E�t�@�C���o�͏���(A-5)
    --================================================================
    output_emp_bank_acct(
      ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
    , ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
    , ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --================================================================
    -- �Ј��������̒��o�E�t�@�C���o�͏����iPaaS�����p�j(A-6)
    --================================================================
    output_emp_info(
      ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
    , ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
    , ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --===============================================
    -- �Ǘ��e�[�u���o�^�E�X�V����(A-7)
    --===============================================
    update_mng_tbl(
      ov_errbuf          => lv_errbuf           -- �G���[�E���b�Z�[�W
    , ov_retcode         => lv_retcode          -- ���^�[���E�R�[�h
    , ov_errmsg          => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
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
    errbuf                     OUT VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode                    OUT VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_proc_date_for_recovery  IN  VARCHAR2       --   �Ɩ����t�i���J�o���p�j
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
--
    lv_msg             VARCHAR2(3000);  -- ���b�Z�[�W
    -- ���o�����p���R�[�h
    TYPE l_get_cnt_rtype IS RECORD
    (
      target           VARCHAR2(100)    -- ���o�Ώ�
    , cnt              VARCHAR2(10)     -- �����i���b�Z�[�W�p�j
    );
    -- ���o�����p�e�[�u��
    TYPE l_get_cnt_ttype IS TABLE OF l_get_cnt_rtype INDEX BY BINARY_INTEGER;
    l_get_cnt_tab    l_get_cnt_ttype;
--
    -- �o�͌����p���R�[�h
    TYPE l_out_cnt_rtype IS RECORD
    (
      target           VARCHAR2(100)    -- �o�͑Ώ�
    , cnt              VARCHAR2(10)     -- �����i���b�Z�[�W�p�j
    );
    -- �o�͌����p�e�[�u��
    TYPE l_out_cnt_ttype IS TABLE OF l_out_cnt_rtype INDEX BY BINARY_INTEGER;
    l_out_cnt_tab    l_out_cnt_ttype;
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
       iv_proc_date_for_recovery
      ,lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    -- �G���[�̏ꍇ
    IF (lv_retcode = cv_status_error) THEN
      --
      -- �e�o�͌����̏������i0���j
      gn_out_wk_cnt           := 0;     -- �]�ƈ����A�g�f�[�^�t�@�C���o�͌���
      gn_out_p_new_user_cnt   := 0;     -- PaaS�����p�̐V�K���[�U�[���t�@�C���o�͌���
      gn_out_user_cnt         := 0;     -- ���[�U�[���A�g�f�[�^�t�@�C���o�͌���
-- Ver1.2(E055) Add Start
      gn_out_user2_cnt        := 0;     -- ���[�U�[���i�폜�j�A�g�f�[�^�t�@�C���o�͌���
-- Ver1.2(E055) Add End
      gn_out_wk2_cnt          := 0;     -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C���o�͌���
      gn_out_p_bank_acct_cnt  := 0;     -- PaaS�����p�̏]�ƈ��o��������t�@�C���o�͌���
      gn_out_p_emp_info_cnt   := 0;     -- PaaS�����p�̎Ј��������t�@�C���o�͌���
-- Ver1.17 Add Start
      gn_out_p_new_emp_cnt    := 0;     -- PaaS�����p�̐V���Ј����t�@�C���o�͌���
-- Ver1.17 Add End
      --
      -- �G���[�����̐ݒ�
      gn_error_cnt            := 1;
      --
      -- �X�L�b�v�����̏������i0���j
      gn_warn_cnt             := 0;
      --
      -- �G���[���b�Z�[�W�̏o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================
    -- �I������(A-8)
    --===============================================
--
    -------------------------------------------------
    -- �t�@�C���N���[�Y
    -------------------------------------------------
    -- �]�ƈ����A�g�f�[�^�t�@�C��
    IF ( UTL_FILE.IS_OPEN ( gf_wrk_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_wrk_file_handle );
    END IF;
    -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
    IF ( UTL_FILE.IS_OPEN ( gf_wrk2_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_wrk2_file_handle );
    END IF;
    -- ���[�U�[���A�g�f�[�^�t�@�C��
    IF ( UTL_FILE.IS_OPEN ( gf_usr_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_usr_file_handle );
    END IF;
-- Ver1.2(E055) Add Start
    -- ���[�U�[���i�폜�j�A�g�f�[�^�t�@�C��
    IF ( UTL_FILE.IS_OPEN ( gf_usr2_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_usr2_file_handle );
    END IF;
-- Ver1.2(E055) Add End
    -- PaaS�����p�̐V�K���[�U�[���t�@�C��
    IF ( UTL_FILE.IS_OPEN ( gf_new_usr_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_new_usr_file_handle );
    END IF;
    -- PaaS�����p�̏]�ƈ��o��������t�@�C��
    IF ( UTL_FILE.IS_OPEN ( gf_emp_bnk_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_emp_bnk_file_handle );
    END IF;
    -- PaaS�����p�̎Ј��������t�@�C��
    IF ( UTL_FILE.IS_OPEN ( gf_emp_inf_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_emp_inf_file_handle );
    END IF;
-- Ver1.17 Add Start
    -- PaaS�����p�̐V���Ј����t�@�C��
    IF ( UTL_FILE.IS_OPEN ( gf_new_emp_file_handle )) THEN
      UTL_FILE.FCLOSE( gf_new_emp_file_handle );
    END IF;
-- Ver1.17 Add End
--    
    -------------------------------------------------
    -- ���o�����̏o��
    -------------------------------------------------
    -- �A�ƎҒ��o����
    l_get_cnt_tab(1).target  := cv_worker_msg;
    l_get_cnt_tab(1).cnt     := TO_CHAR(gn_get_wk_cnt);
    -- �l�����o����
    l_get_cnt_tab(2).target  := cv_per_name_msg;
    l_get_cnt_tab(2).cnt     := TO_CHAR(gn_get_per_name_cnt);
    -- �l���ʎd�l�f�[�^���o����
    l_get_cnt_tab(3).target  := cv_per_legi_msg;
    l_get_cnt_tab(3).cnt     := TO_CHAR(gn_get_per_legi_cnt);
    -- �lE���[�����o����
    l_get_cnt_tab(4).target  := cv_per_email_msg;
    l_get_cnt_tab(4).cnt     := TO_CHAR(gn_get_per_email_cnt);
    -- �ٗp�֌W�i�ސE�ҁj���o����
    l_get_cnt_tab(5).target  := cv_work_relation_msg;
    l_get_cnt_tab(5).cnt     := TO_CHAR(gn_get_wk_rel_cnt);
    -- ���[�U�[���i�V�K�j���o����
    l_get_cnt_tab(6).target  := cv_new_user_info_msg;
    l_get_cnt_tab(6).cnt     := TO_CHAR(gn_get_new_user_cnt);
    -- ���[�U�[���i�V�K�jPaaS�p���o����
    l_get_cnt_tab(7).target  := cv_new_user_info_paas_msg;
    l_get_cnt_tab(7).cnt     := TO_CHAR(gn_get_new_user_paas_cnt);
    -- �ٗp�������o����
    l_get_cnt_tab(8).target  := cv_work_term_msg;
    l_get_cnt_tab(8).cnt     := TO_CHAR(gn_get_wk_terms_cnt);
    -- �A�T�C�����g��񒊏o����
    l_get_cnt_tab(9).target  := cv_assignment_msg;
    l_get_cnt_tab(9).cnt     := TO_CHAR(gn_get_ass_cnt);
    -- ���[�U�[��񒊏o����
    l_get_cnt_tab(10).target  := cv_user_info_msg;
    l_get_cnt_tab(10).cnt     := TO_CHAR(gn_get_user_cnt);
-- Ver1.2(E055) Add Start
    -- ���[�U�[���i�폜�j���o����
    l_get_cnt_tab(11).target  := cv_user2_info_msg;
    l_get_cnt_tab(11).cnt     := TO_CHAR(gn_get_user2_cnt);
-- Ver1.2(E055) Add End
    -- �A�T�C�����g���i�㒷�j���o����
    l_get_cnt_tab(12).target := cv_sup_assignment_msg;
    l_get_cnt_tab(12).cnt    := TO_CHAR(gn_get_ass_sup_cnt);
    -- �ٗp�֌W�i�V�K�̗p�ސE�ҁj���o����
    l_get_cnt_tab(13).target := cv_work_relation_2_msg;
    l_get_cnt_tab(13).cnt    := TO_CHAR(gn_get_wk_rel2_cnt);
    -- �]�ƈ��o�������񒊏o����
    l_get_cnt_tab(14).target := cv_emp_bank_acct_msg;
    l_get_cnt_tab(14).cnt    := TO_CHAR(gn_get_bank_acc_cnt);
    -- �Ј�������񒊏o����
    l_get_cnt_tab(15).target := cv_emp_info_msg;
    l_get_cnt_tab(15).cnt    := TO_CHAR(gn_get_emp_info_cnt);
    --
    <<get_count_out_loop>>
    FOR i IN 1..l_get_cnt_tab.COUNT LOOP
      --
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                , iv_name         => cv_search_trgt_cnt_msg    -- ���b�Z�[�W���F�����ΏہE�������b�Z�[�W
                , iv_token_name1  => cv_tkn_target             -- �g�[�N����1�FTARGET
                , iv_token_value1 => l_get_cnt_tab(i).target   -- �g�[�N���l1�F���o�Ώ�
                , iv_token_name2  => cv_tkn_count              -- �g�[�N����2�FCOUNT
                , iv_token_value2 => l_get_cnt_tab(i).cnt      -- �g�[�N���l2�F���o����
                );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
      );
    END LOOP file_name_out_loop;
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--  
    -------------------------------------------------
    -- �o�͌����̏o��
    -------------------------------------------------
    -- �]�ƈ����A�g�f�[�^�t�@�C��
    l_out_cnt_tab(1).target  := gt_prf_val_wrk_out_file;
    l_out_cnt_tab(1).cnt     := TO_CHAR(gn_out_wk_cnt);
    -- PaaS�����p�̐V�K���[�U�[���t�@�C��
    l_out_cnt_tab(2).target  := gt_prf_val_new_usr_out_file;
    l_out_cnt_tab(2).cnt     := TO_CHAR(gn_out_p_new_user_cnt);
    -- ���[�U�[���A�g�f�[�^�t�@�C��
    l_out_cnt_tab(3).target  := gt_prf_val_usr_out_file;
    l_out_cnt_tab(3).cnt     := TO_CHAR(gn_out_user_cnt);
-- Ver1.2(E055) Add Start
    -- ���[�U�[���i�폜�j�A�g�f�[�^�t�@�C��
    l_out_cnt_tab(4).target  := gt_prf_val_usr2_out_file;
    l_out_cnt_tab(4).cnt     := TO_CHAR(gn_out_user2_cnt);
-- Ver1.2(E055) Add End
    -- �]�ƈ����i�㒷�E�V�K�̗p�ސE�ҁj�A�g�f�[�^�t�@�C��
    l_out_cnt_tab(5).target  := gt_prf_val_wrk2_out_file;
    l_out_cnt_tab(5).cnt     := TO_CHAR(gn_out_wk2_cnt);
    -- PaaS�����p�̏]�ƈ��o��������t�@�C��
    l_out_cnt_tab(6).target  := gt_prf_val_emp_bnk_out_file;
    l_out_cnt_tab(6).cnt     := TO_CHAR(gn_out_p_bank_acct_cnt);
    -- PaaS�����p�̎Ј��������t�@�C��
    l_out_cnt_tab(7).target  := gt_prf_val_emp_inf_out_file;
    l_out_cnt_tab(7).cnt     := TO_CHAR(gn_out_p_emp_info_cnt);
-- Ver1.17 Add Start
    -- PaaS�����p�̐V���Ј����t�@�C��
    l_out_cnt_tab(8).target  := gt_prf_val_new_emp_out_file;
    l_out_cnt_tab(8).cnt     := TO_CHAR(gn_out_p_new_emp_cnt);
-- Ver1.17 Add End
    --
    <<out_count_out_loop>>
    FOR i IN 1..l_out_cnt_tab.COUNT LOOP
      --
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k���FXXCMM
                , iv_name         => cv_file_trgt_cnt_msg      -- ���b�Z�[�W���F�t�@�C���o�͑ΏہE�������b�Z�[�W
                , iv_token_name1  => cv_tkn_target             -- �g�[�N����1�FTARGET
                , iv_token_value1 => l_out_cnt_tab(i).target   -- �g�[�N���l1�F�o�͑Ώ�
                , iv_token_name2  => cv_tkn_count              -- �g�[�N����2�FCOUNT
                , iv_token_value2 => l_out_cnt_tab(i).cnt      -- �g�[�N���l2�F�o�͌���
                );
      --
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_msg
      );
    END LOOP out_count_out_loop;
    --
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -------------------------------------------------
    -- ���v�����̏o��
    -------------------------------------------------
    -- �Ώی����i���o�����̍��v�j��ݒ�
    gn_target_cnt := gn_get_wk_cnt +
                     gn_get_per_name_cnt +
                     gn_get_per_legi_cnt +
                     gn_get_per_email_cnt +
                     gn_get_wk_rel_cnt +
                     gn_get_new_user_cnt +
                     gn_get_new_user_paas_cnt +
                     gn_get_wk_terms_cnt +
                     gn_get_ass_cnt +
                     gn_get_user_cnt +
-- Ver1.2(E055) Add Start
                     gn_get_user2_cnt +
-- Ver1.2(E055) Add End
                     gn_get_ass_sup_cnt +
                     gn_get_wk_rel2_cnt +
                     gn_get_bank_acc_cnt +
                     gn_get_emp_info_cnt;
    --
    -- ���������i�o�͌����̍��v�j��ݒ�
    gn_normal_cnt := gn_out_wk_cnt +
                     gn_out_p_new_user_cnt +
                     gn_out_user_cnt +
-- Ver1.2(E055) Add Start
                     gn_out_user2_cnt +
-- Ver1.2(E055) Add End
                     gn_out_wk2_cnt +
                     gn_out_p_bank_acct_cnt +
-- Ver1.17 Mod Start
--                     gn_out_p_emp_info_cnt;
                     gn_out_p_emp_info_cnt +
                     gn_out_p_new_emp_cnt;
-- Ver1.17 Mod End
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
END XXCMM002A10C;
/
