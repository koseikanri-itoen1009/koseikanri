CREATE OR REPLACE PACKAGE BODY XXCSO019A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name            : XXCSO019A05C(body)
 * Description             : �v���̔��s��ʂ���
 *                           �K�┄��v��Ǘ��\�𒠕[�ɏo�͂��܂��B
 * MD.050                  : �c�ƃV�X�e���\�z�v���W�F�N�g�A�h�I���F
 *                           �K�┄��v��Ǘ��\
 * Version                 : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   �������� (A-1)
 *  chek_param             �p�����[�^�`�F�b�N (A-2)
 *  get_ticket1            ���[���1-�c�ƈ��� (A-3-1,A-3-2)
 *  up_plsql_tab1          �c�ƈ���-PLSQL�\�̍X�V (A-3-3)
 *  get_ticket2            ���[���2-�c�ƈ��O���[�v�� (A-4-1,A-4-2)
 *  up_plsql_tab2          �c�ƈ��O���[�v��-PLSQL�\�̍X�V (A-4-3)
 *  get_ticket3            ���[���3-�c�ƈ����_/�ە� (A-5-1,A-5-2)
 *  up_plsql_tab3          ���_/�ە�-PLSQL�\�̍X�V (A-5-3)
 *  get_ticket4            ���[���4-�n��c�ƕ�/���� (A-6-1,A-6-2)
 *  up_plsql_tab4          �n��c�ƕ�/����-PLSQL�\�̍X�V (A-6-3)
 *  get_ticket5            ���[���5-�n��c�Ɩ{���� (A-7-1,A-7-2)
 *  up_plsql_tab5          �n��c�Ɩ{���ʕ�-PLSQL�\�̍X�V (A-7-3)
 *  insert_wrk_table       ���[�N�e�[�u���ւ̏o�� (A-3-4,A-4-4,A-5-4,A-6-4,A-7-4)
 *  act_svf                SVF�N�� (A-8)
 *  del_wrk_tbl_data       ���[�N�e�[�u���f�[�^�폜 (A-9)
 *  submain                ���C�������v���V�[�W��
 *                         SVF�N��API�G���[�`�F�b�N(A-10)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                         �I������ (A-11)
 *  debug                  �f�o�b�O���O�o��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-10    1.0   Seirin.Kin        �V�K�쐬
 *  2009-03-03    1.1   Kazuyo.Hosoi      SVF�N��API���ߍ���
 *  2009-03-13    1.1   Kazuyo.Hosoi      �y��Q�Ή�047�E057�z�ڋq�敪�A�X�e�[�^�X���o�����ύX
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --TODO�P�̃e�X�g�I������FALSE�ɕύX
  --�f�o�b�O���O�o�͂���^���Ȃ�
  CB_DEBUG_LOG              CONSTANT BOOLEAN      := FALSE;
  --�G���[���������ԍ�
  CB_DO_ERROR_NO            CONSTANT VARCHAR2(10) := 'NULL';
  --���[���[�N�e�[�u���폜����^���Ȃ�
  CB_DO_DELETE         CONSTANT BOOLEAN           := TRUE;
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
  cv_lf                     CONSTANT VARCHAR2(1) := CHR(10);
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_resp_id                CONSTANT VARCHAR2(10)  := 'resp_id';           -- �E��ID
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSO019A05C';      -- �p�b�P�[�W��
  cv_app_name               CONSTANT VARCHAR2(5)   := 'XXCSO';             -- �A�v���P�[�V�����Z�k��
  cv_tab_samari             CONSTANT VARCHAR2(100) := 'XXCSO_SUM_VISIT_SALE_REP';-- �T�}���e�[�u��
  cv_gvm_g                  CONSTANT VARCHAR2(1)   := '1';                 -- ���
  cv_gvm_v                  CONSTANT VARCHAR2(1)   := '2';                 -- ���̋@
  cv_gvm_m                  CONSTANT VARCHAR2(1)   := '3';                 -- MC
  cv_true                   CONSTANT VARCHAR2(4)   := 'TRUE';              -- VARCHAR2�^��TRUE
  cv_false                  CONSTANT VARCHAR2(5)   := 'FALSE';             -- VARCHAR2�^��FALSE
  cv_cust_class_cd1         CONSTANT VARCHAR2(2)   := '13';                -- �@�l�ڋq
  cv_cust_class_cd2         CONSTANT VARCHAR2(2)   := '14';                -- ���|�Ǘ��ڋq
  cv_cust_class_cd3         CONSTANT VARCHAR2(2)   := '10';                -- �ڋq
  cv_cust_class_cd4         CONSTANT VARCHAR2(2)   := '12';                -- ��l�ڋq
  cv_cust_class_cd5         CONSTANT VARCHAR2(2)   := '15';                -- ����
  cv_cust_class_cd6         CONSTANT VARCHAR2(2)   := '16';                -- �≮������
  cv_cust_class_cd7         CONSTANT VARCHAR2(2)   := '17';                -- �v��
  cv_cust_status1           CONSTANT VARCHAR2(2)   := '80';                -- �ڋq�X�e�[�^�X(�X����)
  cv_cust_status2           CONSTANT VARCHAR2(2)   := '90';                -- �ڋq�X�e�[�^�X(���~����)
  cv_cust_status3           CONSTANT VARCHAR2(2)   := '99';                -- �ڋq�X�e�[�^�X(�ΏۊO)
  cv_cust_status4           CONSTANT VARCHAR2(2)   := '20';                -- �ڋq�X�e�[�^�XMC)
  cv_cust_status5           CONSTANT VARCHAR2(2)   := '25';                -- �ڋq�X�e�[�^�X(SP���F)
  cv_cust_status6           CONSTANT VARCHAR2(2)   := '30';                -- �ڋq�X�e�[�^�X(���F��)
  cv_cust_status7           CONSTANT VARCHAR2(2)   := '10';                -- �ڋq�X�e�[�^�X(MC���)
  cv_cust_status8           CONSTANT VARCHAR2(2)   := '40';                -- �ڋq�X�e�[�^�X(�ڋq)
  cv_cust_status9           CONSTANT VARCHAR2(2)   := '50';                -- �ڋq�X�e�[�^�X(�x�~)
  cv_sum_org_type1          CONSTANT VARCHAR2(1)   := '1';                 -- �ڋq�R�[�h
  cv_sum_org_type2          CONSTANT VARCHAR2(1)   := '2';                 -- �]�ƈ��ԍ�
  cv_sum_org_type3          CONSTANT VARCHAR2(1)   := '3';                 -- �c�ƃO���[�v�ԍ�
  cv_sum_org_type4          CONSTANT VARCHAR2(1)   := '4';                 -- ���_�R�[�h
  cv_sum_org_type5          CONSTANT VARCHAR2(1)   := '5';                 -- �n��c�ƕ��R�[�h
  cv_month_date_div1        CONSTANT VARCHAR2(1)   := '1';                 -- �����敪(����)
  cv_month_date_div2        CONSTANT VARCHAR2(1)   := '2';                 -- �����敪(����)
  cv_report_1               CONSTANT VARCHAR2(1)   := '1';                 -- ���[���1-�c�ƈ���
  cv_report_2               CONSTANT VARCHAR2(1)   := '2';                 -- ���[���2-�c�ƃO���[�v��
  cv_report_3               CONSTANT VARCHAR2(1)   := '3';                 -- ���[���3-���_/�ە�
  cv_report_4               CONSTANT VARCHAR2(1)   := '4';                 -- ���[���4-�n��c�ƕ���/����
  cv_report_5               CONSTANT VARCHAR2(1)   := '5';                 -- ���[���5-�n��c�Ɩ{��
  cn_line_kind1             CONSTANT NUMBER(5)     := 1;                   -- ���[�o�͈ʒu�w�b�_��
  cn_line_kind2             CONSTANT NUMBER(5)     := 2;                   -- ���[�o�͈ʒu����グ���ו�
  cn_line_kind3             CONSTANT NUMBER(5)     := 3;                   -- ���[�o�͈ʒu����グ���v��
  cn_line_kind4             CONSTANT NUMBER(5)     := 4;                   -- ���[�o�͈ʒu����グ���v��
  cn_line_kind5             CONSTANT NUMBER(5)     := 5;                   -- ���[�o�͈ʒu�K�⒆�v��
  cn_line_kind6             CONSTANT NUMBER(5)     := 6;                   -- ���[�o�͈ʒu�K�⍇�v��
  cn_line_kind7             CONSTANT NUMBER(5)     := 7;                   -- ���[�o�͈ʒu�K����e���v��
  cn_idx_sales_ippn         CONSTANT NUMBER(1)     := 1;                   -- �{�̕��z��ԍ��i���㒆�v���F��ʁj
  cn_idx_sales_vd           CONSTANT NUMBER(1)     := 2;                   -- �{�̕��z��ԍ��i���㒆�v���F���̋@�j
  cn_idx_sales_sum          CONSTANT NUMBER(1)     := 3;                   -- �{�̕��z��ԍ��i���㒆�v���F���v�j
  cn_idx_visit_ippn         CONSTANT NUMBER(1)     := 4;                   -- �{�̕��z��ԍ��i�K�⒆�v���F��ʁj
  cn_idx_visit_vd           CONSTANT NUMBER(1)     := 5;                   -- �{�̕��z��ԍ��i�K�⒆�v���F���̋@�j
  cn_idx_visit_mc           CONSTANT NUMBER(1)     := 6;                   -- �{�̕��z��ԍ��i�K�⒆�v���F�l�b�j
  cn_idx_visit_sum          CONSTANT NUMBER(1)     := 7;                   -- �{�̕��z��ԍ��i�K�⒆�v���F���v�j
  cn_idx_visit_dsc          CONSTANT NUMBER(1)     := 8;                   -- �{�̕��z��ԍ��i�K����e�j
  cn_idx_max                CONSTANT NUMBER(1)     := cn_idx_visit_dsc;    -- �ő�l
  cv_flg_y                  CONSTANT VARCHAR2(1)   := 'Y';                 -- �c�ƃO���[�v���[�_(�t���O)
  cv_flg_n                  CONSTANT VARCHAR2(1)   := 'N';                 -- �c�ƈ�(�t���O)
  cv_mc                     CONSTANT VARCHAR2(2)   := 'MC';
      -- �K�┄��v��Ǘ��\���[��ʎQ�ƃ^�C�v 
  cv_rep_lookup_type_code   CONSTANT VARCHAR2(100) := 'XXCSO1_VST_SLS_REP_KIND';  
  cv_lookup_type_dai        CONSTANT VARCHAR2(100) := 'XXCMM_CUST_GYOTAI_DAI';
  cv_lookup_type_chu        CONSTANT VARCHAR2(100) := 'XXCMM_CUST_GYOTAI_CHU';
  cv_lookup_type_syo        CONSTANT VARCHAR2(100) := 'XXCMM_CUST_GYOTAI_SHO';
  cv_svf_form_def_no        CONSTANT VARCHAR2(100) := '1';                 -- �t�H�[���l���t�@�C����DEF�ԍ�  
  cv_svf_query_def_no       CONSTANT VARCHAR2(100) := '2';                 -- �N�G���[�l���t�@�C����DEF�ԍ�
--
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00411';  -- ��N��
  cv_tkn_number_02          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00412';  -- ���[���
  cv_tkn_number_03          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00130';  -- ���_�R�[�h  
  cv_tkn_number_04          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00133';  -- ���_�R�[�h��I�����Ă��������B
  cv_tkn_number_05          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00508';  -- ���Ԃ�YYYYMM�̌^�Ŏw�肵�Ă��������B
  cv_tkn_number_06          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00157';  -- ��N���͖������t�͓��͂ł��܂���B
  cv_tkn_number_07          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00134';  -- XXXX�͎��s����������܂���B
  cv_tkn_number_08          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';
  -- ���K��ڋq�ꗗ�̃f�[�^���o�Ɏ��s���܂����A�������I�����܂��B�iSQL�G���[�FORA-XXXX �E�E�E�j�V�X�e���Ǘ��҂ɘA������      ���������B
  cv_tkn_number_09          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00135';  
  -- SVF�N��API�ŃG���[���������܂����B�V�X�e���Ǘ��҂ɘA�����Ă��������B
  cv_tkn_number_10          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00119';  
  -- ���K��ڋq�ꗗ���[���[�N�e�[�u���̃f�[�^�폜�Ɏ��s���܂����A�������I�����܂��B�iSQL�G���[�FORA-XXXX �E�E�E�j�V�X�e      ���Ǘ��҂ɘA�����Ă��������B
  cv_tkn_number_11          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00140';  -- (�f�[�^������܂���B)
  cv_tkn_number_12          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00173';  -- �Q�ƃ^�C�v�Ȃ�
--
  -- �g�[�N���R�[�h
  cv_tkn_entry              CONSTANT VARCHAR2(5)   := 'ENTRY' ;             -- ENTRY
  cv_tkn_table              CONSTANT VARCHAR2(5)   := 'TABLE' ;             -- TABLE
  cv_tkn_api_name           CONSTANT VARCHAR2(10)  := 'API_NAME' ;          -- API_NAME
  cv_tkn_errmsg             CONSTANT VARCHAR2(10)  := 'ERR_MSG' ;           -- ERR_MSG
  cv_tkn_cnt                CONSTANT VARCHAR2(10)  := 'COUNT' ;             -- COUNT
  cv_tkn_task_name          CONSTANT VARCHAR2(10)  := 'TASK_NAME' ;         -- TASK_NAME
  cv_tkn_lookup_type_name   CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE_NAME' ;  -- LOOKUP_TYPE_NAME
  -- DEBUG_LOG�p���b�Z�[�W
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �O���[�o���ϐ�
  gn_resp_id                NUMBER(9);                                              -- �E��ID
  gv_report_meaning         VARCHAR2(100);                                          -- ���[��ʖ�
  gv_svf_form_name          VARCHAR2(50);                                           -- �t�H�[���l���t�@�C����
  gv_svf_query_name         VARCHAR2(50);                                           -- �N�G���[�l���t�@�C����  
  gt_employee_number        xxcso_resource_relations_v2.employee_number%TYPE;       -- �]�ƈ��ԍ�
  gt_work_base_code         xxcso_resource_relations_v2.work_base_code_new%TYPE;    -- �Ζ��n���_�R�[�h
  gt_group_number           xxcso_resource_relations_v2.group_number_new%TYPE;      -- �O���[�v�ԍ�
  gt_position_code          xxcso_resource_relations_v2.position_code_new%TYPE;     -- �E�ʃR�[�h
  gt_job_type_code          xxcso_resource_relations_v2.job_type_code_new%TYPE;     -- �E��R�[�h
  gt_group_leader_flag      xxcso_resource_relations_v2.group_leader_flag_new%TYPE; -- �O���[�v���敪
  gv_report_type            VARCHAR2(9);                                            -- ���͂��ꂽ���[���
  gv_base_code              VARCHAR2(9);                                            -- ���͂��ꂽ���_�R�[�h
  gd_year_month_day         DATE;                                                   -- ��N���̂P��
  gd_year_month_lastday     DATE;                                                   -- ��N���̖���
  gd_online_sysdate         DATE;                                                   -- ���ߓ����f�p
  gv_online_sysdate         VARCHAR2(8);                                            -- ���ߓ����f�e�X�g�p
  gv_year_month             VARCHAR2(6);                                            -- ���͂��ꂽ��N��
  gd_year_month             DATE;                                                   -- ���͂��ꂽ��N����Date�^
  gv_year_month_prev        VARCHAR2(6);                                            -- ��N���̐挎
  gv_year_prev              VARCHAR2(6);                                            -- ��N���̐�N
  gn_operation_days         NUMBER(5);                                              -- �ғ�����
  gn_operation_all_days     NUMBER(5);                                              -- �ғ��\����
  gv_work_base_code         xxcso_resource_relations_v2.work_base_code_new%TYPE;    -- �Ζ��n���_�R�[�h
  gv_is_salesman            VARCHAR2(6);                                            -- ���O�C�����[�U���c�ƈ�
  gv_is_groupleader         VARCHAR2(6);                                            -- ���O�C�����[�U���O���[�v���[�_
  -- 1��������v��A������тȂǂ̍��ڂ�ێ����郌�R�[�h�^��`
  TYPE g_get_one_day_date_rtype IS RECORD(
    plan_vs_amt             xxcso_rep_visit_sale_plan.plan_vs_amt_1%TYPE,           -- ����v��,�K��v��
    rslt_vs_amt             xxcso_rep_visit_sale_plan.rslt_vs_amt_1%TYPE,           -- �������,�K�����
    rslt_other_sales_amt    xxcso_rep_visit_sale_plan.rslt_other_sales_amt_1%TYPE,  -- ������сi�����_�[�i���j
    effective_num           xxcso_rep_visit_sale_plan.effective_num_1%TYPE,         -- �L������
    visit_sign              VARCHAR2(20)                                            -- �����K��L��
  );
  -- �P�������̔���v��A������тȂǂ̍��ڂ�ێ�����e�[�u���^��`
  TYPE g_get_one_day_ttype IS TABLE OF g_get_one_day_date_rtype INDEX BY PLS_INTEGER;
  -- ���o�f�[�^���i�[���R�[�h�^��`
  TYPE g_get_month_data_rtype IS RECORD(
    up_base_code               xxcso_rep_visit_sale_plan.up_base_code%TYPE,              -- ���_�R�[�h�i�e�j
    up_hub_name                xxcso_rep_visit_sale_plan.up_hub_name%TYPE,               -- ���_���́i�e�j
    base_code                  xxcso_rep_visit_sale_plan.base_code%TYPE,                 -- ���_�R�[�h
    hub_name                   xxcso_rep_visit_sale_plan.hub_name%TYPE,                  -- ���_����
    group_number               xxcso_rep_visit_sale_plan.group_number%TYPE,              -- �c�ƃO���[�v�ԍ�
    group_name                 xxcso_rep_visit_sale_plan.group_name%TYPE,                -- �c�ƃO���[�v��
    employee_number            xxcso_rep_visit_sale_plan.employee_number%TYPE,           -- �c�ƈ��R�[�h
    employee_name              xxcso_rep_visit_sale_plan.employee_name%TYPE,             -- �c�ƈ���
    business_high_type         xxcso_rep_visit_sale_plan.business_high_type%TYPE,        -- �Ƒԁi�啪�ށj
    business_high_name         xxcso_rep_visit_sale_plan.business_high_name%TYPE,        -- �Ƒԁi�啪�ށj��
    gvm_type                   xxcso_rep_visit_sale_plan.gvm_type%TYPE,                  -- ��ʁ^���̋@�^�l�b
    account_number             xxcso_rep_visit_sale_plan.account_number%TYPE,            -- �ڋq�R�[�h
    customer_name              xxcso_rep_visit_sale_plan.customer_name%TYPE,             -- �ڋq��
    route_no                   xxcso_rep_visit_sale_plan.route_no%TYPE,                  -- ���[�gNo
    last_year_rslt_sales_amt   xxcso_rep_visit_sale_plan.last_year_rslt_sales_amt%TYPE,  -- �O�N����
    last_mon_rslt_sales_amt    xxcso_rep_visit_sale_plan.last_mon_rslt_sales_amt%TYPE,   -- �挎����
    new_customer_num           xxcso_rep_visit_sale_plan.new_customer_num%TYPE,          -- �V�K�ڋq����
    new_vendor_num             xxcso_rep_visit_sale_plan.new_vendor_num%TYPE,            -- �V�K�u�c����
    new_customer_amt           xxcso_rep_visit_sale_plan.new_customer_amt%TYPE,          -- �V�K�ڋq�������
    new_vendor_amt             xxcso_rep_visit_sale_plan.new_vendor_amt%TYPE,            -- �V�K�u�c�������
    plan_sales_amt             xxcso_rep_visit_sale_plan.plan_sales_amt%TYPE,            -- ����\�Z
    l_get_one_day_tab          g_get_one_day_ttype,                                      -- ���ʃf�[�^�i�[�e�[�u���^
    vis_a_num                  NUMBER(9),                                                -- �K��`����
    vis_b_num                  NUMBER(9),                                                -- �K��a����
    vis_c_num                  NUMBER(9),                                                -- �K��b����
    vis_d_num                  NUMBER(9),                                                -- �K��c����
    vis_e_num                  NUMBER(9),                                                -- �K��d����
    vis_f_num                  NUMBER(9),                                                -- �K��e����
    vis_g_num                  NUMBER(9),                                                -- �K��f����
    vis_h_num                  NUMBER(9),                                                -- �K��g����
    vis_i_num                  NUMBER(9),                                                -- �K���@����
    vis_j_num                  NUMBER(9),                                                -- �K��i����
    vis_k_num                  NUMBER(9),                                                -- �K��j����
    vis_l_num                  NUMBER(9),                                                -- �K��k����
    vis_m_num                  NUMBER(9),                                                -- �K��l����
    vis_n_num                  NUMBER(9),                                                -- �K��m����
    vis_o_num                  NUMBER(9),                                                -- �K��n����
    vis_p_num                  NUMBER(9),                                                -- �K��o����
    vis_q_num                  NUMBER(9),                                                -- �K��p����
    vis_r_num                  NUMBER(9),                                                -- �K��q����
    vis_s_num                  NUMBER(9),                                                -- �K��r����
    vis_t_num                  NUMBER(9),                                                -- �K��s����
    vis_u_num                  NUMBER(9),                                                -- �K��t����
    vis_v_num                  NUMBER(9),                                                -- �K��u����
    vis_w_num                  NUMBER(9),                                                -- �K��v����
    vis_x_num                  NUMBER(9),                                                -- �K��w����
    vis_y_num                  NUMBER(9),                                                -- �K��x����
    vis_z_num                  NUMBER(9)                                                 -- �K��y����
  );
  -- ���o�f�[�^���i�[�e�[�u���^��`
  TYPE g_get_month_square_ttype IS TABLE OF g_get_month_data_rtype INDEX BY PLS_INTEGER;
  -- �c�ƈ��ʒ��[���R�[�h�i���[�P�j
  TYPE g_one_day_rtype1 IS RECORD(
    tgt_amt             xxcso_sum_visit_sale_rep.tgt_amt%TYPE,                -- ����v��
    rslt_amt            xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �������
    rslt_center_amt     xxcso_sum_visit_sale_rep.rslt_center_amt%TYPE,        -- �������_�Q�������
    tgt_vis_num         xxcso_sum_visit_sale_rep.tgt_vis_num%TYPE,            -- �K��v��
    vis_num             xxcso_sum_visit_sale_rep.vis_num%TYPE,                -- �K�����
    vis_sales_num       xxcso_sum_visit_sale_rep.vis_sales_num%TYPE,          -- �L������
    vis_new_num         xxcso_sum_visit_sale_rep.vis_new_num%TYPE,            -- �K����сi�V�K)
    vis_vd_new_num      xxcso_sum_visit_sale_rep.vis_vd_new_num%TYPE,         -- �K����сiVD�F�V�K�j
    visit_sign          VARCHAR2(20),                                         -- �����K��L��
    vis_a_num           NUMBER(9),                                            -- �K��`����
    vis_b_num           NUMBER(9),                                            -- �K��a����
    vis_c_num           NUMBER(9),                                            -- �K��b����
    vis_d_num           NUMBER(9),                                            -- �K��c����
    vis_e_num           NUMBER(9),                                            -- �K��d����
    vis_f_num           NUMBER(9),                                            -- �K��e����
    vis_g_num           NUMBER(9),                                            -- �K��f����
    vis_h_num           NUMBER(9),                                            -- �K��g����
    vis_i_num           NUMBER(9),                                            -- �K���@����
    vis_j_num           NUMBER(9),                                            -- �K��i����
    vis_k_num           NUMBER(9),                                            -- �K��j����
    vis_l_num           NUMBER(9),                                            -- �K��k����
    vis_m_num           NUMBER(9),                                            -- �K��l����
    vis_n_num           NUMBER(9),                                            -- �K��m����
    vis_o_num           NUMBER(9),                                            -- �K��n����
    vis_p_num           NUMBER(9),                                            -- �K��o����
    vis_q_num           NUMBER(9),                                            -- �K��p����
    vis_r_num           NUMBER(9),                                            -- �K��q����
    vis_s_num           NUMBER(9),                                            -- �K��r����
    vis_t_num           NUMBER(9),                                            -- �K��s����
    vis_u_num           NUMBER(9),                                            -- �K��t����
    vis_v_num           NUMBER(9),                                            -- �K��u����
    vis_w_num           NUMBER(9),                                            -- �K��v����
    vis_x_num           NUMBER(9),                                            -- �K��w����
    vis_y_num           NUMBER(9),                                            -- �K��x����
    vis_z_num           NUMBER(9)                                             -- �K��y����
  );
  TYPE g_one_day_ttype1 IS TABLE OF g_one_day_rtype1 INDEX BY PLS_INTEGER;
  TYPE g_month_rtype1 IS RECORD(
    work_base_code      xxcso_resource_relations_v2.work_base_code_new%TYPE,  -- �Ζ��n���_�R�[�h
    base_name           xxcso_resource_relations_v2.work_base_name_new%TYPE,  -- �Ζ��n���_��
    employee_number     xxcso_resource_relations_v2.employee_number%TYPE,     -- �]�ƈ��ԍ�
    name                xxcso_resource_relations_v2.full_name%TYPE,           -- �]�ƈ���
    gvm_type            xxcso_rep_visit_sale_plan.gvm_type%TYPE,              -- ��ʁ^���̋@�^�l�b
    account_number      xxcso_cust_accounts_v.account_number%TYPE,            -- �ڋq�R�[�h
    party_name          xxcso_cust_accounts_v.party_name%TYPE,                -- �ڋq��
    route_number        xxcso_cust_routes_v2.route_number%TYPE,               -- ���[�gNo
    business_high_type  xxcso_rep_visit_sale_plan.business_high_type%TYPE,    -- �Ƒԁi�啪�ށj
    business_high_name  xxcso_rep_visit_sale_plan.business_high_name%TYPE,    -- �Ƒԁi�啪�ށj��
    l_one_day_tab       g_one_day_ttype1,                                     -- ���ʃf�[�^�i�[
    cust_new_num        xxcso_sum_visit_sale_rep.cust_new_num%TYPE,           -- �ڋq�����i�V�K�j
    cust_vd_new_num     xxcso_sum_visit_sale_rep.cust_vd_new_num%TYPE,        -- �ڋq�����iVD�F�V�K�j
    rslt_amty           xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �O�N����
    rslt_amtm           xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �挎����
    tgt_sales_prsn_total_amt xxcso_sum_visit_sale_rep.tgt_sales_prsn_total_amt%TYPE   -- ���ʔ���\�Z
  );
  -- �c�ƃO���[�v�ʁi���[�Q�j
  TYPE g_one_day_rtype2 IS RECORD(
    tgt_amt             xxcso_sum_visit_sale_rep.tgt_amt%TYPE,                -- ����v��
    tgt_new_amt         xxcso_sum_visit_sale_rep.tgt_new_amt%TYPE,            -- ����v��i�V�K�j
    tgt_vd_new_amt      xxcso_sum_visit_sale_rep.tgt_vd_new_amt%TYPE,         -- ����v��iVD�F�V�K�j
    tgt_vd_amt          xxcso_sum_visit_sale_rep.tgt_vd_amt%TYPE,             -- ����v��iVD�j
    tgt_other_new_amt   xxcso_sum_visit_sale_rep.tgt_other_new_amt%TYPE,      -- ����v��iVD�ȊO�F�V�K�j
    tgt_other_amt       xxcso_sum_visit_sale_rep.tgt_other_amt%TYPE,          -- ����v��iVD�ȊO�j
    rslt_amt            xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �������
    rslt_new_amt        xxcso_sum_visit_sale_rep.rslt_new_amt%TYPE,           -- ������сi�V�K�j
    rslt_vd_new_amt     xxcso_sum_visit_sale_rep.rslt_vd_new_amt%TYPE,        -- ������сiVD�F�V�K�j
    rslt_vd_amt         xxcso_sum_visit_sale_rep.rslt_vd_amt%TYPE,            -- ������сiVD�j
    rslt_other_new_amt  xxcso_sum_visit_sale_rep.rslt_other_new_amt%TYPE,     -- ������сiVD�ȊO�F�V�K�j
    rslt_other_amt      xxcso_sum_visit_sale_rep.rslt_other_amt%TYPE,         -- ������сiVD�ȊO�j
    rslt_center_amt     xxcso_sum_visit_sale_rep.rslt_center_amt%TYPE,        -- �������_�Q�������
    tgt_vis_num         xxcso_sum_visit_sale_rep.tgt_vis_num%TYPE,            -- �K��v��
    tgt_vis_new_num     xxcso_sum_visit_sale_rep.tgt_vis_new_num%TYPE,        -- �K��v��i�V�K�j
    tgt_vis_vd_new_num  xxcso_sum_visit_sale_rep.tgt_vis_vd_new_num%TYPE,     -- �K��v��iVD�F�V�K�j
    tgt_vis_vd_num      xxcso_sum_visit_sale_rep.tgt_vis_vd_num%TYPE,         -- �K��v��iVD�j
    tgt_vis_other_new_num     xxcso_sum_visit_sale_rep.tgt_vis_other_new_num%TYPE,  -- �K��v��iVD�ȊO�F�V�K�j
    tgt_vis_mc_num      xxcso_sum_visit_sale_rep.tgt_vis_mc_num%TYPE,         -- �K��v��(MC)
    tgt_vis_other_num   xxcso_sum_visit_sale_rep.tgt_vis_other_num%TYPE,      -- �K��v��iVD�ȊO�j
    vis_num             xxcso_sum_visit_sale_rep.vis_num%TYPE,                -- �K�����
    vis_new_num         xxcso_sum_visit_sale_rep.vis_new_num%TYPE,            -- �K����сi�V�K�j
    vis_vd_new_num      xxcso_sum_visit_sale_rep.vis_vd_new_num%TYPE,         -- �K����сiVD�F�V�K�j
    vis_vd_num          xxcso_sum_visit_sale_rep.vis_vd_num%TYPE,             -- �K����сiVD�j
    vis_other_new_num   xxcso_sum_visit_sale_rep.vis_other_new_num%TYPE,      -- �K����сiVD�ȊO�F�V�K�j
    vis_other_num       xxcso_sum_visit_sale_rep.vis_other_num%TYPE,          -- �K����сiVD�ȊO�j
    vis_mc_num          xxcso_sum_visit_sale_rep.vis_mc_num%TYPE,             -- �K�����(MC)
    vis_sales_num       xxcso_sum_visit_sale_rep.vis_sales_num%TYPE,          -- �L������
    vis_a_num           NUMBER(9),                                            -- �K��`����
    vis_b_num           NUMBER(9),                                            -- �K��a����
    vis_c_num           NUMBER(9),                                            -- �K��b����
    vis_d_num           NUMBER(9),                                            -- �K��c����
    vis_e_num           NUMBER(9),                                            -- �K��d����
    vis_f_num           NUMBER(9),                                            -- �K��e����
    vis_g_num           NUMBER(9),                                            -- �K��f����
    vis_h_num           NUMBER(9),                                            -- �K��g����
    vis_i_num           NUMBER(9),                                            -- �K���@����
    vis_j_num           NUMBER(9),                                            -- �K��i����
    vis_k_num           NUMBER(9),                                            -- �K��j����
    vis_l_num           NUMBER(9),                                            -- �K��k����
    vis_m_num           NUMBER(9),                                            -- �K��l����
    vis_n_num           NUMBER(9),                                            -- �K��m����
    vis_o_num           NUMBER(9),                                            -- �K��n����
    vis_p_num           NUMBER(9),                                            -- �K��o����
    vis_q_num           NUMBER(9),                                            -- �K��p����
    vis_r_num           NUMBER(9),                                            -- �K��q����
    vis_s_num           NUMBER(9),                                            -- �K��r����
    vis_t_num           NUMBER(9),                                            -- �K��s����
    vis_u_num           NUMBER(9),                                            -- �K��t����
    vis_v_num           NUMBER(9),                                            -- �K��u����
    vis_w_num           NUMBER(9),                                            -- �K��v����
    vis_x_num           NUMBER(9),                                            -- �K��w����
    vis_y_num           NUMBER(9),                                            -- �K��x����
    vis_z_num           NUMBER(9)                                             -- �K��y����
  );
  TYPE g_one_day_ttype2 IS TABLE OF g_one_day_rtype2 INDEX BY PLS_INTEGER;
  TYPE g_month_rtype2 IS RECORD(
    work_base_code      xxcso_resource_relations_v2.work_base_code_new%TYPE,  -- �Ζ��n���_�R�[�h
    base_name           xxcso_resource_relations_v2.work_base_name_new%TYPE,  -- �Ζ��n���_��
    group_number        xxcso_resource_relations_v2.group_number_new%TYPE,    -- �c�ƃO���[�v�ԍ�
    group_name          VARCHAR2(160),                                        -- �c�ƃO���[�v��
    employee_number     xxcso_resource_relations_v2.employee_number%TYPE,     -- �]�ƈ��ԍ�
    name                xxcso_resource_relations_v2.full_name%TYPE,           -- �]�ƈ���
    gvm_type            xxcso_rep_visit_sale_plan.gvm_type%TYPE,              -- ��ʁ^���̋@�^�l�b
    l_one_day_tab       g_one_day_ttype2,                                     -- ���ʃf�[�^�i�[�i�e�[�u���^�j
    rslt_amty           xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �O�N����
    rslt_vd_amty        xxcso_sum_visit_sale_rep.rslt_vd_amt%TYPE,            -- �O�N���сiVD�j
    rslt_other_amty     xxcso_sum_visit_sale_rep.rslt_other_amt%TYPE,         -- �O�N���сiVD�ȊO�j
    rslt_amtm           xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �挎����
    rslt_vd_amtm        xxcso_sum_visit_sale_rep.rslt_vd_amt%TYPE,            -- �挎���сiVD�j
    rslt_other_amtm     xxcso_sum_visit_sale_rep.rslt_other_amt%TYPE,         -- �挎���сiVD�ȊO�j
    cust_new_num        xxcso_sum_visit_sale_rep.cust_new_num%TYPE,           -- �ڋq�����i�V�K�j
    cust_vd_new_num     xxcso_sum_visit_sale_rep.cust_vd_new_num%TYPE,        -- �ڋq�����iVD�F�V�K�j
    cust_other_new_num  xxcso_sum_visit_sale_rep.cust_other_new_num%TYPE,     -- �ڋq�����iVD�ȊO�F�V�K�j
    tgt_sales_prsn_total_amt xxcso_sum_visit_sale_rep.tgt_sales_prsn_total_amt%TYPE   -- ���ʔ���\�Z
  );
  -- ���_/�ەʁi���[�R�j
  TYPE g_one_day_rtype3 IS RECORD(
    tgt_amt                   xxcso_sum_visit_sale_rep.tgt_amt%TYPE,           -- ����v��
    tgt_new_amt               xxcso_sum_visit_sale_rep.tgt_new_amt%TYPE,       -- ����v��i�V�K�j
    tgt_vd_new_amt            xxcso_sum_visit_sale_rep.tgt_vd_new_amt%TYPE,    -- ����v��iVD�F�V�K�j
    tgt_vd_amt                xxcso_sum_visit_sale_rep.tgt_vd_amt%TYPE,        -- ����v��iVD�j
    tgt_other_new_amt         xxcso_sum_visit_sale_rep.tgt_other_new_amt%TYPE, -- ����v��iVD�ȊO�F�V�K�j
    tgt_other_amt             xxcso_sum_visit_sale_rep.tgt_other_amt%TYPE,     -- ����v��iVD�ȊO�j
    rslt_amt                  xxcso_sum_visit_sale_rep.rslt_amt%TYPE,          -- �������
    rslt_new_amt              xxcso_sum_visit_sale_rep.rslt_new_amt%TYPE,      -- ������сi�V�K�j
    rslt_vd_new_amt           xxcso_sum_visit_sale_rep.rslt_vd_new_amt%TYPE,   -- ������сiVD�F�V�K�j
    rslt_vd_amt               xxcso_sum_visit_sale_rep.rslt_vd_amt%TYPE,       -- ������сiVD�j
    rslt_other_new_amt        xxcso_sum_visit_sale_rep.rslt_other_new_amt%TYPE,-- ������сiVD�ȊO�F�V�K�j
    rslt_other_amt            xxcso_sum_visit_sale_rep.rslt_other_amt%TYPE,    -- ������сiVD�ȊO�j
    rslt_center_amt           xxcso_sum_visit_sale_rep.rslt_center_amt%TYPE,   -- �������_�Q�������
    rslt_center_vd_amt        xxcso_sum_visit_sale_rep.rslt_center_vd_amt%TYPE,    -- �������_�Q������сiVD�j
    rslt_center_other_amt     xxcso_sum_visit_sale_rep.rslt_center_other_amt%TYPE, -- �������_�Q������сiVD�ȊO�j
    tgt_vis_num               xxcso_sum_visit_sale_rep.tgt_vis_num%TYPE,       -- �K��v��
    tgt_vis_new_num           xxcso_sum_visit_sale_rep.tgt_vis_new_num%TYPE,   -- �K��v��i�V�K�j
    tgt_vis_vd_new_num        xxcso_sum_visit_sale_rep.tgt_vis_vd_new_num%TYPE,-- �K��v��iVD�F�V�K�j
    tgt_vis_vd_num            xxcso_sum_visit_sale_rep.tgt_vis_vd_num%TYPE,    -- �K��v��iVD�j
    tgt_vis_other_new_num     xxcso_sum_visit_sale_rep.tgt_vis_other_new_num%TYPE,-- �K��v��iVD�ȊO�F�V�K�j
    tgt_vis_other_num         xxcso_sum_visit_sale_rep.tgt_vis_other_num%TYPE, -- �K��v��iVD�ȊO�j
    tgt_vis_mc_num            xxcso_sum_visit_sale_rep.tgt_vis_mc_num%TYPE,    -- �K��v��(MC)
    vis_num                   xxcso_sum_visit_sale_rep.vis_num%TYPE,           -- �K�����
    vis_new_num               xxcso_sum_visit_sale_rep.vis_new_num%TYPE,       -- �K����сi�V�K�j
    vis_vd_new_num            xxcso_sum_visit_sale_rep.vis_vd_new_num%TYPE,    -- �K����сiVD�F�V�K�j
    vis_vd_num                xxcso_sum_visit_sale_rep.vis_vd_num%TYPE,        -- �K����сiVD�j
    vis_other_new_num         xxcso_sum_visit_sale_rep.vis_other_new_num%TYPE, -- �K����сiVD�ȊO�F�V�K�j
    vis_other_num             xxcso_sum_visit_sale_rep.vis_other_num%TYPE,     -- �K����сiVD�ȊO�j
    vis_mc_num                xxcso_sum_visit_sale_rep.vis_mc_num%TYPE,        -- �K�����(MC)
    vis_sales_num             xxcso_sum_visit_sale_rep.vis_sales_num%TYPE,     -- �L������
    vis_a_num                 NUMBER(9),                                       -- �K��`����
    vis_b_num                 NUMBER(9),                                       -- �K��a����
    vis_c_num                 NUMBER(9),                                       -- �K��b����
    vis_d_num                 NUMBER(9),                                       -- �K��c����
    vis_e_num                 NUMBER(9),                                       -- �K��d����
    vis_f_num                 NUMBER(9),                                       -- �K��e����
    vis_g_num                 NUMBER(9),                                       -- �K��f����
    vis_h_num                 NUMBER(9),                                       -- �K��g����
    vis_i_num                 NUMBER(9),                                       -- �K���@����
    vis_j_num                 NUMBER(9),                                       -- �K��i����
    vis_k_num                 NUMBER(9),                                       -- �K��j����
    vis_l_num                 NUMBER(9),                                       -- �K��k����
    vis_m_num                 NUMBER(9),                                       -- �K��l����
    vis_n_num                 NUMBER(9),                                       -- �K��m����
    vis_o_num                 NUMBER(9),                                       -- �K��n����
    vis_p_num                 NUMBER(9),                                       -- �K��o����
    vis_q_num                 NUMBER(9),                                       -- �K��p����
    vis_r_num                 NUMBER(9),                                       -- �K��q����
    vis_s_num                 NUMBER(9),                                       -- �K��r����
    vis_t_num                 NUMBER(9),                                       -- �K��s����
    vis_u_num                 NUMBER(9),                                       -- �K��t����
    vis_v_num                 NUMBER(9),                                       -- �K��u����
    vis_w_num                 NUMBER(9),                                       -- �K��v����
    vis_x_num                 NUMBER(9),                                       -- �K��w����
    vis_y_num                 NUMBER(9),                                       -- �K��x����
    vis_z_num                 NUMBER(9)                                        -- �K��y����
  );
  TYPE g_one_day_ttype3 IS TABLE OF g_one_day_rtype3 INDEX BY PLS_INTEGER;
  TYPE g_month_rtype3 IS RECORD(
    work_base_code            xxcso_resource_relations_v2.work_base_code_new%TYPE,  -- �Ζ��n���_�R�[�h
    base_name                 xxcso_resource_relations_v2.work_base_name_new%TYPE,  -- �Ζ��n���_��
    group_number              xxcso_resource_relations_v2.group_number_new%TYPE,    -- �c�ƃO���[�v�ԍ�
    group_name                VARCHAR2(160),                                        -- �c�ƃO���[�v��
    gvm_type                  xxcso_rep_visit_sale_plan.gvm_type%TYPE,              -- ��ʁ^���̋@�^�l�b
    l_one_day_tab             g_one_day_ttype3,                                     -- ���ʃf�[�^�i�[�i�e�[�u���^�j
    cust_new_num              xxcso_sum_visit_sale_rep.cust_new_num%TYPE,           -- �ڋq�����i�V�K�j
    cust_vd_new_num           xxcso_sum_visit_sale_rep.cust_vd_new_num%TYPE,        -- �ڋq�����iVD�F�V�K�j
    cust_other_new_num        xxcso_sum_visit_sale_rep.cust_other_new_num%TYPE,     -- �ڋq�����iVD�ȊO�F�V�K�j
    rslt_amty                 xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �O�N����
    rslt_vd_amty              xxcso_sum_visit_sale_rep.rslt_vd_amt%TYPE,            -- �O�N���сiVD�j
    rslt_other_amty           xxcso_sum_visit_sale_rep.rslt_other_amt%TYPE,         -- �O�N���сiVD�ȊO�j
    rslt_amtm                 xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �挎����
    rslt_vd_amtm              xxcso_sum_visit_sale_rep.rslt_vd_amt%TYPE,            -- �挎���сiVD�j
    rslt_other_amtm           xxcso_sum_visit_sale_rep.rslt_other_amt%TYPE,         -- �挎���сiVD�ȊO�j
    tgt_sales_prsn_total_amt  xxcso_sum_visit_sale_rep.tgt_sales_prsn_total_amt%TYPE   -- ���ʔ���\�Z
  );
  -- �n��c�ƕ��ʁi���[�S�j
  TYPE g_one_day_rtype4 IS RECORD(
    rslt_amt                  xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �������
    rslt_new_amt              xxcso_sum_visit_sale_rep.rslt_new_amt%TYPE,           -- ������сi�V�K�j
    rslt_vd_new_amt           xxcso_sum_visit_sale_rep.rslt_vd_new_amt%TYPE,        -- ������сiVD�F�V�K�j
    rslt_vd_amt               xxcso_sum_visit_sale_rep.rslt_vd_amt%TYPE,            -- ������сiVD�j
    rslt_other_new_amt        xxcso_sum_visit_sale_rep.rslt_other_new_amt%TYPE,     -- ������сiVD�ȊO�F�V�K�j
    rslt_other_amt            xxcso_sum_visit_sale_rep.rslt_other_amt%TYPE,         -- ������сiVD�ȊO�j
    rslt_center_amt           xxcso_sum_visit_sale_rep.rslt_center_amt%TYPE,        -- �������_�Q�������
    rslt_center_vd_amt        xxcso_sum_visit_sale_rep.rslt_center_vd_amt%TYPE,     -- �������_�Q������сiVD�j
    rslt_center_other_amt     xxcso_sum_visit_sale_rep.rslt_center_other_amt%TYPE,  -- �������_�Q������сiVD�ȊO�j
    vis_num                   xxcso_sum_visit_sale_rep.vis_num%TYPE,                -- �K�����
    vis_new_num               xxcso_sum_visit_sale_rep.vis_new_num%TYPE,            -- �K����сi�V�K�j
    vis_vd_new_num            xxcso_sum_visit_sale_rep.vis_vd_new_num%TYPE,         -- �K����сiVD�F�V�K�j
    vis_vd_num                xxcso_sum_visit_sale_rep.vis_vd_num%TYPE,             -- �K����сiVD�j
    vis_other_new_num         xxcso_sum_visit_sale_rep.vis_other_new_num%TYPE,      -- �K����сiVD�ȊO�F�V�K�j
    vis_other_num             xxcso_sum_visit_sale_rep.vis_other_num%TYPE,          -- �K����сiVD�ȊO�j
    vis_mc_num                xxcso_sum_visit_sale_rep.vis_mc_num%TYPE,             -- �K�����(MC)
    vis_sales_num             xxcso_sum_visit_sale_rep.vis_sales_num%TYPE,          -- �L������
    vis_a_num                 NUMBER(9),                                            -- �K��`����
    vis_b_num                 NUMBER(9),                                            -- �K��a����
    vis_c_num                 NUMBER(9),                                            -- �K��b����
    vis_d_num                 NUMBER(9),                                            -- �K��c����
    vis_e_num                 NUMBER(9),                                            -- �K��d����
    vis_f_num                 NUMBER(9),                                            -- �K��e����
    vis_g_num                 NUMBER(9),                                            -- �K��f����
    vis_h_num                 NUMBER(9),                                            -- �K��g����
    vis_i_num                 NUMBER(9),                                            -- �K���@����
    vis_j_num                 NUMBER(9),                                            -- �K��i����
    vis_k_num                 NUMBER(9),                                            -- �K��j����
    vis_l_num                 NUMBER(9),                                            -- �K��k����
    vis_m_num                 NUMBER(9),                                            -- �K��l����
    vis_n_num                 NUMBER(9),                                            -- �K��m����
    vis_o_num                 NUMBER(9),                                            -- �K��n����
    vis_p_num                 NUMBER(9),                                            -- �K��o����
    vis_q_num                 NUMBER(9),                                            -- �K��p����
    vis_r_num                 NUMBER(9),                                            -- �K��q����
    vis_s_num                 NUMBER(9),                                            -- �K��r����
    vis_t_num                 NUMBER(9),                                            -- �K��s����
    vis_u_num                 NUMBER(9),                                            -- �K��t����
    vis_v_num                 NUMBER(9),                                            -- �K��u����
    vis_w_num                 NUMBER(9),                                            -- �K��v����
    vis_x_num                 NUMBER(9),                                            -- �K��w����
    vis_y_num                 NUMBER(9),                                            -- �K��x����
    vis_z_num                 NUMBER(9)                                             -- �K��y����
  );
  TYPE g_one_day_ttype4 IS TABLE OF g_one_day_rtype4 INDEX BY PLS_INTEGER;
  TYPE g_month_rtype4 IS RECORD(
    base_code_par             xxcso_aff_base_level_v.base_code%TYPE,                -- �Ζ��n���_�R�[�h(�e)(���_�R�[�h)
    base_name_par             xxcso_aff_base_v2.base_name%TYPE,                     -- �Ζ��n���_��(�e)(���_��)
    base_code_chi             xxcso_aff_base_level_v.child_base_code%TYPE,          -- �Ζ��n���_�R�[�h
    base_name_chi             xxcso_aff_base_v2.base_name%TYPE,                     -- �Ζ��n���_��
    gvm_type                  xxcso_rep_visit_sale_plan.gvm_type%TYPE,              -- ��ʁ^���̋@�^�l�b
    l_one_day_tab             g_one_day_ttype4,                                     -- ���ʃf�[�^�i�[�i�e�[�u���^�j
    cust_new_num              xxcso_sum_visit_sale_rep.cust_new_num%TYPE,           -- �ڋq�����i�V�K�j
    cust_vd_new_num           xxcso_sum_visit_sale_rep.cust_vd_new_num%TYPE,        -- �ڋq�����iVD�F�V�K�j
    cust_other_new_num        xxcso_sum_visit_sale_rep.cust_other_new_num%TYPE,     -- �ڋq�����iVD�ȊO�F�V�K�j
    rslt_amty                 xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �O�N����
    rslt_vd_amty              xxcso_sum_visit_sale_rep.rslt_vd_amt%TYPE,            -- �O�N���сiVD�j
    rslt_other_amty           xxcso_sum_visit_sale_rep.rslt_other_amt%TYPE,         -- �O�N���сiVD�ȊO�j
    rslt_amtm                 xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �挎����
    rslt_vd_amtm              xxcso_sum_visit_sale_rep.rslt_vd_amt%TYPE,            -- �挎���сiVD�j
    rslt_other_amtm           xxcso_sum_visit_sale_rep.rslt_other_amt%TYPE,         -- �挎���сiVD�ȊO�j
    tgt_sales_prsn_total_amt  xxcso_sum_visit_sale_rep.tgt_sales_prsn_total_amt%TYPE   -- ���ʔ���\�Z
  );
  -- �n��c�Ɩ{���i���[�T�j
  TYPE g_one_day_rtype5 IS RECORD(
    rslt_amt                  xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �������
    rslt_new_amt              xxcso_sum_visit_sale_rep.rslt_new_amt%TYPE,           -- ������сi�V�K�j
    rslt_vd_new_amt           xxcso_sum_visit_sale_rep.rslt_vd_new_amt%TYPE,        -- ������сiVD�F�V�K�j
    rslt_vd_amt               xxcso_sum_visit_sale_rep.rslt_vd_amt%TYPE,            -- ������сiVD�j
    rslt_other_new_amt        xxcso_sum_visit_sale_rep.rslt_other_new_amt%TYPE,     -- ������сiVD�ȊO�F�V�K�j
    rslt_other_amt            xxcso_sum_visit_sale_rep.rslt_other_amt%TYPE,         -- ������сiVD�ȊO�j
    rslt_center_amt           xxcso_sum_visit_sale_rep.rslt_center_amt%TYPE,        -- �������_�Q�������
    rslt_center_vd_amt        xxcso_sum_visit_sale_rep.rslt_center_vd_amt%TYPE,     -- �������_�Q������сiVD�j
    rslt_center_other_amt     xxcso_sum_visit_sale_rep.rslt_center_other_amt%TYPE,  -- �������_�Q������сiVD�ȊO�j
    vis_num                   xxcso_sum_visit_sale_rep.vis_num%TYPE,                -- �K�����
    vis_new_num               xxcso_sum_visit_sale_rep.vis_new_num%TYPE,            -- �K����сi�V�K�j
    vis_vd_new_num            xxcso_sum_visit_sale_rep.vis_vd_new_num%TYPE,         -- �K����сiVD�F�V�K�j
    vis_vd_num                xxcso_sum_visit_sale_rep.vis_vd_num%TYPE,             -- �K����сiVD�j
    vis_other_new_num         xxcso_sum_visit_sale_rep.vis_other_new_num%TYPE,      -- �K����сiVD�ȊO�F�V�K�j
    vis_other_num             xxcso_sum_visit_sale_rep.vis_other_num%TYPE,          -- �K����сiVD�ȊO�j
    vis_mc_num                xxcso_sum_visit_sale_rep.vis_mc_num%TYPE,             -- �K�����(MC)
    vis_sales_num             xxcso_sum_visit_sale_rep.vis_sales_num%TYPE,          -- �L������
    vis_a_num                 NUMBER(9),                                            -- �K��`����
    vis_b_num                 NUMBER(9),                                            -- �K��a����
    vis_c_num                 NUMBER(9),                                            -- �K��b����
    vis_d_num                 NUMBER(9),                                            -- �K��c����
    vis_e_num                 NUMBER(9),                                            -- �K��d����
    vis_f_num                 NUMBER(9),                                            -- �K��e����
    vis_g_num                 NUMBER(9),                                            -- �K��f����
    vis_h_num                 NUMBER(9),                                            -- �K��g����
    vis_i_num                 NUMBER(9),                                            -- �K���@����
    vis_j_num                 NUMBER(9),                                            -- �K��i����
    vis_k_num                 NUMBER(9),                                            -- �K��j����
    vis_l_num                 NUMBER(9),                                            -- �K��k����
    vis_m_num                 NUMBER(9),                                            -- �K��l����
    vis_n_num                 NUMBER(9),                                            -- �K��m����
    vis_o_num                 NUMBER(9),                                            -- �K��n����
    vis_p_num                 NUMBER(9),                                            -- �K��o����
    vis_q_num                 NUMBER(9),                                            -- �K��p����
    vis_r_num                 NUMBER(9),                                            -- �K��q����
    vis_s_num                 NUMBER(9),                                            -- �K��r����
    vis_t_num                 NUMBER(9),                                            -- �K��s����
    vis_u_num                 NUMBER(9),                                            -- �K��t����
    vis_v_num                 NUMBER(9),                                            -- �K��u����
    vis_w_num                 NUMBER(9),                                            -- �K��v����
    vis_x_num                 NUMBER(9),                                            -- �K��w����
    vis_y_num                 NUMBER(9),                                            -- �K��x����
    vis_z_num                 NUMBER(9)                                             -- �K��y����
  );
  TYPE g_one_day_ttype5 IS TABLE OF g_one_day_rtype5 INDEX BY PLS_INTEGER;
  TYPE g_month_rtype5 IS RECORD(
    base_code_par             xxcso_aff_base_level_v.base_code%TYPE,                -- �Ζ��n���_�R�[�h(�e)(���_�R�[�h)
    base_name_par             xxcso_aff_base_v2.base_name%TYPE,                     -- �Ζ��n���_��(�e)(���_��)
    base_code_chi             xxcso_aff_base_level_v.child_base_code%TYPE,          -- �Ζ��n���_�R�[�h
    base_name_chi             xxcso_aff_base_v2.base_name%TYPE,                     -- �Ζ��n���_��
    gvm_type                  xxcso_rep_visit_sale_plan.gvm_type%TYPE,              -- ��ʁ^���̋@�^�l�b
    l_one_day_tab             g_one_day_ttype5,                                     -- ���ʃf�[�^�i�[�i�e�[�u���^�j
    cust_new_num              xxcso_sum_visit_sale_rep.cust_new_num%TYPE,           -- �ڋq�����i�V�K�j
    cust_vd_new_num           xxcso_sum_visit_sale_rep.cust_vd_new_num%TYPE,        -- �ڋq�����iVD�F�V�K�j
    cust_other_new_num        xxcso_sum_visit_sale_rep.cust_other_new_num%TYPE,     -- �ڋq�����iVD�ȊO�F�V�K�j
    rslt_amty                 xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �O�N����
    rslt_vd_amty              xxcso_sum_visit_sale_rep.rslt_vd_amt%TYPE,            -- �O�N���сiVD�j
    rslt_other_amty           xxcso_sum_visit_sale_rep.rslt_other_amt%TYPE,         -- �O�N���сiVD�ȊO�j
    rslt_amtm                 xxcso_sum_visit_sale_rep.rslt_amt%TYPE,               -- �挎����
    rslt_vd_amtm              xxcso_sum_visit_sale_rep.rslt_vd_amt%TYPE,            -- �挎���сiVD�j
    rslt_other_amtm           xxcso_sum_visit_sale_rep.rslt_other_amt%TYPE,         -- �挎���сiVD�ȊO�j
    tgt_sales_prsn_total_amt  xxcso_sum_visit_sale_rep.tgt_sales_prsn_total_amt%TYPE   -- ���ʔ���\�Z
  );
--
  /***********************************************************************************
   * Procedure Name   : debug
   * Description      : �f�o�b�O���O�o��
   ***********************************************************************************/
  PROCEDURE debug(
    buff                IN         VARCHAR2     -- �f�o�b�O���O
  )
  IS
  BEGIN
    IF ( CB_DEBUG_LOG = TRUE ) THEN
      fnd_file.put_line(
        which  => FND_FILE.LOG
       ,buff   => buff || cv_lf || ''   -- ��s�̑}��
      );
    END IF;
  END debug;
--
  /***********************************************************************************
   * Procedure Name   : do_error
   * Description      : ��O����
   ***********************************************************************************/
  PROCEDURE do_error(
    proc_no               IN         VARCHAR2     -- �����ԍ�
  )
  IS
    ln_cnt                NUMBER  := 1;
  BEGIN
    IF ( CB_DO_ERROR_NO =  proc_no ) THEN
      debug(
        buff  => '��O�e�X�g' || cv_lf ||
                 '�����ԍ���' || proc_no || 
                 cv_lf || ''
      );
      ln_cnt  :=  ln_cnt / 0;
    END IF;
  END do_error;
--
  /***********************************************************************************
   * Procedure Name   : init_month_square_hon_tab
   * Description      : PL/SQL�\�i�{�̕��j�̍��ڂ̏�����
   ***********************************************************************************/
  PROCEDURE init_month_square_hon_tab(
    io_tab            IN OUT NOCOPY  g_get_month_square_ttype           -- �z��
  )
  IS
  BEGIN
      FOR j IN 1..8 LOOP
        io_tab(j).last_year_rslt_sales_amt := 0;
        io_tab(j).last_mon_rslt_sales_amt  := 0;
        io_tab(j).new_customer_num         := 0;
        io_tab(j).new_vendor_num           := 0;
        io_tab(j).new_customer_amt         := 0;
        io_tab(j).new_vendor_amt           := 0;
        io_tab(j).plan_sales_amt           := 0;
        io_tab(j).vis_a_num                := 0;
        io_tab(j).vis_b_num                := 0;
        io_tab(j).vis_c_num                := 0;
        io_tab(j).vis_d_num                := 0;
        io_tab(j).vis_e_num                := 0;
        io_tab(j).vis_f_num                := 0;
        io_tab(j).vis_g_num                := 0;
        io_tab(j).vis_h_num                := 0;
        io_tab(j).vis_i_num                := 0;
        io_tab(j).vis_j_num                := 0;
        io_tab(j).vis_k_num                := 0;
        io_tab(j).vis_l_num                := 0;
        io_tab(j).vis_m_num                := 0;
        io_tab(j).vis_n_num                := 0;
        io_tab(j).vis_o_num                := 0;
        io_tab(j).vis_p_num                := 0;
        io_tab(j).vis_q_num                := 0;
        io_tab(j).vis_r_num                := 0;
        io_tab(j).vis_s_num                := 0;
        io_tab(j).vis_t_num                := 0;
        io_tab(j).vis_u_num                := 0;
        io_tab(j).vis_v_num                := 0;
        io_tab(j).vis_w_num                := 0;
        io_tab(j).vis_x_num                := 0;
        io_tab(j).vis_y_num                := 0;
        io_tab(j).vis_z_num                := 0;
        FOR i IN 1..31 LOOP
          io_tab(j).l_get_one_day_tab(i).plan_vs_amt           := 0;
          io_tab(j).l_get_one_day_tab(i).rslt_vs_amt           := 0;
          io_tab(j).l_get_one_day_tab(i).rslt_other_sales_amt  := 0;
          io_tab(j).l_get_one_day_tab(i).effective_num         := 0;
        END LOOP;
      END LOOP;
  END init_month_square_hon_tab;
--
  /***********************************************************************************
   * Procedure Name   : init_month_square_rec1
   * Description      : PL/SQL�\�i�ꃖ�����j�̍��ڂ̏�����
   ***********************************************************************************/
  PROCEDURE init_month_square_rec1(
    io_month_square_rec  IN  OUT NOCOPY     g_month_rtype1  -- �ꃖ�����f�[�^
  )
  IS
  BEGIN
      FOR i IN 1..31 LOOP
        io_month_square_rec.l_one_day_tab(i).tgt_amt                 :=0;
        io_month_square_rec.l_one_day_tab(i).rslt_amt                :=0;
        io_month_square_rec.l_one_day_tab(i).rslt_center_amt         :=0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_num             :=0;
        io_month_square_rec.l_one_day_tab(i).vis_num                 :=0;
        io_month_square_rec.l_one_day_tab(i).vis_sales_num           :=0;
        io_month_square_rec.l_one_day_tab(i).vis_new_num             :=0;
        io_month_square_rec.l_one_day_tab(i).vis_vd_new_num          :=0;
        io_month_square_rec.l_one_day_tab(i).visit_sign              :=NULL;
        io_month_square_rec.l_one_day_tab(i).vis_a_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_b_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_c_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_d_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_e_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_f_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_g_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_h_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_i_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_j_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_k_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_l_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_m_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_n_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_o_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_p_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_q_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_r_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_s_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_t_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_u_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_v_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_w_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_x_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_y_num               :=0;
        io_month_square_rec.l_one_day_tab(i).vis_z_num               :=0;
      END LOOP;
  END init_month_square_rec1;
--
  /***********************************************************************************
   * Procedure Name   : init_month_square_rec2
   * Description      : PL/SQL�\�i�ꃖ�����j�̍��ڂ̏�����
   ***********************************************************************************/
  PROCEDURE init_month_square_rec2(
    io_month_square_rec  IN  OUT NOCOPY     g_month_rtype2  -- �ꃖ�����f�[�^
  )
  IS
  BEGIN
      FOR i IN 1..31 LOOP
        io_month_square_rec.l_one_day_tab(i).tgt_amt                             := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_new_amt                         := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vd_new_amt                      := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vd_amt                          := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_other_new_amt                   := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_other_amt                       := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_amt                            := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_new_amt                        := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_vd_new_amt                     := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_vd_amt                         := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_other_new_amt                  := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_other_amt                      := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_center_amt                     := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_num                         := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_new_num                     := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_vd_new_num                  := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_vd_num                      := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_other_new_num               := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_other_num                   := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_mc_num                      := 0;
        io_month_square_rec.l_one_day_tab(i).vis_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_new_num                         := 0;
        io_month_square_rec.l_one_day_tab(i).vis_vd_new_num                      := 0;
        io_month_square_rec.l_one_day_tab(i).vis_vd_num                          := 0;
        io_month_square_rec.l_one_day_tab(i).vis_other_new_num                   := 0;
        io_month_square_rec.l_one_day_tab(i).vis_other_num                       := 0;
        io_month_square_rec.l_one_day_tab(i).vis_mc_num                          := 0;
        io_month_square_rec.l_one_day_tab(i).vis_sales_num                       := 0;
        io_month_square_rec.l_one_day_tab(i).vis_a_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_b_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_c_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_d_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_e_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_f_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_g_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_h_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_i_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_j_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_k_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_l_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_m_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_n_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_o_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_p_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_q_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_r_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_s_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_t_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_u_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_v_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_w_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_x_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_y_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_z_num                           := 0;
      END LOOP;
  END init_month_square_rec2;
--
  /***********************************************************************************
   * Procedure Name   : init_month_square_rec3
   * Description      : PL/SQL�\�i�ꃖ�����j�̍��ڂ̏�����
   ***********************************************************************************/
  PROCEDURE init_month_square_rec3(
    io_month_square_rec  IN  OUT NOCOPY     g_month_rtype3  -- �ꃖ�����f�[�^
  )
  IS
  BEGIN
      FOR i IN 1..31 LOOP
        io_month_square_rec.l_one_day_tab(i).tgt_amt                               := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_new_amt                           := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vd_new_amt                        := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vd_amt                            := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_other_new_amt                     := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_other_amt                         := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_amt                              := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_new_amt                          := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_vd_new_amt                       := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_vd_amt                           := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_other_new_amt                    := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_other_amt                        := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_center_amt                       := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_center_vd_amt                    := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_center_other_amt                 := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_new_num                       := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_vd_new_num                    := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_vd_num                        := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_other_new_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_other_num                     := 0;
        io_month_square_rec.l_one_day_tab(i).tgt_vis_mc_num                        := 0;
        io_month_square_rec.l_one_day_tab(i).vis_num                               := 0;
        io_month_square_rec.l_one_day_tab(i).vis_new_num                           := 0;
        io_month_square_rec.l_one_day_tab(i).vis_vd_new_num                        := 0;
        io_month_square_rec.l_one_day_tab(i).vis_vd_num                            := 0;
        io_month_square_rec.l_one_day_tab(i).vis_other_new_num                     := 0;
        io_month_square_rec.l_one_day_tab(i).vis_other_num                         := 0;
        io_month_square_rec.l_one_day_tab(i).vis_mc_num                            := 0;
        io_month_square_rec.l_one_day_tab(i).vis_sales_num                         := 0;
        io_month_square_rec.l_one_day_tab(i).vis_a_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_b_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_c_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_d_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_e_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_f_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_g_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_h_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_i_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_j_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_k_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_l_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_m_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_n_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_o_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_p_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_q_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_r_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_s_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_t_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_u_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_v_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_w_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_x_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_y_num                             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_z_num                             := 0;
      END LOOP;
  END init_month_square_rec3;
--
  /***********************************************************************************
   * Procedure Name   : init_month_square_rec4
   * Description      : PL/SQL�\�i�ꃖ�����j�̍��ڂ̏�����
   ***********************************************************************************/
  PROCEDURE init_month_square_rec4(
    io_month_square_rec  IN  OUT NOCOPY     g_month_rtype4  -- �ꃖ�����f�[�^
  )
  IS
  BEGIN
      FOR i IN 1..31 LOOP
        io_month_square_rec.l_one_day_tab(i).rslt_amt                  := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_new_amt              := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_vd_new_amt           := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_vd_amt               := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_other_new_amt        := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_other_amt            := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_center_amt           := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_center_vd_amt        := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_center_other_amt     := 0;
        io_month_square_rec.l_one_day_tab(i).vis_num                   := 0;
        io_month_square_rec.l_one_day_tab(i).vis_new_num               := 0;
        io_month_square_rec.l_one_day_tab(i).vis_vd_new_num            := 0;
        io_month_square_rec.l_one_day_tab(i).vis_vd_num                := 0;
        io_month_square_rec.l_one_day_tab(i).vis_other_new_num         := 0;
        io_month_square_rec.l_one_day_tab(i).vis_other_num             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_mc_num                := 0;
        io_month_square_rec.l_one_day_tab(i).vis_sales_num             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_a_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_b_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_c_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_d_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_e_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_f_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_g_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_h_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_i_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_j_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_k_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_l_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_m_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_n_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_o_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_p_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_q_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_r_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_s_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_t_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_u_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_v_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_w_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_x_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_y_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_z_num                 := 0;
      END LOOP;
  END init_month_square_rec4;
--
  /***********************************************************************************
   * Procedure Name   : init_month_square_rec5
   * Description      : PL/SQL�\�i�ꃖ�����j�̍��ڂ̏�����
   ***********************************************************************************/
  PROCEDURE init_month_square_rec5(
    io_month_square_rec  IN  OUT NOCOPY     g_month_rtype5  -- �ꃖ�����f�[�^
  )
  IS
  BEGIN
      FOR i IN 1..31 LOOP
        io_month_square_rec.l_one_day_tab(i).rslt_amt                  := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_new_amt              := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_vd_new_amt           := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_vd_amt               := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_other_new_amt        := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_other_amt            := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_center_amt           := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_center_vd_amt        := 0;
        io_month_square_rec.l_one_day_tab(i).rslt_center_other_amt     := 0;
        io_month_square_rec.l_one_day_tab(i).vis_num                   := 0;
        io_month_square_rec.l_one_day_tab(i).vis_new_num               := 0;
        io_month_square_rec.l_one_day_tab(i).vis_vd_new_num            := 0;
        io_month_square_rec.l_one_day_tab(i).vis_vd_num                := 0;
        io_month_square_rec.l_one_day_tab(i).vis_other_new_num         := 0;
        io_month_square_rec.l_one_day_tab(i).vis_other_num             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_mc_num                := 0;
        io_month_square_rec.l_one_day_tab(i).vis_sales_num             := 0;
        io_month_square_rec.l_one_day_tab(i).vis_a_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_b_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_c_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_d_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_e_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_f_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_g_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_h_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_i_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_j_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_k_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_l_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_m_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_n_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_o_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_p_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_q_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_r_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_s_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_t_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_u_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_v_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_w_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_x_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_y_num                 := 0;
        io_month_square_rec.l_one_day_tab(i).vis_z_num                 := 0;
      END LOOP;
  END init_month_square_rec5;
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_year_month       IN         VARCHAR2     -- ��N��
   ,iv_report_type      IN         VARCHAR2     -- ���[���
   ,iv_base_code        IN         VARCHAR2     -- ���_�R�[�h
   ,ov_errbuf           OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode          OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'init';              -- �v���O������
    cv_table            CONSTANT VARCHAR2(30)  := 'XXCSO_RESOURCE_RALATIONS_V'; -- ���\�[�X�֘A�}�X�^�r���[

--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  -- ���[�J���ϐ�
    lv_employee_number     xxcso_resource_relations_v2.employee_number%TYPE;      -- �]�ƈ��ԍ��i�[
    lv_work_base_code      xxcso_resource_relations_v2.work_base_code_new%TYPE;   -- �Ζ��n���_�R�[�h�i�[
    lv_group_number        xxcso_resource_relations_v2.group_number_new%TYPE;     -- �O���[�v�ԍ��i�[
    lv_position_code       xxcso_resource_relations_v2.position_code_new%TYPE;    -- �E�ʃR�[�h�i�[
    lv_job_type_code       xxcso_resource_relations_v2.job_type_code_new%TYPE;    -- �E��R�[�h�i�[
    lv_group_leader_flag   xxcso_resource_relations_v2.group_leader_flag_new%TYPE;-- �O���[�v���敪
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ���b�Z�[�W�o��
    -- ���͂��ꂽ��N�����O�ɏo��
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_01         --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_entry             --�g�[�N���R�[�h1
                    ,iv_token_value1 => iv_year_month            --�g�[�N���l1
                   );
    fnd_file.put_line(
          which  => FND_FILE.LOG,
          buff   => ''      || cv_lf ||     -- ��s�̑}��
                  lv_errmsg || cv_lf || 
                   ''                         -- ��s�̑}��
        );
--
    -- ==============================================================================
    -- ���[��ʔԍ��ɂ��A���[ID�A���[��ʖ��A�t�H�[���l���t�@�C�����A�N�G���[�l���t�@�C�������擾 
    -- ==============================================================================    
    -- ���[��ʖ����擾
    gv_report_meaning  := XXCSO_UTIL_COMMON_PKG.get_lookup_meaning(
                            iv_lookup_type           => cv_rep_lookup_type_code,  -- �^�C�v
                            iv_lookup_code           => iv_report_type,           -- �R�[�h
                            id_standard_date         => SYSDATE);                 -- ���
    IF ( gv_report_meaning IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_12         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name         -- �g�[�N���R�[�h1
                      ,iv_token_value1 => iv_report_type           -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_lookup_type_name  -- �g�[�N���R�[�h2
                      ,iv_token_value2 => cv_rep_lookup_type_code  -- �g�[�N���l2
                   );
      RAISE global_api_expt;
    END IF;
    -- �t�H�[���l���t�@�C�������擾
    gv_svf_form_name   := XXCSO_UTIL_COMMON_PKG.get_lookup_attribute(
                            iv_lookup_type           => cv_rep_lookup_type_code,  -- �^�C�v
                            iv_lookup_code           => iv_report_type,           -- �R�[�h
                            in_dff_number            => cv_svf_form_def_no,       -- DFF�ԍ�
                            id_standard_date         => SYSDATE);                 -- ���
    IF ( gv_svf_form_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_12         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name         -- �g�[�N���R�[�h1
                      ,iv_token_value1 => iv_report_type           -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_lookup_type_name  -- �g�[�N���R�[�h2
                      ,iv_token_value2 => cv_rep_lookup_type_code  -- �g�[�N���l2
                   );
      RAISE global_api_expt;
    END IF;
    -- �N�G���[�l���t�@�C�������擾
    gv_svf_query_name  := XXCSO_UTIL_COMMON_PKG.get_lookup_attribute(
                            iv_lookup_type           => cv_rep_lookup_type_code,  -- �^�C�v
                            iv_lookup_code           => iv_report_type,           -- �R�[�h
                            in_dff_number            => cv_svf_query_def_no,      -- DFF�ԍ�
                            id_standard_date         => SYSDATE);                 -- ���
    IF ( gv_svf_query_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_12         -- ���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_task_name         -- �g�[�N���R�[�h1
                      ,iv_token_value1 => iv_report_type           -- �g�[�N���l1
                      ,iv_token_name2  => cv_tkn_lookup_type_name  -- �g�[�N���R�[�h2
                      ,iv_token_value2 => cv_rep_lookup_type_code  -- �g�[�N���l2
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ���[��ʖ������O�ɏo��
    fnd_file.put_line(
          which  => FND_FILE.LOG,
          buff   => ''      || cv_lf ||                        -- ��s�̑}��
                  gv_report_meaning || cv_lf ||
                   ''                                            -- ��s�̑}��
        );
    -- ���͂��ꂽ���_�R�[�h�����O�ɏo��
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_03         --���b�Z�[�W�R�[�h
                    ,iv_token_name1  => cv_tkn_entry             --�g�[�N���R�[�h1
                    ,iv_token_value1 => iv_base_code             --�g�[�N���l1
                   );
    fnd_file.put_line(
          which  => FND_FILE.LOG,
          buff   => ''      || cv_lf ||     -- ��s�̑}��
                  lv_errmsg || cv_lf ||
                   ''                         -- ��s�̑}��
        );
    -- �t�H�[���l���t�@�C����
    lv_errmsg := '�t�H�[���l���t�@�C�����F' || gv_svf_form_name;
    fnd_file.put_line(
          which  => FND_FILE.LOG,
          buff   => ''      || cv_lf ||     -- ��s�̑}��
                  lv_errmsg || cv_lf ||
                   ''                       -- ��s�̑}��
    );
    -- �N�G���[�l���t�@�C����
    lv_errmsg := '�N�G���[�l���t�@�C�����F' || gv_svf_query_name;
    fnd_file.put_line(
          which  => FND_FILE.LOG,
          buff   => ''      || cv_lf ||     -- ��s�̑}��
                  lv_errmsg || cv_lf ||
                   ''                       -- ��s�̑}��
    );
    -- DEBUG���b�Z�[�W
    -- ���[�UID
    debug(
          buff   => ''      || cv_lf ||     -- ��s�̑}��
                  '���[�UID�F'||cn_created_by
    );
    -- �֘A�f�[�^�𒊏o���܂��B
    SELECT  xrrv.employee_number employee_number,    -- �]�ƈ��ԍ�
            (CASE
               WHEN TO_DATE(xrrv.issue_date,'YYYYMMDD') <= gd_online_sysdate
                 THEN xrrv.work_base_code_new
               ELSE xrrv.work_base_code_old
             END 
            ) work_base_code,                        -- �Ζ��n���_�R�[�h
            (CASE
               WHEN TO_DATE(xrrv.issue_date,'YYYYMMDD') <= gd_online_sysdate
                 THEN xrrv.group_number_new
               ELSE xrrv.group_number_old
             END  
            ) group_number                           -- �O���[�v�ԍ�
    INTO    lv_employee_number,                      -- �]�ƈ��ԍ�
            lv_work_base_code,                       -- �Ζ��n���_�R�[�h
            lv_group_number                          -- �O���[�v�ԍ�
    FROM    xxcso_resource_relations_v2 xrrv         -- ���\�[�X�֘A�}�X�^(�ŐV)VIEW
    WHERE   xrrv.user_id = cn_created_by;            -- ���O�C�����[�UID
--
DO_ERROR('A-1');
--
    -- �擾���ꂽ�f�[�^���O���[�o���ϐ��ɐݒ�
    gt_employee_number   := NVL(lv_employee_number,' ');                -- �]�ƈ��ԍ�
    gt_work_base_code    := NVL(lv_work_base_code,' ');                 -- �Ζ��n���_�R�[�h
    gt_group_number      := NVL(lv_group_number,' ');                   -- �O���[�v�ԍ�
    -- ���͂��ꂽ�p�����[�^���O���[�o���ϐ��Ɋi�[
    gv_year_month        := iv_year_month;                     -- ��N��
    gd_year_month        := TO_DATE(gv_year_month,'YYYYMM');
    gv_report_type       := iv_report_type;                    -- ���[���
    gv_base_code         := iv_base_code;                      -- ���_�R�[�h
--
    -- ���O�C�����[�U���c�ƈ�
    gv_is_salesman := xxcso_util_common_pkg.chk_responsibility(      -- ���O�C�����[�U���c�ƈ��̏ꍇ�̂�
                        cn_created_by
                       ,fnd_global.resp_id
                       ,'1'
                      );
    -- ���O�C�����[�U���O���[�v���[�_
    gv_is_groupleader := xxcso_util_common_pkg.chk_responsibility(      -- ���O�C�����[�U���O���[�v���[�_�̏ꍇ�̂�
                           cn_created_by
                          ,fnd_global.resp_id
                          ,'2'
                         );
--
    -- DEBUG���b�Z�[�W
    -- �擾�����f�[�^�����O�ɏo��
    debug(
       buff   => 'A-1 ���������F�擾���ꂽ�f�[�^�F'  || cv_lf ||
                  '�]�ƈ��ԍ�:'       || gt_employee_number   || cv_lf || 
                  '�Ζ��n���_�R�[�h:' || gt_work_base_code    || cv_lf || 
                  '�O���[�v�ԍ�:'     || gt_group_number      || cv_lf || 
                  '��N��:'         || gv_year_month        ||  cv_lf || 
                  '���[���:'         || gv_report_type       ||  cv_lf || 
                  '���_�R�[�h:'       || gv_base_code         ||  cv_lf || 
                  '���[��ʖ�:'       || gv_report_meaning    ||  cv_lf || 
                  '�t�H�[���l���t�@�C����:' || gv_svf_form_name  ||  cv_lf || 
                  '�N�G���[�l���t�@�C����:' || gv_svf_query_name || cv_lf || 
                  '���O�C��ID:'       || cn_created_by || cv_lf || 
                  'is�c�ƈ�:'         || gv_is_salesman || cv_lf || 
                  'is�O���[�v���[�_:' || gv_is_groupleader
     );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chek_param
   * Description      : �p�����[�^�`�F�b�N (A-2)
  ***********************************************************************************/
   PROCEDURE chek_param(
      ov_errbuf         OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
     ,ov_retcode        OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
     ,ov_errmsg         OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chek_param';     -- �v���O������
  --
  --#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  --###########################  �Œ蕔 END   ####################################
--
  -- ===============================
  -- ���[�U�[�錾��
  -- ===============================
  -- *** ���[�J���萔 ***
  -- *** ���[�J���ϐ� ***    
    lv_boolean                    VARCHAR2(5);              -- ���ʊ֐����^�[���l���i�[
    ld_year_month_lastday         DATE;                     -- ��N���������i�I�����C�����t�l���j
  --
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################ 
    -- ====================
    -- �ϐ����������� 
    -- ====================
    -- �E��ID���擾���܂��B
    gn_resp_id         := fnd_global.resp_id;
    -- ��N���̂P�����擾���ăO���[�o���ϐ��Ɋi�[
    gd_year_month_day  := TO_DATE(gv_year_month || '01','YYYYMMDD'); 
    -- ��N���̖������擾���ăO���[�o���ϐ��Ɋi�[
    gd_year_month_lastday := LAST_DAY(gd_year_month_day);
    -- ���͂��ꂽ��N�����ASYSDATE���܂߉ߋ��ł��邩���`�F�b�N���܂��B
    IF (gd_year_month_day > XXCSO_UTIL_COMMON_PKG.GET_ONLINE_SYSDATE()) THEN
      -- ���b�Z�[�W�o��
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                      ,iv_name         => cv_tkn_number_06         --���b�Z�[�W�R�[�h
                      ,iv_token_name1  => cv_tkn_entry             --�g�[�N���R�[�h1
                      ,iv_token_value1 => '��N��'               --�g�[�N���l1
                     );
      fnd_file.put_line(
            which  => FND_FILE.LOG,
            buff   => ''      || cv_lf ||     -- ��s�̑}��
                    lv_errmsg || cv_lf ||
                     ''                         -- ��s�̑}��
          );
      RAISE global_api_expt;
    END IF;
    -- DEBUG���b�Z�[�W
    -- ��N���̂P�������O�ɏo��
    debug(
       buff   => '��N���̂P��' || gd_year_month_day
     );

    -- ���͂��ꂽ���_�R�[�h�A���[��ʂɎ��s�������A���邩���`�F�b�N���܂��B
    xxcso_util_common_pkg.chk_exe_report_visite_sales(
       in_user_id     => fnd_global.user_id
      ,in_resp_id     => gn_resp_id
      ,iv_base_code   => gv_base_code
      ,iv_report_type => gv_report_type
      ,ov_ret_code    => lv_boolean
      ,ov_err_msg     => lv_errmsg
    );
--
DO_ERROR('A-2-2');
--
-- TODO �e�X�g�̂��߈ꎞ�ɒʉ߂����܂��B
--    lv_boolean := cv_true;
--
    IF lv_boolean = cv_false THEN
      debug(
        buff   => ''      || cv_lf ||     -- ��s�̑}��
                lv_errmsg
      );
      RAISE global_api_expt;
    END IF;
    -- ���̓p�����[�^�̊�N�����A�ғ����������擾���܂��B
    -- ��N���̖������擾���ăO���[�o���ϐ��Ɋi�[
    SELECT
          (CASE 
            WHEN XXCSO_UTIL_COMMON_PKG.GET_ONLINE_SYSDATE() < LAST_DAY(gd_year_month_day)  
              THEN XXCSO_UTIL_COMMON_PKG.GET_ONLINE_SYSDATE()
          ELSE
          LAST_DAY(gd_year_month_day)
          END)
    INTO      ld_year_month_lastday             -- ��N���̖���
    FROM      DUAL;
--
DO_ERROR('A-2-3');
--
    -- ��N���̐挎���擾���ăO���[�o���ϐ��Ɋi�[
    gv_year_month_prev    := TO_CHAR(add_months(gd_year_month_day,-1),'YYYYMM');
    -- ��N���̑O�N���擾���ăO���[�o���ϐ��Ɋi�[
    gv_year_prev          := TO_CHAR(add_months(gd_year_month_day,-12),'YYYYMM');
    -- �ғ��������擾���ăO���[�o���ϐ��Ɋi�[
    gn_operation_days     := xxcso_util_common_pkg.get_working_days(
                              gd_year_month_day,TRUNC(ld_year_month_lastday));
    -- �ғ��\�������擾���ăO���[�o���ϐ��Ɋi�[
    gn_operation_all_days := xxcso_util_common_pkg.get_working_days(
                              gd_year_month_day,gd_year_month_lastday);
    -- DEBUG���b�Z�[�W
    -- �擾���ꂽ���t�������O�ɏo��
    debug(
       buff   => '��N���̖���:' ||gd_year_month_lastday || 
                 '��N���̐挎:' ||gv_year_month_prev || 
                 '��N���̑O�N:' ||gv_year_prev ||
                 '�ғ�����:'||gn_operation_days || 
                 '�ғ��\����:'||gn_operation_all_days
     );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END chek_param;
--
  /**********************************************************************************
   * Procedure Name   : insert_wrk_table
   * Description      : ���[�N�e�[�u���ւ̏o�� (A-3-4,A-4-4,A-5-4,A-6-4,A-7-4)
  ***********************************************************************************/
  PROCEDURE insert_wrk_table(
     ir_m_tab            IN  g_get_month_square_ttype         -- ���ו����R�[�h
    ,ir_hon_tab          IN  g_get_month_square_ttype         -- �{�̕����R�[�h
    ,in_m_cnt            IN         NUMBER                           -- ���ו��s��
    ,in_report_output_no IN         NUMBER                           -- ���[�o�̓Z�b�g�ԍ�
    ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
  cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_wrk_table';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
  lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
  lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
  lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
  -- ���[�J���萔
  -- ���[�J���ϐ�
  lv_up_base_code            xxcso_rep_visit_sale_plan.up_base_code%TYPE;           -- ���_�R�[�h�i�e�j
  lv_up_hub_name             xxcso_rep_visit_sale_plan.up_hub_name%TYPE;            -- ���_���́i�e�j
  lv_base_code               xxcso_rep_visit_sale_plan.base_code%TYPE;              -- ���_�R�[�h
  lv_hub_name                xxcso_rep_visit_sale_plan.hub_name%TYPE;               -- ���_����
  lv_group_number            xxcso_rep_visit_sale_plan.group_number%TYPE;           -- �c�ƃO���[�v�ԍ�
  lv_group_name              xxcso_rep_visit_sale_plan.group_name%TYPE;             -- �c�ƃO���[�v��
  lv_employee_number         xxcso_rep_visit_sale_plan.employee_number%TYPE;        -- �c�ƈ��R�[�h
  lv_employee_name           xxcso_rep_visit_sale_plan.employee_name%TYPE;          -- �c�ƈ���
  lv_report_id               xxcso_rep_visit_sale_plan.report_id%TYPE;              -- ���[ID
  lv_report_name             xxcso_rep_visit_sale_plan.report_name%TYPE;            -- ���[�^�C�g��
  ln_line_kind               xxcso_rep_visit_sale_plan.line_kind%TYPE;              -- ���[�o�͈ʒu
  ln_line_num                xxcso_rep_visit_sale_plan.line_num%TYPE;               -- �s�ԍ�
  ln_m_cnt                   NUMBER;
  BEGIN
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- ���[�J���ϐ��̏�����
    -- ���[id�ɂ���Ē��[�^�C�g���𔻒f���܂��B
    -- DEBUG���b�Z�[�W
    -- ���[�N�e�[�u���ւ̏o��
    debug(
       buff   => '���[�N�e�[�u���ւ̏o�͊J�n :' || '���ו��z��F' || TO_CHAR(in_m_cnt)
     );
    IF(gv_report_type = cv_report_1) THEN
      lv_report_name := '��'|| SUBSTR(gv_year_month,1,4) ||'�N' ||
      SUBSTR(gv_year_month,5,2) || '��' || '����K��v��Ǘ��\�i�c�ƈ��ʁj' || '��';
      lv_report_id   := cv_pkg_name;
    ELSIF(gv_report_type = cv_report_2) THEN
      lv_report_name := '��'|| SUBSTR(gv_year_month,1,4) ||'�N' ||
      SUBSTR(gv_year_month,5,2) || '��' || '����K��v��Ǘ��\�i�c�ƈ��O���[�v�ʁj' || '��';
      lv_report_id   := cv_pkg_name;
    ELSIF(gv_report_type = cv_report_3) THEN
      lv_report_name := '��'|| SUBSTR(gv_year_month,1,4) ||'�N' ||
      SUBSTR(gv_year_month,5,2) || '��' || '����K��v��Ǘ��\�i���_/�ەʁj' || '��';
      lv_report_id   := cv_pkg_name;
    ELSIF(gv_report_type = cv_report_4) THEN
      lv_report_name := '��'|| SUBSTR(gv_year_month,1,4) ||'�N' ||
      SUBSTR(gv_year_month,5,2) || '��' || '����K��v��Ǘ��\�i�n��c�ƕ�/���ʁj' || '��';
      lv_report_id   := cv_pkg_name;
    ELSIF(gv_report_type = cv_report_5) THEN
      lv_report_name := '��'|| SUBSTR(gv_year_month,1,4) ||'�N' ||
      SUBSTR(gv_year_month,5,2) || '��' || '����K��v��Ǘ��\�i�n��c�Ɩ{���ʁj' || '��';
      lv_report_id   := cv_pkg_name;
    END IF;
    -- DEBUG���b�Z�[�W
    -- ���[�^�C�g��
    debug(
       buff   => '���[�^�C�g�� :' || lv_report_name
     );
    -- �K�⒠�[���[�N�e�[�u���ɏo��
    -- ���ו�
    FOR i IN 1..(in_m_cnt) LOOP
      BEGIN
        ln_line_kind              := cn_line_kind2;              -- ���[�o�͈ʒu
        ln_line_num               := i;                          -- �s�ԍ�
        INSERT INTO xxcso_rep_visit_sale_plan(
           report_output_no               -- ���[�o�̓Z�b�g�ԍ�
          ,line_kind                      -- ���[�o�͈ʒu
          ,line_num                       -- �s�ԍ�
          ,report_id                      -- ���[�h�c
          ,report_name                    -- ���[�^�C�g��
          ,output_date                    -- �o�͓���
          ,year_month                     -- ��N��
          ,operation_days                 -- �ғ�����
          ,operation_all_days             -- �ғ��\����
          ,up_base_code                   -- ���_�R�[�h�i�e�j
          ,up_hub_name                    -- ���_���́i�e�j
          ,base_code                      -- ���_�R�[�h
          ,hub_name                       -- ���_����
          ,group_number                   -- �c�ƃO���[�v�ԍ�
          ,group_name                     -- �c�ƃO���[�v��
          ,employee_number                -- �c�ƈ��R�[�h
          ,employee_name                  -- �c�ƈ���
          ,business_high_type             -- �Ƒԁi�啪�ށj
          ,business_high_name             -- �Ƒԁi�啪�ށj��
          ,gvm_type                       -- ��ʁ^���̋@�^�l�b
          ,account_number                 -- �ڋq�R�[�h
          ,customer_name                  -- �ڋq��
          ,route_no                       -- ���[�gNo
          ,last_year_rslt_sales_amt       -- �O�N����
          ,last_mon_rslt_sales_amt        -- �挎����
          ,new_customer_num               -- �V�K�ڋq����
          ,new_vendor_num                 -- �V�K�u�c����
          ,new_customer_amt               -- �V�K�ڋq�������
          ,new_vendor_amt                 -- �V�K�u�c�������
          ,plan_sales_amt                 -- ����\�Z
          ,plan_vs_amt_1                  -- �P���|����^�K��v��
          ,rslt_vs_amt_1                  -- �P���|����^�K�����
          ,rslt_other_sales_amt_1         -- �P���|������сi�����_�[�i���j
          ,effective_num_1                -- �P���|�L������
          ,visit_sign_1                   -- �P���|�K��L��
          ,plan_vs_amt_2                  -- �Q���|����^�K��v��
          ,rslt_vs_amt_2                  -- �Q���|����^�K�����
          ,rslt_other_sales_amt_2         -- �Q���|������сi�����_�[�i���j
          ,effective_num_2                -- �Q���|�L������
          ,visit_sign_2                   -- �Q���|�K��L��
          ,plan_vs_amt_3                  -- �R���|����^�K��v��
          ,rslt_vs_amt_3                  -- �R���|����^�K�����
          ,rslt_other_sales_amt_3         -- �R���|������сi�����_�[�i���j
          ,effective_num_3                -- �R���|�L������
          ,visit_sign_3                   -- �R���|�K��L��
          ,plan_vs_amt_4                  -- �S���|����^�K��v��
          ,rslt_vs_amt_4                  -- �S���|����^�K�����
          ,rslt_other_sales_amt_4         -- �S���|������сi�����_�[�i���j
          ,effective_num_4                -- �S���|�L������
          ,visit_sign_4                   -- �S���|�K��L��
          ,plan_vs_amt_5                  -- �T���|����^�K��v��
          ,rslt_vs_amt_5                  -- �T���|����^�K�����
          ,rslt_other_sales_amt_5         -- �T���|������сi�����_�[�i���j
          ,effective_num_5                -- �T���|�L������
          ,visit_sign_5                   -- �T���|�K��L��
          ,plan_vs_amt_6                  -- �U���|����^�K��v��
          ,rslt_vs_amt_6                  -- �U���|����^�K�����
          ,rslt_other_sales_amt_6         -- �U���|������сi�����_�[�i���j
          ,effective_num_6                -- �U���|�L������
          ,visit_sign_6                   -- �U���|�K��L��
          ,plan_vs_amt_7                  -- �V���|����^�K��v��
          ,rslt_vs_amt_7                  -- �V���|����^�K�����
          ,rslt_other_sales_amt_7         -- �V���|������сi�����_�[�i���j
          ,effective_num_7                -- �V���|�L������
          ,visit_sign_7                   -- �V���|�K��L��
          ,plan_vs_amt_8                  -- �W���|����^�K��v��
          ,rslt_vs_amt_8                  -- �W���|����^�K�����
          ,rslt_other_sales_amt_8         -- �W���|������сi�����_�[�i���j
          ,effective_num_8                -- �W���|�L������
          ,visit_sign_8                   -- �W���|�K��L��
          ,plan_vs_amt_9                  -- �X���|����^�K��v��
          ,rslt_vs_amt_9                  -- �X���|����^�K�����
          ,rslt_other_sales_amt_9         -- �X���|������сi�����_�[�i���j
          ,effective_num_9                -- �X���|�L������
          ,visit_sign_9                   -- �X���|�K��L��
          ,plan_vs_amt_10                 -- �P�O���|����^�K��v��
          ,rslt_vs_amt_10                 -- �P�O���|����^�K�����
          ,rslt_other_sales_amt_10        -- �P�O���|������сi�����_�[�i���j
          ,effective_num_10               -- �P�O���|�L������
          ,visit_sign_10                  -- �P�O���|�K��L��
          ,plan_vs_amt_11                 -- �P�P���|����^�K��v��
          ,rslt_vs_amt_11                 -- �P�P���|����^�K�����
          ,rslt_other_sales_amt_11        -- �P�P���|������сi�����_�[�i���j
          ,effective_num_11               -- �P�P���|�L������
          ,visit_sign_11                  -- �P�P���|�K��L��
          ,plan_vs_amt_12                 -- �P�Q���|����^�K��v��
          ,rslt_vs_amt_12                 -- �P�Q���|����^�K�����
          ,rslt_other_sales_amt_12        -- �P�Q���|������сi�����_�[�i���j
          ,effective_num_12               -- �P�Q���|�L������
          ,visit_sign_12                  -- �P�Q���|�K��L��
          ,plan_vs_amt_13                 -- �P�R���|����^�K��v��
          ,rslt_vs_amt_13                 -- �P�R���|����^�K�����
          ,rslt_other_sales_amt_13        -- �P�R���|������сi�����_�[�i���j
          ,effective_num_13               -- �P�R���|�L������
          ,visit_sign_13                  -- �P�R���|�K��L��
          ,plan_vs_amt_14                 -- �P�S���|����^�K��v��
          ,rslt_vs_amt_14                 -- �P�S���|����^�K�����
          ,rslt_other_sales_amt_14        -- �P�S���|������сi�����_�[�i���j
          ,effective_num_14               -- �P�S���|�L������
          ,visit_sign_14                  -- �P�S���|�K��L��
          ,plan_vs_amt_15                 -- �P�T���|����^�K��v��
          ,rslt_vs_amt_15                 -- �P�T���|����^�K�����
          ,rslt_other_sales_amt_15        -- �P�T���|������сi�����_�[�i���j
          ,effective_num_15               -- �P�T���|�L������
          ,visit_sign_15                  -- �P�T���|�K��L��
          ,plan_vs_amt_16                 -- �P�U���|����^�K��v��
          ,rslt_vs_amt_16                 -- �P�U���|����^�K�����
          ,rslt_other_sales_amt_16        -- �P�U���|������сi�����_�[�i���j
          ,effective_num_16               -- �P�U���|�L������
          ,visit_sign_16                  -- �P�U���|�K��L��
          ,plan_vs_amt_17                 -- �P�V���|����^�K��v��
          ,rslt_vs_amt_17                 -- �P�V���|����^�K�����
          ,rslt_other_sales_amt_17        -- �P�V���|������сi�����_�[�i���j
          ,effective_num_17               -- �P�V���|�L������
          ,visit_sign_17                  -- �P�V���|�K��L��
          ,plan_vs_amt_18                 -- �P�W���|����^�K��v��
          ,rslt_vs_amt_18                 -- �P�W���|����^�K�����
          ,rslt_other_sales_amt_18        -- �P�W���|������сi�����_�[�i���j
          ,effective_num_18               -- �P�W���|�L������
          ,visit_sign_18                  -- �P�W���|�K��L��
          ,plan_vs_amt_19                 -- �P�X���|����^�K��v��
          ,rslt_vs_amt_19                 -- �P�X���|����^�K�����
          ,rslt_other_sales_amt_19        -- �P�X���|������сi�����_�[�i���j
          ,effective_num_19               -- �P�X���|�L������
          ,visit_sign_19                  -- �P�X���|�K��L��
          ,plan_vs_amt_20                 -- �Q�O���|����^�K��v��
          ,rslt_vs_amt_20                 -- �Q�O���|����^�K�����
          ,rslt_other_sales_amt_20        -- �Q�O���|������сi�����_�[�i���j
          ,effective_num_20               -- �Q�O���|�L������
          ,visit_sign_20                  -- �Q�O���|�K��L��
          ,plan_vs_amt_21                 -- �Q�P���|����^�K��v��
          ,rslt_vs_amt_21                 -- �Q�P���|����^�K�����
          ,rslt_other_sales_amt_21        -- �Q�P���|������сi�����_�[�i���j
          ,effective_num_21               -- �Q�P���|�L������
          ,visit_sign_21                  -- �Q�P���|�K��L��
          ,plan_vs_amt_22                 -- �Q�Q���|����^�K��v��
          ,rslt_vs_amt_22                 -- �Q�Q���|����^�K�����
          ,rslt_other_sales_amt_22        -- �Q�Q���|������сi�����_�[�i���j
          ,effective_num_22               -- �Q�Q���|�L������
          ,visit_sign_22                  -- �Q�Q���|�K��L��
          ,plan_vs_amt_23                 -- �Q�R���|����^�K��v��
          ,rslt_vs_amt_23                 -- �Q�R���|����^�K�����
          ,rslt_other_sales_amt_23        -- �Q�R���|������сi�����_�[�i���j
          ,effective_num_23               -- �Q�R���|�L������
          ,visit_sign_23                  -- �Q�R���|�K��L��
          ,plan_vs_amt_24                 -- �Q�S���|����^�K��v��
          ,rslt_vs_amt_24                 -- �Q�S���|����^�K�����
          ,rslt_other_sales_amt_24        -- �Q�S���|������сi�����_�[�i���j
          ,effective_num_24               -- �Q�S���|�L������
          ,visit_sign_24                  -- �Q�S���|�K��L��
          ,plan_vs_amt_25                 -- �Q�T���|����^�K��v��
          ,rslt_vs_amt_25                 -- �Q�T���|����^�K�����
          ,rslt_other_sales_amt_25        -- �Q�T���|������сi�����_�[�i���j
          ,effective_num_25               -- �Q�T���|�L������
          ,visit_sign_25                  -- �Q�T���|�K��L��
          ,plan_vs_amt_26                 -- �Q�U���|����^�K��v��
          ,rslt_vs_amt_26                 -- �Q�U���|����^�K�����
          ,rslt_other_sales_amt_26        -- �Q�U���|������сi�����_�[�i���j
          ,effective_num_26               -- �Q�U���|�L������
          ,visit_sign_26                  -- �Q�U���|�K��L��
          ,plan_vs_amt_27                 -- �Q�V���|����^�K��v��
          ,rslt_vs_amt_27                 -- �Q�V���|����^�K�����
          ,rslt_other_sales_amt_27        -- �Q�V���|������сi�����_�[�i���j
          ,effective_num_27               -- �Q�V���|�L������
          ,visit_sign_27                  -- �Q�V���|�K��L��
          ,plan_vs_amt_28                 -- �Q�W���|����^�K��v��
          ,rslt_vs_amt_28                 -- �Q�W���|����^�K�����
          ,rslt_other_sales_amt_28        -- �Q�W���|������сi�����_�[�i���j
          ,effective_num_28               -- �Q�W���|�L������
          ,visit_sign_28                  -- �Q�W���|�K��L��
          ,plan_vs_amt_29                 -- �Q�X���|����^�K��v��
          ,rslt_vs_amt_29                 -- �Q�X���|����^�K�����
          ,rslt_other_sales_amt_29        -- �Q�X���|������сi�����_�[�i���j
          ,effective_num_29               -- �Q�X���|�L������
          ,visit_sign_29                  -- �Q�X���|�K��L��
          ,plan_vs_amt_30                 -- �R�O���|����^�K��v��
          ,rslt_vs_amt_30                 -- �R�O���|����^�K�����
          ,rslt_other_sales_amt_30        -- �R�O���|������сi�����_�[�i���j
          ,effective_num_30               -- �R�O���|�L������
          ,visit_sign_30                  -- �R�O���|�K��L��
          ,plan_vs_amt_31                 -- �R�P���|����^�K��v��
          ,rslt_vs_amt_31                 -- �R�P���|����^�K�����
          ,rslt_other_sales_amt_31        -- �R�P���|������сi�����_�[�i���j
          ,effective_num_31               -- �R�P���|�L������
          ,visit_sign_31                  -- �R�P���|�K��L��
          ,vis_a_num                      -- �K��`����
          ,vis_b_num                      -- �K��a����
          ,vis_c_num                      -- �K��b����
          ,vis_d_num                      -- �K��c����
          ,vis_e_num                      -- �K��d����
          ,vis_f_num                      -- �K��e����
          ,vis_g_num                      -- �K��f����
          ,vis_h_num                      -- �K��g����
          ,vis_i_num                      -- �K���@����
          ,vis_j_num                      -- �K��i����
          ,vis_k_num                      -- �K��j����
          ,vis_l_num                      -- �K��k����
          ,vis_m_num                      -- �K��l����
          ,vis_n_num                      -- �K��m����
          ,vis_o_num                      -- �K��n����
          ,vis_p_num                      -- �K��o����
          ,vis_q_num                      -- �K��p����
          ,vis_r_num                      -- �K��q����
          ,vis_s_num                      -- �K��r����
          ,vis_t_num                      -- �K��s����
          ,vis_u_num                      -- �K��t����
          ,vis_v_num                      -- �K��u����
          ,vis_w_num                      -- �K��v����
          ,vis_x_num                      -- �K��w����
          ,vis_y_num                      -- �K��x����
          ,vis_z_num                      -- �K��y����
          ,created_by                     -- �쐬��
          ,creation_date                  -- �쐬��
          ,last_updated_by                -- �ŏI�X�V��
          ,last_update_date               -- �ŏI�X�V��
          ,last_update_login              -- �ŏI�X�V���O�C��
          ,request_id                     -- �v��ID
          ,program_application_id         -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,program_id                     -- �R���J�����g�E�v���O����ID
          ,program_update_date            -- �v���O�����X�V��
          )
          VALUES(
           in_report_output_no                              -- ���[�o�̓Z�b�g�ԍ�
          ,ln_line_kind                                     -- ���[�o�͈ʒu
          ,ln_line_num                                      -- �s�ԍ�
          ,NULL                                             -- ���[�h�c
          ,NULL                                             -- ���[�^�C�g��
          ,NULL                                             -- �o�͓���
          ,NULL                                             -- ��N��
          ,NULL                                             -- �ғ�����
          ,NULL                                             -- �ғ��\����
          ,ir_m_tab(i).up_base_code                         -- ���_�R�[�h�i�e�j
          ,ir_m_tab(i).up_hub_name                          -- ���_���́i�e�j
          ,ir_m_tab(i).base_code                            -- ���_�R�[�h
          ,ir_m_tab(i).hub_name                             -- ���_����
          ,ir_m_tab(i).group_number                         -- �c�ƃO���[�v�ԍ�
          ,ir_m_tab(i).group_name                           -- �c�ƃO���[�v��
          ,ir_m_tab(i).employee_number                      -- �c�ƈ��R�[�h
          ,ir_m_tab(i).employee_name                        -- �c�ƈ���
          ,ir_m_tab(i).business_high_type                   -- �Ƒԁi�啪�ށj
          ,ir_m_tab(i).business_high_name                   -- �Ƒԁi�啪�ށj��
          ,ir_m_tab(i).gvm_type                             -- ��ʁ^���̋@�^�l�b
          ,ir_m_tab(i).account_number                       -- �ڋq�R�[�h
          ,ir_m_tab(i).customer_name                        -- �ڋq��
          ,ir_m_tab(i).route_no                             -- ���[�gNo
          ,ir_m_tab(i).last_year_rslt_sales_amt             -- �O�N����
          ,ir_m_tab(i).last_mon_rslt_sales_amt              -- �挎����
          ,ir_m_tab(i).new_customer_num                     -- �V�K�ڋq����
          ,ir_m_tab(i).new_vendor_num                       -- �V�K�u�c����
          ,ir_m_tab(i).new_customer_amt                     -- �V�K�ڋq�������
          ,ir_m_tab(i).new_vendor_amt                       -- �V�K�u�c�������
          ,ir_m_tab(i).plan_sales_amt                       -- ����\�Z
          ,ir_m_tab(i).l_get_one_day_tab(1).plan_vs_amt             -- �P���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(1).rslt_vs_amt             -- �P���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(1).rslt_other_sales_amt    -- �P���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(1).effective_num           -- �P���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(1).visit_sign              -- �P���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(2).plan_vs_amt             -- �Q���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(2).rslt_vs_amt             -- �Q���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(2).rslt_other_sales_amt    -- �Q���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(2).effective_num           -- �Q���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(2).visit_sign              -- �Q���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(3).plan_vs_amt             -- �R���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(3).rslt_vs_amt             -- �R���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(3).rslt_other_sales_amt    -- �R���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(3).effective_num           -- �R���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(3).visit_sign              -- �R���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(4).plan_vs_amt             -- �S���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(4).rslt_vs_amt             -- �S���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(4).rslt_other_sales_amt    -- �S���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(4).effective_num           -- �S���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(4).visit_sign              -- �S���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(5).plan_vs_amt             -- �T���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(5).rslt_vs_amt             -- �T���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(5).rslt_other_sales_amt    -- �T���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(5).effective_num           -- �T���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(5).visit_sign              -- �T���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(6).plan_vs_amt             -- �U���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(6).rslt_vs_amt             -- �U���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(6).rslt_other_sales_amt    -- �U���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(6).effective_num           -- �U���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(6).visit_sign              -- �U���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(7).plan_vs_amt             -- �V���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(7).rslt_vs_amt             -- �V���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(7).rslt_other_sales_amt    -- �V���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(7).effective_num           -- �V���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(7).visit_sign              -- �V���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(8).plan_vs_amt             -- �W���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(8).rslt_vs_amt             -- �W���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(8).rslt_other_sales_amt    -- �W���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(8).effective_num           -- �W���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(8).visit_sign              -- �W���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(9).plan_vs_amt             -- �X���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(9).rslt_vs_amt             -- �X���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(9).rslt_other_sales_amt    -- �X���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(9).effective_num           -- �X���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(9).visit_sign              -- �X���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(10).plan_vs_amt            -- �P�O���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(10).rslt_vs_amt            -- �P�O���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(10).rslt_other_sales_amt   -- �P�O���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(10).effective_num          -- �P�O���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(10).visit_sign             -- �P�O���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(11).plan_vs_amt            -- �P�P���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(11).rslt_vs_amt            -- �P�P���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(11).rslt_other_sales_amt   -- �P�P���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(11).effective_num          -- �P�P���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(11).visit_sign             -- �P�P���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(12).plan_vs_amt            -- �P�Q���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(12).rslt_vs_amt            -- �P�Q���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(12).rslt_other_sales_amt   -- �P�Q���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(12).effective_num          -- �P�Q���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(12).visit_sign             -- �P�Q���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(13).plan_vs_amt            -- �P�R���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(13).rslt_vs_amt            -- �P�R���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(13).rslt_other_sales_amt   -- �P�R���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(13).effective_num          -- �P�R���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(13).visit_sign             -- �P�R���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(14).plan_vs_amt            -- �P�S���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(14).rslt_vs_amt            -- �P�S���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(14).rslt_other_sales_amt   -- �P�S���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(14).effective_num          -- �P�S���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(14).visit_sign             -- �P�S���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(15).plan_vs_amt            -- �P�T���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(15).rslt_vs_amt            -- �P�T���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(15).rslt_other_sales_amt   -- �P�T���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(15).effective_num          -- �P�T���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(15).visit_sign             -- �P�T���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(16).plan_vs_amt            -- �P�U���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(16).rslt_vs_amt            -- �P�U���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(16).rslt_other_sales_amt   -- �P�U���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(16).effective_num          -- �P�U���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(16).visit_sign             -- �P�U���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(17).plan_vs_amt            -- �P�V���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(17).rslt_vs_amt            -- �P�V���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(17).rslt_other_sales_amt   -- �P�V���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(17).effective_num          -- �P�V���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(17).visit_sign             -- �P�V���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(18).plan_vs_amt            -- �P�W���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(18).rslt_vs_amt            -- �P�W���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(18).rslt_other_sales_amt   -- �P�W���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(18).effective_num          -- �P�W���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(18).visit_sign             -- �P�W���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(19).plan_vs_amt            -- �P�X���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(19).rslt_vs_amt            -- �P�X���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(19).rslt_other_sales_amt   -- �P�X���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(19).effective_num          -- �P�X���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(19).visit_sign             -- �P�X���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(20).plan_vs_amt            -- �Q�O���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(20).rslt_vs_amt            -- �Q�O���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(20).rslt_other_sales_amt   -- �Q�O���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(20).effective_num          -- �Q�O���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(20).visit_sign             -- �Q�O���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(21).plan_vs_amt            -- �Q�P���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(21).rslt_vs_amt            -- �Q�P���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(21).rslt_other_sales_amt   -- �Q�P���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(21).effective_num          -- �Q�P���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(21).visit_sign             -- �Q�P���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(22).plan_vs_amt            -- �Q�Q���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(22).rslt_vs_amt            -- �Q�Q���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(22).rslt_other_sales_amt   -- �Q�Q���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(22).effective_num          -- �Q�Q���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(22).visit_sign             -- �Q�Q���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(23).plan_vs_amt            -- �Q�R���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(23).rslt_vs_amt            -- �Q�R���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(23).rslt_other_sales_amt   -- �Q�R���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(23).effective_num          -- �Q�R���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(23).visit_sign             -- �Q�R���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(24).plan_vs_amt            -- �Q�S���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(24).rslt_vs_amt            -- �Q�S���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(24).rslt_other_sales_amt   -- �Q�S���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(24).effective_num          -- �Q�S���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(24).visit_sign             -- �Q�S���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(25).plan_vs_amt            -- �Q�T���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(25).rslt_vs_amt            -- �Q�T���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(25).rslt_other_sales_amt   -- �Q�T���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(25).effective_num          -- �Q�T���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(25).visit_sign             -- �Q�T���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(26).plan_vs_amt            -- �Q�U���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(26).rslt_vs_amt            -- �Q�U���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(26).rslt_other_sales_amt   -- �Q�U���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(26).effective_num          -- �Q�U���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(26).visit_sign             -- �Q�U���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(27).plan_vs_amt            -- �Q�V���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(27).rslt_vs_amt            -- �Q�V���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(27).rslt_other_sales_amt   -- �Q�V���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(27).effective_num          -- �Q�V���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(27).visit_sign             -- �Q�V���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(28).plan_vs_amt            -- �Q�W���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(28).rslt_vs_amt            -- �Q�W���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(28).rslt_other_sales_amt   -- �Q�W���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(28).effective_num          -- �Q�W���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(28).visit_sign             -- �Q�W���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(29).plan_vs_amt            -- �Q�X���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(29).rslt_vs_amt            -- �Q�X���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(29).rslt_other_sales_amt   -- �Q�X���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(29).effective_num          -- �Q�X���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(29).visit_sign             -- �Q�X���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(30).plan_vs_amt            -- �R�O���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(30).rslt_vs_amt            -- �R�O���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(30).rslt_other_sales_amt   -- �R�O���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(30).effective_num          -- �R�O���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(30).visit_sign             -- �R�O���|�K��L��
          ,ir_m_tab(i).l_get_one_day_tab(31).plan_vs_amt            -- �R�P���|����^�K��v��
          ,ir_m_tab(i).l_get_one_day_tab(31).rslt_vs_amt            -- �R�P���|����^�K�����
          ,ir_m_tab(i).l_get_one_day_tab(31).rslt_other_sales_amt   -- �R�P���|������сi�����_�[�i���j
          ,ir_m_tab(i).l_get_one_day_tab(31).effective_num          -- �R�P���|�L������
          ,ir_m_tab(i).l_get_one_day_tab(31).visit_sign             -- �R�P���|�K��L��
          ,ir_m_tab(i).vis_a_num                                    -- �K��`����
          ,ir_m_tab(i).vis_b_num                                    -- �K��a����
          ,ir_m_tab(i).vis_c_num                                    -- �K��b����
          ,ir_m_tab(i).vis_d_num                                    -- �K��c����
          ,ir_m_tab(i).vis_e_num                                    -- �K��d����
          ,ir_m_tab(i).vis_f_num                                    -- �K��e����
          ,ir_m_tab(i).vis_g_num                                    -- �K��f����
          ,ir_m_tab(i).vis_h_num                                    -- �K��g����
          ,ir_m_tab(i).vis_i_num                                    -- �K���@����
          ,ir_m_tab(i).vis_j_num                                    -- �K��i����
          ,ir_m_tab(i).vis_k_num                                    -- �K��j����
          ,ir_m_tab(i).vis_l_num                                    -- �K��k����
          ,ir_m_tab(i).vis_m_num                                    -- �K��l����
          ,ir_m_tab(i).vis_n_num                                    -- �K��m����
          ,ir_m_tab(i).vis_o_num                                    -- �K��n����
          ,ir_m_tab(i).vis_p_num                                    -- �K��o����
          ,ir_m_tab(i).vis_q_num                                    -- �K��p����
          ,ir_m_tab(i).vis_r_num                                    -- �K��q����
          ,ir_m_tab(i).vis_s_num                                    -- �K��r����
          ,ir_m_tab(i).vis_t_num                                    -- �K��s����
          ,ir_m_tab(i).vis_u_num                                    -- �K��t����
          ,ir_m_tab(i).vis_v_num                                    -- �K��u����
          ,ir_m_tab(i).vis_w_num                                    -- �K��v����
          ,ir_m_tab(i).vis_x_num                                    -- �K��w����
          ,ir_m_tab(i).vis_y_num                                    -- �K��x����
          ,ir_m_tab(i).vis_z_num                                    -- �K��y����
          ,cn_created_by                                            -- �쐬��
          ,cd_creation_date                                         -- �쐬��
          ,cn_last_updated_by                                       -- �ŏI�X�V��
          ,cd_last_update_date                                      -- �ŏI�X�V��
          ,cn_last_update_login                                     -- �ŏI�X�V���O�C��
          ,cn_request_id                                            -- �v��ID
          ,cn_program_application_id                                -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
          ,cn_program_id                                            -- �R���J�����g�E�v���O����ID
          ,cd_program_update_date                                   -- �v���O�����X�V��
          );
--
DO_ERROR('A-X-4-1');
--
        gn_normal_cnt := gn_normal_cnt + 1;
      EXCEPTION
        WHEN OTHERS THEN
        -- DEBUG���b�Z�[�W
        -- ���[�^�C�g��
        fnd_file.put_line(
           which  => FND_FILE.LOG,
           buff   => '���ו��z��o�͂Ɏ��s���܂����B :' || TO_CHAR(ln_line_num) || SQLERRM ||
                    ''                         -- ��s�̑}��
        );
        RAISE global_api_others_expt;
      END;
    END LOOP;
    -- ���[�{�̕�
    FOR i IN 1..cn_idx_max LOOP
      IF( i < cn_idx_sales_sum )  THEN               -- ����グ���v��
        ln_line_kind              := cn_line_kind3;              -- ���[�o�͈ʒu
        ln_line_num               := i;                          -- �s�ԍ�
      ELSIF( i = cn_idx_sales_sum ) THEN            -- ����グ���v��
        ln_line_kind              := cn_line_kind4;              -- ���[�o�͈ʒu
        ln_line_num               := 1;                          -- �s�ԍ�
        lv_up_base_code           := ir_hon_tab(i).up_base_code;   
        lv_up_hub_name            := ir_hon_tab(i).up_hub_name;    
        lv_base_code              := ir_hon_tab(i).base_code;      
        lv_hub_name               := ir_hon_tab(i).hub_name;       
        lv_group_number           := ir_hon_tab(i).group_number;   
        lv_group_name             := ir_hon_tab(i).group_name;  
        lv_employee_number        := ir_hon_tab(i).employee_number;
        lv_employee_name          := ir_hon_tab(i).employee_name;  
      ELSIF( i BETWEEN cn_idx_visit_ippn AND cn_idx_visit_mc )  THEN    -- �K�⒆�v��
        ln_line_kind              := cn_line_kind5;              -- ���[�o�͈ʒu
        ln_line_num               := i -3;                       -- �s�ԍ�
      ELSIF( i = cn_idx_visit_sum ) THEN            -- �K�⍇�v��
        ln_line_kind              := cn_line_kind6;              -- ���[�o�͈ʒu
        ln_line_num               := 1;                          -- �s�ԍ�
      ELSIF( i = cn_idx_visit_dsc ) THEN            -- �K����e���v��
        ln_line_kind              := cn_line_kind7;              -- ���[�o�͈ʒu
        ln_line_num               := 1;                          -- �s�ԍ�    
      END IF;
      INSERT INTO xxcso_rep_visit_sale_plan(
         report_output_no                                 -- ���[�o�̓Z�b�g�ԍ�
        ,line_kind                                        -- ���[�o�͈ʒu
        ,line_num                                         -- �s�ԍ�
        ,report_id                                        -- ���[�h�c
        ,report_name                                      -- ���[�^�C�g��
        ,output_date                                      -- �o�͓���
        ,year_month                                       -- ��N��
        ,operation_days                                   -- �ғ�����
        ,operation_all_days                               -- �ғ��\����
        ,up_base_code                                     -- ���_�R�[�h�i�e�j
        ,up_hub_name                                      -- ���_���́i�e�j
        ,base_code                                        -- ���_�R�[�h
        ,hub_name                                         -- ���_����
        ,group_number                                     -- �c�ƃO���[�v�ԍ�
        ,group_name                                       -- �c�ƃO���[�v��
        ,employee_number                                  -- �c�ƈ��R�[�h
        ,employee_name                                    -- �c�ƈ���
        ,business_high_type                               -- �Ƒԁi�啪�ށj
        ,business_high_name                               -- �Ƒԁi�啪�ށj��
        ,gvm_type                                         -- ��ʁ^���̋@�^�l�b
        ,account_number                                   -- �ڋq�R�[�h
        ,customer_name                                    -- �ڋq��
        ,route_no                                         -- ���[�gNo
        ,last_year_rslt_sales_amt                         -- �O�N����
        ,last_mon_rslt_sales_amt                          -- �挎����
        ,new_customer_num                                 -- �V�K�ڋq����
        ,new_vendor_num                                   -- �V�K�u�c����
        ,new_customer_amt                                 -- �V�K�ڋq�������
        ,new_vendor_amt                                   -- �V�K�u�c�������
        ,plan_sales_amt                                   -- ����\�Z
        ,plan_vs_amt_1                                    -- �P���|����^�K��v��
        ,rslt_vs_amt_1                                    -- �P���|����^�K�����
        ,rslt_other_sales_amt_1                           -- �P���|������сi�����_�[�i���j
        ,effective_num_1                                  -- �P���|�L������
        ,visit_sign_1                                     -- �P���|�K��L��
        ,plan_vs_amt_2                                    -- �Q���|����^�K��v��
        ,rslt_vs_amt_2                                    -- �Q���|����^�K�����
        ,rslt_other_sales_amt_2                           -- �Q���|������сi�����_�[�i���j
        ,effective_num_2                                  -- �Q���|�L������
        ,visit_sign_2                                     -- �Q���|�K��L��
        ,plan_vs_amt_3                                    -- �R���|����^�K��v��
        ,rslt_vs_amt_3                                    -- �R���|����^�K�����
        ,rslt_other_sales_amt_3                           -- �R���|������сi�����_�[�i���j
        ,effective_num_3                                  -- �R���|�L������
        ,visit_sign_3                                     -- �R���|�K��L��
        ,plan_vs_amt_4                                    -- �S���|����^�K��v��
        ,rslt_vs_amt_4                                    -- �S���|����^�K�����
        ,rslt_other_sales_amt_4                           -- �S���|������сi�����_�[�i���j
        ,effective_num_4                                  -- �S���|�L������
        ,visit_sign_4                                     -- �S���|�K��L��
        ,plan_vs_amt_5                                    -- �T���|����^�K��v��
        ,rslt_vs_amt_5                                    -- �T���|����^�K�����
        ,rslt_other_sales_amt_5                           -- �T���|������сi�����_�[�i���j
        ,effective_num_5                                  -- �T���|�L������
        ,visit_sign_5                                     -- �T���|�K��L��
        ,plan_vs_amt_6                                    -- �U���|����^�K��v��
        ,rslt_vs_amt_6                                    -- �U���|����^�K�����
        ,rslt_other_sales_amt_6                           -- �U���|������сi�����_�[�i���j
        ,effective_num_6                                  -- �U���|�L������
        ,visit_sign_6                                     -- �U���|�K��L��
        ,plan_vs_amt_7                                    -- �V���|����^�K��v��
        ,rslt_vs_amt_7                                    -- �V���|����^�K�����
        ,rslt_other_sales_amt_7                           -- �V���|������сi�����_�[�i���j
        ,effective_num_7                                  -- �V���|�L������
        ,visit_sign_7                                     -- �V���|�K��L��
        ,plan_vs_amt_8                                    -- �W���|����^�K��v��
        ,rslt_vs_amt_8                                    -- �W���|����^�K�����
        ,rslt_other_sales_amt_8                           -- �W���|������сi�����_�[�i���j
        ,effective_num_8                                  -- �W���|�L������
        ,visit_sign_8                                     -- �W���|�K��L��
        ,plan_vs_amt_9                                    -- �X���|����^�K��v��
        ,rslt_vs_amt_9                                    -- �X���|����^�K�����
        ,rslt_other_sales_amt_9                           -- �X���|������сi�����_�[�i���j
        ,effective_num_9                                  -- �X���|�L������
        ,visit_sign_9                                     -- �X���|�K��L��
        ,plan_vs_amt_10                                   -- �P�O���|����^�K��v��
        ,rslt_vs_amt_10                                   -- �P�O���|����^�K�����
        ,rslt_other_sales_amt_10                          -- �P�O���|������сi�����_�[�i���j
        ,effective_num_10                                 -- �P�O���|�L������
        ,visit_sign_10                                    -- �P�O���|�K��L��
        ,plan_vs_amt_11                                   -- �P�P���|����^�K��v��
        ,rslt_vs_amt_11                                   -- �P�P���|����^�K�����
        ,rslt_other_sales_amt_11                          -- �P�P���|������сi�����_�[�i���j
        ,effective_num_11                                 -- �P�P���|�L������
        ,visit_sign_11                                    -- �P�P���|�K��L��
        ,plan_vs_amt_12                                   -- �P�Q���|����^�K��v��
        ,rslt_vs_amt_12                                   -- �P�Q���|����^�K�����
        ,rslt_other_sales_amt_12                          -- �P�Q���|������сi�����_�[�i���j
        ,effective_num_12                                 -- �P�Q���|�L������
        ,visit_sign_12                                    -- �P�Q���|�K��L��
        ,plan_vs_amt_13                                   -- �P�R���|����^�K��v��
        ,rslt_vs_amt_13                                   -- �P�R���|����^�K�����
        ,rslt_other_sales_amt_13                          -- �P�R���|������сi�����_�[�i���j
        ,effective_num_13                                 -- �P�R���|�L������
        ,visit_sign_13                                    -- �P�R���|�K��L��
        ,plan_vs_amt_14                                   -- �P�S���|����^�K��v��
        ,rslt_vs_amt_14                                   -- �P�S���|����^�K�����
        ,rslt_other_sales_amt_14                          -- �P�S���|������сi�����_�[�i���j
        ,effective_num_14                                 -- �P�S���|�L������
        ,visit_sign_14                                    -- �P�S���|�K��L��
        ,plan_vs_amt_15                                   -- �P�T���|����^�K��v��
        ,rslt_vs_amt_15                                   -- �P�T���|����^�K�����
        ,rslt_other_sales_amt_15                          -- �P�T���|������сi�����_�[�i���j
        ,effective_num_15                                 -- �P�T���|�L������
        ,visit_sign_15                                    -- �P�T���|�K��L��
        ,plan_vs_amt_16                                   -- �P�U���|����^�K��v��
        ,rslt_vs_amt_16                                   -- �P�U���|����^�K�����
        ,rslt_other_sales_amt_16                          -- �P�U���|������сi�����_�[�i���j
        ,effective_num_16                                 -- �P�U���|�L������
        ,visit_sign_16                                    -- �P�U���|�K��L��
        ,plan_vs_amt_17                                   -- �P�V���|����^�K��v��
        ,rslt_vs_amt_17                                   -- �P�V���|����^�K�����
        ,rslt_other_sales_amt_17                          -- �P�V���|������сi�����_�[�i���j
        ,effective_num_17                                 -- �P�V���|�L������
        ,visit_sign_17                                    -- �P�V���|�K��L��
        ,plan_vs_amt_18                                   -- �P�W���|����^�K��v��
        ,rslt_vs_amt_18                                   -- �P�W���|����^�K�����
        ,rslt_other_sales_amt_18                          -- �P�W���|������сi�����_�[�i���j
        ,effective_num_18                                 -- �P�W���|�L������
        ,visit_sign_18                                    -- �P�W���|�K��L��
        ,plan_vs_amt_19                                   -- �P�X���|����^�K��v��
        ,rslt_vs_amt_19                                   -- �P�X���|����^�K�����
        ,rslt_other_sales_amt_19                          -- �P�X���|������сi�����_�[�i���j
        ,effective_num_19                                 -- �P�X���|�L������
        ,visit_sign_19                                    -- �P�X���|�K��L��
        ,plan_vs_amt_20                                   -- �Q�O���|����^�K��v��
        ,rslt_vs_amt_20                                   -- �Q�O���|����^�K�����
        ,rslt_other_sales_amt_20                          -- �Q�O���|������сi�����_�[�i���j
        ,effective_num_20                                 -- �Q�O���|�L������
        ,visit_sign_20                                    -- �Q�O���|�K��L��
        ,plan_vs_amt_21                                   -- �Q�P���|����^�K��v��
        ,rslt_vs_amt_21                                   -- �Q�P���|����^�K�����
        ,rslt_other_sales_amt_21                          -- �Q�P���|������сi�����_�[�i���j
        ,effective_num_21                                 -- �Q�P���|�L������
        ,visit_sign_21                                    -- �Q�P���|�K��L��
        ,plan_vs_amt_22                                   -- �Q�Q���|����^�K��v��
        ,rslt_vs_amt_22                                   -- �Q�Q���|����^�K�����
        ,rslt_other_sales_amt_22                          -- �Q�Q���|������сi�����_�[�i���j
        ,effective_num_22                                 -- �Q�Q���|�L������
        ,visit_sign_22                                    -- �Q�Q���|�K��L��
        ,plan_vs_amt_23                                   -- �Q�R���|����^�K��v��
        ,rslt_vs_amt_23                                   -- �Q�R���|����^�K�����
        ,rslt_other_sales_amt_23                          -- �Q�R���|������сi�����_�[�i���j
        ,effective_num_23                                 -- �Q�R���|�L������
        ,visit_sign_23                                    -- �Q�R���|�K��L��
        ,plan_vs_amt_24                                   -- �Q�S���|����^�K��v��
        ,rslt_vs_amt_24                                   -- �Q�S���|����^�K�����
        ,rslt_other_sales_amt_24                          -- �Q�S���|������сi�����_�[�i���j
        ,effective_num_24                                 -- �Q�S���|�L������
        ,visit_sign_24                                    -- �Q�S���|�K��L��
        ,plan_vs_amt_25                                   -- �Q�T���|����^�K��v��
        ,rslt_vs_amt_25                                   -- �Q�T���|����^�K�����
        ,rslt_other_sales_amt_25                          -- �Q�T���|������сi�����_�[�i���j
        ,effective_num_25                                 -- �Q�T���|�L������
        ,visit_sign_25                                    -- �Q�T���|�K��L��
        ,plan_vs_amt_26                                   -- �Q�U���|����^�K��v��
        ,rslt_vs_amt_26                                   -- �Q�U���|����^�K�����
        ,rslt_other_sales_amt_26                          -- �Q�U���|������сi�����_�[�i���j
        ,effective_num_26                                 -- �Q�U���|�L������
        ,visit_sign_26                                    -- �Q�U���|�K��L��
        ,plan_vs_amt_27                                   -- �Q�V���|����^�K��v��
        ,rslt_vs_amt_27                                   -- �Q�V���|����^�K�����
        ,rslt_other_sales_amt_27                          -- �Q�V���|������сi�����_�[�i���j
        ,effective_num_27                                 -- �Q�V���|�L������
        ,visit_sign_27                                    -- �Q�V���|�K��L��
        ,plan_vs_amt_28                                   -- �Q�W���|����^�K��v��
        ,rslt_vs_amt_28                                   -- �Q�W���|����^�K�����
        ,rslt_other_sales_amt_28                          -- �Q�W���|������сi�����_�[�i���j
        ,effective_num_28                                 -- �Q�W���|�L������
        ,visit_sign_28                                    -- �Q�W���|�K��L��
        ,plan_vs_amt_29                                   -- �Q�X���|����^�K��v��
        ,rslt_vs_amt_29                                   -- �Q�X���|����^�K�����
        ,rslt_other_sales_amt_29                          -- �Q�X���|������сi�����_�[�i���j
        ,effective_num_29                                 -- �Q�X���|�L������
        ,visit_sign_29                                    -- �Q�X���|�K��L��
        ,plan_vs_amt_30                                   -- �R�O���|����^�K��v��
        ,rslt_vs_amt_30                                   -- �R�O���|����^�K�����
        ,rslt_other_sales_amt_30                          -- �R�O���|������сi�����_�[�i���j
        ,effective_num_30                                 -- �R�O���|�L������
        ,visit_sign_30                                    -- �R�O���|�K��L��
        ,plan_vs_amt_31                                   -- �R�P���|����^�K��v��
        ,rslt_vs_amt_31                                   -- �R�P���|����^�K�����
        ,rslt_other_sales_amt_31                          -- �R�P���|������сi�����_�[�i���j
        ,effective_num_31                                 -- �R�P���|�L������
        ,visit_sign_31                                    -- �R�P���|�K��L��
        ,vis_a_num                                        -- �K��`����
        ,vis_b_num                                        -- �K��a����
        ,vis_c_num                                        -- �K��b����
        ,vis_d_num                                        -- �K��c����
        ,vis_e_num                                        -- �K��d����
        ,vis_f_num                                        -- �K��e����
        ,vis_g_num                                        -- �K��f����
        ,vis_h_num                                        -- �K��g����
        ,vis_i_num                                        -- �K���@����
        ,vis_j_num                                        -- �K��i����
        ,vis_k_num                                        -- �K��j����
        ,vis_l_num                                        -- �K��k����
        ,vis_m_num                                        -- �K��l����
        ,vis_n_num                                        -- �K��m����
        ,vis_o_num                                        -- �K��n����
        ,vis_p_num                                        -- �K��o����
        ,vis_q_num                                        -- �K��p����
        ,vis_r_num                                        -- �K��q����
        ,vis_s_num                                        -- �K��r����
        ,vis_t_num                                        -- �K��s����
        ,vis_u_num                                        -- �K��t����
        ,vis_v_num                                        -- �K��u����
        ,vis_w_num                                        -- �K��v����
        ,vis_x_num                                        -- �K��w����
        ,vis_y_num                                        -- �K��x����
        ,vis_z_num                                        -- �K��y����
        ,created_by                                       -- �쐬��
        ,creation_date                                    -- �쐬��
        ,last_updated_by                                  -- �ŏI�X�V��
        ,last_update_date                                 -- �ŏI�X�V��
        ,last_update_login                                -- �ŏI�X�V���O�C��
        ,request_id                                       -- �v��ID
        ,program_application_id                           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
        ,program_id                                       -- �R���J�����g�E�v���O����ID
        ,program_update_date                               -- �v���O�����X�V��
      )
      VALUES(
        in_report_output_no                              -- ���[�o�̓Z�b�g�ԍ�
       ,ln_line_kind                                     -- ���[�o�͈ʒu
       ,ln_line_num                                      -- �s�ԍ�
       ,NULL                                             -- ���[�h�c
       ,NULL                                             -- ���[�^�C�g��
       ,NULL                                             -- �o�͓���
       ,NULL                                             -- ��N��
       ,NULL                                             -- �ғ�����
       ,NULL                                             -- �ғ��\����
       ,ir_hon_tab(i).up_base_code                       -- ���_�R�[�h�i�e�j
       ,ir_hon_tab(i).up_hub_name                        -- ���_���́i�e�j
       ,ir_hon_tab(i).base_code                          -- ���_�R�[�h
       ,ir_hon_tab(i).hub_name                           -- ���_����
       ,ir_hon_tab(i).group_number                       -- �c�ƃO���[�v�ԍ�
       ,ir_hon_tab(i).group_name                         -- �c�ƃO���[�v��
       ,ir_hon_tab(i).employee_number                    -- �c�ƈ��R�[�h
       ,ir_hon_tab(i).employee_name                      -- �c�ƈ���
       ,ir_hon_tab(i).business_high_type                 -- �Ƒԁi�啪�ށj
       ,ir_hon_tab(i).business_high_name                 -- �Ƒԁi�啪�ށj��
       ,ir_hon_tab(i).gvm_type                           -- ��ʁ^���̋@�^�l�b
       ,ir_hon_tab(i).account_number                     -- �ڋq�R�[�h
       ,ir_hon_tab(i).customer_name                      -- �ڋq��
       ,ir_hon_tab(i).route_no                           -- ���[�gNo
       ,ir_hon_tab(i).last_year_rslt_sales_amt           -- �O�N����
       ,ir_hon_tab(i).last_mon_rslt_sales_amt            -- �挎����
       ,ir_hon_tab(i).new_customer_num                   -- �V�K�ڋq����
       ,ir_hon_tab(i).new_vendor_num                     -- �V�K�u�c����
       ,ir_hon_tab(i).new_customer_amt                   -- �V�K�ڋq�������
       ,ir_hon_tab(i).new_vendor_amt                     -- �V�K�u�c�������
       ,ir_hon_tab(i).plan_sales_amt                     -- ����\�Z
       ,ir_hon_tab(i).l_get_one_day_tab(1).plan_vs_amt             -- �P���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(1).rslt_vs_amt             -- �P���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(1).rslt_other_sales_amt    -- �P���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(1).effective_num           -- �P���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(1).visit_sign              -- �P���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(2).plan_vs_amt             -- �Q���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(2).rslt_vs_amt             -- �Q���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(2).rslt_other_sales_amt    -- �Q���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(2).effective_num           -- �Q���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(2).visit_sign              -- �Q���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(3).plan_vs_amt             -- �R���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(3).rslt_vs_amt             -- �R���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(3).rslt_other_sales_amt    -- �R���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(3).effective_num           -- �R���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(3).visit_sign              -- �R���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(4).plan_vs_amt             -- �S���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(4).rslt_vs_amt             -- �S���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(4).rslt_other_sales_amt    -- �S���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(4).effective_num           -- �S���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(4).visit_sign              -- �S���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(5).plan_vs_amt             -- �T���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(5).rslt_vs_amt             -- �T���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(5).rslt_other_sales_amt    -- �T���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(5).effective_num           -- �T���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(5).visit_sign              -- �T���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(6).plan_vs_amt             -- �U���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(6).rslt_vs_amt             -- �U���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(6).rslt_other_sales_amt    -- �U���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(6).effective_num           -- �U���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(6).visit_sign              -- �U���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(7).plan_vs_amt             -- �V���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(7).rslt_vs_amt             -- �V���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(7).rslt_other_sales_amt    -- �V���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(7).effective_num           -- �V���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(7).visit_sign              -- �V���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(8).plan_vs_amt             -- �W���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(8).rslt_vs_amt             -- �W���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(8).rslt_other_sales_amt    -- �W���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(8).effective_num           -- �W���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(8).visit_sign              -- �W���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(9).plan_vs_amt             -- �X���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(9).rslt_vs_amt             -- �X���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(9).rslt_other_sales_amt    -- �X���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(9).effective_num           -- �X���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(9).visit_sign              -- �X���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(10).plan_vs_amt            -- �P�O���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(10).rslt_vs_amt            -- �P�O���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(10).rslt_other_sales_amt   -- �P�O���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(10).effective_num          -- �P�O���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(10).visit_sign             -- �P�O���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(11).plan_vs_amt            -- �P�P���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(11).rslt_vs_amt            -- �P�P���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(11).rslt_other_sales_amt   -- �P�P���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(11).effective_num          -- �P�P���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(11).visit_sign             -- �P�P���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(12).plan_vs_amt            -- �P�Q���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(12).rslt_vs_amt            -- �P�Q���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(12).rslt_other_sales_amt   -- �P�Q���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(12).effective_num          -- �P�Q���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(12).visit_sign             -- �P�Q���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(13).plan_vs_amt            -- �P�R���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(13).rslt_vs_amt            -- �P�R���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(13).rslt_other_sales_amt   -- �P�R���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(13).effective_num          -- �P�R���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(13).visit_sign             -- �P�R���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(14).plan_vs_amt            -- �P�S���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(14).rslt_vs_amt            -- �P�S���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(14).rslt_other_sales_amt   -- �P�S���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(14).effective_num          -- �P�S���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(14).visit_sign             -- �P�S���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(15).plan_vs_amt            -- �P�T���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(15).rslt_vs_amt            -- �P�T���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(15).rslt_other_sales_amt   -- �P�T���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(15).effective_num          -- �P�T���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(15).visit_sign             -- �P�T���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(16).plan_vs_amt            -- �P�U���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(16).rslt_vs_amt            -- �P�U���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(16).rslt_other_sales_amt   -- �P�U���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(16).effective_num          -- �P�U���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(16).visit_sign             -- �P�U���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(17).plan_vs_amt            -- �P�V���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(17).rslt_vs_amt            -- �P�V���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(17).rslt_other_sales_amt   -- �P�V���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(17).effective_num          -- �P�V���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(17).visit_sign             -- �P�V���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(18).plan_vs_amt            -- �P�W���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(18).rslt_vs_amt            -- �P�W���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(18).rslt_other_sales_amt   -- �P�W���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(18).effective_num          -- �P�W���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(18).visit_sign             -- �P�W���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(19).plan_vs_amt            -- �P�X���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(19).rslt_vs_amt            -- �P�X���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(19).rslt_other_sales_amt   -- �P�X���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(19).effective_num          -- �P�X���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(19).visit_sign             -- �P�X���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(20).plan_vs_amt            -- �Q�O���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(20).rslt_vs_amt            -- �Q�O���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(20).rslt_other_sales_amt   -- �Q�O���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(20).effective_num          -- �Q�O���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(20).visit_sign             -- �Q�O���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(21).plan_vs_amt            -- �Q�P���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(21).rslt_vs_amt            -- �Q�P���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(21).rslt_other_sales_amt   -- �Q�P���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(21).effective_num          -- �Q�P���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(21).visit_sign             -- �Q�P���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(22).plan_vs_amt            -- �Q�Q���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(22).rslt_vs_amt            -- �Q�Q���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(22).rslt_other_sales_amt   -- �Q�Q���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(22).effective_num          -- �Q�Q���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(22).visit_sign             -- �Q�Q���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(23).plan_vs_amt            -- �Q�R���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(23).rslt_vs_amt            -- �Q�R���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(23).rslt_other_sales_amt   -- �Q�R���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(23).effective_num          -- �Q�R���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(23).visit_sign             -- �Q�R���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(24).plan_vs_amt            -- �Q�S���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(24).rslt_vs_amt            -- �Q�S���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(24).rslt_other_sales_amt   -- �Q�S���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(24).effective_num          -- �Q�S���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(24).visit_sign             -- �Q�S���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(25).plan_vs_amt            -- �Q�T���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(25).rslt_vs_amt            -- �Q�T���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(25).rslt_other_sales_amt   -- �Q�T���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(25).effective_num          -- �Q�T���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(25).visit_sign             -- �Q�T���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(26).plan_vs_amt            -- �Q�U���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(26).rslt_vs_amt            -- �Q�U���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(26).rslt_other_sales_amt   -- �Q�U���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(26).effective_num          -- �Q�U���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(26).visit_sign             -- �Q�U���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(27).plan_vs_amt            -- �Q�V���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(27).rslt_vs_amt            -- �Q�V���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(27).rslt_other_sales_amt   -- �Q�V���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(27).effective_num          -- �Q�V���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(27).visit_sign             -- �Q�V���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(28).plan_vs_amt            -- �Q�W���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(28).rslt_vs_amt            -- �Q�W���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(28).rslt_other_sales_amt   -- �Q�W���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(28).effective_num          -- �Q�W���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(28).visit_sign             -- �Q�W���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(29).plan_vs_amt            -- �Q�X���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(29).rslt_vs_amt            -- �Q�X���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(29).rslt_other_sales_amt   -- �Q�X���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(29).effective_num          -- �Q�X���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(29).visit_sign             -- �Q�X���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(30).plan_vs_amt            -- �R�O���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(30).rslt_vs_amt            -- �R�O���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(30).rslt_other_sales_amt   -- �R�O���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(30).effective_num          -- �R�O���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(30).visit_sign             -- �R�O���|�K��L��
       ,ir_hon_tab(i).l_get_one_day_tab(31).plan_vs_amt            -- �R�P���|����^�K��v��
       ,ir_hon_tab(i).l_get_one_day_tab(31).rslt_vs_amt            -- �R�P���|����^�K�����
       ,ir_hon_tab(i).l_get_one_day_tab(31).rslt_other_sales_amt   -- �R�P���|������сi�����_�[�i���j
       ,ir_hon_tab(i).l_get_one_day_tab(31).effective_num          -- �R�P���|�L������
       ,ir_hon_tab(i).l_get_one_day_tab(31).visit_sign             -- �R�P���|�K��L��
       ,ir_hon_tab(i).vis_a_num                                    -- �K��`����
       ,ir_hon_tab(i).vis_b_num                                    -- �K��a����
       ,ir_hon_tab(i).vis_c_num                                    -- �K��b����
       ,ir_hon_tab(i).vis_d_num                                    -- �K��c����
       ,ir_hon_tab(i).vis_e_num                                    -- �K��d����
       ,ir_hon_tab(i).vis_f_num                                    -- �K��e����
       ,ir_hon_tab(i).vis_g_num                                    -- �K��f����
       ,ir_hon_tab(i).vis_h_num                                    -- �K��g����
       ,ir_hon_tab(i).vis_i_num                                    -- �K���@����
       ,ir_hon_tab(i).vis_j_num                                    -- �K��i����
       ,ir_hon_tab(i).vis_k_num                                    -- �K��j����
       ,ir_hon_tab(i).vis_l_num                                    -- �K��k����
       ,ir_hon_tab(i).vis_m_num                                    -- �K��l����
       ,ir_hon_tab(i).vis_n_num                                    -- �K��m����
       ,ir_hon_tab(i).vis_o_num                                    -- �K��n����
       ,ir_hon_tab(i).vis_p_num                                    -- �K��o����
       ,ir_hon_tab(i).vis_q_num                                    -- �K��p����
       ,ir_hon_tab(i).vis_r_num                                    -- �K��q����
       ,ir_hon_tab(i).vis_s_num                                    -- �K��r����
       ,ir_hon_tab(i).vis_t_num                                    -- �K��s����
       ,ir_hon_tab(i).vis_u_num                                    -- �K��t����
       ,ir_hon_tab(i).vis_v_num                                    -- �K��u����
       ,ir_hon_tab(i).vis_w_num                                    -- �K��v����
       ,ir_hon_tab(i).vis_x_num                                    -- �K��w����
       ,ir_hon_tab(i).vis_y_num                                    -- �K��x����
       ,ir_hon_tab(i).vis_z_num                                    -- �K��y����
       ,cn_created_by                                              -- �쐬��
       ,cd_creation_date                                           -- �쐬��
       ,cn_last_updated_by                                         -- �ŏI�X�V��
       ,cd_last_update_date                                        -- �ŏI�X�V��
       ,cn_last_update_login                                       -- �ŏI�X�V���O�C��
       ,cn_request_id                                              -- �v��ID
       ,cn_program_application_id                                  -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
       ,cn_program_id                                              -- �R���J�����g�E�v���O����ID
       ,cd_program_update_date                                     -- �v���O�����X�V��
      );
--
DO_ERROR('A-X-4-2');
--
      gn_normal_cnt := gn_normal_cnt + 1;
    END LOOP;
    -- �w�b�_�[��
    INSERT INTO xxcso_rep_visit_sale_plan(
       report_output_no                                 -- ���[�o�̓Z�b�g�ԍ�
      ,line_kind                                        -- ���[�o�͈ʒu
      ,line_num                                         -- �s�ԍ�
      ,report_id                                        -- ���[�h�c
      ,report_name                                      -- ���[�^�C�g��
      ,output_date                                      -- �o�͓���
      ,year_month                                       -- ��N��
      ,operation_days                                   -- �ғ�����
      ,operation_all_days                               -- �ғ��\����
      ,up_base_code                                     -- ���_�R�[�h�i�e�j
      ,up_hub_name                                      -- ���_���́i�e�j
      ,base_code                                        -- ���_�R�[�h
      ,hub_name                                         -- ���_����
      ,group_number                                     -- �c�ƃO���[�v�ԍ�
      ,group_name                                       -- �c�ƃO���[�v��
      ,employee_number                                  -- �c�ƈ��R�[�h
      ,employee_name                                    -- �c�ƈ���
      ,business_high_type                               -- �Ƒԁi�啪�ށj
      ,business_high_name                               -- �Ƒԁi�啪�ށj��
      ,gvm_type                                         -- ��ʁ^���̋@�^�l�b
      ,account_number                                   -- �ڋq�R�[�h
      ,customer_name                                    -- �ڋq��
      ,route_no                                         -- ���[�gNo
      ,last_year_rslt_sales_amt                         -- �O�N����
      ,last_mon_rslt_sales_amt                          -- �挎����
      ,new_customer_num                                 -- �V�K�ڋq����
      ,new_vendor_num                                   -- �V�K�u�c����
      ,new_customer_amt                                 -- �V�K�ڋq�������
      ,new_vendor_amt                                   -- �V�K�u�c�������
      ,plan_sales_amt                                   -- ����\�Z
      ,plan_vs_amt_1                                    -- �P���|����^�K��v��
      ,rslt_vs_amt_1                                    -- �P���|����^�K�����
      ,rslt_other_sales_amt_1                           -- �P���|������сi�����_�[�i���j
      ,effective_num_1                                  -- �P���|�L������
      ,visit_sign_1                                     -- �P���|�K��L��
      ,plan_vs_amt_2                                    -- �Q���|����^�K��v��
      ,rslt_vs_amt_2                                    -- �Q���|����^�K�����
      ,rslt_other_sales_amt_2                           -- �Q���|������сi�����_�[�i���j
      ,effective_num_2                                  -- �Q���|�L������
      ,visit_sign_2                                     -- �Q���|�K��L��
      ,plan_vs_amt_3                                    -- �R���|����^�K��v��
      ,rslt_vs_amt_3                                    -- �R���|����^�K�����
      ,rslt_other_sales_amt_3                           -- �R���|������сi�����_�[�i���j
      ,effective_num_3                                  -- �R���|�L������
      ,visit_sign_3                                     -- �R���|�K��L��
      ,plan_vs_amt_4                                    -- �S���|����^�K��v��
      ,rslt_vs_amt_4                                    -- �S���|����^�K�����
      ,rslt_other_sales_amt_4                           -- �S���|������сi�����_�[�i���j
      ,effective_num_4                                  -- �S���|�L������
      ,visit_sign_4                                     -- �S���|�K��L��
      ,plan_vs_amt_5                                    -- �T���|����^�K��v��
      ,rslt_vs_amt_5                                    -- �T���|����^�K�����
      ,rslt_other_sales_amt_5                           -- �T���|������сi�����_�[�i���j
      ,effective_num_5                                  -- �T���|�L������
      ,visit_sign_5                                     -- �T���|�K��L��
      ,plan_vs_amt_6                                    -- �U���|����^�K��v��
      ,rslt_vs_amt_6                                    -- �U���|����^�K�����
      ,rslt_other_sales_amt_6                           -- �U���|������сi�����_�[�i���j
      ,effective_num_6                                  -- �U���|�L������
      ,visit_sign_6                                     -- �U���|�K��L��
      ,plan_vs_amt_7                                    -- �V���|����^�K��v��
      ,rslt_vs_amt_7                                    -- �V���|����^�K�����
      ,rslt_other_sales_amt_7                           -- �V���|������сi�����_�[�i���j
      ,effective_num_7                                  -- �V���|�L������
      ,visit_sign_7                                     -- �V���|�K��L��
      ,plan_vs_amt_8                                    -- �W���|����^�K��v��
      ,rslt_vs_amt_8                                    -- �W���|����^�K�����
      ,rslt_other_sales_amt_8                           -- �W���|������сi�����_�[�i���j
      ,effective_num_8                                  -- �W���|�L������
      ,visit_sign_8                                     -- �W���|�K��L��
      ,plan_vs_amt_9                                    -- �X���|����^�K��v��
      ,rslt_vs_amt_9                                    -- �X���|����^�K�����
      ,rslt_other_sales_amt_9                           -- �X���|������сi�����_�[�i���j
      ,effective_num_9                                  -- �X���|�L������
      ,visit_sign_9                                     -- �X���|�K��L��
      ,plan_vs_amt_10                                   -- �P�O���|����^�K��v��
      ,rslt_vs_amt_10                                   -- �P�O���|����^�K�����
      ,rslt_other_sales_amt_10                          -- �P�O���|������сi�����_�[�i���j
      ,effective_num_10                                 -- �P�O���|�L������
      ,visit_sign_10                                    -- �P�O���|�K��L��
      ,plan_vs_amt_11                                   -- �P�P���|����^�K��v��
      ,rslt_vs_amt_11                                   -- �P�P���|����^�K�����
      ,rslt_other_sales_amt_11                          -- �P�P���|������сi�����_�[�i���j
      ,effective_num_11                                 -- �P�P���|�L������
      ,visit_sign_11                                    -- �P�P���|�K��L��
      ,plan_vs_amt_12                                   -- �P�Q���|����^�K��v��
      ,rslt_vs_amt_12                                   -- �P�Q���|����^�K�����
      ,rslt_other_sales_amt_12                          -- �P�Q���|������сi�����_�[�i���j
      ,effective_num_12                                 -- �P�Q���|�L������
      ,visit_sign_12                                    -- �P�Q���|�K��L��
      ,plan_vs_amt_13                                   -- �P�R���|����^�K��v��
      ,rslt_vs_amt_13                                   -- �P�R���|����^�K�����
      ,rslt_other_sales_amt_13                          -- �P�R���|������сi�����_�[�i���j
      ,effective_num_13                                 -- �P�R���|�L������
      ,visit_sign_13                                    -- �P�R���|�K��L��
      ,plan_vs_amt_14                                   -- �P�S���|����^�K��v��
      ,rslt_vs_amt_14                                   -- �P�S���|����^�K�����
      ,rslt_other_sales_amt_14                          -- �P�S���|������сi�����_�[�i���j
      ,effective_num_14                                 -- �P�S���|�L������
      ,visit_sign_14                                    -- �P�S���|�K��L��
      ,plan_vs_amt_15                                   -- �P�T���|����^�K��v��
      ,rslt_vs_amt_15                                   -- �P�T���|����^�K�����
      ,rslt_other_sales_amt_15                          -- �P�T���|������сi�����_�[�i���j
      ,effective_num_15                                 -- �P�T���|�L������
      ,visit_sign_15                                    -- �P�T���|�K��L��
      ,plan_vs_amt_16                                   -- �P�U���|����^�K��v��
      ,rslt_vs_amt_16                                   -- �P�U���|����^�K�����
      ,rslt_other_sales_amt_16                          -- �P�U���|������сi�����_�[�i���j
      ,effective_num_16                                 -- �P�U���|�L������
      ,visit_sign_16                                    -- �P�U���|�K��L��
      ,plan_vs_amt_17                                   -- �P�V���|����^�K��v��
      ,rslt_vs_amt_17                                   -- �P�V���|����^�K�����
      ,rslt_other_sales_amt_17                          -- �P�V���|������сi�����_�[�i���j
      ,effective_num_17                                 -- �P�V���|�L������
      ,visit_sign_17                                    -- �P�V���|�K��L��
      ,plan_vs_amt_18                                   -- �P�W���|����^�K��v��
      ,rslt_vs_amt_18                                   -- �P�W���|����^�K�����
      ,rslt_other_sales_amt_18                          -- �P�W���|������сi�����_�[�i���j
      ,effective_num_18                                 -- �P�W���|�L������
      ,visit_sign_18                                    -- �P�W���|�K��L��
      ,plan_vs_amt_19                                   -- �P�X���|����^�K��v��
      ,rslt_vs_amt_19                                   -- �P�X���|����^�K�����
      ,rslt_other_sales_amt_19                          -- �P�X���|������сi�����_�[�i���j
      ,effective_num_19                                 -- �P�X���|�L������
      ,visit_sign_19                                    -- �P�X���|�K��L��
      ,plan_vs_amt_20                                   -- �Q�O���|����^�K��v��
      ,rslt_vs_amt_20                                   -- �Q�O���|����^�K�����
      ,rslt_other_sales_amt_20                          -- �Q�O���|������сi�����_�[�i���j
      ,effective_num_20                                 -- �Q�O���|�L������
      ,visit_sign_20                                    -- �Q�O���|�K��L��
      ,plan_vs_amt_21                                   -- �Q�P���|����^�K��v��
      ,rslt_vs_amt_21                                   -- �Q�P���|����^�K�����
      ,rslt_other_sales_amt_21                          -- �Q�P���|������сi�����_�[�i���j
      ,effective_num_21                                 -- �Q�P���|�L������
      ,visit_sign_21                                    -- �Q�P���|�K��L��
      ,plan_vs_amt_22                                   -- �Q�Q���|����^�K��v��
      ,rslt_vs_amt_22                                   -- �Q�Q���|����^�K�����
      ,rslt_other_sales_amt_22                          -- �Q�Q���|������сi�����_�[�i���j
      ,effective_num_22                                 -- �Q�Q���|�L������
      ,visit_sign_22                                    -- �Q�Q���|�K��L��
      ,plan_vs_amt_23                                   -- �Q�R���|����^�K��v��
      ,rslt_vs_amt_23                                   -- �Q�R���|����^�K�����
      ,rslt_other_sales_amt_23                          -- �Q�R���|������сi�����_�[�i���j
      ,effective_num_23                                 -- �Q�R���|�L������
      ,visit_sign_23                                    -- �Q�R���|�K��L��
      ,plan_vs_amt_24                                   -- �Q�S���|����^�K��v��
      ,rslt_vs_amt_24                                   -- �Q�S���|����^�K�����
      ,rslt_other_sales_amt_24                          -- �Q�S���|������сi�����_�[�i���j
      ,effective_num_24                                 -- �Q�S���|�L������
      ,visit_sign_24                                    -- �Q�S���|�K��L��
      ,plan_vs_amt_25                                   -- �Q�T���|����^�K��v��
      ,rslt_vs_amt_25                                   -- �Q�T���|����^�K�����
      ,rslt_other_sales_amt_25                          -- �Q�T���|������сi�����_�[�i���j
      ,effective_num_25                                 -- �Q�T���|�L������
      ,visit_sign_25                                    -- �Q�T���|�K��L��
      ,plan_vs_amt_26                                   -- �Q�U���|����^�K��v��
      ,rslt_vs_amt_26                                   -- �Q�U���|����^�K�����
      ,rslt_other_sales_amt_26                          -- �Q�U���|������сi�����_�[�i���j
      ,effective_num_26                                 -- �Q�U���|�L������
      ,visit_sign_26                                    -- �Q�U���|�K��L��
      ,plan_vs_amt_27                                   -- �Q�V���|����^�K��v��
      ,rslt_vs_amt_27                                   -- �Q�V���|����^�K�����
      ,rslt_other_sales_amt_27                          -- �Q�V���|������сi�����_�[�i���j
      ,effective_num_27                                 -- �Q�V���|�L������
      ,visit_sign_27                                    -- �Q�V���|�K��L��
      ,plan_vs_amt_28                                   -- �Q�W���|����^�K��v��
      ,rslt_vs_amt_28                                   -- �Q�W���|����^�K�����
      ,rslt_other_sales_amt_28                          -- �Q�W���|������сi�����_�[�i���j
      ,effective_num_28                                 -- �Q�W���|�L������
      ,visit_sign_28                                    -- �Q�W���|�K��L��
      ,plan_vs_amt_29                                   -- �Q�X���|����^�K��v��
      ,rslt_vs_amt_29                                   -- �Q�X���|����^�K�����
      ,rslt_other_sales_amt_29                          -- �Q�X���|������сi�����_�[�i���j
      ,effective_num_29                                 -- �Q�X���|�L������
      ,visit_sign_29                                    -- �Q�X���|�K��L��
      ,plan_vs_amt_30                                   -- �R�O���|����^�K��v��
      ,rslt_vs_amt_30                                   -- �R�O���|����^�K�����
      ,rslt_other_sales_amt_30                          -- �R�O���|������сi�����_�[�i���j
      ,effective_num_30                                 -- �R�O���|�L������
      ,visit_sign_30                                    -- �R�O���|�K��L��
      ,plan_vs_amt_31                                   -- �R�P���|����^�K��v��
      ,rslt_vs_amt_31                                   -- �R�P���|����^�K�����
      ,rslt_other_sales_amt_31                          -- �R�P���|������сi�����_�[�i���j
      ,effective_num_31                                 -- �R�P���|�L������
      ,visit_sign_31                                    -- �R�P���|�K��L��
      ,vis_a_num                                        -- �K��`����
      ,vis_b_num                                        -- �K��a����
      ,vis_c_num                                        -- �K��b����
      ,vis_d_num                                        -- �K��c����
      ,vis_e_num                                        -- �K��d����
      ,vis_f_num                                        -- �K��e����
      ,vis_g_num                                        -- �K��f����
      ,vis_h_num                                        -- �K��g����
      ,vis_i_num                                        -- �K���@����
      ,vis_j_num                                        -- �K��i����
      ,vis_k_num                                        -- �K��j����
      ,vis_l_num                                        -- �K��k����
      ,vis_m_num                                        -- �K��l����
      ,vis_n_num                                        -- �K��m����
      ,vis_o_num                                        -- �K��n����
      ,vis_p_num                                        -- �K��o����
      ,vis_q_num                                        -- �K��p����
      ,vis_r_num                                        -- �K��q����
      ,vis_s_num                                        -- �K��r����
      ,vis_t_num                                        -- �K��s����
      ,vis_u_num                                        -- �K��t����
      ,vis_v_num                                        -- �K��u����
      ,vis_w_num                                        -- �K��v����
      ,vis_x_num                                        -- �K��w����
      ,vis_y_num                                        -- �K��x����
      ,vis_z_num                                        -- �K��y����
      ,created_by                                       -- �쐬��
      ,creation_date                                    -- �쐬��
      ,last_updated_by                                  -- �ŏI�X�V��
      ,last_update_date                                 -- �ŏI�X�V��
      ,last_update_login                                -- �ŏI�X�V���O�C��
      ,request_id                                       -- �v��ID
      ,program_application_id                           -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,program_id                                       -- �R���J�����g�E�v���O����ID
      ,program_update_date                               -- �v���O�����X�V��
    )
    VALUES(
       in_report_output_no                              -- ���[�o�̓Z�b�g�ԍ�
      ,cn_line_kind1                                    -- ���[�o�͈ʒu
      ,1                                                -- �s�ԍ�
      ,lv_report_id                                     -- ���[�h�c
      ,lv_report_name                                   -- ���[�^�C�g��
      ,SYSDATE                                          -- �o�͓���
      ,gd_year_month                                    -- ��N��
      ,gn_operation_days                                -- �ғ�����
      ,gn_operation_all_days                            -- �ғ��\����
      ,lv_up_base_code                                  -- ���_�R�[�h�i�e�j
      ,lv_up_hub_name                                   -- ���_���́i�e�j
      ,lv_base_code                                     -- ���_�R�[�h
      ,lv_hub_name                                      -- ���_����
      ,lv_group_number                                  -- �c�ƃO���[�v�ԍ�
      ,lv_group_name                                    -- �c�ƃO���[�v��
      ,lv_employee_number                               -- �c�ƈ��R�[�h
      ,lv_employee_name                                 -- �c�ƈ���
      ,NULL                                             -- �Ƒԁi�啪�ށj
      ,NULL                                             -- �Ƒԁi�啪�ށj��
      ,NULL                                             -- ��ʁ^���̋@�^�l�b
      ,NULL                                             -- �ڋq�R�[�h
      ,NULL                                             -- �ڋq��
      ,NULL                                             -- ���[�gNo
      ,NULL                                             -- �O�N����
      ,NULL                                             -- �挎����
      ,NULL                                             -- �V�K�ڋq����
      ,NULL                                             -- �V�K�u�c����
      ,NULL                                             -- �V�K�ڋq�������
      ,NULL                                             -- �V�K�u�c�������
      ,NULL                                             -- ����\�Z
      ,NULL                                             -- �P���|����^�K��v��
      ,NULL                                             -- �P���|����^�K�����
      ,NULL                                             -- �P���|������сi�����_�[�i���j
      ,NULL                                             -- �P���|�L������
      ,NULL                                             -- �P���|�K��L��
      ,NULL                                             -- �Q���|����^�K��v��
      ,NULL                                             -- �Q���|����^�K�����
      ,NULL                                             -- �Q���|������сi�����_�[�i���j
      ,NULL                                             -- �Q���|�L������
      ,NULL                                             -- �Q���|�K��L��
      ,NULL                                             -- �R���|����^�K��v��
      ,NULL                                             -- �R���|����^�K�����
      ,NULL                                             -- �R���|������сi�����_�[�i���j
      ,NULL                                             -- �R���|�L������
      ,NULL                                             -- �R���|�K��L��
      ,NULL                                             -- �S���|����^�K��v��
      ,NULL                                             -- �S���|����^�K�����
      ,NULL                                             -- �S���|������сi�����_�[�i���j
      ,NULL                                             -- �S���|�L������
      ,NULL                                             -- �S���|�K��L��
      ,NULL                                             -- �T���|����^�K��v��
      ,NULL                                             -- �T���|����^�K�����
      ,NULL                                             -- �T���|������сi�����_�[�i���j
      ,NULL                                             -- �T���|�L������
      ,NULL                                             -- �T���|�K��L��
      ,NULL                                             -- �U���|����^�K��v��
      ,NULL                                             -- �U���|����^�K�����
      ,NULL                                             -- �U���|������сi�����_�[�i���j
      ,NULL                                             -- �U���|�L������
      ,NULL                                             -- �U���|�K��L��
      ,NULL                                             -- �V���|����^�K��v��
      ,NULL                                             -- �V���|����^�K�����
      ,NULL                                             -- �V���|������сi�����_�[�i���j
      ,NULL                                             -- �V���|�L������
      ,NULL                                             -- �V���|�K��L��
      ,NULL                                             -- �W���|����^�K��v��
      ,NULL                                             -- �W���|����^�K�����
      ,NULL                                             -- �W���|������сi�����_�[�i���j
      ,NULL                                             -- �W���|�L������
      ,NULL                                             -- �W���|�K��L��
      ,NULL                                             -- �X���|����^�K��v��
      ,NULL                                             -- �X���|����^�K�����
      ,NULL                                             -- �X���|������сi�����_�[�i���j
      ,NULL                                             -- �X���|�L������
      ,NULL                                             -- �X���|�K��L��
      ,NULL                                             -- �P�O���|����^�K��v��
      ,NULL                                             -- �P�O���|����^�K�����
      ,NULL                                             -- �P�O���|������сi�����_�[�i��
      ,NULL                                             -- �P�O���|�L������
      ,NULL                                             -- �P�O���|�K��L��
      ,NULL                                             -- �P�P���|����^�K��v��
      ,NULL                                             -- �P�P���|����^�K�����
      ,NULL                                             -- �P�P���|������сi�����_�[�i��
      ,NULL                                             -- �P�P���|�L������
      ,NULL                                             -- �P�P���|�K��L��
      ,NULL                                             -- �P�Q���|����^�K��v��
      ,NULL                                             -- �P�Q���|����^�K�����
      ,NULL                                             -- �P�Q���|������сi�����_�[�i��
      ,NULL                                             -- �P�Q���|�L������
      ,NULL                                             -- �P�Q���|�K��L��
      ,NULL                                             -- �P�R���|����^�K��v��
      ,NULL                                             -- �P�R���|����^�K�����
      ,NULL                                             -- �P�R���|������сi�����_�[�i��
      ,NULL                                             -- �P�R���|�L������
      ,NULL                                             -- �P�R���|�K��L��
      ,NULL                                             -- �P�S���|����^�K��v��
      ,NULL                                             -- �P�S���|����^�K�����
      ,NULL                                             -- �P�S���|������сi�����_�[�i��
      ,NULL                                             -- �P�S���|�L������
      ,NULL                                             -- �P�S���|�K��L��
      ,NULL                                             -- �P�T���|����^�K��v��
      ,NULL                                             -- �P�T���|����^�K�����
      ,NULL                                             -- �P�T���|������сi�����_�[�i��
      ,NULL                                             -- �P�T���|�L������
      ,NULL                                             -- �P�T���|�K��L��
      ,NULL                                             -- �P�U���|����^�K��v��
      ,NULL                                             -- �P�U���|����^�K�����
      ,NULL                                             -- �P�U���|������сi�����_�[�i��
      ,NULL                                             -- �P�U���|�L������
      ,NULL                                             -- �P�U���|�K��L��
      ,NULL                                             -- �P�V���|����^�K��v��
      ,NULL                                             -- �P�V���|����^�K�����
      ,NULL                                             -- �P�V���|������сi�����_�[�i��
      ,NULL                                             -- �P�V���|�L������
      ,NULL                                             -- �P�V���|�K��L��
      ,NULL                                             -- �P�W���|����^�K��v��
      ,NULL                                             -- �P�W���|����^�K�����
      ,NULL                                             -- �P�W���|������сi�����_�[�i��
      ,NULL                                             -- �P�W���|�L������
      ,NULL                                             -- �P�W���|�K��L��
      ,NULL                                             -- �P�X���|����^�K��v��
      ,NULL                                             -- �P�X���|����^�K�����
      ,NULL                                             -- �P�X���|������сi�����_�[�i��
      ,NULL                                             -- �P�X���|�L������
      ,NULL                                             -- �P�X���|�K��L��
      ,NULL                                             -- �Q�O���|����^�K��v��
      ,NULL                                             -- �Q�O���|����^�K�����
      ,NULL                                             -- �Q�O���|������сi�����_�[�i��
      ,NULL                                             -- �Q�O���|�L������
      ,NULL                                             -- �Q�O���|�K��L��
      ,NULL                                             -- �Q�P���|����^�K��v��
      ,NULL                                             -- �Q�P���|����^�K�����
      ,NULL                                             -- �Q�P���|������сi�����_�[�i��
      ,NULL                                             -- �Q�P���|�L������
      ,NULL                                             -- �Q�P���|�K��L��
      ,NULL                                             -- �Q�Q���|����^�K��v��
      ,NULL                                             -- �Q�Q���|����^�K�����
      ,NULL                                             -- �Q�Q���|������сi�����_�[�i��
      ,NULL                                             -- �Q�Q���|�L������
      ,NULL                                             -- �Q�Q���|�K��L��
      ,NULL                                             -- �Q�R���|����^�K��v��
      ,NULL                                             -- �Q�R���|����^�K�����
      ,NULL                                             -- �Q�R���|������сi�����_�[�i��
      ,NULL                                             -- �Q�R���|�L������
      ,NULL                                             -- �Q�R���|�K��L��
      ,NULL                                             -- �Q�S���|����^�K��v��
      ,NULL                                             -- �Q�S���|����^�K�����
      ,NULL                                             -- �Q�S���|������сi�����_�[�i��
      ,NULL                                             -- �Q�S���|�L������
      ,NULL                                             -- �Q�S���|�K��L��
      ,NULL                                             -- �Q�T���|����^�K��v��
      ,NULL                                             -- �Q�T���|����^�K�����
      ,NULL                                             -- �Q�T���|������сi�����_�[�i��
      ,NULL                                             -- �Q�T���|�L������
      ,NULL                                             -- �Q�T���|�K��L��
      ,NULL                                             -- �Q�U���|����^�K��v��
      ,NULL                                             -- �Q�U���|����^�K�����
      ,NULL                                             -- �Q�U���|������сi�����_�[�i��
      ,NULL                                             -- �Q�U���|�L������
      ,NULL                                             -- �Q�U���|�K��L��
      ,NULL                                             -- �Q�V���|����^�K��v��
      ,NULL                                             -- �Q�V���|����^�K�����
      ,NULL                                             -- �Q�V���|������сi�����_�[�i��
      ,NULL                                             -- �Q�V���|�L������
      ,NULL                                             -- �Q�V���|�K��L��
      ,NULL                                             -- �Q�W���|����^�K��v��
      ,NULL                                             -- �Q�W���|����^�K�����
      ,NULL                                             -- �Q�W���|������сi�����_�[�i��
      ,NULL                                             -- �Q�W���|�L������
      ,NULL                                             -- �Q�W���|�K��L��
      ,NULL                                             -- �Q�X���|����^�K��v��
      ,NULL                                             -- �Q�X���|����^�K�����
      ,NULL                                             -- �Q�X���|������сi�����_�[�i��
      ,NULL                                             -- �Q�X���|�L������
      ,NULL                                             -- �Q�X���|�K��L��
      ,NULL                                             -- �R�O���|����^�K��v��
      ,NULL                                             -- �R�O���|����^�K�����
      ,NULL                                             -- �R�O���|������сi�����_�[�i��
      ,NULL                                             -- �R�O���|�L������
      ,NULL                                             -- �R�O���|�K��L��
      ,NULL                                             -- �R�P���|����^�K��v��
      ,NULL                                             -- �R�P���|����^�K�����
      ,NULL                                             -- �R�P���|������сi�����_�[�i��
      ,NULL                                             -- �R�P���|�L������
      ,NULL                                             -- �R�P���|�K��L��
      ,NULL                                             -- �K��`����
      ,NULL                                             -- �K��a����
      ,NULL                                             -- �K��b����
      ,NULL                                             -- �K��c����
      ,NULL                                             -- �K��d����
      ,NULL                                             -- �K��e����
      ,NULL                                             -- �K��f����
      ,NULL                                             -- �K��g����
      ,NULL                                             -- �K���@����
      ,NULL                                             -- �K��i����
      ,NULL                                             -- �K��j����
      ,NULL                                             -- �K��k����
      ,NULL                                             -- �K��l����
      ,NULL                                             -- �K��m����
      ,NULL                                             -- �K��n����
      ,NULL                                             -- �K��o����
      ,NULL                                             -- �K��p����
      ,NULL                                             -- �K��q����
      ,NULL                                             -- �K��r����
      ,NULL                                             -- �K��s����
      ,NULL                                             -- �K��t����
      ,NULL                                             -- �K��u����
      ,NULL                                             -- �K��v����
      ,NULL                                             -- �K��w����
      ,NULL                                             -- �K��x����
      ,NULL                                             -- �K��y����
      ,cn_created_by                                    -- �쐬��
      ,cd_creation_date                                 -- �쐬��
      ,cn_last_updated_by                               -- �ŏI�X�V��
      ,cd_last_update_date                              -- �ŏI�X�V��
      ,cn_last_update_login                             -- �ŏI�X�V���O�C��
      ,cn_request_id                                    -- �v��ID
      ,cn_program_application_id                        -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
      ,cn_program_id                                    -- �R���J�����g�E�v���O����ID
      ,cd_program_update_date                           -- �v���O�����X�V��
    );
--
DO_ERROR('A-X-4-3');
--
    gn_normal_cnt := gn_normal_cnt + 1;
        debug(
          buff   => ''      || cv_lf ||     -- ��s�̑}��
                  '���[�N�e�[�u���ւ̏o�͊���'
        );
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END insert_wrk_table;
--
  /**********************************************************************************
   * Procedure Name   : up_plsql_tab1
   * Description      : ���[���1-�c�ƈ���-PLSQL�\�̍X�V (A-3-3)
  ***********************************************************************************/
  PROCEDURE up_plsql_tab1(
     i_month_square_rec  IN             g_month_rtype1                     -- �ꃖ�����f�[�^
    ,in_m_cnt            IN             NUMBER                             -- ���ו��̃J�E���^
    ,io_m_tab            IN OUT NOCOPY  g_get_month_square_ttype           -- ���ו��z��
    ,io_hon_tab          IN OUT NOCOPY  g_get_month_square_ttype           -- �{�̕��z��
    ,ov_errbuf           OUT NOCOPY     VARCHAR2           -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY     VARCHAR2           -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY     VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'up_plsql_tab1';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    ln_m_cnt     NUMBER(5);                         -- ���ו��J�E���^�[
    lv_gvm_type  xxcso_rep_visit_sale_plan.gvm_type%TYPE;
    BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
      ln_m_cnt    := in_m_cnt;
      -- DEBUG���b�Z�[�W
      -- PL/SQL�\�̍X�V
      debug(
         buff   => '�c�ƈ���-PL/SQL�\�̍X�V����:' || TO_CHAR(ln_m_cnt)
      );
      -- ����グ���ו�
      BEGIN
        io_m_tab(ln_m_cnt).base_code       := i_month_square_rec.work_base_code;            -- �Ζ��n���_�R�[�h
        io_m_tab(ln_m_cnt).hub_name        := i_month_square_rec.base_name;                 -- �Ζ��n���_��
        io_m_tab(ln_m_cnt).employee_number := i_month_square_rec.employee_number;           -- �]�ƈ��ԍ�
        io_m_tab(ln_m_cnt).employee_name   := i_month_square_rec.name;                      -- �]�ƈ���
        io_m_tab(ln_m_cnt).account_number  := i_month_square_rec.account_number;            -- �ڋq�R�[�h
        io_m_tab(ln_m_cnt).customer_name   := i_month_square_rec.party_name;                -- �ڋq��
        io_m_tab(ln_m_cnt).route_no        := i_month_square_rec.route_number;              -- ���[�gNo
        io_m_tab(ln_m_cnt).last_year_rslt_sales_amt := i_month_square_rec.rslt_amty;        -- �O�N����
        io_m_tab(ln_m_cnt).last_mon_rslt_sales_amt  := i_month_square_rec.rslt_amtm;        -- �挎����
        io_m_tab(ln_m_cnt).plan_sales_amt  := i_month_square_rec.tgt_sales_prsn_total_amt;  -- ���ʔ���\�Z
        io_m_tab(ln_m_cnt).gvm_type        := i_month_square_rec.gvm_type;                  -- ���/���̋@/����
        io_m_tab(ln_m_cnt).business_high_type := i_month_square_rec.business_high_type;     -- �Ƒԁi�啪�ށj
        io_m_tab(ln_m_cnt).business_high_name := i_month_square_rec.business_high_name;     -- �Ƒԁi�啪�ށj��
        -- DEBUG���b�Z�[�W
        -- PL/SQL�\�̍X�V
        debug(
           buff   => '�c�ƈ���-PL/SQL�\�̍X�V����' || '����グ���ו��Œ蕔����'
        );
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(
             which  => FND_FILE.LOG,
             buff   => '�c�ƈ���-PL/SQL�\�̍X�V�������s:' || SQLERRM 
          );
        RAISE global_api_others_expt;
      END;  
      -- ����グ���v��
      IF(ln_m_cnt = 1) THEN
        -- DEBUG���b�Z�[�W
        -- PL/SQL�\�̍X�V
        debug(
           buff   => '�c�ƈ���-PL/SQL�\�̍X�V����' || '�{�̕��̌Œ蕔'
        );
        FOR i IN 1..cn_idx_max LOOP 
          IF (i = cn_idx_sales_ippn) THEN
            io_hon_tab(i).gvm_type := cv_gvm_g;    -- ���
          ELSIF(i = cn_idx_sales_vd) THEN
            io_hon_tab(i).gvm_type := cv_gvm_v;    -- ���̋@
          ELSIF(i = cn_idx_sales_sum) THEN
            io_hon_tab(i).plan_sales_amt     := i_month_square_rec.tgt_sales_prsn_total_amt;-- ����\�Z
          ELSIF(i = cn_idx_visit_ippn) THEN
            io_hon_tab(i).gvm_type           := cv_gvm_g;                          -- ���
          ELSIF(i = cn_idx_visit_vd) THEN
            io_hon_tab(i).gvm_type           := cv_gvm_v;                          -- ���̋@
          ELSIF(i = cn_idx_visit_mc) THEN
            io_hon_tab(i).gvm_type           := cv_gvm_m;                          --�^�l�b
          END IF;
          io_hon_tab(i).base_code       := i_month_square_rec.work_base_code;   -- �Ɩ��n���_�R�[�h
          io_hon_tab(i).hub_name        := i_month_square_rec.base_name;        -- �Ɩ��n���_��    
          io_hon_tab(i).employee_number := i_month_square_rec.employee_number;  -- �]�ƈ��ԍ�
          io_hon_tab(i).employee_name   := i_month_square_rec.name;             -- �]�ƈ���
          -- DEBUG���b�Z�[�W
          -- PL/SQL�\�̍X�V
          debug(
             buff   =>  '�Ɩ��n���_�R�[�h:' || io_hon_tab(i).base_code ||
                          '�Ɩ��n���_��:' || io_hon_tab(i).hub_name ||
                            '�]�ƈ��ԍ�:' || io_hon_tab(i).employee_number ||
                              '�]�ƈ���:' || io_hon_tab(i).employee_name
          );
        END LOOP;
      END IF;
--
      -- ���㒆�v��(���)
      IF(i_month_square_rec.gvm_type = cv_gvm_g) THEN      -- ���
        io_hon_tab(cn_idx_sales_ippn).last_year_rslt_sales_amt := 
          io_hon_tab(cn_idx_sales_ippn).last_year_rslt_sales_amt +
          NVL(i_month_square_rec.rslt_amty, 0);    -- �O�N����
        io_hon_tab(cn_idx_sales_ippn).last_mon_rslt_sales_amt  :=
          io_hon_tab(cn_idx_sales_ippn).last_mon_rslt_sales_amt +
          NVL(i_month_square_rec.rslt_amtm, 0);    -- �挎����
      END IF;
      -- ���㒆�v��(���̋@)
      IF(i_month_square_rec.gvm_type = cv_gvm_v) THEN      -- ���̋@
        io_hon_tab(cn_idx_sales_vd).last_year_rslt_sales_amt :=
          io_hon_tab(cn_idx_sales_vd).last_year_rslt_sales_amt +
          NVL(i_month_square_rec.rslt_amty, 0);       -- �O�N����
        io_hon_tab(cn_idx_sales_vd).last_mon_rslt_sales_amt :=
          io_hon_tab(cn_idx_sales_vd).last_mon_rslt_sales_amt +
          NVL(i_month_square_rec.rslt_amtm, 0);       -- �挎����
      END IF;
      -- ���㍇�v��
      io_hon_tab(cn_idx_sales_sum).new_customer_num   := 
        io_hon_tab(cn_idx_sales_sum).new_customer_num +
        NVL(i_month_square_rec.cust_new_num, 0);    -- �ڋq�����i�V�K�j
      io_hon_tab(cn_idx_sales_sum).new_vendor_num     :=
        io_hon_tab(cn_idx_sales_sum).new_vendor_num +
        NVL(i_month_square_rec.cust_vd_new_num, 0); -- �V�K�u�c����
--
      -- ���[���ו�
      FOR i IN 1..31 LOOP
        BEGIN
          -- DEBUG���b�Z�[�W
          -- PL/SQL�\�̍X�V
          debug(
             buff   => '�c�ƈ���-PL/SQL�\�̍X�V����' || '1�������̃f�[�^�X�V'
          );
          IF(i_month_square_rec.gvm_type = cv_gvm_g) THEN      -- ���
            -- ����グ���ו�
            -- DEBUG���b�Z�[�W
            -- PL/SQL�\�̍X�V
            debug(
               buff   => '�c�ƈ���-PL/SQL�\-����グ���ו�(���)�̍X�V����' ||
                          '����グ�v��' || TO_CHAR(i_month_square_rec.l_one_day_tab(i).tgt_amt)
            );
            io_m_tab(ln_m_cnt).l_get_one_day_tab(i).plan_vs_amt
              := i_month_square_rec.l_one_day_tab(i).tgt_amt;                 -- ����グ�v��
            io_m_tab(ln_m_cnt).l_get_one_day_tab(i).rslt_vs_amt
              := i_month_square_rec.l_one_day_tab(i).rslt_amt;                -- ����グ����
            io_m_tab(ln_m_cnt).l_get_one_day_tab(i).rslt_other_sales_amt
              := i_month_square_rec.l_one_day_tab(i).rslt_center_amt;         -- �������_�Q�������
            IF(i_month_square_rec.l_one_day_tab(i).visit_sign IS NOT NULL)THEN
              io_m_tab(ln_m_cnt).l_get_one_day_tab(i).visit_sign
              := SUBSTR('*' || i_month_square_rec.l_one_day_tab(i).visit_sign, 1, 20);       -- �����K��L��
            END IF;
            -- ����グ���v��
            -- DEBUG���b�Z�[�W
            -- PL/SQL�\�̍X�V
            debug(
               buff   => '�c�ƈ���-PL/SQL�\-����グ���v��(���)�̍X�V����'
            );
            io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).plan_vs_amt :=
              io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).plan_vs_amt + 
              NVL(i_month_square_rec.l_one_day_tab(i).tgt_amt,0);             -- ����グ�v��
            io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_vs_amt :=
              io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_vs_amt + 
              NVL(i_month_square_rec.l_one_day_tab(i).rslt_amt,0);            -- ����グ����
            -- �K�⒆�v���i��ʁj
            io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).plan_vs_amt :=
              io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).plan_vs_amt + 
              NVL(i_month_square_rec.l_one_day_tab(i).tgt_vis_num,0);         -- �K��v��
            io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).rslt_vs_amt :=
              io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).rslt_vs_amt + 
              NVL(i_month_square_rec.l_one_day_tab(i).vis_num,0);             -- �K�����
          ELSIF (i_month_square_rec.gvm_type = cv_gvm_v) THEN          -- ���̋@
            -- ����グ���ו�
            -- DEBUG���b�Z�[�W
            -- PL/SQL�\�̍X�V
            debug(
               buff   => '�c�ƈ���-PL/SQL�\-����グ���ו�(���̋@)�̍X�V����' ||
                          '����グ�v��' || TO_CHAR(i_month_square_rec.l_one_day_tab(i).tgt_amt)
            );
            io_m_tab(ln_m_cnt).l_get_one_day_tab(i).plan_vs_amt
              := i_month_square_rec.l_one_day_tab(i).tgt_amt;                 -- ����グ�v��
            io_m_tab(ln_m_cnt).l_get_one_day_tab(i).rslt_vs_amt
              := i_month_square_rec.l_one_day_tab(i).rslt_amt;                -- ����グ����
            io_m_tab(ln_m_cnt).l_get_one_day_tab(i).rslt_other_sales_amt
              := i_month_square_rec.l_one_day_tab(i).rslt_center_amt;         -- �������_�Q�������
            IF(i_month_square_rec.l_one_day_tab(i).visit_sign IS NOT NULL)THEN
              io_m_tab(ln_m_cnt).l_get_one_day_tab(i).visit_sign
              := SUBSTR('*' || i_month_square_rec.l_one_day_tab(i).visit_sign, 1, 20);       -- �����K��L��
            END IF;
            -- ����グ���v��
            -- DEBUG���b�Z�[�W
            -- PL/SQL�\�̍X�V
            debug(
               buff   => '�c�ƈ���-PL/SQL�\-����グ���v��(���̋@)�̍X�V����'
            );
            io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).plan_vs_amt :=
              io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).plan_vs_amt + 
              NVL(i_month_square_rec.l_one_day_tab(i).tgt_amt,0);             -- ����グ�v��
            io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_vs_amt :=
              io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_vs_amt + 
              NVL(i_month_square_rec.l_one_day_tab(i).rslt_amt,0);            -- ����グ����
            -- �K�⒆�v��
            -- DEBUG���b�Z�[�W
            -- PL/SQL�\�̍X�V
            debug(
               buff   => '�c�ƈ���-PL/SQL�\-�K�⒆�v��(���̋@)�̍X�V����'
            );
            io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).plan_vs_amt :=
              io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).plan_vs_amt + 
              NVL(i_month_square_rec.l_one_day_tab(i).tgt_vis_num,0);         -- �K��v��
            io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).rslt_vs_amt :=
              io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).rslt_vs_amt + 
              NVL(i_month_square_rec.l_one_day_tab(i).vis_num,0);             -- �K�����
          ELSIF (i_month_square_rec.gvm_type = cv_gvm_m) THEN                 -- MC
            -- ����グ���ו�
            -- DEBUG���b�Z�[�W
            -- PL/SQL�\�̍X�V
            debug(
               buff   => '�c�ƈ���-PL/SQL�\-����グ���ו�(MC)�̍X�V����' ||
                          '����グ�v��' || TO_CHAR(i_month_square_rec.l_one_day_tab(i).tgt_amt)
            );
            io_m_tab(ln_m_cnt).l_get_one_day_tab(i).plan_vs_amt
              := i_month_square_rec.l_one_day_tab(i).tgt_vis_num;            -- �K��v��
            io_m_tab(ln_m_cnt).l_get_one_day_tab(i).rslt_vs_amt
              := i_month_square_rec.l_one_day_tab(i).vis_num;                -- �K�����
            IF(i_month_square_rec.l_one_day_tab(i).vis_num > 0)THEN
              io_m_tab(ln_m_cnt).l_get_one_day_tab(i).visit_sign
              := '*';                                                        -- �����K��L��
            END IF;
            -- �K�⒆�v��
            -- DEBUG���b�Z�[�W
            -- PL/SQL�\�̍X�V
            debug(
               buff   => '�c�ƈ���-PL/SQL�\-�K�⒆�v��(MC)�̍X�V����'
            );
            io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).plan_vs_amt :=
              io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).plan_vs_amt + 
              NVL(i_month_square_rec.l_one_day_tab(i).tgt_vis_num,0);         -- �K��v��
            io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).rslt_vs_amt :=
              io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).rslt_vs_amt + 
              NVL(i_month_square_rec.l_one_day_tab(i).vis_num,0);             -- �K�����
          END IF;
          -- ����グ���v��
          -- DEBUG���b�Z�[�W
          -- PL/SQL�\�̍X�V
          debug(
             buff   => '�c�ƈ���-PL/SQL�\-����グ���v���̍X�V����'
          );
          -- �K�⍇�v��
          -- DEBUG���b�Z�[�W
          -- PL/SQL�\�̍X�V
          debug(
             buff   => '�c�ƈ���-PL/SQL�\-�K�⍇�v���̍X�V����'
          );
          io_hon_tab(cn_idx_visit_sum).l_get_one_day_tab(i).effective_num :=
            io_hon_tab(cn_idx_visit_sum).l_get_one_day_tab(i).effective_num +
            NVL(i_month_square_rec.l_one_day_tab(i).vis_sales_num,0);              -- �L������
          -- �K����e���v��
          -- DEBUG���b�Z�[�W
          -- PL/SQL�\�̍X�V
          debug(
             buff   => '�c�ƈ���-PL/SQL�\-�K����e���v���̍X�V����'
          );
          -- A0Z�K�⌏��
          io_hon_tab(cn_idx_visit_dsc).vis_a_num := 
             io_hon_tab(cn_idx_visit_dsc).vis_a_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_a_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_b_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_b_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_b_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_c_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_c_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_c_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_d_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_d_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_d_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_e_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_e_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_e_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_f_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_f_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_f_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_g_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_g_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_g_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_h_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_h_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_h_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_i_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_i_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_i_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_j_num := 
             io_hon_tab(cn_idx_visit_dsc).vis_j_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_j_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_k_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_k_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_k_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_l_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_l_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_l_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_m_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_m_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_m_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_n_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_n_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_n_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_o_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_o_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_o_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_p_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_p_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_p_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_q_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_q_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_q_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_r_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_r_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_r_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_s_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_s_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_s_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_t_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_t_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_t_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_u_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_u_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_u_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_v_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_v_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_v_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_w_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_w_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_w_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_x_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_x_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_x_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_y_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_y_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_y_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_z_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_z_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_z_num,0);
          -- DEBUG���b�Z�[�W
          -- PL/SQL�\�̍X�V
          debug(
             buff   => '�c�ƈ���-PL/SQL�\�̖K����e���v�����X�V��������' || 'LOOP����:'|| TO_CHAR(i)
          );
        EXCEPTION
          WHEN OTHERS THEN
          fnd_file.put_line(
             which  => FND_FILE.LOG,
             buff   => '�c�ƈ���-PL/SQL�\-�{�̕��̍X�V�����ŃG���[�ɂȂ�܂����B' || SQLERRM ||
                      ''                         -- ��s�̑}��
           );
          RAISE global_api_others_expt;
        END;
      END LOOP;
      -- DEBUG���b�Z�[�W
      -- PL/SQL�\�̍X�V
      debug(
         buff   => '�c�ƈ���-PL/SQL�\�̍X�V��������'
      );
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
            fnd_file.put_line(
               which  => FND_FILE.LOG,
               buff   => '�c�ƈ���-PL/SQL�\-�K����e���v���̍X�V�����ŃG���[�ɂȂ�܂����B' || SQLERRM ||
                        ''                         -- ��s�̑}��
             );
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END up_plsql_tab1;
--
  /**********************************************************************************
   * Procedure Name   : get_ticket1
   * Description      : ���[���1-�c�ƈ��� (A-3-1,A-3-2)
  ***********************************************************************************/
  PROCEDURE get_ticket1(
    ov_errbuf         OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W            --# �Œ� #
   ,ov_retcode        OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h              --# �Œ� #
   ,ov_errmsg         OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_ticket1';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ���[�J���萔
    -- ���[�J���ϐ�
    lb_boolean            BOOLEAN;      -- ���f�p
    ln_m_cnt              NUMBER(9);    -- ���ו��J�E���^�[���i�[
    ln_cnt                NUMBER(9);    -- ���o���ꂽ���R�[�h����
    ln_date               NUMBER(2);    -- ���t�̃i���o�[�^
    ln_report_output_no   NUMBER(9);    -- ���[�o�̓Z�b�g�ԍ�
    lv_gvm_type           VARCHAR2(1);                                        -- ��ʁ^���̋@�^�l�b
    lv_bf_employee_number xxcso_resource_relations_v2.employee_number%TYPE;   -- �c�ƈ��ԍ��i�[
    lv_bf_account_number  xxcso_cust_accounts_v.account_number%TYPE;          -- �ڋq�R�[�h�i�[
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR ticket_data_cur
    IS
      SELECT  
              (CASE
                WHEN TO_DATE(xrrv.issue_date,'YYYYMMDD') <= gd_online_sysdate
                  THEN xrrv.work_base_code_new
                ELSE xrrv.work_base_code_old
              END 
              ) work_base_code,                             -- �Ζ��n���_�R�[�h
              (CASE
                WHEN TO_DATE(xrrv.issue_date,'YYYYMMDD') <= gd_online_sysdate
                  THEN xrrv.work_base_name_new
                ELSE xrrv.work_base_name_old
              END
              ) base_name,                                  -- �Ζ��n���_��
              xrrv.employee_number employee_number,         -- �]�ƈ��ԍ�
              xrrv.full_name name,                          -- �]�ƈ���
             (CASE
                WHEN xcav.customer_status IN (cv_cust_status4,cv_cust_status5,cv_cust_status6)-- �ڋq�X�e�[�^�X(�ڋq)
                  THEN cv_gvm_m                             -- MC
                WHEN (XXCSO_ROUTE_COMMON_PKG.ISCUSTOMERVENDOR(xcav.business_low_type) = cv_true)
                  THEN cv_gvm_v                             -- ���̋@
                ELSE
                       cv_gvm_g                             -- ���
                END
              )                     gvm_type,               -- ��ʁ^���̋@�^�l�b
              xcav.business_low_type business_low_type,     -- �Ƒԁi�����ށj
              xcav.account_number   account_number,         -- �ڋq�R�[�h
              xcav.party_name       party_name,             -- �ڋq��
              xcrv.route_number     route_number,           -- ���[�gNo
              xsvsr.sales_date      sales_date,             -- �̔��N����
              xsvsr.tgt_amt         tgt_amt,                -- ����v��
              xsvsr.rslt_amt        rslt_amt,               -- �������
              xsvsr.rslt_center_amt rslt_center_amt,        -- �������_�Q�������
              xsvsr.tgt_vis_num     tgt_vis_num,            -- �K��v��
              xsvsr.vis_num         vis_num,                -- �K�����
              xsvsr.vis_sales_num   vis_sales_num,          -- �L������
              xsvsr.vis_new_num     vis_new_num,            -- �K����сi�V�K)
              xsvsr.vis_vd_new_num  vis_vd_new_num,         -- �K����сiVD�F�V�K�j
              xsvsr.vis_a_num       vis_a_num,              -- �K��`����
              xsvsr.vis_b_num       vis_b_num,              -- �K��a����
              xsvsr.vis_c_num       vis_c_num,              -- �K��b����
              xsvsr.vis_d_num       vis_d_num,              -- �K��c����
              xsvsr.vis_e_num       vis_e_num,              -- �K��d����
              xsvsr.vis_f_num       vis_f_num,              -- �K��e����
              xsvsr.vis_g_num       vis_g_num,              -- �K��f����
              xsvsr.vis_h_num       vis_h_num,              -- �K��g����
              xsvsr.vis_i_num       vis_i_num,              -- �K���@����
              xsvsr.vis_j_num       vis_j_num,              -- �K��i����
              xsvsr.vis_k_num       vis_k_num,              -- �K��j����
              xsvsr.vis_l_num       vis_l_num,              -- �K��k����
              xsvsr.vis_m_num       vis_m_num,              -- �K��l����
              xsvsr.vis_n_num       vis_n_num,              -- �K��m����
              xsvsr.vis_o_num       vis_o_num,              -- �K��n����
              xsvsr.vis_p_num       vis_p_num,              -- �K��o����
              xsvsr.vis_q_num       vis_q_num,              -- �K��p����
              xsvsr.vis_r_num       vis_r_num,              -- �K��q����
              xsvsr.vis_s_num       vis_s_num,              -- �K��r����
              xsvsr.vis_t_num       vis_t_num,              -- �K��s����
              xsvsr.vis_u_num       vis_u_num,              -- �K��t����
              xsvsr.vis_v_num       vis_v_num,              -- �K��u����
              xsvsr.vis_w_num       vis_w_num,              -- �K��v����
              xsvsr.vis_x_num       vis_x_num,              -- �K��w����
              xsvsr.vis_y_num       vis_y_num,              -- �K��x����
              xsvsr.vis_z_num       vis_z_num,              -- �K��y����
              xsvsry.rslt_amt       rslt_amty,              -- �O�N����
              xsvsrm.rslt_amt       rslt_amtm,              -- �挎����
              (CASE
                WHEN (0 < xsvsr.vis_a_num) THEN 'A'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_b_num) THEN 'B'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_c_num) THEN 'C'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_d_num) THEN 'D'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_e_num) THEN 'E'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_f_num) THEN 'F'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_g_num) THEN 'G'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_h_num) THEN 'H'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_i_num) THEN 'I'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_j_num) THEN 'J'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_k_num) THEN 'K'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_l_num) THEN 'L'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_m_num) THEN 'M'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_n_num) THEN 'N'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_o_num) THEN 'O'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_p_num) THEN 'P'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_q_num) THEN 'Q'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_r_num) THEN 'R'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_s_num) THEN 'S'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_t_num) THEN 'T'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_u_num) THEN 'U'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_v_num) THEN 'V'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_w_num) THEN 'W'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_x_num) THEN 'X'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_y_num) THEN 'Y'
              END
              ) || (CASE
                WHEN (0 < xsvsr.vis_z_num) THEN 'Z'
              END
              ) visit_sign,                                 -- �����K��L��
              xsvsrn.cust_new_num         cust_new_num,     -- �ڋq�����i�V�K�j
              xsvsrn.cust_vd_new_num      cust_vd_new_num,  -- �ڋq�����iVD�F�V�K�j
              xsvsre.tgt_sales_prsn_total_amt tgt_sales_prsn_total_amt --���ʔ���\�Z
      FROM    xxcso_resource_relations_v2 xrrv              -- ���\�[�X�֘A�}�X�^(�ŐV)VIEW
             ,xxcso_resource_custs_v2     xrcv              -- �c�ƈ��S���ڋq(�ŐV)VIEW
             ,xxcso_cust_accounts_v       xcav              -- �ڋq�}�X�^VIEW
             ,xxcso_cust_routes_v2        xcrv              -- �ڋq���[�gNo(�ŐV)VIEW
             ,xxcso_sum_visit_sale_rep    xsvsr             -- �K�┄��v��Ǘ��\�T�}���e�[�u��
             ,xxcso_sum_visit_sale_rep    xsvsry            -- �K�┄��v��Ǘ��\�T�}���O�N
             ,xxcso_sum_visit_sale_rep    xsvsrm            -- �K�┄��v��Ǘ��\�T�}���挎
             ,xxcso_sum_visit_sale_rep    xsvsrn            -- �K�┄��v��Ǘ��\�T�}������
             ,xxcso_sum_visit_sale_rep    xsvsre            -- �K�┄��v��Ǘ��\�T�}���c�ƈ�
      WHERE   (CASE
                WHEN TO_DATE(xrrv.issue_date,'YYYYMMDD') <= gd_online_sysdate
                  THEN xrrv.work_base_code_new
                ELSE xrrv.work_base_code_old
              END 
              )  = gv_base_code
        AND   ( gv_is_groupleader = cv_false
                OR
                ( gv_is_groupleader = cv_true
                  AND
                  ( CASE 
                      WHEN xrrv.issue_date <= gv_online_sysdate
                        THEN xrrv.group_number_new
                      ELSE xrrv.group_number_old
                    END
                  ) = gt_group_number
                )
              )
        AND   ( gv_is_salesman = cv_false
                OR
                ( gv_is_salesman = cv_true
                  AND
                  xrrv.employee_number = gt_employee_number
                )
              )
        AND   xrrv.employee_number = xrcv.employee_number
        AND   xrcv.account_number  = xcav.account_number
        AND   xcav.account_number  = xcrv.account_number(+)
        AND   ((( xcav.customer_class_code IS NULL  -- �ڋq�敪
                )
                AND
                ( xcav.customer_status IN ( cv_cust_status7, cv_cust_status4 )  -- �ڋq�X�e�[�^�X
                )
               )
           OR  (( xcav.customer_class_code = cv_cust_class_cd3 -- �ڋq�敪
                )
                AND
                ( xcav.customer_status IN ( cv_cust_status5
                                           ,cv_cust_status6
                                           ,cv_cust_status8
                                           ,cv_cust_status9
                                          )  -- �ڋq�X�e�[�^�X
                )
               )
           OR  (( xcav.customer_class_code = cv_cust_class_cd4 -- �ڋq�敪
                )
                AND
                ( xcav.customer_status IN ( cv_cust_status6
                                           ,cv_cust_status8
                                          )  -- �ڋq�X�e�[�^�X
                ))
           OR  (( xcav.customer_class_code = cv_cust_class_cd5 -- �ڋq�敪
                )
                AND
                ( xcav.customer_status = cv_cust_status3 -- �ڋq�X�e�[�^�X
                ))
           OR  (( xcav.customer_class_code = cv_cust_class_cd6 -- �ڋq�敪
                )
                AND
                ( xcav.customer_status = cv_cust_status3 -- �ڋq�X�e�[�^�X
                ))
           OR  (( xcav.customer_class_code = cv_cust_class_cd7 -- �ڋq�敪
                )
                AND
                (xcav.customer_status = cv_cust_status3 -- �ڋq�X�e�[�^�X
                )
               )
              )
        AND   xcav.account_number  = xsvsr.sum_org_code
        AND   xsvsr.sum_org_type   = cv_sum_org_type1
        AND   xsvsr.month_date_div = cv_month_date_div2
        AND   xsvsr.sales_date
                BETWEEN TO_CHAR(gd_year_month_day,'YYYYMMDD') AND TO_CHAR(gd_year_month_lastday,'YYYYMMDD')
        AND   xsvsr.sum_org_type   = xsvsry.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsry.sum_org_code(+)
        AND   xsvsry.month_date_div(+)= cv_month_date_div1
        AND   xsvsry.sales_date(+) = gv_year_prev
        AND   xsvsr.sum_org_type   = xsvsrm.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsrm.sum_org_code(+)
        AND   xsvsrm.month_date_div(+)= cv_month_date_div1
        AND   xsvsrm.sales_date(+) = gv_year_month_prev
        AND   xsvsr.sum_org_type   = xsvsrn.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsrn.sum_org_code(+)
        AND   xsvsrn.month_date_div(+)= cv_month_date_div1
        AND   xsvsrn.sales_date(+) = gv_year_month
        AND   xsvsre.sum_org_type(+) = cv_sum_org_type2
        AND   xsvsre.sum_org_code(+) = xrrv.employee_number
        AND   xsvsre.month_date_div(+)= cv_month_date_div1
        AND   xsvsre.sales_date(+)= gv_year_month
      ORDER BY  work_base_code     ASC,
                employee_number    ASC,
                account_number     ASC;
    -- ���[�J�����R�[�h
    l_cur_rec                  ticket_data_cur%ROWTYPE;
    l_month_square_rec         g_month_rtype1;
    l_get_month_square_tab     g_get_month_square_ttype;
    l_get_month_square_hon_tab g_get_month_square_ttype;
    -- ���[�ϐ��i�[�p
    -- *** ���[�J����O ***
    error_get_data_expt        EXCEPTION;
    BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
      ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
      -- ���[�J���ϐ�������
      lb_boolean                := TRUE;        -- �����������f
      ln_m_cnt                  := 1;           -- ���ו��̍s��
      ln_report_output_no       := 1;           -- �z��s��
      ln_cnt                    := 0;           -- LOOP����(���o����)
      -- PL/SQL�\�i�{�̕��j�̍��ڂ̏�����
      init_month_square_hon_tab(l_get_month_square_hon_tab);
      -- ���[�J�����R�[�h�̏�����
      init_month_square_rec1(l_month_square_rec);
      BEGIN
        --�J�[�\���I�[�v��
        OPEN ticket_data_cur;
--
DO_ERROR('A-3-2-1');
--
        <<get_data_loop>>
        LOOP 
          l_cur_rec                           := NULL;          -- �J�[�\�����R�[�h�̏�����
--
          FETCH ticket_data_cur INTO l_cur_rec;                 -- �J�[�\���̃f�[�^�����R�[�h�Ɋi�[
--
          -- �Ώی�����O���̏ꍇ
          EXIT WHEN ticket_data_cur%NOTFOUND
            OR  ticket_data_cur%ROWCOUNT = 0;
--
DO_ERROR('A-3-2-2');
--
          debug(
            buff   =>l_cur_rec.work_base_code ||  ',' ||
                     l_cur_rec.base_name ||  ',' ||
                     l_cur_rec.employee_number ||  ',' ||
                     l_cur_rec.gvm_type ||  ',' ||
                     l_cur_rec.account_number ||  ',' ||
                     l_cur_rec.party_name ||  ',' ||
                     l_cur_rec.route_number ||  ',' ||
                     l_cur_rec.business_low_type ||  ',' ||
                     l_cur_rec.sales_date ||  ',' ||
                     TO_CHAR(l_cur_rec.tgt_amt)          ||  ',' ||
                     TO_CHAR(l_cur_rec.rslt_amt)         ||  ',' ||
                     TO_CHAR(l_cur_rec.rslt_center_amt)  ||  ',' ||
                     TO_CHAR(l_cur_rec.tgt_vis_num)      ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_num)          ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_sales_num)    ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_new_num)      ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_vd_new_num)   ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_a_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_b_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_c_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_d_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_e_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_f_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_g_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_h_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_i_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_j_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_k_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_l_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_m_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_n_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_o_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_p_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_q_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_r_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_s_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_t_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_u_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_v_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_w_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_x_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_y_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.vis_z_num)        ||  ',' ||
                     TO_CHAR(l_cur_rec.rslt_amty)        ||  ',' ||
                     TO_CHAR(l_cur_rec.rslt_amtm)        ||  ',' ||
                     l_cur_rec.visit_sign                ||  ',' ||
                     TO_CHAR(l_cur_rec.cust_new_num)     ||  ',' ||
                     TO_CHAR(l_cur_rec.cust_vd_new_num)  ||  ',' ||
                     TO_CHAR(l_cur_rec.tgt_sales_prsn_total_amt) ||  ',' ||
                     cv_lf 
          );
          -- �O�񃌃R�[�h�Ɖc�ƈ��ԍ��������Ōڋq�R�[�h���Ⴄ�ꍇ�A���ו��z��Ɩ{�̕��z����X�V�B
          IF (lb_boolean = FALSE) THEN
            IF ((lv_bf_employee_number = l_cur_rec.employee_number) AND
                (lv_bf_account_number <> l_cur_rec.account_number))
              THEN
              -- DEBUG���b�Z�[�W
              debug(
                 buff   => '�ڋq�R�[�h���Ⴂ�܂��B :' ||'�O��F '|| lv_bf_account_number ||
                            '����F' || l_cur_rec.account_number ||
                            '���ו��z��' || TO_CHAR(ln_m_cnt)
              );
              -- =================================================
              -- A-3-3.PLSQL�\�̍X�V
              -- =================================================
              up_plsql_tab1(
                 i_month_square_rec   => l_month_square_rec          -- 1�������f�[�^
                ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
                ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
                ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
                ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
                ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
                ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
              l_month_square_rec.l_one_day_tab.DELETE;  -- ���[�J�����R�[�h�̃f�[�^�������B
              l_month_square_rec      := NULL;          -- ���[�J�����R�[�h�̃f�[�^�������B
              -- ���R�[�h�̏�����
              init_month_square_rec1(l_month_square_rec);
              ln_m_cnt          := ln_m_cnt + 1;       -- ���ו��z����{�P����B
              lb_boolean        := TRUE;               -- ���������̃t���O�I������B
            ELSIF (lv_bf_employee_number <> l_cur_rec.employee_number)
              THEN
                -- =================================================
                -- A-3-3.PLSQL�\�̍X�V
                -- =================================================
                up_plsql_tab1(
                   i_month_square_rec   => l_month_square_rec          -- 1�������f�[�^
                  ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
                  ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
                  ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
                  ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
                  ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
                  ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
                );
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
                l_month_square_rec.l_one_day_tab.DELETE;  -- ���[�J�����R�[�h�̃f�[�^�������B
                l_month_square_rec      := NULL;          -- ���[�J�����R�[�h�̃f�[�^�������B
                -- ���R�[�h�̏�����
                init_month_square_rec1(l_month_square_rec);
                lb_boolean        := TRUE;               -- ���������̃t���O�I������B
            END IF;
          END IF;
          -- �o�̓t���O���I���̏�Ԃŉc�ƈ��ԍ����O��擾�����c�ƈ��ԍ��ƈႤ�ꍇ���[�N�e�[�u���ɏo�͂��܂��B
          IF ((ln_cnt > 0) AND
              (lv_bf_employee_number <> l_cur_rec.employee_number))
            THEN
              -- DEBUG���b�Z�[�W
              debug(
                 buff   => '�]�ƈ����Ⴂ�܂��B :' ||'�O��F '|| lv_bf_employee_number ||
                            '����F' || l_cur_rec.employee_number
              );
              -- =================================================
              -- A-3-4,A-4-4,A-5-4,A-6-4,A-7-4.���[�N�e�[�u���֏o��
              -- =================================================
              insert_wrk_table(
                 ir_m_tab            => l_get_month_square_tab                      -- ���ו����R�[�h
                ,ir_hon_tab          => l_get_month_square_hon_tab                  -- �{�̕����R�[�h
                ,in_m_cnt            => ln_m_cnt                                    -- ���ו��s��
                ,in_report_output_no => ln_report_output_no                         -- ���[�o�̓Z�b�g�ԍ�
                ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
                ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
                ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
              -- ���R�[�h�̏�����
              l_get_month_square_tab.DELETE;
              l_get_month_square_hon_tab.DELETE;
              init_month_square_hon_tab(l_get_month_square_hon_tab);
              ln_m_cnt            := 1;                       -- ���ו��z��̍s���̏�����
              ln_report_output_no := ln_report_output_no + 1; -- �o�͂��ꂽ���[���Ɂ{�P����
              lb_boolean          := TRUE;                    -- ���������̏�Ԃɖ߂�
          END IF;
          -- ���������̏ꍇ
          IF (lb_boolean) THEN
            -- DEBUG���b�Z�[�W
            -- ���������̏ꍇ
            debug(
               buff   => '���������̏ꍇ' || '�ڋq�R�[�h:' || l_cur_rec.account_number ||
                         '�]�ƈ��ԍ�:'     || l_cur_rec.employee_number ||
                         '��ʁ^���̋@�^�l�b:' || l_cur_rec.gvm_type
            );
            -- �O��]�ƈ��ԍ��A�ڋq�R�[�h�����[�J���ϐ��Ɋi�[
            lv_bf_account_number       := l_cur_rec.account_number;          -- �ڋq�R�[�h
            lv_bf_employee_number      := l_cur_rec.employee_number;         -- �]�ƈ��ԍ�
            lv_gvm_type             := l_cur_rec.gvm_type;                -- ��ʁ^���̋@�^�l�b
            -- �擾���ꂽ�f�[�^�����[�J�����R�[�h�Ɋi�[
            -- �ڋq�R�[�h
            l_month_square_rec.account_number     := l_cur_rec.account_number;
            -- �ڋq��
            l_month_square_rec.party_name         := l_cur_rec.party_name;
            -- �]�ƈ��ԍ�
            l_month_square_rec.employee_number    := l_cur_rec.employee_number;
            -- ��ʁ^���̋@�^�l�b
            l_month_square_rec.gvm_type           := l_cur_rec.gvm_type;
            -- �Ζ��n���_�R�[�h
            l_month_square_rec.work_base_code     := l_cur_rec.work_base_code;
            -- �Ζ��n���_��
            l_month_square_rec.base_name          := l_cur_rec.base_name;
            -- �]�ƈ���
            l_month_square_rec.name               := l_cur_rec.name;
            -- ���[�gNo
            l_month_square_rec.route_number       := l_cur_rec.route_number;
            -- �O�N����
            l_month_square_rec.rslt_amty          := l_cur_rec.rslt_amty;
            -- �挎����
            l_month_square_rec.rslt_amtm          := l_cur_rec.rslt_amtm;
            -- ���ʔ���\�Z
            l_month_square_rec.tgt_sales_prsn_total_amt := l_cur_rec.tgt_sales_prsn_total_amt;
            -- �V�K�ڋq����
            l_month_square_rec.cust_new_num       := l_cur_rec.cust_new_num;
            -- �V�KVD����
            l_month_square_rec.cust_vd_new_num    := l_cur_rec.cust_vd_new_num;
            BEGIN
              IF (l_cur_rec.business_low_type IS NOT NULL) THEN
                --�Ƒԁi�����ށj����ƑԃR�[�h�ƋƑԖ����擾
                SELECT dai.lookup_code lookup_code                      -- �ƑԃR�[�h
                ,      dai.meaning     meaning                          -- �ƑԖ�
                INTO   l_month_square_rec.business_high_type
                ,      l_month_square_rec.business_high_name
                FROM   fnd_lookup_values_vl dai
                ,      fnd_lookup_values_vl chu
                ,      fnd_lookup_values_vl syo
                WHERE  syo.lookup_type = cv_lookup_type_syo
                AND    chu.lookup_type = cv_lookup_type_chu
                AND    dai.lookup_type = cv_lookup_type_dai
                AND    syo.lookup_code = l_cur_rec.business_low_type    --�Ƒԁi�����ށj
                AND    chu.lookup_code = syo.attribute1
                AND    dai.lookup_code = chu.attribute1
                AND    syo.enabled_flag   = cv_flg_y
                AND    chu.enabled_flag   = cv_flg_y
                AND    dai.enabled_flag   = cv_flg_y
                AND    NVL(dai.start_date_active, TRUNC(gd_online_sysdate)) <= TRUNC(gd_online_sysdate)
                AND    NVL(dai.end_date_active,   TRUNC(gd_online_sysdate)) >= TRUNC(gd_online_sysdate)
                AND    NVL(chu.start_date_active, TRUNC(gd_online_sysdate)) <= TRUNC(gd_online_sysdate)
                AND    NVL(chu.end_date_active,   TRUNC(gd_online_sysdate)) >= TRUNC(gd_online_sysdate)
                AND    NVL(syo.start_date_active, TRUNC(gd_online_sysdate)) <= TRUNC(gd_online_sysdate)
                AND    NVL(syo.end_date_active,   TRUNC(gd_online_sysdate)) >= TRUNC(gd_online_sysdate);
              ELSE
                l_month_square_rec.business_high_type   := NULL;
                l_month_square_rec.business_high_name   := cv_mc;
              END IF;
            EXCEPTION
              WHEN OTHERS THEN
                -- ���b�Z�[�W�o��
                lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                                ,iv_name         => cv_tkn_number_08         --���b�Z�[�W�R�[�h
                                ,iv_token_name1  => cv_tkn_table             --�g�[�N���R�[�h1
                                ,iv_token_value1 => '�Ƒԁi�����ށj�F'||l_cur_rec.business_low_type||
                                                    '����Q�ƃ^�C�v�Ƒԁi�啪�ށj'--�g�[�N���l1
                                ,iv_token_name2  => cv_tkn_errmsg            --�g�[�N���R�[�h�Q
                                ,iv_token_value2 => SQLERRM                  --�g�[�N���l�Q
                );
                fnd_file.put_line(
                      which  => FND_FILE.LOG,
                      buff   => ''      || cv_lf ||     -- ��s�̑}��
                              lv_errmsg || cv_lf || 
                               ''                         -- ��s�̑}��
                );
                l_month_square_rec.business_high_type   := NULL;
                l_month_square_rec.business_high_name   := cv_mc;
            END;
          END IF;
          -- ���t���擾
          ln_date := TO_NUMBER(SUBSTR(l_cur_rec.sales_date,7,2));
          -- DEBUG���b�Z�[�W
          -- ���������̏ꍇ
          debug(
             buff   => '���t:' || l_cur_rec.sales_date || cv_lf ||
                       '���t���̃i���o�[�^:'     || TO_CHAR(ln_date)
          );
          -- ����v��
          l_month_square_rec.l_one_day_tab(ln_date).tgt_amt          := l_cur_rec.tgt_amt;
          -- �������
          l_month_square_rec.l_one_day_tab(ln_date).rslt_amt         := l_cur_rec.rslt_amt;
          -- �������_�Q�������
          l_month_square_rec.l_one_day_tab(ln_date).rslt_center_amt  := l_cur_rec.rslt_center_amt;
          -- �K��v��
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_num      := l_cur_rec.tgt_vis_num;
          -- �K�����
          l_month_square_rec.l_one_day_tab(ln_date).vis_num          := l_cur_rec.vis_num;
          -- �L������
          l_month_square_rec.l_one_day_tab(ln_date).vis_sales_num    := l_cur_rec.vis_sales_num;
          -- �K����сi�V�K)
          l_month_square_rec.l_one_day_tab(ln_date).vis_new_num      := l_cur_rec.vis_new_num;
          -- �K����сiVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_vd_new_num   := l_cur_rec.vis_vd_new_num;
          -- �����K��L��
          l_month_square_rec.l_one_day_tab(ln_date).visit_sign       := SUBSTR(l_cur_rec.visit_sign, 1, 20);
          -- �K��A0Z����
          l_month_square_rec.l_one_day_tab(ln_date).vis_a_num := nvl(l_cur_rec.vis_a_num,0);  -- �K��A����
          l_month_square_rec.l_one_day_tab(ln_date).vis_b_num := nvl(l_cur_rec.vis_b_num,0);  -- �K��B����
          l_month_square_rec.l_one_day_tab(ln_date).vis_c_num := nvl(l_cur_rec.vis_c_num,0);  -- �K��C����
          l_month_square_rec.l_one_day_tab(ln_date).vis_d_num := nvl(l_cur_rec.vis_d_num,0);  -- �K��D����
          l_month_square_rec.l_one_day_tab(ln_date).vis_e_num := nvl(l_cur_rec.vis_e_num,0);  -- �K��E����
          l_month_square_rec.l_one_day_tab(ln_date).vis_f_num := nvl(l_cur_rec.vis_f_num,0);  -- �K��F����
          l_month_square_rec.l_one_day_tab(ln_date).vis_g_num := nvl(l_cur_rec.vis_g_num,0);  -- �K��G����
          l_month_square_rec.l_one_day_tab(ln_date).vis_h_num := nvl(l_cur_rec.vis_h_num,0);  -- �K��H����
          l_month_square_rec.l_one_day_tab(ln_date).vis_i_num := nvl(l_cur_rec.vis_i_num,0);  -- �K��I����
          l_month_square_rec.l_one_day_tab(ln_date).vis_j_num := nvl(l_cur_rec.vis_j_num,0);  -- �K��J����
          l_month_square_rec.l_one_day_tab(ln_date).vis_k_num := nvl(l_cur_rec.vis_k_num,0);  -- �K��K����
          l_month_square_rec.l_one_day_tab(ln_date).vis_l_num := nvl(l_cur_rec.vis_l_num,0);  -- �K��L����
          l_month_square_rec.l_one_day_tab(ln_date).vis_m_num := nvl(l_cur_rec.vis_m_num,0);  -- �K��M����
          l_month_square_rec.l_one_day_tab(ln_date).vis_n_num := nvl(l_cur_rec.vis_n_num,0);  -- �K��N����
          l_month_square_rec.l_one_day_tab(ln_date).vis_o_num := nvl(l_cur_rec.vis_o_num,0);  -- �K��O����
          l_month_square_rec.l_one_day_tab(ln_date).vis_p_num := nvl(l_cur_rec.vis_p_num,0);  -- �K��P����
          l_month_square_rec.l_one_day_tab(ln_date).vis_q_num := nvl(l_cur_rec.vis_q_num,0);  -- �K��Q����
          l_month_square_rec.l_one_day_tab(ln_date).vis_r_num := nvl(l_cur_rec.vis_r_num,0);  -- �K��R����
          l_month_square_rec.l_one_day_tab(ln_date).vis_s_num := nvl(l_cur_rec.vis_s_num,0);  -- �K��S����
          l_month_square_rec.l_one_day_tab(ln_date).vis_t_num := nvl(l_cur_rec.vis_t_num,0);  -- �K��T����
          l_month_square_rec.l_one_day_tab(ln_date).vis_u_num := nvl(l_cur_rec.vis_u_num,0);  -- �K��U����
          l_month_square_rec.l_one_day_tab(ln_date).vis_v_num := nvl(l_cur_rec.vis_v_num,0);  -- �K��V����
          l_month_square_rec.l_one_day_tab(ln_date).vis_w_num := nvl(l_cur_rec.vis_w_num,0);  -- �K��W����
          l_month_square_rec.l_one_day_tab(ln_date).vis_x_num := nvl(l_cur_rec.vis_x_num,0);  -- �K��X����
          l_month_square_rec.l_one_day_tab(ln_date).vis_y_num := nvl(l_cur_rec.vis_y_num,0);  -- �K��Y����
          l_month_square_rec.l_one_day_tab(ln_date).vis_z_num := nvl(l_cur_rec.vis_z_num,0);  -- �K��Z����
          -- �ŏ��̃��R�[�h�̏ꍇ
          IF(lb_boolean) THEN
            lb_boolean              := FALSE;                  -- ���������̃t���O���I�t����B
          END IF;
          -- ���o�����J�E���^�ɂP�𑫂��B
          ln_cnt         := ln_cnt + 1;
          gn_target_cnt  := ln_cnt;
          -- loop����
          debug(
                buff   => 'loop����' || TO_CHAR(ln_cnt)
          );
        END LOOP;
        -- �Ō�̃f�[�^�o�^
        IF (ln_cnt > 0) THEN
            debug(
                  buff   => '�Ō�̃f�[�^�̓o�^'
            );
          -- =================================================
          -- A-3-3.PLSQL�\�̍X�V
          -- =================================================
          up_plsql_tab1(
             i_month_square_rec   => l_month_square_rec          -- �ꃖ�����f�[�^
            ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
            ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
            ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
            ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          -- =================================================
          -- A-3-4,A-4-4,A-5-4,A-6-4,A-7-4.���[�N�e�[�u���֏o��
          -- =================================================
          insert_wrk_table(
             ir_m_tab            => l_get_month_square_tab                      -- ���ו����R�[�h
            ,ir_hon_tab          => l_get_month_square_hon_tab                  -- �{�̕����R�[�h
            ,in_m_cnt            => ln_m_cnt                                    -- ���ו��s��
            ,in_report_output_no => ln_report_output_no                         -- ���[�o�̓Z�b�g�ԍ�
            ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      EXCEPTION
        WHEN error_get_data_expt THEN
          RAISE global_api_expt;
        WHEN OTHERS THEN
          -- ���b�Z�[�W�o��
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_08         --���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_table             --�g�[�N���R�[�h1
                          ,iv_token_value1 => cv_tab_samari            --�g�[�N���l1
                          ,iv_token_name2  => cv_tkn_errmsg            --�g�[�N���R�[�h�Q
                          ,iv_token_value2 => SQLERRM                  --�g�[�N���l�Q
          );
          fnd_file.put_line(
                which  => FND_FILE.LOG,
                buff   => ''      || cv_lf ||     -- ��s�̑}��
                        lv_errmsg || cv_lf || 
                         ''                         -- ��s�̑}��
          );
          RAISE global_api_expt;
      END;
    -- �J�[�\���N���[�Y
    CLOSE ticket_data_cur;
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
  END get_ticket1;
--
  /**********************************************************************************
   * Procedure Name   : up_plsql_tab2
   * Description      : ���[���2-�c�ƈ��O���[�v��-PLSQL�\�̍X�V (A-4-3)
  ***********************************************************************************/
  PROCEDURE up_plsql_tab2(
     i_month_square_rec  IN         g_month_rtype2                     -- �ꃖ�����f�[�^
    ,in_m_cnt            IN         NUMBER                             -- ���ו��̃J�E���^
    ,io_m_tab            IN  OUT    NOCOPY    g_get_month_square_ttype           -- ���ו��z��
    ,io_hon_tab          IN  OUT    NOCOPY    g_get_month_square_ttype           -- �{�̕��z��
    ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'up_plsql_tab2';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ���[�J���ϐ�
    lv_gvm_type           VARCHAR2(1);                                       -- ��ʁ^���̋@�^�l�b
    ln_m_cnt              NUMBER(9);                                         -- IN�p�����[�^���i�[
    BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
      ln_m_cnt                            := in_m_cnt;                       -- IN�p�����[�^���i�[
      -- DEBUG���b�Z�[�W
      -- PL/SQL�\�̍X�V
      debug(
         buff   => '�c�ƃO���[�v��-PL/SQL�\�̍X�V����:' || TO_CHAR(ln_m_cnt)
      );
      
      BEGIN
        -- ����グ���ו�
        io_m_tab(ln_m_cnt).base_code        := i_month_square_rec.work_base_code; -- �Ɩ��n���_�R�[�h
        io_m_tab(ln_m_cnt).hub_name         := i_month_square_rec.base_name;     -- �Ɩ��n���_��  
        io_m_tab(in_m_cnt).group_number     := i_month_square_rec.group_number;  -- �c�ƃO���[�v�ԍ�
        io_m_tab(in_m_cnt).group_name       := i_month_square_rec.group_name;    -- �c�ƃO���[�v��
        io_m_tab(ln_m_cnt).employee_number  := i_month_square_rec.employee_number;-- �]�ƈ��ԍ�
        io_m_tab(ln_m_cnt).employee_name    := i_month_square_rec.name;          -- �]�ƈ���
        io_m_tab(in_m_cnt).last_year_rslt_sales_amt := i_month_square_rec.rslt_amty;   -- �O�N����
        io_m_tab(in_m_cnt).last_mon_rslt_sales_amt  := i_month_square_rec.rslt_amtm;   -- �挎����
        io_m_tab(in_m_cnt).new_customer_num := i_month_square_rec.cust_new_num;     -- �ڋq�����i�V�K�j
        io_m_tab(in_m_cnt).new_vendor_num   := i_month_square_rec.cust_vd_new_num;  -- �ڋq�����iVD�F�V�K�j
        io_m_tab(in_m_cnt).plan_sales_amt   := i_month_square_rec.tgt_sales_prsn_total_amt;  -- ���ʔ���\�Z
        -- DEBUG���b�Z�[�W
        -- PL/SQL�\�̍X�V
        debug(
           buff   => '�c�ƃO���[�v��-PL/SQL�\�̍X�V����' || '����グ���ו��Œ蕔����'
        );
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(
           which  => FND_FILE.LOG,
           buff   => '�c�ƃO���[�v��-PL/SQL�\�̍X�V�������s:' || SQLERRM 
         );
         RAISE global_api_others_expt;
      END;
      -- �{�̕�
      IF(ln_m_cnt = 1) THEN
        FOR i IN 1..cn_idx_max LOOP 
          IF (i = cn_idx_sales_ippn) THEN   --����グ���v��(���)
            io_hon_tab(i).gvm_type                 := cv_gvm_g;                              -- ���
          ELSIF(i=cn_idx_sales_vd) THEN      --����グ���v��(���̋@)
            io_hon_tab(i).gvm_type                 := cv_gvm_v;                              -- ���̋@
          ELSIF(i = cn_idx_sales_sum) THEN
            NULL;
          ELSIF(i=cn_idx_visit_ippn)THEN       --�K�⒆�v��
            io_hon_tab(i).gvm_type                 := cv_gvm_g;                              -- ���
          ELSIF(i=cn_idx_visit_vd)THEN       --�K�⒆�v��
            io_hon_tab(i).gvm_type                 := cv_gvm_v;                              -- ���̋@
          ELSIF(i=cn_idx_visit_mc)THEN       --�K�⒆�v��
            io_hon_tab(i).gvm_type                 := cv_gvm_m;                              -- MC
          END IF;
          io_hon_tab(i).base_code      :=i_month_square_rec.work_base_code;-- �Ɩ��n���_�R�[�h
          io_hon_tab(i).hub_name       :=i_month_square_rec.base_name;    -- �Ɩ��n���_��
          io_hon_tab(i).group_number   :=i_month_square_rec.group_number; -- �c�ƃO���[�v�ԍ�
          io_hon_tab(i).group_name     :=i_month_square_rec.group_name;   -- �c�ƃO���[�v��
        END LOOP;
      END IF;
--
      -- ���㒆�v��(���)
      io_hon_tab(cn_idx_sales_ippn).last_year_rslt_sales_amt := 
        io_hon_tab(cn_idx_sales_ippn).last_year_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_other_amty, 0);    -- �O�N����
      io_hon_tab(cn_idx_sales_ippn).last_mon_rslt_sales_amt  :=
        io_hon_tab(cn_idx_sales_ippn).last_mon_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_other_amtm, 0);    -- �挎����
      io_hon_tab(cn_idx_sales_ippn).new_customer_num :=
        io_hon_tab(cn_idx_sales_ippn).new_customer_num +
        NVL(i_month_square_rec.cust_other_new_num, 0); -- �ڋq�����i�V�K�j�i��ʁj
      -- ���㒆�v��(���̋@)
      io_hon_tab(cn_idx_sales_vd).last_year_rslt_sales_amt :=
        io_hon_tab(cn_idx_sales_vd).last_year_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_vd_amty, 0);       -- �O�N����
      io_hon_tab(cn_idx_sales_vd).last_mon_rslt_sales_amt :=
        io_hon_tab(cn_idx_sales_vd).last_mon_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_vd_amtm, 0);       -- �挎����
      io_hon_tab(cn_idx_sales_vd).new_customer_num :=
        io_hon_tab(cn_idx_sales_vd).new_customer_num +
        i_month_square_rec.cust_vd_new_num;            -- �ڋq�����i�V�K�j(���̋@)
--
      FOR i IN 1..31 LOOP
        BEGIN
          -- DEBUG���b�Z�[�W
          -- PL/SQL�\�̍X�V
          debug(
             buff   => '�c�ƃO���[�v��-PL/SQL�\�̍X�V����' || '1�������̃f�[�^�X�V'
          );
          -- ����グ���ו�
          io_m_tab(ln_m_cnt).l_get_one_day_tab(i).plan_vs_amt
            := i_month_square_rec.l_one_day_tab(i).tgt_amt;               -- ����グ�v��
          io_m_tab(ln_m_cnt).l_get_one_day_tab(i).rslt_vs_amt
            := i_month_square_rec.l_one_day_tab(i).rslt_amt;              -- ����グ����
          io_m_tab(ln_m_cnt).l_get_one_day_tab(i).rslt_other_sales_amt
            := i_month_square_rec.l_one_day_tab(i).rslt_center_amt;       -- �������_�Q�������
          -- ����グ���v��(���)
          io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).plan_vs_amt :=
            io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).plan_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).tgt_other_amt,0);     --����v��,�K��v��
          io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_other_amt,0);    -- �������,�K�����
          -- ����グ���v��(���̋@)
          io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).plan_vs_amt :=
            io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).plan_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).tgt_vd_amt,0);        --����v��,�K��v��
          io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_vd_amt,0);       -- �������,�K�����
          -- ����グ���v��
          -- �K�⒆�v��(���)
          io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).plan_vs_amt :=
            io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).plan_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).tgt_vis_other_num,0); --����v��,�K��v��
          io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_other_num,0);         -- �������,�K�����
          -- �K�⒆�v��(���̋@)
          io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).plan_vs_amt :=
            io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).plan_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).tgt_vis_vd_num,0);        --����v��,�K��v��
          io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_vd_num,0);            -- �������,�K�����
          -- �K�⒆�v��(MC)
          io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).plan_vs_amt :=
            io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).plan_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).tgt_vis_mc_num,0);        --����v��,�K��v��
          io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_mc_num,0);            -- �������,�K�����
          -- �K�⍇�v��
          io_hon_tab(cn_idx_visit_sum).l_get_one_day_tab(i).effective_num :=
            io_hon_tab(cn_idx_visit_sum).l_get_one_day_tab(i).effective_num + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_sales_num,0);         -- �L������
          -- �K����e���v��
          io_hon_tab(cn_idx_visit_dsc).vis_a_num := 
             io_hon_tab(cn_idx_visit_dsc).vis_a_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_a_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_b_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_b_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_b_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_c_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_c_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_c_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_d_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_d_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_d_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_e_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_e_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_e_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_f_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_f_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_f_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_g_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_g_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_g_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_h_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_h_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_h_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_i_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_i_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_i_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_j_num := 
             io_hon_tab(cn_idx_visit_dsc).vis_j_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_j_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_k_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_k_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_k_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_l_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_l_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_l_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_m_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_m_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_m_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_n_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_n_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_n_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_o_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_o_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_o_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_p_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_p_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_p_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_q_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_q_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_q_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_r_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_r_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_r_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_s_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_s_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_s_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_t_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_t_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_t_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_u_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_u_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_u_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_v_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_v_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_v_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_w_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_w_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_w_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_x_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_x_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_x_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_y_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_y_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_y_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_z_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_z_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_z_num,0);
        EXCEPTION
          WHEN OTHERS THEN
          fnd_file.put_line(
             which  => FND_FILE.LOG,
             buff   => '�c�ƃO���[�v��-PL/SQL�\-�{�̕��̍X�V�����ŃG���[�ɂȂ�܂����B' || SQLERRM ||
                      ''                         -- ��s�̑}��
           );
        END;
      END LOOP;
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
  END up_plsql_tab2;
--
  /**********************************************************************************
   * Procedure Name   : get_ticket2
   * Description      : ���[���2-�c�ƈ��O���[�v�� (A-4-1,A-4-2)
  ***********************************************************************************/
  PROCEDURE get_ticket2(
    ov_errbuf         OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W            --# �Œ� #
   ,ov_retcode        OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h              --# �Œ� #
   ,ov_errmsg         OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_ticket2';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ���[�J���萔
    -- ���[�J���ϐ�
    lb_boolean            BOOLEAN;      -- ���f�p
    ln_m_cnt              NUMBER(9);    -- ���ו��J�E���^�[���i�[
    ln_cnt                NUMBER(9);    -- ���o���ꂽ���R�[�h����
    ln_date               NUMBER(2);    -- ���t�̃i���o�[�^
    ln_report_output_no   NUMBER(9);    -- ���[�o�̓Z�b�g�ԍ�
    lv_bf_group_number    xxcso_resource_relations_v2.group_number_new%TYPE;
    lv_bf_employee_number xxcso_resource_relations_v2.employee_number%TYPE;
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR ticket_data_cur
    IS
      SELECT
              (CASE
                WHEN TO_DATE(xrrv.issue_date,'YYYYMMDD') <= gd_online_sysdate
                  THEN xrrv.work_base_code_new
                ELSE xrrv.work_base_code_old
              END 
              ) work_base_code,                         -- �Ζ��n���_�R�[�h
              (CASE
                WHEN TO_DATE(xrrv.issue_date,'YYYYMMDD') <= gd_online_sysdate
                  THEN xrrv.work_base_name_new
                ELSE xrrv.work_base_name_old
              END
              ) base_name,                              -- �Ζ��n���_��
              (CASE
                WHEN TO_DATE(xrrv.issue_date,'YYYYMMDD') <= gd_online_sysdate
                  THEN xrrv.group_number_new
                ELSE xrrv.group_number_old
              END 
              ) group_number,                                     -- �c�ƃO���[�v�ԍ�
              (xrrv.last_name || '�O���[�v') group_name,          -- �c�ƃO���[�v��
              xrrv.employee_number           employee_number,     -- �]�ƈ��ԍ�
              xrrv.full_name              name,                   -- �]�ƈ���
              xsvsr.sales_date            sales_date,             -- �̔��N����
              xsvsr.tgt_amt               tgt_amt,                -- ����v��
              xsvsr.tgt_new_amt           tgt_new_amt,            -- ����v��i�V�K�j
              xsvsr.tgt_vd_new_amt        tgt_vd_new_amt,         -- ����v��iVD�F�V�K�j
              xsvsr.tgt_vd_amt            tgt_vd_amt,             -- ����v��iVD�j
              xsvsr.tgt_other_new_amt     tgt_other_new_amt,      -- ����v��iVD�ȊO�F�V�K�j
              xsvsr.tgt_other_amt         tgt_other_amt,          -- ����v��iVD�ȊO�j
              xsvsr.rslt_amt              rslt_amt,               -- �������
              xsvsr.rslt_new_amt          rslt_new_amt,           -- ������сi�V�K�j
              xsvsr.rslt_vd_new_amt       rslt_vd_new_amt,        -- ������сiVD�F�V�K�j
              xsvsr.rslt_vd_amt           rslt_vd_amt,            -- ������сiVD�j
              xsvsr.rslt_other_new_amt    rslt_other_new_amt,     -- ������сiVD�ȊO�F�V�K�j
              xsvsr.rslt_other_amt        rslt_other_amt,         -- ������сiVD�ȊO�j
              xsvsr.rslt_center_amt       rslt_center_amt,        -- �������_�Q�������
              xsvsr.tgt_vis_num           tgt_vis_num,            -- �K��v��
              xsvsr.tgt_vis_new_num       tgt_vis_new_num,        -- �K��v��i�V�K�j
              xsvsr.tgt_vis_vd_new_num    tgt_vis_vd_new_num,     -- �K��v��iVD�F�V�K�j
              xsvsr.tgt_vis_vd_num        tgt_vis_vd_num,         -- �K��v��iVD�j
              xsvsr.tgt_vis_other_new_num tgt_vis_other_new_num,  -- �K��v��iVD�ȊO�F�V�K�j
              xsvsr.tgt_vis_other_num     tgt_vis_other_num,      -- �K��v��iVD�ȊO�j
              xsvsr.tgt_vis_mc_num        tgt_vis_mc_num,         -- �K��v��iMC�j
              xsvsr.vis_num               vis_num,                -- �K�����
              xsvsr.vis_new_num           vis_new_num,            -- �K����сi�V�K�j
              xsvsr.vis_vd_new_num        vis_vd_new_num,         -- �K����сiVD�F�V�K�j
              xsvsr.vis_vd_num            vis_vd_num,             -- �K����сiVD�j
              xsvsr.vis_other_new_num     vis_other_new_num,      -- �K����сiVD�ȊO�F�V�K�j
              xsvsr.vis_other_num         vis_other_num,          -- �K����сiVD�ȊO�j
              xsvsr.vis_mc_num            vis_mc_num,             -- �K����сiMC�j
              xsvsr.vis_sales_num         vis_sales_num,          -- �L������
              xsvsr.vis_a_num             vis_a_num,              -- �K��`����
              xsvsr.vis_b_num             vis_b_num,              -- �K��a����
              xsvsr.vis_c_num             vis_c_num,              -- �K��b����
              xsvsr.vis_d_num             vis_d_num,              -- �K��c����
              xsvsr.vis_e_num             vis_e_num,              -- �K��d����
              xsvsr.vis_f_num             vis_f_num,              -- �K��e����
              xsvsr.vis_g_num             vis_g_num,              -- �K��f����
              xsvsr.vis_h_num             vis_h_num,              -- �K��g����
              xsvsr.vis_i_num             vis_i_num,              -- �K���@����
              xsvsr.vis_j_num             vis_j_num,              -- �K��i����
              xsvsr.vis_k_num             vis_k_num,              -- �K��j����
              xsvsr.vis_l_num             vis_l_num,              -- �K��k����
              xsvsr.vis_m_num             vis_m_num,              -- �K��l����
              xsvsr.vis_n_num             vis_n_num,              -- �K��m����
              xsvsr.vis_o_num             vis_o_num,              -- �K��n����
              xsvsr.vis_p_num             vis_p_num,              -- �K��o����
              xsvsr.vis_q_num             vis_q_num,              -- �K��p����
              xsvsr.vis_r_num             vis_r_num,              -- �K��q����
              xsvsr.vis_s_num             vis_s_num,              -- �K��r����
              xsvsr.vis_t_num             vis_t_num,              -- �K��s����
              xsvsr.vis_u_num             vis_u_num,              -- �K��t����
              xsvsr.vis_v_num             vis_v_num,              -- �K��u����
              xsvsr.vis_w_num             vis_w_num,              -- �K��v����
              xsvsr.vis_x_num             vis_x_num,              -- �K��w����
              xsvsr.vis_y_num             vis_y_num,              -- �K��x����
              xsvsr.vis_z_num             vis_z_num,              -- �K��y����
              xsvsry.rslt_amt             rslt_amty,              -- �O�N����
              xsvsry.rslt_vd_amt          rslt_vd_amty,           -- �O�N���сiVD�j
              xsvsry.rslt_other_amt       rslt_other_amty,        -- �O�N���сiVD�ȊO�j
              xsvsrm.rslt_amt             rslt_amtm,              -- �挎����
              xsvsrm.rslt_vd_amt          rslt_vd_amtm,           -- �挎���сiVD�j
              xsvsrm.rslt_other_amt       rslt_other_amtm,        -- �挎���сiVD�ȊO�j
              xsvsrn.cust_new_num         cust_new_num,           -- �ڋq�����i�V�K�j
              xsvsrn.cust_vd_new_num      cust_vd_new_num,        -- �ڋq�����iVD�F�V�K�j
              xsvsrn.cust_other_new_num   cust_other_new_num,     -- �ڋq�����iVD�ȊO�F�V�K�j
              xsvsrn.tgt_sales_prsn_total_amt  tgt_sales_prsn_total_amt  -- ���ʔ���\�Z
      FROM    xxcso_resource_relations_v2 xrrv                    -- ���\�[�X�֘A�}�X�^(�ŐV)VIEW
             ,xxcso_sum_visit_sale_rep    xsvsr                   -- �K�┄��v��Ǘ��\�T�}���e�[�u��
             ,xxcso_sum_visit_sale_rep    xsvsry                  -- �K�┄��v��Ǘ��\�T�}���O�N
             ,xxcso_sum_visit_sale_rep    xsvsrm                  -- �K�┄��v��Ǘ��\�T�}���挎
             ,xxcso_sum_visit_sale_rep    xsvsrn                  -- �K�┄��v��Ǘ��\�T�}������
      WHERE  (CASE
                WHEN TO_DATE(xrrv.issue_date,'YYYYMMDD') <= gd_online_sysdate
                  THEN xrrv.work_base_code_new
                ELSE xrrv.work_base_code_old
              END 
              )  = gv_base_code
        AND   ( 
                ( gv_is_groupleader = cv_true
                  AND
                  ( CASE 
                      WHEN xrrv.issue_date IS NULL
                        THEN xrrv.group_number_new
                      WHEN xrrv.issue_date <= gv_online_sysdate
                        THEN xrrv.group_number_new
                      ELSE xrrv.group_number_old
                    END
                  ) = gt_group_number
                )
                OR
                ( gv_is_groupleader = cv_false
                  AND
                  1 = 1
                )
              )
        AND   xrrv.employee_number = xsvsr.sum_org_code
        AND   xsvsr.sum_org_type   = cv_sum_org_type2
        AND   xsvsr.month_date_div = cv_month_date_div2
        AND   xsvsr.sales_date
                BETWEEN TO_CHAR(gd_year_month_day,'YYYYMMDD') AND TO_CHAR(gd_year_month_lastday,'YYYYMMDD')
        AND   xsvsr.sum_org_type   = xsvsry.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsry.sum_org_code(+)
        AND   xsvsry.month_date_div(+)= cv_month_date_div1
        AND   xsvsry.sales_date(+) = gv_year_prev
        AND   xsvsr.sum_org_type   = xsvsrm.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsrm.sum_org_code(+)
        AND   xsvsrm.month_date_div(+)= cv_month_date_div1
        AND   xsvsrm.sales_date(+) = gv_year_month_prev
        AND   xsvsr.sum_org_type   = xsvsrn.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsrn.sum_org_code(+)
        AND   xsvsrn.month_date_div(+)= cv_month_date_div1
        AND   xsvsrn.sales_date(+) = gv_year_month
      ORDER BY  work_base_code     ASC,
                group_number       ASC,
                employee_number    ASC;
    -- ���[�J�����R�[�h
    l_cur_rec               ticket_data_cur%ROWTYPE;
    -- ���[�ϐ��i�[�p
    l_month_square_rec         g_month_rtype2;
    l_get_month_square_tab     g_get_month_square_ttype;
    l_get_month_square_hon_tab g_get_month_square_ttype;
    BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
      -- ���[�J���ϐ�������
      lb_boolean                := TRUE;        -- �����������f
      ln_m_cnt                  := 1;           -- ���ו��̍s��
      ln_report_output_no       := 1;           -- �z��s��
      ln_cnt                    := 0;           -- LOOP����
      -- PL/SQL�\�i�{�̕��j�̏�����
      init_month_square_hon_tab(l_get_month_square_hon_tab);
      -- ���[�J�����R�[�h�̏�����
      init_month_square_rec2(l_month_square_rec);
      BEGIN
        --�J�[�\���I�[�v��
        OPEN ticket_data_cur;
--
DO_ERROR('A-4-2-1');
        debug(
          buff   => 'ticket_data_cur�J�[�\���I�[�v��'
        );
--
        <<get_data_loop>>
        LOOP 
          l_cur_rec                           := NULL;          -- �J�[�\�����R�[�h�̏�����
--
          FETCH ticket_data_cur INTO l_cur_rec;                 -- �J�[�\���̃f�[�^�����R�[�h�Ɋi�[
--
DO_ERROR('A-4-2-2');
          debug(
            buff   => '�@�J�[�\��FETCH'
          );
--
          debug(
            buff   => l_cur_rec.work_base_code                    ||','||
                      l_cur_rec.base_name                         ||','||
                      l_cur_rec.group_number                      ||','||
                      l_cur_rec.group_name                        ||','||
                      l_cur_rec.employee_number                   ||','||
                      l_cur_rec.name                              ||','||
                      l_cur_rec.sales_date                        ||','||
                      TO_CHAR(l_cur_rec.tgt_amt)                  ||','||
                      TO_CHAR(l_cur_rec.tgt_new_amt)              ||','||
                      TO_CHAR(l_cur_rec.tgt_vd_new_amt)           ||','||
                      TO_CHAR(l_cur_rec.tgt_vd_amt)               ||','||
                      TO_CHAR(l_cur_rec.tgt_other_new_amt)        ||','||
                      TO_CHAR(l_cur_rec.tgt_other_amt)            ||','||
                      TO_CHAR(l_cur_rec.rslt_amt)                 ||','||
                      TO_CHAR(l_cur_rec.rslt_new_amt)             ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_new_amt)          ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_amt)              ||','||
                      TO_CHAR(l_cur_rec.rslt_other_new_amt)       ||','||
                      TO_CHAR(l_cur_rec.rslt_other_amt)           ||','||
                      TO_CHAR(l_cur_rec.rslt_center_amt)          ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_num)              ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_new_num)          ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_vd_new_num)       ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_vd_num)           ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_other_new_num)    ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_other_num)        ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_mc_num)           ||','||
                      TO_CHAR(l_cur_rec.vis_num)                  ||','||
                      TO_CHAR(l_cur_rec.vis_new_num)              ||','||
                      TO_CHAR(l_cur_rec.vis_vd_new_num)           ||','||
                      TO_CHAR(l_cur_rec.vis_vd_num)               ||','||
                      TO_CHAR(l_cur_rec.vis_other_new_num)        ||','||
                      TO_CHAR(l_cur_rec.vis_other_num)            ||','||
                      TO_CHAR(l_cur_rec.vis_mc_num)               ||','||
                      TO_CHAR(l_cur_rec.vis_sales_num)            ||','||
                      TO_CHAR(l_cur_rec.vis_a_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_b_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_c_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_d_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_e_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_f_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_g_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_h_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_i_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_j_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_k_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_l_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_m_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_n_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_o_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_p_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_q_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_r_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_s_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_t_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_u_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_v_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_w_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_x_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_y_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_z_num)                ||','||
                      TO_CHAR(l_cur_rec.rslt_amty)                ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_amty)             ||','||
                      TO_CHAR(l_cur_rec.rslt_other_amty)          ||','||
                      TO_CHAR(l_cur_rec.rslt_amtm)                ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_amtm)             ||','||
                      TO_CHAR(l_cur_rec.rslt_other_amtm)          ||','||
                      TO_CHAR(l_cur_rec.cust_new_num)             ||','||
                      TO_CHAR(l_cur_rec.cust_other_new_num)       ||','||
                      TO_CHAR(l_cur_rec.tgt_sales_prsn_total_amt) ||','||
                     cv_lf 
          );
          -- �Ώی�����O���̏ꍇ
          EXIT WHEN ticket_data_cur%NOTFOUND
            OR  ticket_data_cur%ROWCOUNT = 0;
--
          -- �O�񃌃R�[�h�Ɖc�ƃO���[�v�������ŉc�ƈ��ԍ����Ⴄ�ꍇ�A���ו��z��Ɩ{�̕��z����X�V�B
          IF(lb_boolean=FALSE) THEN
            IF((lv_bf_group_number = l_cur_rec.group_number)AND(lv_bf_employee_number <> l_cur_rec.employee_number))
              THEN
              -- DEBUG���b�Z�[�W
              debug(
                 buff   => '�]�ƈ��ԍ����Ⴂ�܂��B :' ||'�O��F '|| lv_bf_employee_number ||
                            '����F' || l_cur_rec.employee_number ||
                            '���ו��z��' || TO_CHAR(ln_m_cnt)
              );
              -- =================================================
              -- A-4-3.PLSQL�\�̍X�V
              -- =================================================
                up_plsql_tab2(
                   i_month_square_rec   => l_month_square_rec          -- �ꃖ�����f�[�^
                  ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
                  ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
                  ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
                  ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
                  ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
                  ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
                );
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
                l_month_square_rec.l_one_day_tab.DELETE;  -- ���[�J�����R�[�h�̃f�[�^�������B
                l_month_square_rec      := NULL;          -- ���[�J�����R�[�h�̃f�[�^�������B
                init_month_square_rec2(l_month_square_rec);
                ln_m_cnt          := ln_m_cnt + 1;       -- ���ו��z����{�P����B
                lb_boolean        := TRUE;               -- ���������̃t���O�I������B
            ELSIF(lv_bf_group_number <> l_cur_rec.group_number)THEN
              -- =================================================
              -- A-4-3.PLSQL�\�̍X�V
              -- =================================================
              up_plsql_tab2(
                 i_month_square_rec   => l_month_square_rec          -- �ꃖ�����f�[�^
                ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
                ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
                ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
                ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
                ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
                ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
              l_month_square_rec.l_one_day_tab.DELETE;  -- ���[�J�����R�[�h�̃f�[�^�������B
              l_month_square_rec      := NULL;          -- ���[�J�����R�[�h�̃f�[�^�������B
              init_month_square_rec2(l_month_square_rec);
              lb_boolean        := TRUE;               -- ���������̃t���O�I������B
            END IF;
          END IF;
          -- �c�ƃO���[�v�ԍ����O��擾�����c�ƃO���[�v�ԍ��ƈႤ�ꍇ���[�N�e�[�u���ɏo�͂��܂��B
          IF ((ln_cnt > 0) AND
              (lv_bf_group_number <> l_cur_rec.group_number)) THEN
            debug(
               buff   => '�c�ƈ��O���[�v�ԍ����Ⴂ�܂��B :' ||'�O��F '|| lv_bf_group_number || ''||
                          '����F' || l_cur_rec.group_number
            );
            -- =================================================
            -- A-3-4,A-4-4,A-5-4,A-6-4,A-7-4.���[�N�e�[�u���֏o��
            -- =================================================
            insert_wrk_table(
               ir_m_tab            => l_get_month_square_tab                      -- ���ו����R�[�h
              ,ir_hon_tab          => l_get_month_square_hon_tab                  -- �{�̕����R�[�h
              ,in_m_cnt            => ln_m_cnt                                    -- ���ו��s��
              ,in_report_output_no => ln_report_output_no                         -- ���[�o�̓Z�b�g�ԍ�
              ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
              ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
              ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
            );
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
            -- ���R�[�h�̏�����
            l_get_month_square_tab.DELETE;
            l_get_month_square_hon_tab.DELETE;
            init_month_square_hon_tab(l_get_month_square_hon_tab);
            ln_m_cnt            := 1;                       -- ���ו��z��̍s���̏�����
            ln_report_output_no := ln_report_output_no + 1; -- �o�͂��ꂽ���[���Ɂ{�P����
            lb_boolean          := TRUE;                    -- ���������̏�Ԃɖ߂�
          END IF;
          -- ���������̏ꍇ
          IF(lb_boolean) THEN
            -- �c�ƈ��ԍ��Ɖc�ƈ��O���[�v�ԍ������[�J���ϐ��Ɋi�[
            lv_bf_group_number         := l_cur_rec.group_number;          -- �c�ƃO���[�v�ԍ�
            lv_bf_employee_number      := l_cur_rec.employee_number;       -- �]�ƈ��ԍ�
            -- ���[�J�����R�[�h�Ɋi�[
            -- �Ζ��n���_�R�[�h
            l_month_square_rec.work_base_code     := l_cur_rec.work_base_code;
            -- �Ζ��n���_��
            l_month_square_rec.base_name          := l_cur_rec.base_name;
            -- �c�ƃO���[�v�ԍ�
            l_month_square_rec.group_number       := l_cur_rec.group_number;
            -- �c�ƃO���[�v��
            l_month_square_rec.group_name         := l_cur_rec.group_name;
            -- �]�ƈ��ԍ�
            l_month_square_rec.employee_number    := l_cur_rec.employee_number;
            -- �]�ƈ���
            l_month_square_rec.name               := l_cur_rec.name;
            -- �V�K�ڋq����
            l_month_square_rec.cust_new_num    := l_cur_rec.cust_new_num;
            -- �V�KVD����
            l_month_square_rec.cust_vd_new_num    := l_cur_rec.cust_vd_new_num;
            -- �V�KVD�ȊO����
            l_month_square_rec.cust_other_new_num := l_cur_rec.cust_other_new_num;
            -- �O�N����
            l_month_square_rec.rslt_amty          := l_cur_rec.rslt_amty;
            -- �O�N���сiVD�j
            l_month_square_rec.rslt_vd_amty       := l_cur_rec.rslt_vd_amty;
            -- �O�N���сiVD�ȊO�j
            l_month_square_rec.rslt_other_amty    := l_cur_rec.rslt_other_amty;
            -- �挎����
            l_month_square_rec.rslt_amtm          := l_cur_rec.rslt_amtm;
            -- �挎���сiVD�j
            l_month_square_rec.rslt_vd_amtm       := l_cur_rec.rslt_vd_amtm;
            -- �挎���сiVD�ȊO�j
            l_month_square_rec.rslt_other_amtm    := l_cur_rec.rslt_other_amtm;
            -- ���ʔ���\�Z
            l_month_square_rec.tgt_sales_prsn_total_amt := l_cur_rec.tgt_sales_prsn_total_amt;
            lb_boolean := FALSE;                  -- ���������̃t���O���I�t����B
            -- DEBUG���b�Z�[�W
            -- ���������̏ꍇ
            debug(
               buff   => '���������t���O:' || 'FALSE'
            );
          END IF;
          -- ���t���擾
          ln_date := TO_NUMBER(SUBSTR(l_cur_rec.sales_date,7,2));
          -- DEBUG���b�Z�[�W
          -- ���������̏ꍇ
          debug(
             buff   => '���t:' || l_cur_rec.sales_date || cv_lf ||
                       '���t���̃i���o�[�^:'     || TO_CHAR(ln_date)
          );
          l_month_square_rec.l_one_day_tab(ln_date).tgt_amt               
            := l_cur_rec.tgt_amt;              -- ����v��
          l_month_square_rec.l_one_day_tab(ln_date).tgt_new_amt           
            := l_cur_rec.tgt_new_amt;          -- ����v��i�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vd_new_amt        
            := l_cur_rec.tgt_vd_new_amt;       -- ����v��iVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vd_amt            
            := l_cur_rec.tgt_vd_amt;           -- ����v��iVD�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_other_new_amt     
            := l_cur_rec.tgt_other_new_amt;    -- ����v��iVD�ȊO�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_other_amt         
            := l_cur_rec.tgt_other_amt;        -- ����v��iVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_amt              
            := l_cur_rec.rslt_amt;             -- �������
          l_month_square_rec.l_one_day_tab(ln_date).rslt_new_amt          
            := l_cur_rec.rslt_new_amt;         -- ������сi�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_vd_new_amt       
            := l_cur_rec.rslt_vd_new_amt;      -- ������сiVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_vd_amt           
            := l_cur_rec.rslt_vd_amt;          -- ������сiVD�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_other_new_amt    
            := l_cur_rec.rslt_other_new_amt;   -- ������сiVD�ȊO�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_other_amt        
            := l_cur_rec.rslt_other_amt;       -- ������сiVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_center_amt       
            := l_cur_rec.rslt_center_amt;      -- �������_�Q�������
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_num           
            := l_cur_rec.tgt_vis_num;          -- �K��v��
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_new_num       
            := l_cur_rec.tgt_vis_new_num;      -- �K��v��i�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_vd_new_num    
            := l_cur_rec.tgt_vis_vd_new_num;   -- �K��v��iVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_vd_num        
            := l_cur_rec.tgt_vis_vd_num;       -- �K��v��iVD�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_other_new_num 
            := l_cur_rec.tgt_vis_other_new_num;-- �K��v��iVD�ȊO�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_other_num     
            := l_cur_rec.tgt_vis_other_num;    -- �K��v��iVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_mc_num     
            := l_cur_rec.tgt_vis_mc_num;        -- �K��v��iMC�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_num               
            := l_cur_rec.vis_num;               -- �K�����
          l_month_square_rec.l_one_day_tab(ln_date).vis_new_num           
            := l_cur_rec.vis_new_num;           -- �K����сi�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_vd_new_num        
            := l_cur_rec.vis_vd_new_num;        -- �K����сiVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_vd_num            
            := l_cur_rec.vis_vd_num;            -- �K����сiVD�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_other_new_num     
            := l_cur_rec.vis_other_new_num;     -- �K����сiVD�ȊO�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_other_num         
            := l_cur_rec.vis_other_num;         -- �K����сiVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_mc_num         
            := l_cur_rec.vis_mc_num;            -- �K����сiMC�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_sales_num         
            := l_cur_rec.vis_sales_num;         -- �L������
          -- A0Z�K�⌏��
          l_month_square_rec.l_one_day_tab(ln_date).vis_a_num := nvl(l_cur_rec.vis_a_num,0);  -- �K��A����
          l_month_square_rec.l_one_day_tab(ln_date).vis_b_num := nvl(l_cur_rec.vis_b_num,0);  -- �K��B����
          l_month_square_rec.l_one_day_tab(ln_date).vis_c_num := nvl(l_cur_rec.vis_c_num,0);  -- �K��C����
          l_month_square_rec.l_one_day_tab(ln_date).vis_d_num := nvl(l_cur_rec.vis_d_num,0);  -- �K��D����
          l_month_square_rec.l_one_day_tab(ln_date).vis_e_num := nvl(l_cur_rec.vis_e_num,0);  -- �K��E����
          l_month_square_rec.l_one_day_tab(ln_date).vis_f_num := nvl(l_cur_rec.vis_f_num,0);  -- �K��F����
          l_month_square_rec.l_one_day_tab(ln_date).vis_g_num := nvl(l_cur_rec.vis_g_num,0);  -- �K��G����
          l_month_square_rec.l_one_day_tab(ln_date).vis_h_num := nvl(l_cur_rec.vis_h_num,0);  -- �K��H����
          l_month_square_rec.l_one_day_tab(ln_date).vis_i_num := nvl(l_cur_rec.vis_i_num,0);  -- �K��I����
          l_month_square_rec.l_one_day_tab(ln_date).vis_j_num := nvl(l_cur_rec.vis_j_num,0);  -- �K��J����
          l_month_square_rec.l_one_day_tab(ln_date).vis_k_num := nvl(l_cur_rec.vis_k_num,0);  -- �K��K����
          l_month_square_rec.l_one_day_tab(ln_date).vis_l_num := nvl(l_cur_rec.vis_l_num,0);  -- �K��L����
          l_month_square_rec.l_one_day_tab(ln_date).vis_m_num := nvl(l_cur_rec.vis_m_num,0);  -- �K��M����
          l_month_square_rec.l_one_day_tab(ln_date).vis_n_num := nvl(l_cur_rec.vis_n_num,0);  -- �K��N����
          l_month_square_rec.l_one_day_tab(ln_date).vis_o_num := nvl(l_cur_rec.vis_o_num,0);  -- �K��O����
          l_month_square_rec.l_one_day_tab(ln_date).vis_p_num := nvl(l_cur_rec.vis_p_num,0);  -- �K��P����
          l_month_square_rec.l_one_day_tab(ln_date).vis_q_num := nvl(l_cur_rec.vis_q_num,0);  -- �K��Q����
          l_month_square_rec.l_one_day_tab(ln_date).vis_r_num := nvl(l_cur_rec.vis_r_num,0);  -- �K��R����
          l_month_square_rec.l_one_day_tab(ln_date).vis_s_num := nvl(l_cur_rec.vis_s_num,0);  -- �K��S����
          l_month_square_rec.l_one_day_tab(ln_date).vis_t_num := nvl(l_cur_rec.vis_t_num,0);  -- �K��T����
          l_month_square_rec.l_one_day_tab(ln_date).vis_u_num := nvl(l_cur_rec.vis_u_num,0);  -- �K��U����
          l_month_square_rec.l_one_day_tab(ln_date).vis_v_num := nvl(l_cur_rec.vis_v_num,0);  -- �K��V����
          l_month_square_rec.l_one_day_tab(ln_date).vis_w_num := nvl(l_cur_rec.vis_w_num,0);  -- �K��W����
          l_month_square_rec.l_one_day_tab(ln_date).vis_x_num := nvl(l_cur_rec.vis_x_num,0);  -- �K��X����
          l_month_square_rec.l_one_day_tab(ln_date).vis_y_num := nvl(l_cur_rec.vis_y_num,0);  -- �K��Y����
          l_month_square_rec.l_one_day_tab(ln_date).vis_z_num := nvl(l_cur_rec.vis_z_num,0);  -- �K��Z����
          -- �ŏ��̃��R�[�h�̏ꍇ
          IF(lb_boolean) THEN
            lb_boolean              := FALSE;                  -- ���������̃t���O���I�t����B
          END IF;
          -- ���o�����J�E���^�ɂP�𑫂��B
          ln_cnt := ln_cnt + 1;
          gn_target_cnt  := ln_cnt;
          -- loop����
          debug(
                buff   => 'loop����' || TO_CHAR(ln_cnt)
          );
        END LOOP;
        -- �Ō�̃f�[�^�o�^
        IF (ln_cnt > 0) THEN
            debug(
                  buff   => '�Ō�̃f�[�^�̓o�^'
            );
        -- =================================================
        -- A-4-3.PLSQL�\�̍X�V
        -- =================================================
        up_plsql_tab2(
          i_month_square_rec   => l_month_square_rec          -- �ꃖ�����f�[�^
         ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
         ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
         ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
         ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
         ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
         ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        -- =================================================
        -- A-3-4,A-4-4,A-5-4,A-6-4,A-7-4.���[�N�e�[�u���֏o��
        -- =================================================
        insert_wrk_table(
           ir_m_tab            => l_get_month_square_tab                      -- ���ו����R�[�h
          ,ir_hon_tab          => l_get_month_square_hon_tab                  -- �{�̕����R�[�h
          ,in_m_cnt            => ln_m_cnt                                    -- ���ו��s��
          ,in_report_output_no => ln_report_output_no                         -- ���[�o�̓Z�b�g�ԍ�                      
          ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
        END IF;
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          -- ���b�Z�[�W�o��
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_08         --���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_table             --�g�[�N���R�[�h1
                          ,iv_token_value1 => cv_tab_samari            --�g�[�N���l1
                          ,iv_token_name2  => cv_tkn_errmsg            --�g�[�N���R�[�h�Q
                          ,iv_token_value2 => SQLERRM                  --�g�[�N���l�Q
          );
          fnd_file.put_line(
                which  => FND_FILE.LOG,
                buff   => ''      || cv_lf ||     -- ��s�̑}��
                        lv_errmsg || cv_lf || 
                         ''                         -- ��s�̑}��
          );
          RAISE global_api_expt;
      END;
    -- �J�[�\���N���[�Y
    CLOSE ticket_data_cur;
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
  END get_ticket2;
--
  /**********************************************************************************
   * Procedure Name   : up_plsql_tab3
   * Description      : ���[���3-���_/�ە�-PLSQL�\�̍X�V (A-5-3)
  ***********************************************************************************/
  PROCEDURE up_plsql_tab3(
     i_month_square_rec  IN         g_month_rtype3                     -- 1�������f�[�^
    ,in_m_cnt            IN         NUMBER                             -- ���ו��̃J�E���^
    ,io_m_tab            IN OUT NOCOPY    g_get_month_square_ttype           -- ���ו��z��
    ,io_hon_tab          IN OUT NOCOPY    g_get_month_square_ttype           -- �{�̕��z��
    ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'up_plsql_tab3';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ���[�J���ϐ�
    lv_gvm_type           VARCHAR2(1);                                       -- ��ʁ^���̋@�^�l�b
    ln_m_cnt              NUMBER(9);                                         -- IN�p�����[�^���i�[
    BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
      ln_m_cnt                            := in_m_cnt;                       -- IN�p�����[�^���i�[
      -- DEBUG���b�Z�[�W
      -- PL/SQL�\�̍X�V
      debug(
         buff   => '���_/�ە�-PL/SQL�\�̍X�V����:' || TO_CHAR(ln_m_cnt)
      );
      BEGIN
        -- ����グ���ו�
        io_m_tab(ln_m_cnt).base_code        := i_month_square_rec.work_base_code;    -- �Ɩ��n���_�R�[�h
        io_m_tab(ln_m_cnt).hub_name         := i_month_square_rec.base_name;         -- �Ɩ��n���_��  
        io_m_tab(in_m_cnt).group_number     := i_month_square_rec.group_number;      -- �c�ƃO���[�v�ԍ�
        io_m_tab(in_m_cnt).group_name       := i_month_square_rec.group_name;        -- �c�ƃO���[�v��
        io_m_tab(in_m_cnt).last_year_rslt_sales_amt := i_month_square_rec.rslt_amty; -- �O�N����
        io_m_tab(in_m_cnt).last_mon_rslt_sales_amt  := i_month_square_rec.rslt_amtm; -- �挎����
        io_m_tab(in_m_cnt).new_customer_num := i_month_square_rec.cust_new_num;      -- �ڋq����
        io_m_tab(in_m_cnt).new_vendor_num   := i_month_square_rec.cust_vd_new_num;   -- �ڋq�����iVD �V�K�j
        io_m_tab(in_m_cnt).plan_sales_amt   := i_month_square_rec.tgt_sales_prsn_total_amt;  -- ���ʔ���\�Z
        -- DEBUG���b�Z�[�W
        -- PL/SQL�\�̍X�V6u
        debug(
           buff   => '���_/�ە�-PL/SQL�\�̍X�V����' || '����グ���ו��Œ蕔����'
        );
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(
           which  => FND_FILE.LOG,
           buff   => '���_/�ە�-PL/SQL�\�̍X�V�������s:' || SQLERRM 
         );
         RAISE global_api_others_expt;
      END;
      -- �{�̕�
      IF(ln_m_cnt = 1) THEN
        FOR i IN 1..cn_idx_max LOOP 
          IF(i = cn_idx_sales_ippn) THEN         --����グ���v��(���)
            io_hon_tab(i).gvm_type                 := cv_gvm_g;                              -- ���
          ELSIF(i = cn_idx_sales_vd) THEN      --����グ���v��(���̋@)
            io_hon_tab(i).gvm_type                 := cv_gvm_v;                              -- ���̋@
          ELSIF(i = cn_idx_sales_sum) THEN      -- ����グ���v��
            NULL;
          ELSIF(i=cn_idx_visit_ippn)THEN       --�K�⒆�v��
            io_hon_tab(i).gvm_type                 := cv_gvm_g;                              -- ���
          ELSIF(i=cn_idx_visit_vd)THEN       --�K�⒆�v��
            io_hon_tab(i).gvm_type                 := cv_gvm_v;                              -- ���̋@
          ELSIF(i=cn_idx_visit_mc)THEN       --�K�⒆�v��
            io_hon_tab(i).gvm_type                 := cv_gvm_m;                              -- MC
          END IF;
          io_hon_tab(i).base_code        := i_month_square_rec.work_base_code;  -- �Ɩ��n���_�R�[�h
          io_hon_tab(i).hub_name         := i_month_square_rec.base_name;       -- �Ɩ��n���_��  
        END LOOP;
      END IF;
--
      -- ���㒆�v��(���)
      io_hon_tab(cn_idx_sales_ippn).last_year_rslt_sales_amt := 
        io_hon_tab(cn_idx_sales_ippn).last_year_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_other_amty, 0);    -- �O�N����
      io_hon_tab(cn_idx_sales_ippn).last_mon_rslt_sales_amt  :=
        io_hon_tab(cn_idx_sales_ippn).last_mon_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_other_amtm, 0);    -- �挎����
      io_hon_tab(cn_idx_sales_ippn).new_customer_num :=
        io_hon_tab(cn_idx_sales_ippn).new_customer_num +
        NVL(i_month_square_rec.cust_other_new_num, 0); -- �ڋq�����i�V�K�j�i��ʁj
      -- ���㒆�v��(���̋@)
      io_hon_tab(cn_idx_sales_vd).last_year_rslt_sales_amt :=
        io_hon_tab(cn_idx_sales_vd).last_year_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_vd_amty, 0);       -- �O�N����
      io_hon_tab(cn_idx_sales_vd).last_mon_rslt_sales_amt :=
        io_hon_tab(cn_idx_sales_vd).last_mon_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_vd_amtm, 0);       -- �挎����
      io_hon_tab(cn_idx_sales_vd).new_customer_num :=
        io_hon_tab(cn_idx_sales_vd).new_customer_num +
        i_month_square_rec.cust_vd_new_num;            -- �ڋq�����i�V�K�j(���̋@)
--
      FOR i IN 1..31 LOOP
        BEGIN
          -- DEBUG���b�Z�[�W
            -- PL/SQL�\�̍X�V
            debug(
               buff   => '���_/�ە�-PL/SQL�\�̍X�V����' || '1�������̃f�[�^�X�V'
            );
          -- ����グ���ו�
          io_m_tab(in_m_cnt).l_get_one_day_tab(i).plan_vs_amt
            := i_month_square_rec.l_one_day_tab(i).tgt_amt;                   -- ����グ�v��
          io_m_tab(in_m_cnt).l_get_one_day_tab(i).rslt_vs_amt
            := i_month_square_rec.l_one_day_tab(i).rslt_amt;                  -- ����グ����
          io_m_tab(in_m_cnt).l_get_one_day_tab(i).rslt_other_sales_amt
            := i_month_square_rec.l_one_day_tab(i).rslt_center_amt;           -- �������_�Q�������
          -- ����グ���v��(���)
          io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).plan_vs_amt :=
            io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).plan_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).tgt_other_amt,0);         --����v��,�K��v��
          io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_other_amt,0);        -- �������,�K�����
          io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_other_sales_amt :=
            io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_other_sales_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_center_other_amt,0); -- �������_�Q�������
          -- ����グ���v��(���̋@)
          io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).plan_vs_amt :=
            io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).plan_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).tgt_vd_amt,0);            --����v��,�K��v��
          io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_vd_amt,0);           -- �������,�K�����
          io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_other_sales_amt :=
            io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_other_sales_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_center_vd_amt,0);    -- �������_�Q�������
          -- ����グ���v��
          -- �K�⒆�v��(���)
          io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).plan_vs_amt :=
            io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).plan_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).tgt_vis_other_num,0);     --����v��,�K��v��
          io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_other_num,0);         -- �������,�K�����
          -- �K�⒆�v��(���̋@)
          io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).plan_vs_amt :=
            io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).plan_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).tgt_vis_vd_num,0);        --����v��,�K��v��
          io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_vd_num,0);            -- �������,�K�����
          -- �K�⒆�v��(MC)
          io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).plan_vs_amt :=
            io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).plan_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).tgt_vis_mc_num,0);        --����v��,�K��v��
          io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_mc_num,0);            -- �������,�K�����
          -- �K�⍇�v��
          io_hon_tab(cn_idx_visit_sum).l_get_one_day_tab(i).effective_num :=
            io_hon_tab(cn_idx_visit_sum).l_get_one_day_tab(i).effective_num + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_sales_num,0);         -- �L������
          -- �K����e���v��
          io_hon_tab(cn_idx_visit_dsc).vis_a_num := 
             io_hon_tab(cn_idx_visit_dsc).vis_a_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_a_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_b_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_b_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_b_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_c_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_c_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_c_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_d_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_d_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_d_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_e_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_e_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_e_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_f_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_f_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_f_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_g_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_g_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_g_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_h_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_h_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_h_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_i_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_i_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_i_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_j_num := 
             io_hon_tab(cn_idx_visit_dsc).vis_j_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_j_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_k_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_k_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_k_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_l_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_l_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_l_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_m_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_m_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_m_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_n_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_n_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_n_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_o_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_o_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_o_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_p_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_p_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_p_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_q_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_q_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_q_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_r_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_r_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_r_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_s_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_s_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_s_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_t_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_t_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_t_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_u_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_u_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_u_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_v_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_v_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_v_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_w_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_w_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_w_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_x_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_x_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_x_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_y_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_y_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_y_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_z_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_z_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_z_num,0);
        EXCEPTION
          WHEN OTHERS THEN
          fnd_file.put_line(
             which  => FND_FILE.LOG,
             buff   => '���_/�ە�-PL/SQL�\-�{�̕��̍X�V�����ŃG���[�ɂȂ�܂����B' || SQLERRM ||
                      ''                         -- ��s�̑}��
           );
        END;
      END LOOP;
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
  END up_plsql_tab3;
--
  /**********************************************************************************
   * Procedure Name   : get_ticket3
   * Description      : ���[���3-���_/�ە� (A-5-1,A-5-2)
  ***********************************************************************************/
  PROCEDURE get_ticket3(
     ov_errbuf         OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_ticket3';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ���[�J���萔
    -- ���[�J���ϐ�
    lb_boolean            BOOLEAN;      -- ���f�p
    ln_m_cnt              NUMBER(9);    -- ���ו��J�E���^�[���i�[
    ln_cnt                NUMBER(9);    -- ���o���ꂽ���R�[�h����
    ln_date               NUMBER(2);    -- ���t�̃i���o�[�^
    ln_report_output_no   NUMBER(9);    -- ���[�o�̓Z�b�g�ԍ�
    lv_bf_group_number    xxcso_resource_relations_v2.group_number_new%TYPE;
    lv_bf_work_base_code  xxcso_resource_relations_v2.work_base_code_new%TYPE;
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR ticket_data_cur
    IS
      SELECT
              gnv.gnv_work_base_code      work_base_code,         -- �Ζ��n���_�R�[�h
              xabv.base_name              base_name,              -- �Ζ��n���_��
              gnv.gnv_group_number        group_number,           -- �c�ƃO���[�v�ԍ�
              (SELECT
                 (last_name || '�O���[�v')       
               FROM
                 xxcso_resource_relations_v2
               WHERE
                    (CASE
                       WHEN TO_DATE(issue_date,'YYYYMMDD') <= gd_online_sysdate
                         THEN work_base_code_new
                       ELSE work_base_code_old
                    END 
                    ) = gnv.gnv_work_base_code
               AND  (CASE
                       WHEN TO_DATE(issue_date,'YYYYMMDD') <= gd_online_sysdate
                         THEN group_number_new
                       ELSE group_number_old
                    END 
                    ) = gnv.gnv_group_number
               AND  (CASE
                       WHEN TO_DATE(issue_date,'YYYYMMDD') <= gd_online_sysdate
                         THEN group_leader_flag_new
                       ELSE group_leader_flag_old
                    END 
                    ) = cv_flg_y
               AND  ROWNUM = 1
              )     group_name,                                   -- �O���[�v��
              xsvsr.sales_date            sales_date,             -- �̔��N����
              xsvsr.tgt_amt               tgt_amt,                -- ����v��
              xsvsr.tgt_new_amt           tgt_new_amt,            -- ����v��i�V�K�j
              xsvsr.tgt_vd_new_amt        tgt_vd_new_amt,         -- ����v��iVD�F�V�K�j
              xsvsr.tgt_vd_amt            tgt_vd_amt,             -- ����v��iVD�j
              xsvsr.tgt_other_new_amt     tgt_other_new_amt,      -- ����v��iVD�ȊO�F�V�K�j
              xsvsr.tgt_other_amt         tgt_other_amt,          -- ����v��iVD�ȊO�j
              xsvsr.rslt_amt              rslt_amt,               -- �������
              xsvsr.rslt_new_amt          rslt_new_amt,           -- ������сi�V�K�j
              xsvsr.rslt_vd_new_amt       rslt_vd_new_amt,        -- ������сiVD�F�V�K�j
              xsvsr.rslt_vd_amt           rslt_vd_amt,            -- ������сiVD�j
              xsvsr.rslt_other_new_amt    rslt_other_new_amt,     -- ������сiVD�ȊO�F�V�K�j
              xsvsr.rslt_other_amt        rslt_other_amt,         -- ������сiVD�ȊO�j
              xsvsr.rslt_center_amt       rslt_center_amt,        -- �������_�Q�������
              xsvsr.rslt_center_vd_amt    rslt_center_vd_amt,     -- �������_�Q������сiVD�j
              xsvsr.rslt_center_other_amt rslt_center_other_amt,  -- �������_�Q������сiVD�ȊO�j
              xsvsr.tgt_vis_num           tgt_vis_num,            -- �K��v��
              xsvsr.tgt_vis_new_num       tgt_vis_new_num,        -- �K��v��i�V�K�j
              xsvsr.tgt_vis_vd_new_num    tgt_vis_vd_new_num,     -- �K��v��iVD�F�V�K�j
              xsvsr.tgt_vis_vd_num        tgt_vis_vd_num,         -- �K��v��iVD�j
              xsvsr.tgt_vis_other_new_num tgt_vis_other_new_num,  -- �K��v��iVD�ȊO�F�V�K�j
              xsvsr.tgt_vis_other_num     tgt_vis_other_num,      -- �K��v��iVD�ȊO�j
              xsvsr.tgt_vis_mc_num        tgt_vis_mc_num,         -- �K��v��iMC�j
              xsvsr.vis_num               vis_num,                -- �K�����
              xsvsr.vis_new_num           vis_new_num,            -- �K����сi�V�K�j
              xsvsr.vis_vd_new_num        vis_vd_new_num,         -- �K����сiVD�F�V�K�j
              xsvsr.vis_vd_num            vis_vd_num,             -- �K����сiVD�j
              xsvsr.vis_other_new_num     vis_other_new_num,      -- �K����сiVD�ȊO�F�V�K�j
              xsvsr.vis_other_num         vis_other_num,          -- �K����сiVD�ȊO�j
              xsvsr.vis_mc_num            vis_mc_num,             -- �K����сiMC�j
              xsvsr.vis_sales_num         vis_sales_num,          -- �L������
              xsvsr.vis_a_num             vis_a_num,              -- �K��`����
              xsvsr.vis_b_num             vis_b_num,              -- �K��a����
              xsvsr.vis_c_num             vis_c_num,              -- �K��b����
              xsvsr.vis_d_num             vis_d_num,              -- �K��c����
              xsvsr.vis_e_num             vis_e_num,              -- �K��d����
              xsvsr.vis_f_num             vis_f_num,              -- �K��e����
              xsvsr.vis_g_num             vis_g_num,              -- �K��f����
              xsvsr.vis_h_num             vis_h_num,              -- �K��g����
              xsvsr.vis_i_num             vis_i_num,              -- �K���@����
              xsvsr.vis_j_num             vis_j_num,              -- �K��i����
              xsvsr.vis_k_num             vis_k_num,              -- �K��j����
              xsvsr.vis_l_num             vis_l_num,              -- �K��k����
              xsvsr.vis_m_num             vis_m_num,              -- �K��l����
              xsvsr.vis_n_num             vis_n_num,              -- �K��m����
              xsvsr.vis_o_num             vis_o_num,              -- �K��n����
              xsvsr.vis_p_num             vis_p_num,              -- �K��o����
              xsvsr.vis_q_num             vis_q_num,              -- �K��p����
              xsvsr.vis_r_num             vis_r_num,              -- �K��q����
              xsvsr.vis_s_num             vis_s_num,              -- �K��r����
              xsvsr.vis_t_num             vis_t_num,              -- �K��s����
              xsvsr.vis_u_num             vis_u_num,              -- �K��t����
              xsvsr.vis_v_num             vis_v_num,              -- �K��u����
              xsvsr.vis_w_num             vis_w_num,              -- �K��v����
              xsvsr.vis_x_num             vis_x_num,              -- �K��w����
              xsvsr.vis_y_num             vis_y_num,              -- �K��x����
              xsvsr.vis_z_num             vis_z_num,              -- �K��y����
              xsvsry.rslt_amt             rslt_amty,              -- �O�N����
              xsvsry.rslt_vd_amt          rslt_vd_amty,           -- �O�N���сiVD�j
              xsvsry.rslt_other_amt       rslt_other_amty,        -- �O�N���сiVD�ȊO�j
              xsvsrm.rslt_amt             rslt_amtm,              -- �挎����
              xsvsrm.rslt_vd_amt          rslt_vd_amtm,           -- �挎���сiVD�j
              xsvsrm.rslt_other_amt       rslt_other_amtm,        -- �挎���сiVD�ȊO�j
              xsvsrn.cust_new_num         cust_new_num,           -- �ڋq�����i�V�K�j
              xsvsrn.cust_vd_new_num      cust_vd_new_num,        -- �ڋq�����iVD�F�V�K�j
              xsvsrn.cust_other_new_num   cust_other_new_num,     -- �ڋq�����iVD�ȊO�F�V�K�j
              xsvsrn.tgt_sales_prsn_total_amt  tgt_sales_prsn_total_amt  -- ���ʔ���\�Z
      FROM    xxcso_sum_visit_sale_rep    xsvsr                   -- �K�┄��v��Ǘ��\�T�}���e�[�u��
             ,xxcso_sum_visit_sale_rep    xsvsry                  -- �K�┄��v��Ǘ��\�T�}���O�N
             ,xxcso_sum_visit_sale_rep    xsvsrm                  -- �K�┄��v��Ǘ��\�T�}���挎
             ,xxcso_sum_visit_sale_rep    xsvsrn                  -- �K�┄��v��Ǘ��\�T�}������
             ,(SELECT  distinct 
                       (CASE
                          WHEN TO_DATE(issue_date,'YYYYMMDD') <= gd_online_sysdate
                            THEN work_base_code_new
                          ELSE work_base_code_old
                        END 
         	               )  gnv_work_base_code
                      ,(CASE
                          WHEN TO_DATE(issue_date,'YYYYMMDD') <= gd_online_sysdate
                            THEN group_number_new
                          ELSE group_number_old
                        END 
                        )  gnv_group_number
               FROM    xxcso_resource_relations_v2
               WHERE   (CASE
                          WHEN TO_DATE(issue_date,'YYYYMMDD') <= gd_online_sysdate
                            THEN work_base_code_new
                          ELSE work_base_code_old
                        END 
                        )  = gv_base_code)       gnv               -- �O���[�v�ԍ��r���[
             ,xxcso_aff_base_v2                  xabv              -- AFF����}�X�^�i�ŐV�j�r���[
      WHERE   xsvsr.group_base_code = gv_base_code
        AND   xsvsr.sum_org_code    = gnv.gnv_group_number
        AND   xabv.base_code        = gnv.gnv_work_base_code
        AND   xsvsr.sum_org_type =cv_sum_org_type3
        AND   xsvsr.month_date_div = cv_month_date_div2
        AND   xsvsr.sales_date
                BETWEEN TO_CHAR(gd_year_month_day,'YYYYMMDD') AND TO_CHAR(gd_year_month_lastday,'YYYYMMDD')
        AND   xsvsr.sum_org_type   = xsvsry.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsry.sum_org_code(+)
        AND   xsvsry.month_date_div(+)= cv_month_date_div1
        AND   xsvsry.sales_date(+) = gv_year_prev
        AND   xsvsr.sum_org_type   = xsvsrm.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsrm.sum_org_code(+)
        AND   xsvsrm.month_date_div(+)= cv_month_date_div1
        AND   xsvsrm.sales_date(+) = gv_year_month_prev
        AND   xsvsr.sum_org_type   = xsvsrn.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsrn.sum_org_code(+)
        AND   xsvsrn.month_date_div(+)= cv_month_date_div1
        AND   xsvsrn.sales_date(+) = gv_year_month
      ORDER BY  work_base_code     ASC,
                group_number       ASC;
    -- ���[�J�����R�[�h
    -- ���[�ϐ��i�[�p
    l_cur_rec                  ticket_data_cur%ROWTYPE;
    l_month_square_rec         g_month_rtype3;
    l_get_month_square_tab     g_get_month_square_ttype;
    l_get_month_square_hon_tab g_get_month_square_ttype;
    BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
      -- ���[�J���ϐ�������
      lb_boolean                := TRUE;        -- �����������f
      ln_m_cnt                  := 1;           -- ���ו��̍s��
      ln_report_output_no       := 1;           -- �z��s��
      ln_cnt                    := 0;           -- LOOP����
      -- PL/SQL�\�i�{�̕��j�̏�����
      init_month_square_hon_tab(l_get_month_square_hon_tab);
      -- ���[�J�����R�[�h�̏�����
      init_month_square_rec3(l_month_square_rec);
      BEGIN
        --�J�[�\���I�[�v��
        OPEN ticket_data_cur;
--
DO_ERROR('A-5-2-1');
--
        <<get_data_loop>>
        LOOP 
          l_cur_rec                           := NULL;          -- �J�[�\�����R�[�h�̏�����
--
          FETCH ticket_data_cur INTO l_cur_rec;                 -- �J�[�\���̃f�[�^�����R�[�h�Ɋi�[
--
          -- �Ώی�����O���̏ꍇ
          EXIT WHEN ticket_data_cur%NOTFOUND
            OR  ticket_data_cur%ROWCOUNT = 0;
--
DO_ERROR('A-5-2-2');
--
          debug(
            buff   => l_cur_rec.work_base_code                    ||','||
                      l_cur_rec.base_name                         ||','||
                      l_cur_rec.group_number                      ||','||
                      l_cur_rec.group_name                        ||','||
                      l_cur_rec.sales_date                        ||','||
                      TO_CHAR(l_cur_rec.tgt_amt)                  ||','||
                      TO_CHAR(l_cur_rec.tgt_new_amt)              ||','||
                      TO_CHAR(l_cur_rec.tgt_vd_new_amt)           ||','||
                      TO_CHAR(l_cur_rec.tgt_vd_amt)               ||','||
                      TO_CHAR(l_cur_rec.tgt_other_new_amt)        ||','||
                      TO_CHAR(l_cur_rec.tgt_other_amt)            ||','||
                      TO_CHAR(l_cur_rec.rslt_amt)                 ||','||
                      TO_CHAR(l_cur_rec.rslt_new_amt)             ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_new_amt)          ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_amt)              ||','||
                      TO_CHAR(l_cur_rec.rslt_other_new_amt)       ||','||
                      TO_CHAR(l_cur_rec.rslt_other_amt)           ||','||
                      TO_CHAR(l_cur_rec.rslt_center_amt)          ||','||
                      TO_CHAR(l_cur_rec.rslt_center_vd_amt)       ||','||
                      TO_CHAR(l_cur_rec.rslt_center_other_amt)    ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_num)              ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_new_num)          ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_vd_new_num)       ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_vd_num)           ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_other_new_num)    ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_other_num)        ||','||
                      TO_CHAR(l_cur_rec.tgt_vis_mc_num)           ||','||
                      TO_CHAR(l_cur_rec.vis_num)                  ||','||
                      TO_CHAR(l_cur_rec.vis_new_num)              ||','||
                      TO_CHAR(l_cur_rec.vis_vd_new_num)           ||','||
                      TO_CHAR(l_cur_rec.vis_vd_num)               ||','||
                      TO_CHAR(l_cur_rec.vis_other_new_num)        ||','||
                      TO_CHAR(l_cur_rec.vis_other_num)            ||','||
                      TO_CHAR(l_cur_rec.vis_mc_num)               ||','||
                      TO_CHAR(l_cur_rec.vis_sales_num)            ||','||
                      TO_CHAR(l_cur_rec.vis_a_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_b_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_c_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_d_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_e_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_f_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_g_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_h_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_i_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_j_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_k_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_l_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_m_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_n_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_o_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_p_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_q_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_r_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_s_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_t_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_u_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_v_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_w_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_x_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_y_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_z_num)                ||','||
                      TO_CHAR(l_cur_rec.rslt_amty)                ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_amty)             ||','||
                      TO_CHAR(l_cur_rec.rslt_other_amty)          ||','||
                      TO_CHAR(l_cur_rec.rslt_amtm)                ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_amtm)             ||','||
                      TO_CHAR(l_cur_rec.rslt_other_amtm)          ||','||
                      TO_CHAR(l_cur_rec.cust_new_num)             ||','||
                      TO_CHAR(l_cur_rec.cust_vd_new_num)          ||','||
                      TO_CHAR(l_cur_rec.cust_other_new_num)       ||','||
                      TO_CHAR(l_cur_rec.tgt_sales_prsn_total_amt) ||','||
                     cv_lf 
          );
          -- �O�񃌃R�[�h�Ƌ��_�R�[�h�������ŃO���[�v�ԍ����Ⴄ�ꍇ�A���ו��z��Ɩ{�̕��z����X�V�B
          IF(lb_boolean=FALSE) THEN
            IF((lv_bf_work_base_code = l_cur_rec.work_base_code)AND(lv_bf_group_number <> l_cur_rec.group_number))
              THEN
              -- DEBUG���b�Z�[�W
              debug(
                 buff   => '�c�ƃO���[�v�ԍ����Ⴂ�܂��B :' ||'�O��F '|| lv_bf_group_number ||
                            '����F' || l_cur_rec.group_number ||
                            '���ו��z��' || TO_CHAR(ln_m_cnt)
              );
              -- =================================================
              -- A-5-3.PLSQL�\�̍X�V
              -- =================================================
              up_plsql_tab3(
                 i_month_square_rec   => l_month_square_rec          -- 1�������f�[�^
                ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
                ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
                ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
                ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
                ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
                ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
              l_month_square_rec.l_one_day_tab.DELETE;
              l_month_square_rec      := NULL;
              init_month_square_rec3(l_month_square_rec);
              ln_m_cnt          := ln_m_cnt + 1;       -- ���ו��z����{�P����B
              lb_boolean        := TRUE;               -- ���������̃t���O�I������B
            ELSIF(lv_bf_work_base_code <> l_cur_rec.work_base_code)THEN
              -- =================================================
              -- A-5-3.PLSQL�\�̍X�V
              -- =================================================
              up_plsql_tab3(
                 i_month_square_rec   => l_month_square_rec          -- 1�������f�[�^
                ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
                ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
                ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
                ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
                ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
                ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
              l_month_square_rec.l_one_day_tab.DELETE;  -- ���[�J�����R�[�h�̃f�[�^�������B
              l_month_square_rec      := NULL;          -- ���[�J�����R�[�h�̃f�[�^�������B
              init_month_square_rec3(l_month_square_rec);
              lb_boolean        := TRUE;               -- ���������̃t���O�I������B
            END IF;
          END IF;
          -- �o�̓t���O���I���̏�Ԃŋ��_�R�[�h���O��擾�����c�ƈ��ԍ��ƈႤ�ꍇ���[�N�e�[�u���ɏo�͂��܂��B
          IF ((ln_cnt > 0) AND
              (lv_bf_work_base_code <> l_cur_rec.work_base_code)) THEN
            debug(
               buff   => '���_�R�[�h���Ⴂ�܂��B :' ||'�O��F '|| lv_bf_work_base_code || ''||
                          '����F' || l_cur_rec.work_base_code
            );
          -- =================================================
          -- A-3-4,A-4-4,A-5-4,A-6-4,A-7-4.���[�N�e�[�u���֏o��
          -- =================================================
          insert_wrk_table(
             ir_m_tab            => l_get_month_square_tab                      -- ���ו����R�[�h
            ,ir_hon_tab          => l_get_month_square_hon_tab                  -- �{�̕����R�[�h
            ,in_m_cnt            => ln_m_cnt                                    -- ���ו��s��
            ,in_report_output_no => ln_report_output_no                         -- ���[�o�̓Z�b�g�ԍ�
            ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
           );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          -- ���R�[�h�̏�����
          l_get_month_square_tab.DELETE;
          l_get_month_square_hon_tab.DELETE;
          init_month_square_hon_tab(l_get_month_square_hon_tab);
          ln_report_output_no := ln_report_output_no + 1; -- �o�͂��ꂽ���[���Ɂ{�P����
          lb_boolean          := TRUE;                    -- ���������̏�Ԃɖ߂�
          ln_m_cnt            := 1;                       -- ���ו��z��̍s���̏�����
          END IF;
          -- ���������̏ꍇ
          IF(lb_boolean) THEN
            -- �c�ƃO���[�v�ԍ��Ə]�ƈ��ԍ������[�J���ϐ��Ɋi�[
            lv_bf_group_number         := l_cur_rec.group_number;          -- �c�ƃO���[�v�ԍ�
            lv_bf_work_base_code       := l_cur_rec.work_base_code;        -- ���_�R�[�h
            -- ���[�J�����R�[�h�Ɋi�[
            -- �Ζ��n���_�R�[�h
            l_month_square_rec.work_base_code     := l_cur_rec.work_base_code;
            -- �Ζ��n���_��
            l_month_square_rec.base_name          := l_cur_rec.base_name;
            -- �c�ƃO���[�v�ԍ�
            l_month_square_rec.group_number       := l_cur_rec.group_number;
            -- �c�ƃO���[�v��
            l_month_square_rec.group_name         := l_cur_rec.group_name;
            -- �V�K�ڋq����
            l_month_square_rec.cust_new_num       := l_cur_rec.cust_new_num;
            -- �V�KVD����
            l_month_square_rec.cust_vd_new_num    := l_cur_rec.cust_vd_new_num;
            -- �V�KVD�ȊO����
            l_month_square_rec.cust_other_new_num := l_cur_rec.cust_other_new_num;
            -- �O�N����
            l_month_square_rec.rslt_amty          := l_cur_rec.rslt_amty;
            -- �O�N���сiVD�j
            l_month_square_rec.rslt_vd_amty       := l_cur_rec.rslt_vd_amty;
            -- �O�N���сiVD�ȊO�j
            l_month_square_rec.rslt_other_amty    := l_cur_rec.rslt_other_amty;
            -- �挎����
            l_month_square_rec.rslt_amtm          := l_cur_rec.rslt_amtm;
            -- �挎���сiVD�j
            l_month_square_rec.rslt_vd_amtm       := l_cur_rec.rslt_vd_amtm;
            -- �挎���сiVD�ȊO�j
            l_month_square_rec.rslt_other_amtm    := l_cur_rec.rslt_other_amtm;
            -- ���ʔ���\�Z
            l_month_square_rec.tgt_sales_prsn_total_amt := l_cur_rec.tgt_sales_prsn_total_amt;
            lb_boolean := FALSE;
            -- DEBUG���b�Z�[�W
            -- ���������̏ꍇ
            debug(
               buff   => '���������t���O:' || 'FALSE'
            );
          END IF;
          -- ���t���擾
          ln_date := TO_NUMBER(SUBSTR(l_cur_rec.sales_date,7,2));
          -- DEBUG���b�Z�[�W
          -- ���������̏ꍇ
          debug(
             buff   => '���t:' || l_cur_rec.sales_date || cv_lf ||
                       '���t���̃i���o�[�^:'     || TO_CHAR(ln_date)
          );
          l_month_square_rec.l_one_day_tab(ln_date).tgt_amt               
            := l_cur_rec.tgt_amt;               -- ����v��
          l_month_square_rec.l_one_day_tab(ln_date).tgt_new_amt           
            := l_cur_rec.tgt_new_amt;           -- ����v��i�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vd_new_amt        
            := l_cur_rec.tgt_vd_new_amt;        -- ����v��iVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vd_amt            
            := l_cur_rec.tgt_vd_amt;            -- ����v��iVD�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_other_new_amt     
            := l_cur_rec.tgt_other_new_amt;     -- ����v��iVD�ȊO�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_other_amt         
            := l_cur_rec.tgt_other_amt;         -- ����v��iVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_amt              
            := l_cur_rec.rslt_amt;               -- �������
          l_month_square_rec.l_one_day_tab(ln_date).rslt_new_amt          
            := l_cur_rec.rslt_new_amt;          -- ������сi�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_vd_new_amt       
            := l_cur_rec.rslt_vd_new_amt;       -- ������сiVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_vd_amt           
            := l_cur_rec.rslt_vd_amt;           -- ������сiVD�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_other_new_amt    
            := l_cur_rec.rslt_other_new_amt;    -- ������сiVD�ȊO�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_other_amt        
            := l_cur_rec.rslt_other_amt;        -- ������сiVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_center_amt       
            := l_cur_rec.rslt_center_amt;       -- �������_�Q�������
          l_month_square_rec.l_one_day_tab(ln_date).rslt_center_vd_amt       
            := l_cur_rec.rslt_center_vd_amt;    -- �������_�Q������сiVD�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_center_other_amt       
            := l_cur_rec.rslt_center_other_amt; -- �������_�Q������сiVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_num           
            := l_cur_rec.tgt_vis_num;           -- �K��v��
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_new_num       
            := l_cur_rec.tgt_vis_new_num;       -- �K��v��i�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_vd_new_num    
            := l_cur_rec.tgt_vis_vd_new_num;    -- �K��v��iVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_vd_num        
            := l_cur_rec.tgt_vis_vd_num;        -- �K��v��iVD�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_other_new_num 
            := l_cur_rec.tgt_vis_other_new_num;-- �K��v��iVD�ȊO�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_other_num     
            := l_cur_rec.tgt_vis_other_num;     -- �K��v��iVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).tgt_vis_mc_num     
            := l_cur_rec.tgt_vis_mc_num;        -- �K��v��iMC�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_num               
            := l_cur_rec.vis_num;               -- �K�����
          l_month_square_rec.l_one_day_tab(ln_date).vis_new_num           
            := l_cur_rec.vis_new_num;           -- �K����сi�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_vd_new_num        
            := l_cur_rec.vis_vd_new_num;        -- �K����сiVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_vd_num            
            := l_cur_rec.vis_vd_num;            -- �K����сiVD�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_other_new_num     
            := l_cur_rec.vis_other_new_num;     -- �K����сiVD�ȊO�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_other_num         
            := l_cur_rec.vis_other_num;         -- �K����сiVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_mc_num         
            := l_cur_rec.vis_mc_num;            -- �K����сiMC�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_sales_num         
            := l_cur_rec.vis_sales_num;         -- �L������
          -- A0Z�K�⌏��
          l_month_square_rec.l_one_day_tab(ln_date).vis_a_num := nvl(l_cur_rec.vis_a_num,0);  -- �K��A����
          l_month_square_rec.l_one_day_tab(ln_date).vis_b_num := nvl(l_cur_rec.vis_b_num,0);  -- �K��B����
          l_month_square_rec.l_one_day_tab(ln_date).vis_c_num := nvl(l_cur_rec.vis_c_num,0);  -- �K��C����
          l_month_square_rec.l_one_day_tab(ln_date).vis_d_num := nvl(l_cur_rec.vis_d_num,0);  -- �K��D����
          l_month_square_rec.l_one_day_tab(ln_date).vis_e_num := nvl(l_cur_rec.vis_e_num,0);  -- �K��E����
          l_month_square_rec.l_one_day_tab(ln_date).vis_f_num := nvl(l_cur_rec.vis_f_num,0);  -- �K��F����
          l_month_square_rec.l_one_day_tab(ln_date).vis_g_num := nvl(l_cur_rec.vis_g_num,0);  -- �K��G����
          l_month_square_rec.l_one_day_tab(ln_date).vis_h_num := nvl(l_cur_rec.vis_h_num,0);  -- �K��H����
          l_month_square_rec.l_one_day_tab(ln_date).vis_i_num := nvl(l_cur_rec.vis_i_num,0);  -- �K��I����
          l_month_square_rec.l_one_day_tab(ln_date).vis_j_num := nvl(l_cur_rec.vis_j_num,0);  -- �K��J����
          l_month_square_rec.l_one_day_tab(ln_date).vis_k_num := nvl(l_cur_rec.vis_k_num,0);  -- �K��K����
          l_month_square_rec.l_one_day_tab(ln_date).vis_l_num := nvl(l_cur_rec.vis_l_num,0);  -- �K��L����
          l_month_square_rec.l_one_day_tab(ln_date).vis_m_num := nvl(l_cur_rec.vis_m_num,0);  -- �K��M����
          l_month_square_rec.l_one_day_tab(ln_date).vis_n_num := nvl(l_cur_rec.vis_n_num,0);  -- �K��N����
          l_month_square_rec.l_one_day_tab(ln_date).vis_o_num := nvl(l_cur_rec.vis_o_num,0);  -- �K��O����
          l_month_square_rec.l_one_day_tab(ln_date).vis_p_num := nvl(l_cur_rec.vis_p_num,0);  -- �K��P����
          l_month_square_rec.l_one_day_tab(ln_date).vis_q_num := nvl(l_cur_rec.vis_q_num,0);  -- �K��Q����
          l_month_square_rec.l_one_day_tab(ln_date).vis_r_num := nvl(l_cur_rec.vis_r_num,0);  -- �K��R����
          l_month_square_rec.l_one_day_tab(ln_date).vis_s_num := nvl(l_cur_rec.vis_s_num,0);  -- �K��S����
          l_month_square_rec.l_one_day_tab(ln_date).vis_t_num := nvl(l_cur_rec.vis_t_num,0);  -- �K��T����
          l_month_square_rec.l_one_day_tab(ln_date).vis_u_num := nvl(l_cur_rec.vis_u_num,0);  -- �K��U����
          l_month_square_rec.l_one_day_tab(ln_date).vis_v_num := nvl(l_cur_rec.vis_v_num,0);  -- �K��V����
          l_month_square_rec.l_one_day_tab(ln_date).vis_w_num := nvl(l_cur_rec.vis_w_num,0);  -- �K��W����
          l_month_square_rec.l_one_day_tab(ln_date).vis_x_num := nvl(l_cur_rec.vis_x_num,0);  -- �K��X����
          l_month_square_rec.l_one_day_tab(ln_date).vis_y_num := nvl(l_cur_rec.vis_y_num,0);  -- �K��Y����
          l_month_square_rec.l_one_day_tab(ln_date).vis_z_num := nvl(l_cur_rec.vis_z_num,0);  -- �K��Z����
          -- �ŏ��̃��R�[�h�̏ꍇ
          IF(lb_boolean) THEN
            lb_boolean              := FALSE;                  -- ���������̃t���O���I�t����B
          END IF;
          -- ���o�����J�E���^�ɂP�𑫂��B
          ln_cnt         := ln_cnt + 1;
          gn_target_cnt  := ln_cnt;
          -- loop����
          debug(
                buff   => 'loop����' || TO_CHAR(ln_cnt)
          );
        END LOOP;
        -- �Ō�̃f�[�^�o�^
        IF (ln_cnt > 0) THEN
          debug(
                  buff   => '�Ō�̃f�[�^�̓o�^'
          );
          -- =================================================
          -- A-5-3.PLSQL�\�̍X�V
          -- =================================================
          up_plsql_tab3(
             i_month_square_rec   => l_month_square_rec          -- 1�������f�[�^
            ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
            ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
            ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
            ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          -- =================================================
          -- A-3-4,A-4-4,A-5-4,A-6-4,A-7-4.���[�N�e�[�u���֏o��
          -- =================================================
          insert_wrk_table(
             ir_m_tab            => l_get_month_square_tab                      -- ���ו����R�[�h
            ,ir_hon_tab          => l_get_month_square_hon_tab                  -- �{�̕����R�[�h
            ,in_m_cnt            => ln_m_cnt                                    -- ���ו��s��
            ,in_report_output_no => ln_report_output_no                         -- ���[�o�̓Z�b�g�ԍ�
            ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
           );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          -- ���b�Z�[�W�o��
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_08         --���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_table             --�g�[�N���R�[�h1
                          ,iv_token_value1 => cv_tab_samari            --�g�[�N���l1
                          ,iv_token_name2  => cv_tkn_errmsg            --�g�[�N���R�[�h�Q
                          ,iv_token_value2 => SQLERRM                  --�g�[�N���l�Q
          );
          fnd_file.put_line(
                which  => FND_FILE.LOG,
                buff   => ''      || cv_lf ||     -- ��s�̑}��
                        lv_errmsg || cv_lf || 
                         ''                         -- ��s�̑}��
          );
        RAISE global_api_expt;
      END;
    -- �J�[�\���N���[�Y
    CLOSE ticket_data_cur;
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
  END get_ticket3;
--
  /**********************************************************************************
   * Procedure Name   : up_plsql_tab4
   * Description      : ���[���4-�n��c�ƕ�/����-PLSQL�\�̍X�V (A-6-3)
  ***********************************************************************************/
  PROCEDURE up_plsql_tab4(
     i_month_square_rec  IN                g_month_rtype4                     -- �ꃖ�����f�[�^
    ,in_m_cnt            IN                NUMBER                             -- ���ו��̃J�E���^
    ,io_m_tab            IN  OUT NOCOPY    g_get_month_square_ttype           -- ���ו��z��
    ,io_hon_tab          IN  OUT NOCOPY    g_get_month_square_ttype           -- �{�̕��z��
    ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'up_plsql_tab4';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ���[�J���ϐ�
    lv_gvm_type           VARCHAR2(1);                                       -- ��ʁ^���̋@�^�l�b
    ln_m_cnt              NUMBER(9);                                         -- IN�p�����[�^���i�[
    BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
      ln_m_cnt                            := in_m_cnt;                       -- IN�p�����[�^���i�[
      -- DEBUG���b�Z�[�W
      -- PL/SQL�\�̍X�V
      debug(
         buff   => '�n��c�ƕ�/����-PL/SQL�\�̍X�V����:' || TO_CHAR(ln_m_cnt)
      );
      BEGIN
        -- ����グ���ו�
        io_m_tab(ln_m_cnt).up_base_code     := i_month_square_rec.base_code_par;       -- ���_�R�[�h�i�e)
        io_m_tab(ln_m_cnt).up_hub_name      := i_month_square_rec.base_name_par;       -- ���_���́i�e�j
        io_m_tab(ln_m_cnt).base_code        := i_month_square_rec.base_code_chi;       -- �Ɩ��n���_�R�[�h
        io_m_tab(ln_m_cnt).hub_name         := i_month_square_rec.base_name_chi;       -- �Ɩ��n���_��  
        io_m_tab(ln_m_cnt).last_year_rslt_sales_amt :=i_month_square_rec.rslt_amty; -- �O�N����
        io_m_tab(ln_m_cnt).last_mon_rslt_sales_amt  :=i_month_square_rec.rslt_amtm; -- �挎����
        io_m_tab(ln_m_cnt).new_customer_num :=i_month_square_rec.cust_new_num;      -- �ڋq����
        io_m_tab(ln_m_cnt).new_vendor_num   :=i_month_square_rec.cust_vd_new_num;   -- �ڋq�����iVD �V�K�j
        io_m_tab(ln_m_cnt).plan_sales_amt  := i_month_square_rec.tgt_sales_prsn_total_amt;  -- ���ʔ���\�Z
        -- DEBUG���b�Z�[�W
        -- PL/SQL�\�̍X�V
        debug(
           buff   => '�n��c�ƕ�/����-PL/SQL�\�̍X�V����' || '����グ���ו��Œ蕔����'
        );
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(
           which  => FND_FILE.LOG,
           buff   => '�n��c�ƕ�/����-PL/SQL�\�̍X�V�������s:' || SQLERRM 
         );
         RAISE global_api_others_expt;
      END;
      -- �{�̕�
      FOR i IN 1..cn_idx_max LOOP 
        IF(i = cn_idx_sales_ippn) THEN         --����グ���v��(���)
          io_hon_tab(i).gvm_type                 := cv_gvm_g;                              -- ���
        ELSIF(i = cn_idx_sales_vd) THEN      --����グ���v��(���̋@)
          io_hon_tab(i).gvm_type                 := cv_gvm_v;                              -- ���̋@
        ELSIF(i = cn_idx_sales_sum) THEN      -- ����グ���v��
          NULL;
        ELSIF(i=cn_idx_visit_ippn)THEN       --�K�⒆�v��
          io_hon_tab(i).gvm_type                 := cv_gvm_g;                              -- ���
        ELSIF(i=cn_idx_visit_vd)THEN       --�K�⒆�v��
          io_hon_tab(i).gvm_type                 := cv_gvm_v;                              -- ���̋@
        ELSIF(i=cn_idx_visit_mc)THEN       --�K�⒆�v��
          io_hon_tab(i).gvm_type                 := cv_gvm_m;                              -- MC
        END IF;
        io_hon_tab(i).up_base_code     := i_month_square_rec.base_code_par;  -- ���_�R�[�h�i�e)
        io_hon_tab(i).up_hub_name      := i_month_square_rec.base_name_par;  -- ���_���́i�e�j
      END LOOP;
--
      -- ���㒆�v��(���)
      io_hon_tab(cn_idx_sales_ippn).last_year_rslt_sales_amt := 
        io_hon_tab(cn_idx_sales_ippn).last_year_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_other_amty, 0);    -- �O�N����
      io_hon_tab(cn_idx_sales_ippn).last_mon_rslt_sales_amt  :=
        io_hon_tab(cn_idx_sales_ippn).last_mon_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_other_amtm, 0);    -- �挎����
      io_hon_tab(cn_idx_sales_ippn).new_customer_num :=
        io_hon_tab(cn_idx_sales_ippn).new_customer_num +
        NVL(i_month_square_rec.cust_other_new_num, 0); -- �ڋq�����i�V�K�j�i��ʁj
      -- ���㒆�v��(���̋@)
      io_hon_tab(cn_idx_sales_vd).last_year_rslt_sales_amt :=
        io_hon_tab(cn_idx_sales_vd).last_year_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_vd_amty, 0);       -- �O�N����
      io_hon_tab(cn_idx_sales_vd).last_mon_rslt_sales_amt :=
        io_hon_tab(cn_idx_sales_vd).last_mon_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_vd_amtm, 0);       -- �挎����
      io_hon_tab(cn_idx_sales_vd).new_customer_num :=
        io_hon_tab(cn_idx_sales_vd).new_customer_num +
        NVL(i_month_square_rec.cust_vd_new_num, 0);     -- �ڋq�����i�V�K�j(���̋@)
--
      FOR i IN 1..31 LOOP
        BEGIN
          -- DEBUG���b�Z�[�W
            -- PL/SQL�\�̍X�V
            debug(
               buff   => '�n��c�ƕ�/����-PL/SQL�\�̍X�V����' || '1�������̃f�[�^�X�V'
            );
          --����グ���ו�
          io_m_tab(ln_m_cnt).l_get_one_day_tab(i).rslt_vs_amt
            := i_month_square_rec.l_one_day_tab(i).rslt_amt;                  -- ����グ����
          io_m_tab(ln_m_cnt).l_get_one_day_tab(i).rslt_other_sales_amt
            := i_month_square_rec.l_one_day_tab(i).rslt_center_amt;           -- �������_�Q�������
          -- ����グ���v��(���)
          io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_other_amt,0);        -- �������,�K�����
          io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_other_sales_amt :=
            io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_other_sales_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_center_other_amt,0); -- �������_�Q�������
          -- ����グ���v��(���̋@)
          io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_vd_amt,0);           -- �������,�K�����
          io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_other_sales_amt :=
            io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_other_sales_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_center_vd_amt,0);    -- �������_�Q�������
          -- ����グ���v��
          -- �K�⒆�v��(���)
          io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_other_num,0);         -- �������,�K�����
          -- �K�⒆�v��(���̋@)
          io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_vd_num,0);            -- �������,�K�����
          -- �K�⒆�v��(MC)
          io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_mc_num,0);            -- �������,�K�����
          -- �K�⍇�v��
          io_hon_tab(cn_idx_visit_sum).l_get_one_day_tab(i).effective_num :=
            io_hon_tab(cn_idx_visit_sum).l_get_one_day_tab(i).effective_num + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_sales_num,0);         -- �L������
          -- �K����e���v��
          io_hon_tab(cn_idx_visit_dsc).vis_a_num := 
             io_hon_tab(cn_idx_visit_dsc).vis_a_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_a_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_b_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_b_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_b_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_c_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_c_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_c_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_d_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_d_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_d_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_e_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_e_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_e_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_f_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_f_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_f_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_g_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_g_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_g_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_h_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_h_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_h_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_i_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_i_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_i_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_j_num := 
             io_hon_tab(cn_idx_visit_dsc).vis_j_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_j_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_k_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_k_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_k_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_l_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_l_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_l_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_m_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_m_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_m_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_n_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_n_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_n_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_o_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_o_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_o_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_p_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_p_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_p_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_q_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_q_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_q_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_r_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_r_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_r_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_s_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_s_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_s_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_t_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_t_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_t_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_u_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_u_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_u_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_v_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_v_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_v_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_w_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_w_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_w_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_x_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_x_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_x_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_y_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_y_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_y_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_z_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_z_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_z_num,0);
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(
               which  => FND_FILE.LOG,
               buff   => '�n��c�ƕ�/����-PL/SQL�\-�{�̕��̍X�V�����ŃG���[�ɂȂ�܂����B' || SQLERRM ||
                        ''                         -- ��s�̑}��
             );
            RAISE global_api_others_expt;
        END;
      END LOOP;
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
  END up_plsql_tab4;
--
  /**********************************************************************************
   * Procedure Name   : get_ticket4
   * Description      : ���[���4-�n��c�ƕ�/���� (A-6-1,A-6-2)
  ***********************************************************************************/
  PROCEDURE get_ticket4(
     ov_errbuf         OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode        OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg         OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_ticket4';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ���[�J���萔
    -- ���[�J���ϐ�
    lb_boolean            BOOLEAN;      -- ���f�p
    ln_m_cnt              NUMBER(9);    -- ���ו��J�E���^�[���i�[
    ln_cnt                NUMBER(9);    -- ���o���ꂽ���R�[�h����
    ln_date               NUMBER(2);    -- ���t�̃i���o�[�^
    ln_report_output_no   NUMBER(9);    -- ���[�o�̓Z�b�g�ԍ�
    lv_bf_base_code_par   xxcso_aff_base_level_v.base_code%TYPE;
    lv_bf_base_code_chi   xxcso_aff_base_level_v.child_base_code%TYPE;
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR ticket_data_cur
    IS
      SELECT
              xablv.base_code             base_code_par,          -- �Ζ��n���_�R�[�h(�e)(���_�R�[�h)
              xabvpar.base_name           base_name_par,          -- �Ζ��n���_��(�e)
              xablv.child_base_code       base_code_chi,          -- �Ζ��n���_�R�[�h
              xabvchi.base_name           base_name_chi,          -- �Ζ��n���_��
              xsvsr.sales_date            sales_date,             -- �̔��N����
              xsvsr.rslt_amt              rslt_amt,               -- �������
              xsvsr.rslt_new_amt          rslt_new_amt,           -- ������сi�V�K�j
              xsvsr.rslt_vd_new_amt       rslt_vd_new_amt,        -- ������сiVD�F�V�K�j
              xsvsr.rslt_vd_amt           rslt_vd_amt,            -- ������сiVD�j
              xsvsr.rslt_other_new_amt    rslt_other_new_amt,     -- ������сiVD�ȊO�F�V�K�j
              xsvsr.rslt_other_amt        rslt_other_amt,         -- ������сiVD�ȊO�j
              xsvsr.rslt_center_amt       rslt_center_amt,        -- �������_�Q�������
              xsvsr.rslt_center_vd_amt    rslt_center_vd_amt,     -- �������_�Q������сiVD�j
              xsvsr.rslt_center_other_amt rslt_center_other_amt,  -- �������_�Q������сiVD�ȊO�j
              xsvsr.vis_num               vis_num,                -- �K�����
              xsvsr.vis_new_num           vis_new_num,            -- �K����сi�V�K�j
              xsvsr.vis_vd_new_num        vis_vd_new_num,         -- �K����сiVD�F�V�K�j
              xsvsr.vis_vd_num            vis_vd_num,             -- �K����сiVD�j
              xsvsr.vis_other_new_num     vis_other_new_num,      -- �K����сiVD�ȊO�F�V�K�j
              xsvsr.vis_other_num         vis_other_num,          -- �K����сiVD�ȊO�j
              xsvsr.vis_mc_num            vis_mc_num,             -- �K����сiMC�j
              xsvsr.vis_sales_num         vis_sales_num,          -- �L������
              xsvsr.vis_a_num             vis_a_num,              -- �K��`����
              xsvsr.vis_b_num             vis_b_num,              -- �K��a����
              xsvsr.vis_c_num             vis_c_num,              -- �K��b����
              xsvsr.vis_d_num             vis_d_num,              -- �K��c����
              xsvsr.vis_e_num             vis_e_num,              -- �K��d����
              xsvsr.vis_f_num             vis_f_num,              -- �K��e����
              xsvsr.vis_g_num             vis_g_num,              -- �K��f����
              xsvsr.vis_h_num             vis_h_num,              -- �K��g����
              xsvsr.vis_i_num             vis_i_num,              -- �K���@����
              xsvsr.vis_j_num             vis_j_num,              -- �K��i����
              xsvsr.vis_k_num             vis_k_num,              -- �K��j����
              xsvsr.vis_l_num             vis_l_num,              -- �K��k����
              xsvsr.vis_m_num             vis_m_num,              -- �K��l����
              xsvsr.vis_n_num             vis_n_num,              -- �K��m����
              xsvsr.vis_o_num             vis_o_num,              -- �K��n����
              xsvsr.vis_p_num             vis_p_num,              -- �K��o����
              xsvsr.vis_q_num             vis_q_num,              -- �K��p����
              xsvsr.vis_r_num             vis_r_num,              -- �K��q����
              xsvsr.vis_s_num             vis_s_num,              -- �K��r����
              xsvsr.vis_t_num             vis_t_num,              -- �K��s����
              xsvsr.vis_u_num             vis_u_num,              -- �K��t����
              xsvsr.vis_v_num             vis_v_num,              -- �K��u����
              xsvsr.vis_w_num             vis_w_num,              -- �K��v����
              xsvsr.vis_x_num             vis_x_num,              -- �K��w����
              xsvsr.vis_y_num             vis_y_num,              -- �K��x����
              xsvsr.vis_z_num             vis_z_num,              -- �K��y����
              xsvsry.rslt_amt             rslt_amty,              -- �O�N����
              xsvsry.rslt_vd_amt          rslt_vd_amty,           -- �O�N���сiVD�j
              xsvsry.rslt_other_amt       rslt_other_amty,        -- �O�N���сiVD�ȊO�j
              xsvsrm.rslt_amt             rslt_amtm,              -- �挎����
              xsvsrm.rslt_vd_amt          rslt_vd_amtm,           -- �挎���сiVD�j
              xsvsrm.rslt_other_amt       rslt_other_amtm,        -- �挎���сiVD�ȊO�j
              xsvsrn.cust_new_num         cust_new_num,           -- �ڋq�����i�V�K�j
              xsvsrn.cust_vd_new_num      cust_vd_new_num,        -- �ڋq�����iVD�F�V�K�j
              xsvsrn.cust_other_new_num   cust_other_new_num,     -- �ڋq�����iVD�ȊO�F�V�K�j
              xsvsrn.tgt_sales_prsn_total_amt  tgt_sales_prsn_total_amt  -- ���ʔ���\�Z
      FROM    xxcso_aff_base_level_v      xablv         -- AFF����K�w�}�X�^�r���[
             ,xxcso_aff_base_v2           xabvpar       -- AFF����}�X�^�i�ŐV�j�r���[(�e)
             ,xxcso_aff_base_v2           xabvchi       -- AFF����}�X�^�i�ŐV�j�r���[(�q)
             ,xxcso_sum_visit_sale_rep    xsvsr         -- �K�┄��v��Ǘ��\�T�}���e�[�u��
             ,xxcso_sum_visit_sale_rep    xsvsry        -- �K�┄��v��Ǘ��\�T�}���O�N
             ,xxcso_sum_visit_sale_rep    xsvsrm        -- �K�┄��v��Ǘ��\�T�}���挎
             ,xxcso_sum_visit_sale_rep    xsvsrn        -- �K�┄��v��Ǘ��\�T�}������
      WHERE   xablv.base_code = gv_base_code
        AND   xablv.child_base_code = xsvsr.sum_org_code
        AND   xablv.base_code = xabvpar.base_code
        AND   xablv.child_base_code = xabvchi.base_code
        AND   xsvsr.sum_org_type = cv_sum_org_type4
        AND   xsvsr.month_date_div = cv_month_date_div2
        AND   xsvsr.sales_date
                BETWEEN TO_CHAR(gd_year_month_day,'YYYYMMDD') AND TO_CHAR(gd_year_month_lastday,'YYYYMMDD')
        AND   xsvsr.sum_org_type   = xsvsry.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsry.sum_org_code(+)
        AND   xsvsry.month_date_div(+)= cv_month_date_div1
        AND   xsvsry.sales_date(+) = gv_year_prev
        AND   xsvsr.sum_org_type   = xsvsrm.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsrm.sum_org_code(+)
        AND   xsvsrm.month_date_div(+)= cv_month_date_div1
        AND   xsvsrm.sales_date(+) = gv_year_month_prev
        AND   xsvsr.sum_org_type   = xsvsrn.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsrn.sum_org_code(+)
        AND   xsvsrn.month_date_div(+)= cv_month_date_div1
        AND   xsvsrn.sales_date(+) = gv_year_month
      ORDER BY  base_code_chi     ASC;
    -- ���[�J�����R�[�h
    l_cur_rec                  ticket_data_cur%ROWTYPE;
    l_month_square_rec         g_month_rtype4;
    l_get_month_square_tab     g_get_month_square_ttype;
    l_get_month_square_hon_tab g_get_month_square_ttype;
    BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
      -- ���[�J���ϐ�������
      lb_boolean                := TRUE;        -- �����������f
      ln_m_cnt                  := 1;           -- ���ו��̍s��
      ln_report_output_no       := 1;           -- �z��s��
      ln_cnt                    := 0;           -- LOOP����
      -- PL/SQL�\�i�{�̕��j�̏�����
      init_month_square_hon_tab(l_get_month_square_hon_tab);
      -- ���[�J�����R�[�h�̏�����
      init_month_square_rec4(l_month_square_rec);
      BEGIN
        --�J�[�\���I�[�v��
        OPEN ticket_data_cur;
--
DO_ERROR('A-6-2-1');
--
        <<get_data_loop>>
        LOOP 
          l_cur_rec                           := NULL;          -- �J�[�\�����R�[�h�̏�����
--
          FETCH ticket_data_cur INTO l_cur_rec;                 -- �J�[�\���̃f�[�^�����R�[�h�Ɋi�[
--
          -- �Ώی�����O���̏ꍇ
          EXIT WHEN ticket_data_cur%NOTFOUND
            OR  ticket_data_cur%ROWCOUNT = 0;
--
DO_ERROR('A-6-2-2');
--
          debug(
            buff   => l_cur_rec.base_code_par                     ||','||
                      l_cur_rec.base_name_par                     ||','||
                      l_cur_rec.base_code_chi                     ||','||
                      l_cur_rec.base_name_chi                     ||','||
                      l_cur_rec.sales_date                        ||','||
                      TO_CHAR(l_cur_rec.rslt_amt)                 ||','||
                      TO_CHAR(l_cur_rec.rslt_new_amt)             ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_new_amt)          ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_amt)              ||','||
                      TO_CHAR(l_cur_rec.rslt_other_new_amt)       ||','||
                      TO_CHAR(l_cur_rec.rslt_other_amt)           ||','||
                      TO_CHAR(l_cur_rec.rslt_center_amt)          ||','||
                      TO_CHAR(l_cur_rec.rslt_center_vd_amt)       ||','||
                      TO_CHAR(l_cur_rec.rslt_center_other_amt)    ||','||
                      TO_CHAR(l_cur_rec.vis_num)                  ||','||
                      TO_CHAR(l_cur_rec.vis_new_num)              ||','||
                      TO_CHAR(l_cur_rec.vis_vd_new_num)           ||','||
                      TO_CHAR(l_cur_rec.vis_vd_num)               ||','||
                      TO_CHAR(l_cur_rec.vis_other_new_num)        ||','||
                      TO_CHAR(l_cur_rec.vis_other_num)            ||','||
                      TO_CHAR(l_cur_rec.vis_mc_num)               ||','||
                      TO_CHAR(l_cur_rec.vis_sales_num)            ||','||
                      TO_CHAR(l_cur_rec.vis_a_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_b_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_c_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_d_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_e_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_f_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_g_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_h_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_i_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_j_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_k_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_l_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_m_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_n_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_o_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_p_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_q_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_r_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_s_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_t_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_u_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_v_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_w_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_x_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_y_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_z_num)                ||','||
                      TO_CHAR(l_cur_rec.rslt_amty)                ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_amty)             ||','||
                      TO_CHAR(l_cur_rec.rslt_other_amty)          ||','||
                      TO_CHAR(l_cur_rec.rslt_amtm)                ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_amtm)             ||','||
                      TO_CHAR(l_cur_rec.rslt_other_amtm)          ||','||
                      TO_CHAR(l_cur_rec.cust_new_num)             ||','||
                      TO_CHAR(l_cur_rec.cust_vd_new_num)          ||','||
                      TO_CHAR(l_cur_rec.cust_other_new_num)       ||','||
                      TO_CHAR(l_cur_rec.tgt_sales_prsn_total_amt) ||','||
                     cv_lf 
          );
          -- �O�񃌃R�[�h�Ƌ��_�R�[�h�������ŋƖ��n�R�[�h���Ⴄ�ꍇ�A���ו��z��Ɩ{�̕��z����X�V�B
          IF(lb_boolean=FALSE) THEN
            IF((lv_bf_base_code_par = l_cur_rec.base_code_par)AND(lv_bf_base_code_chi <> l_cur_rec.base_code_chi))
              THEN
              -- DEBUG���b�Z�[�W
              debug(
                 buff   => '�Ɩ��n�R�[�h���Ⴂ�܂��B :' ||'�O��F '|| lv_bf_base_code_chi ||
                            '����F' || l_cur_rec.base_code_chi ||
                            '���ו��z��' || TO_CHAR(ln_m_cnt)
              );
              -- =================================================
              -- A-6-2,A-6-3.PLSQL�\�̍X�V
              -- =================================================
              up_plsql_tab4(
                 i_month_square_rec   => l_month_square_rec          -- �ꃖ�����f�[�^
                ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
                ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
                ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
                ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
                ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
                ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
              l_month_square_rec.l_one_day_tab.DELETE;  -- ���[�J�����R�[�h�̃f�[�^�������B
              l_month_square_rec      := NULL;          -- ���[�J�����R�[�h�̃f�[�^�������B
              init_month_square_rec4(l_month_square_rec);
              ln_m_cnt          := ln_m_cnt + 1;       -- ���ו��z����{�P����B
              lb_boolean        := TRUE;               -- ���������̃t���O�I������B
            ELSIF(lv_bf_base_code_par <> l_cur_rec.base_code_par) THEN
              -- =================================================
              -- A-6-2,A-6-3.PLSQL�\�̍X�V
              -- =================================================
              up_plsql_tab4(
                 i_month_square_rec   => l_month_square_rec          -- �ꃖ�����f�[�^
                ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
                ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
                ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
                ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
                ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
                ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
              l_month_square_rec.l_one_day_tab.DELETE;  -- ���[�J�����R�[�h�̃f�[�^�������B
              l_month_square_rec      := NULL;          -- ���[�J�����R�[�h�̃f�[�^�������B
              init_month_square_rec4(l_month_square_rec);
              lb_boolean        := TRUE;               -- ���������̃t���O�I������B
            END IF;
          END IF;
          -- ���_�R�[�h���O��擾�������_�R�[�h�ƈႤ�ꍇ���[�N�e�[�u���ɏo�͂��܂��B
          IF ((ln_cnt > 0) AND
              (lv_bf_base_code_par <> l_cur_rec.base_code_par)) THEN
            debug(
               buff   => '���_�R�[�h���Ⴂ�܂��B :' ||'�O��F '|| lv_bf_base_code_par || ''||
                          '����F' || l_cur_rec.base_code_par
            );
          -- =================================================
          -- A-3-4,A-4-4,A-5-4,A-6-4,A-7-4.���[�N�e�[�u���֏o��
          -- =================================================
          insert_wrk_table(
             ir_m_tab            => l_get_month_square_tab                      -- ���ו����R�[�h
            ,ir_hon_tab          => l_get_month_square_hon_tab                  -- �{�̕����R�[�h
            ,in_m_cnt            => ln_m_cnt                                    -- ���ו��s��
            ,in_report_output_no => ln_report_output_no                         -- ���[�o�̓Z�b�g�ԍ�
            ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          -- ���R�[�h�̏�����
          l_get_month_square_tab.DELETE;
          l_get_month_square_hon_tab.DELETE;
          init_month_square_hon_tab(l_get_month_square_hon_tab);
          -- �J�E���^���ɂP�𑫂�
          ln_report_output_no := ln_report_output_no + 1; -- �o�͂��ꂽ���[���Ɂ{�P����
          lb_boolean          := TRUE;                    -- ���������̏�Ԃɖ߂�
          ln_m_cnt            := 1;                       -- ���ו��z��̍s���̏�����
          END IF;
          -- ���������̏ꍇ
          IF(lb_boolean) THEN
            -- �Ɩ��n�R�[�h�����[�J���ϐ��Ɋi�[
            lv_bf_base_code_par         := l_cur_rec.base_code_par;        -- �Ζ��n���_�R�[�h(�e)(���_�R�[�h)
            lv_bf_base_code_chi         := l_cur_rec.base_code_chi;        -- �Ζ��n���_�R�[�h
            -- ���[�J�����R�[�h�Ɋi�[
            -- �Ζ��n���_�R�[�h(�e)(���_�R�[�h)
            l_month_square_rec.base_code_par     := l_cur_rec.base_code_par;
            -- �Ζ��n���_��(�e)(���_�R�[�h)
            l_month_square_rec.base_name_par     := l_cur_rec.base_name_par;
            -- �Ζ��n���_�R�[�h
            l_month_square_rec.base_code_chi     := l_cur_rec.base_code_chi;
            -- �Ζ��n���_��
            l_month_square_rec.base_name_chi     := l_cur_rec.base_name_chi;
            -- �V�K�ڋq����
            l_month_square_rec.cust_new_num      := l_cur_rec.cust_new_num;
            -- �V�KVD����
            l_month_square_rec.cust_vd_new_num   := l_cur_rec.cust_vd_new_num;
            -- �V�KVD�ȊO����
            l_month_square_rec.cust_other_new_num := l_cur_rec.cust_other_new_num;
            -- �O�N����
            l_month_square_rec.rslt_amty         := l_cur_rec.rslt_amty;
            -- �O�N���сiVD�j
            l_month_square_rec.rslt_vd_amty      := l_cur_rec.rslt_vd_amty;
            -- �O�N���сiVD�ȊO�j�j
            l_month_square_rec.rslt_other_amty   := l_cur_rec.rslt_other_amty;
            -- �挎����
            l_month_square_rec.rslt_amtm         := l_cur_rec.rslt_amtm;
            -- �挎���сiVD�j
            l_month_square_rec.rslt_vd_amtm      := l_cur_rec.rslt_vd_amtm;
            -- �挎���сiVD�ȊO
            l_month_square_rec.rslt_other_amtm   := l_cur_rec.rslt_other_amtm;
            -- ���ʔ���\�Z
            l_month_square_rec.tgt_sales_prsn_total_amt := l_cur_rec.tgt_sales_prsn_total_amt;
            lb_boolean := FALSE;                  -- ���������̃t���O���I�t����B
            -- DEBUG���b�Z�[�W
            -- ���������̏ꍇ
            debug(
               buff   => '���������t���O:' || 'FALSE'
            );
          END IF;
          -- ���t���擾
          ln_date := TO_NUMBER(SUBSTR(l_cur_rec.sales_date,7,2));
          -- DEBUG���b�Z�[�W
          -- ���������̏ꍇ
          debug(
             buff   => '���t:' || l_cur_rec.sales_date || cv_lf ||
                       '���t���̃i���o�[�^:'     || TO_CHAR(ln_date)
          );
          l_month_square_rec.l_one_day_tab(ln_date).rslt_amt
            := l_cur_rec.rslt_amt;              -- �������
          l_month_square_rec.l_one_day_tab(ln_date).rslt_new_amt
            := l_cur_rec.rslt_new_amt;          -- ������сi�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_vd_new_amt
            := l_cur_rec.rslt_vd_new_amt;       -- ������сiVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_vd_amt
            := l_cur_rec.rslt_vd_amt;           -- ������сiVD�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_other_new_amt
            := l_cur_rec.rslt_other_new_amt;    -- ������сiVD�ȊO�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_other_amt
            := l_cur_rec.rslt_other_amt;        -- ������сiVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_center_amt
            := l_cur_rec.rslt_center_amt;       -- �������_�Q�������
          l_month_square_rec.l_one_day_tab(ln_date).rslt_center_vd_amt
            := l_cur_rec.rslt_center_vd_amt;    -- �������_�Q������сiVD�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_center_other_amt
            := l_cur_rec.rslt_center_other_amt; -- �������_�Q������сiVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_num
            := l_cur_rec.vis_num;               -- �K�����
          l_month_square_rec.l_one_day_tab(ln_date).vis_new_num
            := l_cur_rec.vis_new_num;           -- �K����сi�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_vd_new_num
            := l_cur_rec.vis_vd_new_num;        -- �K����сiVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_vd_num
            := l_cur_rec.vis_vd_num;            -- �K����сiVD�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_other_new_num
            := l_cur_rec.vis_other_new_num;     -- �K����сiVD�ȊO�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_other_num
            := l_cur_rec.vis_other_num;         -- �K����сiVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_mc_num
            := l_cur_rec.vis_mc_num;            -- �K����сiMC
          l_month_square_rec.l_one_day_tab(ln_date).vis_sales_num
            := l_cur_rec.vis_sales_num;         -- �L������
          -- A0Z�K�⌏��
          l_month_square_rec.l_one_day_tab(ln_date).vis_a_num := nvl(l_cur_rec.vis_a_num,0);  -- �K��A����
          l_month_square_rec.l_one_day_tab(ln_date).vis_b_num := nvl(l_cur_rec.vis_b_num,0);  -- �K��B����
          l_month_square_rec.l_one_day_tab(ln_date).vis_c_num := nvl(l_cur_rec.vis_c_num,0);  -- �K��C����
          l_month_square_rec.l_one_day_tab(ln_date).vis_d_num := nvl(l_cur_rec.vis_d_num,0);  -- �K��D����
          l_month_square_rec.l_one_day_tab(ln_date).vis_e_num := nvl(l_cur_rec.vis_e_num,0);  -- �K��E����
          l_month_square_rec.l_one_day_tab(ln_date).vis_f_num := nvl(l_cur_rec.vis_f_num,0);  -- �K��F����
          l_month_square_rec.l_one_day_tab(ln_date).vis_g_num := nvl(l_cur_rec.vis_g_num,0);  -- �K��G����
          l_month_square_rec.l_one_day_tab(ln_date).vis_h_num := nvl(l_cur_rec.vis_h_num,0);  -- �K��H����
          l_month_square_rec.l_one_day_tab(ln_date).vis_i_num := nvl(l_cur_rec.vis_i_num,0);  -- �K��I����
          l_month_square_rec.l_one_day_tab(ln_date).vis_j_num := nvl(l_cur_rec.vis_j_num,0);  -- �K��J����
          l_month_square_rec.l_one_day_tab(ln_date).vis_k_num := nvl(l_cur_rec.vis_k_num,0);  -- �K��K����
          l_month_square_rec.l_one_day_tab(ln_date).vis_l_num := nvl(l_cur_rec.vis_l_num,0);  -- �K��L����
          l_month_square_rec.l_one_day_tab(ln_date).vis_m_num := nvl(l_cur_rec.vis_m_num,0);  -- �K��M����
          l_month_square_rec.l_one_day_tab(ln_date).vis_n_num := nvl(l_cur_rec.vis_n_num,0);  -- �K��N����
          l_month_square_rec.l_one_day_tab(ln_date).vis_o_num := nvl(l_cur_rec.vis_o_num,0);  -- �K��O����
          l_month_square_rec.l_one_day_tab(ln_date).vis_p_num := nvl(l_cur_rec.vis_p_num,0);  -- �K��P����
          l_month_square_rec.l_one_day_tab(ln_date).vis_q_num := nvl(l_cur_rec.vis_q_num,0);  -- �K��Q����
          l_month_square_rec.l_one_day_tab(ln_date).vis_r_num := nvl(l_cur_rec.vis_r_num,0);  -- �K��R����
          l_month_square_rec.l_one_day_tab(ln_date).vis_s_num := nvl(l_cur_rec.vis_s_num,0);  -- �K��S����
          l_month_square_rec.l_one_day_tab(ln_date).vis_t_num := nvl(l_cur_rec.vis_t_num,0);  -- �K��T����
          l_month_square_rec.l_one_day_tab(ln_date).vis_u_num := nvl(l_cur_rec.vis_u_num,0);  -- �K��U����
          l_month_square_rec.l_one_day_tab(ln_date).vis_v_num := nvl(l_cur_rec.vis_v_num,0);  -- �K��V����
          l_month_square_rec.l_one_day_tab(ln_date).vis_w_num := nvl(l_cur_rec.vis_w_num,0);  -- �K��W����
          l_month_square_rec.l_one_day_tab(ln_date).vis_x_num := nvl(l_cur_rec.vis_x_num,0);  -- �K��X����
          l_month_square_rec.l_one_day_tab(ln_date).vis_y_num := nvl(l_cur_rec.vis_y_num,0);  -- �K��Y����
          l_month_square_rec.l_one_day_tab(ln_date).vis_z_num := nvl(l_cur_rec.vis_z_num,0);  -- �K��Z����
          -- �ŏ��̃��R�[�h�̏ꍇ
          IF(lb_boolean) THEN
            lb_boolean              := FALSE;                  -- ���������̃t���O���I�t����B
          END IF;
          -- ���o�����J�E���^�ɂP�𑫂��B
          ln_cnt := ln_cnt + 1;
          gn_target_cnt  := ln_cnt;
          -- loop����
          debug(
                buff   => 'loop����' || TO_CHAR(ln_cnt)
          );
        END LOOP;
        -- �Ō�̃f�[�^�o�^
        IF (ln_cnt > 0) THEN
          debug(
                buff   => '�Ō�̃f�[�^�̓o�^'
          );
          -- =================================================
          -- A-6-2,A-6-3.PLSQL�\�̍X�V
          -- =================================================
          up_plsql_tab4(
             i_month_square_rec   => l_month_square_rec          -- �ꃖ�����f�[�^
            ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
            ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
            ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
            ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          -- =================================================
          -- A-3-4,A-4-4,A-5-4,A-6-4,A-7-4.���[�N�e�[�u���֏o��
          -- =================================================
          insert_wrk_table(
             ir_m_tab            => l_get_month_square_tab                      -- ���ו����R�[�h
            ,ir_hon_tab          => l_get_month_square_hon_tab                  -- �{�̕����R�[�h
            ,in_m_cnt            => ln_m_cnt                                    -- ���ו��s��
            ,in_report_output_no => ln_report_output_no                         -- ���[�o�̓Z�b�g�ԍ�
            ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          -- ���b�Z�[�W�o��
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_08         --���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_table             --�g�[�N���R�[�h1
                          ,iv_token_value1 => cv_tab_samari            --�g�[�N���l1
                          ,iv_token_name2  => cv_tkn_errmsg            --�g�[�N���R�[�h�Q
                          ,iv_token_value2 => SQLERRM                  --�g�[�N���l�Q
          );
          fnd_file.put_line(
                which  => FND_FILE.LOG,
                buff   => ''      || cv_lf ||     -- ��s�̑}��
                        lv_errmsg || cv_lf || 
                         ''                         -- ��s�̑}��
          );
          RAISE global_api_expt;
      END;
    -- �J�[�\���N���[�Y
    CLOSE ticket_data_cur;
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
  END get_ticket4;
--

  /**********************************************************************************
   * Procedure Name   : up_plsql_tab5
   * Description      : ���[���5-�n��c�Ɩ{���ʕ�-PLSQL�\�̍X�V (A-7-3)
  ***********************************************************************************/
  PROCEDURE up_plsql_tab5(
     i_month_square_rec  IN               g_month_rtype5                     -- �ꃖ�����f�[�^
    ,in_m_cnt            IN               NUMBER                             -- ���ו��̃J�E���^
    ,io_m_tab            IN OUT NOCOPY    g_get_month_square_ttype           -- ���ו��z��
    ,io_hon_tab          IN OUT NOCOPY    g_get_month_square_ttype           -- �{�̕��z��
    ,ov_errbuf           OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'up_plsql_tab5';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    lv_gvm_type           VARCHAR2(1);                                       -- ��ʁ^���̋@�^�l�b
    ln_m_cnt              NUMBER(9);                                         -- IN�p�����[�^���i�[
    BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
      ln_m_cnt                            := in_m_cnt;                       -- IN�p�����[�^���i�[
      -- DEBUG���b�Z�[�W
      -- PL/SQL�\�̍X�V
      debug(
         buff   => '�n��c�Ɩ{��-PL/SQL�\�̍X�V����:' || TO_CHAR(ln_m_cnt)
      );
      BEGIN
        -- ����グ���ו�
        io_m_tab(ln_m_cnt).up_base_code     := i_month_square_rec.base_code_par;       -- ���_�R�[�h�i�e)
        io_m_tab(ln_m_cnt).up_hub_name      := i_month_square_rec.base_name_par;       -- ���_���́i�e�j
        io_m_tab(ln_m_cnt).base_code        := i_month_square_rec.base_code_chi;       -- �Ɩ��n���_�R�[�h
        io_m_tab(ln_m_cnt).hub_name         := i_month_square_rec.base_name_chi;       -- �Ɩ��n���_��  
        io_m_tab(ln_m_cnt).last_year_rslt_sales_amt :=i_month_square_rec.rslt_amty; -- �O�N����
        io_m_tab(ln_m_cnt).last_mon_rslt_sales_amt  :=i_month_square_rec.rslt_amtm; -- �挎����
        io_m_tab(ln_m_cnt).new_customer_num :=i_month_square_rec.cust_new_num;      -- �ڋq����
        io_m_tab(ln_m_cnt).new_vendor_num   :=i_month_square_rec.cust_vd_new_num;   -- �ڋq�����iVD �V�K�j
        io_m_tab(ln_m_cnt).plan_sales_amt   := i_month_square_rec.tgt_sales_prsn_total_amt;  -- ���ʔ���\�Z
        -- DEBUG���b�Z�[�W
        -- PL/SQL�\�̍X�V
        debug(
           buff   => '�n��c�Ɩ{��-PL/SQL�\�̍X�V����' || '����グ���ו��Œ蕔����'
        );
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(
           which  => FND_FILE.LOG,
           buff   => '�n��c�Ɩ{��-PL/SQL�\�̍X�V�������s:' || SQLERRM 
          );
          RAISE global_api_others_expt;
      END;
      -- �{�̕�
      <<get_hontai_loop>>
      FOR i IN 1..cn_idx_max LOOP 
        IF(i = cn_idx_sales_ippn) THEN         --����グ���v��
          io_hon_tab(i).gvm_type                 := cv_gvm_g;                              -- ���
        ELSIF(i = cn_idx_sales_vd) THEN      --����グ���v��
          io_hon_tab(i).gvm_type                 := cv_gvm_v;                              -- ���̋@
        ELSIF(i = cn_idx_sales_sum) THEN      -- ����グ���v��
          NULL;
        ELSIF(i=cn_idx_visit_ippn)THEN       --�K�⒆�v��
          io_hon_tab(i).gvm_type                 := cv_gvm_g;                              -- ���
        ELSIF(i=cn_idx_visit_vd)THEN       --�K�⒆�v��
          io_hon_tab(i).gvm_type                 := cv_gvm_v;                              -- ���̋@
        ELSIF(i=cn_idx_visit_mc)THEN       --�K�⒆�v��
          io_hon_tab(i).gvm_type                 := cv_gvm_m;                              -- MC
        END IF;
        io_hon_tab(i).up_base_code   := i_month_square_rec.base_code_par;  -- ���_�R�[�h�i�e)
        io_hon_tab(i).up_hub_name    := i_month_square_rec.base_name_par;  -- ���_���́i�e�j
      END LOOP get_hontai_loop;
--
      -- ���㒆�v��(���)
      io_hon_tab(cn_idx_sales_ippn).last_year_rslt_sales_amt := 
        io_hon_tab(cn_idx_sales_ippn).last_year_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_other_amty, 0);    -- �O�N����
      io_hon_tab(cn_idx_sales_ippn).last_mon_rslt_sales_amt  :=
        io_hon_tab(cn_idx_sales_ippn).last_mon_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_other_amtm, 0);    -- �挎����
      io_hon_tab(cn_idx_sales_ippn).new_customer_num :=
        io_hon_tab(cn_idx_sales_ippn).new_customer_num +
        NVL(i_month_square_rec.cust_other_new_num, 0); -- �ڋq�����i�V�K�j�i��ʁj
      -- ���㒆�v��(���̋@)
      io_hon_tab(cn_idx_sales_vd).last_year_rslt_sales_amt :=
        io_hon_tab(cn_idx_sales_vd).last_year_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_vd_amty, 0);       -- �O�N����
      io_hon_tab(cn_idx_sales_vd).last_mon_rslt_sales_amt :=
        io_hon_tab(cn_idx_sales_vd).last_mon_rslt_sales_amt +
        NVL(i_month_square_rec.rslt_vd_amtm, 0);       -- �挎����
      io_hon_tab(cn_idx_sales_vd).new_customer_num :=
        io_hon_tab(cn_idx_sales_vd).new_customer_num +
        NVL(i_month_square_rec.cust_vd_new_num, 0);    -- �ڋq�����i�V�K�j(���̋@)
--
      <<get_all_day_data_loop>>
      FOR i IN 1..31 LOOP
        BEGIN
          -- DEBUG���b�Z�[�W
            -- PL/SQL�\�̍X�V
            debug(
               buff   => '�n��c�Ɩ{��-PL/SQL�\�̍X�V����' || '1�������̃f�[�^�X�V'
            );
          -- ����グ���ו�
          io_m_tab(ln_m_cnt).l_get_one_day_tab(i).rslt_vs_amt
            := i_month_square_rec.l_one_day_tab(i).rslt_amt;                 -- ����グ����
          io_m_tab(ln_m_cnt).l_get_one_day_tab(i).rslt_other_sales_amt
            := i_month_square_rec.l_one_day_tab(i).rslt_center_amt;          -- �������_�Q�������
          -- ����グ���v��(���)
          io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_other_amt,0);       -- �������,�K�����
          io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_other_sales_amt :=
            io_hon_tab(cn_idx_sales_ippn).l_get_one_day_tab(i).rslt_other_sales_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_center_other_amt,0);-- �������_�Q�������
          -- ����グ���v��(���̋@)
          io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_vd_amt,0);          -- �������,�K�����
          io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_other_sales_amt :=
            io_hon_tab(cn_idx_sales_vd).l_get_one_day_tab(i).rslt_other_sales_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).rslt_center_vd_amt,0);   -- �������_�Q�������
          -- ����グ���v��
          -- �K�⒆�v��(���)
          io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_visit_ippn).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_other_num,0);        -- �������,�K�����
          -- �K�⒆�v��(���̋@)
          io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_visit_vd).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_vd_num,0);           -- �������,�K�����
          -- �K�⒆�v��(MC)
          io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).rslt_vs_amt :=
            io_hon_tab(cn_idx_visit_mc).l_get_one_day_tab(i).rslt_vs_amt + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_mc_num,0);            -- �������,�K�����
          -- �K�⍇�v��
          io_hon_tab(cn_idx_visit_sum).l_get_one_day_tab(i).effective_num :=
            io_hon_tab(cn_idx_visit_sum).l_get_one_day_tab(i).effective_num + 
            NVL(i_month_square_rec.l_one_day_tab(i).vis_sales_num,0);        -- �L������
          -- �K����e���v��
          io_hon_tab(cn_idx_visit_dsc).vis_a_num := 
             io_hon_tab(cn_idx_visit_dsc).vis_a_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_a_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_b_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_b_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_b_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_c_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_c_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_c_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_d_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_d_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_d_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_e_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_e_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_e_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_f_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_f_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_f_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_g_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_g_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_g_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_h_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_h_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_h_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_i_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_i_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_i_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_j_num := 
             io_hon_tab(cn_idx_visit_dsc).vis_j_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_j_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_k_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_k_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_k_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_l_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_l_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_l_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_m_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_m_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_m_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_n_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_n_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_n_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_o_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_o_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_o_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_p_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_p_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_p_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_q_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_q_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_q_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_r_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_r_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_r_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_s_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_s_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_s_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_t_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_t_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_t_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_u_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_u_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_u_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_v_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_v_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_v_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_w_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_w_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_w_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_x_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_x_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_x_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_y_num :=   
             io_hon_tab(cn_idx_visit_dsc).vis_y_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_y_num,0);
          io_hon_tab(cn_idx_visit_dsc).vis_z_num :=  
             io_hon_tab(cn_idx_visit_dsc).vis_z_num + NVL(i_month_square_rec.l_one_day_tab(i).vis_z_num,0);
        EXCEPTION
          WHEN OTHERS THEN
          fnd_file.put_line(
             which  => FND_FILE.LOG,
             buff   => '�n��c�Ɩ{��-PL/SQL�\-�{�̕��̍X�V�����ŃG���[�ɂȂ�܂����B' || SQLERRM ||
                      ''                         -- ��s�̑}��
          );
          RAISE global_api_others_expt;
        END;
      END LOOP get_all_day_data_loop;
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
  END up_plsql_tab5;
--
  /**********************************************************************************
   * Procedure Name   : get_ticket5
   * Description      : ���[���5-�n��c�Ɩ{���� (A-7-1,A-7-2)
  ***********************************************************************************/
  PROCEDURE get_ticket5(
    ov_errbuf         OUT NOCOPY VARCHAR2           -- �G���[�E���b�Z�[�W            --# �Œ� #
   ,ov_retcode        OUT NOCOPY VARCHAR2           -- ���^�[���E�R�[�h              --# �Œ� #
   ,ov_errmsg         OUT NOCOPY VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
  -- ===============================
  -- �Œ胍�[�J���萔
  -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'get_ticket5';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ���[�J���萔
    -- ���[�J���ϐ�
    lb_boolean            BOOLEAN;      -- ���f�p
    ln_m_cnt              NUMBER(9);    -- ���ו��J�E���^�[���i�[
    ln_cnt                NUMBER(9);    -- ���o���ꂽ���R�[�h����
    ln_date               NUMBER(2);    -- ���t�̃i���o�[�^
    ln_report_output_no   NUMBER(9);    -- ���[�o�̓Z�b�g�ԍ�
    lv_bf_base_code_par   xxcso_aff_base_level_v.base_code%TYPE;
    lv_bf_base_code_chi   xxcso_aff_base_level_v.child_base_code%TYPE;
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR ticket_data_cur
    IS
      SELECT
              xablv.base_code             base_code_par,          -- �Ζ��n���_�R�[�h(�e)(���_�R�[�h)
              xabvpar.base_name           base_name_par,          -- �Ζ��n���_��(�e)
              xablv.child_base_code       base_code_chi,          -- �Ζ��n���_�R�[�h
              xabvchi.base_name           base_name_chi,          -- �Ζ��n���_��
              xsvsr.sales_date            sales_date,             -- �̔��N����
              xsvsr.rslt_amt              rslt_amt,               -- �������
              xsvsr.rslt_new_amt          rslt_new_amt,           -- ������сi�V�K�j
              xsvsr.rslt_vd_new_amt       rslt_vd_new_amt,        -- ������сiVD�F�V�K�j
              xsvsr.rslt_vd_amt           rslt_vd_amt,            -- ������сiVD�j
              xsvsr.rslt_other_new_amt    rslt_other_new_amt,     -- ������сiVD�ȊO�F�V�K�j
              xsvsr.rslt_other_amt        rslt_other_amt,         -- ������сiVD�ȊO�j
              xsvsr.rslt_center_amt       rslt_center_amt,        -- �������_�Q�������
              xsvsr.rslt_center_vd_amt    rslt_center_vd_amt,     -- �������_�Q������сiVD�j
              xsvsr.rslt_center_other_amt rslt_center_other_amt,  -- �������_�Q������сiVD�ȊO�j
              xsvsr.vis_num               vis_num,                -- �K�����
              xsvsr.vis_new_num           vis_new_num,            -- �K����сi�V�K�j
              xsvsr.vis_vd_new_num        vis_vd_new_num,         -- �K����сiVD�F�V�K�j
              xsvsr.vis_vd_num            vis_vd_num,             -- �K����сiVD�j
              xsvsr.vis_other_new_num     vis_other_new_num,      -- �K����сiVD�ȊO�F�V�K�j
              xsvsr.vis_other_num         vis_other_num,          -- �K����сiVD�ȊO�j
              xsvsr.vis_mc_num            vis_mc_num,             -- �K����сiMC�j
              xsvsr.vis_sales_num         vis_sales_num,          -- �L������
              xsvsr.vis_a_num             vis_a_num,              -- �K��`����
              xsvsr.vis_b_num             vis_b_num,              -- �K��a����
              xsvsr.vis_c_num             vis_c_num,              -- �K��b����
              xsvsr.vis_d_num             vis_d_num,              -- �K��c����
              xsvsr.vis_e_num             vis_e_num,              -- �K��d����
              xsvsr.vis_f_num             vis_f_num,              -- �K��e����
              xsvsr.vis_g_num             vis_g_num,              -- �K��f����
              xsvsr.vis_h_num             vis_h_num,              -- �K��g����
              xsvsr.vis_i_num             vis_i_num,              -- �K���@����
              xsvsr.vis_j_num             vis_j_num,              -- �K��i����
              xsvsr.vis_k_num             vis_k_num,              -- �K��j����
              xsvsr.vis_l_num             vis_l_num,              -- �K��k����
              xsvsr.vis_m_num             vis_m_num,              -- �K��l����
              xsvsr.vis_n_num             vis_n_num,              -- �K��m����
              xsvsr.vis_o_num             vis_o_num,              -- �K��n����
              xsvsr.vis_p_num             vis_p_num,              -- �K��o����
              xsvsr.vis_q_num             vis_q_num,              -- �K��p����
              xsvsr.vis_r_num             vis_r_num,              -- �K��q����
              xsvsr.vis_s_num             vis_s_num,              -- �K��r����
              xsvsr.vis_t_num             vis_t_num,              -- �K��s����
              xsvsr.vis_u_num             vis_u_num,              -- �K��t����
              xsvsr.vis_v_num             vis_v_num,              -- �K��u����
              xsvsr.vis_w_num             vis_w_num,              -- �K��v����
              xsvsr.vis_x_num             vis_x_num,              -- �K��w����
              xsvsr.vis_y_num             vis_y_num,              -- �K��x����
              xsvsr.vis_z_num             vis_z_num,              -- �K��y����
              xsvsry.rslt_amt             rslt_amty,              -- �O�N����
              xsvsry.rslt_vd_amt          rslt_vd_amty,           -- �O�N���сiVD�j
              xsvsry.rslt_other_amt       rslt_other_amty,        -- �O�N���сiVD�ȊO�j
              xsvsrm.rslt_amt             rslt_amtm,              -- �挎����
              xsvsrm.rslt_vd_amt          rslt_vd_amtm,           -- �挎���сiVD�j
              xsvsrm.rslt_other_amt       rslt_other_amtm,        -- �挎���сiVD�ȊO�j
              xsvsrn.cust_new_num         cust_new_num,           -- �ڋq�����i�V�K�j
              xsvsrn.cust_vd_new_num      cust_vd_new_num,        -- �ڋq�����iVD�F�V�K�j
              xsvsrn.cust_other_new_num   cust_other_new_num,     -- �ڋq�����iVD�ȊO�F�V�K�j
              xsvsrn.tgt_sales_prsn_total_amt  tgt_sales_prsn_total_amt  -- ���ʔ���\�Z
      FROM    xxcso_aff_base_level_v      xablv         -- AFF����K�w�}�X�^�r���[
             ,xxcso_aff_base_v2           xabvpar       -- AFF����}�X�^�i�ŐV�j�r���[(�e)
             ,xxcso_aff_base_v2           xabvchi       -- AFF����}�X�^�i�ŐV�j�r���[(�q)
             ,xxcso_sum_visit_sale_rep    xsvsr         -- �K�┄��v��Ǘ��\�T�}���e�[�u��
             ,xxcso_sum_visit_sale_rep    xsvsry        -- �K�┄��v��Ǘ��\�T�}���O�N
             ,xxcso_sum_visit_sale_rep    xsvsrm        -- �K�┄��v��Ǘ��\�T�}���挎
             ,xxcso_sum_visit_sale_rep    xsvsrn        -- �K�┄��v��Ǘ��\�T�}������
      WHERE   xablv.base_code = gv_base_code
        AND   xablv.child_base_code = xsvsr.sum_org_code
        AND   xablv.base_code = xabvpar.base_code
        AND   xablv.child_base_code = xabvchi.base_code
        AND   xsvsr.sum_org_type = cv_sum_org_type5
        AND   xsvsr.month_date_div = cv_month_date_div2
        AND   xsvsr.sales_date
                BETWEEN TO_CHAR(gd_year_month_day,'YYYYMMDD') AND TO_CHAR(gd_year_month_lastday,'YYYYMMDD')
        AND   xsvsr.sum_org_type   = xsvsry.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsry.sum_org_code(+)
        AND   xsvsry.month_date_div(+)= cv_month_date_div1
        AND   xsvsry.sales_date(+) = gv_year_prev
        AND   xsvsr.sum_org_type   = xsvsrm.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsrm.sum_org_code(+)
        AND   xsvsrm.month_date_div(+)= cv_month_date_div1
        AND   xsvsrm.sales_date(+) = gv_year_month_prev
        AND   xsvsr.sum_org_type   = xsvsrn.sum_org_type(+)
        AND   xsvsr.sum_org_code   = xsvsrn.sum_org_code(+)
        AND   xsvsrn.month_date_div(+)= cv_month_date_div1
        AND   xsvsrn.sales_date(+) = gv_year_month
      ORDER BY  base_code_chi     ASC;
    -- ���[�J�����R�[�h
    -- ���[�ϐ��i�[�p
    l_cur_rec                  ticket_data_cur%ROWTYPE;
    l_month_square_rec         g_month_rtype5;
    l_get_month_square_tab     g_get_month_square_ttype;
    l_get_month_square_hon_tab g_get_month_square_ttype;
    BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
      -- ���[�J���ϐ�������
      lb_boolean                := TRUE;        -- �����������f
      ln_m_cnt                  := 1;           -- ���ו��̍s��
      ln_report_output_no       := 1;           -- �z��s��
      ln_cnt                    := 0;           -- LOOP����
      -- PL/SQL�\�i�{�̕��j�̏�����
      init_month_square_hon_tab(l_get_month_square_hon_tab);
      -- ���[�J�����R�[�h�̏�����
      init_month_square_rec5(l_month_square_rec);
      BEGIN
      --�J�[�\���I�[�v��
      OPEN ticket_data_cur;
--
DO_ERROR('A-7-2-1');
--
      <<get_data_loop>>
      LOOP 
          l_cur_rec                           := NULL;          -- �J�[�\�����R�[�h�̏�����
--
          FETCH ticket_data_cur INTO l_cur_rec;                 -- �J�[�\���̃f�[�^�����R�[�h�Ɋi�[
--
        -- �Ώی�����O���̏ꍇ
        EXIT WHEN ticket_data_cur%NOTFOUND
          OR  ticket_data_cur%ROWCOUNT = 0;
--
DO_ERROR('A-7-2-2');
--
          debug(
            buff   => l_cur_rec.base_code_par                         ||','||
                      l_cur_rec.base_name_par                         ||','||
                      l_cur_rec.base_code_chi                         ||','||
                      l_cur_rec.base_name_chi                         ||','||
                      l_cur_rec.sales_date                            ||','||
                      TO_CHAR(l_cur_rec.rslt_amt)                     ||','||
                      TO_CHAR(l_cur_rec.rslt_new_amt)                 ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_new_amt)              ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_amt)                  ||','||
                      TO_CHAR(l_cur_rec.rslt_other_new_amt)           ||','||
                      TO_CHAR(l_cur_rec.rslt_other_amt)               ||','||
                      TO_CHAR(l_cur_rec.rslt_center_amt)              ||','||
                      TO_CHAR(l_cur_rec.rslt_center_vd_amt)           ||','||
                      TO_CHAR(l_cur_rec.rslt_center_other_amt)        ||','||
                      TO_CHAR(l_cur_rec.vis_num)                      ||','||
                      TO_CHAR(l_cur_rec.vis_new_num)                  ||','||
                      TO_CHAR(l_cur_rec.vis_vd_new_num)               ||','||
                      TO_CHAR(l_cur_rec.vis_vd_num)                   ||','||
                      TO_CHAR(l_cur_rec.vis_other_new_num)            ||','||
                      TO_CHAR(l_cur_rec.vis_other_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_mc_num)                   ||','||
                      TO_CHAR(l_cur_rec.vis_sales_num)                ||','||
                      TO_CHAR(l_cur_rec.vis_a_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_b_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_c_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_d_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_e_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_f_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_g_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_h_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_i_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_j_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_k_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_l_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_m_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_n_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_o_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_p_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_q_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_r_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_s_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_t_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_u_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_v_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_w_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_x_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_y_num)                    ||','||
                      TO_CHAR(l_cur_rec.vis_z_num)                    ||','||
                      TO_CHAR(l_cur_rec.rslt_amty)                    ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_amty)                 ||','||
                      TO_CHAR(l_cur_rec.rslt_other_amty)              ||','||
                      TO_CHAR(l_cur_rec.rslt_amtm)                    ||','||
                      TO_CHAR(l_cur_rec.rslt_vd_amtm)                 ||','||
                      TO_CHAR(l_cur_rec.rslt_other_amtm)              ||','||
                      TO_CHAR(l_cur_rec.cust_new_num)                 ||','||
                      TO_CHAR(l_cur_rec.cust_vd_new_num)              ||','||
                      TO_CHAR(l_cur_rec.cust_other_new_num)           ||','||
                      TO_CHAR(l_cur_rec.tgt_sales_prsn_total_amt)     ||','||
                     cv_lf 
          );
          -- �O�񃌃R�[�h�Ƌ��_�R�[�h�������ŋƖ��n�R�[�h���Ⴄ�ꍇ�A���ו��z��Ɩ{�̕��z����X�V�B
          IF(lb_boolean=FALSE) THEN
            IF((lv_bf_base_code_par = l_cur_rec.base_code_par)AND(lv_bf_base_code_chi <> l_cur_rec.base_code_chi))
              THEN
              -- DEBUG���b�Z�[�W
              debug(
                 buff   => '�Ɩ��n�R�[�h���Ⴂ�܂��B :' ||'�O��F '|| lv_bf_base_code_chi ||
                            '����F' || l_cur_rec.base_code_chi ||
                            '���ו��z��' || TO_CHAR(ln_m_cnt)
              );
              -- =================================================
              -- A-7-2,A-7-3.PLSQL�\�̍X�V
              -- =================================================
              up_plsql_tab5(
                 i_month_square_rec   => l_month_square_rec          -- �ꃖ�����f�[�^
                ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
                ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
                ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
                ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
                ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
                ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
              l_month_square_rec.l_one_day_tab.DELETE;
              l_month_square_rec     := NULL;
              init_month_square_rec5(l_month_square_rec);
              ln_m_cnt          := ln_m_cnt + 1;       -- ���ו��z����{�P����B
              lb_boolean        := TRUE;               -- ���������̃t���O�I������B
            ELSIF(lv_bf_base_code_par <> l_cur_rec.base_code_par) THEN
              -- =================================================
              -- A-7-2,A-7-3.PLSQL�\�̍X�V
              -- =================================================
              up_plsql_tab5(
                 i_month_square_rec   => l_month_square_rec          -- �ꃖ�����f�[�^
                ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
                ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
                ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
                ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
                ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
                ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
              );
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
              l_month_square_rec.l_one_day_tab.DELETE;
              l_month_square_rec     := NULL;
              init_month_square_rec5(l_month_square_rec);
              lb_boolean        := TRUE;               -- ���������̃t���O�I������B
            END IF;
          END IF;
          -- ���_�R�[�h���O��擾�������_�R�[�h�ƈႤ�ꍇ���[�N�e�[�u���ɏo�͂��܂��B
          IF ((ln_cnt > 0) AND
              (lv_bf_base_code_par <> l_cur_rec.base_code_par)) THEN
            debug(
               buff   => '���_�R�[�h���Ⴂ�܂��B :' ||'�O��F '|| lv_bf_base_code_par || ''||
                          '����F' || l_cur_rec.base_code_par
            );
          -- =================================================
          -- A-3-4,A-4-4,A-5-4,A-6-4,A-7-4.���[�N�e�[�u���֏o��
          -- =================================================
          insert_wrk_table(
             ir_m_tab            => l_get_month_square_tab                      -- ���ו����R�[�h
            ,ir_hon_tab          => l_get_month_square_hon_tab                  -- �{�̕����R�[�h
            ,in_m_cnt            => ln_m_cnt                                    -- ���ו��s��
            ,in_report_output_no => ln_report_output_no                         -- ���[�o�̓Z�b�g�ԍ�
            ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          -- ���R�[�h�̏�����
          l_get_month_square_tab.DELETE;
          l_get_month_square_hon_tab.DELETE;
          init_month_square_hon_tab(l_get_month_square_hon_tab);
          -- �J�E���^���ɂP�𑫂�
          ln_report_output_no := ln_report_output_no + 1; -- �o�͂��ꂽ���[���Ɂ{�P����
          lb_boolean          := TRUE;                    -- ���������̏�Ԃɖ߂�
          ln_m_cnt            := 1;                       -- ���ו��z��̍s���̏�����
          END IF;
          -- ���������̏ꍇ
          IF(lb_boolean) THEN
            -- �Ɩ��n�R�[�h�����[�J���ϐ��Ɋi�[
            lv_bf_base_code_par         := l_cur_rec.base_code_par;        -- �Ζ��n���_�R�[�h(�e)(���_�R�[�h)
            lv_bf_base_code_chi         := l_cur_rec.base_code_chi;        -- �Ζ��n���_�R�[�h
            -- ���[�J�����R�[�h�Ɋi�[
            -- �Ζ��n���_�R�[�h(�e)(���_�R�[�h)
            l_month_square_rec.base_code_par     := l_cur_rec.base_code_par;
            -- �Ζ��n���_��(�e)(���_�R�[�h)
            l_month_square_rec.base_name_par     := l_cur_rec.base_name_par;
            -- �Ζ��n���_�R�[�h
            l_month_square_rec.base_code_chi     := l_cur_rec.base_code_chi;
            -- �Ζ��n���_��
            l_month_square_rec.base_name_chi     := l_cur_rec.base_name_chi;
            -- �V�K�ڋq����
            l_month_square_rec.cust_new_num      := l_cur_rec.cust_new_num;
            -- �V�KVD����
            l_month_square_rec.cust_vd_new_num   := l_cur_rec.cust_vd_new_num;
            -- �V�KVD�ȊO����
            l_month_square_rec.cust_other_new_num := l_cur_rec.cust_other_new_num;
            -- �O�N����
            l_month_square_rec.rslt_amty         := l_cur_rec.rslt_amty;
            -- �O�N���сiVD�j
            l_month_square_rec.rslt_vd_amty      := l_cur_rec.rslt_vd_amty;
            -- �O�N���сiVD�ȊO�j�j
            l_month_square_rec.rslt_other_amty   := l_cur_rec.rslt_other_amty;
            -- �挎����
            l_month_square_rec.rslt_amtm         := l_cur_rec.rslt_amtm;
            -- �挎���сiVD�j
            l_month_square_rec.rslt_vd_amtm      := l_cur_rec.rslt_vd_amtm;
            -- �挎���сiVD�ȊO
            l_month_square_rec.rslt_other_amtm   := l_cur_rec.rslt_other_amtm;
            -- ���ʔ���\�Z
            l_month_square_rec.tgt_sales_prsn_total_amt := l_cur_rec.tgt_sales_prsn_total_amt;
            lb_boolean := FALSE;
            -- DEBUG���b�Z�[�W
            -- ���������̏ꍇ
            debug(
               buff   => '���������t���O:' || 'FALSE'
            );
          END IF;
          -- ���t���擾
          ln_date := TO_NUMBER(SUBSTR(l_cur_rec.sales_date,7,2));
          -- DEBUG���b�Z�[�W
          -- ���������̏ꍇ
          debug(
             buff   => '���t:' || l_cur_rec.sales_date || cv_lf ||
                       '���t���̃i���o�[�^:'     || TO_CHAR(ln_date)
          );
          l_month_square_rec.l_one_day_tab(ln_date).rslt_amt              
            := l_cur_rec.rslt_amt;              -- �������
          l_month_square_rec.l_one_day_tab(ln_date).rslt_new_amt          
            := l_cur_rec.rslt_new_amt;          -- ������сi�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_vd_new_amt       
            := l_cur_rec.rslt_vd_new_amt;       -- ������сiVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_vd_amt           
            := l_cur_rec.rslt_vd_amt;           -- ������сiVD�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_other_new_amt    
            := l_cur_rec.rslt_other_new_amt;    -- ������сiVD�ȊO�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_other_amt        
            := l_cur_rec.rslt_other_amt;        -- ������сiVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_center_amt       
            := l_cur_rec.rslt_center_amt;       -- �������_�Q�������
          l_month_square_rec.l_one_day_tab(ln_date).rslt_center_vd_amt       
            := l_cur_rec.rslt_center_vd_amt;    -- �������_�Q������сiVD�j
          l_month_square_rec.l_one_day_tab(ln_date).rslt_center_other_amt       
            := l_cur_rec.rslt_center_other_amt; -- �������_�Q������сiVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_num               
            := l_cur_rec.vis_num;               -- �K�����
          l_month_square_rec.l_one_day_tab(ln_date).vis_new_num           
            := l_cur_rec.vis_new_num;           -- �K����сi�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_vd_new_num        
            := l_cur_rec.vis_vd_new_num;        -- �K����сiVD�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_vd_num            
            := l_cur_rec.vis_vd_num;            -- �K����сiVD�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_other_new_num     
            := l_cur_rec.vis_other_new_num;     -- �K����сiVD�ȊO�F�V�K�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_other_num         
            := l_cur_rec.vis_other_num;         -- �K����сiVD�ȊO�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_mc_num         
            := l_cur_rec.vis_mc_num;            -- �K����сiMC�j
          l_month_square_rec.l_one_day_tab(ln_date).vis_sales_num         
            := l_cur_rec.vis_sales_num;         -- �L������
          -- A0Z�K�⌏��
          l_month_square_rec.l_one_day_tab(ln_date).vis_a_num := nvl(l_cur_rec.vis_a_num,0);  -- �K��A����
          l_month_square_rec.l_one_day_tab(ln_date).vis_b_num := nvl(l_cur_rec.vis_b_num,0);  -- �K��B����
          l_month_square_rec.l_one_day_tab(ln_date).vis_c_num := nvl(l_cur_rec.vis_c_num,0);  -- �K��C����
          l_month_square_rec.l_one_day_tab(ln_date).vis_d_num := nvl(l_cur_rec.vis_d_num,0);  -- �K��D����
          l_month_square_rec.l_one_day_tab(ln_date).vis_e_num := nvl(l_cur_rec.vis_e_num,0);  -- �K��E����
          l_month_square_rec.l_one_day_tab(ln_date).vis_f_num := nvl(l_cur_rec.vis_f_num,0);  -- �K��F����
          l_month_square_rec.l_one_day_tab(ln_date).vis_g_num := nvl(l_cur_rec.vis_g_num,0);  -- �K��G����
          l_month_square_rec.l_one_day_tab(ln_date).vis_h_num := nvl(l_cur_rec.vis_h_num,0);  -- �K��H����
          l_month_square_rec.l_one_day_tab(ln_date).vis_i_num := nvl(l_cur_rec.vis_i_num,0);  -- �K��I����
          l_month_square_rec.l_one_day_tab(ln_date).vis_j_num := nvl(l_cur_rec.vis_j_num,0);  -- �K��J����
          l_month_square_rec.l_one_day_tab(ln_date).vis_k_num := nvl(l_cur_rec.vis_k_num,0);  -- �K��K����
          l_month_square_rec.l_one_day_tab(ln_date).vis_l_num := nvl(l_cur_rec.vis_l_num,0);  -- �K��L����
          l_month_square_rec.l_one_day_tab(ln_date).vis_m_num := nvl(l_cur_rec.vis_m_num,0);  -- �K��M����
          l_month_square_rec.l_one_day_tab(ln_date).vis_n_num := nvl(l_cur_rec.vis_n_num,0);  -- �K��N����
          l_month_square_rec.l_one_day_tab(ln_date).vis_o_num := nvl(l_cur_rec.vis_o_num,0);  -- �K��O����
          l_month_square_rec.l_one_day_tab(ln_date).vis_p_num := nvl(l_cur_rec.vis_p_num,0);  -- �K��P����
          l_month_square_rec.l_one_day_tab(ln_date).vis_q_num := nvl(l_cur_rec.vis_q_num,0);  -- �K��Q����
          l_month_square_rec.l_one_day_tab(ln_date).vis_r_num := nvl(l_cur_rec.vis_r_num,0);  -- �K��R����
          l_month_square_rec.l_one_day_tab(ln_date).vis_s_num := nvl(l_cur_rec.vis_s_num,0);  -- �K��S����
          l_month_square_rec.l_one_day_tab(ln_date).vis_t_num := nvl(l_cur_rec.vis_t_num,0);  -- �K��T����
          l_month_square_rec.l_one_day_tab(ln_date).vis_u_num := nvl(l_cur_rec.vis_u_num,0);  -- �K��U����
          l_month_square_rec.l_one_day_tab(ln_date).vis_v_num := nvl(l_cur_rec.vis_v_num,0);  -- �K��V����
          l_month_square_rec.l_one_day_tab(ln_date).vis_w_num := nvl(l_cur_rec.vis_w_num,0);  -- �K��W����
          l_month_square_rec.l_one_day_tab(ln_date).vis_x_num := nvl(l_cur_rec.vis_x_num,0);  -- �K��X����
          l_month_square_rec.l_one_day_tab(ln_date).vis_y_num := nvl(l_cur_rec.vis_y_num,0);  -- �K��Y����
          l_month_square_rec.l_one_day_tab(ln_date).vis_z_num := nvl(l_cur_rec.vis_z_num,0);  -- �K��Z����
          -- �ŏ��̃��R�[�h�̏ꍇ
          IF(lb_boolean) THEN
            lb_boolean              := FALSE;                  -- ���������̃t���O���I�t����B
          END IF;
          -- ���o�����J�E���^�ɂP�𑫂��B
          ln_cnt := ln_cnt + 1;
          gn_target_cnt  := ln_cnt;
          -- loop����
          debug(
                buff   => 'loop����' || TO_CHAR(ln_cnt)
          );
        END LOOP;
        -- �Ō�̃f�[�^�o�^
        IF (ln_cnt > 0) THEN
          debug(
                buff   => '�Ō�̃f�[�^�̓o�^'
          );
          -- =================================================
          -- A-7-2,A-7-3.PLSQL�\�̍X�V
          -- =================================================
          up_plsql_tab5(
            i_month_square_rec   => l_month_square_rec          -- �ꃖ�����f�[�^
           ,in_m_cnt             => ln_m_cnt                    -- ���ו��̃J�E���^
           ,io_m_tab             => l_get_month_square_tab      -- ���ו��z��
           ,io_hon_tab           => l_get_month_square_hon_tab  -- �{�̕��z��
           ,ov_errbuf            => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
           ,ov_retcode           => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
           ,ov_errmsg            => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          -- =================================================
          -- A-3-4,A-4-4,A-5-4,A-6-4,A-7-4.���[�N�e�[�u���֏o��
          -- =================================================
          insert_wrk_table(
             ir_m_tab            => l_get_month_square_tab                      -- ���ו����R�[�h
            ,ir_hon_tab          => l_get_month_square_hon_tab                  -- �{�̕����R�[�h
            ,in_m_cnt            => ln_m_cnt                                    -- ���ו��s��
            ,in_report_output_no => ln_report_output_no                         -- ���[�o�̓Z�b�g�ԍ�
            ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
           );
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          -- ���b�Z�[�W�o��
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                          ,iv_name         => cv_tkn_number_08         --���b�Z�[�W�R�[�h
                          ,iv_token_name1  => cv_tkn_table             --�g�[�N���R�[�h1
                          ,iv_token_value1 => cv_tab_samari            --�g�[�N���l1
                          ,iv_token_name2  => cv_tkn_errmsg            --�g�[�N���R�[�h�Q
                          ,iv_token_value2 => SQLERRM                  --�g�[�N���l�Q
          );
          fnd_file.put_line(
                which  => FND_FILE.LOG,
                buff   => ''      || cv_lf ||     -- ��s�̑}��
                        lv_errmsg || cv_lf || 
                         ''                         -- ��s�̑}��
          );
          RAISE global_api_expt;
      END;
    -- �J�[�\���N���[�Y
    CLOSE ticket_data_cur;
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
  END get_ticket5;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF�N������ (A-8)
   ***********************************************************************************/
  PROCEDURE act_svf(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'act_svf'; -- �v���O������
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
    cv_svf_api_name    CONSTANT VARCHAR2(50) := 'SVF�N��';     -- SVF�N��API��
--
    -- *** ���[�J���ϐ� ***
    lv_svf_file_name   VARCHAR2(100);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
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
    -- �t�@�C�����̐ݒ�
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR(cd_creation_date, 'YYYYMMDD')
                     || TO_CHAR(cn_request_id);
--
      BEGIN
        SELECT  user_concurrent_program_name,
                xx00_global_pkg.user_name   ,
                xx00_global_pkg.resp_name
        INTO    lv_conc_name,
                lv_user_name,
                lv_resp_name
        FROM    fnd_concurrent_programs_tl
        WHERE   concurrent_program_id =cn_request_id
        AND     LANGUAGE = 'JA'
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_conc_name := cv_pkg_name;
      END;
      
      lv_file_id := cv_pkg_name;
--
-- ���[�T�[�o���㎞�ɗL����
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_errbuf       => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,ov_retcode      => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
      ,ov_errmsg       => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ,iv_conc_name    => lv_conc_name         -- �R���J�����g��
      ,iv_file_name    => lv_svf_file_name     -- �o�̓t�@�C����
      ,iv_file_id      => lv_file_id           -- ���[ID
      ,iv_output_mode  => '1'                  -- �o�͋敪(=1�FPDF�o�́j
      ,iv_frm_file     => gv_svf_form_name     -- �t�H�[���l���t�@�C����
      ,iv_vrq_file     => gv_svf_query_name    -- �N�G���[�l���t�@�C����
      ,iv_org_id       => fnd_global.org_id    -- ORG_ID
      ,iv_user_name    => lv_user_name         -- ���O�C���E���[�U��
      ,iv_resp_name    => lv_resp_name         -- ���O�C���E���[�U�̐E�Ӗ�
      ,iv_doc_name     => NULL                 -- ������
      ,iv_printer_name => NULL                 -- �v�����^��
      ,iv_request_id   => cn_request_id        -- �v��ID
      ,iv_nodata_msg   => NULL                 -- �f�[�^�Ȃ����b�Z�[�W
    );
--
DO_ERROR('A-8');
--
    debug(
       buff   => 'SVF�N������ (A-8)'
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_app_name              --�A�v���P�[�V�����Z�k��
                             ,iv_name         => cv_tkn_number_09         --���b�Z�[�W�R�[�h
                             ,iv_token_name1  => cv_tkn_api_name          --�g�[�N���R�[�h1
                             ,iv_token_value1 => cv_svf_api_name          --�uSVF�N���v
                   );
      lv_errbuf := lv_errmsg;
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
  END act_svf;
--
  /**********************************************************************************
   * Procedure Name   : del_wrk_tbl_data                                                                         
   * Description      : ���[�N�e�[�u���f�[�^�폜 (A-9)
   ***********************************************************************************/
  PROCEDURE del_wrk_tbl_data(
    ov_errbuf               OUT NOCOPY VARCHAR2,         -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode              OUT NOCOPY VARCHAR2,         -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg               OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name              CONSTANT VARCHAR2(100)    := 'del_wrk_tbl_data';         -- �v���O������
    cv_table_name            CONSTANT VARCHAR2(100)    := '�K�┄��v��Ǘ��\���[���[�N�e�[�u��';
      -- �K�┄��v��Ǘ��\���[���[�N�e�[�u����
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf   VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
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
    -- *** ���[�J���E��O ***
    del_tbl_data_expt     EXCEPTION;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
    -- *******************************************************
    -- ***  �K�┄��v��Ǘ��\���[���[�N�e�[�u���f�[�^�폜 ***
    -- *******************************************************
--TODO �P�̃e�X�g�I�����ɗL����
    BEGIN
      IF ( CB_DO_DELETE ) THEN
        DELETE
        FROM  xxcso_rep_visit_sale_plan
        WHERE request_id = cn_request_id;
        debug(
           buff   => '���[�N�e�[�u���f�[�^�폜���s (A-9)'
        );
      ELSE
        debug(
           buff   => '���[�N�e�[�u���f�[�^�폜���s�X�L�b�v (A-9)'
        );
      END IF;
--
    EXCEPTION
      -- *** OTHERS��O�n���h�� ***
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�쐬
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- �A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_10              -- ���b�Z�[�W�R�[�h �f�[�^�폜�G���[
                       ,iv_token_name1  => cv_tkn_table                  -- �g�[�N���R�[�h1
                       ,iv_token_value1 => cv_table_name                 -- �G���[�����̃e�[�u����
                       ,iv_token_name2  => cv_tkn_errmsg                 -- �g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                       -- ORACLE�G���[
                      );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE del_tbl_data_expt;
    END;
--
DO_ERROR('A-9');
--
  EXCEPTION
    -- *** �f�[�^�폜���̗�O�n���h�� ***
    WHEN del_tbl_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END del_wrk_tbl_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     iv_year_month        IN        VARCHAR2   -- ��N��
    ,iv_report_type       IN        VARCHAR2   -- ���[���
    ,iv_base_code         IN        VARCHAR2   -- ���_�R�[�h
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
        -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_year_month      VARCHAR2(6);     -- ��N��
    lv_report_type     VARCHAR2(9);     -- ���[���
    lv_base_code       VARCHAR2(9);     -- ���_�R�[�h
    -- SVF�N��API�߂�l�i�[�p
    lv_errbuf_svf      VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode_svf     VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg_svf      VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- OUT�p�����[�^�i�[�p
    -- ���b�Z�[�W�o�͗p
    lv_msg               VARCHAR2(2000);

    -- *** ���[�J���E���R�[�h ***
    -- *** ���[�J����O ***
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
    gd_online_sysdate     := XXCSO_UTIL_COMMON_PKG.GET_ONLINE_SYSDATE();
    gv_online_sysdate     := TO_CHAR(gd_online_sysdate,'YYYYMMDD');
    gn_target_cnt         := 0;
    gn_normal_cnt         := 0;
    gn_error_cnt          := 0;
    gn_warn_cnt           := 0;
    lv_year_month         := iv_year_month;
    lv_report_type        := iv_report_type;
    lv_base_code          := iv_base_code;
--
  -- ========================================
  -- A-1.�������� 
  -- ========================================
    init(
       iv_year_month => lv_year_month     -- ��N��
      ,iv_report_type=> lv_report_type    -- ���[���
      ,iv_base_code  => lv_base_code      -- ���_�R�[�h
      ,ov_errbuf     => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode    => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg     => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
  -- ======================================
  -- A-2.�p�����[�^�`�F�b�N 
  -- =======================================
    chek_param(
       ov_errbuf     => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode    => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg     => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
DO_ERROR('submain');
--
    IF (gv_report_type = cv_report_1) THEN
      -- ======================================
      -- A-3-1,A-3-2.���[���1-�c�ƈ��� 
      -- ======================================
      get_ticket1(
         ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    ELSIF (gv_report_type = cv_report_2) THEN
      -- ======================================
      -- A-4-1,A-4-2 ���[���2-�c�ƈ��O���[�v�� 
      -- ======================================
      get_ticket2(
         ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    ELSIF (gv_report_type = cv_report_3) THEN
      -- ======================================
      -- A-5-1,A-5-2 ���[���3-���_/�ە�
      -- ======================================
      get_ticket3(
         ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    ELSIF (gv_report_type = cv_report_4) THEN
      -- ======================================
      -- A-6-1,A-6-2 ���[���4-�n��c�ƕ���
      -- ======================================
      get_ticket4(
         ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    ELSIF (gv_report_type = cv_report_5) THEN
      -- ======================================
      -- A-7-1,A-7-2 ���[���5-�n��c�Ɩ{����
      -- ======================================
      get_ticket5(
         ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- �����Ώۃf�[�^��0���̏ꍇ
    IF gn_target_cnt = 0 THEN
      -- 0�����b�Z�[�W�o��
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_tkn_number_11    --���b�Z�[�W�R�[�h
                   );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg                                 --���[�U�[�E�G���[���b�Z�[�W
      );
      RETURN;
    END IF;
--
    -- ======================================
    -- A-8 SVF�N��
    -- ======================================
    act_svf(
       ov_errbuf    => lv_errbuf_svf     -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode_svf    -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg_svf     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    -- ======================================
    -- A-9 ���[�N�e�[�u���f�[�^�폜
    -- ======================================
    del_wrk_tbl_data(
       ov_errbuf    => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode   => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg    => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ======================================
    -- A-10 SVF�N��API�G���[�`�F�b�N
    -- ======================================
    IF (lv_retcode_svf = cv_status_error) THEN
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
      RAISE global_process_expt;
    END IF;
--
--
--#################################  �Œ��O������ START   ####################################
--
    EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode           OUT NOCOPY VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_year_month     IN         VARCHAR2          -- ��N��
   ,iv_report_type    IN         VARCHAR2          -- ���[���
   ,iv_base_code      IN         VARCHAR2          -- ���_�R�[�h
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
    lv_errbuf          VARCHAR2(4000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(4000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    lv_year_month      VARCHAR2(6);     -- ��N��
    lv_report_type     VARCHAR2(9);     -- ���[���
    lv_base_code       VARCHAR2(9);     -- ���_�R�[�h
--
  BEGIN
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
    lv_year_month      := iv_year_month;
    lv_report_type     := iv_report_type;
    lv_base_code       := iv_base_code;
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_year_month    => lv_year_month     -- ��N��
      ,iv_report_type   => lv_report_type    -- ���[���
      ,iv_base_code     => lv_base_code      -- ���_�R�[�h
      ,ov_errbuf        => lv_errbuf         -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode       => lv_retcode        -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg        => lv_errmsg         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
DO_ERROR('main');
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --�G���[���b�Z�[�W
       );
    END IF;
--
    -- =======================
    -- A-11.�I������ 
    -- =======================
    --��s�̏o��
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      --�G���[�o��
      fnd_file.put_line(
        which  => FND_FILE.LOG
       ,buff   => errbuf                  --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
        which  => FND_FILE.LOG
       ,buff   => cv_pkg_name||cv_msg_cont||
                  cv_prg_name||cv_msg_part||
                  errbuf                  --�G���[���b�Z�[�W
      );
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      --�G���[�o��
      fnd_file.put_line(
        which  => FND_FILE.LOG
       ,buff   => errbuf                  --���[�U�[�E�G���[���b�Z�[�W
      );
      fnd_file.put_line(
        which  => FND_FILE.LOG
       ,buff   => cv_pkg_name||cv_msg_cont||
                  cv_prg_name||cv_msg_part||
                  errbuf                  --�G���[���b�Z�[�W
      );
  END main;
--
--###########################  �Œ蕔 END   #######################################################
END XXCSO019A05C;
/
