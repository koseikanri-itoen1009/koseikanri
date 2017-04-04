CREATE OR REPLACE PACKAGE BODY XXCMM002A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM002A07C(body)
 * Description      : �Ј��}�X�^�A�g�ieSM�j
 * MD.050           : MD050_CMM_002_A07_�Ј��}�X�^�A�g�ieSM�j
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  open_csv_file          �t�@�C���I�[�v������(A-2)
 *  get_emp_data           �]�ƈ��f�[�^�擾����(A-3)
 *  output_csv_data        CSV�t�@�C���o�͏���(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������(A-5)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/02/15    1.0   S.Niki           �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE         := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE         := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE         := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3)  := '.';
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
  global_init_err_expt      EXCEPTION; -- ���������G���[
  global_f_open_err_expt    EXCEPTION; -- �t�@�C���I�[�v���G���[
  global_write_err_expt     EXCEPTION; -- CSV�f�[�^�o�̓G���[
  global_f_close_err_expt   EXCEPTION; -- �t�@�C���N���[�Y�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(12)  := 'XXCMM002A07C';         -- �p�b�P�[�W��
  -- �A�v���P�[�V�����Z�k��
  cv_appl_xxcmm             CONSTANT VARCHAR2(5)   := 'XXCMM';                -- �A�h�I���F�}�X�^�E�}�X�^�̈�
  cv_appl_xxccp             CONSTANT VARCHAR2(5)   := 'XXCCP';                -- �A�h�I���F���ʁEIF�̈�
--
  -- ������
  cv_comma                  CONSTANT VARCHAR2(1)   := ',';                    -- �J���}
  cv_space_full             CONSTANT VARCHAR2(2)   := '�@';                   -- �S�p�X�y�[�X
  cv_hyphen                 CONSTANT VARCHAR2(1)   := '-';                    -- �n�C�t��
--
  -- �v���t�@�C��
  cv_prf_org_id             CONSTANT VARCHAR2(30)  := 'ORG_ID';                         -- �c�ƒP��ID
  cv_prf_out_file_dir       CONSTANT VARCHAR2(30)  := 'XXCMM1_JIHANKI_OUT_DIR';         -- CSV�t�@�C���o�͐�
  cv_prf_out_file_name      CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_OUT_FILE';         -- CSV�t�@�C����
  cv_prf_stop_bumon         CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_STOP_BUMON';       -- ���p��~������
  cv_prf_other_wk_honbu     CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_OTHER_WK_HONBU';   -- ���̒S���Ɩ��i�{���c�Ɓj
  cv_prf_other_wk_tenpo     CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_OTHER_WK_TENPO';   -- ���̒S���Ɩ��i�X�܉c�Ɓj
  cv_prf_other_wk_shanai    CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_OTHER_WK_SHANAI';  -- ���̒S���Ɩ��i�Г��Ɩ��j
  cv_prf_licensed_prdcts    CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_LICENSED_PRDCTS';  -- ���C�Z���X���鐻�i
  cv_prf_timezone           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_TIMEZONE';         -- �^�C���]�[��
  cv_prf_date_format        CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_DATE_FORMAT';      -- ���t�t�H�[�}�b�g
  cv_prf_language           CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_LANGUAGE';         -- ����
  cv_prf_holiday_pattern    CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_HOLIDAY_PATTERN';  -- �x���p�^�[��
  cv_prf_role               CONSTANT VARCHAR2(30)  := 'XXCMM1_002A07_ROLE';             -- ���[��
--
  -- �^�C�v
  cv_lkp_qual_code          CONSTANT VARCHAR2(30)  := 'XXCMM_QUALIFICATION_CODE';       -- ���i�R�[�h
  cv_lkp_posi_code          CONSTANT VARCHAR2(30)  := 'XXCMM_POSITION_CODE';            -- �E�ʃR�[�h
  cv_lkp_main_work          CONSTANT VARCHAR2(30)  := 'XXCSO1_ESM_MAIN_WORK';           -- ��Ɩ�
--
  -- ���b�Z�[�W
  cv_file_name_msg          CONSTANT VARCHAR2(16)  := 'APP-XXCCP1-05102';     -- �t�@�C�������b�Z�[�W
  cv_input_param_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00225';     -- ���̓p�����[�^������
  cv_csv_header_msg         CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00226';     -- CSV�w�b�_������
  cv_process_date_err_msg   CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00018';     -- �Ɩ����t�擾�G���[���b�Z�[�W
  cv_profile_err_msg        CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00002';     -- �v���t�@�C���擾�G���[
  cv_date_reversal_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00227';     -- �ŏI�X�V���t�]�`�F�b�N�G���[
  cv_e_date_select_err_msg  CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00220';     -- �ŏI�X�V���i�I���j�w��G���[
  cv_file_exists_err_msg    CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00010';     -- �t�@�C���쐬�ς݃G���[
  cv_main_work_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00228';     -- eSM��Ɩ����ݒ�G���[
  cv_resource_err_msg       CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00229';     -- ���\�[�X�O���[�v�����d���G���[
  cv_file_open_err_msg      CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00487';     -- �t�@�C���I�[�v���G���[
  cv_file_write_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00488';     -- CSV�f�[�^�o�̓G���[
  cv_file_close_err_msg     CONSTANT VARCHAR2(16)  := 'APP-XXCMM1-00489';     -- �t�@�C���N���[�Y�G���[
--
  -- �g�[�N��
  cv_tkn_date_from          CONSTANT VARCHAR2(30)  := 'DATE_FROM';            -- �J�n��
  cv_tkn_date_to            CONSTANT VARCHAR2(30)  := 'DATE_TO';              -- �I����
  cv_tkn_file_name          CONSTANT VARCHAR2(30)  := 'FILE_NAME';            -- CSV�t�@�C����
  cv_tkn_ng_profile         CONSTANT VARCHAR2(30)  := 'NG_PROFILE';           -- �v���t�@�C����
  cv_tkn_sqlerrm            CONSTANT VARCHAR2(30)  := 'SQLERRM';              -- SQL�G���[���b�Z�[�W
  cv_tkn_employee_number    CONSTANT VARCHAR2(30)  := 'EMPLOYEE_NUMBER';      -- �]�ƈ��ԍ�
  cv_tkn_start_date_active  CONSTANT VARCHAR2(30)  := 'START_DATE_ACTIVE';    -- �K�p�J�n��
--
  cv_fmt_std                CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';           -- ���t�����FYYYY/MM/DD
  cv_max_date               CONSTANT VARCHAR2(10)  := '9999/12/31';           -- �ő���t
  ct_lang                   CONSTANT fnd_lookup_values.language%TYPE
                                                   := USERENV('LANG');        -- ����
  cv_category_emp           CONSTANT VARCHAR2(8)   := 'EMPLOYEE';             -- �J�e�S���F�]�ƈ�
  cv_resource_type_gm       CONSTANT VARCHAR2(15)  := 'RS_GROUP_MEMBER';      -- ���\�[�X�^�C�v�F�O���[�v�����o�[
  cv_cust_class_base        CONSTANT VARCHAR2(1)   := '1';                    -- �ڋq�敪�F���_
  cv_flag_y                 CONSTANT VARCHAR2(1)   := 'Y';                    -- �t���O�FY
  cv_flag_n                 CONSTANT VARCHAR2(1)   := 'N';                    -- �t���O�FN
  cv_main_wk_honbu          CONSTANT VARCHAR2(1)   := '1';                    -- ��Ɩ��F�{���c��
  cv_main_wk_tenpo          CONSTANT VARCHAR2(1)   := '2';                    -- ��Ɩ��F�X�܉c��
  cv_main_wk_shanai         CONSTANT VARCHAR2(1)   := '3';                    -- ��Ɩ��F�Г��Ɩ�
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gd_process_date           DATE;                -- �Ɩ����t
  gf_file_handler           UTL_FILE.FILE_TYPE;  -- �t�@�C���E�n���h��
--
  gd_active_s_date          DATE;                -- �K�p��(�J�n)
  gd_active_e_date          DATE;                -- �K�p��(�I��)
  gd_update_s_date          DATE;                -- �ŏI�X�V��(�J�n)
  gd_update_e_date          DATE;                -- �ŏI�X�V��(�I��)
--
  -- �v���t�@�C��
  gt_org_id                 mtl_parameters.organization_id%TYPE;
                                                 -- �c�ƒP��ID
  gv_out_file_dir           VARCHAR2(100);       -- CSV�t�@�C���o�͐�
  gv_out_file_name          VARCHAR2(100);       -- CSV�t�@�C����
  gv_stop_bumon             VARCHAR2(100);       -- ���p��~������
  gv_other_wk_honbu         VARCHAR2(500);       -- ���̒S���Ɩ��i�{���c�Ɓj
  gv_other_wk_tenpo         VARCHAR2(500);       -- ���̒S���Ɩ��i�X�܉c�Ɓj
  gv_other_wk_shanai        VARCHAR2(500);       -- ���̒S���Ɩ��i�Г��Ɩ��j
  gv_licensed_prdcts        VARCHAR2(500);       -- ���C�Z���X���鐻�i
  gv_timezone               VARCHAR2(100);       -- �^�C���]�[��
  gv_date_format            VARCHAR2(100);       -- ���t�t�H�[�}�b�g
  gv_language               VARCHAR2(100);       -- ����
  gv_holiday_pattern        VARCHAR2(100);       -- �x���p�^�[��
  gv_role                   VARCHAR2(500);       -- ���[��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  CURSOR get_emp_data_cur
  IS
    SELECT /*+
             INDEX( jrrr JTF_RS_ROLE_RELATIONS_N1 )
           */
           papf.employee_number                    AS employee_number     -- �Ј��ԍ�
         , papf.per_information18
             || cv_space_full
             || papf.per_information19             AS employee_name       -- �Ј�����
         , papf.last_name
             || cv_space_full
             || papf.first_name                    AS employee_name_kana  -- �Ј�����(�J�i)
         , flvq.job_duty_name                      AS job_duty_name1      -- ��E��1
         , flvp.job_duty_name                      AS job_duty_name2      -- ��E��2
         , NVL( flvq.un_licence_kbn ,cv_flag_n )   AS un_licence_kbn      -- ���i���C�Z���X�s�v�敪
         , hp.party_name                           AS location_name       -- ������
         , papf.attribute28                        AS location_code       -- �����ԍ�
         , SUBSTRB( hl.postal_code ,1 ,3 )
             || cv_hyphen
             || SUBSTRB( hl.postal_code ,4 ,4 )    AS postal_code         -- �X�֔ԍ�
         , hl.state
             || hl.city
             || hl.address1
             || hl.address2                        AS address             -- �Z��
         , jrrr.start_date_active                  AS start_date_active   -- ���\�[�X�O���[�v�����J�n��
         , ( CASE
               WHEN ppos.actual_termination_date IS NOT NULL THEN
                 cv_flag_n
               ELSE
                 jrrr.attribute1
             END )                                 AS emp_enabled_flag    -- �]�ƈ��L���t���O
         , jrrr.attribute2                         AS main_work           -- ��Ɩ�
         , flvm.main_work_name                     AS main_work_name      -- ��Ɩ���
      FROM jtf_rs_resource_extns   jrse      -- ���\�[�X�}�X�^
         , jtf_rs_group_members    jrgm      -- ���\�[�X�O���[�v�����o�[
         , jtf_rs_groups_vl        jrgv      -- ���\�[�X�O���[�v
         , jtf_rs_role_relations   jrrr      -- ���\�[�X�O���[�v����
         , per_all_people_f        papf      -- �]�ƈ��}�X�^
         , per_all_assignments_f   paaf      -- �A�T�C�����g�}�X�^
         , per_periods_of_service  ppos      -- �]�ƈ��T�[�r�X���ԃ}�X�^
         , hz_cust_accounts        hca       -- �ڋq�}�X�^
         , hz_parties              hp        -- �p�[�e�B�}�X�^
         , hz_party_sites          hps       -- �p�[�e�B�T�C�g�}�X�^
         , hz_cust_acct_sites_all  hcasa     -- �ڋq���ݒn�}�X�^
         , hz_locations            hl        -- �ڋq���Ə��}�X�^
         , ( SELECT flv.lookup_code       AS qual_code
                  , flv.attribute1        AS job_duty_name
                  , flv.attribute2        AS un_licence_kbn
               FROM fnd_lookup_values flv
              WHERE flv.language     = ct_lang
                AND flv.lookup_type  = cv_lkp_qual_code      -- �^�C�v�F���i�R�[�h
                AND flv.enabled_flag = cv_flag_y
           )                       flvq      -- LOOKUP�\(���i)
         , ( SELECT flv.lookup_code       AS posi_code
                  , flv.attribute1        AS job_duty_name
               FROM fnd_lookup_values flv
              WHERE flv.language     = ct_lang
                AND flv.lookup_type  = cv_lkp_posi_code      -- �^�C�v�F�E�ʃR�[�h
                AND flv.enabled_flag = cv_flag_y
           )                       flvp      -- LOOKUP�\(�E��)
         , ( SELECT flv.lookup_code       AS main_work
                  , flv.description       AS main_work_name
               FROM fnd_lookup_values flv
              WHERE flv.language     = ct_lang
                AND flv.lookup_type  = cv_lkp_main_work      -- �^�C�v�FeSM��Ɩ�
                AND flv.enabled_flag = cv_flag_y
           )                       flvm      -- LOOKUP�\(��Ɩ�)
     WHERE jrse.category                       = cv_category_emp            -- �J�e�S���F�]�ƈ�
       AND jrse.resource_id                    = jrgm.resource_id
       AND NVL( jrgm.delete_flag ,cv_flag_n )  = cv_flag_n
       AND jrgm.group_id                       = jrgv.group_id
       AND jrgm.group_member_id                = jrrr.role_resource_id
       AND jrrr.role_resource_type             = cv_resource_type_gm
       AND NVL( jrrr.delete_flag ,cv_flag_n )  = cv_flag_n
       AND (
             -- ���\�[�X�O���[�v�����̊J�n��
             ( jrrr.start_date_active         >= gd_active_s_date )
             -- ���\�[�X�O���[�v�����̍ŏI�X�V��
         OR  ( TRUNC( jrrr.last_update_date ) >= gd_update_s_date
           AND TRUNC( jrrr.last_update_date ) <= gd_update_e_date )
             -- �]�ƈ��}�X�^�̍ŏI�X�V��
         OR  ( TRUNC( papf.last_update_date ) >= gd_update_s_date
           AND TRUNC( papf.last_update_date ) <= gd_update_e_date )
             -- �p�[�e�B�}�X�^�̍ŏI�X�V��
         OR  ( TRUNC( hp.last_update_date )   >= gd_update_s_date
           AND TRUNC( hp.last_update_date )   <= gd_update_e_date )
             -- �ڋq���Ə��}�X�^�̍ŏI�X�V��
         OR  ( TRUNC( hl.last_update_date )   >= gd_update_s_date
           AND TRUNC( hl.last_update_date )   <= gd_update_e_date )
           )
       AND jrrr.start_date_active             <= gd_active_e_date
       AND jrse.source_id                      = papf.person_id
       AND papf.person_id                      = paaf.person_id
       AND paaf.period_of_service_id           = ppos.period_of_service_id
       AND papf.effective_start_date           = ppos.date_start
       AND papf.attribute28                    = ( CASE
                                                     WHEN ppos.actual_termination_date IS NOT NULL THEN
                                                       papf.attribute28
                                                     ELSE
                                                       jrgv.attribute1
                                                   END )
       AND gd_process_date                     BETWEEN papf.effective_start_date
                                                   AND TO_DATE( cv_max_date ,cv_fmt_std )
       AND gd_process_date                     BETWEEN paaf.effective_start_date
                                                   AND TO_DATE( cv_max_date ,cv_fmt_std )
       AND hca.customer_class_code             = cv_cust_class_base         -- �ڋq�敪�F���_
       AND hca.cust_account_id                 = hcasa.cust_account_id
       AND hca.party_id                        = hp.party_id
       AND hcasa.party_site_id                 = hps.party_site_id
       AND hps.location_id                     = hl.location_id
       AND hcasa.org_id                        = gt_org_id                  -- �c�ƒP��ID
       AND hca.account_number                  = papf.attribute28           -- ��������
       AND papf.attribute7                     = flvq.qual_code             -- ���i�R�[�h
       AND papf.attribute11                    = flvp.posi_code             -- �E�ʃR�[�h
       AND jrrr.attribute2                     = flvm.main_work(+)          -- ��Ɩ�
       AND jrrr.attribute1                     IS NOT NULL
    ORDER BY
           papf.employee_number    ASC    -- �]�ƈ��ԍ�
         , jrrr.start_date_active  DESC   -- �J�n���i�~���j
         , jrrr.last_update_date   DESC   -- �ŏI�X�V���i�~���j
    ;
--
  TYPE g_emp_data_ttype IS TABLE OF get_emp_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_emp_data           g_emp_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_update_from  IN  VARCHAR2     --  �ŏI�X�V���i�J�n�j
  , iv_update_to    IN  VARCHAR2     --  �ŏI�X�V���i�I���j
  , ov_errbuf       OUT VARCHAR2     --  �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode      OUT VARCHAR2     --  ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg       OUT VARCHAR2     --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
--
    -- *** ���[�J���ϐ� ***
    lb_fexists              BOOLEAN;          -- �t�@�C�������݂��邩�ǂ���
    ln_file_length          NUMBER;           -- �t�@�C����
    ln_block_size           NUMBER;           -- �u���b�N�T�C�Y
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
    --================================
    -- ���̓p�����[�^�o��
    --================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k��
                 , iv_name         => cv_input_param_msg        -- ���b�Z�[�W�R�[�h
                 , iv_token_name1  => cv_tkn_date_from          -- �g�[�N���R�[�h1
                 , iv_token_value1 => iv_update_from            -- �g�[�N���l1
                 , iv_token_name2  => cv_tkn_date_to            -- �g�[�N���R�[�h2
                 , iv_token_value2 => iv_update_to              -- �g�[�N���l2
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
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --================================
    -- �Ɩ����t�擾
    --================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_xxcmm            -- �A�v���P�[�V�����Z�k��
                   , iv_name        => cv_process_date_err_msg  -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    --================================
    -- �������ԁi�J�n���E�I�����j�擾
    --================================
    IF  ( iv_update_from IS NULL )
      AND ( iv_update_to IS NULL ) THEN
      -- �K�p���i�J�n�j�A�K�p���i�I���j�ɋƖ����t�{1���Z�b�g
      gd_active_s_date := gd_process_date + 1;
      gd_active_e_date := gd_process_date + 1;
      -- �ŏI�X�V���i�J�n�j�A�ŏI�X�V���i�I���j�ɋƖ����t���Z�b�g
      gd_update_s_date := gd_process_date;
      gd_update_e_date := gd_process_date + 1;
    ELSE
      -- �K�p���i�J�n�j�A�K�p���i�I���j�ɓ��̓p�����[�^�l���Z�b�g
      gd_active_s_date := TO_DATE( iv_update_from ,cv_fmt_std );
      gd_active_e_date := TO_DATE( iv_update_to   ,cv_fmt_std );
      -- �ŏI�X�V���ɓK�p���Ɠ����l���Z�b�g
      gd_update_s_date := gd_active_s_date;
      gd_update_e_date := gd_active_e_date;
    END IF;
--
    --================================
    -- �����Ώۊ��ԃ`�F�b�N
    --================================
    -- �ŏI�X�V���i�J�n�j > �ŏI�X�V���i�I���j�̏ꍇ
    IF ( gd_update_s_date > gd_update_e_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm               -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_date_reversal_err_msg    -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    --================================
    -- �I�����`�F�b�N
    --================================
    -- ���̓p�����[�^.�ŏI�X�V���i�I���j �� �Ɩ����t�̏ꍇ
    IF ( TO_DATE( iv_update_to ,cv_fmt_std ) <> gd_process_date ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm               -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_e_date_select_err_msg    -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    --================================
    -- �v���t�@�C���l�擾
    --================================
    -- *******************************
    --  �c�ƒP��
    -- *******************************
    gt_org_id := FND_PROFILE.VALUE( cv_prf_org_id );
    -- �擾�l��NULL�̏ꍇ
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_org_id           -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  CSV�t�@�C���o�͐�
    -- *******************************
    gv_out_file_dir := FND_PROFILE.VALUE( cv_prf_out_file_dir );
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_out_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_out_file_dir     -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  CSV�t�@�C����
    -- *******************************
    gv_out_file_name := FND_PROFILE.VALUE( cv_prf_out_file_name );
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_out_file_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_out_file_name    -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  ���p��~����
    -- *******************************
    gv_stop_bumon := FND_PROFILE.VALUE( cv_prf_stop_bumon );
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_stop_bumon IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_stop_bumon       -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  ���̒S���Ɩ��i�{���c�Ɓj
    -- *******************************
    gv_other_wk_honbu := FND_PROFILE.VALUE( cv_prf_other_wk_honbu );
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_other_wk_honbu IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_other_wk_honbu   -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  ���̒S���Ɩ��i�X�܉c�Ɓj
    -- *******************************
    gv_other_wk_tenpo := FND_PROFILE.VALUE( cv_prf_other_wk_tenpo );
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_other_wk_tenpo IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_other_wk_tenpo   -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  ���̒S���Ɩ��i�Г��Ɩ��j
    -- *******************************
    gv_other_wk_shanai := FND_PROFILE.VALUE( cv_prf_other_wk_shanai );
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_other_wk_shanai IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_other_wk_shanai  -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  ���C�Z���X���鐻�i
    -- *******************************
    gv_licensed_prdcts := FND_PROFILE.VALUE( cv_prf_licensed_prdcts );
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_licensed_prdcts IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_licensed_prdcts  -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  �^�C���]�[��
    -- *******************************
    gv_timezone := FND_PROFILE.VALUE( cv_prf_timezone );
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_timezone IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_timezone         -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  ���t�t�H�[�}�b�g
    -- *******************************
    gv_date_format := FND_PROFILE.VALUE( cv_prf_date_format );
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_date_format IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_date_format      -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  ����
    -- *******************************
    gv_language := FND_PROFILE.VALUE( cv_prf_language );
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_language IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_language         -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  �x���p�^�[��
    -- *******************************
    gv_holiday_pattern := FND_PROFILE.VALUE( cv_prf_holiday_pattern );
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_holiday_pattern IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_holiday_pattern  -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- *******************************
    --  ���[��
    -- *******************************
    gv_role := FND_PROFILE.VALUE( cv_prf_role );
    -- �擾�l��NULL�̏ꍇ
    IF ( gv_role IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                   , iv_name         => cv_profile_err_msg      -- ���b�Z�[�W�R�[�h
                   , iv_token_name1  => cv_tkn_ng_profile       -- �g�[�N���R�[�h1
                   , iv_token_value1 => cv_prf_role             -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    --================================
    -- CSV�t�@�C�����o��
    --================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_xxccp             -- �A�v���P�[�V�����Z�k��
                 , iv_name         => cv_file_name_msg          -- ���b�Z�[�W�R�[�h
                 , iv_token_name1  => cv_tkn_file_name          -- �g�[�N���R�[�h1
                 , iv_token_value1 => gv_out_file_name          -- �g�[�N���l1
                 );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => lv_errmsg
    );
--
    --================================
    -- CSV�t�@�C�����݃`�F�b�N
    --================================
    UTL_FILE.FGETATTR(
      location     => gv_out_file_dir     -- CSV�t�@�C���o�͐�
    , filename     => gv_out_file_name    -- CSV�t�@�C����
    , fexists      => lb_fexists
    , file_length  => ln_file_length
    , block_size   => ln_block_size
    );
    IF ( lb_fexists = TRUE ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k��
                   , iv_name        => cv_file_exists_err_msg    -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_init_err_expt;
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
  EXCEPTION
    --*** ����������O ***
    WHEN global_init_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
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
   * Procedure Name   : open_csv_file
   * Description      : �t�@�C���I�[�v������(A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    ov_errbuf       OUT VARCHAR2             --   �G���[�E���b�Z�[�W                  --# �Œ� #
  , ov_retcode      OUT VARCHAR2             --   ���^�[���E�R�[�h                    --# �Œ� #
  , ov_errmsg       OUT VARCHAR2             --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    cn_record_byte  CONSTANT NUMBER       := 5000;  -- �t�@�C���ǂݍ��ݕ�����
    cv_file_mode    CONSTANT VARCHAR2(1)  := 'W';   -- �������݃��[�h
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
    BEGIN
      --================================
      -- �t�@�C���I�[�v��
      --================================
      gf_file_handler := UTL_FILE.FOPEN(
                           location      => gv_out_file_dir      -- CSV�t�@�C���o�͐�
                         , filename      => gv_out_file_name     -- CSV�t�@�C����
                         , open_mode     => cv_file_mode         -- �������݃��[�h
                         , max_linesize  => cn_record_byte
                         );
    EXCEPTION
      -- �t�@�C���I�[�v���G���[
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm              -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_file_open_err_msg       -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_sqlerrm             -- �g�[�N���R�[�h1
                     , iv_token_value1 => SQLERRM                    -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_f_open_err_expt;
    END;
--
  EXCEPTION
    --*** �t�@�C���I�[�v���G���[ ***
    WHEN global_f_open_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : get_emp_data
   * Description      : �]�ƈ��f�[�^�擾����(A-3)
   ***********************************************************************************/
  PROCEDURE get_emp_data(
    ov_errbuf     OUT VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode    OUT VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg     OUT VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_emp_data';       -- �v���O������
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
    -- �J�[�\���I�[�v��
    OPEN get_emp_data_cur;
    FETCH get_emp_data_cur BULK COLLECT INTO gt_emp_data;
--
    -- �Ώی����J�E���g
    gn_target_cnt := gt_emp_data.COUNT;
--
    -- �J�[�\���N���[�Y
    CLOSE get_emp_data_cur;
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
  END get_emp_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv_data
   * Description      : CSV�t�@�C���o�͏���(A-4)
   ***********************************************************************************/
  PROCEDURE output_csv_data(
    ov_errbuf               OUT VARCHAR2               --   �G���[�E���b�Z�[�W                  --# �Œ� #
  , ov_retcode              OUT VARCHAR2               --   ���^�[���E�R�[�h                    --# �Œ� #
  , ov_errmsg               OUT VARCHAR2               --   ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'output_csv_data'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    ln_cnt                 NUMBER;               -- ���[�v�J�E���^
    lv_hdr_text            VARCHAR2(2000);       -- �w�b�_������i�[�p�ϐ�
    lv_csv_text            VARCHAR2(5000);       -- �o�͕�����i�[�p�ϐ�
--
    lt_employee_number     per_all_people_f.employee_number%TYPE;
                                                 -- �]�ƈ��ԍ��ޔ�p
    lv_job_duty_name       VARCHAR2(100);        -- ��E��
    lv_location_name       VARCHAR2(50);         -- ������
    lv_location_code       VARCHAR2(9);          -- �����ԍ�
    lv_other_work          VARCHAR2(500);        -- ���̒S���Ɩ�
    lv_licensed_prdcts     VARCHAR2(500);        -- ���C�Z���X���鐻�i
    lv_role                VARCHAR2(500);        -- ���[��
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    BEGIN
--
      -- ���[�J���ϐ��̏�����
      lt_employee_number := NULL;  -- �]�ƈ��ԍ��ޔ�p
--
      -- ===============================
      -- CSV�t�@�C���w�b�_�擾
      -- ===============================
      lv_hdr_text := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm       -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_csv_header_msg   -- ���b�Z�[�W�R�[�h
                     );
--
      -- ===============================
      -- CSV�t�@�C���w�b�_�o��
      -- ===============================
      -- �t�@�C����������
      UTL_FILE.PUT_LINE(
        file      => gf_file_handler
      , buffer    => lv_hdr_text
      , autoflush => FALSE
      );
--
      -- ===============================
      -- �]�ƈ��f�[�^�o��
      -- ===============================
      -- �Ώۃ��R�[�h�����݂���ꍇ
      IF ( gn_target_cnt > 0 ) THEN
--
        <<emp_data_loop>>
        FOR ln_cnt IN gt_emp_data.FIRST..gt_emp_data.LAST LOOP
--
          -- *******************************
          --  ��Ɩ�NULL�`�F�b�N
          -- *******************************
          IF ( gt_emp_data(ln_cnt).main_work IS NULL ) THEN
--
           -- eSM��Ɩ����ݒ�G���[
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_xxcmm                         -- �A�v���P�[�V�����Z�k��
                         , iv_name         => cv_main_work_err_msg                  -- ���b�Z�[�W�R�[�h
                         , iv_token_name1  => cv_tkn_employee_number                -- �g�[�N���R�[�h1
                         , iv_token_value1 => gt_emp_data(ln_cnt).employee_number   -- �g�[�N���l1
                         , iv_token_name2  => cv_tkn_start_date_active              -- �g�[�N���R�[�h2
                         , iv_token_value2 => TO_CHAR( gt_emp_data(ln_cnt).start_date_active ,cv_fmt_std )
                                                                                    -- �g�[�N���l2
                         );
            -- ���b�Z�[�W�o��
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
            , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
            );
            -- �X�L�b�v�����J�E���g
            gn_warn_cnt := gn_warn_cnt + 1;
--
          -- ��L�ȊO�̏ꍇ
          ELSE
--
            -- *******************************
            --  ���\�[�X�O���[�v�����d���`�F�b�N
            -- *******************************
            -- �ŏ��̃��R�[�h�A�܂��͑O���R�[�h�Ə]�ƈ��ԍ����قȂ�ꍇ
            IF ( lt_employee_number IS NULL )
              OR ( lt_employee_number <> gt_emp_data(ln_cnt).employee_number ) THEN
--
              -- ���[�J���ϐ��̏�����
              lv_job_duty_name   := NULL;  -- ��E��
              lv_location_name   := NULL;  -- ������
              lv_location_code   := NULL;  -- �����ԍ�
              lv_other_work      := NULL;  -- ���̒S���Ɩ�
              lv_licensed_prdcts := NULL;  -- ���C�Z���X���鐻�i
              lv_role            := NULL;  -- ���[��
--
              -- *******************************
              --  CSV�o�͒l�ݒ�
              -- *******************************
              -- ��E1��NULL�ȊO�̏ꍇ
              IF ( gt_emp_data(ln_cnt).job_duty_name1 IS NOT NULL ) THEN
                -- ��E��
                lv_job_duty_name   := SUBSTRB ( gt_emp_data(ln_cnt).job_duty_name1 ,1 ,100 );
              ELSE
                -- ��E��
                lv_job_duty_name   := SUBSTRB ( gt_emp_data(ln_cnt).job_duty_name2 ,1 ,100 );
              END IF;
--
              -- �L���ȎЈ��̏ꍇ
              IF ( gt_emp_data(ln_cnt).emp_enabled_flag = cv_flag_y ) THEN
                -- ������
                lv_location_name   := SUBSTRB ( REPLACE( gt_emp_data(ln_cnt).location_name ,cv_comma ,NULL ) ,1 ,50 );
                -- �����ԍ�
                lv_location_code   := gt_emp_data(ln_cnt).location_code;
                -- ���C�Z���X���鐻�i
                lv_licensed_prdcts := gv_licensed_prdcts;
                -- ���[��
                lv_role            := gv_role;
              ELSE
                -- ������
                lv_location_name   := NULL;
                -- �����ԍ�
                lv_location_code   := gv_stop_bumon;
                -- ���C�Z���X���鐻�i
                lv_licensed_prdcts := NULL;
                -- ���[��
                lv_role            := NULL;
              END IF;
--
              -- ���C�Z���X�s�v�̏ꍇ
              IF ( gt_emp_data(ln_cnt).un_licence_kbn = cv_flag_y ) THEN
                -- ���C�Z���X���鐻�i
                lv_licensed_prdcts := NULL;
              END IF;
--
              -- ��Ɩ����u�{���c�Ɓv�̏ꍇ
              IF ( gt_emp_data(ln_cnt).main_work = cv_main_wk_honbu ) THEN
                -- ���̒S���Ɩ�
                lv_other_work      := gv_other_wk_honbu;
              -- ��Ɩ����u�X�܉c�Ɓv�̏ꍇ
              ELSIF ( gt_emp_data(ln_cnt).main_work = cv_main_wk_tenpo ) THEN
                -- ���̒S���Ɩ�
                lv_other_work      := gv_other_wk_tenpo;
              -- ��Ɩ����u�Г��Ɩ��v�̏ꍇ
              ELSIF ( gt_emp_data(ln_cnt).main_work = cv_main_wk_shanai ) THEN
                -- ���̒S���Ɩ�
                lv_other_work      := gv_other_wk_shanai;
              ELSE
                -- ���̒S���Ɩ�
                lv_other_work      := NULL;
              END IF;
--
              -- *******************************
              --  �o�͕�����̐���
              -- *******************************
              lv_csv_text :=   SUBSTRB( gt_emp_data(ln_cnt).employee_number ,1 ,50 )  -- �Ј��ԍ�
                || cv_comma || SUBSTRB( REPLACE( gt_emp_data(ln_cnt).employee_name ,cv_comma ,NULL ) ,1 ,100 )
                                                                                      -- �Ј�����
                || cv_comma || SUBSTRB( REPLACE( gt_emp_data(ln_cnt).employee_name_kana ,cv_comma ,NULL ) ,1 ,50 )
                                                                                      -- �Ј������i�J�i�j
                || cv_comma || lv_job_duty_name                                       -- ��E��
                || cv_comma || lv_location_name                                       -- ������
                || cv_comma || lv_location_code                                       -- �����ԍ�
                || cv_comma || gt_emp_data(ln_cnt).postal_code                        -- �X�֔ԍ�
                || cv_comma || SUBSTRB( REPLACE( gt_emp_data(ln_cnt).address ,cv_comma ,NULL ) ,1 ,900 )
                                                                                      -- �Z��
                || cv_comma || NULL                                                   -- �d�b�ԍ�
                || cv_comma || NULL                                                   -- �d�b�ԍ�2
                || cv_comma || NULL                                                   -- �d�b�ԍ�3
                || cv_comma || NULL                                                   -- email
                || cv_comma || NULL                                                   -- �p�X���[�h
                || cv_comma || SUBSTRB( gt_emp_data(ln_cnt).main_work_name ,1 ,60 )   -- ��Ɩ�
                || cv_comma || lv_other_work                                          -- ���̒S���Ɩ�
                || cv_comma || lv_licensed_prdcts                                     -- ���C�Z���X���鐻�i
                || cv_comma || NULL                                                   -- �g�ђ[��ID
                || cv_comma || gv_timezone                                            -- �^�C���]�[��
                || cv_comma || gv_date_format                                         -- ���t�t�H�[�}�b�g
                || cv_comma || gv_language                                            -- ����
                || cv_comma || gv_holiday_pattern                                     -- �x���p�^�[��
                || cv_comma || lv_role                                                -- ���[��
                || cv_comma || NULL                                                   -- ������
                || cv_comma || NULL                                                   -- �u���Z�~�i�[
              ;
--
              -- *******************************
              --  CSV�t�@�C����������
              -- *******************************
              UTL_FILE.PUT_LINE(
                file      => gf_file_handler
              , buffer    => lv_csv_text
              , autoflush => FALSE
              );
--
              -- ���������J�E���g
              gn_normal_cnt := gn_normal_cnt + 1;
              -- �]�ƈ��ԍ��ޔ�
              lt_employee_number := gt_emp_data(ln_cnt).employee_number;
--
            -- ��L�ȊO�̏ꍇ
            ELSE
              -- ���\�[�X�O���[�v�����d���G���[
              lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_xxcmm                         -- �A�v���P�[�V�����Z�k��
                           , iv_name         => cv_resource_err_msg                   -- ���b�Z�[�W�R�[�h
                           , iv_token_name1  => cv_tkn_employee_number                -- �g�[�N���R�[�h1
                           , iv_token_value1 => gt_emp_data(ln_cnt).employee_number   -- �g�[�N���l1
                           , iv_token_name2  => cv_tkn_start_date_active              -- �g�[�N���R�[�h2
                           , iv_token_value2 => TO_CHAR( gt_emp_data(ln_cnt).start_date_active ,cv_fmt_std )
                                                                                      -- �g�[�N���l2
                           );
              -- ���b�Z�[�W�o��
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
              , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
              );
              -- �X�L�b�v�����J�E���g
              gn_warn_cnt := gn_warn_cnt + 1;
            END IF;
--
          END IF;
--
        END LOOP emp_data_loop;
--
      END IF;
--
    EXCEPTION
      -- CSV�f�[�^�o�̓G���[
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_xxcmm             -- �A�v���P�[�V�����Z�k��
                     , iv_name         => cv_file_write_err_msg     -- ���b�Z�[�W�R�[�h
                     , iv_token_name1  => cv_tkn_sqlerrm            -- �g�[�N���R�[�h1
                     , iv_token_value1 => SQLERRM                   -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
    END;
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
  END output_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf                 OUT VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
  , ov_retcode                OUT VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
  , ov_errmsg                 OUT VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  , iv_update_from            IN  VARCHAR2    -- �ŏI�X�V���i�J�n�j
  , iv_update_to              IN  VARCHAR2    -- �ŏI�X�V���i�I���j
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
    gn_warn_cnt   := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- ��������(A-1)
    -- ===============================
    init(
      iv_update_from     -- �ŏI�X�V���i�J�n�j
    , iv_update_to       -- �ŏI�X�V���i�I���j
    , lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
    , lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
    , lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �t�@�C���I�[�v������(A-2)
    -- ===============================
    open_csv_file(
      lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
    , lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
    , lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      -- �G���[����
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �]�ƈ��f�[�^�擾����(A-3)
    -- ===============================
    get_emp_data(
      lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
    , lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
    , lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- CSV�t�@�C���o�͏���(A-4)
    -- ===============================
    output_csv_data(
      lv_errbuf               -- �G���[�E���b�Z�[�W           --# �Œ� #
    , lv_retcode              -- ���^�[���E�R�[�h             --# �Œ� #
    , lv_errmsg               -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �I������(A-5)
    -- ===============================
    BEGIN
      -- �t�@�C���N���[�Y����
      IF ( UTL_FILE.IS_OPEN( gf_file_handler ) ) THEN
        -- �t�@�C���N���[�Y
        UTL_FILE.FCLOSE( gf_file_handler );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_xxcmm           -- �A�v���P�[�V�����Z�k��
                  , iv_name         => cv_file_close_err_msg   -- ���b�Z�[�W�R�[�h
                  , iv_token_name1  => cv_tkn_sqlerrm          -- �g�[�N���R�[�h1
                  , iv_token_value1 => SQLERRM                 -- �g�[�N���l1
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_f_close_err_expt;
    END;
--
    -- �X�L�b�v������1���ȏ�̏ꍇ�͌x����ԋp
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** �t�@�C���N���[�Y�G���[ ***
    WHEN global_f_close_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
    errbuf                    OUT VARCHAR2      -- �G���[�E���b�Z�[�W  --# �Œ� #
  , retcode                   OUT VARCHAR2      -- ���^�[���E�R�[�h    --# �Œ� #
  , iv_update_from            IN  VARCHAR2      -- �ŏI�X�V���i�J�n�j
  , iv_update_to              IN  VARCHAR2      -- �ŏI�X�V���i�I���j
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
--
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
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf        -- �G���[�E���b�Z�[�W           --# �Œ� #
    , lv_retcode       -- ���^�[���E�R�[�h             --# �Œ� #
    , lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    , iv_update_from   -- �ŏI�X�V���i�J�n�j
    , iv_update_to     -- �ŏI�X�V���i�I���j
    );
--
    -- ===============================
    -- �I������(A-5)
    -- ===============================
    -- �G���[�o��
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
      , buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      -- �G���[�������J�E���g
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_warn_cnt   := 0;
      gn_error_cnt  := 1;
    END IF;
--
    -- ��s�}��
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => ''
    );
--
    -- �Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                  , iv_name         => cv_target_rec_msg
                  , iv_token_name1  => cv_cnt_token
                  , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- ���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                  , iv_name         => cv_success_rec_msg
                  , iv_token_name1  => cv_cnt_token
                  , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- �X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                  , iv_name         => cv_skip_rec_msg
                  , iv_token_name1  => cv_cnt_token
                  , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- �G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- �I�����b�Z�[�W
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                  , iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
    , buff   => gv_out_msg
    );
--
    -- �t�@�C�����N���[�Y����Ă��Ȃ������ꍇ�A�N���[�Y����
    IF ( UTL_FILE.IS_OPEN( gf_file_handler ) ) THEN
      -- �t�@�C���N���[�Y
      UTL_FILE.FCLOSE( gf_file_handler );
    END IF;
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCMM002A07C;
/
