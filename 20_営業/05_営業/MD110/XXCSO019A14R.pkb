CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A14R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO019A14R(body)
 * Description      : �w�肵���N���i1�������j�̖K��v��i�K���ڋq���j�����[�gNo���ޕʁA
 *                     �j���ʂ�PDF�֏o�͂��܂��B
 *                    �ڋq�̃��[�gNo�����L�̕��ނ��Ƃɂ܂Ƃ߁A�T�ԖK��񐔂̑������[�g���A
 *                     �ڋq�R�[�h���ɕ\�����܂��B
 *                    ���[�g���ޕʂɉ��זK�⌬�����o�͂��܂��B
 *                    �j���ʂɖK�⌬���A�O��������z�̍��v���o�͂��܂��B
 * MD.050           : MD050_CSO_019_A14_�ڋq�����Ǘ��\
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  ins_upd_lines          �z��̒ǉ��A�X�V(A-3)
 *  insert_row             ���[�N�e�[�u���f�[�^�o�^(A-4)
 *  act_svf                SVF�N��(A-5)
 *  delete_row             ���[�N�e�[�u���f�[�^�폜(A-6)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018-06-14    1.0   K.Kiriu          �V�K�쐬(E_�{�ғ�_14971)
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO019A14R';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  -- ���t����
  cv_format_date_ym      CONSTANT VARCHAR2(6)   := 'YYYYMM';      -- ���t�t�H�[�}�b�g�i�N���j
  cv_format_date_ymd     CONSTANT VARCHAR2(8)   := 'YYYYMMDD';    -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_get_day      CONSTANT VARCHAR2(2)   := 'DY';          -- �j���擾�p�t�H�[�}�b�g
  -- ���b�Z�[�W�R�[�h
  cv_msg_param_base      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00130';  -- �p�����[�^�o��(���_�R�[�h)
  cv_msg_param_date      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00873';  -- �p�����[�^�o��(�Ώ۔N��)
  cv_msg_param_emp       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00842';  -- �p�����[�^�o��(�c�ƈ�)
  cv_msg_err_proc_date   CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00011';  -- �Ɩ��������t�擾�G���[
  cv_msg_err_api         CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00135';  -- API�G���[
  cv_msg_db_del_err      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00872';  -- �폜�G���[
  cv_msg_db_ins_err      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00886';  -- �o�^�G���[
  cv_msg_no_data         CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00140';  -- ����0�����b�Z�[�W
  cv_msg_tbl_nm          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00885';  -- �ڋq�����Ǘ��\���[���[�N�e�[�u��(����)
  -- �g�[�N���R�[�h
  cv_tkn_entry           CONSTANT VARCHAR2(20)  := 'ENTRY';
  cv_thn_table           CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_api_nm          CONSTANT VARCHAR2(20)  := 'API_NAME';
  cv_tkn_count           CONSTANT VARCHAR2(20)  := 'COUNT';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20)  := 'ERROR_MESSAGE';
--
  cv_emp_dummy           CONSTANT VARCHAR2(1)   := '@';   -- �]�ƈ��R�[�h�̃_�~�[
--
  -- �y�[�W�����׍s��
  cn_max_line            CONSTANT NUMBER        := 68;
  --���[�gNo������
  cv_rt_num_hd_st        CONSTANT VARCHAR2(1)   := '0';   -- ���[�gNo������
  cv_rt_num_hd_end       CONSTANT VARCHAR2(1)   := '3';   -- ���[�gNo������
  cv_rt_num_hd_w_m       CONSTANT VARCHAR2(1)   := '5';   -- ���[�gNo������
  --���[�gNo�u�T�E��1����p
  cv_rt_num_mnth         CONSTANT VARCHAR2(1)   := '0';   -- ���[�gNo4����(���[�gNo��������5�̏ꍇ)
  --���[�gNo��
  cn_rt_length           CONSTANT NUMBER        := 7;     -- ���[�gNo����
  -- �K��񐔁i1�����j
  cn_visit_times_20      CONSTANT NUMBER        := 20;    -- ��20��(�T5�ȏ�)
  cn_visit_times_16      CONSTANT NUMBER        := 16;    -- ��16��(�T3��-TO)
  cn_visit_times_12      CONSTANT NUMBER        := 12;    -- ��12��(�T3��-FROM)
  cn_visit_times_8       CONSTANT NUMBER        := 8;     -- ��8��(�T2��)
  cn_visit_times_4       CONSTANT NUMBER        := 4;     -- ��4��(�T1��)
  cn_visit_times_2       CONSTANT NUMBER        := 2;     -- ��2��(�u�T1��)
  cn_visit_times_1       CONSTANT NUMBER        := 1;     -- ��1��(��1��)
  -- ���o���[�gNo���������򏈗��K��񐔐ݒ�p
  cn_dflt_vst_tm         CONSTANT NUMBER        := -999;
  -- �j���ԍ�
  cn_week_mon            CONSTANT NUMBER(1)     := 1;     -- ��
  cn_week_tue            CONSTANT NUMBER(1)     := 2;     -- ��
  cn_week_wed            CONSTANT NUMBER(1)     := 3;     -- ��
  cn_week_thu            CONSTANT NUMBER(1)     := 4;     -- ��
  cn_week_fri            CONSTANT NUMBER(1)     := 5;     -- ��
  cn_week_sat            CONSTANT NUMBER(1)     := 6;     -- �y
  cn_week_sun            CONSTANT NUMBER(1)     := 7;     -- ��
  cn_week_total          CONSTANT NUMBER(1)     := 8;     -- 1�T�ԍ��v
  --���[�g���ޔԍ�
  cn_route_grp_s         CONSTANT NUMBER(2)     := 1;     -- S����
  cn_route_grp_a         CONSTANT NUMBER(2)     := 2;     -- A����
  cn_route_grp_b         CONSTANT NUMBER(2)     := 3;     -- B����
  cn_route_grp_c         CONSTANT NUMBER(2)     := 4;     -- C����
  cn_route_grp_d         CONSTANT NUMBER(2)     := 5;     -- D����
  cn_route_grp_e         CONSTANT NUMBER(2)     := 6;     -- E����
  cn_route_grp_z         CONSTANT NUMBER(2)     := 99;    -- �o�͑ΏۊO
  -- ����擾����
  cv_month_div           CONSTANT VARCHAR2(1)   := '1';   -- ���ʌv��
  cv_org_type_cust       CONSTANT VARCHAR2(1)   := '1';    --�ڋq�^�C�v
  -- ���o�Ώۏ����i�K��敪�j
  cv_visit_target_posi   CONSTANT VARCHAR2(1)   := '1';   -- �ڋq�}�X�^.�K��Ώۋ敪�u1�v(�K��ΏہE���k��)
  cv_visit_target_imposi CONSTANT VARCHAR2(1)   := '2';   -- �ڋq�}�X�^.�K��Ώۋ敪�u2�v(�K��ΏہE���k�s��)
  cv_visit_target_vd     CONSTANT VARCHAR2(1)   := '5';   -- �ڋq�}�X�^.�K��Ώۋ敪�u5�v(�K��ΏہEVD)
  -- ���o�Ώۏ����i�ڋq�敪)
  cv_cstmr_cls_cd10      CONSTANT VARCHAR2(2)   := '10';  -- �ڋq�敪:10 (�ڋq)
  cv_cstmr_cls_cd15      CONSTANT VARCHAR2(2)   := '15';  -- �ڋq�敪:15 (����)
  cv_cstmr_cls_cd16      CONSTANT VARCHAR2(2)   := '16';  -- �ڋq�敪:16 (�≮������)
  -- ���o�Ώۏ����i�ڋq�X�e�[�^�X�j
  cv_cstmr_sttus25       CONSTANT VARCHAR2(2)   := '25';  -- �ڋq�X�e�[�^�X:25 (SP���ύ�)
  cv_cstmr_sttus30       CONSTANT VARCHAR2(2)   := '30';  -- �ڋq�X�e�[�^�X:30 (���F��)
  cv_cstmr_sttus40       CONSTANT VARCHAR2(2)   := '40';  -- �ڋq�X�e�[�^�X:40 (�ڋq)
  cv_cstmr_sttus50       CONSTANT VARCHAR2(2)   := '50';  -- �ڋq�X�e�[�^�X:50 (�x�~)
  cv_cstmr_sttus99       CONSTANT VARCHAR2(2)   := '99';  -- �ڋq�X�e�[�^�X:99 (�ΏۊO)
  -- �Q�ƃ^�C�v
  cv_lookup_type_dai     CONSTANT VARCHAR2(100) := 'XXCMM_CUST_GYOTAI_DAI';
  cv_lookup_type_chu     CONSTANT VARCHAR2(100) := 'XXCMM_CUST_GYOTAI_CHU';
  cv_lookup_type_syo     CONSTANT VARCHAR2(100) := 'XXCMM_CUST_GYOTAI_SHO';
  cv_lookup_type_route   CONSTANT VARCHAR2(100) := 'XXCSO1_ROUTE_CUST_NO_MNG';
  cv_flg_y               CONSTANT VARCHAR2(1)   := 'Y';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  --
  TYPE g_route_ttype      IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE g_week_ttype       IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE g_route_week_ttype IS TABLE OF g_week_ttype INDEX BY BINARY_INTEGER;
  -- ���t
  gd_process_date        DATE;                                           -- �Ɩ����t
  gv_pre_target_yyyymm   xxcso_sum_visit_sale_rep.sales_date%TYPE;       -- �O��
  gn_route_max_line      g_route_ttype;                                  -- ���[�g���ޕʖ��׍s��
  gn_route_start_line    g_route_ttype;                                  -- ���[�g���ޕʃy�[�W���o�͊J�n�ʒu
  -- ���v��
  gn_total_visit_count   xxcso_rep_cust_route_mng.total_count%TYPE;      -- �K�⑍����
  g_visit_count_tab      g_route_ttype;                                  -- ���זK�⌬���i���ޕ�(7)�j
  g_line_count_tab       g_route_week_ttype;                             -- ���׌����i���ޕ�(7)�~�j����(7)�j
  g_weekly_count_tab     g_week_ttype;                                   -- �j���v(����)�i�j����(8) 8��1�T�Ԍv�j
  g_weekly_amount_tab    g_week_ttype;                                   -- �j���v(���z)�i�j����(8) 8��1�T�Ԍv�j
  --���[�N�o�^�X�g�b�N��
  TYPE g_rep_cust_rt_mng_ttype IS TABLE OF xxcso_rep_cust_route_mng%ROWTYPE;
  g_rep_cust_rt_mng_tab    g_rep_cust_rt_mng_ttype;
  -- 
  gn_line_num            NUMBER(5);     --�s�ԍ�
  gn_total_page_no       NUMBER(5);     --�g�[�^���y�[�W�ԍ�
  gn_page_no             NUMBER(5);     --�J�����g�y�[�W�ԍ�
  gn_out_page_no         NUMBER(5);     --�o�͐�y�[�W�ԍ�
  gn_out_route_line_no   NUMBER(5);     --���[�g���ޘg���ʒu
  gn_out_line_no         NUMBER(5);     --�o�͐斾�׍s�ԍ�

  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
    -- �c�ƈ��ʗj���ʖK��\�� ���o�J�[�\�� (���_�w��)
    CURSOR get_prsn_dt_vst_pln_cur(
              iv_base_code        IN VARCHAR2   -- ���_�R�[�h
           )
    IS
      SELECT
               xrme.employee_number employee_number      -- �]�ƈ��R�[�h
              ,xrme.employee_name   employee_name        -- �]�ƈ���
              ,xca.account_number   account_number       -- �ڋq�R�[�h
              ,xca.party_name       party_name           -- �ڋq����
             ,( CASE 
                  WHEN SUBSTRB(xcr2.route_number,1,1) >= cv_rt_num_hd_st
                  AND  SUBSTRB(xcr2.route_number,1,1) <= cv_rt_num_hd_end    -- 1���ڂ�0�`3���T1��ȏ�K��
                  AND  LENGTHB(xcr2.route_number)      = cn_rt_length
                  THEN
                    CASE
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) >= cn_visit_times_20
                    THEN
                      cn_route_grp_s
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) >= cn_visit_times_12
                     AND xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) <= cn_visit_times_16
                    THEN
                      cn_route_grp_a
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) = cn_visit_times_8
                    THEN
                      cn_route_grp_b
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) = cn_visit_times_4
                    THEN
                      cn_route_grp_c
                    END
                  WHEN SUBSTRB(xcr2.route_number,1,1) = cv_rt_num_hd_w_m     -- 1���ڂ�5���u�T�E��1�K��
                  THEN
                    CASE
                      WHEN SUBSTRB(xcr2.route_number,4,1) <> cv_rt_num_mnth  -- 4���ڂ�0�ȊO���u�T�K��
                      AND  LENGTHB(xcr2.route_number)      = cn_rt_length
                      THEN
                        cn_route_grp_d
                      WHEN SUBSTRB(xcr2.route_number,4,1) = cv_rt_num_mnth   -- 4���ڂ�0����1�K��
                      AND  LENGTHB(xcr2.route_number)     = cn_rt_length
                      THEN
                        cn_route_grp_e
                      ELSE
                        cn_route_grp_z
                      END
                  ELSE
                    cn_route_grp_z
                  END
               )                     group_no            -- ���[�gNo���ޔԍ�
              ,(CASE
                WHEN SUBSTRB(xcr2.route_number,1,1) >= cv_rt_num_hd_st
                AND  SUBSTRB(xcr2.route_number,1,1) <= cv_rt_num_hd_end
                THEN
                  xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number)
                WHEN SUBSTRB(xcr2.route_number,1,1) = cv_rt_num_mnth
                THEN
                  xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number)
                ELSE
                  cn_dflt_vst_tm
                END
               ) visit_times                             -- �K���(�\�[�g�p)
              ,xcr2.route_number     route_number        -- ���[�gNo
              ,dai.meaning           business_high_name  -- �Ƒԑ啪��
      FROM     xxcso_cust_accounts_v        xca   -- �ڋq�}�X�^�r���[
              ,xxcso_resource_custs_v2      xrc2  -- �c�ƈ��S���ڋq�i�ŐV�j�r���[
              ,xxcso_cust_routes_v2         xcr2  -- �ڋq���[�gNo�i�ŐV�j�r���[
              ,xxcso_route_management_emp_v xrme  -- ���[�g�Ǘ��p�c�ƈ��Z�L�����e�B�r���[
              ,fnd_lookup_values_vl         sho   -- �Ƒԏ�����
              ,fnd_lookup_values_vl         chu   -- �ƑԒ�����
              ,fnd_lookup_values_vl         dai   -- �Ƒԑ啪��
      WHERE   xrc2.account_number     = xca.account_number
        AND   xcr2.party_id           = xca.party_id
        AND   xrc2.employee_number    = xrme.employee_number
        AND   xrme.employee_base_code = iv_base_code
        AND   xca.vist_target_div     IN (  cv_visit_target_posi
                                           ,cv_visit_target_imposi
                                           ,cv_visit_target_vd )
        AND   xcr2.route_number IS NOT NULL
        AND   (
                (
                  ( xca.customer_class_code = cv_cstmr_cls_cd10 )
                  AND
                  ( xca.customer_status IN (  cv_cstmr_sttus25
                                             ,cv_cstmr_sttus30
                                             ,cv_cstmr_sttus40
                                             ,cv_cstmr_sttus50 )
                  )
                )
                OR
                (
                  ( xca.customer_class_code  = cv_cstmr_cls_cd15 )
                  AND
                  ( xca.customer_status      = cv_cstmr_sttus99 )
                )
                OR
                (
                  ( xca.customer_class_code  = cv_cstmr_cls_cd16 )
                  AND
                  ( xca.customer_status      = cv_cstmr_sttus99 )
                )
              )
        AND   sho.lookup_type          = cv_lookup_type_syo
        AND   chu.lookup_type          = cv_lookup_type_chu
        AND   dai.lookup_type          = cv_lookup_type_dai
        AND   chu.lookup_code          = sho.attribute1
        AND   dai.lookup_code          = chu.attribute1
        AND   sho.enabled_flag         = cv_flg_y
        AND   chu.enabled_flag         = cv_flg_y
        AND   dai.enabled_flag         = cv_flg_y
        AND   NVL(sho.start_date_active, gd_process_date) <= gd_process_date
        AND   NVL(sho.end_date_active,   gd_process_date) >= gd_process_date
        AND   NVL(chu.start_date_active, gd_process_date) <= gd_process_date
        AND   NVL(chu.end_date_active,   gd_process_date) >= gd_process_date
        AND   NVL(dai.start_date_active, gd_process_date) <= gd_process_date
        AND   NVL(dai.end_date_active,   gd_process_date) >= gd_process_date
        AND   sho.lookup_code          = xca.business_low_type
        AND   NOT EXISTS (
                        SELECT 1
                        FROM   fnd_lookup_values_vl flvv  -- �ڋq�����Ǘ��\�ΏۊO���[�g
                        WHERE  flvv.lookup_type         = cv_lookup_type_route
                        AND    flvv.enabled_flag        = cv_flg_y
                        AND    NVL(flvv.start_date_active, gd_process_date) <= gd_process_date
                        AND    NVL(flvv.end_date_active,   gd_process_date) >= gd_process_date
                        AND    SUBSTRB(xcr2.route_number, TO_NUMBER(flvv.attribute1), TO_NUMBER(flvv.attribute2) ) = flvv.lookup_code
              )  -- �o�͑ΏۊO�̃��[�g�ȊO
      ORDER BY
         xrme.employee_number ASC
        ,group_no             ASC
        ,visit_times          DESC
        ,xca.account_number   ASC
    ;
--
    -- �c�ƈ��ʗj���ʖK��\�� ���o�J�[�\�� (�c�ƈ��w��)
    CURSOR get_prsn_dt_vst_pln_cur2(
              iv_base_code        IN VARCHAR2   -- ���_�R�[�h
             ,iv_employee_number  IN VARCHAR2   -- �]�ƈ��R�[�h
           )
    IS
      SELECT
               xrme.employee_number employee_number      -- �]�ƈ��R�[�h
              ,xrme.employee_name   employee_name        -- �]�ƈ���
              ,xca.account_number   account_number       -- �ڋq�R�[�h
              ,xca.party_name       party_name           -- �ڋq����
             ,( CASE 
                  WHEN SUBSTRB(xcr2.route_number,1,1) >= cv_rt_num_hd_st
                  AND  SUBSTRB(xcr2.route_number,1,1) <= cv_rt_num_hd_end    -- 1���ڂ�0�`3���T1��ȏ�K��
                  AND  LENGTHB(xcr2.route_number)      = cn_rt_length
                  THEN
                    CASE
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) >= cn_visit_times_20
                    THEN
                      cn_route_grp_s
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) >= cn_visit_times_12
                     AND xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) <= cn_visit_times_16
                    THEN
                      cn_route_grp_a
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) = cn_visit_times_8
                    THEN
                      cn_route_grp_b
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) = cn_visit_times_4
                    THEN
                      cn_route_grp_c
                    END
                  WHEN SUBSTRB(xcr2.route_number,1,1) = cv_rt_num_hd_w_m     -- 1���ڂ�5���u�T�E��1�K��
                  THEN
                    CASE
                      WHEN SUBSTRB(xcr2.route_number,4,1) <> cv_rt_num_mnth  -- 4���ڂ�0�ȊO���u�T�K��
                      AND  LENGTHB(xcr2.route_number)      = cn_rt_length
                      THEN
                        cn_route_grp_d
                      WHEN SUBSTRB(xcr2.route_number,4,1) = cv_rt_num_mnth   -- 4���ڂ�0����1�K��
                      AND  LENGTHB(xcr2.route_number)     = cn_rt_length
                      THEN
                        cn_route_grp_e
                      ELSE
                        cn_route_grp_z
                      END
                  ELSE
                    cn_route_grp_z
                  END
               )                     group_no            -- ���[�gNo���ޔԍ�
              ,(CASE
                WHEN SUBSTRB(xcr2.route_number,1,1) >= cv_rt_num_hd_st
                AND  SUBSTRB(xcr2.route_number,1,1) <= cv_rt_num_hd_end
                THEN
                  xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number)
                WHEN SUBSTRB(xcr2.route_number,1,1) = cv_rt_num_mnth
                THEN
                  xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number)
                ELSE
                  cn_dflt_vst_tm
                END
               ) visit_times                             -- �K���(�\�[�g�p)
              ,xcr2.route_number     route_number        -- ���[�gNo
              ,dai.meaning           business_high_name  -- �Ƒԑ啪��
      FROM     xxcso_cust_accounts_v        xca   -- �ڋq�}�X�^�r���[
              ,xxcso_resource_custs_v2      xrc2  -- �c�ƈ��S���ڋq�i�ŐV�j�r���[
              ,xxcso_cust_routes_v2         xcr2  -- �ڋq���[�gNo�i�ŐV�j�r���[
              ,xxcso_route_management_emp_v xrme  -- ���[�g�Ǘ��p�c�ƈ��Z�L�����e�B�r���[
              ,fnd_lookup_values_vl         sho   -- �Ƒԏ�����
              ,fnd_lookup_values_vl         chu   -- �ƑԒ�����
              ,fnd_lookup_values_vl         dai   -- �Ƒԑ啪��
      WHERE   xrc2.account_number     = xca.account_number
        AND   xcr2.party_id           = xca.party_id
        AND   xrc2.employee_number    = xrme.employee_number
        AND   xrme.employee_number    = iv_employee_number
        AND   xrme.employee_base_code = iv_base_code
        AND   xca.vist_target_div     IN (  cv_visit_target_posi
                                           ,cv_visit_target_imposi
                                           ,cv_visit_target_vd )
        AND   xcr2.route_number IS NOT NULL
        AND   (
                (
                  ( xca.customer_class_code = cv_cstmr_cls_cd10 )
                  AND
                  ( xca.customer_status IN (  cv_cstmr_sttus25
                                             ,cv_cstmr_sttus30
                                             ,cv_cstmr_sttus40
                                             ,cv_cstmr_sttus50 )
                  )
                )
                OR
                (
                  ( xca.customer_class_code  = cv_cstmr_cls_cd15 )
                  AND
                  ( xca.customer_status      = cv_cstmr_sttus99 )
                )
                OR
                (
                  ( xca.customer_class_code  = cv_cstmr_cls_cd16 )
                  AND
                  ( xca.customer_status      = cv_cstmr_sttus99 )
                )
              )
        AND   sho.lookup_type          = cv_lookup_type_syo
        AND   chu.lookup_type          = cv_lookup_type_chu
        AND   dai.lookup_type          = cv_lookup_type_dai
        AND   chu.lookup_code          = sho.attribute1
        AND   dai.lookup_code          = chu.attribute1
        AND   sho.enabled_flag         = cv_flg_y
        AND   chu.enabled_flag         = cv_flg_y
        AND   dai.enabled_flag         = cv_flg_y
        AND   NVL(sho.start_date_active, gd_process_date) <= gd_process_date
        AND   NVL(sho.end_date_active,   gd_process_date) >= gd_process_date
        AND   NVL(chu.start_date_active, gd_process_date) <= gd_process_date
        AND   NVL(chu.end_date_active,   gd_process_date) >= gd_process_date
        AND   NVL(dai.start_date_active, gd_process_date) <= gd_process_date
        AND   NVL(dai.end_date_active,   gd_process_date) >= gd_process_date
        AND   sho.lookup_code          = xca.business_low_type
        AND   NOT EXISTS (
                        SELECT 1
                        FROM   fnd_lookup_values_vl flvv  -- �ڋq�����Ǘ��\�ΏۊO���[�g
                        WHERE  flvv.lookup_type         = cv_lookup_type_route
                        AND    flvv.enabled_flag        = cv_flg_y
                        AND    NVL(flvv.start_date_active, gd_process_date) <= gd_process_date
                        AND    NVL(flvv.end_date_active,   gd_process_date) >= gd_process_date
                        AND    SUBSTRB(xcr2.route_number, TO_NUMBER(flvv.attribute1), TO_NUMBER(flvv.attribute2) ) = flvv.lookup_code
              )  -- �o�͑ΏۊO�̃��[�g�ȊO
      ORDER BY
         xrme.employee_number ASC
        ,group_no             ASC
        ,visit_times          DESC
        ,xca.account_number   ASC
    ;
--
    g_prsn_dt_vst_pln_rec  get_prsn_dt_vst_pln_cur%ROWTYPE;

  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_base_code        IN  VARCHAR2         -- ���_�R�[�h
    ,iv_target_yyyymm    IN  VARCHAR2         -- �Ώ۔N��
    ,iv_employee_number  IN  VARCHAR2         -- �]�ƈ��R�[�h
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'init';     -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- *** ���[�J���ϐ� ***
    -- ���b�Z�[�W�o�͗p
    lv_msg_bs_num   VARCHAR2(5000);
    lv_msg_stnd_dt  VARCHAR2(5000);
    lv_msg_emp_num  VARCHAR2(5000);
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
    -- ===========================
    -- 1.���̓p�����[�^�o��
    -- ===========================
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- ���b�Z�[�W�擾(���_�R�[�h)
    lv_msg_bs_num   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_param_base   --���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_entry        --�g�[�N���R�[�h1
                         ,iv_token_value1 => iv_base_code        --�g�[�N���l1
                       );
    -- ���b�Z�[�W�擾(�Ώ۔N��)
    lv_msg_stnd_dt  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_param_date   --���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_entry        --�g�[�N���R�[�h1
                         ,iv_token_value1 => iv_target_yyyymm    --�g�[�N���l1
                       );
    -- ���b�Z�[�W�擾(�]�ƈ��R�[�h)
    lv_msg_emp_num  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_msg_param_emp    --���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_entry        --�g�[�N���R�[�h1
                         ,iv_token_value1 => iv_employee_number  --�g�[�N���l1
                       );
--
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_bs_num
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_stnd_dt
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_emp_num
    );
--
    --==================================================
    -- 2.�Ɩ����t�̎擾
    --==================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --�Ɩ��������t�擾�`�F�b�N
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_proc_date
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================================
    -- 3.�O���擾(����擾�p)
    --==================================================
    gv_pre_target_yyyymm := TO_CHAR(ADD_MONTHS(TO_DATE(iv_target_yyyymm, cv_format_date_ym), -1), cv_format_date_ym);
--
    --==================================================
    -- 4.���[�g���ޕʖ��׏��ݒ�
    --==================================================
    --���[�g���ޕʖ��׍s��
    gn_route_max_line(1)  := 10;   -- S
    gn_route_max_line(2)  := 12;   -- A
    gn_route_max_line(3)  := 12;   -- B
    gn_route_max_line(4)  := 12;   -- C
    gn_route_max_line(5)  := 14;   -- D
    gn_route_max_line(6)  := 8;    -- E
    --���[�g���ޕʃy�[�W���J�n�s
    gn_route_start_line(1)  := 1;  -- S
    gn_route_start_line(2)  := 11; -- A
    gn_route_start_line(3)  := 23; -- B
    gn_route_start_line(4)  := 35; -- C
    gn_route_start_line(5)  := 47; -- D
    gn_route_start_line(6)  := 61; -- E
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
--
      ov_errmsg  := lv_errmsg;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_lines
   * Description      : �z��̒ǉ��A�X�V(A-3)
   ***********************************************************************************/
  PROCEDURE ins_upd_lines(
     in_group_no            IN  NUMBER           -- ���[�g���ޔԍ�
    ,in_week_no             IN  NUMBER           -- �j���ԍ�
    ,in_pre_sales_amount    IN  NUMBER           -- �O��������z
    ,ov_errbuf              OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'ins_upd_lines';     -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J����O ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -----------------------------------------------------
    -- ���v�X�V�i���z�A�����j
    -----------------------------------------------------
    -- �K�⑍����
    gn_total_visit_count                      := gn_total_visit_count + 1;
    -- ���זK�⌬���i���ޕʁj
    g_visit_count_tab(in_group_no)            := g_visit_count_tab(in_group_no) + 1;
    -- ���׌����i���ޕʁA�j���ʁj
    g_line_count_tab(in_group_no)(in_week_no) := g_line_count_tab(in_group_no)(in_week_no) + 1;
--
    -----------------------------------------------------
    -- �j���v�i�T�ԕʁA�j���v or 1�T�Ԍv�j�i�����A���z�j
    -----------------------------------------------------
    -- �j���v
    g_weekly_count_tab(in_week_no)            := g_weekly_count_tab(in_week_no)     + 1;
    g_weekly_amount_tab(in_week_no)           := g_weekly_amount_tab(in_week_no)    + in_pre_sales_amount;
    -- 1�T�Ԍv
    g_weekly_count_tab(cn_week_total)         := g_weekly_count_tab(cn_week_total)  + 1;
    g_weekly_amount_tab(cn_week_total)        := g_weekly_amount_tab(cn_week_total) + in_pre_sales_amount;
--
    -- ======================
    -- �o�͐斾�הԍ��̓��o�i�c�ƈ��ʖ��הԍ��j
    -- ======================
    --�o�͐�y�[�W�ԍ��Z�o
    gn_out_page_no := CEIL(g_line_count_tab(in_group_no)(in_week_no) / gn_route_max_line(in_group_no));
--
    --�g�[�^���y�[�W�ԍ��𒴂��Ă���ꍇ�̓��[�N�o�^�X�g�b�N��g��
    IF gn_out_page_no > gn_total_page_no THEN
      gn_total_page_no := gn_total_page_no + 1;
      g_rep_cust_rt_mng_tab.EXTEND(cn_max_line);
    END IF;
--
    --���[�g���ޘg���o�͈ʒu�Z�o
    IF MOD(g_line_count_tab(in_group_no)(in_week_no), gn_route_max_line(in_group_no)) = 0 THEN
      gn_out_route_line_no := gn_route_max_line(in_group_no);
    ELSE
      gn_out_route_line_no := MOD(g_line_count_tab(in_group_no)(in_week_no), gn_route_max_line(in_group_no));
    END IF;
--
    --�o�͐斾�הԍ��̎Z�o�i�c�ƈ��ʖ��הԍ��j
    gn_out_line_no := (gn_out_page_no - 1) * cn_max_line + gn_route_start_line(in_group_no) - 1 + gn_out_route_line_no;
--
    --�o�̓f�[�^�����[�N�o�^�X�g�b�N��ɐݒ肷��
    --���j���̏ꍇ
    IF in_week_no = cn_week_mon THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_mon := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_mon         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_mon  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_mon   := in_pre_sales_amount;
    --�Ηj���̏ꍇ
    ELSIF in_week_no = cn_week_tue THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_tue := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_tue         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_tue  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_tue   := in_pre_sales_amount;
    --���j���̏ꍇ
    ELSIF in_week_no = cn_week_wed THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_wed := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_wed         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_wed  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_wed   := in_pre_sales_amount;
    --�ؗj���̏ꍇ
    ELSIF in_week_no = cn_week_thu THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_thu := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_thu         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_thu  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_thu   := in_pre_sales_amount;
    --���j���̏ꍇ
    ELSIF in_week_no = cn_week_fri THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_fri := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_fri         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_fri  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_fri   := in_pre_sales_amount;
    --�y�j���̏ꍇ
    ELSIF in_week_no = cn_week_sat THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_sat := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_sat         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_sat  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_sat   := in_pre_sales_amount;
    --���j���̏ꍇ
    ELSIF in_week_no = cn_week_sun THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_sun := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_sun         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_sun  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_sun   := in_pre_sales_amount;
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
  END ins_upd_lines;
--
  /**********************************************************************************
   * Procedure Name   : insert_row
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-4)
   ***********************************************************************************/
  PROCEDURE insert_row(
     iv_base_code           IN  VARCHAR2            -- ���_�R�[�h
    ,iv_target_yyyymm       IN  VARCHAR2            -- �Ώ۔N��
    ,iv_employee_number     IN  VARCHAR2            -- �]�ƈ��R�[�h
    ,iv_employee_name       IN  VARCHAR2            -- �]�ƈ���
    ,ov_errbuf              OUT NOCOPY VARCHAR2     -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2     -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2     -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_row';     -- �v���O������
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
    -- *** ���[�J����O ***
    insert_row_expt     EXCEPTION;          -- ���[�N�e�[�u���o�͏�����O
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
      <<insert_row_loop>>
      FOR i IN g_rep_cust_rt_mng_tab.FIRST..g_rep_cust_rt_mng_tab.LAST LOOP
        --�s�ԍ��X�V
        gn_line_num := gn_line_num + 1;
        -- ======================
        -- ���[�N�e�[�u���f�[�^�o�^
        -- ======================
        INSERT INTO xxcso_rep_cust_route_mng xrcrm -- �ڋq�����Ǘ��\���[���[�N�e�[�u��
          ( line_num                        --�s�ԍ�
           ,output_date                     --�o�͓���
           ,target_mm                       --�Ώی�
           ,employee_number                 --�c�ƈ��R�[�h
           ,employee_name                   --�c�ƈ���
           ,account_number_mon              --���j��-�ڋq�R�[�h
           ,gyotai_mon                      --���j��-�Ƒ�
           ,customer_name_mon               --���j��-�ڋq��
           ,sales_amount_mon                --���j��-����
           ,account_number_tue              --�Ηj��-�ڋq�R�[�h
           ,gyotai_tue                      --�Ηj��-�Ƒ�
           ,customer_name_tue               --�Ηj��-�ڋq��
           ,sales_amount_tue                --�Ηj��-����
           ,account_number_wed              --���j��-�ڋq�R�[�h
           ,gyotai_wed                      --���j��-�Ƒ�
           ,customer_name_wed               --���j��-�ڋq��
           ,sales_amount_wed                --���j��-����
           ,account_number_thu              --�ؗj��-�ڋq�R�[�h
           ,gyotai_thu                      --�ؗj��-�Ƒ�
           ,customer_name_thu               --�ؗj��-�ڋq��
           ,sales_amount_thu                --�ؗj��-����
           ,account_number_fri              --���j��-�ڋq�R�[�h
           ,gyotai_fri                      --���j��-�Ƒ�
           ,customer_name_fri               --���j��-�ڋq��
           ,sales_amount_fri                --���j��-����
           ,account_number_sat              --�y�j��-�ڋq�R�[�h
           ,gyotai_sat                      --�y�j��-�Ƒ�
           ,customer_name_sat               --�y�j��-�ڋq��
           ,sales_amount_sat                --�y�j��-����
           ,account_number_sun              --���j��-�ڋq�R�[�h
           ,gyotai_sun                      --���j��-�Ƒ�
           ,customer_name_sun               --���j��-�ڋq��
           ,sales_amount_sun                --���j��-����
           ,total_count_s                   --���זK�⌬��_S����
           ,total_count_a                   --���זK�⌬��_A����
           ,total_count_b                   --���זK�⌬��_B����
           ,total_count_c                   --���זK�⌬��_C����
           ,total_count_d                   --���זK�⌬��_D����
           ,total_count_e                   --���זK�⌬��_E����
           ,total_count                     --���K�⌬��
           ,total_amount_mon                --���j��-������
           ,total_count_mon                 --���j��-������
           ,total_amount_tue                --�Ηj��-������
           ,total_count_tue                 --�Ηj��-������
           ,total_amount_wed                --���j��-������
           ,total_count_wed                 --���j��-������
           ,total_amount_thu                --�ؗj��-������
           ,total_count_thu                 --�ؗj��-������
           ,total_amount_fri                --���j��-������
           ,total_count_fri                 --���j��-������
           ,total_amount_sat                --�y�j��-������
           ,total_count_sat                 --�y�j��-������
           ,total_amount_sun                --���j��-������
           ,total_count_sun                 --���j��-������
           ,total_amount_week               --�T�v-������
           ,total_count_week                --�T�v-������
           ,created_by                      --�쐬��
           ,creation_date                   --�쐬��
           ,last_updated_by                 --�ŏI�X�V��
           ,last_update_date                --�ŏI�X�V��
           ,last_update_login               --�ŏI�X�V���O�C��
           ,request_id                      --�v��ID
           ,program_application_id          --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,program_id                      --�R���J�����g�E�v���O����ID
           ,program_update_date             --�v���O�����X�V��
          )
        VALUES
         (  gn_line_num                                          --�s�ԍ�
           ,cd_creation_date                                     --�o�͓���
           ,SUBSTRB( iv_target_yyyymm, 5, 2 )                    --�Ώی�
           ,iv_employee_number                                   --�c�ƈ��R�[�h
           ,iv_employee_name                                     --�c�ƈ���
           ,g_rep_cust_rt_mng_tab(i).account_number_mon          --���j��-�ڋq�R�[�h
           ,g_rep_cust_rt_mng_tab(i).gyotai_mon                  --���j��-�Ƒ�
           ,g_rep_cust_rt_mng_tab(i).customer_name_mon           --���j��-�ڋq��
           ,g_rep_cust_rt_mng_tab(i).sales_amount_mon            --���j��-����
           ,g_rep_cust_rt_mng_tab(i).account_number_tue          --�Ηj��-�ڋq�R�[�h
           ,g_rep_cust_rt_mng_tab(i).gyotai_tue                  --�Ηj��-�Ƒ�
           ,g_rep_cust_rt_mng_tab(i).customer_name_tue           --�Ηj��-�ڋq��
           ,g_rep_cust_rt_mng_tab(i).sales_amount_tue            --�Ηj��-����
           ,g_rep_cust_rt_mng_tab(i).account_number_wed          --���j��-�ڋq�R�[�h
           ,g_rep_cust_rt_mng_tab(i).gyotai_wed                  --���j��-�Ƒ�
           ,g_rep_cust_rt_mng_tab(i).customer_name_wed           --���j��-�ڋq��
           ,g_rep_cust_rt_mng_tab(i).sales_amount_wed            --���j��-����
           ,g_rep_cust_rt_mng_tab(i).account_number_thu          --�ؗj��-�ڋq�R�[�h
           ,g_rep_cust_rt_mng_tab(i).gyotai_thu                  --�ؗj��-�Ƒ�
           ,g_rep_cust_rt_mng_tab(i).customer_name_thu           --�ؗj��-�ڋq��
           ,g_rep_cust_rt_mng_tab(i).sales_amount_thu            --�ؗj��-����
           ,g_rep_cust_rt_mng_tab(i).account_number_fri          --���j��-�ڋq�R�[�h
           ,g_rep_cust_rt_mng_tab(i).gyotai_fri                  --���j��-�Ƒ�
           ,g_rep_cust_rt_mng_tab(i).customer_name_fri           --���j��-�ڋq��
           ,g_rep_cust_rt_mng_tab(i).sales_amount_fri            --���j��-����
           ,g_rep_cust_rt_mng_tab(i).account_number_sat          --�y�j��-�ڋq�R�[�h
           ,g_rep_cust_rt_mng_tab(i).gyotai_sat                  --�y�j��-�Ƒ�
           ,g_rep_cust_rt_mng_tab(i).customer_name_sat           --�y�j��-�ڋq��
           ,g_rep_cust_rt_mng_tab(i).sales_amount_sat            --�y�j��-����
           ,g_rep_cust_rt_mng_tab(i).account_number_sun          --���j��-�ڋq�R�[�h
           ,g_rep_cust_rt_mng_tab(i).gyotai_sun                  --���j��-�Ƒ�
           ,g_rep_cust_rt_mng_tab(i).customer_name_sun           --���j��-�ڋq��
           ,g_rep_cust_rt_mng_tab(i).sales_amount_sun            --���j��-����
           ,g_visit_count_tab(cn_route_grp_s)                    --���זK�⌬��_S����
           ,g_visit_count_tab(cn_route_grp_a)                    --���זK�⌬��_A����
           ,g_visit_count_tab(cn_route_grp_b)                    --���זK�⌬��_B����
           ,g_visit_count_tab(cn_route_grp_c)                    --���זK�⌬��_C����
           ,g_visit_count_tab(cn_route_grp_d)                    --���זK�⌬��_D����
           ,g_visit_count_tab(cn_route_grp_e)                    --���זK�⌬��_E����
           ,gn_total_visit_count                                 --���K�⌬��
           ,g_weekly_amount_tab(cn_week_mon)                     --���j��-������
           ,g_weekly_count_tab(cn_week_mon)                      --���j��-������
           ,g_weekly_amount_tab(cn_week_tue)                     --�Ηj��-������
           ,g_weekly_count_tab(cn_week_tue)                      --�Ηj��-������
           ,g_weekly_amount_tab(cn_week_wed)                     --���j��-������
           ,g_weekly_count_tab(cn_week_wed)                      --���j��-������
           ,g_weekly_amount_tab(cn_week_thu)                     --�ؗj��-������
           ,g_weekly_count_tab(cn_week_thu)                      --�ؗj��-������
           ,g_weekly_amount_tab(cn_week_fri)                     --���j��-������
           ,g_weekly_count_tab(cn_week_fri)                      --���j��-������
           ,g_weekly_amount_tab(cn_week_sat)                     --�y�j��-������
           ,g_weekly_count_tab(cn_week_sat)                      --�y�j��-������
           ,g_weekly_amount_tab(cn_week_sun)                     --���j��-������
           ,g_weekly_count_tab(cn_week_sun)                      --���j��-������
           ,g_weekly_amount_tab(cn_week_total)                   --�T�v-������
           ,g_weekly_count_tab(cn_week_total)                    --�T�v-������
           ,cn_created_by                                        --�쐬��
           ,cd_creation_date                                     --�쐬��
           ,cn_last_updated_by                                   --�ŏI�X�V��
           ,cd_last_update_date                                  --�ŏI�X�V��
           ,cn_last_update_login                                 --�ŏI�X�V���O�C��
           ,cn_request_id                                        --�v��ID
           ,cn_program_application_id                            --�R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,cn_program_id                                        --�R���J�����g�E�v���O����ID
           ,cd_program_update_date                               --�v���O�����X�V��
         );
      END LOOP insert_row_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_db_ins_err       --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_thn_table            --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_msg_tbl_nm           --�g�[�N���l1
                 ,iv_token_name2  => cv_tkn_errmsg           --�g�[�N���R�[�h2
                 ,iv_token_value2 => SQLERRM                 --�g�[�N���l2
                );
        RAISE insert_row_expt;
    END;
--
  EXCEPTION
    -- *** ���[�N�e�[�u���o�͏�����O ***
    WHEN insert_row_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END insert_row;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF�N��(A-5)
   ***********************************************************************************/
  PROCEDURE act_svf(
     ov_errbuf        OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode       OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg        OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100)   := 'act_svf';     -- �v���O������
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
    cv_tkn_api_nm_svf CONSTANT  VARCHAR2(20) := 'SVF�N��';
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCSO019A14S.xml';  -- �t�H�[���l���t�@�C����
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCSO019A14S.vrq';  -- �N�G���[�l���t�@�C����
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';  
    -- *** ���[�J���ϐ� ***
    lv_svf_file_name   VARCHAR2(50);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ======================
    -- SVF�N������ 
    -- ======================
    -- �t�@�C�����̐ݒ�
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR (cd_creation_date, cv_format_date_ymd)
                     || TO_CHAR (cn_request_id);
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
--
    lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode      => lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg       => lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ,iv_conc_name    => lv_conc_name          -- �R���J�����g��
     ,iv_file_name    => lv_svf_file_name      -- �o�̓t�@�C����
     ,iv_file_id      => lv_file_id            -- ���[ID
     ,iv_output_mode  => cv_output_mode        -- �o�͋敪(=1�FPDF�o�́j
     ,iv_frm_file     => cv_svf_form_name      -- �t�H�[���l���t�@�C����
     ,iv_vrq_file     => cv_svf_query_name     -- �N�G���[�l���t�@�C����
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ���O�C���E���[�U��
     ,iv_resp_name    => lv_resp_name          -- ���O�C���E���[�U�̐E�Ӗ�
     ,iv_doc_name     => NULL                  -- ������
     ,iv_printer_name => NULL                  -- �v�����^��
     ,iv_request_id   => cn_request_id         -- �v��ID
     ,iv_nodata_msg   => NULL                  -- �f�[�^�Ȃ����b�Z�[�W
     );
--
    -- SVF�N��API�̌Ăяo���̓G���[��
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_msg_err_api          --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_api_nm           --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tkn_api_nm_svf       --�g�[�N���l1
                );
      lv_errbuf := lv_errmsg || SQLERRM;
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
  END act_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_row
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-6)
   ***********************************************************************************/
  PROCEDURE delete_row(
     ov_errbuf   OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode  OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg   OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100)   := 'delete_row';     -- �v���O������
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
    -- *** ���[�J����O ***
    delete_row_expt     EXCEPTION;          -- ���[�N�e�[�u���폜������O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==========================
    -- ���[�N�e�[�u���f�[�^�폜
    -- ==========================
    BEGIN
      DELETE FROM xxcso_rep_cust_route_mng xrcrm  -- �ڋq�����Ǘ��\���[���[�N�e�[�u��
      WHERE xrcrm.request_id = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_msg_db_del_err       --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_thn_table            --�g�[�N���R�[�h1
                       ,iv_token_value1 => cv_msg_tbl_nm           --�g�[�N���l1
                       ,iv_token_name2  => cv_tkn_errmsg           --�g�[�N���R�[�h2
                       ,iv_token_value2 => SQLERRM                 --�g�[�N���l2
                     );
        RAISE delete_row_expt;
    END;
--
  EXCEPTION
--
    -- *** ���[�N�e�[�u���폜������O ***
    WHEN delete_row_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
-- #####################################  �Œ蕔 END   ##########################################
--
  END delete_row;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     iv_base_code        IN  VARCHAR2          -- ���_�R�[�h
    ,iv_target_yyyymm    IN  VARCHAR2          -- �Ώ۔N��
    ,iv_employee_number  IN  VARCHAR2          -- �]�ƈ��R�[�h
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
    -- *** ���[�J���ϐ� ***
    lv_pre_target_yyyymm       VARCHAR2(6);  -- �O��
    ln_pre_sales_amount        NUMBER;       -- �O��������z
    lt_employee_number         xxcso_route_management_emp_v.employee_number%TYPE;  -- �J�����g�]�ƈ��R�[�h
    lt_employee_name           xxcso_route_management_emp_v.employee_name%TYPE;    -- �J�����g�]�ƈ���
    lt_pre_employee_number     xxcso_route_management_emp_v.employee_number%TYPE;  -- �O�񏈗��]�ƈ��R�[�h
    lt_pre_employee_name       xxcso_route_management_emp_v.employee_name%TYPE;    -- �O�񏈗��]�ƈ���
    -- ���b�Z�[�W�i�[�p
    lv_msg                     VARCHAR2(5000);
    -- SVF�N��API�߂�l�i�[�p
    lv_errbuf_svf              VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode_svf             VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg_svf              VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
----
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
    -- �s�ԍ�
    gn_line_num   := 0;
--
    -- ========================================
    -- A-1.��������
    -- ========================================
    init(
       iv_base_code        => iv_base_code           -- ���_�R�[�h
      ,iv_target_yyyymm    => iv_target_yyyymm       -- �Ώ۔N��
      ,iv_employee_number  => iv_employee_number     -- �]�ƈ��R�[�h
      ,ov_errbuf           => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode          => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg           => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.�f�[�^�擾
    -- ========================================
    -- �O�񏈗��c�ƈ������l
    lt_pre_employee_number := cv_emp_dummy;
--
    IF ( iv_employee_number IS NULL )  THEN
      -- �J�[�\���I�[�v��
      OPEN  get_prsn_dt_vst_pln_cur(
               iv_base_code        => iv_base_code        -- ���_�R�[�h
            );
    ELSE
      -- �J�[�\���I�[�v��
      OPEN  get_prsn_dt_vst_pln_cur2(
               iv_base_code        => iv_base_code        -- ���_�R�[�h
              ,iv_employee_number  => iv_employee_number  -- �]�ƈ��R�[�h
            );
    END IF;
--
    <<get_prsn_dt_vst_pln_loop1>>
    LOOP
--
      IF ( iv_employee_number IS NULL )  THEN
        FETCH get_prsn_dt_vst_pln_cur INTO g_prsn_dt_vst_pln_rec;
--
        -- �����Ώۃf�[�^�����݂��Ȃ������ꍇEXIT
        EXIT WHEN get_prsn_dt_vst_pln_cur%NOTFOUND
        OR  get_prsn_dt_vst_pln_cur%ROWCOUNT = 0;
      ELSE
--
        FETCH get_prsn_dt_vst_pln_cur2 INTO g_prsn_dt_vst_pln_rec;
--
        -- �����Ώۃf�[�^�����݂��Ȃ������ꍇEXIT
        EXIT WHEN get_prsn_dt_vst_pln_cur2%NOTFOUND
        OR  get_prsn_dt_vst_pln_cur2%ROWCOUNT = 0;
--
      END IF;
--
      --�J�����g�c�ƈ��ޔ�
      lt_employee_number := g_prsn_dt_vst_pln_rec.employee_number;
      lt_employee_name   := g_prsn_dt_vst_pln_rec.employee_name;
--
      -- �O�񏈗��c�ƈ��ƈقȂ�ꍇ�̓��[�N�e�[�u���֓o�^
      IF lt_pre_employee_number <> g_prsn_dt_vst_pln_rec.employee_number THEN
--
        IF lt_pre_employee_number <> cv_emp_dummy THEN
          -- ========================================
          -- A-4.���[�N�e�[�u���f�[�^�o�^
          -- ========================================
          insert_row(
             iv_base_code        => iv_base_code           -- ���_�R�[�h
            ,iv_target_yyyymm    => iv_target_yyyymm       -- �Ώ۔N��
            ,iv_employee_number  => lt_pre_employee_number -- �O�񏈗��]�ƈ��R�[�h
            ,iv_employee_name    => lt_pre_employee_name   -- �O�񏈗��]�ƈ���
            ,ov_errbuf           => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
            ,ov_retcode          => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
            ,ov_errmsg           => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ���[�N�o�^�X�g�b�N��폜
          g_rep_cust_rt_mng_tab.DELETE;
--
        END IF;
--
        -- ======================
        -- �i�[�̈�̏�����
        -- ======================
        -- ���[�N�o�^�X�g�b�N�揉����
        g_rep_cust_rt_mng_tab := g_rep_cust_rt_mng_ttype();
        g_rep_cust_rt_mng_tab.EXTEND(cn_max_line);
--
        -- �y�[�WNo
        gn_total_page_no     := 1;
        gn_page_no           := 1;
--
        --�K�⑍����
        gn_total_visit_count := 0;
--
        --�T�ԕʗj���ʍ��v�i�j���v�j
        << w_total_loop >>
        FOR i IN cn_week_mon..cn_week_total LOOP
          --����
          g_weekly_count_tab(i)  := 0;
          --���z
          g_weekly_amount_tab(i) := 0;
        END LOOP w_total_loop;
--
        --���ޕʉ��זK�⌬��
        << c_total_loop >>
        FOR i IN cn_route_grp_s..cn_route_grp_e LOOP
          g_visit_count_tab(i) := 0;
        END LOOP c_total_loop;
--
        -- ���ޕʗj���ʌ���
        << c_loop >>
        FOR i IN cn_route_grp_s..cn_route_grp_e LOOP
          << w_loop >>
          FOR r IN cn_week_mon..cn_week_sun LOOP
            g_line_count_tab(i)(r) := 0;
          END LOOP w_loop;
        END LOOP c_loop;
--
        -- �O�񏈗��c�ƈ������X�V����
        lt_pre_employee_number := g_prsn_dt_vst_pln_rec.employee_number;
        lt_pre_employee_name   := g_prsn_dt_vst_pln_rec.employee_name;
--
      END IF;
--
      --�O���̔����ю擾
      SELECT NVL(SUM(xsvsr.rslt_amt), 0)
      INTO   ln_pre_sales_amount
      FROM   xxcso_sum_visit_sale_rep xsvsr    -- �K�┄��v��Ǘ��\�T�}���e�[�u��
      WHERE  xsvsr.sum_org_type   = cv_org_type_cust  --�ڋq
      AND    xsvsr.month_date_div = cv_month_div      --����
      AND    xsvsr.sum_org_code   = g_prsn_dt_vst_pln_rec.account_number  --�ڋq�R�[�h
      AND    xsvsr.sales_date     = gv_pre_target_yyyymm
      ;
--
      -- ���[�g(S,A,B,C) �����l0��1�Őݒ肳��郋�[�g
      IF ( g_prsn_dt_vst_pln_rec.group_no IN ( cn_route_grp_s, cn_route_grp_a, cn_route_grp_b, cn_route_grp_c) ) THEN
--
        << sale_amt_loop >>
        FOR ln_week_no IN cn_week_mon..cn_week_sun LOOP
--
         -- �K��\��̗j������
         IF SUBSTRB(g_prsn_dt_vst_pln_rec.route_number, ln_week_no, 1) <> '0' THEN
--
            -- ========================================
            -- A-3.�z��̒ǉ��A�X�V
            -- ========================================
            ins_upd_lines(
               in_group_no            => g_prsn_dt_vst_pln_rec.group_no  -- ���[�g���ޔԍ�
              ,in_week_no             => ln_week_no                      -- �j���ԍ�
              ,in_pre_sales_amount    => ln_pre_sales_amount             -- �O��������z
              ,ov_errbuf              => lv_errbuf                       -- �G���[�E���b�Z�[�W            --# �Œ� #
              ,ov_retcode             => lv_retcode                      -- ���^�[���E�R�[�h              --# �Œ� #
              ,ov_errmsg              => lv_errmsg                       -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
            );
--
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
         END IF;
--
        END LOOP sale_amt_loop;
--
      -- ���[�g(D,E) ��5-����n�܂郋�[�g
      ELSIF ( g_prsn_dt_vst_pln_rec.group_no IN ( cn_route_grp_d, cn_route_grp_e ) ) THEN
--
        -- ========================================
        -- A-3.�z��̒ǉ��A�X�V
        -- ========================================
        ins_upd_lines(
           in_group_no            => g_prsn_dt_vst_pln_rec.group_no  -- ���[�g���ޔԍ�
          ,in_week_no             => TO_NUMBER(SUBSTRB(g_prsn_dt_vst_pln_rec.route_number, 6, 1))  -- �j���ԍ�
          ,in_pre_sales_amount    => ln_pre_sales_amount    -- �O��������z
          ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- �����Ώی����J�E���g�A�b�v
      gn_target_cnt := gn_target_cnt + 1;
--
    END LOOP get_prsn_dt_vst_pln_loop1;
--
    -- �J�[�\���N���[�Y
    IF ( iv_employee_number IS NULL )  THEN
      CLOSE get_prsn_dt_vst_pln_cur;
    ELSE
      CLOSE get_prsn_dt_vst_pln_cur2;
    END IF;
--
    IF ( gn_target_cnt <> 0 ) THEN
      -- ========================================
      -- A-4.���[�N�e�[�u���f�[�^�o�^
      -- ========================================
      insert_row(
         iv_base_code        => iv_base_code           -- ���_�R�[�h
        ,iv_target_yyyymm    => iv_target_yyyymm       -- �Ώ۔N��
        ,iv_employee_number  => lt_employee_number     -- �]�ƈ��R�[�h
        ,iv_employee_name    => lt_employee_name       -- �]�ƈ���
        ,ov_errbuf           => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode          => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg           => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- �����Ώۃf�[�^��0���̏ꍇ
    IF ( gn_target_cnt = 0 ) THEN
--
      -- 0�����b�Z�[�W�o��
      lv_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                    ,iv_name         => cv_msg_no_data      --���b�Z�[�W�R�[�h
                   );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_msg                                   --���[�U�[�E�G���[���b�Z�[�W
      );
      ov_retcode := cv_status_normal;
--
    ELSE
--
      -- ========================================
      -- A-5.SVF�N��
      -- ========================================
      act_svf(
         ov_errbuf     => lv_errbuf_svf                -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode    => lv_retcode_svf               -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg     => lv_errmsg_svf                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode_svf <> cv_status_error) THEN
        gn_normal_cnt := gn_target_cnt;
      END IF;
--
      -- ========================================
      -- A-6.���[�N�e�[�u���f�[�^�폜
      -- ========================================
      delete_row(
         ov_errbuf     => lv_errbuf                    -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode    => lv_retcode                   -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg     => lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ========================================
      -- A-7.SVF�N��API�G���[�`�F�b�N
      -- ========================================
      IF (lv_retcode_svf = cv_status_error) THEN
        lv_errmsg := lv_errmsg_svf;
        lv_errbuf := lv_errbuf_svf;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_prsn_dt_vst_pln_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_prsn_dt_vst_pln_cur;
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_prsn_dt_vst_pln_cur2%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_prsn_dt_vst_pln_cur2;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_prsn_dt_vst_pln_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_prsn_dt_vst_pln_cur;
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_prsn_dt_vst_pln_cur2%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_prsn_dt_vst_pln_cur2;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_prsn_dt_vst_pln_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_prsn_dt_vst_pln_cur;
      END IF;
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_prsn_dt_vst_pln_cur2%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_prsn_dt_vst_pln_cur2;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf             OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode            OUT NOCOPY VARCHAR2    --   ���^�[���E�R�[�h    --# �Œ� #
    ,iv_base_code       IN  VARCHAR2           --   ���_�R�[�h
    ,iv_target_yyyymm   IN  VARCHAR2           --   �Ώ۔N��
    ,iv_employee_number IN  VARCHAR2           --   �]�ƈ��R�[�h
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
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
    -- �G���[���b�Z�[�W
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
--
--###########################  �Œ蕔 END   ####################################
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
       iv_base_code        => iv_base_code       -- ���_�R�[�h
      ,iv_target_yyyymm    => iv_target_yyyymm   -- �Ώ۔N��
      ,iv_employee_number  => iv_employee_number -- �]�ƈ��R�[�h
      ,ov_errbuf           => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode          => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg           => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
      gn_error_cnt  := 1;
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
    END IF;
--
    -- =======================
    -- A-8.�I������ 
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
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
--
-- #################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO019A14R;
/
