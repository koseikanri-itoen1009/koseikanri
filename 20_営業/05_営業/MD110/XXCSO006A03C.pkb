CREATE OR REPLACE PACKAGE BODY APPS.XXCSO006A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCSO006A03C(body)
 * Description      : �K����уf�[�^���[�N�e�[�u���i�A�h�I���j�Ɏ�荞�܂ꂽ�K����уf�[�^����A
 *                    �^�X�N�e�[�u���̓o�^�^�X�V���s�Ȃ��܂��B
 * MD.050           : MD050_CSO_006_A03_eSM-EBS�C���^�t�F�[�X�F�iIN�j�K����уf�[�^
 *                    
 * Version          : 1.1
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        ��������                                        (A-1)
 *  get_visit_data              �K����уf�[�^�擾����                          (A-2)
 *  data_proper_check           �f�[�^�Ó����`�F�b�N����                        (A-3)
 *  get_visit_same_data         ����K����уf�[�^�擾����                      (A-4)
 *  insert_visit_data           �K����уf�[�^�o�^����                          (A-6)
 *  update_visit_data           �K����уf�[�^�X�V����                          (A-7)
 *  delete_work_data            ���[�N�e�[�u���폜����                          (A-8)
 *  submain                     ���C�������v���V�[�W��
 *                              �Z�[�u�|�C���g���s����                          (A-5)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                              �I������                                        (A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/03/09    1.0   K.Kiriu          �V�K�쐬
 *  2017/04/20    1.1   N.Watanabe       E_�{�ғ�_14025�Ή�
 *
 *****************************************************************************************/
-- 
-- #######################  �Œ�O���[�o���萔�錾�� START   #######################
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
  --
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
-- #######################  �Œ�O���[�o���萔�錾�� END   #########################
--
-- #######################  �Œ�O���[�o���ϐ��錾�� START #########################
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
-- #######################  �Œ�O���[�o���ϐ��錾�� END   #########################
--
-- #######################  �Œ苤�ʗ�O�錾�� START       #########################
--
  --*** ���������ʗ�O ***
  global_process_expt    EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt        EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
-- #######################  �Œ苤�ʗ�O�錾�� END         #########################
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name                   CONSTANT VARCHAR2(100) := 'XXCSO006A03C';      -- �p�b�P�[�W��
  cv_app_name                   CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
  cv_app_name_ccp               CONSTANT VARCHAR2(5)   := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
--
  -- ���b�Z�[�W�R�[�h
  cv_msg_ccp_90008              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- �R���J�����g���̓p�����[�^�Ȃ�
  cv_msg_cso_00011              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_msg_cso_00175              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00175';  -- �v���t�@�C���擾�G���[
  cv_msg_cso_00804              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00804';  -- ���������G���[
  cv_msg_cso_00805              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00805';  -- �}�X�^���݂Ȃ��G���[
  cv_msg_cso_00806              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00806';  -- �������s�G���[
  cv_msg_cso_00807              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00807';  -- ��v���ԃN���[�Y�G���[
  cv_msg_cso_00808              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00808';  -- �������e�G���[
  cv_msg_cso_00809              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00809';  -- �^�X�N���݃G���[
  cv_msg_cso_00810              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00810';  -- ���b�N���G���[
  cv_msg_cso_00811              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00811';  -- �폜�G���[
  -- ���b�Z�[�W�R�[�h(�g�[�N���p)
  cv_msg_cso_00707              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00707';  -- �u�ڋq�R�[�h�v
  cv_msg_cso_00812              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00812';  -- �u�Ј��R�[�h�v
  cv_msg_cso_00813              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00813';  -- �u���\�[�X�}�X�^�r���[�v
  cv_msg_cso_00814              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00814';  -- �u�ڋq�}�X�^�r���[�v
  cv_msg_cso_00815              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00815';  -- �u�K����уf�[�^���[�N�e�[�u���v
  cv_msg_cso_00702              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00702';  -- �u�o�^�v
  cv_msg_cso_00703              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00703';  -- �u�X�V�v
  cv_msg_cso_00715              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00715';  -- �u���o�v
  cv_msg_cso_00816              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00816';  -- �u�������e�P�v
  cv_msg_cso_00817              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00817';  -- �u�������e�Q�v
  cv_msg_cso_00818              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00818';  -- �u�������e�R�v
  cv_msg_cso_00819              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00819';  -- �u�������e�S�v
  cv_msg_cso_00820              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00820';  -- �u�������e�T�v
  cv_msg_cso_00821              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00821';  -- �u�������e�U�v
  cv_msg_cso_00822              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00822';  -- �u�������e�V�v
  cv_msg_cso_00823              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00823';  -- �u�������e�W�v
  cv_msg_cso_00824              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00824';  -- �u�������e�X�v
  cv_msg_cso_00825              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00825';  -- �u�������e�P�O�v
  cv_msg_cso_00826              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00826';  -- �u�������e�P�P�v
  cv_msg_cso_00827              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00827';  -- �u�������e�P�Q�v
  cv_msg_cso_00828              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00828';  -- �u�������e�P�R�v
  cv_msg_cso_00829              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00829';  -- �u�������e�P�S�v
  cv_msg_cso_00830              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00830';  -- �u�������e�P�T�v
  cv_msg_cso_00831              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00831';  -- �u�������e�P�U�v
  cv_msg_cso_00832              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00832';  -- �u�������e�P�V�v
  cv_msg_cso_00833              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00833';  -- �u�������e�P�W�v
  cv_msg_cso_00834              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00834';  -- �u�������e�P�X�v
  cv_msg_cso_00835              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00835';  -- �u�������e�Q�O�v
  cv_msg_cso_00836              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00836';  -- �u�^�X�N�e�[�u���v
  cv_msg_cso_00837              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00837';  -- �u�폜�G���[(����0��)�v
  cv_msg_cso_00838              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00838';  -- �u�K��J�n�����v
  cv_msg_cso_00839              CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00839';  -- �u�K��I�������v
  -- �g�[�N���R�[�h
  cv_tkn_profile                CONSTANT VARCHAR2(20)  := 'PROF_NAME';
  cv_tkn_item                   CONSTANT VARCHAR2(20)  := 'ITEM';
  cv_tkn_table                  CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_table2                 CONSTANT VARCHAR2(20)  := 'TABLE2';
  cv_tkn_process                CONSTANT VARCHAR2(20)  := 'PROCESS';
  cv_tkn_emp_code               CONSTANT VARCHAR2(20)  := 'EMP_CODE';
  cv_tkn_cust_code              CONSTANT VARCHAR2(20)  := 'CUST_CODE';
  cv_tkn_visit_date             CONSTANT VARCHAR2(20)  := 'VISIT_DATE';
  cv_tkn_visit_time             CONSTANT VARCHAR2(20)  := 'VISIT_TIME';
  cv_tkn_visit_time_end         CONSTANT VARCHAR2(20)  := 'VISIT_TIME_END';
  cv_tkn_err_msg                CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_lookup_code                CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';
  -- ���t�t�H�[�}�b�g
  cv_format_date_time           CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';
  cv_format_date_minute         CONSTANT VARCHAR2(18)  := 'YYYY/MM/DD HH24:MI';
  cv_format_date                CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
  cv_format_minute              CONSTANT VARCHAR2(7)   := 'HH24:MI';
  -- �v���t�@�C��
  cv_task_open                  CONSTANT VARCHAR2(26)  := 'XXCSO1_TASK_STATUS_OPEN_ID';    -- XXCSO:�^�X�N�X�e�[�^�X�i�I�[�v���j
  cv_task_close                 CONSTANT VARCHAR2(28)  := 'XXCSO1_TASK_STATUS_CLOSED_ID';  -- XXCSO:�^�X�N�X�e�[�^�X�i�N���[�Y�j
  -- �Q�ƃ^�C�v
  cv_kubun_lookup_type          CONSTANT VARCHAR2(22)  := 'XXCSO_ASN_HOUMON_KUBUN';        -- �K��敪(Task DFF)
  -- �������e�̔ԍ�
  cv_activity_content01         CONSTANT VARCHAR2(1)   := '1';  -- �������e�P
  cv_activity_content02         CONSTANT VARCHAR2(1)   := '2';  -- �������e�Q
  cv_activity_content03         CONSTANT VARCHAR2(1)   := '3';  -- �������e�R
  cv_activity_content04         CONSTANT VARCHAR2(1)   := '4';  -- �������e�S
  cv_activity_content05         CONSTANT VARCHAR2(1)   := '5';  -- �������e�T
  cv_activity_content06         CONSTANT VARCHAR2(1)   := '6';  -- �������e�U
  cv_activity_content07         CONSTANT VARCHAR2(1)   := '7';  -- �������e�V
  cv_activity_content08         CONSTANT VARCHAR2(1)   := '8';  -- �������e�W
  cv_activity_content09         CONSTANT VARCHAR2(1)   := '9';  -- �������e�X
  cv_activity_content10         CONSTANT VARCHAR2(2)   := '10'; -- �������e�P�O
  cv_activity_content11         CONSTANT VARCHAR2(2)   := '11'; -- �������e�P�P
  cv_activity_content12         CONSTANT VARCHAR2(2)   := '12'; -- �������e�P�Q
  cv_activity_content13         CONSTANT VARCHAR2(2)   := '13'; -- �������e�P�R
  cv_activity_content14         CONSTANT VARCHAR2(2)   := '14'; -- �������e�P�S
  cv_activity_content15         CONSTANT VARCHAR2(2)   := '15'; -- �������e�P�T
  cv_activity_content16         CONSTANT VARCHAR2(2)   := '16'; -- �������e�P�U
  cv_activity_content17         CONSTANT VARCHAR2(2)   := '17'; -- �������e�P�V
  cv_activity_content18         CONSTANT VARCHAR2(2)   := '18'; -- �������e�P�W
  cv_activity_content19         CONSTANT VARCHAR2(2)   := '19'; -- �������e�P�X
  cv_activity_content20         CONSTANT VARCHAR2(2)   := '20'; -- �������e�Q�O
  -- �ڋq�敪
  ct_cust_class_code_cust       CONSTANT VARCHAR2(2)   := '10'; -- �ڋq
  ct_cust_class_code_cyclic     CONSTANT VARCHAR2(2)   := '15'; -- �X�܉c��
  ct_cust_class_code_tonya      CONSTANT VARCHAR2(2)   := '16'; -- �≮������
  -- �ڋq�X�e�[�^�X
  ct_cust_status_mc_candidate   CONSTANT VARCHAR2(2)   := '10'; -- �l�b���
  ct_cust_status_mc             CONSTANT VARCHAR2(2)   := '20'; -- �l�b
  ct_cust_status_sp_decision    CONSTANT VARCHAR2(2)   := '25'; -- �r�o���ٍ�
  ct_cust_status_approved       CONSTANT VARCHAR2(2)   := '30'; -- ���F��
  ct_cust_status_customer       CONSTANT VARCHAR2(2)   := '40'; -- �ڋq
  ct_cust_status_break          CONSTANT VARCHAR2(2)   := '50'; -- �x�~
  ct_cust_status_abort_approved CONSTANT VARCHAR2(2)   := '90'; -- ���~���ٍ�
  ct_cust_status_not_applicable CONSTANT VARCHAR2(2)   := '99'; -- �ΏۊO
  -- �^�X�N�擾
  cv_code_employee              CONSTANT VARCHAR2(11)  := 'RS_EMPLOYEE';
  cv_code_party                 CONSTANT VARCHAR2(5)   := 'PARTY';
  -- �ėp
  cv_0                          CONSTANT VARCHAR2(1)   := '0';      -- 0:CHAR�^
  cv_1                          CONSTANT VARCHAR2(1)   := '1';      -- 1:CHAR�^
  cv_6                          CONSTANT VARCHAR2(1)   := '6';      -- 6:CHAR�^
  cv_yes                        CONSTANT VARCHAR2(1)   := 'Y';      -- Y:YES
  cv_no                         CONSTANT VARCHAR2(1)   := 'N';      -- Y:NO
  cv_false                      CONSTANT VARCHAR2(5)   := 'FALSE';  -- FALSE:CHAR�^
  cb_true                       CONSTANT BOOLEAN       := TRUE;     -- TRUE:BOOLEAN�^
  cb_false                      CONSTANT BOOLEAN       := FALSE;    -- FALSE:BOOLEAN�^
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  -- �v���t�@�C���l
  gn_task_open                  NUMBER;  -- �^�X�N�X�e�[�^�X�i�I�[�v���j
  gn_task_close                 NUMBER;  -- �^�X�N�X�e�[�^�X�i�N���[�Y�j
  -- �Ɩ����t
  gd_process_date               DATE;    -- �Ɩ����t
  gb_rollback_flag              BOOLEAN; -- ���[���o�b�N�v�t���O

  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
  CURSOR g_visit_work_cur
  IS
    SELECT xivd.seq_no                    seq_no                   -- �V�[�P���X�ԍ�
          ,xivd.base_name                 base_name                -- ������
          ,xivd.employee_number           employee_number          -- �Ј��R�[�h
          ,xivd.account_number            account_number           -- �ڋq�R�[�h
          ,xivd.business_type             business_type            -- �Ɩ��^�C�v
          ,xivd.visit_date                visit_date               -- �K���
          ,xivd.visit_time                visit_time               -- �K��J�n����
          ,xivd.visit_time_end            visit_time_end           -- �K��I������
          ,xivd.detail                    detail                   -- �ڍד��e
          ,xivd.activity_content1         activity_content1        -- �������e�P
          ,xivd.activity_content2         activity_content2        -- �������e�Q
          ,xivd.activity_content3         activity_content3        -- �������e�R
          ,xivd.activity_content4         activity_content4        -- �������e�S
          ,xivd.activity_content5         activity_content5        -- �������e�T
          ,xivd.activity_content6         activity_content6        -- �������e�U
          ,xivd.activity_content7         activity_content7        -- �������e�V
          ,xivd.activity_content8         activity_content8        -- �������e�W
          ,xivd.activity_content9         activity_content9        -- �������e�X
          ,xivd.activity_content10        activity_content10       -- �������e�P�O
          ,xivd.activity_content11        activity_content11       -- �������e�P�P
          ,xivd.activity_content12        activity_content12       -- �������e�P�Q
          ,xivd.activity_content13        activity_content13       -- �������e�P�R
          ,xivd.activity_content14        activity_content14       -- �������e�P�S
          ,xivd.activity_content15        activity_content15       -- �������e�P�T
          ,xivd.activity_content16        activity_content16       -- �������e�P�U
          ,xivd.activity_content17        activity_content17       -- �������e�P�V
          ,xivd.activity_content18        activity_content18       -- �������e�P�W
          ,xivd.activity_content19        activity_content19       -- �������e�P�X
          ,xivd.activity_content20        activity_content20       -- �������e�Q�O
          ,xivd.activity_time1            activity_time1           -- �������ԂP�i���j
          ,xivd.activity_time2            activity_time2           -- �������ԂQ�i���j
          ,xivd.activity_time3            activity_time3           -- �������ԂR�i���j
          ,xivd.activity_time4            activity_time4           -- �������ԂS�i���j
          ,xivd.activity_time5            activity_time5           -- �������ԂT�i���j
          ,xivd.activity_time6            activity_time6           -- �������ԂU�i���j
          ,xivd.activity_time7            activity_time7           -- �������ԂV�i���j
          ,xivd.activity_time8            activity_time8           -- �������ԂW�i���j
          ,xivd.activity_time9            activity_time9           -- �������ԂX�i���j
          ,xivd.activity_time10           activity_time10          -- �������ԂP�O�i���j
          ,xivd.activity_time11           activity_time11          -- �������ԂP�P�i���j
          ,xivd.activity_time12           activity_time12          -- �������ԂP�Q�i���j
          ,xivd.activity_time13           activity_time13          -- �������ԂP�R�i���j
          ,xivd.activity_time14           activity_time14          -- �������ԂP�S�i���j
          ,xivd.activity_time15           activity_time15          -- �������ԂP�T�i���j
          ,xivd.activity_time16           activity_time16          -- �������ԂP�U�i���j
          ,xivd.activity_time17           activity_time17          -- �������ԂP�V�i���j
          ,xivd.activity_time18           activity_time18          -- �������ԂP�W�i���j
          ,xivd.activity_time19           activity_time19          -- �������ԂP�X�i���j
          ,xivd.activity_time20           activity_time20          -- �������ԂQ�O�i���j
          ,xivd.esm_input_date            esm_input_date           -- eSM���͓���
    FROM   xxcso_in_visit_data  xivd  -- �K����уf�[�^���[�N�e�[�u��
    ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �^�X�N�o�^�E�X�V�p
  TYPE g_visit_data_rtype IS RECORD(
     employee_number      per_people_f.employee_number%TYPE         -- �Ј��R�[�h
    ,account_number       hz_cust_accounts.account_number%TYPE      -- �ڋq�R�[�h
    ,visit_date           jtf_tasks_b.actual_end_date%TYPE          -- �K�����
    ,planned_end_date     jtf_tasks_b.planned_end_date%TYPE         -- �f�[�^���͓���
    ,description          jtf_tasks_tl.description%TYPE             -- �ڍד��e
    ,task_status_id       jtf_tasks_b.task_status_id%TYPE           -- �^�X�N�X�e�[�^�X
    ,dff1_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- �K��敪�P
    ,dff2_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- �K��敪�Q
    ,dff3_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- �K��敪�R
    ,dff4_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- �K��敪�S
    ,dff5_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- �K��敪�T
    ,dff6_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- �K��敪�U
    ,dff7_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- �K��敪�V
    ,dff8_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- �K��敪�W
    ,dff9_cd              fnd_lookup_values_vl.lookup_code%TYPE     -- �K��敪�X
    ,dff10_cd             fnd_lookup_values_vl.lookup_code%TYPE     -- �K��敪�P�O
    ,resource_id          jtf_rs_resource_extns.resource_id%TYPE    -- ���\�[�XID
    ,party_id             hz_parties.party_id%TYPE                  -- �p�[�e�BID
    ,party_name           hz_parties.party_name%TYPE                -- �p�[�e�B����
    ,customer_status      hz_parties.duns_number_c%TYPE             -- �ڋq�X�e�[�^�X
  );
--
  -- �������e
  TYPE g_act_content_ttype IS TABLE OF fnd_lookup_values_vl.lookup_code%TYPE INDEX BY PLS_INTEGER;
  -- �K����у��[�N�f�[�^
  TYPE g_visit_work_ttype  IS TABLE OF g_visit_work_cur%ROWTYPE              INDEX BY PLS_INTEGER;
--
  g_visit_work_tab  g_visit_work_ttype;
  g_visit_data_rec  g_visit_data_rtype;
  g_act_content_tab g_act_content_ttype;
--
  -- *** ���[�U�[��`�O���[�o����O ***
  global_skip_error_expt EXCEPTION;
  global_lock_expt       EXCEPTION;                                -- ���b�N��O
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : �������� (A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     ov_errbuf           OUT  VARCHAR2   -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT  VARCHAR2   -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT  VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_pam_msg  VARCHAR2(5000);
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================
    -- �p�����[�^�o��
    -- =======================
    -- �p�����[�^�Ȃ�
    lv_pam_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name_ccp   -- �A�v���P�[�V�����Z�k��
                   ,iv_name         => cv_msg_ccp_90008  -- ���b�Z�[�W�R�[�h
                 );
   -- ���O
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_pam_msg
    );
   -- �o��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_pam_msg
    );
--
    -- =======================
    -- �Ɩ����t�擾
    -- =======================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- �Ɩ����t���擾�ł��Ȃ��ꍇ
    IF ( gd_process_date IS NULL ) THEN
      -- �Ɩ����t�擾�G���[���b�Z�[�W
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_app_name    -- �A�v���P�[�V�����Z�k��
                     ,iv_name        => cv_msg_cso_00011  -- ���b�Z�[�W�R�[�h
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- =======================
    -- �v���t�@�C���l�擾 
    -- =======================
    -- XXCSO: �^�X�N�X�e�[�^�X�i�I�[�v���j
    BEGIN
      gn_task_open := FND_PROFILE.VALUE(cv_task_open);
    EXCEPTION
      -- �v���t�@�C���FXXCSO: �^�X�N�X�e�[�^�X�i�I�[�v���j�̒l���s���ȏꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_cso_00175     -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                      , iv_token_value1 => cv_task_open         -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- �v���t�@�C���FXXCSO: �^�X�N�X�e�[�^�X�i�I�[�v���j���擾�o���Ȃ��ꍇ
    IF ( gn_task_open IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                    , iv_name         => cv_msg_cso_00175     -- ���b�Z�[�W�R�[�h
                    , iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                    , iv_token_value1 => cv_task_open         -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- XXCSO:�^�X�N�X�e�[�^�X�i�N���[�Y�j
    BEGIN
      gn_task_close := FND_PROFILE.VALUE(cv_task_close);
    EXCEPTION
      -- �v���t�@�C���FXXCSO:�^�X�N�X�e�[�^�X�i�N���[�Y�j�̒l���s���ȏꍇ
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                      , iv_name         => cv_msg_cso_00175     -- ���b�Z�[�W�R�[�h
                      , iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                      , iv_token_value1 => cv_task_close         -- �g�[�N���l1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- �v���t�@�C���FXXCSO:�^�X�N�X�e�[�^�X�i�N���[�Y�j���擾�o���Ȃ��ꍇ
    IF ( gn_task_close IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name          -- �A�v���P�[�V�����Z�k��
                    , iv_name         => cv_msg_cso_00175     -- ���b�Z�[�W�R�[�h
                    , iv_token_name1  => cv_tkn_profile       -- �g�[�N���R�[�h1
                    , iv_token_value1 => cv_task_close         -- �g�[�N���l1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** ������O�n���h�� ***
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_visit_data
   * Description      : �K����уf�[�^�擾���� (A-2)
   ***********************************************************************************/
--
  PROCEDURE get_visit_data(
     ov_errbuf            OUT  VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT  VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT  VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_visit_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
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
    -- �Ώۃf�[�^�擾
    OPEN  g_visit_work_cur;
    FETCH g_visit_work_cur BULK COLLECT INTO g_visit_work_tab;
    CLOSE g_visit_work_cur;
--
    -- �Ώی����擾
    gn_target_cnt := g_visit_work_tab.COUNT;
--
  EXCEPTION
    -- *** ������O�n���h�� ***
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
  END get_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : data_proper_check
   * Description      : �f�[�^�Ó����`�F�b�N���� (A-3)
   ***********************************************************************************/
--
  PROCEDURE data_proper_check(
     in_cnt              IN   PLS_INTEGER      -- ���Y�s�f�[�^�̓Y����
    ,ov_errbuf           OUT  VARCHAR2         -- �G���[�E���b�Z�[�W           -- # �Œ� #
    ,ov_retcode          OUT  VARCHAR2         -- ���^�[���E�R�[�h             -- # �Œ� #
    ,ov_errmsg           OUT  VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(20)   := 'data_proper_check';       -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_return                 BOOLEAN;                                -- ���^�[���X�e�[�^�X(���R�[�h�P��)
    lb_func_return            BOOLEAN;                                -- ���^�[���X�e�[�^�X(�������e)
    ln_dff_cnt                NUMBER;                                 -- �������茏��
    lt_dff_cd                 fnd_lookup_values_vl.lookup_code%TYPE;  -- �K��敪
--
    -- *** �v���C�x�[�g�E�t�@���N�V���� ***
    -- �������e�̃`�F�b�N�p�t�@���N�V����
    FUNCTION activity_content_check(
       it_num       IN  fnd_lookup_values_vl.lookup_code%TYPE  -- �������e�̔ԍ�
      ,iv_err_code  IN  VARCHAR2                               -- �G���[���̃��b�Z�[�W�R�[�h(�g�[�N��)
      ,ot_dff_cd    OUT fnd_lookup_values_vl.lookup_code%TYPE  -- �K��敪
    ) RETURN BOOLEAN
    IS
      cn_length CONSTANT NUMBER(1) := 2;  --�K��敪�̍ő包��
    BEGIN
      BEGIN
        -- �K��敪���擾
        SELECT flv.lookup_code  dff_cd
        INTO   ot_dff_cd
        FROM   fnd_lookup_values_vl flv
        WHERE  flv.lookup_type    = cv_kubun_lookup_type
        AND    gd_process_date    BETWEEN flv.start_date_active
                                  AND     NVL( flv.end_date_active, gd_process_date)
        AND    flv.enabled_flag  = cv_yes
        AND    flv.attribute3    = it_num
        ;
      EXCEPTION
        WHEN OTHERS THEN
         RAISE global_process_expt;
      END;
      -- �擾�����K��敪��2���ȏ�̏ꍇ�A�G���[
      IF ( LENGTHB(ot_dff_cd) > cn_length ) THEN
       RAISE global_process_expt;
      END IF;
      -- ����
      RETURN cb_true;
    EXCEPTION
      WHEN global_process_expt THEN
        -- ���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                                     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00808                                                -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                                                      -- �g�[�N���R�[�h1
                       ,iv_token_value1 => iv_err_code                                                      -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_emp_code                                                  -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_visit_work_tab(in_cnt).employee_number                         -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_cust_code                                                 -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_work_tab(in_cnt).account_number                          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_visit_date                                                -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_visit_time                                                -- �g�[�N���R�[�h5
                       ,iv_token_value5 => g_visit_work_tab(in_cnt).visit_time                              -- �g�[�N���l5
                       ,iv_token_name6  => cv_lookup_code                                                   -- �g�[�N���R�[�h6
                       ,iv_token_value6 => it_num                                                           -- �g�[�N���l6
                     );
        -- ���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- �K��敪��NULL��ݒ�B
        ot_dff_cd := NULL;
        -- �x��
        RETURN cb_false;
    END activity_content_check;
--
  BEGIN
--
-- ##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  �Œ蕔 END   ############################
--
    -- �ϐ�������
    lb_return      := cb_true;
    ln_dff_cnt     := 0;
--
    -- �o�^�E�X�V�p�̃��R�[�h�Ɋi�[
    g_visit_data_rec.employee_number  := g_visit_work_tab(in_cnt).employee_number;  -- �Ј��R�[�h
    g_visit_data_rec.account_number   := g_visit_work_tab(in_cnt).account_number;   -- �ڋq�R�[�h
    g_visit_data_rec.description      := g_visit_work_tab(in_cnt).detail;           -- �ڍד��e
    g_visit_data_rec.planned_end_date := g_visit_work_tab(in_cnt).esm_input_date;   -- �f�[�^���͓���
    -- �K������������t�̏ꍇ
    IF ( g_visit_work_tab(in_cnt).visit_date > gd_process_date ) THEN
      g_visit_data_rec.task_status_id := gn_task_open;                              -- �^�X�N�X�e�[�^�X(�I�[�v��)
    ELSE
      g_visit_data_rec.task_status_id := NULL;                                      -- �^�X�N�X�e�[�^�X(�N���[�Y) 
    END IF;
--
    -- ============================
    -- 1.�f�[�^�^�i�����j�̃`�F�b�N
    -- ============================
    -- �K��J�n����
    IF ( xxcso_util_common_pkg.check_date( g_visit_work_tab(in_cnt).visit_time, cv_format_minute ) = cb_false ) THEN
      --���b�Z�[�W�ҏW
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                                                     -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_cso_00804                                                -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item                                                     -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_msg_cso_00838                                                -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_emp_code                                                 -- �g�[�N���R�[�h2
                     ,iv_token_value2 => g_visit_work_tab(in_cnt).employee_number                        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_cust_code                                                -- �g�[�N���R�[�h3
                     ,iv_token_value3 => g_visit_work_tab(in_cnt).account_number                         -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_visit_date                                               -- �g�[�N���R�[�h4
                     ,iv_token_value4 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )  -- �g�[�N���l4
                     ,iv_token_name5  => cv_tkn_visit_time                                               -- �g�[�N���R�[�h5
                     ,iv_token_value5 => g_visit_work_tab(in_cnt).visit_time                             -- �g�[�N���l5
                     ,iv_token_name6  => cv_tkn_visit_time_end                                           -- �g�[�N���R�[�h6
                     ,iv_token_value6 => g_visit_work_tab(in_cnt).visit_time_end                         -- �g�[�N���l6
                   );
      --���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- ���R�[�h�P�ʂŌx��
      lb_return      := cb_false;
    ELSE
      -- �o�^�E�X�V�p�̃��R�[�h�ɃZ�b�g
      g_visit_data_rec.visit_date := TO_DATE(
                                                 TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )
                                       || ' ' || g_visit_work_tab(in_cnt).visit_time, cv_format_date_minute );  --�K����i�K������j
    END IF;
--
    -- �K��I������
    IF ( xxcso_util_common_pkg.check_date( g_visit_work_tab(in_cnt).visit_time_end, cv_format_minute ) = cb_false ) THEN
      --���b�Z�[�W�ҏW
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                                                     -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_cso_00804                                                -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_item                                                     -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_msg_cso_00839                                                -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_emp_code                                                 -- �g�[�N���R�[�h2
                     ,iv_token_value2 => g_visit_work_tab(in_cnt).employee_number                        -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_cust_code                                                -- �g�[�N���R�[�h3
                     ,iv_token_value3 => g_visit_work_tab(in_cnt).account_number                         -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_visit_date                                               -- �g�[�N���R�[�h4
                     ,iv_token_value4 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )  -- �g�[�N���l4
                     ,iv_token_name5  => cv_tkn_visit_time                                               -- �g�[�N���R�[�h5
                     ,iv_token_value5 => g_visit_work_tab(in_cnt).visit_time                             -- �g�[�N���l5
                     ,iv_token_name6  => cv_tkn_visit_time_end                                           -- �g�[�N���R�[�h6
                     ,iv_token_value6 => g_visit_work_tab(in_cnt).visit_time_end                         -- �g�[�N���l6
                   );
      --���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- ���R�[�h�P�ʂŌx��
      lb_return      := cb_false;
    END IF;
--
    -- ============================
    -- 2.�}�X�^�̑��݃`�F�b�N
    -- ============================
    -- �Ј��R�[�h�i���\�[�X�}�X�^�r���[�j
    BEGIN
      SELECT xrv.resource_id  resource_id  -- ���\�[�XID
      INTO   g_visit_data_rec.resource_id
      FROM   xxcso_resources_v xrv
      WHERE  xrv.employee_number = g_visit_work_tab(in_cnt).employee_number
      AND    g_visit_work_tab(in_cnt).visit_date    BETWEEN TRUNC(xrv.employee_start_date)
                                                    AND     TRUNC(NVL(xrv.employee_end_date, g_visit_work_tab(in_cnt).visit_date))
      AND    g_visit_work_tab(in_cnt).visit_date    BETWEEN TRUNC(xrv.resource_start_date)
                                                    AND     TRUNC(NVL(xrv.resource_end_date, g_visit_work_tab(in_cnt).visit_date))
      AND    g_visit_work_tab(in_cnt).visit_date    BETWEEN TRUNC(xrv.assign_start_date)
                                                    AND     TRUNC(NVL(xrv.assign_end_date, g_visit_work_tab(in_cnt).visit_date))
      AND    g_visit_work_tab(in_cnt).visit_date    BETWEEN TRUNC(xrv.start_date)
                                                    AND     TRUNC(NVL(xrv.end_date, g_visit_work_tab(in_cnt).visit_date));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                                     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00805                                                -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                                                     -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00812                                                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_table                                                    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_msg_cso_00813                                                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_emp_code                                                 -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_work_tab(in_cnt).employee_number                        -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_cust_code                                                -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_visit_work_tab(in_cnt).account_number                         -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_visit_date                                               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )  -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_visit_time                                               -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_visit_work_tab(in_cnt).visit_time                             -- �g�[�N���l6
                     );
        --���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���R�[�h�P�ʂŌx��
        lb_return      := cb_false;
      WHEN OTHERS THEN
        --���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                                     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00806                                                -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                                                    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00813                                                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_process                                                  -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_msg_cso_00715                                                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_emp_code                                                 -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_work_tab(in_cnt).employee_number                        -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_cust_code                                                -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_visit_work_tab(in_cnt).account_number                         -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_visit_date                                               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )  -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_visit_time                                               -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_visit_work_tab(in_cnt).visit_time                             -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_err_msg                                                  -- �g�[�N���R�[�h7
                       ,iv_token_value7 => SQLERRM                                                         -- �g�[�N���l7
                     );
        --���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���R�[�h�P�ʂŌx��
        lb_return      := cb_false;
    END;
--
    -- �ڋq�}�X�^�i�ڋq�}�X�^�j
    BEGIN
      SELECT xcav.party_id            party_id          -- �p�[�e�BID
            ,xcav.party_name          party_name        -- �p�[�e�B����
            ,xcav.customer_status     customer_status   -- �ڋq�X�e�[�^�X
       INTO  g_visit_data_rec.party_id
            ,g_visit_data_rec.party_name
            ,g_visit_data_rec.customer_status
       FROM  xxcso_cust_accounts_v  xcav
       WHERE xcav.account_number = g_visit_work_tab(in_cnt).account_number
       AND   (
                -- �ڋq�敪��NULL�܂���'10'�A���ڋq�X�e�[�^�X��'10','20','25','30','40','50'
               (      NVL( xcav.customer_class_code ,ct_cust_class_code_cust ) = ct_cust_class_code_cust  -- �ڋq
                  AND xcav.customer_status IN (  ct_cust_status_mc_candidate  -- �l�b���
                                                ,ct_cust_status_mc            -- �l�b
                                                ,ct_cust_status_sp_decision   -- �r�o���ٍ�
                                                ,ct_cust_status_approved      -- ���F��
                                                ,ct_cust_status_customer      -- �ڋq
                                                ,ct_cust_status_break         -- �x�~
                                              )
               )
               -- �ڋq�敪��'15','16'�A���ڋq�X�e�[�^�X��'90','99'
               OR
               (
                     xcav.customer_class_code IN (  ct_cust_class_code_cyclic  -- �X�܉c��
                                                   ,ct_cust_class_code_tonya   -- �≮������
                                                 )
                 AND xcav.customer_status IN (  ct_cust_status_abort_approved  -- ���~���ٍ�
                                               ,ct_cust_status_not_applicable  -- �ΏۊO
                                             )
               )
             )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                                     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00805                                                -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_item                                                     -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00707                                                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_table                                                    -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_msg_cso_00814                                                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_emp_code                                                 -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_work_tab(in_cnt).employee_number                        -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_cust_code                                                -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_visit_work_tab(in_cnt).account_number                         -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_visit_date                                               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )  -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_visit_time                                               -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_visit_work_tab(in_cnt).visit_time                             -- �g�[�N���l6
                     );
        --���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���R�[�h�P�ʂŌx��
        lb_return      := cb_false;
      WHEN OTHERS THEN
        --���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                                     -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00806                                                -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                                                    -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00814                                                -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_process                                                  -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_msg_cso_00715                                                -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_emp_code                                                 -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_work_tab(in_cnt).employee_number                        -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_cust_code                                                -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_visit_work_tab(in_cnt).account_number                         -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_visit_date                                               -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )  -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_visit_time                                               -- �g�[�N���R�[�h6
                       ,iv_token_value6 => g_visit_work_tab(in_cnt).visit_time                             -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_err_msg                                                  -- �g�[�N���R�[�h7
                       ,iv_token_value7 => SQLERRM                                                         -- �g�[�N���l7
                     );
        --���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
    END;
--
    -- ============================
    -- 3.AR��v���Ԃ̃`�F�b�N
    -- ============================
    -- �K������_��AR��v���ԃ`�F�b�N
    IF ( xxcso_util_common_pkg.check_ar_gl_period_status( g_visit_work_tab(in_cnt).visit_date ) = cv_false ) THEN
      --���b�Z�[�W�ҏW
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                                                      -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_cso_00807                                                 -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_emp_code                                                  -- �g�[�N���R�[�h1
                     ,iv_token_value1 => g_visit_work_tab(in_cnt).employee_number                         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_cust_code                                                 -- �g�[�N���R�[�h2
                     ,iv_token_value2 => g_visit_work_tab(in_cnt).account_number                          -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_visit_date                                                -- �g�[�N���R�[�h3
                     ,iv_token_value3 => TO_CHAR( g_visit_work_tab(in_cnt).visit_date, cv_format_date )   -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_visit_time                                                -- �g�[�N���R�[�h4
                     ,iv_token_value4 => g_visit_work_tab(in_cnt).visit_time                              -- �g�[�N���l4
                   );
      --���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- ���R�[�h�P�ʂŌx��
      lb_return := cb_false;
    END IF;
--
    -- ============================
    -- 4.�������e�̃`�F�b�N
    -- ============================
    -- �������e�P
    IF ( g_visit_work_tab(in_cnt).activity_content1 = cv_1 ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content01
                          ,iv_err_code => cv_msg_cso_00816
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�Q
    IF ( g_visit_work_tab(in_cnt).activity_content2 = cv_1 ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content02
                          ,iv_err_code => cv_msg_cso_00817
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�R
    IF ( g_visit_work_tab(in_cnt).activity_content3 = cv_1 ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content03
                          ,iv_err_code => cv_msg_cso_00818
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�S
    IF ( g_visit_work_tab(in_cnt).activity_content4 = cv_1 ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content04
                          ,iv_err_code => cv_msg_cso_00819
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�T
    IF ( g_visit_work_tab(in_cnt).activity_content5 = cv_1 ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content05
                          ,iv_err_code => cv_msg_cso_00820
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�U
    IF ( g_visit_work_tab(in_cnt).activity_content6 = cv_1 ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content06
                          ,iv_err_code => cv_msg_cso_00821
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�V
    IF ( g_visit_work_tab(in_cnt).activity_content7 = cv_1 ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content07
                          ,iv_err_code => cv_msg_cso_00822
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�W
    IF ( g_visit_work_tab(in_cnt).activity_content8 = cv_1 ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content08
                          ,iv_err_code => cv_msg_cso_00823
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�X
    IF ( g_visit_work_tab(in_cnt).activity_content9 = cv_1 ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content09
                          ,iv_err_code => cv_msg_cso_00824
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�P�O
    IF ( g_visit_work_tab(in_cnt).activity_content10 = cv_1 ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content10
                          ,iv_err_code => cv_msg_cso_00825
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�P�P����Q�O�܂ł́u��������v���P�O�ɖ����Ȃ��ꍇ�擾����
--
    -- �������e�P�P
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content11 = cv_1 )
       ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content11
                          ,iv_err_code => cv_msg_cso_00826
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�P�Q
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content12 = cv_1 )
       ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content12
                          ,iv_err_code => cv_msg_cso_00827
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�P�R
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content13 = cv_1 )
       ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content13
                          ,iv_err_code => cv_msg_cso_00828
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�P�S
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content14 = cv_1 )
       ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content14
                          ,iv_err_code => cv_msg_cso_00829
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�P�T
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content15 = cv_1 )
       ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content15
                          ,iv_err_code => cv_msg_cso_00830
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�P�U
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content16 = cv_1 )
       ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content16
                          ,iv_err_code => cv_msg_cso_00831
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�P�V
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content17 = cv_1 )
       ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content17
                          ,iv_err_code => cv_msg_cso_00832
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�P�W
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content18 = cv_1 )
       ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content18
                          ,iv_err_code => cv_msg_cso_00833
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�P�X
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content19 = cv_1 )
       ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content19
                          ,iv_err_code => cv_msg_cso_00834
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    --�ϐ�������
    lb_func_return := cb_true;
    lt_dff_cd      := NULL;
--
    -- �������e�Q�O
    IF (
         ( ln_dff_cnt < 10 )
         AND
         ( g_visit_work_tab(in_cnt).activity_content20 = cv_1 )
       ) THEN
      -- �������e�̑��݃`�F�b�N
      lb_func_return := activity_content_check(
                           it_num      => cv_activity_content20
                          ,iv_err_code => cv_msg_cso_00835
                          ,ot_dff_cd   => lt_dff_cd
                        );
      IF ( lb_func_return <> cb_false ) THEN
        ln_dff_cnt := ln_dff_cnt + 1;
        -- �������e�Ɋi�[
        g_act_content_tab(ln_dff_cnt) := lt_dff_cd;
      ELSE
        -- ���R�[�h�P�ʂŌx��
        lb_return := cb_false;
      END IF;
    END IF;
--
    -- �x������
    IF ( lb_return = cb_false ) THEN
      --�Y�����R�[�h�̓X�L�b�v������
      RAISE global_skip_error_expt;
    END IF;
--
    -- ������
    ln_dff_cnt                := 1;
    g_visit_data_rec.dff1_cd  := NULL;
    g_visit_data_rec.dff2_cd  := NULL;
    g_visit_data_rec.dff3_cd  := NULL;
    g_visit_data_rec.dff4_cd  := NULL;
    g_visit_data_rec.dff5_cd  := NULL;
    g_visit_data_rec.dff6_cd  := NULL;
    g_visit_data_rec.dff7_cd  := NULL;
    g_visit_data_rec.dff8_cd  := NULL;
    g_visit_data_rec.dff9_cd  := NULL;
    g_visit_data_rec.dff10_cd := NULL;
--
    -- �K��敪�̕ҏW�i���������DFF1����10�ɂ߂Đݒ肷��j
    << act_loop >>
    WHILE g_act_content_tab.EXISTS(ln_dff_cnt) LOOP
--
      -- DFF1
      IF ( ln_dff_cnt = 1 ) THEN
        g_visit_data_rec.dff1_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF2
      ELSIF ( ln_dff_cnt = 2 ) THEN
        g_visit_data_rec.dff2_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF3
      ELSIF ( ln_dff_cnt = 3 ) THEN
        g_visit_data_rec.dff3_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF4
      ELSIF ( ln_dff_cnt = 4 ) THEN
        g_visit_data_rec.dff4_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF5
      ELSIF ( ln_dff_cnt = 5 ) THEN
        g_visit_data_rec.dff5_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF6
      ELSIF ( ln_dff_cnt = 6 ) THEN
        g_visit_data_rec.dff6_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF7
      ELSIF ( ln_dff_cnt = 7 ) THEN
        g_visit_data_rec.dff7_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF8
      ELSIF ( ln_dff_cnt = 8 ) THEN
        g_visit_data_rec.dff8_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF9
      ELSIF ( ln_dff_cnt = 9 ) THEN
        g_visit_data_rec.dff9_cd  := g_act_content_tab(ln_dff_cnt);
      -- DFF10
      ELSIF ( ln_dff_cnt = 10 ) THEN
        g_visit_data_rec.dff10_cd := g_act_content_tab(ln_dff_cnt);
      END IF;
--
      ln_dff_cnt := ln_dff_cnt + 1;
--
    END LOOP act_loop;
--
    --�s�v�Ȕz��̍폜
    g_act_content_tab.DELETE;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END data_proper_check;
--
  /**********************************************************************************
   * Procedure Name   : get_visit_same_data
   * Description      : ����K����уf�[�^�擾����(A-4)
   ***********************************************************************************/
--
  PROCEDURE get_visit_same_data(
     on_task_count            OUT  NUMBER                                 -- ����^�X�N���o����
    ,ot_task_id               OUT  jtf_tasks_b.task_id%TYPE               -- �^�X�N�h�c
    ,ot_obj_ver_num           OUT  jtf_tasks_b.object_version_number%TYPE -- �I�u�W�F�N�g�o�[�W�����ԍ�
    ,ov_errbuf                OUT  VARCHAR2                               -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode               OUT  VARCHAR2                               -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg                OUT  VARCHAR2                               -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_visit_same_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���E�J�[�\�� ***
    -- �������̃^�X�N�擾
    CURSOR l_task_cur
    IS
      SELECT jtb.task_id                task_id      -- �^�X�NID
            ,jtb.object_version_number  obj_ver_num  -- �I�u�W�F�N�g�o�[�W�����ԍ�
      FROM   jtf_tasks_b jtb
      WHERE  jtb.owner_id                = g_visit_data_rec.resource_id
      AND    jtb.owner_type_code         = cv_code_employee               -- RS_EMPLOYEE
      AND    jtb.source_object_id        = g_visit_data_rec.party_id
      AND    jtb.source_object_type_code = cv_code_party                  -- PARTY
      AND    jtb.actual_end_date         = g_visit_data_rec.visit_date
      AND    jtb.deleted_flag            = cv_no                          -- �������Ă��Ȃ�
      ORDER BY
             jtb.last_update_date DESC  --�ŐV
      FOR UPDATE OF jtb.task_id NOWAIT;
--
    -- �ߋ����̃^�X�N�擾
    CURSOR l_task_cur2
    IS
      SELECT jtb.task_id               task_id      -- �^�X�NID
            ,jtb.object_version_number obj_ver_num  -- �I�u�W�F�N�g�o�[�W�����ԍ�
      FROM   jtf_tasks_b jtb
      WHERE  jtb.owner_id                = g_visit_data_rec.resource_id
      AND    jtb.owner_type_code         = cv_code_employee               -- RS_EMPLOYEE
      AND    jtb.source_object_id        = g_visit_data_rec.party_id
      AND    jtb.source_object_type_code = cv_code_party                  -- PARTY
      AND    jtb.actual_end_date         = g_visit_data_rec.visit_date
      AND    jtb.deleted_flag            = cv_no                          -- �������Ă��Ȃ�
      AND    jtb.task_status_id          = gn_task_close                  -- �N���[�Y
      ORDER BY
             jtb.last_update_date DESC  --�ŐV
      FOR UPDATE OF jtb.task_id NOWAIT;
--
    -- *** ���[�J���E���R�[�h *** 
    l_task_rec l_task_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- *** 1. �^�X�N�e�[�u������^�X�NID�ƃI�u�W�F�N�g�o�[�W�����ԍ����擾 *** --
    BEGIN
--
      -- ����^�X�N����
      on_task_count := 0;
--
      -- �K������Ɩ����t��薢�����t�̏ꍇ
      IF ( TRUNC( g_visit_data_rec.visit_date ) > gd_process_date ) THEN
--
        -- �f�[�^�擾�i�ŏI�X�V���̍~���łP���̂݁j
        OPEN l_task_cur;
        FETCH l_task_cur INTO l_task_rec;
        CLOSE l_task_cur;
--
        -- �^�X�N�̑��݊m�F
        IF ( l_task_rec.task_id IS NOT NULL ) THEN
          on_task_count  := 1;
        END IF;
--
        -- �^�X�N�����݂���ꍇ
        IF ( on_task_count > 0 ) THEN
          -- �^�X�NID��ԋp
          ot_task_id     := l_task_rec.task_id;
          -- �I�u�W�F�N�g�o�[�W�����ԍ���ԋp
          ot_obj_ver_num := l_task_rec.obj_ver_num;
        END IF;
--
      -- �K��������Ɩ����t���܂߉ߋ����̏ꍇ
      ELSE
--
        -- �f�[�^�擾�i�ŏI�X�V���̍~���łP���̂݁j
        OPEN l_task_cur2;
        FETCH l_task_cur2 INTO l_task_rec;
        CLOSE l_task_cur2;
--
        -- �^�X�N�̑��݊m�F
        IF ( l_task_rec.task_id IS NOT NULL ) THEN
          on_task_count  := 1;
        END IF;
--
        -- �N���[�Y�̃^�X�N�����݂���ꍇ
        IF ( on_task_count > 0 ) THEN
          -- �K����������݂��܂މߋ����t�Ń^�X�N�����݂����ꍇ�̓X�L�b�v�B
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                                              -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00809                                         -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_emp_code                                          -- �g�[�N���R�[�h1
                         ,iv_token_value1 => g_visit_data_rec.employee_number                         -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_cust_code                                         -- �g�[�N���R�[�h2
                         ,iv_token_value2 => g_visit_data_rec.account_number                          -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_visit_date                                        -- �g�[�N���R�[�h
                         ,iv_token_value3 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_date )   -- �g�[�N���l3
                         ,iv_token_name4  => cv_tkn_visit_time                                        -- �g�[�N���R�[�h4
                         ,iv_token_value4 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_minute ) -- �g�[�N���l4
                       );
          --���b�Z�[�W�o��
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- ���R�[�h�P�ʂŃX�L�b�v����
          RAISE global_skip_error_expt;
        END IF;
--
      END IF;
--
    EXCEPTION
      -- �ߋ����t�Ń^�X�N����
      WHEN global_skip_error_expt THEN
        -- �X�e�[�^�X���x���ɂ���
        ov_retcode := cv_status_warn;
      -- ���b�N���s�����ꍇ�̗�O
      WHEN global_lock_expt THEN
        -- �J�[�\���E�N���[�Y
        IF (l_task_cur%ISOPEN) THEN
          CLOSE l_task_cur;
        END IF;
        IF (l_task_cur2%ISOPEN) THEN
          CLOSE l_task_cur2;
        END IF;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00810                                         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                                             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00836                                          -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_emp_code                                          -- �g�[�N���R�[�h2
                       ,iv_token_value2 => g_visit_data_rec.employee_number                         -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_cust_code                                         -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_data_rec.account_number                          -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_visit_date                                        -- �g�[�N���R�[�h4
                       ,iv_token_value4 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_date )   -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_visit_time                                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_minute ) -- �g�[�N���l5
                     );
        --���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���R�[�h�P�ʂŃX�L�b�v����
        RAISE global_skip_error_expt;
      -- ���o�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        -- �J�[�\���E�N���[�Y
        IF (l_task_cur%ISOPEN) THEN
          CLOSE l_task_cur;
        END IF;
        IF (l_task_cur2%ISOPEN) THEN
          CLOSE l_task_cur2;
        END IF;
        -- ���b�Z�[�W�ҏW
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                                              -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_cso_00806                                         -- ���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_table                                             -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_cso_00836                                         -- �g�[�N���l1
                       ,iv_token_name2  => cv_tkn_process                                           -- �g�[�N���R�[�h2
                       ,iv_token_value2 => cv_msg_cso_00715                                         -- �g�[�N���l2
                       ,iv_token_name3  => cv_tkn_emp_code                                          -- �g�[�N���R�[�h3
                       ,iv_token_value3 => g_visit_data_rec.employee_number                         -- �g�[�N���l3
                       ,iv_token_name4  => cv_tkn_cust_code                                         -- �g�[�N���R�[�h4
                       ,iv_token_value4 => g_visit_data_rec.account_number                          -- �g�[�N���l4
                       ,iv_token_name5  => cv_tkn_visit_date                                        -- �g�[�N���R�[�h5
                       ,iv_token_value5 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_date )   -- �g�[�N���l5
                       ,iv_token_name6  => cv_tkn_visit_time                                        -- �g�[�N���R�[�h6
                       ,iv_token_value6 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_minute ) -- �g�[�N���l6
                       ,iv_token_name7  => cv_tkn_err_msg                                           -- �g�[�N���R�[�h7
                       ,iv_token_value7 => SQLERRM                                                  -- �g�[�N���l7
                     );
        --���b�Z�[�W�o��
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        -- ���R�[�h�P�ʂŃX�L�b�v����
        RAISE global_skip_error_expt;
    END;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END get_visit_same_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_visit_data
   * Description      : �K����уf�[�^�o�^���� (A-6)
   ***********************************************************************************/
--
  PROCEDURE insert_visit_data(
     ov_errbuf            OUT  VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT  VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT  VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'insert_visit_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_task_id         jtf_tasks_b.task_id%TYPE;                -- �^�X�NID
    lt_task_status_id  jtf_task_statuses_b.task_status_id%TYPE; -- �^�X�N�X�e�[�^�X�h�c
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================
    -- �K����уf�[�^�o�^ 
    -- =======================
    xxcso_task_common_pkg.create_task(
       in_resource_id     => g_visit_data_rec.resource_id     -- ���\�[�XID
      ,in_party_id        => g_visit_data_rec.party_id        -- �p�[�e�BID
      ,iv_party_name      => g_visit_data_rec.party_name      -- �p�[�e�B����
-- Ver1.1 ADD Start
      ,id_input_date      => g_visit_data_rec.planned_end_date -- �f�[�^���͓���
-- Ver1.1 ADD End
      ,id_visit_date      => g_visit_data_rec.visit_date      -- �K�����
      ,iv_description     => g_visit_data_rec.description     -- �ڍד��e
      ,it_task_status_id  => g_visit_data_rec.task_status_id  -- �^�X�N�X�e�[�^�X�h�c
      ,iv_attribute1      => g_visit_data_rec.dff1_cd         -- �K��敪�P
      ,iv_attribute2      => g_visit_data_rec.dff2_cd         -- �K��敪�Q
      ,iv_attribute3      => g_visit_data_rec.dff3_cd         -- �K��敪�R
      ,iv_attribute4      => g_visit_data_rec.dff4_cd         -- �K��敪�S
      ,iv_attribute5      => g_visit_data_rec.dff5_cd         -- �K��敪�T
      ,iv_attribute6      => g_visit_data_rec.dff6_cd         -- �K��敪�U
      ,iv_attribute7      => g_visit_data_rec.dff7_cd         -- �K��敪�V
      ,iv_attribute8      => g_visit_data_rec.dff8_cd         -- �K��敪�W
      ,iv_attribute9      => g_visit_data_rec.dff9_cd         -- �K��敪�X
      ,iv_attribute10     => g_visit_data_rec.dff10_cd        -- �K��敪�P�O
      ,iv_attribute11     => cv_0                             -- �L���K��敪:0�i�K��j
      ,iv_attribute12     => cv_6                             -- �o�^�敪:6�i�K�����eSM�j
      ,iv_attribute13     => NULL                             -- �o�^���\�[�X�ԍ�:NULL
      ,iv_attribute14     => g_visit_data_rec.customer_status -- �ڋq�X�e�[�^�X
      ,on_task_id         => lt_task_id
      ,ov_errbuf          => lv_errbuf
      ,ov_retcode         => lv_retcode
      ,ov_errmsg          => lv_errmsg
    );
    -- ����ł͂Ȃ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�ҏW
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                                              -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_cso_00806                                         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table                                             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_msg_cso_00836                                         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_process                                           -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_msg_cso_00702                                         -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_emp_code                                          -- �g�[�N���R�[�h3
                     ,iv_token_value3 => g_visit_data_rec.employee_number                         -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_cust_code                                         -- �g�[�N���R�[�h4
                     ,iv_token_value4 => g_visit_data_rec.account_number                          -- �g�[�N���l4
                     ,iv_token_name5  => cv_tkn_visit_date                                        -- �g�[�N���R�[�h5
                     ,iv_token_value5 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_date )   -- �g�[�N���l5
                     ,iv_token_name6  => cv_tkn_visit_time                                        -- �g�[�N���R�[�h6
                     ,iv_token_value6 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_minute ) -- �g�[�N���l6
                     ,iv_token_name7  => cv_tkn_err_msg                                           -- �g�[�N���R�[�h7
                     ,iv_token_value7 => lv_errmsg                                                -- �g�[�N���l7
                   );
      --���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- ���R�[�h�P�ʂŃX�L�b�v����
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END insert_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : update_visit_data
   * Description      : �K����уf�[�^�X�V���� (A-7)
   ***********************************************************************************/
--
  PROCEDURE update_visit_data(
     it_task_id           IN  jtf_tasks_b.task_id%TYPE               -- �^�X�N�h�c
    ,it_obj_ver_num       IN  jtf_tasks_b.object_version_number%TYPE -- �I�u�W�F�N�g�o�[�W�����ԍ�
    ,ov_errbuf            OUT  VARCHAR2                              -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT  VARCHAR2                              -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT  VARCHAR2                              -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'update_visit_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lt_task_status_id jtf_task_statuses_b.task_status_id%TYPE; -- �^�X�N�X�e�[�^�X�h�c
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =======================
    -- �K����уf�[�^�X�V 
    -- =======================
    xxcso_task_common_pkg.update_task(
       in_task_id         => it_task_id                       -- �^�X�NID
      ,in_resource_id     => g_visit_data_rec.resource_id     -- ���\�[�XID
      ,in_party_id        => g_visit_data_rec.party_id        -- �p�[�e�BID
      ,iv_party_name      => g_visit_data_rec.party_name      -- �p�[�e�B����
      ,id_visit_date      => g_visit_data_rec.visit_date      -- �K�����
      ,iv_description     => g_visit_data_rec.description     -- �ڍד��e
      ,in_obj_ver_num     => it_obj_ver_num                   -- �I�u�W�F�N�g�E�o�[�W�����E�ԍ�
      ,it_task_status_id  => g_visit_data_rec.task_status_id  -- �^�X�N�X�e�[�^�X�h�c
      ,iv_attribute1      => g_visit_data_rec.dff1_cd         -- �K��敪�P
      ,iv_attribute2      => g_visit_data_rec.dff2_cd         -- �K��敪�Q
      ,iv_attribute3      => g_visit_data_rec.dff3_cd         -- �K��敪�R
      ,iv_attribute4      => g_visit_data_rec.dff4_cd         -- �K��敪�S
      ,iv_attribute5      => g_visit_data_rec.dff5_cd         -- �K��敪�T
      ,iv_attribute6      => g_visit_data_rec.dff6_cd         -- �K��敪�U
      ,iv_attribute7      => g_visit_data_rec.dff7_cd         -- �K��敪�V
      ,iv_attribute8      => g_visit_data_rec.dff8_cd         -- �K��敪�W
      ,iv_attribute9      => g_visit_data_rec.dff9_cd         -- �K��敪�X
      ,iv_attribute10     => g_visit_data_rec.dff10_cd        -- �K��敪�P�O
      ,iv_attribute11     => cv_0                             -- �L���K��敪:0�i�K��j
      ,iv_attribute12     => cv_6                             -- �o�^�敪:6�i�K�����eSM�j
      ,iv_attribute13     => NULL                             -- �o�^���\�[�X�ԍ�:NULL
      ,iv_attribute14     => g_visit_data_rec.customer_status
      ,ov_errbuf          => lv_errbuf
      ,ov_retcode         => lv_retcode
      ,ov_errmsg          => lv_errmsg
    );
    -- ����ł͂Ȃ��ꍇ
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ���b�Z�[�W�ҏW
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                                              -- �A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_msg_cso_00806                                         -- ���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_table                                             -- �g�[�N���R�[�h1
                     ,iv_token_value1 => cv_msg_cso_00836                                         -- �g�[�N���l1
                     ,iv_token_name2  => cv_tkn_process                                           -- �g�[�N���R�[�h2
                     ,iv_token_value2 => cv_msg_cso_00703                                         -- �g�[�N���l2
                     ,iv_token_name3  => cv_tkn_emp_code                                          -- �g�[�N���R�[�h3
                     ,iv_token_value3 => g_visit_data_rec.employee_number                         -- �g�[�N���l3
                     ,iv_token_name4  => cv_tkn_cust_code                                         -- �g�[�N���R�[�h4
                     ,iv_token_value4 => g_visit_data_rec.account_number                          -- �g�[�N���l4
                     ,iv_token_name5  => cv_tkn_visit_date                                        -- �g�[�N���R�[�h5
                     ,iv_token_value5 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_date )   -- �g�[�N���l5
                     ,iv_token_name6  => cv_tkn_visit_time                                        -- �g�[�N���R�[�h6
                     ,iv_token_value6 => TO_CHAR( g_visit_data_rec.visit_date, cv_format_minute ) -- �g�[�N���l6
                     ,iv_token_name7  => cv_tkn_err_msg                                           -- �g�[�N���R�[�h7
                     ,iv_token_value7 => lv_errmsg                                                -- �g�[�N���l7
                   );
      --���b�Z�[�W�o��
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- ���R�[�h�P�ʂŃX�L�b�v����
      RAISE global_skip_error_expt;
    END IF;
--
  EXCEPTION
    -- *** �X�L�b�v��O�n���h�� ***
    WHEN global_skip_error_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END update_visit_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_data
   * Description      : ���[�N�e�[�u���폜���� (A-8)
   ***********************************************************************************/
--
  PROCEDURE delete_work_data(
     ov_errbuf            OUT  VARCHAR2             -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode           OUT  VARCHAR2             -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg            OUT  VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'delete_work_data';     -- �v���O������
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode           VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg            VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- #####################  �Œ胍�[�J���ϐ��錾�� END       #########################
    -- ===============================
    -- ���[�U�[�錾��
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
    BEGIN
--
      -- �K����у��[�N�e�[�u���f�[�^�폜
      DELETE FROM xxcso_in_visit_data xivd;
--
    EXCEPTION
      -- �폜�Ɏ��s�����ꍇ
      WHEN OTHERS THEN
        -- ��������0���ȊO�̏ꍇ�i�^�X�N�ɓo�^�E�X�V���ꂽ�f�[�^�����݂���j
        IF ( gn_normal_cnt <> 0 ) THEN
          -- ���b�Z�[�W�ҏW
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name       -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00811  -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_table      -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_msg_cso_00815  -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_table2     -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_msg_cso_00815  -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_err_msg    -- �g�[�N���R�[�h3
                         ,iv_token_value3 => SQLERRM           -- �g�[�N���l3
                       );
        -- ��������0���̏ꍇ�i�^�X�N�ɓo�^�E�X�V���ꂽ�f�[�^�����݂��Ȃ��j
        ELSE
          -- ���b�Z�[�W�ҏW
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name       -- �A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_cso_00837  -- ���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_table      -- �g�[�N���R�[�h1
                         ,iv_token_value1 => cv_msg_cso_00815  -- �g�[�N���l1
                         ,iv_token_name2  => cv_tkn_table2     -- �g�[�N���R�[�h2
                         ,iv_token_value2 => cv_msg_cso_00815  -- �g�[�N���l2
                         ,iv_token_name3  => cv_tkn_err_msg    -- �g�[�N���R�[�h3
                         ,iv_token_value3 => SQLERRM           -- �g�[�N���l3
                       );
        END IF;
        lv_errbuf := lv_errmsg;
        -- �G���[�I���Ƃ���
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** ������O�n���h�� ***
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
  END delete_work_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
--
  PROCEDURE submain(
     ov_errbuf           OUT  VARCHAR2   -- �G���[�E���b�Z�[�W            -- # �Œ� #
    ,ov_retcode          OUT  VARCHAR2   -- ���^�[���E�R�[�h              -- # �Œ� #
    ,ov_errmsg           OUT  VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
  )
  IS
--
-- #####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_sub_retcode VARCHAR2(1);     -- �T�[�u���^�[���E�R�[�h
    lv_errmsg      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
-- ###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_task_count           NUMBER;                                  -- ����^�X�N����
    lt_task_id              jtf_tasks_b.task_id%TYPE;                -- �^�X�N�h�c
    lt_obj_ver_num          jtf_tasks_b.object_version_number%TYPE;  -- �I�u�W�F�N�g�o�[�W�����ԍ�
    -- *** ���[�J�����R�[�h ***
    g_visit_date_format_rec g_visit_data_rtype;                      -- �������p
--
    -- *** ���[�J����O ***
--
  BEGIN
--
-- ##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ================================
    -- ��������(A-1)
    -- ================================
    init(
       ov_errbuf  => lv_errbuf           -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode => lv_retcode          -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg  => lv_errmsg           -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- �K����уf�[�^�擾����(A-2)
    -- ========================================
    get_visit_data(
       ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- A-2�Œ��o�����f�[�^��1���ȏ�̏ꍇ
    IF ( g_visit_work_tab.COUNT > 0 ) THEN
--
      << visit_loop >>
      FOR i IN 1..g_visit_work_tab.COUNT LOOP
--
        -- �o�^�E�X�V�p���R�[�h������
        g_visit_data_rec := g_visit_date_format_rec;
        -- ���[���o�b�N�t���O������
        gb_rollback_flag := cb_false;
--
        BEGIN
--
          -- =============================
          -- �f�[�^�Ó����`�F�b�N����(A-3)
          -- =============================
          data_proper_check(
             in_cnt           => i                -- ���Y�s�f�[�^�̓Y����
            ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
            ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            -- �����G���[
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            -- ���R�[�h�P�ʂŃX�L�b�v
            RAISE global_skip_error_expt;
          END IF;
--
          -- =============================
          -- ����K����уf�[�^�擾����(A-4)
          -- =============================
          get_visit_same_data(
             on_task_count    => ln_task_count    -- ����^�X�N���o����
            ,ot_task_id       => lt_task_id       -- �^�X�N�h�c
            ,ot_obj_ver_num   => lt_obj_ver_num   -- �I�u�W�F�N�g�o�[�W�����ԍ�
            ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
            ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
            ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            -- �G���[�I��
            RAISE global_process_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            -- ���R�[�h�P�ʂŃX�L�b�v
            RAISE global_skip_error_expt;
          END IF;
--
          -- ============================
          -- SAVEPOINT���s����(A-5)
          -- ============================
          SAVEPOINT visit;
--
          -- �X�V�Ώۂ����݂��Ȃ��ꍇ
          IF ( ln_task_count = 0 ) THEN
--
            -- =============================
            -- �K����уf�[�^�o�^����(A-6)
            -- =============================
            insert_visit_data(
               ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
              ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
              ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              -- �G���[�I��
              RAISE global_process_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              -- ���[���o�b�N��v�Ƃ��X�L�b�v����
              gb_rollback_flag := cb_true;
              RAISE global_skip_error_expt;
            END IF;
--
          -- �X�V�Ώۂ����݂���ꍇ
          ELSE
--
            -- =============================
            -- �K����уf�[�^�X�V����(A-7)
            -- =============================
            update_visit_data(
               it_task_id       => lt_task_id       -- �^�X�N�h�c
              ,it_obj_ver_num   => lt_obj_ver_num   -- �I�u�W�F�N�g�o�[�W�����ԍ�
              ,ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
              ,ov_retcode       => lv_sub_retcode   -- ���^�[���E�R�[�h              -- # �Œ� #
              ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              -- �G���[�I��
              RAISE global_process_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              -- ���[���o�b�N��v�Ƃ��X�L�b�v����
              gb_rollback_flag := cb_true;
              RAISE global_skip_error_expt;
            END IF;
          END IF;
--
          -- ���������J�E���g
          gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
          -- *** �X�L�b�v��O�n���h�� ***
          WHEN global_skip_error_expt THEN
            gn_warn_cnt := gn_warn_cnt + 1;       -- �x�������J�E���g
            lv_retcode  := cv_status_warn;
            -- ���[���o�b�N�v�̏ꍇ
            IF ( gb_rollback_flag = cb_true )THEN
              ROLLBACK TO SAVEPOINT visit;        -- ROLLBACK
            END IF;
        END;
--
      END LOOP get_visit_data_loop;
--
      ov_retcode := lv_retcode;  -- ���^�[���E�R�[�h�ݒ�
--
    END IF;
--
    -- �o�^�E�X�V�̊m��ׁ̈ACOMMIT
    COMMIT;
--
    -- =============================
    -- ���[�N�e�[�u���폜����(A-8)
    -- =============================
    delete_work_data(
       ov_errbuf        => lv_errbuf        -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode       => lv_retcode       -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg        => lv_errmsg        -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- �G���[�I��
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
-- #################################  �Œ��O������ START   ####################################
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
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT  VARCHAR2          -- �G���[�E���b�Z�[�W  -- # �Œ� #
    ,retcode       OUT  VARCHAR2          -- ���^�[���E�R�[�h    -- # �Œ� #
  )    
--
-- ###########################  �Œ蕔 START   ###########################
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
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90007'; -- �G���[�I���ꕔ�������b�Z�[�W
    cv_error_msg2      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008'; -- �G���[�I�����b�Z�[�W

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
-- ###########################  �Œ蕔 START   #####################################################
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
-- ###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- �G���[�E���b�Z�[�W            -- # �Œ� #
      ,ov_retcode  => lv_retcode         -- ���^�[���E�R�[�h              -- # �Œ� #
      ,ov_errmsg   => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  -- # �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg    -- ���[�U�[�E�G���[���b�Z�[�W
       );
       FND_FILE.PUT_LINE(
          which  => FND_FILE.LOG
         ,buff   => lv_errbuf    -- �G���[���b�Z�[�W
       );
       --�G���[�����̐ݒ�
       gn_error_cnt  := 1;
    END IF;
--
    -- =======================
    -- �I������(A-9)
    -- =======================
    -- ��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- �Ώی����o��
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
    -- ���������o��
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
    -- �x�������o��
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
    -- �G���[�����o��
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
    -- �I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      -- 1���ł����������ꍇ
      IF ( gn_normal_cnt <> 0 ) THEN
        -- �G���[�I���ꕔ�������b�Z�[�W
        lv_message_code := cv_error_msg;
      ELSE
        -- �G���[�I�����b�Z�[�W
        lv_message_code := cv_error_msg2;
      END IF;
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
--
    -- �X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    -- �I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
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
END XXCSO006A03C;
/
