create or replace PACKAGE BODY XXCSO019A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A06C(body)
 * Description      :  �w�肵���c�ƈ��̎w�肵�������܂�1�T�Ԃ̖K��v��(�K���ڋq��)
 *                    ����ʂ�PDF�֏o�͂��܂��B
 *                     �ڋq�͓���̃��[�gNo���Ƃɂ܂Ƃ߁A�T�ԖK��񐔂̑������[�gNo����
 *                    ���ɕ\�����܂��B(���[�gNo��\�����܂��B)
 *                     ���t���̉E�[��1���̌�����\�����܂��B
 * MD.050           : MD050_CSO_019_A06_�K�⑍���Ǘ��\
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  chk_param              �p�����[�^�`�F�b�N(A-2)
 *  header_process         ���[�w�b�_����(A-3)
 *  ins_upd_lines          �z��̒ǉ��A�X�V(A-5)
 *  insert_row             ���[�N�e�[�u���f�[�^�o�^(A-6)
 *  act_svf                SVF�N��(A-7)
 *  delete_row             ���[�N�e�[�u���f�[�^�폜(A-8)
 *  submain                ���C�������v���V�[�W��
 *                           �f�[�^�擾(A-4)
 *                           SVF�N��API�G���[�`�F�b�N(A-9)
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                           �I������(A-10)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-16    1.0   Mio.Maruyama     �V�K�쐬
 *  2009-03-02    1.0   Mio.Maruyama     ���������J�E���g�A�b�v�G���[�C��
 *  2009-03-03    1.1   Kazuyo.Hosoi     SVF�N��API���ߍ���
 *  2009-03-11    1.1   Kazuyo.Hosoi     �y��Q�Ή�047�z�ڋq�敪�A�X�e�[�^�X���o�����ύX
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
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO019A06C';  -- �p�b�P�[�W��
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- �A�v���P�[�V�����Z�k��
  cn_org_id              CONSTANT NUMBER        := TO_NUMBER(SUBSTRB(USERENV('CLIENT_INFO'), 1, 10)); -- ���O�C���g�D�h�c
  --
  cv_report_id           CONSTANT VARCHAR2(30)  := 'XXCSO019A06C';  -- ���[ID
  -- ���t����
  cv_format_date_ymd1    CONSTANT VARCHAR2(8)   := 'YYYYMMDD';      -- ���t�t�H�[�}�b�g�i�N�����j
  cv_format_get_dayname  CONSTANT VARCHAR2(3)   := 'DAY';           -- �j���擾�p�t�H�[�}�b�g
  -- ���b�Z�[�W�R�[�h
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00129';  -- �p�����[�^�o��(��N����)
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00131';  -- �p�����[�^�o��(�]�ƈ��R�[�h)
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00132';  -- �N�����̌^�Ⴂ�G���[
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00133';  -- �K�{���ږ��I���G���[
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00134';  -- �����O�̃I�y���[�V�����G���[
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00135';  -- API�G���[
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00042';  -- �c�a�o�^�E�X�V�G���[
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00140';  -- ����0�����b�Z�[�W
  -- �g�[�N���R�[�h
  cv_tkn_entry           CONSTANT VARCHAR2(20)  := 'ENTRY';
  cv_thn_table           CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_api_nm          CONSTANT VARCHAR2(20)  := 'API_NAME';
  cv_tkn_count           CONSTANT VARCHAR2(20)  := 'COUNT';
  cv_tkn_act             CONSTANT VARCHAR2(20)  := 'ACTION';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20)  := 'ERRMSG';
--
  cv_msg_prnthss_l       CONSTANT VARCHAR2(1)   := '(';
  cv_msg_prnthss_r       CONSTANT VARCHAR2(1)   := ')';
--
  cn_user_id             CONSTANT NUMBER        := fnd_global.user_id;   -- ���[�U�[ID
  cn_resp_id             CONSTANT NUMBER        := fnd_global.resp_id;   -- �E��ID
  cd_work_date            CONSTANT DATE         := xxcso_util_common_pkg.get_online_sysdate;  -- ���ݓ��t
  cd_now_date            CONSTANT DATE          := SYSDATE;  -- ���ݓ��t
  cv_rep_tp              CONSTANT VARCHAR2(1)   := '1';                  -- ���[�^�C�v
  cv_true                CONSTANT VARCHAR2(4)   := 'TRUE';               -- �߂�l���f�p
  cv_false               CONSTANT VARCHAR2(5)   := 'FALSE';              -- �߂�l���f�p
--
  -- ���[�N�e�[�u���ւ̗j���i�[�p
  cv_week_1              CONSTANT VARCHAR2(2)   := '��';
  cv_week_2              CONSTANT VARCHAR2(2)   := '��';
  cv_week_3              CONSTANT VARCHAR2(2)   := '��';
  cv_week_4              CONSTANT VARCHAR2(2)   := '��';
  cv_week_5              CONSTANT VARCHAR2(2)   := '��';
  cv_week_6              CONSTANT VARCHAR2(2)   := '�y';
  cv_week_7              CONSTANT VARCHAR2(2)   := '��';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_total_count         NUMBER(10) DEFAULT 0;         -- ������
  gn_total_count_1       NUMBER(10) DEFAULT 0;         -- ���j��-������
  gn_total_count_2       NUMBER(10) DEFAULT 0;         -- �Ηj��-������
  gn_total_count_3       NUMBER(10) DEFAULT 0;         -- ���j��-������
  gn_total_count_4       NUMBER(10) DEFAULT 0;         -- �ؗj��-������
  gn_total_count_5       NUMBER(10) DEFAULT 0;         -- ���j��-������
  gn_total_count_6       NUMBER(10) DEFAULT 0;         -- �y�j��-������
  gn_total_count_7       NUMBER(10) DEFAULT 0;         -- ���j��-������
--
  gd_day_1               DATE;                         -- ���j��-��
  gd_day_2               DATE;                         -- �Ηj��-��
  gd_day_3               DATE;                         -- ���j��-��
  gd_day_4               DATE;                         -- �ؗj��-��
  gd_day_5               DATE;                         -- ���j��-��
  gd_day_6               DATE;                         -- �y�j��-��
  gd_day_7               DATE;                         -- ���j��-��
--
  gn_cnt                 NUMBER DEFAULT 0;             -- �z��p�J�E���^
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- �c�ƈ��ʓ��ʖK��v�� ���R�[�h�^��`
  TYPE g_prsn_dt_vst_pln_rtype IS RECORD(
     account_number         xxcso_cust_accounts_v.account_number%TYPE   -- �ڋq�R�[�h
    ,party_name             xxcso_cust_accounts_v.party_name%TYPE       -- �ڋq����
    ,route_no               xxcso_cust_routes_v2.route_number%TYPE      -- ���[�gNo
  );
--  -- �K�⑍���Ǘ����[���[�N�e�[�u�� ���R�[�h�^��`
  TYPE g_rep_vst_rt_mng_rtype IS RECORD(
     line_num               xxcso_rep_visit_route_mng.line_num%TYPE               -- �s�ԍ�
    ,report_id              xxcso_rep_visit_route_mng.report_id%TYPE              -- ���[�h�c
    ,report_name            xxcso_rep_visit_route_mng.report_name%TYPE            -- ���[�^�C�g��
    ,output_date            xxcso_rep_visit_route_mng.output_date%TYPE            -- �o�͓���
    ,base_date              xxcso_rep_visit_route_mng.base_date%TYPE              -- ��N����
    ,base_date_start        xxcso_rep_visit_route_mng.base_date_start%TYPE        -- ���START
    ,base_date_end          xxcso_rep_visit_route_mng.base_date_end%TYPE          -- ���END
    ,base_code              xxcso_rep_visit_route_mng.base_code%TYPE              -- ���_�R�[�h
    ,hub_name               xxcso_rep_visit_route_mng.hub_name%TYPE               -- ���_����
    ,employee_number        xxcso_rep_visit_route_mng.employee_number%TYPE        -- �c�ƈ��R�[�h
    ,employee_name          xxcso_rep_visit_route_mng.employee_name%TYPE          -- �c�ƈ���
    ,total_count            xxcso_rep_visit_route_mng.total_count%TYPE            -- ������
    ,day_1                  xxcso_rep_visit_route_mng.day_1%TYPE                  -- ���j��-��
    ,week_1                 xxcso_rep_visit_route_mng.week_1%TYPE                 -- ���j��-�j��
    ,total_count_1          xxcso_rep_visit_route_mng.total_count_1%TYPE          -- ���j��-������
    ,account_number_1       xxcso_rep_visit_route_mng.account_number_1%TYPE       -- ���j��-�ڋq�R�[�h
    ,route_no_1             xxcso_rep_visit_route_mng.route_no_1%TYPE             -- ���j��-���[�gNo.
    ,customer_name_1        xxcso_rep_visit_route_mng.customer_name_1%TYPE        -- ���j��-�ڋq��
    ,day_2                  xxcso_rep_visit_route_mng.day_2%TYPE                  -- �Ηj��-��
    ,week_2                 xxcso_rep_visit_route_mng.week_2%TYPE                 -- �Ηj��-�j��
    ,total_count_2          xxcso_rep_visit_route_mng.total_count_2%TYPE          -- �Ηj��-������
    ,account_number_2       xxcso_rep_visit_route_mng.account_number_2%TYPE       -- �Ηj��-�ڋq�R�[�h
    ,route_no_2             xxcso_rep_visit_route_mng.route_no_2%TYPE             -- �Ηj��-���[�gNo.
    ,customer_name_2        xxcso_rep_visit_route_mng.customer_name_2%TYPE        -- �Ηj��-�ڋq��
    ,day_3                  xxcso_rep_visit_route_mng.day_3%TYPE                  -- ���j��-��
    ,week_3                 xxcso_rep_visit_route_mng.week_3%TYPE                 -- ���j��-�j��
    ,total_count_3          xxcso_rep_visit_route_mng.total_count_3%TYPE          -- ���j��-������
    ,account_number_3       xxcso_rep_visit_route_mng.account_number_3%TYPE       -- ���j��-�ڋq�R�[�h
    ,route_no_3             xxcso_rep_visit_route_mng.route_no_3%TYPE             -- ���j��-���[�gNo.
    ,customer_name_3        xxcso_rep_visit_route_mng.customer_name_3%TYPE        -- ���j��-�ڋq��
    ,day_4                  xxcso_rep_visit_route_mng.day_4%TYPE                  -- �ؗj��-��
    ,week_4                 xxcso_rep_visit_route_mng.week_4%TYPE                 -- �ؗj��-�j��
    ,total_count_4          xxcso_rep_visit_route_mng.total_count_4%TYPE          -- �ؗj��-������
    ,account_number_4       xxcso_rep_visit_route_mng.account_number_4%TYPE       -- �ؗj��-�ڋq�R�[�h
    ,route_no_4             xxcso_rep_visit_route_mng.route_no_4%TYPE             -- �ؗj��-���[�gNo.
    ,customer_name_4        xxcso_rep_visit_route_mng.customer_name_4%TYPE        -- �ؗj��-�ڋq��
    ,day_5                  xxcso_rep_visit_route_mng.day_5%TYPE                  -- ���j��-��
    ,week_5                 xxcso_rep_visit_route_mng.week_5%TYPE                 -- ���j��-�j��
    ,total_count_5          xxcso_rep_visit_route_mng.total_count_5%TYPE          -- ���j��-������
    ,account_number_5       xxcso_rep_visit_route_mng.account_number_5%TYPE       -- ���j��-�ڋq�R�[�h
    ,route_no_5             xxcso_rep_visit_route_mng.route_no_5%TYPE             -- ���j��-���[�gNo.
    ,customer_name_5        xxcso_rep_visit_route_mng.customer_name_5%TYPE        -- ���j��-�ڋq��
    ,day_6                  xxcso_rep_visit_route_mng.day_6%TYPE                  -- �y�j��-��
    ,week_6                 xxcso_rep_visit_route_mng.week_6%TYPE                 -- �y�j��-�j��
    ,total_count_6          xxcso_rep_visit_route_mng.total_count_6%TYPE          -- �y�j��-������
    ,account_number_6       xxcso_rep_visit_route_mng.account_number_6%TYPE       -- �y�j��-�ڋq�R�[�h
    ,route_no_6             xxcso_rep_visit_route_mng.route_no_6%TYPE             -- �y�j��-���[�gNo.
    ,customer_name_6        xxcso_rep_visit_route_mng.customer_name_6%TYPE        -- �y�j��-�ڋq��
    ,day_7                  xxcso_rep_visit_route_mng.day_7%TYPE                  -- ���j��-��
    ,week_7                 xxcso_rep_visit_route_mng.week_7%TYPE                 -- ���j��-�j��
    ,total_count_7          xxcso_rep_visit_route_mng.total_count_7%TYPE          -- ���j��-������
    ,account_number_7       xxcso_rep_visit_route_mng.account_number_7%TYPE       -- ���j��-�ڋq�R�[�h
    ,route_no_7             xxcso_rep_visit_route_mng.route_no_7%TYPE             -- ���j��-���[�gNo.
    ,customer_name_7        xxcso_rep_visit_route_mng.customer_name_7%TYPE        -- ���j��-�ڋq��
    ,created_by             xxcso_rep_visit_route_mng.created_by%TYPE             -- �쐬��
    ,creation_date          xxcso_rep_visit_route_mng.creation_date%TYPE          -- �쐬��
    ,last_updated_by        xxcso_rep_visit_route_mng.last_updated_by%TYPE        -- �ŏI�X�V��
    ,last_update_date       xxcso_rep_visit_route_mng.last_update_date%TYPE       -- �ŏI�X�V��
    ,last_update_login      xxcso_rep_visit_route_mng.last_update_login%TYPE      -- �ŏI�X�V���O�C��
    ,request_id             xxcso_rep_visit_route_mng.request_id%TYPE             -- �v��ID
    ,program_application_id xxcso_rep_visit_route_mng.program_application_id%TYPE -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    ,program_id             xxcso_rep_visit_route_mng.program_id%TYPE             -- �R���J�����g�E�v���O����ID
    ,program_update_date    xxcso_rep_visit_route_mng.program_update_date%TYPE    -- �v���O�����X�V��
  );
  -- �c�ƈ��ʖK����ѕ\���[���[�N�e�[�u�� �e�[�u���^��`
  TYPE g_rep_vst_rt_mng_ttype IS TABLE OF g_rep_vst_rt_mng_rtype INDEX BY BINARY_INTEGER;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  g_rep_vst_rt_mng_tab      g_rep_vst_rt_mng_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : ��������(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_standard_date    IN  VARCHAR2         -- ��N����
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
    lv_msg_stnd_dt  VARCHAR2(5000);
    lv_msg_bs_num   VARCHAR2(5000);
    lv_msg_emp_num  VARCHAR2(5000);
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
    -- ���̓p�����[�^���b�Z�[�W�o��
    -- ===========================
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- ���b�Z�[�W�擾(��N����)
    lv_msg_stnd_dt  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_01    --���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_entry        --�g�[�N���R�[�h1
                         ,iv_token_value1 => iv_standard_date    --�g�[�N���l1
                       );
    -- ���b�Z�[�W�擾(�]�ƈ��R�[�h)
    lv_msg_emp_num  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                         ,iv_name         => cv_tkn_number_02    --���b�Z�[�W�R�[�h
                         ,iv_token_name1  => cv_tkn_entry        --�g�[�N���R�[�h1
                         ,iv_token_value1 => iv_employee_number  --�g�[�N���l1
                       );
--
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_stnd_dt
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_emp_num
    );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : �p�����[�^�`�F�b�N(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
     iv_standard_date    IN  VARCHAR2         -- ��N����
    ,iv_employee_number  IN  VARCHAR2         -- �]�ƈ��R�[�h
    ,od_standard_date    OUT DATE             -- ��N����(DATE�^)
    ,ov_full_name        OUT NOCOPY VARCHAR2  -- ��������
    ,ov_work_base_code     OUT NOCOPY VARCHAR2                           -- �Ζ��n���_�R�[�h
    ,ov_hub_name         OUT NOCOPY VARCHAR2  -- �Ζ��n���_��
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'chk_param';  -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_stnd_dt           CONSTANT VARCHAR2(20) := '��N����';
    cv_bs_nm             CONSTANT VARCHAR2(20) := '���_�R�[�h';
    cv_emp_nm            CONSTANT VARCHAR2(20) := '�]�ƈ��R�[�h';
    -- *** ���[�J���ϐ� ***
    ld_standard_date     DATE;                                     -- ��N����(DATE�^)
    lt_employee_number   xxcso_resources_v2.employee_number%TYPE;  -- �]�ƈ��R�[�h
    lt_last_name         xxcso_resources_v2.last_name%TYPE;        -- ������
    lt_first_name        xxcso_resources_v2.first_name%TYPE;       -- ������
    lv_work_base_code    VARCHAR2(150);                            -- �Ζ��n���_�R�[�h
    lv_work_base_name    VARCHAR2(4000);                           -- �Ζ��n���_��
    lv_retcd             VARCHAR2(5);                              -- ���ʊ֐��߂�l�i�[
    -- *** ���[�J����O ***
    chk_param_expt       EXCEPTION;  -- ���σw�b�_�[�h�c�����̓G���[
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
    -- �p�����[�^�K�{�`�F�b�N
    -- ===========================
    -- �p�����[�^��N������������
    IF (iv_standard_date IS NULL) THEN
      -- �G���[���b�Z�[�W�擾(��N����)
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_04  --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_entry      --�g�[�N���R�[�h1
                     ,iv_token_value1 => cv_stnd_dt        --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
    -- �p�����[�^�]�ƈ��R�[�h��������
    IF (iv_employee_number IS NULL) THEN
      -- �G���[���b�Z�[�W�擾(�]�ƈ��R�[�h)
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       --�A�v���P�[�V�����Z�k��
                     ,iv_name         => cv_tkn_number_04  --���b�Z�[�W�R�[�h
                     ,iv_token_name1  => cv_tkn_entry      --�g�[�N���R�[�h1
                     ,iv_token_value1 => cv_emp_nm         --�g�[�N���l1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
    -- ================================
    -- �p�����[�^(��N����)�`�F�b�N
    -- ================================
--
    BEGIN
      SELECT TO_DATE(iv_standard_date,cv_format_date_ymd1) standard_date -- IN�p�����[�^��N����
      INTO   ld_standard_date
      FROM   dual;
    EXCEPTION
      WHEN OTHERS THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_03    --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_entry        --�g�[�N���R�[�h1
                       ,iv_token_value1 => cv_stnd_dt          --�g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE chk_param_expt;
    END;
    -- ===========================
    -- �]�ƈ��R�[�h�`�F�b�N
    -- ===========================
    -- ���O�C�����[�U�[�̐E�Ӄ`�F�b�N
    lv_retcd   := xxcso_util_common_pkg.chk_responsibility(
                    in_user_id     => cn_user_id       -- ���O�C�����[�U�h�c
                   ,in_resp_id     => cn_resp_id       -- �E�ʂh�c
                   ,iv_report_type => cv_rep_tp        -- ���[�^�C�v�i1:�c�ƈ��ʁA2:�c�ƈ��O���[�v�ʁA���̑��͎w��s�j
                  );
--
    BEGIN
      SELECT  xrv2.employee_number  employee_number -- �]�ƈ��R�[�h
             ,xrv2.last_name        last_name       -- ������
             ,xrv2.first_name       first_name      -- ������
             ,(CASE WHEN xrv2.issue_date <= TO_CHAR(cd_work_date, cv_format_date_ymd1) THEN
                      xrv2.work_base_code_new  -- �Ζ��n���_�R�[�h�i�V�j
                    ELSE
                      xrv2.work_base_code_old  -- �Ζ��n���_�R�[�h�i���j
                    END
               ) work_base_code                -- �Ζ��n���_�R�[�h
             ,(CASE WHEN xrv2.issue_date <= TO_CHAR(cd_work_date, cv_format_date_ymd1) THEN
                      xrv2.work_base_name_new  -- �Ζ��n���_���i�V�j
                    ELSE
                      xrv2.work_base_name_old  -- �Ζ��n���_���i���j
                    END
               ) work_base_name                -- �Ζ��n���_��
      INTO    lt_employee_number
             ,lt_last_name
             ,lt_first_name
             ,lv_work_base_code
             ,lv_work_base_name
      FROM   xxcso_resources_v2 xrv2           -- ���\�[�X�}�X�^(�ŐV)VIEW
      WHERE (CASE WHEN xrv2.issue_date <= TO_CHAR(cd_work_date, cv_format_date_ymd1) THEN
                    xrv2.work_base_code_new  -- �Ζ��n���_�R�[�h�i�V�j
                  ELSE
                    xrv2.work_base_code_old  -- �Ζ��n���_�R�[�h�i���j
                  END
             ) = ( SELECT (CASE WHEN xrv.issue_date <= TO_CHAR(cd_work_date, cv_format_date_ymd1) THEN
                                  xrv.work_base_code_new  -- �Ζ��n���_�R�[�h�i�V�j
                                ELSE
                                  xrv.work_base_code_old  -- �Ζ��n���_�R�[�h�i���j
                                END
                           ) work_base_code2
                   FROM    xxcso_resources_v2 xrv
                   WHERE   xrv.user_id = cn_user_id
                  )
        AND xrv2.employee_number = iv_employee_number
        AND ((lv_retcd  =  cv_true
               AND xrv2.user_id = cn_user_id
              )
            OR (lv_retcd  =  cv_false
               AND 1 = 1
              ));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                       ,iv_name         => cv_tkn_number_05    --���b�Z�[�W�R�[�h
                       ,iv_token_name1  => cv_tkn_entry        --�g�[�N���R�[�h1
                       ,iv_token_value1 => iv_employee_number  --�g�[�N���l1
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE chk_param_expt;
      WHEN OTHERS THEN
        RAISE;
    END;
    -- OUT�p�����[�^�̐ݒ�
    od_standard_date   := ld_standard_date;   -- ���(DATE�^)
    ov_full_name       := SUBSTRB(lt_last_name || lt_first_name, 1, 40);  -- ��������
    ov_work_base_code  := lv_work_base_code;  -- �Ζ��n���_�R�[�h
    ov_hub_name        := lv_work_base_name;  -- �Ζ��n���_��
--
    -- ��s�̑}��
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
    -- *** �p�����[�^�`�F�b�N�G���[ ***
    WHEN chk_param_expt THEN
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : header_process
   * Description      : ���[�w�b�_����(A-3)
   ***********************************************************************************/
  PROCEDURE header_process(
     id_standard_date       IN  DATE             -- ���(DATE�^)
    ,od_start_date          OUT DATE             -- �������
    ,od_end_date            OUT DATE             -- �������
    ,ov_errbuf              OUT NOCOPY VARCHAR2  -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2  -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'header_process';     -- �v���O������
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
    cv_strt_dt_nm  CONSTANT VARCHAR2(20) := '���j��';  -- ���j��(��������̗j��)
    cv_end_dt_nm   CONSTANT VARCHAR2(20) := '���j��';  -- ���j��(��������̗j��)
    -- *** ���[�J���ϐ� ***
    lv_dayname     VARCHAR2(20);  -- ����j���i�[�p
    ld_start_date  DATE;          -- �������
    ld_end_date    DATE;          -- �������
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
    -- �W�v�Ώۊ��� ���o
    -- ======================
    lv_dayname := TO_CHAR(id_standard_date,cv_format_get_dayname);  -- ����̗j�����擾
--
    IF (lv_dayname = cv_strt_dt_nm) THEN            -- ��������j���̏ꍇ
      ld_start_date := id_standard_date;            -- �������
      
      SELECT NEXT_DAY(id_standard_date,cv_end_dt_nm) end_date    -- �������
      INTO   ld_end_date
      FROM dual
      ;
--
    ELSIF (lv_dayname = cv_end_dt_nm) THEN  -- ��������j���̏ꍇ
      SELECT NEXT_DAY(id_standard_date,cv_strt_dt_nm)-7 start_date -- �������
      INTO   ld_start_date
      FROM dual
      ;
      ld_end_date := id_standard_date;      -- �������
--
    ELSIF ((lv_dayname <> cv_strt_dt_nm)    -- �ǂ���ł��Ȃ��ꍇ
      AND (lv_dayname <> cv_end_dt_nm))
    THEN
      SELECT NEXT_DAY(id_standard_date,cv_strt_dt_nm)-7 start_date -- �������
      INTO   ld_start_date
      FROM dual
      ;
      
      SELECT NEXT_DAY(id_standard_date,cv_end_dt_nm) end_date    -- �������
      INTO   ld_end_date
      FROM dual
      ;
    END IF;
--
    -- OUT�p�����[�^�̐ݒ�
    od_start_date  := ld_start_date;  -- �������
    od_end_date    := ld_end_date;    -- �������
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
  END header_process;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_lines
   * Description      : �z��̒ǉ��A�X�V(A-5)
   ***********************************************************************************/
  PROCEDURE ins_upd_lines(
     id_base_date           IN  DATE                     -- ���[�v�p���
    ,i_prsn_dt_vst_pln_rec  IN  g_prsn_dt_vst_pln_rtype  -- �c�ƈ��ʓ��ʖK��v��f�[�^
    ,ov_errbuf              OUT NOCOPY VARCHAR2          -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2          -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
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
    -- �K��j��
    cv_visit_dayname_mon  CONSTANT VARCHAR(20) := '���j��';
    cv_visit_dayname_tue  CONSTANT VARCHAR(20) := '�Ηj��';
    cv_visit_dayname_wed  CONSTANT VARCHAR(20) := '���j��';
    cv_visit_dayname_thu  CONSTANT VARCHAR(20) := '�ؗj��';
    cv_visit_dayname_fri  CONSTANT VARCHAR(20) := '���j��';
    cv_visit_dayname_sat  CONSTANT VARCHAR(20) := '�y�j��';
    cv_visit_dayname_sun  CONSTANT VARCHAR(20) := '���j��';
    -- *** ���[�J���ϐ� ***
    lv_visit_dayname  VARCHAR(20);
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
    -- ======================
    -- �K��j���̓��o
    -- ======================
    SELECT TO_CHAR(id_base_date, cv_format_get_dayname)  dayname -- �K��j��
    INTO   lv_visit_dayname
    FROM   dual
    ;
--
    -- ======================
    -- �����v�̍X�V
    -- ======================
    -- �������̃J�E���g�A�b�v
    gn_total_count := gn_total_count + 1;
--
    -- �����v�̃J�E���g�A�b�v
    -- ���j���̏ꍇ
    IF (lv_visit_dayname = cv_visit_dayname_mon) THEN
      gn_total_count_1 := gn_total_count_1 + 1;
      -- �z��p�J�E���^�֊i�[
      gn_cnt := gn_total_count_1;
      -- �z��ւ̃f�[�^�i�[
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- �s�ԍ�
      gd_day_1                                      := id_base_date;                          -- ��
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_1 := i_prsn_dt_vst_pln_rec.account_number;  -- �ڋq�R�[�h
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_1       := i_prsn_dt_vst_pln_rec.route_no;        -- ���[�gNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_1  := i_prsn_dt_vst_pln_rec.party_name;      -- �ڋq����
--
    -- �Ηj���̏ꍇ
    ELSIF (lv_visit_dayname = cv_visit_dayname_tue) THEN
      gn_total_count_2 := gn_total_count_2 + 1;
      -- �z��p�J�E���^�֊i�[
      gn_cnt := gn_total_count_2;
      -- �z��ւ̃f�[�^�i�[
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- �s�ԍ�
      gd_day_2                                      := id_base_date;                          -- ��
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_2 := i_prsn_dt_vst_pln_rec.account_number;  -- �ڋq�R�[�h
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_2       := i_prsn_dt_vst_pln_rec.route_no;        -- ���[�gNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_2  := i_prsn_dt_vst_pln_rec.party_name;      -- �ڋq����
--
    -- ���j���̏ꍇ
    ELSIF (lv_visit_dayname = cv_visit_dayname_wed) THEN
      gn_total_count_3 := gn_total_count_3 + 1;
      -- �z��p�J�E���^�֊i�[
      gn_cnt := gn_total_count_3;
      -- �z��ւ̃f�[�^�i�[
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- �s�ԍ�
      gd_day_3                                      := id_base_date;                          -- ��
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_3 := i_prsn_dt_vst_pln_rec.account_number;  -- �ڋq�R�[�h
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_3       := i_prsn_dt_vst_pln_rec.route_no;        -- ���[�gNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_3  := i_prsn_dt_vst_pln_rec.party_name;      -- �ڋq����
--
    -- �ؗj���̏ꍇ
    ELSIF (lv_visit_dayname = cv_visit_dayname_thu) THEN
      gn_total_count_4 := gn_total_count_4 + 1;
      -- �z��p�J�E���^�֊i�[
      gn_cnt := gn_total_count_4;
      -- �z��ւ̃f�[�^�i�[
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- �s�ԍ�
      gd_day_4                                      := id_base_date;                          -- ��
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_4 := i_prsn_dt_vst_pln_rec.account_number;  -- �ڋq�R�[�h
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_4       := i_prsn_dt_vst_pln_rec.route_no;        -- ���[�gNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_4  := i_prsn_dt_vst_pln_rec.party_name;      -- �ڋq����
--
    -- ���j���̏ꍇ
    ELSIF (lv_visit_dayname = cv_visit_dayname_fri) THEN
      gn_total_count_5 := gn_total_count_5 + 1;
      -- �z��p�J�E���^�֊i�[
      gn_cnt := gn_total_count_5;
      -- �z��ւ̃f�[�^�i�[
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- �s�ԍ�
      gd_day_5                                      := id_base_date;                          -- ��
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_5 := i_prsn_dt_vst_pln_rec.account_number;  -- �ڋq�R�[�h
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_5       := i_prsn_dt_vst_pln_rec.route_no;        -- ���[�gNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_5  := i_prsn_dt_vst_pln_rec.party_name;      -- �ڋq����
--
    -- �y�j���̏ꍇ
    ELSIF (lv_visit_dayname = cv_visit_dayname_sat) THEN
      gn_total_count_6 := gn_total_count_6 + 1;
      -- �z��p�J�E���^�֊i�[
      gn_cnt := gn_total_count_6;
      -- �z��ւ̃f�[�^�i�[
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- �s�ԍ�
      gd_day_6                                      := id_base_date;                          -- ��
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_6 := i_prsn_dt_vst_pln_rec.account_number;  -- �ڋq�R�[�h
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_6       := i_prsn_dt_vst_pln_rec.route_no;        -- ���[�gNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_6  := i_prsn_dt_vst_pln_rec.party_name;      -- �ڋq����
--
    -- ���j���̏ꍇ
    ELSIF (lv_visit_dayname = cv_visit_dayname_sun) THEN
      gn_total_count_7 := gn_total_count_7 + 1;
      -- �z��p�J�E���^�֊i�[
      gn_cnt := gn_total_count_7;
      -- �z��ւ̃f�[�^�i�[
      g_rep_vst_rt_mng_tab(gn_cnt).line_num         := gn_cnt;                                -- �s�ԍ�
      gd_day_7                                      := id_base_date;                          -- ��
      g_rep_vst_rt_mng_tab(gn_cnt).account_number_7 := i_prsn_dt_vst_pln_rec.account_number;  -- �ڋq�R�[�h
      g_rep_vst_rt_mng_tab(gn_cnt).route_no_7       := i_prsn_dt_vst_pln_rec.route_no;        -- ���[�gNo
      g_rep_vst_rt_mng_tab(gn_cnt).customer_name_7  := i_prsn_dt_vst_pln_rec.party_name;      -- �ڋq����
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
   * Description      : ���[�N�e�[�u���f�[�^�o�^(A-6)
   ***********************************************************************************/
  PROCEDURE insert_row(
     id_standard_date       IN  DATE                               -- ��N����(DATE�^)
    ,id_start_date          IN  DATE                               -- �������
    ,id_end_date            IN  DATE                               -- �������
    ,iv_work_base_code      IN  VARCHAR2                           -- ���_�R�[�h
    ,iv_hub_name            IN  VARCHAR2                           -- ���_����
    ,iv_employee_number     IN  VARCHAR2                           -- �]�ƈ��R�[�h
    ,iv_full_name           IN  VARCHAR2                           -- ��������
    ,ov_errbuf              OUT NOCOPY VARCHAR2                    -- �G���[�E���b�Z�[�W            --# �Œ� #
    ,ov_retcode             OUT NOCOPY VARCHAR2                    -- ���^�[���E�R�[�h              --# �Œ� #
    ,ov_errmsg              OUT NOCOPY VARCHAR2                    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
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
    -- *** ���[�J���萔 ***
    cv_report_name      CONSTANT VARCHAR2(40)  := '��K�⑍���Ǘ��\��'; -- ���[�^�C�g��
    cv_tkn_tbl_nm       CONSTANT VARCHAR2(100) := '�K�⑍���Ǘ��\���[���[�N�e�[�u���̓o�^';
    -- *** ���[�J���ϐ� ***
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
      <<insert_row_loop>>
      FOR i IN 1..g_rep_vst_rt_mng_tab.COUNT LOOP
        -- ======================
        -- ���[�N�e�[�u���f�[�^�o�^
        -- ======================
        INSERT INTO xxcso_rep_visit_route_mng xrvrm  -- �K�⑍���Ǘ��\���[���[�N�e�[�u��
          ( line_num                -- �s�ԍ�
           ,report_id               -- ���[�h�c
           ,report_name             -- ���[�^�C�g��
           ,output_date             -- �o�͓���
           ,base_date               -- ��N����
           ,base_date_start         -- ���START
           ,base_date_end           -- ���END
           ,base_code               -- ���_�R�[�h
           ,hub_name                -- ���_����
           ,employee_number         -- �c�ƈ��R�[�h
           ,employee_name           -- �c�ƈ���
           ,total_count             -- ������
           ,day_1                   -- ���j��-��
           ,week_1                  -- ���j��-�j��
           ,total_count_1           -- ���j��-������
           ,account_number_1        -- ���j��-�ڋq�R�[�h
           ,route_no_1              -- ���j��-���[�gNo.
           ,customer_name_1         -- ���j��-�ڋq��
           ,day_2                   -- �Ηj��-��
           ,week_2                  -- �Ηj��-�j��
           ,total_count_2           -- �Ηj��-������
           ,account_number_2        -- �Ηj��-�ڋq�R�[�h
           ,route_no_2              -- �Ηj��-���[�gNo.
           ,customer_name_2         -- �Ηj��-�ڋq��
           ,day_3                   -- ���j��-��
           ,week_3                  -- ���j��-�j��
           ,total_count_3           -- ���j��-������
           ,account_number_3        -- ���j��-�ڋq�R�[�h
           ,route_no_3              -- ���j��-���[�gNo.
           ,customer_name_3         -- ���j��-�ڋq��
           ,day_4                   -- �ؗj��-��
           ,week_4                  -- �ؗj��-�j��
           ,total_count_4           -- �ؗj��-������
           ,account_number_4        -- �ؗj��-�ڋq�R�[�h
           ,route_no_4              -- �ؗj��-���[�gNo.
           ,customer_name_4         -- �ؗj��-�ڋq��
           ,day_5                   -- ���j��-��
           ,week_5                  -- ���j��-�j��
           ,total_count_5           -- ���j��-������
           ,account_number_5        -- ���j��-�ڋq�R�[�h
           ,route_no_5              -- ���j��-���[�gNo.
           ,customer_name_5         -- ���j��-�ڋq��
           ,day_6                   -- �y�j��-��
           ,week_6                  -- �y�j��-�j��
           ,total_count_6           -- �y�j��-������
           ,account_number_6        -- �y�j��-�ڋq�R�[�h
           ,route_no_6              -- �y�j��-���[�gNo.
           ,customer_name_6         -- �y�j��-�ڋq��
           ,day_7                   -- ���j��-��
           ,week_7                  -- ���j��-�j��
           ,total_count_7           -- ���j��-������
           ,account_number_7        -- ���j��-�ڋq�R�[�h
           ,route_no_7              -- ���j��-���[�gNo.
           ,customer_name_7         -- ���j��-�ڋq��
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
        VALUES
         (  g_rep_vst_rt_mng_tab(i).line_num          -- �s�ԍ�
           ,cv_report_id                              -- ���[�h�c
           ,cv_report_name                            -- ���[�^�C�g��
           ,cd_now_date                               -- �o�͓���
           ,id_standard_date                          -- ��N����
           ,id_start_date                             -- ���START
           ,id_end_date                               -- ���END
           ,iv_work_base_code                         -- ���_�R�[�h
           ,iv_hub_name                               -- ���_����
           ,iv_employee_number                        -- �c�ƈ��R�[�h
           ,iv_full_name                              -- �c�ƈ���
           ,gn_total_count                            -- ������
           ,gd_day_1                                  -- ���j��-��
           ,cv_week_1                                 -- ���j��-�j��
           ,gn_total_count_1                          -- ���j��-������
           ,g_rep_vst_rt_mng_tab(i).account_number_1  -- ���j��-�ڋq�R�[�h
           ,g_rep_vst_rt_mng_tab(i).route_no_1        -- ���j��-���[�gNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_1   -- ���j��-�ڋq��
           ,gd_day_2                                  -- �Ηj��-��
           ,cv_week_2                                 -- �Ηj��-�j��
           ,gn_total_count_2                          -- �Ηj��-������
           ,g_rep_vst_rt_mng_tab(i).account_number_2  -- �Ηj��-�ڋq�R�[�h
           ,g_rep_vst_rt_mng_tab(i).route_no_2        -- �Ηj��-���[�gNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_2   -- �Ηj��-�ڋq��
           ,gd_day_3                                  -- ���j��-��
           ,cv_week_3                                 -- ���j��-�j��
           ,gn_total_count_3                          -- ���j��-������
           ,g_rep_vst_rt_mng_tab(i).account_number_3  -- ���j��-�ڋq�R�[�h
           ,g_rep_vst_rt_mng_tab(i).route_no_3        -- ���j��-���[�gNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_3   -- ���j��-�ڋq��
           ,gd_day_4                                  -- �ؗj��-��
           ,cv_week_4                                 -- �ؗj��-�j��
           ,gn_total_count_4                          -- �ؗj��-������
           ,g_rep_vst_rt_mng_tab(i).account_number_4  -- �ؗj��-�ڋq�R�[�h
           ,g_rep_vst_rt_mng_tab(i).route_no_4        -- �ؗj��-���[�gNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_4   -- �ؗj��-�ڋq��
           ,gd_day_5                                  -- ���j��-��
           ,cv_week_5                                 -- ���j��-�j��
           ,gn_total_count_5                          -- ���j��-������
           ,g_rep_vst_rt_mng_tab(i).account_number_5  -- ���j��-�ڋq�R�[�h
           ,g_rep_vst_rt_mng_tab(i).route_no_5        -- ���j��-���[�gNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_5   -- ���j��-�ڋq��
           ,gd_day_6                                  -- �y�j��-��
           ,cv_week_6                                 -- �y�j��-�j��
           ,gn_total_count_6                          -- �y�j��-������
           ,g_rep_vst_rt_mng_tab(i).account_number_6  -- �y�j��-�ڋq�R�[�h
           ,g_rep_vst_rt_mng_tab(i).route_no_6        -- �y�j��-���[�gNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_6   -- �y�j��-�ڋq��
           ,gd_day_7                                  -- ���j��-��
           ,cv_week_7                                 -- ���j��-�j��
           ,gn_total_count_7                          -- ���j��-������
           ,g_rep_vst_rt_mng_tab(i).account_number_7  -- ���j��-�ڋq�R�[�h
           ,g_rep_vst_rt_mng_tab(i).route_no_7        -- ���j��-���[�gNo.
           ,g_rep_vst_rt_mng_tab(i).customer_name_7   -- ���j��-�ڋq��
           ,cn_created_by                             -- �쐬��
           ,cd_creation_date                          -- �쐬��
           ,cn_last_updated_by                        -- �ŏI�X�V��
           ,cd_last_update_date                       -- �ŏI�X�V��
           ,cn_last_update_login                      -- �ŏI�X�V���O�C��
           ,cn_request_id                             -- �v��ID
           ,cn_program_application_id                 -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
           ,cn_program_id                             -- �R���J�����g�E�v���O����ID
           ,cd_program_update_date                    -- �v���O�����X�V��
         );
      END LOOP insert_row_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --�A�v���P�[�V�����Z�k��
                 ,iv_name         => cv_tkn_number_07        --���b�Z�[�W�R�[�h
                 ,iv_token_name1  => cv_tkn_act              --�g�[�N���R�[�h1
                 ,iv_token_value1 => cv_tkn_tbl_nm           --�g�[�N���l1
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
   * Description      : SVF�N��(A-7)
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
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCSO019A06S.xml';  -- �t�H�[���l���t�@�C����
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCSO019A06S.vrq';  -- �N�G���[�l���t�@�C����
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
                     || TO_CHAR (cd_creation_date, cv_format_date_ymd1)
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
                 ,iv_name         => cv_tkn_number_06        --���b�Z�[�W�R�[�h
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
   * Description      : ���[�N�e�[�u���f�[�^�폜(A-8)
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
    DELETE FROM xxcso_rep_visit_route_mng xrvrm -- �K�⑍���Ǘ��\���[���[�N�e�[�u��
    WHERE xrvrm.request_id = cn_request_id;
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
-- #####################################  �Œ蕔 END   ##########################################
--
  END delete_row;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   ***********************************************************************************/
  PROCEDURE submain(
     iv_standard_date    IN  VARCHAR2          -- ��N����
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
    -- �f�[�^���o�p(�J�[�\���ɂĎg�p)
    cv_rt_num_hd_st   CONSTANT VARCHAR2(2) := '0';   -- ���o���[�gNo���������򏈗��p(�ŏ��l)
    cv_rt_num_hd_end  CONSTANT VARCHAR2(2) := '3';   -- ���o���[�gNo���������򏈗��p(�ő�l)
    cv_rt_num_mnth    CONSTANT VARCHAR2(2) := '5';   -- ���o���[�gNo���������򏈗��p(���P�ʖK��)
    cv_srtng_grp_a    CONSTANT VARCHAR2(2) := 'A';   -- ���o���[�gNo���������򏈗��O���[�s���O�p(A)
    cv_srtng_grp_b    CONSTANT VARCHAR2(2) := 'B';   -- ���o���[�gNo���������򏈗��O���[�s���O�p(B)
    cv_srtng_grp_c    CONSTANT VARCHAR2(2) := 'C';   -- ���o���[�gNo���������򏈗��O���[�s���O�p(C)
    cn_dflt_vst_tm    CONSTANT NUMBER      := -999;  -- ���o���[�gNo���������򏈗��K��񐔐ݒ�p
    cv_date_plan      CONSTANT VARCHAR2(2) := '2';   -- �ڋq�ʔ���v��e�[�u��.�����敪�u2�v���ʌv��
    cv_visit_target   CONSTANT VARCHAR2(2) := '1';   -- �ڋq�}�X�^.�K��Ώۋ敪�u1�v�K��Ώ�(����܂�)
    cv_replace_char   CONSTANT VARCHAR2(2) := '-';   -- ���[�gNo��NUMBER�^�֕ϊ����邽�߂̃��v���C�X����
    --
    cv_cstmr_cls_cd10      CONSTANT VARCHAR(2) := '10';      -- �ڋq�敪:10 (�ڋq)
    cv_cstmr_cls_cd15      CONSTANT VARCHAR(2) := '15';      -- �ڋq�敪:15 (����)
    cv_cstmr_cls_cd16      CONSTANT VARCHAR(2) := '16';      -- �ڋq�敪:16 (�≮������)
    --
    cv_cstmr_sttus25       CONSTANT VARCHAR(2) := '25';      -- �ڋq�X�e�[�^�X:25 (SP���ύ�)
    cv_cstmr_sttus30       CONSTANT VARCHAR(2) := '30';      -- �ڋq�X�e�[�^�X:30 (���F��)
    cv_cstmr_sttus40       CONSTANT VARCHAR(2) := '40';      -- �ڋq�X�e�[�^�X:40 (�ڋq)
    cv_cstmr_sttus50       CONSTANT VARCHAR(2) := '50';      -- �ڋq�X�e�[�^�X:50 (�x�~)
    cv_cstmr_sttus99       CONSTANT VARCHAR(2) := '99';      -- �ڋq�X�e�[�^�X:99 (�ΏۊO)
    -- *** ���[�J���ϐ� ***
    -- ���[�v�J�E���^
    ln_loop_cnt       NUMBER DEFAULT 1;
    -- OUT�p�����[�^�i�[�p
    ld_standard_date  DATE;             -- ��N����(DATE�^)
    ld_start_date     DATE;             -- �������
    ld_end_date       DATE;             -- �������
    ld_base_date      DATE;             -- ���[�v�p���
    lv_full_name      VARCHAR(40);      -- ��������
    lv_work_base_code VARCHAR2(150);    -- �Ζ��n���_�R�[�h
    lv_hub_name       VARCHAR2(4000);   -- �Ζ��n���_��
    -- ���b�Z�[�W�i�[�p
    lv_msg            VARCHAR2(5000);
    -- SVF�N��API�߂�l�i�[�p
    lv_errbuf_svf     VARCHAR2(5000);   -- �G���[�E���b�Z�[�W
    lv_retcode_svf    VARCHAR2(1);      -- ���^�[���E�R�[�h
    lv_errmsg_svf     VARCHAR2(5000);   -- ���[�U�[�E�G���[�E���b�Z�[�W
    -- *** ���[�J���E�J�[�\�� ***
    -- �c�ƈ��ʎ��ԕʖK����� ���o�J�[�\�� 
    CURSOR get_prsn_dt_vst_pln_cur(
              id_base_date        IN  DATE     -- ���[�v�p���
             ,iv_employee_number  IN VARCHAR2  -- �]�ƈ��R�[�h
             ,iv_rt_num_hd_st     IN VARCHAR2  -- ���o���[�gNo��������������p(�ŏ��l)
             ,iv_rt_num_hd_end    IN VARCHAR2  -- ���o���[�gNo��������������p(�ő�l)
             ,iv_rt_num_mnth      IN VARCHAR2  -- ���o���[�gNo��������������p(���P�ʖK��)
             ,iv_srtng_grp_a      IN VARCHAR2  -- ���o���[�gNo���������򏈗��O���[�s���O�p(A)
             ,iv_srtng_grp_b      IN VARCHAR2  -- ���o���[�gNo���������򏈗��O���[�s���O�p(B)
             ,iv_srtng_grp_c      IN VARCHAR2  -- ���o���[�gNo���������򏈗��O���[�s���O�p(C)
             ,in_dflt_vst_tm      IN NUMBER    -- ���o���[�gNo���������򏈗��K��񐔐ݒ�p
             ,iv_date_plan        IN VARCHAR2  -- �ڋq�ʔ���v��e�[�u��.�����敪�u2�v���ʌv��
             ,iv_visit_target     IN VARCHAR2  -- �ڋq�}�X�^.�K��Ώۋ敪�u1�v�K��Ώ�(����܂�)
             ,iv_format_date_ymd1 IN VARCHAR2  -- ���t����
             ,iv_replace_char     IN VARCHAR2  -- ���[�gNo��NUMBER�^�֕ϊ����邽�߂̃��v���C�X����
           )
    IS
      SELECT   xca.account_number  account_number  -- �ڋq�R�[�h
              ,xca.party_name      party_name      -- �ڋq����
              ,xcr2.route_number   route_number    -- ���[�gNo
              ,(CASE 
                WHEN SUBSTRB(xcr2.route_number,1,1) >= iv_rt_num_hd_st
                AND  SUBSTRB(xcr2.route_number,1,1) <= iv_rt_num_hd_end
                THEN iv_srtng_grp_a
                WHEN SUBSTRB(xcr2.route_number,1,1) = iv_rt_num_mnth
                THEN iv_srtng_grp_b
                ELSE iv_srtng_grp_c
                END) group_name                  -- �������ɂ��O���[�v(�\�[�g�p)
              ,(CASE
                WHEN SUBSTRB(xcr2.route_number,1,1) >= iv_rt_num_hd_st
                AND  SUBSTRB(xcr2.route_number,1,1) <= iv_rt_num_hd_end
                THEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number)
                WHEN SUBSTRB(xcr2.route_number,1,1) = iv_rt_num_mnth
                THEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number)
                ELSE in_dflt_vst_tm
                END) visit_times                 -- �K���(�\�[�g�p)
              ,(CASE
                WHEN SUBSTRB(xcr2.route_number,1,1) >= iv_rt_num_hd_st
                AND  SUBSTRB(xcr2.route_number,1,1) <= iv_rt_num_hd_end
                THEN TO_NUMBER(REPLACE(xcr2.route_number,iv_replace_char))
                WHEN SUBSTRB(xcr2.route_number,1,1) = iv_rt_num_mnth
                THEN TO_NUMBER(REPLACE(xcr2.route_number,iv_replace_char))
                ELSE 1 / TO_NUMBER(REPLACE(xcr2.route_number,iv_replace_char))
                END) rt_nmbr_fr_srtng            -- ���[�gNo(�\�[�g�p) 
      FROM     xxcso_cust_accounts_v xca         -- �ڋq�}�X�^�r���[
              ,xxcso_account_sales_plans xasp    -- �ڋq�ʔ���v��e�[�u��
              ,xxcso_resource_custs_v2 xrc2      -- �c�ƈ��S���ڋq�i�ŐV�j�r���[
              ,xxcso_cust_routes_v2 xcr2         -- �ڋq���[�gNo�i�ŐV�j�r���[
      WHERE   xrc2.employee_number    = iv_employee_number
        AND   xrc2.account_number     = xasp.account_number
        AND   xasp.plan_date          = TO_CHAR(id_base_date,iv_format_date_ymd1)
        AND   xasp.month_date_div     = iv_date_plan
        AND   xasp.sales_plan_day_amt > 0
        AND   xasp.account_number     = xca.account_number
        AND   xcr2.party_id           = xca.party_id
        AND   xca.vist_target_div     = iv_visit_target
        AND   xcr2.route_number IS NOT NULL
        AND   ((xca.customer_class_code    = cv_cstmr_cls_cd10
                AND xca.customer_status    IN (cv_cstmr_sttus25, cv_cstmr_sttus30,
                                                  cv_cstmr_sttus40, cv_cstmr_sttus50))
          OR  (xca.customer_class_code    = cv_cstmr_cls_cd15
                AND xca.customer_status    = cv_cstmr_sttus99)
          OR  (xca.customer_class_code    = cv_cstmr_cls_cd16
                AND xca.customer_status    = cv_cstmr_sttus99)
              )
      ORDER BY
         group_name          ASC
        ,visit_times         DESC
        ,rt_nmbr_fr_srtng    DESC
        ,xca.account_number  ASC
    ;
--
    -- *** ���[�J���E���R�[�h ***
    l_prsn_dt_vst_pln_cur_rec  get_prsn_dt_vst_pln_cur%ROWTYPE;
    l_prsn_dt_vst_pln_rec      g_prsn_dt_vst_pln_rtype;
--    -- *** ���[�J���E��O ***
----
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �J�E���^�̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ========================================
    -- A-1.��������
    -- ========================================
    init(
       iv_standard_date    => iv_standard_date       -- ��N����
      ,iv_employee_number  => iv_employee_number     -- �]�ƈ��R�[�h
      ,ov_errbuf           => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode          => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg           => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    -- ========================================
    -- A-2.�p�����[�^�`�F�b�N
    -- ========================================
    chk_param(
       iv_standard_date    => iv_standard_date       -- ��N����
      ,iv_employee_number  => iv_employee_number     -- �]�ƈ��R�[�h
      ,od_standard_date    => ld_standard_date       -- ��N����(DATE�^)
      ,ov_full_name        => lv_full_name           -- ��������
      ,ov_work_base_code   => lv_work_base_code      -- �Ζ��n���_�R�[�h
      ,ov_hub_name         => lv_hub_name            -- �Ζ��n���_��
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
    -- A-3.���[�w�b�_����
    -- ========================================
    header_process(
       id_standard_date    => ld_standard_date       -- ��N����(DATE�^)
      ,od_start_date       => ld_start_date          -- �������
      ,od_end_date         => ld_end_date            -- �������
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
    -- A-4.�f�[�^�擾
    -- ========================================
--
    <<get_prsn_dt_vst_pln_loop1>>
    LOOP
      -- 8��ڂ�EXIT
      EXIT WHEN ln_loop_cnt >= 8;
--
      IF ln_loop_cnt = 1 THEN
        -- 1��ځF�J�[�\���ɓn�����[�v�p����ɁA���������ݒ�
        ld_base_date := ld_start_date;
      ELSIF ln_loop_cnt >= 2 THEN
        -- 2��ڈȍ~�F�J�[�\���ɓn�����[�v�p������J�E���g�A�b�v
        ld_base_date := ld_base_date + 1;
      END IF;
--
      -- �J�[�\���I�[�v��
      OPEN  get_prsn_dt_vst_pln_cur(
               id_base_date        => ld_base_date        -- ���[�v�p���
              ,iv_employee_number  => iv_employee_number  -- �]�ƈ��R�[�h
              ,iv_rt_num_hd_st     => cv_rt_num_hd_st     -- ���o���[�gNo��������������p(�ŏ��l)
              ,iv_rt_num_hd_end    => cv_rt_num_hd_end    -- ���o���[�gNo��������������p(�ő�l)
              ,iv_rt_num_mnth      => cv_rt_num_mnth      -- ���o���[�gNo��������������p(���P�ʖK��)
              ,iv_srtng_grp_a      => cv_srtng_grp_a      -- ���o���[�gNo���������򏈗��O���[�s���O�p(A)
              ,iv_srtng_grp_b      => cv_srtng_grp_b      -- ���o���[�gNo���������򏈗��O���[�s���O�p(B)
              ,iv_srtng_grp_c      => cv_srtng_grp_c      -- ���o���[�gNo���������򏈗��O���[�s���O�p(C)
              ,in_dflt_vst_tm      => cn_dflt_vst_tm      -- ���o���[�gNo���������򏈗��K��񐔐ݒ�p
              ,iv_date_plan        => cv_date_plan        -- �ڋq�ʔ���v��e�[�u��.�����敪�u2�v���ʌv��
              ,iv_visit_target     => cv_visit_target     -- �ڋq�}�X�^.�K��Ώۋ敪�u1�v�K��Ώ�(����܂�)
              ,iv_format_date_ymd1 => cv_format_date_ymd1 -- ���t����'YYYYMMDD'
              ,iv_replace_char     => cv_replace_char     -- ���[�gNo��NUMBER�^�֕ϊ����邽�߂̃��v���C�X����
            );
--
      <<get_prsn_dt_vst_pln_loop2>>
      LOOP
--
        FETCH get_prsn_dt_vst_pln_cur INTO l_prsn_dt_vst_pln_cur_rec;
--
        -- �����Ώۃf�[�^�����݂��Ȃ������ꍇEXIT
        EXIT WHEN get_prsn_dt_vst_pln_cur%NOTFOUND
        OR  get_prsn_dt_vst_pln_cur%ROWCOUNT = 0;
--
        -- �����Ώی����J�E���g�A�b�v
        gn_target_cnt := gn_target_cnt + 1;
--
        -- ���R�[�h�ϐ�������
        l_prsn_dt_vst_pln_rec := NULL;
--
        -- �擾�f�[�^���i�[
        l_prsn_dt_vst_pln_rec.account_number  := l_prsn_dt_vst_pln_cur_rec.account_number;   -- �ڋq�R�[�h
        l_prsn_dt_vst_pln_rec.party_name      := l_prsn_dt_vst_pln_cur_rec.party_name;       -- �ڋq����
        l_prsn_dt_vst_pln_rec.route_no        := l_prsn_dt_vst_pln_cur_rec.route_number;     -- ���[�gNo
--
        -- ========================================
        -- A-5.�z��̒ǉ��A�X�V
        -- ========================================
        ins_upd_lines(
           id_base_date           => ld_base_date           -- ���[�v�p���
          ,i_prsn_dt_vst_pln_rec  => l_prsn_dt_vst_pln_rec  -- �c�ƈ��ʓ��ʖK��v��f�[�^
          ,ov_errbuf              => lv_errbuf              -- �G���[�E���b�Z�[�W            --# �Œ� #
          ,ov_retcode             => lv_retcode             -- ���^�[���E�R�[�h              --# �Œ� #
          ,ov_errmsg              => lv_errmsg              -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END LOOP get_prsn_dt_vst_pln_loop2;
      -- �J�[�\���N���[�Y
      CLOSE get_prsn_dt_vst_pln_cur;
      -- LOOP�������J�E���g�A�b�v
      ln_loop_cnt := ln_loop_cnt + 1;
--
    END LOOP get_prsn_dt_vst_pln_loop1;
--
    -- �����Ώۃf�[�^��0���̏ꍇ
    IF gn_target_cnt = 0 THEN
      -- 0�����b�Z�[�W�o��
      lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name         --�A�v���P�[�V�����Z�k��
                  ,iv_name         => cv_tkn_number_09    --���b�Z�[�W�R�[�h
                );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_msg                                 --���[�U�[�E�G���[���b�Z�[�W
      );
--
      ov_retcode := cv_status_normal;
    ELSE
      -- ========================================
      -- A-6.���[�N�e�[�u���f�[�^�o�^
      -- ========================================
      insert_row(
         id_standard_date    => ld_standard_date       -- ��N����(DATE�^)
        ,id_start_date       => ld_start_date          -- �������
        ,id_end_date         => ld_end_date            -- �������
        ,iv_work_base_code   => lv_work_base_code      -- ���_�R�[�h
        ,iv_hub_name         => lv_hub_name            -- ���_����
        ,iv_employee_number  => iv_employee_number     -- �]�ƈ��R�[�h
        ,iv_full_name        => lv_full_name           -- ��������
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
      -- A-7.SVF�N��
      -- ========================================
      act_svf(
         ov_errbuf     => lv_errbuf_svf                -- �G���[�E���b�Z�[�W            --# �Œ� #
        ,ov_retcode    => lv_retcode_svf               -- ���^�[���E�R�[�h              --# �Œ� #
        ,ov_errmsg     => lv_errmsg_svf                -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
      IF (lv_retcode_svf <> cv_status_error) THEN
        gn_normal_cnt := gn_total_count;
      END IF;
--
      -- ========================================
      -- A-8.���[�N�e�[�u���f�[�^�폜
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
      -- A-9.SVF�N��API�G���[�`�F�b�N
      -- ========================================
      IF (lv_retcode_svf = cv_status_error) THEN
        lv_errmsg := lv_errmsg_svf;
        lv_errbuf := lv_errbuf_svf;
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_prsn_dt_vst_pln_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_prsn_dt_vst_pln_cur;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      -- �G���[�����J�E���g
      gn_error_cnt := gn_error_cnt + 1;
--
      -- �J�[�\�����N���[�Y����Ă��Ȃ��ꍇ
      IF (get_prsn_dt_vst_pln_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_prsn_dt_vst_pln_cur;
      END IF;
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
      IF (get_prsn_dt_vst_pln_cur%ISOPEN) THEN
        -- �J�[�\���N���[�Y
        CLOSE get_prsn_dt_vst_pln_cur;
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
    ,iv_standard_date   IN  VARCHAR2           --   ��N����
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
    cv_log_msg         CONSTANT VARCHAR2(100) := '�V�X�e���G���[���������܂����B�V�X�e���Ǘ��҂Ɋm�F���Ă��������B';
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
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    cv_log             CONSTANT VARCHAR2(3)   := 'LOG';  -- �R���J�����g�w�b�_���b�Z�[�W�o�� �o�͋敪
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
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
       iv_standard_date    => iv_standard_date   -- ��N����
      ,iv_employee_number  => iv_employee_number -- �]�ƈ��R�[�h
      ,ov_errbuf           => lv_errbuf          -- �G���[�E���b�Z�[�W            --# �Œ� #
      ,ov_retcode          => lv_retcode         -- ���^�[���E�R�[�h              --# �Œ� #
      ,ov_errmsg           => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --�G���[�o��
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => lv_errmsg                  --���[�U�[�E�G���[���b�Z�[�W
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => SUBSTRB(
                      cv_log_msg ||cv_msg_prnthss_l||
                      cv_pkg_name||cv_msg_cont||
                      cv_prg_name||cv_msg_part||
                      lv_errbuf  ||cv_msg_prnthss_r,1,5000
                    )
       );                                                     --�G���[���b�Z�[�W
    END IF;
--
    -- =======================
    -- A-10.�I������ 
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
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;      
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
END XXCSO019A06C;
/
